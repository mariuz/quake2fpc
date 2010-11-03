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


(*
Copyright (C) 1997-2001 Id Software, Inc.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

*)
{******************************************************
   Name: g_func.pas
   Translator: you_known
   Description: a part of Quake 2 - Visual C to Delphi
                Conversion
   Date: 2002-02-03 16:43
   E-mail: you_known@163.com
******************************************************}

unit g_func;

interface

uses
  q_shared,
  GameUnit,
  g_local,
  g_combat,
  game_add,
  g_local_add,
  SysUtils;


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

const
  PLAT_LOW_TRIGGER = 1;

   STATE_TOP      =   0;
    STATE_BOTTOM    =   1;
  STATE_UP       =   2;
  STATE_DOWN     =   3;

    DOOR_START_OPEN   =   1;
  DOOR_REVERSE     =   2;
  DOOR_CRUSHER     =   4;
  DOOR_NOMONSTER   =   8;
  DOOR_TOGGLE       = 32;
  DOOR_X_AXIS       =   64;
  DOOR_Y_AXIS       =   128;

procedure Think_AccelMove (ent: edict_p); cdecl;

procedure plat_go_down (ent:edict_p); cdecl;

procedure door_go_down (self:edict_p); cdecl;

procedure train_next (self:edict_p); cdecl;

procedure train_use (self:edict_p; other:edict_p; activator:edict_p); cdecl;
procedure func_train_find (self:edict_p); cdecl;


procedure door_secret_move1 (self:edict_p); cdecl;
procedure door_secret_move2 (self:edict_p); cdecl;
procedure door_secret_move3 (self:edict_p); cdecl;
procedure door_secret_move4 (self:edict_p); cdecl;
procedure door_secret_move5 (self:edict_p); cdecl;
procedure door_secret_move6 (self:edict_p); cdecl;
procedure door_secret_done (self:edict_p); cdecl;

procedure SP_func_plat (ent:edict_p); cdecl;
procedure SP_func_button (ent:edict_p); cdecl;
procedure SP_func_door_rotating (ent:edict_p); cdecl;
procedure SP_func_rotating (ent:edict_p); cdecl;
procedure SP_func_door (ent:edict_p); cdecl;
procedure SP_func_water (self:edict_p); cdecl;
procedure SP_func_train (self:edict_p); cdecl;
procedure SP_func_timer (self:edict_p); cdecl;
procedure SP_func_conveyor (self:edict_p); cdecl;
procedure SP_func_door_secret (ent:edict_p); cdecl;
procedure SP_func_killbox (ent:edict_p); cdecl;
procedure SP_trigger_elevator (self:edict_p); cdecl;

implementation

uses
  g_misc,
  g_utils,
  g_save,
  g_main,
  q_shared_add;

//
// Support routines for movement (changes in origin using velocity)
//

procedure Move_Done (ent:edict_p); cdecl;
begin
   VectorClear (ent^.velocity);
   ent^.moveinfo.endfunc (ent);
end;

procedure Move_Final (ent:edict_p); cdecl;
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

procedure Move_Begin (ent:edict_p); cdecl;
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
   ent^.moveinfo.remaining_distance := ent^.moveinfo.remaining_distance - frames * ent^.moveinfo.speed * FRAMETIME;
   ent^.nextthink := level.time + (frames * FRAMETIME);
   ent^.think := Move_Final;
end;



procedure Move_Calc (ent: edict_p; const dest: vec3_t; Func : Proc_edit_s);
var
  tempEdict : edict_p;
begin
   VectorClear (ent^.velocity);
   VectorSubtract (dest, ent^.s.origin, ent^.moveinfo.dir);
   ent^.moveinfo.remaining_distance := VectorNormalize (ent^.moveinfo.dir);
   ent^.moveinfo.endfunc := func;

   if (ent^.moveinfo.speed = ent^.moveinfo.accel) and (ent^.moveinfo.speed = ent^.moveinfo.decel) then
   begin
    if (ent^.flags and FL_TEAMSLAVE) <> 0 then
      tempEdict := ent^.teammaster
    else
      tempEdict := ent;
      if (level.current_entity  = tempEdict) then
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

procedure AngleMove_Done (ent:edict_p); cdecl;
begin
   VectorClear (ent^.avelocity);
   ent^.moveinfo.endfunc (ent);
end;

procedure AngleMove_Final (ent:edict_p); cdecl;
var
   move:vec3_t;
begin
   if (ent^.moveinfo.state = STATE_UP) then
      VectorSubtract (ent^.moveinfo.end_angles, ent^.s.angles, move)
   else
      VectorSubtract (ent^.moveinfo.start_angles, ent^.s.angles, move);

   if (VectorCompare (move, vec3_origin) <> 0) then
   begin
      AngleMove_Done (ent);
      exit;
   end;

   VectorScale (move, 1.0/FRAMETIME, ent^.avelocity);

   ent^.think := AngleMove_Done;
   ent^.nextthink := level.time + FRAMETIME;
end;

procedure AngleMove_Begin (ent:edict_p); cdecl;
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

procedure AngleMove_Calc (ent:edict_p; func : Proc_edit_s);
var
  tempEdict : edict_p;
begin
   VectorClear (ent^.avelocity);
   ent^.moveinfo.endfunc := func;
  if (ent^.flags and FL_TEAMSLAVE) <> 0 then
    tempEdict := ent^.teammaster
  else
    tempEdict := ent;
   if (level.current_entity = tempEdict) then
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
function AccelerationDistance(target, rate : double):double;
begin
  Result := (target * ((target / rate) + 1) / 2);
end;

procedure plat_CalcAcceleratedMove(moveinfo:moveinfo_p);
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

procedure plat_Accelerate (moveinfo:moveinfo_p);
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
         if (moveinfo^.next_speed <> 0) then
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

procedure Think_AccelMove (ent:edict_p);
begin
   ent^.moveinfo.remaining_distance := ent^.moveinfo.remaining_distance - ent^.moveinfo.current_speed;

   if (ent^.moveinfo.current_speed = 0) then      // starting or blocked
      plat_CalcAcceleratedMove(@ent^.moveinfo);

   plat_Accelerate (@ent^.moveinfo);

   // will the entire move complete on next frame?
   if (ent^.moveinfo.remaining_distance <= ent^.moveinfo.current_speed) then
   begin
      Move_Final (ent);
      exit;
   end;

   VectorScale (ent^.moveinfo.dir, ent^.moveinfo.current_speed*10, ent^.velocity);
   ent^.nextthink := level.time + FRAMETIME;
   ent^.think := Think_AccelMove;
end;




