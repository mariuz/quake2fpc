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
{ File(s): in_win.c                                                          }
{ Content: Quake2\Win32\ support for qhost                                   }
{                                                                            }
{ Initial conversion by : andre                                              }
{ Initial conversion on : 02-May-2002                                        }
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
{ 03-jun-2002 Juha Hartikainen (juha@linearteam.org)                         }
{ - Added missing units to uses clause.                    }
{}
{ 06-jun-2002 Juha Hartikainen (juha@linearteam.org)                         }
{ - Finished conversion.                    }
{----------------------------------------------------------------------------}

unit in_win;

// in_win.c -- windows 95 mouse and joystick code
// 02/21/97 JCB Added extended DirectInput code to support external controllers.

//------------------------------------------------------------------------------
// translated by andre: all my comments are marked with (andre),
//                      other comments are original
//------------------------------------------------------------------------------

interface

uses
  q_shared,
  CPas,
  CVar;

procedure IN_Activate(active: qboolean);
procedure IN_Frame;
procedure IN_Commands;
procedure IN_Init;
procedure IN_MouseEvent(mstate: Integer);
procedure IN_Move(cmd: usercmd_p);
procedure IN_Shutdown;

var
  in_joystick: cvar_p;

implementation

uses
  client,
  sys_win,
  cl_input,
  cl_main,
  vid_dll,
  keys,
  common,
  MMSystem,
  Windows,
  Types,
  Cmd;

// joystick defines and variables
// where should defines be moved?
const
  JOY_ABSOLUTE_AXIS = $00000000;        // control like a joystick
  JOY_RELATIVE_AXIS = $00000010;        // control like a mouse, spinner, trackball
  JOY_MAX_AXES = 6;                     // X, Y, Z, R, U, V
  JOY_AXIS_X = 0;
  JOY_AXIS_Y = 1;
  JOY_AXIS_Z = 2;
  JOY_AXIS_R = 3;
  JOY_AXIS_U = 4;
  JOY_AXIS_V = 5;

type
  _ControlList = (AxisNada = 0, AxisForward, AxisLook, AxisSide, AxisTurn, AxisUp);

const
  dwAxisFlags: array[0..JOY_MAX_AXES - 1] of DWord =
  (
    JOY_RETURNX, JOY_RETURNY, JOY_RETURNZ, JOY_RETURNR, JOY_RETURNU, JOY_RETURNV
    );

var
  dwAxisMap: array[0..JOY_MAX_AXES - 1] of DWord;
  dwControlMap: array[0..JOY_MAX_AXES - 1] of DWord;
  pdwRawValue: array[0..JOY_MAX_AXES - 1] of PDWord;

  in_mouse: cvar_p;

  // none of these cvars are saved over a session
  // this means that advanced controller configuration needs to be executed
  // each time.  this avoids any problems with getting back to a default usage
  // or when changing from one controller to another.  this way at least something
  // works.
  joy_name: cvar_p;
  joy_advanced: cvar_p;
  joy_advaxisx: cvar_p;
  joy_advaxisy: cvar_p;
  joy_advaxisz: cvar_p;
  joy_advaxisr: cvar_p;
  joy_advaxisu: cvar_p;
  joy_advaxisv: cvar_p;
  joy_forwardthreshold: cvar_p;
  joy_sidethreshold: cvar_p;
  joy_pitchthreshold: cvar_p;
  joy_yawthreshold: cvar_p;
  joy_forwardsensitivity: cvar_p;
  joy_sidesensitivity: cvar_p;
  joy_pitchsensitivity: cvar_p;
  joy_yawsensitivity: cvar_p;
  joy_upthreshold: cvar_p;
  joy_upsensitivity: cvar_p;

  joy_avail, joy_advancedinit, joy_haspov: qboolean;
  joy_oldbuttonstate, joy_oldpovstate: DWORD;

  joy_id: Integer;
  joy_flags: DWORD;
  joy_numbuttons: DWORD;

  ji: JOYINFOEX;

  in_appactive: qboolean;

  // forward-referenced functions
