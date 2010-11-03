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
{ File(s): m_boss32.h                                                        }
{                                                                            }
{ Initial conversion by : Ben Watt (ben@delphigamedev.com)                   }
{ Initial conversion on : 11-Feb-2002                                        }
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

Makron -- Final Boss

==============================================================================
}

unit m_boss32;

interface

uses
  g_local,
  q_shared;

var
  sound_pain4,
  sound_pain5,
  sound_pain6,
  sound_death,
  sound_step_left,
  sound_step_right,
  sound_attack_bfg,
  sound_brainsplorch,
  sound_prerailgun,
  sound_popup,
  sound_taunt1,
  sound_taunt2,
  sound_taunt3,
  sound_hit           : Integer;

{$I m_boss32.inc}

procedure makron_taunt(self : edict_p); cdecl;
procedure makron_stand(self : edict_p); cdecl;
procedure makron_hit(self : edict_p); cdecl;
procedure makron_popup(self : edict_p); cdecl;
procedure makron_step_left(self : edict_p); cdecl;
procedure makron_step_right(self : edict_p); cdecl;
procedure makron_brainsplorch(self : edict_p); cdecl;
procedure makron_prerailgun(self : edict_p); cdecl;
procedure makron_walk(self : edict_p); cdecl;
procedure makron_run(self : edict_p); cdecl;
procedure makronBFG(self : edict_p); cdecl;
procedure MakronSaveloc(self : edict_p); cdecl;
procedure MakronRailgun(self : edict_p); cdecl;
procedure MakronHyperblaster(self : edict_p); cdecl;
procedure makron_pain(self, other : edict_p; kick : single; damage : integer); cdecl;
procedure makron_sight(self, other : edict_p); cdecl;
procedure makron_attack(self : edict_p); cdecl;
procedure makron_torso_think(self : edict_p); cdecl;
procedure makron_torso(ent : edict_p); cdecl;
procedure makron_dead(self : edict_p); cdecl;
procedure makron_die(self, inflictor, attacker : edict_p;  damage : integer; const point : vec3_t); cdecl;
function  Makron_CheckAttack(self : edict_p): qboolean; cdecl;
procedure MakronPrecache; cdecl;
procedure SP_monster_makron(self : edict_p); cdecl;
procedure MakronSpawn(self : edict_p); cdecl;
procedure MakronToss(self : edict_p); cdecl;

implementation

uses g_ai, g_main, g_misc, game_add, g_utils, m_flash, g_monster,
  g_local_add, GameUnit;

procedure makron_taunt(self : edict_p);
var
  r : single;
begin
  r := _random();
  if r <= 0.3 then
    gi.sound(self, CHAN_AUTO, sound_taunt1, 1, ATTN_NONE, 0)
  else
  if r <= 0.6 then
    gi.sound(self, CHAN_AUTO, sound_taunt2, 1, ATTN_NONE, 0)
  else
    gi.sound(self, CHAN_AUTO, sound_taunt3, 1, ATTN_NONE, 0);
end;

//
// stand
//

const
  makron_frames_stand : Array[0..59] of mframe_t =
    ((aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),      // 10
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),      // 20
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),      // 30
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),      // 40
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),      // 50
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil));      // 60

  makron_move_stand : mmove_t =
    (firstframe:FRAME_stand201; lastframe:FRAME_stand260; frame:@makron_frames_stand; endfunc:nil);

procedure makron_stand(self : edict_p);
begin
  self.monsterinfo.currentmove := @makron_move_stand;
end;

const
  makron_frames_run : Array[0..9] of mframe_t =
    ((aifunc:ai_run; dist:3;  thinkfunc:makron_step_left),
     (aifunc:ai_run; dist:12; thinkfunc:nil),
     (aifunc:ai_run; dist:8;  thinkfunc:nil),
     (aifunc:ai_run; dist:8;  thinkfunc:nil),
     (aifunc:ai_run; dist:8;  thinkfunc:makron_step_right),
     (aifunc:ai_run; dist:6;  thinkfunc:nil),
     (aifunc:ai_run; dist:12; thinkfunc:nil),
     (aifunc:ai_run; dist:9;  thinkfunc:nil),
     (aifunc:ai_run; dist:6;  thinkfunc:nil),
     (aifunc:ai_run; dist:12; thinkfunc:nil));

  makron_move_run : mmove_t =
    (firstframe:FRAME_stand204; lastframe:FRAME_stand213; frame:@makron_frames_run; endfunc:nil);

