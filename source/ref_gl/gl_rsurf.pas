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
{ File(s): GL_RSURF.C: surface-related refresh code                          }
{                                                                            }
{ Initial conversion by : YgriK (Igor Karpov) - glYgriK@hotbox.ru            }
{ Initial conversion on : 16-Jan-2002                                        }
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
// 28.06.2003 Juha: Proofreaded
// GL_RSURF.C: surface-related refresh code

unit gl_rsurf;

interface

uses
  q_shared,
  ref,
  qfiles,
  gl_local,
  OpenGL,
  qgl_win,
  gl_model_h,
  gl_rmain;

procedure R_DrawAlphaSurfaces;
procedure R_DrawBrushModel(e: entity_p);
procedure R_DrawWorld;
procedure R_MarkLeaves;

procedure GL_BuildPolygonFromSurface(fa: msurface_p);
procedure GL_CreateSurfaceLightmap(surf: msurface_p);
procedure GL_BeginBuildingLightmaps(m: model_p);
procedure GL_EndBuildingLightmaps;

var
  c_visible_lightmaps: Integer;
  c_visible_textures: Integer;


implementation

uses
  q_shwin,
  SysUtils,
  CPas,
  DelphiTypes,
  qgl_h,
  gl_light,
  gl_model,
  gl_warp,
  gl_image;

var
  modelorg: vec3_t; // relative to viewpoint
  r_alpha_surfaces: msurface_p;

const
  DYNAMIC_LIGHT_WIDTH = 128;
  DYNAMIC_LIGHT_HEIGHT = 128;

  LIGHTMAP_BYTES = 4;

  BLOCK_WIDTH = 128;
  BLOCK_HEIGHT = 128;

  MAX_LIGHTMAPS = 128;

  GL_LIGHTMAP_FORMAT = GL_RGBA;

type
  gllightmapstate_t = record
    internal_format: integer;
    current_lightmap_texture: integer;

    lightmap_surfaces: array[0..MAX_LIGHTMAPS - 1] of msurface_p;

    allocated: array[0..BLOCK_WIDTH - 1] of integer;

    // the lightmap texture data needs to be kept in
    // main memory so texsubimage can update properly
    lightmap_buffer: array[0..4 * BLOCK_WIDTH * BLOCK_HEIGHT - 1] of byte;
  end;

var
  gl_lms: gllightmapstate_t;


procedure LM_InitBlock; forward;
procedure LM_UploadBlock(dynamic_: qboolean); forward;
function LM_AllocBlock(w, h: integer; var x, y: integer): qboolean; forward;


{*
=============================================================

 BRUSH MODELS

=============================================================
*}

{*
===============
R_TextureAnimation

Returns the proper texture for a given time and base texture
===============
*}
function R_TextureAnimation(tex: mtexinfo_p): image_p;
var
  c: integer;
begin
  if (tex.next = nil) then
  begin
    Result := tex.image;
    Exit;
  end;

  c := currententity.frame mod tex.numframes;
  while (c <> 0) do
  begin
    tex := tex.next;
    Dec(c);
  end;

  Result := tex.image;
end; //function

(*
/*
=================
WaterWarpPolyVerts

Mangles the x and y coordinates in a copy of the poly
so that any drawing routine can be water warped
=================
*/
glpoly_t *WaterWarpPolyVerts (glpoly_t *p)
{
 int      i;
 float   *v, *nv;
 static byte   buffer[1024];
 glpoly_t *out;

 out = (glpoly_t * )buffer;

 out->numverts = p->numverts;
 v = p->verts[0];
 nv = out->verts[0];
 for (i=0 ; i<p->numverts ; i++, v+= VERTEXSIZE, nv+=VERTEXSIZE)
 {
  nv[0] = v[0] + 4*sin(v[1]*0.05+r_newrefdef.time)*sin(v[2]*0.05+r_newrefdef.time);
  nv[1] = v[1] + 4*sin(v[0]*0.05+r_newrefdef.time)*sin(v[2]*0.05+r_newrefdef.time);

  nv[2] = v[2];
  nv[3] = v[3];
  nv[4] = v[4];
  nv[5] = v[5];
  nv[6] = v[6];
 }

 return out;
}

/*
================
DrawGLWaterPoly

Warp the vertex coordinates
================
*/
void DrawGLWaterPoly (glpoly_t *p)
{
 int      i;
 float   *v;

 p = WaterWarpPolyVerts (p);
 qglBegin (GL_TRIANGLE_FAN);
 v = p->verts[0];
 for (i=0 ; i<p->numverts ; i++, v+= VERTEXSIZE)
 {
  qglTexCoord2f (v[3], v[4]);
  qglVertex3fv (v);
 }
 qglEnd ();
}
void DrawGLWaterPolyLightmap (glpoly_t *p)
{
 int      i;
 float   *v;

 p = WaterWarpPolyVerts (p);
 qglBegin (GL_TRIANGLE_FAN);
 v = p->verts[0];
 for (i=0 ; i<p->numverts ; i++, v+= VERTEXSIZE)
 {
  qglTexCoord2f (v[5], v[6]);
  qglVertex3fv (v);
 }
 qglEnd ();
}
*)

{*
================
DrawGLPoly
================
*}
procedure DrawGLPoly(p: glpoly_p);
var
  i: integer;
  v: PSingle;
begin
  qglBegin(GL_POLYGON);

  i := 0;
  v := @p^.verts[0];
  while (i < p^.NumVerts) do
  begin
    qglTexCoord2f(PSingleArray(v)^[3], PSingleArray(v)^[4]);
    qglVertex3fv(PGLFloat(v));
    Inc(i);
    Inc(v, VERTEXSIZE);
  end;
  qglEnd();
end;

//============
//PGM
{*
================
DrawGLFlowingPoly -- version of DrawGLPoly that handles scrolling texture
================
*}
procedure DrawGLFlowingPoly(fa: msurface_p);
var
  i: integer;
  v: PSingle;
  p: glpoly_p;
  scroll: Single;
begin
  p := fa.polys;

  scroll := -64 * ((r_newrefdef.time / 40.0) - Trunc(r_newrefdef.time / 40.0));
  if (scroll = 0.0) then
    scroll := -64.0;

  qglBegin(GL_POLYGON);
  v := @p.verts[0];
  i := 0;
  while (i < p^.NumVerts) do
  begin
    qglTexCoord2f((PSingleArray(v)^[3] + scroll), PSingleArray(v)^[4]);
    qglVertex3fv(PGLfloat(v));
    Inc(v, VERTEXSIZE);
    Inc(i);
  end;
  qglEnd();
