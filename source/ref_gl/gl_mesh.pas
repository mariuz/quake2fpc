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
{ File(s): gl_mesh.c                                                         }
{                                                                            }
{ Initial conversion by : softland                                           }
{ Initial conversion on : 14-Jan-2002                                        }
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
{ * Updated                                                                  }
{     16-Jun-2002 by Magog (magog@fistofbenztown.de)                         }
{     Added missing functions                                                }
{     30-Lug-2002 by Fabrizio Rossini (rossini.f@libero.it)                  }
{     added code convertion ( NOT 100% )                                     }
{----------------------------------------------------------------------------}
{ 28.06.2003 Juha: Proofreaded}
unit gl_mesh;

interface

uses
  DelphiTypes,
  q_shared,
  qfiles,
  gl_image,
  ref;

procedure R_DrawAliasModel(e: entity_p);


const
  NUMVERTEXNORMALS = 162;
  r_avertexnormals: array[0..NUMVERTEXNORMALS - 1, 0..2] of Single = (
{$I 'anorms.inc'}
    );

  // Precalculated dot products for quantized angles.
  SHADEDOT_QUANT = 16;
  r_avertexnormal_dots: array[0..SHADEDOT_QUANT - 1, 0..255] of Single = (
{$I 'anormtab.inc'}
    );

var
  shadedots: PSingleArray = @r_avertexnormal_dots;

type
  vec4_t = array[0..3] of Single;

var
  s_lerped: array[0..MAX_VERTS - 1] of vec4_t;
  shadevector: vec3_t;
  shadelight: array[0..2] of Single;

implementation

uses
  CPas,
  sysutils,
  OpenGL,
  gl_local,
  gl_light,
  gl_rmain,
  qgl_win,
  qgl_h;


procedure GL_LerpVerts(nverts: Integer; v, ov: dtrivertx_p; verts: dtrivertx_a;
  lerp: vec3_p; move, frontv, backv: vec3_t);
var
  i: Integer;
  normal: vec3_p;
begin
  //PMM -- added RF_SHELL_DOUBLE, RF_SHELL_HALF_DAM
  if (currententity^.flags and (RF_SHELL_RED or RF_SHELL_GREEN or RF_SHELL_BLUE or RF_SHELL_DOUBLE or RF_SHELL_HALF_DAM)) <> 0 then
  begin
    i := 0;
    while i < nverts do
    begin
      normal := @r_avertexnormals[verts[i].lightnormalindex];
      lerp[0] := move[0] + ov.v[0] * backv[0] + v.v[0] * frontv[0] + normal[0] * POWERSUIT_SCALE;
      lerp[1] := move[1] + ov.v[1] * backv[1] + v.v[1] * frontv[1] + normal[1] * POWERSUIT_SCALE;
      lerp[2] := move[2] + ov.v[2] * backv[2] + v.v[2] * frontv[2] + normal[2] * POWERSUIT_SCALE;
      Inc(i);
      Inc(v);
      Inc(ov);
      lerp := Pointer(Cardinal(lerp) + 4 * sizeof(Single));
    end;
  end
  else
  begin
    i := 0;
    while i < nverts do
    begin
      lerp[0] := move[0] + ov.v[0] * backv[0] + v.v[0] * frontv[0];
      lerp[1] := move[1] + ov.v[1] * backv[1] + v.v[1] * frontv[1];
      lerp[2] := move[2] + ov.v[2] * backv[2] + v.v[2] * frontv[2];
      Inc(i);
      Inc(v);
      Inc(ov);
      lerp := Pointer(Cardinal(lerp) + 4 * sizeof(Single));
    end;
  end;
end;

{
=============
GL_DrawAliasFrameLerp

interpolates between two frames and origins
FIXME: batch lerp all vertexes
=============
}

procedure GL_DrawAliasFrameLerp(
  paliashdr: dmdl_p;
  backlerp: Single);
