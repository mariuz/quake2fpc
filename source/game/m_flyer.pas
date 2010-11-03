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
{ File(s): m_flyer.c                                                         }
{                                                                            }
{ Initial conversion by : YgriK (Igor Karpov) - glYgriK@hotbox.ru            }
{ Initial conversion on : 01-Feb-2002                                        }
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
{ 1) inc:  m_flyer                                                           }
{                                                                            }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{ 1) Do more tests                                                           }
{                                                                            }
{----------------------------------------------------------------------------}

{*
==============================================================================

flyer

==============================================================================
*}


unit m_flyer;

interface

uses g_local;

procedure SP_monster_flyer (self : edict_p); cdecl;

implementation

uses q_shared, gameunit, m_flash , g_ai, g_main, g_local_add, game_add,
  g_utils, g_monster, g_weapon, g_misc, CPas;

{$I 'm_flyer.inc'}


var
  nextmove: Integer;  // Used for start/stop frames

  sound_sight,
  sound_idle,
  sound_pain1,
  sound_pain2,
  sound_slash,
  sound_sproing,
  sound_die: Integer;


procedure flyer_check_melee (self : edict_p); cdecl; forward;
procedure flyer_loop_melee (self : edict_p); cdecl; forward;
(*void flyer_melee (edict_t *self);
void flyer_setstart (edict_t *self);
void flyer_stand (edict_t *self);*)
procedure flyer_nextmove (self : edict_p); cdecl; forward;


procedure flyer_sight (self, other : edict_p); cdecl;
begin
  gi.sound (self, CHAN_VOICE, sound_sight, 1, ATTN_NORM, 0);
end;

procedure flyer_idle (self : edict_p); cdecl;
begin
  gi.sound (self, CHAN_VOICE, sound_idle, 1, ATTN_IDLE, 0);
end;

procedure flyer_pop_blades (self : edict_p); cdecl;
begin
  gi.sound (self, CHAN_VOICE, sound_sproing, 1, ATTN_NORM, 0);
end;

const
  flyer_frames_stand : array [0..44] of mframe_t = (
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
  flyer_move_stand : mmove_t = (firstframe: FRAME_stand01;  lastframe: FRAME_stand45;  frame: @flyer_frames_stand;  endfunc: Nil);

  flyer_frames_walk : array [0..44] of mframe_t = (
    (aifunc: ai_walk;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 5;  thinkfunc: Nil) );
  flyer_move_walk : mmove_t = (firstframe: FRAME_stand01;  lastframe: FRAME_stand45;  frame: @flyer_frames_walk;  endfunc: Nil);

  flyer_frames_run : array [0..44] of mframe_t = (
    (aifunc: ai_run;  dist: 10;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 10;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 10;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 10;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 10;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 10;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 10;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 10;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 10;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 10;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 10;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 10;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 10;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 10;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 10;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 10;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 10;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 10;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 10;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 10;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 10;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 10;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 10;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 10;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 10;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 10;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 10;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 10;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 10;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 10;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 10;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 10;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 10;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 10;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 10;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 10;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 10;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 10;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 10;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 10;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 10;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 10;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 10;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 10;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 10;  thinkfunc: Nil) );
  flyer_move_run : mmove_t = (firstframe: FRAME_stand01;  lastframe: FRAME_stand45;  frame: @flyer_frames_run;  endfunc: Nil);

procedure flyer_run (self : edict_p); cdecl;
begin
  if (self^.monsterinfo.aiflags AND AI_STAND_GROUND) <> 0 then
    self^.monsterinfo.currentmove := @flyer_move_stand
  else
    self^.monsterinfo.currentmove := @flyer_move_run;
end;

procedure flyer_walk (self : edict_p); cdecl;
begin
  self^.monsterinfo.currentmove := @flyer_move_walk;
end;

procedure flyer_stand (self : edict_p); cdecl;
begin
  self^.monsterinfo.currentmove := @flyer_move_stand;
end;

var
  flyer_frames_start : array [0..5] of mframe_t = (
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: flyer_nextmove) );
  flyer_move_start : mmove_t = (firstframe: FRAME_start01;  lastframe: FRAME_start06;  frame: @flyer_frames_start;  endfunc: Nil);

  flyer_frames_stop : array [0..6] of mframe_t = (
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: flyer_nextmove) );
  flyer_move_stop : mmove_t = (firstframe: FRAME_stop01;  lastframe: FRAME_stop07;  frame: @flyer_frames_stop; endfunc: Nil);


