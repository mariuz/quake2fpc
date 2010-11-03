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
{ File(s): qasm.inc                                                          }
{                                                                            }
{ Initial conversion by : Carl Kenner (carl_kenner@hotmail.com)              }
{ Initial conversion on : 15-Feb-2002                                        }
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
{ Nothing                                                                    }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{ Nothing - except work out what to do with id386                            }
{----------------------------------------------------------------------------}
unit qasm_inc;

interface
//
// qasm.inc
//
// Include file for asm routines.
//

//
// !!! note that this file must match the corresponding C structures at all
// times !!!
//

// !!! must be kept the same as in d_iface.h !!!
const
  TRANSPARENT_COLOR = 255;

// plane_t structure
// !!! if this is changed, it must be changed in model.h too !!!
// !!! if the size of this is changed, the array lookup in SV_HullPointContents
//     must be changed too !!!
const
  pl_normal = 0;
  pl_dist = 12;
  pl_type = 16;
  pl_signbits = 17;
  pl_pad = 18;
  pl_size = 20;

// hull_t structure
// !!! if this is changed, it must be changed in model.h too !!!
const
  hu_clipnodes = 0;
  hu_planes = 4;
  hu_firstclipnode = 8;
  hu_lastclipnode = 12;
  hu_clip_mins = 16;
  hu_clip_maxs = 28;
  hu_size = 40;

// dnode_t structure
// !!! if this is changed, it must be changed in bspfile.h too !!!
const
  nd_planenum = 0;
  nd_children = 4;
  nd_mins = 8;
  nd_maxs = 20;
  nd_firstface = 32;
  nd_numfaces = 36;
  nd_size = 40;

// sfxcache_t structure
// !!! if this is changed, it much be changed in sound.h too !!!
const
  sfxc_length = 0;
  sfxc_loopstart = 4;
  sfxc_speed = 8;
  sfxc_width = 12;
  sfxc_stereo = 16;
  sfxc_data = 20;

// channel_t structure
// !!! if this is changed, it much be changed in sound.h too !!!
const
  ch_sfx = 0;
  ch_leftvol = 4;
  ch_rightvol = 8;
  ch_end = 12;
  ch_pos = 16;
  ch_looping = 20;
  ch_entnum = 24;
  ch_entchannel = 28;
  ch_origin = 32;
  ch_dist_mult = 44;
  ch_master_vol = 48;
  ch_size = 52;

// portable_samplepair_t structure
// !!! if this is changed, it much be changed in sound.h too !!!
const
  psp_left = 0;
  psp_right = 4;
  psp_size = 8;

// !!! if this is changed, it must be changed in r_local.h too !!!
const
  NEAR_CLIP = 0.01;

// !!! if this is changed, it must be changed in r_local.h too !!!
const
  CYCLE = 128;

// espan_t structure
// !!! if this is changed, it must be changed in r_shared.h too !!!
const
  espan_t_u = 0;
  espan_t_v = 4;
  espan_t_count = 8;
  espan_t_pnext = 12;
  espan_t_size = 16;

// sspan_t structure
// !!! if this is changed, it must be changed in d_local.h too !!!
const
  sspan_t_u = 0;
  sspan_t_v = 4;
  sspan_t_count = 8;
  sspan_t_size = 12;

// spanpackage_t structure
// !!! if this is changed, it must be changed in d_polyset.c too !!!
const
  spanpackage_t_pdest = 0;
  spanpackage_t_pz = 4;
  spanpackage_t_count = 8;
  spanpackage_t_ptex = 12;
  spanpackage_t_sfrac = 16;
  spanpackage_t_tfrac = 20;
  spanpackage_t_light = 24;
  spanpackage_t_zi = 28;
  spanpackage_t_size = 32;

// edge_t structure
// !!! if this is changed, it must be changed in r_shared.h too !!!
const
  et_u = 0;
  et_u_step = 4;
  et_prev = 8;
  et_next = 12;
  et_surfs = 16;
  et_nextremove = 20;
  et_nearzi = 24;
  et_owner = 28;
  et_size = 32;

// surf_t structure
// !!! if this is changed, it must be changed in r_shared.h too !!!
const
  SURF_T_SHIFT = 6;
  st_next = 0;
  st_prev = 4;
  st_spans = 8;
  st_key = 12;
  st_last_u = 16;
  st_spanstate = 20;
  st_flags = 24;
  st_data = 28;
  st_entity = 32;
  st_nearzi = 36;
  st_insubmodel = 40;
  st_d_ziorigin = 44;
  st_d_zistepu = 48;
  st_d_zistepv = 52;
  st_pad = 56;
  st_size = 64;

// clipplane_t structure
// !!! if this is changed, it must be changed in r_local.h too !!!
const
  cp_normal = 0;
  cp_dist = 12;
  cp_next = 16;
  cp_leftedge = 20;
  cp_rightedge = 21;
  cp_reserved = 22;
  cp_size = 24;

// medge_t structure
// !!! if this is changed, it must be changed in model.h too !!!
const
  me_v = 0;
  me_cachededgeoffset = 4;
  me_size = 8;

// mvertex_t structure
// !!! if this is changed, it must be changed in model.h too !!!
const
  mv_position = 0;
  mv_size = 12;

// refdef_t structure
// !!! if this is changed, it must be changed in render.h too !!!
const
  rd_vrect = 0;
  rd_aliasvrect = 20;
  rd_vrectright = 40;
  rd_vrectbottom = 44;
  rd_aliasvrectright = 48;
  rd_aliasvrectbottom = 52;
  rd_vrectrightedge = 56;
  rd_fvrectx = 60;
  rd_fvrecty = 64;
  rd_fvrectx_adj = 68;
  rd_fvrecty_adj = 72;
  rd_vrect_x_adj_shift20 = 76;
  rd_vrectright_adj_shift20 = 80;
  rd_fvrectright_adj = 84;
  rd_fvrectbottom_adj = 88;
  rd_fvrectright = 92;
  rd_fvrectbottom = 96;
  rd_horizontalFieldOfView = 100;
  rd_xOrigin = 104;
  rd_yOrigin = 108;
  rd_vieworg = 112;
  rd_viewangles = 124;
  rd_ambientlight = 136;
  rd_size = 140;

// mtriangle_t structure
// !!! if this is changed, it must be changed in model.h too !!!
const
  mtri_facesfront = 0;
  mtri_vertindex = 4;
  mtri_size = 16; // !!! if this changes, array indexing in !!!
                  // !!! d_polysa.s must be changed to match !!!
  mtri_shift = 4;

implementation

end.
