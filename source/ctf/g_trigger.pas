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
{ File(s): g_trigger.c                                                       }
{                                                                            }
{ Initial conversion by : you_known                                          }
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
{ Updated on :                                                               }
{ Updated by :                                                               }
{                                                                            }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{                                                                            }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{                                                                            }
{----------------------------------------------------------------------------}

unit g_trigger;

interface

uses g_local,SysUtils;

type pedict_t = ^edict_t;
     pcplane_t = ^cplane_t;
     pcsurface_t = ^csurface_t;
     
implementation

procedure InitTrigger (self:pedict_t);
begin
   if (not VectorCompare (self^.s.angles, vec3_origin)) then
      G_SetMovedir (self^.s.angles, self^.movedir);

   self^.solid := SOLID_TRIGGER;
   self^.movetype := MOVETYPE_NONE;
   gi.setmodel (self, self^.model);
   self^.svflags := SVF_NOCLIENT;
end;


// the wait time has passed, so set back up for another activation
procedure multi_wait (ent:pedict_t);
begin
   ent^.nextthink := 0;
end;


// the trigger was just activated
// ent->activator should be set to the activator so it can be held through a delay
// so wait for the delay time before firing
procedure multi_trigger (ent:pedict_t);
begin
   if (ent^.nextthink) then
      exit;      // already been triggered

   G_UseTargets (ent, ent^.activator);

   if (ent^.wait > 0) then
    begin
      ent^.think := multi_wait;
      ent^.nextthink := level.time + ent^.wait;
    end
   else
   begin   // we can't just remove (self) here, because this is a touch function
      // called while looping through area links...
      ent^.touch := NiL;
      ent^.nextthink := level.time + FRAMETIME;
      ent^.think := G_FreeEdict;
    end;
end;

procedure Use_Multi (ent:pedict_t; other:pedict_t; activator:pedict_t);
begin
   ent^.activator := activator;
   multi_trigger (ent);
end;

procedure Touch_Multi (self:pedict_t; other:pedict_t; plane:pcplane_t; surf:pcsurface_t);
var  forward:vec3_t;
begin
   if(other^.client) then
    begin
      if (self^.spawnflags and 2) then
         exit;
    end
   else if (other^.svflags and SVF_MONSTER) then
    begin
      if (not (self^.spawnflags and 1)) then
         exit;
    end
   else
      exit;

   if (not VectorCompare(self^.movedir, vec3_origin)) then
    begin
      

      AngleVectors(other^.s.angles, forward, Nil, NiL);
      if (_DotProduct(forward, self^.movedir) < 0) then
         exit;
    end;

   self^.activator := other;
   multi_trigger (self);
end;

(*QUAKED trigger_multiple (.5 .5 .5) ? MONSTER NOT_PLAYER TRIGGERED
Variable sized repeatable trigger.  Must be targeted at one or more entities.
If 'delay' is set, the trigger waits some time after activating before firing.
'wait' : Seconds between triggerings. (.2 default)
sounds
1)   secret
2)   beep beep
3)   large switch
4)
set 'message' to text string
*)
procedure trigger_enable (self:pedict_t; other:pedict_t; activator:pedict_t);
begin
   self^.solid := SOLID_TRIGGER;
   self^.use := Use_Multi;
   gi.linkentity (self);
end;

procedure SP_trigger_multiple (ent:pedict_t);
begin
   if (ent^.sounds = 1) then
      ent^.noise_index := gi.soundindex ('misc/secret.wav')
   else if (ent^.sounds = 2) then
      ent^.noise_index := gi.soundindex ('misc/talk.wav')
   else if (ent^.sounds = 3) then
      ent^.noise_index := gi.soundindex ('misc/trigger1.wav');
   
   if (not ent^.wait) then
      ent^.wait := 0.2;
   ent^.touch := Touch_Multi;
   ent^.movetype := MOVETYPE_NONE;
   ent^.svflags := ent^.svflags or SVF_NOCLIENT;


   if (ent^.spawnflags and 4) then
    begin
      ent^.solid := SOLID_NOT;
      ent^.use := trigger_enable;
    end
   else
    begin
      ent^.solid := SOLID_TRIGGER;
      ent^.use := Use_Multi;
    end;

   if (not VectorCompare(ent^.s.angles, vec3_origin)) then
      G_SetMovedir (ent^.s.angles, ent^.movedir);

   gi.setmodel (ent, ent^.model);
   gi.linkentity (ent);
