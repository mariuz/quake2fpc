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
{ File(s): g_ai.c                                                            }
{ Content:                                                                   }
{                                                                            }
{ Initial conversion by : Scott Price                                        }
{ Initial conversion on : 09-Jan-2002                                        }
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
{ NOTE!! This is same file than in CTF folder with same name                 }
{----------------------------------------------------------------------------}
unit g_ai;

interface

uses
  q_shared,
  g_local;

function FindTarget(self: edict_p): qboolean;
//extern cvar_t   *maxclients;
function infront(self: edict_p; other: edict_p): qboolean;
function ai_checkattack(self: edict_p; dist: Single): qboolean;
procedure FoundTarget(self: edict_p);
function M_CheckAttack(self: edict_p): qboolean; cdecl;
function visible(self: edict_p; other: edict_p): qboolean;
function range(self: edict_p; other: edict_p): Integer;
procedure AI_SetSightClient;

procedure ai_stand(self: edict_p; dist: Single); cdecl;
procedure ai_walk(self: edict_p; dist: Single); cdecl;
procedure ai_run(self: edict_p; dist: Single); cdecl;
procedure ai_move(self: edict_p; dist: Single); cdecl;
procedure ai_turn(self: edict_p; dist: Single); cdecl;
procedure ai_charge(self: edict_p; dist: Single); cdecl;


var
  enemy_vis: qboolean;
  enemy_infront: qboolean;
  enemy_range: Integer;
  enemy_yaw: Single;

implementation

uses
  g_utils,
  GameUnit,
  g_main,
  m_move,
  g_monster,
  Cpas,
  p_trail;


(* =================
AI_SetSightClient

Called once each frame to set level.sight_client to the
player to be checked for in findtarget.

If all clients sare either dead or in notarget, sight_client
will be null.

In coop games, sight_client will cycle between the clients.
================= *)
procedure AI_SetSightClient;
var
  ent: edict_p;
  start, check: Integer;
begin
  if (level.sight_client = nil) then
     start := 1
  else
     start := (Cardinal(level.sight_client) - Cardinal(g_edicts)) div sizeof(edict_t);

  check := start;
  while (True) do begin
     Inc(check);

     if (check > game.maxclients) then
        check := 1;

     ent := @g_edicts[check];
     if (ent^.inuse AND (ent^.health > 0) AND ((ent^.flags AND FL_NOTARGET) = 0)) then begin
        level.sight_client := ent;
        Exit;  // got one
     end;

     if (check = start) then begin
        level.sight_client := nil;
        Exit;  // nobody to see
     end;
  end;
end;

(* =============
ai_move

Move the specified distance at current facing.
This replaces the QC functions: ai_forward, ai_back, ai_pain, and ai_painforward
============== *)
procedure ai_move(self: edict_p; dist: Single);
begin
  M_walkmove(self, self^.s.angles[YAW], dist);
end;

(* =============
ai_stand

Used for standing around and looking for players
Distance is for slight position adjustments needed by the animations
============== *)
procedure ai_stand(self: edict_p; dist: Single);
var
  v: vec3_t;
begin
  if (dist <> 0) then
     M_walkmove(self, self^.s.angles[YAW], dist);

  if ((self^.monsterinfo.aiflags AND AI_STAND_GROUND) <> 0) then begin
     if (self^.enemy <> nil) then begin
        VectorSubtract(self^.enemy^.s.origin, self^.s.origin, v);
        self^.ideal_yaw := vectoyaw(v);
        { TODO:  Translate the Line Below: }
        // ORIGINAL:  if (self->s.angles[YAW] <> self->ideal_yaw && self->monsterinfo.aiflags & AI_TEMP_STAND_GROUND) then
        if ((self^.s.angles[YAW] <> self^.ideal_yaw) AND ((self^.monsterinfo.aiflags AND AI_TEMP_STAND_GROUND) <> 0)) then
        begin
           { TODO:  Translate the Line Below: }
           // ORIGINAL:  self->monsterinfo.aiflags &= ~(AI_STAND_GROUND | AI_TEMP_STAND_GROUND);
           self^.monsterinfo.aiflags := self^.monsterinfo.aiflags AND (NOT (AI_STAND_GROUND OR AI_TEMP_STAND_GROUND));
           self^.monsterinfo.run(self);
        end;

        M_ChangeYaw(self);
        ai_checkattack(self, 0);
     end else
         FindTarget(self);

     Exit;
  end;

  if (FindTarget(self)) then
     Exit;

  if (level.time > self^.monsterinfo.pausetime) then begin
     self^.monsterinfo.walk(self);
     Exit;
  end;

  { TODO:  Translate the Line Below: }
  // ORIGINAL:  if (!(self->spawnflags & 1) && (self->monsterinfo.idle) && (level.time > self->monsterinfo.idle_time))
  if (((self^.spawnflags AND 1) = 0) AND (@self^.monsterinfo.idle <> nil) AND (level.time > self^.monsterinfo.idle_time)) then
  begin
     { TODO:  Translate the Line Below: }
     if (self^.monsterinfo.idle_time <> 0) then begin
        self^.monsterinfo.idle(self);
        self^.monsterinfo.idle_time := level.time + 15 + _random() * 15;
     end else begin
         self^.monsterinfo.idle_time := level.time + _random() * 15;
     end;
  end;
