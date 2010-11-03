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
{ File(s): cl_input.c                                                        }
{ Content: Quake2\Client - builds an intended movement command to send to the server }
{                                                                            }
{ Initial conversion by : Mani - mani246@yahoo.com                           }
{ Initial conversion on : 23-Mar-2002                                        }
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
{ * Updated: 03-jun-2002 Juha Hartikainen (juha@linearteam.org)              }
{ - Changed this to real unit}
{ - Around 100 little fixes to make this compile }
{}
{ * Updated: 06-jun-2002 Juha Hartikainen (juha@linearteam.org)              }
{ - Unit compiles now }
{                                                                            }
{----------------------------------------------------------------------------}

// cl.input.pas  -- builds an intended movement command to send to the server

unit cl_input;

interface

uses
  q_shared,
  client;

procedure IN_CenterView; cdecl;

procedure CL_SendCmd;
procedure CL_InitInput;

var
  cl_nodelta: cvar_p;
  frame_msec,
    old_sys_frame_time: Cardinal;

var
  cl_upspeed,
    cl_forwardspeed,
    cl_sidespeed,
    cl_yawspeed,
    cl_pitchspeed,
    cl_run,
    cl_anglespeedkey: cvar_p;

  {*
  ===============================================================================

  KEY BUTTONS

  Continuous button event tracking is complicated by the fact that two different
  input sources (say, mouse button 1 and the control key) can both press the
  same button, but the button should only be released when both of the
  pressing key have been released.

  When a key event issues a button command (+forward, +attack, etc), it appends
  its key number as a parameter to the command so it can be matched up with
  the release.

  state bit 0 is the current state of the key
  state bit 1 is edge triggered on the up to down transition
  state bit 2 is edge triggered on the down to up transition

  Key_Event (int key, qboolean down, unsigned time);

    +mlook src time

  ===============================================================================
  *}

implementation

uses
  Common,
  net_chan,
  CVar,
  SysUtils,
  Cmd,
  {$IFDEF WIN32}
  sys_win,
  q_shwin,
  in_win,
  {$ELSE}
  sys_linux,
  q_shlinux,
  in_linux,
  {$ENDIF}
  cl_main,
  Keys,
  cl_cin;

var
  in_klook,
    in_left, in_right, in_forward, in_back,
    in_lookup, in_lookdown, in_moveleft, in_moveright,
    in_strafe, in_speed, in_use, in_attack,
    in_up, in_down: kbutton_t;

  in_impulse_: integer;

procedure KeyDown(b: kbutton_p);
var
  k: integer;
  c: PChar;
