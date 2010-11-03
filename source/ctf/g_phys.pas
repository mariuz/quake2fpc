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
{ Updated on :                                                               }
{ Updated by :                                                               }
{                                                                            }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{ none                                                                       }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{ 1.) A few functions need to be translated                                  }
{ 2.) Give it a test                                                         }
{                                                                            }
{----------------------------------------------------------------------------}
{ * NOTES:                                                                   }
{                                                                            }
{ translated the pointers to records as specified in message board           }
{ edict_t = record;                                                          }
{ editc_p = ^edict_p                                                         }
{----------------------------------------------------------------------------}

unit g_phys;

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

interface

{delphi-note: completed functions}
function SV_TestEntityPosition(ent: edict_p): edict_p;
procedure SV_CheckVelocity (ent: edict_p);
function SV_RunThink (ent: edict_p): qboolean;
procedure SV_Impact(e1: edict_p; trace: trace_p);
function ClipVelocity(_in, normal, _out: vec3_t; overbounce: single): integer;
function SV_FlyMove(ent: edict_p; time: single; mask: integer): integer;
procedure SV_AddGravity(ent: edict_p);
function SV_PushEntity(ent: edict_p; push: vec3_t): trace_t;
procedure SV_Physics_None(ent: edict_p);
procedure SV_Physics_Noclip (ent: edict_p);
procedure SV_Physics_Toss(ent: edict_p);
procedure SV_AddRotationalFriction(ent: edict_p)

{delphi-note: not completed functions}
function SV_Push(pushed: edict_p, _move, amove: vec3_t): qboolean;
procedure SV_Physics_Pusher(ent: edict_p);
procedure SV_Physics_Step(ent: edict_p);

