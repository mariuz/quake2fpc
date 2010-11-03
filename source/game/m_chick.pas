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
{ File(s): m_chick.c                                                         }
{                                                                            }
{ Initial conversion by : YgriK (Igor Karpov) - glYgriK@hotbox.ru            }
{ Initial conversion on : 12-Feb-2002                                        }
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
{ 1) unit: g_local                                                           }
{ 2) unit: q_shared                                                          }
{ 3) unit: game                                                              }
{ 4) unit: m_flash                                                           }
{                                                                            }
{ .) unit: g_ai                                                              }
{                                                                            }
{ 1) inc:  m_chick                                                           }
{                                                                            }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{ 1) Do more tests                                                           }
{                                                                            }
{----------------------------------------------------------------------------}

{*
==============================================================================

chick

==============================================================================
*}


unit m_chick;

interface

uses g_local;

procedure SP_monster_chick (self : edict_p); cdecl;

implementation

uses q_shared, gameunit, m_flash , g_ai, g_main, g_local_add, game_add,
  g_misc, g_weapon, g_utils, g_monster, CPas;

{$I m_chick.inc}

procedure chick_stand (self : edict_p); cdecl; forward;
procedure chick_run (self : edict_p); cdecl; forward;
procedure chick_reslash (self : edict_p); cdecl; forward;
procedure chick_rerocket (self : edict_p); cdecl; forward;
procedure chick_attack1 (self : edict_p); cdecl; forward;


var
  sound_missile_prelaunch,
  sound_missile_launch,
  sound_melee_swing,
  sound_melee_hit,
  sound_missile_reload,
  sound_death1,
  sound_death2,
  sound_fall_down,
  sound_idle1,
  sound_idle2,
  sound_pain1,
  sound_pain2,
  sound_pain3,
  sound_sight,
  sound_search  : integer;

procedure ChickMoan (self : edict_p); cdecl;
begin
  if (_random() < 0.5) then
    gi.sound (self, CHAN_VOICE, sound_idle1, 1, ATTN_IDLE, 0)
  else
    gi.sound (self, CHAN_VOICE, sound_idle2, 1, ATTN_IDLE, 0);
end;

const
  chick_frames_fidget : array [0..29] of mframe_t = (
    (aifunc: ai_stand;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_stand;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_stand;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_stand;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_stand;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_stand;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_stand;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_stand;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_stand;  dist: 0;  thinkfunc: ChickMoan),
    (aifunc: ai_stand;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_stand;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_stand;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_stand;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_stand;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_stand;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_stand;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_stand;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_stand;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_stand;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_stand;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_stand;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_stand;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_stand;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_stand;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_stand;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_stand;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_stand;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_stand;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_stand;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_stand;  dist: 0;  thinkfunc: Nil) );
  chick_move_fidget : mmove_t = (firstframe: FRAME_stand201;  lastframe: FRAME_stand230;  frame: @chick_frames_fidget;  endfunc: chick_stand);

procedure chick_fidget (self : edict_p); cdecl;
begin
  if (self^.monsterinfo.aiflags AND AI_STAND_GROUND) <> 0 then
     Exit;
  if (_random() <= 0.3) then
    self^.monsterinfo.currentmove := @chick_move_fidget;
end;

const
  chick_frames_stand : array [0..29] of mframe_t = (
    (aifunc: ai_stand;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_stand;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_stand;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_stand;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_stand;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_stand;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_stand;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_stand;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_stand;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_stand;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_stand;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_stand;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_stand;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_stand;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_stand;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_stand;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_stand;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_stand;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_stand;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_stand;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_stand;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_stand;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_stand;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_stand;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_stand;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_stand;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_stand;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_stand;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_stand;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_stand;  dist: 0;  thinkfunc: chick_fidget) );
  chick_move_stand : mmove_t = (firstframe: FRAME_stand101;  lastframe: FRAME_stand130;  frame: @chick_frames_stand;  endfunc: Nil);

procedure chick_stand (self : edict_p);
begin
  self^.monsterinfo.currentmove := @chick_move_stand;
end;

