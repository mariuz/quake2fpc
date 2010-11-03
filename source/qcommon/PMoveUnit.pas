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


{$ALIGN ON}{$MINENUMSIZE 4}
{----------------------------------------------------------------------------}
{                                                                            }
{ File(s): QCommon.h (part), PMove.c                                         }
{ Content: Quake2\QCommon\ PLAYER MOVEMENT CODE                              }
{                                                                            }
{ Initial conversion by : Clootie (Alexey Barkovoy) - clootie@reactor.ru     }
{ Initial conversion on : 25-Feb-2002                                        }
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
{                                                                            }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{                                                                            }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{----------------------------------------------------------------------------}

unit PMoveUnit;

interface

uses
  q_shared_add,
  q_shared;

{*
==============================================================

PLAYER MOVEMENT CODE

Common between server and client so prediction matches

==============================================================
*}

var
  pm_airaccelerate: Single = 0;

procedure Pmove(pmove: pmove_p); cdecl;

implementation

uses
  Common;

const
  STEPSIZE = 18;

// all of the locals will be zeroed before each
// pmove, just to make damn sure we don't have
// any differences when running on client or server

type
  pml_p = ^pml_t;
  pml_t = record
    origin: vec3_t;                     // full float precision
    velocity: vec3_t;                   // full float precision

    forward, right, up: vec3_t;
    frametime: Single;

    groundsurface: csurface_p;
    groundplane: cplane_t;
    groundcontents: Integer;

    previous_origin: vec3_t;
    ladder: qboolean;
  end;

var
  pm: pmove_p;
  pml: pml_t;

  // movement parameters
  pm_stopspeed: Single = 100;
  pm_maxspeed: Single = 300;
  pm_duckspeed: Single = 100;
  pm_accelerate: Single = 10;
  //  pm_airaccelerate      : Single = 0; // - in interface part
  pm_wateraccelerate: Single = 10;
  pm_friction: Single = 6;
  pm_waterfriction: Single = 1;
  pm_waterspeed: Single = 400;

{*

  walking up a step should kill some velocity

*}

{*
==================
PM_ClipVelocity

Slide off of the impacting object
returns the blocked flags (1 = floor, 2 = step / wall)
==================
*}
const
  STOP_EPSILON = 0.1;

procedure PM_ClipVelocity(const in_, normal: vec3_t; var out_: vec3_t; overbounce: Single);
var
  backoff: Single;
  change: Single;
  i: Integer;
begin
  backoff := DotProduct(in_, normal) * overbounce;

  for i := 0 to 2 do
  begin
    change := normal[i] * backoff;
    out_[i] := in_[i] - change;
    if (out_[i] > -STOP_EPSILON) and (out_[i] < STOP_EPSILON) then
      out_[i] := 0;
  end;
end;

{*
==================
PM_StepSlideMove

Each intersection will try to step over the obstruction instead of
sliding along it.

Returns a new origin, velocity, and contact entity
Does not modify any world state?
==================
*}
const
  MIN_STEP_NORMAL = 0.7;                // can't step up onto very steep slopes
  MAX_CLIP_PLANES = 5;

procedure PM_StepSlideMove_;
var
  bumpcount, numbumps: Integer;
  dir: vec3_t;
  d: Single;
  numplanes: Integer;
  planes: array[0..MAX_CLIP_PLANES - 1] of vec3_t;
  primal_velocity: vec3_t;
  i, j: Integer;
  trace: trace_t;
  end_: vec3_t;
  time_left: Single;
