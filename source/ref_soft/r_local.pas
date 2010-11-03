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

//100%
{$ALIGN 8}{$MINENUMSIZE 4}
{----------------------------------------------------------------------------}
{                                                                            }
{ File(s): r_local.h                                                         }
{                                                                            }
{ Initial conversion by : Clairebear (clairebear69@ntlworld.com)             }
{ Initial conversion on : 10-Jan-2002                                        }
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
{ Updated on : 25-Feb-2002                                                   }
{ Updated by : Carl Kenner (carl_kenner@hotmail.com)                         }
{                                                                            }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{ none                                                                       }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{ work out what to do with those externs                                     }
{----------------------------------------------------------------------------}

unit r_local;

// There's no C file to go with this header.
// All "extern" variables and functions have been commented out and are
// highlighted with my initials.
// Records not defined as Packed (deliberately!)
// Added uses for types not defined in this unit.
// All original comments retained. Added initials to any comments of mine
// Some types are defined in both r_model and gl_model. I tried to find out
// which one I should include, but no indication. Probs can be found in make
// file.
// CAK - You should include r_model, which I have done below
// the two engines are not supposed to be mixed

interface

uses
  Windows, // CAK - needed for Delphi 3
  q_shared,
  qfiles, // CHANGED FROM Q_FILES BY CARL KENNER (CAK)
  r_model,
  ref;

const
  REF_VERSION = 'SOFT 0.01';

// up / down
const
  PITCH = 0;

// left / right
const
  YAW = 1;

// fall over
const
  ROLL = 2;

/////////// CAK - MOVED TO r_model.h
(*

  skins will be outline flood filled and mip mapped
  pics and sprites with alpha will be outline flood filled
  pic won't be mip mapped

  model skin
  sprite frame
  wall texture
  pic

*)

type
  vec5_arr = array[0..MaxInt div SizeOf(vec5_t) - 1] of vec5_t;
  vec5_arrp = ^vec5_arr;

  lightstyle_arr = array[0..MaxInt div SizeOf(lightstyle_t) - 1] of lightstyle_t;
  lightstyle_arrp = ^lightstyle_arr;

  dlight_arr = array[0..MaxInt div SizeOf(dlight_t) - 1] of dlight_t;
  dlight_arrp = ^dlight_arr;

  dmdl_arr = array[0..MaxInt div SizeOf(dmdl_t) - 1] of dmdl_t;
  dmdl_arrp = ^dmdl_arr;

type
  imagetype_p = r_model.imagetype_p;
  imagetype_t = r_model.imagetype_t;

  image_p = r_model.image_p;
  image_t = r_model.image_t;

//===================================================================
  pixel_t = Byte;
  pixel_p = PByte;

  vrect_p = ^vrect_t;
  vrect_t = record
    x, y, width, height: Integer;
    pnext: vrect_p;
  end;

  viddef_p = ^viddef_t;
  viddef_t = record
    buffer: pixel_p; // invisible buffer
    colormap: pixel_p; // 256 * VID_GRADES size
    alphamap: pixel_p; // 256 * 256 translucency map
    rowbytes: integer; // may be > width if displayed in a window
         // can be negative for stupid dibs
    width: integer;
    height: integer;
  end;

  rserr_p = ^rserr_t;
  rserr_t = (
    rserr_ok,
    rserr_invalid_fullscreen,
    rserr_invalid_mode,
    rserr_unknown
    );

// !!! if this is changed, it must be changed in asm_draw.h too !!!
type
  oldrefdef_p = ^oldrefdef_t;
  oldrefdef_t = record
    vrect: vrect_t; // subwindow in video for refresh
                    // FIXME: not need vrect next field here?
    aliasvrect: vrect_t; // scaled Alias version
    vrectright, vrectbottom: integer; // right & bottom screen coords
    aliasvrectright, aliasvrectbottom: integer; // scaled Alias versions
    vrectrightedge: Single; // rightmost right edge we care about,
       // for use in edge list
    fvrectx, fvrecty: single; // for floating-point compares
    fvrectx_adj, fvrecty_adj: single; // left and top edges, for clamping
    vrect_x_adj_shift20: integer; // (vrect.x + 0.5 - epsilon) << 20
    vrectright_adj_shift20: integer; // (vrectright + 0.5 - epsilon) << 20
    fvrectright_adj, fvrectbottom_adj: single;
                                 // right and bottom edges, for clamping
    fvrectright: single; // rightmost edge, for Alias clamping
    fvrectbottom: single; // bottommost edge, for Alias clamping
    horizontalFieldOfView: single; // at Z = 1.0, this many X is visible
                                    // 2.0 = 90 degrees
    xOrigin: single; // should probably always be 0.5
    yOrigin: single; // between be around 0.3 to 0.5

    vieworg: vec3_t;
    viewangles: vec3_t;

    ambientlight: integer;
  end;

