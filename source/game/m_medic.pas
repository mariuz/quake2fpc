{
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                           Quake 2 Freepascal Port 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


--------------------------------------------------------------------------------
  Contributors:
--------------------------------------------------------------------------------
    Lars aka L505 (started FPC port)
    http://z505.com
    

--------------------------------------------------------------------------------
 Notes regarding freepascal port:
--------------------------------------------------------------------------------

 - see below for delphi notes, conversion notes, and copyright
 
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
}


{----------------------------------------------------------------------------}
{                                                                            }
{ File(s): m_medic.pas                                                       }
{                                                                            }
{ Initial conversion by : Skaljac Bojan (Skaljac@Italy.Com)                  }
{ Initial conversion on : 19-Feb-2002                                        }
{                                                                            }
{ This File contains part of convertion of Quake2 source to ObjectPascal.    }
{ More information about this project can be found at:                       }
{ http://www.sulaco.co.za/quake2/                                            }
{                                                                            }
{ Copyright (C) 1997-2001 Id Software, Inc.                                  }
{                                                                            }
{ This program is free software; you can redistribute it and/or              }
{ modify it under the terms of the GNU General Public License                }
{ as published by the Free Software Foundation; either version 2             }
{ of the License, or (at your option) any later version.                     }
{                                                                            }
{ This program is distributed in the hope that it will be useful,            }
{ but WITHOUT ANY WARRANTY; without even the implied warranty of             }
{ MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                       }
{                                                                            }
{ See the GNU General Public License for more details.                       }
{                                                                            }
{----------------------------------------------------------------------------}
{ Updated on :                                                               }
{ Updated by :                                                               }
{                                                                            }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{ 1.) g_local.h and game.h                                                   }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{ 1.) test compilation with the above two units                              }
{----------------------------------------------------------------------------}

unit m_medic;

interface

uses
  g_local,
  q_shared;

procedure medic_idle(self:edict_p); cdecl;
procedure medic_search (self:edict_p); cdecl;
procedure medic_sight (self, other : edict_p); cdecl;
procedure medic_stand(self:edict_p); cdecl;
procedure medic_walk(self:edict_p); cdecl;
procedure medic_run(self:edict_p); cdecl;
procedure medic_pain(self, other:edict_p;kick:single;damage:Integer); cdecl;
procedure medic_fire_blaster(self:edict_p); cdecl;
procedure medic_dead (self:edict_p); cdecl;
procedure medic_die (self, inflictor, attacker:edict_p; damage:Integer; const point:vec3_t); cdecl;
procedure medic_duck_down (self:edict_p); cdecl;
procedure medic_duck_hold (self:edict_p); cdecl;
procedure medic_duck_up (self:edict_p); cdecl;
procedure medic_dodge (self , attacker : edict_p;eta : single); cdecl;
procedure medic_continue (self:edict_p); cdecl;
procedure medic_hook_launch (self:edict_p); cdecl;
procedure medic_cable_attack (self:edict_p); cdecl;
procedure medic_hook_retract (self:edict_p); cdecl;
procedure medic_attack(self:edict_p); cdecl;
function medic_checkattack (self:edict_p):qboolean; cdecl;

procedure SP_monster_medic(self:edict_p); cdecl;

//qboolean visible (edict_t *self, edict_t *other);
const MODEL_SCALE     = 1.200000;
var     sound_idle1,
        sound_pain1,
        sound_pain2,
        sound_die,
        sound_sight,
        sound_search,
        sound_hook_launch,
        sound_hook_hit,
        sound_hook_heal,
        sound_hook_retract: Integer;
{$I m_medic.inc}

implementation

uses
  g_utils, game_add, GameUnit, g_ai, g_main, m_flash, g_monster, g_local_add,
  g_misc, q_shared_add, g_spawn;

function medic_FindDeadMonster(self:edict_p):edict_p;
var
  ent, best  : edict_p;
