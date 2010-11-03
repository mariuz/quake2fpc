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
{ File(s): r_rast.c                                                          }
{ Content:                                                                   }
{                                                                            }
{ Initial conversion by : Carl A Kenner (carl_kenner@hotmail.com)            }
{ Initial conversion on : 23-Feb-2002                                        }
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
{ Updated by : Carl A Kenner (carl_kenner@hotmail.com)                       }
{ Updated on : 12-Aug-2002                                                   }
{ Updated by : CodeFusion (Michael@skovslund.dk)                             }
{                                                                            }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{ none                                                                       }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{----------------------------------------------------------------------------}
// r_rast.c
unit r_rast;

{$DEFINE _NODEPEND}

interface

uses
  q_shared,
  qfiles,
  r_model,
  r_misc,
  r_local;

procedure R_InitSkyBox;
procedure R_RenderFace(fa: msurface_p; clipflags: Integer);
procedure R_EmitEdge(pv0, pv1: mvertex_p);
procedure R_RenderBmodelFace(pedges: bedge_p; psurf: msurface_p);

var
  sintable: array[0..1279] of Integer;
  intsintable: array[0..1279] of Integer;
  blanktable: array[0..1279] of Integer; // PGM
  view_clipplanes: array[0..3] of clipplane_t;
  c_faceclip: Integer; // number of faces clipped
  r_skytexinfo: array[0..5] of mtexinfo_t;

implementation

uses
  r_poly,
  r_edgea,
  r_edge,
  r_bsp_c,
  r_main,
  SysUtils;

const
  MAXLEFTCLIPEDGES = 100;

// !!! if these are changed, they must be changed in asm_draw.h too !!!
  FULLY_CLIPPED_CACHED = $80000000;
  FRAMECOUNT_MASK = $7FFFFFFF;

var
  cacheoffset: Cardinal;
//  entity_clipplanes : clipplane_p;
//  world_clipplanes  : Array[0..15] of clipplane_t;
  r_pedge: medge_p;
  r_leftclipped: qboolean;
  r_rightclipped: qboolean;
  r_nearzionly: qboolean;
  r_leftenter: mvertex_t;
  r_leftexit: mvertex_t;
  r_rightenter: mvertex_t;
  r_rightexit: mvertex_t;

type
  evert_p = ^evert_t;
  pevert_t = evert_p;
  evert_t = record
    u, v: Single;
    ceilv: Integer;
  end;
  TEvert = evert_t;
  PEvert = evert_p;

var
  r_emitted: Integer;
  r_nearzi: Single;
  r_u1, r_v1, r_lzi1: Single;
  r_ceilv1: Integer;

  r_lastvertvalid: qboolean;
  r_skyframe: Integer;

  r_skyfaces: msurface_p;
  r_skyplanes: array[0..5] of mplane_t;
  r_skyverts: mvertex_p;
  r_skyedges: medge_p;
  r_skysurfedges: PInteger;

// I just copied this data from a box map...
var
  skybox_planes: array[0..11] of Integer = (2, -128, 0, -128, 2, 128, 1, 128, 0, 128, 1, -128);
  box_surfedges: array[0..23] of Integer = (1, 2, 3, 4, -1, 5, 6, 7, 8, 9, -6, 10, -2, -7, -9, 11,
    12, -3, -11, -8, -12, -10, -5, -4);
  box_edges: array[0..23] of Integer = (1, 2, 2, 3, 3, 4, 4, 1, 1, 5, 5, 6, 6, 2,
    7, 8, 8, 6, 5, 7, 8, 3, 7, 4);
  box_faces: array[0..5] of Integer = (0, 0, 2, 2, 2, 0);
  box_vecs: array[0..5, 0..1] of vec3_t = (
    ((0, -1, 0), (-1, 0, 0)),
    ((0, 1, 0), (0, 0, -1)),
    ((0, -1, 0), (1, 0, 0)),
    ((1, 0, 0), (0, 0, -1)),
    ((0, -1, 0), (0, 0, -1)),
    ((-1, 0, 0), (0, 0, -1))
    );
  box_verts: array[0..7, 0..2] of Single = (
    (-1, -1, -1),
    (-1, 1, -1),
    (1, 1, -1),
    (1, -1, -1),
    (-1, -1, 1),
    (-1, 1, 1),
    (1, -1, 1),
    (1, 1, 1)
    );

