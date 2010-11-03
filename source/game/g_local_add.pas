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
{ File(s): g_local related                                                   }
{ Content: local definitions for game module                                 }
{                                                                            }
{ Initial created by: Juha                                                   }
{ Initial created on: 02-Dec-2002                                            }
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
{ Updated on:  2003-May-23                                                   }
{ Updated by:  Scott Price (scott.price@totalise.co.uk)                      }
{              Tidy-up and addition of header and completion percentile      }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{ none                                                                       }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{ none                                                                       }
{----------------------------------------------------------------------------}
{ * Note:                                                                    }
{ none                                                                       }
{----------------------------------------------------------------------------}

unit g_local_add;

interface

uses
  game_add,
  q_shared_add,
  q_shared;

type
// edict->movetype values
  movetype_p = ^movetype_t;
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

  damage_p = ^damage_t;
  damage_t = (
    DAMAGE_NO,
    DAMAGE_YES,   // will take damage if hit
    DAMAGE_AIM   // auto targeting recognizes this
  );

  edict_p = ^edict_t;
  gitem_p = ^gitem_t;

  BoolFunc_2edict_s = function(ent, other: edict_p): qboolean; cdecl;
  Proc_edit_s__gitem_s = procedure(ent: edict_p; item: gitem_p); cdecl;
  Proc_edit_s = procedure(ent: edict_p); cdecl;

  gitem_t = record
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


// client data that stays across multiple level loads
  client_persistant_p = ^client_persistant_t;
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

// client data that stays across deathmatch respawns
  client_respawn_p = ^client_respawn_t;
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

  weaponstate_p = ^weaponstate_t;
  weaponstate_t = (
    WEAPON_READY,
    WEAPON_ACTIVATING,
    WEAPON_DROPPING,
    WEAPON_FIRING
  );


// this structure is cleared on each PutClientInServer(),
// except for 'client->pers'
  gclient_p = ^gclient_t;
  gclient_t = record
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

    weaponstate: weaponstate_t; //was Integer; modified by FAB

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



  Proc_Pedictt = procedure(x: edict_p); cdecl;
  Proc_Pedictt_single = procedure(self: edict_p; dist: single); cdecl;
  Boolfunc_Pedictt = function(self: edict_p): qboolean; cdecl;
  Proc_2Pedictt_single = procedure(self, other: edict_p; eta: single); cdecl;
  Proc_2Pedictt = procedure(self, other: edict_p); cdecl;
  Proc_2edictt_cplanet_csurfacet = Procedure(self, other: edict_p;
                                                  plane: cplane_p; surf: csurface_p); cdecl;
  Proc_3edictt = Procedure (self, other, activator: edict_p); cdecl;
  Proc_2edictt_single_int = Procedure(self, other: edict_p;
                                          kick: single; damage: integer); cdecl;
  Proc_3edictt_int_vec3t = Procedure(self, inflictor, attacker: edict_p;
                                          damage: integer; const point: vec3_t); cdecl;


  moveinfo_p = ^moveinfo_t;
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

  mframe_p = ^mframe_t;
  mframe_t = record
    aifunc: Proc_Pedictt_single;
    dist: Single;
    thinkfunc: Proc_Pedictt;
  end;
  mframe_at = array[0..MaxInt div SizeOf(mframe_t) - 1] of mframe_t;
  mframe_a = ^mframe_at;

  mmove_p = ^mmove_t;
  mmove_t = record
    firstframe,
    lastframe: integer;
    frame: mframe_p;
    endfunc: Proc_Pedictt;
  end;

  monsterinfo_p = ^monsterinfo_t;
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

  edict_t = record
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


implementation

end.
 
