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
{ File(s): m_boss31.h                                                         }
{                                                                            }
{ Initial conversion by : Ben Watt (ben@delphigamedev.com)                   }
{ Initial conversion on : 10-March-2002                                        }
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

jorg

==============================================================================
}

unit m_boss31;

interface

uses
  g_local,
  m_boss3;

const MODEL_SCALE     = 1.000000;

var
  sound_pain1,
  sound_pain2,
  sound_pain3,
  sound_idle,
  sound_death,
  sound_search1,
  sound_search2,
  sound_search3,
  sound_attack1,
  sound_attack2,
  sound_firegun,
  sound_step_left,
  sound_step_right,
  sound_death_hit       : Integer;

{$I m_boss31.inc}

procedure SP_monster_jorg(self : edict_p); cdecl;

implementation

uses g_main, q_shared, g_ai, m_boss32, m_supertank, g_utils, m_flash,
  g_monster, game_add, GameUnit, g_local_add;

procedure jorg_idle(self : edict_p); cdecl; forward;
procedure jorg_step_left(self : edict_p); cdecl; forward;
procedure jorg_step_right(self : edict_p); cdecl; forward;
procedure jorg_dead(self : edict_p); cdecl; forward;
procedure jorgBFG(self : edict_p); cdecl; forward;
procedure jorg_attack1(self : edict_p); cdecl; forward;
procedure jorg_firebullet(self : edict_p); cdecl; forward;
procedure jorg_reattack1(self : edict_p); cdecl; forward;

procedure jorg_search(self : edict_p);cdecl;
var
  r : single;
begin
  r := _random();

  if r <= 0.3 then
    gi.sound(self, CHAN_VOICE, sound_search1, 1, ATTN_NORM, 0)
  else
  if r <= 0.6 then
    gi.sound(self, CHAN_VOICE, sound_search2, 1, ATTN_NORM, 0)
  else
    gi.sound(self, CHAN_VOICE, sound_search3, 1, ATTN_NORM, 0);
end;

//
// stand
//

