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
{ File(s): ref_soft\r_scan.c                                                 }
{                                                                            }
{ Initial conversion by : Adam Kurek (adam@koala.pl)                         }
{ Initial conversion on : 05-Aug-2002                                        }
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
{ Updated on : 06-Aug-2002                                                   }
{ Updated by : Adam Kurek (adam@koala.pl)                                    }
{                                                                            }
{ Updated on : 09-Aug-2002                                                   }
{ Updated by : CodeFusion (Michael@Skovslund.dk)                             }
{                                                                            }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{ none                                                                       }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{ CHECK translations from c to pas (delete commented c code)                 }
{ Should we zero global tables rowptr & column ?                             }
{ Defined types: Short, PShort, ShortArray, PShortArray, fixed16_t, PPByte   }
{   shoud be moved to r_main unit                                            }
{ Defined type Short should be depended of IFDEF USE_DELPHI_TYPES directive? }
{----------------------------------------------------------------------------}
unit r_scan;

interface

uses
  r_local,
  r_model,
  q_shared;

procedure D_WarpScreen;
procedure D_DrawTurbulent8Span;
procedure Turbulent8(pspan: espan_p);
procedure NonTurbulent8(pspan: espan_p);
procedure D_DrawSpans16(pspan: espan_p);
procedure D_DrawZSpans(pspan: espan_p);

var
  r_turb_turb: PInteger;

implementation

uses
  Windows,
  SysUtils,
  ref,
  r_rast,
  r_scana,
  DelphiTypes,
  r_main;

var
  r_turb_pbase: PByte;
  r_turb_pdest: PByte;
  r_turb_s: fixed16_t;
  r_turb_t: fixed16_t;
  r_turb_sstep: fixed16_t;
  r_turb_tstep: fixed16_t;
  r_turb_spancount: Integer;

// STATIC variables
var
  cached_width: Integer = 0;
  cached_height: Integer = 0;
  rowptr: array[0..1200 + (AMP2 * 2) - 1] of PByte;
  column: array[0..1600 + (AMP2 * 2) - 1] of Integer;
  { Should we zero tables rowptr & column ? }

procedure D_WarpScreen;
var
  //byte   **row;
  w, h: Integer;
  u, v: Integer;
  u2, v2: Integer;
  dest: PByte;
  turb: PInteger;
  col: PInteger;
  row: ^PByte;
  destloop: PByte;
// tmp vars to calc pointers
  colptr: Integer;
  turbptr: Integer;
begin
  //
  // these are constant over resolutions, and can be saved
  //
  w := r_newrefdef.width;
  h := r_newrefdef.height;
  if (w <> cached_width) or (h <> cached_height) then
  begin
    cached_width := w;
    cached_height := h;
    for v := 0 to (h + AMP2 * 2) - 1 do
    begin
      v2 := Trunc(v / (h + AMP2 * 2) * r_refdef.vrect.height);
      rowptr[v] := @r_warpbuffer[WARP_WIDTH * v2];
    end;

    for u := 0 to (w + AMP2 * 2) - 1 do
    begin
      //u2 = (int)((float)u/(w + AMP2 * 2) * r_refdef.vrect.width);
      u2 := Trunc(u / (w + AMP2 * 2) * r_refdef.vrect.width);
      column[u] := u2;
    end
  end;

  //turb = intsintable + ((int)(r_newrefdef.time*SPEED)&(CYCLE-1));
  turb := @intsintable[Trunc(r_newrefdef.time * SPEED) and (CYCLE - 1)];
  //dest = vid.buffer + r_newrefdef.y * vid.rowbytes + r_newrefdef.x;
  dest := vid.buffer;
  Inc(Integer(dest), r_newrefdef.y * vid.rowbytes + r_newrefdef.x);

  //for (v=0 ; v<h ; v++, dest += vid.rowbytes)
  for v := 0 to h - 1 do
  begin
    //col = &column[turb[v]];
    col := @column[PIntegerArray(turb)^[v]];
    //row = &rowptr[v];
    row := @rowptr[v];
    //for (u=0 ; u<w ; u+=4)
    u := 0;
    destloop := dest;
    colptr := Integer(col);
    turbptr := Integer(turb);
    while u < w do
    begin
      { CHECK IT !!! }
      { Has been checked and rewritten ;-) }
      //dest[u+0] = row[turb[u+0]][col[u+0]];
      //dest[u+1] = row[turb[u+1]][col[u+1]];
      //dest[u+2] = row[turb[u+2]][col[u+2]];
      //dest[u+3] = row[turb[u+3]][col[u+3]];
      destloop^ := PByteArray(Integer(row) + (PInteger(turbptr)^ * SizeOf(Pointer)))^[PInteger(colptr)^];
      Inc(destloop);
      Inc(turbptr, SizeOf(Integer));
      Inc(colptr, SizeOf(Integer));
      destloop^ := PByteArray(Integer(row) + (PInteger(turbptr)^ * SizeOf(Pointer)))^[PInteger(colptr)^];
      Inc(destloop);
      Inc(turbptr, SizeOf(Integer));
      Inc(colptr, SizeOf(Integer));
      destloop^ := PByteArray(Integer(row) + (PInteger(turbptr)^ * SizeOf(Pointer)))^[PInteger(colptr)^];
      Inc(destloop);
      Inc(turbptr, SizeOf(Integer));
      Inc(colptr, SizeOf(Integer));
      destloop^ := PByteArray(Integer(row) + (PInteger(turbptr)^ * SizeOf(Pointer)))^[PInteger(colptr)^];
      Inc(destloop);
      Inc(turbptr, SizeOf(Integer));
      Inc(colptr, SizeOf(Integer));
      Inc(u, 4); //u+=4
    end;
    Inc(dest, vid.rowbytes); //for (u=0...
  end
