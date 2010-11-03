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
{ File(s): rw_Imp.h                                                          }
{                                                                            }
{ Initial conversion by : Avatar.dx(Avatar.dx@libertysurf.fr)                }
{ Initial conversion on : 23-Jan-2002                                        }
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
{ Updated on : 9-August-2002                                                 }
{ Updated by : CodeFusion(Michael@Skovslund.dk)                              }
{                                                                            }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{ ?                                                                          }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{ ?                                                                          }
{----------------------------------------------------------------------------}

(*
**
** RW_IMP.C
**
** This file contains ALL Win32 specific stuff having to do with the
** software refresh.  When a port is being made the following functions
** must be implemented by the port:
**
** SWimp_EndFrame
** SWimp_Init
** SWimp_SetPalette
** SWimp_Shutdown
*)

unit rw_Imp;

interface

uses
  Windows,
  q_shared,
  rw_Win,
  SysUtils,
  r_Local;

procedure VID_CreateWindow(Width, Height, StyleBits : Integer); cdecl;
function SWimp_Init( hInstance : Pointer; wndProc : Pointer ) : QBoolean; cdecl;
function SWimp_InitGraphics(FullScreen : Boolean) : QBoolean; cdecl;
procedure SWimp_EndFrame; cdecl;
function SWimp_SetMode(pWidth,pHeight : PInteger; Mode : Integer; FullScreen : QBoolean): rserr_t; cdecl;
procedure SWimp_SetPalette(Palette : PByteArray); cdecl;
procedure SWimp_ShutDown; cdecl;
procedure SWimp_AppActivate(Active : qBoolean); cdecl;
procedure Sys_MakeCodeWriteable(StartAddr, Length : Double); cdecl;

// Console variables that we need to access from this module
// CodeFusion: Removed as it is defined in rw_win.
//var
//  sww_state  : swwstate_t;

const
  WINDOW_CLASS_NAME = 'Quake2';
  WINDOW_STYLE =   (WS_OVERLAPPED or WS_BORDER or WS_CAPTION or WS_VISIBLE);

implementation

uses
  rw_dib,
  rw_ddraw,
  Directdraw,
  r_main;

(*
** VID_CreateWindow
*)

procedure VID_CreateWindow(Width, Height, StyleBits : Integer);
var
  wc : WNDCLASS;
  r  : TRect;
  x,y,w,h : Integer;
  exStyle : Integer;
  vid_xPos, vid_yPos , vid_FullScreen : cvar_p;

Begin
  vid_xPos       := ri.Cvar_Get('Vid_xPos', '0', 0);
  vid_yPos       := ri.Cvar_Get('Vid_yPos', '0', 0);
  vid_FullScreen := ri.Cvar_Get('Vid_Fullscreen','0', CVAR_ARCHIVE);

  if (vid_FullScreen.Value <> 0) then
    exstyle := WS_EX_TOPMOST
  else
    exstyle := 0;

  (* Register the frame class *)

  wc.Style         := 0;
  wc.lpfnWndProc   := sww_state.wndProc;
  wc.cbClsExtra    := 0;
  wc.cbWndExtra    := 0;
  wc.HInstance     := sww_state.h_Inst;
  wc.hIcon         := 0;
  wc.hCursor       := LoadCursor(0,IDC_ARROW);
  wc.hbrBackground := Windows.COLOR_GRAYTEXT;
  wc.lpszMenuName  := NIL;
  wc.lpszClassName := WINDOW_CLASS_NAME;

  if RegisterClass(wc) = 0 then
    ri.Sys_Error(ERR_FATAL, 'Couldn''t register window class');

  r.Left   :=0;
  r.Top    := 0;
  r.Right  := Width;
  r.Bottom := Height;

  AdjustWindowRect(r, stylebits, FALSE);

  w := r.right - r.left;
  h := r.bottom - r.top;
  x := Round(vid_xpos.value);
  y := Round(vid_ypos.value);

  sww_state.h_Wnd := CreateWindowEx(exStyle,
                                    WINDOW_CLASS_NAME,
                                    'Quake2',
                                    stylebits,
                                    x,y,w,h,
                                    0,
                                    0,
                                    sww_state.h_Inst,
                                    nil);

  if sww_state.h_Wnd = 0 then
    ri.Sys_Error(ERR_FATAL, 'Couldn''t create device window');

  ShowWindow(sww_state.h_Wnd, SW_SHOWNORMAL);
  UpdateWindow(sww_state.h_Wnd);
  SetForegroundWindow(sww_state.h_Wnd);
  SetFocus(sww_state.h_Wnd);

  // let the sound and input subsystems know about the new window
  ri.Vid_NewWindow(width, height);
