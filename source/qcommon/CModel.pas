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
{ File(s): CModel                                                            }
{ Content: Quake2\QCommon\ model loading                                     }
{                                                                            }
{ Initial conversion by : Clootie (Alexey Barkovoy) - clootie@reactor.ru     }
{ Initial conversion on : 03-Mar-2002                                        }
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
{ * Updated:                                                                 }
{ 06-jun-2002 Juha Hartikainen (juha@linearteam.org)                         }
{ - Changed file handling to use SysUtils style of file handling             }
{----------------------------------------------------------------------------}
// cmodel.c -- model loading

{$IFDEF WIN32}
{$INCLUDE ..\Jedi.inc}
{$ELSE}
{$INCLUDE ../Jedi.inc}
{$ENDIF}

unit CModel;

interface

uses
//  DelphiTypes,
  qfiles,
  {$IFDEF WIN32}
  Windows,
  {$ENDIF}
  q_shared,
  SysUtils;


function CM_LoadMap(name: PChar; clientload: qboolean; var checksum: Cardinal): cmodel_p;
function CM_InlineModel(name: PChar): cmodel_p; // *1, *2, etc

function CM_NumClusters: Integer;
function CM_NumInlineModels: Integer;
function CM_EntityString: PChar;

// creates a clipping hull for an arbitrary box
function CM_HeadnodeForBox(const mins, maxs: vec3_t): Integer;

// returns an ORed contents mask
function CM_PointContents(const p: vec3_t; headnode: Integer): Integer;
function CM_TransformedPointContents(const p: vec3_t; headnode: Integer;
  const origin, angles: vec3_t): Integer;

function CM_BoxTrace(const start, _end, mins, maxs: vec3_t;
  headnode, brushmask: Integer): trace_t;
function CM_TransformedBoxTrace(const start, _end, mins, maxs: vec3_t;
  headnode, brushmask: Integer; const origin, angles: vec3_t): trace_t;

function CM_ClusterPVS(cluster: Integer): PByte;
function CM_ClusterPHS(cluster: Integer): PByte;

function CM_PointLeafnum(const p: vec3_t): Integer;

// call with topnode set to the headnode, returns with topnode
// set to the first node that splits the box
function CM_BoxLeafnums(var mins, maxs: vec3_t; list: PInteger;
  listsize: Integer; topnode: PInteger): Integer;

function CM_LeafContents(leafnum: Integer): Integer;
function CM_LeafCluster(leafnum: Integer): Integer;
function CM_LeafArea(leafnum: Integer): Integer;

procedure CM_SetAreaPortalState(portalnum: Integer; open: qboolean); cdecl;
function CM_AreasConnected(area1, area2: Integer): qboolean; cdecl;

function CM_WriteAreaBits(buffer: PByte; area: Integer): Integer;
function CM_HeadnodeVisible(nodenum: Integer; visbits: PByteArray): qboolean;

procedure CM_WritePortalState(var file_: integer);
procedure CM_ReadPortalState(var file_: integer);

var
  numtexinfo: Integer;
  map_surfaces: array[0..MAX_MAP_TEXINFO - 1] of mapsurface_t;
  c_pointcontents: Integer;
  c_traces, c_brush_traces: Integer;

implementation

uses
  Common,
  CPas,
  CVar,
  Files,
  MD4;

type
  cnode_p = ^cnode_t;
  cnode_t = record
    plane: cplane_p;
    children: array[0..1] of Integer;   // negative numbers are leafs
  end;

  cbrushside_p = ^cbrushside_t;
  cbrushside_t = record
    plane: cplane_p;
    surface: mapsurface_p;
  end;

  cleaf_p = ^cleaf_t;
  cleaf_t = record
    contents: Integer;
    cluster: Integer;
    area: Integer;
    firstleafbrush: Word;
    numleafbrushes: Word;
  end;

  cbrush_p = ^cbrush_t;
  cbrush_t = record
    contents: Integer;
    numsides: Integer;
    firstbrushside: Integer;
    checkcount: Integer;                // to avoid repeated testings
  end;

  carea_p = ^carea_t;
  carea_t = record
    numareaportals: Integer;
    firstareaportal: Integer;
    floodnum: Integer;                  // if two areas have equal floodnums, they are connected
    floodvalid: Integer;
  end;

var
  checkcount: Integer;

  map_name: array[0..MAX_QPATH - 1] of Char;

  numbrushsides: Integer;
  map_brushsides: array[0..MAX_MAP_BRUSHSIDES - 1] of cbrushside_t;

  numplanes: Integer;
  map_planes: array[0..MAX_MAP_PLANES + 6 - 1] of cplane_t; // extra for box hull

  numnodes: Integer;
  map_nodes: array[0..MAX_MAP_NODES + 6 - 1] of cnode_t; // extra for box hull

  numleafs: Integer = 1;                // allow leaf funcs to be called without a map
  map_leafs: array[0..MAX_MAP_LEAFS - 1] of cleaf_t;
  emptyleaf, solidleaf: Integer;

  numleafbrushes: Integer;
  map_leafbrushes: array[0..MAX_MAP_LEAFBRUSHES - 1] of Word;

  numcmodels: Integer;
  map_cmodels: array[0..MAX_MAP_MODELS - 1] of cmodel_t;

  numbrushes: Integer;
  map_brushes: array[0..MAX_MAP_BRUSHES - 1] of cbrush_t;

  numvisibility: Integer;
  map_visibility: array[0..MAX_MAP_VISIBILITY - 1] of Byte;
  map_vis: dvis_p = @map_visibility;

  numentitychars: Integer;
  map_entitystring: array[0..MAX_MAP_ENTSTRING - 1] of Char;

  numareas: Integer = 1;
  map_areas: array[0..MAX_MAP_AREAS - 1] of carea_t;

  numareaportals: Integer;

  map_areaportals: array[0..MAX_MAP_AREAPORTALS - 1] of dareaportal_t;

  numclusters: Integer = 1;

  nullsurface: mapsurface_t;

  floodvalid: Integer;

  portalopen: array[0..MAX_MAP_AREAPORTALS - 1] of qboolean;

  map_noareas: cvar_p;

procedure CM_initBoxHull; forward;
procedure FloodAreaConnections; forward;

(*
===============================================================================

     MAP LOADING

===============================================================================
*)

var
  cmod_base: PByte;

  (*
  =================
  CMod_LoadSubmodels
  =================
  *)

procedure CMod_LoadSubmodels(l: lump_p);
var
  in_: dmodel_p;
  out_: cmodel_p;
  i, j, count: Integer;