label __Continue;
begin
  ent  := nil;
  best := nil;

  ent := findradius(ent, self^.s.origin, 1024);
  while (ent <> nil) do
  begin
    if (ent = self) then
      goto __Continue;
    if (ent^.svflags and SVF_MONSTER) = 0 then
      goto __Continue;
    if (ent^.monsterinfo.aiflags and AI_GOOD_GUY) = 0 then
      goto __Continue;
    if (ent^.owner<>nil) then
      goto __Continue;
    if (ent^.health > 0) then
      goto __Continue;
    if (ent^.nextthink<>0.0) then
      goto __Continue;
    if (not visible(self, ent)) then
      goto __Continue;

    if (best = nil) then
    begin
      best := ent;
      goto __Continue;
    end;

    if (ent^.max_health <= best^.max_health) then
      goto __Continue;

    best := ent;

  __Continue:
    ent := findradius(ent, self^.s.origin, 1024);
  end;

  Result := best;
end;

procedure medic_idle(self:edict_p);
var
  ent: edict_p;
begin
  gi.sound (self, CHAN_VOICE, sound_idle1, 1, ATTN_IDLE, 0);

  ent := medic_FindDeadMonster(self);
  if (ent <> nil) then
  begin
    self^.enemy := ent;
    self^.enemy^.owner := self;
    self^.monsterinfo.aiflags := self^.monsterinfo.aiflags or AI_MEDIC;
    FoundTarget (self);
  end;
end;

procedure medic_search (self:edict_p);
var
  ent     : edict_p;
begin
  gi.sound (self, CHAN_VOICE, sound_search, 1, ATTN_IDLE, 0);

  if (self^.oldenemy = nil) then
  begin
    ent := medic_FindDeadMonster(self);
    if (ent <> nil) then
    begin
      self^.oldenemy := self^.enemy;
      self^.enemy := ent;
      self^.enemy^.owner := self;
      self^.monsterinfo.aiflags := self^.monsterinfo.aiflags or AI_MEDIC;
      FoundTarget (self);
    end;
  end;
end;

procedure medic_sight (self, other : edict_p);
begin
   gi.sound (self, CHAN_VOICE, sound_sight, 1, ATTN_NORM, 0);
end;

const
  medic_frames_stand : Array[0..89] of mframe_t =
    ((aifunc:ai_stand; dist:0; thinkfunc:medic_idle),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil));

  medic_move_stand : mmove_t =
    (firstframe:FRAME_wait1; lastframe:FRAME_wait90; frame:@medic_frames_stand; endfunc:nil);

procedure medic_stand(self:edict_p);
begin
   self^.monsterinfo.currentmove := @medic_move_stand;
end;

const
  medic_frames_walk : Array[0..11] of mframe_t =
    ((aifunc:ai_walk; dist:6.2; thinkfunc:nil),
     (aifunc:ai_walk; dist:18.1; thinkfunc:nil),
     (aifunc:ai_walk; dist:1; thinkfunc:nil),
     (aifunc:ai_walk; dist:9; thinkfunc:nil),
     (aifunc:ai_walk; dist:10; thinkfunc:nil),
     (aifunc:ai_walk; dist:9; thinkfunc:nil),
     (aifunc:ai_walk; dist:11; thinkfunc:nil),
     (aifunc:ai_walk; dist:11.6; thinkfunc:nil),
     (aifunc:ai_walk; dist:2; thinkfunc:nil),
     (aifunc:ai_walk; dist:9.9; thinkfunc:nil),
     (aifunc:ai_walk; dist:14; thinkfunc:nil),
     (aifunc:ai_walk; dist:9.3; thinkfunc:nil));

  medic_move_walk : mmove_t =
    (firstframe:FRAME_walk1; lastframe:FRAME_walk12; frame:@medic_frames_walk; endfunc:nil);


procedure medic_walk(self:edict_p);
begin
   self^.monsterinfo.currentmove := @medic_move_walk;
end;

const
  medic_frames_run : Array[0..5] of mframe_t =
    ((aifunc:ai_run; dist:18; thinkfunc:nil),
     (aifunc:ai_run; dist:22.5; thinkfunc:nil),
     (aifunc:ai_run; dist:25.4; thinkfunc:nil),
     (aifunc:ai_run; dist:23.4; thinkfunc:nil),
     (aifunc:ai_run; dist:24; thinkfunc:nil),
     (aifunc:ai_run; dist:35.6; thinkfunc:nil));
  medic_move_run : mmove_t =
    (firstframe:FRAME_run1; lastframe:FRAME_run2; frame:@medic_frames_run; endfunc:nil);

