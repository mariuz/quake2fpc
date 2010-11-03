// PLEASE, don't modify this file
// 50% complete

{----------------------------------------------------------------------------}
{                                                                            }
{ File(s): r_surf.c: surface-related refresh code                            }
{                                                                            }
{ Initial conversion by : YgriK (Igor Karpov) - glYgriK@hotbox.ru            }
{ Initial conversion on : 04-Feb-2002                                        }
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
{ x)                                                                         }
{                                                                            }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{ 1) Do more tests                                                           }
{                                                                            }
{----------------------------------------------------------------------------}

// r_surf.c: surface-related refresh code

unit r_surf;

interface

uses
  q_shared,
  r_model,
  r_local;

procedure D_FlushCaches;
procedure R_SurfacePatch;
procedure R_InitCaches;
function R_TextureAnimation(tex: mtexinfo_p): image_p;
procedure R_DrawSurface;
function D_CacheSurface(surface: msurface_p; miplevel: Integer): surfcache_p;

var
  r_drawsurf: drawsurf_t;
  sc_size: Integer;
  sc_rover: surfcache_p;
  sc_base: surfcache_p;

implementation

uses
  r_bsp_c,
  r_light,
  r_main,
  r_misc,
  ref,
  SysUtils;

procedure R_DrawSurfaceBlock8_mip0; forward;
procedure R_DrawSurfaceBlock8_mip1; forward;
procedure R_DrawSurfaceBlock8_mip2; forward;
procedure R_DrawSurfaceBlock8_mip3; forward;

var
surfmiptable: array[0..3]

of procedure = (
  R_DrawSurfaceBlock8_mip0,
  R_DrawSurfaceBlock8_mip1,
  R_DrawSurfaceBlock8_mip2,
  R_DrawSurfaceBlock8_mip3
  );
//*****************************************
// CodeFusion: Has been commented because
//   it's not used in pure delphi version.
//*****************************************
//  sourcesstep     : Integer;
//  lightdelta      : Integer;
//  lightdeltastep  : Integer;
//*****************************************
var
  lightleft: Integer;
  blocksize: Integer;
  sourcetstep: Integer;
  lightright: Integer;
  lightleftstep: Integer;
  lightrightstep: Integer;
  blockdivshift: Integer;
  blockdivmask: Cardinal;
  prowdestbase: Pointer;
  pbasesource: PByte;
  surfrowbytes: Integer; // used by ASM files
  r_lightptr: PCardinal;
  r_stepback: Integer;
  r_lightwidth: Integer;
  r_numhblocks: Integer;
  r_numvblocks: Integer;
  r_source: PByte;
  r_sourcemax: PByte;

//extern   unsigned      blocklights[1024];   // allow some very large lightmaps

  surfscale: Single;
  r_cache_thrash: qboolean; // set if surface cache is thrashing

(*
===============
R_TextureAnimation

Returns the proper texture for a given time and base texture
===============
*)

  function R_TextureAnimation(tex: mtexinfo_p): image_p;
  var
    c: Integer;
  begin
    if (tex^.next = nil) then
    begin
      Result := tex^.image;
      Exit;
    end;
    c := currententity^.frame mod tex^.numframes;
    while (c > 0) do
    begin
      tex := tex^.next;
      Dec(c);
    end;
    Result := tex^.image;
  end;

(*
===============
R_DrawSurface
===============
*)

  procedure R_DrawSurface;
  var
    basetptr: PByte;
    smax, tmax: Integer;
    twidth, u: Integer;
    soffset: Integer;
    basetoffset: Integer;
    texwidth: Integer;
    horzblockstep: Integer;
    pcolumndest: PByte;
    pblockdrawer: procedure;
    mt: image_p;
  begin
    surfrowbytes := r_drawsurf.rowbytes;
    mt := r_drawsurf.image;

    r_source := mt^.pixels[r_drawsurf.surfmip];

// the fractional light values should range from 0 to (VID_GRADES - 1) << 16
// from a source range of 0 - 255

    texwidth := mt^.width shr r_drawsurf.surfmip;

    blocksize := 16 shr r_drawsurf.surfmip;
    blockdivshift := 4 - r_drawsurf.surfmip;
    blockdivmask := (1 shl blockdivshift) - 1;

    r_lightwidth := _SAR(r_drawsurf.surf^.extents[0], 4) + 1;

    r_numhblocks := r_drawsurf.surfwidth shr blockdivshift;
    r_numvblocks := r_drawsurf.surfheight shr blockdivshift;

