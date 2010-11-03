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
{ File(s): asm_draw.h                                                        }
{                                                                            }
{ Initial conversion by : Massimo Soricetti (max-67@libero.it)               }
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
{ Updated on :                                                               }
{ Updated by :                                                               }
{                                                                            }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{ ?                                                                          }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{ ?                                                                          }
{----------------------------------------------------------------------------}

unit asm_draw;

interface

// !!! note that this file must match the corresponding C structures at all
// times !!!

// !!! if this is changed, it must be changed in r_local.h too !!!
const

  NEAR_CLIP = 0.01;

// !!! if this is changed, it must be changed in r_local.h too !!!
  CYCLE = 128;

// espan_t structure
// !!! if this is changed, it must be changed in r_shared.h too !!!
  espan_t_u = 0;
  espan_t_v = 4;
  espan_t_count = 8;
  espan_t_pnext = 12;
  espan_t_size = 16;

// sspan_t structure
// !!! if this is changed, it must be changed in d_local.h too !!!
  span_t_u = 0;
  sspan_t_v = 4;
  sspan_t_count = 8;
  sspan_t_pnext = 12;
  sspan_t_size = 16;

// edge_t structure
// !!! if this is changed, it must be changed in r_shared.h too !!!
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
  cp_normal = 0;
  cp_dist = 12;
  cp_next = 16;
  cp_leftedge = 20;
  cp_rightedge = 21;
  cp_reserved = 22;
  cp_size = 24;

// medge_t structure
// !!! if this is changed, it must be changed in model.h too !!!
  me_v = 0;
  me_cachededgeoffset = 4;
  me_size = 8;

// mvertex_t structure
// !!! if this is changed, it must be changed in model.h too !!!
  mv_position = 0;
  mv_size = 12;

// refdef_t structure
// !!! if this is changed, it must be changed in render.h too !!!
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
  mtri_facesfront = 0;
  mtri_vertindex = 4;
  mtri_size = 16; // !!! if this changes, array indexing in !!!
         // !!! d_polysa.s must be changed to match !!!
  mtri_shift = 4;

implementation

end.
