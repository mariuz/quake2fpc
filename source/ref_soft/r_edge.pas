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

unit r_edge;
{$ALIGN 8}{$MINENUMSIZE 4}
{----------------------------------------------------------------------------}
{                                                                            }
{ File(s): r_edge.c                                                          }
{                                                                            }
{ Initial conversion by : CodeFusion (michael@skovslund.dk)                  }
{ Initial conversion on : 8-July-2002                                        }
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
{ r_bsp_c.pas                                                                }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{ Functions has been commented out, so the source will compile.              }
{ What needs to be done is to get the vector math working.                   }
{----------------------------------------------------------------------------}

interface

uses
  r_local,
//  r_main,  // uncomment when r_main is done
//  cvar,
  r_model;

(*
the complex cases add new polys on most lines, so dont optimize for keeping them the same
have multiple free span lists to try to get better coherence?
low depth complexity -- 1 to 3 or so

have a sentinal at both ends?
*)

type
  surf_t_array = array[0..2048] of surf_t;
  surf_p_array = ^surf_t_array;

type
  tdrawfunc = procedure;

// FIXME: should go away
//procedure R_RotateBmodel; external;
//procedure R_TransformFrustum; external;

procedure R_GenerateSpans;
procedure R_GenerateSpansBackward;

procedure R_LeadingEdge(edge: edge_p);
procedure R_LeadingEdgeBackwards(edge: edge_p);
procedure R_TrailingEdge(surf: surf_p; edge: edge_p);

procedure R_BeginEdgeFrame;
procedure R_ScanEdges;

var
  r_currentkey: Integer;

  edge_p_: edge_p;
  r_edges: edge_p;
  edge_max: edge_p;

  surface_p: surf_p;
  surf_max: surf_p;

  newedges: array[0..MAXHEIGHT - 1] of edge_p;
  removeedges: array[0..MAXHEIGHT - 1] of edge_p;
  auxedges: edge_p;

  errorterm: Integer;
  erroradjustup: Integer;
  erroradjustdown: Integer;
  ubasestep: Integer;
  scale_for_mip: Single;

implementation

uses
//  r_alias_c,
  DelphiTypes,
  SysUtils,
  r_surf,
  r_misc,
  r_main,
  q_shared,
  r_scan,
  r_bsp_c,
  r_edgea;

var
// surfaces are generated in back to front order by the bsp, so if a surf
// pointer is greater than another one, it should be drawn in front
// surfaces[1] is the background, and is used as the active surface stack
  max_span_p: espan_p;
  pdrawfunc: tdrawfunc; // static
  edge_sentinel: edge_t;
  miplevel: Integer; // static

procedure D_DrawSurfaces; forward;

{$IFNDEF id386}

procedure R_SurfacePatch;
begin
end;

procedure R_EdgeCodeStart;
begin
end;

procedure R_EdgeCodeEnd;
begin
end;
{$ENDIF}

(*
===============================================================================

EDGE SCANNING

===============================================================================
*)

(*
==============
R_BeginEdgeFrame
==============
*)

procedure R_BeginEdgeFrame;
var
  v: Integer;
  lSurf: surf_p;
begin
  edge_p_ := r_edges;
  edge_max := @PEdge_tArray(r_edges)^[r_numallocatededges];
//   edge_max := edge_p(Integer(r_edges)+(r_numallocatededges*SizeOf(edge_t)));

  surface_p := @PSurf_tArray(surfaces)^[2]; // background is surface 1,
                    //  surface 0 is a dummy
  lSurf := @PSurf_tArray(surfaces)^[1];
  lSurf^.spans := nil; // no background spans yet
  lSurf^.flags := SURF_DRAWBACKGROUND;

// put the background behind everything in the world
  if (sw_draworder^.value <> 0) then
  begin
    pdrawfunc := R_GenerateSpansBackward;
    lSurf^.key := 0;
    r_currentkey := 1;
  end
  else
  begin
    pdrawfunc := R_GenerateSpans;
    lSurf^.key := $7FFFFFFF;
    r_currentkey := 0;
  end;

// FIXME: set with memset
  for v := r_refdef.vrect.y to r_refdef.vrectbottom - 1 do
  begin
    newedges[v] := nil;
    removeedges[v] := nil;
  end;
end;

