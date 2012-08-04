{%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
{ File(s): qcommon.h (part), CVar.c                                          }
{ Content: Quake2\QCommon\ dynamic variable tracking                         }
{                                                                            }
{ Initial conversion by : Clootie (Alexey Barkovoy) - clootie@reactor.ru     }
{ Initial conversion on : 12-Jan-2002                                        }
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
{    Now all external dependencies are cleaned up.                           }
{                                                                            }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{     NONE                                                                   }
{                                                                            }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{ 1) Clootie: Still waiting for someone to fully convert q_shared.pas        }
{                                                                            }
{----------------------------------------------------------------------------}

unit CVar;

interface

uses
  {$IFDEF WIN32}
  Windows,
  {$ENDIF}
  SysUtils,
  Q_Shared;

(*
==========================================================

CVARS (console variables)

==========================================================
*)
type
  cvar_p = Q_Shared.cvar_p;
  cvar_t = Q_Shared.cvar_t;

  // From "QShared.h" line 297
  //todo: Clootie: This should be removed when Q_Shared will be stabilized
  (*
  const
    CVAR_ARCHIVE           = 1;    // set to cause it to be saved to vars.rc
    CVAR_USERINFO           = 2;    // added to userinfo  when changed
    CVAR_SERVERINFO   = 4;    // added to serverinfo when changed
    CVAR_NOSET      = 8;    // don't allow change from console at all,
                                  // but can be set from the command line
    CVAR_LATCH      = 16;   // save changes until server restart

  // nothing outside the Cvar_*() functions should modify these fields!
  type
    cvar_p = ^cvar_t;
    cvar_s = record
      name        : PChar;
      string_     : PChar;
      latched_string: PChar;   // for CVAR_LATCH vars
      flags       : Integer;
      modified    : qboolean;   // set each time the cvar is changed
      value       : Single;
      next        : cvar_p;
    end;
    cvar_t = cvar_s;
  *)

  (*
  =============================================================

  CVAR

  ==============================================================
  *)

  (*

  cvar_t variables are used to hold scalar or string variables that can be
  changed or displayed at the console or prog code as well as accessed directly
  in C code.

  The user can access cvars from the console in three ways:
  r_draworder         prints the current value
  r_draworder 0      sets the current value to 0
  set r_draworder 0   as above, but creates the cvar if not present
  Cvars are restricted from having the same names as commands to keep this
  interface from being ambiguous.
  *)

var
  cvar_vars: cvar_p;

function Cvar_Get(var_name, var_value: PChar; flags: Integer): cvar_p; cdecl;
// creates the variable if it doesn't exist, or returns the existing one
// if it exists, the value will not be changed, but flags will be ORed in
// that allows variables to be unarchived without needing bitflags

function Cvar_Set(var_name, value: PChar): cvar_p; cdecl;
// will create the variable if it doesn't exist

function Cvar_ForceSet(var_name, value: PChar): cvar_p; cdecl;
// will set the variable even if NOSET or LATCH

function Cvar_FullSet(var_name, value: PChar; flags: Integer): cvar_p; cdecl;

procedure Cvar_SetValue(var_name: PChar; value: Single); cdecl;
// expands value to a string and calls Cvar_Set

function Cvar_VariableValue(var_name: PChar): Single; cdecl;
// returns 0 if not defined or non numeric

function Cvar_VariableString(var_name: PChar): PChar; cdecl;
// returns an empty string if not defined

function Cvar_CompleteVariable(partial: PChar): PChar; cdecl;
// attempts to match a partial variable name for command line completion
// returns NULL if nothing fits

procedure Cvar_GetLatchedVars; cdecl;
// any CVAR_LATCHED variables that have been set will now take effect

function Cvar_Command: qboolean; cdecl;
// called by Cmd_ExecuteString when Cmd_Argv(0) doesn't match a known
// command.  Returns true if the command was a variable reference that
// was handled. (print or change)

procedure Cvar_WriteVariables(path: PChar); cdecl;
// appends lines containing "set variable value" for all variables
// with the archive flag set to true.

procedure Cvar_Init; cdecl;

function Cvar_Userinfo_: PChar; cdecl;
// returns an info string containing all the CVAR_USERINFO cvars

function Cvar_Serverinfo_: PChar; cdecl;
// returns an info string containing all the CVAR_SERVERINFO cvars

var
  userinfo_modified: qboolean;
  // this is set each time a CVAR_USERINFO variable is changed
  // so that the client knows to send it to the server

implementation

uses
  Common,
  Files,
  CPas;

