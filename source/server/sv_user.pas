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

unit sv_user;

{----------------------------------------------------------------------------}
{                                                                            }
{ File(s): sv_user.c                                                         }
{                                                                            }
{ Initial conversion by : Scott Price (scott.price@totalise.co.uk)           }
{ Initial conversion on : 23-Feb-2002                                        }
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
{ Updated on : 16-jul-2002                                                   }
{ Updated by : Sly                                                           }
{ - Fixed bad translation of SV_ExecuteUserCommand                           }
{                                                                            }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{----------------------------------------------------------------------------}
// 25.07.2002 Juha: Proof-readed this unit

interface

uses
  SysUtils,
  GameUnit,
  Server,
  sv_init;

const
  MAX_STRINGCMDS = 8;

type
  ucmd_t = packed record
    name: PChar;
    func: procedure;
  end;
  ucmd_p = ^ucmd_t;

  // Global functions
procedure SV_Nextserver;
procedure SV_ExecuteClientMessage(cl: client_p);

// Functions for the local array
procedure SV_New_f;
procedure SV_Configstrings_f;
procedure SV_Baselines_f;
procedure SV_Begin_f;
procedure SV_Nextserver_f;
procedure SV_Disconnect_f;
procedure SV_ShowServerinfo_f;
procedure SV_BeginDownload_f;
procedure SV_NextDownload_f;

var
  sv_player: edict_p;

  ucmds: array[0..9] of ucmd_t = (      // auto issued
    (name: 'new'; func: SV_New_f),
    (name: 'configstrings'; func: SV_Configstrings_f),
    (name: 'baselines'; func: SV_Baselines_f),
    (name: 'begin'; func: SV_Begin_f),

    (name: 'nextserver'; func: SV_Nextserver_f),

    (name: 'disconnect'; func: SV_Disconnect_f),

    // issued by hand at client consoles
    (name: 'info'; func: SV_ShowServerinfo_f),

    (name: 'download'; func: SV_BeginDownload_f),
    (name: 'nextdl'; func: SV_NextDownload_f),

    (name: nil; func: nil));

implementation

uses
  Files,
  Common,
  CVar,
  CPas,
  Cmd,
  net_chan,
  sv_main,
  sv_game,
  q_shared;

(* ============================================================

USER STRINGCMD EXECUTION

sv_client and sv_player will be valid.
============================================================ *)

(* ==================
SV_BeginDemoServer
================== *)

procedure SV_BeginDemoserver;
var
  name: array[0..MAX_OSPATH - 1] of char;
