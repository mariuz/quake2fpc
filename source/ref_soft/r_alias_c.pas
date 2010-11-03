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
{ File(s): r_alias_c.c                                                       }
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
{ Updated on :                                                               }
{ Updated by :                                                               }
{                                                                            }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{                                                                            }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{ proofread: missing.                                                        }
{                                                                            }
{----------------------------------------------------------------------------}
(*
  - Initial translation by Diogo Teixeira (20/01/2002)
  NOTES:
    .some pointer types are named ptype_t, others type_p and some
     ^type_t, this is because they were different in the files i
     used from the delphi source and some weren't present at all.
     (this should have been discussed earlier)
    .i added a "// TRANSLATOR'S NOTE:" in every critical point in
     the translation, any "missing ->" points to a variable that
     is declared in some other file and should be linked here.
    .ALL_SET switch makes this compile using all the code
     that is hidden because of "missing ->".
    .ASM_CODE switch enables assembly code, i did not translate
     this part since it is not needed and we didn't discussed
     this previously, so the "pure c" version was translated instead.
  - Finished Initial translation in 24/01/2002
  - For any discussion about this delphi translation mail: fozi_b@yahoo.com
*)

unit r_alias_c;

interface

uses
  windows,
  qfiles,
  q_shared,
  r_local,
  r_bsp_c,
  r_model;

type // TRANSLATOR'S NOTE: added to simplify translation
  tmatrix3x4 = array[0..2, 0..3] of single;

procedure R_AliasSetUpLerpData(pmdl : dmdl_p; backlerp : single);
procedure R_AliasSetUpTransform;
procedure R_AliasTransformVector(in_ : vec3_t; var out_ : vec3_t; xf : matrix34);
//procedure R_AliasTransformVector(in_, out_ : vec3_t; xf : tmatrix3x4);
procedure R_AliasProjectAndClipTestFinalVert(fv: finalvert_p);
procedure R_AliasTransformFinalVerts(numpoints: integer; fv: finalvert_p; oldv: dtrivertx_p; newv: dtrivertx_p);

function R_AliasCheckFrameBBox(frame : daliasframe_p; worldxf : matrix34) : cardinal;
function R_AliasCheckBBox : qboolean;
procedure R_AliasPreparePoints;
procedure R_AliasSetupLighting;
procedure R_AliasSetupFrames(pmdl: dmdl_p);
procedure R_AliasDrawModel;

// TRANSLATOR'S NOTE: defined but not used???
//procedure R_AliasLerpFrames(paliashdr : dmdl_p; backlerp : single);

const
  BBOX_TRIVIAL_ACCEPT = 0;
  BBOX_MUST_CLIP_XY = 1;
  BBOX_MUST_CLIP_Z = 2;
  BBOX_TRIVIAL_REJECT = 8;

var
  r_affinetridesc: affinetridesc_t;
  r_aliasblendcolor: integer;
  r_amodels_drawn: integer;

implementation

uses
  ref,
  r_light,
  r_main,
  r_rast,
  r_aclip,
  r_polyse,
  SysUtils;



const
  LIGHT_MIN   = 5;      // lowest light value we'll allow, to avoid the
                               //  need for inner-loop light clamping
  NUMVERTEXNORMALS =   162;

type
  paedge_t = ^aedge_t;
  aedge_t = array[0..1] of integer;

(*
** use a real variable to control lerping
*)
var
  r_plightvec             : vec3_t;
// CodeFusion...The line below MUST be commented out as it is not used.
//  r_lerped                : array [0..1023] of vec3_t;
  r_lerp_frontv           : vec3_t;
  r_lerp_backv            : vec3_t;
  r_lerp_move             : vec3_t;
  r_ambientlight          : integer;
  r_shadelight            : single;
  r_thisframe             : daliasframe_p;
  r_lastframe             : daliasframe_p;
  s_pmdl                  : dmdl_p;
  aliastransform          : matrix34;
  aliasworldtransform     : matrix34;
  aliasoldworldtransform  : matrix34;
  r_avertexnormals        : array [0..NUMVERTEXNORMALS- 1] of vec3_t = ({$I anorms.inc});
  s_ziscale               : Single;
  s_alias_forward         : vec3_t;
  s_alias_right           : vec3_t;
  s_alias_up              : vec3_t;
  aedges                  : array [0..11] of aedge_t = (
                                                        (0, 1), (1, 2), (2, 3), (3, 0),
                                                        (4, 5), (5, 6), (6, 7), (7, 4),
                                                        (0, 5), (1, 4), (2, 7), (3, 6)
                                                       );


(*
================
R_ConcatTransforms
================
*)
// TRANSLATOR'S NOTE: also defined in q_shared.h
(*
procedure R_ConcatTransforms(in1: tmatrix3x4; in2: tmatrix3x4; var out_: tmatrix3x4);
begin
  out_[0][0] := in1[0][0] * in2[0][0] + in1[0][1] * in2[1][0] +
    in1[0][2] * in2[2][0];
  out_[0][1] := in1[0][0] * in2[0][1] + in1[0][1] * in2[1][1] +
    in1[0][2] * in2[2][1];
  out_[0][2] := in1[0][0] * in2[0][2] + in1[0][1] * in2[1][2] +
    in1[0][2] * in2[2][2];
  out_[0][3] := in1[0][0] * in2[0][3] + in1[0][1] * in2[1][3] +
    in1[0][2] * in2[2][3] + in1[0][3];
  out_[1][0] := in1[1][0] * in2[0][0] + in1[1][1] * in2[1][0] +
    in1[1][2] * in2[2][0];
  out_[1][1] := in1[1][0] * in2[0][1] + in1[1][1] * in2[1][1] +
    in1[1][2] * in2[2][1];
  out_[1][2] := in1[1][0] * in2[0][2] + in1[1][1] * in2[1][2] +
    in1[1][2] * in2[2][2];
  out_[1][3] := in1[1][0] * in2[0][3] + in1[1][1] * in2[1][3] +
    in1[1][2] * in2[2][3] + in1[1][3];
  out_[2][0] := in1[2][0] * in2[0][0] + in1[2][1] * in2[1][0] +
    in1[2][2] * in2[2][0];
  out_[2][1] := in1[2][0] * in2[0][1] + in1[2][1] * in2[1][1] +
    in1[2][2] * in2[2][1];
  out_[2][2] := in1[2][0] * in2[0][2] + in1[2][1] * in2[1][2] +
    in1[2][2] * in2[2][2];
  out_[2][3] := in1[2][0] * in2[0][3] + in1[2][1] * in2[1][3] +
    in1[2][2] * in2[2][3] + in1[2][3];
end;
*)
(*
================
R_AliasCheckBBox
================
*)

(*
** R_AliasCheckFrameBBox
**
** Checks a specific alias frame bounding box
*)
function R_AliasCheckFrameBBox(frame : daliasframe_p; worldxf : matrix34) : cardinal;
var
  aggregate_and_clipcode: cardinal;
  aggregate_or_clipcode: cardinal;
  zclipped: qboolean;
  zfullyclipped: qboolean;
