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
{ File(s): r_polyse.c                                                          }
{                                                                            }
{ Initial conversion by : Michael Skovslund (Michael@skovslund.dk)               }
{ Initial conversion on : 24-Mar-2002                                        }
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
{ Updated on : 24-Mar-2002                                                   }
{ Updated by : CodeFusion (Michael@skovslund.dk)                             }
{   Last functions is converted.                                             }
{                                                                            }
{ Updated on : 19-July-2002                                                  }
{ Updated by : CodeFusion (Michael@skovslund.dk)                             }
{   2 functions was forgotten, so now they are implemented :-).              }
{   The functions are:                                                       }
{     procedure R_PolysetDrawSpansConstant8_66(pspanpackage : spanpackage_p);}
{     procedure R_PolysetDrawSpansConstant8_33(pspanpackage : spanpackage_p);}
{                                                                            }
{ Updated on : 21-Aug-2002                                                   }
{ Updated by : Magog (magog@fistofbenztown.de)                               }
{   removed declaration of "r_newrefdef" as it is defined in r_main.pas      }
{                                                                            }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{                                                                            }
{----------------------------------------------------------------------------}
{ IMPORTANT NOTES:                                                           }
{ the file "adivtab.pas" has been converted to "adivtab.inc" so the array    }
{ type is kept within this unit eg. I removed the const declaration from     }
{ "adivtab.pas" so it can be included in this source file.                   }
{ Some functions are not found in .c file. The files are:                    }
{ 1. procedure R_PolysetScanLeftEdge(height : Integer);                      }
{ 2. procedure R_DrawNonSubdiv;                                              }
{ These procedures are defined at the buttom of the unit.                    }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{ Fix all the bugs                                                           }
{ 1)                                                                         }
{ 2)                                                                         }
{----------------------------------------------------------------------------}

// r_polyse.c
unit r_polyse;

interface

uses
  r_local,
{$IFNDEF id386}
  ref,
  q_shared,
{$ENDIF}
  SysUtils;

const
  rand1k: array[0..1023] of integer = (
{$INCLUDE rand1k.inc}
    );
  MASK_1K = $3FF;
// TODO: put in span spilling to shrink list size
// !!! if this is changed, it must be changed in d_polysa.s too !!!
  DPS_MAXSPANS = MAXHEIGHT + 1;
         // 1 extra for spanpackage that marks end

type
// !!! if this is changed, it must be changed in asm_draw.h too !!!
  spanpackage_p = ^spanpackage_t;
  spanpackage_t = record
    pdest: Pointer;
    pz: PSmallInt;
    count: Integer;
    ptex: PByte;
    sfrac: Integer;
    tfrac: Integer;
    light: Integer;
    zi: Integer;
  end;
  spanpackage_array_p = ^spanpackage_array;
  spanpackage_array = array[0..(MaxInt div SizeOf(spanpackage_t))-1] of spanpackage_t;
  fixed8_t = Integer;

// Reported missing in action :-)
{$IFNDEF id386}
procedure R_PolysetScanLeftEdge(height: Integer);
{$ENDIF}
// Well, these survieved the "accident".
procedure R_PolysetSetEdgeTable;
procedure R_RasterizeAliasPolySmooth;
procedure R_PolysetCalcGradients(skinwidth: Integer);
procedure R_PolysetScanLeftEdge_C(height: Integer);
procedure R_PolysetDrawSpans8_Opaque(pspanpackage: spanpackage_p);
procedure R_PolysetDrawThreshSpans8(pspanpackage: spanpackage_p);
procedure R_PolysetDrawSpans8_33(pspanpackage: spanpackage_p);
procedure R_PolysetDrawSpans8_66(pspanpackage: spanpackage_p);
procedure R_DrawTriangle;
procedure R_PolysetUpdateTables;
procedure R_PolysetDrawSpansConstant8_66(pspanpackage: spanpackage_p);
procedure R_PolysetDrawSpansConstant8_33(pspanpackage: spanpackage_p);

type
  drawspans_func = procedure(pspanpackage: spanpackage_p);

var
  d_pdrawspans: drawspans_func;
  aliastriangleparms: aliastriangleparms_t;
  d_aflatcolor: Integer;
  iractive: Byte = 0;

implementation

uses
//  Math,
  r_main,
  r_bsp_c,
  adivtab_inc,
  r_alias_c,
  r_edge,
  DelphiTypes,
  r_polysa;

type
  edgetable_p = ^edgetable;
  edgetable = record
    isflattop: Integer;
    numleftedges: Integer;
    pleftedgevert0: PInteger;
    pleftedgevert1: PInteger;
    pleftedgevert2: PInteger;
    numrightedges: Integer;
    prightedgevert0: PInteger;
    prightedgevert1: PInteger;
    prightedgevert2: PInteger;
  end;

// ======================
// PGM
// 64 65 66 67 68 69 70 71   72 73 74 75 76 77 78 79
const
  irtable: array[0..255] of byte = (
    79, 78, 77, 76, 75, 74, 73, 72, // black/white
    71, 70, 69, 68, 67, 66, 65, 64,
    64, 65, 66, 67, 68, 69, 70, 71, // dark taupe
    72, 73, 74, 75, 76, 77, 78, 79,

    64, 65, 66, 67, 68, 69, 70, 71, // slate grey
    72, 73, 74, 75, 76, 77, 78, 79,
    208, 208, 208, 208, 208, 208, 208, 208, // unused?'
    64, 66, 68, 70, 72, 74, 76, 78, // dark yellow

    64, 65, 66, 67, 68, 69, 70, 71, // dark red
    72, 73, 74, 75, 76, 77, 78, 79,
    64, 65, 66, 67, 68, 69, 70, 71, // grey/tan
    72, 73, 74, 75, 76, 77, 78, 79,

    64, 66, 68, 70, 72, 74, 76, 78, // chocolate
    68, 67, 66, 65, 64, 65, 66, 67, // mauve / teal
    68, 69, 70, 71, 72, 73, 74, 75,
    76, 76, 77, 77, 78, 78, 79, 79,

    64, 65, 66, 67, 68, 69, 70, 71, // more mauve
    72, 73, 74, 75, 76, 77, 78, 79,
    64, 65, 66, 67, 68, 69, 70, 71, // olive
    72, 73, 74, 75, 76, 77, 78, 79,

    64, 65, 66, 67, 68, 69, 70, 71, // maroon
    72, 73, 74, 75, 76, 77, 78, 79,
    64, 65, 66, 67, 68, 69, 70, 71, // sky blue
    72, 73, 74, 75, 76, 77, 78, 79,

    64, 65, 66, 67, 68, 69, 70, 71, // olive again
    72, 73, 74, 75, 76, 77, 78, 79,
    64, 65, 66, 67, 68, 69, 70, 71, // nuclear green
    64, 65, 66, 67, 68, 69, 70, 71, // bright yellow

    64, 65, 66, 67, 68, 69, 70, 71, // fire colors
    72, 73, 74, 75, 76, 77, 78, 79,
    208, 208, 64, 64, 70, 71, 72, 64, // mishmash1
    66, 68, 70, 64, 65, 66, 67, 68); // mishmash2
var
  skintable: array[0..MAX_LBM_HEIGHT - 1] of PByte;
  skinwidth: Integer;
  skinstart: PByte;
  rand1k_index: Integer = 0;
  r_p0: array[0..5] of Integer;
  r_p1: array[0..5] of Integer;
  r_p2: array[0..5] of Integer;
// Compiler says it's never used!
//  d_pcolormap         : PByte;
  d_xdenom: Integer;
  pedgetable: edgetable_p;
// FIXME: some of these can become statics
  a_sstepxfrac: Integer;
  a_tstepxfrac: Integer;
  r_lstepx: Integer;
  a_ststepxwhole: Integer;

  r_sstepx: Integer;
  r_tstepx: Integer;
  r_lstepy: Integer;
  r_sstepy: Integer;
  r_tstepy: Integer;

  r_zistepx: Integer;
  r_zistepy: Integer;

  d_aspancount: Integer;
  d_countextrastep: Integer;

  a_spans: spanpackage_p;
  d_pedgespanpackage: spanpackage_p;
  ystart: Integer;
  d_pdest: PByte;
  d_ptex: PByte;
  d_pz: PSmallInt;

  d_sfrac: Integer;
  d_tfrac: Integer;
  d_light: Integer;
  d_zi: Integer;
  d_ptexextrastep: Integer;
  d_sfracextrastep: Integer;

  d_tfracextrastep: Integer;
  d_lightextrastep: Integer;
  d_pdestextrastep: Integer;

  d_lightbasestep: Integer;
  d_pdestbasestep: Integer;
  d_ptexbasestep: Integer;

  d_sfracbasestep: Integer;
  d_tfracbasestep: Integer;

  d_ziextrastep: Integer;
  d_zibasestep: Integer;

  d_pzextrastep: Integer;
  d_pzbasestep: Integer;

