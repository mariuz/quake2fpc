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
{ File(s): game.h related                                                    }
{ Content: game dll information visible to server                            }
{                                                                            }
{ Initial created by: Juha                                                   }
{ Initial created on: 25-Nov-2002                                            }
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
{ Updated on:  2003-May-23                                                   }
{ Updated by:  Scott Price (scott.price@totalise.co.uk)                      }
{              Tidy-up and addition of header and completion percentile      }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{ none                                                                       }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{ none                                                                       }
{----------------------------------------------------------------------------}
{ * Note:                                                                    }
{ - Was required to move some of these from GameUnit due to the in-compatible}
{   structures in the game and main Quake2d.exe projects                     }
{----------------------------------------------------------------------------}
unit game_add;

interface

const
  MAX_ENT_CLUSTERS = 16;

type
  // edict->solid values
  solid_p = ^solid_t;
  solid_t = (
    SOLID_NOT,                          // no interaction with other objects
    SOLID_TRIGGER,                      // only touch when inside, after moving
    SOLID_BBOX,                         // touch on edge
    SOLID_BSP                           // bsp clip, touch on edge
    );

  // Juha: Taken from game.h
  // link_t is only used for entity area links now
  link_p = ^link_t;
  link_t = record
    prev, next: link_p;
  end;

implementation

end.
