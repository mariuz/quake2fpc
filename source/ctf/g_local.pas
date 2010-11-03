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

{$ifdef CTF}
//ZOID
//uses p_menu;
//ZOID
{$endif}

// CAK - TAKEN FROM q_shared.h
const
  MAX_QPATH = 64; // max length of a quake game pathname
  MAX_INFO_STRING = 512;
  MAX_ITEMS = 256;
  MAX_STATS = 32;
// CAK - TAKEN FROM game.h
  MAX_ENT_CLUSTERS = 16;

type
// TAKEN FROM q_shared.h
  qboolean = LongBool;
  PQBoolean = ^qboolean;
  TQBooleanArray = array[0..MaxInt div sizeof(qboolean)-1] of qboolean;
  PQBooleanArray = ^TQBooleanArray;

  vec_t = Single;
  vec3_t = array[0..2] of vec_t;
  vec5_t = array[0..4] of vec_t;

  vec_p = ^vec_t;
  vec3_p = ^vec3_t;
  vec5_p = ^vec5_t;

  pvec_t = vec_p;
  pvec3_t = vec3_p;
  pvec5_t = vec5_p;

  TVec = vec_t;
  PVec = vec_p;
  TVec3 = vec3_t;
  PVec3 = vec3_p;
  TVec5 = vec5_t;
  PVec5 = vec5_p;

  vec_at = Array[0..MaxInt div sizeof(vec_t)-1] of vec_t;
  vec_a = ^vec_at;
  vec3_at = Array[0..MaxInt div sizeof(vec3_t)-1] of vec3_t;
  vec3_a = ^vec3_at;
  vec5_at = Array[0..MaxInt div sizeof(vec5_t)-1] of vec5_t;
  vec5_a = ^vec5_at;
  TVecArray = vec_at;
  PVecArray = vec_a;
  TVec3Array = vec3_at;
  PVec3Array = vec3_a;
  TVec5Array = vec5_at;
  PVec5Array = vec5_a;


// NOT TAKEN FROM ANYWHERE, NORMAL g_local.h
  damage_p = ^damage_t;
  pdamage_t = damage_p;
  damage_t = (
    DAMAGE_NO,
    DAMAGE_YES,   // will take damage if hit
    DAMAGE_AIM   // auto targeting recognizes this
  );
  TDamage = damage_t;
  PDamage = damage_p;
  damage_at = array[0..MaxInt div SizeOf(damage_t)-1] of damage_t;
  damage_a = ^damage_at;
  TDamageArray = damage_at;
  PDamageArray = ^TDamageArray;

  weaponstate_p = ^weaponstate_t;
  pweaponstate_t = weaponstate_p;
  weaponstate_t = (
    WEAPON_READY,
    WEAPON_ACTIVATING,
    WEAPON_DROPPING,
    WEAPON_FIRING
  );
  TWeaponState = weaponstate_t;
  PWeaponState = weaponstate_p;
  weaponstate_at = array[0..MaxInt div SizeOf(weaponstate_t)-1] of weaponstate_t;
  weaponstate_a = ^weaponstate_at;
  TWeaponStateArray = weaponstate_at;
  PWeaponStateArray = weaponstate_a;

  ammo_p = ^ammo_t;
  pammo_t = ammo_p;
  ammo_t = (
    AMMO_BULLETS,
    AMMO_SHELLS,
    AMMO_ROCKETS,
    AMMO_GRENADES,
    AMMO_CELLS,
    AMMO_SLUGS
  );
  TAmmo = ammo_t;
  PAmmo = ammo_p;
  ammo_at = array[0..MaxInt div SizeOf(ammo_t)-1] of ammo_t;
  ammo_a = ^ammo_at;
  TAmmoArray = ammo_at;
  PAmmoArray = ammo_a;

