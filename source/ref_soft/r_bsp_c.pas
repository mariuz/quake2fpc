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
{ File(s): r_bsp_c.c                                                         }
{                                                                            }
{ Initial conversion by : Diogo Teixeira - fozi_b@yahoo.com                  }
{ Initial conversion on : 20-Jan-2002                                        }
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
{ Updated on : 18-july-2002                                                  }
{ Updated by : CodeFusion (michael@skovslund.dk)                             }
{                                                                            }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{ None.                                                                      }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{ Debug an see if the code works :0)                                         }
{----------------------------------------------------------------------------}
(*
  - Initial translation by Diogo Teixeira (20/01/2002)
  NOTES:
    .i added a "// TRANSLATOR'S NOTE:" in every critical point in
     the translation, any "missing ->" points to a variable that
     is declared in some other file and should be linked here.
    .ALL_SET switch makes this compile using all the code
     that is hidden because of "missing ->".
  - Finished Initial translation in 24/01/2002
  - For any discussion about this delphi translation mail: fozi_b@yahoo.com
*)

unit r_bsp_c;

interface

uses
  qfiles,
  q_shared,
  r_local,
  ref,
  r_model;

type
  solidstate_t = (touchessolid, drawnode, nodrawnode);

const
  M_PI = 3.14159265358979323846;
  MAX_BMODEL_VERTS = 500; // 6K
  MAX_BMODEL_EDGES = 1000; // 12K

//
// current entity info
//

procedure R_RotateBmodel;
procedure R_DrawSolidClippedSubmodelPolygons(pmodel: model_p; topnode: mnode_p);
procedure R_DrawSubmodelPolygons(pmodel: model_p; clipflags: Integer; topnode: mnode_p);
procedure R_RenderWorld;

var
  insubmodel: qboolean;
  currententity: entity_p;
  modelorg: vec3_t; // modelorg is the viewpoint reletive to
                      // the currently rendering entity
  r_currentbkey: Integer;
  r_entorigin: vec3_t; // the currently rendering entity in world
                      // coordinates

//===========================================================================
implementation

uses
  r_misc,
  r_rast,
  r_edge,
  DelphiTypes,
  r_main,
  SysUtils;

var
  entity_rotation: matrix33;
  pbverts: mvertex_p;
  pbedges: bedge_p;
  numbverts: Integer;
  numbedges: Integer;
  pfrontenter: mvertex_p;
  pfrontexit: mvertex_p;
  makeclippededge: qboolean;
  c_drawnode: Integer;

(*
================
R_EntityRotate
================
*)

procedure R_EntityRotate(var vec: vec3_t);
var
  tvec: vec3_t;
begin
  VectorCopy(vec, tvec);
  vec[0] := DotProduct(vec3_p(@entity_rotation[0])^, tvec);
  vec[1] := DotProduct(vec3_p(@entity_rotation[1])^, tvec);
  vec[2] := DotProduct(vec3_p(@entity_rotation[2])^, tvec);
end;

(*
================
R_RotateBmodel
================
*)

procedure R_RotateBmodel;
var
  angle: Single;
  s, c: Single;
  temp1: matrix33;
  temp2: matrix33;
  temp3: matrix33;
begin
// TODO: should use a look-up table
// TODO: should really be stored with the entity instead of being reconstructed
// TODO: could cache lazily, stored in the entity
// TODO: share work with R_SetUpAliasTransform

// yaw
  angle := currententity^.angles[YAW];
  angle := angle * M_PI * 2 / 360;
  s := sin(angle);
  c := cos(angle);

  temp1[0, 0] := c;
  temp1[0, 1] := s;
  temp1[0, 2] := 0.0;
  temp1[1, 0] := -s;
  temp1[1, 1] := c;
  temp1[1, 2] := 0.0;
  temp1[2, 0] := 0.0;
  temp1[2, 1] := 0.0;
  temp1[2, 2] := 1;

// pitch
  angle := currententity^.angles[PITCH];
  angle := angle * M_PI * 2 / 360;
  s := sin(angle);
  c := cos(angle);

  temp2[0, 0] := c;
  temp2[0, 1] := 0.0;
  temp2[0, 2] := -s;
  temp2[1, 0] := 0.0;
  temp2[1, 1] := 1;
  temp2[1, 2] := 0.0;
  temp2[2, 0] := s;
  temp2[2, 1] := 0.0;
  temp2[2, 2] := c;

  R_ConcatRotations(temp2, temp1, temp3);

