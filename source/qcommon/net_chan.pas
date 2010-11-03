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
{ File(s): qcommon.h (part), net_chan.c                                      }
{ Content: Quake2\QCommon\ net chaining                                      }
{                                                                            }
{ Initial conversion by : Clootie (Alexey Barkovoy) - clootie@reactor.ru     }
{ Initial conversion on : 15-Jan-2002                                        }
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
{$IFDEF WIN32}
{$INCLUDE ..\JEDI.inc}
{$ELSE}
{$INCLUDE ../Jedi.inc}
{$ENDIF}

unit net_chan;

interface

uses
  Q_Shared,
  Common
  {$IFNDEF COMPILER6_UP}
  {$IFDEF WIN32}
  ,Windows
  {$ENDIF}
  {$ENDIF};

{*

packet header
-------------
31   sequence
1   does this message contain a reliable payload
31   acknowledge sequence
1   acknowledge receipt of even/odd message
16   qport

The remote connection never knows if it missed a reliable message, the
local side detects that it has been dropped by seeing a sequence acknowledge
higher thatn the last reliable sequence, but without the correct evon/odd
bit for the reliable set.

If the sender notices that a reliable message has been dropped, it will be
retransmitted.  It will not be retransmitted again until a message after
the retransmit has been acknowledged and the reliable still failed to get there.

if the sequence number is -1, the packet should be handled without a netcon

The reliable message can be added to at any time by doing
MSG_Write* (&netchan->message, <data>).

If the message buffer is overflowed, either by a single message, or by
multiple frames worth piling up while the last reliable transmit goes
unacknowledged, the netchan signals a fatal error.

Reliable messages are always placed first in a packet, then the unreliable
message is included if there is sufficient room.

To the receiver, there is no distinction between the reliable and unreliable
parts of the message, they are just processed out as a single larger message.

Illogical packet sequence numbers cause the packet to be dropped, but do
not kill the connection.  This, combined with the tight window of valid
reliable acknowledgement numbers provides protection against malicious
address spoofing.

The qport field is a workaround for bad address translating routers that
sometimes remap the client's source port on a packet during gameplay.

If the base part of the net address matches and the qport matches, then the
channel matches even if the IP port differs.  The IP port should be updated
to the new value before sending out any replies.

If there is no information that needs to be transfered on a given frame,
such as during the connection stage while waiting for the client to load,
then a packet only needs to be delivered if there is something in the
unacknowledged reliable
*}

var
  net_from: netadr_t;
  net_message: sizebuf_t;
  net_message_buffer: array[0..MAX_MSGLEN - 1] of Byte;

procedure Netchan_Init;
procedure Netchan_Setup(sock: netsrc_t; chan: netchan_p; adr: netadr_t; qport: Integer);

function Netchan_NeedReliable(const chan: netchan_t): qboolean;
procedure Netchan_Transmit(var chan: netchan_t; length_: Integer; data: PByte);
procedure Netchan_OutOfBand(net_socket: netsrc_t; const adr: netadr_t; length_: Integer; data: PByte);
procedure Netchan_OutOfBandPrint(net_socket: netsrc_t; const adr: netadr_t; format_: pchar; args: array of const);
function Netchan_Process(var chan: netchan_t; var msg: sizebuf_t): qboolean;

function Netchan_CanReliable(const chan: netchan_t): qboolean;

implementation

uses
  SysUtils,
  CVar
{$IFDEF WIN32}
  ,net_wins
  ,q_shwin
{$ENDIF}
{$IFDEF LINUX}
  ,net_udp
  ,q_shlinux
{$ENDIF}
  ;

var
  showpackets: cvar_p;
  showdrop: cvar_p;
  qport: cvar_p;

{*
===============
Netchan_Init

===============
*}
procedure Netchan_Init;
var
  port: Integer;
begin
  // pick a port value that should be nice and random
  port := Sys_Milliseconds and $FFFF;

  showpackets := Cvar_Get('showpackets', '0', 0);
  showdrop := Cvar_Get('showdrop', '0', 0);
  qport := Cvar_Get('qport', va('%d', [port]), CVAR_NOSET);
end;

{*
===============
Netchan_OutOfBand

Sends an out-of-band datagram
================
*}
procedure Netchan_OutOfBand(net_socket: netsrc_t; const adr: netadr_t; length_: Integer; data: PByte);
var
  send: sizebuf_t;
  send_buf: array[0..MAX_MSGLEN - 1] of Byte;