const
//  adivtab : array[0..32*32-1] of adivtab_t = (
//    {$include adivtab.inc}
//  );

  edgetables: array[0..11] of edgetable = (
    (isflattop: 0;
    numleftedges: 1;
    pleftedgevert0: @r_p0;
    pleftedgevert1: @r_p2;
    pleftedgevert2: nil;
    numrightedges: 2;
    prightedgevert0: @r_p0;
    prightedgevert1: @r_p1;
    prightedgevert2: @r_p2),
    (isflattop: 0;
    numleftedges: 2;
    pleftedgevert0: @r_p1;
    pleftedgevert1: @r_p0;
    pleftedgevert2: @r_p2;
    numrightedges: 1;
    prightedgevert0: @r_p1;
    prightedgevert1: @r_p2;
    prightedgevert2: nil),
    (isflattop: 1;
    numleftedges: 1;
    pleftedgevert0: @r_p0;
    pleftedgevert1: @r_p2;
    pleftedgevert2: nil;
    numrightedges: 1;
    prightedgevert0: @r_p1;
    prightedgevert1: @r_p2;
    prightedgevert2: nil),
    (isflattop: 0;
    numleftedges: 1;
    pleftedgevert0: @r_p1;
    pleftedgevert1: @r_p0;
    pleftedgevert2: nil;
    numrightedges: 2;
    prightedgevert0: @r_p1;
    prightedgevert1: @r_p2;
    prightedgevert2: @r_p0),
    (isflattop: 0;
    numleftedges: 2;
    pleftedgevert0: @r_p0;
    pleftedgevert1: @r_p2;
    pleftedgevert2: @r_p1;
    numrightedges: 1;
    prightedgevert0: @r_p0;
    prightedgevert1: @r_p1;
    prightedgevert2: nil),
    (isflattop: 0;
    numleftedges: 1;
    pleftedgevert0: @r_p2;
    pleftedgevert1: @r_p1;
    pleftedgevert2: nil;
    numrightedges: 1;
    prightedgevert0: @r_p2;
    prightedgevert1: @r_p0;
    prightedgevert2: nil),
    (isflattop: 0;
    numleftedges: 1;
    pleftedgevert0: @r_p2;
    pleftedgevert1: @r_p1;
    pleftedgevert2: nil;
    numrightedges: 2;
    prightedgevert0: @r_p2;
    prightedgevert1: @r_p0;
    prightedgevert2: @r_p1),
    (isflattop: 0;
    numleftedges: 2;
    pleftedgevert0: @r_p2;
    pleftedgevert1: @r_p1;
    pleftedgevert2: @r_p0;
    numrightedges: 1;
    prightedgevert0: @r_p2;
    prightedgevert1: @r_p0;
    prightedgevert2: nil),
    (isflattop: 0;
    numleftedges: 1;
    pleftedgevert0: @r_p1;
    pleftedgevert1: @r_p0;
    pleftedgevert2: nil;
    numrightedges: 1;
    prightedgevert0: @r_p1;
    prightedgevert1: @r_p2;
    prightedgevert2: nil),
    (isflattop: 1;
    numleftedges: 1;
    pleftedgevert0: @r_p2;
    pleftedgevert1: @r_p1;
    pleftedgevert2: nil;
    numrightedges: 1;
    prightedgevert0: @r_p0;
    prightedgevert1: @r_p1;
    prightedgevert2: nil),
    (isflattop: 1;
    numleftedges: 1;
    pleftedgevert0: @r_p1;
    pleftedgevert1: @r_p0;
    pleftedgevert2: nil;
    numrightedges: 1;
    prightedgevert0: @r_p2;
    prightedgevert1: @r_p0;
    prightedgevert2: nil),
    (isflattop: 0;
    numleftedges: 1;
    pleftedgevert0: @r_p0;
    pleftedgevert1: @r_p2;
    pleftedgevert2: nil;
    numrightedges: 1;
    prightedgevert0: @r_p0;
    prightedgevert1: @r_p1;
    prightedgevert2: nil)
    );

(*
================
R_PolysetUpdateTables
================
*)

procedure R_PolysetUpdateTables;
var
  i: Integer;
  s: PByte;
begin
  if (r_affinetridesc.skinwidth <> skinwidth) or (r_affinetridesc.pskin <> skinstart) then
  begin
    skinwidth := r_affinetridesc.skinwidth;
    skinstart := r_affinetridesc.pskin;
    s := skinstart;
    for I := 0 to MAX_LBM_HEIGHT - 1 do
    begin
      skintable[i] := s;
      Inc(Integer(s), skinwidth);
    end;
  end;
end;

(*
================
R_DrawTriangle
================
*)

procedure R_DrawTriangle;
var
  spans: array[0..DPS_MAXSPANS - 1] of spanpackage_t;
  dv1_ab: Integer;
  dv0_ac: Integer;
  dv0_ab: Integer;
  dv1_ac: Integer;
begin
  FillChar(spans, SizeOf(spans), 0);
   (*
   d_xdenom = ( aliastriangleparms.a->v[1] - aliastriangleparms.b->v[1] ) * ( aliastriangleparms.a->v[0] - aliastriangleparms.c->v[0] ) -
            ( aliastriangleparms.a->v[0] - aliastriangleparms.b->v[0] ) * ( aliastriangleparms.a->v[1] - aliastriangleparms.c->v[1] );
   *)

   dv0_ab := aliastriangleparms.a^.u - aliastriangleparms.b^.u;
   dv1_ab := aliastriangleparms.a^.v - aliastriangleparms.b^.v;

   if ((dv0_ab or dv1_ab) = 0) then
      Exit;

  dv0_ac := aliastriangleparms.a^.u - aliastriangleparms.c^.u;
  dv1_ac := aliastriangleparms.a^.v - aliastriangleparms.c^.v;

  if ((dv0_ac or dv1_ac) = 0) then
    Exit;

  d_xdenom := (dv0_ac * dv1_ab) - (dv0_ab * dv1_ac);

  if (d_xdenom < 0) then
  begin
    a_spans := @spans;

    r_p0[0] := aliastriangleparms.a^.u; // u
    r_p0[1] := aliastriangleparms.a^.v; // v
    r_p0[2] := aliastriangleparms.a^.s; // s
    r_p0[3] := aliastriangleparms.a^.t; // t
    r_p0[4] := aliastriangleparms.a^.l; // light
    r_p0[5] := aliastriangleparms.a^.zi; // iz

    r_p1[0] := aliastriangleparms.b^.u;
    r_p1[1] := aliastriangleparms.b^.v;
    r_p1[2] := aliastriangleparms.b^.s;
    r_p1[3] := aliastriangleparms.b^.t;
    r_p1[4] := aliastriangleparms.b^.l;
    r_p1[5] := aliastriangleparms.b^.zi;

    r_p2[0] := aliastriangleparms.c^.u;
    r_p2[1] := aliastriangleparms.c^.v;
    r_p2[2] := aliastriangleparms.c^.s;
    r_p2[3] := aliastriangleparms.c^.t;
    r_p2[4] := aliastriangleparms.c^.l;
    r_p2[5] := aliastriangleparms.c^.zi;

    R_PolysetSetEdgeTable;
    R_RasterizeAliasPolySmooth;
  end;
end;

(*
===================
R_PolysetScanLeftEdge_C
====================
*)

