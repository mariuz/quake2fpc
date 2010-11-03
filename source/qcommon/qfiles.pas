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
{$ALIGN ON}{$MINENUMSIZE 4}
{----------------------------------------------------------------------------}
{                                                                            }
{ File(s): qfiles.h - quake file formats                                     }
{                                                                            }
{ Initial conversion by : Lars Middendorf (lmid@gmx.de)                      }
{ Initial conversion on : 07-Jan-2002                                        }
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
{ * Updated:                                                                 }
{ 1) 12-Jan-2002 - Clootie (clootie@reactor.ru)                              }
{    Added pointer types and changed formatting to be more Borland like      }
{ 2) 18-Feb-2002 - Carl A Kenner (carl_kenner@hotmail.com)                   }
{    Made it work in Delphi 3                                                }
{ 3) 23-Feb-2002 - Carl A Kenner (carl_kenner@hotmail.com)                   }
{    Added array types                                                       }
{    Made it use q_shared so that I could use the right types                }
{ 4) 26-Feb-2002 - Carl A Kenner (carl_kenner@hotmail.com)                   }
{    Made types the right size                                               }
{                                                                            }
{----------------------------------------------------------------------------}

unit QFiles;

(*
========================================================================

The .pak files are just a linear collapse of a directory tree

========================================================================
*)

interface
uses q_shared;

const
  IDPAKHEADER = ((ord('K') shl 24) + (ord('C') shl 16) + (ord('A') shl 8) + ord('P'));

type
  dpackfile_p = ^dpackfile_t;
  pdpackfile_t = dpackfile_p;
  dpackfile_t = record
    name: array[0..55] of char;
    filepos, filelen: Integer;
  end;
  dpackfile_at = array[0..0] of dpackfile_t;
  dpackfile_a = ^dpackfile_at;

  dpackheader_p = ^dpackheader_t;
  pdpackheader_t = dpackheader_p;
  dpackheader_t = record
    ident: Integer;                     // == IDPAKHEADER
    dirofs: Integer;
    dirlen: Integer;
  end;
  dpackheader_at = array[0..0] of dpackheader_t;
  dpackheader_a = ^dpackheader_at;

const
  MAX_FILES_IN_PACK = 4096;

  {
  ========================================================================

  PCX files are used for as many images as possible

  ========================================================================
  }
type
  pcx_p = ^pcx_t;
  ppcx_t = pcx_p;
  pcx_t = record
    manufacturer: Char;
    version: Char;
    encoding: Char;
    bits_per_pixel: Char;
    xmin, ymin, xmax, ymax: Word;
    hres, vres: Word;
    palette: array[0..47] of Byte;
    reserved: Char;
    color_planes: Byte;
    bytes_per_line: Word;
    palette_type: Word;
    filler: array[0..57] of Char;
    data: Byte;                         // unbounded
  end;
  pcx_at = array[0..0] of pcx_t;
  pcx_a = ^pcx_at;

  {
  ========================================================================

  .MD2 triangle model file format

  ========================================================================
  }

const
  IDALIASHEADER = ((ord('2') shl 24) + (ord('P') shl 16) + (ord('D') shl 8) + ord('I'));
  ALIAS_VERSION = 8;

  MAX_TRIANGLES = 4096;
  MAX_VERTS = 2048;
  MAX_FRAMES = 512;
  MAX_MD2SKINS = 32;
  MAX_SKINNAME = 64;

type
  dstvert_p = ^dstvert_t;
  dstvert_t = record
    s: Smallint;
    t: Smallint;
  end;
  dstvert_at = array[0..0] of dstvert_t;
  dstvert_a = ^dstvert_at;

  dtriangle_p = ^dtriangle_t;
  dtriangle_t = record
    index_xyz: array[0..2] of Smallint;
    index_st: array[0..2] of Smallint;
  end;
  dtriangle_at = array[0..0] of dtriangle_t;
  dtriangle_a = ^dtriangle_at;

  dtrivertx_p = ^dtrivertx_t;
  dtrivertx_t = record
    v: array[0..2] of Byte;             // scaled byte to fit in frame mins/maxs
    lightnormalindex: Byte;
  end;
  dtrivertx_at = array[0..0] of dtrivertx_t;
  dtrivertx_a = ^dtrivertx_at;

const
  DTRIVERTX_V0 = 0;
  DTRIVERTX_V1 = 1;
  DTRIVERTX_V2 = 2;
  DTRIVERTX_LNI = 3;
  DTRIVERTX_SIZE = 4;

