unit net_udp;

//Initial conversion by : Fabrizio Rossini ( FAB )
//
{ This File contains part of convertion of Quake2 source to ObjectPascal.    }
{ More information about this project can be found at:                       }
{ http://www.sulaco.co.za/quake2/                                            }


(*
Copyright (C) 1997-2001 Id Software, Inc.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  

See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
*)
(* net_wins.c*)

{.$include "../qcommon/qcommon.h"}

{.$include <unistd.h>}
{.$include <sys/socket.h>}
{.$include <sys/time.h>}
{.$include <netinet/in.h>}
{.$include <netdb.h>}
{.$include <sys/param.h>}
{.$include <sys/ioctl.h>}
{.$include <sys/uio.h>}
{.$include <errno.h>}

{.$ifdef NeXT}
{.$include <libc.h>}
{.$endif}
interface
uses q_shared_add , Common, libc ;

var
net_local_adr: netadr_t;
 
const
LOOPBACK = $7f000001; 

MAX_LOOPBACK = 4; 

type
loopmsg_t = record
data: array [0..Pred(MAX_MSGLEN)] of byte; 
datalen: integer; 
end;
loopmsg_p = ^loopmsg_t;

loopback_t = record
msgs: array [0..Pred(MAX_LOOPBACK)] of loopmsg_t;
get: integer;
send: integer;
end;

loopback_p = ^loopback_t ;

var
loopbacks: array [0..Pred(2)] of loopback_t; 
ip_sockets: array [0..Pred(2)] of integer; 
ipx_sockets: array [0..Pred(2)] of integer; 

function NET_Socket(net_interface: pchar;  port: integer): integer; 
procedure NET_SendPacket(sock: netsrc_t;  length: integer;  data: pointer;  _to: netadr_t);
function NET_AdrToString(a: netadr_t): pchar;
procedure NET_Config(multiplayer: qboolean);
function NET_StringToAdr(s: pchar;  a: netadr_p): qboolean;
function NET_CompareBaseAdr(a: netadr_t;  b: netadr_t): qboolean;
function NET_CompareAdr(a: netadr_t;  b: netadr_t): qboolean;
function NET_IsLocalAddress(adr: netadr_t): qboolean;
function NET_GetPacket(sock: netsrc_t;  net_from: netadr_p;  net_message: sizebuf_p): qboolean;
function NET_ErrorString(): pchar;
procedure NET_Init();
procedure NET_Sleep(msec: integer);

(*=============================================================================*)

implementation

uses q_shared ,
     Cvar , SysUtils, sys_linux,
     Kernelioctl;

procedure NetadrToSockadr(a: netadr_p;  s: PSockAddrIn);
begin
  //RtlZeroMemory(s, sizeof( s^));
   memset (s, 0, sizeof(s^));
  
  if a^.type_ = NA_BROADCAST then
  begin 
    s^.sin_family:= AF_INET;
    s^.sin_port:= a^.port;
	//*(int *)&s->sin_addr = -1; 
	//*(int* )@s.sin_addr:=-1;
	Integer(s^.sin_addr) := -1 ;
  end
  else
  if a^.type_ = NA_IP then
  begin 
    s^.sin_family:= AF_INET;
	
	//*(int *)&s->sin_addr = *(int *)&a->ip;
	//*(int* )@s.sin_addr:=*(int* ) @a.ip;
	Integer(s^.sin_addr) := Integer(a^.ip);
	
	 
    s^.sin_port:= a^.port; 
    
  end;
end;


procedure SockadrToNetadr (s: PSockAddrIn;  a: netadr_p);
begin
 //*(int* ) and a.ip:=*(int* )@s.sin_addr;
  Integer(a^.ip) := Integer(s^.sin_addr) ;
  a^.port:= s^.sin_port;
  a^.type_:= NA_IP;
end;



function NET_CompareAdr(a: netadr_t;  b: netadr_t): qboolean;
begin
  if ((a.ip[0] = b.ip[0]) and (a.ip[1] = b.ip[1]) and (a.ip[2] = b.ip[2]) and (a.ip[3] = b.ip[3]) and (a.port = b.port)) then
  begin
    result:= true; 
    exit;
  end;

  result:= false;

end;

(*
===================
NET_CompareBaseAdr

Compares without the port
===================
*)

function NET_CompareBaseAdr(a: netadr_t;  b: netadr_t): qboolean; 
begin
  if (a.type_ <> b.type_ ) then
  begin
    result:= false; 
    exit;
  end;

  if (a.type_ = NA_LOOPBACK ) then
  begin
    result:= true; 
    exit;
    
  end;

  if (a.type_ = NA_IP ) then
  begin
    if ((a.ip[0] = b.ip[0]) and (a.ip[1] = b.ip[1]) and (a.ip[2] = b.ip[2]) and (a.ip[3] = b.ip[3])) then
    begin
      result:= true; 
      exit;
    end;

    result:= false;
    //  exit;

  end;
  
  if (a.type_ = NA_IPX) then
  begin 
    if (memcmp(@a.ipx, @b.ipx, 10) =0) then
    begin
      result:= true; 
      exit;
    end;


    result:= false;

  end;
end;

//var {was static}
//s: array [0..Pred(64)] of char;

function NET_AdrToString(a: netadr_t): pchar;
var {was static}
s: array [0..Pred(64)] of char;

begin
  
  Com_sprintf(s, sizeof(s), '%i.%i.%i.%i:%i', [a.ip[0], a.ip[1], a.ip[2], a.ip[3], ntohs(a.port)]);
  

  result:= s; 

end;

//var {was static}
//s: array [0..Pred(64)] of char;

function NET_BaseAdrToString(a: netadr_t): pchar;
var {was static}
s: array [0..Pred(64)] of char;
begin
  
  Com_sprintf(s, sizeof(s), '%i.%i.%i.%i', [a.ip[0], a.ip[1], a.ip[2], a.ip[3] ] );
  

  result:= s;

end;

(*
=============
NET_StringToAdr

localhost
idnewt
idnewt:28000
192.246.40.70
192.246.40.70:28000
=============
*)
function NET_StringToSockaddr(s: pchar;  sadr: psockaddr): qboolean; 
var
colon: pchar; 
copya: array [0..Pred(128)] of char;
h : Phostent ;
begin
  
  
  memset (sadr, 0, sizeof( sadr^));
  //RtlZeroMemory(sadr,sizeof(*sadr));

  //((structsockaddr_in* )sadr).sin_family:=AF_INET;
  //((structsockaddr_in* )sadr).sin_port:=0;
  sadr.sin_family := AF_INET ;
  sadr.sin_port := 0;

  strcpy(copya,s);
  
  (* strip off a trailing :port if present*)
  colon:= copya;

  while colon <> nil
  do
  begin
  if colon^=':' then
  begin 
    colon^:=#0;
    //((structsockaddr_in* )sadr).sin_port:=htons({!!!a type cast? =>} {smallint(}atoi(colon+1));
    sadr.sin_port := htons ( atoi(colon+1));
   end;
  inc(colon);
  end;

  if ((copya[0] >='0') and (copya[0] <= '9')) then
  begin 
    //*(int* )@((structsockaddr_in* )sadr).sin_addr:=inet_addr(copy);
    Cardinal(sadr.sin_addr) := inet_addr (copya) ;
  end
  else
  begin
   h:= gethostbyname (copya);
    if {not} (h = nil) then
    begin
      result:= False;
      exit;
    end;


    //*(int* )@((structsockaddr_in* )sadr).sin_addr:=*{!!!a type cast? =>} {pinteger(}h.h_addr_list[0];
    // 
    // TODO  sadr.sin_addr := h.h_addr_list[0];

  end;

    result:= true;
end;

(*
=============
NET_StringToAdr

localhost
idnewt
idnewt:28000
192.246.40.70
192.246.40.70:28000
=============
*)

function NET_StringToAdr(s: pchar;  a: netadr_p): qboolean;
var
sadr : TSockAddrIn;
begin
  
  if {not} strcmp(s,'localhost') = 0 then
  begin

   memset (a, 0, sizeof(a^));

    a^.type_:= NA_LOOPBACK;

    result:= true;
    exit;

  end;
  
  //if {not}0=NET_StringToSockaddr(s,(structsockaddr* )@sadr)
  if not NET_StringToSockaddr (s , @sadr) then
  begin
    result:= false; 
    exit;
  end;
  SockadrToNetadr(@sadr,a); 
  
  begin
    result:= true; 
    exit;
  end;
end;



function NET_IsLocalAddress(adr: netadr_t): qboolean; 
begin
  begin
    result:= NET_CompareAdr(adr,net_local_adr); 
    exit;
  end;
end;

(*
=============================================================================

LOOPBACK BUFFERS FOR LOCAL PLAYER

=============================================================================
*)


function NET_GetLoopPacket(sock: netsrc_t;  net_from: netadr_p;  net_message: sizebuf_p): qboolean;
var
i: integer; 
loop: loopback_p;
begin
  
  loop:= @loopbacks[integer(sock)];

  if ((loop^.send - loop^.get) > MAX_LOOPBACK ) then
  loop^.get:= loop^.send - MAX_LOOPBACK;

  if (loop^.get >= loop.send ) then
  begin
    result:= false; 
    exit;
  end;

  i:= loop^.get and (MAX_LOOPBACK-1);
  inc(loop^.get);

  memcpy(net_message^.data,@loop^.msgs[i].data,loop^.msgs[i].datalen);
  
  net_message^.cursize:= loop^.msgs[i].datalen;
  net_from^:=net_local_adr;


  result:= true;

end;



procedure NET_SendLoopPacket(sock: netsrc_t;  length: integer;  data: pointer;  to_: netadr_t);
var
i: integer; 
loop: loopback_p;
begin
  
  loop:= @loopbacks[Integer(sock) xor 1];

  i:= loop^.send and (MAX_LOOPBACK-1);
  inc(loop^.send);
  memcpy(@loop^.msgs[i].data, data, length);
  

  loop^.msgs[i].datalen:= length;
end;

(*=============================================================================*)

function NET_GetPacket(sock: netsrc_t;  net_from: netadr_p;  net_message: sizebuf_p): qboolean;
var
ret: integer; 
fromlen: integer; 
net_socket: integer; 
protocol: integer; 
err: integer;
from : TSockAddrIn;
begin

  
  if NET_GetLoopPacket(sock,net_from,net_message)
  then
  begin
    result:= true; 
    exit;
    
  end;
  for protocol:= 0 to Pred(2) do
  begin 
    if protocol= 0 then
    net_socket:= ip_sockets[integer(sock)]
    else
    net_socket:= ipx_sockets[Integer(sock)];

    if {not} net_socket= 0 then continue ;

    fromlen:= sizeof(from);

    ret:= recvfrom (net_socket, net_message^.data, net_message^.maxsize, 0, @from, @fromlen);
    SockadrToNetadr( @from, net_from);
    
    
    
    if ret=-1 then
    begin 
      err:= errno;

      if (( err = EWOULDBLOCK) or (err = ECONNREFUSED)) then

      continue;

      Com_Printf('NET_GetPacket: %s from %s'#10, [NET_ErrorString , NET_AdrToString(net_from^)]);

      continue

    end;
    
    if ret = net_message^.maxsize then
    begin 
      Com_Printf('Oversize packet from %s'#10, [NET_AdrToString(net_from^)] );
      begin

        continue
      end; 
    end;

    net_message^.cursize:= ret;

    result:= true;
    exit;

  end;
  

  result:= false;

end;

(*=============================================================================*)

procedure NET_SendPacket(sock: netsrc_t;  length: integer;  data: pointer;  _to: netadr_t);
var
ret: integer;
net_socket: integer;
addr : TSockAddrIn;
begin
  
  
  if _to.type_ = NA_LOOPBACK then
  begin 
    NET_SendLoopPacket(sock, length, data, _to);
    exit;
  end;
  
  if _to.type_ = NA_BROADCAST then
  begin 
    net_socket:= ip_sockets[Integer(sock)];
    if {not} net_socket = 0 then exit;
  end
  else
  if _to.type_ = NA_IP then
  begin 
    net_socket:= ip_sockets[Integer(sock)];
    if {not} net_socket = 0 then exit;
  end
  else
  if _to.type_ = NA_IPX then
  begin 
    net_socket:= ipx_sockets[Integer(sock)];
    if {not} net_socket = 0 then exit;
  end
  else
  if _to.type_ = NA_BROADCAST_IPX then
  begin 
    net_socket:= ipx_sockets[Integer(sock)]; 
    if {not} net_socket = 0 then exit;
  end
  else
  Com_Error(ERR_FATAL,'NET_SendPacket: bad address type'); 
  NetadrToSockadr(@_to, @addr);
  
  ret := sendto( net_socket, data, length, 0, addr, sizeof(addr));
  if ret = -1 then
  begin 
    Com_Printf('NET_SendPacket ERROR: %s to %s'#10, [ NET_ErrorString , NET_AdrToString(_to)]);
  end;
end;


(*=============================================================================*)



(*
====================
NET_OpenIP
====================
*)

procedure NET_OpenIP(); 
var
port: cvar_p;
ip :  cvar_p; 
begin
  
  port:= Cvar_Get('port', va('%i',[PORT_SERVER]), CVAR_NOSET);

  ip:= Cvar_Get('ip', 'localhost', CVAR_NOSET);

  if {not} ip_sockets[Integer(NS_SERVER)]= 0 then

  ip_sockets[integer(NS_SERVER)]:= NET_Socket(ip^.string_, Trunc(port^.value));

  if {not} ip_sockets[Integer(NS_CLIENT)]= 0 then
  ip_sockets[Integer(NS_CLIENT)]:= NET_Socket(ip^.string_,PORT_ANY);
end;

(*
====================
NET_OpenIPX
====================
*)

procedure NET_OpenIPX(); 
begin
end;


(*
====================
NET_Config

A single player game will only use the loopback code
====================
*)

procedure NET_Config(multiplayer: qboolean); 
var
i: integer; 
begin
  if not multiplayer then
  begin 
    (* shut down any existing sockets*)
    for{while} i:=0 to Pred(2) { i++}
    do
    begin 
      if ip_sockets[i]<> 0 then
      begin
        __close(ip_sockets[i]);
        ip_sockets[i]:= 0;
      end;
      if ipx_sockets[i]<> 0 then
      begin 
        __close(ipx_sockets[i]);
        ipx_sockets[i]:= 0; 
      end;
    end;
  end
  else
  begin 
    (* open sockets*)
    NET_OpenIP(); 
    NET_OpenIPX(); 
  end;
end;


(*===================================================================*)

(*
====================
NET_Init
====================
*)

procedure NET_Init(); 
begin
end;


(*
====================
NET_Socket
====================
*)

function NET_Socket(net_interface: pchar;  port: integer): integer; 
var
newsocket: integer; 
_true: qboolean;
address : TSockAddrIn;
i: integer;
 
begin

  _true:= true;

  i:=1;
  newsocket:= socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP);
  if (newsocket = -1 ) then
  begin 
    Com_Printf('ERROR: UDP_OpenSocket: socket: %s', [NET_ErrorString] );

    result:= 0;
    exit;
  end;
  
  (* make it non-blocking*)
  
  if ioctl(newsocket, FIONBIO, @_true) = -1 then
  begin
    Com_Printf('ERROR: UDP_OpenSocket: ioctl FIONBIO:%s'#10, [NET_ErrorString()]);

    result:= 0;
    exit;
  end;
  
  (* make it broadcast capable*)
  if setsockopt(newsocket, SOL_SOCKET, SO_BROADCAST, @i, sizeof(i)) = -1 then
  begin
    Com_Printf('ERROR: UDP_OpenSocket: setsockopt SO_BROADCAST:%s'#10, [NET_ErrorString] );

    result:= 0;
    exit;
  end;
  
  //if {not}0=net_interface)or({not}0=net_interface[0])or({not}0=stricmp(net_interface,'localhost')
  if ((net_interface = nil) or (net_interface[0] = #0) or ( stricomp (net_interface ,'localhost') = 0)) then
  address.sin_addr.s_addr:= INADDR_ANY
  else
  NET_StringToSockaddr(net_interface, @address);
  
  if port = PORT_ANY then
  address.sin_port:= 0
  else
  address.sin_port := htons( port);
  address.sin_family := AF_INET;
  
  if (bind(newsocket, address, sizeof(address))= -1) then
  begin 
    Com_Printf('ERROR: UDP_OpenSocket: bind: %s'#10, [NET_ErrorString] );
    __close(newsocket);

    result:= 0;
    exit;
  end;
  

  result:= newsocket; 

end;


(*
====================
NET_Shutdown
====================
*)

procedure NET_Shutdown(); 
begin
  NET_Config(false); 
end;(* close sockets*)



(*
====================
NET_ErrorString
====================
*)

function NET_ErrorString(): pchar; 
var
code: integer; 
begin
  code:= errno; 

  result:= strerror(code);
  exit;
end;


(* sleeps msec or until net socket is ready*)
procedure NET_Sleep(msec: integer); 
var
fdset: __fd_set; // or TFdSet ----in Libc.pas
timeout :Timeval;
begin

  //if {not}0=ip_sockets[NS_SERVER])or((dedicated)and({not}0=dedicated.value)
  if (( ip_sockets[Integer(NS_SERVER)] = 0) or ((dedicated <> nil) and (dedicated.value = 0)))
  then
  exit;

  (* we're not a server, just run full speed*)
  FD_ZERO( fdset);
  if stdin_active  then
  FD_SET(0, fdset);  (* stdin is processed too*)

  FD_SET(ip_sockets[Integer(NS_SERVER)], fdset);

  timeout.tv_sec:= msec div 1000; 
  timeout.tv_usec:= (msec mod 1000)*1000; 
  select(ip_sockets[Integer(NS_SERVER)]+1, @fdset, nil, nil, @timeout);
  (* network socket*)
end;


end.