procedure medic_run(self:edict_p);
var     ent     : edict_p;
begin
   if (self^.monsterinfo.aiflags and AI_MEDIC) = 0 then
   begin
      ent := medic_FindDeadMonster(self);
      if (ent<>nil) then
      begin
         self^.oldenemy := self^.enemy;
         self^.enemy := ent;
         self^.enemy^.owner := self;
         self^.monsterinfo.aiflags :=self^.monsterinfo.aiflags and AI_MEDIC;
         FoundTarget (self);
         exit;
      end;
   end;

   if (self^.monsterinfo.aiflags and AI_STAND_GROUND) <> 0 then
      self^.monsterinfo.currentmove := @medic_move_stand
   else
      self^.monsterinfo.currentmove := @medic_move_run;
end;

const
  medic_frames_pain1 : Array[0..7] of mframe_t =
    ((aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil));
  medic_move_pain1 : mmove_t =
    (firstframe:FRAME_paina1; lastframe:FRAME_paina8; frame:@medic_frames_pain1; endfunc:medic_run);

  medic_frames_pain2 : Array[0..14] of mframe_t =
    ((aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil));
  medic_move_pain2 : mmove_t =
    (firstframe:FRAME_painb1; lastframe:FRAME_painb15; frame:@medic_frames_pain2; endfunc:medic_run);

procedure medic_pain(self, other:edict_p;kick:single;damage:Integer);
begin
   if (self^.health < (self^.max_health / 2)) then
      self^.s.skinnum := 1;

   if (level.time < self^.pain_debounce_time) then
      exit;

   self^.pain_debounce_time := level.time + 3;

   if (skill^.value = 3) then
      exit;      // no pain anims in nightmare

   if (_random() < 0.5) then
   begin
      self^.monsterinfo.currentmove := @medic_move_pain1;
      gi.sound (self, CHAN_VOICE, sound_pain1, 1, ATTN_NORM, 0);
   end
   else
   begin
      self^.monsterinfo.currentmove := @medic_move_pain2;
      gi.sound (self, CHAN_VOICE, sound_pain2, 1, ATTN_NORM, 0);
   end;
end;

procedure medic_fire_blaster(self:edict_p);
var     start, _forward, right, _end, dir : vec3_t;
        effect  : Integer;
begin
   if ((self^.s.frame = FRAME_attack9) or (self^.s.frame = FRAME_attack12)) then
      effect := EF_BLASTER
   else if ((self^.s.frame = FRAME_attack19) or (self^.s.frame = FRAME_attack22) or (self^.s.frame = FRAME_attack25) or (self^.s.frame = FRAME_attack28)) then
      effect := EF_HYPERBLASTER
   else
      effect := 0;

   AngleVectors (self^.s.angles, @_forward, @right, nil);
   G_ProjectSource (self^.s.origin, monster_flash_offset[MZ2_MEDIC_BLASTER_1], _forward, right, start);

   VectorCopy (self^.enemy^.s.origin, _end);
   _end[2] :=_end[2] + self^.enemy^.viewheight;
   VectorSubtract (_end, start, dir);

   monster_fire_blaster (self, start, dir, 2, 1000, MZ2_MEDIC_BLASTER_1, effect);
end;


procedure medic_dead (self:edict_p);
begin
   VectorSet (self^.mins, -16, -16, -24);
   VectorSet (self^.maxs, 16, 16, -8);
   self^.movetype := MOVETYPE_TOSS;
   self^.svflags :=self^.svflags or SVF_DEADMONSTER;
   self^.nextthink := 0;
   gi.linkentity (self);
end;

const
  medic_frames_death : Array[0..29] of mframe_t =
    ((aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil));
  medic_move_death : mmove_t =
    (firstframe:FRAME_death1; lastframe:FRAME_death30; frame:@medic_frames_death; endfunc:medic_dead);

procedure medic_die (self, inflictor, attacker:edict_p; damage:Integer; const point:vec3_t);
var     n       : Integer;
begin
   // if we had a pending patient, free him up for another medic
   if ((self^.enemy<>nil) and (self^.enemy^.owner = self)) then
      self^.enemy^.owner := nil;

