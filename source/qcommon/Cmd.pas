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
{ File(s): qcommon.h (part), cmd.c                                           }
{ Content: Quake2\QCommon\                                                   }
{                                                                            }
{ Initial conversion by : D-12 (Thomas.lavergne) - d-12@laposte.net          }
{ Initial conversion on :   -Jan-2002                                        }
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
{ Updated on : 03-jun-2002                                                   }
{ Updated by : Juha Hartikainen (juha@linearteam.org)                        }
{ - Removed NODEPEND hack.                                                   }
{ - Fixed couple places to let this compile right.                    }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{ - cl_main.pas                                                              }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{                                                                            }
{----------------------------------------------------------------------------}

unit cmd;

interface

uses
  q_shared,
  common,
  cl_main,
  SysUtils,
  CPas;

// From Quake2\QCommon\qcommon.h
(*
==============================================================

CMD

Command text buffering and command execution

==============================================================
*)

(*

Any number of commands can be added in a frame, from several different sources.
Most commands come from either keybindings or console line input, but remote
servers can also send across commands and entire text files can be execed.

The + command line options are also added to the command buffer.

The game starts with a Cbuf_AddText ('exec quake.rc'#10); Cbuf_Execute ();

*)

const
  EXEC_NOW = 0;                         // don't return until completed
  EXEC_INSERT = 1;                      // insert at current position, but don't run yet
  EXEC_APPEND = 2;                      // add to end of the command buffer

procedure Cbuf_Init; cdecl;
// allocates an initial text buffer that will grow as needed

procedure Cbuf_AddText(text_: PChar); cdecl;
// as new commands are generated from the console or keybindings,
// the text is added to the end of the command buffer.

procedure Cbuf_InsertText(text_: PChar); cdecl;
// when a command wants to issue other commands immediately, the text is
// inserted at the beginning of the buffer, before any remaining unexecuted
// commands.

procedure Cbuf_ExecuteText(exec_when: Integer; text_: PChar); cdecl;
// this can be used in place of either Cbuf_AddText or Cbuf_InsertText

procedure Cbuf_AddEarlyCommands(clear: qboolean); cdecl;
// adds all the +set commands from the command line

function Cbuf_AddLateCommands: qboolean; cdecl;
// adds all the remaining + commands from the command line
// Returns true if any late commands were added, which
// will keep the demoloop from immediately starting

procedure Cbuf_Execute; cdecl;
// Pulls off \n terminated lines of text from the command buffer and sends
// them through Cmd_ExecuteString.  Stops when the buffer is empty.
// Normally called once per frame, but may be explicitly invoked.
// Do not call inside a command function!

procedure Cbuf_CopyToDefer; cdecl;
procedure Cbuf_InsertFromDefer; cdecl;
// These two functions are used to defer any pending commands while a map
// is being loaded

//===========================================================================

(*

Command execution takes a null terminated string, breaks it into tokens,
then searches for a command or variable that matches the first token.

*)

procedure Cmd_Init; cdecl;

procedure Cmd_AddCommand(cmd_name: PChar; function_: tcdeclproc); cdecl;
// called by the init functions of other parts of the program to
// register commands and functions to call for them.
// The cmd_name is referenced later, so it should not be in temp memory
// if function is NULL, the command will be forwarded to the server
// as a clc_stringcmd instead of executed locally

procedure Cmd_RemoveCommand(cmd_name: PChar); cdecl;

function Cmd_Exists(cmd_name: PChar): qboolean; cdecl;
// used by the cvar code to check for cvar / command name overlap

function Cmd_CompleteCommand(partial: PChar): PChar; cdecl;
// attempts to match a partial command for automatic command line completion
// returns NULL if nothing fits

function Cmd_Argc: Integer; cdecl;
function Cmd_Argv(arg: Integer): PChar; cdecl;
function Cmd_Args: PChar; cdecl;
// The functions that execute commands get their parameters with these
// functions. Cmd_Argv () will return an empty string, not a NULL
// if arg > argc, so string operations are always safe.

procedure Cmd_TokenizeString(text_: PChar; macroExpand: qboolean); cdecl;
// Takes a null terminated string.  Does not need to be /n terminated.
// breaks the string up into arg tokens.

procedure Cmd_ExecuteString(text_: PChar); cdecl;
// Parses a single line of text into arguments and tries to execute it
// as if it was typed at the console

//procedure Cmd_ForwardToServer;
// adds the current command line as a clc_stringcmd to the client message.
// things like godmode, noclip, etc, are commands directed to the server,
// so when they are typed in at the console, they will need to be forwarded.

implementation

uses
  cvar,
  files;

// cmd.c -- Quake script command processing module

const
  MAX_ALIAS_NAME = 32;

type
  cmdalias_p = ^cmdalias_s;
  cmdalias_s = packed record
    next: cmdalias_p;
    name: array[0..MAX_ALIAS_NAME - 1] of Char;
    value: PChar;
  end;
  cmdalias_t = cmdalias_s;

var
  cmd_alias: cmdalias_p;

  cmd_wait: qboolean;

const
  ALIAS_LOOP_COUNT = 16;

var
  alias_count: Integer;

  //=============================================================================

  (*
  ============
  Cmd_Wait_f

  Causes execution of the remainder of the command buffer to be delayed until
  next frame.  This allows commands like:
  bind g "impulse 5 ; +attack ; wait ; -attack ; impulse 2"
  ============
  *)

procedure Cmd_Wait_f; cdecl;
begin
  cmd_wait := True;
end;

(*
=============================================================================

      COMMAND BUFFER

=============================================================================
*)

var
  cmd_text: sizebuf_t;
  cmd_text_buf: array[0..8191] of Char;
  defer_text_buf: array[0..8191] of Char;

  (*
  ============
  Cbuf_Init
  ============
  *)

procedure Cbuf_Init;
begin
  SZ_Init(cmd_text, PByte(@cmd_text_buf[0]), SizeOf(cmd_text_buf));
end;

(*
============
Cbuf_AddText

Adds command text at the end of the buffer
============
*)

procedure Cbuf_AddText(text_: PChar);
var
  l: Integer;
begin
  l := StrLen(text_);
  if (cmd_text.cursize + l) >= cmd_text.maxsize then
  begin
    Com_Printf('Cbuf_AddText: overflow'#10, []);
    Exit;
  end;
  SZ_Write(cmd_text, text_, strlen(text_));
end;

(*
============
Cbuf_InsertText

Adds command text immediately after the current command
Adds a \n(#10) to the text
FIXME: actually change the command buffer to do less copying
============
*)

procedure Cbuf_InsertText(text_: PChar);
var
  temp: PChar;
  templen: Integer;
begin
  // copy off any commands still remaining in the exec buffer
  templen := cmd_text.cursize;
  if templen <> 0 then
  begin
    temp := Z_Malloc(templen);
    memcpy(temp, cmd_text.data, templen);
    SZ_Clear(cmd_text);
  end
  else
    temp := nil;                        // shut up compiler

  // add the entire text of the file
  Cbuf_AddText(text_);

  // add the copied off data
  if templen <> 0 then
  begin
    SZ_Write(cmd_text, temp, templen);
    Z_Free(temp);
  end;
end;

(*
============
Cbuf_CopyToDefer
============
*)

procedure Cbuf_CopyToDefer;
begin
  memcpy(@defer_text_buf[0], @cmd_text_buf[0], cmd_text.cursize);
  defer_text_buf[cmd_text.cursize] := #0;
  cmd_text.cursize := 0;
end;

(*
============
Cbuf_InsertFromDefer
============
*)

procedure Cbuf_InsertFromDefer;
begin
  Cbuf_InsertText(@defer_text_buf);
  defer_text_buf[0] := #0;
end;

(*
============
Cbuf_ExecuteText
============
*)

procedure Cbuf_ExecuteText(exec_when: Integer; text_: PChar);
begin
  case exec_when of
    EXEC_NOW: Cmd_ExecuteString(text_);
    EXEC_INSERT: Cbuf_InsertText(text_);
    EXEC_APPEND: Cbuf_AddText(text_);
  else
    Com_Error(ERR_FATAL, 'Cbuf_ExecuteText: bad exec_when', []);
  end;
end;

(*
============
Cbuf_Execute
============
*)

procedure Cbuf_Execute;
var
  i: Integer;
  text_: PChar;
  line: array[0..1023] of Char;
  quotes: Integer;
begin
  alias_count := 0;                     // don't allow infinite alias loops

  while cmd_text.cursize <> 0 do
  begin
    // find a \n(#10) or ; line break
    text_ := PChar(cmd_text.data);

    quotes := 0;
    for i := 0 to cmd_text.cursize - 1 do
    begin
      if (text_[i] = '"') then
        Inc(quotes);
      if ((not ((quotes and 1) <> 0)) and (text_[i] = ';')) then
        Break;
      if (text_[i] = #10) then
        Break;
    end;

    memcpy(@line, text_, i);
    line[i] := #0;

    // delete the text from the command buffer and move remaining commands down
    // this is necessary because commands (exec, alias) can insert data at the
    // beginning of the text buffer

    if (i = cmd_text.cursize) then
    begin
      cmd_text.cursize := 0;
    end
    else
    begin
      Inc(i);
      Dec(cmd_text.cursize, i);
      memmove(text_, text_ + i, cmd_text.cursize);
    end;

    // execute the command line
    Cmd_ExecuteString(line);

    if cmd_wait then
    begin
      //skip out while text still remains in buffer, leaving it
      // for next frame
      cmd_wait := false;
      Break;
    end;
  end;
end;

(*
===============
Cbuf_AddEarlyCommands

Adds command line parameters as script statements
Commands lead with a +, and continue until another +

Set commands are added early, so they are guaranteed to be set before
the client and server initialize for the first time.

Other commands are added late, after all initialization is complete.
===============
*)

procedure Cbuf_AddEarlyCommands(clear: qboolean);
var
  i: Integer;
  s: PChar;
begin
  i := 0;
  while i < COM_Argc do
  begin
    s := COM_Argv(i);
    if strcmp(s, '+set') <> 0 then
    begin
      Inc(i, 1);
      Continue;
    end;
    Cbuf_AddText(va('set %s %s'#10, [COM_Argv(i + 1), COM_Argv(i + 2)]));
    if clear then
    begin
      COM_ClearArgv(i);
      COM_ClearArgv(i + 1);
      COM_ClearArgv(i + 2);
    end;
    Inc(i, 3);
  end;
end;

(*
=================
Cbuf_AddLateCommands

Adds command line parameters as script statements
Commands lead with a + and continue until another + or -
quake +vid_ref gl +map amlev1

Returns true if any late commands were added, which
will keep the demoloop from immediately starting
=================
*)

function Cbuf_AddLateCommands: qboolean;
var
  i, j: Integer;
  s: Integer;
  c: Char;
  text_, build: PChar;
  argc: Integer;
begin
  // build the combined string to parse from
  s := 0;
  argc := COM_Argc;
  for i := 1 to argc - 1 do
    Inc(s, strlen(COM_Argv(i)) + 1);
  if s = 0 then
  begin
    Result := False;
    Exit;
  end;

  text_ := Z_Malloc(s + 1);
  text_[0] := #0;
  for i := 1 to argc - 1 do
  begin
    StrCat(text_, COM_Argv(i));
    if i <> (argc - 1) then
      strcat(text_, ' ');
  end;

  // pull out the commands
  build := Z_Malloc(s + 1);
  build[0] := #0;

  i := 0;
  while i < s - 1 do
  begin
    if text_[i] = '+' then
    begin
      Inc(i);

      j := i;
      while (text_[j] <> '+') and (text_[j] <> '-') and (text_[j] <> #0) do
        Inc(j);

      c := text_[j];
      text_[j] := #0;

      strcat(build, text_ + i);
      strcat(build, #10);
      text_[j] := c;
      i := j - 1;
    end;
    Inc(i);
  end;

  Result := build[0] <> #0;
  if Result then
    Cbuf_AddText(build);

  Z_Free(text_);
  Z_Free(build);
end;

(*
==============================================================================

      SCRIPT COMMANDS

==============================================================================
*)

(*
===============
Cmd_Exec_f
===============
*)

procedure Cmd_Exec_f; cdecl;
var
  f, f2: PChar;
  len: Integer;
begin
  if Cmd_Argc <> 2 then
  begin
    Com_Printf('exec <filename> : execute a script file'#10, []);
    Exit;
  end;

  len := FS_LoadFile(Cmd_Argv(1), @f);
  if f = nil then
  begin
    Com_Printf('couldn''t exec %s'#10, [Cmd_Argv(1)]);
    Exit;
  end;
  Com_Printf('execing %s'#10, [Cmd_Argv(1)]);

  // the file doesn't have a trailing 0, so we need to copy it off
  f2 := Z_Malloc(len + 1);
  memcpy(f2, f, len);
  f2[len] := #0;

  Cbuf_InsertText(f2);

  Z_Free(f2);
  FS_FreeFile(f);
end;

(*
===============
Cmd_Echo_f

Just prints the rest of the line to the console
===============
*)

procedure Cmd_Echo_f; cdecl;
var
  i: Integer;
begin
  for i := 1 to Cmd_Argc - 1 do
    Com_Printf('%s ', [Cmd_Argv(i)]);
  Com_Printf(#10, []);
end;

(*
===============
Cmd_Alias_f

Creates a new command that executes a command string (possibly ; seperated)
===============
*)

procedure Cmd_Alias_f; cdecl;
var
  a: cmdalias_p;
  cmd: array[0..1023] of Char;
  i, c: Integer;
  s: PChar;
begin
  if Cmd_Argc = 1 then
  begin
    Com_Printf('Current alias commands:'#10, []);
    a := cmd_alias;
    while a <> nil do
    begin
      Com_Printf('%s : %s'#10, [a^.name, a^.value]);
      a := a^.next;
    end;
    Exit;
  end;

  s := Cmd_Argv(1);
  if strlen(s) >= MAX_ALIAS_NAME then
  begin
    Com_Printf('Alias name is too long'#10, []);
    Exit;
  end;

  // if the alias already exists, reuse it
  a := cmd_alias;
  while a <> nil do
  begin
    if strcmp(s, @a^.name) = 0 then
    begin
      Z_Free(a^.value);
      break;
    end;
    a := a^.next;
  end;

  if a = nil then
  begin
    a := Z_Malloc(SizeOf(cmdalias_t));
    a^.next := cmd_alias;
    cmd_alias := a;
  end;
  strcpy(@a^.name, s);

  // copy the rest of the command line
  cmd[0] := #0;
  c := Cmd_Argc;
  for i := 2 to c - 1 do
  begin
    StrCat(cmd, Cmd_Argv(i));
    if i <> (c - 1) then
      StrCat(cmd, ' ');
  end;
  StrCat(cmd, #10);

  a^.value := CopyString(cmd);
end;

(*
=============================================================================

     COMMAND EXECUTION

=============================================================================
*)

type
  cmd_function_p = ^cmd_function_s;
  cmd_function_s = packed record
    next: cmd_function_p;
    name: PChar;
    function_: tcdeclproc;
  end;
  cmd_function_t = cmd_function_s;

var
  cmd_argc_: Integer;
  cmd_argv_: array[0..MAX_STRING_TOKENS - 1] of PChar;
  cmd_null_string: PChar = '';
  cmd_args_: array[0..MAX_STRING_CHARS - 1] of Char;

  cmd_functions: cmd_function_p;

  (*
  ============
  Cmd_Argc
  ============
  *)

function Cmd_Argc: Integer; cdecl;
begin
  Result := cmd_argc_;
end;

(*
============
Cmd_Argv
============
*)

function Cmd_Argv(arg: Integer): PChar;
begin
  if arg >= cmd_argc_ then
    Result := cmd_null_string
  else
    Result := Cmd_Argv_[arg];
end;

(*
============
Cmd_Args

Returns a single string containing argv(1) to argv(argc()-1)
============
*)

function Cmd_Args: PChar;
begin
  Result := cmd_args_;
end;

(*
======================
Cmd_MacroExpandString
======================
*)

function Cmd_MacroExpandString(text_: PChar): PChar;
const
  expanded: array[0..MAX_STRING_CHARS - 1] of Char = #0;
var
  i, j, count, len: Integer;
  inquote: qboolean;
  scan: PChar;
  temporary: array[0..MAX_STRING_CHARS - 1] of Char;
  token, start: PChar;
label
  CONTINUE_;
begin
  inquote := False;
  scan := text_;

  len := strlen(scan);
  if len >= MAX_STRING_CHARS then
  begin
    Com_Printf('Line exceeded %d chars, discarded.'#10, [MAX_STRING_CHARS]);
    Result := nil;
    Exit;
  end;

  count := 0;

  i := 0;
  while (i < len) do
  begin
    if scan[i] = '"' then
      inquote := not inquote;           //inquote := inquote xor 1;
    if inquote then
      goto CONTINUE_;                   // don't expand inside quotes
    if scan[i] <> '$' then
      goto CONTINUE_;
    // scan out the complete macro
    start := scan + i + 1;
    token := COM_Parse(start);
    if start <> nil then
      goto CONTINUE_;

    token := Cvar_VariableString(token);

    j := strlen(token);
    Inc(len, j);
    if len >= MAX_STRING_CHARS then
    begin
      Com_Printf('Expanded line exceeded %d chars, discarded.', [MAX_STRING_CHARS]);
      Result := nil;
      Exit;
    end;

    strncpy(temporary, scan, i);
    strcpy(temporary + i, token);
    strcpy(temporary + i + j, start);

    strcpy(expanded, temporary);
    scan := expanded;
    Dec(i);

    Inc(count);
    if count = 100 then
    begin
      Com_Printf('Macro expansion loop, discarded.'#10, []);
      Result := nil;
      Exit;
    end;
    CONTINUE_:
    Inc(i);
  end;

  if inquote then
  begin
    Com_Printf('Line has unmatched quote, discarded.'#10, []);
    Result := nil;
    Exit;
  end;

  Result := scan;
end;

(*
============
Cmd_TokenizeString

Parses the given string into command line tokens.
$Cvars will be expanded unless they are in a quoted token
============
*)

procedure Cmd_TokenizeString(text_: PChar; macroExpand: qboolean);
var
  i: Integer;
  com_token: PChar;
  l: Integer;
begin
  // clear the args from the last string
  for i := 0 to cmd_argc_ - 1 do
    Z_Free(cmd_argv_[i]);

  cmd_argc_ := 0;
  cmd_args[0] := #0;

  // macro expand the text
  if macroExpand then
    text_ := Cmd_MacroExpandString(text_);
  if text_ = nil then
    Exit;

  while True do
  begin
    // skip whitespace up to a /n
    while (text_^ <> #0) and (text_^ <= ' ') and (text_^ <> #10) do
      Inc(text_);

    if text_^ = #10 then
    begin                               // a newline seperates commands in the buffer
      Inc(text_);
      Break;
    end;

    if text_^ = #0 then
      Exit;

    // set cmd_args to everything after the first arg
    if cmd_argc_ = 1 then
    begin
      strcpy(cmd_args_, text_);

      // strip off any trailing whitespace
      l := strlen(cmd_args_) - 1;
      while l >= 0 do
      begin
        if cmd_args_[l] <= ' ' then
          cmd_args_[l] := #0
        else
          Break;
        Dec(l);
      end;
    end;

    com_token := COM_Parse(text_);
    if text_ = nil then
      Exit;

    if cmd_argc_ < MAX_STRING_TOKENS then
    begin
      cmd_argv_[cmd_argc_] := Z_Malloc(strlen(com_token) + 1);
      strcpy(cmd_argv_[cmd_argc_], com_token);
      Inc(cmd_argc_);
    end;
  end;
end;

(*
============
Cmd_AddCommand
============
*)

procedure Cmd_AddCommand(cmd_name: PChar; function_: tcdeclproc); cdecl;
var
  cmd: cmd_function_p;
begin
  // fail if the command is a variable name
  if Cvar_VariableString(cmd_name)[0] <> #0 then
  begin
    Com_Printf('Cmd_AddCommand: %s already defined as a var'#10, [cmd_name]);
    Exit;
  end;

  // fail if the command already exists
  cmd := cmd_functions;
  while cmd <> nil do
  begin
    if strcmp(cmd_name, cmd^.name) = 0 then
    begin
      Com_Printf('Cmd_AddCommand: %s already defined'#10, [cmd_name]);
      Exit;
    end;
    cmd := cmd^.next;
  end;

  cmd := Z_Malloc(SizeOf(cmd_function_t));
  cmd^.name := cmd_name;
  cmd^.function_ := function_;
  cmd^.next := cmd_functions;
  cmd_functions := cmd;
end;

(*
============
Cmd_RemoveCommand
============
*)

procedure Cmd_RemoveCommand(cmd_name: PChar); cdecl;
type
  cmd_function_pp = ^cmd_function_p;
var
  cmd: cmd_function_p;
  back: cmd_function_pp;
begin
  back := @cmd_functions;
  while True do
  begin
    cmd := back^;
    if cmd = nil then
    begin
      Com_Printf('Cmd_RemoveCommand: %s not added'#10, [cmd_name]);
      Exit;
    end;
    if strcmp(cmd_name, cmd^.name) = 0 then
    begin
      back^ := cmd^.next;
      Z_Free(cmd);
      Exit;
    end;
    back := @cmd^.next;
  end;
end;

(*
============
Cmd_Exists
============
*)

function Cmd_Exists(cmd_name: PChar): qboolean;
var
  cmd: cmd_function_p;
begin
  cmd := cmd_functions;
  while cmd <> nil do
  begin
    if strcmp(cmd_name, cmd^.name) = 0 then
    begin
      Result := True;
      Exit;
    end;
    cmd := cmd^.next;
  end;
  Result := False;
end;

(*
============
Cmd_CompleteCommand
============
*)

function Cmd_CompleteCommand(partial: PChar): PChar;
var
  cmd: cmd_function_p;
  len: Integer;
  a: cmdalias_p;
begin
  len := strlen(partial);

  if len = 0 then
  begin
    Result := nil;
    Exit;
  end;

  // check for exact match
  cmd := cmd_functions;
  while cmd <> nil do
  begin
    if strcmp(partial, cmd^.name) = 0 then
    begin
      Result := cmd^.name;
      Exit;
    end;
    cmd := cmd^.next;
  end;
  a := cmd_alias;
  while a <> nil do
  begin
    if strcmp(partial, a^.name) = 0 then
    begin
      Result := a^.name;
      Exit;
    end;
    a := a^.next;
  end;

  // check for partial match
  cmd := cmd_functions;
  while cmd <> nil do
  begin
    if strncmp(partial, cmd^.name, len) = 0 then
    begin
      Result := cmd^.name;
      Exit;
    end;
    cmd := cmd^.next;
  end;
  a := cmd_alias;
  while a <> nil do
  begin
    if strncmp(partial, a^.name, len) = 0 then
    begin
      Result := a^.name;
      Exit;
    end;
    a := a^.next;
  end;

  Result := nil;
end;

(*
============
Cmd_ExecuteString

A complete command line has been parsed, so try to execute it
FIXME: lookupnoadd the token to speed search?
============
*)

procedure Cmd_ExecuteString(text_: PChar);
var
  cmd: cmd_function_p;
  a: cmdalias_p;
begin
  Cmd_TokenizeString(text_, True);

  // execute the command line
  if Cmd_Argc() = 0 then
    Exit;                               // no tokens

  // check functions
  cmd := cmd_functions;
  while cmd <> nil do
  begin
    if Q_strcasecmp(cmd_argv_[0], cmd^.name) = 0 then
    begin
      if not Assigned(cmd^.function_) then
        Cmd_ExecuteString(va('cmd %s', [text_])) // forward to server command
      else
        cmd^.function_;
      Exit;
    end;
    cmd := cmd^.next;
  end;

  // check alias
  a := cmd_alias;
  while a <> nil do
  begin
    if Q_strcasecmp(cmd_argv_[0], a^.name) = 0 then
    begin
      Inc(alias_count);
      if alias_count = ALIAS_LOOP_COUNT then
      begin
        Com_Printf('ALIAS_LOOP_COUNT'#10, []);
        Exit;
      end;
      Cbuf_InsertText(a^.value);
      Exit;
    end;
    a := a^.next;
  end;

  // check cvars
  if Cvar_Command then
    Exit;

  // send it as a server command if we are connected
  Cmd_ForwardToServer;
end;

(*
============
Cmd_List_f
============
*)

procedure Cmd_List_f; cdecl;
var
  cmd: cmd_function_p;
  i: Integer;
begin
  i := 0;
  cmd := cmd_functions;
  while cmd <> nil do
  begin
    Com_Printf('%s'#10, [cmd^.name]);
    Inc(i);
    cmd := cmd^.next;
  end;
  Com_Printf('%d commands'#10, [i]);
end;

(*
============
Cmd_Init
============
*)

procedure Cmd_Init;
begin
  //
  // register our commands
  //
  Cmd_AddCommand('cmdlist', Cmd_List_f);
  Cmd_AddCommand('exec', Cmd_Exec_f);
  Cmd_AddCommand('echo', Cmd_Echo_f);
  Cmd_AddCommand('alias', Cmd_Alias_f);
  Cmd_AddCommand('wait', Cmd_Wait_f);
end;

end.