// edict->movetype values
  movetype_p = ^movetype_t;
  pmovetype_t = movetype_p;
  movetype_t = (
    MOVETYPE_NONE,       // never moves
    MOVETYPE_NOCLIP,     // origin and angles change with no interaction
    MOVETYPE_PUSH,       // no clip to world, push on box contact
    MOVETYPE_STOP,       // no clip to world, stops on box contact

    MOVETYPE_WALK,    // gravity
    MOVETYPE_STEP,    // gravity, special edge handling
    MOVETYPE_FLY,
    MOVETYPE_TOSS,    // gravity
    MOVETYPE_FLYMISSILE, // extra size to monsters
    MOVETYPE_BOUNCE
  );
  TMoveType = movetype_t;
  PMoveType = movetype_p;
  movetype_at = array[0..MaxInt div SizeOf(movetype_t)-1] of movetype_t;
  movetype_a = ^movetype_at;
  TMoveTypeArray = movetype_at;
  PMoveTypeArray = movetype_a;


  gitem_armor_p = ^gitem_armor_t;
  pgitem_armor_t = gitem_armor_p;
  gitem_armor_t = record
    base_count: integer;
    max_count: integer;
    normal_protection: Single;
    energy_protection: Single;
    armor: integer;
  end;
  TGItemArmor = gitem_armor_t;
  PGItemArmor = gitem_armor_p;
  gitem_armor_at = array[0..MaxInt div SizeOf(gitem_armor_t)-1] of gitem_armor_t;
  gitem_armor_a = ^gitem_armor_at;
  TGItemArmorArray = gitem_armor_at;
  PGItemArmorArray = ^TGItemArmorArray;

  edict_p = ^edict_s;
  gitem_p = ^gitem_t;

  BoolFunc_2edict_s = function(ent, other: edict_p): qboolean; cdecl;
  Proc_edit_s__gitem_s = procedure(ent: edict_p; item: gitem_p); cdecl;
  Proc_edit_s = procedure(ent: edict_p); cdecl;

  pgitem_s = gitem_p;
  gitem_s = record
    classname: PChar;  // spawning name
    pickup: BoolFunc_2edict_s;
    use: Proc_edit_s__gitem_s;
    drop: Proc_edit_s__gitem_s;
    weaponthink: Proc_edit_s;
    pickup_sound: PChar;
    world_model: PChar;
    world_model_flags: integer;
    view_model: PChar;

    // client side info
    icon: PChar;
    pickup_name: PChar;   // for printing on pickup
    count_width: integer; // number of digits to display by icon

    quantity: integer;   // for ammo how much, for weapons how much is used per shot
    ammo: PChar;    // for weapons
    flags: integer;   // IT_* flags

    weapmodel: integer;   // weapon model index (for weapons)

    info: Pointer;
    tag: integer;

    precaches: PChar; // string of all models, sounds, and images this item will use
  end;
  gitem_t = gitem_s;
  pgitem_t = gitem_p;
  TGItem = gitem_t;
  PGItem = gitem_p;
  gitem_at = array[0..MaxInt div SizeOf(gitem_t)-1] of gitem_t;
  gitem_a = ^gitem_at;
  TGItemArray = gitem_at;
  PGItemArray = gitem_a;


  gclient_p = ^gclient_t;
//
// this structure is left intact through an entire game
// it should be initialized at dll load time, and read/written to
// the server.ssv file for savegames
//
  game_locals_p = ^game_locals_t;
  pgame_locals_t = game_locals_p;
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
  TGameLocals = game_locals_t;
  PGameLocals = game_locals_p;
  game_locals_at = array[0..MaxInt div SizeOf(game_locals_t)-1] of game_locals_t;
  game_locals_a = ^game_locals_at;
  TGameLocalsArray = game_locals_at;
  PGameLocalsArray = game_locals_a;

//
// this structure is cleared as each map is entered
// it is read/written to the level.sav file for savegames
//
  level_locals_p = ^level_locals_t;
  plevel_locals_t = level_locals_p;
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
  TLevelLocals = level_locals_t;
  PLevelLocals = level_locals_p;
  level_locals_at = array[0..MaxInt div sizeof(level_locals_t)-1] of level_locals_t;
  level_locals_a = ^level_locals_at;
  TLevelLocalsArray = level_locals_at;
  PLevelLocalsArray = level_locals_a;

