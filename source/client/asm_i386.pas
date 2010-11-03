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
{ File(s): asm_i386.h                                                        }
{                                                                            }
{ Initial conversion by : Jan Horn (jhorn@global.co.za)                      }
{ Initial conversion on : 12-Jan-2002                                        }
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
{ none                                                                       }
{----------------------------------------------------------------------------}

unit asm_i386;

interface

// plane_t structure
// !!! if this is changed, it must be changed in model.h too !!!
// !!! if the size of this is changed, the array lookup in SV_HullPointContents
//     must be changed too !!!
const pl_normal     =  0;
const pl_dist     = 12;
const pl_type     = 16;
const pl_signbits = 17;
const pl_pad     = 18;
const pl_size     = 20;

// hull_t structure
// !!! if this is changed, it must be changed in model.h too !!!
const hu_clipnodes     = 0;
const hu_planes          = 4;
const hu_firstclipnode = 8;
const hu_lastclipnode  = 12;
const hu_clip_mins     = 16;
const hu_clip_maxs     = 28;
const hu_size            = 40;

// dnode_t structure
// !!! if this is changed, it must be changed in bspfile.h too !!!
const nd_planenum  = 0;
const nd_children  = 4;
const nd_mins      = 8;
const nd_maxs      = 20;
const nd_firstface = 32;
const nd_numfaces  = 36;
const nd_size      = 40;

// sfxcache_t structure
// !!! if this is changed, it much be changed in sound.h too !!!
const sfxc_length    = 0;
const sfxc_loopstart = 4;
const sfxc_speed     = 8;
const sfxc_width     = 12;
const sfxc_stereo    = 16;
const sfxc_data        = 20;

// channel_t structure
// !!! if this is changed, it much be changed in sound.h too !!!
const ch_sfx       = 0;
const ch_leftvol    = 4;
const ch_rightvol   = 8;
const ch_end       = 12;
const ch_pos       = 16;
const ch_looping    = 20;
const ch_entnum       = 24;
const ch_entchannel = 28;
const ch_origin       = 32;
const ch_dist_mult  = 44;
const ch_master_vol = 48;
const ch_size       = 52;

// portable_samplepair_t structure
// !!! if this is changed, it much be changed in sound.h too !!!
const psp_left   = 0;
const psp_right   = 4;
const psp_size   = 8;

// !!! must be kept the same as in d_iface.h !!!
const TRANSPARENT_COLOR   = 255;

implementation

end.

