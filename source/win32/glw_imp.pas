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
{ File(s): GLW_IMP.C                                                         }
{                                                                            }
{ Initial conversion by : YgriK (Igor Karpov) - glYgriK@hotbox.ru            }
{ Initial conversion on : 18-Jan-2002                                        }
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

{*
** GLW_IMP.C
**
** This file contains ALL Win32 specific stuff having to do with the
** OpenGL refresh.  When a port is being made the following functions
** must be implemented by the port:
**
** GLimp_EndFrame
** GLimp_Init
** GLimp_Shutdown
** GLimp_SwitchFullscreen
**
*}

unit glw_imp;

interface

uses
  q_shared,
  glw_win,
  qgl_win,
  gl_local;

//NB! none cdecl
function GLimp_SetMode(var pwidth, pheight: integer;
  mode: integer; fullscreen: qboolean): rserr_t;
procedure GLimp_Shutdown;
function GLimp_Init(hinstance: HINST; wndproc: pointer): qboolean; //add info: glw_win.inc: glwstate_t
procedure GLimp_BeginFrame(camera_separation: Single);

//NB! cdecl
procedure GLimp_EndFrame; cdecl;
procedure GLimp_AppActivate(active: qboolean); cdecl;

var
  glw_state: glwstate_t;

implementation

uses
  CPas,
  Windows,
  ref,
  gl_rmain,
  OpenGL;

function GLimp_InitGL: qboolean; forward;

function VerifyDriver: qboolean;
var
  buffer: PChar;
begin
  //strcpy( buffer, PChar(qglGetString(GL_RENDERER)) );
  //strlwr( buffer );
  //if ( strcmp( buffer, 'gdi generic' ) == 0 ) then}

  //Y:
  buffer := PChar(qglGetString(GL_RENDERER));
  if strcmp('gdi generic', buffer) = 0 then
    if (not glw_state.mcd_accelerated) then
    begin
      Result := false;
      Exit;
    end;
  Result := true;
end; //function

{*
** VID_CreateWindow
*}
const
  WINDOW_CLASS_NAME = 'Quake 2 Delphi';
  WINDOW_NAME = 'Quake 2 Delphi';
  WINDOW_STYLE = (WS_OVERLAPPED or WS_BORDER or WS_CAPTION or WS_VISIBLE);

function VID_CreateWindow(width, height: integer; fullscreen: qboolean): qboolean;
var
  wc: WNDCLASS;
  r: TRECT;
  vid_xpos,
    vid_ypos: cvar_p;
  stylebits,
    x, y, w, h,
    exstyle: integer;
