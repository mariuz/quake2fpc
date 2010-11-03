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
{ File(s): m_float.c                                                         }
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
{ 4) unit: m_flash                                                           }
{                                                                            }
{ .) unit: g_ai                                                              }
{                                                                            }
{ 1) inc:  m_float                                                           }
{                                                                            }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{ 1) Do more tests                                                           }
{                                                                            }
{----------------------------------------------------------------------------}

{*
==============================================================================

floater

==============================================================================
*}

{$I ..\jedi.inc}
unit m_float;

interface

uses g_local;

procedure SP_monster_floater (self : edict_p); cdecl;

implementation

uses q_shared, gameunit, m_flash , g_ai, q_shared_add, g_main, g_local_add,
  game_add, g_monster, g_utils, g_misc, g_weapon, g_combat, CPas;

{$I m_float.inc}




var
  sound_attack2,
  sound_attack3,
  sound_death1,
  sound_idle,
  sound_pain1,
  sound_pain2,
  sound_sight  : integer;


procedure floater_sight (self, other : edict_p); cdecl;
begin
  gi.sound (self, CHAN_VOICE, sound_sight, 1, ATTN_NORM, 0);
end;

procedure floater_idle (self : edict_p); cdecl;
begin
  gi.sound (self, CHAN_VOICE, sound_idle, 1, ATTN_IDLE, 0);
end;


//void floater_stand1 (edict_t *self);
procedure floater_dead (self : edict_p); cdecl; forward;
procedure floater_die (self, inflictor, attacker: edict_p; damage: Integer; const point: vec3_t); cdecl; forward;
procedure floater_run (self : edict_p); cdecl; forward;
procedure floater_wham (self : edict_p); cdecl; forward;
procedure floater_zap (self : edict_p); cdecl; forward;


procedure floater_fire_blaster (self : edict_p); cdecl;
var
  start,
  forward_, right,
  end_,
  dir : vec3_t;
  effect : integer;
begin
  if ((self^.s.frame = FRAME_attak104) OR (self^.s.frame = FRAME_attak107)) then
    effect := EF_HYPERBLASTER
  else
    effect := 0;
  AngleVectors (self^.s.angles, @forward_, @right, Nil);
  G_ProjectSource (self^.s.origin, monster_flash_offset[MZ2_FLOAT_BLASTER_1], forward_, right, start);

  VectorCopy (self^.enemy^.s.origin, end_);
  end_[2] := end_[2] + self^.enemy^.viewheight;
  VectorSubtract (end_, start, dir);

  monster_fire_blaster (self, start, dir, 1, 1000, MZ2_FLOAT_BLASTER_1, effect);
end;