begin
  numbumps := 4;

  VectorCopy(pml.velocity, primal_velocity);
  numplanes := 0;

  time_left := pml.frametime;

  for bumpcount := 0 to numbumps - 1 do
  begin
    for i := 0 to 2 do
      end_[i] := pml.origin[i] + time_left * pml.velocity[i];

    trace := pm.trace(pml.origin, pm.mins, pm.maxs, end_);

    if (trace.allsolid) then
    begin                               // entity is trapped in another solid
      pml.velocity[2] := 0;             // don't build up falling damage
      Exit;
    end;

    if (trace.fraction > 0) then
    begin                               // actually covered some distance
      VectorCopy(trace.endpos, pml.origin);
      numplanes := 0;
    end;

    if (trace.fraction = 1) then
      Break;                            // moved the entire distance

    // save entity for contact
    if (pm.numtouch < MAXTOUCH) and (trace.ent <> nil) then
    begin
      pm.touchents[pm.numtouch] := trace.ent;
      Inc(pm.numtouch);
    end;

    time_left := time_left - time_left * trace.fraction;

    // slide along this plane
    if (numplanes >= MAX_CLIP_PLANES) then
    begin                               // this shouldn't really happen
      VectorCopy(vec3_origin, pml.velocity);
      Break;
    end;

    VectorCopy(trace.plane.normal, planes[numplanes]);
    Inc(numplanes);

    (*
    float      rub;

        //
        // modify velocity so it parallels all of the clip planes
        //
        if (numplanes == 1)
        {   // go along this plane
                VectorCopy (pml.velocity, dir);
                VectorNormalize (dir);
                rub = 1.0 + 0.5 * DotProduct (dir, planes[0]);

                // slide along the plane
                PM_ClipVelocity (pml.velocity, planes[0], pml.velocity, 1.01);
                // rub some extra speed off on xy axis
                // not on Z, or you can scrub down walls
                pml.velocity[0] *= rub;
                pml.velocity[1] *= rub;
                pml.velocity[2] *= rub;
        }
        else if (numplanes == 2)
        {   // go along the crease
                VectorCopy (pml.velocity, dir);
                VectorNormalize (dir);
                rub = 1.0 + 0.5 * DotProduct (dir, planes[0]);

                // slide along the plane
                CrossProduct (planes[0], planes[1], dir);
                d = DotProduct (dir, pml.velocity);
                VectorScale (dir, d, pml.velocity);

                // rub some extra speed off
                VectorScale (pml.velocity, rub, pml.velocity);
        }
        else
        {
    //         Con_Printf ("clip velocity, numplanes == %d\n",numplanes);
                VectorCopy (vec3_origin, pml.velocity);
                break;
        }

    *)
    //
    // modify original_velocity so it parallels all of the clip planes
    //
    i := 0;
    while (i < numplanes) do
    begin
      PM_ClipVelocity(pml.velocity, planes[i], pml.velocity, 1.01);
      j := 0;
      while (j < numplanes) do
      begin
        if (j <> i) then
        begin
          if (DotProduct(pml.velocity, planes[j]) < 0) then
            Break;                      // not ok
        end;
        Inc(j);
      end;

      if (j = numplanes) then
        Break;
      Inc(i);
    end;

    if (i <> numplanes) then
    begin                               // go along this plane
    end
    else
    begin                               // go along the crease
      if (numplanes <> 2) then
      begin
        //      Con_Printf ('clip velocity, numplanes == %d'#10, [numplanes]);
        VectorCopy(vec3_origin, pml.velocity);
        Break;
      end;
      CrossProduct(planes[0], planes[1], dir);
      d := DotProduct(dir, pml.velocity);
      VectorScale(dir, d, pml.velocity);
    end;
    //
    // if velocity is against the original velocity, stop dead
    // to avoid tiny occilations in sloping corners
    //
    if (DotProduct(pml.velocity, primal_velocity) <= 0) then
    begin
      VectorCopy(vec3_origin, pml.velocity);
      Break;
    end;
  end;

  if (pm.s.pm_time <> 0) then
  begin
    VectorCopy(primal_velocity, pml.velocity);
  end;
end;

{*
==================
PM_StepSlideMove

==================
*}
procedure PM_StepSlideMove;
var
  start_o, start_v: vec3_t;
  down_o, down_v: vec3_t;
  trace: trace_t;
  down_dist, up_dist: Single;
  up, down: vec3_t;
begin
  VectorCopy(pml.origin, start_o);
  VectorCopy(pml.velocity, start_v);

  PM_StepSlideMove_;

  VectorCopy(pml.origin, down_o);
  VectorCopy(pml.velocity, down_v);

  VectorCopy(start_o, up);
  up[2] := up[2] + STEPSIZE;

  trace := pm.trace(up, pm.mins, pm.maxs, up);
  if (trace.allsolid) then
    Exit;                               // can't step up

  // try sliding above
  VectorCopy(up, pml.origin);
  VectorCopy(start_v, pml.velocity);

  PM_StepSlideMove_;

  // push down the final amount
  VectorCopy(pml.origin, down);
  down[2] := down[2] - STEPSIZE;
  trace := pm.trace(pml.origin, pm.mins, pm.maxs, down);
  if not trace.allsolid then
  begin
    VectorCopy(trace.endpos, pml.origin);
  end;

  {
    VectorSubtract (pml.origin, up, delta);
    up_dist = DotProduct (delta, start_v);

    VectorSubtract (down_o, start_o, delta);
    down_dist = DotProduct (delta, start_v);
  }
  VectorCopy(pml.origin, up);

  // decide which one went farther
  down_dist := (down_o[0] - start_o[0]) * (down_o[0] - start_o[0]) +
    (down_o[1] - start_o[1]) * (down_o[1] - start_o[1]);
  up_dist := (up[0] - start_o[0]) * (up[0] - start_o[0]) +
    (up[1] - start_o[1]) * (up[1] - start_o[1]);

  if (down_dist > up_dist) or (trace.plane.normal[2] < MIN_STEP_NORMAL) then
  begin
    VectorCopy(down_o, pml.origin);
    VectorCopy(down_v, pml.velocity);
    Exit;
  end;
  //!! Special case
  // if we were walking along a plane, then we need to copy the Z over
  pml.velocity[2] := down_v[2];
end;

{*
==================
PM_Friction

Handles both ground friction and water friction
==================
*}
procedure PM_Friction_func;
var
  vel: vec3_p;
  speed, newspeed, control: Single;
  friction: Single;
  drop: Single;
