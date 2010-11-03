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
{ File(s): r_model.c and r_model.h                                           }
{ Content: model loading and caching                                         }
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
{                                                                            }
{ Updated on : 19-July-2002                                                  }
{ Updated by : CodeFusion (Michael@Skovslund.dk)                             }
{                                                                            }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{ none!!!                                                                    }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{ none!!!                                                                    }
{----------------------------------------------------------------------------}

unit r_model;

interface

uses
  Qfiles,
  Windows,
  q_shared;

(*
==============================================================================

BRUSH MODELS

==============================================================================
*)

//
// in memory representation
//
// !!! if this is changed, it must be changed in asm_draw.h too !!!
type
  mvertex_p = ^mvertex_t;
  mvertex_t = record
    position: vec3_t;
  end;
  mvertex_arr = array[0..MaxInt div SizeOf(mvertex_t) - 1] of mvertex_t;
  mvertex_arrp = ^mvertex_arr;

const
  SIDE_FRONT = 0;
  SIDE_BACK = 1;
  SIDE_ON = 2;

// plane_t structure
// !!! if this is changed, it must be changed in asm_i386.h too !!!
type
  mplane_p = ^mplane_t;
  mplane_t = record
    normal: vec3_t;
    dist: Single;
    _type: Byte; // for texture axis selection and fast side tests
    signbits: Byte; // signx + signy<<1 + signz<<1
    pad: array[0..1] of Byte;
  end;
  mplane_arr = array[0..MaxInt div SizeOf(mplane_t) - 1] of mplane_t;
  mplane_arrp = ^mplane_arr;

// FIXME: differentiate from texinfo SURF_ flags
const
  SURF_PLANEBACK = 2;
  SURF_DRAWSKY = 4; // sky brush face
  SURF_DRAWTURB = $10;
  SURF_DRAWBACKGROUND = $40;
  SURF_DRAWSKYBOX = $80; // sky box

  SURF_FLOW = $100; //PGM

// !!! if this is changed, it must be changed in asm_draw.h too !!!
type
  medge_p = ^medge_t;
  medge_t = record
    v: array[0..1] of Word;
    cachededgeoffset: Integer;
  end;
  medge_arr = array[0..MaxInt div SizeOf(medge_t) - 1] of medge_t;
  medge_arrp = ^medge_arr;

/////////// CAK - TAKEN FROM r_local.h
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
  imagetype_p = ^imagetype_t;
  imagetype_t = (
    it_skin,
    it_sprite,
    it_wall,
    it_pic,
    it_sky
    );

  image_p = ^image_t;
  image_t = record
    name: array[0..MAX_QPATH - 1] of char; // game path, including extension
    _type: imagetype_t;
    width, height: integer;
    transparent: qboolean; // true if any 255 pixels in image
    registration_sequence: integer; // 0 = free
    pixels: array[0..3] of pByte; // mip levels
  end;

  mtexinfo_p = ^mtexinfo_t;
  mtexinfo_t = record
    vecs: array[0..1, 0..3] of Single; // CAK - STRANGE! had to typecast this to vec3_t
    mipadjust: Single;
    image: image_p;
    flags: integer;
    numframes: integer;
    next: mtexinfo_p; // animation chain
  end;
  mtexinfo_arr = array[0..MaxInt div SizeOf(mtexinfo_t) - 1] of mtexinfo_t;
  mtexinfo_arrp = ^mtexinfo_arr;

  surfcache_p = ^surfcache_t;
  surfcache_t = record
    next: surfcache_p;
    owner: ^surfcache_p; // NULL is an empty chunk of memory
    lightadj: array[0..MAXLIGHTMAPS - 1] of integer; // checked for strobe flush
    dlight: integer;
    size: integer; // including header
    width: Cardinal;
    height: Cardinal; // DEBUG only needed for debug
    mipscale: single;
    image: image_p;
    data: array[0..3] of byte; // width*height elements
  end;

  msurface_p = ^msurface_t;
  msurface_t = record
    visframe: integer; // should be drawn when node is crossed
    dlightframe: integer;
    dlightbits: integer;
    plane: mplane_p;
    flags: integer;
    firstedge: integer; // look up in model->surfedges[], negative numbers
    numedges: integer; // are backwards edges
    // surface generation data
    cachespots: array[0..MIPLEVELS - 1] of surfcache_p;
    texturemins: array[0..1] of smallint;
    extents: array[0..1] of smallint;
    texinfo: mtexinfo_p;
    // lighting info
    styles: array[0..MAXLIGHTMAPS - 1] of byte;
    samples: PByte; // [numstyles*surfsize]
    nextalphasurface: msurface_p;
  end;
  msurface_s = msurface_t;
  msurface_pp = ^msurface_p;
  msurface_arr = array[0..MaxInt div SizeOf(msurface_t) - 1] of msurface_t;
  msurface_arrp = ^msurface_arr;

  mnode_p = ^mnode_t;
  mnode_t = record
    // common with leaf
    contents: integer; // CONTENTS_NODE, to differentiate from leafs
    visframe: integer; // node needs to be traversed if current
    minmaxs: array[0..5] of smallint; // for bounding box culling
    parent: mnode_p;
    // node specific
    plane: mplane_p;
    children: array[0..1] of mnode_p;
    firstsurface: word;
    numsurfaces: word;
  end;
  mnode_s = mnode_t;
  mnode_arr = array[0..MaxInt div SizeOf(mnode_t) - 1] of mnode_t;
  mnode_arrp = ^mnode_arr;

  mleaf_p = ^mleaf_t;
  mleaf_t = record
    // common with node
    contents: integer; // wil be something other than CONTENTS_NODE
    visframe: integer; // node needs to be traversed if current
    minmaxs: array[0..5] of smallint; // for bounding box culling
    parent: mnode_p;
    // leaf specific
    cluster: integer;
    area: integer;
    firstmarksurface: msurface_pp; // CAK - pointer to pointer to msurface_t
    nummarksurfaces: integer;
    key: integer; // BSP sequence number for leaf's contents
  end;
  mleaf_arr = array[0..MaxInt div SizeOf(mleaf_t) - 1] of mleaf_t;
  mleaf_arrp = ^mleaf_arr;

//===================================================================

//
// Whole model
//

  modtype_p = ^modtype_t;
  modtype_t = (mod_bad,
    mod_brush,
    mod_sprite,
    mod_alias);

  model_p = ^model_t;
  model_t = record
    name: array[0..MAX_QPATH - 1] of Char;
    registration_sequence: integer;
    _type: modtype_t;
    numframes: integer;
    flags: integer;
// volume occupied by the model graphics
    mins: vec3_t;
    maxs: vec3_t;
