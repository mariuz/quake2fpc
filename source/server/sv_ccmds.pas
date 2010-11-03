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
{ File(s): sv_ccmds                                                          }
{                                                                            }
{ Initial conversion by : Soo Xiangdong (suxid@sina.com)                     }
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
{ Updated on : 10-Jun-2002                                                   }
{ Updated by : Juha Hartikainen (juha@linearteam.org)                        }
{ - Finished conversion (10%->100%)                                          }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{----------------------------------------------------------------------------}
// 25.07.2002 Juha: Proof-readed this unit

unit sv_ccmds;

interface

procedure SV_ReadLevelFile;
procedure SV_InitOperatorCommands();

implementation

uses
  DateUtils,
  SysUtils,
  Server,
  CVar,
  CPas,
  Cmd,
  Common,
  CModel,
  Files,
  {$IFDEF WIN32}
  net_wins,
  q_shwin,
  {$ELSE}
  net_udp,
  q_shlinux,
  {$ENDIF}
  net_chan,
  sv_main,
  sv_game,
  sv_init,
  sv_user,
  sv_send,
  q_shared;

(*==================================================*)
(*                                                  *)
(*OPERATOR CONSOLE ONLY COMMANDS                    *)
(*                                                  *)
(*These commands can only be entered from stdin or  *)
(*by a remote operator datagram                     *)
(*==================================================*)

(*==================================================*)
(*SV_SetMaster_f                                    *)
(*                                                  *)
(*Specify a list of master servers                  *)
(*==================================================*)

procedure SV_SetMaster_f(); cdecl;
var
  i, slot: Integer;