procedure plat_hit_top (ent:edict_p); cdecl;
begin
   if ((ent^.flags and FL_TEAMSLAVE) = 0) then
   begin
      if (ent^.moveinfo.sound_end <> 0) then
         gi.sound (ent, CHAN_NO_PHS_ADD+CHAN_VOICE, ent^.moveinfo.sound_end, 1, ATTN_STATIC, 0);
      ent^.s.sound := 0;
   end;
   ent^.moveinfo.state := STATE_TOP;

   ent^.think := plat_go_down;
   ent^.nextthink := level.time + 3;
end;

procedure plat_hit_bottom (ent:edict_p); cdecl;
begin
   if ((ent^.flags and FL_TEAMSLAVE) = 0) then
   begin;
      if (ent^.moveinfo.sound_end <> 0) then
         gi.sound (ent, CHAN_NO_PHS_ADD+CHAN_VOICE, ent^.moveinfo.sound_end, 1, ATTN_STATIC, 0);
      ent^.s.sound := 0;
   end;
   ent^.moveinfo.state := STATE_BOTTOM;
end;

procedure plat_go_down (ent:edict_p);
begin
   if ((ent^.flags and FL_TEAMSLAVE) = 0) then
   begin
      if (ent^.moveinfo.sound_start <> 0) then
         gi.sound (ent, CHAN_NO_PHS_ADD+CHAN_VOICE, ent^.moveinfo.sound_start, 1, ATTN_STATIC, 0);
      ent^.s.sound := ent^.moveinfo.sound_middle;
   end;
   ent^.moveinfo.state := STATE_DOWN;
   Move_Calc (ent, ent^.moveinfo.end_origin, plat_hit_bottom);
end;

procedure plat_go_up (ent:edict_p);
begin
   if ((ent^.flags and FL_TEAMSLAVE) = 0) then
   begin
      if (ent^.moveinfo.sound_start <> 0) then
         gi.sound (ent, CHAN_NO_PHS_ADD+CHAN_VOICE, ent^.moveinfo.sound_start, 1, ATTN_STATIC, 0);
      ent^.s.sound := ent^.moveinfo.sound_middle;
   end;
   ent^.moveinfo.state := STATE_UP;
   Move_Calc (ent, ent^.moveinfo.start_origin, plat_hit_top);
end;

procedure plat_blocked (self:edict_p; other:edict_p); cdecl;
begin
   if ((other^.svflags and SVF_MONSTER = 0) and (other^.client = nil)) then
   begin
      // give it a chance to go away on it's own terms (like gibs)
      T_Damage (other, self, self, vec3_origin, other^.s.origin, vec3_origin, 100000, 1, 0, MOD_CRUSH);
      // if it's still there, nuke it
      if assigned(other) then
         BecomeExplosion1 (other);
      exit;
   end;

   T_Damage (other, self, self, vec3_origin, other^.s.origin, vec3_origin, self^.dmg, 1, 0, MOD_CRUSH);

   if (self^.moveinfo.state = STATE_UP) then
      plat_go_down (self)
   else if (self^.moveinfo.state = STATE_DOWN) then
      plat_go_up (self);
end;


procedure Use_Plat (ent:edict_p; other:edict_p;activator:edict_p); cdecl;
begin
   if assigned(ent^.think) then
      exit;      // already down
   plat_go_down (ent);
end;


procedure Touch_Plat_Center (ent:edict_p; other:edict_p; plane:cplane_p; surf:csurface_p); cdecl;
begin
   if (other^.client = nil) then
      exit;
      
   if (other^.health <= 0) then
      exit;

   ent := ent^.enemy;   // now point at the plat, not the trigger
   if (ent^.moveinfo.state = STATE_BOTTOM) then
      plat_go_up (ent)
   else if (ent^.moveinfo.state = STATE_TOP) then
      ent^.nextthink := level.time + 1;   // the player is still on the plat, so delay going down
end;

procedure plat_spawn_inside_trigger (ent:edict_p);
var
   trigger:edict_p;
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

   if (ent^.spawnflags and PLAT_LOW_TRIGGER) <> 0 then
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
speed   default 150

Plats are always drawn in the extended position, so they will light correctly.

If the plat is the target of another trigger or button, it will start out disabled in the extended position until it is trigger, when it will lower and become a normal plat.

"speed"   overrides default 200.
"accel" overrides default 500
"lip"   overrides default 8 pixel lip

If the "height" key is set, that will determine the amount the plat moves, instead of being implicitly determoveinfoned by the model's height.

Set "sounds" to one of the following:
1) base fast
2) chain slow
*)
procedure SP_func_plat (ent:edict_p);
begin
   VectorClear (ent^.s.angles);
   ent^.solid := SOLID_BSP;
   ent^.movetype := MOVETYPE_PUSH;

   gi.setmodel (ent, ent^.model);

   ent^.blocked := plat_blocked;

   if (ent^.speed = 0) then
      ent^.speed := 20
   else
      ent^.speed := ent^.speed * 0.1;

   if (ent^.accel=0) then
      ent^.accel := 5
   else
      ent^.accel := ent^.accel * 0.1;

   if (ent^.decel=0) then
      ent^.decel := 5
   else
      ent^.decel := ent^.decel * 0.1;

   if (ent^.dmg=0) then
      ent^.dmg := 2;

   if (st.lip=0) then
      st.lip := 8;

   // pos1 is the top position, pos2 is the bottom
   VectorCopy (ent^.s.origin, ent^.pos1);
   VectorCopy (ent^.s.origin, ent^.pos2);
   if (st.Height <> 0) then
      ent^.pos2[2] := ent^.pos2[2] - st.height
   else
      ent^.pos2[2] := ent^.pos2[2] - ((ent^.maxs[2] - ent^.mins[2]) - st.lip);

   ent^.use := Use_Plat;

   plat_spawn_inside_trigger (ent);   // the "start moving" trigger   

   if Assigned(ent^.targetname) then
   begin
      ent^.moveinfo.state := STATE_UP;
   end
   else
   begin
      VectorCopy (ent^.pos2, ent^.s.origin);
      gi.linkentity (ent);
      ent^.moveinfo.state := STATE_BOTTOM;
   end;

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
"dmg"   damage to inflict when blocked (2 default)

REVERSE will cause the it to rotate in the opposite direction.
STOP mean it will stop moving instead of pushing entities
*)

procedure rotating_blocked (self:edict_p; other:edict_p); cdecl;
begin
   T_Damage (other, self, self, vec3_origin, other^.s.origin, vec3_origin, self^.dmg, 1, 0, MOD_CRUSH);
end;

