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
{ File(s): m_tank.c                                                          }
{                                                                            }
{ Initial conversion by : YgriK (Igor Karpov) - glYgriK@hotbox.ru            }
{ Initial conversion on : 25-Jan-2002                                        }
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
{ 1) inc:  m_tank                                                            }
{                                                                            }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{ 1) Do more tests                                                           }
{                                                                            }
{----------------------------------------------------------------------------}


{*
==============================================================================

TANK

==============================================================================
*}


unit m_tank;

interface

uses g_local;

procedure SP_monster_tank (self : edict_p); cdecl;

implementation

uses q_shared, gameunit, m_flash, g_ai, g_main, g_local_add, game_add,
  g_utils, g_monster, g_misc, CPas;

{$I m_tank.inc}

procedure tank_walk (self : edict_p); cdecl; forward;
procedure tank_run (self : edict_p); cdecl; forward;

procedure tank_refire_rocket (self : edict_p); cdecl; forward;
procedure tank_doattack_rocket (self : edict_p); cdecl; forward;
procedure tank_reattack_blaster (self : edict_p);cdecl; forward;


//static int   sound_strike;
var
  sound_thud,
  sound_pain,
  sound_idle,
  sound_die,
  sound_step,
  sound_sight,
  sound_windup,
  sound_strike : integer;


//
// misc
//

procedure tank_sight (self, other : edict_p); cdecl;
begin
  gi.sound (self, CHAN_VOICE, sound_sight, 1, ATTN_NORM, 0);
end;//procedure

procedure tank_footstep (self : edict_p); cdecl;
begin
  gi.sound (self, CHAN_BODY, sound_step, 1, ATTN_NORM, 0);
end;//procedure

procedure tank_thud (self : edict_p); cdecl;
begin
  gi.sound (self, CHAN_BODY, sound_thud, 1, ATTN_NORM, 0);
end;//procedure

procedure tank_windup (self : edict_p); cdecl;
begin
  gi.sound (self, CHAN_WEAPON, sound_windup, 1, ATTN_NORM, 0);
end;//procedure

procedure tank_idle (self : edict_p); cdecl;
begin
  gi.sound (self, CHAN_VOICE, sound_idle, 1, ATTN_IDLE, 0);
end;//procedure