end;

{$IFNDEF id386end}

(*
=============
D_DrawTurbulent8Span
=============
*)

procedure D_DrawTurbulent8Span;
var
  sturb, tturb: Integer;
begin
  repeat
    //sturb = ((r_turb_s + r_turb_turb[(r_turb_t>>16)&(CYCLE-1)])>>16)&63;
    sturb := ((r_turb_s + PIntegerArray(r_turb_turb)[(r_turb_t shr 16) and (CYCLE - 1)]) shr 16) and 63;
    //tturb = ((r_turb_t + r_turb_turb[(r_turb_s>>16)&(CYCLE-1)])>>16)&63;
    tturb := ((r_turb_t + PIntegerArray(r_turb_turb)[(r_turb_s shr 16) and (CYCLE - 1)]) shr 16) and 63;
    //*r_turb_pdest++ = *(r_turb_pbase + (tturb<<6) + sturb);
    r_turb_pdest^ := PByteArray(r_turb_pbase)^[(tturb shl 6) + sturb];
    Inc(r_turb_pdest);
    //r_turb_s += r_turb_sstep;
    r_turb_s := r_turb_s + r_turb_sstep;
    //r_turb_t += r_turb_tstep;
    r_turb_t := r_turb_t + r_turb_tstep;
    Dec(r_turb_spancount);
  until not (r_turb_spancount > 0);
  //while (--r_turb_spancount > 0);
end;

{$ENDIF}

(*
=============
Turbulent8
=============
*)

procedure Turbulent8(pspan: espan_p);
var
  count: Integer;
  snext: fixed16_t;
  tnext: fixed16_t;
  sdivz, tdivz: Single;
  zi, z, du, dv: Single;
  spancountminus1: Single;
  sdivz16stepu: Single;
  tdivz16stepu: Single;
  zi16stepu: Single;
