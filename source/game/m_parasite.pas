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
{ File(s): m_parasite.c                                                      }
{ Content: actions and effects for parasite villain                          }
{                                                                            }
{ Initial conversion by : Massimo Soricetti (max-67@libero.it)               }
{ Initial conversion on : 09-Jan-2002                                        }
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
{ g_local.pas                                                                }
{----------------------------------------------------------------------------}

{
=======================================

parasite

=======================================
}

unit m_parasite;

interface

uses g_local;

const
  FRAME_break01  =  0;
  FRAME_break02  =  1;
  FRAME_break03  = 2;
  FRAME_break04  = 3;
  FRAME_break05  = 4;
  FRAME_break06  = 5;
  FRAME_break07  = 6;
  FRAME_break08  = 7;
  FRAME_break09  = 8;
  FRAME_break10  = 9;
  FRAME_break11  = 10;
  FRAME_break12  = 11;
  FRAME_break13  = 12;
  FRAME_break14  = 13;
  FRAME_break15  = 14;
  FRAME_break16  = 15;
  FRAME_break17  = 16;
  FRAME_break18  = 17;
  FRAME_break19  = 18;
  FRAME_break20  = 19;
  FRAME_break21  = 20;
  FRAME_break22  = 21;
  FRAME_break23  = 22;
  FRAME_break24  = 23;
  FRAME_break25  = 24;
  FRAME_break26  = 25;
  FRAME_break27  = 26;
  FRAME_break28  = 27;
  FRAME_break29  = 28;
  FRAME_break30  = 29;
  FRAME_break31  = 30;
  FRAME_break32  = 31;
  FRAME_death101 = 32;
  FRAME_death102 = 33;
  FRAME_death103 = 34;
  FRAME_death104 = 35;
  FRAME_death105 = 36;
  FRAME_death106 = 37;
  FRAME_death107 = 38;
  FRAME_drain01  = 39;
  FRAME_drain02  = 40;
  FRAME_drain03  = 41;
  FRAME_drain04  = 42;
  FRAME_drain05  = 43;
  FRAME_drain06  = 44;
  FRAME_drain07  = 45;
  FRAME_drain08  = 46;
  FRAME_drain09  = 47;
  FRAME_drain10  = 48;
  FRAME_drain11  = 49;
  FRAME_drain12  = 50;
  FRAME_drain13  = 51;
  FRAME_drain14  = 52;
  FRAME_drain15  = 53;
  FRAME_drain16  = 54;
  FRAME_drain17  = 55;
  FRAME_drain18  = 56;
  FRAME_pain101  = 57;
  FRAME_pain102  = 58;
  FRAME_pain103  = 59;
  FRAME_pain104  = 60;
  FRAME_pain105  = 61;
  FRAME_pain106  = 62;
  FRAME_pain107  = 63;
  FRAME_pain108  = 64;
  FRAME_pain109  = 65;
  FRAME_pain110  = 66;
  FRAME_pain111  = 67;
  FRAME_run01    = 68;
  FRAME_run02    = 69;
  FRAME_run03    = 70;
  FRAME_run04    = 71;
  FRAME_run05    = 72;
  FRAME_run06    = 73;
  FRAME_run07    = 74;
  FRAME_run08    = 75;
  FRAME_run09    = 76;
  FRAME_run10    = 77;
  FRAME_run11    = 78;
  FRAME_run12    = 79;
  FRAME_run13    = 80;
  FRAME_run14    = 81;
  FRAME_run15    = 82;
  FRAME_stand01  = 83;
  FRAME_stand02  = 84;
  FRAME_stand03  = 85;
  FRAME_stand04  = 86;
  FRAME_stand05  = 87;
  FRAME_stand06  = 88;
  FRAME_stand07  = 89;
  FRAME_stand08  = 90;
  FRAME_stand09  = 91;
  FRAME_stand10  = 92;
  FRAME_stand11  = 93;
  FRAME_stand12  = 94;
  FRAME_stand13  = 95;
  FRAME_stand14  = 96;
  FRAME_stand15  = 97;
  FRAME_stand16  = 98;
  FRAME_stand17  = 99;
  FRAME_stand18  = 100;
  FRAME_stand19  = 101;
  FRAME_stand20  = 102;
  FRAME_stand21  = 103;
  FRAME_stand22  = 104;
  FRAME_stand23  = 105;
  FRAME_stand24  = 106;
  FRAME_stand25  = 107;
  FRAME_stand26  = 108;
  FRAME_stand27  = 109;
  FRAME_stand28  = 110;
  FRAME_stand29  = 111;
  FRAME_stand30  = 112;
  FRAME_stand31  = 113;
  FRAME_stand32  = 114;
  FRAME_stand33  = 115;
  FRAME_stand34  = 116;
  FRAME_stand35  = 117;

  MODEL_SCALE    = 1.000000;

