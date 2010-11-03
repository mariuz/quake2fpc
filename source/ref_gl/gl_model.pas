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
{ File(s): gl_model.c - model loading and caching                            }
{                                                                            }
{ Initial conversion by : YgriK (Igor Karpov) - glYgriK@hotbox.ru            }
{ Initial conversion on : 03-Apr-2002                                        }
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
{ 28.06.2003 Juha: Proofreaded }
unit gl_model;

interface

uses
  q_shared,
  gl_local_add,
  gl_local,
  gl_model_h,
  ref;

var
  loadmodel: model_p;


function Mod_PointInLeaf(const p: vec3_t; model: model_p): mleaf_p;
function Mod_ClusterPVS(cluster: integer; model: model_p): PByte;
procedure Mod_Modellist_f; cdecl;
procedure Mod_Init;

procedure R_BeginRegistration(model: PChar); cdecl;
function R_RegisterModel(name: PChar): pointer; cdecl;
procedure R_EndRegistration; cdecl;

procedure Mod_FreeAll;

var
  registration_sequence: Integer;

implementation

uses
  DelphiTypes,
  SysUtils,
  q_shwin,
  CPas,
  qfiles,
  gl_rmain,
  gl_image,
  gl_warp,
  gl_rsurf;


procedure Mod_Free(_mod: model_p); forward;


var
  modfilelen: integer;


procedure Mod_LoadBrushModel(_mod: model_p; buffer: pointer); forward;
procedure Mod_LoadAliasModel(_mod: model_p; buffer: pointer); forward;
procedure Mod_LoadSpriteModel(_mod: model_p; buffer: pointer); forward;

const
  MAX_MOD_KNOWN = 512;


var
  mod_novis: array[0..MAX_MAP_LEAFS div 8 - 1] of byte;
  mod_known: array[0..MAX_MOD_KNOWN - 1] of model_t;
  mod_numknown: integer;
  // the inline * models from the current map are kept seperate
  mod_inline: array[0..MAX_MOD_KNOWN - 1] of model_t;

{*
===============
Mod_PointInLeaf
===============
*}

function Mod_PointInLeaf(const p: vec3_t; model: model_p): mleaf_p;
var
  node: mnode_p;
  d: Single;
  plane: cplane_p;
begin
  if (model = nil) or (model^.nodes = nil) then
    ri.Sys_Error(ERR_DROP, 'Mod_PointInLeaf: bad model');

  node := model^.nodes;
  while (True) do
  begin
    if (node^.contents <> -1) then
    begin
      Result := mleaf_p(node);
      Exit;
    end;
    plane := node^.plane;
    d := DotProduct(p, plane^.normal) - plane^.dist;
    if (d > 0) then
      node := node^.children[0]
    else
      node := node^.children[1];
  end;

  Result := nil; // never reached
end;

{*
===================
Mod_DecompressVis
===================
*}
var
  decompressed: array[0..(MAX_MAP_LEAFS div 8) - 1] of Byte;

function Mod_DecompressVis(_in: PByte; model: model_p): PByte;
var
  c: Integer;
  _out: PByte;
  row: Integer;
begin
  row := (model^.vis^.numclusters + 7) shr 3;
  _out := @decompressed;

  if _in = nil then
  begin // no vis info, so make all visible
    while row <> 0 do
    begin
      _out^ := $FF;
      inc(_out);
      dec(row, 1);
    end;
    Result := @decompressed;
    exit;
  end;

  repeat
    if (_in^ <> 0) then
    begin
      _out^ := _in^;
      inc(_out);
      inc(_in);
      continue;
    end;
    c := PByteArray(_in)^[1];
    inc(_in, 2);
    while (c <> 0) do
    begin
      _out^ := 0;
      inc(_out);
      dec(c);
    end;
  until (Integer(_out) - Integer(@decompressed)) >= row;
  Result := @decompressed;
end;

{*
==============
Mod_ClusterPVS
==============
*}

function Mod_ClusterPVS(cluster: integer; model: model_p): PByte;
begin
  if (cluster = -1) or (model.vis = nil) then
  begin
    Result := @mod_novis;
    Exit;
  end;

  Result := Mod_DecompressVis(PByte(Integer(model^.vis) + model^.vis^.bitofs[cluster][DVIS_PVS]), model);
end;

{*
================
Mod_Modellist_f
================
*}

procedure Mod_Modellist_f;
var
  i, total: integer;
  _mod: model_p;
label
  continue_;
