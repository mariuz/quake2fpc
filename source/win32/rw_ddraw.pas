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
{ File(s): rw_draw.h - This handles DirecTDraw management under Windows.     }
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

unit rw_ddraw;

interface

uses
  Windows,
  SysUtils,
  q_shared,
  r_local;

//var
//  d_8to24table: array[0..255] of Word;
type
  PPByte = ^PByte;

function DDrawError(code: integer): string;
function DDRAW_Init(ppbuffer: PPByte; ppitch: Pinteger): boolean; stdcall;
procedure DDRAW_Shutdown;
procedure DDRAW_SetPalette( palette: PByteArray);

implementation

uses
  Directdraw,
  rw_win,
  r_main,
  rw_imp;

(*
** DDRAW_Init
**
** Builds our DDRAW stuff
*)
type
//  TDirectDrawCreate = function(lpGUID: PGUID; out lplpDDRAW: IDirectDraw; pUnkOuter: IUnknown): HResult; cdecl;
//  TDirectDrawCreate = function(lpGUID: PGUID; lplpDDRAW: Pointer; pUnkOuter: IUnknown): HResult; cdecl;
  TDirectDrawCreate = function(lpGUID : PGUID; out lplpDD : IDirectDraw; pUnkOuter : IUnknown) : HResult; stdcall;

function DDRAW_Init(ppbuffer: PPByte; ppitch: PInteger): boolean; stdcall;
var
  QDirectDrawCreate : TDirectDrawCreate;
  palentries: array[0..255] of TPALETTEENTRY;
  ddrval: HRESULT;
  ddsd: TDDSURFACEDESC;
{$IFNDEF DIRECTX_WINDOWMODE}
  ddscaps: TDDSCAPS;
{$ENDIF}
  i: integer;
begin
  ri.Con_Printf(PRINT_ALL, 'Initializing DirectDraw ');
  for i := 0 to 255 do
  begin
    palentries[i].peRed := (d_8to24table[i] shr 0) and $FF;
    palentries[i].peGreen := (d_8to24table[i] shr 8) and $FF;
    palentries[i].peBlue := (d_8to24table[i] shr 16) and $FF;
  end;

  (*
  ** load DLL and fetch pointer to entry point
  *)
  if (sww_state.hinstDDRAW = 0) then
  begin
    ri.Con_Printf(PRINT_ALL, '...loading DDRAW.DLL: ');
    sww_state.hinstDDRAW := LoadLibrary('ddraw.dll');
    if (sww_state.hinstDDRAW = 0) then
    begin
      ri.Con_Printf(PRINT_ALL, 'failed ');
      DDRAW_Shutdown;
      result := False;
      Exit;
    end;
    ri.Con_Printf(PRINT_ALL, 'ok ');
  end;

  QDirectDrawCreate := GetProcAddress(sww_state.hinstDDRAW, 'DirectDrawCreate');
  if not (Assigned(QDirectDrawCreate)) then
  begin
    ri.Con_Printf(PRINT_ALL, '*** DirectDrawCreate = nil *** ');
    DDRAW_Shutdown;
    result := False;
    Exit;
  end;

  (*
  ** create the direct draw object
  *)
  ri.Con_Printf(PRINT_ALL, '...creating DirectDraw object: ');
  ddrval := QDirectDrawCreate(nil, sww_state.lpDirectDraw, nil);
  if (ddrval <> DD_OK) then
  begin