// solid volume for clipping (sent from server)
    clipbox: qboolean;
    clipmins: vec3_t;
    clipmaxs: vec3_t;
// brush model
    firstmodelsurface: integer;
    nummodelsurfaces: integer;

    numsubmodels: integer;
    submodels: dmodel_p;

    numplanes: integer;
    planes: mplane_p;

    numleafs: integer; // number of visible leafs, not counting 0
    leafs: mleaf_p;

    numvertexes: integer;
    vertexes: mvertex_p;

    numedges: integer;
    edges: medge_p;

    numnodes: integer;
    firstnode: integer;
    nodes: mnode_p;

    numtexinfo: integer;
    texinfo: mtexinfo_p;

    numsurfaces: integer;
    surfaces: msurface_p;

    numsurfedges: integer;
    surfedges: PInteger;

    nummarksurfaces: integer;
    marksurfaces: msurface_pp;

    vis: dvis_p;
    lightdata: PByte;
// for alias models and sprites
    skins: array[0..MAX_MD2SKINS - 1] of image_p;
    extradata: pointer;
    extradatasize: integer;
  end;

//============================================================================

const
  CONTENTS_NODE = -1;

procedure Mod_Init;
(*
void   Mod_ClearAll (void);
*)
function Mod_ForName(name: PChar; crash: qboolean): model_p;
(*
void   *Mod_Extradata (model_t *mod);   // handles caching
void   Mod_TouchModel (char *name);
*)

function Mod_PointInLeaf(const p: vec3_t; model: model_p): mleaf_p;
function Mod_ClusterPVS(cluster: integer; model: model_p): PByte;
procedure Mod_Modellist_f; cdecl;
procedure Mod_FreeAll;
procedure Mod_Free(_mod: model_p);
function R_RegisterModel(name: PChar): Pointer; cdecl;
procedure R_BeginRegistration(model: PChar); cdecl;
procedure R_EndRegistration; cdecl;

var
  registration_sequence: Integer;
  loadmodel: model_p; // used by r_rast

//////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////
implementation
//////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////

uses
  sysutils,
  q_shwin,
  r_local,
  r_rast,
  r_image,
  r_surf,
  r_main;

//////////////////////////////////////////////
// CAK - Stuff that doesn't exist in Delphi 3
//////////////////////////////////////////////
//var
//  loadname              : array[0..31] of Char; // for hunk tags

(*
function floor(x: Single): Integer;
begin
  if Trunc(x) = x then
    Result := Trunc(x)
  else
    if x < 0 then
      Result := Trunc(x) - 1
    else
      Result := Trunc(x);
end;

function ceil(x: Single): Integer;
begin
  if Trunc(x) = x then
    Result := Trunc(x)
  else
    if x < 0 then
      Result := Trunc(x)
    else
      Result := Trunc(x) + 1;
end;
*)
// models.c -- model loading and caching

// models are the only shared resource between a client and server running
// on the same machine.

procedure Mod_LoadSpriteModel(_mod: model_p; buffer: Pointer); forward;
procedure Mod_LoadBrushModel(_mod: model_p; buffer: Pointer); forward;
procedure Mod_LoadAliasModel(_mod: model_p; buffer: Pointer); forward;
//CAK - BUG!!! This function prototype is for a function which
//doesn't exist ANYWHERE in the original C code!!!
//function Mod_LoadModel(_mod: model_p; crash: qboolean): model_p; forward;

const
  MAX_MOD_KNOWN = 256;

var
  mod_novis: array[0..(MAX_MAP_LEAFS div 8) - 1] of byte;
  mod_known: array[0..MAX_MOD_KNOWN - 1] of model_t;
  mod_numknown: integer;
// the inline * models from the current map are kept seperate
  mod_inline: array[0..MAX_MOD_KNOWN - 1] of model_t;
  modfilelen: Integer;

//===============================================================================

function IntToStr2(Value: Integer; Size: Integer): string;
begin
  Result := IntToStr(Value);
  while length(Result) < size do
    Result := ' ' + Result;
end {function};

(*
================
Mod_Modellist_f
================
*)

procedure Mod_Modellist_f; cdecl;
var
  i: Integer;
  _mod: model_p;
  total: Integer;