procedure makron_hit(self : edict_p);
begin
  gi.sound(self, CHAN_AUTO, sound_hit, 1, ATTN_NONE,0);
end;

procedure makron_popup(self : edict_p);
begin
  gi.sound(self, CHAN_BODY, sound_popup, 1, ATTN_NONE,0);
end;

procedure makron_step_left(self : edict_p);
begin
  gi.sound(self, CHAN_BODY, sound_step_left, 1, ATTN_NORM,0);
end;

procedure makron_step_right(self : edict_p); 
begin
  gi.sound(self, CHAN_BODY, sound_step_right, 1, ATTN_NORM,0);
end;

procedure makron_brainsplorch(self : edict_p);
begin
  gi.sound(self, CHAN_VOICE, sound_brainsplorch, 1, ATTN_NORM,0);
end;

procedure makron_prerailgun(self : edict_p);
begin
  gi.sound(self, CHAN_WEAPON, sound_prerailgun, 1, ATTN_NORM,0);
end;

const
  makron_frames_walk : Array[0..9] of mframe_t =
    ((aifunc:ai_walk; dist:3;  thinkfunc:makron_step_left),
     (aifunc:ai_walk; dist:12; thinkfunc:nil),
     (aifunc:ai_walk; dist:8;  thinkfunc:nil),
     (aifunc:ai_walk; dist:8;  thinkfunc:nil),
     (aifunc:ai_walk; dist:8;  thinkfunc:makron_step_right),
     (aifunc:ai_walk; dist:6;  thinkfunc:nil),
     (aifunc:ai_walk; dist:12; thinkfunc:nil),
     (aifunc:ai_walk; dist:9;  thinkfunc:nil),
     (aifunc:ai_walk; dist:6;  thinkfunc:nil),
     (aifunc:ai_walk; dist:12; thinkfunc:nil));

  makron_move_walk : mmove_t =
    (firstframe:FRAME_walk204; lastframe:FRAME_walk213; frame:@makron_frames_run; endfunc:nil);

procedure makron_walk(self : edict_p);
begin
  self.monsterinfo.currentmove := @makron_move_walk;
end;

procedure makron_run(self : edict_p);
begin
  if (self.monsterinfo.aiflags and AI_STAND_GROUND) <> 0 then
    self.monsterinfo.currentmove := @makron_move_stand
  else
    self.monsterinfo.currentmove := @makron_move_run;
end;