end;


(*QUAKED trigger_once (.5 .5 .5) ? x x TRIGGERED
Triggers once, then removes itself.
You must set the key 'target' to the name of another object in the level that has a matching 'targetname'.

If TRIGGERED, this trigger must be triggered before it is live.

sounds
 1)   secret
 2)   beep beep
 3)   large switch
 4)

'message'   string to be displayed when triggered
*)

procedure SP_trigger_once(ent:pedict_t);
var  v:vec3_t;
begin
   // make old maps work because I messed up on flag assignments here
   // triggered was on bit 1 when it should have been on bit 4
   if (ent^.spawnflags and 1) then
    begin


      VectorMA (ent^.mins, 0.5, ent^.size, v);
      ent^.spawnflags := ent^.spawnflags and (not 1);
      ent^.spawnflags := ent^.spawnflags or 4;
      gi.dprintf('fixed TRIGGERED flag on %s at %s\n', ent^.classname, vtos(v));
    end;

   ent^.wait := -1;
   SP_trigger_multiple (ent);
end;

(*QUAKED trigger_relay (.5 .5 .5) (-8 -8 -8) (8 8 8)
This fixed size trigger cannot be touched, it can only be fired by other events.
*)
procedure trigger_relay_use (self:pedict_t; other:pedict_t; activator:pedict_t);
begin
   G_UseTargets (self, activator);
end;

procedure SP_trigger_relay ( self:pedict_t);
begin
   self^.use := trigger_relay_use;
end;


(*
==============================================================================

trigger_key

==============================================================================
*)
(*QUAKED trigger_key (.5 .5 .5) (-8 -8 -8) (8 8 8)
A relay trigger that only fires it's targets if player has the proper key.
Use 'item' to specify the required key, for example 'key_data_cd'
*)
procedure trigger_key_use (self:pedict_t; other:pedict_t; activator:pedict_t);
var index:smallint;
    player:smallint;
    ent:pedict_t;
    cube:smallint;
begin


   if (not self^.item) then
      exit;
   if (not activator^.client) then
      exit;

   index := ITEM_INDEX(self^.item);
   if (not activator^.client^.pers.inventory[index]) then
    begin
      if (level.time < self^.touch_debounce_time) then
         exit;
      self^.touch_debounce_time := level.time + 5.0;
      gi.centerprintf (activator, 'You need the %s', self^.item^.pickup_name);
      gi.sound (activator, CHAN_AUTO, gi.soundindex ('misc/keytry.wav'), 1, ATTN_NORM, 0);
      exit;
    end;

   gi.sound (activator, CHAN_AUTO, gi.soundindex ('misc/keyuse.wav'), 1, ATTN_NORM, 0);
   if (coop^.value) then
    begin


      if (strcomp(self^.item^.classname, 'key_power_cube') = 0) then
        begin
         

         for cube := 0 to 7 do
            if (activator^.client^.pers.power_cubes and (1 shl cube)) then
               break;
         for player := 1 to game.maxclients do
            begin
            ent := @g_edicts[player];
            if (not ent^.inuse) then
               continue;
            if (not ent^.client) then
               continue;
            if (ent^.client^.pers.power_cubes and (1 shl cube)) then
                begin
               ent^.client^.pers.inventory[index] := ent^.client^.pers.inventory[index] - 1;
               ent^.client^.pers.power_cubes := ent^.client^.pers.power_cubes and (not(1 shl cube));
                end;
            end;
        end
      else
        begin
         for player := 1 to game.maxclients do
            begin
            ent := @g_edicts[player];
            if (not ent^.inuse) then
               continue;
            if (not ent^.client) then
               continue;
            ent^.client^.pers.inventory[index] := 0;
            end;
        end;
    end
   else
    begin
      activator^.client^.pers.inventory[index] := activator^.client^.pers.inventory[index] - 1;
    end;

   G_UseTargets (self, activator);

   self^.use := NiL;
end;

