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
{ File(s): gl_draw.c                                                         }
{ Content: Quake2\ref_soft\ sound structures and constants                   }
{                                                                            }
{ Initial conversion by : Skaljac Bojan (Skaljac@Italy.Com)                  }
{ Initial conversion on : 18-Feb-2002                                        }
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
{ 28.06.2003 Juha: Proofreaded}
unit gl_draw;

interface

uses
  SysUtils,
  DelphiTypes,
  gl_local_add,
  gl_local;

procedure Draw_InitLocal;
function Draw_FindPic(name: PChar): pointer; cdecl;
procedure Draw_GetPicSize(w, h: PInteger; pic: PChar); cdecl;
procedure Draw_Pic(x, y: Integer; pic: PChar); cdecl;
procedure Draw_StretchPic(x, y, w, h: Integer; pic: PChar); cdecl;
procedure Draw_Char(x, y, num: Integer); cdecl;
procedure Draw_TileClear(x, y, w, h: Integer; pic: PChar); cdecl;
procedure Draw_Fill(x, y, w, h, c: Integer); cdecl;
procedure Draw_FadeScreen; cdecl;
procedure Draw_StretchRaw(x, y, w, h, cols, rows: Integer; data: PByte); cdecl;


var
  draw_chars: image_p;


implementation

uses
  OpenGL,
  q_shared,
  qgl_win,
  gl_rmain,
  gl_image;

{*
===============
Draw_InitLocal
===============
*}
procedure Draw_InitLocal;
begin
 // load console characters (don't bilerp characters)
  draw_chars := GL_FindImage('pics/conchars.pcx', it_pic);
  GL_Bind(draw_chars^.texnum);
  qglTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  qglTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
end;



{*
================
Draw_Char

Draws one 8*8 graphics character with 0 being transparent.
It can be clipped to the top of the screen to allow the console to be
smoothly scrolled off.
================
*}
procedure Draw_Char(x, y, num: Integer);
var
  row, col: Integer;
  frow, fcol, size: Single;
begin
  num := num and 255;

  if ((num and 127) = 32) then
    exit; // space

  if (y <= -8) then
    exit; // totally off screen

  row := num shr 4;
  col := num and 15;

  frow := row * 0.0625;
  fcol := col * 0.0625;
  size := 0.0625;

  GL_Bind(draw_chars^.texnum);

  qglBegin(GL_QUADS);
  qglTexCoord2f(fcol, frow);
  qglVertex2f(x, y);
  qglTexCoord2f(fcol + size, frow);
  qglVertex2f(x + 8, y);
  qglTexCoord2f(fcol + size, frow + size);
  qglVertex2f(x + 8, y + 8);
  qglTexCoord2f(fcol, frow + size);
  qglVertex2f(x, y + 8);
  qglEnd();
end;

{*
=============
Draw_FindPic
=============
*}
function Draw_FindPic(name: PChar): pointer;
var
  gl: image_p;
  fullname: array[0..MAX_QPATH - 1] of Char;