//
// stand
//
const
  tank_frames_stand : array [0..29] of mframe_t = (
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
  tank_move_stand : mmove_t =
    (firstframe: FRAME_stand01;  lastframe: FRAME_stand30;  frame: @tank_frames_stand;  endfunc: Nil);

procedure tank_stand (self : edict_p); cdecl;
begin
  self.monsterinfo.currentmove := @tank_move_stand;
end;//procedure


//
// walk
//
(*void tank_walk (edict_t *self);*)

const
  tank_frames_start_walk : array [0..3] of mframe_t = (
    (aifunc: ai_walk;  dist:  0;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist:  6;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist:  6;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 11;  thinkfunc: tank_footstep) );
  tank_move_start_walk : mmove_t =
    (firstframe: FRAME_walk01;  lastframe: FRAME_walk04;  frame: @tank_frames_start_walk;  endfunc: tank_walk);

  tank_frames_walk : array [0..15] of mframe_t = (
    (aifunc: ai_walk;  dist: 4;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 3;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 2;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 4;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 4;  thinkfunc: tank_footstep),
    (aifunc: ai_walk;  dist: 3;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 4;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 7;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 7;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 6;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 6;  thinkfunc: tank_footstep) );
  tank_move_walk : mmove_t =
    (firstframe: FRAME_walk05;  lastframe: FRAME_walk20;  frame: @tank_frames_walk;  endfunc: Nil);

  tank_frames_stop_walk : array [0..4] of mframe_t = (
    (aifunc: ai_walk;  dist: 3;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 3;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 2;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 2;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 4;  thinkfunc: tank_footstep) );
  tank_move_stop_walk : mmove_t =
    (firstframe: FRAME_walk21;  lastframe: FRAME_walk25;  frame: @tank_frames_stop_walk;  endfunc: tank_stand);

procedure tank_walk (self : edict_p); cdecl;
begin
  self.monsterinfo.currentmove := @tank_move_walk;
end;//procedure


//
// run
//
const
  tank_frames_start_run : array [0..3] of mframe_t = (
    (aifunc: ai_run;  dist:  0;  thinkfunc: Nil),
    (aifunc: ai_run;  dist:  6;  thinkfunc: Nil),
    (aifunc: ai_run;  dist:  6;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 11;  thinkfunc: tank_footstep) );
  tank_move_start_run : mmove_t =
    (firstframe: FRAME_walk01;  lastframe: FRAME_walk04;  frame: @tank_frames_start_run;  endfunc: tank_run);

  tank_frames_run : array [0..15] of mframe_t = (
    (aifunc: ai_run;  dist: 4;  thinkfunc: Nil),      
    (aifunc: ai_run;  dist: 5;  thinkfunc: Nil),      
    (aifunc: ai_run;  dist: 3;  thinkfunc: Nil),      
    (aifunc: ai_run;  dist: 2;  thinkfunc: Nil),      
    (aifunc: ai_run;  dist: 5;  thinkfunc: Nil),      
    (aifunc: ai_run;  dist: 5;  thinkfunc: Nil),      
    (aifunc: ai_run;  dist: 4;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 4;  thinkfunc: tank_footstep),
    (aifunc: ai_run;  dist: 3;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 4;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 7;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 7;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 6;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 6;  thinkfunc: tank_footstep) );
  tank_move_run : mmove_t =
    (firstframe: FRAME_walk05;  lastframe: FRAME_walk20;  frame: @tank_frames_run;  endfunc: Nil);

  tank_frames_stop_run : array [0..4] of mframe_t = (
    (aifunc: ai_run;  dist: 3;  thinkfunc: Nil), 
    (aifunc: ai_run;  dist: 3;  thinkfunc: Nil), 
    (aifunc: ai_run;  dist: 2;  thinkfunc: Nil), 
    (aifunc: ai_run;  dist: 2;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 4;  thinkfunc: tank_footstep) );
  tank_move_stop_run : mmove_t =
    (firstframe: FRAME_walk21;  lastframe: FRAME_walk25;  frame: @tank_frames_stop_run;  endfunc: tank_walk);

procedure tank_run (self : edict_p); cdecl;
begin
  if (self.enemy <> Nil) AND (self.enemy.client <> Nil)
  then self.monsterinfo.aiflags := self.monsterinfo.aiflags OR AI_BRUTAL
  else self.monsterinfo.aiflags := self.monsterinfo.aiflags AND (NOT AI_BRUTAL);

  if (self.monsterinfo.aiflags AND AI_STAND_GROUND) <> 0 then
  begin
    self.monsterinfo.currentmove := @tank_move_stand;
    Exit;
  end;

  if (self.monsterinfo.currentmove = @tank_move_walk) OR
     (self.monsterinfo.currentmove = @tank_move_start_run)
  then self.monsterinfo.currentmove := @tank_move_run
  else self.monsterinfo.currentmove := @tank_move_start_run;
end;//procedure


//
// pain
//
const
  tank_frames_pain1 : array [0..3] of mframe_t = (
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil) );
  tank_move_pain1 : mmove_t =
    (firstframe: FRAME_pain101;  lastframe: FRAME_pain104;  frame: @tank_frames_pain1;  endfunc: tank_run);

  tank_frames_pain2 : array [0..4] of mframe_t = (
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil) );
  tank_move_pain2 : mmove_t =
    (firstframe: FRAME_pain201;  lastframe: FRAME_pain205;  frame: @tank_frames_pain2;  endfunc: tank_run);

  tank_frames_pain3 : array [0..15] of mframe_t = (
    (aifunc: ai_move;  dist: -7; thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 2;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 3;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 2;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: tank_footstep) );
  tank_move_pain3 : mmove_t =
    (firstframe: FRAME_pain301;  lastframe: FRAME_pain316;  frame: @tank_frames_pain3;  endfunc: tank_run);

