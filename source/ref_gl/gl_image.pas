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
{ File(s): gl_image.c - model loading and caching                            }
{                                                                            }
{ Initial conversion by : YgriK (Igor Karpov) - glYgriK@hotbox.ru            }
{ Initial conversion on : 03-Apr-2002                                        }
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
{ PROOFREADED: 8.03.2003 Juha }
{ PROOFREADED: 28.06.2003 Juha }
unit gl_image;

interface

{$I ..\Jedi.inc}

uses
  DelphiTypes,
  CPas,
  gl_local,
  gl_local_add,
  q_shared,
  OpenGL;

procedure GL_EnableMultitexture(enable: qboolean);
procedure GL_TexEnv(mode: TGLenum);
procedure GL_Bind(texnum: integer);

procedure GL_TextureMode(_string: PChar);
procedure GL_TextureAlphaMode(_string: PChar);
procedure GL_TextureSolidMode(_string: PChar);

procedure GL_ImageList_f; cdecl;

function GL_FindImage(name: PChar; _type: imagetype_t): image_p;
function R_RegisterSkin(name: PChar): pointer; cdecl;
procedure GL_FreeUnusedImages;
function GL_LoadPic(name: PChar; pic: PByte; width, height: integer; _type: imagetype_t; bits: integer): image_p;
procedure GL_SetTexturePalette(palette: PCardinalArray);

function Draw_GetPalette: integer;
procedure GL_InitImages;
procedure GL_ShutdownImages;
procedure GL_MBind(target: TGLenum; texnum: integer);
procedure GL_SelectTexture(texture: TGLenum);
procedure Scrap_Upload;

var
  gltextures: array[0..MAX_GLTEXTURES - 1] of image_t;
  numgltextures: Integer;
  scrap_dirty: qboolean;
  d_8to24table: array[0..256 - 1] of Cardinal;
  gl_solid_format: Integer = 3;
  gl_alpha_format: Integer = 4;

  gl_tex_solid_format: Integer = 3;
  gl_tex_alpha_format: Integer = 4;
  gl_filter_min: integer = GL_LINEAR_MIPMAP_NEAREST;
  gl_filter_max: integer = GL_LINEAR;

implementation

uses
  SysUtils,
  Math,
  QFiles,
  gl_draw,
  gl_rmain,
  gl_model,
  qgl_win,
  ref;

var
  base_textureid: Integer; // gltextures[i] = base_textureid+i

  intensitytable: array[0..256 - 1] of byte;
  gammatable: array[0..256 - 1] of byte;

  intensity: cvar_p;

function GL_Upload8(data: PByteArray; width, height: integer; mipmap, is_sky: qboolean): qboolean; forward;

procedure GL_SetTexturePalette(palette: PCardinalArray);
var
  i: integer;
  temptable: array[0..768 - 1] of byte;
begin
  if (@qglColorTableEXT <> nil) and (gl_ext_palettedtexture^.value <> 0) then
  begin
    for i := 0 to 255 do
    begin
      temptable[i * 3 + 0] := (palette[i] shr 0) and $FF;
      temptable[i * 3 + 1] := (palette[i] shr 8) and $FF;
      temptable[i * 3 + 2] := (palette[i] shr 16) and $FF;
    end;

    qglColorTableEXT(GL_SHARED_TEXTURE_PALETTE_EXT,
      GL_RGB,
      256,
      GL_RGB,
      GL_UNSIGNED_BYTE,
      @temptable);
  end;
end;

procedure GL_EnableMultitexture(enable: qboolean);
begin
  if (@qglSelectTextureSGIS = nil) and (@qglActiveTextureARB = nil) then
    Exit;

  if (enable) then
  begin
    GL_SelectTexture(GL_TEXTURE1);
    qglEnable(GL_TEXTURE_2D);
    GL_TexEnv(GL_REPLACE);
  end
  else
  begin
    GL_SelectTexture(GL_TEXTURE1);
    qglDisable(GL_TEXTURE_2D);
    GL_TexEnv(GL_REPLACE);
  end;
  GL_SelectTexture(GL_TEXTURE0);
  GL_TexEnv(GL_REPLACE);
end;

procedure GL_SelectTexture(texture: TGLenum);
var
  tmu: integer;
begin
  if (@qglSelectTextureSGIS = nil) and (@qglActiveTextureARB = nil) then
    exit;

  if (texture = GL_TEXTURE0) then
    tmu := 0
  else
    tmu := 1;

  if (tmu = gl_state.currenttmu) then
    exit;

  gl_state.currenttmu := tmu;

  if (@qglSelectTextureSGIS <> nil) then
    qglSelectTextureSGIS(texture)
  else
    if (@qglActiveTextureARB <> nil) then
    begin
      qglActiveTextureARB(texture);
      qglClientActiveTextureARB(texture);
    end;
end;

procedure GL_TexEnv(mode: TGLenum);
{$IFDEF COMPILER6_UP}{$WRITEABLECONST ON}{$ENDIF}
const
  lastmodes: array[0..1] of integer = (-1, -1);
{$IFDEF COMPILER6_UP}{$WRITEABLECONST OFF}{$ENDIF}
begin
  if (mode <> lastmodes[gl_state.currenttmu]) then
  begin
    qglTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, mode);
    lastmodes[gl_state.currenttmu] := mode;
  end;
end;

procedure GL_Bind(texnum: integer);
begin
  if (gl_nobind^.value <> 0) and (draw_chars <> nil) then // performance evaluation option
    texnum := draw_chars^.texnum;

  if (gl_state.currenttextures[gl_state.currenttmu] = texnum) then
    Exit;
  gl_state.currenttextures[gl_state.currenttmu] := texnum;
  qglBindTexture(GL_TEXTURE_2D, texnum);
end;

procedure GL_MBind(target: TGLenum; texnum: integer);
begin
  GL_SelectTexture(target);
  if (target = GL_TEXTURE0) then
  begin
    if (gl_state.currenttextures[0] = texnum) then
      exit;
  end
  else
  begin
    if (gl_state.currenttextures[1] = texnum) then
      exit;
  end;
  GL_Bind(texnum);
end;