//==============================

    pblockdrawer := surfmiptable[r_drawsurf.surfmip];
// TODO: only needs to be set when there is a display settings change
    horzblockstep := blocksize;

    smax := mt^.width shr r_drawsurf.surfmip;
    twidth := texwidth;
    tmax := mt^.height shr r_drawsurf.surfmip;
    sourcetstep := texwidth;
    r_stepback := tmax * twidth;

    r_sourcemax := PByte(Integer(r_source) + (tmax * smax));

    soffset := r_drawsurf.surf^.texturemins[0];
    basetoffset := r_drawsurf.surf^.texturemins[1];

// << 16 components are to guarantee positive values for %
    soffset := (_SAR(soffset, r_drawsurf.surfmip) + _SAR(smax, 16)) mod smax;
    basetptr := @PByteArray(r_source)^[(((_SAR(basetoffset, r_drawsurf.surfmip) + _SAR(tmax, 16)) mod tmax) * twidth)];

    pcolumndest := r_drawsurf.surfdat;

    for u := 0 to r_numhblocks - 1 do
    begin
      r_lightptr := PCardinal(Integer(@blocklights) + (u * SizeOf(Cardinal)));
      prowdestbase := pcolumndest;

      pbasesource := PByte(Integer(basetptr) + soffset);

      pblockdrawer;

      soffset := soffset + blocksize;
      if (soffset >= smax) then
        soffset := 0;

      Inc(Integer(pcolumndest), horzblockstep);
    end;
  end;

//=============================================================================

{$IFNDEF id386}

(*
================
R_DrawSurfaceBlock8_mip0
================
*)

  procedure R_DrawSurfaceBlock8_mip0;
  var
    v, i, b: Integer;
    lightstep: Integer;
    lighttemp: Integer;
    light: Integer;
    pix: Byte;
    psource: PByte;
    prowdest: PByte;
  begin
    psource := pbasesource;
    prowdest := prowdestbase;

    for V := 0 to r_numvblocks - 1 do
    begin
 // FIXME: make these locals?
 // FIXME: use delta rather than both right and left, like ASM?
      lightleft := r_lightptr^;
      lightright := PCardinal(Integer(r_lightptr) + SizeOf(Cardinal))^;
      Inc(Integer(r_lightptr), r_lightwidth * SizeOf(Cardinal));
      lightleftstep := _SAR(Integer(r_lightptr^) - lightleft, 4);
      lightrightstep := _SAR(Integer(PCardinal(Integer(r_lightptr) + SizeOf(Cardinal))^) - lightright, 4);

      for i := 0 to 15 do
      begin
        lighttemp := lightleft - lightright;
        lightstep := _SAR(lighttemp, 4);

        light := lightright;

        for b := 15 downto 0 do
        begin
          pix := PByteArray(psource)^[b];
          PByteArray(prowdest)^[b] := PByteArray(vid.colormap)^[(light and $FF00) + pix];
          Inc(light, lightstep);
        end;

        Inc(Integer(psource), sourcetstep);
        Inc(lightright, lightrightstep);
        Inc(lightleft, lightleftstep);
        Inc(Integer(prowdest), surfrowbytes);
      end;

      if (Integer(psource) >= Integer(r_sourcemax)) then
        Dec(Integer(psource), r_stepback);
    end;
  end;

(*
================
R_DrawSurfaceBlock8_mip1
================
*)

  procedure R_DrawSurfaceBlock8_mip1;
  var
    v, i, b: Integer;
    lightstep: Integer;
    lighttemp: Integer;
    light: Integer;
    pix: Byte;
    psource: PByte;
    prowdest: PByte;
  begin
    psource := pbasesource;
    prowdest := prowdestbase;

    for V := 0 to r_numvblocks - 1 do
    begin
 // FIXME: make these locals?
 // FIXME: use delta rather than both right and left, like ASM?
      lightleft := r_lightptr^;
      lightright := PCardinal(Integer(r_lightptr) + SizeOf(Cardinal))^;
      Inc(Integer(r_lightptr), r_lightwidth * SizeOf(Cardinal));
      lightleftstep := _SAR(Integer(r_lightptr^) - lightleft, 3);
      lightrightstep := _SAR(Integer(PCardinal(Integer(r_lightptr) + SizeOf(Cardinal))^) - lightright, 3);

      for i := 0 to 7 do
      begin
        lighttemp := lightleft - lightright;
        lightstep := _SAR(lighttemp, 3);

        light := lightright;

        for b := 7 downto 0 do
        begin
          pix := PByteArray(psource)^[b];
          PByteArray(prowdest)^[b] := PByteArray(vid.colormap)^[(light and $FF00) + pix];
          Inc(light, lightstep);
        end;

        Inc(Integer(psource), sourcetstep);
        Inc(lightright, lightrightstep);
        Inc(lightleft, lightleftstep);
        Inc(Integer(prowdest), surfrowbytes);
      end;

      if (Integer(psource) >= Integer(r_sourcemax)) then
        Dec(Integer(psource), r_stepback);
    end;
  end;

