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

unit r_main;
{----------------------------------------------------------------------------}
{                                                                            }
{ File(s): r_main.c                                                          }
{                                                                            }
{ Initial conversion by : YgriK (Igor Karpov) - glYgriK@hotbox.ru            }
{ Initial conversion on : 23-Jan-2002                                        }
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
{ Updated on : 17-July-2002                                                  }
{ Updated by : CodeFusion (Michael@Skovslund.dk)                             }
{                                                                            }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{                                                                            }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{                                                                            }
{----------------------------------------------------------------------------}

interface

uses
  q_shared,
  ref,
  r_local,
  r_model;

procedure Com_Printf(fmt: PChar; args: array of const); overload;
procedure Com_Printf(fmt: PChar); overload;

function _SAR(AValue: Integer; AShift: Byte): Integer;
function _SAL(AValue: Integer; AShift: Byte): Integer;

var
  vid: viddef_t;
  ri: refimport_t;

  d_8to24table: array[0..256 - 1] of Cardinal;
  r_worldentity: entity_t;

  skyname: array[0..MAX_QPATH - 1] of Char;
  skyrotate: Single;
  skyaxis: vec3_t;
  sky_images: array[0..6 - 1] of image_p;

  r_newrefdef: refdef_t;
  currentmodel: model_p;

  r_worldmodel: model_p;

  r_warpbuffer: array[0..(WARP_WIDTH * WARP_HEIGHT) - 1] of Byte;

  sw_state: swstate_t;

  colormap: Pointer;
  viewlightvec: vec3_t;
//alight_t  r_viewlighting = {128, 192, viewlightvec};
  r_viewlighting: alight_t = (ambientlight: 128; shadelight: 192; plightvec: @viewlightvec);

  r_time1: Single;
  r_numallocatededges: Integer;
  r_aliasuvscale: Single = 1.0;
  r_outofsurfaces: Integer;
  r_outofedges: Integer;

  r_dowarp: qboolean;

  r_pcurrentvertbase: mvertex_p;

  c_surf: Integer;
  r_maxsurfsseen: Integer;
  r_maxedgesseen: Integer;
  r_cnumsurfs: Integer;
  r_surfsonstack: qboolean;
  r_clipflags: Integer;

//
// view origin
//
  vup: vec3_t;
  base_vup: vec3_t;
  vpn: vec3_t;
  base_vpn: vec3_t;
  vright: vec3_t;
  base_vright: vec3_t;
  r_origin: vec3_t;

//
// screen size info
//
  r_refdef: oldrefdef_t;
  xcenter: Single;
  ycenter: Single;
  xscale: Single;
  yscale: Single;
  xscaleinv: Single;
  yscaleinv: Single;
  xscaleshrink: Single;
  yscaleshrink: Single;
  aliasxscale: Single;
  aliasyscale: Single;
  aliasxcenter: Single;
  aliasycenter: Single;

  r_screenwidth: Integer;

  verticalFieldOfView: Single;
  xOrigin: Single;
  yOrigin: Single;

  screenedge: array[0..4 - 1] of mplane_t;

//
// refresh flags
//
  r_framecount: Integer = 1; // so frame counts initialized to 0 don't match
  r_visframecount: Integer;
  d_spanpixcount: Integer;
  r_polycount: Integer;
  r_drawnpolycount: Integer;
  r_wholepolycount: Integer;

  pfrustum_indexes: array[0..4 - 1] of PInteger;
  r_frustum_indexes: array[0..(4 * 6) - 1] of Integer;

  r_viewleaf: mleaf_p;
  r_viewcluster: Integer;
  r_oldviewcluster: Integer;

  r_notexture_mip: image_p;

  da_time1: Single;
  da_time2: Single;
  dp_time1: Single;
  dp_time2: Single;
  db_time1: Single;
  db_time2: Single;
  rw_time1: Single;
  rw_time2: Single;
  se_time1: Single;
  se_time2: Single;
  de_time1: Single;
  de_time2: Single;

  r_lefthand: cvar_p;
  sw_aliasstats: cvar_p;
  sw_allow_modex: cvar_p;
  sw_clearcolor: cvar_p;
  sw_drawflat: cvar_p;
  sw_draworder: cvar_p;
  sw_maxedges: cvar_p;
  sw_maxsurfs: cvar_p;
  sw_mode: cvar_p;
  sw_reportedgeout: cvar_p;
  sw_reportsurfout: cvar_p;
  sw_stipplealpha: cvar_p;
  sw_surfcacheoverride: cvar_p;
  sw_waterwarp: cvar_p;

  r_drawworld: cvar_p;
  r_drawentities: cvar_p;
  r_dspeeds: cvar_p;
  r_fullbright: cvar_p;
  r_lerpmodels: cvar_p;
  r_novis: cvar_p;

  r_speeds: cvar_p;
  r_lightlevel: cvar_p; //FIXME HACK

  vid_fullscreen: cvar_p;
  vid_gamma: cvar_p;

//PGM
  sw_lockpvs: cvar_p;
//PGM

//#define  STRINGER(x) "x"
procedure R_MarkLeaves;
procedure R_GammaCorrectAndSetPalette(const palette: PByte);
procedure R_NewMap;

{$IFNDEF id386}

// r_vars.c

// all global and static refresh variables are collected in a contiguous block
// to avoid cache conflicts.

//-------------------------------------------------------
// global refresh variables
//-------------------------------------------------------

// FIXME: make into one big structure, like cl or sv
// FIXME: do separately for refresh engine and driver

// d_vars.c

// all global and static refresh variables are collected in a contiguous block
// to avoid cache conflicts.

//-------------------------------------------------------
// global refresh variables
//-------------------------------------------------------