// down, west, up, north, east, south
// {"rt", "bk", "lf", "ft", "up", "dn"};

var
  makeleftedge,
    makerightedge: qboolean; // CAK - global static means other units can't use it

(*
================
R_InitSkyBox

================
*)

procedure R_InitSkyBox;
var
  i: Integer;
begin
//  r_skyfaces := msurface_p(Integer(loadmodel^.surfaces)+(loadmodel^.numsurfaces*SizeOf(msurface_t)));
  r_skyfaces := @msurface_arrp(loadmodel^.surfaces)^[loadmodel^.numsurfaces];
  Inc(loadmodel^.numsurfaces, 6);

//  r_skyverts := mvertex_p(Integer(loadmodel^.vertexes)+(loadmodel^.numvertexes*SizeOf(mvertex_t)));
  r_skyverts := @mvertex_arrp(loadmodel^.vertexes)^[loadmodel^.numvertexes];
  Inc(loadmodel^.numvertexes, 8);

//  r_skyedges := medge_p(Integer(loadmodel^.edges)+(loadmodel^.numedges*SizeOf(medge_t)));
  r_skyedges := @medge_arrp(loadmodel^.edges)^[loadmodel^.numedges];
  Inc(loadmodel^.numedges, 12);

//  r_skysurfedges := PInteger(Integer(loadmodel^.surfedges)+(loadmodel^.numsurfedges*SizeOf(Integer)));
  r_skysurfedges := @PIntegerArray(loadmodel^.surfedges)^[loadmodel^.numsurfedges];
  Inc(loadmodel^.numsurfedges, 24);

  if (loadmodel^.numsurfaces > MAX_MAP_FACES) or (loadmodel^.numvertexes > MAX_MAP_VERTS) or (loadmodel^.numedges > MAX_MAP_EDGES) then
    ri.Sys_Error(ERR_DROP, 'InitSkyBox: map overflow');

  FillChar(r_skyfaces^, 6*sizeof(r_skyfaces^), 0);
  for i:= 0 to 5 do
  begin
    r_skyplanes[i].normal[skybox_planes[i * 2]] := 1;
    r_skyplanes[i].dist := skybox_planes[i * 2 + 1];

    VectorCopy(box_vecs[i][0], vec3_p(@r_skytexinfo[i].vecs[0][0])^);
    VectorCopy(box_vecs[i][1], vec3_p(@r_skytexinfo[i].vecs[1][0])^);

    msurface_arrp(r_skyfaces)^[i].plane := @r_skyplanes[i];
    msurface_arrp(r_skyfaces)^[i].numedges := 4;
    msurface_arrp(r_skyfaces)^[i].flags := box_faces[i] or SURF_DRAWSKYBOX;
    msurface_arrp(r_skyfaces)^[i].firstedge := loadmodel.numsurfedges - 24 + i * 4;
    msurface_arrp(r_skyfaces)^[i].texinfo := @r_skytexinfo[i];
    msurface_arrp(r_skyfaces)^[i].texturemins[0] := -128;
    msurface_arrp(r_skyfaces)^[i].texturemins[1] := -128;
    msurface_arrp(r_skyfaces)^[i].extents[0] := 256;
    msurface_arrp(r_skyfaces)^[i].extents[1] := 256;
  end;

  for i := 0 to 23 do
  begin
    if box_surfedges[i] > 0 then
      PIntegerArray(r_skysurfedges)^[i] := loadmodel^.numedges - 13 + box_surfedges[i]
//      PInteger(Integer(r_skysurfedges)+(i*SizeOf(Integer)))^ := loadmodel.numedges-13 + box_surfedges[i]
    else
      PIntegerArray(r_skysurfedges)^[i] := -(loadmodel^.numedges-13 + (-box_surfedges[i]));
//      PInteger(Integer(r_skysurfedges)+(i*SizeOf(Integer)))^ := - (loadmodel.numedges-13 + -box_surfedges[i]);
  end;

  for i := 0 to 11 do
  begin
    medge_arrp(r_skyedges)^[i].v[0] := loadmodel.numvertexes - 9 + box_edges[i * 2 + 0];
    medge_arrp(r_skyedges)^[i].v[1] := loadmodel.numvertexes - 9 + box_edges[i * 2 + 1];
    medge_arrp(r_skyedges)^[i].cachededgeoffset := 0;
  end;
end;