begin
  if ((name[0] <> '/') and (name[0] <> '\')) then
  begin
    Com_sprintf(fullname, sizeof(fullname), 'pics/%s.pcx', [name]);
    gl := GL_FindImage(fullname, it_pic);
  end
  else
    gl := GL_FindImage(name + 1, it_pic);

  Result := gl;
end;

{*
=============
Draw_GetPicSize
=============
*}
procedure Draw_GetPicSize(w, h: PInteger; pic: PChar);
var
  gl: image_p;
begin
  gl := Draw_FindPic(pic);
  if (gl = nil) then
  begin
    w^ := -1;
    h^ := -1;
    exit;
  end;
  w^ := gl^.width;
  h^ := gl^.height;
end;

{*
=============
Draw_StretchPic
=============
*}
procedure Draw_StretchPic(x, y, w, h: Integer; pic: PChar);
var
  gl: image_p;
begin
  gl := Draw_FindPic(pic);
  if (gl = nil) then
  begin
    ri.Con_Printf(PRINT_ALL, 'Can''t find pic: %s'#10, pic);
    exit;
  end;

  if (scrap_dirty) then
    Scrap_Upload;

  if (((gl_config.renderer = GL_RENDERER_MCD) or (gl_config.renderer and GL_RENDERER_RENDITION<>0)) and (not gl^.has_alpha)) then
    qglDisable(GL_ALPHA_TEST);

  GL_Bind(gl^.texnum);
  qglBegin(GL_QUADS);
  qglTexCoord2f(gl^.sl, gl^.tl);
  qglVertex2f(x, y);
  qglTexCoord2f(gl^.sh, gl^.tl);
  qglVertex2f(x + w, y);
  qglTexCoord2f(gl^.sh, gl^.th);
  qglVertex2f(x + w, y + h);
  qglTexCoord2f(gl^.sl, gl^.th);
  qglVertex2f(x, y + h);
  qglEnd;

  if (((gl_config.renderer = GL_RENDERER_MCD) or (gl_config.renderer and GL_RENDERER_RENDITION<>0)) and (not gl^.has_alpha)) then
    qglEnable(GL_ALPHA_TEST);
end;


{*
=============
Draw_Pic
=============
*}
procedure Draw_Pic(x, y: Integer; pic: PChar);
var
  gl: image_p;
begin
  gl := Draw_FindPic(pic);
  if (gl = nil) then
  begin
    ri.Con_Printf(PRINT_ALL, 'Can''t find pic: %s'#10, pic);
    exit;
  end;
  if (scrap_dirty) then
    Scrap_Upload;

  if (((gl_config.renderer = GL_RENDERER_MCD) or (gl_config.renderer and GL_RENDERER_RENDITION<>0)) and (not gl^.has_alpha)) then
    qglDisable(GL_ALPHA_TEST);

  GL_Bind(gl^.texnum);
  qglBegin(GL_QUADS);
  qglTexCoord2f(gl^.sl, gl^.tl);
  qglVertex2f(x, y);
  qglTexCoord2f(gl^.sh, gl^.tl);
  qglVertex2f(x + gl^.width, y);
  qglTexCoord2f(gl^.sh, gl^.th);
  qglVertex2f(x + gl^.width, y + gl^.height);
  qglTexCoord2f(gl^.sl, gl^.th);
  qglVertex2f(x, y + gl^.height);
  qglEnd;

  if (((gl_config.renderer = GL_RENDERER_MCD) or (gl_config.renderer and GL_RENDERER_RENDITION<>0)) and (not gl^.has_alpha)) then
    qglEnable(GL_ALPHA_TEST);
end;

{*
=============
Draw_TileClear

This repeats a 64*64 tile graphic to fill the screen around a sized down
refresh window.
=============
*}
procedure Draw_TileClear(x, y, w, h: Integer; pic: PChar);
var
  image: image_p;
begin
  image := Draw_FindPic(pic);
  if (image = nil) then
  begin
    ri.Con_Printf(PRINT_ALL, 'Can''t find pic: %s'#10, pic);
    exit;
  end;

  if (((gl_config.renderer = GL_RENDERER_MCD) or (gl_config.renderer and GL_RENDERER_RENDITION<>0)) and (not image^.has_alpha)) then
    qglDisable(GL_ALPHA_TEST);

  GL_Bind(image^.texnum);
  qglBegin(GL_QUADS);
  qglTexCoord2f(x / 64.0, y / 64.0);
  qglVertex2f(x, y);
  qglTexCoord2f((x + w) / 64.0, y / 64.0);
  qglVertex2f(x + w, y);
  qglTexCoord2f((x + w) / 64.0, (y + h) / 64.0);
  qglVertex2f(x + w, y + h);
  qglTexCoord2f(x / 64.0, (y + h) / 64.0);
  qglVertex2f(x, y + h);
  qglEnd;

  if (((gl_config.renderer = GL_RENDERER_MCD) or (gl_config.renderer and GL_RENDERER_RENDITION<>0)) and (not image^.has_alpha)) then
    qglEnable(GL_ALPHA_TEST);
end;


{*
=============
Draw_Fill

Fills a box of pixels with a single color
=============
*}
procedure Draw_Fill(x, y, w, h, c: Integer);
type
  Tcolor = record
    case boolean of
      true: (c: Cardinal);
      false: (v: array[0..3] of Byte);
  end;
var
  color: Tcolor;
begin
  if (Cardinal(c) > 255) then
    ri.Sys_Error(ERR_FATAL, 'Draw_Fill: bad color');

  qglDisable(GL_TEXTURE_2D);

  color.c := d_8to24table[c];
  qglColor3f(color.v[0] / 255,
    color.v[1] / 255,
    color.v[2] / 255);

  qglBegin(GL_QUADS);

  qglVertex2f(x, y);
  qglVertex2f(x + w, y);
  qglVertex2f(x + w, y + h);
  qglVertex2f(x, y + h);

  qglEnd;
  qglColor3f(1, 1, 1);
  qglEnable(GL_TEXTURE_2D);
end;

//=============================================================================

{*
================
Draw_FadeScreen

================
*}
procedure Draw_FadeScreen;
begin
  qglEnable(GL_BLEND);
  qglDisable(GL_TEXTURE_2D);
  qglColor4f(0, 0, 0, 0.8);
  qglBegin(GL_QUADS);

  qglVertex2f(0, 0);
  qglVertex2f(vid.width, 0);
  qglVertex2f(vid.width, vid.height);
  qglVertex2f(0, vid.height);

  qglEnd;
  qglColor4f(1, 1, 1, 1);
  qglEnable(GL_TEXTURE_2D);
  qglDisable(GL_BLEND);
end;


//====================================================================

{*
=============
Draw_StretchRaw
=============
*}
procedure Draw_StretchRaw(x, y, w, h, cols, rows: Integer; data: PByte);
var
  image32: array[0..(256 * 256) - 1] of Cardinal;
  image8: array[0..(256 * 256) - 1] of Byte;
  i, j, trows: Integer;
  source: PByte;
  frac, fracstep: Integer;
  hscale: Single;
  row: Integer;
  t: Single;
  dest: Pointer; //unsigned *name;
begin
  GL_Bind(0);

  if (rows <= 256) then
  begin
    hscale := 1;
    trows := rows;
  end
  else
  begin
    hscale := rows / 256.0;
    trows := 256;
  end;
  t := rows * hscale / 256;

  if (@qglColorTableEXT = nil) then
  begin
    for i := 0 to trows - 1 do
    begin
      row := Trunc(i * hscale);
      if (row > rows) then
        break;
      source := @PByteArray(data)^[cols * row];
      dest := @image32[i * 256];
      fracstep := cols * $10000 div 256;
      frac := fracstep shr 1;
      for j := 0 to 255 do
      begin
        PCardinalArray(dest)^[j] := r_rawpalette[PByteArray(source)^[frac shr 16]];
        frac := frac + fracstep;
      end;
    end;

    qglTexImage2D(GL_TEXTURE_2D, 0, gl_tex_solid_format, 256, 256, 0, GL_RGBA, GL_UNSIGNED_BYTE, @image32);
  end
  else
  begin
    //      unsigned char *dest;
    for i := 0 to trows - 1 do
    begin
      row := Trunc(i * hscale);
      if (row > rows) then
        break;
      source := @PByteArray(data)^[cols * row];
      dest := @image8[i * 256];
      fracstep := (cols * $10000) div 256;
      frac := fracstep shr 1;
      for j := 0 to 255 do
      begin
        PByteArray(dest)^[j] := PByteArray(source)^[frac shr 16];
        frac := frac + fracstep;
      end;
    end;

    qglTexImage2D(GL_TEXTURE_2D,
      0,
      GL_COLOR_INDEX8_EXT,
      256, 256,
      0,
      GL_COLOR_INDEX,
      GL_UNSIGNED_BYTE,
      @image8);
  end;
  qglTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  qglTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

  if ((gl_config.renderer = GL_RENDERER_MCD) or (gl_config.renderer and GL_RENDERER_RENDITION<>0)) then
    qglDisable(GL_ALPHA_TEST);

  qglBegin(GL_QUADS);
  qglTexCoord2f(0, 0);
  qglVertex2f(x, y);
  qglTexCoord2f(1, 0);
  qglVertex2f(x + w, y);
  qglTexCoord2f(1, t);
  qglVertex2f(x + w, y + h);
  qglTexCoord2f(0, t);
  qglVertex2f(x, y + h);
  qglEnd;

  if ((gl_config.renderer = GL_RENDERER_MCD) or (gl_config.renderer and GL_RENDERER_RENDITION<>0)) then
    qglEnable(GL_ALPHA_TEST);
end;



end.
