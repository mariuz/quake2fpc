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
{ File(s): g_func.pas                                                        }
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

unit g_func;

interface

uses g_local,SysUtils;

type pedict_t  = ^edict_t;
     pcplane_t = ^cplane_t;
     pcsurface_t = ^csurface_t;
     pmoveinfo = ^moveinfo;
     qboolean  = boolean;

(*
=========================================================

  PLATS

  movement options:

  linear
  smooth start, hard stop
  smooth start, smooth stop

  start
  end
  acceleration
  speed
  deceleration
  begin sound
  end sound
  target fired when reaching end
  wait at end

  object characteristics that use move segments
  ---------------------------------------------
  movetype_push, or movetype_stop
  action when touched
  action when blocked
  action when used
  disabled?
  auto trigger spawning


=========================================================
*)

const  PLAT_LOW_TRIGGER = 1;
  
    STATE_TOP    = 0;
    STATE_BOTTOM = 1;
    STATE_UP     = 2;
    STATE_DOWN   = 3;

    DOOR_START_OPEN =  1;
    DOOR_REVERSE    =  2;
    DOOR_CRUSHER    =  4;
    DOOR_NOMONSTER  =  8;
    DOOR_TOGGLE     = 32;
    DOOR_X_AXIS     = 64;
    DOOR_Y_AXIS     =128;

procedure Think_AccelMove (ent:pedict_t);

procedure plat_go_down (ent:pedict_t);

procedure door_go_down (self:pedict_t);

procedure train_next (self:pedict_t);

procedure door_secret_move1 (self:pedict_t);
procedure door_secret_move2 (self:pedict_t);
procedure door_secret_move3 (self:pedict_t);
procedure door_secret_move4 (self:pedict_t);
procedure door_secret_move5 (self:pedict_t);
procedure door_secret_move6 (self:pedict_t);
procedure door_secret_done (self:pedict_t);

implementation
//
// Support routines for movement (changes in origin using velocity)
//

procedure Move_Done (ent:pedict_t);
begin
  VectorClear (ent^.velocity);
  ent^.moveinfo.endfunc (ent);
end;

procedure Move_Final (ent:pedict_t);
begin
  if (ent^.moveinfo.remaining_distance = 0) then
  begin
    Move_Done (ent);
    exit;
  end;

  VectorScale (ent^.moveinfo.dir, ent^.moveinfo.remaining_distance / FRAMETIME, ent^.velocity);

  ent^.think := Move_Done;
  ent^.nextthink := level.time + FRAMETIME;
end;

procedure Move_Begin (ent:pedict_t);
var
  frames:single;
begin
  if ((ent^.moveinfo.speed * FRAMETIME) >= ent^.moveinfo.remaining_distance) then
  begin
    Move_Final (ent);
    exit;
  end;
  VectorScale (ent^.moveinfo.dir, ent^.moveinfo.speed, ent^.velocity);
  frames := floor((ent^.moveinfo.remaining_distance / ent^.moveinfo.speed) / FRAMETIME);
  ent^.moveinfo.remaining_distance -:= frames * ent^.moveinfo.speed * FRAMETIME;
  ent^.nextthink := level.time + (frames * FRAMETIME);
  ent^.think := Move_Final;
end;



procedure Move_Calc (ent:pedict_t, vec3_t dest, procedure(*func)(edict_t**));
begin
  VectorClear (ent^.velocity);
  VectorSubtract (dest, ent^.s.origin, ent^.moveinfo.dir);
  ent^.moveinfo.remaining_distance := VectorNormalize (ent^.moveinfo.dir);
  ent^.moveinfo.endfunc := func;

  if (ent^.moveinfo.speed = ent^.moveinfo.accel andand ent^.moveinfo.speed = ent^.moveinfo.decel) then
  begin
    if (level.current_entity  = (if (ent^.flags and FL_TEAMSLAVE)=1 then ent^.teammaster else ent)) then
    begin
      Move_Begin (ent);
    end
    else
    begin
      ent^.nextthink := level.time + FRAMETIME;
      ent^.think := Move_Begin;
    end;
  end
  else
  begin
    // accelerative
    ent^.moveinfo.current_speed := 0;
    ent^.think := Think_AccelMove;
    ent^.nextthink := level.time + FRAMETIME;
  end;
end;


//
// Support routines for angular movement (changes in angle using avelocity)
//

procedure AngleMove_Done (ent:pedict_t);
begin
  VectorClear (ent^.avelocity);
  ent^.moveinfo.endfunc (ent);
end;

procedure AngleMove_Final (ent:pedict_t);
var
  move:vec3_t;
begin
  if (ent^.moveinfo.state = STATE_UP) then
    VectorSubtract (ent^.moveinfo.end_angles, ent^.s.angles, move)
  else
    VectorSubtract (ent^.moveinfo.start_angles, ent^.s.angles, move);

  if (VectorCompare (move, vec3_origin)) then
  begin
    AngleMove_Done (ent);
    exit;
  end;

  VectorScale (move, 1.0/FRAMETIME, ent^.avelocity);

  ent^.think := AngleMove_Done;
  ent^.nextthink := level.time + FRAMETIME;
end;

procedure AngleMove_Begin (ent:pedict_t);
var
  destdelta:vec3_t;
  len:single;
  traveltime:single;
  frames:single;
begin
  // set destdelta to the vector needed to move
  if (ent^.moveinfo.state = STATE_UP) then
    VectorSubtract (ent^.moveinfo.end_angles, ent^.s.angles, destdelta) 
  else
    VectorSubtract (ent^.moveinfo.start_angles, ent^.s.angles, destdelta);
  
  // calculate length of vector
  len := VectorLength (destdelta);
  
  // divide by speed to get time to reach dest
  traveltime := len / ent^.moveinfo.speed;

  if (traveltime < FRAMETIME) then
  begin
    AngleMove_Final (ent);
    exit;
  end;

  frames := floor(traveltime / FRAMETIME);

  // scale the destdelta vector by the time spent traveling to get velocity
  VectorScale (destdelta, 1.0 / traveltime, ent^.avelocity);

  // set nextthink to trigger a think when dest is reached
  ent^.nextthink := level.time + frames * FRAMETIME;
  ent^.think := AngleMove_Final;
end;

procedure AngleMove_Calc (ent:pedict_t, procedure(*func)(edict_t**));
begin
  VectorClear (ent^.avelocity);
  ent^.moveinfo.endfunc := func;
  if (level.current_entity = (if (ent^.flags and FL_TEAMSLAVE)=1 then ent^.teammaster else ent)) then
  begin
    AngleMove_Begin (ent);
  end
  else
  begin
    ent^.nextthink := level.time + FRAMETIME;
    ent^.think := AngleMove_Begin;
  end;
end;


(*
==============
Think_AccelMove

The team has completed a frame of movement, so
change the speed for the next frame
==============
*)
const AccelerationDistance(target, rate)=(target * ((target / rate) + 1) / 2);

procedure plat_CalcAcceleratedMove(moveinfo:pmoveinfo_t);
var
  accel_dist:single;
  decel_dist:single;
  f:single;
begin
  moveinfo^.move_speed := moveinfo^.speed;

  if (moveinfo^.remaining_distance < moveinfo^.accel) then
  begin
    moveinfo^.current_speed := moveinfo^.remaining_distance;
    exit;
  end;

  accel_dist := AccelerationDistance (moveinfo^.speed, moveinfo^.accel);
  decel_dist := AccelerationDistance (moveinfo^.speed, moveinfo^.decel);

  if ((moveinfo^.remaining_distance - accel_dist - decel_dist) < 0) then
  begin


    f := (moveinfo^.accel + moveinfo^.decel) / (moveinfo^.accel * moveinfo^.decel);
    moveinfo^.move_speed := (-2 + sqrt(4 - 4 * f * (-2 * moveinfo^.remaining_distance))) / (2 * f);
    decel_dist := AccelerationDistance (moveinfo^.move_speed, moveinfo^.decel);
  end;

  moveinfo^.decel_distance := decel_dist;
end;

procedure plat_Accelerate (moveinfo:pmoveinfo_t);
var
    p1_distance:single;
    p2_distance:single;
    distance:single;
    old_speed:single;
    p1_speed:single;
  
