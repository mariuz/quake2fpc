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

unit r_aclip;
{----------------------------------------------------------------------------}
{                                                                            }
{ File(s): r_aclip.c                                                         }
{ Content: Quake2\rep_soft\ clipping routines                                }
{                                                                            }
{ Initial conversion by : Massimo Soricetti (max-67@libero.it)               }
{ Initial conversion on : 09-Jan-2002                                        }
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
{ Updated on : 19-July-2002                                                  }
{ Updated by : CodeFusion (Michael@Skovslund.dk)                             }
{ 27-Marts-2003 - CodeFusion, corrected conv. error in R_AliasClip           }
{                                                                            }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{ none                                                                       }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{ proofread: ok.                                                             }
{ none                                                                       }
{----------------------------------------------------------------------------}

interface

uses
  r_local;

procedure R_AliasClipTriangle(index0, index1, index2: finalvert_p);

implementation

uses
  r_main,
  r_alias_c,
  r_polyse;

type
  TProcPfvt_3 = procedure(pfv0, pfv1, _out: finalvert_p);

var
  fv: array[0..1, 0..7] of finalvert_t;

{
================
R_Alias_clip_z

pfv0 is the unclipped vertex, pfv1 is the z-clipped vertex
================
}

procedure R_Alias_clip_z(pfv0, pfv1, _out: finalvert_p);
var
  scale: Single;
begin
  scale := (ALIAS_Z_CLIP_PLANE - pfv0^.xyz[2]) / (pfv1^.xyz[2] - pfv0^.xyz[2]);

  _out^.xyz[0] := pfv0^.xyz[0] + (pfv1^.xyz[0] - pfv0^.xyz[0]) * scale;
  _out^.xyz[1] := pfv0^.xyz[1] + (pfv1^.xyz[1] - pfv0^.xyz[1]) * scale;
  _out^.xyz[2] := ALIAS_Z_CLIP_PLANE;

  _out^.s := Trunc(pfv0^.s + (pfv1^.s - pfv0^.s) * scale);
  _out^.t := Trunc(pfv0^.t + (pfv1^.t - pfv0^.t) * scale);
  _out^.l := Trunc(pfv0^.l + (pfv1^.l - pfv0^.l) * scale);
  R_AliasProjectAndClipTestFinalVert(_out);
end;

{$IFNDEF   id386}

procedure R_Alias_clip_left(pfv0, pfv1, _out: finalvert_p);
var
  scale: Single;
begin
  if (pfv0^.v >= pfv1^.v) then
  begin
    scale := (r_refdef.aliasvrect.x - pfv0^.u) / (pfv1^.u - pfv0^.u);
    _out^.u := Trunc(pfv0^.u + (pfv1^.u - pfv0^.u) * scale + 0.5);
    _out^.v := Trunc(pfv0^.v + (pfv1^.v - pfv0^.v) * scale + 0.5);
    _out^.s := Trunc(pfv0^.s + (pfv1^.s - pfv0^.s) * scale + 0.5);
    _out^.t := Trunc(pfv0^.t + (pfv1^.t - pfv0^.t) * scale + 0.5);
    _out^.l := Trunc(pfv0^.l + (pfv1^.l - pfv0^.l) * scale + 0.5);
    _out^.zi := Trunc(pfv0^.zi + (pfv1^.zi - pfv0^.zi) * scale + 0.5);
  end
  else
  begin
    scale := (r_refdef.aliasvrect.x - pfv1^.u) / (pfv0^.u - pfv1^.u);
    _out^.u := Trunc(pfv1^.u + (pfv0^.u - pfv1^.u) * scale + 0.5);
    _out^.v := Trunc(pfv1^.v + (pfv0^.v - pfv1^.v) * scale + 0.5);
    _out^.s := Trunc(pfv1^.s + (pfv0^.s - pfv1^.s) * scale + 0.5);
    _out^.t := Trunc(pfv1^.t + (pfv0^.t - pfv1^.t) * scale + 0.5);
    _out^.l := Trunc(pfv1^.l + (pfv0^.l - pfv1^.l) * scale + 0.5);
    _out^.zi := Trunc(pfv1^.zi + (pfv0^.zi - pfv1^.zi) * scale + 0.5);
  end;
end;

procedure R_Alias_clip_right(pfv0, pfv1, _out: finalvert_p);
var
  scale: Single;