// FIXME: make into one big structure, like cl or sv
// FIXME: do separately for refresh engine and driver
var
  d_sdivzstepu: Single;
  d_tdivzstepu: Single;
  d_zistepu: Single;
  d_sdivzstepv: Single;
  d_tdivzstepv: Single;
  d_zistepv: Single;
  d_sdivzorigin: Single;
  d_tdivzorigin: Single;
  d_ziorigin: Single;

  sadjust: fixed16_t;
  tadjust: fixed16_t;
  bbextents: fixed16_t;
  bbextentt: fixed16_t;

  cacheblock: pixel_p;
  cachewidth: Integer;
  d_viewbuffer: pixel_P;
  d_pzbuffer: PSmallInt;
  d_zrowbytes: Cardinal;
  d_zwidth: Cardinal;

{$ENDIF} // !id386

var
  r_notexture_buffer: array[0..1024 - 1] of Byte;

function GetRefAPI(rimp: refimport_t): refexport_t; cdecl;

implementation

uses
  SysUtils,
  Math,
  r_misc,
  r_surf,
  r_image,
  r_draw,
  r_rast,
  r_light,
  rw_imp,
  r_bsp_c,
  r_edge,
  r_edgea,
  r_part,
  r_poly,
  r_scan,
  r_sprite,
  r_alias_c,
  DelphiTypes,
  q_shwin;

const
  NUM_BEAM_SEGS = 6;

var
  modified: qboolean; (*was static*)
// 3dstudio environment map names
  suf: array[0..5] of PChar = ('rt', 'bk', 'lf', 'ft', 'up', 'dn');
  r_skysideimage: array[0..5] of Integer = (5, 2, 4, 1, 0, 3);

procedure Draw_GetPalette; forward;

procedure R_BeginFrame(camera_separation: Single); cdecl; forward;

procedure Draw_BuildGammaTable; cdecl; forward;

procedure R_DrawBeam(e: entity_p); cdecl; forward;

function _SAR(AValue: Integer; AShift: Byte): Integer;
asm
  mov eax,AValue
  mov cl,AShift
  sar eax,cl
end;

function _SAL(AValue: Integer; AShift: Byte): Integer;
asm
  mov eax,AValue
  mov cl,AShift
  sal eax,cl
end;

(*
==================
R_InitTextures
==================
*)

procedure R_InitTextures;
var
  x, y, m: Integer;
  dest: PByte;
begin
// create a simple checkerboard texture for the default
  r_notexture_mip := image_p(@r_notexture_buffer);

  r_notexture_mip^.height := 16;
  r_notexture_mip^.width := 16;
  r_notexture_mip^.pixels[0] := PByte(@r_notexture_buffer[sizeof(image_t)]);
  r_notexture_mip^.pixels[1] := PByte(Cardinal(r_notexture_mip^.pixels[0]) + 16 * 16);
  r_notexture_mip^.pixels[2] := PByte(Cardinal(r_notexture_mip^.pixels[1]) + 8 * 8);
  r_notexture_mip^.pixels[3] := PByte(Cardinal(r_notexture_mip^.pixels[2]) + 4 * 4);

  for m := 0 to 3 do
  begin
    dest := r_notexture_mip^.pixels[m];
    for y := 0 to (16 shr m) - 1 do
    begin
      for x := 0 to (16 shr m) - 1 do
      begin
        if ((y < (8 shr m)) xor (x < (8 shr m))) then
          dest^ := 0
        else
          dest^ := $FF;
        dest := PByte(Cardinal(dest) + 1);
      end;
    end;
  end;
end;

(*
================
R_InitTurb
================
*)

procedure R_InitTurb;
var
  i: Integer;
begin
  for i := 0 to 1280 - 1 do
  begin
    sintable[i] := Trunc(AMP + sin(i * 3.14159 * 2 / CYCLE) * AMP);
    intsintable[i] := Trunc(AMP2 + sin(i * 3.14159 * 2 / CYCLE) * AMP2); // AMP2, not 20
    blanktable[i] := 0; //PGM
  end;
end;

procedure R_Register;
begin
  sw_aliasstats := ri.Cvar_Get('sw_polymodelstats', '0', 0);
  sw_allow_modex := ri.Cvar_Get('sw_allow_modex', '1', CVAR_ARCHIVE);
  sw_clearcolor := ri.Cvar_Get('sw_clearcolor', '2', 0);
  sw_drawflat := ri.Cvar_Get('sw_drawflat', '0', 0);
  sw_draworder := ri.Cvar_Get('sw_draworder', '0', 0);
  sw_maxedges := ri.Cvar_Get('sw_maxedges', 'MAXSTACKSURFACES', 0);
  sw_maxsurfs := ri.Cvar_Get('sw_maxsurfs', '0', 0);
  sw_mipcap := ri.Cvar_Get('sw_mipcap', '0', 0);
  sw_mipscale := ri.Cvar_Get('sw_mipscale', '1', 0);
  sw_reportedgeout := ri.Cvar_Get('sw_reportedgeout', '0', 0);
  sw_reportsurfout := ri.Cvar_Get('sw_reportsurfout', '0', 0);
  sw_stipplealpha := ri.Cvar_Get('sw_stipplealpha', '0', CVAR_ARCHIVE);
  sw_surfcacheoverride := ri.Cvar_Get('sw_surfcacheoverride', '0', 0);
  sw_waterwarp := ri.Cvar_Get('sw_waterwarp', '1', 0);
  sw_mode := ri.Cvar_Get('sw_mode', '0', CVAR_ARCHIVE);

  r_lefthand := ri.Cvar_Get('hand', '0', CVAR_USERINFO or CVAR_ARCHIVE);
  r_speeds := ri.Cvar_Get('r_speeds', '0', 0);
  r_fullbright := ri.Cvar_Get('r_fullbright', '0', 0);
  r_drawentities := ri.Cvar_Get('r_drawentities', '1', 0);
  r_drawworld := ri.Cvar_Get('r_drawworld', '1', 0);
  r_dspeeds := ri.Cvar_Get('r_dspeeds', '0', 0);
  r_lightlevel := ri.Cvar_Get('r_lightlevel', '0', 0);
  r_lerpmodels := ri.Cvar_Get('r_lerpmodels', '1', 0);
  r_novis := ri.Cvar_Get('r_novis', '0', 0);

  vid_fullscreen := ri.Cvar_Get('vid_fullscreen', '0', CVAR_ARCHIVE);
  vid_gamma := ri.Cvar_Get('vid_gamma', '1.0', CVAR_ARCHIVE);

  ri.Cmd_AddCommand('modellist', Mod_Modellist_f);
  ri.Cmd_AddCommand('screenshot', R_ScreenShot_f);
  ri.Cmd_AddCommand('imagelist', R_ImageList_f);

  sw_mode^.modified := True; // force us to do mode specific stuff later
  vid_gamma^.modified := true; // force us to rebuild the gamma table later

