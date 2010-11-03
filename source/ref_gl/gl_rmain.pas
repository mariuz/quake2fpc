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
{ File(s): gl_rmain.c                                                        }
{                                                                            }
{ Initial conversion by : YgriK (Igor Karpov) - glYgriK@hotbox.ru            }
{ Initial conversion on : 17-Jan-2002                                        }
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
// (r_main.c) gl_rmain.c
{ 28.06.2003 Juha: Proofreaded }
{$I ..\Jedi.inc}
unit gl_rmain;

interface

uses
  SysUtils,
  DelphiTypes,
  OpenGL,
  gl_model_h,
  gl_local,
  q_shared,
  q_shared_add,
  ref;

function R_CullBox(var mins, maxs: vec3_t): qboolean;
procedure R_RotateForEntity(e: entity_p);

function GetRefAPI(rimp: refimport_t): refexport_t; cdecl;

procedure Sys_Error(fmt: PChar; args: array of const); overload;
procedure Com_Printf(fmt: PChar; args: array of const); overload;
procedure Com_Printf(fmt: PChar); overload;

procedure MYgluPerspective(fovy, aspect, zNear, zFar: TGLdouble);


var
  vid: viddef_t;
  ri: refimport_t;
  GL_TEXTURE0,
    GL_TEXTURE1: Integer;
  r_worldmodel: model_p;

  gldepthmin, gldepthmax: Single;

  gl_config: glconfig_t;
  gl_state: glstate_t;

  r_notexture: image_p; // use for bad textures
  r_particletexture: image_p; // little dot for particles

  currententity: entity_p;
  currentmodel: model_p;

  frustum: array[0..3] of cplane_t;

  r_visframecount: Integer; // bumped when going to a new PVS
  r_framecount: Integer; // used for dlight push checking

  c_brush_polys,
    c_alias_polys: Integer;

  v_blend: array[0..3] of single; // final blending color

//
// view origin
//
  vup: vec3_t;
  vpn: vec3_t;
  vright: vec3_t;
  r_origin: vec3_t;

  r_world_matrix: array[0..16 - 1] of Single;
  r_base_world_matrix: array[0..16 - 1] of Single;

//
// screen size info
//
  r_newrefdef: refdef_t;

  r_viewcluster,
    r_viewcluster2,
    r_oldviewcluster,
    r_oldviewcluster2: Integer;


  r_norefresh,
    r_drawentities,
    r_drawworld_,
    r_speeds,
    r_fullbright,
    r_novis,
    r_nocull,
    r_lerpmodels,
    r_lefthand,

  r_lightlevel, // FIXME: This is a HACK to get the client's light level

  gl_nosubimage,
    gl_allow_software,

  gl_vertex_arrays,

  gl_particle_min_size,
    gl_particle_max_size,
    gl_particle_size,
    gl_particle_att_a,
    gl_particle_att_b,
    gl_particle_att_c,

  gl_ext_swapinterval,
    gl_ext_palettedtexture,
    gl_ext_multitexture,
    gl_ext_pointparameters,
    gl_ext_compiled_vertex_array,

  gl_log,
    gl_bitdepth,
    gl_drawbuffer,
    gl_driver,
    gl_lightmap,
    gl_shadows,
    gl_mode,
    gl_dynamic,
    gl_monolightmap,
    gl_modulate_,
    gl_nobind,
    gl_round_down,
    gl_picmip,
    gl_skymip,
    gl_showtris,
    gl_ztrick,
    gl_finish,
    gl_clear_,
    gl_cull,
    gl_polyblend,
    gl_flashblend,
    gl_playermip,
    gl_saturatelighting,
    gl_swapinterval,
    gl_texturemode_,
    gl_texturealphamode_,
    gl_texturesolidmode_,
    gl_lockpvs,

  gl_3dlabs_broken,

  vid_fullscreen,
    vid_gamma,
    vid_ref: cvar_p;

  r_rawpalette: array[0..256 - 1] of Cardinal;


implementation

uses
  glw_win,
  glw_imp,
  qgl_h,
  qgl_win,
  gl_model,
  gl_image,
  gl_rmisc,
  gl_light,
  qfiles,
  gl_warp,
  gl_rsurf,
  gl_draw,
  gl_mesh,
  Math,
  CPas;

procedure R_DrawBeam(e: entity_p); forward;


{*
=================
R_CullBox

Returns true if the box is completely outside the frustom
=================
*}
function R_CullBox(var mins, maxs: vec3_t): qboolean;
var
  i: integer;
begin
  if (r_nocull.value <> 0) then
  begin
    Result := false;
    Exit;
  end;

  for i := 0 to 3 do
    if (BOX_ON_PLANE_SIDE(mins, maxs, @frustum[i]) = 2) then
    begin
      Result := true;
      Exit;
    end;

  Result := false;
end;

procedure R_RotateForEntity(e: entity_p);
begin
  qglTranslatef(e.origin[0], e.origin[1], e.origin[2]);

  qglRotatef(e.angles[1], 0, 0, 1);
  qglRotatef(-e.angles[0], 0, 1, 0);
  qglRotatef(-e.angles[2], 1, 0, 0);
end;

{*
=============================================================

  SPRITE MODELS

=============================================================
*}

{*
=================
R_DrawSpriteModel

=================
*}

procedure R_DrawSpriteModel(e: entity_p);
var
  point: vec3_t;
  frame: dsprframe_p;
  up, right: vec3_p;
  psprite: dsprite_p;
  alpha: Single;
  //v_forward, v_right, v_up: vec3_t;
begin
  alpha := 1;
  // don't even bother culling, because it's just a single
  // polygon without a surface cache

  psprite := dsprite_p(currentmodel.extradata);

(*
 if (e->frame < 0 || e->frame >= psprite->numframes)
 {
  ri.Con_Printf (PRINT_ALL, "no such sprite frame %i\n", e->frame);
  e->frame = 0;
 }
*)

  e.frame := e.frame mod psprite.numframes;
  frame := @psprite.frames[e.frame];

(*
 if (psprite->type == SPR_ORIENTED)
 {   // bullet marks on walls
 vec3_t      v_forward, v_right, v_up;

 AngleVectors (currententity->angles, v_forward, v_right, v_up);
  up = v_up;
  right = v_right;
 }
 else
*)
  begin // normal sprite
    up := @vup;
    right := @vright;
  end;

  if (e.flags and RF_TRANSLUCENT) <> 0 then
    alpha := e.alpha;

  if (alpha <> 1.0) then
    qglEnable(GL_BLEND);

  qglColor4f(1, 1, 1, alpha);

  GL_Bind(currentmodel.skins[e.frame].texnum);

  GL_TexEnv(GL_MODULATE);

  if (alpha = 1.0) then
    qglEnable(GL_ALPHA_TEST)
  else
    qglDisable(GL_ALPHA_TEST);

  qglBegin(GL_QUADS);
  qglTexCoord2f(0, 1);
  VectorMA(vec3_t(e.origin), -frame.origin_y, up^, point);
  VectorMA(point, -frame.origin_x, right^, point);
  qglVertex3fv(@point);

  qglTexCoord2f(0, 0);
  VectorMA(vec3_t(e.origin), frame.height - frame.origin_y, up^, point);
  VectorMA(point, -frame.origin_x, right^, point);
  qglVertex3fv(@point);

  qglTexCoord2f(1, 0);
  VectorMA(vec3_t(e.origin), frame.height - frame.origin_y, up^, point);
  VectorMA(point, frame.width - frame.origin_x, right^, point);
  qglVertex3fv(@point);

  qglTexCoord2f(1, 1);
  VectorMA(vec3_t(e.origin), -frame.origin_y, up^, point);
  VectorMA(point, frame.width - frame.origin_x, right^, point);
  qglVertex3fv(@point);
  qglEnd();

  qglDisable(GL_ALPHA_TEST);
  GL_TexEnv(GL_REPLACE);

  if (alpha <> 1.0) then
    qglDisable(GL_BLEND);

  qglColor4f(1, 1, 1, 1);