var
  l: Single;
  frame, oldframe: daliasframe_p;
  v, ov, verts: dtrivertx_a;
  order: PInteger;
  count: Integer;
  frontlerp: Single;
  alpha: Single;
  move, delta: vec3_t;
  vectors: array[0..2] of vec3_t;
  frontv, backv: vec3_t;
  i: integer;
  index_xyz: integer;
  lerp: vec3_p;
  colorArray: array[0..MAX_VERTS * 4 - 1] of Single;
begin
  frame := @PByteArray(paliashdr)[paliashdr.ofs_frames + currententity.frame * paliashdr.framesize];
  verts := @frame.verts;
  v := @frame.verts;

  oldframe := @PByteArray(paliashdr)[paliashdr.ofs_frames + currententity.oldframe * paliashdr.framesize];
  ov := @oldframe.verts;

  order := @PByteArray(paliashdr)[paliashdr.ofs_glcmds];

//  glTranslatef (frame->translate[0], frame->translate[1], frame->translate[2]);
//  glScalef (frame->scale[0], frame->scale[1], frame->scale[2]);

  if (currententity^.flags and RF_TRANSLUCENT <> 0) then
    alpha := currententity^.alpha
  else
    alpha := 1.0;

  // PMM - added double shell
  if (currententity^.flags and (RF_SHELL_RED or RF_SHELL_GREEN or RF_SHELL_BLUE or RF_SHELL_DOUBLE or RF_SHELL_HALF_DAM) <> 0) then
    qglDisable(GL_TEXTURE_2D);

  frontlerp := 1.0 - backlerp;

  // move should be the delta back to the previous frame * backlerp
  VectorSubtract(vec3_t(currententity^.oldorigin), vec3_t(currententity^.origin), delta);
  AngleVectors(vec3_t(currententity^.angles), @vectors[0], @vectors[1], @vectors[2]);

  move[0] := DotProduct(delta, vectors[0]); // forward
  move[1] := -DotProduct(delta, vectors[1]); // left
  move[2] := DotProduct(delta, vectors[2]); // up

  VectorAdd(move, oldframe^.translate, move);

  for i := 0 to 2 do
    move[i] := backlerp * move[i] + frontlerp * frame^.translate[i];

  for i := 0 to 2 do
  begin
    frontv[i] := frontlerp * frame^.scale[i];
    backv[i] := backlerp * oldframe^.scale[i];
  end;

  lerp := @s_lerped[0];

  GL_LerpVerts(paliashdr^.num_xyz, @v[0], @ov[0], verts, lerp, move, frontv, backv);

  if (gl_vertex_arrays^.value <> 0) then
  begin
    qglEnableClientState(GL_VERTEX_ARRAY);
    qglVertexPointer(3, GL_FLOAT, 16, @s_lerped); // padded for SIMD

