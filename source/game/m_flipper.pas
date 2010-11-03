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


//100%
{----------------------------------------------------------------------------}
{                                                                            }
{ File(s): m_flipper.h                                                       }
{                                                                            }
{ Initial conversion by : Ben Watt (ben@delphigamedev.com)                   }
{ Initial conversion on : 29-Jan-2002                                        }
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
{ Updated on :  2003-May-23                                                  }
{ Updated by :  Scott Price (scott.price@totalise.co.uk)                     }
{               Pointer dereferences mostly                                  }
{                                                                            }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{ none                                                                       }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{ none                                                                       }
{----------------------------------------------------------------------------}
{
==============================================================================

FLIPPER

==============================================================================
}

unit m_flipper;

interface

uses
  g_local,
  q_shared;


{$I m_flipper.inc}

const MODEL_SCALE     = 1.000000;


procedure flipper_stand(self : edict_p); cdecl;
procedure flipper_run_loop(self : edict_p); cdecl;
procedure flipper_run(self : edict_p); cdecl;
procedure flipper_walk(self : edict_p); cdecl;
procedure flipper_start_run(self : edict_p); cdecl;
procedure flipper_bite(self : edict_p); cdecl;
procedure flipper_preattack(self : edict_p); cdecl;
procedure flipper_melee(self : edict_p); cdecl;
procedure flipper_pain(self, other : edict_p; kick : single; damage : integer); cdecl;
procedure flipper_dead(self : edict_p); cdecl;
procedure flipper_sight(self, other : edict_p); cdecl;
procedure flipper_die(self, inflictor, attacker : edict_p; damage : integer; const point : vec3_t); cdecl;

procedure SP_monster_flipper(self : edict_p); cdecl;



implementation



uses g_ai, g_weapon, g_main, g_local_add, q_shared_add, g_misc, GameUnit,
  g_utils, game_add, g_monster, CPas;


var
  sound_chomp,
  sound_attack,
  sound_pain1,
  sound_pain2,
  sound_death,
  sound_idle,
  sound_search,
  sound_sight   : Integer;


const
  flipper_frames_stand : array[0..0] of mframe_t =
    ((aifunc:ai_stand; dist:0; thinkfunc:nil));

  flipper_move_stand : mmove_t =
    (firstframe:FRAME_flphor01; lastframe:FRAME_flphor01; frame:@flipper_frames_stand; endfunc:nil);


procedure flipper_stand(self : edict_p);
begin
  self^.monsterinfo.currentmove := @flipper_move_stand;
end;

