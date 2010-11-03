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
{ File(s): m_boss2.h                                                         }
{                                                                            }
{ Initial conversion by : Ben Watt (ben@delphigamedev.com)                   }
{ Initial conversion on : 05-March-2002                                        }
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
{
==============================================================================

boss2

==============================================================================
}

unit m_boss2;

interface

uses
  g_local;

const MODEL_SCALE     = 1.000000;

var
  sound_pain1,
  sound_pain2,
  sound_pain3,
  sound_death,
  sound_search1 : Integer;

{$I m_boss2.inc}

procedure SP_monster_boss2(self : edict_p); cdecl;

implementation

uses g_ai, g_main, q_shared, g_misc, g_utils, m_flash, g_monster,
  m_supertank, q_shared_add, g_local_add, game_add, GameUnit;

procedure boss2_attack_mg(self : edict_p); cdecl; forward;
procedure boss2_reattack_mg(self : edict_p); cdecl; forward;
procedure boss2_run(self : edict_p); cdecl; forward;
procedure boss2_dead(self : edict_p); cdecl; forward;

procedure boss2_search(self : edict_p); cdecl;
begin
  if (_random() < 0.5) then
    gi.sound(self, CHAN_VOICE, sound_search1, 1, ATTN_NONE, 0);
end;

procedure Boss2Rocket(self : edict_p); cdecl;
var
  fwrd, right : vec3_t;
  start       : vec3_t;
  dir         : vec3_t;
  vec         : vec3_t;
begin
  AngleVectors(self.s.angles, @fwrd, @right, nil);

//1
  G_ProjectSource(self.s.origin, monster_flash_offset[MZ2_BOSS2_ROCKET_1], fwrd, right, start);
  VectorCopy(self.enemy.s.origin, vec);
  vec[2] := vec[2] + self.enemy.viewheight;
  VectorSubtract(vec, start, dir);
  VectorNormalize(dir);
  monster_fire_rocket(self, start, dir, 50, 500, MZ2_BOSS2_ROCKET_1);

//2
  G_ProjectSource(self.s.origin, monster_flash_offset[MZ2_BOSS2_ROCKET_2], fwrd, right, start);
  VectorCopy(self.enemy.s.origin, vec);
  vec[2] := vec[2] + self.enemy.viewheight;
  VectorSubtract(vec, start, dir);
  VectorNormalize(dir);
  monster_fire_rocket(self, start, dir, 50, 500, MZ2_BOSS2_ROCKET_2);

//3
  G_ProjectSource(self.s.origin, monster_flash_offset[MZ2_BOSS2_ROCKET_3], fwrd, right, start);
  VectorCopy(self.enemy.s.origin, vec);
  vec[2] := vec[2] + self.enemy.viewheight;
  VectorSubtract(vec, start, dir);
  VectorNormalize(dir);
  monster_fire_rocket(self, start, dir, 50, 500, MZ2_BOSS2_ROCKET_3);

//4
  G_ProjectSource(self.s.origin, monster_flash_offset[MZ2_BOSS2_ROCKET_4], fwrd, right, start);
  VectorCopy(self.enemy.s.origin, vec);
  vec[2] := vec[2] + self.enemy.viewheight;
  VectorSubtract(vec, start, dir);
  VectorNormalize(dir);
  monster_fire_rocket(self, start, dir, 50, 500, MZ2_BOSS2_ROCKET_4);
end;

procedure boss2_firebullet_right(self : edict_p);
var
  fwrd, right, target : vec3_t;
  start               : vec3_t;
begin
  AngleVectors(self.s.angles, @fwrd, @right, nil);
  G_ProjectSource(self.s.origin, monster_flash_offset[MZ2_BOSS2_MACHINEGUN_R1], fwrd, right, start);

  VectorMA(self.enemy.s.origin, -0.2, self.enemy.velocity, target);
  target[2] := target[2] + self.enemy.viewheight;
  VectorSubtract(target, start, fwrd);
  VectorNormalize(fwrd);

  monster_fire_bullet(self, start, fwrd, 6, 4, DEFAULT_BULLET_HSPREAD, DEFAULT_BULLET_VSPREAD, MZ2_BOSS2_MACHINEGUN_R1);