end;

(* =============
ai_walk

The monster is walking it's beat
============= *)
procedure ai_walk(self: edict_p; dist: Single);
begin
  M_MoveToGoal(self, dist);

  // check for noticing a player
  if FindTarget(self) then
     Exit;

  { TODO:  Translate the Line Below: }
  // ORIGINAL:  if ((self->monsterinfo.search) && (level.time > self->monsterinfo.idle_time)) then begin
  if ((@self^.monsterinfo.search <> nil) AND (level.time > self^.monsterinfo.idle_time)) then begin
     { TODO:  Translate the Line Below: }
     if (self^.monsterinfo.idle_time <> 0) then begin
        self^.monsterinfo.search(self);
        self^.monsterinfo.idle_time := level.time + 15 + _random() * 15;
     end else begin
         self^.monsterinfo.idle_time := level.time + _random() * 15;
     end;
  end;
end;

(* =============
ai_charge

Turns towards target and advances
Use this call with a distnace of 0 to replace ai_face
============== *)
procedure ai_charge(self: edict_p; dist: Single);
var
  v: vec3_t;
begin
  VectorSubtract(self^.enemy^.s.origin, self^.s.origin, v);
  self^.ideal_yaw := vectoyaw(v);
  M_ChangeYaw(self);

  if (dist <> 0) then
     M_walkmove(self, self^.s.angles[YAW], dist);
end;

(* =============
ai_turn

don't move, but turn towards ideal_yaw
Distance is for slight position adjustments needed by the animations
============= *)
procedure ai_turn(self: edict_p; dist: Single);
begin
  if (dist <> 0) then
     M_walkmove(self, self^.s.angles[YAW], dist);

  if FindTarget(self) then
     Exit;

  M_ChangeYaw(self);
end;

(*
.enemy
Will be world if not currently angry at anyone.

.movetarget
The next path spot to walk toward.  If .enemy, ignore .movetarget.
When an enemy is killed, the monster will try to return to it's path.

.hunt_time
Set to time + something when the player is in sight, but movement straight for
him is blocked.  This causes the monster to use wall following code for
movement direction instead of sighting on the player.

.ideal_yaw
A yaw angle of the intended direction, which will be turned towards at up
to 45 deg / state.  If the enemy is in view and hunt_time is not active,
this will be the exact line towards the enemy.

.pausetime
A monster will leave it's stand state and head towards it's .movetarget when
time > .pausetime.

walkmove(angle, speed) primitive is all or nothing  *)

(*
=============
range

returns the range catagorization of an entity reletive to self
0   melee range, will become hostile even if back is turned
1   visibility and infront, or visibility and show hostile
2   infront and show hostile
3   only triggered by damage
=============
*)
function range(self: edict_p; other: edict_p): Integer;
//function range(self, other: Pedict_t): Integer;
var
  v: vec3_t;
  len: Single;
begin
  VectorSubtract(self^.s.origin, other^.s.origin, v);
  len := VectorLength(v);

  if (len < MELEE_DISTANCE) then begin
     Result := RANGE_MELEE;
     Exit;
  end;

  if (len < 500) then begin
     Result := RANGE_NEAR;
     Exit;
  end;

  if (len < 1000) then begin
     Result := RANGE_MID;
     Exit;
  end;

  Result := RANGE_FAR;
end;

(* =============
visible

returns 1 if the entity is visible to self, even if not infront ()
============= *)
function visible(self: edict_p; other: edict_p): qboolean;
//function visible(self, other: Pedict_t): qboolean;
var
  spot1: vec3_t;
  spot2: vec3_t;
  trace: trace_t;
begin
  VectorCopy(self^.s.origin, spot1);
  //spot1[2] += self->viewheight;  <-- TODO:  Check this Translation
  spot1[2] := (spot1[2] + self^.viewheight);

  VectorCopy(other^.s.origin, spot2);
  //spot2[2] += other->viewheight;  <-- TODO:  Check this Translation
  spot2[2] := (spot2[2] + other^.viewheight);
  trace := gi.trace(@spot1, @vec3_origin, @vec3_origin, @spot2, self, MASK_OPAQUE);

  if (trace.fraction = 1.0) then begin
     Result := True;
     Exit;
  end;

  Result := False;
end;

(* =============
infront

returns 1 if the entity is in front (in sight) of self
============= *)
function infront(self: edict_p; other: edict_p): qboolean;
//function infront(self, other: Pedict_t): qboolean;
var
  vec: vec3_t;
  dot: Single;
  forward_: vec3_t;
begin
  AngleVectors(self^.s.angles, @forward_, Nil, Nil);
  VectorSubtract(other^.s.origin, self^.s.origin, vec);
  VectorNormalize(vec);
  dot := DotProduct(vec, forward_);

  if (dot > 0.3) then begin
     Result := True;
     Exit;
  end;

  Result := False;
