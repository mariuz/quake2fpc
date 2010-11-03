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
{ File(s): gl_local.c                                                        }
{                                                                            }
{ Initial conversion by : YgriK (Igor Karpov) - glYgriK@hotbox.ru            }
{ Initial conversion on : 14-Feb-2002                                        }
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

unit gl_local;

interface

uses
  SysUtils,
  DelphiTypes,
  OpenGL,
  ref,
  q_shared,
  gl_local_add,
  gl_model_h;

const
  GL_COLOR_INDEX8_EXT = GL_COLOR_INDEX;


const
  REF_VERSION = 'GL 0.01';

  // up / down
  PITCH   = 0;

  // left / right
  YAW   = 1;

  // fall over
  ROLL   = 2;

type
  viddef_t = record
    width, height : integer;  // coordinates from main game
  end;


{*

  skins will be outline flood filled and mip mapped
  pics and sprites with alpha will be outline flood filled
  pic won't be mip mapped

  model skin
  sprite frame
  wall texture
  pic

*}
type
  imagetype_t = gl_local_add.imagetype_t;

  image_p = gl_local_add.image_p;
  image_t = gl_local_add.image_t;

const
  TEXNUM_LIGHTMAPS = 1024;
  TEXNUM_SCRAPS      = 1152;
  TEXNUM_IMAGES      = 1153;

  MAX_GLTEXTURES   = 1024;

//===================================================================

type
  rserr_t = (rserr_ok, rserr_invalid_fullscreen, rserr_invalid_mode, rserr_unknown);


  glvert_t = record
    x, y, z,
    s, t,
    r, g, b : Single;
  end;

const
  MAX_LBM_HEIGHT   = 480;

  BACKFACE_EPSILON = 0.01;

(*
** GL extension emulation functions
*)

(*
** GL config stuff
*)
const
  GL_RENDERER_VOODOO     = $00000001;
  GL_RENDERER_VOODOO2     = $00000002;
  GL_RENDERER_VOODOO_RUSH = $00000004;
  GL_RENDERER_BANSHEE     = $00000008;
  GL_RENDERER_3DFX     = $0000000F;

  GL_RENDERER_PCX1     = $00000010;
  GL_RENDERER_PCX2     = $00000020;
  GL_RENDERER_PMX     = $00000040;
  GL_RENDERER_POWERVR     = $00000070;

  GL_RENDERER_PERMEDIA2     = $00000100;
  GL_RENDERER_GLINT_MX     = $00000200;
  GL_RENDERER_GLINT_TX     = $00000400;
  GL_RENDERER_3DLABS_MISC = $00000800;
  GL_RENDERER_3DLABS     = $00000F00;

  GL_RENDERER_REALIZM     = $00001000;
  GL_RENDERER_REALIZM2     = $00002000;
  GL_RENDERER_INTERGRAPH  = $00003000;

  GL_RENDERER_3DPRO     = $00004000;
  GL_RENDERER_REAL3D     = $00008000;
  GL_RENDERER_RIVA128     = $00010000;
  GL_RENDERER_DYPIC     = $00020000;

  GL_RENDERER_V1000     = $00040000;
  GL_RENDERER_V2100     = $00080000;
  GL_RENDERER_V2200     = $00100000;
  GL_RENDERER_RENDITION     = $001C0000;

  GL_RENDERER_O2          = $00100000;
  GL_RENDERER_IMPACT      = $00200000;
  GL_RENDERER_RE     = $00400000;
  GL_RENDERER_IR     = $00800000;
  GL_RENDERER_SGI     = $00F00000;

  GL_RENDERER_MCD     = $01000000;
  GL_RENDERER_OTHER     = $80000000;

type
  glconfig_t = record
    renderer : integer;
{   const char *renderer_string;
   const char *vendor_string;
   const char *version_string;
   const char *extensions_string;}
    renderer_string,
    vendor_string,
    version_string,
    extensions_string : PChar;

    allow_cds : qboolean;
  end;

  glstate_t = record
    inverse_intensity : Single;
    fullscreen : qboolean;

    prev_mode : integer;

//   unsigned char *d_16to8table;
    d_16to8table: PByteArray;

    lightmap_textures : integer;

    currenttextures : array [0..1] of integer;
    currenttmu : integer;

    camera_separation : Single;
    stereo_enabled : qboolean;

    originalRedGammaTable,
    originalGreenGammaTable,
    originalBlueGammaTable   : array [0..255] of char; //OR byte
  end;

implementation

// End of file
end.
