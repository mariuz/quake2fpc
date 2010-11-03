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
{ File(s): qcommon.h (part), files.c                                         }
{ Content: Quake2\QCommon\ dynamic variable tracking                         }
{                                                                            }
{ Initial conversion by : Clootie (Alexey Barkovoy) - clootie@reactor.ru     }
{ Initial conversion on : 13-Jan-2002                                        }
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
{ 1) 19-Jan-2002 - Clootie (clootie@reactor.ru)                              }
{    Updated, now unit uses existing code in QCommon dir instead of stubs.   }
{ 2) 25-Feb-2002 - Clootie (clootie@reactor.ru)                              }
{    Resolved all dependency to Q_Shared.pas.                                }
{ 3) 06-Jun-2002 - Juha Hartikainen (juha@linearteam.org                     }
{  - Changed file handling from pascal style to FileOpen/FileWrite.. style,  }
{    since pascal style handles can't be checked wether they are open or not }
{  - Removed NODEPEND hack                                                   }
{ 4) 19-Jul-2002 - Sly                                                       }
{  - Uses PPointer type declaration in ref.pas                               }
{ 4) 25-Jul-2002 - burnin (leonel@linuxbr.com.br)                            }
{  - Added routines needed by menu.pas to interface section                  }
{  - Only declaring PPCharArray when not Delphi6                             }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{ 1) q_shwin.pas  (unit exist but doesn't compile)                           }
{ 2) cd_win.pas                                                              }
{                                                                            }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{                                                                            }
{----------------------------------------------------------------------------}

// non-dependable compilation will use STUBS for some external symbols

{$IFDEF WIN32}
{$INCLUDE ..\Jedi.inc}
{$ELSE}
{$INCLUDE ../Jedi.inc}
{$ENDIF}

unit Files;

// define this to dissalow any data but the demo pak file
//{$DEFINE NO_ADDONS}

interface

uses
//DELPHI 5
//  D5Compat,
  {$IFDEF LINUX}
  Libc,
  {$ENDIF}
  CVar {, ref};

// From qcommon.h, line 687
(*
==============================================================

FILESYSTEM

==============================================================
*)

procedure FS_InitFilesystem; cdecl;
procedure FS_SetGamedir(dir: PChar); cdecl;
function FS_Gamedir: PChar; cdecl;
function FS_NextPath(prevpath: PChar): PChar; cdecl;
procedure FS_ExecAutoexec; cdecl;

function FS_FOpenFile(filename: PChar; var file_: integer): Integer; cdecl;
procedure FS_FCloseFile(var file_: integer); cdecl;
// note: this can't be called from another DLL, due to MS libc issues

function FS_LoadFile(path: PChar; buffer: PPointer): Integer; cdecl;
// a null buffer will just return the file length without loading
// a -1 length is not present

procedure FS_Read(buffer: Pointer; len: Integer; var file_: integer); cdecl;
// properly handles partial reads

procedure FS_FreeFile(buffer: Pointer); cdecl;

procedure FS_CreatePath(path: PChar); cdecl;

function Developer_searchpath(who: Integer): Integer; cdecl;

function FS_ListFiles(findname: PChar; var numfiles: Integer; musthave, canthave: Cardinal): PPCharArray;

var
  file_from_pak: Integer = 0;
  fs_basedir: cvar_p;
  fs_cddir: cvar_p;
  fs_gamedirvar: cvar_p;

implementation

uses
  CPas,
  SysUtils,
  q_Shared,
  qfiles,
  {$IFDEF WIN32}
  sys_win,
  cd_win,
  q_shwin,
  {$ELSE}
  sys_linux,
  cd_sdl,
  q_shlinux,
  //libc,
  {$ENDIF}
  CMD,
  Common;

// if a packfile directory differs from this, it is assumed to be hacked
const
  // Full version
  PAK0_CHECKSUM = $40E614E0;
  // Demo
  // PAK0_CHECKSUM        = $b2c6d7ea;
  // OEM
  // PAK0_CHECKSUM        = $78e135c;

  (*
  =============================================================================

  QUAKE FILESYSTEM

  =============================================================================
  *)