// spawn_temp_t is only used to hold entity field values that
// can be set from the editor, but aren't actualy present
// in edict_t during gameplay
  spawn_temp_p = ^spawn_temp_t;
  pspawn_temp_t = spawn_temp_p;
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
  TSpawnTemp = spawn_temp_t;
  PSpawnTemp = spawn_temp_p;
  spawn_temp_at = array[0..MaxInt div sizeof(spawn_temp_t)-1] of spawn_temp_t;
  spawn_temp_a = ^spawn_temp_at;
  TSpawnTempArray = spawn_temp_at;
  PSpawnTempArray = spawn_temp_a;

  Proc_Pedictt = procedure(x: edict_p); cdecl;

  moveinfo_p = ^moveinfo_t;
  pmoveinfo_t = moveinfo_p;
  moveinfo_t = record
    // fixed data
    start_origin,
    start_angles,
    end_origin,
    end_angles: vec3_t;

    sound_start,
    sound_middle,
    sound_end: integer;

    accel,
    speed,
    decel,
    distance: Single;

    wait: Single;

    // state data
    state: integer;
    dir: vec3_t;
    current_speed,
    move_speed,
    next_speed,
    remaining_distance,
    decel_distance: Single;
    endfunc: Proc_Pedictt;
  end;
  TMoveInfo = moveinfo_t;
  PMoveInfo = moveinfo_p;
  moveinfo_at = array[0..MaxInt div sizeof(moveinfo_t)-1] of moveinfo_t;
  moveinfo_a = ^moveinfo_at;
  TMoveInfoArray = moveinfo_at;
  PMoveInfoArray = moveinfo_a;

  Proc_Pedictt_single = procedure(self: edict_p; dist: single); cdecl;

  mframe_p = ^mframe_t;
  pmframe_t = mframe_p;
  mframe_t = record
    aifunc: Proc_Pedictt_single;
    dist: Single;
    thinkfunc: Proc_Pedictt;
  end;
  TMFrame = mframe_t;
  PMFrame = mframe_p;
  mframe_at = array[0..MaxInt div sizeof(mframe_t)-1] of mframe_t;
  mframe_a = ^mframe_at;
  TMFrameArray = mframe_at;
  PMFrameArray = mframe_a;

  mmove_p = ^mmove_t;
  pmmove_t = mmove_p;
  mmove_t = record
    firstframe,
    lastframe: integer;
    frame: mframe_p;
    endfunc: Proc_Pedictt;
  end;
  TMMove = mmove_t;
  PMMove = mmove_p;
  mmove_at = array[0..MaxInt div sizeof(mmove_t)-1] of mmove_t;
  mmove_a = ^mmove_at;
  TMMoveArray = mmove_at;
  PMMoveArray = mmove_a;

  Boolfunc_Pedictt = function(self: edict_p): qboolean; cdecl;
  Proc_2Pedictt_single = procedure(self, other: edict_p; eta: single); cdecl;
  Proc_2Pedictt = procedure(self, other: edict_p); cdecl;

  monsterinfo_p = ^monsterinfo_t;
  pmonsterinfo_t = monsterinfo_p;
  monsterinfo_t = record
    currentmove: mmove_p;
    aiflags,
    nextframe: integer;
    scale: Single;

    stand,
    idle,
    search,
    walk,
    run: Proc_Pedictt;
    dodge: Proc_2Pedictt_single;
    attack: Proc_Pedictt;
    melee: Proc_Pedictt;
    sight: Proc_2Pedictt;
    checkattack: Boolfunc_Pedictt;

    pausetime,
    attack_finished: Single; // CAK - FIXED!!! WAS IN WRONG ORDER!!!!! NAUGHTY!!!

    saved_goal: vec3_t;      // CAK - THIS WHOLE STRUCT WAS WRONG!!!!!!
    search_time,
    trail_time: Single;
    last_sighting: vec3_t;
    attack_state,
    lefty: integer;
    idle_time: Single;
    linkcount: integer;

    power_armor_type,
    power_armor_power: integer;
  end;
  TMonsterInfo = monsterinfo_t;
  PMonsterInfo = monsterinfo_p;
  monsterinfo_at = array[0..MaxInt div sizeof(monsterinfo_t)-1] of monsterinfo_t;
  monsterinfo_a = ^monsterinfo_at;
  TMonsterInfoArray = monsterinfo_at;
  PMonsterInfoArray = monsterinfo_a;




//
// fields are needed for spawning from the entity string
// and saving / loading games
//
  fieldtype_p = ^fieldtype_t;
  pfieldtype_t = fieldtype_p;
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
  TFieldType = fieldtype_t;
  PFieldType = fieldtype_p;
  fieldtype_at = array[0..MaxInt div sizeof(fieldtype_t)-1] of fieldtype_t;
  fieldtype_a = ^fieldtype_at;
  TFieldTypeArray = fieldtype_at;
  PFieldTypeArray = fieldtype_a;

  field_p = ^field_t;
  pfield_t = field_p;
  field_t = record
    name: PChar;
    ofs: integer;
    _type: fieldtype_t;
    flags: integer;
  end;
  TField = field_t;
  PField = field_p;
  field_at = array[0..MaxInt div sizeof(field_t)-1] of field_t;
  field_a = ^field_at;
  TFieldArray = field_at;
  PFieldArray = field_a;

//============================================================================

// client data that stays across multiple level loads
  client_persistant_p = ^client_persistant_t;
  pclient_persistant_t = client_persistant_p;
  client_persistant_t = record
    userinfo: array[0..MAX_INFO_STRING -1] of char;
    netname: array[0..15] of char;
    hand: integer;

    connected: qboolean; // a loadgame will leave valid entities that
                         // just don't have a connection yet

    // values saved and restored from edicts when changing levels
    health,
    max_health,
    savedFlags: integer;

    selected_item: integer;
    inventory: array[0..MAX_ITEMS-1] of integer;

    // ammo capacities
    max_bullets,
    max_shells,
    max_rockets,
    max_grenades,
    max_cells,
    max_slugs: integer;

    weapon,
    lastweapon: gitem_p;

    power_cubes,     // used for tracking the cubes in coop games
    score: integer;  // for calculating total unit score in coop games