end;

procedure boss2_firebullet_left(self : edict_p);
var
  fwrd, right, target : vec3_t;
  start               : vec3_t;
begin
  AngleVectors(self.s.angles, @fwrd, @right, nil);
  G_ProjectSource(self.s.origin, monster_flash_offset[MZ2_BOSS2_MACHINEGUN_L1], fwrd, right, start);

  VectorMA(self.enemy.s.origin, -0.2, self.enemy.velocity, target);

  target[2] := target[2] + self.enemy.viewheight;
  VectorSubtract(target, start, fwrd);
  VectorNormalize(fwrd);

  monster_fire_bullet(self, start, fwrd, 6, 4, DEFAULT_BULLET_HSPREAD, DEFAULT_BULLET_VSPREAD, MZ2_BOSS2_MACHINEGUN_L1);
end;

procedure Boss2MachineGun(self : edict_p); cdecl;
{var
  fwrd, right  : vec3_t;
  start        : vec3_t;
  dir          : vec3_t;
  vec          : vec3_t;
  flash_number : integer; }
begin
{ AngleVectors(self.s.angles, forward, right, nil);

  flash_number := MZ2_BOSS2_MACHINEGUN_1 + (self.s.frame - FRAME_attack10);
  G_ProjectSource(self.s.origin, monster_flash_offset[flash_number], forward, right, start);

  VectorCopy(self.enemy.s.origin, vec);
  vec[2] := vec[2] + self.enemy.viewheight;
  VectorSubtract(vec, start, dir);
  VectorNormalize(dir);
  monster_fire_bullet(self, start, dir, 3, 4, DEFAULT_BULLET_HSPREAD, DEFAULT_BULLET_VSPREAD, flash_number);
}
  boss2_firebullet_left(self);
  boss2_firebullet_right(self);
end;

