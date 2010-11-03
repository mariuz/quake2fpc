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
{ File(s): q_shwin.c                                                         }
{                                                                            }
{ Initial conversion by : Softland (softland_gh@ureach.com)                  }
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
{ Updated on : 23-Feb-2002                                                   }
{ Updated by : Carl A Kenner (carl_kenner@hotmail.com                        }
{                                                                            }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{ none, but Sys_Error will show errors in a MessageBox instead of the console}
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{ 1.) This unit MUST be checked by someone else.                             }
{ 2. I don't know which of the constants, variables, procedures and          }
{    functions should remain in the interface part of the unit, and which    }
 {    should be hidden in the implementation part.                            }
{                                                                            }
{----------------------------------------------------------------------------}

// Remove DOT before $DEFINE in next line to allow non-dependable compilation //
{$DEFINE NODEPEND}
// non-dependable compilation will use STUBS for some external symbols

unit q_shwin;

interface

uses
  Windows,
  q_shared;

var
  hunkcount: Integer;
  membase: PByte;
  hunkmaxsize: Integer;
  cursize: Integer;

  curtime: Integer;
  findbase: array[0..MAX_OSPATH - 1] of Char;
  findpath: array[0..MAX_OSPATH - 1] of Char;
  findhandle: Cardinal;

function Hunk_Begin(maxsize: Integer): Pointer;
function Hunk_Alloc(size: Integer): Pointer;
function Hunk_End: Integer;
procedure Hunk_Free(base: Pointer);

function Sys_Milliseconds: Integer;
procedure Sys_Mkdir(path: PChar);
function Sys_FindFirst(path: PChar; musthave, canthave: Cardinal): PChar;
function Sys_FindNext(musthave, canthave: Cardinal): PChar;
procedure Sys_FindClose;
function CompareAttributes(found, musthave, canthave: Cardinal): qboolean;

implementation

uses
  MMSystem,
  sysutils{$IFNDEF NODEPEND},
  sys_win{$ENDIF};

{$IFDEF NODEPEND}
// CAK - HACK!

procedure Sys_Error(error: string; const Args: array of const);
var
  text: string;
begin
  // Report error.
  text := Format(error, args);
  MessageBox(0, PChar(text), 'Error', 0 { MB_OK});
  Halt(1);
end;
{$ENDIF}

{$DEFINE VIRTUAL_ALLOC}

{$IFDEF DEF_FALSE}
{$UNDEF DEF_FALSE}
{$ENDIF}

function Hunk_Begin(maxsize: Integer): Pointer;
begin

  // Reserve a huge chunk of memory, but don't commit any yet.
  cursize := 0;
  hunkmaxsize := maxsize;

{$IFDEF VIRTUAL_ALLOC}

  membase := VirtualAlloc(nil, maxsize, MEM_RESERVE, PAGE_NOACCESS);

{$ELSE}

  GetMem(membase, maxsize);
  FillChar(membase^, maxsize, 0);

{$ENDIF}

  if membase = nil then
    Sys_Error('VirtualAlloc reserve failed', ['']);

  Result := membase;
end;

function Hunk_Alloc(size: Integer): Pointer;
var
  buf: Pointer;
begin

  // Round to cache line.
  size := (size + 31) and (not 31);

{$IFDEF VIRTUAL_ALLOC}

  // Commit pages as needed.
  buf := VirtualAlloc(membase, cursize + size, MEM_COMMIT, PAGE_READWRITE);
  if buf = nil then
  begin
    FormatMessage(
      FORMAT_MESSAGE_ALLOCATE_BUFFER or FORMAT_MESSAGE_FROM_SYSTEM,
      nil, GetLastError, LANG_NEUTRAL or SUBLANG_DEFAULT shl 10, buf, 0, nil
      );
    Sys_Error('VirtualAlloc commit failed.'#13'%s', [buf]);
  end;

{$ENDIF}

  Inc(cursize, size);
  if cursize > hunkmaxsize then
    Sys_Error('Hunk_Alloc overflow', []);

  Result := Pointer(Integer(membase) + cursize - size);
end;

function Hunk_End: Integer;
{$IFDEF DEF_FALSE}
var
  buf: Pointer;
{$ENDIF}
begin

  // Free the remaining unused virtual memory,
  // and write-protect the used memory.

{$IFDEF VIRTUAL_ALLOC}                  // This may be replaced with IF FALSE.

{$IFDEF DEF_FALSE}
  buf := VirtualAlloc(membase, cursize, MEM_COMMIT, PAGE_READONLY);
  if buf = nil then
    Sys_Error('VirtualAlloc commit failed', []);
{$ENDIF}                                // This may be replaced with IFEND.

{$ENDIF}                                // This may be replaced with IFEND.

  Inc(hunkcount);
  // Com_Printf('hunkcount: %d'#10, [hunkcount]);

  Result := cursize;
end;

procedure Hunk_Free(base: Pointer);
begin
  if base <> nil then

{$IFDEF VIRTUAL_ALLOC}

    VirtualFree(base, 0, MEM_RELEASE);

{$ELSE}

    FreeMem(base);

{$ENDIF}

end;

var
  base: Integer;
  initialized: boolean;

function Sys_Milliseconds: Integer;
begin
  if not initialized then
  begin
    // Let base retain 16 bits of effectively random data.
    base := timeGetTime and $FFFF0000;
    initialized := True;
  end;
  curtime := Integer(timeGetTime) - base;
  Result := curtime;
end;

procedure Sys_Mkdir(path: PChar);
begin
  CreateDir(path);
end;

function CompareAttributes(found, musthave, canthave: Cardinal): qboolean;
begin
  Result := False;

  if (((found and FILE_ATTRIBUTE_READONLY) <> 0) and ((canthave and SFF_RDONLY) <> 0)) then
    Exit;
  if (((found and FILE_ATTRIBUTE_HIDDEN) <> 0) and ((canthave and SFF_HIDDEN) <> 0)) then
    Exit;
  if (((found and FILE_ATTRIBUTE_SYSTEM) <> 0) and ((canthave and SFF_SYSTEM) <> 0)) then
    Exit;
  if (((found and FILE_ATTRIBUTE_DIRECTORY) <> 0) and ((canthave and SFF_SUBDIR) <> 0)) then
    Exit;
  if (((found and FILE_ATTRIBUTE_ARCHIVE) <> 0) and ((canthave and SFF_ARCH) <> 0)) then
    Exit;

  if (((found and FILE_ATTRIBUTE_READONLY) = 0) and ((musthave and SFF_RDONLY) <> 0)) then
    Exit;
  if (((found and FILE_ATTRIBUTE_HIDDEN) = 0) and ((musthave and SFF_HIDDEN) <> 0)) then
    Exit;
  if (((found and FILE_ATTRIBUTE_SYSTEM) = 0) and ((musthave and SFF_SYSTEM) <> 0)) then
    Exit;
  if (((found and FILE_ATTRIBUTE_DIRECTORY) = 0) and ((musthave and SFF_SUBDIR) <> 0)) then
    Exit;
  if (((found and FILE_ATTRIBUTE_ARCHIVE) = 0) and ((musthave and SFF_ARCH) <> 0)) then
    Exit;

  Result := True;
end;

function Sys_FindFirst(path: PChar; musthave, canthave: Cardinal): PChar;
var
  findinfo: TWin32FindData;
begin
  FillChar(findinfo, sizeof(findinfo), 0);
  Result := nil;

  if findhandle <> 0 then
    Sys_Error('Sys_BeginFind without close', ['']);
  findhandle := 0;

  Com_FilePath(path, findbase);
  findhandle := FindFirstFile(pchar(path), findinfo);
  if findhandle = INVALID_HANDLE_VALUE then
    Exit;
  if not CompareAttributes(findinfo.dwFileAttributes, musthave, canthave) then
    Exit;
  Com_sprintf(findpath, SizeOf(findpath), '%s/%s', [findbase, findinfo.cFileName]);
  Result := findpath;
end;

function Sys_FindNext(musthave, canthave: Cardinal): PChar;
var
  findinfo: TWin32FindData;
begin
  Result := nil;

  if findhandle = Cardinal(-1) then
    Exit;
  if not FindNextFile(findhandle, findinfo) then
    Exit;
  if not CompareAttributes(findinfo.dwFileAttributes, musthave, canthave) then
    Exit;

  Com_sprintf(findpath, SizeOf(findpath), '%s/%s', [findbase, findinfo.cFileName]);
  Result := findpath;
end;

procedure Sys_FindClose;
begin
  if findhandle <> INVALID_HANDLE_VALUE then
    Windows.FindClose(findhandle);
  findhandle := 0;
end;

initialization

  initialized := False;

end.
