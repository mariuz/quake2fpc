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
{ File(s): qcommon.h (part), Common.c                                        }
{ Content: Quake2\QCommon\ common routines                                   }
{                                                                            }
{ Initial conversion by : Clootie (Alexey Barkovoy) - clootie@reactor.ru     }
{ Initial conversion on : 19-Jan-2002                                        }
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
{ 1) 25-Feb-2002 - Clootie (clootie@reactor.ru)                              }
{    Some clean up of external dependencies.                                 }
{ 3) 03-Mar-2002 - Clootie (clootie@reactor.ru)                              }
{    Compatibility with new g_local.                                         }
{                                                                            }
{----------------------------------------------------------------------------}

{.$DEFINE PARANOID}//Clootie: just to debug

// qcommon.h -- definitions common between client and server, but not game.dll
{$IFDEF WIN32}
  {$INCLUDE ..\Jedi.inc}
{$ELSE}
  {$INCLUDE ../Jedi.inc}
{$ENDIF}

unit Common;

interface

uses
  SysUtils,
  q_shared,
  q_shared_add,
  CVar
{$IFNDEF COMPILER6_UP}
{$IFDEF WIN32}
  ,Windows
{$ENDIF}
{$ENDIF};

const
  VERSION = 3.21;

  //Clootie: This is substitute for C predefined macro
  __DATE__ = '01 Feb 2002';

  BASEDIRNAME = 'baseq2';

{$IFDEF WIN32}
const
{$IFNDEF DEBUG}
  BUILDSTRING = 'Win32 RELEASE';
{$ELSE}
  BUILDSTRING = 'Win32 DEBUG';
{$ENDIF}

const
  CPUSTRING = 'i386';

{$ENDIF}

{$IFDEF LINUX}
const
  BUILDSTRING = 'Linux';

const
  CPUSTRING = 'i386';
{$ENDIF}

  //============================================================================

type
  sizebuf_p = ^sizebuf_t;
  sizebuf_s = record
    allowoverflow: qboolean;            // if false, do a Com_Error
    overflowed: qboolean;               // set to true if the buffer size failed
    data: PByteArray;
    maxsize: Integer;
    cursize: Integer;
    readcount: Integer;
  end;
  sizebuf_t = sizebuf_s;

procedure SZ_Init(var buf: sizebuf_t; data: PByte; length: Integer);
procedure SZ_Clear(var buf: sizebuf_t);
function SZ_GetSpace(var buf: sizebuf_t; length: Integer): Pointer;
procedure SZ_Write(var buf: sizebuf_t; data: Pointer; length: Integer);
procedure SZ_Print(var buf: sizebuf_t; data: PChar); // strcats onto the sizebuf

//============================================================================

procedure MSG_WriteChar(var sb: sizebuf_t; c: ShortInt);
procedure MSG_WriteByte(var sb: sizebuf_t; c: Integer);
procedure MSG_WriteShort(var sb: sizebuf_t; c: Integer);
procedure MSG_WriteLong(var sb: sizebuf_t; c: Integer);
procedure MSG_WriteFloat(var sb: sizebuf_t; f: Single);
procedure MSG_WriteString(var sb: sizebuf_t; s: PChar);
procedure MSG_WriteCoord(var sb: sizebuf_t; f: Single);
procedure MSG_WritePos(var sb: sizebuf_t; const pos: vec3_t);
procedure MSG_WriteAngle(var sb: sizebuf_t; f: Single);
procedure MSG_WriteAngle16(var sb: sizebuf_t; f: Single);
procedure MSG_WriteDeltaUsercmd(var buf: sizebuf_t; const from: usercmd_t; const cmd: usercmd_t);
procedure MSG_WriteDeltaEntity(const from, to_: entity_state_t; var msg: sizebuf_t; force, newentity: qboolean);
procedure MSG_WriteDir(var sb: sizebuf_t; dir: vec3_p);

procedure MSG_BeginReading(var sb: sizebuf_t);

function MSG_ReadChar(var msg_read: sizebuf_t): ShortInt;
function MSG_ReadByte(var msg_read: sizebuf_t): Integer;
function MSG_ReadShort(var msg_read: sizebuf_t): Integer;
function MSG_ReadLong(var msg_read: sizebuf_t): Integer;
function MSG_ReadFloat(var msg_read: sizebuf_t): Single;
function MSG_ReadString(var msg_read: sizebuf_t): PChar;
function MSG_ReadStringLine(var msg_read: sizebuf_t): PChar;

function MSG_ReadCoord(var msg_read: sizebuf_t): Single;
procedure MSG_ReadPos(var msg_read: sizebuf_t; var pos: vec3_t);
function MSG_ReadAngle(var msg_read: sizebuf_t): Single;
function MSG_ReadAngle16(var msg_read: sizebuf_t): Single;
procedure MSG_ReadDeltaUsercmd(var msg_read: sizebuf_t; const from: usercmd_t; var move: usercmd_t);

procedure MSG_ReadDir(var sb: sizebuf_t; var dir: vec3_t);

procedure MSG_ReadData(var msg_read: sizebuf_t; data: Pointer; len: Integer);

const
  MAX_NUM_ARGVS = 50;

type
  //Clootie: Object Pascal introduced types
  PComArgvArray = ^TComArgvArray;
  TComArgvArray = array[0..MAX_NUM_ARGVS] of PChar;

function COM_Argc: Integer;
function COM_Argv(arg: Integer): PChar; // range and null checked
procedure COM_ClearArgv(arg: Integer);
function COM_CheckParm(parm: PChar): Integer;
procedure COM_AddParm(parm: PChar);

// procedure COM_Init; //Clootie: Not used in source base...
procedure COM_InitArgv(argc: Integer; argv: PComArgvArray);

function CopyString(in_: PChar): PChar;

//============================================================================

procedure Info_Print(s: PChar);

{*
==============================================================

PROTOCOL

==============================================================
*}

// protocol.h -- communications protocols
const
  PROTOCOL_VERSION = 34;

  //=========================================

  PORT_MASTER = 27900;
  PORT_CLIENT = 27901;
  PORT_SERVER = 27910;

  //=========================================

  UPDATE_BACKUP = 16;                   // copies of entity_state_t to keep buffered
  // must be power of two
  UPDATE_MASK = (UPDATE_BACKUP - 1);

  //==================
  // the svc_strings[] array in cl_parse.c should mirror this
  //==================

  //
  // server to client
  //
type
  svc_ops_e = (
    svc_bad,

    // these ops are known to the game dll
    svc_muzzleflash,
    svc_muzzleflash2,
    svc_temp_entity,
    svc_layout,
    svc_inventory,

    // the rest are private to the client and server
    svc_nop,
    svc_disconnect,
    svc_reconnect,
    svc_sound,                          // <see code>
    svc_print,                          // [byte] id [string] null terminated string
    svc_stufftext,                      // [string] stuffed into client's console buffer, should be \n(#10) terminated
    svc_serverdata,                     // [long] protocol ...
    svc_configstring,                   // [short] [string]
    svc_spawnbaseline,
    svc_centerprint,                    // [string] to put in center of the screen
    svc_download,                       // [short] size [size bytes]
    svc_playerinfo,                     // variable
    svc_packetentities,                 // [...]
    svc_deltapacketentities,            // [...]
    svc_frame
    );

  //==============================================

  //
  // client to server
  //
  clc_ops_e = (
    clc_bad,
    clc_nop,
    clc_move,                           // [[usercmd_t]
    clc_userinfo,                       // [[userinfo string]
    clc_stringcmd                       // [string] message
    );

  //==============================================

  // plyer_state_t communication