begin
  in_ := Pointer(Integer(cmod_base) + l.fileofs);

  if (l^.filelen mod SizeOf(in_^)) <> 0 then
    Com_Error(ERR_DROP, 'MOD_LoadBmodel: funny lump size', []);
  count := l^.filelen div SizeOf(in_^);

  if (count < 1) then
    Com_Error(ERR_DROP, 'Map with no models', []);
  if (count > MAX_MAP_MODELS) then
    Com_Error(ERR_DROP, 'Map has too many models', []);

  numcmodels := count;

  for i := 0 to count - 1 do
  begin
    out_ := @map_cmodels[i];

    for j := 0 to 2 do
    begin                               // spread the mins / maxs by a pixel
      out_^.mins[j] := LittleFloat(in_^.mins[j]) - 1;
      out_^.maxs[j] := LittleFloat(in_^.maxs[j]) + 1;
      out_^.origin[j] := LittleFloat(in_^.origin[j]);
    end;
    out_^.headnode := LittleLong(in_^.headnode);
    Inc(in_);
    // Inc(out_); //Clootie: - never used
  end;
end;

(*
=================
CMod_LoadSurfaces
=================
*)

procedure CMod_LoadSurfaces(l: lump_p);
var
  in_: texinfo_p;
  out_: mapsurface_p;
  i, count: Integer;
begin
  in_ := Pointer(Integer(cmod_base) + l.fileofs);

  if (l^.filelen mod SizeOf(in_^)) <> 0 then
    Com_Error(ERR_DROP, 'MOD_LoadBmodel: funny lump size', []);
  count := l^.filelen div SizeOf(in_^);
  if (count < 1) then
    Com_Error(ERR_DROP, 'Map with no surfaces', []);
  if (count > MAX_MAP_TEXINFO) then
    Com_Error(ERR_DROP, 'Map has too many surfaces', []);

  numtexinfo := count;
  out_ := @map_surfaces;

  for i := 0 to count - 1 do
  begin
    strncpy(out_^.c.name, in_^.texture, SizeOf(out_^.c.name) - 1);
    strncpy(out_^.rname, in_^.texture, SizeOf(out_^.rname) - 1);
    out_^.c.flags := LittleLong(in_^.flags);
    out_^.c.value := LittleLong(in_^.value);
    Inc(in_);
    Inc(out_);
  end;
end;

(*
=================
CMod_LoadNodes

=================
*)

procedure CMod_LoadNodes(l: lump_p);
var
  in_: dnode_p;
  child: Integer;
  out_: cnode_p;
  i, j, count: Integer;
begin
  in_ := Pointer(Integer(cmod_base) + l^.fileofs);
  if (l^.filelen mod SizeOf(in_^)) <> 0 then
    Com_Error(ERR_DROP, 'MOD_LoadBmodel: funny lump size', []);
  count := l^.filelen div SizeOf(in_^);

  if (count < 1) then
    Com_Error(ERR_DROP, 'Map has no nodes', []);
  if (count > MAX_MAP_NODES) then
    Com_Error(ERR_DROP, 'Map has too many nodes', []);

  out_ := @map_nodes;

  numnodes := count;

  for i := 0 to count - 1 do
  begin
    out_^.plane := @map_planes[LittleLong(in_^.planenum)];
    for j := 0 to 1 do
    begin
      child := LittleLong(in_^.children[j]);
      out_^.children[j] := child;
    end;
    Inc(in_);
    Inc(out_);
  end;
end;

(*
=================
CMod_LoadBrushes

=================
*)

procedure CMod_LoadBrushes(l: lump_p);
var
  in_: dbrush_p;
  out_: cbrush_p;
  i, count: Integer;
begin
  in_ := Pointer(Integer(cmod_base) + l^.fileofs);
  if (l^.filelen mod SizeOf(in_^)) <> 0 then
    Com_Error(ERR_DROP, 'MOD_LoadBmodel: funny lump size', []);
  count := l^.filelen div SizeOf(in_^);

  if (count > MAX_MAP_BRUSHES) then
    Com_Error(ERR_DROP, 'Map has too many brushes', []);

  out_ := @map_brushes;

  numbrushes := count;

  for i := 0 to count - 1 do
  begin
    out_^.firstbrushside := LittleLong(in_^.firstside);
    out_^.numsides := LittleLong(in_^.numsides);
    out_^.contents := LittleLong(in_^.contents);
    Inc(in_);
    Inc(out_);
  end;

end;

(*
=================
CMod_LoadLeafs
=================
*)

procedure CMod_LoadLeafs(l: lump_p);
var
  i: Integer;
  out_: cleaf_p;
  in_: dleaf_p;
  count: Integer;
begin
  in_ := Pointer(Integer(cmod_base) + l^.fileofs);
  if (l^.filelen mod SizeOf(in_^)) <> 0 then
    Com_Error(ERR_DROP, 'MOD_LoadBmodel: funny lump size', []);
  count := l^.filelen div SizeOf(in_^);

  if (count < 1) then
    Com_Error(ERR_DROP, 'Map with no leafs', []);
  // need to save space for box planes
  if (count > MAX_MAP_PLANES) then
    Com_Error(ERR_DROP, 'Map has too many planes', []);

  out_ := @map_leafs;
  numleafs := count;
  numclusters := 0;

  for i := 0 to count - 1 do
  begin
    out_^.contents := LittleLong(in_^.contents);
    out_^.cluster := LittleShort(in_^.cluster);
    out_^.area := LittleShort(in_^.area);
    out_^.firstleafbrush := LittleShort(in_^.firstleafbrush);
    out_^.numleafbrushes := LittleShort(in_^.numleafbrushes);

    if (out_^.cluster >= numclusters) then
      numclusters := out_^.cluster + 1;
    Inc(in_);
    Inc(out_);
  end;

  if (map_leafs[0].contents <> CONTENTS_SOLID) then
    Com_Error(ERR_DROP, 'Map leaf 0 is not CONTENTS_SOLID', []);
  solidleaf := 0;
  emptyleaf := -1;
  for i := 1 to numleafs - 1 do
  begin
    if (map_leafs[i].contents = 0) then
    begin
      emptyleaf := i;
      Break;
    end;
  end;
  if (emptyleaf = -1) then
    Com_Error(ERR_DROP, 'Map does not have an empty leaf', []);
end;

(*
=================
CMod_LoadPlanes
=================
*)

procedure CMod_LoadPlanes(l: lump_p);
var
  i, j: Integer;
  out_: cplane_p;
  in_: dplane_p;
  count: Integer;
  bits: Integer;
