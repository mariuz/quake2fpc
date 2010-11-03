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
{ File(s): ref_soft\r_light.c                                                }
{                                                                            }
{ Content: lights methods                                                    }
{                                                                            }
{ Initial conversion by : Slavisa Milojkovic [keeper@milnet.co.yu]           }
{ Initial conversion on : 01-May-2002                                        }
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
{ Finished on : 13-May-2002                                                  }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{ - r_local.pas                                                              }
{----------------------------------------------------------------------------}
{ Updated on : 18-July-2002                                                  }
{ Updated by : CodeFusion (michael@skovslund.dk)                             }
{ Updated on : 11-August-2002                                                }
{ Updated by : CodeFusion (michael@skovslund.dk)                             }
{                                                                            }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{ None.                                                                      }
{                                                                            }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{----------------------------------------------------------------------------}

{
==============================================================================

DYNAMIC LIGHTS

==============================================================================
}
unit r_light;

interface

uses
  q_shared,
  r_model,
  r_local;

var
  r_dlightframecount: Integer;
  blocklights: array[0..1024 - 1] of Cardinal; (* allow some very large lightmaps*)

procedure R_PushDlights(model: model_p);
procedure R_LightPoint(p: vec3_t; var color: vec3_t);
//procedure R_LightPoint(p, color: vec3_t);
procedure R_BuildLightMap;

implementation

uses
  qfiles,
  ref,
  r_bsp_c,
  r_surf,
  r_main,
  SysUtils;

{
=============================================================================

LIGHT SAMPLING

=============================================================================
}
var
  pointcolor: vec3_t;
  lightplane: mplane_p; // used as shadow plane
  lightspot: vec3_t;

//procedure R_PushDlights (model: model_p);
//begin
//end;

//procedure R_LightPoint (p, color: vec3_t);
//begin
//end;

{
=============
R_MarkLights
=============
}

procedure R_MarkLights(light: dlight_p; bit: integer; node: mnode_p);
var
  splitplane: mplane_p;
  dist: Single;
  surf: msurface_p;
  i: Integer;
begin
  if not (node^.contents <> (-1)) then
    Exit;

  splitplane := node^.plane;
  dist := DotProduct(light^.origin, splitplane^.normal) - splitplane^.dist;

//=====
//PGM
  i := trunc(light^.intensity);
  if (i < 0) then
    i := -i;
//PGM
//=====

  if dist > i then // PGM (dist > light->intensity)
  begin
    R_MarkLights(light, bit, node^.children[0]);
    exit;
  end;
  if dist < (-i) then // PGM (dist < -light->intensity)
  begin
    R_MarkLights(light, bit, node^.children[1]);
    exit;
  end;

// mark the polygons
  surf := @msurface_arrp(r_worldmodel^.surfaces)^[node^.firstsurface];
  i := 0;
  while i < node^.numsurfaces do
  begin
    if (surf^.dlightframe <> r_dlightframecount) then
    begin
      surf^.dlightbits := 0;
      surf^.dlightframe := r_dlightframecount;
    end;
    surf^.dlightbits := (surf^.dlightbits or bit);
    inc(i);
    inc(Integer(surf), SizeOf(msurface_t));
  end;
  R_MarkLights(light, bit, node^.children[0]);
  R_MarkLights(light, bit, node^.children[1]);
end;

{
=============
R_PushDlights
=============
}

procedure R_PushDlights(model: model_p);
var
  i: integer;
  l: dlight_p;
begin
  r_dlightframecount := r_framecount;
  i := 0;
  l := r_newrefdef.dlights;
  while i < r_newrefdef.num_dlights do
  begin
    R_MarkLights(l, 1 shl i, @mnode_arrp(model^.nodes)^[model.firstnode]);
    Inc(i);
    Inc(integer(l), SizeOf(dlight_t));
  end;
end;

function RecursiveLightPoint(node: mnode_p; start, ends: vec3_t): Integer;
var
  front, back, frac: Single;
  side: integer;
  plane: mplane_p;
  mid: vec3_t;
  surf: msurface_p;
  s, t, ds, dt, i: integer;
  tex: mtexinfo_p;
  lightmap: pbyte;
  scales: PSingle;
  maps, r: integer;
  samp: Single;
begin
  if (node^.contents <> -1) then
  begin
    Result := -1; // didn't hit anything
    Exit;
  end;

// calculate mid point