procedure flyer_stop (self : edict_p);
begin
  self^.monsterinfo.currentmove := @flyer_move_stop;
end;

procedure flyer_start (self : edict_p);
begin
  self^.monsterinfo.currentmove := @flyer_move_start;
end;


var
  flyer_frames_rollright : array [0..8] of mframe_t = (
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil) );
  flyer_move_rollright : mmove_t = (firstframe: FRAME_rollr01;  lastframe: FRAME_rollr09;  frame: @flyer_frames_rollright;  endfunc: Nil);

  flyer_frames_rollleft : array [0..8] of mframe_t = (
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil) );
  flyer_move_rollleft : mmove_t = (firstframe: FRAME_rollf01;  lastframe: FRAME_rollf09;  frame: @flyer_frames_rollleft;  endfunc: Nil);

  flyer_frames_pain3 : array [0..3] of mframe_t = (
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil) );
  flyer_move_pain3 : mmove_t = (firstframe: FRAME_pain301;  lastframe: FRAME_pain304;  frame: @flyer_frames_pain3; endfunc: flyer_run);

  flyer_frames_pain2 : array [0..3] of mframe_t = (
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil) );
  flyer_move_pain2 : mmove_t = (firstframe: FRAME_pain201;  lastframe: FRAME_pain204; frame: @flyer_frames_pain2; endfunc: flyer_run);

  flyer_frames_pain1 : array [0..8] of mframe_t = (
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil) );
  flyer_move_pain1 : mmove_t = (firstframe: FRAME_pain101;  lastframe: FRAME_pain109;  frame: @flyer_frames_pain1;  endfunc: flyer_run);

  flyer_frames_defense : array [0..5] of mframe_t = (
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),      // Hold this frame
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil) );
  flyer_move_defense : mmove_t = (firstframe: FRAME_defens01;  lastframe: FRAME_defens06;  frame: @flyer_frames_defense;  endfunc: Nil);

  flyer_frames_bankright : array [0..6] of mframe_t = (
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil) );
  flyer_move_bankright : mmove_t = (firstframe: FRAME_bankr01;  lastframe: FRAME_bankr07;  frame: @flyer_frames_bankright;  endfunc: Nil);

  flyer_frames_bankleft : array [0..6] of mframe_t = (
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil) );
  flyer_move_bankleft : mmove_t = (firstframe: FRAME_bankl01;  lastframe: FRAME_bankl07;  frame: @flyer_frames_bankleft;  endfunc: Nil);


procedure flyer_fire (self : edict_p; flash_number : integer);
var
  start, forward_, right, end_, dir: vec3_t;
  effect: Integer;
begin
  if ( (self^.s.frame = FRAME_attak204) OR (self^.s.frame = FRAME_attak207) OR (self^.s.frame = FRAME_attak210) ) then
    effect := EF_HYPERBLASTER
  else
    effect := 0;

  AngleVectors (self^.s.angles, @forward_, @right, Nil);
  G_ProjectSource (self^.s.origin, monster_flash_offset[flash_number], forward_, right, start);

  VectorCopy (self^.enemy^.s.origin, end_);
  end_[2] := end_[2] + self^.enemy^.viewheight;
  VectorSubtract (end_, start, dir);

  monster_fire_blaster (self, start, dir, 1, 1000, flash_number, effect);
end;

procedure flyer_fireleft (self : edict_p); cdecl;
begin
  flyer_fire (self, MZ2_FLYER_BLASTER_1);
end;

procedure flyer_fireright (self : edict_p); cdecl;
begin
  flyer_fire (self, MZ2_FLYER_BLASTER_2);
end;