procedure rotating_touch (self:edict_p; other:edict_p; plane:cplane_p; surf:csurface_p); cdecl;
begin
   if (self^.avelocity[0] <> 0) or (self^.avelocity[1] <> 0 ) or (self^.avelocity[2] <> 0) then
      T_Damage (other, self, self, vec3_origin, other^.s.origin, vec3_origin, self^.dmg, 1, 0, MOD_CRUSH);
end;

procedure rotating_use (self:edict_p; other:edict_p;activator:edict_p); cdecl;
begin
   if (VectorCompare (self^.avelocity, vec3_origin) = 0) then
   begin
      self^.s.sound := 0;
      VectorClear (self^.avelocity);
      self^.touch := nil;
   end
   else
   begin
      self^.s.sound := self^.moveinfo.sound_middle;
      VectorScale (self^.movedir, self^.speed, self^.avelocity);
      if (self^.spawnflags and 16) <> 0 then
         self^.touch := rotating_touch;
   end;
end;

procedure SP_func_rotating (ent:edict_p);
begin
   ent^.solid := SOLID_BSP;
   if (ent^.spawnflags and 32) <> 0 then
      ent^.movetype := MOVETYPE_STOP
   else
      ent^.movetype := MOVETYPE_PUSH;

   // set the axis of rotation
   VectorClear(ent^.movedir);
   if (ent^.spawnflags and 4) <> 0 then
      ent^.movedir[2] := 1.0 
   else if (ent^.spawnflags and 8) <> 0 then
      ent^.movedir[0] := 1.0
   else // Z_AXIS
      ent^.movedir[1] := 1.0;

   // check for reverse rotation
   if (ent^.spawnflags and 2 ) <> 0 then
      VectorNegate (ent^.movedir, ent^.movedir);

   if (ent^.speed = 0)  then
      ent^.speed := 100;
   if (ent^.dmg = 0) then
      ent^.dmg := 2;

//   ent^.moveinfo.sound_middle := "doors/hydro1.wav";

   ent^.use := rotating_use;
   if (ent^.dmg <> 0) then
      ent^.blocked := rotating_blocked;

   if (ent^.spawnflags and 1) <> 0 then
      ent^.use (ent, nil, nil);

   if (ent^.spawnflags and 64) <> 0 then
      ent^.s.effects := ent^.s.effects or EF_ANIM_ALL;
   if (ent^.spawnflags and 128) <> 0 then
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

"angle"      determines the opening direction
"target"   all entities with a matching targetname will be used
"speed"      override the default 40 speed
"wait"      override the default 1 second wait (-1 := never exit)
"lip"      override the default 4 pixel lip remaining at end of move
"health"   if set, the button must be killed instead of touched
"sounds"
1) silent
2) steam metal
3) wooden clunk
4) metallic click
5) in-out
*)

procedure button_done (self:edict_p); cdecl;
begin
   self^.moveinfo.state := STATE_BOTTOM;
   self^.s.effects := self^.s.effects and not EF_ANIM23;
   self^.s.effects := self^.s.effects or EF_ANIM01;
end;

procedure button_exit (self:edict_p); cdecl;
begin
   self^.moveinfo.state := STATE_DOWN;

   Move_Calc (self, self^.moveinfo.start_origin, button_done);

   self^.s.frame := 0;

   if (self^.health <> 0) then
      self^.takedamage := DAMAGE_YES;
end;

procedure button_wait (self:edict_p); cdecl;
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

procedure button_fire (self:edict_p);
begin
   if (self^.moveinfo.state = STATE_UP) or (self^.moveinfo.state = STATE_TOP) then
      exit;

   self^.moveinfo.state := STATE_UP;
   if (self^.moveinfo.sound_start <> 0) and (self^.flags and FL_TEAMSLAVE=0) then
      gi.sound (self, CHAN_NO_PHS_ADD+CHAN_VOICE, self^.moveinfo.sound_start, 1, ATTN_STATIC, 0);
   Move_Calc (self, self^.moveinfo.end_origin, button_wait);
end;

procedure button_use (self:edict_p; other:edict_p;activator:edict_p); cdecl;
begin
   self^.activator := activator;
   button_fire (self);
end;

procedure button_touch (self:edict_p; other:edict_p; plane:cplane_p; surf:csurface_p); cdecl;
begin
   if not assigned(other^.client) then
      exit;

   if (other^.health <= 0) then
      exit;

   self^.activator := other;
   button_fire (self);
end;

procedure button_killed (self:edict_p; inflictor :edict_p; attacker:edict_p ; damage:integer; const point:vec3_t ); cdecl;
begin
   self^.activator := attacker;
   self^.health := self^.max_health;
   self^.takedamage := DAMAGE_NO;
   button_fire (self);
end;

procedure SP_func_button (ent:edict_p);
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
   
   if (ent^.speed = 0) then
      ent^.speed := 40;
   if (ent^.accel = 0) then
      ent^.accel := ent^.speed;
   if (ent^.decel = 0) then
      ent^.decel := ent^.speed;

   if (ent^.wait = 0) then
      ent^.wait := 3;
   if (st.lip = 0) then
      st.lip := 4;

   VectorCopy (ent^.s.origin, ent^.pos1);
   abs_movedir[0] := fabs(ent^.movedir[0]);
   abs_movedir[1] := fabs(ent^.movedir[1]);
   abs_movedir[2] := fabs(ent^.movedir[2]);
   dist := abs_movedir[0] * ent^.size[0] + abs_movedir[1] * ent^.size[1] + abs_movedir[2] * ent^.size[2] - st.lip;
   VectorMA (ent^.pos1, dist, ent^.movedir, ent^.pos2);

   ent^.use := button_use;
   ent^.s.effects := ent^.s.effects or EF_ANIM01;

   if (ent^.health <> 0) then
   begin
      ent^.max_health := ent^.health;
      ent^.die := button_killed;
      ent^.takedamage := DAMAGE_YES;
   end
   else if not assigned(ent^.targetname) then
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
  already targeted by another

======================================================================
*)

(*QUAKED func_door (0 .5 .8) ? START_OPEN x CRUSHER NOMONSTER ANIMATED TOGGLE ANIMATED_FAST
TOGGLE      wait in both the start and end states for a trigger event.
START_OPEN   the door to moves to its destination when spawned, and operate in reverse.  It is used to temporarily or permanently close off an area when triggered (not useful for touch or takedamage doors).
NOMONSTER   monsters will not trigger this door

"message"   is printed when the door is touched if it is a trigger door and it hasn't been fired yet
"angle"      determines the opening direction
"targetname" if set, no touch field will be spawned and a remote button or trigger field activates the door.
"health"   if set, door must be shot open
"speed"      movement speed (100 default)
"wait"      wait before exiting (3 default, -1 := never exit)
"lip"      lip remaining at end of move (8 default)
"dmg"      damage to inflict when blocked (2 default)
"sounds"
1)   silent
2)   light
3)   medium
4)   heavy
*)