begin
  vel := @pml.velocity;

  speed := sqrt(vel[0] * vel[0] + vel[1] * vel[1] + vel[2] * vel[2]);
  if (speed < 1) then
  begin
    vel[0] := 0;
    vel[1] := 0;
    Exit;
  end;

  drop := 0;

  // apply ground friction
  if ((pm.groundentity <> nil) and (pml.groundsurface <> nil) and (pml.groundsurface.flags and SURF_SLICK = 0)) or
    (pml.ladder) then
  begin
    friction := pm_friction;
    // control = speed < pm_stopspeed ? pm_stopspeed : speed;
    if (speed < pm_stopspeed) then
      control := pm_stopspeed
    else
      control := speed;
    drop := drop + control * friction * pml.frametime;
  end;

  // apply water friction
  if (pm.waterlevel <> 0) and (not pml.ladder) then
    drop := drop + speed * pm_waterfriction * pm.waterlevel * pml.frametime;

  // scale the velocity
  newspeed := speed - drop;
  if (newspeed < 0) then
  begin
    newspeed := 0;
  end;
  newspeed := newspeed / speed;

  vel[0] := vel[0] * newspeed;
  vel[1] := vel[1] * newspeed;
  vel[2] := vel[2] * newspeed;
end;

{*
==============
PM_Accelerate

Handles user intended acceleration
==============
*}
procedure PM_Accelerate_func(const wishdir: vec3_t; wishspeed, accel: Single);
var
  i: Integer;
  addspeed, accelspeed, currentspeed: Single;
begin
  currentspeed := DotProduct(pml.velocity, wishdir);
  addspeed := wishspeed - currentspeed;
  if (addspeed <= 0) then
    Exit;
  accelspeed := accel * pml.frametime * wishspeed;
  if (accelspeed > addspeed) then
    accelspeed := addspeed;

  for i := 0 to 2 do
    pml.velocity[i] := pml.velocity[i] + accelspeed * wishdir[i];
end;

procedure PM_AirAccelerate_func(const wishdir: vec3_t; wishspeed, accel: Single);
var
  i: Integer;
  addspeed, accelspeed, currentspeed, wishspd: Single;
begin
  wishspd := wishspeed;

  if (wishspd > 30) then
    wishspd := 30;
  currentspeed := DotProduct(pml.velocity, wishdir);
  addspeed := wishspd - currentspeed;
  if (addspeed <= 0) then
    Exit;
  accelspeed := accel * wishspeed * pml.frametime;
  if (accelspeed > addspeed) then
    accelspeed := addspeed;

  for i := 0 to 2 do
    pml.velocity[i] := pml.velocity[i] + accelspeed * wishdir[i];
end;

{*
=============
PM_AddCurrents
=============
*}
procedure PM_AddCurrents(var wishvel: vec3_t);
var
  v: vec3_t;
  s: Single;
begin
  //
  // account for ladders
  //

  if pml.ladder and (Abs(pml.velocity[2]) <= 200) then
  begin
    if ((pm.viewangles[PITCH] <= -15) and (pm.cmd.forwardmove > 0)) then
      wishvel[2] := 200
    else if ((pm.viewangles[PITCH] >= 15) and (pm.cmd.forwardmove > 0)) then
      wishvel[2] := -200
    else if (pm.cmd.upmove > 0) then
      wishvel[2] := 200
    else if (pm.cmd.upmove < 0) then
      wishvel[2] := -200
    else
      wishvel[2] := 0;

    // limit horizontal speed when on a ladder
    if (wishvel[0] < -25) then
      wishvel[0] := -25
    else if (wishvel[0] > 25) then
      wishvel[0] := 25;

    if (wishvel[1] < -25) then
      wishvel[1] := -25
    else if (wishvel[1] > 25) then
      wishvel[1] := 25;
  end;

  //
  // add water currents
  //

  if (pm.watertype and MASK_CURRENT <> 0) then
  begin
    VectorClear(v);

    if (pm.watertype and CONTENTS_CURRENT_0 <> 0) then
      v[0] := v[0] + 1;
    if (pm.watertype and CONTENTS_CURRENT_90 <> 0) then
      v[1] := v[1] + 1;
    if (pm.watertype and CONTENTS_CURRENT_180 <> 0) then
      v[0] := v[0] - 1;
    if (pm.watertype and CONTENTS_CURRENT_270 <> 0) then
      v[1] := v[1] - 1;
    if (pm.watertype and CONTENTS_CURRENT_UP <> 0) then
      v[2] := v[2] + 1;
    if (pm.watertype and CONTENTS_CURRENT_DOWN <> 0) then
      v[2] := v[2] - 1;

    s := pm_waterspeed;
    if (pm.waterlevel = 1) and (pm.groundentity <> nil) then
      s := s / 2;

    VectorMA(wishvel, s, v, wishvel);
  end;

  //
  // add conveyor belt velocities
  //

  if (pm.groundentity <> nil) then
  begin
    VectorClear(v);

    if (pml.groundcontents and CONTENTS_CURRENT_0 <> 0) then
      v[0] := v[0] + 1;
    if (pml.groundcontents and CONTENTS_CURRENT_90 <> 0) then
      v[1] := v[1] + 1;
    if (pml.groundcontents and CONTENTS_CURRENT_180 <> 0) then
      v[0] := v[0] - 1;
    if (pml.groundcontents and CONTENTS_CURRENT_270 <> 0) then
      v[1] := v[1] - 1;
    if (pml.groundcontents and CONTENTS_CURRENT_UP <> 0) then
      v[2] := v[2] + 1;
    if (pml.groundcontents and CONTENTS_CURRENT_DOWN <> 0) then
      v[2] := v[2] - 1;

    VectorMA(wishvel, 100 {* pm->groundentity->speed *}, v, wishvel);
  end;