//    if ( currententity->flags & ( RF_SHELL_RED | RF_SHELL_GREEN | RF_SHELL_BLUE ) )
    // PMM - added double damage shell
    if (currententity.flags and (RF_SHELL_RED or RF_SHELL_GREEN or RF_SHELL_BLUE or RF_SHELL_DOUBLE or RF_SHELL_HALF_DAM) <> 0) then
      qglColor4f(shadelight[0], shadelight[1], shadelight[2], alpha)
    else
    begin
      qglEnableClientState(GL_COLOR_ARRAY);
      qglColorPointer(3, GL_FLOAT, 0, @colorArray);

      //
      // pre light everything
      //
      for i := 0 to paliashdr^.num_xyz - 1 do
      begin
        l := shadedots[verts[i].lightnormalindex];

        colorArray[i * 3 + 0] := l * shadelight[0];
        colorArray[i * 3 + 1] := l * shadelight[1];
        colorArray[i * 3 + 2] := l * shadelight[2];
      end;
    end;

    if Assigned(qglLockArraysEXT) then
      qglLockArraysEXT(0, paliashdr^.num_xyz);

    while true do
    begin
      // get the vertex count and primitive type
      count := order^;
      inc(order);
      if (count = 0) then
        break; // done

      if (count < 0) then
      begin
        count := -count;
        qglBegin(GL_TRIANGLE_FAN);
      end
      else
      begin
        qglBegin(GL_TRIANGLE_STRIP);
      end;

      // PMM - added double damage shell
      if (currententity^.flags and (RF_SHELL_RED or RF_SHELL_GREEN or RF_SHELL_BLUE or RF_SHELL_DOUBLE or RF_SHELL_HALF_DAM) <> 0) then
      begin
        repeat
          index_xyz := PIntegerArray(order)[2];
          inc(order, 3);
          qglVertex3fv(@s_lerped[index_xyz]);
          dec(count);
        until (count = 0);
      end
      else
      begin
        repeat
          // texture coordinates come from the draw list
          qglTexCoord2f(PSingleArray(order)[0], PSingleArray(order)[1]);
          index_xyz := PIntegerArray(order)[2];

          inc(order, 3);
          // normals and vertexes come from the frame list
          // l = shadedots[verts[index_xyz].lightnormalindex];
          // qglColor4f (l* shadelight[0], l*shadelight[1], l*shadelight[2], alpha);
          qglArrayElement(index_xyz);
          dec(count);
        until (count = 0);
      end;
      qglEnd;
    end;

    if Assigned(qglUnlockArraysEXT) then
      qglUnlockArraysEXT;
  end
  else
  begin
    while true do
    begin
      // get the vertex count and primitive type
      count := order^;
      inc(order);
      if (count = 0) then
        break; // done

      if (count < 0) then
      begin
        count := -count;
        qglBegin(GL_TRIANGLE_FAN);
      end
      else
      begin
        qglBegin(GL_TRIANGLE_STRIP);
      end;

      if (currententity^.flags and (RF_SHELL_RED or RF_SHELL_GREEN or RF_SHELL_BLUE) <> 0) then
      begin
        repeat
          index_xyz := PIntegerArray(order)[2];
          inc(order, 3);

          qglColor4f(shadelight[0], shadelight[1], shadelight[2], alpha);
          qglVertex3fv(@s_lerped[index_xyz]);
          dec(count);
        until (count = 0);
      end
      else
      begin
        repeat
          // texture coordinates come from the draw list
          qglTexCoord2f(PSingleArray(order)[0], PSingleArray(order)[1]);
          index_xyz := PIntegerArray(order)[2];
          inc(order, 3);

          // normals and vertexes come from the frame list
          l := shadedots[verts[index_xyz].lightnormalindex];

          qglColor4f(l * shadelight[0], l * shadelight[1], l * shadelight[2], alpha);
          qglVertex3fv(@s_lerped[index_xyz]);
          dec(count);
        until (count = 0);
      end;
      qglEnd;
    end;
  end;

// if ( currententity->flags & ( RF_SHELL_RED | RF_SHELL_GREEN | RF_SHELL_BLUE ) )
  // PMM - added double damage shell
  if (currententity^.flags and (RF_SHELL_RED or RF_SHELL_GREEN or RF_SHELL_BLUE or RF_SHELL_DOUBLE or RF_SHELL_HALF_DAM) <> 0) then
    qglEnable(GL_TEXTURE_2D);
end;


(*
=============
GL_DrawAliasShadow
=============
*)
procedure GL_DrawAliasShadow(paliashdr: dmdl_p; posenum: integer);
var
  verts: dtrivertx_p;
  order: pInteger;
  point: vec3_t;
  height, lheight: Single;
  count: integer;
  frame: daliasframe_p;
begin
  lheight := currententity^.origin[2] - lightspot[2];
  frame := Pointer(Cardinal(paliashdr) + paliashdr^.ofs_frames + currententity^.frame * paliashdr^.framesize);
  verts := @frame.verts;

  height := 0;

  order := Pointer(Cardinal(paliashdr) + paliashdr.ofs_glcmds);

  height := -lheight + 1.0;

  while true do
  begin
      // get the vertex count and primitive type
    count := order^;
    inc(order);
    if (count = 0) then
      break; // done

    if (count < 0) then
    begin
      count := -count;
      qglBegin(GL_TRIANGLE_FAN);
    end
    else
      qglBegin(GL_TRIANGLE_STRIP);

    //do
    repeat
      // normals and vertexes come from the frame list