procedure IN_StartupJoystick; forward;

procedure Joy_AdvancedUpdate_f; cdecl; forward;
procedure IN_JoyMove(cmd: usercmd_p); forward;

(*
============================================================

  MOUSE CONTROL

============================================================
*)

// mouse variables
var
  m_filter: cvar_p;
  mlooking: qboolean;

procedure IN_MLookDown; cdecl;
begin
  mlooking := true;
end;

procedure IN_MLookUp; cdecl;
begin
  mlooking := false;
  if (freelook^.value = 0) and (lookspring^.value <> 0) then
    IN_CenterView;
end;

var
  mouse_buttons: Integer;
  mouse_oldbuttonstate: Integer;
  current_pos: TPoint;
  mouse_x, mouse_y,
    old_mouse_x, old_mouse_y,
    mx_accum, my_accum: Integer;

  old_x, old_y: Integer;

  mouseactive: qboolean;                // false when not focus app

  restore_spi: qboolean;
  mouseinitialized: qboolean;
  mouseparmsvalid: qboolean;

  window_center_x,
    window_center_y: Integer;
  window_rect: TRECT;

const
  originalmouseparms: array[0..2] of integer = (0, 0, 1);
  newmouseparms: array[0..2] of integer = (0, 0, 1);

  (*
  ===========
  IN_ActivateMouse

  Called when the window gains focus or changes in some way
  ===========
  *)

procedure IN_ActivateMouse;
var
  width, height: Integer;
begin
  if not mouseinitialized then
    exit;
  if (in_mouse^.value = 0) then
  begin
    mouseactive := false;
    exit;
  end;
  if mouseactive then
    exit;

  mouseactive := true;

  if mouseparmsvalid then
    restore_spi := SystemParametersInfo(SPI_SETMOUSE, 0, @newmouseparms, 0);

  width := GetSystemMetrics(SM_CXSCREEN);
  height := GetSystemMetrics(SM_CYSCREEN);

  GetWindowRect(cl_hwnd, window_rect);
  if window_rect.left < 0 then
    window_rect.left := 0;
  if window_rect.top < 0 then
    window_rect.top := 0;
  if window_rect.right >= width then
    window_rect.right := width - 1;
  if window_rect.bottom >= height - 1 then
    window_rect.bottom := height - 1;

  window_center_x := (window_rect.right + window_rect.left) div 2;
  window_center_y := (window_rect.top + window_rect.bottom) div 2;

  SetCursorPos(window_center_x, window_center_y);

  old_x := window_center_x;
  old_y := window_center_y;

  SetCapture(cl_hwnd);
  ClipCursor(@window_rect);
  while ShowCursor(FALSE) >= 0 do
    ;
end;

(*
===========
IN_DeactivateMouse

Called when the window loses focus
===========
*)

procedure IN_DeactivateMouse;
begin
  if not mouseinitialized then
    exit;
  if not mouseactive then
    exit;

  if restore_spi then
    SystemParametersInfo(SPI_SETMOUSE, 0, @originalmouseparms, 0);

  mouseactive := false;

  ClipCursor(NULL);
  ReleaseCapture;
  while (ShowCursor(TRUE) < 0) do
    ;
end;

(*
===========
IN_StartupMouse
===========
*)

procedure IN_StartupMouse;
var
  cv: cvar_p;
begin
  cv := Cvar_Get('in_initmouse', '1', CVAR_NOSET);
  if (cv^.value = 0) then
    exit;

  mouseinitialized := true;
  mouseparmsvalid := SystemParametersInfo(SPI_GETMOUSE, 0, @originalmouseparms, 0);
  mouse_buttons := 3;
end;

(*
===========
IN_MouseEvent
===========
*)

procedure IN_MouseEvent(mstate: Integer);
var
  i: Integer;