//(*H*)    ri.Con_Printf(PRINT_ALL, 'failed - %s ', DDrawError(ddrval));
    ri.Con_Printf(PRINT_ALL, 'failed - %s', DDrawError(ddrval));
    DDRAW_Shutdown;
    result := False;
    Exit;
  end;
  ri.Con_Printf(PRINT_ALL, 'ok ');

  (*
  ** see if linear modes exist first
  *)
  sww_state.modex := false;

  ri.Con_Printf(PRINT_ALL, '...setting exclusive mode: ');
{$IFDEF DIRECTX_WINDOWMODE}
  ddrval := sww_state.lpDIRECTDraw.SetCooperativeLevel(sww_state.h_Wnd, DDSCL_NORMAL);
  if (ddrval <> DD_OK) then
  begin
    ri.Con_Printf(PRINT_ALL, 'failed - %s', DDrawError(ddrval));
    DDRAW_Shutdown;
    result := False;
    Exit;
  end;
  ri.Con_Printf(PRINT_ALL, 'ok ');

  (*
  ** try changing the display mode normally
  *)
  ri.Con_Printf(PRINT_ALL, '...finding display mode ');
  ri.Con_Printf(PRINT_ALL, '...setting linear mode: ');
  ddrval := sww_state.lpDIRECTDraw.SetDisplayMode( 1024, 768, 8);
  if (ddrval = DD_OK) then
    ri.Con_Printf(PRINT_ALL, 'ok ')
  else
  begin
    ri.Con_Printf(PRINT_ALL, 'failed - %s', DDrawError(ddrval));
    DDRAW_Shutdown;
    result := False;
    Exit;
  end;

  (*
  ** create our front buffer
  *)
  FillChar(ddsd, sizeof(ddsd), 0);
  ddsd.dwSize := sizeof(ddsd);
  ddsd.dwFlags := DDSD_CAPS;
  ddsd.ddsCaps.dwCaps := DDSCAPS_PRIMARYSURFACE;
  ri.Con_Printf(PRINT_ALL, '...creating front buffer: ');
  ddrval := sww_state.lpDIRECTDraw.CreateSurface(ddsd, sww_state.lpddsFrontBuffer, nil);
  if (ddrval <> DD_OK) then
  begin
    ri.Con_Printf(PRINT_ALL, 'failed - %s', DDrawError(ddrval));
    DDRAW_Shutdown;
    result := False;
    Exit;
  end;
  ri.Con_Printf(PRINT_ALL, 'ok ');

  (*
  ** create our back buffer
  *)
  ddsd.ddsCaps.dwCaps := DDSCAPS_BACKBUFFER;
(*
  ri.Con_Printf(PRINT_ALL, '...creating back buffer: ');
  ddrval := sww_state.lpddsFrontBuffer.GetAttachedSurface(ddsd.ddsCaps, sww_state.lpddsBackBuffer);
  if (ddrval <> DD_OK) then
  begin
    ri.Con_Printf(PRINT_ALL, PChar('failed - '+DDrawError(ddrval)));
    DDRAW_Shutdown;
    result := False;
    Exit;
  end;
  ri.Con_Printf(PRINT_ALL, 'ok ');
*)
  sww_state.lpddsBackBuffer := nil;
// Create clipper
  ri.Con_Printf(PRINT_ALL, '...creating clipper: ');
  ddrval := sww_state.lpDIRECTDraw.CreateClipper(0, sww_state.lpddsClipper, nil);
  if (ddrval <> DD_OK) then
  begin
    ri.Con_Printf(PRINT_ALL, 'failed - %s', DDrawError(ddrval));
    DDRAW_Shutdown;
    result := False;
    Exit;
  end;
  ri.Con_Printf(PRINT_ALL, 'ok ');

  ri.Con_Printf(PRINT_ALL, '...Attaching clipper to window: ');
  ddrval := sww_state.lpddsClipper.SetHWnd(0, sww_state.h_Wnd);
  if (ddrval <> DD_OK) then
  begin
    ri.Con_Printf(PRINT_ALL, 'failed - %s', DDrawError(ddrval));
    DDRAW_Shutdown;
    result := False;
    Exit;
  end;
  ri.Con_Printf(PRINT_ALL, 'ok ');

  ri.Con_Printf(PRINT_ALL, '...Attaching clipper to surface: ');
  ddrval := sww_state.lpddsFrontBuffer.SetClipper(sww_state.lpddsClipper);
  if (ddrval <> DD_OK) then
  begin
    ri.Con_Printf(PRINT_ALL, 'failed - %s', DDrawError(ddrval));
    DDRAW_Shutdown;
    result := False;
    Exit;
  end;
  ri.Con_Printf(PRINT_ALL, 'ok ');

