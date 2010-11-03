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


{$DEFINE CTF}
//100%
{$ALIGN ON}{$MINENUMSIZE 4}
{----------------------------------------------------------------------------}
{                                                                            }
{ File(s): game\g_save.c                                                     }
{ Content: Saving and loading games                                          }
{                                                                            }
{ Initial conversion by: Carl A Kenner (carlkenner@hotmail.com)              }
{ Initial conversion on: 28-Feb-2002                                         }
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
{ Updated on: 3-Mar-2002                                                     }
{ Updated by: Carl A Kenner                                                  }
{                                                                            }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{ g_items.InitItems, p_client.SaveClientData                                 }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{ check for errors                                                           }
{----------------------------------------------------------------------------}
unit g_save;

{$DEFINE NODEPEND}

interface
Uses q_shared, GameUnit, g_local;

Const __Date__ = 'Mar 01 2002';

Var mmove_reloc: mmove_t;

procedure InitGame; cdecl;
procedure WriteGame(filename: PChar; autosave: qboolean); cdecl;
procedure ReadGame(filename: PChar); cdecl;
procedure WriteLevel(filename: PChar); cdecl;
procedure ReadLevel(filename: PChar); cdecl;

var
  fields: Array[0..80] of field_t;
  clientfields: Array[0..3] of field_t;
  levelfields: Array[0..5] of field_t;

// CAK - These were originally 4 macros in g_local.h
// But this was the only way to convert them, and because they are so long, I moved them here.
function FOFS_classname: Integer;
function FOFS_model: Integer;
function FOFS_spawnflags: Integer;
function FOFS_speed: Integer;
function FOFS_accel: Integer;
function FOFS_decel: Integer;
function FOFS_target: Integer;
function FOFS_targetname: Integer;
function FOFS_pathtarget: Integer;
function FOFS_deathtarget: Integer;
function FOFS_killtarget: Integer;
function FOFS_combattarget: Integer;
function FOFS_message: Integer;
function FOFS_team: Integer;
function FOFS_wait: Integer;
function FOFS_delay: Integer;
function FOFS_random: Integer;
function FOFS_move_origin: Integer;
function FOFS_move_angles: Integer;
function FOFS_style: Integer;
function FOFS_count: Integer;
function FOFS_health: Integer;
function FOFS_sounds: Integer;
//function FOFS_light: Integer;
function FOFS_dmg: Integer;
function FOFS_mass: Integer;
function FOFS_volume: Integer;
function FOFS_attenuation: Integer;
function FOFS_map: Integer;
function FOFS_s_origin: Integer;
function FOFS_s_angles: Integer;
//function FOFS_s_angles: Integer;

function FOFS_goalentity: Integer;
function FOFS_movetarget: Integer;
function FOFS_enemy: Integer;
function FOFS_oldenemy: Integer;
function FOFS_activator: Integer;
function FOFS_groundentity: Integer;
function FOFS_teamchain: Integer;
function FOFS_teammaster: Integer;
function FOFS_owner: Integer;
function FOFS_mynoise: Integer;
function FOFS_mynoise2: Integer;
function FOFS_target_ent: Integer;
function FOFS_chain: Integer;

function FOFS_prethink: Integer;
function FOFS_think: Integer;
function FOFS_blocked: Integer;
function FOFS_touch: Integer;
function FOFS_use: Integer;
function FOFS_pain: Integer;
function FOFS_die: Integer;

function FOFS_monsterinfo_stand: Integer;
function FOFS_monsterinfo_idle: Integer;
function FOFS_monsterinfo_search: Integer;
function FOFS_monsterinfo_walk: Integer;
function FOFS_monsterinfo_run: Integer;
function FOFS_monsterinfo_dodge: Integer;
function FOFS_monsterinfo_attack: Integer;
function FOFS_monsterinfo_melee: Integer;
function FOFS_monsterinfo_sight: Integer;
function FOFS_monsterinfo_checkattack: Integer;
function FOFS_monsterinfo_currentmove: Integer;

function FOFS_moveinfo_endfunc: Integer;

function FOFS_item: Integer;

function STOFS_lip: Integer;
function STOFS_distance: Integer;
function STOFS_height: Integer;
function STOFS_noise: Integer;
function STOFS_pausetime: Integer;
function STOFS_item: Integer;

function STOFS_gravity: Integer;
function STOFS_sky: Integer;
function STOFS_skyrotate: Integer;
function STOFS_skyaxis: Integer;
function STOFS_minyaw: Integer;
function STOFS_maxyaw: Integer;
function STOFS_minpitch: Integer;
function STOFS_maxpitch: Integer;
function STOFS_nextmap: Integer;

function LLOFS_changemap: Integer;
function LLOFS_sight_client: Integer;
function LLOFS_sight_entity: Integer;
function LLOFS_sound_entity: Integer;
function LLOFS_sound2_entity: Integer;

function CLOFS_pers_weapon: Integer;
function CLOFS_pers_lastweapon: Integer;
function CLOFS_newweapon: Integer;

implementation

Uses SysUtils {$IFNDEF NODEPEND}, g_items{$ENDIF};

{$IFDEF NODEPEND}
procedure InitItems;
begin
  game.num_items := (sizeof(itemlist) div sizeof(itemlist[0])) - 1;
end;

procedure SaveClientData;
begin
end;
{$ENDIF}

// CAK - These were originally 4 macros in g_local.h
// But this was the only way to convert them, and because they are so long, I moved them here.

