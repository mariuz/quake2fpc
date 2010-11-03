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


{$ALIGN ON}{$MINENUMSIZE 4}
{----------------------------------------------------------------------------}
{                                                                            }
{ File(s): client\cl_main.c                                                    }
{                                                                            }
{ Initial conversion by : Juha Hartikainen (juha@linearteam.org)             }
{ Initial conversion on : 02-Jun-2002                                        }
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
{ Updated on : 25-jul-2002                                                   }
{ Updated by : burnin (leonel@linuxbr.com.br)                                }
{   Removed IFDEF TODO directives around menu calls.                         }
{   Added some routines needed by menu.pas to interface section              }
{                                                                            }
{----------------------------------------------------------------------------}
// cl_main.c  -- client main loop

unit cl_main;

interface

uses
  Client,
  q_shared;

procedure Cmd_ForwardToServer;
procedure CL_Disconnect;
procedure CL_FixUpGender;
procedure CL_Snd_Restart_f; cdecl;
procedure CL_Drop;
procedure CL_Init;
procedure CL_Shutdown;
procedure CL_Frame(msec: Integer);
procedure CL_RequestNextDownload;
procedure CL_ClearState;
procedure CL_WriteDemoMessage;
procedure CL_PingServers_f; cdecl;
procedure CL_Quit_f; cdecl;

var
  cls: client_static_t;
  cl: client_state_t;
  cl_entities: array[0..MAX_EDICTS - 1] of centity_t;
  cl_parse_entities: array[0..MAX_PARSE_ENTITIES - 1] of entity_state_t;

var
  freelook,
    adr0,
    adr1,
    adr2,
    adr3,
    adr4,
    adr5,
    adr6,
    adr7,
    adr8,

  cl_stereo_separation,
    cl_stereo,

  rcon_client_password,
    rcon_address,

  cl_noskins,
    cl_autoskins,
    cl_footsteps,
    cl_timeout,
    cl_predict,
    //cvar_t   *cl_minfps,
  cl_maxfps,
    cl_gun,

  cl_add_particles,
    cl_add_lights,
    cl_add_entities,
    cl_add_blend,

  cl_shownet,
    cl_showmiss,
    cl_showclamp,

  cl_paused,
    cl_timedemo,

  lookspring,
    lookstrafe,
    sensitivity,

  m_pitch,
    m_yaw,
    m_forward,
    m_side,

  cl_lightlevel,

  //
  // userinfo
  //
  info_password,
    info_spectator,
    name,
    skin,
    rate,
    fov,
    msg,
    hand,
    gender,
    gender_auto,

  cl_vwep: cvar_p;

implementation

uses
  {$IFDEF WIN32}
  Windows,
  net_wins,
  sys_win,
  cd_win,
  q_shwin,
  in_win,
  vid_dll,
  {$ELSE}
  vid_so ,
  in_linux,
  q_shlinux,
  sys_linux,
  cd_sdl,
  net_udp,
  libc,
  {$ENDIF}
  qfiles,
  SysUtils,
  Files,
  Cmd,
  Common,
  Console,
  CModel,
  CVar,
  CPas,
  Keys,
  net_chan,
  server,
  sv_main,
  snd_dma,
  cl_tent,
  menu,
  cl_parse,
  cl_pred,
  cl_cin,
  cl_view,
  cl_input,
  cl_fx,
  cl_scrn;

//======================================================================

{*
====================
CL_WriteDemoMessage

Dumps the current net message, prefixed by the length
====================
*}
procedure CL_WriteDemoMessage;
var
  len, swlen: Integer;
  buf: pchar;
begin
  // the first eight bytes are just packet sequencing stuff
  len := net_message.cursize - 8;
  swlen := LittleLong(len);

  FileWrite(cls.demofile, swlen, 4);
  buf := PChar(Integer(net_message.data) + 8);
  FileWrite(cls.demofile, buf^, len);
end;

{*
====================
CL_Stop_f

stop recording a demo
====================
*}
procedure CL_Stop_f; cdecl;
var
  len: Integer;