procedure SP_monster_parasite (self: edict_p); cdecl;


implementation

uses g_ai, g_main, q_shared, g_utils, q_shared_add, g_combat, g_local_add,
  GameUnit, g_misc, game_add, g_monster;

procedure parasite_stand (self: edict_p); cdecl; forward;
procedure parasite_start_run (self: edict_p); cdecl; forward;
procedure parasite_run (self: edict_p); cdecl; forward;
procedure parasite_walk (self: edict_p); cdecl; forward;
procedure parasite_start_walk (self: edict_p); cdecl; forward;
procedure parasite_end_fidget (self: edict_p); cdecl; forward;
procedure parasite_do_fidget (self: edict_p); cdecl; forward;
procedure parasite_refidget (self: edict_p); cdecl; forward;
procedure parasite_scratch (self: edict_p);  cdecl; forward;
procedure parasite_tap (self: edict_p); cdecl; forward;
procedure parasite_launch (self: edict_p); cdecl; forward;
procedure parasite_drain_attack (self: edict_p); cdecl; forward;
procedure parasite_reel_in (self: edict_p); cdecl; forward;
procedure parasite_dead (self: edict_p); cdecl; forward;

const
  parasite_frames_start_fidget : array[0..3] of mframe_t =
        (
   (aifunc:ai_stand; dist : 0; thinkfunc:nil),
   (aifunc:ai_stand; dist : 0; thinkfunc:nil),
   (aifunc:ai_stand; dist : 0; thinkfunc:nil),
   (aifunc:ai_stand; dist : 0; thinkfunc:nil)
        );

  parasite_move_start_fidget : mmove_t =
        (
        firstframe:FRAME_stand18;
        lastframe:FRAME_stand21;
        frame:@parasite_frames_start_fidget;
        endfunc:parasite_do_fidget
        );

  parasite_frames_fidget : array[0..5] of mframe_t =
        (
   (aifunc:ai_stand; dist : 0; thinkfunc:parasite_scratch),
   (aifunc:ai_stand; dist : 0; thinkfunc:nil),
   (aifunc:ai_stand; dist : 0; thinkfunc:nil),
   (aifunc:ai_stand; dist : 0; thinkfunc:parasite_scratch),
   (aifunc:ai_stand; dist : 0; thinkfunc:nil),
   (aifunc:ai_stand; dist : 0; thinkfunc:nil)
        );

  parasite_move_fidget : mmove_t =
        (
        firstframe:FRAME_stand22;
        lastframe:FRAME_stand27;
        frame:@parasite_frames_fidget;
        endfunc:parasite_refidget
        );

  parasite_frames_end_fidget: array[0..7] of mframe_t=
        (
   (aifunc:ai_stand; dist : 0; thinkfunc:parasite_scratch),
   (aifunc:ai_stand; dist : 0; thinkfunc:nil),
   (aifunc:ai_stand; dist : 0; thinkfunc:nil),
   (aifunc:ai_stand; dist : 0; thinkfunc:nil),
   (aifunc:ai_stand; dist : 0; thinkfunc:nil),
   (aifunc:ai_stand; dist : 0; thinkfunc:nil),
   (aifunc:ai_stand; dist : 0; thinkfunc:nil),
   (aifunc:ai_stand; dist : 0; thinkfunc:nil)
        );

  parasite_move_end_fidget : mmove_t =
        (
        firstframe:FRAME_stand28;
        lastframe:FRAME_stand35;
        frame:@parasite_frames_end_fidget;
        endfunc:parasite_stand
        );

  parasite_frames_stand : array[0..16] of mframe_t =
        (
   (aifunc:ai_stand; dist : 0; thinkfunc:nil),
   (aifunc:ai_stand; dist : 0; thinkfunc:nil),
   (aifunc:ai_stand; dist : 0; thinkfunc:parasite_tap),
   (aifunc:ai_stand; dist : 0; thinkfunc:nil),
   (aifunc:ai_stand; dist : 0; thinkfunc:parasite_tap),
   (aifunc:ai_stand; dist : 0; thinkfunc:nil),
   (aifunc:ai_stand; dist : 0; thinkfunc:nil),
   (aifunc:ai_stand; dist : 0; thinkfunc:nil),
   (aifunc:ai_stand; dist : 0; thinkfunc:parasite_tap),
   (aifunc:ai_stand; dist : 0; thinkfunc:nil),
   (aifunc:ai_stand; dist : 0; thinkfunc:parasite_tap),
   (aifunc:ai_stand; dist : 0; thinkfunc:nil),
   (aifunc:ai_stand; dist : 0; thinkfunc:nil),
   (aifunc:ai_stand; dist : 0; thinkfunc:nil),
   (aifunc:ai_stand; dist : 0; thinkfunc:parasite_tap),
   (aifunc:ai_stand; dist : 0; thinkfunc:nil),
   (aifunc:ai_stand; dist : 0; thinkfunc:parasite_tap)
        );

  parasite_move_stand : mmove_t =
        (
        firstframe:FRAME_stand01;
        lastframe:FRAME_stand17;
        frame:@parasite_frames_stand;
        endfunc:parasite_stand
        );

  parasite_frames_run : array[0..6] of mframe_t =
        (
   (aifunc: ai_run; dist : 30; thinkfunc:nil),
   (aifunc: ai_run; dist : 30; thinkfunc:nil),
   (aifunc: ai_run; dist : 22; thinkfunc:nil),
   (aifunc: ai_run; dist : 19; thinkfunc:nil),
   (aifunc: ai_run; dist : 24; thinkfunc:nil),
   (aifunc: ai_run; dist : 28; thinkfunc:nil),
   (aifunc: ai_run; dist : 25; thinkfunc:nil)
        );

  parasite_move_run: mmove_t =
        (
        firstframe:FRAME_run03;
        lastframe:FRAME_run09;
        frame:@parasite_frames_run;
        endfunc:nil
        );

  parasite_frames_start_run : array[0..1] of mframe_t =
        (
   (aifunc: ai_run; dist : 0; thinkfunc:nil),
   (aifunc: ai_run; dist : 30; thinkfunc:nil)
        );

  parasite_move_start_run : mmove_t =
        (
        firstframe:FRAME_run01;
        lastframe:FRAME_run02;
        frame:@parasite_frames_start_run;
        endfunc:parasite_run
        );

  parasite_frames_stop_run : array [0..5] of mframe_t =
        (
   (aifunc: ai_run; dist : 20; thinkfunc:nil),
  (aifunc: ai_run; dist : 20; thinkfunc:nil),
   (aifunc: ai_run; dist : 12; thinkfunc:nil),
   (aifunc: ai_run; dist : 10; thinkfunc:nil),
   (aifunc: ai_run; dist : 0; thinkfunc:nil),
   (aifunc: ai_run; dist : 0; thinkfunc:nil)
        );

  parasite_move_stop_run : mmove_t =
        (
        firstframe:FRAME_run10;
        lastframe:FRAME_run15;
        frame:@parasite_frames_stop_run;
        endfunc:nil
        );

  parasite_frames_walk : array [0..6] of mframe_t =
        (
   (aifunc: ai_walk; dist : 30; thinkfunc:nil),
   (aifunc: ai_walk; dist : 30; thinkfunc:nil),
   (aifunc: ai_walk; dist : 22; thinkfunc:nil),
   (aifunc: ai_walk; dist : 19; thinkfunc:nil),
   (aifunc: ai_walk; dist : 24; thinkfunc:nil),
   (aifunc: ai_walk; dist : 28; thinkfunc:nil),
   (aifunc: ai_walk; dist : 25; thinkfunc:nil)
        );

  parasite_move_walk : mmove_t =
        (
        firstframe:FRAME_run03;
        lastframe:FRAME_run09;
        frame:@parasite_frames_walk;
        endfunc:parasite_walk
        );

  parasite_frames_start_walk : array [0..1] of mframe_t =
        (
   (aifunc: ai_walk; dist : 0; thinkfunc:nil),
   (aifunc: ai_walk; dist : 30; thinkfunc:parasite_walk)
        );

  parasite_move_start_walk : mmove_t=
        (
        firstframe:FRAME_run01;
        lastframe:FRAME_run02;
        frame:@parasite_frames_start_walk;
        endfunc:nil
        );

  parasite_frames_stop_walk : array [0..5] of mframe_t =
        (
   (aifunc: ai_walk; dist : 20; thinkfunc:nil),
   (aifunc: ai_walk; dist : 20; thinkfunc:nil),
   (aifunc: ai_walk; dist : 12; thinkfunc:nil),
   (aifunc: ai_walk; dist : 10; thinkfunc:nil),
   (aifunc: ai_walk; dist : 0; thinkfunc:nil),
   (aifunc: ai_walk; dist : 0; thinkfunc:nil)
        );

  parasite_move_stop_walk : mmove_t =
        (
        firstframe:FRAME_run10;
        lastframe:FRAME_run15;
        frame:@parasite_frames_stop_walk;
        endfunc:nil
        );

  parasite_frames_pain1 : array[0..10] of mframe_t =
        (
   (aifunc: ai_move; dist : 0; thinkfunc:nil),
   (aifunc: ai_move; dist : 0; thinkfunc:nil),
   (aifunc: ai_move; dist : 0; thinkfunc:nil),
   (aifunc: ai_move; dist : 0; thinkfunc:nil),
   (aifunc: ai_move; dist : 0; thinkfunc:nil),
   (aifunc: ai_move; dist : 0; thinkfunc:nil),
   (aifunc: ai_move; dist : 6; thinkfunc:nil),
   (aifunc: ai_move; dist : 16; thinkfunc:nil),
   (aifunc: ai_move; dist :-6; thinkfunc:nil),
   (aifunc: ai_move; dist :-7; thinkfunc:nil),
   (aifunc: ai_move; dist : 0; thinkfunc:nil)
        );

  parasite_move_pain1 : mmove_t =
        (
        firstframe:FRAME_pain101;
        lastframe:FRAME_pain111;
        frame:@parasite_frames_pain1;
        endfunc:parasite_start_run
        );

  parasite_frames_drain : array[0..17] of mframe_t =
        (
   (aifunc: ai_charge; dist : 0; thinkfunc:parasite_launch),
   (aifunc: ai_charge; dist : 0; thinkfunc:nil),
   (aifunc: ai_charge; dist : 15; thinkfunc:parasite_drain_attack),   // Target hits
   (aifunc: ai_charge; dist : 0; thinkfunc:parasite_drain_attack),   // drain
   (aifunc: ai_charge; dist : 0; thinkfunc:parasite_drain_attack),   // drain
   (aifunc: ai_charge; dist : 0; thinkfunc:parasite_drain_attack),   // drain
   (aifunc: ai_charge; dist : 0; thinkfunc:parasite_drain_attack),   // drain
   (aifunc: ai_charge; dist :-2; thinkfunc:parasite_drain_attack),   // drain
   (aifunc: ai_charge; dist :-2; thinkfunc:parasite_drain_attack),   // drain
   (aifunc: ai_charge; dist :-3; thinkfunc:parasite_drain_attack),   // drain
   (aifunc: ai_charge; dist :-2; thinkfunc:parasite_drain_attack),   // drain
   (aifunc: ai_charge; dist : 0; thinkfunc:parasite_drain_attack),   // drain
   (aifunc: ai_charge; dist :-1; thinkfunc:parasite_drain_attack),   // drain
   (aifunc: ai_charge; dist : 0; thinkfunc:parasite_reel_in),   // let go
   (aifunc: ai_charge; dist :-2; thinkfunc:nil),
   (aifunc: ai_charge; dist :-2; thinkfunc:nil),
   (aifunc: ai_charge; dist :-3; thinkfunc:nil),
   (aifunc: ai_charge; dist : 0; thinkfunc:nil)
        );

  parasite_move_drain : mmove_t =
        (
        firstframe:FRAME_drain01;
        lastframe:FRAME_drain18;
        frame:@parasite_frames_drain;
        endfunc:parasite_start_run
        );

  parasite_frames_break : array[0..31] of mframe_t =
  (
  (aifunc: ai_charge; dist : 0; thinkfunc:nil),
   (aifunc: ai_charge; dist :-3; thinkfunc:nil),
   (aifunc: ai_charge; dist : 1; thinkfunc:nil),
   (aifunc: ai_charge; dist : 2; thinkfunc:nil),
   (aifunc: ai_charge; dist :-3; thinkfunc:nil),
   (aifunc: ai_charge; dist : 1; thinkfunc:nil),
   (aifunc: ai_charge; dist : 1; thinkfunc:nil),
   (aifunc: ai_charge; dist : 3; thinkfunc:nil),
   (aifunc: ai_charge; dist : 0; thinkfunc:nil),
   (aifunc: ai_charge; dist :-18; thinkfunc:nil),
   (aifunc: ai_charge; dist : 3; thinkfunc:nil),
   (aifunc: ai_charge; dist : 9; thinkfunc:nil),
   (aifunc: ai_charge; dist : 6; thinkfunc:nil),
   (aifunc: ai_charge; dist : 0; thinkfunc:nil),
   (aifunc: ai_charge; dist :-18; thinkfunc:nil),
   (aifunc: ai_charge; dist : 0; thinkfunc:nil),
   (aifunc: ai_charge; dist : 8; thinkfunc:nil),
   (aifunc: ai_charge; dist : 9; thinkfunc:nil),
   (aifunc: ai_charge; dist : 0; thinkfunc:nil),
   (aifunc: ai_charge; dist :-18; thinkfunc:nil),
   (aifunc: ai_charge; dist : 0; thinkfunc:nil),
   (aifunc: ai_charge; dist : 0; thinkfunc:nil),   // airborne
   (aifunc: ai_charge; dist : 0; thinkfunc:nil),   // airborne
   (aifunc: ai_charge; dist : 0; thinkfunc:nil),   // slides
   (aifunc: ai_charge; dist : 0; thinkfunc:nil),   // slides
   (aifunc: ai_charge; dist : 0; thinkfunc:nil), // slides
   (aifunc: ai_charge; dist : 0; thinkfunc:nil),   // slides
   (aifunc: ai_charge; dist : 4; thinkfunc:nil),
   (aifunc: ai_charge; dist : 11; thinkfunc:nil),
   (aifunc: ai_charge; dist :-2; thinkfunc:nil),
   (aifunc: ai_charge; dist :-5; thinkfunc:nil),
   (aifunc: ai_charge; dist : 1; thinkfunc:nil)
        );

  parasite_move_break : mmove_t =
        (
        firstframe:FRAME_break01;
        lastframe:FRAME_break32;
        frame:@parasite_frames_break;
        endfunc:parasite_start_run
        );

  parasite_frames_death : array [0..6] of mframe_t =
        (
   (aifunc: ai_move; dist : 0; thinkfunc:nil),
   (aifunc: ai_move; dist : 0; thinkfunc:nil),
   (aifunc: ai_move; dist : 0; thinkfunc:nil),
   (aifunc: ai_move; dist : 0; thinkfunc:nil),
   (aifunc: ai_move; dist : 0; thinkfunc:nil),
   (aifunc: ai_move; dist : 0; thinkfunc:nil),
   (aifunc: ai_move; dist : 0; thinkfunc:nil)
        );

  parasite_move_death : mmove_t =
        (
        firstframe:FRAME_death101;
        lastframe:FRAME_death107;
        frame:@parasite_frames_death;
        endfunc:parasite_dead
        );