end;

//PGM
//============

{*
** R_DrawTriangleOutlines
*}

procedure R_DrawTriangleOutlines;
var
  i, j: integer;
  p: glpoly_p;
  surf: msurface_p;
begin
  if (gl_showtris.value = 0) then
    Exit;

  qglDisable(GL_TEXTURE_2D);
  qglDisable(GL_DEPTH_TEST);
  qglColor4f(1, 1, 1, 1);

  for i := 0 to MAX_LIGHTMAPS - 1 do
  begin
    surf := gl_lms.lightmap_surfaces[i];
    while (surf <> nil) do
    begin
      p := surf.polys;
      while (p <> nil) do
      begin
        for j := 2 to p.numverts - 1 do
        begin
          qglBegin(GL_LINE_STRIP);
          qglVertex3fv(@p.verts[0]);
          qglVertex3fv(@p.verts[j - 1]);
          qglVertex3fv(@p.verts[j]);
          qglVertex3fv(@p.verts[0]);
          qglEnd();
        end;
        p := p^.chain;
      end;
      surf := surf^.lightmapchain;
    end;
  end;

  qglEnable(GL_DEPTH_TEST);
  qglEnable(GL_TEXTURE_2D);
end; //procedure

{*
** DrawGLPolyChain
*}

procedure DrawGLPolyChain(p: glpoly_p; soffset, toffset: Single);
var
  v: PSingle;
  j: integer;
begin
  if (soffset = 0) and (toffset = 0) then
  begin
    while (p <> nil) do
    begin
      qglBegin(GL_POLYGON);
      v := @p^.verts[0];
      j := 0;
      while (j < p^.NumVerts) do
      begin
        qglTexCoord2f(PSingleArray(v)^[5], PSingleArray(v)^[6]);
        qglVertex3fv(PGLfloat(v));
        Inc(j);
        Inc(v, VERTEXSIZE);
      end;
      qglEnd();
      p := p^.Chain;
    end;
  end
  else
  begin
    while (p <> nil) do
    begin
      qglBegin(GL_POLYGON);
      v := @p.verts[0];
      j := 0;
      while (j < p^.NumVerts) do
      begin
        qglTexCoord2f(PSingleArray(v)^[5] - soffset, PSingleArray(v)^[6] - toffset);
        qglVertex3fv(PGLfloat(v));
        Inc(j);
        Inc(v, VERTEXSIZE);
      end;
      qglEnd();
      p := p^.Chain;
    end;
  end;
end;

{*
** R_BlendLightMaps
**
** This routine takes all the given light mapped surfaces in the world and
** blends them into the framebuffer.
*}

procedure R_BlendLightmaps;
var
  i, smax, tmax: integer;
  surf,
    newdrawsurf,
    drawsurf: msurface_p;
  base: PByte;