const
  boss2_frames_stand : Array[0..20] of mframe_t =
    ((aifunc:ai_stand; dist:0; thinkfunc:nil),
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

  boss2_move_stand : mmove_t =
    (firstframe:FRAME_stand30; lastframe:FRAME_stand50; frame:@boss2_frames_stand; endfunc:nil);

  boss2_frames_fidget : Array[0..29] of mframe_t =
    ((aifunc:ai_stand; dist:0; thinkfunc:nil),
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

  boss2_move_fidget : mmove_t =
    (firstframe:FRAME_stand1; lastframe:FRAME_stand30; frame:@boss2_frames_fidget; endfunc:nil);

  boss2_frames_walk : Array[0..19] of mframe_t =
    ((aifunc:ai_walk; dist:8; thinkfunc:nil),
     (aifunc:ai_walk; dist:8; thinkfunc:nil),
     (aifunc:ai_walk; dist:8; thinkfunc:nil),
     (aifunc:ai_walk; dist:8; thinkfunc:nil),
     (aifunc:ai_walk; dist:8; thinkfunc:nil),
     (aifunc:ai_walk; dist:8; thinkfunc:nil),
     (aifunc:ai_walk; dist:8; thinkfunc:nil),
     (aifunc:ai_walk; dist:8; thinkfunc:nil),
     (aifunc:ai_walk; dist:8; thinkfunc:nil),
     (aifunc:ai_walk; dist:8; thinkfunc:nil),
     (aifunc:ai_walk; dist:8; thinkfunc:nil),
     (aifunc:ai_walk; dist:8; thinkfunc:nil),
     (aifunc:ai_walk; dist:8; thinkfunc:nil),
     (aifunc:ai_walk; dist:8; thinkfunc:nil),
     (aifunc:ai_walk; dist:8; thinkfunc:nil),
     (aifunc:ai_walk; dist:8; thinkfunc:nil),
     (aifunc:ai_walk; dist:8; thinkfunc:nil),
     (aifunc:ai_walk; dist:8; thinkfunc:nil),
     (aifunc:ai_walk; dist:8; thinkfunc:nil),
     (aifunc:ai_walk; dist:8; thinkfunc:nil));

  boss2_move_walk : mmove_t =
    (firstframe:FRAME_walk1; lastframe:FRAME_walk20; frame:@boss2_frames_walk; endfunc:nil);

  boss2_frames_run : Array[0..19] of mframe_t =
    ((aifunc:ai_run; dist:8; thinkfunc:nil),
     (aifunc:ai_run; dist:8; thinkfunc:nil),
     (aifunc:ai_run; dist:8; thinkfunc:nil),
     (aifunc:ai_run; dist:8; thinkfunc:nil),
     (aifunc:ai_run; dist:8; thinkfunc:nil),
     (aifunc:ai_run; dist:8; thinkfunc:nil),
     (aifunc:ai_run; dist:8; thinkfunc:nil),
     (aifunc:ai_run; dist:8; thinkfunc:nil),
     (aifunc:ai_run; dist:8; thinkfunc:nil),
     (aifunc:ai_run; dist:8; thinkfunc:nil),
     (aifunc:ai_run; dist:8; thinkfunc:nil),
     (aifunc:ai_run; dist:8; thinkfunc:nil),
     (aifunc:ai_run; dist:8; thinkfunc:nil),
     (aifunc:ai_run; dist:8; thinkfunc:nil),
     (aifunc:ai_run; dist:8; thinkfunc:nil),
     (aifunc:ai_run; dist:8; thinkfunc:nil),
     (aifunc:ai_run; dist:8; thinkfunc:nil),
     (aifunc:ai_run; dist:8; thinkfunc:nil),
     (aifunc:ai_run; dist:8; thinkfunc:nil),
     (aifunc:ai_run; dist:8; thinkfunc:nil));

  boss2_move_run : mmove_t =
    (firstframe:FRAME_walk1; lastframe:FRAME_walk20; frame:@boss2_frames_run; endfunc:nil);

  boss2_frames_attack_pre_mg : Array[0..8] of mframe_t =
    ((aifunc:ai_charge; dist:1; thinkfunc:nil),
     (aifunc:ai_charge; dist:1; thinkfunc:nil),
     (aifunc:ai_charge; dist:1; thinkfunc:nil),
     (aifunc:ai_charge; dist:1; thinkfunc:nil),
     (aifunc:ai_charge; dist:1; thinkfunc:nil),
     (aifunc:ai_charge; dist:1; thinkfunc:nil),
     (aifunc:ai_charge; dist:1; thinkfunc:nil),
     (aifunc:ai_charge; dist:1; thinkfunc:nil),
     (aifunc:ai_charge; dist:1; thinkfunc:boss2_attack_mg));

  boss2_move_attack_pre_mg : mmove_t =
    (firstframe:FRAME_attack1; lastframe:FRAME_attack9; frame:@boss2_frames_attack_pre_mg; endfunc:nil);

  // Loop this
  boss2_frames_attack_mg : Array[0..5] of mframe_t =
    ((aifunc:ai_charge; dist:1; thinkfunc:Boss2MachineGun),
     (aifunc:ai_charge; dist:1; thinkfunc:Boss2MachineGun),
     (aifunc:ai_charge; dist:1; thinkfunc:Boss2MachineGun),
     (aifunc:ai_charge; dist:1; thinkfunc:Boss2MachineGun),
     (aifunc:ai_charge; dist:1; thinkfunc:Boss2MachineGun),
     (aifunc:ai_charge; dist:1; thinkfunc:boss2_reattack_mg));

  boss2_move_attack_mg : mmove_t =
    (firstframe:FRAME_attack10; lastframe:FRAME_attack15; frame:@boss2_frames_attack_mg; endfunc:nil);

  boss2_frames_attack_post_mg : Array[0..3] of mframe_t =
    ((aifunc:ai_charge; dist:1; thinkfunc:nil),
     (aifunc:ai_charge; dist:1; thinkfunc:nil),
     (aifunc:ai_charge; dist:1; thinkfunc:nil),
     (aifunc:ai_charge; dist:1; thinkfunc:nil));

  boss2_move_attack_post_mg : mmove_t =
    (firstframe:FRAME_attack16; lastframe:FRAME_attack19; frame:@boss2_frames_attack_post_mg; endfunc:boss2_run);

  boss2_frames_attack_rocket : Array[0..20] of mframe_t =
    ((aifunc:ai_charge; dist:1; thinkfunc:nil),
     (aifunc:ai_charge; dist:1; thinkfunc:nil),
     (aifunc:ai_charge; dist:1; thinkfunc:nil),
     (aifunc:ai_charge; dist:1; thinkfunc:nil),
     (aifunc:ai_charge; dist:1; thinkfunc:nil),
     (aifunc:ai_charge; dist:1; thinkfunc:nil),
     (aifunc:ai_charge; dist:1; thinkfunc:nil),
     (aifunc:ai_charge; dist:1; thinkfunc:nil),
     (aifunc:ai_charge; dist:1; thinkfunc:nil),
     (aifunc:ai_charge; dist:1; thinkfunc:nil),
     (aifunc:ai_charge; dist:1; thinkfunc:nil),
     (aifunc:ai_charge; dist:1; thinkfunc:nil),
     (aifunc:ai_move; dist:-20; thinkfunc:Boss2Rocket),
     (aifunc:ai_charge; dist:1; thinkfunc:nil),
     (aifunc:ai_charge; dist:1; thinkfunc:nil),
     (aifunc:ai_charge; dist:1; thinkfunc:nil),
     (aifunc:ai_charge; dist:1; thinkfunc:nil),
     (aifunc:ai_charge; dist:1; thinkfunc:nil),
     (aifunc:ai_charge; dist:1; thinkfunc:nil),
     (aifunc:ai_charge; dist:1; thinkfunc:nil),
     (aifunc:ai_charge; dist:1; thinkfunc:nil));

  boss2_move_attack_rocket : mmove_t =
    (firstframe:FRAME_attack20; lastframe:FRAME_attack40; frame:@boss2_frames_attack_rocket; endfunc:boss2_run);

  boss2_frames_pain_heavy : Array[0..17] of mframe_t =
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
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil));

  boss2_move_pain_heavy : mmove_t =
    (firstframe:FRAME_pain2; lastframe:FRAME_pain19; frame:@boss2_frames_pain_heavy; endfunc:boss2_run);

  boss2_frames_pain_light : Array[0..3] of mframe_t =
    ((aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil));

  boss2_move_pain_light : mmove_t =
    (firstframe:FRAME_pain20; lastframe:FRAME_pain23; frame:@boss2_frames_pain_light; endfunc:boss2_run);

  boss2_frames_death : Array[0..48] of mframe_t =
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
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:BossExplode));

  boss2_move_death : mmove_t =
    (firstframe:FRAME_death2; lastframe:FRAME_death50; frame:@boss2_frames_death; endfunc:boss2_dead);