var

  sound_pain1,
  sound_pain2,
  sound_die,
  sound_launch,
  sound_impact,
  sound_suck,
  sound_reelin,
  sound_sight,
  sound_tap,
  sound_scratch,
  sound_search: integer;


procedure parasite_launch (self: edict_p);
begin
  gi.sound(self, CHAN_WEAPON, sound_launch, 1, ATTN_NORM, 0);
end;

Procedure parasite_reel_in (self: edict_p);
begin
  gi.sound (self, CHAN_WEAPON, sound_reelin, 1, ATTN_NORM, 0);
end;

Procedure parasite_sight (self, other: edict_p); cdecl;
begin
  gi.sound (self, CHAN_WEAPON, sound_sight, 1, ATTN_NORM, 0);
end;

Procedure parasite_tap (self: edict_p);
begin
  gi.sound (self, CHAN_WEAPON, sound_tap, 1, ATTN_IDLE, 0);
end;

Procedure parasite_scratch (self: edict_p);
begin
  gi.sound (self, CHAN_WEAPON, sound_scratch, 1, ATTN_IDLE, 0);
end;

Procedure parasite_search (self: edict_p);
begin
  gi.sound (self, CHAN_WEAPON, sound_search, 1, ATTN_IDLE, 0);
end;



Procedure parasite_end_fidget (self: edict_p);
begin
  self^.monsterinfo.currentmove := @parasite_move_end_fidget;