const
  CACHE_SIZE = 32;

(*
====================================================

  CONSTANTS

====================================================
*)

const
  VID_CBITS = 6;
const
  VID_GRADES = (1 shl VID_CBITS);

// r_shared.h: general refresh-related stuff shared between the refresh and the
// driver

const
  MAXVERTS = 64; // max points in a surface polygon
const
  MAXWORKINGVERTS = (MAXVERTS + 4); // max points in an intermediate
           //  polygon (while processing)
// !!! if this is changed, it must be changed in d_ifacea.h too !!!
const
  MAXHEIGHT = 1200;
const
  MAXWIDTH = 1600;

const
  INFINITE_DISTANCE = $10000; // distance that's always guaranteed to
                                  //  be farther away than anything in
                                  //  the scene

// d_iface.h: interface header file for rasterization driver modules

const
  WARP_WIDTH = 320;
const
  WARP_HEIGHT = 240;

const
  MAX_LBM_HEIGHT = 480;

const
  PARTICLE_Z_CLIP = 8.0;

// !!! must be kept the same as in quakeasm.h !!!
const
  TRANSPARENT_COLOR = $FF;

// !!! if this is changed, it must be changed in d_ifacea.h too !!!
const
  TURB_TEX_SIZE = 64; // base turbulent texture size

// !!! if this is changed, it must be changed in d_ifacea.h too !!!
const
  CYCLE = 128; // turbulent cycle size

const
  SCANBUFFERPAD = $1000;

const
  DS_SPAN_LIST_END = -128;

const
  NUMSTACKEDGES = 2000;
const
  MINEDGES = NUMSTACKEDGES;
const
  NUMSTACKSURFACES = 1000;
const
  MINSURFACES = NUMSTACKSURFACES;
const
  MAXSPANS = 3000;

// flags in finalvert_t.flags
const
  ALIAS_LEFT_CLIP = $0001;
const
  ALIAS_TOP_CLIP = $0002;
const
  ALIAS_RIGHT_CLIP = $0004;
const
  ALIAS_BOTTOM_CLIP = $0008;
const
  ALIAS_Z_CLIP = $0010;
const
  ALIAS_XY_CLIP_MASK = $000F;

const
  SURFCACHE_SIZE_AT_320X240 = 1024 * 768;

const
  BMODEL_FULLY_CLIPPED = $10; // value returned by R_BmodelCheckBBox ()
                                  //  if bbox is trivially rejected

const
  XCENTERING = (1.0 / 2.0);
const
  YCENTERING = (1.0 / 2.0);

const
  CLIP_EPSILON = 0.001;

const
  BACKFACE_EPSILON = 0.01;

// !!! if this is changed, it must be changed in asm_draw.h too !!!
const
  NEAR_CLIP = 0.01;

const
  MAXALIASVERTS = 2000; // TODO: tune this
const
  ALIAS_Z_CLIP_PLANE = 4;

// turbulence stuff

const
  AMP = 8 * $10000;
const
  AMP2 = 3;
const
  SPEED = 20;

(*
====================================================

TYPES

====================================================
*)

type
  emitpoint_p = ^emitpoint_t;
  emitpoint_t = record
    u, v: Single;
    s, t: Single;
    zi: single;
  end;
  emitpoint_arr = array[0..MaxInt div SizeOf(emitpoint_t) - 1] of emitpoint_t;
  emitpoint_arrp = ^emitpoint_arr;
