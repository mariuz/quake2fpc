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
{----------------------------------------------------------------------------}
{                                                                            }
{ File(s): r_misc.c                                                          }
{                                                                            }
{ Initial conversion by : YgriK (Igor Karpov) - glYgriK@hotbox.ru            }
{ Initial conversion on : 13-Feb-2002                                        }
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
{ Updated on : 22-July-2002                                                  }
{ Updated by : CodeFusion (Michael@Skovslund.dk)                             }
{ Updated on : 21-May-2003                                                   }
{ Updated by : Scott Price (scott.price@totalise.co.uk)                      }
{                                                                            }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{ None.                                                                      }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{ - Still some outstanding questions as to why some code is commented out    }
{----------------------------------------------------------------------------}

unit r_misc;

interface

uses
  q_shared,
  r_model,
  r_local;

const
  NUM_MIPS = 4;

var
  sw_mipcap: cvar_p;
  sw_mipscale: cvar_p;

  d_initial_rover: surfcache_p;
  d_roverwrapped: qboolean;
  d_minmip: Integer;
  d_scalemip: array[0..NUM_MIPS - 1 - 1] of Single;

{ extern int         d_aflatcolor; }

  d_vrectx: Integer;
  d_vrecty: Integer;
  d_vrectright_particle: Integer;
  d_vrectbottom_particle: Integer;

  d_pix_min: Integer;
  d_pix_max: Integer;
  d_pix_shift: Integer;

  d_scantable: array[0..MAXHEIGHT - 1] of Integer;
  zspantable: array[0..MAXHEIGHT - 1] of PSmallInt;

  alias_colormap: PByte;

procedure D_Patch;
procedure D_ViewChanged;
procedure R_PrintTimes;
procedure R_PrintDSpeeds;
procedure R_PrintAliasStats;
procedure R_TransformFrustum;
procedure TransformVector(_in: vec3_t; var _out: vec3_t);
//procedure TransformVector(_in, _out : vec3_t);
procedure R_TransformPlane(p: mplane_p; normal: PSingle; dist: PSingle);
procedure R_SetUpFrustumIndexes;
procedure R_ViewChanged(vr: vrect_p);
procedure R_SetupFrame;
procedure R_SurfacePatch;
procedure WritePCXfile(filename: PChar; data: PByte; width, height, rowbytes: Integer; palette: PByte);
procedure R_ScreenShot_f; cdecl;

implementation

uses
  { Borland Standard Units }
  Math,
  SysUtils,

  { Game Units }
  CPas,
  r_bsp_c,
  r_alias_c,
  r_edge,
  r_main,
  r_draw,
  q_shwin,
  r_rast,
  qfiles,
  r_surf,
  r_polyse;

var
  basemip: array[0..NUM_MIPS - 1 - 1] of Single = (1.0, 0.5 * 0.8, 0.25 * 0.8);
{$IFDEF id386}
  protectset8: qboolean = false;
{$ENDIF}

(*
================
D_Patch
================
*)

procedure D_Patch;
begin
{$IFDEF id386}
  if (not protectset8) then
  begin
// Asm code has been changed so it will not be self-modifying.
// As Delphi inline assembler cannot handle self-modifying code.
// Ask CodeFusion (see contacts above) if more information is required.
//============================================================================
//      Sys_MakeCodeWriteable((int)D_PolysetAff8Start,(int)D_Aff8Patch -
//                          (int)D_PolysetAff8Start);
//      Sys_MakeCodeWriteable ((long)R_Surf8Start,(long)R_Surf8End -
//                           (long)R_Surf8Start);
    protectset8 := true;
  end;
  colormap := vid.colormap;

  R_Surf8Patch;
  D_Aff8Patch;
{$ENDIF}
end;

(*
================
D_ViewChanged
================
*)

procedure D_ViewChanged;
var
  I: Integer;