end;

Procedure parasite_do_fidget (self: edict_p);
begin
  self^.monsterinfo.currentmove := @parasite_move_fidget;
end;

Procedure parasite_refidget (self: edict_p);
begin
  if (_random() <= 0.8) then
    self^.monsterinfo.currentmove := @parasite_move_fidget
  else
    self^.monsterinfo.currentmove := @parasite_move_end_fidget;
end;

Procedure parasite_idle (self: edict_p); cdecl;
begin
  self^.monsterinfo.currentmove := @parasite_move_start_fidget;
end;



Procedure parasite_stand (self: edict_p);
begin
  self^.monsterinfo.currentmove := @parasite_move_stand;
end;



Procedure parasite_start_run (self: edict_p);
begin
  if (self^.monsterinfo.aiflags and AI_STAND_GROUND) <> 0 then
     self^.monsterinfo.currentmove := @parasite_move_stand
  else
     self^.monsterinfo.currentmove := @parasite_move_start_run;
end;

Procedure parasite_run (self: edict_p);
begin
  if (self^.monsterinfo.aiflags and AI_STAND_GROUND) <> 0 then
    self^.monsterinfo.currentmove := @parasite_move_stand
  else
    self^.monsterinfo.currentmove := @parasite_move_run;
end;



Procedure parasite_start_walk (self: edict_p);
begin
  self^.monsterinfo.currentmove := @parasite_move_start_walk;