procedure boss2_stand(self : edict_p); cdecl;
begin                             
  self.monsterinfo.currentmove := @boss2_move_stand;
end;

procedure boss2_run(self : edict_p);
begin
  if (self.monsterinfo.aiflags and AI_STAND_GROUND) <> 0 then
    self.monsterinfo.currentmove := @boss2_move_stand
  else
    self.monsterinfo.currentmove := @boss2_move_run;
end;

procedure boss2_walk(self : edict_p); cdecl;
begin
  self.monsterinfo.currentmove := @boss2_move_walk;
end;

procedure boss2_attack(self : edict_p); cdecl;
var
  vec   : vec3_t;
  range : single;
begin
  VectorSubtract(self.enemy.s.origin, self.s.origin, vec);
  range := VectorLength(vec);
   
  if range <= 125 then
    self.monsterinfo.currentmove := @boss2_move_attack_pre_mg
  else
  begin
    if _random() <= 0.6 then
      self.monsterinfo.currentmove := @boss2_move_attack_pre_mg
    else
      self.monsterinfo.currentmove := @boss2_move_attack_rocket;
  end;
end;

procedure boss2_attack_mg(self : edict_p); cdecl;
begin
  self.monsterinfo.currentmove := @boss2_move_attack_mg;
end;

procedure boss2_reattack_mg(self : edict_p);
begin
  if infront(self, self.enemy) then
  begin
    if _random() <= 0.7 then
      self.monsterinfo.currentmove := @boss2_move_attack_mg
    else
      self.monsterinfo.currentmove := @boss2_move_attack_post_mg;
  end
  else
    self.monsterinfo.currentmove := @boss2_move_attack_post_mg;
