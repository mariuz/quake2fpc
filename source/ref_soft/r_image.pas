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

{$ALIGN 8}{$MINENUMSIZE 4}
{----------------------------------------------------------------------------}
{                                                                            }
{ File(s): r_image.c                                                          }
{                                                                            }
{ Initial conversion by : Michael Skovslund (Michael@skovslund.dk)               }
{ Initial conversion on : 24-Mar-2002                                        }
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
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{ Fix all the bugs                                                           }
{ 1)                                                                         }
{ 2)                                                                         }
{----------------------------------------------------------------------------}

// r_image.c
unit r_image;

interface

uses
  r_local;

procedure R_ImageList_f; cdecl;
procedure LoadPCX(const filename: PChar; pic: PPointer; palette: PPointer; width: PInteger; height: PInteger);
procedure LoadTGA(const name: PChar; pic: PPointer; width, height: PInteger);
function R_FindFreeImage: image_p;
function GL_LoadPic(name: PChar; pic: PByte; width, height: Integer; _type: imagetype_t): image_p;
function R_LoadWal(const name: PChar): image_p;
function R_FindImage(const name: PChar; _type: imagetype_t): image_p;
function R_RegisterSkin(name: PChar): Pointer; cdecl; //image_p;
procedure R_FreeUnusedImages;
procedure R_InitImages;
procedure R_ShutdownImages;

implementation

uses
  r_main,
  QFiles,
  q_shared,
  r_model,
  SysUtils;

const
  CrLf = #13 + #10;
const
  MAX_RIMAGES = 1024;

type
//PPByte = ^PByte;
  TargaHeader = record
    id_length: Byte;
    colormap_type: Byte;
    image_type: Byte;
    colormap_index: Word;
    colormap_length: Word;
    colormap_size: Byte;
    x_origin: Word;
    y_origin: Word;
    width: Word;
    height: Word;
    pixel_size: Byte;
    attributes: Byte;
  end;

var
  r_images: array[0..MAX_RIMAGES - 1] of image_t;
  numr_images: Integer;

(*
===============
R_ImageList_f
===============
*)

procedure R_ImageList_f; cdecl;
var
  i: Integer;
  image: image_p;
  texels: Integer;
begin
   ri.Con_Printf(PRINT_ALL,'------------------');
   texels := 0;
  for i := 0 to numr_images - 1 do
  begin
    image := @r_images[i];
    if (image^.registration_sequence <= 0) then
    begin
      continue;
    end;
      inc(texels, image^.width*image^.height);
      case (image^._type) of
        it_skin:
           ri.Con_Printf(PRINT_ALL,'M');
        it_sprite:
           ri.Con_Printf(PRINT_ALL,'S');
        it_wall:
           ri.Con_Printf(PRINT_ALL,'W');
        it_pic:
           ri.Con_Printf(PRINT_ALL,'P');
        else
           ri.Con_Printf(PRINT_ALL,' ');
    end;
      ri.Con_Printf(PRINT_ALL,' %d %d : %s', image^.width, image^.height, image^.name);
   end;
   ri.Con_Printf(PRINT_ALL,'Total texel count: %d', texels);
end;

(*
=================================================================
PCX LOADING
=================================================================
*)

(*
==============
LoadPCX
==============
*)

procedure LoadPCX(const filename: PChar; pic: PPointer; palette: PPointer; width: PInteger; height: PInteger);
var
  raw       : PByte;
  pcx       : pcx_p;
  x,y       : Integer;
  len       : Integer;
  dataByte  : Integer;
  runLength : Integer;
  _out,pix  : PByte;
