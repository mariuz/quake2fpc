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
{ File(s): rw_dib.c - This handles DIB section management under Windows.     }
{                                                                            }
{ Initial conversion (90%) by : Savage (Dominique@SavageSoftware.com.au)     }
{ Final conversion by : Massimo (max-67@libero.it)                           }
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
{ Updated on : 07-August-2002                                                }
{ Updated by : CodeFusion(Michael@Skovslund.dk)                              }
{                                                                            }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{ 1) ?                                                                       }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{ 1) ?                                                                       }
{----------------------------------------------------------------------------}

unit rw_dib;

interface

uses
  Windows,
  SysUtils,
  r_local,
  r_main,
  rw_win;

type
  PPByte = ^PByte;

var
  d_8to24table: array[0..255] of Word;

var
  s_systemcolors_saved: Boolean; //qboolean;
  previously_selected_GDI_obj: HGDIOBJ;

type
  t_syspalindices = (
    COLOR_ACTIVEBORDER,
    COLOR_ACTIVECAPTION,
    COLOR_APPWORKSPACE,
    COLOR_BACKGROUND,
    COLOR_BTNFACE,
    COLOR_BTNSHADOW,
    COLOR_BTNTEXT,
    COLOR_CAPTIONTEXT,
    COLOR_GRAYTEXT,
    COLOR_HIGHLIGHT,
    COLOR_HIGHLIGHTTEXT,
    COLOR_INACTIVEBORDER,
    COLOR_INACTIVECAPTION,
    COLOR_MENU,
    COLOR_MENUTEXT,
    COLOR_SCROLLBAR,
    COLOR_WINDOW,
    COLOR_WINDOWFRAME,
    COLOR_WINDOWTEXT
    );

const
  NUM_SYS_COLORS = (20{SizeOf(s_syspalindices) div sizeof(integer)});
  s_syspalindices : array[0..19] of Integer= (
    Windows.COLOR_ACTIVEBORDER,
    Windows.COLOR_ACTIVECAPTION,
    Windows.COLOR_APPWORKSPACE,
    Windows.COLOR_BACKGROUND,
    Windows.COLOR_BTNFACE,
    Windows.COLOR_BTNSHADOW,
    Windows.COLOR_BTNTEXT,
    Windows.COLOR_CAPTIONTEXT,
    Windows.COLOR_GRAYTEXT,
    Windows.COLOR_HIGHLIGHT,
    Windows.COLOR_HIGHLIGHTTEXT,
    Windows.COLOR_INACTIVEBORDER,
    Windows.COLOR_INACTIVECAPTION,
    Windows.COLOR_INACTIVECAPTIONTEXT,
    Windows.COLOR_MENU,
    Windows.COLOR_MENUTEXT,
    Windows.COLOR_SCROLLBAR,
    Windows.COLOR_WINDOW,
    Windows.COLOR_WINDOWFRAME,
    Windows.COLOR_WINDOWTEXT
    );

var
  s_oldsyscolors: array[0..NUM_SYS_COLORS - 1] of integer;

type
  dibinfo = record
    header: TBITMAPINFOHEADER;
    acolors: array[0..255] of TRGBQUAD;
  end;
  dibinfo_t = dibinfo;

  identitypalette = record
    palVersion: WORD;
    palNumEntries: WORD;
    palEntries: array[0..255] of PALETTEENTRY;
  end;
  identitypalette_t = identitypalette;

var
  s_ipal: identitypalette_t;

procedure DIB_SaveSystemColors;
procedure DIB_RestoreSystemColors;

(*
** DIB code
*)
function DIB_Init(ppbuffer: PPByte; ppitch: Pinteger): Boolean; //qboolean;
procedure DIB_Shutdown;
procedure DIB_SetPalette(const palette: PByteArray);

implementation

uses
  q_shared;

(*
** DIB_Init
**
** Builds our DIB section
*)

function DIB_Init(ppbuffer: PPByte; ppitch: Pinteger): Boolean; //qboolean;
var
  dibheader: dibinfo_t;
  i: integer;
  pbmiDIB: PBITMAPINFO;