begin
  // write the packet header
  SZ_Init(send, @send_buf, SizeOf(send_buf));

  MSG_WriteLong(send, -1);              // -1 sequence means out of band
  SZ_Write(send, data, length_);

  // send the datagram
  NET_SendPacket(net_socket, send.cursize, send.data, adr);
end;

{*
===============
Netchan_OutOfBandPrint

Sends a text message in an out-of-band datagram
================
*}
procedure Netchan_OutOfBandPrint(net_socket: netsrc_t; const adr: netadr_t; format_: pchar; args: array of const);
{$IFDEF COMPILER6_UP}{$WRITEABLECONST ON}{$ENDIF}
const
  string_: array[0..MAX_MSGLEN - 5] of Char = #0;
{$IFDEF COMPILER6_UP}{$WRITEABLECONST OFF}{$ENDIF}
begin
  DelphiStrFmt(string_, format_, args);
  Netchan_OutOfBand(net_socket, adr, StrLen(string_), PByte(@string_[0]));
end;

{*
==============
Netchan_Setup

called to open a channel to a remote system
==============
*}
procedure Netchan_Setup(sock: netsrc_t; chan: netchan_p; adr: netadr_t; qport: Integer);
begin
  FillChar(chan^, SizeOf(chan^), 0);

  chan.sock := sock;
  chan.remote_address := adr;
  chan.qport := qport;
  chan.last_received := curtime;
  chan.incoming_sequence := 0;
  chan.outgoing_sequence := 1;

  SZ_Init(chan.message, @chan.message_buf, SizeOf(chan.message_buf));
  chan.message.allowoverflow := True;
end;

{*
===============
Netchan_CanReliable

Returns true if the last reliable message has acked
================
*}
function Netchan_CanReliable(const chan: netchan_t): qboolean;
begin
  // (chan.reliable_length <> 0) - equal to - // waiting for ack
  Result := (chan.reliable_length = 0);
end;

function Netchan_NeedReliable(const chan: netchan_t): qboolean;
var
  send_reliable: qboolean;
begin
  // if the remote side dropped the last reliable message, resend it
  send_reliable := false;

  if (chan.incoming_acknowledged > chan.last_reliable_sequence) and
    (chan.incoming_reliable_acknowledged <> chan.reliable_sequence) then
    send_reliable := True;

  // if the reliable transmit buffer is empty, copy the current message out
  if (chan.reliable_length = 0) and (chan.message.cursize <> 0) then
  begin
    send_reliable := True;
  end;

  Result := send_reliable;
end;

{*
===============
Netchan_Transmit

tries to send an unreliable message to a connection, and handles the
transmition / retransmition of the reliable messages.

A 0 length will still generate a packet and deal with the reliable messages.
================
*}
procedure Netchan_Transmit(var chan: netchan_t; length_: Integer; data: PByte);
var
  send: sizebuf_t;
  send_buf: array[0..MAX_MSGLEN - 1] of Byte;
  send_reliable: qboolean;
  w1, w2: Cardinal;