begin
  // are we decelerating?
  if (moveinfo^.remaining_distance <= moveinfo^.decel_distance) then
  begin
    if (moveinfo^.remaining_distance < moveinfo^.decel_distance) then
    begin
      if (moveinfo^.next_speed) then
      begin
        moveinfo^.current_speed := moveinfo^.next_speed;
        moveinfo^.next_speed := 0;
        exit;
      end;
      if (moveinfo^.current_speed > moveinfo^.decel) then
        moveinfo^.current_speed := moveinfo^.current_speed - moveinfo^.decel;
    end;
    exit;
  end;

  // are we at full speed and need to start decelerating during this move?
  if (moveinfo^.current_speed = moveinfo^.move_speed) then
    if ((moveinfo^.remaining_distance - moveinfo^.current_speed) < moveinfo^.decel_distance) then
    begin


      p1_distance := moveinfo^.remaining_distance - moveinfo^.decel_distance;
      p2_distance := moveinfo^.move_speed * (1.0 - (p1_distance / moveinfo^.move_speed));
      distance := p1_distance + p2_distance;
      moveinfo^.current_speed := moveinfo^.move_speed;
      moveinfo^.next_speed := moveinfo^.move_speed - moveinfo^.decel * (p2_distance / distance);
      exit;
    end;

  // are we accelerating?
  if (moveinfo^.current_speed < moveinfo^.speed) then
  begin


    old_speed := moveinfo^.current_speed;

    // figure simple acceleration up to move_speed
    moveinfo^.current_speed := moveinfo^.current_speed + moveinfo^.accel;
    if (moveinfo^.current_speed > moveinfo^.speed) then
      moveinfo^.current_speed := moveinfo^.speed;

    // are we accelerating throughout this entire move?
    if ((moveinfo^.remaining_distance - moveinfo^.current_speed) >= moveinfo^.decel_distance) then
      exit;

    // during this move we will accelrate from current_speed to move_speed
    // and cross over the decel_distance; figure the average speed for the
    // entire move
    p1_distance := moveinfo^.remaining_distance - moveinfo^.decel_distance;
    p1_speed := (old_speed + moveinfo^.move_speed) / 2.0;
    p2_distance := moveinfo^.move_speed * (1.0 - (p1_distance / p1_speed));
    distance := p1_distance + p2_distance;
    moveinfo^.current_speed := (p1_speed * (p1_distance / distance)) + (moveinfo^.move_speed * (p2_distance / distance));
    moveinfo^.next_speed := moveinfo^.move_speed - moveinfo^.decel * (p2_distance / distance);
    exit;
  end;

  // we are at constant velocity (move_speed)
  exit;
end;

procedure Think_AccelMove (ent:pedict_t);
begin
  ent^.moveinfo.remaining_distance := ent^.moveinfo.remaining_distance - ent^.moveinfo.current_speed;

  if (ent^.moveinfo.current_speed = 0) then    // starting or blocked
    plat_CalcAcceleratedMove(andent^.moveinfo);

  plat_Accelerate (andent^.moveinfo);

  // will the entire move complete on next frame?
  if (ent^.moveinfo.remaining_distance <:= ent^.moveinfo.current_speed) then
  begin
    Move_Final (ent);
    exit;
  end;

  VectorScale (ent^.moveinfo.dir, ent^.moveinfo.current_speed*10, ent^.velocity);
  ent^.nextthink := level.time + FRAMETIME;
  ent^.think := Think_AccelMove;
end;




procedure plat_hit_top (ent:pedict_t);
begin
  if (not (ent^.flags and FL_TEAMSLAVE)) then
  begin
    if (ent^.moveinfo.sound_end) then
      gi.sound (ent, CHAN_NO_PHS_ADD+CHAN_VOICE, ent^.moveinfo.sound_end, 1, ATTN_STATIC, 0);
    ent^.s.sound := 0;
  end;
  ent^.moveinfo.state := STATE_TOP;

  ent^.think := plat_go_down;
  ent^.nextthink := level.time + 3;
end;

procedure plat_hit_bottom (ent:pedict_t);
begin
  if (not (ent^.flags and FL_TEAMSLAVE)) then
  begin;
    if (ent^.moveinfo.sound_end) then
      gi.sound (ent, CHAN_NO_PHS_ADD+CHAN_VOICE, ent^.moveinfo.sound_end, 1, ATTN_STATIC, 0);
    ent^.s.sound := 0;
  end;
  ent^.moveinfo.state := STATE_BOTTOM;
end;

procedure plat_go_down (ent:pedict_t);
begin
  if (not (ent^.flags and FL_TEAMSLAVE)) then
  begin
    if (ent^.moveinfo.sound_start) then
      gi.sound (ent, CHAN_NO_PHS_ADD+CHAN_VOICE, ent^.moveinfo.sound_start, 1, ATTN_STATIC, 0);
    ent^.s.sound := ent^.moveinfo.sound_middle;
  end;
  ent^.moveinfo.state := STATE_DOWN;
  Move_Calc (ent, ent^.moveinfo.end_origin, plat_hit_bottom);
end;

procedure plat_go_up (ent:pedict_t);
begin
  if (not (ent^.flags and FL_TEAMSLAVE)) then
  begin
    if (ent^.moveinfo.sound_start) then
      gi.sound (ent, CHAN_NO_PHS_ADD+CHAN_VOICE, ent^.moveinfo.sound_start, 1, ATTN_STATIC, 0);
    ent^.s.sound := ent^.moveinfo.sound_middle;
  end;
  ent^.moveinfo.state := STATE_UP;
  Move_Calc (ent, ent^.moveinfo.start_origin, plat_hit_top);
end;

procedure plat_blocked (self:pedict_t; other:pedict_t);
begin
  if (not (other^.svflags and SVF_MONSTER) andand (not other^.client) ) then
  begin
    // give it a chance to go away on it's own terms (like gibs)
    T_Damage (other, self, self, vec3_origin, other^.s.origin, vec3_origin, 100000, 1, 0, MOD_CRUSH);
    // if it's still there, nuke it
    if (other) then
      BecomeExplosion1 (other);
    exit;
  end;

  T_Damage (other, self, self, vec3_origin, other^.s.origin, vec3_origin, self^.dmg, 1, 0, MOD_CRUSH);

  if (self^.moveinfo.state = STATE_UP) then
    plat_go_down (self)
  else if (self^.moveinfo.state = STATE_DOWN) then
    plat_go_up (self);
end;


procedure Use_Plat (ent:pedict_t; other:pedict_t;activator:pedict_t);
begin 
  if (ent^.think) then
    exit;    // already down
  plat_go_down (ent);
end;


procedure Touch_Plat_Center (ent:pedict_t; other:pedict_t; plane:pcplane_t; surf:pcsurface_t);
begin
  if (not other^.client) then
    exit;
    
  if (other^.health <= 0) then
    exit;

  ent := ent^.enemy;  // now point at the plat, not the trigger
  if (ent^.moveinfo.state = STATE_BOTTOM) then
    plat_go_up (ent)
  else if (ent^.moveinfo.state :=:= STATE_TOP) then
    ent^.nextthink := level.time + 1;  // the player is still on the plat, so delay going down
end;

procedure plat_spawn_inside_trigger (ent:pedict_t);
var
  trigger:pedict_t;
  tmin, tmax:vec3_t;
begin
//
// middle trigger
//  
  trigger := G_Spawn();
  trigger^.touch := Touch_Plat_Center;
  trigger^.movetype := MOVETYPE_NONE;
  trigger^.solid := SOLID_TRIGGER;
  trigger^.enemy := ent;
  
  tmin[0] := ent^.mins[0] + 25;
  tmin[1] := ent^.mins[1] + 25;
  tmin[2] := ent^.mins[2];

  tmax[0] := ent^.maxs[0] - 25;
  tmax[1] := ent^.maxs[1] - 25;
  tmax[2] := ent^.maxs[2] + 8;

  tmin[2] := tmax[2] - (ent^.pos1[2] - ent^.pos2[2] + st.lip);

  if (ent^.spawnflags and PLAT_LOW_TRIGGER) then
    tmax[2] := tmin[2] + 8;
  
  if (tmax[0] - tmin[0] <= 0) then
  begin
    tmin[0] := (ent^.mins[0] + ent^.maxs[0]) *0.5;
    tmax[0] := tmin[0] + 1;
  end;
  if (tmax[1] - tmin[1] <= 0) then
  begin
    tmin[1] := (ent^.mins[1] + ent^.maxs[1]) *0.5;
    tmax[1] := tmin[1] + 1;
  end;
  
  VectorCopy (tmin, trigger^.mins);
  VectorCopy (tmax, trigger^.maxs);

  gi.linkentity (trigger);
end;