// check for gib
   if (self^.health <= self^.gib_health) then
   begin
      gi.sound (self, CHAN_VOICE, gi.soundindex ('misc/udeath.wav'), 1, ATTN_NORM, 0);
      for n:= 0 to 1 do
         ThrowGib (self, 'models/objects/gibs/bone/tris.md2', damage, GIB_ORGANIC);
      for n:= 0 to 3 do
         ThrowGib (self, 'models/objects/gibs/sm_meat/tris.md2', damage, GIB_ORGANIC);
      ThrowHead (self, 'models/objects/gibs/head2/tris.md2', damage, GIB_ORGANIC);
      self^.deadflag := DEAD_DEAD;
      exit;
   end;

   if (self^.deadflag = DEAD_DEAD) then
      exit;

// regular death
   gi.sound (self, CHAN_VOICE, sound_die, 1, ATTN_NORM, 0);
   self^.deadflag := DEAD_DEAD;
   self^.takedamage := DAMAGE_YES;

   self^.monsterinfo.currentmove := @medic_move_death;
end;


procedure medic_duck_down (self:edict_p);
begin
   if (self^.monsterinfo.aiflags and AI_DUCKED) <> 0 then
      exit;
   self^.monsterinfo.aiflags :=self^.monsterinfo.aiflags or AI_DUCKED;
   self^.maxs[2] := self^.maxs[2] - 32;
   self^.takedamage := DAMAGE_YES;
   self^.monsterinfo.pausetime := level.time + 1;
   gi.linkentity (self);
end;

procedure medic_duck_hold (self:edict_p);
begin
   if (level.time >= self^.monsterinfo.pausetime) then
      self^.monsterinfo.aiflags :=self^.monsterinfo.aiflags and ((AI_HOLD_FRAME+1)*(-1))
   else
      self^.monsterinfo.aiflags :=self^.monsterinfo.aiflags or AI_HOLD_FRAME;
end;

procedure medic_duck_up (self:edict_p);
begin
   self^.monsterinfo.aiflags :=self^.monsterinfo.aiflags and ((AI_DUCKED+1) * (-1));
   self^.maxs[2] := self^.maxs[2] - 32;
   self^.takedamage := DAMAGE_AIM;
   gi.linkentity (self);
end;

const
  medic_frames_duck : Array[0..15] of mframe_t =
    ((aifunc:ai_move; dist:-1;  thinkfunc:nil),
     (aifunc:ai_move; dist:-1;  thinkfunc:nil),
     (aifunc:ai_move; dist:-1;  thinkfunc:medic_duck_down),
     (aifunc:ai_move; dist:-1;  thinkfunc:medic_duck_hold),
     (aifunc:ai_move; dist:-1;  thinkfunc:nil),
     (aifunc:ai_move; dist:-1;  thinkfunc:nil),
     (aifunc:ai_move; dist:-1;  thinkfunc:medic_duck_up),
     (aifunc:ai_move; dist:-1;  thinkfunc:nil),
     (aifunc:ai_move; dist:-1;  thinkfunc:nil),
     (aifunc:ai_move; dist:-1;  thinkfunc:nil),
     (aifunc:ai_move; dist:-1;  thinkfunc:nil),
     (aifunc:ai_move; dist:-1;  thinkfunc:nil),
     (aifunc:ai_move; dist:-1;  thinkfunc:nil),
     (aifunc:ai_move; dist:-1;  thinkfunc:nil),
     (aifunc:ai_move; dist:-1;  thinkfunc:nil),
     (aifunc:ai_move; dist:-1;  thinkfunc:nil));

  medic_move_duck : mmove_t =
    (firstframe:FRAME_duck1; lastframe:FRAME_duck16; frame:@medic_frames_duck; endfunc:medic_run);

procedure medic_dodge (self , attacker : edict_p;eta : single);
begin
   if (_random() > 0.25) then
      exit;

   if (self^.enemy=nil) then
      self^.enemy := attacker;

   self^.monsterinfo.currentmove := @medic_move_duck;
end;

