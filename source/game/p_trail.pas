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
{ File(s): g_local.h (part), p_trail.c                                       }
{ Content: Quake2\Game\ list of recent player positions                      }
{                                                                            }
{ Initial conversion by : Clootie (Alexey Barkovoy) - clootie@reactor.ru     }
{ Initial conversion on : 13-Jan-2002                                        }
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
{ 1) 22-Jan-2002 - Clootie (clootie@reactor.ru)                              }
{    Updated, now unit uses existing code in Q_Shared.pas instead of stubs.  }
{ 2) 25-Feb-2002 - Clootie (clootie@reactor.ru)                              }
{    Cleaned up most external dependencies - only g_ai.pas - "visible" lasts.}
{                                                                            }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{ 1) g_ai                                                                    }
{                                                                            }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{ 1) Clootie: Resolve other unit dependencies                                }
{                                                                            }
{----------------------------------------------------------------------------}

unit p_trail;

interface

uses
  Q_shared, g_local;

// From g_local.h, line 737
//
// g_ptrail.c
//
procedure PlayerTrail_Init;
procedure PlayerTrail_Add(const spot: vec3_t);
procedure PlayerTrail_New(const spot: vec3_t);
function PlayerTrail_PickFirst(const self: edict_t): edict_p;
function PlayerTrail_PickNext(const self: edict_t): edict_p;
function PlayerTrail_LastSpot: edict_p;

implementation

uses
  g_main,
  g_utils,
  g_ai;



(*
==============================================================================

PLAYER TRAIL

==============================================================================

This is a circular list containing the a list of points of where
the player has been recently.  It is used by monsters for pursuit.

.origin      the spot
.owner      forward link
.aiment      backward link
*)

const
  TRAIL_LENGTH  = 8;

var
  trail:        array[0..TRAIL_LENGTH-1] of edict_p;
  trail_head:   Integer;
  trail_active: qboolean = False;

  
//#define NEXT(n)      (((n) + 1) & (TRAIL_LENGTH - 1))
function NEXT(n: Integer): Integer;
begin
  Result:= (n + 1) and (TRAIL_LENGTH - 1);
end;

//#define PREV(n)      (((n) - 1) & (TRAIL_LENGTH - 1))
function PREV(n: Integer): Integer;
begin
  Result:= (n - 1) and (TRAIL_LENGTH - 1);
end;


procedure PlayerTrail_Init;
var
  n: Integer;
begin
  if (deathmatch.value (* FIXME || coop *) <> 0) then Exit;

  for n := 0 to TRAIL_LENGTH - 1 do
  begin
    trail[n] := G_Spawn;
    trail[n].classname := 'player_trail';
  end;

  trail_head := 0;
  trail_active := True;
end;


procedure PlayerTrail_Add(const spot: vec3_t);
var
  temp: vec3_t;
begin
  if not trail_active then Exit;

  VectorCopy(spot, trail[trail_head].s.origin);

  trail[trail_head].timestamp := level.time;

  VectorSubtract(spot, trail[PREV(trail_head)].s.origin, temp);
  trail[trail_head].s.angles[1] := vectoyaw(temp);

  trail_head := NEXT(trail_head);
end;


procedure PlayerTrail_New(const spot: vec3_t);
begin
  if (not trail_active) then Exit;

  PlayerTrail_Init;
  PlayerTrail_Add(spot);
end;


function PlayerTrail_PickFirst(const self: edict_t): edict_p;
var
  marker: Integer;
  n: Integer;
begin
  Result:= nil;
  if (not trail_active) then Exit;

  // for (marker = trail_head, n = TRAIL_LENGTH; n; n--)
  marker := trail_head;
  for n:= TRAIL_LENGTH downto 1 do
  begin
    if (trail[marker].timestamp <= self.monsterinfo.trail_time) then
      marker := NEXT(marker)
    else
      Break;
  end;

  if visible(@self, trail[marker]) then
  begin
    Result:= trail[marker];
    Exit;
  end;

  if visible(@self, trail[PREV(marker)]) then
  begin
    Result:= trail[PREV(marker)];
    Exit;
  end;

  Result:= trail[marker];
end;


function PlayerTrail_PickNext(const self: edict_t): edict_p;
var
  marker: Integer;
  n: Integer;
begin
  Result:= nil;
  if not trail_active then Exit;

  // for (marker = trail_head, n = TRAIL_LENGTH; n; n--)
  marker := trail_head;
  for n:= TRAIL_LENGTH downto 1 do
  begin
    if (trail[marker].timestamp <= self.monsterinfo.trail_time) then
      marker := NEXT(marker)
    else
      Break;
  end;

  Result:= trail[marker];
end;


function PlayerTrail_LastSpot: edict_p;
begin
  Result:= trail[PREV(trail_head)];
end;

end.

