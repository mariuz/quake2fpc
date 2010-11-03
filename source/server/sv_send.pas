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
{ File(s):  server\sv_send.c                                                 }
{                                                                            }
{ Initial conversion by : Hierro (hierro86@libero.it)                        }
{ Initial conversion on : 09-Jan-2002                                        }
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

unit sv_send;

interface

uses
  Server,
  GameUnit,
  q_shared_add,
  q_shared;

procedure SV_Multicast(origin: vec3_p; to_: multicast_t); cdecl;
procedure SV_ClientPrintf(cl: client_p; level: integer; fmt: PChar; args: array of const);
procedure SV_BroadcastCommand(fmt: PChar; args: array of const);
procedure SV_SendClientMessages; cdecl;
procedure SV_StartSound(origin: vec3_p; entity: edict_p; channel: integer;
  soundindex: integer; volume: single;
  attenuation: single; timeofs: single); cdecl;
procedure SV_FlushRedirect(sv_redirected: integer; outputbuf: PChar);

procedure SV_BroadcastPrintf(level: integer; fmt: PChar; args: array of const);

var
  sv_outputbuf: array[0..SV_OUTPUTBUF_LENGTH - 1] of char;

implementation

uses
  SysUtils,
  game_add,
  Common,
  CModel,
  CPas,
  {$IFDEF WIN32}
  q_shwin,
  {$ELSE}
  q_shlinux,
  {$ENDIF}
  sv_main,
  sv_init,
  sv_ents,
  sv_user,
  net_chan;

(*
=============================================================================

Com_Printf redirection

=============================================================================
*)

