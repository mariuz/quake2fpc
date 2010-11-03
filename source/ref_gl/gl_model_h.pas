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
{ File(s): gl_model.h                                                        }
{                                                                            }
{ Initial conversion by : osamaao                                            }
{ Initial conversion on : 14-Jan-2002                                        }
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
{ Updated on : 27/07/2002                                                    }
{ Updated by : Fabrizio Rossini  rossini.f@libero.it                         }
{ Added USES clause ,fixed some var declaration from Double to Single        }
{ Copied from GL_Local.pas the Image_s RECORD declaration to avoid circular  }
{ use of unit in delphi                                                      }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{ Q_Shared , QFiles                                                          }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{ none                                                                       }
{----------------------------------------------------------------------------}


(*/*

d*_t structures are on-disk representations
m*_t structures are in-memory

*/*)


{==============================================================================

BRUSH MODELS

==============================================================================}




unit gl_model_h;

interface

uses
  gl_local_add,
  q_shared,
  QFiles;

const
  SIDE_FRONT          = 0;
  SIDE_BACK           = 1;
  SIDE_ON             = 2;

  SURF_PLANEBACK      =   2;
  SURF_DRAWSKY         =   4;
  SURF_DRAWTURB         =   $10;
  SURF_DRAWBACKGROUND =   $40;
  SURF_UNDERWATER     =   $80;

  VERTEXSIZE          = 7;


type


//
// in memory representation
//
// !!! if this is changed, it must be changed in asm_draw.h too !!!


  mVertex_p = ^mVertex_t;
  mVertex_t = record
    Position :vec3_t;
  end;
  mVertex_arr = array[0..0] of mVertex_t;
  mVertex_arrp = ^mVertex_arr;

  mModel_p = ^mModel_t;
  mModel_t = record
    Mins     : Vec3_t;
    Maxs     : Vec3_t;
    Origin   : Vec3_t;              // for sounds or lights
    Radius   : Single ;
    HeadNode : Integer;
    VisLeafs : Integer;             // not including the solid leaf 0
    FirstFace: Integer;
    NumFaces : Integer;
  end;
  mModel_arr = array[0..0] of mModel_t;
  mModel_arrp = ^mModel_arr;

