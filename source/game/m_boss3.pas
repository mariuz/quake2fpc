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
{----------------------------------------------------------------------------}
{                                                                            }
{ File(s): m_boss3.c                                                         }
{                                                                            }
{ Initial conversion by : Ben Watt (ben@delphigamedev.com)                   }
{ Initial conversion on : 29-Jan-2002                                        }
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
{ Updated on :  2003-May-23                                                  }
{ Updated by :  Scott Price (scott.price@totalise.co.uk)                     }
{               Pointer dereferences and conversion error in Think_Boss3Stand}
{                                                                            }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{----------------------------------------------------------------------------}
{
==============================================================================

boss3

==============================================================================
}

unit m_boss3;

interface

uses g_local, m_boss32;

const MODEL_SCALE     = 1.000000;

procedure Use_Boss3(ent, other, activator : edict_p); cdecl;
procedure Think_Boss3Stand(ent : edict_p); cdecl;
procedure SP_monster_boss3_stand(self : edict_p); cdecl;

implementation

uses g_main, q_shared, q_shared_add, g_utils, g_local_add, game_add;

procedure Use_Boss3(ent, other, activator : edict_p);
begin
  gi.WriteByte(svc_temp_entity);
  gi.WriteByte(Ord(TE_BOSSTPORT));
  gi.WritePosition(ent^.s.origin);
  gi.multicast(@ent^.s.origin, MULTICAST_PVS);
  G_FreeEdict(ent);
end;

procedure Think_Boss3Stand(ent : edict_p);
begin
  if ent^.s.frame = FRAME_stand260 then
    ent^.s.frame := FRAME_stand201
  else
    ent^.s.frame   := ent^.s.frame + 1;
  ent^.nextthink := level.time + FRAMETIME;
end;

{QUAKED monster_boss3_stand (1 .5 0) (-32 -32 0) (32 32 90)

Just stands and cycles in one place until targeted, then teleports away.}
procedure SP_monster_boss3_stand(self : edict_p);
begin
  if (deathmatch^.Value <> 0) then
  begin
    G_FreeEdict(self);
    Exit;
  end;

  self^.movetype := MOVETYPE_STEP;
  self^.solid := SOLID_BBOX;
  self^.model := 'models/monsters/boss3/rider/tris.md2';
  self^.s.modelindex := gi.modelindex(self^.model);
  self^.s.frame := FRAME_stand201;

  gi.soundindex('misc/bigtele.wav');

  VectorSet(self^.mins, -32, -32, 0);
  VectorSet(self^.maxs,  32, 32, 90);

  self^.use := Use_Boss3;
  self^.think := Think_Boss3Stand;
  self^.nextthink := level.time + FRAMETIME;
  gi.linkentity(self);
end;

end.