(*
================
R_DrawSurfaceBlock8_mip2
================
*)

  procedure R_DrawSurfaceBlock8_mip2;
  var
    v, i, b: Integer;
    lightstep: Integer;
    lighttemp: Integer;
    light: Integer;
    pix: Byte;
    psource: PByte;
    prowdest: PByte;
  begin
    psource := pbasesource;
    prowdest := prowdestbase;

    for V := 0 to r_numvblocks - 1 do
    begin
 // FIXME: make these locals?
 // FIXME: use delta rather than both right and left, like ASM?
      lightleft := r_lightptr^;
      lightright := PCardinal(Integer(r_lightptr) + SizeOf(Cardinal))^;
      Inc(Integer(r_lightptr), r_lightwidth * SizeOf(Cardinal));
      lightleftstep := _SAR(Integer(r_lightptr^) - lightleft, 2);
      lightrightstep := _SAR(Integer(PCardinal(Integer(r_lightptr) + SizeOf(Cardinal))^) - lightright, 2);

      for i := 0 to 3 do
      begin
        lighttemp := lightleft - lightright;
        lightstep := _SAR(lighttemp, 2);

        light := lightright;

        for b := 3 downto 0 do
        begin
          pix := PByteArray(psource)^[b];
          PByteArray(prowdest)^[b] := PByteArray(vid.colormap)^[(light and $FF00) + pix];
          Inc(light, lightstep);
        end;

        Inc(Integer(psource), sourcetstep);
        Inc(lightright, lightrightstep);
        Inc(lightleft, lightleftstep);
        Inc(Integer(prowdest), surfrowbytes);
      end;

      if (Integer(psource) >= Integer(r_sourcemax)) then
        Dec(Integer(psource), r_stepback);
    end;
  end;

(*
================
R_DrawSurfaceBlock8_mip3
================
*)

  procedure R_DrawSurfaceBlock8_mip3;
  var
    v, i, b: Integer;
    lightstep: Integer;
    lighttemp: Integer;
    light: Integer;
    pix: Byte;
    psource: PByte;
    prowdest: PByte;
  begin
    psource := pbasesource;
    prowdest := prowdestbase;

    for V := 0 to r_numvblocks - 1 do
    begin
 // FIXME: make these locals?
 // FIXME: use delta rather than both right and left, like ASM?
      lightleft := r_lightptr^;
      lightright := PCardinal(Integer(r_lightptr) + SizeOf(Cardinal))^;
      Inc(Integer(r_lightptr), r_lightwidth * SizeOf(Cardinal));
      lightleftstep := _SAR(Integer(r_lightptr^) - lightleft, 1);
      lightrightstep := _SAR(Integer(PCardinal(Integer(r_lightptr) + SizeOf(Cardinal))^) - lightright, 1);

      for i := 0 to 1 do
      begin
        lighttemp := lightleft - lightright;
        lightstep := _SAR(lighttemp, 1);

        light := lightright;

        for b := 1 downto 0 do
        begin
          pix := PByteArray(psource)^[b];
          PByteArray(prowdest)^[b] := PByteArray(vid.colormap)^[(light and $FF00) + pix];
          Inc(light, lightstep);
        end;

        Inc(Integer(psource), sourcetstep);
        Inc(lightright, lightrightstep);
        Inc(lightleft, lightleftstep);
        Inc(Integer(prowdest), surfrowbytes);
      end;

      if (Integer(psource) >= Integer(r_sourcemax)) then
        Dec(Integer(psource), r_stepback);
    end;
  end;
{$ENDIF}

//============================================================================