const
  PS_M_TYPE = (1 shl 0);
  PS_M_ORIGIN = (1 shl 1);
  PS_M_VELOCITY = (1 shl 2);
  PS_M_TIME = (1 shl 3);
  PS_M_FLAGS = (1 shl 4);
  PS_M_GRAVITY = (1 shl 5);
  PS_M_DELTA_ANGLES = (1 shl 6);

  PS_VIEWOFFSET = (1 shl 7);
  PS_VIEWANGLES = (1 shl 8);
  PS_KICKANGLES = (1 shl 9);
  PS_BLEND = (1 shl 10);
  PS_FOV = (1 shl 11);
  PS_WEAPONINDEX = (1 shl 12);
  PS_WEAPONFRAME = (1 shl 13);
  PS_RDFLAGS = (1 shl 14);

  //==============================================

  // user_cmd_t communication

  // ms and light always sent, the others are optional
  CM_ANGLE1 = (1 shl 0);
  CM_ANGLE2 = (1 shl 1);
  CM_ANGLE3 = (1 shl 2);
  CM_FORWARD = (1 shl 3);
  CM_SIDE = (1 shl 4);
  CM_UP = (1 shl 5);
  CM_BUTTONS = (1 shl 6);
  CM_IMPULSE = (1 shl 7);

  //==============================================

  // a sound without an ent or pos will be a local only sound
  SND_VOLUME = (1 shl 0);               // a byte
  SND_ATTENUATION = (1 shl 1);          // a byte
  SND_POS = (1 shl 2);                  // three coordinates
  SND_ENT = (1 shl 3);                  // a short 0-2: channel, 3-12: entity
  SND_OFFSET = (1 shl 4);               // a byte, msec offset from frame start

  DEFAULT_SOUND_PACKET_VOLUME = 1.0;
  DEFAULT_SOUND_PACKET_ATTENUATION = 1.0;

  //==============================================

  // entity_state_t communication

  // try to pack the common update flags into the first byte
  U_ORIGIN1 = (1 shl 0);
  U_ORIGIN2 = (1 shl 1);
  U_ANGLE2 = (1 shl 2);
  U_ANGLE3 = (1 shl 3);
  U_FRAME8 = (1 shl 4);                 // frame is a byte
  U_EVENT = (1 shl 5);
  U_REMOVE = (1 shl 6);                 // REMOVE this entity, don't add it
  U_MOREBITS1 = (1 shl 7);              // read one additional byte

  // second byte
  U_NUMBER16 = (1 shl 8);               // NUMBER8 is implicit if not set
  U_ORIGIN3 = (1 shl 9);
  U_ANGLE1 = (1 shl 10);
  U_MODEL = (1 shl 11);
  U_RENDERFX8 = (1 shl 12);             // fullbright, etc
  U_EFFECTS8 = (1 shl 14);              // autorotate, trails, etc
  U_MOREBITS2 = (1 shl 15);             // read one additional byte

  // third byte
  U_SKIN8 = (1 shl 16);
  U_FRAME16 = (1 shl 17);               // frame is a short
  U_RENDERFX16 = (1 shl 18);            // 8 + 16 = 32
  U_EFFECTS16 = (1 shl 19);             // 8 + 16 = 32
  U_MODEL2 = (1 shl 20);                // weapons, flags, etc
  U_MODEL3 = (1 shl 21);
  U_MODEL4 = (1 shl 22);
  U_MOREBITS3 = (1 shl 23);             // read one additional byte

  // fourth byte
  U_OLDORIGIN = (1 shl 24);             // FIXME: get rid of this
  U_SKIN16 = (1 shl 25);
  U_SOUND = (1 shl 26);
  U_SOLID = (1 shl 27);

  {*
  ==============================================================

  NET

  ==============================================================
  *}

  // net.h -- quake's interface to the networking layer

const
  PORT_ANY = -1;

  MAX_MSGLEN = 1400;                    // max length of a message
  PACKET_HEADER = 10;                   // two ints and a short

type
  netadrtype_t = (NA_LOOPBACK, NA_BROADCAST, NA_IP, NA_IPX, NA_BROADCAST_IPX);

  netsrc_t = (NS_CLIENT, NS_SERVER);

  netadr_p = ^netadr_t;
  netadr_t = record
    type_: netadrtype_t;
    ip: array[0..3] of Byte;
    ipx: array[0..9] of Byte;

    port: Word;
  end;

  //============================================================================
const
  OLD_AVG = 0.99;                       // total = oldtotal*OLD_AVG + new*(1-OLD_AVG)

  MAX_LATENT = 32;

type
  netchan_p = ^netchan_t;
  netchan_t = record
    fatal_error: qboolean;

    sock: netsrc_t;

    dropped: Integer;                   // between last packet and previous

    last_received: Integer;             // for timeouts
    last_sent: Integer;                 // for retransmits

    remote_address: netadr_t;
    qport: Integer;                     // qport value to write when transmitting

    // sequencing variables
    incoming_sequence: Integer;
    incoming_acknowledged: Integer;
    incoming_reliable_acknowledged: Integer; // single bit

    incoming_reliable_sequence: Integer; // single bit, maintained local

    outgoing_sequence: Integer;
    reliable_sequence: Integer;         // single bit
    last_reliable_sequence: Integer;    // sequence number of last send

    // reliable staging and holding areas
    message: sizebuf_t;                 // writing buffer to send to server
    message_buf: array[0..MAX_MSGLEN - 16 - 1] of Byte; // leave space for header

    // message is copied to this buffer when it is first transfered
    reliable_length: Integer;
    reliable_buf: array[0..MAX_MSGLEN - 16 - 1] of Byte; // unacked reliable message
  end;

{*
==============================================================

MISC

==============================================================
*}

const
  ERR_FATAL = 0;                        // exit the entire game with a popup window
  ERR_DROP = 1;                         // print to console and disconnect from game
  ERR_QUIT = 2;                         // not an error, just a normal exit

  EXEC_NOW = 0;                         // don't return until completed
  EXEC_INSERT = 1;                      // insert at current position, but don't run yet
  EXEC_APPEND = 2;                      // add to end of the command buffer

  PRINT_ALL = 0;
  PRINT_DEVELOPER = 1;                  // only print when "developer 1"

type
  rd_flush_proc = procedure(target: Integer; buffer: PChar);

procedure Com_BeginRedirect(target: Integer; buffer: PChar; buffersize: Integer; flush: rd_flush_proc);
procedure Com_EndRedirect;
procedure Com_Printf(fmt: PChar; args: array of const); overload;
procedure Com_DPrintf(fmt: PChar; args: array of const); overload;
procedure Com_Error(code: Integer; fmt: PChar; args: array of const); overload;
procedure Com_Printf(fmt: PChar); overload;
procedure Com_DPrintf(fmt: PChar); overload;
procedure Com_Error(code: Integer; fmt: PChar); overload;
procedure Com_Quit; cdecl;

function Com_ServerState: Integer;      // this should have just been a cvar...
procedure Com_SetServerState(state: Integer);

// function Com_BlockChecksum(buffer: Pointer; length: Integer): Cardinal; // in md4.pas
function COM_BlockSequenceCRCByte(base: PByte; length, sequence: Integer): Byte;

function rand: Integer;                 // 0 to $7FFF
function frand: Single;                 // 0 to 1
function crand: Single;                 // -1 to 1
function fmod(x, y: Single): Single;

var
  developer: cvar_p;
  dedicated: cvar_p;
  host_speeds: cvar_p;
  log_stats: cvar_p;

  log_stats_file: integer;

  // host_speeds times
var
  time_before_game: Integer;
  time_after_game: Integer;
  time_before_ref: Integer;
  time_after_ref: Integer;

procedure Z_Free(ptr: Pointer); cdecl;
function Z_Malloc(size: Integer): Pointer; cdecl; // returns 0 filled memory
function Z_TagMalloc(size: Integer; tag: Integer): Pointer; cdecl;
procedure Z_FreeTags(tag: Integer); cdecl;

procedure Qcommon_Init(argc: Integer; argv: PComArgvArray);
procedure Qcommon_Frame(msec: Integer);
procedure Qcommon_Shutdown;

const
  NUMVERTEXNORMALS = 162;
var
  bytedirs: array[0..NUMVERTEXNORMALS - 1] of vec3_t = (
  {$IFDEF WIN32}
  {$INCLUDE '..\client\anorms.inc'}
  {$ELSE}
  {$INCLUDE '../client/anorms.inc'}
  {$ENDIF}
    );

  //todo: Don't know what to do
  {*
  // this is in the client code, but can be used for debugging from server
  void SCR_DebugGraph (float value, int color); *}

var
  //todo: Clootie: do we really need this variable at all
  realtime: Integer;

implementation

uses
  Files,
  crc,
  cmd,
  net_chan,
  cl_main,
  sv_main,
  cl_scrn,
  CModel
{$IFDEF WIN32}
  ,
  net_Wins,
  q_shwin,
  sys_win
{$ENDIF}
{$IFDEF LINUX}
  ,
  net_udp,
  sys_linux,
  q_shlinux
{$ENDIF}
  ,
  Console,
  Keys,
  CPas;

// common.c -- misc functions used in client and server

const
  MAXPRINTMSG = 4096;
  // MAX_NUM_ARGVS   = 50; //Clootie: Declared in interface part

var
  com_argc_: Integer;
  com_argv_: TComArgvArray;             // array[0..MAX_NUM_ARGVS] of PChar;

  //Clootie: "abortframe" is used in C for exception alike handling with
  // "setjmp" and "longjmp" functions -> is replaced in ObjectPascal by exceptions
  //  abortframe: jmp_buf;      // an ERR_DROP occured, exit the entire frame
type
  ELongJump = Exception;

var
  timescale: cvar_p;
  fixedtime: cvar_p;
  logfile_active: cvar_p;               // 1 = buffer log, 2 = flush after each print
  showtrace: cvar_p;

  logfile: integer = 0;

  server_state: Integer;

{*
============================================================================

CLIENT / SERVER interactions

============================================================================
*}

var
  rd_target: Integer;
  rd_buffer: PChar;
  rd_buffersize: Integer;

var
  rd_flush: rd_flush_proc;