begin
  Assert(pspan <> nil);
  //r_turb_turb = sintable + ((int)(r_newrefdef.time*SPEED)&(CYCLE-1));
  r_turb_turb := @sintable[Round(r_newrefdef.time * SPEED) and (CYCLE - 1)];

  r_turb_sstep := 0; // keep compiler happy
  r_turb_tstep := 0; // ditto

  //r_turb_pbase = (unsigned char *)cacheblock;
  r_turb_pbase := cacheblock;

  //sdivz16stepu = d_sdivzstepu * 16;
  //tdivz16stepu = d_tdivzstepu * 16;
  //zi16stepu = d_zistepu * 16;
  sdivz16stepu := d_sdivzstepu * 16;
  tdivz16stepu := d_tdivzstepu * 16;
  zi16stepu := d_zistepu * 16;

  //do
  repeat
    //r_turb_pdest = (unsigned char *)((byte *)d_viewbuffer +
    //                (r_screenwidth * pspan->v) + pspan->u);
    r_turb_pdest := @PByteArray(d_viewbuffer)[(r_screenwidth * pspan.v) + pspan.u];

    //count = pspan->count;
    count := pspan.count;

    // calculate the initial s/z, t/z, 1/z, s, and t and clamp
    //du = (float)pspan->u;
    //dv = (float)pspan->v;
    du := pspan.u;
    dv := pspan.v;

    sdivz := d_sdivzorigin + dv * d_sdivzstepv + du * d_sdivzstepu;
    tdivz := d_tdivzorigin + dv * d_tdivzstepv + du * d_tdivzstepu;
    zi := d_ziorigin + dv * d_zistepv + du * d_zistepu;
    //z = (float)0x10000 / zi;   // prescale to 16.16 fixed-point
    z := $10000 / zi; { prescale to 16.16 fixed-point }

    //r_turb_s = (int)(sdivz * z) + sadjust;
    r_turb_s := Round(sdivz * z) + sadjust;
    if (r_turb_s > bbextents) then
      r_turb_s := bbextents
    else
      if (r_turb_s < 0) then
        r_turb_s := 0;

    //r_turb_t = (int)(tdivz * z) + tadjust;
    r_turb_t := Round(tdivz * z) + tadjust;
    if (r_turb_t > bbextentt) then
      r_turb_t := bbextentt
    else
      if (r_turb_t < 0) then
        r_turb_t := 0;

    //do
    repeat
      // calculate s and t at the far end of the span
      if (count >= 16) then
        r_turb_spancount := 16
      else
        r_turb_spancount := count;

      //count -= r_turb_spancount;
      count := count - r_turb_spancount;

      //if (count)
      if (count <> 0) then
      begin
        // calculate s/z, t/z, zi->fixed s and t at far end of span,
        // calculate s and t steps across span by shifting
        sdivz := sdivz + sdivz16stepu;
        tdivz := tdivz + tdivz16stepu;
        zi := zi + zi16stepu;
        //z = (float)0x10000 / zi;   // prescale to 16.16 fixed-point
        z := $10000 / zi; // prescale to 16.16 fixed-point

        //snext = (int)(sdivz * z) + sadjust;
        snext := Round(sdivz * z) + sadjust;
        if (snext > bbextents) then
          snext := bbextents
        else
          if (snext < 16) then
            snext := 16; // prevent round-off error on <0 steps from
                         //  from causing overstepping & running off the
                         //  edge of the texture

        //tnext = (int)(tdivz * z) + tadjust;
        tnext := trunc(tdivz * z) + tadjust;
        if (tnext > bbextentt) then
          tnext := bbextentt
        else
          if (tnext < 16) then
            tnext := 16; // guard against round-off error on <0 steps

        //r_turb_sstep = (snext - r_turb_s) >> 4;
        //r_turb_tstep = (tnext - r_turb_t) >> 4;
        r_turb_sstep := _SAR((snext - r_turb_s), 4);
        r_turb_tstep := _SAR((tnext - r_turb_t), 4);
      end
      else
      begin
        // calculate s/z, t/z, zi->fixed s and t at last pixel in span (so
        // can't step off polygon), clamp, calculate s and t steps across
        // span by division, biasing steps low so we don't run off the
        // texture
        //spancountminus1 = (float)(r_turb_spancount - 1);
        spancountminus1 := (r_turb_spancount - 1);
        //sdivz += d_sdivzstepu * spancountminus1;
        sdivz := sdivz + d_sdivzstepu * spancountminus1;
        tdivz := tdivz + d_tdivzstepu * spancountminus1;
        //zi += d_zistepu * spancountminus1;
        zi := zi + d_zistepu * spancountminus1;
        //z = (float)0x10000 / zi;   // prescale to 16.16 fixed-point
        z := $10000 / zi; { prescale to 16.16 fixed-point }
        //snext = (int)(sdivz * z) + sadjust;
        snext := Round(sdivz * z) + sadjust;
        if (snext > bbextents) then
          snext := bbextents
        else
          if (snext < 16) then
            snext := 16; // prevent round-off error on <0 steps from
                         //  from causing overstepping & running off the
                         //  edge of the texture

        //tnext = (int)(tdivz * z) + tadjust;
        tnext := Round(tdivz * z) + tadjust;
        if (tnext > bbextentt) then
          tnext := bbextentt
        else
          if (tnext < 16) then
            tnext := 16; // guard against round-off error on <0 steps

        if (r_turb_spancount > 1) then
        begin
          //r_turb_sstep = (snext - r_turb_s) / (r_turb_spancount - 1);
          //r_turb_tstep = (tnext - r_turb_t) / (r_turb_spancount - 1);
          r_turb_sstep := (snext - r_turb_s) div (r_turb_spancount - 1);
          r_turb_tstep := (tnext - r_turb_t) div (r_turb_spancount - 1);
        end
      end;

      //r_turb_s = r_turb_s & ((CYCLE<<16)-1);
      //r_turb_t = r_turb_t & ((CYCLE<<16)-1);
      r_turb_s := r_turb_s and ((CYCLE shl 16) - 1);
      r_turb_t := r_turb_t and ((CYCLE shl 16) - 1);

      D_DrawTurbulent8Span();

      r_turb_s := snext;
      r_turb_t := tnext;

    until not (count > 0);
    //while (count > 0);

    pspan := pspan.pnext;
  until not (pspan <> nil);
  //while ((pspan = pspan->pnext) != NULL);