const
  makron_frames_pain6 : Array[0..26] of mframe_t =
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
     (aifunc:ai_move; dist:0; thinkfunc:makron_popup),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),      // 20
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:makron_taunt),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil));

  makron_move_pain6 : mmove_t =
    (firstframe:FRAME_pain601; lastframe:FRAME_pain627; frame:@makron_frames_pain6; endfunc:makron_run);

  makron_frames_pain5 : Array[0..3] of mframe_t =
    ((aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil));

  makron_move_pain5 : mmove_t =
    (firstframe:FRAME_pain501; lastframe:FRAME_pain504; frame:@makron_frames_pain5; endfunc:makron_run);

  makron_frames_pain4 : Array[0..3] of mframe_t =
    ((aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil));

  makron_move_pain4 : mmove_t =
    (firstframe:FRAME_pain401; lastframe:FRAME_pain404; frame:@makron_frames_pain4; endfunc:makron_run);

  makron_frames_death2 : Array[0..94] of mframe_t =
    ((aifunc:ai_move; dist:-15; thinkfunc:nil),
     (aifunc:ai_move; dist:3;   thinkfunc:nil),
     (aifunc:ai_move; dist:-12; thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:makron_step_left),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),              // 10
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:11;  thinkfunc:nil),
     (aifunc:ai_move; dist:12;  thinkfunc:nil),
     (aifunc:ai_move; dist:11;  thinkfunc:makron_step_right),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),              // 20
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),              // 30
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:5;   thinkfunc:nil),
     (aifunc:ai_move; dist:7;   thinkfunc:nil),
     (aifunc:ai_move; dist:6;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:-1;  thinkfunc:nil),
     (aifunc:ai_move; dist:2;   thinkfunc:nil),              // 40
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),              // 50
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:-6;  thinkfunc:nil),
     (aifunc:ai_move; dist:-4;  thinkfunc:nil),
     (aifunc:ai_move; dist:-6;  thinkfunc:makron_step_right),
     (aifunc:ai_move; dist:-4;  thinkfunc:nil),
     (aifunc:ai_move; dist:-4;  thinkfunc:makron_step_left),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),              // 60
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:-2;  thinkfunc:nil),
     (aifunc:ai_move; dist:-5;  thinkfunc:nil),
     (aifunc:ai_move; dist:-3;  thinkfunc:makron_step_right),
     (aifunc:ai_move; dist:-8;  thinkfunc:nil),
     (aifunc:ai_move; dist:-3;  thinkfunc:makron_step_left),
     (aifunc:ai_move; dist:-7;  thinkfunc:nil),
     (aifunc:ai_move; dist:-4;  thinkfunc:nil),
     (aifunc:ai_move; dist:-4;  thinkfunc:makron_step_right),   // 70
     (aifunc:ai_move; dist:-6;  thinkfunc:nil),
     (aifunc:ai_move; dist:-7;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:makron_step_left),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),              // 80
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:-2;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:2;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),              // 90
     (aifunc:ai_move; dist:27;  thinkfunc:makron_hit),
     (aifunc:ai_move; dist:26;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:makron_brainsplorch),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil));      // 95

  makron_move_death2 : mmove_t =
    (firstframe:FRAME_death201; lastframe:FRAME_death295; frame:@makron_frames_death2; endfunc:makron_dead);

  makron_frames_death3 : Array[0..19] of mframe_t =
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
     (aifunc:ai_move; dist:0; thinkfunc:nil));

  makron_move_death3 : mmove_t =
    (firstframe:FRAME_death301; lastframe:FRAME_death320; frame:@makron_frames_death3; endfunc:nil);

  makron_frames_sight : Array[0..12] of mframe_t =
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
     (aifunc:ai_move; dist:0; thinkfunc:nil));

  makron_move_sight : mmove_t =
    (firstframe:FRAME_active01; lastframe:FRAME_active13; frame:@makron_frames_sight; endfunc:makron_run);

procedure makronBFG(self : edict_p);
var
  fwrd, right : vec3_t;
  start       : vec3_t;
  dir         : vec3_t;
  vec         : vec3_t;
begin
  AngleVectors(self.s.angles, @fwrd, @right, nil);
  G_ProjectSource(self.s.origin, monster_flash_offset[MZ2_MAKRON_BFG], fwrd, right, start);
  VectorCopy(self.enemy.s.origin, vec);
  vec[2] := vec[2] + self.enemy.viewheight;
  VectorSubtract(vec, start, dir);
  VectorNormalize(dir);
  gi.sound(self, CHAN_VOICE, sound_attack_bfg, 1, ATTN_NORM, 0);
  monster_fire_bfg(self, start, dir, 50, 300, 100, 300, MZ2_MAKRON_BFG);
end;

