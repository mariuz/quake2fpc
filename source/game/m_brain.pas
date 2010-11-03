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


// PLEASE, don't modify this file
// 99% complete

{----------------------------------------------------------------------------}
{                                                                            }
{ File(s): m_brain.c                                                         }
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
{                                                                            }
{ .) unit: g_ai                                                              }
{                                                                            }
{ 1) inc:  m_brain                                                           }
{                                                                            }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{ 1) Do more tests                                                           }
{                                                                            }
{----------------------------------------------------------------------------}

{*
==============================================================================

brain

==============================================================================
*}


unit m_brain;

interface

uses g_local;

procedure SP_monster_brain (self : edict_p); cdecl;

implementation

uses q_shared, gameUnit, g_ai, g_local_add, g_main, game_add, g_misc,
  g_weapon, g_monster, g_utils, CPas;

{$I m_brain.inc}




var
  sound_chest_open,
  sound_tentacles_extend,
  sound_tentacles_retract,
  sound_death,
  sound_idle1,
  sound_idle2,
  sound_idle3,
  sound_pain1,
  sound_pain2,
  sound_sight,
  sound_search,
  sound_melee1,
  sound_melee2,
  sound_melee3: Integer;

procedure brain_sight (self, other : edict_p); cdecl;
begin
  gi.sound (self, CHAN_VOICE, sound_sight, 1, ATTN_NORM, 0);
end;

procedure brain_search (self : edict_p); cdecl;
begin
  gi.sound (self, CHAN_VOICE, sound_search, 1, ATTN_NORM, 0);
end;


//void brain_run (edict_t *self);
procedure brain_run (self : edict_p); cdecl; forward; //Y: need test
//void brain_dead (edict_t *self);
procedure brain_dead (self : edict_p); cdecl; forward; //Y: need test


//
// STAND
//
const
  brain_frames_stand : array [0..29] of mframe_t = (
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
    (aifunc: ai_stand;  dist: 0;  thinkfunc: Nil) );
  brain_move_stand : mmove_t = (firstframe: FRAME_stand01;  lastframe: FRAME_stand30;  frame: @brain_frames_stand;  endfunc: Nil);

procedure brain_stand (self : edict_p); cdecl; //Y: need test
begin
  self^.monsterinfo.currentmove := @brain_move_stand;
end;


//
// IDLE
//
const
  brain_frames_idle : array [0..29] of mframe_t = (
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
    (aifunc: ai_stand;  dist: 0;  thinkfunc: Nil) );
  brain_move_idle : mmove_t = (firstframe: FRAME_stand31;  lastframe: FRAME_stand60;  frame: @brain_frames_idle;  endfunc: brain_stand);

procedure brain_idle (self : edict_p); cdecl;
begin
  gi.sound (self, CHAN_AUTO, sound_idle3, 1, ATTN_IDLE, 0);
  self^.monsterinfo.currentmove := @brain_move_idle;
end;


//
// WALK
//
const
  brain_frames_walk1 : array [0..10] of mframe_t = (
    (aifunc: ai_walk;  dist: 7;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 2;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 3;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 3;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 1;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 9;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: -4; thinkfunc: Nil),
    (aifunc: ai_walk;  dist: -1; thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 2;  thinkfunc: Nil) );
  brain_move_walk1 : mmove_t = (firstframe: FRAME_walk101;  lastframe: FRAME_walk111;  frame: @brain_frames_walk1;  endfunc: Nil);

