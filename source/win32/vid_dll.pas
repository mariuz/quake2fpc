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
{ File(s): vid_dll.c                                                         }
{ Content:                                                                   }
{                                                                            }
{ Initial conversion by : Scott Price                                        }
{ Initial conversion on : 12-Jan-2002                                        }
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

unit vid_dll;

interface

{ Main windowed and fullscreen graphics interface module. This module
  is used for both the software and OpenGL rendering versions of the
  Quake refresh engine. }

uses
  { Borland Standard Units }
  Windows,
  Messages,
  MMSystem,
  SysUtils,
  { Own Units }
  Delphi_cdecl_printf,
  ref,
  keys,
  cvar,
  vid_h,
  snd_win,
  in_win,
  cl_scrn,
  Common,
  sys_win,
  q_shared,
  Console,
  snd_dma,
  Client;

{ Defined Constants }
const
  MAXPRINTMSG = 4096;

type
  vidmode_p = ^vidmode_t;
  vidmode_t = packed record
    description: PChar;                 { const char * }
    width, height: Integer;
    mode: Integer;
  end;

procedure VID_CheckChanges;
procedure VID_Init;
procedure VID_Shutdown;
function MainWndProc(h_Wnd: HWND; uMsg: Cardinal; wParam: WPARAM; lParam: LPARAM): LongInt; cdecl;

// Juha: These are only exported because our Delphi_cdecl_printf.pas needs to call them back.
procedure VID_Printf(print_level: Integer; fmt: PChar; args: array of const);
procedure VID_Error(err_level: integer; fmt: PChar; args: array of const);

(* ==========================================================================
DLL GLUE   // What this Means?
========================================================================== *)

