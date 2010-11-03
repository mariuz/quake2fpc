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
{ File(s): g_trigger.c                                                       }
{ Content: monster movement                                                  }
{                                                                            }
{ Initial conversion by : you_known (you_known@163.com)                      }
{ Initial conversion on : 2002-02-03                                         }
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
{ Updated on :  2003-May-22                                                  }
{ Updated by :  Scott Price (scott.price@totalise.co.uk)                     }
{                                                                            }
{----------------------------------------------------------------------------}
{ Notes:                                                                     }
{----------------------------------------------------------------------------}

unit g_trigger;



interface



uses
  { Quake2 Units }
  g_local,

  { Borland Standard Units }
  SysUtils;

  
procedure SP_trigger_multiple (ent:edict_p); cdecl;
procedure SP_trigger_once(ent:edict_p); cdecl;
procedure SP_trigger_relay ( self:edict_p); cdecl;
procedure SP_trigger_key (self:edict_p); cdecl;
procedure SP_trigger_counter (self:edict_p); cdecl;
procedure SP_trigger_always (ent:edict_p); cdecl;
procedure SP_trigger_push (self:edict_p); cdecl;
procedure SP_trigger_hurt (self:edict_p); cdecl;
procedure SP_trigger_gravity (self:edict_p); cdecl;
procedure SP_trigger_monsterjump ( self:edict_p); cdecl;


implementation


uses
  g_utils,
  gameunit,
  game_add,
  g_local_add,
  g_main,
  q_shared,
  g_items,
  g_combat,
  CPas;

  
procedure InitTrigger (self: edict_p);
begin
  if (VectorCompare(self^.s.angles, vec3_origin) = 0) then
    G_SetMovedir (self^.s.angles, self^.movedir);

  self^.solid := SOLID_TRIGGER;
  self^.movetype := MOVETYPE_NONE;
  gi.setmodel (self, self^.model);
  self^.svflags := SVF_NOCLIENT;
end;


// the wait time has passed, so set back up for another activation
procedure multi_wait (ent: edict_p); cdecl;
begin
  ent^.nextthink := 0;
end;


// the trigger was just activated
// ent->activator should be set to the activator so it can be held through a delay
// so wait for the delay time before firing
procedure multi_trigger (ent: edict_p);
begin
  if (ent^.nextthink <> 0) then
    Exit;      // already been triggered

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

procedure Use_Multi (ent: edict_p; other: edict_p; activator: edict_p); cdecl;
begin
  ent^.activator := activator;
  multi_trigger (ent);
end;

procedure Touch_Multi (self:edict_p; other:edict_p; plane:cplane_p; surf:csurface_p); cdecl;
var
  forward_: vec3_t;
begin
  if (other^.client <> nil) then
  begin
    if (self^.spawnflags and 2) <> 0 then
      Exit;
  end
  else if (other^.svflags and SVF_MONSTER) <> 0 then
  begin
    if ((self^.spawnflags and 1) = 0) then
      Exit;
  end
  else
    Exit;

  if (VectorCompare(self^.movedir, vec3_origin) = 0) then
  begin
    AngleVectors(other^.s.angles, @forward_, Nil, NiL);
    if (_DotProduct(forward_, self^.movedir) < 0) then
      Exit;
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
procedure trigger_enable (self: edict_p; other: edict_p; activator: edict_p); cdecl;
begin
  self^.solid := SOLID_TRIGGER;
  self^.use := Use_Multi;
  gi.linkentity (self);
end;

procedure SP_trigger_multiple (ent:edict_p);
begin
  if (ent^.sounds = 1) then
    ent^.noise_index := gi.soundindex ('misc/secret.wav')
  else if (ent^.sounds = 2) then
    ent^.noise_index := gi.soundindex ('misc/talk.wav')
  else if (ent^.sounds = 3) then
    ent^.noise_index := gi.soundindex ('misc/trigger1.wav');

  if (ent^.wait = 0) then
    ent^.wait := 0.2;
  ent^.touch := Touch_Multi;
  ent^.movetype := MOVETYPE_NONE;
  ent^.svflags := ent^.svflags or SVF_NOCLIENT;


  if (ent^.spawnflags and 4) <> 0 then
  begin
    ent^.solid := SOLID_NOT;
    ent^.use := trigger_enable;
  end
  else
  begin
    ent^.solid := SOLID_TRIGGER;
    ent^.use := Use_Multi;
  end;

  if (VectorCompare(ent^.s.angles, vec3_origin) = 0) then
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

procedure SP_trigger_once(ent: edict_p);
var
  v: vec3_t;
