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
{ File(s): sv_main.c                                                         }
{                                                                            }
{ Initial conversion by : George Melekos (inet_crow@hotmail.com)             }
{ Initial conversion on : 13-Feb-2002                                        }
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
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{----------------------------------------------------------------------------}
// 25.07.2002 Juha: Proof-readed this unit

  // address of group servers
  // current client
  // seconds without any message
  // seconds to sink messages after disconnect
  // password for remote server commands
  // don't reload level state when reentering
  // FIXME: rename sv_maxclients
  // should heartbeats be sent
  // minimum seconds between connect messages

unit sv_main;

interface

uses
  {$IFDEF WIN32}
  Windows,
  {$ENDIF}
  SysUtils,
  Common,
  GameUnit,
  q_shared,
  Server,
  ref;

var
  master_adr: array[0..MAX_MASTERS - 1] of netadr_t; // address of group servers

  sv_client: client_p;                  // current client

  sv_paused,
    sv_timedemo,

  sv_enforcetime,

  timeout,                              // seconds without any message
  zombietime,                           // seconds to sink messages after disconnect

  rcon_password,                        // password for remote server commands

  allow_download,
    allow_download_players,
    allow_download_models,
    allow_download_sounds,
    allow_download_maps,

  sv_airaccelerate,

  sv_noreload,                          // don't reload level state when reentering

  maxclients,                           // FIXME: rename sv_maxclients
  sv_showclamp,

  hostname,
    public_server,                      // should heartbeats be sent

  sv_reconnect_limit: cvar_p;           // minimum seconds between connect messages

  //============================================================================

(*
=====================
SV_DropClient

Called when the player is totally leaving the server, either willingly
or unwillingly.  This is NOT called if the entire server is quiting
or crashing.
=====================
*)

procedure SV_DropClient(drop: client_p);
// add the disconnect

(*
==============================================================================

CONNECTIONLESS COMMANDS

==============================================================================
*)

(*
===============
SV_StatusString

Builds the string that is sent as heartbeats and status replies
===============
*)

function SV_StatusString: PChar;

(*
================
SVC_Status

Responds with all the info that qplug or qspy can see
================
*)

procedure SVC_Status;

(*
================
SVC_Ack

================
*)

procedure SVC_Ack;

(*
================
SVC_Info

Responds with short info for broadcast scans
The second parameter should be the current protocol version number.
================
*)

procedure SVC_Info;

(*
================
SVC_Ping

Just responds with an acknowledgement
================
*)

procedure SVC_Ping;

(*
=================
SVC_GetChallenge

Returns a challenge number that can be used
in a subsequent client_connect command.
We do this to prevent denial of service attacks that
flood the server with invalid connection IPs.  With a
challenge, they must give a valid IP address.
=================
*)

procedure SVC_GetChallenge;

(*
==================
SVC_DirectConnect

A connection request that did not come from the master
==================
*)

procedure SVC_DirectConnect;

function Rcon_Validate: Integer;

(*
===============
SVC_RemoteCommand

A client issued an rcon command.
Shift down the remaining args
Redirect all printfs
===============
*)

procedure SVC_RemoteCommand;

(*
=================
SV_ConnectionlessPacket

A connectionless packet has four leading $ff
characters to distinguish it from a game channel.
Clients that are in the game can still send
connectionless packets.
=================
*)

procedure SV_ConnectionlessPacket;
//============================================================================

(*
===================
SV_CalcPings

Updates the cl^.ping variables
===================
*)

procedure SV_CalcPings;

(*
===================
SV_GiveMsec

Every few frames, gives all clients an allotment of milliseconds
for their command moves.  If they exceed it, assume cheating.
===================
*)

procedure SV_GiveMsec;

(*
=================
SV_ReadPackets
=================
*)

procedure SV_ReadPackets;

(*
==================
SV_CheckTimeouts

If a packet has not been received from a client for timeout^.value
seconds, drop the conneciton.  Server frames are used instead of
realtime to aprocedure dropping the local client while debugging.

When a client is normally dropped, the client_t goes into a zombie state
for a few seconds to make sure any final reliable message gets resent
if necessary
==================
*)

procedure SV_CheckTimeouts;

(*
================
SV_PrepWorldFrame

This has to be done before the world logic, because
player processing happens outside RunWorldFrame
================
*)

procedure SV_PrepWorldFrame;

(*
=================
SV_RunGameFrame
=================
*)

procedure SV_RunGameFrame;

(*
==================
SV_Frame

==================
*)