const
  FLIPPER_RUN_SPEED = 24;
  flipper_frames_run : array[0..23] of mframe_t =
    ((aifunc:ai_run; dist:FLIPPER_RUN_SPEED; thinkfunc:nil),   // 6
     (aifunc:ai_run; dist:FLIPPER_RUN_SPEED; thinkfunc:nil),
     (aifunc:ai_run; dist:FLIPPER_RUN_SPEED; thinkfunc:nil),
     (aifunc:ai_run; dist:FLIPPER_RUN_SPEED; thinkfunc:nil),
     (aifunc:ai_run; dist:FLIPPER_RUN_SPEED; thinkfunc:nil),   // 10

     (aifunc:ai_run; dist:FLIPPER_RUN_SPEED; thinkfunc:nil),
     (aifunc:ai_run; dist:FLIPPER_RUN_SPEED; thinkfunc:nil),
     (aifunc:ai_run; dist:FLIPPER_RUN_SPEED; thinkfunc:nil),
     (aifunc:ai_run; dist:FLIPPER_RUN_SPEED; thinkfunc:nil),
     (aifunc:ai_run; dist:FLIPPER_RUN_SPEED; thinkfunc:nil),
     (aifunc:ai_run; dist:FLIPPER_RUN_SPEED; thinkfunc:nil),
     (aifunc:ai_run; dist:FLIPPER_RUN_SPEED; thinkfunc:nil),
     (aifunc:ai_run; dist:FLIPPER_RUN_SPEED; thinkfunc:nil),
     (aifunc:ai_run; dist:FLIPPER_RUN_SPEED; thinkfunc:nil),
     (aifunc:ai_run; dist:FLIPPER_RUN_SPEED; thinkfunc:nil),   // 20

     (aifunc:ai_run; dist:FLIPPER_RUN_SPEED; thinkfunc:nil),
     (aifunc:ai_run; dist:FLIPPER_RUN_SPEED; thinkfunc:nil),
     (aifunc:ai_run; dist:FLIPPER_RUN_SPEED; thinkfunc:nil),
     (aifunc:ai_run; dist:FLIPPER_RUN_SPEED; thinkfunc:nil),
     (aifunc:ai_run; dist:FLIPPER_RUN_SPEED; thinkfunc:nil),
     (aifunc:ai_run; dist:FLIPPER_RUN_SPEED; thinkfunc:nil),
     (aifunc:ai_run; dist:FLIPPER_RUN_SPEED; thinkfunc:nil),
     (aifunc:ai_run; dist:FLIPPER_RUN_SPEED; thinkfunc:nil),
     (aifunc:ai_run; dist:FLIPPER_RUN_SPEED; thinkfunc:nil));  // 29

  flipper_move_run_loop : mmove_t =
    (firstframe:FRAME_flpver06; lastframe:FRAME_flpver29; frame:@flipper_frames_run; endfunc:nil);

procedure flipper_run_loop(self : edict_p);
begin
  self^.monsterinfo.currentmove := @flipper_move_run_loop;
end;

const
  flipper_frames_run_start : array[0..5] of mframe_t =
    ((aifunc:ai_run; dist:8;  thinkfunc:nil),
     (aifunc:ai_run; dist:8;  thinkfunc:nil),
     (aifunc:ai_run; dist:8;  thinkfunc:nil),
     (aifunc:ai_run; dist:8;  thinkfunc:nil),
     (aifunc:ai_run; dist:8;  thinkfunc:nil),
     (aifunc:ai_run; dist:8;  thinkfunc:nil));

  flipper_move_run_start : mmove_t =
    (firstframe:FRAME_flpver01; lastframe:FRAME_flpver06; frame:@flipper_frames_run_start; endfunc:flipper_run_loop);

procedure flipper_run(self : edict_p);
begin
  self^.monsterinfo.currentmove := @flipper_move_run_start;
end;

const
  { Standard Swimming }
  flipper_frames_walk : array[0..23] of mframe_t =
    ((aifunc:ai_walk; dist:4; thinkfunc:nil),
     (aifunc:ai_walk; dist:4; thinkfunc:nil),
     (aifunc:ai_walk; dist:4; thinkfunc:nil),
     (aifunc:ai_walk; dist:4; thinkfunc:nil),
     (aifunc:ai_walk; dist:4; thinkfunc:nil),
     (aifunc:ai_walk; dist:4; thinkfunc:nil),
     (aifunc:ai_walk; dist:4; thinkfunc:nil),
     (aifunc:ai_walk; dist:4; thinkfunc:nil),
     (aifunc:ai_walk; dist:4; thinkfunc:nil),
     (aifunc:ai_walk; dist:4; thinkfunc:nil),
     (aifunc:ai_walk; dist:4; thinkfunc:nil),
     (aifunc:ai_walk; dist:4; thinkfunc:nil),
     (aifunc:ai_walk; dist:4; thinkfunc:nil),
     (aifunc:ai_walk; dist:4; thinkfunc:nil),
     (aifunc:ai_walk; dist:4; thinkfunc:nil),
     (aifunc:ai_walk; dist:4; thinkfunc:nil),
     (aifunc:ai_walk; dist:4; thinkfunc:nil),
     (aifunc:ai_walk; dist:4; thinkfunc:nil),
     (aifunc:ai_walk; dist:4; thinkfunc:nil),
     (aifunc:ai_walk; dist:4; thinkfunc:nil),
     (aifunc:ai_walk; dist:4; thinkfunc:nil),
     (aifunc:ai_walk; dist:4; thinkfunc:nil),
     (aifunc:ai_walk; dist:4; thinkfunc:nil),
     (aifunc:ai_walk; dist:4; thinkfunc:nil));

  flipper_move_walk : mmove_t =
    (firstframe:FRAME_flphor01; lastframe:FRAME_flphor24; frame:@flipper_frames_walk; endfunc:nil);

