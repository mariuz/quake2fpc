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
{ File(s): m_supertank.c                                                     }
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
{                                                                            }
{ .) unit: g_ai                                                              }
{                                                                            }
{ 1) inc:  m_supertank                                                       }
{                                                                            }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{ 1) Do more tests                                                           }
{                                                                            }
{----------------------------------------------------------------------------}


{*
==============================================================================

SUPERTANK

==============================================================================
*}

unit m_supertank;

interface

uses g_local;

procedure BossExplode (self : edict_p); cdecl;

procedure SP_monster_supertank (self : edict_p); cdecl;

implementation

uses q_shared, gameunit, m_flash , g_ai, g_main, g_misc, g_func, g_utils,
  g_monster, q_shared_add, game_add, g_local_add, CPas;

{$I m_supertank.inc}

var
  sound_pain1,
  sound_pain2,
  sound_pain3,
  sound_death,
  sound_search1,
  sound_search2,
  tread_sound : integer;


procedure supertank_dead (self : edict_p); cdecl; forward;
procedure supertankRocket (self : edict_p); cdecl; forward;
procedure supertankMachineGun (self : edict_p); cdecl; forward;
procedure supertank_reattack1 (self : edict_p); cdecl; forward;


procedure TreadSound (self : edict_p); cdecl;
begin
  gi.sound (self, CHAN_VOICE, tread_sound, 1, ATTN_NORM, 0);
end;

procedure supertank_search (self : edict_p); cdecl;
begin
  if (_random() < 0.5) then
    gi.sound (self, CHAN_VOICE, sound_search1, 1, ATTN_NORM, 0)
  else
    gi.sound (self, CHAN_VOICE, sound_search2, 1, ATTN_NORM, 0);
end;


//
// stand
//