(*
================
R_EmitSkyBox
================
*)

procedure R_EmitSkyBox;
var
  i, j: Integer;
  oldkey: Integer;
begin
  if insubmodel then
    exit; // submodels should never have skies
  if r_skyframe = r_framecount then
    exit; // already set this frame

  r_skyframe := r_framecount;

  // set the eight fake vertexes
  for i := 0 to 7 do
    for j := 0 to 2 do
      mvertex_arrp(r_skyverts)^[i].position[j] := r_origin[j] + box_verts[i][j] * 128;

  // set the six fake planes
  for i := 0 to 5 do
    if skybox_planes[(i * 2) + 1] > 0 then
      r_skyplanes[i].dist := r_origin[skybox_planes[i * 2]] + 128
    else
      r_skyplanes[i].dist := r_origin[skybox_planes[i * 2]] - 128;

  // fix texture offseets
  for i := 0 to 5 do
  begin
    r_skytexinfo[i].vecs[0][3] := -DotProduct(r_origin, vec3_p(@r_skytexinfo[i].vecs[0][0])^);
    r_skytexinfo[i].vecs[1][3] := -DotProduct(r_origin, vec3_p(@r_skytexinfo[i].vecs[1][0])^);
  end;

  // emit the six faces
  oldkey := r_currentkey;
  r_currentkey := $7FFFFFF0;
  for i := 0 to 5 do
  begin
    R_RenderFace(@msurface_arrp(r_skyfaces)^[i], 15);
  end;
  r_currentkey := oldkey; // bsp sorting order
end;

(*
================
R_EmitEdge
================
*)
{$IFNDEF id386}

procedure R_EmitEdge(pv0, pv1: mvertex_p);
var
  edge, pcheck: edge_p;
  u_check: Integer;
  u, u_step: Single;
  local: vec3_t;
  transformed: vec3_t;
  world: PSingle;
  v, v2, ceilv0: Integer;
  scale, lzi0: Single;
  u0, v0: Single;
  side: Integer;
begin
  if r_lastvertvalid then
  begin
    u0 := r_u1;
    v0 := r_v1;
    lzi0 := r_lzi1;
    ceilv0 := r_ceilv1;
  end
  else
  begin
    world := @pv0^.position[0];

    // transform and project
    VectorSubtract(vec3_p(world)^, modelorg, local);
    TransformVector(local, transformed);

    if transformed[2] < NEAR_CLIP then
      transformed[2] := NEAR_CLIP;

    lzi0 := 1.0 / transformed[2];

    // FIXME: build x/yscale into transform?
    scale := xscale * lzi0;
    u0 := xcenter + scale * transformed[0];
    if u0 < r_refdef.fvrectx_adj then
      u0 := r_refdef.fvrectx_adj;
    if u0 > r_refdef.fvrectright_adj then
      u0 := r_refdef.fvrectright_adj;

    scale := yscale * lzi0;
    v0 := ycenter - scale * transformed[1];
    if v0 < r_refdef.fvrecty_adj then
      v0 := r_refdef.fvrecty_adj;
    if v0 > r_refdef.fvrectbottom_adj then
      v0 := r_refdef.fvrectbottom_adj;

    ceilv0 := ceil(v0);
  end;

  world := @pv1^.position[0];

  // transform and project
  VectorSubtract(vec3_p(world)^, modelorg, local);
  TransformVector(local, transformed);

  if transformed[2] < NEAR_CLIP then
    transformed[2] := NEAR_CLIP;

  r_lzi1 := 1.0 / transformed[2];

  scale := xscale * r_lzi1;
  r_u1 := (xcenter + scale * transformed[0]);
  if r_u1 < r_refdef.fvrectx_adj then
    r_u1 := r_refdef.fvrectx_adj;
  if r_u1 > r_refdef.fvrectright_adj then
    r_u1 := r_refdef.fvrectright_adj;

  scale := yscale * r_lzi1;
  r_v1 := ycenter - scale * transformed[1];
  if r_v1 < r_refdef.fvrecty_adj then
    r_v1 := r_refdef.fvrecty_adj;
  if r_v1 > r_refdef.fvrectbottom_adj then
    r_v1 := r_refdef.fvrectbottom_adj;

  if r_lzi1 > lzi0 then
    lzi0 := r_lzi1;

  if lzi0 > r_nearzi then // for mipmap finding
    r_nearzi := lzi0;

  // for right edges, all we want is the effect on 1/z
  if r_nearzionly then
    exit;

  r_emitted := 1;

  r_ceilv1 := ceil(r_v1);

  // create the edge
  if ceilv0 = r_ceilv1 then
  begin
    // we cache unclipped horizontal edges as fully clipped
    if cacheoffset <> $7FFFFFFF then
    begin
      cacheoffset := FULLY_CLIPPED_CACHED or (Cardinal(r_framecount) and FRAMECOUNT_MASK);
    end;
    exit; // horizontal edge
  end;

  side := Integer(ceilv0 > r_ceilv1);

  edge := edge_p_;
  Inc(Integer(edge_p_), SizeOf(edge_p_^));

  edge^.owner := r_pedge;

  edge^.nearzi := lzi0;

  if side = 0 then
  begin
    // trailing edge (go from p1 to p2)
    v := ceilv0;
    v2 := r_ceilv1 - 1;

    edge^.surfs[0] := (Integer(surface_p) - Integer(surfaces)) div sizeof(surf_t);
    edge^.surfs[1] := 0;

    u_step := ((r_u1 - u0) / (r_v1 - v0));
    u := v;
    u := u0 + (u - v0) * u_step;
  end
  else
  begin
    // leading edge (go from p2 to p1)
    v2 := ceilv0 - 1;
    v := r_ceilv1;

    edge^.surfs[0] := 0;
    edge^.surfs[1] := (Integer(surface_p) - Integer(surfaces)) div sizeof(surf_t);

    u_step := ((u0 - r_u1) / (v0 - r_v1));
    u := v;
    u := r_u1 + (u - r_v1) * u_step;
  end;

  edge^.u_step := Trunc(u_step * $100000); // CAK truncate or round ???? CODEFUSION -> Trunc!!!!
  edge^.u := Trunc(u * $100000 + $FFFFF);