procedure flipper_walk(self : edict_p);
begin
  self^.monsterinfo.currentmove := @flipper_move_walk;
end;

const
  flipper_frames_start_run : Array[0..4] of mframe_t =
    ((aifunc:ai_run; dist:8; thinkfunc:nil),
     (aifunc:ai_run; dist:8; thinkfunc:nil),
     (aifunc:ai_run; dist:8; thinkfunc:nil),
     (aifunc:ai_run; dist:8; thinkfunc:nil),
     (aifunc:ai_run; dist:8; thinkfunc:flipper_run));

  flipper_move_start_run : mmove_t =
    (firstframe:FRAME_flphor01; lastframe:FRAME_flphor05; frame:@flipper_frames_start_run; endfunc:nil);

procedure flipper_start_run(self : edict_p);
begin
  self^.monsterinfo.currentmove := @flipper_move_start_run;
end;

const
  flipper_frames_pain2 : array[0..4] of mframe_t =
    ((aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil));

  flipper_move_pain2 : mmove_t =
    (firstframe:FRAME_flppn101; lastframe:FRAME_flppn105; frame:@flipper_frames_pain2; endfunc:flipper_run);

  flipper_frames_pain1 : array[0..4] of mframe_t =
    ((aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil));

  flipper_move_pain1 : mmove_t =
    (firstframe:FRAME_flppn201; lastframe:FRAME_flppn205; frame:@flipper_frames_pain1; endfunc:flipper_run);

procedure flipper_bite(self : edict_p);
var
  aim : vec3_t;
begin
  VectorSet(aim, MELEE_DISTANCE, 0, 0);
  fire_hit(Self, aim, 5, 0);
end;

procedure flipper_preattack(self : edict_p);
begin
  gi.sound(self, CHAN_WEAPON, sound_chomp, 1, ATTN_NORM, 0);
end;

const
  flipper_frames_attack : array[0..19] of mframe_t =
    ((aifunc:ai_charge; dist:0; thinkfunc:flipper_preattack),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:flipper_bite),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:flipper_bite),
     (aifunc:ai_charge; dist:0; thinkfunc:nil));

  flipper_move_attack : mmove_t =
    (firstframe:FRAME_flpbit01; lastframe:FRAME_flpbit20; frame:@flipper_frames_attack; endfunc:flipper_run);

procedure flipper_melee(self : edict_p);
begin
  self^.monsterinfo.currentmove := @flipper_move_attack;
end;

procedure flipper_pain(self, other : edict_p; kick : single; damage : integer);
var
  n : Integer;
begin
  if self^.health < (self^.max_health / 2) then
    self^.s.skinnum := 1;

  if level.time < self^.pain_debounce_time then
    Exit;

  self^.pain_debounce_time := level.time + 3;
   
  if skill^.value = 3 then
    Exit;      // no pain anims in nightmare

  n := (rand() + 1) mod 2;
  if n = 0 then
  begin
    gi.sound(self, CHAN_VOICE, sound_pain1, 1, ATTN_NORM, 0);
    self^.monsterinfo.currentmove := @flipper_move_pain1;
  end
  else
  begin
    gi.sound(self, CHAN_VOICE, sound_pain2, 1, ATTN_NORM, 0);
    self^.monsterinfo.currentmove := @flipper_move_pain2;
  end;
end;

