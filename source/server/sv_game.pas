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
{ File(s): sv_game.c -- interface to the game dll                            }
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
{ Updated on :                                                               }
{ Updated by :                                                               }
{                                                                            }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{ 1) server.pas                                                              }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{ 1) check for the constant argument array parameter                         }
{----------------------------------------------------------------------------}
// 25.07.2002 Juha: Proof-readed this unit

unit sv_game;

interface

uses
  GameUnit,
  server;

procedure SV_InitGameProgs;
procedure SV_ShutdownGameProgs;

// Juha: Exported for Delphi_cdecl_printf.pas
procedure PF_centerprintf(ent: edict_p; fmt: PChar; args: array of const);
procedure PF_cprintf(ent: edict_p; level: integer; fmt: PChar; args: array of const);
procedure PF_dprintf(fmt: PChar; args: array of const);

var
  ge: game_export_p;

implementation

uses
  Delphi_cdecl_printf,
  SysUtils,
  Common,
  CModel,
  PMoveUnit,
  CPas,
  CVar,
  Cmd,
  sv_init,
  sv_send,
  sv_world,
  {$IFDEF WIN32}
  sys_win,
  {$ELSE}
  sys_linux,
  {$ENDIF}
  cl_scrn,
  q_shared,
  q_shared_add,
  sv_main;

(*
===============
PF_Unicast

Sends the contents of the mutlicast buffer to a single client
===============
*)

procedure PF_Unicast(ent: edict_p; reliable: qboolean); cdecl;
var
  p: integer;
  client: client_p;
begin
  if (ent = nil) then
    exit;

  p := NUM_FOR_EDICT(ent);
  if (p < 1) or (p > maxclients.value) then
    exit;

  client := client_p(svs.clients);
  Inc(client, p - 1);

  if (reliable) then
    SZ_Write(client.netchan.message, sv.multicast.data, sv.multicast.cursize)
  else
    SZ_Write(client.datagram, sv.multicast.data, sv.multicast.cursize);

  SZ_Clear(sv.multicast);
end;

(*
===============
PF_dprintf

Debug print to server console
===============
*)

procedure PF_dprintf(fmt: PChar; args: array of const);
var
  msg: array[0..1023] of char;
begin
  DelphiStrFmt(msg, fmt, args);
  Com_Printf('%s', [msg]);
end;

(*
===============
PF_cprintf

Print to a single client
===============
*)

procedure PF_cprintf(ent: edict_p; level: integer; fmt: PChar; args: array of const);
var
  msg: array[0..1024 - 1] of char;
  client: client_p;
  n: integer;
begin
  if (ent <> nil) then
  begin
    n := NUM_FOR_EDICT(ent);
    if (n < 1) or (n > maxclients.value) then
      Com_Error(ERR_DROP, 'cprintf to a non-client');
  end;

  DelphiStrFmt(msg, fmt, args);
  if (ent <> nil) then
  begin
    client := client_p(svs.clients);
    inc(client, n - 1);
    SV_ClientPrintf(client, level, '%s', [msg])
  end
  else
    Com_Printf('%s', [msg]);
end;

(*
===============
PF_centerprintf

centerprint to a single client
===============
*)

procedure PF_centerprintf(ent: edict_p; fmt: PChar; args: array of const);
var
  msg: array[0..1024 - 1] of char;
  n: integer;
begin
  n := NUM_FOR_EDICT(ent);
  if (n < 1) or (n > maxclients.value) then
    exit;                               // Com_Error (ERR_DROP, "centerprintf to a non-client");

  DelphiStrFmt(msg, fmt, args);

  MSG_WriteByte(sv.multicast, Integer(svc_centerprint));
  MSG_WriteString(sv.multicast, msg);
  PF_Unicast(ent, true);
end;

(*
===============
PF_error

Abort the server with a game error
===============
*)

procedure PF_error(fmt: PChar); cdecl;
var
  msg: array[0..1024 - 1] of char;
begin
  strcpy(@msg, fmt);
  //DelphiStrFmt(msg, fmt, args);
  Com_Error(ERR_DROP, 'Game Error: %s', [msg]);
end;