const
  jorg_frames_stand : Array[0..50] of mframe_t =
    ((aifunc:ai_stand; dist:0;   thinkfunc:jorg_idle),
     (aifunc:ai_stand; dist:0;   thinkfunc:nil),
     (aifunc:ai_stand; dist:0;   thinkfunc:nil),
     (aifunc:ai_stand; dist:0;   thinkfunc:nil),
     (aifunc:ai_stand; dist:0;   thinkfunc:nil),
     (aifunc:ai_stand; dist:0;   thinkfunc:nil),
     (aifunc:ai_stand; dist:0;   thinkfunc:nil),
     (aifunc:ai_stand; dist:0;   thinkfunc:nil),
     (aifunc:ai_stand; dist:0;   thinkfunc:nil),
     (aifunc:ai_stand; dist:0;   thinkfunc:nil),         // 10
     (aifunc:ai_stand; dist:0;   thinkfunc:nil),
     (aifunc:ai_stand; dist:0;   thinkfunc:nil),
     (aifunc:ai_stand; dist:0;   thinkfunc:nil),
     (aifunc:ai_stand; dist:0;   thinkfunc:nil),
     (aifunc:ai_stand; dist:0;   thinkfunc:nil),
     (aifunc:ai_stand; dist:0;   thinkfunc:nil),
     (aifunc:ai_stand; dist:0;   thinkfunc:nil),
     (aifunc:ai_stand; dist:0;   thinkfunc:nil),
     (aifunc:ai_stand; dist:0;   thinkfunc:nil),
     (aifunc:ai_stand; dist:0;   thinkfunc:nil),         // 20
     (aifunc:ai_stand; dist:0;   thinkfunc:nil),
     (aifunc:ai_stand; dist:0;   thinkfunc:nil),
     (aifunc:ai_stand; dist:0;   thinkfunc:nil),
     (aifunc:ai_stand; dist:0;   thinkfunc:nil),
     (aifunc:ai_stand; dist:0;   thinkfunc:nil),
     (aifunc:ai_stand; dist:0;   thinkfunc:nil),
     (aifunc:ai_stand; dist:0;   thinkfunc:nil),
     (aifunc:ai_stand; dist:0;   thinkfunc:nil),
     (aifunc:ai_stand; dist:0;   thinkfunc:nil),
     (aifunc:ai_stand; dist:0;   thinkfunc:nil),         // 30
     (aifunc:ai_stand; dist:0;   thinkfunc:nil),
     (aifunc:ai_stand; dist:0;   thinkfunc:nil),
     (aifunc:ai_stand; dist:0;   thinkfunc:nil),
     (aifunc:ai_stand; dist:19;  thinkfunc:nil),
     (aifunc:ai_stand; dist:11;  thinkfunc:jorg_step_left),
     (aifunc:ai_stand; dist:0;   thinkfunc:nil),
     (aifunc:ai_stand; dist:0;   thinkfunc:nil),
     (aifunc:ai_stand; dist:6;   thinkfunc:nil),
     (aifunc:ai_stand; dist:9;   thinkfunc:jorg_step_right),
     (aifunc:ai_stand; dist:0;   thinkfunc:nil),         // 40
     (aifunc:ai_stand; dist:0;   thinkfunc:nil),
     (aifunc:ai_stand; dist:0;   thinkfunc:nil),
     (aifunc:ai_stand; dist:0;   thinkfunc:nil),
     (aifunc:ai_stand; dist:0;   thinkfunc:nil),
     (aifunc:ai_stand; dist:0;   thinkfunc:nil),
     (aifunc:ai_stand; dist:0;   thinkfunc:nil),
     (aifunc:ai_stand; dist:0;   thinkfunc:nil),
     (aifunc:ai_stand; dist:-17; thinkfunc:jorg_step_left),
     (aifunc:ai_stand; dist:0;   thinkfunc:nil),
     (aifunc:ai_stand; dist:-12; thinkfunc:nil),         // 50
     (aifunc:ai_stand; dist:-14; thinkfunc:jorg_step_right)); // 51

  jorg_move_stand : mmove_t =
    (firstframe:FRAME_stand01; lastframe:FRAME_stand51; frame:@jorg_frames_stand; endfunc:nil);

procedure jorg_idle(self : edict_p);
begin
  gi.sound(self, CHAN_VOICE, sound_idle, 1, ATTN_NORM,0);
end;

procedure jorg_death_hit(self : edict_p);
begin
  gi.sound(self, CHAN_BODY, sound_death_hit, 1, ATTN_NORM,0);
end;


procedure jorg_step_left(self : edict_p);
begin
  gi.sound(self, CHAN_BODY, sound_step_left, 1, ATTN_NORM,0);
end;

procedure jorg_step_right(self : edict_p);
begin
  gi.sound(self, CHAN_BODY, sound_step_right, 1, ATTN_NORM,0);
end;


procedure jorg_stand(self : edict_p);cdecl;
begin
  self.monsterinfo.currentmove := @jorg_move_stand;
end;

const
  jorg_frames_run : Array[0..13] of mframe_t =
    ((aifunc:ai_run; dist:17; thinkfunc:jorg_step_left),
     (aifunc:ai_run; dist:0; thinkfunc:nil),
     (aifunc:ai_run; dist:0; thinkfunc:nil),
     (aifunc:ai_run; dist:0; thinkfunc:nil),
     (aifunc:ai_run; dist:12; thinkfunc:nil),
     (aifunc:ai_run; dist:8; thinkfunc:nil),
     (aifunc:ai_run; dist:10; thinkfunc:nil),
     (aifunc:ai_run; dist:33; thinkfunc:jorg_step_right),
     (aifunc:ai_run; dist:0; thinkfunc:nil),
     (aifunc:ai_run; dist:0; thinkfunc:nil),
     (aifunc:ai_run; dist:0; thinkfunc:nil),
     (aifunc:ai_run; dist:9; thinkfunc:nil),
     (aifunc:ai_run; dist:9; thinkfunc:nil),
     (aifunc:ai_run; dist:9; thinkfunc:nil));

  jorg_move_run : mmove_t =
    (firstframe:FRAME_walk06; lastframe:FRAME_walk19; frame:@jorg_frames_run; endfunc:nil);

