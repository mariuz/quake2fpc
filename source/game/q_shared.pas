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
{ File(s): game\q_shared.c                                                   }
{          game\q_shared.h                                                   }
{ Content: stuff "included first by ALL program modules"                     }
{                                                                            }
{ Initial conversion by : savage                                             }
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
{ 1) Updated on : 24-Feb-2002                                                }
{    Updated by : Carl A Kenner (carl_kenner@hotmail.com)                    }
{                                                                            }
{ 2) 26-Feb-2002 - Clootie (clootie@reactor.ru)                              }
{    *** edict_s and cplane_t *** set orecord (including pointers) to be     }
{    [originally] defined only in one unit                                   }
{                                                                            }
{ 1) Updated on : 3-Mar-2002                                                 }
{    Updated by : Carl A Kenner (carl_kenner@hotmail.com)                    }
{
{ Updated on: 3-jun-2002
{ Updated by: Juha Hartikainen (juha@linearteam.org}
{ - Changed OUT function parameters to VAR.
{ - Added overloaded version of VectorCopy }
{                                                                            }
{----------------------------------------------------------------------------}
unit q_shared;

interface

uses
  {$IFDEF WIN32}
  Windows,
  {$ENDIF}
  q_shared_add,
  Math;

const
  // angle indexes
  PITCH = 0;                            // up / down

  YAW = 1;                              // left / right

  ROLL = 2;                             // fall over

  MAX_STRING_CHARS = 1024;              // max length of a string passed to Cmd_TokenizeString
  MAX_STRING_TOKENS = 80;               // max tokens resulting from Cmd_TokenizeString
  MAX_TOKEN_CHARS = 128;                // max length of an individual token

  MAX_QPATH = 64;                       // max length of a quake game pathname
  MAX_OSPATH = 128;                     // max length of a filesystem pathname

  //
  // per-level limits
  //
  MAX_CLIENTS = 256;                    // absolute limit
  MAX_EDICTS = 1024;                    // must change protocol to increase more
  MAX_LIGHTSTYLES = 256;
  MAX_MODELS = 256;                     // these are sent over the net as bytes
  MAX_SOUNDS = 256;                     // so they cannot be blindly increased
  MAX_IMAGES = 256;
  MAX_ITEMS = 256;
  MAX_GENERAL = (MAX_CLIENTS * 2);      // general config strings

  // game pr : integer flags
  PRINT_LOW = 0;                        // pickup messages
  PRINT_MEDIUM = 1;                     // death messages
  PRINT_HIGH = 2;                       // critical messages
  PRINT_CHAT = 3;                       // chat messages

  ERR_FATAL = 0;                        // exit the entire game with a popup window
  ERR_DROP = 1;                         // pr : integer to console and disconnect from game
  ERR_DISCONNECT = 2;                   // don't kill server

  PRINT_ALL = 0;
  PRINT_DEVELOPER = 1;                  // only pr : integer when 'developer 1'
  PRINT_ALERT = 2;

type
  qboolean = q_shared_add.qboolean;
  PQboolean = q_shared_add.Pqboolean;

  // destination class for gi.multicast
  multicast_t = q_shared_add.multicast_t;
  multicast_p = q_shared_add.multicast_p;

  tcdeclproc = procedure; cdecl;

  (*
  ==============================================================

  MATHLIB

  ==============================================================
  *)
type
  vec_t = q_shared_add.vec_t;
  vec3_t = q_shared_add.vec3_t;
  vec5_t = q_shared_add.vec5_t;

  vec_p = q_shared_add.vec_p;
  vec3_p = q_shared_add.vec3_p;
  vec5_p = q_shared_add.vec5_p;

  fixed4_t = integer;
  fixed8_t = integer;
  fixed16_t = integer;

  fixed4_p = ^fixed4_t;                 // CAK
  fixed8_p = ^fixed8_t;                 // CAK
  fixed16_p = ^fixed16_t;               // CAK

  matrix33 = array[0..2, 0..2] of single; // CAK - Used for transform function below
  matrix34 = array[0..2, 0..3] of single; // CAK - Used for transform function below

const
  M_PI = 3.14159265358979323846;        // matches value in gcc v2 math.h

var
  vec3_origin: vec3_t = (0, 0, 0);

const
  nanmask = 255 shl 23;

function IS_NAN(x: single): qboolean;

// microsoft's fabs seems to be ungodly slow...
// CAK - I don't know if borland's abs is ungodly slow
// CAK - if so, then maybe copy and paste to a new abs function
function Q_fabs(f: single): single;
function fabs(f: single): single;       // SAME AS Q_fabs

function Q_ftol(f: single): LongInt;

// CAK - math functions, missing in Delphi 3
function floor(const x: Single): Integer;
function ceil(const x: Single): Integer;

// CAK - These were originally MACROS
function DotProduct(const v1, v2: vec3_t): vec_t;
procedure VectorSubtract(const veca, vecb: vec3_t; var out_: vec3_t); overload;
procedure VectorSubtract(const veca, vecb: array of smallint; var out_: array of integer); overload;
procedure VectorAdd(const veca, vecb: vec3_t; var out_: vec3_t);
procedure VectorCopy(const _in: vec3_t; var out_: vec3_t); overload;
procedure VectorCopy(const _in: vec3_t; var out_: array of smallint); overload;
procedure VectorCopy(const _in: array of smallint; var out_: array of smallint); overload;
procedure VectorCopy(const _in: array of smallint; var out_: vec3_t); overload;
procedure VectorClear(var a: vec3_t);
procedure VectorNegate(const a: vec3_t; var b: vec3_t);
procedure VectorSet(var v: vec3_t; x, y, z: vec_t);

procedure VectorMA(const veca: vec3_t; scale: single; const vecb: vec3_t; var vecc: vec3_t);

// just in  you do't want to use the macros  [sic - CAK]
function _DotProduct(const v1, v2: vec3_t): vec_t;
procedure _VectorSubtract(const veca, vecb: vec3_t; var out_: vec3_t);
procedure _VectorAdd(const veca, vecb: vec3_t; var out_: vec3_t);
procedure _VectorCopy(const _in: vec3_t; var out_: vec3_t);

procedure ClearBounds(var mins, maxs: vec3_t);
procedure AddPointToBounds(const v: vec3_t; var mins, maxs: vec3_t);
function VectorCompare(const v1, v2: vec3_t): integer;
function VectorLength(const v: vec3_t): vec_t;
procedure CrossProduct(const v1, v2: vec3_t; var cross: vec3_t);
function VectorNormalize(var v: vec3_t): vec_t; // result =s vector length
function VectorNormalize2(const v: vec3_t; var out_: vec3_t): vec_t;
procedure VectorInverse(var v: vec3_t);
procedure VectorScale(const _in: vec3_t; const scale: vec_t; var out_: vec3_t);
function Q_log2(val: Integer): Integer;

procedure R_ConcatRotations(const in1, in2: matrix33; var out_: matrix33);
procedure R_ConcatTransforms(const in1, in2: matrix34; var out_: matrix34);

// plane_t structure
// !!!  if this is changed, it must be changed in asm code too !!!
type
  cplane_p = q_shared_add.cplane_p;
  cplane_t = q_shared_add.cplane_t;
  cplane_arrp = q_shared_add.cplane_arrp;

procedure AngleVectors(const angles: vec3_t; forwards, right, up: vec3_p);
function BoxOnPlaneSide(var emins, emaxs: vec3_t; p: cplane_p): Integer;
function anglemod(a: single): single;
function LerpAngle(a2, a1, frac: single): single;

// CAK - This was originally a MACRO
function BOX_ON_PLANE_SIDE(var emins, emaxs: vec3_t; p: cplane_p): Integer;

procedure ProjectPointOnPlane(var dst: vec3_t; const p, normal: vec3_t);
procedure PerpendicularVector(var dst: vec3_t; const src: vec3_t);
procedure RotatePointAroundVector(var dst: vec3_t; const dir, point: vec3_t; degrees: single);

//=============================================

function COM_SkipPath(pathname: PChar): PChar;
procedure COM_StripExtension(in_, out_: PChar);
procedure COM_FileBase(in_, out_: PChar);
procedure COM_FilePath(in_, out_: PChar);
procedure COM_DefaultExtension(path, extension: PChar);

function COM_Parse(var data_p: PChar): PChar; // CAK - WARNING!!!! WAS ^PChar
// data is an in/out parm, returns a parsed out token

procedure Com_sprintf(dest: PChar; size: Integer; fmt: PChar; const Args: array of const);

procedure Com_PageInMemory(buffer: PByte; size: Integer);

//=============================================

// portable case insensitive compare
function Q_stricmp(s1, s2: PChar): Integer;
function Q_strcasecmp(s1, s2: PChar): Integer;
function Q_strncasecmp(s1, s2: PChar; n: Integer): Integer;

//=============================================

function BigShort(L: SmallInt): SmallInt;
function LittleShort(L: SmallInt): SmallInt;
function BigLong(L: LongInt): LongInt;
function LittleLong(L: LongInt): LongInt;
function BigFloat(L: Single): Single;
function LittleFloat(L: Single): Single;

procedure Swap_Init;

function va(format: PChar; const Args: array of const): PChar;

//=============================================

//
// key / value info strings
//

const
  MAX_INFO_KEY = 64;
  MAX_INFO_VALUE = 64;
  MAX_INFO_STRING = 512;

function Info_ValueForKey(s, key: PChar): PChar;
procedure Info_RemoveKey(s, key: PChar);
procedure Info_SetValueForKey(s, key, value: PChar);
function Info_Validate(s: PChar): qboolean;

(*
==============================================================

SYSTEM SPECIFIC

==============================================================
*)

// directory searching
const
  SFF_ARCH = $01;
  SFF_HIDDEN = $02;
  SFF_RDONLY = $04;
  SFF_SUBDIR = $08;
  SFF_SYSTEM = $10;

  (*
  ==========================================================

  CVARS (console variables)

  ==========================================================
  *)

{$DEFINE CVAR}
const
  CVAR_ARCHIVE = 1;                     // set to cause it to be saved to vars.rc
  CVAR_USERINFO = 2;                    // added to userinfo  when changed
  CVAR_SERVERINFO = 4;                  // added to serverinfo when changed
  CVAR_NOSET = 8;                       // don't allow change from console at all,
  // but can be set from the command line
  CVAR_LATCH = 16;                      // save changes until server restart

  // nothing outside the Cvar_*() functions should modify these fields!
type
  cvar_p = q_shared_add.cvar_p;
  cvar_t = q_shared_add.cvar_t;

  (*
  ==============================================================

  COLLISION DETECTION

  ==============================================================
  *)

  // lower bits are stronger, and will eat weaker brushes completely
const
  CONTENTS_SOLID = 1;                   // an eye is never valid in a solid
  CONTENTS_WINDOW = 2;                  // translucent, but not watery
  CONTENTS_AUX = 4;
  CONTENTS_LAVA = 8;
  CONTENTS_SLIME = 16;
  CONTENTS_WATER = 32;
  CONTENTS_MIST = 64;
  LAST_VISIBLE_CONTENTS = 64;

  // remaining contents are non-visible, and don't eat brushes

const
  CONTENTS_AREAPORTAL = $8000;
  CONTENTS_PLAYERCLIP = $10000;
  CONTENTS_MONSTERCLIP = $20000;

  // currents can be added to any other contents, and may be mixed
const
  CONTENTS_CURRENT_0 = $40000;
  CONTENTS_CURRENT_90 = $80000;
  CONTENTS_CURRENT_180 = $100000;
  CONTENTS_CURRENT_270 = $200000;
  CONTENTS_CURRENT_UP = $400000;
  CONTENTS_CURRENT_DOWN = $800000;

const
  CONTENTS_ORIGIN = $1000000;           // removed before bsping an entity
  CONTENTS_MONSTER = $2000000;          // should never be on a brush, only in game
  CONTENTS_DEADMONSTER = $4000000;
  CONTENTS_DETAIL = $8000000;           // brushes to be added after vis leafs
  CONTENTS_TRANSLUCENT = $10000000;     // auto set if any surface has trans
  CONTENTS_LADDER = $20000000;

const
  SURF_LIGHT = $1;                      // value will hold the light strength
  SURF_SLICK = $2;                      // effects game physics
  SURF_SKY = $4;                        // don't draw, but add to skybox
  SURF_WARP = $8;                       // turbulent water warp
  SURF_TRANS33 = $10;
  SURF_TRANS66 = $20;
  SURF_FLOWING = $40;                   // scroll towards angle
  SURF_NODRAW = $80;                    // don't bother referencing the texture

  // content masks
const
  MASK_ALL = (-1);
  MASK_SOLID = (CONTENTS_SOLID or CONTENTS_WINDOW);
  MASK_PLAYERSOLID = (CONTENTS_SOLID or CONTENTS_PLAYERCLIP or CONTENTS_WINDOW or
    CONTENTS_MONSTER);
  MASK_DEADSOLID = (CONTENTS_SOLID or CONTENTS_PLAYERCLIP or CONTENTS_WINDOW);
  MASK_MONSTERSOLID = (CONTENTS_SOLID or CONTENTS_MONSTERCLIP or CONTENTS_WINDOW or
    CONTENTS_MONSTER);
  MASK_WATER = (CONTENTS_WATER or CONTENTS_LAVA or CONTENTS_SLIME);
  MASK_OPAQUE = (CONTENTS_SOLID or CONTENTS_SLIME or CONTENTS_LAVA);
  MASK_SHOT = (CONTENTS_SOLID or CONTENTS_MONSTER or CONTENTS_WINDOW or
    CONTENTS_DEADMONSTER);
  MASK_CURRENT = (CONTENTS_CURRENT_0 or CONTENTS_CURRENT_90 or CONTENTS_CURRENT_180
    or CONTENTS_CURRENT_270 or CONTENTS_CURRENT_UP or CONTENTS_CURRENT_DOWN);

  // gi.BoxEdicts can return a list of either solid or trigger entities
  // FIXME: eliminate AREA_ distinction?
const
  AREA_SOLID = 1;
  AREA_TRIGGERS = 2;

  // Cplane record was moved above prototypes so it would compile!

  // type = recordure offset for asm code
const
  CPLANE_NORMAL_X = 0;
  CPLANE_NORMAL_Y = 4;
  CPLANE_NORMAL_Z = 8;
  CPLANE_DIST = 12;
  CPLANE_TYPE = 16;
  CPLANE_SIGNBITS = 17;
  CPLANE_PAD0 = 18;
  CPLANE_PAD1 = 19;

type
  cmodel_p = ^cmodel_t;
  cmodel_t = record
    mins, maxs: vec3_t;
    origin: vec3_t;                     // for sounds or lights
    headnode: Integer;
  end;

  csurface_p = q_shared_add.csurface_p;
  csurface_t = q_shared_add.csurface_t;

  mapsurface_p = ^mapsurface_t;
  mapsurface_t = record                 // used internally due to name len probs //ZOID
    c: csurface_t;
    rname: array[0..31] of Char;
  end;

  //==============================================

  // entity_state_t->event values
  // ertity events are for effects that take place reletive
  // to an existing entities origin.  Very network efficient.
  // All muzzle flashes really should be converted to events...
  entity_event_p = q_shared_add.entity_event_p;
  entity_event_t = q_shared_add.entity_event_t;

  // entity_state_t is the information conveyed from the server
  // in an update message about entities that the client will
  // need to render in some way
  entity_state_p = q_shared_add.entity_state_p;
  entity_state_t = q_shared_add.entity_state_t;

  //==============================================

  // pmove_state_t is the information necessary for client side movement
  // prediction
  pmtype_p = q_shared_add.pmtype_p;
  pmtype_t = q_shared_add.pmtype_t;

  // pmove.pm_flags
const
  PMF_DUCKED = 1;
  PMF_JUMP_HELD = 2;
  PMF_ON_GROUND = 4;
  PMF_TIME_WATERJUMP = 8;               // pm_time is waterjump
  PMF_TIME_LAND = 16;                   // pm_time is time before rejump
  PMF_TIME_TELEPORT = 32;               // pm_time is non-moving time
  PMF_NO_PREDICTION = 64;               // temporarily disables prediction (used for grappling hook)

type

{$IFNDEF GAMEDLL}
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
{$ENDIF}

  player_state_p = q_shared_add.player_state_p;
  player_state_t = q_shared_add.player_state_t;

  //
  // button bits
  //
const
  BUTTON_ATTACK = 1;
  BUTTON_USE = 2;
  BUTTON_ANY = 128;                     // any key whatsoever

  // usercmd_t is sent to the server each client frame
type
  usercmd_p = q_shared_add.usercmd_p;
  usercmd_t = q_shared_add.usercmd_t;

const

  // entity_state_t.effects
  // Effects are things handled on the client side (lights, particles, frame animations)
  // that happen constantly on the given entity.
  // An entity that has effects will be sent to the client
  // even if it has a zero index model.
  EF_ROTATE = $00000001;                // rotate (bonus items)
  EF_GIB = $00000002;                   // leave a trail
  EF_BLASTER = $00000008;               // redlight + trail
  EF_ROCKET = $00000010;                // redlight + trail
  EF_GRENADE = $00000020;
  EF_HYPERBLASTER = $00000040;
  EF_BFG = $00000080;
  EF_COLOR_SHELL = $00000100;
  EF_POWERSCREEN = $00000200;
  EF_ANIM01 = $00000400;                // automatically cycle between frames 0 and 1 at 2 hz
  EF_ANIM23 = $00000800;                // automatically cycle between frames 2 and 3 at 2 hz
  EF_ANIM_ALL = $00001000;              // automatically cycle through all frames at 2hz
  EF_ANIM_ALLFAST = $00002000;          // automatically cycle through all frames at 10hz
  EF_FLIES = $00004000;
  EF_QUAD = $00008000;
  EF_PENT = $00010000;
  EF_TELEPORTER = $00020000;            // particle fountain
  EF_FLAG1 = $00040000;
  EF_FLAG2 = $00080000;
  // RAFAEL
  EF_IONRIPPER = $00100000;
  EF_GREENGIB = $00200000;
  EF_BLUEHYPERBLASTER = $00400000;
  EF_SPINNINGLIGHTS = $00800000;
  EF_PLASMA = $01000000;
  EF_TRAP = $02000000;

  //ROGUE
  EF_TRACKER = $04000000;
  EF_DOUBLE = $08000000;
  EF_SPHERETRANS = $10000000;
  EF_TAGTRAIL = $20000000;
  EF_HALF_DAMAGE = $40000000;
  EF_TRACKERTRAIL = $80000000;
  //ROGUE

  // entity_state_t.renderfx flags
  RF_MINLIGHT = 1;                      // allways have some light (viewmodel)
  RF_VIEWERMODEL = 2;                   // don't draw through eyes, only mirrors
  RF_WEAPONMODEL = 4;                   // only draw through eyes
  RF_FULLBRIGHT = 8;                    // allways draw full intensity
  RF_DEPTHHACK = 16;                    // for view weapon Z crunching
  RF_TRANSLUCENT = 32;
  RF_FRAMELERP = 64;
  RF_BEAM = 128;
  RF_CUSTOMSKIN = 256;                  // skin is an index in image_precache
  RF_GLOW = 512;                        // pulse lighting for bonus items
  RF_SHELL_RED = 1024;
  RF_SHELL_GREEN = 2048;
  RF_SHELL_BLUE = 4096;

  //ROGUE
  RF_IR_VISIBLE = $00008000;            // 32768
  RF_SHELL_DOUBLE = $00010000;          // 65536
  RF_SHELL_HALF_DAM = $00020000;
  RF_USE_DISGUISE = $00040000;
  //ROGUE

  // player_state_t.refdef flags
  RDF_UNDERWATER = 1;                   // warp the screen as apropriate
  RDF_NOWORLDMODEL = 2;                 // used for player configuration screen

  //ROGUE
  RDF_IRGOGGLES = 4;
  RDF_UVGOGGLES = 8;
  //ROGUE

  //
  // muzzle flashes / player effects
  //
  MZ_BLASTER = 0;
  MZ_MACHINEGUN = 1;
  MZ_SHOTGUN = 2;
  MZ_CHAINGUN1 = 3;
  MZ_CHAINGUN2 = 4;
  MZ_CHAINGUN3 = 5;
  MZ_RAILGUN = 6;
  MZ_ROCKET = 7;
  MZ_GRENADE = 8;
  MZ_LOGIN = 9;
  MZ_LOGOUT = 10;
  MZ_RESPAWN = 11;
  MZ_BFG = 12;
  MZ_SSHOTGUN = 13;
  MZ_HYPERBLASTER = 14;
  MZ_ITEMRESPAWN = 15;
  // RAFAEL
  MZ_IONRIPPER = 16;
  MZ_BLUEHYPERBLASTER = 17;
  MZ_PHALANX = 18;
  MZ_SILENCED = 128;                    // bit flag ORed with one of the above numbers

  //ROGUE
  MZ_ETF_RIFLE = 30;
  MZ_UNUSED = 31;
  MZ_SHOTGUN2 = 32;
  MZ_HEATBEAM = 33;
  MZ_BLASTER2 = 34;
  MZ_TRACKER = 35;
  MZ_NUKE1 = 36;
  MZ_NUKE2 = 37;
  MZ_NUKE4 = 38;
  MZ_NUKE8 = 39;
  //ROGUE

  //
  // monster muzzle flashes
  //
  MZ2_TANK_BLASTER_1 = 1;
  MZ2_TANK_BLASTER_2 = 2;
  MZ2_TANK_BLASTER_3 = 3;
  MZ2_TANK_MACHINEGUN_1 = 4;
  MZ2_TANK_MACHINEGUN_2 = 5;
  MZ2_TANK_MACHINEGUN_3 = 6;
  MZ2_TANK_MACHINEGUN_4 = 7;
  MZ2_TANK_MACHINEGUN_5 = 8;
  MZ2_TANK_MACHINEGUN_6 = 9;
  MZ2_TANK_MACHINEGUN_7 = 10;
  MZ2_TANK_MACHINEGUN_8 = 11;
  MZ2_TANK_MACHINEGUN_9 = 12;
  MZ2_TANK_MACHINEGUN_10 = 13;
  MZ2_TANK_MACHINEGUN_11 = 14;
  MZ2_TANK_MACHINEGUN_12 = 15;
  MZ2_TANK_MACHINEGUN_13 = 16;
  MZ2_TANK_MACHINEGUN_14 = 17;
  MZ2_TANK_MACHINEGUN_15 = 18;
  MZ2_TANK_MACHINEGUN_16 = 19;
  MZ2_TANK_MACHINEGUN_17 = 20;
  MZ2_TANK_MACHINEGUN_18 = 21;
  MZ2_TANK_MACHINEGUN_19 = 22;
  MZ2_TANK_ROCKET_1 = 23;
  MZ2_TANK_ROCKET_2 = 24;
  MZ2_TANK_ROCKET_3 = 25;

  MZ2_INFANTRY_MACHINEGUN_1 = 26;
  MZ2_INFANTRY_MACHINEGUN_2 = 27;
  MZ2_INFANTRY_MACHINEGUN_3 = 28;
  MZ2_INFANTRY_MACHINEGUN_4 = 29;
  MZ2_INFANTRY_MACHINEGUN_5 = 30;
  MZ2_INFANTRY_MACHINEGUN_6 = 31;
  MZ2_INFANTRY_MACHINEGUN_7 = 32;
  MZ2_INFANTRY_MACHINEGUN_8 = 33;
  MZ2_INFANTRY_MACHINEGUN_9 = 34;
  MZ2_INFANTRY_MACHINEGUN_10 = 35;
  MZ2_INFANTRY_MACHINEGUN_11 = 36;
  MZ2_INFANTRY_MACHINEGUN_12 = 37;
  MZ2_INFANTRY_MACHINEGUN_13 = 38;

  MZ2_SOLDIER_BLASTER_1 = 39;
  MZ2_SOLDIER_BLASTER_2 = 40;
  MZ2_SOLDIER_SHOTGUN_1 = 41;
  MZ2_SOLDIER_SHOTGUN_2 = 42;
  MZ2_SOLDIER_MACHINEGUN_1 = 43;
  MZ2_SOLDIER_MACHINEGUN_2 = 44;

  MZ2_GUNNER_MACHINEGUN_1 = 45;
  MZ2_GUNNER_MACHINEGUN_2 = 46;
  MZ2_GUNNER_MACHINEGUN_3 = 47;
  MZ2_GUNNER_MACHINEGUN_4 = 48;
  MZ2_GUNNER_MACHINEGUN_5 = 49;
  MZ2_GUNNER_MACHINEGUN_6 = 50;
  MZ2_GUNNER_MACHINEGUN_7 = 51;
  MZ2_GUNNER_MACHINEGUN_8 = 52;
  MZ2_GUNNER_GRENADE_1 = 53;
  MZ2_GUNNER_GRENADE_2 = 54;
  MZ2_GUNNER_GRENADE_3 = 55;
  MZ2_GUNNER_GRENADE_4 = 56;

  MZ2_CHICK_ROCKET_1 = 57;

  MZ2_FLYER_BLASTER_1 = 58;
  MZ2_FLYER_BLASTER_2 = 59;

  MZ2_MEDIC_BLASTER_1 = 60;

  MZ2_GLADIATOR_RAILGUN_1 = 61;

  MZ2_HOVER_BLASTER_1 = 62;

  MZ2_ACTOR_MACHINEGUN_1 = 63;

  MZ2_SUPERTANK_MACHINEGUN_1 = 64;
  MZ2_SUPERTANK_MACHINEGUN_2 = 65;
  MZ2_SUPERTANK_MACHINEGUN_3 = 66;
  MZ2_SUPERTANK_MACHINEGUN_4 = 67;
  MZ2_SUPERTANK_MACHINEGUN_5 = 68;
  MZ2_SUPERTANK_MACHINEGUN_6 = 69;
  MZ2_SUPERTANK_ROCKET_1 = 70;
  MZ2_SUPERTANK_ROCKET_2 = 71;
  MZ2_SUPERTANK_ROCKET_3 = 72;

  MZ2_BOSS2_MACHINEGUN_L1 = 73;
  MZ2_BOSS2_MACHINEGUN_L2 = 74;
  MZ2_BOSS2_MACHINEGUN_L3 = 75;
  MZ2_BOSS2_MACHINEGUN_L4 = 76;
  MZ2_BOSS2_MACHINEGUN_L5 = 77;
  MZ2_BOSS2_ROCKET_1 = 78;
  MZ2_BOSS2_ROCKET_2 = 79;
  MZ2_BOSS2_ROCKET_3 = 80;
  MZ2_BOSS2_ROCKET_4 = 81;

  MZ2_FLOAT_BLASTER_1 = 82;

  MZ2_SOLDIER_BLASTER_3 = 83;
  MZ2_SOLDIER_SHOTGUN_3 = 84;
  MZ2_SOLDIER_MACHINEGUN_3 = 85;
  MZ2_SOLDIER_BLASTER_4 = 86;
  MZ2_SOLDIER_SHOTGUN_4 = 87;
  MZ2_SOLDIER_MACHINEGUN_4 = 88;
  MZ2_SOLDIER_BLASTER_5 = 89;
  MZ2_SOLDIER_SHOTGUN_5 = 90;
  MZ2_SOLDIER_MACHINEGUN_5 = 91;
  MZ2_SOLDIER_BLASTER_6 = 92;
  MZ2_SOLDIER_SHOTGUN_6 = 93;
  MZ2_SOLDIER_MACHINEGUN_6 = 94;
  MZ2_SOLDIER_BLASTER_7 = 95;
  MZ2_SOLDIER_SHOTGUN_7 = 96;
  MZ2_SOLDIER_MACHINEGUN_7 = 97;
  MZ2_SOLDIER_BLASTER_8 = 98;
  MZ2_SOLDIER_SHOTGUN_8 = 99;
  MZ2_SOLDIER_MACHINEGUN_8 = 100;

  // --- Xian shit below ---
  MZ2_MAKRON_BFG = 101;
  MZ2_MAKRON_BLASTER_1 = 102;
  MZ2_MAKRON_BLASTER_2 = 103;
  MZ2_MAKRON_BLASTER_3 = 104;
  MZ2_MAKRON_BLASTER_4 = 105;
  MZ2_MAKRON_BLASTER_5 = 106;
  MZ2_MAKRON_BLASTER_6 = 107;
  MZ2_MAKRON_BLASTER_7 = 108;
  MZ2_MAKRON_BLASTER_8 = 109;
  MZ2_MAKRON_BLASTER_9 = 110;
  MZ2_MAKRON_BLASTER_10 = 111;
  MZ2_MAKRON_BLASTER_11 = 112;
  MZ2_MAKRON_BLASTER_12 = 113;
  MZ2_MAKRON_BLASTER_13 = 114;
  MZ2_MAKRON_BLASTER_14 = 115;
  MZ2_MAKRON_BLASTER_15 = 116;
  MZ2_MAKRON_BLASTER_16 = 117;
  MZ2_MAKRON_BLASTER_17 = 118;
  MZ2_MAKRON_RAILGUN_1 = 119;
  MZ2_JORG_MACHINEGUN_L1 = 120;
  MZ2_JORG_MACHINEGUN_L2 = 121;
  MZ2_JORG_MACHINEGUN_L3 = 122;
  MZ2_JORG_MACHINEGUN_L4 = 123;
  MZ2_JORG_MACHINEGUN_L5 = 124;
  MZ2_JORG_MACHINEGUN_L6 = 125;
  MZ2_JORG_MACHINEGUN_R1 = 126;
  MZ2_JORG_MACHINEGUN_R2 = 127;
  MZ2_JORG_MACHINEGUN_R3 = 128;
  MZ2_JORG_MACHINEGUN_R4 = 129;
  MZ2_JORG_MACHINEGUN_R5 = 130;
  MZ2_JORG_MACHINEGUN_R6 = 131;
  MZ2_JORG_BFG_1 = 132;
  MZ2_BOSS2_MACHINEGUN_R1 = 133;
  MZ2_BOSS2_MACHINEGUN_R2 = 134;
  MZ2_BOSS2_MACHINEGUN_R3 = 135;
  MZ2_BOSS2_MACHINEGUN_R4 = 136;
  MZ2_BOSS2_MACHINEGUN_R5 = 137;

  //ROGUE
  MZ2_CARRIER_MACHINEGUN_L1 = 138;
  MZ2_CARRIER_MACHINEGUN_R1 = 139;
  MZ2_CARRIER_GRENADE = 140;
  MZ2_TURRET_MACHINEGUN = 141;
  MZ2_TURRET_ROCKET = 142;
  MZ2_TURRET_BLASTER = 143;
  MZ2_STALKER_BLASTER = 144;
  MZ2_DAEDALUS_BLASTER = 145;
  MZ2_MEDIC_BLASTER_2 = 146;
  MZ2_CARRIER_RAILGUN = 147;
  MZ2_WIDOW_DISRUPTOR = 148;
  MZ2_WIDOW_BLASTER = 149;
  MZ2_WIDOW_RAIL = 150;
  MZ2_WIDOW_PLASMABEAM = 151;           // PMM - not used
  MZ2_CARRIER_MACHINEGUN_L2 = 152;
  MZ2_CARRIER_MACHINEGUN_R2 = 153;
  MZ2_WIDOW_RAIL_LEFT = 154;
  MZ2_WIDOW_RAIL_RIGHT = 155;
  MZ2_WIDOW_BLASTER_SWEEP1 = 156;
  MZ2_WIDOW_BLASTER_SWEEP2 = 157;
  MZ2_WIDOW_BLASTER_SWEEP3 = 158;
  MZ2_WIDOW_BLASTER_SWEEP4 = 159;
  MZ2_WIDOW_BLASTER_SWEEP5 = 160;
  MZ2_WIDOW_BLASTER_SWEEP6 = 161;
  MZ2_WIDOW_BLASTER_SWEEP7 = 162;
  MZ2_WIDOW_BLASTER_SWEEP8 = 163;
  MZ2_WIDOW_BLASTER_SWEEP9 = 164;
  MZ2_WIDOW_BLASTER_100 = 165;
  MZ2_WIDOW_BLASTER_90 = 166;
  MZ2_WIDOW_BLASTER_80 = 167;
  MZ2_WIDOW_BLASTER_70 = 168;
  MZ2_WIDOW_BLASTER_60 = 169;
  MZ2_WIDOW_BLASTER_50 = 170;
  MZ2_WIDOW_BLASTER_40 = 171;
  MZ2_WIDOW_BLASTER_30 = 172;
  MZ2_WIDOW_BLASTER_20 = 173;
  MZ2_WIDOW_BLASTER_10 = 174;
  MZ2_WIDOW_BLASTER_0 = 175;
  MZ2_WIDOW_BLASTER_10L = 176;
  MZ2_WIDOW_BLASTER_20L = 177;
  MZ2_WIDOW_BLASTER_30L = 178;
  MZ2_WIDOW_BLASTER_40L = 179;
  MZ2_WIDOW_BLASTER_50L = 180;
  MZ2_WIDOW_BLASTER_60L = 181;
  MZ2_WIDOW_BLASTER_70L = 182;
  MZ2_WIDOW_RUN_1 = 183;
  MZ2_WIDOW_RUN_2 = 184;
  MZ2_WIDOW_RUN_3 = 185;
  MZ2_WIDOW_RUN_4 = 186;
  MZ2_WIDOW_RUN_5 = 187;
  MZ2_WIDOW_RUN_6 = 188;
  MZ2_WIDOW_RUN_7 = 189;
  MZ2_WIDOW_RUN_8 = 190;
  MZ2_CARRIER_ROCKET_1 = 191;
  MZ2_CARRIER_ROCKET_2 = 192;
  MZ2_CARRIER_ROCKET_3 = 193;
  MZ2_CARRIER_ROCKET_4 = 194;
  MZ2_WIDOW2_BEAMER_1 = 195;
  MZ2_WIDOW2_BEAMER_2 = 196;
  MZ2_WIDOW2_BEAMER_3 = 197;
  MZ2_WIDOW2_BEAMER_4 = 198;
  MZ2_WIDOW2_BEAMER_5 = 199;
  MZ2_WIDOW2_BEAM_SWEEP_1 = 200;
  MZ2_WIDOW2_BEAM_SWEEP_2 = 201;
  MZ2_WIDOW2_BEAM_SWEEP_3 = 202;
  MZ2_WIDOW2_BEAM_SWEEP_4 = 203;
  MZ2_WIDOW2_BEAM_SWEEP_5 = 204;
  MZ2_WIDOW2_BEAM_SWEEP_6 = 205;
  MZ2_WIDOW2_BEAM_SWEEP_7 = 206;
  MZ2_WIDOW2_BEAM_SWEEP_8 = 207;
  MZ2_WIDOW2_BEAM_SWEEP_9 = 208;
  MZ2_WIDOW2_BEAM_SWEEP_10 = 209;
  MZ2_WIDOW2_BEAM_SWEEP_11 = 210;

  // ROGUE

  // CAK - monster_flash_offset is the only thing in m_flash.c
  // So the variable will be declared there and nowhere else.
  // Also it is never used in Capture The Flag.
  // It was here originally

  // temp entity events
  //
  // Temp entity events are for things that happen
  // at a location seperate from any existing entity.
  // Temporary entity messages are explicitly contype = recorded
  // and broadcast.
type
  temp_event_t = (
    TE_GUNSHOT,
    TE_BLOOD,
    TE_BLASTER,
    TE_RAILTRAIL,
    TE_SHOTGUN,
    TE_EXPLOSION1,
    TE_EXPLOSION2,
    TE_ROCKET_EXPLOSION,
    TE_GRENADE_EXPLOSION,
    TE_SPARKS,
    TE_SPLASH,
    TE_BUBBLETRAIL,
    TE_SCREEN_SPARKS,
    TE_SHIELD_SPARKS,
    TE_BULLET_SPARKS,
    TE_LASER_SPARKS,
    TE_PARASITE_ATTACK,
    TE_ROCKET_EXPLOSION_WATER,
    TE_GRENADE_EXPLOSION_WATER,
    TE_MEDIC_CABLE_ATTACK,
    TE_BFG_EXPLOSION,
    TE_BFG_BIGEXPLOSION,
    TE_BOSSTPORT,                       // used as '22' in a map, so DON'T RENUMBER!!!
    TE_BFG_LASER,
    TE_GRAPPLE_CABLE,
    TE_WELDING_SPARKS,
    TE_GREENBLOOD,
    TE_BLUEHYPERBLASTER,
    TE_PLASMA_EXPLOSION,
    TE_TUNNEL_SPARKS,
    //ROGUE
    TE_BLASTER2,
    TE_RAILTRAIL2,
    TE_FLAME,
    TE_LIGHTNING,
    TE_DEBUGTRAIL,
    TE_PLAIN_EXPLOSION,
    TE_FLASHLIGHT,
    TE_FORCEWALL,
    TE_HEATBEAM,
    TE_MONSTER_HEATBEAM,
    TE_STEAM,
    TE_BUBBLETRAIL2,
    TE_MOREBLOOD,
    TE_HEATBEAM_SPARKS,
    TE_HEATBEAM_STEAM,
    TE_CHAINFIST_SMOKE,
    TE_ELECTRIC_SPARKS,
    TE_TRACKER_EXPLOSION,
    TE_TELEPORT_EFFECT,
    TE_DBALL_GOAL,
    TE_WIDOWBEAMOUT,
    TE_NUKEBLAST,
    TE_WIDOWSPLASH,
    TE_EXPLOSION1_BIG,
    TE_EXPLOSION1_NP,
    TE_FLECHETTE
    //ROGUE
    );

const
  SPLASH_UNKNOWN = 0;
  SPLASH_SPARKS = 1;
  SPLASH_BLUE_WATER = 2;
  SPLASH_BROWN_WATER = 3;
  SPLASH_SLIME = 4;
  SPLASH_LAVA = 5;
  SPLASH_BLOOD = 6;

  // sound channels
  // channel 0 never willingly overrides
  // other channels (1-7) allways override a playing sound on that channel
const
  CHAN_AUTO = 0;
  CHAN_WEAPON = 1;
  CHAN_VOICE = 2;
  CHAN_ITEM = 3;
  CHAN_BODY = 4;
  // modifier flags
  CHAN_NO_PHS_ADD = 8;                  // send to all clients, not just ones in PHS (ATTN 0 will also do this)
  CHAN_RELIABLE = 16;                   // send by reliable message, not datagram

  // sound attenuation values
  ATTN_NONE: Single = 0;                // full volume the entire level
  ATTN_NORM: Single = 1;
  ATTN_IDLE: Single = 2;
  ATTN_STATIC: Single = 3;              // diminish very rapidly with distance

  // player_state->stats[] indexes
  STAT_HEALTH_ICON = 0;
  STAT_HEALTH = 1;
  STAT_AMMO_ICON = 2;
  STAT_AMMO = 3;
  STAT_ARMOR_ICON = 4;
  STAT_ARMOR = 5;
  STAT_SELECTED_ICON = 6;
  STAT_PICKUP_ICON = 7;
  STAT_PICKUP_STRING = 8;
  STAT_TIMER_ICON = 9;
  STAT_TIMER = 10;
  STAT_HELPICON = 11;
  STAT_SELECTED_ITEM = 12;
  STAT_LAYOUTS = 13;
  STAT_FRAGS = 14;
  STAT_FLASHES = 15;                    // cleared each frame, 1 = health, 2 = armor
  STAT_CHASE = 16;
  STAT_SPECTATOR = 17;

  MAX_STATS = q_shared_add.MAX_STATS;

  // dmflags->value flags
  DF_NO_HEALTH = $00000001;             // 1
  DF_NO_ITEMS = $00000002;              // 2
  DF_WEAPONS_STAY = $00000004;          // 4
  DF_NO_FALLING = $00000008;            // 8
  DF_INSTANT_ITEMS = $00000010;         // 16
  DF_SAME_LEVEL = $00000020;            // 32
  DF_SKINTEAMS = $00000040;             // 64
  DF_MODELTEAMS = $00000080;            // 128
  DF_NO_FRIENDLY_FIRE = $00000100;      // 256
  DF_SPAWN_FARTHEST = $00000200;        // 512
  DF_FORCE_RESPAWN = $00000400;         // 1024
  DF_NO_ARMOR = $00000800;              // 2048
  DF_ALLOW_EXIT = $00001000;            // 4096
  DF_INFINITE_AMMO = $00002000;         // 8192
  DF_QUAD_DROP = $00004000;             // 16384
  DF_FIXED_FOV = $00008000;             // 32768

  // RAFAEL
  DF_QUADFIRE_DROP = $00010000;         // 65536

  //ROGUE
const
  DF_NO_MINES = $00020000;
  DF_NO_STACK_DOUBLE = $00040000;
  DF_NO_NUKES = $00080000;
  DF_NO_SPHERES = $00100000;
  //ROGUE

  // player_state_t is the information needed in addition to pmove_state_t
  // to rendered a view.  There will only be 10 player_state_t sent each second,
  // but the number of pmove_state_t changes will be reletive to client
  // frame rates
  // this structure needs to be communicated bit-accurate
  // from the server to the client to guarantee that
  // prediction stays in sync, so no floats are used.
  // if any part of the game code modifies this struct, it
  // will result in a prediction error of some degree.

const
  MAXTOUCH = q_shared_add.MAXTOUCH;

type

  // a trace is returned when a box is swept through the world
  trace_p = q_shared_add.trace_p;
  trace_t = q_shared_add.trace_t;

  pmove_p = q_shared_add.pmove_p;
  pmove_t = q_shared_add.pmove_t;

  (*
  ROGUE - VERSIONS
  1234   08/13/1998      Activision
  1235   08/14/1998      Id Software
  1236   08/15/1998      Steve Tietze
  1237   08/15/1998      Phil Dobranski
  1238   08/15/1998      John Sheley
  1239   08/17/1998      Barrett Alexander
  1230   08/17/1998      Brandon Fish
  1245   08/17/1998      Don MacAskill
  1246   08/17/1998      David "Zoid" Kirsch
  1247   08/17/1998      Manu Smith
  1248   08/17/1998      Geoff Scully
  1249   08/17/1998      Andy Van Fossen
  1240   08/20/1998      Activision Build 2
  1256   08/20/1998      Ranger Clan
  1257   08/20/1998      Ensemble Studios
  1258   08/21/1998      Robert Duffy
  1259   08/21/1998      Stephen Seachord
  1250   08/21/1998      Stephen Heaslip
  1267   08/21/1998      Samir Sandesara
  1268   08/21/1998      Oliver Wyman
  1269   08/21/1998      Steven Marchegiano
  1260   08/21/1998      Build #2 for Nihilistic
  1278   08/21/1998      Build #2 for Ensemble

  9999   08/20/1998      Internal Use
  *)
const
  ROGUE_VERSION_ID = 1278;
  ROGUE_VERSION_STRING = '08/21/1998 Beta 2 for Ensemble';

  // ROGUE
  (*
  ==========================================================

    ELEMENTS COMMUNICATED ACROSS THE NET

  ==========================================================
  *)

function ANGLE2SHORT(x: Single): Word;
function SHORT2ANGLE(x: Word): Single;

//
// config strings are a general means of communication from
// the server to all connected clients.
// Each config string can be at most MAX_QPATH characters.
//
const
  CS_NAME = 0;
  CS_CDTRACK = 1;
  CS_SKY = 2;
  CS_SKYAXIS = 3;                       // %f %f %f format
  CS_SKYROTATE = 4;
  CS_STATUSBAR = 5;                     // display program string

  CS_AIRACCEL = 29;                     // air acceleration control
  CS_MAXCLIENTS = 30;
  CS_MAPCHECKSUM = 31;                  // for catching cheater maps

  CS_MODELS = 32;
  CS_SOUNDS = (CS_MODELS + MAX_MODELS);
  CS_IMAGES = (CS_SOUNDS + MAX_SOUNDS);
  CS_LIGHTS = (CS_IMAGES + MAX_IMAGES);
  CS_ITEMS = (CS_LIGHTS + MAX_LIGHTSTYLES);
  CS_PLAYERSKINS = (CS_ITEMS + MAX_ITEMS);
  CS_GENERAL = (CS_PLAYERSKINS + MAX_CLIENTS);
  MAX_CONFIGSTRINGS = (CS_GENERAL + MAX_GENERAL);

  // ==================
  // PGM
const
  VIDREF_GL = 1;
  VIDREF_SOFT = 2;
  VIDREF_OTHER = 3;

{$IFNDEF RENDERERDLL}
var
  vidref_val: Integer;                  // CAK - external for cl_ents.c
{$ENDIF}
  // PGM
  // ==================

procedure DelphiStrFmt(buf: PChar; fmt: PChar; args: array of const);

implementation

uses
  CPas,
{$IFDEF GAMEDLL}
  g_main,                               // <- we are compiling gamex86.dll
{$ELSE}
{$IFDEF RENDERERDLL}
  {$IFDEF REF_GL}
  gl_rmain,
  {$ENDIF}
  {$IFDEF REF_SOFT}
  r_main,
  {$ENDIF}
{$ELSE}
  Common,
{$ENDIF}
{$ENDIF}
  SysUtils;

{
  DelphiStrFmt
  - Delphi's StrFmt routine don't understand %i parameter, so we need to
    convert them to %d (which is same).
}

procedure DelphiStrFmt(buf: PChar; fmt: PChar; args: array of const);
var
  p, p2: PChar;
begin
  buf^ := #0;
  try
    { Replace (delphi)unsafe %i with %d }
    p := AllocMem(StrLen(fmt) + 1);
    StrCopy(p, fmt);
    p2 := p;
    while p2^ <> #0 do
    begin
      if (p2^ = '%') then
      begin
        Inc(p2);
        { Skip length part in format (example: %7.2f) }
        while (p2^ in ['0'..'9', '.']) do
          Inc(p2);
        { i->d: i and d are 100% equivalent}
        if p2^ = 'i' then
          p2^ := 'd';
        { c->s: c means one character, we will convert it to s(tring) }
        if p2^ = 'c' then
          p2^ := 's';
      end;
      Inc(p2);
    end;
    StrFmt(buf, p, args);
    FreeMem(p);
  except
    // Juha: This is just to find out all of the bugs in our routine.
    on E: Exception do
      Com_Printf(PChar('Exception in q_shared.DelphiStrFmt!'), []);
  end;
end;

function IS_NAN(x: single): qboolean;
begin
  Result := (PLongInt(@x)^ and nanmask) = nanmask;
end;

function ANGLE2SHORT(x: Single): Word;
begin
  Result := Round(x * 65536 / 360) and 65535;
end;

function SHORT2ANGLE(x: Word): Single;
begin
  Result := x * 360 / 65536;
end;

function DEG2RAD(a: extended): extended;
begin
  Result := a * M_PI / 180;
end;

procedure VectorClear(var a: vec3_t);
begin
  a[0] := 0;
  a[1] := 0;
  a[2] := 0;
end;

procedure VectorNegate(const a: vec3_t; var b: vec3_t);
begin
  b[0] := -a[0];
  b[1] := -a[1];
  b[2] := -a[2];
end;

procedure VectorSet(var v: vec3_t; x, y, z: vec_t);
begin
  v[0] := x;
  v[1] := y;
  v[2] := z;
end;

// CAK - math functions, missing in Delphi 3

function ceil(const x: Single): Integer;
begin
  Result := Integer(Trunc(x));
  if Frac(x) > 0 then
    Inc(Result);
end;

function floor(const x: Single): Integer;
begin
  Result := Integer(Trunc(x));
  if Frac(x) < 0 then
    Dec(Result);
end;

//============================================================================

procedure RotatePointAroundVector(var dst: vec3_t; const dir, point: vec3_t; degrees: single);
var
  m, im, zrot, tmpmat, rot: matrix33;
  i: Integer;
  vr, vup, vf: vec3_t;
begin
  vf[0] := dir[0];
  vf[1] := dir[1];
  vf[2] := dir[2];

  PerpendicularVector(vr, dir);
  CrossProduct(vr, vf, vup);

  m[0][0] := vr[0];
  m[1][0] := vr[1];
  m[2][0] := vr[2];

  m[0][1] := vup[0];
  m[1][1] := vup[1];
  m[2][1] := vup[2];

  m[0][2] := vf[0];
  m[1][2] := vf[1];
  m[2][2] := vf[2];

  Move(m, im, SizeOf(im));

  im[0][1] := m[1][0];
  im[0][2] := m[2][0];
  im[1][0] := m[0][1];
  im[1][2] := m[2][1];
  im[2][0] := m[0][2];
  im[2][1] := m[1][2];

  FillChar(zrot, sizeof(zrot), 0);
  zrot[0][0] := 1;
  zrot[1][1] := 1;
  zrot[2][2] := 1;

  zrot[0][0] := cos(DEG2RAD(degrees));
  zrot[0][1] := sin(DEG2RAD(degrees));
  zrot[1][0] := -sin(DEG2RAD(degrees));
  zrot[1][1] := cos(DEG2RAD(degrees));

  R_ConcatRotations(m, zrot, tmpmat);
  R_ConcatRotations(tmpmat, im, rot);

  for i := 0 to 2 do
  begin
    dst[i] := rot[i][0] * point[0] + rot[i][1] * point[1] + rot[i][2] * point[2];
  end;
end;

procedure AngleVectors(const angles: vec3_t; forwards, right, up: vec3_p);
var
  sr, sp, sy, cr, cp, cy: single;       // static to help MS compiler fp bugs
  angle: single;
begin
  angle := angles[YAW] * (M_PI * 2 / 360);
  sy := sin(angle);
  cy := cos(angle);
  angle := angles[PITCH] * (M_PI * 2 / 360);
  sp := sin(angle);
  cp := cos(angle);
  angle := angles[ROLL] * (M_PI * 2 / 360);
  sr := sin(angle);
  cr := cos(angle);

  if (forwards <> nil) then
  begin
    forwards[0] := cp * cy;
    forwards[1] := cp * sy;
    forwards[2] := -sp;
  end;
  if (right <> nil) then
  begin
    right[0] := (-1 * sr * sp * cy + -1 * cr * -sy);
    right[1] := (-1 * sr * sp * sy + -1 * cr * cy);
    right[2] := -1 * sr * cp;
  end;
  if (up <> nil) then
  begin
    up[0] := (cr * sp * cy + -sr * -sy);
    up[1] := (cr * sp * sy + -sr * cy);
    up[2] := cr * cp;
  end;
end;

procedure ProjectPointOnPlane(var dst: vec3_t; const p, normal: vec3_t);
var
  d: single;
  n: vec3_t;
  inv_denom: single;
begin
  inv_denom := 1 / DotProduct(normal, normal);
  d := DotProduct(normal, p) * inv_denom;

  n[0] := normal[0] * inv_denom;
  n[1] := normal[1] * inv_denom;
  n[2] := normal[2] * inv_denom;

  dst[0] := p[0] - d * n[0];
  dst[1] := p[1] - d * n[1];
  dst[2] := p[2] - d * n[2];
end;

(*
** assumes "src" is normalized
*)

procedure PerpendicularVector(var dst: vec3_t; const src: vec3_t);
var
  pos, i: Integer;
  minelem: single;
  tempvec: vec3_t;
begin
  minelem := 1;

  (*
  ** find the smallest magnitude axially aligned vector
  *)
  pos := 0;
  for i := 0 to 2 do
  begin
    if abs(src[i]) < minelem then
    begin
      pos := i;
      minelem := abs(src[i]);
    end;
  end;
  tempvec[0] := 0;
  tempvec[1] := 0;
  tempvec[2] := 0;
  tempvec[pos] := 1;

  (*
  ** project the point onto the plane defined by src
  *)
  ProjectPointOnPlane(dst, tempvec, src);

  (*
  ** normalize the result
  *)
  VectorNormalize(dst);
end;

(*
================
R_ConcatRotations
================
*)

procedure R_ConcatRotations(const in1, in2: matrix33; var out_: matrix33);
begin
  out_[0][0] := in1[0][0] * in2[0][0] + in1[0][1] * in2[1][0] +
    in1[0][2] * in2[2][0];
  out_[0][1] := in1[0][0] * in2[0][1] + in1[0][1] * in2[1][1] +
    in1[0][2] * in2[2][1];
  out_[0][2] := in1[0][0] * in2[0][2] + in1[0][1] * in2[1][2] +
    in1[0][2] * in2[2][2];
  out_[1][0] := in1[1][0] * in2[0][0] + in1[1][1] * in2[1][0] +
    in1[1][2] * in2[2][0];
  out_[1][1] := in1[1][0] * in2[0][1] + in1[1][1] * in2[1][1] +
    in1[1][2] * in2[2][1];
  out_[1][2] := in1[1][0] * in2[0][2] + in1[1][1] * in2[1][2] +
    in1[1][2] * in2[2][2];
  out_[2][0] := in1[2][0] * in2[0][0] + in1[2][1] * in2[1][0] +
    in1[2][2] * in2[2][0];
  out_[2][1] := in1[2][0] * in2[0][1] + in1[2][1] * in2[1][1] +
    in1[2][2] * in2[2][1];
  out_[2][2] := in1[2][0] * in2[0][2] + in1[2][1] * in2[1][2] +
    in1[2][2] * in2[2][2];
end;

(*
================
R_ConcatTransforms
================
*)

procedure R_ConcatTransforms(const in1, in2: matrix34; var out_: matrix34);
begin
  out_[0][0] := in1[0][0] * in2[0][0] + in1[0][1] * in2[1][0] +
    in1[0][2] * in2[2][0];
  out_[0][1] := in1[0][0] * in2[0][1] + in1[0][1] * in2[1][1] +
    in1[0][2] * in2[2][1];
  out_[0][2] := in1[0][0] * in2[0][2] + in1[0][1] * in2[1][2] +
    in1[0][2] * in2[2][2];
  out_[0][3] := in1[0][0] * in2[0][3] + in1[0][1] * in2[1][3] +
    in1[0][2] * in2[2][3] + in1[0][3];
  out_[1][0] := in1[1][0] * in2[0][0] + in1[1][1] * in2[1][0] +
    in1[1][2] * in2[2][0];
  out_[1][1] := in1[1][0] * in2[0][1] + in1[1][1] * in2[1][1] +
    in1[1][2] * in2[2][1];
  out_[1][2] := in1[1][0] * in2[0][2] + in1[1][1] * in2[1][2] +
    in1[1][2] * in2[2][2];
  out_[1][3] := in1[1][0] * in2[0][3] + in1[1][1] * in2[1][3] +
    in1[1][2] * in2[2][3] + in1[1][3];
  out_[2][0] := in1[2][0] * in2[0][0] + in1[2][1] * in2[1][0] +
    in1[2][2] * in2[2][0];
  out_[2][1] := in1[2][0] * in2[0][1] + in1[2][1] * in2[1][1] +
    in1[2][2] * in2[2][1];
  out_[2][2] := in1[2][0] * in2[0][2] + in1[2][1] * in2[1][2] +
    in1[2][2] * in2[2][2];
  out_[2][3] := in1[2][0] * in2[0][3] + in1[2][1] * in2[1][3] +
    in1[2][2] * in2[2][3] + in1[2][3];
end;

//============================================================================

function Q_fabs(f: single): single;
var
  tmp: LongInt;
begin
  tmp := PLongInt(@f)^;
  tmp := tmp and $7FFFFFFF;
  result := PSingle(@tmp)^;
end;

function fabs(f: single): single;
var
  tmp: LongInt;
begin
  tmp := PLongInt(@f)^;
  tmp := tmp and $7FFFFFFF;
  result := PSingle(@tmp)^;
end;

function Q_ftol(f: single): LongInt;
begin
  Result := Trunc(f);
end;

(*
===============
LerpAngle

===============
*)

function LerpAngle(a2, a1, frac: single): single;
begin
  if a1 - a2 > 180 then
    a1 := a1 - 360;
  if a1 - a2 < -180 then
    a1 := a1 + 360;
  result := a2 + frac * (a1 - a2);
end;

function anglemod(a: single): single;
begin
  (*
    if a >= 0 then
      a:=a - 360*trunc(a/360)
    else
      a:=a + 360*( 1 + trunc(-a/360) );
  *)
  a := (360 / 65536) * (trunc(a * (65536 / 360)) and 65535);
  result := a;
end;

// CAK - DANGER WILL ROBINSON!!!!!!!!!
// CAK - These could cause many errors, so I removed them.
// CAK - This was a bug in q_shared.c
//var i: Integer;
//var corners: array[0..1] of vec3_t;

// this is the slow, general version

function BoxOnPlaneSide2(var emins, emaxs: vec3_t; p: cplane_p): Integer;
var
  i: Integer;
  dist1, dist2: single;
  sides: integer;
  corners: array[0..1] of vec3_t;
begin
  for i := 0 to 2 do
  begin
    if p^.normal[i] < 0 then
    begin
      corners[0][i] := emins[i];
      corners[1][i] := emaxs[i];
    end
    else
    begin
      corners[1][i] := emins[i];
      corners[0][i] := emaxs[i];
    end;
  end;
  dist1 := DotProduct(p^.normal, corners[0]) - p^.dist;
  dist2 := DotProduct(p^.normal, corners[1]) - p^.dist;
  sides := 0;
  if dist1 >= 0 then
    sides := 1;
  if dist2 < 0 then
    sides := (sides or 2);

  result := sides;
end;

(*
==================
BoxOnPlaneSide

Returns 1, 2, or 1 + 2
==================
*)

function BoxOnPlaneSide(var emins, emaxs: vec3_t; p: cplane_p): Integer;
var
  dist1, dist2: single;
  sides: Integer;
begin
  // fast axial cases
  if p^._type < 3 then
  begin
    if p^.dist <= emins[p^._type] then
    begin
      result := 1;
      exit;
    end;
    if p^.dist >= emaxs[p^._type] then
    begin
      result := 2;
      exit;
    end;
    result := 3;
    exit;
  end;

  // general case
  case p^.signbits of
    0:
      begin
        dist1 := p^.normal[0] * emaxs[0] + p^.normal[1] * emaxs[1] + p^.normal[2] * emaxs[2];
        dist2 := p^.normal[0] * emins[0] + p^.normal[1] * emins[1] + p^.normal[2] * emins[2];
      end;
    1:
      begin
        dist1 := p^.normal[0] * emins[0] + p^.normal[1] * emaxs[1] + p^.normal[2] * emaxs[2];
        dist2 := p^.normal[0] * emaxs[0] + p^.normal[1] * emins[1] + p^.normal[2] * emins[2];
      end;
    2:
      begin
        dist1 := p^.normal[0] * emaxs[0] + p^.normal[1] * emins[1] + p^.normal[2] * emaxs[2];
        dist2 := p^.normal[0] * emins[0] + p^.normal[1] * emaxs[1] + p^.normal[2] * emins[2];
      end;
    3:
      begin
        dist1 := p^.normal[0] * emins[0] + p^.normal[1] * emins[1] + p^.normal[2] * emaxs[2];
        dist2 := p^.normal[0] * emaxs[0] + p^.normal[1] * emaxs[1] + p^.normal[2] * emins[2];
      end;
    4:
      begin
        dist1 := p^.normal[0] * emaxs[0] + p^.normal[1] * emaxs[1] + p^.normal[2] * emins[2];
        dist2 := p^.normal[0] * emins[0] + p^.normal[1] * emins[1] + p^.normal[2] * emaxs[2];
      end;
    5:
      begin
        dist1 := p^.normal[0] * emins[0] + p^.normal[1] * emaxs[1] + p^.normal[2] * emins[2];
        dist2 := p^.normal[0] * emaxs[0] + p^.normal[1] * emins[1] + p^.normal[2] * emaxs[2];
      end;
    6:
      begin
        dist1 := p^.normal[0] * emaxs[0] + p^.normal[1] * emins[1] + p^.normal[2] * emins[2];
        dist2 := p^.normal[0] * emins[0] + p^.normal[1] * emaxs[1] + p^.normal[2] * emaxs[2];
      end;
    7:
      begin
        dist1 := p^.normal[0] * emins[0] + p^.normal[1] * emins[1] + p^.normal[2] * emins[2];
        dist2 := p^.normal[0] * emaxs[0] + p^.normal[1] * emaxs[1] + p^.normal[2] * emaxs[2];
      end;
  else
    begin
      dist1 := 0;
      dist2 := 0;                       // shut up compiler
      assert(false, 'BoxOnPlaneSide error: invalid sign bits, (Carl Kenner)');
    end;
  end;

  sides := 0;
  if dist1 >= p^.dist then
    sides := 1;
  if dist2 < p^.dist then
    sides := sides or 2;

  assert(sides <> 0, 'BoxOnPlaneSide error: sides must be zero, (Carl Kenner)');

  result := sides;
end;

// CAK - There was an assembly language version here too, but I didn't
// CAK - bother converting it. Sorry.

// MACRO - Calls the original function

function BOX_ON_PLANE_SIDE(var emins, emaxs: vec3_t; p: cplane_p): Integer;
begin
  Result := BoxOnPlaneSide(emins, emaxs, p);
end;

procedure ClearBounds(var mins, maxs: vec3_t);
begin
  mins[0] := 99999;
  mins[1] := 99999;
  mins[2] := 99999;
  maxs[0] := -99999;
  maxs[1] := -99999;
  maxs[2] := -99999;
end;

procedure AddPointToBounds(const v: vec3_t; var mins, maxs: vec3_t);
var
  i: Integer;
  val: vec_t;
begin
  for i := 0 to 2 do
  begin
    val := v[i];
    if val < mins[i] then
      mins[i] := val;
    if val > maxs[i] then
      maxs[i] := val;
  end;
end;

function VectorCompare(const v1, v2: vec3_t): integer;
begin
  if (v1[0] <> v2[0]) or (v1[1] <> v2[1]) or (v1[2] <> v2[2]) then
    result := 0
  else
    result := 1;
end;

function VectorNormalize(var v: vec3_t): vec_t;
var
  length, ilength: single;
begin
  length := v[0] * v[0] + v[1] * v[1] + v[2] * v[2];
  length := sqrt(length);               // FIXME

  if length <> 0 then
  begin
    ilength := 1 / length;
    v[0] := v[0] * ilength;
    v[1] := v[1] * ilength;
    v[2] := v[2] * ilength;
  end;

  result := length;
end;

function VectorNormalize2(const v: vec3_t; var out_: vec3_t): vec_t;
var
  length, ilength: single;
begin
  length := v[0] * v[0] + v[1] * v[1] + v[2] * v[2];
  length := sqrt(length);               // FIXME

  if length <> 0 then
  begin
    ilength := 1 / length;
    out_[0] := v[0] * ilength;
    out_[1] := v[1] * ilength;
    out_[2] := v[2] * ilength;
  end;

  result := length;
end;

procedure VectorMA(const veca: vec3_t; scale: single; const vecb: vec3_t; var vecc: vec3_t);
begin
  vecc[0] := veca[0] + scale * vecb[0];
  vecc[1] := veca[1] + scale * vecb[1];
  vecc[2] := veca[2] + scale * vecb[2];
end;

function _DotProduct(const v1, v2: vec3_t): vec_t;
begin
  result := v1[0] * v2[0] + v1[1] * v2[1] + v1[2] * v2[2];
end;

function DotProduct(const v1, v2: vec3_t): vec_t;
begin
  result := v1[0] * v2[0] + v1[1] * v2[1] + v1[2] * v2[2];
end;

procedure _VectorSubtract(const veca, vecb: vec3_t; var out_: vec3_t);
begin
  out_[0] := veca[0] - vecb[0];
  out_[1] := veca[1] - vecb[1];
  out_[2] := veca[2] - vecb[2];
end;

procedure VectorSubtract(const veca, vecb: vec3_t; var out_: vec3_t);
begin
  out_[0] := veca[0] - vecb[0];
  out_[1] := veca[1] - vecb[1];
  out_[2] := veca[2] - vecb[2];
end;

procedure VectorSubtract(const veca, vecb: array of smallint; var out_: array of integer);
begin
  out_[0] := veca[0] - vecb[0];
  out_[1] := veca[1] - vecb[1];
  out_[2] := veca[2] - vecb[2];
end;

procedure _VectorAdd(const veca, vecb: vec3_t; var out_: vec3_t);
begin
  out_[0] := veca[0] + vecb[0];
  out_[1] := veca[1] + vecb[1];
  out_[2] := veca[2] + vecb[2];
end;

procedure VectorAdd(const veca, vecb: vec3_t; var out_: vec3_t);
begin
  out_[0] := veca[0] + vecb[0];
  out_[1] := veca[1] + vecb[1];
  out_[2] := veca[2] + vecb[2];
end;

procedure _VectorCopy(const _in: vec3_t; var out_: vec3_t);
begin
  out_[0] := _in[0];
  out_[1] := _in[1];
  out_[2] := _in[2];
end;

procedure VectorCopy(const _in: vec3_t; var out_: vec3_t);
begin
  out_[0] := _in[0];
  out_[1] := _in[1];
  out_[2] := _in[2];
end;

procedure VectorCopy(const _in: vec3_t; var out_: array of smallint);
begin
  out_[0] := Trunc(_in[0]);
  out_[1] := Trunc(_in[1]);
  out_[2] := Trunc(_in[2]);
end;

procedure VectorCopy(const _in: array of smallint; var out_: array of smallint);
begin
  out_[0] := _in[0];
  out_[1] := _in[1];
  out_[2] := _in[2];
end;

procedure VectorCopy(const _in: array of smallint; var out_: vec3_t);
begin
  out_[0] := _in[0];
  out_[1] := _in[1];
  out_[2] := _in[2];
end;

procedure CrossProduct(const v1, v2: vec3_t; var cross: vec3_t);
begin
  cross[0] := v1[1] * v2[2] - v1[2] * v2[1];
  cross[1] := v1[2] * v2[0] - v1[0] * v2[2];
  cross[2] := v1[0] * v2[1] - v1[1] * v2[0];
end;

//double sqrt(double x);

function VectorLength(const v: vec3_t): vec_t;
var
  i: Integer;
  length: single;
begin
  length := 0;
  for i := 0 to 2 do
    length := length + v[i] * v[i];
  length := sqrt(length);               // FIXME
  result := length;
end;

procedure VectorInverse(var v: vec3_t);
begin
  v[0] := -v[0];
  v[1] := -v[1];
  v[2] := -v[2];
end;

procedure VectorScale(const _in: vec3_t; const scale: vec_t; var out_: vec3_t);
begin
  out_[0] := _in[0] * scale;
  out_[1] := _in[1] * scale;
  out_[2] := _in[2] * scale;
end;

function Q_log2(val: Integer): Integer;
var
  answer: Integer;
begin
  answer := 0;
  val := val shr 1;
  while val <> 0 do
  begin
    inc(answer);
    val := val shr 1;
  end;
  Result := answer;
end;

//====================================================================================

(*
============
COM_SkipPath
============
*)

function COM_SkipPath(pathname: PChar): PChar;
var
  last: PChar;
begin
  last := pathname;
  while pathname^ <> #0 do
  begin
    if pathname^ = '/' then
    begin
      last := pathname;
      inc(last);
    end;
    inc(pathname);
  end;
  Result := last;
end;

(*
============
COM_StripExtension
============
*)

procedure COM_StripExtension(in_, out_: PChar);
begin
  while (in_^ <> #0) and (in_^ <> '.') do
  begin
    out_^ := in_^;
    inc(in_);
    inc(out_);
  end;
  out_^ := #0;
end;

(*
============
COM_FileExtension
============
*)
var
  exten: array[0..7] of char;

function COM_FileExtension(_in: PChar): PChar;
var
  i: Integer;
begin
  while (_in^ <> #0) and (_in^ <> '.') do
    inc(_in);
  if (_in^ = #0) then
  begin
    Result := '';
    exit;
  end;
  inc(_in);
  i := 0;
  while (i < 7) and (_in^ <> #0) do
  begin
    exten[i] := _in^;
    inc(i);
    inc(_in);
  end;
  exten[i] := #0;
  Result := @exten;
end;

(*
============
COM_FileBase
============
*)

procedure COM_FileBase(in_, out_: PChar);
var
  s, s2: PChar;
begin
  s := in_;
  inc(s, strlen(in_) - 1);

  while (s <> in_) and (s^ <> '.') do
    dec(s);

  s2 := s;
  while (s2 <> in_) and (s2^ <> '/') do
    dec(s2);

  if LongInt(s) - LongInt(s2) < 2 then
    out_^ := #0
  else
  begin
    dec(s);
    strncpy(out_, Pointer(Cardinal(s2) + 1), Cardinal(s) - Cardinal(s2));
    out_[Cardinal(s) - Cardinal(s2)] := #0;
  end;
end;

(*
============
COM_FilePath

Returns the path up to, but not including the last /
============
*)

procedure COM_FilePath(in_, out_: PChar);
var
  s: PChar;
begin
  s := in_;
  inc(s, strlen(in_) - 1);

  while (s <> in_) and (s^ <> '/') do
    dec(s);

  strncpy(out_, in_, LongInt(s) - LongInt(in_));
  out_[LongInt(s) - LongInt(in_)] := #0;
end;

(*
==================
COM_DefaultExtension
==================
*)

procedure COM_DefaultExtension(path, extension: PChar);
var
  src: PChar;
begin
  //
  // if path doesn't have a .EXT, append extension
  // (extension should include the .)
  //
  src := path;
  inc(src, strlen(path) - 1);

  while (src^ <> '/') and (src <> path) do
  begin
    if (src^ = '.') then
      exit;                             // it has an extension
    dec(src);
  end;

  strcat(path, extension);
end;

(*
============================================================================

     BYTE ORDER FUNCTIONS

============================================================================
*)

var
  bigendien: qboolean;                  // NOTE SPELLING!!!!
  // can't just use function pointers, or dll linkage can
  // mess up when qcommon is included in multiple places
  _BigShort: function(L: SmallInt): SmallInt;
  _LittleShort: function(L: SmallInt): SmallInt;
  _BigLong: function(L: LongInt): LongInt;
  _LittleLong: function(L: LongInt): LongInt;
  _BigFloat: function(L: Single): Single;
  _LittleFloat: function(L: Single): Single;

function BigShort(L: SmallInt): SmallInt;
begin
  Result := _BigShort(L);
end;

function LittleShort(L: SmallInt): SmallInt;
begin
  Result := _LittleShort(L);
end;

function BigLong(L: LongInt): LongInt;
begin
  Result := _BigLong(L);
end;

function LittleLong(L: LongInt): LongInt;
begin
  Result := _LittleLong(L);
end;

function BigFloat(L: Single): Single;
begin
  Result := _BigFloat(L);
end;

function LittleFloat(L: Single): Single;
begin
  Result := _LittleFloat(L);
end;

function ShortSwap(L: SmallInt): SmallInt;
var
  b1, b2: Byte;
begin
  b1 := L and 255;
  b2 := (L shr 8) and 255;
  result := (b1 shl 8) + b2;
end;

function ShortNoSwap(L: SmallInt): SmallInt;
begin
  result := L
end;

function LongSwap(L: LongInt): LongInt;
var
  b1, b2, b3, b4: Byte;
begin
  b1 := L and 255;
  b2 := (L shr 8) and 255;
  b3 := (L shr 16) and 255;
  b4 := (L shr 24) and 255;
  result := (LongInt(b1) shl 24) + (LongInt(b2) shl 16) + (LongInt(b3) shl 8) + b4;
end;

function LongNoSwap(L: LongInt): LongInt;
begin
  result := L
end;

function FloatSwap(f: Single): Single;
type
  ba = array[0..3] of byte;
var
  dat1, dat2: ^ba;
begin
  dat1 := Pointer(@f);
  dat2 := Pointer(@result);
  dat2[0] := dat1[3];
  dat2[1] := dat1[2];
  dat2[2] := dat1[1];
  dat2[3] := dat1[0];
end;

function FloatNoSwap(f: Single): Single;
begin
  Result := f;
end;

(*
================
Swap_Init
================
*)

procedure Swap_Init;
var
  swaptest: array[0..1] of byte;
begin
  swaptest[0] := 1;
  swaptest[1] := 0;

  // set the byte swapping variables in a portable manner
  if PSmallInt(@SwapTest)^ = 1 then
  begin
    bigendien := false;
    @_BigShort := @ShortSwap;
    @_LittleShort := @ShortNoSwap;
    @_BigLong := @LongSwap;
    @_LittleLong := @LongNoSwap;
    @_BigFloat := @FloatSwap;
    @_LittleFloat := @FloatNoSwap;
  end
  else
  begin
    bigendien := true;
    @_BigShort := @ShortNoSwap;
    @_LittleShort := @ShortSwap;
    @_BigLong := @LongNoSwap;
    @_LittleLong := @LongSwap;
    @_BigFloat := @FloatNoSwap;
    @_LittleFloat := @FloatSwap;
  end;
end;

(*
============
va

does a varargs printf into a temp buffer, so I don't need to have
varargs versions of all text functions.
FIXME: make this buffer size safe someday
============
*)
{static}
var
  _string: array[0..1024 - 1] of char;

function va(format: PChar; const Args: array of const): PChar;
begin
  DelphiStrFmt(_string, format, args);
  Result := @_string;
end;

var
  com_token: array[0..MAX_TOKEN_CHARS - 1] of Char;

  (*
  ==============
  COM_Parse

  Parse a token out of a string
  ==============
  *)

function COM_Parse(var data_p: PChar): PChar; // CAK - WARNING!!!! WAS ^PChar
// data is an in/out parm, returns a parsed out token
var
  data: PChar;
  c: Char;
  len: Integer;
label
  skipwhite;
begin
  data := data_p;
  len := 0;
  com_token[0] := #0;

  if (data = nil) then
  begin
    data_p := nil;
    Result := '';
    exit;
  end;

  // skip whitespace
  skipwhite:
  c := data^;
  while c <= ' ' do
  begin
    if c = #0 then
    begin
      data_p := nil;
      Result := '';
      exit;
    end;
    inc(data);
    c := data^;
  end;

  // skip // comments
  if (c = '/') and (data[1] = '/') then
  begin
    while (data^ <> #0) and (data^ <> #13) and (data^ <> #10) do
    begin                               // CAK - '\n' can be #13 or #10
      inc(data);
    end;
    goto skipwhite;
  end;

  // handle quoted strings specially
  if (c = '"') then
  begin
    inc(data);
    while true do
    begin
      c := data^;
      inc(data);
      if (c = '"') or (c = #0) then
      begin
        com_token[len] := #0;
        data_p := data;
        result := com_token;
        exit;
      end;
      // 10-Jun-2002 Juha: NOTE, original quake2 has this bug as well. If you
      // send exactly MAX_TOKEN_CHARS length connect string, it will crash the
      // server. We might want to make this read "if (len<MAX_TOKEN_CHARS-1)".
      if (len < MAX_TOKEN_CHARS) then
      begin
        com_token[len] := c;
        inc(len);
      end;
    end;
  end;

  // parse a regular word
  repeat
    if len < MAX_TOKEN_CHARS then
    begin
      com_token[len] := c;
      inc(len);
    end;
    inc(data);
    c := data^;
  until c <= #32;

  if len = MAX_TOKEN_CHARS then
  begin
    Com_Printf('Token exceeded %i chars, discarded.'#10, [MAX_TOKEN_CHARS]);
    len := 0;
  end;
  com_token[len] := #0;

  data_p := data;
  result := com_token;
end;

(*
===============
Com_PageInMemory

===============
*)
var
  paged_total: Integer;                 // CAK - This variable is never initialised ANYWHERE
  // But as it's never used anywhere either, I guess
  // that doesn't matter. :-)
  // all it is used for is to ensure that one byte out
  // of every 4K pointed to by buffer is read, and
  // therefore in memory.

procedure Com_PageInMemory(buffer: PByte; size: Integer);
var
  i: Integer;
begin
  i := size - 1;
  while (i > 0) do
  begin
    paged_total := paged_total + PByteArray(buffer)[i];
    dec(i, 4096);
  end;
end;

(*
============================================================================

     LIBRARY REPLACEMENT FUNCTIONS

============================================================================
*)

// FIXME: replace all Q_stricmp with Q_strcasecmp

function Q_stricmp(s1, s2: PChar): Integer;
begin
  Result := strcmp(PChar(LowerCase(s1)), PChar(LowerCase(s2)));
end;

function Q_strncasecmp(s1, s2: PChar; n: integer): Integer;
var
  z1, z2: string;
begin
  z1 := s1;
  z2 := s2;
  z1 := lowercase(copy(z1, 1, n));
  z2 := lowercase(copy(z2, 1, n));
  if z1 = z2 then
    result := 0                         // strings are equal
  else
    result := -1;                       // strings not equal
end;

function Q_strcasecmp(s1, s2: PChar): Integer;
begin
  result := Q_strncasecmp(s1, s2, 99999);
end;

procedure Com_sprintf(dest: PChar; size: Integer; fmt: PChar; const Args: array of const);
var
  bigbuffer: array[0..$10000 - 1] of char;
  SLen: Integer;
begin
  DelphiStrFmt(bigbuffer, fmt, Args);
  SLen := StrLen(bigbuffer);
  move(bigbuffer, dest^, Min(size, SLen + 1));
  { Terminate string if needed }
  if SLen >= size then
    dest[size - 1] := #0;
end;

(*
=====================================================================

  INFO STRINGS

=====================================================================
*)

(*
===============
Info_ValueForKey

Searches the string for the given
key and returns the associated value, or an empty string.
===============
*)
var
  value: array[0..1, 0..511] of Char;   // use two buffers so compares
  valueindex: integer;                  // work without stomping on each other

function Info_ValueForKey(s, key: PChar): PChar;
var
  pkey: array[0..511] of Char;
  o: PChar;
begin
  valueindex := valueindex xor 1;
  if s^ = '\' then
    inc(s);
  while true do
  begin
    o := pkey;
    while (s^ <> '\') do
    begin
      if s^ = #0 then
      begin
        Result := '';
        exit;
      end;
      o^ := s^;
      inc(o);
      inc(s);
    end;
    o^ := #0;
    inc(s);

    o := value[valueindex];

    while (s^ <> '\') and (s^ <> #0) do
    begin
      if (s^ = #0) then
      begin
        result := '';
        exit;
      end;
      o^ := s^;
      inc(o);
      inc(s);
    end;
    o^ := #0;

    if (strcomp(key, pkey) = 0) then
    begin
      result := value[valueindex];
      exit;
    end;

    if s^ = #0 then
    begin
      result := '';
      exit;
    end;
    inc(s);
  end;
end;

procedure Info_RemoveKey(s, key: PChar);
var
  start: PChar;
  pkey, value: array[0..511] of Char;
  o: PChar;
begin
  if (pos('\', key) <> 0) then
  begin
    Com_Printf('Can''t use a key with a \'#13#10);
    exit;
  end;

  while true do
  begin
    start := s;
    if (s^ = '\') then
      inc(s);
    o := pkey;
    while s^ <> '\' do
    begin
      if s^ = #0 then
        exit;
      o^ := s^;
      inc(o);
      inc(s);
    end {while};
    o^ := #0;
    inc(s);

    o := value;

    while (s^ <> '\') and (s^ <> #0) do
    begin
      if s^ = #0 then
        exit;
      o^ := s^;
      inc(o);
      inc(s);
    end;
    o^ := #0;

    if strcomp(key, pkey) = 0 then
    begin
      strcopy(start, s);                // remove this part
      exit;
    end;

    if s^ = #0 then
      exit;
  end {while};
end;

(*
==================
Info_Validate

Some characters are illegal in info strings because they
can mess up the server's parsing
==================
*)

function Info_Validate(s: PChar): qboolean;
begin
  if pos('"', s) > 0 then
    result := false
  else if pos(';', s) > 0 then
    result := false
  else
    result := true;
end;

procedure Info_SetValueForKey(s, key, value: PChar);
var
  newi: array[0..MAX_INFO_STRING - 1] of Char;
  v: PChar;
  c: Char;
  maxsize: Cardinal;
begin
  maxsize := MAX_INFO_STRING;
  if (strstr(key, '\') <> nil) or (strstr(value, '\') <> nil) then
  begin
    Com_Printf('Can''t use keys or values with a \'#10);
    exit;
  end;

  if strstr(key, ';') <> nil then
  begin
    Com_Printf('Can''t use keys or values with a semicolon'#10); // CAK - BUG: VALUES NOT MENTIONED
    exit;
  end;

  if (strstr(key, '"') <> nil) or (strstr(value, '"') <> nil) then
  begin
    Com_Printf('Can''t use keys or values with a "'#10);
    exit;
  end;

  if (strlen(key) > MAX_INFO_KEY - 1) or (strlen(value) > MAX_INFO_KEY - 1) then
  begin
    Com_Printf('Keys and values must be < 64 characters.'#10);
    exit;
  end;

  Info_RemoveKey(s, key);
  if (value = nil) or (strlen(value) = 0) then
    exit;

  Com_sprintf(newi, sizeof(newi), '\%s\%s', [key, value]);

  if strlen(newi) + strlen(s) > maxsize then
  begin
    Com_Printf('Info string length exceeded'#10);
    exit;
  end;

  // only copy ascii values
  Inc(s, strlen(s));
  v := newi;
  while v^ <> #0 do
  begin
    c := v^;
    inc(v);
    c := Chr(ord(c) and 127);           // strip high bits
    if (c >= #32) and (c <= #127) then
    begin
      s^ := c;
      inc(s);
    end;
  end;
  s^ := #0;
end;

//====================================================================

initialization
  // Check the size of standard types:
  Assert(sizeof(char) = 1);
  Assert(sizeof(integer) = 4);
  Assert(sizeof(single) = 4);
  Assert(sizeof(cardinal) = 4);
  Assert(sizeof(pointer) = 4);
  Assert(sizeof(smallint) = 2);
  // Check the size of types defined in q_shared.h
  Assert(sizeof(byte) = 1);
  Assert(sizeof(q_shared.qboolean) = 4);
  Assert(sizeof(q_shared.multicast_t) = 4);
  Assert(sizeof(q_shared.vec_t) = 4);
  Assert(sizeof(q_shared.vec3_t) = 12);
  Assert(sizeof(q_shared.vec5_t) = 20);
  Assert(sizeof(q_shared.fixed4_t) = 4);
  Assert(sizeof(q_shared.fixed8_t) = 4);
  Assert(sizeof(q_shared.fixed16_t) = 4);
  Assert(sizeof(q_shared.cvar_t) = 28);
  Assert(sizeof(q_shared.cplane_t) = 20);
  Assert(sizeof(q_shared.cmodel_t) = 40);
  Assert(sizeof(q_shared.csurface_t) = 24);
  Assert(sizeof(q_shared.mapsurface_t) = 56);
  Assert(sizeof(q_shared.trace_t) = 56);
  Assert(sizeof(q_shared.pmtype_t) = 4);
{$IFNDEF GAMEDLL}
  Assert(sizeof(q_shared.pmove_state_t) = 28);
{$ENDIF}
  Assert(sizeof(q_shared.usercmd_t) = 16);
  Assert(sizeof(q_shared.pmove_t) = 240);
  Assert(sizeof(q_shared.temp_event_t) = 4);
  Assert(sizeof(q_shared.entity_event_t) = 4);
  Assert(sizeof(q_shared.entity_state_t) = 84);
  Assert(sizeof(q_shared.player_state_t) = 184);

  // Perform Initialisation of Endien Routines
  // needed for LittleLong, LittleShort, LittleFloat, BigLong, BigShort, BigFloat
  Swap_Init;
end.