// roll
  angle := currententity^.angles[ROLL];
  angle := angle * M_PI * 2 / 360;
  s := sin(angle);
  c := cos(angle);

  temp1[0, 0] := 1;
  temp1[0, 1] := 0.0;
  temp1[0, 2] := 0.0;
  temp1[1, 0] := 0.0;
  temp1[1, 1] := c;
  temp1[1, 2] := s;
  temp1[2, 0] := 0.0;
  temp1[2, 1] := -s;
  temp1[2, 2] := c;

  R_ConcatRotations(temp1, temp3, entity_rotation);

//
// rotate modelorg and the transformation matrix
//
  R_EntityRotate(modelorg);
  R_EntityRotate(vpn);
  R_EntityRotate(vright);
  R_EntityRotate(vup);

  R_TransformFrustum;
end;

(*
================
R_RecursiveClipBPoly

Clip a bmodel poly down the world bsp tree
================
*)

procedure R_RecursiveClipBPoly(pedges: bedge_p; pnode: mnode_p; psurf: msurface_p);
var
  psideedges: array[0..1] of bedge_p;
  pnextedge: bedge_p;
  ptedge: bedge_p;
  i, side: Integer;
  lastside: Integer;
  dist, frac: Single;
  lastdist: Single;
  splitplane: mplane_p;
  tplane: mplane_t;
  pvert: mvertex_p;
  plastvert: mvertex_p;
  ptvert: mvertex_p;
  pn: mnode_p;
  area: Integer;
begin
  psideedges[0] := nil;
  psideedges[1] := nil;

  makeclippededge := false;

// transform the BSP plane into model space
// FIXME: cache these?
  splitplane := pnode^.plane;
  tplane.dist := splitplane^.dist - DotProduct(r_entorigin, splitplane^.normal);
  tplane.normal[0] := DotProduct(vec3_p(@entity_rotation[0, 0])^, splitplane^.normal);
  tplane.normal[1] := DotProduct(vec3_p(@entity_rotation[1, 0])^, splitplane^.normal);
  tplane.normal[2] := DotProduct(vec3_p(@entity_rotation[2, 0])^, splitplane^.normal);

// clip edges to BSP plane
//   for ( ; pedges ; pedges = pnextedge)
  while (pedges <> nil) do
  begin
    pnextedge := pedges^.pnext;
 // set the status for the last point as the previous point
 // FIXME: cache this stuff somehow?
    plastvert := pedges^.v[0];
    lastdist := DotProduct(plastvert^.position, tplane.normal) - tplane.dist;

    if (lastdist > 0) then
      lastside := 0
    else
      lastside := 1;

    pvert := pedges^.v[1];

    dist := DotProduct(pvert^.position, tplane.normal) - tplane.dist;

    if (dist > 0) then
      side := 0
    else
      side := 1;

    if (side <> lastside) then
    begin
  // clipped
      if (numbverts >= MAX_BMODEL_VERTS) then
        Exit;

  // generate the clipped vertex
      frac := lastdist / (lastdist - dist);
//         ptvert = &pbverts[numbverts++];
      ptvert := mvertex_p(Integer(pbverts) + (numbverts * SizeOf(mvertex_t)));
      Inc(numbverts, 1);
         ptvert^.position[0] := plastvert^.position[0] +
                                  frac * (pvert^.position[0] -
                                  plastvert^.position[0]);
         ptvert^.position[1] := plastvert^.position[1] +
                                  frac * (pvert^.position[1] -
                                  plastvert^.position[1]);
         ptvert^.position[2] := plastvert^.position[2] +
                                  frac * (pvert^.position[2] -
                                  plastvert^.position[2]);

      // split into two edges, one on each side, and remember entering
      // and exiting points
      // FIXME: share the clip edge by having a winding direction flag?
         if (numbedges >= (MAX_BMODEL_EDGES - 1)) then
         begin
            ri.Con_Printf(PRINT_ALL,'Out of edges for bmodel');
            Exit;
         end;

         ptedge := bedge_p(Integer(pbedges)+(numbedges*SizeOf(bedge_t)));
         ptedge^.pnext := psideedges[lastside];
         psideedges[lastside] := ptedge;
         ptedge^.v[0] := plastvert;
         ptedge^.v[1] := ptvert;
         Inc(numbedges);

         ptedge := bedge_p(Integer(pbedges)+(numbedges*SizeOf(bedge_t)));
         ptedge^.pnext := psideedges[side];
         psideedges[side] := ptedge;
         ptedge^.v[0] := ptvert;
         ptedge^.v[1] := pvert;
         Inc(numbedges);

         if (side = 0) then
         begin
         // entering for front, exiting for back
            pfrontenter := ptvert;
            makeclippededge := true;
         end
         else
         begin
            pfrontexit := ptvert;
            makeclippededge := true;
         end
      end
      else
      begin
      // add the edge to the appropriate side
         pedges^.pnext := psideedges[side];
         psideedges[side] := pedges;
      end;
      pedges := pnextedge;
   end;