end;

//==================================================================================

{*
=============
R_DrawNullModel
=============
*}

procedure R_DrawNullModel;
var
  shadelight: vec3_t;
  i: integer;
begin
  if (currententity.flags and RF_FULLBRIGHT) <> 0 then
  begin
    shadelight[0] := 1.0;
    shadelight[1] := 1.0;
    shadelight[2] := 1.0;
  end
  else
    R_LightPoint(vec3_t(currententity.origin), shadelight);

  qglPushMatrix();
  R_RotateForEntity(currententity);

  qglDisable(GL_TEXTURE_2D);
  qglColor3fv(@shadelight);

  qglBegin(GL_TRIANGLE_FAN);
  qglVertex3f(0, 0, -16);
  for i := 0 to 4 do
    qglVertex3f(16 * cos(i * M_PI / 2), 16 * sin(i * M_PI / 2), 0);
  qglEnd();

  qglBegin(GL_TRIANGLE_FAN);
  qglVertex3f(0, 0, 16);
  for i := 4 downto 0 do
    qglVertex3f(16 * cos(i * M_PI / 2), 16 * sin(i * M_PI / 2), 0);
  qglEnd();

  qglColor3f(1, 1, 1);
  qglPopMatrix();
  qglEnable(GL_TEXTURE_2D);
end;

{*
=============
R_DrawEntitiesOnList
=============
*}

procedure R_DrawEntitiesOnList;
var
  i: integer;
begin
  if (r_drawentities.value = 0) then
    Exit;

  // draw non-transparent first
  for i := 0 to r_newrefdef.num_entities - 1 do
  begin
    currententity := @entity_arrp(r_newrefdef.entities)^[i];
    if (currententity.flags and RF_TRANSLUCENT) <> 0 then
      Continue; // solid

    // if ( currententity->flags & RF_BEAM )
    if (currententity.flags and RF_BEAM) <> 0 then
      R_DrawBeam(currententity)
    else
    begin
      currentmodel := currententity.model;
      if (currentmodel = nil) then
      begin
        R_DrawNullModel();
        Continue;
      end;
      case currentmodel._type of
        mod_alias: R_DrawAliasModel(currententity);
        mod_brush: R_DrawBrushModel(currententity);
        mod_sprite: R_DrawSpriteModel(currententity);
      else
        ri.Sys_Error(ERR_DROP, 'Bad modeltype', []);
      end;
    end;
  end;

  // draw transparent entities
  // we could sort these if it ever becomes a problem...
  qglDepthMask(False); // no z writes
  for i := 0 to r_newrefdef.num_entities - 1 do
  begin
    currententity := @entity_arrp(r_newrefdef.entities)[i];
    if ((currententity.flags and RF_TRANSLUCENT) = 0) then
      Continue; // solid

    // if ( currententity->flags & RF_BEAM )
    if (currententity.flags and RF_BEAM) <> 0 then
      R_DrawBeam(currententity)
    else
    begin
      currentmodel := currententity.model;
      if (currentmodel = nil) then
      begin
        R_DrawNullModel();
        Continue;
      end;
      case currentmodel._type of
        mod_alias: R_DrawAliasModel(currententity);
        mod_brush: R_DrawBrushModel(currententity);
        mod_sprite: R_DrawSpriteModel(currententity);
      else
        ri.Sys_Error(ERR_DROP, 'Bad modeltype', []);
      end;
    end;
  end;
  qglDepthMask(True); // back to writing
end;

{*
** GL_DrawParticles
**
*}
//procedure GL_DrawParticles( int num_particles, const particle_t particles[], const unsigned colortable[768] );

procedure GL_DrawParticles(num_particles: integer; particles: particle_p; colortable: PCardinalArray);
var
  p: particle_p;
  i: integer;
  up, right: vec3_t;
  scale: Single;
  color: array[0..3] of byte;
begin
  GL_Bind(r_particletexture.texnum);
  qglDepthMask(False); // no z buffering
  qglEnable(GL_BLEND);
  GL_TexEnv(GL_MODULATE);
  qglBegin(GL_TRIANGLES);
  VectorScale(vup, 1.5, up);
  VectorScale(vright, 1.5, right);

  p := particles;
  for i := 0 to num_particles - 1 do
  begin
    // hack a scale up to keep particles from disapearing
    scale := (p.origin[0] - r_origin[0]) * vpn[0] +
      (p.origin[1] - r_origin[1]) * vpn[1] +
      (p.origin[2] - r_origin[2]) * vpn[2];

    if (scale < 20) then
      scale := 1
    else
      scale := 1 + scale * 0.004;

    PInteger(@color)^ := colortable[p.color];
    color[3] := Trunc(p.alpha * 255);

    qglColor4ubv(@color);

    qglTexCoord2f(0.0625, 0.0625);
    qglVertex3fv(@p.origin);

    qglTexCoord2f(1.0625, 0.0625);
    qglVertex3f(p.origin[0] + up[0] * scale,
      p.origin[1] + up[1] * scale,
      p.origin[2] + up[2] * scale);

    qglTexCoord2f(0.0625, 1.0625);
    qglVertex3f(p.origin[0] + right[0] * scale,
      p.origin[1] + right[1] * scale,
      p.origin[2] + right[2] * scale);

    Inc(p);
  end;
  qglEnd();
  qglDisable(GL_BLEND);
  qglColor4f(1, 1, 1, 1);
  qglDepthMask(True); // back to normal Z buffering
  GL_TexEnv(GL_REPLACE);
end;

{*
===============
R_DrawParticles
===============
*}

procedure R_DrawParticles;
var
  i: integer;
  color: array[0..3] of byte;
  p: particle_p;
begin
  if (gl_ext_pointparameters.value <> 0) and Assigned(qglPointParameterfEXT) then
  begin
    qglDepthMask(False);
    qglEnable(GL_BLEND);
    qglDisable(GL_TEXTURE_2D);

    qglPointSize(gl_particle_size.value);

    qglBegin(GL_POINTS);
    p := r_newrefdef.particles;
    for i := 0 to r_newrefdef.num_particles - 1 do
    begin
//            *(int * )color = d_8to24table[p.color];
      move(d_8to24table[p.color], color, 4);
      color[3] := Trunc(p.alpha * 255);

      qglColor4ubv(@color);

      qglVertex3fv(@p.origin);

      Inc(p);
    end;
    qglEnd();

    qglDisable(GL_BLEND);
    qglColor4f(1.0, 1.0, 1.0, 1.0);
    qglDepthMask(True);
    qglEnable(GL_TEXTURE_2D);
  end
  else
    GL_DrawParticles(r_newrefdef.num_particles, r_newrefdef.particles, @d_8to24table);
