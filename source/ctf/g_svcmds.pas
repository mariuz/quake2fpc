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
{ File(s): g_local.h (part), g_svcmds.c                                      }
{ Content: Quake2\Game-CTF\ Server commands                                  }
{                                                                            }
{ Initial conversion by : Clootie (Alexey Barkovoy) - clootie@reactor.ru     }
{ Initial conversion on : 28-Jan-2002                                        }
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
{ * Updated:                                                                 }
{ 1) 25-Feb-2002 - Clootie (clootie@reactor.ru)                              }
{    Now all external dependencies are cleaned up.                           }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{----------------------------------------------------------------------------}

{$Include ..\JEDI.inc}

unit g_svcmds;

interface

uses
  Q_Shared;

function SV_FilterPacket(from: PChar): qboolean;

procedure ServerCommand; cdecl;

implementation

uses
  SysUtils,
  CVar, G_Main, G_Local, GameUnit;

{$IFNDEF COMPILER6_UP}
type
  PCardinal = ^Cardinal;
{$ENDIF}

procedure Svcmd_Test_f;
begin
  gi_cprintf(nil, PRINT_HIGH, 'Svcmd_Test_f()'#10, ['']);
end;

(*
==============================================================================

PACKET FILTERING


You can add or remove addresses from the filter list with:

addip <ip>
removeip <ip>

The ip address is specified in dot format, and any unspecified digits will match any value, so you can specify an entire class C network with "addip 192.246.40".

Removeip will only remove an address specified exactly the same way.  You cannot addip a subnet, then removeip a single host.

listip
Prints the current list of filters.

writeip
Dumps "addip <ip>" commands to listip.cfg so it can be execed at a later date.  The filter lists are not saved and restored by default, because I beleive it would cause too much confusion.

filterban <0 or 1>

If 1 (the default), then ip addresses matching the current list will be prohibited from entering the game.  This is the default setting.

If 0, then only addresses matching the list will be allowed.  This lets you easily set up a private game, or a game that only allows players from your local network.


==============================================================================
*)

type
  TIPFilter = record
    mask    : Cardinal;
    compare : Cardinal;
  end;
  ipfilter_t = TIPFilter;

const
  MAX_IPFILTERS = 1024;

var
  ipfilters: array [0..MAX_IPFILTERS-1] of TIPFilter;
  numipfilters: Integer;

(*
=================
StringToFilter
=================
*)
function StringToFilter(s: PChar; var f: TIPFilter): qboolean;
var
  num: array [0..128-1] of Char;
  i, j: Integer;
  b: array [0..3] of Byte;
  m: array [0..3] of Byte;
begin
  for i:= 0 to 3 do
  begin
    b[i] := 0;
    m[i] := 0;
  end;

  for i:= 0 to 3 do
  begin
    if (s^ < '0') or (s^ > '9') then
    begin
      gi_cprintf(nil, PRINT_HIGH, 'Bad filter address: %s'#10, [s]);
      Result:= False;
      Exit;
    end;

    j := 0;
    while (s^ >= '0') and (s^ <= '9') do
    begin
      num[j] := s^;
      Inc(j);
      Inc(s);
    end;
    num[j] := #0;
    b[i] := StrToInt(num);
    if (b[i] <> 0) then
      m[i] := 255;

    if (s^ = #0) then Break;
    Inc(s);
  end;

  f.mask := PCardinal(@m)^;
  f.compare := PCardinal(@b)^;

  Result:= True;
end;

(*
=================
SV_FilterPacket
=================
*)
function SV_FilterPacket(from: PChar): qboolean;
var
  i: Integer;
  in_: Cardinal;
  m: array [0..3] of Byte;
  p: PChar;
begin
  i := 0;
  p := from;
  while (p^ <> #0) and (i < 4) do
  begin
    m[i] := 0;
    while (p^ >= '0') and (p^ <= '9') do
    begin
      m[i] := m[i]*10 + (Ord(p^) - Ord('0'));
      Inc(p);
    end;
    if (p^ = #0) or (p^ = ':') then Break;
    Inc(i); Inc(p)
  end;

  in_ := PCardinal(@m)^;

  for i:= 0  to numipfilters - 1 do
    if ( (in_ and ipfilters[i].mask) = ipfilters[i].compare) then
    begin
      Result := (filterban.value <> 0);
      Exit;
    end;

  Result := not (filterban.value <> 0);
end;


(*
=================
SV_AddIP_f
=================
*)
procedure SVCmd_AddIP_f;
var
  i: Integer;
begin
  if (gi.argc < 3) then
  begin
    gi_cprintf(nil, PRINT_HIGH, 'Usage:  addip <ip-mask>'#10, []);
    Exit;
  end;

  i:= 0;
  repeat
    if (ipfilters[i].compare = $ffffffff) then
      Break;      // free spot
    Inc(i);
  until (i = numipfilters);

  if (i = numipfilters) then
  begin
    if (numipfilters = MAX_IPFILTERS) then
    begin
      gi_cprintf(nil, PRINT_HIGH, 'IP filter list is full'#10, []);
      Exit;
    end;
    Inc(numipfilters);
  end;

  if not StringToFilter(gi.argv(2), ipfilters[i]) then
    ipfilters[i].compare := $ffffffff;
end;

(*
=================
SV_RemoveIP_f
=================
*)
procedure SVCmd_RemoveIP_f;
var
  f: TIPFilter;
  i, j: Integer;
begin
  if (gi.argc < 3) then
  begin
    gi_cprintf(nil, PRINT_HIGH, 'Usage:  sv removeip <ip-mask>'#10, []);
    Exit;
  end;

  if not StringToFilter(gi.argv(2), f) then Exit;

  for i:= 0 to numipfilters - 1  do
    if (ipfilters[i].mask = f.mask) and
       (ipfilters[i].compare = f.compare) then
    begin
      for j:= i+1 to numipfilters - 1 do
        ipfilters[j-1] := ipfilters[j];
      Dec(numipfilters);
      gi_cprintf(nil, PRINT_HIGH, 'Removed.'#10, []);
      Exit;
    end;
  gi_cprintf(nil, PRINT_HIGH, 'Didn''t find %s.'#10, [gi.argv(2)]);
end;

(*
=================
SV_ListIP_f
=================
*)
procedure SVCmd_ListIP_f;
var
  i: Integer;
  b: array [0..3] of Byte;
begin
  gi_cprintf(nil, PRINT_HIGH, 'Filter list:'#10, []);
  for i:= 0 to numipfilters - 1 do
  begin
    PCardinal(@b)^ := ipfilters[i].compare;
    gi_cprintf(nil, PRINT_HIGH, '%3d.%3d.%3d.%3d'#10, [b[0], b[1], b[2], b[3]]);
  end;
end;

(*
=================
SV_WriteIP_f
=================
*)
procedure SVCmd_WriteIP_f;
var
  f: Text;
  name: array [0..MAX_OSPATH-1] of Char;
  b: array [0..3] of Byte;
  i: Integer;
  game: cvar_p;
begin
  game := gi.cvar('game', '', 0);

  if (game.string_^ = #0) then
    StrFmt(name, '%s/listip.cfg', [GAMEVERSION])
  else
    StrFmt(name, '%s/listip.cfg', [game.string_]);

  gi_cprintf(nil, PRINT_HIGH, 'Writing %s.'#10, [name]);

  AssignFile(f, name);
  FileMode := fmOpenWrite;
  Reset(f); // f = fopen (name, "wb"); -- open file "binary write"
  if (IOResult <> 0) then
  begin
    gi_cprintf(nil, PRINT_HIGH, 'Couldn''t open %s'#10, [name]);
    Exit;
  end;

  Write(f, Format('set filterban %d'#10, [Round(filterban.value)]));

  for i:= 0 to numipfilters - 1 do
  begin
    PCardinal(@b)^ := ipfilters[i].compare;
    Write(f, Format('sv addip %d.%d.%d.%d'#10, [b[0], b[1], b[2], b[3]]));
  end;

  CloseFile(f);
end;

(*
=================
ServerCommand

ServerCommand will be called when an "sv" command is issued.
The game can issue gi.argc() / gi.argv() commands to get the rest
of the parameters
=================
*)
procedure ServerCommand; cdecl;
var
  cmd: PChar;
begin
  cmd := gi.argv(1);
  if (Q_stricmp(cmd, 'test') = 0) then Svcmd_Test_f
  else if (Q_stricmp(cmd, 'addip') = 0) then SVCmd_AddIP_f
  else if (Q_stricmp(cmd, 'removeip') = 0) then SVCmd_RemoveIP_f
  else if (Q_stricmp(cmd, 'listip') = 0) then SVCmd_ListIP_f
  else if (Q_stricmp(cmd, 'writeip') = 0) then SVCmd_WriteIP_f
  else
    gi_cprintf(nil, PRINT_HIGH, 'Unknown server command "%s"'#10, [cmd]);
end;

end.

nd(filterban.value)]));

  for i:= 0 to numipfilters - 1 do
  begin
    PCardinal(@b)^ := ipfilters[i].compare;
    Write(f, Format('sv addip %d.%d.%d.%d'#10, [b[0], b[1], b[2], b[3]]));
  end;

  CloseFile(f);
end;

(*
=================
ServerCommand

ServerCommand will be called when an "sv" command is issued.
The game can issue gi.argc() / gi.argv() commands to get the rest
of the parameters
=================
*)
procedure ServerCommand;
var
  cmd: PChar;
begin
  cmd := gi.argv(1);
  if (Q_stricmp(cmd, 'test') = 0) then Svcmd_Test_f
  else if (Q_stricmp(cmd, 'addip') = 0) then SVCmd_AddIP_f
  else if (Q_stricmp(cmd, 'removeip') = 0) then SVCmd_RemoveIP_f
  else if (Q_stricmp(cmd, 'listip') = 0) then SVCmd_ListIP_f
  else if (Q_stricmp(cmd, 'writeip') = 0) then SVCmd_WriteIP_f
  else
    gi.cprintf(nil, PRINT_HIGH, 'Unknown server command "%s"'#10, [cmd]);
end;

end.