const
  makron_frames_attack3 : Array[0..7] of mframe_t =
    ((aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:makronBFG),    // FIXME: BFG Attack here
     (aifunc:ai_move;   dist:0; thinkfunc:nil),
     (aifunc:ai_move;   dist:0; thinkfunc:nil),
     (aifunc:ai_move;   dist:0; thinkfunc:nil),
     (aifunc:ai_move;   dist:0; thinkfunc:nil));

  makron_move_attack3 : mmove_t =
    (firstframe:FRAME_attak301; lastframe:FRAME_attak308; frame:@makron_frames_attack3; endfunc:makron_run);

  makron_frames_attack4 : Array[0..25] of mframe_t =
    ((aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_move;   dist:0; thinkfunc:MakronHyperblaster),      // fire
     (aifunc:ai_move;   dist:0; thinkfunc:MakronHyperblaster),      // fire
     (aifunc:ai_move;   dist:0; thinkfunc:MakronHyperblaster),      // fire
     (aifunc:ai_move;   dist:0; thinkfunc:MakronHyperblaster),      // fire
     (aifunc:ai_move;   dist:0; thinkfunc:MakronHyperblaster),      // fire
     (aifunc:ai_move;   dist:0; thinkfunc:MakronHyperblaster),      // fire
     (aifunc:ai_move;   dist:0; thinkfunc:MakronHyperblaster),      // fire
     (aifunc:ai_move;   dist:0; thinkfunc:MakronHyperblaster),      // fire
     (aifunc:ai_move;   dist:0; thinkfunc:MakronHyperblaster),      // fire
     (aifunc:ai_move;   dist:0; thinkfunc:MakronHyperblaster),      // fire
     (aifunc:ai_move;   dist:0; thinkfunc:MakronHyperblaster),      // fire
     (aifunc:ai_move;   dist:0; thinkfunc:MakronHyperblaster),      // fire
     (aifunc:ai_move;   dist:0; thinkfunc:MakronHyperblaster),      // fire
     (aifunc:ai_move;   dist:0; thinkfunc:MakronHyperblaster),      // fire
     (aifunc:ai_move;   dist:0; thinkfunc:MakronHyperblaster),      // fire
     (aifunc:ai_move;   dist:0; thinkfunc:MakronHyperblaster),      // fire
     (aifunc:ai_move;   dist:0; thinkfunc:MakronHyperblaster),      // fire
     (aifunc:ai_move;   dist:0; thinkfunc:nil),
     (aifunc:ai_move;   dist:0; thinkfunc:nil),
     (aifunc:ai_move;   dist:0; thinkfunc:nil),
     (aifunc:ai_move;   dist:0; thinkfunc:nil),
     (aifunc:ai_move;   dist:0; thinkfunc:nil));

  makron_move_attack4 : mmove_t =
    (firstframe:FRAME_attak401; lastframe:FRAME_attak426; frame:@makron_frames_attack4; endfunc:makron_run);

  makron_frames_attack5 : Array[0..15] of mframe_t =
    ((aifunc:ai_charge; dist:0; thinkfunc:makron_prerailgun),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:MakronSaveloc),
     (aifunc:ai_move;   dist:0; thinkfunc:MakronRailgun),    // Fire railgun
     (aifunc:ai_move;   dist:0; thinkfunc:nil),
     (aifunc:ai_move;   dist:0; thinkfunc:nil),
     (aifunc:ai_move;   dist:0; thinkfunc:nil),
     (aifunc:ai_move;   dist:0; thinkfunc:nil),
     (aifunc:ai_move;   dist:0; thinkfunc:nil),
     (aifunc:ai_move;   dist:0; thinkfunc:nil),
     (aifunc:ai_move;   dist:0; thinkfunc:nil));

  makron_move_attack5 : mmove_t =
    (firstframe:FRAME_attak501; lastframe:FRAME_attak516; frame:@makron_frames_attack5; endfunc:makron_run);

procedure MakronSaveloc(self : edict_p);
begin
  VectorCopy(self.enemy.s.origin, self.pos1);   //save for aiming the shot
  self.pos1[2] := self.pos1[2] + self.enemy.viewheight;
end;

// FIXME: He's not firing from the proper Z
procedure MakronRailgun(self : edict_p);
var
  start       : vec3_t;
  dir         : vec3_t;
  fwrd, right : vec3_t;