type
  //
  // in memory
  //

  PackFile_p = ^PackFile_t;
  PackFile_t = record
    name: array[0..MAX_QPATH - 1] of Char;
    filepos: Integer;
    filelen: Integer;
  end;
  PackFile_a = ^PackFile_at;
  PackFile_at = array[0..MaxInt div SizeOf(PackFile_t) - 1] of PackFile_t;

  //Pfile = ^file;

  pack_p = ^pack_t;
  pack_t = record
    filename: array[0..MAX_OSPATH - 1] of Char;
    handle: Integer;
    numfiles: Integer;
    files: PackFile_a;
  end;
  //pack_t = pack_s;

type
  filelink_p = ^filelink_t;
  filelink_t = record
    next: filelink_p;
    from: PChar;
    fromlength: Integer;
    to_: PChar;
  end;
  //filelink_t = filelink_s;

var
  fs_links: filelink_p;
  fs_gamedir_: array[0..MAX_OSPATH - 1] of Char;

type
  searchpath_p = ^searchpath_t;
  searchpath_t = record
    filename: array[0..MAX_OSPATH - 1] of Char;
    pack: pack_p;                       // only one of filename / pack will be used
    next: searchpath_p;
  end;
  //searchpath_t = searchpath_s;

var
  fs_searchpaths: searchpath_p;
  fs_base_searchpaths: searchpath_p;    // without gamedirs

  (*

  All of Quake's data access is through a hierchal file system, but the contents of the file system can be transparently merged from several sources.

  The "base directory" is the path to the directory holding the quake.exe and all game directories.  The sys_* files pass this to host_init in quakeparms_t->basedir.  This can be overridden with the "-basedir" command line parm to allow code debugging in a different directory.  The base directory is
  only used during filesystem initialization.

  The "game directory" is the first tree on the search path and directory that all generated files (savegames, screenshots, demos, config files) will be saved to.  This can be overridden with the "-game" command line parameter.  The game directory can never be changed while quake is executing.  This is a precacution against having a malicious server instruct clients to write files over areas they shouldn't.

  *)

  (*
  ================
  FS_filelength
  ================
  *)

function FS_filelength(file_: Integer): Integer;
var
  CurPos: Integer;
begin
  { Get current position }
  CurPos := FileSeek(file_, 0, 1);
  { Seek to end }
  Result := FileSeek(file_, 0, 2);
  { And restore original position }
  FileSeek(file_, CurPos, 0);
end;

(*
============
FS_CreatePath

Creates any directories needed to store the given filename
============
*)

procedure FS_CreatePath(path: PChar);
var
  ofs: PChar;