procedure tank_pain (self, other : edict_p;  kick : single; damage : integer); cdecl;
begin
  if (self.health < self.max_health / 2) then
    self.s.skinnum := self.s.skinnum OR 1;

  if (damage <= 10) then
    Exit;

  if (level.time < self.pain_debounce_time) then
    Exit;

  if (damage <= 30) then
    if (_random() > 0.2) then
      Exit;

  // If hard or nightmare, don't go into pain while attacking
  if (skill.value >= 2) then
  begin
    if (self.s.frame >= FRAME_attak301) AND (self.s.frame <= FRAME_attak330) then
      Exit;
    if (self.s.frame >= FRAME_attak101) AND (self.s.frame <= FRAME_attak116) then
      Exit;
  end;

  self.pain_debounce_time := level.time + 3;
  gi.sound (self, CHAN_VOICE, sound_pain, 1, ATTN_NORM, 0);

  if (skill.value = 3) then
    Exit;    // no pain anims in nightmare

  if (damage <= 30)
  then self.monsterinfo.currentmove := @tank_move_pain1
  else
    if (damage <= 60)
    then self.monsterinfo.currentmove := @tank_move_pain2
    else self.monsterinfo.currentmove := @tank_move_pain3;
end;//procedure


//
// attacks
//
procedure TankBlaster (self : edict_p); cdecl;
var
  forward_, right,
  start,
  end_,
  dir           : vec3_t;
  flash_number  : integer;
begin
  if (self.s.frame = FRAME_attak110)
  then flash_number := MZ2_TANK_BLASTER_1
  else
    if (self.s.frame = FRAME_attak113)
    then flash_number := MZ2_TANK_BLASTER_2
    else begin
      //idsoft (self->s.frame == FRAME_attak116)
      flash_number := MZ2_TANK_BLASTER_3;
    end;

  AngleVectors (self.s.angles, @forward_, @right, Nil);
  G_ProjectSource (self.s.origin, monster_flash_offset[flash_number], forward_, right, start);

  VectorCopy (self.enemy.s.origin, end_);
  end_[2] := end_[2] +self.enemy.viewheight;
  VectorSubtract (end_, start, dir);

  monster_fire_blaster (self, start, dir, 30, 800, flash_number, EF_BLASTER);
end;//procedure

procedure TankStrike (self : edict_p); cdecl;
begin
  gi.sound (self, CHAN_WEAPON, sound_strike, 1, ATTN_NORM, 0);
end;//procedure

procedure TankRocket (self : edict_p); cdecl;
var
  forward_, right,
  start,
  dir,
  vec           : vec3_t;
  flash_number  : integer;
begin
  if (self.s.frame = FRAME_attak324)
  then flash_number := MZ2_TANK_ROCKET_1
  else
    if (self.s.frame = FRAME_attak327)
    then flash_number := MZ2_TANK_ROCKET_2
    else begin
      //idsoft (self->s.frame == FRAME_attak330)
      flash_number := MZ2_TANK_ROCKET_3;
    end;

  AngleVectors (self.s.angles, @forward_, @right, Nil);
  G_ProjectSource (self.s.origin, monster_flash_offset[flash_number], forward_, right, start);

  VectorCopy (self.enemy.s.origin, vec);
  vec[2] := vec[2] +self.enemy.viewheight;
  VectorSubtract (vec, start, dir);
  VectorNormalize (dir);

  monster_fire_rocket (self, start, dir, 50, 550, flash_number);
end;//procedure

procedure TankMachineGun (self : edict_p); cdecl;
var
  dir,
  vec,
  start,
  forward_, right : vec3_t;
  flash_number   : integer;