end;

//====================
//PGM
{*
=============
NonTurbulent8 - this is for drawing scrolling textures. they're warping water textures
 but the turbulence is automatically 0.
=============
*}

procedure NonTurbulent8(pspan: espan_p);
var
  count: Integer;
  snext, tnext: fixed16_t;
  sdivz, tdivz: Single;
  zi, z, du, dv: Single;
  spancountminus1: Single;
  sdivz16stepu: Single;
  tdivz16stepu: Single;
  zi16stepu: Single;
begin
  Assert(pspan <> nil);
  //   r_turb_turb = sintable + ((int)(r_newrefdef.time*SPEED)&(CYCLE-1));
  Assert(r_turb_turb <> nil);
  //r_turb_turb = blanktable;
  Move(blanktable[0], PIntegerArray(r_turb_turb)[0], SizeOf(blanktable));

  r_turb_sstep := 0; // keep compiler happy
  r_turb_tstep := 0; // ditto

  //r_turb_pbase = (unsigned char *)cacheblock;
  r_turb_pbase := cacheblock;

  sdivz16stepu := d_sdivzstepu * 16;
  tdivz16stepu := d_tdivzstepu * 16;
  zi16stepu := d_zistepu * 16;

  //do
  repeat
    //r_turb_pdest = (unsigned char *)((byte *)d_viewbuffer +
    //                (r_screenwidth * pspan->v) + pspan->u);
    r_turb_pdest := @PByteArray(d_viewbuffer)^[(r_screenwidth * pspan^.v) + pspan^.u];

    count := pspan^.count;

    // calculate the initial s/z, t/z, 1/z, s, and t and clamp
    //du = (float)pspan->u;
    //dv = (float)pspan->v;
    du := pspan^.u;
    dv := pspan^.v;

    sdivz := d_sdivzorigin + dv * d_sdivzstepv + du * d_sdivzstepu;
    tdivz := d_tdivzorigin + dv * d_tdivzstepv + du * d_tdivzstepu;
    zi := d_ziorigin + dv * d_zistepv + du * d_zistepu;
    //z = (float)0x10000 / zi;   // prescale to 16.16 fixed-point
    z := $10000 / zi; { prescale to 16.16 fixed-point }

    //r_turb_s = (int)(sdivz * z) + sadjust;
    r_turb_s := Trunc(sdivz * z) + sadjust;
    if (r_turb_s > bbextents) then
      r_turb_s := bbextents
    else
      if (r_turb_s < 0) then
        r_turb_s := 0;

    //r_turb_t = (int)(tdivz * z) + tadjust;
    r_turb_t := Round(tdivz * z) + tadjust;
    if (r_turb_t > bbextentt) then
      r_turb_t := bbextentt
    else
      if (r_turb_t < 0) then
        r_turb_t := 0;

    //do
    repeat
      // calculate s and t at the far end of the span
      if (count >= 16) then
        r_turb_spancount := 16
      else
        r_turb_spancount := count;

      //count -= r_turb_spancount;
      count := count - r_turb_spancount;

      //if (count)
      if Boolean(count) then
      begin
        // calculate s/z, t/z, zi->fixed s and t at far end of span,
        // calculate s and t steps across span by shifting
        sdivz := sdivz + sdivz16stepu;
        tdivz := tdivz + tdivz16stepu;
        zi := zi + zi16stepu;
        //z = (float)0x10000 / zi;   // prescale to 16.16 fixed-point
        z := $10000 / zi; // prescale to 16.16 fixed-point

        //snext = (int)(sdivz * z) + sadjust;
        snext := Round(sdivz * z) + sadjust;
        if (snext > bbextents) then
          snext := bbextents
        else
          if (snext < 16) then
            snext := 16; // prevent round-off error on <0 steps from
                          //  from causing overstepping & running off the
                          //  edge of the texture

        //tnext = (int)(tdivz * z) + tadjust;
        tnext := Round(tdivz * z) + tadjust;
        if (tnext > bbextentt) then
          tnext := bbextentt
        else
          if (tnext < 16) then
            tnext := 16; // guard against round-off error on <0 steps

        //r_turb_sstep = (snext - r_turb_s) >> 4;
        //r_turb_tstep = (tnext - r_turb_t) >> 4;
        r_turb_sstep := _SAR((snext - r_turb_s), 4);
        r_turb_tstep := _SAR((tnext - r_turb_t), 4);
      end
      else
      begin
        // calculate s/z, t/z, zi->fixed s and t at last pixel in span (so
        // can't step off polygon), clamp, calculate s and t steps across
        // span by division, biasing steps low so we don't run off the
        // texture
        //spancountminus1 = (float)(r_turb_spancount - 1);
        spancountminus1 := (r_turb_spancount - 1);
        sdivz := sdivz + d_sdivzstepu * spancountminus1;
        tdivz := tdivz + d_tdivzstepu * spancountminus1;
        zi := zi + d_zistepu * spancountminus1;
        //z = (float)0x10000 / zi;   // prescale to 16.16 fixed-point
        z := $10000 / zi; { prescale to 16.16 fixed-point }
        //snext = (int)(sdivz * z) + sadjust;
        snext := Round(sdivz * z) + sadjust;
        if (snext > bbextents) then
          snext := bbextents
        else
          if (snext < 16) then
            snext := 16; // prevent round-off error on <0 steps from
                          //  from causing overstepping & running off the
                          //  edge of the texture

        //tnext = (int)(tdivz * z) + tadjust;
        tnext := Round(tdivz * z) + tadjust;
        if (tnext > bbextentt) then
          tnext := bbextentt
        else
          if (tnext < 16) then
            tnext := 16; // guard against round-off error on <0 steps

        if (r_turb_spancount > 1) then
        begin
          //r_turb_sstep = (snext - r_turb_s) / (r_turb_spancount - 1);
          //r_turb_tstep = (tnext - r_turb_t) / (r_turb_spancount - 1);
          r_turb_sstep := (snext - r_turb_s) div (r_turb_spancount - 1);
          r_turb_tstep := (tnext - r_turb_t) div (r_turb_spancount - 1);
        end
      end;

      //r_turb_s = r_turb_s & ((CYCLE<<16)-1);
      //r_turb_t = r_turb_t & ((CYCLE<<16)-1);
      r_turb_s := r_turb_s and ((CYCLE shl 16) - 1);
      r_turb_t := r_turb_t and ((CYCLE shl 16) - 1);

      D_DrawTurbulent8Span;

      r_turb_s := snext;
      r_turb_t := tnext;

    until not (count > 0);
    //while (count > 0);

    pspan := pspan.pnext;
  until not (pspan <> nil);
  //while ((pspan = pspan->pnext) != NULL);
