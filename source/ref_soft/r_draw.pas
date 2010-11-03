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
{$ALIGN 8}{$MINENUMSIZE 4}
{----------------------------------------------------------------------------}
{                                                                            }
{ File(s): r_draw.c                                                          }
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
{ Updated on : 24-Feb-2002                                                   }
{ Updated by : Carl Kenner (carl_kenner@hotmail.com)                         }
{                                                                            }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{ Fix all the bugs                                                           }
{ 1)                                                                         }
{ 2)                                                                         }
{----------------------------------------------------------------------------}

// draw.c

unit r_draw;

{$DEFINE _NODEPEND}

interface

uses
  r_main,
  r_model,
  r_local,
  r_image,
  q_shared;

procedure Draw_FadeScreen; cdecl;
procedure Draw_Char(x, y, num: integer); cdecl;
procedure Draw_GetPicSize(w, h: PInteger; pic: Pchar); cdecl;
procedure Draw_StretchPic(x, y, w, h: integer; name: Pchar); cdecl;
procedure Draw_StretchRaw(x, y, w, h, cols, rows: integer; data: PByte); cdecl; // CAK - ^byte to PByte
procedure Draw_Pic(x, y: integer; name: Pchar); cdecl;
procedure Draw_TileClear(x, y, w, h: integer; name: Pchar); cdecl;
procedure Draw_Fill(x, y, w, h, c: integer); cdecl;
function Draw_FindPic(name: Pchar): Pointer; cdecl;
procedure Draw_InitLocal; cdecl;

//=============================================================================

implementation

uses
  SysUtils;

type
  cByteArr = array[0..MaxInt - 1] of byte;
  cPtrByte = ^cByteArr;

var // CAK - made a var, changed to pointer type
  draw_chars: image_p; // 8*8 graphic characters

{
================
Draw_FindPic
================
}

function Draw_FindPic(name: Pchar): Pointer; cdecl;
var
  image: image_p;
  fullname: array[0..MAX_QPATH - 1] of char; // CAK - Array of char NOT PCHAR !!!