function FOFS_classname: Integer; begin Result:=Integer(@edict_p(Ptr(0)).classname); end;
function FOFS_model: Integer; begin Result:=Integer(@edict_p(Ptr(0)).model); end;
function FOFS_spawnflags: Integer; begin Result:=Integer(@edict_p(Ptr(0)).spawnflags); end;
function FOFS_speed: Integer; begin Result:=Integer(@edict_p(Ptr(0)).speed); end;
function FOFS_accel: Integer; begin Result:=Integer(@edict_p(Ptr(0)).accel); end;
function FOFS_decel: Integer; begin Result:=Integer(@edict_p(Ptr(0)).decel); end;
function FOFS_target: Integer; begin Result:=Integer(@edict_p(Ptr(0)).target); end;
function FOFS_targetname: Integer; begin Result:=Integer(@edict_p(Ptr(0)).targetname); end;
function FOFS_pathtarget: Integer; begin Result:=Integer(@edict_p(Ptr(0)).pathtarget); end;
function FOFS_deathtarget: Integer; begin Result:=Integer(@edict_p(Ptr(0)).deathtarget); end;
function FOFS_killtarget: Integer; begin Result:=Integer(@edict_p(Ptr(0)).killtarget); end;
function FOFS_combattarget: Integer; begin Result:=Integer(@edict_p(Ptr(0)).combattarget); end;
function FOFS_message: Integer; begin Result:=Integer(@edict_p(Ptr(0))._message); end;
function FOFS_team: Integer; begin Result:=Integer(@edict_p(Ptr(0)).team); end;
function FOFS_wait: Integer; begin Result:=Integer(@edict_p(Ptr(0)).wait); end;
function FOFS_delay: Integer; begin Result:=Integer(@edict_p(Ptr(0)).delay); end;
function FOFS_random: Integer; begin Result:=Integer(@edict_p(Ptr(0)).random); end;
function FOFS_move_origin: Integer; begin Result:=Integer(@edict_p(Ptr(0)).move_origin); end;
function FOFS_move_angles: Integer; begin Result:=Integer(@edict_p(Ptr(0)).move_angles); end;
function FOFS_style: Integer; begin Result:=Integer(@edict_p(Ptr(0)).style); end;
function FOFS_count: Integer; begin Result:=Integer(@edict_p(Ptr(0)).count); end;
function FOFS_health: Integer; begin Result:=Integer(@edict_p(Ptr(0)).health); end;
function FOFS_sounds: Integer; begin Result:=Integer(@edict_p(Ptr(0)).sounds); end;
//function FOFS_light: Integer; begin Result:=Integer(@edict_p(Ptr(0)).light); end;
function FOFS_dmg: Integer; begin Result:=Integer(@edict_p(Ptr(0)).dmg); end;
function FOFS_mass: Integer; begin Result:=Integer(@edict_p(Ptr(0)).mass); end;
function FOFS_volume: Integer; begin Result:=Integer(@edict_p(Ptr(0)).volume); end;
function FOFS_attenuation: Integer; begin Result:=Integer(@edict_p(Ptr(0)).attenuation); end;
function FOFS_map: Integer; begin Result:=Integer(@edict_p(Ptr(0)).map); end;
function FOFS_s_origin: Integer; begin Result:=Integer(@edict_p(Ptr(0)).s.origin); end;
function FOFS_s_angles: Integer; begin Result:=Integer(@edict_p(Ptr(0)).s.angles); end;
//function FOFS_s_angles: Integer; begin Result:=Integer(@edict_p(Ptr(0)).s.angles); end;

function FOFS_goalentity: Integer; begin Result:=Integer(@edict_p(Ptr(0)).goalentity); end;
function FOFS_movetarget: Integer; begin Result:=Integer(@edict_p(Ptr(0)).movetarget); end;
function FOFS_enemy: Integer; begin Result:=Integer(@edict_p(Ptr(0)).enemy); end;
function FOFS_oldenemy: Integer; begin Result:=Integer(@edict_p(Ptr(0)).oldenemy); end;
function FOFS_activator: Integer; begin Result:=Integer(@edict_p(Ptr(0)).activator); end;
function FOFS_groundentity: Integer; begin Result:=Integer(@edict_p(Ptr(0)).groundentity); end;
function FOFS_teamchain: Integer; begin Result:=Integer(@edict_p(Ptr(0)).teamchain); end;
function FOFS_teammaster: Integer; begin Result:=Integer(@edict_p(Ptr(0)).teammaster); end;
function FOFS_owner: Integer; begin Result:=Integer(@edict_p(Ptr(0)).owner); end;
function FOFS_mynoise: Integer; begin Result:=Integer(@edict_p(Ptr(0)).mynoise); end;
function FOFS_mynoise2: Integer; begin Result:=Integer(@edict_p(Ptr(0)).mynoise2); end;
function FOFS_target_ent: Integer; begin Result:=Integer(@edict_p(Ptr(0)).target_ent); end;
function FOFS_chain: Integer; begin Result:=Integer(@edict_p(Ptr(0)).chain); end;

function FOFS_prethink: Integer; begin Result:=Integer(@edict_p(Ptr(0)).prethink); end;
function FOFS_think: Integer; begin Result:=Integer(@edict_p(Ptr(0)).think); end;
function FOFS_blocked: Integer; begin Result:=Integer(@edict_p(Ptr(0)).blocked); end;
function FOFS_touch: Integer; begin Result:=Integer(@edict_p(Ptr(0)).touch); end;
function FOFS_use: Integer; begin Result:=Integer(@edict_p(Ptr(0)).use); end;
function FOFS_pain: Integer; begin Result:=Integer(@edict_p(Ptr(0)).pain); end;
function FOFS_die: Integer; begin Result:=Integer(@edict_p(Ptr(0)).die); end;