procedure R_PolysetScanLeftEdge_C(height: Integer);
begin
  repeat
    d_pedgespanpackage^.pdest := d_pdest;
    d_pedgespanpackage^.pz := d_pz;
    d_pedgespanpackage^.count := d_aspancount;
    d_pedgespanpackage^.ptex := d_ptex;

    d_pedgespanpackage^.sfrac := d_sfrac;
    d_pedgespanpackage^.tfrac := d_tfrac;

 // FIXME: need to clamp l, s, t, at both ends?
    d_pedgespanpackage^.light := d_light;
    d_pedgespanpackage^.zi := d_zi;

    inc(Integer(d_pedgespanpackage), SizeOf(spanpackage_t));

    inc(errorterm, erroradjustup);
    if (errorterm >= 0) then
    begin
      inc(Integer(d_pdest), d_pdestextrastep);
      inc(Integer(d_pz), (d_pzextrastep * SizeOf(SmallInt)));
      inc(d_aspancount, d_countextrastep);
      inc(Integer(d_ptex), d_ptexextrastep);
      inc(d_sfrac, d_sfracextrastep);
      inc(Integer(d_ptex), _SAR(d_sfrac, 16));
//         inc(Integer(d_ptex), d_sfrac shr 16);
         d_sfrac := d_sfrac and $FFFF;
         inc(d_tfrac, d_tfracextrastep);
         if (d_tfrac and $10000) <> 0 then
         begin
            inc(d_ptex, r_affinetridesc.skinwidth);
            d_tfrac := d_tfrac and $FFFF;
         end;
         inc(d_light, d_lightextrastep);
         inc(d_zi, d_ziextrastep);
         dec(errorterm, erroradjustdown);
      end
      else
      begin
         inc(Integer(d_pdest), d_pdestbasestep);
         inc(Integer(d_pz), d_pzbasestep*SizeOf(SmallInt));
         inc(d_aspancount, ubasestep);
         inc(Integer(d_ptex), d_ptexbasestep);
         inc(d_sfrac, d_sfracbasestep);
         inc(Integer(d_ptex), _SAR(d_sfrac, 16));
         d_sfrac := d_sfrac and $FFFF;
         inc(d_tfrac, d_tfracbasestep);
         if (d_tfrac and $10000) <> 0 then
         begin
            inc(Integer(d_ptex), r_affinetridesc.skinwidth);
            d_tfrac := d_tfrac and $FFFF;
         end;
         inc(d_light, d_lightbasestep);
         inc(d_zi, d_zibasestep);
      end;
    dec(height);
  until (height = 0);
end;

(*
===================
FloorDivMod

Returns mathematically correct (floor-based) quotient and remainder for
numer and denom, both of which should contain no fractional part. The
quotient must fit in 32 bits.
FIXME: GET RID OF THIS! (FloorDivMod)
====================
*)

procedure FloorDivMod(numer, denom: Single; quotient, rem: PInteger);
var
  q: Integer;
  r: Integer;
  x: Single;
begin
   if (numer >= 0.0) then
   begin
      x := floor(numer / denom);
      q := Trunc(x);
      r := Trunc(floor(numer - (x * denom)));
   end
   else
   begin
   //
   // perform operations with positive values, and fix mod to make floor-based
   //
      x := floor(-numer / denom);
      q := -Trunc(x);
      r := Trunc(floor(-numer - (x * denom)));
      if (r <> 0) then
      begin
         dec(q);
         r := Trunc(denom - r);
      end;
   end;
   quotient^ := q;
   rem^ := r;
end;

(*
===================
R_PolysetSetUpForLineScan
====================
*)

procedure R_PolysetSetUpForLineScan(startvertu, startvertv, endvertu, endvertv: fixed8_t);
var
  dm, dn: Single;
  tm, tn: Integer;
  ptemp: adivtab_p;
begin
// TODO: implement x86 version

  errorterm := -1;
  tm := endvertu - startvertu;
  tn := endvertv - startvertv;
  if (((tm <= 16) and (tm >= -15)) and ((tn <= 16) and (tn >= -15))) then
  begin
    ptemp := @adivtab[_SAL((tm + 15), 5) + (tn + 15)];
    ubasestep := ptemp^.quotient;
    erroradjustup := ptemp^.remainder;
    erroradjustdown := tn;
  end
  else
  begin
    dm := tm;
    dn := tn;
    FloorDivMod(dm, dn, @ubasestep, @erroradjustup);
    erroradjustdown := Trunc(dn);
  end;
end;

(*
================
R_PolysetCalcGradients
================
*)
//#if id386 && !defined __linux__

{$IFDEF id386}
var
  xstepdenominv: Single;
  ystepdenominv: Single;
  t0: Single;
  t1: Single;
  p01_minus_p21: Single;
  p11_minus_p21: Single;
  p00_minus_p20: Single;
  p10_minus_p20: Single;
  t0_int, t1_int: LongInt;

  fpu_sp24_ceil_cw: LongInt external;
  fpu_ceil_cw: LongInt external;
  fpu_chop_cw: LongInt external;

const
   one           : Single = 1.0;
  negative_one  : Single = -1.0F;

procedure R_PolysetCalcGradients(skinwidth: Integer);
begin
 (*
 p00_minus_p20 = r_p0[0] - r_p2[0];
 p01_minus_p21 = r_p0[1] - r_p2[1];
 p10_minus_p20 = r_p1[0] - r_p2[0];
 p11_minus_p21 = r_p1[1] - r_p2[1];
 *)
  asm
     mov eax, dword ptr [r_p0+0]
     mov ebx, dword ptr [r_p0+4]
     sub eax, dword ptr [r_p2+0]
     sub ebx, dword ptr [r_p2+4]
     mov p00_minus_p20, eax
     mov p01_minus_p21, ebx
     fild dword ptr p00_minus_p20
     fild dword ptr p01_minus_p21
     mov eax, dword ptr [r_p1+0]
     mov ebx, dword ptr [r_p1+4]
     sub eax, dword ptr [r_p2+0]
     sub ebx, dword ptr [r_p2+4]
     fstp p01_minus_p21
     fstp p00_minus_p20
     mov p10_minus_p20, eax
     mov p11_minus_p21, ebx
     fild dword ptr p10_minus_p20
     fild dword ptr p11_minus_p21
     fstp p11_minus_p21
     fstp p10_minus_p20
  end;
 (*
 xstepdenominv = 1.0 / (float)d_xdenom;

 ystepdenominv = -xstepdenominv;
 *)

 (*
 ** put FPU in single precision ceil mode
 *)
  asm
     fldcw word ptr [fpu_sp24_ceil_cw]
//   __asm fldcw word ptr [fpu_ceil_cw]

     fild  dword ptr d_xdenom    //; d_xdenom
     fdivr one                   //; 1 / d_xdenom
     fst   xstepdenominv         //;
     fmul  negative_one          //; -( 1 / d_xdenom )