begin
  // check for message overflow
  if chan.message.overflowed then
  begin
    chan.fatal_error := True;
    Com_Printf('%s:Outgoing message overflow'#10, [NET_AdrToString(chan.remote_address)]);
    Exit;
  end;

  send_reliable := Netchan_NeedReliable(chan);

  if (chan.reliable_length = 0) and (chan.message.cursize <> 0) then
  begin
    Move(chan.message_buf, chan.reliable_buf, chan.message.cursize);
    chan.reliable_length := chan.message.cursize;
    chan.message.cursize := 0;
    chan.reliable_sequence := chan.reliable_sequence xor 1;
  end;

  // write the packet header
  SZ_Init(send, @send_buf, SizeOf(send_buf));

  w1 := (Cardinal(chan.outgoing_sequence) and not (1 shl 31)) or (Cardinal(send_reliable) shl 31);
  w2 := (Cardinal(chan.incoming_sequence) and not (1 shl 31)) or (Cardinal(chan.incoming_reliable_sequence shl 31));

  Inc(chan.outgoing_sequence);
  chan.last_sent := curtime;

  MSG_WriteLong(send, Integer(w1));
  MSG_WriteLong(send, Integer(w2));

  // send the qport if we are a client
  if (chan.sock = NS_CLIENT) then
    MSG_WriteShort(send, Round(qport.value));

  // copy the reliable message to the packet first
  if (send_reliable) then
  begin
    SZ_Write(send, @chan.reliable_buf, chan.reliable_length);
    chan.last_reliable_sequence := chan.outgoing_sequence;
  end;

  // add the unreliable part if space is available
  if (send.maxsize - send.cursize >= length_) then
    SZ_Write(send, data, length_)
  else
    Com_Printf('Netchan_Transmit: dumped unreliable'#10, ['']);

  // send the datagram
  NET_SendPacket(chan.sock, send.cursize, send.data, chan.remote_address);

  if (showpackets.value <> 0) then
  begin
    if (send_reliable) then
      Com_Printf('send %4d : s=%d reliable=%d ack=%d rack=%d'#10,
        [send.cursize,
        chan.outgoing_sequence - 1,
          chan.reliable_sequence,
          chan.incoming_sequence,
          chan.incoming_reliable_sequence])
    else
      Com_Printf('send %4d : s=%d ack=%d rack=%d'#10,
        [send.cursize,
        chan.outgoing_sequence - 1,
          chan.incoming_sequence,
          chan.incoming_reliable_sequence]);
  end;
end;

{*
=================
Netchan_Process

called when the current net_message is from remote_address
modifies net_message so that it points to the packet payload
=================
*}
function Netchan_Process(var chan: netchan_t; var msg: sizebuf_t): qboolean;
var
  sequence: Integer;                    //Clootie: changed due to compiler warnings
  sequence_ack: Cardinal;
  reliable_ack: Integer;                //Clootie: changed due to compiler warnings
  reliable_message: Cardinal;
  // qport: Integer; //Clootie: qport is never used
begin
  // get sequence numbers
  MSG_BeginReading(msg);
  sequence := MSG_ReadLong(msg);
  sequence_ack := Cardinal(MSG_ReadLong(msg));

  // read the qport if we are a server
  if (chan.sock = NS_SERVER) then
    {qport := } MSG_ReadShort(msg);     //Clootie: qport is never used

  reliable_message := sequence shr 31;
  reliable_ack := sequence_ack shr 31;

  sequence := sequence and not (1 shl 31);
  sequence_ack := sequence_ack and not (1 shl 31);

  if (showpackets.value <> 0) then
  begin
    if (reliable_message <> 0) then
      Com_Printf('recv %4d : s=%d reliable=%d ack=%d rack=%d'#10,
        [msg.cursize,
        sequence,
          chan.incoming_reliable_sequence xor 1,
          sequence_ack,
          reliable_ack])
    else
      Com_Printf('recv %4d : s=%d ack=%d rack=%d'#10,
        [msg.cursize,
        sequence,
          sequence_ack,
          reliable_ack]);
  end;

  //
  // discard stale or duplicated packets
  //
  if (sequence <= chan.incoming_sequence) then
  begin
    if (showdrop.value <> 0) then
      Com_Printf('%s:Out of order packet %d at %d'#10,
        [NET_AdrToString(chan.remote_address),
        sequence,
          chan.incoming_sequence]);
    Result := False;
    Exit;
  end;

  //
  // dropped packets don't keep the message from being used
  //
  chan.dropped := sequence - (chan.incoming_sequence + 1);
  if (chan.dropped > 0) then
  begin
    if (showdrop.value <> 0) then
      Com_Printf('%s:Dropped %d packets at %d'#10,
        [NET_AdrToString(chan.remote_address),
        chan.dropped,
          sequence]);
  end;

  //
  // if the current outgoing reliable message has been acknowledged
  // clear the buffer to make way for the next
  //
  if (reliable_ack = chan.reliable_sequence) then
    chan.reliable_length := 0;          // it has been received

  //
  // if this message contains a reliable message, bump incoming_reliable_sequence
  //
  chan.incoming_sequence := sequence;
  chan.incoming_acknowledged := sequence_ack;
  chan.incoming_reliable_acknowledged := reliable_ack;
  if (reliable_message <> 0) then
  begin
    chan.incoming_reliable_sequence := chan.incoming_reliable_sequence xor 1;
  end;

  //
  // the message can now be read from the current message pointer
  //
  chan.last_received := curtime;

  Result := True;
end;

end.