procedure SV_Frame(msec: Integer);
//============================================================================

(*
================
Master_Heartbeat

Send a message to the master every few minutes to
let it know we are alive, and log information
================
*)

const
  HEARTBEAT_SECONDS = 300;

procedure Master_Heartbeat;

(*
=================
Master_Shutdown

Informs all masters that this server is going down
=================
*)

procedure Master_Shutdown;
//============================================================================

(*
=================
SV_UserinfoChanged

Pull specific info from a newly changed userinfo string
into a more C freindly form.
=================
*)

procedure SV_UserinfoChanged(cl: client_p);
//============================================================================

(*
===============
SV_Init

Only called at quake2.exe startup, not for each game
===============
*)

procedure SV_Init;

(*
==================
SV_FinalMessage

Used by SV_Shutdown to send a final message to all
connected clients before the server goes down.  The messages are sent immediately,
not just stuck on the outgoing message list, because the server is going
to totally exit after returning from this function.
==================
*)

procedure SV_FinalMessage(message_: PChar; reconnect: qboolean);

(*
================
SV_Shutdown

Called when each game quits,
before Sys_Quit or Sys_Error
================
*)

procedure SV_Shutdown(finalmsg: PChar; reconnect: qboolean);

implementation

uses
  CVar,
  CPas,
  Cmd,
  Files,
  {$IFDEF WIN32}
  net_wins,
  q_shwin,
  {$ELSE}
  net_udp,
  q_shlinux,
  {$ENDIF}
  net_chan,
  sv_ccmds,
  sv_send,
  sv_ents,
  sv_init,
  sv_user,
  sv_game;

(*
=====================
SV_DropClient

Called when the player is totally leaving the server, either willingly
or unwillingly.  This is NOT called if the entire server is quiting
or crashing.
=====================
*)

procedure SV_DropClient(drop: client_p);
begin
  // add the disconnect
  MSG_WriteByte(drop.netchan.message, Integer(svc_disconnect));

  if (drop^.state = cs_spawned) then
  begin
    // call the prog function for removing a client
    // this will remove the body, among other things
    ge^.ClientDisconnect(drop^.edict);
  end;

  if (drop^.download <> nil) then
  begin
    FS_FreeFile(drop^.download);
    drop^.download := nil;
  end;

  drop^.state := cs_zombie;             // become free in a few seconds
  drop^.name[0] := #0;
end;

(*
==============================================================================

CONNECTIONLESS COMMANDS

==============================================================================
*)

(*
===============
SV_StatusString

Builds the string that is sent as heartbeats and status replies
===============
*)
var
  status: array[0..MAX_MSGLEN - 16 - 1] of char;

function SV_StatusString(): pchar;
var
  player: array[0..1024 - 1] of char;
  i: integer;
  cl: client_p;
  statusLength: integer;
  playerLength: integer;