const
  medic_frames_attackHyperBlaster : Array[0..14] of mframe_t =
    ((aifunc:ai_move; dist:0;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;  thinkfunc:medic_fire_blaster),
     (aifunc:ai_move; dist:0;  thinkfunc:medic_fire_blaster),
     (aifunc:ai_move; dist:0;  thinkfunc:medic_fire_blaster),
     (aifunc:ai_move; dist:0;  thinkfunc:medic_fire_blaster),
     (aifunc:ai_move; dist:0;  thinkfunc:medic_fire_blaster),
     (aifunc:ai_move; dist:0;  thinkfunc:medic_fire_blaster),
     (aifunc:ai_move; dist:0;  thinkfunc:medic_fire_blaster),
     (aifunc:ai_move; dist:0;  thinkfunc:medic_fire_blaster),
     (aifunc:ai_move; dist:0;  thinkfunc:medic_fire_blaster),
     (aifunc:ai_move; dist:0;  thinkfunc:medic_fire_blaster));

  medic_move_attackHyperBlaster : mmove_t =
    (firstframe:FRAME_attack15; lastframe:FRAME_attack30; frame:@medic_frames_attackHyperBlaster; endfunc:medic_run);


procedure medic_continue (self:edict_p);
begin
   if (visible (self, self^.enemy) ) then
      if (_random() <= 0.95) then
         self^.monsterinfo.currentmove := @medic_move_attackHyperBlaster;
end;

const
  medic_frames_attackBlaster : Array[0..13] of mframe_t =
    ((aifunc:ai_charge; dist:0;  thinkfunc:nil),
     (aifunc:ai_charge; dist:5;  thinkfunc:nil),
     (aifunc:ai_charge; dist:5;  thinkfunc:nil),
     (aifunc:ai_charge; dist:3;  thinkfunc:nil),
     (aifunc:ai_charge; dist:2;  thinkfunc:nil),
     (aifunc:ai_charge; dist:0;  thinkfunc:nil),
     (aifunc:ai_charge; dist:0;  thinkfunc:nil),
     (aifunc:ai_charge; dist:0;  thinkfunc:nil),
     (aifunc:ai_charge; dist:0;  thinkfunc:medic_fire_blaster),
     (aifunc:ai_charge; dist:0;  thinkfunc:nil),
     (aifunc:ai_charge; dist:0;  thinkfunc:nil),
     (aifunc:ai_charge; dist:0;  thinkfunc:medic_fire_blaster),
     (aifunc:ai_charge; dist:0;  thinkfunc:nil),
     (aifunc:ai_charge; dist:0;  thinkfunc:medic_continue));

medic_move_attackBlaster : mmove_t =
    (firstframe:FRAME_attack1; lastframe:FRAME_attack14; frame:@medic_frames_attackBlaster; endfunc:medic_run);


procedure medic_hook_launch (self:edict_p);
begin
   gi.sound (self, CHAN_WEAPON, sound_hook_launch, 1, ATTN_NORM, 0);
end;

const
  medic_cable_offsets : array[0..9] of vec3_t =
        ((45.0,  -9.2, 15.5),
   (48.4,  -9.7, 15.2),
   (47.8,  -9.8, 15.8),
   (47.3,  -9.3, 14.3),
   (45.4, -10.1, 13.1),
   (41.9, -12.7, 12.0),
   (37.8, -15.8, 11.2),
   (34.3, -18.4, 10.7),
   (32.7, -19.7, 10.4),
   (32.7, -19.7, 10.4));

procedure medic_cable_attack (self:edict_p); cdecl;
var     offset, start, _end, f, r       : vec3_t;
        dir, angles                     : vec3_t;
        tr                              : trace_t;
        distance                        : Single;