//  minz                    : single;
  i: integer;
  mins, maxs: vec3_t;
  transformed_min: vec3_t;
  transformed_max: vec3_t;
  j: integer;
  tmp, transformed: vec3_t;
  clipcode: cardinal;
  dp: single;
begin
  aggregate_and_clipcode := Cardinal(not Cardinal(0));
  aggregate_or_clipcode := 0;
  zclipped := false;
  zfullyclipped := true;
//  minz:= 9999.0;
  clipcode := 0;

 (*
 ** get the exact frame bounding box
 *)
  for i := 0 to 2 do
  begin
    mins[i] := frame^.translate[i];
    maxs[i] := mins[i] + frame^.scale[i] * 255;
  end;

 (*
 ** transform the min and max values into view space
 *)
  R_AliasTransformVector(mins, transformed_min, aliastransform);
  R_AliasTransformVector(maxs, transformed_max, aliastransform);

  if (transformed_min[2] >= ALIAS_Z_CLIP_PLANE) then
    zfullyclipped := false;
  if (transformed_max[2] >= ALIAS_Z_CLIP_PLANE) then
    zfullyclipped := false;

  if (zfullyclipped) then
  begin
    Result := BBOX_TRIVIAL_REJECT;
    Exit;
  end;
  if (zclipped) then
  begin
    Result := (BBOX_MUST_CLIP_XY or BBOX_MUST_CLIP_Z);
    Exit;
  end;

   (*
   ** build a transformed bounding box from the given min and max
   *)
   for i:= 0 to 7 do
  begin
    clipcode := 0;
      if ((i and 1) <> 0) then
         tmp[0] := mins[0]
      else
         tmp[0] := maxs[0];

      if ((i and 2) <> 0) then
         tmp[1] := mins[1]
      else
         tmp[1] := maxs[1];

      if ((i and 4) <> 0) then
         tmp[2] := mins[2]
      else
         tmp[2] := maxs[2];

    R_AliasTransformVector(tmp, transformed, worldxf);

    for j := 0 to 3 do
    begin
         dp := DotProduct(transformed, view_clipplanes[j].normal);
      if ((dp - view_clipplanes[j].dist) < 0.0) then
        clipcode := clipcode or (1 shl j);
      end;
      aggregate_and_clipcode := aggregate_and_clipcode and clipcode;
      aggregate_or_clipcode := aggregate_or_clipcode or clipcode;
   end;

  if (aggregate_and_clipcode <> 0) then
  begin
    Result := BBOX_TRIVIAL_REJECT;
    Exit;
  end;
  if (aggregate_or_clipcode = 0) then
  begin
    Result := BBOX_TRIVIAL_ACCEPT;
    Exit;
  end;
  Result := BBOX_MUST_CLIP_XY;
end;

function R_AliasCheckBBox : qboolean;
var
  ccodes: array[0..1] of cardinal;
begin
   (*
   ** non-lerping model
   *)
   ccodes[0] := R_AliasCheckFrameBBox(r_thisframe, aliasworldtransform);
  ccodes[1] := 0;
   if (currententity^.backlerp = 0.0) then
  begin
    if (ccodes[0] = BBOX_TRIVIAL_ACCEPT) then
    begin
         Result := qboolean(BBOX_TRIVIAL_ACCEPT);
      Exit;
    end
    else
      if ((ccodes[0] and BBOX_TRIVIAL_REJECT) <> 0) then
      begin
           Result := qboolean(BBOX_TRIVIAL_REJECT);
        Exit;
      end
      else
      begin
           Result := qboolean(ccodes[0] and (not cardinal(BBOX_TRIVIAL_REJECT)));
        Exit;
      end;
  end;

  ccodes[1] := R_AliasCheckFrameBBox(r_lastframe, aliasoldworldtransform);
  if ((ccodes[0] or ccodes[1]) = BBOX_TRIVIAL_ACCEPT) then
  begin
      Result := qboolean(BBOX_TRIVIAL_ACCEPT);
    Exit;
  end
  else
    if (((ccodes[0] and ccodes[1]) and BBOX_TRIVIAL_REJECT) <> 0) then
    begin
        Result := qboolean(BBOX_TRIVIAL_REJECT);
      Exit;
    end
    else
    begin
        Result:= qboolean((ccodes[0] or ccodes[1]) and (not Cardinal(BBOX_TRIVIAL_REJECT)));
      Exit;
    end;
end;

(*
================
R_AliasTransformVector
================
*)
procedure R_AliasTransformVector(in_ : vec3_t; var out_ : vec3_t; xf : matrix34);
begin
  out_[0] := DotProduct(in_, vec3_p(@xf[0][0])^) + xf[0][3];
  out_[1] := DotProduct(in_, vec3_p(@xf[1][0])^) + xf[1][3];
  out_[2] := DotProduct(in_, vec3_p(@xf[2][0])^) + xf[2][3];
end;

(*
================
R_AliasPreparePoints

General clipped case
================
*)
type
  aliasbatchedtransformdata_t = record
    num_points: integer;
    last_verts: dtrivertx_p; // verts from the last frame
    this_verts: dtrivertx_p; // verts from this frame
    dest_verts: finalvert_p; // destination for transformed verts
  end;

var
  aliasbatchedtransformdata: aliasbatchedtransformdata_t;

procedure R_AliasPreparePoints;
(*type
  tfinalvert_t_array = array [word] of finalvert_t; // TRANSLATOR'S NOTE: added to solve pointer->array problems
  pfinalvert_t_array = ^tfinalvert_t_array;

  tdstvert_t_array = array [word] of dstvert_t; // TRANSLATOR'S NOTE: added to solve pointer->array problems
  pdstvert_t_array = ^tdstvert_t_array; *)
var
  i           : integer;
   pstverts    : dstvert_a;//pdstvert_t_array;
   ptri        : dtriangle_p;
   pfv         : array [0..2] of finalvert_p;
   finalverts  : array [0..integer(MAXALIASVERTS+((CACHE_SIZE- 1) div sizeof(finalvert_t)))+ 3- 1] of finalvert_t;
   pfinalverts : finalvert_arrp;
begin
//PGM
  iractive := 0;
  if ((r_newrefdef.rdflags and RDF_IRGOGGLES) <> 0) and ((currententity^.flags and RF_IR_VISIBLE) <> 0) then
    iractive := 1;