{$IFNDEF   id386}
(*
==============
R_InsertNewEdges

Adds the edges in the linked list edgestoadd, adding them to the edges in the
linked list edgelist.  edgestoadd is assumed to be sorted on u, and non-empty (
this is actually newedges[v]).  edgelist is assumed to be sorted on u, with a
sentinel at the end (actually, this is the active edge table starting at
edge_head.next).
==============
*)

procedure R_InsertNewEdges(edgestoadd: edge_p; edgelist: edge_p);
label
  edgesearch;
label
  addedge;
var
  next_edge: edge_p;
begin
  repeat
    next_edge := edgestoadd^.next;
    edgesearch:
    if (edgelist^.u >= edgestoadd^.u) then
      goto addedge;
    edgelist := edgelist^.next;
    if (edgelist^.u >= edgestoadd^.u) then
      goto addedge;
    edgelist := edgelist^.next;
    if (edgelist^.u >= edgestoadd^.u) then
      goto addedge;
    edgelist := edgelist^.next;
    if (edgelist^.u >= edgestoadd^.u) then
      goto addedge;
    edgelist := edgelist^.next;
    goto edgesearch;

 // insert edgestoadd before edgelist
    addedge:
    edgestoadd^.next := edgelist;
    edgestoadd^.prev := edgelist^.prev;
    edgelist^.prev^.next := edgestoadd;
    edgelist^.prev := edgestoadd;

    edgestoadd := next_edge;
  until (edgestoadd = nil);
end;
{$ENDIF} // !id386

{$IFNDEF   id386}
(*
==============
R_RemoveEdges
==============
*)

procedure R_RemoveEdges(pedge: edge_p);
begin
  repeat
    pedge^.next^.prev := pedge^.prev;
    pedge^.prev^.next := pedge^.next;
    pedge := pedge^.nextremove;
  until (pedge = nil);
end;
{$ENDIF} // !id386

{$IFNDEF   id386}
(*
==============
R_StepActiveU
==============
*)

procedure R_StepActiveU(pedge: edge_p);
label
  nextedge;
label
  pushback;
var
  pnext_edge: edge_p;
  pwedge: edge_p;
begin
  while (True) do
  begin
    nextedge:
    pedge^.u := pedge^.u + pedge^.u_step;
    if (pedge^.u < pedge^.prev^.u) then
      goto pushback;
    pedge := pedge^.next;

    pedge^.u := pedge^.u + pedge^.u_step;
    if (pedge^.u < pedge^.prev^.u) then
      goto pushback;
    pedge := pedge^.next;

    pedge^.u := pedge^.u + pedge^.u_step;
    if (pedge^.u < pedge^.prev^.u) then
      goto pushback;
    pedge := pedge^.next;

    pedge^.u := pedge^.u + pedge^.u_step;
    if (pedge^.u < pedge^.prev^.u) then
      goto pushback;
    pedge := pedge^.next;

    goto nextedge;

    pushback:
    if (Integer(pedge) = Integer(@edge_aftertail)) then
      Exit;

 // push it back to keep it sorted
    pnext_edge := pedge^.next;

 // pull the edge out of the edge list
    pedge^.next^.prev := pedge^.prev;
    pedge^.prev^.next := pedge^.next;

 // find out where the edge goes in the edge list
    pwedge := pedge^.prev^.prev;

    while (pwedge^.u > pedge^.u) do
      pwedge := pwedge^.prev;

 // put the edge back into the edge list
    pedge^.next := pwedge^.next;
    pedge^.prev := pwedge;
    pedge^.next^.prev := pedge;
    pwedge^.next := pedge;

    pedge := pnext_edge;
    if (Integer(pedge) = Integer(@edge_tail)) then
      Exit;
  end;
end;
{$ENDIF} // !id386

(*
==============
R_CleanupSpan
==============
*)

procedure R_CleanupSpan;
var
  surf: surf_p;
  iu: Integer;
  span: espan_p;
begin
// now that we've reached the right edge of the screen, we're done with any
// unfinished surfaces, so emit a span for whatever's on top
  surf := PSurf_tArray(surfaces)^[1].next;
  iu := edge_tail_u_shift20;
  if (iu > surf^.last_u) then
  begin
    span := span_p;
    Inc(Integer(span_p), SizeOf(espan_t));
    span^.u := surf^.last_u;
    span^.count := iu - span^.u;
    span^.v := current_iv;
    span^.pnext := surf^.spans;
    surf^.spans := span;
  end;

// reset spanstate for all surfaces in the surface stack
  repeat
    surf^.spanstate := 0;
    surf := surf^.next;
  until (Integer(surf) = Integer(@PSurf_tArray(surfaces)^[1]));
