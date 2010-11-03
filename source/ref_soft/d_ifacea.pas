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
{ File(s): d_ifacea.h                                                        }
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

unit d_ifacea;

// !!! note that this file must match the corresponding C structures in
// d_iface.h at all times !!!
//

interface

const
// !!! if this is changed, it must be changed in d_iface.h too !!!
  TURB_TEX_SIZE = 64; // base turbulent texture size

// !!! if this is changed, it must be changed in d_iface.h too !!!
  CYCLE = 128;

// !!! if this is changed, it must be changed in r_shared.h too !!!
  MAXHEIGHT = 1200;

// !!! if this is changed, it must be changed in qcommon.h too !!!
  CACHE_SIZE = 32; // used to align key data structures

// particle_t structure
// !!! if this is changed, it must be changed in d_iface.h too !!!
// driver-usable fields
  pt_org = 0;
  pt_color = 12;
// drivers never touch the following fields
  pt_next = 16;
  pt_vel = 20;
  pt_ramp = 32;
  pt_die = 36;
  pt_type = 40;
  pt_size = 44;

  PARTICLE_Z_CLIP = 8.0;

// finalvert_t structure
// !!! if this is changed, it must be changed in d_iface.h too !!!
  fv_v = 0; // !!! if this is moved, cases where the !!!
         // !!! address of this field is pushed in !!!
         // !!! d_polysa.s must be changed !!!
  fv_flags = 24;
  fv_reserved = 28;
  fv_size = 32;
  fv_shift = 5;

// stvert_t structure
// !!! if this is changed, it must be changed in modelgen.h too !!!
  stv_onseam = 0;
  stv_s = 4;
  stv_t = 8;
  stv_size = 12;

// trivertx_t structure
// !!! if this is changed, it must be changed in modelgen.h too !!!
  tv_v = 0;
  tv_lightnormalindex = 3;
  tv_size = 4;

// affinetridesc_t structure
// !!! if this is changed, it must be changed in d_iface.h too !!!
  atd_pskin = 0;
  atd_pskindesc = 4;
  atd_skinwidth = 8;
  atd_skinheight = 12;
  atd_ptriangles = 16;
  atd_pfinalverts = 20;
  atd_numtriangles = 24;
  atd_drawtype = 28;
  atd_seamfixupX16 = 32;
  atd_size = 36;

implementation

end.
