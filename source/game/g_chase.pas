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
{$ALIGN 8}{$MINENUMSIZE 4}
{----------------------------------------------------------------------------}
{                                                                            }
{ File(s): game\g_chase.c (not ctf\g_chase.c!!!!!)                           }
{ Content: local definitions for game module                                 }
{                                                                            }
{ Initial conversion by : you_known (you_known@163.com)                      }
{ Initial conversion on : 03-Feb-2002                                        }
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
{ Updated on : 24-Feb-2002                                                   }
{ Updated by : Carl A Kenner (carl_kenner@hotmail.com)                       }
{                                                                            }
{ Updated on : 2003-May-13                                                   }
{ Updated by : Scott Price (scott.price@totalise.co.uk)                      }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{ none!!!                                                                    }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{ nothing!!!                                                                 }
{ TEST:  Changed some calls to Round() to Trunc().  Might require a little   }
{        testing to ensure all still performs as expected, and some          }
{        formatting changes.                                                 }
{----------------------------------------------------------------------------}

unit g_chase;

interface

uses
  q_shared,
  q_shared_add,
  g_local,
  GameUnit;

procedure UpdateChaseCam(ent: edict_p);
procedure ChaseNext(ent: edict_p);
procedure ChasePrev(ent: edict_p);
procedure GetChaseTarget(ent: edict_p);

implementation

uses
  g_main;

procedure UpdateChaseCam(ent: edict_p);
var
  o, ownerv, goal: vec3_t;
  targ: edict_p;
  forwards, right: vec3_t;
  trace: trace_t;
  i: Integer;
  oldgoal: vec3_t;
  angles: vec3_t;
  old: edict_p;
begin
  // is our chase target gone?
  if (not ent^.client^.chase_target^.inuse)
  or (ent^.client^.chase_target^.client^.resp.spectator) then
  begin
    old := ent^.client^.chase_target;
    ChaseNext(ent);
    if ent^.client^.chase_target = old then
    begin
      ent^.client^.chase_target := Nil;
      ent^.client^.ps.pmove.pm_flags := ent^.client^.ps.pmove.pm_flags and (not PMF_NO_PREDICTION);
      exit;
    end;
  end;

  targ := ent^.client^.chase_target;

  VectorCopy(targ^.s.origin, ownerv);
  VectorCopy(ent^.s.origin, oldgoal);

  ownerv[2] := ownerv[2] + targ^.viewheight;

  VectorCopy(targ^.client^.v_angle, angles);
  if angles[PITCH] > 56 then
    angles[PITCH] := 56;
  AngleVectors(angles, @forwards, @right, Nil);
  VectorNormalize(forwards);
  VectorMA(ownerv, -30, forwards, o);

  if o[2] < targ^.s.origin[2] + 20 then
    o[2] := targ^.s.origin[2] + 20;

  // jump animation lifts
  if targ^.groundentity = Nil then
    o[2] := o[2] + 16;

  trace := gi.trace(@ownerv, @vec3_origin, @vec3_origin, @o, targ, MASK_SOLID);

  VectorCopy(trace.endpos, goal);

  VectorMA(goal, 2, forwards, goal);

  // pad for floors and ceilings
  VectorCopy(goal, o);
  o[2] := o[2] + 6;
  trace := gi.trace(@goal, @vec3_origin, @vec3_origin, @o, targ, MASK_SOLID);
  if trace.fraction < 1 then
  begin
    VectorCopy(trace.endpos, goal);
    goal[2] := goal[2] - 6;
  end;

  VectorCopy(goal, o);
  o[2] := o[2] - 6;
  trace := gi.trace(@goal, @vec3_origin, @vec3_origin, @o, targ, MASK_SOLID);
  if trace.fraction < 1 then
  begin
    VectorCopy(trace.endpos, goal);
    goal[2] := goal[2] + 6;
  end;

  if targ^.deadflag <> 0 then
    ent^.client^.ps.pmove.pm_type := PM_DEAD
  else
    ent^.client^.ps.pmove.pm_type := PM_FREEZE;

  VectorCopy(goal, ent^.s.origin);
  for i := 0 to 2 do
    ent^.client^.ps.pmove.delta_angles[i] := ANGLE2SHORT(targ^.client^.v_angle[i] - ent^.client^.resp.cmd_angles[i]);

  if targ^.deadflag <> 0 then
  begin
    ent^.client^.ps.viewangles[ROLL] := 40;
    ent^.client^.ps.viewangles[PITCH] := -15;
    ent^.client^.ps.viewangles[YAW] := targ^.client^.killer_yaw;
  end else
  begin
    VectorCopy(targ^.client^.v_angle, ent^.client^.ps.viewangles);
    VectorCopy(targ^.client^.v_angle, ent^.client^.v_angle);
  end;

  ent^.viewheight := 0;
  ent^.client^.ps.pmove.pm_flags := ent^.client^.ps.pmove.pm_flags or PMF_NO_PREDICTION;
  gi.linkentity(ent);
end;


procedure ChaseNext(ent: edict_p);
var
  i: Integer;
  e: edict_p;
begin
  if ent^.client^.chase_target = Nil then
    Exit;

  i := (LongInt(ent^.client^.chase_target) - LongInt(g_edicts)) div sizeof(edict_t);
  repeat
    inc(i);
    if i > maxclients^.value then
      i := 1;
    e := @g_edicts^[0];
    inc(e, i);
    if not e^.inuse then
      Continue;
    if not e^.client^.resp.spectator then
      Break;
  until e = ent^.client^.chase_target;

  ent^.client^.chase_target := e;
  ent^.client^.update_chase := true;
end;


procedure ChasePrev(ent: edict_p);
var
  i: Integer;
  e: edict_p;
begin
  if ent^.client^.chase_target = Nil then
    Exit;

  i := (LongInt(ent^.client^.chase_target) - LongInt(g_edicts)) div sizeof(edict_t);
  repeat
    dec(i);
    if i < 1 then
{      i := Round(maxclients^.value);  { 2003-05-13 - SP:  Should this be Trunc instead }
      i := Trunc(maxclients^.value);  { 2003-05-13 - SP:  Provided alternative }
    e := @g_edicts^[0];
    inc(e, i);
    if not e^.inuse then
      Continue;
    if not e^.client^.resp.spectator then
      Break;
  until e = ent^.client^.chase_target;

  ent^.client^.chase_target := e;
  ent^.client^.update_chase := true;
end;


procedure GetChaseTarget(ent: edict_p);
var
  i: Integer;
  other: edict_p;
begin
  for i := 1 to Trunc(maxclients^.Value) do
  begin
    other := @g_edicts^[0];
    inc(other, i);
    if other^.inuse and (not other^.client^.resp.spectator) then
    begin
      ent^.client^.chase_target := other;
      ent^.client^.update_chase := true;
      UpdateChaseCam(ent);
      Exit;
    end;
  end;
  gi.centerprintf(ent, 'No other players to chase.');
end;



end.