(*
================
R_InitCaches

================
*)
procedure R_InitCaches;
var
   size  : Integer;
   pix   : Integer;
begin
   // calculate size to allocate
   if (sw_surfcacheoverride^.value <> 0.0) then
   begin
      size := Trunc(sw_surfcacheoverride^.value);
   end
   else
   begin
      size := SURFCACHE_SIZE_AT_320X240;

      pix := vid.width*vid.height;
      if (pix > 64000) then
         Inc(size, (pix-64000)*3);
   end;

   // round up to page size
   size := (size + 8191) and (not 8191);

   ri.Con_Printf(PRINT_ALL,'%dk surface cache', (size shr 10));

   sc_size := size;
   sc_base := AllocMem(size);
   sc_rover := sc_base;

   sc_base^.next := NIL;
   sc_base^.owner := NIL;
   sc_base^.size := sc_size;
end;

(*
==================
D_FlushCaches
==================
*)

  procedure D_FlushCaches;
  var
    c: surfcache_p;
  begin
    if (sc_base = nil) then
      Exit;

    c := sc_base;
    while (c <> nil) do
    begin
      if (c^.owner <> nil) then
        c^.owner^ := nil;
      c := c^.next
    end;

    sc_rover := sc_base;
    sc_base^.next := nil;
    sc_base^.owner := nil;
    sc_base^.size := sc_size;
  end;

(*
=================
D_SCAlloc
=================
*)

  function D_SCAlloc(width, size: Integer): surfcache_p;
  var
    new: surfcache_p;
    wrapped_this_time: qboolean;
  begin
    if ((width < 0) or (width > 256)) then
      ri.Sys_Error(ERR_FATAL, PChar('D_SCAlloc: bad cache width ' + IntToStr(width)));

    if ((size <= 0) or (size > $10000)) then
      ri.Sys_Error(ERR_FATAL, PChar('D_SCAlloc: bad cache size ' + IntToStr(size)));

// Don't know if this generates an error but lets see :-)
    size := Integer(@(surfcache_p(0)^.data[size]));
    size := (size + 3) and (not 3);
    if (size > sc_size) then
      ri.Sys_Error(ERR_FATAL, PChar('D_SCAlloc: ' + IntToStr(size) + ' > cache size of ' + IntToStr(sc_size)));

// if there is not size bytes after the rover, reset to the start
    wrapped_this_time := false;

    if (sc_rover = nil) or ((Integer(sc_rover) - Integer(sc_base)) > sc_size - size) then
    begin
      if (sc_rover <> nil) then
      begin
        wrapped_this_time := true;
      end;
      sc_rover := sc_base;
    end;

// colect and free surfcache_t blocks until the rover block is large enough
    new := sc_rover;
    if (sc_rover^.owner <> nil) then
      sc_rover^.owner^ := nil;

    while (new^.size < size) do
    begin
 // free another
      sc_rover := sc_rover^.next;
      if (sc_rover = nil) then
        ri.Sys_Error(ERR_FATAL, 'D_SCAlloc: hit the end of memory');
      if (sc_rover^.owner <> nil) then
        sc_rover^.owner^ := nil;

      Inc(new^.size, sc_rover^.size);
      new^.next := sc_rover^.next;
    end;

// create a fragment out of any leftovers
    if (new^.size - size > 256) then
    begin
      sc_rover := surfcache_p(Integer(new) + size);
      sc_rover^.size := new^.size - size;
      sc_rover^.next := new^.next;
      sc_rover^.width := 0;
      sc_rover^.owner := nil;
      new^.next := sc_rover;
      new^.size := size;
    end
    else
      sc_rover := new^.next;

    new^.width := width;
// DEBUG
    if (width > 0) then
      new^.height := (size - sizeof(new^) + sizeof(new^.data)) div width;

    new^.owner := nil; // should be set properly after return

    if (d_roverwrapped) then
    begin
      if (wrapped_this_time or (Integer(sc_rover) >= Integer(d_initial_rover))) then
        r_cache_thrash := true;
    end
    else
    begin
      if (wrapped_this_time) then
      begin
        d_roverwrapped := true;
      end;
    end;
    Result := new;
  end;

(*
=================
D_SCDump
=================
*)
procedure D_SCDump;
var
  test  : surfcache_p;