// FIXME: optimize for axial
  plane := node^.plane;
  front := DotProduct(start, plane^.normal) - plane^.dist;
  back := DotProduct(ends, plane^.normal) - plane^.dist;
  if (front < 0.0) then
    side := 1
  else
    side := 0;

  if (Integer(back < 0.0) = side) then
  begin
    Result := RecursiveLightPoint(node^.children[side], start, ends);
    Exit;
  end;

  frac := front / (front - back);
  mid[0] := start[0] + (ends[0] - start[0]) * frac;
  mid[1] := start[1] + (ends[1] - start[1]) * frac;
  mid[2] := start[2] + (ends[2] - start[2]) * frac;
  if (plane^._type < 3) then // axial planes
    mid[plane._type] := plane^.dist;

// go down front side
  r := RecursiveLightPoint(node^.children[side], start, mid);
  if (r >= 0) then
  begin
    Result := r; // hit something
    Exit;
  end;

  if (Integer(back < 0.0) = side) then
  begin
    Result := -1; // didn't hit anything
    Exit;
  end;

// check for impact on this node
  VectorCopy(mid, lightspot);
  lightplane := plane;

  surf := @msurface_arrp(r_worldmodel^.surfaces)^[node^.firstsurface];
//  i := 0;
//  while i < node^.numsurfaces do
  for i := 0 to node^.numsurfaces - 1 do
  begin
    if (surf^.flags and (SURF_DRAWTURB or SURF_DRAWSKY)) <> 0 then
    begin
      Inc(Integer(Surf), SizeOf(msurface_t));
      continue; // no lightmaps
    end;
    tex := surf^.texinfo;
    s := trunc(DotProduct(mid, vec3_p(@tex^.vecs[0])^) + tex^.vecs[0][3]);
    t := trunc(DotProduct(mid, vec3_p(@tex^.vecs[1])^) + tex^.vecs[1][3]);
    if ((s < surf^.texturemins[0]) or (t < surf^.texturemins[1])) then
    begin
      Inc(Integer(Surf), SizeOf(msurface_t));
      continue;
    end;

    ds := s - surf^.texturemins[0];
    dt := t - surf^.texturemins[1];

    if ((ds > surf^.extents[0]) or (dt > surf^.extents[1])) then
    begin
      Inc(Integer(Surf), SizeOf(msurface_t));
      continue;
    end;

    if (surf^.samples = nil) then
    begin
      Result := 0;
      Exit;
    end;

    ds := _SAR(ds, 4);
    dt := _SAR(dt, 4);

    lightmap := surf^.samples;
    VectorCopy(vec3_origin, pointcolor);
    if (lightmap <> nil) then
    begin
      Inc(Integer(lightmap), (dt * (_SAR(surf^.extents[0], 4) + 1) + ds));
      maps := 0;
      while ((maps < MAXLIGHTMAPS) and (surf^.styles[maps] <> 255)) do
      begin
        samp := lightmap^;
        samp := samp * (1.0 / 255); // adjust for gl scale
        scales := @lightstyle_arrp(r_newrefdef.lightstyles)^[surf^.styles[maps]].rgb;
        VectorMA(pointcolor, samp, vec3_p(scales)^, pointcolor);
        Inc(Integer(lightmap), ((_SAR(surf^.extents[0], 4) + 1) * (_SAR(surf^.extents[1], 4) + 1)));
        Inc(maps);
      end;
    end;
    Result := 1;
    Exit;
  end;

// go down back side
  Result := RecursiveLightPoint(node^.children[side xor 1], mid, ends);
end;

{
===============
R_LightPoint
===============
}

procedure R_LightPoint(p: vec3_t; var color: vec3_t);
var
  ends: vec3_t;
  r: Single;
  lnum: integer;
  dl: dlight_p;
//  light   : Single;
  dist: vec3_t;
  add: Single;
begin
  if r_worldmodel^.lightdata = nil then
  begin
    color[0] := 1.0;
    color[1] := 1.0;
    color[2] := 1.0;
    Exit;
  end;

  ends[0] := p[0];
  ends[1] := p[1];
  ends[2] := p[2] - 2048;

  r := RecursiveLightPoint(r_worldmodel^.nodes, p, ends);

  if (r = -1) then
    VectorCopy(vec3_origin, color)
  else
    VectorCopy(pointcolor, color);

  //
  // add dynamic lights
  //

//  light := 0.0;
  for lnum := 0 to r_newrefdef.num_dlights - 1 do
  begin
    dl := @dlight_arrp(r_newrefdef.dlights)^[lnum];
    VectorSubtract(vec3_p(@currententity^.origin)^, dl^.origin, dist);
    add := dl^.intensity - VectorLength(dist);
    add := add * (1.0 / 256);
    if (add > 0) then
    begin
      VectorMA(color, add, dl^.color, color);
    end;
  end;
end;

//===================================================================

{
===============
R_AddDynamicLights
===============
}