//   iractive:= 0;
//   if(r_newrefdef.rdflags & RDF_IRGOGGLES && currententity.flags & RF_IR_VISIBLE)
//      iractive:= 1;
//PGM

   // put work vertexes on stack, cache aligned
   pfinalverts := finalvert_arrp(((Integer(@finalverts[0]) + CACHE_SIZE - 1) and (not Cardinal(CACHE_SIZE - 1))));

   aliasbatchedtransformdata.num_points := s_pmdl^.num_xyz;
   aliasbatchedtransformdata.last_verts := @r_lastframe^.verts;
   aliasbatchedtransformdata.this_verts := @r_thisframe^.verts;
   aliasbatchedtransformdata.dest_verts := Pointer(pfinalverts);

   R_AliasTransformFinalVerts( aliasbatchedtransformdata.num_points,
                                aliasbatchedtransformdata.dest_verts,
                                      aliasbatchedtransformdata.last_verts,
                                      aliasbatchedtransformdata.this_verts );

// clip and draw all triangles
//
   pstverts := Pointer(Cardinal(s_pmdl) + s_pmdl^.ofs_st);
   ptri := Pointer(Cardinal(s_pmdl) + s_pmdl^.ofs_tris);

   if ((currententity^.flags and RF_WEAPONMODEL) <> 0) and (r_lefthand^.value = 1.0) then
  begin
      for i := 0 to s_pmdl^.num_tris-1 do
    begin
         pfv[0] := @pfinalverts^[ptri^.index_xyz[0]];
         pfv[1] := @pfinalverts^[ptri^.index_xyz[1]];
         pfv[2] := @pfinalverts^[ptri^.index_xyz[2]];

      if ((pfv[0]^.flags and pfv[1]^.flags and pfv[2].flags) <> 0) then
      begin
        Inc(Integer(ptri), SizeOf(dtriangle_t));
        continue; // completely clipped
      end;
   // insert s/t coordinates
      pfv[0]^.s := _SAL(pstverts^[ptri^.index_st[0]].s, 16);
      pfv[0]^.t := _SAL(pstverts^[ptri^.index_st[0]].t, 16);

      pfv[1]^.s := _SAL(pstverts^[ptri^.index_st[1]].s, 16);
      pfv[1]^.t := _SAL(pstverts^[ptri^.index_st[1]].t, 16);

      pfv[2]^.s := _SAL(pstverts^[ptri^.index_st[2]].s, 16);
      pfv[2]^.t := _SAL(pstverts^[ptri^.index_st[2]].t, 16);

      if ((pfv[0]^.flags or pfv[1]^.flags or pfv[2]^.flags) = 0) then
      begin
     // totally unclipped
        aliastriangleparms.a := pfv[2];
        aliastriangleparms.b := pfv[1];
        aliastriangleparms.c := pfv[0];
        R_DrawTriangle;
      end
      else
      begin
        R_AliasClipTriangle(pfv[2], pfv[1], pfv[0]);
      end;
      inc(Integer(ptri), SizeOf(dtriangle_t));
    end;
  end
  else
  begin
      for i := 0 to s_pmdl^.num_tris-1 do
    begin
         pfv[0] := @pfinalverts^[ptri^.index_xyz[0]];
         pfv[1] := @pfinalverts^[ptri^.index_xyz[1]];
         pfv[2] := @pfinalverts^[ptri^.index_xyz[2]];

      if ((pfv[0]^.flags and pfv[1]^.flags and pfv[2]^.flags) <> 0) then
      begin
        inc(Integer(ptri), SizeOf(dtriangle_t));
        continue; // completely clipped
      end;
   // insert s/t coordinates
      pfv[0]^.s := _SAL(pstverts^[ptri^.index_st[0]].s, 16);
      pfv[0]^.t := _SAL(pstverts^[ptri^.index_st[0]].t, 16);

      pfv[1]^.s := _SAL(pstverts^[ptri^.index_st[1]].s, 16);
      pfv[1]^.t := _SAL(pstverts^[ptri^.index_st[1]].t, 16);

      pfv[2]^.s := _SAL(pstverts^[ptri^.index_st[2]].s, 16);
      pfv[2]^.t := _SAL(pstverts^[ptri^.index_st[2]].t, 16);

      if ((pfv[0]^.flags or pfv[1]^.flags or pfv[2]^.flags) = 0) then
      begin
     // totally unclipped
        aliastriangleparms.a := pfv[0];
        aliastriangleparms.b := pfv[1];
        aliastriangleparms.c := pfv[2];
        R_DrawTriangle;
      end
      else
      begin
    // partially clipped
        R_AliasClipTriangle(pfv[0], pfv[1], pfv[2]);
      end;
      inc(Integer(ptri), SizeOf(dtriangle_t));
    end;
  end;
end;

(*
================
R_AliasSetUpTransform
================
*)

procedure R_AliasSetUpTransform;
var
   i           : Integer;
   viewmatrix  : matrix34;
   angles      : vec3_t;
begin

// TODO: should really be stored with the entity instead of being reconstructed
// TODO: should use a look-up table
// TODO: could cache lazily, stored in the entity
//

  angles[ROLL] := currententity^.angles[ROLL];
  angles[PITCH] := currententity^.angles[PITCH];
  angles[YAW] := currententity^.angles[YAW];
  AngleVectors(angles, @s_alias_forward, @s_alias_right, @s_alias_up);

// TODO: can do this with simple matrix rearrangement

  fillchar(aliasworldtransform, sizeof(aliasworldtransform), 0);
  fillchar(aliasoldworldtransform, sizeof(aliasworldtransform), 0);

  for i := 0 to 2 do
  begin
    aliasworldtransform[i][0] := s_alias_forward[i];
    aliasoldworldtransform[i][0] := aliasworldtransform[i][0];

    aliasworldtransform[i][1] := -s_alias_right[i];
    aliasoldworldtransform[i][0] := aliasworldtransform[i][1];

    aliasworldtransform[i][2] := s_alias_up[i];
    aliasoldworldtransform[i][0] := aliasworldtransform[i][2];
  end;

  aliasworldtransform[0][3] := currententity.origin[0] - r_origin[0];
  aliasworldtransform[1][3] := currententity.origin[1] - r_origin[1];
  aliasworldtransform[2][3] := currententity.origin[2] - r_origin[2];

  aliasoldworldtransform[0][3] := currententity.oldorigin[0] - r_origin[0];
  aliasoldworldtransform[1][3] := currententity.oldorigin[1] - r_origin[1];
  aliasoldworldtransform[2][3] := currententity.oldorigin[2] - r_origin[2];

// FIXME: can do more efficiently than full concatenation
//   memcpy( rotationmatrix, t2matrix, sizeof( rotationmatrix ) );

//   R_ConcatTransforms (t2matrix, tmatrix, rotationmatrix);

// TODO: should be global, set when vright, etc., set
  VectorCopy(vright, vec3_p(@viewmatrix[0])^);
  VectorCopy(vup, vec3_p(@viewmatrix[1])^);
  VectorInverse(vec3_p(@viewmatrix[1])^);
  VectorCopy(vpn, vec3_p(@viewmatrix[2])^);

  viewmatrix[0][3] := 0;
  viewmatrix[1][3] := 0;
  viewmatrix[2][3] := 0;