end;

Procedure parasite_walk (self: edict_p);
begin
  self^.monsterinfo.currentmove := @parasite_move_walk;
end;



Procedure parasite_pain (self, other: edict_p; kick: Single; damage: integer); cdecl;
begin
  if self^.health < (self^.max_health / 2) then
    self^.s.skinnum := 1;
  if level.time >= self^.pain_debounce_time then
  begin
    self^.pain_debounce_time := level.time + 3;
    if skill^.value <> 3 then
    begin
      if (_random() < 0.5) then
        gi.sound (self, CHAN_VOICE, sound_pain1, 1, ATTN_NORM, 0)
      else
        gi.sound (self, CHAN_VOICE, sound_pain2, 1, ATTN_NORM, 0);
      self^.monsterinfo.currentmove := @parasite_move_pain1;
    end;
  end;
end;


Function parasite_drain_attack_ok (const start, _end: vec3_t): boolean;
var
  dir, angles: vec3_t;

begin
        // check for max distance
  VectorSubtract(start, _end, dir);
  if VectorLength(dir) > 256 then
    result:= false
  else
  begin
        // check for min/max pitch
    vectoangles (dir, angles);
    if angles[0] < -180 then
      angles[0] := angles[0] + 360;
    if abs(angles[0]) > 30 then
      result:= false
    else
      result:= true;
  end;
