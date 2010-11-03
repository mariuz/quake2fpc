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
{ File(s): gl_warp.c -- sky and water polygons                               }
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
{ Updated on :                                                               }
{ Updated by :                                                               }
{                                                                            }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{                                                                            }
{ x) warpsin.inc                                                             }
{                                                                            }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{ 1) Do more tests                                                           }
{                                                                            }
{----------------------------------------------------------------------------}
{ 28.06.2003 Juha: Proofreaded}
// gl_warp.c -- sky and water polygons

unit gl_warp;

interface

uses
  q_shared,
  gl_model_h;

procedure GL_SubdivideSurface(fa: msurface_p);
procedure R_SetSky(name: PChar; rotate: Single; axis: vec3_p); cdecl
procedure R_DrawSkyBox;
procedure R_ClearSkyBox;
procedure R_AddSkySurface(fa: msurface_p);
procedure EmitWaterPolys(fa: msurface_p);

var
  // speed up sin calculations - Ed
  r_turbsin: array[0..32 * 8 - 1] of Single =
  (
{$I warpsin.inc}
    );


implementation

uses
  DelphiTypes,
  CPas,
  q_shwin,
  Ref,
  gl_local_add,
  gl_local,
  OpenGL,
  qgl_win,
  gl_model,
  gl_rmain,
  gl_image;



var
  skyname: array[0..MAX_QPATH - 1] of char;
  skyrotate: Single;
  skyaxis: vec3_t;
  sky_images: array[0..5] of image_p;

  warpface: msurface_p;

const
  SUBDIVIDE_SIZE = 64;
//id: #define   SUBDIVIDE_SIZE   1024


procedure BoundPoly(numverts: integer; verts: PSingle; var mins, maxs: vec3_t);
var
  i, j: integer;
  v: PSingle;
begin
  mins[0] := 9999;
  mins[1] := mins[0];
  mins[2] := mins[0];
  maxs[0] := -9999;
  maxs[1] := maxs[0];
  maxs[2] := maxs[0];
  v := verts;
  for i := 0 to numverts - 1 do
    for j := 0 to 2 do
    begin
      if (v^ < mins[j]) then
        mins[j] := v^;
      if (v^ > maxs[j]) then
        maxs[j] := v^;
      Inc(v);
    end;
end;

procedure SubdividePolygon(numverts: integer; verts: PSingle);
var
  i, j, k: integer;
  mins,
  maxs: vec3_t;
  m: Single;
  v: PSingle;

  front,
  back: array[0..63] of vec3_t;
  f, b: integer;
  dist: array[0..63] of Single;
  frac: Single;

  poly: glpoly_p;

  total: vec3_t;
  s, t,
  total_s,
  total_t: Single;
label
  continue_;