//
// walk
//

  jorg_frames_start_walk : Array[0..4] of mframe_t =
    ((aifunc:ai_walk; dist:5;  thinkfunc:nil),
     (aifunc:ai_walk; dist:6;  thinkfunc:nil),
     (aifunc:ai_walk; dist:7;  thinkfunc:nil),
     (aifunc:ai_walk; dist:9;  thinkfunc:nil),
     (aifunc:ai_walk; dist:15; thinkfunc:nil));

  jorg_move_start_walk : mmove_t =
    (firstframe:FRAME_walk01; lastframe:FRAME_walk05; frame:@jorg_frames_start_walk; endfunc:nil);

  jorg_frames_walk : Array[0..13] of mframe_t =
    ((aifunc:ai_walk; dist:17; thinkfunc:nil),
     (aifunc:ai_walk; dist:0;  thinkfunc:nil),
     (aifunc:ai_walk; dist:0;  thinkfunc:nil),
     (aifunc:ai_walk; dist:0;  thinkfunc:nil),
     (aifunc:ai_walk; dist:12; thinkfunc:nil),
     (aifunc:ai_walk; dist:8;  thinkfunc:nil),
     (aifunc:ai_walk; dist:10; thinkfunc:nil),
     (aifunc:ai_walk; dist:33; thinkfunc:nil),
     (aifunc:ai_walk; dist:0;  thinkfunc:nil),
     (aifunc:ai_walk; dist:0;  thinkfunc:nil),
     (aifunc:ai_walk; dist:0;  thinkfunc:nil),
     (aifunc:ai_walk; dist:9;  thinkfunc:nil),
     (aifunc:ai_walk; dist:9;  thinkfunc:nil),
     (aifunc:ai_walk; dist:9;  thinkfunc:nil));

  jorg_move_walk : mmove_t =
    (firstframe:FRAME_walk06; lastframe:FRAME_walk19; frame:@jorg_frames_walk; endfunc:nil);

  jorg_frames_end_walk : Array[0..5] of mframe_t =
    ((aifunc:ai_walk; dist:11; thinkfunc:nil),
     (aifunc:ai_walk; dist:0;  thinkfunc:nil),
     (aifunc:ai_walk; dist:0;  thinkfunc:nil),
     (aifunc:ai_walk; dist:0;  thinkfunc:nil),
     (aifunc:ai_walk; dist:8;  thinkfunc:nil),
     (aifunc:ai_walk; dist:-8; thinkfunc:nil));

  jorg_move_end_walk : mmove_t =
    (firstframe:FRAME_walk20; lastframe:FRAME_walk25; frame:@jorg_frames_end_walk; endfunc:nil);

procedure jorg_walk(self : edict_p);cdecl;
begin
  self.monsterinfo.currentmove := @jorg_move_walk;
end;

procedure jorg_run(self : edict_p); cdecl;
begin
  if (self.monsterinfo.aiflags and AI_STAND_GROUND) <> 0 then
    self.monsterinfo.currentmove := @jorg_move_stand
  else
    self.monsterinfo.currentmove := @jorg_move_run;
end;