end;

procedure boss2_pain(self, other : edict_p; kick : single; damage : integer); cdecl;
begin
  if self.health < (self.max_health / 2) then
    self.s.skinnum := 1;

  if level.time < self.pain_debounce_time then
    exit;

  self.pain_debounce_time := level.time + 3;
  // American wanted these at no attenuation
  if damage < 10 then
  begin
    gi.sound(self, CHAN_VOICE, sound_pain3, 1, ATTN_NONE, 0);
    self.monsterinfo.currentmove := @boss2_move_pain_light;
  end
  else
  if damage < 30 then
  begin
    gi.sound(self, CHAN_VOICE, sound_pain1, 1, ATTN_NONE, 0);
    self.monsterinfo.currentmove := @boss2_move_pain_light;
  end
  else
  begin
    gi.sound(self, CHAN_VOICE, sound_pain2, 1, ATTN_NONE, 0);
    self.monsterinfo.currentmove := @boss2_move_pain_heavy;
  end;
end;

procedure boss2_dead(self : edict_p);
begin
  VectorSet(self.mins, -56, -56,  0);
  VectorSet(self.maxs,  56,  56, 80);
  self.movetype  := MOVETYPE_TOSS;
  self.svflags   := self.svflags or SVF_DEADMONSTER;
  self.nextthink := 0;
  gi.linkentity(self);
end;

procedure boss2_die(self, inflictor, attacker : edict_p; damage : integer; const point : vec3_t); cdecl;
var
  n : integer;
begin
  gi.sound(self, CHAN_VOICE, sound_death, 1, ATTN_NONE, 0);
  self.deadflag := DEAD_DEAD;
  self.takedamage := DAMAGE_NO;
  self.count := 0;
  self.monsterinfo.currentmove := @boss2_move_death;

  {$IF FALSE}
    self.s.sound := 0;
    // check for gib
    if self.health <= self.gib_health then
    begin
      gi.sound(self, CHAN_VOICE, gi.soundindex('misc/udeath.wav'), 1, ATTN_NORM, 0);
      for n := 0 to 1 do
        ThrowGib(self, 'models/objects/gibs/bone/tris.md2', damage, GIB_ORGANIC);
      for n := 0 to 3 do
        ThrowGib(self, 'models/objects/gibs/sm_meat/tris.md2', damage, GIB_ORGANIC);
      ThrowHead (self, 'models/objects/gibs/head2/tris.md2', damage, GIB_ORGANIC);
      self.deadflag := DEAD_DEAD;
      exit;
    end;

    if self.deadflag = DEAD_DEAD then
      exit;

    self.deadflag := DEAD_DEAD;
    self.takedamage := DAMAGE_YES;
    self.monsterinfo.currentmove := @boss2_move_death;
  {$IFEND}
end;

function Boss2_CheckAttack(self : edict_p):qboolean; cdecl;
var
  spot1, spot2  : vec3_t;
  temp          : vec3_t;
  chance        : single;
  tr            : trace_t;
  enemy_infront : qboolean;
  enemy_range   : integer;
  enemy_yaw     : single;