end;

{*
===================
PM_WaterMove

===================
*}
procedure PM_WaterMove;
var
  i: Integer;
  wishvel: vec3_t;
  wishspeed: Single;
  wishdir: vec3_t;
begin
  //
  // user intentions
  //
  for i := 0 to 2 do
    wishvel[i] := pml.forward[i] * pm.cmd.forwardmove + pml.right[i] * pm.cmd.sidemove;

  if (pm.cmd.forwardmove = 0) and (pm.cmd.sidemove = 0) and (pm.cmd.upmove = 0) then
    wishvel[2] := wishvel[2] - 60       // drift towards bottom
  else
    wishvel[2] := wishvel[2] + pm.cmd.upmove;

  PM_AddCurrents(wishvel);

  VectorCopy(wishvel, wishdir);
  wishspeed := VectorNormalize(wishdir);

  if (wishspeed > pm_maxspeed) then
  begin
    VectorScale(wishvel, pm_maxspeed / wishspeed, wishvel);
    wishspeed := pm_maxspeed;
  end;
  wishspeed := wishspeed * 0.5;

  PM_Accelerate_func(wishdir, wishspeed, pm_wateraccelerate);

  PM_StepSlideMove;
end;

{*
===================
PM_AirMove

===================
*}
procedure PM_AirMove;
var
  i: Integer;
  wishvel: vec3_t;
  fmove, smove: Single;
  wishdir: vec3_t;
  wishspeed: Single;
  maxspeed: Single;
begin
  fmove := pm.cmd.forwardmove;
  smove := pm.cmd.sidemove;

  {
    pml.forward[2] = 0;
    pml.right[2] = 0;
    VectorNormalize (pml.forward);
    VectorNormalize (pml.right);
  }

  for i := 0 to 1 do
    wishvel[i] := pml.forward[i] * fmove + pml.right[i] * smove;
  wishvel[2] := 0;

  PM_AddCurrents(wishvel);

  VectorCopy(wishvel, wishdir);
  wishspeed := VectorNormalize(wishdir);

  //
  // clamp to server defined max speed
  //
  // maxspeed = (pm->s.pm_flags & PMF_DUCKED) ? pm_duckspeed : pm_maxspeed;
  if (pm.s.pm_flags and PMF_DUCKED) <> 0 then
    maxspeed := pm_duckspeed
  else
    maxspeed := pm_maxspeed;

  if (wishspeed > maxspeed) then
  begin
    VectorScale(wishvel, maxspeed / wishspeed, wishvel);
    wishspeed := maxspeed;
  end;

  if pml.ladder then
  begin
    PM_Accelerate_func(wishdir, wishspeed, pm_accelerate);
    if (wishvel[2] = 0) then
    begin
      if (pml.velocity[2] > 0) then
      begin
        pml.velocity[2] := pml.velocity[2] - pm.s.gravity * pml.frametime;
        if (pml.velocity[2] < 0) then
          pml.velocity[2] := 0;
      end
      else
      begin
        pml.velocity[2] := pml.velocity[2] + pm.s.gravity * pml.frametime;
        if (pml.velocity[2] > 0) then
          pml.velocity[2] := 0;
      end;
    end;
    PM_StepSlideMove;
  end
  else if (pm.groundentity <> nil) then
  begin                                 // walking on ground
    pml.velocity[2] := 0;               //!!! this is before the accel
    PM_Accelerate_func(wishdir, wishspeed, pm_accelerate);

    // PGM   -- fix for negative trigger_gravity fields
    //      pml.velocity[2] = 0;
    if (pm.s.gravity > 0) then
      pml.velocity[2] := 0
    else
      pml.velocity[2] := pml.velocity[2] - pm.s.gravity * pml.frametime;
    // PGM

    if (pml.velocity[0] = 0) and (pml.velocity[1] = 0) then
      Exit;
    PM_StepSlideMove;
  end
  else
  begin                                 // not on ground, so little effect on velocity
    if (pm_airaccelerate <> 0) then
      PM_AirAccelerate_func(wishdir, wishspeed, pm_accelerate)
    else
      PM_Accelerate_func(wishdir, wishspeed, 1);
    // add gravity
    pml.velocity[2] := pml.velocity[2] - pm.s.gravity * pml.frametime;
    PM_StepSlideMove;
  end;
end;

{*
=============
PM_CatagorizePosition
=============
*}
procedure PM_CatagorizePosition;
var
  point: vec3_t;
  cont: Integer;
  trace: trace_t;
  sample1: Integer;
  sample2: Integer;