begin
  scale_for_mip := xscale;
  if (yscale > xscale) then
    scale_for_mip := yscale;

  d_zrowbytes := vid.width * 2;
  d_zwidth := vid.width;

  d_pix_min := r_refdef.vrect.width div 320;
  if (d_pix_min < 1) then
    d_pix_min := 1;

  d_pix_max := Trunc(r_refdef.vrect.width / (320.0 / 4.0) + 0.5);
  d_pix_shift := 8 - Trunc(r_refdef.vrect.width / 320.0 + 0.5);
  if (d_pix_max < 1) then
    d_pix_max := 1;

  d_vrectx := r_refdef.vrect.x;
  d_vrecty := r_refdef.vrect.y;
  d_vrectright_particle := r_refdef.vrectright - d_pix_max;
  d_vrectbottom_particle := r_refdef.vrectbottom - d_pix_max;

  for I := 0 to vid.height - 1 do
  begin
    d_scantable[i] := i * r_screenwidth;
    zspantable[i] := PSmallInt(Integer(d_pzbuffer) + ((i * Integer(d_zwidth)) * SizeOf(SmallInt)));
  end;

  (*
  ** clear Z-buffer and color-buffers if we're doing the gallery
  *)
  if (r_newrefdef.rdflags and RDF_NOWORLDMODEL) <> 0 then
  begin
    memset(d_pzbuffer, vid.width * vid.height * SizeOf(SmallInt), $FF);
    Draw_Fill(r_newrefdef.x, r_newrefdef.y, r_newrefdef.width, r_newrefdef.height, Trunc(sw_clearcolor^.value) and $FF);
  end;
  alias_colormap := vid.colormap;
  D_Patch;
end;

(*
=============
R_PrintTimes
=============
*)

procedure R_PrintTimes;
var
  r_time2: Integer;
  ms: Integer;
begin
  r_time2 := Sys_Milliseconds;

  ms := r_time2 - Trunc(r_time1);
  ri.Con_Printf(PRINT_ALL,'%5d ms %3d/%3d/%3d poly %3d surf', ms, c_faceclip, r_polycount, r_drawnpolycount, c_surf);
  c_surf := 0;
end;

(*
=============
R_PrintDSpeeds
=============
*)

procedure R_PrintDSpeeds;
var
  ms: Integer;
  dp_time: Integer;
  r_time2: Integer;
  rw_time: Integer;
  db_time: Integer;
  se_time: Integer;
  de_time: Integer;
  da_time: Integer;
begin
  r_time2 := Sys_Milliseconds;

  da_time := Trunc(da_time2 - da_time1);
  dp_time := Trunc(dp_time2 - dp_time1);
  rw_time := Trunc(rw_time2 - rw_time1);
  db_time := Trunc(db_time2 - db_time1);
  se_time := Trunc(se_time2 - se_time1);
  de_time := Trunc(de_time2 - de_time1);
  ms := (r_time2 - Trunc(r_time1));

  ri.Con_Printf(PRINT_ALL, '%3d %2dp %2dw %2db %2ds %2de %2da', ms, dp_time, rw_time, db_time, se_time, de_time, da_time);
end;

(*
=============
R_PrintAliasStats
=============
*)

procedure R_PrintAliasStats;
begin
   ri.Con_Printf(PRINT_ALL,'%d polygon model drawn', r_amodels_drawn);
end;

(*
===================
R_TransformFrustum
===================
*)

procedure R_TransformFrustum;
var
  i: Integer;
  v: vec3_t;
  v2: vec3_t;
begin
  for I := 0 to 3 do
  begin
    v[0] := screenedge[i].normal[2];
    v[1] := -screenedge[i].normal[0];
    v[2] := screenedge[i].normal[1];

    v2[0] := v[1] * vright[0] + v[2] * vup[0] + v[0] * vpn[0];
    v2[1] := v[1] * vright[1] + v[2] * vup[1] + v[0] * vpn[1];
    v2[2] := v[1] * vright[2] + v[2] * vup[2] + v[0] * vpn[2];

    VectorCopy(v2, view_clipplanes[i].normal);

    view_clipplanes[i].dist := DotProduct(modelorg, v2);
  end;
end;