const
  jorg_frames_pain3 : Array[0..24] of mframe_t =
    ((aifunc:ai_move; dist:-28; thinkfunc:nil),
     (aifunc:ai_move; dist:-6;  thinkfunc:nil),
     (aifunc:ai_move; dist:-3;  thinkfunc:jorg_step_left),
     (aifunc:ai_move; dist:-9;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:jorg_step_right),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:-7;  thinkfunc:nil),
     (aifunc:ai_move; dist:1;   thinkfunc:nil),
     (aifunc:ai_move; dist:-11; thinkfunc:nil),
     (aifunc:ai_move; dist:-4;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:10;  thinkfunc:nil),
     (aifunc:ai_move; dist:11;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:10;  thinkfunc:nil),
     (aifunc:ai_move; dist:3;   thinkfunc:nil),
     (aifunc:ai_move; dist:10;  thinkfunc:nil),
     (aifunc:ai_move; dist:7;   thinkfunc:jorg_step_left),
     (aifunc:ai_move; dist:17;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:jorg_step_right));

  jorg_move_pain3 : mmove_t =
    (firstframe:FRAME_pain301; lastframe:FRAME_pain325; frame:@jorg_frames_pain3; endfunc:jorg_run);

  jorg_frames_pain2 : Array[0..2] of mframe_t =
    ((aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil));

  jorg_move_pain2 : mmove_t =
    (firstframe:FRAME_pain201; lastframe:FRAME_pain203; frame:@jorg_frames_pain2; endfunc:jorg_run);

  jorg_frames_pain1 : Array[0..2] of mframe_t =
    ((aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil));

  jorg_move_pain1 : mmove_t =
    (firstframe:FRAME_pain101; lastframe:FRAME_pain103; frame:@jorg_frames_pain1; endfunc:jorg_run);

  jorg_frames_death1 : Array[0..49] of mframe_t =
    ((aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),      // 10
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),      // 20
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),      // 30
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),      // 40
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:MakronToss),
     (aifunc:ai_move; dist:0; thinkfunc:BossExplode));   // 50

  jorg_move_death : mmove_t =
    (firstframe:FRAME_death01; lastframe:FRAME_death50; frame:@jorg_frames_death1; endfunc:jorg_dead);

  jorg_frames_attack2 : Array[0..12] of mframe_t =
    ((aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:jorgBFG),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil));

  jorg_move_attack2 : mmove_t =
    (firstframe:FRAME_attak201; lastframe:FRAME_attak213; frame:@jorg_frames_attack2; endfunc:jorg_run);

  jorg_frames_start_attack1 : Array[0..7] of mframe_t =
    ((aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:nil));

  jorg_move_start_attack1 : mmove_t =
    (firstframe:FRAME_attak101; lastframe:FRAME_attak108; frame:@jorg_frames_start_attack1; endfunc:jorg_attack1);

  jorg_frames_attack1 : Array[0..5] of mframe_t =
    ((aifunc:ai_charge; dist:0; thinkfunc:jorg_firebullet),
     (aifunc:ai_charge; dist:0; thinkfunc:jorg_firebullet),
     (aifunc:ai_charge; dist:0; thinkfunc:jorg_firebullet),
     (aifunc:ai_charge; dist:0; thinkfunc:jorg_firebullet),
     (aifunc:ai_charge; dist:0; thinkfunc:jorg_firebullet),
     (aifunc:ai_charge; dist:0; thinkfunc:jorg_firebullet));

  jorg_move_attack1 : mmove_t =
    (firstframe:FRAME_attak109; lastframe:FRAME_attak114; frame:@jorg_frames_attack1; endfunc:jorg_reattack1);

  jorg_frames_end_attack1 : Array[0..3] of mframe_t =
    ((aifunc:ai_move; dist:0; thinkfunc:jorg_firebullet),
     (aifunc:ai_move; dist:0; thinkfunc:jorg_firebullet),
     (aifunc:ai_move; dist:0; thinkfunc:jorg_firebullet),
     (aifunc:ai_move; dist:0; thinkfunc:jorg_firebullet));

  jorg_move_end_attack1 : mmove_t =
    (firstframe:FRAME_attak115; lastframe:FRAME_attak118; frame:@jorg_frames_end_attack1; endfunc:jorg_run);