begin
  AngleVectors(self.s.angles, @fwrd, @right, nil);
  G_ProjectSource(self.s.origin, monster_flash_offset[MZ2_MAKRON_RAILGUN_1], fwrd, right, start);
   
  // calc direction to where we targted
  VectorSubtract(self.pos1, start, dir);
  VectorNormalize(dir);

  monster_fire_railgun(self, start, dir, 50, 100, MZ2_MAKRON_RAILGUN_1);
end;

// FIXME: This is all wrong. He's not firing at the proper angles.
procedure MakronHyperblaster(self : edict_p);
var
  dir          : vec3_t;
  vec          : vec3_t;
  start        : vec3_t;
  fwrd, right  : vec3_t;
  flash_number : integer;
begin
  flash_number := MZ2_MAKRON_BLASTER_1 + (self.s.frame - FRAME_attak405);

  AngleVectors(self.s.angles, @fwrd, @right, nil);
  G_ProjectSource(self.s.origin, monster_flash_offset[flash_number], fwrd, right, start);

  if (self.enemy <> nil) then
  begin
    VectorCopy(self.enemy.s.origin, vec);
    vec[2] := vec[2] + self.enemy.viewheight;
    VectorSubtract(vec, start, vec);
    vectoangles(vec, vec);
    dir[0] := vec[0];
  end
  else
    dir[0] := 0;

  if self.s.frame <= FRAME_attak413 then
    dir[1] := self.s.angles[1] - 10 * (self.s.frame - FRAME_attak413)
  else
    dir[1] := self.s.angles[1] + 10 * (self.s.frame - FRAME_attak421);

  dir[2] := 0;

  AngleVectors(dir, @fwrd, nil, nil);

  monster_fire_blaster(self, start, fwrd, 15, 1000, MZ2_MAKRON_BLASTER_1, EF_BLASTER);
end;

procedure makron_pain(self, other : edict_p; kick : single; damage : integer);
begin
  if (self.health < (self.max_health / 2)) then
    self.s.skinnum := 1;

  if (level.time < self.pain_debounce_time) then
    exit;

  // Lessen the chance of him going into his pain frames
  if damage <=25 then
  begin
    if (_random()<0.2) then
      exit;
  end;

  self.pain_debounce_time := level.time + 3;
  if (skill.value = 3) then
    exit;      // no pain anims in nightmare


  if (damage <= 40) then
  begin
    gi.sound(self, CHAN_VOICE, sound_pain4, 1, ATTN_NONE,0);
    self.monsterinfo.currentmove := @makron_move_pain4;
  end
  else
  if (damage <= 110) then
  begin
    gi.sound(self, CHAN_VOICE, sound_pain5, 1, ATTN_NONE,0);
    self.monsterinfo.currentmove := @makron_move_pain5;
  end
  else
  begin
    if (damage <= 150) then
    begin
      if (_random() <= 0.45) then
      begin
        gi.sound (self, CHAN_VOICE, sound_pain6, 1, ATTN_NONE,0);
        self.monsterinfo.currentmove := @makron_move_pain6;
      end
      else
      if (_random() <= 0.35) then
      begin
        gi.sound(self, CHAN_VOICE, sound_pain6, 1, ATTN_NONE,0);
        self.monsterinfo.currentmove := @makron_move_pain6;
      end;
    end;
  end;
end;

procedure makron_sight(self, other : edict_p);
begin
  self.monsterinfo.currentmove := @makron_move_sight;
end;

procedure makron_attack(self : edict_p);
var
  vec   : vec3_t;
  range : single;
  r     : single;
begin
  r := _random();

  VectorSubtract(self.enemy.s.origin, self.s.origin, vec);
  range := VectorLength(vec);

  if (r <= 0.3) then
    self.monsterinfo.currentmove := @makron_move_attack3
  else
  if (r <= 0.6) then
    self.monsterinfo.currentmove := @makron_move_attack4
  else
    self.monsterinfo.currentmove := @makron_move_attack5;
end;