// ceil () for light so positive steps are exaggerated, negative steps
// diminished,  pushing us away from underflow toward overflow. Underflow is
// very visible, overflow is very unlikely, because of ambient lighting
   (*
   t0 = r_p0[4] - r_p2[4];
   t1 = r_p1[4] - r_p2[4];
   r_lstepx = (int)
         ceil((t1 * p01_minus_p21 - t0 * p11_minus_p21) * xstepdenominv);
   r_lstepy = (int)
         ceil((t1 * p00_minus_p20 - t0 * p10_minus_p20) * ystepdenominv);
   *)
     mov   eax, dword ptr [r_p0+16]
     mov   ebx, dword ptr [r_p1+16]
     sub   eax, dword ptr [r_p2+16]
     sub   ebx, dword ptr [r_p2+16]

     fstp  ystepdenominv       //; (empty)

     mov   t0_int, eax
     mov   t1_int, ebx
     fild  t0_int              //; t0
     fild  t1_int              //; t1 | t0
     fxch  st(1)               //; t0 | t1
     fstp  t0                  //; t1
     fst   t1                  //; t1
     fmul  p01_minus_p21       //; t1 * p01_minus_p21
     fld   t0                  //; t0 | t1 * p01_minus_p21
     fmul  p11_minus_p21       //; t0 * p11_minus_p21 | t1 * p01_minus_p21
     fld   t1                  //; t1 | t0 * p11_minus_p21 | t1 * p01_minus_p21
     fmul  p00_minus_p20       //; t1 * p00_minus_p20 | t0 * p11_minus_p21 | t1 * p01_minus_p21
     fld   t0                  //; t0 | t1 * p00_minus_p20 | t0 * p11_minus_p21 | t1 * p01_minus_p21
     fmul  p10_minus_p20       //; t0 * p10_minus_p20 | t1 * p00_minus_p20 | t0 * p11_minus_p21 | t1 * p01_minus_p21
     fxch  st(2)               //; t0 * p11_minus_p21 | t0 * p10_minus_p20 | t1 * p00_minus_p20 | t1 * p01_minus_p21
     fsubp st(3), st           //; t0 * p10_minus_p20 | t1 * p00_minus_p20 | t1 * p01_minus_p21 - t0 * p11_minus_p21
     fsubrp st(1), st          //; t1 * p00_minus_p20 - t0 * p10_minus_p20 | t1 * p01_minus_p21 - t0 * p11_minus_p21
     fxch  st(1)               //; t1 * p01_minus_p21 - t0 * p11_minus_p21 | t1 * p00_minus_p20 - t0 * p10_minus_p20
     fmul  xstepdenominv       //; r_lstepx | t1 * p00_minus_p20 - t0 * p10_minus_p20
     fxch  st(1)
     fmul  ystepdenominv       //; r_lstepy | r_lstepx
     fxch  st(1)               //; r_lstepx | r_lstepy
     fistp dword ptr [r_lstepx]
     fistp dword ptr [r_lstepy]

   (*
   ** put FPU back into extended precision chop mode
   *)
     fldcw word ptr [fpu_chop_cw]

   (*
   t0 = r_p0[2] - r_p2[2];
   t1 = r_p1[2] - r_p2[2];
   r_sstepx = (int)((t1 * p01_minus_p21 - t0 * p11_minus_p21) *
         xstepdenominv);
   r_sstepy = (int)((t1 * p00_minus_p20 - t0* p10_minus_p20) *
         ystepdenominv);
   *)
     mov eax, dword ptr [r_p0+8]
     mov ebx, dword ptr [r_p1+8]
     sub eax, dword ptr [r_p2+8]
     sub ebx, dword ptr [r_p2+8]
     mov   t0_int, eax
     mov   t1_int, ebx
     fild  t0_int              //; t0
     fild  t1_int              //; t1 | t0
     fxch  st(1)               //; t0 | t1
     fstp  t0                  //; t1
     fst   t1                  //; (empty)

     fmul  p01_minus_p21       //; t1 * p01_minus_p21
     fld   t0                  //; t0 | t1 * p01_minus_p21
     fmul  p11_minus_p21       //; t0 * p11_minus_p21 | t1 * p01_minus_p21
     fld   t1                  //; t1 | t0 * p11_minus_p21 | t1 * p01_minus_p21
     fmul  p00_minus_p20       //; t1 * p00_minus_p20 | t0 * p11_minus_p21 | t1 * p01_minus_p21
     fld   t0                  //; t0 | t1 * p00_minus_p20 | t0 * p11_minus_p21 | t1 * p01_minus_p21
     fmul  p10_minus_p20       //; t0 * p10_minus_p20 | t1 * p00_minus_p20 | t0 * p11_minus_p21 | t1 * p01_minus_p21
     fxch  st(2)               //; t0 * p11_minus_p21 | t0 * p10_minus_p20 | t1 * p00_minus_p20 | t1 * p01_minus_p21
     fsubp st(3), st           //; t0 * p10_minus_p20 | t1 * p00_minus_p20 | t1 * p01_minus_p21 - t0 * p11_minus_p21
     fsubrp st(1), st          // ; t1 * p00_minus_p20 - t0 * p10_minus_p20 | t1 * p01_minus_p21 - t0 * p11_minus_p21
     fxch  st(1)               //; t1 * p01_minus_p21 - t0 * p11_minus_p21 | t1 * p00_minus_p20 - t0 * p10_minus_p20
     fmul  xstepdenominv       //; r_lstepx | t1 * p00_minus_p20 - t0 * p10_minus_p20
     fxch  st(1)
     fmul  ystepdenominv       //; r_lstepy | r_lstepx
     fxch  st(1)               //; r_lstepx | r_lstepy
     fistp dword ptr [r_sstepx]
     fistp dword ptr [r_sstepy]

   (*
   t0 = r_p0[3] - r_p2[3];
   t1 = r_p1[3] - r_p2[3];
   r_tstepx = (int)((t1 * p01_minus_p21 - t0 * p11_minus_p21) *
         xstepdenominv);
   r_tstepy = (int)((t1 * p00_minus_p20 - t0 * p10_minus_p20) *
         ystepdenominv);
   *)
     mov eax, dword ptr [r_p0+12]
     mov ebx, dword ptr [r_p1+12]
     sub eax, dword ptr [r_p2+12]
     sub ebx, dword ptr [r_p2+12]

     mov   t0_int, eax
     mov   t1_int, ebx
     fild  t0_int              //; t0
     fild  t1_int              //; t1 | t0
     fxch  st(1)               //; t0 | t1
     fstp  t0                  //; t1
     fst   t1                  //; (empty)

     fmul  p01_minus_p21       //; t1 * p01_minus_p21
     fld   t0                  //; t0 | t1 * p01_minus_p21
     fmul  p11_minus_p21       //; t0 * p11_minus_p21 | t1 * p01_minus_p21
     fld   t1                  //; t1 | t0 * p11_minus_p21 | t1 * p01_minus_p21
     fmul  p00_minus_p20       //; t1 * p00_minus_p20 | t0 * p11_minus_p21 | t1 * p01_minus_p21
     fld   t0                  //; t0 | t1 * p00_minus_p20 | t0 * p11_minus_p21 | t1 * p01_minus_p21
     fmul  p10_minus_p20       //; t0 * p10_minus_p20 | t1 * p00_minus_p20 | t0 * p11_minus_p21 | t1 * p01_minus_p21
     fxch  st(2)               //; t0 * p11_minus_p21 | t0 * p10_minus_p20 | t1 * p00_minus_p20 | t1 * p01_minus_p21
     fsubp st(3), st           //; t0 * p10_minus_p20 | t1 * p00_minus_p20 | t1 * p01_minus_p21 - t0 * p11_minus_p21
     fsubrp st(1), st          // ; t1 * p00_minus_p20 - t0 * p10_minus_p20 | t1 * p01_minus_p21 - t0 * p11_minus_p21
     fxch  st(1)               //; t1 * p01_minus_p21 - t0 * p11_minus_p21 | t1 * p00_minus_p20 - t0 * p10_minus_p20
     fmul  xstepdenominv       //; r_lstepx | t1 * p00_minus_p20 - t0 * p10_minus_p20
     fxch  st(1)
     fmul  ystepdenominv       //; r_lstepy | r_lstepx
     fxch  st(1)               //; r_lstepx | r_lstepy
     fistp dword ptr [r_tstepx]
     fistp dword ptr [r_tstepy]

   (*
   t0 = r_p0[5] - r_p2[5];
   t1 = r_p1[5] - r_p2[5];
   r_zistepx = (int)((t1 * p01_minus_p21 - t0 * p11_minus_p21) *
         xstepdenominv);
   r_zistepy = (int)((t1 * p00_minus_p20 - t0 * p10_minus_p20) *
         ystepdenominv);
   *)
     mov eax, dword ptr [r_p0+20]
     mov ebx, dword ptr [r_p1+20]
     sub eax, dword ptr [r_p2+20]
     sub ebx, dword ptr [r_p2+20]

     mov   t0_int, eax
     mov   t1_int, ebx
     fild  t0_int              //; t0
     fild  t1_int              //; t1 | t0
     fxch  st(1)               //; t0 | t1
     fstp  t0                  //; t1
     fst   t1                  //; (empty)

     fmul  p01_minus_p21       //; t1 * p01_minus_p21
     fld   t0                  //; t0 | t1 * p01_minus_p21
     fmul  p11_minus_p21       //; t0 * p11_minus_p21 | t1 * p01_minus_p21
     fld   t1                  //; t1 | t0 * p11_minus_p21 | t1 * p01_minus_p21
     fmul  p00_minus_p20       //; t1 * p00_minus_p20 | t0 * p11_minus_p21 | t1 * p01_minus_p21
     fld   t0                  //; t0 | t1 * p00_minus_p20 | t0 * p11_minus_p21 | t1 * p01_minus_p21
     fmul  p10_minus_p20       //; t0 * p10_minus_p20 | t1 * p00_minus_p20 | t0 * p11_minus_p21 | t1 * p01_minus_p21
     fxch  st(2)               //; t0 * p11_minus_p21 | t0 * p10_minus_p20 | t1 * p00_minus_p20 | t1 * p01_minus_p21
     fsubp st(3), st           //; t0 * p10_minus_p20 | t1 * p00_minus_p20 | t1 * p01_minus_p21 - t0 * p11_minus_p21
     fsubrp st(1), st          // ; t1 * p00_minus_p20 - t0 * p10_minus_p20 | t1 * p01_minus_p21 - t0 * p11_minus_p21
     fxch  st(1)               //; t1 * p01_minus_p21 - t0 * p11_minus_p21 | t1 * p00_minus_p20 - t0 * p10_minus_p20
     fmul  xstepdenominv       //; r_lstepx | t1 * p00_minus_p20 - t0 * p10_minus_p20
     fxch  st(1)
     fmul  ystepdenominv       //; r_lstepy | r_lstepx
     fxch  st(1)               //; r_lstepx | r_lstepy
     fistp dword ptr [r_zistepx]
     fistp dword ptr [r_zistepy]

   (*
#if   id386ALIAS
   a_sstepxfrac = r_sstepx << 16;
   a_tstepxfrac = r_tstepx << 16;
#else
   a_sstepxfrac = r_sstepx & 0xFFFF;
   a_tstepxfrac = r_tstepx & 0xFFFF;
#endif
   *)
     mov eax, d_pdrawspans
     cmp eax, offset R_PolysetDrawSpans8_Opaque
     mov eax, r_sstepx
     mov ebx, r_tstepx
     jne @translucent