procedure jorg_reattack1(self : edict_p);
begin
  if visible(self, self.enemy) then
  begin
    if (_random() < 0.9) then
      self.monsterinfo.currentmove := @jorg_move_attack1
    else
    begin
      self.s.sound := 0;
      self.monsterinfo.currentmove := @jorg_move_end_attack1;
    end
  end
  else
  begin
    self.s.sound := 0;
    self.monsterinfo.currentmove := @jorg_move_end_attack1;
  end;
end;

procedure jorg_attack1(self : edict_p);
begin
  self.monsterinfo.currentmove := @jorg_move_attack1;
end;

procedure jorg_pain(self, other : edict_p; kick : single; damage : integer);cdecl;
begin
  if (self.health < (self.max_health / 2)) then
    self.s.skinnum := 1;

  self.s.sound := 0;

  if level.time < self.pain_debounce_time then
    exit;

  // Lessen the chance of him going into his pain frames if he takes little damage
  if damage <= 40 then
    if (_random()<=0.6) then
      exit;

  {
  If he's entering his attack1 or using attack1, lessen the chance of him
  going into pain
  }

  if ( (self.s.frame >= FRAME_attak101) and (self.s.frame <= FRAME_attak108) ) then
  begin
    if (_random() <= 0.005) then
      exit;
  end;

  if ( (self.s.frame >= FRAME_attak109) and (self.s.frame <= FRAME_attak114) ) then
  begin
    if (_random() <= 0.00005) then
      exit;
  end;

  if ( (self.s.frame >= FRAME_attak201) and (self.s.frame <= FRAME_attak208) ) then
  begin
    if (_random() <= 0.005) then
      exit;
  end;

  self.pain_debounce_time := level.time + 3;
  if skill.value = 3 then
    exit;      // no pain anims in nightmare

  if damage <= 50 then
  begin
    gi.sound(self, CHAN_VOICE, sound_pain1, 1, ATTN_NORM,0);
    self.monsterinfo.currentmove := @jorg_move_pain1;
  end
  else
  if damage <= 100 then
  begin
    gi.sound(self, CHAN_VOICE, sound_pain2, 1, ATTN_NORM,0);
    self.monsterinfo.currentmove := @jorg_move_pain2;
  end
  else
  begin
    if (_random() <= 0.3) then
    begin
      gi.sound(self, CHAN_VOICE, sound_pain3, 1, ATTN_NORM,0);
      self.monsterinfo.currentmove := @jorg_move_pain3;
    end;
  end;
end;

procedure jorgBFG(self : edict_p);
var
  fwrd, right : vec3_t;
  start       : vec3_t;
  dir         : vec3_t;
  vec         : vec3_t;
begin
  AngleVectors(self.s.angles, @fwrd, @right, nil);
  G_ProjectSource(self.s.origin, monster_flash_offset[MZ2_JORG_BFG_1], fwrd, right, start);

  VectorCopy(self.enemy.s.origin, vec);
  vec[2] := vec[2] + self.enemy.viewheight;
  VectorSubtract(vec, start, dir);
  VectorNormalize(dir);
  gi.sound(self, CHAN_VOICE, sound_attack2, 1, ATTN_NORM, 0);
  {void monster_fire_bfg (edict_t *self,
                                                vec3_t start,
                                                vec3_t aimdir,
                  int damage,
                  int speed,
                  int kick,
                  float damage_radius,
                  int flashtype)}
  monster_fire_bfg(self, start, dir, 50, 300, 100, 200, MZ2_JORG_BFG_1);
end;

procedure jorg_firebullet_right(self : edict_p);
var
  fwrd, right, target : vec3_t;
  start               : vec3_t;