const
  chick_frames_start_run : array [0..9] of mframe_t = (
    (aifunc: ai_run;  dist: 1;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: -1; thinkfunc: Nil),
    (aifunc: ai_run;  dist: -1; thinkfunc: Nil),
    (aifunc: ai_run;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 1;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 3;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 6;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 3;  thinkfunc: Nil) );
  chick_move_start_run : mmove_t = (firstframe: FRAME_walk01;  lastframe: FRAME_walk10;  frame: @chick_frames_start_run;  endfunc: chick_run);

  chick_frames_run : array [0..9] of mframe_t = (
    (aifunc: ai_run;  dist: 6;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 8;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 13; thinkfunc: Nil),
    (aifunc: ai_run;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 7;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 4;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 11; thinkfunc: Nil),
    (aifunc: ai_run;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 9;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 7;  thinkfunc: Nil) );
  chick_move_run : mmove_t = (firstframe: FRAME_walk11;  lastframe: FRAME_walk20;  frame: @chick_frames_run;  endfunc: Nil);

  chick_frames_walk : array [0..9] of mframe_t = (
    (aifunc: ai_walk;  dist: 6;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 8;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 13; thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 7;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 4;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 11; thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 9;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 7;  thinkfunc: Nil) );
  chick_move_walk : mmove_t = (firstframe: FRAME_walk11;  lastframe: FRAME_walk20;  frame: @chick_frames_walk;  endfunc: Nil);

procedure chick_walk (self : edict_p); cdecl;
begin
  self^.monsterinfo.currentmove := @chick_move_walk;
end;

procedure chick_run (self : edict_p); cdecl;
begin
  if (self^.monsterinfo.aiflags AND AI_STAND_GROUND) <> 0 then
  begin
    self^.monsterinfo.currentmove := @chick_move_stand;
    Exit;
  end;

  if (self^.monsterinfo.currentmove = @chick_move_walk) OR (self^.monsterinfo.currentmove = @chick_move_start_run) then
    self^.monsterinfo.currentmove := @chick_move_run
  else
    self^.monsterinfo.currentmove := @chick_move_start_run;
end;

const
  chick_frames_pain1 : array [0..4] of mframe_t = (
    (aifunc: ai_move;  dist: 0; thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0; thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0; thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0; thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0; thinkfunc: Nil) );
  chick_move_pain1 : mmove_t = (firstframe: FRAME_pain101;  lastframe: FRAME_pain105;  frame: @chick_frames_pain1;  endfunc: chick_run);

  chick_frames_pain2 : array [0..4] of mframe_t = (
    (aifunc: ai_move;  dist: 0; thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0; thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0; thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0; thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0; thinkfunc: Nil) );
  chick_move_pain2 : mmove_t = (firstframe: FRAME_pain201;  lastframe: FRAME_pain205;  frame: @chick_frames_pain2;  endfunc: chick_run);

  chick_frames_pain3 : array [0..20] of mframe_t = (
    (aifunc: ai_move;  dist: 0; thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0; thinkfunc: Nil),
    (aifunc: ai_move;  dist: -6; thinkfunc: Nil),
    (aifunc: ai_move;  dist: 3; thinkfunc: Nil),
    (aifunc: ai_move;  dist: 11; thinkfunc: Nil),
    (aifunc: ai_move;  dist: 3; thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0; thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0; thinkfunc: Nil),
    (aifunc: ai_move;  dist: 4; thinkfunc: Nil),
    (aifunc: ai_move;  dist: 1; thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0; thinkfunc: Nil),
    (aifunc: ai_move;  dist: -3; thinkfunc: Nil),
    (aifunc: ai_move;  dist: -4; thinkfunc: Nil),
    (aifunc: ai_move;  dist: 5; thinkfunc: Nil),
    (aifunc: ai_move;  dist: 7; thinkfunc: Nil),
    (aifunc: ai_move;  dist: -2; thinkfunc: Nil),
    (aifunc: ai_move;  dist: 3; thinkfunc: Nil),
    (aifunc: ai_move;  dist: -5; thinkfunc: Nil),
    (aifunc: ai_move;  dist: -2; thinkfunc: Nil),
    (aifunc: ai_move;  dist: -8; thinkfunc: Nil),
    (aifunc: ai_move;  dist: 2; thinkfunc: Nil) );
  chick_move_pain3 : mmove_t = (firstframe: FRAME_pain301;  lastframe: FRAME_pain321;  frame: @chick_frames_pain3;  endfunc: chick_run);