end; //procedure

{*
============
R_PolyBlend
============
*}

procedure R_PolyBlend;
begin
  if (gl_polyblend.value = 0) then
    Exit;
  if (v_blend[3] = 0) then
    Exit;

  qglDisable(GL_ALPHA_TEST);
  qglEnable(GL_BLEND);
  qglDisable(GL_DEPTH_TEST);
  qglDisable(GL_TEXTURE_2D);

  qglLoadIdentity();

  // FIXME: get rid of these
  qglRotatef(-90, 1, 0, 0); // put Z going up
  qglRotatef(90, 0, 0, 1); // put Z going up

  qglColor4fv(@v_blend);

  qglBegin(GL_QUADS);
  qglVertex3f(10, 100, 100);
  qglVertex3f(10, -100, 100);
  qglVertex3f(10, -100, -100);
  qglVertex3f(10, 100, -100);
  qglEnd();

  qglDisable(GL_BLEND);
  qglEnable(GL_TEXTURE_2D);
  qglEnable(GL_ALPHA_TEST);

  qglColor4f(1, 1, 1, 1);
end;

//=======================================================================

function SignbitsForPlane(_out: cplane_p): integer;
var
  bits, j: integer;
begin
  // for fast box on planeside test

  bits := 0;
  for j := 0 to 2 do
    if (_out.normal[j] < 0) then
      bits := bits or (1 shl j);
  Result := bits;
end; //function

procedure R_SetFrustum;
var
  i: integer;
begin
(*
 /*
 ** this code is wrong, since it presume a 90 degree FOV both in the
 ** horizontal and vertical plane
 */
 // front side is visible
 VectorAdd (vpn, vright, frustum[0].normal);
 VectorSubtract (vpn, vright, frustum[1].normal);
 VectorAdd (vpn, vup, frustum[2].normal);
 VectorSubtract (vpn, vup, frustum[3].normal);

 // we theoretically don't need to normalize these vectors, but I do it
 // anyway so that debugging is a little easier
 VectorNormalize( frustum[0].normal );
 VectorNormalize( frustum[1].normal );
 VectorNormalize( frustum[2].normal );
 VectorNormalize( frustum[3].normal );
*)
  // rotate VPN right by FOV_X/2 degrees
  RotatePointAroundVector(frustum[0].normal, vup, vpn, -(90 - r_newrefdef.fov_x / 2));
  // rotate VPN left by FOV_X/2 degrees
  RotatePointAroundVector(frustum[1].normal, vup, vpn, 90 - r_newrefdef.fov_x / 2);
  // rotate VPN up by FOV_X/2 degrees
  RotatePointAroundVector(frustum[2].normal, vright, vpn, 90 - r_newrefdef.fov_y / 2);
  // rotate VPN down by FOV_X/2 degrees
  RotatePointAroundVector(frustum[3].normal, vright, vpn, -(90 - r_newrefdef.fov_y / 2));

  for i := 0 to 3 do
  begin
    frustum[i]._type := PLANE_ANYZ;
    frustum[i].dist := DotProduct(r_origin, frustum[i].normal);
    frustum[i].signbits := SignbitsForPlane(@frustum[i]);
  end;
end; //procedure

//=======================================================================

{*
===============
R_SetupFrame
===============
*}

procedure R_SetupFrame;
var
  i: integer;
  leaf: mleaf_p;
  temp: vec3_t;
begin
  Inc(r_framecount);

  // build the transformation matrix for the given view angles
  VectorCopy(vec3_t(r_newrefdef.vieworg), r_origin);

  AngleVectors(vec3_t(r_newrefdef.viewangles), @vpn, @vright, @vup);

// current viewcluster
  if (r_newrefdef.rdflags and RDF_NOWORLDMODEL) = 0 then
  begin
    r_oldviewcluster := r_viewcluster;
    r_oldviewcluster2 := r_viewcluster2;
    leaf := Mod_PointInLeaf(r_origin, r_worldmodel);
//    r_viewcluster = r_viewcluster2 = leaf->cluster;
    r_viewcluster2 := leaf.cluster;
    r_viewcluster := r_viewcluster2;

    // check above and below so crossing solid water doesn't draw wrong
    if (leaf.contents = 0) then
    begin
      // look down a bit
      VectorCopy(r_origin, temp);
      temp[2] := temp[2] - 16;
      leaf := Mod_PointInLeaf(temp, r_worldmodel);
      if ((leaf.contents and CONTENTS_SOLID) = 0) and
        (leaf.cluster <> r_viewcluster2) then
        r_viewcluster2 := leaf.cluster;
    end
    else
    begin
      // look up a bit
      VectorCopy(r_origin, temp);
      temp[2] := temp[2] + 16;
      leaf := Mod_PointInLeaf(temp, r_worldmodel);
      if ((leaf.contents and CONTENTS_SOLID) = 0) and
        (leaf.cluster <> r_viewcluster2) then
        r_viewcluster2 := leaf.cluster;
    end;
  end;

  for i := 0 to 3 do
    v_blend[i] := r_newrefdef.blend[i];

  c_brush_polys := 0;
  c_alias_polys := 0;

  // clear out the portion of the screen that the NOWORLDMODEL defines
  if (r_newrefdef.rdflags and RDF_NOWORLDMODEL) <> 0 then
  begin
    qglEnable(GL_SCISSOR_TEST);
    qglClearColor(0.3, 0.3, 0.3, 1);
    qglScissor(r_newrefdef.x, vid.height - r_newrefdef.height - r_newrefdef.y,
      r_newrefdef.width, r_newrefdef.height);
    qglClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
    qglClearColor(1, 0, 0.5, 0.5);
    qglDisable(GL_SCISSOR_TEST);
  end;
end;

procedure MYgluPerspective(fovy, aspect,
  zNear, zFar: TGLdouble);
var
  xmin, xmax, ymin, ymax: TGLdouble;
begin
  ymax := zNear * tan(fovy * M_PI / 360.0);
  ymin := -ymax;

  xmin := ymin * aspect;
  xmax := ymax * aspect;

  xmin := xmin - (2 * gl_state.camera_separation) / zNear;
  xmax := xmax - (2 * gl_state.camera_separation) / zNear;

  qglFrustum(xmin, xmax, ymin, ymax, zNear, zFar);
end;

{*
=============
R_SetupGL
=============
*}

procedure R_SetupGL;
var
  screenaspect: Single;
//   float   yfov;
  x, x2, y2, y, w, h: integer;
begin
  //
  // set up viewport
  //
  x := Floor(r_newrefdef.x * vid.width / vid.width);
  x2 := Ceil((r_newrefdef.x + r_newrefdef.width) * vid.width / vid.width);
  y := Floor(vid.height - r_newrefdef.y * vid.height / vid.height);
  y2 := Ceil(vid.height - (r_newrefdef.y + r_newrefdef.height) * vid.height / vid.height);

  w := x2 - x;
  h := y - y2;

  qglViewport(x, y2, w, h);

  //
  // set up projection matrix
  //
  screenaspect := r_newrefdef.width / r_newrefdef.height;