procedure flipper_dead(self : edict_p);
begin
  VectorSet(self^.mins, -16, -16, -24);
  VectorSet(self^.maxs,  16,  16,  -8);
  self^.movetype := MOVETYPE_TOSS;
  self^.svflags := (self^.svflags or SVF_DEADMONSTER);
  self^.nextthink := 0;
  gi.linkentity(self);
end;

const
  flipper_frames_death : array[0..55] of mframe_t =
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
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),

     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil));

  flipper_move_death : mmove_t =
    (firstframe:FRAME_flpdth01; lastframe:FRAME_flpdth56; frame:@flipper_frames_death; endfunc:flipper_dead);

procedure flipper_sight(self, other : edict_p);
begin
  gi.sound(self, CHAN_VOICE, sound_sight, 1, ATTN_NORM, 0);
end;

procedure flipper_die(self, inflictor, attacker : edict_p; damage : integer; const point : vec3_t);
var
  n : integer;
begin
  // check for gib
  if self^.health <= self^.gib_health then
  begin
    gi.sound(self, CHAN_VOICE, gi.soundindex('misc/udeath.wav'), 1, ATTN_NORM, 0);
    for n := 0 to 1 do
      ThrowGib(self, 'models/objects/gibs/bone/tris.md2', damage, GIB_ORGANIC);
    for n := 0 to 1 do
      ThrowGib(self, 'models/objects/gibs/sm_meat/tris.md2', damage, GIB_ORGANIC);
    ThrowHead(self, 'models/objects/gibs/sm_meat/tris.md2', damage, GIB_ORGANIC);
    self^.deadflag := DEAD_DEAD;
    Exit;
  end;

  if self^.deadflag = DEAD_DEAD then
    Exit;

  // regular death
  gi.sound(self, CHAN_VOICE, sound_death, 1, ATTN_NORM, 0);
  self^.deadflag := DEAD_DEAD;
  self^.takedamage := DAMAGE_YES;
  self^.monsterinfo.currentmove := @flipper_move_death;
end;

{QUAKED monster_flipper (1 .5 0) (-16 -16 -24) (16 16 32) Ambush Trigger_Spawn Sight
}
procedure SP_monster_flipper(self : edict_p);
begin
  if (deathmatch^.Value <> 0) then
  begin
    G_FreeEdict (self);
    Exit;
  end;

  sound_pain1        := gi.soundindex ('flipper/flppain1.wav');
  sound_pain2        := gi.soundindex ('flipper/flppain2.wav');
  sound_death        := gi.soundindex ('flipper/flpdeth1.wav');
  sound_chomp        := gi.soundindex ('flipper/flpatck1.wav');
  sound_attack        := gi.soundindex ('flipper/flpatck2.wav');
  sound_idle        := gi.soundindex ('flipper/flpidle1.wav');
  sound_search        := gi.soundindex ('flipper/flpsrch1.wav');
  sound_sight        := gi.soundindex ('flipper/flpsght1.wav');

  self^.movetype := MOVETYPE_STEP;
  self^.solid := SOLID_BBOX;
  self^.s.modelindex := gi.modelindex('models/monsters/flipper/tris.md2');
  VectorSet(self^.mins, -16, -16, 0);
  VectorSet(self^.maxs,  16,  16, 32);

  self^.health := 50;
  self^.gib_health := -30;
  self^.mass := 100;

  self^.pain := flipper_pain;
  self^.die  := flipper_die;

  self^.monsterinfo.stand := flipper_stand;
  self^.monsterinfo.walk  := flipper_walk;
  self^.monsterinfo.run   := flipper_start_run;
  self^.monsterinfo.melee := flipper_melee;
  self^.monsterinfo.sight := flipper_sight;

  gi.linkentity(self);

  self^.monsterinfo.currentmove := @flipper_move_stand;
  self^.monsterinfo.scale := MODEL_SCALE;

  swimmonster_start(self);
end;

end.