(*// walk2 is FUBAR, do not use
#if 0
void brain_walk2_cycle (edict_t *self)
{
   if (_random() > 0.1)
      self->monsterinfo.nextframe = FRAME_walk220;
}

mframe_t brain_frames_walk2 [] =
{
   ai_walk,   3,   NULL,
   ai_walk,   -2,   NULL,
   ai_walk,   -4,   NULL,
   ai_walk,   -3,   NULL,
   ai_walk,   0,   NULL,
   ai_walk,   1,   NULL,
   ai_walk,   12,   NULL,
   ai_walk,   0,   NULL,
   ai_walk,   -3,   NULL,
   ai_walk,   0,   NULL,

   ai_walk,   -2,   NULL,
   ai_walk,   0,   NULL,
   ai_walk,   0,   NULL,
   ai_walk,   1,   NULL,
   ai_walk,   0,   NULL,
   ai_walk,   0,   NULL,
   ai_walk,   0,   NULL,
   ai_walk,   0,   NULL,
   ai_walk,   0,   NULL,
   ai_walk,   10,   NULL,      // Cycle Start

   ai_walk,   -1,   NULL,
   ai_walk,   7,   NULL,
   ai_walk,   0,   NULL,
   ai_walk,   3,   NULL,
   ai_walk,   -3,   NULL,
   ai_walk,   2,   NULL,
   ai_walk,   4,   NULL,
   ai_walk,   -3,   NULL,
   ai_walk,   2,   NULL,
   ai_walk,   0,   NULL,

   ai_walk,   4,   brain_walk2_cycle,
   ai_walk,   -1,   NULL,
   ai_walk,   -1,   NULL,
   ai_walk,   -8,   NULL,
   ai_walk,   0,   NULL,
   ai_walk,   1,   NULL,
   ai_walk,   5,   NULL,
   ai_walk,   2,   NULL,
   ai_walk,   -1,   NULL,
   ai_walk,   -5,   NULL
};
mmove_t brain_move_walk2 = {FRAME_walk201, FRAME_walk240, brain_frames_walk2, NULL};
#endif*)

procedure brain_walk (self : edict_p); cdecl;
begin
//idsoft   if (random() <= 0.5)
  self^.monsterinfo.currentmove := @brain_move_walk1;
//idsoft   else
//idsoft      self->monsterinfo.currentmove = &brain_move_walk2;
end;


const
  brain_frames_defense : array [0..8] of mframe_t = (
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil) );
  brain_move_defense : mmove_t = (firstframe: FRAME_defens01;  lastframe: FRAME_defens08;  frame: @brain_frames_defense;  endfunc: Nil);

  brain_frames_pain3 : array [0..5] of mframe_t = (
    (aifunc: ai_move;  dist: -2; thinkfunc: Nil),
    (aifunc: ai_move;  dist: 2;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 1;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 3;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: -4; thinkfunc: Nil) );
  brain_move_pain3 : mmove_t = (firstframe: FRAME_pain301;  lastframe: FRAME_pain306;  frame: @brain_frames_pain3;  endfunc: brain_run);

  brain_frames_pain2 : array [0..7] of mframe_t = (
    (aifunc: ai_move;  dist: -2; thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 3;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 1;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: -2; thinkfunc: Nil) );
  brain_move_pain2 : mmove_t = (firstframe: FRAME_pain201;  lastframe: FRAME_pain208;  frame: @brain_frames_pain2;  endfunc: brain_run);

  brain_frames_pain1 : array [0..20] of mframe_t = (
    (aifunc: ai_move;  dist: -6; thinkfunc: Nil),
    (aifunc: ai_move;  dist: -2; thinkfunc: Nil),
    (aifunc: ai_move;  dist: -6; thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 2;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 2;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 1;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 7;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 3;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: -1; thinkfunc: Nil) );
  brain_move_pain1 : mmove_t = (firstframe: FRAME_pain101;  lastframe: FRAME_pain121;  frame: @brain_frames_pain1;  endfunc: brain_run);


//
// DUCK
//
procedure brain_duck_down (self : edict_p); cdecl;
begin
  if ((self^.monsterinfo.aiflags AND AI_DUCKED) <> 0) then
    Exit;
  self^.monsterinfo.aiflags := self^.monsterinfo.aiflags OR AI_DUCKED;
  self^.maxs[2] := self^.maxs[2] - 32;
  self^.takedamage := DAMAGE_YES;  //Y: g_local - C2PAS
  gi.linkentity (self);
end;

procedure brain_duck_hold (self : edict_p); cdecl;
begin
  if (level.time >= self^.monsterinfo.pausetime) then
    self^.monsterinfo.aiflags := self^.monsterinfo.aiflags AND (NOT AI_HOLD_FRAME)
  else
    self^.monsterinfo.aiflags := self^.monsterinfo.aiflags OR AI_HOLD_FRAME;
end;

procedure brain_duck_up (self : edict_p); cdecl;
begin
  self^.monsterinfo.aiflags := self^.monsterinfo.aiflags AND (NOT AI_DUCKED);
  self^.maxs[2] := self^.maxs[2] + 32;
  self^.takedamage := DAMAGE_AIM;  //Y: g_local - C2PAS
  gi.linkentity (self);
