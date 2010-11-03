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
{$ALIGN ON}{$MINENUMSIZE 4}
{----------------------------------------------------------------------------}
{                                                                            }
{ File(s): game\g_local.h                                                    }
{          ctf\g_local.h (if you define CTF)                                 }
{ Content: local definitions for game module                                 }
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
{ Updated on : 3-Mar-2002                                                    }
{ Updated by : Carl A Kenner (carl_kenner@hotmail.com)                       }
{                                                                            }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{ none!!!!! (completely self contained)                                      }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{----------------------------------------------------------------------------}
unit g_local;

interface

uses
  GameUnit,
  g_local_add,
  q_shared;


type

  damage_p = g_local_add.damage_p;
  damage_t = g_local_add.damage_t;

  weaponstate_p = g_local_add.weaponstate_p;
  weaponstate_t = g_local_add.weaponstate_t;

  ammo_p = ^ammo_t;
  ammo_t = (
    AMMO_BULLETS,
    AMMO_SHELLS,
    AMMO_ROCKETS,
    AMMO_GRENADES,
    AMMO_CELLS,
    AMMO_SLUGS
  );

// edict->movetype values
  movetype_p = g_local_add.movetype_p;
  movetype_t = g_local_add.movetype_t;

  gitem_armor_p = ^gitem_armor_t;
  gitem_armor_t = record
    base_count: integer;
    max_count: integer;
    normal_protection: Single;
    energy_protection: Single;
    armor: integer;
  end;


  gitem_p = g_local_add.gitem_p;
  gitem_t = g_local_add.gitem_t;


// client data that stays across multiple level loads
  client_persistant_p = g_local_add.client_persistant_p;
  client_persistant_t = g_local_add.client_persistant_t;

// client data that stays across deathmatch respawns
  client_respawn_p = g_local_add.client_respawn_p;
  client_respawn_t = g_local_add.client_respawn_t;


// this structure is cleared on each PutClientInServer(),
// except for 'client->pers'
  gclient_p = g_local_add.gclient_p;
  gclient_t = g_local_add.gclient_t;
  gclient_at = array[0..MaxInt div sizeof(gclient_t)-1] of gclient_t;
  gclient_a = ^gclient_at;
  edict_t = g_local_add.edict_t;
  edict_p = g_local_add.edict_p;




//
// this structure is left intact through an entire game
// it should be initialized at dll load time, and read/written to
// the server.ssv file for savegames
//
  game_locals_p = ^game_locals_t;
  game_locals_t = record
    helpmessage1: array[0..511] of char;
    helpmessage2: array[0..511] of char;
    helpchanged: integer; // flash F1 icon if non 0, play sound
                          // and increment only if 1, 2, or 3

    clients: gclient_p;   // [maxclients]

    // can't store spawnpoint in level, because
    // it would get overwritten by the savegame restore
    spawnpoint: array[0..511] of char;   // needed for coop respawns // CAK - Fixed array of PCHAR!!!!!

    // store latched cvars here that we want to get at often
    maxclients: integer;
    maxentities: integer;

    // cross level triggers
    serverflags: integer;

    // items
    num_items: integer;

    autosaved: qboolean;
  end;

//
// this structure is cleared as each map is entered
// it is read/written to the level.sav file for savegames
//
  level_locals_p = ^level_locals_t;
  level_locals_t = record
    framenum: integer;
    time: Single;

    level_name: array[0..MAX_QPATH - 1] of char; // the descriptive name (Outer Base, etc)
    mapname: array[0..MAX_QPATH - 1] of char;   // the server name (base1, etc)
    nextmap: array[0..MAX_QPATH - 1] of char;  // go here when fraglimit is hit
{$ifdef CTF}
    forcemap: array[0..MAX_QPATH - 1] of char;  // go here
{$endif}

    // intermission state
    intermissiontime: Single; // time the intermission was started
    changemap: PChar;
    exitintermission: integer;
    intermission_origin: vec3_t;
    intermission_angle: vec3_t;

    sight_client: edict_p; // changed once each frame for coop games

    sight_entity: edict_p;
    sight_entity_framenum: integer;
    sound_entity: edict_p;
    sound_entity_framenum: integer;
    sound2_entity: edict_p;
    sound2_entity_framenum: integer;

    pic_health: integer;

    total_secrets: integer;
    found_secrets: integer;

    total_goals: integer;
    found_goals: integer;

    total_monsters: integer;
    killed_monsters: integer;

    current_entity: edict_p; // entity running from G_RunFrame
    body_que: integer; // dead bodies

    power_cubes: integer; // ugly necessity for coop
  end;