begin
  AngleVectors(self.s.angles, @fwrd, @right, nil);
  G_ProjectSource(self.s.origin, monster_flash_offset[MZ2_JORG_MACHINEGUN_R1], fwrd, right, start);

  VectorMA(self.enemy.s.origin, -0.2, self.enemy.velocity, target);
  target[2] := target[2] + self.enemy.viewheight;
  VectorSubtract(target, start, fwrd);
  VectorNormalize(fwrd);

  monster_fire_bullet(self, start, fwrd, 6, 4, DEFAULT_BULLET_HSPREAD, DEFAULT_BULLET_VSPREAD, MZ2_JORG_MACHINEGUN_R1);
end;

procedure jorg_firebullet_left(self : edict_p);
var
  fwrd, right, target : vec3_t;
  start               : vec3_t;
begin
  AngleVectors(self.s.angles, @fwrd, @right, nil);
  G_ProjectSource(self.s.origin, monster_flash_offset[MZ2_JORG_MACHINEGUN_L1], fwrd, right, start);

  VectorMA(self.enemy.s.origin, -0.2, self.enemy.velocity, target);
  target[2] := target[2] + self.enemy.viewheight;
  VectorSubtract(target, start, fwrd);
  VectorNormalize(fwrd);

  monster_fire_bullet(self, start, fwrd, 6, 4, DEFAULT_BULLET_HSPREAD, DEFAULT_BULLET_VSPREAD, MZ2_JORG_MACHINEGUN_L1);
end;

procedure jorg_firebullet(self : edict_p);
begin
  jorg_firebullet_left(self);
  jorg_firebullet_right(self);
end;

procedure jorg_attack(self : edict_p);cdecl;
var
  vec   : vec3_t;
  range : single;
begin
  VectorSubtract(self.enemy.s.origin, self.s.origin, vec);
  range := VectorLength(vec);

  if (_random() <= 0.75) then
  begin
    gi.sound(self, CHAN_VOICE, sound_attack1, 1, ATTN_NORM,0);
    self.s.sound := gi.soundindex('boss3/w_loop.wav');
    self.monsterinfo.currentmove := @jorg_move_start_attack1;
  end
  else
  begin
    gi.sound(self, CHAN_VOICE, sound_attack2, 1, ATTN_NORM,0);
    self.monsterinfo.currentmove := @jorg_move_attack2;
  end;
end;

procedure jorg_dead(self : edict_p);
var
  tempent : edict_p;
begin
{IF FALSE}
  {
  VectorSet (self->mins, -16, -16, -24);
  VectorSet (self->maxs, 16, 16, -8);
  }
   
  // Jorg is on modelindex2. Do not clear him.
  VectorSet(self.mins, -60, -60, 0);
  VectorSet(self.maxs, 60, 60, 72);
  self.movetype := MOVETYPE_TOSS;
  self.nextthink := 0;
  gi.linkentity(self);

  tempent := G_Spawn();
  VectorCopy(self.s.origin, tempent.s.origin);
  VectorCopy(self.s.angles, tempent.s.angles);
  tempent.killtarget := self.killtarget;
  tempent.target := self.target;
  tempent.activator := self.enemy;
  self.killtarget := nil;
  self.target := nil;
  SP_monster_makron(tempent);
{IFEND}
end;


procedure jorg_die(self, inflictor, attacker : edict_p; damage : integer;const  point : vec3_t);cdecl;
begin
  gi.sound(self, CHAN_VOICE, sound_death, 1, ATTN_NORM, 0);
  self.deadflag   := DEAD_DEAD;
  self.takedamage := DAMAGE_NO;
  self.s.sound    := 0;
  self.count      := 0;
  self.monsterinfo.currentmove := @jorg_move_death;
end;