//idsoft   yfov = 2*atan((float)r_newrefdef.height/r_newrefdef.width)*180/M_PI;
  qglMatrixMode(GL_PROJECTION);
  qglLoadIdentity();
  MYgluPerspective(r_newrefdef.fov_y, screenaspect, 4, 4096);

  qglCullFace(GL_FRONT);

  qglMatrixMode(GL_MODELVIEW);
  qglLoadIdentity();

  qglRotatef(-90, 1, 0, 0); // put Z going up
  qglRotatef(90, 0, 0, 1); // put Z going up
  qglRotatef(-r_newrefdef.viewangles[2], 1, 0, 0);
  qglRotatef(-r_newrefdef.viewangles[0], 0, 1, 0);
  qglRotatef(-r_newrefdef.viewangles[1], 0, 0, 1);
  qglTranslatef(-r_newrefdef.vieworg[0], -r_newrefdef.vieworg[1], -r_newrefdef.vieworg[2]);

//idsoft   if ( gl_state.camera_separation != 0 && gl_state.stereo_enabled )
//idsoft      qglTranslatef ( gl_state.camera_separation, 0, 0 );

  qglGetFloatv(GL_MODELVIEW_MATRIX, @r_world_matrix);

  //
  // set drawing parms
  //
  if (gl_cull.value <> 0) then
    qglEnable(GL_CULL_FACE)
  else
    qglDisable(GL_CULL_FACE);

  qglDisable(GL_BLEND);
  qglDisable(GL_ALPHA_TEST);
  qglEnable(GL_DEPTH_TEST);
end;

{*
=============
R_Clear
=============
*}

procedure R_Clear;
{$IFDEF COMPILER6_UP}{$WRITEABLECONST ON}{$ENDIF}
const
  trickframe: integer = 0;
{$IFDEF COMPILER6_UP}{$WRITEABLECONST OFF}{$ENDIF}
begin
  if (gl_ztrick.value <> 0) then
  begin
    if (gl_clear_.value <> 0) then
      qglClear(GL_COLOR_BUFFER_BIT);

    Inc(trickframe);
    if (trickframe and 1) <> 0 then
    begin
      gldepthmin := 0;
      gldepthmax := 0.49999;
      qglDepthFunc(GL_LEQUAL);
    end
    else
    begin
      gldepthmin := 1;
      gldepthmax := 0.5;
      qglDepthFunc(GL_GEQUAL);
    end;
  end
  else
  begin
    if (gl_clear_.value <> 0) then
      qglClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)
    else
      qglClear(GL_DEPTH_BUFFER_BIT);
    gldepthmin := 0;
    gldepthmax := 1;
    qglDepthFunc(GL_LEQUAL);
  end;

  qglDepthRange(gldepthmin, gldepthmax);
end;

procedure R_Flash;
begin
  R_PolyBlend();
end;

{*
================
R_RenderView

r_newrefdef must be set before the first call
================
*}

procedure R_RenderView(fd: refdef_p);
begin
  if (r_norefresh.value <> 0) then
    Exit;

  r_newrefdef := fd^;

  if (r_worldmodel = nil) and ((r_newrefdef.rdflags and RDF_NOWORLDMODEL) = 0) then
    ri.Sys_Error(ERR_DROP, 'R_RenderView: NULL worldmodel', []);

  if (r_speeds.value <> 0) then
  begin
    c_brush_polys := 0;
    c_alias_polys := 0;
  end;

  R_PushDlights();

  if (gl_finish.value <> 0) then
    qglFinish();

  R_SetupFrame();

  R_SetFrustum();

  R_SetupGL();

  R_MarkLeaves(); // done here so we know if we're in water

  R_DrawWorld();

  R_DrawEntitiesOnList();

  R_RenderDlights();

  R_DrawParticles();

  R_DrawAlphaSurfaces();

  R_Flash();

  if (r_speeds.value <> 0) then
    ri.Con_Printf(PRINT_ALL, '%4i wpoly %4i epoly %i tex %i lmaps'#10,
      c_brush_polys,
      c_alias_polys,
      c_visible_textures,
      c_visible_lightmaps);
end;


procedure R_SetGL2D;
begin
  // set 2D virtual screen size
  qglViewport(0, 0, vid.width, vid.height);
  qglMatrixMode(GL_PROJECTION);
  qglLoadIdentity();
  qglOrtho(0, vid.width, vid.height, 0, -99999, 99999);
  qglMatrixMode(GL_MODELVIEW);
  qglLoadIdentity();
  qglDisable(GL_DEPTH_TEST);
  qglDisable(GL_CULL_FACE);
  qglDisable(GL_BLEND);
  qglEnable(GL_ALPHA_TEST);
  qglColor4f(1, 1, 1, 1);
end;

procedure GL_DrawColoredStereoLinePair(r, g, b, y: Single);
begin
  qglColor3f(r, g, b);
  qglVertex2f(0, y);
  qglVertex2f(vid.width, y);
  qglColor3f(0, 0, 0);
  qglVertex2f(0, y + 1);
  qglVertex2f(vid.width, y + 1);
end;

procedure GL_DrawStereoPattern;
var
  i: Integer;
begin
  if (gl_config.renderer and GL_RENDERER_INTERGRAPH) = 0 then
    exit;

  if (not gl_state.stereo_enabled) then
    exit;

  R_SetGL2D();

  qglDrawBuffer(GL_BACK_LEFT);

  for i := 0 to 19 do
  begin
    qglBegin(GL_LINES);
    GL_DrawColoredStereoLinePair(1, 0, 0, 0);
    GL_DrawColoredStereoLinePair(1, 0, 0, 2);
    GL_DrawColoredStereoLinePair(1, 0, 0, 4);
    GL_DrawColoredStereoLinePair(1, 0, 0, 6);
    GL_DrawColoredStereoLinePair(0, 1, 0, 8);
    GL_DrawColoredStereoLinePair(1, 1, 0, 10);
    GL_DrawColoredStereoLinePair(1, 1, 0, 12);
    GL_DrawColoredStereoLinePair(0, 1, 0, 14);
    qglEnd();

    GLimp_EndFrame();
  end;
end;

{*
====================
R_SetLightLevel

====================
*}

procedure R_SetLightLevel;
var
  shadelight: vec3_t;
begin
  if (r_newrefdef.rdflags and RDF_NOWORLDMODEL) <> 0 then
    Exit;

  // save off light value for server to look at (BIG HACK!)

  R_LightPoint(vec3_t(r_newrefdef.vieworg), shadelight);

  // pick the greatest component, which should be the same
  // as the mono value returned by software
  if (shadelight[0] > shadelight[1]) then
  begin
    if (shadelight[0] > shadelight[2]) then
      r_lightlevel.value := 150 * shadelight[0]
    else
      r_lightlevel.value := 150 * shadelight[2]
  end
  else
  begin
    if (shadelight[1] > shadelight[2]) then
      r_lightlevel.value := 150 * shadelight[1]
    else
      r_lightlevel.value := 150 * shadelight[2];
  end;
end; //procedure

{*
@@@@@@@@@@@@@@@@@@@@@
R_RenderFrame

@@@@@@@@@@@@@@@@@@@@@
*}

procedure R_RenderFrame(fd: refdef_p); cdecl;
begin
  R_RenderView(fd);
  R_SetLightLevel();
  R_SetGL2D();
end; //procedure