type
  glmode_t = record
    name: PChar;
    minimize,
      maximize: integer;
  end;

var
  modes: array[0..5] of glmode_t = (
    (name: 'GL_NEAREST'; minimize: GL_NEAREST; maximize: GL_NEAREST),
    (name: 'GL_LINEAR'; minimize: GL_LINEAR; maximize: GL_LINEAR),
    (name: 'GL_NEAREST_MIPMAP_NEAREST'; minimize: GL_NEAREST_MIPMAP_NEAREST; maximize: GL_NEAREST),
    (name: 'GL_LINEAR_MIPMAP_NEAREST'; minimize: GL_LINEAR_MIPMAP_NEAREST; maximize: GL_LINEAR),
    (name: 'GL_NEAREST_MIPMAP_LINEAR'; minimize: GL_NEAREST_MIPMAP_LINEAR; maximize: GL_NEAREST),
    (name: 'GL_LINEAR_MIPMAP_LINEAR'; minimize: GL_LINEAR_MIPMAP_LINEAR; maximize: GL_LINEAR));

const
  NUM_GL_MODES = sizeof(modes) div sizeof(glmode_t);

type
  gltmode_t = record
    name: PChar;
    mode: integer;
  end;
var
  gl_alpha_modes: array[0..5] of gltmode_t = (
    (name: 'default'; mode: 4),
    (name: 'GL_RGBA'; mode: GL_RGBA),
    (name: 'GL_RGBA8'; mode: GL_RGBA8),
    (name: 'GL_RGB5_A1'; mode: GL_RGB5_A1),
    (name: 'GL_RGBA4'; mode: GL_RGBA4),
    (name: 'GL_RGBA2'; mode: GL_RGBA2));

const
  NUM_GL_ALPHA_MODES = sizeof(gl_alpha_modes) div sizeof(gltmode_t);

var
  gl_solid_modes: array[0..5 {6}] of gltmode_t = (
    (name: 'default'; mode: 3),
    (name: 'GL_RGB'; mode: GL_RGB),
    (name: 'GL_RGB8'; mode: GL_RGB8),
    (name: 'GL_RGB5'; mode: GL_RGB5),
    (name: 'GL_RGB4'; mode: GL_RGB4),
    (name: 'GL_R3_G3_B2'; mode: GL_R3_G3_B2));
{*
#ifdef GL_RGB2_EXT
 ("GL_RGB2", GL_RGB2_EXT),
#endif
*}

const
  NUM_GL_SOLID_MODES = sizeof(gl_solid_modes) div sizeof(gltmode_t);

{*
===============
GL_TextureMode
===============
*}
procedure GL_TextureMode(_string: PChar);
var
  i: integer;
  glt: image_p;
begin
  i := 0;
  while (i < NUM_GL_MODES) do
  begin
    if (Q_stricmp(modes[i].name, _string) = 0) then
      Break;
    Inc(i);
  end;

  if (i = NUM_GL_MODES) then
  begin
    ri.Con_Printf(PRINT_ALL, 'bad filter name'#10, []);
    Exit;
  end;

  gl_filter_min := modes[i].minimize;
  gl_filter_max := modes[i].maximize;

  // change all the existing mipmap texture objects
  i := 0;
  glt := @gltextures;
  while (i < numgltextures) do
  begin
    if (glt.type_ <> it_pic) and (glt.type_ <> it_sky) then
    begin
      GL_Bind(glt.texnum);
      qglTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, gl_filter_min);
      qglTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, gl_filter_max);
    end;
    Inc(i);
    Inc(glt);
  end;
end;

{*
===============
GL_TextureAlphaMode
===============
*}
procedure GL_TextureAlphaMode(_string: PChar);
var
  i: integer;
