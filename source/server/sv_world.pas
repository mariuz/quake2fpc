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

{$ALIGN ON}{$MINENUMSIZE 4}
{----------------------------------------------------------------------------}
{                                                                            }
{ File(s): server\sv_world.c                                                 }
{                                                                            }
{ Initial conversion by : Juha Hartikainen (juha@linearteam.org)             }
{ Initial conversion on : 02-Jun-2002                                        }
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
unit sv_world;

// world.c -- world query functions

interface

uses
  DelphiTypes,
  SysUtils,
  Common,
  GameUnit,
  q_shared,
  Server;

type
  areanode_p = ^areanode_t;
  areanode_t = record
    axis: Integer;                      // -1 = leaf node
    dist: Single;
    children: array[0..1] of areanode_p; // to areanode_t;
    trigger_edicts: link_t;
    solid_edicts: link_t;
  end;

function SV_HullForEntity(ent: edict_p): Integer; cdecl;
procedure SV_ClearWorld; cdecl;
procedure SV_LinkEdict(ent: edict_p); cdecl;
procedure SV_UnlinkEdict(ent: edict_p); cdecl;
function SV_AreaEdicts(mins, maxs: vec3_p; list: Parea_list;
  maxcount, areatype: Integer): Integer; cdecl;

function SV_Trace(start, mins, maxs, end_: vec3_p; passedict: edict_p; contentmask: Integer): trace_t; cdecl;

function SV_PointContents(const p: vec3_t): Integer; cdecl;

const
  AREA_DEPTH = 4;
  AREA_NODES = 32;

var
  sv_areanodes: array[0..AREA_NODES - 1] of areanode_t;
  sv_numareanodes: Integer;

  area_mins, area_maxs: PSingleArray;
  area_list: Parea_list;
  area_count, area_maxcount: Integer;
  area_type: Integer;

implementation

uses
  game_add,
  CModel,
  sv_game,
  sv_init;

function EDICT_FROM_AREA(l: pointer): edict_p;
begin
  Result := edict_p(Integer(l) - Integer(@edict_p(0)^.area));
end;

// ClearLink is used for new headnodes

procedure ClearLink(l: link_p);
begin
  l^.next := l;
  l^.prev := l^.next;
end;

procedure RemoveLink(l: link_p);
begin
  l^.next^.prev := l^.prev;
  l^.prev^.next := l^.next;
end;

procedure InsertLinkBefore(l: link_p; before: link_p);
begin
  l^.next := before;
  l^.prev := before^.prev;
  l^.prev^.next := l;
  l^.next^.prev := l;
end;

(*
===============
SV_CreateAreaNode

Builds a uniformly subdivided tree for the given world size
===============
*)

function SV_CreateAreaNode(depth: Integer; mins, maxs: vec3_p): areanode_p;
var
  anode: areanode_p;
  size, mins1, maxs1, mins2, maxs2: vec3_t;
begin
  anode := @sv_areanodes[sv_numareanodes];
  Inc(sv_numareanodes);

  ClearLink(@anode^.trigger_edicts);
  ClearLink(@anode^.solid_edicts);

  if (depth = AREA_DEPTH) then
  begin
    anode^.axis := -1;
    anode^.children[1] := nil;
    anode^.children[0] := anode^.children[1];
    Result := anode;
    Exit;
  end;

  VectorSubtract(maxs^, mins^, size);
  if (size[0] > size[1]) then
    anode^.axis := 0
  else
    anode^.axis := 1;

  anode^.dist := 0.5 * (maxs[anode^.axis] + mins[anode^.axis]);
  VectorCopy(mins^, mins1);
  VectorCopy(mins^, mins2);
  VectorCopy(maxs^, maxs1);
  VectorCopy(maxs^, maxs2);

  mins2[anode^.axis] := anode^.dist;
  maxs1[anode^.axis] := mins2[anode^.axis];

  anode^.children[0] := SV_CreateAreaNode(depth + 1, @mins2, @maxs2);
  anode^.children[1] := SV_CreateAreaNode(depth + 1, @mins1, @maxs1);

  Result := anode;
end;