procedure R_Register;
begin
  r_lefthand := ri.Cvar_Get('hand', '0', CVAR_USERINFO or CVAR_ARCHIVE);
  r_norefresh := ri.Cvar_Get('r_norefresh', '0', 0);
  r_fullbright := ri.Cvar_Get('r_fullbright', '0', 0);
  r_drawentities := ri.Cvar_Get('r_drawentities', '1', 0);
  r_drawworld_ := ri.Cvar_Get('r_drawworld', '1', 0);
  r_novis := ri.Cvar_Get('r_novis', '0', 0);
  r_nocull := ri.Cvar_Get('r_nocull', '0', 0);
  r_lerpmodels := ri.Cvar_Get('r_lerpmodels', '1', 0);
  r_speeds := ri.Cvar_Get('r_speeds', '0', 0);

  r_lightlevel := ri.Cvar_Get('r_lightlevel', '0', 0);

  gl_nosubimage := ri.Cvar_Get('gl_nosubimage', '0', 0);
  gl_allow_software := ri.Cvar_Get('gl_allow_software', '0', 0);

  gl_particle_min_size := ri.Cvar_Get('gl_particle_min_size', '2', CVAR_ARCHIVE);
  gl_particle_max_size := ri.Cvar_Get('gl_particle_max_size', '40', CVAR_ARCHIVE);
  gl_particle_size := ri.Cvar_Get('gl_particle_size', '40', CVAR_ARCHIVE);
  gl_particle_att_a := ri.Cvar_Get('gl_particle_att_a', '0.01', CVAR_ARCHIVE);
  gl_particle_att_b := ri.Cvar_Get('gl_particle_att_b', '0.0', CVAR_ARCHIVE);
  gl_particle_att_c := ri.Cvar_Get('gl_particle_att_c', '0.01', CVAR_ARCHIVE);

  gl_modulate_ := ri.Cvar_Get('gl_modulate', '1', CVAR_ARCHIVE);
  gl_log := ri.Cvar_Get('gl_log', '0', 0);
  gl_bitdepth := ri.Cvar_Get('gl_bitdepth', '0', 0);
  gl_mode := ri.Cvar_Get('gl_mode', '3', CVAR_ARCHIVE);
  gl_lightmap := ri.Cvar_Get('gl_lightmap', '0', 0);
  gl_shadows := ri.Cvar_Get('gl_shadows', '0', CVAR_ARCHIVE);
  gl_dynamic := ri.Cvar_Get('gl_dynamic', '1', 0);
  gl_nobind := ri.Cvar_Get('gl_nobind', '0', 0);
  gl_round_down := ri.Cvar_Get('gl_round_down', '1', 0);
  gl_picmip := ri.Cvar_Get('gl_picmip', '0', 0);
  gl_skymip := ri.Cvar_Get('gl_skymip', '0', 0);
  gl_showtris := ri.Cvar_Get('gl_showtris', '0', 0);
  gl_ztrick := ri.Cvar_Get('gl_ztrick', '0', 0);
  gl_finish := ri.Cvar_Get('gl_finish', '0', CVAR_ARCHIVE);
  gl_clear_ := ri.Cvar_Get('gl_clear', '0', 0);
  gl_cull := ri.Cvar_Get('gl_cull', '1', 0);
  gl_polyblend := ri.Cvar_Get('gl_polyblend', '1', 0);
  gl_flashblend := ri.Cvar_Get('gl_flashblend', '0', 0);
  gl_playermip := ri.Cvar_Get('gl_playermip', '0', 0);
  gl_monolightmap := ri.Cvar_Get('gl_monolightmap', '0', 0);
  gl_driver := ri.Cvar_Get('gl_driver', 'opengl32', CVAR_ARCHIVE);
  gl_texturemode_ := ri.Cvar_Get('gl_texturemode', 'GL_LINEAR_MIPMAP_NEAREST', CVAR_ARCHIVE);
  gl_texturealphamode_ := ri.Cvar_Get('gl_texturealphamode', 'default', CVAR_ARCHIVE);
  gl_texturesolidmode_ := ri.Cvar_Get('gl_texturesolidmode', 'default', CVAR_ARCHIVE);
  gl_lockpvs := ri.Cvar_Get('gl_lockpvs', '0', 0);

  gl_vertex_arrays := ri.Cvar_Get('gl_vertex_arrays', '0', CVAR_ARCHIVE);

  gl_ext_swapinterval := ri.Cvar_Get('gl_ext_swapinterval', '1', CVAR_ARCHIVE);
  gl_ext_palettedtexture := ri.Cvar_Get('gl_ext_palettedtexture', '1', CVAR_ARCHIVE);
  gl_ext_multitexture := ri.Cvar_Get('gl_ext_multitexture', '1', CVAR_ARCHIVE);
  gl_ext_pointparameters := ri.Cvar_Get('gl_ext_pointparameters', '1', CVAR_ARCHIVE);
  gl_ext_compiled_vertex_array := ri.Cvar_Get('gl_ext_compiled_vertex_array', '1', CVAR_ARCHIVE);

  gl_drawbuffer := ri.Cvar_Get('gl_drawbuffer', 'GL_BACK', 0);
  gl_swapinterval := ri.Cvar_Get('gl_swapinterval', '1', CVAR_ARCHIVE);

  gl_saturatelighting := ri.Cvar_Get('gl_saturatelighting', '0', 0);

  gl_3dlabs_broken := ri.Cvar_Get('gl_3dlabs_broken', '1', CVAR_ARCHIVE);

  vid_fullscreen := ri.Cvar_Get('vid_fullscreen', '0', CVAR_ARCHIVE);
  vid_gamma := ri.Cvar_Get('vid_gamma', '1.0', CVAR_ARCHIVE);
  vid_ref := ri.Cvar_Get('vid_ref', 'soft', CVAR_ARCHIVE);

  ri.Cmd_AddCommand('imagelist', GL_ImageList_f);
  ri.Cmd_AddCommand('screenshot', GL_ScreenShot_f);
  ri.Cmd_AddCommand('modellist', Mod_Modellist_f);
  ri.Cmd_AddCommand('gl_strings', GL_Strings_f);
end; //procedure

{*
==================
R_SetMode
==================
*}

function R_SetMode: qboolean;
var
  err: rserr_t;
  fullscreen: qboolean;
