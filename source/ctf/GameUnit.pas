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
//This is the game.h file from the GAME directory
//  This unit designed to be compatible with both Game and CTF build
//  targets. By default unit compiles to GAME build target. To build
//  for CTF one should define "CTF" global conditional define.

//Clootie: "Can you change Game.pas to GameUnit.pas (or something like it) -
//  because there is "game" global variable in "g_main" (and it's used
//  already in some units) - so we have conflicting names."
{----------------------------------------------------------------------------}
{                                                                            }
{ File(s): game\game.h                                                       }
{          ctf\game.h (if you define CTF)                                    }
{ Content: game dll information visible to server                            }
{                                                                            }
{ Initial conversion by: Gutter (jeanspayette@videotron.ca)                  }
{ Initial conversion on: 17-Jan-2002                                         }
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
{ Updated on: 26-Feb-2002                                                    }
{ Updated by: Carl A Kenner                                                  }
{ With sugestions by: Clootie (Alexey Barkovoy) (clootie@reactor.ru)         }
{                                                                            }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{ none                                                                       }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{ none                                                                       }
{----------------------------------------------------------------------------}
{ * Note:                                                                    }
{ 1.) Gutter - On line (120 to 124 and 133 in that file)                     }
{     argument we passed as '...'. I changed that to arg: array of PChar,    }
{     but I am not sure that its right                                       }
{                                                                            }
{     CAK - No, it's not the right thing. Then you just have one pointer on  }
{     the stack which points to the fist PChar.                              }
{     What we need to do is declare it as CDECL, and then leave out all the  }
{     optional parameters. When we want to read the parameters we will have  }
{     to do it manually in Assembly language. And when we want to call the   }
{     functions we have to push the parameters on the stack in assembly.     }
{     It's annoying, but PASCAL won't do it for us automatically.            }
{                                                                            }
{     You can use the gi_ functions I added instead to make things easier.   }
{     They accept a variable number of parameters in square brackets.        }
{----------------------------------------------------------------------------}
Unit GameUnit;

Interface
Uses g_local, q_shared;

Const
  GAME_API_VERSION = 3;

// edict->svflags

  SVF_NOCLIENT = $00000001; // don't send entity to clients, even if it has effects
  SVF_DEADMONSTER = $00000002; // treat as CONTENTS_DEADMONSTER for collision
  SVF_MONSTER = $00000004; // treat as CONTENTS_MONSTER for collision

//=======================================
// CAK - THIS PART IS FROM ctf
//       BUT NOT game
//=======================================
{$ifdef CTF}
//ZOID
  SVF_PROJECTILE = $00000008; // entity is simple projectile, used for network optimization
// if an entity is projectile, the model index/x/y/z/pitch/yaw are sent, encoded into
// seven (or eight) bytes.  This is to speed up projectiles.  Currently, only the
// hyperblaster makes use of this.  use for items that are moving with a constant
// velocity that don't change direction or model
//ZOID
{$endif}
//=======================================

// CAK - THESE WERE TAKEN FROM HERE AND MOVED TO g_local
// edict->solid values
type
  solid_t = g_local.solid_t;
  solid_p = g_local.solid_p;
  psolid_t = g_local.psolid_t;
  TSolid = g_local.TSolid;
  PSolid = g_local.Psolid;
  solid_at = g_local.solid_at;
  solid_a = g_local.solid_a;
  TSolidArray = g_local.TSolidArray;
  PSolidArray = g_local.PSolidArray;



//===============================================================

// CAK - THESE WERE TAKEN FROM HERE AND MOVED TO g_local
// link_t is only used for entity area links now
type
  link_s = g_local.link_s;
  link_t = g_local.link_t;
  link_p = g_local.link_p;
  plink_s = g_local.plink_s;
  plink_t = g_local.plink_t;
  TLink = g_local.TLink;
  PLink = g_local.PLink;
  link_at = g_local.link_at;
  link_a = g_local.link_a;
  TLinkArray = g_local.TLinkArray;
  PLinkArray = g_local.PLinkArray;

// CAK - THIS WAS TAKEN FROM HERE AND MOVED TO g_local
const
  MAX_ENT_CLUSTERS = g_local.MAX_ENT_CLUSTERS;

//===============================================================


type
{$define GAME_INCLUDE}
{$ifndef GAME_INCLUDE}

// CAK - this is the stupid small version of gclient_t and edict_t

  gclient_p = ^gclient_t;
  pgclient_s = gclient_p;
  gclient_s = record
     ps: player_state_t; // communicated by server to clients
     ping: Integer;
      // the game dll can add anything it wants after
      // this point in the structure
  end;
  gclient_t = gclient_s;
  pgclient_t = gclient_p;
  TGClient = gclient_t;
  PGClient = gclient_p;
  gclient_at = array[0..MaxInt div sizeof(gclient_t)-1] of gclient_t;
  gclient_a = ^gclient_at;
  TGClientArray = gclient_at;
  PGClientArray = gclient_a;

  edict_p = ^edict_t;
  pedict_s = edict_p;
  edict_s = record
    s: entity_state_t;
    client: gclient_p;
    inuse: qboolean;
    linkcount: Integer;

    // FIXME: move these fields to a server private sv_entity_t
    area: link_t; // linked to a division node or leaf

    num_clusters: Integer;    // if -1, use headnode instead
    clusternums   : Array[0..MAX_ENT_CLUSTERS-1] of Integer; // CAK - Did -1
    headnode: Integer;     // unused if num_clusters != -1
    areanum,
    areanum2: Integer;

    //================================

    svflags: Integer; // SVF_NOCLIENT, SVF_DEADMONSTER, SVF_MONSTER, etc
    mins, maxs: vec3_t;
    absmin, absmax, size: vec3_t;
    solid: solid_t;
    clipmask: Integer;
    owner: edict_p;

  // the game dll can add anything it wants after
  // this point in the structure
  end;
  edict_t = edict_s;
  pedict_t = edict_p;
  _edict_s = edict_t;
  p_edict_s = edict_p;
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
{$ELSE}
  gclient_p = g_local.gclient_p;
  gclient_s = g_local.gclient_s;
  gclient_t = g_local.gclient_t;
  _gclient_s = g_local._gclient_s;
  pgclient_s = g_local.pgclient_s;
  pgclient_t = g_local.pgclient_t;
  p_gclient_s = g_local.p_gclient_s;
  TGClient = g_local.TGClient;
  PGClient = g_local.PGClient;
  gclient_at = g_local.gclient_at;
  gclient_a = g_local.gclient_a;
  TGClientArray = g_local.TGClientArray;
  PGClientArray = g_local.PGClientArray;

  edict_p = g_local.edict_p;
  edict_s = g_local.edict_s;
  edict_t = g_local.edict_t;
  _edict_s = g_local._edict_s;
  pedict_s = g_local.pedict_s;
  pedict_t = g_local.pedict_t;
  p_edict_s = g_local.p_edict_s;
  TEdict = g_local.TEdict;
  PEdict = g_local.PEdict;
  edict_at = g_local.edict_at;
  edict_a = g_local.edict_a;
  TEdictArray = g_local.TEdictArray;
  PEdictArray = g_local.PEdictArray;

  // CAK - These two types are thanks to Clootie
  // Note - This is an array of POINTERS,
  // Most places you should use an array of RECORDS
  PEdictPArray = g_local.PEdictPArray;
  TEdictPArray = g_local.TEdictPArray;

{$ENDIF}


//===============================================================

//
// functions provided by the main engine
//



  game_import_p = ^game_import_t;
  pgame_import_t = game_import_p;
  game_import_t = record
    // special messages
    bprintf: Procedure(printlevel: Integer; fmt: PChar {;...}); cdecl;
    dprintf: Procedure(fmt: PChar {;...}); cdecl;
    cprintf: Procedure(ent: edict_p; printlevel: Integer; fmt: PChar {;...}); cdecl;
    centerprintf: Procedure(ent: edict_p; fmt: PChar {;...}); cdecl;
    sound: Procedure(ent: edict_p; channel, soundindex: Integer; volume,attenuation,timeofs: Single); cdecl;
    positioned_sound: Procedure(origin: vec3_t; ent: edict_p; channel, soundinedex: Integer; volume, attenuation, timeofs: Single); cdecl;

    // config strings hold all the index strings, the lightstyles,
    // and misc data like the sky definition and cdtrack.
    // All of the current configstrings are sent to clients when
    // they connect, and changes are sent to all connected clients.
    configstring: Procedure(num: Integer; _string: PChar); cdecl;

    error: Procedure(fmt: PChar {;...}); cdecl;

    // the *index functions create configstrings and some internal server state
    modelindex: Function(name: PChar): Integer; cdecl;
    soundindex: Function(name: PChar): Integer; cdecl;
    imageindex: Function(name: PChar): Integer; cdecl;

    setmodel: Procedure(ent: edict_p; name: PChar); cdecl;

    // collision detection
    trace: Function(start, mins, maxs, _end: vec3_t; passent: edict_p; contentmask: Integer): trace_t; cdecl;
    pointcontents: Function(point: vec3_t): Integer; cdecl;
    inPVS: Function(p1, p2: vec3_t): qboolean; cdecl;
    inPHS: Function(p1, p2: vec3_t): qboolean; cdecl;
    SetAreaPortalState: Procedure(portalnum: Integer; open: qboolean); cdecl;
    AreasConnected: Function(area1, area2: Integer): qboolean; cdecl;

    // an entity will never be sent to a client or used for collision
    // if it is not passed to linkentity.  If the size, position, or
    // solidity changes, it must be relinked.
    linkentity: Procedure(ent: edict_p);  cdecl;
    unlinkentity: Procedure(ent: edict_p);  cdecl; // call before removing an interactive edict
    BoxEdicts: Function(mins, maxs: vec3_t; list: edict_p; maxcount, areatype: Integer): Integer; cdecl;
    Pmove: Procedure(pmove: pmove_p);   cdecl; // player movement code common with client prediction

    // network messaging
    multicast: Procedure(origin: vec3_t; _to: multicast_t); cdecl;
    unicast: Procedure(ent: edict_p; reliable: qboolean); cdecl;
    WriteChar: Procedure(c: Integer); cdecl;
    WriteByte: Procedure(c: Integer); cdecl;
    WriteShort: Procedure(c: Integer); cdecl;
    WriteLong: Procedure(c: Integer); cdecl;
    WriteFloat: Procedure(f: Single); cdecl;
    WriteString: Procedure(s: PChar); cdecl;
    WritePosition: Procedure(pos: vec3_t); cdecl; // some fractional bits
    WriteDir: Procedure(pos: vec3_t); cdecl; // single byte encoded, very coarse
    WriteAngle: Procedure(f: Single); cdecl;

    // managed memory allocation
    TagMalloc: Function(size, tag: Integer): Pointer; cdecl;
    TagFree: Procedure(block: pointer); cdecl;
    FreeTags: Procedure(tag: Integer); cdecl;

    // console variable interaction
    cvar: function(var_name, value: PChar; flags: Integer): cvar_p; cdecl;
    cvar_set: function(var_name, value: PChar): cvar_p; cdecl;
    cvar_forceset: function(var_name, value: PChar): cvar_p; cdecl;

    // ClientCommand and ServerCommand parameter access
    argc: Function: Integer; cdecl;
    argv: Function(n: Integer): PChar; cdecl;
    args: Function: PChar; cdecl; // concatenation of all argv >= 1

    // add commands to the server console as if they were typed in
    // for map changing, etc
    AddCommandString: Procedure(text: PChar); cdecl;

    DebugGraph: Procedure(value: Single; color: Integer); cdecl;
  end;
  TGameImport = game_import_t;
  PGameImport = game_import_p;
  game_import_at = array [0..MaxInt div SizeOf(game_import_t)-1] of game_import_t;
  game_import_a = ^game_import_at;
  TGameImportArray = game_import_at;
  PGameImportArray = game_import_a;

//
// functions exported by the game subsystem
//
  game_export_p = ^game_export_t;
  pgame_export_t = game_export_p;
  game_export_t = record
    apiversion: Integer;

    // the init function will only be called when a game starts,
    // not each time a level is loaded.  Persistant data for clients
    // and the server can be allocated in init
    Init: procedure; cdecl;
    Shutdown: Procedure; cdecl;

    // each new level entered will cause a call to SpawnEntities
    SpawnEntities: Procedure(mapname, entstring, spawnpoint: PChar); cdecl;

    // Read/Write Game is for storing persistant cross level information
    // about the world state and the clients.
    // WriteGame is called every time a level is exited.
    // ReadGame is called on a loadgame.
    WriteGame: Procedure(filename: PChar; autosave: qboolean); cdecl;
    ReadGame: Procedure(filename: PChar); cdecl;

    // ReadLevel is called after the default map information has been
    // loaded with SpawnEntities
    WriteLevel: Procedure(filename: PChar); cdecl;
    ReadLevel: Procedure(filename: PChar); cdecl;

    ClientConnect: Function(ent: edict_p; userinfo: PChar): qboolean; cdecl;
    ClientBegin: Procedure(ent: edict_p); cdecl;
    ClientUserinfoChanged: Procedure(ent: edict_p; userinfo: PChar); cdecl;
    ClientDisconnect: Procedure(ent: edict_p); cdecl;
    ClientCommand: Procedure(ent: edict_p); cdecl;
    ClientThink: Procedure(ent: edict_p; cmd: usercmd_p); cdecl;

    RunFrame: Procedure; cdecl;

    // ServerCommand will be called when an "sv <command>" command is issued on the
    // server console.
    // The game can issue gi.argc() / gi.argv() commands to get the rest
    // of the parameters
    ServerCommand: Procedure; cdecl;

    //
    // global variables shared between game and server
    //

    // The edict array is allocated in the game dll so it
    // can vary in size from one game to another.
    //
    // The size will be fixed when ge->Init() is called
    edicts: edict_p;
    edict_size: Integer;
    num_edicts: Integer;  // current number, <= max_edicts
    max_edicts: Integer;
  end;
  TGameExport = game_export_t;
  PGameExport = game_export_p;
  game_export_at = array [0..MaxInt div SizeOf(game_export_t)-1] of game_export_t;
  game_export_a = ^game_export_at;
  TGameExportArray = game_export_at;
  PGameExportArray = game_export_a;

// CAK - TAKEN FROM g_local.h
Var
  gi: game_import_t;
  globals: game_export_t;

// CAK - Convenience functions by Carl Kenner.
// These allow you to use functions in gi properly
procedure gi_Error(Fmt: String; const Args: array of const);
procedure gi_bprintf(PrintLevel: Integer; Fmt: String; const Args: array of const);
procedure gi_dprintf(Fmt: String; const Args: array of const);
procedure gi_cprintf(Ent: edict_p; PrintLevel: Integer; Fmt: String; const Args: array of const);
procedure gi_centerprintf(ent: edict_p; fmt: String; const Args: array of const);

////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////
                         Implementation
////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////
Uses SysUtils;

procedure gi_Error(Fmt: String; const Args: array of const);
Var Buffer: Array[0..9999] of Char;
begin
  Com_Sprintf(Buffer,sizeof(Buffer),PChar(Fmt),Args);
  gi.error(Buffer);
end;

procedure gi_bprintf(PrintLevel: Integer; Fmt: String; const Args: array of const);
Var Buffer: Array[0..9999] of Char;
begin
  Com_Sprintf(Buffer,sizeof(Buffer),PChar(Fmt),Args);
  gi.bprintf(PrintLevel, Buffer);
end;

procedure gi_dprintf(Fmt: String; const Args: array of const);
Var Buffer: Array[0..9999] of Char;
begin
  Com_Sprintf(Buffer,sizeof(Buffer),PChar(Fmt),Args);
  gi.dprintf(Buffer);
end;

procedure gi_cprintf(Ent: edict_p; PrintLevel: Integer; Fmt: String; const Args: array of const);
Var Buffer: Array[0..9999] of Char;
begin
  Com_Sprintf(Buffer,sizeof(Buffer),PChar(Fmt),Args);
  gi.cprintf(Ent, PrintLevel, Buffer);
end;

procedure gi_centerprintf(ent: edict_p; fmt: String; const Args: array of const);
Var Buffer: Array[0..9999] of Char;
begin
  Com_Sprintf(Buffer,sizeof(Buffer),PChar(Fmt),Args);
  gi.centerprintf(Ent, Buffer);
end;


initialization
  Assert(sizeof(solid_t)=4);
  Assert(sizeof(link_t)=8);
  Assert(sizeof(game_import_t)=176);
  Assert(sizeof(game_export_t)=80);
{$IFNDEF GAME_INCLUDE}
  Assert(sizeof(edict_t)=260);
  Assert(sizeof(gclient_t)=188);
{$ENDIF}
end.