begin
  in_ := Pointer(Integer(cmod_base) + l^.fileofs);
  if (l^.filelen mod SizeOf(in_^)) <> 0 then
    Com_Error(ERR_DROP, 'MOD_LoadBmodel: funny lump size', []);
  count := l^.filelen div SizeOf(in_^);

  if (count < 1) then
    Com_Error(ERR_DROP, 'Map with no planes', []);
  // need to save space for box planes
  if (count > MAX_MAP_PLANES) then
    Com_Error(ERR_DROP, 'Map has too many planes', []);

  out_ := @map_planes;
  numplanes := count;

  for i := 0 to count - 1 do
  begin
    bits := 0;
    for j := 0 to 2 do
    begin
      out_^.normal[j] := LittleFloat(in_^.normal[j]);
      if (out_^.normal[j] < 0) then
        bits := bits or (1 shl j);
    end;

    out_^.dist := LittleFloat(in_^.dist);
    out_^._type := LittleLong(in_^._type);
    out_^.signbits := bits;
    Inc(in_);
    Inc(out_);
  end;
end;

(*
=================
CMod_LoadLeafBrushes
=================
*)

procedure CMod_LoadLeafBrushes(l: lump_p);
var
  i: Integer;
  out_: PWord;
  in_: PWord;
  count: Integer;
begin
  in_ := Pointer(Integer(cmod_base) + l^.fileofs);
  if (l^.filelen mod SizeOf(in_^)) <> 0 then
    Com_Error(ERR_DROP, 'MOD_LoadBmodel: funny lump size', []);
  count := l^.filelen div SizeOf(in_^);

  if (count < 1) then
    Com_Error(ERR_DROP, 'Map with no planes', []);
  // need to save space for box planes
  if (count > MAX_MAP_LEAFBRUSHES) then
    Com_Error(ERR_DROP, 'Map has too many leafbrushes', []);

  out_ := @map_leafbrushes;
  numleafbrushes := count;

  for i := 0 to count - 1 do
  begin
    out_^ := LittleShort(in_^);
    Inc(in_);
    Inc(out_);
  end;
end;

(*
=================
CMod_LoadBrushSides
=================
*)

procedure CMod_LoadBrushSides(l: lump_p);
var
  i, j: Integer;
  out_: cbrushside_p;
  in_: dbrushside_p;
  count: Integer;
  num: Integer;
begin
  in_ := Pointer(Integer(cmod_base) + l^.fileofs);
  if (l^.filelen mod SizeOf(in_^)) <> 0 then
    Com_Error(ERR_DROP, 'MOD_LoadBmodel: funny lump size', []);
  count := l^.filelen div SizeOf(in_^);

  // need to save space for box planes
  if (count > MAX_MAP_BRUSHSIDES) then
    Com_Error(ERR_DROP, 'Map has too many planes', []);

  out_ := @map_brushsides;
  numbrushsides := count;

  for i := 0 to count - 1 do
  begin
    num := LittleShort(in_^.planenum);
    out_^.plane := @map_planes[num];
    j := LittleShort(in_^.texinfo);
    if (j >= numtexinfo) then
      Com_Error(ERR_DROP, 'Bad brushside texinfo', []);
    out_^.surface := @map_surfaces[j];
    Inc(in_);
    Inc(out_);
  end;
end;

(*
=================
CMod_LoadAreas
=================
*)

procedure CMod_LoadAreas(l: lump_p);
var
  i: Integer;
  out_: carea_p;
  in_: darea_p;
  count: Integer;
begin
  in_ := Pointer(Integer(cmod_base) + l^.fileofs);
  if (l .filelen mod SizeOf(in_^)) <> 0 then
    Com_Error(ERR_DROP, 'MOD_LoadBmodel: funny lump size', []);
  count := l^.filelen div SizeOf(in_^);

  if (count > MAX_MAP_AREAS) then
    Com_Error(ERR_DROP, 'Map has too many areas', []);

  out_ := @map_areas;
  numareas := count;

  for i := 0 to count - 1 do
  begin
    out_^.numareaportals := LittleLong(in_^.numareaportals);
    out_^.firstareaportal := LittleLong(in_^.firstareaportal);
    out_^.floodvalid := 0;
    out_^.floodnum := 0;
    Inc(in_);
    Inc(out_);
  end;
end;

(*
=================
CMod_LoadAreaPortals
=================
*)

procedure CMod_LoadAreaPortals(l: lump_p);
var
  i: Integer;
  out_: dareaportal_p;
  in_: dareaportal_p;
  count: Integer;
begin
  in_ := Pointer(Integer(cmod_base) + l^.fileofs);
  if (l^.filelen mod SizeOf(in_^)) <> 0 then
    Com_Error(ERR_DROP, 'MOD_LoadBmodel: funny lump size', []);
  count := l^.filelen div SizeOf(in_^);

  if (count > MAX_MAP_AREAS) then
    Com_Error(ERR_DROP, 'Map has too many areas', []);

  out_ := @map_areaportals;
  numareaportals := count;

  for i := 0 to count - 1 do
  begin
    out_^.portalnum := LittleLong(in_^.portalnum);
    out_^.otherarea := LittleLong(in_^.otherarea);
    Inc(in_);
    Inc(out_);
  end;
end;

(*
=================
CMod_LoadVisibility
=================
*)

procedure CMod_LoadVisibility(l: lump_p);
var
  i: Integer;
begin
  numvisibility := l^.filelen;
  if (l^.filelen > MAX_MAP_VISIBILITY) then
    Com_Error(ERR_DROP, 'Map has too large visibility lump', []);

  Move(Pointer(Integer(cmod_base) + l^.fileofs)^, map_visibility, l^.filelen);

  map_vis^.numclusters := LittleLong(map_vis^.numclusters);
  for i := 0 to map_vis^.numclusters - 1 do
  begin
    map_vis^.bitofs[i][0] := LittleLong(map_vis^.bitofs[i][0]);
    map_vis^.bitofs[i][1] := LittleLong(map_vis^.bitofs[i][1]);
  end;
end;

(*
=================
CMod_LoadEntityString
=================
*)

procedure CMod_LoadEntityString(l: lump_p);
begin
  numentitychars := l^.filelen;
  if (l^.filelen > MAX_MAP_ENTSTRING) then
    Com_Error(ERR_DROP, 'Map has too large entity lump', []);

  Move(Pointer(Cardinal(cmod_base) + l^.fileofs)^, map_entitystring, l^.filelen);
end;

(*
==================
CM_LoadMap

Loads in the map and all submodels
==================
*)

