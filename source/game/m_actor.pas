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
{ File(s): asm_i386.h                                                        }
{                                                                            }
{ Initial conversion by : Jan Horn (jhorn@global.co.za)                      }
{ Initial conversion on : 12-Jan-2002                                        }
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
{ 2.) Validate converted items.  Some routines were converted as if STATIC   }
{     which was incorrect.  Tried to make visible all that needed to be but  }
{     would still benefit from an additional set of eyes.                    }
{----------------------------------------------------------------------------}

unit m_actor;

interface

uses
  q_shared_add,
  g_local_add,
  g_ai;

const MAX_ACTOR_NAMES = 8;

{$I m_actor.inc}

const actor_names : Array[0..MAX_ACTOR_NAMES-1] of PChar=(
   'Hellrot',
   'Tokay',
   'Killme',
   'Disruptor',
   'Adrianator',
   'Rambear',
   'Titus',
   'Bitterman'
);

procedure actor_stand(self : edict_p); cdecl;
procedure actor_walk(self : edict_p); cdecl;
procedure actor_run(self : edict_p); cdecl;
procedure actor_dead(self : edict_p); cdecl;
procedure actor_die(self, inflictor, attacker: edict_p; damage: Integer; const point: vec3_t); cdecl;
procedure actor_fire(self : edict_p); cdecl;