procedure chick_pain (self, other : edict_p; kick : single; damage : integer); cdecl;
var
  r : single;
begin
  if (self^.health < (self^.max_health / 2)) then
    self^.s.skinnum := 1;

  if (level.time < self^.pain_debounce_time) then
    Exit;

  self^.pain_debounce_time := level.time + 3;

  r := _random();
  if (r < 0.33) then
    gi.sound (self, CHAN_VOICE, sound_pain1, 1, ATTN_NORM, 0)
  else if (r < 0.66) then
    gi.sound (self, CHAN_VOICE, sound_pain2, 1, ATTN_NORM, 0)
  else
    gi.sound (self, CHAN_VOICE, sound_pain3, 1, ATTN_NORM, 0);

  if (skill^.value = 3) then
    Exit;   // no pain anims in nightmare

  if (damage <= 10) then
    self^.monsterinfo.currentmove := @chick_move_pain1
  else if (damage <= 25) then
    self^.monsterinfo.currentmove := @chick_move_pain2
  else
    self^.monsterinfo.currentmove := @chick_move_pain3;
end;

procedure chick_dead (self : edict_p); cdecl;
begin
  VectorSet (self^.mins, -16, -16, 0);
  VectorSet (self^.maxs, 16, 16, 16);
  self^.movetype := MOVETYPE_TOSS;
  self^.svflags := self^.svflags OR SVF_DEADMONSTER;
  self^.nextthink := 0;
  gi.linkentity (self);
end;

const
  chick_frames_death2 : array [0..22] of mframe_t = (
    (aifunc: ai_move;  dist: -6; thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: -1; thinkfunc: Nil),
    (aifunc: ai_move;  dist: -5; thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: -1; thinkfunc: Nil),
    (aifunc: ai_move;  dist: -2; thinkfunc: Nil),
    (aifunc: ai_move;  dist: 1;  thinkfunc: Nil), 
    (aifunc: ai_move;  dist: 10; thinkfunc: Nil), 
    (aifunc: ai_move;  dist: 2;  thinkfunc: Nil), 
    (aifunc: ai_move;  dist: 3;  thinkfunc: Nil), 
    (aifunc: ai_move;  dist: 1;  thinkfunc: Nil), 
    (aifunc: ai_move;  dist: 2;  thinkfunc: Nil), 
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil), 
    (aifunc: ai_move;  dist: 3;  thinkfunc: Nil), 
    (aifunc: ai_move;  dist: 3;  thinkfunc: Nil), 
    (aifunc: ai_move;  dist: 1;  thinkfunc: Nil), 
    (aifunc: ai_move;  dist: -3; thinkfunc: Nil),
    (aifunc: ai_move;  dist: -5; thinkfunc: Nil),
    (aifunc: ai_move;  dist: 4;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 15; thinkfunc: Nil),
    (aifunc: ai_move;  dist: 14; thinkfunc: Nil),
    (aifunc: ai_move;  dist: 1;  thinkfunc: Nil) );
  chick_move_death2 : mmove_t = (firstframe: FRAME_death201;  lastframe: FRAME_death223;  frame: @chick_frames_death2;  endfunc: chick_dead);

  chick_frames_death1 : array [0..11] of mframe_t = (
    (aifunc: ai_move;  dist: 0; thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0; thinkfunc: Nil),
    (aifunc: ai_move;  dist: -7; thinkfunc: Nil),
    (aifunc: ai_move;  dist: 4; thinkfunc: Nil),
    (aifunc: ai_move;  dist: 11; thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0; thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0; thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0; thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0; thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0; thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0; thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0; thinkfunc: Nil) );
  chick_move_death1 : mmove_t = (firstframe: FRAME_death101;  lastframe: FRAME_death112;  frame: @chick_frames_death1;  endfunc: chick_dead);