end;


Procedure parasite_drain_attack (self: edict_p);
var
  offset, start, f, r, _end, dir: vec3_t;
  tr: trace_t;
  damage: integer;

begin

  AngleVectors (self^.s.angles, @f, @r, nil);
  VectorSet (offset, 24, 0, 6);
  G_ProjectSource (self^.s.origin, offset, f, r, start);
  VectorCopy (self^.enemy^.s.origin, _end);
  if not parasite_drain_attack_ok(start, _end) then
  begin
    _end[2] := self^.enemy^.s.origin[2] + self^.enemy^.maxs[2] - 8;
    if (not parasite_drain_attack_ok(start, _end)) then
    begin
      _end[2] := self^.enemy^.s.origin[2] + self^.enemy^.mins[2] + 8;
      if not parasite_drain_attack_ok(start, _end) then
         exit;
    end;
  end;
  VectorCopy (self^.enemy^.s.origin, _end);
  tr := gi.trace (@start, nil, nil, @_end, self, MASK_SHOT);
  if tr.ent <> self^.enemy then
    exit;
  if self^.s.frame = FRAME_drain03 then
  begin
    damage := 5;
    gi.sound (self^.enemy, CHAN_AUTO, sound_impact, 1, ATTN_NORM, 0);
  end
  else
  begin
    if self^.s.frame = FRAME_drain04 then
      gi.sound (self, CHAN_WEAPON, sound_suck, 1, ATTN_NORM, 0);
    damage := 2;
  end;

  gi.WriteByte (svc_temp_entity);
  gi.WriteByte (Ord(TE_PARASITE_ATTACK));
  gi.WriteShort ((Cardinal(Self)-Cardinal(g_edicts)) div SizeOf(edict_t));
  gi.WritePosition (start);
  gi.WritePosition (_end);
  gi.multicast (@self^.s.origin, MULTICAST_PVS);

  VectorSubtract (start, _end, dir);
  T_Damage (self^.enemy, self, self, dir, self^.enemy^.s.origin, vec3_origin, damage, 0, DAMAGE_NO_KNOCKBACK, MOD_UNKNOWN);