begin
  i := 0;
  while (i < NUM_GL_ALPHA_MODES) do
  begin
    if (Q_stricmp(gl_alpha_modes[i].name, _string) = 0) then
      break;
    Inc(i);
  end;

  if (i = NUM_GL_ALPHA_MODES) then
  begin
    ri.Con_Printf(PRINT_ALL, 'bad alpha texture mode name'#10, []);
    Exit;
  end;

  gl_tex_alpha_format := gl_alpha_modes[i].mode;
end;

{*
===============
GL_TextureSolidMode
===============
*}
procedure GL_TextureSolidMode(_string: PChar);
var
  i: integer;
begin
  i := 0;
  while (i < NUM_GL_SOLID_MODES) do
  begin
    if (Q_stricmp(gl_solid_modes[i].name, _string) = 0) then
      Break;
    Inc(i);
  end;

  if (i = NUM_GL_SOLID_MODES) then
  begin
    ri.Con_Printf(PRINT_ALL, 'bad solid texture mode name'#10, []);
    Exit;
  end;

  gl_tex_solid_format := gl_solid_modes[i].mode;
end;

{*
===============
GL_ImageList_f
===============
*}
procedure GL_ImageList_f;
var
  i: integer;
  image: image_p;
  texels: integer;
const // Changed to Boolean since integer(true) = -1
  palstrings: array[Boolean] of PChar =
  ('RGB',
    'PAL');
label
  Continue_;
begin
  ri.Con_Printf(PRINT_ALL, '------------------'#10, []);
  texels := 0;

  i := 0;
  image := @gltextures;
  while (i < numgltextures) do
  begin
    if (image.texnum <= 0) then
      goto Continue_;
    Inc(texels, image.upload_width * image.upload_height);
    case (image.type_) of
      it_skin: ri.Con_Printf(PRINT_ALL, 'M', []);
      it_sprite: ri.Con_Printf(PRINT_ALL, 'S', []);
      it_wall: ri.Con_Printf(PRINT_ALL, 'W', []);
      it_pic: ri.Con_Printf(PRINT_ALL, 'P', []);
    else
      ri.Con_Printf(PRINT_ALL, ' ', []);
    end;

    ri.Con_Printf(PRINT_ALL, ' %3i %3i %s: %s'#10,
      image.upload_width, image.upload_height, palstrings[image.paletted], image.name);
    Continue_:
    Inc(i);
    Inc(image);
  end;
  ri.Con_Printf(PRINT_ALL, 'Total texel count (not counting mipmaps): %i'#10, [texels]);
end;

{*
=============================================================================

  scrap allocation

  Allocate all the little status bar obejcts into a single texture
  to crutch up inefficient hardware / drivers

=============================================================================
*}
const
  MAX_SCRAPS = 1;
  BLOCK_WIDTH = 256;
  BLOCK_HEIGHT = 256;
var
  scrap_allocated: array[0..MAX_SCRAPS - 1, 0..BLOCK_WIDTH - 1] of integer;
  scrap_texels: array[0..MAX_SCRAPS - 1, 0..BLOCK_WIDTH * BLOCK_HEIGHT - 1] of byte;

// returns a texture number and the position inside it
function Scrap_AllocBlock(w, h: integer;
  var x, y: integer): integer;
var
  i, j,
    best, best2,
    texnum: integer;
begin
  for texnum := 0 to MAX_SCRAPS - 1 do
  begin
    best := BLOCK_HEIGHT;

    for i := 0 to BLOCK_WIDTH - w - 1 do
    begin
      best2 := 0;

      j := 0;
      while (j < w) do
      begin
        if (scrap_allocated[texnum][i + j] >= best) then
          Break;
        if (scrap_allocated[texnum][i + j] > best2) then
          best2 := scrap_allocated[texnum][i + j];
        Inc(j);
      end;
      if (j = w) then
      begin
        // this is a valid spot
        x := i;
        best := best2;
        y := best;
      end;
    end;

    if (best + h > BLOCK_HEIGHT) then
      Continue;

    for i := 0 to w - 1 do
      scrap_allocated[texnum][x + i] := best + h;

    Result := texnum;
    Exit;
  end;

  Result := -1;
//id_soft   Sys_Error ("Scrap_AllocBlock: full");
end;

var
  scrap_uploads: Integer;

procedure Scrap_Upload;
begin
  Inc(scrap_uploads);
  GL_Bind(TEXNUM_SCRAPS);
  GL_Upload8(@scrap_texels[0], BLOCK_WIDTH, BLOCK_HEIGHT, false, false);
  scrap_dirty := false;
end;

{*
=================================================================

PCX LOADING

=================================================================
*}

{*
==============
LoadPCX
==============
*}
procedure LoadPCX(filename: PChar; pic: PPointer; palette: PPointer; width: PInteger; height: PInteger);
var
  raw: PByte;
  pcx: pcx_p;
  x, y: Integer;
  len: Integer;
  dataByte: Integer;
  runLength: Integer;
  _out, pix: PByte;
begin
  pic^ := nil;
  palette^ := nil;

  //
  // load the file
  //
  len := ri.FS_LoadFile(filename, @raw);
  if (raw = nil) then
  begin
    ri.Con_Printf(PRINT_DEVELOPER, 'Bad pcx file %s'#10, filename);
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
    ri.Con_Printf(PRINT_ALL, 'Bad pcx file %s'#10, filename);
    Exit;
  end;

  _out := malloc((pcx^.ymax + 1) * (pcx^.xmax + 1));
  pic^ := _out;
  pix := _out;

  if (palette <> nil) then
  begin
    palette^ := malloc(768);
    memcpy(palette^, Pointer(Integer(pcx) + len - 768), 768);
  end;

  if (width <> nil) then
    width^ := pcx^.xmax + 1;
  if (height <> nil) then
    height^ := pcx^.ymax + 1;

  for y := 0 to pcx^.ymax do
  begin
    x := 0;
    while (x <= pcx^.xmax) do
    begin
      dataByte := raw^;
      Inc(raw);
      if ((dataByte and $C0) = $C0) then
      begin
        runLength := dataByte and $3F;
        dataByte := raw^;
        Inc(raw);
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
    ri.Con_Printf(PRINT_DEVELOPER, 'PCX file %s was malformed', filename);
    FreeMem(pic^);
    pic^ := nil;
  end;
  ri.FS_FreeFile(pcx);
end;

{*
=========================================================

TARGA LOADING

=========================================================
*}
type
  targaheader_t = record
    id_length, colormap_type, image_type: Byte;
    colormap_index, colormap_length: Word;
    colormap_size: Byte;
    x_origin, y_origin, width, height: Word;
    pixel_size, attributes: Byte;
  end;

{*
=============
LoadTGA
=============
*}
procedure LoadTGA(name: PChar; pic: PPointer; width, height: PInteger);
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
  targa_header: targaheader_t;
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
  ri.FS_LoadFile(name, @buffer);
  if (buffer = nil) then
  begin
    ri.Con_Printf(PRINT_DEVELOPER, 'Bad tga file %s'#10, name);
    Exit;
  end;

  buf_p := buffer;

  targa_header.id_length := buf_p^;
  inc(buf_p);
  targa_header.colormap_type := buf_p^;
  inc(buf_p);
  targa_header.image_type := buf_p^;
  inc(buf_p);

  targa_header.colormap_index := LittleShort(PSmallInt(buf_p)^);
  inc(buf_p, 2);
  targa_header.colormap_length := LittleShort(PSmallInt(buf_p)^);
  inc(buf_p, 2);
  targa_header.colormap_size := buf_p^;
  Inc(buf_p);
  targa_header.x_origin := LittleShort(PSmallInt(buf_p)^);
  Inc(buf_p, 2);
  targa_header.y_origin := LittleShort(PSmallInt(buf_p)^);
  Inc(buf_p, 2);
  targa_header.width := LittleShort(PSmallInt(buf_p)^);
  Inc(buf_p, 2);
  targa_header.height := LittleShort(PSmallInt(buf_p)^);
  Inc(buf_p, 2);
  targa_header.pixel_size := buf_p^;
  Inc(buf_p);
  targa_header.attributes := buf_p^;
  Inc(buf_p);

  if (targa_header.image_type <> 2) and (targa_header.image_type <> 10) then
    ri.Sys_Error(ERR_DROP, 'LoadTGA: Only type 2 and 10 targa RGB images supported'#10);

  if (targa_header.colormap_type <> 0) or ((targa_header.pixel_size <> 32) and (targa_header.pixel_size <> 24)) then
    ri.Sys_Error(ERR_DROP, 'LoadTGA: Only 32 or 24 bit images supported (no colormaps)'#10);

  columns := targa_header.width;
  rows := targa_header.height;
  numPixels := columns * rows;

  if (width <> nil) then
    width^ := columns;
  if (height <> nil) then
    height^ := rows;

  targa_rgba := malloc(numPixels * 4);
  pic^ := targa_rgba;

  if (targa_header.id_length <> 0) then
    Inc(buf_p, targa_header.id_length); // skip TARGA image comment

  if (targa_header.image_type = 2) then
  begin // Uncompressed, RGB images
    for row := rows - 1 downto 0 do
    begin
      pixbuf := Pointer(Integer(targa_rgba) + row * columns * 4);
      column := 0;
      while (column < columns) do
      begin
        case (targa_header.pixel_size) of
          24:
            begin
              blue := buf_p^;
              inc(buf_p);
              green := buf_p^;
              inc(buf_p);
              red := buf_p^;
              inc(buf_p);
              pixbuf^ := red;
              inc(pixbuf);
              pixbuf^ := green;
              inc(pixbuf);
              pixbuf^ := blue;
              inc(pixbuf);
              pixbuf^ := 255;
              inc(pixbuf);
            end;
          32:
            begin
              blue := buf_p^;
              inc(buf_p);
              green := buf_p^;
              inc(buf_p);
              red := buf_p^;
              inc(buf_p);
              alphabyte := buf_p^;
              inc(buf_p);
              pixbuf^ := red;
              inc(pixbuf);
              pixbuf^ := green;
              inc(pixbuf);
              pixbuf^ := blue;
              inc(pixbuf);
              pixbuf^ := alphabyte;
              inc(pixbuf);
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
        while (column < columns) do
        begin
          packetHeader := buf_p^;
          Inc(buf_p);
          packetSize := 1 + (packetHeader and $7F);
          if (packetHeader and $80) = $80 then
          begin // run-length packet
            case (targa_header.pixel_size) of
              24:
                begin
                  blue := buf_p^;
                  Inc(buf_p);
                  green := buf_p^;
                  Inc(buf_p);
                  red := buf_p^;
                  Inc(buf_p);
                  alphabyte := 255;
                end;
              32:
                begin
                  blue := buf_p^;
                  Inc(buf_p);
                  green := buf_p^;
                  Inc(buf_p);
                  red := buf_p^;
                  Inc(buf_p);
                  alphabyte := buf_p^;
                  Inc(buf_p);
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
              Inc(pixbuf);
              pixbuf^ := green;
              Inc(pixbuf);
              pixbuf^ := blue;
              Inc(pixbuf);
              pixbuf^ := alphabyte;
              Inc(pixbuf);
              Inc(column);
              if (column = columns) then
              begin // run spans across rows
                column := 0;
                if (row > 0) then
                  Dec(row)
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
                    Inc(buf_p);
                    green := buf_p^;
                    Inc(buf_p);
                    red := buf_p^;
                    Inc(buf_p);
                    pixbuf^ := red;
                    Inc(pixbuf);
                    pixbuf^ := green;
                    Inc(pixbuf);
                    pixbuf^ := blue;
                    Inc(pixbuf);
                    pixbuf^ := 255;
                    Inc(pixbuf);
                  end;
                32:
                  begin
                    blue := buf_p^;
                    Inc(buf_p);
                    green := buf_p^;
                    Inc(buf_p);
                    red := buf_p^;
                    Inc(buf_p);
                    alphabyte := buf_p^;
                    Inc(buf_p);
                    pixbuf^ := red;
                    Inc(pixbuf);
                    pixbuf^ := green;
                    Inc(pixbuf);
                    pixbuf^ := blue;
                    Inc(pixbuf);
                    pixbuf^ := alphabyte;
                    Inc(pixbuf);
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
        Dec(Row);
      end;
    end;
  ri.FS_FreeFile(buffer);
end;

{*
====================================================================

IMAGE FLOOD FILLING

====================================================================
*}

{*
=================
Mod_FloodFillSkin

Fill background pixels so mipmapping doesn't have haloes
=================
*}
type
  floodfill_t = record
    x, y: SmallInt;
  end;

// must be a power of 2
const
  FLOODFILL_FIFO_SIZE = $1000;
  FLOODFILL_FIFO_MASK = (FLOODFILL_FIFO_SIZE - 1);

procedure R_FloodFillSkin(skin: PByte; skinwidth, skinheight: integer);
var
  fillcolor: Byte; // assume this is the pixel to fill
  fifo: array[0..FLOODFILL_FIFO_SIZE - 1] of floodfill_t;
  inpt, outpt: Integer;
  filledcolor: Integer;
  x, y, i, fdc: Integer;
  pos: PByte;

  procedure FLOODFILL_STEP(off, dx, dy: Integer);
  begin
    if (PByteArray(pos)^[off] = fillcolor) then
    begin
      PByteArray(pos)[off] := 255;
      fifo[inpt].x := x + (dx);
      fifo[inpt].y := y + (dy);
      inpt := (inpt + 1) and FLOODFILL_FIFO_MASK;
    end
    else
      if (PByteArray(pos)^[off] <> 255) then
        fdc := PByteArray(pos)^[off];
  end;

begin
  fillcolor := skin^; // assume this is the pixel to fill
  inpt := 0;
  outpt := 0;
  filledcolor := -1;

  if (filledcolor = -1) then
  begin
    filledcolor := 0;
    // attempt to find opaque black
    for i := 1 to 256 - 1 do
      if (d_8to24table[i] = (255 shl 0)) then // alpha 1.0
      begin
        filledcolor := i;
        break;
      end;
  end;

  // can't fill to filled color or to transparent color (used as visited marker)
  if ((fillcolor = filledcolor) or (fillcolor = 255)) then
  begin
    //printf( "not filling skin from %d to %d\n", fillcolor, filledcolor );
    Exit;
  end;

  fifo[inpt].x := 0;
  fifo[inpt].y := 0;
  inpt := (inpt + 1) and FLOODFILL_FIFO_MASK;

  while (outpt <> inpt) do
  begin
    x := fifo[outpt].x;
    y := fifo[outpt].y;
    fdc := filledcolor;
    pos := @PByteArray(skin)^[x + skinwidth * y];

    outpt := (outpt + 1) and FLOODFILL_FIFO_MASK;

    if (x > 0) then
      FLOODFILL_STEP(-1, -1, 0);
    if (x < skinwidth - 1) then
      FLOODFILL_STEP(1, 1, 0);
    if (y > 0) then
      FLOODFILL_STEP(-skinwidth, 0, -1);
    if (y < skinheight - 1) then
      FLOODFILL_STEP(skinwidth, 0, 1);
    PByteArray(skin)^[x + skinwidth * y] := fdc;
  end;
end;

//=======================================================

{*
================
GL_ResampleTexture
================
*}
procedure GL_ResampleTexture(in_: PCardinal; inwidth, inheight: integer; out_: PCardinal; outwidth, outheight: integer);
var
  i, j: Integer;
  inrow, inrow2: PCardinal;
  frac, fracstep: Cardinal;
  p1, p2: array[0..1024 - 1] of Cardinal;
  pix1, pix2, pix3, pix4: PByteArray;
  tmp: PByteArray; // <- Added by Juha to ease some wicked pointer calculations.
begin
  fracstep := (inwidth * $10000) div outwidth;

  frac := fracstep shr 2;
  for i := 0 to outwidth - 1 do
  begin
    p1[i] := 4 * (frac shr 16);
    frac := frac + fracstep;
  end;
  frac := 3 * (fracstep shr 2);
  for i := 0 to outwidth - 1 do
  begin
    p2[i] := 4 * (frac shr 16);
    frac := frac + fracstep;
  end;

  for i := 0 to outheight - 1 do
  begin
    inrow := Pointer(Cardinal(in_) + (inwidth * Trunc((i + 0.25) * inheight / outheight)) * sizeof(Cardinal));
    inrow2 := Pointer(Cardinal(in_) + (inwidth * Trunc((i + 0.75) * inheight / outheight)) * sizeof(Cardinal));
    frac := fracstep shr 1;
    for j := 0 to outwidth - 1 do
    begin
      pix1 := Pointer(Cardinal(inrow) + p1[j]);
      pix2 := Pointer(Cardinal(inrow) + p2[j]);
      pix3 := Pointer(Cardinal(inrow2) + p1[j]);
      pix4 := Pointer(Cardinal(inrow2) + p2[j]);
      tmp := Pointer(Cardinal(out_) + j * sizeof(Cardinal));
      tmp[0] := (pix1[0] + pix2[0] + pix3[0] + pix4[0]) shr 2;
      tmp[1] := (pix1[1] + pix2[1] + pix3[1] + pix4[1]) shr 2;
      tmp[2] := (pix1[2] + pix2[2] + pix3[2] + pix4[2]) shr 2;
      tmp[3] := (pix1[3] + pix2[3] + pix3[3] + pix4[3]) shr 2;
    end;
    Inc(out_, outwidth);
  end;
end;

{*
================
GL_LightScaleTexture

Scale up the pixel values in a texture to increase the
lighting range
================
*}
procedure GL_LightScaleTexture(in_: PCardinal; inwidth, inheight: integer; only_gamma: qboolean);
var
  i, c: Integer;
  p: PByte;
begin
  if (only_gamma) then
  begin
    p := PByte(in_);
    c := inwidth * inheight;
    for i := 0 to c - 1 do
    begin
      PByteArray(p)^[0] := gammatable[PByteArray(p)^[0]];
      PByteArray(p)^[1] := gammatable[PByteArray(p)^[1]];
      PByteArray(p)^[2] := gammatable[PByteArray(p)^[2]];
      Inc(p, 4);
    end;
  end
  else
  begin
    p := PByte(in_);
    c := inwidth * inheight;
    for i := 0 to c - 1 do
    begin
      PByteArray(p)^[0] := gammatable[intensitytable[PByteArray(p)^[0]]];
      PByteArray(p)^[1] := gammatable[intensitytable[PByteArray(p)^[1]]];
      PByteArray(p)^[2] := gammatable[intensitytable[PByteArray(p)^[2]]];
      Inc(p, 4);
    end;
  end;
end;

{*
================
GL_MipMap

Operates in place, quartering the size of the texture
================
*}
procedure GL_MipMap(in_: PByteArray; width, height: integer);
var
  i, j: integer;
  out_: PByteArray;
begin
  width := width shl 2;
  height := height shr 1;
  out_ := in_;
  for i := 0 to height - 1 do
  begin
    j := 0;
    while (j < width) do
    begin
      out_[0] := (in_[0] + in_[4] + in_[width + 0] + in_[width + 4]) shr 2;
      out_[1] := (in_[1] + in_[5] + in_[width + 1] + in_[width + 5]) shr 2;
      out_[2] := (in_[2] + in_[6] + in_[width + 2] + in_[width + 6]) shr 2;
      out_[3] := (in_[3] + in_[7] + in_[width + 3] + in_[width + 7]) shr 2;
      Inc(j, 8);
      out_ := Pointer(Cardinal(out_) + 4);
      in_ := Pointer(Cardinal(in_) + 8);
    end;
    in_ := Pointer(Cardinal(in_) + width);
  end;
end;

{*
===============
GL_Upload32

Returns has_alpha
===============
*}
procedure GL_BuildPalettedTexture(paletted_texture: PByte; scaled: PByte; scaled_width, scaled_height: integer);
var
  i: integer;
  r, g, b, c: Cardinal;
begin
  for i := 0 to scaled_width * scaled_height - 1 do
  begin
    r := (PByteArray(scaled)^[0] shr 3) and 31;
    g := (PByteArray(scaled)^[1] shr 2) and 63;
    b := (PByteArray(scaled)^[2] shr 3) and 31;

    c := r or (g shl 5) or (b shl 11);

    PByteArray(paletted_texture)[i] := gl_state.d_16to8table[c];

    Inc(scaled, 4);
  end;
end;

var
  upload_width, upload_height: integer;
  uploaded_paletted: qboolean;

function GL_Upload32(data: PCardinal; width, height: integer; mipmap: qboolean): qboolean;
var
  scaled: array[0..256 * 256 - 1] of Cardinal;
  paletted_texture: array[0..256 * 256 - 1] of byte;
  samples,
  scaled_width, scaled_height,
  miplevel: integer;
  i, c: Integer;
  scan: PByte;
  comp: Integer;
label
  done;
begin
  uploaded_paletted := false;

  scaled_width := 1;
  while (scaled_width < width) do
    scaled_width := scaled_width shl 1;
  if (gl_round_down^.value <> 0) and (scaled_width > width) and (mipmap) then
    scaled_width := scaled_width shr 1;
  scaled_height := 1;
  while (scaled_height < height) do
    scaled_height := scaled_height shl 1;
  if (gl_round_down^.value <> 0) and (scaled_height > height) and (mipmap) then
    scaled_height := scaled_height shr 1;

  // let people sample down the world textures for speed
  if (mipmap) then
  begin
    scaled_width := scaled_width shr Trunc(gl_picmip^.Value);
    scaled_height := scaled_height shr Trunc(gl_picmip^.value);
  end;

  // don't ever bother with >256 textures
  if (scaled_width > 256) then
    scaled_width := 256;
  if (scaled_height > 256) then
    scaled_height := 256;

  if (scaled_width < 1) then
    scaled_width := 1;
  if (scaled_height < 1) then
    scaled_height := 1;

  upload_width := scaled_width;
  upload_height := scaled_height;

  if (scaled_width * scaled_height > sizeof(scaled) / 4) then
    ri.Sys_Error(ERR_DROP, 'GL_Upload32: too big');

  // scan the texture for any non-255 alpha
  c := width * height;
  scan := Pointer(Cardinal(data) + 3);
  samples := gl_solid_format;
  for i := 0 to c - 1 do
  begin
    if (scan^ <> 255) then
    begin
      samples := gl_alpha_format;
      break;
    end;
    Inc(scan, 4);
  end;

  if (samples = gl_solid_format) then
    comp := gl_tex_solid_format
  else
    if (samples = gl_alpha_format) then
      comp := gl_tex_alpha_format
    else
    begin
      ri.Con_Printf(PRINT_ALL,
        'Unknown number of texture components %i'#10,
        samples);
      comp := samples;
    end;

{*
  if (mipmap)
          gluBuild2DMipmaps (GL_TEXTURE_2D, samples, width, height, GL_RGBA, GL_UNSIGNED_BYTE, trans);
  else if (scaled_width == width && scaled_height == height)
          qglTexImage2D (GL_TEXTURE_2D, 0, comp, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, trans);
  else
  )
          gluScaleImage (GL_RGBA, width, height, GL_UNSIGNED_BYTE, trans,
                  scaled_width, scaled_height, GL_UNSIGNED_BYTE, scaled);
          qglTexImage2D (GL_TEXTURE_2D, 0, comp, scaled_width, scaled_height, 0, GL_RGBA, GL_UNSIGNED_BYTE, scaled);
  )
*}

  if (scaled_width = width) and (scaled_height = height) then
  begin
    if (not mipmap) then
    begin
      if (Assigned(qglColorTableEXT) and (gl_ext_palettedtexture.value <> 0) and (samples = gl_solid_format)) then
      begin
        uploaded_paletted := true;
        GL_BuildPalettedTexture(@paletted_texture, PByte(data), scaled_width, scaled_height);
        qglTexImage2D(GL_TEXTURE_2D,
          0,
          GL_COLOR_INDEX8_EXT,
          scaled_width,
          scaled_height,
          0,
          GL_COLOR_INDEX,
          GL_UNSIGNED_BYTE,
          @paletted_texture);
      end
      else
        qglTexImage2D(GL_TEXTURE_2D, 0, comp, scaled_width, scaled_height, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);
      goto done;
    end;
    memcpy(@scaled, data, width * height * 4);
  end
  else
    GL_ResampleTexture(data, width, height, @scaled, scaled_width, scaled_height);

  GL_LightScaleTexture(@scaled, scaled_width, scaled_height, not mipmap);

  if (Assigned(qglColorTableEXT) and (gl_ext_palettedtexture.Value <> 0) and (samples = gl_solid_format)) then
  begin
    uploaded_paletted := true;
    GL_BuildPalettedTexture(@paletted_texture, @scaled, scaled_width, scaled_height);
    qglTexImage2D(GL_TEXTURE_2D,
      0,
      GL_COLOR_INDEX8_EXT,
      scaled_width,
      scaled_height,
      0,
      GL_COLOR_INDEX,
      GL_UNSIGNED_BYTE,
      @paletted_texture);
  end
  else
    qglTexImage2D(GL_TEXTURE_2D, 0, comp, scaled_width, scaled_height, 0, GL_RGBA, GL_UNSIGNED_BYTE, @scaled);

  if (mipmap) then
  begin
    miplevel := 0;
    while (scaled_width > 1) or (scaled_height > 1) do
    begin
      GL_MipMap(@scaled, scaled_width, scaled_height);
      scaled_width := scaled_width shr 1;
      scaled_height := scaled_height shr 1;
      if (scaled_width < 1) then
        scaled_width := 1;
      if (scaled_height < 1) then
        scaled_height := 1;
      Inc(miplevel);
      if (Assigned(qglColorTableEXT) and (gl_ext_palettedtexture.Value <> 0) and (samples = gl_solid_format)) then
      begin
        uploaded_paletted := true;
        GL_BuildPalettedTexture(@paletted_texture, @scaled, scaled_width, scaled_height);
        qglTexImage2D(GL_TEXTURE_2D,
          miplevel,
          GL_COLOR_INDEX8_EXT,
          scaled_width,
          scaled_height,
          0,
          GL_COLOR_INDEX,
          GL_UNSIGNED_BYTE,
          @paletted_texture);
      end
      else
        qglTexImage2D(GL_TEXTURE_2D, miplevel, comp, scaled_width, scaled_height, 0, GL_RGBA, GL_UNSIGNED_BYTE, @scaled);
    end;
  end;
  done: ;

  if (mipmap) then
  begin
    qglTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, gl_filter_min);
    qglTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, gl_filter_max)
  end
  else
  begin
    qglTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, gl_filter_max);
    qglTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, gl_filter_max);
  end;

  Result := (samples = gl_alpha_format);
end;

{*
===============
GL_Upload8

Returns has_alpha
===============
*}
(*
static qboolean IsPowerOf2( int value )
{
 int i = 1;

 while ( 1 )
 {
  if ( value == i )
   return true;
  if ( i > value )
   return false;
  i <<= 1;
 }
}
*)

function GL_Upload8(data: PByteArray; width, height: integer; mipmap, is_sky: qboolean): qboolean;
var
  trans: array[0..512 * 256 - 1] of Cardinal;
  i, s, p: integer;
begin
  s := width * height;

  if (s > sizeof(trans) / 4) then
    ri.Sys_Error(ERR_DROP, 'GL_Upload8: too large');

  if Assigned(qglColorTableEXT) and
    (gl_ext_palettedtexture.value <> 0) and (is_sky) then
  begin
    qglTexImage2D(GL_TEXTURE_2D,
      0,
      GL_COLOR_INDEX8_EXT,
      width,
      height,
      0,
      GL_COLOR_INDEX,
      GL_UNSIGNED_BYTE,
      data);

    qglTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, gl_filter_max);
    qglTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, gl_filter_max);
  end
  else
  begin
    for i := 0 to s - 1 do
    begin
      p := data[i];
      trans[i] := d_8to24table[p];

      if (p = 255) then
      begin
        // transparent, so scan around for another color
        // to avoid alpha fringes
        // FIXME: do a full flood fill so mips work...
        if (i > width) and (data[i - width] <> 255) then
          p := data[i - width]
        else
          if (i < s - width) and (data[i + width] <> 255) then
            p := data[i + width]
          else
            if (i > 0) and (data[i - 1] <> 255) then
              p := data[i - 1]
            else
              if (i < s - 1) and (data[i + 1] <> 255) then
                p := data[i + 1]
              else
                p := 0;

        // copy rgb components
        PByteArray(@trans[i])^[0] := PByteArray(@d_8to24table[p])^[0];
        PByteArray(@trans[i])^[1] := PByteArray(@d_8to24table[p])^[1];
        PByteArray(@trans[i])^[2] := PByteArray(@d_8to24table[p])^[2];
      end;
    end;

    Result := GL_Upload32(@trans, width, height, mipmap);
  end;
end;

{*
================
GL_LoadPic

This is also used as an entry point for the generated r_notexture
================
*}
function GL_LoadPic(name: PChar; pic: PByte; width, height: integer; _type: imagetype_t; bits: integer): image_p;
var
  image: image_p;
  i, j, k,
    x, y,
    texnum: integer;
label
  nonscrap;
begin
  // find a free image_t
  image := @gltextures;
  i := 0;
  while (i < numgltextures) do
  begin
    if (image^.texnum = 0) then
      break;
    inc(image);
    inc(i);
  end;
  if (i = numgltextures) then
  begin
    if (numgltextures = MAX_GLTEXTURES) then
      ri.Sys_Error(ERR_DROP, 'MAX_GLTEXTURES');
    Inc(numgltextures);
  end;
  image := @gltextures[i];

  if (strlen(name) >= sizeof(image^.name)) then
    ri.Sys_Error(ERR_DROP, 'Draw_LoadPic: "%s" is too long', name);
  strcpy(image^.name, name);
  image^.registration_sequence := registration_sequence;

  image.width := width;
  image.height := height;
  image.type_ := _type;

  if (_type = it_skin) and (bits = 8) then
    R_FloodFillSkin(pic, width, height);

  // load little pics into the scrap
  if (image.type_ = it_pic) and (bits = 8) and
    (image.width < 64) and (image.height < 64) then
  begin
    texnum := Scrap_AllocBlock(image.width, image.height, x, y);
    if (texnum = -1) then
      goto nonscrap;
    scrap_dirty := true;

    // copy the texels into the scrap block
    k := 0;
    for i := 0 to image.height - 1 do
      for j := 0 to image^.width - 1 do
      begin
        scrap_texels[texnum][(y + i) * BLOCK_WIDTH + x + j] := PByteArray(pic)^[k];
        Inc(k);
      end;
    image.texnum := TEXNUM_SCRAPS + texnum;
    image.scrap := true;
    image.has_alpha := true;
    image.sl := (x + 0.01) / BLOCK_WIDTH;
    image.sh := (x + image.width - 0.01) / BLOCK_WIDTH;
    image.tl := (y + 0.01) / BLOCK_WIDTH;
    image.th := (y + image.height - 0.01) / BLOCK_WIDTH;
  end
  else
  begin
    nonscrap:
    image.scrap := false;
    image.texnum := TEXNUM_IMAGES + ((Integer(image) - Integer(@gltextures)) div sizeof(image_t));
    GL_Bind(image^.texnum);
    if (bits = 8) then
      image.has_alpha := GL_Upload8(PByteArray(pic), width, height, ((image.type_ <> it_pic) and (image.type_ <> it_sky)), (image.type_ = it_sky))
    else
      image.has_alpha := GL_Upload32(PCardinal(pic), width, height, ((image.type_ <> it_pic) and (image.type_ <> it_sky)));
    image.upload_width := upload_width; // after power of 2 and scales
    image.upload_height := upload_height;
    image.paletted := uploaded_paletted;
    image.sl := 0;
    image.sh := 1;
    image.tl := 0;
    image.th := 1;
  end;

  Result := image;
end;

{*
================
GL_LoadWal
================
*}
function GL_LoadWal(name: PChar): image_p;
var
  mt: miptex_p;
  width, height, ofs: Integer;
  image: image_p;
begin
  ri.FS_LoadFile(name, @mt);
  if (mt = nil) then
  begin
    ri.Con_Printf(PRINT_ALL, 'GL_FindImage: can''t load %s'#10, name);
    Result := r_notexture;
    exit;
  end;

  width := LittleLong(mt^.width);
  height := LittleLong(mt^.height);
  ofs := LittleLong(mt^.offsets[0]);

  image := GL_LoadPic(name, Pointer(Cardinal(mt) + ofs), width, height, it_wall, 8);

  ri.FS_FreeFile(mt);

  Result := image;
end;

{*
===============
GL_FindImage

Finds or loads the given image
===============
*}
function GL_FindImage(name: PChar; _type: imagetype_t): image_p;
var
  image: image_p;
  i, len: integer;
  pic, palette: PByte;
  width, height: integer;
begin
  if (name = nil) then
  begin
    result := nil; //ri.Sys_Error (ERR_DROP, "GL_FindImage: NULL name");
    Exit;
  end;
  len := strlen(name);
  if (len < 5) then
  begin
    Result := nil; //ri.Sys_Error (ERR_DROP, "GL_FindImage: bad name: %s", name);
    Exit;
  end;

  // look for it
  image := @gltextures;
  for i := 0 to numgltextures - 1 do
  begin
    if (strcmp(name, image^.name) = 0) then
    begin
      image^.registration_sequence := registration_sequence;
      Result := image;
      exit;
    end;
    inc(image);
  end;

  //
  // load the pic from disk
  //
  pic := nil;
  palette := nil;
  if strcmp(name + len - 4, '.pcx') = 0 then
  begin
    LoadPCX(name, @pic, @palette, @width, @height);
    if (pic = nil) then
    begin
      Result := nil; // ri.Sys_Error (ERR_DROP, "GL_FindImage: can't load %s", name);
      Exit;
    end;
    image := GL_LoadPic(name, pic, width, height, _type, 8);
  end
  else
    if strcmp(name + len - 4, '.wal') = 0 then
      image := GL_LoadWal(name)
    else
      if strcmp(name + len - 4, '.tga') = 0 then
      begin
        LoadTGA(name, @pic, @width, @height);
        if (pic = nil) then
        begin
          Result := nil; // ri.Sys_Error (ERR_DROP, "GL_FindImage: can't load %s", name);
          Exit;
        end;
        image := GL_LoadPic(name, pic, width, height, _type, 32);
      end
      else
      begin
        Result := nil; //ri.Sys_Error (ERR_DROP, "GL_FindImage: bad extension on: %s", name);
        Exit;
      end;

  if Assigned(pic) then
    FreeMem(pic);
  if Assigned(palette) then
    FreeMem(palette);

  Result := image;
end;

{*
===============
R_RegisterSkin
===============
*}
function R_RegisterSkin(name: PChar): pointer; cdecl;
begin
  Result := GL_FindImage(name, it_skin);
end;

{*
================
GL_FreeUnusedImages

Any image that was not touched on this registration sequence
will be freed.
================
*}
procedure GL_FreeUnusedImages;
var
  i: integer;
  image: image_p;
label
  continue_;
begin
  // never free r_notexture or particle texture
  r_notexture.registration_sequence := registration_sequence;
  r_particletexture.registration_sequence := registration_sequence;

  image := @gltextures;
  for i := 0 to numgltextures - 1 do
  begin
    if (image^.registration_sequence = registration_sequence) then
      goto continue_; // used this sequence
    if (image^.registration_sequence = 0) then
      goto continue_; // free image_t slot
    if (image^.type_ = it_pic) then
      goto continue_; // don't free pics
    // free it
    qglDeleteTextures(1, @image.texnum);
    memset(image, 0, sizeof(image^));
    continue_:
    Inc(image);
  end;
end;

{*
===============
Draw_GetPalette
===============
*}
function Draw_GetPalette: integer;
var
  i,
  r, g, b,
  width, height: integer;
  v: Cardinal;
  pic, pal: PByteArray;
begin
  // get the palette

  LoadPCX('pics/colormap.pcx', @pic, @pal, @width, @height);
  if (pal = nil) then
    ri.Sys_Error(ERR_FATAL, 'Couldn''t load pics/colormap.pcx', []);

  for i := 0 to 255 do
  begin
    r := pal[i * 3 + 0];
    g := pal[i * 3 + 1];
    b := pal[i * 3 + 2];

    v := (255 shl 24) + (r shl 0) + (g shl 8) + (b shl 16);
    d_8to24table[i] := LittleLong(v);
  end;

  d_8to24table[255] := d_8to24table[255] and LittleLong($FFFFFF); // 255 is transparent

  FreeMem(pic);
  FreeMem(pal);

  Result := 0;
end;

{*
===============
GL_InitImages
===============
*}
procedure GL_InitImages;
var
  i, j: integer;
  g, inf: Single;
begin
  g := vid_gamma.value;

  registration_sequence := 1;

  // init intensity conversions
  intensity := ri.Cvar_Get('intensity', '2', 0);

  if (intensity.value <= 1) then
    ri.Cvar_Set('intensity', '1');

  gl_state.inverse_intensity := 1 / intensity.value;

  Draw_GetPalette();

  if Assigned(qglColorTableEXT) then
  begin
    ri.FS_LoadFile('pics/16to8.dat', @gl_state.d_16to8table);
    if (gl_state.d_16to8table = nil) then
      ri.Sys_Error(ERR_FATAL, 'Couldn''t load pics/16to8.pcx', []);
  end;

  if (gl_config.renderer and (GL_RENDERER_VOODOO or GL_RENDERER_VOODOO2)) <> 0 then
    g := 1.0;

  for i := 0 to 255 do
    if (g = 1) then
      gammatable[i] := i
    else
    begin
      inf := 255 * power((i + 0.5) / 255.5, g) + 0.5;
      if (inf < 0) then
        inf := 0;
      if (inf > 255) then
        inf := 255;
      gammatable[i] := Trunc(inf);
    end;

  for i := 0 to 255 do
  begin
    j := Trunc(i * intensity.value);
    if (j > 255) then
      j := 255;
    intensitytable[i] := j;
  end;
end;

{*
===============
GL_ShutdownImages
===============
*}
procedure GL_ShutdownImages;
var
  i: integer;
  image: image_p;
begin
  image := @gltextures;
  for i := 0 to numgltextures - 1 do
  begin
    if (image^.registration_sequence = 0) then
    begin
      Inc(image);
      continue; // free image_t slot
    end;
    // free it
    qglDeleteTextures(1, @image.texnum);
    memset(image, 0, sizeof(image^));
    Inc(image);
  end;
end;

end.