end;

(*
** SWimp_Init
**
** This routine is responsible for initializing the implementation
** specific stuff in a software rendering subsystem.
*)

function SWimp_Init( hInstance : Pointer; wndProc : Pointer ) : QBoolean;
Begin
  sww_state.h_Inst := Cardinal(hInstance);
  sww_state.wndproc := wndProc;
  Result := True;
end;

(*
** SWimp_InitGraphics
**
** This initializes the software refresh's implementation specific
** graphics subsystem.  In the case of Windows it creates DIB or
** DDRAW surfaces.
**
** The necessary width and height parameters are grabbed from
** vid.width and vid.height.
*)

function SWimp_InitGraphics(FullScreen : Boolean) : QBoolean;
Begin
  // free resources in use
  SWimp_ShutDown;

  // create a new window
  VID_CreateWindow(vid.width, vid.height,WINDOW_STYLE);

  // initialize the appropriate subsystem
  if not Fullscreen then
  Begin
    if not Dib_Init(@vid.Buffer, @vid.rowBytes) then
    Begin
      vid.Buffer := nil;
      vid.RowBytes := 0;
      Result := False;
      Exit;
    end;
  end
  else
  Begin
    if not DDraw_Init(@vid.Buffer, @vid.RowBytes) then
    Begin
      vid.Buffer := nil;
      vid.RowBytes := 0;
      Result := False;
      Exit;
    end;
  end;
  Result := true;
end;

(*
** SWimp_EndFrame
**
** This does an implementation specific copy from the backbuffer to the
** front buffer.  In the Win32 case it uses BitBlt or BltFast depending
** on whether we're using DIB sections/GDI or DDRAW.
*)

procedure SWimp_EndFrame; cdecl;
var
{$IFDEF DIRECTX_WINDOWMODE}
  RS   : TRect;
  p    : TPoint;
{$ENDIF}
  r    : TRect;
  rVal : HResult;
  ddsd : TDDsurfaceDesc;

Begin
  if not sw_state.FullScreen then
  Begin
    if sww_state.palettized then
    Begin
//    holdpal = SelectPalette(hdcScreen, hpalDIB, FALSE);
//    RealizePalette(hdcScreen);
    end;

    BitBlt(sww_state.h_DC, 0, 0,
           vid.Width, vid.Height,
           sww_state.hdcDIBSection,
           0, 0,
           SRCCOPY);

    if  sww_state.palettized then
    Begin
//    SelectPalette(hdcScreen, holdpal, FALSE);
    end;
  end
  else
  Begin

    r.Left   := 0;
    r.Top    := 0;
    r.Right  := vid.Width;
    r.Bottom := vid.Height;
    sww_state.lpddsOffScreenBuffer.Unlock(vid.buffer);
//    sww_state.lpddsOffScreenBuffer.lpVtbl.Unlock( sww_state.lpddsOffScreenBuffer, vid.buffer);

{$IFDEF DIRECTX_WINDOWMODE}
    p.x := 0;
    p.y := 0;
    ClientToScreen(sww_state.h_Wnd, p);
    GetClientRect(sww_state.h_Wnd, R);
    OffsetRect(R, p.x, p.y);
    SetRect(RS, 0, 0, vid.width, vid.height);
    rval := sww_state.lpddsFrontBuffer.Blt(@R, sww_state.lpddsOffScreenBuffer, @RS, DDBLT_WAIT, nil);
    if rval = DDERR_SURFACELOST then
    begin
      sww_state.lpddsFrontBuffer._Restore;
      sww_state.lpddsFrontBuffer.Blt(@R, sww_state.lpddsOffScreenBuffer, @RS, DDBLT_WAIT, nil);
    end;