//PGM
  sw_lockpvs := ri.Cvar_Get('sw_lockpvs', '0', 0);
//PGM
end;

procedure R_UnRegister;
begin
  ri.Cmd_RemoveCommand('screenshot');
  ri.Cmd_RemoveCommand('modellist');
  ri.Cmd_RemoveCommand('imagelist');
end;

(*
===============
R_Init
===============
*)

function R_Init(hInstance: Cardinal; wndProc: Pointer): Integer; cdecl;
begin
  try
    R_InitImages;
    Mod_Init;
    Draw_InitLocal;
    R_InitTextures;

    R_InitTurb;

    view_clipplanes[0].leftedge := 1;
    view_clipplanes[1].rightedge := 1;
    view_clipplanes[1].leftedge := 0;
    view_clipplanes[2].leftedge := 0;
    view_clipplanes[3].leftedge := 0;
    view_clipplanes[0].rightedge := 0;
    view_clipplanes[2].rightedge := 0;
    view_clipplanes[3].rightedge := 0;

    r_refdef.xOrigin := XCENTERING;
    r_refdef.yOrigin := YCENTERING;

// TODO: collect 386-specific code in one place
{$IF defined(id386)}

//*****************************************************************************
// This should not be neccessary, as all asm code has been changed so it will
// not change the upcodes directly during runtime.
//*****************************************************************************
//  Sys_MakeCodeWriteable ((long)R_EdgeCodeStart,
//               (long)R_EdgeCodeEnd - (long)R_EdgeCodeStart);
//  Sys_SetFPCW ();    // get bit masks for FPCW  (FIXME: is this id386?)
{$IFEND} // id386

    r_aliasuvscale := 1.0;

    R_Register;
    Draw_GetPalette;
    SWimp_Init(Pointer(hInstance), wndProc);

 // create the window
    R_BeginFrame(0);

    ri.Con_Printf(PRINT_ALL, 'ref_soft version: %s', REF_VERSION);
  except
    ri.Sys_Error(ERR_FATAL,'Unhandled exception in R_Init.')
  end;
  Result := 1;
end;

(*
===============
R_Shutdown
===============
*)

procedure R_Shutdown; cdecl;
begin
 // free z buffer
  if (d_pzbuffer <> nil) then
  begin
    FreeMem(d_pzbuffer);
    d_pzbuffer := nil;
  end;
 // free surface cache
  if (sc_base <> nil) then
  begin
    D_FlushCaches;
    FreeMem(sc_base);
    sc_base := nil;
  end;

 // free colormap
  if (vid.colormap <> nil) then
  begin
    FreeMem(vid.colormap);
    vid.colormap := nil;
  end;
  R_UnRegister;
  Mod_FreeAll;
  R_ShutdownImages;

  SWimp_Shutdown;
end;

(*
===============
R_NewMap
===============
*)

procedure R_NewMap;
begin
  r_viewcluster := -1;

  r_cnumsurfs := Trunc(sw_maxsurfs^.value);

  if (r_cnumsurfs <= MINSURFACES) then
    r_cnumsurfs := MINSURFACES;

  if (r_cnumsurfs > NUMSTACKSURFACES) then
  begin
    surfaces := AllocMem(r_cnumsurfs * sizeof(surf_t));
    surface_p := surfaces;
    surf_max := surf_p(Integer(surfaces) + (r_cnumsurfs * sizeof(surf_t)));
    r_surfsonstack := false;
 // surface 0 doesn't really exist; it's just a dummy because index 0
 // is used to indicate no edge attached to surface
    Dec(Integer(surfaces), SizeOf(surf_t));
    R_SurfacePatch;
  end
  else
  begin
    r_surfsonstack := true;
  end;

  r_maxedgesseen := 0;
  r_maxsurfsseen := 0;

  r_numallocatededges := Trunc(sw_maxedges^.value);

  if (r_numallocatededges < MINEDGES) then
    r_numallocatededges := MINEDGES;

  if (r_numallocatededges <= NUMSTACKEDGES) then
  begin
    auxedges := nil;
  end
  else
  begin
    auxedges := AllocMem(r_numallocatededges * sizeof(edge_t));
  end;
end;

(*
===============
R_MarkLeaves

Mark the leaves and nodes that are in the PVS for the current
cluster
===============
*)

procedure R_MarkLeaves;
var
  vis: PByte;
  node: mnode_p;
  i: Integer;
  leaf: mleaf_p;
  cluster: Integer;