begin
  if (name^ <> '/') and (name^ <> '\') then // CAK - '\\' is C for '\'
  begin
    Com_sprintf(fullname, MAX_QPATH - 1, 'pics/%s.pcx', [name]); // CAK - changed quotes to single
    image := R_FindImage(fullname, it_pic);
  end
  else
  begin
    inc(Integer(name), SizeOf(name[0])); // CAK - much shorter code!
    image := R_FindImage(name, it_pic);
  end;

  Result := image;
end;

{
===============
Draw_InitLocal
===============
}

procedure Draw_InitLocal;
begin
  draw_chars := Draw_FindPic('conchars');
end;

{
================
Draw_Char

Draws one 8*8 graphics character
It can be clipped to the top of the screen to allow the console to be
smoothly scrolled off.
================
}

(*
{
 byte         *dest;
 byte         *source;
 int            drawline;
 int            row, col;

 num &= 255;

 if (num == 32 || num == 32+128)
  return;

 if (y <= -8)
  return;         // totally off screen

//   if ( ( y + 8 ) >= vid.height )
 if ( ( y + 8 ) > vid.height )      // PGM - status text was missing in sw...
  return;

#ifdef PARANOID
 if (y > vid.height - 8 || x < 0 || x > vid.width - 8)
  ri.Sys_Error (ERR_FATAL,"Con_DrawCharacter: (%i, %i)", x, y);
 if (num < 0 || num > 255)
  ri.Sys_Error (ERR_FATAL,"Con_DrawCharacter: char %i", num);
#endif

 row = num>>4;
 col = num&15;
 source = draw_chars->pixels[0] + (row<<10) + (col<<3);

 if (y < 0)
 {   // clipped
  drawline = 8 + y;
  source -= 128*y;
  y = 0;
 }
 else
  drawline = 8;

 dest = vid.buffer + y*vid.rowbytes + x;

 while (drawline--)
 {
  if (source[0] != TRANSPARENT_COLOR)
   dest[0] = source[0];
  if (source[1] != TRANSPARENT_COLOR)
   dest[1] = source[1];
  if (source[2] != TRANSPARENT_COLOR)
   dest[2] = source[2];
  if (source[3] != TRANSPARENT_COLOR)
   dest[3] = source[3];
  if (source[4] != TRANSPARENT_COLOR)
   dest[4] = source[4];
  if (source[5] != TRANSPARENT_COLOR)
   dest[5] = source[5];
  if (source[6] != TRANSPARENT_COLOR)
   dest[6] = source[6];
  if (source[7] != TRANSPARENT_COLOR)
   dest[7] = source[7];
  source += 128;
  dest += vid.rowbytes;
 }
}
*)

procedure Draw_Char(x, y, num: integer); cdecl;
var
  dest: PByteArray;
  source: PByteArray;
  drawline: Integer;
  row, col: Integer;
begin
  num := num and 255;

  if (num = 32) or (num = 32 + 128) then
    exit;

  if y <= -8 then
    exit; // totally off screen

// if ( y + 8 ) >= vid.height then
  if (y + 8) > vid.height then // PGM - status text was missing in sw...
    exit;

{$IFDEF PARANOID}
  if (y > vid.height - 8) or (x < 0) or (x > vid.width - 8)
    ri.Sys_Error(ERR_FATAL, 'Con_DrawCharacter: (%i, %i)', x, y);
  if (num < 0) or (num > 255)
    ri.Sys_Error(ERR_FATAL, 'Con_DrawCharacter: char %i', num);
{$ENDIF}

  row := num shr 4; // CAK - changed DIV to SHR - the answer would have been wrong!!!
  col := num and 15;
  source := PByteArray(Integer(draw_chars^.pixels[0]) + (row shl 10) + (col shl 3));

  if (y < 0) then // CAK - missing then
  begin // clipped
    drawline := 8 + y;
    Integer(source) := Integer(source) - (128 * y);
    y := 0;
  end
  else
    drawline := 8;

  dest := PByteArray(Integer(vid.buffer) + (y * vid.rowbytes) + x);
  while (drawline <> 0) do
  begin
    if source^[0] <> TRANSPARENT_COLOR then
      dest^[0] := source^[0];
    if source^[1] <> TRANSPARENT_COLOR then
      dest^[1] := source^[1];
    if source^[2] <> TRANSPARENT_COLOR then
      dest^[2] := source^[2];
    if source^[3] <> TRANSPARENT_COLOR then
      dest^[3] := source^[3];
    if source^[4] <> TRANSPARENT_COLOR then
      dest^[4] := source^[4];
    if source^[5] <> TRANSPARENT_COLOR then
      dest^[5] := source^[5];
    if source^[6] <> TRANSPARENT_COLOR then
      dest^[6] := source^[6];
    if source^[7] <> TRANSPARENT_COLOR then
      dest^[7] := source^[7];

    source := PByteArray(Integer(Source) + 128);
    dest := PByteArray(Integer(dest) + vid.rowbytes);
    drawline := drawline - 1;
  end;

end;

{
=============
Draw_GetPicSize
=============
}

procedure Draw_GetPicSize(w, h: PInteger; pic: PChar); cdecl;
var
  gl: image_p;
begin
  gl := Draw_FindPic(pic);
  if gl <> nil then
  begin
    w^ := gl^.width;
    h^ := gl^.height;
  end
  else
  begin
    w^ := -1;
    h^ := -1;
  end;
end;

{
=============
Draw_StretchPicImplementation
=============
}

procedure Draw_StretchPicImplementation(x, y, w, h: integer; pic: image_p);
var
  dest, source: pbyte;
  v, u, sv,
    height,
    f, fstep,
    skip: integer;
begin

  if (x < 0) or (x + w > vid.width) or (y + h > vid.height) then
    ri.Sys_Error(ERR_FATAL, 'Draw_Pic: bad coordinates');

  height := h;
  if (y < 0) then
  begin
    skip := -y;
    height := height + y;
    y := 0;
  end
  else
    skip := 0;

  dest := Ptr(LongInt(vid.buffer) + y * vid.rowbytes + x);
  for v := 0 to height - 1 do
  begin
    sv := ((skip + v) * pic^.height) div h;
    source := PByte(Integer(pic^.pixels[0]) + sv * pic^.width);
    if w = pic^.width then
      move(source^, Dest^, w)
    else
    begin
      f := 0;
      fstep := (pic^.width * $10000) div w;
      u := 0;
      while (u < w) do
      begin
        PByteArray(dest)^[u] := PByteArray(source)^[f shr 16];
        f := f + fstep;
        PByteArray(dest)^[u + 1] := PByteArray(source)^[f shr 16];
        f := f + fstep;
        PByteArray(dest)^[u + 2] := PByteArray(source)^[f shr 16];
        f := f + fstep;
        PByteArray(dest)^[u + 3] := PByteArray(source)^[f shr 16];
        f := f + fstep;
        Inc(u, 4);
      end;
    end;
    Inc(Integer(dest), vid.rowbytes);
  end;
end;

{
=============
Draw_StretchPic
=============
}

procedure Draw_StretchPic(x, y, w, h: integer; name: Pchar); cdecl;
var
  pic: image_p;
begin
  pic := Draw_FindPic(name);
  if pic = nil then
  begin
    ri.Con_Printf (PRINT_ALL, 'Can''t find pic: %s', name);
    exit;
  end;
  Draw_StretchPicImplementation(x, y, w, h, pic);
end;

{
=============
Draw_StretchRaw
=============
}

procedure Draw_StretchRaw(x, y, w, h, cols, rows: integer; data: Pbyte);
var
  pic: image_t;
begin
  pic.pixels[0] := data;
  pic.width := cols;
  pic.height := rows;
  Draw_StretchPicImplementation(x, y, w, h, @pic);
end;

{
=============
Draw_Pic
=============
}

procedure Draw_Pic(x, y: integer; name: Pchar); cdecl;
var
  pic: image_p;
  dest, source: cPtrByte;
  v, u,
    tbyte,
    height: integer;

begin
  pic := Draw_FindPic(name);
  if (pic = nil) then
  begin
    ri.Con_Printf(PRINT_ALL, 'Can''t find pic: %s', name);
    exit;
  end;

  if (x < 0) or (x + pic^.width > vid.width) or (y + pic^.height > vid.height) then
  begin
    ri.Sys_Error(ERR_FATAL, 'Draw_Pic: bad coordinates');
    exit; // ri.Sys_Error (ERR_FATAL,"Draw_Pic: bad coordinates");
  end;
  height := pic^.height;
  source := cPtrByte(Integer(pic^.pixels[0]));
  if (y < 0) then
  begin
    height := height + y;
    source := cPtrByte(Integer(source) + pic^.width * -y);
    y := 0;
  end;

  dest := cPtrByte(Integer(vid.buffer) + y * vid.rowbytes + x);
  if not pic^.transparent then
  begin
    for v := 0 to height - 1 do
    begin
      Move(source^, dest^, pic^.width);
      dest := cPtrByte(Integer(dest) + vid.rowbytes);
      source := cPtrByte(Integer(source) + pic^.width);
    end;
  end
  else
  begin
    if (pic^.width and 7) <> 0 then
    begin // general
      for v := 0 to height - 1 do
      begin
        for u := 0 to pic^.width - 1 do
        begin
          tbyte := source^[u];
          if tbyte <> TRANSPARENT_COLOR then
            dest^[u] := tbyte;
        end;
        dest := cPtrByte(Integer(dest) + vid.rowbytes);
        source := cPtrByte(Integer(source) + pic^.width);
      end;
    end
    else
    begin // unwound
      for v := 0 to height - 1 do
      begin
        u := 0;
        while (u < pic^.width) do
        begin
          tbyte := source^[u];
          if tbyte <> TRANSPARENT_COLOR then
            dest^[u] := tbyte;
          tbyte := source^[u + 1];
          if tbyte <> TRANSPARENT_COLOR then
            dest^[u + 1] := tbyte;
          tbyte := source^[u + 2];
          if tbyte <> TRANSPARENT_COLOR then
            dest^[u + 2] := tbyte;
          tbyte := source^[u + 3];
          if tbyte <> TRANSPARENT_COLOR then
            dest^[u + 3] := tbyte;
          tbyte := source^[u + 4];
          if tbyte <> TRANSPARENT_COLOR then
            dest^[u + 4] := tbyte;
          tbyte := source^[u + 5];
          if tbyte <> TRANSPARENT_COLOR then
            dest^[u + 5] := tbyte;
          tbyte := source^[u + 6];
          if tbyte <> TRANSPARENT_COLOR then
            dest^[u + 6] := tbyte;
          tbyte := source^[u + 7];
          if tbyte <> TRANSPARENT_COLOR then
            dest^[u + 7] := tbyte;
          Inc(u, 8);
        end;
        dest := cPtrByte(Integer(dest) + vid.rowbytes);
        source := cPtrByte(Integer(source) + pic^.width);
      end;
    end;
  end;
end;

{
=============
Draw_TileClear

This repeats a 64*64 tile graphic to fill the screen around a sized down
refresh window.
=============
}

procedure Draw_TileClear(x, y, w, h: integer; name: Pchar); cdecl;
var
  i, j: integer;
  psrc, pdest: cPtrByte;
  pic: image_p;
  x2: integer;

begin
  if x < 0 then
  begin
    w := w + x;
    x := 0;
  end;
  if y < 0 then
  begin
    h := h + y;
    y := 0;
  end;
  if x + w > vid.width then
    w := vid.width - x;
  if y + h > vid.height then
    h := vid.height - y;
  if not (w <= 0) or (h <= 0) then
  begin
    pic := Draw_FindPic(name);
    if pic <> nil then
    begin
      x2 := x + w;
      pdest := cPtrByte(Integer(vid.buffer) + y * vid.rowbytes);
      for i := 0 to h - 1 do
      begin
        psrc := cPtrByte(Integer(pic^.pixels[0]) + pic^.width * ((i + y) and 63));
        for j := x to x2 - 1 do
          pdest^[j] := psrc^[j and 63];
        pdest := cPtrByte(Integer(pdest) + vid.rowbytes);
      end;
    end
    else
      ri.Con_Printf (PRINT_ALL, 'Can''t find pic: %s', name);
  end;
end;

{
=============
Draw_Fill

Fills a box of pixels with a single color
=============
}

procedure Draw_Fill(x, y, w, h, c: integer); cdecl;
var
  dest: cPtrByte;
  u, v: integer;
begin
  if (x + w > vid.width) then
    w := vid.width - x;
  if (y + h > vid.height) then
    h := vid.height - y;
  if x < 0 then
  begin
    w := w + x;
    x := 0;
  end;
  if (y < 0) then
  begin
    h := h + y;
    y := 0;
  end;
  if not ((w < 0) or (h < 0)) then
  begin
    dest := cPtrByte(Integer(vid.buffer) + y * vid.rowbytes + x);
    for v := 0 to h - 1 do
    begin
      for u := 0 to w - 1 do
        dest^[u] := c;
      dest := cPtrByte(Integer(dest) + vid.rowbytes);
    end;
  end;
end;
//=============================================================================

{
================
Draw_FadeScreen

================
}

procedure Draw_FadeScreen();
var
  x, y, t: integer;
  pbuf: cPtrByte;
begin
  for y := 0 to vid.height - 1 do
  begin
    pbuf := cPtrByte(Integer(vid.buffer) + vid.rowbytes * y);
    t := (y and 1) shl 1;
    for x := 0 to vid.width - 1 do
    begin
      if ((x and 3) <> t) then
        pbuf^[x] := 0;
    end;
  end;
end;

end.