begin
  // for (ofs = path+1 ; *ofs ; ofs++)
  ofs := path + 1;
  while (ofs^ <> #0) do
  begin
    if (ofs^ = '/') then
    begin                               // create the directory
      ofs^ := #0;
      Sys_Mkdir(path);
      ofs^ := '/';
    end;
    Inc(ofs)
  end;
end;

(*
==============
FS_FCloseFile

For some reason, other dll's can't just cal fclose()
on files returned by FS_FOpenFile...
==============
*)

procedure FS_FCloseFile(var file_: integer);
begin
  FileClose(file_);
  file_ := 0;
end;

// RAFAEL
(*
 Developer_searchpath
*)

function Developer_searchpath(who: Integer): Integer;
var
  //  ch: Integer;
    // PMM - warning removal
  //   char   *start;
  search: searchpath_p;
begin
  {//Clootie: code below was not used anyway
    if (who = 1) then // xatrix
      ch := 'x'
    else if (who = 2)
      ch := 'r';
  }

    // for (search = fs_searchpaths ; search ; search = search->next)
  search := fs_searchpaths;
  while (search <> nil) do
  begin
    if (StrPos(search.filename, 'xatrix') <> nil) then
    begin
      Result := 1;
      Exit;
    end;

    if (StrPos(search.filename, 'rogue') <> nil) then
    begin
      Result := 2;
      Exit;
    end;
    //Clootie: Code below was originally commented
    (*
        start = strchr (search->filename, ch);

        if (start == NULL)
                continue;

        if (strcmp (start ,"xatrix") == 0)
                return (1);
    *)
    search := search.next;
  end;
  Result := 0;
end;

(*
===========
FS_FOpenFile

Finds the file in the search path.
returns filesize and an open FILE *
Used for streaming data out of either a pak file or
a seperate file.
===========
*)

{$IFNDEF NO_ADDONS}

function FS_FOpenFile(filename: PChar; var file_: integer): Integer;
var
  search: searchpath_p;
  netpath: array[0..MAX_OSPATH - 1] of Char;
  pak: pack_p;
  i: Integer;
  link: filelink_p;
begin
  file_from_pak := 0;

  // check for links first
  // for (link = fs_links ; link ; link=link->next)
  link := fs_links;

  while (link <> nil) do
  begin
    if (strncmp(filename, link.from, link.fromlength) = 0) then // strncmp
    begin
      Com_sprintf(netpath, SizeOf(netpath), '%s%s', [link.to_, filename + link.fromlength]);
      file_ := FileOpen(netpath, fmOpenRead);
      if (file_ <> -1) then
      begin
        Com_DPrintf('link file: %s'#10, [netpath]);
        Result := FS_filelength(file_);
        Exit;
      end;
      file_ := 0;
      Result := -1;
      Exit;
    end;
    link := link.next;
  end;

  //
  // search through the path, one element at a time
  //
    // for (search = fs_searchpaths ; search ; search = search->next)
  search := fs_searchpaths;
  while (search <> nil) do
  begin
    // is the element a pak file?
    if (search.pack <> nil) then
    begin
      // look through all the pak file elements
      pak := search.pack;
      for i := 0 to pak.numfiles - 1 do
      begin
        if (Q_strcasecmp(pak.files[i].name, filename) = 0) then
        begin                           // found it!
          file_from_pak := 1;
          Com_DPrintf('PackFile: %s : %s'#10, [pak.filename, filename]);
          // open a new file on the pakfile
          file_ := FileOpen(pak.filename, fmOpenRead or fmShareDenyNone);
          if (file_ = -1) then
            Com_Error(ERR_FATAL, 'Couldn''t reopen %s', [pak.filename]);
          FileSeek(file_, pak.files[i].filepos, 0);
          Result := pak.files[i].filelen;
          Exit;
        end;
      end;
    end
    else
    begin
      // check a file in the directory tree

      Com_sprintf(netpath, SizeOf(netpath), '%s/%s', [search.filename, filename]);

      file_ := FileOpen(netpath, fmOpenRead);
      if (file_ <> -1) then
      begin
        Com_DPrintf('FindFile: %s'#10, [netpath]);

        Result := FS_filelength(file_);
        Exit;
      end;
    end;

    search := search.next;
  end;

  Com_DPrintf('FindFile: can''t find %s'#10, [filename]);
  file_ := 0;
  Result := -1;
end;

{$ELSE}

// this is just for demos to prevent add on hacking

function FS_FOpenFile(filename: PChar; var file_: integer): Integer;
var
  search: searchpath_p;
  netpath: array[0..MAX_OSPATH - 1] of Char;
  pak: pack_p;
  i: Integer;
begin
  file_from_pak := 0;

  // get config from directory, everything else from pak
  if (StrComp(filename, 'config.cfg') = 0) or (StrLComp(filename, 'players/', 8) = 0) then
  begin
    Com_sprintf(netpath, SizeOf(netpath), '%s/%s', [FS_Gamedir(), filename]);
    file_ := FileOpen(netpath, fmOpenRead);
    if (file_ = -1) then
    begin
      Result := -1;
      Exit;
    end;

    Com_DPrintf('FindFile: %s'#10, [netpath]);

    Result := FS_filelength(file_);
    Exit;
  end;

  // for (search = fs_searchpaths ; search ; search = search->next)
  search := fs_searchpaths;
  while (search <> nil) do
  begin
    if (search.pack <> nil) then
      Break;
    search := search.next;
  end;

  if (search = nil) then
  begin
    Result := -1;
    Exit;
  end;

  pak := search.pack;
  for i := 0 to pak.numfiles - 1 do
  begin
    if (Q_strcasecmp(pak.files[i].name, filename) = 0) then
    begin                               // found it!
      file_from_pak := 1;
      Com_DPrintf('PackFile: %s : %s'#10, [pak.filename, filename]);
      // open a new file on the pakfile
      file_ := FileOpen(pak.filename, fmOpenRead);
      if (file_ = -1) then
        Com_Error(ERR_FATAL, 'Couldn''t reopen %s', [pak.filename]);
      FileSeek(file_, pak.files[i].filepos, 0);
      Result := pak.files[i].filelen;
      Exit;
    end;
  end;

  Com_DPrintf('FindFile: can''t find %s'#10, [filename]);

  Result := -1;
end;

{$ENDIF}

(*
=================
FS_ReadFile

Properly handles partial reads
=================
*)
const
  MAX_READ = $10000;                    // read in blocks of 64k

procedure FS_Read(buffer: Pointer; len: Integer; var file_: integer);
var
  block, remaining: Integer;
  read: Integer;
  buf: PByte;
  tries: Integer;
begin
  buf := PByte(buffer);

  // read in chunks for progress bar
  remaining := len;
  tries := 0;
  while (remaining <> 0) do
  begin
    block := remaining;
    if (block > MAX_READ) then
      block := MAX_READ;
    read := FileRead(file_, buf^, block);
    if (read = 0) then
    begin
      // we might have been trying to read from a CD
      if (tries = 0) then
      begin
        tries := 1;
        CDAudio_Stop;
      end
      else
        Com_Error(ERR_FATAL, 'FS_Read: 0 bytes read', []);
    end;

    if (read = -1) then
      Com_Error(ERR_FATAL, 'FS_Read: -1 bytes read', []);
    if (read <> block) then
      Com_Error(ERR_FATAL, 'FS_Read: read less when requested', []);

    // do some progress bar thing here...

    remaining := remaining - read;
    Inc(buf, read);
  end;
end;

(*
============
FS_LoadFile

Filename are reletive to the quake search path
a null buffer will just return the file length without loading
============
*)

function FS_LoadFile(path: PChar; buffer: PPointer): Integer;
var
  h: integer;
  buf: PByte;
  len: Integer;
begin
  //buf := nil;   // quiet compiler warning //Clootie: not needed in Delphi

// look for it in the filesystem or pack files
  len := FS_FOpenFile(path, h);
  if (len = -1) then                    // (!h)
  begin
    if (buffer <> nil) then
      buffer^ := nil;
    Result := -1;
    Exit;
  end;

  if (buffer = nil) then
  begin
    FileClose(h);
    Result := len;
    Exit;
  end;

  buf := Z_Malloc(len);
  buffer^ := buf;

  FS_Read(buf, len, h);

  FileClose(h);

  Result := len;
end;

(*
=============
FS_FreeFile
=============
*)

procedure FS_FreeFile(buffer: Pointer);
begin
  Z_Free(buffer);
end;

(*
=================
FS_LoadPackFile

Takes an explicit (not game tree related) path to a pak file.

Loads the header and directory, adding the files at the beginning
of the list so they override previous pack files.
=================
*)

function FS_LoadPackFile(packfile: PChar): pack_p;
var
  header: dpackheader_t;
  i: Integer;
  newfiles: PackFile_a;
  numpackfiles: Integer;
  pack: pack_p;
  packhandle: integer;                  //File
  info: array[0..MAX_FILES_IN_PACK - 1] of dpackfile_t;
{$IFDEF NO_ADDONS}
  checksum: Cardinal;
{$ENDIF}
begin
  packhandle := FileOpen(packfile, fmOpenRead or fmShareDenyNone);
  if (packhandle = -1) then
  begin
    Result := nil;
    Exit;
  end;

  FileRead(packhandle, header, sizeof(header)); // fread (&header, 1, sizeof(header), packhandle);
  if (LittleLong(header.ident) <> IDPAKHEADER) then
    Com_Error(ERR_FATAL, '%s is not a packfile', [packfile]);
  header.dirofs := LittleLong(header.dirofs);
  header.dirlen := LittleLong(header.dirlen);

  numpackfiles := header.dirlen div SizeOf(dpackfile_t);

  if (numpackfiles > MAX_FILES_IN_PACK) then
    Com_Error(ERR_FATAL, '%s has %d files', [packfile, numpackfiles]);

  newfiles := Z_Malloc(numpackfiles * SizeOf(packfile_t));

  FileSeek(packhandle, header.dirofs, 0); // fseek (packhandle, header.dirofs, SEEK_SET);
  FileRead(packhandle, info, header.dirlen); // fread (info, 1, header.dirlen, packhandle);

{$IFDEF NO_ADDONS}
  // crc the directory to check for modifications
  checksum := Com_BlockChecksum(@info, header.dirlen);

  if (checksum <> PAK0_CHECKSUM) then
  begin
    Result := nil;
    Exit;
  end;

{$ENDIF}
  // parse the directory
  for i := 0 to numpackfiles - 1 do
  begin
    StrCopy(newfiles[i].name, info[i].name);
    newfiles[i].filepos := LittleLong(info[i].filepos);
    newfiles[i].filelen := LittleLong(info[i].filelen);
  end;

  pack := Z_Malloc(SizeOf(pack_t));
  StrCopy(pack.filename, packfile);
  pack.handle := packhandle;
  pack.numfiles := numpackfiles;
  pack.files := newfiles;

  Com_Printf('Added packfile %s (%d files)'#10, [packfile, numpackfiles]);
  Result := pack;
end;

(*
================
FS_AddGameDirectory

Sets fs_gamedir_, adds the directory to the head of the path,
then loads and adds pak1.pak pak2.pak ...
================
*)

procedure FS_AddGameDirectory(dir: PChar);
var
  i: Integer;
  search: searchpath_p;
  pak: pack_p;
  pakfile: array[0..MAX_OSPATH - 1] of Char;
begin
  StrCopy(fs_gamedir_, dir);

  //
  // add the directory to the search path
  //
  search := Z_Malloc(SizeOf(searchpath_t));
  StrCopy(search.filename, dir);
  search.next := fs_searchpaths;
  fs_searchpaths := search;

  //
  // add any pak files in the format pak0.pak pak1.pak, ...
  //
  for i := 0 to 9 do
  begin
    Com_sprintf(pakfile, SizeOf(pakfile), '%s/pak%d.pak', [dir, i]);
    pak := FS_LoadPackFile(pakfile);
    if (pak = nil) then
      Continue;
    search := Z_Malloc(SizeOf(searchpath_t));
    search.pack := pak;
    search.next := fs_searchpaths;
    fs_searchpaths := search;
  end;
end;

(*
============
FS_Gamedir

Called to find where to write a file (demos, savegames, etc)
============
*)

function FS_Gamedir: PChar;
begin
  if (fs_gamedir_ <> nil) then
    Result := fs_gamedir_
  else
    Result := BASEDIRNAME;
end;

(*
=============
FS_ExecAutoexec
=============
*)

procedure FS_ExecAutoexec;
var
  dir: PChar;
  name: array[0..MAX_QPATH - 1] of Char;
begin
  dir := Cvar_VariableString('gamedir');
  if (dir <> nil) then
    Com_sprintf(name, sizeof(name), '%s/%s/autoexec.cfg', [fs_basedir.string_, dir])
  else
    Com_sprintf(name, sizeof(name), '%s/%s/autoexec.cfg', [fs_basedir.string_, BASEDIRNAME]);
  if (Sys_FindFirst(name, 0, SFF_SUBDIR or SFF_HIDDEN or SFF_SYSTEM) <> nil) then
    Cbuf_AddText('exec autoexec.cfg'#10);
  Sys_FindClose;
end;

(*
================
FS_SetGamedir

Sets the gamedir and path to a different directory.
================
*)

procedure FS_SetGamedir(dir: PChar);
var
  next: searchpath_p;
begin
  if (strstr(dir, '..') <> nil) or (strstr(dir, '/') <> nil) or
    (strstr(dir, '\') <> nil) or (strstr(dir, ':') <> nil) then
  begin
    Com_Printf('Gamedir should be a single filename, not a path'#10);
    Exit;
  end;

  //
  // free up any current game dir info
  //
  while (fs_searchpaths <> fs_base_searchpaths) do
  begin
    if (fs_searchpaths.pack <> nil) then
    begin
      FileClose(fs_searchpaths.pack.handle);
      Z_Free(fs_searchpaths.pack.files);
      Z_Free(fs_searchpaths.pack);
    end;
    next := fs_searchpaths.next;
    Z_Free(fs_searchpaths);
    fs_searchpaths := next;
  end;

  //
  // flush all data, so it will be forced to reload
  //
  if (dedicated <> nil) and (dedicated.value = 0) then
    Cbuf_AddText('vid_restart'#10'snd_restart'#10);

  Com_sprintf(fs_gamedir_, SizeOf(fs_gamedir_), '%s/%s', [fs_basedir.string_, dir]);

  if (strcmp(dir, BASEDIRNAME) = 0) or (dir^ = #0) then
  begin
    Cvar_FullSet('gamedir', '', CVAR_SERVERINFO or CVAR_NOSET);
    Cvar_FullSet('game', '', CVAR_LATCH or CVAR_SERVERINFO);
  end
  else
  begin
    Cvar_FullSet('gamedir', dir, CVAR_SERVERINFO or CVAR_NOSET);
    if (fs_cddir.string_[0] <> #0) then
      FS_AddGameDirectory(va('%s/%s', [fs_cddir.string_, dir]));
    FS_AddGameDirectory(va('%s/%s', [fs_basedir.string_, dir]));
  end;
end;

(*
================
FS_Link_f

Creates a filelink_t
================
*)

procedure FS_Link_f; cdecl;
var
  l: filelink_p;
  prev: ^filelink_p;
begin
  if (Cmd_Argc <> 3) then
  begin
    Com_Printf('USAGE: link <from> <to>'#10);
    Exit;
  end;

  // see if the link already exists
  prev := @fs_links;
  // for (l=fs_links ; l ; l=l->next)
  l := fs_links;
  while (l <> nil) do
  begin
    if (strcmp(l.from, Cmd_Argv(1)) = 0) then
    begin
      Z_Free(l.to_);
      if (StrLen(Cmd_Argv(2)) = 0) then
      begin                             // delete it
        prev^ := l.next;
        Z_Free(l.from);
        Z_Free(l);
        Exit;
      end;
      l.to_ := CopyString(Cmd_Argv(2));
      Exit;
    end;
    prev := @l.next;

    l := l.next;
  end;

  // create a new link
  l := Z_Malloc(SizeOf(l^));
  l.next := fs_links;
  fs_links := l;
  l.from := CopyString(Cmd_Argv(1));
  l.fromlength := StrLen(l.from);
  l.to_ := CopyString(Cmd_Argv(2));
end;

(*
** FS_ListFiles
*)

function FS_ListFiles(findname: PChar; var numfiles: Integer; musthave, canthave: Cardinal): PPCharArray;
var
  s: PChar;
  nfiles: Integer;
  list: PPCharArray;
begin
  nfiles := 0;
  //list := nil; //Clootie: not needed in Delphi

  s := Sys_FindFirst(findname, musthave, canthave);
  while (s <> nil) do
  begin
    if (s[strlen(s) - 1] <> '.') then
      Inc(nfiles);
    s := Sys_FindNext(musthave, canthave);
  end;
  Sys_FindClose;

  if (nfiles = 0) then
  begin
    Result := nil;
    Exit;
  end;

  Inc(nfiles);                          // add space for a guard
  numfiles := nfiles;

  GetMem(list, SizeOf(PChar) * nfiles);
  FillChar(list^, SizeOf(PChar) * nfiles, 0);

  s := Sys_FindFirst(findname, musthave, canthave);
  nfiles := 0;
  while (s <> nil) do
  begin
    if (s[strlen(s) - 1] <> '.') then
    begin
      list[nfiles] := StrNew(s);        // strdup(s)
{$IFDEF WIN32}
      StrLower(list[nfiles]);           // strlwr(list[nfiles]);
{$ENDIF}
      Inc(nfiles);
    end;
    s := Sys_FindNext(musthave, canthave);
  end;
  Sys_FindClose;

  Result := list;
end;

(*
** FS_Dir_f
*)

procedure FS_Dir_f; cdecl;
var
  path: PChar;
  findname: array[0..1023] of Char;
  wildcard: array[0..1023] of Char;
  dirnames: PPCharArray;
  ndirs: Integer;
  tmp: PChar;
  i: Integer;
begin
  path := nil;
  wildcard := '*.*';

  if (Cmd_Argc <> 1) then
  begin
    StrCopy(wildcard, Cmd_Argv(1));
  end;

  path := FS_NextPath(path);
  while (path <> nil) do
  begin
    tmp := findname;

    Com_sprintf(findname, SizeOf(findname), '%s/%s', [path, wildcard]);

    while (tmp^ <> #0) do
    begin
      if (tmp^ = '\') then
        tmp^ := '/';
      Inc(tmp);
    end;
    Com_Printf('Directory of %s'#10, [findname]);
    Com_Printf('----'#10, []);

    dirnames := FS_ListFiles(findname, ndirs, 0, 0);
    if (dirnames <> nil) then
    begin
      for i := 0 to ndirs - 2 do
      begin
        if (StrRScan(dirnames[i], '/') <> nil) then // strrchr( dirnames[i], '/' )
          Com_Printf('%s'#10, [PChar(StrRScan(dirnames[i], '/') + 1)])
        else
          Com_Printf('%s'#10, [dirnames[i]]);

        StrDispose(dirnames[i]);        // free(dirnames[i]);
      end;
      FreeMem(dirnames);                // free(dirnames);
    end;
    Com_Printf(#10, []);
    path := FS_NextPath(path)
  end;
end;

(*
============
FS_Path_f

============
*)

procedure FS_Path_f; cdecl;
var
  s: searchpath_p;
  l: filelink_p;
begin
  Com_Printf('Current search path:'#10, []);
  // for (s=fs_searchpaths ; s ; s=s->next)
  s := fs_searchpaths;
  while (s <> nil) do
  begin
    if (s = fs_base_searchpaths) then
      Com_Printf('----------'#10, []);
    if (s.pack <> nil) then
      Com_Printf('%s (%d files)'#10, [s.pack.filename, s.pack.numfiles])
    else
      Com_Printf('%s'#10, [s.filename]);
    s := s.next;
  end;

  Com_Printf(#10'Links:'#10, []);
  // for (l=fs_links ; l ; l=l->next)
  l := fs_links;
  while (l <> nil) do
  begin
    Com_Printf('%s : %s'#10, [l.from, l.to_]);
    l := l.next;
  end;
end;

(*
================
FS_NextPath

Allows enumerating all of the directories in the search path
================
*)

function FS_NextPath(prevpath: PChar): PChar;
var
  s: searchpath_p;
  prev: PChar;
begin
  if (prevpath = nil) then
  begin
    Result := fs_gamedir_;
    Exit;
  end;

  prev := fs_gamedir_;
  // for (s=fs_searchpaths ; s ; s=s->next)
  s := fs_searchpaths;
  while (s <> nil) do
  begin
    if (s.pack <> nil) then
    begin
      s := s.next;
      Continue;
    end;
    if (prevpath = prev) then
    begin
      Result := s.filename;
      Exit;
    end;
    prev := s.filename;
    s := s.next;
  end;

  Result := nil;
end;

(*
================
FS_InitFilesystem
================
*)

procedure FS_InitFilesystem;
begin
  Cmd_AddCommand('path', @FS_Path_f);
  Cmd_AddCommand('link', @FS_Link_f);
  Cmd_AddCommand('dir', @FS_Dir_f);

  //
  // basedir <path>
  // allows the game to run from outside the data tree
  //
  fs_basedir := Cvar_Get('basedir', '.', CVAR_NOSET);

  //
  // cddir <path>
  // Logically concatenates the cddir after the basedir for
  // allows the game to run from outside the data tree
  //
  fs_cddir := Cvar_Get('cddir', '', CVAR_NOSET);
  if (fs_cddir.string_[0] <> #0) then
    FS_AddGameDirectory(va('%s/' + BASEDIRNAME, [fs_cddir.string_]));

  //
  // start up with baseq2 by default
  //
  FS_AddGameDirectory(va('%s/' + BASEDIRNAME, [fs_basedir.string_]));

  // any set gamedirs will be freed up to here
  fs_base_searchpaths := fs_searchpaths;

  // check for game override
  fs_gamedirvar := Cvar_Get('game', '', CVAR_LATCH or CVAR_SERVERINFO);
  if (fs_gamedirvar.string_[0] <> #0) then
    FS_SetGamedir(fs_gamedirvar.string_);
end;

end.