begin
  if ((r_oldviewcluster = r_viewcluster) and (r_novis^.value = 0.0) and (r_viewcluster <> -1)) then
    Exit;

 // development aid to let you run around and see exactly where
 // the pvs ends
  if (sw_lockpvs^.value <> 0.0) then
    Exit;

  Inc(r_visframecount);
  r_oldviewcluster := r_viewcluster;

  if (r_novis^.value <> 0.0) or (r_viewcluster = -1) or (r_worldmodel^.vis = nil) then
  begin
  // mark everything
    for i := 0 to r_worldmodel^.numleafs - 1 do
      mleaf_arrp(r_worldmodel^.leafs)^[i].visframe := r_visframecount;
    for i := 0 to r_worldmodel^.numnodes - 1 do
      mnode_arrp(r_worldmodel^.nodes)^[i].visframe := r_visframecount;
    Exit;
  end;

  vis := Mod_ClusterPVS(r_viewcluster, r_worldmodel);

  leaf := r_worldmodel^.leafs;
  for I := 0 to r_worldmodel^.numleafs - 1 do
  begin
    cluster := leaf^.cluster;
    if (cluster = -1) then
    begin
      Inc(Integer(leaf), Sizeof(mleaf_t));
      continue;
    end;
    if (PByteArray(vis)^[cluster shr 3] and (1 shl (cluster and 7))) <> 0 then
    begin
      node := mnode_p(leaf);
      repeat
        if (node^.visframe = r_visframecount) then
          break;
        node^.visframe := r_visframecount;
        node := node^.parent;
      until (node = nil);
    end;
    Inc(Cardinal(leaf), Sizeof(mleaf_t));
  end;
end;

(*
** R_DrawNullModel
**
** IMPLEMENT THIS!
*)

procedure R_DrawNullModel;
begin
end;

(*
=============
R_DrawEntitiesOnList
=============
*)

procedure R_DrawEntitiesOnList;
var
  i: Integer;
  translucent_entities: qboolean;
begin
  translucent_entities := False;
  if (r_drawentities^.value = 0.0) then
    Exit;

 // all bmodels have already been drawn by the edge list
  for I := 0 to r_newrefdef.num_entities - 1 do
  begin
    currententity := @entity_arrp(r_newrefdef.entities)^[i];

    if (currententity^.flags and RF_TRANSLUCENT) <> 0 then
    begin
      translucent_entities := true;
      continue;
    end;

    if (currententity^.flags and RF_BEAM) <> 0 then
    begin
      modelorg[0] := -r_origin[0];
      modelorg[1] := -r_origin[1];
      modelorg[2] := -r_origin[2];
      VectorCopy(vec3_origin, r_entorigin);
      R_DrawBeam(currententity);
    end
    else
    begin
      currentmodel := currententity^.model;
      if (currentmodel = nil) then
      begin
        R_DrawNullModel;
        continue;
      end;
      VectorCopy(vec3_p(@currententity^.origin)^, r_entorigin);
      VectorSubtract(r_origin, r_entorigin, modelorg);

      case (currentmodel^._type) of
        mod_sprite:
          R_DrawSprite;
        mod_alias:
          R_AliasDrawModel;
      end;
    end
  end;

  if (not translucent_entities) then
    Exit;

  for I := 0 to r_newrefdef.num_entities - 1 do
  begin
    currententity := @entity_arrp(r_newrefdef.entities)^[i];

    if ((currententity^.flags and RF_TRANSLUCENT) = 0) then
      continue;

    if (currententity^.flags and RF_BEAM) <> 0 then
    begin
      modelorg[0] := -r_origin[0];
      modelorg[1] := -r_origin[1];
      modelorg[2] := -r_origin[2];
      VectorCopy(vec3_origin, r_entorigin);
      R_DrawBeam(currententity);
    end
    else
    begin
      currentmodel := currententity^.model;
      if (currentmodel = nil) then
      begin
        R_DrawNullModel;
        continue;
      end;
      VectorCopy(vec3_p(@currententity^.origin)^, r_entorigin);
      VectorSubtract(r_origin, r_entorigin, modelorg);

      case (currentmodel^._type) of
        mod_sprite:
          R_DrawSprite;
        mod_alias:
          R_AliasDrawModel;
      end;
    end;
  end;
end;

(*
=============
R_BmodelCheckBBox
=============
*)

function R_BmodelCheckBBox(minmaxs: PSingle): Integer;
var
  i: Integer;
  pindex: PInteger;
  clipflags: Integer;
  acceptpt: vec3_t;
  rejectpt: vec3_t;
  d: Single;
begin
  clipflags := 0;

  for I := 0 to 4 - 1 do
  begin
 // generate accept and reject points
 // FIXME: do with fast look-ups or integer tests based on the sign bit
 // of the floating point values

    pindex := pfrustum_indexes[i];

    rejectpt[0] := PSingleArray(minmaxs)^[PIntegerArray(pindex)^[0]];
    rejectpt[1] := PSingleArray(minmaxs)^[PIntegerArray(pindex)^[1]];
    rejectpt[2] := PSingleArray(minmaxs)^[PIntegerArray(pindex)^[2]];

    d := DotProduct(rejectpt, view_clipplanes[i].normal);
    d := d - view_clipplanes[i].dist;

    if (d <= 0) then
    begin
      Result := BMODEL_FULLY_CLIPPED;
      Exit;
    end;

    acceptpt[0] := PSingleArray(minmaxs)^[PIntegerArray(pindex)^[3 + 0]];
    acceptpt[1] := PSingleArray(minmaxs)^[PIntegerArray(pindex)^[3 + 1]];
    acceptpt[2] := PSingleArray(minmaxs)^[PIntegerArray(pindex)^[3 + 2]];

    d := DotProduct(acceptpt, view_clipplanes[i].normal);
    d := d - view_clipplanes[i].dist;

    if (d <= 0) then
      clipflags := clipflags or (1 shl i);
  end;
  Result := clipflags;
end;

(*
===================
R_FindTopnode

Find the first node that splits the given box
===================
*)

function R_FindTopnode(var mins: vec3_t; var maxs: vec3_t): mnode_p;
var
  splitplane: mplane_p;
  sides: Integer;
  node: mnode_p;