begin
  total := 0;
  ri.Con_Printf(PRINT_ALL, 'Loaded models:'#13#10);
  _mod := @mod_known[0];
  for i := 0 to mod_numknown - 1 do
  begin
    if _mod^.name[0] = #0 then
    begin
      inc(Integer(_mod), SizeOf(model_t));
      continue;
    end;
    ri.Con_Printf(PRINT_ALL, '%d : %s', _mod.extradatasize, _mod.name);
    total := total + _mod^.extradatasize;
    inc(Integer(_mod), SizeOf(model_t));
  end; {next i};
  ri.Con_Printf(PRINT_ALL, 'Total resident: %d', total);
end {procedure};

(*
===============
Mod_Init
===============
*)

procedure Mod_Init;
begin
  FillChar(mod_novis, sizeof(mod_novis), $FF);
end;

// CAK

function PCharToInt(s: PChar): Integer;
var
  s2: string;
begin
  s2 := s;
  try
    Result := StrToInt(s2);
  except
    Result := -1;
  end {try};
end;

(*
==================
Mod_ForName

Loads in a model for the given name
==================
*)

function Mod_ForName(name: PChar; crash: qboolean): model_p;
var
  _mod: model_p;
  buf: Pointer;
  i: Integer;
begin
  if (name^ = #0) then
    ri.Sys_Error(ERR_DROP, 'Mod_ForName: NULL name');

  //
  // inline models are grabbed only from worldmodel
  //
  if name[0] = '*' then
  begin
    i := PCharToInt(PChar(@name[1]));
    if (i < 1) or (r_worldmodel = nil) or (i >= r_worldmodel^.numsubmodels) then
      ri.Sys_Error(ERR_DROP, 'bad inline model number');
    Result := @mod_inline[i];
    Exit;
  end;

  //
  // search the currently loaded models
  //
  _mod := @mod_known[0];
  for i := 0 to mod_numknown - 1 do
  begin
    if strcomp(PChar(@_mod^.name), name) = 0 then
    begin
      Result := _mod;
      Exit;
    end;
    _mod := @mod_known[i];
  end;

  //
  // find a free model slot spot
  //
  _mod := nil;
  for i := 0 to mod_numknown - 1 do
  begin
    if mod_known[i].name[0] = #0 then
    begin
      _mod := @mod_known[i];
      break; // free spot
    end;
  end;
  if (_mod = nil) then
  begin // no free spot found
    if mod_numknown = MAX_MOD_KNOWN then
      ri.Sys_Error(ERR_DROP, 'mod_numknown == MAX_MOD_KNOWN');
    inc(mod_numknown);
    _mod := @mod_known[mod_numknown - 1];
  end;
  strcopy(PChar(@_mod^.name[0]), name);

  //
  // load the file
  //
  modfilelen := ri.FS_LoadFile(PChar(@_mod^.name), @buf);
  if buf = nil then
  begin
    if crash then
      ri.Sys_Error(ERR_DROP, PChar('Mod_NumForName: ' + string(_mod.name) + ' not found'));
    FillChar(_mod^.name[0], sizeof(_mod^.name), 0);
    Result := nil;
    Exit;
  end;

  loadmodel := _mod;

  //
  // fill it in
  //

  // call the apropriate loader

  case LittleLong(PInteger(buf)^) of
    IDALIASHEADER:
      begin
        loadmodel^.extradata := Hunk_Begin($200000);
        Mod_LoadAliasModel(_mod, buf);
      end;
    IDSPRITEHEADER:
      begin
        loadmodel^.extradata := Hunk_Begin($10000);
        Mod_LoadSpriteModel(_mod, buf);
      end;
    IDBSPHEADER:
      begin
        loadmodel^.extradata := Hunk_Begin($1000000);
        Mod_LoadBrushModel(_mod, buf);
      end;
  else
    begin
      ri.Sys_Error(ERR_DROP, PChar('Mod_NumForName: unknown fileid for ' + string(_mod^.name)));
    end;
  end;

  loadmodel^.extradatasize := Hunk_End;

  ri.FS_FreeFile(buf);

  Result := _mod;
end;

(*
===============
Mod_PointInLeaf
===============
*)

function Mod_PointInLeaf(const p: vec3_t; model: model_p): mleaf_p;
var
  node: mnode_p;
  d: Single;
  plane: mplane_p;
begin
  if (model = nil) or (model^.nodes = nil) then
    ri.Sys_Error(ERR_DROP, 'Mod_PointInLeaf: bad model');

  node := model^.nodes;
  while (True) do
  begin
    if node^.contents <> -1 then
    begin
      Result := mleaf_p(node);
      exit;
    end;
    plane := node^.plane;
    d := DotProduct(p, plane^.normal) - plane^.dist;
    if d > 0.0 then
      node := node^.children[0]
    else
      node := node^.children[1];
  end;
  Result := nil; // never reached
end;

(*
===================
Mod_DecompressVis
===================
*)
var
  decompressed: array[0..(MAX_MAP_LEAFS div 8) - 1] of Byte;

function Mod_DecompressVis(_in: PByte; model: model_p): PByte;
var
  c: Integer;
  _out: PByte;
  row: Integer;
begin
  row := (model^.vis^.numclusters + 7) shr 3;
  _out := @decompressed[0];

(*
    move(in^,out^,row);
*)
  if _in = nil then
  begin // no vis info, so make all visible
    while row <> 0 do
    begin
      _out^ := $FF;
      inc(Integer(_out), 1);
      dec(row, 1);
    end;
    Result := @decompressed[0];
    exit;
  end;

  repeat
    if (_in^ <> 0) then
    begin
      _out^ := _in^;
      inc(Integer(_out), 1);
      inc(Integer(_in), 1);
    end
    else
    begin
      c := PByteArray(_in)^[1];
      inc(Integer(_in), 2);
      while (c > 0) do
      begin
        _out^ := 0;
        inc(Integer(_out), 1);
        dec(c);
      end;
    end;
  until (Integer(_out) - Integer(@decompressed[0])) >= row;
  Result := @decompressed[0];
end;

(*
==============
Mod_ClusterPVS
==============
*)

function Mod_ClusterPVS(cluster: integer; model: model_p): PByte;
begin
  if (cluster = -1) or (model^.vis = nil) then
  begin
    Result := @mod_novis[0];
    exit;
  end {if};
  Result := Mod_DecompressVis(PByte(Integer(model^.vis) + model^.vis^.bitofs[cluster][DVIS_PVS]), model);
end {function};

(*
===============================================================================

     BRUSHMODEL LOADING

===============================================================================
*)

var
  mod_base: PByte;

(*
=================
Mod_LoadLighting

Converts the 24 bit lighting down to 8 bit
by taking the brightest component
=================
*)

procedure Mod_LoadLighting(l: lump_p);
var
  i, size: Integer;
  _in: PByte;
  _out: PByte;
begin
  if l^.filelen = 0 then
  begin
    loadmodel^.lightdata := nil;
    exit;
  end;
  size := Trunc(l^.filelen / 3);
  loadmodel^.lightdata := Hunk_Alloc(size);
  _in := Pointer(Integer(mod_base) + l^.fileofs);
  _out := loadmodel^.lightdata;
  for i := 0 to size - 1 do
  begin
    if (PByteArray(_in)^[0] > PByteArray(_in)^[1]) and (PByteArray(_in)^[0] > PByteArray(_in)^[2]) then
      _out^ := PByteArray(_in)^[0]
    else
    begin
      if (PByteArray(_in)^[1] > PByteArray(_in)^[0]) and (PByteArray(_in)^[1] > PByteArray(_in)^[2]) then
        _out^ := PByteArray(_in)^[1]
      else
        _out^ := PByteArray(_in)^[2];
    end;
    inc(Integer(_in), 3);
    inc(Integer(_out));
  end;
end;

var
  r_leaftovis: array[0..MAX_MAP_LEAFS - 1] of Integer;
  r_vistoleaf: array[0..MAX_MAP_LEAFS - 1] of Integer;
  r_numvisleafs: Integer;

procedure R_NumberLeafs(node: mnode_p);
var
  leaf: mleaf_p;
  leafnum: Integer;
begin
  if node^.contents <> -1 then
  begin
    leaf := mleaf_p(node);
    leafnum := (Integer(leaf) - Integer(loadmodel^.leafs)) div SizeOf(mleaf_t);
    if (leaf^.contents and CONTENTS_SOLID) <> 0 then
      Exit;
    r_leaftovis[leafnum] := r_numvisleafs;
    r_vistoleaf[r_numvisleafs] := leafnum;
    inc(r_numvisleafs);
    exit;
  end;
  R_NumberLeafs(node^.children[0]);
  R_NumberLeafs(node^.children[1]);
end;

(*
=================
Mod_LoadVisibility
=================
*)

procedure Mod_LoadVisibility(l: lump_p);
var
  i: Integer;
begin
  if (l^.filelen = 0) then
  begin
    loadmodel^.vis := nil;
    Exit;
  end;
  loadmodel^.vis := Hunk_Alloc(l^.filelen);
  move(Pointer(Integer(mod_base) + l^.fileofs)^, loadmodel^.vis^, l^.filelen);

  loadmodel^.vis^.numclusters := LittleLong(loadmodel^.vis^.numclusters);
  for i := 0 to loadmodel^.vis^.numclusters - 1 do
  begin
    loadmodel^.vis^.bitofs[i][0] := LittleLong(loadmodel^.vis^.bitofs[i][0]);
    loadmodel^.vis^.bitofs[i][1] := LittleLong(loadmodel^.vis^.bitofs[i][1]);
  end;
end;

(*
=================
Mod_LoadVertexes
=================
*)

procedure Mod_LoadVertexes(l: lump_p);
var
  _in: dvertex_p;
  _out: mvertex_p;
  i, count: Integer;
begin
  _in := Pointer(Integer(mod_base) + l^.fileofs);
  if (l^.filelen mod SizeOf(_in^)) <> 0 then
    ri.Sys_Error(ERR_DROP, PChar('MOD_LoadBmodel: funny lump size in ' + string(loadmodel^.name)));
  count := Trunc(l^.filelen / SizeOf(_in^));
  _out := Hunk_Alloc((count + 8) * sizeof(_out^)); // extra for skybox

  loadmodel^.vertexes := _out;
  loadmodel^.numvertexes := count;

  for i := 0 to count - 1 do
  begin
    _out^.position[0] := LittleFloat(_in^.point[0]);
    _out^.position[1] := LittleFloat(_in^.point[1]);
    _out^.position[2] := LittleFloat(_in^.point[2]);
    inc(Integer(_in), SizeOf(_in^));
    inc(Integer(_out), SizeOf(_out^));
  end;
end;

(*
=================
Mod_LoadSubmodels
=================
*)

procedure Mod_LoadSubmodels(l: lump_p);
var
  _in, _out: dmodel_p;
  i, j, count: Integer;
begin
  _in := Pointer(Integer(mod_base) + l^.fileofs);
  if (l^.filelen mod SizeOf(_in^)) <> 0 then
    ri.Sys_Error(ERR_DROP, PChar('MOD_LoadBmodel: funny lump size in ' + string(loadmodel^.name)));
  count := Trunc(l^.filelen / SizeOf(_in^));
  _out := Hunk_Alloc(count * sizeof(_out^));

  loadmodel^.submodels := _out;
  loadmodel^.numsubmodels := count;

  for i := 0 to count - 1 do
  begin
    for j := 0 to 2 do
    begin // spread the mins / maxs by a pixel
      _out^.mins[j] := LittleFloat(_in^.mins[j]) - 1;
      _out^.maxs[j] := LittleFloat(_in^.maxs[j]) + 1;
      _out^.origin[j] := LittleFloat(_in^.origin[j]);
    end;
    _out^.headnode := LittleLong(_in^.headnode);
    _out^.firstface := LittleLong(_in^.firstface);
    _out^.numfaces := LittleLong(_in^.numfaces);

    inc(Integer(_in), SizeOf(_in^));
    inc(Integer(_out), SizeOf(_out^));
  end;
end;

(*
=================
Mod_LoadEdges
=================
*)

procedure Mod_LoadEdges(l: lump_p);
var
  _in: dedge_p;
  _out: medge_p;
  i: Integer;
  count: Integer;
begin
  _in := Pointer(Integer(mod_base) + l^.fileofs);
  if (l^.filelen mod SizeOf(_in^)) <> 0 then
    ri.Sys_Error(ERR_DROP, PChar('MOD_LoadBmodel: funny lump size in ' + string(loadmodel^.name)));
  count := Trunc(l^.filelen / sizeof(_in^));
  _out := Hunk_Alloc((count + 13) * sizeof(_out^)); // extra for skybox

  loadmodel^.edges := _out;
  loadmodel^.numedges := count;

  for i := 0 to count - 1 do
  begin
    _out^.v[0] := Word(LittleShort(_in^.v[0]));
    _out^.v[1] := Word(LittleShort(_in^.v[1]));
    inc(Integer(_in), SizeOf(_in^));
    inc(Integer(_out), SizeOf(_out^));
  end {next i};
end {procedure};

(*
=================
Mod_LoadTexinfo
=================
*)

procedure Mod_LoadTexinfo(l: lump_p);
var
  _in: texinfo_p;
  _out, step: mtexinfo_p;
  i, j, count: Integer;
  len1, len2: Single;
  name: array[0..MAX_QPATH - 1] of Char;
  next: Integer;
begin
  _in := Pointer(Integer(mod_base) + l^.fileofs);
  if (l^.filelen mod SizeOf(_in^)) <> 0 then
    ri.Sys_Error(ERR_DROP, PChar('MOD_LoadBmodel: funny lump size in ' + string(loadmodel^.name)));
  count := Trunc(l^.filelen / sizeof(_in^));
  _out := Hunk_Alloc((count + 6) * sizeof(_out^)); // extra for skybox

  loadmodel^.texinfo := _out;
  loadmodel^.numtexinfo := count;

  for i := 0 to count - 1 do
  begin
    for j := 0 to 7 do
    begin
      _out^.vecs[0][j] := LittleFloat(_in^.vecs[0][j]);
      //_out^.vecs[1][j] := LittleFloat(_in^.vecs[1][j]);
    end;
    len1 := VectorLength(vec3_p(@_out^.vecs[0][0])^);
    len2 := VectorLength(vec3_p(@_out^.vecs[1][0])^);
    len1 := (len1 + len2)/2;
    if len1 < 0.32 then
      _out^.mipadjust := 4
    else
      if len1 < 0.49 then
        _out^.mipadjust := 3
      else
        if len1 < 0.99 then
          _out^.mipadjust := 2
        else
          _out^.mipadjust := 1;
(*
  if (len1 + len2 < 0.001)
   _out.mipadjust := 1;      // don't crash
  else
   _out.mipadjust := 1 / floor( (len1+len2)/2 + 0.1 );
*)

    _out^.flags := LittleLong(_in^.flags);

    next := LittleLong(_in^.nexttexinfo);
    if next > 0 then
      _out^.next := mtexinfo_p(Integer(loadmodel^.texinfo) + (next * SizeOf(loadmodel^.texinfo^)));

    Com_sprintf(name, sizeof(name), 'textures/%s.wal', [_in^.texture]);
    _out^.image := R_FindImage(name, it_wall);
    if _out^.image = nil then
    begin
      _out^.image := r_notexture_mip; // texture not found
      _out^.flags := 0;
    end;
    inc(Integer(_in), SizeOf(_in^));
    inc(Integer(_out), SizeOf(_out^));
  end;

  // count animation frames
  _out := loadmodel^.texinfo;
  for i := 0 to count - 1 do
  begin
    _out^.numframes := 1;
    step := _out^.next;
    while (step <> nil) and (Integer(step) <> Integer(_out)) do
    begin
      inc(_out^.numframes);
      step := step^.next;
    end;
    Inc(Integer(_out), SizeOf(_out^));
  end;
end;

(*
================
CalcSurfaceExtents

Fills in s->texturemins[] and s->extents[]
================
*)

procedure CalcSurfaceExtents(s: msurface_p);
var
  mins, maxs: array[0..1] of Single;
  val: Single;
  i, j, e: Integer;
  v: mvertex_p;
  tex: mtexinfo_p;
  bmins, bmaxs: array[0..1] of Single;
begin
  mins[0] := 999999;
  mins[1] := 999999;
  maxs[0] := -99999;
  maxs[1] := -99999;

  tex := s^.texinfo;

  for i := 0 to s^.numedges - 1 do
  begin
    e := PIntegerArray(loadmodel^.surfedges)^[s^.firstedge + i];
    if e >= 0 then
      v := @mvertex_arrp(loadmodel^.vertexes)^[medge_arrp(loadmodel^.edges)^[e].v[0]]
    else
      v := @mvertex_arrp(loadmodel^.vertexes)^[medge_arrp(loadmodel^.edges)^[-e].v[1]];

    for j := 0 to 1 do
    begin
      val := v^.position[0] * tex^.vecs[j][0] +
        v^.position[1] * tex^.vecs[j][1] +
        v^.position[2] * tex^.vecs[j][2] +
        tex^.vecs[j][3];
      if val < mins[j] then
        mins[j] := val;
      if val > maxs[j] then
        maxs[j] := val;
    end;
  end;

  for i := 0 to 1 do
  begin
    bmins[i] := floor(mins[i] / 16);
    bmaxs[i] := ceil(maxs[i] / 16);

    s^.texturemins[i] := Trunc(bmins[i] * 16);
    s^.extents[i] := Trunc((bmaxs[i] - bmins[i]) * 16);
    if s^.extents[i] < 16 then
      s^.extents[i] := 16; // take at least one cache block
    if ((tex^.flags and (SURF_WARP or SURF_SKY)) = 0) and (s^.extents[i] > 256) then
      ri.Sys_Error(ERR_DROP, 'Bad surface extents');
  end;
end;

(*
=================
Mod_LoadFaces
=================
*)

procedure Mod_LoadFaces(l: lump_p);
var
  _in: dface_p;
  _out: msurface_p;
  i, count: Integer;
  surfnum: Integer;
  planenum: Integer;
  side: Integer;
begin
  _in := Pointer(Integer(mod_base) + l^.fileofs);
  if (l^.filelen mod SizeOf(_in^)) <> 0 then
    ri.Sys_Error(ERR_DROP, PChar('MOD_LoadBmodel: funny lump size in ' + string(loadmodel^.name)));
  count := Trunc(l^.filelen / sizeof(_in^));
  _out := Hunk_Alloc((count + 6) * sizeof(_out^)); // extra for skybox

  loadmodel^.surfaces := _out;
  loadmodel^.numsurfaces := count;

  for surfnum := 0 to count - 1 do
  begin
    _out^.firstedge := LittleLong(_in^.firstedge);
    _out^.numedges := LittleShort(_in^.numedges);
    if _out^.numedges < 3 then
      ri.Sys_Error(ERR_DROP, PChar('Surface with ' + IntToStr(_out^.numedges) + ' edges')); // CAK BUG!!!!! The number of edges was passed to printf as a string instead of an integer
    _out^.flags := 0;

    planenum := LittleShort(_in^.planenum);
    side := LittleShort(_in^.side);
    if side <> 0 then
      _out^.flags := _out^.flags or SURF_PLANEBACK;

    _out^.plane := @mplane_arrp(loadmodel^.planes)^[planenum];

    _out^.texinfo := @mtexinfo_arrp(loadmodel^.texinfo)^[LittleShort(_in^.texinfo)];

    CalcSurfaceExtents(_out);

    // lighting info is converted from 24 bit on disk to 8 bit

    for i := 0 to MAXLIGHTMAPS - 1 do
      _out^.styles[i] := _in^.styles[i];
    i := LittleLong(_in^.lightofs);
    if i = -1 then
      _out^.samples := nil
    else
      _out^.samples := Pointer(Integer(loadmodel.lightdata) + (i div 3));

    // set the drawing flags flag

    if _out^.texinfo.image = nil then
    begin
      inc(Integer(_in), SizeOf(_in^));
      inc(Integer(_out), SizeOf(_out^));
      continue;
    end;
    if (_out^.texinfo.flags and SURF_SKY) <> 0 then
    begin
      _out^.flags := _out^.flags or SURF_DRAWSKY;
      inc(Integer(_in), SizeOf(_in^));
      inc(Integer(_out), SizeOf(_out^));
      continue;
    end;

    if (_out^.texinfo.flags and SURF_WARP) <> 0 then
    begin
      _out^.flags := _out^.flags or SURF_DRAWTURB;
      for i := 0 to 1 do
      begin
        _out^.extents[i] := 16384;
        _out^.texturemins[i] := -8192;
      end;
      inc(Integer(_in), SizeOf(_in^));
      inc(Integer(_out), SizeOf(_out^));
      continue;
    end;
//==============
//PGM
    // this marks flowing surfaces as turbulent, but with the new
    // SURF_FLOW flag.
    if (_out^.texinfo.flags and SURF_FLOWING) <> 0 then
    begin
      _out^.flags := _out^.flags or SURF_DRAWTURB or SURF_FLOW;
      for i := 0 to 1 do
      begin
        _out^.extents[i] := 16384;
        _out^.texturemins[i] := -8192;
      end;
      inc(Integer(_in), SizeOf(_in^));
      inc(Integer(_out), SizeOf(_out^));
      continue;
    end;
//PGM
//==============
    inc(Integer(_in), SizeOf(_in^));
    inc(Integer(_out), SizeOf(_out^));
  end {next i};
end;

(*
=================
Mod_SetParent
=================
*)

procedure Mod_SetParent(node, parent: mnode_p);
begin
  node^.parent := parent;
  if node^.contents <> -1 then
    exit;
  Mod_SetParent(node^.children[0], node);
  Mod_SetParent(node^.children[1], node);
end;

(*
=================
Mod_LoadNodes
=================
*)

procedure Mod_LoadNodes(l: lump_p);
var
  i, j: Integer;
  count: Integer;
  p: Integer;
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
    _out^.plane := @mplane_arrp(loadmodel^.planes)^[p];

    _out^.firstsurface := LittleShort(_in^.firstface);
    _out^.numsurfaces := LittleShort(_in^.numfaces);
    _out^.contents := CONTENTS_NODE; // differentiate from leafs

    for j := 0 to 1 do
    begin
      p := LittleLong(_in^.children[j]);
      if p >= 0 then
        _out^.children[j] := @mnode_arrp(loadmodel^.nodes)^[p]
      else
        _out^.children[j] := mnode_p(@mleaf_arrp(loadmodel^.leafs)^[-1 - p]); // CAK - Huh?????
    end;
    inc(Integer(_in), SizeOf(_in^));
    inc(Integer(_out), SizeOf(_out^));
  end {next i};
  Mod_SetParent(loadmodel^.nodes, nil); // sets nodes and leafs
end;

(*
=================
Mod_LoadLeafs
=================
*)

procedure Mod_LoadLeafs(l: lump_p);
var
  _in: dleaf_p;
  _out: mleaf_p;
  i, j: Integer;
  count: Integer;
begin
  _in := Pointer(Integer(mod_base) + l^.fileofs);
  if (l^.filelen mod SizeOf(_in^)) <> 0 then
    ri.Sys_Error(ERR_DROP, PChar('MOD_LoadBmodel: funny lump size in ' + string(loadmodel^.name)));
  count := Trunc(l^.filelen / sizeof(_in^));
  _out := Hunk_Alloc(count * sizeof(_out^));

  loadmodel^.leafs := _out;
  loadmodel^.numleafs := count;

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
    inc(Integer(_in), SizeOf(_in^));
    inc(Integer(_out), SizeOf(_out^));
  end;
end;

(*
=================
Mod_LoadMarksurfaces
=================
*)

procedure Mod_LoadMarksurfaces(l: lump_p);
var
  i, j: Integer;
  count: Integer;
  _in: PSmallInt;
  _out: msurface_pp;
begin
  _in := Pointer(Integer(mod_base) + l^.fileofs);
  if (l^.filelen mod SizeOf(_in^)) <> 0 then
    ri.Sys_Error(ERR_DROP, PChar('MOD_LoadBmodel: funny lump size in ' + string(loadmodel^.name)));
  count := Trunc(l^.filelen / sizeof(_in^));
  _out := Hunk_Alloc(count * sizeof(_out^));

  loadmodel^.marksurfaces := _out;
  loadmodel^.nummarksurfaces := count;

  for i := 0 to count - 1 do
  begin
    j := LittleShort(_in^);
    if j >= loadmodel^.numsurfaces then
      ri.Sys_Error(ERR_DROP, 'Mod_ParseMarksurfaces: bad surface number');
    _out^ := @(msurface_arrp(loadmodel^.surfaces)^[j]);
    inc(Integer(_in), SizeOf(_in^));
    inc(Integer(_out), SizeOf(_out^));
  end;
end;

(*
=================
Mod_LoadSurfedges
=================
*)

procedure Mod_LoadSurfedges(l: lump_p);
var
  i, count: Integer;
  _in, _out: PInteger;
begin
  _in := Pointer(Integer(mod_base) + l^.fileofs);
  if (l^.filelen mod SizeOf(_in^)) <> 0 then
    ri.Sys_Error(ERR_DROP, PChar('MOD_LoadBmodel: funny lump size in ' + string(loadmodel^.name)));
  count := Trunc(l^.filelen / sizeof(_in^));
  _out := Hunk_Alloc((count + 24) * sizeof(_out^)); // extra for skybox

  loadmodel^.surfedges := _out;
  loadmodel^.numsurfedges := count;

  for i := 0 to count - 1 do
  begin
    _out^ := LittleLong(_in^);
    inc(Integer(_in), SizeOf(_in^));
    inc(Integer(_out), SizeOf(_out^));
  end;
end;

(*
=================
Mod_LoadPlanes
=================
*)

procedure Mod_LoadPlanes(l: lump_p);
var
  i, j: Integer;
  _out: mplane_p;
  _in: dplane_p;
  count: Integer;
  bits: Integer;
begin
  _in := Pointer(Integer(mod_base) + l^.fileofs);
  if (l^.filelen mod SizeOf(_in^)) <> 0 then
    ri.Sys_Error(ERR_DROP, PChar('MOD_LoadBmodel: funny lump size in ' + string(loadmodel^.name)));
  count := Trunc(l^.filelen / sizeof(_in^));
  _out := Hunk_Alloc((count + 6) * sizeof(_out^)); // extra for skybox

  loadmodel^.planes := _out;
  loadmodel^.numplanes := count;

  for i := 0 to count - 1 do
  begin
    bits := 0;
    for j := 0 to 2 do
    begin
      _out^.normal[j] := LittleFloat(_in^.normal[j]);
      if _out^.normal[j] < 0 then
        bits := bits or (1 shl j);
    end {next j};

    _out^.dist := LittleFloat(_in^.dist);
    _out^._type := LittleLong(_in^._type);
    _out^.signbits := bits;
    inc(Integer(_in), SizeOf(_in^));
    inc(Integer(_out), SizeOf(_out^));
  end;
end;

(*
=================
Mod_LoadBrushModel
=================
*)

procedure Mod_LoadBrushModel(_mod: model_p; buffer: Pointer);
var
  i: Integer;
  header: dheader_p;
  bm: dmodel_p;
  starmod: model_p;
begin
  loadmodel^._type := mod_brush;
  if loadmodel <> @mod_known[0] then
    ri.Sys_Error(ERR_DROP, 'Loaded a brush model after the world');

  header := dheader_p(buffer);

  i := LittleLong(header^.version);
  if i <> BSPVERSION then
    ri.Sys_Error(ERR_DROP, PChar('Mod_LoadBrushModel: ' + string(_mod^.name) + ' has wrong version number (' + IntToStr(i) + ' should be ' + IntToStr(BSPVERSION) + ')'));

// swap all the lumps
  mod_base := PByte(header);

  for i := 0 to (sizeof(dheader_t) div 4) - 1 do
    PIntegerArray(header)^[i] := LittleLong(PIntegerArray(header)^[i]);

// load into heap

  Mod_LoadVertexes(@header^.lumps[LUMP_VERTEXES]);
  Mod_LoadEdges(@header^.lumps[LUMP_EDGES]);
  Mod_LoadSurfedges(@header^.lumps[LUMP_SURFEDGES]);
  Mod_LoadLighting(@header^.lumps[LUMP_LIGHTING]);
  Mod_LoadPlanes(@header^.lumps[LUMP_PLANES]);
  Mod_LoadTexinfo(@header^.lumps[LUMP_TEXINFO]);
  Mod_LoadFaces(@header^.lumps[LUMP_FACES]);
  Mod_LoadMarksurfaces(@header^.lumps[LUMP_LEAFFACES]);
  Mod_LoadVisibility(@header^.lumps[LUMP_VISIBILITY]);
  Mod_LoadLeafs(@header^.lumps[LUMP_LEAFS]);
  Mod_LoadNodes(@header^.lumps[LUMP_NODES]);
  Mod_LoadSubmodels(@header^.lumps[LUMP_MODELS]);
  r_numvisleafs := 0;
  R_NumberLeafs(loadmodel^.nodes);

//
// set up the submodels
//
  for i := 0 to _mod^.numsubmodels - 1 do
  begin
    bm := dmodel_p(Integer(_mod^.submodels) + (i * SizeOf(dmodel_t)));
    starmod := @mod_inline[i];
    starmod^ := loadmodel^;

    starmod^.firstmodelsurface := bm^.firstface;
    starmod^.nummodelsurfaces := bm^.numfaces;
    starmod^.firstnode := bm^.headnode;
    if starmod^.firstnode >= loadmodel^.numnodes then
      ri.Sys_Error(ERR_DROP, PChar('Inline model ' + IntToStr(i) + ' has bad firstnode'));

    VectorCopy(bm^.maxs, starmod^.maxs);
    VectorCopy(bm^.mins, starmod^.mins);

    if i = 0 then
      loadmodel^ := starmod^;
  end {next i};

  R_InitSkyBox;
end;

(*
==============================================================================

ALIAS MODELS

==============================================================================
*)

(*
=================
Mod_LoadAliasModel
=================
*)

procedure Mod_LoadAliasModel(_mod: model_p; buffer: Pointer);
var
  i, j: Integer;
  pinmodel, pheader: dmdl_p;
  pinst, poutst: dstvert_p;
  pintri, pouttri: dtriangle_p;
  pinframe, poutframe: daliasframe_p;
  pincmd, poutcmd: PInteger;
  version: Integer;
begin
  pinmodel := dmdl_p(buffer);

  version := LittleLong(pinmodel^.version);
  if version <> ALIAS_VERSION then
    ri.Sys_Error(ERR_DROP, PChar(string(_mod^.name) + ' has wrong version number (' + IntToStr(version) + ' should be ' + IntToStr(ALIAS_VERSION)));

  pheader := Hunk_Alloc(LittleLong(pinmodel^.ofs_end));

  // byte swap the header fields and sanity check
  for i := 0 to (sizeof(dmdl_t) div 4) - 1 do
    PIntegerArray(pheader)^[i] := LittleLong(PIntegerArray(buffer)^[i]);

  if pheader^.skinheight > MAX_LBM_HEIGHT then
    ri.Sys_Error(ERR_DROP, PChar('model ' + string(_mod^.name) + ' has a skin taller than ' + IntToStr(MAX_LBM_HEIGHT)));

  if pheader^.num_xyz <= 0 then
    ri.Sys_Error(ERR_DROP, PChar('model ' + string(_mod^.name) + ' has no vertices'));

  if pheader^.num_xyz > MAX_VERTS then
    ri.Sys_Error(ERR_DROP, PChar('model ' + string(_mod^.name) + ' has too many vertices'));

  if pheader^.num_st <= 0 then
    ri.Sys_Error(ERR_DROP, PChar('model ' + string(_mod^.name) + ' has no st vertices'));

  if pheader^.num_tris <= 0 then
    ri.Sys_Error(ERR_DROP, PChar('model ' + string(_mod^.name) + ' has no triangles'));

  if pheader.num_frames <= 0 then
    ri.Sys_Error(ERR_DROP, PChar('model ' + string(_mod^.name) + ' has no frames'));

//
// load base s and t vertices (not used in gl version)
//
  pinst := dstvert_p(Integer(pinmodel) + pheader^.ofs_st);
  poutst := dstvert_p(Integer(pheader) + pheader^.ofs_st);

  for i := 0 to pheader^.num_st - 1 do
  begin
    poutst^.s := LittleShort(pinst^.s);
    poutst^.t := LittleShort(pinst^.t);
    Inc(Integer(pinst), SizeOf(dstvert_t));
    Inc(Integer(poutst), SizeOf(dstvert_t));
//    dstvert_a(poutst)[i].s := LittleShort(dstvert_a(pinst)[i].s);
//    dstvert_a(poutst)[i].t := LittleShort(dstvert_a(pinst)[i].t);
  end {next i};

//
// load triangle lists
//
  pintri := dtriangle_p(Integer(pinmodel) + pheader^.ofs_tris);
  pouttri := dtriangle_p(Integer(pheader) + pheader^.ofs_tris);

  for i := 0 to pheader^.num_tris - 1 do
  begin
    for j := 0 to 2 do
    begin
      pouttri^.index_xyz[j] := LittleShort(pintri^.index_xyz[j]);
      pouttri^.index_st[j] := LittleShort(pintri^.index_st[j]);
//      dtriangle_a(pouttri)[i].index_xyz[j] := LittleShort(dtriangle_a(pintri)[i].index_xyz[j]);
//      dtriangle_a(pouttri)[i].index_st[j] := LittleShort(dtriangle_a(pintri)[i].index_st[j]);
    end {next j};
    Inc(Integer(pouttri), SizeOf(pouttri^));
    Inc(Integer(pintri), SizeOf(pintri^));
  end {next i};

//
// load the frames
//
  for i := 0 to pheader^.num_frames - 1 do
  begin
    pinframe := daliasframe_p(Integer(pinmodel) + pheader^.ofs_frames + i * pheader^.framesize);
    poutframe := daliasframe_p(Integer(pheader) + pheader^.ofs_frames + i * pheader^.framesize);

    Move(pinframe^.name, poutframe^.name, SizeOf(poutframe^.name));
    for j := 0 to 2 do
    begin
      poutframe^.scale[j] := LittleFloat(pinframe^.scale[j]);
      poutframe^.translate[j] := LittleFloat(pinframe^.translate[j]);
    end {next j};
    // verts are all 8 bit, so no swapping needed
    move(pinframe^.verts[0], poutframe^.verts[0], pheader^.num_xyz * sizeof(dtrivertx_t));
  end {next i};

  _mod^._type := mod_alias;

  //
  // load the glcmds
  //
  pincmd := PInteger(Integer(pinmodel) + pheader^.ofs_glcmds);
  poutcmd := PInteger(Integer(pheader) + pheader^.ofs_glcmds);
  for i := 0 to pheader^.num_glcmds - 1 do
    PIntegerArray(poutcmd)^[i] := LittleLong(PIntegerArray(pincmd)^[i]);

  // register all skins
  move(PChar(Integer(pinmodel) + pheader^.ofs_skins)^,
    PChar(Integer(pheader) + pheader^.ofs_skins)^,
    pheader^.num_skins * MAX_SKINNAME);
  for i := 0 to pheader.num_skins - 1 do
  begin
    _mod^.skins[i] := R_FindImage(PChar(Integer(pheader) + pheader.ofs_skins + i * MAX_SKINNAME), it_skin);
  end {next i};
end {procedure};

(*
==============================================================================

SPRITE MODELS

==============================================================================
*)

(*
=================
Mod_LoadSpriteModel
=================
*)

procedure Mod_LoadSpriteModel(_mod: model_p; buffer: Pointer);
var
  sprin: dsprite_p;
  sprout: dsprite_p;
  i: Integer;
begin
  sprin := dsprite_p(buffer);
  sprout := Hunk_Alloc(modfilelen);

  sprout^.ident := LittleLong(sprin^.ident);
  sprout^.version := LittleLong(sprin^.version);
  sprout^.numframes := LittleLong(sprin^.numframes);

  if sprout^.version <> SPRITE_VERSION then
    ri.Sys_Error(ERR_DROP, PChar(string(_mod^.name) + ' has wrong version number (' + IntToStr(sprout^.version) + ' should be ' + IntToStr(SPRITE_VERSION) + ')'));

  if sprout^.numframes > MAX_MD2SKINS then
    ri.Sys_Error(ERR_DROP, PChar(string(_mod^.name) + ' has too many frames (' + IntToStr(sprout^.numframes) + ' > ' + IntToStr(MAX_MD2SKINS) + ')'));

  // byte swap everything
  for i := 0 to sprout^.numframes - 1 do
  begin
    sprout^.frames[i].width := LittleLong(sprin^.frames[i].width);
    sprout^.frames[i].height := LittleLong(sprin^.frames[i].height);
    sprout^.frames[i].origin_x := LittleLong(sprin^.frames[i].origin_x);
    sprout^.frames[i].origin_y := LittleLong(sprin^.frames[i].origin_y);
    move(sprin^.frames[i].name[0], sprout^.frames[i].name[0], MAX_SKINNAME);
    _mod^.skins[i] := R_FindImage(sprout^.frames[i].name, it_sprite);
  end;
  _mod^._type := mod_sprite;
end {procedure};

//=============================================================================

(*
@@@@@@@@@@@@@@@@@@@@@
R_BeginRegistration

Specifies the model that will be used as the world
@@@@@@@@@@@@@@@@@@@@@
*)

procedure R_BeginRegistration(model: PChar); cdecl;
var
  fullname: array[0..MAX_QPATH - 1] of Char;
  flushmap: cvar_p;
begin
  inc(registration_sequence);
  r_oldviewcluster := -1; // force markleafs
  Com_sprintf(fullname, sizeof(fullname), 'maps/%s.bsp', [model]);

  D_FlushCaches;
  // explicitly free the old map if different
  // this guarantees that mod_known[0] is the world map
  flushmap := ri.Cvar_Get('flushmap', '0', 0);
  if (strcomp(PChar(@mod_known[0].name), fullname) <> 0) or (flushmap^.value <> 0.0) then
    Mod_Free(@mod_known[0]);
  r_worldmodel := R_RegisterModel(fullname);
  R_NewMap;
end {procedure};

(*
@@@@@@@@@@@@@@@@@@@@@
R_RegisterModel

@@@@@@@@@@@@@@@@@@@@@
*)

function R_RegisterModel(name: PChar): Pointer;
var
  _mod: model_p;
  i: Integer;
  sprout: dsprite_p;
  pheader: dmdl_p;
begin
  _mod := Mod_ForName(name, false);
  if _mod <> nil then
  begin
    _mod^.registration_sequence := registration_sequence;

    // register any images used by the models
    if _mod^._type = mod_sprite then
    begin
      sprout := dsprite_p(_mod^.extradata);
      for i := 0 to sprout^.numframes - 1 do
        _mod^.skins[i] := R_FindImage(PChar(@sprout^.frames[i].name), it_sprite);
    end
    else
      if _mod^._type = mod_alias then
      begin
        pheader := dmdl_p(_mod^.extradata);
        for i := 0 to pheader^.num_skins - 1 do
          _mod^.skins[i] := R_FindImage(PChar(Integer(pheader) + pheader^.ofs_skins + i * MAX_SKINNAME), it_skin);
//PGM
        _mod^.numframes := pheader^.num_frames;
//PGM
      end
      else
        if _mod^._type = mod_brush then
        begin
          for i := 0 to _mod^.numtexinfo - 1 do
            mtexinfo_p(Integer(_mod^.texinfo) + (i * SizeOf(mtexinfo_t)))^.image^.registration_sequence := registration_sequence;
        end;
  end;
  Result := _mod;
end;

(*
@@@@@@@@@@@@@@@@@@@@@
R_EndRegistration

@@@@@@@@@@@@@@@@@@@@@
*)

procedure R_EndRegistration;
var
  i: Integer;
  _mod: model_p;
begin
  _mod := @mod_known[0];
  for i := 0 to mod_numknown - 1 do
  begin
    if _mod^.name[0] = #0 then
    begin
      Inc(Integer(_mod), SizeOf(_mod^));
      continue;
    end;
    if _mod^.registration_sequence <> registration_sequence then
    begin
      // don't need this model
      Hunk_Free(_mod^.extradata);
      FillChar(_mod^, sizeof(_mod^), 0);
    end
    else
    begin
      // make sure it is paged in
      Com_PageInMemory(_mod^.extradata, _mod^.extradatasize);
    end;
    Inc(Integer(_mod), SizeOf(_mod^));
  end;

  R_FreeUnusedImages;
end;

//=============================================================================

(*
================
Mod_Free
================
*)

procedure Mod_Free(_mod: model_p);
begin
  Hunk_Free(_mod^.extradata);
  FillChar(_mod^, sizeof(_mod^), 0);
end {procedure};

(*
================
Mod_FreeAll
================
*)

procedure Mod_FreeAll;
var
  i: Integer;
begin
  for i := 0 to mod_numknown - 1 do
  begin
    if mod_known[i].extradatasize <> 0 then
    begin
      Mod_Free(@mod_known[i]);
    end {if};
  end {next i};
end {procedure};

initialization
// Check the size of types defined in r_model.h
  Assert(sizeof(mvertex_t) = 12);
  Assert(sizeof(mplane_t) = 20);
  Assert(sizeof(medge_t) = 8);
  Assert(sizeof(mtexinfo_t) = 52);
  Assert(sizeof(msurface_t) = 68);
  Assert(sizeof(mnode_t) = 40);
  Assert(sizeof(mleaf_t) = 44);
  Assert(sizeof(modtype_t) = 4);
  Assert(sizeof(model_t) = 368);
end.