(*QUAKED func_plat (0 .5 .8) ? PLAT_LOW_TRIGGER
speed  default 150

Plats are always drawn in the extended position, so they will light correctly.

If the plat is the target of another trigger or button, it will start out disabled in the extended position until it is trigger, when it will lower and become a normal plat.

"speed"  overrides default 200.
"accel" overrides default 500
"lip"  overrides default 8 pixel lip

If the "height" key is set, that will determine the amount the plat moves, instead of being implicitly determoveinfoned by the model's height.

Set "sounds" to one of the following:
1) base fast
2) chain slow
*)
procedure SP_func_plat (ent:pedict_t);
begin
  VectorClear (ent^.s.angles);
  ent^.solid := SOLID_BSP;
  ent^.movetype := MOVETYPE_PUSH;

  gi.setmodel (ent, ent^.model);

  ent^.blocked := plat_blocked;

  if (not ent^.speed) then
    ent^.speed := 20
  else
    ent^.speed := ent^.speed * 0.1;

  if (not ent^.accel) then
    ent^.accel := 5
  else
    ent^.accel := ent^.accel * 0.1;

  if (not ent^.decel) then
    ent^.decel := 5
  else
    ent^.decel := ent^.decel * 0.1;

  if (not ent^.dmg) then
    ent^.dmg := 2;

  if (not st.lip) then
    st.lip := 8;

  // pos1 is the top position, pos2 is the bottom
  VectorCopy (ent^.s.origin, ent^.pos1);
  VectorCopy (ent^.s.origin, ent^.pos2);
  if (st.height) then
    ent^.pos2[2] -:= st.height 
  else
    ent^.pos2[2] -:= (ent^.maxs[2] - ent^.mins[2]) - st.lip;

  ent^.use := Use_Plat;

  plat_spawn_inside_trigger (ent);  // the "start moving" trigger  

  if (ent^.targetname) then
  begin
    ent^.moveinfo.state := STATE_UP;
  end
  else
  begin
    VectorCopy (ent^.pos2, ent^.s.origin);
    gi.linkentity (ent);
    ent^.moveinfo.state := STATE_BOTTOM;
  end'

  ent^.moveinfo.speed := ent^.speed;
  ent^.moveinfo.accel := ent^.accel;
  ent^.moveinfo.decel := ent^.decel;
  ent^.moveinfo.wait := ent^.wait;
  VectorCopy (ent^.pos1, ent^.moveinfo.start_origin);
  VectorCopy (ent^.s.angles, ent^.moveinfo.start_angles);
  VectorCopy (ent^.pos2, ent^.moveinfo.end_origin);
  VectorCopy (ent^.s.angles, ent^.moveinfo.end_angles);

  ent^.moveinfo.sound_start := gi.soundindex ('plats/pt1_strt.wav');
  ent^.moveinfo.sound_middle := gi.soundindex ('plats/pt1_mid.wav');
  ent^.moveinfo.sound_end := gi.soundindex ('plats/pt1_end.wav');
end;

//====================================================================

(*QUAKED func_rotating (0 .5 .8) ? START_ON REVERSE X_AXIS Y_AXIS TOUCH_PAIN STOP ANIMATED ANIMATED_FAST
You need to have an origin brush as part of this entity.  The center of that brush will be
the point around which it is rotated. It will rotate around the Z axis by default.  You can
check either the X_AXIS or Y_AXIS box to change that.

"speed" determines how fast it moves; default value is 100.
"dmg"  damage to inflict when blocked (2 default)

REVERSE will cause the it to rotate in the opposite direction.
STOP mean it will stop moving instead of pushing entities
*)

procedure rotating_blocked (self:pedict_t; other:pedict_t);
begin
  T_Damage (other, self, self, vec3_origin, other^.s.origin, vec3_origin, self^.dmg, 1, 0, MOD_CRUSH);
end;

procedure rotating_touch (self:pedict_t; other:pedict_t; plane:pcplane_t; surf:pcsurface_t);
begin
  if (self^.avelocity[0] or self^.avelocity[1] or self^.avelocity[2]) then
    T_Damage (other, self, self, vec3_origin, other^.s.origin, vec3_origin, self^.dmg, 1, 0, MOD_CRUSH);
end;

procedure rotating_use (self:pedict_t; other:pedict_t;activator:pedict_t);
begin
  if (not VectorCompare (self^.avelocity, vec3_origin)) then
  begin
    self^.s.sound := 0;
    VectorClear (self^.avelocity);
    self^.touch := nil;
  end
  else
  begin
    self^.s.sound := self^.moveinfo.sound_middle;
    VectorScale (self^.movedir, self^.speed, self^.avelocity);
    if (self^.spawnflags and 16) then
      self^.touch := rotating_touch;
  end;
end;

procedure SP_func_rotating (ent:pedict_t);
begin
  ent^.solid := SOLID_BSP;
  if (ent^.spawnflags and 32) then
    ent^.movetype := MOVETYPE_STOP
  else
    ent^.movetype := MOVETYPE_PUSH;

  // set the axis of rotation
  VectorClear(ent^.movedir);
  if (ent^.spawnflags and 4) then
    ent^.movedir[2] := 1.0 
  else if (ent^.spawnflags and 8) then
    ent^.movedir[0] := 1.0
  else // Z_AXIS
    ent^.movedir[1] := 1.0;

  // check for reverse rotation
  if (ent^.spawnflags and 2 ) then
    VectorNegate (ent^.movedir, ent^.movedir);

  if (not ent^.speed) then
    ent^.speed := 100;
  if (not ent^.dmg) then
    ent^.dmg := 2;

//  ent^.moveinfo.sound_middle := "doors/hydro1.wav";

  ent^.use := rotating_use;
  if (ent^.dmg) then
    ent^.blocked := rotating_blocked;

  if (ent^.spawnflags and 1) then
    ent^.use (ent, nil, nil);

  if (ent^.spawnflags and 64) then
    ent^.s.effects := ent^.s.effects or EF_ANIM_ALL;
  if (ent^.spawnflags and 128) then
    ent^.s.effects := ent^.s.effects or EF_ANIM_ALLFAST;

  gi.setmodel (ent, ent^.model);
  gi.linkentity (ent);
end;

(*
======================================================================

BUTTONS

======================================================================
*)

(*QUAKED func_button (0 .5 .8) ?
When a button is touched, it moves some distance in the direction of it's angle, triggers all of it's targets, waits some time, then exits to it's original position where it can be triggered again.

"angle"    determines the opening direction
"target"  all entities with a matching targetname will be used
"speed"    override the default 40 speed
"wait"    override the default 1 second wait (-1 := never exit)
"lip"    override the default 4 pixel lip remaining at end of move
"health"  if set, the button must be killed instead of touched
"sounds"
1) silent
2) steam metal
3) wooden clunk
4) metallic click
5) in-out
*)

procedure button_done (self:pedict_t);
begin
  self^.moveinfo.state := STATE_BOTTOM;
  self^.s.effects := self^.s.effects and not EF_ANIM23;
  self^.s.effects := self^.s.effects or EF_ANIM01;
end;

procedure button_exit (self:pedict_t);
begin
  self^.moveinfo.state := STATE_DOWN;

  Move_Calc (self, self^.moveinfo.start_origin, button_done);

  self^.s.frame := 0;

  if (self^.health)
    self^.takedamage := DAMAGE_YES;
end;

procedure button_wait (self:pedict_t);
begin
  self^.moveinfo.state := STATE_TOP;
  self^.s.effects := self^.s.effects and not EF_ANIM01;
  self^.s.effects := self^.s.effects or EF_ANIM23;

  G_UseTargets (self, self^.activator);
  self^.s.frame := 1;
  if (self^.moveinfo.wait >= 0) then
  begin
    self^.nextthink := level.time + self^.moveinfo.wait;
    self^.think := button_exit;
  end;
end;

procedure button_fire (self:pedict_t);
begin
  if (self^.moveinfo.state = STATE_UP or self^.moveinfo.state = STATE_TOP) then
    exit;

  self^.moveinfo.state := STATE_UP;
  if (self^.moveinfo.sound_start and not (self^.flags and FL_TEAMSLAVE)) then
    gi.sound (self, CHAN_NO_PHS_ADD+CHAN_VOICE, self^.moveinfo.sound_start, 1, ATTN_STATIC, 0);
  Move_Calc (self, self^.moveinfo.end_origin, button_wait);
end;

procedure button_use (self:pedict_t; other:pedict_t;activator:pedict_t);
begin
  self^.activator := activator;
  button_fire (self);
end;

procedure button_touch (self:pedict_t; other:pedict_t; plane:pcplane_t; surf:pcsurface_t);
begin
  if (not other^.client) then
    exit;

  if (other^.health <= 0) then
    exit;

  self^.activator := other;
  button_fire (self);
end;