begin
  node := r_worldmodel^.nodes;

  while (True) do
  begin
    if (node^.visframe <> r_visframecount) then
    begin
      Result := nil; // not visible at all
      Exit;
    end;

    if (node^.contents <> CONTENTS_NODE) then
    begin
      if (node^.contents <> CONTENTS_SOLID) then
      begin
        Result := node; // we've reached a non-solid leaf, so it's
        Exit; //  visible and not BSP clipped
      end;
      Result := nil; // in solid, so not visible
      Exit;
    end;

    splitplane := node^.plane;
    sides := BOX_ON_PLANE_SIDE(mins, maxs, cplane_p(splitplane));

    if (sides = 3) then
    begin
      Result := node; // this is the splitter
      Exit;
    end;
 // not split yet; recurse down the contacted side
    if (sides and 1) = 1 then
      node := node^.children[0]
    else
      node := node^.children[1];
  end;
end;

(*
=============
RotatedBBox

Returns an axially aligned box that contains the input box at the given rotation
=============
*)

procedure RotatedBBox(var mins: vec3_t; var maxs: vec3_t; var angles: vec3_t; var tmins: vec3_t; var tmaxs: vec3_t);
var
  tmp, v: vec3_t;
  i, j: Integer;
  _forward: vec3_t;
  right: vec3_t;
  up: vec3_t;
begin
  if ((angles[0] = 0.0) and (angles[1] = 0.0) and (angles[2] = 0.0)) then
  begin
    VectorCopy(mins, tmins);
    VectorCopy(maxs, tmaxs);
    Exit;
  end;

  for I := 0 to 2 do
  begin
    tmins[i] := 99999;
    tmaxs[i] := -99999;
  end;

  AngleVectors(angles, @_forward, @right, @up);

  for I := 0 to 7 do
  begin
    if (i and 1) = 1 then
      tmp[0] := mins[0]
    else
      tmp[0] := maxs[0];

    if (i and 2) = 2 then
      tmp[1] := mins[1]
    else
      tmp[1] := maxs[1];

    if (i and 4) = 4 then
      tmp[2] := mins[2]
    else
      tmp[2] := maxs[2];

    VectorScale(_forward, tmp[0], v);
    VectorMA(v, -tmp[1], right, v);
    VectorMA(v, tmp[2], up, v);

    for j := 0 to 2 do
    begin
      if (v[j] < tmins[j]) then
        tmins[j] := v[j];
      if (v[j] > tmaxs[j]) then
        tmaxs[j] := v[j];
    end;
  end;
end;

(*
=============
R_DrawBEntitiesOnList
=============
*)

procedure R_DrawBEntitiesOnList;
var
  i, clipflags: Integer;
  oldorigin: vec3_t;
  mins, maxs: vec3_t;
  minmaxs: array[0..6 - 1] of Single;
  topnode: mnode_p;
begin
  if (r_drawentities^.value = 0.0) then
    Exit;

  VectorCopy(modelorg, oldorigin);
  insubmodel := true;
  r_dlightframecount := r_framecount;

  for I := 0 to r_newrefdef.num_entities - 1 do
  begin
    currententity := @entity_arrp(r_newrefdef.entities)^[i];
    currentmodel := currententity^.model;
    if (currentmodel = nil) then
      continue;
    if (currentmodel^.nummodelsurfaces = 0) then
      continue; // clip brush only
    if (currententity^.flags and RF_BEAM) = RF_BEAM then
      continue;
    if (currentmodel^._type <> mod_brush) then
      continue;
 // see if the bounding box lets us trivially reject, also sets
 // trivial accept status
    RotatedBBox(currentmodel^.mins, currentmodel^.maxs, vec3_p(@currententity^.angles)^, mins, maxs);
    VectorAdd(mins, vec3_p(@currententity^.origin)^, vec3_p(@minmaxs)^);
    VectorAdd(maxs, vec3_p(@currententity^.origin)^, vec3_p(@minmaxs[3])^);

    clipflags := R_BmodelCheckBBox(@minmaxs[0]);
    if (clipflags = BMODEL_FULLY_CLIPPED) then
      continue; // off the edge of the screen

    topnode := R_FindTopnode(vec3_p(@minmaxs)^, vec3_p(@minmaxs[3])^);
    if (topnode = nil) then
      continue; // no part in a visible leaf

    VectorCopy(vec3_p(@currententity^.origin)^, r_entorigin);
    VectorSubtract(r_origin, r_entorigin, modelorg);

    r_pcurrentvertbase := currentmodel^.vertexes;

 // FIXME: stop transforming twice
    R_RotateBmodel;

 // calculate dynamic lighting for bmodel
    R_PushDlights(currentmodel);

    if (topnode^.contents = CONTENTS_NODE) then
    begin
  // not a leaf; has to be clipped to the world BSP
      r_clipflags := clipflags;
      R_DrawSolidClippedSubmodelPolygons(currentmodel, topnode);
    end
    else
    begin
  // falls entirely in one leaf, so we just put all the
  // edges in the edge list and let 1/z sorting handle
  // drawing order
      R_DrawSubmodelPolygons(currentmodel, clipflags, topnode);
    end;

 // put back world rotation and frustum clipping
 // FIXME: R_RotateBmodel should just work off base_vxx
    VectorCopy(base_vpn, vpn);
    VectorCopy(base_vup, vup);
    VectorCopy(base_vright, vright);
    VectorCopy(oldorigin, modelorg);
    R_TransformFrustum;
  end;
  insubmodel := false;
end;

(*
================
R_EdgeDrawing
================
*)

procedure R_EdgeDrawing;
var
  ledges  : array[0..(NUMSTACKEDGES+Trunc((CACHE_SIZE-1) / sizeof(edge_t)))] of edge_t;
  lsurfs  : array[0..(NUMSTACKSURFACES+Trunc((CACHE_SIZE-1) / sizeof(surf_t)))] of surf_t;