// spawn_temp_t is only used to hold entity field values that
// can be set from the editor, but aren't actualy present
// in edict_t during gameplay
  spawn_temp_p = ^spawn_temp_t;
  spawn_temp_t = record
    // world vars
    sky: PChar;
    skyrotate: Single;
    skyaxis: vec3_t;
    nextmap: PChar;

    lip,
    distance,
    height: integer;
    noise: PChar;
    pausetime: Single;
    item,
    gravity: PChar;

    minyaw,
    maxyaw,
    minpitch,
    maxpitch: Single;
  end;


  moveinfo_p = g_local_add.moveinfo_p;
  moveinfo_t = g_local_add.moveinfo_t;


  mframe_p = g_local_add.mframe_p;
  mframe_t = g_local_add.mframe_t;

  mmove_p = g_local_add.mmove_p;
  mmove_t = g_local_add.mmove_t;

  monsterinfo_p = g_local_add.monsterinfo_p;
  monsterinfo_t = g_local_add.monsterinfo_t;



//
// fields are needed for spawning from the entity string
// and saving / loading games
//
  fieldtype_p = ^fieldtype_t;
  fieldtype_t = (
    F_INT,
    F_FLOAT,
    F_LSTRING,   // string on disk, pointer in memory, TAG_LEVEL
    F_GSTRING,   // string on disk, pointer in memory, TAG_GAME
    F_VECTOR,
    F_ANGLEHACK,
    F_EDICT,   // index on disk, pointer in memory
    F_ITEM,   // index on disk, pointer in memory
    F_CLIENT,   // index on disk, pointer in memory
{$ifndef CTF}
    F_FUNCTION,
    F_MMOVE,
{$endif}
    F_IGNORE
  );

  field_p = ^field_t;
  field_t = record
    name: PChar;
    ofs: integer;
    _type: fieldtype_t;
    flags: integer;
  end;

//============================================================================




// the "gameversion" client command will print this plus compile date
const
  GAMEVERSION = 'baseq2';

// protocol bytes that can be directly added to messages
  svc_muzzleflash = 1;
  svc_muzzleflash2 = 2;
  svc_temp_entity = 3;
  svc_layout = 4;
  svc_inventory   = 5;
{$ifndef CTF}
  svc_stufftext   = 11;
{$endif}
//==================================================================

  // view pitching times
  DAMAGE_TIME = 0.5;
  FALL_TIME   = 0.3;


  // edict->spawnflags
  // these are set with checkboxes on each entity in the map editor
  SPAWNFLAG_NOT_EASY       = $00000100;
  SPAWNFLAG_NOT_MEDIUM     = $00000200;
  SPAWNFLAG_NOT_HARD       = $00000400;
  SPAWNFLAG_NOT_DEATHMATCH = $00000800;
  SPAWNFLAG_NOT_COOP       = $00001000;

  // edict->flags
  FL_FLY         = $00000001;
  FL_SWIM         = $00000002; // implied immunity to drowining
  FL_IMMUNE_LASER      = $00000004;
  FL_INWATER               = $00000008;
  FL_GODMODE               = $00000010;
  FL_NOTARGET              = $00000020;
  FL_IMMUNE_SLIME      = $00000040;
  FL_IMMUNE_LAVA      = $00000080;
  FL_PARTIALGROUND         = $00000100; // not all corners are valid
  FL_WATERJUMP             = $00000200; // player jumping out of water
  FL_TEAMSLAVE             = $00000400; // not the first on the team
  FL_NO_KNOCKBACK          = $00000800;
  FL_POWER_ARMOR           = $00001000; // power armor (if any) is active
  FL_RESPAWN               = $80000000; // used for item respawning

  FRAMETIME   = 0.1;

  // memory tags to allow dynamic memory to be cleaned up
  TAG_GAME = 765;           // clear when unloading the dll
  TAG_LEVEL = 766;          // clear when loading a new level
  MELEE_DISTANCE = 80;
  BODY_QUEUE_SIZE = 8;

  //deadflag
  DEAD_NO          = 0;
  DEAD_DYING       = 1;
  DEAD_DEAD        = 2;
  DEAD_RESPAWNABLE = 3;

  //range
  RANGE_MELEE   = 0;
  RANGE_NEAR   = 1;
  RANGE_MID   = 2;
  RANGE_FAR   = 3;

  //gib types
  GIB_ORGANIC   = 0;
  GIB_METALLIC   = 1;

  //monster ai flags
  AI_STAND_GROUND = $00000001;
  AI_TEMP_STAND_GROUND = $00000002;
  AI_SOUND_TARGET = $00000004;
  AI_LOST_SIGHT   = $00000008;
  AI_PURSUIT_LAST_SEEN = $00000010;
  AI_PURSUE_NEXT = $00000020;
  AI_PURSUE_TEMP = $00000040;
  AI_HOLD_FRAME   = $00000080;
  AI_GOOD_GUY = $00000100;
  AI_BRUTAL = $00000200;
  AI_NOSTEP = $00000400;
  AI_DUCKED = $00000800;
  AI_COMBAT_POINT = $00001000;
  AI_MEDIC = $00002000;
  AI_RESURRECTING = $00004000;

  //monster attack state
  AS_STRAIGHT   =   1;
  AS_SLIDING    =   2;
  AS_MELEE      =   3;
  AS_MISSILE    =   4;

  // armor types
  ARMOR_NONE    =   0;
  ARMOR_JACKET  =   1;
  ARMOR_COMBAT  =   2;
  ARMOR_BODY    =   3;
  ARMOR_SHARD   =   4;

  // power armor types
  POWER_ARMOR_NONE   = 0;
  POWER_ARMOR_SCREEN = 1;
  POWER_ARMOR_SHIELD = 2;

  // handedness values
  RIGHT_HANDED   = 0;
  LEFT_HANDED    = 1;
  CENTER_HANDED  = 2;


  // game.serverflags values
  SFL_CROSS_TRIGGER_1    = $00000001;
  SFL_CROSS_TRIGGER_2    = $00000002;
  SFL_CROSS_TRIGGER_3    = $00000004;
  SFL_CROSS_TRIGGER_4    = $00000008;
  SFL_CROSS_TRIGGER_5    = $00000010;
  SFL_CROSS_TRIGGER_6    = $00000020;
  SFL_CROSS_TRIGGER_7    = $00000040;
  SFL_CROSS_TRIGGER_8    = $00000080;
  SFL_CROSS_TRIGGER_MASK = $000000ff;


  // noise types for PlayerNoise
  PNOISE_SELF    = 0;
  PNOISE_WEAPON  = 1;
  PNOISE_IMPACT  = 2;



  // gitem_t->flags
  IT_WEAPON    = 1;   // use makes active weapon
  IT_AMMO      = 2;
  IT_ARMOR     = 4;
  IT_STAY_COOP = 8;
  IT_KEY       = 16;
  IT_POWERUP   = 32;