begin
  flash_number := MZ2_TANK_MACHINEGUN_1 + (self.s.frame - FRAME_attak406);

  AngleVectors (self.s.angles, @forward_, @right, Nil);
  G_ProjectSource (self.s.origin, monster_flash_offset[flash_number], forward_, right, start);

  if (self.enemy <> Nil)
  then begin
    VectorCopy (self.enemy.s.origin, vec);
    vec[2] := vec[2] +self.enemy.viewheight;
    VectorSubtract (vec, start, vec);
    vectoangles (vec, vec);
    dir[0] := vec[0];
  end
  else dir[0] := 0;

  if (self.s.frame <= FRAME_attak415)
  then dir[1] := self.s.angles[1] - 8 * (self.s.frame - FRAME_attak411)
  else dir[1] := self.s.angles[1] + 8 * (self.s.frame - FRAME_attak419);
  dir[2] := 0;

  AngleVectors (dir, @forward_, Nil, Nil);

  monster_fire_bullet (self, start, forward_, 20, 4, DEFAULT_BULLET_HSPREAD, DEFAULT_BULLET_VSPREAD, flash_number);
end;//procedure


const
  tank_frames_attack_blast : array [0..15] of mframe_t = (
    (aifunc: ai_charge;  dist: 0;   thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;   thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;   thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;   thinkfunc: Nil),
    (aifunc: ai_charge;  dist: -1;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: -2;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: -1;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: -1;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;   thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;   thinkfunc: TankBlaster),   // 10
    (aifunc: ai_charge;  dist: 0;   thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;   thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;   thinkfunc: TankBlaster),
    (aifunc: ai_charge;  dist: 0;   thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;   thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;   thinkfunc: TankBlaster) ); // 16
  tank_move_attack_blast : mmove_t =
    (firstframe: FRAME_attak101;  lastframe: FRAME_attak116;  frame: @tank_frames_attack_blast;  endfunc: tank_reattack_blaster);

  tank_frames_reattack_blast : array [0..5] of mframe_t = (
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: TankBlaster),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: TankBlaster) );  // 16
  tank_move_reattack_blast : mmove_t =
    (firstframe: FRAME_attak111;  lastframe: FRAME_attak116;  frame: @tank_frames_reattack_blast;  endfunc: tank_reattack_blaster);

  tank_frames_attack_post_blast : array [0..5] of mframe_t = (
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),             // 17
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 2;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 3;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 2;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: -2; thinkfunc: tank_footstep) );   // 22
  tank_move_attack_post_blast : mmove_t =
    (firstframe: FRAME_attak117;  lastframe: FRAME_attak122;  frame: @tank_frames_attack_post_blast;  endfunc: tank_run);

procedure tank_reattack_blaster (self : edict_p);cdecl;
begin
  if (skill.value >= 2) then
    if (visible (self, self.enemy)) then
      if (self.enemy.health > 0) then
        if (_random() <= 0.6) then
        begin
          self.monsterinfo.currentmove := @tank_move_reattack_blast;
          Exit;
        end;
  self.monsterinfo.currentmove := @tank_move_attack_post_blast;
end;//procedure

procedure tank_poststrike (self : edict_p); cdecl;
begin
  self.enemy := Nil;
  tank_run (self);
end;//procedure