(*
** if you change this structure be sure to change the #defines
** listed after it!
*)
{$UNDEF SMALL_FINALVERT} // cnh 08/jan/2002, used undef here, cos no equiv of c code

{$IFDEF SMALL_FINALVERT}

type
  finalvert_p = ^finalvert_t;
  finalvert_t = record
    u, v, s, t: smallint;
    l: integer;
    zi: integer;
    flags: integer;
    xyz: array[0..2] of single; // eye space
  end;

const
  FINALVERT_V0 = 0;
const
  FINALVERT_V1 = 2;
const
  FINALVERT_V2 = 4;
const
  FINALVERT_V3 = 6;
const
  FINALVERT_V4 = 8;
const
  FINALVERT_V5 = 12;
const
  FINALVERT_FLAGS = 16;
const
  FINALVERT_X = 20;
const
  FINALVERT_Y = 24;
const
  FINALVERT_Z = 28;
const
  FINALVERT_SIZE = 32;

{$ELSE}

type
  finalvert_p = ^finalvert_t;
  finalvert_t = record
    u, v, s, t: integer;
    l: integer;
    zi: integer;
    flags: integer;
    xyz: array[0..2] of single; // eye space
  end;
  finalvert_arr = array[0..MaxInt div SizeOf(finalvert_t) - 1] of finalvert_t;
  finalvert_arrp = ^finalvert_arr;

const
  FINALVERT_V0 = 0;
const
  FINALVERT_V1 = 4;
const
  FINALVERT_V2 = 8;
const
  FINALVERT_V3 = 12;
const
  FINALVERT_V4 = 16;
const
  FINALVERT_V5 = 20;
const
  FINALVERT_FLAGS = 24;
const
  FINALVERT_X = 28;
const
  FINALVERT_Y = 32;
const
  FINALVERT_Z = 36;
const
  FINALVERT_SIZE = 40;

{$ENDIF}

type
  affinetridesc_p = ^affinetridesc_t;
  affinetridesc_t = record
    pskin: pointer;
    pskindesc: integer;
    skinwidth: integer;
    skinheight: integer;
    ptriangles: dtriangle_p;
    pfinalverts: finalvert_p;
    numtriangles: integer;
    drawtype: integer;
    seamfixupX16: integer;
    do_vis_thresh: qboolean;
    vis_thresh: integer;
  end;

  drawsurf_p = ^drawsurf_t;
  drawsurf_t = record
    surfdat: pByte; // destination for generated surface
    rowbytes: integer; // destination logical width in bytes
    surf: msurface_p; // description for surface to generate
    lightadj: array[0..MAXLIGHTMAPS - 1] of fixed8_t;
                     // adjust for lightmap levels for dynamic lighting
    image: image_p;
    surfmip: integer; // mipmapped ratio of surface texels / world pixels
    surfwidth: integer; // in mipmapped texels
    surfheight: integer; // in mipmapped texels
  end;

  alight_p = ^alight_t;
  alight_t = record
    ambientlight: integer;
    shadelight: integer;
    plightvec: pSingle;
  end;

// clipped bmodel edges
  bedge_p = ^bedge_t;
  bedge_t = record
    v: array[0..1] of mvertex_p;
    pnext: bedge_p;
  end;
  TBedge_tArray = array[0..MaxInt div SizeOf(bedge_t) - 1] of bedge_t;
  PBedge_tArray = ^TBedge_tArray;

// !!! if this is changed, it must be changed in asm_draw.h too !!!
  clipplane_p = ^clipplane_t;
  clipplane_t = record
    normal: vec3_t;
    dist: single;
    next: clipplane_p;
    leftedge: byte;
    rightedge: byte;
    reserved: array[0..1] of byte;
  end;

// !!! if this is changed, it must be changed in asm_draw.h too !!!
  espan_p = ^espan_t;
  espan_t = record
    u, v, count: integer;
    pNext: espan_p;
  end;
  TEspan_tArray = array[0..MaxInt div SizeOf(espan_t) - 1] of espan_t;
  PEspan_tArray = ^TEspan_tArray;