function FOFS_monsterinfo_stand: Integer; begin Result:=Integer(@edict_p(Ptr(0)).monsterinfo.stand); end;
function FOFS_monsterinfo_idle: Integer; begin Result:=Integer(@edict_p(Ptr(0)).monsterinfo.idle); end;
function FOFS_monsterinfo_search: Integer; begin Result:=Integer(@edict_p(Ptr(0)).monsterinfo.search); end;
function FOFS_monsterinfo_walk: Integer; begin Result:=Integer(@edict_p(Ptr(0)).monsterinfo.walk); end;
function FOFS_monsterinfo_run: Integer; begin Result:=Integer(@edict_p(Ptr(0)).monsterinfo.run); end;
function FOFS_monsterinfo_dodge: Integer; begin Result:=Integer(@edict_p(Ptr(0)).monsterinfo.dodge); end;
function FOFS_monsterinfo_attack: Integer; begin Result:=Integer(@edict_p(Ptr(0)).monsterinfo.attack); end;
function FOFS_monsterinfo_melee: Integer; begin Result:=Integer(@edict_p(Ptr(0)).monsterinfo.melee); end;
function FOFS_monsterinfo_sight: Integer; begin Result:=Integer(@edict_p(Ptr(0)).monsterinfo.sight); end;
function FOFS_monsterinfo_checkattack: Integer; begin Result:=Integer(@edict_p(Ptr(0)).monsterinfo.checkattack); end;
function FOFS_monsterinfo_currentmove: Integer; begin Result:=Integer(@edict_p(Ptr(0)).monsterinfo.currentmove); end;

function FOFS_moveinfo_endfunc: Integer; begin Result:=Integer(@edict_p(Ptr(0)).moveinfo.endfunc); end;

function FOFS_item: Integer; begin Result:=Integer(@edict_p(Ptr(0)).item); end;

function STOFS_lip: Integer; begin Result:=Integer(@spawn_temp_p(Ptr(0)).lip); end;
function STOFS_distance: Integer; begin Result:=Integer(@spawn_temp_p(Ptr(0)).distance); end;
function STOFS_height: Integer; begin Result:=Integer(@spawn_temp_p(Ptr(0)).height); end;
function STOFS_noise: Integer; begin Result:=Integer(@spawn_temp_p(Ptr(0)).noise); end;
function STOFS_pausetime: Integer; begin Result:=Integer(@spawn_temp_p(Ptr(0)).pausetime); end;
function STOFS_item: Integer; begin Result:=Integer(@spawn_temp_p(Ptr(0)).item); end;

function STOFS_gravity: Integer; begin Result:=Integer(@spawn_temp_p(Ptr(0)).gravity); end;
function STOFS_sky: Integer; begin Result:=Integer(@spawn_temp_p(Ptr(0)).sky); end;
function STOFS_skyrotate: Integer; begin Result:=Integer(@spawn_temp_p(Ptr(0)).skyrotate); end;
function STOFS_skyaxis: Integer; begin Result:=Integer(@spawn_temp_p(Ptr(0)).skyaxis); end;
function STOFS_minyaw: Integer; begin Result:=Integer(@spawn_temp_p(Ptr(0)).minyaw); end;
function STOFS_maxyaw: Integer; begin Result:=Integer(@spawn_temp_p(Ptr(0)).maxyaw); end;
function STOFS_minpitch: Integer; begin Result:=Integer(@spawn_temp_p(Ptr(0)).minpitch); end;
function STOFS_maxpitch: Integer; begin Result:=Integer(@spawn_temp_p(Ptr(0)).maxpitch); end;
function STOFS_nextmap: Integer; begin Result:=Integer(@spawn_temp_p(Ptr(0)).nextmap); end;

function LLOFS_changemap: Integer; begin Result:=Integer(@level_locals_p(Ptr(0)).changemap); end;
function LLOFS_sight_client: Integer; begin Result:=Integer(@level_locals_p(Ptr(0)).sight_client); end;
function LLOFS_sight_entity: Integer; begin Result:=Integer(@level_locals_p(Ptr(0)).sight_entity); end;
function LLOFS_sound_entity: Integer; begin Result:=Integer(@level_locals_p(Ptr(0)).sound_entity); end;
function LLOFS_sound2_entity: Integer; begin Result:=Integer(@level_locals_p(Ptr(0)).sound2_entity); end;

function CLOFS_pers_weapon: Integer; begin Result:=Integer(@gclient_p(Ptr(0)).pers.weapon); end;
function CLOFS_pers_lastweapon: Integer; begin Result:=Integer(@gclient_p(Ptr(0)).pers.lastweapon); end;
function CLOFS_newweapon: Integer; begin Result:=Integer(@gclient_p(Ptr(0)).newweapon); end;