begin
(*********
CODEFUSION:
  Somewhere in here the walls are not drawn.
**********)
  if (r_newrefdef.rdflags and RDF_NOWORLDMODEL) <> 0 then
    Exit;

  if (auxedges <> nil) then
  begin
    r_edges := auxedges;
  end
  else
  begin
    r_edges := edge_p((Cardinal(@ledges[0])+CACHE_SIZE-1) and (not Cardinal(CACHE_SIZE-1)));
  end;

  if (r_surfsonstack) then
  begin
    surfaces := surf_p((Cardinal(@lsurfs[0])+CACHE_SIZE-1) and (not Cardinal(CACHE_SIZE-1)));
    surf_max := surf_p(Integer(surfaces)+(r_cnumsurfs*SizeOf(surf_t)));
  // surface 0 doesn't really exist; it's just a dummy because index 0
  // is used to indicate no edge attached to surface
    Dec(Integer(surfaces), Sizeof(surf_t));
    R_SurfacePatch;
  end;
  R_BeginEdgeFrame;

  if (r_dspeeds^.value <> 0.0) then
  begin
    rw_time1 := Sys_Milliseconds;
  end;

  R_RenderWorld;

  if (r_dspeeds^.value <> 0.0) then
  begin
    rw_time2 := Sys_Milliseconds;
    db_time1 := rw_time2;
  end;

  R_DrawBEntitiesOnList;

  if (r_dspeeds^.value <> 0.0) then
  begin
    db_time2 := Sys_Milliseconds;
    se_time1 := db_time2;
  end;
  R_ScanEdges;
end;

//=======================================================================

(*
=============
R_CalcPalette

=============
*)

procedure R_CalcPalette;
var
  palette: array[0..256, 0..4] of Byte;
  _in, _out: PByte;
  i, j, v: Integer;
  alpha: Single;
  one_minus_alpha: Single;
  premult: vec3_t;
begin
  alpha := r_newrefdef.blend[3];
  if (alpha <= 0.0) then
  begin
    if (modified) then
    begin // set back to default
      modified := false;
      R_GammaCorrectAndSetPalette(PByte(@d_8to24table));
      Exit;
    end;
    Exit;
  end;

  modified := true;
  if (alpha > 1) then
    alpha := 1;

  premult[0] := r_newrefdef.blend[0] * alpha * 255;
  premult[1] := r_newrefdef.blend[1] * alpha * 255;
  premult[2] := r_newrefdef.blend[2] * alpha * 255;

  one_minus_alpha := (1.0 - alpha);

  _in := PByte(@d_8to24table);
  _out := PByte(@palette[0, 0]);
  for I := 0 to 255 do
  begin
    for j := 0 to 2 do
    begin
      v := Trunc(premult[j] + one_minus_alpha * PByte(Integer(_in) + j)^);
      if (v > 255) then
        v := 255;
      PByte(Integer(_out) + j)^ := v;
    end;
    PByte(Integer(_out) + 3)^ := 255;
    _in := PByte(Integer(_in) + 4);
    _out := PByte(Integer(_out) + 4);
  end;

  R_GammaCorrectAndSetPalette(PByte(@palette[0, 0]));
//  SWimp_SetPalette( palette[0] );
end;

//=======================================================================

procedure R_SetLightLevel;
var
  light: vec3_t;
begin
  if (((r_newrefdef.rdflags and RDF_NOWORLDMODEL) <> 0) or (r_drawentities^.value = 0.0) or (currententity = nil)) then
  begin
    r_lightlevel^.value := 150.0;
    Exit;
  end;

 // save off light value for server to look at (BIG HACK!)
  R_LightPoint(vec3_p(@r_newrefdef.vieworg)^, light);
  r_lightlevel^.value := 150.0 * light[0];
end;

(*
@@@@@@@@@@@@@@@@
R_RenderFrame

@@@@@@@@@@@@@@@@
*)

procedure R_RenderFrame(fd: refdef_p); cdecl;
begin
  Move(fd^, r_newrefdef, SizeOf(refdef_t));

  if ((r_worldmodel = nil) and ((r_newrefdef.rdflags and RDF_NOWORLDMODEL) = 0)) then
    ri.Sys_Error(ERR_FATAL, 'R_RenderView: NULL worldmodel');

  VectorCopy(vec3_p(@fd^.vieworg)^, r_refdef.vieworg);
  VectorCopy(vec3_p(@fd^.viewangles)^, r_refdef.viewangles);

  if ((r_speeds^.value <> 0.0) or (r_dspeeds^.value <> 0.0)) then
    r_time1 := Sys_Milliseconds;

  R_SetupFrame;
  R_MarkLeaves; // done here so we know if we're in water
  R_PushDlights(r_worldmodel);
  R_EdgeDrawing;

  if (r_dspeeds^.value <> 0.0) then
  begin
    se_time2 := Sys_Milliseconds;
    de_time1 := se_time2;
  end;

  // draws models (monster, weapons, items etc.).
  R_DrawEntitiesOnList;

  if (r_dspeeds^.value <> 0.0) then
  begin
    de_time2 := Sys_Milliseconds;
    dp_time1 := Sys_Milliseconds;
  end;

  R_DrawParticles;

  if (r_dspeeds^.value <> 0.0) then
    dp_time2 := Sys_Milliseconds;

  R_DrawAlphaSurfaces;

  R_SetLightLevel;

  if (r_dowarp) then
    D_WarpScreen;

  if (r_dspeeds^.value <> 0.0) then
    da_time1 := Sys_Milliseconds;

  if (r_dspeeds^.value <> 0.0) then
    da_time2 := Sys_Milliseconds;

  R_CalcPalette;

  if (sw_aliasstats^.value <> 0.0) then
    R_PrintAliasStats;

  if (r_speeds^.value <> 0.0) then
    R_PrintTimes;

  if (r_dspeeds^.value <> 0.0) then
    R_PrintDSpeeds;

  if ((sw_reportsurfout^.value <> 0.0) and (r_outofsurfaces <> 0)) then
    ri.Con_Printf(PRINT_ALL,'Short %d surfaces', r_outofsurfaces);

  if ((sw_reportedgeout^.value <> 0.0) and (r_outofedges <> 0)) then
    ri.Con_Printf(PRINT_ALL,'Short roughly %d edges', (r_outofedges * 2 div 3));