begin
  // make old maps work because I messed up on flag assignments here
  // triggered was on bit 1 when it should have been on bit 4
  if (ent^.spawnflags and 1) <> 0 then
  begin
    VectorMA (ent^.mins, 0.5, ent^.size, v);
    ent^.spawnflags := ent^.spawnflags and (not 1);
    ent^.spawnflags := ent^.spawnflags or 4;
    gi.dprintf('fixed TRIGGERED flag on %s at %s'#10, ent^.classname, vtos(v));
  end;

  ent^.wait := -1;
  SP_trigger_multiple (ent);
end;

(*QUAKED trigger_relay (.5 .5 .5) (-8 -8 -8) (8 8 8)
This fixed size trigger cannot be touched, it can only be fired by other events.
*)
procedure trigger_relay_use (self: edict_p; other: edict_p; activator: edict_p); cdecl;
begin
  G_UseTargets (self, activator);
end;

procedure SP_trigger_relay (self: edict_p);
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
procedure trigger_key_use (self: edict_p; other: edict_p; activator: edict_p); cdecl;
var
  index: {TODO:smallint} Integer;
  player: {TODO:smallint} Integer;
  ent: edict_p;
  cube: {TODO:smallint} Integer;
begin
  if (self^.item = nil) then
    Exit;
  if (activator^.client = nil) then
    Exit;

  index := ITEM_INDEX(self^.item);
  if (activator^.client^.pers.inventory[index] = 0) then
  begin
    if (level.time < self^.touch_debounce_time) then
      Exit;
    self^.touch_debounce_time := level.time + 5.0;
    gi.centerprintf (activator, 'You need the %s', self^.item^.pickup_name);
    gi.sound (activator, CHAN_AUTO, gi.soundindex ('misc/keytry.wav'), 1, ATTN_NORM, 0);
    Exit;
  end;

  gi.sound (activator, CHAN_AUTO, gi.soundindex ('misc/keyuse.wav'), 1, ATTN_NORM, 0);
  if (coop^.Value <> 0) then
  begin
    if (strcomp(self^.item^.classname, 'key_power_cube') = 0) then
    begin
      for cube := 0 to 7 do
        if (activator^.client^.pers.power_cubes and (1 shl cube)) <> 0 then
          Break;
      for player := 1 to game.maxclients do
      begin
        ent := @g_edicts^[player];
        if (not ent^.inuse) then
          Continue;
        if (ent^.client = nil) then
          Continue;
        if (ent^.client^.pers.power_cubes and (1 shl cube)) <> 0 then
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
        ent := @g_edicts^[player];
        if (not ent^.inuse) then
          Continue;
        if (ent^.client) = nil then
          Continue;
        ent^.client^.pers.inventory[index] := 0;
      end;
    end;
  end
  else
  begin
    activator^.client^.pers.inventory[index] := activator^.client^.pers.inventory[index] - 1;
  end;

  G_UseTargets (self, activator);

  self^.use := Nil;
end;

procedure SP_trigger_key (self: edict_p);
begin
  if (st.item = '') then
  begin
    gi.dprintf('no key item for trigger_key at %s'#10, vtos(self^.s.origin));
    Exit;
  end;
  self^.item := FindItemByClassname (st.item);

  if (self^.item = nil) then
  begin
    gi.dprintf('item %s not found for trigger_key at %s'#10, st.item, vtos(self^.s.origin));
    Exit;
  end;

  if (self^.target = '') then
  begin
    gi.dprintf('%s at %s has no target'#10, self^.classname, vtos(self^.s.origin));
    Exit;
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

procedure trigger_counter_use(self: edict_p; other: edict_p; activator: edict_p); cdecl;
begin
  if (self^.count = 0) then
    Exit;

  self^.count := self^.count - 1;

  if (self^.count <> 0) then
  begin
    if ((self^.spawnflags and 1) = 0) then
    begin
      gi.centerprintf(activator, '%i more to go...', self^.count);
      gi.sound (activator, CHAN_AUTO, gi.soundindex ('misc/talk1.wav'), 1, ATTN_NORM, 0);
    end;
    Exit;
  end;

  if ((self^.spawnflags and 1) = 0) then
  begin
    gi.centerprintf(activator, 'Sequence completed!');
    gi.sound (activator, CHAN_AUTO, gi.soundindex ('misc/talk1.wav'), 1, ATTN_NORM, 0);
  end;
  self^.activator := activator;
  multi_trigger (self);
end;

procedure SP_trigger_counter (self: edict_p);
begin
  self^.wait := -1;
  if (self^.Count = 0) then
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
procedure SP_trigger_always (ent: edict_p);
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

var windsound: {TODO:smallint} Integer;

procedure trigger_push_touch (self: edict_p; other:edict_p; plane:cplane_p; surf:csurface_p); cdecl;
begin
  if (strcomp(other^.classname, 'grenade') = 0) then
  begin
    VectorScale (self^.movedir, self^.speed * 10, other^.velocity);
  end
  else if (other^.health > 0) then
  begin
    VectorScale (self^.movedir, self^.speed * 10, other^.velocity);

    if (other^.client <> nil) then
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
  if (self^.spawnflags and PUSH_ONCE) <> 0 then
    G_FreeEdict (self);
end;


(*QUAKED trigger_push (.5 .5 .5) ? PUSH_ONCE
Pushes the player
'speed'      defaults to 1000
*)
procedure SP_trigger_push (self: edict_p);
begin
  InitTrigger (self);
  windsound := gi.soundindex ('misc/windfly.wav');
  self^.touch := trigger_push_touch;
  if (self^.speed = 0) then
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
procedure hurt_use (Self : edict_p ; other : edict_p ; activator : edict_p); cdecl;
begin
  if (self^.solid = SOLID_NOT) then
    self^.solid := SOLID_TRIGGER
  else
    self^.solid := SOLID_NOT;
  gi.linkentity (self);

  if ((self^.spawnflags and 2) = 0) then
    self^.use := Nil;
end;


procedure hurt_touch (self: edict_p; other: edict_p; plane: cplane_p; surf: csurface_p); cdecl;
var
  dflags: {TODO:smallint} Integer;
begin
  if (other^.takedamage = DAMAGE_NO) then
    Exit;

  if (self^.timestamp > level.time) then
    Exit;

  if (self^.spawnflags and 16) <> 0 then
    self^.timestamp := level.time + 1
  else
    self^.timestamp := level.time + FRAMETIME;

  if ((self^.spawnflags and 4) = 0) then
  begin
    if ((level.framenum mod 10) = 0) then
      gi.sound (other, CHAN_AUTO, self^.noise_index, 1, ATTN_NORM, 0);
  end;

  if (self^.spawnflags and 8) <> 0 then
    dflags := DAMAGE_NO_PROTECTION
  else
    dflags := 0;
  T_Damage (other, self, self, vec3_origin, other^.s.origin, vec3_origin, self^.dmg, self^.dmg, dflags, MOD_TRIGGER_HURT);
end;

procedure SP_trigger_hurt (self: edict_p);
begin
  InitTrigger (self);

  self^.noise_index := gi.soundindex ('world/electro.wav');
  self^.touch := hurt_touch;

  if (self^.dmg = 0) then
    self^.dmg := 5;

  if (self^.spawnflags and 1) <> 0 then
    self^.solid := SOLID_NOT
  else
    self^.solid := SOLID_TRIGGER;

  if (self^.spawnflags and 2) <> 0 then
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

procedure trigger_gravity_touch ( self: edict_p; other: edict_p; plane: cplane_p; surf: csurface_p); cdecl;
begin
  other^.gravity := self^.gravity;
end;

procedure SP_trigger_gravity (self: edict_p);
begin
  if (st.gravity = '') then
  begin
    gi.dprintf('trigger_gravity without gravity set at %s'#10, vtos(self^.s.origin));
    G_FreeEdict  (self);
    Exit;
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

procedure trigger_monsterjump_touch (self: edict_p; other: edict_p; plane: cplane_p; surf: csurface_p); cdecl;
begin
  if (other^.flags and (FL_FLY or FL_SWIM)) <> 0 then
    Exit;
  if (other^.svflags and SVF_DEADMONSTER) <> 0 then
    Exit;
  if ((other^.svflags and SVF_MONSTER) = 0) then
    Exit;

// set XY even if not on ground, so the jump will clear lips
  other^.velocity[0] := self^.movedir[0] * self^.speed;
  other^.velocity[1] := self^.movedir[1] * self^.speed;

  if (other^.groundentity = nil) then
    Exit;

  other^.groundentity := Nil;
  other^.velocity[2] := self^.movedir[2];
end;

procedure SP_trigger_monsterjump (self: edict_p);
begin
  if (self^.speed = 0) then
    self^.speed := 200;
  if (st.Height = 0) then
    st.height := 200;
  if (self^.s.angles[q_shared.YAW] = 0) then
    self^.s.angles[q_shared.YAW] := 360;
  InitTrigger (self);
  self^.touch := trigger_monsterjump_touch;
  self^.movedir[2] := st.height;
end;

end.