// if anything was clipped, reconstitute and add the edges along the clip
// plane to both sides (but in opposite directions)
  if (makeclippededge) then
  begin
    if (numbedges >= (MAX_BMODEL_EDGES - 2)) then
    begin
      ri.Con_Printf(PRINT_ALL, 'Out of edges for bmodel' + #13#10);
      Exit;
    end;

    ptedge := bedge_p(Integer(pbedges) + (numbedges * SizeOf(bedge_t)));
    ptedge^.pnext := psideedges[0];
    psideedges[0] := ptedge;
    ptedge^.v[0] := pfrontexit;
    ptedge^.v[1] := pfrontenter;
    Inc(numbedges);

    ptedge := bedge_p(Integer(pbedges) + (numbedges * SizeOf(bedge_t)));
    ptedge^.pnext := psideedges[1];
    psideedges[1] := ptedge;
    ptedge^.v[0] := pfrontenter;
    ptedge^.v[1] := pfrontexit;
    Inc(numbedges);
  end;

// draw or recurse further
  for I := 0 to 1 do
  begin
    if (psideedges[i] <> nil) then
    begin
  // draw if we've reached a non-solid leaf, done if all that's left is a
  // solid leaf, and continue down the tree if it's not a leaf
      pn := pnode^.children[i];

  // we're done with this branch if the node or leaf isn't in the PVS
      if (pn^.visframe = r_visframecount) then
      begin
        if (pn^.contents <> CONTENTS_NODE) then
        begin
          if (pn^.contents <> CONTENTS_SOLID) then
          begin
            if (r_newrefdef.areabits <> nil) then
            begin
              area := mleaf_p(pn)^.area;
              if ((PByte(Integer(r_newrefdef.areabits) + (area shr 3))^ and (1 shl (area and 7))) = 0) then
                continue; // not visible
            end;
            r_currentbkey := mleaf_p(pn)^.key;
            R_RenderBmodelFace(psideedges[i], psurf);
          end;
        end
        else
        begin
          R_RecursiveClipBPoly(psideedges[i], pnode^.children[i], psurf);
        end;
      end;
    end;
  end;
end;

(*
================
R_DrawSolidClippedSubmodelPolygons

Bmodel crosses multiple leafs
================
*)
procedure R_DrawSolidClippedSubmodelPolygons(pmodel : model_p; topnode : mnode_p);
var
   i, j, lindex  : Integer;
   dot           : vec_t;
   psurf         : msurface_p;
   numsurfaces   : Integer;
   pplane        : mplane_p;
   bverts        : array[0..MAX_BMODEL_VERTS] of mvertex_t;
   bedges        : array[0..MAX_BMODEL_EDGES] of bedge_t;
  pbedge        : bedge_p;
   pedge         : medge_p;
  pedges        : medge_p;
begin
// FIXME: use bounding-box-based frustum clipping info?

  psurf := @msurface_arrp(pmodel^.surfaces)^[pmodel^.firstmodelsurface];
//   psurf := msurface_p(Integer(pmodel^.surfaces)+(pmodel^.firstmodelsurface*SizeOf(msurface_t)));
  numsurfaces := pmodel^.nummodelsurfaces;
  pedges := pmodel^.edges;

//   for (i=0 ; i<numsurfaces ; i++, psurf++)
  for I := 0 to numsurfaces - 1 do
  begin
 // find which side of the node we are on
    pplane := psurf^.plane;

    dot := DotProduct(modelorg, pplane^.normal) - pplane^.dist;

 // draw the polygon
    if (((psurf^.flags and SURF_PLANEBACK) = 0) and (dot < -BACKFACE_EPSILON)) or
      (((psurf^.flags and SURF_PLANEBACK) <> 0) and (dot > BACKFACE_EPSILON)) then
    begin
      //psurf := msurface_p(Integer(psurf)+SizeOf(msurface_t));
      Inc(Integer(psurf), SizeOf(msurface_t));
      continue;
    end;
 // FIXME: use bounding-box-based frustum clipping info?

 // copy the edges to bedges, flipping if necessary so always
 // clockwise winding
 // FIXME: if edges and vertices get caches, these assignments must move
 // outside the loop, and overflow checking must be done here
    pbverts := @bverts;
    pbedges := @bedges;
    numbverts := 0;
    numbedges := 0;
    pbedge := @bedges[numbedges];
    Inc(numbedges, psurf^.numedges);

    for j := 0 to psurf^.numedges-1 do
      begin // check here.
      lindex := PIntegerArray(pmodel^.surfedges)^[psurf^.firstedge+j];
         if (lindex > 0) then
         begin
        pedge := @medge_arrp(pedges)^[lindex];
        PBedge_tArray(pbedge)^[j].v[0] := @mvertex_arrp(r_pcurrentvertbase)^[pedge^.v[0]];
        PBedge_tArray(pbedge)^[j].v[1] := @mvertex_arrp(r_pcurrentvertbase)^[pedge^.v[1]];
         end
         else
         begin
            lindex := abs(lindex);
        pedge := @medge_arrp(pedges)^[lindex];
        PBedge_tArray(pbedge)^[j].v[0] := @mvertex_arrp(r_pcurrentvertbase)^[pedge^.v[0]];
        PBedge_tArray(pbedge)^[j].v[1] := @mvertex_arrp(r_pcurrentvertbase)^[pedge^.v[1]];
      end;
      PBedge_tArray(pbedge)^[j].pnext := @PBedge_tArray(pbedge)^[j + 1];
    end;
    PBedge_tArray(pbedge)^[psurf^.numedges - 1].pnext := nil; // mark end of edges

    if ((psurf^.texinfo^.flags and (SURF_TRANS66 or SURF_TRANS33)) = 0) then
      R_RecursiveClipBPoly(pbedge, topnode, psurf)
    else
      R_RenderBmodelFace(pbedge, psurf);

    Inc(Integer(psurf), SizeOf(msurface_t));
  end;
end;

(*
================
R_DrawSubmodelPolygons

All in one leaf
================
*)

procedure R_DrawSubmodelPolygons(pmodel: model_p; clipflags: Integer; topnode: mnode_p);
var
  i: Integer;
  dot: vec_t;
  psurf: msurface_p;
  numsurfaces: Integer;
  pplane: mplane_p;
begin
// FIXME: use bounding-box-based frustum clipping info?
  psurf := @msurface_arrp(pmodel^.surfaces)^[pmodel^.firstmodelsurface];
  numsurfaces := pmodel^.nummodelsurfaces;

//   for (i=0 ; i<numsurfaces ; i++, psurf++)
  for I := 0 to numsurfaces - 1 do
  begin
 // find which side of the node we are on
    pplane := psurf^.plane;

    dot := DotProduct(modelorg, pplane^.normal) - pplane^.dist;

 // draw the polygon
    if (((psurf^.flags and SURF_PLANEBACK) <> 0) and (dot < -BACKFACE_EPSILON)) or
      (((psurf^.flags and SURF_PLANEBACK) = 0) and (dot > BACKFACE_EPSILON)) then
    begin
      r_currentkey := mleaf_p(topnode)^.key;

  // FIXME: use bounding-box-based frustum clipping info?
      R_RenderFace(psurf, clipflags);
    end;
    Inc(Integer(psurf), SizeOf(msurface_t));
  end;
end;

(*
================
R_RecursiveWorldNode
================
*)

procedure R_RecursiveWorldNode(node: mnode_p; clipflags: Integer);
var
  i, c, side: Integer;
  pindex: PInteger;
  acceptpt: vec3_t;
  rejectpt: vec3_t;
  plane: mplane_p;
  surf: msurface_p;
  mark: msurface_pp;
  d, dot: Single;
  pleaf: mleaf_p;
begin

  if (node^.contents = CONTENTS_SOLID) then
    Exit; // solid

  if (node^.visframe <> r_visframecount) then
    Exit;

// cull the clipping planes if not trivial accept
// FIXME: the compiler is doing a lousy job of optimizing here; it could be
//  twice as fast in ASM
  if (clipflags <> 0) then
  begin
    for I := 0 to 3 do
      begin
         if ((clipflags and (1 shl i)) = 0) then
            continue;   // don't need to clip against it

      // generate accept and reject points
      // FIXME: do with fast look-ups or integer tests based on the sign bit
      // of the floating point values

         pindex := pfrustum_indexes[i];

         rejectpt[0] := node^.minmaxs[PIntegerArray(pindex)^[0]];
         rejectpt[1] := node^.minmaxs[PIntegerArray(pindex)^[1]];
         rejectpt[2] := node^.minmaxs[PIntegerArray(pindex)^[2]];

         d := DotProduct(rejectpt, view_clipplanes[i].normal);
         d := d - view_clipplanes[i].dist;
         if (d <= 0) then
            Exit;
         acceptpt[0] := node^.minmaxs[PIntegerArray(pindex)^[3]];
         acceptpt[1] := node^.minmaxs[PIntegerArray(pindex)^[4]];
         acceptpt[2] := node^.minmaxs[PIntegerArray(pindex)^[5]];

         d := DotProduct(acceptpt, view_clipplanes[i].normal);
         d := d - view_clipplanes[i].dist;

         if (d >= 0) then
            clipflags := clipflags and ($FFFFFFFF xor (1 shl i));   // node is entirely on screen
      end;
   end;

  Inc(c_drawnode);

// if a leaf node, draw stuff
  if (node^.contents <> -1) then
  begin
    pleaf := mleaf_p(node);

  // check for door connected areas
    if (r_newrefdef.areabits <> nil) then
    begin
      if ((PByteArray(r_newrefdef.areabits)^[pleaf^.area shr 3] and (1 shl (pleaf^.area and 7))) = 0) then
        Exit; // not visible
    end;

    mark := pleaf^.firstmarksurface;
    c := pleaf^.nummarksurfaces;

    if (c <> 0) then
    begin
      while (c <> 0) do
      begin
        (mark^)^.visframe := r_framecount;
        Inc(Integer(mark), Sizeof(msurface_p));
        Dec(c);
      end;
    end;

    pleaf^.key := r_currentkey;
    Inc(r_currentkey); // all bmodels in a leaf share the same key
  end
  else
  begin
 // node is just a decision point, so go down the apropriate sides

 // find which side of the node we are on
    plane := node^.plane;

    case (plane^._type) of
      PLANE_X:
        dot := modelorg[0] - plane^.dist;
      PLANE_Y:
        dot := modelorg[1] - plane^.dist;
      PLANE_Z:
        dot := modelorg[2] - plane^.dist;
    else
      dot := DotProduct(modelorg, plane^.normal) - plane^.dist;
    end;

    if (dot >= 0.0) then
      side := 0
    else
      side := 1;

 // recurse down the children, front side first
    R_RecursiveWorldNode(node^.children[side], clipflags);

 // draw stuff
    c := node^.numsurfaces;

    if (c <> 0) then
    begin
      surf := @msurface_arrp(r_worldmodel^.surfaces)^[node^.firstsurface];
      if (dot < -BACKFACE_EPSILON) then
      begin
        while (c <> 0) do
        begin
          if (((surf^.flags and SURF_PLANEBACK) <> 0) and (surf^.visframe = r_framecount)) then
          begin
            R_RenderFace(surf, clipflags);
          end;
          Inc(Integer(surf), SizeOf(msurface_t));
          Dec(c);
        end;
      end
      else
      begin
        if (dot > BACKFACE_EPSILON) then
        begin
          while (c <> 0) do
          begin
            if (((surf^.flags and SURF_PLANEBACK) = 0) and (surf^.visframe = r_framecount)) then
            begin
              R_RenderFace(surf, clipflags);
            end;
            Inc(Integer(surf), SizeOf(msurface_t));
            Dec(c);
          end;
        end;
      end;
  // all surfaces on the same node share the same sequence number
      Inc(r_currentkey);
    end;

 // recurse down the back side
    R_RecursiveWorldNode(node^.children[side xor 1], clipflags);
  end;
end;

(*
================
R_RenderWorld
================
*)

procedure R_RenderWorld;
begin
  if (r_drawworld^.value = 0.0) then
    Exit;
  if (r_newrefdef.rdflags and RDF_NOWORLDMODEL) <> 0 then
    Exit;

  c_drawnode := 0;

 // auto cycle the world frame for texture animation
  r_worldentity.frame := Trunc(r_newrefdef.time * 2);
  currententity := @r_worldentity;

  VectorCopy(r_origin, modelorg);
  currentmodel := r_worldmodel;
  r_pcurrentvertbase := currentmodel^.vertexes;

  R_RecursiveWorldNode(currentmodel^.nodes, 15);
end;

end.