(*
=================
PF_setmodel

Also sets mins and maxs for inline bmodels
=================
*)

procedure PF_setmodel(ent: edict_p; name: PChar); cdecl;
var
  i: integer;
  mod_: cmodel_p;
begin
  if (name = nil) then
    Com_Error(ERR_DROP, 'PF_setmodel: nil');

  i := SV_ModelIndex(name);

  //   ent->model = name;
  ent^.s.modelindex := i;

  // if it is an inline model, get the size information for it
  if (name[0] = '*') then
  begin
    mod_ := CM_InlineModel(name);
    VectorCopy(mod_.mins, ent.mins);
    VectorCopy(mod_.maxs, ent.maxs);
    SV_LinkEdict(ent);
  end;
end;

(*
===============
PF_Configstring

===============
*)

procedure PF_Configstring(index: integer; val: PChar); cdecl;
begin
  if (index < 0) or (index >= MAX_CONFIGSTRINGS) then
    Com_Error(ERR_DROP, 'configstring: bad index %i'#10, [index]);

  if (val = nil) then
    val := '';

  // change the string in sv
  strcpy(sv.configstrings[index], val);

  if (sv.state <> ss_loading) then
  begin
    // send the update to everyone
    SZ_Clear(sv.multicast);
    MSG_WriteChar(sv.multicast, Integer(svc_configstring));
    MSG_WriteShort(sv.multicast, index);
    MSG_WriteString(sv.multicast, val);

    SV_Multicast(@vec3_origin, MULTICAST_ALL_R);
  end;
end;

procedure PF_WriteChar(c: integer); cdecl;
begin
  MSG_WriteChar(sv.multicast, c);
end;

procedure PF_WriteByte(c: integer); cdecl;
begin
  MSG_WriteByte(sv.multicast, c);
end;

procedure PF_WriteShort(c: integer); cdecl;
begin
  MSG_WriteShort(sv.multicast, c);
end;

procedure PF_WriteLong(c: integer); cdecl;
begin
  MSG_WriteLong(sv.multicast, c);
end;

procedure PF_WriteFloat(f: Single); cdecl;
begin
  MSG_WriteFloat(sv.multicast, f);
end;

procedure PF_WriteString(s: PChar); cdecl;
begin
  MSG_WriteString(sv.multicast, s);
end;

procedure PF_WritePos(const pos: vec3_t); cdecl;
begin
  MSG_WritePos(sv.multicast, pos);
end;

procedure PF_WriteDir(const dir: vec3_t); cdecl;
begin
  MSG_WriteDir(sv.multicast, @dir);
end;

procedure PF_WriteAngle(f: Single); cdecl;
begin
  MSG_WriteAngle(sv.multicast, f);
end;

(*
=================
PF_inPVS

Also checks portalareas so that doors block sight
=================
*)

function PF_inPVS(var p1, p2: vec3_t): qboolean; cdecl;
var
  leafnum: Integer;
  cluster: Integer;
  area1,
    area2: Integer;
  mask: PByteArray;
begin
  leafnum := CM_PointLeafnum(p1);
  cluster := CM_LeafCluster(leafnum);
  area1 := CM_LeafArea(leafnum);
  mask := PByteArray(CM_ClusterPVS(cluster));

  leafnum := CM_PointLeafnum(p2);
  cluster := CM_LeafCluster(leafnum);
  area2 := CM_LeafArea(leafnum);
  if (mask <> nil) and (not ((mask[cluster shr 3] <> 0) and (1 shl (cluster and 7) <> 0))) then
  begin
    Result := False;
    exit;
  end;
  if (not CM_AreasConnected(area1, area2)) then
  begin
    Result := False;
    exit;                               // a door blocks sight
  end;
  Result := True;
end;

(*
=================
PF_inPHS

Also checks portalareas so that doors block sound
=================
*)

function PF_inPHS(var p1, p2: vec3_t): qboolean; cdecl;
var
  leafnum: Integer;
  cluster: Integer;
  area1,
    area2: Integer;
  mask: PByteArray;
begin
  leafnum := CM_PointLeafnum(p1);
  cluster := CM_LeafCluster(leafnum);
  area1 := CM_LeafArea(leafnum);
  mask := PByteArray(CM_ClusterPHS(cluster));

  leafnum := CM_PointLeafnum(p2);
  cluster := CM_LeafCluster(leafnum);
  area2 := CM_LeafArea(leafnum);
  if (mask <> nil) and (not ((mask[cluster shr 3] <> 0) and (1 shl (cluster and 7) <> 0))) then
  begin
    Result := False;
    exit;                               // more than one bounce away
  end;
  if (not CM_AreasConnected(area1, area2)) then
  begin
    Result := False;
    exit;                               // a door blocks hearing
  end;
  Result := True;
end;

procedure PF_StartSound(entity: edict_p; channel: Integer; sound_num: Integer; volume: Single;
  attenuation: Single; timeofs: Single); cdecl;
begin
  if (entity = nil) then
    exit;
  SV_StartSound(nil, entity, channel, sound_num, volume, attenuation, timeofs);
end;

//==============================================

(*
===============
SV_ShutdownGameProgs

Called when either the entire server is being killed, or
it is changing to a different game directory.
===============
*)

procedure SV_ShutdownGameProgs;
begin
  if (ge = nil) then
    exit;
  ge.Shutdown;
  Sys_UnloadGame;
  ge := nil;
end;

(*
===============
SV_InitGameProgs

Init the game subsystem for a new map
===============
*)
//procedure SCR_DebugGraph (value:float; color:integer); cdecl;

procedure SV_InitGameProgs;
var
  import: game_import_t;
begin
  // unload anything we have now
  if (ge <> nil) then
    SV_ShutdownGameProgs;

  // load a new game dll
  import.multicast := SV_Multicast;
  import.unicast := PF_Unicast;
  import.bprintf := SV_BroadcastPrintf_cdecl;
  import.dprintf := PF_dprintf_cdecl;
  import.cprintf := PF_cprintf_cdecl;
  import.centerprintf := PF_centerprintf_cdecl;
  {TODO Juha: We need to make cdecl varargs compatible routine for PF_error as well}
  import.error := PF_error;

  import.linkentity := SV_LinkEdict;
  import.unlinkentity := SV_UnlinkEdict;
  import.BoxEdicts := SV_AreaEdicts;
  import.trace := SV_Trace;
  import.pointcontents := SV_PointContents;
  import.setmodel := PF_setmodel;
  import.inPVS := PF_inPVS;
  import.inPHS := PF_inPHS;
  import.Pmove := Pmove;

  import.modelindex := SV_ModelIndex;
  import.soundindex := SV_SoundIndex;
  import.imageindex := SV_ImageIndex;

  import.configstring := PF_Configstring;
  import.sound := PF_StartSound;
  import.positioned_sound := SV_StartSound;

  import.WriteChar := PF_WriteChar;
  import.WriteByte := PF_WriteByte;
  import.WriteShort := PF_WriteShort;
  import.WriteLong := PF_WriteLong;
  import.WriteFloat := PF_WriteFloat;
  import.WriteString := PF_WriteString;
  import.WritePosition := PF_WritePos;
  import.WriteDir := PF_WriteDir;
  import.WriteAngle := PF_WriteAngle;

  import.TagMalloc := Z_TagMalloc;
  import.TagFree := Z_Free;
  import.FreeTags := Z_FreeTags;

  import.cvar := Cvar_Get;
  import.cvar_set := Cvar_Set;
  import.cvar_forceset := Cvar_ForceSet;

  import.argc := Cmd_Argc;
  import.argv := Cmd_Argv;
  import.args := Cmd_Args;
  import.AddCommandString := Cbuf_AddText;

  import.DebugGraph := SCR_DebugGraph;
  import.SetAreaPortalState := CM_SetAreaPortalState;
  import.AreasConnected := CM_AreasConnected;

  ge := Sys_GetGameAPI(@import);

  if (ge = nil) then
    Com_Error(ERR_DROP, 'failed to load game DLL');
  if (ge.apiversion <> GAME_API_VERSION) then
    Com_Error(ERR_DROP, 'game is version %i, not %i', [ge.apiversion, GAME_API_VERSION]);

  ge.Init();
end;

end.
