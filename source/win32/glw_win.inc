

// PLEASE, don't modify this file
// 99% complete


{*
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

*}

(*
#ifndef _WIN32
#  error You should not be including this file on this platform
#endif

#ifndef __GLW_WIN_H__
#define __GLW_WIN_H__
*)

type
  glwstate_t = record
    hInstance : HINST{ANCE};
//   void   *wndproc;
    wndproc : pointer; //??? "Windows.TFNWndProc" or "TFarProc = Pointer"

    {h}DC   : HDC;       // handle to device context
    {h}Wnd  : HWND;      // handle to window
    {h}GLRC : HGLRC;     // handle to GL rendering context

    hinstOpenGL : HINST{ANCE};  // HINSTANCE for the OpenGL library

    minidriver,
    allowdisplaydepthchange,
    mcd_accelerated : boolean;

//        FILE *log_fp;
    log_fp : textfile; //or file
  end;
  
//extern glwstate_t glw_state;

//#endif

// End of file