procedure SetFields;
begin
  with fields[0] do begin
    name:='classname'; ofs:= FOFS_classname; _type:= F_LSTRING;
  end;
  with fields[1] do begin
    name:='model'; ofs:= FOFS_model; _type:= F_LSTRING;
  end;
  with fields[2] do begin
    name:='spawnflags'; ofs:= FOFS_spawnflags; _type:= F_INT;
  end;
  with fields[3] do begin
    name:='speed'; ofs:= FOFS_speed; _type:= F_FLOAT;
  end;
  with fields[4] do begin
    name:='accel'; ofs:= FOFS_accel; _type:= F_FLOAT;
  end;
  with fields[5] do begin
    name:='decel'; ofs:= FOFS_decel; _type:= F_FLOAT;
  end;
  with fields[6] do begin
    name:='target'; ofs:= FOFS_target; _type:= F_LSTRING;
  end;
  with fields[7] do begin
    name:='targetname'; ofs:= FOFS_targetname; _type:= F_LSTRING;
  end;
  with fields[8] do begin
    name:='pathtarget'; ofs:= FOFS_pathtarget; _type:= F_LSTRING;
  end;
  with fields[9] do begin
    name:='deathtarget'; ofs:= FOFS_deathtarget; _type:= F_LSTRING;
  end;
  with fields[10] do begin
    name:='killtarget'; ofs:= FOFS_killtarget; _type:= F_LSTRING;
  end;
  with fields[11] do begin
    name:='combattarget'; ofs:= FOFS_combattarget; _type:= F_LSTRING;
  end;
  with fields[12] do begin name:='message'; ofs:= FOFS_message; _type:= F_LSTRING; end;
  with fields[13] do begin name:='team'; ofs:= FOFS_team; _type:= F_LSTRING; end;
  with fields[14] do begin name:='wait'; ofs:= FOFS_wait; _type:= F_FLOAT; end;
  with fields[15] do begin name:='delay'; ofs:= FOFS_delay; _type:= F_FLOAT; end;
  with fields[16] do begin name:='random'; ofs:= FOFS_random; _type:= F_FLOAT; end;
  with fields[17] do begin name:='move_origin'; ofs:= FOFS_move_origin; _type:= F_VECTOR; end;
  with fields[18] do begin name:='move_angles'; ofs:= FOFS_move_angles; _type:= F_VECTOR; end;
  with fields[19] do begin name:='style'; ofs:= FOFS_style; _type:= F_INT; end;
  with fields[20] do begin name:='count'; ofs:= FOFS_count; _type:= F_INT; end;
  with fields[21] do begin name:='health'; ofs:= FOFS_health; _type:= F_INT; end;
  with fields[22] do begin name:='sounds'; ofs:= FOFS_sounds; _type:= F_INT; end;
  with fields[23] do begin name:='light'; ofs:= 0; _type:= F_IGNORE; end;
  with fields[24] do begin name:='dmg'; ofs:= FOFS_dmg; _type:= F_INT; end;
  with fields[25] do begin name:='mass'; ofs:= FOFS_mass; _type:= F_INT; end;
  with fields[26] do begin name:='volume'; ofs:= FOFS_volume; _type:= F_FLOAT; end;
  with fields[27] do begin name:='attenuation'; ofs:= FOFS_attenuation; _type:= F_FLOAT; end;
  with fields[28] do begin name:='map'; ofs:= FOFS_map; _type:= F_LSTRING; end;
  with fields[29] do begin name:='origin'; ofs:= FOFS_s_origin; _type:= F_VECTOR; end;
  with fields[30] do begin name:='angles'; ofs:= FOFS_s_angles; _type:= F_VECTOR; end;
  with fields[31] do begin name:='angle'; ofs:= FOFS_s_angles; _type:= F_ANGLEHACK; end;