{$ifndef CTF}
    game_helpchanged,
    helpchanged: integer;

    spectator: qboolean; // client is a spectator
{$endif}
  end;
  TClientPersistant = client_persistant_t;
  PClientPersistant = client_persistant_p;
  client_persistant_at = array[0..MaxInt div sizeof(client_persistant_t)-1] of client_persistant_t;
  client_persistant_a = ^client_persistant_at;

{$ifdef CTF}
  // TAKEN FROM g_ctf.h
  ghost_p = ^ghost_t;
  pghost_s = ghost_p;
  ghost_s = record
    netname: Array[0..15] of char;
    number: Integer;

    // stats
    deaths,
    kills,
    caps,
    basedef,
    carrierdef: Integer;

    code: Integer; // ghost code
    team: Integer; // team
    score: Integer; // frags at time of disconnect
    ent: edict_p;
  end;
  ghost_t = ghost_s;
  pghost_t = ghost_p;
  ghost_at = array[0..0] of ghost_t;
  ghost_a = ^ghost_at;
  TGhost = ghost_t;
  PGhost = ghost_p;
  TGhostArray = ghost_at;
  PGhostArray = ghost_a;
{$endif}

// client data that stays across deathmatch respawns
  client_respawn_p = ^client_respawn_t;
  pclient_respawn_t = client_respawn_p;
  client_respawn_t = record
    coop_respawn: client_persistant_t; // what to set client->pers to on a respawn
    enterframe,        // level.framenum the client entered the game
    score: integer;  // frags, etc
{$ifdef CTF}
//ZOID
    ctf_team, // CTF team
    ctf_state: Integer;
    ctf_lasthurtcarrier,
    ctf_lastreturnedflag,
    ctf_flagsince,
    ctf_lastfraggedcarrier: Single;
    id_state: qboolean;
    lastidtime: Single;
    voted, // for elections
    ready,
    admin: qboolean;
    ghost: ghost_p; // for ghost codes
//ZOID
{$endif}
    cmd_angles: vec3_t;  // angles sent over in the last command

{$ifndef CTF}
    spectator: qboolean; // client is a spectator
{$else}
    game_helpchanged: Integer;
    helpchanged: Integer;
{$endif}
  end;
  TClientRespawn = client_respawn_t;
  PClientRespawn = client_respawn_p;
  client_respawn_at = array[0..MaxInt div sizeof(client_respawn_t)-1] of client_respawn_t;
  client_respawn_a = ^client_respawn_at;
  TClientRespawnArray = client_respawn_at;
  PClientRespawnArray = client_respawn_a;


// CAK - TAKEN FROM q_shared.h
// pmove_state_t is the information necessary for client side movement
// prediction
  pmtype_p = ^pmtype_t;
  ppmtype_t = pmtype_p;
  pmtype_t = (
    // can accelerate and turn
    PM_NORMAL,
    PM_SPECTATOR,
    // no acceleration or turning
    PM_DEAD,
    PM_GIB, // different bounding box
    PM_FREEZE
  );
  TPMType = pmtype_t;
  PPMType = pmtype_p;
  pmtype_at = array[0..MaxInt div sizeof(pmtype_t)-1] of pmtype_t;
  pmtype_a = ^pmtype_at;
  TPMTypeArray = pmtype_at;
  PPMTypeArray = pmtype_a;


  // CAK - TAKEN FROM q_shared.h
  pmove_state_p = ^pmove_state_t;
  ppmove_state_t = pmove_state_p;
  pmove_state_t = record
    pm_type: pmtype_t;

    origin: array[0..2] of smallint; // 12.3
    velocity: array[0..2] of smallint; // 12.3
    pm_flags: byte; // ducked, jump_held, etc
    pm_time: byte; // each unit = 8 ms
    gravity: smallint;
    delta_angles: array[0..2] of smallint; // add to command angles to get view direction
                                           // changed by spawns, rotating objects, and teleporters
  end;
  TPMoveState = pmove_state_t;
  PPMoveState = pmove_state_p;
  pmove_state_at = array[0..MaxInt div sizeof(pmove_state_t)-1] of pmove_state_t;
  pmove_state_a = ^pmove_state_at;
  TPMoveStateArray = pmove_state_at;
  PPMoveStateArray = pmove_state_a;

  // CAK - TAKEN FROM q_shared.h
  player_state_p = ^player_state_t;
  pplayer_state_t = player_state_p;
  player_state_t = record
    pmove: pmove_state_t; // for prediction

    // these fields do not need to be communicated bit-precise

    viewangles: vec3_t; // for fixed views
    viewoffset: vec3_t; // add to pmovestate->origin
    kick_angles: vec3_t; // add to view direction to get render angles
           // set by weapon kicks, pain effects, etc
    gunangles: vec3_t;
    gunoffset: vec3_t;
    gunindex: Integer;
    gunframe: Integer;

    blend: Array[0..3] of single; // rgba full screen effect

    fov: single; // horizontal field of view

    rdflags: Integer; // refdef flags

    stats: Array[0..MAX_STATS-1] of smallint; // fast status bar updates
  end;
  TPlayerState = player_state_t;
  PPlayerState = player_state_p;
  player_state_at = array[0..MaxInt div sizeof(player_state_t)-1] of player_state_t;
  player_state_a = ^player_state_at;
  TPlayerStateArray = player_state_at;
  PPlayerStateArray = player_state_a;