(*
      point[0] = verts[order[2]].v[0] * frame->scale[0] + frame->translate[0];
      point[1] = verts[order[2]].v[1] * frame->scale[1] + frame->translate[1];
      point[2] = verts[order[2]].v[2] * frame->scale[2] + frame->translate[2];
*)

      memcpy(@point, @s_lerped[PIntegerArray(order)^[2]], sizeof(point));

      point[0] := point[0] - shadevector[0] * (point[2] + lheight);
      point[1] := point[1] - shadevector[1] * (point[2] + lheight);
      point[2] := height;
      // commented by ID soft         height -= 0.001;
      qglVertex3fv(@point);

      inc(order, 3);

      //   commented by ID soft      verts++;

      dec(count);
    until (count = 0);
    qglEnd;
  end;
end;


(*
** R_CullAliasModel
*)
function R_CullAliasModel(var bbox: array of vec3_t; e: entity_p): qboolean;
var
  i: integer;
  mins, maxs, tmp: vec3_t;
  paliashdr: dmdl_p;
  vectors: array[0..2] of vec3_t;
  thismins, oldmins, thismaxs, oldmaxs, angles: vec3_t;
  pframe, poldframe: daliasframe_p;
  p, f: Integer;
  aggregatemask: Integer;
  mask: integer;
  dp: Single;
begin
  paliashdr := currentmodel^.extradata;

  if ((e^.frame >= paliashdr^.num_frames) or (e^.frame < 0)) then
  begin
    ri.Con_Printf(PRINT_ALL, 'R_CullAliasModel %s: no such frame %d'#10,
      currentmodel^.name, e^.frame);
    e^.frame := 0;
  end;
  if ((e^.oldframe >= paliashdr^.num_frames) or (e^.oldframe < 0)) then
  begin
    ri.Con_Printf(PRINT_ALL, 'R_CullAliasModel %s: no such oldframe %d'#10,
      currentmodel^.name, e^.oldframe);
    e^.oldframe := 0;
  end;

  pframe := Pointer(Cardinal(paliashdr) + paliashdr^.ofs_frames + e^.frame * paliashdr^.framesize);

  poldframe := Pointer(Cardinal(paliashdr) + paliashdr^.ofs_frames + e^.oldframe * paliashdr^.framesize);

 (*
 ** compute axially aligned mins and maxs
 *)
  if (pframe = poldframe) then
  begin
    for i := 0 to 3 - 1 do
    begin
      mins[i] := pframe^.translate[i];
      maxs[i] := mins[i] + pframe^.scale[i] * 255;
    end;
  end
  else

    for i := 0 to 3 - 1 do
    begin
      thismins[i] := pframe^.translate[i];
      thismaxs[i] := thismins[i] + pframe^.scale[i] * 255;

      oldmins[i] := poldframe.translate[i];
      oldmaxs[i] := oldmins[i] + poldframe^.scale[i] * 255;

      if (thismins[i] < oldmins[i]) then
        mins[i] := thismins[i]
      else
        mins[i] := oldmins[i];

      if (thismaxs[i] > oldmaxs[i]) then
        maxs[i] := thismaxs[i]
      else
        maxs[i] := oldmaxs[i];
    end;


 (*
 ** compute a full bounding box
 *)
  for i := 0 to 7 do
  begin
    if (i and 1 <> 0) then
      tmp[0] := mins[0]
    else
      tmp[0] := maxs[0];

    if (i and 2 <> 0) then
      tmp[1] := mins[1]
    else
      tmp[1] := maxs[1];

    if (i and 4 <> 0) then
      tmp[2] := mins[2]
    else
      tmp[2] := maxs[2];

    VectorCopy(tmp, bbox[i]);
  end;

 (*
 ** rotate the bounding box
 *)
  VectorCopy(vec3_t(e^.angles), angles);
  angles[YAW] := -angles[YAW];
  AngleVectors(angles, @vectors[0], @vectors[1], @vectors[2]);

  for i := 0 to 7 do
  begin
    VectorCopy(bbox[i], tmp);

    bbox[i][0] := DotProduct(vectors[0], tmp);
    bbox[i][1] := -DotProduct(vectors[1], tmp);
    bbox[i][2] := DotProduct(vectors[2], tmp);

    VectorAdd(vec3_t(e^.origin), bbox[i], bbox[i]);
  end;


  aggregatemask := not 0;

  for p := 0 to 7 do
  begin
    mask := 0;

    for f := 0 to 3 do
    begin
      dp := DotProduct(frustum[f].normal, bbox[p]);

      if ((dp - frustum[f].dist) < 0) then
        mask := mask or (1 shl f);
    end;

    aggregatemask := aggregatemask and mask;
  end;

  if (aggregatemask <> 0) then
  begin
    result := true;
    exit;
  end;
  result := false;