begin
  // if the player hull point one unit down is solid, the player
  // is on ground

  // see if standing on something solid
  point[0] := pml.origin[0];
  point[1] := pml.origin[1];
  point[2] := pml.origin[2] - 0.25;
  if (pml.velocity[2] > 180) then       //!!ZOID changed from 100 to 180 (ramp accel)
  begin
    pm.s.pm_flags := pm.s.pm_flags and not PMF_ON_GROUND;
    pm.groundentity := nil;
  end
  else
  begin
    trace := pm.trace(pml.origin, pm.mins, pm.maxs, point);
    pml.groundplane := trace.plane;
    pml.groundsurface := trace.surface;
    pml.groundcontents := trace.contents;

    if (trace.ent = nil) or
      ((trace.plane.normal[2] < 0.7) and (not trace.startsolid)) then
    begin
      pm.groundentity := nil;
      pm.s.pm_flags := pm.s.pm_flags and not PMF_ON_GROUND;
    end
    else
    begin
      pm.groundentity := trace.ent;

      // hitting solid ground will end a waterjump
      if (pm.s.pm_flags and PMF_TIME_WATERJUMP <> 0) then
      begin
        pm.s.pm_flags := pm.s.pm_flags and not (PMF_TIME_WATERJUMP or PMF_TIME_LAND or PMF_TIME_TELEPORT);
        pm.s.pm_time := 0;
      end;

      if (pm.s.pm_flags and PMF_ON_GROUND) = 0 then
      begin                             // just hit the ground
        pm.s.pm_flags := pm.s.pm_flags or PMF_ON_GROUND;
        // don't do landing time if we were just going down a slope
        if (pml.velocity[2] < -200) then
        begin
          pm.s.pm_flags := pm.s.pm_flags or PMF_TIME_LAND;
          // don't allow another jump for a little while
          if (pml.velocity[2] < -400) then
            pm.s.pm_time := 25
          else
            pm.s.pm_time := 18;
        end;
      end;
    end;

    {
        if (trace.fraction < 1.0 && trace.ent && pml.velocity[2] < 0)
                pml.velocity[2] = 0;
    }

    if (pm.numtouch < MAXTOUCH) and (trace.ent <> nil) then
    begin
      pm.touchents[pm.numtouch] := trace.ent;
      Inc(pm.numtouch);
    end;
  end;

  //
  // get waterlevel, accounting for ducking
  //
  pm.waterlevel := 0;
  pm.watertype := 0;

  sample2 := Trunc(pm.viewheight - pm.mins[2]);
  sample1 := sample2 div 2;

  point[2] := pml.origin[2] + pm.mins[2] + 1;
  cont := pm.pointcontents(point);

  if (cont and MASK_WATER <> 0) then
  begin
    pm.watertype := cont;
    pm.waterlevel := 1;
    point[2] := pml.origin[2] + pm.mins[2] + sample1;
    cont := pm.pointcontents(point);
    if (cont and MASK_WATER <> 0) then
    begin
      pm.waterlevel := 2;
      point[2] := pml.origin[2] + pm.mins[2] + sample2;
      cont := pm.pointcontents(point);
      if (cont and MASK_WATER <> 0) then
        pm.waterlevel := 3;
    end;
  end;

end;

{*
=============
PM_CheckJump
=============
*}
procedure PM_CheckJump;
begin
  if (pm.s.pm_flags and PMF_TIME_LAND <> 0) then
  begin                                 // hasn't been long enough since landing to jump again
    Exit;
  end;

  if (pm.cmd.upmove < 10) then
  begin                                 // not holding jump
    pm.s.pm_flags := pm.s.pm_flags and not PMF_JUMP_HELD;
    Exit;
  end;

  // must wait for jump to be released
  if (pm.s.pm_flags and PMF_JUMP_HELD <> 0) then
    Exit;

  if (pm.s.pm_type = PM_DEAD) then
    Exit;

  if (pm.waterlevel >= 2) then
  begin                                 // swimming, not jumping
    pm.groundentity := nil;

    if (pml.velocity[2] <= -300) then
      Exit;

    if (pm.watertype = CONTENTS_WATER) then
      pml.velocity[2] := 100
    else if (pm.watertype = CONTENTS_SLIME) then
      pml.velocity[2] := 80
    else
      pml.velocity[2] := 50;
    Exit;
  end;

  if (pm.groundentity = nil) then
    Exit;                               // in air, so no effect

  pm.s.pm_flags := pm.s.pm_flags or PMF_JUMP_HELD;

  pm.groundentity := nil;
  pml.velocity[2] := pml.velocity[2] + 270;
  if (pml.velocity[2] < 270) then
    pml.velocity[2] := 270;
end;

{*
=============
PM_CheckSpecialMovement
=============
*}
procedure PM_CheckSpecialMovement;
var
  spot: vec3_t;
  cont: Integer;
  flatforward: vec3_t;
  trace: trace_t;