{$ELSE}
    if sww_State.Modex then
    Begin
      Rval := sww_state.lpddsBackBuffer.BltFast(0, 0,
                                                      sww_state.lpddsOffScreenBuffer,
                                                      @r,DDBLTFAST_WAIT);
      if RVal = DDERR_SURFACELOST then
      Begin
        sww_state.lpddsBackBuffer._Restore;
        sww_state.lpddsBackBuffer.BltFast(0, 0, sww_state.lpddsOffScreenBuffer,
                                               @r, DDBLTFAST_WAIT );
      end;
      Rval := sww_state.lpddsFrontBuffer.Flip(Nil, DDFLIP_WAIT);
      if Rval = DDERR_SURFACELOST then
      Begin
        sww_state.lpddsFrontBuffer._Restore;
        sww_state.lpddsFrontBuffer.Flip(Nil, DDFLIP_WAIT);
      end;
    end
    Else
    Begin
      rval := sww_state.lpddsBackBuffer.BltFast(0, 0, sww_state.lpddsOffScreenBuffer,
                                                @r,DDBLTFAST_WAIT);
      if rval = DDERR_SURFACELOST then
      Begin
        sww_state.lpddsBackBuffer._Restore;
        sww_state.lpddsBackBuffer.BltFast(0, 0, sww_state.lpddsOffScreenBuffer,
                                          @r, DDBLTFAST_WAIT);
      end;
    end;
{$ENDIF}

    FillChar(ddsd,SizeOf(ddsd),0);
    ddsd.dwSize := sizeOf(ddsd);

    sww_state.lpddsOffScreenBuffer.Lock(nil, ddsd, DDLOCK_WAIT, 0);

    vid.Buffer   := ddsd.lpSurface;
    vid.RowBytes := ddsd.lPitch;
  end;
end;

(*
** SWimp_SetMode
*)

function SWimp_SetMode(pWidth,pHeight : PInteger; Mode : Integer; FullScreen : QBoolean): rserr_t;
const
  win_fs : array[0..1] of Pchar = ('W','FS');
var
  retVal : rserr_t;