end;


(*
=================
R_DrawAliasModel

=================
*)
procedure R_DrawAliasModel(e: entity_p);
var
  i: integer;
  paliashdr: dmdl_p;
  an, s, scale, min: Single;
  bbox: array[0..7] of vec3_t;
  skin: image_p;
begin
  if (e^.flags and RF_WEAPONMODEL = 0) then
  begin
    if (R_CullAliasModel(bbox, e)) then
      exit; //return;
  end;

  if (e^.flags and RF_WEAPONMODEL <> 0) then
  begin
    if (r_lefthand^.value = 2) then
      exit;
  end;

  paliashdr := currentmodel^.extradata;

 //
 // get lighting information
 //
 // PMM - rewrote, reordered to handle new shells & mixing
 // PMM - 3.20 code .. replaced with original way of doing it to keep mod authors happy
 //
  if (currententity.flags and (RF_SHELL_HALF_DAM or RF_SHELL_GREEN or RF_SHELL_RED or RF_SHELL_BLUE or RF_SHELL_DOUBLE) <> 0) then
  begin
    VectorClear(vec3_t(shadelight));
    if (currententity^.flags and RF_SHELL_HALF_DAM <> 0) then
    begin
      shadelight[0] := 0.56;
      shadelight[1] := 0.59;
      shadelight[2] := 0.45;
    end;
    if (currententity^.flags and RF_SHELL_DOUBLE <> 0) then
    begin
      shadelight[0] := 0.9;
      shadelight[1] := 0.7;
    end;
    if (currententity.flags and RF_SHELL_RED <> 0) then
      shadelight[0] := 1.0;
    if (currententity.flags and RF_SHELL_GREEN <> 0) then
      shadelight[1] := 1.0;
    if (currententity.flags and RF_SHELL_BLUE <> 0) then
      shadelight[2] := 1.0;
  end
(*
  // PMM -special case for godmode
  if ( (currententity->flags & RF_SHELL_RED) &&
   (currententity->flags & RF_SHELL_BLUE) &&
   (currententity->flags & RF_SHELL_GREEN) )
  {
   for (i=0 ; i<3 ; i++)
    shadelight[i] = 1.0;
  }
  else if ( currententity->flags & ( RF_SHELL_RED | RF_SHELL_BLUE | RF_SHELL_DOUBLE ) )
  {
   VectorClear (shadelight);

   if ( currententity->flags & RF_SHELL_RED )
   {
    shadelight[0] = 1.0;
    if (currententity->flags & (RF_SHELL_BLUE|RF_SHELL_DOUBLE) )
     shadelight[2] = 1.0;
   }
   else if ( currententity->flags & RF_SHELL_BLUE )
   {
    if ( currententity->flags & RF_SHELL_DOUBLE )
    {
     shadelight[1] = 1.0;
     shadelight[2] = 1.0;
    }
    else
    {
     shadelight[2] = 1.0;
    }
   }
   else if ( currententity->flags & RF_SHELL_DOUBLE )
   {
    shadelight[0] = 0.9;
    shadelight[1] = 0.7;
   }
  }
  else if ( currententity->flags & ( RF_SHELL_HALF_DAM | RF_SHELL_GREEN ) )
  {
   VectorClear (shadelight);
   // PMM - new colors
   if ( currententity->flags & RF_SHELL_HALF_DAM )
   {
    shadelight[0] = 0.56;
    shadelight[1] = 0.59;
    shadelight[2] = 0.45;
   }
   if ( currententity->flags & RF_SHELL_GREEN )
   {
    shadelight[1] = 1.0;
   }
  }
 }
   //PMM - ok, now flatten these down to range from 0 to 1.0.
 //      max_shell_val = max(shadelight[0], max(shadelight[1], shadelight[2]));
 //      if (max_shell_val > 0)
 //      {
 //         for (i=0; i<3; i++)
 //         {
 //            shadelight[i] = shadelight[i] / max_shell_val;
 //         }
 //      }
 // pmm