begin

  pbmiDIB := PBITMAPINFO(@dibheader);

  FillChar(dibheader, sizeof(dibheader), 0);

  (*
  ** grab a DC
  *)
  if (sww_state.h_DC = 0) then
  begin
    sww_state.h_DC := GetDC(sww_state.h_Wnd);
    if (sww_state.h_DC = 0) then
    begin
      result := false;
      Exit;
    end;
  end;

  (*
  ** figure out if we're running in an 8-bit display mode
  *)
  sww_state.palettized := false;
  if (GetDeviceCaps(sww_state.h_DC, RASTERCAPS) and RC_PALETTE) <> 0 then
  begin
  // CF: I have removed this line.
    if GetDeviceCaps(sww_state.h_DC, COLORRES) <= 8 then
    begin
      sww_state.palettized := true;

      // save system colors
      if (not s_systemcolors_saved) then
      begin
        DIB_SaveSystemColors;
        s_systemcolors_saved := true;
      end;
    end;
  end;

  (*
  ** fill in the BITMAPINFO type = record
  *)
  pbmiDIB^.bmiHeader.biSize := sizeof(BITMAPINFOHEADER);
  pbmiDIB^.bmiHeader.biWidth := vid.width;
  pbmiDIB^.bmiHeader.biHeight := vid.height;
  pbmiDIB^.bmiHeader.biPlanes := 1;
  pbmiDIB^.bmiHeader.biBitCount := 8;
  pbmiDIB^.bmiHeader.biCompression := BI_RGB;
  pbmiDIB^.bmiHeader.biSizeImage := 0;
  pbmiDIB^.bmiHeader.biXPelsPerMeter := 0;
  pbmiDIB^.bmiHeader.biYPelsPerMeter := 0;
  pbmiDIB^.bmiHeader.biClrUsed := 256;
  pbmiDIB^.bmiHeader.biClrImportant := 256;

  (*
  ** fill in the palette
  *)
  for i := 0 to 255 do
  begin
    dibheader.acolors[i].rgbRed := (d_8to24table[i] shr 0) and $FF;
    dibheader.acolors[i].rgbGreen := (d_8to24table[i] shr 8) and $FF;
    dibheader.acolors[i].rgbBlue := (d_8to24table[i] shr 16) and $FF;
  end;

  (*
  ** create the DIB section
  *)
  sww_state.hDIBSection := CreateDIBSection(sww_state.h_DC,
                                            pbmiDIB^,
                                            DIB_RGB_COLORS,
                                            sww_state.pDIBBase,
                                            0,
                                            0);

  if (sww_state.hDIBSection = 0) then
  begin
    ri.Con_Printf(PRINT_ALL, 'DIB_Init - CreateDIBSection failed ');
    DIB_Shutdown;
    result := False;
    Exit;
  end;

  if (pbmiDIB.bmiHeader.biHeight > 0) then
  begin
    // bottom up
    ppbuffer^ := PByte(Cardinal(sww_state.pDIBBase) + (vid.height - 1) * vid.Width);
    ppitch^ := -vid.width;
  end
  else
  begin
    // top down
    ppbuffer^ := @sww_state.pDIBBase;
    ppitch^ := vid.width;
  end;

  (*
  ** clear the DIB memory buffer
  *)
  FillChar(sww_state.pDIBBase^, vid.width * vid.height, $FF);
  sww_state.hdcDIBSection := CreateCompatibleDC(sww_state.h_DC);
  if (sww_state.hdcDIBSection = 0) then
  begin
    ri.Con_Printf(PRINT_ALL, 'DIB_Init - CreateCompatibleDC failed ');
    DIB_Shutdown;
    result := False;
    Exit;
  end;

  previously_selected_GDI_obj := SelectObject(sww_state.hdcDIBSection, sww_state.hDIBSection);
  if (previously_selected_GDI_obj = 0) then
  begin
    ri.Con_Printf(PRINT_ALL, 'DIB_Init - SelectObject failed ');
    DIB_Shutdown;
    result := False;
    Exit;
  end;

  result := true;
end;

(*
** DIB_SetPalette
**
** Sets the color table in our DIB section, and also sets the system palette
** into an identity mode if we're running in an 8-bit palettized display mode.
**
** The palette is expected to be 1024 bytes, in the format:
**
** R := offset 0
** G := offset 1
** B := offset 2
** A := offset 3
*)

procedure DIB_SetPalette(const palette: PByteArray);
var
  pal: pByteArray;
  pLogPal: PMaxLogPalette;
  colors: array[0..255] of TRGBQUAD;
  i: integer;
  ret: integer;
  h_DC: HDC;
  hpalOld: HPALETTE;