begin
  if (pm.s.pm_time <> 0) then
    Exit;

  pml.ladder := False;

  // check for ladder
  flatforward[0] := pml.forward[0];
  flatforward[1] := pml.forward[1];
  flatforward[2] := 0;
  VectorNormalize(flatforward);

  VectorMA(pml.origin, 1, flatforward, spot);
  trace := pm.trace(pml.origin, pm.mins, pm.maxs, spot);
  if (trace.fraction < 1) and (trace.contents and CONTENTS_LADDER <> 0) then
    pml.ladder := True;

  // check for water jump
  if (pm.waterlevel <> 2) then
    Exit;

  VectorMA(pml.origin, 30, flatforward, spot);
  spot[2] := spot[2] + 4;
  cont := pm.pointcontents(spot);
  if (cont and CONTENTS_SOLID = 0) then
    Exit;

  spot[2] := spot[2] + 16;
  cont := pm.pointcontents(spot);
  if (cont <> 0) then
    exit;

  // jump out of water
  VectorScale(flatforward, 50, pml.velocity);
  pml.velocity[2] := 350;

  pm.s.pm_flags := pm.s.pm_flags or PMF_TIME_WATERJUMP;
  pm.s.pm_time := 255;
end;

{*
===============
PM_FlyMove
===============
*}
procedure PM_FlyMove(doclip: qboolean);
var
  speed, drop, friction, control, newspeed: Single;
  currentspeed, addspeed, accelspeed: Single;
  i: Integer;
  wishvel: vec3_t;
  fmove, smove: Single;
  wishdir: vec3_t;
  wishspeed: Single;
  end_: vec3_t;
  trace: trace_t;
begin
  pm.viewheight := 22;

  // friction

  speed := VectorLength(pml.velocity);
  if (speed < 1) then
  begin
    VectorCopy(vec3_origin, pml.velocity);
  end
  else
  begin
    drop := 0;

    friction := pm_friction * 1.5;      // extra friction
    //control = speed < pm_stopspeed ? pm_stopspeed : speed;
    if (speed < pm_stopspeed) then
      control := pm_stopspeed
    else
      control := speed;
    drop := drop + control * friction * pml.frametime;

    // scale the velocity
    newspeed := speed - drop;
    if (newspeed < 0) then
      newspeed := 0;
    newspeed := newspeed / speed;

    VectorScale(pml.velocity, newspeed, pml.velocity);
  end;

  // accelerate
  fmove := pm.cmd.forwardmove;
  smove := pm.cmd.sidemove;

  VectorNormalize(pml.forward);
  VectorNormalize(pml.right);

  for i := 0 to 2 do
    wishvel[i] := pml.forward[i] * fmove + pml.right[i] * smove;
  wishvel[2] := wishvel[2] + pm.cmd.upmove;

  VectorCopy(wishvel, wishdir);
  wishspeed := VectorNormalize(wishdir);

  //
  // clamp to server defined max speed
  //
  if (wishspeed > pm_maxspeed) then
  begin
    VectorScale(wishvel, pm_maxspeed / wishspeed, wishvel);
    wishspeed := pm_maxspeed;
  end;

  currentspeed := DotProduct(pml.velocity, wishdir);
  addspeed := wishspeed - currentspeed;
  if (addspeed <= 0) then
    Exit;
  accelspeed := pm_accelerate * pml.frametime * wishspeed;
  if (accelspeed > addspeed) then
    accelspeed := addspeed;

  for i := 0 to 2 do
    pml.velocity[i] := pml.velocity[i] + accelspeed * wishdir[i];

  if (doclip) then
  begin
    for i := 0 to 2 do
      end_[i] := pml.origin[i] + pml.frametime * pml.velocity[i];

    trace := pm.trace(pml.origin, pm.mins, pm.maxs, end_);

    VectorCopy(trace.endpos, pml.origin);
  end
  else
  begin
    // move
    VectorMA(pml.origin, pml.frametime, pml.velocity, pml.origin);
  end;
end;

{*
==============
PM_CheckDuck

Sets mins, maxs, and pm->viewheight
==============
*}
procedure PM_CheckDuck;
var
  trace: trace_t;
begin
  pm.mins[0] := -16;
  pm.mins[1] := -16;

  pm.maxs[0] := 16;
  pm.maxs[1] := 16;

  if (pm.s.pm_type = PM_GIB) then
  begin
    pm.mins[2] := 0;
    pm.maxs[2] := 16;
    pm.viewheight := 8;
    Exit;
  end;

  pm.mins[2] := -24;

  if (pm.s.pm_type = PM_DEAD) then
  begin
    pm.s.pm_flags := pm.s.pm_flags or PMF_DUCKED;
  end
  else if (pm.cmd.upmove < 0) and (pm.s.pm_flags and PMF_ON_GROUND <> 0) then
  begin                                 // duck
    pm.s.pm_flags := pm.s.pm_flags or PMF_DUCKED;
  end
  else
  begin                                 // stand up if possible
    if (pm.s.pm_flags and PMF_DUCKED <> 0) then
    begin
      // try to stand up
      pm.maxs[2] := 32;
      trace := pm.trace(pml.origin, pm.mins, pm.maxs, pml.origin);
      if (not trace.allsolid) then
        pm.s.pm_flags := pm.s.pm_flags and not PMF_DUCKED;
    end;
  end;

  if (pm.s.pm_flags and PMF_DUCKED <> 0) then
  begin
    pm.maxs[2] := 4;
    pm.viewheight := -2;
  end
  else
  begin
    pm.maxs[2] := 32;
    pm.viewheight := 22;
  end;