end;

const
  brain_frames_duck : array [0..7] of mframe_t = (
    (aifunc: ai_move;  dist: 0;   thinkfunc: Nil),
    (aifunc: ai_move;  dist: -2;  thinkfunc: brain_duck_down),
    (aifunc: ai_move;  dist: 17;  thinkfunc: brain_duck_hold),
    (aifunc: ai_move;  dist: -3;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: -1;  thinkfunc: brain_duck_up),
    (aifunc: ai_move;  dist: -5;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: -6;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: -6;  thinkfunc: Nil) );
  brain_move_duck : mmove_t = (firstframe: FRAME_duck01;  lastframe: FRAME_duck08;  frame: @brain_frames_duck;  endfunc: brain_run);

procedure brain_dodge (self, attacker : edict_p; eta : single); cdecl;
begin
  if (_random() > 0.25) then
    Exit;

  if (self^.enemy = Nil) then
    self^.enemy := attacker;

  self^.monsterinfo.pausetime := level.time + eta + 0.5;
  self^.monsterinfo.currentmove := @brain_move_duck;
end;

const
  brain_frames_death2 : array [0..4] of mframe_t = (
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 9;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil) );
  brain_move_death2 : mmove_t = (firstframe: FRAME_death201;  lastframe: FRAME_death205;  frame: @brain_frames_death2;  endfunc: brain_dead);

  brain_frames_death1 : array [0..17] of mframe_t = (
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: -2; thinkfunc: Nil),
    (aifunc: ai_move;  dist: 9;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil) );
  brain_move_death1 : mmove_t = (firstframe: FRAME_death101;  lastframe: FRAME_death118;  frame: @brain_frames_death1;  endfunc: brain_dead);


//
// MELEE
//

procedure brain_swing_right (self : edict_p); cdecl;
begin
  gi.sound (self, CHAN_BODY, sound_melee1, 1, ATTN_NORM, 0);
end;

procedure brain_hit_right (self : edict_p); cdecl;
var
  aim : vec3_t;
begin
  VectorSet (aim, MELEE_DISTANCE, self^.maxs[0], 8);
  if fire_hit (self, aim, (15 + (rand() mod 5)), 40) then
    gi.sound (self, CHAN_WEAPON, sound_melee3, 1, ATTN_NORM, 0);
end;

procedure brain_swing_left (self : edict_p); cdecl;
begin
  gi.sound (self, CHAN_BODY, sound_melee2, 1, ATTN_NORM, 0);
end;

procedure brain_hit_left (self : edict_p); cdecl;
var
  aim : vec3_t;
begin
  VectorSet (aim, MELEE_DISTANCE, self^.mins[0], 8);
  if fire_hit (self, aim, (15 + (rand() mod 5)), 40) then
    gi.sound (self, CHAN_WEAPON, sound_melee3, 1, ATTN_NORM, 0);
end;

const
  brain_frames_attack1 : array [0..17] of mframe_t = (
    (aifunc: ai_charge;  dist: 8;   thinkfunc: Nil), 
    (aifunc: ai_charge;  dist: 3;   thinkfunc: Nil), 
    (aifunc: ai_charge;  dist: 5;   thinkfunc: Nil), 
    (aifunc: ai_charge;  dist: 0;   thinkfunc: Nil),
    (aifunc: ai_charge;  dist: -3;  thinkfunc: brain_swing_right),
    (aifunc: ai_charge;  dist: 0;   thinkfunc: Nil),
    (aifunc: ai_charge;  dist: -5;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: -7;  thinkfunc: brain_hit_right),
    (aifunc: ai_charge;  dist: 0;   thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 6;   thinkfunc: brain_swing_left),
    (aifunc: ai_charge;  dist: 1;   thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 2;   thinkfunc: brain_hit_left),
    (aifunc: ai_charge;  dist: -3;  thinkfunc: Nil),   
    (aifunc: ai_charge;  dist: 6;   thinkfunc: Nil),   
    (aifunc: ai_charge;  dist: -1;  thinkfunc: Nil),   
    (aifunc: ai_charge;  dist: -3;  thinkfunc: Nil),   
    (aifunc: ai_charge;  dist: 2;   thinkfunc: Nil),
    (aifunc: ai_charge;  dist: -11; thinkfunc: Nil) );
  brain_move_attack1 : mmove_t = (firstframe: FRAME_attak101;  lastframe: FRAME_attak118;  frame: @brain_frames_attack1;  endfunc: brain_run);