{$ifdef CTF}
//ZOID
  IT_TECH      = 64;
//ZOID
{$endif}


  // gitem_t->weapmodel for weapons indicates model index
  WEAP_BLASTER          = 1;
  WEAP_SHOTGUN          = 2;
  WEAP_SUPERSHOTGUN    = 3;
  WEAP_MACHINEGUN      = 4;
  WEAP_CHAINGUN          = 5;
  WEAP_GRENADES          = 6;
  WEAP_GRENADELAUNCHER = 7;
  WEAP_ROCKETLAUNCHER  = 8;
  WEAP_HYPERBLASTER    = 9;
  WEAP_RAILGUN          = 10;
  WEAP_BFG          = 11;
{$ifdef CTF}
  WEAP_GRAPPLE         = 12;
{$endif}


  // item spawnflags
  ITEM_TRIGGER_SPAWN  = $00000001;
  ITEM_NO_TOUCH         = $00000002;
  // 6 bits reserved for editor flags
  // 8 bits used as power cube id bits for coop games
  DROPPED_ITEM         = $00010000;
  DROPPED_PLAYER_ITEM = $00020000;
  ITEM_TARGETS_USED   = $00040000;

  //
  // fields are needed for spawning from the entity string
  // and saving / loading games
  //
  FFL_SPAWNTEMP   = 1;
{$ifndef CTF}
  FFL_NOSPAWN   = 2;
{$endif}

  // means of death
  MOD_UNKNOWN      = 0;
  MOD_BLASTER      = 1;
  MOD_SHOTGUN      = 2;
  MOD_SSHOTGUN      = 3;
  MOD_MACHINEGUN   = 4;
  MOD_CHAINGUN      = 5;
  MOD_GRENADE      = 6;
  MOD_G_SPLASH      = 7;
  MOD_ROCKET      = 8;
  MOD_R_SPLASH      = 9;
  MOD_HYPERBLASTER = 10;
  MOD_RAILGUN      = 11;
  MOD_BFG_LASER      = 12;
  MOD_BFG_BLAST      = 13;
  MOD_BFG_EFFECT   = 14;
  MOD_HANDGRENADE  = 15;
  MOD_HG_SPLASH      = 16;
  MOD_WATER      = 17;
  MOD_SLIME      = 18;
  MOD_LAVA      = 19;
  MOD_CRUSH      = 20;
  MOD_TELEFRAG      = 21;
  MOD_FALLING      = 22;
  MOD_SUICIDE      = 23;
  MOD_HELD_GRENADE = 24;
  MOD_EXPLOSIVE      = 25;
  MOD_BARREL      = 26;
  MOD_BOMB      = 27;
  MOD_EXIT      = 28;
  MOD_SPLASH      = 29;
  MOD_TARGET_LASER = 30;
  MOD_TRIGGER_HURT = 31;
  MOD_HIT      = 32;
  MOD_TARGET_BLASTER=33;
{$ifdef CTF}
  MOD_GRAPPLE      =34;
{$endif}
  MOD_FRIENDLY_FIRE= $8000000;


  // damage flags
  DAMAGE_RADIUS          = $00000001; // damage was indirect
  DAMAGE_NO_ARMOR      = $00000002; // armour does not protect from this damage
  DAMAGE_ENERGY          = $00000004; // damage is from an energy based weapon
  DAMAGE_NO_KNOCKBACK  = $00000008; // do not affect velocity, just view angles
  DAMAGE_BULLET          = $00000010; // damage is from a bullet (used for ricochets)
  DAMAGE_NO_PROTECTION = $00000020; // armor, shields, invulnerability, and godmode have no effect

  DEFAULT_BULLET_HSPREAD = 300;
  DEFAULT_BULLET_VSPREAD = 500;
  DEFAULT_SHOTGUN_HSPREAD = 1000;
  DEFAULT_SHOTGUN_VSPREAD = 500;
  DEFAULT_DEATHMATCH_SHOTGUN_COUNT = 12;
  DEFAULT_SHOTGUN_COUNT = 12;
  DEFAULT_SSHOTGUN_COUNT = 20;


  //============================================================================

  // client_t->anim_priority
  ANIM_BASIC   = 0;      // stand / run
  ANIM_WAVE    = 1;
  ANIM_JUMP    = 2;
  ANIM_PAIN    = 3;
  ANIM_ATTACK  = 4;
  ANIM_DEATH   = 5;
  ANIM_REVERSE = 6;