(*
===============
SV_ClearWorld

===============
*)

procedure SV_ClearWorld;
begin
  FillChar(sv_areanodes, SizeOf(sv_areanodes), 0);
  sv_numareanodes := 0;
  SV_CreateAreaNode(0, @sv.models[1].mins, @sv.models[1].maxs);
end;

(*
===============
SV_UnlinkEdict

===============
*)

procedure SV_UnlinkEdict(ent: edict_p); cdecl;
begin
  if (ent^.area.prev = nil) then
    Exit;                               // not linked in anywhere
  RemoveLink(@ent^.area);
  ent^.area.next := nil;
  ent^.area.prev := ent^.area.next;
end;

(*
===============
SV_LinkEdict

===============
*)
const
  MAX_TOTAL_ENT_LEAFS = 128;

type
  TMaxLeafsArray = array[0..MAX_TOTAL_ENT_LEAFS - 1] of Integer;

procedure SV_LinkEdict(ent: edict_p);
var
  node: areanode_p;
  leafs: TMaxLeafsArray;
  clusters: TMaxLeafsArray;
  num_leafs: Integer;
  i, j, k: Integer;
  area: Integer;
  topnode: Integer;
  max, v: Single;
begin
  if (ent.area.prev <> nil) then
    SV_UnlinkEdict(ent);                // unlink from old position

  if (ent = ge^.edicts) then
    Exit;                               // don't add the world

  if (not ent^.inuse) then
    Exit;

  // set the size
  VectorSubtract(ent^.maxs, ent^.mins, ent^.size);

  // encode the size into the entity_state for client prediction
  if (ent^.solid = SOLID_BBOX) and ((ent^.svflags and SVF_DEADMONSTER) = 0) then
  begin
    // assume that x/y are equal and symetric
    i := Trunc(ent^.maxs[0] / 8);
    if (i < 1) then
      i := 1;

    if (i > 31) then
      i := 31;

    // z is not symetric
    j := Trunc((-ent^.mins[2]) / 8);
    if (j < 1) then
      j := 1;

    if (j > 31) then
      j := 31;

    // and z maxs can be negative...
    k := Trunc((ent^.maxs[2] + 32) / 8);
    if (k < 1) then
      k := 1;

    if (k > 63) then
      k := 63;

    ent^.s.solid := (k shl 10) or (j shl 5) or i;
  end
  else if (ent^.solid = SOLID_BSP) then
  begin
    ent^.s.solid := 31;                 // a solid_bbox will never create this value
  end
  else
    ent^.s.solid := 0;

  // set the abs box
  if ((ent^.solid = SOLID_BSP) and
    ((ent^.s.angles[0] <> 0) or (ent^.s.angles[1] <> 0) or (ent^.s.angles[2] <> 0))) then
  begin
    // expand for rotation
    max := 0;
    for i := 0 to 2 do
    begin
      v := fabs(ent^.mins[i]);
      if (v > max) then
        max := v;
      v := fabs(ent^.maxs[i]);
      if (v > max) then
        max := v;
    end;
    for i := 0 to 2 do
    begin
      ent^.absmin[i] := ent^.s.origin[i] - max;
      ent^.absmax[i] := ent^.s.origin[i] + max;
    end;
  end
  else
  begin
    // normal
    VectorAdd(ent^.s.origin, ent^.mins, ent^.absmin);
    VectorAdd(ent^.s.origin, ent^.maxs, ent^.absmax);
  end;

  // because movement is clipped an epsilon away from an actual edge,
  // we must fully check even when bounding boxes don't quite touch
  ent^.absmin[0] := ent^.absmin[0] - 1;
  ent^.absmin[1] := ent^.absmin[1] - 1;
  ent^.absmin[2] := ent^.absmin[2] - 1;
  ent^.absmax[0] := ent^.absmax[0] + 1;
  ent^.absmax[1] := ent^.absmax[1] + 1;
  ent^.absmax[2] := ent^.absmax[2] + 1;

  // link to PVS leafs
  ent^.num_clusters := 0;
  ent^.areanum := 0;
  ent^.areanum2 := 0;

  //get all leafs, including solids
  num_leafs := CM_BoxLeafnums(ent^.absmin, ent^.absmax, @leafs,
    MAX_TOTAL_ENT_LEAFS, @topnode);

  // set areas
  for i := 0 to (num_leafs - 1) do
  begin
    clusters[i] := CM_LeafCluster(leafs[i]);
    area := CM_LeafArea(leafs[i]);
    if (area <> 0) then
    begin
      // doors may legally straggle two areas,
      // but nothing should evern need more than that
      if (ent^.areanum <> 0) and (ent^.areanum <> area) then
      begin
        if (ent^.areanum2 <> 0) and (ent^.areanum2 <> area) and (sv.state = ss_loading) then
          Com_DPrintf('Object touching 3 areas at %f %f %f'#10, [
            ent^.absmin[0], ent^.absmin[1], ent^.absmin[2]]);

        ent^.areanum2 := area;
      end
      else
        ent^.areanum := area;
    end;
  end;

  if (num_leafs >= MAX_TOTAL_ENT_LEAFS) then
  begin
    // assume we missed some leafs, and mark by headnode
    ent^.num_clusters := -1;
    ent^.headnode := topnode;
  end
  else
  begin
    ent^.num_clusters := 0;
    for i := 0 to (num_leafs - 1) do
    begin
      if (clusters[i] = -1) then
        Continue;                       // not a visible leaf

      j := 0;
      while j < i do
      begin
        if (clusters[j] = clusters[i]) then
          Break;
        Inc(j);
      end;

      if (j = i) then
      begin
        if (ent^.num_clusters = MAX_ENT_CLUSTERS) then
        begin
          // assume we missed some leafs, and mark by headnode
          ent^.num_clusters := -1;
          ent^.headnode := topnode;
          Break;
        end;

        ent^.clusternums[ent^.num_clusters] := clusters[i];
        Inc(ent^.num_clusters);
      end;
    end;
  end;

  // if first time, make sure old_origin is valid
  if (ent^.linkcount = 0) then
  begin
    VectorCopy(ent^.s.origin, ent^.s.old_origin);
  end;

  Inc(ent^.linkcount);

  if (ent^.solid = SOLID_NOT) then
    Exit;

  // find the first node that the ent's box crosses
  node := @sv_areanodes;
  while (True) do
  begin
    if (node^.axis = -1) then
      Break;
    if (ent^.absmin[node^.axis] > node^.dist) then
      node := node^.children[0]
    else if (ent^.absmax[node^.axis] < node^.dist) then
      node := node^.children[1]
    else
      Break;                            // crosses the node
  end;

  // link it in
  if (ent^.solid = SOLID_TRIGGER) then
    InsertLinkBefore(@ent^.area, @node^.trigger_edicts)
  else
    InsertLinkBefore(@ent^.area, @node^.solid_edicts);
