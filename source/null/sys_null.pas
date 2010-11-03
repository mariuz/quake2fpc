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


{----------------------------------------------------------------------------}
{                                                                            }
{ File(s): sys_null.h - null system driver to aid porting efforts            }
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
{ Updated on : 04-jun-2002                                                               }
{ Updated by : Juha Hartikainen (juha@linearteam.org)                                                              }
{ - Language fixes to make this compile }
{                                                                            }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{ 1) qcommon\qcommon.pas                                                     }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{ 1) Convert the C procedure "Main" to something equal in delphi             }
{ 2) Find a sostitute for the errno.h                                        }
{ 3) Check the Sys_Error parameter                                           }
{----------------------------------------------------------------------------}

unit sys_null;

interface

var
  curtime:integer;
  sys_frame_time:Cardinal;

procedure Sys_mkdir(path:PChar);
procedure Sys_Error(error:PChar; args: array of const);
procedure Sys_Quit;
procedure Sys_UnloadGame;
function Sys_GetGameAPI(parms:pointer):pointer;
function Sys_ConsoleInput:PChar;
procedure Sys_ConsoleOutput (strng:PChar);
procedure Sys_SendKeyEvents;
procedure Sys_AppActivate;
procedure Sys_CopyProtect;
function Sys_GetClipboardData:PChar;
function Hunk_Begin (maxsize:integer):pointer;
function Hunk_Alloc(size:integer):pointer;
procedure Hunk_Free(buf:pointer);
function Hunk_End:integer;
function Sys_Milliseconds:integer;
function Sys_FindFirst (path:PChar; musthave:Cardinal; canthave:Cardinal):PChar;
function Sys_FindNext (musthave:Cardinal; canthave:Cardinal):PChar;
procedure Sys_FindClose;
procedure Sys_Init;
procedure main (argc:integer; argv:PPChar);

implementation

uses SysUtils, Windows, Common;

procedure Sys_mkdir(path:PChar);
begin
end;

procedure Sys_Error(error:PChar; args: array of const);
var
  text  : string;
begin
  // Report error.
  text := Format(error, args);
  MessageBox(0, PChar(text), 'Error', 0 { MB_OK} );
  halt(1);
end;

procedure Sys_Quit;
begin
  Halt(0);
end;

procedure Sys_UnloadGame;
begin
end;

function Sys_GetGameAPI(parms:pointer):pointer;
begin
  Sys_GetGameAPI:=nil;
end;

function Sys_ConsoleInput:PChar;
begin
  Sys_ConsoleInput:=nil;
end;

procedure Sys_ConsoleOutput (strng:PChar);
begin
end;

procedure Sys_SendKeyEvents;
begin
end;

procedure Sys_AppActivate;
begin
end;

procedure Sys_CopyProtect;
begin
end;

function Sys_GetClipboardData:PChar;
begin
  Sys_GetClipboardData:=nil;
end;

function Hunk_Begin (maxsize:integer):pointer;
begin
  Hunk_Begin:=nil;
end;

function Hunk_Alloc(size:integer):pointer;
begin
  Hunk_Alloc:=nil;
end;

procedure Hunk_Free(buf:pointer);
begin
end;

function Hunk_End:integer;
begin
  Hunk_End:=0;
end;

function Sys_Milliseconds:integer;
begin
  Sys_Milliseconds:=0;
end;

function Sys_FindFirst (path:PChar; musthave:Cardinal; canthave:Cardinal):PChar;
begin
  Sys_FindFirst:=nil;
end;

function Sys_FindNext (musthave:Cardinal; canthave:Cardinal):PChar;
begin
  Sys_FindNext:=nil;
end;

procedure Sys_FindClose;
begin
end;

procedure Sys_Init;
begin
end;

//=============================================================================

procedure main (argc:integer; argv:PPChar);
begin
  (*  TODO: Juha -> Do we really ever come here (?)
  Qcommon_Init (argc, argv);
  while (true)
    Qcommon_Frame (0.1);
  *)
end;

end.
