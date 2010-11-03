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
{ File(s): sound.h                                                           }
{ Content: Quake2\ref_soft\ sound structures and constants                   }
{                                                                            }
{ Initial conversion by : George Melekos (inet_crow@hotmail.com)             }
{ Initial conversion on : 20-Feb-2002                                        }
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
{ Updated on : 03-jun-2002                                                   }
{ Updated by : Juha Hartikainen (juha@linearteam.org)                        }
{ - Commented out the procedures, they are not here.                         }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{ 1. Some test of couple functions in this unit                              }
{----------------------------------------------------------------------------}

unit Sound_h;

interface

{
 struct sfx_s;
}

type
  sfx_s = record
  end;
  psfx_s = ^sfx_s;

  (*
  procedure S_Init;

  procedure S_Shutdown;
  // if origin is NULL, the sound will be dynamically sourced from the entity

  procedure S_StartSound (origin :vec3_t; entnum : Integer; entchannel : Integer;
                          var sfx :sfx_s; fvol : Single; attenuation : Single; timeofs : Single);

  procedure S_StartLocalSound (s : PChar);

  procedure S_RawSamples (samples : Integer; rate : Integer; width : Integer; channels : Integer; var data : byte);

  procedure S_StopAllSounds;

  procedure S_Update (origin : vec3_t; v_forward : vec3_t; v_right : vec3_t; v_up : vec3_t);

  procedure S_Activate (active : qboolean);

  procedure S_BeginRegistration;

  function S_RegisterSound (sample : PChar) : psfx_s;

  procedure S_EndRegistration;

  function S_FindName (name : PChar; create : qboolean) : ^sfx_s;

  // the sound code makes callbacks to the client for entitiy position
  // information, so entities can be dynamically re-spatialized

  procedure CL_GetEntitySoundOrigin (ent : Integer; org : vec3_t);
  *)

implementation

end.