procedure R_AddDynamicLights;
var
  surf: msurface_p;
  lnum: Integer;
  sd: Integer;
  td: Integer;
  dist: Single;
  rad: Single;
  minlight: Single;
  impact: vec3_t;
  local: vec3_t;
  s: Integer;
  t: Integer;
  i: Integer;
  smax: Integer;
  tmax: Integer;
  tex: mtexinfo_p;
  dl: dlight_p;
  negativeLight: Integer; //PGM
begin
  surf := r_drawsurf.surf;
  smax := _SAR(surf^.extents[0], 4) + 1;
  tmax := _SAR(surf^.extents[1], 4) + 1;
  tex := surf^.texinfo;

  for lnum := 0 to r_newrefdef.num_dlights - 1 do
  begin
    if ((surf^.dlightbits and (1 shl lnum)) = 0) then
      Continue; // not lit by this light

    dl := @dlight_arrp(r_newrefdef.dlights)^[lnum];
    rad := dl^.intensity;

//=====
//PGM
    negativeLight := 0;
    if (rad < 0.0) then
    begin
      negativeLight := 1;
      rad := -rad;
    end;
//PGM
//=====

    dist := DotProduct(dl^.origin, surf^.plane^.normal) - surf^.plane^.dist;
    rad := rad - fabs(dist);
    minlight := 32; // dl->minlight;
    if (rad < minlight) then
      continue;

    minlight := rad - minlight;
    for i := 0 to 2 do
      impact[i] := dl^.origin[i] - surf^.plane^.normal[i] * dist;

    local[0] := DotProduct(impact, vec3_p(@tex^.vecs[0])^) + tex^.vecs[0][3];
    local[1] := DotProduct(impact, vec3_p(@tex^.vecs[1])^) + tex^.vecs[1][3];

    local[0] := local[0] - surf^.texturemins[0];
    local[1] := local[1] - surf^.texturemins[1];

    for t := 0 to tmax - 1 do
    begin
      td := trunc(local[1] - t * 16);
      if (td < 0) then
        td := -td;

      for s := 0 to smax - 1 do
      begin
        sd := trunc(local[0] - s * 16);
        if (sd < 0) then
          sd := -sd;
        if (sd > td) then
          dist := sd + (td shr 1)
        else
          dist := td + (sd shr 1);
//====
//PGM
        if negativeLight = 0 then
          if (dist < minlight) then
            blocklights[t * smax + s] := blocklights[t * smax + s] + trunc((rad - dist) * 256)
          else
          begin
            if (dist < minlight) then
              blocklights[t * smax + s] := blocklights[t * smax + s] - trunc((rad - dist) * 256);
            if (blocklights[t * smax + s] < minlight) then
              blocklights[t * smax + s] := trunc(minlight);
          end;
//PGM
//====
      end;
    end;
  end;
end;

{
===============
R_BuildLightMap

Combine and scale multiple lightmaps into the 8.8 format in blocklights
===============
}

procedure R_BuildLightMap;
var
  smax: Integer;
  tmax: Integer;
  t: Integer;
  i: Integer;
  size: Integer;
  lightmap: PByte;
  scale: Cardinal;
  maps: Integer;
  surf: msurface_p;

begin
  surf := r_drawsurf.surf;

  smax := _SAR(surf^.extents[0], 4) + 1;
  tmax := _SAR(surf^.extents[1], 4) + 1;
  size := smax * tmax;

  if ((r_fullbright^.value <> 0.0) or (r_worldmodel^.lightdata = nil)) then
  begin
    for i := 0 to size - 1 do
      blocklights[i] := 0;
    exit;
  end;

// clear to no light
  for i := 0 to size - 1 do
    blocklights[i] := 0;

// add all the lightmaps
  lightmap := surf^.samples;
  if (lightmap <> nil) then
  begin
    maps := 0;
    while (maps < MAXLIGHTMAPS) and (surf^.styles[maps] <> 255) do
    begin
      scale := r_drawsurf.lightadj[maps]; // 8.8 fraction
      for i := 0 to size - 1 do
        blocklights[i] := blocklights[i] + (PByteArray(lightmap)^[i] * scale);
      Inc(Integer(lightmap), size); // skip to next lightmap
      Inc(maps);
    end;
  end;
// add all the dynamic lights
  if (surf^.dlightframe = r_framecount) then
    R_AddDynamicLights;

// bound, invert, and shift
  for i := 0 to size - 1 do
  begin
    t := Integer(blocklights[i]);
    if (t < 0) then
      t := 0;
    t := (255 * 256 - t) shr (8 - VID_CBITS);

    if (t < (1 shl 6)) then
      t := (1 shl 6);

    blocklights[i] := t;
  end;
end;

end.