begin
  if not mouseinitialized then
    exit;

  // perform button actions
  for i := 0 to mouse_buttons - 1 do
  begin
    if ((mstate and (1 shl i)) <> 0) and
      not ((mouse_oldbuttonstate and (1 shl i)) <> 0) then
    begin
      keys.Key_Event(K_MOUSE1 + i, true, sys_msg_time);
    end;

    if not ((mstate and (1 shl i)) <> 0) and
      ((mouse_oldbuttonstate and (1 shl i)) <> 0) then
    begin
      keys.Key_Event(K_MOUSE1 + i, false, sys_msg_time);
    end;
  end;

  mouse_oldbuttonstate := mstate;
end;

(*
===========
IN_MouseMove
===========
*)

procedure IN_MouseMove(cmd: usercmd_p);
var
  mx, my: Integer;
begin
  if not mouseactive then
    exit;

  // find mouse movement
  if not GetCursorPos(current_pos) then
    exit;

  mx := current_pos.x - window_center_x;
  my := current_pos.y - window_center_y;

  if (m_filter^.value <> 0) then
  begin
    mouse_x := (mx + old_mouse_x) div 2;
    mouse_y := (my + old_mouse_y) div 2;
  end
  else
  begin
    mouse_x := mx;
    mouse_y := my;
  end;

  old_mouse_x := mx;
  old_mouse_y := my;

  mouse_x := Round(mouse_x * sensitivity^.value);
  mouse_y := Round(mouse_y * sensitivity^.value);
  if ((in_strafe.state and 1 <> 0) or
    ((lookstrafe.value <> 0) and mlooking)) then
    cmd^.sidemove := Round(cmd^.sidemove + (m_side^.value * mouse_x))
  else
    cl.viewangles[YAW] := cl.viewangles[YAW] - (m_yaw^.value * mouse_x);

  if ((mlooking or (freelook.value <> 0)) and
    not (in_strafe.state and 1 <> 0)) then
  begin
    cl.viewangles[PITCH] := cl.viewangles[PITCH] + (m_pitch^.value * mouse_y);
  end
  else
  begin
    cmd^.forwardmove := Round(cmd^.forwardmove - (m_forward^.value * mouse_y));
  end;

  // force the mouse to the center, so there's room to move
  if (mx <> 0) or (my <> 0) then
    SetCursorPos(window_center_x, window_center_y);
end;

(*
=========================================================================

VIEW CENTERING

=========================================================================
*)

var
  v_centermove: cvar_p;
  v_centerspeed: cvar_p;

  (*
  ===========
  IN_Init
  ===========
  *)

procedure IN_Init;
begin
  // mouse variables
  m_filter := Cvar_Get('m_filter', '0', 0);
  in_mouse := Cvar_Get('in_mouse', '1', CVAR_ARCHIVE);

  // joystick variables
  in_joystick := Cvar_Get('in_joystick', '0', CVAR_ARCHIVE);
  joy_name := Cvar_Get('joy_name', 'joystick', 0);
  joy_advanced := Cvar_Get('joy_advanced', '0', 0);
  joy_advaxisx := Cvar_Get('joy_advaxisx', '0', 0);
  joy_advaxisy := Cvar_Get('joy_advaxisy', '0', 0);
  joy_advaxisz := Cvar_Get('joy_advaxisz', '0', 0);
  joy_advaxisr := Cvar_Get('joy_advaxisr', '0', 0);
  joy_advaxisu := Cvar_Get('joy_advaxisu', '0', 0);
  joy_advaxisv := Cvar_Get('joy_advaxisv', '0', 0);
  joy_forwardthreshold := Cvar_Get('joy_forwardthreshold', '0.15', 0);
  joy_sidethreshold := Cvar_Get('joy_sidethreshold', '0.15', 0);
  joy_upthreshold := Cvar_Get('joy_upthreshold', '0.15', 0);
  joy_pitchthreshold := Cvar_Get('joy_pitchthreshold', '0.15', 0);
  joy_yawthreshold := Cvar_Get('joy_yawthreshold', '0.15', 0);
  joy_forwardsensitivity := Cvar_Get('joy_forwardsensitivity', '-1', 0);
  joy_sidesensitivity := Cvar_Get('joy_sidesensitivity', '-1', 0);
  joy_upsensitivity := Cvar_Get('joy_upsensitivity', '-1', 0);
  joy_pitchsensitivity := Cvar_Get('joy_pitchsensitivity', '1', 0);
  joy_yawsensitivity := Cvar_Get('joy_yawsensitivity', '-1', 0);
  // centering
  v_centermove := Cvar_Get('v_centermove', '0.15', 0);
  v_centerspeed := Cvar_Get('v_centerspeed', '500', 0);

  Cmd_AddCommand('+mlook', IN_MLookDown);
  Cmd_AddCommand('-mlook', IN_MLookUp);

  Cmd_AddCommand('joy_advancedupdate', Joy_AdvancedUpdate_f);

  IN_StartupMouse();
  IN_StartupJoystick();
