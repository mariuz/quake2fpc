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
{ File(s): sv_init.c                                                         }
{                                                                            }
{ Initial conversion by : dhouse (david@dahsoftware.com)                     }
{ Initial conversion on : 013-Jan-2002                                       }
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
{ Updated on :                                                               }
{ Updated by :                                                               }
{                                                                            }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{----------------------------------------------------------------------------}
// 25.07.2002 Juha: Proof-readed this unit
unit sv_init;

interface

uses
  q_shared,
  q_shared_add,
  GameUnit,
  server;

procedure SV_InitGame; cdecl;
procedure SV_Map(attractloop: qboolean; levelstring: PChar; loadgame: qboolean); cdecl;
function SV_ModelIndex(name: PChar): Integer; cdecl;
function SV_SoundIndex(name: PChar): Integer; cdecl;
function SV_ImageIndex(name: PChar): Integer; cdecl;

var
  svs: server_static_t;                 // persistant server info
  sv: server_t;                         // local server

implementation

uses
  SysUtils,
  Common,
  Cpas,
  CVar,
  CModel,
  PMoveUnit,
  Files,
  Cmd,
  cl_main,
  cl_scrn,
  {$IFDEF WIN32}
  net_wins,
  {$ELSE}
  net_udp,
  {$ENDIF}
  sv_ccmds,
  sv_game,
  sv_world,
  sv_main,
  sv_send;

{
================
SV_FindIndex
================
}

function SV_FindIndex(name: PChar; start, max: Integer; create: qboolean): Integer;
var
  i: Integer;