//#if id386ALIAS
     shl eax, 16
     shl ebx, 16
     jmp @done_with_steps
//#else
@translucent:
     and eax, 0ffffh
     and ebx, 0ffffh
//#endif
@done_with_steps:
     mov a_sstepxfrac, eax
     mov a_tstepxfrac, ebx

   (*
   a_ststepxwhole = skinwidth * (r_tstepx >> 16) + (r_sstepx >> 16);
   *)
     mov ebx, r_tstepx
     mov ecx, r_sstepx
     sar ebx, 16
     mov eax, skinwidth
     mul ebx
     sar ecx, 16
     add eax, ecx
     mov a_ststepxwhole, eax
  end;
end;

{$ELSE}

procedure R_PolysetCalcGradients(skinwidth: Integer);
var
  xstepdenominv: Single;
  ystepdenominv: Single;
  t0, t1: Single;
  p01_minus_p21: Single;
  p11_minus_p21: Single;
  p00_minus_p20: Single;
  p10_minus_p20: Single;
begin
  p00_minus_p20 := r_p0[0] - r_p2[0];
  p01_minus_p21 := r_p0[1] - r_p2[1];
  p10_minus_p20 := r_p1[0] - r_p2[0];
  p11_minus_p21 := r_p1[1] - r_p2[1];

//   xstepdenominv := 1.0 / d_xdenom;
   xstepdenominv := d_xdenom;
   xstepdenominv := 1.0 / xstepdenominv;

  ystepdenominv := -xstepdenominv;

// ceil () for light so positive steps are exaggerated, negative steps
// diminished,  pushing us away from underflow toward overflow. Underflow is
// very visible, overflow is very unlikely, because of ambient lighting
  t0 := r_p0[4] - r_p2[4];
  t1 := r_p1[4] - r_p2[4];
  r_lstepx := ceil((t1 * p01_minus_p21 - t0 * p11_minus_p21) * xstepdenominv);
  r_lstepy := ceil((t1 * p00_minus_p20 - t0 * p10_minus_p20) * ystepdenominv);

  t0 := r_p0[2] - r_p2[2];
  t1 := r_p1[2] - r_p2[2];
  r_sstepx := Trunc(((t1 * p01_minus_p21 - t0 * p11_minus_p21) * xstepdenominv));
  r_sstepy := Trunc(((t1 * p00_minus_p20 - t0 * p10_minus_p20) * ystepdenominv));

  t0 := r_p0[3] - r_p2[3];
  t1 := r_p1[3] - r_p2[3];
  r_tstepx := Trunc(((t1 * p01_minus_p21 - t0 * p11_minus_p21) * xstepdenominv));
  r_tstepy := Trunc(((t1 * p00_minus_p20 - t0 * p10_minus_p20) * ystepdenominv));

  t0 := r_p0[5] - r_p2[5];
  t1 := r_p1[5] - r_p2[5];
  r_zistepx := Trunc(((t1 * p01_minus_p21 - t0 * p11_minus_p21) * xstepdenominv));
  r_zistepy := Trunc(((t1 * p00_minus_p20 - t0 * p10_minus_p20) * ystepdenominv));

{$IFDEF id386}
  if (d_pdrawspans = R_PolysetDrawSpans8_Opaque) then
  begin
    a_sstepxfrac := _SAL(r_sstepx, 16);
    a_tstepxfrac := _SAL(r_tstepx, 16);
  end
  else
{$ENDIF}
  begin
    a_sstepxfrac := r_sstepx and $FFFF;
    a_tstepxfrac := r_tstepx and $FFFF;
  end;

  a_ststepxwhole := skinwidth * _SAR(r_tstepx, 16) + _SAR(r_sstepx, 16);
end;
{$ENDIF}

(*
================
R_PolysetDrawThreshSpans8

Random fizzle fade rasterizer
================
*)

procedure R_PolysetDrawThreshSpans8(pspanpackage: spanpackage_p);
var
  lcount: Integer;
  lpdest: PByte;
  lptex: PByte;
  lsfrac: Integer;
  ltfrac: Integer;
  llight: Integer;
  lzi: Integer;
  lpz: PSmallInt;
begin
  repeat
    lcount := d_aspancount - pspanpackage^.count;

      inc(errorterm, erroradjustup);
      if (errorterm >= 0) then
      begin
         inc(d_aspancount, d_countextrastep);
         dec(errorterm, erroradjustdown);
      end
      else
      begin
         inc(d_aspancount, ubasestep);
      end;

      if (lcount <> 0) then
      begin
         lpdest := pspanpackage^.pdest;
         lptex := pspanpackage^.ptex;
         lpz := pspanpackage^.pz;
         lsfrac := pspanpackage^.sfrac;
         ltfrac := pspanpackage^.tfrac;
         llight := pspanpackage^.light;
         lzi := pspanpackage^.zi;

         repeat
            if (_SAR(lzi, 16) >= lpz^) then
            begin
               rand1k_index := (rand1k_index + 1) and MASK_1K;

               if (rand1k[rand1k_index] <= r_affinetridesc.vis_thresh) then
               begin
                  lpdest^ := PByteArray(vid.colormap)^[lptex^ + (llight and $FF00)];
                  lpz^ := _SAR(lzi, 16);
               end;
            end;

            inc(Integer(lpdest), 1);
            inc(lzi, r_zistepx);
            inc(Integer(lpz), SizeOf(SmallInt));
            inc(llight, r_lstepx);
            inc(Integer(lptex), a_ststepxwhole);
            inc(lsfrac, a_sstepxfrac);
            inc(Integer(lptex), _SAR(lsfrac, 16));
            lsfrac := lsfrac and $FFFF;
            inc(ltfrac, a_tstepxfrac);
            if (ltfrac and $10000) <> 0 then
            begin
               inc(lptex, r_affinetridesc.skinwidth);
               ltfrac := ltfrac and $FFFF;
            end;
        dec(lcount);
      until lcount = 0;
    end;
    inc(Integer(pspanpackage), SizeOf(spanpackage_t));
  until (pspanpackage^.count = -999999);
end;

(*
================
R_PolysetDrawSpans8
================
*)

procedure R_PolysetDrawSpans8_33(pspanpackage: spanpackage_p);
var
  lcount: Integer;
  lpdest: PByte;
  lptex: PByte;
  lsfrac: Integer;
  ltfrac: Integer;
  llight: Integer;
  lzi: Integer;
  lpz: PSmallInt;
  temp: Integer;