{* CAK - These 4 macros...

  #define FOFS(x) (int)&(((edict_t *)0)->x)
  #define STOFS(x) (int)&(((spawn_temp_t *)0)->x)
  #define LLOFS(x) (int)&(((level_locals_t *)0)->x)
  #define CLOFS(x) (int)&(((gclient_t *)0)->x)

are now hundreds of functions in g_save. Instead of:

  FOFS(classname)

use:

  FOFS_classname

It is defined as:

  function FOFS_classname: Integer; begin Result:=Integer(@edict_p(Ptr(0)).classname); end;
}


function _random: Single; // CAK - MACROS
function crandom: Single;



implementation

Uses
  SysUtils; // CAK - Exception handling only (for assertions below)

function _random: Single; // ((rand () & 0x7fff) / ((float)0x7fff))
begin
  Result:= System.Random($8000) / $7fff;
end;

function crandom: Single;
begin
  Result:= 2.0 * (_random - 0.5);
end;

initialization
// Check the size of types defined in g_local.h
{$ifndef CTF}
  Assert(sizeof(damage_t)=4);
  Assert(sizeof(weaponstate_t)=4);
  Assert(sizeof(ammo_t)=4);
  Assert(sizeof(movetype_t)=4);
  Assert(sizeof(gitem_armor_t)=20);
  Assert(sizeof(gitem_t)=76);
  Assert(sizeof(game_locals_t)=1564);
  Assert(sizeof(level_locals_t)=304);
  Assert(sizeof(spawn_temp_t)=68);
  Assert(sizeof(moveinfo_t)=120);
  Assert(sizeof(mframe_t)=12);
  Assert(sizeof(mmove_t)=16);
  Assert(sizeof(monsterinfo_t)=120);
  Assert(sizeof(fieldtype_t)=4);
  Assert(sizeof(field_t)=16);
  Assert(sizeof(client_persistant_t)=1628);
  Assert(sizeof(client_respawn_t)=1652);
{$else}
  Assert(sizeof(damage_t)=4);
  Assert(sizeof(weaponstate_t)=4);
  Assert(sizeof(ammo_t)=4);
  Assert(sizeof(movetype_t)=4);
  Assert(sizeof(gitem_armor_t)=20);
  Assert(sizeof(gitem_t)=76);
  Assert(sizeof(game_locals_t)=1564);
  Assert(sizeof(level_locals_t)=368);
  Assert(sizeof(spawn_temp_t)=68);
  Assert(sizeof(moveinfo_t)=120);
  Assert(sizeof(mframe_t)=12);
  Assert(sizeof(mmove_t)=16);
  Assert(sizeof(monsterinfo_t)=120);
  Assert(sizeof(fieldtype_t)=4);
  Assert(sizeof(field_t)=16);
  Assert(sizeof(client_persistant_t)=1616);
  Assert(sizeof(client_respawn_t)=1692);
  Assert(sizeof(gclient_s)=3872);
  Assert(sizeof(edict_s)=892);
{$endif}
end.