procedure brain_chest_open (self : edict_p); cdecl;
begin
  self^.spawnflags := self^.spawnflags AND (NOT 65536);
  self^.monsterinfo.power_armor_type := POWER_ARMOR_NONE;
  gi.sound (self, CHAN_BODY, sound_chest_open, 1, ATTN_NORM, 0);
end;

procedure brain_tentacle_attack (self : edict_p); cdecl;
var
  aim : vec3_t;
begin
  VectorSet (aim, MELEE_DISTANCE, 0, 8);
  if fire_hit (self, aim, (10 + (rand() mod 5)), -600) AND (skill^.value > 0) then
    self^.spawnflags := self^.spawnflags OR 65536;
  gi.sound (self, CHAN_WEAPON, sound_tentacles_retract, 1, ATTN_NORM, 0);
end;

procedure brain_chest_closed (self : edict_p); cdecl;
begin
  self^.monsterinfo.power_armor_type := POWER_ARMOR_SCREEN;
  if (self^.spawnflags AND 65536) <> 0 then
  begin
    self^.spawnflags := self^.spawnflags AND (NOT 65536);
    self^.monsterinfo.currentmove := @brain_move_attack1;
  end;
end;

const
  brain_frames_attack2 : array [0..16] of mframe_t = (
    (aifunc: ai_charge;  dist: 5;  thinkfunc: Nil), 
    (aifunc: ai_charge;  dist: -4; thinkfunc: Nil), 
    (aifunc: ai_charge;  dist: -4; thinkfunc: Nil), 
    (aifunc: ai_charge;  dist: -3; thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: brain_chest_open),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 13; thinkfunc: brain_tentacle_attack),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 2;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: -9; thinkfunc: brain_chest_closed),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),   
    (aifunc: ai_charge;  dist: 4;  thinkfunc: Nil),   
    (aifunc: ai_charge;  dist: 3;  thinkfunc: Nil),   
    (aifunc: ai_charge;  dist: 2;  thinkfunc: Nil),   
    (aifunc: ai_charge;  dist: -3; thinkfunc: Nil),   
    (aifunc: ai_charge;  dist: -6; thinkfunc: Nil) );
  brain_move_attack2 : mmove_t = (firstframe: FRAME_attak201;  lastframe: FRAME_attak217;  frame: @brain_frames_attack2;  endfunc: brain_run);

procedure brain_melee(self : edict_p); cdecl;
begin
  if (_random() <= 0.5) then
    self^.monsterinfo.currentmove := @brain_move_attack1
  else
    self^.monsterinfo.currentmove := @brain_move_attack2;
end;


//
// RUN
//
const
  brain_frames_run : array [0..10] of mframe_t = (
    (aifunc: ai_run;  dist: 9;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 2;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 3;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 3;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 1;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 10; thinkfunc: Nil),
    (aifunc: ai_run;  dist: -4; thinkfunc: Nil),
    (aifunc: ai_run;  dist: -1; thinkfunc: Nil),
    (aifunc: ai_run;  dist: 2;  thinkfunc: Nil) );
  brain_move_run : mmove_t = (firstframe: FRAME_walk101;  lastframe: FRAME_walk111;  frame: @brain_frames_run;  endfunc: Nil);

procedure brain_run (self : edict_p); cdecl; //Y: need test
begin
  self^.monsterinfo.power_armor_type := POWER_ARMOR_SCREEN;
  if (self^.monsterinfo.aiflags AND AI_STAND_GROUND) <> 0 then
    self^.monsterinfo.currentmove := @brain_move_stand
  else
    self^.monsterinfo.currentmove := @brain_move_run;
end;


procedure brain_pain (self, other : edict_p; kick : single; damage : integer); cdecl;
var
  r : single;