function CM_LoadMap(name: PChar; clientload: qboolean; var checksum: Cardinal): cmodel_p;
var
  buf: PCardinal;
  i: Integer;
  header: dheader_t;
  length: Integer;
{$IFDEF COMPILER6_UP}{$WRITEABLECONST ON}{$ENDIF}
const
  last_checksum: Cardinal = 0;
{$IFDEF COMPILER6_UP}{$WRITEABLECONST OFF}{$ENDIF}
begin
  map_noareas := Cvar_Get('map_noareas', '0', 0);

  if (strcmp(map_name, name) = 0) and
    (clientload or (Cvar_VariableValue('flushmap') = 0)) then
  begin
    checksum := last_checksum;
    if not clientload then
    begin
      FillChar(portalopen, SizeOf(portalopen), 0);
      FloodAreaConnections;
    end;
    Result := @map_cmodels[0];          // still have the right version
    Exit;
  end;

  // free old stuff
  numplanes := 0;
  numnodes := 0;
  numleafs := 0;
  numcmodels := 0;
  numvisibility := 0;
  numentitychars := 0;
  map_entitystring[0] := #0;
  map_name[0] := #0;

  if (name = nil) or (name[0] = #0) then
  begin
    numleafs := 1;
    numclusters := 1;
    numareas := 1;
    checksum := 0;
    Result := @map_cmodels[0];          // cinematic servers won't have anything at all
    Exit;
  end;

  //
  // load the file
  //
  length := FS_LoadFile(name, @buf);
  if (buf = nil) then
    Com_Error(ERR_DROP, 'Couldn''t load %s', [name]);

  last_checksum := LittleLong(Com_BlockChecksum(buf, length));
  checksum := last_checksum;

  header := dheader_p(buf)^;
  for i := 0 to (SizeOf(dheader_t) div 4) - 1 do
    PCardinalArray(@header)[i] := LittleLong(PCardinalArray(@header)[i]);

  if (header.version <> BSPVERSION) then
    Com_Error(ERR_DROP, 'CMod_LoadBrushModel: %s has wrong version number (%d should be %d)',
      [name, header.version, BSPVERSION]);

  cmod_base := PByte(buf);

  // load into heap
  CMod_LoadSurfaces(@header.lumps[LUMP_TEXINFO]);
  CMod_LoadLeafs(@header.lumps[LUMP_LEAFS]);
  CMod_LoadLeafBrushes(@header.lumps[LUMP_LEAFBRUSHES]);
  CMod_LoadPlanes(@header.lumps[LUMP_PLANES]);
  CMod_LoadBrushes(@header.lumps[LUMP_BRUSHES]);
  CMod_LoadBrushSides(@header.lumps[LUMP_BRUSHSIDES]);
  CMod_LoadSubmodels(@header.lumps[LUMP_MODELS]);
  CMod_LoadNodes(@header.lumps[LUMP_NODES]);
  CMod_LoadAreas(@header.lumps[LUMP_AREAS]);
  CMod_LoadAreaPortals(@header.lumps[LUMP_AREAPORTALS]);
  CMod_LoadVisibility(@header.lumps[LUMP_VISIBILITY]);
  CMod_LoadEntityString(@header.lumps[LUMP_ENTITIES]);

  FS_FreeFile(buf);

  CM_initBoxHull;

  FillChar(portalopen, SizeOf(portalopen), 0);
  FloodAreaConnections;

  StrCopy(map_name, name);

  Result := @map_cmodels[0];
end;

(*
==================
CM_inlineModel
==================
*)

function CM_inlineModel(name: PChar): cmodel_p;
var
  num: Integer;
begin
  if (name = nil) or (name[0] <> '*') then
    Com_Error(ERR_DROP, 'CM_InlineModel: bad name', []);
  num := atoi(name + 1);
  if (num < 1) or (num >= numcmodels) then
    Com_Error(ERR_DROP, 'CM_InlineModel: bad number', []);

  Result := @map_cmodels[num];
end;

function CM_NumClusters: Integer;
begin
  Result := numclusters;
end;

function CM_NumInlineModels: Integer;
begin
  Result := numcmodels;
end;

function CM_EntityString: PChar;
begin
  Result := map_entitystring;
end;

function CM_LeafContents(leafnum: Integer): Integer;
begin
  if (leafnum < 0) or (leafnum >= numleafs) then
    Com_Error(ERR_DROP, 'CM_LeafContents: bad number', []);
  Result := map_leafs[leafnum].contents;
end;

function CM_LeafCluster(leafnum: Integer): Integer;
begin
  if (leafnum < 0) or (leafnum >= numleafs) then
    Com_Error(ERR_DROP, 'CM_LeafCluster: bad number', []);
  Result := map_leafs[leafnum].cluster;
end;

function CM_LeafArea(leafnum: Integer): Integer;
begin
  if (leafnum < 0) or (leafnum >= numleafs) then
    Com_Error(ERR_DROP, 'CM_LeafArea: bad number', []);
  Result := map_leafs[leafnum].area;
end;

//=======================================================================

type
  cplane_pa = ^cplane_ta;
  cplane_ta = array[0..MaxInt div SizeOf(cplane_t) - 1] of cplane_t;

var
  box_planes: cplane_pa;
  box_headnode: Integer;
  box_brush: cbrush_p;
  box_leaf: cleaf_p;

  (*
  ===================
  CM_InitBoxHull

  Set up the planes and nodes so that the six floats of a bounding box
  can just be stored out and get a proper clipping hull structure.
  ===================
  *)

procedure CM_InitBoxHull;
var
  i: Integer;
  side: Integer;
  c: cnode_p;
  p: cplane_p;
  s: cbrushside_p;
begin
  box_headnode := numnodes;
  box_planes := @map_planes[numplanes];
  if (numnodes + 6 > MAX_MAP_NODES) or
    (numbrushes + 1 > MAX_MAP_BRUSHES) or
    (numleafbrushes + 1 > MAX_MAP_LEAFBRUSHES) or
    (numbrushsides + 6 > MAX_MAP_BRUSHSIDES) or
    (numplanes + 12 > MAX_MAP_PLANES) then
    Com_Error(ERR_DROP, 'Not enough room for box tree', []);

  box_brush := @map_brushes[numbrushes];
  box_brush.numsides := 6;
  box_brush.firstbrushside := numbrushsides;
  box_brush.contents := CONTENTS_MONSTER;

  box_leaf := @map_leafs[numleafs];
  box_leaf.contents := CONTENTS_MONSTER;
  box_leaf.firstleafbrush := numleafbrushes;
  box_leaf.numleafbrushes := 1;

  map_leafbrushes[numleafbrushes] := numbrushes;

  for i := 0 to 5 do
  begin
    side := i and 1;

    // brush sides
    s := @map_brushsides[numbrushsides + i];
    s^.plane := @map_planes[numplanes + i * 2 + side];
    s^.surface := @nullsurface;

    // nodes
    c := @map_nodes[box_headnode + i];
    c^.plane := @map_planes[numplanes + i * 2];
    c^.children[side] := -1 - emptyleaf;
    if (i <> 5) then
      c^.children[side xor 1] := box_headnode + i + 1
    else
      c^.children[side xor 1] := -1 - numleafs;

    // planes
    p := @box_planes[i * 2];
    p^._type := i shr 1;
    p^.signbits := 0;
    VectorClear(p^.normal);
    p^.normal[i shr 1] := 1;

    p := @box_planes[i * 2 + 1];
    p^._type := 3 + (i shr 1);
    p^.signbits := 0;
    VectorClear(p^.normal);
    p^.normal[i shr 1] := -1;
  end;
end;

(*
===================
CM_HeadnodeForBox

To keep everything totally uniform, bounding boxes are turned into small
BSP trees instead of being compared directly.
===================
*)

function CM_HeadnodeForBox(const mins, maxs: vec3_t): Integer;
begin
  box_planes[0].dist := maxs[0];
  box_planes[1].dist := -maxs[0];
  box_planes[2].dist := mins[0];
  box_planes[3].dist := -mins[0];
  box_planes[4].dist := maxs[1];
  box_planes[5].dist := -maxs[1];
  box_planes[6].dist := mins[1];
  box_planes[7].dist := -mins[1];
  box_planes[8].dist := maxs[2];
  box_planes[9].dist := -maxs[2];
  box_planes[10].dist := mins[2];
  box_planes[11].dist := -mins[2];

  Result := box_headnode;
end;

(*
==================
CM_PointLeafnum_r

==================
*)

function CM_PointLeafnum_r(const p: vec3_t; num: Integer): Integer;
var
  d: Single;
  node: cnode_p;
  plane: cplane_p;
begin
  while (num >= 0) do
  begin
    node := @map_nodes[num];
    plane := node^.plane;

    if (plane^._type < 3) then
      d := p[plane^._type] - plane^.dist
    else
      d := DotProduct(plane^.normal, p) - plane^.dist;

    if (d < 0) then
      num := node^.children[1]
    else
      num := node^.children[0];
  end;

  Inc(c_pointcontents);                 // optimize counter

  Result := -1 - num;
end;

function CM_PointLeafnum(const p: vec3_t): Integer;
begin
  if (numplanes = 0) then
    Result := 0                         // sound may call this without map loaded
  else
    Result := CM_PointLeafnum_r(p, 0);
end;

(*
=============
CM_BoxLeafnums

Fills in a list of all the leafs touched
=============
*)

var
  leaf_count, leaf_maxcount: Integer;
  leaf_list: PIntegerArray;
  leaf_mins, leaf_maxs: vec3_p;
  leaf_topnode: Integer;

procedure CM_BoxLeafnums_r(nodenum: Integer);
var
  plane: cplane_p;
  node: cnode_p;
  s: Integer;
begin
  while True do
  begin
    if (nodenum < 0) then
    begin
      if (leaf_count >= leaf_maxcount) then
      begin
        //   Com_Printf ('CM_BoxLeafnums_r: overflow'#10);
        Exit;
      end;
      leaf_list[leaf_count] := -1 - nodenum;
      Inc(leaf_count);
      Exit;
    end;

    node := @map_nodes[nodenum];
    plane := node.plane;
    //   s = BoxOnPlaneSide (leaf_mins, leaf_maxs, plane);
    s := BOX_ON_PLANE_SIDE(leaf_mins^, leaf_maxs^, plane);
    if (s = 1) then
      nodenum := node.children[0]
    else if (s = 2) then
      nodenum := node.children[1]
    else
    begin                               // go down both
      if (leaf_topnode = -1) then
        leaf_topnode := nodenum;
      CM_BoxLeafnums_r(node.children[0]);
      nodenum := node.children[1];
    end;
  end;
end;

function CM_BoxLeafnums_headnode(var mins, maxs: vec3_t;
  list: PIntegerArray; listsize, headnode: Integer; topnode: PInteger): Integer;
begin
  leaf_list := list;
  leaf_count := 0;
  leaf_maxcount := listsize;
  leaf_mins := @mins;
  leaf_maxs := @maxs;

  leaf_topnode := -1;

  CM_BoxLeafnums_r(headnode);

  if (topnode <> nil) then
    topnode^ := leaf_topnode;

  Result := leaf_count;
end;

function CM_BoxLeafnums(var mins, maxs: vec3_t; list: PInteger;
  listsize: Integer; topnode: PInteger): Integer;
begin
  Result := CM_BoxLeafnums_headnode(mins, maxs, PIntegerArray(list), listsize,
    map_cmodels[0].headnode, topnode);
end;

(*
==================
CM_PointContents

==================
*)

function CM_PointContents(const p: vec3_t; headnode: Integer): Integer;
var
  l: Integer;
begin
  if (numnodes = 0) then                // map not loaded
  begin
    Result := 0;
    Exit;
  end;

  l := CM_PointLeafnum_r(p, headnode);

  Result := map_leafs[l].contents;
end;

(*
==================
CM_TransformedPointContents

Handles offseting and rotation of the end points for moving and
rotating entities
==================
*)

function CM_TransformedPointContents(const p: vec3_t; headnode: Integer;
  const origin, angles: vec3_t): Integer;
var
  p_l: vec3_t;
  temp: vec3_t;
  forward_, right, up: vec3_t;
  l: Integer;
begin
  // subtract origin offset
  VectorSubtract(p, origin, p_l);

  // rotate start and end into the models frame of reference
  if (headnode <> box_headnode) and
    ((angles[0] <> 0) or (angles[1] <> 0) or (angles[2] <> 0)) then
  begin
    AngleVectors(angles, @forward_, @right, @up);

    VectorCopy(p_l, temp);
    p_l[0] := DotProduct(temp, forward_);
    p_l[1] := -DotProduct(temp, right);
    p_l[2] := DotProduct(temp, up);
  end;

  l := CM_PointLeafnum_r(p_l, headnode);

  Result := map_leafs[l].contents;
end;

(*
===============================================================================

BOX TRACING

===============================================================================
*)

// 1/32 epsilon to keep floating point happy
const
  DIST_EPSILON: Single = (0.03125);

var
  trace_start, trace_end: vec3_t;
  trace_mins, trace_maxs: vec3_t;
  trace_extents: vec3_t;

  trace_trace: trace_t;
  trace_contents: Integer;
  trace_ispoint: qboolean;              // optimized case

  (*
  ================
  CM_ClipBoxToBrush
  ================
  *)

procedure CM_ClipBoxToBrush(const mins, maxs, p1, p2: vec3_t;
  trace: trace_p; brush: cbrush_p);
var
  i, j: Integer;
  plane, clipplane: cplane_p;
  dist: Single;
  enterfrac, leavefrac: Single;
  ofs: vec3_t;
  d1, d2: Single;
  getout, startout: qboolean;
  f: Single;
  side, leadside: cbrushside_p;
begin
  enterfrac := -1;
  leavefrac := 1;
  clipplane := nil;

  if (brush^.numsides = 0) then
    Exit;

  Inc(c_brush_traces);

  getout := False;
  startout := False;
  leadside := nil;

  for i := 0 to brush^.numsides - 1 do
  begin
    side := @map_brushsides[brush^.firstbrushside + i];
    plane := side^.plane;

    // FIXME: special case for axial

    if not trace_ispoint then
    begin                               // general box case
      // push the plane out apropriately for mins/maxs

      // FIXME: use signbits into 8 way lookup for each mins/maxs
      for j := 0 to 2 do
      begin
        if (plane^.normal[j] < 0) then
          ofs[j] := maxs[j]
        else
          ofs[j] := mins[j];
      end;
      dist := DotProduct(ofs, plane^.normal);
      dist := plane^.dist - dist;
    end
    else
    begin                               // special point case
      dist := plane^.dist;
    end;

    d1 := DotProduct(p1, plane^.normal) - dist;
    d2 := DotProduct(p2, plane^.normal) - dist;

    if (d2 > 0) then
      getout := True;                   // endpoint is not in solid
    if (d1 > 0) then
      startout := True;

    // if completely in front of face, no intersection
    if (d1 > 0) and (d2 >= d1) then
      Exit;

    if (d1 <= 0) and (d2 <= 0) then
      Continue;

    // crosses face
    if (d1 > d2) then
    begin                               // enter
      f := (d1 - DIST_EPSILON) / (d1 - d2);
      if (f > enterfrac) then
      begin
        enterfrac := f;
        clipplane := plane;
        leadside := side;
      end;
    end
    else
    begin                               // leave
      f := (d1 + DIST_EPSILON) / (d1 - d2);
      if (f < leavefrac) then
        leavefrac := f;
    end;
  end;

  if not startout then
  begin                                 // original point was inside brush
    trace^.startsolid := true;
    if not getout then
      trace^.allsolid := True;
    Exit;
  end;
  if (enterfrac < leavefrac) then
  begin
    if (enterfrac > -1) and (enterfrac < trace^.fraction) then
    begin
      if (enterfrac < 0) then
        enterfrac := 0;
      trace^.fraction := enterfrac;
      trace^.plane := clipplane^;
      trace^.surface := @leadside^.surface^.c;
      trace^.contents := brush^.contents;
    end;
  end;
end;

(*
================
CM_TestBoxInBrush
================
*)

procedure CM_TestBoxInBrush(const mins, maxs, p1: vec3_t;
  trace: trace_p; brush: cbrush_p);
var
  i, j: Integer;
  plane: cplane_p;
  dist: Single;
  ofs: vec3_t;
  d1: Single;
  side: cbrushside_p;
begin
  if (brush.numsides = 0) then
    Exit;

  for i := 0 to brush.numsides - 1 do
  begin
    side := @map_brushsides[brush^.firstbrushside + i];
    plane := side^.plane;

    // FIXME: special case for axial

    // general box case

    // push the plane out apropriately for mins/maxs

    // FIXME: use signbits into 8 way lookup for each mins/maxs
    for j := 0 to 2 do
    begin
      if (plane^.normal[j] < 0) then
        ofs[j] := maxs[j]
      else
        ofs[j] := mins[j];
    end;
    dist := DotProduct(ofs, plane^.normal);
    dist := plane^.dist - dist;

    d1 := DotProduct(p1, plane^.normal) - dist;

    // if completely in front of face, no intersection
    if (d1 > 0) then
      Exit;
  end;

  // inside this brush
  trace^.allsolid := True;
  trace^.startsolid := True;
  trace^.fraction := 0;
  trace^.contents := brush^.contents;
end;

(*
================
CM_TraceToLeaf
================
*)

procedure CM_TraceToLeaf(leafnum: Integer);
var
  k: Integer;
  brushnum: Integer;
  leaf: cleaf_p;
  b: cbrush_p;
begin
  leaf := @map_leafs[leafnum];
  if ((leaf.contents and trace_contents) = 0) then
    Exit;

  // trace line against all brushes in the leaf
  for k := 0 to leaf.numleafbrushes - 1 do
  begin
    brushnum := map_leafbrushes[leaf^.firstleafbrush + k];
    b := @map_brushes[brushnum];
    if (b^.checkcount = checkcount) then
      Continue;                         // already checked this brush in another leaf
    b^.checkcount := checkcount;

    if ((b^.contents and trace_contents) = 0) then
      Continue;
    CM_ClipBoxToBrush(trace_mins, trace_maxs, trace_start, trace_end, @trace_trace, b);
    if (trace_trace.fraction = 0) then
      Exit;
  end;

end;

(*
================
CM_TestInLeaf
================
*)

procedure CM_TestInLeaf(leafnum: Integer);
var
  k: Integer;
  brushnum: Integer;
  leaf: cleaf_p;
  b: cbrush_p;
begin
  leaf := @map_leafs[leafnum];
  if ((leaf^.contents and trace_contents) = 0) then
    Exit;

  // trace line against all brushes in the leaf
  for k := 0 to leaf^.numleafbrushes - 1 do
  begin
    brushnum := map_leafbrushes[leaf^.firstleafbrush + k];
    b := @map_brushes[brushnum];
    if (b^.checkcount = checkcount) then
      Continue;                         // already checked this brush in another leaf
    b^.checkcount := checkcount;

    if ((b^.contents and trace_contents) = 0) then
      Continue;
    CM_TestBoxInBrush(trace_mins, trace_maxs, trace_start, @trace_trace, b);
    if (trace_trace.fraction = 0) then
      Exit;
  end;

end;

(*
==================
CM_RecursiveHullCheck

==================
*)

procedure CM_RecursiveHullCheck(num: Integer; p1f, p2f: Single; const p1, p2: vec3_t);
var
  node: cnode_p;
  plane: cplane_p;
  t1, t2, offset: Single;
  frac, frac2: Single;
  idist: Single;
  i: Integer;
  mid: vec3_t;
  side: Integer;
  midf: Single;
begin
  if (trace_trace.fraction <= p1f) then
    Exit;                               // already hit something nearer

  // if < 0, we are in a leaf node
  if (num < 0) then
  begin
    CM_TraceToLeaf(-1 - num);
    Exit;
  end;

  //
  // find the point distances to the seperating plane
  // and the offset for the size of the box
  //
  node := @map_nodes[num];
  plane := node^.plane;

  if (plane^._type < 3) then
  begin
    t1 := p1[plane^._type] - plane^.dist;
    t2 := p2[plane^._type] - plane^.dist;
    offset := trace_extents[plane^._type];
  end
  else
  begin
    t1 := DotProduct(plane^.normal, p1) - plane^.dist;
    t2 := DotProduct(plane^.normal, p2) - plane^.dist;
    if (trace_ispoint) then
      offset := 0
    else
      offset := fabs(trace_extents[0] * plane^.normal[0]) +
        fabs(trace_extents[1] * plane^.normal[1]) +
        fabs(trace_extents[2] * plane^.normal[2]);
  end;

  {
  CM_RecursiveHullCheck (node->children[0], p1f, p2f, p1, p2);
  CM_RecursiveHullCheck (node->children[1], p1f, p2f, p1, p2);
  return;
  }
    // see which sides we need to consider
  if (t1 >= offset) and (t2 >= offset) then
  begin
    CM_RecursiveHullCheck(node^.children[0], p1f, p2f, p1, p2);
    Exit;
  end;
  if (t1 < -offset) and (t2 < -offset) then
  begin
    CM_RecursiveHullCheck(node^.children[1], p1f, p2f, p1, p2);
    Exit;
  end;

  // put the crosspoint DIST_EPSILON pixels on the near side
  if (t1 < t2) then
  begin
    idist := 1.0 / (t1 - t2);
    side := 1;
    frac2 := (t1 + offset + DIST_EPSILON) * idist;
    frac := (t1 - offset + DIST_EPSILON) * idist;
  end
  else if (t1 > t2) then
  begin
    idist := 1.0 / (t1 - t2);
    side := 0;
    frac2 := (t1 - offset - DIST_EPSILON) * idist;
    frac := (t1 + offset + DIST_EPSILON) * idist;
  end
  else
  begin
    side := 0;
    frac := 1;
    frac2 := 0;
  end;

  // move up to the node
  if (frac < 0) then
    frac := 0;
  if (frac > 1) then
    frac := 1;

  midf := p1f + (p2f - p1f) * frac;
  for i := 0 to 2 do
    mid[i] := p1[i] + frac * (p2[i] - p1[i]);

  CM_RecursiveHullCheck(node^.children[side], p1f, midf, p1, mid);

  // go past the node
  if (frac2 < 0) then
    frac2 := 0;
  if (frac2 > 1) then
    frac2 := 1;

  midf := p1f + (p2f - p1f) * frac2;
  for i := 0 to 2 do
    mid[i] := p1[i] + frac2 * (p2[i] - p1[i]);

  CM_RecursiveHullCheck(node^.children[side xor 1], midf, p2f, mid, p2);
end;

//======================================================================

(*
==================
CM_BoxTrace
==================
*)

function CM_BoxTrace(const start, _end, mins, maxs: vec3_t;
  headnode, brushmask: Integer): trace_t;
var
  i: Integer;
  leafs: array[0..1023] of Integer;
  numleafs: Integer;
  c1, c2: vec3_t;
  topnode: Integer;
begin
  Inc(checkcount);                      // for multi-check avoidance

  Inc(c_traces);                        // for statistics, may be zeroed

  // fill in a default trace
  FillChar(trace_trace, SizeOf(trace_trace), 0);
  trace_trace.fraction := 1;
  trace_trace.surface := @nullsurface.c;

  if (numnodes = 0) then
  begin                                 // map not loaded
    Result := trace_trace;
    exit;
  end;

  trace_contents := brushmask;
  VectorCopy(start, trace_start);
  VectorCopy(_end, trace_end);
  VectorCopy(mins, trace_mins);
  VectorCopy(maxs, trace_maxs);

  //
  // check for position test special case
  //
  if (start[0] = _end[0]) and (start[1] = _end[1]) and (start[2] = _end[2]) then
  begin
    VectorAdd(start, mins, c1);
    VectorAdd(start, maxs, c2);
    for i := 0 to 2 do
    begin
      c1[i] := c1[i] - 1;
      c2[i] := c2[i] + 1;
    end;

    numleafs := CM_BoxLeafnums_headnode(c1, c2, @leafs, 1024, headnode, @topnode);
    for i := 0 to numleafs - 1 do
    begin
      CM_TestInLeaf(leafs[i]);
      if (trace_trace.allsolid) then
        Break;
    end;
    VectorCopy(start, trace_trace.endpos);
    Result := trace_trace;
  end;

  //
  // check for point special case
  //
  if (mins[0] = 0) and (mins[1] = 0) and (mins[2] = 0) and
    (maxs[0] = 0) and (maxs[1] = 0) and (maxs[2] = 0) then
  begin
    trace_ispoint := True;
    VectorClear(trace_extents);
  end
  else
  begin
    trace_ispoint := False;
    if (-mins[0] > maxs[0]) then
      trace_extents[0] := -mins[0]
    else
      trace_extents[0] := maxs[0];
    if (-mins[1] > maxs[1]) then
      trace_extents[1] := -mins[1]
    else
      trace_extents[1] := maxs[1];
    if (-mins[2] > maxs[2]) then
      trace_extents[2] := -mins[2]
    else
      trace_extents[2] := maxs[2];
  end;

  //
  // general sweeping through world
  //
  CM_RecursiveHullCheck(headnode, 0, 1, start, _end);

  if (trace_trace.fraction = 1) then
  begin
    VectorCopy(_end, trace_trace.endpos);
  end
  else
  begin
    for i := 0 to 2 do
      trace_trace.endpos[i] := start[i] + trace_trace.fraction * (_end[i] - start[i]);
  end;
  Result := trace_trace;
end;

(*
==================
CM_TransformedBoxTrace

Handles offseting and rotation of the end points for moving and
rotating entities
==================
*)

function CM_TransformedBoxTrace(const start, _end, mins, maxs: vec3_t;
  headnode, brushmask: Integer; const origin, angles: vec3_t): trace_t;
var
  trace: trace_t;
  start_l, end_l: vec3_t;
  a: vec3_t;
  forward_, right, up: vec3_t;
  temp: vec3_t;
  rotated: qboolean;
begin
  // subtract origin offset
  VectorSubtract(start, origin, start_l);
  VectorSubtract(_end, origin, end_l);

  // rotate start and end into the models frame of reference
  if (headnode <> box_headnode) and
    ((angles[0] <> 0) or (angles[1] <> 0) or (angles[2] <> 0)) then
    rotated := True
  else
    rotated := False;

  if (rotated) then
  begin
    AngleVectors(angles, @forward_, @right, @up);

    VectorCopy(start_l, temp);
    start_l[0] := DotProduct(temp, forward_);
    start_l[1] := -DotProduct(temp, right);
    start_l[2] := DotProduct(temp, up);

    VectorCopy(end_l, temp);
    end_l[0] := DotProduct(temp, forward_);
    end_l[1] := -DotProduct(temp, right);
    end_l[2] := DotProduct(temp, up);
  end;

  // sweep the box through the model
  trace := CM_BoxTrace(start_l, end_l, mins, maxs, headnode, brushmask);

  if rotated and (trace.fraction <> 1.0) then
  begin
    // FIXME: figure out how to do this with existing angles
    VectorNegate(angles, a);
    AngleVectors(a, @forward_, @right, @up);

    VectorCopy(trace.plane.normal, temp);
    trace.plane.normal[0] := DotProduct(temp, forward_);
    trace.plane.normal[1] := -DotProduct(temp, right);
    trace.plane.normal[2] := DotProduct(temp, up);
  end;

  trace.endpos[0] := start[0] + trace.fraction * (_end[0] - start[0]);
  trace.endpos[1] := start[1] + trace.fraction * (_end[1] - start[1]);
  trace.endpos[2] := start[2] + trace.fraction * (_end[2] - start[2]);

  Result := trace;
end;

(*
===============================================================================

PVS / PHS

===============================================================================
*)

(*
===================
CM_DecompressVis
===================
*)

procedure CM_DecompressVis(in_, out_: PByte);
var
  c: Integer;
  out_p: PByte;
  row: Integer;
begin
  row := (numclusters + 7) shr 3;
  out_p := out_;

  if (in_ = nil) or (numvisibility = 0) then
  begin                                 // no vis info, so make all visible
    while (row <> 0) do
    begin
      out_p^ := $FF;
      Inc(out_p);
      Dec(row);
    end;
    Exit;
  end;

  repeat
    if (in_^ <> 0) then
    begin
      out_p^ := in_^;
      Inc(out_p);
      Inc(in_);
      Continue;
    end;

    Inc(in_);
    c := in_^;
    Inc(in_);
    if ((Integer(out_p) - Integer(out_)) + c > row) then
    begin
      c := row - (Integer(out_p) - Integer(out_));
      Com_DPrintf('warning: Vis decompression overrun'#10, []);
    end;

    while (c <> 0) do
    begin
      out_p^ := 0;
      Inc(out_p);
      Dec(c);
    end;
  until (Integer(out_p) - Integer(out_) >= row);
end;

var
  pvsrow: array[0..MAX_MAP_LEAFS div 8 - 1] of Byte;
  phsrow: array[0..MAX_MAP_LEAFS div 8 - 1] of Byte;

function CM_ClusterPVS(cluster: Integer): PByte;
begin
  if (cluster = -1) then
    FillChar(pvsrow, (numclusters + 7) shr 3, 0)
  else
    CM_DecompressVis(@map_visibility[map_vis.bitofs[cluster][DVIS_PVS]], @pvsrow);

  Result := @pvsrow;
end;

function CM_ClusterPHS(cluster: Integer): PByte;
begin
  if (cluster = -1) then
    FillChar(phsrow, (numclusters + 7) shr 3, 0)
  else
    CM_DecompressVis(@map_visibility[map_vis.bitofs[cluster][DVIS_PHS]], @phsrow);

  Result := @phsrow;
end;

(*
===============================================================================

AREAPORTALS

===============================================================================
*)

procedure FloodArea_r(area: carea_p; floodnum: Integer);
var
  i: Integer;
  p: dareaportal_p;
begin
  if (area^.floodvalid = floodvalid) then
  begin
    if (area^.floodnum = floodnum) then
      Exit;
    Com_Error(ERR_DROP, 'FloodArea_r: reflooded', []);
  end;

  area^.floodnum := floodnum;
  area^.floodvalid := floodvalid;
  p := @map_areaportals[area^.firstareaportal];
  for i := 0 to area^.numareaportals - 1 do // i++, p++)
  begin
    if (portalopen[p^.portalnum]) then
      FloodArea_r(@map_areas[p^.otherarea], floodnum);
    Inc(p);
  end;
end;

(*
====================
FloodAreaConnections

====================
*)

procedure FloodAreaConnections;
var
  i: Integer;
  area: carea_p;
  floodnum: Integer;
begin
  // all current floods are now invalid
  Inc(floodvalid);
  floodnum := 0;

  // area 0 is not used
  for i := 1 to numareas - 1 do
  begin
    area := @map_areas[i];
    if (area^.floodvalid = floodvalid) then
      Continue;                         // already flooded into
    Inc(floodnum);
    FloodArea_r(area, floodnum);
  end;
end;

procedure CM_SetAreaPortalState(portalnum: Integer; open: qboolean);
begin
  if (portalnum > numareaportals) then
    Com_Error(ERR_DROP, 'areaportal > numareaportals', []);

  portalopen[portalnum] := open;
  FloodAreaConnections;
end;

function CM_AreasConnected(area1, area2: Integer): qboolean;
begin
  if (map_noareas.value <> 0) then
  begin
    Result := True;
    Exit;
  end;

  if (area1 > numareas) or (area2 > numareas) then
    Com_Error(ERR_DROP, 'area > numareas', []);

  if (map_areas[area1].floodnum = map_areas[area2].floodnum) then
  begin
    Result := True;
    Exit;
  end;

  Result := False;
end;

(*
=================
CM_WriteAreaBits

Writes a length byte followed by a bit vector of all the areas
that area in the same flood as the area parameter

This is used by the client refreshes to cull visibility
=================
*)

function CM_WriteAreaBits(buffer: PByte; area: Integer): Integer;
var
  i: Integer;
  floodnum: Integer;
  bytes: Integer;
  b: PByte;
begin
  bytes := (numareas + 7) shr 3;

  if (map_noareas^.value <> 0) then
  begin                                 // for debugging, send everything
    FillChar(buffer^, bytes, 255);
  end
  else
  begin
    FillChar(buffer^, bytes, 0);

    floodnum := map_areas[area].floodnum;
    for i := 0 to numareas - 1 do
    begin
      if (map_areas[i].floodnum = floodnum) or (area = 0) then
      begin
        // buffer[i>>3] |= 1<<(i&7);
        b := @PByteArray(buffer)^[i shr 3];
        b^ := b^ or (1 shl (i and 7));
      end;
    end;
  end;

  Result := bytes;
end;

(*
===================
CM_WritePortalState

Writes the portal state to a savegame file
===================
*)

procedure CM_WritePortalState(var file_: integer);
begin
  FileWrite(file_, portalopen, sizeof(portalopen));
end;

(*
===================
CM_ReadPortalState

Reads the portal state from a savegame file
and recalculates the area connections
===================
*)

procedure CM_ReadPortalState(var file_: integer);
begin
  FS_Read(@portalopen, SizeOf(portalopen), file_);
  FloodAreaConnections;
end;

(*
=============
CM_HeadnodeVisible

Returns true if any leaf under headnode has a cluster that
is potentially visible
=============
*)

function CM_HeadnodeVisible(nodenum: Integer; visbits: PByteArray): qboolean;
var
  leafnum: Integer;
  cluster: Integer;
  node: cnode_p;
begin
  if (nodenum < 0) then
  begin
    leafnum := -1 - nodenum;
    cluster := map_leafs[leafnum].cluster;
    if (cluster = -1) then
    begin
      Result := False;
      Exit;
    end;

    if (visbits[cluster shr 3] and (1 shl (cluster and 7))) <> 0 then
    begin
      Result := True;
      Exit;
    end;
    Result := false;
    Exit;
  end;

  node := @map_nodes[nodenum];
  if CM_HeadnodeVisible(node^.children[0], visbits) then
  begin
    Result := true;
    Exit;
  end;
  Result := CM_HeadnodeVisible(node^.children[1], visbits);
end;

end.