begin
  if (pfv0^.v >= pfv1^.v) then
  begin
    scale := (r_refdef.aliasvrectright - pfv0^.u) / (pfv1^.u - pfv0^.u);
    _out^.u := Trunc(pfv0^.u + (pfv1^.u - pfv0^.u) * scale + 0.5);
    _out^.v := Trunc(pfv0^.v + (pfv1^.v - pfv0^.v) * scale + 0.5);
    _out^.s := Trunc(pfv0^.s + (pfv1^.s - pfv0^.s) * scale + 0.5);
    _out^.t := Trunc(pfv0^.t + (pfv1^.t - pfv0^.t) * scale + 0.5);
    _out^.l := Trunc(pfv0^.l + (pfv1^.l - pfv0^.l) * scale + 0.5);
    _out^.zi := Trunc(pfv0^.zi + (pfv1^.zi - pfv0^.zi) * scale + 0.5);
  end
  else
  begin
    scale := (r_refdef.aliasvrectright - pfv1^.u) / (pfv0^.u - pfv1^.u);
    _out^.u := Trunc(pfv1^.u + (pfv0^.u - pfv1^.u) * scale + 0.5);
    _out^.v := Trunc(pfv1^.v + (pfv0^.v - pfv1^.v) * scale + 0.5);
    _out^.s := Trunc(pfv1^.s + (pfv0^.s - pfv1^.s) * scale + 0.5);
    _out^.t := Trunc(pfv1^.t + (pfv0^.t - pfv1^.t) * scale + 0.5);
    _out^.l := Trunc(pfv1^.l + (pfv0^.l - pfv1^.l) * scale + 0.5);
    _out^.zi := Trunc(pfv1^.zi + (pfv0^.zi - pfv1^.zi) * scale + 0.5);
  end;
end;

procedure R_Alias_clip_top(pfv0, pfv1, _out: finalvert_p);
var
  scale: Single;
begin
  if (pfv0^.v >= pfv1^.v) then
  begin
    scale := (r_refdef.aliasvrect.y - pfv0^.v) / (pfv1^.v - pfv0^.v);
    _out^.u := Trunc(pfv0^.u + (pfv1^.u - pfv0^.u) * scale + 0.5);
    _out^.v := Trunc(pfv0^.v + (pfv1^.v - pfv0^.v) * scale + 0.5);
    _out^.s := Trunc(pfv0^.s + (pfv1^.s - pfv0^.s) * scale + 0.5);
    _out^.t := Trunc(pfv0^.t + (pfv1^.t - pfv0^.t) * scale + 0.5);
    _out^.l := Trunc(pfv0^.l + (pfv1^.l - pfv0^.l) * scale + 0.5);
    _out^.zi := Trunc(pfv0^.zi + (pfv1^.zi - pfv0^.zi) * scale + 0.5);
  end
  else
  begin
    scale := (r_refdef.aliasvrect.y - pfv1^.v) / (pfv0^.v - pfv1^.v);
    _out^.u := Trunc(pfv1^.u + (pfv0^.u - pfv1^.u) * scale + 0.5);
    _out^.v := Trunc(pfv1^.v + (pfv0^.v - pfv1^.v) * scale + 0.5);
    _out^.s := Trunc(pfv1^.s + (pfv0^.s - pfv1^.s) * scale + 0.5);
    _out^.t := Trunc(pfv1^.t + (pfv0^.t - pfv1^.t) * scale + 0.5);
    _out^.l := Trunc(pfv1^.l + (pfv0^.l - pfv1^.l) * scale + 0.5);
    _out^.zi := Trunc(pfv1^.zi + (pfv0^.zi - pfv1^.zi) * scale + 0.5);
  end;
end;

procedure R_Alias_clip_bottom(pfv0, pfv1, _out: finalvert_p);
var
  scale: Single;
begin
  if (pfv0^.v >= pfv1^.v) then
  begin
    scale := (r_refdef.aliasvrectbottom - pfv0^.v) / (pfv1^.v - pfv0^.v);
    _out^.u := Trunc(pfv0^.u + (pfv1^.u - pfv0^.u) * scale + 0.5);
    _out^.v := Trunc(pfv0^.v + (pfv1^.v - pfv0^.v) * scale + 0.5);
    _out^.s := Trunc(pfv0^.s + (pfv1^.s - pfv0^.s) * scale + 0.5);
    _out^.t := Trunc(pfv0^.t + (pfv1^.t - pfv0^.t) * scale + 0.5);
    _out^.l := Trunc(pfv0^.l + (pfv1^.l - pfv0^.l) * scale + 0.5);
    _out^.zi := Trunc(pfv0^.zi + (pfv1^.zi - pfv0^.zi) * scale + 0.5);
  end
  else
  begin
    scale := (r_refdef.aliasvrectbottom - pfv1^.v) / (pfv0^.v - pfv1^.v);
    _out^.u := Trunc(pfv1^.u + (pfv0^.u - pfv1^.u) * scale + 0.5);
    _out^.v := Trunc(pfv1^.v + (pfv0^.v - pfv1^.v) * scale + 0.5);
    _out^.s := Trunc(pfv1^.s + (pfv0^.s - pfv1^.s) * scale + 0.5);
    _out^.t := Trunc(pfv1^.t + (pfv0^.t - pfv1^.t) * scale + 0.5);
    _out^.l := Trunc(pfv1^.l + (pfv0^.l - pfv1^.l) * scale + 0.5);
    _out^.zi := Trunc(pfv1^.zi + (pfv0^.zi - pfv1^.zi) * scale + 0.5);
  end;
end;

{$ENDIF}

function R_AliasClip(_in, _out: finalvert_p; flag, count: integer; clip: TProcPfvt_3): Integer;
var
  i, j, k   : Integer;
  flags     : Integer;
  oldflags  : Integer;
  _in_arr   : finalvert_arrp;
  _out_arr  : finalvert_arrp;