begin
   if (not self^.enemy^.inuse) then
      exit;

   AngleVectors (self^.s.angles, @f, @r, nil);
   VectorCopy (medic_cable_offsets[self^.s.frame - FRAME_attack42], offset);
   G_ProjectSource (self^.s.origin, offset, f, r, start);

   // check for max distance
   VectorSubtract (start, self^.enemy^.s.origin, dir);
   distance := VectorLength(dir);
   if (distance > 256) then
      exit;

   // check for min/max pitch
   vectoangles (dir, angles);
   if (angles[0] < -180) then
      angles[0] := angles[0] + 360;
   if (fabs(angles[0]) > 45) then
      exit;

   tr := gi.trace (@start, nil, nil, @self^.enemy^.s.origin, self, MASK_SHOT);
   if ((tr.fraction <> 1.0) and (tr.ent <> self^.enemy)) then
      exit;

   if (self^.s.frame = FRAME_attack43) then
   begin
      gi.sound (self^.enemy, CHAN_AUTO, sound_hook_hit, 1, ATTN_NORM, 0);
      self^.enemy^.monsterinfo.aiflags :=self^.enemy^.monsterinfo.aiflags or AI_RESURRECTING;
   end
   else if (self^.s.frame = FRAME_attack50) then
   begin
      self^.enemy^.spawnflags := 0;
      self^.enemy^.monsterinfo.aiflags := 0;
      self^.enemy^.target := nil;
      self^.enemy^.targetname := nil;
      self^.enemy^.combattarget := nil;
      self^.enemy^.deathtarget := nil;
      self^.enemy^.owner := self;
      ED_CallSpawn (self^.enemy);
      self^.enemy^.owner := nil;
      if (@self^.enemy^.think <> nil) then
      begin
         self^.enemy^.nextthink := level.time;
         self^.enemy^.think (self^.enemy);
      end;
      self^.enemy^.monsterinfo.aiflags :=self^.enemy^.monsterinfo.aiflags or AI_RESURRECTING;
      if ((self^.oldenemy<>nil) and (self^.oldenemy^.client<>nil)) then
      begin
         self^.enemy^.enemy := self^.oldenemy;
         FoundTarget (self^.enemy);
      end;
   end
   else
   begin
      if (self^.s.frame = FRAME_attack44) then
         gi.sound (self, CHAN_WEAPON, sound_hook_heal, 1, ATTN_NORM, 0);
   end;

   // adjust start for beam origin being in middle of a segment
   VectorMA (start, 8, f, start);

   // adjust end z for end spot since the monster is currently dead
   VectorCopy (self^.enemy^.s.origin, _end);
   _end[2] := self^.enemy^.absmin[2] + self^.enemy^.size[2] / 2;

   gi.WriteByte (svc_temp_entity);
   gi.WriteByte (Ord(TE_MEDIC_CABLE_ATTACK));
   gi.WriteShort (ShortInt((Cardinal(Self) - Cardinal(g_edicts)) div SizeOf(edict_t)));
   gi.WritePosition (start);
   gi.WritePosition (_end);
   gi.multicast (@self^.s.origin, MULTICAST_PVS);
end;

procedure medic_hook_retract (self:edict_p);
begin
   gi.sound (self, CHAN_WEAPON, sound_hook_retract, 1, ATTN_NORM, 0);
   self^.enemy^.monsterinfo.aiflags := self^.enemy^.monsterinfo.aiflags and (AI_RESURRECTING+1)*(-1);
end;

const
  medic_frames_attackCable : Array[0..27] of mframe_t =
    ((aifunc:ai_move; dist:2;  thinkfunc:nil),
     (aifunc:ai_move; dist:3;  thinkfunc:nil),
     (aifunc:ai_move; dist:5;  thinkfunc:nil),
     (aifunc:ai_move; dist:4.4;  thinkfunc:nil),
     (aifunc:ai_charge; dist:4.7;  thinkfunc:nil),
     (aifunc:ai_charge; dist:5;  thinkfunc:nil),
     (aifunc:ai_charge; dist:6;  thinkfunc:nil),
     (aifunc:ai_charge; dist:4;  thinkfunc:nil),
     (aifunc:ai_charge; dist:0;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;  thinkfunc:medic_hook_launch),
     (aifunc:ai_move; dist:0;  thinkfunc:medic_cable_attack),
     (aifunc:ai_move; dist:0;  thinkfunc:medic_cable_attack),
     (aifunc:ai_move; dist:0;  thinkfunc:medic_cable_attack),
     (aifunc:ai_move; dist:0;  thinkfunc:medic_cable_attack),
     (aifunc:ai_move; dist:0;  thinkfunc:medic_cable_attack),
     (aifunc:ai_move; dist:0;  thinkfunc:medic_cable_attack),
     (aifunc:ai_move; dist:0;  thinkfunc:medic_cable_attack),
     (aifunc:ai_move; dist:0;  thinkfunc:medic_cable_attack),
     (aifunc:ai_move; dist:0;  thinkfunc:medic_cable_attack),
     (aifunc:ai_move; dist:-15;  thinkfunc:medic_hook_retract),
     (aifunc:ai_move; dist:-1.5;  thinkfunc:nil),
     (aifunc:ai_move; dist:-1.2;  thinkfunc:nil),
     (aifunc:ai_move; dist:-3;  thinkfunc:nil),
     (aifunc:ai_move; dist:-2;  thinkfunc:nil),
     (aifunc:ai_move; dist:0.3;  thinkfunc:nil),
     (aifunc:ai_move; dist:0.7;  thinkfunc:nil),
     (aifunc:ai_move; dist:1.2;  thinkfunc:nil),
     (aifunc:ai_move; dist:1.3;  thinkfunc:nil));

