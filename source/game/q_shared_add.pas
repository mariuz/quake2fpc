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
{ File(s): q_shared.pas related                                              }
{ Content: This is unit which contains all the structures which were         }
{          crosslinked by original game.h and q_shared.h                     }
{                                                                            }
{ Initial created by: Juha                                                   }
{ Initial created on: 04-Mar-2003                                            }
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

unit q_shared_add;

interface

const
  MAX_STATS = 32;
  MAXTOUCH = 32;

type
  qboolean = LongBool;
  PQboolean = ^qboolean;

  vec_t = Single;
  vec3_t = array[0..2] of vec_t;
  vec5_t = array[0..4] of vec_t;

  vec_p = ^vec_t;
  vec3_p = ^vec3_t;
  vec5_p = ^vec5_t;

  cvar_p = ^cvar_t;
  cvar_t = record
    name: PChar;
    string_: PChar;
    latched_string: PChar;              // for CVAR_LATCH vars
    flags: integer;
    modified: qboolean;                 // set each time the cvar is changed
    Value: single;
    Next: cvar_p;
  end;

  cplane_p = ^cplane_t;
  cplane_t = record
    normal: vec3_t;
    dist: single;
    _type: byte;                        // for fast side tests
    signbits: byte;                     // signx + (signyshl1) + (signzshl1)
    pad: array[0..1] of byte;
  end;
  cplane_arr = array[0..0] of cplane_t;
  cplane_arrp = ^cplane_arr;

  csurface_p = ^csurface_t;
  csurface_t = record
    name: array[0..15] of char;
    flags: Integer;
    value: Integer;
  end;

  trace_p = ^trace_t;
  trace_t = record
    allsolid: qboolean;                 // if true, plane is not valid
    startsolid: qboolean;               // if true, the initial po : integer was in a solid area
    fraction: single;                   // time completed, 1.0 := didn't hit anything
    endpos: vec3_t;                     // final position
    plane: cplane_t;                    // surface normal at impact
    surface: csurface_p;                // surface hit
    contents: Integer;                  // contents on other side of surface hit
    ent: pointer;                       // not set by CM_* functions
  end;

  pmtype_p = ^pmtype_t;
  pmtype_t = (
    // can accelerate and turn
    PM_NORMAL,
    PM_SPECTATOR,
    // no acceleration or turning
    PM_DEAD,
    PM_GIB,                             // different bounding box
    PM_FREEZE
    );

  pmove_state_p = ^pmove_state_t;
  pmove_state_t = record
    pm_type: pmtype_t;

    origin: array[0..2] of smallint;    // 12.3
    velocity: array[0..2] of smallint;  // 12.3
    pm_flags: byte;                     // ducked, jump_held, etc
    pm_time: byte;                      // each unit = 8 ms
    gravity: smallint;
    delta_angles: array[0..2] of smallint; // add to command angles to get view direction
    // changed by spawns, rotating objects, and teleporters
  end;

  player_state_p = ^player_state_t;
  player_state_t = record
    pmove: pmove_state_t;               // for prediction
    // these fields do not need to be communicated bit-precise
    viewangles: vec3_t;                 // for fixed views
    viewoffset: vec3_t;                 // add to pmovestate->origin
    kick_angles: vec3_t;                // add to view direction to get render angles
    // set by weapon kicks, pain effects, etc
    gunangles: vec3_t;
    gunoffset: vec3_t;
    gunindex: Integer;
    gunframe: Integer;
    blend: array[0..3] of single;       // rgba full screen effect
    fov: single;                        // horizontal field of view
    rdflags: Integer;                   // refdef flags
    stats: array[0..MAX_STATS - 1] of smallint; // fast status bar updates
  end;

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

  entity_state_p = ^entity_state_t;
  entity_state_t = record
    number: integer;                    // edict index

    origin: vec3_t;
    angles: vec3_t;
    old_origin: vec3_t;                 // for lerping
    modelindex: Integer;
    modelindex2, modelindex3, modelindex4: Integer; // weapons, CTF flags, etc
    frame: Integer;
    skinnum: Integer;
    effects: Cardinal;                  // PGM - we're filling it, so it needs to be unsigned
    renderfx: Integer;
    solid: Integer;                     // for client side prediction, 8*(bits 0-4) is x/y radius
    // 8*(bits 5-9) is z down distance, 8(bits10-15) is z up
    // gi.linkentity sets this properly
    sound: Integer;                     // for looping sounds, to guarantee shutoff
    event: entity_event_t;              // CAK - was int
    // impulse events -- muzzle flashes, footsteps, etc
    // events only go out for a single frame, they
    // are automatically cleared each frame
  end;

  usercmd_p = ^usercmd_t;
  usercmd_t = record
    msec: byte;
    buttons: byte;
    angles: array[0..3 - 1] of smallint;
    forwardmove, sidemove, upmove: smallint;
    impulse: byte;                      // remove?
    lightlevel: byte;                   // light level the player is standing on
  end;

  pmove_p = ^pmove_t;
  pmove_t = record
    // state (in / out)
    s: pmove_state_t;

    // command (in)
    cmd: usercmd_t;
    snapinitial: qboolean;              // if s has been changed outside pmove

    // results (out)
    numtouch: integer;
    touchents: array[0..MAXTOUCH - 1] of pointer;

    viewangles: vec3_t;                 // clamped
    viewheight: single;

    mins, maxs: vec3_t;                 // bounding box size

    groundentity: pointer;
    watertype: integer;
    waterlevel: integer;

    // callbacks to test the world
    trace: function(var start, mins, maxs, _end: vec3_t): trace_t; cdecl;
    pointcontents: function(const point: vec3_t): Integer; cdecl;
  end;

  // destination class for gi.multicast
  multicast_t = (
    MULTICAST_ALL,
    MULTICAST_PHS,
    MULTICAST_PVS,
    MULTICAST_ALL_R,
    MULTICAST_PHS_R,
    MULTICAST_PVS_R
    );
  multicast_p = ^multicast_t;
  pmulticast_t = multicast_p;

implementation

end.