procedure chick_die (self, inflictor, attacker : edict_p; damage : integer; const point : vec3_t); cdecl;
var
  n : Integer;
begin
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
    Exit;
  end;

  if (self^.deadflag = DEAD_DEAD) then
    Exit;

// regular death
  self^.deadflag := DEAD_DEAD;
  self^.takedamage := DAMAGE_YES;

  n := rand() mod 2;
  if (n = 0) then
  begin
    self^.monsterinfo.currentmove := @chick_move_death1;
    gi.sound (self, CHAN_VOICE, sound_death1, 1, ATTN_NORM, 0);
  end
  else
  begin
    self^.monsterinfo.currentmove := @chick_move_death2;
    gi.sound (self, CHAN_VOICE, sound_death2, 1, ATTN_NORM, 0);
  end;
end;


procedure chick_duck_down (self : edict_p); cdecl;
begin
  if (self^.monsterinfo.aiflags AND AI_DUCKED) <> 0 then
    Exit;
  self^.monsterinfo.aiflags := self^.monsterinfo.aiflags OR AI_DUCKED;
  self^.maxs[2] := self^.maxs[2] - 32;
  self^.takedamage := DAMAGE_YES;
  self^.monsterinfo.pausetime := level.time + 1;
  gi.linkentity (self);
end;

procedure chick_duck_hold (self : edict_p); cdecl;
begin
  if (level.time >= self^.monsterinfo.pausetime) then
    self^.monsterinfo.aiflags := self^.monsterinfo.aiflags AND (NOT AI_HOLD_FRAME)
  else
    self^.monsterinfo.aiflags := self^.monsterinfo.aiflags OR AI_HOLD_FRAME;
end;

procedure chick_duck_up (self : edict_p); cdecl;
begin
  self^.monsterinfo.aiflags := self^.monsterinfo.aiflags AND (NOT AI_DUCKED);
  self^.maxs[2] := self^.maxs[2] + 32;
  self^.takedamage := DAMAGE_AIM;
  gi.linkentity (self);
end;

const
  chick_frames_duck : array [0..6] of mframe_t = (
    (aifunc: ai_move;  dist: 0;  thinkfunc: chick_duck_down),
    (aifunc: ai_move;  dist: 1;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 4;  thinkfunc: chick_duck_hold),
    (aifunc: ai_move;  dist: -4; thinkfunc: Nil),
    (aifunc: ai_move;  dist: -5; thinkfunc: chick_duck_up),
    (aifunc: ai_move;  dist: 3;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 1;  thinkfunc: Nil) );
  chick_move_duck : mmove_t = (firstframe: FRAME_duck01;  lastframe: FRAME_duck07;  frame: @chick_frames_duck;  endfunc: chick_run);


procedure chick_dodge (self, attacker : edict_p; eta : single); cdecl;
begin
  if (_random() > 0.25) then
    Exit;

  if (self^.enemy = Nil) then
    self^.enemy := attacker;

  self^.monsterinfo.currentmove := @chick_move_duck;
end;

procedure ChickSlash (self : edict_p); cdecl;
var
  aim : vec3_t;
begin
  VectorSet (aim, MELEE_DISTANCE, self^.mins[0], 10);
  gi.sound (self, CHAN_WEAPON, sound_melee_swing, 1, ATTN_NORM, 0);
  fire_hit (self, aim, (10 + (rand() mod 6)), 100);
end;


procedure ChickRocket (self : edict_p); cdecl;
var
  forward_, right,
  start,
  dir,
  vec  : vec3_t;
begin
  AngleVectors (self^.s.angles, @forward_, @right, Nil);
  G_ProjectSource (self^.s.origin, monster_flash_offset[MZ2_CHICK_ROCKET_1], forward_, right, start);

  VectorCopy (self^.enemy^.s.origin, vec);
  vec[2] := vec[2] + self^.enemy^.viewheight;
  VectorSubtract (vec, start, dir);
  VectorNormalize (dir);

  monster_fire_rocket (self, start, dir, 50, 500, MZ2_CHICK_ROCKET_1);
end;