{
---
Makron Torso. This needs to be spawned in
---
}

procedure makron_torso_think(self : edict_p);
begin
  self.s.frame := self.s.frame + 1;
  if (self.s.frame < 365) then
    self.nextthink := level.time + FRAMETIME
  else
  begin
    self.s.frame := 346;
    self.nextthink := level.time + FRAMETIME;
  end;
end;

procedure makron_torso(ent : edict_p);
begin
  ent.movetype := MOVETYPE_NONE;
  ent.solid := SOLID_NOT;
  VectorSet(ent.mins, -8, -8, 0);
  VectorSet(ent.maxs, 8, 8, 8);
  ent.s.frame := 346;
  ent.s.modelindex := gi.modelindex('models/monsters/boss3/rider/tris.md2');
  ent.think := makron_torso_think;
  ent.nextthink := level.time + 2 * FRAMETIME;
  ent.s.sound := gi.soundindex ('makron/spine.wav');
  gi.linkentity(ent);
end;

//
// death
//

procedure makron_dead(self : edict_p);
begin
  VectorSet(self.mins, -60, -60, 0);
  VectorSet(self.maxs, 60, 60, 72);
  self.movetype := MOVETYPE_TOSS;
  self.svflags := self.svflags or SVF_DEADMONSTER;
  self.nextthink := 0;
  gi.linkentity(self);
end;

procedure makron_die(self, inflictor, attacker : edict_p;  damage : integer; const point : vec3_t);
var
  tempent : edict_p;
  n : integer;
begin
  self.s.sound := 0;
  // check for gib
  if (self.health <= self.gib_health) then
  begin
    gi.sound(self, CHAN_VOICE, gi.soundindex('misc/udeath.wav'), 1, ATTN_NORM, 0);
//    for (n= 0; n < 1 /*4*/; n++)
    for n := 0 to 0 {3} do
      ThrowGib(self, 'models/objects/gibs/sm_meat/tris.md2', damage, GIB_ORGANIC);
    for n := 0 to 3 do
      ThrowGib(self, 'models/objects/gibs/sm_metal/tris.md2', damage, GIB_METALLIC);
    ThrowHead(self, 'models/objects/gibs/gear/tris.md2', damage, GIB_METALLIC);
    self.deadflag := DEAD_DEAD;
    exit;
  end;

  if (self.deadflag = DEAD_DEAD) then
    Exit;

  // regular death
  gi.sound(self, CHAN_VOICE, sound_death, 1, ATTN_NONE, 0);
  self.deadflag := DEAD_DEAD;
  self.takedamage := DAMAGE_YES;

  tempent := G_Spawn();
  VectorCopy(self.s.origin, tempent.s.origin);
  VectorCopy(self.s.angles, tempent.s.angles);
  tempent.s.origin[1] := tempent.s.origin[1] - 84;
  makron_torso(tempent);

  self.monsterinfo.currentmove := @makron_move_death2;
   
end;

function Makron_CheckAttack(self : edict_p): qboolean;
var
  spot1, spot2  : vec3_t;
  temp          : vec3_t;
  chance        : single;
  tr            : trace_t;
  enemy_infront : qboolean;
  enemy_range   : integer;
  enemy_yaw     : single;
begin
  if (self.enemy.health > 0) then
  begin
    // see if any entities are in the way of the shot
    VectorCopy(self.s.origin, spot1);
    spot1[2] := spot1[2] + self.viewheight;
    VectorCopy(self.enemy.s.origin, spot2);
    spot2[2] := spot2[2] + self.enemy.viewheight;

    tr := gi.trace(@spot1, nil, nil, @spot2, self, (CONTENTS_SOLID or CONTENTS_MONSTER or CONTENTS_SLIME or CONTENTS_LAVA));

    // do we have a clear shot?
    if (tr.ent <> self.enemy)  then
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
  if (enemy_range = RANGE_MELEE) then
  begin
    if (@self.monsterinfo.melee <> nil) then
      self.monsterinfo.attack_state := AS_MELEE
    else
      self.monsterinfo.attack_state := AS_MISSILE;
    Result := true;
    Exit;
  end;

  // missile attack
  if (@self.monsterinfo.attack = nil) then
  begin
    Result := false;
    Exit;
  end;

  if (level.time < self.monsterinfo.attack_finished) then
  begin
    Result := false;
    Exit;
  end;

  if (enemy_range = RANGE_FAR) then
  begin
    Result := false;
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
    Result := False;
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