end;

(*
==============
R_LeadingEdgeBackwards
==============
*)

procedure R_LeadingEdgeBackwards(edge: edge_p);
label
  gotposition;
label
  newtop;
label
  continue_search;
var
  span: espan_p;
  surf: surf_p;
  surf2: surf_p;
  iu: Integer;
begin
// it's adding a new surface in, so find the correct place
  surf := @PSurf_tArray(surfaces)^[edge^.surfs[1]];

// don't start a span if this is an inverted span, with the end
// edge preceding the start edge (that is, we've already seen the
// end edge)
  Inc(surf^.spanstate, 1);
  if (surf^.spanstate = 1) then
  begin
    surf2 := PSurf_tArray(surfaces)^[1].next;

    if (surf^.key > surf2^.key) then
      goto newtop;

 // if it's two surfaces on the same plane, the one that's already
 // active is in front, so keep going unless it's a bmodel
    if ((surf^.insubmodel) and (surf^.key = surf2^.key)) then
    begin
  // must be two bmodels in the same leaf; don't care, because they'll
  // never be farthest anyway
      goto newtop;
    end;

    continue_search:

    repeat
      surf2 := surf2^.next;
    until (surf^.key >= surf2^.key);

    if (surf^.key = surf2^.key) then
    begin
  // if it's two surfaces on the same plane, the one that's already
  // active is in front, so keep going unless it's a bmodel
      if not (surf^.insubmodel) then
        goto continue_search;

  // must be two bmodels in the same leaf; don't care which is really
  // in front, because they'll never be farthest anyway
    end;

    goto gotposition;

    newtop:
 // emit a span (obscures current top)
    iu := _SAR(edge^.u, 20);

    if (iu > surf2^.last_u) then
    begin
      span := span_p;
      Inc(Integer(span_p), SizeOf(espan_t));
      span^.u := surf2^.last_u;
      span^.count := iu - span^.u;
      span^.v := current_iv;
      span^.pnext := surf2^.spans;
      surf2^.spans := span;
    end;

  // set last_u on the new span
    surf^.last_u := iu;

    gotposition:
 // insert before surf2
    surf^.next := surf2;
    surf^.prev := surf2^.prev;
    surf2^.prev^.next := surf;
    surf2^.prev := surf;
  end;
end;

(*
==============
R_TrailingEdge
==============
*)

procedure R_TrailingEdge(surf: surf_p; edge: edge_p);
var
  span: espan_p;
  iu: Integer;
begin
// don't generate a span if this is an inverted span, with the end
// edge preceding the start edge (that is, we haven't seen the
// start edge yet)
  Dec(surf^.spanstate, 1);
  if (surf^.spanstate = 0) then
  begin
    if (Integer(surf) = Integer(@PSurf_tArray(surfaces)^[1].next)) then
    begin
  // emit a span (current top going away)
      iu := _SAR(edge^.u, 20);
      if (iu > surf^.last_u) then
      begin
        span := span_p;
        Inc(Integer(span_p), SizeOf(espan_t));
        span^.u := surf^.last_u;
        span^.count := iu - span^.u;
        span^.v := current_iv;
        span^.pnext := surf^.spans;
        surf^.spans := span;
      end;

  // set last_u on the surface below
      surf^.next^.last_u := iu;
    end;

    surf^.prev^.next := surf^.next;
    surf^.next^.prev := surf^.prev;
  end;
end;

{$IFNDEF   id386}
(*
==============
R_LeadingEdge
==============
*)

procedure R_LeadingEdge(edge: edge_p);
label
  gotposition;
label
  newtop;
label
  continue_search;
var
  span: espan_p;
  surf: surf_p;
  surf2: surf_p;
  iu: Integer;
  fu, newzi: Single;
  testzi: Single;
  newzitop: Single;
  newzibottom: Single;