begin
  if (numverts > 60) then
    ri.Sys_Error(ERR_DROP, 'numverts = %i', [numverts]);

  BoundPoly(numverts, verts, mins, maxs);

  for i := 0 to 2 do
  begin
    m := (mins[i] + maxs[i]) * 0.5;
    m := SUBDIVIDE_SIZE * Floor(m / SUBDIVIDE_SIZE + 0.5);
    if (maxs[i] - m < 8) then
      Continue;
    if (m - mins[i] < 8) then
      Continue;

    // cut it
    v := verts;
    Inc(v, i);
    j := 0;
    while (j < numverts) do
    begin
      dist[j] := v^ - m;
      Inc(v, 3);
      Inc(j);
    end;

    // wrap cases
    dist[j] := dist[0];
    Dec(v, i);
    VectorCopy(vec3_p(verts)^, vec3_p(v)^);

    f := 0;
    b := 0;
    v := verts;
    for j := 0 to numverts - 1 do
    begin
      if (dist[j] >= 0) then
      begin
        VectorCopy(vec3_p(v)^, front[f]);
        Inc(f);
      end;
      if (dist[j] <= 0) then
      begin
        VectorCopy(vec3_p(v)^, back[b]);
        Inc(b);
      end;
      if (dist[j] = 0) or (dist[j + 1] = 0) then
        goto continue_;
      if ((dist[j] > 0) <> (dist[j + 1] > 0)) then
      begin
        // clip point
        frac := dist[j] / (dist[j] - dist[j + 1]);
        for k := 0 to 2 do
        begin
          back[b][k] := PSingleArray(v)^[k] + frac * (PSingleArray(v)^[3 + k] - PSingleArray(v)^[k]);
          front[f][k] := back[b][k];
        end;
        Inc(f);
        Inc(b);
      end;

      continue_:
      Inc(v, 3);
    end;

    SubdividePolygon(f, @front[0]);
    SubdividePolygon(b, @back[0]);
    Exit;
  end;

  // add a point in the center to help keep warp valid
  poly := Hunk_Alloc(sizeof(glpoly_t) + ((numverts - 4) + 2) * VERTEXSIZE * sizeof(Single));
  poly.next := warpface.polys;
  warpface.polys := poly;
  poly.numverts := numverts + 2;
  VectorClear(total);
  total_s := 0;
  total_t := 0;
  i := 0;
  while (i < numverts) do
  begin
    VectorCopy(vec3_p(verts)^, vec3_p(@poly.verts[i + 1])^);
    s := DotProduct(vec3_p(verts)^, vec3_p(@warpface.texinfo.vecs[0])^);
    t := DotProduct(vec3_p(verts)^, vec3_p(@warpface.texinfo.vecs[1])^);

    total_s := total_s + s;
    total_t := total_t + t;
    VectorAdd(total, vec3_p(verts)^, total);

    poly.verts[i + 1][3] := s;
    poly.verts[i + 1][4] := t;

    Inc(i);
    Inc(verts, 3);
  end;

  VectorScale(total, (1.0 / numverts), vec3_p(@poly.verts[0])^);
  poly.verts[0][3] := total_s / numverts;
  poly.verts[0][4] := total_t / numverts;

  // copy first vertex to last
  memcpy(@poly.verts[i + 1], @poly.verts[1], sizeof(poly.verts[0]));
end; //procedure

{*
================
GL_SubdivideSurface

Breaks a polygon up along axial 64 unit
boundaries so that turbulent and sky warps
can be done reasonably.
================
*}
procedure GL_SubdivideSurface(fa: msurface_p); //for gl_model
var
  verts: array[0..63] of vec3_t;
  numverts,
    i,
    lindex: integer;
  vec: vec3_p;
begin
  warpface := fa;
  //
  // convert edges back to a normal polygon
  //
  numverts := 0;
  for i := 0 to fa.numedges - 1 do
  begin
    lindex := PIntegerArray(loadmodel.surfedges)^[fa^.firstedge + i];

    if (lindex > 0) then
      vec := @loadmodel.vertexes^[loadmodel.edges[lindex].v[0]].position
    else
      vec := @loadmodel.vertexes[loadmodel.edges[-lindex].v[1]].position;
    VectorCopy(vec^, verts[numverts]);
    Inc(numverts);
  end;

  SubdividePolygon(numverts, @verts[0]);
end;

const
  TURBSCALE = 256.0 / (2 * M_PI);

{*
=============
EmitWaterPolys

Does a water warp on the pre-fragmented glpoly_t chain
=============
*}
procedure EmitWaterPolys(fa: msurface_p);
var
  bp, p: glpoly_p;
  v: psinglearray;
  i: integer;
  s, t,
    os, ot,
    scroll,
    rdt: Single;
begin
  rdt := r_newrefdef.time;

  if ((fa.texinfo.flags and SURF_FLOWING) <> 0) then
    scroll := -64 * ( (r_newrefdef.time*0.5) - Trunc(r_newrefdef.time*0.5) )
  else
    scroll := 0;


  bp := fa.polys;
  while (bp <> nil) do
  begin
    p := bp;

    qglBegin(GL_TRIANGLE_FAN);
    v := @p.verts[0];
    for i:= 0 to p.numverts - 1 do
    begin
      os := v[3];
      ot := v[4];

{$ifndef id386}
      s := os + r_turbsin[trunc(((ot*0.125+r_newrefdef.time) * TURBSCALE)) and 255];
{$else}
      s := os + r_turbsin[Q_ftol( ((ot*0.125+rdt) * TURBSCALE) ) and 255];
{$endif}
      s := s +scroll;
      s := s *(1.0/64);
{$ifndef id386}
      t := ot + r_turbsin[trunc((os*0.125+rdt) * TURBSCALE) and 255];
{$else}
      t := ot + r_turbsin[Q_ftol( ((os*0.125+rdt) * TURBSCALE)) and 255];
{$endif}
      t := t *(1.0/64);

      qglTexCoord2f (s, t);
      qglVertex3fv (@v[0]);
      v := PSingleArray(Cardinal(v) + VERTEXSIZE * SizeOf(Single));
    end;
    qglEnd();
    bp := bp.next;
  end;