{$ifdef CTF}
//TAKEN FROM ctf\p_menu.h
  pmenu_p = ^pmenu_t;

  pmenuhnd_p = ^pmenuhnd_t;
  pmenuhnd_s = record
    entries: pmenu_p;
    //TODO: This is giving me problems: struct pmenu_s *entries;
    //I think that it should be an array of pmenu_s
    cur: Integer;
    num: Integer;
    arg: Pointer;
  end;
  pmenuhnd_t = pmenuhnd_s;
  pmenuhnd_at = Array[0..0] of pmenuhnd_t;
  pmenuhnd_a = ^pmenuhnd_at;
  TPMenuHnd = pmenuhnd_t;
  PPMenuHnd = pmenuhnd_p;
  TPMenuHndArray = pmenuhnd_at;
  PPMenuHndArray = pmenuhnd_a;

  SelectFunc_t = procedure(ent: edict_p; hnd: pmenuhnd_p); cdecl;

  ppmenu_s = pmenu_p;
  pmenu_s = record
    text: PChar;
    align: Integer;
    SelectFunc: SelectFunc_t;
  end;
  pmenu_t = pmenu_s;
  pmenu_at = Array[0..0] of pmenu_t;
  pmenu_a = ^pmenu_at;
  TPMenu = pmenu_t;
  PPMenu = pmenu_p;
  TPMenuArray = pmenu_at;
  PPMenuArray = pmenu_a;
{$endif}

// this structure is cleared on each PutClientInServer(),
// except for 'client->pers'
  pgclient_s = gclient_p;
  gclient_s = record
    // known to server
    ps: player_state_t;   // communicated by server to clients
    ping: integer;

    // private to game
    pers: client_persistant_t;
    resp: client_respawn_t;
    old_pmove: pmove_state_t; // for detecting out-of-pmove changes

    showscores,      // set layout stat
{$ifdef CTF}
//ZOID
    inmenu: qboolean; // in menu
    menu: pmenuhnd_p; // current menu
//ZOID
{$endif}
    showinventory, // set layout stat
    showhelp,
    showhelpicon: qboolean;

    ammo_index: integer;

    buttons,
    oldbuttons,
    latched_buttons: integer;

    weapon_thunk: qboolean;

    newweapon: gitem_p;

    // sum up damage over an entire frame, so
    // shotgun blasts give a single big kick
    damage_armor,      // damage absorbed by armor
    damage_parmor,      // damage absorbed by power armor
    damage_blood,      // damage taken out of health
    damage_knockback: integer;   // impact damage
    damage_from: vec3_t;          // origin for vector calculation

    killer_yaw: Single;   // when dead, look at killer

    weaponstate: weaponstate_t;
    kick_angles: vec3_t;  // weapon kicks
    kick_origin: vec3_t;
    v_dmg_roll, v_dmg_pitch, v_dmg_time, // damage kicks
    fall_time, fall_value,  // for view drop on fall
    damage_alpha,
    bonus_alpha: single;
    damage_blend,
    v_angle: vec3_t; // aiming direction
    bobtime: Single;   // so off-ground doesn't change it
    oldviewangles: vec3_t;
    oldvelocity: vec3_t;

    next_drown_time: Single;
    old_waterlevel,
    breather_sound: integer;

    machinegun_shots: integer;   // for weapon raising

    // animation vars
    anim_end,
    anim_priority: integer;
    anim_duck,
    anim_run: qboolean;

    // powerup timers
    quad_framenum,
    invincible_framenum,
    breather_framenum,
    enviro_framenum: single;

    grenade_blew_up: qboolean;
    grenade_time: single;
    silencer_shots,
    weapon_sound: integer;

    pickup_msg_time: Single;

    flood_locktill: single;  // locked from talking
    flood_when: array[0..9] of single;   // when messages were said
    flood_whenhead: integer;  // head pointer for when said

    respawn_time: single;  // can respawn when time > this


