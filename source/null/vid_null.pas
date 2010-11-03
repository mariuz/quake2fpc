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


{99%}
{----------------------------------------------------------------------------}
{                                                                            }
{ File(s): sys_null.c - null system driver to aid porting efforts            }
{                                                                            }
{ Initial conversion by : Hierro (hierro86@libero.it)                        }
{ Initial conversion on : 07-Jan-2002                                        }
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
{ Updated on : 15-July-2002                                                  }
{ Updated by: John Clements (macarser@users.sourceforge.net                  }
{   - spot-checked whole unit and declared functions in Interface section    }
{----------------------------------------------------------------------------}
{ Updated on : 3-Jun-2002                                                    }
{ Updated by : Juha Hartikainen (juha@linearteam.org)                        }
{  - done all missing parts here + fixed some bugs                           }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{ 1) client\client.pas                                                       }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{ 1) Some guru might want to check if the whole unit is correctly converted, }
{    specially GetRefAPI thing                                               }
{----------------------------------------------------------------------------}

unit vid_null;

interface

uses
  client, vid_h, ref;

type
  vidmode_t = packed record
    description: PChar; // Was " const char *description; "
    width, height: integer;
    mode: integer;
  end;

const
  MAXPRINTMSG=4096;

  vid_modes:array[0..10] of vidmode_t= ( (* Initialize the "vid_modes" variable with these values *)
    ( description:'Mode 0: 320x240'; width: 320; height: 240;mode:  0 ),
    ( description:'Mode 1: 400x300'; width: 400; height: 300;mode:  1 ),
    ( description:'Mode 2: 512x384'; width: 512; height: 384;mode:  2 ),
    ( description:'Mode 3: 640x480'; width: 640; height: 480;mode:  3 ),
    ( description:'Mode 4: 800x600'; width: 800; height: 600;mode:  4 ),
    ( description:'Mode 5: 960x720'; width: 960; height: 720;mode:  5 ),
    ( description:'Mode 6: 1024x768'; width: 1024; height: 768;mode:  6 ),
    ( description:'Mode 7: 1152x864'; width: 1152; height: 864;mode:  7 ),
    ( description:'Mode 8: 1280x960'; width: 1280; height: 960;mode:  8 ),
    ( description:'Mode 9: 1600x1200'; width: 1600; height: 1200;mode:  9 ),
    ( description:'Mode 10: 2048x1536'; width: 2048; height: 1536;mode:  10 )
    );

  VID_NUM_MODES = ( sizeof( vid_modes ) / sizeof( vid_modes[0] ) ); // currently equal to 11

var
  viddef:viddef_t;            // global video state
  re:refexport_t;
  GetRefAPI: GetRefAPI_t;

procedure VID_Printf(print_level:integer; fmt:PChar; args: array of const);
procedure VID_Error(err_level:integer; fmt:PChar; args: array of const);
procedure VID_NewWindow (width:integer; height:integer);
function VID_GetModeInfo(width:PInteger; height:PInteger; mode:integer):boolean;
procedure VID_Init;
procedure VID_Shutdown;
procedure VID_CheckChanges;
procedure VID_MenuInit;
procedure VID_MenuDraw;
function VID_MenuKey(k:integer):PChar;

implementation

uses SysUtils, Files, q_shared, Common, Cmd, CVar;

(*
==========================================================================

DIRECT LINK GLUE

==========================================================================
*)

procedure VID_Printf(print_level:integer; fmt:PChar; args: array of const);
var
  valist : argptr;
  msg: array[0..MAXPRINTMSG-1] of char;
begin
  StrFmt(msg, fmt, args);
  // it appears this line replaces the 3 lines below
{  va_start (argptr, fmt);
  vsprintf (msg, fmt, argptr);
  va_end (argptr);}

  if (print_level=PRINT_ALL) then
    Com_Printf ('%s', [msg])
  else
    Com_DPrintf ('%s', [msg]);
end;

procedure VID_Error(err_level:integer; fmt:PChar; args: array of const);
var
  valist : argptr;
  msg: array[0..MAXPRINTMSG-1] of char;
begin
  StrFmt(msg, fmt, args);
  // it appears this line replaces the 3 lines below
{  va_start (argptr, fmt);
  vsprintf (msg, fmt, argptr);
  va_end (argptr);}

  Com_Error (err_level, '%s', [msg]);
end;

procedure VID_NewWindow (width:integer; height:integer);
begin
  viddef.width := width;
  viddef.height := height;
end;

function VID_GetModeInfo(width:PInteger; height:PInteger; mode:integer):boolean;
begin
  if (mode<0) or (mode>=VID_NUM_MODES) then
    VID_GetModeInfo:=false
  else
    begin
      width^  := vid_modes[mode].width;
      height^ := vid_modes[mode].height;

      VID_GetModeInfo := true;
    end;
end;

procedure VID_Init;
var ri:refimport_t;
begin
  viddef.width := 320;
  viddef.height := 240;

  ri.Cmd_AddCommand := @Cmd_AddCommand;
  ri.Cmd_RemoveCommand := @Cmd_RemoveCommand;
  ri.Cmd_Argc := @Cmd_Argc;
  ri.Cmd_Argv := @Cmd_Argv;
  ri.Cmd_ExecuteText := @Cbuf_ExecuteText;
  ri.Con_Printf := @VID_Printf;
  ri.Sys_Error := @VID_Error;
  ri.FS_LoadFile := @FS_LoadFile;
  ri.FS_FreeFile := @FS_FreeFile;
  ri.FS_Gamedir := @FS_Gamedir;
  ri.Vid_NewWindow := @VID_NewWindow;
  ri.Cvar_Get := @Cvar_Get;
  ri.Cvar_Set := @Cvar_Set;
  ri.Cvar_SetValue := @Cvar_SetValue;
  ri.Vid_GetModeInfo := @VID_GetModeInfo;

  re := GetRefAPI(ri);

  if (re.api_version<>API_VERSION) then
    Com_Error (ERR_FATAL, 'Re has incompatible api_version', []);

  // call the init function
  if (re.Init(nil, nil) = false) then
    Com_Error (ERR_FATAL, 'Couldn''t start refresh', []);
end;

procedure VID_Shutdown;
begin
  if Assigned(re.Shutdown) then
    re.Shutdown ();
end;

procedure VID_CheckChanges;
begin
end;

procedure VID_MenuInit;
begin
end;

procedure VID_MenuDraw;
begin
end;

function VID_MenuKey(k:integer):PChar; (* was " const char *VID_MenuKey( int k) " *)
begin
  VID_MenuKey:=nil;;
end;

end.