begin
  if (edge^.surfs[1] <> 0) then
  begin
 // it's adding a new surface in, so find the correct place
    surf := @PSurf_tArray(surfaces)^[1];

 // don't start a span if this is an inverted span, with the end
 // edge preceding the start edge (that is, we've already seen the
 // end edge)
    Inc(surf^.spanstate, 1);
    if (surf^.spanstate = 1) then
    begin
      surf2 := PSurf_tArray(surfaces)^[1].next;

      if (surf^.key < surf2^.key) then
        goto newtop;

  // if it's two surfaces on the same plane, the one that's already
  // active is in front, so keep going unless it's a bmodel
      if ((surf^.insubmodel) and (surf^.key = surf2^.key)) then
      begin
   // must be two bmodels in the same leaf; sort on 1/z
        fu := edge^.u;
        fu := (fu - $FFFFF) * (1.0 / $100000);
        newzi := surf^.d_ziorigin + fv * surf^.d_zistepv + fu * surf^.d_zistepu;
        newzibottom := newzi * 0.99;

        testzi := surf2^.d_ziorigin + fv * surf2^.d_zistepv + fu * surf2^.d_zistepu;

        if (newzibottom >= testzi) then
        begin
          goto newtop;
        end;

        newzitop := newzi * 1.01;
        if (newzitop >= testzi) then
        begin
          if (surf^.d_zistepu >= surf2^.d_zistepu) then
          begin
            goto newtop;
          end;
        end;
      end;

      continue_search:

      repeat
        surf2 := surf2^.next;
      until (surf^.key <= surf2^.key);

      if (surf^.key = surf2^.key) then
      begin
   // if it's two surfaces on the same plane, the one that's already
   // active is in front, so keep going unless it's a bmodel
        if not (surf^.insubmodel) then
          goto continue_search;

   // must be two bmodels in the same leaf; sort on 1/z
        fu := edge^.u;
        fu := (fu - $FFFFF) * (1.0 / $100000);
        newzi := surf^.d_ziorigin + fv * surf^.d_zistepv + fu * surf^.d_zistepu;
        newzibottom := newzi * 0.99;

        testzi := surf2^.d_ziorigin + fv * surf2^.d_zistepv + fu * surf2^.d_zistepu;

        if (newzibottom >= testzi) then
        begin
          goto gotposition;
        end;

        newzitop := newzi * 1.01;
        if (newzitop >= testzi) then
        begin
          if (surf^.d_zistepu >= surf2^.d_zistepu) then
          begin
            goto gotposition;
          end;
        end;

        goto continue_search;
      end;

      goto gotposition;

      newtop:
  // emit a span (obscures current top)
      iu := _SAR(edge^.u, 20);

      if (iu > surf2^.last_u) then
      begin
        span := span_p;
        Inc(Integer(span_p), SizeOf(espan_t));
        span^.u := surf2^.last_u;
        span^.count := iu - span^.u;
        span^.v := current_iv;
        span^.pnext := surf2^.spans;
        surf2^.spans := span;
      end;

   // set last_u on the new span
      surf^.last_u := iu;

      gotposition:
  // insert before surf2
      surf^.next := surf2;
      surf^.prev := surf2^.prev;
      surf2^.prev^.next := surf;
      surf2^.prev := surf;
    end;
  end;
end;

(*
==============
R_GenerateSpans
==============
*)

procedure R_GenerateSpans;
var
  edge: edge_p;
  surf: surf_p;
begin
// clear active surfaces to just the background surface
  PSurf_tArray(surfaces)^[1].next := @PSurf_tArray(surfaces)^[1];
  PSurf_tArray(surfaces)^[1].prev := @PSurf_tArray(surfaces)^[1];
  PSurf_tArray(surfaces)^[1].last_u := edge_head_u_shift20;

// generate spans
  edge := edge_head.next;
  while (Integer(edge) <> Integer(@edge_tail)) do
//   for (edge=edge_head.next ; edge != &edge_tail; edge=edge->next) then
  begin
    if (edge^.surfs[0] <> 0) then
    begin
  // it has a left surface, so a surface is going away for this span
      surf := @PSurf_tArray(surfaces)^[edge^.surfs[0]];
      R_TrailingEdge(surf, edge);
      if (edge^.surfs[1] = 0) then
      begin
        edge := edge^.next;
        continue;
      end;
    end;
    R_LeadingEdge(edge);
    edge := edge^.next;
  end;
  R_CleanupSpan;
end;
{$ENDIF} // !id386

(*
==============
R_GenerateSpansBackward
==============
*)

procedure R_GenerateSpansBackward;
var
  edge: edge_p;
  surf: surf_p;
begin
// clear active surfaces to just the background surface
  PSurf_tArray(surfaces)^[1].next := @PSurf_tArray(surfaces)^[1];
  PSurf_tArray(surfaces)^[1].prev := @PSurf_tArray(surfaces)^[1];
  PSurf_tArray(surfaces)^[1].last_u := edge_head_u_shift20;