end;

const
  skyclip: array[0..5] of vec3_t =
  ((1, 1, 0),
    (1, -1, 0),
    (0, -1, 1),
    (0, 1, 1),
    (1, 0, 1),
    (-1, 0, 1));
var
  c_sky: integer;

const
  // 1 = s, 2 = t, 3 = 2048
  st_to_vec: array[0..5, 0..2] of integer =
  ((3, -1, 2),
    (-3, 1, 2),

    (1, 3, 2),
    (-1, -3, 2),

    (-2, -1, 3), // 0 degrees yaw, look straight up
    (2, -1, -3) // look straight down

//   {-1,2,3},
//   {1,2,-3}
    );

  // s = [0]/[2], t = [1]/[2]
  vec_to_st: array[0..5, 0..2] of integer =
  ((-2, 3, 1),
    (2, 3, -1),

    (1, 3, 2),
    (-1, 3, -2),

    (-2, -1, 3),
    (-2, 1, -3)

//   {-1,2,3},
//   {1,2,-3}
    );

var
  skymins, skymaxs: array[0..1, 0..5] of Single;
  sky_min, sky_max: Single;

procedure DrawSkyPolygon(nump: integer; vecs: vec3_p);
var
  i, j,
    axis: integer;
  v, av: vec3_t;
  s, t, dv: Single;
  vp: vec3_p;
label
  continue_;
begin
  Inc(c_sky);

(*
glBegin (GL_POLYGON);
for (i=0 ; i<nump ; i++, vecs+=3)
{
 VectorAdd(vecs, r_origin, v);
 qglVertex3fv (v);
}
glEnd();
return;
*)

  // decide which face it maps to
  VectorCopy(vec3_origin, v);
  vp := vecs;
  for i := 0 to nump - 1 do
  begin
    VectorAdd(vp^, v, v);
    Inc(vp);
  end;

  av[0] := abs(v[0]);
  av[1] := abs(v[1]);
  av[2] := abs(v[2]);
  if (av[0] > av[1]) and (av[0] > av[2]) then
  begin
    if (v[0] < 0) then
      axis := 1
    else
      axis := 0
  end
  else
  begin
    if (av[1] > av[2]) and (av[1] > av[0]) then
    begin
      if (v[1] < 0) then
        axis := 3
      else
        axis := 2
    end
    else
    begin
      if (v[2] < 0) then
        axis := 5
      else
        axis := 4;
    end;
  end;
  // project new texture coords
  for i := 0 to nump - 1 do
  begin
    j := vec_to_st[axis][2];
    if (j > 0) then
      dv := vecs[j - 1]
    else
      dv := -vecs[-j - 1];
    if (dv < 0.001) then
      goto continue_; // don't divide by zero
    j := vec_to_st[axis][0];
    if (j < 0) then
      s := -vecs[-j - 1] / dv
    else
      s := vecs[j - 1] / dv;
    j := vec_to_st[axis][1];
    if (j < 0) then
      t := -vecs[-j - 1] / dv
    else
      t := vecs[j - 1] / dv;

    if (s < skymins[0][axis]) then
      skymins[0][axis] := s;
    if (t < skymins[1][axis]) then
      skymins[1][axis] := t;
    if (s > skymaxs[0][axis]) then
      skymaxs[0][axis] := s;
    if (t > skymaxs[1][axis]) then
      skymaxs[1][axis] := t;

    continue_:
    inc(vecs);
  end;
end; //procedure

const
  ON_EPSILON = 0.1; // point on plane side epsilon
  MAX_CLIP_VERTS = 64;

procedure ClipSkyPolygon(nump: integer; vecs: vec3_p; stage: integer);
var
  norm: vec3_p;
  v: vec3_p;
  front, back: qboolean;
  d, e: Single;
  dists: array[0..MAX_CLIP_VERTS - 1] of Single;
  sides: array[0..MAX_CLIP_VERTS - 1] of integer;
  newv: array[0..1, 0..MAX_CLIP_VERTS - 1] of vec3_t;
  newc: array[0..1] of integer;
  i, j: integer;