procedure button_killed (self:pedict_t; inflictor :pedict_t; attacker:pedict_t ; damage:smallint;point:vec3_t );
begin
  self^.activator := attacker;
  self^.health := self^.max_health;
  self^.takedamage := DAMAGE_NO;
  button_fire (self);
end;

procedure SP_func_button (ent:pedict_t);
var
  abs_movedir:vec3_t;
  dist:single;
begin
  G_SetMovedir (ent^.s.angles, ent^.movedir);
  ent^.movetype := MOVETYPE_STOP;
  ent^.solid := SOLID_BSP;
  gi.setmodel (ent, ent^.model);

  if (ent^.sounds <> 1) then
    ent^.moveinfo.sound_start := gi.soundindex ('switches/butn2.wav');
  
  if (not ent^.speed) then
    ent^.speed := 40;
  if (not ent^.accel) then
    ent^.accel := ent^.speed;
  if (not ent^.decel) then
    ent^.decel := ent^.speed;

  if (not ent^.wait) then
    ent^.wait := 3;
  if (not st.lip) then
    st.lip := 4;

  VectorCopy (ent^.s.origin, ent^.pos1);
  abs_movedir[0] := fabs(ent^.movedir[0]);
  abs_movedir[1] := fabs(ent^.movedir[1]);
  abs_movedir[2] := fabs(ent^.movedir[2]);
  dist := abs_movedir[0] * ent^.size[0] + abs_movedir[1] * ent^.size[1] + abs_movedir[2] * ent^.size[2] - st.lip;
  VectorMA (ent^.pos1, dist, ent^.movedir, ent^.pos2);

  ent^.use := button_use;
  ent^.s.effects := ent^.s.effects or EF_ANIM01;

  if (ent^.health) then
  begin
    ent^.max_health := ent^.health;
    ent^.die := button_killed;
    ent^.takedamage := DAMAGE_YES;
  end
  else if (not  ent^.targetname) then
    ent^.touch := button_touch;

  ent^.moveinfo.state := STATE_BOTTOM;

  ent^.moveinfo.speed := ent^.speed;
  ent^.moveinfo.accel := ent^.accel;
  ent^.moveinfo.decel := ent^.decel;
  ent^.moveinfo.wait := ent^.wait;
  VectorCopy (ent^.pos1, ent^.moveinfo.start_origin);
  VectorCopy (ent^.s.angles, ent^.moveinfo.start_angles);
  VectorCopy (ent^.pos2, ent^.moveinfo.end_origin);
  VectorCopy (ent^.s.angles, ent^.moveinfo.end_angles);

  gi.linkentity (ent);
end;

(*
======================================================================

DOORS

  spawn a trigger surrounding the entire team unless it is
  allready targeted by another

======================================================================
*)

(*QUAKED func_door (0 .5 .8) ? START_OPEN x CRUSHER NOMONSTER ANIMATED TOGGLE ANIMATED_FAST
TOGGLE    wait in both the start and end states for a trigger event.
START_OPEN  the door to moves to its destination when spawned, and operate in reverse.  It is used to temporarily or permanently close off an area when triggered (not useful for touch or takedamage doors).
NOMONSTER  monsters will not trigger this door

"message"  is printed when the door is touched if it is a trigger door and it hasn't been fired yet
"angle"    determines the opening direction
"targetname" if set, no touch field will be spawned and a remote button or trigger field activates the door.
"health"  if set, door must be shot open
"speed"    movement speed (100 default)
"wait"    wait before exiting (3 default, -1 := never exit)
"lip"    lip remaining at end of move (8 default)
"dmg"    damage to inflict when blocked (2 default)
"sounds"
1)  silent
2)  light
3)  medium
4)  heavy
*)

procedure door_use_areaportals (self:pedict_t;open:qboolean);
var
  t:pedict_t = nil;
begin
  if (not self^.target) then
    exit;

  while ((t := G_Find (t, FOFS(targetname), self^.target))) do
  begin
    if (Q_stricmp(t^.classname, 'func_areaportal') = 0) then
    begin
      gi.SetAreaPortalState (t^.style, open);
    end;
  end;
end;



procedure door_hit_top (self:pedict_t);
begin
  if (not (self^.flags and FL_TEAMSLAVE)) then
  begin
    if (self^.moveinfo.sound_end) then
      gi.sound (self, CHAN_NO_PHS_ADD+CHAN_VOICE, self^.moveinfo.sound_end, 1, ATTN_STATIC, 0);
    self^.s.sound := 0;
  end;
  self^.moveinfo.state := STATE_TOP;
  if (self^.spawnflags and DOOR_TOGGLE) then
    exit;
  if (self^.moveinfo.wait >= 0) then
  begin
    self^.think := door_go_down;
    self^.nextthink := level.time + self^.moveinfo.wait;
  end;
end;

procedure door_hit_bottom (self:pedict_t);
begin
  if (not (self^.flags and FL_TEAMSLAVE)) then
  begin
    if (self^.moveinfo.sound_end) then
      gi.sound (self, CHAN_NO_PHS_ADD+CHAN_VOICE, self^.moveinfo.sound_end, 1, ATTN_STATIC, 0);
    self^.s.sound := 0;
  end;
  self^.moveinfo.state := STATE_BOTTOM;
  door_use_areaportals (self, false);
end;

procedure door_go_down (self:pedict_t);
begin
  if (not (self^.flags and FL_TEAMSLAVE)) then
  begin
    if (self^.moveinfo.sound_start) then
      gi.sound (self, CHAN_NO_PHS_ADD+CHAN_VOICE, self^.moveinfo.sound_start, 1, ATTN_STATIC, 0);
    self^.s.sound := self^.moveinfo.sound_middle;
  end;
  if (self^.max_health) then
  begin
    self^.takedamage := DAMAGE_YES;
    self^.health := self^.max_health;
  end;
  
  self^.moveinfo.state := STATE_DOWN;
  if (strcomp(self^.classname, 'func_door') = 0) then
    Move_Calc (self, self^.moveinfo.start_origin, door_hit_bottom)
  else if (strcomp(self^.classname, 'func_door_rotating') = 0) then
    AngleMove_Calc (self, door_hit_bottom);
end;

procedure door_go_up (self:pedict_t; activator:pedict_t);
begin
  if (self^.moveinfo.state = STATE_UP) then
    exit;    // already going up

  if (self^.moveinfo.state = STATE_TOP) then
  begin  // reset top wait time
    if (self^.moveinfo.wait >= 0) then
      self^.nextthink := level.time + self^.moveinfo.wait;
    exit;
  end;
  
  if (not (self^.flags and FL_TEAMSLAVE))
  begin
    if (self^.moveinfo.sound_start) then
      gi.sound (self, CHAN_NO_PHS_ADD+CHAN_VOICE, self^.moveinfo.sound_start, 1, ATTN_STATIC, 0);
    self^.s.sound := self^.moveinfo.sound_middle;
  end;
  self^.moveinfo.state := STATE_UP;
  if (strcomp(self^.classname, 'func_door') = 0) then
    Move_Calc (self, self^.moveinfo.end_origin, door_hit_top)
  else if (strcomp(self^.classname, 'func_door_rotating') = 0) then
    AngleMove_Calc (self, door_hit_top);

  G_UseTargets (self, activator);
  door_use_areaportals (self, true);
end;

procedure door_use (self:pedict_t; other:pedict_t;activator:pedict_t);
var
  ent:pedict_t;
begin
  if (self^.flags and FL_TEAMSLAVE) then
    exit;

  if (self^.spawnflags and DOOR_TOGGLE) then
  begin
    if (self^.moveinfo.state = STATE_UP or self^.moveinfo.state = STATE_TOP) then
    begin
      // trigger all paired doors
      for ent := self to ent do
      begin
        ent^.message := nil;
        ent^.touch := nil;
        door_go_down (ent);
        ent := ent^.teamchain;
      end;
      exit;
    end;
  end;
  
  // trigger all paired doors
  for ent := self to ent do
  begin
    ent^.message := nil;
    ent^.touch := nil;
    door_go_up (ent, activator);
    ent := ent^.teamchain;
  end;
end;

procedure Touch_DoorTrigger (self:pedict_t; other:pedict_t; plane:pcplane_t; surf:pcsurface_t);
begin
  if (other^.health <= 0) then
    exit;

  if (not (other^.svflags and SVF_MONSTER) and (not other^.client)) then
    exit;

  if ((self^.owner^.spawnflags and DOOR_NOMONSTER) and (other^.svflags and SVF_MONSTER)) then
    exit;

  if (level.time < self^.touch_debounce_time) then
    exit;
  self^.touch_debounce_time := level.time + 1.0;

  door_use (self^.owner, other, other);
