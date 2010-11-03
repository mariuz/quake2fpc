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
{ File(s): QCommon.h (part), net_wins.c                                      }
{ Content: Quake2\QCommon\ network routines implementation (PLATFORM)        }
{                                                                            }
{ Initial conversion by : Clootie (Alexey Barkovoy) - clootie@reactor.ru     }
{ Initial conversion on : 27-Jan-2002                                        }
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
{ 1) 25-Feb-2002 - Clootie (clootie@reactor.ru)                              }
{    Now all external dependencies are cleaned up.                           }
{                                                                            }
{ 2) 17-Jul-2002 - Sly (stevewilliams@kromestudios.com)                      }
{    Optionally removed dependency on "JEDI Expanded Win32 API translation"  }
{----------------------------------------------------------------------------}
{ * Notes: (Clootie)                                                         }
{ To compile this unit requires "JEDI Expanded Win32 API translation"        }
{ available at:  http://www.delphi-jedi.org/Jedi:APILIBRARY:36949            }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{   NONE                                                                     }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{----------------------------------------------------------------------------}

unit net_wins;

{ Define USE_JWA to use the JEDI Expanded Win32 API translation headers }
{.$DEFINE USE_JWA}

{$INCLUDE ..\JEDI.inc}

interface

uses
{$IFDEF USE_JWA}
  JwaWinSock,
{$ELSE}
  WinSock,
{$ENDIF}
  Q_Shared,
  Common;

{$IFNDEF USE_JWA}
type
  sockaddr = TSockAddr;
{$ENDIF}


procedure NET_Init;
procedure NET_Shutdown;

procedure NET_Config(multiplayer: qboolean);

function NET_GetPacket(sock: netsrc_t; var net_from: netadr_t; var net_message: sizebuf_t): qboolean;
procedure NET_SendPacket(sock: netsrc_t; length: Integer; data: Pointer; const to_: netadr_t);

function NET_CompareAdr(const a, b: netadr_t): qboolean;
function NET_CompareBaseAdr(const a, b: netadr_t): qboolean;
function NET_IsLocalAddress(const adr: netadr_t): qboolean;
function NET_AdrToString(const a: netadr_t): PChar;
function NET_StringToSockaddr(s: PChar; var sadr: sockaddr): qboolean;
procedure NET_Sleep(msec: Integer);
function NET_StringToAdr(s: PChar; var a: netadr_t): qboolean;

implementation

uses
  SysUtils,
  Windows,
{$IFDEF USE_JWA}
  JwaWSipx,
{$ENDIF}
  CVar;

const
  MAX_LOOPBACK = 4;

type
  loopmsg_p = ^loopmsg_t;
  loopmsg_t = record
    data: array[0..MAX_MSGLEN - 1] of Byte;
    datalen: Integer;
  end;

  loopback_p = ^loopback_t;
  loopback_t = record
    msgs: array[0..MAX_LOOPBACK - 1] of loopmsg_t;
    get, send: Integer;
  end;

{$IFNDEF USE_JWA}
const
  NSPROTO_IPX = 1000;

type
  sockaddr_ipx = record
    sa_family: Smallint;
    sa_netnum: array[0..3] of Char;
    sa_nodenum: array[0..5] of Char;
    sa_socket: Word;
  end;
  TSockAddrIPX = sockaddr_ipx;
  PSockAddrIPX = ^sockaddr_ipx;
{$ENDIF}

var
  net_shownet: cvar_p;
  noudp: cvar_p;                        // static
  noipx: cvar_p;                        // static

  loopbacks: array[NS_CLIENT..NS_SERVER] of loopback_t;
  ip_sockets: array[NS_CLIENT..NS_SERVER] of Integer;
  ipx_sockets: array[NS_CLIENT..NS_SERVER] of Integer;

function NET_ErrorString: PChar; forward;

//=============================================================================

procedure NetadrToSockadr(const a: netadr_t; var s: TSockAddr);
type
  Pu_long = ^u_long;
begin
  FillChar(s, SizeOf(s), 0);

  if (a.type_ = NA_BROADCAST) then
  begin
    sockaddr_in(s).sin_family := AF_INET;
    sockaddr_in(s).sin_port := a.port;
    sockaddr_in(s).sin_addr.s_addr := INADDR_BROADCAST;
  end
  else if (a.type_ = NA_IP) then
  begin
    sockaddr_in(s).sin_family := AF_INET;
    sockaddr_in(s).sin_addr.s_addr := Pu_long(@a.ip)^;
    sockaddr_in(s).sin_port := a.port;
  end
  else if (a.type_ = NA_IPX) then
  begin
    PSockAddrIPX(@s).sa_family := AF_IPX;
    Move(a.ipx[0], PSockAddrIPX(@s).sa_netnum, 4);
    Move(a.ipx[4], PSockAddrIPX(@s).sa_nodenum, 6);
    PSockAddrIPX(@s).sa_socket := a.port;
  end
  else if (a.type_ = NA_BROADCAST_IPX) then
  begin
    PSockAddrIPX(@s).sa_family := AF_IPX;
    FillChar(PSockAddrIPX(@s).sa_netnum, 4, 0);
    FillChar(PSockAddrIPX(@s).sa_nodenum, 6, $FF);
    PSockAddrIPX(@s).sa_socket := a.port;
  end;
end;

procedure SockadrToNetadr(const s: sockaddr; var a: netadr_t);
begin
  if (s.sa_family = AF_INET) then
  begin
    a.type_ := NA_IP;
    PInteger(@a.ip)^ := sockaddr_in(s).sin_addr.s_addr;
    a.port := sockaddr_in(s).sin_port;
  end
  else if (s.sa_family = AF_IPX) then
  begin
    a.type_ := NA_IPX;
    Move(PSockAddrIPX(@s).sa_netnum, a.ipx[0], 4);
    Move(PSockAddrIPX(@s).sa_nodenum, a.ipx[4], 6);
    a.port := PSockAddrIPX(@s).sa_socket;
  end;
end;

function NET_CompareAdr(const a, b: netadr_t): qboolean;
begin
  Result := (a.type_ = b.type_);
  if not Result then
    Exit;

  if (a.type_ = NA_LOOPBACK) then
  begin
    Result := True;
    Exit;
  end;

  if (a.type_ = NA_IP) then
  begin
    if (a.ip[0] = b.ip[0]) and (a.ip[1] = b.ip[1]) and
      (a.ip[2] = b.ip[2]) and (a.ip[3] = b.ip[3]) and (a.port = b.port) then
    begin
      Result := True;
      Exit;
    end;
    Result := False;
    Exit;
  end;

  if (a.type_ = NA_IPX) then
  begin
    if CompareMem(@a.ipx, @b.ipx, 10) and (a.port = b.port) then
    begin
      Result := True;
      Exit;
    end;
    Result := False;
  end;
end;

{*
===================
NET_CompareBaseAdr

Compares without the port
===================
*}
function NET_CompareBaseAdr(const a, b: netadr_t): qboolean;
begin
  if (a.type_ <> b.type_) then
  begin
    Result := False;
    Exit;
  end;

  if (a.type_ = NA_LOOPBACK) then
  begin
    Result := True;
    Exit;
  end;

  if (a.type_ = NA_IP) then
  begin
    if (a.ip[0] = b.ip[0]) and (a.ip[1] = b.ip[1]) and
      (a.ip[2] = b.ip[2]) and (a.ip[3] = b.ip[3]) then
    begin
      Result := True;
      Exit;
    end;
    Result := False;
    Exit;
  end;

  if (a.type_ = NA_IPX) then
  begin
    if CompareMem(@a.ipx, @b.ipx, 10) then
    begin
      Result := True;
      Exit;
    end;
    Result := False;
    Exit;
  end;

  Result := False;
end;

function NET_AdrToString(const a: netadr_t): PChar;
{$IFDEF COMPILER6_UP}{$WRITEABLECONST ON}{$ENDIF}
const
  s: array[0..63] of Char = '';
  recursive: qboolean = False;
{$IFDEF COMPILER6_UP}{$WRITEABLECONST OFF}{$ENDIF}
begin
  if (a.type_ = NA_LOOPBACK) then
    Com_sprintf(s, SizeOf(s), 'loopback', [''])
  else if (a.type_ = NA_IP) then
    Com_sprintf(s, SizeOf(s), '%d.%d.%d.%d:%d', [a.ip[0], a.ip[1], a.ip[2], a.ip[3], ntohs(a.port)])
  else
    Com_sprintf(s, SizeOf(s), '%02x%02x%02x%02x:%02x%02x%02x%02x%02x%02x:%d',
      [a.ipx[0], a.ipx[1], a.ipx[2], a.ipx[3], a.ipx[4],
      a.ipx[5], a.ipx[6], a.ipx[7], a.ipx[8], a.ipx[9], ntohs(a.port)]);

  Result := s;
end;

{*
=============
NET_StringToAdr

localhost
idnewt
idnewt:28000
192.246.40.70
192.246.40.70:28000
=============
*}
function NET_StringToSockaddr(s: PChar; var sadr: sockaddr): qboolean;
type
  PCharArray = ^TCharArray;
  TCharArray = array[0..MaxInt div SizeOf(Char) - 1] of Char;
var
  copy: array[0..127] of Char;
  val: Integer;

  {#define DO(src,dest)   \
  copy[0] = s[src];   \
  copy[1] = s[src + 1];   \
  sscanf (copy, "%x", &val);   \
  ((struct sockaddr_ipx * )sadr)->dest = val}
  procedure DoIt(src: Integer; var dest: Char);
  begin
    copy[0] := s[src];
    copy[1] := s[src + 1];
    // sscanf (copy, "%x", &val);
    val := StrToInt(copy);
    dest := Chr(val);
  end;

{$IFNDEF COMPILER6_UP}
type
  PCardinal = ^Cardinal;
{$ENDIF}
var
  h: PHostEnt;
  colon: PChar;
begin
  FillChar(sadr, SizeOf(sadr), 0);

  if (StrLen(s) >= 23) and (PCharArray(s)[8] = ':') and (PCharArray(s)[21] = ':') then // check for an IPX address
  begin
    PSockAddrIPX(@sadr).sa_family := AF_IPX;
    copy[2] := #0;
    DOit(0, PSockAddrIPX(@sadr).sa_netnum[0]);
    DOit(2, PSockAddrIPX(@sadr).sa_netnum[1]);
    DOit(4, PSockAddrIPX(@sadr).sa_netnum[2]);
    DOit(6, PSockAddrIPX(@sadr).sa_netnum[3]);
    DOit(9, PSockAddrIPX(@sadr).sa_nodenum[0]);
    DOit(11, PSockAddrIPX(@sadr).sa_nodenum[1]);
    DOit(13, PSockAddrIPX(@sadr).sa_nodenum[2]);
    DOit(15, PSockAddrIPX(@sadr).sa_nodenum[3]);
    DOit(17, PSockAddrIPX(@sadr).sa_nodenum[4]);
    DOit(19, PSockAddrIPX(@sadr).sa_nodenum[5]);
    // sscanf (&s[22], "%u", &val);
    val := StrToInt(PChar(@s[22]));
    PSockAddrIPX(@sadr).sa_socket := htons(val);
  end
  else
  begin
    PSockAddrIn(@sadr).sin_family := AF_INET;

    PSockAddrIn(@sadr).sin_port := 0;

    StrCopy(copy, s);
    // strip off a trailing :port if present
    // for (colon = copy ; *colon ; colon++)
    colon := copy;
    while (colon^ <> #0) do
    begin
      if (colon^ = ':') then
      begin
        colon^ := #0;
        PSockAddrIn(@sadr).sin_port := htons(StrToInt(colon + 1));
      end;
      Inc(colon);
    end;

    if (copy[0] >= '0') and (copy[0] <= '9') then
    begin
      // *(int *}&((struct sockaddr_in *}sadr)->
      PCardinal(@(PSockAddrIn(@sadr).sin_addr))^ := inet_addr(copy);
    end
    else
    begin
      h := gethostbyname(copy);
      if (h = nil) then
      begin
        Result := False;
        Exit;
      end;
      Cardinal(PSockAddrIn(@sadr).sin_addr) := PCardinal(@h.h_addr_list^^)^;
    end;
  end;

  Result := true;
end;

{*
=============
NET_StringToAdr

localhost
idnewt
idnewt:28000
192.246.40.70
192.246.40.70:28000
=============
*}
function NET_StringToAdr(s: PChar; var a: netadr_t): qboolean;
var
  sadr: sockaddr;
begin
  if (StrComp(s, 'localhost') = 0) then
  begin
    FillChar(a, SizeOf(a), 0);
    a.type_ := NA_LOOPBACK;
    Result := True;
    Exit;
  end;

  if not NET_StringToSockaddr(s, sadr) then
  begin
    Result := false;
    Exit;
  end;

  SockadrToNetadr(sadr, a);

  Result := True;
end;

function NET_IsLocalAddress(const adr: netadr_t): qboolean;
begin
  Result := (adr.type_ = NA_LOOPBACK);
end;

{*
=============================================================================

LOOPBACK BUFFERS FOR LOCAL PLAYER

=============================================================================
*}

function NET_GetLoopPacket(sock: netsrc_t; var net_from: netadr_t;
  var net_message: sizebuf_t): qboolean;
var
  i: Integer;
  loop: loopback_p;
begin
  loop := @loopbacks[sock];

  if (loop.send - loop.get > MAX_LOOPBACK) then
    loop.get := loop.send - MAX_LOOPBACK;

  if (loop.get >= loop.send) then
  begin
    Result := false;
    Exit;
  end;

  i := loop.get and (MAX_LOOPBACK - 1);
  Inc(loop.get);

  // memcpy (net_message->data, loop->msgs[i].data, loop->msgs[i].datalen);
  Move(loop.msgs[i].data, net_message.data^, loop.msgs[i].datalen);
  net_message.cursize := loop.msgs[i].datalen;
  FillChar(net_from, SizeOf(net_from), 0);
  net_from.type_ := NA_LOOPBACK;
  Result := true;
end;

procedure NET_SendLoopPacket(sock: netsrc_t; length: Integer;
  data: Pointer; const to_: netadr_t);
var
  i: Integer;
  loop: loopback_p;
begin
  loop := @loopbacks[netsrc_t(Ord(sock) xor 1)];

  i := loop.send and (MAX_LOOPBACK - 1);
  Inc(loop.send);

  Move(data^, loop.msgs[i].data, length);
  loop.msgs[i].datalen := length;
end;

//=============================================================================

function NET_GetPacket(sock: netsrc_t; var net_from: netadr_t;
  var net_message: sizebuf_t): qboolean;
var
  ret: Integer;
  from: sockaddr;
  fromlen: Integer;
  net_socket: Integer;
  protocol: Integer;
  err: Integer;
begin
  if (NET_GetLoopPacket(sock, net_from, net_message)) then
  begin
    Result := True;
    Exit;
  end;

  for protocol := 0 to 1 do
  begin
    if (protocol = 0) then
      net_socket := ip_sockets[sock]
    else
      net_socket := ipx_sockets[sock];

    if (net_socket = 0) then
      Continue;

    fromlen := SizeOf(from);
    ret := recvfrom(net_socket, net_message.data^, net_message.maxsize, 0,
{$IFDEF USE_JWA}
      @from, fromlen);
{$ELSE}
      from, fromlen);
{$ENDIF}

    SockadrToNetadr(from, net_from);

    if (ret = -1) then
    begin
      err := WSAGetLastError;

      // Juha: This is bug in original quake2 engine as well. Windows 2000 gives
      // WSAECONNRESET error when client disconnects, and thus, the server
      // crashes. We just choose to ignore these messages.
      // NOTE: Better way could be to drop the client as well..
      if (err = WSAEWOULDBLOCK) or (err = WSAECONNRESET) then
        Continue;
      if (err = WSAEMSGSIZE) then
      begin
        Com_Printf('Warning:  Oversize packet from %s'#10,
          [NET_AdrToString(net_from)]);
        Continue;
      end;

      if (dedicated.value <> 0) then    // let dedicated servers continue after errors
        Com_Printf('NET_GetPacket: %s from %s'#10,
          [NET_ErrorString, NET_AdrToString(net_from)])
      else
        Com_Error(ERR_DROP, 'NET_GetPacket: %s from %s',
          [NET_ErrorString, NET_AdrToString(net_from)]);
      Continue;
    end;

    if (ret = net_message.maxsize) then
    begin
      Com_Printf('Oversize packet from %s'#10, [NET_AdrToString(net_from)]);
      Continue;
    end;

    net_message.cursize := ret;
    Result := True;
    Exit;
  end;

  Result := False;
end;

//=============================================================================

procedure NET_SendPacket(sock: netsrc_t; length: Integer; data: Pointer; const to_: netadr_t);
var
  ret: Integer;
  addr: sockaddr;
  net_socket: Integer;
  err: Integer;
begin
  if (to_.type_ = NA_LOOPBACK) then
  begin
    NET_SendLoopPacket(sock, length, data, to_);
    Exit;
  end;

  if (to_.type_ = NA_BROADCAST) then
  begin
    net_socket := ip_sockets[sock];
    if (net_socket = 0) then
      Exit;
  end
  else if (to_.type_ = NA_IP) then
  begin
    net_socket := ip_sockets[sock];
    if (net_socket = 0) then
      Exit;
  end
  else if (to_.type_ = NA_IPX) then
  begin
    net_socket := ipx_sockets[sock];
    if (net_socket = 0) then
      Exit;
  end
  else if (to_.type_ = NA_BROADCAST_IPX) then
  begin
    net_socket := ipx_sockets[sock];
    if (net_socket = 0) then
      Exit;
  end
  else
  begin
    Com_Error(ERR_FATAL, 'NET_SendPacket: bad address type', []);
    Exit;                               //Clootie: to fool compiler
  end;

  NetadrToSockadr(to_, addr);

{$IFDEF USE_JWA}
  ret := sendto(net_socket, data, length, 0, @addr, SizeOf(addr));
{$ELSE}
  ret := sendto(net_socket, data^, length, 0, addr, SizeOf(addr));
{$ENDIF}
  if (ret = -1) then
  begin
    err := WSAGetLastError;

    // wouldblock is silent
    if (err = WSAEWOULDBLOCK) then
      Exit;

    // some PPP links dont allow broadcasts
    if (err = WSAEADDRNOTAVAIL) and
      ((to_.type_ = NA_BROADCAST) or (to_.type_ = NA_BROADCAST_IPX)) then
      Exit;

    if (dedicated.value <> 0) then      // let dedicated servers continue after errors
    begin
      Com_Printf('NET_SendPacket ERROR: %s to %s'#10,
        [NET_ErrorString, NET_AdrToString(to_)]);
    end
    else
    begin
      if (err = WSAEADDRNOTAVAIL) then
      begin
        Com_DPrintf('NET_SendPacket Warning: %s : %s'#10,
          [NET_ErrorString, NET_AdrToString(to_)]);
      end
      else
      begin
        Com_Error(ERR_DROP, 'NET_SendPacket ERROR: %s to %s'#10,
          [NET_ErrorString, NET_AdrToString(to_)]);
      end;
    end;
  end;
end;

//=============================================================================

{*
====================
NET_Socket
====================
*}
function NET_IPSocket(net_interface: PChar; port: Integer): Integer;
var
  newsocket: Integer;
  address: sockaddr_in;
  _true: Integer; // qboolean
  i: Integer;
  err: Integer;
begin
  _true := 1;
  i := 1;

  newsocket := socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP);
  if (newsocket = -1) then
  begin
    err := WSAGetLastError;
    if (err <> WSAEAFNOSUPPORT) then
      Com_Printf('WARNING: UDP_OpenSocket: socket: %s', [NET_ErrorString]);
    Result := 0;
    Exit;
  end;

  // make it non-blocking
{$IFDEF USE_JWA}
  if (ioctlsocket(newsocket, FIONBIO, Cardinal(_true)) = -1) then
{$ELSE}
  if (ioctlsocket(newsocket, FIONBIO, _true) = -1) then
{$ENDIF}
  begin
    Com_Printf('WARNING: UDP_OpenSocket: ioctl FIONBIO: %s'#10, [NET_ErrorString]);
    Result := 0;
    Exit;
  end;

  // make it broadcast capable
  if (setsockopt(newsocket, SOL_SOCKET, SO_BROADCAST, PChar(@i), SizeOf(i)) = -1) then
  begin
    Com_Printf('WARNING: UDP_OpenSocket: setsockopt SO_BROADCAST: %s'#10, [NET_ErrorString]);
    Result := 0;
    Exit;
  end;

  if (net_interface = nil) or (net_interface[0] = #0) or
    (StrIComp(net_interface, 'localhost') = 0) then
    address.sin_addr.s_addr := INADDR_ANY
  else
    NET_StringToSockaddr(net_interface, sockaddr(address));

  if (port = PORT_ANY) then
    address.sin_port := 0
  else
    address.sin_port := htons(port);

  address.sin_family := AF_INET;

{$IFDEF USE_JWA}
  if (bind(newsocket, @address, SizeOf(address)) = -1) then
{$ELSE}
  if (bind(newsocket, address, SizeOf(address)) = -1) then
{$ENDIF}
  begin
    Com_Printf('WARNING: UDP_OpenSocket: bind: %s'#10, [NET_ErrorString]);
    closesocket(newsocket);
    Result := 0;
    Exit;
  end;

  Result := newsocket;
end;

{*
====================
NET_OpenIP
====================
*}
procedure NET_OpenIP;
var
  ip: cvar_p;
  port: Integer;
  dedicated: Integer;
begin
  ip := Cvar_Get('ip', 'localhost', CVAR_NOSET);

  dedicated := Round(Cvar_VariableValue('dedicated'));

  if (ip_sockets[NS_SERVER] = 0) then
  begin
    port := Round(Cvar_Get('ip_hostport', '0', CVAR_NOSET).value);
    if (port = 0) then
    begin
      port := Round(Cvar_Get('hostport', '0', CVAR_NOSET).value);
      if (port = 0) then
      begin
        port := Round(Cvar_Get('port', va('%d', [PORT_SERVER]), CVAR_NOSET).value);
      end;
    end;
    ip_sockets[NS_SERVER] := NET_IPSocket(ip.string_, port);
    if (ip_sockets[NS_SERVER] = 0) and (dedicated <> 0) then
      Com_Error(ERR_FATAL, 'Couldn''t allocate dedicated server IP port', []);
  end;

  // dedicated servers don't need client ports
  if (dedicated <> 0) then
    Exit;

  if (ip_sockets[NS_CLIENT] = 0) then
  begin
    port := Round(Cvar_Get('ip_clientport', '0', CVAR_NOSET).value);
    if (port = 0) then
    begin
      port := Round(Cvar_Get('clientport', va('%d', [PORT_CLIENT]), CVAR_NOSET).value);
      if (port = 0) then
        port := PORT_ANY;
    end;
    ip_sockets[NS_CLIENT] := NET_IPSocket(ip.string_, port);
    if (ip_sockets[NS_CLIENT] = 0) then
      ip_sockets[NS_CLIENT] := NET_IPSocket(ip.string_, PORT_ANY);
  end;
end;

{*
====================
IPX_Socket
====================
*}
function NET_IPXSocket(port: Integer): Integer;
var
  newsocket: Integer;
  address: sockaddr_in;
  _true: Integer;
  err: Integer;
begin
  _true := 1;

  newsocket := socket(PF_IPX, SOCK_DGRAM, NSPROTO_IPX);
  if (newsocket = -1) then
  begin
    err := WSAGetLastError;
    if (err <> WSAEAFNOSUPPORT) then
      Com_Printf('WARNING: IPX_Socket: socket: %s'#10, [NET_ErrorString]);
    Result := 0;
    Exit;
  end;

  // make it non-blocking
{$IFDEF USE_JWA}
  if (ioctlsocket(newsocket, FIONBIO, Cardinal(_true)) = -1) then
{$ELSE}
  if (ioctlsocket(newsocket, FIONBIO, _true) = -1) then
{$ENDIF}
  begin
    Com_Printf('WARNING: IPX_Socket: ioctl FIONBIO: %s'#10, [NET_ErrorString]);
    Result := 0;
    Exit;
  end;

  // make it broadcast capable
  if (setsockopt(newsocket, SOL_SOCKET, SO_BROADCAST, PChar(@_true), SizeOf(_true)) = -1) then
  begin
    Com_Printf('WARNING: IPX_Socket: setsockopt SO_BROADCAST: %s'#10, [NET_ErrorString]);
    Result := 0;
    Exit;
  end;

  PSockAddrIPX(@address).sa_family := AF_IPX;
  FillChar(PSockAddrIPX(@address).sa_netnum, 4, 0);
  FillChar(PSockAddrIPX(@address).sa_nodenum, 6, 0);
  if (port = PORT_ANY) then
    PSockAddrIPX(@address).sa_socket := 0
  else
    PSockAddrIPX(@address).sa_socket := htons(port);

{$IFDEF USE_JWA}
  if (bind(newsocket, PSockAddr(@address), SizeOf(address)) = -1) then
{$ELSE}
  if (bind(newsocket, address, SizeOf(address)) = -1) then
{$ENDIF}
  begin
    Com_Printf('WARNING: IPX_Socket: bind: %s'#10, [NET_ErrorString]);
    closesocket(newsocket);
    Result := 0;
    Exit;
  end;

  Result := newsocket;
end;

{*
====================
NET_OpenIPX
====================
*}
procedure NET_OpenIPX;
var
  port: Integer;
  dedicated: Integer;
begin
  dedicated := Round(Cvar_VariableValue('dedicated'));

  if (ipx_sockets[NS_SERVER] = 0) then
  begin
    port := Round(Cvar_Get('ipx_hostport', '0', CVAR_NOSET).value);
    if (port = 0) then
    begin
      port := Round(Cvar_Get('hostport', '0', CVAR_NOSET).value);
      if (port = 0) then
      begin
        port := Round(Cvar_Get('port', va('%d', [PORT_SERVER]), CVAR_NOSET).value);
      end;
    end;
    ipx_sockets[NS_SERVER] := NET_IPXSocket(port);
  end;

  // dedicated servers don't need client ports
  if (dedicated <> 0) then
    Exit;

  if (ipx_sockets[NS_CLIENT] = 0) then
  begin
    port := Round(Cvar_Get('ipx_clientport', '0', CVAR_NOSET).value);
    if (port = 0) then
    begin
      port := Round(Cvar_Get('clientport', va('%d', [PORT_CLIENT]), CVAR_NOSET).value);
      if (port = 0) then
        port := PORT_ANY;
    end;
    ipx_sockets[NS_CLIENT] := NET_IPXSocket(port);
    if (ipx_sockets[NS_CLIENT] = 0) then
      ipx_sockets[NS_CLIENT] := NET_IPXSocket(PORT_ANY);
  end;
end;

{*
====================
NET_Config

A single player game will only use the loopback code
====================
*}
procedure NET_Config(multiplayer: qboolean);
const
{$IFDEF COMPILER6_UP}{$WRITEABLECONST ON}{$ENDIF}
  old_config: qboolean = False;
{$IFDEF COMPILER6_UP}{$WRITEABLECONST OFF}{$ENDIF}
var
  i: netsrc_t;
begin
  if (old_config = multiplayer) then
    Exit;

  old_config := multiplayer;

  if not multiplayer then
  begin                                 // shut down any existing sockets
    for i := NS_CLIENT to NS_SERVER do
    begin
      if (ip_sockets[i] <> 0) then
      begin
        closesocket(ip_sockets[i]);
        ip_sockets[i] := 0;
      end;
      if (ipx_sockets[i] <> 0) then
      begin
        closesocket(ipx_sockets[i]);
        ipx_sockets[i] := 0;
      end;
    end;
  end
  else
  begin                                 // open sockets
    if (noudp.value = 0) then
      NET_OpenIP;
    if (noipx.value = 0) then
      NET_OpenIPX;
  end;
end;

// sleeps msec or until net socket is ready

procedure NET_Sleep(msec: Integer);
var
  timeout: timeval;
  fdset: TFDSet;
  i: Integer;
begin
  if (dedicated = nil) or (dedicated.value = 0) then
    Exit;                               // we're not a server, just run full speed

  FD_ZERO(fdset);
  i := 0;
  if (ip_sockets[NS_SERVER] <> 0) then
  begin
{$IFDEF USE_JWA}
    _FD_SET(ip_sockets[NS_SERVER], fdset); // network socket
{$ELSE}
    FD_SET(ip_sockets[NS_SERVER], fdset); // network socket
{$ENDIF}
    i := ip_sockets[NS_SERVER];
  end;
  if (ipx_sockets[NS_SERVER] <> 0) then
  begin
{$IFDEF USE_JWA}
    _FD_SET(ipx_sockets[NS_SERVER], fdset); // network socket
{$ELSE}
    FD_SET(ipx_sockets[NS_SERVER], fdset); // network socket
{$ENDIF}
    if (ipx_sockets[NS_SERVER] > i) then
      i := ipx_sockets[NS_SERVER];
  end;
  timeout.tv_sec := msec div 1000;
  timeout.tv_usec := (msec mod 1000) * 1000;
  select(i + 1, @fdset, nil, nil, @timeout);
end;

//===================================================================

var
  winsockdata: WSADATA;

{*
====================
NET_Init
====================
*}
procedure NET_Init;
var
  //  wVersionRequested: Word; //Clootie: never used
  r: Integer;
begin
  //  wVersionRequested := MAKEWORD(1, 1); //Clootie: never used

  r := WSAStartup(MAKEWORD(1, 1), winsockdata);

  if (r <> 0) then
    Com_Error(ERR_FATAL, 'Winsock initialization failed.', []);

  Com_Printf('Winsock Initialized'#10, []);

  noudp := Cvar_Get('noudp', '0', CVAR_NOSET);
  noipx := Cvar_Get('noipx', '0', CVAR_NOSET);

  net_shownet := Cvar_Get('net_shownet', '0', 0);
end;

{*
====================
NET_Shutdown
====================
*}
procedure NET_Shutdown;
begin
  NET_Config(False);                    // close sockets

  WSACleanup;
end;

{*
====================
NET_ErrorString
====================
*}
function NET_ErrorString: PChar;
var
  code: Integer;
begin
  code := WSAGetLastError;
  case (code) of
    WSAEINTR: Result := 'WSAEINTR';
    WSAEBADF: Result := 'WSAEBADF';
    WSAEACCES: Result := 'WSAEACCES';
    WSAEDISCON: Result := 'WSAEDISCON';
    WSAEFAULT: Result := 'WSAEFAULT';
    WSAEINVAL: Result := 'WSAEINVAL';
    WSAEMFILE: Result := 'WSAEMFILE';
    WSAEWOULDBLOCK: Result := 'WSAEWOULDBLOCK';
    WSAEINPROGRESS: Result := 'WSAEINPROGRESS';
    WSAEALREADY: Result := 'WSAEALREADY';
    WSAENOTSOCK: Result := 'WSAENOTSOCK';
    WSAEDESTADDRREQ: Result := 'WSAEDESTADDRREQ';
    WSAEMSGSIZE: Result := 'WSAEMSGSIZE';
    WSAEPROTOTYPE: Result := 'WSAEPROTOTYPE';
    WSAENOPROTOOPT: Result := 'WSAENOPROTOOPT';
    WSAEPROTONOSUPPORT: Result := 'WSAEPROTONOSUPPORT';
    WSAESOCKTNOSUPPORT: Result := 'WSAESOCKTNOSUPPORT';
    WSAEOPNOTSUPP: Result := 'WSAEOPNOTSUPP';
    WSAEPFNOSUPPORT: Result := 'WSAEPFNOSUPPORT';
    WSAEAFNOSUPPORT: Result := 'WSAEAFNOSUPPORT';
    WSAEADDRINUSE: Result := 'WSAEADDRINUSE';
    WSAEADDRNOTAVAIL: Result := 'WSAEADDRNOTAVAIL';
    WSAENETDOWN: Result := 'WSAENETDOWN';
    WSAENETUNREACH: Result := 'WSAENETUNREACH';
    WSAENETRESET: Result := 'WSAENETRESET';
    WSAECONNABORTED: Result := 'WSWSAECONNABORTEDAEINTR';
    WSAECONNRESET: Result := 'WSAECONNRESET';
    WSAENOBUFS: Result := 'WSAENOBUFS';
    WSAEISCONN: Result := 'WSAEISCONN';
    WSAENOTCONN: Result := 'WSAENOTCONN';
    WSAESHUTDOWN: Result := 'WSAESHUTDOWN';
    WSAETOOMANYREFS: Result := 'WSAETOOMANYREFS';
    WSAETIMEDOUT: Result := 'WSAETIMEDOUT';
    WSAECONNREFUSED: Result := 'WSAECONNREFUSED';
    WSAELOOP: Result := 'WSAELOOP';
    WSAENAMETOOLONG: Result := 'WSAENAMETOOLONG';
    WSAEHOSTDOWN: Result := 'WSAEHOSTDOWN';
    WSASYSNOTREADY: Result := 'WSASYSNOTREADY';
    WSAVERNOTSUPPORTED: Result := 'WSAVERNOTSUPPORTED';
    WSANOTINITIALISED: Result := 'WSANOTINITIALISED';
    WSAHOST_NOT_FOUND: Result := 'WSAHOST_NOT_FOUND';
    WSATRY_AGAIN: Result := 'WSATRY_AGAIN';
    WSANO_RECOVERY: Result := 'WSANO_RECOVERY';
    WSANO_DATA: Result := 'WSANO_DATA';
  else
    Result := 'NO ERROR';
  end;
end;

end.