const
  floater_frames_stand1 : array [0..51] of mframe_t = (
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
  floater_move_stand1 : mmove_t = (firstframe: FRAME_stand101;  lastframe: FRAME_stand152;  frame: @floater_frames_stand1;  endfunc: Nil);

  floater_frames_stand2 : array [0..51] of mframe_t = (
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
    (aifunc: ai_stand;  dist: 0;  thinkfunc: Nil)
);
  floater_move_stand2 : mmove_t = (firstframe: FRAME_stand201;  lastframe: FRAME_stand252;  frame: @floater_frames_stand2;  endfunc: Nil);

procedure floater_stand (self : edict_p); cdecl;
begin
  if (_random() <= 0.5) then
    self^.monsterinfo.currentmove := @floater_move_stand1
  else
    self^.monsterinfo.currentmove := @floater_move_stand2;
end;

const
  floater_frames_activate : array [0..29] of mframe_t = (
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
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil)
);
  floater_move_activate : mmove_t = (firstframe: FRAME_actvat01;  lastframe: FRAME_actvat31;  frame: @floater_frames_activate;  endfunc: Nil);

  floater_frames_attack1 : array [0..13] of mframe_t = (
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),                     // Blaster attack
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: floater_fire_blaster),   // BOOM (0, -25.8, 32.5)  -- LOOP Starts
    (aifunc: ai_charge;  dist: 0;  thinkfunc: floater_fire_blaster),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: floater_fire_blaster),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: floater_fire_blaster),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: floater_fire_blaster),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: floater_fire_blaster),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: floater_fire_blaster),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil) );             // -- LOOP Ends
  floater_move_attack1 : mmove_t = (firstframe: FRAME_attak101;  lastframe: FRAME_attak114;  frame: @floater_frames_attack1;  endfunc: floater_run);

  floater_frames_attack2 : array [0..24] of mframe_t = (
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),      // Claws
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: floater_wham),   // WHAM (0, -45, 29.6)    -- LOOP Starts
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),      // -- LOOP Ends
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil) );
  floater_move_attack2 : mmove_t = (firstframe: FRAME_attak201;  lastframe: FRAME_attak225;  frame: @floater_frames_attack2;  endfunc: floater_run);

  floater_frames_attack3 : array [0..33] of mframe_t = (
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: floater_zap),    // -- LOOP Starts
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),      //  -- LOOP Ends
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_charge;  dist: 0;  thinkfunc: Nil)
);
  floater_move_attack3 : mmove_t = (firstframe: FRAME_attak301;  lastframe: FRAME_attak334;  frame: @floater_frames_attack3;  endfunc: floater_run);

  floater_frames_death : array [0..12] of mframe_t = (
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
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil)
);
  floater_move_death : mmove_t = (firstframe: FRAME_death01;  lastframe: FRAME_death13;  frame: @floater_frames_death;  endfunc: floater_dead);

  floater_frames_pain1 : array [0..6] of mframe_t = (
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil)
);
  floater_move_pain1 : mmove_t = (firstframe: FRAME_pain101;  lastframe: FRAME_pain107;  frame: @floater_frames_pain1;  endfunc: floater_run);

  floater_frames_pain2 : array [0..7] of mframe_t = (
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil),
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil)
);
  floater_move_pain2 : mmove_t = (firstframe: FRAME_pain201;  lastframe: FRAME_pain208;  frame: @floater_frames_pain2;  endfunc: floater_run);

  floater_frames_pain3 : array [0..11] of mframe_t = (
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
    (aifunc: ai_move;  dist: 0;  thinkfunc: Nil)
);
  floater_move_pain3 : mmove_t = (firstframe: FRAME_pain301;  lastframe: FRAME_pain312;  frame: @floater_frames_pain3;  endfunc: floater_run);

  floater_frames_walk : array [0..51] of mframe_t = (
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
    (aifunc: ai_walk;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 5;  thinkfunc: Nil),
    (aifunc: ai_walk;  dist: 5;  thinkfunc: Nil) );
  floater_move_walk : mmove_t = (firstframe: FRAME_stand101;  lastframe: FRAME_stand152;  frame: @floater_frames_walk;  endfunc: Nil);

  floater_frames_run : array [0..51] of mframe_t = (
    (aifunc: ai_run;  dist: 13;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 13;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 13;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 13;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 13;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 13;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 13;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 13;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 13;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 13;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 13;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 13;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 13;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 13;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 13;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 13;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 13;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 13;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 13;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 13;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 13;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 13;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 13;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 13;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 13;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 13;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 13;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 13;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 13;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 13;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 13;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 13;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 13;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 13;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 13;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 13;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 13;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 13;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 13;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 13;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 13;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 13;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 13;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 13;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 13;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 13;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 13;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 13;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 13;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 13;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 13;  thinkfunc: Nil),
    (aifunc: ai_run;  dist: 13;  thinkfunc: Nil)
);
  floater_move_run : mmove_t = (firstframe: FRAME_stand101;  lastframe: FRAME_stand152;  frame: @floater_frames_run;  endfunc: Nil);

procedure floater_run (self : edict_p); cdecl;
begin
  if (self^.monsterinfo.aiflags AND AI_STAND_GROUND) <> 0 then
    self^.monsterinfo.currentmove := @floater_move_stand1
  else
    self^.monsterinfo.currentmove := @floater_move_run;
end;

procedure floater_walk (self : edict_p); cdecl;
begin
  self^.monsterinfo.currentmove := @floater_move_walk;
end;

procedure floater_wham (self : edict_p); cdecl;
//   static   vec3_t   aim = {MELEE_DISTANCE, 0, 0};
{$IFDEF COMPILER6_UP}{$WRITEABLECONST ON}{$ENDIF}
const
  aim : vec3_t = (MELEE_DISTANCE, 0, 0);
{$IFDEF COMPILER6_UP}{$WRITEABLECONST OFF}{$ENDIF}
begin
  gi.sound (self, CHAN_WEAPON, sound_attack3, 1, ATTN_NORM, 0);
  fire_hit (Self, aim, 5 + rand() mod 6, -50);
end;

procedure floater_zap (self : edict_p); cdecl;
var
  forward_, right,
  origin,
  dir,
  offset  : vec3_t;
begin
  VectorSubtract (self^.enemy^.s.origin, self^.s.origin, dir);

  AngleVectors (self^.s.angles, @forward_, @right, Nil);
  //FIXME use a flash and replace these two lines with the commented one
  VectorSet (offset, 18.5, -0.9, 10);
  G_ProjectSource (self^.s.origin, offset, forward_, right, origin);