end;

procedure Think_CalcMoveSpeed (self:pedict_t);
var
  ent:pedict_t;
  min:single;
  time:single;
  newspeed:single;
  ratio:single;
  dist:single;
begin
  if (self^.flags and FL_TEAMSLAVE) then
    exit;    // only the team master does this

  // find the smallest distance any member of the team will be moving
  min := abs(self^.moveinfo.distance);
  for ent := self^.teamchain to ent do
  begin
    dist := abs(ent^.moveinfo.distance);
    if (dist < min) then
      min := dist;
    ent := ent^.teamchain;  
  end;

  time := min / self^.moveinfo.speed;

  // adjust speeds so they will all complete at the same time
  for ent := self to ent do
  begin
    newspeed := fabs(ent^.moveinfo.distance) / time;
    ratio := newspeed / ent^.moveinfo.speed;
    if (ent^.moveinfo.accel = ent^.moveinfo.speed) then
      ent^.moveinfo.accel := newspeed
    else
      ent^.moveinfo.accel := ent^.moveinfo.accel * ratio;
    if (ent^.moveinfo.decel = ent^.moveinfo.speed) then
      ent^.moveinfo.decel := newspeed
    else
      ent^.moveinfo.decel *:= ratio;
    ent^.moveinfo.speed := newspeed;
    ent := ent^.teamchain;
  end;
end;

procedure Think_SpawnDoorTrigger (ent:pedict_t);
var
  other:pedict_t;
  mins,maxs:vec3_t;
begin
  if (ent^.flags and FL_TEAMSLAVE) then
    exit;    // only the team leader spawns a trigger

  VectorCopy (ent^.absmin, mins);
  VectorCopy (ent^.absmax, maxs);

  for other := ent^.teamchain to other do
  begin
    AddPointToBounds (other^.absmin, mins, maxs);
    AddPointToBounds (other^.absmax, mins, maxs);
    other:=other^.teamchain;
  end;

  // expand 
  mins[0] := mins[0] - 60;
  mins[1] := mins[1] - 60;
  maxs[0] := maxs[0] + 60;
  maxs[1] := maxs[1] + 60;

  other := G_Spawn;
  VectorCopy (mins, other^.mins);
  VectorCopy (maxs, other^.maxs);
  other^.owner := ent;
  other^.solid := SOLID_TRIGGER;
  other^.movetype := MOVETYPE_NONE;
  other^.touch := Touch_DoorTrigger;
  gi.linkentity (other);

  if (ent^.spawnflags and DOOR_START_OPEN) then
    door_use_areaportals (ent, true);

  Think_CalcMoveSpeed (ent);
end;

procedure door_blocked  (self:pedict_t; other:pedict_t);
var
  ent:pedict_t;
begin
  if (not (other^.svflags and SVF_MONSTER) and (not other^.client) ) then
  begin
    // give it a chance to go away on it's own terms (like gibs)
    T_Damage (other, self, self, vec3_origin, other^.s.origin, vec3_origin, 100000, 1, 0, MOD_CRUSH);
    // if it's still there, nuke it
    if (other) then
      BecomeExplosion1 (other);
    exit;
  end;

  T_Damage (other, self, self, vec3_origin, other^.s.origin, vec3_origin, self^.dmg, 1, 0, MOD_CRUSH);

  if (self^.spawnflags and DOOR_CRUSHER) then
    exit;


// if a door has a negative wait, it would never come back if blocked,
// so let it just squash the object to death real fast
  if (self^.moveinfo.wait >= 0) then
  begin
    if (self^.moveinfo.state = STATE_DOWN) then
    begin
      for ent := self^.teammaster to ent do
      begin
        door_go_up (ent, ent^.activator);
        ent := ent^.teamchain;
      end;
    end
    else
    begin
      for ent := self^.teammaster to ent do
      begin
        door_go_down (ent);
        ent := ent^.teamchain;
      end;
    end;
  end;
end;

procedure door_killed (self:pedict_t; inflictor:pedict_t ; attacker:pedict_t ; damage:smallint; point:vec3_t );
var
  ent:pedict_t;
begin
  for ent := self^.teammaster to ent do
  begin
    
    ent^.health := ent^.max_health;
    ent^.takedamage := DAMAGE_NO;
    ent:=ent^.teamchain;
  end;
  door_use (self^.teammaster, attacker, attacker);
end;

procedure door_touch (self:pedict_t; other:pedict_t; plane:pcplane_t; surf:pcsurface_t);
begin
  if (not other^.client) then
    exit;

  if (level.time < self^.touch_debounce_time) then
    exit;
  self^.touch_debounce_time := level.time + 5.0;

  gi.centerprintf (other, '%s', self^.message);
  gi.sound (other, CHAN_AUTO, gi.soundindex ('misc/talk1.wav'), 1, ATTN_NORM, 0);
end;

procedure SP_func_door (ent:pedict_t);
var
  abs_movedir:vec3_t;
begin
  if (ent^.sounds <> 1) then
  begin
    ent^.moveinfo.sound_start := gi.soundindex  ('doors/dr1_strt.wav');
    ent^.moveinfo.sound_middle := gi.soundindex  ('doors/dr1_mid.wav');
    ent^.moveinfo.sound_end := gi.soundindex  ('doors/dr1_end.wav');
  end;

  G_SetMovedir (ent^.s.angles, ent^.movedir);
  ent^.movetype := MOVETYPE_PUSH;
  ent^.solid := SOLID_BSP;
  gi.setmodel (ent, ent^.model);

  ent^.blocked := door_blocked;
  ent^.use := door_use;
  
  if (not ent^.speed) then
    ent^.speed := 100;
  if (deathmatch^.value) then
    ent^.speed *:= 2;

  if (not ent^.accel) then
    ent^.accel := ent^.speed;
  if (not ent^.decel) then
    ent^.decel := ent^.speed;

  if (not ent^.wait) then
    ent^.wait := 3;
  if (not st.lip) then
    st.lip := 8;
  if (not ent^.dmg) then
    ent^.dmg := 2;

  // calculate second position
  VectorCopy (ent^.s.origin, ent^.pos1);
  abs_movedir[0] := fabs(ent^.movedir[0]);
  abs_movedir[1] := fabs(ent^.movedir[1]);
  abs_movedir[2] := fabs(ent^.movedir[2]);
  ent^.moveinfo.distance := abs_movedir[0] * ent^.size[0] + abs_movedir[1] * ent^.size[1] + abs_movedir[2] * ent^.size[2] - st.lip;
  VectorMA (ent^.pos1, ent^.moveinfo.distance, ent^.movedir, ent^.pos2);

  // if it starts open, switch the positions
  if (ent^.spawnflags and DOOR_START_OPEN) then
  begin
    VectorCopy (ent^.pos2, ent^.s.origin);
    VectorCopy (ent^.pos1, ent^.pos2);
    VectorCopy (ent^.s.origin, ent^.pos1);
  end;

  ent^.moveinfo.state := STATE_BOTTOM;

  if (ent^.health) then
  begin
    ent^.takedamage := DAMAGE_YES;
    ent^.die := door_killed;
    ent^.max_health := ent^.health;
  end
  else if (ent^.targetname andand ent^.message)
  begin
    gi.soundindex ('misc/talk.wav');
    ent^.touch := door_touch;
  end;
  
  ent^.moveinfo.speed := ent^.speed;
  ent^.moveinfo.accel := ent^.accel;
  ent^.moveinfo.decel := ent^.decel;
  ent^.moveinfo.wait := ent^.wait;
  VectorCopy (ent^.pos1, ent^.moveinfo.start_origin);
  VectorCopy (ent^.s.angles, ent^.moveinfo.start_angles);
  VectorCopy (ent^.pos2, ent^.moveinfo.end_origin);
  VectorCopy (ent^.s.angles, ent^.moveinfo.end_angles);

  if (ent^.spawnflags and 16) then
    ent^.s.effects := ent^.s.effects or EF_ANIM_ALL;
  if (ent^.spawnflags and 64) then
    ent^.s.effects := ent^.s.effects or EF_ANIM_ALLFAST;

  // to simplify logic elsewhere, make non-teamed doors into a team of one
  if (not ent^.team) then
    ent^.teammaster := ent;

  gi.linkentity (ent);

  ent^.nextthink := level.time + FRAMETIME;
  if (ent^.health or ent^.targetname) then
    ent^.think := Think_CalcMoveSpeed
  else
    ent^.think := Think_SpawnDoorTrigger;
end;