const
  tank_frames_attack_strike : array [0..37] of mframe_t = (
    (aifunc: ai_move;  dist: 3;   thinkfunc: Nil),
    (aifunc: ai_move;  dist: 2;   thinkfunc: Nil),
    (aifunc: ai_move;  dist: 2;   thinkfunc: Nil),
    (aifunc: ai_move;  dist: 1;   thinkfunc: Nil),
    (aifunc: ai_move;  dist: 6;   thinkfunc: Nil),
    (aifunc: ai_move;  dist: 7;   thinkfunc: Nil),
    (aifunc: ai_move;  dist: 9;   thinkfunc: tank_footstep),
    (aifunc: ai_move;  dist: 2;   thinkfunc: Nil),
    (aifunc: ai_move;  dist: 1;   thinkfunc: Nil),
    (aifunc: ai_move;  dist: 2;   thinkfunc: Nil),
    (aifunc: ai_move;  dist: 2;   thinkfunc: tank_footstep),
    (aifunc: ai_move;  dist: 2;   thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;   thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;   thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;   thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;   thinkfunc: Nil),
    (aifunc: ai_move;  dist: -2;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: -2;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;   thinkfunc: tank_windup),
    (aifunc: ai_move;  dist: 0;   thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;   thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;   thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;   thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;   thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;   thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;   thinkfunc: TankStrike),
    (aifunc: ai_move;  dist: 0;   thinkfunc: Nil),
    (aifunc: ai_move;  dist: -1;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: -1;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: -1;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: -1;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: -1;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: -3;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: -10; thinkfunc: Nil),
    (aifunc: ai_move;  dist: -10; thinkfunc: Nil),
    (aifunc: ai_move;  dist: -2;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: -3;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: -2;  thinkfunc: tank_footstep) );
  tank_move_attack_strike : mmove_t =
    (firstframe: FRAME_attak201;  lastframe: FRAME_attak238;  frame: @tank_frames_attack_strike;  endfunc: tank_poststrike);

  tank_frames_attack_pre_rocket : array [0..20] of mframe_t = (
    (aifunc: ai_charge;  dist: 0;   thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;   thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;   thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;   thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;   thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;   thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;   thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;   thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;   thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;   thinkfunc: Nil),      // 10

    (aifunc: ai_charge;  dist: 0;   thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 1;   thinkfunc: Nil),  
    (aifunc: ai_charge;  dist: 2;   thinkfunc: Nil),  
    (aifunc: ai_charge;  dist: 7;   thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 7;   thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 7;   thinkfunc: tank_footstep),
    (aifunc: ai_charge;  dist: 0;   thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;   thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;   thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;   thinkfunc: Nil),        // 20

    (aifunc: ai_charge;  dist: -3;  thinkfunc: Nil) );
  tank_move_attack_pre_rocket : mmove_t =
    (firstframe: FRAME_attak301;  lastframe: FRAME_attak321;  frame: @tank_frames_attack_pre_rocket;  endfunc: tank_doattack_rocket);

  tank_frames_attack_fire_rocket : array [0..8] of mframe_t = (
    (aifunc: ai_charge;  dist: -3;  thinkfunc: Nil),             // Loop Start   22
    (aifunc: ai_charge;  dist: 0;   thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;   thinkfunc: TankRocket),      // 24
    (aifunc: ai_charge;  dist: 0;   thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;   thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;   thinkfunc: TankRocket),
    (aifunc: ai_charge;  dist: 0;   thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;   thinkfunc: Nil),
    (aifunc: ai_charge;  dist: -1;  thinkfunc: TankRocket) );    // 30   Loop End
  tank_move_attack_fire_rocket : mmove_t =
    (firstframe: FRAME_attak322; lastframe: FRAME_attak330;  frame: @tank_frames_attack_fire_rocket;  endfunc: tank_refire_rocket);

  tank_frames_attack_post_rocket : array [0..22] of mframe_t = (
    (aifunc: ai_charge;  dist: 0;   thinkfunc: Nil),           // 31
    (aifunc: ai_charge;  dist: -1;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: -1;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;   thinkfunc: Nil),  
    (aifunc: ai_charge;  dist: 2;   thinkfunc: Nil),  
    (aifunc: ai_charge;  dist: 3;   thinkfunc: Nil),  
    (aifunc: ai_charge;  dist: 4;   thinkfunc: Nil),  
    (aifunc: ai_charge;  dist: 2;   thinkfunc: Nil),  
    (aifunc: ai_charge;  dist: 0;   thinkfunc: Nil),  
    (aifunc: ai_charge;  dist: 0;   thinkfunc: Nil),           // 40

    (aifunc: ai_charge;  dist: 0;   thinkfunc: Nil),  
    (aifunc: ai_charge;  dist: -9;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: -8;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: -7;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: -1;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: -1;  thinkfunc: tank_footstep),
    (aifunc: ai_charge;  dist: 0;   thinkfunc: Nil),  
    (aifunc: ai_charge;  dist: 0;   thinkfunc: Nil),  
    (aifunc: ai_charge;  dist: 0;   thinkfunc: Nil),  
    (aifunc: ai_charge;  dist: 0;   thinkfunc: Nil),           // 50

    (aifunc: ai_charge;  dist: 0;   thinkfunc: Nil),  
    (aifunc: ai_charge;  dist: 0;   thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;   thinkfunc: Nil) );
  tank_move_attack_post_rocket : mmove_t =
    (firstframe: FRAME_attak331;  lastframe: FRAME_attak353;  frame: @tank_frames_attack_post_rocket;  endfunc: tank_run);

  tank_frames_attack_chain : array [0..28] of mframe_t = (
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: Nil;        dist: 0;  thinkfunc: TankMachineGun),
    (aifunc: Nil;        dist: 0;  thinkfunc: TankMachineGun),
    (aifunc: Nil;        dist: 0;  thinkfunc: TankMachineGun),
    (aifunc: Nil;        dist: 0;  thinkfunc: TankMachineGun),
    (aifunc: Nil;        dist: 0;  thinkfunc: TankMachineGun),
    (aifunc: Nil;        dist: 0;  thinkfunc: TankMachineGun),
    (aifunc: Nil;        dist: 0;  thinkfunc: TankMachineGun),
    (aifunc: Nil;        dist: 0;  thinkfunc: TankMachineGun),
    (aifunc: Nil;        dist: 0;  thinkfunc: TankMachineGun),
    (aifunc: Nil;        dist: 0;  thinkfunc: TankMachineGun),
    (aifunc: Nil;        dist: 0;  thinkfunc: TankMachineGun),
    (aifunc: Nil;        dist: 0;  thinkfunc: TankMachineGun),
    (aifunc: Nil;        dist: 0;  thinkfunc: TankMachineGun),
    (aifunc: Nil;        dist: 0;  thinkfunc: TankMachineGun),
    (aifunc: Nil;        dist: 0;  thinkfunc: TankMachineGun),
    (aifunc: Nil;        dist: 0;  thinkfunc: TankMachineGun),
    (aifunc: Nil;        dist: 0;  thinkfunc: TankMachineGun),
    (aifunc: Nil;        dist: 0;  thinkfunc: TankMachineGun),
    (aifunc: Nil;        dist: 0;  thinkfunc: TankMachineGun),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil) );
  tank_move_attack_chain : mmove_t =
    (firstframe: FRAME_attak401;  lastframe: FRAME_attak429;  frame: @tank_frames_attack_chain;  endfunc: tank_run);

