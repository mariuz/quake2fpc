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


{$ALIGN ON}{$MINENUMSIZE 4}
//100% complete
{----------------------------------------------------------------------------}
{                                                                            }
{ File(s): ref.h                                                             }
{                                                                            }
{ Initial conversion by : Carl Kenner (carl_kenner@hotmail.com)              }
{ Initial conversion on : 15-Feb-2002                                        }
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
{ Updated on : 04-jun-2002                                                   }
{ Updated by : Juha Hartikainen (juha@linearteam.org)                        }
{ - Fixed bug in ref_export_t.init declaration                               }
{                                                                            }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{ none                                                                       }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{ none                                                                       }
{----------------------------------------------------------------------------}
{ * Acknowledgements:                                                        }
{ Special thanks to YgriK (Igor Karpov) - glYgriK@hotbox.ru                  }
{ for making a half finished ref.inc                                         }
{ This file is not based on that, it is a conversion straight from ref.h     }
{----------------------------------------------------------------------------}

unit ref;

interface

uses
//  DelphiTypes,
  {$IFDEF WIN32}
  windows,
  {$ENDIF}
  q_shared;

const
  MAX_DLIGHTS = 32;
  MAX_ENTITIES = 128;
  MAX_PARTICLES = 4096;
  MAX_LIGHTSTYLES = 256;

  POWERSUIT_SCALE = 4.0;

  SHELL_RED_COLOR = $F2;
  SHELL_GREEN_COLOR = $D0;
  SHELL_BLUE_COLOR = $F3;

  SHELL_RG_COLOR = $DC;
  //  SHELL_RB_COLOR = $86;
  SHELL_RB_COLOR = $68;
  SHELL_BG_COLOR = $78;

  //ROGUE
  SHELL_DOUBLE_COLOR = $DF;             // 223
  SHELL_HALF_DAM_COLOR = $90;
  SHELL_CYAN_COLOR = $72;
  //ROGUE

  SHELL_WHITE_COLOR = $D7;

  // CAK - because model_s and image_s are different for different renderers,
  //       this file does not know what the contents of the structures are.
  //       ID calls them "opaque type outside refresh". For this reason I have
  //       made them generic delphi pointers, so they can point to either
  //       r_local.image_s or gl_local.image_s
type
  entity_p = ^entity_t;
  entity_t = record
    model: pointer;                     // opaque type outside refresh
    angles: array[0..2] of Single;

    (*
    ** most recent data
    *)
    origin: array[0..2] of Single;      // also used as RF_BEAM's "from"
    frame: Integer;                     // also used as RF_BEAM's diameter

    (*
    ** previous data for lerping
    *)
    oldorigin: array[0..2] of Single;   // also used as RF_BEAM's "to"
    oldframe: Integer;

    (*
    ** misc
    *)
    backlerp: Single;                   // 0.0 = current, 1.0 = old
    skinnum: Integer;                   // also used as RF_BEAM's palette index

    lightstyle: Integer;                // for flashing entities
    alpha: Single;                      // ignore if RF_TRANSLUCENT isn't set

    skin: Pointer {to image_s};         // NULL for inline skin
    flags: Integer;
  end;
  entity_arr = array[0..0] of entity_t;
  entity_arrp = ^entity_arr;

const
  ENTITY_FLAGS = 68;

type
  dlight_p = ^dlight_t;
  dlight_t = record
    origin: vec3_t;
    color: vec3_t;
    intensity: Single;
  end;
  dlight_arr = array[0..0] of dlight_t;
  dlight_arrp = ^dlight_arr;

  particle_p = ^particle_t;
  particle_t = record
    origin: vec3_t;
    color: Integer;
    alpha: Single;
  end;

  lightstyle_p = ^lightstyle_t;
  lightstyle_t = record
    rgb: array[0..2] of Single;         // 0.0 - 2.0
    white: Single;                      // highest of rgb
  end;
  lightstyle_arr = array[0..0] of lightstyle_t;
  lightstyle_arrp = ^lightstyle_arr;

  refdef_p = ^refdef_t;
  refdef_t = record
    x, y, width, height: Integer;       // in virtual screen coordinates
    fov_x, fov_y: Single;
    vieworg: array[0..2] of Single;
    viewangles: array[0..2] of Single;
    blend: array[0..3] of Single;       // rgba 0-1 full screen blend
    time: Single;                       // time is uesed to auto animate
    rdflags: Integer;                   // RDF_UNDERWATER, etc

    areabits: PByte;                    // if not NULL, only areas with set bits will be drawn

    lightstyles: lightstyle_arrp;          // [MAX_LIGHTSTYLES]

    num_entities: Integer;
    entities: entity_p;

    num_dlights: Integer;
    dlights: dlight_p;

    num_particles: Integer;
    particles: particle_p;
  end;