{$IFNDEF CTF}
  with fields[32] do begin name:='goalentity'; ofs:= FOFS_goalentity; _type:= F_EDICT; flags:= FFL_NOSPAWN; end;
  with fields[33] do begin name:='movetarget'; ofs:= FOFS_movetarget; _type:= F_EDICT; flags:= FFL_NOSPAWN; end;
  with fields[34] do begin name:='enemy'; ofs:= FOFS_enemy; _type:= F_EDICT; flags:= FFL_NOSPAWN; end;
  with fields[35] do begin name:='oldenemy'; ofs:= FOFS_oldenemy; _type:= F_EDICT; flags:= FFL_NOSPAWN; end;
  with fields[36] do begin name:='activator'; ofs:= FOFS_activator; _type:= F_EDICT; flags:= FFL_NOSPAWN; end;
  with fields[37] do begin name:='groundentity'; ofs:= FOFS_groundentity; _type:= F_EDICT; flags:= FFL_NOSPAWN; end;
  with fields[38] do begin name:='teamchain'; ofs:= FOFS_teamchain; _type:= F_EDICT; flags:= FFL_NOSPAWN; end;
  with fields[39] do begin name:='teammaster'; ofs:= FOFS_teammaster; _type:= F_EDICT; flags:= FFL_NOSPAWN; end;
  with fields[40] do begin name:='owner'; ofs:= FOFS_owner; _type:= F_EDICT; flags:= FFL_NOSPAWN; end;
  with fields[41] do begin name:='mynoise'; ofs:= FOFS_mynoise; _type:= F_EDICT; flags:= FFL_NOSPAWN; end;
  with fields[42] do begin name:='mynoise2'; ofs:= FOFS_mynoise2; _type:= F_EDICT; flags:= FFL_NOSPAWN; end;
  with fields[43] do begin name:='target_ent'; ofs:= FOFS_target_ent; _type:= F_EDICT; flags:= FFL_NOSPAWN; end;
  with fields[44] do begin name:='chain'; ofs:= FOFS_chain; _type:= F_EDICT; flags:= FFL_NOSPAWN; end;

  with fields[45] do begin name:='prethink'; ofs:= FOFS_prethink; _type:= F_FUNCTION; flags:= FFL_NOSPAWN; end;
  with fields[46] do begin name:='think'; ofs:= FOFS_think; _type:= F_FUNCTION; flags:= FFL_NOSPAWN; end;
  with fields[47] do begin name:='blocked'; ofs:= FOFS_blocked; _type:= F_FUNCTION; flags:= FFL_NOSPAWN; end;
  with fields[48] do begin name:='touch'; ofs:= FOFS_touch; _type:= F_FUNCTION; flags:= FFL_NOSPAWN; end;
  with fields[49] do begin name:='use'; ofs:= FOFS_use; _type:= F_FUNCTION; flags:= FFL_NOSPAWN; end;
  with fields[50] do begin name:='pain'; ofs:= FOFS_pain; _type:= F_FUNCTION; flags:= FFL_NOSPAWN; end;
  with fields[51] do begin name:='die'; ofs:= FOFS_die; _type:= F_FUNCTION; flags:= FFL_NOSPAWN; end;

  with fields[52] do begin name:='stand'; ofs:= FOFS_monsterinfo_stand; _type:= F_FUNCTION; flags:= FFL_NOSPAWN; end;
  with fields[53] do begin name:='idle'; ofs:= FOFS_monsterinfo_idle; _type:= F_FUNCTION; flags:= FFL_NOSPAWN; end;
  with fields[54] do begin name:='search'; ofs:= FOFS_monsterinfo_search; _type:= F_FUNCTION; flags:= FFL_NOSPAWN; end;
  with fields[55] do begin name:='walk'; ofs:= FOFS_monsterinfo_walk; _type:= F_FUNCTION; flags:= FFL_NOSPAWN; end;
  with fields[56] do begin name:='run'; ofs:= FOFS_monsterinfo_run; _type:= F_FUNCTION; flags:= FFL_NOSPAWN; end;
  with fields[57] do begin name:='dodge'; ofs:= FOFS_monsterinfo_dodge; _type:= F_FUNCTION; flags:= FFL_NOSPAWN; end;
  with fields[58] do begin name:='attack'; ofs:= FOFS_monsterinfo_attack; _type:= F_FUNCTION; flags:= FFL_NOSPAWN; end;
  with fields[59] do begin name:='melee'; ofs:= FOFS_monsterinfo_melee; _type:= F_FUNCTION; flags:= FFL_NOSPAWN; end;
  with fields[60] do begin name:='sight'; ofs:= FOFS_monsterinfo_sight; _type:= F_FUNCTION; flags:= FFL_NOSPAWN; end;
  with fields[61] do begin name:='checkattack'; ofs:= FOFS_monsterinfo_checkattack; _type:= F_FUNCTION; flags:= FFL_NOSPAWN; end;
  with fields[62] do begin name:='currentmove'; ofs:= FOFS_monsterinfo_currentmove; _type:= F_MMOVE; flags:= FFL_NOSPAWN; end;

  with fields[63] do begin name:='endfunc'; ofs:= FOFS_moveinfo_endfunc; _type:= F_FUNCTION; flags:= FFL_NOSPAWN; end;

  // temp spawn vars -- only valid when the spawn function is called
  with fields[64] do begin name:='lip'; ofs:= STOFS_lip; _type:= F_INT; flags:= FFL_SPAWNTEMP; end;
  with fields[65] do begin name:='distance'; ofs:= STOFS_distance; _type:= F_INT; flags:= FFL_SPAWNTEMP; end;
  with fields[66] do begin name:='height'; ofs:= STOFS_height; _type:= F_INT; flags:= FFL_SPAWNTEMP; end;
  with fields[67] do begin name:='noise'; ofs:= STOFS_noise; _type:= F_LSTRING; flags:= FFL_SPAWNTEMP; end;
  with fields[68] do begin name:='pausetime'; ofs:= STOFS_pausetime; _type:= F_FLOAT; flags:= FFL_SPAWNTEMP; end;
  with fields[69] do begin name:='item'; ofs:= STOFS_item; _type:= F_LSTRING; flags:= FFL_SPAWNTEMP; end;

  //need for item field in edict struct, FFL_SPAWNTEMP item will be skipped on saves
  with fields[70] do begin name:='item'; ofs:= FOFS_item; _type:= F_ITEM; end;

  with fields[71] do begin name:='gravity'; ofs:= STOFS_gravity; _type:= F_LSTRING; flags:= FFL_SPAWNTEMP; end;
  with fields[72] do begin name:='sky'; ofs:= STOFS_sky; _type:= F_LSTRING; flags:= FFL_SPAWNTEMP; end;
  with fields[73] do begin name:='skyrotate'; ofs:= STOFS_skyrotate; _type:= F_FLOAT; flags:= FFL_SPAWNTEMP; end;
  with fields[74] do begin name:='skyaxis'; ofs:= STOFS_skyaxis; _type:= F_VECTOR; flags:= FFL_SPAWNTEMP; end;
  with fields[75] do begin name:='minyaw'; ofs:= STOFS_minyaw; _type:= F_FLOAT; flags:= FFL_SPAWNTEMP; end;
  with fields[76] do begin name:='maxyaw'; ofs:= STOFS_maxyaw; _type:= F_FLOAT; flags:= FFL_SPAWNTEMP; end;
  with fields[77] do begin name:='minpitch'; ofs:= STOFS_minpitch; _type:= F_FLOAT; flags:= FFL_SPAWNTEMP; end;
  with fields[78] do begin name:='maxpitch'; ofs:= STOFS_maxpitch; _type:= F_FLOAT; flags:= FFL_SPAWNTEMP; end;
  with fields[79] do begin name:='nextmap'; ofs:= STOFS_nextmap; _type:= F_LSTRING; flags:= FFL_SPAWNTEMP; end;
{$ENDIF}
  with fields[80] do begin name:=Nil; ofs:= 0; _type:= fieldtype_t(0); flags:= 0; end;
end;

procedure SetLevelFields;
begin
  with levelfields[0] do begin
    name:='changemap'; ofs:= LLOFS_changemap; _type:= F_LSTRING;
  end;
  with levelfields[1] do begin
    name:='sight_client'; ofs:= LLOFS_sight_client; _type:= F_EDICT;
  end;
  with levelfields[2] do begin
    name:='sight_entity'; ofs:= LLOFS_sight_entity; _type:= F_EDICT;
  end;
  with levelfields[3] do begin
    name:='sound_entity'; ofs:= LLOFS_sound_entity; _type:= F_EDICT;
  end;
  with levelfields[4] do begin
    name:='sound2_entity'; ofs:= LLOFS_sound2_entity; _type:= F_EDICT;
  end;
  with levelfields[5] do begin
    name:=Nil; ofs:= 0; _type:= F_INT;
  end;
end;

procedure SetClientFields;
begin
  with clientfields[0] do begin
    name:='pers.weapon'; ofs:= CLOFS_pers_weapon; _type:= F_ITEM;
  end;
  with clientfields[1] do begin
    name:='pers.lastweapon'; ofs:= CLOFS_pers_lastweapon; _type:= F_ITEM;
  end;
  with clientfields[2] do begin
    name:='newweapon'; ofs:= CLOFS_newweapon; _type:= F_ITEM;
  end;
  with clientfields[3] do begin
    name:=Nil; ofs:= 0; _type:= F_INT;
  end;
end;