begin
  repeat
    lcount := d_aspancount - pspanpackage^.count;

    inc(errorterm, erroradjustup);
    if (errorterm >= 0) then
    begin
      inc(d_aspancount, d_countextrastep);
      dec(errorterm, erroradjustdown);
    end
    else
    begin
      inc(d_aspancount, ubasestep);
    end;

    if (lcount <> 0) then
    begin
      lpdest := pspanpackage^.pdest;
      lptex := pspanpackage^.ptex;
      lpz := pspanpackage^.pz;
      lsfrac := pspanpackage^.sfrac;
      ltfrac := pspanpackage^.tfrac;
      llight := pspanpackage^.light;
      lzi := pspanpackage^.zi;

   //do
      repeat
        if (_SAR(lzi, 16) >= lpz^) then
//            if (lzi shr 16 >= lpz^) then
        begin
          temp := PByteArray(vid.colormap)^[lptex^ + (llight and $FF00)];
          lpdest^ := PByteArray(vid.alphamap)^[temp + lpdest^ * 256];
        end;
        inc(integer(lpdest));
        inc(lzi, r_zistepx);
        inc(Integer(lpz), SizeOf(SmallInt));
        inc(llight, r_lstepx);
        inc(Integer(lptex), a_ststepxwhole);
        inc(lsfrac, a_sstepxfrac);
        inc(lptex, _SAR(lsfrac, 16));
        lsfrac := lsfrac and $FFFF;
        inc(ltfrac, a_tstepxfrac);
        if (ltfrac and $10000) <> 0 then
        begin
          inc(lptex, r_affinetridesc.skinwidth);
          ltfrac := ltfrac and $FFFF;
        end;
        dec(lcount);
      until lcount = 0;
    end;
    inc(Integer(pspanpackage), sizeof(spanpackage_t));
  until pspanpackage^.count = -999999;
end;

procedure R_PolysetDrawSpansConstant8_33(pspanpackage: spanpackage_p);
var
  lcount: Integer;
  lpdest: PByte;
  lzi: Integer;
  lpz: PSmallInt;
begin
  while (pspanpackage^.count <> -999999) do
  begin
    lcount := d_aspancount - pspanpackage^.count;

    Inc(errorterm, erroradjustup);
    if (errorterm >= 0) then
    begin
      Inc(d_aspancount, d_countextrastep);
      Dec(errorterm, erroradjustdown);
    end
    else
    begin
      Inc(d_aspancount, ubasestep);
    end;

    if (lcount <> 0) then
    begin
      lpdest := pspanpackage^.pdest;
      lpz := pspanpackage^.pz;
      lzi := pspanpackage^.zi;

      while (lcount > 0) do
      begin
        if (_SAR(lzi, 16) >= lpz^) then
          lpdest^ := PByte(Integer(vid.alphamap) + (r_aliasblendcolor + lpdest^ * 256))^;
        Inc(Integer(lpdest));
        Inc(lzi, r_zistepx);
        Inc(Integer(lpz), SizeOf(SmallInt));
        Dec(lcount);
      end;
    end;
    Inc(Integer(pspanpackage), sizeof(spanpackage_t));
  end;
end;

procedure R_PolysetDrawSpans8_66(pspanpackage: spanpackage_p);
var
  lcount: Integer;
  lpdest: PByte;
  lptex: PByte;
  lsfrac: Integer;
  ltfrac: Integer;
  llight: Integer;
  lzi: Integer;
  lpz: PSmallInt;
  temp: Integer;
begin
  repeat
    lcount := d_aspancount - pspanpackage^.count;
    inc(errorterm, erroradjustup);
    if (errorterm >= 0) then
    begin
      inc(d_aspancount, d_countextrastep);
      dec(errorterm, erroradjustdown);
    end
    else
    begin
      inc(d_aspancount, ubasestep);
    end;

    if (lcount <> 0) then
    begin
      lpdest := pspanpackage^.pdest;
      lptex := pspanpackage^.ptex;
      lpz := pspanpackage^.pz;
      lsfrac := pspanpackage^.sfrac;
      ltfrac := pspanpackage^.tfrac;
      llight := pspanpackage^.light;
      lzi := pspanpackage^.zi;

      repeat
        if (_SAR(lzi, 16) >= lpz^) then
        begin
          temp := PByteArray(vid.colormap)^[lptex^ + (llight and $FF00)];

          lpdest^ := PByteArray(vid.alphamap)^[temp * 256 + lpdest^];
          lpz^ := _SAR(lzi, 16);
        end;
        inc(lpdest);
        inc(lzi, r_zistepx);
        inc(lpz);
        inc(llight, r_lstepx);
        inc(lptex, a_ststepxwhole);
        inc(lsfrac, a_sstepxfrac);
        inc(lptex, _SAR(lsfrac, 16));
        lsfrac := lsfrac and $FFFF;
        inc(ltfrac, a_tstepxfrac);
        if (ltfrac and $10000) <> 0 then
        begin
          inc(lptex, r_affinetridesc.skinwidth);
          ltfrac := ltfrac and $FFFF;
        end;
        dec(lcount);
      until lcount = 0;
    end;
    inc(Integer(pspanpackage), sizeof(spanpackage_t));
  until pspanpackage^.count = -999999;
end;

procedure R_PolysetDrawSpansConstant8_66(pspanpackage: spanpackage_p);
var
  lcount: Integer;
  lpdest: PByte;
  lzi: Integer;
  lpz: PSmallInt;
begin
  repeat
    lcount := d_aspancount - pspanpackage^.count;

    Inc(errorterm, erroradjustup);
    if (errorterm >= 0) then
    begin
      Inc(d_aspancount, d_countextrastep);
      Dec(errorterm, erroradjustdown);
    end
    else
    begin
      Inc(d_aspancount, ubasestep);
    end;

    if (lcount <> 0) then
    begin
      lpdest := pspanpackage^.pdest;
      lpz := pspanpackage^.pz;
      lzi := pspanpackage^.zi;

      while (lcount > 0) do
      begin
        if (_SAR(lzi, 16) >= lpz^) then
          lpdest^ := PByte(Integer(vid.alphamap) + (r_aliasblendcolor * 256 + lpdest^))^;
        Inc(Integer(lpdest));
        Inc(lzi, r_zistepx);
        Inc(Integer(lpz), SizeOf(SmallInt));
        Dec(lcount);
      end;
    end;
    Inc(Integer(pspanpackage), sizeof(spanpackage_t));
  until (pspanpackage^.count = -999999);
end;

{$IFNDEF id386}

procedure R_PolysetDrawSpans8_Opaque(pspanpackage: spanpackage_p);
var
  lcount: Integer;
  lsfrac: Integer;
  ltfrac: Integer;
  lpdest: PByte;
  lptex: PByte;
  llight: Integer;
  lzi: Integer;
  lpz: PSmallInt;
begin
  repeat
    lcount := d_aspancount - pspanpackage^.count;

    inc(errorterm, erroradjustup);
    if (errorterm >= 0) then
    begin
      inc(d_aspancount, d_countextrastep);
      dec(errorterm, erroradjustdown);
    end
    else
    begin
      inc(d_aspancount, ubasestep);
    end;

    if (lcount > 0) then
    begin
      lpdest := pspanpackage^.pdest;
      lptex := pspanpackage^.ptex;
      lpz := pspanpackage^.pz;
      lsfrac := pspanpackage^.sfrac;
      ltfrac := pspanpackage^.tfrac;
      llight := pspanpackage^.light;
      lzi := pspanpackage^.zi;

      repeat
        if (_SAR(lzi, 16) >= lpz^) then
        begin
//PGM
//try
          if (((r_newrefdef.rdflags and RDF_IRGOGGLES) <> 0) and
            ((currententity^.flags and RF_IR_VISIBLE) <> 0)) then
            lpdest^ := PByteArray(vid.colormap)^[irtable[lptex^]]
          else
            lpdest^ := PByteArray(vid.colormap)^[lptex^ + (llight and $FF00)];
//except
//end;
//PGM
          lpz^ := _SAR(lzi, 16);
        end;
        inc(Integer(lpdest));
        inc(lzi, r_zistepx);
        inc(Integer(lpz), SizeOf(SmallInt));
        inc(llight, r_lstepx);
        inc(Integer(lptex), a_ststepxwhole);
        inc(lsfrac, a_sstepxfrac);
        inc(Integer(lptex), _SAR(lsfrac, 16));
        lsfrac := lsfrac and $FFFF;
        inc(ltfrac, a_tstepxfrac);
        if (ltfrac and $10000) <> 0 then
        begin
          inc(Integer(lptex), r_affinetridesc.skinwidth);
          ltfrac := ltfrac and $FFFF;
        end;
        dec(lcount);
      until lcount = 0;
    end;
    inc(Integer(pspanpackage), sizeof(spanpackage_t));
  until pspanpackage^.count = -999999;