end;


//============================================================================

procedure HuntTarget(self: edict_p);
var
  vec: vec3_t;
begin
  self^.goalentity := self^.enemy;
  if ((self^.monsterinfo.aiflags AND AI_STAND_GROUND) <> 0) then
     self^.monsterinfo.stand(self)
  else
     self^.monsterinfo.run(self);

  VectorSubtract(self^.enemy^.s.origin, self^.s.origin, vec);
  self^.ideal_yaw := vectoyaw(vec);
  { wait a while before first attack }
  if ((self^.monsterinfo.aiflags AND AI_STAND_GROUND) = 0) then
     AttackFinished(self, 1);
end;

procedure FoundTarget(self: edict_p);
begin
  { let other monsters see this monster for a while }
  if (self^.enemy^.client <> nil) then begin
     level.sight_entity := self;
     level.sight_entity_framenum := level.framenum;
     level.sight_entity^.light_level := 128;
  end;

  { wake up other monsters }
  //self->show_hostile = level.time + 1;  original C
  if level.time+1 > 0 then  // check this translation
  self^.show_hostile := true ;  //check this translation 

  VectorCopy(self^.enemy^.s.origin, self^.monsterinfo.last_sighting);
  self^.monsterinfo.trail_time := level.time;

  if (self^.combattarget = nil) then begin
     HuntTarget(self);
     Exit;
  end;

  self^.movetarget := G_PickTarget(self^.combattarget);
  self^.goalentity := self^.movetarget;
  if (self^.movetarget = nil) then begin
     self^.movetarget := self^.enemy;
     self^.goalentity := self^.movetarget;
     HuntTarget(self);
     { Enable this when dprintf finished
     gi.dprintf('%s at %s, combattarget %s not found'#10, self^.classname,
       vtos(self^.s.origin), self^.combattarget);
      }
     Exit;
  end;

  { clear out our combattarget, these are a one shot deal }
  self^.combattarget := Nil;
  { TODO:  Translate the Line Below: }
  self^.monsterinfo.aiflags := self^.monsterinfo.aiflags OR AI_COMBAT_POINT;

  { clear the targetname, that point is ours! }
  self^.movetarget^.targetname := Nil;
  self^.monsterinfo.pausetime := 0;

  { run for it }
  self^.monsterinfo.run(self);
end;

(* ===========
FindTarget

Self is currently not attacking anything, so try to find a target

Returns TRUE if an enemy was sighted

When a player fires a missile, the point of impact becomes a fakeplayer so
that monsters that see the impact will respond as if they had seen the
player.

To avoid spending too much time, only a single client (or fakeclient) is
checked each frame.  This means multi player games will have slightly
slower noticing monsters.
============ *)
function FindTarget(self: edict_p): qboolean;
var
  client: edict_p;
  heardit: qboolean;
  r: Integer;
  temp: vec3_t;