end;

(*
===========
IN_Shutdown
===========
*)

procedure IN_Shutdown;
begin
  IN_DeactivateMouse;
end;

(*
===========
IN_Activate

Called when the main window gains or loses focus.
The window may have been destroyed and recreated
between a deactivate and an activate.
===========
*)

procedure IN_Activate(active: qboolean);
begin
  in_appactive := active;
  mouseactive := not active;            // force a new window check or turn off
end;

(*
==================
IN_Frame

Called every frame, even if not generating commands
==================
*)

procedure IN_Frame;
begin
  if not mouseinitialized then
    exit;

  if (in_mouse = nil) or (not in_appactive) then
  begin
    IN_DeactivateMouse;
    exit;
  end;

  if (not cl.refresh_prepped)
    or (cls.key_dest = key_console)
    or (cls.key_dest = key_menu) then
  begin
    // temporarily deactivate if in fullscreen
    if (Cvar_VariableValue('vid_fullscreen') = 0) then
    begin
      IN_DeactivateMouse;
      exit;
    end;
  end;

  IN_ActivateMouse;
end;

(*
===========
IN_Move
===========
*)

procedure IN_Move(cmd: usercmd_p);
begin
  IN_MouseMove(cmd);

  if (ActiveApp <> 0) then
    IN_JoyMove(cmd);
end;

(*
===================
IN_ClearStates
===================
*)

procedure IN_ClearStates;
begin
  mx_accum := 0;
  my_accum := 0;
  mouse_oldbuttonstate := 0;
end;

(*
=========================================================================

JOYSTICK

=========================================================================
*)

(*
===============
IN_StartupJoystick
===============
*)

procedure IN_StartupJoystick;
var
  numdevs: Integer;
  jc: JOYCAPS;
  mmr: MMRESULT;
  cv: cvar_p;