{$ifdef CTF}
//ZOID
    ctf_grapple: pointer; // entity of grapple
    ctf_grapplestate: integer; // true if pulling
    ctf_grapplereleasetime: Single; // time of grapple release
    ctf_regentime: Single;          // regen tech
    ctf_techsndtime: Single;
    ctf_lasttechmsg: Single;
{$endif}
    chase_target: edict_p;  // player we are chasing
    update_chase: qboolean; // need to update chase info?
{$ifdef CTF}
    menutime: single; // time to update menu
    menudirty: qboolean;
//ZOID
{$endif}
  end;
  gclient_t = gclient_s;
  _gclient_s = gclient_s;
  pgclient_t = gclient_p;
  p_gclient_s = gclient_p;
  TGClient = gclient_t;
  PGClient = gclient_p;
  gclient_at = array[0..MaxInt div sizeof(gclient_t)-1] of gclient_t;
  gclient_a = ^gclient_at;
  TGClientArray = gclient_at;
  PGClientArray = gclient_a;

// CAK - TAKEN FROM q_shared.h
// entity_state_t->event values
// ertity events are for effects that take place reletive
// to an existing entities origin.  Very network efficient.
// All muzzle flashes really should be converted to events...
//  entity_event_p = g_local.entity_event_p;
//  entity_event_t = g_local.entity_event_t;
  entity_event_p = ^entity_event_t;
  entity_event_t = (
    EV_NONE,
    EV_ITEM_RESPAWN,
    EV_FOOTSTEP,
    EV_FALLSHORT,
    EV_FALL,
    EV_FALLFAR,
    EV_PLAYER_TELEPORT,
    EV_OTHER_TELEPORT
  );

// CAK - TAKEN FROM q_shared.h
// entity_state_t is the information conveyed from the server
// in an update message about entities that the client will
// need to render in some way
  entity_state_p = ^entity_state_t;
  pentity_state_s = entity_state_p;
  entity_state_s = record
    number: integer; // edict index

    origin: vec3_t;
    angles: vec3_t;
    old_origin: vec3_t; // for lerping
    modelindex: Integer;
    modelindex2,modelindex3,modelindex4: Integer; // weapons, CTF flags, etc
    frame: Integer;
    skinnum: Integer;
    effects: Cardinal; // PGM - we're filling it, so it needs to be unsigned
    renderfx: Integer;
    solid: Integer; // for client side prediction, 8*(bits 0-4) is x/y radius
                    // 8*(bits 5-9) is z down distance, 8(bits10-15) is z up
                    // gi.linkentity sets this properly
    sound: Integer;  // for looping sounds, to guarantee shutoff
    event: entity_event_t; // CAK - was int
                    // impulse events -- muzzle flashes, footsteps, etc
                    // events only go out for a single frame, they
                    // are automatically cleared each frame
  end;
  entity_state_t = entity_state_s;
  pentity_state_t = entity_state_p;
  TEntityState = entity_state_t;
  PEntityState = entity_state_p;
  entity_state_at = array[0..MaxInt div sizeof(entity_state_t)-1] of entity_state_t;
  entity_state_a = ^entity_state_at;
  TEntityStateArray = entity_state_at;
  PEntityStateArray = entity_state_a;

// CAK - TAKEN FROM game.h
// link_t is only used for entity area links now
  link_p = ^link_t;
  plink_s = link_p;
  link_s = record
    prev, next : link_p;
  end;
  link_t = link_s;
  plink_t = link_p;
  TLink = link_t;
  PLink = link_p;
  link_at = array[0..MaxInt div sizeof(link_t)-1] of link_t;
  link_a = ^link_at;
  TLinkArray = link_at;
  PLinkArray = link_a;

// CAK - TAKEN FROM game.h
// edict->solid values
  solid_p = ^solid_t;
  psolid_t = solid_p;
  solid_t = (
    SOLID_NOT,         // no interaction with other objects
    SOLID_TRIGGER,      // only touch when inside, after moving
    SOLID_BBOX,         // touch on edge
    SOLID_BSP         // bsp clip, touch on edge
  );
  TSolid = solid_t;
  PSolid = solid_p;
  solid_at = array[0..MaxInt div sizeof(solid_t)-1] of solid_t;
  solid_a = ^solid_at;
  TSolidArray = solid_at;
  PSolidArray = solid_a;