(*
============
Cvar_InfoValidate
============
*)
//static qboolean Cvar_InfoValidate (char *s)

function Cvar_InfoValidate(s: PChar): qboolean;
begin
  if (StrPos(s, '\') <> nil) then
    Result := False
  else if (StrPos(s, '"') <> nil) then
    Result := False
  else if (StrPos(s, ';') <> nil) then
    Result := False
  else
    Result := True;
end;

(*
============
Cvar_FindVar
============
*)
// static cvar_t *Cvar_FindVar (char *var_name)

function Cvar_FindVar(var_name: PChar): cvar_p;
var
  var_: cvar_p;
begin
  // for (var=cvar_vars ; var ; var=var->next)
  var_ := cvar_vars;
  while (var_ <> nil) do
  begin
    if (StrComp(var_name, var_.name) = 0) then
    begin
      Result := var_;
      Exit;
    end;
    var_ := var_.next;
  end;

  Result := nil;
end;

(*
============
Cvar_VariableValue
============
*)

function Cvar_VariableValue(var_name: PChar): Single;
var
  var_: cvar_p;
begin
  var_ := Cvar_FindVar(var_name);
  if (var_ = nil) then
    Result := 0
  else
    Result := atof(var_.string_);
end;

(*
============
Cvar_VariableString
============
*)

function Cvar_VariableString(var_name: PChar): PChar;
var
  var_: cvar_p;
begin
  var_ := Cvar_FindVar(var_name);
  if (var_ = nil) then
    Result := ''
  else
    Result := var_.string_;
end;

(*
============
Cvar_CompleteVariable
============
*)

function Cvar_CompleteVariable(partial: PChar): PChar;
var
  cvar: cvar_p;
  len: Integer;
begin
  Result := nil;

  len := StrLen(partial);
  if (len = 0) then
    Exit;

  // check exact match
  // for (cvar=cvar_vars ; cvar ; cvar=cvar->next)
  cvar := cvar_vars;
  while (cvar <> nil) do
  begin
    if (StrComp(partial, cvar.name) = 0) then
    begin
      Result := cvar.name;
      Exit;
    end;
    cvar := cvar.next;
  end;

  // check partial match
  // for (cvar=cvar_vars ; cvar ; cvar=cvar->next)
  cvar := cvar_vars;
  while (cvar <> nil) do
  begin
    if (StrLComp(partial, cvar.name, len) = 0) then
    begin
      Result := cvar.name;
      Exit;
    end;
    cvar := cvar.next;
  end;
end;

(*
============
Cvar_Get

If the variable already exists, the value will not be set
The flags will be or'ed in if the variable exists.
============
*)

function Cvar_Get(var_name, var_value: PChar; flags: Integer): cvar_p;
var
  var_: cvar_p;
begin
  Result := nil;

  if (flags and (CVAR_USERINFO or CVAR_SERVERINFO) <> 0) then
  begin
    if not Cvar_InfoValidate(var_name) then
    begin
      Com_Printf('invalid info cvar name'#10, ['']);
      Exit;
    end;
  end;

  var_ := Cvar_FindVar(var_name);
  if Assigned(var_) then
  begin
    var_.flags := var_.flags or flags;
    Result := var_;
    Exit;
  end;

  if (var_value = nil) then
    Exit;

  if (flags and (CVAR_USERINFO or CVAR_SERVERINFO) <> 0) then
  begin
    if not Cvar_InfoValidate(var_value) then
    begin
      Com_Printf('invalid info cvar value'#10, []);
      Exit;
    end;
  end;

  var_ := Z_Malloc(SizeOf(var_^));
  var_.name := CopyString(var_name);
  var_.string_ := CopyString(var_value);
  var_.modified := True;
  var_.value := atof(var_.string_);
  // link the variable in
  var_.next := cvar_vars;
  cvar_vars := var_;

  var_.flags := flags;

  Result := var_;
end;

(*
============
Cvar_Set2
============
*)

function Cvar_Set2(var_name, value: PChar; force: qboolean): cvar_p;
var
  var_: cvar_p;
begin
  var_ := Cvar_FindVar(var_name);
  if (var_ = nil) then
  begin                                 // create it
    Result := Cvar_Get(var_name, value, 0);
    Exit;
  end;

  if (var_.flags and (CVAR_USERINFO or CVAR_SERVERINFO) <> 0) then
  begin
    if not Cvar_InfoValidate(value) then
    begin
      Com_Printf('invalid info cvar value'#10, []);
      Result := var_;
      Exit;
    end;
  end;

  if (not force) then
  begin
    if ((var_.flags and CVAR_NOSET) <> 0) then
    begin
      Com_Printf('%s is write protected.'#10, [var_name]);
      Result := var_;
      Exit;
    end;

    if (var_.flags and CVAR_LATCH) <> 0 then
    begin
      if (var_.latched_string <> nil) then
      begin
        if (StrComp(value, var_.latched_string) = 0) then
        begin
          Result := var_;
          Exit;
        end;
        Z_Free(var_.latched_string);
      end
      else
      begin
        if (StrComp(value, var_.string_) = 0) then
        begin
          Result := var_;
          Exit;
        end;
      end;

      if (Com_ServerState <> 0) then
      begin
        Com_Printf('%s will be changed for next game.'#10, [var_name]);
        var_.latched_string := CopyString(value);
      end
      else
      begin
        var_.string_ := CopyString(value);
        var_.value := atof(var_.string_);
        if (StrComp(var_.name, 'game') = 0) then
        begin
          FS_SetGamedir(var_.string_);
          FS_ExecAutoexec;
        end;
      end;
      Result := var_;
      Exit;
    end;
  end
  else
  begin
    if (var_.latched_string <> nil) then
    begin
      Z_Free(var_.latched_string);
      var_.latched_string := nil;
    end;
  end;

  if (StrComp(value, var_.string_) = 0) then
  begin
    Result := var_;                     // not changed
    Exit;
  end;

  var_.modified := True;

  if (var_.flags and CVAR_USERINFO) <> 0 then
    userinfo_modified := True;          // transmit at next oportunity

  Z_Free(var_.string_);                 // free the old value string

  var_.string_ := CopyString(value);
  var_.value := atof(var_.string_);
  Result := var_;
end;

(*
============
Cvar_ForceSet
============
*)

function Cvar_ForceSet(var_name, value: PChar): cvar_p;
begin
  Result := Cvar_Set2(var_name, value, true);
end;

(*
============
Cvar_Set
============
*)

function Cvar_Set(var_name, value: PChar): cvar_p;
begin
  Result := Cvar_Set2(var_name, value, false);
end;

(*
============
Cvar_FullSet
============
*)

function Cvar_FullSet(var_name, value: PChar; flags: Integer): cvar_p;
var
  var_: cvar_p;
begin
  var_ := Cvar_FindVar(var_name);
  if (var_ = nil) then
  begin                                 // create it
    Result := Cvar_Get(var_name, value, flags);
    Exit;
  end;

  var_.modified := true;

  if (var_.flags and CVAR_USERINFO) <> 0 then
    userinfo_modified := True;          // transmit at next oportunity

  Z_Free(var_.string_);                 // free the old value string

  var_.string_ := CopyString(value);
  var_.value := atof(var_.string_);
  var_.flags := flags;

  Result := var_;
end;

(*
============
Cvar_SetValue
============
*)

procedure Cvar_SetValue(var_name: PChar; value: Single);
var
  val: array[0..31] of Char;
  i: Integer;
begin
  if (value = Round(value)) then
    Com_sprintf(val, sizeof(val), '%d', [Round(value)])
  else
    Com_sprintf(val, sizeof(val), '%f', [value]);
  // Juha: Hack to make sure that we use DOT as decimal separator, since
  // Delphi takes it from Windows international settings.
  for i := 0 to 31 do
    if val[i] = ',' then
      val[i] := '.';
  Cvar_Set(var_name, val);
end;

(*
============
Cvar_GetLatchedVars

Any variables with latched values will now be updated
============
*)

procedure Cvar_GetLatchedVars;
var
  var_: cvar_p;
begin
  // for (var = cvar_vars ; var ; var = var->next)
  var_ := cvar_vars;
  while (var_ <> nil) do
  begin
    if (var_.latched_string = nil) then
    begin
      var_ := var_.next;
      Continue;
    end;
    Z_Free(var_.string_);
    var_.string_ := var_.latched_string;
    var_.latched_string := nil;
    var_.value := atof(var_.string_);
    if (StrComp(var_.name, 'game') = 0) then
    begin
      FS_SetGamedir(var_.string_);
      FS_ExecAutoexec;
    end;
    var_ := var_.next;
  end;
end;

(*
============
Cvar_Command

Handles variable inspection and changing from the console
============
*)

function Cvar_Command: qboolean;
var
  v: cvar_p;
begin
  // check variables
  v := Cvar_FindVar(Cmd_Argv(0));
  if (v = nil) then
  begin
    Result := False;
    Exit;
  end;

  // perform a variable print or set
  if (Cmd_Argc = 1) then
  begin
    Com_Printf('"%s" is "%s"'#10, [v.name, v.string_]);
    Result := True;
    Exit;
  end;

  Cvar_Set(v.name, Cmd_Argv(1));
  Result := true;
end;

(*
============
Cvar_Set_f

Allows setting and defining of arbitrary cvars from console
============
*)

procedure Cvar_Set_f; cdecl;
var
  c: Integer;
  flags: Integer;
begin
  c := Cmd_Argc;
  if (c <> 3) and (c <> 4) then
  begin
    Com_Printf('usage: set <variable> <value> [u / s]'#10, []);
    Exit;
  end;

  if (c = 4) then
  begin
    if (StrComp(Cmd_Argv(3), 'u') = 0) then
      flags := CVAR_USERINFO
    else if (StrComp(Cmd_Argv(3), 's') = 0) then
      flags := CVAR_SERVERINFO
    else
    begin
      Com_Printf('flags can only be ''u'' or ''s'''#10, []);
      Exit;
    end;
    Cvar_FullSet(Cmd_Argv(1), Cmd_Argv(2), flags);
  end
  else
    Cvar_Set(Cmd_Argv(1), Cmd_Argv(2));
end;

(*
============
Cvar_WriteVariables

Appends lines containing "set variable value" for all variables
with the archive flag set to true.
============
*)

procedure Cvar_WriteVariables(path: PChar);
var
  var_: cvar_p;
  buffer: array[0..1024 - 1] of Char;
  f: Integer;
begin
  f := FileOpen(path, fmOpenWrite);
  if f = -1 then
  begin
    f := FileCreate(path);
  end
  else
    FileSeek(f, 0, 2);
  var_ := cvar_vars;
  while (var_ <> nil) do
  begin
    if ((var_.flags and CVAR_ARCHIVE) <> 0) then
    begin
      Com_sprintf(buffer, SizeOf(buffer), 'set %s "%s"'#13#10, [var_.name, var_.string_]);
      FileWrite(f, buffer, strlen(buffer));
    end;
    var_ := var_.next;
  end;
  FileClose(f);
end;

(*
============
Cvar_List_f

============
*)

procedure Cvar_List_f; cdecl;
var
  var_: cvar_p;
  i: Integer;
begin
  i := 0;
  // for (var = cvar_vars ; var ; var = var->next, i++)
  var_ := cvar_vars;
  while (var_ <> nil) do
  begin
    if (var_.flags and CVAR_ARCHIVE) <> 0 then
      Com_Printf('*', [])
    else
      Com_Printf(' ', []);
    if (var_.flags and CVAR_USERINFO) <> 0 then
      Com_Printf('U', [])
    else
      Com_Printf(' ', []);
    if (var_.flags and CVAR_SERVERINFO) <> 0 then
      Com_Printf('S', [])
    else
      Com_Printf(' ', []);
    if (var_.flags and CVAR_NOSET) <> 0 then
      Com_Printf('-', [])
    else if (var_.flags and CVAR_LATCH) <> 0 then
      Com_Printf('L', [])
    else
      Com_Printf(' ', []);
    Com_Printf(' %s "%s"'#10, [var_.name, var_.string_]);

    var_ := var_.next;
    Inc(i);
  end;
  Com_Printf('%d cvars'#10, [i]);
end;

function Cvar_BitInfo(bit: Integer): PChar;
{$WRITEABLECONST ON}
const
  info: array[0..MAX_INFO_STRING - 1] of Char = '';
{$WRITEABLECONST OFF}
var
  var_: cvar_p;
begin
  info[0] := #0;

  // for (var = cvar_vars ; var ; var = var->next)
  var_ := cvar_vars;
  while (var_ <> nil) do
  begin
    if (var_.flags and bit) <> 0 then
      Info_SetValueForKey(info, var_.name, var_.string_);
    var_ := var_.next;
  end;
  Result := info;
end;

// returns an info string containing all the CVAR_USERINFO cvars

function Cvar_Userinfo_: PChar;
begin
  Result := Cvar_BitInfo(CVAR_USERINFO);
end;

// returns an info string containing all the CVAR_SERVERINFO cvars

function Cvar_Serverinfo_: PChar;
begin
  Result := Cvar_BitInfo(CVAR_SERVERINFO);
end;

(*
============
Cvar_Init

Reads in all archived cvars
============
*)

procedure Cvar_Init;
begin
  Cmd_AddCommand('set', Cvar_Set_f);
  Cmd_AddCommand('cvarlist', Cvar_List_f);
end;

end.