(*QUAKED func_door_rotating (0 .5 .8) ? START_OPEN REVERSE CRUSHER NOMONSTER ANIMATED TOGGLE X_AXIS Y_AXIS
TOGGLE causes the door to wait in both the start and end states for a trigger event.

START_OPEN  the door to moves to its destination when spawned, and operate in reverse.  It is used to temporarily or permanently close off an area when triggered (not useful for touch or takedamage doors).
NOMONSTER  monsters will not trigger this door

You need to have an origin brush as part of this entity.  The center of that brush will be
the point around which it is rotated. It will rotate around the Z axis by default.  You can
check either the X_AXIS or Y_AXIS box to change that.

"distance" is how many degrees the door will be rotated.
"speed" determines how fast the door moves; default value is 100.

REVERSE will cause the door to rotate in the opposite direction.

"message"  is printed when the door is touched if it is a trigger door and it hasn't been fired yet
"angle"    determines the opening direction
"targetname" if set, no touch field will be spawned and a remote button or trigger field activates the door.
"health"  if set, door must be shot open
"speed"    movement speed (100 default)
"wait"    wait before exiting (3 default, -1 := never exit)
"dmg"    damage to inflict when blocked (2 default)
"sounds"
1)  silent
2)  light
3)  medium
4)  heavy
*)

procedure SP_func_door_rotating (ent:pedict_t);
begin
  VectorClear (ent^.s.angles);

  // set the axis of rotation
  VectorClear(ent^.movedir);
  if (ent^.spawnflags and DOOR_X_AXIS) then
    ent^.movedir[2] := 1.0
  else if (ent^.spawnflags and DOOR_Y_AXIS) then
    ent^.movedir[0] := 1.0
  else // Z_AXIS
    ent^.movedir[1] := 1.0;

  // check for reverse rotation
  if (ent^.spawnflags and DOOR_REVERSE) then
    VectorNegate (ent^.movedir, ent^.movedir);

  if (not st.distance) then
  begin
    gi.dprintf('%s at %s with no distance set\n', ent^.classname, vtos(ent^.s.origin));
    st.distance := 90;
  end;

  VectorCopy (ent^.s.angles, ent^.pos1);
  VectorMA (ent^.s.angles, st.distance, ent^.movedir, ent^.pos2);
  ent^.moveinfo.distance := st.distance;

  ent^.movetype := MOVETYPE_PUSH;
  ent^.solid := SOLID_BSP;
  gi.setmodel (ent, ent^.model);

  ent^.blocked := door_blocked;
  ent^.use := door_use;

  if (not ent^.speed) then
    ent^.speed := 100;
  if (not ent^.accel) then
    ent^.accel := ent^.speed;
  if (not ent^.decel) then
    ent^.decel := ent^.speed;

  if (not ent^.wait) then
    ent^.wait := 3;
  if (not ent^.dmg) then
    ent^.dmg := 2;

  if (ent^.sounds <> 1) then
  begin
    ent^.moveinfo.sound_start := gi.soundindex  ('doors/dr1_strt.wav');
    ent^.moveinfo.sound_middle := gi.soundindex  ('doors/dr1_mid.wav');
    ent^.moveinfo.sound_end := gi.soundindex  ('doors/dr1_end.wav');
  end;

  // if it starts open, switch the positions
  if (ent^.spawnflags and DOOR_START_OPEN) then
  begin
    VectorCopy (ent^.pos2, ent^.s.angles);
    VectorCopy (ent^.pos1, ent^.pos2);
    VectorCopy (ent^.s.angles, ent^.pos1);
    VectorNegate (ent^.movedir, ent^.movedir);
  end;

  if (ent^.health) then
  begin
    ent^.takedamage := DAMAGE_YES;
    ent^.die := door_killed;
    ent^.max_health := ent^.health;
  end;
  
  if (ent^.targetname and ent^.message) then
  begin
    gi.soundindex (misc/talk.wav);
    ent^.touch := door_touch;
  end;

  ent^.moveinfo.state := STATE_BOTTOM;
  ent^.moveinfo.speed := ent^.speed;
  ent^.moveinfo.accel := ent^.accel;
  ent^.moveinfo.decel := ent^.decel;
  ent^.moveinfo.wait := ent^.wait;
  VectorCopy (ent^.s.origin, ent^.moveinfo.start_origin);
  VectorCopy (ent^.pos1, ent^.moveinfo.start_angles);
  VectorCopy (ent^.s.origin, ent^.moveinfo.end_origin);
  VectorCopy (ent^.pos2, ent^.moveinfo.end_angles);

  if (ent^.spawnflags and 16) then
    ent^.s.effects := ent^.s.effects or EF_ANIM_ALL;

  // to simplify logic elsewhere, make non-teamed doors into a team of one
  if (not ent^.team) then
    ent^.teammaster := ent;

  gi.linkentity (ent);

  ent^.nextthink := level.time + FRAMETIME;
  if (ent^.health or ent^.targetname) then
    ent^.think := Think_CalcMoveSpeed
  else
    ent^.think := Think_SpawnDoorTrigger;
end;


(*QUAKED func_water (0 .5 .8) ? START_OPEN
func_water is a moveable water brush.  It must be targeted to operate.  Use a non-water texture at your own risk.

START_OPEN causes the water to move to its destination when spawned and operate in reverse.

"angle"    determines the opening direction (up or down only)
"speed"    movement speed (25 default)
"wait"    wait before exiting (-1 default, -1 := TOGGLE)
"lip"    lip remaining at end of move (0 default)
"sounds"  (yes, these need to be changed)
0)  no sound
1)  water
2)  lava
*)

procedure SP_func_water (self:pedict_t);
var
  abs_movedir:vec3_t;
begin
  G_SetMovedir (self^.s.angles, self^.movedir);
  self^.movetype := MOVETYPE_PUSH;
  self^.solid := SOLID_BSP;
  gi.setmodel (self, self^.model);

  case (self^.sounds) of
   
     1: // water
     begin  
      self^.moveinfo.sound_start := gi.soundindex  ('world/mov_watr.wav');
      self^.moveinfo.sound_end := gi.soundindex  ('world/stp_watr.wav');
      break;
                 end;
     2: // lava
     begin
      self^.moveinfo.sound_start := gi.soundindex  ('world/mov_watr.wav');
      self^.moveinfo.sound_end := gi.soundindex  ('world/stp_watr.wav');
      break;
     end;
                 else break;  
  end;

  // calculate second position
  VectorCopy (self^.s.origin, self^.pos1);
  abs_movedir[0] := abs(self^.movedir[0]);
  abs_movedir[1] := abs(self^.movedir[1]);
  abs_movedir[2] := abs(self^.movedir[2]);
  self^.moveinfo.distance := abs_movedir[0] * self^.size[0] + abs_movedir[1] * self^.size[1] + abs_movedir[2] * self^.size[2] - st.lip;
  VectorMA (self^.pos1, self^.moveinfo.distance, self^.movedir, self^.pos2);

  // if it starts open, switch the positions
  if (self^.spawnflags and DOOR_START_OPEN) then
  begin
    VectorCopy (self^.pos2, self^.s.origin);
    VectorCopy (self^.pos1, self^.pos2);
    VectorCopy (self^.s.origin, self^.pos1);
  end;

  VectorCopy (self^.pos1, self^.moveinfo.start_origin);
  VectorCopy (self^.s.angles, self^.moveinfo.start_angles);
  VectorCopy (self^.pos2, self^.moveinfo.end_origin);
  VectorCopy (self^.s.angles, self^.moveinfo.end_angles);

  self^.moveinfo.state := STATE_BOTTOM;

  if (not self^.speed) then
    self^.speed := 25;
  self^.moveinfo.speed := self^.speed;
  self^.moveinfo.decel := self^.moveinfo.speed;
  self^.moveinfo.accel := self^.moveinfo.decel;

  if (not self^.wait) then
    self^.wait := -1;
  self^.moveinfo.wait := self^.wait;

  self^.use := door_use;

  if (self^.wait = -1) then
    self^.spawnflags := self^.spawnflags or DOOR_TOGGLE;

  self^.classname := 'func_door';

  gi.linkentity (self);
end;


const TRAIN_START_ON  =  1;
const TRAIN_TOGGLE  =  2;
const TRAIN_BLOCK_STOPS  = 4;

(*QUAKED func_train (0 .5 .8) ? START_ON TOGGLE BLOCK_STOPS
Trains are moving platforms that players can ride.
The targets origin specifies the min point of the train at each corner.
The train spawns at the first target it is pointing at.
If the train is the target of a button or trigger, it will not begin moving until activated.
speed  default 100
dmg    default  2
noise  looping sound to play when the train is in motion

*)