procedure door_use_areaportals (self:edict_p;open:qboolean);
var
   t:edict_p;
begin
  t := nil;
   if not assigned(self^.target) then
      exit;
  t := G_Find (t, FOFS_targetname, self^.target);
   while Assigned(t) do
   begin
      if (Q_stricmp(t^.classname, 'func_areaportal') = 0) then
      begin
         gi.SetAreaPortalState (t^.style, open);
      end;
    t := G_Find (t, FOFS_targetname, self^.target);
   end;
end;



procedure door_hit_top (self:edict_p);  cdecl;
begin
   if ((self^.flags and FL_TEAMSLAVE)=0) then
   begin
      if (self^.moveinfo.sound_end <> 0) then
         gi.sound (self, CHAN_NO_PHS_ADD+CHAN_VOICE, self^.moveinfo.sound_end, 1, ATTN_STATIC, 0);
      self^.s.sound := 0;
   end;
   self^.moveinfo.state := STATE_TOP;
   if (self^.spawnflags and DOOR_TOGGLE) <> 0 then
      exit;
   if (self^.moveinfo.wait >= 0) then
   begin
      self^.think := door_go_down;
      self^.nextthink := level.time + self^.moveinfo.wait;
   end;
end;

procedure door_hit_bottom (self:edict_p); cdecl;
begin
   if ((self^.flags and FL_TEAMSLAVE) = 0) then
   begin
      if (self^.moveinfo.sound_end <> 0) then
         gi.sound (self, CHAN_NO_PHS_ADD+CHAN_VOICE, self^.moveinfo.sound_end, 1, ATTN_STATIC, 0);
      self^.s.sound := 0;
   end;
   self^.moveinfo.state := STATE_BOTTOM;
   door_use_areaportals (self, false);
end;

procedure door_go_down (self:edict_p);
begin
   if ((self^.flags and FL_TEAMSLAVE) = 0) then
   begin
      if (self^.moveinfo.sound_start <> 0) then
         gi.sound (self, CHAN_NO_PHS_ADD+CHAN_VOICE, self^.moveinfo.sound_start, 1, ATTN_STATIC, 0);
      self^.s.sound := self^.moveinfo.sound_middle;
   end;
   if (self^.max_health <> 0) then
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

procedure door_go_up (self:edict_p; activator:edict_p);
begin
   if (self^.moveinfo.state = STATE_UP) then
      exit;      // already going up

   if (self^.moveinfo.state = STATE_TOP) then
   begin   // reset top wait time
      if (self^.moveinfo.wait >= 0) then
         self^.nextthink := level.time + self^.moveinfo.wait;
      exit;
   end;

   if ((self^.flags and FL_TEAMSLAVE) = 0) then
   begin
      if (self^.moveinfo.sound_start <> 0) then
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

procedure door_use (self:edict_p; other:edict_p;activator:edict_p); cdecl;
var
   ent:edict_p;
begin
   if (self^.flags and FL_TEAMSLAVE <> 0) then
      exit;

   if (self^.spawnflags and DOOR_TOGGLE <> 0) then
   begin
      if (self^.moveinfo.state = STATE_UP) or (self^.moveinfo.state = STATE_TOP) then
      begin
         // trigger all paired doors
      ent := Self;
         while Assigned(ent) do
         begin
            ent^._message := nil;
            ent^.touch := nil;
            door_go_down (ent);
            ent := ent^.teamchain;
         end;
         exit;
      end;
   end;

   // trigger all paired doors
  ent := Self;
   while Assigned(ent) do
   begin
      ent^._message := nil;
      ent^.touch := nil;
      door_go_up (ent, activator);
      ent := ent^.teamchain;
   end;
end;

procedure Touch_DoorTrigger (self:edict_p; other:edict_p; plane:cplane_p; surf:csurface_p); cdecl;
begin
   if (other^.health <= 0) then
      exit;

   if ((other^.svflags and SVF_MONSTER=0) and (not Assigned(other^.client))) then
      exit;

   if ((self^.owner^.spawnflags and DOOR_NOMONSTER<>0) and (other^.svflags and SVF_MONSTER<>0)) then
      exit;

   if (level.time < self^.touch_debounce_time) then
      exit;
   self^.touch_debounce_time := level.time + 1.0;

   door_use (self^.owner, other, other);
end;

procedure Think_CalcMoveSpeed (self:edict_p); cdecl;
var
   ent:edict_p;
   min:single;
   time:single;
   newspeed:single;
   ratio:single;
   dist:single;
begin
   if (self^.flags and FL_TEAMSLAVE<>0) then
      exit;      // only the team master does this

   // find the smallest distance any member of the team will be moving
   min := fabs(self^.moveinfo.distance);
  ent := self^.teamchain;
   while Assigned(ent) do
   begin
      dist := fabs(ent^.moveinfo.distance);
      if (dist < min) then
         min := dist;
      ent := ent^.teamchain;
   end;

   time := min / self^.moveinfo.speed;

   // adjust speeds so they will all complete at the same time
  ent := Self;
   while Assigned(ent) do
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
         ent^.moveinfo.decel := ent^.moveinfo.decel * ratio;
      ent^.moveinfo.speed := newspeed;
      ent := ent^.teamchain;
   end;
end;

procedure Think_SpawnDoorTrigger (ent:edict_p); cdecl;
var
   other:edict_p;
   mins,maxs:vec3_t;
begin
   if (ent^.flags and FL_TEAMSLAVE<>0) then
      exit;      // only the team leader spawns a trigger

   VectorCopy (ent^.absmin, mins);
   VectorCopy (ent^.absmax, maxs);

  other := ent^.teamchain;
   while Assigned(other) do
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

   if (ent^.spawnflags and DOOR_START_OPEN) <> 0 then
      door_use_areaportals (ent, true);

   Think_CalcMoveSpeed (ent);
end;

procedure door_blocked  (self:edict_p; other:edict_p); cdecl;
var
   ent:edict_p;
begin
   if ((other^.svflags and SVF_MONSTER=0) and (not Assigned(other^.client))) then
   begin
      // give it a chance to go away on it's own terms (like gibs)
      T_Damage (other, self, self, vec3_origin, other^.s.origin, vec3_origin, 100000, 1, 0, MOD_CRUSH);
      // if it's still there, nuke it
      if Assigned(other) then
         BecomeExplosion1 (other);
      exit;
   end;

   T_Damage (other, self, self, vec3_origin, other^.s.origin, vec3_origin, self^.dmg, 1, 0, MOD_CRUSH);

   if (self^.spawnflags and DOOR_CRUSHER<>0) then
      exit;


