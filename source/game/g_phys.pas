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
{ File(s): g_phys.c                                                          }
{ Content: physics logic                                                     }
{                                                                            }
{ Initial conversion by : MathD (matheus@tilt.net                            }
{ Initial conversion on : 05-Feb-2002                                        }
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
{ Updated on :  26-Jul-2002                                                  }
{ Updated by :  Scott Price                                                  }
{                                                                            }
{----------------------------------------------------------------------------}


unit g_phys;

interface

uses
  g_local,
  q_shared;

{pushmove objects do not obey gravity, and do not interact with each other or
trigger fields, but block normal movement and push normal objects when they move.

onground is set for toss objects when they come to a complete rest.  it is set
for steping or walking objects

doors, plats, etc are SOLID_BSP, and MOVETYPE_PUSH
bonus items are SOLID_TRIGGER touch, and MOVETYPE_TOSS
corpses are SOLID_NOT and MOVETYPE_TOSS
crates are SOLID_BBOX and MOVETYPE_TOSS
walking monsters are SOLID_SLIDEBOX and MOVETYPE_STEP
flying/floating monsters are SOLID_SLIDEBOX and MOVETYPE_FLY

solid_edge items only clip against bsp models.}




function SV_TestEntityPosition(ent: edict_p): edict_p;
procedure SV_CheckVelocity (ent: edict_p);
function SV_RunThink (ent: edict_p): qboolean;
procedure SV_Impact(e1: edict_p; trace: trace_p);
function ClipVelocity(var in_, normal, out_: vec3_t; overbounce: single): integer;
function SV_FlyMove(ent: edict_p; time: single; mask: integer): integer;
procedure SV_AddGravity(ent: edict_p);
function SV_PushEntity(ent: edict_p; var push: vec3_t): trace_t;
function SV_Push(pusher: edict_p; var move_, amove: vec3_t): qboolean;
procedure SV_Physics_Pusher(ent: edict_p);
procedure SV_Physics_None(ent: edict_p);
procedure SV_Physics_Noclip(ent: edict_p);
procedure SV_Physics_Toss(ent: edict_p);
procedure SV_AddRotationalFriction(ent: edict_p);
procedure SV_Physics_Step(ent: edict_p);
procedure G_RunEntity(ent: edict_p);



implementation

uses g_main, game_add, g_utils, g_local_add, g_monster, m_move, GameUnit;


{/*
============
SV_TestEntityPosition

============
*/}
function SV_TestEntityPosition(ent: edict_p): edict_p;
var
  trace: trace_t;
  mask: integer;
begin
  if ent^.clipMask <> 0 then
    mask := ent^.clipMask
  else
    mask := MASK_SOLID;

  trace := gi.trace(@ent^.s.origin, @ent^.mins, @ent^.maxs, @ent^.s.origin, ent, mask);
  
  if (trace.startsolid) then
  begin
    Result := @g_edicts[0];
    exit;
  end;

  result := nil;
end;


{/*
================
SV_CheckVelocity
================
*/}

procedure SV_CheckVelocity (ent: edict_p);
var
  i: integer;
begin
  //
  // bound velocity
  //
  for i := 0 to 2 do
  begin
    if (ent^.velocity[i] > sv_maxvelocity^.value) then
      ent^.velocity[i] := sv_maxvelocity^.value
    else if (ent^.velocity[i] < (- sv_maxvelocity^.value)) then
      ent^.velocity[i] := -sv_maxvelocity^.value;
  end;
end;


{/*
=============
SV_RunThink

Runs thinking code for this frame if necessary
=============
*/}
function SV_RunThink (ent: edict_p): qboolean;
var
  thinktime: single;
begin
  thinktime := ent^.nextthink;
  if (thinktime <= 0) then
  begin
    Result := True;
    Exit;
  end;
  if (thinktime > level.time + 0.001) then
  begin
    Result := True;
    Exit;
  end;

  ent^.nextthink := 0;
  if (@ent^.think = nil) then
    gi.error('NIL ent^.think');
  ent^.think(ent);
  result := false;
end;


{/*
==================
SV_Impact

Two entities have touched, so run their touch functions
==================
*/}
procedure SV_Impact(e1: edict_p; trace: trace_p);
var
  e2: edict_p;
  //backplane: cplane_p;  <-- Commented out in the original
begin
  e2 := trace^.ent;

  if (@e1^.touch <> nil) and (e1^.solid <> SOLID_NOT) then
    e1^.touch(e1, e2, @trace^.plane, trace^.surface);

  if (@e2^.touch <> nil) and (e2^.solid <> SOLID_NOT) then
    e2^.touch(e2, e1, nil, nil);
end;



{/*
==================
ClipVelocity

Slide off of the impacting object
returns the blocked flags (1 = floor, 2 = step / wall)
==================
*/}
const STOP_EPSILON = 0.1;

function ClipVelocity(var in_, normal, out_: vec3_t; overbounce: single): integer;
var
  backoff, change: single;
  i, blocked: integer;
begin
  blocked := 0;
  if (normal[2] > 0) then
    blocked := blocked or 1; //floor

  if (normal[2] = 0) then
    blocked := blocked or 2; //step

  backoff := DotProduct(in_, normal) * overbounce;

  for i := 0 to 2 do
  begin
    change := normal[i] * backoff;
    out_[i] := in_[i] - change;
    if (out_[i] > -STOP_EPSILON) and (out_[i] < STOP_EPSILON) then
      out_[i] := 0;
  end;

  Result := blocked;
end;


{/*
============
SV_FlyMove

The basic solid body movement clip that slides along multiple planes
Returns the clipflags if the velocity was modified (hit something solid)
1 = floor
2 = wall / step
4 = dead stop
============
*/}
const MAX_CLIP_PLANES = 5;

function SV_FlyMove(ent: edict_p; time: single; mask: integer): integer;
var
  hit: edict_p;
  bumpcount, numbumps: integer;
  dir: vec3_t;
  d: single;
  numplanes: integer;
  planes: array[0..MAX_CLIP_PLANES -1] of vec3_t;
  primal_velocity, original_velocity, new_velocity: vec3_t;
  i, j: integer;
  trace: trace_t;
  end_: vec3_t;
  time_left: single;
  blocked: integer;
begin
  numbumps := 4;
  blocked := 0;
  VectorCopy(ent^.velocity, original_velocity);
  VectorCopy(ent^.velocity, primal_velocity);
  numplanes := 0;

  time_left := time;
  ent^.groundentity := nil;
  for bumpcount := 0 to (numbumps - 1) do
  begin
    for i := 0 to 2 do
      end_[i] := ent^.s.origin[i] + time_left * ent^.velocity[i];

    trace := gi.trace(@ent^.s.origin, @ent^.mins, @ent^.maxs, @end_, ent, mask);

    if (trace.allsolid) then
    begin
      //entity is trapped in another solid
      VectorCopy(vec3_origin, ent^.velocity);
      result := 3;
      Exit;
    end;

    if (trace.fraction > 0) then
    begin
      //actually covered some distance
      VectorCopy(trace.endpos, ent^.s.origin);
      VectorCopy(ent^.velocity, original_velocity);
      numplanes := 0;
    end;

    if (trace.fraction = 1) then
      Break; //moved the entire distance

    hit := trace.ent;

    if (trace.plane.normal[2] > 0.7) then
    begin
      blocked := blocked or 1; //floor;

      if (hit^.solid = SOLID_BSP) then
      begin
        ent^.groundentity := hit;
        ent^.groundentity_linkcount := hit^.linkcount;
      end;
    end;

    if trace.plane.normal[2]  = 0 then
      blocked := blocked or 2; //step

//
// run the impact function
//
    SV_Impact(ent, @trace);
    if not ent^.inuse then
      Break;

    time_left := time_left - (time_left * trace.fraction);
    //cliped to another plane
    if (numplanes >= MAX_CLIP_PLANES) then
    begin
      //this shouldn't really happen
      VectorCopy(vec3_origin, ent^.velocity);
      result := 3;
      Exit;
    end;

    VectorCopy(trace.plane.normal, planes[numplanes]);
    Inc(numplanes);

//
// modify original_velocity so it parallels all of the clip planes
//
    for i := 0 to (numplanes - 1) do
    begin
      ClipVelocity(original_velocity, planes[i], new_velocity, 1);

      for j := 0 to (numplanes - 1) do
      begin
        if (j <> i) and (VectorCompare(planes[i], planes[j]) = 0) then
        begin
          if (DotProduct(new_velocity, planes[j]) < 0) then
            Break; //not ok
        end;
      end;

      if j = numplanes then
        Break;
    end;

    if (i <> numplanes) then
      VectorCopy(new_velocity, ent^.velocity) //go along this plane
    else
    begin
      if (numplanes <> 2) then begin //go along the crease
        //gi.dprintf('clip velocity, numplanes = %i #13#10', numplanes);
        VectorCopy(vec3_origin, ent^.velocity);
        result := 7;
        Exit;
      end;

      CrossProduct(planes[0], planes[1], dir);
      d := DotProduct(dir, ent^.velocity);
      VectorScale(dir, d, ent^.velocity);
    end;

//
// if original velocity is against the original velocity, stop dead
// to avoid tiny occilations in sloping corners
//
    if (DotProduct(ent^.velocity, primal_velocity) <= 0) then
    begin
      VectorCopy(vec3_origin, ent^.velocity);
      result := blocked;
      exit;
    end;
  end;

  result := blocked;
end;


{/*
============
SV_AddGravity

============
*/}
procedure SV_AddGravity(ent: edict_p);
begin
  ent^.velocity[2] := ent^.velocity[2] - (ent^.gravity * sv_gravity^.value * FRAMETIME);
end;

{/*
===============================================================================

PUSHMOVE

===============================================================================
*/`}

{/*
============
SV_PushEntity

Does not change the entities velocity at all
============
*/}
function SV_PushEntity(ent: edict_p; var push: vec3_t): trace_t;
label retry;
var
  trace: trace_t;
  start, end_: vec3_t;
  mask: integer;
begin
  VectorCopy(ent^.s.origin, start);
  VectorAdd(start, push, end_);

retry:
  if (ent^.clipmask <> 0) then
    mask := ent^.clipmask
  else
    mask := MASK_SOLID;

  trace := gi.trace(@start, @ent^.mins, @ent^.maxs, @end_, ent, mask);

  VectorCopy(trace.endpos, ent^.s.origin);
  gi.linkentity(ent);

  if (trace.fraction <> 1.0) then
  begin
    SV_Impact(ent, @trace);

    //if the pushed entity went away and the pusher is still there
    if (not edict_p(trace.ent)^.inuse) and (ent^.inuse) then
    begin
      //move the pusher back and try again
      VectorCopy(start, ent^.s.origin);
      gi.linkentity(ent);
      goto retry;
    end;
  end;

  if ent^.inuse then
    G_TouchTriggers(ent);

  result := trace;
end;

{delphi-note: converted the C pushed_p variable to _pushed_p since}
{pushed_p is the typed pointer of a record}
type
  pushed_t = packed record
    ent: edict_p;
    origin, angles: vec3_t;
    deltayaw: single;
  end;
  pushed_p = ^pushed_t;

var
  pushed: array[0..MAX_EDICTS -1] of pushed_t;
  _pushed_p: pushed_p;
  obstacle: edict_p;

{/*
============
SV_Push

Objects need to be moved back on a failed push,
otherwise riders would continue to slide.
============
*/}
function SV_Push(pusher: edict_p; var move_, amove: vec3_t): qboolean;
var
  i, e: Integer;
  check, block: edict_p;
  mins, maxs: vec3_t;
  p: pushed_p;
  org, org2, move2, forward_, right, up: vec3_t;
  temp: Single;
begin
  // clamp the move to 1/8 units, so the position will
  // be accurate for client side prediction
  for i := 0 to 2 do
  begin
    temp := move_[i] * 8.0;
    if (temp > 0.0) then
      temp := temp + 0.5
    else
      temp := temp - 0.5;

    move_[i] := 0.125 * Trunc(temp);
  end;

  // find the bounding box
  for i := 0 to 2 do
  begin
    mins[i] := pusher^.absmin[i] + move_[i];
    maxs[i] := pusher^.absmax[i] + move_[i];
  end;

// we need this for pushing things later
  VectorSubtract(vec3_origin, amove, org);
  AngleVectors(org, @forward_, @right, @up);

// save the pusher's original position
  _pushed_p^.ent := pusher;
  VectorCopy(pusher^.s.origin, _pushed_p^.origin);
  VectorCopy(pusher^.s.angles, _pushed_p^.angles);
  if (pusher^.client <> Nil) then
          _pushed_p^.deltayaw := pusher^.client^.ps.pmove.delta_angles[YAW];

  Inc(_pushed_p);

// move the pusher to it's final position
  VectorAdd(pusher^.s.origin, move_, pusher^.s.origin);
  VectorAdd(pusher^.s.angles, amove, pusher^.s.angles);
  gi.linkentity(pusher);

// see if any solid entities are inside the final position
  check :=  @g_edicts[1];
  for e := 1 to (globals.num_edicts - 1) do
  begin
    try
      if (not check^.inuse) then
        Continue;
      if (check^.movetype = MOVETYPE_PUSH)
      OR (check^.movetype = MOVETYPE_STOP)
      OR (check^.movetype = MOVETYPE_NONE)
      OR (check^.movetype = MOVETYPE_NOCLIP) then
        Continue;

      if (check^.area.prev = nil) then
        Continue;      // not linked in anywhere

  // if the entity is standing on the pusher, it will definitely be moved
      if (check^.groundentity <> pusher) then
      begin
        // see if the ent needs to be tested
        if (check^.absmin[0] >= maxs[0])
        OR (check^.absmin[1] >= maxs[1])
        OR (check^.absmin[2] >= maxs[2])
        OR (check^.absmax[0] <= mins[0])
        OR (check^.absmax[1] <= mins[1])
        OR (check^.absmax[2] <= mins[2]) then
          Continue;

        // see if the ent's bbox is inside the pusher's final position
        if (SV_TestEntityPosition(check) = nil) then
          Continue;
      end;

      if ((pusher^.movetype = MOVETYPE_PUSH) OR (check^.groundentity = pusher)) then
      begin
        // move this entity
        _pushed_p^.ent := check;
        VectorCopy(check^.s.origin, _pushed_p^.origin);
        VectorCopy(check^.s.angles, _pushed_p^.angles);
        Inc(_pushed_p);

        // try moving the contacted entity
        VectorAdd(check^.s.origin, move_, check^.s.origin);
        if (check^.client <> nil) then
        begin   // FIXME: doesn't rotate monsters?
          check^.client^.ps.pmove.delta_angles[YAW] := check^.client^.ps.pmove.delta_angles[YAW] + trunc(amove[YAW]);
        end;

        // figure movement due to the pusher's amove
        VectorSubtract(check^.s.origin, pusher^.s.origin, org);
        org2[0] := DotProduct(org, forward_);
        org2[1] := -DotProduct(org, right);
        org2[2] := DotProduct(org, up);
        VectorSubtract(org2, org, move2);
        VectorAdd(check^.s.origin, move2, check^.s.origin);

        // may have pushed them off an edge
        if (check^.groundentity <> pusher) then
          check^.groundentity := nil;

        block := SV_TestEntityPosition(check);
        if (block = nil) then
        begin   // pushed ok
          gi.linkentity(check);
          // impact?
          Continue;
        end;

        // if it is ok to leave in the old position, do it
        // this is only relevent for riding entities, not pushed
        // FIXME: this doesn't acount for rotation
        VectorSubtract(check^.s.origin, move_, check^.s.origin);
        block := SV_TestEntityPosition(check);
        if (block = nil) then
        begin
          Dec(_pushed_p);
          Continue;
        end;
      end;

      // save off the obstacle so we can call the block function
      obstacle := check;

      // move back any entities we already moved
      // go backwards, so if the same entity was pushed
      // twice, it goes back to the original position
      p := Pointer(Cardinal(_pushed_p) - 1 * SizeOf(pushed_t));
      while (Cardinal(p) >= Cardinal(@pushed)) do
      begin
          VectorCopy(p^.origin, p^.ent^.s.origin);
          VectorCopy(p^.angles, p^.ent^.s.angles);
          if (p^.ent^.client <> nil) then
          begin
            p^.ent^.client^.ps.pmove.delta_angles[YAW] := trunc(p^.deltayaw);
          end;
          gi.linkentity(p^.ent);

          p := Pointer(Cardinal(p) - 1 * SizeOf(pushed_t));
      end;
      Result := False;
      Exit;
    finally
      { All Expression Two items get evaluated at the End of any loop }
      Inc(check);
      { Inc(e)  <-- Shouldnt' be needed as should already be incremented }
    end;
  end;

//FIXME: is there a better way to handle this?
  // see if anything we moved has touched a trigger
  p := Pointer(Cardinal(_pushed_p) - 1 * SizeOf(pushed_t));
  while (Cardinal(p) >= Cardinal(@pushed)) do
  begin
      G_TouchTriggers(p^.ent);
      p := Pointer(Cardinal(p) - 1 * SizeOf(pushed_t));
  end;

  Result := True;
end;

{/*
================
SV_Physics_Pusher

Bmodel objects don't interact with each other, but
push all box objects
================
*/}
procedure SV_Physics_Pusher(ent: edict_p);
var
  move_, amove: vec3_t;
  part, mv: edict_p;
begin
  // if not a team captain, so movement will be handled elsewhere
  if (ent^.flags AND FL_TEAMSLAVE) <> 0 then
    Exit;

  // make sure all team slaves can move before commiting
  // any moves or calling any think functions
  // if the move is blocked, all moved objects will be backed out
//retry:
  _pushed_p := @pushed[0];

  { ORIGINAL LINE:  for (part = ent ; part ; part=part->teamchain) }
  { NOTE(SP):  While (part <> nil) might be better - but logic similar in either case.
     - Whilst originally implemented with a repeat until and using a try..finally block
       to ensure the next pointer assignment occered, this also inadvertently moved the
       pointer forwards, even in the case of the call to Brea.  As such, changed the
       approach to use a while loop, and removed the try..finally for performance. }
  part := ent;
  while (part <> nil) do
  begin
    if (part^.velocity[0] <> 0) OR (part^.velocity[1] <> 0) OR (part^.velocity[2] <> 0) OR
    (part^.avelocity[0] <> 0) OR (part^.avelocity[1] <> 0) OR (part^.avelocity[2] <> 0) then
    begin   // object is moving
      VectorScale(part^.velocity, FRAMETIME, move_);
      VectorScale(part^.avelocity, FRAMETIME, amove);

      if (NOT SV_Push(part, move_, amove)) then
        Break;   // move was blocked
    end;
    part := part^.teamchain;
  end;

  if (Cardinal(_pushed_p) > Cardinal(@pushed[MAX_EDICTS - 1])) then //was pushed[MAX_EDICTS]
    gi.error({ERR_FATAL,} '_pushed_p > @pushed[MAX_EDICTS], memory corrupted');

  if (part <> nil) then
  begin
    // the move failed, bump all nextthink times and back out moves
    mv := ent;
    while (mv <> nil) do
    begin
      if (mv^.nextthink > 0) then
        mv^.nextthink := mv^.nextthink + FRAMETIME;
      mv := mv^.teamchain;
    end;

    // if the pusher has a "blocked" function, call it
    // otherwise, just stay in place until the obstacle is gone
    if (@part^.blocked <> nil) then
      part^.blocked(part, obstacle);
(*{$ifdef 0}
    // if the pushed entity went away and the pusher is still there
    if (NOT obstacle^.inuse) AND part^.inuse) then
      goto retry;
{$endif}*)
  end
  else
  begin
    // the move succeeded, so call all think functions
    part := ent;
    while (part <> nil) do
    begin
      SV_RunThink(part);
      part := part^.teamchain
    end;
  end;
end;

//==================================================================
{/*
=============
SV_Physics_None

Non moving objects can only think
=============
*/}
procedure SV_Physics_None(ent: edict_p);
begin
  // regular thinking
  SV_RunThink(ent);
end;

{/*
=============
SV_Physics_Noclip

A moving object that doesn't obey physics
=============
*/}
procedure SV_Physics_Noclip(ent: edict_p);
begin
  // regular thinking
  if not SV_RunThink(ent) then
    Exit;

  VectorMA(ent^.s.angles, FRAMETIME, ent^.avelocity, ent^.s.angles);
  VectorMA(ent^.s.origin, FRAMETIME, ent^.velocity, ent^.s.origin);

  gi.linkentity(ent);
end;

{/*
==============================================================================

TOSS / BOUNCE

==============================================================================
*/}

{/*
=============
SV_Physics_Toss

Toss, bounce, and fly movement.  When onground, do nothing.
=============
*/}
procedure SV_Physics_Toss(ent: edict_p);
var
  trace: trace_t;
  move_: vec3_t;
  backoff: single;
  slave: edict_p;
  wasinwater, isinwater: qboolean;
  old_origin: vec3_t;
begin
  // regular thinking
  SV_RunThink(ent);

  // if not a team captain, so movement will be handled elsewhere
  if (ent^.flags and FL_TEAMSLAVE) <> 0 then
    Exit;

  if (ent^.velocity[2] > 0) then
    ent^.groundentity := nil;

  // check for the groundentity going away
  if (ent^.groundentity <> nil) then
    if not ent^.groundentity^.inuse then
      ent^.groundentity := nil;

  // if onground, return without moving
  if (ent^.groundentity <> nil) then
    Exit;

  VectorCopy(ent^.s.origin, old_origin);

  SV_CheckVelocity(ent);

  // add gravity
  if (ent^.movetype <> MOVETYPE_FLY) and (ent^.movetype <> MOVETYPE_FLYMISSILE) then
    SV_AddGravity(ent);

  // move angles
  VectorMA(ent^.s.angles, FRAMETIME, ent^.avelocity, ent^.s.angles);

  // move origin
  VectorScale(ent^.velocity, FRAMETIME, move_);
  trace := SV_PushEntity(ent, move_);
  if not ent^.inuse then
    Exit;

  if (trace.fraction < 1) then
  begin
    if (ent^.movetype = MOVETYPE_BOUNCE) then
      backoff := 1.5
    else
      backoff := 1;

    ClipVelocity(ent^.velocity, trace.plane.normal, ent^.velocity, backoff);

    // stop if on ground
    if (trace.plane.normal[2] > 0.7) then
    begin
      if (ent^.velocity[2] < 60) or (ent^.movetype <> MOVETYPE_BOUNCE) then
      begin
        ent^.groundentity := trace.ent;
        ent^.groundentity_linkcount := edict_p(trace.ent)^.linkcount;
        VectorCopy(vec3_origin, ent^.velocity);
        VectorCopy(vec3_origin, ent^.avelocity);
      end;
    end;

    { The following was originally commented out, but converted still :) }
    //if (ent^.touch <> nil) then
    //  ent^.touch(ent, trace.ent, @trace.plane, trace.surface);
  end;

  //check for water transition
  wasinwater := (ent^.watertype and MASK_WATER) <> 0;
  ent^.watertype := gi.pointcontents(ent^.s.origin);
  isinwater := ent^.watertype and MASK_WATER <> 0;

  if (isinwater) then
    ent^.waterlevel := 1
  else
    ent^.waterlevel := 0;

  if (not wasinwater) and isinwater then
    gi.positioned_sound(@old_origin, @g_edicts[0], CHAN_AUTO, gi.soundindex('misc/h2ohit1.wav'), 1, 1, 0)
  else if wasinwater and (not isinwater) then
    gi.positioned_sound(@ent^.s.origin, @g_edicts[0], CHAN_AUTO, gi.soundindex('misc/h2ohit1.wav'), 1, 1, 0);

  //move teamslaves
  {for (slave = ent->teamchain; slave; slave = slave->teamchain)}
  { Or replace with while (slave <> nil) do loop }
  slave := ent^.teamchain;
  while (slave <> nil) do
  begin
    VectorCopy(ent^.s.origin, slave^.s.origin);
    gi.linkentity(slave);
    slave := slave^.teamchain;
  end;
end;

{/*
===============================================================================

STEPPING MOVEMENT

===============================================================================
*/}

{/*
=============
SV_Physics_Step

Monsters freefall when they don't have a ground entity, otherwise
all movement is done with discrete steps.

This is also used for objects that have become still on the ground, but
will fall if the floor is pulled out from under them.
FIXME: is this true?
=============
*/}

//FIXME: hacked in for E3 demo
const
  sv_stopspeed = 100;
  sv_friction = 6;
  sv_waterfriction = 1;

procedure SV_AddRotationalFriction(ent: edict_p);
var
  n: integer;
  adjustment: single;
begin
  VectorMA(ent^.s.angles, FRAMETIME, ent^.avelocity, ent^.s.angles);
  adjustment := FRAMETIME * sv_stopspeed * sv_friction;

  for n := 0 to 2 do
  begin
    if (ent^.avelocity[n] > 0) then
    begin
      ent^.avelocity[n] := ent^.avelocity[n] - adjustment;
      if (ent^.avelocity[n] < 0) then
        ent^.avelocity[n] := 0;
    end
    else
    begin
      ent^.avelocity[n] := ent^.avelocity[n] + adjustment;
      if (ent^.avelocity[n] > 0) then
        ent^.avelocity[n] := 0;
    end;
  end;
end;

procedure SV_Physics_Step(ent: edict_p);
var
  wasonground, hitsound: qboolean;
  vel: vec3_p;
  speed, newspeed, control, friction: Single;
  groundentity: edict_p;
  mask: Integer;
begin
  hitsound := False;

  // airborn monsters should always check for ground
  if (ent^.groundentity = nil) then
    M_CheckGround(ent);

  groundentity := ent^.groundentity;

  SV_CheckVelocity(ent);

  if (groundentity <> nil) then
    wasonground := True
  else
    wasonground := False;

  if (ent^.avelocity[0] <> 0) OR (ent^.avelocity[1] <> 0) OR (ent^.avelocity[2] <> 0) then
    SV_AddRotationalFriction(ent);

  // add gravity except:
  //   flying monsters
  //   swimming monsters who are in the water
  if (NOT wasonground) then
    if ((ent^.flags AND FL_FLY) = 0) then
      if NOT (((ent^.flags AND FL_SWIM) <> 0) AND (ent^.waterlevel > 2)) then
      begin
        if (ent^.velocity[2] < (sv_gravity^.value * -0.1)) then
          hitsound := True;
        if (ent^.waterlevel = 0) then
          SV_AddGravity(ent);
      end;

  // friction for flying monsters that have been given vertical velocity
  if ((ent^.flags AND FL_FLY) <> 0) AND (ent^.velocity[2] <> 0) then
  begin
    speed := fabs(ent^.velocity[2]);
    if (speed < sv_stopspeed) then
      control := sv_stopspeed
    else
      control := speed;

    friction := (sv_friction / 3);
    newspeed := speed - (FRAMETIME * control * friction);
    if (newspeed < 0) then
      newspeed := 0;
    newspeed := newspeed / speed;
    ent^.velocity[2] := ent^.velocity[2] * newspeed;
  end;

  // friction for flying monsters that have been given vertical velocity
  if ((ent^.flags AND FL_SWIM) <> 0) AND (ent^.velocity[2] <> 0) then
  begin
    speed := fabs(ent^.velocity[2]);
    if (speed < sv_stopspeed) then
      control := sv_stopspeed
    else
      control := speed;
    newspeed := speed - (FRAMETIME * control * sv_waterfriction * ent^.waterlevel);
    if (newspeed < 0) then
      newspeed := 0;
    newspeed := newspeed / speed;
    ent^.velocity[2] := ent^.velocity[2] * newspeed;
  end;

  if (ent^.velocity[2] <> 0) OR (ent^.velocity[1] <> 0) OR (ent^.velocity[0] <> 0) then
  begin
    // apply friction
    // let dead monsters who aren't completely onground slide
    if (wasonground) OR ((ent^.flags AND (FL_SWIM OR FL_FLY)) <> 0) then
      if NOT ((ent^.health <= 0.0) AND (NOT M_CheckBottom(ent))) then
      begin
        vel := @ent^.velocity;
        speed := sqrt(vel[0] * vel[0] + vel[1] * vel[1]);
        if (speed <> 0) then
        begin
          friction := sv_friction;

          if (speed < sv_stopspeed) then
            control := sv_stopspeed
          else
            control := speed;
          newspeed := speed - FRAMETIME * control * friction;

          if (newspeed < 0) then
            newspeed := 0;
          newspeed := newspeed / speed;

          vel[0] := vel[0] * newspeed;
          vel[1] := vel[1] * newspeed;
        end;
      end;

    if (ent^.svflags AND SVF_MONSTER) <> 0 then
      mask := MASK_MONSTERSOLID
    else
      mask := MASK_SOLID;
    SV_FlyMove(ent, FRAMETIME, mask);

    gi.linkentity(ent);
    G_TouchTriggers(ent);
    if (NOT ent^.inuse) then
      Exit;

    if (ent^.groundentity <> nil) then
      if (NOT wasonground) then
        if (hitsound) then
          gi.sound(ent, 0, gi.soundindex('world/land.wav'), 1, 1, 0);
  end;

// regular thinking
  SV_RunThink(ent);
end;

//============================================================================
{/*
================
G_RunEntity

================
*/}
procedure G_RunEntity(ent: edict_p);
begin
  if (@ent^.prethink <> nil) then
    ent^.prethink(ent);

  case Integer(ent^.movetype) of
    Ord(MOVETYPE_PUSH),
    Ord(MOVETYPE_STOP):
    begin
      SV_Physics_Pusher(ent);
      //break;
    end;
    Ord(MOVETYPE_NONE):
    begin
      SV_Physics_None(ent);
      //break;
    end;
    Ord(MOVETYPE_NOCLIP):
    begin
      SV_Physics_Noclip(ent);
      //break;
    end;
    Ord(MOVETYPE_STEP):
    begin
      SV_Physics_Step(ent);
      //break;
    end;
    Ord(MOVETYPE_TOSS),
    Ord(MOVETYPE_BOUNCE),
    Ord(MOVETYPE_FLY),
    Ord(MOVETYPE_FLYMISSILE):
    begin
      SV_Physics_Toss(ent);
      //break;
    end;
  else
    gi.error('SV_Physics: bad movetype %i', Integer(ent^.movetype));
  end;
end;

end.