procedure tank_refire_rocket (self : edict_p); cdecl;
begin
  // Only on hard or nightmare
  if (skill.value >= 2) then
    if (self.enemy.health > 0) then
      if (visible(self, self.enemy)) then
        if (_random() <= 0.4) then
        begin
          self.monsterinfo.currentmove := @tank_move_attack_fire_rocket;
          Exit;
        end;
  self.monsterinfo.currentmove := @tank_move_attack_post_rocket;
end;//procedure

procedure tank_doattack_rocket (self : edict_p); cdecl;
begin
  self.monsterinfo.currentmove := @tank_move_attack_fire_rocket;
end;//procedure

procedure tank_attack (self : edict_p); cdecl;
var
  vec    : vec3_t;
  range,
  r      : single;
begin
  if (self.enemy.health < 0) then
  begin
    self.monsterinfo.currentmove := @tank_move_attack_strike;
    self.monsterinfo.aiflags     := self.monsterinfo.aiflags AND (NOT AI_BRUTAL);
    Exit;
  end;

  VectorSubtract (self.enemy.s.origin, self.s.origin, vec);
  range := VectorLength (vec);

  r := _random();

  if (range <= 125)
  then
    if (r < 0.4)
    then self.monsterinfo.currentmove := @tank_move_attack_chain
    else self.monsterinfo.currentmove := @tank_move_attack_blast
  else
    if (range <= 250)
    then
      if (r < 0.5)
      then self.monsterinfo.currentmove := @tank_move_attack_chain
      else self.monsterinfo.currentmove := @tank_move_attack_blast
    else
      if (r < 0.33)
      then self.monsterinfo.currentmove := @tank_move_attack_chain
      else
        if (r < 0.66)
        then begin
          self.monsterinfo.currentmove := @tank_move_attack_pre_rocket;
          self.pain_debounce_time := level.time + 5.0;   // no pain for a while
        end
        else
          self.monsterinfo.currentmove := @tank_move_attack_blast;