//mframe_t supertank_frames_stand []=
const
  supertank_frames_stand : array[0..59] of mframe_t = (
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
  supertank_move_stand : mmove_t =
    (firstframe: FRAME_stand_1;  lastframe: FRAME_stand_60;  frame: @supertank_frames_stand;  endfunc: Nil);

procedure supertank_stand (self : edict_p); cdecl;
begin
  self^.monsterinfo.currentmove := @supertank_move_stand;
end;


const
  supertank_frames_run : array [0..17] of mframe_t = (
    (aifunc: ai_run;  dist: 12;  thinkfunc: TreadSound),
    (aifunc: ai_run;  dist: 12;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 12;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 12;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 12;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 12;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 12;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 12;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 12;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 12;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 12;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 12;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 12;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 12;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 12;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 12;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 12;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 12;  thinkfunc: Nil) );
  supertank_move_run : mmove_t =
    (firstframe: FRAME_forwrd_1;  lastframe: FRAME_forwrd_18;  frame: @supertank_frames_run;  endfunc: Nil);

//
// walk
//

const
  supertank_frames_forward : array [0..17] of mframe_t = (
    (aifunc: ai_walk;  dist: 4;  thinkfunc: TreadSound),
    (aifunc: ai_walk;  dist: 4;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 4;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 4;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 4;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 4;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 4;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 4;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 4;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 4;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 4;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 4;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 4;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 4;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 4;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 4;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 4;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 4;  thinkfunc: Nil) );
  supertank_move_forward : mmove_t =
    (firstframe: FRAME_forwrd_1;  lastframe: FRAME_forwrd_18;  frame: @supertank_frames_forward; endfunc: Nil);

procedure supertank_forward (self : edict_p);
begin
  self^.monsterinfo.currentmove := @supertank_move_forward;
end;

procedure supertank_walk (self : edict_p); cdecl;
begin
  self^.monsterinfo.currentmove := @supertank_move_forward;
end;

procedure supertank_run (self : edict_p); cdecl;
begin
  if (self^.monsterinfo.aiflags AND AI_STAND_GROUND) <> 0 then
    self^.monsterinfo.currentmove := @supertank_move_stand
  else
    self^.monsterinfo.currentmove := @supertank_move_run;
end;

const
  supertank_frames_turn_right : array [0..17] of mframe_t = (
    (aifunc: ai_move;  dist: 0;  thinkfunc: TreadSound),
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
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),      
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),      
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),      
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil) );      
  supertank_move_turn_right : mmove_t =
    (firstframe: FRAME_right_1;  lastframe: FRAME_right_18;  frame: @supertank_frames_turn_right; endfunc: supertank_run);

  supertank_frames_turn_left : array [0..17] of mframe_t = (
    (aifunc: ai_move;  dist: 0;  thinkfunc: TreadSound),
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
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),      
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),      
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),      
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil) );      
  supertank_move_turn_left : mmove_t =
    (firstframe: FRAME_left_1;  lastframe: FRAME_left_18;  frame: @supertank_frames_turn_left;  endfunc: supertank_run);

  supertank_frames_pain3 : array [0..3] of mframe_t = (
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil), 
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil), 
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil) );
  supertank_move_pain3 : mmove_t =
    (firstframe: FRAME_pain3_9;  lastframe: FRAME_pain3_12;  frame: @supertank_frames_pain3;  endfunc: supertank_run);

  supertank_frames_pain2 : array [0..3] of mframe_t = (
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil) );
  supertank_move_pain2 : mmove_t =
    (firstframe: FRAME_pain2_5;  lastframe: FRAME_pain2_8;  frame: @supertank_frames_pain2;  endfunc: supertank_run);

  supertank_frames_pain1 : array [0..3] of mframe_t = (
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),      
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),      
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),      
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil) );      
  supertank_move_pain1 : mmove_t =
    (firstframe: FRAME_pain1_1;  lastframe: FRAME_pain1_4;  frame: @supertank_frames_pain1;  endfunc: supertank_run);

  supertank_frames_death1 : array [0..23] of mframe_t = (
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
    (aifunc: ai_move;  dist: 0;  thinkfunc: BossExplode) );
  supertank_move_death : mmove_t =
    (firstframe: FRAME_death_1;  lastframe: FRAME_death_24;  frame: @supertank_frames_death1;  endfunc: supertank_dead);

  supertank_frames_backward : array [0..17] of mframe_t = (
    (aifunc: ai_walk;  dist: 0;  thinkfunc: TreadSound),
    (aifunc: ai_walk;  dist: 0;  thinkfunc: Nil),      
    (aifunc: ai_walk;  dist: 0;  thinkfunc: Nil),      
    (aifunc: ai_walk;  dist: 0;  thinkfunc: Nil),      
    (aifunc: ai_walk;  dist: 0;  thinkfunc: Nil),      
    (aifunc: ai_walk;  dist: 0;  thinkfunc: Nil),      
    (aifunc: ai_walk;  dist: 0;  thinkfunc: Nil),      
    (aifunc: ai_walk;  dist: 0;  thinkfunc: Nil),      
    (aifunc: ai_walk;  dist: 0;  thinkfunc: Nil),      
    (aifunc: ai_walk;  dist: 0;  thinkfunc: Nil),      
    (aifunc: ai_walk;  dist: 0;  thinkfunc: Nil),      
    (aifunc: ai_walk;  dist: 0;  thinkfunc: Nil),      
    (aifunc: ai_walk;  dist: 0;  thinkfunc: Nil),      
    (aifunc: ai_walk;  dist: 0;  thinkfunc: Nil),      
    (aifunc: ai_walk;  dist: 0;  thinkfunc: Nil),      
    (aifunc: ai_walk;  dist: 0;  thinkfunc: Nil),      
    (aifunc: ai_walk;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 0;  thinkfunc: Nil) );
  supertank_move_backward : mmove_t =
    (firstframe: FRAME_backwd_1;  lastframe: FRAME_backwd_18;  frame: @supertank_frames_backward;  endfunc: Nil);

  supertank_frames_attack4 : array [0..5] of mframe_t = (
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil) );
  supertank_move_attack4 : mmove_t =
    (firstframe: FRAME_attak4_1;  lastframe: FRAME_attak4_6;  frame: @supertank_frames_attack4;  endfunc: supertank_run);

  supertank_frames_attack3 : array [0..26] of mframe_t = (
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
  supertank_move_attack3 : mmove_t =
    (firstframe: FRAME_attak3_1;  lastframe: FRAME_attak3_27;  frame: @supertank_frames_attack3;  endfunc: supertank_run);

  supertank_frames_attack2 : array [0..26] of mframe_t = (
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: supertankRocket),
    (aifunc: ai_move;    dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;    dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;    dist: 0;  thinkfunc: supertankRocket),
    (aifunc: ai_move;    dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;    dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;    dist: 0;  thinkfunc: supertankRocket),
    (aifunc: ai_move;    dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;    dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;    dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;    dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;    dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;    dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;    dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;    dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;    dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;    dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;    dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;    dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;    dist: 0;  thinkfunc: Nil) );
  supertank_move_attack2 : mmove_t =
    (firstframe: FRAME_attak2_1;  lastframe: FRAME_attak2_27;  frame: @supertank_frames_attack2;  endfunc: supertank_run);

  supertank_frames_attack1 : array [0..5] of mframe_t = (
    (aifunc: ai_charge;  dist: 0;  thinkfunc: supertankMachineGun),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: supertankMachineGun),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: supertankMachineGun),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: supertankMachineGun),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: supertankMachineGun),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: supertankMachineGun) );
  supertank_move_attack1 : mmove_t =
    (firstframe: FRAME_attak1_1;  lastframe: FRAME_attak1_6;  frame: @supertank_frames_attack1;  endfunc: supertank_reattack1);

  supertank_frames_end_attack1 : array [0..13] of mframe_t = (
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
  supertank_move_end_attack1 : mmove_t =
    (firstframe: FRAME_attak1_7;  lastframe: FRAME_attak1_20;  frame: @supertank_frames_end_attack1;  endfunc: supertank_run);

procedure supertank_reattack1 (self : edict_p); cdecl;
begin
  if (visible(self, self^.enemy)) then
    if (_random() < 0.9) then
      self^.monsterinfo.currentmove := @supertank_move_attack1
    else
      self^.monsterinfo.currentmove := @supertank_move_end_attack1
  else
    self^.monsterinfo.currentmove := @supertank_move_end_attack1;
end;

procedure supertank_pain (self, other : edict_p; kick : single; damage : integer); cdecl;
begin
  if (self^.health < (self^.max_health / 2)) then
    self^.s.skinnum := 1;

  if (level.time < self^.pain_debounce_time) then
    Exit;

  // Lessen the chance of him going into his pain frames
  if (damage <= 25) then
    if (_random() < 0.2) then
      Exit;

  // Don't go into pain if he's firing his rockets
  if (skill^.value >= 2) then
    if (self^.s.frame >= FRAME_attak2_1) AND (self^.s.frame <= FRAME_attak2_14) then
      Exit;

  self^.pain_debounce_time := level.time + 3;

  if (skill^.value = 3) then
    Exit;   // no pain anims in nightmare

  if (damage <= 10) then
  begin
    gi.sound (self, CHAN_VOICE, sound_pain1, 1, ATTN_NORM,0);
    self^.monsterinfo.currentmove := @supertank_move_pain1;
  end
  else if (damage <= 25) then
  begin
    gi.sound (self, CHAN_VOICE, sound_pain3, 1, ATTN_NORM,0);
    self^.monsterinfo.currentmove := @supertank_move_pain2;
  end
  else
  begin
    gi.sound (self, CHAN_VOICE, sound_pain2, 1, ATTN_NORM,0);
    self^.monsterinfo.currentmove := @supertank_move_pain3;
  end;
end;


procedure supertankRocket (self : edict_p); cdecl;
var
  forward_, right,
  start,
  dir,
  vec           : vec3_t;
  flash_number  : integer;
begin
  if (self^.s.frame = FRAME_attak2_8) then
    flash_number := MZ2_SUPERTANK_ROCKET_1
  else if (self^.s.frame = FRAME_attak2_11) then
    flash_number := MZ2_SUPERTANK_ROCKET_2
  else //idsoft (self->s.frame == FRAME_attak2_14)
    flash_number := MZ2_SUPERTANK_ROCKET_3;

  AngleVectors (self^.s.angles, @forward_, @right, Nil);
  G_ProjectSource (self^.s.origin, monster_flash_offset[flash_number], forward_, right, start);

  VectorCopy (self^.enemy^.s.origin, vec);
  vec[2] := vec[2] + self^.enemy^.viewheight;
  VectorSubtract (vec, start, dir);
  VectorNormalize (dir);

  monster_fire_rocket (self, start, dir, 50, 500, flash_number);
end;


procedure supertankMachineGun (self : edict_p); cdecl; 
var
  dir,
  vec,
  start,
  forward_, right : vec3_t;
  flash_number   : integer;
begin
  flash_number := MZ2_SUPERTANK_MACHINEGUN_1 + (self^.s.frame - FRAME_attak1_1);

  //FIXME!!!
  dir[0] := 0;
  dir[1] := self^.s.angles[1];
  dir[2] := 0;

  AngleVectors (dir, @forward_, @right, Nil);
  G_ProjectSource (self^.s.origin, monster_flash_offset[flash_number], forward_, right, start);

  if (self^.enemy <> nil) then
  begin
    VectorCopy (self^.enemy^.s.origin, vec);
    VectorMA (vec, 0, self^.enemy^.velocity, vec);
    vec[2] := vec[2] + self^.enemy^.viewheight;
    VectorSubtract (vec, start, forward_);
    VectorNormalize (forward_);
  end;

  monster_fire_bullet (self, start, forward_, 6, 4, DEFAULT_BULLET_HSPREAD, DEFAULT_BULLET_VSPREAD, flash_number);
end;


procedure supertank_attack (self : edict_p); cdecl;
var
  vec   : vec3_t;
  range : single;
   //single   r;
begin
  VectorSubtract (self^.enemy^.s.origin, self^.s.origin, vec);
  range := VectorLength (vec);

  //r = _random();

  // Attack 1 == Chaingun
  // Attack 2 == Rocket Launcher

  if (range <= 160) then
    self^.monsterinfo.currentmove := @supertank_move_attack1
  else begin
    // fire rockets more often at distance
    if (_random() < 0.3) then
      self^.monsterinfo.currentmove := @supertank_move_attack1
    else
      self^.monsterinfo.currentmove := @supertank_move_attack2;
  end;
end;


//
// death
//

procedure supertank_dead (self : edict_p); cdecl;
begin
  VectorSet (self^.mins, -60, -60, 0);
  VectorSet (self^.maxs, 60, 60, 72);
  self^.movetype  := MOVETYPE_TOSS;
  self^.svflags   := self^.svflags OR SVF_DEADMONSTER;
  self^.nextthink := 0;
  gi.linkentity (self);
end;


procedure BossExplode (self : edict_p); cdecl;
var
  org : vec3_t;
  n   : integer;
begin
  self^.think := BossExplode;
  VectorCopy (self^.s.origin, org);
  org[2] := org[2] + 24 + (rand() AND 15);
  
//  switch (self->count++)
  Case self^.count of
    0: begin
         org[0] := org[0] -24;
         org[1] := org[1] -24;
       end;
    1: begin
         org[0] := org[0] +24;
         org[1] := org[1] +24;
       end;
    2: begin
         org[0] := org[0] +24;
         org[1] := org[1] -24;
       end;
    3: begin
         org[0] := org[0] -24;
         org[1] := org[1] +24;
       end;
    4: begin
         org[0] := org[0] -48;
         org[1] := org[1] -48;
       end;
    5: begin
         org[0] := org[0] +48;
         org[1] := org[1] +48;
       end;
    6: begin
         org[0] := org[0] -48;
         org[1] := org[1] +48;
       end;
    7: begin
         org[0] := org[0] +48;
         org[1] := org[1] -48;
       end;
    8: begin
         self^.s.sound := 0;
         for n:= 0 to 3 do
           ThrowGib (self, 'models/objects/gibs/sm_meat/tris.md2', 500, GIB_ORGANIC);
         for n:= 0 to 7 do
           ThrowGib (self, 'models/objects/gibs/sm_metal/tris.md2', 500, GIB_METALLIC);
         ThrowGib  (self, 'models/objects/gibs/chest/tris.md2', 500, GIB_ORGANIC);
         ThrowHead (self, 'models/objects/gibs/gear/tris.md2', 500, GIB_METALLIC);
         self^.deadflag := DEAD_DEAD;
         Exit;
       end;
  end; //case
  Inc (self.count); //case

  gi.WriteByte (svc_temp_entity);
  gi.WriteByte (Ord(TE_EXPLOSION1));
  gi.WritePosition (org);
  gi.multicast (@self^.s.origin, MULTICAST_PVS);

  self^.nextthink := level.time + 0.1;
end;


procedure supertank_die (self, inflictor, attacker : edict_p; damage : integer; const point : vec3_t); cdecl;
begin
  gi.sound (self, CHAN_VOICE, sound_death, 1, ATTN_NORM, 0);
  self^.deadflag := DEAD_DEAD;
  self^.takedamage := DAMAGE_NO;
  self^.count := 0;
  self^.monsterinfo.currentmove := @supertank_move_death;
end;

//
// monster_supertank
//

{*QUAKED monster_supertank (1 .5 0) (-64 -64 0) (64 64 72) Ambush Trigger_Spawn Sight
*}
procedure SP_monster_supertank (self : edict_p);
begin
  if (deathmatch^.Value <> 0) then
  begin
    G_FreeEdict (self);
    Exit;
  end;

  sound_pain1   := gi.soundindex ('bosstank/btkpain1.wav');
  sound_pain2   := gi.soundindex ('bosstank/btkpain2.wav');
  sound_pain3   := gi.soundindex ('bosstank/btkpain3.wav');
  sound_death   := gi.soundindex ('bosstank/btkdeth1.wav');
  sound_search1 := gi.soundindex ('bosstank/btkunqv1.wav');
  sound_search2 := gi.soundindex ('bosstank/btkunqv2.wav');

//idsoft  self->s.sound = gi.soundindex ("bosstank/btkengn1.wav");
  tread_sound := gi.soundindex ('bosstank/btkengn1.wav');

  self^.movetype := MOVETYPE_STEP;
  self^.solid := SOLID_BBOX;
  self^.s.modelindex := gi.modelindex ('models/monsters/boss1/tris.md2');
  VectorSet (self^.mins, -64, -64, 0);
  VectorSet (self^.maxs, 64, 64, 112);

  self^.health := 1500;
  self^.gib_health := -500;
  self^.mass := 800;

  self^.pain := supertank_pain;
  self^.die := supertank_die;
  self^.monsterinfo.stand := supertank_stand;
  self^.monsterinfo.walk := supertank_walk;
  self^.monsterinfo.run := supertank_run;
  self^.monsterinfo.dodge := nil;
  self^.monsterinfo.attack := supertank_attack;
  self^.monsterinfo.search := supertank_search;
  self^.monsterinfo.melee := nil;
  self^.monsterinfo.sight := nil;

  gi.linkentity (self);

  self^.monsterinfo.currentmove := @supertank_move_stand;
  self^.monsterinfo.scale := MODEL_SCALE;

  walkmonster_start(self);
end;

end.