var
  flyer_frames_attack2 : array [0..16] of mframe_t = (
    (aifunc: ai_charge;  dist: 0;    thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;    thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;    thinkfunc: Nil),
    (aifunc: ai_charge;  dist: -10;  thinkfunc: flyer_fireleft),   // left gun
    (aifunc: ai_charge;  dist: -10;  thinkfunc: flyer_fireright),  // right gun
    (aifunc: ai_charge;  dist: -10;  thinkfunc: flyer_fireleft),   // left gun
    (aifunc: ai_charge;  dist: -10;  thinkfunc: flyer_fireright),  // right gun
    (aifunc: ai_charge;  dist: -10;  thinkfunc: flyer_fireleft),   // left gun
    (aifunc: ai_charge;  dist: -10;  thinkfunc: flyer_fireright),  // right gun
    (aifunc: ai_charge;  dist: -10;  thinkfunc: flyer_fireleft),   // left gun
    (aifunc: ai_charge;  dist: -10;  thinkfunc: flyer_fireright),  // right gun
    (aifunc: ai_charge;  dist: 0;    thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;    thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;    thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;    thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;    thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;    thinkfunc: Nil) );
  flyer_move_attack2 : mmove_t = (firstframe: FRAME_attak201;  lastframe: FRAME_attak217;  frame: @flyer_frames_attack2;  endfunc: flyer_run);


procedure flyer_slash_left (self : edict_p); cdecl;
var
  aim : vec3_t;
begin
  VectorSet (aim, MELEE_DISTANCE, self^.mins[0], 0);
  fire_hit (self, aim, 5, 0);
  gi.sound (self, CHAN_WEAPON, sound_slash, 1, ATTN_NORM, 0);
end;

procedure flyer_slash_right (self : edict_p); cdecl;
var
  aim : vec3_t;
begin
  VectorSet (aim, MELEE_DISTANCE, self^.maxs[0], 0);
  fire_hit (self, aim, 5, 0);
  gi.sound (self, CHAN_WEAPON, sound_slash, 1, ATTN_NORM, 0);
end;

var
  flyer_frames_start_melee : array [0..5] of mframe_t = (
    (aifunc: ai_charge;  dist: 0;  thinkfunc: flyer_pop_blades),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil) );
  flyer_move_start_melee : mmove_t = (firstframe: FRAME_attak101;  lastframe: FRAME_attak106;  frame: @flyer_frames_start_melee;  endfunc: flyer_loop_melee);

  flyer_frames_end_melee : array [0..2] of mframe_t = (
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil), 
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil) );
  flyer_move_end_melee : mmove_t = (firstframe: FRAME_attak119;  lastframe: FRAME_attak121;  frame: @flyer_frames_end_melee;  endfunc: flyer_run);

  flyer_frames_loop_melee : array [0..11] of mframe_t = (
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),              // Loop Start
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: flyer_slash_left),  // Left Wing Strike
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: flyer_slash_right), // Right Wing Strike
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil) );         // Loop Ends
  flyer_move_loop_melee : mmove_t = (firstframe: FRAME_attak107;  lastframe: FRAME_attak118;  frame: @flyer_frames_loop_melee;  endfunc: flyer_check_melee);


procedure flyer_loop_melee (self : edict_p); cdecl;
begin
{ifsoft Originally Commented out
/*   if (random() <= 0.5)
      self->monsterinfo.currentmove = &flyer_move_attack1;
   else */}
  self^.monsterinfo.currentmove := @flyer_move_loop_melee;
end;

procedure flyer_attack (self : edict_p); cdecl;
begin
{idsoft Originally Commented out
/*   if (random() <= 0.5)
      self->monsterinfo.currentmove = &flyer_move_attack1;
   else */}
  self^.monsterinfo.currentmove := @flyer_move_attack2;
end;

procedure flyer_setstart (self : edict_p);
begin
  nextmove := ACTION_run;
  self^.monsterinfo.currentmove := @flyer_move_start;
end;

procedure flyer_nextmove (self : edict_p); cdecl;
begin
  if (nextmove = ACTION_attack1) then
    self^.monsterinfo.currentmove := @flyer_move_start_melee
  else if (nextmove = ACTION_attack2) then
    self^.monsterinfo.currentmove := @flyer_move_attack2
  else if (nextmove = ACTION_run) then
    self^.monsterinfo.currentmove := @flyer_move_run;
end;

procedure flyer_melee (self : edict_p); cdecl;
begin
  { The Following Lines were originally commented out }