// CAK - TAKEN FROM q_shared.h
// plane_t structure
// !!!  if this is changed, it must be changed in asm code too !!!
  cplane_p = ^cplane_t;
  pcplane_s = cplane_p;
  cplane_s = record
    normal: vec3_t;
    dist: single;
    _type: byte; // for fast side tests
    signbits: byte; // signx + (signyshl1) + (signzshl1)
    pad: array[0..1] of byte;
  end;
  cplane_t = cplane_s;
  pcplane_t = cplane_p;
  TCPlane = cplane_t;
  PCPlane = cplane_p;
  cplane_at = array[0..MaxInt div sizeof(cplane_t)-1] of cplane_t;
  cplane_a = ^cplane_at;
  TCPlaneArray = cplane_at;
  PCPlaneArray = cplane_a;

// CAK - TAKEN FROM q_shared.h
  csurface_p = ^csurface_t;
  pcsurface_s = csurface_p;
  csurface_s = record
    name: array[0..15] of char;
    flags: Integer;
    value: Integer;
  end;
  csurface_t = csurface_s;
  pcsurface_t = csurface_p;
  TCSurface = csurface_t;
  PCSurface = csurface_p;
  csurface_at = array[0..MaxInt div sizeof(csurface_t)-1] of csurface_t;
  csurface_a = ^csurface_at;
  TCSurfaceArray = csurface_at;
  PCSurfaceArray = csurface_a;


  Proc_2edictt_cplanet_csurfacet = Procedure(self, other: edict_p;
                                                  plane: cplane_p; surf: csurface_p); cdecl;
  Proc_3edictt = Procedure (self, other, activator: edict_p); cdecl;
  Proc_2edictt_single_int = Procedure(self, other: edict_p;
                                          kick: single; damage: integer); cdecl;
  Proc_3edictt_int_vec3t = Procedure(self, inflictor, attacker: edict_p;
                                          damage: integer; point: vec3_t); cdecl;

  pedict_s = edict_p;
  edict_s = record
    s: entity_state_t;
    client: gclient_p;   // NULL if not a player
                        // the server expects the first part
                        // of gclient_s to be a player_state_t
                        // but the rest of it is opaque

    inuse: qboolean;
    linkcount: integer;

    // FIXME: move these fields to a server private sv_entity_t
    area: link_t; // linked to a division node or leaf

    num_clusters: integer;      // if -1, use headnode instead
    clusternums: array[0..MAX_ENT_CLUSTERS - 1] of integer;
    headnode: integer;         // unused if num_clusters != -1
    areanum, areanum2: integer;

    //================================

    svflags :integer;
    mins, maxs: vec3_t;
    absmin, absmax, size: vec3_t;
    solid: solid_t;
    clipmask: integer;
    owner: edict_p;


    // DO NOT MODIFY ANYTHING ABOVE THIS, THE SERVER
    // EXPECTS THE FIELDS IN THAT ORDER!

    //================================
    movetype: movetype_t; // CAK - was Integer
    flags: integer;

    model: PChar;
    freetime: single; // sv.time when the object was freed

    //
    // only used locally in game, not by server
    //
    _message,
    classname: Pchar;
    spawnflags: integer;

    timestamp: Single;

    angle: Single; // set in qe3, -1 = up, -2 = down
    target,
    targetname,
    killtarget,
    team,
    pathtarget,
    deathtarget,
    combattarget: PChar;
    target_ent: edict_p;

    speed, accel, decel: Single;
    movedir: vec3_t;
    pos1, pos2: vec3_t;

    velocity: vec3_t;
    avelocity: vec3_t;
    mass: integer;
    air_finished,
    gravity: Single; // per entity gravity multiplier (1.0 is normal)
                     // use for lowgrav artifact, flares

    goalentity: edict_p;
    movetarget: edict_p;
    yaw_speed,
    ideal_yaw: Single;

    nextthink: single;
    prethink: Proc_Pedictt;
    think: Proc_Pedictt;
    blocked: Proc_2Pedictt;   //move to moveinfo?
    touch: Proc_2edictt_cplanet_csurfacet;
    use: Proc_3edictt;
    pain: Proc_2edictt_single_int;
    die: Proc_3edictt_int_vec3t;

    touch_debounce_time, // are all these legit?  do we need more/less of them?
    pain_debounce_time,
    damage_debounce_time,
    fly_sound_debounce_time, //move to clientinfo
    last_move_time: single;

    health,
    max_health,
    gib_health,
    deadflag: integer;
    show_hostile: qboolean;

    powerarmor_time: Single;

    map: PChar;   // target_changelevel

    viewheight: Integer; // height above origin where eyesight is determined
    takedamage: damage_t; // CAK - was Integer
    dmg,
    radius_dmg: integer;
    dmg_radius: Single; // CAK - THIS WAS WRONG!!!!!
    sounds,  //make this a spawntemp var
    count: integer;

    chain,
    enemy,
    oldenemy,
    activator,
    groundentity: edict_p;
    groundentity_linkcount: integer;
    teamchain,
    teammaster: edict_p;

    mynoise,        // can go in client only
    mynoise2: edict_p;

    noise_index,
    noise_index2: integer;
    volume,
    attenuation: Single;

    // timing variables
    wait,
    delay,  // before firing targets
    random: Single;

    teleport_time: single;

    watertype,
    waterlevel: integer;

    move_origin: vec3_t;
    move_angles: vec3_t;

    // move this to clientinfo?
    light_level: integer;

    style: integer; // also used as areaportal number

    item: gitem_p; // for bonus items

    // common data blocks
    moveinfo: moveinfo_t;
    monsterinfo: monsterinfo_t;
  end;
  edict_t = edict_s;
  _edict_s = edict_t;
  p_edict_s = edict_p;
  pedict_t = edict_p;
  TEdict = edict_t;
  PEdict = edict_p;
  edict_at = array [0..MaxInt div SizeOf(edict_t)-1] of edict_t;
  edict_a = ^edict_at;
  TEdictArray = edict_at;
  PEdictArray = edict_a;

  // CAK - These two types are thanks to Clootie
  // Note - This is an array of POINTERS,
  // Most places you should use an array of RECORDS
  PEdictPArray = ^TEdictPArray;
  TEdictPArray = array [0..MaxInt div SizeOf(edict_p)-1] of edict_p;