end;
//PGM
//====================

{$IFNDEF id386}

(*
=============
D_DrawSpans16

  FIXME: actually make this subdivide by 16 instead of 8!!!
=============
*)
//void D_DrawSpans16( espan_t *pspan)

procedure D_DrawSpans16(pspan: espan_p);
var
  count: Integer;
  spancount: Integer;
  s, t, snext: fixed16_t;
  tnext, sstep: fixed16_t;
  tstep: fixed16_t;
  sdivz, tdivz: Single;
  zi, z, du, dv: Single;
  spancountminus1: Single;
  sdivz8stepu: Single;
  tdivz8stepu: Single;
  zi8stepu: Single;
  pbase, pdest: PByte;
  ts, tt: fixed16_t;
begin
  sstep := 0; // keep compiler happy
  tstep := 0; // ditto

  //pbase = (unsigned char *)cacheblock;
  pbase := PByte(cacheblock);

  sdivz8stepu := d_sdivzstepu * 8;
  tdivz8stepu := d_tdivzstepu * 8;
  zi8stepu := d_zistepu * 8;

  //do
  repeat
    //pdest = (unsigned char *)((byte *)d_viewbuffer +
    //                (r_screenwidth * pspan->v) + pspan->u);
    pdest := @PByteArray(d_viewbuffer)^[(r_screenwidth * pspan^.v) + pspan^.u];
    count := pspan^.count;
    // calculate the initial s/z, t/z, 1/z, s, and t and clamp
    //du = (float)pspan->u;
    //dv = (float)pspan->v;
    du := pspan^.u;
    dv := pspan^.v;

    sdivz := d_sdivzorigin + dv * d_sdivzstepv + du * d_sdivzstepu;
    tdivz := d_tdivzorigin + dv * d_tdivzstepv + du * d_tdivzstepu;
    zi := d_ziorigin + dv * d_zistepv + du * d_zistepu;
    //z = (float)0x10000 / zi;   // prescale to 16.16 fixed-point
    z := $10000 / zi; // prescale to 16.16 fixed-point

    //s = (int)(sdivz * z) + sadjust;
    s := Trunc(sdivz * z) + sadjust;
    if (s > bbextents) then
      s := bbextents
    else
      if (s < 0) then
        s := 0;

    //t = (int)(tdivz * z) + tadjust;
    t := Trunc(tdivz * z) + tadjust;
    if (t > bbextentt) then
      t := bbextentt
    else
      if (t < 0) then
        t := 0;

    //do
    repeat
      // calculate s and t at the far end of the span
      if (count >= 8) then
        spancount := 8
      else
        spancount := count;

      //count -= spancount;
      count := count - spancount;

      //if (count)
      if count > 0 then
      begin
        // calculate s/z, t/z, zi->fixed s and t at far end of span,
        // calculate s and t steps across span by shifting
        sdivz := sdivz + sdivz8stepu;
        tdivz := tdivz + tdivz8stepu;
        zi := zi + zi8stepu;
        //z = (float)0x10000 / zi;   // prescale to 16.16 fixed-point
        z := $10000 / zi; // prescale to 16.16 fixed-point

        //snext = (int)(sdivz * z) + sadjust;
        snext := Trunc(sdivz * z) + sadjust;
        if (snext > bbextents) then
          snext := bbextents
        else
          if (snext < 8) then
            snext := 8; // prevent round-off error on <0 steps from
                        //  from causing overstepping & running off the
                        //  edge of the texture

        //tnext = (int)(tdivz * z) + tadjust;
        tnext := Trunc(tdivz * z) + tadjust;
        if (tnext > bbextentt) then
          tnext := bbextentt
        else
          if (tnext < 8) then
            tnext := 8; // guard against round-off error on <0 steps

        //sstep = (snext - s) >> 3;
        //tstep = (tnext - t) >> 3;
        sstep := _SAR((snext - s), 3); //(snext - s) div 8;//shr 3;
        tstep := _SAR((tnext - t), 3);
      end
      else
      begin
        // calculate s/z, t/z, zi->fixed s and t at last pixel in span (so
        // can't step off polygon), clamp, calculate s and t steps across
        // span by division, biasing steps low so we don't run off the
        // texture
        //spancountminus1 = (float)(spancount - 1);
        spancountminus1 := (spancount - 1);
        sdivz := sdivz + d_sdivzstepu * spancountminus1;
        tdivz := tdivz + d_tdivzstepu * spancountminus1;
        zi := zi + d_zistepu * spancountminus1;
        //z = (float)0x10000 / zi;   // prescale to 16.16 fixed-point
        z := $10000 / zi; { prescale to 16.16 fixed-point }
        //snext = (int)(sdivz * z) + sadjust;
        snext := Trunc(sdivz * z) + sadjust;
        if (snext > bbextents) then
          snext := bbextents
        else
          if (snext < 8) then
            snext := 8; // prevent round-off error on <0 steps from
                         //  from causing overstepping & running off the
                         //  edge of the texture

        //tnext = (int)(tdivz * z) + tadjust;
        tnext := Trunc(tdivz * z) + tadjust;
        if (tnext > bbextentt) then
          tnext := bbextentt
        else
          if (tnext < 8) then
            tnext := 8; // guard against round-off error on <0 steps

        if (spancount > 1) then
        begin
          //sstep = (snext - s) / (spancount - 1);
          //tstep = (tnext - t) / (spancount - 1);
          sstep := trunc((snext - s) / (spancount - 1));
          tstep := trunc((tnext - t) / (spancount - 1));
        end
      end;

      //do
      repeat
        //*pdest++ = *(pbase + (s >> 16) + (t >> 16) * cachewidth);
        ts := _SAR(s, 16);
        tt := _SAR(t, 16);
        pdest^ := PByte(Integer(pbase) + ts + tt * cachewidth)^;
        Inc(Integer(pdest));
        s := s + sstep;
        t := t + tstep;
        Dec(spancount);
      until (spancount <= 0);
      s := snext;
      t := tnext;
    until not (count > 0);
    //while (count > 0);

    pspan := pspan^.pnext;
  until (pspan = nil);
  //while ((pspan = pspan->pnext) != NULL);