begin
  pal := palette;
  pLogPal := PMaxLogPalette(@s_ipal);

  h_DC := sww_state.h_DC;

  (*
  ** set the DIB color table
  *)
  if (sww_state.hdcDIBSection <> 0) then
  begin
    for i := 0 to 255 do
    begin
      colors[i].rgbRed := pal[0];
      colors[i].rgbGreen := pal[1];
      colors[i].rgbBlue := pal[2];
      colors[i].rgbReserved := 0;
      Inc(PByte(pal),4);
    end;

    colors[0].rgbRed := 0;
    colors[0].rgbGreen := 0;
    colors[0].rgbBlue := 0;

    colors[255].rgbRed := $FF;
    colors[255].rgbGreen := $FF;
    colors[255].rgbBlue := $FF;

    if (SetDIBColorTable(sww_state.hdcDIBSection, 0, 256, colors) = 0) then
    begin
      ri.Con_Printf(PRINT_ALL, 'DIB_SetPalette - SetDIBColorTable failed');
    end;
  end;

  (*
  ** for 8-bit color desktop modes we set up the palette for maximum
  ** speed by going into an identity palette mode.
  *)
  if (sww_state.palettized) then
  begin
    if (SetSystemPaletteUse(h_DC, SYSPAL_NOSTATIC) = SYSPAL_ERROR) then
    begin
      //ri.Sys_Error(ERR_FATAL, 'DIB_SetPalette - SetSystemPaletteUse failed ');
    end;

    (*
    ** destroy our old palette
    *)
    if (sww_state.hPal <> 0) then
    begin
      DeleteObject(sww_state.hPal);
      sww_state.hPal := 0;
    end;

    (*
    ** take up all physical palette entries to flush out anything that's currently
    ** in the palette
    *)
    pLogPal.palVersion := $300;
    pLogPal.palNumEntries := 256;
    i := 0;
    pal := palette;
    while (i < 256) do
    begin
      pLogPal^.palPalEntry[i].peRed := pal^[0];
      pLogPal^.palPalEntry[i].peGreen := pal^[1];
      pLogPal^.palPalEntry[i].peBlue := pal^[2];
      pLogPal^.palPalEntry[i].peFlags := PC_RESERVED or PC_NOCOLLAPSE;
      Inc(i);
      Inc(PByte(pal), 4);
    end;

    pLogPal^.palPalEntry[0].peRed := 0;
    pLogPal^.palPalEntry[0].peGreen := 0;
    pLogPal^.palPalEntry[0].peBlue := 0;
    pLogPal^.palPalEntry[0].peFlags := 0;

    pLogPal^.palPalEntry[255].peRed := $FF;
    pLogPal^.palPalEntry[255].peGreen := $FF;
    pLogPal^.palPalEntry[255].peBlue := $FF;
    pLogPal^.palPalEntry[255].peFlags := 0;

    sww_state.hPal := CreatePalette(PLOGPALETTE(pLogPal)^);
    if (sww_state.hPal = 0) then
    begin
      ri.Sys_Error(ERR_FATAL, 'DIB_SetPalette - CreatePalette failed(modx) ');
    end;

    hpalOld := SelectPalette(h_DC, sww_state.hPal, False);
    if (hpalOld = 0) then
    begin
      ri.Sys_Error(ERR_FATAL, 'DIB_SetPalette - SelectPalette failed(modx) ');
    end;

    if (sww_state.hpalOld = 0) then
      sww_state.hpalOld := hpalOld;

    ret := RealizePalette(h_DC);
    if (ret <> pLogPal.palNumEntries) then
    begin
      ri.Sys_Error(ERR_FATAL, 'DIB_SetPalette - RealizePalette set %d entries ');
    end;
  end;
end;

(*
** DIB_Shutdown
*)

procedure DIB_Shutdown;
begin
  if (sww_state.palettized and s_systemcolors_saved) then
    DIB_RestoreSystemColors;

  if (sww_state.hPal <> 0) then
  begin
    DeleteObject(sww_state.hPal);
    sww_state.hPal := 0;
  end;

  if (sww_state.hpalOld <> 0 ) then
  begin
    SelectPalette(sww_state.h_DC, sww_state.hpalOld, FALSE);
    RealizePalette(sww_state.h_DC);
    sww_state.hpalOld := 0;
  end;

  if (sww_state.hdcDIBSection <> 0) then
  begin
    SelectObject(sww_state.hdcDIBSection, previously_selected_GDI_obj);
    DeleteDC(sww_state.hdcDIBSection);
    sww_state.hdcDIBSection := 0;
  end;

  if (sww_state.hDIBSection <> 0 ) then
  begin
    DeleteObject(sww_state.hDIBSection);
    sww_state.hDIBSection := 0;
    sww_state.pDIBBase := nil;
  end;

  if (sww_state.h_DC <> 0 ) then
  begin
    ReleaseDC(sww_state.h_Wnd, sww_state.h_DC);
    sww_state.h_DC := 0;
  end;
end;

(*
** DIB_Save/RestoreSystemColors
*)

procedure DIB_RestoreSystemColors;
begin
  SetSystemPaletteUse(sww_state.h_DC, SYSPAL_STATIC);
  SetSysColors(NUM_SYS_COLORS, s_syspalindices, s_oldsyscolors);
end;

procedure DIB_SaveSystemColors;
var
  i: integer;
begin
  for i := 0 to NUM_SYS_COLORS - 1 do
    s_oldsyscolors[i] := GetSysColor(s_syspalindices[i]);
end;

end.