medic_move_attackCable : mmove_t =
    (firstframe:FRAME_attack33; lastframe:FRAME_attack60; frame:@medic_frames_attackCable; endfunc:medic_run);


procedure medic_attack(self:edict_p);
begin
   if ((self^.monsterinfo.aiflags and AI_MEDIC) <> 0) then
      self^.monsterinfo.currentmove := @medic_move_attackCable
   else
      self^.monsterinfo.currentmove := @medic_move_attackBlaster;
end;

function medic_checkattack (self:edict_p):qboolean;
begin
   if ((self^.monsterinfo.aiflags) and (AI_MEDIC) <> 0) then
   begin
      medic_attack(self);
      Result := True;
                Exit;
   end;

   Result := M_CheckAttack (self);
end;


(* QUAKED monster_medic (1 .5 0) (-16 -16 -24) (16 16 32) Ambush Trigger_Spawn Sight *)

procedure SP_monster_medic(self:edict_p);
begin
   if (deathmatch^.value<>0.0) then
   begin
      G_FreeEdict (self);
      exit;
   end;

   sound_idle1 := gi.soundindex ('medic/idle.wav');
   sound_pain1 := gi.soundindex ('medic/medpain1.wav');
   sound_pain2 := gi.soundindex ('medic/medpain2.wav');
   sound_die := gi.soundindex ('medic/meddeth1.wav');
   sound_sight := gi.soundindex ('medic/medsght1.wav');
   sound_search := gi.soundindex ('medic/medsrch1.wav');
   sound_hook_launch := gi.soundindex ('medic/medatck2.wav');
   sound_hook_hit := gi.soundindex ('medic/medatck3.wav');
   sound_hook_heal := gi.soundindex ('medic/medatck4.wav');
   sound_hook_retract := gi.soundindex ('medic/medatck5.wav');

   gi.soundindex ('medic/medatck1.wav');

   self^.movetype := MOVETYPE_STEP;
   self^.solid := SOLID_BBOX;
   self^.s.modelindex := gi.modelindex ('models/monsters/medic/tris.md2');
   VectorSet (self^.mins, -24, -24, -24);
   VectorSet (self^.maxs, 24, 24, 32);

   self^.health := 300;
   self^.gib_health := -130;
   self^.mass := 400;

   self^.pain := medic_pain;
   self^.die := medic_die;

   self^.monsterinfo.stand := medic_stand;
   self^.monsterinfo.walk := medic_walk;
   self^.monsterinfo.run := medic_run;
   self^.monsterinfo.dodge := medic_dodge;
   self^.monsterinfo.attack := medic_attack;
   self^.monsterinfo.melee := nil;
   self^.monsterinfo.sight := medic_sight;
   self^.monsterinfo.idle := medic_idle;
   self^.monsterinfo.search := medic_search;
   self^.monsterinfo.checkattack := medic_checkattack;

   gi.linkentity (self);

   self^.monsterinfo.currentmove := @medic_move_stand;
   self^.monsterinfo.scale := MODEL_SCALE;

   walkmonster_start (self);
end;

end.