const
  API_VERSION = 3;

  // Carl Kenner (CAK) - I made all the functions CDECL
  // because Register, Pascal, and STDCALL, don't allow the "..." in printf
  // also it was originally a C program

  //
  // these are the functions exported by the refresh module
  //
type
  refexport_p = ^refexport_t;
  refexport_t = record
    // if api_version is different, the dll cannot be used
    api_version: integer;

    // called when the library is loaded
    // Juha: This needs to return integer, as vid_dll.c(=pas) checks it for "-1".
    Init: function(hinstance: cardinal; wndproc: pointer): Integer; cdecl;

    // called before the library is unloaded
    Shutdown: procedure; cdecl;

    // All data that will be used in a level should be
    // registered before rendering any frames to prevent disk hits,
    // but they can still be registered at a later time
    // if necessary.
    //
    // EndRegistration will free any remaining data that wasn't registered.
    // Any model_s or skin_s pointers from before the BeginRegistration
    // are no longer valid after EndRegistration.
    //
    // Skins and images need to be differentiated, because skins
    // are flood filled to eliminate mip map edge errors, and pics have
    // an implicit "pics/" prepended to the name. (a pic name that starts with a
    // slash will not use the "pics/" prefix or the ".pcx" postfix)
    BeginRegistration: procedure(map: PChar); cdecl;
    RegisterModel: function(name: PChar): Pointer {to model_s}; cdecl;
    RegisterSkin: function(name: PChar): Pointer {to image_s}; cdecl;
    RegisterPic: function(name: PChar): Pointer {to image_s}; cdecl;
    SetSky: procedure(name: PChar; rotate: single; axis: vec3_p); cdecl;
    EndRegistration: procedure; cdecl;

    RenderFrame: procedure(fd: refdef_p); cdecl;

    DrawGetPicSize: procedure(w, h: PInteger; name: PChar); cdecl; // will return 0 0 if not found
    DrawPic: procedure(x, y: Integer; name: PChar); cdecl;
    DrawStretchPic: procedure(x, y, w, h: Integer; name: PChar); cdecl;
    DrawChar: procedure(x, y, c: Integer); cdecl; // CAK - c should be char
    DrawTileClear: procedure(x, y, w, h: Integer; name: PChar); cdecl;
    DrawFill: procedure(x, y, w, h, c: Integer); cdecl;
    DrawFadeScreen: procedure; cdecl;

    // Draw images for cinematic rendering (which can have a different palette). Note that calls
    DrawStretchRaw: procedure(x, y, w, h, cols, rows: Integer; data: PByte); cdecl;

    (*
    ** video mode and refresh state management entry points
    *)
    CinematicSetPalette: procedure(palette: PByte); cdecl; // NULL = game palette
    BeginFrame: procedure(camera_separation: Single); cdecl;
    EndFrame: procedure; cdecl;

    AppActivate: procedure(activate: qboolean); cdecl;
  end;

  //
  // these are the functions imported by the refresh module
  //
  refimport_p = ^refimport_t;
  refimport_t = record
    Sys_Error: procedure(err_level: integer; str: PChar); cdecl varargs; // Juha: Should be ...

    Cmd_AddCommand: procedure(name: PChar; cmd: tcdeclproc); cdecl;
    Cmd_RemoveCommand: procedure(name: PChar); cdecl;
    Cmd_Argc: function: integer; cdecl;
    Cmd_Argv: function(i: Integer): PChar; cdecl;
    Cmd_ExecuteText: procedure(exec_when: Integer; text: PChar); cdecl;

    Con_Printf: procedure(print_level: Integer; str: PChar); cdecl varargs; // Juha: should be ...

    // files will be memory mapped read only
    // the returned buffer may be part of a larger pak file,
    // or a discrete file from anywhere in the quake search path
    // a -1 return means the file does not exist
    // NULL can be passed for buf to just determine existance
    FS_LoadFile: function(name: PChar; buf: PPointer): Integer; cdecl;
    FS_FreeFile: procedure(buf: Pointer); cdecl;

    // gamedir will be the current directory that generated
    // files should be stored to, ie: "f:\quake\id1"
    FS_Gamedir: function: PChar; cdecl;

    Cvar_Get: function(name: PChar; value: PChar; flags: Integer): cvar_p; cdecl;
    Cvar_Set: function(name: PChar; value: PChar): cvar_p; cdecl;
    Cvar_SetValue: procedure(name: PChar; value: single); cdecl;

    Vid_GetModeInfo: function(width, height: PInteger; mode: Integer): qboolean; cdecl;
    Vid_MenuInit: procedure; cdecl;
    Vid_NewWindow: procedure(width, height: Integer); cdecl;
  end;

  // this is the only function actually exported at the linker level
  GetRefAPI_t = function(value: refimport_t): refexport_t; cdecl;

implementation
end.