Begin
  retval := rserr_ok;
  ri.Con_Printf(PRINT_ALL, PChar('setting mode '+IntToStr(mode)+':'));
  if not Ri.Vid_GetModeInfo(pwidth, pheight, mode) then
  Begin
    ri.Con_Printf(PRINT_ALL, ' invalid mode'+#13#10);
    Result := rserr_invalid_mode;
    Exit;
  end;

  ri.Con_Printf(PRINT_ALL, PChar(' '+IntToStr(pwidth^)+' '+IntToStr(pheight^)+' '+win_fs[Integer(fullscreen) and 1]+#13#10));
  sww_state.Initializing := true;
  if FullScreen  then
  Begin
    if not SWimp_InitGraphics(True) then
    Begin
      if SWimp_InitGraphics(False)  then
      Begin
        // mode is legal but not as fullscreen
        fullscreen := False;
        retval := rserr_invalid_fullscreen;
      end
      else
      Begin
        // failed to set a valid mode in windowed mode
          retval := rserr_unknown;
      end;
    end;
  end
  else
  Begin
    // failure to set a valid mode in windowed mode
    if not SWimp_InitGraphics(fullscreen) then
    Begin
      sww_state.initializing := true;
      result := rserr_unknown;
      exit;
    end;
  end;
  sw_state.fullscreen := fullscreen;

  R_GammaCorrectAndSetPalette(PByte(@d_8to24table));
  sww_state.initializing := true;

  Result := RetVal;

end;

(*
** SWimp_SetPalette
**
** System specific palette setting routine.  A NULL palette means
** to use the existing palette.  The palette is expected to be in
** a padded 4-byte xRGB format.
*)

procedure SWimp_SetPalette(Palette : PByteArray);
Begin
// MGL - what the fuck was kendall doing here?!
// clear screen to black and change palette
//   for (i=0 ; i<vid.height ; i++)
//      memset (vid.buffer + i*vid.rowbytes, 0, vid.width);

  if not Assigned(Palette) then
    Palette := (@sw_state.currentpalette);
  if not sw_state.FullScreen then
    DIB_SetPalette(Palette)
  else
    DDraw_SetPalette(Palette);
end;

(*
** SWimp_Shutdown
**
** System specific graphics subsystem shutdown routine.  Destroys
** DIBs or DDRAW surfaces as appropriate.
*)

procedure SWimp_ShutDown;
Begin
  ri.Con_Printf(PRINT_ALL, 'Shutting down SW imp'+#13#10);
  DIB_Shutdown;
  DDRAW_Shutdown;

  if sww_state.h_wnd <> 0 then
  Begin
    ri.Con_Printf(PRINT_ALL, '...destroying window'+#13#10);
    ShowWindow( sww_state.h_Wnd, SW_SHOWNORMAL);   // prevents leaving empty slots in the taskbar
    DestroyWindow(sww_state.h_Wnd);
    sww_state.h_Wnd := 0;
    UnregisterClass(WINDOW_CLASS_NAME, sww_state.h_Inst);
  end;
end;

(*
** SWimp_AppActivate
*)

procedure SWimp_AppActivate(Active : qBoolean);
Begin
  if Active then
  begin
    if sww_state.h_wnd <> 0 then
    begin
      SetForegroundWindow(sww_state.h_Wnd);
      ShowWindow(sww_state.h_Wnd, SW_RESTORE);
    end;
  end
  else
  begin
    if sww_state.h_wnd <> 0 then
    begin
      if sww_state.Initializing then
        Exit;
      if vid_fullscreen.Value <> 0 then
        ShowWindow(sww_state.h_wnd, SW_MINIMIZE);
    end;
  end;
end;

//===============================================================================


(*
================
Sys_MakeCodeWriteable
================
*)

procedure Sys_MakeCodeWriteable(StartAddr, Length : Double);
//var
//  flOldProtect : DWORD;
Begin
// This has been removed because we do not use any code that is self-
// modificating. The asm routine that do so has been changed.

//  if not(VirtualProtect(startaddr, length, PAGE_READWRITE, @flOldProtect)) then
//  ri.sys_Error(ERR_FATAL, 'Protection change failed\n');
//
end;

(*
** Sys_SetFPCW
**
** For reference:
**
** 1
** 5               0
** xxxxRRPP.xxxxxxxx
**
** PP = 00 = 24-bit single precision
** PP = 01 = reserved
** PP = 10 = 53-bit double precision
** PP = 11 = 64-bit extended precision
**
** RR = 00 = round to nearest
** RR = 01 = round down (towards -inf, floor)
** RR = 10 = round up (towards +inf, ceil)
** RR = 11 = round to zero (truncate/towards 0)
**
*)
{$IFNDEF id386}
procedure Sys_SetFPCW;
begin
end;
{$ELSE}
var
  fpu_ceil_cwfpu_chop_cw,
  fpu_full_cw,
  fpu_cw,
  fpu_pushed_cw : Cardinal;
  fpu_sp24_cw,
  fpu_sp24_ceil_cw : Cardinal;

procedure Sys_SetFPCW;
begin
  asm
  xor eax, eax
  fnstcw  word ptr fpu_cw
  mov ax, word ptr fpu_cw

  and ah, 0f0h
  or  ah, 003h          // round to nearest mode, extended precision
  mov fpu_full_cw, eax

  and ah, 0f0h
  or  ah, 00fh          // RTZ/truncate/chop mode, extended precision
  mov fpu_chop_cw, eax

  and ah, 0f0h
  or  ah, 00bh          // ceil mode, extended precision
  mov fpu_ceil_cw, eax

  and ah, 0f0h          // round to nearest, 24-bit single precision
  mov fpu_sp24_cw, eax

  and ah, 0f0h          // ceil mode, 24-bit single precision
  or  ah, 008h          //
  mov fpu_sp24_ceil_cw, eax
end;
{$ENDIF}




end.