begin
  Com_sprintf(name, SizeOf(name), 'demos/%s', [sv.name]);
  FS_FOpenFile(name, sv.demofile);
  if (sv.demofile <= 0) then
    Com_Error(ERR_DROP, 'Couldn''t open %s'#10, [name]);
end;

(* ================
SV_New_f

Sends the first message from the server to a connected client.
This will be sent on the initial connection and upon each server load.
================ *)

procedure SV_New_f;
var
  gamedir: PChar;
  playernum: Integer;
  ent: edict_p;
begin
  Com_DPrintf('New() from %s'#10, [sv_client^.name]);

  if (sv_client^.state <> cs_connected) then
  begin
    Com_Printf('New not valid -- already spawned'#10, []);
    Exit;
  end;

  { demo servers just dump the file message }
  if (sv.state = ss_demo) then
  begin
    SV_BeginDemoserver;
    Exit;
  end;

  { serverdata needs to go over for all types of servers
    to make sure the protocol is right, and to set the gamedir }
  gamedir := Cvar_VariableString('gamedir');

  { send the serverdata }
  MSG_WriteByte(sv_client^.netchan.message, Integer(svc_serverdata));
  MSG_WriteLong(sv_client^.netchan.message, PROTOCOL_VERSION);
  MSG_WriteLong(sv_client^.netchan.message, svs.spawncount);
  MSG_WriteByte(sv_client^.netchan.message, Integer(sv.attractloop));
  MSG_WriteString(sv_client^.netchan.message, gamedir);

  if (sv.state = ss_cinematic) or (sv.state = ss_pic) then
    playernum := -1
  else
    playernum := (Cardinal(sv_client) - Cardinal(svs.clients)) div sizeof(client_t);

  MSG_WriteShort(sv_client^.netchan.message, playernum);

  { send full levelname }
  MSG_WriteString(sv_client^.netchan.message, sv.configstrings[CS_NAME]);

  { game server }
  if (sv.state = ss_game) then
  begin
    { set up the entity for the client }
    ent := EDICT_NUM(playernum + 1);
    ent^.s.number := playernum + 1;
    sv_client^.edict := ent;
    FillChar(sv_client^.lastcmd, SizeOf(sv_client^.lastcmd), 0);

    { begin fetching configstrings }
    MSG_WriteByte(sv_client^.netchan.message, Integer(svc_stufftext));
    MSG_WriteString(sv_client^.netchan.message, va('cmd configstrings %d 0'#10, [svs.spawncount]));
  end;
end;

(* ==================
SV_Configstrings_f
================== *)

procedure SV_Configstrings_f;
var
  start, iHalfMesLen: Integer;
begin
  Com_DPrintf('Configstrings() from %s'#10, [sv_client^.name]);

  if (sv_client^.state <> cs_connected) then
  begin
    Com_Printf('configstrings not valid -- already spawned'#10, []);
    Exit;
  end;

  { handle the case of a level changing while a client was connecting }
  if (StrToInt(Cmd_Argv(1)) <> svs.spawncount) then
  begin
    Com_Printf('SV_Configstrings_f from different level'#10, []);
    SV_New_f;
    Exit;
  end;

  start := StrToInt(Cmd_Argv(2));

  { write a packet full of data }

  iHalfMesLen := (MAX_MSGLEN div 2);
  while (sv_client^.netchan.message.cursize < iHalfMesLen) and (start < MAX_CONFIGSTRINGS) do
  begin
    if (sv.configstrings[start][0] <> #0) then
    begin
      MSG_WriteByte(sv_client^.netchan.message, Integer(svc_configstring));
      MSG_WriteShort(sv_client^.netchan.message, start);
      MSG_WriteString(sv_client^.netchan.message, sv.configstrings[start]);
    end;

    Inc(start);
  end;

  { send next command }
  if (start = MAX_CONFIGSTRINGS) then
  begin
    MSG_WriteByte(sv_client^.netchan.message, Integer(svc_stufftext));
    MSG_WriteString(sv_client^.netchan.message, va('cmd baselines %d 0'#10, [svs.spawncount]));
  end
  else
  begin
    MSG_WriteByte(sv_client^.netchan.message, Integer(svc_stufftext));
    MSG_WriteString(sv_client^.netchan.message, va('cmd configstrings %d %d'#10, [svs.spawncount, start]));
  end;
end;

(* ==================
SV_Baselines_f
================== *)

procedure SV_Baselines_f;
var
  start: Integer;
  nullstate: entity_state_t;
  base: entity_state_p;
begin
  Com_DPrintf('Baselines() from %s'#10, [sv_client^.name]);

  if (sv_client^.state <> cs_connected) then
  begin
    Com_Printf('baselines not valid -- already spawned'#10, []);
    Exit;
  end;

  { handle the case of a level changing while a client was connecting }
  if (atoi(Cmd_Argv(1)) <> svs.spawncount) then
  begin
    Com_Printf('SV_Baselines_f from different level'#10, []);
    SV_New_f;
    Exit;
  end;

  start := atoi(Cmd_Argv(2));

  FillChar(nullstate, SizeOf(nullstate), 0);

  { write a packet full of data }
  while (sv_client^.netchan.message.cursize < MAX_MSGLEN div 2) and (start < MAX_EDICTS) do
  begin
    base := @sv.baselines[start];
    if (base^.modelindex <> 0) or (base^.sound <> 0) or (base^.effects <> 0) then
    begin
      MSG_WriteByte(sv_client^.netchan.message, Integer(svc_spawnbaseline));
      MSG_WriteDeltaEntity(nullstate, base^, sv_client^.netchan.message, true, true);
    end;

    Inc(start);
  end;

  { send next command }
  if (start = MAX_EDICTS) then
  begin
    MSG_WriteByte(sv_client^.netchan.message, Integer(svc_stufftext));
    MSG_WriteString(sv_client^.netchan.message, va('precache %d'#10, [svs.spawncount]));
  end
  else
  begin
    MSG_WriteByte(sv_client^.netchan.message, Integer(svc_stufftext));
    MSG_WriteString(sv_client^.netchan.message, va('cmd baselines %d %d'#10, [svs.spawncount, start]));
  end;
end;

(* ==================
SV_Begin_f
================== *)

procedure SV_Begin_f;
begin
  Com_DPrintf('Begin() from %s'#10, [sv_client^.name]);

  { handle the case of a level changing while a client was connecting }
  if (StrToInt(Cmd_Argv(1)) <> svs.spawncount) then
  begin
    Com_Printf('SV_Begin_f from different level'#10, []);
    SV_New_f;
    Exit;
  end;

  sv_client^.state := cs_spawned;

  { call the game begin function }
  ge^.ClientBegin(sv_player);

  Cbuf_InsertFromDefer;
end;

(* ==================
SV_NextDownload_f
================== *)

procedure SV_NextDownload_f;
var
  r, percent, size: Integer;
begin
  if (sv_client^.download = nil) then
    Exit;

  r := (sv_client^.downloadsize - sv_client^.downloadcount);
  if (r > 1024) then
    r := 1024;

  MSG_WriteByte(sv_client^.netchan.message, Integer(svc_download));
  MSG_WriteShort(sv_client^.netchan.message, r);

  sv_client^.downloadcount := sv_client^.downloadcount + r;
  size := sv_client^.downloadsize;
  if (size = 0) then
    size := 1;

  percent := (sv_client^.downloadcount * 100) div size;
  MSG_WriteByte(sv_client^.netchan.message, percent);
  SZ_Write(sv_client^.netchan.message, Pointer(Cardinal(sv_client^.download) + sv_client^.downloadcount - r), r);

  if (sv_client^.downloadcount <> sv_client^.downloadsize) then
    Exit;

  FS_FreeFile(sv_client^.download);
  sv_client^.download := nil;
end;

(* ==================
SV_BeginDownload_f
================== *)

procedure SV_BeginDownload_f;
var
  name: PChar;
  offset: Integer;
begin
  (*
  extern   cvar_t *allow_download;
  extern   cvar_t *allow_download_players;
  extern   cvar_t *allow_download_models;
  extern   cvar_t *allow_download_sounds;
  extern   cvar_t *allow_download_maps;
  extern   int      file_from_pak; // ZOID did file come from pak? *)
  offset := 0;

  name := Cmd_Argv(1);

  if (Cmd_Argc > 2) then
    offset := StrToInt(Cmd_Argv(2));    // downloaded offset

  { hacked by zoid to allow more conrol over download
    first off, no .. or global allow check }
  if ((strstr(name, '..') <> nil)
    or (not (allow_download.value <> 0))
    // leading dot is no good
    or (name^ = '.')
    // leading slash bad as well, must be in subdir
    or (name^ = '/')
    // next up, skin check
    or ((strncmp(name, 'players/', 6) = 0) and (not (allow_download_players.value <> 0)))
    // now models
    or ((strncmp(name, 'models/', 6) = 0) and (not (allow_download_models.value <> 0)))
    // now sounds
    or ((strncmp(name, 'sound/', 6) = 0) and (not (allow_download_sounds.value <> 0)))
    // now maps (note special case for maps, must not be in pak)
    or ((strncmp(name, 'maps/', 6) = 0) and (not (allow_download_maps.value <> 0)))
    // MUST be in a subdirectory
    or (strstr(name, '/') = nil)
    ) then
  begin                                 { don't allow anything with .. path }
    MSG_WriteByte(sv_client^.netchan.message, Integer(svc_download));
    MSG_WriteShort(sv_client^.netchan.message, -1);
    MSG_WriteByte(sv_client^.netchan.message, 0);
    Exit;
  end;

  if (sv_client^.download <> nil) then
    FS_FreeFile(sv_client^.download);

  sv_client^.downloadsize := FS_LoadFile(name, @sv_client^.download);
  sv_client^.downloadcount := offset;

  if (offset > sv_client^.downloadsize) then
    sv_client^.downloadcount := sv_client^.downloadsize;

  if (not (sv_client^.download <> nil)
    // special check for maps, if it came from a pak file, don't allow
    // download  ZOID
    or (strncmp(name, 'maps/', 5) = 0) and (file_from_pak <> 0)) then
  begin
    Com_DPrintf('Couldn''t download %s to %s'#10, [name, sv_client^.name]);
    if (sv_client^.download <> nil) then
    begin
      FS_FreeFile(sv_client^.download);
      sv_client^.download := nil;
    end;

    MSG_WriteByte(sv_client^.netchan.message, Integer(svc_download));
    MSG_WriteShort(sv_client^.netchan.message, -1);
    MSG_WriteByte(sv_client^.netchan.message, 0);
    Exit;
  end;

  SV_NextDownload_f;
  Com_DPrintf('Downloading %s to %s'#10, [name, sv_client^.name]);
end;

(* =================
SV_Disconnect_f

The client is going to disconnect, so remove the connection immediately
================= *)

procedure SV_Disconnect_f;
begin
  //   SV_EndRedirect ();
  SV_DropClient(sv_client);
end;

(* ==================
SV_ShowServerinfo_f

Dumps the serverinfo info string
================== *)

procedure SV_ShowServerinfo_f;
begin
  Info_Print(Cvar_Serverinfo_);
end;

procedure SV_Nextserver;
var
  v: PChar;
begin
  //ZOID, ss_pic can be nextserver'd in coop mode
  if (sv.state = ss_game) or ((sv.state = ss_pic) and (not (Cvar_VariableValue('coop') <> 0))) then
    Exit;                               // can't nextserver while playing a normal game

  Inc(svs.spawncount);                  // make sure another doesn't sneak in
  v := Cvar_VariableString('nextserver');
  if (v[0] = #0) then
    Cbuf_AddText('killserver'#10)
  else
  begin
    Cbuf_AddText(v);
    Cbuf_AddText(#10);
  end;
  Cvar_Set('nextserver', '');
end;

(* ==================
SV_Nextserver_f

A cinematic has completed or been aborted by a client, so move
to the next server,
================== *)

procedure SV_Nextserver_f;
begin
  if (StrToInt(Cmd_Argv(1)) <> svs.spawncount) then
  begin
    Com_DPrintf('Nextserver() from wrong level, from %s'#10, [sv_client^.name]);
    Exit;                               // leftover from last server
  end;

  Com_DPrintf('Nextserver() from %s'#10, [sv_client^.name]);

  SV_Nextserver;
end;

(* ==================
SV_ExecuteUserCommand
================== *)

procedure SV_ExecuteUserCommand(s: PChar);
var
  i: Integer;
begin
  Cmd_TokenizeString(s, true);
  sv_player := sv_client^.edict;

  //  SV_BeginRedirect (RD_CLIENT);

  i := 0;
  while (ucmds[i].name <> nil) do
  begin
    if (strcmp(Cmd_Argv(0), ucmds[i].name) = 0) then
    begin
      ucmds[i].func;
      Exit;
    end;
    Inc(i);
  end;

  if ((ucmds[i].name = nil) and (sv.state = ss_game)) then
    ge^.ClientCommand(sv_player);

  //  SV_EndRedirect ();
end;

(* ===========================================================================

USER CMD EXECUTION

=========================================================================== *)

procedure SV_ClientThink(cl: client_p; cmd: usercmd_p);
begin
  cl^.commandMsec := (cl^.commandMsec - cmd.msec);

  if (cl^.commandMsec < 0) and (sv_enforcetime^.value <> 0) then
  begin
    Com_DPrintf('commandMsec underflow from %s'#10, [cl^.name]);
    Exit;
  end;

  ge^.ClientThink(cl^.edict, cmd);
end;

(* ===================
SV_ExecuteClientMessage

The current net_message is parsed for the given client
=================== *)

procedure SV_ExecuteClientMessage(cl: client_p);
var
  c, net_drop, stringCmdCount, checksum, calculatedChecksum, checksumIndex,
    lastframe: Integer;
  s: PChar;
  nullcmd, oldest, oldcmd, newcmd: usercmd_t;
  move_issued: qboolean;
begin
  sv_client := cl;
  sv_player := sv_client^.edict;

  // only allow one move command
  move_issued := false;
  stringCmdCount := 0;

  while (True) do
  begin
    if (net_message.readcount > net_message.cursize) then
    begin
      Com_Printf('SV_ReadClientMessage: badread'#10, []);
      SV_DropClient(cl);
      Exit;
    end;

    c := MSG_ReadByte(net_message);
    if (c = -1) then
      Break;

    case clc_ops_e(c) of
      clc_nop: ;

      clc_userinfo:
        begin
          strncpy(cl^.userinfo, MSG_ReadString(net_message), (SizeOf(cl^.userinfo) - 1));
          SV_UserinfoChanged(cl);
        end;

      clc_move:
        begin
          if (move_issued) then
            Exit;                       { someone is trying to cheat... }

          move_issued := true;
          checksumIndex := net_message.readcount;
          checksum := MSG_ReadByte(net_message);
          lastframe := MSG_ReadLong(net_message);
          if (lastframe <> cl^.lastframe) then
          begin
            cl^.lastframe := lastframe;
            if (cl^.lastframe > 0) then
            begin
              cl^.frame_latency[cl^.lastframe and (LATENCY_COUNTS - 1)] :=
                svs.realtime - cl^.frames[cl^.lastframe and UPDATE_MASK].senttime;
            end;
          end;

          FillChar(nullcmd, SizeOf(nullcmd), 0);
          MSG_ReadDeltaUsercmd(net_message, nullcmd, oldest);
          MSG_ReadDeltaUsercmd(net_message, oldest, oldcmd);
          MSG_ReadDeltaUsercmd(net_message, oldcmd, newcmd);

          if (cl^.state <> cs_spawned) then
          begin
            cl^.lastframe := -1;
            Break;
          end;

          { if the checksum fails, ignore the rest of the packet }
          calculatedChecksum := COM_BlockSequenceCRCByte(
            Pointer(Cardinal(net_message.data) + checksumIndex + 1),
            net_message.readcount - checksumIndex - 1,
            cl.netchan.incoming_sequence);

          if (calculatedChecksum <> checksum) then
          begin
            Com_DPrintf('Failed command checksum for %s (%d != %d)/%d'#10,
              [cl.name, calculatedChecksum, checksum,
              cl.netchan.incoming_sequence]);
            Exit;
          end;

          if (sv_paused.value = 0) then
          begin
            net_drop := cl.netchan.dropped;
            if (net_drop < 20) then
            begin
              //if (net_drop > 2)

              //   Com_Printf ("drop %d\n", net_drop);
              while (net_drop > 2) do
              begin
                SV_ClientThink(cl, @cl.lastcmd);

                Dec(net_drop);
              end;

              if (net_drop > 1) then
                SV_ClientThink(cl, @oldest);

              if (net_drop > 0) then
                SV_ClientThink(cl, @oldcmd);

            end;
            SV_ClientThink(cl, @newcmd);
          end;

          cl.lastcmd := newcmd;
        end;

      clc_stringcmd:
        begin
          s := MSG_ReadString(net_message);

          { malicious users may try using too many string commands }
          Inc(stringCmdCount);
          if (stringCmdCount < MAX_STRINGCMDS) then
            SV_ExecuteUserCommand(s);

          if (cl^.state = cs_zombie) then
            Exit;                       { disconnect command }

        end;
    else
      Com_Printf('SV_ReadClientMessage: unknown command char'#10, []);
      SV_DropClient(cl);
      Exit;
    end;
  end;
end;

end.