procedure SP_trigger_key (self:pedict_t);
begin
   if (not st.item) then
    begin
      gi.dprintf('no key item for trigger_key at %s\n', vtos(self^.s.origin));
      exit;
    end;
   self^.item := FindItemByClassname (st.item);

   if (not self^.item) then
    begin
      gi.dprintf('item %s not found for trigger_key at %s\n', st.item, vtos(self^.s.origin));
      exit;
    end;

   if (not self^.target) then
    begin
      gi.dprintf('%s at %s has no target\n', self^.classname, vtos(self^.s.origin));
      exit;
    end;

   gi.soundindex ('misc/keytry.wav');
   gi.soundindex ('misc/keyuse.wav');

   self^.use := trigger_key_use;
end;


(*
===============================================================================

trigger_counter

==============================================================================
*)

(*QUAKED trigger_counter (.5 .5 .5) ? nomessage
Acts as an intermediary for an action that takes multiple inputs.

If nomessage is not set, t will print '1 more.. ' etc when triggered and 'sequence complete' when finished.

After the counter has been triggered 'count' times (default 2), it will fire all of it's targets and remove itself.
*)

procedure trigger_counter_use(self:pedict_t; other:pedict_t; activator:pedict_t);
begin
   if (self^.count = 0) then
      exit;
   
   self^.count := self^.count - 1;

   if (self^.count = 1) then
    begin
      if (not (self^.spawnflags and 1)) then
        begin
         gi.centerprintf(activator, '%i more to go...', self^.count);
         gi.sound (activator, CHAN_AUTO, gi.soundindex ('misc/talk1.wav'), 1, ATTN_NORM, 0);
        end;
      exit;
    end;
   
   if (not (self^.spawnflags and 1)) then
    begin
      gi.centerprintf(activator, 'Sequence completed!');
      gi.sound (activator, CHAN_AUTO, gi.soundindex ('misc/talk1.wav'), 1, ATTN_NORM, 0);
    end;
   self^.activator := activator;
   multi_trigger (self);
end;

procedure SP_trigger_counter (self:pedict_t);
begin
   self^.wait := -1;
   if (not self^.count) then
      self^.count := 2;

   self^.use := trigger_counter_use;
end;


(*
==============================================================================

trigger_always

==============================================================================
*)

(*QUAKED trigger_always (.5 .5 .5) (-8 -8 -8) (8 8 8)
This trigger will always fire.  It is activated by the world.
*)
procedure SP_trigger_always (ent:pedict_t);
begin
   // we must have some delay to make sure our use targets are present
   if (ent^.delay < 0.2) then
      ent^.delay := 0.2;
   G_UseTargets(ent, ent);
end;


(*
==============================================================================

trigger_push

==============================================================================
*)

const PUSH_ONCE   = 1 ;

var windsound:smallint;

procedure trigger_push_touch (self:pedict_t; other:pedict_t; plane:pcplane_t, surf:pcsurface_t);
begin
   if (strcomp(other^.classname, 'grenade') = 0) then
    begin
      VectorScale (self^.movedir, self^.speed * 10, other^.velocity);
    end
   else if (other^.health > 0) then
         begin
      VectorScale (self^.movedir, self^.speed * 10, other^.velocity);

      if (other^.client) then
        begin
         // don't take falling damage immediately from this
         VectorCopy (other^.velocity, other^.client^.oldvelocity);
         if (other^.fly_sound_debounce_time < level.time) then
            begin
            other^.fly_sound_debounce_time := level.time + 1.5;
            gi.sound (other, CHAN_AUTO, windsound, 1, ATTN_NORM, 0);
            end;
        end;
    end;
   if (self^.spawnflags and PUSH_ONCE) then
      G_FreeEdict (self);
end;


(*QUAKED trigger_push (.5 .5 .5) ? PUSH_ONCE
Pushes the player
'speed'      defaults to 1000
*)
procedure SP_trigger_push (self:pedict_t);
begin
   InitTrigger (self);
   windsound := gi.soundindex ('misc/windfly.wav');
   self^.touch := trigger_push_touch;
   if (not self^.speed) then
      self^.speed := 1000;
   gi.linkentity (self);
end;


(*
==============================================================================

trigger_hurt

==============================================================================
*)

