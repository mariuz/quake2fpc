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
{ File(s): game\game.h                                                       }
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
{ Updated on:  2003-May-23                                                   }
{ Updated by:  Scott Price (scott.price@totalise.co.uk)                      }
{              Tidy-up and removal of un-neccessary commented code           }
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
unit GameUnit;

interface

uses
{$IFDEF GAMEDLL}
  g_local_add,
{$ENDIF}
  game_add,
  q_shared_add;

  // game.h -- game dll information visible to server  
const
  GAME_API_VERSION = 3;

  // edict->svflags

  SVF_NOCLIENT = $00000001;             // don't send entity to clients, even if it has effects
  SVF_DEADMONSTER = $00000002;          // treat as CONTENTS_DEADMONSTER for collision
  SVF_MONSTER = $00000004;              // treat as CONTENTS_MONSTER for collision

  MAX_ENT_CLUSTERS = game_add.MAX_ENT_CLUSTERS;

type
  solid_p = game_add.solid_p;
  solid_t = game_add.solid_t;

  link_p = game_add.link_p;
  link_t = game_add.link_t;

  //===============================================================

  //===============================================================

type

{$IFNDEF GAMEDLL}
  gclient_p = ^gclient_t;
  gclient_t = record
    ps: player_state_t;                 // communicated by server to clients
    ping: Integer;
    // the game dll can add anything it wants after
    // this point in the structure
  end;

  edict_p = ^edict_t;
  edict_t = record
    s: entity_state_t;
    client: gclient_p;
    inuse: qboolean;
    linkcount: Integer;

    // FIXME: move these fields to a server private sv_entity_t
    area: link_t;                       // linked to a division node or leaf

    num_clusters: Integer;              // if -1, use headnode instead
    clusternums: array[0..MAX_ENT_CLUSTERS - 1] of Integer; // CAK - Did -1
    headnode: Integer;                  // unused if num_clusters != -1
    areanum,
      areanum2: Integer;

    //================================

    svflags: Integer;                   // SVF_NOCLIENT, SVF_DEADMONSTER, SVF_MONSTER, etc
    mins, maxs: vec3_t;
    absmin, absmax, size: vec3_t;
    solid: solid_t;
    clipmask: Integer;
    owner: edict_p;

    // the game dll can add anything it wants after
    // this point in the structure
  end;
{$ENDIF}

  Tarea_list = array[0..0] of edict_p;
  Parea_list = ^Tarea_list;

  //===============================================================

  //
  // functions provided by the main engine
  //

  //  testproc = Procedure(printlevel: Integer; fmt: PChar {;...}); cdecl; varargs = blah;

  game_import_p = ^game_import_t;
  game_import_t = record
    // special messages
    bprintf: procedure(printlevel: Integer; fmt: PChar {;...}); cdecl varargs;
    dprintf: procedure(fmt: PChar {;...}); cdecl varargs;
    cprintf: procedure(ent: edict_p; printlevel: Integer; fmt: PChar {;...}); cdecl varargs;
    centerprintf: procedure(ent: edict_p; fmt: PChar {;...}); cdecl varargs;
    sound: procedure(ent: edict_p; channel, soundindex: Integer; volume, attenuation, timeofs: Single); cdecl;
    positioned_sound: procedure(origin: vec3_p; ent: edict_p; channel, soundinedex: Integer; volume, attenuation, timeofs: Single); cdecl;

    // config strings hold all the index strings, the lightstyles,
    // and misc data like the sky definition and cdtrack.
    // All of the current configstrings are sent to clients when
    // they connect, and changes are sent to all connected clients.
    configstring: procedure(num: Integer; _string: PChar); cdecl;

    error: procedure(fmt: PChar {;...}); cdecl varargs;

    // the *index functions create configstrings and some internal server state
    modelindex: function(name: PChar): Integer; cdecl;
    soundindex: function(name: PChar): Integer; cdecl;
    imageindex: function(name: PChar): Integer; cdecl;

    setmodel: procedure(ent: edict_p; name: PChar); cdecl;

    // collision detection
    trace: function(start, mins, maxs, _end: vec3_p; passent: edict_p; contentmask: Integer): trace_t; cdecl;
    pointcontents: function(const point: vec3_t): Integer; cdecl;
    inPVS: function(var p1, p2: vec3_t): qboolean; cdecl;
    inPHS: function(var p1, p2: vec3_t): qboolean; cdecl;
    SetAreaPortalState: procedure(portalnum: Integer; open: qboolean); cdecl;
    AreasConnected: function(area1, area2: Integer): qboolean; cdecl;

    // an entity will never be sent to a client or used for collision
    // if it is not passed to linkentity.  If the size, position, or
    // solidity changes, it must be relinked.
    linkentity: procedure(ent: edict_p); cdecl;
    unlinkentity: procedure(ent: edict_p); cdecl; // call before removing an interactive edict
    BoxEdicts: function(mins, maxs: vec3_p; list: Parea_list; maxcount, areatype: Integer): Integer; cdecl;
    Pmove: procedure(pmove: pmove_p); cdecl; // player movement code common with client prediction

    // network messaging
    multicast: procedure(origin: vec3_p; _to: multicast_t); cdecl;
    unicast: procedure(ent: edict_p; reliable: qboolean); cdecl;
    WriteChar: procedure(c: Integer); cdecl;
    WriteByte: procedure(c: Integer); cdecl;
    WriteShort: procedure(c: Integer); cdecl;
    WriteLong: procedure(c: Integer); cdecl;
    WriteFloat: procedure(f: Single); cdecl;
    WriteString: procedure(s: PChar); cdecl;
    WritePosition: procedure(const pos: vec3_t); cdecl; // some fractional bits
    WriteDir: procedure(const pos: vec3_t); cdecl; // single byte encoded, very coarse
    WriteAngle: procedure(f: Single); cdecl;

    // managed memory allocation
    TagMalloc: function(size, tag: Integer): Pointer; cdecl;
    TagFree: procedure(block: pointer); cdecl;
    FreeTags: procedure(tag: Integer); cdecl;

    // console variable interaction
    cvar: function(var_name, value: PChar; flags: Integer): cvar_p; cdecl;
    cvar_set: function(var_name, value: PChar): cvar_p; cdecl;
    cvar_forceset: function(var_name, value: PChar): cvar_p; cdecl;

    // ClientCommand and ServerCommand parameter access
    argc: function: Integer; cdecl;
    argv: function(n: Integer): PChar; cdecl;
    args: function: PChar; cdecl;       // concatenation of all argv >= 1

    // add commands to the server console as if they were typed in
    // for map changing, etc
    AddCommandString: procedure(text: PChar); cdecl;

    DebugGraph: procedure(value: Single; color: Integer); cdecl;
  end;

  //
  // functions exported by the game subsystem
  //
  game_export_p = ^game_export_t;
  game_export_t = record
    apiversion: Integer;

    // the init function will only be called when a game starts,
    // not each time a level is loaded.  Persistant data for clients
    // and the server can be allocated in init
    Init: procedure; cdecl;
    Shutdown: procedure; cdecl;

    // each new level entered will cause a call to SpawnEntities
    SpawnEntities: procedure(mapname, entstring, spawnpoint: PChar); cdecl;

    // Read/Write Game is for storing persistant cross level information
    // about the world state and the clients.
    // WriteGame is called every time a level is exited.
    // ReadGame is called on a loadgame.
    WriteGame: procedure(filename: PChar; autosave: qboolean); cdecl;
    ReadGame: procedure(filename: PChar); cdecl;

    // ReadLevel is called after the default map information has been
    // loaded with SpawnEntities
    WriteLevel: procedure(filename: PChar); cdecl;
    ReadLevel: procedure(filename: PChar); cdecl;

    ClientConnect: function(ent: edict_p; userinfo: PChar): qboolean; cdecl;
    ClientBegin: procedure(ent: edict_p); cdecl;
    ClientUserinfoChanged: procedure(ent: edict_p; userinfo: PChar); cdecl;
    ClientDisconnect: procedure(ent: edict_p); cdecl;
    ClientCommand: procedure(ent: edict_p); cdecl;
    ClientThink: procedure(ent: edict_p; cmd: usercmd_p); cdecl;

    RunFrame: procedure; cdecl;

    // ServerCommand will be called when an "sv <command>" command is issued on the
    // server console.
    // The game can issue gi.argc() / gi.argv() commands to get the rest
    // of the parameters
    ServerCommand: procedure; cdecl;

    //
    // global variables shared between game and server
    //

    // The edict array is allocated in the game dll so it
    // can vary in size from one game to another.
    //
    // The size will be fixed when ge->Init() is called
    edicts: edict_p;
    edict_size: Integer;
    num_edicts: Integer;                // current number, <= max_edicts
    max_edicts: Integer;
  end;

  ////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////
implementation
////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////
uses
  SysUtils;


initialization
begin
  { 2003-05-23 (SP):  Assume these are basic tests on structure sizes, etc }
  Assert(SizeOf(solid_t) = 4);
  Assert(SizeOf(link_t) = 8);
  Assert(SizeOf(game_import_t) = 176);
  Assert(SizeOf(game_export_t) = 80);
{$IFNDEF GAMEDLL}
  Assert(SizeOf(edict_t) = 260);
  Assert(SizeOf(gclient_t) = 188);
{$ENDIF}
end;

end.