end;//procedure


//
// death
//

procedure tank_dead (self : edict_p); cdecl;
begin
  VectorSet (self.mins, -16, -16, -16);
  VectorSet (self.maxs, 16, 16, -0);
  self.movetype := MOVETYPE_TOSS;
  self.svflags  := self.svflags or SVF_DEADMONSTER;
  self.nextthink := 0;
  gi.linkentity (self);
end;//procedure

const
  tank_frames_death1 : array [0..31] of mframe_t = (
    (aifunc: ai_move;  dist: -7;  thinkfunc: Nil), 
    (aifunc: ai_move;  dist: -2;  thinkfunc: Nil), 
    (aifunc: ai_move;  dist: -2;  thinkfunc: Nil), 
    (aifunc: ai_move;  dist: 1;   thinkfunc: Nil), 
    (aifunc: ai_move;  dist: 3;   thinkfunc: Nil), 
    (aifunc: ai_move;  dist: 6;   thinkfunc: Nil), 
    (aifunc: ai_move;  dist: 1;   thinkfunc: Nil), 
    (aifunc: ai_move;  dist: 1;   thinkfunc: Nil), 
    (aifunc: ai_move;  dist: 2;   thinkfunc: Nil), 
    (aifunc: ai_move;  dist: 0;   thinkfunc: Nil), 
    (aifunc: ai_move;  dist: 0;   thinkfunc: Nil), 
    (aifunc: ai_move;  dist: 0;   thinkfunc: Nil), 
    (aifunc: ai_move;  dist: -2;  thinkfunc: Nil), 
    (aifunc: ai_move;  dist: 0;   thinkfunc: Nil), 
    (aifunc: ai_move;  dist: 0;   thinkfunc: Nil), 
    (aifunc: ai_move;  dist: -3;  thinkfunc: Nil), 
    (aifunc: ai_move;  dist: 0;   thinkfunc: Nil), 
    (aifunc: ai_move;  dist: 0;   thinkfunc: Nil), 
    (aifunc: ai_move;  dist: 0;   thinkfunc: Nil), 
    (aifunc: ai_move;  dist: 0;   thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;   thinkfunc: Nil), 
    (aifunc: ai_move;  dist: 0;   thinkfunc: Nil), 
    (aifunc: ai_move;  dist: -4;  thinkfunc: Nil), 
    (aifunc: ai_move;  dist: -6;  thinkfunc: Nil), 
    (aifunc: ai_move;  dist: -4;  thinkfunc: Nil), 
    (aifunc: ai_move;  dist: -5;  thinkfunc: Nil), 
    (aifunc: ai_move;  dist: -7;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: -15; thinkfunc: tank_thud),
    (aifunc: ai_move;  dist: -5;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;   thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;   thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;   thinkfunc: Nil) );
  tank_move_death : mmove_t =
    (firstframe: FRAME_death101; lastframe: FRAME_death132; frame: @tank_frames_death1;  endfunc: tank_dead);

procedure tank_die (self, inflictor, attacker : edict_p; damage : integer; const point : vec3_t); cdecl;
var
  n : integer;