//idsoft   G_ProjectSource (self->s.origin, monster_flash_offset[flash_number], forward, right, origin);

  gi.sound (self, CHAN_WEAPON, sound_attack2, 1, ATTN_NORM, 0);

  //FIXME use the flash, Luke
  gi.WriteByte (svc_temp_entity);
  gi.WriteByte (Ord(TE_SPLASH));
  gi.WriteByte (32);
  gi.WritePosition (origin);
  gi.WriteDir (dir);
  gi.WriteByte (1);   //sparks
  gi.multicast (@origin, MULTICAST_PVS);

  T_Damage (self^.enemy, self, self, dir, self^.enemy^.s.origin, vec3_origin, 5 + rand() mod 6, -10, DAMAGE_ENERGY, MOD_UNKNOWN);
end;

procedure floater_attack (self : edict_p); cdecl;
begin
  self^.monsterinfo.currentmove := @floater_move_attack1;
end;


procedure floater_melee (self : edict_p); cdecl;
begin
  if (_random() < 0.5) then
    self^.monsterinfo.currentmove := @floater_move_attack3
  else
    self^.monsterinfo.currentmove := @floater_move_attack2;
end;


procedure floater_pain (self, other : edict_p; kick : single; damage : integer); cdecl;
var
  n : integer;
begin
  if (self^.health < (self^.max_health / 2)) then
    self^.s.skinnum := 1;

  if (level.time < self^.pain_debounce_time) then
    Exit;

  self^.pain_debounce_time := level.time + 3;
  if (skill^.value = 3) then
    Exit;  // no pain anims in nightmare

  n := (rand() + 1) mod 3;
  if (n = 0) then
  begin
    gi.sound (self, CHAN_VOICE, sound_pain1, 1, ATTN_NORM, 0);
    self^.monsterinfo.currentmove := @floater_move_pain1;
  end
  else
  begin
    gi.sound (self, CHAN_VOICE, sound_pain2, 1, ATTN_NORM, 0);
    self^.monsterinfo.currentmove := @floater_move_pain2;
  end;
end;

procedure floater_dead (self : edict_p); cdecl;
begin
  VectorSet (self^.mins, -16, -16, -24);
  VectorSet (self^.maxs, 16, 16, -8);
  self^.movetype := MOVETYPE_TOSS;
  self^.svflags  := self^.svflags OR SVF_DEADMONSTER;
  self^.nextthink := 0;
  gi.linkentity (self);
end;

procedure floater_die (self, inflictor, attacker : edict_p; damage : integer; const point : vec3_t); cdecl;
begin
  gi.sound (self, CHAN_VOICE, sound_death1, 1, ATTN_NORM, 0);
  BecomeExplosion1(self);
end;

//*QUAKED monster_floater (1 .5 0) (-16 -16 -24) (16 16 32) Ambush Trigger_Spawn Sight
procedure SP_monster_floater (self : edict_p);
begin
  if (deathmatch^.value <> 0) then
  begin
    G_FreeEdict (self);
    Exit;
  end;

  sound_attack2 := gi.soundindex ('floater/fltatck2.wav');
  sound_attack3 := gi.soundindex ('floater/fltatck3.wav');
  sound_death1 := gi.soundindex ('floater/fltdeth1.wav');
  sound_idle := gi.soundindex ('floater/fltidle1.wav');
  sound_pain1 := gi.soundindex ('floater/fltpain1.wav');
  sound_pain2 := gi.soundindex ('floater/fltpain2.wav');
  sound_sight := gi.soundindex ('floater/fltsght1.wav');

  gi.soundindex ('floater/fltatck1.wav');

  self^.s.sound := gi.soundindex ('floater/fltsrch1.wav');

  self^.movetype := MOVETYPE_STEP;
  self^.solid := SOLID_BBOX;
  self^.s.modelindex := gi.modelindex ('models/monsters/single/tris.md2');
  VectorSet (self^.mins, -24, -24, -24);
  VectorSet (self^.maxs, 24, 24, 32);

  self^.health := 200;
  self^.gib_health := -80;
  self^.mass := 300;

  self^.pain := floater_pain;
  self^.die := floater_die;

  self^.monsterinfo.stand := floater_stand;
  self^.monsterinfo.walk := floater_walk;
  self^.monsterinfo.run := floater_run;
//idsoft   self->monsterinfo.dodge = floater_dodge;
  self^.monsterinfo.attack := floater_attack;
  self^.monsterinfo.melee := floater_melee;
  self^.monsterinfo.sight := floater_sight;
  self^.monsterinfo.idle := floater_idle;

  gi.linkentity (self);

  if (_random() <= 0.5) then
    self^.monsterinfo.currentmove := @floater_move_stand1
  else
    self^.monsterinfo.currentmove := @floater_move_stand2;

  self^.monsterinfo.scale := MODEL_SCALE;

  flymonster_start (self);
end;

end.