label
  continue_;
begin
  if (nump > MAX_CLIP_VERTS - 2) then
    ri.Sys_Error(ERR_DROP, 'ClipSkyPolygon: MAX_CLIP_VERTS', []);
  if (stage = 6) then
  begin
    // fully clipped, so draw it
    DrawSkyPolygon(nump, vecs);
    Exit;
  end;

  front := false;
  back := false;
  norm := @skyclip[stage];
  v := vecs;
  i := 0;
  while (i<nump) do
  begin
    d := DotProduct(v^, norm^);
    if (d > ON_EPSILON) then
    begin
      front := true;
      sides[i] := SIDE_FRONT;
    end
    else
      if (d < -ON_EPSILON) then
      begin
        back := true;
        sides[i] := SIDE_BACK;
      end
      else
        sides[i] := SIDE_ON;
    dists[i] := d;

    inc(i);
    Inc(v);
  end;

  if (not front) or (not back) then
  begin
    // not clipped
    ClipSkyPolygon(nump, vecs, stage + 1);
    Exit;
  end;

  // clip it
  sides[i] := sides[0];
  dists[i] := dists[0];
  VectorCopy(vecs^, vec3_p(Pointer(Cardinal(vecs)+i*3*sizeof(Single)))^);


  newc[1] := 0;
  newc[0] := 0;

  v := vecs;
  for i := 0 to nump - 1 do
  begin
    case (sides[i]) of
      SIDE_FRONT:
        begin
          VectorCopy(v^, newv[0][newc[0]]);
          Inc(newc[0]);
        end;
      SIDE_BACK:
        begin
          VectorCopy(v^, newv[1][newc[1]]);
          Inc(newc[1]);
        end;
      SIDE_ON:
        begin
          VectorCopy(v^, newv[0][newc[0]]);
          Inc(newc[0]);
          VectorCopy(v^, newv[1][newc[1]]);
          Inc(newc[1]);
        end;
    end; //case

    if (sides[i] = SIDE_ON) or (sides[i + 1] = SIDE_ON) or (sides[i + 1] = sides[i]) then
      goto continue_;

    d := dists[i] / (dists[i] - dists[i + 1]);
    for j := 0 to 2 do
    begin
      e := v[j] + d * (v[j + 3] - v[j]);
      newv[0][newc[0]][j] := e;
      newv[1][newc[1]][j] := e;
    end;
    Inc(newc[0]);
    Inc(newc[1]);

    continue_:
    Inc(v);
  end;

  // continue
  ClipSkyPolygon(newc[0], @newv[0][0], stage + 1);
  ClipSkyPolygon(newc[1], @newv[1][0], stage + 1);
end; //procedure

{*
=================
R_AddSkySurface
=================
*}

procedure R_AddSkySurface(fa: msurface_p);
var
  i: integer;
  verts: array[0..MAX_CLIP_VERTS - 1] of vec3_t;
  p: glpoly_p;
begin
  // calculate vertex values for sky box
  p := fa.polys;
  while p <> nil do
  begin
    for i := 0 to p.numverts - 1 do
      VectorSubtract(vec3_p(@p^.verts[i])^, r_origin, verts[i]);
    ClipSkyPolygon(p^.numverts, @verts[0], 0);
    p := p.next;
  end;
end; //procedure

{*
==============
R_ClearSkyBox
==============
*}

procedure R_ClearSkyBox;
var
  i: integer;
begin
  for i := 0 to 5 do
  begin
    skymins[0][i] := 9999;
    skymins[1][i] := 9999;
    skymaxs[0][i] := -9999;
    skymaxs[1][i] := -9999;
  end;
end; //procedure

procedure MakeSkyVec(s, t: Single; axis: integer);
var
  v, b: vec3_t;
  j, k: integer;