(*
============
InitGame

This will be called when the dll is first loaded, which
only happens when a new game is started or a save game
is loaded.
============
*)
procedure InitGame; cdecl;
begin
{$IFNDEF CTF}
  gi.dprintf('==== InitGame ===='#10);

  gun_x := gi.cvar('gun_x', '0', 0);
  gun_y := gi.cvar('gun_y', '0', 0);
  gun_z := gi.cvar('gun_z', '0', 0);

  //FIXME: sv_ prefix is wrong for these
  sv_rollspeed := gi.cvar('sv_rollspeed', '200', 0);
  sv_rollangle := gi.cvar('sv_rollangle', '2', 0);
  sv_maxvelocity := gi.cvar('sv_maxvelocity', '2000', 0);
  sv_gravity := gi.cvar('sv_gravity', '800', 0);

  // noset vars
  dedicated := gi.cvar('dedicated', '0', CVAR_NOSET);

  // latched vars
  sv_cheats := gi.cvar('cheats', '0', CVAR_SERVERINFO OR CVAR_LATCH);
  gi.cvar('gamename', GAMEVERSION, CVAR_SERVERINFO OR CVAR_LATCH);
  gi.cvar('gamedate', __DATE__ , CVAR_SERVERINFO OR CVAR_LATCH);

  maxclients := gi.cvar('maxclients', '4', CVAR_SERVERINFO OR CVAR_LATCH);
  maxspectators := gi.cvar('maxspectators', '4', CVAR_SERVERINFO);
  deathmatch := gi.cvar('deathmatch', '0', CVAR_LATCH);
  coop := gi.cvar('coop', '0', CVAR_LATCH);
  skill := gi.cvar('skill', '1', CVAR_LATCH);
  maxentities := gi.cvar('maxentities', '1024', CVAR_LATCH);

  // change anytime vars
  dmflags := gi.cvar('dmflags', '0', CVAR_SERVERINFO);
  fraglimit := gi.cvar('fraglimit', '0', CVAR_SERVERINFO);
  timelimit := gi.cvar('timelimit', '0', CVAR_SERVERINFO);
  password := gi.cvar('password', '', CVAR_USERINFO);
  spectator_password := gi.cvar('spectator_password', '', CVAR_USERINFO);
  needpass := gi.cvar('needpass', '0', CVAR_SERVERINFO);
  filterban := gi.cvar('filterban', '1', 0);

  g_select_empty := gi.cvar ('g_select_empty', '0', CVAR_ARCHIVE);

  run_pitch := gi.cvar('run_pitch', '0.002', 0);
  run_roll := gi.cvar('run_roll', '0.005', 0);
  bob_up := gi.cvar('bob_up', '0.005', 0);
  bob_pitch := gi.cvar('bob_pitch', '0.002', 0);
  bob_roll := gi.cvar('bob_roll', '0.002', 0);

  // flood control
  flood_msgs := gi.cvar('flood_msgs', '4', 0);
  flood_persecond := gi.cvar('flood_persecond', '4', 0);
  flood_waitdelay := gi.cvar('flood_waitdelay', '10', 0);

  // dm map list
  sv_maplist := gi.cvar('sv_maplist', '', 0);

  // items
  InitItems();

  Com_sprintf(game.helpmessage1, sizeof(game.helpmessage1), '', ['']);

  Com_sprintf(game.helpmessage2, sizeof(game.helpmessage2), '', ['']);

  // initialize all entities for this game
  game.maxentities := Trunc(maxentities.value); //CAK - Trunc ?
  g_edicts :=  gi.TagMalloc (game.maxentities * sizeof(g_edicts[0]), TAG_GAME);
  globals.edicts := @g_edicts[0];
  globals.max_edicts := game.maxentities;

  // initialize all clients for this game
  game.maxclients := Trunc(maxclients.value);
  game.clients := gi.TagMalloc (game.maxclients * sizeof(gclient_a(game.clients)[0]), TAG_GAME);
  globals.num_edicts := game.maxclients+1;
{$ENDIF}
end;

//=========================================================

type
  pedict_p = ^edict_p;
  pgclient_p = ^gclient_p;
  pgitem_p = ^gitem_p;
  PPByte = ^PByte;

procedure WriteField1(Var f: File; field: field_p; base: PByte);
Var p: Pointer; len: Integer; index: Integer;
begin
{$IFNDEF CTF}
  if (field.flags AND FFL_SPAWNTEMP)>0 then
    exit;
  p := Pointer(LongInt(base) + field.ofs);
  case field._type of
    F_INT, F_FLOAT, F_ANGLEHACK, F_VECTOR, F_IGNORE: {do nothing};
    F_LSTRING, F_GSTRING: begin
      if PPChar(p)^<>Nil then
        len := strlen(PPChar(p)^)+1
      else
        len := 0;
      PInteger(p)^ := len;
    end;
    F_EDICT: begin
      if pedict_p(p)^ = Nil then
        index := -1
      else
        index := (LongInt(pedict_p(p)^) - LongInt(g_edicts)) div sizeof(edict_t);
      PInteger(p)^ := index;
    end;
    F_CLIENT: begin
      if pgclient_p(p)^ = Nil then
        index := -1
      else
        index := (LongInt(pgclient_p(p)^) - LongInt(game.clients)) div sizeof(gclient_t);
      PInteger(p)^ := index;
    end;
    F_ITEM: begin
      if pedict_p(p)^ = Nil then
        index := -1
      else
        index := (LongInt(pgitem_p(p)^) - LongInt(@itemlist)) div sizeof(gitem_t);
      PInteger(p)^ := index;
    end;
    //relative to code segment
    F_FUNCTION: begin
      if PPByte(p)^ = Nil then
        index := 0
      else
        index := LongInt(PPByte(p)^) - LongInt(PByte(@InitGame));
      PInteger(p)^ := index;
    end;
    //relative to data segment
    F_MMOVE: begin
      if PPByte(p)^ = Nil then
        index := 0
      else
        index := LongInt(PPByte(p)^) - LongInt(PByte(@mmove_reloc));
      PInteger(p)^ := index;
    end;
    else
      gi.error('WriteEdict: unknown field type');
  end;
{$ENDIF}
end;


procedure WriteField2(Var f: File; field: field_p; base: PByte);
Var len: Integer; p: Pointer;
begin
  if (field.flags AND FFL_SPAWNTEMP)>0 then
    exit;

  p := Pointer(LongInt(base) + field.ofs);
  case field._type of
    F_LSTRING:
      if PPChar(p)^ <> Nil then begin
        len := strlen(PPChar(p)^) + 1;
        BlockWrite(F, PPChar(p)^^, len);
      end;
  end;
end;

procedure ReadField(Var f: File; field: field_p; base: PByte);
Var p: Pointer; len: Integer; index: Integer;
begin
{$IFNDEF CTF}
  if (field.flags AND FFL_SPAWNTEMP)>0 then
    exit;

  p := Ptr(LongInt(base) + field.ofs);
  case field._type of
    F_INT, F_FLOAT, F_ANGLEHACK, F_VECTOR, F_IGNORE: {do nothing};
    F_LSTRING: begin
      len := PInteger(p)^;
      if len = 0 then
   PPChar(p)^ := Nil
      else begin
        PPChar(p)^ := gi.TagMalloc(len, TAG_LEVEL);
        BlockRead(f, PPChar(p)^^, len);
      end;
    end;
    F_EDICT: begin
      index := PInteger(p)^;
      if index = -1 then
        pedict_p(p)^ := Nil
      else
        pedict_p(p)^ := @g_edicts[index];
    end;
    F_CLIENT: begin
      index := PInteger(p)^;
      if index = -1 then
        pgclient_p(p)^ := Nil
      else
        pgclient_p(p)^ := @gclient_a(game.clients)[index];
    end;
    F_ITEM: begin
      index := PInteger(p)^;
      if index = -1 then
        pgitem_p(p)^ := Nil
      else
        pgitem_p(p)^ := @itemlist[index];
    end;
    //relative to code segment
    F_FUNCTION: begin
      index := PInteger(p)^;
      if index = 0 then
        PPByte(p)^ := Nil
      else
        PPByte(p)^ := PByte(LongInt(@InitGame)+index);
    end;
    //relative to data segment
    F_MMOVE: begin
      index := PInteger(p)^;
      if index = 0 then
   PPByte(p)^ := Nil
      else
   PPByte(p)^ := PByte(LongInt(@mmove_reloc) + index);
    end;
    else
      gi.error('ReadEdict: unknown field type');
  end {case};
{$ENDIF}
end {procedure};

//=========================================================

(*
==============
WriteClient

All pointer variables (except function pointers) must be handled specially.
==============
*)
procedure WriteClient(Var f: File; client: gclient_p);
Var field: field_p; temp: gclient_t;
begin
  // all of the ints, floats, and vectors stay as they are
  temp := client^;

  // change the pointers to lengths or indexes
  field:=@clientfields[0];
  while field.name <> Nil do begin
    WriteField1(f, field, PByte(@temp));
    inc(field);
  end;

  // write the block
  BlockWrite(f, temp, sizeof(temp));

  // now write any allocated data following the edict
  field:=@clientfields[0];
  while field.name<>Nil do begin
    WriteField2(f, field, PByte(client));
    inc(field);
  end;
end;

(*
==============
ReadClient

All pointer variables (except function pointers) must be handled specially.
==============
*)
procedure ReadClient(Var f: File; client: gclient_p);
Var field: field_p;
begin
  BlockRead(f, client^, sizeof(client^));
  field := @clientfields[0];
  while field.name<>Nil do begin
    ReadField(f, field, PByte(client));
    inc(field);
  end;
end;

(*
============
WriteGame

This will be called whenever the game goes to a new level,
and when the user explicitly saves the game.

Game information include cross level data, like multi level
triggers, help computer info, and all client states.

A single player death will automatically restore from the
last save position.
============
*)
procedure WriteGame(filename: PChar; autosave: qboolean); cdecl;
Var f: File; i: Integer; str: Array[0..15] of Char;
begin
  if not autosave then
    SaveClientData;

    try
      AssignFile(f, filename);
      Rewrite(f, 1);
    except
      gi_error('Couldn''t open %s', [filename]);
    end;

    FillChar(str[0],sizeof(str),0);
    strcopy(str, __DATE__);
    BlockWrite(f, str[0], sizeof(str));

    game.autosaved := autosave;
    BlockWrite(f, game, sizeof(game));
    game.autosaved := false;

    for i:=0 to game.maxclients-1 do begin
      WriteClient(f, @gclient_a(game.clients)[i]);
    end;

    CloseFile(f);
end;

procedure ReadGame(filename: PChar); cdecl;
Var f: File; i: Integer; str: Array[0..15] of Char;
begin
  gi.FreeTags(TAG_GAME);

  try
    AssignFile(f, filename);
    Reset(f,1);
  except
    gi_error('Couldn''t open %s', [filename]);
  end;

  BlockRead(f, str[0], sizeof(str));
  if strcomp(str, __DATE__) <> 0 then begin
    CloseFile(f);
    gi.error('Savegame from an older version.'#10);
  end;

  g_edicts := gi.TagMalloc(game.maxentities * sizeof(g_edicts[0]), TAG_GAME);
  globals.edicts := @g_edicts[0];

  BlockRead(f, game, sizeof(game));
  game.clients := gi.TagMalloc(game.maxclients * sizeof(gclient_t), TAG_GAME);
  for i:=0 to game.maxclients-1 do
    ReadClient(f, @gclient_a(game.clients)[i]);

  CloseFile(f);
end;

//==========================================================

(*
==============
WriteEdict

All pointer variables (except function pointers) must be handled specially.
==============
*)
procedure WriteEdict(Var f: File; ent: edict_p);
Var field: field_p; temp: edict_t;
begin
  // all of the ints, floats, and vectors stay as they are
  temp := ent^;

  // change the pointers to lengths or indexes
  field := @fields[0];
  while (field.name <> Nil) do begin
    WriteField1(f, field, PByte(@temp));
    inc(field);
  end;

  // write the block
  BlockWrite(f, temp, sizeof(temp));

  // now write any allocated data following the edict
  field := @fields[0];
  while field.name <> Nil do begin
    WriteField2(f, field, PByte(ent));
    inc(field);
  end;
end;

(*
==============
WriteLevelLocals

All pointer variables (except function pointers) must be handled specially.
==============
*)
procedure WriteLevelLocals(Var f: File);
Var field: field_p; temp: level_locals_t;
begin
  // all of the ints, floats, and vectors stay as they are
  temp := level;

  // change the pointers to lengths or indexes
  field := @levelfields[0];
  While field.name <> Nil do begin
    WriteField1(f, field, PByte(@temp));
    inc(field);
  end;

  // write the block
  BlockWrite(f, temp, sizeof(temp));

  // now write any allocated data following the edict
  field := @levelfields[0];
  While field.name <> Nil do begin
    WriteField2(f, field, PByte(@level));
    inc(field);
  end;
end;


(*
==============
ReadEdict

All pointer variables (except function pointers) must be handled specially.
==============
*)
procedure ReadEdict(Var f: File; ent: edict_p);
Var field: field_p;
begin
  BlockRead(f, ent^, sizeof(ent^));

  field := @fields[0];
  While field.name <> Nil do begin
    ReadField(f, field, PByte(ent));
    inc(field);
  end;
end;

(*
==============
ReadLevelLocals

All pointer variables (except function pointers) must be handled specially.
==============
*)
procedure ReadLevelLocals(Var f: File);
Var field: field_p;
begin
  BlockRead(f, level, sizeof(level));

  field := @levelfields[0];
  While field.name <> Nil do begin
    ReadField(f, field, PByte(@level));
    inc(field);
  end;
end;

(*
=================
WriteLevel

=================
*)
procedure WriteLevel(filename: PChar); cdecl;
Var i: Integer; ent: edict_p; f: File; base: Pointer;
begin
  Try
    AssignFile(f, filename);
    Rewrite(f, 1);
  Except
    gi_error('Couldn''t open %s', [filename]);
  end;


  // write out edict size for checking
  i := sizeof(edict_t);
  BlockWrite(f, i, sizeof(i));

  // write out a function pointer for checking
  base := @InitGame;
  BlockWrite(f, base, sizeof(base));

  // write out level_locals_t
  WriteLevelLocals(f);

  // write out all the entities
  for i:=0 to globals.num_edicts - 1 do begin
    ent := @g_edicts[i];
    if not ent.inuse then
      continue;
    BlockWrite(f, i, sizeof(i));
    WriteEdict(f, ent);
  end;
  i := -1;
  BlockWrite(f, i, sizeof(i));

  CloseFile(f);
end;


(*
=================
ReadLevel

SpawnEntities will allready have been called on the
level the same way it was when the level was saved.

That is necessary to get the baselines
set up identically.

The server will have cleared all of the world links before
calling ReadLevel.

No clients are connected yet.
=================
*)
procedure ReadLevel(filename: PChar); cdecl;
Var entnum: Integer; f: File; i: Integer; base: Pointer; ent: edict_p;
BytesRead: Integer;
begin
  Try
    AssignFile(f, filename);
    Reset(f, 1);
  Except
    gi_error('Couldn''t open %s', [filename]);
  end;

  // free any dynamic memory allocated by loading the level
  // base state
  gi.FreeTags(TAG_LEVEL);

  // wipe all the entities
  FillChar(g_edicts, game.maxentities*sizeof(g_edicts[0]), 0);
  globals.num_edicts := Trunc(maxclients.value)+1;

  // check edict size
  BlockRead(f, i, sizeof(i));
  if i <> sizeof(edict_t) then begin
    CloseFile(f);
    gi.error('ReadLevel: mismatched edict size');
  end;

  // check function pointer base address
  BlockRead(f, base, sizeof(base));
{$ifdef WIN32}
  if base <> @InitGame then begin
    CloseFile(f);
    gi.error('ReadLevel: function pointers have moved');
  end;
{$else}
  gi_dprintf('Function offsets %d\n', [LongInt(base) - LongInt(@InitGame)]);
{$endif}

  // load the level locals
  ReadLevelLocals(f);

  // load all the entities
  while true do begin
    BlockRead(f, entnum, sizeof(entnum), BytesRead);
    if BytesRead <> sizeof(entnum) then begin
      CloseFile(f);
      gi.error('ReadLevel: failed to read entnum');
    end;
    if entnum = -1 then
      break;
    if entnum >= globals.num_edicts then
      globals.num_edicts := entnum+1;

    ent := @g_edicts[entnum];
    ReadEdict(f, ent);

    // let the server rebuild world links for this ent
    FillChar(ent.area, sizeof(ent.area), 0);
    gi.linkentity(ent);
  end;

  CloseFile(f);

  // mark all clients as unconnected
  for i:=0 to Trunc(maxclients.value) - 1 do begin
    ent := @g_edicts[i+1];
    ent.client := @gclient_a(game.clients)[i];
    ent.client.pers.connected := false;
  end;

  // do any load time things at this point
  for i:=0 to globals.num_edicts-1 do begin
    ent := @g_edicts[i];

    if not ent.inuse then
      continue;

    // fire any cross-level triggers
    if ent.classname <> Nil then
      if (strcomp(ent.classname, 'target_crosslevel_target') = 0) then
        ent.nextthink := level.time + ent.delay;
  end;
end;

Initialization
  SetFields;
  SetLevelFields;
  SetClientFields;
end.