end;

{$ENDIF}

{$IFNDEF id386}

(*
=============
D_DrawZSpans
=============
*)
//void D_DrawZSpans (espan_t *pspan)

procedure D_DrawZSpans(pspan: espan_p);
var
  count: Integer;
  doublecount: Integer;
  izistep: Integer;
  izi: Integer;
  pdest: PSmallInt;
  ltemp: Cardinal;
  zi: Single;
  du, dv: Single;
begin
  // FIXME: check for clamping/range problems
  // we count on FP exceptions being turned off to avoid range problems

  Assert(pspan <> nil);
  //izistep = (int)(d_zistepu * 0x8000 * 0x10000);
  izistep := Trunc(d_zistepu * $8000 * $10000);

  //do
  repeat
    //pdest = d_pzbuffer + (d_zwidth * pspan->v) + pspan->u;
    pdest := @PSmallIntArray(d_pzbuffer)^[(Integer(d_zwidth) * pspan^.v) + pspan^.u];
//    pdest := PSmallInt(Integer(d_pzbuffer)+(((Integer(d_zwidth)*pspan^.v)+pspan^.u)*SizeOf(SmallInt)));

    count := pspan^.count;

    // calculate the initial 1/z
    du := pspan^.u;
    dv := pspan^.v;

    zi := d_ziorigin + dv * d_zistepv + du * d_zistepu;
    // we count on FP exceptions being turned off to avoid range problems
    //izi = (int)(zi * 0x8000 * 0x10000);
    izi := Trunc(zi * $8000 * $10000);

    //if ((long)pdest & 0x02)
    if (Cardinal(pdest) and $02) <> 0 then
    begin
      //*pdest++ = (short)(izi >> 16);
      pdest^ := _SAR(izi, 16); //(izi shr 16);
      Inc(Integer(pdest), SizeOf(pdest^));
      izi := izi + izistep;
      Dec(count);
    end;

    //if ((doublecount = count >> 1) > 0)
    doublecount := count shr 1;
    if (doublecount) > 0 then
    //do
      repeat
        ltemp := izi shr 16; // need to clear upper part (16 high bits).
        izi := izi + izistep;
      //ltemp |= izi & 0xFFFF0000;
        ltemp := (ltemp and $FFFF) or (Cardinal(izi) and $FFFF0000);
        izi := izi + izistep;
      //*(int *)pdest = ltemp;
        PCardinal(pdest)^ := ltemp;
      //pdest += 2;
        Inc(Integer(pdest), SizeOf(Cardinal));
        Dec(doublecount);
      until (doublecount = 0);
    //while (--doublecount > 0);

    //if (count & 1)
    if (count and 1) <> 0 then
      pdest^ := _SAR(izi, 16);
      //*pdest = (short)(izi >> 16);
    pspan := pspan^.pnext;
  until (pspan = nil);
  //while ((pspan = pspan->pnext) != NULL);
end;

{$ENDIF}

end.