*)
  else
    if (currententity.flags and RF_FULLBRIGHT <> 0) then
    begin
      for i := 0 to 2 do
      begin
        shadelight[i] := 1.0;
      end;
    end
    else
    begin
      R_LightPoint(vec3_t(currententity^.origin), vec3_t(shadelight));

      // player lighting hack for communication back to server
      // big hack!
      if (currententity^.flags and RF_WEAPONMODEL <> 0) then
      begin
        // pick the greatest component, which should be the same
        // as the mono value returned by software
        if (shadelight[0] > shadelight[1]) then
        begin
          if (shadelight[0] > shadelight[2]) then
            r_lightlevel^.value := 150 * shadelight[0]
          else
            r_lightlevel^.value := 150 * shadelight[2];
        end
        else
        begin
          if (shadelight[1] > shadelight[2]) then
            r_lightlevel^.value := 150 * shadelight[1]
          else
            r_lightlevel^.value := 150 * shadelight[2];
        end;

      end;

      if (gl_monolightmap^.string_[0] <> '0') then
      begin
        s := shadelight[0];

        if (s < shadelight[1]) then
          s := shadelight[1];
        if (s < shadelight[2]) then
          s := shadelight[2];

        shadelight[0] := s;
        shadelight[1] := s;
        shadelight[2] := s;
      end;
    end;

  if (currententity^.flags and RF_MINLIGHT <> 0) then
  begin
    i := 0;
    while (i < 3) do
    begin
      if (shadelight[i] > 0.1) then
        break;
      inc(i);
    end;
    if (i = 3) then
    begin
      shadelight[0] := 0.1;
      shadelight[1] := 0.1;
      shadelight[2] := 0.1;
    end;
  end;

  if (currententity^.flags and RF_GLOW <> 0) then
  // bonus items will pulse with time
  begin
    scale := 0.1 * sin(r_newrefdef.time * 7);
    for i := 0 to 2 do
    begin
      min := shadelight[i] * 0.8;
      shadelight[i] := shadelight[i] + scale;
      if (shadelight[i] < min) then
        shadelight[i] := min;
    end;
  end;

// =================
// PGM   ir goggles color override
  if (r_newrefdef.rdflags and RDF_IRGOGGLES <> 0) and (currententity^.flags and RF_IR_VISIBLE <> 0) then
  begin
    shadelight[0] := 1.0;
    shadelight[1] := 0.0;
    shadelight[2] := 0.0;
  end;