//
// monster_makron
//

procedure MakronPrecache;
begin
  sound_pain4        := gi.soundindex('makron/pain3.wav');
  sound_pain5        := gi.soundindex('makron/pain2.wav');
  sound_pain6        := gi.soundindex('makron/pain1.wav');
  sound_death        := gi.soundindex('makron/death.wav');
  sound_step_left    := gi.soundindex('makron/step1.wav');
  sound_step_right   := gi.soundindex('makron/step2.wav');
  sound_attack_bfg   := gi.soundindex('makron/bfg_fire.wav');
  sound_brainsplorch := gi.soundindex('makron/brain1.wav');
  sound_prerailgun   := gi.soundindex('makron/rail_up.wav');
  sound_popup        := gi.soundindex('makron/popup.wav');
  sound_taunt1       := gi.soundindex('makron/voice4.wav');
  sound_taunt2       := gi.soundindex('makron/voice3.wav');
  sound_taunt3       := gi.soundindex('makron/voice.wav');
  sound_hit          := gi.soundindex('makron/bhit.wav');

  gi.modelindex('models/monsters/boss3/rider/tris.md2');
end;

{QUAKED monster_makron (1 .5 0) (-30 -30 0) (30 30 90) Ambush Trigger_Spawn Sight
}
procedure SP_monster_makron(self : edict_p);
begin
  if (deathmatch.Value <> 0) then
  begin
    G_FreeEdict(self);
    exit;
  end;

  MakronPrecache;

  self.movetype := MOVETYPE_STEP;
  self.solid := SOLID_BBOX;
  self.s.modelindex := gi.modelindex('models/monsters/boss3/rider/tris.md2');
  VectorSet(self.mins, -30, -30, 0);
  VectorSet(self.maxs, 30, 30, 90);

  self.health := 3000;
  self.gib_health := -2000;
  self.mass := 500;

  self.pain := makron_pain;
  self.die := makron_die;
  self.monsterinfo.stand := makron_stand;
  self.monsterinfo.walk := makron_walk;
  self.monsterinfo.run := makron_run;
  self.monsterinfo.dodge := nil;
  self.monsterinfo.attack := makron_attack;
  self.monsterinfo.melee := nil;
  self.monsterinfo.sight := makron_sight;
  self.monsterinfo.checkattack := Makron_CheckAttack;

  gi.linkentity(self);

//self.monsterinfo.currentmove := @makron_move_stand;
  self.monsterinfo.currentmove := @makron_move_sight;
  self.monsterinfo.scale := MODEL_SCALE;

  walkmonster_start(self);
end;


{
=================
MakronSpawn

=================
}
procedure MakronSpawn(self : edict_p);
var
  vec    : vec3_t;
  player : edict_p;
begin
  SP_monster_makron(self);

  // jump at player
  player := level.sight_client;
  if (player = nil) then
    exit;

  VectorSubtract(player.s.origin, self.s.origin, vec);
  self.s.angles[YAW] := vectoyaw(vec);
  VectorNormalize(vec);
  VectorMA(vec3_origin, 400, vec, self.velocity);
  self.velocity[2] := 200;
  self.groundentity := nil;
end;

{
=================
MakronToss

Jorg is just about dead, so set up to launch Makron out
=================
}
procedure MakronToss(self : edict_p);
var
  ent : edict_p;
begin
  ent := G_Spawn();
  ent.nextthink := level.time + 0.8;
  ent.think := MakronSpawn;
  ent.target := Self.target;
  VectorCopy(self.s.origin, ent.s.origin);
end;


end.
 