begin
  if (name = nil) or (name[0] = #0) then
  begin
    Result := 0;
    Exit;
  end;                                  { if }

  i := 1;
  while (i < max) and (sv.configstrings[start + i][0] <> #0) do
  begin
    if strcmp(sv.configstrings[start + i], name) = 0 then
    begin
      Result := i;
      Exit;
    end;                                { if }
    Inc(i);
  end;                                  { for }

  if (not create) then
  begin
    Result := 0;
    Exit;
  end;                                  { if }

  if (i = max) then
    Com_Error(ERR_DROP, '*Index: overflow');

  strncpy(sv.configstrings[start + i], name, sizeof(sv.configstrings[i]));

  if (sv.state <> ss_loading) then
  begin
    // Send the update to everyone
    SZ_Clear(sv.multicast);
    MSG_WriteChar(sv.multicast, Integer(svc_configstring));
    MSG_WriteShort(sv.multicast, start + i);
    MSG_WriteString(sv.multicast, name);
    SV_Multicast(@vec3_origin, MULTICAST_ALL_R);
  end;                                  { if }
  Result := i;
end;

function SV_ModelIndex(name: pchar): Integer;
begin
  Result := SV_FindIndex(name, CS_MODELS, MAX_MODELS, True);
end;

function SV_SoundIndex(name: pchar): Integer;
begin
  Result := SV_FindIndex(name, CS_SOUNDS, MAX_SOUNDS, True);
end;

function SV_ImageIndex(name: pchar): Integer;
begin
  Result := SV_FindIndex(name, CS_IMAGES, MAX_IMAGES, True);
end;

{
================
SV_CreateBaseline

Entity baselines are used to compress the update messages
to the clients -- only the fields that differ from the
baseline will be transmitted
================
}

procedure SV_CreateBaseline;
var
  svent: edict_p;
  entnum: Integer;
begin
  for entnum := 1 to (ge.num_edicts - 1) do
  begin
    svent := EDICT_NUM(entnum);
    if (not svent^.inuse) then
      Continue;
    if ((not svent^.s.modelindex <> 0) and (not svent^.s.sound <> 0) and (not svent^.s.effects <> 0)) then
      Continue;
    svent^.s.number := entnum;

    //
    // take current state as baseline
    //
    VectorCopy(svent^.s.origin, svent^.s.old_origin);
    sv.baselines[entnum] := svent^.s;
  end;                                  { for }
end;

{
=================
SV_CheckForSavegame
=================
}

procedure SV_CheckForSavegame;
var
  name: array[0..MAX_OSPATH - 1] of Char;
  f: integer;
  i: Integer;
  previousState: server_state_t;
begin
  if (sv_noreload^.value <> 0) then
    Exit;

  if (Cvar_VariableValue('deathmatch') <> 0) then
    Exit;

  Com_sprintf(name, sizeof(name), '%s/save/current/%s.sav', [FS_Gamedir(), sv.name]);
  f := FileOpen(name, fmOpenRead);
  if f = -1 then
    Exit;                               // no savegame

  FileClose(f);

  SV_ClearWorld;

  // get configstrings and areaportals
  SV_ReadLevelFile;

  if (not sv.loadgame) then
  begin
    // coming back to a level after being in a different
    // level, so run it for ten seconds

    // rlava2 was sending too many lightstyles, and overflowing the
    // reliable data. temporarily changing the server state to loading
    // prevents these from being passed down.
    previousState := sv.state;
    sv.state := ss_loading;
    for i := 0 to 100 - 1 do
      ge^.RunFrame;

    sv.state := previousState;
  end;                                  { if }
end;

{
================
SV_SpawnServer

Change the server to a new map, taking all connected
clients along with it.

================
}

procedure SV_SpawnServer(server, spawnpoint: PChar; serverstate: server_state_t; attractloop, loadgame: qboolean);
var
  i: Integer;
  checksum: Cardinal;
begin
  if (attractloop) then
    Cvar_Set('paused', '0');

  Com_Printf('------- Server Initialization -------'#10);

  Com_DPrintf('SpawnServer: %s'#10, [server]);
  if (sv.demofile > 0) then
  begin
    FileClose(sv.demofile);
    sv.demofile := 0;
  end;

  Inc(svs.spawncount);                  // any partially connected client will be restarted

  sv.state := ss_dead;
  Com_SetServerState(Integer(sv.state));

  // wipe the entire per-level structure
  FillChar(sv, sizeof(sv), 0);
  svs.realtime := 0;
  sv.loadgame := loadgame;
  sv.attractloop := attractloop;

  // save name for levels that don't set message
  strcpy(sv.configstrings[CS_NAME], server);
  if (Cvar_VariableValue('deathmatch') <> 0) then
  begin
    Com_sprintf(sv.configstrings[CS_AIRACCEL], MAX_QPATH, '%g', [sv_airaccelerate^.value]);
    pm_airaccelerate := sv_airaccelerate^.value;
  end
  else
  begin
    strcpy(sv.configstrings[CS_AIRACCEL], '0');
    pm_airaccelerate := 0;
  end;                                  { if }

  SZ_Init(sv.multicast, @sv.multicast_buf, sizeof(sv.multicast_buf));

  strcpy(sv.name, server);

  // leave slots at start for clients only
  for i := 0 to Trunc(maxclients.value - 1) do
  begin
    // needs to reconnect
    if (svs.clients^[i].state > cs_connected) then
      svs.clients^[i].state := cs_connected;
    svs.clients^[i].lastframe := -1;
  end;                                  { for }

  sv.time := 1000;

  strcpy(sv.name, server);
  strcpy(sv.configstrings[CS_NAME], server);

  if (serverstate <> ss_game) then
    sv.models[1] := CM_LoadMap('', False, checksum) // no real map
  else
  begin
    Com_sprintf(sv.configstrings[CS_MODELS + 1], sizeof(sv.configstrings[CS_MODELS + 1]),
      'maps/%s.bsp', [server]);
    sv.models[1] := CM_LoadMap(sv.configstrings[CS_MODELS + 1], False, checksum);
  end;                                  { if }
  Com_sprintf(sv.configstrings[CS_MAPCHECKSUM], sizeof(sv.configstrings[CS_MAPCHECKSUM]),
    '%i', [checksum]);

  //
  // clear physics interaction links
  //
  SV_ClearWorld();

  for i := 1 to CM_NumInLineModels() - 1 do
  begin
    Com_sprintf(sv.configstrings[CS_MODELS + 1 + i], sizeof(sv.configstrings[CS_MODELS + 1 + i]),
      '*%i', [i]);
    sv.models[i + 1] := CM_InlineModel(sv.configstrings[CS_MODELS + 1 + i]);
  end;                                  { for }

  //
  // spawn the rest of the entities on the map
  //

  // precache and static commands can be issued during
  // map initialization
  sv.state := ss_loading;
  Com_SetServerState(Integer(sv.state));

  // load and spawn all other entities
  ge^.SpawnEntities(sv.name, CM_EntityString, spawnpoint);

  // run two frames to allow everything to settle
  ge^.RunFrame;
  ge^.RunFrame;

  // all precaches are complete
  sv.state := serverstate;
  Com_SetServerState(Integer(sv.state));

  // create a baseline for more efficient communications
  SV_CreateBaseline;

  // check for a savegame
  SV_CheckForSavegame;

  // set serverinfo variable
  Cvar_FullSet('mapname', sv.name, CVAR_SERVERINFO or CVAR_NOSET);

  Com_Printf('-------------------------------------'#10);
end;

{
==============
SV_InitGame

A brand new game has been started
==============
}

procedure SV_InitGame;
var
  i: Integer;
  ent: edict_p;
  idmaster: array[0..32 - 1] of Char;
begin
  if (svs.initialized) then
  begin
    // Cause any connected clients to reconnect
    SV_Shutdown('Server restarted'#10, True);
  end
  else
  begin
    // Make sure the client is down
    CL_Drop;
    SCR_BeginLoadingPlaque;
  end;                                  { if }

  // get any latched variable changes (maxclients, etc)
  Cvar_GetLatchedVars;

  svs.initialized := True;

  if (Cvar_VariableValue('coop') <> 0) and (Cvar_VariableValue('deathmatch') <> 0) then
  begin
    Com_Printf('Deathmatch and Coop both set, disabling Coop'#10);
    Cvar_FullSet('coop', '0', CVAR_SERVERINFO or CVAR_LATCH);
  end;                                  { if }

  // dedicated servers are can't be single player and are usually DM
  // so unless they explicity set coop, force it to deathmatch
  if (dedicated.value <> 0) then
  begin
    if not (Cvar_VariableValue('coop') <> 0) then
      Cvar_FullSet('deathmatch', '1', CVAR_SERVERINFO or CVAR_LATCH);
  end;                                  { if }

  // init clients
  if (Cvar_VariableValue('deathmatch') <> 0) then
  begin
    if (maxclients.value <= 1) then
      Cvar_FullSet('maxclients', '8', CVAR_SERVERINFO or CVAR_LATCH)
    else if (maxclients.value > MAX_CLIENTS) then
      Cvar_FullSet('maxclients', va('%i', [MAX_CLIENTS]), CVAR_SERVERINFO or CVAR_LATCH);
  end
  else if (Cvar_VariableValue('coop') <> 0) then
  begin
    if ((maxclients.value <= 1) or (maxclients.value > 4)) then
      Cvar_FullSet('maxclients', '4', CVAR_SERVERINFO or CVAR_LATCH);

{$IFDEF COPYPROTECT}
    if ((not sv.attractloop) and (not dedicated.value <> 0)) then
      Sys_CopyProtect;
{$ENDIF}

  end
  else
  begin                                 // non-deathmatch, non-coop is one player
    Cvar_FullSet('maxclients', '1', CVAR_SERVERINFO or CVAR_LATCH);
{$IFDEF COPYPROTECT}
    if (not sv.attractloop) then
      Sys_CopyProtect;
{$ENDIF}
  end;                                  { if }

  svs.spawncount := rand();
  svs.clients := Z_Malloc(sizeof(client_t) * Round(maxclients.value));
  svs.num_client_entities := Round(maxclients.value) * UPDATE_BACKUP * 64;
  svs.client_entities := Z_Malloc(sizeof(entity_state_t) * svs.num_client_entities);

  // init network stuff
  NET_Config((maxclients.value > 1));

  // heartbeats will always be sent to the id master
  svs.last_heartbeat := -99999;
  Com_sprintf(idmaster, sizeof(idmaster), '192.246.40.37:%d', [PORT_MASTER]);
  {$IFDEF WIN32}
  NET_StringToAdr(idmaster, master_adr[0]);
  {$ELSE}
  NET_StringToAdr(idmaster, @master_adr[0]);
  {$ENDIF}
  // Init game
  SV_InitGameProgs;
  for i := 0 to Trunc(maxclients.value) - 1 do
  begin
    ent := EDICT_NUM(i + 1);
    ent^.s.number := i + 1;
    svs.clients^[i].edict := ent;
    FillChar(svs.clients^[i].lastcmd, sizeof(svs.clients^[i].lastcmd), 0);
  end;                                  { for }
end;

{
======================
SV_Map

  the full syntax is:

  map [*]<map>$<startspot>+<nextserver>

command from the console or progs.
Map can also be a.cin, .pcx, or .dm2 file
Nextserver is used to allow a cinematic to play, then proceed to
another level:

 map tram.cin+jail_e3
======================
}

procedure SV_Map(attractloop: qboolean; levelstring: PChar; loadgame: qboolean);
var
  level: array[0..MAX_QPATH - 1] of Char;
  ch: PChar;
  l: Integer;
  spawnpoint: array[0..MAX_QPATH - 1] of Char;
begin
  sv.loadgame := loadgame;
  sv.attractloop := attractloop;

  if ((sv.state = ss_dead) and (not sv.loadgame)) then
    SV_InitGame;                        // the game is just starting

  strcpy(level, levelstring);

  // if there is a + in the map, set nextserver to the remainder
  ch := strstr(level, '+');
  if (ch <> nil) then
  begin
    ch^ := #0;
    Cvar_Set('nextserver', va('gamemap "%s"', [ch + 1]))
  end
  else
    Cvar_Set('nextserver', '');

  // ZOID special hack for end game screen in coop mode
  if (Cvar_VariableValue('coop') <> 0) and (not Q_stricmp(level, 'victory.pcx') <> 0) then
    Cvar_Set('nextserver', 'gamemap "*base1"');

  // if there is a $, use the remainder as a spawnpoint
  ch := strstr(level, '$');
  if (ch <> nil) then
  begin
    ch^ := #0;
    strcpy(spawnpoint, ch + 1)
  end
  else
    spawnpoint[0] := #0;

  // skip the end-of-unit flag if necessary
  if (level[0] = '*') then
    strcpy(level, level + 1);

  l := strlen(level);
  if (l > 4) and (strcmp(level + l - 4, '.cin') = 0) then
  begin
    SCR_BeginLoadingPlaque;             // for local system
    SV_BroadcastCommand('changing'#10, []);
    SV_SpawnServer(level, spawnpoint, ss_cinematic, attractloop, loadgame);
  end
  else if (l > 4) and (strcmp(level + l - 4, '.dm2') = 0) then
  begin
    SCR_BeginLoadingPlaque;             // for local system
    SV_BroadcastCommand('changing'#10, []);
    SV_SpawnServer(level, spawnpoint, ss_demo, attractloop, loadgame);
  end
  else if (l > 4) and (strcmp(level + l - 4, '.pcx') = 0) then
  begin
    SCR_BeginLoadingPlaque;             // for local system
    SV_BroadcastCommand('changing'#10, []);
    SV_SpawnServer(level, spawnpoint, ss_pic, attractloop, loadgame);
  end
  else
  begin
    SCR_BeginLoadingPlaque;             // for local system
    SV_BroadcastCommand('changing'#10, []);
    SV_SendClientMessages;
    SV_SpawnServer(level, spawnpoint, ss_game, attractloop, loadgame);
    Cbuf_CopyToDefer;
  end;                                  { if }

  SV_BroadcastCommand('reconnect'#10, []);
end;

end.
d.