// if a door has a negative wait, it would never come back if blocked,
// so let it just squash the object to death real fast
   if (self^.moveinfo.wait >= 0) then
   begin
      if (self^.moveinfo.state = STATE_DOWN) then
      begin
      ent := self^.teammaster;
         while Assigned(ent) do
         begin
            door_go_up (ent, ent^.activator);
            ent := ent^.teamchain;
         end;
      end
      else
      begin
      ent := self^.teammaster;
         while Assigned(ent) do
         begin
            door_go_down (ent);
            ent := ent^.teamchain;
         end;
      end;
   end;
end;

procedure door_killed (self:edict_p; inflictor:edict_p ; attacker:edict_p ; damage:Integer; const point:vec3_t ); cdecl;
var
   ent:edict_p;
begin
  ent := self^.teammaster;
   while Assigned(ent) do
   begin

      ent^.health := ent^.max_health;
      ent^.takedamage := DAMAGE_NO;
      ent:=ent^.teamchain;
   end;
   door_use (self^.teammaster, attacker, attacker);
end;

procedure door_touch (self:edict_p; other:edict_p; plane:cplane_p; surf:csurface_p); cdecl;
begin
   if not Assigned(other^.client) then
      exit;

   if (level.time < self^.touch_debounce_time) then
      exit;
   self^.touch_debounce_time := level.time + 5.0;

   gi.centerprintf (other, '%s', self^._message);
   gi.sound (other, CHAN_AUTO, gi.soundindex ('misc/talk1.wav'), 1, ATTN_NORM, 0);
end;

procedure SP_func_door (ent:edict_p);
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

   if (ent^.speed = 0) then
      ent^.speed := 100;
   if (deathmatch^.Value <> 0) then
      ent^.speed := ent^.speed  * 2;

   if (ent^.accel = 0) then
      ent^.accel := ent^.speed;
   if (ent^.decel = 0) then
      ent^.decel := ent^.speed;

   if (ent^.wait = 0) then
      ent^.wait := 3;
   if (st.lip = 0) then
      st.lip := 8;
   if (ent^.dmg = 0) then
      ent^.dmg := 2;

   // calculate second position
   VectorCopy (ent^.s.origin, ent^.pos1);
   abs_movedir[0] := fabs(ent^.movedir[0]);
   abs_movedir[1] := fabs(ent^.movedir[1]);
   abs_movedir[2] := fabs(ent^.movedir[2]);
   ent^.moveinfo.distance := abs_movedir[0] * ent^.size[0] + abs_movedir[1] * ent^.size[1] + abs_movedir[2] * ent^.size[2] - st.lip;
   VectorMA (ent^.pos1, ent^.moveinfo.distance, ent^.movedir, ent^.pos2);

   // if it starts open, switch the positions
   if (ent^.spawnflags and DOOR_START_OPEN) <> 0 then
   begin
      VectorCopy (ent^.pos2, ent^.s.origin);
      VectorCopy (ent^.pos1, ent^.pos2);
      VectorCopy (ent^.s.origin, ent^.pos1);
   end;

   ent^.moveinfo.state := STATE_BOTTOM;

   if (ent^.health) <> 0 then
   begin
      ent^.takedamage := DAMAGE_YES;
      ent^.die := door_killed;
      ent^.max_health := ent^.health;
   end
   else if Assigned(ent^.targetname) and Assigned(ent^._message) then
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

   if (ent^.spawnflags and 16) <> 0 then
      ent^.s.effects := ent^.s.effects or EF_ANIM_ALL;
   if (ent^.spawnflags and 64) <> 0 then
      ent^.s.effects := ent^.s.effects or EF_ANIM_ALLFAST;

   // to simplify logic elsewhere, make non-teamed doors into a team of one
   if not assigned(ent^.team) then
      ent^.teammaster := ent;

   gi.linkentity (ent);

   ent^.nextthink := level.time + FRAMETIME;
   if (ent^.health <> 0) or assigned(ent^.targetname) then
      ent^.think := Think_CalcMoveSpeed
   else
      ent^.think := Think_SpawnDoorTrigger;
end;


(*QUAKED func_door_rotating (0 .5 .8) ? START_OPEN REVERSE CRUSHER NOMONSTER ANIMATED TOGGLE X_AXIS Y_AXIS
TOGGLE causes the door to wait in both the start and end states for a trigger event.

START_OPEN   the door to moves to its destination when spawned, and operate in reverse.  It is used to temporarily or permanently close off an area when triggered (not useful for touch or takedamage doors).
NOMONSTER   monsters will not trigger this door

You need to have an origin brush as part of this entity.  The center of that brush will be
the point around which it is rotated. It will rotate around the Z axis by default.  You can
check either the X_AXIS or Y_AXIS box to change that.

"distance" is how many degrees the door will be rotated.
"speed" determines how fast the door moves; default value is 100.

REVERSE will cause the door to rotate in the opposite direction.

"message"   is printed when the door is touched if it is a trigger door and it hasn't been fired yet
"angle"      determines the opening direction
"targetname" if set, no touch field will be spawned and a remote button or trigger field activates the door.
"health"   if set, door must be shot open
"speed"      movement speed (100 default)
"wait"      wait before exiting (3 default, -1 := never exit)
"dmg"      damage to inflict when blocked (2 default)
"sounds"
1)   silent
2)   light
3)   medium
4)   heavy
*)