procedure SV_FlushRedirect(sv_redirected: integer; outputbuf: PChar);
begin
  if (redirect_t(sv_redirected) = RD_PACKET) then
    Netchan_OutOfBandPrint(NS_SERVER, net_from, 'print'#10'%s', [outputbuf])
  else if (redirect_t(sv_redirected) = RD_CLIENT) then
  begin
    MSG_WriteByte(sv_client.netchan.message, Integer(svc_print));
    MSG_WriteByte(sv_client.netchan.message, PRINT_HIGH);
    MSG_WriteString(sv_client.netchan.message, outputbuf);
  end;
end;

(*
=============================================================================

EVENT MESSAGES

=============================================================================
*)

(*
=================
SV_ClientPrintf

Sends text across to be displayed if the level passes
=================
*)

procedure SV_ClientPrintf(cl: client_p; level: integer; fmt: PChar; args: array of const);
var
  msg: array[0..1023] of char;
begin
  if (level < cl.messagelevel) then
    exit;

  DelphiStrFmt(msg, fmt, args);

  MSG_WriteByte(cl.netchan.message, Integer(svc_print));
  MSG_WriteByte(cl.netchan.message, level);
  MSG_WriteString(cl.netchan.message, msg);
end;

(*
=================
SV_BroadcastPrintf

Sends text to all active clients
=================
*)

procedure SV_BroadcastPrintf(level: integer; fmt: PChar; args: array of const);
var
  string_: array[0..2048 - 1] of char;
  copy: array[0..1024 - 1] of char;
  cl: client_p;
  i: integer;
begin
  DelphiStrFmt(string_, fmt, args);

  // echo to console
  if (dedicated.value <> 0) then
  begin
    // mask off high bits
    i := 0;
    while (i < 1023) and (string_[i] <> #0) do
    begin
      copy[i] := Char(Byte(string_[i]) and 127);
      Inc(i);
    end;
    copy[i] := #0;
    Com_Printf('%s', [copy]);
  end;

  i := 0;
  cl := client_p(svs.clients);
  while i < maxclients^.value do
  begin
    if (level < cl^.messagelevel) then
    begin
      Inc(cl);
      Inc(i);
      Continue;
    end;
    if (cl^.state <> cs_spawned) then
    begin
      Inc(cl);
      Inc(i);
      Continue;
    end;
    MSG_WriteByte(cl^.netchan.message, Integer(svc_print));
    MSG_WriteByte(cl^.netchan.message, level);
    MSG_WriteString(cl^.netchan.message, string_);

    Inc(i);
    Inc(cl);
  end;
end;

(*
=================
SV_BroadcastCommand

Sends text to all active clients
=================
*)

procedure SV_BroadcastCommand(fmt: PChar; args: array of const);
var
  string_: array[0..1024 - 1] of char;
begin
  if (Integer(sv.state) = 0) then
    exit;

  DelphiStrFmt(string_, fmt, args);

  MSG_WriteByte(sv.multicast, Integer(svc_stufftext));
  MSG_WriteString(sv.multicast, string_);
  SV_Multicast(nil, MULTICAST_ALL_R);
end;

(*
=================
SV_Multicast

Sends the contents of sv.multicast to a subset of the clients,
then clears sv.multicast.

MULTICAST_ALL   same as broadcast (origin can be NULL)
MULTICAST_PVS   send to clients potentially visible from org
MULTICAST_PHS   send to clients potentially hearable from org
=================
*)

procedure SV_Multicast(origin: vec3_p; to_: multicast_t);
var
  client: client_p;
  mask: PByteArray;
  leafnum, cluster: integer;
  j: integer;
  reliable: boolean;
  area1, area2: integer;
begin
  reliable := False;

  if (to_ <> MULTICAST_ALL_R) and (to_ <> MULTICAST_ALL) then
  begin
    leafnum := CM_PointLeafnum(origin^);
    area1 := CM_LeafArea(leafnum);
  end
  else
  begin
    { Sly 12-Jul-2002 Not needed. Value assigned to 'leafnum' never used }
    //    leafnum := 0;   // just to avoid compiler warnings
    area1 := 0;
  end;

  // if doing a serverrecord, store everything
  if (svs.demofile > 0) then
    SZ_Write(svs.demo_multicast, sv.multicast.data, sv.multicast.cursize);

  case to_ of
    MULTICAST_ALL_R:
      begin
        reliable := true;               // intentional fallthrough
        { Sly 12-Jul-2002 Since Pascal does not allow fall-through, we must
          duplicate the code }
  { Sly 12-Jul-2002 Not needed. Value assigned to 'leafnum' never used }
  //      leafnum := 0;
        mask := nil;
      end;
    MULTICAST_ALL:
      begin
        { Sly 12-Jul-2002 Not needed. Value assigned to 'leafnum' never used }
        //      leafnum := 0;
        mask := nil;
      end;

    MULTICAST_PHS_R:
      begin
        reliable := true;               // intentional fallthrough
        { Sly 12-Jul-2002 Since Pascal does not allow fall-through, we must
          duplicate the code }
        leafnum := CM_PointLeafnum(origin^);
        cluster := CM_LeafCluster(leafnum);
        mask := PByteArray(CM_ClusterPHS(cluster));
      end;
    MULTICAST_PHS:
      begin
        leafnum := CM_PointLeafnum(origin^);
        cluster := CM_LeafCluster(leafnum);
        mask := PByteArray(CM_ClusterPHS(cluster));
      end;

    MULTICAST_PVS_R:
      begin
        reliable := true;               // intentional fallthrough
        { Sly 12-Jul-2002 Since Pascal does not allow fall-through, we must
          duplicate the code }
        leafnum := CM_PointLeafnum(origin^);
        cluster := CM_LeafCluster(leafnum);
        mask := PByteArray(CM_ClusterPVS(cluster));
      end;
    MULTICAST_PVS:
      begin
        leafnum := CM_PointLeafnum(origin^);
        cluster := CM_LeafCluster(leafnum);
        mask := PByteArray(CM_ClusterPVS(cluster));
      end;

  else
    begin
      mask := nil;
      Com_Error(ERR_FATAL, 'SV_Multicast: bad to:%i', [Integer(to_)]);
    end;
  end;

  // send the data to all relevent clients
  client := client_p(svs.clients);
  for j := 0 to Round(maxclients.value) - 1 do
  begin
    if (client.state = cs_free) or (client.state = cs_zombie) then
    begin
      inc(client);
      continue;
    end;
    if (client.state <> cs_spawned) and (not reliable) then
    begin
      inc(client);
      continue;
    end;

    if (mask <> nil) then
    begin
      leafnum := CM_PointLeafnum(client^.edict^.s.origin);
      cluster := CM_LeafCluster(leafnum);
      area2 := CM_LeafArea(leafnum);
      if (not CM_AreasConnected(area1, area2)) then
      begin
        inc(client);
        continue;
      end;
      if (mask <> nil) and (not (mask[cluster shr 3] and (1 shl (cluster and 7)) <> 0)) then
      begin
        inc(client);
        continue;
      end;
    end;

    if (reliable) then
      SZ_Write(client.netchan.message, sv.multicast.data, sv.multicast.cursize)
    else
      SZ_Write(client.datagram, sv.multicast.data, sv.multicast.cursize);

    inc(client);
  end;

  SZ_Clear(sv.multicast);
end;

(*
==================
SV_StartSound

Each entity can have eight independant sound sources, like voice,
weapon, feet, etc.

If cahnnel & 8, the sound will be sent to everyone, not just
things in the PHS.

FIXME: if entity isn't in PHS, they must be forced to be sent or
have the origin explicitly sent.

Channel 0 is an auto-allocate channel, the others override anything
already running on that entity/channel pair.

An attenuation of 0 will play full volume everywhere in the level.
Larger attenuations will drop off.  (max 4 attenuation)

Timeofs can range from 0.0 to 0.1 to cause sounds to be started
later in the frame than they normally would.

If origin is NULL, the origin is determined from the entity origin
or the midpoint of the entity box for bmodels.
==================
*)

procedure SV_StartSound(origin: vec3_p; entity: edict_p; channel: integer;
  soundindex: integer; volume: single;
  attenuation: single; timeofs: single);
var
  sendchan: integer;
  flags: integer;
  i: integer;
  ent: integer;
  origin_v: vec3_t;
  use_phs: boolean;
begin
  if (volume < 0) or (volume > 1.0) then
    Com_Error(ERR_FATAL, 'SV_StartSound: volume = %f', [volume]);

  if (attenuation < 0) or (attenuation > 4) then
    Com_Error(ERR_FATAL, 'SV_StartSound: attenuation = %f', [attenuation]);

  //   if (channel < 0 || channel > 15)
  //      Com_Error (ERR_FATAL, "SV_StartSound: channel = %i", channel);

  if (timeofs < 0) or (timeofs > 0.255) then
    Com_Error(ERR_FATAL, 'SV_StartSound: timeofs = %f', [timeofs]);

  ent := NUM_FOR_EDICT(entity);

  if (channel and 8 <> 0) then          // no PHS flag
  begin
    use_phs := false;
    channel := channel and 7;
  end
  else
    use_phs := true;

  sendchan := (ent shl 3) or (channel and 7);

  flags := 0;
  if (volume <> DEFAULT_SOUND_PACKET_VOLUME) then
    flags := flags or SND_VOLUME;
  if (attenuation <> DEFAULT_SOUND_PACKET_ATTENUATION) then
    flags := flags or SND_ATTENUATION;

  // the client doesn't know that bmodels have weird origins
  // the origin can also be explicitly set
  if ((entity^.svflags and SVF_NOCLIENT <> 0) or (entity^.solid = SOLID_BSP) or (origin <> nil)) then
    flags := flags or SND_POS;

  // always send the entity number for channel overrides
  flags := flags or SND_ENT;

  if (timeofs <> 0) then
    flags := flags or SND_OFFSET;

  // use the entity origin unless it is a bmodel or explicitly specified
  if (origin = nil) then
  begin
    origin := @origin_v;
    if (entity.solid = SOLID_BSP) then
      for i := 0 to 2 do
        origin_v[i] := entity^.s.origin[i] + 0.5 * (entity^.mins[i] + entity^.maxs[i])
    else
      VectorCopy(entity^.s.origin, origin_v);
  end;

  MSG_WriteByte(sv.multicast, Integer(svc_sound));
  MSG_WriteByte(sv.multicast, flags);
  MSG_WriteByte(sv.multicast, soundindex);

  if (flags and SND_VOLUME <> 0) then
    MSG_WriteByte(sv.multicast, Round(volume * 255));
  if (flags and SND_ATTENUATION <> 0) then
    MSG_WriteByte(sv.multicast, Round(attenuation * 64));
  if (flags and SND_OFFSET <> 0) then
    MSG_WriteByte(sv.multicast, Round(timeofs * 1000));

  if (flags and SND_ENT <> 0) then
    MSG_WriteShort(sv.multicast, sendchan);

  if (flags and SND_POS <> 0) then
    MSG_WritePos(sv.multicast, origin^);

  // if the sound doesn't attenuate,send it to everyone
  // (global radio chatter, voiceovers, etc)
  if (attenuation = ATTN_NONE) then
    use_phs := false;

  if (channel and CHAN_RELIABLE <> 0) then
  begin
    if (use_phs) then
      SV_Multicast(origin, MULTICAST_PHS_R)
    else
      SV_Multicast(origin, MULTICAST_ALL_R);
  end
  else
  begin
    if (use_phs) then
      SV_Multicast(origin, MULTICAST_PHS)
    else
      SV_Multicast(origin, MULTICAST_ALL);
  end;
end;

(*
===============================================================================

FRAME UPDATES

===============================================================================
*)

(*
=======================
SV_SendClientDatagram
=======================
*)

function SV_SendClientDatagram(client: client_p): qboolean;
var
  msg_buf: array[0..MAX_MSGLEN - 1] of byte;
  msg: sizebuf_t;
begin
  SV_BuildClientFrame(client);

  SZ_Init(msg, @msg_buf, sizeof(msg_buf));
  msg.allowoverflow := true;

  // send over all the relevant entity_state_t
  // and the player_state_t
  SV_WriteFrameToClient(client, @msg);

  // copy the accumulated multicast datagram
  // for this client out to the message
  // it is necessary for this to be after the WriteEntities
  // so that entity references will be current
  if (client^.datagram.overflowed) then
    Com_Printf('WARNING: datagram overflowed for %s'#10, [client^.name])
  else
    SZ_Write(msg, client.datagram.data, client.datagram.cursize);
  SZ_Clear(client.datagram);

  if (msg.overflowed) then
  begin
    // must have room left for the packet header
    Com_Printf('WARNING: msg overflowed for %s'#10, [client.name]);
    SZ_Clear(msg);
  end;

  // send the datagram
  Netchan_Transmit(client.netchan, msg.cursize, PByte(msg.data));

  // record the size for rate estimation
  client^.message_size[sv.framenum mod RATE_MESSAGES] := msg.cursize;

  Result := True;
end;

(*
==================
SV_DemoCompleted
==================
*)

procedure SV_DemoCompleted;
begin
  if (sv.demofile > 0) then
  begin
    FileClose(sv.demofile);
    sv.demofile := 0;
  end;
  SV_Nextserver;
end;

(*
=======================
SV_RateDrop

Returns true if the client is over its current
bandwidth estimation and should not be sent another packet
=======================
*)

function SV_RateDrop(c: client_p): boolean;
var
  total: integer;
  i: integer;
begin
  // never drop over the loopback
  if (c.netchan.remote_address.type_ = NA_LOOPBACK) then
  begin
    Result := False;
    exit;
  end;

  total := 0;

  for i := 0 to RATE_MESSAGES - 1 do
    inc(total, c^.message_size[i]);

  if (total > c^.rate) then
  begin
    c^.surpressCount := c^.surpressCount + 1;
    c^.message_size[sv.framenum mod RATE_MESSAGES] := 0;
    Result := True;
    exit;
  end;

  Result := False;
end;

(*
=======================
SV_SendClientMessages
=======================
*)

procedure SV_SendClientMessages;
var
  i: integer;
  c: client_p;
  msglen: integer;
  msgbuf: array[0..MAX_MSGLEN - 1] of byte;
  r: integer;
begin
  msglen := 0;

  // read the next demo message if needed
  if (sv.state = ss_demo) and (sv.demofile > 0) then
  begin
    if (sv_paused.value <> 0) then
      msglen := 0
    else
    begin
      // get the next message
      r := FileRead(sv.demofile, msglen, 4);
      if (r <> 4) then
      begin
        SV_DemoCompleted;
        exit;
      end;
      msglen := LittleLong(msglen);
      if (msglen = -1) then
      begin
        SV_DemoCompleted;
        exit;
      end;
      if (msglen > MAX_MSGLEN) then
        Com_Error(ERR_DROP, 'SV_SendClientMessages: msglen > MAX_MSGLEN', []);
      r := FileRead(sv.demofile, msgbuf, msglen);
      if (r <> msglen) then
      begin
        SV_DemoCompleted;
        exit;
      end;
    end;
  end;

  // send a message to each connected client
  c := client_p(svs.clients);
  for i := 0 to Round(maxclients.value - 1) do
  begin
    if (Integer(c^.state) = 0) then
    begin
      inc(c);
      continue;
    end;
    // if the reliable message overflowed,
    // drop the client
    if (c^.netchan.message.overflowed) then
    begin
      SZ_Clear(c^.netchan.message);
      SZ_Clear(c^.datagram);
      SV_BroadcastPrintf(PRINT_HIGH, '%s overflowed'#10, [c^.name]);
      SV_DropClient(c);
    end;

    if (sv.state = ss_cinematic) or (sv.state = ss_demo) or (sv.state = ss_pic) then
      Netchan_Transmit(c^.netchan, msglen, @msgbuf)
    else if (c^.state = cs_spawned) then
    begin
      // don't overrun bandwidth
      if (SV_RateDrop(c)) then
      begin
        inc(c);
        continue;
      end;

      SV_SendClientDatagram(c);
    end
    else
    begin
      // just update reliable if needed
      if (c^.netchan.message.cursize <> 0) or (curtime - c^.netchan.last_sent > 1000) then
        Netchan_Transmit(c.netchan, 0, nil);
    end;
    inc(c);
  end;
end;

end.