// generate spans
  edge := edge_head.next;
  while (Integer(edge) <> Integer(@edge_tail)) do
//   for (edge=edge_head.next ; edge != &edge_tail; edge=edge->next) then
  begin
    if (edge^.surfs[0] <> 0) then
    begin
  // it has a left surface, so a surface is going away for this span
      surf := @PSurf_tArray(surfaces)^[edge^.surfs[0]];
      R_TrailingEdge(surf, edge);
    end;
    if (edge^.surfs[1] <> 0) then
      R_LeadingEdgeBackwards(edge);
    edge := edge^.next;
  end;
  R_CleanupSpan;
end;

(*
==============
R_ScanEdges

Input:
newedges[] array
 this has links to edges, which have links to surfaces

Output:
Each surface has a linked list of its visible spans
==============
*)

procedure R_ScanEdges;
var
  iv, bottom: Integer;
  basespans: array[0..(MAXSPANS * sizeof(espan_t) + CACHE_SIZE) - 1] of Byte;
  basespan_p: espan_p;
  s: surf_p;
begin
//   basespan_p = (espan_t *)((long)(basespans + CACHE_SIZE - 1) & ~(CACHE_SIZE - 1));
  basespan_p := espan_p(Integer(@basespans[(CACHE_SIZE - 1) * sizeof(espan_t)]) and ($FFFFFFFF xor (CACHE_SIZE - 1)));

//   max_span_p = &basespan_p[MAXSPANS - r_refdef.vrect.width];
  max_span_p := @PEspan_tArray(basespan_p)^[MAXSPANS - r_refdef.vrect.width];

  span_p := basespan_p;

// clear active edges to just the background edges around the whole screen
// FIXME: most of this only needs to be set up once
  edge_head.u := _SAL(r_refdef.vrect.x, 20);
  edge_head_u_shift20 := _SAR(edge_head.u, 20);
  edge_head.u_step := 0;
  edge_head.prev := nil;
  edge_head.next := @edge_tail;
  edge_head.surfs[0] := 0;
  edge_head.surfs[1] := 1;

  edge_tail.u := _SAL(r_refdef.vrectright, 20) + $FFFFF;
  edge_tail_u_shift20 := _SAR(edge_tail.u, 20);
  edge_tail.u_step := 0;
  edge_tail.prev := @edge_head;
  edge_tail.next := @edge_aftertail;
  edge_tail.surfs[0] := 1;
  edge_tail.surfs[1] := 0;

  edge_aftertail.u := -1; // force a move
  edge_aftertail.u_step := 0;
  edge_aftertail.next := @edge_sentinel;
  edge_aftertail.prev := @edge_tail;

// FIXME: do we need this now that we clamp x in r_draw.c?
  edge_sentinel.u := 125 shl 24; //2000 shl 24;      // make sure nothing sorts past this
  edge_sentinel.prev := @edge_aftertail;

//
// process all scan lines
//
  bottom := r_refdef.vrectbottom - 1;

//   for (iv=r_refdef.vrect.y ; iv<bottom ; iv++) do
  for iv := r_refdef.vrect.y to bottom - 1 do
  begin
    current_iv := iv;
    fv := iv;

 // mark that the head (background start) span is pre-included
    PSurf_tArray(surfaces)^[1].spanstate := 1;
    if (newedges[iv] <> nil) then
    begin
      R_InsertNewEdges(newedges[iv], edge_head.next);
    end;

    pdrawfunc;

 // flush the span list if we can't be sure we have enough spans left for
 // the next scan
    if (Integer(span_p) > Integer(max_span_p)) then
    begin
      D_DrawSurfaces;

  // clear the surface span pointers

//         for (s = &surfaces[1] ; s<surface_p ; s++) do
      s := @PSurf_tArray(surfaces)^[1];
      while (Integer(s) < Integer(surface_p)) do
      begin
        s^.spans := nil;
        Inc(Integer(s), SizeOf(surf_t));
      end;
      span_p := basespan_p;
    end;

    if (removeedges[iv] <> nil) then
      R_RemoveEdges(removeedges[iv]);

    if (Integer(edge_head.next) <> Integer(@edge_tail)) then
      R_StepActiveU(edge_head.next);
  end;

// do the last scan (no need to step or sort or remove on the last scan)
  iv := bottom;
  current_iv := iv;
  fv := iv;

// mark that the head (background start) span is pre-included
  PSurf_tArray(surfaces)^[1].spanstate := 1;

  if (newedges[iv] <> nil) then
    R_InsertNewEdges(newedges[iv], edge_head.next);

  pdrawfunc;