//   memcpy( aliasworldtransform, rotationmatrix, sizeof( aliastransform ) );

  R_ConcatTransforms(viewmatrix, aliasworldtransform, aliastransform);

  aliasworldtransform[0][3] := currententity^.origin[0];
  aliasworldtransform[1][3] := currententity^.origin[1];
  aliasworldtransform[2][3] := currententity^.origin[2];

  aliasoldworldtransform[0][3] := currententity^.oldorigin[0];
  aliasoldworldtransform[1][3] := currententity^.oldorigin[1];
  aliasoldworldtransform[2][3] := currententity^.oldorigin[2];
end;

(*
================
R_AliasTransformFinalVerts
================
*)
{$IFDEF ASM_CODE}

procedure R_AliasTransformFinalVerts(int numpoints, finalvert_t * fv, dtrivertx_t * oldv, dtrivertx_t * newv)
{
 float  lightcos;
 float   lerped_vert[3];
 int    byte_to_dword_ptr_var;
 int    tmpint;

 float  one:= 1.0F;
 float  zi;

 static float  FALIAS_Z_CLIP_PLANE:= ALIAS_Z_CLIP_PLANE;
 static float  PS_SCALE:= POWERSUIT_SCALE;

 __asm mov ecx, numpoints

 (*
 lerped_vert[0]:= r_lerp_move[0] + oldv.v[0]*r_lerp_backv[0] + newv.v[0]*r_lerp_frontv[0];
 lerped_vert[1]:= r_lerp_move[1] + oldv.v[1]*r_lerp_backv[1] + newv.v[1]*r_lerp_frontv[1];
 lerped_vert[2]:= r_lerp_move[2] + oldv.v[2]*r_lerp_backv[2] + newv.v[2]*r_lerp_frontv[2];
 *)
top_of_loop:

 __asm mov esi, oldv
 __asm mov edi, newv

 __asm xor ebx, ebx

 __asm mov bl, byte ptr [esi+DTRIVERTX_V0]
 __asm mov byte_to_dword_ptr_var, ebx
 __asm fild dword ptr byte_to_dword_ptr_var
 __asm fmul dword ptr [r_lerp_backv+0]                  ; oldv[0]*rlb[0]

 __asm mov bl, byte ptr [esi+DTRIVERTX_V1]
 __asm mov byte_to_dword_ptr_var, ebx
 __asm fild dword ptr byte_to_dword_ptr_var
 __asm fmul dword ptr [r_lerp_backv+4]                  ; oldv[1]*rlb[1] | oldv[0]*rlb[0]

 __asm mov bl, byte ptr [esi+DTRIVERTX_V2]
 __asm mov byte_to_dword_ptr_var, ebx
 __asm fild dword ptr byte_to_dword_ptr_var
 __asm fmul dword ptr [r_lerp_backv+8]                  ; oldv[2]*rlb[2] | oldv[1]*rlb[1] | oldv[0]*rlb[0]

 __asm mov bl, byte ptr [edi+DTRIVERTX_V0]
 __asm mov byte_to_dword_ptr_var, ebx
 __asm fild dword ptr byte_to_dword_ptr_var
 __asm fmul dword ptr [r_lerp_frontv+0]                 ; newv[0]*rlf[0] | oldv[2]*rlb[2] | oldv[1]*rlb[1] | oldv[0]*rlb[0]

 __asm mov bl, byte ptr [edi+DTRIVERTX_V1]
 __asm mov byte_to_dword_ptr_var, ebx
 __asm fild dword ptr byte_to_dword_ptr_var
 __asm fmul dword ptr [r_lerp_frontv+4]                 ; newv[1]*rlf[1] | newv[0]*rlf[0] | oldv[2]*rlb[2] | oldv[1]*rlb[1] | oldv[0]*rlb[0]

 __asm mov bl, byte ptr [edi+DTRIVERTX_V2]
 __asm mov byte_to_dword_ptr_var, ebx
 __asm fild dword ptr byte_to_dword_ptr_var
 __asm fmul dword ptr [r_lerp_frontv+8]                 ; newv[2]*rlf[2] | newv[1]*rlf[1] | newv[0]*rlf[0] | oldv[2]*rlb[2] | oldv[1]*rlb[1] | oldv[0]*rlb[0]

 __asm fxch st(5)                     ; oldv[0]*rlb[0] | newv[1]*rlf[1] | newv[0]*rlf[0] | oldv[2]*rlb[2] | oldv[1]*rlb[1] | newv[2]*rlf[2]
 __asm faddp st(2), st                ; newv[1]*rlf[1] | oldv[0]*rlb[0] + newv[0]*rlf[0] | oldv[2]*rlb[2] | oldv[1]*rlb[1] | newv[2]*rlf[2]
 __asm faddp st(3), st                ; oldv[0]*rlb[0] + newv[0]*rlf[0] | oldv[2]*rlb[2] | oldv[1]*rlb[1] + newv[1]*rlf[1] | newv[2]*rlf[2]
 __asm fxch st(1)                     ; oldv[2]*rlb[2] | oldv[0]*rlb[0] + newv[0]*rlf[0] | oldv[1]*rlb[1] + newv[1]*rlf[1] | newv[2]*rlf[2]
 __asm faddp st(3), st                ; oldv[0]*rlb[0] + newv[0]*rlf[0] | oldv[1]*rlb[1] + newv[1]*rlf[1] | oldv[2]*rlb[2] + newv[2]*rlf[2]
 __asm fadd dword ptr [r_lerp_move+0] ; lv0 | oldv[1]*rlb[1] + newv[1]*rlf[1] | oldv[2]*rlb[2] + newv[2]*rlf[2]
 __asm fxch st(1)                     ; oldv[1]*rlb[1] + newv[1]*rlf[1] | lv0 | oldv[2]*rlb[2] + newv[2]*rlf[2]
 __asm fadd dword ptr [r_lerp_move+4] ; lv1 | lv0 | oldv[2]*rlb[2] + newv[2]*rlf[2]
 __asm fxch st(2)                     ; oldv[2]*rlb[2] + newv[2]*rlf[2] | lv0 | lv1
 __asm fadd dword ptr [r_lerp_move+8] ; lv2 | lv0 | lv1
 __asm fxch st(1)                     ; lv0 | lv2 | lv1
 __asm fstp dword ptr [lerped_vert+0] ; lv2 | lv1
 __asm fstp dword ptr [lerped_vert+8] ; lv2
 __asm fstp dword ptr [lerped_vert+4] ; (empty)

 __asm mov  eax, currententity
 __asm mov  eax, dword ptr [eax+ENTITY_FLAGS]
 __asm mov  ebx, RF_SHELL_RED | RF_SHELL_GREEN | RF_SHELL_BLUE | RF_SHELL_DOUBLE | RF_SHELL_HALF_DAM
 __asm and  eax, ebx
 __asm jz   not_powersuit

 (*
 **    lerped_vert[0] += lightnormal[0] * POWERSUIT_SCALE
 **    lerped_vert[1] += lightnormal[1] * POWERSUIT_SCALE
 **    lerped_vert[2] += lightnormal[2] * POWERSUIT_SCALE
 *)

 __asm xor ebx, ebx
 __asm mov bl,  byte ptr [edi+DTRIVERTX_LNI]
 __asm mov eax, 12
 __asm mul ebx
 __asm lea eax, [r_avertexnormals+eax]

 __asm fld  dword ptr [eax+0]            ; n[0]
 __asm fmul PS_SCALE                     ; n[0] * PS
 __asm fld  dword ptr [eax+4]            ; n[1] | n[0] * PS
 __asm fmul PS_SCALE                     ; n[1] * PS | n[0] * PS
 __asm fld  dword ptr [eax+8]            ; n[2] | n[1] * PS | n[0] * PS
 __asm fmul PS_SCALE                     ; n[2] * PS | n[1] * PS | n[0] * PS
 __asm fld  dword ptr [lerped_vert+0]      ; lv0 | n[2] * PS | n[1] * PS | n[0] * PS
 __asm faddp st(3), st                  ; n[2] * PS | n[1] * PS | n[0] * PS + lv0
 __asm fld  dword ptr [lerped_vert+4]      ; lv1 | n[2] * PS | n[1] * PS | n[0] * PS + lv0
 __asm faddp st(2), st                  ; n[2] * PS | n[1] * PS + lv1 | n[0] * PS + lv0
 __asm fadd dword ptr [lerped_vert+8]      ; n[2] * PS + lv2 | n[1] * PS + lv1 | n[0] * PS + lv0
 __asm fxch st(2)                     ; LV0 | LV1 | LV2
 __asm fstp dword ptr [lerped_vert+0]      ; LV1 | LV2
 __asm fstp dword ptr [lerped_vert+4]      ; LV2
 __asm fstp dword ptr [lerped_vert+8]      ; (empty)

not_powersuit:

 (*
 fv.flags:= 0;

 fv.xyz[0]:= DotProduct(lerped_vert, aliastransform[0]) + aliastransform[0][3];
 fv.xyz[1]:= DotProduct(lerped_vert, aliastransform[1]) + aliastransform[1][3];
 fv.xyz[2]:= DotProduct(lerped_vert, aliastransform[2]) + aliastransform[2][3];
 *)
 __asm mov  eax, fv
 __asm mov  dword ptr [eax+FINALVERT_FLAGS], 0

 __asm fld  dword ptr [lerped_vert+0]           ; lv0
 __asm fmul dword ptr [aliastransform+0]        ; lv0*at[0][0]
 __asm fld  dword ptr [lerped_vert+4]           ; lv1 | lv0*at[0][0]
 __asm fmul dword ptr [aliastransform+4]        ; lv1*at[0][1] | lv0*at[0][0]
 __asm fld  dword ptr [lerped_vert+8]           ; lv2 | lv1*at[0][1] | lv0*at[0][0]
 __asm fmul dword ptr [aliastransform+8]        ; lv2*at[0][2] | lv1*at[0][1] | lv0*at[0][0]
 __asm fxch st(2)                               ; lv0*at[0][0] | lv1*at[0][1] | lv2*at[0][2]
 __asm faddp st(1), st                          ; lv0*at[0][0] + lv1*at[0][1] | lv2*at[0][2]
 __asm faddp st(1), st                          ; lv0*at[0][0] + lv1*at[0][1] + lv2*at[0][2]
 __asm fadd  dword ptr [aliastransform+12]      ; FV.X

 __asm fld  dword ptr [lerped_vert+0]           ; lv0
 __asm fmul dword ptr [aliastransform+16]       ; lv0*at[1][0]
 __asm fld  dword ptr [lerped_vert+4]           ; lv1 | lv0*at[1][0]
 __asm fmul dword ptr [aliastransform+20]       ; lv1*at[1][1] | lv0*at[1][0]
 __asm fld  dword ptr [lerped_vert+8]           ; lv2 | lv1*at[1][1] | lv0*at[1][0]
 __asm fmul dword ptr [aliastransform+24]       ; lv2*at[1][2] | lv1*at[1][1] | lv0*at[1][0]
 __asm fxch st(2)                               ; lv0*at[1][0] | lv1*at[1][1] | lv2*at[1][2]
 __asm faddp st(1), st                          ; lv0*at[1][0] + lv1*at[1][1] | lv2*at[1][2]
 __asm faddp st(1), st                          ; lv0*at[1][0] + lv1*at[1][1] + lv2*at[1][2]
 __asm fadd dword ptr [aliastransform+28]       ; FV.Y | FV.X
 __asm fxch st(1)                               ; FV.X | FV.Y
 __asm fstp  dword ptr [eax+FINALVERT_X]        ; FV.Y

 __asm fld  dword ptr [lerped_vert+0]           ; lv0
 __asm fmul dword ptr [aliastransform+32]       ; lv0*at[2][0]
 __asm fld  dword ptr [lerped_vert+4]           ; lv1 | lv0*at[2][0]
 __asm fmul dword ptr [aliastransform+36]       ; lv1*at[2][1] | lv0*at[2][0]
 __asm fld  dword ptr [lerped_vert+8]           ; lv2 | lv1*at[2][1] | lv0*at[2][0]
 __asm fmul dword ptr [aliastransform+40]       ; lv2*at[2][2] | lv1*at[2][1] | lv0*at[2][0]
 __asm fxch st(2)                               ; lv0*at[2][0] | lv1*at[2][1] | lv2*at[2][2]
 __asm faddp st(1), st                          ; lv0*at[2][0] + lv1*at[2][1] | lv2*at[2][2]
 __asm faddp st(1), st                          ; lv0*at[2][0] + lv1*at[2][1] + lv2*at[2][2]
 __asm fadd dword ptr [aliastransform+44]       ; FV.Z | FV.Y
 __asm fxch st(1)                               ; FV.Y | FV.Z
 __asm fstp dword ptr [eax+FINALVERT_Y]         ; FV.Z
 __asm fstp dword ptr [eax+FINALVERT_Z]         ; (empty)

 (*
 **  lighting
 **
 **  plightnormal:= r_avertexnormals[newv.lightnormalindex];
 **   lightcos:= DotProduct (plightnormal, r_plightvec);
 **   temp:= r_ambientlight;
 *)
 __asm xor ebx, ebx
 __asm mov bl,  byte ptr [edi+DTRIVERTX_LNI]
 __asm mov eax, 12
 __asm mul ebx
 __asm lea eax, [r_avertexnormals+eax]
 __asm lea ebx, r_plightvec

 __asm fld  dword ptr [eax+0]
 __asm fmul dword ptr [ebx+0]
 __asm fld  dword ptr [eax+4]
 __asm fmul dword ptr [ebx+4]
 __asm fld  dword ptr [eax+8]
 __asm fmul dword ptr [ebx+8]
 __asm fxch st(2)
 __asm faddp st(1), st
 __asm faddp st(1), st
 __asm fstp dword ptr lightcos
 __asm mov eax, lightcos
 __asm mov ebx, r_ambientlight

 (*
 if (lightcos < 0)
 {
  temp += (int)(r_shadelight * lightcos);

  // clamp; because we limited the minimum ambient and shading light, we
  // don't have to clamp low light, just bright
  if (temp < 0)
   temp:= 0;
 }

fv.v[4] := temp;
* )
  __asm or eax, eax
  __asm jns store_fv4

  __asm fld dword ptr r_shadelight
  __asm fmul dword ptr lightcos
  __asm fistp dword ptr tmpint
  __asm add ebx, tmpint

  __asm or ebx, ebx
  __asm jns store_fv4
  __asm mov ebx, 0

  store_fv4:
  __asm mov edi, fv
  __asm mov dword ptr[edi + FINALVERT_V4], ebx

  __asm mov edx, dword ptr[edi + FINALVERT_FLAGS]

 (*
 ** do clip testing and projection here
 *)
 (*
 if ( dest_vert.xyz[2] < ALIAS_Z_CLIP_PLANE )
 {
  dest_vert.flags |= ALIAS_Z_CLIP;
 }
 else
 {
  R_AliasProjectAndClipTestFinalVert( dest_vert );
 }
 *)
__asm mov eax, dword ptr[edi + FINALVERT_Z]
__asm and eax, eax
__asm js alias_z_clip
__asm cmp eax, FALIAS_Z_CLIP_PLANE
__asm jl alias_z_clip

 (*
 This is the code to R_AliasProjectAndClipTestFinalVert

 float   zi;
 float   x, y, z;

 x:= fv.xyz[0];
 y:= fv.xyz[1];
 z:= fv.xyz[2];
 zi:= 1.0 / z;

 fv.v[5]:= zi * s_ziscale;

 fv.v[0]:= (x * aliasxscale * zi) + aliasxcenter;
 fv.v[1]:= (y * aliasyscale * zi) + aliasycenter;
 *)
__asm fld one;
1
__asm fdiv dword ptr[edi + FINALVERT_Z];
zi

__asm mov eax, dword ptr[edi + 32]
__asm mov eax, dword ptr[edi + 64]

__asm fst zi;
zi
__asm fmul s_ziscale;
fv5
__asm fld dword ptr[edi + FINALVERT_X];
x | fv5
__asm fmul aliasxscale;
x * aliasxscale | fv5
__asm fld dword ptr[edi + FINALVERT_Y];
y | x * aliasxscale | fv5
__asm fmul aliasyscale;
y * aliasyscale | x * aliasxscale | fv5
__asm fxch st(1);
x * aliasxscale | y * aliasyscale | fv5
__asm fmul zi;
x * asx * zi | y * asy | fv5
__asm fadd aliasxcenter;
fv0 | y * asy | fv5
__asm fxch st(1);
y * asy | fv0 | fv5
__asm fmul zi;
y * asy * zi | fv0 | fv5
__asm fadd aliasycenter;
fv1 | fv0 | fv5
__asm fxch st(2);
fv5 | fv0 | fv1
__asm fistp dword ptr[edi + FINALVERT_V5];
fv0 | fv1
__asm fistp dword ptr[edi + FINALVERT_V0];
fv1
__asm fistp dword ptr[edi + FINALVERT_V1];
(empty)

 (*
 if (fv.v[0] < r_refdef.aliasvrect.x)
  fv.flags |= ALIAS_LEFT_CLIP;
 if (fv.v[1] < r_refdef.aliasvrect.y)
  fv.flags |= ALIAS_TOP_CLIP;
 if (fv.v[0] > r_refdef.aliasvrectright)
  fv.flags |= ALIAS_RIGHT_CLIP;
 if (fv.v[1] > r_refdef.aliasvrectbottom)
  fv.flags |= ALIAS_BOTTOM_CLIP;
 *)
__asm mov eax, dword ptr[edi + FINALVERT_V0]
__asm mov ebx, dword ptr[edi + FINALVERT_V1]

__asm cmp eax, r_refdef.aliasvrect.x
__asm jge ct_alias_top
__asm or edx, ALIAS_LEFT_CLIP
ct_alias_top:
__asm cmp ebx, r_refdef.aliasvrect.y
__asm jge ct_alias_right
__asm or edx, ALIAS_TOP_CLIP
ct_alias_right:
__asm cmp eax, r_refdef.aliasvrectright
__asm jle ct_alias_bottom
__asm or edx, ALIAS_RIGHT_CLIP
ct_alias_bottom:
__asm cmp ebx, r_refdef.aliasvrectbottom
__asm jle end_of_loop
__asm or edx, ALIAS_BOTTOM_CLIP

__asm jmp end_of_loop

alias_z_clip:
__asm or edx, ALIAS_Z_CLIP

end_of_loop:

__asm mov dword ptr[edi + FINALVERT_FLAGS], edx
__asm add oldv, DTRIVERTX_SIZE
__asm add newv, DTRIVERTX_SIZE
__asm add fv, FINALVERT_SIZE

__asm dec ecx
__asm jnz top_of_loop
}
{$ELSE}