begin
  // only dedicated servers send heartbeats
  if not (dedicated.value <> 0) then
  begin
    Com_Printf('Only dedicated servers use masters.'#10, []);
    exit;
  end;

  // make sure the server is listed public
  Cvar_Set('public', '1');

  for i := 1 to MAX_MASTERS - 1 do
    FillChar(master_adr[i], sizeof(master_adr[i]), 0);

  slot := 1;                            // slot 0 will always contain the id master
  for i := 1 to Cmd_Argc() - 1 do
  begin
    if (slot = MAX_MASTERS) then
      break;
    {$IFDEF WIN32}
    if (not NET_StringToAdr(Cmd_Argv(i), master_adr[i])) then
    {$ELSE}
    if (not NET_StringToAdr(Cmd_Argv(i), @master_adr[i])) then
    {$ENDIF}
    begin
      Com_Printf('Bad address: %s'#10, [Cmd_Argv(i)]);
      continue;
    end;
    if (master_adr[slot].port = 0) then
      master_adr[slot].port := BigShort(PORT_MASTER);

    Com_Printf('Master server at %s'#10, [NET_AdrToString(master_adr[slot])]);
    Com_Printf('Sending a ping.'#10, []);
    Netchan_OutOfBandPrint(NS_SERVER, master_adr[slot], 'ping', []);
    Inc(slot);
  end;
  svs.last_heartbeat := -9999999;
end;

(*
==================================================
SV_SetPlayer

Sets sv_client and sv_player to the player with idnum Cmd_Argv(1)
==================================================
*)

function SV_SetPlayer(): qboolean;
var
  cl: client_p;
  i: integer;
  idnum: integer;
  s: PChar;
begin
  if (Cmd_Argc() < 2) then
  begin
    Result := False;
    exit;
  end;

  s := Cmd_Argv(1);

  // numeric values are just slot numbers
  if (s[0] >= '0') and (s[0] <= '9') then
  begin
    idnum := StrToInt(Cmd_Argv(1));
    if (idnum < 0) or (idnum >= maxclients.value) then
    begin
      Com_Printf('Bad client slot: %i'#10, [idnum]);
      Result := false;
      exit;
    end;

    sv_client := @svs.clients^[idnum];
    sv_player := sv_client.edict;
    if (Integer(sv_client.state) = 0) then
    begin
      Com_Printf('Client %i is not active'#10, [idnum]);
      Result := false;
      exit;
    end;
    Result := true;
    exit;
  end;

  // check for a name match
  for i := 0 to Round(maxclients.value) - 1 do
  begin
    cl := @svs.clients[i];
    if (Integer(cl.state) = 0) then
      continue;
    if (strcmp(cl.name, s) = 0) then
    begin
      sv_client := cl;
      sv_player := sv_client.edict;
      Result := true;
      exit;
    end;
  end;
  Com_Printf('Userid %s is not on the server'#10, [s]);
  Result := false;
end;

(*==================================================

SAVEGAME FILES

==================================================*)

(*==================================================
SV_WipeSavegame
Delete save/<XXX>/
==================================================*)

procedure SV_WipeSavegame(savename: pchar);
var
  name: array[0..MAX_OSPATH - 1] of char;
  s: pchar;
begin
  Com_DPrintf('SV_WipeSaveGame(%s)'#10, [savename]);
  Com_sprintf(name, sizeof(name), '%s/save/%s/server.ssv', [FS_Gamedir(), savename]);
  DeleteFile(name);
  Com_sprintf(name, sizeof(name), '%s/save/%s/game.ssv', [FS_Gamedir(), savename]);
  DeleteFile(name);

  Com_sprintf(name, sizeof(name), '%s/save/%s/*.sav', [FS_Gamedir(), savename]);
  s := Sys_FindFirst(name, 0, 0);
  while (s <> nil) do
  begin
    DeleteFile(s);
    s := Sys_FindNext(0, 0);
  end;
  Sys_FindClose();
  Com_sprintf(name, sizeof(name), '%s/save/%s/*.sv2', [FS_Gamedir(), savename]);
  s := Sys_FindFirst(name, 0, 0);
  while (s <> nil) do
  begin
    DeleteFile(s);
    s := Sys_FindNext(0, 0);
  end;
  Sys_FindClose();
end;

(*==================================================
CopyFile
==================================================*)

procedure CopyFile(src, dst: pchar);
var
  f1, f2: integer;
  l: integer;
  buffer: array[0..65536 - 1] of char;
begin
  Com_DPrintf('CopyFile (%s, %s)'#10, [src, dst]);
  f1 := FileOpen(src, fmOpenRead);
  if f1 = -1 then
    exit;
  f2 := FileCreate(dst);
  if f2 = -1 then
  begin
    FileClose(f1);
    exit;
  end;

  while (true) do
  begin
    l := FileRead(f1, buffer, sizeof(buffer));
    if (l = 0) then
      break;
    FileWrite(f2, buffer, l);
  end;

  FileClose(f1);
  FileClose(f2);
end;

(*==================================================
SV_CopySaveGame
==================================================*)

procedure SV_CopySaveGame(src, dst: pchar);
var
  name, name2: array[0..MAX_OSPATH - 1] of char;
  l, len: integer;
  found: pchar;
begin
  Com_DPrintf('SV_CopySaveGame(%s, %s)'#10, [src, dst]);

  SV_WipeSavegame(dst);

  // copy the savegame over
  Com_sprintf(name, sizeof(name), '%s/save/%s/server.ssv', [FS_Gamedir(), src]);
  Com_sprintf(name2, sizeof(name2), '%s/save/%s/server.ssv', [FS_Gamedir(), dst]);
  FS_CreatePath(name2);
  CopyFile(name, name2);

  Com_sprintf(name, sizeof(name), '%s/save/%s/game.ssv', [FS_Gamedir(), src]);
  Com_sprintf(name2, sizeof(name2), '%s/save/%s/game.ssv', [FS_Gamedir(), dst]);
  CopyFile(name, name2);

  Com_sprintf(name, sizeof(name), '%s/save/%s/', [FS_Gamedir(), src]);
  len := strlen(name);
  Com_sprintf(name, sizeof(name), '%s/save/%s/*.sav', [FS_Gamedir(), src]);
  found := Sys_FindFirst(name, 0, 0);
  while (found <> nil) do
  begin
    strcpy(name + len, found + len);

    Com_sprintf(name2, sizeof(name2), '%s/save/%s/%s', [FS_Gamedir(), dst, found + len]);
    CopyFile(name, name2);

    // change sav to sv2
    l := strlen(name);
    strcpy(name + l - 3, 'sv2');
    l := strlen(name2);
    strcpy(name2 + l - 3, 'sv2');
    CopyFile(name, name2);

    found := Sys_FindNext(0, 0);
  end;
  Sys_FindClose();
end;

(*==================================================
SV_WriteLevelFile
==================================================*)

procedure SV_WriteLevelFile();
var
  name: array[0..MAX_OSPATH - 1] of char;
  f: integer;
begin
  Com_DPrintf('SV_WriteLevelFile()'#10, []);
  Com_sprintf(name, sizeof(name), '%s/save/current/%s.sv2', [FS_Gamedir(), sv.name]);

  f := FileOpen(name, fmOpenReadWrite);

  if f = -1 then
    f := FileCreate(name);

  if f = -1 then
  begin
    Com_Printf('Failed to open %s'#10, [name]);
    exit;
  end;

  FileWrite(f, sv.configstrings, sizeof(sv.configstrings));
  CM_WritePortalState(f);
  FileClose(f);

  Com_sprintf(name, sizeof(name), '%s/save/current/%s.sav', [FS_Gamedir(), sv.name]);
  ge.WriteLevel(name);
end;

(*==================================================
SV_ReadLevelFile

==================================================*)

procedure SV_ReadLevelFile;
var
  name: array[0..MAX_OSPATH - 1] of char;
  f: integer;
begin
  Com_DPrintf('SV_ReadLevelFile()'#10, []);

  Com_sprintf(name, sizeof(name), '%s/save/current/%s.sv2', [FS_Gamedir(), sv.name]);
  f := FileOpen(name, fmOpenRead);
  if (f = -1) then
  begin
    Com_Printf('Failed to open %s'#10, [name]);
    exit;
  end;
  FS_Read(@sv.configstrings, sizeof(sv.configstrings), f);
  CM_ReadPortalState(f);
  FileClose(f);

  Com_sprintf(name, sizeof(name), '%s/save/current/%s.sav', [FS_Gamedir(), sv.name]);
  ge.ReadLevel(name);
end;

(*==================================================
SV_WriteServerFile

==================================================*)

procedure SV_WriteServerFile(autosave: qboolean);
var
  f: integer;
  var_: cvar_p;
  name: array[0..MAX_OSPATH - 1] of char;
  string_: array[0..128 - 1] of char;
  comment: array[0..32 - 1] of char;
  tmp: string;
  year, month, day, hour, minute, second, ms: Word;
label
  continue_;
begin
  if autosave then
    tmp := 'true'
  else
    tmp := 'false';
  Com_DPrintf('SV_WriteServerFile(%s)'#10, [tmp]);

  Com_sprintf(name, sizeof(name), '%s/save/current/server.ssv', [FS_Gamedir()]);
  f := FileOpen(name, fmOpenReadWrite);

  if (f = -1) then
    f := FileCreate(name);

  if (f = -1) then
  begin
    Com_Printf('Couldn''t write %s'#10, [name]);
    exit;
  end;
  // write the comment field
  FillChar(comment, sizeof(comment), 0);

  if (not autosave) then
  begin
    DecodeDateTime(Now, Year, Month, Day, Hour, Minute, Second, Ms);
    Com_sprintf(comment, sizeof(comment), '%2i:%i%i %2i/%2i  ', [Hour
      , Minute div 10, Minute mod 10,
        Month, Day]);
    strncat(comment, sv.configstrings[CS_NAME], sizeof(comment) - 1 - strlen(comment));
  end
  else
  begin                                 // autosaved
    Com_sprintf(comment, sizeof(comment), 'ENTERING %s', [sv.configstrings[CS_NAME]]);
  end;

  FileWrite(f, comment, sizeof(comment));

  // write the mapcmd
  FileWrite(f, svs.mapcmd, sizeof(svs.mapcmd));

  // write all CVAR_LATCH cvars
  // these will be things like coop, skill, deathmatch, etc
  var_ := cvar_vars;
  while (var_ <> nil) do
  begin
    if (not (var_.flags and CVAR_LATCH <> 0)) then
      goto continue_;
    if (strlen(var_.name) >= sizeof(name) - 1)
      or (strlen(var_.string_) >= sizeof(string_) - 1) then
    begin
      Com_Printf('Cvar too long: %s := %s'#10, [var_.name, var_.string_]);
      goto continue_;
    end;
    FillChar(name, sizeof(name), 0);
    FillChar(string_, sizeof(string_), 0);
    strcpy(name, var_.name);
    strcpy(string_, var_.string_);
    FileWrite(f, name, sizeof(name));
    FileWrite(f, string_, sizeof(string_));
    continue_:
    var_ := var_.next;
  end;

  FileClose(f);

  // write game state
  Com_sprintf(name, sizeof(name), '%s/save/current/game.ssv', [FS_Gamedir()]);
  ge.WriteGame(name, autosave);
end;

(*==================================================
SV_ReadServerFile
==================================================*)

procedure SV_ReadServerFile();
var
  f: integer;
  name: array[0..MAX_OSPATH - 1] of char;
  string_: array[0..128 - 1] of char;
  comment: array[0..32 - 1] of char;
  mapcmd: array[0..MAX_TOKEN_CHARS - 1] of char;
begin
  Com_DPrintf('SV_ReadServerFile()'#10, []);

  Com_sprintf(name, sizeof(name), '%s/save/current/server.ssv', [FS_Gamedir()]);
  f := FileOpen(name, fmOpenRead);
  if (f = -1) then
  begin
    Com_Printf('Couldn''t read %s'#10, [name]);
    exit;
  end;
  // read the comment field
  FS_Read(@comment, sizeof(comment), f);

  // read the mapcmd
  FS_Read(@mapcmd, sizeof(mapcmd), f);

  // read all CVAR_LATCH cvars
  // these will be things like coop, skill, deathmatch, etc
  while (true) do
  begin
    if (FileRead(f, name, sizeof(name)) = 0) then
      break;
    FS_Read(@string_, sizeof(string_), f);
    Com_DPrintf('Set %s := %s'#10, [name, string_]);
    Cvar_ForceSet(name, string_);
  end;

  FileClose(f);

  // start a new game fresh with new cvars
  SV_InitGame();

  strcpy(@svs.mapcmd, mapcmd);

  // read game state
  Com_sprintf(name, sizeof(name), '%s/save/current/game.ssv', [FS_Gamedir()]);
  ge.ReadGame(name);
end;

(*
==================================================
SV_DemoMap_f

Puts the server in demo mode on a specific map/cinematic
==================================================
*)

procedure SV_DemoMap_f(); cdecl;
begin
  SV_Map(true, Cmd_Argv(1), false);
end;

(*
==================================================
SV_GameMap_f

Saves the state of the map just being exited and goes to a new map.

If the initial character of the map string is '*', the next map is
in a new unit, so the current savegame directory is cleared of
map files.

Example:

*inter.cin+jail

Clears the archived maps, plays the inter.cin cinematic, then
goes to map jail.bsp.
==================================================
*)

procedure SV_GameMap_f(); cdecl;
type
  TQBoolArr = array[0..0] of qboolean;
  PQBoolArr = ^TQBoolArr;
var
  map: PChar;
  i: integer;
  cl: client_p;
  savedInuse: PQBoolArr;
begin
  if (Cmd_Argc() <> 2) then
  begin
    Com_Printf('USAGE: gamemap <map>'#10, []);
    exit;
  end;

  Com_DPrintf('SV_GameMap(%s)'#10, [Cmd_Argv(1)]);

  FS_CreatePath(va('%s/save/current/', [FS_Gamedir()]));

  // check for clearing the current savegame
  map := Cmd_Argv(1);
  if (map[0] = '*') then
  begin
    // wipe all the *.sav files
    SV_WipeSavegame('current');
  end
  else
  begin                                 // save the map just exited
    if (sv.state = ss_game) then
    begin
      // clear all the client inuse flags before saving so that
      // when the level is re-entered, the clients will spawn
      // at spawn points instead of occupying body shells
      savedInuse := malloc(Round(maxclients.value) * sizeof(qboolean));
      cl := client_p(svs.clients);
      i := 0;
      while (i < maxclients.value) do
      begin
        savedInuse^[i] := cl^.edict^.inuse;
        cl^.edict^.inuse := false;
        Inc(i);
        Inc(cl);
      end;

      SV_WriteLevelFile();

      // we must restore these for clients to transfer over correctly
      cl := client_p(svs.clients);
      i := 0;
      while (i < maxclients.value) do
      begin
        cl^.edict^.inuse := savedInuse^[i];
        inc(i);
        inc(cl);
      end;
      free(savedInuse);
    end;
  end;

  // start up the next map
  SV_Map(false, Cmd_Argv(1), false);

  // archive server state
  strncpy(@svs.mapcmd, Cmd_Argv(1), sizeof(svs.mapcmd) - 1);

  // copy off the level to the autosave slot
  if not (dedicated.value <> 0) then
  begin
    SV_WriteServerFile(true);
    SV_CopySaveGame('current', 'save0');
  end;
end;

(*
==================================================
SV_Map_f

Goes directly to a given map without any savegame archiving.
For development work
==================================================
*)

procedure SV_Map_f(); cdecl;
var
  map: pchar;
  expanded: array[0..MAX_QPATH - 1] of char;
begin
  // if not a pcx, demo, or cinematic, check to make sure the level exists
  map := Cmd_Argv(1);
  if (not (strstr(map, '.') <> nil)) then
  begin
    Com_sprintf(expanded, sizeof(expanded), 'maps/%s.bsp', [map]);
    if FS_LoadFile(expanded, nil) = -1 then
    begin
      Com_Printf('Can''t find %s'#10, [expanded]);
      exit;
    end;
  end;

  sv.state := ss_dead;                  // don't save current level when changing
  SV_WipeSavegame('current');
  SV_GameMap_f();
end;

(*
==================================================

  SAVEGAMES

==================================================
*)

(*
==================================================
SV_Loadgame_f

==================================================
*)

procedure SV_Loadgame_f(); cdecl;
var
  name: array[0..MAX_OSPATH - 1] of Char;
  f: Integer;
  dir: PChar;
begin
  if (Cmd_Argc() <> 2) then
  begin
    Com_Printf('USAGE: loadgame <directory>'#10, []);
    exit;
  end;

  Com_Printf('Loading game...'#10, []);

  dir := Cmd_Argv(1);
  if (strstr(dir, '..') <> nil) or (strstr(dir, '/') <> nil) or (strstr(dir, '\') <> nil) then
  begin
    Com_Printf('Bad savedir.'#10, []);
  end;

  // make sure the server.ssv file exists
  Com_sprintf(name, sizeof(name), '%s/save/%s/server.ssv', [FS_Gamedir(), Cmd_Argv(1)]);
  f := FileOpen(name, fmOpenRead);
  if (f = -1) then
  begin
    Com_Printf('No such savegame: %s'#10, [name]);
    exit;
  end;
  FileClose(f);

  SV_CopySaveGame(Cmd_Argv(1), 'current');

  SV_ReadServerFile();

  // go to the map
  sv.state := ss_dead;                  // don't save current level when changing
  SV_Map(false, @svs.mapcmd, true);
end;

(*
==================================================
SV_Savegame_f

==================================================
*)

procedure SV_Savegame_f(); cdecl;
var
  dir: pchar;
begin
  if (sv.state <> ss_game) then
  begin
    Com_Printf('You must be in a game to save.'#10, []);
    exit;
  end;

  if (Cmd_Argc() <> 2) then
  begin
    Com_Printf('USAGE: savegame <directory>'#10, []);
    exit;
  end;

  if (Cvar_VariableValue('deathmatch') <> 0) then
  begin
    Com_Printf('Can''t savegame in a deathmatch'#10, []);
    exit;
  end;

  if not (strcmp(Cmd_Argv(1), 'current') <> 0) then
  begin
    Com_Printf('Can''t save to ''current'''#10, []);
    exit;
  end;

  if (maxclients.value = 1) and (svs.clients^[0].edict^.client^.ps.stats[STAT_HEALTH] <= 0) then
  begin
    Com_Printf(#10'Can''t savegame while dead!'#10, []);
    exit;
  end;

  dir := Cmd_Argv(1);
  if (strstr(dir, '..') <> nil) or (strstr(dir, '/') <> nil) or (strstr(dir, '\') <> nil) then
  begin
    Com_Printf('Bad savedir.'#10, []);
  end;

  Com_Printf('Saving game...'#10, []);

  // archive current level, including all client edicts.
  // when the level is reloaded, they will be shells awaiting
  // a connecting client
  SV_WriteLevelFile();

  // save server state
  SV_WriteServerFile(false);

  // copy it off
  SV_CopySaveGame('current', dir);

  Com_Printf('Done.'#10, []);
end;

(*
==================================================
SV_Kick_f

Kick a user off of the server
==================================================
*)

procedure SV_Kick_f(); cdecl;
begin
  if (not svs.initialized) then
  begin
    Com_Printf('No server running.'#10, []);
    exit;
  end;

  if (Cmd_Argc() <> 2) then
  begin
    Com_Printf('Usage: kick <userid>'#10, []);
    exit;
  end;

  if (not SV_SetPlayer()) then
    exit;

  SV_BroadcastPrintf(PRINT_HIGH, '%s was kicked'#10, [sv_client^.name]);
  // print directly, because the dropped client won't get the
  // SV_BroadcastPrintf message
  SV_ClientPrintf(sv_client, PRINT_HIGH, 'You were kicked from the game'#10, []);
  SV_DropClient(sv_client);
  sv_client^.lastmessage := svs.realtime; // min case there is a funny zombie
end;

(*
==================================================
SV_Status_f
==================================================
*)

procedure SV_Status_f; cdecl;
var
  i, j, l: integer;
  cl: client_p;
  s: pchar;
  ping: integer;
label
  continue_;
begin
  if (svs.clients = nil) then
  begin
    Com_Printf('No server running.'#10, []);
    exit;
  end;
  Com_Printf('map              : %s'#10, [sv.name]);

  Com_Printf('num score ping name            lastmsg address               qport '#10, []);
  Com_Printf('--- ----- ---- --------------- ------- --------------------- ------'#10, []);
  i := 0;
  cl := client_p(svs.clients);
  while (i < maxclients.value) do
  begin
    if (Integer(cl.state) = 0) then
      goto continue_;
    Com_Printf('%3i ', [i]);
    Com_Printf('%5i ', [cl^.edict^.client^.ps.stats[STAT_FRAGS]]);

    if (cl^.state = cs_connected) then
      Com_Printf('CNCT ', [])
    else if (cl^.state = cs_zombie) then
      Com_Printf('ZMBI ', [])
    else
    begin
      if cl^.ping < 9999 then
        ping := cl^.ping
      else
        ping := 9999;
      Com_Printf('%4i ', [ping]);
    end;

    Com_Printf('%s', [cl^.name]);
    l := 16 - strlen(cl.name);
    for j := 0 to l - 1 do
      Com_Printf(' ');

    Com_Printf('%7i ', [svs.realtime - cl.lastmessage]);

    s := NET_AdrToString(cl.netchan.remote_address);
    Com_Printf('%s', [s]);
    l := 22 - strlen(s);
    for j := 0 to l - 1 do
      Com_Printf(' ');

    Com_Printf('%5i', [cl.netchan.qport]);

    Com_Printf(#10);
    continue_:
    Inc(i);
    Inc(cl);
  end;
  Com_Printf(#10);
end;

(*
==================================================
SV_ConSay_f
==================================================
*)

procedure SV_ConSay_f; cdecl;
var
  client: client_p;
  j: integer;
  p: pchar;
  text: array[0..1024 - 1] of char;
label
  continue_;
begin
  if (Cmd_Argc() < 2) then
    exit;

  strcpy(text, 'console: ');
  p := Cmd_Args();

  if (p^ = '"') then
  begin
    Inc(p);
    p[strlen(p) - 1] := #0;
  end;

  strcat(text, p);

  j := 0;
  client := client_p(svs.clients);
  while (j < maxclients.value) do
  begin
    if (client^.state <> cs_spawned) then
      goto continue_;
    SV_ClientPrintf(client, PRINT_CHAT, '%s'#10, [text]);
    continue_:
    Inc(j);
    Inc(client);
  end;
end;

(*
==================================================
SV_Heartbeat_f
==================================================
*)

procedure SV_Heartbeat_f; cdecl;
begin
  svs.last_heartbeat := -9999999;
end;

(*
==================================================
SV_Serverinfo_f

  Examine or change the serverinfo string
==================================================
*)

procedure SV_Serverinfo_f; cdecl;
begin
  Com_Printf('Server info settings:'#10);
  Info_Print(Cvar_Serverinfo_());
end;

(*
==================================================
SV_DumpUser_f

Examine all a users info strings
==================================================
*)

procedure SV_DumpUser_f; cdecl;
begin
  if (Cmd_Argc() <> 2) then
  begin
    Com_Printf('Usage: info <userid>'#10);
    exit;
  end;

  if (not SV_SetPlayer()) then
    exit;

  Com_Printf('userinfo'#10);
  Com_Printf('--------'#10);
  Info_Print(sv_client.userinfo);

end;

(*
==================================================
SV_ServerRecord_f

Begins server demo recording.  Every entity and every message will be
recorded, but no playerinfo will be stored.  Primarily for demo merging.
==================================================
*)

procedure SV_ServerRecord_f; cdecl;
var
  name: array[0..MAX_OSPATH - 1] of char;
  buf_data: array[0..32768 - 1] of char;
  buf: sizebuf_t;
  len: integer;
  i: integer;
begin
  if (Cmd_Argc() <> 2) then
  begin
    Com_Printf('serverrecord <demoname>'#10);
    exit;
  end;

  if (svs.demofile > 0) then
  begin
    Com_Printf('Already recording.'#10);
    exit;
  end;

  if (sv.state <> ss_game) then
  begin
    Com_Printf('You must be in a level to record.'#10);
    exit;
  end;

  //
  // open the demo file
  //
  Com_sprintf(name, sizeof(name), '%s/demos/%s.dm2', [FS_Gamedir(), Cmd_Argv(1)]);

  Com_Printf('recording to %s.'#10, [name]);
  FS_CreatePath(name);
  svs.demofile := FileOpen(name, fmOpenReadWrite);
  if (svs.demofile = -1) then
  begin
    Com_Printf('ERROR: couldn''t open.'#10);
    exit;
  end;

  // setup a buffer to catch all multicasts
  SZ_Init(svs.demo_multicast, @svs.demo_multicast_buf, sizeof(svs.demo_multicast_buf));

  //
  // write a single giant fake message with all the startup info
  //
  SZ_Init(buf, @buf_data, sizeof(buf_data));

  //
  // serverdata needs to go over for all types of servers
  // to make sure the protocol is right, and to set the gamedir
  //
  // send the serverdata
  MSG_WriteByte(buf, Integer(svc_serverdata));
  MSG_WriteLong(buf, PROTOCOL_VERSION);
  MSG_WriteLong(buf, svs.spawncount);
  // 2 means server demo
  MSG_WriteByte(buf, 2);                // demos are always attract loops
  MSG_WriteString(buf, Cvar_VariableString('gamedir'));
  MSG_WriteShort(buf, -1);
  // send full levelname
  MSG_WriteString(buf, sv.configstrings[CS_NAME]);

  for i := 0 to MAX_CONFIGSTRINGS - 1 do
  begin
    if (sv.configstrings[i, 0] <> #0) then
    begin
      MSG_WriteByte(buf, Integer(svc_configstring));
      MSG_WriteShort(buf, i);
      MSG_WriteString(buf, sv.configstrings[i]);
    end;
  end;
  // write it to the demo file
  Com_DPrintf('signon message length: %i'#10, [buf.cursize]);
  len := LittleLong(buf.cursize);
  FileWrite(svs.demofile, len, 4);
  FileWrite(svs.demofile, buf.data^, buf.cursize);

  // the rest of the demo file will be individual frames
end;

(*
==================================================
SV_ServerStop_f

Ends server demo recording
==================================================
*)

procedure SV_ServerStop_f; cdecl;
begin
  if (svs.demofile <= 0) then
  begin
    Com_Printf('Not doing a serverrecord.'#10);
    exit;
  end;
  FileClose(svs.demofile);
  svs.demofile := 0;
  Com_Printf('Recording completed.'#10);
end;

(*
==================================================
SV_KillServer_f

Kick everyone off, possibly in preparation for a new game

==================================================*)

procedure SV_KillServer_f; cdecl;
begin
  if (not svs.initialized) then
    exit;
  SV_Shutdown('Server was killed.'#10, false);
  NET_Config(false);                    // close network sockets
end;

(*
==================================================
SV_ServerCommand_f

Let the game dll handle a command
==================================================
*)

procedure SV_ServerCommand_f(); cdecl;
begin
  if (ge = nil) then
  begin
    Com_Printf('No game loaded.'#10);
    exit;
  end;
  ge.ServerCommand();
end;

(*
==================================================
SV_InitOperatorCommands
==================================================
*)

procedure SV_InitOperatorCommands();
begin
  Cmd_AddCommand('heartbeat', SV_Heartbeat_f);
  Cmd_AddCommand('kick', SV_Kick_f);
  Cmd_AddCommand('status', SV_Status_f);
  Cmd_AddCommand('serverinfo', SV_Serverinfo_f);
  Cmd_AddCommand('dumpuser', SV_DumpUser_f);

  Cmd_AddCommand('map', SV_Map_f);
  Cmd_AddCommand('demomap', SV_DemoMap_f);
  Cmd_AddCommand('gamemap', SV_GameMap_f);
  Cmd_AddCommand('setmaster', SV_SetMaster_f);

  if (dedicated.value <> 0) then
    Cmd_AddCommand('say', SV_ConSay_f);

  Cmd_AddCommand('serverrecord', SV_ServerRecord_f);
  Cmd_AddCommand('serverstop', SV_ServerStop_f);

  Cmd_AddCommand('save', SV_Savegame_f);
  Cmd_AddCommand('load', SV_Loadgame_f);

  Cmd_AddCommand('killserver', SV_KillServer_f);

  Cmd_AddCommand('sv', SV_ServerCommand_f);
end;

end.