type
  daliasframe_p = ^daliasframe_t;
  daliasframe_t = record
    scale: vec3_t;                      // multiply byte verts by this
    translate: vec3_t;                  // then add this
    name: array[0..15] of Char;         // frame name from grabbing
    verts: array[0..0] of dtrivertx_t;  // variable sized
  end;
  daliasframe_at = array[0..0] of daliasframe_t;
  daliasframe_a = ^daliasframe_at;

  // the glcmd format:
  // a positive integer starts a tristrip command, followed by that many
  // vertex structures.
  // a negative integer starts a trifan command, followed by -x vertexes
  // a zero indicates the end of the command list.
  // a vertex consists of a floating point s, a floating point t,
  // and an integer vertex index.

  dmdl_p = ^dmdl_t;
  dmdl_t = record
    ident: Integer;
    version: Integer;

    skinwidth: Integer;
    skinheight: Integer;
    framesize: Integer;                 // byte size of each frame

    num_skins: Integer;
    num_xyz: Integer;
    num_st: Integer;                    // greater than num_xyz for seams
    num_tris: Integer;
    num_glcmds: Integer;                // dwords in strip/fan command list
    num_frames: Integer;

    ofs_skins: Integer;                 // each skin is a MAX_SKINNAME string
    ofs_st: Integer;                    // byte offset from start for stverts
    ofs_tris: Integer;                  // offset for dtriangles
    ofs_frames: Integer;                // offset for first frame
    ofs_glcmds: Integer;
    ofs_end: Integer;                   // end of file
  end;
  dmdl_at = array[0..0] of dmdl_t;
  dmdl_a = ^dmdl_at;

  {
  ========================================================================

  .SP2 sprite file format

  ========================================================================
  }

const
  IDSPRITEHEADER = ((ord('2') shl 24) + (ord('S') shl 16) + (ord('D') shl 8) + ord('I'));
  // little-endian "IDS2"
  SPRITE_VERSION = 2;

type
  dsprframe_p = ^dsprframe_t;
  dsprframe_t = record
    width, height: Integer;
    origin_x, origin_y: Integer;        // raster coordinates inside pic
    name: array[0..MAX_SKINNAME - 1] of Char;
  end;
  dsprframe_at = array[0..0] of dsprframe_t;
  dsprframe_a = ^dsprframe_at;

  dsprite_p = ^dsprite_t;
  dsprite_t = record
    ident: Integer;
    version: Integer;
    numframes: Integer;
    frames: array[0..0] of dsprframe_t; // variable sized
  end;
  dsprite_at = array[0..0] of dsprite_t;
  dsprite_a = ^dsprite_at;

  {
  ==============================================================================

    .WAL texture file format

  ==============================================================================
  }

const
  MIPLEVELS = 4;

type
  miptex_p = ^miptex_t;
  miptex_s = record
    name: array[0..31] of Char;
    width, height: Cardinal;
    offsets: array[0..MIPLEVELS - 1] of Cardinal; // four mip maps stored
    animname: array[0..31] of Char;     // next frame in animation chain
    flags: Integer;
    contents: Integer;
    value: Integer;
  end;
  miptex_t = miptex_s;
  miptex_at = array[0..0] of miptex_t;
  miptex_a = ^miptex_at;

  {
  ==============================================================================

    .BSP file format

  ==============================================================================
  }

const
  IDBSPHEADER = ((ord('P') shl 24) + (ord('S') shl 16) + (ord('B') shl 8) + ord('I'));
  // little-endian "IBSP"
  BSPVERSION = 38;

  // upper design bounds
  // leaffaces, leafbrushes, planes, and verts are still bounded by
  // 16 bit short limits

  MAX_MAP_MODELS = 1024;
  MAX_MAP_BRUSHES = 8192;
  MAX_MAP_ENTITIES = 2048;
  MAX_MAP_ENTSTRING = $40000;
  MAX_MAP_TEXINFO = 8192;

  MAX_MAP_AREAS = 256;
  MAX_MAP_AREAPORTALS = 1024;
  MAX_MAP_PLANES = 65536;
  MAX_MAP_NODES = 65536;
  MAX_MAP_BRUSHSIDES = 65536;
  MAX_MAP_LEAFS = 65536;
  MAX_MAP_VERTS = 65536;
  MAX_MAP_FACES = 65536;
  MAX_MAP_LEAFFACES = 65536;
  MAX_MAP_LEAFBRUSHES = 65536;
  MAX_MAP_PORTALS = 65536;
  MAX_MAP_EDGES = 128000;
  MAX_MAP_SURFEDGES = 256000;
  MAX_MAP_LIGHTING = $200000;
  MAX_MAP_VISIBILITY = $100000;

  // key / value pair sizes

  MAX_KEY = 32;
  MAX_VALUE = 1024;

  //=============================================================================