var
  { Structure containing functions exported from refresh DLL }
  re: refexport_t;
  win_noalttab: cvar_p;

  { Console variables that we need to access from this module }
  vid_gamma: cvar_p;
  vid_ref: cvar_p;                      { Name of Refresh DLL loaded }
  vid_xpos: cvar_p;                     { X coordinate of window position }
  vid_ypos: cvar_p;                     { Y coordinate of window position }
  vid_fullscreen: cvar_p;

  { Global variables used internally by this module }
  viddef: viddef_t;                     { global video state; used by other modules }

  cl_hwnd: HWND;                        { Main window handle for life of program }

  scantokey: array[0..128 - 1] of byte = (
    //  0           1       2       3       4       5       6       7
    //  8           9       A       B       C       D       E       F
    0, 27, byte('1'), byte('2'), byte('3'), byte('4'), byte('5'), byte('6'),
    byte('7'), byte('8'), byte('9'), byte('0'), byte('-'), byte('='), K_BACKSPACE, 9, // 0
    byte('q'), byte('w'), byte('e'), byte('r'), byte('t'), byte('y'), byte('u'), byte('i'),
    byte('o'), byte('p'), byte('['), byte(']'), 13, K_CTRL, byte('a'), byte('s'), // 1
    byte('d'), byte('f'), byte('g'), byte('h'), byte('j'), byte('k'), byte('l'), byte(';'),
    byte(''''), byte('`'), K_SHIFT, byte('\'), byte('z'), byte('x'), byte('c'), byte('v'), // 2
    byte('b'), byte('n'), byte('m'), byte(','), byte('.'), byte('/'), K_SHIFT, byte('*'),
    K_ALT, byte(' '), 0, K_F1, K_F2, K_F3, K_F4, K_F5, // 3
    K_F6, K_F7, K_F8, K_F9, K_F10, K_PAUSE, 0, K_HOME,
    K_UPARROW, K_PGUP, K_KP_MINUS, K_LEFTARROW, K_KP_5, K_RIGHTARROW, K_KP_PLUS, K_END, //4
    K_DOWNARROW, K_PGDN, K_INS, K_DEL, 0, 0, 0, K_F11,
    K_F12, 0, 0, 0, 0, 0, 0, 0,         // 5
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,             // 6
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0              // 7
    );

  vid_modes: array[0..10] of vidmode_t = (* Initialize the "vid_modes" variable with these values *)
  (
    (description: 'Mode 0: 320x240'; width: 320; height: 240; mode: 0),
    (description: 'Mode 1: 400x300'; width: 400; height: 300; mode: 1),
    (description: 'Mode 2: 512x384'; width: 512; height: 384; mode: 2),
    (description: 'Mode 3: 640x480'; width: 640; height: 480; mode: 3),
    (description: 'Mode 4: 800x600'; width: 800; height: 600; mode: 4),
    (description: 'Mode 5: 960x720'; width: 960; height: 720; mode: 5),
    (description: 'Mode 6: 1024x768'; width: 1024; height: 768; mode: 6),
    (description: 'Mode 7: 1152x864'; width: 1152; height: 864; mode: 7),
    (description: 'Mode 8: 1280x960'; width: 1280; height: 960; mode: 8),
    (description: 'Mode 9: 1600x1200'; width: 1600; height: 1200; mode: 9),
    (description: 'Mode 10: 2048x1536'; width: 2048; height: 1536; mode: 10)
    );

const
  VID_NUM_MODES = (sizeof(vid_modes) / sizeof(vid_modes[0]));

implementation

uses
  cd_win,
  cl_main,
  Cmd,
  Files,
  vid_menu,
  CPas;

var
  { Static Variables  ?? }
  MSH_MOUSEWHEEL: Cardinal;
  s_alttab_disabled: qboolean;
  reflib_library: LongWord;             { Handle to refresh DLL }
  reflib_active: qboolean = False;

  { Static Function Translations }

procedure WIN_DisableAltTab;
var
  old: Boolean;
begin
  if s_alttab_disabled then
    Exit;

  if s_win95 then
    SystemParametersInfo(SPI_SCREENSAVERRUNNING, 1, @old, 0)
  else
  begin
    RegisterHotKey(0, 0, MOD_ALT, VK_TAB);
    RegisterHotKey(0, 1, MOD_ALT, VK_RETURN);
  end;

  s_alttab_disabled := True;
end;

procedure WIN_EnableAltTab;
var
  old: Boolean;
begin
  if s_alttab_disabled then
  begin
    if s_win95 then
      SystemParametersInfo(SPI_SCREENSAVERRUNNING, 0, @old, 0)
    else
    begin
      UnregisterHotKey(0, 0);
      UnregisterHotKey(0, 1);
    end;

    s_alttab_disabled := False;
  end;
end;

{ Other Routines }

procedure VID_Printf(print_level: Integer; fmt: PChar; args: array of const);
var
  msg: array[0..MAXPRINTMSG - 1] of char;
begin
  // Sly 04-Jul-2002 This is a problem because the ref DLL calls this function,
  // however it is expecting the parameters to be C-like.
  DelphiStrFmt(msg, fmt, args);
  if (print_level = PRINT_ALL) then
    Com_Printf('%s', [msg])
  else if (print_level = PRINT_DEVELOPER) then
    Com_DPrintf('%s', [msg])
  else if (print_level = PRINT_ALERT) then
  begin
    MessageBox(0, msg, 'PRINT_ALERT', MB_ICONWARNING);
    OutputDebugString(msg);
  end;
end;

procedure VID_Error(err_level: integer; fmt: PChar; args: array of const);
var
  msg: array[0..MAXPRINTMSG - 1] of char;
begin
  // Sly 04-Jul-2002 This is a problem because the ref DLL calls this function,
  // however it is expecting the parameters to be C-like.
  DelphiStrFmt(msg, fmt, args);
  //strcpy(msg, fmt);
  Com_Error(err_level, '%s', [msg]);
end;

(* ============
VID_Restart_f

Console command to re-start the video mode and refresh DLL. We do this
simply by setting the modified flag for the vid_ref variable, which will
cause the entire video mode and refresh DLL to be reset on the next frame.
============ *)

procedure VID_Restart_f; cdecl;
begin
  vid_ref.modified := True;
end;

procedure VID_Front_f; cdecl;
begin
  SetWindowLong(cl_hwnd, GWL_EXSTYLE, WS_EX_TOPMOST);
  SetForegroundWindow(cl_hwnd);
end;

(* =======
MapKey

Map from windows to quake keynums
======= *)

function MapKey(key: Integer): Integer;
var
  iResult: Integer;
  modified: Integer;
  is_extended: qboolean;
begin
  modified := (key shr 16) and 255;
  is_extended := False;

  if (modified > 127) then
  begin
    Result := 0;
    Exit;
  end;

  if (key and (1 shl 24) <> 0) then
    is_extended := True;

  iResult := scantokey[modified];

  if (not is_extended) then
  begin
    case iResult of
      K_HOME: Result := K_KP_HOME;
      K_UPARROW: Result := K_KP_UPARROW;
      K_PGUP: Result := K_KP_PGUP;
      K_LEFTARROW: Result := K_KP_LEFTARROW;
      K_RIGHTARROW: Result := K_KP_RIGHTARROW;
      K_END: Result := K_KP_END;
      K_DOWNARROW: Result := K_KP_DOWNARROW;
      K_PGDN: Result := K_KP_PGDN;
      K_INS: Result := K_KP_INS;
      K_DEL: Result := K_KP_DEL;
    else
      Result := iResult;
    end;
  end
  else
  begin
    case iResult of
      $0D: Result := K_KP_ENTER;
      $2F: Result := K_KP_SLASH;
      $AF: Result := K_KP_PLUS;
    else
      Result := iResult;
    end;
    { TODO:  Looking at the original this might have been:
    case iResult of
      $0D:  begin
        Result := K_KP_ENTER;
        Exit;
      end;
      $2F:  begin
        Result := K_KP_SLASH;
        Exit;
      end;
      $AF:  begin
        Result := K_KP_PLUS;
        Exit;
      end;
    end;

    Result:= iResult; }
  end;
end;

procedure AppActivate(fActive: Boolean; minimize: Boolean);
var
  Minimized: Boolean;
begin
  Minimized := minimize;

  Key_ClearStates;

  { we don't want to act like we're active if we're minimized }
  if (fActive and (not Minimized)) then
    ActiveApp := Integer(True)
  else
    ActiveApp := Integer(False);

  { minimize/restore mouse-capture on demand }
  if (ActiveApp = 0) then
  begin
    IN_Activate(False);
    CDAudio_Activate(False);
    S_Activate(False);

    if win_noalttab.value <> 0 then
      WIN_EnableAltTab;
  end
  else
  begin
    IN_Activate(True);
    CDAudio_Activate(True);
    S_Activate(True);

    if win_noalttab.value <> 0 then
      WIN_DisableAltTab;
  end;
end;

(* ====================
MainWndProc

main window procedure
==================== *)

function MainWndProc(h_Wnd: HWND; uMsg: Cardinal; wParam: WPARAM; lParam: LPARAM): LongInt;
var
  //  lRet: LongInt;
  fActive, fMinimized: Integer;
  xPos, yPos, style: Integer;
  temp: Integer;
  r: TRECT;
begin
  //  lRet:= 0;

  if (uMsg = MSH_MOUSEWHEEL) then
  begin
    if (wParam > 0) then
    begin
      Key_Event(K_MWHEELUP, True, sys_msg_time);
      Key_Event(K_MWHEELUP, False, sys_msg_time);
    end
    else
    begin
      Key_Event(K_MWHEELDOWN, True, sys_msg_time);
      Key_Event(K_MWHEELDOWN, False, sys_msg_time);
    end;

    Result := DefWindowProc(h_Wnd, uMsg, wParam, lParam);
    Exit;
  end;

  { Do what used to be the switch... }
  case uMsg of
    WM_MOUSEWHEEL:
      begin
        (*** this chunk of code theoretically only works under NT4 and Win98
             since this message doesn't exist under Win95 ***)
        if (SmallInt(LongRec(wParam).Hi) > 0) then
        begin
          Key_Event(K_MWHEELUP, True, sys_msg_time);
          Key_Event(K_MWHEELUP, False, sys_msg_time);
        end
        else
        begin
          Key_Event(K_MWHEELDOWN, True, sys_msg_time);
          Key_Event(K_MWHEELDOWN, False, sys_msg_time);
        end;

        //Break;
      end;
    WM_HOTKEY:
      begin
        Result := 0;
        Exit;
      end;
    WM_CREATE:
      begin
        cl_hwnd := h_Wnd;

        MSH_MOUSEWHEEL := RegisterWindowMessage('MSWHEEL_ROLLMSG');
        Result := DefWindowProc(h_Wnd, uMsg, wParam, lParam);
        Exit;
      end;
    WM_PAINT:
      begin
        { force entire screen to update next frame }
        SCR_DirtyScreen();
        Result := DefWindowProc(h_Wnd, uMsg, wParam, lParam);
        Exit;
      end;
    WM_DESTROY:
      begin
        { let sound and input know about this? }
        cl_hwnd := 0;

        Result := DefWindowProc(h_Wnd, uMsg, wParam, lParam);
        Exit;
      end;
    WM_ACTIVATE:
      begin
        { KJB: Watch this for problems in fullscreen modes with Alt-tabbing }
        fActive := LongRec(wParam).Lo;
        fMinimized := LongRec(wParam).Hi;

        AppActivate((fActive <> WA_INACTIVE), (fMinimized <> 0));

        if reflib_active then
          re.AppActivate(not (fActive = WA_INACTIVE));

        Result := DefWindowProc(h_Wnd, uMsg, wParam, lParam);
        Exit;
      end;
    WM_MOVE:
      begin
        if (vid_fullscreen.value = 0) then
        begin
          { horizontal position }
          xPos := LongRec(lParam).Lo;
          { vertical position }
          yPos := LongRec(lParam).Hi;

          r.left := 0;
          r.top := 0;
          r.right := 1;
          r.bottom := 1;

          style := GetWindowLong(h_Wnd, GWL_STYLE);
          AdjustWindowRect(r, style, FALSE);

          Cvar_SetValue('vid_xpos', xPos + r.left);
          Cvar_SetValue('vid_ypos', yPos + r.top);
          vid_xpos.modified := False;
          vid_ypos.modified := False;
          if (ActiveApp <> 0) then
            IN_Activate(True);
        end;

        Result := DefWindowProc(h_Wnd, uMsg, wParam, lParam);
        Exit;
      end;
    { this is complicated because Win32 seems to pack multiple mouse events into
      one update sometimes, so we always check all states and look for events }
    WM_LBUTTONDOWN,
      WM_LBUTTONUP,
      WM_RBUTTONDOWN,
      WM_RBUTTONUP,
      WM_MBUTTONDOWN,
      WM_MBUTTONUP,
      WM_MOUSEMOVE:
      begin
        temp := 0;

        if ((wParam and MK_LBUTTON) <> 0) then
          temp := temp or 1;

        if ((wParam and MK_RBUTTON) <> 0) then
          temp := temp or 2;

        if ((wParam and MK_MBUTTON) <> 0) then
          temp := temp or 4;

        IN_MouseEvent(temp);

      end;
    WM_SYSCOMMAND:
      begin
        if (wParam = SC_SCREENSAVE) then
        begin
          Result := 0;
          Exit;
        end;
      end;
    WM_SYSKEYDOWN:
      begin
        if (wParam = 13) then
        begin
          if (vid_fullscreen <> nil) then
            Cvar_SetValue('vid_fullscreen', Integer(not (vid_fullscreen.value <> 0)));

          Result := 0;
          Exit;
        end;
        { fall through }
        { Would seem to go through to the WM_KEYDOWN message, and then break out }
        Key_Event(MapKey(lParam), True, sys_msg_time);
      end;
    WM_KEYDOWN:
      begin
        Key_Event(MapKey(lParam), True, sys_msg_time);
        //Break;
      end;
    WM_SYSKEYUP, WM_KEYUP:
      begin
        Key_Event(MapKey(lParam), False, sys_msg_time);
        //Break;
      end;
    MM_MCINOTIFY:
      begin
        { LONG CDAudio_MessageHandler(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam); }
        { Remove the definition of this function.  Must be being called from somewhere else }
        {lRet :=} CDAudio_MessageHandler(h_Wnd, uMsg, wParam, lParam);

        //Break;
      end;
  end;

  (* return 0 if handled message, 1 if not *)
  Result := DefWindowProc(h_Wnd, uMsg, wParam, lParam);
end;

function VID_GetModeInfo(width, height: PInteger; mode: integer): qboolean; cdecl;
begin
  if (mode < 0) or (mode >= VID_NUM_MODES) then
  begin
    Result := False;
    Exit;
  end;

  width^ := vid_modes[mode].width;
  height^ := vid_modes[mode].height;

  Result := True;
end;

(*** VID_UpdateWindowPosAndSize ***)

procedure VID_UpdateWindowPosAndSize(x, y: Integer); cdecl;
var
  r: TRECT;
  style, w, h: Integer;
begin
  r.left := 0;
  r.top := 0;
  r.right := viddef.width;
  r.bottom := viddef.height;

  style := GetWindowLong(cl_hwnd, GWL_STYLE);
  AdjustWindowRect(r, style, FALSE);

  w := (r.right - r.left);
  h := (r.bottom - r.top);

  MoveWindow(cl_hwnd, Round(vid_xpos.value), Round(vid_ypos.value), w, h, TRUE);
end;

(*** VID_NewWindow ***)

procedure VID_NewWindow(width, height: Integer); cdecl;
begin
  viddef.width := width;
  viddef.height := height;

  cl.force_refdef := True;              { can't use a paused refdef }
end;

procedure VID_FreeReflib;
begin
  if (not FreeLibrary(reflib_library)) then
    Com_Error(ERR_FATAL, 'Reflib FreeLibrary failed', []);

  { ORIGINAL:  memset(@re, 0, sizeof(re)); }
  FillChar(re, SizeOf(re), 0);

  reflib_library := 0;
  reflib_active := False;
end;

(* ==============
VID_LoadRefresh
============== *)

function VID_LoadRefresh(name: PChar): qboolean; cdecl;
var
  ri: refimport_t;
  GetRefAPI: GetRefAPI_t;
begin
  if (reflib_active) then
  begin
    re.Shutdown;
    VID_FreeReflib;
  end;

  Com_Printf('------- Loading %s -------'#10, [name]);

  reflib_library := LoadLibrary(name);
  if (reflib_library = 0) then
  begin
    Com_Printf('LoadLibrary("%s") failed'#10, [name]);

    Result := False;
    Exit;
  end;

  ri.Cmd_AddCommand := Cmd_AddCommand;
  ri.Cmd_RemoveCommand := Cmd_RemoveCommand;
  ri.Cmd_Argc := Cmd_Argc;
  ri.Cmd_Argv := Cmd_Argv;
  ri.Cmd_ExecuteText := Cbuf_ExecuteText;
  ri.Con_Printf := VID_Printf_cdecl;
  ri.Sys_Error := VID_Error_cdecl;
  ri.FS_LoadFile := FS_LoadFile;
  ri.FS_FreeFile := FS_FreeFile;
  ri.FS_Gamedir := FS_Gamedir;
  ri.Cvar_Get := Cvar_Get;
  ri.Cvar_Set := Cvar_Set;
  ri.Cvar_SetValue := Cvar_SetValue;
  ri.Vid_GetModeInfo := VID_GetModeInfo;
  ri.Vid_MenuInit := VID_MenuInit;
  ri.Vid_NewWindow := VID_NewWindow;

  { ORIGINAL:     if ( ( GetRefAPI = (void *) GetProcAddress( reflib_library, "GetRefAPI" ) ) == 0 )  }
  GetRefApi := GetProcAddress(reflib_library, 'GetRefAPI');
  if not Assigned(GetRefApi) then
    Com_Error(ERR_FATAL, 'GetProcAddress failed on %s', [name]);

  re := GetRefAPI(ri);

  if (re.api_version <> API_VERSION) then
  begin
    VID_FreeReflib;
    Com_Error(ERR_FATAL, '%s has incompatible api_version', [name]);
  end;

  if (re.Init(global_hInstance, @MainWndProc) = -1) then
  begin
    re.Shutdown;
    VID_FreeReflib;
    Result := False;
    Exit;
  end;

  Com_Printf('------------------------------------'#10, []);
  reflib_active := True;

  //======
  //PGM
  vidref_val := VIDREF_OTHER;
  if Assigned(vid_ref) then
  begin
    if (StrComp(vid_ref.string_, 'gl') = 0) then
      vidref_val := VIDREF_GL
    else if (StrComp(vid_ref.string_, 'soft') = 0) then
      vidref_val := VIDREF_SOFT;
  end;
  //PGM
  //======

  Result := True;
end;

{*
============
VID_CheckChanges

This function gets called once just before drawing each frame, and it's sole purpose in life
is to check to see if any of the video mode parameters have changed, and if they have to
update the rendering DLL and/or video mode to match.
============
*}

procedure VID_CheckChanges;
var
  name: array[0..100 - 1] of Char;
begin
  if (win_noalttab.modified) then
  begin
    if (win_noalttab.value <> 0) then
      WIN_DisableAltTab
    else
      WIN_EnableAltTab;

    win_noalttab.modified := False;
  end;

  if (vid_ref.modified) then
  begin
    cl.force_refdef := True;            { can't use a paused refdef }
    S_StopAllSounds;
  end;

  while (vid_ref.modified) do
  begin
    (*** refresh has changed ***)
    vid_ref.modified := False;
    vid_fullscreen.modified := True;
    cl.refresh_prepped := False;
    cls.disable_screen := Integer(True);

    Com_sprintf(name, SizeOf(name), 'ref_%s.dll', [vid_ref.string_]);

    if (not VID_LoadRefresh(name)) then
    begin
      if (CompareStr(vid_ref.string_, 'soft') = 0) then
        Com_Error(ERR_FATAL, 'Couldn''t fall back to software refresh!', []);

      Cvar_Set('vid_ref', 'soft');

      (*** drop the console if we fail to load a refresh ***)
      if (cls.key_dest <> key_console) then
        Con_ToggleConsole_f;
    end;

    cls.disable_screen := Integer(False);
  end;

  (*** update our window position ***)
  if (vid_xpos.modified or vid_ypos.modified) then
  begin
    if (vid_fullscreen.value = 0) then
      VID_UpdateWindowPosAndSize(Round(vid_xpos.value), Round(vid_ypos.value));

    vid_xpos.modified := False;
    vid_ypos.modified := False;
  end;
end;

(* ============
VID_Init
============ *)

procedure VID_Init;
begin
  { Create the video variables so we know how to start the graphics drivers }
  vid_ref := Cvar_Get('vid_ref', 'soft', CVAR_ARCHIVE);
  vid_xpos := Cvar_Get('vid_xpos', '3', CVAR_ARCHIVE);
  vid_ypos := Cvar_Get('vid_ypos', '22', CVAR_ARCHIVE);
  vid_fullscreen := Cvar_Get('vid_fullscreen', '0', CVAR_ARCHIVE);
  vid_gamma := Cvar_Get('vid_gamma', '1', CVAR_ARCHIVE);
  win_noalttab := Cvar_Get('win_noalttab', '0', CVAR_ARCHIVE);

  { Add some console commands that we want to handle }
  Cmd_AddCommand('vid_restart', @VID_Restart_f);
  Cmd_AddCommand('vid_front', @VID_Front_f);

  (*
  ** this is a gross hack but necessary to clamp the mode for 3Dfx
  *)
(*
  {
          cvar_t *gl_driver = Cvar_Get( "gl_driver", "opengl32", 0 );
          cvar_t *gl_mode = Cvar_Get( "gl_mode", "3", 0 );

          if ( stricmp( gl_driver->string, "3dfxgl" ) == 0 )
          {
                  Cvar_SetValue( "gl_mode", 3 );
                  viddef.width  = 640;
                  viddef.height = 480;
          }
  }
*)

  { Disable the 3Dfx splash screen }
  Windows.SetEnvironmentVariable('FX_GLIDE_NO_SPLASH', '0');

  { Start the graphics mode and load refresh DLL }
  VID_CheckChanges;
end;

(* ============
VID_Shutdown
============ *)

procedure VID_Shutdown;
begin
  if (reflib_active) then
  begin
    re.Shutdown;
    VID_FreeReflib;
  end;
end;

end.