// draw whatever's left in the span list
  D_DrawSurfaces;
end;

(*
=========================================================================

SURFACE FILLING

=========================================================================
*)

var
  pface: msurface_p;
  pcurrentcache: surfcache_p;
  transformed_modelorg: vec3_t;
  world_transformed_modelorg: vec3_t;
  local_modelorg: vec3_t;

(*
=============
D_MipLevelForScale
=============
*)

function D_MipLevelForScale(scale: Single): Integer;
var
  lmiplevel: Integer;
begin
  if (scale >= d_scalemip[0]) then
    lmiplevel := 0
  else
    if (scale >= d_scalemip[1]) then
      lmiplevel := 1
    else
      if (scale >= d_scalemip[2]) then
        lmiplevel := 2
      else
        lmiplevel := 3;

  if (lmiplevel < d_minmip) then
    lmiplevel := d_minmip;

  Result := lmiplevel;
end;

(*
==============
D_FlatFillSurface

Simple single color fill with no texture mapping
==============
*)

procedure D_FlatFillSurface(surf: surf_p; color: Integer);
var
  span: espan_p;
  pdest: PByte;
  u, u2: Integer;
begin
//   for (span=surf->spans ; span ; span=span->pnext)
  span := surf^.spans;
  while (span <> nil) do
  begin
    pdest := PByte(Integer(d_viewbuffer) + r_screenwidth * span^.v);
    u := span^.u;
    u2 := span^.u + span^.count - 1;
    while (u <= u2) do
    begin
      PByteArray(pdest)^[u] := color;
      u := u + 1;
    end;
    span := span^.pnext;
  end;
end;

(*
==============
D_CalcGradients
==============
*)

procedure D_CalcGradients(pface: msurface_p);
var
//   pplane    : mplane_p;
  mipscale: Single;
  p_temp1: vec3_t;
  p_saxis: vec3_t;
  p_taxis: vec3_t;
  t: Single;
begin
//   pplane := pface^.plane;

  mipscale := 1.0 / (1 shl miplevel);

  TransformVector(vec3_p(@pface^.texinfo^.vecs[0])^, p_saxis);
  TransformVector(vec3_p(@pface^.texinfo^.vecs[1])^, p_taxis);

  t := xscaleinv * mipscale;
  d_sdivzstepu := p_saxis[0] * t;
  d_tdivzstepu := p_taxis[0] * t;

  t := yscaleinv * mipscale;
  d_sdivzstepv := -p_saxis[1] * t;
  d_tdivzstepv := -p_taxis[1] * t;

  d_sdivzorigin := p_saxis[2] * mipscale - xcenter * d_sdivzstepu - ycenter * d_sdivzstepv;
  d_tdivzorigin := p_taxis[2] * mipscale - xcenter * d_tdivzstepu - ycenter * d_tdivzstepv;

  VectorScale(transformed_modelorg, mipscale, p_temp1);

  t := $10000 * mipscale;

  sadjust := (fixed16_t(Trunc(DotProduct(p_temp1, p_saxis) * $10000 + 0.5))) -
    _SAR(_SAL(pface^.texturemins[0], 16), miplevel) + Trunc(pface^.texinfo^.vecs[0][3] * t);
  tadjust := (fixed16_t(Trunc(DotProduct(p_temp1, p_taxis) * $10000 + 0.5))) -
    _SAR(_SAL(pface^.texturemins[1], 16), miplevel) + Trunc(pface^.texinfo^.vecs[1][3] * t);

(*   sadjust := (fixed16_t(Trunc(DotProduct(p_temp1, p_saxis) * $10000 + 0.5))) -
          ((pface^.texturemins[0] shl 16) shr miplevel)+ Trunc(pface^.texinfo^.vecs[0][3]*t);
 tadjust := (fixed16_t(Trunc(DotProduct(p_temp1, p_taxis) * $10000 + 0.5))) -
             ((pface^.texturemins[1] shl 16) shr miplevel) + Trunc(pface^.texinfo^.vecs[1][3]*t);
*)
 // PGM - changing flow speed for non-warping textures.
  if (pface^.texinfo^.flags and SURF_FLOWING) <> 0 then
  begin
    if (pface^.texinfo^.flags and SURF_WARP) <> 0 then
      sadjust := sadjust + Trunc($10000 * (-128 * ((r_newrefdef.time * 0.25) - (r_newrefdef.time * 0.25))))
    else
      sadjust := sadjust + Trunc($10000 * (-128 * ((r_newrefdef.time * 0.77) - (r_newrefdef.time * 0.77))));
  end;
 // PGM