type
  lump_p = ^lump_t;
  lump_t = record
    fileofs, filelen: Integer;
  end;
  lump_at = array[0..0] of lump_t;
  lump_a = ^lump_at;

const
  LUMP_ENTITIES = 0;
  LUMP_PLANES = 1;
  LUMP_VERTEXES = 2;
  LUMP_VISIBILITY = 3;
  LUMP_NODES = 4;
  LUMP_TEXINFO = 5;
  LUMP_FACES = 6;
  LUMP_LIGHTING = 7;
  LUMP_LEAFS = 8;
  LUMP_LEAFFACES = 9;
  LUMP_LEAFBRUSHES = 10;
  LUMP_EDGES = 11;
  LUMP_SURFEDGES = 12;
  LUMP_MODELS = 13;
  LUMP_BRUSHES = 14;
  LUMP_BRUSHSIDES = 15;
  LUMP_POP = 16;
  LUMP_AREAS = 17;
  LUMP_AREAPORTALS = 18;
  HEADER_LUMPS = 19;

type
  dheader_p = ^dheader_t;
  dheader_t = record
    ident: Integer;
    version: Integer;
    lumps: array[0..HEADER_LUMPS - 1] of lump_t;
  end;
  dheader_at = array[0..0] of dheader_t;
  dheader_a = ^dheader_at;

  dmodel_p = ^dmodel_t;
  dmodel_t = record
    mins, maxs: vec3_t;
    origin: vec3_t;                     // for sounds or lights
    headnode: Integer;
    firstface, numfaces: Integer;       // submodels just draw faces
    // without walking the bsp tree
  end;
  dmodel_at = array[0..0] of dmodel_t;
  dmodel_a = ^dmodel_at;

  dvertex_p = ^dvertex_t;
  dvertex_t = record
    point: vec3_t;
  end;
  dvertex_at = array[0..0] of dvertex_t;
  dvertex_a = ^dvertex_at;

const
  // 0-2 are axial planes
  PLANE_X = 0;
  PLANE_Y = 1;
  PLANE_Z = 2;

  // 3-5 are non-axial planes snapped to the nearest
  PLANE_ANYX = 3;
  PLANE_ANYY = 4;
  PLANE_ANYZ = 5;

  // planes (x&~1) and (x&~1)+1 are always opposites

type
  dplane_p = ^dplane_t;
  dplane_t = record
    normal: vec3_t;
    dist: Single;
    _type: Integer;                     // PLANE_X - PLANE_ANYZ ?remove? trivial to regenerate
  end;
  dplane_at = array[0..0] of dplane_t;
  dplane_a = ^dplane_at;

const
  // contents flags are seperate bits
  // a given brush can contribute multiple content bits
  // multiple brushes can be in a single leaf

  // these definitions also need to be in q_shared.h!

  // lower bits are stronger, and will eat weaker brushes completely
  CONTENTS_SOLID = 1;                   // an eye is never valid in a solid
  CONTENTS_WINDOW = 2;                  // translucent, but not watery
  CONTENTS_AUX = 4;
  CONTENTS_LAVA = 8;
  CONTENTS_SLIME = 16;
  CONTENTS_WATER = 32;
  CONTENTS_MIST = 64;
  LAST_VISIBLE_CONTENTS = 64;

  // remaining contents are non-visible, and don't eat brushes

  CONTENTS_AREAPORTAL = $8000;

  CONTENTS_PLAYERCLIP = $10000;
  CONTENTS_MONSTERCLIP = $20000;

  // currents can be added to any other contents, and may be mixed
  CONTENTS_CURRENT_0 = $40000;
  CONTENTS_CURRENT_90 = $80000;
  CONTENTS_CURRENT_180 = $100000;
  CONTENTS_CURRENT_270 = $200000;
  CONTENTS_CURRENT_UP = $400000;
  CONTENTS_CURRENT_DOWN = $800000;

  CONTENTS_ORIGIN = $1000000;           // removed before bsping an entity

  CONTENTS_MONSTER = $2000000;          // should never be on a brush, only in game
  CONTENTS_DEADMONSTER = $4000000;
  CONTENTS_DETAIL = $8000000;           // brushes to be added after vis leafs
  CONTENTS_TRANSLUCENT = $10000000;     // auto set if any surface has trans
  CONTENTS_LADDER = $20000000;

  SURF_LIGHT = $1;                      // value will hold the light strength

  SURF_SLICK = $2;                      // effects game physics

  SURF_SKY = $4;                        // don't draw, but add to skybox
  SURF_WARP = $8;                       // turbulent water warp
  SURF_TRANS33 = $10;
  SURF_TRANS66 = $20;
  SURF_FLOWING = $40;                   // scroll towards angle
  SURF_NODRAW = $80;                    // don't bother referencing the texture