procedure Chick_PreAttack1 (self : edict_p); cdecl;
begin
  gi.sound (self, CHAN_VOICE, sound_missile_prelaunch, 1, ATTN_NORM, 0);
end;

procedure ChickReload (self : edict_p); cdecl;
begin
  gi.sound (self, CHAN_VOICE, sound_missile_reload, 1, ATTN_NORM, 0);
end;

const
  chick_frames_start_attack1 : array [0..12] of mframe_t = (
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Chick_PreAttack1),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),    
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),    
    (aifunc: ai_charge;  dist: 4;  thinkfunc: Nil),    
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),    
    (aifunc: ai_charge;  dist: -3; thinkfunc: Nil),  
    (aifunc: ai_charge;  dist: 3;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 7;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: chick_attack1) );
  chick_move_start_attack1 : mmove_t = (firstframe: FRAME_attak101;  lastframe:  FRAME_attak113;  frame: @chick_frames_start_attack1;  endfunc: Nil);


  chick_frames_attack1 : array [0..13] of mframe_t = (
    (aifunc: ai_charge;  dist: 19; thinkfunc: ChickRocket),
    (aifunc: ai_charge;  dist: -6; thinkfunc: Nil),    
    (aifunc: ai_charge;  dist: -5; thinkfunc: Nil),    
    (aifunc: ai_charge;  dist: -2; thinkfunc: Nil),    
    (aifunc: ai_charge;  dist: -7; thinkfunc: Nil),    
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),    
    (aifunc: ai_charge;  dist: 1;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 10; thinkfunc: ChickReload),
    (aifunc: ai_charge;  dist: 4;  thinkfunc: Nil),    
    (aifunc: ai_charge;  dist: 5;  thinkfunc: Nil),    
    (aifunc: ai_charge;  dist: 6;  thinkfunc: Nil),    
    (aifunc: ai_charge;  dist: 6;  thinkfunc: Nil),    
    (aifunc: ai_charge;  dist: 4;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 3;  thinkfunc: chick_rerocket) );
  chick_move_attack1 : mmove_t = (firstframe: FRAME_attak114;  lastframe: FRAME_attak127;  frame: @chick_frames_attack1;  endfunc: Nil);


  chick_frames_end_attack1 : array [0..4] of mframe_t = (
    (aifunc: ai_charge;  dist: -3; thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: -6; thinkfunc: Nil),
    (aifunc: ai_charge;  dist: -4; thinkfunc: Nil),
    (aifunc: ai_charge;  dist: -2; thinkfunc: Nil) );
  chick_move_end_attack1 : mmove_t = (firstframe: FRAME_attak128;  lastframe: FRAME_attak132;  frame: @chick_frames_end_attack1;  endfunc: chick_run);

procedure chick_rerocket (self : edict_p); cdecl;
begin
  if (self^.enemy^.health > 0) then
  begin
    if range (self, self^.enemy) > RANGE_MELEE then
      if visible (self, self^.enemy) then
        if (_random() <= 0.6) then
        begin
          self^.monsterinfo.currentmove := @chick_move_attack1;
          Exit;
        end;
  end;
  self^.monsterinfo.currentmove := @chick_move_end_attack1;
end;

procedure chick_attack1 (self : edict_p); cdecl;
begin
  self^.monsterinfo.currentmove := @chick_move_attack1;
end;

const
  chick_frames_slash : array [0..8] of mframe_t = (
    (aifunc: ai_charge;  dist: 1;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 7;  thinkfunc: ChickSlash),
    (aifunc: ai_charge;  dist: -7; thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 1;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: -1; thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 1;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 1;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: -2; thinkfunc: chick_reslash) );
  chick_move_slash : mmove_t = (firstframe: FRAME_attak204;  lastframe: FRAME_attak212;  frame: @chick_frames_slash;  endfunc: Nil);


  chick_frames_end_slash : array [0..3] of mframe_t = (
    (aifunc: ai_charge;  dist: -6; thinkfunc: Nil),
    (aifunc: ai_charge;  dist: -1; thinkfunc: Nil),
    (aifunc: ai_charge;  dist: -6; thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil) );
  chick_move_end_slash : mmove_t = (firstframe: FRAME_attak213;  lastframe: FRAME_attak216;  frame: @chick_frames_end_slash;  endfunc: chick_run);