end;


{
=:=
Break Stuff Ends
=:=
}

Procedure parasite_attack (self: edict_p); cdecl;
begin
//   if (_random() <= 0.2)
//      self^.monsterinfo.currentmove := @parasite_move_break;
//   else
  self^.monsterinfo.currentmove := @parasite_move_drain;
end;



{
=:=
Death Stuff Starts
=:=
}

Procedure parasite_dead (self: edict_p);
begin
  VectorSet (self^.mins, -16, -16, -24);
  VectorSet (self^.maxs, 16, 16, -8);
  self^.movetype := MOVETYPE_TOSS;
  self^.svflags := self^.svflags or SVF_DEADMONSTER;
  self^.nextthink := 0;
  gi.linkentity (self);
end;


Procedure parasite_die (self, inflictor, attacker: edict_p; damage: Integer; const point: vec3_t); cdecl;
var
  i: integer;
begin

// check for gib
  if self^.health <= self^.gib_health then
  begin
    gi.sound (self, CHAN_VOICE, gi.soundindex ('misc/udeath.wav'), 1, ATTN_NORM, 0);
    for  i := 0 to 1 do
      ThrowGib (self, 'models/objects/gibs/bone/tris.md2', damage, GIB_ORGANIC);
    for i := 0 to 3 do
      ThrowGib (self, 'models/objects/gibs/sm_meat/tris.md2', damage, GIB_ORGANIC);
    ThrowHead (self, 'models/objects/gibs/head2/tris.md2', damage, GIB_ORGANIC);
    self^.deadflag := DEAD_DEAD;
  end
  else
  if self^.deadflag <> DEAD_DEAD then
  begin