//
// -1 (-epsilon) so we never wander off the edge of the texture
//
  bbextents := _SAR(_SAL(pface^.extents[0], 16), miplevel) - 1;
  bbextentt := _SAR(_SAL(pface^.extents[1], 16), miplevel) - 1;
//   bbextents := ((pface^.extents[0] shl 16) shr miplevel) - 1;
//   bbextentt := ((pface^.extents[1] shl 16) shr miplevel) - 1;
end;

(*
==============
D_BackgroundSurf

The grey background filler seen when there is a hole in the map
==============
*)

procedure D_BackgroundSurf(s: surf_p);
begin
// set up a gradient for the background surface that places it
// effectively at infinity distance from the viewpoint
  d_zistepu := 0;
  d_zistepv := 0;
  d_ziorigin := -0.9;

  D_FlatFillSurface(s, Trunc(sw_clearcolor^.value) and $FF);
  D_DrawZSpans(s^.spans);
end;

(*
=================
D_TurbulentSurf
=================
*)

procedure D_TurbulentSurf(s: surf_p);
begin
  d_zistepu := s^.d_zistepu;
  d_zistepv := s^.d_zistepv;
  d_ziorigin := s^.d_ziorigin;

  pface := s^.msurf;
  miplevel := 0;
  cacheblock := pface^.texinfo^.image^.pixels[0];
  cachewidth := 64;

  if (s^.insubmodel) then
  begin
 // FIXME: we don't want to do all this for every polygon!
 // TODO: store once at start of frame
    currententity := s^.entity; //FIXME: make this passed in to
         // R_RotateBmodel ()
    VectorSubtract(r_origin, vec3_p(@currententity^.origin)^, local_modelorg);
    TransformVector(local_modelorg, transformed_modelorg);

    R_RotateBmodel; // FIXME: don't mess with the frustum,
       // make entity passed in
  end;

  D_CalcGradients(pface);

//============
//PGM
 // textures that aren't warping are just flowing. Use NonTurbulent8 instead
  if ((pface^.texinfo^.flags and SURF_WARP) = 0) then
    NonTurbulent8(s^.spans)
  else
    Turbulent8(s^.spans);
//PGM
//============

  D_DrawZSpans(s^.spans);

  if (s^.insubmodel) then
  begin
 //
 // restore the old drawing state
 // FIXME: we don't want to do this every time!
 // TODO: speed up
 //
    currententity := nil; // &r_worldentity;
    VectorCopy(world_transformed_modelorg, transformed_modelorg);
    VectorCopy(base_vpn, vpn);
    VectorCopy(base_vup, vup);
    VectorCopy(base_vright, vright);
    R_TransformFrustum;
  end;
end;

(*
==============
D_SkySurf
==============
*)

procedure D_SkySurf(s: surf_p);
begin
  pface := s^.msurf;
  miplevel := 0;
  if (pface^.texinfo^.image = nil) then
    Exit;
  cacheblock := pface^.texinfo^.image^.pixels[0];
  cachewidth := 256;

  d_zistepu := s^.d_zistepu;
  d_zistepv := s^.d_zistepv;
  d_ziorigin := s^.d_ziorigin;

  D_CalcGradients(pface);

  D_DrawSpans16(s^.spans);

// set up a gradient for the background surface that places it
// effectively at infinity distance from the viewpoint
  d_zistepu := 0;
  d_zistepv := 0;
  d_ziorigin := -0.9;

  D_DrawZSpans(s^.spans);
end;

(*
==============
D_SolidSurf

Normal surface cached, texture mapped surface
==============
*)

procedure D_SolidSurf(s: surf_p);
{$IF false}
var
  dot: Single;
  normal: array[0..2] of Single;
{$IFEND}
begin
  d_zistepu := s^.d_zistepu;
  d_zistepv := s^.d_zistepv;
  d_ziorigin := s^.d_ziorigin;

  if (s^.insubmodel) then
  begin
 // FIXME: we don't want to do all this for every polygon!
 // TODO: store once at start of frame
    currententity := s^.entity; //FIXME: make this passed in to
         // R_RotateBmodel ()
    VectorSubtract(r_origin, vec3_p(@currententity^.origin)^, local_modelorg);
    TransformVector(local_modelorg, transformed_modelorg);

    R_RotateBmodel; // FIXME: don't mess with the frustum,
       // make entity passed in
  end
  else
    currententity := @r_worldentity;

  pface := s^.msurf;
{$IF True}
  miplevel := D_MipLevelForScale(s^.nearzi * scale_for_mip * pface^.texinfo^.mipadjust);
{$ELSE}
  begin

    if (s^.insubmodel) then
    begin
      VectorCopy(pface^.plane^.normal, normal);