begin
  if (self^.health < (self^.max_health / 2)) then
    self^.s.skinnum := 1;

  if (level.time < self^.pain_debounce_time) then
    Exit;

  self^.pain_debounce_time := level.time + 3;
  if (skill^.value = 3) then
    Exit;   // no pain anims in nightmare

  r := _random();
  if (r < 0.33) then
  begin
    gi.sound (self, CHAN_VOICE, sound_pain1, 1, ATTN_NORM, 0);
    self^.monsterinfo.currentmove := @brain_move_pain1;
  end
  else if (r < 0.66) then
  begin
    gi.sound (self, CHAN_VOICE, sound_pain2, 1, ATTN_NORM, 0);
    self^.monsterinfo.currentmove := @brain_move_pain2;
  end
  else
  begin
    gi.sound (self, CHAN_VOICE, sound_pain1, 1, ATTN_NORM, 0);
    self^.monsterinfo.currentmove := @brain_move_pain3;
  end;
end;

procedure brain_dead (self : edict_p); cdecl;
begin
  VectorSet (self^.mins, -16, -16, -24);
  VectorSet (self^.maxs, 16, 16, -8);
  self^.movetype := MOVETYPE_TOSS;  //Y: g_local - C2PAS
  self^.svflags := self^.svflags OR SVF_DEADMONSTER;
  self^.nextthink := 0;
  gi.linkentity (self);
end;


procedure brain_die (self, inflictor, attacker : edict_p; damage : integer; const point : vec3_t); cdecl;
var
  n : integer;
begin
  self^.s.effects := 0;
  self^.monsterinfo.power_armor_type := POWER_ARMOR_NONE;

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
  gi.sound (self, CHAN_VOICE, sound_death, 1, ATTN_NORM, 0);
  self^.deadflag := DEAD_DEAD;
  self^.takedamage := DAMAGE_YES; 
  if (_random() <= 0.5) then
    self^.monsterinfo.currentmove := @brain_move_death1
  else
    self^.monsterinfo.currentmove := @brain_move_death2;
end;

{*QUAKED monster_brain (1 .5 0) (-16 -16 -24) (16 16 32) Ambush Trigger_Spawn Sight
*}
procedure SP_monster_brain (self : edict_p); 
begin
  if (deathmatch^.value <> 0) then
  begin
    G_FreeEdict (self);
    Exit;
  end;

  sound_chest_open := gi.soundindex ('brain/brnatck1.wav');
  sound_tentacles_extend := gi.soundindex ('brain/brnatck2.wav');
  sound_tentacles_retract := gi.soundindex ('brain/brnatck3.wav');
  sound_death := gi.soundindex ('rain/brndeth1.wav');
  sound_idle1 := gi.soundindex ('rain/brnidle1.wav');
  sound_idle2 := gi.soundindex ('brain/brnidle2.wav');
  sound_idle3 := gi.soundindex ('brain/brnlens1.wav');
  sound_pain1 := gi.soundindex ('brain/brnpain1.wav');
  sound_pain2 := gi.soundindex ('brain/brnpain2.wav');
  sound_sight := gi.soundindex ('brain/brnsght1.wav');
  sound_search := gi.soundindex ('rain/brnsrch1.wav');
  sound_melee1 := gi.soundindex ('brain/melee1.wav');
  sound_melee2 := gi.soundindex ('brain/melee2.wav');
  sound_melee3 := gi.soundindex ('brain/melee3.wav');

  self^.movetype := MOVETYPE_STEP;  //Y: g_local - C2PAS
  self^.solid := SOLID_BBOX;
  self^.s.modelindex := gi.modelindex ('models/monsters/brain/tris.md2');
  VectorSet (self^.mins, -16, -16, -24);
  VectorSet (self^.maxs, 16, 16, 32);

  self^.health := 300;
  self^.gib_health := -150;
  self^.mass := 400;

  self^.pain := brain_pain;
  self^.die := brain_die;

  self^.monsterinfo.stand := brain_stand;
  self^.monsterinfo.walk := brain_walk;
  self^.monsterinfo.run := brain_run;
  self^.monsterinfo.dodge := brain_dodge;
//idsoft   self->monsterinfo.attack = brain_attack;
  self^.monsterinfo.melee := brain_melee;
  self^.monsterinfo.sight := brain_sight;
  self^.monsterinfo.search := brain_search; 
  self^.monsterinfo.idle := brain_idle;

  self^.monsterinfo.power_armor_type := POWER_ARMOR_SCREEN;
  self^.monsterinfo.power_armor_power := 100;

  gi.linkentity (self);

  self^.monsterinfo.currentmove := @brain_move_stand;
  self^.monsterinfo.scale := MODEL_SCALE;

  walkmonster_start (self);
end;

end.