procedure Com_BeginRedirect(target: Integer; buffer: PChar; buffersize: Integer; flush: rd_flush_proc);
begin
  if (target = 0) or (buffer = nil) or (buffersize = 0) or (@flush = nil) then
    Exit;
  rd_target := target;
  rd_buffer := buffer;
  rd_buffersize := buffersize;
  rd_flush := flush;

  rd_buffer^ := #0;
end;

procedure Com_EndRedirect;
begin
  rd_flush(rd_target, rd_buffer);

  rd_target := 0;
  rd_buffer := nil;
  rd_buffersize := 0;
  rd_flush := nil;
end;

{*
=============
Com_Printf

Both client and server can use this, and it will output
to the apropriate place.
=============
*}
procedure Com_Printf(fmt: PChar; args: array of const);
var
  msg: array[0..MAXPRINTMSG - 1] of Char;
  name: array[0..MAX_QPATH - 1] of Char;
  TmpS: string;
begin
  DelphiStrFmt(msg, fmt, args);

  if (rd_target <> 0) then
  begin
    if ((StrLen(msg) + StrLen(rd_buffer)) > Cardinal(rd_buffersize - 1)) then
    begin
      rd_flush(rd_target, rd_buffer);
      rd_buffer^ := #0;
    end;
    StrCat(rd_buffer, msg);
    Exit;
  end;

  Con_Print(msg);

  // also echo to debugging console
  Sys_ConsoleOutput(msg);

  // logfile
  if (logfile_active <> nil) and (logfile_active.value <> 0) then
  begin
    if (logfile <= 0) then
    begin
      Com_sprintf(name, SizeOf(name), '%s/qconsole.log', [FS_Gamedir]);

      if (logfile_active.value > 2) then
      begin
        { Juha: Append (was fopen "a") }
        logfile := FileOpen(name, fmOpenReadWrite);
        if logfile = -1 then
          logfile := FileCreate(name, fmOpenReadWrite);
        FileSeek(logfile, 0, 2);
      end
      else
      begin
        { Juha: Wipe existing (was fopen "w") }
        DeleteFile(name);
        logfile := FileCreate(name, fmOpenReadWrite);
      end;

      //Clootie: need to clean up on error
      if logfile = -1 then
      begin
        logfile := 0;
      end;
    end;

    if (logfile > 0) then
    begin
      // Juha: Because we don't have C-style autotranslating text file write
      // routines, we need to manually format LF -> CRLF.
      TmpS := StringReplace(PChar(@msg), #10, #13#10, [rfReplaceAll]);
      if TmpS <> '' then
        FileWrite(logfile, TmpS[1], Length(TmpS));
    end;
    if (logfile_active.value > 1) then
      ;
    //Flush(logfile^);          // force it to save every time
  end;
end;

// Overloaded version without parameters

procedure Com_Printf(fmt: PChar);
begin
  Com_Printf(fmt, []);
end;

{*
================
Com_DPrintf

A Com_Printf that only shows up if the "developer" cvar is set
================
*}
procedure Com_DPrintf(fmt: PChar; args: array of const);
var
  msg: array[0..MAXPRINTMSG - 1] of Char;
begin
  if (developer = nil) or (developer.value = 0) then
    Exit;                               // don't confuse non-developers with techie stuff...

  DelphiStrFmt(msg, fmt, args);

  Com_Printf('%s', [msg]);
end;

// Overloaded version without parameters

procedure Com_DPrintf(fmt: PChar);
begin
  Com_DPrintf(fmt, []);
end;

{*
=============
Com_Error

Both client and server can use this, and it will
do the apropriate things.
=============
*}
procedure Com_Error(code: Integer; fmt: PChar; args: array of const);
{$IFDEF COMPILER6_UP}{$WRITEABLECONST ON}{$ENDIF}
const
  msg: array[0..MAXPRINTMSG - 1] of Char = #0;
  recursive: qboolean = False;
{$IFDEF COMPILER6_UP}{$WRITEABLECONST OFF}{$ENDIF}
begin
  if (recursive) then
    Sys_Error('recursive error after: %s', [msg]);
  recursive := True;

  DelphiStrFmt(msg, fmt, args);

  if (code = ERR_DISCONNECT) then
  begin
    CL_Drop;
    recursive := False;
    raise ELongJump.Create('longjmp');  //Clootie: instead of "longjmp (abortframe, -1);"
  end
  else if (code = ERR_DROP) then
  begin
    Com_Printf('********************'#10'ERROR: %s'#10'********************'#10, [msg]);
    SV_Shutdown(va('Server crashed: %s'#10, [msg]), False);
    CL_Drop;
    recursive := False;
    raise ELongJump.Create('longjmp');  //Clootie: instead of "longjmp (abortframe, -1);"
  end
  else
  begin
    SV_Shutdown(va('Server fatal crashed: %s'#10, [msg]), False);
    CL_Shutdown;
  end;

  if (logfile <> 0) then
  begin
    FileClose(logfile);
    logfile := 0;
  end;

  Sys_Error('%s', [msg]);
end;

// Overloaded version without parameters

procedure Com_Error(code: Integer; fmt: PChar);
begin
  Com_Error(code, fmt, []);
end;

{*
=============
Com_Quit

Both client and server can use this, and it will
do the apropriate things.
=============
*}
procedure Com_Quit;
begin
  SV_Shutdown('Server quit'#10, False);
  CL_Shutdown;

  if (logfile <> 0) then
  begin
    FileClose(logfile);
    logfile := 0;
  end;

  Sys_Quit;
end;

{*
==================
Com_ServerState
==================
*}
function Com_ServerState: Integer;
begin
  Result := server_state;
end;

{*
==================
Com_SetServerState
==================
*}
procedure Com_SetServerState(state: Integer);
begin
  server_state := state;
end;

{*
==============================================================================

   MESSAGE IO FUNCTIONS

Handles byte ordering and avoids alignment errors
==============================================================================
*}

//
// writing functions
//

procedure MSG_WriteChar(var sb: sizebuf_t; c: ShortInt);
var
  buf: PByteArray;
begin
{$IFDEF PARANOID}
  if (c < -128) or (c > 127) then
    Com_Error(ERR_FATAL, 'MSG_WriteChar: range error', []);
{$ENDIF}

  buf := SZ_GetSpace(sb, 1);
  buf[0] := c;
end;

procedure MSG_WriteByte(var sb: sizebuf_t; c: Integer);
var
  buf: PByteArray;
begin
{$IFDEF PARANOID}
  if (c < 0) or (c > 255) then
    Com_Error(ERR_FATAL, 'MSG_WriteByte: range error', []);
{$ENDIF}

  buf := SZ_GetSpace(sb, 1);
  buf[0] := Byte(c);
end;

procedure MSG_WriteShort(var sb: sizebuf_t; c: Integer);
var
  buf: PByteArray;
begin
{$IFDEF PARANOID}
  if (c < SmallInt($8000)) or (c > SmallInt($7FFF)) then
    Com_Error(ERR_FATAL, 'MSG_WriteShort: range error', []);
{$ENDIF}

  buf := SZ_GetSpace(sb, 2);
  buf[0] := c and $FF;
  buf[1] := Byte(c shr 8);
end;

procedure MSG_WriteLong(var sb: sizebuf_t; c: Integer);
var
  buf: PByteArray;
begin
  buf := SZ_GetSpace(sb, 4);
  buf[0] := c and $FF;
  buf[1] := (c shr 8) and $FF;
  buf[2] := (c shr 16) and $FF;
  buf[3] := c shr 24;
end;

procedure MSG_WriteFloat(var sb: sizebuf_t; f: Single);
type
  dat_ = packed record
    case Boolean of
      True: (f: Single; );
      False: (l: Integer; )
  end;
var
  dat: dat_;
begin
  dat.f := f;
  dat.l := LittleLong(dat.l);

  SZ_Write(sb, @dat.l, 4);
end;

procedure MSG_WriteString(var sb: sizebuf_t; s: PChar);
begin
  if (s = nil) then
    SZ_Write(sb, PChar(''), 1)
  else
    SZ_Write(sb, s, StrLen(s) + 1);
end;

procedure MSG_WriteCoord(var sb: sizebuf_t; f: Single);
begin
  MSG_WriteShort(sb, Trunc(f * 8));
end;

procedure MSG_WritePos(var sb: sizebuf_t; const pos: vec3_t);
begin
  MSG_WriteShort(sb, Trunc(pos[0] * 8));
  MSG_WriteShort(sb, Trunc(pos[1] * 8));
  MSG_WriteShort(sb, Trunc(pos[2] * 8));
end;

procedure MSG_WriteAngle(var sb: sizebuf_t; f: Single);
begin
  MSG_WriteByte(sb, Trunc(f * 256 / 360) and 255);
end;

procedure MSG_WriteAngle16(var sb: sizebuf_t; f: Single);
begin
  MSG_WriteShort(sb, ANGLE2SHORT(f));
end;

procedure MSG_WriteDeltaUsercmd(var buf: sizebuf_t; const from: usercmd_t; const cmd: usercmd_t);
var
  bits: Integer;
begin
  //
  // send the movement message
  //
  bits := 0;
  if (cmd.angles[0] <> from.angles[0]) then
    bits := bits or CM_ANGLE1;
  if (cmd.angles[1] <> from.angles[1]) then
    bits := bits or CM_ANGLE2;
  if (cmd.angles[2] <> from.angles[2]) then
    bits := bits or CM_ANGLE3;
  if (cmd.forwardmove <> from.forwardmove) then
    bits := bits or CM_FORWARD;
  if (cmd.sidemove <> from.sidemove) then
    bits := bits or CM_SIDE;
  if (cmd.upmove <> from.upmove) then
    bits := bits or CM_UP;
  if (cmd.buttons <> from.buttons) then
    bits := bits or CM_BUTTONS;
  if (cmd.impulse <> from.impulse) then
    bits := bits or CM_IMPULSE;

  MSG_WriteByte(buf, bits);

  if (bits and CM_ANGLE1) <> 0 then
    MSG_WriteShort(buf, cmd.angles[0]);
  if (bits and CM_ANGLE2) <> 0 then
    MSG_WriteShort(buf, cmd.angles[1]);
  if (bits and CM_ANGLE3) <> 0 then
    MSG_WriteShort(buf, cmd.angles[2]);

  if (bits and CM_FORWARD) <> 0 then
    MSG_WriteShort(buf, cmd.forwardmove);
  if (bits and CM_SIDE) <> 0 then
    MSG_WriteShort(buf, cmd.sidemove);
  if (bits and CM_UP) <> 0 then
    MSG_WriteShort(buf, cmd.upmove);

  if (bits and CM_BUTTONS) <> 0 then
    MSG_WriteByte(buf, cmd.buttons);
  if (bits and CM_IMPULSE) <> 0 then
    MSG_WriteByte(buf, cmd.impulse);

  MSG_WriteByte(buf, cmd.msec);
  MSG_WriteByte(buf, cmd.lightlevel);
end;

procedure MSG_WriteDir(var sb: sizebuf_t; dir: vec3_p);
var
  i, best: Integer;
  d, bestd: Single;
begin
  if (dir = nil) then
  begin
    MSG_WriteByte(sb, 0);
    Exit;
  end;

  bestd := 0;
  best := 0;
  for i := 0 to NUMVERTEXNORMALS - 1 do
  begin
    d := DotProduct(dir^, bytedirs[i]);
    if (d > bestd) then
    begin
      bestd := d;
      best := i;
    end;
  end;
  MSG_WriteByte(sb, best);
end;

procedure MSG_ReadDir(var sb: sizebuf_t; var dir: vec3_t);
var
  b: Integer;
begin
  b := MSG_ReadByte(sb);
  if (b >= NUMVERTEXNORMALS) then
    Com_Error(ERR_DROP, 'MSF_ReadDir: out of range', []);
  VectorCopy(bytedirs[b], dir);
end;

{*
==================
MSG_WriteDeltaEntity

Writes part of a packetentities message.
Can delta from either a baseline or a previous packet_entity
==================
*}
procedure MSG_WriteDeltaEntity(const from, to_: entity_state_t; var msg: sizebuf_t; force, newentity: qboolean);
var
  bits: Cardinal;
begin
  if (to_.number = 0) then
    Com_Error(ERR_FATAL, 'Unset entity number', []);
  if (to_.number >= MAX_EDICTS) then
    Com_Error(ERR_FATAL, 'Entity number >= MAX_EDICTS', []);

  // send an update
  bits := 0;

  if (to_.number >= 256) then
    bits := bits or U_NUMBER16;         // number8 is implicit otherwise

  if (to_.origin[0] <> from.origin[0]) then
    bits := bits or U_ORIGIN1;
  if (to_.origin[1] <> from.origin[1]) then
    bits := bits or U_ORIGIN2;
  if (to_.origin[2] <> from.origin[2]) then
    bits := bits or U_ORIGIN3;

  if (to_.angles[0] <> from.angles[0]) then
    bits := bits or U_ANGLE1;
  if (to_.angles[1] <> from.angles[1]) then
    bits := bits or U_ANGLE2;
  if (to_.angles[2] <> from.angles[2]) then
    bits := bits or U_ANGLE3;

  if (to_.skinnum <> from.skinnum) then
  begin
    if (Cardinal(to_.skinnum) < 256) then
      bits := bits or U_SKIN8
    else if (Cardinal(to_.skinnum) < $10000) then
      bits := bits or U_SKIN16
    else
      bits := bits or (U_SKIN8 or U_SKIN16);
  end;

  if (to_.frame <> from.frame) then
  begin
    if (to_.frame < 256) then
      bits := bits or U_FRAME8
    else
      bits := bits or U_FRAME16;
  end;

  if (to_.effects <> from.effects) then
  begin
    if (to_.effects < 256) then
      bits := bits or U_EFFECTS8
    else if (to_.effects < $8000) then
      bits := bits or U_EFFECTS16
    else
      bits := bits or U_EFFECTS8 or U_EFFECTS16;
  end;

  if (to_.renderfx <> from.renderfx) then
  begin
    if (to_.renderfx < 256) then
      bits := bits or U_RENDERFX8
    else if (to_.renderfx < $8000) then
      bits := bits or U_RENDERFX16
    else
      bits := bits or U_RENDERFX8 or U_RENDERFX16;
  end;

  if (to_.solid <> from.solid) then
    bits := bits or U_SOLID;

  // event is not delta compressed, just 0 compressed
  if (to_.event <> EV_NONE) then
    bits := bits or U_EVENT;

  if (to_.modelindex <> from.modelindex) then
    bits := bits or U_MODEL;
  if (to_.modelindex2 <> from.modelindex2) then
    bits := bits or U_MODEL2;
  if (to_.modelindex3 <> from.modelindex3) then
    bits := bits or U_MODEL3;
  if (to_.modelindex4 <> from.modelindex4) then
    bits := bits or U_MODEL4;

  if (to_.sound <> from.sound) then
    bits := bits or U_SOUND;

  if newentity or ((to_.renderfx and RF_BEAM) <> 0) then
    bits := bits or U_OLDORIGIN;

  //
  // write the message
  //
  if (bits = 0) and not force then
    Exit;                               // nothing to send!

  //----------

  if (bits and $FF000000) <> 0 then
    bits := bits or U_MOREBITS3 or U_MOREBITS2 or U_MOREBITS1
  else if (bits and $00FF0000) <> 0 then
    bits := bits or U_MOREBITS2 or U_MOREBITS1
  else if (bits and $0000FF00) <> 0 then
    bits := bits or U_MOREBITS1;

  MSG_WriteByte(msg, bits and 255);

  if (bits and $FF000000) <> 0 then
  begin
    MSG_WriteByte(msg, (bits shr 8) and 255);
    MSG_WriteByte(msg, (bits shr 16) and 255);
    MSG_WriteByte(msg, (bits shr 24) and 255);
  end
  else if (bits and $00FF0000) <> 0 then
  begin
    MSG_WriteByte(msg, (bits shr 8) and 255);
    MSG_WriteByte(msg, (bits shr 16) and 255);
  end
  else if (bits and $0000FF00) <> 0 then
  begin
    MSG_WriteByte(msg, (bits shr 8) and 255);
  end;

  //----------

  if (bits and U_NUMBER16) <> 0 then
    MSG_WriteShort(msg, to_.number)
  else
    MSG_WriteByte(msg, to_.number);

  if (bits and U_MODEL) <> 0 then
    MSG_WriteByte(msg, to_.modelindex);
  if (bits and U_MODEL2) <> 0 then
    MSG_WriteByte(msg, to_.modelindex2);
  if (bits and U_MODEL3) <> 0 then
    MSG_WriteByte(msg, to_.modelindex3);
  if (bits and U_MODEL4) <> 0 then
    MSG_WriteByte(msg, to_.modelindex4);

  if (bits and U_FRAME8) <> 0 then
    MSG_WriteByte(msg, to_.frame);
  if (bits and U_FRAME16) <> 0 then
    MSG_WriteShort(msg, to_.frame);

  if ((bits and U_SKIN8) <> 0) and ((bits and U_SKIN16)<>0) then //used for laser colors
    MSG_WriteLong(msg, to_.skinnum)
  else if (bits and U_SKIN8) <> 0 then
    MSG_WriteByte(msg, to_.skinnum)
  else if (bits and U_SKIN16) <> 0 then
    MSG_WriteShort(msg, to_.skinnum);

  if (bits and (U_EFFECTS8 or U_EFFECTS16)) = (U_EFFECTS8 or U_EFFECTS16) then
    MSG_WriteLong(msg, to_.effects)
  else if (bits and U_EFFECTS8) <> 0 then
    MSG_WriteByte(msg, to_.effects)
  else if (bits and U_EFFECTS16) <> 0 then
    MSG_WriteShort(msg, to_.effects);

  if (bits and (U_RENDERFX8 or U_RENDERFX16)) = (U_RENDERFX8 or U_RENDERFX16) then
    MSG_WriteLong(msg, to_.renderfx)
  else if (bits and U_RENDERFX8) <> 0 then
    MSG_WriteByte(msg, to_.renderfx)
  else if (bits and U_RENDERFX16) <> 0 then
    MSG_WriteShort(msg, to_.renderfx);

  if (bits and U_ORIGIN1) <> 0 then
    MSG_WriteCoord(msg, to_.origin[0]);
  if (bits and U_ORIGIN2) <> 0 then
    MSG_WriteCoord(msg, to_.origin[1]);
  if (bits and U_ORIGIN3) <> 0 then
    MSG_WriteCoord(msg, to_.origin[2]);

  if (bits and U_ANGLE1) <> 0 then
    MSG_WriteAngle(msg, to_.angles[0]);
  if (bits and U_ANGLE2) <> 0 then
    MSG_WriteAngle(msg, to_.angles[1]);
  if (bits and U_ANGLE3) <> 0 then
    MSG_WriteAngle(msg, to_.angles[2]);

  if (bits and U_OLDORIGIN) <> 0 then
  begin
    MSG_WriteCoord(msg, to_.old_origin[0]);
    MSG_WriteCoord(msg, to_.old_origin[1]);
    MSG_WriteCoord(msg, to_.old_origin[2]);
  end;

  if (bits and U_SOUND) <> 0 then
    MSG_WriteByte(msg, to_.sound);
  if (bits and U_EVENT) <> 0 then
    MSG_WriteByte(msg, Integer(to_.event));
  if (bits and U_SOLID) <> 0 then
    MSG_WriteShort(msg, to_.solid);
end;

//============================================================

//
// reading functions
//

procedure MSG_BeginReading(var sb: sizebuf_t);
begin
  sb.readcount := 0;
end;

// returns -1 if no more characters are available
function MSG_ReadChar(var msg_read: sizebuf_t): ShortInt;
begin
  if (msg_read.readcount + 1 > msg_read.cursize) then
    Result := -1
  else
    Result := ShortInt(msg_read.data[msg_read.readcount]);

  Inc(msg_read.readcount);
end;

function MSG_ReadByte(var msg_read: sizebuf_t): Integer;
begin
  if (msg_read.readcount + 1 > msg_read.cursize) then
    Result := -1
  else
    Result := Byte(msg_read.data[msg_read.readcount]);

  Inc(msg_read.readcount);
end;

function MSG_ReadShort(var msg_read: sizebuf_t): Integer;
begin
  if (msg_read.readcount + 2 > msg_read.cursize) then
    Result := -1
  else
    Result := SmallInt(msg_read.data[msg_read.readcount] +
      (msg_read.data[msg_read.readcount + 1] shl 8));

  Inc(msg_read.readcount, 2);
end;

function MSG_ReadLong(var msg_read: sizebuf_t): Integer;
begin
  if (msg_read.readcount + 4 > msg_read.cursize) then
    Result := -1
  else
    Result := msg_read.data[msg_read.readcount] +
      (msg_read.data[msg_read.readcount + 1] shl 8) +
      (msg_read.data[msg_read.readcount + 2] shl 16) +
      (msg_read.data[msg_read.readcount + 3] shl 24);

  Inc(msg_read.readcount, 4);
end;

function MSG_ReadFloat(var msg_read: sizebuf_t): Single;
type
  dat_ = packed record
    case Integer of
      0: (f: Single);
      1: (b: array[0..3] of Byte);
      2: (l: Integer);
  end;
var
  dat: dat_;
begin
  if (msg_read.readcount + 4 > msg_read.cursize) then
    dat.f := -1
  else
  begin
    dat.b[0] := msg_read.data[msg_read.readcount];
    dat.b[1] := msg_read.data[msg_read.readcount + 1];
    dat.b[2] := msg_read.data[msg_read.readcount + 2];
    dat.b[3] := msg_read.data[msg_read.readcount + 3];
  end;
  Inc(msg_read.readcount, 4);

  dat.l := LittleLong(dat.l);

  Result := dat.f;
end;

function MSG_ReadString(var msg_read: sizebuf_t): PChar;
{$IFDEF COMPILER6_UP}{$WRITEABLECONST ON}{$ENDIF}
const
  string_: array[0..2048 - 1] of Char = #0;
{$IFDEF COMPILER6_UP}{$WRITEABLECONST OFF}{$ENDIF}
var
  l, c: Integer;
begin
  l := 0;
  repeat
    c := MSG_ReadChar(msg_read);
    if (c = -1) or (c = 0) then
      Break;
    string_[l] := Char(c);
    Inc(l);
  until (l >= SizeOf(string_) - 1);
  //} while (l < sizeof(string)-1);

  string_[l] := #0;

  Result := string_;
end;

function MSG_ReadStringLine(var msg_read: sizebuf_t): PChar;
{$IFDEF COMPILER6_UP}{$WRITEABLECONST ON}{$ENDIF}
const
  string_: array[0..2048 - 1] of Char = #0;
{$IFDEF COMPILER6_UP}{$WRITEABLECONST OFF}{$ENDIF}
var
  l, c: Integer;
begin
  l := 0;
  repeat
    c := MSG_ReadChar(msg_read);
    if (c = -1) or (c = 0) or (c = 10) then
      Break;
    string_[l] := Char(c);
    Inc(l);
  until (l >= SizeOf(string_) - 1);
  //} while (l < sizeof(string)-1);

  string_[l] := #0;

  Result := string_;
end;

function MSG_ReadCoord(var msg_read: sizebuf_t): Single;
begin
  Result := MSG_ReadShort(msg_read) * (1.0 / 8);
end;

procedure MSG_ReadPos(var msg_read: sizebuf_t; var pos: vec3_t);
begin
  pos[0] := MSG_ReadShort(msg_read) * (1.0 / 8);
  pos[1] := MSG_ReadShort(msg_read) * (1.0 / 8);
  pos[2] := MSG_ReadShort(msg_read) * (1.0 / 8);
end;

function MSG_ReadAngle(var msg_read: sizebuf_t): Single;
begin
  Result := MSG_ReadChar(msg_read) * (360.0 / 256);
end;

function MSG_ReadAngle16(var msg_read: sizebuf_t): Single;
begin
  Result := SHORT2ANGLE(MSG_ReadShort(msg_read));
end;

procedure MSG_ReadDeltaUsercmd(var msg_read: sizebuf_t; const from: usercmd_t; var move: usercmd_t);
var
  bits: Integer;
begin
  System.Move(from, move, SizeOf(move));

  bits := MSG_ReadByte(msg_read);

  // read current angles
  if (bits and CM_ANGLE1) <> 0 then
    move.angles[0] := MSG_ReadShort(msg_read);
  if (bits and CM_ANGLE2) <> 0 then
    move.angles[1] := MSG_ReadShort(msg_read);
  if (bits and CM_ANGLE3) <> 0 then
    move.angles[2] := MSG_ReadShort(msg_read);

  // read movement
  if (bits and CM_FORWARD) <> 0 then
    move.forwardmove := MSG_ReadShort(msg_read);
  if (bits and CM_SIDE) <> 0 then
    move.sidemove := MSG_ReadShort(msg_read);
  if (bits and CM_UP) <> 0 then
    move.upmove := MSG_ReadShort(msg_read);

  // read buttons
  if (bits and CM_BUTTONS) <> 0 then
    move.buttons := MSG_ReadByte(msg_read);

  if (bits and CM_IMPULSE) <> 0 then
    move.impulse := MSG_ReadByte(msg_read);

  // read time to run command
  move.msec := MSG_ReadByte(msg_read);

  // read the light level
  move.lightlevel := MSG_ReadByte(msg_read);
end;

procedure MSG_ReadData(var msg_read: sizebuf_t; data: Pointer; len: Integer);
var
  i: integer;
begin
  for i := 0 to len - 1 do
    PByteArray(data)[i] := MSG_ReadByte(msg_read);
end;

//===========================================================================

procedure SZ_Init(var buf: sizebuf_t; data: PByte; length: Integer);
begin
  FillChar(buf, SizeOf(buf), 0);
  buf.data := PByteArray(data);
  buf.maxsize := length;
end;

procedure SZ_Clear(var buf: sizebuf_t);
begin
  buf.cursize := 0;
  buf.overflowed := False;
end;

function SZ_GetSpace(var buf: sizebuf_t; length: Integer): Pointer;
begin
  if (buf.cursize + length > buf.maxsize) then
  begin
    if (not buf.allowoverflow) then
      Com_Error(ERR_FATAL, 'SZ_GetSpace: overflow without allowoverflow set', []);

    if (length > buf.maxsize) then
      Com_Error(ERR_FATAL, 'SZ_GetSpace: %d is > full buffer size', [length]);

    Com_Printf('SZ_GetSpace: overflow'#10, []);
    SZ_Clear(buf);
    buf.overflowed := True;
  end;

  Result := Pointer(Integer(buf.data) + buf.cursize);
  buf.cursize := buf.cursize + length;
end;

procedure SZ_Write(var buf: sizebuf_t; data: Pointer; length: Integer);
begin
  Move(data^, SZ_GetSpace(buf, length)^, length);
end;

procedure SZ_Print(var buf: sizebuf_t; data: PChar);
var
  len: Integer;
begin
  len := StrLen(data) + 1;

  if (buf.cursize <> 0) then
  begin
    if (buf.data[buf.cursize - 1] <> 0) then
      Move(data^, SZ_GetSpace(buf, len)^, len) // no trailing 0
    else
      Move(data^, Pointer(Cardinal(SZ_GetSpace(buf, len - 1)) - 1)^, len) // write over trailing 0
  end
  else
    Move(data^, SZ_GetSpace(buf, len)^, len) // no trailing 0
end;

//============================================================================

{*
================
COM_CheckParm

Returns the position (1 to argc-1) in the program's argument list
where the given parameter apears, or 0 if not present
================
*}
function COM_CheckParm(parm: PChar): Integer;
var
  i: Integer;
begin
  for i := 1 to com_argc_ - 1 do
  begin
    if (StrComp(parm, com_argv_[i]) = 0) then
    begin
      Result := i;
      Exit;
    end;
  end;

  Result := 0;
end;

function COM_Argc: Integer;
begin
  Result := com_argc_;
end;

function COM_Argv(arg: Integer): PChar;
begin
  if (arg < 0) or (arg >= com_argc_) or (com_argv_[arg] = nil) then
    Result := nil
  else
    Result := com_argv_[arg];
end;

procedure COM_ClearArgv(arg: Integer);
begin
  if (arg < 0) or (arg >= com_argc_) or (com_argv_[arg] = nil) then
    Exit;
  com_argv_[arg] := '';
end;

{*
================
COM_InitArgv
================
*}
procedure COM_InitArgv(argc: Integer; argv: PComArgvArray); //todo: , char **argv);
var
  i: Integer;
begin
  if (argc > MAX_NUM_ARGVS) then
    Com_Error(ERR_FATAL, 'argc > MAX_NUM_ARGVS', []);
  com_argc_ := argc;
  for i := 0 to argc - 1 do
  begin
    if (argv[i] = nil) or (StrLen(argv[i]) >= MAX_TOKEN_CHARS) then
      com_argv_[i] := ''
    else
      com_argv_[i] := argv[i];
  end;
end;

{*
================
COM_AddParm

Adds the given string at the end of the current argument list
================
*}
procedure COM_AddParm(parm: PChar);
begin
  if (com_argc = MAX_NUM_ARGVS) then
    Com_Error(ERR_FATAL, 'COM_AddParm: MAX_NUM)ARGS', []);
  com_argv_[com_argc_] := parm;
  Inc(com_argc_);
end;

/// just for debugging
function MemSearch(start: PByte; count, search: Integer): Integer;
var
  i: Integer;
begin
  for i := 0 to count - 1 do
    if (PByteArray(start)[i] = search) then
    begin
      Result := i;
      Exit;
    end;
  Result := -1;
end;

function CopyString(in_: PChar): PChar;
var
  out_: PChar;
begin
  out_ := Z_Malloc(StrLen(in_) + 1);
  StrCopy(out_, in_);
  Result := out_;
end;

procedure Info_Print(s: PChar);
var
  key: array[0..512 - 1] of Char;
  value: array[0..512 - 1] of Char;
  o: PChar;
  l: Integer;
begin
  if (s^ = '\') then
    Inc(s);

  while (s^ <> #0) do
  begin
    o := key;
    // while {*s && *s != '\\')
    while (s^ <> #0) and (s^ <> '\') do
    begin
      // *o++ = *s++;
      o^ := s^;
      Inc(o);
      Inc(s);
    end;

    l := longint(o - key);
    if (l < 20) then
    begin
      FillChar(o^, 20 - l, ' ');
      key[20] := #0;
    end
    else
      o^ := #0;
    Com_Printf('%s', [key]);

    if (s^ = #0) then
    begin
      Com_Printf('MISSING VALUE'#10, []);
      Exit;
    end;

    o := value;
    Inc(s);
    // while {*s && *s != '\\')
    while (s^ <> #0) and (s^ <> '\') do
    begin
      // *o++ = *s++;
      o^ := s^;
      Inc(o);
      Inc(s);
    end;
    o^ := #0;

    if (s^ <> #0) then
      Inc(s);
    Com_Printf('%s'#10, [value]);
  end;
end;

{*
==============================================================================

      ZONE MEMORY ALLOCATION

just cleared malloc with counters now...

==============================================================================
*}

const
  Z_MAGIC = $1D1D;

type
  zhead_p = ^zhead_t;
  zhead_s = record
    prev, next: zhead_p;
    magic: SmallInt;
    tag: SmallInt;                      // for group free
    size: Integer;
  end;
  zhead_t = zhead_s;

var
  z_chain: zhead_t;
  z_count, z_bytes: Integer;

{*
========================
Z_Free
========================
*}
procedure Z_Free(ptr: Pointer);
var
  z: zhead_p;
begin
  // z = ((zhead_t *}ptr) - 1;
  z := zhead_p(ptr);
  Dec(z);

  if (z.magic <> Z_MAGIC) then
    Com_Error(ERR_FATAL, 'Z_Free: bad magic', []);

  z.prev.next := z.next;
  z.next.prev := z.prev;

  Dec(z_count);
  z_bytes := z_bytes - z.size;
  FreeMem(z);
end;

{*
========================
Z_Stats_f
========================
*}
procedure Z_Stats_f; cdecl;
begin
  Com_Printf('%d bytes in %d blocks'#10, [z_bytes, z_count]);
end;

{*
========================
Z_FreeTags
========================
*}
procedure Z_FreeTags(tag: Integer);
var
  z, next: zhead_p;
begin
  z := z_chain.next;
  while (z <> @z_chain) do
  begin
    next := z.next;
    if (z.tag = tag) then
      Z_Free(Pointer(Integer(z) + 1 * SizeOf(zhead_t)));
    z := next;
  end;
end;

{*
========================
Z_TagMalloc
========================
*}
function Z_TagMalloc(size: Integer; tag: Integer): Pointer;
var
  z: zhead_p;
begin
  size := size + sizeof(zhead_t);
  try
    GetMem(z, size);
  except
    Com_Error(ERR_FATAL, 'Z_Malloc: failed on allocation of %d bytes', [size]);
    raise;                              // to fool Compiler warnings
  end;
  FillChar(z^, size, 0);
  Inc(z_count);
  z_bytes := z_bytes + size;
  z.magic := Z_MAGIC;
  z.tag := tag;
  z.size := size;

  z.next := z_chain.next;
  z.prev := @z_chain;
  z_chain.next.prev := z;
  z_chain.next := z;

  Result := z;
  Inc(zhead_p(Result));
end;

{*
========================
Z_Malloc
========================
*}
function Z_Malloc(size: Integer): Pointer;
begin
  Result := Z_TagMalloc(size, 0);
end;

//============================================================================

{*
====================
COM_BlockSequenceCheckByte

For proxy protecting

// THIS IS MASSIVELY BROKEN!  CHALLENGE MAY BE NEGATIVE
// DON'T USE THIS FUNCTION!!!!!

====================
*}
function COM_BlockSequenceCheckByte(base: PByte; length, sequence, challenge: Integer): Byte;
begin
  Sys_Error('COM_BlockSequenceCheckByte called'#10, []);

  {
   int      checksum;
   byte   buf[68];
   byte   *p;
   float temp;
   byte c;

   temp = bytedirs[(sequence/3) % NUMVERTEXNORMALS][sequence % 3];
   temp = LittleFloat(temp);
   p = ((byte * )&temp);

   if (length > 60)
    length = 60;
   memcpy (buf, base, length);

   buf[length] = (sequence & 0xff) ^ p[0];
   buf[length+1] = p[1];
   buf[length+2] = ((sequence>>8) & 0xff) ^ p[2];
   buf[length+3] = p[3];

   temp = bytedirs[((sequence+challenge)/3) % NUMVERTEXNORMALS][(sequence+challenge) % 3];
   temp = LittleFloat(temp);
   p = ((byte * )&temp);

   buf[length+4] = (sequence & 0xff) ^ p[3];
   buf[length+5] = (challenge & 0xff) ^ p[2];
   buf[length+6] = ((sequence>>8) & 0xff) ^ p[1];
   buf[length+7] = ((challenge >> 7) & 0xff) ^ p[0];

   length += 8;

   checksum = LittleLong(Com_BlockChecksum (buf, length));

   checksum &= 0xff;

   return checksum;
  }
  Result := 0;
end;

const
  //Clootie: It was declated as "static byte chktbl[1024]",
  //         but actual size is 930 = 15*64, instead of 16*64
  chktbl: array[0..15 * 64 - 1] of Byte = (
    $84, $47, $51, $C1, $93, $22, $21, $24, $2F, $66, $60, $4D, $B0, $7C, $DA,
    $88, $54, $15, $2B, $C6, $6C, $89, $C5, $9D, $48, $EE, $E6, $8A, $B5, $F4,
    $CB, $FB, $F1, $0C, $2E, $A0, $D7, $C9, $1F, $D6, $06, $9A, $09, $41, $54,
    $67, $46, $C7, $74, $E3, $C8, $B6, $5D, $A6, $36, $C4, $AB, $2C, $7E, $85,
    $A8, $A4, $A6, $4D, $96, $19, $19, $9A, $CC, $D8, $AC, $39, $5E, $3C, $F2,
    $F5, $5A, $72, $E5, $A9, $D1, $B3, $23, $82, $6F, $29, $CB, $D1, $CC, $71,
    $FB, $EA, $92, $EB, $1C, $CA, $4C, $70, $FE, $4D, $C9, $67, $43, $47, $94,
    $B9, $47, $BC, $3F, $01, $AB, $7B, $A6, $E2, $76, $EF, $5A, $7A, $29, $0B,
    $51, $54, $67, $D8, $1C, $14, $3E, $29, $EC, $E9, $2D, $48, $67, $FF, $ED,
    $54, $4F, $48, $C0, $AA, $61, $F7, $78, $12, $03, $7A, $9E, $8B, $CF, $83,
    $7B, $AE, $CA, $7B, $D9, $E9, $53, $2A, $EB, $D2, $D8, $CD, $A3, $10, $25,
    $78, $5A, $B5, $23, $06, $93, $B7, $84, $D2, $BD, $96, $75, $A5, $5E, $CF,
    $4E, $E9, $50, $A1, $E6, $9D, $B1, $E3, $85, $66, $28, $4E, $43, $DC, $6E,
    $BB, $33, $9E, $F3, $0D, $00, $C1, $CF, $67, $34, $06, $7C, $71, $E3, $63,
    $B7, $B7, $DF, $92, $C4, $C2, $25, $5C, $FF, $C3, $6E, $FC, $AA, $1E, $2A,
    $48, $11, $1C, $36, $68, $78, $86, $79, $30, $C3, $D6, $DE, $BC, $3A, $2A,
    $6D, $1E, $46, $DD, $E0, $80, $1E, $44, $3B, $6F, $AF, $31, $DA, $A2, $BD,
    $77, $06, $56, $C0, $B7, $92, $4B, $37, $C0, $FC, $C2, $D5, $FB, $A8, $DA,
    $F5, $57, $A8, $18, $C0, $DF, $E7, $AA, $2A, $E0, $7C, $6F, $77, $B1, $26,
    $BA, $F9, $2E, $1D, $16, $CB, $B8, $A2, $44, $D5, $2F, $1A, $79, $74, $87,
    $4B, $00, $C9, $4A, $3A, $65, $8F, $E6, $5D, $E5, $0A, $77, $D8, $1A, $14,
    $41, $75, $B1, $E2, $50, $2C, $93, $38, $2B, $6D, $F3, $F6, $DB, $1F, $CD,
    $FF, $14, $70, $E7, $16, $E8, $3D, $F0, $E3, $BC, $5E, $B6, $3F, $CC, $81,
    $24, $67, $F3, $97, $3B, $FE, $3A, $96, $85, $DF, $E4, $6E, $3C, $85, $05,
    $0E, $A3, $2B, $07, $C8, $BF, $E5, $13, $82, $62, $08, $61, $69, $4B, $47,
    $62, $73, $44, $64, $8E, $E2, $91, $A6, $9A, $B7, $E9, $04, $B6, $54, $0C,
    $C5, $A9, $47, $A6, $C9, $08, $FE, $4E, $A6, $CC, $8A, $5B, $90, $6F, $2B,
    $3F, $B6, $0A, $96, $C0, $78, $58, $3C, $76, $6D, $94, $1A, $E4, $4E, $B8,
    $38, $BB, $F5, $EB, $29, $D8, $B0, $F3, $15, $1E, $99, $96, $3C, $5D, $63,
    $D5, $B1, $AD, $52, $B8, $55, $70, $75, $3E, $1A, $D5, $DA, $F6, $7A, $48,
    $7D, $44, $41, $F9, $11, $CE, $D7, $CA, $A5, $3D, $7A, $79, $7E, $7D, $25,
    $1B, $77, $BC, $F7, $C7, $0F, $84, $95, $10, $92, $67, $15, $11, $5A, $5E,
    $41, $66, $0F, $38, $03, $B2, $F1, $5D, $F8, $AB, $C0, $02, $76, $84, $28,
    $F4, $9D, $56, $46, $60, $20, $DB, $68, $A7, $BB, $EE, $AC, $15, $01, $2F,
    $20, $09, $DB, $C0, $16, $A1, $89, $F9, $94, $59, $00, $C1, $76, $BF, $C1,
    $4D, $5D, $2D, $A9, $85, $2C, $D6, $D3, $14, $CC, $02, $C3, $C2, $FA, $6B,
    $B7, $A6, $EF, $DD, $12, $26, $A4, $63, $E3, $62, $BD, $56, $8A, $52, $2B,
    $B9, $DF, $09, $BC, $0E, $97, $A9, $B0, $82, $46, $08, $D5, $1A, $8E, $1B,
    $A7, $90, $98, $B9, $BB, $3C, $17, $9A, $F2, $82, $BA, $64, $0A, $7F, $CA,
    $5A, $8C, $7C, $D3, $79, $09, $5B, $26, $BB, $BD, $25, $DF, $3D, $6F, $9A,
    $8F, $EE, $21, $66, $B0, $8D, $84, $4C, $91, $45, $D4, $77, $4F, $B3, $8C,
    $BC, $A8, $99, $AA, $19, $53, $7C, $02, $87, $BB, $0B, $7C, $1A, $2D, $DF,
    $48, $44, $06, $D6, $7D, $0C, $2D, $35, $76, $AE, $C4, $5F, $71, $85, $97,
    $C4, $3D, $EF, $52, $BE, $00, $E4, $CD, $49, $D1, $D1, $1C, $3C, $D0, $1C,
    $42, $AF, $D4, $BD, $58, $34, $07, $32, $EE, $B9, $B5, $EA, $FF, $D7, $8C,
    $0D, $2E, $2F, $AF, $87, $BB, $E6, $52, $71, $22, $F5, $25, $17, $A1, $82,
    $04, $C2, $4A, $BD, $57, $C6, $AB, $C8, $35, $0C, $3C, $D9, $C2, $43, $DB,
    $27, $92, $CF, $B8, $25, $60, $FA, $21, $3B, $04, $52, $C8, $96, $BA, $74,
    $E3, $67, $3E, $8E, $8D, $61, $90, $92, $59, $B6, $1A, $1C, $5E, $21, $C1,
    $65, $E5, $A6, $34, $05, $6F, $C5, $60, $B1, $83, $C1, $D5, $D5, $ED, $D9,
    $C7, $11, $7B, $49, $7A, $F9, $F9, $84, $47, $9B, $E2, $A5, $82, $E0, $C2,
    $88, $D0, $B2, $58, $88, $7F, $45, $09, $67, $74, $61, $BF, $E6, $40, $E2,
    $9D, $C2, $47, $05, $89, $ED, $CB, $BB, $B7, $27, $E7, $DC, $7A, $FD, $BF,
    $A8, $D0, $AA, $10, $39, $3C, $20, $F0, $D3, $6E, $B1, $72, $F8, $E6, $0F,
    $EF, $37, $E5, $09, $33, $5A, $83, $43, $80, $4F, $65, $2F, $7C, $8C, $6A,
    $A0, $82, $0C, $D4, $D4, $FA, $81, $60, $3D, $DF, $06, $F1, $5F, $08, $0D,
    $6D, $43, $F2, $E3, $11, $7D, $80, $32, $C5, $FB, $C5, $D9, $27, $EC, $C6,
    $4E, $65, $27, $76, $87, $A6, $EE, $EE, $D7, $8B, $D1, $A0, $5C, $B0, $42,
    $13, $0E, $95, $4A, $F2, $06, $C6, $43, $33, $F4, $C7, $F8, $E7, $1F, $DD,
    $E4, $46, $4A, $70, $39, $6C, $D0, $ED, $CA, $BE, $60, $3B, $D1, $7B, $57,
    $48, $E5, $3A, $79, $C1, $69, $33, $53, $1B, $80, $B8, $91, $7D, $B4, $F6,
    $17, $1A, $1D, $5A, $32, $D6, $CC, $71, $29, $3F, $28, $BB, $F3, $5E, $71,
    $B8, $43, $AF, $F8, $B9, $64, $EF, $C4, $A5, $6C, $08, $53, $C7, $00, $10,
    $39, $4F, $DD, $E4, $B6, $19, $27, $FB, $B8, $F5, $32, $73, $E5, $CB, $32
    );

{*
====================
COM_BlockSequenceCRCByte

For proxy protecting
====================
*}
function COM_BlockSequenceCRCByte(base: PByte; length, sequence: Integer): Byte;
var
  n: Integer;
  p: PByteArray;
  x: Integer;
  chkb: array[0..60 + 4 - 1] of Byte;
  crc: Word;
begin
  if (sequence < 0) then
    Sys_Error('sequence < 0, this shouldn''t happen'#10, []);

  // p = chktbl + (sequence % (sizeof(chktbl) - 4));
  p := Pointer(Integer(@chktbl) + sequence mod (SizeOf(chktbl) - 4));

  if (length > 60) then
    length := 60;

  memcpy(@chkb, base, length);

  chkb[length] := p[0];
  chkb[length + 1] := p[1];
  chkb[length + 2] := p[2];
  chkb[length + 3] := p[3];

  Inc(length, 4);

  crc := CRC_Block(@chkb, length);

  // for (x=0, n=0; n<length; n++)
  x := 0;
  n := 0;
  while (n < length) do
  begin
    x := x + chkb[n];
    Inc(n);
  end;

  crc := (crc xor x) and $FF;

  Result := crc;
end;

//========================================================
const
  RAND_MAX = $7FFF;                     // unsigned

function rand: Integer;
begin
  Result := Random(RAND_MAX);
end;

function frand: Single;                 // 0 ti 1
begin
  // return (rand()&32767)* (1.0/32767);
  Result := (Random(RAND_MAX) and 32767) * (1.0 / 32767);
end;

function crand: Single;                 // -1 to 1
begin
  // return (rand()&32767)* (2.0/32767) - 1;
  Result := (Random(RAND_MAX) and 32767) * (2.0 / 32767) - 1;
end;

function fmod(x, y: Single): Single;
begin
  Result := x - (Trunc(x) div Trunc(y)) * y;
end;

{*
=============
Com_Error_f

Just throw a fatal error to
test error shutdown procedures
=============
*}
procedure Com_Error_f; cdecl;
begin
  Com_Error(ERR_FATAL, '%s', [Cmd_Argv(1)]);
end;

{*
=================
Qcommon_Init
=================
*}
procedure Qcommon_Init(argc: Integer; argv: PComArgvArray);
var
  s: PChar;
begin
  //Clootie: this is replcaed by exceptions...
  //if (setjmp (abortframe) )
  //  Sys_Error('Error during initialization');

  try
    z_chain.prev := @z_chain;
    z_chain.next := z_chain.prev;

    // prepare enough of the subsystems to handle
    // cvar and command buffer management
    COM_InitArgv(argc, argv);

    Swap_Init;
    Cbuf_Init;

    Cmd_Init;
    Cvar_Init;

    Key_Init;

    // we need to add the early commands twice, because
    // a basedir or cddir needs to be set before execing
    // config files, but we want other parms to override
    // the settings of the config files
    Cbuf_AddEarlyCommands(False);
    Cbuf_Execute;

    FS_InitFilesystem;

    Cbuf_AddText('exec default.cfg'#10);
    Cbuf_AddText('exec config.cfg'#10);

    Cbuf_AddEarlyCommands(True);
    Cbuf_Execute;

    //
    // init commands and vars
    //
    Cmd_AddCommand('z_stats', Z_Stats_f);
    Cmd_AddCommand('error', Com_Error_f);

    host_speeds := Cvar_Get('host_speeds', '0', 0);
    log_stats := Cvar_Get('log_stats', '0', 0);
    developer := Cvar_Get('developer', '0', 0);
    timescale := Cvar_Get('timescale', '1', 0);
    fixedtime := Cvar_Get('fixedtime', '0', 0);
    logfile_active := Cvar_Get('logfile', '0', 0);
    showtrace := Cvar_Get('showtrace', '0', 0);
{$IFDEF DEDICATED_ONLY}
    dedicated := Cvar_Get('dedicated', '1', CVAR_NOSET);
{$ELSE}
    dedicated := Cvar_Get('dedicated', '0', CVAR_NOSET);
{$ENDIF}

    s := va('%4.2f %s %s %s', [VERSION, CPUSTRING, __DATE__, BUILDSTRING]);
    Cvar_Get('version', s, CVAR_SERVERINFO or CVAR_NOSET);

    if (dedicated.value <> 0) then
      Cmd_AddCommand('quit', Com_Quit);

    Sys_Init;

    NET_Init;
    Netchan_Init;

    SV_Init;
    CL_Init;

    // add + commands from command line
    if not Cbuf_AddLateCommands then
    begin                               // if the user didn't give any commands, run default action
      if (dedicated.value = 0) then
        Cbuf_AddText('d1'#10)
      else
        Cbuf_AddText('dedicated_start'#10);
      Cbuf_Execute;
    end
    else
    begin                               // the user asked for something explicit
      // so drop the loading plaque
      SCR_EndLoadingPlaque;
    end;

    Com_Printf('====== Quake2 Initialized ======'#10#10, []);
  except
    on E: Exception do
      Sys_Error('Error during initialization (exception=%s)', [E.Message]);
  end;
end;

{*
=================
Qcommon_Frame
=================
*}
procedure Qcommon_Frame(msec: Integer);
const
  LOGLINE = 'entities,dlights,parts,frame time'#10;
var
  s: PChar;
  time_before, time_between, time_after: Integer;

  all, sv, gm, cl, rf: Integer;
begin
  //if (setjmp (abortframe) )
  //   return;         // an ERR_DROP was thrown
  try
    if log_stats.modified then
    begin
      log_stats.modified := False;
      if (log_stats.value <> 0) then
      begin
        if (log_stats_file <> 0) then
        begin
          FileClose(log_stats_file);
          log_stats_file := 0;
        end;

        DeleteFile('stats.log');
        log_stats_file := FileCreate('stats.log');
        // log_stats_file = fopen( "stats.log", "w" );

        //Clootie: need to clean up on error
        if log_stats_file = -1 then
        begin
          logfile := 0;
        end;

        if (log_stats_file <> 0) then
        begin
          // fprintf( log_stats_file, 'entities,dlights,parts,frame time'#10 );
          FileWrite(log_stats_file, LOGLINE, length(LOGLINE));
        end;
      end
      else
      begin
        if (log_stats_file <> 0) then
        begin
          FileClose(log_stats_file);
          log_stats_file := 0;
        end;
      end;
    end;

    if (fixedtime.value <> 0) then
      msec := Trunc(fixedtime.value)
    else if (timescale.value <> 0) then
    begin
      msec := Trunc(msec * timescale.value);
      if (msec < 1) then
        msec := 1;
    end;

    if (showtrace.value <> 0) then
    begin
      {
            extern   int c_traces, c_brush_traces;
            extern   int   c_pointcontents;
      }

      Com_Printf('%4d traces  %4d points'#10, [c_traces, c_pointcontents]);
      c_traces := 0;
      c_brush_traces := 0;
      c_pointcontents := 0;
    end;

    repeat
      s := Sys_ConsoleInput;
      if (s <> nil) then
        Cbuf_AddText(va('%s'#10, [s]));
    until (s = nil);
    Cbuf_Execute;

    time_before := 0;
    time_between := 0;
    time_after := 0;

    if (host_speeds.value <> 0) then
      time_before := Sys_Milliseconds;

    SV_Frame(msec);

    if (host_speeds.value <> 0) then
      time_between := Sys_Milliseconds;

    CL_Frame(msec);

    if (host_speeds.value <> 0) then
      time_after := Sys_Milliseconds;

    if (host_speeds.value <> 0) then
    begin
      all := time_after - time_before;
      sv := time_between - time_before;
      cl := time_after - time_between;
      gm := time_after_game - time_before_game;
      rf := time_after_ref - time_before_ref;
      sv := sv - gm;
      cl := cl - rf;
      Com_Printf('all:%3d sv:%3d gm:%3d cl:%3d rf:%3d'#10,
        [all, sv, gm, cl, rf]);
    end;
  except
    // Juha: In original Quake2 source, there isn't any specific exception
    // handling, but in our version we print the exception to console.
    on E: Exception do
    begin
      if E is ELongJump then
        Exit
      else
        Com_Printf(PChar(#10 + 'EXCEPTION: ' + E.Message + #10));
    end;
  end;
end;

{*
=================
Qcommon_Shutdown
=================
*}
procedure Qcommon_Shutdown;
begin
end;

end.