const actor_frames_stand : Array[0..39] of mframe_t = (
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
      actor_move_stand : mmove_t = (firstframe:FRAME_stand101; lastframe:FRAME_stand140; frame:@actor_frames_stand; endfunc:nil);

const actor_frames_walk : Array[0..10] of mframe_t = (
        (aifunc:ai_walk; dist:0;  thinkfunc:nil),
   (aifunc:ai_walk; dist:6;  thinkfunc:nil),
   (aifunc:ai_walk; dist:10; thinkfunc:nil),
   (aifunc:ai_walk; dist:3;  thinkfunc:nil),
   (aifunc:ai_walk; dist:2;  thinkfunc:nil),
   (aifunc:ai_walk; dist:7;  thinkfunc:nil),
   (aifunc:ai_walk; dist:10; thinkfunc:nil),
   (aifunc:ai_walk; dist:1;  thinkfunc:nil),
   (aifunc:ai_walk; dist:4;  thinkfunc:nil),
   (aifunc:ai_walk; dist:0;  thinkfunc:nil),
   (aifunc:ai_walk; dist:0;  thinkfunc:nil));
      actor_move_walk : mmove_t = (firstframe:FRAME_walk01; lastframe:FRAME_walk08; frame:@actor_frames_walk; endfunc:nil);

const actor_frames_run : Array[0..11] of mframe_t = (
        (aifunc:ai_run; dist:4;  thinkfunc:nil),
        (aifunc:ai_run; dist:15; thinkfunc:nil),
   (aifunc:ai_run; dist:15; thinkfunc:nil),
   (aifunc:ai_run; dist:8;  thinkfunc:nil),
   (aifunc:ai_run; dist:20; thinkfunc:nil),
   (aifunc:ai_run; dist:15; thinkfunc:nil),
   (aifunc:ai_run; dist:8;  thinkfunc:nil),
   (aifunc:ai_run; dist:17; thinkfunc:nil),
   (aifunc:ai_run; dist:12; thinkfunc:nil),
   (aifunc:ai_run; dist:-2; thinkfunc:nil),
   (aifunc:ai_run; dist:-2; thinkfunc:nil),
   (aifunc:ai_run; dist:-1; thinkfunc:nil));
      actor_move_run : mmove_t = (firstframe:FRAME_run02; lastframe:FRAME_run07; frame:@actor_frames_run; endfunc:nil);

const actor_frames_pain1 : Array[0..2] of mframe_t = (
   (aifunc:ai_move; dist:-5; thinkfunc:nil),
   (aifunc:ai_move; dist:4;  thinkfunc:nil),
   (aifunc:ai_move; dist:1;  thinkfunc:nil));
      actor_move_pain1 : mmove_t = (firstframe:FRAME_pain101; lastframe:FRAME_pain103; frame:@actor_frames_pain1; endfunc:actor_run);

const actor_frames_pain2 : Array[0..2] of mframe_t = (
   (aifunc:ai_move; dist:-4; thinkfunc:nil),
   (aifunc:ai_move; dist:4;  thinkfunc:nil),
   (aifunc:ai_move; dist:0;  thinkfunc:nil));
      actor_move_pain2 : mmove_t = (firstframe:FRAME_pain201; lastframe:FRAME_pain203; frame:@actor_frames_pain2; endfunc:actor_run);

const actor_frames_pain3 : Array[0..2] of mframe_t = (
   (aifunc:ai_move; dist:-1; thinkfunc:nil),
   (aifunc:ai_move; dist:1;  thinkfunc:nil),
   (aifunc:ai_move; dist:0;  thinkfunc:nil));
      actor_move_pain3 : mmove_t = (firstframe:FRAME_pain301; lastframe:FRAME_pain303; frame:@actor_frames_pain3; endfunc:actor_run);

const actor_frames_flipoff : Array[0..13] of mframe_t = (
   (aifunc:ai_turn; dist:0; thinkfunc:nil),
   (aifunc:ai_turn; dist:0; thinkfunc:nil),
   (aifunc:ai_turn; dist:0; thinkfunc:nil),
   (aifunc:ai_turn; dist:0; thinkfunc:nil),
   (aifunc:ai_turn; dist:0; thinkfunc:nil),
   (aifunc:ai_turn; dist:0; thinkfunc:nil),
   (aifunc:ai_turn; dist:0; thinkfunc:nil),
   (aifunc:ai_turn; dist:0; thinkfunc:nil),
   (aifunc:ai_turn; dist:0; thinkfunc:nil),
   (aifunc:ai_turn; dist:0; thinkfunc:nil),
   (aifunc:ai_turn; dist:0; thinkfunc:nil),
   (aifunc:ai_turn; dist:0; thinkfunc:nil),
   (aifunc:ai_turn; dist:0; thinkfunc:nil),
   (aifunc:ai_turn; dist:0; thinkfunc:nil));
      actor_move_flipoff : mmove_t = (firstframe:FRAME_flip01; lastframe:FRAME_flip14; frame:@actor_frames_flipoff; endfunc:actor_run);

const actor_frames_taunt : Array[0..16] of mframe_t = (
   (aifunc:ai_turn; dist:0; thinkfunc:nil),
   (aifunc:ai_turn; dist:0; thinkfunc:nil),
   (aifunc:ai_turn; dist:0; thinkfunc:nil),
   (aifunc:ai_turn; dist:0; thinkfunc:nil),
   (aifunc:ai_turn; dist:0; thinkfunc:nil),
   (aifunc:ai_turn; dist:0; thinkfunc:nil),
   (aifunc:ai_turn; dist:0; thinkfunc:nil),
   (aifunc:ai_turn; dist:0; thinkfunc:nil),
   (aifunc:ai_turn; dist:0; thinkfunc:nil),
   (aifunc:ai_turn; dist:0; thinkfunc:nil),
   (aifunc:ai_turn; dist:0; thinkfunc:nil),
   (aifunc:ai_turn; dist:0; thinkfunc:nil),
   (aifunc:ai_turn; dist:0; thinkfunc:nil),
   (aifunc:ai_turn; dist:0; thinkfunc:nil),
   (aifunc:ai_turn; dist:0; thinkfunc:nil),
   (aifunc:ai_turn; dist:0; thinkfunc:nil),
   (aifunc:ai_turn; dist:0; thinkfunc:nil));
      actor_move_taunt : mmove_t = (firstframe:FRAME_taunt01; lastframe:FRAME_taunt17; frame:@actor_frames_taunt; endfunc:actor_run);

const actor_frames_death1 : Array[0..6] of mframe_t = (
        (aifunc:ai_move; dist:0;  thinkfunc:nil),
        (aifunc:ai_move; dist:0;  thinkfunc:nil),
        (aifunc:ai_move; dist:-13;thinkfunc:nil),
        (aifunc:ai_move; dist:14; thinkfunc:nil),
        (aifunc:ai_move; dist:3;  thinkfunc:nil),
        (aifunc:ai_move; dist:-2; thinkfunc:nil),
        (aifunc:ai_move; dist:1;  thinkfunc:nil));
      actor_move_death1 : mmove_t = (firstframe:FRAME_death101; lastframe:FRAME_death107; frame:@actor_frames_death1; endfunc:actor_dead);

const actor_frames_death2 : Array[0..12] of mframe_t = (
        (aifunc:ai_move; dist:0;   thinkfunc:nil),
        (aifunc:ai_move; dist:7;   thinkfunc:nil),
        (aifunc:ai_move; dist:-6;  thinkfunc:nil),
        (aifunc:ai_move; dist:-5;  thinkfunc:nil),
        (aifunc:ai_move; dist:1;   thinkfunc:nil),
        (aifunc:ai_move; dist:0;   thinkfunc:nil),
        (aifunc:ai_move; dist:-1;  thinkfunc:nil),
        (aifunc:ai_move; dist:-2;  thinkfunc:nil),
        (aifunc:ai_move; dist:-1;  thinkfunc:nil),
        (aifunc:ai_move; dist:-9;  thinkfunc:nil),
        (aifunc:ai_move; dist:-13; thinkfunc:nil),
        (aifunc:ai_move; dist:-13; thinkfunc:nil),
        (aifunc:ai_move; dist:0;   thinkfunc:nil));
      actor_move_death2 : mmove_t = (firstframe:FRAME_death201; lastframe:FRAME_death213; frame:@actor_frames_death2; endfunc:actor_dead);

const actor_frames_attack : Array[0..3] of mframe_t = (
   (aifunc:ai_charge; dist:-2; thinkfunc:actor_fire),
   (aifunc:ai_charge; dist:-2; thinkfunc:nil),
   (aifunc:ai_charge; dist:3;  thinkfunc:nil),
   (aifunc:ai_charge; dist:2;  thinkfunc:nil));
      actor_move_attack : mmove_t = (firstframe:FRAME_attak01; lastframe:FRAME_attak04; frame:@actor_frames_attack; endfunc:actor_run);

const messages : Array[0..3] of PChar = (
          'Watch it', '#$@*&', 'Idiot','Check your targets');

procedure actor_attack(self : edict_p); cdecl;
procedure actor_use(self, other, activator : edict_p); cdecl;
procedure SP_misc_actor(self : edict_p); cdecl;
procedure target_actor_touch(self, other: edict_p; plane: cplane_p; surf: csurface_p); cdecl;
procedure SP_target_actor(self: edict_p); cdecl;


implementation

uses
  q_shared,
  g_utils,
  g_main,
  m_flash,
  g_monster,
  g_local,
  GameUnit,
  g_misc,
  CPas,
  game_add;

procedure actor_stand(self : edict_p);
begin
  self^.monsterinfo.currentmove := @actor_move_stand;
  // randomize on startup
  if (level.time < 1.0) then
    self^.s.frame := self^.monsterinfo.currentmove^.firstframe + (rand() mod (self^.monsterinfo.currentmove^.lastframe - self^.monsterinfo.currentmove^.firstframe + 1));
end;


procedure actor_walk(self : edict_p);
begin
  self^.monsterinfo.currentmove := @actor_move_walk;
end;

procedure actor_run(self : edict_p);
begin
  if ((level.time < self^.pain_debounce_time) AND (self.enemy = nil)) then
  begin
    if (self^.movetarget <> nil) then
      actor_walk(self)
    else
      actor_stand(self);
    Exit;
  end;

  if (self^.monsterinfo.aiflags AND AI_STAND_GROUND) <> 0 then
  begin
    actor_stand(self);
    Exit;
  end;

  self^.monsterinfo.currentmove := @actor_move_run;
end;


procedure actor_pain(self, other : edict_p; kick : single; damage : Integer); cdecl;
var n : Integer;
    v : vec3_t;
    name : PChar;
begin
  if self^.health < (self^.max_health / 2) then
    self^.s.skinnum := 1;

  if level.time < self^.pain_debounce_time then
    Exit;

  self^.pain_debounce_time := level.time + 3;
//   gi.sound (self, CHAN_VOICE, actor.sound_pain, 1, ATTN_NORM, 0);

  if (other^.client <> nil) AND (_random() < 0.4) then
  begin
    VectorSubtract(other^.s.origin, self^.s.origin, v);
    self^.ideal_yaw := vectoyaw(v);
    if (_random() < 0.5) then
      self^.monsterinfo.currentmove := @actor_move_flipoff
    else
      self^.monsterinfo.currentmove := @actor_move_taunt;
    name := actor_names[Cardinal(Self) - Cardinal(g_edicts) MOD MAX_ACTOR_NAMES];   //(self - g_edicts)%MAX_ACTOR_NAMES
    { TODO:  Original:  gi.cprintf (other, PRINT_CHAT, "%s: %s!\n", name, messages[rand()%3]); }
    gi.cprintf(other, PRINT_CHAT, '%s: %s!'#10, name, messages[rand() mod 3]);
    Exit;
  end;

  n := rand() mod 3;
  if n = 0 then
    self^.monsterinfo.currentmove := @actor_move_pain1
  else if n = 1 then
    self^.monsterinfo.currentmove := @actor_move_pain2
  else
    self^.monsterinfo.currentmove := @actor_move_pain3;
end;


procedure actorMachineGun(self : edict_p);
var start, target  : vec3_t;
    fforward, right : vec3_t;
begin
  AngleVectors(self^.s.angles, @fforward, @right, nil);
  G_ProjectSource(self^.s.origin, monster_flash_offset[MZ2_ACTOR_MACHINEGUN_1], fforward, right, start);
  if (self^.enemy <> nil) then
  begin
    if (self^.enemy^.health > 0) then
    begin
      VectorMA(self^.enemy^.s.origin, -0.2, self^.enemy^.velocity, target);
      target[2] := target[2] + self^.enemy^.viewheight;
    end
    else
    begin
      VectorCopy(self^.enemy^.absmin, target);
      target[2] := target[2] + (self^.enemy^.size[2] / 2);
    end;
    VectorSubtract(target, start, fforward);
    VectorNormalize(fforward);
  end
  else
    AngleVectors(self^.s.angles, @fforward, Nil, Nil);

  monster_fire_bullet(self, start, fforward, 3, 4, DEFAULT_BULLET_HSPREAD, DEFAULT_BULLET_VSPREAD, MZ2_ACTOR_MACHINEGUN_1);
end;


procedure actor_dead(self : edict_p);
begin
  VectorSet(self^.mins, -16, -16, -24);
  VectorSet(self^.maxs, 16, 16, -8);
  self^.movetype := MOVETYPE_TOSS;
  self^.svflags := (self^.svflags OR SVF_DEADMONSTER);
  self^.nextthink := 0;
  gi.linkentity(self);
end;


procedure actor_die(self, inflictor, attacker : edict_p; damage : Integer; const point : vec3_t); cdecl;
var n : Integer;
begin
  // check for gib
  if self.health <= -80 then
  begin
    for n := 0 to (2 - 1) do
      ThrowGib(self, 'models/objects/gibs/bone/tris.md2', damage, GIB_ORGANIC);
    for n := 0 to (4 - 1) do
      ThrowGib(self, 'models/objects/gibs/sm_meat/tris.md2', damage, GIB_ORGANIC);
    ThrowHead(self, 'models/objects/gibs/head2/tris.md2', damage, GIB_ORGANIC);
    self^.deadflag := DEAD_DEAD;
    Exit;
  end;

  if (self.deadflag = DEAD_DEAD) then
    Exit;

  // regular death
  self^.deadflag := DEAD_DEAD;
  self^.takedamage := DAMAGE_YES;

  n := rand() mod 2;
  if n = 0 then
    self^.monsterinfo.currentmove := @actor_move_death1
  else
    self^.monsterinfo.currentmove := @actor_move_death2;
end;


procedure actor_fire(self : edict_p);
begin
  actorMachineGun(self);

  if (level.time >= self^.monsterinfo.pausetime) then
    self^.monsterinfo.aiflags := (self^.monsterinfo.aiflags AND not AI_HOLD_FRAME)
  else
    self^.monsterinfo.aiflags := (self^.monsterinfo.aiflags OR AI_HOLD_FRAME);
end;


procedure actor_attack(self : edict_p); cdecl;
var n : Integer;
begin
  self^.monsterinfo.currentmove := @actor_move_attack;
  n := (rand() AND 15) + 3 + 7;    // (rand() & 15) + 3 + 7
  self^.monsterinfo.pausetime := level.time + n * FRAMETIME;
end;


procedure actor_use(self, other, activator : edict_p); cdecl;
var v : vec3_t;
begin
  self^.movetarget := G_PickTarget(self.target);
  self^.goalentity := self^.movetarget;

  if (self^.movetarget = Nil) OR (StrCmp(self^.movetarget^.classname, 'target_actor') <> 0) then
  begin
    gi.dprintf('%s has bad target %s at %s'#10, self^.classname, self^.target, vtos(self^.s.origin));
    self^.target := nil;
    self^.monsterinfo.pausetime := 100000000;
    self^.monsterinfo.stand(self);
    Exit;
  end;

  VectorSubtract(self^.goalentity^.s.origin, self^.s.origin, v);
  self^.s.angles[YAW] := vectoyaw(v);
  self^.ideal_yaw := self^.s.angles[YAW];
  self^.monsterinfo.walk(self);
  self^.target := nil;
end;


// QUAKED misc_actor (1 .5 0) (-16 -16 -24) (16 16 32)

procedure SP_misc_actor(self : edict_p);
begin
  if (deathmatch^.Value <> 0) then
  begin
    G_FreeEdict(self);
    Exit;
  end;

  if (self^.targetname = Nil) then
  begin
    gi.dprintf('untargeted %s at %s'#10, self^.classname, vtos(self^.s.origin));
    G_FreeEdict(self);
    Exit;
  end;

  if (self.target = Nil) then
  begin
    gi.dprintf('%s with no target at %s'#10, self^.classname, vtos(self^.s.origin));
    G_FreeEdict(self);
    Exit;
  end;

  self^.movetype := MOVETYPE_STEP;
  self^.solid := SOLID_BBOX;
  self^.s.modelindex := gi.modelindex('players/male/tris.md2');
  VectorSet(self^.mins, -16, -16, -24);
  VectorSet(self^.maxs, 16, 16, 32);

  if (self^.health = 0) then
    self^.health := 100;
  self^.mass := 200;

  self^.pain := actor_pain;
  self^.die := actor_die;

  self^.monsterinfo.stand := actor_stand;
  self^.monsterinfo.walk := actor_walk;
  self^.monsterinfo.run := actor_run;
  self^.monsterinfo.attack := actor_attack;
  self^.monsterinfo.melee := nil;
  self^.monsterinfo.sight := nil;

  self^.monsterinfo.aiflags := (self^.monsterinfo.aiflags OR AI_GOOD_GUY);

  gi.linkentity(self);

  self^.monsterinfo.currentmove := @actor_move_stand;
  self^.monsterinfo.scale := MODEL_SCALE;

  walkmonster_start(self);

  // actors always start in a dormant state, they *must* be used to get going
  self^.use := actor_use;
end;

{ TODO:  From here down }
{
QUAKED target_actor (.5 .3 0) (-8 -8 -8) (8 8 8) JUMP SHOOT ATTACK x HOLD BRUTAL
JUMP             jump in set direction upon reaching this target
SHOOT             take a single shot at the pathtarget
ATTACK             attack pathtarget until it or actor is dead

"target"          next target_actor
"pathtarget"    target of any action to be taken at this point
"wait"             amount of time actor should pause at this point
"message"         actor will "say" this to the player

for JUMP only:
"speed"             speed thrown forward (default 200)
"height"          speed thrown upwards (default 200)
}

procedure target_actor_touch(self, other: edict_p; plane: cplane_p; surf: csurface_p); cdecl;
var v : vec3_t;
    n : Integer;
    ent : edict_p;
    savetarget : PChar;
begin
  if (other^.movetarget <> self) then
    Exit;

  if (other^.enemy <> nil) then
    Exit;

  other^.movetarget := nil;
  other^.goalentity := other^.movetarget;

  if (self^._message <> Nil) then
  begin
    for n := 1 to game.maxclients do
    begin
      ent := @g_edicts[n];
      if ent^.inuse then
        gi.cprintf(ent, PRINT_CHAT, '%s: %s'#10, actor_names[(Cardinal(other) - Cardinal(g_edicts)) MOD MAX_ACTOR_NAMES], self._message);
    end;
  end;

  if (self^.spawnflags AND 1) <> 0 then      //jump
  begin
    other^.velocity[0] := self^.movedir[0] * self^.speed;
    other^.velocity[1] := self^.movedir[1] * self^.speed;

    if (other^.groundentity <> Nil) then
    begin
      other^.groundentity := nil;
      other^.velocity[2]  := self^.movedir[2];
      gi.sound(other, CHAN_VOICE, gi.soundindex('player/male/jump1.wav'), 1, ATTN_NORM, 0);
    end;
  end;

  if (self^.spawnflags AND 2) <> 0 then              //shoot
  begin
  end
  else if (self^.spawnflags AND 4) <> 0 then            //attack
  begin
    other^.enemy := G_PickTarget(self^.pathtarget);
    if (other^.enemy <> Nil) then
    begin
      other^.goalentity := other^.enemy;
      if (self^.spawnflags AND 32) <> 0 then
        other^.monsterinfo.aiflags := (other^.monsterinfo.aiflags OR AI_BRUTAL);
      if (self.spawnflags AND 16) <> 0 then
      begin
        other^.monsterinfo.aiflags := (other^.monsterinfo.aiflags OR AI_STAND_GROUND);
        actor_stand(other);
      end
      else
        actor_run(other);
    end;
  end;

  if (((self^.spawnflags AND 6) = 0) AND (self^.pathtarget <> ''))   then
  begin
    savetarget := self^.target;
    self^.target := self^.pathtarget;
    G_UseTargets(self, other);
    self^.target := savetarget;
  end;

  other^.movetarget := G_PickTarget(self^.target);

  if (other^.goalentity = Nil) then
    other^.goalentity := other^.movetarget;

  if ((other^.movetarget = Nil) AND (other^.enemy = Nil)) then
  begin
    other^.monsterinfo.pausetime := level.time + 100000000;
    other^.monsterinfo.stand(other);
  end
  else if (other^.movetarget = other^.goalentity) then
  begin
    VectorSubtract(other^.movetarget^.s.origin, other^.s.origin, v);
    other^.ideal_yaw := vectoyaw(v);
  end;
end;


procedure SP_target_actor(self: edict_p);
begin
  if (self^.targetname = nil) then
    gi.dprintf('%s with no targetname at %s'#10, self^.classname, vtos(self^.s.origin));

  self^.solid := SOLID_TRIGGER;
  self^.touch := target_actor_touch;
  VectorSet(self^.mins, -8, -8, -8);
  VectorSet(self^.maxs, 8, 8, 8);
  self^.svflags := SVF_NOCLIENT;

  if (self^.spawnflags AND 1) <> 0 then
  begin
    if self^.speed = 0 then
      self^.speed := 200;
    if st.height = 0 then
      st.height := 200;
    if (self^.s.angles[YAW] = 0) then
      self^.s.angles[YAW] := 360;
    G_SetMovedir(self^.s.angles, self^.movedir);
    self^.movedir[2] := st.height;
  end;

  gi.linkentity(self);
end;

end.