procedure chick_reslash (self : edict_p); cdecl;
begin
  if (self^.enemy^.health > 0) then
  begin
    if (range (self, self^.enemy) = RANGE_MELEE) then
      if (_random() <= 0.9) then
      begin
        self^.monsterinfo.currentmove := @chick_move_slash;
        Exit;
      end
      else
      begin
        self^.monsterinfo.currentmove := @chick_move_end_slash;
        Exit;
      end;
  end;
  self^.monsterinfo.currentmove := @chick_move_end_slash;
end;

procedure chick_slash (self : edict_p); cdecl;
begin
  self^.monsterinfo.currentmove := @chick_move_slash;
end;

const
  chick_frames_start_slash : array [0..2] of mframe_t = (
    (aifunc: ai_charge;  dist: 1;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 8;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 3;  thinkfunc: Nil) );
  chick_move_start_slash : mmove_t = (firstframe: FRAME_attak201;  lastframe: FRAME_attak203;  frame: @chick_frames_start_slash;  endfunc: chick_slash);


procedure chick_melee (self : edict_p); cdecl;
begin
  self^.monsterinfo.currentmove := @chick_move_start_slash;
end;


procedure chick_attack (self : edict_p); cdecl;
begin
  self^.monsterinfo.currentmove := @chick_move_start_attack1;
end;

procedure chick_sight (self, other : edict_p); cdecl;
begin
  gi.sound (self, CHAN_VOICE, sound_sight, 1, ATTN_NORM, 0);
end;

{*QUAKED monster_chick (1 .5 0) (-16 -16 -24) (16 16 32) Ambush Trigger_Spawn Sight
*}
procedure SP_monster_chick (self : edict_p);
begin
  if (deathmatch^.value <> 0) then
  begin
    G_FreeEdict (self);
    Exit;
  end;

  sound_missile_prelaunch := gi.soundindex ('chick/chkatck1.wav');
  sound_missile_launch   := gi.soundindex ('chick/chkatck2.wav');
  sound_melee_swing := gi.soundindex ('chick/chkatck3.wav');
  sound_melee_hit := gi.soundindex ('chick/chkatck4.wav');
  sound_missile_reload   := gi.soundindex ('chick/chkatck5.wav');
  sound_death1 := gi.soundindex ('chick/chkdeth1.wav');
  sound_death2 := gi.soundindex ('chick/chkdeth2.wav');
  sound_fall_down := gi.soundindex ('chick/chkfall1.wav');
  sound_idle1 := gi.soundindex ('chick/chkidle1.wav');
  sound_idle2 := gi.soundindex ('chick/chkidle2.wav');
  sound_pain1 := gi.soundindex ('chick/chkpain1.wav');
  sound_pain2 := gi.soundindex ('chick/chkpain2.wav');
  sound_pain3 := gi.soundindex ('chick/chkpain3.wav');
  sound_sight := gi.soundindex ('chick/chksght1.wav');
  sound_search := gi.soundindex ('chick/chksrch1.wav');

  self^.movetype := MOVETYPE_STEP;
  self^.solid := SOLID_BBOX;
  self^.s.modelindex := gi.modelindex ('models/monsters/bitch/tris.md2');
  VectorSet (self^.mins, -16, -16, 0);
  VectorSet (self^.maxs, 16, 16, 56);

  self^.health := 175;
  self^.gib_health := -70;
  self^.mass := 200;

  self^.pain := chick_pain;
  self^.die := chick_die;

  self^.monsterinfo.stand := chick_stand;
  self^.monsterinfo.walk := chick_walk;
  self^.monsterinfo.run := chick_run;
  self^.monsterinfo.dodge := chick_dodge;
  self^.monsterinfo.attack := chick_attack;
  self^.monsterinfo.melee := chick_melee;
  self^.monsterinfo.sight := chick_sight;

  gi.linkentity (self);

  self^.monsterinfo.currentmove := @chick_move_stand;
  self^.monsterinfo.scale := MODEL_SCALE;

  walkmonster_start (self);
end;

end.