begin
  if self.enemy.health > 0 then
  begin
    // see if any entities are in the way of the shot
    VectorCopy(self.s.origin, spot1);
    spot1[2] := spot1[2] + self.viewheight;
    VectorCopy(self.enemy.s.origin, spot2);
    spot2[2] := spot2[2] + self.enemy.viewheight;

    tr := gi.trace(@spot1, nil, nil, @spot2, self, (CONTENTS_SOLID or CONTENTS_MONSTER or CONTENTS_SLIME or CONTENTS_LAVA));

    // do we have a clear shot?
    if tr.ent <> self.enemy then
    begin
      Result := false;
      Exit;
    end;
  end;

  enemy_infront := infront(self, self.enemy);
  enemy_range := range(self, self.enemy);
  VectorSubtract(self.enemy.s.origin, self.s.origin, temp);
  enemy_yaw := vectoyaw(temp);

  self.ideal_yaw := enemy_yaw;


  // melee attack
  if enemy_range = RANGE_MELEE then
  begin
    if @self.monsterinfo.melee <> nil then
      self.monsterinfo.attack_state := AS_MELEE
    else
      self.monsterinfo.attack_state := AS_MISSILE;
    Result := true;
    Exit;
  end;
   
  // missile attack
  if @self.monsterinfo.attack = nil then
  begin
    Result := false;
    Exit;
  end;
      
  if level.time < self.monsterinfo.attack_finished then
  begin
    Result := false;
    Exit;
  end;
      
  if enemy_range = RANGE_FAR then
  begin
    Result := false;
    Exit;
  end;

  if (self.monsterinfo.aiflags and AI_STAND_GROUND) <> 0 then
    chance := 0.4
  else
  if enemy_range = RANGE_MELEE then
    chance := 0.8
  else
  if enemy_range = RANGE_NEAR then
    chance := 0.8
  else
  if enemy_range = RANGE_MID then
    chance := 0.8
  else
  begin
    Result := false;
    Exit;
  end;

  if _random() < chance then
  begin
    self.monsterinfo.attack_state    := AS_MISSILE;
    self.monsterinfo.attack_finished := level.time + 2*_random();
    Result := true;
    Exit;
  end;

  if (self.flags and FL_FLY) <> 0 then
  begin
    if _random() < 0.3 then
      self.monsterinfo.attack_state := AS_SLIDING
    else
      self.monsterinfo.attack_state := AS_STRAIGHT;
  end;

  Result := false;
end;



{QUAKED monster_boss2 (1 .5 0) (-56 -56 0) (56 56 80) Ambush Trigger_Spawn Sight
}
procedure SP_monster_boss2(self : edict_p);
begin
  if deathmatch.Value <> 0 then
  begin
    G_FreeEdict(self);
    exit;
  end;

  sound_pain1   := gi.soundindex('bosshovr/bhvpain1.wav');
  sound_pain2   := gi.soundindex('bosshovr/bhvpain2.wav');
  sound_pain3   := gi.soundindex('bosshovr/bhvpain3.wav');
  sound_death   := gi.soundindex('bosshovr/bhvdeth1.wav');
  sound_search1 := gi.soundindex('bosshovr/bhvunqv1.wav');

  self.s.sound  := gi.soundindex('bosshovr/bhvengn1.wav');

  self.movetype := MOVETYPE_STEP;
  self.solid := SOLID_BBOX;
  self.s.modelindex := gi.modelindex('models/monsters/boss2/tris.md2');
  VectorSet(self.mins, -56, -56,  0);
  VectorSet(self.maxs,  56,  56, 80);

  self.health := 2000;
  self.gib_health := -200;
  self.mass := 1000;

  self.flags := self.flags or FL_IMMUNE_LASER;

  self.pain := boss2_pain;
  self.die  := boss2_die;

  self.monsterinfo.stand       := boss2_stand;
  self.monsterinfo.walk        := boss2_walk;
  self.monsterinfo.run         := boss2_run;
  self.monsterinfo.attack      := boss2_attack;
  self.monsterinfo.search      := boss2_search;
  self.monsterinfo.checkattack := Boss2_CheckAttack;
  gi.linkentity(self);

  self.monsterinfo.currentmove := @boss2_move_stand;
  self.monsterinfo.scale       := MODEL_SCALE;

  flymonster_start(self);
end;

end.