procedure R_AliasTransformFinalVerts(numpoints: integer; fv: finalvert_p; oldv: dtrivertx_p; newv: dtrivertx_p);
var
  i: integer;
  temp: integer;
  lightcos: single;
  plightnormal: vec3_t;
  lerped_vert: vec3_t;
begin
  for i := 0 to numpoints - 1 do
  begin
    lerped_vert[0] := r_lerp_move[0] + oldv^.v[0] * r_lerp_backv[0] + newv^.v[0] * r_lerp_frontv[0];
    lerped_vert[1] := r_lerp_move[1] + oldv^.v[1] * r_lerp_backv[1] + newv^.v[1] * r_lerp_frontv[1];
    lerped_vert[2] := r_lerp_move[2] + oldv^.v[2] * r_lerp_backv[2] + newv^.v[2] * r_lerp_frontv[2];

    plightnormal := r_avertexnormals[newv^.lightnormalindex];

  // PMM - added double damage shell
    if ((currententity^.flags and (RF_SHELL_RED or RF_SHELL_GREEN or RF_SHELL_BLUE or RF_SHELL_DOUBLE or RF_SHELL_HALF_DAM)) <> 0) then
    begin
      lerped_vert[0] := lerped_vert[0] + plightnormal[0] * POWERSUIT_SCALE;
      lerped_vert[1] := lerped_vert[1] + plightnormal[1] * POWERSUIT_SCALE;
      lerped_vert[2] := lerped_vert[2] + plightnormal[2] * POWERSUIT_SCALE;
    end;

    fv^.xyz[0] := DotProduct(lerped_vert, vec3_p(@aliastransform[0])^) + aliastransform[0][3];
    fv^.xyz[1] := DotProduct(lerped_vert, vec3_p(@aliastransform[1])^) + aliastransform[1][3];
    fv^.xyz[2] := DotProduct(lerped_vert, vec3_p(@aliastransform[2])^) + aliastransform[2][3];

    fv.flags := 0;

  // lighting
    lightcos := DotProduct(plightnormal, r_plightvec);
    temp := r_ambientlight;

    if (lightcos < 0) then
    begin
      inc(temp, Trunc(r_shadelight * lightcos));

   // clamp; because we limited the minimum ambient and shading light, we
   // don't have to clamp low light, just bright
      if (temp < 0) then
        temp := 0;
    end;

    fv^.l := temp;

    if (fv^.xyz[2] < ALIAS_Z_CLIP_PLANE) then
    begin
      fv^.flags := fv^.flags or ALIAS_Z_CLIP;
    end
    else
    begin
      R_AliasProjectAndClipTestFinalVert(fv);
    end;
    inc(Integer(fv), SizeOf(finalvert_t));
    inc(Integer(oldv), SizeOf(dtrivertx_t));
    inc(Integer(newv), SizeOf(dtrivertx_t));
  end;