end;

(*
** R_InitGraphics
*)

procedure R_InitGraphics(width: Integer; height: Integer);
begin
  vid.width := width;
  vid.height := height;

 // free z buffer
  if (d_pzbuffer <> nil) then
  begin
    FreeMem(d_pzbuffer);
    d_pzbuffer := nil;
  end;

 // free surface cache
  if (sc_base <> nil) then
  begin
    D_FlushCaches;
    FreeMem(sc_base);
    sc_base := nil;
  end;
  d_pzbuffer := AllocMem(vid.width * vid.height * 2);
  R_InitCaches;
  R_GammaCorrectAndSetPalette(PByte(@d_8to24table));
end;

(*
** R_BeginFrame
*)

procedure R_BeginFrame(camera_separation: Single); cdecl;
var
  err: rserr_t;
begin
 (*
 ** rebuild the gamma correction palette if necessary
 *)
  if (vid_gamma^.modified) then
  begin
    Draw_BuildGammaTable;
    R_GammaCorrectAndSetPalette(PByte(@d_8to24table));
    vid_gamma^.modified := false;
  end;

  while ((sw_mode^.modified) or (vid_fullscreen^.modified)) do
  begin
  (*
  ** if this returns rserr_invalid_fullscreen then it set the mode but not as a
  ** fullscreen mode, e.g. 320x200 on a system that doesn't support that res
  *)
    err := SWimp_SetMode(@vid.width, @vid.height, Trunc(sw_mode^.value), (vid_fullscreen^.value <> 0.0));
    if (err = rserr_ok) then
    begin
      R_InitGraphics(vid.width, vid.height);

      sw_state.prev_mode := Trunc(sw_mode^.value);
      vid_fullscreen^.modified := false;
      sw_mode^.modified := false;
    end
    else
    begin
      if (err = rserr_invalid_mode) then
      begin
        ri.Cvar_SetValue('sw_mode', sw_state.prev_mode);
        ri.Con_Printf(PRINT_ALL, 'ref_soft::R_BeginFrame() - could not set mode' + #13#10);
      end
      else
        if (err = rserr_invalid_fullscreen) then
        begin
          R_InitGraphics(vid.width, vid.height);

          ri.Cvar_SetValue('vid_fullscreen', 0);
          ri.Con_Printf(PRINT_ALL, 'ref_soft::R_BeginFrame() - fullscreen unavailable in this mode' + #13#10);
          sw_state.prev_mode := Trunc(sw_mode^.value);
//        vid_fullscreen->modified = false;
//        sw_mode->modified = false;
        end
        else
        begin
          ri.Sys_Error(ERR_FATAL, 'ref_soft::R_BeginFrame() - catastrophic mode change failure' + #13#10);
        end;
    end;
  end;
end;

(*
================
Draw_BuildGammaTable
================
*)

procedure Draw_BuildGammaTable;
var
  i: Integer;
  inf: Integer;
  g: Single;
begin
  g := vid_gamma^.value;

  if (g = 1.0) then
  begin
    for I := 0 to 255 do
      sw_state.gammatable[i] := i;
    Exit;
  end;

  for I := 0 to 255 do
  begin
    inf := Trunc(255 * Power((i + 0.5) / 255.5, g) + 0.5);
    if (inf < 0) then
      inf := 0;
    if (inf > 255) then
      inf := 255;
    sw_state.gammatable[i] := inf;
  end;
end;

(*
** R_GammaCorrectAndSetPalette
*)

procedure R_GammaCorrectAndSetPalette(const palette: PByte);
var
  i: Integer;
begin
  for I := 0 to 255 do
  begin
    sw_state.currentpalette[i * 4 + 0] := sw_state.gammatable[PByte(Integer(palette) + (i * 4 + 0))^];
    sw_state.currentpalette[i * 4 + 1] := sw_state.gammatable[PByte(Integer(palette) + (i * 4 + 1))^];
    sw_state.currentpalette[i * 4 + 2] := sw_state.gammatable[PByte(Integer(palette) + (i * 4 + 2))^];
  end;
  SWimp_SetPalette(PByteArray(@sw_state.currentpalette[0]));
end;

(*
** R_CinematicSetPalette
*)

procedure R_CinematicSetPalette(palette: PByte); cdecl;
var
  palette32: array[0..1024 - 1] of Byte;
  i, j, w: Integer;
  d: PIntegerArray;
begin
 // clear screen to black to avoid any palette flash
  w := abs(vid.rowbytes) shr 2; // stupid negative pitch win32 stuff...
  for I := 0 to vid.height - 1 do
  begin
    d := PIntegerArray(Integer(vid.buffer) + i * vid.rowbytes);
    for j := 0 to w - 1 do
      d[j] := 0;
  end;
 // flush it to the screen
  SWimp_EndFrame;

  if (palette <> nil) then
  begin
    for I := 0 to 255 do
    begin
      palette32[i * 4 + 0] := PByteArray(palette)^[i * 3 + 0];
      palette32[i * 4 + 1] := PByteArray(palette)^[i * 3 + 1];
      palette32[i * 4 + 2] := PByteArray(palette)^[i * 3 + 2];
      palette32[i * 4 + 3] := $FF;
    end;
    R_GammaCorrectAndSetPalette(PByte(@palette32));
  end
  else
  begin
    R_GammaCorrectAndSetPalette(PByte(@d_8to24table));
  end;
end;

(*
** R_DrawBeam
*)

procedure R_DrawBeam(e: entity_p);
var
  i: Integer;
  perpvec: vec3_t;
  direction: vec3_t;
  normalized_direction: vec3_t;
  start_points: array[0..NUM_BEAM_SEGS - 1] of vec3_t;
  end_points: array[0..NUM_BEAM_SEGS - 1] of vec3_t;
  oldorigin: vec3_t;
  origin: vec3_t;
begin
  oldorigin[0] := e^.oldorigin[0];
  oldorigin[1] := e^.oldorigin[1];
  oldorigin[2] := e^.oldorigin[2];

  origin[0] := e^.origin[0];
  origin[1] := e^.origin[1];
  origin[2] := e^.origin[2];

  direction[0] := oldorigin[0] - origin[0];
  normalized_direction[0] := direction[0];
  direction[1] := oldorigin[1] - origin[1];
  normalized_direction[1] := direction[1];
  direction[2] := oldorigin[2] - origin[2];
  normalized_direction[2] := direction[2];

  if (VectorNormalize(normalized_direction) = 0.0) then
    Exit;

  PerpendicularVector(perpvec, normalized_direction);
  VectorScale(perpvec, e^.frame / 2, perpvec);

  for I := 0 to NUM_BEAM_SEGS - 1 do
  begin
    RotatePointAroundVector(start_points[i], normalized_direction, perpvec, (360.0 / NUM_BEAM_SEGS) * i);
    VectorAdd(start_points[i], origin, start_points[i]);
    VectorAdd(start_points[i], direction, end_points[i]);
  end;

  for I := 0 to NUM_BEAM_SEGS - 1 do
  begin
    R_IMFlatShadedQuad(start_points[i],
      end_points[i],
      end_points[(i + 1) mod NUM_BEAM_SEGS],
      start_points[(i + 1) mod NUM_BEAM_SEGS],
      e^.skinnum and $FF,
      e^.alpha);
  end;
end;

//===================================================================

(*
============
R_SetSky
============
*)

procedure R_SetSky(name: PChar; rotate: Single; axis: vec3_p); cdecl;
var
  i: Integer;
  pathname: array[0..MAX_QPATH - 1] of Char;
begin
  StrLCopy(skyname, name, sizeof(skyname) - 1);
  skyrotate := rotate;
  VectorCopy(axis^, skyaxis);

  for I := 0 to 5 do
  begin
    Com_sprintf(pathname, sizeof(pathname), 'env/%s%s.pcx', [skyname, suf[r_skysideimage[i]]]);
    r_skytexinfo[i].image := R_FindImage(pathname, it_sky);
  end;
end;

(*
===============
Draw_GetPalette
===============
*)

procedure Draw_GetPalette;
var
  pal, _out: PByteArray;
  i: Integer;
  r, g, b: Integer;
begin
 // get the palette and colormap
  LoadPCX('pics/colormap.pcx', @vid.colormap, @pal, nil, nil);
  if (vid.colormap = nil) then
    ri.Sys_Error(ERR_FATAL, 'Couldn''t load pics/colormap.pcx');
  vid.alphamap := PByte(Integer(vid.colormap) + 64 * 256);

  _out := PByteArray(@d_8to24table);
  for I := 0 to 255 do
  begin
    r := pal^[i * 3 + 0];
    g := pal^[i * 3 + 1];
    b := pal^[i * 3 + 2];
    _out^[0] := r;
    _out^[1] := g;
    _out^[2] := b;
    _out := PByteArray(Integer(_out) + 4);
  end;
  FreeMem(pal);
end;

(*
@@@@@@@@@@@@@@@@@@@@@
GetRefAPI

@@@@@@@@@@@@@@@@@@@@@
*)
var
  re: refexport_t;

function GetRefAPI(rimp: refimport_t): refexport_t; cdecl;
begin
  try
    ri := rimp;
    re.api_version := API_VERSION;
    re.BeginRegistration := R_BeginRegistration;
    re.RegisterModel := R_RegisterModel;
    re.RegisterSkin := R_RegisterSkin;
    re.RegisterPic := Draw_FindPic;
    re.SetSky := R_SetSky;
    re.EndRegistration := R_EndRegistration;
    re.RenderFrame := R_RenderFrame;
    re.DrawGetPicSize := Draw_GetPicSize;
    re.DrawPic := Draw_Pic;
    re.DrawStretchPic := Draw_StretchPic;
    re.DrawChar := Draw_Char;
    re.DrawTileClear := Draw_TileClear;
    re.DrawFill := Draw_Fill;
    re.DrawFadeScreen := Draw_FadeScreen;
    re.DrawStretchRaw := Draw_StretchRaw;
    re.Init := R_Init;
    re.Shutdown := R_Shutdown;
    re.CinematicSetPalette := R_CinematicSetPalette;
    re.BeginFrame := R_BeginFrame;
    re.EndFrame := SWimp_EndFrame;
    re.AppActivate := SWimp_AppActivate;
    Swap_Init;
  except
    ri.Sys_Error(ERR_FATAL, 'Unhandled exception in GetRefAPI.')
  end;
  // DEBUGGERS NOTE:
  // The result MUST be the last assignment otherwise Delphi generate faulty code
  // and the result becomes NIL. This is due to the except statement which clears
  // the eax register and it does not restore it to its original value :-(
  Result := re;
end;

// this is only here so the functions in q_shared.c and q_shwin.c can link
(*
procedure Sys_Error (char *error, ...)
begin
 va_list    argptr;
 char    text[1024];

 va_start (argptr, error);
 vsprintf (text, error, argptr);
 va_end (argptr);

 ri.Sys_Error (ERR_FATAL, "%s", text);
end;
*)

procedure Com_Printf(fmt: PChar; args: array of const);
var
  text: array[0..1024 - 1] of char;
begin
  DelphiStrFmt(text, fmt, args);
  ri.Con_Printf(PRINT_ALL, text);
end;

procedure Com_Printf(fmt: PChar); overload;
begin
  Com_Printf(fmt, []);
end;

end.