// we need to do this to avoid stepping off the edges if a very nearly
// horizontal edge is less than epsilon above a scan, and numeric error causes
// it to incorrectly extend to the scan, and the extension of the line goes off
// the edge of the screen
// FIXME: is this actually needed?
  if edge^.u < r_refdef.vrect_x_adj_shift20 then
    edge^.u := r_refdef.vrect_x_adj_shift20;
  if edge^.u > r_refdef.vrectright_adj_shift20 then
    edge^.u := r_refdef.vrectright_adj_shift20;

//
// sort the edge in normally
//
  u_check := edge^.u;
  if edge^.surfs[0] <> 0 then
    inc(u_check); // sort trailers after leaders

  if (newedges[v] = nil) or (newedges[v]^.u >= u_check) then
  begin
    edge^.next := newedges[v];
    newedges[v] := edge;
  end
  else
  begin
    pcheck := newedges[v];
    while (pcheck^.next <> nil) and (pcheck^.next^.u < u_check) do
      pcheck := pcheck^.next;
    edge^.next := pcheck^.next;
    pcheck^.next := edge;
  end;

  edge^.nextremove := removeedges[v2];
  removeedges[v2] := edge;
end;

(*
================
R_ClipEdge
================
*)

procedure R_ClipEdge(pv0, pv1: mvertex_p; clip: clipplane_p);
var
  d0, d1, f: Single;
  clipvert: mvertex_t;