begin
  if (not cls.demorecording) then
  begin
    Com_Printf('Not recording a demo.'#10, []);
    exit;
  end;

  // finish up
  len := -1;
  FileWrite(cls.demofile, len, 4);
  FileClose(cls.demofile);
  cls.demofile := 0;
  cls.demorecording := false;
  Com_Printf('Stopped demo.'#10, []);
end;

{*
====================
CL_Record_f

record <demoname>

Begins recording a demo from the current position
====================
*}
procedure CL_Record_f; cdecl;
var
  name: array[0..MAX_OSPATH - 1] of char;
  buf_data: array[0..MAX_MSGLEN - 1] of char;
  buf: sizebuf_t;
  i: Integer;
  len: Integer;
  ent: entity_state_p;
  nilstate: entity_state_t;
begin
  if (Cmd_Argc <> 2) then
  begin
    Com_Printf('record <demoname>'#10, []);
    exit;
  end;

  if (cls.demorecording) then
  begin
    Com_Printf('Already recording.'#10, []);
    exit;
  end;

  if (cls.state <> ca_active) then
  begin
    Com_Printf('You must be in a level to record.'#10, []);
    exit;
  end;

  //
  // open the demo file
  //
  Com_sprintf(name, sizeof(name), '%s/demos/%s.dm2', [FS_Gamedir, Cmd_Argv(1)]);

  Com_Printf('recording to %s.'#10, [name]);
  FS_CreatePath(name);

  cls.demofile := FileOpen(name, fmOpenReadWrite);
  if (cls.demofile = 0) then
  begin
    Com_Printf('ERROR: couldn''t open.'#10, []);
    exit;
  end;
  cls.demorecording := true;

  // don't start saving messages until a non-delta compressed message is received
  cls.demowaiting := true;

  //
  // write out messages to hold the startup information
  //
  SZ_Init(buf, PByte(@buf_data), sizeof(buf_data));

  // send the serverdata
  MSG_WriteByte(buf, Byte(svc_serverdata));
  MSG_WriteLong(buf, PROTOCOL_VERSION);
  MSG_WriteLong(buf, $010000 + cl.servercount);
  MSG_WriteByte(buf, 1);                // demos are always attract loops
  MSG_WriteString(buf, cl.gamedir);
  MSG_WriteShort(buf, cl.playernum);

  MSG_WriteString(buf, cl.configstrings[CS_NAME]);

  // configstrings
  for i := 0 to MAX_CONFIGSTRINGS - 1 do
  begin
    if (Byte(cl.configstrings[i][0]) <> 0) then
    begin
      if (buf.cursize + Length(cl.configstrings[i]) + 32 > buf.maxsize) then
      begin
        // write it out
        len := LittleLong(buf.cursize);
        FileWrite(cls.demofile, len, 4);
        FileWrite(cls.demofile, buf.data, buf.cursize);
        buf.cursize := 0;
      end;
      MSG_WriteByte(buf, Byte(svc_configstring));
      MSG_WriteShort(buf, i);
      MSG_WriteString(buf, cl.configstrings[i]);
    end;
  end;

  // baselines
  FillChar(nilstate, sizeof(nilstate), #0);
  for i := 0 to MAX_EDICTS - 1 do
  begin
    ent := @cl_entities[i].baseline;
    if (ent.modelindex = 0) then
      continue;

    if (buf.cursize + 64 > buf.maxsize) then
    begin
      // write it out
      len := LittleLong(buf.cursize);
      FileWrite(cls.demofile, len, 4);
      FileWrite(cls.demofile, buf.data, buf.cursize);
      buf.cursize := 0;
    end;

    MSG_WriteByte(buf, Byte(svc_spawnbaseline));
    MSG_WriteDeltaEntity(nilstate, cl_entities[i].baseline, buf, true, true);
  end;

  MSG_WriteByte(buf, Byte(svc_stufftext));
  MSG_WriteString(buf, 'precache'#10);

  // write it to the demo file

  len := LittleLong(buf.cursize);

  FileWrite(cls.demofile, len, 4);
  FileWrite(cls.demofile, buf.data, buf.cursize);

  // the rest of the demo file will be individual frames
end;

//======================================================================

{*
===================
Cmd_ForwardToServer

adds the current command line as a clc_stringcmd to the client message.
things like godmode, noclip, etc, are commands directed to the server,
so when they are typed in at the console, they will need to be forwarded.
===================
*}
procedure Cmd_ForwardToServer;
var
  cmd: PChar;
begin
  cmd := Cmd_Argv(0);
  if (cls.state <= ca_connected) or
    (cmd^ = '-') or
    (cmd^ = '+') then
  begin
    Com_Printf('Unknown command "%s"'#10, [cmd]);
    exit;
  end;

  MSG_WriteByte(cls.netchan.message, Byte(clc_stringcmd));
  SZ_Print(cls.netchan.message, cmd);
  if (Cmd_Argc > 1) then
  begin
    SZ_Print(cls.netchan.message, ' ');
    SZ_Print(cls.netchan.message, Cmd_Args);
  end;
end;

procedure CL_Setenv_f; cdecl;
var
  argc: Integer;
  name, value: string;
  i: Integer;
begin
  argc := Cmd_Argc();

  if (argc > 2) then
  begin

    name := Cmd_Argv(1);
    for i := 2 to argc - 1 do
    begin
      value := value + Cmd_Argv(i) + ' ';
    end;
    {$IFDEF LINUX}
    putenv( PChar(name) ); // on linux
    {$ELSE}
    Windows.SetEnvironmentVariable(PChar(name), PChar(value));
    {$ENDIF}
  end
  else if (argc = 2) then
  begin
    Value := SysUtils.GetEnvironmentVariable(Cmd_Argv(1));
    if (Value <> '') then
      Com_Printf('%s=%s'#10, [Cmd_Argv(1), Value])
    else
      Com_Printf('%s undefined'#10, [Cmd_Argv(1), Value]);
  end;
end;

{*
==================
CL_ForwardToServer_f
==================
*}
procedure CL_ForwardToServer_f; cdecl;
begin
  if (cls.state <> ca_connected) and (cls.state <> ca_active) then
  begin
    Com_Printf('Can''t "%s", not connected'#10, [Cmd_Argv(0)]);
    exit;
  end;

  // don't forward the first argument
  if (Cmd_Argc() > 1) then
  begin
    MSG_WriteByte(cls.netchan.message, Byte(clc_stringcmd));
    SZ_Print(cls.netchan.message, Cmd_Args());
  end;
end;

{*
==================
CL_Pause_f
==================
*}
procedure CL_Pause_f; cdecl;
begin
  // never pause in multiplayer
  if (Cvar_VariableValue('maxclients') > 1) or
    (not Boolean(Com_ServerState)) then
  begin
    Cvar_SetValue('paused', 0);
    exit;
  end;
  Cvar_SetValue('paused', Integer(not Boolean(Round(cl_paused.value))));
end;

{*
==================
CL_Quit_f
==================
*}
procedure CL_Quit_f; cdecl;
begin
  CL_Disconnect;
  Com_Quit;
end;

{*
================
CL_Drop

Called after an ERR_DROP was thrown
================
*}
procedure CL_Drop;
begin
  if (cls.state = ca_uninitialized) then
    exit;
  if (cls.state = ca_disconnected) then
    exit;

  CL_Disconnect;

  // drop loading plaque unless this is the initial game start
  if (cls.disable_servercount <> -1) then
    SCR_EndLoadingPlaque;               // get rid of loading plaque
end;

{*
=======================
CL_SendConnectPacket

We have gotten a challenge from the server, so try and
connect.
======================
*}
procedure CL_SendConnectPacket;
var
  adr: netadr_t;
  port: Integer;
begin
  {$IFDEF WIN32}
  if (not NET_StringToAdr(cls.servername, adr)) then
  {$ELSE}
  if (not NET_StringToAdr(cls.servername, @adr)) then
  {$ENDIF}
  begin
    Com_Printf('Bad server address'#10, []);
    cls.connect_time := 0;
    exit;
  end;
  if (adr.port = 0) then
    adr.port := BigShort(PORT_SERVER);

  port := Round(Cvar_VariableValue('qport'));
  userinfo_modified := false;

  Netchan_OutOfBandPrint(NS_CLIENT, adr, 'connect %d %d %d "%s"'#10,
    [PROTOCOL_VERSION, port, cls.challenge, Cvar_Userinfo_()]);
end;

{*
=================
CL_CheckForResend

Resend a connect message if the last one has timed out
=================
*}
procedure CL_CheckForResend;
var
  adr: netadr_t;
begin
  // if the local server is running and we aren't
  // then connect
  if (cls.state = ca_disconnected) and (Com_ServerState() <> 0) then
  begin
    cls.state := ca_connecting;
    strncpy(cls.servername, 'localhost', sizeof(cls.servername) - 1);
    // we don't need a challenge on the localhost
    CL_SendConnectPacket();
    exit;
    // cls.connect_time = -99999;   // CL_CheckForResend() will fire immediately
  end;

  // resend if we haven't gotten a reply yet
  if (cls.state <> ca_connecting) then
    exit;

  if (cls.realtime - cls.connect_time < 3000) then
    exit;

  {$IFDEF WIN32}
  if (not NET_StringToAdr(cls.servername, adr)) then
  {$ELSE}
  if (not NET_StringToAdr(cls.servername, @adr)) then
  {$ENDIF}
  begin
    Com_Printf('Bad server address'#10, []);
    cls.state := ca_disconnected;
    exit;
  end;
  if (adr.port = 0) then
    adr.port := BigShort(PORT_SERVER);

  cls.connect_time := cls.realtime;     // for retransmit requests

  Com_Printf('Connecting to %s...'#10, [cls.servername]);

  Netchan_OutOfBandPrint(NS_CLIENT, adr, 'getchallenge'#10, []);
end;

{*
================
CL_Connect_f

================
*}
procedure CL_Connect_f; cdecl;
var
  server: pchar;
begin
  if (Cmd_Argc() <> 2) then
  begin
    Com_Printf('usage: connect <server>'#10, []);
    exit;
  end;

  if (Com_ServerState <> 0) then
  begin
    // if running a local server, kill it and reissue
    SV_Shutdown(va('Server quit'#10, [msg]), false);
  end
  else
  begin
    CL_Disconnect();
  end;

  server := Cmd_Argv(1);

  NET_Config(true);                     // allow remote

  CL_Disconnect();

  cls.state := ca_connecting;
  strncpy(cls.servername, server, sizeof(cls.servername) - 1);
  cls.connect_time := -99999;           // CL_CheckForResend() will fire immediately
end;

{*
=====================
CL_Rcon_f

  Send the rest of the command line over as
  an unconnected command.
=====================
*}
procedure CL_Rcon_f; cdecl;
var
  message_: array[0..1024 - 1] of char;
  i: Integer;
  to_: netadr_t;
begin
  if (rcon_client_password.string_ = nil) then
  begin
    Com_Printf('You must set ''rcon_password'' before'#10 +
      'issuing an rcon command.'#10, []);
    exit;
  end;

  message_[0] := #255;
  message_[1] := #255;
  message_[2] := #255;
  message_[3] := #255;
  message_[4] := #0;

  NET_Config(true);                     // allow remote

  strcat(message_, 'rcon ');

  strcat(message_, rcon_client_password.string_);
  strcat(message_, ' ');

  for i := 1 to Cmd_Argc() - 1 do
  begin
    strcat(message_, Cmd_Argv(i));
    strcat(message_, ' ');
  end;

  if (cls.state >= ca_connected) then
    to_ := cls.netchan.remote_address
  else
  begin
    if (Length(rcon_address.string_) = 0) then
    begin
      Com_Printf('You must either be connected,'#10 +
        'or set the ''rcon_address'' cvar'#10 +
        'to issue rcon commands'#10);

      exit;
    end;
    {$IFDEF WIN32}
    NET_StringToAdr(rcon_address.string_, to_);
    {$ELSE}
    NET_StringToAdr(rcon_address.string_, @to_);
    {$ENDIF}
    if (to_.port = 0) then
      to_.port := BigShort(PORT_SERVER);
  end;

  NET_SendPacket(NS_CLIENT, strlen(message_) + 1, @message_, to_);
end;

{*
=====================
CL_ClearState

=====================
*}
procedure CL_ClearState;
begin
  S_StopAllSounds();
  CL_ClearEffects();
  CL_ClearTEnts();

  // wipe the entire cl structure
  FillChar(cl, sizeof(cl), #0);
  FillChar(cl_entities, sizeof(cl_entities), #0);

  SZ_Clear(cls.netchan.message);
end;

{*
=====================
CL_Disconnect

Goes from a connected state to full screen console state
Sends a disconnect message to the server
This is also called on Com_Error, so it shouldn't cause any errors
=====================
*}
procedure CL_Disconnect;
var
  final: array[0..32 - 1] of byte;
  time: Integer;
begin
  if (cls.state = ca_disconnected) then
    exit;

  if (cl_timedemo <> nil) and (cl_timedemo.value <> 0) then
  begin
    time := Sys_Milliseconds() - cl.timedemo_start;
    if (time > 0) then
      Com_Printf('%d frames, %3.1f seconds: %3.1f fps'#10, [cl.timedemo_frames,
        time / 1000.0, cl.timedemo_frames * 1000.0 / time]);
  end;

  VectorClear(vec3_p(@cl.refdef.blend)^);
  re.CinematicSetPalette(nil);

  M_ForceMenuOff();

  cls.connect_time := 0;

  SCR_StopCinematic();

  if (cls.demorecording) then
    CL_Stop_f();

  // send a disconnect message to the server
  final[0] := Byte(clc_stringcmd);
  strcpy(@final[1], 'disconnect');
  Netchan_Transmit(cls.netchan, strlen(@final), @final);
  Netchan_Transmit(cls.netchan, strlen(@final), @final);
  Netchan_Transmit(cls.netchan, strlen(@final), @final);

  CL_ClearState();

  // stop download
  if (cls.download > 0) then
  begin
    FileClose(cls.download);
    cls.download := 0;
  end;

  cls.state := ca_disconnected;
end;

procedure CL_Disconnect_f; cdecl;
begin
  Com_Error(ERR_DROP, 'Disconnected from server');
end;

{*
====================
CL_Packet_f

packet <destination> <contents>

Contents allows \n(#10) escape character
====================
*}
procedure CL_Packet_f; cdecl;
var
  send: array[0..2048 - 1] of char;
  i, l: Integer;
  in_, out_: pchar;
  adr: netadr_t;
begin
  if (Cmd_Argc() <> 3) then
  begin
    Com_Printf('packet <destination> <contents>'#10, []);
    exit;
  end;

  NET_Config(true);                     // allow remote

  {$IFDEF WIN32}
  if (not NET_StringToAdr(Cmd_Argv(1), adr)) then
  {$ELSE}
  if (not NET_StringToAdr(Cmd_Argv(1), @adr)) then
  {$ENDIF}
  begin
    Com_Printf('Bad address'#10);
    exit;
  end;

  if (adr.port = 0) then
    adr.port := BigShort(PORT_SERVER);

  in_ := Cmd_Argv(2);
  out_ := send + 4;
  send[0] := #$FF;
  send[1] := #$FF;
  send[2] := #$FF;
  send[3] := #$FF;

  l := strlen(in_);
  for i := 0 to l - 1 do
  begin
    if (in_[i] = '\') and (in_[i + 1] = #10) then
    begin
      out_^ := #10;
      inc(out_);
    end
    else
    begin
      out_^ := in_[i];
      inc(out_);
    end;
  end;
  out_^ := #0;

  NET_SendPacket(NS_CLIENT, longint(out_ - send), @send, adr);
end;

{*
=================
CL_Changing_f

Just sent as a hint to the client that they should
drop to full console
=================
*}
procedure CL_Changing_f; cdecl;
begin
  //ZOID
  //if we are downloading, we don't change!  This so we don't suddenly stop downloading a map
  if (cls.download > 0) then
    exit;

  SCR_BeginLoadingPlaque();
  cls.state := ca_connected;            // not active anymore, but not disconnected
  Com_Printf(#10'Changing map...'#10);
end;

{*
=================
CL_Reconnect_f

The server is changing levels
=================
*}
procedure CL_Reconnect_f; cdecl;
begin
  //ZOID
  //if we are downloading, we don't change!  This so we don't suddenly stop downloading a map
  if (cls.download > 0) then
    exit;

  S_StopAllSounds();
  if (cls.state = ca_connected) then
  begin
    Com_Printf('reconnecting...'#10, []);
    cls.state := ca_connected;
    MSG_WriteChar(cls.netchan.message, Byte(clc_stringcmd));
    MSG_WriteString(cls.netchan.message, 'new');
    exit;
  end;

  if (cls.servername <> nil) then
  begin
    if (cls.state >= ca_connected) then
    begin
      CL_Disconnect();
      cls.connect_time := cls.realtime - 1500;
    end
    else
      cls.connect_time := -99999;       // fire immediately

    cls.state := ca_connecting;
    Com_Printf('reconnecting...'#10, []);
  end;
end;

{*
=================
CL_ParseStatusMessage

Handle a reply from a ping
=================
*}
procedure CL_ParseStatusMessage;
var
  s: pchar;
begin
  s := MSG_ReadString(net_message);

  Com_Printf('%s'#10, [s]);

  M_AddToServerList(net_from, s);
end;

{*
=================
CL_PingServers_f
=================
*}
procedure CL_PingServers_f; cdecl;
var
  i: Integer;
  adr: netadr_t;
  name: array[0..32 - 1] of char;
  adrstring: pchar;
  noudp,
    noipx: cvar_p;
begin
  NET_Config(true);                     // allow remote

  // send a broadcast packet
  Com_Printf('pinging broadcast...'#10, []);

  noudp := Cvar_Get('noudp', '0', CVAR_NOSET);
  if (noudp.value = 0) then
  begin
    adr.type_ := NA_BROADCAST;
    adr.port := BigShort(PORT_SERVER);
    Netchan_OutOfBandPrint(NS_CLIENT, adr, va('info %d', [PROTOCOL_VERSION]), []);
  end;

  noipx := Cvar_Get('noipx', '0', CVAR_NOSET);
  if (noipx.value = 0) then
  begin
    adr.type_ := NA_BROADCAST_IPX;
    adr.port := BigShort(PORT_SERVER);
    Netchan_OutOfBandPrint(NS_CLIENT, adr, va('info %d', [PROTOCOL_VERSION]), []);
  end;

  // send a packet to each address book entry
  for i := 0 to 16 - 1 do
  begin
    Com_sprintf(name, sizeof(name), 'adr%d', [i]);
    adrstring := Cvar_VariableString(name);
    if (adrstring = nil) or (adrstring[0] = #0) then
      continue;

    Com_Printf('pinging %s...'#10, [adrstring]);
    {$IFDEF WIN32}
    if (not NET_StringToAdr(adrstring, adr)) then
    {$ELSE}
    if (not NET_StringToAdr(adrstring, @adr)) then
    {$ENDIF}
    begin
      Com_Printf('Bad address: %s'#10, [adrstring]);
      continue;
    end;
    if (adr.port = 0) then
      adr.port := BigShort(PORT_SERVER);
    Netchan_OutOfBandPrint(NS_CLIENT, adr, va('info %d', [PROTOCOL_VERSION]), []);
  end;
end;

{*
=================
CL_Skins_f

Load or download any custom player skins and models
=================
*}
procedure CL_Skins_f; cdecl;
var
  i: integer;
begin
  for i := 0 to MAX_CLIENTS - 1 do
  begin
    if (cl.configstrings[CS_PLAYERSKINS + i][0] = #0) then
      continue;
    Com_Printf('client %d: %s'#10, [i, cl.configstrings[CS_PLAYERSKINS + i]]);
    SCR_UpdateScreen();
    Sys_SendKeyEvents();                // pump message loop
    CL_ParseClientinfo(i);
  end;
end;

{*
=================
CL_ConnectionlessPacket

Responses to broadcasts, etc
=================
*}
procedure CL_ConnectionlessPacket;
var
  s, c: pchar;
begin
  MSG_BeginReading(net_message);
  MSG_ReadLong(net_message);            // skip the -1

  s := MSG_ReadStringLine(net_message);

  Cmd_TokenizeString(s, false);

  c := Cmd_Argv(0);

  Com_Printf('%s: %s'#10, [NET_AdrToString(net_from), c]);

  // server connection
  if (strcmp(c, 'client_connect') = 0) then
  begin
    if (cls.state = ca_connected) then
    begin
      Com_Printf('Dup connect received.  Ignored.'#10);
      exit;
    end;
    Netchan_Setup(NS_CLIENT, @cls.netchan, net_from, cls.quakePort);
    MSG_WriteChar(cls.netchan.message, Byte(clc_stringcmd));
    MSG_WriteString(cls.netchan.message, 'new');
    cls.state := ca_connected;
    exit;
  end;

  // server responding to a status broadcast
  if (strcmp(c, 'info') = 0) then
  begin
    CL_ParseStatusMessage();
    exit;
  end;

  // remote command from gui front end
  if (strcmp(c, 'cmd') = 0) then
  begin
    if (not NET_IsLocalAddress(net_from)) then
    begin
      Com_Printf('Command packet from remote host.  Ignored.'#10);
      exit;
    end;
    Sys_AppActivate();
    s := MSG_ReadString(net_message);
    Cbuf_AddText(s);
    Cbuf_AddText(#10);
    exit;
  end;
  // print command from somewhere
  if (strcmp(c, 'print') = 0) then
  begin
    s := MSG_ReadString(net_message);
    Com_Printf('%s', [s]);
    exit;
  end;

  // ping from somewhere
  if (strcmp(c, 'ping') = 0) then
  begin
    Netchan_OutOfBandPrint(NS_CLIENT, net_from, 'ack', []);
    exit;
  end;

  // challenge from the server we are connecting to
  if (strcmp(c, 'challenge') = 0) then
  begin
    cls.challenge := StrToInt(Cmd_Argv(1));
    CL_SendConnectPacket();
    exit;
  end;

  // echo request from server
  if (strcmp(c, 'echo') = 0) then
  begin
    Netchan_OutOfBandPrint(NS_CLIENT, net_from, '%s', [Cmd_Argv(1)]);
    exit;
  end;

  Com_Printf('Unknown command.'#10);
end;

{*
=================
CL_DumpPackets

A vain attempt to help bad TCP stacks that cause problems
when they overflow
=================
*}
procedure CL_DumpPackets;
begin
  {$IFDEF WIN32}
  while (NET_GetPacket(NS_CLIENT, net_from, net_message)) do
  {$ELSE}
  while (NET_GetPacket(NS_CLIENT, @net_from, @net_message)) do
  {$ENDIF}
  begin
    Com_Printf('dumping a packet'#10);
  end;
end;

{*
=================
CL_ReadPackets
=================
*}
procedure CL_ReadPackets;
begin
  {$IFDEF WIN32}
  while (NET_GetPacket(NS_CLIENT, net_from, net_message)) do
  {$ELSE}
  while (NET_GetPacket(NS_CLIENT, @net_from, @net_message)) do
  {$ENDIF}
  begin
    //   Com_Printf ("packet"#10);
    //
    // remote command packet
    //
    if (PInteger(net_message.data)^ = -1) then
    begin
      CL_ConnectionlessPacket();
      continue;
    end;

    if (cls.state = ca_disconnected) or (cls.state = ca_connecting) then
      continue;                         // dump it if not connected

    if (net_message.cursize < 8) then
    begin
      Com_Printf('%s: Runt packet'#10, [NET_AdrToString(net_from)]);
      continue;
    end;

    //
    // packet from server
    //
    if (not NET_CompareAdr(net_from, cls.netchan.remote_address)) then
    begin
      Com_DPrintf('%s:sequenced packet without connection'#10
        , [NET_AdrToString(net_from)]);
      continue;
    end;
    if (not Netchan_Process(cls.netchan, net_message)) then
      continue;                         // wasn't accepted for some reason
    CL_ParseServerMessage();
  end;

  //
  // check timeout
  //
  if (cls.state >= ca_connected) and
    (cls.realtime - cls.netchan.last_received > cl_timeout.value * 1000) then
  begin
    Inc(cl.timeoutcount);
    if (cl.timeoutcount > 5) then
    begin                               // timeoutcount saves debugger
      Com_Printf(#10'Server connection timed out.'#10);
      CL_Disconnect();
      exit;
    end;
  end
  else
    cl.timeoutcount := 0;

end;

//=============================================================================

{*
==============
CL_FixUpGender_f
==============
*}
procedure CL_FixUpGender;
var
  p: pchar;
  sk: array[0..80 - 1] of char;
begin
  if (gender_auto.value <> 0) then
  begin
    if (gender.modified) then
    begin
      // was set directly, don't override the user
      gender.modified := false;
      exit;
    end;

    strncpy(sk, skin.string_, sizeof(sk) - 1);
    p := strchr(sk, Byte('/'));
    if (p <> nil) then
      p^ := #0;
    if (Q_stricmp(sk, 'male') = 0) or (Q_stricmp(sk, 'cyborg') = 0) then
      Cvar_Set('gender', 'male')
    else if (Q_stricmp(sk, 'female') = 0) or (Q_stricmp(sk, 'crackhor') = 0) then
      Cvar_Set('gender', 'female')
    else
      Cvar_Set('gender', 'none');
    gender.modified := false;
  end;
end;

{*
==============
CL_Userinfo_f
==============
*}
procedure CL_Userinfo_f; cdecl;
begin
  Com_Printf('User info settings:'#10);
  Info_Print(Cvar_Userinfo_());
end;

{*
=================
CL_Snd_Restart_f

Restart the sound subsystem so it can pick up
new parameters and flush all sounds
=================
*}
procedure CL_Snd_Restart_f; cdecl;
begin
  S_Shutdown();
  S_Init();
  CL_RegisterSounds();
end;

var
  precache_check,                       // for autodownload of precache items
  precache_spawncount,
    precache_tex,
    precache_model_skin: integer;

  precache_model: PByte;                // used for skin checking in alias models

const
  PLAYER_MULT = 5;

  // ENV_CNT is map load, ENV_CNT+1 is first env map
  ENV_CNT = (CS_PLAYERSKINS + MAX_CLIENTS * PLAYER_MULT);
  TEXTURE_CNT = (ENV_CNT + 13);

var
  env_suf: array[0..5] of pchar = ('rt', 'bk', 'lf', 'ft', 'up', 'dn');

procedure CL_RequestNextDownload;
var
  map_checksum: Cardinal;               // for detecting cheater maps
  fn: array[0..MAX_OSPATH - 1] of char;
  pheader: dmdl_p;
  i, n: integer;
  model, skin: array[0..MAX_QPATH - 1] of char;
  p: pchar;
begin
  if (cls.state <> ca_connected) then
    exit;

  if (allow_download.value = 0) and (precache_check < ENV_CNT) then
    precache_check := ENV_CNT;

  //ZOID
  if (precache_check = CS_MODELS) then
  begin                                 // confirm map
    precache_check := CS_MODELS + 2;    // 0 isn't used
    if (allow_download_maps.value <> 0) then
      if (not CL_CheckOrDownloadFile(cl.configstrings[CS_MODELS + 1])) then
        exit;                           // started a download
  end;
  if (precache_check >= CS_MODELS) and (precache_check < CS_MODELS + MAX_MODELS) then
  begin
    if (allow_download_models.value <> 0) then
    begin
      while (precache_check < CS_MODELS + MAX_MODELS) and
        (cl.configstrings[precache_check][0] <> #0) do
      begin
        if (cl.configstrings[precache_check][0] = '*') or
          (cl.configstrings[precache_check][0] = '#') then
        begin
          Inc(precache_check);
          continue;
        end;
        if (precache_model_skin = 0) then
        begin
          if (not CL_CheckOrDownloadFile(cl.configstrings[precache_check])) then
          begin
            precache_model_skin := 1;
            exit;                       // started a download
          end;
          precache_model_skin := 1;
        end;

        // checking for skins in the model
        if (precache_model = nil) then
        begin
          FS_LoadFile(cl.configstrings[precache_check], @precache_model);
          if (precache_model = nil) then
          begin
            precache_model_skin := 0;
            Inc(precache_check);
            continue;                   // couldn't load it
          end;
          if (LittleLong(PCardinal(precache_model)^) <> IDALIASHEADER) then
          begin
            // not an alias model
            FS_FreeFile(precache_model);
            precache_model := nil;
            precache_model_skin := 0;
            Inc(precache_check);
            continue;
          end;
          pheader := dmdl_p(precache_model);
          if (LittleLong(pheader.version) <> ALIAS_VERSION) then
          begin
            Inc(precache_check);
            precache_model_skin := 0;
            continue;                   // couldn't load it
          end;
        end;

        pheader := dmdl_p(precache_model);

        while (precache_model_skin - 1 < LittleLong(pheader.num_skins)) do
        begin
          if (not CL_CheckOrDownloadFile(Pointer(Cardinal(precache_model) +
            LittleLong(pheader.ofs_skins) +
            (precache_model_skin - 1) * MAX_SKINNAME))) then
          begin
            Inc(precache_model_skin);
            exit;                       // started a download
          end;
          Inc(precache_model_skin);
        end;
        if (precache_model <> nil) then
        begin
          FS_FreeFile(precache_model);
          precache_model := nil;
        end;
        precache_model_skin := 0;
        Inc(precache_check);
      end;
    end;
    precache_check := CS_SOUNDS;
  end;

  if (precache_check >= CS_SOUNDS) and (precache_check < CS_SOUNDS + MAX_SOUNDS) then
  begin
    if (allow_download_sounds.value <> 0) then
    begin
      if (precache_check = CS_SOUNDS) then
        Inc(precache_check);            // zero is blank
      while (precache_check < CS_SOUNDS + MAX_SOUNDS) and
        (cl.configstrings[precache_check][0] <> #0) do
      begin
        if (cl.configstrings[precache_check][0] = '*') then
        begin
          Inc(precache_check);
          continue;
        end;
        Com_sprintf(fn, sizeof(fn), 'sound/%s', [cl.configstrings[precache_check]]);
        Inc(precache_check);
        if (not CL_CheckOrDownloadFile(fn)) then
          exit;                         // started a download
      end;
    end;
    precache_check := CS_IMAGES;
  end;

  if (precache_check >= CS_IMAGES) and (precache_check < CS_IMAGES + MAX_IMAGES) then
  begin
    if (precache_check = CS_IMAGES) then
      Inc(precache_check);              // zero is blank
    while (precache_check < CS_IMAGES + MAX_IMAGES) and
      (cl.configstrings[precache_check][0] <> #0) do
    begin
      Com_sprintf(fn, sizeof(fn), 'pics/%s.pcx', [cl.configstrings[precache_check]]);
      Inc(precache_check);
      if (not CL_CheckOrDownloadFile(fn)) then
        exit;                           // started a download
    end;
    precache_check := CS_PLAYERSKINS;
  end;
  // skins are special, since a player has three things to download:
  // model, weapon model and skin
  // so precache_check is now *3
  if (precache_check >= CS_PLAYERSKINS) and (precache_check < CS_PLAYERSKINS + MAX_CLIENTS * PLAYER_MULT) then
  begin
    if (allow_download_players.value <> 0) then
    begin
      while (precache_check < CS_PLAYERSKINS + MAX_CLIENTS * PLAYER_MULT) do
      begin

        i := (precache_check - CS_PLAYERSKINS) div PLAYER_MULT;
        n := (precache_check - CS_PLAYERSKINS) mod PLAYER_MULT;

        if (cl.configstrings[CS_PLAYERSKINS + i][0] = #0) then
        begin
          precache_check := CS_PLAYERSKINS + (i + 1) * PLAYER_MULT;
          continue;
        end;

        p := strchr(cl.configstrings[CS_PLAYERSKINS + i], Byte('\'));
        if (p <> nil) then
          Inc(p)
        else
          p := cl.configstrings[CS_PLAYERSKINS + i];
        strcpy(model, p);
        p := strchr(model, Byte('/'));
        if (p = nil) then
          p := strchr(model, Byte('\'));
        if (p <> nil) then
        begin
          p^ := #0;
          inc(p);
          strcpy(skin, p);
        end
        else
          skin[0] := #0;

        if (n = 0) then
        begin                           // model
          Com_sprintf(fn, sizeof(fn), 'players/%s/tris.md2', [model]);
          if (not CL_CheckOrDownloadFile(fn)) then
          begin
            precache_check := CS_PLAYERSKINS + i * PLAYER_MULT + 1;
            exit;                       // started a download
          end;
          Inc(n);
          {*FALL THROUGH*}
        end;

        if (n = 1) then
        begin                           // weapon model
          Com_sprintf(fn, sizeof(fn), 'players/%s/weapon.md2', [model]);
          if (not CL_CheckOrDownloadFile(fn)) then
          begin
            precache_check := CS_PLAYERSKINS + i * PLAYER_MULT + 2;
            exit;                       // started a download
          end;
          Inc(n);
          {*FALL THROUGH*}
        end;

        if (n = 2) then
        begin                           // weapon skin
          Com_sprintf(fn, sizeof(fn), 'players/%s/weapon.pcx', [model]);
          if (not CL_CheckOrDownloadFile(fn)) then
          begin
            precache_check := CS_PLAYERSKINS + i * PLAYER_MULT + 3;
            exit;                       // started a download
          end;
          Inc(n);
          {*FALL THROUGH*}
        end;

        if (n = 3) then
        begin                           // skin
          Com_sprintf(fn, sizeof(fn), 'players/%s/%s.pcx', [model, skin]);
          if (not CL_CheckOrDownloadFile(fn)) then
          begin
            precache_check := CS_PLAYERSKINS + i * PLAYER_MULT + 4;
            exit;                       // started a download
          end;
          Inc(n);
          {*FALL THROUGH*}
        end;

        if (N = 4) then
        begin                           // skin_i
          Com_sprintf(fn, sizeof(fn), 'players/%s/%s_i.pcx', [model, skin]);
          if (not CL_CheckOrDownloadFile(fn)) then
          begin
            precache_check := CS_PLAYERSKINS + i * PLAYER_MULT + 5;
            exit;                       // started a download
          end;
          // move on to next model
          precache_check := CS_PLAYERSKINS + (i + 1) * PLAYER_MULT;
        end;
      end;
    end;
    // precache phase completed
    precache_check := ENV_CNT;
  end;

  if (precache_check = ENV_CNT) then
  begin
    precache_check := ENV_CNT + 1;

    CM_LoadMap(cl.configstrings[CS_MODELS + 1], true, map_checksum);
    // Note : map_checksum has been typecasted to Integer in the conversion - by burnin
    if (Integer(map_checksum) <> StrToInt(cl.configstrings[CS_MAPCHECKSUM])) then
    begin
      Com_Error(ERR_DROP, 'Local map version differs from server: %d != ''%s'''#10,
        [map_checksum, cl.configstrings[CS_MAPCHECKSUM]]);
      exit;
    end;
  end;

  if (precache_check > ENV_CNT) and (precache_check < TEXTURE_CNT) then
  begin
    if (allow_download.value <> 0) and (allow_download_maps.value <> 0) then
    begin
      while (precache_check < TEXTURE_CNT) do
      begin
        n := precache_check - ENV_CNT - 1;
        Inc(precache_check);
        if ((n and 1) <> 0) then
          Com_sprintf(fn, sizeof(fn), 'env/%s%s.pcx',
            [cl.configstrings[CS_SKY], env_suf[n div 2]])
        else
          Com_sprintf(fn, sizeof(fn), 'env/%s%s.tga',
            [cl.configstrings[CS_SKY], env_suf[n div 2]]);
        if (not CL_CheckOrDownloadFile(fn)) then
          exit;                         // started a download
      end;
    end;
    precache_check := TEXTURE_CNT;
  end;

  if (precache_check = TEXTURE_CNT) then
  begin
    precache_check := TEXTURE_CNT + 1;
    precache_tex := 0;
  end;

  // confirm existance of textures, download any that don't exist
  if (precache_check = TEXTURE_CNT + 1) then
  begin

    if (allow_download.value <> 0) and (allow_download_maps.value <> 0) then
    begin
      while (precache_tex < numtexinfo) do
      begin
        Com_sprintf(fn, sizeof(fn), 'textures/%s.wal', [map_surfaces[precache_tex].rname]);
        Inc(precache_tex);
        if (not CL_CheckOrDownloadFile(fn)) then
          exit;                         // started a download
      end;
    end;
    precache_check := TEXTURE_CNT + 999;
  end;

  //ZOID
  CL_RegisterSounds();
  CL_PrepRefresh();

  MSG_WriteByte(cls.netchan.message, Byte(clc_stringcmd));
  MSG_WriteString(cls.netchan.message, va('begin %d'#10, [precache_spawncount]));
end;

{*
=================
CL_Precache_f

The server will send this command right
before allowing the client into the server
=================
*}
procedure CL_Precache_f; cdecl;
var
  map_checksum: Cardinal;               // for detecting cheater maps
begin
  //Yet another hack to let old demos work
  //the old precache sequence
  if (Cmd_Argc() < 2) then
  begin
    CM_LoadMap(cl.configstrings[CS_MODELS + 1], true, map_checksum);
    CL_RegisterSounds();
    CL_PrepRefresh();
    exit;
  end;

  precache_check := CS_MODELS;
  precache_spawncount := StrToInt(Cmd_Argv(1));
  precache_model := nil;
  precache_model_skin := 0;

  CL_RequestNextDownload();
end;

{*
=================
CL_InitLocal
=================
*}
procedure CL_InitLocal;
begin
  cls.state := ca_disconnected;
  cls.realtime := Sys_Milliseconds();

  CL_InitInput();

  adr0 := Cvar_Get('adr0', '', CVAR_ARCHIVE);
  adr1 := Cvar_Get('adr1', '', CVAR_ARCHIVE);
  adr2 := Cvar_Get('adr2', '', CVAR_ARCHIVE);
  adr3 := Cvar_Get('adr3', '', CVAR_ARCHIVE);
  adr4 := Cvar_Get('adr4', '', CVAR_ARCHIVE);
  adr5 := Cvar_Get('adr5', '', CVAR_ARCHIVE);
  adr6 := Cvar_Get('adr6', '', CVAR_ARCHIVE);
  adr7 := Cvar_Get('adr7', '', CVAR_ARCHIVE);
  adr8 := Cvar_Get('adr8', '', CVAR_ARCHIVE);

  //
  // register our variables
  //
  cl_stereo_separation := Cvar_Get('cl_stereo_separation', '0.4', CVAR_ARCHIVE);
  cl_stereo := Cvar_Get('cl_stereo', '0', 0);

  cl_add_blend := Cvar_Get('cl_blend', '1', 0);
  cl_add_lights := Cvar_Get('cl_lights', '1', 0);
  cl_add_particles := Cvar_Get('cl_particles', '1', 0);
  cl_add_entities := Cvar_Get('cl_entities', '1', 0);
  cl_gun := Cvar_Get('cl_gun', '1', 0);
  cl_footsteps := Cvar_Get('cl_footsteps', '1', 0);
  cl_noskins := Cvar_Get('cl_noskins', '0', 0);
  cl_autoskins := Cvar_Get('cl_autoskins', '0', 0);
  cl_predict := Cvar_Get('cl_predict', '1', 0);
  //   cl_minfps := Cvar_Get ('cl_minfps', '5', 0);
  cl_maxfps := Cvar_Get('cl_maxfps', '90', 0);

  cl_upspeed := Cvar_Get('cl_upspeed', '200', 0);
  cl_forwardspeed := Cvar_Get('cl_forwardspeed', '200', 0);
  cl_sidespeed := Cvar_Get('cl_sidespeed', '200', 0);
  cl_yawspeed := Cvar_Get('cl_yawspeed', '140', 0);
  cl_pitchspeed := Cvar_Get('cl_pitchspeed', '150', 0);
  cl_anglespeedkey := Cvar_Get('cl_anglespeedkey', '1.5', 0);

  cl_run := Cvar_Get('cl_run', '0', CVAR_ARCHIVE);
  freelook := Cvar_Get('freelook', '0', CVAR_ARCHIVE);
  lookspring := Cvar_Get('lookspring', '0', CVAR_ARCHIVE);
  lookstrafe := Cvar_Get('lookstrafe', '0', CVAR_ARCHIVE);
  sensitivity := Cvar_Get('sensitivity', '3', CVAR_ARCHIVE);

  m_pitch := Cvar_Get('m_pitch', '0.022', CVAR_ARCHIVE);
  m_yaw := Cvar_Get('m_yaw', '0.022', 0);
  m_forward := Cvar_Get('m_forward', '1', 0);
  m_side := Cvar_Get('m_side', '1', 0);

  cl_shownet := Cvar_Get('cl_shownet', '0', 0);
  cl_showmiss := Cvar_Get('cl_showmiss', '0', 0);
  cl_showclamp := Cvar_Get('showclamp', '0', 0);
  cl_timeout := Cvar_Get('cl_timeout', '120', 0);
  cl_paused := Cvar_Get('paused', '0', 0);
  cl_timedemo := Cvar_Get('timedemo', '0', 0);

  rcon_client_password := Cvar_Get('rcon_password', '', 0);
  rcon_address := Cvar_Get('rcon_address', '', 0);

  cl_lightlevel := Cvar_Get('r_lightlevel', '0', 0);

  //
  // userinfo
  //
  info_password := Cvar_Get('password', '', CVAR_USERINFO);
  info_spectator := Cvar_Get('spectator', '0', CVAR_USERINFO);
  name := Cvar_Get('name', 'unnamed', CVAR_USERINFO or CVAR_ARCHIVE);
  skin := Cvar_Get('skin', 'male/grunt', CVAR_USERINFO or CVAR_ARCHIVE);
  rate := Cvar_Get('rate', '25000', CVAR_USERINFO or CVAR_ARCHIVE); // FIXME
  msg := Cvar_Get('msg', '1', CVAR_USERINFO or CVAR_ARCHIVE);
  hand := Cvar_Get('hand', '0', CVAR_USERINFO or CVAR_ARCHIVE);
  fov := Cvar_Get('fov', '90', CVAR_USERINFO or CVAR_ARCHIVE);
  gender := Cvar_Get('gender', 'male', CVAR_USERINFO or CVAR_ARCHIVE);
  gender_auto := Cvar_Get('gender_auto', '1', CVAR_ARCHIVE);
  gender.modified := false;             // clear this so we know when user sets it manually

  cl_vwep := Cvar_Get('cl_vwep', '1', CVAR_ARCHIVE);

  //
  // register our commands
  //
  Cmd_AddCommand('cmd', CL_ForwardToServer_f);
  Cmd_AddCommand('pause', CL_Pause_f);
  Cmd_AddCommand('pingservers', CL_PingServers_f);
  Cmd_AddCommand('skins', CL_Skins_f);

  Cmd_AddCommand('userinfo', CL_Userinfo_f);
  Cmd_AddCommand('snd_restart', CL_Snd_Restart_f);

  Cmd_AddCommand('changing', CL_Changing_f);
  Cmd_AddCommand('disconnect', CL_Disconnect_f);
  Cmd_AddCommand('record', CL_Record_f);
  Cmd_AddCommand('stop', CL_Stop_f);

  Cmd_AddCommand('quit', CL_Quit_f);

  Cmd_AddCommand('connect', CL_Connect_f);
  Cmd_AddCommand('reconnect', CL_Reconnect_f);

  Cmd_AddCommand('rcon', CL_Rcon_f);

  //    Cmd_AddCommand ('packet', CL_Packet_f); // this is dangerous to leave in

  Cmd_AddCommand('setenv', CL_Setenv_f);

  Cmd_AddCommand('precache', CL_Precache_f);

  Cmd_AddCommand('download', CL_Download_f);

  //
  // forward to server commands
  //
  // the only thing this does is allow command completion
  // to work -- all unknown commands are automatically
  // forwarded to the server
  Cmd_AddCommand('wave', nil);
  Cmd_AddCommand('inven', nil);
  Cmd_AddCommand('kill', nil);
  Cmd_AddCommand('use', nil);
  Cmd_AddCommand('drop', nil);
  Cmd_AddCommand('say', nil);
  Cmd_AddCommand('say_team', nil);
  Cmd_AddCommand('info', nil);
  Cmd_AddCommand('prog', nil);
  Cmd_AddCommand('give', nil);
  Cmd_AddCommand('god', nil);
  Cmd_AddCommand('notarget', nil);
  Cmd_AddCommand('noclip', nil);
  Cmd_AddCommand('invuse', nil);
  Cmd_AddCommand('invprev', nil);
  Cmd_AddCommand('invnext', nil);
  Cmd_AddCommand('invdrop', nil);
  Cmd_AddCommand('weapnext', nil);
  Cmd_AddCommand('weapprev', nil);
end;

{*
===============
CL_WriteConfiguration

Writes key bindings and archived cvars to config.cfg
===============
*}
procedure CL_WriteConfiguration;
const
  FILEGENTAG = '// generated by quake, do not modify'#10;
var
  f: integer;
  path: array[0..MAX_QPATH - 1] of char;
begin
  if (cls.state = ca_uninitialized) then
    exit;

  Com_sprintf(path, sizeof(path), '%s/config.cfg', [FS_Gamedir()]);

  if FileExists(path) then
    DeleteFile(path);
  f := FileCreate(path);
  if (f = -1) then
  begin
    Com_Printf('Couldn''t write config.cfg.'#10);
    exit;
  end;

  FileWrite(f, FILEGENTAG, length(FILEGENTAG));
  Key_WriteBindings(f);
  FileClose(f);

  Cvar_WriteVariables(path);
end;

{*
==================
CL_FixCvarCheats

==================
*}
type
  cheatvar_p = ^cheatvar_t;
  cheatvar_t = record
    name: pchar;
    value: pchar;
    var_: cvar_p;
  end;

var
  cheatvars: array[0..11] of cheatvar_t = (
    (name: 'timescale'; value: '1'; var_: nil),
    (name: 'timedemo'; value: '0'; var_: nil),
    (name: 'r_drawworld'; value: '1'; var_: nil),
    (name: 'cl_testlights'; value: '0'; var_: nil),
    (name: 'r_fullbright'; value: '0'; var_: nil),
    (name: 'r_drawflat'; value: '0'; var_: nil),
    (name: 'paused'; value: '0'; var_: nil),
    (name: 'fixedtime'; value: '0'; var_: nil),
    (name: 'sw_draworder'; value: '0'; var_: nil),
    (name: 'gl_lightmap'; value: '0'; var_: nil),
    (name: 'gl_saturatelighting'; value: '0'; var_: nil),
    (name: nil; value: nil; var_: nil)
    );

  numcheatvars: integer;

procedure CL_FixCvarCheats;
var
  i: Integer;
  var_: cheatvar_p;
begin
  if (strcmp(cl.configstrings[CS_MAXCLIENTS], '1') = 0) or
    (cl.configstrings[CS_MAXCLIENTS][0] = #0) then
    exit;                               // single player can cheat

  // find all the cvars if we haven't done it yet
  if (numcheatvars = 0) then
  begin
    while (cheatvars[numcheatvars].name <> nil) do
    begin
      cheatvars[numcheatvars].var_ := Cvar_Get(cheatvars[numcheatvars].name,
        cheatvars[numcheatvars].value, 0);
      Inc(numcheatvars);
    end;
  end;

  // make sure they are all set to the proper values
  i := 0;
  var_ := @cheatvars;
  while (i < numcheatvars) do
  begin
    if (strcmp(var_.var_.string_, var_.value)) <> 0 then
    begin
      Cvar_Set(var_.name, var_.value);
    end;
    Inc(i);
    Inc(Var_);
  end;
end;

//============================================================================

{*
==================
CL_SendCommand

==================
*}
procedure CL_SendCommand;
begin
  // get new key events
  Sys_SendKeyEvents();

  // allow mice or other external controllers to add commands
  IN_Commands();

  // process console commands
  Cbuf_Execute();

  // fix any cheating cvars
  CL_FixCvarCheats();

  // send intentions now
  CL_SendCmd();

  // resend a connection request if necessary
  CL_CheckForResend();
end;

{*
==================
CL_Frame

==================
*}
var
  extratime: integer;
  lasttimecalled: integer;

procedure CL_Frame(msec: Integer);
var
  now_: integer;
  tmp: string;
begin
  if (dedicated.value <> 0) then
    exit;

  extratime := extratime + msec;

  if (cl_timedemo.value = 0) then
  begin
    if (cls.state = ca_connected) and (extratime < 100) then
      exit;                             // don't flood packets out while connecting
    if (extratime < 1000 / cl_maxfps.value) then
      exit;                             // framerate is too high
  end;

  // let the mouse activate or deactivate
  IN_Frame();

  // decide the simulation time
  cls.frametime := extratime / 1000.0;
  cl.time := cl.time + extratime;
  cls.realtime := curtime;

  extratime := 0;
  {
   if (cls.frametime > (1.0 / cl_minfps.value))
    cls.frametime = (1.0 / cl_minfps.value);
  }
  if (cls.frametime > (1.0 / 5)) then
    cls.frametime := (1.0 / 5);

  // if in the debugger last frame, don't timeout
  if (msec > 5000) then
    cls.netchan.last_received := Sys_Milliseconds();

  // fetch results from server
  CL_ReadPackets();

  // send a new command message to the server
  CL_SendCommand();

  // predict all unacknowledged movements
  CL_PredictMovement();

  // allow rendering DLL change
  VID_CheckChanges();
  if (not cl.refresh_prepped) and (cls.state = ca_active) then
    CL_PrepRefresh();

  // update the screen
  if (host_speeds.value <> 0) then
    time_before_ref := Sys_Milliseconds();
  SCR_UpdateScreen();
  if (host_speeds.value <> 0) then
    time_after_ref := Sys_Milliseconds();

  // update audio
  S_Update(vec3_t(cl.refdef.vieworg), cl.v_forward, cl.v_right, cl.v_up);

  CDAudio_Update();

  // advance local effects for next frame
  CL_RunDLights();
  CL_RunLightStyles();
  SCR_RunCinematic();
  SCR_RunConsole();

  Inc(cls.framecount);

  if (log_stats.value <> 0) then
  begin
    if (cls.state = ca_active) then
    begin
      if (lasttimecalled = 0) then
      begin
        lasttimecalled := Sys_Milliseconds();
        if (log_stats_file <> 0) then
          FileWrite(log_stats_file, '0'#10, 2);
      end
      else
      begin
        now_ := Sys_Milliseconds();

        if (log_stats_file <> 0) then
        begin
          tmp := Format('%d'#10, [now_ - lasttimecalled]);
          FileWrite(log_stats_file, tmp[1], length(tmp));
        end;
        lasttimecalled := now_;
      end;
    end;
  end;
end;

//============================================================================

{*
====================
CL_Init
====================
*}
procedure CL_Init;
begin
  if (dedicated.value <> 0) then
    exit;                               // nothing running on the client

  // all archived variables will now be loaded

  Con_Init();
{$IFDEF LINUX}
  S_Init();
  VID_Init();
{$ELSE}
  VID_Init();
  S_Init();                             // sound must be initialized after window is created
{$ENDIF}

  V_Init();

  net_message.data := @net_message_buffer;
  net_message.maxsize := sizeof(net_message_buffer);

  M_Init();

  SCR_Init();
  cls.disable_screen := Integer(true);  // don't draw yet

  CDAudio_Init();
  CL_InitLocal();
  IN_Init();

  //   Cbuf_AddText ("exec autoexec.cfg"#10);
  FS_ExecAutoexec();
  Cbuf_Execute();

  {
    Juha:
    Quake2 -> Delphi conversion project was initially started by Jan Horn.
    Jan Horn died in car accident in year 2002. This project is dedicated
    to loving memory of Jan Horn.
  }
  SCR_CenterPrint('Quake ][ Delphi/Freepascal conversion'         +
               #10'dedicated to loving memory of Jan Horn..'      +
               #10#10'Delphi port'                                +
               #10'http://www.sulaco.co.za'                       +
               #10#10'Freepascal port:'                           +
               #10'http://z505.com')                              

end;

{*
===============
CL_Shutdown

FIXME: this is a callback from Sys_Quit and Com_Error.  It would be better
to run quit through here before the final handoff to the sys code.
===============
*}
var
  isdown: qboolean = false;

procedure CL_Shutdown;
begin
  if (isdown) then
  begin
    Com_printf('recursive shutdown'#10);
    exit;
  end;
  isdown := true;

  CL_WriteConfiguration();

  CDAudio_Shutdown();
  S_Shutdown();
  IN_Shutdown();
  VID_Shutdown();
end;

end.