end;
{$ENDIF}

(*
================
R_AliasProjectAndClipTestFinalVert
================
*)

procedure R_AliasProjectAndClipTestFinalVert(fv: finalvert_p);
var
  zi: single;
  x, y, z: single;
begin
 // project points
  x := fv^.xyz[0];
  y := fv^.xyz[1];
  z := fv^.xyz[2];
  zi := 1.0 / z;

  fv^.zi := Trunc(zi * s_ziscale);

  fv^.u := Trunc((x * aliasxscale * zi) + aliasxcenter);
  fv^.v := Trunc((y * aliasyscale * zi) + aliasycenter);

  if (fv^.u < r_refdef.aliasvrect.x) then
    fv^.flags := fv^.flags or ALIAS_LEFT_CLIP;
  if (fv^.v < r_refdef.aliasvrect.y) then
    fv^.flags := fv^.flags or ALIAS_TOP_CLIP;
  if (fv^.u > r_refdef.aliasvrectright) then
    fv^.flags := fv^.flags or ALIAS_RIGHT_CLIP;
  if (fv^.v > r_refdef.aliasvrectbottom) then
    fv^.flags := fv^.flags or ALIAS_BOTTOM_CLIP;
end;

(*
===============
R_AliasSetupSkin
===============
*)
// static