{$ELSE}

  ddrval := sww_state.lpDIRECTDraw.SetCooperativeLevel(sww_state.h_Wnd, DDSCL_EXCLUSIVE or DDSCL_FULLSCREEN);
  if (ddrval <> DD_OK) then
  begin
    ri.Con_Printf(PRINT_ALL, 'failed - %s', DDrawError(ddrval));
    DDRAW_Shutdown;
    result := False;
    Exit;
  end;
  ri.Con_Printf(PRINT_ALL, 'ok ');

  (*
  ** try changing the display mode normally
  *)
  ri.Con_Printf(PRINT_ALL, '...finding display mode ');
  ri.Con_Printf(PRINT_ALL, '...setting linear mode: ');
  ddrval := sww_state.lpDIRECTDraw.SetDisplayMode( vid.width, vid.height, 8);
  if (ddrval = DD_OK) then
    ri.Con_Printf(PRINT_ALL, 'ok ')
    (*
    ** if no linear mode found, go for modex if we're trying 32$240
    *)
  else
    if (sw_mode^.value = 0.0) and (sw_allow_modex^.value <> 0.0) then
    begin
      ri.Con_Printf(PRINT_ALL, 'failed ');
      ri.Con_Printf(PRINT_ALL, '...attempting ModeX 320x240: ');

      (*
      ** reset to normal cooperative level
      *)
      sww_state.lpDIRECTDraw.SetCooperativeLevel( sww_state.h_Wnd, DDSCL_NORMAL);

      (*
      ** set exclusive mode
      *)
      ddrval :=
        sww_state.lpDIRECTDraw.SetCooperativeLevel( sww_state.h_Wnd,
                                                    DDSCL_EXCLUSIVE or
                                                    DDSCL_FULLSCREEN or
                                                    DDSCL_NOWINDOWCHANGES or
                                                    DDSCL_ALLOWMODEX);
      if (ddrval <> DD_OK) then
      begin
    ri.Con_Printf(PRINT_ALL, 'failed - %s', DDrawError(ddrval));
        DDRAW_Shutdown;
        result := False;
        Exit;
      end;

      (*
      ** change our display mode
      *)
      ddrval := sww_state.lpDIRECTDraw.SetDisplayMode( vid.Width, vid.height, 8);
      if (ddrval <> DD_OK) then
      begin
    ri.Con_Printf(PRINT_ALL, 'failed - %s', DDrawError(ddrval));
        DDRAW_Shutdown;
        result := False;
        Exit;
      end;
      ri.Con_Printf(PRINT_ALL, 'ok ');

      sww_state.modex := true;
    end
    else
    begin
      ri.Con_Printf(PRINT_ALL, 'failed ');
      DDRAW_Shutdown;
      result := False;
      Exit;
    end;

  (*
  ** create our front buffer
  *)
  FillChar(ddsd, sizeof(ddsd), 0);
  ddsd.dwSize := sizeof(ddsd);
  ddsd.dwFlags := DDSD_CAPS or DDSD_BACKBUFFERCOUNT;
  ddsd.ddsCaps.dwCaps := DDSCAPS_PRIMARYSURFACE or DDSCAPS_FLIP or DDSCAPS_COMPLEX;
  ddsd.dwBackBufferCount := 1;

  ri.Con_Printf(PRINT_ALL, '...creating front buffer: ');
  ddrval := sww_state.lpDIRECTDraw.CreateSurface(ddsd, sww_state.lpddsFrontBuffer, nil);
  if (ddrval <> DD_OK) then
  begin
    ri.Con_Printf(PRINT_ALL, 'failed - %s', DDrawError(ddrval));
    DDRAW_Shutdown;
    result := False;
    Exit;
  end;
  ri.Con_Printf(PRINT_ALL, 'ok ');

  (*
  ** see if we're a ModeX mode
  *)
  sww_state.lpddsFrontBuffer.GetCaps(ddscaps);
  if (ddscaps.dwCaps and DDSCAPS_MODEX) = 0 then
    ri.Con_Printf(PRINT_ALL, '...using ModeX ');

  (*
  ** create our back buffer
  *)
  ddsd.ddsCaps.dwCaps := DDSCAPS_BACKBUFFER;

  ri.Con_Printf(PRINT_ALL, '...creating back buffer: ');
  ddrval := sww_state.lpddsFrontBuffer.GetAttachedSurface(ddsd.ddsCaps, sww_state.lpddsBackBuffer);
  if (ddrval <> DD_OK) then
  begin
    ri.Con_Printf(PRINT_ALL, 'failed - %s', DDrawError(ddrval));
    DDRAW_Shutdown;
    result := False;
    Exit;
  end;
  ri.Con_Printf(PRINT_ALL, 'ok ');
{$ENDIF}

  (*
  ** create our rendering buffer
  *)
  FillChar(ddsd, sizeof(ddsd), 0);
  ddsd.dwSize := sizeof(ddsd);
  ddsd.dwFlags := DDSD_WIDTH or DDSD_HEIGHT or DDSD_CAPS;
  ddsd.dwHeight := vid.height;
  ddsd.dwWidth := vid.width;
  ddsd.ddsCaps.dwCaps := DDSCAPS_OFFSCREENPLAIN or DDSCAPS_SYSTEMMEMORY;

  ri.Con_Printf(PRINT_ALL, '...creating offscreen buffer: ');
  ddrval := sww_state.lpDIRECTDraw.CreateSurface(ddsd,sww_state.lpddsOffScreenBuffer, nil);
  if (ddrval <> DD_OK) then
  begin
    ri.Con_Printf(PRINT_ALL, 'failed - %s', DDrawError(ddrval));
    DDRAW_Shutdown;
    result := False;
    Exit;
  end;
  ri.Con_Printf(PRINT_ALL, 'ok ');

  (*
  ** create our DIRECTDRAWPALETTE
  *)
  ri.Con_Printf(PRINT_ALL, '...creating palette: ');
  ddrval := sww_state.lpDIRECTDraw.CreatePalette(DDPCAPS_8BIT or DDPCAPS_ALLOW256,
                                                 @palentries, sww_state.lpddpPalette,
                                                 nil);
  if (ddrval <> DD_OK) then
  begin
    ri.Con_Printf(PRINT_ALL, 'failed - %s', DDrawError(ddrval));
    DDRAW_Shutdown;
    result := False;
    Exit;
  end;
  ri.Con_Printf(PRINT_ALL, 'ok ');

  ri.Con_Printf(PRINT_ALL, '...setting palette: ');
  ddrval := sww_state.lpddsFrontBuffer.SetPalette(sww_state.lpddpPalette);
  if (ddrval <> DD_OK) then
  begin
    ri.Con_Printf(PRINT_ALL, 'failed - %s', DDrawError(ddrval));
    DDRAW_Shutdown;
    result := False;
    Exit;
  end;
  ri.Con_Printf(PRINT_ALL, 'ok ');

  DDRAW_SetPalette(@sw_state.currentpalette);

  (*
  ** lock the back buffer
  *)
  FillChar(ddsd, sizeof(ddsd), 0);
  ddsd.dwSize := sizeof(ddsd);

  ri.Con_Printf(PRINT_ALL, '...locking backbuffer: ');
  ddrval := sww_state.lpddsOffScreenBuffer.Lock(nil, ddsd, DDLOCK_WAIT, 0);
  if (ddrval <> DD_OK) then
  begin
    ri.Con_Printf(PRINT_ALL, 'failed - %s', DDrawError(ddrval));
    DDRAW_Shutdown;
    result := False;
    Exit;
  end;
  ri.Con_Printf(PRINT_ALL, 'ok ');

  ppbuffer^ := ddsd.lpSurface;
  ppitch^ := ddsd.lPitch;

  for i := 0 to vid.height - 1 do
    FillChar(PByteArray(ppbuffer^)^[i * ppitch^], ppitch^, 0);

  sww_state.palettized := true;
  Result := true;