//         TransformVector( pface->plane->normal, normal);
      dot := DotProduct(normal, vpn);
    end
    else
    begin
      VectorCopy(pface^.plane^.normal, normal);
      dot := DotProduct(normal, vpn);
    end;

    if (pface^.flags and SURF_PLANEBACK) <> 0 then
      dot := -dot;

//      if (dot > 0) then
//         printf( "blah" );

    miplevel := D_MipLevelForScale(s^.nearzi * scale_for_mip * pface^.texinfo^.mipadjust);
  end;
{$IFEND}

// FIXME: make this passed in to D_CacheSurface
  pcurrentcache := D_CacheSurface(pface, miplevel);

  cacheblock := pixel_p(@pcurrentcache^.data);
  cachewidth := pcurrentcache^.width;

  D_CalcGradients(pface);

  D_DrawSpans16(s^.spans);

  D_DrawZSpans(s^.spans);

  if (s^.insubmodel) then
  begin
 //
 // restore the old drawing state
 // FIXME: we don't want to do this every time!
 // TODO: speed up
 //
    VectorCopy(world_transformed_modelorg, transformed_modelorg);
    VectorCopy(base_vpn, vpn);
    VectorCopy(base_vup, vup);
    VectorCopy(base_vright, vright);
    R_TransformFrustum;
    currententity := nil; //&r_worldentity;
  end;
end;

(*
=============
D_DrawflatSurfaces

To allow developers to see the polygon carving of the world
=============
*)

procedure D_DrawflatSurfaces;
var
  s: surf_p;
begin
  s := @PSurf_tArray(surfaces)^[1];
//   for (s = &surfaces[1] ; s<surface_p ; s++)
  while (Integer(s) < Integer(surface_p)) do
  begin
    if (s^.spans = nil) then
    begin
      Inc(Integer(s), SizeOf(surf_t));
      continue;
    end;
    d_zistepu := s^.d_zistepu;
    d_zistepv := s^.d_zistepv;
    d_ziorigin := s^.d_ziorigin;

  // make a stable color for each surface by taking the low
  // bits of the msurface pointer
    D_FlatFillSurface(s, Integer(s^.msurf) and $FF);
    D_DrawZSpans(s^.spans);
    Inc(Integer(s), SizeOf(surf_t));
  end;
end;

(*
==============
D_DrawSurfaces

Rasterize all the span lists.  Guaranteed zero overdraw.
May be called more than once a frame if the surf list overflows (higher res)
==============
*)

procedure D_DrawSurfaces;
var
  s: surf_p;
begin
  currententity := nil; //&r_worldentity;
  VectorSubtract(r_origin, vec3_origin, modelorg);
  TransformVector(modelorg, transformed_modelorg);
  VectorCopy(transformed_modelorg, world_transformed_modelorg);

  if (sw_drawflat^.value = 0.0) then
  begin
    s := @PSurf_tArray(surfaces)^[1];
    while (Integer(s) < Integer(surface_p)) do
    begin
      if (s^.spans = nil) then
      begin
        Inc(Integer(s), SizeOf(surf_t));
        continue;
      end;
      r_drawnpolycount := r_drawnpolycount + 1;

      if ((s^.flags and (SURF_DRAWSKYBOX or SURF_DRAWBACKGROUND or SURF_DRAWTURB)) = 0) then
        D_SolidSurf(s)
      else
        if (s^.flags and SURF_DRAWSKYBOX) <> 0 then
          D_SkySurf(s)
        else
          if (s^.flags and SURF_DRAWBACKGROUND) <> 0 then
            D_BackgroundSurf(s)
          else
            if (s^.flags and SURF_DRAWTURB) <> 0 then
              D_TurbulentSurf(s);
      Inc(Integer(s), SizeOf(surf_t));
    end;
  end
  else
    D_DrawflatSurfaces;

  currententity := nil; //&r_worldentity;
  VectorSubtract(r_origin, vec3_origin, modelorg);
  R_TransformFrustum;
end;

end.