begin
  newdrawsurf := nil;

  // don't bother if we're set to fullbright
  if (r_fullbright.value <> 0) then
    Exit;
  if (r_worldmodel.lightdata = nil) then
    Exit;

  // don't bother writing Z
  qglDepthMask(False);

  {*
  ** set the appropriate blending mode unless we're only looking at the
  ** lightmaps.
  *}
  if (gl_lightmap.value = 0) then
  begin
    qglEnable(GL_BLEND);

    if (gl_saturatelighting.value <> 0) then
      qglBlendFunc(GL_ONE, GL_ONE)
    else
    begin
      if (gl_monolightmap.string_[0] <> '0') then
      begin
        case UpCase(gl_monolightmap.string_[0]) of
          'I': qglBlendFunc(GL_ZERO, GL_SRC_COLOR);
          'L': qglBlendFunc(GL_ZERO, GL_SRC_COLOR);
          //'A':  <- Juha: This falls to default section as well.
        else
          qglBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        end;
      end
      else
        qglBlendFunc(GL_ZERO, GL_SRC_COLOR);
    end; //else
  end; //if

  if (currentmodel = r_worldmodel) then
    c_visible_lightmaps := 0;

  {*
  ** render static lightmaps first
  *}
  for i := 1 to MAX_LIGHTMAPS - 1 do
    if (gl_lms.lightmap_surfaces[i] <> nil) then
    begin
      if (currentmodel = r_worldmodel) then
        Inc(c_visible_lightmaps);
      GL_Bind(gl_state.lightmap_textures + i);

      surf := gl_lms.lightmap_surfaces[i];
      while (surf <> nil) do
      begin
        if (surf.polys <> nil) then
          DrawGLPolyChain(surf.polys, 0, 0);
        surf := surf^.LightMapChain;
      end;
    end;

  {*
  ** render dynamic lightmaps
  *}
  if (gl_dynamic.value <> 0) then
  begin
    LM_InitBlock();

    GL_Bind(gl_state.lightmap_textures + 0);

    if (currentmodel = r_worldmodel) then
      Inc(c_visible_lightmaps);

    newdrawsurf := gl_lms.lightmap_surfaces[0];

    surf := gl_lms.lightmap_surfaces[0];
    while (surf <> nil) do
    begin
      smax := (surf.extents[0] shr 4) + 1;
      tmax := (surf.extents[1] shr 4) + 1;

      if (LM_AllocBlock(smax, tmax, surf.dlight_s, surf.dlight_t)) then
      begin
        base := @gl_lms.lightmap_buffer;
        Inc(base, (surf.dlight_t * BLOCK_WIDTH + surf.dlight_s) * LIGHTMAP_BYTES);

        R_BuildLightMap(surf, PByteArray(base), BLOCK_WIDTH * LIGHTMAP_BYTES);
      end
      else
      begin
             // upload what we have so far
        LM_UploadBlock(true);

             // draw all surfaces that use this lightmap
        drawsurf := newdrawsurf;
        while (drawsurf <> surf) do
        begin
          if (drawsurf.polys <> nil) then
            DrawGLPolyChain(drawsurf.polys,
              (drawsurf.light_s - drawsurf.dlight_s) * (1.0 / 128.0),
              (drawsurf.light_t - drawsurf.dlight_t) * (1.0 / 128.0));
          drawsurf := drawsurf^.lightmapchain;
        end;

        newdrawsurf := drawsurf;

             // clear the block
        LM_InitBlock();

             // try uploading the block now
        if (not LM_AllocBlock(smax, tmax, surf.dlight_s, surf.dlight_t)) then
          ri.Sys_Error(ERR_FATAL, 'Consecutive calls to LM_AllocBlock(%d,%d) failed (dynamic)'#10, [smax, tmax]);

        base := @gl_lms.lightmap_buffer;
        Inc(base, (surf.dlight_t * BLOCK_WIDTH + surf.dlight_s) * LIGHTMAP_BYTES);

        R_BuildLightMap(surf, PByteArray(base), BLOCK_WIDTH * LIGHTMAP_BYTES);
      end;
      surf := surf^.lightmapchain;
    end;

    {*
    ** draw remainder of dynamic lightmaps that haven't been uploaded yet
    *}
    if (newdrawsurf <> nil) then
      LM_UploadBlock(true);

    surf := newdrawsurf;
    while (surf <> nil) do
    begin
      if (surf.polys <> nil) then
        DrawGLPolyChain(surf.polys,
          (surf.light_s - surf.dlight_s) * (1.0 / 128.0),
          (surf.light_t - surf.dlight_t) * (1.0 / 128.0));
      surf := surf^.lightmapchain;
    end;
  end; //if

  {*
  ** restore state
  *}
  qglDisable(GL_BLEND);
  qglBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  qglDepthMask(True);
end; //procedure

{*
================
R_RenderBrushPoly
================
*}
procedure R_RenderBrushPoly(fa: msurface_p);
var
  maps,
    smax, tmax: integer;
  image: image_p;
  is_dynamic: qboolean;
  temp: array[0..34 * 34 - 1] of Cardinal;
label
  _dynamic;
begin
  is_dynamic := false;

  Inc(c_brush_polys);

  image := R_TextureAnimation(fa.texinfo);

  if ((fa.flags and SURF_DRAWTURB) <> 0) then
  begin
    GL_Bind(image^.texnum);

    // warp texture, no lightmaps
    GL_TexEnv(GL_MODULATE);
    qglColor4f(gl_state.inverse_intensity,
      gl_state.inverse_intensity,
      gl_state.inverse_intensity,
      1.0);
    EmitWaterPolys(fa);
    GL_TexEnv(GL_REPLACE);

    Exit;
  end
  else
  begin
    GL_Bind(image^.texnum);

    GL_TexEnv(GL_REPLACE);
  end;

//======
//PGM
  if (fa.texinfo.flags and SURF_FLOWING) <> 0 then
    DrawGLFlowingPoly(fa)
  else
    DrawGLPoly(fa^.polys);
//PGM
//======

  {*
  ** check for lightmap modification
  *}
  maps := 0;
  while (maps < MAXLIGHTMAPS) and (fa^.styles[maps] <> 255) do
  begin
    if (r_newrefdef.lightstyles[fa^.styles[maps]].white <> fa^.cached_light[maps]) then
      goto _dynamic;
    Inc(maps);
  end;

  // dynamic this frame or dynamic previously
  if (fa^.dlightframe = r_framecount) then
  begin
    _dynamic:
    if (gl_dynamic.value <> 0) then
    begin
//            if (!( fa.texinfo.flags & (SURF_SKY|SURF_TRANS33|SURF_TRANS66|SURF_WARP ) ) ) then
      if ((fa^.texinfo.flags and (SURF_SKY or SURF_TRANS33 or SURF_TRANS66 or SURF_WARP)) = 0) then
        is_dynamic := true;
    end;
  end; //if

  if (is_dynamic) then
  begin
    if (((fa^.styles[maps] >= 32) or (fa^.styles[maps] = 0)) and
      (fa^.dlightframe <> r_framecount)) then
    begin
      smax := (fa^.extents[0] shr 4) + 1;
      tmax := (fa^.extents[1] shr 4) + 1;

      R_BuildLightMap(fa, @temp, smax * 4);
      R_SetCacheState(fa);

      GL_Bind(gl_state.lightmap_textures + fa.lightmaptexturenum);

      qglTexSubImage2D(GL_TEXTURE_2D, 0,
        fa^.light_s, fa^.light_t,
        smax, tmax,
        GL_LIGHTMAP_FORMAT,
        GL_UNSIGNED_BYTE, @temp);

      fa^.lightmapchain := gl_lms.lightmap_surfaces[fa^.lightmaptexturenum];
      gl_lms.lightmap_surfaces[fa^.lightmaptexturenum] := fa;
    end
    else
    begin
      fa^.lightmapchain := gl_lms.lightmap_surfaces[0];
      gl_lms.lightmap_surfaces[0] := fa;
    end;
  end
  else
  begin
    fa^.lightmapchain := gl_lms.lightmap_surfaces[fa^.lightmaptexturenum];
    gl_lms.lightmap_surfaces[fa^.lightmaptexturenum] := fa;
  end;
end; //procedure

{*
================
R_DrawAlphaSurfaces

Draw water surfaces and windows.
The BSP tree is waled front to back, so unwinding the chain
of alpha_surfaces will draw back to front, giving proper ordering.
================
*}
procedure R_DrawAlphaSurfaces; //for gl_rmain
var
  s: msurface_p;
  intens: Single;
begin
  //
  // go back to the world matrix
  //
  qglLoadMatrixf(@r_world_matrix);

  qglEnable(GL_BLEND);
  GL_TexEnv(GL_MODULATE);

  // the textures are prescaled up for a better lighting range,
  // so scale it back down
  intens := gl_state.inverse_intensity;

  s := r_alpha_surfaces;
  while (s <> nil) do
  begin
    GL_Bind(s.texinfo.image.texnum);
    Inc(c_brush_polys);
    if (s^.texinfo.flags and SURF_TRANS33) <> 0 then
      qglColor4f(intens, intens, intens, 0.33)
    else
      if (s^.texinfo.flags and SURF_TRANS66) <> 0 then
        qglColor4f(intens, intens, intens, 0.66)
      else
        qglColor4f(intens, intens, intens, 1);
    if (s^.flags and SURF_DRAWTURB) <> 0 then
      EmitWaterPolys(s)
    else
      if (s^.texinfo^.flags and SURF_FLOWING) <> 0 then
        DrawGLFlowingPoly(s)
      else
        DrawGLPoly(s.polys);

    s := s.texturechain;
  end;

  GL_TexEnv(GL_REPLACE);
  qglColor4f(1, 1, 1, 1);
  qglDisable(GL_BLEND);

  r_alpha_surfaces := nil;
end;

{*
================
DrawTextureChains
================
*}

procedure DrawTextureChains;
var
  i: integer;
  s: msurface_p;
  image: image_p;
label
  continue1_,
    continue2_,
    continue3_;
begin
  c_visible_textures := 0;

//idsoft   GL_TexEnv( GL_REPLACE );

  if (not Assigned(qglSelectTextureSGIS)) and (not Assigned(qglActiveTextureARB)) then
  begin
    i := 0;
    image := @gltextures;
    while (i < numgltextures) do
    begin
      if (image.registration_sequence = 0) then
        goto continue1_;
      s := image.texturechain;
      if (s = nil) then
        goto continue1_;
      Inc(c_visible_textures);

      while (s <> nil) do
      begin
        R_RenderBrushPoly(s);
        s := s^.texturechain;
      end;

      image.texturechain := nil;
      continue1_:
      Inc(i);
      Inc(image);
    end;
  end
  else
  begin
    i := 0;
    image := @gltextures;
    while (i < numgltextures) do
    begin
      if (image.registration_sequence = 0) then
        goto continue2_;
      if (image.texturechain = nil) then
        goto continue2_;
      Inc(c_visible_textures);

      s := image^.texturechain;
      while (s <> nil) do
      begin
        if ((s.flags and SURF_DRAWTURB) = 0) then
          R_RenderBrushPoly(s);
        s := s^.texturechain;
      end;
      continue2_:
      Inc(i);
      Inc(image);
    end;

    GL_EnableMultitexture(false);
    i := 0;
    image := @gltextures;
    while (i < numgltextures) do
    begin
      if (image.registration_sequence = 0) then
        goto continue3_;
      s := image.texturechain;
      if (s = nil) then
        goto continue3_;

      while (s <> nil) do
      begin
        if (s.flags and SURF_DRAWTURB) <> 0 then
          R_RenderBrushPoly(s);
        s := s^.texturechain;
      end;

      image.texturechain := nil;
      continue3_:
      Inc(i);
      Inc(image);
    end;
//idsoft   GL_EnableMultitexture( true );
  end;

  GL_TexEnv(GL_REPLACE);
end; //procedure

procedure GL_RenderLightmappedPoly(surf: msurface_p);
var
  i, map: integer;
  v: PSingle;
  p: glpoly_p;
  temp: array[0..128 * 128 - 1] of Cardinal;
  is_dynamic: qboolean;
  smax, tmax: integer;
  scroll: Single;
  nv: integer;
  image: image_p;
  lmtex: Cardinal;
label
  dynamic_;
begin
  is_dynamic := false;

  nv := surf^.polys^.numverts;
  image := R_TextureAnimation(surf^.texinfo);
  lmtex := surf^.lightmaptexturenum;

  map := 0;
  while (map < MAXLIGHTMAPS) and (surf^.styles[map] <> 255) do
  begin
    if (r_newrefdef.lightstyles[surf^.styles[map]].white <> surf.cached_light[map]) then
      goto dynamic_;
    Inc(map);
  end;

  // dynamic this frame or dynamic previously
  if (surf^.dlightframe = r_framecount) then
  begin
    dynamic_:
    if (gl_dynamic.value <> 0) then
    begin
      if (surf^.texinfo^.flags and (SURF_SKY or SURF_TRANS33 or SURF_TRANS66 or SURF_WARP) = 0) then
        is_dynamic := true;
    end;
  end;

  if (is_dynamic) then
  begin
    if (((surf^.styles[map] >= 32) or (surf^.styles[map] = 0)) and
      (surf^.dlightframe <> r_framecount)) then
    begin
      smax := (surf^.extents[0] shr 4) + 1;
      tmax := (surf^.extents[1] shr 4) + 1;

      R_BuildLightMap(surf, @temp, smax * 4);
      R_SetCacheState(surf);

      GL_MBind(GL_TEXTURE1, gl_state.lightmap_textures + surf^.lightmaptexturenum);

      lmtex := surf^.lightmaptexturenum;

      qglTexSubImage2D(GL_TEXTURE_2D, 0,
        surf^.light_s, surf^.light_t,
        smax, tmax,
        GL_LIGHTMAP_FORMAT,
        GL_UNSIGNED_BYTE, @temp);
    end
    else
    begin
      smax := (surf^.extents[0] shr 4) + 1;
      tmax := (surf^.extents[1] shr 4) + 1;

      R_BuildLightMap(surf, @temp, smax * 4);

      GL_MBind(GL_TEXTURE1, gl_state.lightmap_textures + 0);

      lmtex := 0;

      qglTexSubImage2D(GL_TEXTURE_2D, 0,
        surf^.light_s, surf^.light_t,
        smax, tmax,
        GL_LIGHTMAP_FORMAT,
        GL_UNSIGNED_BYTE, @temp);
    end;

    Inc(c_brush_polys);

    GL_MBind(GL_TEXTURE0, image^.texnum);
    GL_MBind(GL_TEXTURE1, gl_state.lightmap_textures + lmtex);

//==========
//PGM
    if (surf^.texinfo^.flags and SURF_FLOWING) <> 0 then
    begin
      scroll := -64 * ((r_newrefdef.time / 40.0) - Trunc(r_newrefdef.time / 40.0));
      if (scroll = 0.0) then
        scroll := -64.0;

      p := surf^.polys;
      while p <> nil do
      begin
        v := @p.verts[0];
        qglBegin(GL_POLYGON);
        for i := 0 to nv - 1 do
        begin
          qglMTexCoord2fSGIS(GL_TEXTURE0, (PSingleArray(v)^[3] + scroll), PSingleArray(v)^[4]);
          qglMTexCoord2fSGIS(GL_TEXTURE1, PSingleArray(v)^[5], PSingleArray(v)^[6]);
          qglVertex3fv(PGLFloat(v));
          Inc(v, VERTEXSIZE);
        end;
        qglEnd();
        p := p.chain;
      end;
    end
    else
    begin
      p := surf^.polys;
      while p <> nil do
      begin
        v := @p^.verts[0];
        qglBegin(GL_POLYGON);
        for i := 0 to nv - 1 do
        begin
          qglMTexCoord2fSGIS(GL_TEXTURE0, PSingleArray(v)^[3], PSingleArray(v)^[4]);
          qglMTexCoord2fSGIS(GL_TEXTURE1, PSingleArray(v)^[5], PSingleArray(v)^[6]);
          qglVertex3fv(PGLFloat(v));
          Inc(v, VERTEXSIZE);
        end;
        qglEnd();

        p := p^.chain;
      end;
    end;
//PGM
//==========
  end //then
  else
  begin
    Inc(c_brush_polys);

    GL_MBind(GL_TEXTURE0, image^.texnum);
    GL_MBind(GL_TEXTURE1, gl_state.lightmap_textures + lmtex);

//==========
//PGM
    if (surf^.texinfo^.flags and SURF_FLOWING) <> 0 then
    begin
      scroll := -64 * ((r_newrefdef.time / 40.0) - Trunc(r_newrefdef.time / 40.0));
      if (scroll = 0.0) then
        scroll := -64.0;

      p := surf^.polys;
      while p <> nil do
      begin
        v := @p^.verts[0];
        qglBegin(GL_POLYGON);
        for i := 0 to nv - 1 do
        begin
          qglMTexCoord2fSGIS(GL_TEXTURE0, (PSingleArray(v)^[3] + scroll), PSingleArray(v)^[4]);
          qglMTexCoord2fSGIS(GL_TEXTURE1, PSingleArray(v)^[5], PSingleArray(v)^[6]);
          qglVertex3fv(PGLFloat(v));
          Inc(v, VERTEXSIZE);
        end;
        qglEnd();

        p := p^.chain;
      end;
    end
    else
    begin
//PGM
//==========
      p := surf^.polys;
      while p <> nil do
      begin
        v := @p^.verts[0];
        qglBegin(GL_POLYGON);
        for i := 0 to nv - 1 do
        begin
          qglMTexCoord2fSGIS(GL_TEXTURE0, PSingleArray(v)^[3], PSingleArray(v)^[4]);
          qglMTexCoord2fSGIS(GL_TEXTURE1, PSingleArray(v)^[5], PSingleArray(v)^[6]);
          qglVertex3fv(PGLFloat(v));
          Inc(v, VERTEXSIZE);
        end;
        qglEnd();

        p := p^.chain;
      end;
//==========
//PGM
    end;
//PGM
//==========
  end;
end; //procedure

{*
=================
R_DrawInlineBModel
=================
*}
procedure R_DrawInlineBModel;
var
  i, k: integer;
  pplane: cplane_p;
  dot: Single;
  psurf: msurface_p;
  lt: dlight_p;
begin
  // calculate dynamic lighting for bmodel
  if (gl_flashblend^.value = 0) then
  begin
    lt := r_newrefdef.dlights;
    k := 0;
    while (k < r_newrefdef.num_dlights) do
    begin
      R_MarkLights(lt, 1 shl k, Pointer(Cardinal(currentmodel^.nodes) + (currentmodel^.firstnode * sizeof(mnode_t))));
      Inc(k);
      Inc(lt);
    end;
  end;

  psurf := @currentmodel^.surfaces[currentmodel^.firstmodelsurface];

  if (currententity.flags and RF_TRANSLUCENT) <> 0 then
  begin
    qglEnable(GL_BLEND);
    qglColor4f(1, 1, 1, 0.25);
    GL_TexEnv(GL_MODULATE);
  end;

  //
  // draw texture
  //
  for i := 0 to currentmodel^.nummodelsurfaces - 1 do
  begin
  // find which side of the node we are on
    pplane := psurf^.plane;

    dot := DotProduct(modelorg, pplane^.normal) - pplane^.dist;

// draw the polygon
    if ((((psurf^.flags and SURF_PLANEBACK) <> 0) and (dot < -BACKFACE_EPSILON)) or
      (((psurf^.flags and SURF_PLANEBACK) = 0) and (dot > BACKFACE_EPSILON))) then
    begin
      if (psurf^.texinfo^.flags and (SURF_TRANS33 or SURF_TRANS66) <> 0) then
      begin
        // add to the translucent chain
        psurf^.texturechain := r_alpha_surfaces;
        r_alpha_surfaces := psurf;
      end
      else
        if (Assigned(qglMTexCoord2fSGIS) and ((psurf.flags and SURF_DRAWTURB) = 0)) then
          GL_RenderLightmappedPoly(psurf)
        else
        begin
          GL_EnableMultitexture(false);
          R_RenderBrushPoly(psurf);
          GL_EnableMultitexture(true);
        end;
    end; //if
    inc(psurf);
  end;

  if ((currententity.flags and RF_TRANSLUCENT) = 0) then
  begin
    if not Assigned(qglMTexCoord2fSGIS) then
      R_BlendLightmaps();
  end
  else
  begin
    qglDisable(GL_BLEND);
    qglColor4f(1, 1, 1, 1);
    GL_TexEnv(GL_REPLACE);
  end;
end; //procedure

{*
=================
R_DrawBrushModel
=================
*}
procedure R_DrawBrushModel(e: entity_p); //for gl_rmain
var
  i: integer;
  rotated: qboolean;
  mins, maxs,
    temp,
    forward_,
    right, up: vec3_t;
begin
  if (currentmodel^.nummodelsurfaces = 0) then
    Exit;

  currententity := e;
  gl_state.currenttextures[0] := -1;
  gl_state.currenttextures[1] := -1;

  if (e^.angles[0] <> 0) or (e^.angles[1] <> 0) or (e^.angles[2] <> 0) then
  begin
    rotated := true;
    for i := 0 to 2 do
    begin
      mins[i] := e^.origin[i] - currentmodel^.radius;
      maxs[i] := e^.origin[i] + currentmodel^.radius;
    end;
  end
  else
  begin
    rotated := false;
    VectorAdd(vec3_t(e^.origin), currentmodel^.mins, mins);
    VectorAdd(vec3_t(e^.origin), currentmodel^.maxs, maxs);
  end;

  if (R_CullBox(mins, maxs)) then
    Exit;

  qglColor3f(1, 1, 1);
  FillChar(gl_lms.lightmap_surfaces, sizeof(gl_lms.lightmap_surfaces), 0);

  VectorSubtract(vec3_t(r_newrefdef.vieworg), vec3_t(e^.origin), modelorg);
  if (rotated) then
  begin
    VectorCopy(modelorg, temp);
    AngleVectors(vec3_t(e^.angles), @forward_, @right, @up);
    modelorg[0] := DotProduct(temp, forward_);
    modelorg[1] := -DotProduct(temp, right);
    modelorg[2] := DotProduct(temp, up);
  end;

  qglPushMatrix();
  e^.angles[0] := -e^.angles[0]; // stupid quake bug
  e^.angles[2] := -e^.angles[2]; // stupid quake bug
  R_RotateForEntity(e);
  e^.angles[0] := -e^.angles[0]; // stupid quake bug
  e^.angles[2] := -e^.angles[2]; // stupid quake bug

  GL_EnableMultitexture(true);
  GL_SelectTexture(GL_TEXTURE0);
  GL_TexEnv(GL_REPLACE);
  GL_SelectTexture(GL_TEXTURE1);
  GL_TexEnv(GL_MODULATE);

  R_DrawInlineBModel();
  GL_EnableMultitexture(false);
  qglPopMatrix();
end;

{*
=============================================================

 WORLD MODEL

=============================================================
*}

{*
================
R_RecursiveWorldNode
================
*}
procedure R_RecursiveWorldNode(node: mnode_p);
var
  c, side, sidebit: integer;
  plane: cplane_p;

  surf: msurface_p;
  mark: msurface_pp;

  pleaf: mleaf_p;
  dot: Single;
  image: image_p;
  notside_: Integer;
label
  Continue_;
begin
  if (node^.contents = CONTENTS_SOLID) then
    Exit; // solid

  if (node^.visframe <> r_visframecount) then
    Exit;
  if (R_CullBox(vec3_p(@node^.minmaxs)^, vec3_p(@node^.minmaxs[3])^)) then
    Exit;

// if a leaf node, draw stuff
  if (node.contents <> -1) then
  begin
    pleaf := mleaf_p(node);

    // check for door connected areas
    if (r_newrefdef.areabits <> nil) then
    begin
      if ((PByteArray(r_newrefdef.areabits)[pleaf^.area shr 3] and (1 shl (pleaf^.area and 7))) = 0) then
        Exit; // not visible
    end;
    mark := pleaf^.firstmarksurface;
    c := pleaf^.nummarksurfaces;

    if (c <> 0) then
    begin
      repeat
        mark^^.visFrame := r_framecount;
        Inc(mark);
        Dec(c);
      until (c = 0);
    end;
    Exit;
  end; //if

// node is just a decision point, so go down the apropriate sides

// find which side of the node we are on
  plane := node^.plane;

  case plane^._type of
    PLANE_X: dot := modelorg[0] - plane.dist;
    PLANE_Y: dot := modelorg[1] - plane.dist;
    PLANE_Z: dot := modelorg[2] - plane.dist;
  else
    dot := DotProduct(modelorg, plane^.normal) - plane^.dist;
  end;

  if (dot >= 0) then
  begin
    side := 0;
    sidebit := 0;
  end
  else
  begin
    side := 1;
    sidebit := SURF_PLANEBACK;
  end;

// recurse down the children, front side first
  R_RecursiveWorldNode(node^.children[side]);

  // draw stuff
  c := node^.numsurfaces;
  surf := @r_worldmodel^.surfaces^[node^.firstsurface];
  while (c <> 0) do
  begin
    if (surf.visframe <> r_framecount) then
      goto Continue_;

    if ((surf^.flags and SURF_PLANEBACK) <> sidebit) then
      goto Continue_; // wrong side

    if (surf^.texinfo^.flags and SURF_SKY) <> 0 then
    begin
      // just adds to visible sky bounds
      R_AddSkySurface(surf);
    end
    else
      if (surf^.texinfo^.flags and (SURF_TRANS33 or SURF_TRANS66) <> 0) then
      begin
        // add to the translucent chain
        surf^.texturechain := r_alpha_surfaces;
        r_alpha_surfaces := surf;
      end
      else
      begin
        if (Assigned(qglMTexCoord2fSGIS) and ((surf^.flags and SURF_DRAWTURB) = 0)) then
          GL_RenderLightmappedPoly(surf)
        else
        begin
          // the polygon is visible, so add it to the texture
          // sorted chain
          // FIXME: this is a hack for animation
          image := R_TextureAnimation(surf^.texinfo);
          surf^.texturechain := image^.texturechain;
          image^.texturechain := surf;
        end;
      end;
    Continue_:
    Dec(c);
    Inc(surf);
  end;

  // recurse down the back side

  if side = 0 then
    notside_ := 1
  else
    notside_ := 0;
  R_RecursiveWorldNode(node.children[notside_]);
(*Id Software /*
 for ( ; c ; c--, surf++)
 {
  if (surf->visframe != r_framecount)
   continue;

  if ( (surf->flags & SURF_PLANEBACK) != sidebit )
   continue;      // wrong side

  if (surf->texinfo->flags & SURF_SKY)
  {   // just adds to visible sky bounds
   R_AddSkySurface (surf);
  }
  else if (surf->texinfo->flags & (SURF_TRANS33|SURF_TRANS66))
  {   // add to the translucent chain
//         surf->texturechain = alpha_surfaces;
//         alpha_surfaces = surf;
  }
  else
  {
   if ( qglMTexCoord2fSGIS && !( surf->flags & SURF_DRAWTURB ) )
   {
    GL_RenderLightmappedPoly( surf );
   }
   else
   {
    // the polygon is visible, so add it to the texture
    // sorted chain
    // FIXME: this is a hack for animation
    image = R_TextureAnimation (surf->texinfo);
    surf->texturechain = image->texturechain;
    image->texturechain = surf;
   }
  }
 }
*/*)
end; //procedure

{*
=============
R_DrawWorld
=============
*}
procedure R_DrawWorld; //for gl_rmain
var
  ent: entity_t;
begin
  if (r_drawworld_.value = 0) then
    Exit;

  if (r_newrefdef.rdflags and RDF_NOWORLDMODEL) <> 0 then
    Exit;

  currentmodel := r_worldmodel;

  VectorCopy(vec3_t(r_newrefdef.vieworg), modelorg);

  // auto cycle the world frame for texture animation
  memset(@ent, 0, sizeof(ent));
  ent.frame := Trunc(r_newrefdef.time * 2);
  currententity := @ent;

  gl_state.currenttextures[0] := -1;
  gl_state.currenttextures[1] := -1;

  qglColor3f(1, 1, 1);
  memset(@gl_lms.lightmap_surfaces, 0, sizeof(gl_lms.lightmap_surfaces));
  R_ClearSkyBox();

  if Assigned(qglMTexCoord2fSGIS) then
  begin
    GL_EnableMultitexture(true);

    GL_SelectTexture(GL_TEXTURE0);
    GL_TexEnv(GL_REPLACE);
    GL_SelectTexture(GL_TEXTURE1);

    if (gl_lightmap.value <> 0) then
      GL_TexEnv(GL_REPLACE)
    else
      GL_TexEnv(GL_MODULATE);

    R_RecursiveWorldNode(r_worldmodel^.nodes);

    GL_EnableMultitexture(false);
  end
  else
    R_RecursiveWorldNode(r_worldmodel^.nodes);

  {*
  ** theoretically nothing should happen in the next two functions
  ** if multitexture is enabled
  *}
  DrawTextureChains();
  R_BlendLightmaps();

  R_DrawSkyBox();

  R_DrawTriangleOutlines();
end; //procedure

{*
===============
R_MarkLeaves

Mark the leaves and nodes that are in the PVS for the current
cluster
===============
*}
procedure R_MarkLeaves; //for gl_rmain
var
  vis: PByte;
  fatvis: array[0..MAX_MAP_LEAFS div 8 - 1] of byte;

  node: mnode_p;
  i, c,
    cluster: integer;
  leaf: mleaf_p;
label
  continue_;
begin
  if (r_oldviewcluster = r_viewcluster) and (r_oldviewcluster2 = r_viewcluster2) and
    (r_novis.value = 0) and (r_viewcluster <> -1) then
    Exit;

  // development aid to let you run around and see exactly where
  // the pvs ends
  if (gl_lockpvs^.value <> 0) then
    Exit;

  Inc(r_visframecount);
  r_oldviewcluster := r_viewcluster;
  r_oldviewcluster2 := r_viewcluster2;

  if (r_novis^.value <> 0) or (r_viewcluster = -1) or (r_worldmodel.vis = nil) then
  begin
    // mark everything
    for i := 0 to r_worldmodel.numleafs - 1 do
      mLeaf_arrp(r_worldmodel.leafs)[i].visframe := r_visframecount;
    for i := 0 to r_worldmodel.numnodes - 1 do
      mNode_arrp(r_worldmodel.nodes)[i].visframe := r_visframecount;
    Exit;
  end;

  vis := Mod_ClusterPVS(r_viewcluster, r_worldmodel);
  // may have to combine two clusters because of solid water boundaries
  if (r_viewcluster2 <> r_viewcluster) then
  begin
    memcpy(@fatvis, vis, (r_worldmodel.numleafs + 7) div 8);
    vis := Mod_ClusterPVS(r_viewcluster2, r_worldmodel);
    c := (r_worldmodel.numleafs + 31) div 32;
    for i := 0 to c - 1 do
      PIntegerArray(@fatvis)^[i] := PIntegerArray(@fatvis)^[i] or PIntegerArray(vis)^[i];
    vis := @fatvis;
  end;

  leaf := r_worldmodel^.leafs;
  for i := 0 to r_worldmodel^.numleafs - 1 do
  begin
    cluster := leaf^.cluster;
    if (cluster = -1) then
      goto continue_;
    if (PByteArray(vis)^[cluster shr 3] and (1 shl (cluster and 7))) <> 0 then
    begin
      node := mnode_p(leaf);
      repeat
        if (node.visframe = r_visframecount) then
          Break;
        node.visframe := r_visframecount;
        node := node.parent;
      until node = nil;
    end;
    continue_:
    Inc(leaf);
  end;

(*
 for (i=0 ; i<r_worldmodel->vis->numclusters ; i++)
 {
  if (vis[i>>3] & (1<<(i&7)))
  {
   node = (mnode_t * )&r_worldmodel->leafs[i];   // FIXME: cluster
   do
   {
    if (node->visframe == r_visframecount)
     break;
    node->visframe = r_visframecount;
    node = node->parent;
   } while (node);
  }
 }
*)
end; //procedure



{*
=============================================================================

  LIGHTMAP ALLOCATION

=============================================================================
*}

procedure {static}  LM_InitBlock;
begin
  FillChar(gl_lms.allocated, sizeof(gl_lms.allocated), 0);
end; //procedure

procedure {static}  LM_UploadBlock(dynamic_: qboolean);
var
  texture, i,
    height: integer;
begin
  height := 0;

  if dynamic_ then
    texture := 0
  else
    texture := gl_lms.current_lightmap_texture;

  GL_Bind(gl_state.lightmap_textures + texture);
  qglTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  qglTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

  if dynamic_ then
  begin
    for i := 0 to BLOCK_WIDTH - 1 do
      if (gl_lms.allocated[i] > height) then
        height := gl_lms.allocated[i];

    qglTexSubImage2D(GL_TEXTURE_2D,
      0,
      0, 0,
      BLOCK_WIDTH, height,
      GL_LIGHTMAP_FORMAT,
      GL_UNSIGNED_BYTE,
      @gl_lms.lightmap_buffer);
  end
  else
  begin
    qglTexImage2D(GL_TEXTURE_2D,
      0,
      gl_lms.internal_format,
      BLOCK_WIDTH, BLOCK_HEIGHT,
      0,
      GL_LIGHTMAP_FORMAT,
      GL_UNSIGNED_BYTE,
      @gl_lms.lightmap_buffer);
    Inc(gl_lms.current_lightmap_texture);
    if (gl_lms.current_lightmap_texture = MAX_LIGHTMAPS) then
      ri.Sys_Error(ERR_DROP, 'LM_UploadBlock() - MAX_LIGHTMAPS exceeded'#10, []);
  end;
end; //procedure


// returns a texture number and the position inside it
function {static}  LM_AllocBlock(w, h: integer; var x, y: integer): qboolean;
var
  i, j,
    best, best2: integer;
begin
  best := BLOCK_HEIGHT;

  for i := 0 to BLOCK_WIDTH - w - 1 do
  begin
    best2 := 0;

    j := 0;
    while (j < w) do
    begin
      if (gl_lms.allocated[i + j] >= best) then
        Break;
      if (gl_lms.allocated[i + j] > best2) then
        best2 := gl_lms.allocated[i + j];
      inc(j);
    end;
    if (j = w) then
    begin
      // this is a valid spot
      x := i;
      best := best2;
      y := best;
    end;
  end; //for

  if (best + h > BLOCK_HEIGHT) then
  begin
    Result := false;
    Exit;
  end;

  for i := 0 to w - 1 do
    gl_lms.allocated[{*} x + i] := best + h;

  Result := true;
end; //function

{*
================
GL_BuildPolygonFromSurface
================
*}
procedure GL_BuildPolygonFromSurface(fa: msurface_p);
var
  i, lindex,
  lnumverts,
  vertpage: integer;
  pedges,
  r_pedge: medge_p;
  vec: vec3_t;

  s, t: Single;
  poly: glpoly_p;
  total: vec3_t;
begin
  // reconstruct the polygon
  pedges := medge_p(currentmodel^.edges);
  lnumverts := fa^.numedges;
  vertpage := 0;

  VectorClear(total);
  //
  // draw texture
  //
  poly := Hunk_Alloc(sizeof(glpoly_t) + (lnumverts - 4) * VERTEXSIZE * sizeof(Single));
  poly^.next := fa^.polys;
  poly^.flags := fa^.flags;
  fa^.polys := poly;
  poly^.numverts := lnumverts;

  for i := 0 to lnumverts - 1 do
  begin
    lindex := PIntegerArray(currentmodel^.surfedges)^[fa^.firstedge + i];

    if (lindex > 0) then
    begin
      r_pedge := @mEdge_arrp(pedges)^[lindex];
      vec := currentmodel^.vertexes[r_pedge^.v[0]].position;
    end
    else
    begin
      r_pedge := @mEdge_arrp(pedges)^[-lindex];
      vec := currentmodel^.vertexes[r_pedge^.v[1]].position;
    end;
    s := DotProduct(vec, vec3_p(@fa^.texinfo^.vecs[0])^) + fa^.texinfo^.vecs[0][3];
    s := s / fa^.texinfo^.image^.width;

    t := DotProduct(vec, vec3_p(@fa^.texinfo^.vecs[1])^) + fa^.texinfo^.vecs[1][3];
    t := t / fa^.texinfo^.image^.height;

    VectorAdd(total, vec, total);
    VectorCopy(vec, vec3_t(vec3_p(@poly^.verts[i])^));
    poly.verts[i][3] := s;
    poly.verts[i][4] := t;

    //
    // lightmap texture coordinates
    //
    s := DotProduct(vec, vec3_p(@fa^.texinfo^.vecs[0])^) + fa^.texinfo^.vecs[0][3];
    s := s - fa^.texturemins[0];
    s := s + fa^.light_s * 16;
    s := s + 8;
    s := s / (BLOCK_WIDTH * 16); //fa->texinfo->texture->width;

    t := DotProduct(vec, vec3_p(@fa^.texinfo^.vecs[1])^) + fa^.texinfo^.vecs[1][3];
    t := t - fa^.texturemins[1];
    t := t + fa^.light_t * 16;
    t := t + 8;
    t := t / (BLOCK_HEIGHT * 16); //fa->texinfo->texture->height;

    poly^.verts[i][5] := s;
    poly^.verts[i][6] := t;
  end; //for

  poly^.numverts := lnumverts;
end; //procedure

{*
========================
GL_CreateSurfaceLightmap
========================
*}
procedure GL_CreateSurfaceLightmap(surf: msurface_p);
var
  smax, tmax: integer;
  base: PByte;
begin
  if (surf.flags and (SURF_DRAWSKY or SURF_DRAWTURB) <> 0) then
    Exit;

  smax := (surf.extents[0] shr 4) + 1;
  tmax := (surf.extents[1] shr 4) + 1;

  if (not LM_AllocBlock(smax, tmax, surf^.light_s, surf^.light_t)) then
  begin
    LM_UploadBlock(false);
    LM_InitBlock();
    if (not LM_AllocBlock(smax, tmax, surf^.light_s, surf^.light_t)) then
      ri.Sys_Error(ERR_FATAL, 'Consecutive calls to LM_AllocBlock(%d,%d) failed'#10, [smax, tmax]);
  end;

  surf^.lightmaptexturenum := gl_lms.current_lightmap_texture;

  base := @gl_lms.lightmap_buffer;
  Inc(base, (surf^.light_t * BLOCK_WIDTH + surf^.light_s) * LIGHTMAP_BYTES);

  R_SetCacheState(surf);
  R_BuildLightMap(surf, PByteArray(base), BLOCK_WIDTH * LIGHTMAP_BYTES);
end; //procedure

{*
==================
GL_BeginBuildingLightmaps
==================
*}
var
  lightstyles: array[0..MAX_LIGHTSTYLES - 1] of lightstyle_t;

procedure GL_BeginBuildingLightmaps(m: model_p); //for gl_model
//   static lightstyle_t   lightstyles[MAX_LIGHTSTYLES];
var
  i: integer;
  dummy: array[0..128 * 128 - 1] of Cardinal;
begin
  memset(@gl_lms.allocated, 0, sizeof(gl_lms.allocated));

  r_framecount := 1; // no dlightcache

  GL_EnableMultitexture(true);
  GL_SelectTexture(GL_TEXTURE1);

  {*
  ** setup the base lightstyles so the lightmaps won't have to be regenerated
  ** the first time they're seen
  *}
  for i := 0 to MAX_LIGHTSTYLES - 1 do
  begin
    lightstyles[i].rgb[0] := 1;
    lightstyles[i].rgb[1] := 1;
    lightstyles[i].rgb[2] := 1;
    lightstyles[i].white := 3;
  end;
  r_newrefdef.lightstyles := @lightstyles;

  if (gl_state.lightmap_textures = 0) then
  begin
    gl_state.lightmap_textures := TEXNUM_LIGHTMAPS;
//idsoft      gl_state.lightmap_textures   = gl_state.texture_extension_number;
//idsoft      gl_state.texture_extension_number = gl_state.lightmap_textures + MAX_LIGHTMAPS;
  end;

  gl_lms.current_lightmap_texture := 1;

  {*
  ** if mono lightmaps are enabled and we want to use alpha
  ** blending (a,1-a) then we're likely running on a 3DLabs
  ** Permedia2.  In a perfect world we'd use a GL_ALPHA lightmap
  ** in order to conserve space and maximize bandwidth, however
  ** this isn't a perfect world.
  **
  ** So we have to use alpha lightmaps, but stored in GL_RGBA format,
  ** which means we only get 1/16th the color resolution we should when
  ** using alpha lightmaps.  If we find another board that supports
  ** only alpha lightmaps but that can at least support the GL_ALPHA
  ** format then we should change this code to use real alpha maps.
  *}
//  if ( toupper( gl_monolightmap.string[0] ) == 'A' )
  if UpCase(gl_monolightmap.string_[0]) = 'A' then
  begin
    gl_lms.internal_format := gl_tex_alpha_format;
  end
  {*
  ** try to do hacked colored lighting with a blended texture
  *}
  else
    if UpCase(gl_monolightmap.string_[0]) = 'C' then
      gl_lms.internal_format := gl_tex_alpha_format
    else
      if UpCase(gl_monolightmap.string_[0]) = 'I' then
        gl_lms.internal_format := GL_INTENSITY8
      else
        if UpCase(gl_monolightmap.string_[0]) = 'L' then
          gl_lms.internal_format := GL_LUMINANCE8
        else
          gl_lms.internal_format := gl_tex_solid_format;

  {*
  ** initialize the dynamic lightmap texture
  *}
  GL_Bind(gl_state.lightmap_textures + 0);
  qglTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  qglTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  qglTexImage2D(GL_TEXTURE_2D,
    0,
    gl_lms.internal_format,
    BLOCK_WIDTH, BLOCK_HEIGHT,
    0,
    GL_LIGHTMAP_FORMAT,
    GL_UNSIGNED_BYTE,
    @dummy);
end; //procedure

{*
=======================
GL_EndBuildingLightmaps
=======================
*}
procedure GL_EndBuildingLightmaps; //for gl_model
begin
  LM_UploadBlock(false);
  GL_EnableMultitexture(false);
end; //procedure

// End of file
end.

