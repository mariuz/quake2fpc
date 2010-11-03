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

{$ALIGN ON}{$MINENUMSIZE 4}
{----------------------------------------------------------------------------}
{                                                                            }
{ File(s): sys_null.c - null system driver to aid porting efforts            }
{                                                                            }
{ Initial conversion by : MathD (matheus@tilt.net)                           }
{ Initial conversion on : 10-Jan-2002                                        }
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
{ none                                                                       }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{ 1.) TO be tested                                                           }
{----------------------------------------------------------------------------}
{ 28.06.2003 Juha: Proofreaded }

unit gl_rmisc;

// r_misc.c

interface

uses
  DelphiTypes,
  gl_local;

procedure GL_UpdateSwapInterval;
procedure GL_SetDefaultState;
procedure R_InitParticleTexture;
procedure GL_ScreenShot_f; cdecl;
procedure GL_Strings_f; cdecl;


{/*
==================
R_InitParticleTexture
==================
*/}

const
  dottexture: array[0..7, 0..7] of byte = (
    (0, 0, 0, 0, 0, 0, 0, 0),
    (0, 0, 1, 1, 0, 0, 0, 0),
    (0, 1, 1, 1, 1, 0, 0, 0),
    (0, 1, 1, 1, 1, 0, 0, 0),
    (0, 0, 1, 1, 0, 0, 0, 0),
    (0, 0, 0, 0, 0, 0, 0, 0),
    (0, 0, 0, 0, 0, 0, 0, 0),
    (0, 0, 0, 0, 0, 0, 0, 0)
    );

implementation

uses
  OpenGL,
  CPas,
  SysUtils,
  q_shared,
  qgl_win,
  gl_rmain,
  gl_local_add,
  gl_image,
  q_shwin;

procedure R_InitParticleTexture;
var
  x, y: integer;
  data: array[0..7, 0..7, 0..3] of byte;
begin
  //
  // particle texture
  //
  for x := 0 to 7 do
  begin
    for y := 0 to 7 do
    begin
      data[y, x, 0] := 255;
      data[y, x, 1] := 255;
      data[y, x, 2] := 255;
      data[y, x, 3] := dottexture[x, y] * 255;
    end;
  end;
  r_particletexture := GL_LoadPic('***particle***', @data, 8, 8, it_sprite, 32);

  //
  // also use this for bad textures, but without alpha
  //
  for x := 0 to 7 do
  begin
    for y := 0 to 7 do
    begin
      data[y, x, 0] := dottexture[x and 3, y and 3] * 255;
      data[y, x, 1] := 0; // dottexture[x&3][y&3]*255;
      data[y, x, 2] := 0; // dottexture[x&3][y&3]*255;
      data[y, x, 3] := 255;
    end;
  end;
  r_notexture := GL_LoadPic('***r_notexture***', @data, 8, 8, it_wall, 32);
end;


{/*
==============================================================================

      SCREEN SHOTS

==============================================================================
*/}
{  //redundant declaration fixed by FAB
type
  _TargaHeader = record
    id_length, colormap_type, image_type: char;
    colormap_index, colormap_length: word;
    colormap_size: byte;
    x_origin, y_origin, width, height: word;
    pixel_size, attributes: byte;
  end;
}
{
==================
GL_ScreenShot_f
==================
}
procedure GL_ScreenShot_f;
var
  buffer: PByteArray ; //array of byte;
  picname: array[0..79] of char;
  checkname: array[0..MAX_OSPATH - 1] of char;
  i, c, temp: integer;
  f :integer ;