begin
  test := sc_base;
  while (test <> nil) do
   begin
      if (Integer(test) = Integer(sc_rover)) then
         ri.Con_Printf(PRINT_ALL,'ROVER:');
      ri.Con_Printf(PRINT_ALL,'%d : %d bytes. %d width', Integer(test), test^.size, test^.width);
    test := test^.next;
   end;
end;

//=============================================================================

// if the num is not a power of 2, assume it will not repeat

  function MaskForNum(num: Integer): Integer;
  begin
    if (num = 128) then
    begin
      Result := 127;
      Exit;
    end;
    if (num = 64) then
    begin
      Result := 63;
      Exit;
    end;
    if (num = 32) then
    begin
      Result := 31;
      Exit;
    end;
    if (num = 16) then
    begin
      Result := 15;
      Exit;
    end;
    Result := 255;
  end;

  function D_log2(num: Integer): Integer;
  var
    c: Integer;
  begin
    c := 0;
    while (num <> 0) do
    begin
      Inc(c);
      num := num shr 1;
    end;
    Result := c;
  end;

//=============================================================================

(*
================
D_CacheSurface
================
*)

  function D_CacheSurface(surface: msurface_p; miplevel: Integer): surfcache_p;
  var
    cache: surfcache_p;
  begin
//
// if the surface is animating or flashing, flush the cache
//
    r_drawsurf.image := R_TextureAnimation(surface^.texinfo);
    r_drawsurf.lightadj[0] := Trunc(lightstyle_p(Integer(r_newrefdef.lightstyles) + (surface^.styles[0] * SizeOf(lightstyle_t)))^.white * 128);
    r_drawsurf.lightadj[1] := Trunc(lightstyle_p(Integer(r_newrefdef.lightstyles) + (surface^.styles[1] * SizeOf(lightstyle_t)))^.white * 128);
    r_drawsurf.lightadj[2] := Trunc(lightstyle_p(Integer(r_newrefdef.lightstyles) + (surface^.styles[2] * SizeOf(lightstyle_t)))^.white * 128);
    r_drawsurf.lightadj[3] := Trunc(lightstyle_p(Integer(r_newrefdef.lightstyles) + (surface^.styles[3] * SizeOf(lightstyle_t)))^.white * 128);

//
// see if the cache holds apropriate data
//
    cache := surface^.cachespots[miplevel];

    if ((cache <> nil) and ((cache^.dlight = 0) and (surface^.dlightframe <> r_framecount)) and
      (Integer(cache^.image) = Integer(r_drawsurf.image)) and
      (cache^.lightadj[0] = r_drawsurf.lightadj[0]) and
      (cache^.lightadj[1] = r_drawsurf.lightadj[1]) and
      (cache^.lightadj[2] = r_drawsurf.lightadj[2]) and
      (cache^.lightadj[3] = r_drawsurf.lightadj[3])) then
    begin
      Result := cache;
      Exit;
    end;

//
// determine shape of surface
//
    surfscale := 1.0 / (1 shl miplevel);
    r_drawsurf.surfmip := miplevel;
    r_drawsurf.surfwidth := surface^.extents[0] shr miplevel;
    r_drawsurf.rowbytes := r_drawsurf.surfwidth;
    r_drawsurf.surfheight := surface^.extents[1] shr miplevel;

//
// allocate memory if needed
//
    if (cache = nil) then // if a texture just animated, don't reallocate it
    begin
      cache := D_SCAlloc(r_drawsurf.surfwidth, r_drawsurf.surfwidth * r_drawsurf.surfheight);
      surface^.cachespots[miplevel] := cache;
      cache^.owner := @surface^.cachespots[miplevel];
      cache^.mipscale := surfscale;
    end;

    if (surface^.dlightframe = r_framecount) then
      cache^.dlight := 1
    else
      cache^.dlight := 0;

    r_drawsurf.surfdat := @cache^.data;

    cache^.image := r_drawsurf.image;
    cache^.lightadj[0] := r_drawsurf.lightadj[0];
    cache^.lightadj[1] := r_drawsurf.lightadj[1];
    cache^.lightadj[2] := r_drawsurf.lightadj[2];
    cache^.lightadj[3] := r_drawsurf.lightadj[3];

//
// draw and light the surface texture
//
    r_drawsurf.surf := surface;

    Inc(c_surf);

 // calculate the lightings
    R_BuildLightMap;

 // rasterize the surface into the cache
    R_DrawSurface;

    Result := cache;
  end;

  procedure R_SurfacePatch;
  begin
  end;

end.