begin
  if clip <> nil then
  begin
    repeat
      d0 := DotProduct(pv0^.position, clip^.normal) - clip^.dist;
      d1 := DotProduct(pv1^.position, clip^.normal) - clip^.dist;

      if d0 >= 0 then
      begin
        // point 0 is unclipped
        if d1 >= 0 then
        begin
          // both points are unclipped
          clip := clip^.next;
          continue;
        end;

        // only point 1 is clipped

        // we don't cache clipped edges
        cacheoffset := $7FFFFFFF;

        f := d0 / (d0 - d1);
        clipvert.position[0] := pv0^.position[0] + f * (pv1^.position[0] - pv0^.position[0]);
        clipvert.position[1] := pv0^.position[1] + f * (pv1^.position[1] - pv0^.position[1]);
        clipvert.position[2] := pv0^.position[2] + f * (pv1^.position[2] - pv0^.position[2]);

        if clip^.leftedge <> 0 then
        begin
          r_leftclipped := true;
          r_leftexit := clipvert;
        end
        else
        begin
          if clip^.rightedge <> 0 then
          begin
            r_rightclipped := true;
            r_rightexit := clipvert;
          end;
        end;
        R_ClipEdge(pv0, @clipvert, clip^.next);
        Exit;
      end
      else
      begin
        // point 0 is clipped
        if d1 < 0 then
        begin
          // both points are clipped
          // we do cache fully clipped edges
          if not r_leftclipped then
          begin
            cacheoffset := FULLY_CLIPPED_CACHED or (Cardinal(r_framecount) and FRAMECOUNT_MASK);
          end;
          Exit;
        end;

        // only point 0 is clipped
        r_lastvertvalid := false;

        // we don't cache partially clipped edges
        cacheoffset := $7FFFFFFF;

        f := d0 / (d0 - d1);
        clipvert.position[0] := pv0^.position[0] + f * (pv1^.position[0] - pv0^.position[0]);
        clipvert.position[1] := pv0^.position[1] + f * (pv1^.position[1] - pv0^.position[1]);
        clipvert.position[2] := pv0^.position[2] + f * (pv1^.position[2] - pv0^.position[2]);

        if clip^.leftedge <> 0 then
        begin
          r_leftclipped := true;
          r_leftenter := clipvert;
        end
        else
        begin
          if clip^.rightedge <> 0 then
          begin
            r_rightclipped := true;
            r_rightenter := clipvert;
          end;
        end;
        R_ClipEdge(@clipvert, pv1, clip^.next);
        Exit;
      end;
      clip := clip^.next;
    until clip = nil;
  end;
  // add the edge
  R_EmitEdge(pv0, pv1);
end;
{$ENDIF}

(*
================
R_EmitCachedEdge
================
*)

procedure R_EmitCachedEdge;
var
  pedge_t: edge_p;
begin
  pedge_t := edge_p(Integer(r_edges) + r_pedge^.cachededgeoffset);
  if pedge_t^.surfs[0] = 0 then
    pedge_t^.surfs[0] := (Integer(surface_p) - Integer(surfaces)) div sizeof(surf_t)
  else
    pedge_t^.surfs[1] := (Integer(surface_p) - Integer(surfaces)) div sizeof(surf_t);

  if pedge_t^.nearzi > r_nearzi then // for mipmap finding
    r_nearzi := pedge_t^.nearzi;

  r_emitted := 1;
end;

(*
================
R_RenderFace
================
*)

procedure R_RenderFace(fa: msurface_p; clipflags: Integer);
var
  i, lindex: Integer;
  mask: Cardinal;
  pplane: mplane_p;
  distinv: Single;
  p_normal: vec3_t;
  pedges: medge_p;
  tedge: medge_t;
  pclip: clipplane_p;