end;
{$ELSE}

procedure R_PolysetDrawSpans8_Opaque(pspanpackage: spanpackage_p);
begin
end;
{$ENDIF}

(*
================
R_PolysetFillSpans8
================
*)

procedure R_PolysetFillSpans8(pspanpackage: spanpackage_p);
var
  color: Integer;
  lcount: Integer;
  lpdest: PByte;
begin
// FIXME: do z buffering
  color := d_aflatcolor;
  inc(d_aflatcolor);
  while (true) do
  begin
    lcount := pspanpackage^.count;
    if (lcount = -1) then
      Exit;
    if (lcount <> 0) then
    begin
      lpdest := pspanpackage^.pdest;
      repeat
        lpdest^ := color;
        inc(integer(lpdest), 1);
        dec(lcount);
      until lcount <= 0;
    end;
    inc(Integer(pspanpackage), sizeof(spanpackage_t));
  end;
end;

(*
================
R_RasterizeAliasPolySmooth
================
*)

procedure R_RasterizeAliasPolySmooth;
var
  initialleftheight: Integer;
  initialrightheight: Integer;
  plefttop: PIntegerArray;
  prighttop: PIntegerArray;
  pleftbottom: PIntegerArray;
  prightbottom: PIntegerArray;
  working_lstepx: Integer;
  originalcount: Integer;
  height: Integer;
  pstart: spanpackage_p;
begin
  plefttop := PIntegerArray(pedgetable^.pleftedgevert0);
  prighttop := PIntegerArray(pedgetable^.prightedgevert0);

  pleftbottom := PIntegerArray(pedgetable^.pleftedgevert1);
  prightbottom := PIntegerArray(pedgetable^.prightedgevert1);

  initialleftheight := pleftbottom^[1] - plefttop^[1];
  initialrightheight := prightbottom^[1] - prighttop^[1];

//
// set the s, t, and light gradients, which are consistent across the triangle
// because being a triangle, things are affine
//
  R_PolysetCalcGradients(r_affinetridesc.skinwidth);
//
// rasterize the polygon
//

//
// scan out the top (and possibly only) part of the left edge
//
  d_pedgespanpackage := a_spans;

  ystart := plefttop^[1];
  d_aspancount := plefttop^[0] - prighttop^[0];

//   d_ptex := @PByteArray(r_affinetridesc.pskin)^[_SAR(plefttop^[2], 16)+_SAR(plefttop^[3], 16)*r_affinetridesc.skinwidth];

   d_ptex := PByte(Integer(r_affinetridesc.pskin) +
                  _SAR(plefttop^[2], 16) +
               _SAR(plefttop^[3], 16) *
                  r_affinetridesc.skinwidth);

//#if   id386ALIAS
{$IFDEF id386}
  if (addr(d_pdrawspans) = addr(R_PolysetDrawSpans8_Opaque)) then
  begin
    d_sfrac := (plefttop^[2] and $FFFF) shl 16;
    d_tfrac := (plefttop^[3] and $FFFF) shl 16;
  end
  else
{$ENDIF}
  begin
    d_sfrac := plefttop^[2] and $FFFF;
    d_tfrac := plefttop^[3] and $FFFF;
  end;
  d_light := plefttop^[4];
  d_zi := plefttop^[5];

  d_pdest := @PByteArray(d_viewbuffer)^[ystart * r_screenwidth + plefttop^[0]];
//   d_pdest := PByte(Integer(d_viewbuffer) + ystart * r_screenwidth + plefttop^[0]);
  d_pz := @PSmallIntArray(d_pzbuffer)^[ystart * Integer(d_zwidth) + plefttop^[0]];
//   d_pz := PSmallInt(Integer(d_pzbuffer) + ((ystart * Integer(d_zwidth) + plefttop^[0])*SizeOf(SmallInt)));

   if (initialleftheight = 1) then
   begin
      d_pedgespanpackage^.pdest := d_pdest;
      d_pedgespanpackage^.pz := d_pz;
      d_pedgespanpackage^.count := d_aspancount;
      d_pedgespanpackage^.ptex := d_ptex;

      d_pedgespanpackage^.sfrac := d_sfrac;
      d_pedgespanpackage^.tfrac := d_tfrac;

   // FIXME: need to clamp l, s, t, at both ends?
      d_pedgespanpackage^.light := d_light;
      d_pedgespanpackage^.zi := d_zi;

      inc(Integer(d_pedgespanpackage), SizeOf(spanpackage_t));
   end
   else
   begin
      R_PolysetSetUpForLineScan(plefttop[0], plefttop[1],
                                     pleftbottom[0], pleftbottom[1]);

{$ifdef id386}
      if (Addr(d_pdrawspans) = Addr(R_PolysetDrawSpans8_Opaque)) then
      begin
         d_pzbasestep := _SAL((Integer(d_zwidth) + ubasestep), 1);
         d_pzextrastep := d_pzbasestep + 2;
      end
      else
{$endif}
      begin
         d_pzbasestep := Integer(d_zwidth) + ubasestep;
         d_pzextrastep := d_pzbasestep + 1;
      end;

      d_pdestbasestep := r_screenwidth + ubasestep;
      d_pdestextrastep := d_pdestbasestep + 1;

   // TODO: can reuse partial expressions here

   // for negative steps in x along left edge, bias toward overflow rather than
   // underflow (sort of turning the floor () we did in the gradient calcs into
   // ceil (), but plus a little bit)
      if (ubasestep < 0) then
         working_lstepx := r_lstepx - 1
      else
         working_lstepx := r_lstepx;

      d_countextrastep := ubasestep + 1;

      d_ptexbasestep := _SAR((r_sstepy + r_sstepx * ubasestep), 16) +
                          _SAR((r_tstepy + r_tstepx * ubasestep), 16) *
                          r_affinetridesc.skinwidth;

{$ifdef id386}
      if (Addr(d_pdrawspans) = Addr(R_PolysetDrawSpans8_Opaque)) then
      begin
         d_sfracbasestep := _SAR((r_sstepy + r_sstepx * ubasestep), 16);
         d_tfracbasestep := _SAR((r_tstepy + r_tstepx * ubasestep), 16);
      end
      else
{$endif}
      begin
         d_sfracbasestep := (r_sstepy + r_sstepx * ubasestep) and $FFFF;
         d_tfracbasestep := (r_tstepy + r_tstepx * ubasestep) and $FFFF;
      end;
      d_lightbasestep := (r_lstepy + working_lstepx) * ubasestep;
      d_zibasestep := (r_zistepy + r_zistepx) * ubasestep;

      d_ptexextrastep :=  _SAR((r_sstepy + r_sstepx * d_countextrastep), 16) +
                            _SAR((r_tstepy + r_tstepx * d_countextrastep), 16) *
                            r_affinetridesc.skinwidth;

{$ifdef id386}
      if (Addr(d_pdrawspans) = Addr(R_PolysetDrawSpans8_Opaque)) then
      begin
         d_sfracextrastep := _SAL((r_sstepy + r_sstepx*d_countextrastep), 16);
         d_tfracextrastep := _SAL((r_tstepy + r_tstepx*d_countextrastep), 16);
      end
      else
{$endif}
      begin
         d_sfracextrastep := (r_sstepy + r_sstepx*d_countextrastep) and $FFFF;
         d_tfracextrastep := (r_tstepy + r_tstepx*d_countextrastep) and $FFFF;
      end;
      d_lightextrastep := d_lightbasestep + working_lstepx;
      d_ziextrastep := d_zibasestep + r_zistepx;

{$ifdef id386}
      if (Addr(d_pdrawspans) = Addr(R_PolysetDrawSpans8_Opaque)) then
      begin
         R_PolysetScanLeftEdge(initialleftheight);
      end
      else
{$endif}
      begin
         R_PolysetScanLeftEdge_C(initialleftheight);
      end;
   end;

//
// scan out the bottom part of the left edge, if it exists
//
  if (pedgetable^.numleftedges = 2) then
  begin
    plefttop := pleftbottom;
    pleftbottom := PIntegerArray(pedgetable^.pleftedgevert2);

    height := pleftbottom^[1] - plefttop^[1];