begin

  // assume no joystick
  joy_avail := false;

  // abort startup if user requests no joystick
  cv := Cvar_Get('in_initjoy', '1', CVAR_NOSET);
  if cv^.value = 0 then
    exit;

  // verify joystick driver is present
  numdevs := joyGetNumDevs();
  if (numdevs = 0) then
  begin
    //      Com_Printf (#10'joystick not found -- driver not present'#10#10, []);
    Exit;
  end;

  // cycle through the joystick ids for the first valid one
  joy_id := 0;
  while joy_id < numdevs do
  begin
    FillChar(ji, sizeof(ji), 0);
    ji.dwSize := sizeof(ji);
    ji.dwFlags := JOY_RETURNCENTERED;
    mmr := joyGetPosEx(joy_id, @ji);
    if (mmr = JOYERR_NOERROR) then
      break;
    Inc(joy_id);
  end;

  // abort startup if we didn't find a valid joystick
  if mmr <> JOYERR_NOERROR then
  begin
    Com_Printf(#10'joystick not found -- no valid joysticks (%x)'#10#10, [mmr]);
    exit;
  end;

  // get the capabilities of the selected joystick
  // abort startup if command fails
  FillChar(jc, sizeof(jc), 0);
  mmr := joyGetDevCaps(joy_id, @jc, sizeof(jc));
  if (mmr <> JOYERR_NOERROR) then
  begin
    Com_Printf(#10'joystick not found -- invalid joystick capabilities (%x)'#10#10, [mmr]);
    exit;
  end;

  // save the joystick's number of buttons and POV status
  joy_numbuttons := jc.wNumButtons;
  joy_haspov := (jc.wCaps and JOYCAPS_HASPOV) <> 0;

  // old button and POV states default to no buttons pressed
  joy_oldbuttonstate := 0;
  joy_oldpovstate := 0;

  // mark the joystick as available and advanced initialization not completed
  // this is needed as cvars are not available during initialization

  joy_avail := true;
  joy_advancedinit := false;

  Com_Printf(#10'joystick detected'#10#10, []);
end;

(*
===========
RawValuePointer
===========
*)

function RawValuePointer(axis: Integer): PDWORD;
begin
  case axis of
    JOY_AXIS_X: Result := @ji.wXpos;
    JOY_AXIS_Y: Result := @ji.wYpos;
    JOY_AXIS_Z: Result := @ji.wZpos;
    JOY_AXIS_R: Result := @ji.dwRpos;
    JOY_AXIS_U: Result := @ji.dwUpos;
    JOY_AXIS_V: Result := @ji.dwVpos;
  end;
end;

(*
===========
Joy_AdvancedUpdate_f
===========
*)

procedure Joy_AdvancedUpdate_f; cdecl;
var
  // called once by IN_ReadJoystick and by user whenever an update is needed
  // cvars are now available
  i: Integer;
  dwTemp: DWORD;
begin
  // initialize all the maps
  for i := 0 to JOY_MAX_AXES - 1 do
  begin
    dwAxisMap[i] := Cardinal(AxisNada);
    dwControlMap[i] := JOY_ABSOLUTE_AXIS;
    pdwRawValue[i] := RawValuePointer(i);
  end;

  if joy_advanced^.value = 0.0 then
  begin
    // default joystick initialization
    // 2 axes only with joystick control
    dwAxisMap[JOY_AXIS_X] := Cardinal(AxisTurn);
    // dwControlMap[JOY_AXIS_X] = JOY_ABSOLUTE_AXIS;
    dwAxisMap[JOY_AXIS_Y] := Cardinal(AxisForward);
    // dwControlMap[JOY_AXIS_Y] = JOY_ABSOLUTE_AXIS;
  end
  else
  begin
    if strcmp(joy_name^.string_, 'joystick') <> 0 then
    begin
      // notify user of advanced controller
      Com_Printf(#10'%s configured'#10#10, [joy_name^.string_]);
    end;

    // advanced initialization here
    // data supplied by user via joy_axisn cvars
    dwTemp := Round(joy_advaxisx^.value);
    dwAxisMap[JOY_AXIS_X] := dwTemp and $0000000F;
    dwControlMap[JOY_AXIS_X] := dwTemp and JOY_RELATIVE_AXIS;
    dwTemp := Round(joy_advaxisy^.value);
    dwAxisMap[JOY_AXIS_Y] := dwTemp and $0000000F;
    dwControlMap[JOY_AXIS_Y] := dwTemp and JOY_RELATIVE_AXIS;
    dwTemp := Round(joy_advaxisz^.value);
    dwAxisMap[JOY_AXIS_Z] := dwTemp and $0000000F;
    dwControlMap[JOY_AXIS_Z] := dwTemp and JOY_RELATIVE_AXIS;
    dwTemp := Round(joy_advaxisr^.value);
    dwAxisMap[JOY_AXIS_R] := dwTemp and $0000000F;
    dwControlMap[JOY_AXIS_R] := dwTemp and JOY_RELATIVE_AXIS;
    dwTemp := Round(joy_advaxisu^.value);
    dwAxisMap[JOY_AXIS_U] := dwTemp and $0000000F;
    dwControlMap[JOY_AXIS_U] := dwTemp and JOY_RELATIVE_AXIS;
    dwTemp := Round(joy_advaxisv^.value);
    dwAxisMap[JOY_AXIS_V] := dwTemp and $0000000F;
    dwControlMap[JOY_AXIS_V] := dwTemp and JOY_RELATIVE_AXIS;
  end;

  // compute the axes to collect from DirectInput
  joy_flags := JOY_RETURNCENTERED or JOY_RETURNBUTTONS or JOY_RETURNPOV;
  for i := 0 to JOY_MAX_AXES - 1 do
  begin
    if (dwAxisMap[i] <> Cardinal(AxisNada)) then
    begin
      joy_flags := joy_flags or dwAxisFlags[i];
    end;
  end;
end;

(*
===========
IN_Commands
===========
*)

procedure IN_Commands;
var
  i, key_index: Integer;
  buttonstate, povstate: DWORD;
begin
  if not joy_avail then
  begin
    exit;
  end;

  // loop through the joystick buttons
  // key a joystick event or auxillary event for higher number buttons for each state change
  buttonstate := ji.wButtons;
  for i := 0 to joy_numbuttons - 1 do
  begin
    if ((buttonstate and (1 shl i) <> 0) and
      not (joy_oldbuttonstate and (1 shl i) <> 0)) then
    begin
      if i < 4 then
        key_index := K_JOY1
      else
        key_index := K_AUX1;
      keys.Key_Event(key_index + i, true, 0);
    end;

    if (not (buttonstate and (1 shl i) <> 0) and
      (joy_oldbuttonstate and (1 shl i) <> 0)) then
    begin
      if i < 4 then
        key_index := K_JOY1
      else
        key_index := K_AUX1;
      keys.Key_Event(key_index + i, false, 0);
    end;
  end;
  joy_oldbuttonstate := buttonstate;

  if joy_haspov then
  begin
    // convert POV information into 4 bits of state information
    // this avoids any potential problems related to moving from one
    // direction to another without going through the center position
    povstate := 0;
    if not (ji.dwPOV = JOY_POVCENTERED) then
    begin
      if (ji.dwPOV = JOY_POVFORWARD) then
        povstate := povstate or $01;
      if (ji.dwPOV = JOY_POVRIGHT) then
        povstate := povstate or $02;
      if (ji.dwPOV = JOY_POVBACKWARD) then
        povstate := povstate or $04;
      if (ji.dwPOV = JOY_POVLEFT) then
        povstate := povstate or $08;
    end;
    // determine which bits have changed and key an auxillary event for each change
    for i := 0 to 3 do
    begin
      if ((povstate and (1 shl i) <> 0) and
        not (joy_oldpovstate and (1 shl i) <> 0)) then
      begin
        keys.Key_Event(K_AUX29 + i, true, 0);
      end;

      if (not (povstate and (1 shl i) <> 0) and
        (joy_oldpovstate and (1 shl i) <> 0)) then
      begin
        keys.Key_Event(K_AUX29 + i, false, 0);
      end;
    end;
    joy_oldpovstate := povstate;
  end;
end;

(*
===============
IN_ReadJoystick
===============
*)

function IN_ReadJoystick: qboolean;
begin

  FillChar(ji, sizeof(ji), 0);
  ji.dwSize := sizeof(ji);
  ji.dwFlags := joy_flags;

  if joyGetPosEx(joy_id, @ji) = JOYERR_NOERROR then
  begin
    Result := true;
  end
  else
  begin
    // read error occurred
    // turning off the joystick seems too harsh for 1 read error,\
    // but what should be done?
    // Com_Printf ('IN_ReadJoystick: no response'#10);
    // joy_avail = false;
    Result := false;
  end;
end;

(*
===========
IN_JoyMove
===========
*)

procedure IN_JoyMove(cmd: usercmd_p);
var
  speed, aspeed: Single;
  fAxisValue: Single;
  i: Integer;
begin

  // complete initialization if first time in
  // this is needed as cvars are not available at initialization time
  if not (joy_advancedinit) then
  begin
    Joy_AdvancedUpdate_f;
    joy_advancedinit := true;
  end;

  // verify joystick is available and that the user wants to use it
  if not (joy_avail) or not (in_joystick^.value <> 0) then
  begin
    exit;
  end;

  // collect the joystick data, if possible
  if not IN_ReadJoystick then
  begin
    exit;
  end;

  if ((in_speed.state and 1) xor (round(cl_run.value)) <> 0) then
    speed := 2
  else
    speed := 1;
  aspeed := speed * cls.frametime;

  // loop through the axes
  for i := 0 to JOY_MAX_AXES - 1 do
  begin
    // get the floating point zero-centered, potentially-inverted data for the current axis
    fAxisValue := pdwRawValue[i]^;
    // move centerpoint to zero
    fAxisValue := fAxisValue - 32768.0;

    // convert range from -32768..32767 to -1..1
    fAxisValue := fAxisValue / 32768.0;

    case _ControlList(dwAxisMap[i]) of
      AxisForward:
        begin
          if ((joy_advanced^.value = 0.0) and mlooking) then
          begin
            // user wants forward control to become look control
            if (fabs(fAxisValue) > joy_pitchthreshold^.value) then
            begin
              // if mouse invert is on, invert the joystick pitch value
              // only absolute control support here (joy_advanced is false)
              if (m_pitch^.value < 0.0) then
              begin
                cl.viewangles[PITCH] := cl.viewangles[PITCH] - (fAxisValue * joy_pitchsensitivity.value) * aspeed * cl_pitchspeed.value;
              end
              else
              begin
                cl.viewangles[PITCH] := cl.viewangles[PITCH] + (fAxisValue * joy_pitchsensitivity.value) * aspeed * cl_pitchspeed.value;
              end;
            end;
          end
          else
          begin
            // user wants forward control to be forward control
            if (fabs(fAxisValue) > joy_forwardthreshold^.value) then
            begin
              cmd.forwardmove := Round(cmd.forwardmove + (fAxisValue * joy_forwardsensitivity.value) * speed * cl_forwardspeed.value);
            end;
          end;
        end;
      AxisSide:
        begin
          if (fabs(fAxisValue) > joy_sidethreshold^.value) then
          begin
            cmd.sidemove := Round(cmd.sidemove + (fAxisValue * joy_sidesensitivity.value) * speed * cl_sidespeed.value);
          end;
        end;
      AxisUp:
        begin
          if (fabs(fAxisValue) > joy_upthreshold^.value) then
          begin
            cmd.upmove := Round(cmd.upmove + (fAxisValue * joy_upsensitivity.value) * speed * cl_upspeed.value);
          end;
        end;
      AxisTurn:
        begin
          if ((in_strafe.state and 1 <> 0) or ((lookstrafe.value <> 0) and mlooking)) then
          begin
            // user wants turn control to become side control
            if (fabs(fAxisValue) > joy_sidethreshold.value) then
            begin
              cmd.sidemove := Round(cmd.sidemove - (fAxisValue * joy_sidesensitivity.value) * speed * cl_sidespeed.value);
            end;
          end
          else
          begin
            // user wants turn control to be turn control
            if (fabs(fAxisValue) > joy_yawthreshold.value) then
            begin
              if (dwControlMap[i] = JOY_ABSOLUTE_AXIS) then
              begin
                cl.viewangles[YAW] := Round(cl.viewangles[YAW] + (fAxisValue * joy_yawsensitivity.value) * aspeed * cl_yawspeed.value);
              end
              else
              begin
                cl.viewangles[YAW] := cl.viewangles[YAW] + (fAxisValue * joy_yawsensitivity.value) * speed * 180.0;
              end;

            end;
          end;
        end;
      AxisLook:
        begin
          if (mlooking) then
          begin
            if (fabs(fAxisValue) > joy_pitchthreshold.value) then
            begin
              // pitch movement detected and pitch movement desired by user
              if (dwControlMap[i] = JOY_ABSOLUTE_AXIS) then
              begin
                cl.viewangles[PITCH] := cl.viewangles[PITCH] + (fAxisValue * joy_pitchsensitivity.value) * aspeed * cl_pitchspeed.value;
              end
              else
              begin
                cl.viewangles[PITCH] := cl.viewangles[PITCH] + (fAxisValue * joy_pitchsensitivity.value) * speed * 180.0;
              end;
            end;
          end;
        end;
    end;
  end;
end;

end.