end;

{*
==============
PM_DeadMove
==============
*}
procedure PM_DeadMove;
var
  forward_: Single;
begin
  if (pm.groundentity = nil) then
    Exit;

  // extra friction

  forward_ := VectorLength(pml.velocity);
  forward_ := forward_ - 20;
  if (forward_ <= 0) then
  begin
    VectorClear(pml.velocity);
  end
  else
  begin
    VectorNormalize(pml.velocity);
    VectorScale(pml.velocity, forward_, pml.velocity);
  end;
end;

function PM_GoodPosition: qboolean;
var
  trace: trace_t;
  origin, end_: vec3_t;
  i: Integer;
begin
  if (pm.s.pm_type = PM_SPECTATOR) then
  begin
    Result := True;
    Exit;
  end;

  for i := 0 to 2 do
  begin
    end_[i] := pm.s.origin[i] * 0.125;
    origin[i] := end_[i]
  end;
  trace := pm.trace(origin, pm.mins, pm.maxs, end_);

  Result := not trace.allsolid;
end;

{*
================
PM_SnapPosition

On exit, the origin will have a value that is pre-quantized to the 0.125
precision of the network channel and in a valid position.
================
*}
procedure PM_SnapPosition;
var
  sign: array[0..2] of Integer;
  i, j, bits: Integer;
  base: array[0..2] of Smallint;
{$IFDEF COMPILER6_UP}{$WRITEABLECONST ON}{$ENDIF}
const
  // try all single bits first
  jitterbits: array[0..7] of Integer = (0, 4, 1, 2, 3, 5, 6, 7);
{$IFDEF COMPILER6_UP}{$WRITEABLECONST OFF}{$ENDIF}
begin
  // snap velocity to eigths
  for i := 0 to 2 do
    pm.s.velocity[i] := Trunc(pml.velocity[i] * 8);

  for i := 0 to 2 do
  begin
    if (pml.origin[i] >= 0) then
      sign[i] := 1
    else
      sign[i] := -1;
    pm.s.origin[i] := Trunc(pml.origin[i] * 8);
    if (pm.s.origin[i] * 0.125 = pml.origin[i]) then
      sign[i] := 0;
  end;
  VectorCopy(pm.s.origin, base);

  // try all combinations
  for j := 0 to 7 do
  begin
    bits := jitterbits[j];
    VectorCopy(base, pm.s.origin);
    for i := 0 to 2 do
      if (bits and (1 shl i) <> 0) then
        pm.s.origin[i] := pm.s.origin[i] + sign[i];

    if PM_GoodPosition then
      Exit;
  end;

  // go back to the last position
  VectorCopy(pml.previous_origin, pm.s.origin);
  //Com_DPrintf ('using previous_origin', []);
end;