procedure SP_func_door_rotating (ent:edict_p);
begin
   VectorClear (ent^.s.angles);

   // set the axis of rotation
   VectorClear(ent^.movedir);
   if (ent^.spawnflags and DOOR_X_AXIS) <> 0 then
      ent^.movedir[2] := 1.0
   else if (ent^.spawnflags and DOOR_Y_AXIS) <> 0 then
      ent^.movedir[0] := 1.0
   else // Z_AXIS
      ent^.movedir[1] := 1.0;

   // check for reverse rotation
   if (ent^.spawnflags and DOOR_REVERSE) <> 0 then
      VectorNegate (ent^.movedir, ent^.movedir);

   if st.distance = 0 then
   begin
      gi.dprintf('%s at %s with no distance set'#10, ent^.classname, vtos(ent^.s.origin));
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

   if (ent^.speed = 0) then
      ent^.speed := 100;
   if (ent^.accel = 0) then
      ent^.accel := ent^.speed;
   if (ent^.decel = 0) then
      ent^.decel := ent^.speed;

   if (ent^.wait = 0) then
      ent^.wait := 3;
   if (ent^.dmg = 0) then
      ent^.dmg := 2;

   if (ent^.sounds <> 1) then
   begin
      ent^.moveinfo.sound_start := gi.soundindex  ('doors/dr1_strt.wav');
      ent^.moveinfo.sound_middle := gi.soundindex  ('doors/dr1_mid.wav');
      ent^.moveinfo.sound_end := gi.soundindex  ('doors/dr1_end.wav');
   end;

   // if it starts open, switch the positions
   if (ent^.spawnflags and DOOR_START_OPEN) <> 0 then
   begin
      VectorCopy (ent^.pos2, ent^.s.angles);
      VectorCopy (ent^.pos1, ent^.pos2);
      VectorCopy (ent^.s.angles, ent^.pos1);
      VectorNegate (ent^.movedir, ent^.movedir);
   end;

   if (ent^.health) <> 0 then
   begin
      ent^.takedamage := DAMAGE_YES;
      ent^.die := door_killed;
      ent^.max_health := ent^.health;
   end;

   if assigned(ent^.targetname) and assigned(ent^._message) then
   begin
      gi.soundindex ('misc/talk.wav');
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

   if (ent^.spawnflags and 16) <> 0 then
      ent^.s.effects := ent^.s.effects or EF_ANIM_ALL;

   // to simplify logic elsewhere, make non-teamed doors into a team of one
   if not Assigned(ent^.team) then
      ent^.teammaster := ent;

   gi.linkentity (ent);

   ent^.nextthink := level.time + FRAMETIME;
   if (ent^.health <> 0) or Assigned(ent^.targetname) then
      ent^.think := Think_CalcMoveSpeed
   else
      ent^.think := Think_SpawnDoorTrigger;
end;


(*QUAKED func_water (0 .5 .8) ? START_OPEN
func_water is a moveable water brush.  It must be targeted to operate.  Use a non-water texture at your own risk.

START_OPEN causes the water to move to its destination when spawned and operate in reverse.

"angle"      determines the opening direction (up or down only)
"speed"      movement speed (25 default)
"wait"      wait before exiting (-1 default, -1 := TOGGLE)
"lip"      lip remaining at end of move (0 default)
"sounds"   (yes, these need to be changed)
0)   no sound
1)   water
2)   lava
*)

procedure SP_func_water (self:edict_p);
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
//         break;
                 end;
       2: // lava
       begin
         self^.moveinfo.sound_start := gi.soundindex  ('world/mov_watr.wav');
         self^.moveinfo.sound_end := gi.soundindex  ('world/stp_watr.wav');
//         break;
       end;
//                 else break;
   end;

   // calculate second position
   VectorCopy (self^.s.origin, self^.pos1);
   abs_movedir[0] := abs(self^.movedir[0]);
   abs_movedir[1] := abs(self^.movedir[1]);
   abs_movedir[2] := abs(self^.movedir[2]);
   self^.moveinfo.distance := abs_movedir[0] * self^.size[0] + abs_movedir[1] * self^.size[1] + abs_movedir[2] * self^.size[2] - st.lip;
   VectorMA (self^.pos1, self^.moveinfo.distance, self^.movedir, self^.pos2);

   // if it starts open, switch the positions
   if (self^.spawnflags and DOOR_START_OPEN) <> 0 then
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

   if (self^.speed = 0) then
      self^.speed := 25;
   self^.moveinfo.speed := self^.speed;
   self^.moveinfo.decel := self^.moveinfo.speed;
   self^.moveinfo.accel := self^.moveinfo.decel;

   if (self^.wait = 0) then
      self^.wait := -1;
   self^.moveinfo.wait := self^.wait;

   self^.use := door_use;

   if (self^.wait = -1) then
      self^.spawnflags := self^.spawnflags or DOOR_TOGGLE;

   self^.classname := 'func_door';

   gi.linkentity (self);
end;


const
  TRAIN_START_ON      = 1;
  TRAIN_TOGGLE        = 2;
  TRAIN_BLOCK_STOPS    = 4;

(*QUAKED func_train (0 .5 .8) ? START_ON TOGGLE BLOCK_STOPS
Trains are moving platforms that players can ride.
The targets origin specifies the min point of the train at each corner.
The train spawns at the first target it is pointing at.
If the train is the target of a button or trigger, it will not begin moving until activated.
speed   default 100
dmg      default   2
noise   looping sound to play when the train is in motion

*)


procedure train_blocked (self:edict_p; other:edict_p); cdecl;
begin
   if ((other^.svflags and SVF_MONSTER=0) and (not Assigned(other^.client))) then
   begin
      // give it a chance to go away on it's own terms (like gibs)
      T_Damage (other, self, self, vec3_origin, other^.s.origin, vec3_origin, 100000, 1, 0, MOD_CRUSH);
      // if it's still there, nuke it
      if assigned(other) then
         BecomeExplosion1 (other);
      exit;
   end;

   if (level.time < self^.touch_debounce_time) then
      exit;

   if (self^.dmg=0) then
      exit;
   self^.touch_debounce_time := level.time + 0.5;
   T_Damage (other, self, self, vec3_origin, other^.s.origin, vec3_origin, self^.dmg, 1, 0, MOD_CRUSH);
end;

procedure train_wait (self:edict_p); cdecl;
var
      savetarget:pchar;
      ent:edict_p;
begin
   if assigned(self^.target_ent^.pathtarget) then
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

   if (self^.moveinfo.wait<>0) then
   begin
      if (self^.moveinfo.wait > 0) then
      begin
         self^.nextthink := level.time + self^.moveinfo.wait;
         self^.think := train_next;
      end
      else if (self^.spawnflags and TRAIN_TOGGLE) <> 0 then  // && wait < 0
      begin
         train_next (self);
         self^.spawnflags := self^.spawnflags and not TRAIN_START_ON;
         VectorClear (self^.velocity);
         self^.nextthink := 0;
      end;

      if ((self^.flags and FL_TEAMSLAVE)=0) then
      begin
         if (self^.moveinfo.sound_end <> 0) then
            gi.sound (self, CHAN_NO_PHS_ADD+CHAN_VOICE, self^.moveinfo.sound_end, 1, ATTN_STATIC, 0);
         self^.s.sound := 0;
      end;
   end
   else
   begin
      train_next (self);
   end;

end;

procedure train_next (self:edict_p);
label again;
var
   ent:edict_p;
   dest:vec3_t;
   first:qboolean;
begin
   first := true;
again:
   if not Assigned(self^.target) then
   begin