begin
  // translucent surfaces are not drawn by the edge renderer
  if (fa^.texinfo^.flags and (SURF_TRANS33 or SURF_TRANS66)) <> 0 then
  begin
    fa^.nextalphasurface := r_alpha_surfaces;
    r_alpha_surfaces := fa;
    Exit;
  end;

  // sky surfaces encountered in the world will cause the
  // environment box surfaces to be emited
  if (fa^.texinfo^.flags and SURF_SKY) <> 0 then
  begin
    R_EmitSkyBox;
    Exit;
  end;

  // skip out if no more surfs
  if Integer(surface_p) >= Integer(surf_max) then
  begin
    Inc(r_outofsurfaces);
    Exit;
  end;
  // ditto if not enough edges left, or switch to auxedges if possible
  if Integer(@PEdge_tArray(edge_p_)^[(fa^.numedges + 4)]) >= Integer(edge_max) then
  begin
    Inc(r_outofedges, fa^.numedges);
    Exit;
  end;

  Inc(c_faceclip);

  // set up clip planes
  pclip := nil;

  mask := $08;
  for i := 3 downto 0 do
  begin
    if (clipflags and mask) <> 0 then
    begin
      view_clipplanes[i].next := pclip;
      pclip := @view_clipplanes[i];
    end;
    mask := mask shr 1;
  end;

  // push the edges through
  r_emitted := 0;
  r_nearzi := 0;
  r_nearzionly := false;
  makeleftedge := false;
  makerightedge := false;
  pedges := currentmodel^.edges;
  r_lastvertvalid := false;

  for i := 0 to fa^.numedges - 1 do
  begin
    lindex := PIntegerArray(currentmodel^.surfedges)^[fa^.firstedge + i];
    if lindex > 0 then
    begin
      r_pedge := @medge_arrp(pedges)^[lindex];

      // if the edge is cached, we can just reuse the edge
      if not insubmodel then
      begin
        if (r_pedge^.cachededgeoffset and FULLY_CLIPPED_CACHED) <> 0 then
        begin
          if Integer(r_pedge^.cachededgeoffset and FRAMECOUNT_MASK) = r_framecount then
          begin
            r_lastvertvalid := false;
            continue;
          end;
        end
        else
        begin
          if (Integer(edge_p_) - Integer(r_edges) > r_pedge^.cachededgeoffset) and
            (edge_p(Integer(r_edges) + r_pedge^.cachededgeoffset)^.owner = r_pedge) then
          begin
            R_EmitCachedEdge;
            r_lastvertvalid := false;
            continue;
          end;
        end;
      end;
      // assume it's cacheable
      cacheoffset := Cardinal(edge_p_) - Cardinal(r_edges);
      r_leftclipped := false;
      r_rightclipped := false;
      R_ClipEdge(@mvertex_arrp(r_pcurrentvertbase)^[r_pedge^.v[0]],
        @mvertex_arrp(r_pcurrentvertbase)^[r_pedge^.v[1]], pclip);
      r_pedge^.cachededgeoffset := cacheoffset;

      if r_leftclipped then
        makeleftedge := true;
      if r_rightclipped then
        makerightedge := true;
      r_lastvertvalid := true;
    end
    else
    begin
      lindex := -lindex;
      r_pedge := @medge_arrp(pedges)^[lindex];
      // if the edge is cached, we can just reuse the edge
      if not insubmodel then
      begin
        if (r_pedge^.cachededgeoffset and FULLY_CLIPPED_CACHED) > 0 then
        begin
          if Integer(r_pedge^.cachededgeoffset and FRAMECOUNT_MASK) = r_framecount then
          begin
            r_lastvertvalid := false;
            continue;
          end;
        end
        else
        begin
     // it's cached if the cached edge is valid and is owned
     // by this medge_t
          if (Cardinal(edge_p_) - Cardinal(r_edges) > Cardinal(r_pedge^.cachededgeoffset)) and
              (edge_p(Integer(r_edges) + r_pedge^.cachededgeoffset)^.owner = r_pedge) then
          begin
            R_EmitCachedEdge;
            r_lastvertvalid := false;
            continue;
          end;
        end;
      end;
      // assume it's cacheable
      cacheoffset := Cardinal(edge_p_) - Cardinal(r_edges);
      r_leftclipped := false;
      r_rightclipped := false;
      R_ClipEdge(@mvertex_arrp(r_pcurrentvertbase)^[r_pedge^.v[1]],
        @mvertex_arrp(r_pcurrentvertbase)^[r_pedge^.v[0]], pclip);
      r_pedge^.cachededgeoffset := cacheoffset;

      if r_leftclipped then
        makeleftedge := true;
      if r_rightclipped then
        makerightedge := true;
      r_lastvertvalid := true;
    end;
  end;

  // if there was a clip off the left edge, add that edge too
  // FIXME: faster to do in screen space?
  // FIXME: share clipped edges?
  if makeleftedge then
  begin
    r_pedge := @tedge;
    r_lastvertvalid := false;
    R_ClipEdge(@r_leftexit, @r_leftenter, pclip^.next);
  end;
  // if there was a clip off the right edge, get the right r_nearzi
  if makerightedge then
  begin
    r_pedge := @tedge;
    r_lastvertvalid := false;
    r_nearzionly := true;
    R_ClipEdge(@r_rightexit, @r_rightenter, view_clipplanes[1].next);
  end;

  // if no edges made it out, return without posting the surface
  if r_emitted = 0 then
    exit;

  inc(r_polycount);

  surface_p^.msurf := fa;
  surface_p^.nearzi := r_nearzi;
  surface_p^.flags := fa^.flags;
  surface_p^.insubmodel := insubmodel;
  surface_p^.spanstate := 0;
  surface_p^.entity := currententity;
  surface_p^.key := r_currentkey;
  inc(r_currentkey);
  surface_p^.spans := nil;

  pplane := fa^.plane;

  // FIXME: cache this?
  TransformVector(pplane^.normal, p_normal);
  // FIXME: cache this?
  distinv := 1.0 / (pplane^.dist - DotProduct(modelorg, pplane^.normal));

  surface_p^.d_zistepu := p_normal[0] * xscaleinv * distinv;
  surface_p^.d_zistepv := -p_normal[1] * yscaleinv * distinv;
  surface_p^.d_ziorigin := p_normal[2] * distinv - xcenter * surface_p^.d_zistepu - ycenter * surface_p^.d_zistepv;
  inc(Integer(surface_p), SizeOf(surf_t));