function R_AliasSetupSkin: qboolean;
var
  skinnum: integer;
  pskindesc: image_p;
begin
  if (currententity^.skin <> nil) then
    pskindesc := currententity^.skin
  else
  begin
    skinnum := currententity^.skinnum;
    if ((skinnum >= s_pmdl^.num_skins) or (skinnum < 0)) then
    begin
         ri.Con_Printf(PRINT_ALL, 'R_AliasSetupSkin %s: no such skin #%d\n', currentmodel^.name, skinnum);
         skinnum:= 0;
      end;
      pskindesc := currentmodel^.skins[skinnum];
   end;

  if (pskindesc = nil) then
  begin
    Result := false;
    Exit;
  end;

  r_affinetridesc.pskin := pskindesc^.pixels[0];
  r_affinetridesc.skinwidth := pskindesc^.width;
  r_affinetridesc.skinheight := pskindesc^.height;

  R_PolysetUpdateTables; // FIXME: precalc edge lookups

  Result := true;
end;

(*
================
R_AliasSetupLighting

  FIXME: put lighting into tables
================
*)

procedure R_AliasSetupLighting;
var
  lighting: alight_t;
  lightvec: array[0..2] of single;
  light: vec3_t;
  i, j: integer;
  scale: single;
  min: single;
begin
  lightvec[0] := -1;
  lightvec[1] := 0;
  lightvec[2] := 0;

 // all components of light should be identical in software
  if ((currententity^.flags and RF_FULLBRIGHT) <> 0) then
  begin
    for i := 0 to 2 do
      light[i] := 1.0;
  end
  else
  begin
    R_LightPoint(vec3_p(@currententity^.origin)^, light);
  end;

 // save off light value for server to look at (BIG HACK!)
  if ((currententity^.flags and RF_WEAPONMODEL) <> 0) then
    r_lightlevel^.value := 150.0 * light[0];

  if ((currententity^.flags and RF_MINLIGHT) <> 0) then
  begin
    for i := 0 to 2 do
    begin
      if (light[i] < 0.1) then
        light[i] := 0.1;
    end;
  end;

  if ((currententity.flags and RF_GLOW) <> 0) then
  begin
  // bonus items will pulse with time
    scale := 0.1 * sin(r_newrefdef.time * 7);
    for i := 0 to 2 do
    begin
      min := light[i] * 0.8;
      light[i] := light[i] + scale;
      if (light[i] < min) then
        light[i] := min;
    end;
  end;

  j := Trunc((light[0] + light[1] + light[2]) * 0.3333 * 255);

  lighting.ambientlight := j;
  lighting.shadelight := j;

  lighting.plightvec := @lightvec;

// clamp lighting so it doesn't overbright as much
  if (lighting.ambientlight > 128) then
    lighting.ambientlight := 128;
  if (lighting.ambientlight + lighting.shadelight > 192) then
    lighting.shadelight := 192 - lighting.ambientlight;

// guarantee that no vertex will ever be lit below LIGHT_MIN, so we don't have
// to clamp off the bottom
  r_ambientlight := lighting.ambientlight;

  if (r_ambientlight < LIGHT_MIN) then
    r_ambientlight := LIGHT_MIN;

  r_ambientlight := (255 - r_ambientlight) shl VID_CBITS;

  if (r_ambientlight < LIGHT_MIN) then
    r_ambientlight := LIGHT_MIN;

  r_shadelight := lighting.shadelight;

  if (r_shadelight < 0) then
    r_shadelight := 0;

  r_shadelight := r_shadelight * VID_GRADES;

// rotate the lighting vector into the model's frame of reference
  r_plightvec[0] := DotProduct(vec3_p(lighting.plightvec)^, s_alias_forward);
  r_plightvec[1] := -DotProduct(vec3_p(lighting.plightvec)^, s_alias_right);
  r_plightvec[2] := DotProduct(vec3_p(lighting.plightvec)^, s_alias_up);
end;

(*
=================
R_AliasSetupFrames

=================
*)

procedure R_AliasSetupFrames(pmdl: dmdl_p);
var
  thisframe, lastframe: integer;