(*
//NO LONGER USED
/*
================
PM_InitialSnapPosition

================
*/
void PM_InitialSnapPosition (void)
{
 int      x, y, z;
 short   base[3];

 VectorCopy (pm->s.origin, base);

 for (z=1 ; z>=-1 ; z--)
 {
  pm->s.origin[2] = base[2] + z;
  for (y=1 ; y>=-1 ; y--)
  {
   pm->s.origin[1] = base[1] + y;
   for (x=1 ; x>=-1 ; x--)
   {
    pm->s.origin[0] = base[0] + x;
    if (PM_GoodPosition ())
    {
     pml.origin[0] = pm->s.origin[0]*0.125;
     pml.origin[1] = pm->s.origin[1]*0.125;
     pml.origin[2] = pm->s.origin[2]*0.125;
     VectorCopy (pm->s.origin, pml.previous_origin);
     return;
    }
   }
  }
 }

 Com_DPrintf ('Bad InitialSnapPosition'#10);
}
*)

{*
================
PM_InitialSnapPosition

================
*}
procedure PM_InitialSnapPosition;
var
  x, y, z: Integer;
  base: array[0..2] of Smallint;
{$IFDEF COMPILER6_UP}{$WRITEABLECONST ON}{$ENDIF}
const
  offset: array[0..2] of Integer = (0, -1, 1);
{$IFDEF COMPILER6_UP}{$WRITEABLECONST OFF}{$ENDIF}
begin
  VectorCopy(pm.s.origin, base);

  for z := 0 to 2 do
  begin
    pm.s.origin[2] := base[2] + offset[z];
    for y := 0 to 2 do
    begin
      pm.s.origin[1] := base[1] + offset[y];
      for x := 0 to 2 do
      begin
        pm.s.origin[0] := base[0] + offset[x];
        if PM_GoodPosition then
        begin
          pml.origin[0] := pm.s.origin[0] * 0.125;
          pml.origin[1] := pm.s.origin[1] * 0.125;
          pml.origin[2] := pm.s.origin[2] * 0.125;
          VectorCopy(pm.s.origin, pml.previous_origin);
          Exit;
        end;
      end;
    end;
  end;

  Com_DPrintf('Bad InitialSnapPosition'#10, ['']);
end;

{*
================
PM_ClampAngles

================
*}
procedure PM_ClampAngles;
var
  temp: Word;
  i: Integer;
begin
  if (pm.s.pm_flags and PMF_TIME_TELEPORT <> 0) then
  begin
    pm.viewangles[YAW] := SHORT2ANGLE(pm.cmd.angles[YAW] + pm.s.delta_angles[YAW]);
    pm.viewangles[PITCH] := 0;
    pm.viewangles[ROLL] := 0;
  end
  else
  begin
    // circularly clamp the angles with deltas
    for i := 0 to 2 do
    begin
      temp := pm.cmd.angles[i] + pm.s.delta_angles[i];
      pm.viewangles[i] := SHORT2ANGLE(temp);
    end;

    // don't let the player look up or down more than 90 degrees
    if (pm.viewangles[PITCH] > 89) and (pm.viewangles[PITCH] < 180) then
      pm.viewangles[PITCH] := 89
    else if (pm.viewangles[PITCH] < 271) and (pm.viewangles[PITCH] >= 180) then
      pm.viewangles[PITCH] := 271;
  end;
  AngleVectors(pm.viewangles, @pml.forward, @pml.right, @pml.up);
end;

{*
================
Pmove

Can be called by either the server or the client
================
*}
procedure Pmove(pmove: pmove_p);
var
  msec: Integer;
  angles: vec3_t;
begin
  pm := pmove;

  // clear results
  pm.numtouch := 0;
  VectorClear(pm.viewangles);
  pm.viewheight := 0;
  pm.groundentity := nil;
  pm.watertype := 0;
  pm.waterlevel := 0;

  // clear all pmove local vars
  FillChar(pml, SizeOf(pml), 0);

  // convert origin and velocity to float values
  pml.origin[0] := pm.s.origin[0] * 0.125;
  pml.origin[1] := pm.s.origin[1] * 0.125;
  pml.origin[2] := pm.s.origin[2] * 0.125;

  pml.velocity[0] := pm.s.velocity[0] * 0.125;
  pml.velocity[1] := pm.s.velocity[1] * 0.125;
  pml.velocity[2] := pm.s.velocity[2] * 0.125;

  // save old org in case we get stuck
  VectorCopy(pm.s.origin, pml.previous_origin);

  pml.frametime := pm.cmd.msec * 0.001;

  PM_ClampAngles;

  if (pm.s.pm_type = PM_SPECTATOR) then
  begin
    PM_FlyMove(False);
    PM_SnapPosition;
    Exit;
  end;

  if (pm.s.pm_type >= PM_DEAD) then
  begin
    pm.cmd.forwardmove := 0;
    pm.cmd.sidemove := 0;
    pm.cmd.upmove := 0;
  end;

  if (pm.s.pm_type = PM_FREEZE) then
    Exit;                               // no movement at all

  // set mins, maxs, and viewheight
  PM_CheckDuck;

  if (pm.snapinitial) then
    PM_InitialSnapPosition;

  // set groundentity, watertype, and waterlevel
  PM_CatagorizePosition;

  if (pm.s.pm_type = PM_DEAD) then
    PM_DeadMove;

  PM_CheckSpecialMovement;

  // drop timing counter
  if (pm.s.pm_time <> 0) then
  begin
    msec := pm.cmd.msec shr 3;
    if (msec = 0) then
      msec := 1;
    if (msec >= pm.s.pm_time) then
    begin
      pm.s.pm_flags := pm.s.pm_flags and not (PMF_TIME_WATERJUMP or PMF_TIME_LAND or PMF_TIME_TELEPORT);
      pm.s.pm_time := 0;
    end
    else
      pm.s.pm_time := pm.s.pm_time - msec;
  end;

  if (pm.s.pm_flags and PMF_TIME_TELEPORT <> 0) then
  begin                                 // teleport pause stays exactly in place
  end
  else if (pm.s.pm_flags and PMF_TIME_WATERJUMP <> 0) then
  begin                                 // waterjump has no control, but falls
    pml.velocity[2] := pml.velocity[2] - pm.s.gravity * pml.frametime;
    if (pml.velocity[2] < 0) then
    begin                               // cancel as soon as we are falling down again
      pm.s.pm_flags := pm.s.pm_flags and not (PMF_TIME_WATERJUMP or PMF_TIME_LAND or PMF_TIME_TELEPORT);
      pm.s.pm_time := 0;
    end;

    PM_StepSlideMove;
  end
  else
  begin
    PM_CheckJump;

    PM_Friction_func;

    if (pm.waterlevel >= 2) then
      PM_WaterMove
    else
    begin
      VectorCopy(pm.viewangles, angles);
      if (angles[PITCH] > 180) then
        angles[PITCH] := angles[PITCH] - 360;
      angles[PITCH] := angles[PITCH] / 3;

      AngleVectors(angles, @pml.forward, @pml.right, @pml.up);

      PM_AirMove;
    end;
  end;

  // set groundentity, watertype, and waterlevel for final spot
  PM_CatagorizePosition;

  PM_SnapPosition;
end;

end.
