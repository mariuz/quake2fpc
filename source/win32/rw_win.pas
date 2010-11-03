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
{ File(s): rw_win.c                                                          }
{                                                                            }
{ Initial conversion by : Savage (Dominique@SavageSoftware.com.au)           }
{ Initial conversion on : 09-Jan-2002                                        }
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
{ * Still dependent (to compile correctly) on:                               }
{ none                                                                       }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{ none                                                                       }
{----------------------------------------------------------------------------}

unit rw_win;

interface

uses
  Windows,
  DirectDraw,
  q_shared;

type
  pswwstate_t = ^swwstate_t;
  swwstate_t = Record
    h_Inst: HINST;

    wndproc: Pointer;
    h_DC: HDC;                                // global DC we're using
    h_Wnd: HWND;                              // HWND of parent window

    hdcDIBSection: HDC;                       // DC compatible with DIB section
    hDIBSection: HBITMAP;                     // DIB section
    pDIBBase: Pointer;                        // DIB base pointer, NOT used directly for rendering

    hPal: HPALETTE;                           // palette we're using
    hpalOld: HPALETTE;                        // original system palette
    oldsyscolors: array[0..19] of TCOLORREF;  // original system colors

    hinstDDRAW: HINST;                        // library instance for DDRAW.DLL
    lpDirectDraw: IDIRECTDRAW;                // pointer to DirectDraw object

    lpddsFrontBuffer: IDIRECTDRAWSURFACE;     // video card display memory front buffer
    lpddsBackBuffer: IDIRECTDRAWSURFACE;      // system memory backbuffer
    lpddsOffScreenBuffer: IDIRECTDRAWSURFACE; // system memory backbuffer
    lpddpPalette: IDIRECTDRAWPALETTE;         // DirectDraw palette
{$IFDEF DIRECTX_WINDOWMODE}
    lpddsClipper: IDirectDrawClipper;
{$ENDIF}
    palettized: qboolean;                     // true if desktop is paletted
    modex:  qboolean;

    initializing: qboolean;
  end;

var
  sww_state  : swwstate_t;

implementation

end.