begin
  if ((self^.monsterinfo.aiflags AND AI_GOOD_GUY) <> 0) then begin
     { TODO:  Translate the Line Below: }
     if ((self^.goalentity <> Nil) AND self^.goalentity^.inuse AND (self^.goalentity^.classname <> Nil)) then begin
        if (StrCmp(self^.goalentity^.classname, 'target_actor') = 0) then
        begin
           Result := False;
           Exit;
        end;
     end;

     //FIXME look for monsters?
     Result := False;
     Exit;
  end;

  { if we're going to a combat point, just proceed }
  if (self^.monsterinfo.aiflags AND AI_COMBAT_POINT)<> 0 then
  begin
     Result := False;
     Exit;
  end;

  { if the first spawnflag bit is set, the monster will only wake up on
    really seeing the player, not another monster getting angry or hearing
    something }

  { revised behavior so they will wake up if they "see" a player make a
    noise but not weapon impact/explosion noises }

  heardit := False;
  { TODO:  Translate the Line Below: }
  // ORIGINAL:  if ((level.sight_entity_framenum >= (level.framenum - 1)) && !(self^.spawnflags AND 1) ) then begin
  if ((level.sight_entity_framenum >= (level.framenum - 1)) AND ((self^.spawnflags AND 1) = 0)) then begin
     client := level.sight_entity;
     if (client^.enemy = self^.enemy) then begin
        Result := False;
        Exit;
     end;
  end else if (level.sound_entity_framenum >= (level.framenum - 1)) then begin
      client := level.sound_entity;
      heardit := True;
  end
  { TODO:  Translate the Line Below: }
  // ORIGINAL:  else if (!(self->enemy) && (level.sound2_entity_framenum >= (level.framenum - 1)) && !(self->spawnflags & 1) ) then begin
  else if ((self^.enemy = Nil) AND (level.sound2_entity_framenum >= (level.framenum - 1)) AND ((self^.spawnflags AND 1) = 0)) then begin
       client := level.sound2_entity;
       heardit := True;
  end else begin
      client := level.sight_client;
      if (client = nil) then begin
         { no clients to get mad at }
         Result := False;
         Exit;
      end;
  end;

  { if the entity went away, forget it }
  if (not client^.inuse) then begin
     Result := False;
     Exit;
  end;

  if (client = self^.enemy) then begin
     Result := True;   // JDC false;
     Exit;
  end;

  if (client^.client <> nil) then begin
     if ((client^.flags AND FL_NOTARGET) <> 0) then begin
        Result := False;
        Exit;
     end;
  end else if ((client^.svflags AND SVF_MONSTER) <> 0) then begin
      if (client^.enemy = nil) then begin
         Result := False;
         Exit;
      end;
      if ((client^.enemy^.flags AND FL_NOTARGET) <> 0) then begin
         Result := False;
         Exit;
      end;
  end else if (heardit) then begin
      if ((client^.owner^.flags AND FL_NOTARGET) <> 0) then begin
         Result := False;
         Exit;
      end;
  end else begin
      Result := False;
      Exit;
  end;

  if (NOT heardit) then begin
     r := range(self, client);

     if (r = RANGE_FAR) then begin
        Result := False;
        Exit;
     end;

     { this is where we would check invisibility }

     { is client in an spot too dark to be seen? }
     if (client^.light_level <= 5) then begin
        Result := False;
        Exit;
     end;

     if (NOT visible(self, client)) then begin
        Result := False;
        Exit;
     end;

     if (r = RANGE_NEAR) then begin
        if {(client^.show_hostile < level.time) and }(not infront(self, client)) then begin
           Result := False;
           Exit;
        end;
     end else if (r = RANGE_MID) then begin
         if (NOT infront(self, client)) then begin
            Result := False;
            Exit;
         end;
     end;

     self^.enemy := client;

     if (StrCmp(self^.enemy^.classname, 'player_noise') <> 0) then begin
        { TODO:  Translate the Line Below: }
        self^.monsterinfo.aiflags := self^.monsterinfo.aiflags AND (NOT AI_SOUND_TARGET);

        if ( self^.enemy^.client = nil) then begin
           self^.enemy := self^.enemy^.enemy;
           if ( self^.enemy^.client = nil) then begin
              self^.enemy := Nil;
              Result := False;
              Exit;
           end;
        end;
     end;
  end
  else   // heardit
  begin
     if ((self^.spawnflags AND 1) <> 0) then begin
        if (NOT visible (self, client)) then begin
           Result := False;
           Exit;
        end;
     end else begin
         if (NOT gi.inPHS(self^.s.origin, client^.s.origin)) then begin
            Result := False;
            Exit;
         end;
     end;

     VectorSubtract(client^.s.origin, self^.s.origin, temp);

     if (VectorLength(temp) > 1000) then begin
        { too far to hear }
        Result := False;
        Exit;
     end;

     { check area portals - if they are different and not connected
       then we can't hear it }
     if (client^.areanum <> self^.areanum) then
        if (NOT gi.AreasConnected(self^.areanum, client^.areanum)) then begin
           Result := False;
           Exit;
        end;

     self^.ideal_yaw := vectoyaw(temp);
     M_ChangeYaw(self);

     { hunt the sound for a bit; hopefully find the real player }
     { TODO:  Translate the Line Below: }
     self^.monsterinfo.aiflags := self^.monsterinfo.aiflags OR AI_SOUND_TARGET;
     self^.enemy := client;
  end;

  //
  // got one
  //
  FoundTarget(self);

  { TODO:  Translate the Line Below: }
  // ORIGINAL:  if (NOT ((self^.monsterinfo.aiflags AND AI_SOUND_TARGET) <> 0) && (self^.monsterinfo.sight)) then begin
  if (((self^.monsterinfo.aiflags AND AI_SOUND_TARGET) = 0) AND (@self^.monsterinfo.sight <> Nil)) then
     self^.monsterinfo.sight(self, self^.enemy);

  Result := True;
end;

(* ============
FacingIdeal

============ *)
function FacingIdeal(self: edict_p): qboolean;
var
  delta: Single;
begin
  delta := anglemod(self^.s.angles[YAW] - self^.ideal_yaw);
  { TODO:  Translate the Line Below: }
  if ((delta > 45) AND (delta < 315)) then begin
     Result := False;
     Exit;
  end;

  Result := True;
end;

function M_CheckAttack(self: edict_p): qboolean;
var
  spot1, spot2: vec3_t;
  chance: Single;
  tr: trace_t;
begin
  if (self^.enemy^.health > 0) then begin
     { see if any entities are in the way of the shot }
     VectorCopy(self^.s.origin, spot1);
     //spot1[2] += self->viewheight;
     spot1[2] := spot1[2] + self^.viewheight;
     VectorCopy(self^.enemy^.s.origin, spot2);
     //spot2[2] += self->enemy->viewheight;
     spot2[2] := spot2[2] + self^.enemy^.viewheight;

     tr := gi.trace(@spot1, Nil, Nil, @spot2, self, CONTENTS_SOLID OR
       CONTENTS_MONSTER OR CONTENTS_SLIME OR CONTENTS_LAVA OR CONTENTS_WINDOW);

     { do we have a clear shot? }
     if (tr.ent <> self^.enemy) then begin
        Result := False;
        Exit;
     end;
  end;

  { melee attack }
  if (enemy_range = RANGE_MELEE) then begin
     { don't always melee in easy mode }
     { TODO:  Translate the Line Below: }
     if ((skill^.value = 0) AND ((rand() AND 3) <> 0)) then begin
        Result := False;
        Exit;
     end;

     if (@self^.monsterinfo.melee <> nil) then
        self^.monsterinfo.attack_state := AS_MELEE
     else
        self^.monsterinfo.attack_state := AS_MISSILE;

     Result := True;
     Exit;
  end;

  { missile attack }
  if (@self^.monsterinfo.attack = nil) then begin
     Result := False;
     Exit;
  end;

  if (level.time < self^.monsterinfo.attack_finished) then begin
     Result := False;
     Exit;
  end;

  if (enemy_range = RANGE_FAR) then begin
     Result := False;
     Exit;
  end;

  if ((self^.monsterinfo.aiflags AND AI_STAND_GROUND) <> 0) then
     chance := 0.4
  else if (enemy_range = RANGE_MELEE) then
       chance := 0.2
  else if (enemy_range = RANGE_NEAR) then
       chance := 0.1
  else if (enemy_range = RANGE_MID) then
       chance := 0.02
  else begin
       Result := False;
       Exit;
  end;

  if (skill^.value = 0) then
     { TODO:  Translate the Line Below: }
     chance := (chance * 0.5)
  else if (skill^.value >= 2) then
       { TODO:  Translate the Line Below: }
       chance := (chance * 2);

  if (_random() < chance) then begin
     self^.monsterinfo.attack_state := AS_MISSILE;
     self^.monsterinfo.attack_finished := level.time + (2 * _random());
     Result := True;
     Exit;
  end;

  if (self^.flags AND FL_FLY <> 0) then begin
     if (_random() < 0.3) then
        self^.monsterinfo.attack_state := AS_SLIDING
     else
        self^.monsterinfo.attack_state := AS_STRAIGHT;
  end;

  Result := False;
end;

(* =============
ai_run_melee

Turn and close until within an angle to launch a melee attack
============= *)
procedure ai_run_melee(self: edict_p);
begin
  self^.ideal_yaw := enemy_yaw;
  M_ChangeYaw(self);

  if (FacingIdeal(self)) then begin
     self^.monsterinfo.melee(self);
     self^.monsterinfo.attack_state := AS_STRAIGHT;
  end;
end;

(* =============
ai_run_missile

Turn in place until within an angle to launch a missile attack
============= *)
procedure ai_run_missile(self: edict_p);
begin
  self^.ideal_yaw := enemy_yaw;
  M_ChangeYaw(self);

  if (FacingIdeal(self)) then begin
     self^.monsterinfo.attack(self);
     self^.monsterinfo.attack_state := AS_STRAIGHT;
  end;
end;

(* =============
ai_run_slide

Strafe sideways, but stay at aproximately the same range
============= *)
procedure ai_run_slide(self: edict_p; distance: Single);
var
  ofs: Single;
begin
  self^.ideal_yaw := enemy_yaw;
  M_ChangeYaw(self);

  if (self^.monsterinfo.lefty <> 0) then
     ofs := 90
  else
     ofs := -90;

  if (M_walkmove(self, self^.ideal_yaw + ofs, distance)) then
     Exit;

  self^.monsterinfo.lefty := (1 - self^.monsterinfo.lefty);
  M_walkmove(self, (self^.ideal_yaw - ofs), distance);
end;

(* =============
ai_checkattack

Decides if we're going to attack or do something else
used by ai_run and ai_stand
============= *)
function ai_checkattack(self: edict_p; dist: Single): qboolean;
var
  temp: vec3_t;
  hesDeadJim: qboolean;
begin
  { this causes monsters to run blindly to the combat point w/o firing }
  if (self^.goalentity <> nil) then begin
     if (self^.monsterinfo.aiflags AND AI_COMBAT_POINT) <> 0 then begin
        Result := False;
        Exit;
     end;

     if (self^.monsterinfo.aiflags AND AI_SOUND_TARGET) <> 0 then begin
        if ((level.time - self^.enemy^.teleport_time) > 5.0) then begin
           if (self^.goalentity = self^.enemy) then begin
              if (self^.movetarget <> nil) then
                 self^.goalentity := self^.movetarget
              else
                 self^.goalentity := Nil;
           end;

           { TODO:  Translate the Line Below: }
           // ORIGINAL:  self->monsterinfo.aiflags &= ~AI_SOUND_TARGET;
           self^.monsterinfo.aiflags := self^.monsterinfo.aiflags AND (NOT AI_SOUND_TARGET);
           if (self^.monsterinfo.aiflags AND AI_TEMP_STAND_GROUND) <> 0 then
              { TODO:  Translate the Line Below: }
              // ORIGINAL:  self->monsterinfo.aiflags &= ~(AI_STAND_GROUND | AI_TEMP_STAND_GROUND);
              self^.monsterinfo.aiflags := self^.monsterinfo.aiflags AND (NOT (AI_STAND_GROUND OR AI_TEMP_STAND_GROUND));
        end else begin
                if level.time+1 > 0 then
            self^.show_hostile :=true;// (level.time + 1);
            Result := False;
            Exit;
        end;
     end;
  end;

  enemy_vis := False;

  { see if the enemy is dead }
  hesDeadJim := False;
  { TODO:  Translate the Line Below: }
  if ((self^.enemy = Nil) OR (NOT self^.enemy^.inuse)) then
     hesDeadJim := True
  else if (self^.monsterinfo.aiflags AND AI_MEDIC <> 0) then begin
       if (self^.enemy^.health > 0) then begin
          hesDeadJim := True;
          { TODO:  Translate the Line Below: }
          // ORIGINAL:  self->monsterinfo.aiflags &= ~AI_MEDIC;
          self^.monsterinfo.aiflags := self^.monsterinfo.aiflags AND (NOT AI_MEDIC);
       end;
  end else begin
      if (self^.monsterinfo.aiflags AND AI_BRUTAL) <> 0 then begin
         if (self^.enemy^.health <= -80) then
            hesDeadJim := True;
      end else begin
          if (self^.enemy^.health <= 0) then
             hesDeadJim := True;
      end;
  end;

  if (hesDeadJim) then begin
     self^.enemy := Nil;
     // FIXME: look all around for other targets
     { TODO:  Translate the Line Below: }
     // ORIGINAL:  if (self->oldenemy && self->oldenemy->health > 0)
     if ((self^.oldenemy <> Nil) AND (self^.oldenemy^.health > 0)) then begin
        self^.enemy := self^.oldenemy;
        self^.oldenemy := Nil;
        HuntTarget(self);
     end else begin
         if (self^.movetarget <> nil) then begin
            self^.goalentity := self^.movetarget;
            self^.monsterinfo.walk(self);
         end else begin
             { we need the pausetime otherwise the stand code
               will just revert to walking with no target and
               the monsters will wonder around aimlessly trying
               to hunt the world entity }
             self^.monsterinfo.pausetime := (level.time + 100000000);
             self^.monsterinfo.stand(self);
         end;

         Result := True;
         Exit;
     end;
  end;

  { wake up other monsters }
  if level.time+1 > 0 then
  self^.show_hostile :=true;// (level.time + 1);

  { check knowledge of enemy }
  enemy_vis := visible(self, self^.enemy);
  if (enemy_vis) then begin
     self^.monsterinfo.search_time := (level.time + 5);
     VectorCopy(self^.enemy^.s.origin, self^.monsterinfo.last_sighting);
  end;

  // look for other coop players here
  //   if (coop && self->monsterinfo.search_time < level.time)
  //   {
  //      if (FindTarget (self))
  //         return true;
  //   }

  enemy_infront := infront(self, self^.enemy);
  enemy_range := range(self, self^.enemy);
  VectorSubtract(self^.enemy^.s.origin, self^.s.origin, temp);
  enemy_yaw := vectoyaw(temp);


  // JDC self->ideal_yaw = enemy_yaw;

  if (self^.monsterinfo.attack_state = AS_MISSILE) then begin
     ai_run_missile(self);
     Result := True;
     Exit;
  end;

  if (self^.monsterinfo.attack_state = AS_MELEE) then begin
     ai_run_melee(self);
     Result := True;
     Exit;
  end;

  { if enemy is not currently visible, we will never attack }
  if (NOT enemy_vis) then begin
     Result := False;
     Exit;
  end;

  Result := self^.monsterinfo.checkattack(self);
end;

(* =============
ai_run

The monster has an enemy it is trying to kill
============= *)
procedure ai_run(self: edict_p; dist: Single);
var
  v, v_forward, v_right, left_target, right_target: vec3_t;
  tempgoal, save, marker: edict_p;
  new: qboolean;
  d1, d2, left, center, right: Single {float};
  tr: trace_t;
begin
  { Originally Removed comments by ID start the line like:
//             eg...}
  { if we're going to a combat point, just proceed }
  if (self^.monsterinfo.aiflags AND AI_COMBAT_POINT) <> 0 then begin
     M_MoveToGoal(self, dist);
     Exit;
  end;

  if (self^.monsterinfo.aiflags AND AI_SOUND_TARGET) <> 0 then begin
     VectorSubtract(self^.s.origin, self^.enemy^.s.origin, v);
     if (VectorLength(v) < 64) then begin
        { TODO:  Translate the Line Below: }
        // ORIGINAL:  self^.monsterinfo.aiflags |= (AI_STAND_GROUND OR AI_TEMP_STAND_GROUND);
        self^.monsterinfo.aiflags := self^.monsterinfo.aiflags OR (AI_STAND_GROUND OR AI_TEMP_STAND_GROUND);
        self^.monsterinfo.stand(self);
        Exit;
     end;

     M_MoveToGoal(self, dist);

     if (NOT FindTarget(self)) then
        Exit;
  end;

  if (ai_checkattack(self, dist)) then
     Exit;

  if (self^.monsterinfo.attack_state = AS_SLIDING) then begin
     ai_run_slide(self, dist);
     Exit;
  end;

  if (enemy_vis) then begin
//      if (self.aiflags & AI_LOST_SIGHT)
//         dprint("regained sight\n");
     M_MoveToGoal(self, dist);
     { TODO:  Translate the Line Below: }
     // ORIGINAL:  self->monsterinfo.aiflags &= ~AI_LOST_SIGHT;
     self^.monsterinfo.aiflags := self^.monsterinfo.aiflags AND (NOT AI_LOST_SIGHT);
     VectorCopy(self^.enemy^.s.origin, self^.monsterinfo.last_sighting);
     self^.monsterinfo.trail_time := level.time;
     Exit;
  end;

  { coop will change to another enemy if visible }
  if (coop^.value <> 0) then begin
     // FIXME: insane guys get mad with this, which causes crashes!
     if (FindTarget(self)) then
        Exit;
  end;

  { TODO:  Translate the Line Below: }
  // ORIGINAL:  if ((self->monsterinfo.search_time) && (level.time > (self->monsterinfo.search_time + 20)))
  if ((self^.monsterinfo.search_time <> 0) AND (level.time > (self^.monsterinfo.search_time + 20))) then begin
     M_MoveToGoal(self, dist);
     self^.monsterinfo.search_time := 0;
//      dprint("search timeout\n");
     Exit;
  end;

  save := self^.goalentity;
  tempgoal := G_Spawn();
  self^.goalentity := tempgoal;

  new := False;

  if ((self^.monsterinfo.aiflags AND AI_LOST_SIGHT) = 0) then begin
          // just lost sight of the player, decide where to go first
//      dprint("lost sight of player, last seen at "); dprint(vtos(self.last_sighting)); dprint("\n");
     { TODO:  Translate the Line Below: }
     // ORIGINAL:  self->monsterinfo.aiflags |= (AI_LOST_SIGHT | AI_PURSUIT_LAST_SEEN);
     self^.monsterinfo.aiflags := self^.monsterinfo.aiflags OR (AI_LOST_SIGHT OR AI_PURSUIT_LAST_SEEN);
     { TODO:  Translate the Line Below: }
     // ORIGINAL:  self->monsterinfo.aiflags &= ~(AI_PURSUE_NEXT | AI_PURSUE_TEMP);
     self^.monsterinfo.aiflags := self^.monsterinfo.aiflags AND (NOT (AI_PURSUE_NEXT OR AI_PURSUE_TEMP));
     new := True;
  end;

  if (self^.monsterinfo.aiflags AND AI_PURSUE_NEXT) <> 0 then begin
     { TODO:  Translate the Line Below: }
     // ORIGINAL:  self^.monsterinfo.aiflags &= ~AI_PURSUE_NEXT;
     self^.monsterinfo.aiflags := self^.monsterinfo.aiflags AND (NOT AI_PURSUE_NEXT);
//      dprint("reached current goal: "); dprint(vtos(self.origin)); dprint(" "); dprint(vtos(self.last_sighting)); dprint(" "); dprint(ftos(vlen(self.origin - self.last_sighting))); dprint("\n");

     { give ourself more time since we got this far }
     self^.monsterinfo.search_time := (level.time + 5);

     if (self^.monsterinfo.aiflags AND AI_PURSUE_TEMP <> 0) then begin
//         dprint("was temp goal; retrying original\n");
        { TODO:  Translate the Line Below: }
        // ORIGINAL:  self->monsterinfo.aiflags &= ~AI_PURSUE_TEMP;
        self^.monsterinfo.aiflags := self^.monsterinfo.aiflags AND (NOT AI_PURSUE_TEMP);
        marker := Nil;
        VectorCopy(self^.monsterinfo.saved_goal, self^.monsterinfo.last_sighting);
        new := True;
     end else if (self^.monsterinfo.aiflags AND AI_PURSUIT_LAST_SEEN <> 0) then begin
         { TODO:  Translate the Line Below: }
         // ORIGINAL:  self^.monsterinfo.aiflags &= ~AI_PURSUIT_LAST_SEEN;
         self^.monsterinfo.aiflags := self^.monsterinfo.aiflags AND (NOT AI_PURSUIT_LAST_SEEN);
         marker := PlayerTrail_PickFirst(self^);
     end else begin
         marker := PlayerTrail_PickNext(self^);
     end;

     if (marker <> nil) then begin
        VectorCopy(marker^.s.origin, self^.monsterinfo.last_sighting);
        self^.monsterinfo.trail_time := marker^.timestamp;
        // self->s.angles[YAW] = self->ideal_yaw = marker->s.angles[YAW];
        self^.ideal_yaw := marker^.s.angles[YAW];
        self^.s.angles[YAW] := self^.ideal_yaw;
//         dprint("heading is "); dprint(ftos(self.ideal_yaw)); dprint("\n");

//         debug_drawline(self.origin, self.last_sighting, 52);
        new := True;
     end;
  end;

  VectorSubtract(self^.s.origin, self^.monsterinfo.last_sighting, v);
  d1 := VectorLength(v);
  if (d1 <= dist) then begin
     { TODO:  Translate the Line Below: }
     // ORIGINAL:  self^.monsterinfo.aiflags |= AI_PURSUE_NEXT;
     self^.monsterinfo.aiflags := self^.monsterinfo.aiflags OR AI_PURSUE_NEXT;
     dist := d1;
  end;

  VectorCopy(self^.monsterinfo.last_sighting, self^.goalentity^.s.origin);

  if (new) then begin
//      gi.dprintf("checking for course correction\n");

     tr := gi.trace(@self^.s.origin, @self^.mins, @self^.maxs, @self^.monsterinfo.last_sighting, self, MASK_PLAYERSOLID);
     if (tr.fraction < 1) then begin
        VectorSubtract(self^.goalentity^.s.origin, self^.s.origin, v);
        d1 := VectorLength(v);
        center := tr.fraction;
        d2 := (d1 * ((center + 1) / 2));
        //self^.s.angles[YAW] = self^.ideal_yaw = vectoyaw(v);
        self^.ideal_yaw := vectoyaw(v);
        self^.s.angles[YAW] := self^.ideal_yaw;
        AngleVectors(self^.s.angles, @v_forward, @v_right, Nil);

        VectorSet(v, d2, -16, 0);
        G_ProjectSource(self^.s.origin, v, v_forward, v_right, left_target);
        tr := gi.trace(@self^.s.origin, @self^.mins, @self^.maxs, @left_target, self, MASK_PLAYERSOLID);
        left := tr.fraction;

        VectorSet(v, d2, 16, 0);
        G_ProjectSource(self^.s.origin, v, v_forward, v_right, right_target);
        tr := gi.trace(@self^.s.origin, @self^.mins, @self^.maxs, @right_target, self, MASK_PLAYERSOLID);
        right := tr.fraction;

        center := ((d1 * center) / d2);
        { TODO:  Translate the Line Below: }
        // ORIGINAL:  if (left >= center && left > right)
        if ((left >= center) AND (left > right)) then begin
           if (left < 1) then begin
              VectorSet(v, (d2 * left * 0.5), -16, 0);
              G_ProjectSource(self^.s.origin, v, v_forward, v_right, left_target);
//               gi.dprintf("incomplete path, go part way and adjust again\n");
           end;
           VectorCopy(self^.monsterinfo.last_sighting, self^.monsterinfo.saved_goal);
           { TODO:  Translate the Line Below: }
           // ORIGINAL:  self->monsterinfo.aiflags |= AI_PURSUE_TEMP;
           self^.monsterinfo.aiflags := self^.monsterinfo.aiflags OR AI_PURSUE_TEMP;
           VectorCopy(left_target, self^.goalentity^.s.origin);
           VectorCopy(left_target, self^.monsterinfo.last_sighting);
           VectorSubtract(self^.goalentity^.s.origin, self^.s.origin, v);
           //self^.s.angles[YAW] = self^.ideal_yaw = vectoyaw(v);
           self^.ideal_yaw := vectoyaw(v);
           self^.s.angles[YAW] := self^.ideal_yaw;
//            gi.dprintf("adjusted left\n");
//            debug_drawline(self.origin, self.last_sighting, 152);
        { TODO:  Translate the Line Below: }
        end else if ((right >= center) AND (right > left)) then begin
            if (right < 1) then begin
               VectorSet(v, (d2 * right * 0.5), 16, 0);
               G_ProjectSource(self^.s.origin, v, v_forward, v_right, right_target);
//               gi.dprintf("incomplete path, go part way and adjust again\n");
            end;
            VectorCopy(self^.monsterinfo.last_sighting, self^.monsterinfo.saved_goal);
            { TODO:  Translate the Line Below: }
            // ORIGINAL:  self->monsterinfo.aiflags |= AI_PURSUE_TEMP;
            self^.monsterinfo.aiflags := self^.monsterinfo.aiflags OR AI_PURSUE_TEMP;
            VectorCopy(right_target, self^.goalentity^.s.origin);
            VectorCopy(right_target, self^.monsterinfo.last_sighting);
            VectorSubtract(self^.goalentity^.s.origin, self^.s.origin, v);
            //self^.s.angles[YAW] = self^.ideal_yaw = vectoyaw(v);
            self^.ideal_yaw := vectoyaw(v);
            self^.s.angles[YAW] := self^.ideal_yaw;
//            gi.dprintf("adjusted right\n");
//            debug_drawline(self.origin, self.last_sighting, 152);
        end;
     end;
//      else gi.dprintf("course was fine\n");
  end;

  M_MoveToGoal(self, dist);

  G_FreeEdict(tempgoal);

  if (self <> nil) then
     self^.goalentity := save;
end;

end.