begin
  if (vid_fullscreen.modified) and (not gl_config.allow_cds) then
  begin
    ri.Con_Printf(PRINT_ALL, 'R_SetMode() - CDS not allowed with this driver'#10, []);
    ri.Cvar_SetValue('vid_fullscreen', Integer(not Boolean(Trunc(vid_fullscreen.value))));
    vid_fullscreen.modified := false;
  end;

  fullscreen := (vid_fullscreen.value <> 0);

  vid_fullscreen.modified := false;
  gl_mode.modified := false;

  err := GLimp_SetMode(vid.width, vid.height, Trunc(gl_mode.value), fullscreen);
  if (err = rserr_ok) then
    gl_state.prev_mode := Trunc(gl_mode.value)
  else
  begin
    if (err = rserr_invalid_fullscreen) then
    begin
      ri.Cvar_SetValue('vid_fullscreen', 0);
      vid_fullscreen.modified := false;
      ri.Con_Printf(PRINT_ALL, 'ref_gl::R_SetMode() - fullscreen unavailable in this mode'#10, []);
      err := GLimp_SetMode(vid.width, vid.height, Trunc(gl_mode.value), false); 
      if (err = rserr_ok) then
      begin
        Result := true;
        Exit;
      end;
    end
    else
      if (err = rserr_invalid_mode) then
      begin
        ri.Cvar_SetValue('gl_mode', gl_state.prev_mode);
        gl_mode.modified := false;
        ri.Con_Printf(PRINT_ALL, 'ref_gl::R_SetMode() - invalid mode'#10, []);
      end;

    // try setting it back to something safe
    err := GLimp_SetMode(vid.width, vid.height, gl_state.prev_mode, false);
    if (err <> rserr_ok) then
    begin
      ri.Con_Printf(PRINT_ALL, 'ref_gl::R_SetMode() - could not revert to safe mode'#10, []);
      Result := false;
      Exit;
    end;
  end;
  Result := true;
end;

{*
===============
R_Init
===============
*}
function R_Init(hinstance: HINST; hWnd: pointer): integer; cdecl;
var
  renderer_buffer,
  vendor_buffer: array[0..1000 - 1] of Char;

  err: integer;
  j: integer;
begin
  for j := 0 to 255 do
    r_turbsin[j] := r_turbsin[j] * 0.5;

  ri.Con_Printf(PRINT_ALL, 'ref_gl version: ' + REF_VERSION + #10, []);

  Draw_GetPalette();

  R_Register();

  // initialize our QGL dynamic bindings
  if not QGL_Init(gl_driver.string_) then
  begin
    QGL_Shutdown();
    ri.Con_Printf(PRINT_ALL, 'ref_gl::R_Init() - could not load "%s"'#10, gl_driver.string_);
    Result := -1;
    Exit;
  end;

  // initialize OS-specific parts of OpenGL
  if not GLimp_Init(hinstance, hWnd) then
  begin
    QGL_Shutdown();
    Result := -1;
    Exit;
  end;

  // set our "safe" modes
  gl_state.prev_mode := 3;

  // create the window and set up the context
  if not R_SetMode() then
  begin
    QGL_Shutdown();
    ri.Con_Printf(PRINT_ALL, 'ref_gl::R_Init() - could not R_SetMode()'#10, []);
    Result := -1;
    Exit;
  end;

  ri.Vid_MenuInit();

  {*
  ** get our various GL strings
  *}
  gl_config.vendor_string := PChar(qglGetString(GL_VENDOR));
  ri.Con_Printf(PRINT_ALL, 'GL_VENDOR: %s'#10, gl_config.vendor_string);
  gl_config.renderer_string := PChar(qglGetString(GL_RENDERER));
  ri.Con_Printf(PRINT_ALL, 'GL_RENDERER: %s'#10, gl_config.renderer_string);
  gl_config.version_string := PChar(qglGetString(GL_VERSION));
  ri.Con_Printf(PRINT_ALL, 'GL_VERSION: %s'#10, gl_config.version_string);
  gl_config.extensions_string := PChar(qglGetString(GL_EXTENSIONS));
  ri.Con_Printf(PRINT_ALL, 'GL_EXTENSIONS: %s'#10, gl_config.extensions_string);

  CPas.strcpy(renderer_buffer, gl_config.renderer_string);
//  strlwr( renderer_buffer );

  CPas.strcpy(vendor_buffer, gl_config.vendor_string);
//  strlwr( vendor_buffer );

  if (CPas.strstr(renderer_buffer, 'voodoo') <> nil) then
  begin
//    if (!strstr (renderer_buffer, 'rush'))
    if (CPas.strstr(renderer_buffer, 'rush') = nil) then
      gl_config.renderer := GL_RENDERER_VOODOO
    else
      gl_config.renderer := GL_RENDERER_VOODOO_RUSH;
  end
  else
  begin
    if (CPas.strstr(vendor_buffer, 'sgi') <> nil) then
      gl_config.renderer := GL_RENDERER_SGI
    else
      if (CPas.strstr(renderer_buffer, 'permedia') <> nil) then
        gl_config.renderer := GL_RENDERER_PERMEDIA2
      else
        if (CPas.strstr(renderer_buffer, 'glint') <> nil) then
          gl_config.renderer := GL_RENDERER_GLINT_MX
        else
          if (CPas.strstr(renderer_buffer, 'glzicd') <> nil) then
            gl_config.renderer := GL_RENDERER_REALIZM
          else
            if (CPas.strstr(renderer_buffer, 'gdi') <> nil) then
              gl_config.renderer := GL_RENDERER_MCD
            else
              if (CPas.strstr(renderer_buffer, 'pcx2') <> nil) then
                gl_config.renderer := GL_RENDERER_PCX2
              else
                if (CPas.strstr(renderer_buffer, 'verite') <> nil) then
                  gl_config.renderer := GL_RENDERER_RENDITION
                else
                  gl_config.renderer := GL_RENDERER_OTHER;
  end; //else

//  if ( toupper( gl_monolightmap.string[1] ) != 'F' )
  if (UpCase(gl_monolightmap.string_[1]) <> 'F') then
  begin
    if (gl_config.renderer = GL_RENDERER_PERMEDIA2) then
    begin
      ri.Cvar_Set('gl_monolightmap', 'A');
      ri.Con_Printf(PRINT_ALL, '...using gl_monolightmap ''a'''#10, []);
    end
    else
      if (gl_config.renderer and GL_RENDERER_POWERVR) <> 0 then
        ri.Cvar_Set('gl_monolightmap', '0')
      else
        ri.Cvar_Set('gl_monolightmap', '0');
  end;

  // power vr can't have anything stay in the framebuffer, so
  // the screen needs to redraw the tiled background every frame
  if (gl_config.renderer and GL_RENDERER_POWERVR) <> 0 then
    ri.Cvar_Set('scr_drawall', '1')
  else
    ri.Cvar_Set('scr_drawall', '0');

  // MCD has buffering issues
  if (gl_config.renderer = GL_RENDERER_MCD) then
    ri.Cvar_SetValue('gl_finish', 1);

  if (gl_config.renderer and GL_RENDERER_3DLABS) <> 0 then
  begin
    if (gl_3dlabs_broken.value <> 0) then
      gl_config.allow_cds := false
    else
      gl_config.allow_cds := true;
  end
  else
    gl_config.allow_cds := true;

  if (gl_config.allow_cds) then
    ri.Con_Printf(PRINT_ALL, '...allowing CDS'#10, [])
  else
    ri.Con_Printf(PRINT_ALL, '...disabling CDS'#10, []);

  {*
   ** grab extensions
   *}
  if (CPas.strstr(gl_config.extensions_string, 'GL_EXT_compiled_vertex_array') <> nil) or
    (CPas.strstr(gl_config.extensions_string, 'GL_SGI_compiled_vertex_array') <> nil) then
  begin
    ri.Con_Printf(PRINT_ALL, '...enabling GL_EXT_compiled_vertex_array'#10, []);
    qglLockArraysEXT := qwglGetProcAddress('glLockArraysEXT');
    qglUnlockArraysEXT := qwglGetProcAddress('glUnlockArraysEXT');
  end
  else
    ri.Con_Printf(PRINT_ALL, '...GL_EXT_compiled_vertex_array not found'#10, []);

{$IFDEF WIN32}
  if (CPas.strstr(gl_config.extensions_string, 'WGL_EXT_swap_control') <> nil) then
  begin
    qwglSwapIntervalEXT := qwglGetProcAddress('wglSwapIntervalEXT');
    ri.Con_Printf(PRINT_ALL, '...enabling WGL_EXT_swap_control'#10, []);
  end
  else
    ri.Con_Printf(PRINT_ALL, '...WGL_EXT_swap_control not found'#10, []);
{$ENDIF}

  if (CPas.strstr(gl_config.extensions_string, 'GL_EXT_point_parameters') <> nil) then
  begin
    if (gl_ext_pointparameters.value <> 0) then
    begin
      qglPointParameterfEXT := qwglGetProcAddress('glPointParameterfEXT');
      qglPointParameterfvEXT := qwglGetProcAddress('glPointParameterfvEXT');
      ri.Con_Printf(PRINT_ALL, '...using GL_EXT_point_parameters'#10, []);
    end
    else
      ri.Con_Printf(PRINT_ALL, '...ignoring GL_EXT_point_parameters'#10, []);
  end
  else
    ri.Con_Printf(PRINT_ALL, '...GL_EXT_point_parameters not found'#10, []);

  if (not assigned(qglColorTableEXT)) and
    (CPas.strstr(gl_config.extensions_string, 'GL_EXT_paletted_texture') <> nil) and
    (CPas.strstr(gl_config.extensions_string, 'GL_EXT_shared_texture_palette') <> nil) then
  begin
    if (gl_ext_palettedtexture.value <> 0) then
    begin
      ri.Con_Printf(PRINT_ALL, '...using GL_EXT_shared_texture_palette'#10, []);
      qglColorTableEXT := qwglGetProcAddress('glColorTableEXT');
    end
    else
      ri.Con_Printf(PRINT_ALL, '...ignoring GL_EXT_shared_texture_palette'#10, []);
  end
  else
    ri.Con_Printf(PRINT_ALL, '...GL_EXT_shared_texture_palette not found'#10, []);

  if (strstr(gl_config.extensions_string, 'GL_ARB_multitexture') <> nil) then
  begin
    if (gl_ext_multitexture.value <> 0) then
    begin
      ri.Con_Printf(PRINT_ALL, '...using GL_ARB_multitexture'#10);
      qglMTexCoord2fSGIS := qwglGetProcAddress('glMultiTexCoord2fARB');
      qglActiveTextureARB := qwglGetProcAddress('glActiveTextureARB');
      qglClientActiveTextureARB := qwglGetProcAddress('glClientActiveTextureARB');
      GL_TEXTURE0 := GL_TEXTURE0_ARB;
      GL_TEXTURE1 := GL_TEXTURE1_ARB;
    end
    else
    begin
      ri.Con_Printf(PRINT_ALL, '...ignoring GL_ARB_multitexture'#10);
    end
  end
  else
  begin
    ri.Con_Printf(PRINT_ALL, '...GL_ARB_multitexture not found'#10);
  end;

  if (CPas.strstr(gl_config.extensions_string, 'GL_SGIS_multitexture') <> nil) then
  begin
    if assigned(qglActiveTextureARB) then
    begin
      ri.Con_Printf(PRINT_ALL, '...GL_SGIS_multitexture deprecated in favor of ARB_multitexture'#10);
    end
    else
      if (gl_ext_multitexture.value <> 0) then
      begin
        ri.Con_Printf(PRINT_ALL, '...using GL_SGIS_multitexture'#10, []);
        qglMTexCoord2fSGIS := qwglGetProcAddress('glMTexCoord2fSGIS');
        qglSelectTextureSGIS := qwglGetProcAddress('glSelectTextureSGIS');
        GL_TEXTURE0 := GL_TEXTURE0_SGIS;
        GL_TEXTURE1 := GL_TEXTURE1_SGIS;
      end
      else
        ri.Con_Printf(PRINT_ALL, '...ignoring GL_SGIS_multitexture'#10, []);
  end
  else
    ri.Con_Printf(PRINT_ALL, '...GL_SGIS_multitexture not found'#10, []);

  GL_SetDefaultState();

  {
  ** draw our stereo patterns
  }
  (*
  // commented out until H3D pays us the money they owe us
  GL_DrawStereoPattern();
  *)

  GL_InitImages();
  Mod_Init();
  R_InitParticleTexture();
  Draw_InitLocal();

  err := qglGetError();
  if (err <> GL_NO_ERROR) then
    ri.Con_Printf(PRINT_ALL, 'glGetError() = 0x%x'#10, [err]);
end; //function

{*
===============
R_Shutdown
===============
*}

procedure R_Shutdown; cdecl;
begin
  ri.Cmd_RemoveCommand('modellist');
  ri.Cmd_RemoveCommand('screenshot');
  ri.Cmd_RemoveCommand('imagelist');
  ri.Cmd_RemoveCommand('gl_strings');

  Mod_FreeAll();

  GL_ShutdownImages();

  {*
  ** shut down OS specific OpenGL stuff like contexts, etc.
  *}
  GLimp_Shutdown();

  {*
  ** shutdown our QGL subsystem
  *}
  QGL_Shutdown();
end; //procedure

{*
@@@@@@@@@@@@@@@@@@@@@
R_BeginFrame
@@@@@@@@@@@@@@@@@@@@@
*}

procedure R_BeginFrame(camera_separation: Single); cdecl;
var
  ref: cvar_p;
  envbuffer: array[0..1024 - 1] of char;
  g: Single;
begin
  gl_state.camera_separation := camera_separation;

  {*
  ** change modes if necessary
  *}
  if (gl_mode.modified or vid_fullscreen.modified) then
  begin
    // FIXME: only restart if CDS is required
    ref := ri.Cvar_Get('vid_ref', 'gl', 0);
    ref.modified := true;
  end;

  if (gl_log.modified) then
  begin
    GLimp_EnableLogging((gl_log.value <> 0));
    gl_log.modified := false;
  end;

  if (gl_log.value <> 0) then
    GLimp_LogNewFrame();

  {*
  ** update 3Dfx gamma -- it is expected that a user will do a vid_restart
  ** after tweaking this value
  *}
  if (vid_gamma.modified) then
  begin
    vid_gamma.modified := false;

    if ((gl_config.renderer and GL_RENDERER_VOODOO) <> 0) then
    begin
      g := 2.00 * (0.8 - (vid_gamma.value - 0.5)) + 1.0;
      (* Juha: TODO
      Com_sprintf (envbuffer, sizeof(envbuffer), 'SSTV2_GAMMA=%f', g);
      putenv (envbuffer);
      Com_sprintf (envbuffer, sizeof(envbuffer), 'SST_GAMMA=%f', g);
      putenv (envbuffer);*)
    end;
  end;

  GLimp_BeginFrame(camera_separation);

  {*
  ** go into 2D mode
  *}
  qglViewport(0, 0, vid.width, vid.height);
  qglMatrixMode(GL_PROJECTION);
  qglLoadIdentity();
  qglOrtho(0, vid.width, vid.height, 0, -99999, 99999);
  qglMatrixMode(GL_MODELVIEW);
  qglLoadIdentity();
  qglDisable(GL_DEPTH_TEST);
  qglDisable(GL_CULL_FACE);
  qglDisable(GL_BLEND);
  qglEnable(GL_ALPHA_TEST);
  qglColor4f(1, 1, 1, 1);

  {*
  ** draw buffer stuff
  *}
  if (gl_drawbuffer.modified) then
  begin
    gl_drawbuffer.modified := false;

    if (gl_state.camera_separation = 0) or (not gl_state.stereo_enabled) then
      if (Q_stricmp(gl_drawbuffer.string_, 'GL_FRONT') = 0) then
        qglDrawBuffer(GL_FRONT)
      else
        qglDrawBuffer(GL_BACK);
  end;

  {*
  ** texturemode stuff
  *}
  if (gl_texturemode_.modified) then
  begin
    GL_TextureMode(gl_texturemode_.string_);
    gl_texturemode_.modified := false;
  end;

  if (gl_texturealphamode_.modified) then
  begin
    GL_TextureAlphaMode(gl_texturealphamode_.string_);
    gl_texturealphamode_.modified := false;
  end;

  if (gl_texturesolidmode_.modified) then
  begin
    GL_TextureSolidMode(gl_texturesolidmode_.string_);
    gl_texturesolidmode_.modified := false;
  end;

  {*
  ** swapinterval stuff
  *}
  GL_UpdateSwapInterval();

  //
  // clear screen if desired
  //
  R_Clear();
end; //procedure

{*
=============
R_SetPalette
=============
*}

procedure R_SetPalette(palette: PByte); cdecl;
var
  i: integer;
  rp: PByteArray;
begin
  rp := @r_rawpalette;

  if (palette <> nil) then
    for i := 0 to 255 do
    begin
      rp[i * 4 + 0] := PByteArray(palette)[i * 3 + 0];
      rp[i * 4 + 1] := PByteArray(palette)[i * 3 + 1];
      rp[i * 4 + 2] := PByteArray(palette)[i * 3 + 2];
      rp[i * 4 + 3] := $FF;
    end
  else
    for i := 0 to 255 do
    begin
      rp[i * 4 + 0] := d_8to24table[i] and $FF;
      rp[i * 4 + 1] := (d_8to24table[i] shr 8) and $FF;
      rp[i * 4 + 2] := (d_8to24table[i] shr 16) and $FF;
      rp[i * 4 + 3] := $FF;
    end;
  GL_SetTexturePalette(@r_rawpalette);

  qglClearColor(0, 0, 0, 0);
  qglClear(GL_COLOR_BUFFER_BIT);
  qglClearColor(1, 0, 0.5, 0.5);
end; //procedure

{*
** R_DrawBeam
*}

procedure R_DrawBeam(e: entity_p);
const
  NUM_BEAM_SEGS = 6;
var
  i: integer;
  r, g, b: Single;

  perpvec,
    direction,
    normalized_direction,
    oldorigin, origin: vec3_t;
  start_points,
    end_points: array[0..NUM_BEAM_SEGS - 1] of vec3_t;
begin
  oldorigin[0] := e.oldorigin[0];
  oldorigin[1] := e.oldorigin[1];
  oldorigin[2] := e.oldorigin[2];
//oldorigin := e.oldorigin;  if EQUAL type:  vec3_t & array[0..2] of float

  origin[0] := e.origin[0];
  origin[1] := e.origin[1];
  origin[2] := e.origin[2];
//origin := e.origin;  //up!

{  normalized_direction[0] = direction[0] = oldorigin[0] - origin[0];
  normalized_direction[1] = direction[1] = oldorigin[1] - origin[1];
  normalized_direction[2] = direction[2] = oldorigin[2] - origin[2];}
  direction[0] := oldorigin[0] - origin[0];
  direction[1] := oldorigin[1] - origin[1];
  direction[2] := oldorigin[2] - origin[2];
  normalized_direction := direction;

  if (VectorNormalize(normalized_direction) = 0) then
    Exit;

  PerpendicularVector(perpvec, normalized_direction);
  VectorScale(perpvec, e.frame / 2, perpvec);

  for i := 0 to 5 do
  begin
    RotatePointAroundVector(start_points[i], normalized_direction, perpvec, (360.0 / NUM_BEAM_SEGS) * i);
    VectorAdd(start_points[i], origin, start_points[i]);
    VectorAdd(start_points[i], direction, end_points[i]);
  end;

  qglDisable(GL_TEXTURE_2D);
  qglEnable(GL_BLEND);
  qglDepthMask(False);

  r := (d_8to24table[e.skinnum and $FF]) and $FF;
  g := (d_8to24table[e.skinnum and $FF] shr 8) and $FF;
  b := (d_8to24table[e.skinnum and $FF] shr 16) and $FF;

  r := r * (1 / 255.0);
  g := g * (1 / 255.0);
  b := b * (1 / 255.0);

  qglColor4f(r, g, b, e.alpha);

  qglBegin(GL_TRIANGLE_STRIP);
  for i := 0 to NUM_BEAM_SEGS - 1 do
  begin
    qglVertex3fv(@start_points[i]);
    qglVertex3fv(@end_points[i]);
    qglVertex3fv(@start_points[(i + 1) mod NUM_BEAM_SEGS]);
    qglVertex3fv(@end_points[(i + 1) mod NUM_BEAM_SEGS]);
  end;
  qglEnd();

  qglEnable(GL_TEXTURE_2D);
  qglDisable(GL_BLEND);
  qglDepthMask(True);
end;

//===================================================================

{*
@@@@@@@@@@@@@@@@@@@@@
GetRefAPI

@@@@@@@@@@@@@@@@@@@@@
*}

function GetRefAPI(rimp: refimport_t): refexport_t;
var
  re: refexport_t;
begin
  ri := rimp;

  re.api_version := API_VERSION;

  re.BeginRegistration := R_BeginRegistration; //gl_model.c
  re.RegisterModel := R_RegisterModel; //gl_model.c
  re.RegisterSkin := R_RegisterSkin; //gl_image.c
  re.RegisterPic := Draw_FindPic; //gl_draw.c
  re.SetSky := R_SetSky; //gl_warp.c
  re.EndRegistration := R_EndRegistration; //gl_model.c

  re.RenderFrame := R_RenderFrame; //gl_rmain.R_RenderFrame ();

  re.DrawGetPicSize := Draw_GetPicSize; //gl_draw.c
  re.DrawPic := Draw_Pic; //gl_draw.c
  re.DrawStretchPic := Draw_StretchPic; //gl_draw.c
  re.DrawChar := Draw_Char; //gl_draw.c
  re.DrawTileClear := Draw_TileClear; //gl_draw.c
  re.DrawFill := Draw_Fill; //gl_draw.c
  re.DrawFadeScreen := Draw_FadeScreen; //gl_draw.c

  re.DrawStretchRaw := Draw_StretchRaw; //gl_draw.c

  re.Init := R_Init; //gl_rmain.R_Init ();
  re.Shutdown := R_Shutdown; //gl_rmain.R_Shutdown ();

  re.CinematicSetPalette := R_SetPalette; //gl_rmain.R_SetPalette ()
  re.BeginFrame := R_BeginFrame; //gl_rmain.R_BeginFrame ()
  re.EndFrame := GLimp_EndFrame; //glw_imp.GLimp_EndFrame

  re.AppActivate := GLimp_AppActivate; //glw_imp.GLimp_AppActivate

  Swap_Init();

  Result := re;
end;


// this is only here so the functions in q_shared.c and q_shwin.c can link

procedure Sys_Error(fmt: PChar; args: array of const);
var
  text: array[0..1024 - 1] of char;
begin
  DelphiStrFmt(text, fmt, args);
  ri.Sys_Error(ERR_FATAL, text);
end;

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

// End of file
end.

