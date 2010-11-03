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

{$ALIGN 8}{$MINENUMSIZE 4}
{----------------------------------------------------------------------------}
{                                                                            }
{ File(s): r_poly.pas                                                        }
{                                                                            }
{ Initial conversion by : Jose M. Navarro (jose.man@airtel.net)              }
{ Initial conversion on : 16-Jul-2002                                        }
{                                                                            }
{ This File contains part of convertion of Quake2 source to ObjectPascal.    }
{ More information about this project can be found at:                       }
{ http://www.sulaco.co.za/quake2/                                            }
{                                                                            }
{ Copyright (C) 1997-2001 Id Software, Inc.                                  }
{                                                                            }
{ This program is free software; you can redistribute it and/or              }
{ modify it under the terms of the GNU General Public License                }
{ as puC:\Documents and Settings\PCDELPHI4.PC-DELPHI4\Escritorio\g_target.c  }
{ blished by the Free Software Foundation; either version 2                  }
{ of the License, or (at your option) any later version.                     }
{                                                                            }
{ This program is distributed in the hope that it will be useful,            }
{ but WITHOUT ANY WARRANTY; without even the implied warranty of             }
{ MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                       }
{                                                                            }
{ See the GNU General Public License for more details.                       }
{                                                                            }
{----------------------------------------------------------------------------}
{ Updated on : 12-Aug-2002                                                   }
{ Updated by : CodeFusion (Michael@Skovslund.dk)                             }
{                                                                            }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{ All critical points has been noted with //????. Please search that in      }
{ final conversion                                                           }
{                                                                            }
{  r_scan.pas unit must be included (interface) when finished.               }
{  r_main.pas unit must be included (implementation) when finished           }
{  For uncomment when r_main.pas included.                                   }
{  Sys_Error (in ref.pas) still doesn't support arguments                    }
{  no overloaded version of VectorSubtract                                   }
{  mSurface_s structure hasn't any field called "nextalphasurface"           }
{  DotProduct expects vec3_t instead vec5_t                                  }
{                                                                            }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{----------------------------------------------------------------------------}
unit r_poly;

interface

uses
  r_local,
  r_model,
  q_shared;

procedure R_DrawSpanletOpaque; cdecl;
procedure R_DrawSpanletTurbulentStipple33; cdecl;
procedure R_DrawSpanletTurbulentStipple66; cdecl;
procedure R_DrawSpanletTurbulentBlended66; cdecl;
procedure R_DrawSpanletTurbulentBlended33; cdecl;
procedure R_DrawSpanlet33; cdecl;
procedure R_DrawSpanletConstant33; cdecl;
procedure R_DrawSpanlet66; cdecl;
procedure R_DrawSpanlet33Stipple; cdecl;
procedure R_DrawSpanlet66Stipple; cdecl;
function R_ClipPolyFace(nump: Integer; pclipplane: clipplane_p): Integer;
procedure R_PolygonDrawSpans(pspan: espan_p; iswater: Integer);
procedure R_PolygonScanLeftEdge;
procedure R_PolygonScanRightEdge;
procedure R_ClipAndDrawPoly(alpha: Single; isturbulent: Integer; textured: qboolean);
procedure R_BuildPolygonFromSurface(fa: msurface_p);
procedure R_PolygonCalculateGradients;
procedure R_DrawPoly(iswater: Integer);
procedure R_DrawAlphaSurfaces;
procedure R_IMFlatShadedQuad(a: vec3_t; b: vec3_t; c: vec3_t; d: vec3_t; color: Integer; alpha: Single);

var
  r_alpha_surfaces: msurface_p;
  r_polydesc: polydesc_t;
  r_clip_verts: array[0..1, 0..(MAXWORKINGVERTS + 2) - 1] of vec5_t;

implementation

uses
  r_surf,
  r_misc,
  r_main,
  r_scan,
  r_rast,
  r_bsp_c,
  SysUtils,
  DelphiTypes,
  Math;

const
  AFFINE_SPANLET_SIZE = 16;
  AFFINE_SPANLET_SIZE_BITS = 4;

type
  spanletvars_p = ^spanletvars_t;
  spanletvars_t = record
    pbase: PByte;
    pdest: PByte;
    pz: PSmallInt;
    s, t: fixed16_t;
    sstep: fixed16_t;
    tstep: fixed16_t;
    izi: Integer;
    izistep: Integer;
    izistep_times_2: Integer;
    spancount: Integer;
    u, v: Cardinal;
  end;

var
  s_spanletvars: spanletvars_t;
  r_polyblendcolor: Integer;
  s_polygon_spans: espan_p;
  clip_current: Integer;
  s_minindex: Integer;
  s_maxindex: Integer;

{
** R_DrawSpanletOpaque
}

procedure R_DrawSpanletOpaque;
var
  btemp: cardinal; // translated unsigned as cardinal
  ts, tt: Integer;
begin
  repeat
    ts := _SAR(s_spanletvars.s, 16);
    tt := _SAR(s_spanletvars.t, 16);

    btemp := PByte(Integer(s_spanletvars.pbase) + (ts) + (tt) * cachewidth)^;
    if btemp <> 255 then
    begin
      if s_spanletvars.pz^ <= _SAR(s_spanletvars.izi, 16) then
      begin
        s_spanletvars.pz^ := _SAR(s_spanletvars.izi, 16);
        s_spanletvars.pdest^ := btemp;
      end;
    end;

    Inc(s_spanletvars.izi, s_spanletvars.izistep);
    Inc(Integer(s_spanletvars.pdest), 1);
    Inc(Integer(s_spanletvars.pz), SizeOf(SmallInt));
    Inc(s_spanletvars.s, s_spanletvars.sstep);
    Inc(s_spanletvars.t, s_spanletvars.tstep);

    Dec(s_spanletvars.spancount); // extracted from while part
  until (s_spanletvars.spancount <= 0); // negated condition for until loop
end;

{
** R_DrawSpanletTurbulentStipple33
}

procedure R_DrawSpanletTurbulentStipple33;
var
  btemp: Cardinal;
  sturb: Integer;
  tturb: Integer;
  pdest: PByte;
  pz: PSmallInt;
  izi: Integer;
begin
  pdest := s_spanletvars.pdest;
  pz := s_spanletvars.pz;
  izi := s_spanletvars.izi;

  if (s_spanletvars.v and 1) <> 0 then
  begin
    Inc(Integer(s_spanletvars.pdest), s_spanletvars.spancount);
    Inc(Integer(s_spanletvars.pz), s_spanletvars.spancount * SizeOf(SmallInt));

    if s_spanletvars.spancount = AFFINE_SPANLET_SIZE then
      Inc(s_spanletvars.izi, _SAL(s_spanletvars.izistep, AFFINE_SPANLET_SIZE_BITS))
    else
      Inc(s_spanletvars.izi, s_spanletvars.izistep * s_spanletvars.izistep);

    if (s_spanletvars.u and 1) <> 0 then
    begin
      Inc(izi, s_spanletvars.izistep);
      Inc(s_spanletvars.s, s_spanletvars.sstep);
      Inc(s_spanletvars.t, s_spanletvars.tstep);

      Inc(Integer(pdest), 1);
      Inc(Integer(pz), SizeOf(SmallInt));
      Dec(s_spanletvars.spancount);
    end;

    s_spanletvars.sstep := s_spanletvars.sstep * 2;
    s_spanletvars.tstep := s_spanletvars.tstep * 2;

    while (s_spanletvars.spancount > 0) do
    begin
      // temporary conversion for pointer arithmetic
//      tmp := r_turb_turb;
      sturb := _SAR(PIntegerArray(r_turb_turb)^[_SAR(s_spanletvars.t, 16) and (CYCLE - 1)], 16) and 63;
      tturb := _SAR(PIntegerArray(r_turb_turb)^[_SAR(s_spanletvars.s, 16) and (CYCLE - 1)], 16) and 63;
      btemp := PByte(Integer(s_spanletvars.pbase) + (sturb) + _SAL(tturb, 6))^;

      if pz^ <= _SAR(izi, 16) then
        pdest^ := btemp;

      Inc(izi, s_spanletvars.izistep_times_2);
      Inc(s_spanletvars.s, s_spanletvars.sstep);
      Inc(s_spanletvars.t, s_spanletvars.tstep);

      Inc(Integer(pdest), 2);
      Inc(Integer(pz), 2 * SizeOF(SmallInt));

      Dec(s_spanletvars.spancount, 2);
    end;
  end;
end;

{
** R_DrawSpanletTurbulentStipple66
}

procedure R_DrawSpanletTurbulentStipple66;
var
  btemp: cardinal;
  sturb, tturb: integer;
  pdest: PByte;
  pz: PSmallInt;
  izi: integer;
  tmp: PInteger;
begin
  pdest := s_spanletvars.pdest;
  pz := s_spanletvars.pz;
  izi := s_spanletvars.izi;

  if (s_spanletvars.v and 1) = 0 then
  begin
    Inc(Integer(s_spanletvars.pdest), s_spanletvars.spancount);
    Inc(Integer(s_spanletvars.pz), s_spanletvars.spancount * SizeOf(SmallInt));

    if s_spanletvars.spancount = AFFINE_SPANLET_SIZE then
      Inc(s_spanletvars.izi, s_spanletvars.izistep shl AFFINE_SPANLET_SIZE_BITS)
    else
      Inc(s_spanletvars.izi, s_spanletvars.izistep * s_spanletvars.izistep);

    if (s_spanletvars.u and 1) <> 0 then
    begin
      Inc(izi, s_spanletvars.izistep);
      Inc(s_spanletvars.s, s_spanletvars.sstep);
      Inc(s_spanletvars.t, s_spanletvars.tstep);

      Inc(Integer(pdest));
      Inc(Integer(pz), SizeOf(SmallInt));
      Dec(s_spanletvars.spancount);
    end;

    s_spanletvars.sstep := s_spanletvars.sstep * 2;
    s_spanletvars.tstep := s_spanletvars.tstep * 2;

    while s_spanletvars.spancount > 0 do
    begin
      // temporary conversion for pointer arithmetic
      tmp := r_turb_turb;
      Inc(Integer(tmp), ((s_spanletvars.t shr 16) and (CYCLE - 1)) * SizeOf(Integer));
      sturb := ((s_spanletvars.s + tmp^) shr 16) and 63;
      // temporary conversion for pointer arithmetic
      tmp := r_turb_turb;
      Inc(Integer(tmp), ((s_spanletvars.s shr 16) and (CYCLE - 1)) * SizeOf(Integer));
      tturb := ((s_spanletvars.t + tmp^) shr 16) and 63;

      btemp := PByte(Integer(s_spanletvars.pbase) + (sturb) + (tturb shl 6))^;

      if pz^ <= (izi shr 16) then
        pdest^ := btemp;

      Inc(izi, s_spanletvars.izistep_times_2);
      Inc(s_spanletvars.s, s_spanletvars.sstep);
      Inc(s_spanletvars.t, s_spanletvars.tstep);

      Inc(Integer(pdest), 2);
      Inc(Integer(pz), 2 * SizeOf(SmallInt));

      Dec(s_spanletvars.spancount, 2);
    end;
  end
  else
  begin
    Inc(Integer(s_spanletvars.pdest), s_spanletvars.spancount);
    Inc(Integer(s_spanletvars.pz), s_spanletvars.spancount * SizeOf(SmallInt));

    if s_spanletvars.spancount = AFFINE_SPANLET_SIZE then
      Inc(s_spanletvars.izi, s_spanletvars.izistep shl AFFINE_SPANLET_SIZE_BITS)
    else
      Inc(s_spanletvars.izi, s_spanletvars.izistep * s_spanletvars.izistep);

    while s_spanletvars.spancount > 0 do
    begin
      // temporary conversion for pointer arithmetic
      tmp := r_turb_turb;
      Inc(Integer(tmp), ((s_spanletvars.t shr 16) and (CYCLE - 1)) * SizeOf(Integer));
      sturb := ((s_spanletvars.s + tmp^) shr 16) and 63;
      // temporary conversion for pointer arithmetic
      tmp := r_turb_turb;
      Inc(Integer(tmp), ((s_spanletvars.s shr 16) and (CYCLE - 1)) * SizeOf(Integer));
      tturb := ((s_spanletvars.t + tmp^) shr 16) and 63;

      btemp := PByte(Integer(s_spanletvars.pbase) + (sturb) + (tturb shl 6))^;

      if pz^ <= (izi shr 16) then
        pdest^ := btemp;

      Inc(izi, s_spanletvars.izistep);
      Inc(s_spanletvars.s, s_spanletvars.sstep);
      Inc(s_spanletvars.t, s_spanletvars.tstep);

      Inc(Integer(pdest));
      Inc(Integer(pz), SizeOf(SmallInt));

      Dec(s_spanletvars.spancount);
    end;
  end;
end;

{
** R_DrawSpanletTurbulentBlended
}

procedure R_DrawSpanletTurbulentBlended66;
var
  btemp: cardinal;
  sturb, tturb: integer;
  tmp: PInteger;
  tmp_b: PByte;
begin
  repeat
    // temporary conversion for pointer arithmetic
    tmp := r_turb_turb;
    Inc(Integer(tmp), ((s_spanletvars.t shr 16) and (CYCLE - 1)) * SizeOf(Integer));
    sturb := ((s_spanletvars.s + tmp^) shr 16) and 63;
    // temporary conversion for pointer arithmetic
    tmp := r_turb_turb;
    Inc(Integer(tmp), ((s_spanletvars.s shr 16) and (CYCLE - 1)) * SizeOf(Integer));
    tturb := ((s_spanletvars.t + tmp^) shr 16) and 63;

    btemp := PByte(Integer(s_spanletvars.pbase) + (sturb) + (tturb shl 6))^;

    if s_spanletvars.pz^ <= (s_spanletvars.izi shr 16) then
    begin
      // temporary conversion for pointer arithmetic
      tmp_b := vid.alphamap;
      Inc(Integer(tmp_b), btemp * 256 + s_spanletvars.pdest^);
      s_spanletvars.pdest^ := tmp_b^;
    end;

    Inc(s_spanletvars.izi, s_spanletvars.izistep);
    Inc(Integer(s_spanletvars.pdest));
    Inc(Integer(s_spanletvars.pz), SizeOf(SmallInt));
    Inc(s_spanletvars.s, s_spanletvars.sstep);
    Inc(s_spanletvars.t, s_spanletvars.tstep);

    Dec(s_spanletvars.spancount);
  until (s_spanletvars.spancount <= 0);
end;

procedure R_DrawSpanletTurbulentBlended33;
var
  btemp: cardinal;
  sturb, tturb: integer;
  tmp: PInteger;
  tmp_b: PByte;
begin
  repeat
    // temporary conversion for pointer arithmetic
    tmp := r_turb_turb;
    Inc(tmp, (s_spanletvars.t shr 16) and (CYCLE - 1));
    sturb := ((s_spanletvars.s + tmp^) shr 16) and 63;
    // temporary conversion for pointer arithmetic
    tmp := r_turb_turb;
    Inc(tmp, (s_spanletvars.s shr 16) and (CYCLE - 1));
    tturb := ((s_spanletvars.t + tmp^) shr 16) and 63;

    btemp := PByte(Integer(s_spanletvars.pbase) + (sturb) + (tturb shl 6))^;

    if s_spanletvars.pz^ <= (s_spanletvars.izi shr 16) then
    begin
      // temporary conversion for pointer arithmetic
      tmp_b := vid.alphamap;
      Inc(Integer(tmp_b), btemp + s_spanletvars.pdest^ * 256);
      s_spanletvars.pdest^ := tmp_b^;
    end;

    Inc(s_spanletvars.izi, s_spanletvars.izistep);
    Inc(Integer(s_spanletvars.pdest), 1);
    Inc(Integer(s_spanletvars.pz), SizeOf(SmallInt));
    Inc(s_spanletvars.s, s_spanletvars.sstep);
    Inc(s_spanletvars.t, s_spanletvars.tstep);

    Dec(s_spanletvars.spancount);
  until not (s_spanletvars.spancount > 0);
end;

{
** R_DrawSpanlet33
}

procedure R_DrawSpanlet33;
var
  btemp: cardinal;
  ts, tt: Integer;
  tmp_b: PByte;
begin
  repeat
    ts := _SAR(s_spanletvars.s, 16);
    tt := _SAR(s_spanletvars.t, 16);

    btemp := PByte(Integer(s_spanletvars.pbase) + (ts) + (tt) * cachewidth)^;

    if btemp <> 255 then
    begin
      if s_spanletvars.pz^ <= _SAR(s_spanletvars.izi, 16) then
      begin
        // temporary conversion for pointer arithmetic
        tmp_b := vid.alphamap;
        Inc(Integer(tmp_b), btemp + s_spanletvars.pdest^ * 256);
        s_spanletvars.pdest^ := tmp_b^;
      end;
    end;

    Inc(s_spanletvars.izi, s_spanletvars.izistep);
    Inc(Integer(s_spanletvars.pdest), 1);
    Inc(Integer(s_spanletvars.pz), SizeOf(SmallInt));
    Inc(s_spanletvars.s, s_spanletvars.sstep);
    Inc(s_spanletvars.t, s_spanletvars.tstep);

    Dec(s_spanletvars.spancount);
  until not (s_spanletvars.spancount > 0);
end;

procedure R_DrawSpanletConstant33;
var
  tmp_b: PByte;
begin
  repeat
    if s_spanletvars.pz^ <= _SAR(s_spanletvars.izi, 16) then
    begin
      // temporary conversion for pointer arithmetic
      tmp_b := vid.alphamap;
      Inc(Integer(tmp_b), r_polyblendcolor + s_spanletvars.pdest^ * 256);
      s_spanletvars.pdest^ := tmp_b^;
    end;

    Inc(s_spanletvars.izi, s_spanletvars.izistep);
    Inc(Integer(s_spanletvars.pdest), 1);
    Inc(Integer(s_spanletvars.pz), SizeOf(SmallInt));

    Dec(s_spanletvars.spancount);
  until not (s_spanletvars.spancount > 0);
end;

{
** R_DrawSpanlet66
}

procedure R_DrawSpanlet66;
var
  btemp: cardinal;
  ts, tt: Integer;
  tmp_b: PByte;
begin
  repeat
    ts := _SAR(s_spanletvars.s, 16);
    tt := _SAR(s_spanletvars.t, 16);

    btemp := PByte(Integer(s_spanletvars.pbase) + (ts) + (tt) * cachewidth)^;

    if btemp <> 255 then
    begin
      if s_spanletvars.pz^ <= _SAR(s_spanletvars.izi, 16) then
      begin
        // temporary conversion for pointer arithmetic
        tmp_b := vid.alphamap;
        Inc(Integer(tmp_b), btemp * 256 + s_spanletvars.pdest^);
        s_spanletvars.pdest^ := tmp_b^;
      end;
    end;

    Inc(s_spanletvars.izi, s_spanletvars.izistep);
    Inc(Integer(s_spanletvars.pdest), 1);
    Inc(Integer(s_spanletvars.pz), SizeOf(SmallInt));
    Inc(s_spanletvars.s, s_spanletvars.sstep);
    Inc(s_spanletvars.t, s_spanletvars.tstep);

    Dec(s_spanletvars.spancount);
  until not (s_spanletvars.spancount > 0);
end;

{
** R_DrawSpanlet33Stipple
}

procedure R_DrawSpanlet33Stipple;
var
  btemp: cardinal;
  pdest: PByte;
  pz: PSmallInt;
  izi: integer;

  s, t: Integer;
begin
  pdest := s_spanletvars.pdest;
  pz := s_spanletvars.pz;
  izi := s_spanletvars.izi;
  if IntPower(r_polydesc.stipple_parity, (s_spanletvars.v and 1)) > 0 then
  begin
    Inc(Integer(s_spanletvars.pdest), s_spanletvars.spancount);
    Inc(Integer(s_spanletvars.pz), s_spanletvars.spancount * SizeOf(SmallInt));

    if s_spanletvars.spancount = AFFINE_SPANLET_SIZE then
      Inc(s_spanletvars.izi, (s_spanletvars.izistep shl AFFINE_SPANLET_SIZE_BITS))
    else
      Inc(s_spanletvars.izi, (s_spanletvars.izistep * s_spanletvars.izistep));

    if IntPower(r_polydesc.stipple_parity, (s_spanletvars.u and 1)) > 0 then
    begin
      Inc(izi, s_spanletvars.izistep);
      Inc(s_spanletvars.s, s_spanletvars.sstep);
      Inc(s_spanletvars.t, s_spanletvars.tstep);

      Inc(Integer(pdest), 1);
      Inc(Integer(pz), SizeOf(SmallInt));
      Dec(s_spanletvars.spancount);
    end;

    s_spanletvars.sstep := s_spanletvars.sstep * 2;
    s_spanletvars.tstep := s_spanletvars.tstep * 2;

    while s_spanletvars.spancount > 0 do
    begin
      s := _SAR(s_spanletvars.s, 16);
      t := _SAR(s_spanletvars.t, 16);

      btemp := PByte(Integer(s_spanletvars.pbase) + (s) + (t * cachewidth))^;

      if btemp <> 255 then
      begin
        if pz^ <= _SAR(izi, 16) then
          pdest^ := btemp;
      end;

      Inc(izi, s_spanletvars.izistep_times_2);
      Inc(s_spanletvars.s, s_spanletvars.sstep);
      Inc(s_spanletvars.t, s_spanletvars.tstep);

      Inc(Integer(pdest), 2);
      Inc(Integer(pz), 2 * SizeOf(SmallInt));

      Dec(s_spanletvars.spancount, 2);
    end;
  end;
end;

{
** R_DrawSpanlet66Stipple
}

procedure R_DrawSpanlet66Stipple;
var
  btemp: cardinal;
  pdest: PByte;
  pz: PSmallInt;
  izi: integer;
  s, t: Integer;
begin
  pdest := s_spanletvars.pdest;
  pz := s_spanletvars.pz;
  izi := s_spanletvars.izi;

  Inc(Integer(s_spanletvars.pdest), s_spanletvars.spancount);
  Inc(Integer(s_spanletvars.pz), s_spanletvars.spancount * SizeOf(SmallInt));

  if (s_spanletvars.spancount = AFFINE_SPANLET_SIZE) then
    Inc(s_spanletvars.izi, (s_spanletvars.izistep shl AFFINE_SPANLET_SIZE_BITS))
  else
    Inc(s_spanletvars.izi, s_spanletvars.izistep * s_spanletvars.izistep);

  if IntPower(r_polydesc.stipple_parity, (s_spanletvars.v and 1)) <> 0 then
  begin
    if IntPower(r_polydesc.stipple_parity, (s_spanletvars.u and 1)) <> 0 then
    begin
      Inc(izi, s_spanletvars.izistep);
      Inc(s_spanletvars.s, s_spanletvars.sstep);
      Inc(s_spanletvars.t, s_spanletvars.tstep);

      Inc(Integer(pdest), 1);
      Inc(Integer(pz), SizeOf(SmallInt));
      Dec(s_spanletvars.spancount);
    end;

    s_spanletvars.sstep := s_spanletvars.sstep * 2;
    s_spanletvars.tstep := s_spanletvars.tstep * 2;

    while (s_spanletvars.spancount > 0) do
    begin
      s := _SAR(s_spanletvars.s, 16);
      t := _SAR(s_spanletvars.t, 16);

      btemp := PByte(Integer(s_spanletvars.pbase) + (s) + (t * cachewidth))^;

      if btemp <> 255 then
      begin
        if pz^ <= _SAR(izi, 16) then
          pdest^ := btemp;
      end;

      Inc(izi, s_spanletvars.izistep_times_2);
      Inc(s_spanletvars.s, s_spanletvars.sstep);
      Inc(s_spanletvars.t, s_spanletvars.tstep);

      Inc(Integer(pdest), 2);
      Inc(Integer(pz), 2 * SizeOf(SmallInt));

      Dec(s_spanletvars.spancount, 2);
    end;
  end
  else
  begin
    while (s_spanletvars.spancount > 0) do
    begin
      s := _SAR(s_spanletvars.s, 16);
      t := _SAR(s_spanletvars.t, 16);

      btemp := PByte(Integer(s_spanletvars.pbase) + (s) + (t * cachewidth))^;

      if (btemp <> 255) then
      begin
        if pz^ <= _SAR(izi, 16) then
          pdest^ := btemp;
      end;

      Inc(izi, s_spanletvars.izistep);
      Inc(s_spanletvars.s, s_spanletvars.sstep);
      Inc(s_spanletvars.t, s_spanletvars.tstep);

      Inc(Integer(pdest), 1);
      Inc(Integer(pz), SizeOf(SmallInt));

      Dec(s_spanletvars.spancount);
    end;
  end;
end;

{
** R_ClipPolyFace
**
** Clips the winding at clip_verts[clip_current] and changes clip_current
** Throws out the back side
}

function R_ClipPolyFace(nump: integer; pclipplane: clipplane_p): integer;
var
  i, outcount: Integer;
  dists: array[0..MAXWORKINGVERTS + 3 - 1] of Single;
  frac, clipdist: Single;
  pclipnormal: PSingle;
  _in, instep: PSingle;
  outstep, vert2: PSingle;
label
  continue_;
begin
  clipdist := pclipplane^.dist;
  pclipnormal := @pclipplane^.normal;

// calc dists
  if (clip_current <> 0) then
  begin
    _in := @r_clip_verts[1][0]; // Converted from "r_clip_verts[1][0]"
    outstep := @r_clip_verts[0][0]; // Converted from "r_clip_verts[0][0]"
    clip_current := 0;
  end
  else
  begin
    _in := @r_clip_verts[0][0]; // Converted from "r_clip_verts[0][0]"
    outstep := @r_clip_verts[1][0]; // Converted from "r_clip_verts[1][0]"
    clip_current := 1;
  end;

  instep := _in;
  for i := 0 to nump - 1 do
  begin
    dists[i] := DotProduct(vec3_p(instep)^, vec3_p(pclipnormal)^) - clipdist;
    Inc(Integer(instep), SizeOf(vec5_t));
  end;

// handle wraparound case
  dists[nump] := dists[0];
  Move(_in^, instep^, sizeof(vec5_t));

// clip the winding
  instep := _in;
  outcount := 0;

  for i := 0 to nump - 1 do
  begin
    if (dists[i] >= 0) then
    begin
      Move(instep^, outstep^, SizeOf(vec5_t));
      Inc(Integer(outstep), SizeOf(vec5_t));
      Inc(outcount);
    end;

    if (dists[i] = 0) or (dists[i + 1] = 0) then
      goto continue_;

    if (dists[i] > 0) = (dists[i + 1] > 0) then
      goto continue_;

    // split it into a new vertex
    frac := dists[i] / (dists[i] - dists[i + 1]);

    vert2 := PSingle(Integer(instep) + SizeOf(vec5_t));

    vec5_p(outstep)^[0] := vec5_p(instep)^[0] + frac * (vec5_p(vert2)^[0] - vec5_p(instep)^[0]);
    vec5_p(outstep)^[1] := vec5_p(instep)^[1] + frac * (vec5_p(vert2)^[1] - vec5_p(instep)^[1]);
    vec5_p(outstep)^[2] := vec5_p(instep)^[2] + frac * (vec5_p(vert2)^[2] - vec5_p(instep)^[2]);
    vec5_p(outstep)^[3] := vec5_p(instep)^[3] + frac * (vec5_p(vert2)^[3] - vec5_p(instep)^[3]);
    vec5_p(outstep)^[4] := vec5_p(instep)^[4] + frac * (vec5_p(vert2)^[4] - vec5_p(instep)^[4]);

    Inc(Integer(outstep), SizeOf(vec5_t)); // "/" operator has been changed to "div"
    Inc(outcount);

    continue_:
    Inc(Integer(instep), SizeOf(vec5_t));
  end;
  result := outcount;
end;

{
** R_PolygonDrawSpans
}
// PGM - iswater was qboolean. changed to allow passing more flags

procedure R_PolygonDrawSpans(pspan: espan_p; iswater: integer);
var
  count: integer;
  snext, tnext: fixed16_t;
  sdivz, tdivz: single;
  zi, z, du, dv: single;
  spancountminus1: single;
  sdivzspanletstepu: single;
  tdivzspanletstepu: single;
  zispanletstepu: single;
label
  NextSpan;
begin
  s_spanletvars.pbase := cacheblock;

//PGM
  if (iswater and SURF_WARP) <> 0 then
    r_turb_turb := @sintable[(Trunc(r_newrefdef.time * SPEED) and (CYCLE - 1))] // removed innecesary cast
  else
    if (iswater and SURF_FLOWING) <> 0 then
      r_turb_turb := @blanktable;
//PGM

  sdivzspanletstepu := d_sdivzstepu * AFFINE_SPANLET_SIZE;
  tdivzspanletstepu := d_tdivzstepu * AFFINE_SPANLET_SIZE;
  zispanletstepu := d_zistepu * AFFINE_SPANLET_SIZE;

// we count on FP exceptions being turned off to avoid range problems
  s_spanletvars.izistep := Trunc(d_zistepu * $8000 * $10000);
  s_spanletvars.izistep_times_2 := s_spanletvars.izistep * 2;

  s_spanletvars.pz := nil;

  if (pspan^.count = DS_SPAN_LIST_END) then
    exit;

  repeat
    s_spanletvars.pdest := PByte(Integer(d_viewbuffer) + d_scantable[pspan^.v] + pspan^.u);
    s_spanletvars.pz := @PSmallIntArray(d_pzbuffer)^[(Integer(d_zwidth) * pspan^.v) + pspan^.u];
    s_spanletvars.u := pspan^.u;
    s_spanletvars.v := pspan^.v;

    count := pspan^.count;

    if (count <= 0) then
      goto NextSpan;

      // calculate the initial s/z, t/z, 1/z, s, and t and clamp
    du := pspan^.u;
    dv := pspan^.v;

    sdivz := d_sdivzorigin + dv * d_sdivzstepv + du * d_sdivzstepu;
    tdivz := d_tdivzorigin + dv * d_tdivzstepv + du * d_tdivzstepu;

    zi := d_ziorigin + dv * d_zistepv + du * d_zistepu;
    z := $10000 / zi; // prescale to 16.16 fixed-point
      // we count on FP exceptions being turned off to avoid range problems
    s_spanletvars.izi := Trunc(zi * $8000 * $10000);

    s_spanletvars.s := Trunc(sdivz * z) + sadjust;
    s_spanletvars.t := Trunc(tdivz * z) + tadjust;

    if iswater = 0 then
    begin
      if (s_spanletvars.s > bbextents) then
        s_spanletvars.s := bbextents
      else
        if (s_spanletvars.s < 0) then
          s_spanletvars.s := 0;

      if (s_spanletvars.t > bbextentt) then
        s_spanletvars.t := bbextentt
      else
        if (s_spanletvars.t < 0) then
          s_spanletvars.t := 0;
    end;

    repeat
        // calculate s and t at the far end of the span
      if (count >= AFFINE_SPANLET_SIZE) then
        s_spanletvars.spancount := AFFINE_SPANLET_SIZE
      else
        s_spanletvars.spancount := count;

      Dec(count, s_spanletvars.spancount);

      if count <> 0 then
      begin
          // calculate s/z, t/z, zi->fixed s and t at far end of span,
          // calculate s and t steps across span by shifting
        sdivz := sdivz + sdivzspanletstepu;
        tdivz := tdivz + tdivzspanletstepu;
        zi := zi + zispanletstepu;
        z := z + ($10000 / zi); // prescale to 16.16 fixed-point

        snext := Trunc(sdivz * z) + sadjust;
        tnext := Trunc(tdivz * z) + tadjust;

        if iswater = 0 then
        begin
          if (snext > bbextents) then
            snext := bbextents
          else
            if (snext < AFFINE_SPANLET_SIZE) then
              snext := AFFINE_SPANLET_SIZE; // prevent round-off error on <0 steps from
                                             //  from causing overstepping & running off the
                                             //  edge of the texture

          if (tnext > bbextentt) then
            tnext := bbextentt
          else
            if (tnext < AFFINE_SPANLET_SIZE) then
              tnext := AFFINE_SPANLET_SIZE; // guard against round-off error on <0 steps
        end;

        s_spanletvars.sstep := _SAR(snext - s_spanletvars.s, AFFINE_SPANLET_SIZE_BITS);
        s_spanletvars.tstep := _SAR(tnext - s_spanletvars.t, AFFINE_SPANLET_SIZE_BITS);
      end
      else
      begin
          // calculate s/z, t/z, zi->fixed s and t at last pixel in span (so
          // can't step off polygon), clamp, calculate s and t steps across
          // span by division, biasing steps low so we don't run off the
          // texture
        spancountminus1 := (s_spanletvars.spancount - 1);
        sdivz := sdivz + (d_sdivzstepu * spancountminus1);
        tdivz := tdivz + (d_tdivzstepu * spancountminus1);
        zi := zi + (d_zistepu * spancountminus1);
        z := $10000 / zi; // prescale to 16.16 fixed-point
        snext := Trunc(sdivz * z) + sadjust;
        tnext := Trunc(tdivz * z) + tadjust;

        if iswater = 0 then
        begin
          if (snext > bbextents) then
            snext := bbextents
          else
            if (snext < AFFINE_SPANLET_SIZE) then
              snext := AFFINE_SPANLET_SIZE; // prevent round-off error on <0 steps from
                                             //  from causing overstepping & running off the
                                             //  edge of the texture

          if (tnext > bbextentt) then
            tnext := bbextentt
          else
            if (tnext < AFFINE_SPANLET_SIZE) then
              tnext := AFFINE_SPANLET_SIZE; // guard against round-off error on <0 steps
        end;

        if (s_spanletvars.spancount > 1) then
        begin
          s_spanletvars.sstep := (snext - s_spanletvars.s) div (s_spanletvars.spancount - 1);
          s_spanletvars.tstep := (tnext - s_spanletvars.t) div (s_spanletvars.spancount - 1);
        end;
      end;

      if iswater <> 0 then
      begin
        s_spanletvars.s := s_spanletvars.s and ((CYCLE shl 16) - 1);
        s_spanletvars.t := s_spanletvars.t and ((CYCLE shl 16) - 1);
      end;

      r_polydesc.drawspanlet;

      s_spanletvars.s := snext;
      s_spanletvars.t := tnext;

    until (count <= 0);

    NextSpan:
    Inc(Integer(pspan), SizeOf(espan_t));

  until (pspan^.count = DS_SPAN_LIST_END);
end;

{
**
** R_PolygonScanLeftEdge
**
** Goes through the polygon and scans the left edge, filling in
** screen coordinate data for the spans
}

procedure R_PolygonScanLeftEdge;
var
  i, v, itop: integer;
  ibottom: integer;
  lmaxindex: integer;
  pvert, pnext: emitpoint_p;
  pspan: espan_p;
  du, dv, vtop: single;
  vbottom, slope: single;
  u, u_step: fixed16_t;
begin
  pspan := s_polygon_spans;
  i := s_minindex;
  if (i = 0) then
    i := r_polydesc.nump;

  lmaxindex := s_maxindex;
  if (lmaxindex = 0) then
    lmaxindex := r_polydesc.nump;

  vtop := q_shared.ceil(emitpoint_arrp(r_polydesc.pverts)^[i].v);

  repeat
    pvert := @emitpoint_arrp(r_polydesc.pverts)^[i];
    pnext := Pointer(Integer(pvert) - SizeOf(emitpoint_t));

    vbottom := q_shared.ceil(pnext^.v);

    if (vtop < vbottom) then
    begin
      du := pnext^.u - pvert^.u;
      dv := pnext^.v - pvert^.v;

      slope := du / dv;
      u_step := trunc(slope * $10000);
      //adjust u to ceil the integer portion
      u := Trunc((pvert^.u + (slope * (vtop - pvert^.v))) * $10000) + ($10000 - 1);
      itop := Trunc(vtop);
      ibottom := Trunc(vbottom);

      for v := itop to ibottom - 1 do
      begin
        pspan^.u := _SAR(u, 16);
        pspan^.v := v;
        Inc(u, u_step);
        Inc(Integer(pspan), SizeOf(espan_t));
      end;
    end;

    vtop := vbottom;

    Dec(i);
    if (i = 0) then
      i := r_polydesc.nump;

  until (i = lmaxindex);
end;

{
** R_PolygonScanRightEdge
**
** Goes through the polygon and scans the right edge, filling in
** count values.
}

procedure R_PolygonScanRightEdge;
var
  i, v, itop: Integer;
  ibottom: Integer;
  pvert, pnext: emitpoint_p;
  pspan: espan_p;
  du, dv, vtop: Single;
  vbottom: Single;
  slope, uvert: Single;
  unext, vvert: Single;
  vnext: Single;
  u, u_step: fixed16_t;
begin
  pspan := s_polygon_spans;
  i := s_minindex;

  vvert := emitpoint_arrp(r_polydesc.pverts)^[i].v;

  if (vvert < r_refdef.fvrecty_adj) then
    vvert := r_refdef.fvrecty_adj;

  if (vvert > r_refdef.fvrectbottom_adj) then
    vvert := r_refdef.fvrectbottom_adj;

  vtop := q_shared.ceil(vvert);

  repeat
    pvert := @emitpoint_arrp(r_polydesc.pverts)^[i];
    pnext := Pointer(Integer(pvert) + SizeOf(emitpoint_t));

    vnext := pnext^.v;
    if (vnext < r_refdef.fvrecty_adj) then
      vnext := r_refdef.fvrecty_adj;

    if (vnext > r_refdef.fvrectbottom_adj) then
      vnext := r_refdef.fvrectbottom_adj;

    vbottom := q_shared.ceil(vnext);

    if (vtop < vbottom) then
    begin
      uvert := pvert^.u;
      if (uvert < r_refdef.fvrectx_adj) then
        uvert := r_refdef.fvrectx_adj;
      if (uvert > r_refdef.fvrectright_adj) then
        uvert := r_refdef.fvrectright_adj;

      unext := pnext^.u;
      if (unext < r_refdef.fvrectx_adj) then
        unext := r_refdef.fvrectx_adj;
      if (unext > r_refdef.fvrectright_adj) then
        unext := r_refdef.fvrectright_adj;

      du := unext - uvert;
      dv := vnext - vvert;
      slope := du / dv;
      u_step := Trunc(slope * $10000);
      // adjust u to ceil the integer portion
      u := Trunc((uvert + (slope * (vtop - vvert))) * $10000) + ($10000 - 1);
      itop := Trunc(vtop);
      ibottom := Trunc(vbottom);

      for v := itop to ibottom - 1 do
      begin
        pspan^.count := _SAR(u, 16) - pspan^.u;
        Inc(u, u_step);
        Inc(Integer(pspan), SizeOf(espan_t));
      end;
    end;

    vtop := vbottom;
    vvert := vnext;

    Inc(i);
    if (i = r_polydesc.nump) then
      i := 0;

  until (i = s_maxindex);

  pspan^.count := DS_SPAN_LIST_END; // mark the end of the span list
end;

{
** R_ClipAndDrawPoly
}
// PGM - isturbulent was qboolean. changed to int to allow passing more flags

procedure R_ClipAndDrawPoly(alpha: single; isturbulent: integer; textured: qboolean);
var
  outverts: array[0..MAXWORKINGVERTS + 3 - 1] of emitpoint_t;
  pout: emitpoint_p;
  pv: PSingle;
  i, nump: integer;
  scale: single;
  transformed: vec3_t;
  local: vec3_t;
begin
  FillChar(outverts, SizeOf(outverts), 0);
  if not textured then
  begin
    r_polydesc.drawspanlet := R_DrawSpanletConstant33;
  end
  else
  begin
    {
      ** choose the correct spanlet routine based on alpha
    }
    if (alpha = 1) then
    begin
      // isturbulent is ignored because we know that turbulent surfaces
      // can't be opaque
      r_polydesc.drawspanlet := R_DrawSpanletOpaque;
    end
    else
    begin
      if sw_stipplealpha^.value <> 0.0 then
      begin
        if (isturbulent <> 0) then
        begin
          if (alpha > 0.33) then
            r_polydesc.drawspanlet := R_DrawSpanletTurbulentStipple66
          else
            r_polydesc.drawspanlet := R_DrawSpanletTurbulentStipple33;
        end
        else
        begin
          if (alpha > 0.33) then
            r_polydesc.drawspanlet := R_DrawSpanlet66Stipple
          else
            r_polydesc.drawspanlet := R_DrawSpanlet33Stipple;
        end;
      end
      else
      begin
        if (isturbulent <> 0) then
        begin
          if (alpha > 0.33) then
            r_polydesc.drawspanlet := R_DrawSpanletTurbulentBlended66
          else
            r_polydesc.drawspanlet := R_DrawSpanletTurbulentBlended33;
        end
        else
        begin
          if (alpha > 0.33) then
            r_polydesc.drawspanlet := R_DrawSpanlet66
          else
            r_polydesc.drawspanlet := R_DrawSpanlet33;
        end;
      end;
    end;
  end;

  // clip to the frustum in worldspace
  nump := r_polydesc.nump;
  clip_current := 0;

  for i := 0 to 3 do
  begin
    nump := R_ClipPolyFace(nump, @view_clipplanes[i]);
    if (nump < 3) then
      exit;
    if (nump > MAXWORKINGVERTS) then
      ri.Sys_Error(ERR_DROP, PChar('R_ClipAndDrawPoly: too many points: ' + IntToStr(nump)));
  end;

  // transform vertices into viewspace and project
  pv := @r_clip_verts[clip_current][0];

  for i := 0 to nump - 1 do
  begin
    VectorSubtract(vec3_p(pv)^, r_origin, local);
    TransformVector(local, transformed);

    if (transformed[2] < NEAR_CLIP) then
      transformed[2] := NEAR_CLIP;

    pout := @outverts[i];
    pout^.zi := 1.0 / transformed[2];

    pout^.s := vec5_p(pv)^[3];
    pout^.t := vec5_p(pv)^[4];

    scale := xscale * pout^.zi;
    pout^.u := (xcenter + scale * transformed[0]);

    scale := yscale * pout^.zi;
    pout^.v := (ycenter - scale * transformed[1]);
    Inc(Integer(pv), SizeOf(vec5_t));
  end;

// draw it
  r_polydesc.nump := nump;
  r_polydesc.pverts := @outverts[0]; // C pointer can be converted as Pascal's 1st address element
  R_DrawPoly(isturbulent);
end;

{
** R_BuildPolygonFromSurface
}

procedure R_BuildPolygonFromSurface(fa: msurface_p);
var
  i, lindex: Integer;
  lnumverts: Integer;
  pedges: medge_p;
  r_pedge: medge_p;
//  vertpage  : Integer; // never used
  vec: PSingle;
  pverts: vec5_p;
  tmins: array[0..2 - 1] of Single;
  scache: surfcache_p;
begin
  tmins[0] := 0;
  tmins[1] := 0;

  r_polydesc.nump := 0;

  // reconstruct the polygon
  pedges := currentmodel^.edges;
  lnumverts := fa^.numedges;
//  vertpage  := 0; // never used

  pverts := @r_clip_verts[0][0];

  for i := 0 to lnumverts - 1 do
  begin
    lindex := PIntegerArray(currentmodel^.surfedges)^[fa^.firstedge + i];

    if (lindex > 0) then
    begin
      r_pedge := @medge_arrp(pedges)^[lindex];
      vec := @mvertex_arrp(currentmodel^.vertexes)^[r_pedge^.v[0]].position;
    end
    else
    begin
      r_pedge := @medge_arrp(pedges)^[-lindex];
      vec := @mvertex_arrp(currentmodel^.vertexes)^[r_pedge^.v[1]].position;
    end;
    VectorCopy(vec3_p(vec)^, vec3_p(@vec5_arrp(pverts)^[i])^);
  end;

  VectorCopy(vec3_p(@fa^.texinfo^.vecs[0])^, r_polydesc.vright);
  VectorCopy(vec3_p(@fa^.texinfo^.vecs[1])^, r_polydesc.vup);
  VectorCopy(fa^.plane^.normal, r_polydesc.vpn);
  VectorCopy(r_origin, vec3_p(@r_polydesc.viewer_position)^);

  if (fa^.flags and SURF_PLANEBACK) <> 0 then
  begin
    VectorSubtract(vec3_origin, r_polydesc.vpn, r_polydesc.vpn);
  end;

// PGM 09/16/98
  if (fa^.texinfo^.flags and (SURF_WARP or SURF_FLOWING)) <> 0 then
  begin
    r_polydesc.pixels := fa^.texinfo^.image^.pixels[0];
    r_polydesc.pixel_width := fa^.texinfo^.image^.width;
    r_polydesc.pixel_height := fa^.texinfo^.image^.height;
  end
// PGM 09/16/98
  else
  begin
    scache := D_CacheSurface(fa, 0);

    r_polydesc.pixels := @scache^.data[0];
    r_polydesc.pixel_width := scache^.width;
    r_polydesc.pixel_height := scache^.height;

    tmins[0] := fa^.texturemins[0];
    tmins[1] := fa^.texturemins[1];
  end;

  r_polydesc.dist := DotProduct(r_polydesc.vpn, vec3_p(pverts)^);
  r_polydesc.s_offset := fa^.texinfo^.vecs[0, 3] - tmins[0];
  r_polydesc.t_offset := fa^.texinfo^.vecs[1, 3] - tmins[1];

  // scrolling texture addition
  if (fa^.texinfo^.flags and SURF_FLOWING) <> 0 then
  begin
    r_polydesc.s_offset := r_polydesc.s_offset + (-128 * ((r_newrefdef.time * 0.25) - Trunc(r_newrefdef.time * 0.25)));
  end;

  r_polydesc.nump := lnumverts;
end;

{
** R_PolygonCalculateGradients
}

procedure R_PolygonCalculateGradients;
var
  p_normal: vec3_t;
  p_saxis: vec3_t;
  p_taxis: vec3_t;
  distinv: single;
begin
  TransformVector(r_polydesc.vpn, p_normal);
  TransformVector(r_polydesc.vright, p_saxis);
  TransformVector(r_polydesc.vup, p_taxis);

  distinv := 1.0 / (-(DotProduct(vec3_t(r_polydesc.viewer_position), r_polydesc.vpn)) + r_polydesc.dist);

  d_sdivzstepu := p_saxis[0] * xscaleinv;
  d_sdivzstepv := -p_saxis[1] * yscaleinv;
  d_sdivzorigin := p_saxis[2] - xcenter * d_sdivzstepu - ycenter * d_sdivzstepv;

  d_tdivzstepu := p_taxis[0] * xscaleinv;
  d_tdivzstepv := -p_taxis[1] * yscaleinv;
  d_tdivzorigin := p_taxis[2] - xcenter * d_tdivzstepu - ycenter * d_tdivzstepv;

  d_zistepu := p_normal[0] * xscaleinv * distinv;
  d_zistepv := -p_normal[1] * yscaleinv * distinv;
  d_ziorigin := p_normal[2] * distinv - xcenter * d_zistepu - ycenter * d_zistepv;

  sadjust := fixed16_t(Trunc((DotProduct(vec3_p(@r_polydesc.viewer_position)^, r_polydesc.vright) + r_polydesc.s_offset) * $10000));
  tadjust := fixed16_t(Trunc((DotProduct(vec3_p(@r_polydesc.viewer_position)^, r_polydesc.vup) + r_polydesc.t_offset) * $10000));

// -1 (-epsilon) so we never wander off the edge of the texture
  bbextents := (r_polydesc.pixel_width shl 16) - 1;
  bbextentt := (r_polydesc.pixel_height shl 16) - 1;
end;

{
** R_DrawPoly
**
** Polygon drawing function.  Uses the polygon described in r_polydesc
** to calculate edges and gradients, then renders the resultant spans.
**
** This should NOT be called externally since it doesn't do clipping!
}
// PGM - iswater was qboolean. changed to support passing more flags

procedure R_DrawPoly(iswater: Integer);
var
  i, nump: integer;
  ymin, ymax: single;
  pverts: emitpoint_p;
  spans: array[0..MAXHEIGHT + 1 - 1] of espan_t;
begin
  FillChar(spans, SizeOf(spans), 0);
  s_polygon_spans := @spans[0];

// find the top and bottom vertices, and make sure there's at least one scan to
// draw
  ymin := 999999.9;
  ymax := -999999.9;
  pverts := r_polydesc.pverts;

  for i := 0 to r_polydesc.nump - 1 do
  begin
    if (pverts^.v < ymin) then
    begin
      ymin := pverts^.v;
      s_minindex := i;
    end;

    if (pverts^.v > ymax) then
    begin
      ymax := pverts^.v;
      s_maxindex := i;
    end;
    Inc(Integer(pverts), SizeOf(emitpoint_p));
  end;

  ymin := q_shared.ceil(ymin);
  ymax := q_shared.ceil(ymax);

  if (ymin >= ymax) then
    Exit; // doesn't cross any scans at all

  cachewidth := r_polydesc.pixel_width;
  cacheblock := r_polydesc.pixels;

// copy the first vertex to the last vertex, so we don't have to deal with
// wrapping
  nump := r_polydesc.nump;
  pverts := r_polydesc.pverts;

  emitpoint_arrp(pverts)^[nump] := pverts^;

  R_PolygonCalculateGradients;
  R_PolygonScanLeftEdge;
  R_PolygonScanRightEdge;

  R_PolygonDrawSpans(s_polygon_spans, iswater);
end;

{
** R_DrawAlphaSurfaces
}

procedure R_DrawAlphaSurfaces;
var
  s: msurface_p;
begin
  s := r_alpha_surfaces;

  currentmodel := r_worldmodel;

  modelorg[0] := -r_origin[0];
  modelorg[1] := -r_origin[1];
  modelorg[2] := -r_origin[2];

  while s <> nil do
  begin
    R_BuildPolygonFromSurface(s);

//=======
//PGM
//      if (s->texinfo->flags & SURF_TRANS66)
//         R_ClipAndDrawPoly( 0.60f, ( s->texinfo->flags & SURF_WARP) != 0, true );
//      else
//         R_ClipAndDrawPoly( 0.30f, ( s->texinfo->flags & SURF_WARP) != 0, true );

  // PGM - pass down all the texinfo flags, not just SURF_WARP.
    if (s^.texinfo^.flags and SURF_TRANS66) <> 0 then
      R_ClipAndDrawPoly(0.60, (s^.texinfo^.flags and (SURF_WARP or SURF_FLOWING)), true)
    else
      R_ClipAndDrawPoly(0.30, (s^.texinfo^.flags and (SURF_WARP or SURF_FLOWING)), true);
//PGM
//=======
    s := s^.nextalphasurface;
  end;
  r_alpha_surfaces := nil;
end;

{
** R_IMFlatShadedQuad
}

procedure R_IMFlatShadedQuad(a, b, c, d: vec3_t; color: integer; alpha: single);
var
  s0, s1: vec3_t;
begin
  r_polydesc.nump := 4;

  VectorCopy(r_origin, vec3_p(@r_polydesc.viewer_position)^);

  VectorCopy(a, vec3_p(@r_clip_verts[0][0])^);
  VectorCopy(b, vec3_p(@r_clip_verts[0][1])^);
  VectorCopy(c, vec3_p(@r_clip_verts[0][2])^);
  VectorCopy(d, vec3_p(@r_clip_verts[0][3])^);

  r_clip_verts[0][0][3] := 0;
  r_clip_verts[0][1][3] := 0;
  r_clip_verts[0][2][3] := 0;
  r_clip_verts[0][3][3] := 0;

  r_clip_verts[0][0][4] := 0;
  r_clip_verts[0][1][4] := 0;
  r_clip_verts[0][2][4] := 0;
  r_clip_verts[0][3][4] := 0;

  VectorSubtract(d, c, s0);
  VectorSubtract(c, b, s1);
  CrossProduct(s0, s1, r_polydesc.vpn);
  VectorNormalize(r_polydesc.vpn);

  //???? DotProduct expects vec3_t instead vec5_t
  r_polydesc.dist := DotProduct(r_polydesc.vpn, vec3_p(@r_clip_verts[0][0])^);
  r_polyblendcolor := color;
  R_ClipAndDrawPoly(alpha, 0, false);
end;

end.