begin
   pic^ := nil;

   //
   // load the file
   //
   len := ri.FS_LoadFile(filename,@raw);
   if (raw = nil) then
   begin
      ri.Con_Printf(PRINT_DEVELOPER,'Bad pcx file %s', filename);
      Exit;
   end;

   //
   // parse the PCX file
   //
   pcx := pcx_p(raw);
  pcx^.xmin := LittleShort(pcx^.xmin);
  pcx^.ymin := LittleShort(pcx^.ymin);
  pcx^.xmax := LittleShort(pcx^.xmax);
  pcx^.ymax := LittleShort(pcx^.ymax);
  pcx^.hres := LittleShort(pcx^.hres);
  pcx^.vres := LittleShort(pcx^.vres);
  pcx^.bytes_per_line := LittleShort(pcx^.bytes_per_line);
  pcx^.palette_type := LittleShort(pcx^.palette_type);

  raw := @pcx^.data;

  if (pcx^.manufacturer <> #$0A) or (pcx^.version <> #5) or (pcx^.encoding <> #1) or
    (pcx^.bits_per_pixel <> #8) or (pcx^.xmax >= 640) or (pcx^.ymax >= 480) then
  begin
    ri.Con_Printf(PRINT_ALL, PChar('Bad pcx file ' + filename + CrLf));
    Exit;
  end;

  _out := AllocMem((pcx^.ymax + 1) * (pcx^.xmax + 1));
  pic^ := _out;
  pix := _out;

  if (palette <> nil) then
  begin
    palette^ := AllocMem(768);
    Move(Pointer(Integer(pcx) + len - 768)^, palette^^, 768);
  end;

   if (pcx^.manufacturer <> #$0a) or (pcx^.version <> #5) or (pcx^.encoding <> #1) or
       (pcx^.bits_per_pixel <> #8) or (pcx^.xmax >= 640) or (pcx^.ymax >= 480) then
   begin
      ri.Con_Printf(PRINT_ALL,'Bad pcx file %s', filename);
      Exit;
   end;

   _out := AllocMem((pcx^.ymax+1)*(pcx^.xmax+1));
   pic^ := _out;
   pix := _out;

   if (palette <> nil) then
   begin
      palette^ := AllocMem(768);
    Move(Pointer(Integer(pcx)+len-768)^,palette^^,768);
   end;

   if (width <> nil) then
      width^ := pcx^.xmax+1;
   if (height <> nil) then
      height^ := pcx^.ymax+1;

  for y := 0 to pcx^.ymax do
  begin
    x := 0;
    while (x <= pcx^.xmax) do
    begin
      dataByte := raw^;
      Inc(Cardinal(raw), 1);
      if ((dataByte and $C0) = $C0) then
      begin
        runLength := dataByte and $3F;
        dataByte := raw^;
        Inc(Cardinal(raw), 1);
      end
      else
        runLength := 1;
      while (runLength > 0) do
      begin
        PByteArray(pix)^[x] := dataByte;
        inc(x);
        dec(runLength);
      end;
    end;
    pix := PByte(Cardinal(pix) + pcx^.xmax + 1);
  end;
   if (Integer(raw) - Integer(pcx) > len) then
   begin
      ri.Con_Printf(PRINT_DEVELOPER,'PCX file %s was malformed', filename);
      FreeMem(pic^);
      pic^ := nil;
   end;
   ri.FS_FreeFile(pcx);
end;

(*
=========================================================

TARGA LOADING

=========================================================
*)

(*
=============
LoadTGA
=============
*)

procedure LoadTGA(const name: PChar; pic: PPointer; width, height: PInteger);
var
  columns: Integer;
  rows: Integer;
  numPixels: Integer;
  pixbuf: PByte;
  row: Integer;
  column: Integer;
  buf_p: PByte;
  buffer: PByte;
//   length          : Integer;
  targa_header: TargaHeader;
  targa_rgba: PByte;
  red, green: Byte;
  blue, alphabyte: Byte;
  packetHeader: Byte;
  packetSize, j: Byte;

label
  breakOut;
begin
  pic^ := nil;

 //
 // load the file
 //
//   length :=
  ri.FS_LoadFile(name,@buffer);
   if (buffer = nil) then
   begin
      ri.Con_Printf(PRINT_DEVELOPER,'Bad tga file %s', name);
      Exit;
   end;

  buf_p := buffer;

  targa_header.id_length := buf_p^;
  inc(Cardinal(buf_p));
  targa_header.colormap_type := buf_p^;
  inc(Cardinal(buf_p));
  targa_header.image_type := buf_p^;
  inc(Cardinal(buf_p));

  targa_header.colormap_index := LittleShort(buf_p^);
  inc(Cardinal(buf_p), 2);
  targa_header.colormap_length := LittleShort(buf_p^);
  inc(Cardinal(buf_p), 2);
  targa_header.colormap_size := buf_p^;
  inc(Cardinal(buf_p));
  targa_header.x_origin := LittleShort(buf_p^);
  inc(Cardinal(buf_p), 2);
  targa_header.y_origin := LittleShort(buf_p^);
  inc(Cardinal(buf_p), 2);
  targa_header.width := LittleShort(buf_p^);
  inc(Cardinal(buf_p), 2);
  targa_header.height := LittleShort(buf_p^);
  inc(Cardinal(buf_p), 2);
  targa_header.pixel_size := buf_p^;
  inc(Cardinal(buf_p));
  targa_header.attributes := buf_p^;
  inc(Cardinal(buf_p));

  if (targa_header.image_type <> 2) and (targa_header.image_type <> 10) then
    ri.Sys_Error(ERR_DROP, PChar('LoadTGA: Only type 2 and 10 targa RGB images supported' + CrLf));

  if (targa_header.colormap_type <> 0) or ((targa_header.pixel_size <> 32) and (targa_header.pixel_size <> 24)) then
    ri.Sys_Error(ERR_DROP, PChar('LoadTGA: Only 32 or 24 bit images supported (no colormaps)' + CrLf));

  columns := targa_header.width;
  rows := targa_header.height;
  numPixels := columns * rows;

  if (width <> nil) then
    width^ := columns;
  if (height <> nil) then
    height^ := rows;

  targa_rgba := AllocMem(numPixels * 4);
  pic^ := targa_rgba;

  if (targa_header.id_length <> 0) then
    Inc(Cardinal(buf_p), targa_header.id_length); // skip TARGA image comment

  if (targa_header.image_type = 2) then
  begin // Uncompressed, RGB images
    for row := rows - 1 downto 0 do
    begin
      pixbuf := Pointer(Integer(targa_rgba) + row * columns * 4);
      column := 0;
      while (column <= columns - 1) do
      begin
        case (targa_header.pixel_size) of
          24:
            begin
              blue := buf_p^;
              inc(Cardinal(buf_p));
              green := buf_p^;
              inc(Cardinal(buf_p));
              red := buf_p^;
              inc(Cardinal(buf_p));
              pixbuf^ := red;
              inc(Cardinal(pixbuf));
              pixbuf^ := green;
              inc(Cardinal(pixbuf));
              pixbuf^ := blue;
              inc(Cardinal(pixbuf));
              pixbuf^ := 255;
              inc(Cardinal(pixbuf));
            end;
          32:
            begin
              blue := buf_p^;
              inc(Cardinal(buf_p));
              green := buf_p^;
              inc(Cardinal(buf_p));
              red := buf_p^;
              inc(Cardinal(buf_p));
              alphabyte := buf_p^;
              inc(Cardinal(buf_p));
              pixbuf^ := red;
              inc(Cardinal(pixbuf));
              pixbuf^ := green;
              inc(Cardinal(pixbuf));
              pixbuf^ := blue;
              inc(Cardinal(pixbuf));
              pixbuf^ := alphabyte;
              inc(Cardinal(pixbuf));
            end;
        end;
        Inc(column);
      end;
    end;
  end
  else
    if (targa_header.image_type = 10) then
    begin // Runlength encoded RGB images
      row := rows - 1;
      while (row >= 0) do
      begin
        pixbuf := Pointer(Integer(targa_rgba) + row * columns * 4);
        column := 0;
        while (column <= columns - 1) do
        begin
          packetHeader := buf_p^;
          inc(Cardinal(buf_p));
          packetSize := 1 + (packetHeader and $7F);
          if (packetHeader and $80) = $80 then
          begin // run-length packet
            case (targa_header.pixel_size) of
              24:
                begin
                  blue := buf_p^;
                  inc(Cardinal(buf_p));
                  green := buf_p^;
                  inc(Cardinal(buf_p));
                  red := buf_p^;
                  inc(Cardinal(buf_p));
                  alphabyte := 255;
                end;
              32:
                begin
                  blue := buf_p^;
                  inc(Cardinal(buf_p));
                  green := buf_p^;
                  inc(Cardinal(buf_p));
                  red := buf_p^;
                  inc(Cardinal(buf_p));
                  alphabyte := buf_p^;
                  inc(Cardinal(buf_p));
                end;
            else // hhmmm, actually this should produce an error, but set rgb to default black
              begin
                red := 0;
                green := 0;
                blue := 0;
                alphabyte := 0;
              end;
            end;
            for j := 0 to packetSize - 1 do
            begin
              pixbuf^ := red;
              inc(Cardinal(pixbuf));
              pixbuf^ := green;
              inc(Cardinal(pixbuf));
              pixbuf^ := blue;
              inc(Cardinal(pixbuf));
              pixbuf^ := alphabyte;
              inc(Cardinal(pixbuf));
              Inc(column);
              if (column = columns) then
              begin // run spans across rows
                column := 0;
                if (row > 0) then
                  inc(row)
                else
                  goto breakOut;
                pixbuf := Pointer(Integer(targa_rgba) + row * columns * 4);
              end;
            end;
          end
          else
          begin // non run-length packet
            for j := 0 to packetSize - 1 do
            begin
              case (targa_header.pixel_size) of
                24:
                  begin
                    blue := buf_p^;
                    inc(Cardinal(buf_p));
                    green := buf_p^;
                    inc(Cardinal(buf_p));
                    red := buf_p^;
                    inc(Cardinal(buf_p));
                    pixbuf^ := red;
                    inc(Cardinal(pixbuf));
                    pixbuf^ := green;
                    inc(Cardinal(pixbuf));
                    pixbuf^ := blue;
                    inc(Cardinal(pixbuf));
                    pixbuf^ := 255;
                    inc(Cardinal(pixbuf));
                  end;
                32:
                  begin
                    blue := buf_p^;
                    inc(Cardinal(buf_p));
                    green := buf_p^;
                    inc(Cardinal(buf_p));
                    red := buf_p^;
                    inc(Cardinal(buf_p));
                    alphabyte := buf_p^;
                    inc(Cardinal(buf_p));
                    pixbuf^ := red;
                    inc(Cardinal(pixbuf));
                    pixbuf^ := green;
                    inc(Cardinal(pixbuf));
                    pixbuf^ := blue;
                    inc(Cardinal(pixbuf));
                    pixbuf^ := alphabyte;
                    inc(Cardinal(pixbuf));
                  end;
              end;
              inc(column);
              if (column = columns) then
              begin // pixel packet run spans across rows
                column := 0;
                if (row > 0) then
                  dec(row)
                else
                  goto breakOut;
                pixbuf := Pointer(Integer(targa_rgba) + row * columns * 4);
              end;
            end;
          end;
          Inc(column);
        end;
        breakOut:
        Inc(Row);
      end;
    end;
  ri.FS_FreeFile(buffer);
end;

//=======================================================

function R_FindFreeImage: image_p;
var
  image: image_t;
  i: Integer;
begin
 // find a free image_t
  for i := 0 to numr_images - 1 do
  begin
    image := r_images[i];
    if (image.registration_sequence = 0) then
      break;
  end;
  if (i = numr_images) then
  begin
    if (numr_images = MAX_RIMAGES) then
      ri.Sys_Error(ERR_DROP, 'MAX_RIMAGES');
    inc(numr_images);
  end;
  if numr_images = 0 then
  begin
    i := 0;
    inc(numr_images);
  end;
  Result := @r_images[i];
end;

(*
================
GL_LoadPic

================
*)

function GL_LoadPic(name: PChar; pic: PByte; width, height: Integer; _type: imagetype_t): image_p;
var
  image: image_p;
  i, c, b: Integer;
  pix: PByte;
begin
  image := R_FindFreeImage;
  if (StrLen(name) >= sizeof(image^.name)) then
    ri.Sys_Error(ERR_DROP, 'Draw_LoadPic: "%s" is too long', name);
  StrCopy(PChar(@image^.name), name);
  image^.registration_sequence := registration_sequence;

  image^.width := width;
  image^.height := height;
  image^._type := _type;

  c := width * height;
  image^.pixels[0] := AllocMem(c);
  image^.transparent := false;
  pix := image^.pixels[0];
  for i := 0 to c - 1 do
  begin
    b := pic^;
    if (b = 255) then
      image^.transparent := true;
    pix^ := b;
    Inc(Integer(pic));
    Inc(Integer(pix));
  end;
  result := image;
end;

(*
================
R_LoadWal
================
*)

function R_LoadWal(const name: PChar): image_p;
var
   mt    : miptex_p;
   ofs   : Integer;
   image : image_p;
   size  : Integer;
begin
   ri.FS_LoadFile(name,@mt);
   if (mt = nil) then
   begin
      ri.Con_Printf(PRINT_ALL,'R_LoadWal: can''t load %s', name);
      Result := r_notexture_mip;
    Exit;
  end;
  image := R_FindFreeImage;
  StrCopy(PChar(@image^.name), name);
  image^.width := LittleLong(mt^.width);
  image^.height := LittleLong(mt^.height);
  image^._type := it_wall;
  image^.registration_sequence := registration_sequence;

  size := image^.width * image^.height * (256 + 64 + 16 + 4) div 256;
  image^.pixels[0] := AllocMem(size);
  image^.pixels[1] := PByte(Integer(image^.pixels[0]) + image^.width * image^.height);
  image^.pixels[2] := PByte(Integer(image^.pixels[1]) + image^.width * image^.height div 4);
  image^.pixels[3] := PByte(Integer(image^.pixels[2]) + image^.width * image^.height div 16);

  ofs := LittleLong(mt^.offsets[0]);
  Move(Pointer(Integer(mt) + ofs)^, image^.pixels[0]^, size);

  ri.FS_FreeFile(mt);
  Result := image;
end;

(*
===============
R_FindImage
Finds or loads the given image
===============
*)

function R_FindImage(const name: PChar; _type: imagetype_t): image_p;
var
  image: image_p;
  i, len: Integer;
  pic: PByte;
  palette: PByte;
  width: Integer;
  height: Integer;
begin
  Result := nil;
  if (name = nil) then
  begin
    //ri.Sys_Error(ERR_DROP, PChar('R_FindImage: NULL name'+CrLf));
    Exit; //
  end;
  len := StrLen(name);
  if (len < 5) then
  begin
    //ri.Sys_Error(ERR_DROP, PChar('R_FindImage: bad name: '+name+CrLf));
    Exit; //
  end;
 // look for it
  for i := 0 to numr_images - 1 do
  begin
    image := @r_images[i];
    if (StrComp(name, image^.name) = 0) then
    begin
      image^.registration_sequence := registration_sequence;
      Result := image;
      Exit;
    end;
  end;

 //
 // load the pic from disk
 //
  pic := nil;
  palette := nil;
  if (StrComp(PChar(@name[len - 4]), '.pcx') = 0) then
  begin
    LoadPCX(name, @pic, @palette, @width, @height);
    if (pic = nil) then
    begin
      //ri.Sys_Error(ERR_DROP, PChar('R_FindImage: can''t load '+name+CrLf));
      Exit; //
    end;
    image := GL_LoadPic(name, pic, width, height, _type);
  end
  else
    if (StrComp(PChar(@name[len - 4]), '.wal') = 0) then
      image := R_LoadWal(name)
    else
      if (StrComp(PChar(@name[len - 4]), '.tga') = 0) then
      begin
        //ri.Sys_Error(ERR_DROP, PChar('R_FindImage: can''t load '+name+' in software renderer'+CrLf));
        Exit //
      end
      else
      begin
        //ri.Sys_Error(ERR_DROP, PChar('R_FindImage: bad extension on: '+name+CrLf));
        Exit; //
      end;
  if (pic <> nil) then
    FreeMem(pic);
  if (palette <> nil) then
    FreeMem(palette);
  Result := image;
end;

(*
===============
R_RegisterSkin
===============
*)

function R_RegisterSkin(name: PChar): Pointer; cdecl; //image_p;
begin
  Result := R_FindImage(name, it_skin);
end;

(*
================
R_FreeUnusedImages

Any image that was not touched on this registration sequence
will be freed.
================
*)

procedure R_FreeUnusedImages;
var
  i: Integer;
  image: image_p;
begin
  for i := 0 to numr_images - 1 do
  begin
    image := @r_images[i];
    if (image^.registration_sequence = registration_sequence) then
    begin
      Com_PageInMemory(image^.pixels[0], image^.width * image^.height);
      continue; // used this sequence
    end;
    if (image^.registration_sequence = 0) then
      continue; // free texture
    if (image^._type = it_pic) then
      continue; // don't free pics
  // free it
    FreeMem(image^.pixels[0]); // the other mip levels just follow
    FillChar(image^, sizeof(image_t), 0);
  end;
end;

(*
===============
R_ShutdownImages
===============
*)

procedure R_ShutdownImages;
var
  i: Integer;
  image: image_p;
begin
  for i := 0 to numr_images - 1 do
  begin
    image := @r_images[i];
    if (image^.registration_sequence = 0) then
      continue; // free texture
  // free it
    FreeMem(image^.pixels[0]); // the other mip levels just follow
    FillChar(image^, sizeof(image_t), 0);
  end;
end;

(*
===============
R_InitImages
===============
*)

procedure R_InitImages;
begin
  registration_sequence := 1;
end;

end.