//////////////////////////////////////
///////////////////////////////////////
/////////////////////////////////////


// define GAME_INCLUDE so that game.h does not define the
// short, server-visible gclient_t and edict_t structures,
// because we define the full size ones in this file
{$define GAME_INCLUDE}

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


Var
  game: game_locals_t;
  level: level_locals_t;
// CAK - MOVED TO game
//  gi: game_import_t;
//  globals: game_export_t;
  st: spawn_temp_t;

  sm_meat_index: integer;
  snd_fry: integer;

  jacket_armor_index: integer;
  combat_armor_index: integer;
  body_armor_index: integer;

  meansOfDeath: integer;
  g_edicts: edict_a;

  fields: Array[0..0] of field_t;
  itemlist: Array[0..0] of gitem_t;


// CAK - TAKEN FROM q_shared.h
(*
==========================================================

CVARS (console variables)

==========================================================
*)

// nothing outside the Cvar_*() functions should modify these fields!
type
  cvar_p = ^cvar_s;
  pcvar_s = cvar_p;
  cvar_s = record
    name: PChar;
    string_: PChar;
    latched_string: PChar; // for CVAR_LATCH vars
    flags: integer;
    modified: qboolean; // set each time the cvar is changed
    Value: single;
    Next: cvar_p;
  end;
  cvar_t = cvar_s;
  pcvar_t = cvar_p;
  TCVar = cvar_t;
  PCVar = cvar_p;
  cvar_at = array[0..MaxInt div sizeof(cvar_t)-1] of cvar_t;
  cvar_a = ^cvar_at;
  TCVarArray = cvar_at;
  PCVarArray = cvar_a;


Var
  maxentities,
  deathmatch,
  coop,
  dmflags,
  skill,
  fraglimit,
  timelimit: cvar_p;
{$ifdef CTF}
//ZOID
  capturelimit,
  instantweap: cvar_p;
//ZOID
{$endif}
  password: cvar_p;
{$ifndef CTF}
  spectator_password,
  needpass: cvar_p;
{$endif}
  g_select_empty,
  dedicated: cvar_p;

  filterban: cvar_p;

  sv_gravity,
  sv_maxvelocity: cvar_p;

  gun_x, gun_y, gun_z,
  sv_rollspeed,
  sv_rollangle: cvar_p;

  run_pitch,
  run_roll,
  bob_up,
  bob_pitch,
  bob_roll: cvar_p;

  sv_cheats,
  maxclients: cvar_p;
{$ifndef CTF}
  maxspectators: cvar_p;
{$endif}

  flood_msgs,
  flood_persecond,
  flood_waitdelay: cvar_p;

  sv_maplist: cvar_p;


{$ifdef CTF}
//ZOID
  is_quad: qboolean;
//ZOID
{$endif}



// massimo - Also, what does means this thing???
// #define world (&g_edicts[0])

// CAK - world is the first edict in the g_edicts array
// because MACROS do not exist in Delphi, I converted it to
// an edict_p which always points to the first edict in the g_edicts array.
Var
  world: edict_p absolute g_edicts;


implementation
Uses SysUtils; // CAK - Exception handling only (for assertions below)

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
  Assert(sizeof(gclient_s)=3804);
  Assert(sizeof(edict_s)=892);
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

