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
{ File(s): g_chase.pas                                                       }
{ Content: Quake2\Game-CTF\ Server commands                                  }
{                                                                            }
{ Initial conversion by : you_known - you_known@163.com                      }
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
{ * Updated:                                                                 }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{                                                                            }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{                                                                            }
{----------------------------------------------------------------------------}

unit g_chase;

interface

uses g_local;

type pedict_t = ^edict_t;
     ptrace_t = ^trace_t;

implementation

procedure UpdateChaseCam( ent:pedict_t);
var
  o, ownerv, goal:vec3_t;
  targ:pedict_t;
  forwards, right:vec3_t;
  trace:ptrace_t;
  i:smallint;
  oldgoal:vec3_t;
  angles:vec3_t;
        s:array [0..1023] of char;
begin
  // is our chase target gone?
  if (not ent^.client^.chase_target^.inuse) then
  begin
    ent^.client^.chase_target := nil;
    exit;
  end;

  targ := ent^.client^.chase_target;

  VectorCopy(targ^.s.origin, ownerv);
  VectorCopy(ent^.s.origin, oldgoal);

  ownerv[2] := ownerv[2] + targ^.viewheight;

  VectorCopy(targ^.client^.v_angle, angles);
  if (angles[PITCH] > 56) then
    angles[PITCH] := 56;
  AngleVectors (angles, forwards, right, nil);
  VectorNormalize(forwards);
  VectorMA(ownerv, -30, forwards, o);

  if (o[2] < targ^.s.origin[2] + 20) then
    o[2] := targ^.s.origin[2] + 20;

  // jump animation lifts
  if (not targ^.groundentity) then
    o[2] := o[2] + 16;

  trace := gi.trace(ownerv, vec3_origin, vec3_origin, o, targ, MASK_SOLID);

  VectorCopy(trace.endpos, goal);

  VectorMA(goal, 2, forwards, goal);

  // pad for floors and ceilings
  VectorCopy(goal, o);
  o[2] := o[2] + 6;
  trace := gi.trace(goal, vec3_origin, vec3_origin, o, targ, MASK_SOLID);
  if (trace.fraction < 1) then
        begin
    VectorCopy(trace.endpos, goal);
    goal[2] := goal[2] - 6;
        end;

  VectorCopy(goal, o);
  o[2] := o[2] - 6;
  trace := gi.trace(goal, vec3_origin, vec3_origin, o, targ, MASK_SOLID);
  if (trace.fraction < 1) then
        begin
    VectorCopy(trace.endpos, goal);
    goal[2] := goal[2] - 6;
        end;

  ent^.client^.ps.pmove.pm_type := PM_FREEZE;

  VectorCopy(goal, ent^.s.origin);
  for i:=0 to 2 do
    ent^.client^.ps.pmove.delta_angles[i] := ANGLE2SHORT(targ^.client^.v_angle[i] - ent^.client^.resp.cmd_angles[i]);

  VectorCopy(targ^.client^.v_angle, ent^.client^.ps.viewangles);
  VectorCopy(targ^.client^.v_angle, ent^.client^.v_angle);

  ent^.viewheight := 0;
  ent^.client^.ps.pmove.pm_flags := ent^.client^.ps.pmove.pm_flags or PMF_NO_PREDICTION;
  gi.linkentity(ent);

  if ((not ent^.client^.showscores and not ent^.client^.menu and
    not ent^.client^.showinventory and not ent^.client^.showhelp and
    not (level.framenum and 31)) or ent^.client^.update_chase) then
  begin
    ent^.client^.update_chase := false;
    sprintf(s, 'xv 0 yb -68 string2 "Chasing %s"', targ^.client^.pers.netname);
    gi.WriteByte (svc_layout);
    gi.WriteString (s);
    gi.unicast(ent, false);
  end;

end;

procedure ChaseNext( ent:pedict_t);
var
  i:smallint;
  e:pedict_t;
begin
  if (not ent^.client^.chase_target) then
    exit;

  i := ent^.client^.chase_target - g_edicts;
        repeat
    i := i + 1;
    if (i > maxclients^.value) then
      i := 1;
    e := g_edicts + i;
    if (not e^.inuse) then
      continue;
    if (e^.solid <> SOLID_NOT) then
      break;
  until (e <> ent^.client^.chase_target);

  ent^.client^.chase_target := e;
  ent^.client^.update_chase := true;
end;

procedure ChasePrev(ent:pedict_t);
var  i:smallint;
  e:pedict_t;
begin
  if (not ent^.client^.chase_target) then
    exit;

  i := ent^.client^.chase_target - g_edicts;
  repeat
    i := i - 1;
    if (i < 1) then
      i := maxclients^.value;
    e := g_edicts + i;
    if (not e^.inuse) then
      continue;
    if (e^.solid <> SOLID_NOT) then
      break;
  until (e <> ent^.client^.chase_target);

  ent^.client^.chase_target := e;
  ent^.client^.update_chase := true;
end;

end.