// regular death
    gi.sound (self, CHAN_VOICE, sound_die, 1, ATTN_NORM, 0);
    self^.deadflag := DEAD_DEAD;
    self^.takedamage := DAMAGE_YES;
    self^.monsterinfo.currentmove := @parasite_move_death;
  end;
end;

{
=:=
End Death Stuff
=:=
}

{QUAKED monster_parasite (1 .5 0) (-16 -16 -24) (16 16 32) Ambush Trigger_Spawn Sight
}
Procedure SP_monster_parasite (self: edict_p);
begin
  if deathmatch^.value <> 0 then
    G_FreeEdict (self)
  else
  begin
    sound_pain1 := gi.soundindex ('parasite/parpain1.wav');
    sound_pain2 := gi.soundindex ('parasite/parpain2.wav');
    sound_die := gi.soundindex ('parasite/pardeth1.wav');
    sound_launch := gi.soundindex('parasite/paratck1.wav');
    sound_impact := gi.soundindex('parasite/paratck2.wav');
    sound_suck := gi.soundindex('parasite/paratck3.wav');
    sound_reelin := gi.soundindex('parasite/paratck4.wav');
    sound_sight := gi.soundindex('parasite/parsght1.wav');
    sound_tap := gi.soundindex('parasite/paridle1.wav');
    sound_scratch := gi.soundindex('parasite/paridle2.wav');
    sound_search := gi.soundindex('parasite/parsrch1.wav');

    self^.s.modelindex := gi.modelindex ('models/monsters/parasite/tris.md2');
    VectorSet (self^.mins, -16, -16, -24);
    VectorSet (self^.maxs, 16, 16, 24);
    self^.movetype := MOVETYPE_STEP;
    self^.solid := SOLID_BBOX;

    self^.health := 175;
    self^.gib_health := -50;
    self^.mass := 250;

    self^.pain := parasite_pain;
    self^.die := parasite_die;

    self^.monsterinfo.stand := parasite_stand;
    self^.monsterinfo.walk := parasite_start_walk;
    self^.monsterinfo.run := parasite_start_run;
    self^.monsterinfo.attack := parasite_attack;
    self^.monsterinfo.sight := parasite_sight;
    self^.monsterinfo.idle := parasite_idle;

    gi.linkentity (self);

    self^.monsterinfo.currentmove := @parasite_move_stand;
    self^.monsterinfo.scale := MODEL_SCALE;

    walkmonster_start (self);
  end;
end;

end.