end;

(*
================
R_RenderBmodelFace
================
*)

procedure R_RenderBmodelFace(pedges: bedge_p; psurf: msurface_p);
var
  i: Integer;
  mask: Cardinal;
  pplane: mplane_p;
  distinv: Single;
  p_normal: vec3_t;
  tedge: medge_t;
  pclip: clipplane_p;
begin
  if (psurf^.texinfo^.flags and (SURF_TRANS33 or SURF_TRANS66)) <> 0 then
  begin
    psurf^.nextalphasurface := r_alpha_surfaces;
    r_alpha_surfaces := psurf;
    Exit;
  end;

  // skip out if no more surfs
  if Cardinal(surface_p) >= Cardinal(surf_max) then
  begin
    inc(r_outofsurfaces);
    Exit;
  end;

  // ditto if not enough edges left, or switch to auxedges if possible
  if (Integer(edge_p_) + ((psurf^.numedges + 4) * sizeof(edge_t))) >= Integer(edge_max) then
  begin
    Inc(r_outofedges, psurf^.numedges);
    Exit;
  end;

  inc(c_faceclip);

  // this is a dummy to give the caching mechanism someplace to write to
  r_pedge := @tedge;

  // set up clip planes
  pclip := nil;

  mask := $08;
  for i := 3 downto 0 do
  begin
    if (r_clipflags and mask) <> 0 then
    begin
      view_clipplanes[i].next := pclip;
      pclip := @view_clipplanes[i];
    end;
    mask := mask shr 1;
  end;

  // push the edges through
  r_emitted := 0;
  r_nearzi := 0;
  r_nearzionly := false;
  makeleftedge := false;
  makerightedge := false;
  // FIXME: keep clipped bmodel edges in clockwise order so last vertex caching
  // can be used?
  r_lastvertvalid := false;

  while (pedges <> nil) do
  begin
    r_leftclipped := false;
    r_rightclipped := false;
    R_ClipEdge(pedges^.v[0], pedges^.v[1], pclip);

    if (r_leftclipped) then
      makeleftedge := true;
    if (r_rightclipped) then
      makerightedge := true;

    pedges := pedges^.pnext;
  end;

  // if there was a clip off the left edge, add that edge too
  // FIXME: faster to do in screen space?
  // FIXME: share clipped edges?
  if (makeleftedge) then
  begin
    r_pedge := @tedge;
    R_ClipEdge(@r_leftexit, @r_leftenter, pclip^.next);
  end;

  // if there was a clip off the right edge, get the right r_nearzi
  if makerightedge then
  begin
    r_pedge := @tedge;
    r_nearzionly := true;
    R_ClipEdge(@r_rightexit, @r_rightenter, view_clipplanes[1].next);
  end;

  // if no edges made it out, exit without posting the surface
  if r_emitted = 0 then
    exit;

  inc(r_polycount);

  surface_p^.msurf := psurf;
  surface_p^.nearzi := r_nearzi;
  surface_p^.flags := psurf^.flags;
  surface_p^.insubmodel := true;
  surface_p^.spanstate := 0;
  surface_p^.entity := currententity;
  surface_p^.key := r_currentbkey;
  surface_p^.spans := nil;

  pplane := psurf^.plane;
  // FIXME: cache this?
  TransformVector(pplane^.normal, p_normal);
  // FIXME: cache this?
  distinv := 1.0 / (pplane^.dist - DotProduct(modelorg, pplane^.normal));

  surface_p^.d_zistepu := p_normal[0] * xscaleinv * distinv;
  surface_p^.d_zistepv := -p_normal[1] * yscaleinv * distinv;
  surface_p^.d_ziorigin := p_normal[2] * distinv - xcenter * surface_p^.d_zistepu - ycenter * surface_p^.d_zistepv;

  Inc(Integer(surface_p), SizeOf(surf_t));
end;

end.