// used by the polygon drawer (R_POLY.C) and sprite setup code (R_SPRITE.C)
  polydesc_p = ^polydesc_t;
  polydesc_t = record
    nump: integer;
    pverts: emitpoint_p;
    pixels: PByte; // image
    pixel_width: integer; // image width
    pixel_height: integer; // image height
    vup, vright, vpn: vec3_t; // in worldspace, for plane eq
    dist: single;
    s_offset: single;
    t_offset: single;
    viewer_position: array[0..2] of single;
    drawspanlet: procedure; cdecl;
    stipple_parity: integer;
  end;

// FIXME: compress, make a union if that will help
// insubmodel is only 1, flags is fewer than 32, spanstate could be a byte
  surf_p = ^surf_t;
  surf_t = record
    next: surf_p; // active surface stack in r_edge.c
    prev: surf_p; // used in r_edge.c for active surf stack
    spans: espan_p; // pointer to linked list of spans to draw
    key: integer; // sorting key (BSP order)
    last_u: integer; // set during tracing
    spanstate: integer; // 0 = not in span
                                       // 1 = in span
                                       // -1 = in inverted span (end before
                                       //  start)
    flags: integer; // currentface flags
    msurf: msurface_p;
    entity: entity_p;
    nearzi: single; // nearest 1/z on surface, for mipmapping
    insubmodel: Boolean;
    d_ziorigin: single;
    d_zistepu: single;
    d_zistepv: single;

    pad: array[0..1] of integer; // to 64 bytes
  end;
  TSurf_tArray = array[0..MaxInt div SizeOf(surf_t) - 1] of surf_t;
  PSurf_tArray = ^TSurf_tArray;

// !!! if this is changed, it must be changed in asm_draw.h too !!!
  edge_p = ^edge_t;
  edge_t = record
    u: fixed16_t;
    u_step: fixed16_t;
    prev: edge_p;
    next: edge_p;
    surfs: array[0..1] of Word;
    nextremove: edge_p;
    nearzi: single;
    owner: medge_p;
  end;
  TEdge_tArray = array[0..MaxInt div SizeOf(edge_t) - 1] of edge_t;
  PEdge_tArray = ^TEdge_tArray;

  aliastriangleparms_p = ^aliastriangleparms_t;
  paliastriangleparms_t = aliastriangleparms_p;
  aliastriangleparms_t = record
    a, b, c: finalvert_p;
  end;
  TAliasTriangleParms = aliastriangleparms_t;
  PAliasTriangleParms = aliastriangleparms_p;

  swstate_p = ^swstate_t;
  swstate_t = record
    fullscreen: boolean;
    prev_mode: integer; // last valid SW mode

    gammatable: array[0..255] of byte;
    currentpalette: array[0..1023] of byte;
  end;

implementation

uses
  r_main, // to gain access to the ri variable.
  SysUtils; //For Exception Handling Only (Assertions)

procedure ri_Sys_Error(err_level: Integer; Fmt: string; const Args: array of const);
var
  Buffer: array[0..9999] of Char;
begin
  Com_Sprintf(Buffer, sizeof(Buffer), PChar(Fmt), Args);
  ri.Sys_Error(err_level, Buffer);
end;

initialization
// Check the size of types defined in r_local.h
  Assert(sizeof(imagetype_t) = 4);
  Assert(sizeof(image_t) = 100);
  Assert(sizeof(pixel_t) = 1);
  Assert(sizeof(vrect_t) = 20);
  Assert(sizeof(viddef_t) = 24);
  Assert(sizeof(rserr_t) = 4);
  Assert(sizeof(oldrefdef_t) = 140);
  Assert(sizeof(emitpoint_t) = 20);
  Assert(sizeof(finalvert_t) = 40);
  Assert(sizeof(affinetridesc_t) = 44);
  Assert(sizeof(drawsurf_t) = 44);
  Assert(sizeof(alight_t) = 12);
  Assert(sizeof(bedge_t) = 12);
  Assert(sizeof(clipplane_t) = 24);
  Assert(sizeof(surfcache_t) = 52);
  Assert(sizeof(espan_t) = 16);
  Assert(sizeof(polydesc_t) = 88);
  Assert(sizeof(surf_t) = 64);
  Assert(sizeof(edge_t) = 32);
  Assert(sizeof(aliastriangleparms_t) = 12);
  Assert(sizeof(swstate_t) = 1288);
end.