begin
  c := Cmd_Argv(1);
  if (c^ <> #0) then
    k := StrToInt(c)
  else
    k := -1;                            // typed manually at the console for continuous down

  if (k = b^.down[0]) or (k = b^.down[1]) then
    Exit;                               // repeating key

  if (b^.down[0] = 0) then
    b^.down[0] := k
  else if (b^.down[1] = 0) then
    b^.down[1] := k
  else
  begin
    Com_Printf('Three keys down for a button!'#10, []);
    Exit;
  end;

  if (b^.state and 1 <> 0) then
    Exit;                               // still down

  // save timestamp
  c := Cmd_Argv(2);
  b^.downtime := StrToInt(c);
  if (b^.downtime = 0) then
    b^.downtime := sys_frame_time - 100;

  b^.state := b^.state or (1 + 2);      // down + impulse down
end;

procedure KeyUp(b: kbutton_p);
var
  k: integer;
  c: PChar;
  uptime: word;
begin
  c := Cmd_Argv(1);
  if (c <> '') then
    k := StrToInt(c)
  else
  begin                                 // typed manually at the console, assume for unsticking, so clear all
    b^.down[0] := 0;
    b^.down[1] := 0;
    b^.state := 4;                      // impulse up
    exit;
  end;

  if (b^.down[0] = k) then
    b^.down[0] := 0
  else if (b^.down[1] = k) then
    b^.down[1] := 0
  else
    exit;                               // key up without coresponding down (menu pass through)
  if (b^.down[0] <> 0) or (b^.down[1] <> 0) then
    Exit;                               // some other key is still holding it down

  if ((b^.state and 1) = 0) then
    Exit;                               // still up (this should not happen)

  // save timestamp
  c := Cmd_Argv(2);
  uptime := StrToInt(c);
  if (uptime <> 0) then
    b^.msec := b^.msec + uptime - b^.downtime
  else
    b^.msec := b^.msec + 10;

  b^.state := b^.state and (not 1);     // now up
  b^.state := b^.state or 4;            // impulse up
end;

procedure IN_KLookDown; cdecl;
begin
  KeyDown(@in_klook);
end;

procedure IN_KLookUp; cdecl;
begin
  KeyUp(@in_klook);
end;

procedure IN_UpDown; cdecl;
begin
  KeyDown(@in_up);
end;

procedure IN_UpUp; cdecl;
begin
  KeyUp(@in_up);
end;

procedure IN_DownDown; cdecl;
begin
  KeyDown(@in_down);
end;

procedure IN_DownUp; cdecl;
begin
  KeyUp(@in_down);
end;

procedure IN_LeftDown; cdecl;
begin
  KeyDown(@in_left);
end;

procedure IN_LeftUp; cdecl;
begin
  KeyUp(@in_left);
end;

procedure IN_RightDown; cdecl;
begin
  KeyDown(@in_right);
end;

procedure IN_RightUp; cdecl;
begin
  KeyUp(@in_right);
end;

procedure IN_ForwardDown; cdecl;
begin
  KeyDown(@in_forward);
end;

procedure IN_ForwardUp; cdecl;
begin
  KeyUp(@in_forward);
end;

procedure IN_BackDown; cdecl;
begin
  KeyDown(@in_back);
end;

procedure IN_BackUp; cdecl;
begin
  KeyUp(@in_back);
end;

procedure IN_LookupDown; cdecl;
begin
  KeyDown(@in_lookup);
end;

procedure IN_LookupUp; cdecl;
begin
  KeyUp(@in_lookup);
end;

procedure IN_LookdownDown; cdecl;
begin
  KeyDown(@in_lookdown);
end;

procedure IN_LookdownUp; cdecl;
begin
  KeyUp(@in_lookdown);
end;

procedure IN_MoveleftDown; cdecl;
begin
  KeyDown(@in_moveleft);
end;

procedure IN_MoveleftUp; cdecl;
begin
  KeyUp(@in_moveleft);
end;

procedure IN_MoverightDown; cdecl;
begin
  KeyDown(@in_moveright);
end;

procedure IN_MoverightUp; cdecl;
begin
  KeyUp(@in_moveright);
end;

procedure IN_SpeedDown; cdecl;
begin
  KeyDown(@in_speed);
end;

procedure IN_SpeedUp; cdecl;
begin
  KeyUp(@in_speed);
end;

procedure IN_StrafeDown; cdecl;
begin
  KeyDown(@in_strafe);
end;

procedure IN_StrafeUp; cdecl;
begin
  KeyUp(@in_strafe);
end;

procedure IN_AttackDown; cdecl;
begin
  KeyDown(@in_attack);
end;

procedure IN_AttackUp; cdecl;
begin
  KeyUp(@in_attack);
end;

procedure IN_UseDown; cdecl;
begin
  KeyDown(@in_use);
end;

procedure IN_UseUp; cdecl;
begin
  KeyUp(@in_use);
end;

procedure IN_Impulse; cdecl;
begin
  in_impulse_ := StrToInt(Cmd_Argv(1));
end;

{*
===============
CL_KeyState

Returns the fraction of the frame that the key was down
===============
*}

function CL_KeyState(key: kbutton_p): single;
var
  val: single;
  msec: integer;
begin
  key^.state := key^.state and 1;       // clear impulses

  msec := key^.msec;
  key^.msec := 0;

  if (key^.state <> 0) then
  begin                                 // still down
    msec := msec + sys_frame_time - key^.downtime;
    key^.downtime := sys_frame_time;
  end;

  {
    if (msec) then
    begin
      Com_Printf ('%d ', [msec]);
    end;
  }

  val := msec / frame_msec;
  if (val < 0) then
    val := 0;
  if (val > 1) then
    val := 1;

  result := val;
end;

//==========================================================================

{*
================
CL_AdjustAngles

Moves the local angle positions
================
*}

procedure CL_AdjustAngles;
var
  speed, up, down: single;
begin
  if (in_speed.state and 1 <> 0) then
    speed := cls.frametime * cl_anglespeedkey^.value
  else
    speed := cls.frametime;

  if ((in_strafe.state and 1) = 0) then
  begin
    cl.viewangles[YAW] := cl.viewangles[YAW] - speed * cl_yawspeed^.value * CL_KeyState(@in_right);
    cl.viewangles[YAW] := cl.viewangles[YAW] + speed * cl_yawspeed^.value * CL_KeyState(@in_left);
  end;
  if (in_klook.state and 1 <> 0) then
  begin
    cl.viewangles[PITCH] := cl.viewangles[PITCH] - speed * cl_pitchspeed^.value * CL_KeyState(@in_forward);
    cl.viewangles[PITCH] := cl.viewangles[PITCH] + speed * cl_pitchspeed^.value * CL_KeyState(@in_back);
  end;

  up := CL_KeyState(@in_lookup);
  down := CL_KeyState(@in_lookdown);

  cl.viewangles[PITCH] := cl.viewangles[PITCH] - speed * cl_pitchspeed^.value * up;
  cl.viewangles[PITCH] := cl.viewangles[PITCH] + speed * cl_pitchspeed^.value * down;
end;

{*
================
CL_BaseMove

Send the intended movement message to the server
================
*}

procedure CL_BaseMove(cmd: usercmd_p);
begin
  CL_AdjustAngles;

  FillChar(cmd^, sizeof(cmd^), #0);

  VectorCopy(cl.viewangles, cmd^.angles);
  if (in_strafe.state and 1 <> 0) then
  begin
    cmd^.sidemove := Round(cmd^.sidemove + cl_sidespeed^.value * CL_KeyState(@in_right));
    cmd^.sidemove := Round(cmd^.sidemove - cl_sidespeed^.value * CL_KeyState(@in_left));
  end;

  cmd^.sidemove := Round(cmd^.sidemove + cl_sidespeed^.value * CL_KeyState(@in_moveright));
  cmd^.sidemove := Round(cmd^.sidemove - cl_sidespeed^.value * CL_KeyState(@in_moveleft));

  cmd^.upmove := Round(cmd^.upmove + cl_upspeed^.value * CL_KeyState(@in_up));
  cmd^.upmove := Round(cmd^.upmove - cl_upspeed^.value * CL_KeyState(@in_down));

  if ((in_klook.state and 1) = 0) then
  begin
    cmd^.forwardmove := Round(cmd^.forwardmove + cl_forwardspeed^.value * CL_KeyState(@in_forward));
    cmd^.forwardmove := Round(cmd^.forwardmove - cl_forwardspeed^.value * CL_KeyState(@in_back));
  end;

  //
  // adjust for speed key / running
  //
  if ((in_speed.state and 1) xor Round(cl_run^.value)) <> 0 then
  begin
    cmd^.forwardmove := cmd^.forwardmove * 2;
    cmd^.sidemove := cmd^.sidemove * 2;
    cmd^.upmove := cmd^.upmove * 2;
  end;
end;

procedure CL_ClampPitch;
var
  pitch_: single;
begin
  pitch_ := SHORT2ANGLE(Word(cl.frame.playerstate.pmove.delta_angles[PITCH]));
  if (pitch_ > 180) then
    pitch_ := pitch_ - 360;

  if (cl.viewangles[PITCH] + pitch_ < -360) then
    cl.viewangles[PITCH] := cl.viewangles[PITCH] + 360; // wrapped
  if (cl.viewangles[PITCH] + pitch_ > 360) then
    cl.viewangles[PITCH] := cl.viewangles[PITCH] + 360; // wrapped

  if (cl.viewangles[PITCH] + pitch_ > 89) then
    cl.viewangles[PITCH] := 89 - pitch_;
  if (cl.viewangles[PITCH] + pitch_ < -89) then
    cl.viewangles[PITCH] := -89 - pitch_;
end;

{*
==============
CL_FinishMove
==============
*}

procedure CL_FinishMove(cmd: usercmd_p);
var
  ms, i: integer;
begin
  //
  // figure button bits
  //
  if (in_attack.state and 3 <> 0) then
    cmd^.buttons := cmd^.buttons or BUTTON_ATTACK;
  in_attack.state := in_attack.state and (not 2);

  if (in_use.state and 3 <> 0) then
    cmd^.buttons := cmd^.buttons or BUTTON_USE;
  in_use.state := in_use.state and (not 2);

  if (anykeydown <> 0) and (cls.key_dest = key_game) then
    cmd^.buttons := cmd^.buttons or BUTTON_ANY;

  // send milliseconds of time to apply the move
  ms := Round(cls.frametime * 1000);
  if (ms > 250) then
    ms := 100;                          // time was unreasonable
  cmd^.msec := ms;

  CL_ClampPitch;
  for i := 0 to 2 do
    cmd^.angles[i] := SmallInt(ANGLE2SHORT(cl.viewangles[i]));

  cmd^.impulse := in_impulse_;
  in_impulse_ := 0;

  // send the ambient light level at the player's current position
  cmd^.lightlevel := Round(cl_lightlevel^.value);
end;

{*
=================
CL_CreateCmd
=================
*}

function CL_CreateCmd: usercmd_t;
var
  cmd: usercmd_t;
begin
  frame_msec := sys_frame_time - old_sys_frame_time;
  if (frame_msec < 1) then
    frame_msec := 1;
  if (frame_msec > 200) then
    frame_msec := 200;

  // get basic movement from keyboard
  CL_BaseMove(@cmd);

  // allow mice or other external controllers to add to the move
  IN_Move(@cmd);

  CL_FinishMove(@cmd);

  old_sys_frame_time := sys_frame_time;

  //cmd.impulse := cls.framecount;

  result := cmd;
end;

procedure IN_CenterView;
begin
  cl.viewangles[PITCH] := -SHORT2ANGLE(cl.frame.playerstate.pmove.delta_angles[PITCH]);
end;

{*
============
CL_InitInput
============
*}

procedure CL_InitInput;
begin
  Cmd_AddCommand('centerview', IN_CenterView);

  Cmd_AddCommand('+moveup', IN_UpDown);
  Cmd_AddCommand('-moveup', IN_UpUp);
  Cmd_AddCommand('+movedown', IN_DownDown);
  Cmd_AddCommand('-movedown', IN_DownUp);
  Cmd_AddCommand('+left', IN_LeftDown);
  Cmd_AddCommand('-left', IN_LeftUp);
  Cmd_AddCommand('+right', IN_RightDown);
  Cmd_AddCommand('-right', IN_RightUp);
  Cmd_AddCommand('+forward', IN_ForwardDown);
  Cmd_AddCommand('-forward', IN_ForwardUp);
  Cmd_AddCommand('+back', IN_BackDown);
  Cmd_AddCommand('-back', IN_BackUp);
  Cmd_AddCommand('+lookup', IN_LookupDown);
  Cmd_AddCommand('-lookup', IN_LookupUp);
  Cmd_AddCommand('+lookdown', IN_LookdownDown);
  Cmd_AddCommand('-lookdown', IN_LookdownUp);
  Cmd_AddCommand('+strafe', IN_StrafeDown);
  Cmd_AddCommand('-strafe', IN_StrafeUp);
  Cmd_AddCommand('+moveleft', IN_MoveleftDown);
  Cmd_AddCommand('-moveleft', IN_MoveleftUp);
  Cmd_AddCommand('+moveright', IN_MoverightDown);
  Cmd_AddCommand('-moveright', IN_MoverightUp);
  Cmd_AddCommand('+speed', IN_SpeedDown);
  Cmd_AddCommand('-speed', IN_SpeedUp);
  Cmd_AddCommand('+attack', IN_AttackDown);
  Cmd_AddCommand('-attack', IN_AttackUp);
  Cmd_AddCommand('+use', IN_UseDown);
  Cmd_AddCommand('-use', IN_UseUp);
  Cmd_AddCommand('impulse', IN_Impulse);
  Cmd_AddCommand('+klook', IN_KLookDown);
  Cmd_AddCommand('-klook', IN_KLookUp);

  cl_nodelta := Cvar_Get('cl_nodelta', '0', 0);
end;

{*
=================
CL_SendCmd
=================
*}

procedure CL_SendCmd;
var
  buf: sizebuf_t;
  data: array[0..128 - 1] of byte;
  i, checksumIndex: integer;
  cmd, oldcmd: usercmd_p;
  nullcmd: usercmd_t;
begin
  // build a command even if not connected

  // save this command off for prediction
  i := cls.netchan.outgoing_sequence and (CMD_BACKUP - 1);
  cmd := @cl.cmds[i];
  cl.cmd_time[i] := cls.realtime;       // for netgraph ping calculation

  cmd^ := CL_CreateCmd;

  cl.cmd := cmd^;

  if (cls.state = ca_disconnected) or
    (cls.state = ca_connecting) then
    exit;

  if (cls.state = ca_connected) then
  begin
    if (cls.netchan.message.cursize <> 0) or
      (curtime - cls.netchan.last_sent > 1000) then
      Netchan_Transmit(cls.netchan, 0, PByte(buf.data));
    exit;
  end;

  // send a userinfo update if needed
  if (userinfo_modified) then
  begin
    CL_FixUpGender;
    userinfo_modified := false;
    MSG_WriteByte(cls.netchan.message, Integer(clc_userinfo));
    MSG_WriteString(cls.netchan.message, Cvar_Userinfo_());
  end;

  SZ_Init(buf, @data, sizeof(data));

  if (cmd^.buttons <> 0) and (cl.cinematictime > 0) and
    (not cl.attractloop) and
    (cls.realtime - cl.cinematictime > 1000) then
  begin                                 // skip the rest of the cinematic
    SCR_FinishCinematic;
  end;

  // begin a client move command
  MSG_WriteByte(buf, Integer(clc_move));

  // save the position for a checksum byte
  checksumIndex := buf.cursize;
  MSG_WriteByte(buf, 0);

  // let the server know what the last frame we
  // got was, so the next message can be delta compressed
  if (cl_nodelta^.value <> 0) or (not cl.frame.valid) or (cls.demowaiting) then
    MSG_WriteLong(buf, -1)              // no compression
  else
    MSG_WriteLong(buf, cl.frame.serverframe);

  // send this and the previous cmds in the message, so
  // if the last packet was dropped, it can be recovered
  i := (cls.netchan.outgoing_sequence - 2) and (CMD_BACKUP - 1);
  cmd := @cl.cmds[i];
  FillChar(nullcmd, sizeof(nullcmd), #0);
  MSG_WriteDeltaUsercmd(buf, nullcmd, cmd^);
  oldcmd := cmd;
  i := (cls.netchan.outgoing_sequence - 1) and (CMD_BACKUP - 1);
  cmd := @cl.cmds[i];
  MSG_WriteDeltaUsercmd(buf, oldcmd^, cmd^);
  oldcmd := cmd;

  i := (cls.netchan.outgoing_sequence) and (CMD_BACKUP - 1);
  cmd := @cl.cmds[i];
  MSG_WriteDeltaUsercmd(buf, oldcmd^, cmd^);
  // calculate a checksum over the move commands
  buf.data[checksumIndex] :=
    COM_BlockSequenceCRCByte(Pointer(Cardinal(buf.data) + checksumIndex + 1),
    buf.cursize - checksumIndex - 1,
    cls.netchan.outgoing_sequence);
  //
  // deliver the message
  //
  Netchan_Transmit(cls.netchan, buf.cursize, PByte(buf.data));
end;

end.