begin
  // Register the frame class
  wc.style := 0;
  wc.lpfnWndProc := {(WNDPROC)} glw_state.wndproc;
  wc.cbClsExtra := 0;
  wc.cbWndExtra := 0;
  wc.hInstance := glw_state.hInstance;
  wc.hIcon := 0;
  wc.hCursor := LoadCursor(0, IDC_ARROW);
  wc.hbrBackground := COLOR_GRAYTEXT;
  wc.lpszMenuName := nil;
  wc.lpszClassName := WINDOW_CLASS_NAME;

  if (RegisterClass(wc) = 0) then
    ri.Sys_Error(ERR_FATAL, 'Couldn''t register window class');

  if (fullscreen) then
  begin
    exstyle := WS_EX_TOPMOST;
    stylebits := WS_POPUP or WS_VISIBLE;
  end
  else
  begin
    exstyle := 0;
    stylebits := WINDOW_STYLE;
  end;

  r.left := 0;
  r.top := 0;
  r.right := width;
  r.bottom := height;

  AdjustWindowRect(r, stylebits, FALSE);

  w := r.right - r.left;
  h := r.bottom - r.top;

  if (fullscreen) then
  begin
    x := 0;
    y := 0;
  end
  else
  begin
    vid_xpos := ri.Cvar_Get('vid_xpos', '0', 0);
    vid_ypos := ri.Cvar_Get('vid_ypos', '0', 0);
    x := Trunc(vid_xpos.value);
    y := Trunc(vid_ypos.value);
  end;

  glw_state.Wnd := CreateWindowEx(exstyle,
    WINDOW_CLASS_NAME,
    WINDOW_NAME,
    stylebits,
    x, y, w, h,
    0,
    0,
    glw_state.hInstance,
    nil);

  if (glw_state.Wnd = 0) then
    ri.Sys_Error(ERR_FATAL, 'Couldn''t create window');

  ShowWindow(glw_state.Wnd, SW_SHOW);
  UpdateWindow(glw_state.Wnd);

  // init all the gl stuff for the window
  if (not GLimp_InitGL()) then
  begin
    ri.Con_Printf(PRINT_ALL, 'VID_CreateWindow() - GLimp_InitGL failed'#10);
    Result := false;
    Exit;
  end;

  SetForegroundWindow(glw_state.Wnd);
  SetFocus(glw_state.Wnd);

  // let the sound and input subsystems know about the new window
  ri.Vid_NewWindow(width, height);

  Result := true;
end;

{*
** GLimp_SetMode
*}

function GLimp_SetMode(var pwidth, pheight: integer;
  mode: integer; fullscreen: qboolean): rserr_t;
var
  width, height,
    bitspixel_: integer;
  dm: DEVMODE;
  dc: HDC;
const
  win_fs: array[{0..1} boolean] of PChar = ('W', 'FS');
begin
  ri.Con_Printf(PRINT_ALL, 'Initializing OpenGL display'#10);

  ri.Con_Printf(PRINT_ALL, '...setting mode %d:', [mode]);

  if (not ri.Vid_GetModeInfo(@width, @height, mode)) then
  begin
    ri.Con_Printf(PRINT_ALL, ' invalid mode'#10);
    Result := rserr_invalid_mode;
    Exit;
  end;

  ri.Con_Printf(PRINT_ALL, '%d %d %s'#10, width, height, win_fs[fullscreen]);

  // destroy the existing window
  if (glw_state.Wnd <> 0) then
    GLimp_Shutdown();

  // do a CDS if needed
  if (fullscreen) then
  begin
    ri.Con_Printf(PRINT_ALL, '...attempting fullscreen'#10);

    memset(@dm, 0, sizeof(dm));

    dm.dmSize := sizeof(dm);

    dm.dmPelsWidth := width;
    dm.dmPelsHeight := height;
    dm.dmFields := DM_PELSWIDTH or DM_PELSHEIGHT;

    if (gl_bitdepth.value <> 0) then
    begin
      dm.dmBitsPerPel := Trunc(gl_bitdepth.value);
      dm.dmFields := dm.dmFields or DM_BITSPERPEL;
      ri.Con_Printf(PRINT_ALL, '...using gl_bitdepth of %d'#10, Trunc(gl_bitdepth.value));
    end
    else
    begin
      dc := GetDC(0);
      bitspixel_ := GetDeviceCaps(dc, BITSPIXEL);

      ri.Con_Printf(PRINT_ALL, '...using desktop display depth of %d'#10, bitspixel_);

      ReleaseDC(0, dc);
    end;

    ri.Con_Printf(PRINT_ALL, '...calling CDS: ');
    if (ChangeDisplaySettings(dm, CDS_FULLSCREEN) = DISP_CHANGE_SUCCESSFUL) then
    begin
      pwidth := width;
      pheight := height;

      gl_state.fullscreen := true;

      ri.Con_Printf(PRINT_ALL, 'ok'#10);

      if (not VID_CreateWindow(width, height, true)) then
      begin
        Result := rserr_invalid_mode;
        Exit;
      end;

      Result := rserr_ok;
      Exit;
    end
    else
    begin
      pwidth := width;
      pheight := height;

      ri.Con_Printf(PRINT_ALL, 'failed'#10);

      ri.Con_Printf(PRINT_ALL, '...calling CDS assuming dual monitors:');

      dm.dmPelsWidth := width * 2;
      dm.dmPelsHeight := height;
      dm.dmFields := DM_PELSWIDTH or DM_PELSHEIGHT;

      if (gl_bitdepth.value <> 0) then
      begin
        dm.dmBitsPerPel := Trunc(gl_bitdepth.value);
        dm.dmFields := dm.dmFields or DM_BITSPERPEL;
      end;
      {*
      ** our first CDS failed, so maybe we're running on some weird dual monitor
      ** system
      *}
      if (ChangeDisplaySettings({&} dm, CDS_FULLSCREEN) <> DISP_CHANGE_SUCCESSFUL) then
      begin
        ri.Con_Printf(PRINT_ALL, ' failed'#10);

        ri.Con_Printf(PRINT_ALL, '...setting windowed mode'#10);

//Y        ChangeDisplaySettings (0, 0);
        ChangeDisplaySettings(devmode(nil^), 0);

        pwidth := width;
        pheight := height;
        gl_state.fullscreen := false;
        if (not VID_CreateWindow(width, height, false)) then
        begin
          Result := rserr_invalid_mode;
          Exit;
        end;
        Result := rserr_invalid_fullscreen;
        Exit;
      end
      else
      begin
        ri.Con_Printf(PRINT_ALL, ' ok'#10);
        if (not VID_CreateWindow(width, height, true)) then
        begin
          Result := rserr_invalid_mode;
          Exit;
        end;

        gl_state.fullscreen := true;
        Result := rserr_ok;
        Exit;
      end;
    end;
  end
  else
  begin
    ri.Con_Printf(PRINT_ALL, '...setting windowed mode'#10);

//Y:    ChangeDisplaySettings (0, 0);
    ChangeDisplaySettings(devmode(nil^), 0);

    pwidth := width;
    pheight := height;
    gl_state.fullscreen := false;
    if (not VID_CreateWindow(width, height, false)) then
    begin
      Result := rserr_invalid_mode;
      Exit;
    end;
  end;

  Result := rserr_ok;
end;

{*
** GLimp_Shutdown
**
** This routine does all OS specific shutdown procedures for the OpenGL
** subsystem.  Under OpenGL this means NULLing out the current DC and
** HGLRC, deleting the rendering context, and releasing the DC acquired
** for the window.  The state structure is also nulled out.
**
*}

procedure GLimp_Shutdown;
begin
  if (Assigned(qwglMakeCurrent) and (not qwglMakeCurrent(0, 0))) then
    ri.Con_Printf(PRINT_ALL, 'ref_gl::R_Shutdown() - wglMakeCurrent failed'#10);
  if (glw_state. {h} GLRC <> 0) then
  begin
    if (Assigned(qwglDeleteContext) and (not qwglDeleteContext(glw_state. {h} GLRC))) then
      ri.Con_Printf(PRINT_ALL, 'ref_gl::R_Shutdown() - wglDeleteContext failed'#10);
    glw_state. {h} GLRC := 0;
  end;
  if (glw_state. {h} DC <> 0) then
  begin
    if (ReleaseDC(glw_state. {h} Wnd, glw_state. {h} DC) = 0) then
      ri.Con_Printf(PRINT_ALL, 'ref_gl::R_Shutdown() - ReleaseDC failed'#10, []); //Y:
    glw_state. {h} DC := 0;
  end;
  if (glw_state. {h} Wnd <> 0) then
  begin
    DestroyWindow(glw_state. {h} Wnd);
    glw_state. {h} Wnd := 0;
  end;

{  if ( glw_state.log_fp ) then
  begin
    fclose( glw_state.log_fp );
    glw_state.log_fp := 0;
  end;}
  if (TTextRec(glw_state.log_fp).Mode <> fmClosed) and
    (TTextRec(glw_state.log_fp).Name <> '') then
    CloseFile(glw_state.log_fp);

  UnregisterClass(WINDOW_CLASS_NAME, glw_state.hInstance);

  if (gl_state.fullscreen) then
  begin
//Y:    ChangeDisplaySettings (0, 0);
    ChangeDisplaySettings(devmode(nil^), 0);
    gl_state.fullscreen := false;
  end;
end; //procedure

{*
** GLimp_Init
**
** This routine is responsible for initializing the OS specific portions
** of OpenGL.  Under Win32 this means dealing with the pixelformats and
** doing the wgl interface stuff.
*}
//function GLimp_Init (void *hinstance, void *wndproc) : qboolean;

function GLimp_Init(hinstance: HINST; wndproc: pointer): qboolean; //add info: glw_win.inc: glwstate_t
const
  OSR2_BUILD_NUMBER = 1111;
var
  vinfo: OSVERSIONINFO;
begin
  vinfo.dwOSVersionInfoSize := sizeof(vinfo);

  glw_state.allowdisplaydepthchange := false;

  if (GetVersionEx({&} vinfo)) then
  begin
    if (vinfo.dwMajorVersion > 4) then
      glw_state.allowdisplaydepthchange := true
    else
      if (vinfo.dwMajorVersion = 4) then
        if (vinfo.dwPlatformId = VER_PLATFORM_WIN32_NT) then
          glw_state.allowdisplaydepthchange := true
        else
          if (vinfo.dwPlatformId = VER_PLATFORM_WIN32_WINDOWS) then
            if (LOWORD(vinfo.dwBuildNumber) >= OSR2_BUILD_NUMBER) then
              glw_state.allowdisplaydepthchange := true;
  end
  else
  begin
    ri.Con_Printf(PRINT_ALL, 'GLimp_Init() - GetVersionEx failed'#10, []); //Y:
    Result := false;
    Exit;
  end;

  glw_state.hInstance := {( HINSTANCE )} hinstance;
  glw_state.wndproc := wndproc;

  Result := true;
end; //function

function GLimp_InitGL: qboolean; //only imp
var
  pfd: TPIXELFORMATDESCRIPTOR;
(*    PIXELFORMATDESCRIPTOR pfd =
 {
  sizeof(PIXELFORMATDESCRIPTOR),   // size of this pfd
  1,                        // version number
  PFD_DRAW_TO_WINDOW |         // support window
  PFD_SUPPORT_OPENGL |         // support OpenGL
  PFD_DOUBLEBUFFER,            // double buffered
  PFD_TYPE_RGBA,               // RGBA type
  24,                        // 24-bit color depth
  0, 0, 0, 0, 0, 0,            // color bits ignored
  0,                        // no alpha buffer
  0,                        // shift bit ignored
  0,                        // no accumulation buffer
  0, 0, 0, 0,                // accum bits ignored
  32,                        // 32-bit z-buffer
  0,                        // no stencil buffer
  0,                        // no auxiliary buffer
  PFD_MAIN_PLANE,               // main layer
  0,                        // reserved
  0, 0, 0                     // layer masks ignored
    };*)
  pixelformat: integer;
  stereo: cvar_p;
label
  fail;
begin
  with pfd do
  begin
    nSize := sizeof(PIXELFORMATDESCRIPTOR); // size of this pfd
    nVersion := 1; // version number
    dwFlags := PFD_DRAW_TO_WINDOW or // support window
      PFD_SUPPORT_OPENGL or // support OpenGL
      PFD_DOUBLEBUFFER; // double buffered
    iPixelType := PFD_TYPE_RGBA; // RGBA type
    cColorBits := 24; // 24-bit color depth

    cRedBits := 0; // color bits ignored
    cRedShift := 0;
    cGreenBits := 0;
    cGreenShift := 0;
    cBlueBits := 0;
    cBlueShift := 0;

    cAlphaBits := 0; // no alpha buffer
    cAlphaShift := 0; // shift bit ignored

    cAccumBits := 0; // no accumulation buffer
    cAccumRedBits := 0; // accum bits ignored
    cAccumGreenBits := 0;
    cAccumBlueBits := 0;
    cAccumAlphaBits := 0;

    cDepthBits := 32; // 32-bit z-buffer
    cStencilBits := 0; // no stencil buffer
    cAuxBuffers := 0; // no auxiliary buffer
    iLayerType := PFD_MAIN_PLANE; // main layer

    bReserved := 0; // reserved

    dwLayerMask := 0; // layer masks ignored
    dwVisibleMask := 0;
    dwDamageMask := 0;
  end;

  stereo := ri.Cvar_Get('cl_stereo', '0', 0);

  {*
  ** set PFD_STEREO if necessary
  *}
  if (stereo.value <> 0) then
  begin
    ri.Con_Printf(PRINT_ALL, '...attempting to use stereo'#10);
    pfd.dwFlags := pfd.dwFlags or PFD_STEREO;
    gl_state.stereo_enabled := true;
  end
  else
    gl_state.stereo_enabled := false;

  {*
  ** figure out if we're running on a minidriver or not
  *}
  if (strstr(gl_driver.string_, 'opengl32') <> nil) then
    glw_state.minidriver := false
  else
    glw_state.minidriver := true;

  {*
  ** Get a DC for the specified window
  *}
  if (glw_state. {h} DC <> 0) then
    ri.Con_Printf(PRINT_ALL, 'GLimp_Init() - non-NULL DC exists'#10);

//  if ( ( glw_state.hDC = GetDC( glw_state.hWnd ) ) == NULL ) then
  glw_state. {h} DC := GetDC(glw_state. {h} Wnd);
  if (glw_state. {h} DC = 0) then
  begin
    ri.Con_Printf(PRINT_ALL, 'GLimp_Init() - GetDC failed'#10, []); //Y:
    Result := false;
    Exit;
  end;

  if (glw_state.minidriver) then
  begin
    pixelformat := qwglChoosePixelFormat(glw_state. {h} DC, {&}@pfd);
    if (pixelformat = 0) then
    begin
      ri.Con_Printf(PRINT_ALL, 'GLimp_Init() - qwglChoosePixelFormat failed'#10, []); //Y:
      Result := false;
      Exit;
    end;
    if (qwglSetPixelFormat(glw_state. {h} DC, pixelformat, {&}@pfd) = FALSE) then
    begin
      ri.Con_Printf(PRINT_ALL, 'GLimp_Init() - qwglSetPixelFormat failed'#10, []); //Y
      Result := false;
      Exit;
    end;
    qwglDescribePixelFormat(glw_state. {h} DC, pixelformat, sizeof(pfd), {&} pfd);
  end
  else
  begin
    pixelformat := ChoosePixelFormat(glw_state. {h} DC, {&}@pfd);
    if (pixelformat = 0) then
    begin
      ri.Con_Printf(PRINT_ALL, 'GLimp_Init() - ChoosePixelFormat failed'#10, []); //Y:
      Result := false;
      Exit;
    end;
    if (SetPixelFormat(glw_state. {h} DC, pixelformat, {&}@pfd) = FALSE) then
    begin
      ri.Con_Printf(PRINT_ALL, 'GLimp_Init() - SetPixelFormat failed'#10, []); //Y:
      Result := false;
      Exit;
    end;
    DescribePixelFormat(glw_state. {h} DC, pixelformat, sizeof(pfd), {&} pfd);

    if ((pfd.dwFlags and PFD_GENERIC_ACCELERATED) = 0) then
    begin
      if (gl_allow_software.value <> 0) then
        glw_state.mcd_accelerated := true
      else
        glw_state.mcd_accelerated := false;
      glw_state.mcd_accelerated := (gl_allow_software.value <> 0);
    end
    else
      glw_state.mcd_accelerated := true;
  end;

  {*
  ** report if stereo is desired but unavailable
  *}
  if ((pfd.dwFlags and PFD_STEREO) = 0) and (stereo.value <> 0) then
  begin
    ri.Con_Printf(PRINT_ALL, '...failed to select stereo pixel format'#10, []); //Y:
    ri.Cvar_SetValue('cl_stereo', 0);
    gl_state.stereo_enabled := false;
  end;

  {*
  ** startup the OpenGL subsystem by creating a context and making
  ** it current
  *}
  glw_state. {h} GLRC := qwglCreateContext(glw_state. {h} DC);
  if (glw_state. {h} GLRC = 0) then
  begin
    ri.Con_Printf(PRINT_ALL, 'GLimp_Init() - qwglCreateContext failed'#10, []); //Y:
    goto fail;
  end;

  if not qwglMakeCurrent(glw_state. {h} DC, glw_state. {h} GLRC) then
  begin
    ri.Con_Printf(PRINT_ALL, 'GLimp_Init() - qwglMakeCurrent failed'#10, []); //Y:
    goto fail;
  end;

  if not VerifyDriver() then
  begin
    ri.Con_Printf(PRINT_ALL, 'GLimp_Init() - no hardware acceleration detected'#10, []); //Y:
    goto fail;
  end;

  {*
  ** print out PFD specifics
  *}
  ri.Con_Printf(PRINT_ALL, 'GL PFD: color(%d-bits) Z(%d-bit)'#10, Trunc(pfd.cColorBits), Trunc(pfd.cDepthBits)); //Y:

  Result := true;
  Exit;

  fail:
  if (glw_state. {h} GLRC <> 0) then
  begin
    qwglDeleteContext(glw_state. {h} GLRC);
    glw_state. {h} GLRC := 0;
  end;

  if (glw_state. {h} DC <> 0) then
  begin
    ReleaseDC(glw_state. {h} Wnd, glw_state. {h} DC);
    glw_state. {h} DC := 0;
  end;
  Result := false;
end;

{*
** GLimp_BeginFrame
*}

procedure GLimp_BeginFrame(camera_separation: Single);
begin
  if (gl_bitdepth.modified) then
  begin
    if (gl_bitdepth.value <> 0) and (not glw_state.allowdisplaydepthchange) then
    begin
      ri.Cvar_SetValue('gl_bitdepth', 0);
      ri.Con_Printf(PRINT_ALL, 'gl_bitdepth requires Win95 OSR2.x or WinNT 4.x'#10, []); //Y:
    end;
    gl_bitdepth.modified := false;
  end;

  if (camera_separation < 0) and (gl_state.stereo_enabled) then
    qglDrawBuffer(GL_BACK_LEFT)
  else
    if (camera_separation > 0) and (gl_state.stereo_enabled) then
      qglDrawBuffer(GL_BACK_RIGHT)
    else
      qglDrawBuffer(GL_BACK);
end;

{*
** GLimp_EndFrame
**
** Responsible for doing a swapbuffers and possibly for other stuff
** as yet to be determined.  Probably better not to make this a GLimp
** function and instead do a call to GLimp_SwapBuffers.
*}

procedure GLimp_EndFrame; cdecl;
var
  err: integer;
begin
  err := qglGetError();
  assert(err = GL_NO_ERROR);

  if (strcmp(gl_drawbuffer^.string_, 'GL_BACK') = 0) then
    if not qwglSwapBuffers(glw_state. {h} DC) then
      ri.Sys_Error(ERR_FATAL, 'GLimp_EndFrame() - SwapBuffers() failed!'#10, []);
end;

{*
** GLimp_AppActivate
*}

procedure GLimp_AppActivate(active: qboolean);
begin
  if (active) then
  begin
    SetForegroundWindow(glw_state. {h} Wnd);
    ShowWindow(glw_state. {h} Wnd, SW_RESTORE);
  end
  else
    if (vid_fullscreen^.value <> 0) then
      ShowWindow(glw_state. {h} Wnd, SW_MINIMIZE);
end;

end.

My current problems:
- - - - - - - - - - - - - - - - - - - -
1)C - code:
if (strstr(gl_driver.string, 'opengl32')! = 0)
PAS:
if Pos('opengl32', gl_driver.string) > 0 then