begin
  strcpy(status, Cvar_Serverinfo_());
  strcat(status, #10);
  statusLength := strlen(status);

  for i := 0 to Round(maxclients^.value) - 1 do
  begin
    cl := @svs.clients^[i];
    if (cl^.state = cs_connected) or (cl^.state = cs_spawned) then
    begin
      Com_sprintf(player, sizeof(player), '%i %i "%s"'#10,
        [cl^.edict^.client^.ps.stats[STAT_FRAGS], cl^.ping, cl^.name]);
      playerLength := strlen(player);
      if (statusLength + playerLength >= sizeof(status)) then
        break;                          // can't hold any more
      strcpy(status + statusLength, player);
      statusLength := statusLength + playerLength;
    end;
  end;

  Result := status;
end;

(*
================
SVC_Status

Responds with all the info that qplug or qspy can see
================
*)

procedure SVC_Status();
begin
  Netchan_OutOfBandPrint(NS_SERVER, net_from, 'print'#10'%s', [SV_StatusString()]);
  {
   Com_BeginRedirect (RD_PACKET, sv_outputbuf, SV_OUTPUTBUF_LENGTH, SV_FlushRedirect);
   Com_Printf (SV_StatusString());
   Com_EndRedirect ();
  }
end;

(*
================
SVC_Ack

================
*)

procedure SVC_Ack();
begin
  Com_Printf('Ping acknowledge from %s'#10, [NET_AdrToString(net_from)]);
end;

(*
================
SVC_Info

Responds with short info for broadcast scans
The second parameter should be the current protocol version number.
================
*)

procedure SVC_Info();
var
  string_: array[0..64 - 1] of char;
  i, count: Integer;
  version: integer;
begin
  if (maxclients^.value = 1) then
    exit;                               // ignore in single player

  version := StrToInt(Cmd_Argv(1));

  if (version <> PROTOCOL_VERSION) then
    Com_sprintf(string_, sizeof(string_), '%s: wrong version'#10, [hostname^.string_, sizeof(string_)])
  else
  begin
    count := 0;
    for i := 0 to Round(maxclients^.value) - 1 do
      if (svs.clients^[i].state >= cs_connected) then
        Inc(count);
    Com_sprintf(string_, sizeof(string_), '%16s %8s %2i/%2i'#10, [hostname^.string_, sv.name, count, round(maxclients^.value)]);
  end;

  Netchan_OutOfBandPrint(NS_SERVER, net_from, 'info'#10'%s', [string_]);
end;

(*
================
SVC_Ping

Just responds with an acknowledgement
================
*)

procedure SVC_Ping();
begin
  Netchan_OutOfBandPrint(NS_SERVER, net_from, 'ack', []);
end;

(*
=================
SVC_GetChallenge

Returns a challenge number that can be used
in a subsequent client_connect command.
We do this to prevent denial of service attacks that
flood the server with invalid connection IPs.  With a
challenge, they must give a valid IP address.
=================
*)

procedure SVC_GetChallenge();
var
  i: integer;
  oldest: integer;
  oldestTime: integer;
begin
  oldest := 0;
  oldestTime := $7FFFFFFF;

  // see if we already have a challenge for this ip
  i := 0;
  while (i < MAX_CHALLENGES) do
  begin
    if (NET_CompareBaseAdr(net_from, svs.challenges[i].adr)) then
      break;
    if (svs.challenges[i].time < oldestTime) then
    begin
      oldestTime := svs.challenges[i].time;
      oldest := i;
    end;
    Inc(i);
  end;

  if (i = MAX_CHALLENGES) then
  begin
    // overwrite the oldest
    svs.challenges[oldest].challenge := rand() and $7FFF;
    svs.challenges[oldest].adr := net_from;
    svs.challenges[oldest].time := curtime;
    i := oldest;
  end;

  // send it back
  Netchan_OutOfBandPrint(NS_SERVER, net_from, 'challenge %i', [svs.challenges[i].challenge]);
end;

(*
==================
SVC_DirectConnect

A connection request that did not come from the master
==================
*)

procedure SVC_DirectConnect();
var
  userinfo: array[0..MAX_INFO_STRING - 1] of char;
  adr: netadr_t;
  i: integer;
  cl, newcl: client_p;
  temp: client_t;
  ent: edict_p;
  edictnum: integer;
  version: integer;
  qport: integer;
  challenge: integer;
label
  gotnewcl;
begin
  adr := net_from;

  Com_DPrintf('SVC_DirectConnect ()'#10);

  version := StrToInt(Cmd_Argv(1));
  if (version <> PROTOCOL_VERSION) then
  begin
    Netchan_OutOfBandPrint(NS_SERVER, adr, 'print'#10'Server is version %4.2f.'#10, [VERSION]);
    Com_DPrintf('    rejected connect from version %i'#10, [version]);
    exit;
  end;

  qport := StrToInt(Cmd_Argv(2));

  challenge := StrToInt(Cmd_Argv(3));

  strncpy(userinfo, Cmd_Argv(4), sizeof(userinfo) - 1);
  userinfo[sizeof(userinfo) - 1] := #0;

  // force the IP key/value pair so the game can filter based on ip
  Info_SetValueForKey(userinfo, 'ip', NET_AdrToString(net_from));

  // attractloop servers are ONLY for local clients
  if (sv.attractloop) then
  begin
    if (not NET_IsLocalAddress(adr)) then
    begin
      Com_Printf('Remote connect in attract loop.  Ignored.'#10);
      Netchan_OutOfBandPrint(NS_SERVER, adr, 'print'#10'Connection refused.'#10, []);
      exit;
    end;
  end;

  // see if the challenge is valid
  if (not NET_IsLocalAddress(adr)) then
  begin
    for i := 0 to MAX_CHALLENGES - 1 do
    begin
      if (NET_CompareBaseAdr(net_from, svs.challenges[i].adr)) then
      begin
        if (challenge = svs.challenges[i].challenge) then
          break;                        // good
        Netchan_OutOfBandPrint(NS_SERVER, adr, 'print'#10'Bad challenge.'#10, []);
        exit;
      end;
    end;
    if (i = MAX_CHALLENGES) then
    begin
      Netchan_OutOfBandPrint(NS_SERVER, adr, 'print'#10'No challenge for address.'#10, []);
      exit;
    end;
  end;

  newcl := @temp;
  FillChar(newcl^, sizeof(client_t), #0);

  // if there is already a slot for this ip, reuse it
  for i := 0 to Round(maxclients^.value) - 1 do
  begin
    cl := @svs.clients^[i];
    if (cl^.state = cs_free) then
      continue;
    if NET_CompareBaseAdr(adr, cl^.netchan.remote_address) and
      ((cl^.netchan.qport = qport) or (adr.port = cl^.netchan.remote_address.port)) then
    begin
      if (not NET_IsLocalAddress(adr)) and ((svs.realtime - cl^.lastconnect) < (sv_reconnect_limit^.value * 1000)) then
      begin
        Com_DPrintf('%s:reconnect rejected : too soon'#10, [NET_AdrToString(adr)]);
        exit;
      end;
      Com_Printf('%s:reconnect'#10, [NET_AdrToString(adr)]);
      newcl := cl;
      goto gotnewcl;
    end;
  end;

  // find a client slot
  newcl := nil;

  for i := 0 to round(maxclients^.value) - 1 do
  begin
    cl := @svs.clients^[i];
    if (cl^.state = cs_free) then
    begin
      newcl := cl;
      break;
    end;
  end;

  if (newcl = nil) then
  begin
    Netchan_OutOfBandPrint(NS_SERVER, adr, 'print'#10'Server is full.'#10, []);
    Com_DPrintf('Rejected a connection.'#10);
    exit;
  end;

  gotnewcl:
  // build a new connection
  // accept the new client
  // this is the only place a client_t is ever initialized
  newcl^ := temp;
  sv_client := newcl;
  edictnum := (Cardinal(newcl) - Cardinal(svs.clients)) div sizeof(client_s) + 1;
  ent := EDICT_NUM(edictnum);
  newcl^.edict := ent;
  newcl^.challenge := challenge;        // save challenge for checksumming

  // get the game a chance to reject this connection or modify the userinfo
  if (not (ge^.ClientConnect(ent, @userinfo))) then
  begin
    if (Info_ValueForKey(userinfo, 'rejmsg')^ <> #0) then
      Netchan_OutOfBandPrint(NS_SERVER, adr, 'print'#10'%s'#10'Connection refused.'#10,
        [Info_ValueForKey(userinfo, 'rejmsg')])
    else
      Netchan_OutOfBandPrint(NS_SERVER, adr, 'print'#10'Connection refused.'#10, []);
    Com_DPrintf('Game rejected a connection.'#10);
    exit;
  end;

  // parse some info from the info strings
  strncpy(newcl^.userinfo, userinfo, sizeof(newcl^.userinfo) - 1);
  SV_UserinfoChanged(newcl);

  // send the connect packet to the client
  Netchan_OutOfBandPrint(NS_SERVER, adr, 'client_connect', []);

  Netchan_Setup(NS_SERVER, @newcl^.netchan, adr, qport);

  newcl^.state := cs_connected;

  SZ_Init(newcl^.datagram, @newcl^.datagram_buf, sizeof(newcl^.datagram_buf));
  newcl^.datagram.allowoverflow := true;
  newcl^.lastmessage := svs.realtime;   // don't timeout
  newcl^.lastconnect := svs.realtime;
end;

function Rcon_Validate(): integer;
begin
  if (strlen(rcon_password^.string_) = 0) then
  begin
    Result := 0;
    exit;
  end;

  if (strcmp(Cmd_Argv(1), rcon_password^.string_) <> 0) then
  begin
    Result := 0;
    exit;
  end;

  Result := 1;
end;

(*
===============
SVC_RemoteCommand

A client issued an rcon command.
Shift down the remaining args
Redirect all printfs
===============
*)

procedure SVC_RemoteCommand();
var
  i: integer;
  remaining: array[0..1024 - 1] of char;
begin
  i := Rcon_Validate();

  if (i = 0) then
    Com_Printf('Bad rcon from %s:'#10'%s'#10, [NET_AdrToString(net_from), PChar(Pointer(Cardinal(net_message.data) + 4))])
  else
    Com_Printf('Rcon from %s:'#10'%s'#10, [NET_AdrToString(net_from), PChar(Pointer(Cardinal(net_message.data) + 4))]);

  Com_BeginRedirect(Integer(RD_PACKET), sv_outputbuf, SV_OUTPUTBUF_LENGTH, SV_FlushRedirect);

  if (Rcon_Validate() = 0) then
  begin
    Com_Printf('Bad rcon_password.'#10);
  end
  else
  begin
    remaining[0] := #0;

    for i := 2 to Cmd_Argc() - 1 do
    begin
      strcat(remaining, Cmd_Argv(i));
      strcat(remaining, ' ');
    end;

    Cmd_ExecuteString(remaining);
  end;

  Com_EndRedirect();
end;

(*
=================
SV_ConnectionlessPacket

A connectionless packet has four leading $ff
characters to distinguish it from a game channel.
Clients that are in the game can still send
connectionless packets.
=================
*)

procedure SV_ConnectionlessPacket();
var
  s: pchar;
  c: pchar;
begin
  MSG_BeginReading(net_message);
  MSG_ReadLong(net_message);            // skip the -1 marker

  s := MSG_ReadStringLine(net_message);

  Cmd_TokenizeString(s, false);

  c := Cmd_Argv(0);
  Com_DPrintf('Packet %s : %s'#10, [NET_AdrToString(net_from), c]);

  if (strcmp(c, 'ping') = 0) then
    SVC_Ping()
  else if (strcmp(c, 'ack') = 0) then
    SVC_Ack()
  else if (strcmp(c, 'status') = 0) then
    SVC_Status()
  else if (strcmp(c, 'info') = 0) then
    SVC_Info()
  else if (strcmp(c, 'getchallenge') = 0) then
    SVC_GetChallenge()
  else if (strcmp(c, 'connect') = 0) then
    SVC_DirectConnect()
  else if (strcmp(c, 'rcon') = 0) then
    SVC_RemoteCommand()
  else
    Com_Printf('bad connectionless packet from %s:'#10'%s'#10
      , [NET_AdrToString(net_from), s]);
end;

//============================================================================

(*
===================
SV_CalcPings

Updates the cl^.ping variables
===================
*)

procedure SV_CalcPings();
var
  i, j: integer;
  cl: client_p;
  total, count: integer;
begin
  for i := 0 to round(maxclients^.value) - 1 do
  begin
    cl := @svs.clients^[i];
    if (cl^.state <> cs_spawned) then
      continue;

    {
      if (cl^.lastframe > 0)
       cl^.frame_latency[sv.framenum&(LATENCY_COUNTS-1)] = sv.framenum - cl^.lastframe + 1;
      else
       cl^.frame_latency[sv.framenum&(LATENCY_COUNTS-1)] = 0;
    }

    total := 0;
    count := 0;
    for j := 0 to LATENCY_COUNTS - 1 do
    begin
      if (cl^.frame_latency[j] > 0) then
      begin
        Inc(count);
        total := total + cl^.frame_latency[j];
      end;
    end;
    if (count = 0) then
      cl^.ping := 0
    else
      {
        cl^.ping := total*100/count - 100;
      }
      cl^.ping := total div count;

    // let the game dll know about the ping
    cl^.edict^.client^.ping := cl^.ping;
  end;
end;

(*
===================
SV_GiveMsec

Every few frames, gives all clients an allotment of milliseconds
for their command moves.  If they exceed it, assume cheating.
===================
*)

procedure SV_GiveMsec();
var
  i: integer;
  cl: client_p;
begin
  if (sv.framenum and 15 <> 0) then
    exit;

  for i := 0 to Round(maxclients^.value) - 1 do
  begin
    cl := @svs.clients^[i];
    if (cl^.state = cs_free) then
      continue;

    cl^.commandMsec := 1800;            // 1600 + some slop
  end;
end;

(*
=================
SV_ReadPackets
=================
*)

procedure SV_ReadPackets();
var
  i: integer;
  cl: client_p;
  qport: integer;
begin
  {$IFDEF WIN32}
  while (NET_GetPacket(NS_SERVER, net_from, net_message)) do
  {$ELSE}
  while (NET_GetPacket(NS_SERVER, @net_from, @net_message)) do
  {$ENDIF}
  begin
    // check for connectionless packet ($ffffffff) first
    if (PInteger(net_message.data)^ = -1) then
    begin
      SV_ConnectionlessPacket();
      continue;
    end;

    // read the qport out of the message so we can fix up
    // stupid address translating routers
    MSG_BeginReading(net_message);
    MSG_ReadLong(net_message);          // sequence number
    MSG_ReadLong(net_message);          // sequence number
    qport := MSG_ReadShort(net_message) and $FFFF;

    // check for packets from connected clients
    for i := 0 to Round(maxclients^.value) - 1 do
    begin
      cl := @svs.clients^[i];
      if (cl^.state = cs_free) then
        continue;
      if (not NET_CompareBaseAdr(net_from, cl^.netchan.remote_address)) then
        continue;
      if (cl^.netchan.qport <> qport) then
        continue;
      if (cl^.netchan.remote_address.port <> net_from.port) then
      begin
        Com_Printf('SV_ReadPackets: fixing up a translated port'#10);
        cl^.netchan.remote_address.port := net_from.port;
      end;

      if (Netchan_Process(cl^.netchan, net_message)) then
      begin
        // this is a valid, sequenced packet, so process it
        if (cl^.state <> cs_zombie) then
        begin
          cl^.lastmessage := svs.realtime; // don't timeout
          SV_ExecuteClientMessage(cl);
        end;
      end;
      break;
    end;

    if (i <> maxclients^.value) then
      continue;
  end;
end;

(*
==================
SV_CheckTimeouts

If a packet has not been received from a client for timeout^.value
seconds, drop the conneciton.  Server frames are used instead of
realtime to aprocedure dropping the local client while debugging.

When a client is normally dropped, the client_t goes into a zombie state
for a few seconds to make sure any final reliable message gets resent
if necessary
==================
*)

procedure SV_CheckTimeouts();
var
  i: integer;
  cl: client_p;
  droppoint: integer;
  zombiepoint: integer;
begin
  droppoint := svs.realtime - Round(1000 * timeout^.value);
  zombiepoint := svs.realtime - Round(1000 * zombietime^.value);

  for i := 0 to round(maxclients^.value) - 1 do
  begin
    cl := @svs.clients^[i];
    // message times may be wrong across a changelevel
    if (cl^.lastmessage > svs.realtime) then
      cl^.lastmessage := svs.realtime;

    if (cl^.state = cs_zombie) and (cl^.lastmessage < zombiepoint) then
    begin
      cl^.state := cs_free;             // can now be reused
      continue;
    end;
    if ((cl^.state = cs_connected) or (cl^.state = cs_spawned)) and
      (cl^.lastmessage < droppoint) then
    begin
      SV_BroadcastPrintf(PRINT_HIGH, '%s timed out'#10, [cl^.name]);
      SV_DropClient(cl);
      cl^.state := cs_free;             // don't bother with zombie state
    end;
  end;
end;

(*
================
SV_PrepWorldFrame

This has to be done before the world logic, because
player processing happens outside RunWorldFrame
================
*)

procedure SV_PrepWorldFrame();
var
  ent: edict_p;
  i: integer;
begin
  for i := 0 to ge^.num_edicts - 1 do
  begin
    ent := EDICT_NUM(i);
    // events only last for a single message
    ent^.s.event := entity_event_t(0);
    Inc(ent);
  end;
end;

(*
=================
SV_RunGameFrame
=================
*)

procedure SV_RunGameFrame();
begin
  if (host_speeds^.value <> 0) then
    time_before_game := Sys_Milliseconds();

  // we always need to bump framenum, even if we
  // don't run the world, otherwise the delta
  // compression can get confused when a client
  // has the "current" frame
  Inc(sv.framenum);
  sv.time := sv.framenum * 100;

  // don't run if paused
  if (sv_paused^.value = 0) or (maxclients^.value > 1) then
  begin
    ge^.RunFrame();

    // never get more than one tic behind
    if (sv.time < svs.realtime) then
    begin
      if (sv_showclamp^.value <> 0) then
        Com_Printf('sv highclamp'#10);
      svs.realtime := sv.time;
    end;
  end;

  if (host_speeds^.value <> 0) then
    time_after_game := Sys_Milliseconds();
end;

(*
==================
SV_Frame

==================
*)

procedure SV_Frame(msec: integer);
begin
  time_before_game := 0;
  time_after_game := 0;

  // if server is not active, do nothing
  if (not svs.initialized) then
    exit;

  svs.realtime := svs.realtime + msec;

  // keep the random time dependent
  Random;

  // check timeouts
  SV_CheckTimeouts();

  // get packets from clients
  SV_ReadPackets();

  // move autonomous things around if enough time has passed
  if (sv_timedemo^.value = 0) and (svs.realtime < sv.time) then
  begin
    // never let the time get too far off
    if (sv.time - svs.realtime > 100) then
    begin
      if (sv_showclamp^.value <> 0) then
        Com_Printf('sv lowclamp'#10);
      svs.realtime := sv.time - 100;
    end;
    NET_Sleep(sv.time - svs.realtime);
    exit;
  end;

  // update ping based on the last known frame from all clients
  SV_CalcPings();

  // give the clients some timeslices
  SV_GiveMsec();

  // let everything in the world think and move
  SV_RunGameFrame();

  // send messages back to the clients that had packets read this frame
  SV_SendClientMessages();

  // save the entire world state if recording a serverdemo
  SV_RecordDemoMessage();

  // send a heartbeat to the master if needed
  Master_Heartbeat();

  // clear teleport flags, etc for next frame
  SV_PrepWorldFrame();

end;

//============================================================================

(*
================
Master_Heartbeat

Send a message to the master every few minutes to
let it know we are alive, and log information
================
*)

procedure Master_Heartbeat();
var
  string_: pchar;
  i: integer;
begin
  // pgm post3.19 change, cvar pointer not validated before dereferencing
  if (dedicated = nil) or (dedicated^.value = 0) then
    exit;                               // only dedicated servers send heartbeats

  // pgm post3.19 change, cvar pointer not validated before dereferencing
  if (public_server = nil) or (public_server^.value = 0) then
    exit;                               // a private dedicated game

  // check for time wraparound
  if (svs.last_heartbeat > svs.realtime) then
    svs.last_heartbeat := svs.realtime;

  if (svs.realtime - svs.last_heartbeat < HEARTBEAT_SECONDS * 1000) then
    exit;                               // not time to send yet

  svs.last_heartbeat := svs.realtime;

  // send the same string that we would give for a status OOB command
  string_ := SV_StatusString();

  // send to group master
  for i := 0 to MAX_MASTERS - 1 do
    if (master_adr[i].port <> 0) then
    begin
      Com_Printf('Sending heartbeat to %s'#10, [NET_AdrToString(master_adr[i])]);
      Netchan_OutOfBandPrint(NS_SERVER, master_adr[i], 'heartbeat'#10'%s', [string_]);
    end;
end;

(*
=================
Master_Shutdown

Informs all masters that this server is going down
=================
*)

procedure Master_Shutdown();
var
  i: integer;
begin
  // pgm post3.19 change, cvar pointer not validated before dereferencing
  if (dedicated = nil) or (dedicated^.value = 0) then
    exit;                               // only dedicated servers send heartbeats

  // pgm post3.19 change, cvar pointer not validated before dereferencing
  if (public_server = nil) or (public_server^.value = 0) then
    exit;                               // a private dedicated game

  // send to group master
  for i := 0 to MAX_MASTERS - 1 do
    if (master_adr[i].port <> 0) then
    begin
      if (i > 0) then
        Com_Printf('Sending heartbeat to %s'#10, [NET_AdrToString(master_adr[i])]);
      Netchan_OutOfBandPrint(NS_SERVER, master_adr[i], 'shutdown', []);
    end;
end;

//============================================================================

(*
=================
SV_UserinfoChanged

Pull specific info from a newly changed userinfo string
into a more C freindly form.
=================
*)

procedure SV_UserinfoChanged(cl: client_p);
var
  val: pchar;
  i: integer;
begin
  // call prog code to allow overrides
  ge^.ClientUserinfoChanged(cl^.edict, cl^.userinfo);

  // name for C code
  strncpy(cl^.name, Info_ValueForKey(cl^.userinfo, 'name'), sizeof(cl^.name) - 1);
  // mask off high bit
  for i := 0 to sizeof(cl^.name) - 1 do
    cl^.name[i] := char(byte(cl^.name[i]) and 127);

  // rate command
  val := Info_ValueForKey(cl^.userinfo, 'rate');
  if (strlen(val) <> 0) then
  begin
    i := StrToInt(val);
    cl^.rate := i;
    if (cl^.rate < 100) then
      cl^.rate := 100;
    if (cl^.rate > 15000) then
      cl^.rate := 15000;
  end
  else
    cl^.rate := 5000;

  // msg command
  val := Info_ValueForKey(cl^.userinfo, 'msg');
  if (strlen(val) <> 0) then
  begin
    cl^.messagelevel := StrToInt(val);
  end;

end;

//============================================================================

(*
===============
SV_Init

Only called at quake2.exe startup, not for each game
===============
*)

procedure SV_Init();
begin
  SV_InitOperatorCommands();

  rcon_password := Cvar_Get('rcon_password', '', 0);
  Cvar_Get('skill', '1', 0);
  Cvar_Get('deathmatch', '0', CVAR_LATCH);
  Cvar_Get('coop', '0', CVAR_LATCH);
  Cvar_Get('dmflags', va('%d', [DF_INSTANT_ITEMS]), CVAR_SERVERINFO);
  Cvar_Get('fraglimit', '0', CVAR_SERVERINFO);
  Cvar_Get('timelimit', '0', CVAR_SERVERINFO);
  Cvar_Get('cheats', '0', CVAR_SERVERINFO or CVAR_LATCH);
  Cvar_Get('protocol', va('%d', [PROTOCOL_VERSION]), CVAR_SERVERINFO or CVAR_NOSET);
  ;
  maxclients := Cvar_Get('maxclients', '1', CVAR_SERVERINFO or CVAR_LATCH);
  hostname := Cvar_Get('hostname', 'noname', CVAR_SERVERINFO or CVAR_ARCHIVE);
  timeout := Cvar_Get('timeout', '125', 0);
  zombietime := Cvar_Get('zombietime', '2', 0);
  sv_showclamp := Cvar_Get('showclamp', '0', 0);
  sv_paused := Cvar_Get('paused', '0', 0);
  sv_timedemo := Cvar_Get('timedemo', '0', 0);
  sv_enforcetime := Cvar_Get('sv_enforcetime', '0', 0);
  allow_download := Cvar_Get('allow_download', '1', CVAR_ARCHIVE);
  allow_download_players := Cvar_Get('allow_download_players', '0', CVAR_ARCHIVE);
  allow_download_models := Cvar_Get('allow_download_models', '1', CVAR_ARCHIVE);
  allow_download_sounds := Cvar_Get('allow_download_sounds', '1', CVAR_ARCHIVE);
  allow_download_maps := Cvar_Get('allow_download_maps', '1', CVAR_ARCHIVE);

  sv_noreload := Cvar_Get('sv_noreload', '0', 0);

  sv_airaccelerate := Cvar_Get('sv_airaccelerate', '0', CVAR_LATCH);

  public_server := Cvar_Get('public', '0', 0);

  sv_reconnect_limit := Cvar_Get('sv_reconnect_limit', '3', CVAR_ARCHIVE);

  SZ_Init(net_message, @net_message_buffer, sizeof(net_message_buffer));
end;

(*
==================
SV_FinalMessage

Used by SV_Shutdown to send a final message to all
connected clients before the server goes down.  The messages are sent immediately,
not just stuck on the outgoing message list, because the server is going
to totally exit after returning from this function.
==================
*)

procedure SV_FinalMessage(message_: pchar; reconnect: qboolean);
var
  i: integer;
  cl: client_p;
begin
  SZ_Clear(net_message);
  MSG_WriteByte(net_message, Integer(svc_print));
  MSG_WriteByte(net_message, PRINT_HIGH);
  MSG_WriteString(net_message, message_);

  if (reconnect) then
    MSG_WriteByte(net_message, Integer(svc_reconnect))
  else
    MSG_WriteByte(net_message, Integer(svc_disconnect));

  // send it twice
  // stagger the packets to crutch operating system limited buffers

  for i := 0 to round(maxclients^.value) - 1 do
  begin
    cl := @svs.clients^[i];
    if (cl^.state >= cs_connected) then
      Netchan_Transmit(cl^.netchan, net_message.cursize, PByte(net_message.data));
  end;

  for i := 0 to Round(maxclients^.value) - 1 do
  begin
    cl := @svs.clients^[i];
    if (cl^.state >= cs_connected) then
      Netchan_Transmit(cl^.netchan, net_message.cursize, PByte(net_message.data));
  end;
end;

(*
================
SV_Shutdown

Called when each game quits,
before Sys_Quit or Sys_Error
================
*)

procedure SV_Shutdown(finalmsg: pchar; reconnect: qboolean);
begin
  if (svs.clients <> nil) then
    SV_FinalMessage(finalmsg, reconnect);

  Master_Shutdown();
  SV_ShutdownGameProgs();

  // free current level
  if (sv.demofile > 0) then
    FileClose(sv.demofile);
  sv.demofile := 0;

  FillChar(sv, sizeof(sv), #0);
  Com_SetServerState(Integer(sv.state));

  // free server static data
  if (svs.clients <> nil) then
    Z_Free(svs.clients);
  if (svs.client_entities <> nil) then
    Z_Free(svs.client_entities);
  if (svs.demofile > 0) then
    FileClose(svs.demofile);
  FillChar(svs, sizeof(svs), 0);
end;

end.