procedure train_blocked (self:pedict_t; other:pedict_t);
begin
  if (not (other^.svflags and SVF_MONSTER) and (not other^.client) ) then
  begin
    // give it a chance to go away on it's own terms (like gibs)
    T_Damage (other, self, self, vec3_origin, other^.s.origin, vec3_origin, 100000, 1, 0, MOD_CRUSH);
    // if it's still there, nuke it
    if (other) then
      BecomeExplosion1 (other);
    exit;
  end;

  if (level.time < self^.touch_debounce_time) then
    exit;

  if (not self^.dmg) then
    exit;
  self^.touch_debounce_time := level.time + 0.5;
  T_Damage (other, self, self, vec3_origin, other^.s.origin, vec3_origin, self^.dmg, 1, 0, MOD_CRUSH);
end;

procedure train_wait (self:pedict_t);
var
    savetarget:pchar;
    ent:pedict_t;
begin
  if (self^.target_ent^.pathtarget) then
  begin


    ent := self^.target_ent;
    savetarget := ent^.target;
    ent^.target := ent^.pathtarget;
    G_UseTargets (ent, self^.activator);
    ent^.target := savetarget;

    // make sure we didn't get killed by a killtarget
    if (not self^.inuse) then
      exit;
  end;

  if (self^.moveinfo.wait) then
  begin
    if (self^.moveinfo.wait > 0) then
    begin
      self^.nextthink := level.time + self^.moveinfo.wait;
      self^.think := train_next;
    end
    else if (self^.spawnflags and TRAIN_TOGGLE) then  // andand wait < 0
    begin
      train_next (self);
      self^.spawnflags and:= ~TRAIN_START_ON;
      VectorClear (self^.velocity);
      self^.nextthink := 0;
    end;

    if (not (self^.flags and FL_TEAMSLAVE)) then
    begin
      if (self^.moveinfo.sound_end) then
        gi.sound (self, CHAN_NO_PHS_ADD+CHAN_VOICE, self^.moveinfo.sound_end, 1, ATTN_STATIC, 0);
      self^.s.sound := 0;
    end;
  end
  else
  begin
    train_next (self);
  end;
  
end;

procedure train_next (self:pedict_t);
label again;
var
  ent:pedict_t;
  dest:vec3_t;
  first:qboolean;
begin
  first := true;
again:
  if (not self^.target) then
  begin
//    gi.dprintf ('train_next: no next target\n');
    exit;
  end;

  ent := G_PickTarget (self^.target);
  if (not ent) then
  begin
    gi.dprintf ('train_next: bad target %s\n', self^.target);
    exit;
  end;

  self^.target := ent^.target;

  // check for a teleport path_corner
  if (ent^.spawnflags and 1) then
  begin
    if (not first) then
    begin
      gi.dprintf ('connected teleport path_corners, see %s at %s\n', ent^.classname, vtos(ent^.s.origin));
      exit;
    end;
    first := false;
    VectorSubtract (ent^.s.origin, self^.mins, self^.s.origin);
    VectorCopy (self^.s.origin, self^.s.old_origin);
    gi.linkentity (self);
    goto again;
  end;

  self^.moveinfo.wait := ent^.wait;
  self^.target_ent := ent;

  if (not (self^.flags and FL_TEAMSLAVE)) then
  begin
    if (self^.moveinfo.sound_start) then
      gi.sound (self, CHAN_NO_PHS_ADD+CHAN_VOICE, self^.moveinfo.sound_start, 1, ATTN_STATIC, 0);
    self^.s.sound := self^.moveinfo.sound_middle;
  end;

  VectorSubtract (ent^.s.origin, self^.mins, dest);
  self^.moveinfo.state := STATE_TOP;
  VectorCopy (self^.s.origin, self^.moveinfo.start_origin);
  VectorCopy (dest, self^.moveinfo.end_origin);
  Move_Calc (self, dest, train_wait);
  self^.spawnflags := self^.spawnflags or TRAIN_START_ON;
end;

procedure train_resume (self:pedict_t);
var
  ent:pedict_t;
  dest:vec3_t;
begin
  ent := self^.target_ent;

  VectorSubtract (ent^.s.origin, self^.mins, dest);
  self^.moveinfo.state := STATE_TOP;
  VectorCopy (self^.s.origin, self^.moveinfo.start_origin);
  VectorCopy (dest, self^.moveinfo.end_origin);
  Move_Calc (self, dest, train_wait);
  self^.spawnflags := self^.spawnflags or TRAIN_START_ON;
end;

procedure func_train_find (self:pedict_t);
var
  ent:pedict_t;
begin
  if (not self^.target) then
  begin
    gi.dprintf ('train_find: no target\n');
    exit;
  end;
  ent := G_PickTarget (self^.target);
  if (not ent) then
  begin
    gi.dprintf ('train_find: target %s not found\n', self^.target);
    exit;
  end;
  self^.target := ent^.target;

  VectorSubtract (ent^.s.origin, self^.mins, self^.s.origin);
  gi.linkentity (self);

  // if not triggered, start immediately
  if (not self^.targetname) then
    self^.spawnflags := self^.spawnflags or TRAIN_START_ON;

  if (self^.spawnflags and TRAIN_START_ON) then
  begin
    self^.nextthink := level.time + FRAMETIME;
    self^.think := train_next;
    self^.activator := self;
  end;
end;

procedure train_use (self:pedict_t; other:pedict_t; activator:pedict_t);
begin
  self^.activator := activator;

  if (self^.spawnflags and TRAIN_START_ON) then
  begin
    if (not (self^.spawnflags and TRAIN_TOGGLE)) then
      exit;
    self^.spawnflags := self^.spawnflags and (not TRAIN_START_ON);
    VectorClear (self^.velocity);
    self^.nextthink := 0;
  end
  else
  begin
    if (self^.target_ent) then
      train_resume(self)
    else
      train_next(self);
  end;
end;

procedure SP_func_train (self:pedict_t);
begin
  self^.movetype := MOVETYPE_PUSH;

  VectorClear (self^.s.angles);
  self^.blocked := train_blocked;
  if (self^.spawnflags and TRAIN_BLOCK_STOPS) then
    self^.dmg := 0
  else
  begin
    if (not self^.dmg) then
      self^.dmg := 100;
  end;
  self^.solid := SOLID_BSP;
  gi.setmodel (self, self^.model);

  if (st.noise) then
    self^.moveinfo.sound_middle := gi.soundindex  (st.noise);

  if (not self^.speed) then
    self^.speed := 100;

  self^.moveinfo.speed := self^.speed;
  self^.moveinfo.accel := self^.moveinfo.decel := self^.moveinfo.speed;

  self^.use := train_use;

  gi.linkentity (self);

  if (self^.target) then
  begin
    // start trains on the second frame, to make sure their targets have had
    // a chance to spawn
    self^.nextthink := level.time + FRAMETIME;
    self^.think := func_train_find;
  end
  else
  begin
    gi.dprintf ('func_train without a target at %s\n', vtos(self^.absmin));
  end;
end;


(*QUAKED trigger_elevator (0.3 0.1 0.6) (-8 -8 -8) (8 8 8)
*)
procedure trigger_elevator_use (self:pedict_t; other:pedict_t; activator:pedict_t);
var
  target:pedict_t;
begin
  if (self^.movetarget^.nextthink)
  begin
//    gi.dprintf('elevator busy\n');
    exit;
  end

  if (not other^.pathtarget) then
  begin
    gi.dprintf('elevator used with no pathtarget\n');
    exit;
  end;

  target := G_PickTarget (other^.pathtarget);
  if (not target) then
  begin
    gi.dprintf('elevator used with bad pathtarget: %s\n', other^.pathtarget);
    exit;
  end;

  self^.movetarget^.target_ent := target;
  train_resume (self^.movetarget);
end;

procedure trigger_elevator_init (self:pedict_t);
begin
  if (not self^.target) then
  begin
    gi.dprintf('trigger_elevator has no target\n');
    exit;
  end;
  self^.movetarget := G_PickTarget (self^.target);
  if (not self^.movetarget) then
  begin
    gi.dprintf('trigger_elevator unable to find target %s\n', self^.target);
    exit;
  end;
  if (strcomp(self^.movetarget^.classname, 'func_train') not := 0) then
  begin
    gi.dprintf('trigger_elevator target %s is not a train\n', self^.target);
    exit;
  end;

  self^.use := trigger_elevator_use;
  self^.svflags := SVF_NOCLIENT;

end;

procedure SP_trigger_elevator (self:pedict_t);
begin
  self^.think := trigger_elevator_init;
  self^.nextthink := level.time + FRAMETIME;
end;