(*QUAKED trigger_hurt (.5 .5 .5) ? START_OFF TOGGLE SILENT NO_PROTECTION SLOW
Any entity that touches this will be hurt.

It does dmg points of damage each server frame

SILENT         supresses playing the sound
SLOW         changes the damage rate to once per second
NO_PROTECTION   *nothing* stops the damage

'dmg'         default 5 (whole numbers only)

*)
procedure hurt_use (edict_t *self, edict_t *other, edict_t *activator);
begin
   if (self^.solid = SOLID_NOT) then
      self^.solid := SOLID_TRIGGER
   else
      self^.solid := SOLID_NOT;
   gi.linkentity (self);

   if (not (self^.spawnflags and 2)) then
      self^.use := NiL;
end;


procedure hurt_touch (self:pedict_t; other:pedict_t; plane:pcplane_t; surf:pcsurface_t);
var    dflags:smallint;
begin


   if (not other^.takedamage) then
      exit;

   if (self^.timestamp > level.time) then
      exit;

   if (self^.spawnflags and 16) then
      self^.timestamp := level.time + 1
   else
      self^.timestamp := level.time + FRAMETIME;

   if (not (self^.spawnflags and 4)) then
    begin
      if ((level.framenum mod 10) = 0) then
         gi.sound (other, CHAN_AUTO, self^.noise_index, 1, ATTN_NORM, 0);
    end;

   if (self^.spawnflags and 8) then
      dflags := DAMAGE_NO_PROTECTION
   else
      dflags := 0;
   T_Damage (other, self, self, vec3_origin, other^.s.origin, vec3_origin, self^.dmg, self^.dmg, dflags, MOD_TRIGGER_HURT);
end;

procedure SP_trigger_hurt (self:pedict_t);
begin
   InitTrigger (self);

   self^.noise_index := gi.soundindex ('world/electro.wav');
   self^.touch := hurt_touch;

   if (not self^.dmg) then
      self^.dmg := 5;

   if (self^.spawnflags and 1) then
      self^.solid := SOLID_NOT
   else
      self^.solid := SOLID_TRIGGER;

   if (self^.spawnflags and 2) then
      self^.use := hurt_use;

   gi.linkentity (self);
end;


(*
==============================================================================

trigger_gravity

==============================================================================
*)

(*QUAKED trigger_gravity (.5 .5 .5) ?
Changes the touching entites gravity to
the value of 'gravity'.  1.0 is standard
gravity for the level.
*)

procedure trigger_gravity_touch ( self:pedict_t; other:pedict_t; plane:pcplane_t; surf:pcsurface_t);
begin
   other^.gravity := self^.gravity;
end;

procedure SP_trigger_gravity (self:pedict_t);
begin
   if (st.gravity = 0) then
    begin
      gi.dprintf('trigger_gravity without gravity set at %s\n', vtos(self^.s.origin));
      G_FreeEdict  (self);
      exit;
    end;

   InitTrigger (self);
   self^.gravity := atoi(st.gravity);
   self^.touch := trigger_gravity_touch;
end;


(*
==============================================================================

trigger_monsterjump

==============================================================================
*)

(*QUAKED trigger_monsterjump (.5 .5 .5) ?
Walking monsters that touch this will jump in the direction of the trigger's angle
'speed' default to 200, the speed thrown forward
'height' default to 200, the speed thrown upwards
*)

procedure trigger_monsterjump_touch ( self:pedict_t; other:pedict_t; plane:pcplane_t; surf:pcsurface_t);
begin
   if (other^.flags and (FL_FLY or FL_SWIM) ) then
      exit;
   if (other^.svflags and SVF_DEADMONSTER) then
      exit;
   if ( not(other^.svflags and SVF_MONSTER)) then
      exit;

// set XY even if not on ground, so the jump will clear lips
   other^.velocity[0] := self^.movedir[0] * self^.speed;
   other^.velocity[1] := self^.movedir[1] * self^.speed;
   
   if (not other^.groundentity) then
      exit;
   
   other^.groundentity := Nil;
   other^.velocity[2] := self^.movedir[2];
end;

procedure SP_trigger_monsterjump ( self:pedict_t);
begin
   if (not self^.speed) then
      self^.speed := 200;
   if (not st.height) then
      st.height := 200;
   if (self^.s.angles[YAW] = 0) then
      self^.s.angles[YAW] := 360;
   InitTrigger (self);
   self^.touch := trigger_monsterjump_touch;
   self^.movedir[2] := st.height;
end;

end.