// TODO: make this a function; modularize this function in general

    ystart := plefttop^[1];
    d_aspancount := plefttop^[0] - prighttop^[0];
    d_ptex := @PByteArray(r_affinetridesc.pskin)^[_SAR(plefttop^[2], 16) +
      _SAR(plefttop^[3], 16) *
      r_affinetridesc.skinwidth];
(*
  d_ptex := PByte(Integer(r_affinetridesc.pskin) + _SAR(plefttop^[2],16) +
                _SAR(plefttop^[3], 16) * r_affinetridesc.skinwidth);
*)
    d_sfrac := 0;
    d_tfrac := 0;
    d_light := plefttop^[4];
    d_zi := plefttop^[5];

    d_pdest := @PByteArray(d_viewbuffer)^[ystart * r_screenwidth + plefttop^[0]];
(*
  d_pdest := PByte(Integer(d_viewbuffer) + ystart * r_screenwidth + plefttop^[0]);
*)
    d_pz := @PSmallIntArray(d_pzbuffer)^[ystart * Integer(d_zwidth) + plefttop^[0]];
(*
  d_pz := PSmallInt(Integer(d_pzbuffer) + ystart * Integer(d_zwidth) + plefttop^[0]);
*)

    if (height = 1) then
    begin
      d_pedgespanpackage^.pdest := d_pdest;
      d_pedgespanpackage^.pz := d_pz;
      d_pedgespanpackage^.count := d_aspancount;
      d_pedgespanpackage^.ptex := d_ptex;

      d_pedgespanpackage^.sfrac := d_sfrac;
      d_pedgespanpackage^.tfrac := d_tfrac;

  // FIXME: need to clamp l, s, t, at both ends?
      d_pedgespanpackage^.light := d_light;
      d_pedgespanpackage^.zi := d_zi;

      inc(Integer(d_pedgespanpackage), SizeOf(spanpackage_t));
    end
    else
    begin
      R_PolysetSetUpForLineScan(plefttop^[0], plefttop^[1],
        pleftbottom^[0], pleftbottom^[1]);

      d_pdestbasestep := r_screenwidth + ubasestep;
      d_pdestextrastep := d_pdestbasestep + 1;

{$IFDEF id386}
      if (Addr(d_pdrawspans) = Addr(R_PolysetDrawSpans8_Opaque)) then
      begin
        d_pzbasestep := _SAL((Integer(d_zwidth) + ubasestep), 1);
        d_pzextrastep := d_pzbasestep + 2;
      end
      else
{$ENDIF}
      begin
        d_pzbasestep := Integer(d_zwidth) + ubasestep;
        d_pzextrastep := d_pzbasestep + 1;
      end;

      if (ubasestep < 0) then
        working_lstepx := r_lstepx - 1
      else
        working_lstepx := r_lstepx;

      d_countextrastep := ubasestep + 1;
      d_ptexbasestep := _SAR((r_sstepy + r_sstepx * ubasestep), 16) +
        _SAR((r_tstepy + r_tstepx * ubasestep), 16) *
        r_affinetridesc.skinwidth;

{$IFDEF id386}
      if (Addr(d_pdrawspans) = Addr(R_PolysetDrawSpans8_Opaque)) then
      begin
        d_sfracbasestep := _SAL((r_sstepy + r_sstepx * ubasestep), 16);
        d_tfracbasestep := _SAL((r_tstepy + r_tstepx * ubasestep), 16);
      end
      else
{$ENDIF}
      begin
        d_sfracbasestep := (r_sstepy + r_sstepx * ubasestep) and $FFFF;
        d_tfracbasestep := (r_tstepy + r_tstepx * ubasestep) and $FFFF;
      end;
      d_lightbasestep := r_lstepy + working_lstepx * ubasestep;
      d_zibasestep := r_zistepy + r_zistepx * ubasestep;

      d_ptexextrastep := _SAR((r_sstepy + r_sstepx * d_countextrastep), 16) +
        _SAR((r_tstepy + r_tstepx * d_countextrastep), 16) *
        r_affinetridesc.skinwidth;

{$IFDEF id386}
      if (Addr(d_pdrawspans) = Addr(R_PolysetDrawSpans8_Opaque)) then
      begin
        d_sfracextrastep := _SAL(((r_sstepy + r_sstepx * d_countextrastep) and $FFFF), 16);
        d_tfracextrastep := _SAL(((r_tstepy + r_tstepx * d_countextrastep) and $FFFF), 16);
      end
      else
{$ENDIF}
      begin
        d_sfracextrastep := (r_sstepy + r_sstepx * d_countextrastep) and $FFFF;
        d_tfracextrastep := (r_tstepy + r_tstepx * d_countextrastep) and $FFFF;
      end;
      d_lightextrastep := d_lightbasestep + working_lstepx;
      d_ziextrastep := d_zibasestep + r_zistepx;

{$IFDEF id386}
      if (Addr(d_pdrawspans) = Addr(R_PolysetDrawSpans8_Opaque)) then
      begin
        R_PolysetScanLeftEdge(height);
      end
      else
{$ENDIF}
      begin
        R_PolysetScanLeftEdge_C(height);
      end;
    end;
  end;

// scan out the top (and possibly only) part of the right edge, updating the
// count field
  d_pedgespanpackage := a_spans;

  R_PolysetSetUpForLineScan(prighttop^[0], prighttop^[1],
    prightbottom^[0], prightbottom^[1]);
  d_aspancount := 0;
  d_countextrastep := ubasestep + 1;
  originalcount := spanpackage_array_p(a_spans)^[initialrightheight].count;
  spanpackage_array_p(a_spans)^[initialrightheight].count := -999999; // mark end of the spanpackages
  d_pdrawspans(a_spans);

// scan out the bottom part of the right edge, if it exists
  if (pedgetable^.numrightedges = 2) then
  begin
    pstart := @spanpackage_array_p(a_spans)^[initialrightheight];
    pstart^.count := originalcount;

    d_aspancount := prightbottom^[0] - prighttop^[0];

    prighttop := prightbottom;
    prightbottom := PIntegerArray(pedgetable^.prightedgevert2);

    height := prightbottom^[1] - prighttop^[1];

    R_PolysetSetUpForLineScan(prighttop^[0], prighttop^[1],
      prightbottom^[0], prightbottom^[1]);

    d_countextrastep := ubasestep + 1;
    spanpackage_array_p(a_spans)^[initialrightheight + height].count := -999999;
           // mark end of the spanpackages
    d_pdrawspans(pstart);
  end;
end;

(*
================
R_PolysetSetEdgeTable
================
*)

procedure R_PolysetSetEdgeTable;
var
  edgetableindex: Integer;
begin
  edgetableindex := 0; // assume the vertices are already in
                  //  top to bottom order

//
// determine which edges are right & left, and the order in which
// to rasterize them
//
  if (r_p0[1] >= r_p1[1]) then
  begin
    if (r_p0[1] = r_p1[1]) then
    begin
      if (r_p0[1] < r_p2[1]) then
        pedgetable := @edgetables[2]
      else
        pedgetable := @edgetables[5];
      exit;
    end
    else
    begin
      edgetableindex := 1;
    end;
  end;

  if (r_p0[1] = r_p2[1]) then
  begin
    if (edgetableindex <> 0) then
      pedgetable := @edgetables[8]
    else
      pedgetable := @edgetables[9];
    Exit;
  end
  else
    if (r_p1[1] = r_p2[1]) then
    begin
      if (edgetableindex <> 0) then
        pedgetable := @edgetables[10]
      else
        pedgetable := @edgetables[11];
      Exit;
    end;

  if (r_p0[1] > r_p2[1]) then
    inc(edgetableindex, 2);

  if (r_p1[1] > r_p2[1]) then
    inc(edgetableindex, 4);

  pedgetable := @edgetables[edgetableindex];
end;

{$IFNDEF id386}

procedure R_PolysetScanLeftEdge(height: Integer);
begin
end;
{$ENDIF}

initialization
  FillChar(r_p0, SizeOf(r_p0), 0);
  FillChar(r_p1, SizeOf(r_p1), 0);
  FillChar(r_p2, SizeOf(r_p2), 0);

end.