end;

(*
====================
SV_AreaEdicts_r

====================
*)

procedure SV_AreaEdicts_r(node: areanode_p);
var
  l, next, start: link_p;
  check: edict_p;
  //  count: Integer;
begin
  //  count := 0;

    // touch linked edicts
  if (area_type = AREA_SOLID) then
    start := @node.solid_edicts
  else
    start := @node.trigger_edicts;

  l := start^.next;
  while l <> start do
  begin
    next := l^.next;
    check := EDICT_FROM_AREA(l);

    if (check^.solid = SOLID_NOT) then
    begin
      l := next;
      Continue;                         // deactivated
    end;
    if ((check^.absmin[0] > area_maxs^[0]) or
      (check^.absmin[1] > area_maxs^[1]) or
      (check^.absmin[2] > area_maxs^[2]) or
      (check^.absmax[0] < area_mins^[0]) or
      (check^.absmax[1] < area_mins^[1]) or
      (check^.absmax[2] < area_mins^[2])) then
    begin
      l := next;
      Continue;                         // not touching
    end;

    if (area_count = area_maxcount) then
    begin
      Com_Printf('SV_AreaEdicts: MAXCOUNT'#10, []);
      Exit;
    end;

    area_list^[area_count] := check;
    Inc(area_count);

    l := next;
  end;

  if (node^.axis = -1) then
    Exit;                               // terminal node

  // recurse down both sides
  if (area_maxs^[node^.axis] > node^.dist) then
    SV_AreaEdicts_r(node^.children[0]);

  if (area_mins^[node^.axis] < node^.dist) then
    SV_AreaEdicts_r(node^.children[1]);
end;

(*
================
SV_AreaEdicts
================
*)

function SV_AreaEdicts(mins, maxs: vec3_p; list: Parea_list;
  maxcount, areatype: Integer): Integer;
begin
  area_mins := PSingleArray(mins);
  area_maxs := PSingleArray(maxs);
  area_list := list;
  area_count := 0;
  area_maxcount := maxcount;
  area_type := areatype;

  SV_AreaEdicts_r(@sv_areanodes);

  Result := area_count;
end;

//===========================================================================

(*
=============
SV_PointContents
=============
*)
type
  TEdictArr = array[0..MAX_EDICTS - 1] of edict_p;
  PEdictArr = ^TEdictArr;

function SV_PointContents(const p: vec3_t): Integer;
var
  touch: TEdictArr;
  hit: edict_p;
  i, num: Integer;
  contents, c2: Integer;
  headnode: Integer;
  angles: PSingleArray;
begin
  // get base contents from world
  contents := CM_PointContents(p, sv.models[1].headnode);

  // or in contents from all the other entities
  num := SV_AreaEdicts(@p, @p, Parea_list(@touch), MAX_EDICTS, AREA_SOLID);

  for i := 0 to (num - 1) do
  begin
    hit := touch[i];

    // might intersect, so do an exact clip
    headnode := SV_HullForEntity(hit);
    angles := @hit^.s.angles;
    if (hit^.solid <> SOLID_BSP) then
      angles := @vec3_origin;           // boxes don't rotate

    c2 := CM_TransformedPointContents(p, headnode, hit^.s.origin, hit^.s.angles);

    contents := contents or c2;
  end;

  Result := contents;
end;

type
  moveclip_p = ^moveclip_t;
  moveclip_t = record
    boxmins, boxmaxs: vec3_t;           // enclose the test object along entire move
    mins, maxs: PSingleArray;           // size of the moving object
    mins2, maxs2: vec3_t;               // size when clipping against mosnters
    start, end_: PSingleArray;
    trace: trace_t;
    passedict: edict_p;
    contentmask: Integer;
  end;

  (*
  ================
  SV_HullForEntity

  Returns a headnode that can be used for testing or clipping an
  object of mins/maxs size.
  Offset is filled in to contain the adjustment that must be added to the
  testing object's origin to get a point to use with the returned hull.
  ================
  *)

function SV_HullForEntity(ent: edict_p): Integer;
var
  model: cmodel_p;
begin
  // decide which clipping hull to use, based on the size
  if (ent^.solid = SOLID_BSP) then
  begin
    // explicit hulls in the BSP model
    model := sv.models[ent^.s.modelindex];

    if (model = nil) then
      Com_Error(ERR_FATAL, 'MOVETYPE_PUSH with a non bsp model', []);

    Result := model^.headnode;
    Exit;
  end;

  // create a temp hull from bounding box sizes

  Result := CM_HeadnodeForBox(ent^.mins, ent^.maxs);
end;

//===========================================================================

(*
====================
SV_ClipMoveToEntities

====================
*)

procedure SV_ClipMoveToEntities(clip: moveclip_p);
var
  i, num: Integer;
  touchlist: TEdictArr;
  touch: edict_p;
  trace: trace_t;
  headnode: Integer;
  angles: PSingleArray;
begin
  num := SV_AreaEdicts(@clip.boxmins, @clip.boxmaxs, Parea_list(@touchlist), MAX_EDICTS,
    AREA_SOLID);

  // be careful, it is possible to have an entity in this
  // list removed before we get to it (killtriggered)
  for i := 0 to (num - 1) do
  begin
    touch := touchlist[i];
    if (touch^.solid = SOLID_NOT) then
      Continue;
    if (touch = clip^.passedict) then
      Continue;
    if (clip^.trace.allsolid) then
      Exit;
    if (clip^.passedict <> nil) then
    begin
      if (touch^.owner = clip^.passedict) then
        Continue;                       // don't clip against own missiles
      if (clip^.passedict^.owner = touch) then
        Continue;                       // don't clip against owner
    end;

    if ((clip^.contentmask and CONTENTS_DEADMONSTER = 0) and
      ((touch^.svflags and SVF_DEADMONSTER) <> 0)) then
      Continue;

    // might intersect, so do an exact clip
    headnode := SV_HullForEntity(touch);
    angles := @touch^.s.angles;
    if (touch^.solid <> SOLID_BSP) then
      angles := @vec3_origin;           // boxes don't rotate

    if (touch^.svflags and SVF_MONSTER) <> 0 then
      trace := CM_TransformedBoxTrace(vec3_p(clip^.start)^, vec3_p(clip^.end_)^,
        clip^.mins2, clip^.maxs2, headnode, clip^.contentmask,
        touch^.s.origin, vec3_p(angles)^)
    else
      trace := CM_TransformedBoxTrace(vec3_p(clip^.start)^, vec3_p(clip^.end_)^,
        vec3_p(clip^.mins)^, vec3_p(clip^.maxs)^, headnode, clip^.contentmask,
        touch^.s.origin, vec3_p(angles)^);

    if ((trace.allsolid) or (trace.startsolid) or
      (trace.fraction < clip^.trace.fraction)) then
    begin
      trace.ent := touch;
      if (clip^.trace.startsolid) then
      begin
        clip^.trace := trace;
        clip^.trace.startsolid := true;
      end
      else
        clip^.trace := trace;
    end
    else if (trace.startsolid) then
      clip^.trace.startsolid := true;
  end;
end;

(*
==================
SV_TraceBounds
==================
*)

procedure SV_TraceBounds(var start, mins, maxs, end_, boxmins, boxmaxs: vec3_t);
var
  i: Integer;
begin
  {
    // debug to test against everything
    boxmins[2] := -9999;
    boxmins[1] := boxmins[2];
    boxmins[0] := boxmins[1];

    boxmaxs[2] := 9999;
    boxmaxs[1] := boxmaxs[2];
    boxmaxs[0] := boxmaxs[1];
  }
  for i := 0 to 2 do
  begin
    if (end_[i] > start[i]) then
    begin
      boxmins[i] := start[i] + mins[i] - 1;
      boxmaxs[i] := end_[i] + maxs[i] + 1;
    end
    else
    begin
      boxmins[i] := end_[i] + mins[i] - 1;
      boxmaxs[i] := start[i] + maxs[i] + 1;
    end;
  end;
end;

(*
==================
SV_Trace

Moves the given mins/maxs volume through the world from start to end.

Passedict and edicts owned by passedict are explicitly not checked.

==================
*)

function SV_Trace(start, mins, maxs, end_: vec3_p; passedict: edict_p; contentmask: Integer): trace_t; cdecl;
var
  clip: moveclip_t;
begin
  if (mins = nil) then
    mins := @vec3_origin;
  if (maxs = nil) then
    maxs := @vec3_origin;

  FillChar(clip, SizeOf(moveclip_t), 0);

  // clip to world
  clip.trace := CM_BoxTrace(start^, end_^, mins^, maxs^, 0, contentmask);
  clip.trace.ent := ge^.edicts;
  if (clip.trace.fraction = 0) then
  begin
    Result := clip.trace;               // blocked by the world
    Exit;
  end;

  clip.contentmask := contentmask;
  clip.start := PSingleArray(start);
  clip.end_ := PSingleArray(end_);
  clip.mins := PSingleArray(mins);
  clip.maxs := PSingleArray(maxs);
  clip.passedict := passedict;

  VectorCopy(mins^, clip.mins2);
  VectorCopy(maxs^, clip.maxs2);

  // create the bounding box of the entire move
  SV_TraceBounds(start^, clip.mins2, clip.maxs2, end_^, clip.boxmins, clip.boxmaxs);

  // clip to other solid entities
  SV_ClipMoveToEntities(@clip);

  Result := clip.trace;
end;

end.