begin
  total := 0;
  ri.Con_Printf(PRINT_ALL, 'Loaded models:'#10, []);
  i := 0;
  _mod := @mod_known;
  while (i < mod_numknown) do
  begin
    if (_mod^.name[0] = #0) then
      goto continue_;
    ri.Con_Printf(PRINT_ALL, '%8i : %s'#10, _mod.extradatasize, _mod.name);
    Inc(total, _mod.extradatasize);
    continue_:
    Inc(_mod);
  end;
  ri.Con_Printf(PRINT_ALL, 'Total resident: %i'#10, [total]);
end;

{*
===============
Mod_Init
===============
*}

procedure Mod_Init;
begin
  memset(@mod_novis, $FF, sizeof(mod_novis));
end;

{*
==================
Mod_ForName

Loads in a model for the given name
==================
*}

function Mod_ForName(name: PChar; crash: qboolean): model_p;
var
  mod_: model_p;
  buf: PCardinal;
  i: integer;
label
  continue_;
begin
  if (name[0] = #0) then
    ri.Sys_Error(ERR_DROP, 'Mod_ForName: NULL name', []);

  //
  // inline models are grabbed only from worldmodel
  //
  if (name[0] = '*') then
  begin
    i := atoi(name + 1);
    if (i < 1) or (r_worldmodel = nil) or (i >= r_worldmodel^.numsubmodels) then
      ri.Sys_Error(ERR_DROP, 'bad inline model number', []);
    Result := @mod_inline[i];
    exit;
  end;

  //
  // search the currently loaded models
  //
  mod_ := @mod_known;
  for i := 0 to mod_numknown - 1 do
  begin
    if (mod_^.name[0] = #0) then
      goto continue_;
    if (strcmp(mod_^.name, name) = 0) then
    begin
      Result := mod_;
      exit;
    end;
    continue_:
    Inc(mod_);
  end;

  //
  // find a free model slot spot
  //
  mod_ := @mod_known;
  i := 0;
  while (i < mod_numknown) do
  begin
    if (mod_^.name[0] = #0) then
      break; // free spot
    Inc(mod_);
    Inc(i);
  end;
  if (i = mod_numknown) then
  begin
    if (mod_numknown = MAX_MOD_KNOWN) then
      ri.Sys_Error(ERR_DROP, 'mod_numknown == MAX_MOD_KNOWN');
    Inc(mod_numknown);
  end;
  strcpy(mod_^.name, name);

  //
  // load the file
  //
  modfilelen := ri.FS_LoadFile(mod_^.name, @buf);
  if (buf = nil) then
  begin
    if (crash) then
      ri.Sys_Error(ERR_DROP, 'Mod_NumForName: %s not found', mod_^.name);
    memset(@mod_^.name, 0, sizeof(mod_^.name));
    Result := nil;
    exit;
  end;

  loadmodel := mod_;

  //
  // fill it in
  //


  // call the apropriate loader

//  switch (LittleLong(*(unsigned * )buf))
  case PCardinal(buf)^ of
    IDALIASHEADER:
      begin
        loadmodel^.extradata := Hunk_Begin($200000);
        Mod_LoadAliasModel(mod_, buf);
      end;

    IDSPRITEHEADER:
      begin
        loadmodel^.extradata := Hunk_Begin($10000);
        Mod_LoadSpriteModel(mod_, buf);
      end;

    IDBSPHEADER:
      begin
        loadmodel^.extradata := Hunk_Begin($1000000);
        Mod_LoadBrushModel(mod_, buf);
      end;

  else
    ri.Sys_Error(ERR_DROP, 'Mod_NumForName: unknown fileid for %s', mod_.name);
  end; //case

  loadmodel^.extradatasize := Hunk_End();

  ri.FS_FreeFile(buf);

  Result := mod_;
end;


{*
===============================================================================

     BRUSHMODEL LOADING

===============================================================================
*}

var
  mod_base: PByte;

{*
=================
Mod_LoadLighting
=================
*}

procedure Mod_LoadLighting(l: lump_p);
begin
  if (l^.filelen = 0) then
  begin
    loadmodel^.lightdata := nil;
    Exit;
  end;
  loadmodel^.lightdata := Hunk_Alloc(l^.filelen);
  memcpy(loadmodel^.lightdata, @PByteArray(mod_base)^[l^.fileofs], l^.filelen);
end;

{*
=================
Mod_LoadVisibility
=================
*}

procedure Mod_LoadVisibility(l: lump_p);
var
  i: integer;
begin
  if (l^.filelen = 0) then
  begin
    loadmodel^.vis := nil;
    Exit;
  end;
  loadmodel^.vis := Hunk_Alloc(l^.filelen);
  memcpy(loadmodel^.vis, @PByteArray(mod_base)[l^.fileofs], l^.filelen);

  loadmodel^.vis^.numclusters := LittleLong(loadmodel^.vis^.numclusters);
  for i := 0 to loadmodel^.vis^.numclusters - 1 do
  begin
    loadmodel^.vis^.bitofs[i][0] := LittleLong(loadmodel^.vis^.bitofs[i][0]);
    loadmodel^.vis^.bitofs[i][1] := LittleLong(loadmodel^.vis^.bitofs[i][1]);
  end;
end;

{*
=================
Mod_LoadVertexes
=================
*}

procedure Mod_LoadVertexes(l: lump_p);
var
  _in: dvertex_p;
  _out: mvertex_p;
  i,
    count: integer;
begin
  _in := Pointer(Cardinal(mod_base) + l^.fileofs);
  if (l.filelen mod sizeof(_in^)) <> 0 then
    ri.Sys_Error(ERR_DROP, 'MOD_LoadBmodel: funny lump size in %s', loadmodel.name);
  count := l^.filelen div sizeof(_in^);
  _out := Hunk_Alloc(count * sizeof(_out^));

  loadmodel^.vertexes := Pointer(_out);
  loadmodel^.numvertexes := count;

  for i := 0 to count - 1 do
  begin
    _out^.position[0] := LittleFloat(_in^.point[0]);
    _out^.position[1] := LittleFloat(_in^.point[1]);
    _out^.position[2] := LittleFloat(_in^.point[2]);
    Inc(_in);
    Inc(_out);
  end;
end;

{*
=================
RadiusFromBounds
=================
*}

function RadiusFromBounds(const mins, maxs: vec3_t): Single;
var
  i: integer;
  corner: vec3_t;
begin
  for i := 0 to 2 do
    if fabs(mins[i]) > fabs(maxs[i]) then
      corner[i] := fabs(mins[i])
    else
      corner[i] := fabs(maxs[i]);

  Result := VectorLength(corner);
end;

{*
=================
Mod_LoadSubmodels
=================
*}

procedure Mod_LoadSubmodels(l: lump_p);
var
  _in: dmodel_p;
  _out: mmodel_p;
  i, j,
    count: integer;
begin
  _in := Pointer(Cardinal(mod_base) + l^.fileofs);
  if (l^.filelen mod sizeof(_in^)) <> 0 then
    ri.Sys_Error(ERR_DROP, 'MOD_LoadBmodel: funny lump size in %s', loadmodel^.name);
  count := l^.filelen div sizeof(_in^);
  _out := Hunk_Alloc(count * sizeof(_out^));

  loadmodel^.submodels := _out;
  loadmodel^.numsubmodels := count;

  for i := 0 to count - 1 do
  begin
    for j := 0 to 2 do
    begin
      // spread the mins / maxs by a pixel
      _out^.mins[j] := LittleFloat(_in^.mins[j]) - 1;
      _out^.maxs[j] := LittleFloat(_in^.maxs[j]) + 1;
      _out^.origin[j] := LittleFloat(_in^.origin[j]);
    end;
    _out^.radius := RadiusFromBounds(_out^.mins, _out^.maxs);
    _out^.headnode := LittleLong(_in^.headnode);
    _out^.firstface := LittleLong(_in^.firstface);
    _out^.numfaces := LittleLong(_in^.numfaces);
    Inc(_in);
    Inc(_out);
  end;
end;

{*
=================
Mod_LoadEdges
=================
*}

procedure Mod_LoadEdges(l: lump_p);
var
  _in: dedge_p;
  _out: medge_p;
  i,
    count: integer;
begin
  _in := Pointer(Cardinal(mod_base) + l^.fileofs);
  if (l^.filelen mod sizeof(_in^)) <> 0 then
    ri.Sys_Error(ERR_DROP, 'MOD_LoadBmodel: funny lump size in %s', loadmodel.name);
  count := l^.filelen div sizeof(_in^);
  _out := Hunk_Alloc((count + 1) * sizeof(_out^));

  loadmodel^.edges := Pointer(_out);
  loadmodel^.numedges := count;

  for i := 0 to count - 1 do
  begin
    _out^.v[0] := word(LittleShort(_in^.v[0]));
    _out^.v[1] := word(LittleShort(_in^.v[1]));
    Inc(_in);
    Inc(_out);
  end;
end;

{*
=================
Mod_LoadTexinfo
=================
*}

procedure Mod_LoadTexinfo(l: lump_p);
var
  _in: texinfo_p;
  _out,
    step: mtexinfo_p;
  i, j,
    count: integer;
  name: array[0..MAX_QPATH - 1] of char;
  next: integer;
begin
  _in := Pointer(Cardinal(mod_base) + l^.fileofs);
  if (l^.filelen mod sizeof(_in^)) <> 0 then
    ri.Sys_Error(ERR_DROP, 'MOD_LoadBmodel: funny lump size in %s', loadmodel.name);
  count := l^.filelen div sizeof(_in^);
  _out := Hunk_Alloc(count * sizeof(_out^));

  loadmodel^.texinfo := _out;
  loadmodel^.numtexinfo := count;

  for i := 0 to count - 1 do
  begin
    for j := 0 to 7 do
      _out^.vecs[0][j] := LittleFloat(_in^.vecs[0][j]);

    _out^.flags := LittleLong(_in.flags);
    next := LittleLong(_in.nexttexinfo);
    if (next > 0) then
      _out.next := Pointer(Cardinal(loadmodel.texinfo) + next * sizeof(mTexInfo_t))
    else
      _out.next := nil;
    Com_sprintf(name, sizeof(name), 'textures/%s.wal', [_in.texture]);

    _out.image := GL_FindImage(name, it_wall);
    if (_out.image = nil) then
    begin
      ri.Con_Printf(PRINT_ALL, 'Couldn''t load %s'#10, name);
      _out.image := r_notexture;
    end;
    Inc(_in);
    Inc(_out);
  end;

  // count animation frames
  for i := 0 to count - 1 do
  begin
    _out := @mTexinfo_arrp(loadmodel.texinfo)^[i];
    _out^.numframes := 1;
    step := _out^.Next;
    while (step <> nil) and (step <> _out) do
    begin
      Inc(_out^.NumFrames);
      step := step^.next;
    end;
  end;
end;

{*
================
CalcSurfaceExtents

Fills in s->texturemins[] and s->extents[]
================
*}

procedure CalcSurfaceExtents(s: msurface_p);
var
  mins,
    maxs: array[0..1] of Single;
  val: Single;
  i, j, e: integer;
  v: mvertex_p;
  tex: mtexinfo_p;
  bmins,
    bmaxs: array[0..1] of integer;
begin
  mins[1] := 999999;
  mins[0] := mins[1];
  maxs[1] := -99999;
  maxs[0] := maxs[1];

  tex := s.texinfo;

  for i := 0 to s.numedges - 1 do
  begin
    e := PIntegerArray(loadmodel.surfedges)^[s.firstedge + i];
    if (e >= 0) then
      v := @loadmodel.vertexes[loadmodel.edges[e].v[0]]
    else
      v := @loadmodel.vertexes[loadmodel.edges[-e].v[1]];

    for j := 0 to 1 do
    begin
      val := v.position[0] * tex.vecs[j][0] +
        v.position[1] * tex.vecs[j][1] +
        v.position[2] * tex.vecs[j][2] +
        tex.vecs[j][3];
      if (val < mins[j]) then
        mins[j] := val;
      if (val > maxs[j]) then
        maxs[j] := val;
    end;
  end;

  for i := 0 to 1 do
  begin
    bmins[i] := Floor(mins[i] / 16);
    bmaxs[i] := Ceil(maxs[i] / 16);

    s.texturemins[i] := bmins[i] * 16;
    s.extents[i] := (bmaxs[i] - bmins[i]) * 16;

//id_soft    if ( !(tex->flags & TEX_SPECIAL) && s->extents[i] > 512 /* 256 */ )
//id_soft    ri.Sys_Error (ERR_DROP, "Bad surface extents");
  end;
end;

{*
=================
Mod_LoadFaces
=================
*}
procedure Mod_LoadFaces(l: lump_p);
var
  _in: dface_p;
  _out: msurface_p;
  i, count, surfnum,
  planenum, side,
  ti: integer;
begin
  _in := Pointer(Cardinal(mod_base) + l^.fileofs);
  if (l.filelen mod sizeof(_in^)) <> 0 then
    ri.Sys_Error(ERR_DROP, 'MOD_LoadBmodel: funny lump size in %s', loadmodel.name);
  count := l.filelen div sizeof(_in^);
  _out := Hunk_Alloc(count * sizeof(_out^));

  loadmodel.surfaces := Pointer(_out);
  loadmodel.numsurfaces := count;

  currentmodel := loadmodel;

  GL_BeginBuildingLightmaps(loadmodel);

  for surfnum := 0 to count - 1 do
  begin
    _out.firstedge := LittleLong(_in.firstedge);
    _out.numedges := LittleShort(_in.numedges);
    _out.flags := 0;
    _out.polys := nil;

    planenum := LittleShort(_in.planenum);
    side := LittleShort(_in.side);
    if (side <> 0) then
      _out.flags := _out.flags or SURF_PLANEBACK;

    _out.plane := Pointer(Cardinal(loadmodel.planes) + planenum * sizeof(cplane_t));

    ti := LittleShort(_in.texinfo);
    if (ti < 0) or (ti >= loadmodel.numtexinfo) then
      ri.Sys_Error(ERR_DROP, 'MOD_LoadBmodel: bad texinfo number', []);
    _out.texinfo := Pointer(Cardinal(loadmodel.texinfo) + ti * sizeof(mTexinfo_t));

    CalcSurfaceExtents(_out);

  // lighting info

    for i := 0 to MAXLIGHTMAPS - 1 do
      _out.styles[i] := _in.styles[i];
    i := LittleLong(_in.lightofs);
    if (i = -1) then
      _out.samples := nil
    else
      _out.samples := Pointer(Cardinal(loadmodel.lightdata) + i);

  // set the drawing flags

    if (_out.texinfo.flags and SURF_WARP) <> 0 then
    begin
      _out.flags := _out.flags or SURF_DRAWTURB;
      for i := 0 to 1 do
      begin
        _out.extents[i] := 16384;
        _out.texturemins[i] := -8192;
      end;
      GL_SubdivideSurface(_out); // cut up polygon for warps
    end;

    // create lightmaps and polygons
    if ((_out.texinfo.flags and (SURF_SKY or SURF_TRANS33 or SURF_TRANS66 or SURF_WARP)) = 0) then
      GL_CreateSurfaceLightmap(_out);

    if ((_out.texinfo.flags and SURF_WARP) = 0) then
      GL_BuildPolygonFromSurface(_out);
    Inc(_in);
    Inc(_out);
  end;

  GL_EndBuildingLightmaps();
end;

{*
=================
Mod_SetParent
=================
*}

procedure Mod_SetParent(node, parent: mnode_p);
begin
  node.parent := parent;
  if (node.contents <> -1) then
    Exit;
  Mod_SetParent(node.children[0], node);
  Mod_SetParent(node.children[1], node);
end;

{*
=================
Mod_LoadNodes
=================
*}

procedure Mod_LoadNodes(l: lump_p);
var
  i, j,
    count, p: integer;
  _in: dnode_p;
  _out: mnode_p;
begin
  _in := Pointer(Integer(mod_base) + l^.fileofs);
  if (l^.filelen mod SizeOf(_in^)) <> 0 then
    ri.Sys_Error(ERR_DROP, PChar('MOD_LoadBmodel: funny lump size in ' + string(loadmodel^.name)));
  count := Trunc(l^.filelen / sizeof(_in^));
  _out := Hunk_Alloc(count * sizeof(_out^));

  loadmodel^.nodes := _out;
  loadmodel^.numnodes := count;

  for i := 0 to count - 1 do
  begin
    for j := 0 to 2 do
    begin
      _out^.minmaxs[j] := LittleShort(_in^.mins[j]);
      _out^.minmaxs[3 + j] := LittleShort(_in^.maxs[j]);
    end;

    p := LittleLong(_in^.planenum);
    _out^.plane := @cplane_arrp(loadmodel^.planes)^[p];

    _out^.firstsurface := LittleShort(_in^.firstface);
    _out^.numsurfaces := LittleShort(_in^.numfaces);
    _out^.contents := -1; // differentiate from leafs

    for j := 0 to 1 do
    begin
      p := LittleLong(_in^.children[j]);
      if p >= 0 then
        _out^.children[j] := @mnode_arrp(loadmodel^.nodes)^[p]
      else
        _out^.children[j] := mnode_p(@mleaf_arrp(loadmodel^.leafs)^[-1 - p]); // CAK - Huh?????
    end;
    inc(_in);
    inc(_out);
  end {next i};
  Mod_SetParent(loadmodel^.nodes, nil); // sets nodes and leafs
end;

{*
=================
Mod_LoadLeafs
=================
*}

procedure Mod_LoadLeafs(l: lump_p);
var
  _in: dleaf_p;
  _out: mleaf_p;
  i, j,
    count, p: integer;
//   glpoly_t   *poly;
begin
  _in := Pointer(Cardinal(mod_base) + l^.fileofs);
  if (l.filelen mod sizeof(_in^)) <> 0 then
    ri.Sys_Error(ERR_DROP, 'MOD_LoadBmodel: funny lump size in %s', loadmodel.name);
  count := l.filelen div sizeof(_in^);
  _out := Hunk_Alloc(count * sizeof(_out^));

  loadmodel.leafs := _out;
  loadmodel.numleafs := count;

  for i := 0 to count - 1 do
  begin
    for j := 0 to 2 do
    begin
      _out^.minmaxs[j] := LittleShort(_in^.mins[j]);
      _out^.minmaxs[3 + j] := LittleShort(_in^.maxs[j]);
    end;

    _out^.contents := LittleLong(_in^.contents);
    _out^.cluster := LittleShort(_in^.cluster);
    _out^.area := LittleShort(_in^.area);

    _out^.firstmarksurface := Pointer(Integer(loadmodel^.marksurfaces) + (LittleShort(_in^.firstleafface) * Sizeof(msurface_p)));
    _out^.nummarksurfaces := LittleShort(_in^.numleaffaces);
    inc(_in);
    inc(_out);
(*
          // gl underwater warp
          if (out->contents & (CONTENTS_WATER|CONTENTS_SLIME|CONTENTS_LAVA|CONTENTS_THINWATER) )
          {
                  for (j=0 ; j<out->nummarksurfaces ; j++)
                  {
                          out->firstmarksurface[j]->flags |= SURF_UNDERWATER;
                          for (poly = out->firstmarksurface[j]->polys ; poly ; poly=poly->next)
                                  poly->flags |= SURF_UNDERWATER;
                  }
          }
*)
  end;
end;

{*
=================
Mod_LoadMarksurfaces
=================
*}

procedure Mod_LoadMarksurfaces(l: lump_p);
var
  i, j, count: integer;
  in_: PSmallInt;
  out_: msurface_pp;
begin
  in_ := Pointer(Cardinal(mod_base) + l^.fileofs);
  if (l.filelen mod sizeof(in_^)) <> 0 then
    ri.Sys_Error(ERR_DROP, 'MOD_LoadBmodel: funny lump size in %s', loadmodel.name);
  count := l.filelen div sizeof(in_^);
  out_ := Hunk_Alloc(count * sizeof(out_^));

  loadmodel.marksurfaces := out_;
  loadmodel.nummarksurfaces := count;

  for i := 0 to count - 1 do
  begin
    j := LittleShort(in_^);
    if j >= loadmodel^.numsurfaces then
      ri.Sys_Error(ERR_DROP, 'Mod_ParseMarksurfaces: bad surface number');
    out_^ := @(msurface_arrp(loadmodel^.surfaces)^[j]);
    inc(Integer(in_), SizeOf(in_^));
    inc(Integer(out_), SizeOf(out_^));
  end;
end;

{*
=================
Mod_LoadSurfedges
=================
*}

procedure Mod_LoadSurfedges(l: lump_p);
var
  i, count: integer;
  _in, _out: PInteger;
begin
  _in := Pointer(Cardinal(mod_base) + l^.fileofs);
  if (l.filelen mod sizeof(_in^)) <> 0 then
    ri.Sys_Error(ERR_DROP, 'MOD_LoadBmodel: funny lump size in %s', loadmodel.name);
  count := l.filelen div sizeof(_in^);
  if (count < 1) or (count >= MAX_MAP_SURFEDGES) then
    ri.Sys_Error(ERR_DROP, 'MOD_LoadBmodel: bad surfedges count in %s: %i',
      loadmodel.name, count);

  _out := Hunk_Alloc(count * sizeof(_out^));

  loadmodel.surfedges := _out;
  loadmodel.numsurfedges := count;

  for i := 0 to count - 1 do
    PIntegerArray(_out)^[i] := LittleLong(PIntegerArray(_in)^[i]);
end;

{*
=================
Mod_LoadPlanes
=================
*}

procedure Mod_LoadPlanes(l: lump_p);
var
  i, j: integer;
  _out: cplane_p;
  _in: dplane_p;
  count,
    bits: integer;
begin
  _in := Pointer(Cardinal(mod_base) + l^.fileofs);
  if (l.filelen mod sizeof(_in^)) <> 0 then
    ri.Sys_Error(ERR_DROP, 'MOD_LoadBmodel: funny lump size in %s', loadmodel.name);
  count := l.filelen div sizeof(_in^);
  _out := Hunk_Alloc(count * 2 * sizeof(_out^));

  loadmodel.planes := _out;
  loadmodel.numplanes := count;

  for i := 0 to count - 1 do
  begin
    bits := 0;
    for j := 0 to 2 do
    begin
      _out.normal[j] := LittleFloat(_in.normal[j]);
      if (_out.normal[j] < 0) then
        bits := bits or (1 shl j);
    end;

    _out.dist := LittleFloat(_in.dist);
    _out._type := LittleLong(_in._type);
    _out.signbits := bits;
    Inc(_in);
    Inc(_out);
  end;
end;

{*
=================
Mod_LoadBrushModel
=================
*}

procedure Mod_LoadBrushModel(_mod: model_p; buffer: pointer);
var
  i: integer;
  header: dheader_p;
  bm: mmodel_p;
  starmod: model_p;
begin
  loadmodel._type := mod_brush;
  if (loadmodel <> @mod_known) then
    ri.Sys_Error(ERR_DROP, 'Loaded a brush model after the world', []);

  header := buffer;

  i := LittleLong(header^.version);
  if (i <> BSPVERSION) then
    ri.Sys_Error(ERR_DROP, 'Mod_LoadBrushModel: %s has wrong version number (%i should be %i)', _mod.name, i, BSPVERSION);

// swap all the lumps
  mod_base := PByte(header);

  for i := 0 to sizeof(dheader_t) div 4 - 1 do
    PIntegerArray(header)^[i] := LittleLong(PIntegerArray(header)^[i]);

// load into heap
  Mod_LoadVertexes(@header.lumps[LUMP_VERTEXES]);
  Mod_LoadEdges(@header.lumps[LUMP_EDGES]);
  Mod_LoadSurfedges(@header.lumps[LUMP_SURFEDGES]);
  Mod_LoadLighting(@header.lumps[LUMP_LIGHTING]);
  Mod_LoadPlanes(@header.lumps[LUMP_PLANES]);
  Mod_LoadTexinfo(@header.lumps[LUMP_TEXINFO]);
  Mod_LoadFaces(@header.lumps[LUMP_FACES]);
  Mod_LoadMarksurfaces(@header.lumps[LUMP_LEAFFACES]);
  Mod_LoadVisibility(@header.lumps[LUMP_VISIBILITY]);
  Mod_LoadLeafs(@header.lumps[LUMP_LEAFS]);
  Mod_LoadNodes(@header.lumps[LUMP_NODES]);
  Mod_LoadSubmodels(@header.lumps[LUMP_MODELS]);
  _mod.numframes := 2; // regular and alternate animation

//
// set up the submodels
//
  for i := 0 to _mod.numsubmodels - 1 do
  begin
    bm := @mModel_arrp(_mod.submodels)^[i];
    starmod := @mod_inline[i];

    starmod^ := loadmodel^;

    starmod.firstmodelsurface := bm.firstface;
    starmod.nummodelsurfaces := bm.numfaces;
    starmod.firstnode := bm.headnode;
    if (starmod.firstnode >= loadmodel.numnodes) then
      ri.Sys_Error(ERR_DROP, 'Inline model %i has bad firstnode', [i]);

    VectorCopy(bm.maxs, starmod.maxs);
    VectorCopy(bm.mins, starmod.mins);
    starmod.radius := bm.radius;

    if (i = 0) then
      loadmodel^ := starmod^;

    starmod.numleafs := bm.visleafs;
  end;
end;


{*
==============================================================================

ALIAS MODELS

==============================================================================
*}

{*
=================
Mod_LoadAliasModel
=================
*}

procedure Mod_LoadAliasModel(_mod: model_p; buffer: pointer);
var
  i, j: integer;
  pinmodel,
    pheader: dmdl_p;
  pinst,
    poutst: dstvert_p;
  pintri,
    pouttri: dtriangle_p;
  pinframe, poutframe: daliasframe_p;
  pincmd, poutcmd: PInteger;
  version: integer;
begin
  pinmodel := dmdl_p(buffer);

  version := LittleLong(pinmodel.version);
  if (version <> ALIAS_VERSION) then
    ri.Sys_Error(ERR_DROP, '%s has wrong version number (%i should be %i)',
      _mod.name, version, ALIAS_VERSION);

  pheader := Hunk_Alloc(LittleLong(pinmodel^.ofs_end));

  // byte swap the header fields and sanity check
  for i := 0 to sizeof(dmdl_t) div 4 - 1 do
    PIntegerArray(pheader)^[i] := LittleLong(PIntegerArray(buffer)^[i]);

  if (pheader.skinheight > MAX_LBM_HEIGHT) then
    ri.Sys_Error(ERR_DROP, 'model %s has a skin taller than %d',
      _mod.name, MAX_LBM_HEIGHT);

  if (pheader.num_xyz <= 0) then
    ri.Sys_Error(ERR_DROP, 'model %s has no vertices', _mod.name);

  if (pheader.num_xyz > MAX_VERTS) then
    ri.Sys_Error(ERR_DROP, 'model %s has too many vertices', _mod.name);

  if (pheader.num_st <= 0) then
    ri.Sys_Error(ERR_DROP, 'model %s has no st vertices', _mod.name);

  if (pheader.num_tris <= 0) then
    ri.Sys_Error(ERR_DROP, 'model %s has no triangles', _mod.name);

  if (pheader.num_frames <= 0) then
    ri.Sys_Error(ERR_DROP, 'model %s has no frames', _mod.name);

//
// load base s and t vertices (not used in gl version)
//
  pinst := Pointer(Cardinal(pinmodel) + pheader^.ofs_st);
  poutst := Pointer(Cardinal(pheader) + pheader^.ofs_st);

  for i := 0 to pheader.num_st - 1 do
  begin
    dstvert_a(poutst)^[i].s := LittleShort(dstvert_a(pinst)^[i].s);
    dstvert_a(poutst)^[i].t := LittleShort(dstvert_a(pinst)^[i].t);
  end;

//
// load triangle lists
//
  pintri := Pointer(Cardinal(pinmodel) + pheader^.ofs_tris);
  pouttri := Pointer(Cardinal(pheader) + pheader^.ofs_tris);

  for i := 0 to pheader.num_tris - 1 do
    for j := 0 to 2 do
    begin
      dtriangle_a(pouttri)^[i].index_xyz[j] := LittleShort(dtriangle_a(pintri)^[i].index_xyz[j]);
      dtriangle_a(pouttri)^[i].index_st[j] := LittleShort(dtriangle_a(pintri)^[i].index_st[j]);
    end;

//
// load the frames
//
  for i := 0 to pheader.num_frames - 1 do
  begin
    pinframe := Pointer(Cardinal(pinmodel)
      + pheader^.ofs_frames + i * pheader^.framesize);
    poutframe := Pointer(Cardinal(pheader)
      + pheader^.ofs_frames + i * pheader^.framesize);

    memcpy(@poutframe^.name, @pinframe^.name, sizeof(poutframe^.name));
    for j := 0 to 2 do
    begin
      poutframe^.scale[j] := LittleFloat(pinframe^.scale[j]);
      poutframe^.translate[j] := LittleFloat(pinframe^.translate[j]);
    end;
    // verts are all 8 bit, so no swapping needed
    memcpy(@poutframe^.verts, @pinframe^.verts,
      pheader^.num_xyz * sizeof(dtrivertx_t));
  end;

  _mod._type := mod_alias;

  //
  // load the glcmds
  //
  pincmd := Pointer(Cardinal(pinmodel) + pheader^.ofs_glcmds);
  poutcmd := Pointer(Cardinal(pheader) + pheader^.ofs_glcmds);
  for i := 0 to pheader^.num_glcmds - 1 do
    PIntegerArray(poutcmd)^[i] := LittleLong(PIntegerArray(pincmd)^[i]);


  // register all skins
  memcpy(Pointer(Cardinal(pheader) + pheader^.ofs_skins), Pointer(Cardinal(pinmodel) + pheader^.ofs_skins),
    pheader^.num_skins * MAX_SKINNAME);
  for i := 0 to pheader.num_skins - 1 do
    _mod.skins[i] := GL_FindImage(Pointer(Cardinal(pheader) + pheader^.ofs_skins + i * MAX_SKINNAME), it_skin);

  _mod.mins[0] := -32;
  _mod.mins[1] := -32;
  _mod.mins[2] := -32;
  _mod.maxs[0] := 32;
  _mod.maxs[1] := 32;
  _mod.maxs[2] := 32;
end;


{*
==============================================================================

SPRITE MODELS

==============================================================================
*}

{*
=================
Mod_LoadSpriteModel
=================
*}

procedure Mod_LoadSpriteModel(_mod: model_p; buffer: pointer);
var
  sprin,
    sprout: dsprite_p;
  i: integer;
begin
  sprin := buffer;
  sprout := Hunk_Alloc(modfilelen);

  sprout.ident := LittleLong(sprin.ident);
  sprout.version := LittleLong(sprin.version);
  sprout.numframes := LittleLong(sprin.numframes);

  if (sprout.version <> SPRITE_VERSION) then
    ri.Sys_Error(ERR_DROP, '%s has wrong version number (%i should be %i)',
      _mod.name, sprout.version, SPRITE_VERSION);

  if (sprout.numframes > MAX_MD2SKINS) then
    ri.Sys_Error(ERR_DROP, '%s has too many frames (%i > %i)',
      _mod.name, sprout.numframes, MAX_MD2SKINS);

  // byte swap everything
  for i := 0 to sprout.numframes - 1 do
  begin
    sprout.frames[i].width := LittleLong(sprin.frames[i].width);
    sprout.frames[i].height := LittleLong(sprin.frames[i].height);
    sprout.frames[i].origin_x := LittleLong(sprin.frames[i].origin_x);
    sprout.frames[i].origin_y := LittleLong(sprin.frames[i].origin_y);
    memcpy(@sprout^.frames[i].name, @sprin^.frames[i].name, MAX_SKINNAME);
    _mod.skins[i] := GL_FindImage(sprout.frames[i].name, it_sprite);
  end;

  _mod._type := mod_sprite;
end;


//=============================================================================

{*
@@@@@@@@@@@@@@@@@@@@@
R_BeginRegistration

Specifies the model that will be used as the world
@@@@@@@@@@@@@@@@@@@@@
*}

procedure R_BeginRegistration(model: PChar); cdecl; //for gl_rmain
var
  fullname: array[0..MAX_QPATH - 1] of char;
  flushmap: cvar_p;
begin
  Inc(registration_sequence);
  r_oldviewcluster := -1; // force markleafs

  Com_sprintf(fullname, sizeof(fullname), 'maps/%s.bsp', [model]);

  // explicitly free the old map if different
  // this guarantees that mod_known[0] is the world map
  flushmap := ri.Cvar_Get('flushmap', '0', 0);
  if (strcmp(mod_known[0].name, fullname) <> 0) or (flushmap^.Value <> 0) then
    Mod_Free(@mod_known[0]);
  r_worldmodel := Mod_ForName(fullname, true);

  r_viewcluster := -1;
end;

{*
@@@@@@@@@@@@@@@@@@@@@
R_RegisterModel

@@@@@@@@@@@@@@@@@@@@@
*}
//struct model_s *R_RegisterModel (char *name)

function R_RegisterModel(name: PChar): pointer; cdecl; //for gl_rmain
var
  _mod: model_p;
  i: integer;
  sprout: dsprite_p;
  pheader: dmdl_p;
begin
  _mod := Mod_ForName(name, false);
  if Assigned(_mod) then
  begin
    _mod.registration_sequence := registration_sequence;

    // register any images used by the models
    if (_mod._type = mod_sprite) then
    begin
      sprout := {(dsprite_t * )} _mod.extradata;
      for i := 0 to sprout.numframes - 1 do
        _mod.skins[i] := GL_FindImage(sprout.frames[i].name, it_sprite);
    end
    else
      if (_mod._type = mod_alias) then
      begin
        pheader := {(dmdl_t * )} _mod.extradata;
        for i := 0 to pheader.num_skins - 1 do
          _mod.skins[i] := GL_FindImage(Pointer(Cardinal(pheader) + pheader^.ofs_skins + i * MAX_SKINNAME), it_skin);
//PGM
        _mod.numframes := pheader.num_frames;
//PGM
      end
      else
        if (_mod._type = mod_brush) then
          for i := 0 to _mod.numtexinfo - 1 do
            mTexInfo_arrp(_mod.texinfo)^[i].image.registration_sequence := registration_sequence;
  end;
  Result := _mod;
end;

{*
@@@@@@@@@@@@@@@@@@@@@
R_EndRegistration

@@@@@@@@@@@@@@@@@@@@@
*}

procedure R_EndRegistration; cdecl; //gl_rmain
var
  i: integer;
  _mod: model_p;
begin
  _mod := @mod_known[0];
  for i := 0 to mod_numknown - 1 do
  begin
    if _mod^.name[0] = #0 then
    begin
      Inc(_mod);
      continue;
    end;
    if _mod^.registration_sequence <> registration_sequence then
      Mod_Free(_mod);
    Inc(_mod);
  end;

  GL_FreeUnusedImages();
end;

//=============================================================================

{*
================
Mod_Free
================
*}

procedure Mod_Free(_mod: model_p);
begin
  Hunk_Free(_mod.extradata);
  memset(_mod, 0, sizeof(_mod^));
end;

{*
================
Mod_FreeAll
================
*}

procedure Mod_FreeAll;
var
  i: integer;
begin
  for i := 0 to mod_numknown - 1 do
    if (mod_known[i].extradatasize <> 0) then
      Mod_Free(@mod_known[i]);
end;

end.