// !!! if this is changed, it must be changed in asm_draw.h too !!!
  mEdge_p = ^mEdge_t;
  mEdge_t = record
    V               : array[0..1] of Word;
    CachedEdgeOffset: Cardinal;
  end;
  mEdge_arr = array[0..0] of mEdge_t;
  mEdge_arrp = ^mEdge_arr;


  mTexInfo_p = ^mtexInfo_t;
  mTexInfo_t = record
    Vecs     : array[0..1, 0..3] of Single;
    Flags    : Integer;
    NumFrames: Integer;
    Next     : mTexInfo_p;         // animation chain
    Image    : Image_p;
  end;
  mTexInfo_arr = array[0..0] of mTexInfo_t;
  mTexInfo_arrp = ^mTexInfo_arr;


  glPoly_p = ^glPoly_t;
  glPoly_t = record
    Next    : glPoly_p;
    Chain   : glPoly_p;
    NumVerts: Integer;
    Flags   : Integer;         // for SURF_UNDERWATER (not needed anymore?)
    Verts   : array[0..3, 0..VERTEXSIZE - 1] of Single;   // variable sized (xyz s1t1 s2t2)
  end;



  mSurface_p = ^mSurface_t;
  mSurface_pp = ^mSurface_p;
  mSurface_t = record
    visFrame          : Integer;         // should be drawn when node is crossed
    Plane             : cPlane_p;
    Flags             : Integer;
    FirstEdge         : Integer;         // look up in model->surfedges[], negative numbers
    NumEdges          : Integer;         // are backwards edges
    TextureMins       : array[0..1] of SmallInt;
    Extents           : array[0..1] of   SmallInt;
    Light_s           : Integer;
    Light_t           : Integer;   // gl lightmap coordinates
    dLight_s          : Integer;
    dLight_t          : Integer;        // gl lightmap coordinates for dynamic lightmaps
    Polys             : glPoly_p;   // multiple if warped
    TextureChain      : mSurface_p;
    LightMapChain     : mSurface_p;
    TexInfo           : mtexinfo_p;
    // lighting info
    dLightFrame       : Integer;
    dLightBits        : Integer;
    LightMapTextureNum: Integer;

    Styles      : array [0..MAXLIGHTMAPS - 1] of Byte;
    Cached_Light: array [0..MAXLIGHTMAPS - 1] of Single;   // values currently used in lightmap
    Samples     : PByte;      // [numstyles*surfsize]
  end;
  mSurface_arr = array[0..0] of mSurface_t;
  mSurface_arrp = ^mSurface_arr;


  mNode_p = ^mNode_t;
  mNode_t = record
    // common with leaf
    Contents    : Integer;              // -1, to differentiate from leafs
    visFrame    : Integer;              // node needs to be traversed if current
    MinMaxs     : array[0..5] of Single;   // for bounding box culling
    Parent      : mNode_p;
    // node specific
    Plane       : cPlane_p;
    Children    : array[0..1] of mNode_p;
    FirstSurface: Word;
    NumSurfaces : Word;
  end;
  mNode_arr = array[0..0] of mNode_t;
  mNode_arrp = ^mNode_arr;



  mLeaf_p = ^mLeaf_t;
  mLeaf_t = record
    // common with node
    Contents        : Integer;              // wil be a negative contents number
    visFrame        : Integer;              // node needs to be traversed if current
    MinMaxs         : array[0..5] of Single;   // for bounding box culling
    Parent          : mNode_p;
    // leaf specific
    Cluster         : Integer;
    Area            : Integer;
    FirstMarkSurface: mSurface_pp;
    NumMarkSurfaces : Integer;
  end;
  mLeaf_arr = array[0..0] of mLeaf_t;
  mLeaf_arrp = ^mLeaf_arr;

//
// Whole model
//

  modType_t = (mod_bad, mod_brush, mod_sprite, mod_alias);


  Model_p = ^Model_t;
  Model_t = record
    Name                 : array [0..MAX_QPATH-1] of char;
    Registration_Sequence: Integer;
    _Type                : modType_t;
    NumFrames            : Integer;
    Flags                : Integer;
    //
    // volume occupied by the model graphics
    //
    Mins, Maxs           : Vec3_t;
    Radius               :Single;
    //
    // solid volume for clipping
    //
    ClipBox              :qBoolean;
    ClipMins, ClipMaxs   : Vec3_t;
    //
    // brush model
    //
    FirstModelSurface    : Integer;
    NumModelSurfaces     : Integer;
    LightMap             : Integer;      // only for submodels

    NumSubModels         : Integer;
    SubModels            : mmodel_p;

    NumPlanes            : Integer;
    Planes               : cPlane_p;

    NumLeafs             : Integer;      // number of visible leafs, not counting 0
    Leafs                : mLeaf_p;

    NumVertexes          : Integer;
    vertexes             : mVertex_arrp;

    NumEdges             : Integer;
    Edges                : medge_arrp;

    NumNodes             : Integer;
    FirstNode            : Integer;
    Nodes                : mNode_p;

    NumTexInfo           : Integer;
    TexInfo              : mTexInfo_p;

    NumSurfaces          : Integer;
    Surfaces             : mSurface_arrp;

    NumSurfEdges         : Integer;
    SurfEdges            : PInteger;

    NumMarkSurfaces      : Integer;
    MarkSurfaces         : msurface_pp;

    vis                  : dvis_p;   // {FAB} declared in QFiles
    LightData            : PByte;

    // for alias models and skins
    Skins                : array[0..MAX_MD2SKINS - 1] of Image_p;
    ExtraDataSize        : Integer;
    ExtraData            : Pointer;
  end;


//============================================================================

implementation

end.