function Jorg_CheckAttack(self : edict_p): qboolean;cdecl;
var
  spot1, spot2 : vec3_t;
  temp         : vec3_t;
  chance       : single;
  tr           : trace_t;
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
    if (tr.ent <> self.enemy) then
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
    if (@self.monsterinfo.melee<>nil) then
      self.monsterinfo.attack_state := AS_MELEE
    else
      self.monsterinfo.attack_state := AS_MISSILE;
    Result := True;
    Exit;
  end;
   
  // missile attack
  if (@self.monsterinfo.attack=nil) then
  begin
    Result := False;
    Exit;
  end;
      
  if level.time < self.monsterinfo.attack_finished then
  begin
    Result := False;
    Exit;
  end;

  if enemy_range = RANGE_FAR then
  begin
    Result := False;
    Exit;
  end;

  if (self.monsterinfo.aiflags and AI_STAND_GROUND) <> 0 then
    chance := 0.4
  else
  if (enemy_range = RANGE_MELEE) then
    chance := 0.8
  else
  if (enemy_range = RANGE_NEAR) then
    chance := 0.4
  else
  if (enemy_range = RANGE_MID) then
    chance := 0.2
  else
  begin
    Result := false;
    Exit;
  end;

  if (_random() < chance) then
  begin
    self.monsterinfo.attack_state := AS_MISSILE;
    self.monsterinfo.attack_finished := level.time + 2*_random();
    Result := true;
    Exit;
  end;

  if (self.flags and FL_FLY) <> 0 then
  begin
    if (_random() < 0.3) then
      self.monsterinfo.attack_state := AS_SLIDING
    else
      self.monsterinfo.attack_state := AS_STRAIGHT;
  end;

  Result := false;
end;

{QUAKED monster_jorg (1 .5 0) (-80 -80 0) (90 90 140) Ambush Trigger_Spawn Sight
}
procedure SP_monster_jorg(self : edict_p);
begin
  if (deathmatch.Value <> 0) then
  begin
    G_FreeEdict(self);
    exit;
  end;

  sound_pain1      := gi.soundindex('boss3/bs3pain1.wav');
  sound_pain2      := gi.soundindex('boss3/bs3pain2.wav');
  sound_pain3      := gi.soundindex('boss3/bs3pain3.wav');
  sound_death      := gi.soundindex('boss3/bs3deth1.wav');
  sound_attack1    := gi.soundindex('boss3/bs3atck1.wav');
  sound_attack2    := gi.soundindex('boss3/bs3atck2.wav');
  sound_search1    := gi.soundindex('boss3/bs3srch1.wav');
  sound_search2    := gi.soundindex('boss3/bs3srch2.wav');
  sound_search3    := gi.soundindex('boss3/bs3srch3.wav');
  sound_idle       := gi.soundindex('boss3/bs3idle1.wav');
  sound_step_left  := gi.soundindex('boss3/step1.wav');
  sound_step_right := gi.soundindex('boss3/step2.wav');
  sound_firegun    := gi.soundindex('boss3/xfire.wav');
  sound_death_hit  := gi.soundindex('boss3/d_hit.wav');

  MakronPrecache();
  self.movetype := MOVETYPE_STEP;
  self.solid := SOLID_BBOX;
  self.s.modelindex := gi.modelindex('models/monsters/boss3/rider/tris.md2');
  self.s.modelindex2 := gi.modelindex('models/monsters/boss3/jorg/tris.md2');
  VectorSet(self.mins, -80, -80,   0);
  VectorSet(self.maxs, 80,   80, 140);

  self.health := 3000;
  self.gib_health := -2000;
  self.mass := 1000;

  self.pain := jorg_pain;
  self.die := jorg_die;
  self.monsterinfo.stand := jorg_stand;
  self.monsterinfo.walk := jorg_walk;
  self.monsterinfo.run := jorg_run;
  self.monsterinfo.dodge := nil;
  self.monsterinfo.attack := jorg_attack;
  self.monsterinfo.search := jorg_search;
  self.monsterinfo.melee := nil;
  self.monsterinfo.sight := niL;
  self.monsterinfo.checkattack := Jorg_CheckAttack;
  gi.linkentity(self);

  self.monsterinfo.currentmove := @jorg_move_stand;
  self.monsterinfo.scale := MODEL_SCALE;

  walkmonster_start(self);
end;


end.