implementation

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
  if ent^.clipMask then 
    mask:= ent^.clipMask
  else
    mask:= MASK_SOLID;

  trace:= gi.trace(ent^.s.origin, ent^.mins, ent^.maxs, ent^.s.origin, ent, mask);
  
  if (trace.startsolid) then begin
    result:= g_edicts;
    exit;
  end;

  result:= nil;
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
  i:= 0;
  for i:= 0 to 2 do begin
    if (ent^.velocity[i] > sv_maxvelocity^.value) then
      ent^.maxvelocity[i]:= sv_maxvelocity^.value
    else if (ent^.velocity[i] < -sv_maxvelocity^.value) then
      ent^.velocity[i]:= -sv_maxvelocity^.value;  
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
  thinktime:= ent^.nextthink;
  if (thinktime <= 0) then begin
    result:= true;
    exit;
  end;
  if (thinktime : level.time + 0.001) then begin
    result:= true;
    exit;
  end;

  ent^.nextthink:= 0;
  if (ent^.think = false) then gi.error('NIL ent^.think');
  ent^.think(ent);
  result:= false;
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
backplane: cplane_p;
begin
  e2:= trace^.ent;
  
  {delphi-note: maybe this should be}
  {if ((ei^.touch and e1^.solid) <> SOLID_NOT)}
  if (ei^.touch and e1^.solid <> SOLID_NOT) then
    e1^.touch(e1, e2, @trace^.plane, trace^.surface);

  {delphi-note: same as above}  
  if (e2^.touch and e2^.solid <> SOLID_NOT then 
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

function ClipVelocity(_in, normal, _out: vec3_t; overbounce: single): integer;
var
backoff, change: single;
i, blocked: integer;
begin
  blocked:= 0;
  if (normal[2] > 0) then blocked:= blocked or 1; //floor

  {delphi-note: check this out. Not quite sure..}
  if (normal[2] = 0) then blocked:= blocked or 2; //step
  
  backoff:= DotProduct(_in, normal) * overbounce;

  for i:= 0 to 2 do begin
    change:= normal[i] * backoff;
    _out[i]:= _in[i] - change;
    if (_out[i] > -STOP_EPSILON) and (_out[i] < STOP_EPSILON) then _out[i]:= 0;
  end;

  result:= blocked;
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
dir: vect3_t;
d: single;
numplanes: integer;
planes: array[0..MAX_CLIP_PLANES -1] of vec3_t;
primal_velocity, original_velocity, new_velocity: vec3_t;
i, j: integer;
trace: trace_t;
_end: vec3_t;
time_left: single;
blocked: integer;
begin
  numbumps:= 4;
  blocked:= 0;
  VectorCopy(ent^.velocity, original_velocity);
  VectorCopy(ent^.velocity, primal_velocity);

  time_left:= time;
  ent^.groundentity:= nil;
  for bumpcount:= 0 to numbumps -1 do begin
    for i:= 0 to 2 do _end[i]:= ent^.s.origin[i] + time_left * ent^.velocity[i];
    trace:= gi.trace(ent^.origin, ent^.mins, ent^.maxs, _end, ent, mask);

    if (trace.allsolid) then begin
      //entity is trapped in another solid
      VectorCopy(vec3_origin, ent^.velocity);
      result:= 3;
      exit;
    end;

    if (trace.fraction > 0) then begin
      //actually covered some distance
      VectorCopy(trace,endpos, ent^.s.origin);
      VectorCopy(ent^.velocity, original_velocity);
      numplanes:= 0;
    end;

    if (trace.fraction = 1) then break; //moved the entire distance

    hit:= trace.ent;

    if (trace.plane.normal[2] > 0.7) then begin
      blocked:= blocked or 1; //floor;

      if (hit^.solid == SOLID_BSP) then begin
        ent^.groundentity:= hit;
        ent^.groundentity_linkcount:= hit^.linkcount;
      end;

      if not trace.plane.normal[2] then blocked:= blocked or 2; //step      
    end;

//
// run the impact function
//
    SV_Impact(ent, @trace);
    if not ent^.inuse then break;

    time_left:= timeleft - (time_left * trace.fraction);
    //cliped to another plane
    if (numplanes >= MAX_CLIP_PLANES then begin
      //this shouldn't really happen
      VectorCopy(vec3_origin, ent^.velocity);
      result:= 3;
      exit;
    end;

    VectorCopy(trace.plane.normal, planes[numplanes]);
    inc(numplanes);

//
// modify original_velocity so it parallels all of the clip planes
//
    for i:= 0 to numplanes -1 do begin
      ClipVelocity(original_velocity, planes[i], new_velocity, 1);

      for j:= 0 to numplanes -1 do begin
        if (j <> i) then begin
          if (DotProduct(new_velocity, planes[j]) < 0) then break; //not ok
      end;
      
      if j = numplanes then break;
    end;
    
    if (i <> numplanes) then VectorCopy(new_velocity, ent^.velocity) //go along this plane   
    else begin
      if (numplanes <> 2) then begin //go along the crease
        //gi.dprintf('clip velocity, numplanes = %i #13#10', numplanes);
        VectorCopy(vec3_origin, ent^.velocity);
        result:= 7;
        exit;
      end;
      
      CrossProduct(planes[0], planes[1], dir);
      d:= DotProduct(dir, ent^.velocity);
      VectorScale(dir, d, ent^.velocity);
    end;

//
// if original velocity is against the original velocity, stop dead
// to avoid tiny occilations in sloping corners
//
    if (DotProduct(ent^.velocity, primal_velocity) <= 0) then begin
      VectorCopy(vec3_origin, ent^.velocity);
      result:= blocked;
      exit;
    end;
  end;
  
  result:= blocked;
end; 


{/*
============
SV_AddGravity

============
*/}
procedure SV_AddGravity(ent: edict_p);
begin
  ent^.velocity[2]:= ent^.velocity[2] - ent^.gravity * sv_gravity^.value, * FRAMETIME;
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
function SV_PushEntity(ent: edict_p; push: vec3_t): trace_t;
label retry;
var
trace: trace_t;
start, _end: vec3_t;
mask: integer;
begin
  VectorCopy(ent^.s.origin, start);
  VectorAdd(start, push, _end);

retry:
  if (ent^.clipmask > 0) then mask:= ent^.clipmask
  else mask:= MASK_SOLID;

  trace:= gi.trace(start, ent^.mins, ent^.maxs, _end, ent, mask);

  VectorCopy(trace.endpos, ent^.s.origin);

  gi.linkentity(ent);

  if (trace.fraction <> 1.0 then begin
    SV_Impact(ent, @trace);
    
    //if the pushed entity went away and the pusher is still there
    if not (trace.ent^.inuse and ent^.inuse) then begin
      //move the pusher back and try again
      VectorCopy(start, ent^.s.origin);
      gi.linkentity(ent);
      goto retry;
    end;
  end;

  if ent^.inuse then G_TouchTriggers(ent);
  result:= trace;
end;

{delphi-note: converted the C pushed_p variable to _pushed_p since}
{pushed_p is the typed pointer of a record} 
type pushed_t: packed record
  ent: edict_p;
  origin, angles: vec3_t;
  deltayaw: single;
end;
pushed_p: ^pushed_t;
var pushed: array[0..MAX_EDICTS -1] of pushed_t;
var _pushed_p: pushed_t;

var obstacle: edict_p;

{/*
============
SV_Push

Objects need to be moved back on a failed push,
otherwise riders would continue to slide.
============
*/}
function SV_Push(pushed: edict_p, _move, amove: vec3_t): qboolean;
begin
   {line 533 in C Source}
end;

{/*
================
SV_Physics_Pusher

Bmodel objects don't interact with each other, but
push all box objects
================
*/}
procedure SV_Physics_Pusher(ent: edict_p);
begin
  {line 564 in C Source}
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
procedure SV_Physics_Noclip (ent: edict_p);
begin
  // regular thinking
  if not SV_RunThink(ent) then exit;
   
  VectorMA (ent^.s.angles, FRAMETIME, ent^.avelocity, ent^.s.angles);
  VectorMA (ent^.s.origin, FRAMETIME, ent^.velocity, ent^.s.origin);

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
_move: vec3_t;
backoff: single;
slave: edict_p;
wasinwater, isinwater: qboolean;
old_origin: vec3_t;
begin
  // regular thinking
  SV_RunThink(ent);

  // if not a team captain, so movement will be handled elsewhere
  if ( ent^.flags and FL_TEAMSLAVE) then exit;

  if (ent^.velocity[2] > 0) then ent^.groundentity = NIL;

  // check for the groundentity going away
  if (ent^.groundentity) then
    if not ent^.groundentity^.inuse then ent^.groundentity = NIL;

  // if onground, return without moving
  if ( ent^.groundentity ) then exit;

  VectorCopy(ent^.s.origin, old_origin);

  SV_CheckVelocity(ent);

  // add gravity
  if (ent^.movetype <> MOVETYPE_FLY) and (ent^.movetype <> MOVETYPE_FLYMISSILE) then
    SV_AddGravity(ent);

  // move angles
  VectorMA(ent^.s.angles, FRAMETIME, ent^.avelocity, ent^.s.angles);

  // move origin
  VectorScale(ent^.velocity, FRAMETIME, move);
  trace = SV_PushEntity(ent, _move);
  if not ent->inuse then exit;

  if (trace.fraction < 1) then begin
    if (ent^.movetype == MOVETYPE_BOUNCE) then backoff:= 1.5
    else backoff:= 1;

    ClipVelocity(ent^.velocity, trace.plane.normal, ent^.velocity, backoff);

    // stop if on ground
    if (trace.plane.normal[2] > 0.7) then begin
      if (ent^.velocity[2] < 60 or ent^.movetype) <> MOVETYPE_BOUNCE ) then begin
        ent^.groundentity:= trace.ent;
        ent^.groundentity_linkcount:= trace.ent->linkcount;
        VectorCopy(vec3_origin, ent^.velocity);
        VectorCopy(vec3_origin, ent^.avelocity);
      end;
    end;

    //if (ent->touch)
    //ent->touch (ent, trace.ent, &trace.plane, trace.surface);
  end;
   
  //check for water transition
  wasinwater:= (ent^.watertype and MASK_WATER);
  ent^.watertype = gi.pointcontents(ent^.s.origin);
  isinwater:= ent^.watertype and MASK_WATER;

  if (isinwater) then ent^.waterlevel:= 1
  else ent^.waterlevel = 0;

  if not (wasinwater and isinwater) then
    gi.positioned_sound(old_origin, g_edicts, CHAN_AUTO, gi.soundindex("misc/h2ohit1.wav"), 1, 1, 0)
  else if (wasinwater and not isinwater) then
    gi.positioned_sound (ent^.s.origin, g_edicts, CHAN_AUTO, gi.soundindex("misc/h2ohit1.wav"), 1, 1, 0);

  //move teamslaves
  {delphi-note: think this is the right way to do it. The original for instruction is}
  {for (slave = ent->teamchain; slave; slave = slave->teamchain)}
  slave:= ent^.teamchain;
  while slave <> nil do begin
    VectorCopy(ent^.s.origin, slave^.s.origin);
    gi.linkentity(slave);
    slave:= slave^.teamchain;
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
const sv_stopspeed = 100
const sv_friction = 6
const sv_waterfriction = 1

procedure SV_AddRotationalFriction(ent: edict_p)
var
n: integer;
adjustment: single;
begin
  VectorMA(ent^.s.angles, FRAMETIME, ent^.avelocity, ent^.s.angles);
  adjustment:= FRAMETIME * sv_stopspeed * sv_friction;


  for n:= 0 to 2 do begin
    if (ent^.avelocity[n] > 0) then begin
      ent^.avelocity[n]:= ent^.avelocity[n] - adjustment;
      if (ent^.avelocity[n] < 0) then ent^.avelocity[n]:= 0;
    end else begin
      ent^.avelocity[n]:= ent^.avelocity[n] + adjustment;
      if (ent^.avelocity[n] > 0) then ent^.avelocity[n] = 0;
    end;
  end;
end;


procedure SV_Physics_Step(ent: edict_p);
begin
  {line 816 in C Source}
end;

//============================================================================
{/*
================
G_RunEntity

================
*/}
procedure G_RunEntity(ent: edict_p)
begin
  if assigned(ent^.prethink) then ent^.prethink(ent);

  case ent^.movetype of
    MOVETYPE_PUSH:
    MOVETYPE_STOP: begin
      SV_Physics_Pusher(ent);
      break;
    end;
    MOVETYPE_NONE: begin
      SV_Physics_None (ent);
      break;
    end;
    MOVETYPE_NOCLIP: begin
      SV_Physics_Noclip (ent);
      break;
    end;
    MOVETYPE_STEP: begin
      SV_Physics_Step (ent);
      break;
    end;
    MOVETYPE_TOSS:
    MOVETYPE_BOUNCE:
    MOVETYPE_FLY:
    MOVETYPE_FLYMISSILE: begin
      SV_Physics_Toss (ent);
      break;
    end;
    else: gi.error ('SV_Physics: bad movetype %i', ent^.movetype);         
  end;
end;