//  flyer.nextmove = ACTION_attack1;
//  self->monsterinfo.currentmove = &flyer_move_stop;
  self^.monsterinfo.currentmove := @flyer_move_start_melee;
end;

procedure flyer_check_melee (self : edict_p); cdecl;
begin
  if (range(self, self^.enemy) = RANGE_MELEE) then
    if (_random() <= 0.8) then
      self^.monsterinfo.currentmove := @flyer_move_loop_melee
    else
      self^.monsterinfo.currentmove := @flyer_move_end_melee
  else
    self^.monsterinfo.currentmove := @flyer_move_end_melee;
end;

procedure flyer_pain (self, other : edict_p; kick : single; damage : integer); cdecl;
var
  n : integer;
begin
  if (self^.health < (self^.max_health div 2)) then
    self^.s.skinnum := 1;

  if (level.time < self^.pain_debounce_time) then
    Exit;

  self^.pain_debounce_time := level.time + 3;
  if (skill^.value = 3) then
    Exit;   // no pain anims in nightmare

  n := rand() mod 3;
  if (n = 0) then
  begin
    gi.sound (self, CHAN_VOICE, sound_pain1, 1, ATTN_NORM, 0);
    self^.monsterinfo.currentmove := @flyer_move_pain1;
  end else if (n = 1) then
  begin
    gi.sound (self, CHAN_VOICE, sound_pain2, 1, ATTN_NORM, 0);
    self^.monsterinfo.currentmove := @flyer_move_pain2;
  end
  else
  begin
    gi.sound (self, CHAN_VOICE, sound_pain1, 1, ATTN_NORM, 0);
    self^.monsterinfo.currentmove := @flyer_move_pain3;
  end;
end;

procedure flyer_die (self, inflictor, attacker : edict_p; damage : integer; const point : vec3_t); cdecl;
begin
  gi.sound (self, CHAN_VOICE, sound_die, 1, ATTN_NORM, 0);
  BecomeExplosion1(self);
end;

//*QUAKED monster_flyer (1 .5 0) (-16 -16 -24) (16 16 32) Ambush Trigger_Spawn Sight
procedure SP_monster_flyer (self : edict_p);
begin
  if (deathmatch^.value <> 0) then
  begin
    G_FreeEdict(self);
    Exit;
  end;

  // fix a map bug in jail5.bsp
  if ((Q_stricmp(level.mapname, 'jail5') = 0) AND (self^.s.origin[2] = -104)) then
  begin
    self^.targetname := self^.target;
    self^.target := Nil;
  end;

  sound_sight := gi.soundindex ('flyer/flysght1.wav');
  sound_idle := gi.soundindex ('flyer/flysrch1.wav');
  sound_pain1 := gi.soundindex ('flyer/flypain1.wav');
  sound_pain2 := gi.soundindex ('flyer/flypain2.wav');
  sound_slash := gi.soundindex ('flyer/flyatck2.wav');
  sound_sproing := gi.soundindex ('flyer/flyatck1.wav');
  sound_die := gi.soundindex ('flyer/flydeth1.wav');

  gi.soundindex ('flyer/flyatck3.wav');

  self^.s.modelindex := gi.modelindex ('models/monsters/flyer/tris.md2');
  VectorSet (self^.mins, -16, -16, -24);
  VectorSet (self^.maxs, 16, 16, 32);
  self^.movetype := MOVETYPE_STEP;
  self^.solid := SOLID_BBOX;

  self^.s.sound := gi.soundindex ('flyer/flyidle1.wav');

  self^.health := 50;
  self^.mass := 50;

  self^.pain := flyer_pain;
  self^.die := flyer_die;

  self^.monsterinfo.stand := flyer_stand;
  self^.monsterinfo.walk := flyer_walk;
  self^.monsterinfo.run := flyer_run;
  self^.monsterinfo.attack := flyer_attack;
  self^.monsterinfo.melee := flyer_melee;
  self^.monsterinfo.sight := flyer_sight;
  self^.monsterinfo.idle := flyer_idle;

  gi.linkentity (self);

  self^.monsterinfo.currentmove := @flyer_move_stand;
  self^.monsterinfo.scale := MODEL_SCALE;

  flymonster_start (self);
end;

// End of file
end.