begin
  j := count - 1;
  k := 0;
  _in_arr := finalvert_arrp(_in);
  _out_arr := finalvert_arrp(_out);
  for i := 0 to count-1 do
  begin
      oldflags := _in_arr^[j].flags and flag;
      flags := _in_arr^[i].flags and flag;
      if (flags and oldflags) <> 0 then
    begin
      j := i;
         continue;
    end;
    if (oldflags xor flags) <> 0 then
    begin
        clip(@_in_arr[j], @_in_arr[i], @_out_arr[k]);
      _out_arr^[k].flags := 0;
      if _out_arr^[k].u < r_refdef.aliasvrect.x then
        _out_arr^[k].flags := _out_arr^[k].flags or ALIAS_LEFT_CLIP;
      if _out_arr^[k].v < r_refdef.aliasvrect.y then
        _out_arr^[k].flags := _out_arr^[k].flags or ALIAS_TOP_CLIP;
      if _out_arr^[k].u > r_refdef.aliasvrectright then
        _out_arr^[k].flags := _out_arr^[k].flags or ALIAS_RIGHT_CLIP;
      if _out_arr^[k].v > r_refdef.aliasvrectbottom then
        _out_arr^[k].flags := _out_arr^[k].flags or ALIAS_BOTTOM_CLIP;
      Inc(k);
    end;
    if flags = 0 then
    begin
      _out_arr^[k] := _in_arr^[i];
      Inc(k);
    end;
    j := i;
  end;
  Result := k;
end;

{
================
R_AliasClipTriangle
================
}

procedure R_AliasClipTriangle(index0, index1, index2: finalvert_p);
var
  i, k: Integer;
  pingpong: Integer;
  clipflags: Cardinal;
begin
// copy vertexes and fix seam texture coordinates
  FillChar(fv, SizeOf(fv), 0);
  fv[0, 0] := index0^;
  fv[0, 1] := index1^;
  fv[0, 2] := index2^;

// clip
  clipflags := (fv[0, 0].flags or fv[0, 1].flags or fv[0, 2].flags);

  if (clipflags and ALIAS_Z_CLIP) <> 0 then
  begin
    k := R_AliasClip(@fv[0,0], @fv[1,0], ALIAS_Z_CLIP, 3, R_Alias_clip_z);
    if k = 0 then
      Exit;
    pingpong := 1;
    clipflags := (fv[1, 0].flags or fv[1, 1].flags or fv[1, 2].flags);
  end
  else
  begin
    pingpong := 0;
    k := 3;
  end;

  if (clipflags and ALIAS_LEFT_CLIP) <> 0 then
  begin
    k := R_AliasClip(@fv[pingpong,0], @fv[pingpong xor 1,0], ALIAS_LEFT_CLIP, k, R_Alias_clip_left);
    if k = 0 then
      Exit;
    pingpong := pingpong xor 1;
  end;

  if (clipflags and ALIAS_RIGHT_CLIP) <> 0 then
  begin
    k := R_AliasClip(@fv[pingpong,0], @fv[pingpong xor 1,0], ALIAS_RIGHT_CLIP, k, R_Alias_clip_right);
    if (k = 0) then
      Exit;
    pingpong := pingpong xor 1;
  end;

  if (clipflags and ALIAS_BOTTOM_CLIP) <> 0 then
  begin
    k := R_AliasClip(@fv[pingpong,0], @fv[pingpong xor 1,0], ALIAS_BOTTOM_CLIP, k, R_Alias_clip_bottom);
    if (k = 0) then
      Exit;
    pingpong := pingpong xor 1;
  end;

  if (clipflags and ALIAS_TOP_CLIP) <> 0 then
  begin
    k := R_AliasClip(@fv[pingpong,0], @fv[pingpong xor 1,0], ALIAS_TOP_CLIP, k, R_Alias_clip_top);
    if k = 0 then
      Exit;
    pingpong := pingpong xor 1;
  end;

  for i := 0 to k - 1 do
  begin
    if fv[pingpong, i].u < r_refdef.aliasvrect.x then
      fv[pingpong, i].u := r_refdef.aliasvrect.x
    else
      if fv[pingpong, i].u > r_refdef.aliasvrectright then
        fv[pingpong, i].u := r_refdef.aliasvrectright;

    if fv[pingpong, i].v < r_refdef.aliasvrect.y then
      fv[pingpong, i].v := r_refdef.aliasvrect.y
    else
      if fv[pingpong, i].v > r_refdef.aliasvrectbottom then
        fv[pingpong, i].v := r_refdef.aliasvrectbottom;

    fv[pingpong, i].flags := 0;
  end;

// draw triangles
  for i := 1 to k - 2 do
  begin
    aliastriangleparms.a := @fv[pingpong, 0];
    aliastriangleparms.b := @fv[pingpong, i];
    aliastriangleparms.c := @fv[pingpong, i + 1];
    R_DrawTriangle;
  end;
end;

end.