//      gi.dprintf ('train_next: no next target\n');
      exit;
   end;

   ent := G_PickTarget (self^.target);
   if not Assigned(ent) then
   begin
      gi.dprintf ('train_next: bad target %s'#10, self^.target);
      exit;
   end;

   self^.target := ent^.target;

   // check for a teleport path_corner
   if (ent^.spawnflags and 1) <> 0 then
   begin
      if (not first) then
      begin
         gi.dprintf ('connected teleport path_corners, see %s at %s'#10, ent^.classname, vtos(ent^.s.origin));
         Exit;
      end;
      first := false;
      VectorSubtract (ent^.s.origin, self^.mins, self^.s.origin);
      VectorCopy (self^.s.origin, self^.s.old_origin);
      self^.s.event := EV_OTHER_TELEPORT;
      gi.linkentity (self);
      goto again;
   end;

   self^.moveinfo.wait := ent^.wait;
   self^.target_ent := ent;

   if ((self^.flags and FL_TEAMSLAVE)=0) then
   begin
      if (self^.moveinfo.sound_start) <> 0 then
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

procedure train_resume (self:edict_p);
var
   ent:edict_p;
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

procedure func_train_find (self:edict_p);
var
   ent:edict_p;
begin
   if not Assigned(self^.target) then
   begin
      gi.dprintf ('train_find: no target'#10);
      exit;
   end;
   ent := G_PickTarget (self^.target);
   if not Assigned(ent) then
   begin
      gi.dprintf ('train_find: target %s not found'#10, self^.target);
      exit;
   end;
   self^.target := ent^.target;

   VectorSubtract (ent^.s.origin, self^.mins, self^.s.origin);
   gi.linkentity (self);

   // if not triggered, start immediately
   if not Assigned(self^.targetname) then
      self^.spawnflags := self^.spawnflags or TRAIN_START_ON;

   if (self^.spawnflags and TRAIN_START_ON) <> 0 then
   begin
      self^.nextthink := level.time + FRAMETIME;
      self^.think := train_next;
      self^.activator := self;
   end;
end;

procedure train_use (self:edict_p; other:edict_p; activator:edict_p);
begin
   self^.activator := activator;

   if (self^.spawnflags and TRAIN_START_ON) <> 0 then
   begin
      if ((self^.spawnflags and TRAIN_TOGGLE)=0) then
         exit;
      self^.spawnflags := self^.spawnflags and (not TRAIN_START_ON);
      VectorClear (self^.velocity);
      self^.nextthink := 0;
   end
   else
   begin
      if assigned(self^.target_ent) then
         train_resume(self)
      else
         train_next(self);
   end;
end;

procedure SP_func_train (self:edict_p);
begin
   self^.movetype := MOVETYPE_PUSH;

   VectorClear (self^.s.angles);
   self^.blocked := train_blocked;
   if (self^.spawnflags and TRAIN_BLOCK_STOPS) <> 0 then
      self^.dmg := 0
   else
   begin
      if (self^.dmg=0) then
         self^.dmg := 100;
   end;
   self^.solid := SOLID_BSP;
   gi.setmodel (self, self^.model);

   if assigned(st.noise) then
      self^.moveinfo.sound_middle := gi.soundindex  (st.noise);

   if (self^.speed=0) then
      self^.speed := 100;

   self^.moveinfo.speed := self^.speed;
   self^.moveinfo.decel := self^.moveinfo.speed;
  self^.moveinfo.accel := self^.moveinfo.decel;

   self^.use := train_use;

   gi.linkentity (self);

   if Assigned(self^.target) then
   begin
      // start trains on the second frame, to make sure their targets have had
      // a chance to spawn
      self^.nextthink := level.time + FRAMETIME;
      self^.think := func_train_find;
   end
   else
   begin
      gi.dprintf ('func_train without a target at %s'#10, vtos(self^.absmin));
   end;
end;


(*QUAKED trigger_elevator (0.3 0.1 0.6) (-8 -8 -8) (8 8 8)
*)
procedure trigger_elevator_use (self:edict_p; other:edict_p; activator:edict_p); cdecl;
var
   target:edict_p;
begin
   if (self^.movetarget^.nextthink <> 0) then
   begin
  // next line was originaly commented - burnin
//      gi.dprintf('elevator busy\n');
      exit;
   end;

   if not Assigned(other^.pathtarget) then
   begin
      gi.dprintf('elevator used with no pathtarget'#10);
      exit;
   end;

   target := G_PickTarget (other^.pathtarget);
   if not Assigned(target) then
   begin
      gi.dprintf('elevator used with bad pathtarget: %s'#10, other^.pathtarget);
      exit;
   end;

   self^.movetarget^.target_ent := target;
   train_resume (self^.movetarget);
end;

procedure trigger_elevator_init (self:edict_p); cdecl;
begin
   if not Assigned(self^.target) then
   begin
      gi.dprintf('trigger_elevator has no target'#10);
      exit;
   end;
   self^.movetarget := G_PickTarget (self^.target);
   if not Assigned(self^.movetarget) then
   begin
      gi.dprintf('trigger_elevator unable to find target %s'#10, self^.target);
      exit;
   end;
   if (strcomp(self^.movetarget^.classname, 'func_train') <> 0) then
   begin
      gi.dprintf('trigger_elevator target %s is not a train'#10, self^.target);
      exit;
   end;

   self^.use := trigger_elevator_use;
   self^.svflags := SVF_NOCLIENT;

end;

procedure SP_trigger_elevator (self:edict_p);
begin
   self^.think := trigger_elevator_init;
   self^.nextthink := level.time + FRAMETIME;
end;


(*QUAKED func_timer (0.3 0.1 0.6) (-8 -8 -8) (8 8 8) START_ON
"wait"         base time between triggering all targets, default is 1
"random"      wait variance, default is 0

so, the basic time between firing is a random time between
(wait - random) and (wait + random)

"delay"         delay before first firing when turned on, default is 0

"pausetime"      additional delay used only the very first time
            and only if spawned with START_ON

These can used but not touched.
*)
procedure func_timer_think (self:edict_p); cdecl;
begin
   G_UseTargets (self, self^.activator);
   self^.nextthink := level.time + self^.wait + crandom * self^.random;
end;

procedure func_timer_use (self:edict_p; other:edict_p; activator:edict_p); cdecl;
begin
   self^.activator := activator;

   // if on, turn it off
   if (self^.nextthink <> 0) then
   begin
      self^.nextthink := 0;
      exit;
   end;

   // turn it on
   if (self^.delay <> 0) then
      self^.nextthink := level.time + self^.delay
   else
      func_timer_think (self);
end;

procedure SP_func_timer (self:edict_p);
begin
   if (self^.wait = 0) then
      self^.wait := 1.0;

   self^.use := func_timer_use;
   self^.think := func_timer_think;

   if (self^.random >= self^.wait) then
   begin
      self^.random := self^.wait - FRAMETIME;
      gi.dprintf('func_timer at %s has random >= wait'#10, vtos(self^.s.origin));
   end;

   if (self^.spawnflags and 1) <> 0 then
   begin
      self^.nextthink := level.time + 1.0 + st.pausetime + self^.delay + self^.wait + crandom() * self^.random;
      self^.activator := self;
   end;

   self^.svflags := SVF_NOCLIENT;
end;


(*QUAKED func_conveyor (0 .5 .8) ? START_ON TOGGLE
Conveyors are stationary brushes that move what's on them.
The brush should be have a surface with at least one current content enabled.
speed   default 100
*)

procedure func_conveyor_use (self:edict_p; other:edict_p; activator:edict_p); cdecl;
begin
   if (self^.spawnflags and 1) <> 0 then
   begin
      self^.speed := 0;
      self^.spawnflags := self^.spawnflags and (not 1);
   end
   else
   begin
      self^.speed := self^.count;
      self^.spawnflags := self^.spawnflags or 1;
   end;

   if (self^.spawnflags and 2) = 0 then
      self^.count := 0;
end;

procedure SP_func_conveyor (self:edict_p);
begin
   if (self^.speed = 0) then
      self^.speed := 100;

   if ((self^.spawnflags and 1)=0) then
   begin
      self^.count := trunc(self^.speed);
      self^.speed := 0;
   end;

   self^.use := func_conveyor_use;

   gi.setmodel (self, self^.model);
   self^.solid := SOLID_BSP;
   gi.linkentity (self);
end;


(*QUAKED func_door_secret (0 .5 .8) ? always_shoot 1st_left 1st_down
A secret door.  Slide back and then to the side.

open_once      doors never closes
1st_left      1st move is left of arrow
1st_down      1st move is down from arrow
always_shoot   door is shootebale even if targeted

"angle"      determines the direction
"dmg"      damage to inflic when blocked (default 2)
"wait"      how long to hold in the open position (default 5, -1 means hold)
*)

const SECRET_ALWAYS_SHOOT =   1;
const SECRET_1ST_LEFT   =   2;
const SECRET_1ST_DOWN   =   4;



procedure door_secret_use (self:edict_p; other:edict_p; activator:edict_p); cdecl;
begin
   // make sure we're not already moving
   if (VectorCompare(self^.s.origin, vec3_origin)=0) then
      exit;

   Move_Calc (self, self^.pos1, door_secret_move1);
   door_use_areaportals (self, true);
end;

procedure door_secret_move1 (self:edict_p);
begin
   self^.nextthink := level.time + 1.0;
   self^.think := door_secret_move2;
end;

procedure door_secret_move2 (self:edict_p);
begin
   Move_Calc (self, self^.pos2, door_secret_move3);
end;

procedure door_secret_move3 (self:edict_p);
begin
   if (self^.wait = -1) then
      exit;
   self^.nextthink := level.time + self^.wait;
   self^.think := door_secret_move4;
end;

procedure door_secret_move4 (self:edict_p);
begin
   Move_Calc (self, self^.pos1, door_secret_move5);
end;

procedure door_secret_move5 (self:edict_p);
begin
   self^.nextthink := level.time + 1.0;
   self^.think := door_secret_move6;
end;

procedure door_secret_move6 (self:edict_p);
begin
   Move_Calc (self, vec3_origin, door_secret_done);
end;

procedure door_secret_done (self:edict_p);
begin
   if (not assigned(self^.targetname) or (self^.spawnflags and SECRET_ALWAYS_SHOOT<>0)) then
   begin
      self^.health := 0;
      self^.takedamage := DAMAGE_YES;
   end;
   door_use_areaportals (self, false);
end;

procedure door_secret_blocked  (self:edict_p; other:edict_p); cdecl;
begin
   if ((other^.svflags and SVF_MONSTER=0) and (not Assigned(other^.client))) then
   begin
      // give it a chance to go away on it's own terms (like gibs)
      T_Damage (other, self, self, vec3_origin, other^.s.origin, vec3_origin, 100000, 1, 0, MOD_CRUSH);
      // if it's still there, nuke it
      if assigned(other) then
         BecomeExplosion1 (other);
      exit;
   end;

   if (level.time < self^.touch_debounce_time) then
      exit;
   self^.touch_debounce_time := level.time + 0.5;

   T_Damage (other, self, self, vec3_origin, other^.s.origin, vec3_origin, self^.dmg, 1, 0, MOD_CRUSH);
end;

procedure door_secret_die (self:edict_p;inflictor :edict_p; attacker:edict_p ; damage:integer; const point: vec3_t ); cdecl;
begin
   self^.takedamage := DAMAGE_NO;
   door_secret_use (self, attacker, attacker);
end;

procedure SP_func_door_secret (ent:edict_p);
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

   if (not assigned(ent^.targetname) or (ent^.spawnflags and SECRET_ALWAYS_SHOOT<>0)) then
   begin
      ent^.health := 0;
      ent^.takedamage := DAMAGE_YES;
      ent^.die := door_secret_die;
   end;

   if (ent^.dmg = 0) then
      ent^.dmg := 2;

   if (ent^.wait=0) then
      ent^.wait := 5;

   ent^.moveinfo.accel := 50;
   ent^.moveinfo.decel := 50;
   ent^.moveinfo.speed := 50;

   // calculate positions
   AngleVectors (ent^.s.angles, @forwards, @right, @up);
   VectorClear (ent^.s.angles);
   side := 1.0 - (ent^.spawnflags and SECRET_1ST_LEFT);
   if (ent^.spawnflags and SECRET_1ST_DOWN) <> 0 then
      width := fabs(DotProduct(up, ent^.size))
   else
      width := fabs(DotProduct(right, ent^.size));
   length := fabs(DotProduct(forwards, ent^.size));
   if (ent^.spawnflags and SECRET_1ST_DOWN) <> 0 then
      VectorMA (ent^.s.origin, -1 * width, up, ent^.pos1)
   else
      VectorMA (ent^.s.origin, side * width, right, ent^.pos1);
   VectorMA (ent^.pos1, length, forwards, ent^.pos2);

   if (ent^.health) <> 0 then
   begin
      ent^.takedamage := DAMAGE_YES;
      ent^.die := door_killed;
      ent^.max_health := ent^.health;
   end
   else if assigned(ent^.targetname) and assigned(ent^._message) then
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
procedure use_killbox (self:edict_p; other:edict_p ;  activator:edict_p); cdecl;
begin
   KillBox (self);
end;

procedure SP_func_killbox (ent:edict_p);
begin
   gi.setmodel (ent, ent^.model);
   ent^.use := use_killbox;
   ent^.svflags := SVF_NOCLIENT;
end;


end.