begin
  // create the scrnshots directory if it doesn't exist
  Com_sprintf(checkname, sizeof(checkname), '%s/scrnshot', [ri.FS_Gamedir]);
  Sys_MkDir(checkname);

  //
  // find a file name to save it to
  //
  strPCopy(picname, 'quake00.tga');
  for i := 0 to 99 do
  begin
    picname[5] := Char(i div 10 + Byte('0'));
    picname[6] := Char(i mod 10 + Byte('0'));
    Com_sprintf(checkname, sizeof(checkname), '%s/scrnshot/%s', [ri.FS_Gamedir, picname]);


    f:= fileOpen (checkname ,fmOpenRead);
    if f < 0 then
    Break;     // file doesn't exist
    Fileclose (f);
  end;

  if i = 100 then
  begin
    ri.Con_Printf(PRINT_ALL, 'SCR_ScreenShot_f: Couldn''t create a file'#10);
    exit;
  end;

  //SetLength(buffer, (vid.width * vid.height * 3 + 18) );
  buffer := malloc(vid.width*vid.height*3 + 18);
  //memset (buffer, 0, 18); //---this should zero the mem. Not needed since AllocMem does that
  buffer[2] := 2; //uncompressed type
  buffer[12] := vid.width and 255;
  buffer[13] := vid.width shr 8;
  buffer[14] := vid.height and 255;
  buffer[15] := vid.height shr 8;
  buffer[16] := 24; //pixel size

  qglReadPixels(0, 0, vid.width, vid.height, GL_RGB, GL_UNSIGNED_BYTE, Pointer(Integer(buffer) + 18));

  //swap rgb to bgr
  c := 18 + (vid.width * vid.height * 3);

  i := 18;
  while i < c-1 do
  begin
    temp := buffer[i];
    buffer[i] := buffer[i + 2];
    buffer[i + 2] := temp;
    inc (i,3);
  end;

  f := FileCreate(checkname);
   if f < 0 then
  ri.Con_Printf (PRINT_ALL, 'Failed to create  %s'#10, checkname)  //changed by Fab
  else
       begin
        FileWrite (f, buffer^ ,c);
        FileClose(f);
       end;
  FreeMem(buffer);
  ri.Con_Printf(PRINT_ALL, 'Wrote %s'#10, picname);
end;

{/*
** GL_Strings_f
*/}

procedure GL_Strings_f;
begin
  ri.Con_Printf(PRINT_ALL, 'GL_VENDOR: %s'#10, gl_config.vendor_string);
  ri.Con_Printf(PRINT_ALL, 'GL_RENDERER: %s'#10, gl_config.renderer_string);
  ri.Con_Printf(PRINT_ALL, 'GL_VERSION: %s'#10, gl_config.version_string);
  ri.Con_Printf(PRINT_ALL, 'GL_EXTENSIONS: %s'#10, gl_config.extensions_string);
end;

{/*
** GL_SetDefaultState
*/}

procedure GL_SetDefaultState;
var
  attenuations: array[0..2] of single;
begin
  qglClearColor(1, 0, 0.5, 0.5);
  qglCullFace(GL_FRONT);
  qglEnable(GL_TEXTURE_2D);

  qglEnable(GL_ALPHA_TEST);
  qglAlphaFunc(GL_GREATER, 0.666);

  qglDisable(GL_DEPTH_TEST);
  qglDisable(GL_CULL_FACE);
  qglDisable(GL_BLEND);

  qglColor4f(1, 1, 1, 1);

  qglPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
  qglShadeModel(GL_FLAT);

  GL_TextureMode(gl_texturemode_^.string_);
  GL_TextureAlphaMode(gl_texturealphamode_^.string_);
  GL_TextureSolidMode(gl_texturesolidmode_^.string_);

  qglTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, gl_filter_min);
  qglTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, gl_filter_max);

  qglTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
  qglTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);

  qglBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

  GL_TexEnv(GL_REPLACE);

  if @qglPointParameterfExt <> nil then
  begin
    attenuations[0] := gl_particle_att_a.value;
    attenuations[1] := gl_particle_att_b.value;
    attenuations[2] := gl_particle_att_c.value;

    qglEnable(GL_POINT_SMOOTH);
    qglPointParameterfEXT(GL_POINT_SIZE_MIN_EXT, gl_particle_min_size^.value);
    qglPointParameterfEXT(GL_POINT_SIZE_MAX_EXT, gl_particle_max_size^.value);
    qglPointParameterfvEXT(GL_DISTANCE_ATTENUATION_EXT, @attenuations);
  end;

  if (@qglColorTableEXT <> nil) and (gl_ext_palettedtexture^.value <> 0) then
  begin
    qglEnable(GL_SHARED_TEXTURE_PALETTE_EXT);
    GL_SetTexturePalette(PCardinalArray(@d_8to24table));
  end;

  GL_UpdateSwapInterval();
end;

procedure GL_UpdateSwapInterval;
begin
  if gl_swapinterval^.modified then
  begin
    gl_swapinterval^.modified := false;
    if gl_state.stereo_enabled = false then
    begin
{$IFDEF WIN32}
      if @qwglSwapIntervalEXT<>nil then
        qwglSwapIntervalEXT(Trunc(gl_swapinterval^.value));
{$ENDIF}
    end;
  end;
end;

end.