end;

(*
** DDRAW_SetPalette
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

procedure DDRAW_SetPalette( palette: PByteArray);
var
  palentries: array[0..255] of TPALETTEENTRY;
  i: integer;
begin

  if not (sww_state.lpddpPalette = nil) then
    exit;

  for i := 0 to 255 do
  begin
    palentries[i].peRed := palette[0];
    palentries[i].peGreen := palette[1];
    palentries[i].peBlue := palette[2];
    palentries[i].peFlags := PC_RESERVED or PC_NOCOLLAPSE;
    Inc( palette, 4 );
  end;

  if (sww_state.lpddpPalette.SetEntries(0, 0, 256, @palentries) <> DD_OK) then
    ri.Con_Printf(PRINT_ALL, 'DDRAW_SetPalette - SetEntries failed ');
end;

(*
** DDRAW_Shutdown
*)

procedure DDRAW_Shutdown;
begin
  if (sww_state.lpddsOffScreenBuffer <> nil) then
  begin
    ri.Con_Printf(PRINT_ALL, '...releasing offscreen buffer ');
    sww_state.lpddsOffScreenBuffer.Unlock(vid.buffer);
//    sww_state.lpddsOffScreenBuffer.Release(sww_state.lpddsOffScreenBuffer);
    sww_state.lpddsOffScreenBuffer := nil;
  end;

{$IFDEF DIRECTX_WINDOWMODE}
  if (sww_state.lpddsClipper <> nil) then
  begin
    ri.Con_Printf(PRINT_ALL, '...releasing clipper');
    sww_state.lpddsClipper := nil;
  end;
{$ENDIF}

  if (sww_state.lpddsBackBuffer <> nil) then
  begin
    ri.Con_Printf(PRINT_ALL, '...releasing back buffer ');
//    sww_state.lpddsBackBuffer.Release(sww_state.lpddsBackBuffer);
    sww_state.lpddsBackBuffer := nil;
  end;

  if (sww_state.lpddsFrontBuffer <> nil) then
  begin
    ri.Con_Printf(PRINT_ALL, '...releasing front buffer ');
//    sww_state.lpddsFrontBuffer.Release(sww_state.lpddsFrontBuffer);
    sww_state.lpddsFrontBuffer := nil;
  end;

  if (sww_state.lpddpPalette <> nil) then
  begin
    ri.Con_Printf(PRINT_ALL, '...releasing palette ');
//    sww_state.lpddpPalette.Release(sww_state.lpddpPalette);
    sww_state.lpddpPalette := nil;
  end;

  if (sww_state.lpDIRECTDraw <> nil) then
  begin
    ri.Con_Printf(PRINT_ALL, '...restoring display mode ');
    sww_state.lpDIRECTDraw.RestoreDisplayMode;
    ri.Con_Printf(PRINT_ALL, '...restoring normal coop mode ');
    sww_state.lpDIRECTDraw.SetCooperativeLevel( sww_state.h_Wnd, DDSCL_NORMAL);
    ri.Con_Printf(PRINT_ALL, '...releasing IDIRECTDraw ');
//    sww_state.lpDIRECTDraw.lpVtbl.Release(sww_state.IDIRECTDraw);
    sww_state.lpDIRECTDraw := nil;
  end;

  if (sww_state.hinstDDRAW <> 0 ) then
  begin
    ri.Con_Printf(PRINT_ALL, '...freeing library ');
    FreeLibrary(sww_state.hinstDDRAW);
    sww_state.hinstDDRAW := 0;
  end;
end;

function DDrawError(code: integer): string;
begin
  case (code) of
    DD_OK:
      result := 'DD_OK';
    DDERR_ALREADYINITIALIZED:
      result := 'DDERR_ALREADYINITIALIZED';
    DDERR_BLTFASTCANTCLIP:
      result := 'DDERR_BLTFASTCANTCLIP';
    DDERR_CANNOTATTACHSURFACE:
      result := 'DDER_CANNOTATTACHSURFACE';
    DDERR_CANNOTDETACHSURFACE:
      result := 'DDERR_CANNOTDETACHSURFACE';
    DDERR_CANTCREATEDC:
      result := 'DDERR_CANTCREATEDC';
    DDERR_CANTDUPLICATE:
      result := 'DDER_CANTDUPLICATE';
    DDERR_CLIPPERISUSINGHWND:
      result := 'DDER_CLIPPERUSINGHWND';
    DDERR_COLORKEYNOTSET:
      result := 'DDERR_COLORKEYNOTSET';
    DDERR_CURRENTLYNOTAVAIL:
      result := 'DDERR_CURRENTLYNOTAVAIL';
    DDERR_DIRECTDRAWALREADYCREATED:
      result := 'DDERR_DIRECTDRAWALREADYCREATED';
    DDERR_EXCEPTION:
      result := 'DDERR_EXCEPTION';
    DDERR_EXCLUSIVEMODEALREADYSET:
      result := 'DDERR_EXCLUSIVEMODEALREADYSET';
    DDERR_GENERIC:
      result := 'DDERR_GENERIC';
    DDERR_HEIGHTALIGN:
      result := 'DDERR_HEIGHTALIGN';
    DDERR_HWNDALREADYSET:
      result := 'DDERR_HWNDALREADYSET';
    DDERR_HWNDSUBCLASSED:
      result := 'DDERR_HWNDSUBCLASSED';
    DDERR_IMPLICITLYCREATED:
      result := 'DDERR_IMPLICITLYCREATED';
    DDERR_INCOMPATIBLEPRIMARY:
      result := 'DDERR_INCOMPATIBLEPRIMARY';
    DDERR_INVALIDCAPS:
      result := 'DDERR_INVALIDCAPS';
    DDERR_INVALIDCLIPLIST:
      result := 'DDERR_INVALIDCLIPLIST';
    DDERR_INVALIDDIRECTDRAWGUID:
      result := 'DDERR_INVALIDDIRECTDRAWGUID';
    DDERR_INVALIDMODE:
      result := 'DDERR_INVALIDMODE';
    DDERR_INVALIDOBJECT:
      result := 'DDERR_INVALIDOBJECT';
    DDERR_INVALIDPARAMS:
      result := 'DDERR_INVALIDPARAMS';
    DDERR_INVALIDPIXELFORMAT:
      result := 'DDERR_INVALIDPIXELFORMAT';
    DDERR_INVALIDPOSITION:
      result := 'DDERR_INVALIDPOSITION';
    DDERR_INVALIDRECT:
      result := 'DDERR_INVALIDRECT';
    DDERR_LOCKEDSURFACES:
      result := 'DDERR_LOCKEDSURFACES';
    DDERR_NO3D:
      result := 'DDERR_NO3D';
    DDERR_NOALPHAHW:
      result := 'DDERR_NOALPHAHW';
    DDERR_NOBLTHW:
      result := 'DDERR_NOBLTHW';
    DDERR_NOCLIPLIST:
      result := 'DDERR_NOCLIPLIST';
    DDERR_NOCLIPPERATTACHED:
      result := 'DDERR_NOCLIPPERATTACHED';
    DDERR_NOCOLORCONVHW:
      result := 'DDERR_NOCOLORCONVHW';
    DDERR_NOCOLORKEY:
      result := 'DDERR_NOCOLORKEY';
    DDERR_NOCOLORKEYHW:
      result := 'DDERR_NOCOLORKEYHW';
    DDERR_NOCOOPERATIVELEVELSET:
      result := 'DDERR_NOCOOPERATIVELEVELSET';
    DDERR_NODC:
      result := 'DDERR_NODC';
    DDERR_NODDROPSHW:
      result := 'DDERR_NODDROPSHW';
    DDERR_NODIRECTDRAWHW:
      result := 'DDERR_NODIRECTDRAWHW';
    DDERR_NOEMULATION:
      result := 'DDERR_NOEMULATION';
    DDERR_NOEXCLUSIVEMODE:
      result := 'DDERR_NOEXCLUSIVEMODE';
    DDERR_NOFLIPHW:
      result := 'DDERR_NOFLIPHW';
    DDERR_NOGDI:
      result := 'DDERR_NOGDI';
    DDERR_NOHWND:
      result := 'DDERR_NOHWND';
    DDERR_NOMIRRORHW:
      result := 'DDERR_NOMIRRORHW';
    DDERR_NOOVERLAYDEST:
      result := 'DDERR_NOOVERLAYDEST';
    DDERR_NOOVERLAYHW:
      result := 'DDERR_NOOVERLAYHW';
    DDERR_NOPALETTEATTACHED:
      result := 'DDERR_NOPALETTEATTACHED';
    DDERR_NOPALETTEHW:
      result := 'DDERR_NOPALETTEHW';
    DDERR_NORASTEROPHW:
      result :=
        'Operation could not be carried out because there is no appropriate raster op hardware present or available.\0';
    DDERR_NOROTATIONHW:
      result :=
        'Operation could not be carried out because there is no rotation hardware present or available.\0';
    DDERR_NOSTRETCHHW:
      result :=
        'Operation could not be carried out because there is no hardware support for stretching.\0';
    DDERR_NOT4BITCOLOR:
      result :=
        'DirectDrawSurface is not in 4 bit color palette and the requested operation requires 4 bit color palette.\0';
    DDERR_NOT4BITCOLORINDEX:
      result :=
        'DirectDrawSurface is not in 4 bit color index palette and the requested operation requires 4 bit color index palette.\0';
    DDERR_NOT8BITCOLOR:
      result := 'DDERR_NOT8BITCOLOR';
    DDERR_NOTAOVERLAYSURFACE:
      result :=
        'result :=ed when an overlay member is called for a non-overlay surface.\0';
    DDERR_NOTEXTUREHW:
      result :=
        'Operation could not be carried out because there is no texture mapping hardware present or available.\0';
    DDERR_NOTFLIPPABLE:
      result := 'DDERR_NOTFLIPPABLE';
    DDERR_NOTFOUND:
      result := 'DDERR_NOTFOUND';
    DDERR_NOTLOCKED:
      result := 'DDERR_NOTLOCKED';
    DDERR_NOTPALETTIZED:
      result := 'DDERR_NOTPALETTIZED';
    DDERR_NOVSYNCHW:
      result := 'DDERR_NOVSYNCHW';
    DDERR_NOZBUFFERHW:
      result :=
        'Operation could not be carried out because there is no hardware support for zbuffer blitting.\0';
    DDERR_NOZOVERLAYHW:
      result :=
        'Overlay surfaces could not be z layered based on their BltOrder because the hardware does not support z layering of overlays.\0';
    DDERR_OUTOFCAPS:
      result :=
        'The hardware needed for the requested operation has already been allocated.\0';
    DDERR_OUTOFMEMORY:
      result := 'DDERR_OUTOFMEMORY';
    DDERR_OUTOFVIDEOMEMORY:
      result := 'DDERR_OUTOFVIDEOMEMORY';
    DDERR_OVERLAYCANTCLIP:
      result := 'The hardware does not support clipped overlays.\0';
    DDERR_OVERLAYCOLORKEYONLYONEACTIVE:
      result :=
        'Can only have ony color key active at one time for overlays.\0';
    DDERR_OVERLAYNOTVISIBLE:
      result :=
        'result :=ed when GetOverlayPosition is called on a hidden overlay.\0';
    DDERR_PALETTEBUSY:
      result := 'DDERR_PALETTEBUSY';
    DDERR_PRIMARYSURFACEALREADYEXISTS:
      result := 'DDERR_PRIMARYSURFACEALREADYEXISTS';
    DDERR_REGIONTOOSMALL:
      result := 'Region passed to Clipper.GetClipList is too small.\0';
    DDERR_SURFACEALREADYATTACHED:
      result := 'DDERR_SURFACEALREADYATTACHED';
    DDERR_SURFACEALREADYDEPENDENT:
      result := 'DDERR_SURFACEALREADYDEPENDENT';
    DDERR_SURFACEBUSY:
      result := 'DDERR_SURFACEBUSY';
    DDERR_SURFACEISOBSCURED:
      result := 'Access to surface refused because the surface is obscured.\0';
    DDERR_SURFACELOST:
      result := 'DDERR_SURFACELOST';
    DDERR_SURFACENOTATTACHED:
      result := 'DDERR_SURFACENOTATTACHED';
    DDERR_TOOBIGHEIGHT:
      result := 'Height requested by DirectDraw is too large.\0';
    DDERR_TOOBIGSIZE:
      result :=
        'Size requested by DirectDraw is too large, but the individual height and width are OK.\0';
    DDERR_TOOBIGWIDTH:
      result := 'Width requested by DirectDraw is too large.\0';
    DDERR_UNSUPPORTED:
      result := 'DDERR_UNSUPPORTED';
    DDERR_UNSUPPORTEDFORMAT:
      result := 'FOURCC format requested is unsupported by DirectDraw.\0';
    DDERR_UNSUPPORTEDMASK:
      result :=
        'Bitmask in the pixel format requested is unsupported by DirectDraw.\0';
    DDERR_VERTICALBLANKINPROGRESS:
      result := 'Vertical blank is in progress.\0';
    DDERR_WASSTILLDRAWING:
      result := 'DDERR_WASSTILLDRAWING';
    DDERR_WRONGMODE:
      result :=
        'This surface can not be restored because it was created in a different mode.\0';
    DDERR_XALIGN:
      result :=
        'Rectangle provided was not horizontally aligned on required boundary.\0';
  else
    result := 'UNKNOWN';
  end;
end;

end.