(*
================
TransformVector
================
*)
{ #if !(defined __linux__ && defined __i386__)  // <<--  To Convert}

procedure TransformVector(_in: vec3_t; var _out: vec3_t);
{$IFNDEF id386}
begin
  { 2003-05-21 (SP):  Is this a complete conversion replacement? }
  _out[0] := DotProduct(_in, vright);
  _out[1] := DotProduct(_in, vup);
  _out[2] := DotProduct(_in, vpn);
end;
{$ELSE}
{ DELPHI TODO: put asm code here! }
asm
end;
{$ENDIF}

(*
================
R_TransformPlane
================
*)

procedure R_TransformPlane(p: mplane_p; normal: PSingle; dist: PSingle);
var
  d: Single;
begin
  d := DotProduct(r_origin, p^.normal);
  dist^ := p^.dist - d;
// TODO: when we have rotating entities, this will need to use the view matrix
   TransformVector(p^.normal, vec3_p(normal)^);
// OLD line (CodeFusion):  TransformVector(p^.normal, vec3_p(@normal)^);
end;

(*
===============
R_SetUpFrustumIndexes
===============
*)

procedure R_SetUpFrustumIndexes;
var
  i, j: Integer;
  pindex: PInteger;
begin
  pindex := @r_frustum_indexes;

  for I := 0 to 3 do
  begin
    for j := 0 to 2 do
    begin
      { 2003-05-21 (SP):  Not sure about these conversions below }
      if (view_clipplanes[i].normal[j] < 0) then
      begin
        PInteger(Integer(pindex) + (j * SizeOf(Integer)))^ := j;
        PInteger(Integer(pindex) + ((j + 3) * SizeOf(Integer)))^ := j + 3;
      end
      else
      begin
        PInteger(Integer(pindex) + (j * SizeOf(Integer)))^ := j + 3;
        PInteger(Integer(pindex) + ((j + 3) * SizeOf(Integer)))^ := j;
      end;
    end;

  // FIXME: do just once at start
    pfrustum_indexes[i] := pindex;
    { 2003-05-21 (SP):  Not sure about this conversions below }
    Inc(Integer(pindex), 6 * SizeOf(Integer));
  end;
end;

(*
===============
R_ViewChanged

Called every time the vid structure or r_refdef changes.
Guaranteed to be called before the first refresh
===============
*)

procedure R_ViewChanged(vr: vrect_p);
var
  i: Integer;
begin
  r_refdef.vrect := vr^;

  r_refdef.horizontalFieldOfView := 2 * tan(r_newrefdef.fov_x / 360 * M_PI);
  verticalFieldOfView := 2 * tan(r_newrefdef.fov_y / 360 * M_PI);

  r_refdef.fvrectx := r_refdef.vrect.x;
  r_refdef.fvrectx_adj := r_refdef.vrect.x - 0.5;
  r_refdef.vrect_x_adj_shift20 := (r_refdef.vrect.x shl 20) + (1 shl 19) - 1;
  r_refdef.fvrecty := r_refdef.vrect.y;
  r_refdef.fvrecty_adj := r_refdef.vrect.y - 0.5;
  r_refdef.vrectright := r_refdef.vrect.x + r_refdef.vrect.width;
  r_refdef.vrectright_adj_shift20 := (r_refdef.vrectright shl 20) + (1 shl 19) - 1;
  r_refdef.fvrectright := r_refdef.vrectright;
  r_refdef.fvrectright_adj := r_refdef.vrectright - 0.5;
  r_refdef.vrectrightedge := r_refdef.vrectright - 0.99;
  r_refdef.vrectbottom := r_refdef.vrect.y + r_refdef.vrect.height;
  r_refdef.fvrectbottom := r_refdef.vrectbottom;
  r_refdef.fvrectbottom_adj := r_refdef.vrectbottom - 0.5;

  r_refdef.aliasvrect.x := Trunc(r_refdef.vrect.x * r_aliasuvscale);
  r_refdef.aliasvrect.y := Trunc(r_refdef.vrect.y * r_aliasuvscale);
  r_refdef.aliasvrect.width := Trunc(r_refdef.vrect.width * r_aliasuvscale);
  r_refdef.aliasvrect.height := Trunc(r_refdef.vrect.height * r_aliasuvscale);
  r_refdef.aliasvrectright := r_refdef.aliasvrect.x + r_refdef.aliasvrect.width;
  r_refdef.aliasvrectbottom := r_refdef.aliasvrect.y + r_refdef.aliasvrect.height;

  xOrigin := r_refdef.xOrigin;
  yOrigin := r_refdef.yOrigin;

// values for perspective projection
// if math were exact, the values would range from 0.5 to to range+0.5
// hopefully they wll be in the 0.000001 to range+.999999 and truncate
// the polygon rasterization will never render in the first row or column
// but will definately render in the [range] row and column, so adjust the
// buffer origin to get an exact edge to edge fill
  xcenter := (r_refdef.vrect.width * XCENTERING) + r_refdef.vrect.x - 0.5;
  aliasxcenter := xcenter * r_aliasuvscale;
  ycenter := (r_refdef.vrect.height * YCENTERING) + r_refdef.vrect.y - 0.5;
  aliasycenter := ycenter * r_aliasuvscale;

  xscale := r_refdef.vrect.width / r_refdef.horizontalFieldOfView;
  aliasxscale := xscale * r_aliasuvscale;
  xscaleinv := 1.0 / xscale;

  yscale := xscale;
  aliasyscale := yscale * r_aliasuvscale;
  yscaleinv := 1.0 / yscale;
  xscaleshrink := (r_refdef.vrect.width - 6) / r_refdef.horizontalFieldOfView;
  yscaleshrink := xscaleshrink;

// left side clip
  screenedge[0].normal[0] := -1.0 / (xOrigin * r_refdef.horizontalFieldOfView);
  screenedge[0].normal[1] := 0;
  screenedge[0].normal[2] := 1;
  screenedge[0]._type := PLANE_ANYZ;

// right side clip
  screenedge[1].normal[0] := 1.0 / ((1.0 - xOrigin) * r_refdef.horizontalFieldOfView);
  screenedge[1].normal[1] := 0;
  screenedge[1].normal[2] := 1;
  screenedge[1]._type := PLANE_ANYZ;

// top side clip
  screenedge[2].normal[0] := 0;
  screenedge[2].normal[1] := -1.0 / (yOrigin * verticalFieldOfView);
  screenedge[2].normal[2] := 1;
  screenedge[2]._type := PLANE_ANYZ;

// bottom side clip
  screenedge[3].normal[0] := 0;
  screenedge[3].normal[1] := 1.0 / ((1.0 - yOrigin) * verticalFieldOfView);
  screenedge[3].normal[2] := 1;
  screenedge[3]._type := PLANE_ANYZ;

  for i := 0 to 3 do
    VectorNormalize(screenedge[i].normal);

  D_ViewChanged;
end;

(*
===============
R_SetupFrame
===============
*)

procedure R_SetupFrame;
var
  i: Integer;
  vrect: vrect_t;
begin
  if (r_fullbright^.modified) then
  begin
    r_fullbright^.modified := false;
    D_FlushCaches; // so all lighting changes
  end;

  Inc(r_framecount);

// build the transformation matrix for the given view angles
  VectorCopy(r_refdef.vieworg, modelorg);
  VectorCopy(r_refdef.vieworg, r_origin);

  AngleVectors(r_refdef.viewangles, @vpn, @vright, @vup);

// current viewleaf
  if ((r_newrefdef.rdflags and RDF_NOWORLDMODEL) = 0) then
  begin
    r_viewleaf := Mod_PointInLeaf(r_origin, r_worldmodel);
    r_viewcluster := r_viewleaf^.cluster;
  end;

  if ((sw_waterwarp^.value <> 0) and ((r_newrefdef.rdflags and RDF_UNDERWATER) <> 0)) then
    r_dowarp := true
  else
    r_dowarp := false;

  if (r_dowarp) then
  begin // warp into off screen buffer
    vrect.x := 0;
    vrect.y := 0;

    if r_newrefdef.width < WARP_WIDTH then
      vrect.width := r_newrefdef.width
    else
      vrect.width := WARP_WIDTH;

    if r_newrefdef.height < WARP_HEIGHT then
      vrect.height := r_newrefdef.height
    else
      vrect.height := WARP_HEIGHT;

    d_viewbuffer := @r_warpbuffer;
    r_screenwidth := WARP_WIDTH;
  end
  else
  begin
    vrect.x := r_newrefdef.x;
    vrect.y := r_newrefdef.y;
    vrect.width := r_newrefdef.width;
    vrect.height := r_newrefdef.height;

    d_viewbuffer := vid.buffer;
    r_screenwidth := vid.rowbytes;
  end;

  R_ViewChanged(@vrect);

// start off with just the four screen edge clip planes
  R_TransformFrustum;
  R_SetUpFrustumIndexes;

// save base values
  VectorCopy(vpn, base_vpn);
  VectorCopy(vright, base_vright);
  VectorCopy(vup, base_vup);

// clear frame counts
  c_faceclip := 0;
  d_spanpixcount := 0;
  r_polycount := 0;
  r_drawnpolycount := 0;
  r_wholepolycount := 0;
  r_amodels_drawn := 0;
  r_outofsurfaces := 0;
  r_outofedges := 0;

// d_setup
  d_roverwrapped := false;
  d_initial_rover := sc_rover;

  d_minmip := Trunc(sw_mipcap^.value);
  if (d_minmip > 3) then
    d_minmip := 3
  else
    if (d_minmip < 0) then
      d_minmip := 0;

  for I := 0 to NUM_MIPS - 2 do
    d_scalemip[i] := basemip[i] * sw_mipscale^.value;

  d_aflatcolor := 0;
end;

{$IFNDEF id386}
(*
================
R_SurfacePatch
================
*)

procedure R_SurfacePatch;
begin
 // we only patch code on Intel
end;
{$ENDIF}

(*
==============================================================================

      SCREEN SHOTS

==============================================================================
*)

(*
==============
WritePCXfile
==============
*)

procedure WritePCXfile(filename: PChar; data: PByte; width, height,
  rowbytes: Integer; palette: PByte);
var
  i, j, length: Integer;
  pcx: pcx_p;
  pack: PByte;
  f: Integer; // was File;
begin
  //pcx := AllocMem(width*height*2+1000);
  pcx := pcx_p(malloc(width * height * 2 + 1000)); // changed by fab
  if (pcx = nil) then
    Exit;

  pcx^.manufacturer := #$0A; // PCX id
  pcx^.version := #5; // 256 color
  pcx^.encoding := #1; // uncompressed
  pcx^.bits_per_pixel := #8; // 256 color
  pcx^.xmin := 0;
  pcx^.ymin := 0;
  pcx^.xmax := LittleShort(width - 1);
  pcx^.ymax := LittleShort(height - 1);
  pcx^.hres := LittleShort(width);
  pcx^.vres := LittleShort(height);
  //FillChar(pcx^.palette,SizeOf(pcx^.palette),0);
  memset(@pcx^.palette, 0, SizeOf(pcx^.palette)); //changed by fab
  pcx^.color_planes := 1; // chunky image
  pcx^.bytes_per_line := LittleShort(width);
  pcx^.palette_type := LittleShort(2); // not a grey scale
  //FillChar(pcx^.filler,SizeOf(pcx^.filler),0);
  memset(@pcx^.filler, 0, SizeOf(pcx^.filler)); //changed by fab

  // pack the image
  pack := @pcx^.data;

  for I := 0 to height - 1 do
  begin
    for j := 0 to width - 1 do
    begin
      if ((data^ and $C0) <> $C0) then
      begin
        pack^ := data^;

        Inc(Integer(pack));

        Inc(Integer(data));
      end
      else
      begin
        pack^ := $C1;

        Inc(Integer(pack));
        pack^ := data^;

        Inc(Integer(pack));

        Inc(Integer(data));
      end;
    end;

    Inc(Integer(data), rowbytes - width);
  end;

  // write the palette
  pack^ := $0C; // palette ID byte
  Inc(Integer(pack));

  for i := 0 to 768 - 1 do
  begin
    pack^ := palette^;

    Inc(Integer(pack));
    Inc(Integer(palette));
  end;

  // write output file
  length := Integer(pack) - Integer(pcx);

  f := FileCreate(filename);
  if f < 0 then
    ri.Con_Printf(PRINT_ALL, 'Failed to create  %s'#10, filename) //changed by Fab
  else
  begin
    FileWrite(f, pcx^, length);
    FileClose(f);
  end;

  FreeMem(pcx);
end;

procedure R_ScreenShot_f; cdecl;
var
  i: integer;
  pcxname: array[0..80 - 1] of Char;
  checkname: array[0..MAX_OSPATH - 1] of Char;
  palette: array[0..768 - 1] of Byte;
  f: Integer;
begin
  // create the scrnshots directory if it doesn't exist
  Com_sprintf(checkname, SizeOf(checkname), '%s/scrnshot', [ri.FS_Gamedir]);
  MkDir(checkname);
  //
  // find a file name to save it to
  //
  strcpy(pcxname, 'quake00.pcx');

  for i := 0 to 99 do
  begin

    pcxname[5] := Char(i div 10 + Byte('0'));
    pcxname[6] := Char(i mod 10 + Byte('0'));
    Com_sprintf(checkname, sizeof(checkname), '%s/scrnshot/%s', [ri.FS_Gamedir, pcxname]);

    f := fileOpen(checkname, fmOpenRead);
    if f < 0 then
      Break; // file doesn't exist
    Fileclose(f);
  end;
  if i = 100 then
  begin
    ri.Con_Printf(PRINT_ALL, 'R_ScreenShot_f: Couldn''t create a PCX'#10);
    exit;
  end;
  // turn the current 32 bit palette into a 24 bit palette
  for i := 0 to 255 do
  begin
    palette[i * 3 + 0] := sw_state.currentpalette[i * 4 + 0];
    palette[i * 3 + 1] := sw_state.currentpalette[i * 4 + 1];
    palette[i * 3 + 2] := sw_state.currentpalette[i * 4 + 2];
  end;

  //
  // save the pcx file
  //

  WritePCXfile(checkname, vid.buffer, vid.width, vid.height, vid.rowbytes, @palette);

  ri.Con_Printf(PRINT_ALL, 'Wrote %s'#10, checkname);
end;

end.