type
  dnode_p = ^dnode_t;
  dnode_t = record
    planenum: Integer;
    children: array[0..1] of Integer;   // negative numbers are -(leafs+1), not nodes
    mins: array[0..2] of Smallint;      // for frustom culling
    maxs: array[0..2] of Smallint;
    firstface: Word;
    numfaces: Word;                     // counting both sides
  end;
  dnode_at = array[0..0] of dnode_t;
  dnode_a = ^dnode_at;

  texinfo_p = ^texinfo_t;
  texinfo_s = record
    vecs: array[0..1, 0..3] of Single;  // [s/t][xyz offset]
    flags: Integer;                     // miptex flags + overrides
    value: Integer;                     // light emission, etc
    texture: array[0..31] of Char;      // texture name (textures/*.wal)
    nexttexinfo: Integer;               // for animations, -1 = end of chain
  end;
  texinfo_t = texinfo_s;
  texinfo_at = array[0..0] of texinfo_t;
  texinfo_a = ^texinfo_at;

  // note that edge 0 is never used, because negative edge nums are used for
  // counterclockwise use of the edge in a face

  dedge_p = ^dedge_t;
  dedge_t = record
    v: array[0..1] of Word;             // vertex numbers
  end;
  dedge_at = array[0..0] of dedge_t;
  dedge_a = ^dedge_at;

const
  MAXLIGHTMAPS = 4;

type
  dface_p = ^dface_t;
  dface_t = record
    planenum: Word;
    side: Smallint;

    firstedge: Integer;                 // we must support > 64k edges
    numedges: Smallint;
    texinfo: Smallint;

    // lighting info
    styles: array[0..MAXLIGHTMAPS - 1] of Byte;
    lightofs: Integer;                  // start of [numstyles*surfsize] samples
  end;
  dface_at = array[0..0] of dface_t;
  dface_a = ^dface_at;

  dleaf_p = ^dleaf_t;
  dleaf_t = record
    contents: Integer;                  // OR of all brushes (not needed?)

    cluster: Smallint;
    area: Smallint;

    mins: array[0..2] of Smallint;      // for frustum culling
    maxs: array[0..2] of Smallint;

    firstleafface: Word;
    numleaffaces: Word;

    firstleafbrush: Word;
    numleafbrushes: Word;
  end;
  dleaf_at = array[0..0] of dleaf_t;
  dleaf_a = ^dleaf_at;

  dbrushside_p = ^dbrushside_t;
  dbrushside_t = record
    planenum: Word;                     // facing out of the leaf
    texinfo: Smallint;
  end;
  dbrushside_at = array[0..0] of dbrushside_t;
  dbrushside_a = ^dbrushside_at;

  dbrush_p = ^dbrush_t;
  dbrush_t = record
    firstside: Integer;
    numsides: Integer;
    contents: Integer;
  end;
  dbrush_at = array[0..0] of dbrush_t;
//  dbrush_a = ^dbrush_a;

const
  ANGLE_UP = -1;
  ANGLE_DOWN = -2;

  // the visibility lump consists of a header with a count, then
  // byte offsets for the PVS and PHS of each cluster, then the raw
  // compressed bit vectors
  DVIS_PVS = 0;
  DVIS_PHS = 1;

type
  dvis_p = ^dvis_t;
  dvis_t = record
    numclusters: Integer;
    bitofs: array[0..7, 0..1] of Integer; // bitofs[numclusters][2]
  end;
  dvis_at = array[0..0] of dvis_t;
  dvis_a = ^dvis_at;

  // each area has a list of portals that lead into other areas
  // when portals are closed, other areas may not be visible or
  // hearable even if the vis info says that it should be
  dareaportal_p = ^dareaportal_t;
  dareaportal_t = record
    portalnum: Integer;
    otherarea: Integer;
  end;
  dareaportal_at = array[0..0] of dareaportal_t;
  dareaportal_a = ^dareaportal_at;

  darea_p = ^darea_t;
  darea_t = record
    numareaportals: Integer;
    firstareaportal: Integer;
  end;
  darea_at = array[0..0] of darea_t;
  darea_a = ^darea_at;

implementation

end.