(*QUAKED func_timer (0.3 0.1 0.6) (-8 -8 -8) (8 8 8) START_ON
"wait"      base time between triggering all targets, default is 1
"random"    wait variance, default is 0

so, the basic time between firing is a random time between
(wait - random) and (wait + random)

"delay"      delay before first firing when turned on, default is 0

"pausetime"    additional delay used only the very first time
        and only if spawned with START_ON

These can used but not touched.
*)
procedure func_timer_think (self:pedict_t);
begin
  G_UseTargets (self, self^.activator);
  self^.nextthink := level.time + self^.wait + random * self^.random;
end;

procedure func_timer_use (self:pedict_t; other:pedict_t; activator:pedict_t);
begin
  self^.activator := activator;

  // if on, turn it off
  if (self^.nextthink) then
  begin
    self^.nextthink := 0;
    exit;
  end;

  // turn it on
  if (self^.delay) then
    self^.nextthink := level.time + self^.delay
  else
    func_timer_think (self);
end;

procedure SP_func_timer (self:pedict_t);
begin
  if (not self^.wait) then
    self^.wait := 1.0;

  self^.use := func_timer_use;
  self^.think := func_timer_think;

  if (self^.random >= self^.wait) then
  begin
    self^.random := self^.wait - FRAMETIME;
    gi.dprintf('func_timer at %s has random >= wait\n', vtos(self^.s.origin));
  end;

  if (self^.spawnflags and 1) then
  begin
    self^.nextthink := level.time + 1.0 + st.pausetime + self^.delay + self^.wait + random * self^.random;
    self^.activator := self;
  end;

  self^.svflags := SVF_NOCLIENT;
end;


(*QUAKED func_conveyor (0 .5 .8) ? START_ON TOGGLE
Conveyors are stationary brushes that move what's on them.
The brush should be have a surface with at least one current content enabled.
speed  default 100
*)

procedure func_conveyor_use (self:pedict_t; other:pedict_t; activator:pedict_t);
begin
  if (self^.spawnflags and 1) then
  begin
    self^.speed := 0;
    self^.spawnflags := self^.spawnflags and (not 1);
  end
  else
  begin
    self^.speed := self^.count;
    self^.spawnflags |:= 1;
  end;

  if (not (self^.spawnflags and 2)) then
    self^.count := 0;
end;

procedure SP_func_conveyor (self:pedict_t);
begin
  if (not self^.speed) then
    self^.speed := 100;

  if (not (self^.spawnflags and 1)) then
  begin
    self^.count := self^.speed;
    self^.speed := 0;
  end;

  self^.use := func_conveyor_use;

  gi.setmodel (self, self^.model);
  self^.solid := SOLID_BSP;
  gi.linkentity (self);
end;


(*QUAKED func_door_secret (0 .5 .8) ? always_shoot 1st_left 1st_down
A secret door.  Slide back and then to the side.

open_once    doors never closes
1st_left    1st move is left of arrow
1st_down    1st move is down from arrow
always_shoot  door is shootebale even if targeted

"angle"    determines the direction
"dmg"    damage to inflic when blocked (default 2)
"wait"    how long to hold in the open position (default 5, -1 means hold)
*)

const SECRET_ALWAYS_SHOOT =  1;
const SECRET_1ST_LEFT  =  2;
const SECRET_1ST_DOWN  =  4;



procedure door_secret_use (self:pedict_t; other:pedict_t; activator:pedict_t) then
begin
  // make sure we're not already moving
  if (not VectorCompare(self^.s.origin, vec3_origin)) then
    exit;

  Move_Calc (self, self^.pos1, door_secret_move1);
  door_use_areaportals (self, true);
end;

procedure door_secret_move1 (self:pedict_t);
begin
  self^.nextthink := level.time + 1.0;
  self^.think := door_secret_move2;
end;

procedure door_secret_move2 (self:pedict_t);
begin
  Move_Calc (self, self^.pos2, door_secret_move3);
end;

procedure door_secret_move3 (self:pedict_t);
begin
  if (self^.wait = -1) then
    exit;
  self^.nextthink := level.time + self^.wait;
  self^.think := door_secret_move4;
end;

procedure door_secret_move4 (self:pedict_t);
begin
  Move_Calc (self, self^.pos1, door_secret_move5);
end;

procedure door_secret_move5 (self:pedict_t);
begin
  self^.nextthink := level.time + 1.0;
  self^.think := door_secret_move6;
end;

procedure door_secret_move6 (self:pedict_t);
begin
  Move_Calc (self, vec3_origin, door_secret_done);
end;

procedure door_secret_done (self:pedict_t);
begin
  if (not (self^.targetname) or (self^.spawnflags and SECRET_ALWAYS_SHOOT))
  begin
    self^.health := 0;
    self^.takedamage := DAMAGE_YES;
  end;
  door_use_areaportals (self, false);
end;

procedure door_secret_blocked  (self:pedict_t; other:pedict_t);
begin
  if (not (other^.svflags and SVF_MONSTER) and (not other^.client) ) then
  begin
    // give it a chance to go away on it's own terms (like gibs)
    T_Damage (other, self, self, vec3_origin, other^.s.origin, vec3_origin, 100000, 1, 0, MOD_CRUSH);
    // if it's still there, nuke it
    if (other) then
      BecomeExplosion1 (other);
    exit;
  end;

  if (level.time < self^.touch_debounce_time) then
    exit;
  self^.touch_debounce_time := level.time + 0.5;

  T_Damage (other, self, self, vec3_origin, other^.s.origin, vec3_origin, self^.dmg, 1, 0, MOD_CRUSH);
end;

procedure door_secret_die (self:pedict_t;inflictor :pedict_t; attacker:pedict_t ; damage:smallint;point: vec3_t );
begin
  self^.takedamage := DAMAGE_NO;
  door_secret_use (self, attacker, attacker);
end;

procedure SP_func_door_secret (ent:pedict_t);
var
  forwards, right, up:vec3_t;
  side:single;
  width:single;
  length:single;
begin  
  ent^.moveinfo.sound_start := gi.soundindex  ('doors/dr1_strt.wav');
  ent^.moveinfo.sound_middle := gi.soundindex  ('doors/dr1_mid.wav');
  ent^.moveinfo.sound_end := gi.soundindex  ('doors/dr1_end.wav');

  ent^.movetype := MOVETYPE_PUSH;
  ent^.solid := SOLID_BSP;
  gi.setmodel (ent, ent^.model);

  ent^.blocked := door_secret_blocked;
  ent^.use := door_secret_use;

  if (not (ent^.targetname) or (ent^.spawnflags and SECRET_ALWAYS_SHOOT)) then
  begin
    ent^.health := 0;
    ent^.takedamage := DAMAGE_YES;
    ent^.die := door_secret_die;
  end;

  if (not ent^.dmg) then
    ent^.dmg := 2;

  if (not ent^.wait) then
    ent^.wait := 5;

  ent^.moveinfo.accel := 50;
  ent^.moveinfo.decel := 50;
  ent^.moveinfo.speed := 50;

  // calculate positions
  AngleVectors (ent^.s.angles, forwards, right, up);
  VectorClear (ent^.s.angles);
  side := 1.0 - (ent^.spawnflags and SECRET_1ST_LEFT);
  if (ent^.spawnflags and SECRET_1ST_DOWN) then
    width := abs(DotProduct(up, ent^.size))
  else
    width := abs(DotProduct(right, ent^.size));
  length := abs(DotProduct(forwards, ent^.size));
  if (ent^.spawnflags and SECRET_1ST_DOWN) then
    VectorMA (ent^.s.origin, -1 * width, up, ent^.pos1)
  else
    VectorMA (ent^.s.origin, side * width, right, ent^.pos1);
  VectorMA (ent^.pos1, length, forwards, ent^.pos2);

  if (ent^.health) then
  begin
    ent^.takedamage := DAMAGE_YES;
    ent^.die := door_killed;
    ent^.max_health := ent^.health;
  end
  else if (ent^.targetname and ent^.message) then
  begin
    gi.soundindex ('misc/talk.wav');
    ent^.touch := door_touch;
  end;
  
  ent^.classname := 'func_door';

  gi.linkentity (ent);
end;


(*QUAKED func_killbox (1 0 0) ?
Kills everything inside when fired, irrespective of protection.
*)
procedure use_killbox (self:pedict_t; other:pedict_t ;  activator:pedict_t);
begin
  KillBox (self);
end;

procedure SP_func_killbox (ent:pedict_t);
begin
  gi.setmodel (ent, ent^.model);
  ent^.use := use_killbox;
  ent^.svflags := SVF_NOCLIENT;
end;


end.