begin
  b[0] := s * 2300;
  b[1] := t * 2300;
  b[2] := 2300;

  for j := 0 to 2 do
  begin
    k := st_to_vec[axis][j];
    if (k < 0) then
      v[j] := -b[-k - 1]
    else
      v[j] := b[k - 1];
  end;

  // avoid bilerp seam
  s := (s + 1) * 0.5;
  t := (t + 1) * 0.5;

  if (s < sky_min) then
    s := sky_min
  else
    if (s > sky_max) then
      s := sky_max;

  if (t < sky_min) then
    t := sky_min
  else
    if (t > sky_max) then
      t := sky_max;

  t := 1.0 - t;
  qglTexCoord2f(s, t);
  qglVertex3fv(@v);
end; //procedure

{*
==============
R_DrawSkyBox
==============
*}
const
  skytexorder: array[0..5] of integer = (0, 2, 1, 3, 4, 5);

procedure R_DrawSkyBox;
var
  i: integer;
begin
(*#if 0
qglEnable (GL_BLEND);
GL_TexEnv( GL_MODULATE );
qglColor4f (1,1,1,0.5);
qglDisable (GL_DEPTH_TEST);
#endif*)

  if (skyrotate <> 0) then
  begin
    // check for no sky at all
    i := 0;
    while (i<6) do
    begin
      if (skymins[0][i] < skymaxs[0][i]) and (skymins[1][i] < skymaxs[1][i]) then
        Break;
      Inc(i);
    end;
    if (i = 6) then
      Exit; // nothing visible
  end;

  qglPushMatrix();
  qglTranslatef(r_origin[0], r_origin[1], r_origin[2]);
  qglRotatef(r_newrefdef.time * skyrotate, skyaxis[0], skyaxis[1], skyaxis[2]);

  for i := 0 to 5 do
  begin
    if (skyrotate <> 0) then
    begin
        // hack, forces full sky to draw when rotating
      skymins[0][i] := -1;
      skymins[1][i] := -1;
      skymaxs[0][i] := 1;
      skymaxs[1][i] := 1;
    end;

    if (skymins[0][i] >= skymaxs[0][i]) or (skymins[1][i] >= skymaxs[1][i]) then
      Continue;

    GL_Bind(sky_images[skytexorder[i]].texnum);

    qglBegin(GL_QUADS);
    MakeSkyVec(skymins[0][i], skymins[1][i], i);
    MakeSkyVec(skymins[0][i], skymaxs[1][i], i);
    MakeSkyVec(skymaxs[0][i], skymaxs[1][i], i);
    MakeSkyVec(skymaxs[0][i], skymins[1][i], i);
    qglEnd();
  end; //for i
  qglPopMatrix();

(*#if 0
glDisable (GL_BLEND);
glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
glColor4f (1,1,1,0.5);
glEnable (GL_DEPTH_TEST);
#endif*)
end; //procedure

{*
============
R_SetSky
============
*}
const
// 3dstudio environment map names
  suf: array[0..5] of PChar = ('rt', 'bk', 'lf', 'ft', 'up', 'dn');

procedure R_SetSky(name: PChar; rotate: Single; axis: vec3_p); cdecl; //for gl_rmain
var
  i: integer;
  pathname: array[0..MAX_QPATH-1] of char;
begin
  strncpy(skyname, name, sizeof(skyname) - 1);
  skyrotate := rotate;
  VectorCopy(axis^, skyaxis);

  for i := 0 to 5 do
  begin
    // chop down rotating skies for less memory
    if (gl_skymip.value <> 0) or (skyrotate <> 0) then
      gl_picmip.value := gl_picmip.value + 1;

    if Assigned(qglColorTableEXT) and (gl_ext_palettedtexture.value <> 0) then
      Com_sprintf(pathname, sizeof(pathname), 'env/%s%s.pcx', [skyname, suf[i]])
    else
      Com_sprintf(pathname, sizeof(pathname), 'env/%s%s.tga', [skyname, suf[i]]);

    sky_images[i] := GL_FindImage(pathname, it_sky);
    if (sky_images[i] = nil) then
      sky_images[i] := r_notexture;

    if (gl_skymip.value <> 0) or (skyrotate <> 0) then
    begin
      // take less memory
      gl_picmip.value := gl_picmip.value - 1;
      sky_min := 1.0 / 256;
      sky_max := 255.0 / 256;
    end
    else
    begin
      sky_min := 1.0 / 512;
      sky_max := 511.0 / 512;
    end;
  end; //for i
end; //procedure

// End of file
end.