begin
  thisframe := currententity^.frame;
  lastframe := currententity^.oldframe;

  if ((thisframe >= pmdl^.num_frames) or (thisframe < 0)) then
  begin
    ri.Con_Printf(PRINT_ALL, PChar('R_AliasSetupFrames ' + currentmodel^.name + ': no such thisframe ' + IntToStr(thisframe) + #13#10));
    thisframe := 0;
  end;
  if ((lastframe >= pmdl^.num_frames) or (lastframe < 0)) then
  begin
      ri.Con_Printf(PRINT_ALL, 'R_AliasSetupFrames %s: no such thisframe %d', currentmodel^.name, thisframe);
      thisframe := 0;
   end;
   r_thisframe := daliasframe_p(integer(pmdl) + pmdl^.ofs_frames + (thisframe * pmdl^.framesize));
   r_lastframe := daliasframe_p(integer(pmdl) + pmdl^.ofs_frames + (lastframe * pmdl^.framesize));
end;

(*
** R_AliasSetUpLerpData
**
** Precomputes lerp coefficients used for the whole frame.
*)

procedure R_AliasSetUpLerpData(pmdl: dmdl_p; backlerp: single);
var
  frontlerp: single;
  translation: vec3_t;
  vectors: array[0..2] of vec3_t;
  i: integer;
begin
  frontlerp := 1.0 - backlerp;

 (*
 ** convert entity's angles into discrete vectors for R, U, and F
 *)
  AngleVectors(vec3_p(@currententity.angles)^, @vectors[0], @vectors[1], @vectors[2]);

 (*
 ** translation is the vector from last position to this position
 *)
  VectorSubtract(vec3_p(@currententity^.oldorigin)^, vec3_p(@currententity^.origin)^, translation);

 (*
 ** move should be the delta back to the previous frame * backlerp
 *)
  r_lerp_move[0] := DotProduct(translation, vectors[0]); // forward
  r_lerp_move[1] := -DotProduct(translation, vectors[1]); // left
  r_lerp_move[2] := DotProduct(translation, vectors[2]); // up

  VectorAdd(r_lerp_move, r_lastframe^.translate, r_lerp_move);

  for i := 0 to 2 do
  begin
    r_lerp_move[i] := backlerp * r_lerp_move[i] + frontlerp * r_thisframe^.translate[i];
  end;

  for i := 0 to 2 do
  begin
    r_lerp_frontv[i] := frontlerp * r_thisframe^.scale[i];
    r_lerp_backv[i] := backlerp * r_lastframe^.scale[i];
  end;
end;

(*
================
R_AliasDrawModel
================
*)

procedure R_AliasDrawModel;
var
  color: integer;
begin
  s_pmdl := dmdl_p(currentmodel^.extradata);

  if (r_lerpmodels^.value = 0.0) then
    currententity^.backlerp := 0;

  if ((currententity^.flags and RF_WEAPONMODEL) <> 0) then
  begin
    if (r_lefthand^.value = 1.0) then
      aliasxscale := -aliasxscale
    else
      if (r_lefthand^.value = 2.0) then
        Exit;
  end;

   (*
   ** we have to set our frame pointers and transformations before
   ** doing any real work
   *)
   R_AliasSetupFrames(s_pmdl);
   R_AliasSetUpTransform;

   // see if the bounding box lets us trivially reject, also sets
   // trivial accept status
   if (Cardinal(R_AliasCheckBBox) = BBOX_TRIVIAL_REJECT) then
  begin
    if (((currententity^.flags and RF_WEAPONMODEL) <> 0) and (r_lefthand^.value = 1.0)) then
    begin
         aliasxscale := -aliasxscale;
      end;
      Exit;
  end;

   // set up the skin and verify it exists
   if (not R_AliasSetupSkin) then
  begin
      ri.Con_Printf(PRINT_ALL, 'R_AliasDrawModel %s: NULL skin found\n', currentmodel^.name);
      Exit;
  end;

   inc(r_amodels_drawn);
   R_AliasSetupLighting;

   (*
   ** select the proper span routine based on translucency
   *)
   // PMM - added double damage shell
   // PMM - reordered to handle blending
   if ((currententity^.flags and (RF_SHELL_RED or RF_SHELL_GREEN or RF_SHELL_BLUE or RF_SHELL_DOUBLE or RF_SHELL_HALF_DAM)) <> 0) then
  begin
      // PMM - added double
      color := currententity^.flags and (RF_SHELL_RED or RF_SHELL_GREEN or RF_SHELL_BLUE or RF_SHELL_DOUBLE or RF_SHELL_HALF_DAM);
      // PMM - reordered, new shells after old shells (so they get overriden)

      if ( color = RF_SHELL_RED ) then
         r_aliasblendcolor:= SHELL_RED_COLOR
      else
      if ( color = RF_SHELL_GREEN ) then
           r_aliasblendcolor:= SHELL_GREEN_COLOR
        else
        if ( color = RF_SHELL_BLUE ) then
             r_aliasblendcolor:= SHELL_BLUE_COLOR
          else
          if ( color = (RF_SHELL_RED or RF_SHELL_GREEN) ) then
               r_aliasblendcolor:= SHELL_RG_COLOR
            else
            if ( color = (RF_SHELL_RED or RF_SHELL_BLUE) ) then
                 r_aliasblendcolor:= SHELL_RB_COLOR
              else
              if ( color = (RF_SHELL_BLUE or RF_SHELL_GREEN) ) then
                   r_aliasblendcolor:= SHELL_BG_COLOR
                  // PMM - added this .. it's yellowish
                else
                if ( color = (RF_SHELL_DOUBLE) ) then
                     r_aliasblendcolor:= SHELL_DOUBLE_COLOR
                  else
                  if ( color = (RF_SHELL_HALF_DAM) ) then
                       r_aliasblendcolor:= SHELL_HALF_DAM_COLOR
                  // pmm
                  else
                    r_aliasblendcolor := SHELL_WHITE_COLOR;

    if (currententity^.alpha > 0.33) then
      d_pdrawspans := R_PolysetDrawSpansConstant8_66
    else
      d_pdrawspans := R_PolysetDrawSpansConstant8_33;
  end
  else
    if ((currententity.flags and RF_TRANSLUCENT) <> 0) then
    begin
      if (currententity.alpha > 0.66) then
        d_pdrawspans := R_PolysetDrawSpans8_Opaque
      else
        if (currententity.alpha > 0.33) then
          d_pdrawspans := R_PolysetDrawSpans8_66
        else
          d_pdrawspans := R_PolysetDrawSpans8_33
    end
    else
    begin
      d_pdrawspans := R_PolysetDrawSpans8_Opaque;
    end;

 (*
 ** compute this_frame and old_frame addresses
 *)
  R_AliasSetUpLerpData(s_pmdl, currententity^.backlerp);

  if ((currententity^.flags and RF_DEPTHHACK) <> 0) then
    // TRANSLATOR'S NOTE: (x* 1.0) to avoid arithmetic overflow
    s_ziscale := ($8000 * 1.0) * ($10000 * 1.0) * 3.0
  else
    s_ziscale := ($8000 * 1.0) * ($10000 * 1.0);

  R_AliasPreparePoints;

  if ((currententity^.flags and RF_WEAPONMODEL <> 0) and (r_lefthand^.value = 1.0)) then
  begin
    aliasxscale := -aliasxscale;
  end;
end;

end.