begin
// check for gib
  if (self.health <= self.gib_health) then
  begin
    gi.sound (self, CHAN_VOICE, gi.soundindex ('misc/udeath.wav'), 1, ATTN_NORM, 0);
    
    for n := 0 to 1 {4} do
      ThrowGib (self, 'models/objects/gibs/sm_meat/tris.md2', damage, GIB_ORGANIC);

    for n:=0 to 3 do
      ThrowGib (self, 'models/objects/gibs/sm_metal/tris.md2', damage, GIB_METALLIC);
    ThrowGib  (self, 'models/objects/gibs/chest/tris.md2', damage, GIB_ORGANIC);
    ThrowHead (self, 'models/objects/gibs/gear/tris.md2',  damage, GIB_METALLIC);
    self.deadflag := DEAD_DEAD;
    Exit;
  end;

  if (self.deadflag = DEAD_DEAD) then
    Exit;

// regular death
  gi.sound (self, CHAN_VOICE, sound_die, 1, ATTN_NORM, 0);
  self.deadflag := DEAD_DEAD;
  self.takedamage := DAMAGE_YES;

  self.monsterinfo.currentmove := @tank_move_death;
end;//procedure


//
// monster_tank
//

{*QUAKED monster_tank (1 .5 0) (-32 -32 -16) (32 32 72) Ambush Trigger_Spawn Sight
*/
/*QUAKED monster_tank_commander (1 .5 0) (-32 -32 -16) (32 32 72) Ambush Trigger_Spawn Sight
*}

procedure SP_monster_tank (self : edict_p);
begin
  if (deathmatch.value <> 0) then
  begin
    G_FreeEdict (self);
    Exit;
  end;

  self.s.modelindex := gi.modelindex ('models/monsters/tank/tris.md2');
  VectorSet (self.mins, -32, -32, -16);
  VectorSet (self.maxs, 32, 32, 72);
  self.movetype := MOVETYPE_STEP;
  self.solid := SOLID_BBOX;

  sound_pain   := gi.soundindex ('tank/tnkpain2.wav');
  sound_thud   := gi.soundindex ('tank/tnkdeth2.wav');
  sound_idle   := gi.soundindex ('tank/tnkidle1.wav');
  sound_die    := gi.soundindex ('tank/death.wav');
  sound_step   := gi.soundindex ('tank/step.wav');
  sound_windup := gi.soundindex ('tank/tnkatck4.wav');
  sound_strike := gi.soundindex ('tank/tnkatck5.wav');
  sound_sight  := gi.soundindex ('tank/sight1.wav');

  gi.soundindex ('tank/tnkatck1.wav');
  gi.soundindex ('tank/tnkatk2a.wav');
  gi.soundindex ('tank/tnkatk2b.wav');
  gi.soundindex ('tank/tnkatk2c.wav');
  gi.soundindex ('tank/tnkatk2d.wav');
  gi.soundindex ('tank/tnkatk2e.wav');
  gi.soundindex ('tank/tnkatck3.wav');

(*Y  if (strcmp(self.classname, 'monster_tank_commander') = 0)
  then begin
    self.health := 1000;
    self.gib_health := -225;
  end
  else begin
    self.health := 750;
    self.gib_health := -200;
  end;*)

  self.mass := 500;

  self.pain := tank_pain;
  self.die := tank_die;
  self.monsterinfo.stand := tank_stand;
  self.monsterinfo.walk := tank_walk;
  self.monsterinfo.run := tank_run;
  self.monsterinfo.dodge := Nil;
  self.monsterinfo.attack := tank_attack;
  self.monsterinfo.melee := Nil;
  self.monsterinfo.sight := tank_sight;
  self.monsterinfo.idle := tank_idle;

  gi.linkentity (self);

  self.monsterinfo.currentmove := @tank_move_stand;
  self.monsterinfo.scale := MODEL_SCALE;

  walkmonster_start(self);

  if (strcmp(self.classname, 'monster_tank_commander') = 0) then
    self.s.skinnum := 2;
end;//procedure

// End of file
end.