// PGM
// =================

  shadedots := @r_avertexnormal_dots[Trunc(currententity^.angles[1] * (SHADEDOT_QUANT / 360.0)) and (SHADEDOT_QUANT - 1)];
  an := currententity^.angles[1] / 180 * M_PI;
  shadevector[0] := cos(-an);
  shadevector[1] := sin(-an);
  shadevector[2] := 1;
  VectorNormalize(shadevector);

 //
 // locate the proper data
 //

  c_alias_polys := c_alias_polys + paliashdr^.num_tris;

 //
 // draw all the triangles
 //
  if (currententity^.flags and RF_DEPTHHACK <> 0) then // hack the depth range to prevent view model from poking into walls
    qglDepthRange(gldepthmin, gldepthmin + 0.3 * (gldepthmax - gldepthmin));

  if ((currententity^.flags and RF_WEAPONMODEL <> 0) and (r_lefthand^.value = 1.0)) then
  begin
    qglMatrixMode(GL_PROJECTION);
    qglPushMatrix();
    qglLoadIdentity();
    qglScalef(-1, 1, 1);
    MYgluPerspective(r_newrefdef.fov_y, r_newrefdef.width / r_newrefdef.height, 4, 4096);
    qglMatrixMode(GL_MODELVIEW);

    qglCullFace(GL_BACK);
  end;

  qglPushMatrix();
  e^.angles[PITCH] := -e^.angles[PITCH]; // sigh.
  R_RotateForEntity(e);
  e^.angles[PITCH] := -e^.angles[PITCH]; // sigh.

 // select skin
  if assigned(currententity^.skin) then
    skin := currententity^.skin // custom player skin
  else
  begin
    if (currententity^.skinnum >= MAX_MD2SKINS) then
      skin := currentmodel^.skins[0]
    else
    begin
      skin := currentmodel^.skins[currententity^.skinnum];
      if (skin = nil) then
        skin := currentmodel^.skins[0];
    end;
  end;
  if (skin = nil) then
    skin := r_notexture; // fallback...
  GL_Bind(skin^.texnum);

 // draw it

  qglShadeModel(GL_SMOOTH);

  GL_TexEnv(GL_MODULATE);
  if (currententity^.flags and RF_TRANSLUCENT <> 0) then

    qglEnable(GL_BLEND);



  if ((currententity^.frame >= paliashdr^.num_frames) or (currententity^.frame < 0)) then
  begin
    ri.Con_Printf(PRINT_ALL, 'R_DrawAliasModel %s: no such frame %d'#10,
      currentmodel^.name, currententity^.frame);
    currententity^.frame := 0;
    currententity^.oldframe := 0;
  end;

  if ((currententity^.oldframe >= paliashdr^.num_frames) or (currententity^.oldframe < 0)) then
  begin
    ri.Con_Printf(PRINT_ALL, 'R_DrawAliasModel %s: no such oldframe %d'#10,
      currentmodel^.name, currententity^.oldframe);
    currententity^.frame := 0;
    currententity^.oldframe := 0;
  end;

  if (r_lerpmodels^.value = 0) then
    currententity^.backlerp := 0;
  GL_DrawAliasFrameLerp(paliashdr, currententity^.backlerp);

  GL_TexEnv(GL_REPLACE);
  qglShadeModel(GL_FLAT);

  qglPopMatrix();

(*
 qglDisable( GL_CULL_FACE );
 qglPolygonMode( GL_FRONT_AND_BACK, GL_LINE );
 qglDisable( GL_TEXTURE_2D );
 qglBegin( GL_TRIANGLE_STRIP );
 for  i := 0 to 8 do
 begin
  qglVertex3fv( bbox[i] );
 end;
 qglEnd();
 qglEnable( GL_TEXTURE_2D );
 qglPolygonMode( GL_FRONT_AND_BACK, GL_FILL );
 qglEnable( GL_CULL_FACE );
*)

  if ((currententity^.flags and RF_WEAPONMODEL <> 0) and (r_lefthand^.value = 1.0)) then
  begin
    qglMatrixMode(GL_PROJECTION);
    qglPopMatrix();
    qglMatrixMode(GL_MODELVIEW);
    qglCullFace(GL_FRONT);
  end;

  if (currententity^.flags and RF_TRANSLUCENT <> 0) then

    qglDisable(GL_BLEND);


  if (currententity^.flags and RF_DEPTHHACK <> 0) then
    qglDepthRange(gldepthmin, gldepthmax);

  if (gl_shadows^.value <> 0) and (currententity^.flags and (RF_TRANSLUCENT or RF_WEAPONMODEL) = 0) then
  begin
    qglPushMatrix();
    R_RotateForEntity(e);
    qglDisable(GL_TEXTURE_2D);
    qglEnable(GL_BLEND);
    qglColor4f(0, 0, 0, 0.5);
    GL_DrawAliasShadow(paliashdr, currententity^.frame);
    qglEnable(GL_TEXTURE_2D);
    qglDisable(GL_BLEND);
    qglPopMatrix();
  end;
  qglColor4f(1, 1, 1, 1);
end;

end.
