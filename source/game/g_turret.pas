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
{ File(s): g_turret.c                                                        }
{                                                                            }
{ Initial conversion by : Ben Watt (ben@delphigamedev.com)                   }
{ Initial conversion on : 12-Feb-2002                                        }
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
{               Corrected pointer dereferences, and some minor conversion    }
{               errors such as excluded ~ operator effects on logic          }
{                                                                            }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{                                                                            }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{                                                                            }
{----------------------------------------------------------------------------}

unit g_turret;

interface

uses
  g_local,
  q_shared;

procedure AnglesNormalize(var vec : vec3_t);
function  SnapToEights(x : single): Single;
procedure turret_blocked(self, other : edict_p); cdecl;
procedure turret_breach_fire(self : edict_p); cdecl;
procedure turret_breach_think(self : edict_p); cdecl;
procedure turret_breach_finish_init(self : edict_p); cdecl;
procedure SP_turret_breach(self : edict_p); cdecl;
procedure SP_turret_base(self : edict_p); cdecl;
procedure turret_driver_die(self, inflictor, attacker : edict_p; damage : integer; const point : vec3_t); cdecl;
procedure turret_driver_think(self : edict_p); cdecl;
procedure turret_driver_link(self : edict_p); cdecl;
procedure SP_turret_driver(self : edict_p); cdecl;

implementation

uses math, g_local_add, g_combat, g_main, g_weapon, CPas, g_utils,
  game_add, m_infantry, g_ai, GameUnit, g_monster, g_items;

procedure AnglesNormalize(var vec : vec3_t);
begin
  while vec[0] > 360 do
    vec[0] := vec[0] - 360;
  while vec[0] < 0 do
    vec[0] := vec[0] + 360;
  while vec[1] > 360 do
    vec[1] := vec[1] - 360;
  while vec[1] < 0 do
    vec[1] := vec[1] + 360;
end;

function SnapToEights(x : single): Single;
begin
  x := x*8.0;
  if x > 0.0 then
    x := x+0.5
  else
    x := x-0.5;
  Result := 0.125 * {TODO:Int}Trunc(x);  { TODO:  Should this have been left as Int()? }
end;


procedure turret_blocked(self, other : edict_p);
var
  attacker : edict_p;
begin
  if other^.takedamage <> DAMAGE_NO then
  begin
    if self^.teammaster^.owner <> nil then
      attacker := self^.teammaster^.owner
    else
      attacker := self^.teammaster;
    T_Damage(other, self, attacker, vec3_origin, other^.s.origin, vec3_origin, self^.teammaster^.dmg, 10, 0, MOD_CRUSH);
  end;
end;

{QUAKED turret_breach (0 0 0) ?
This portion of the turret can change both pitch and yaw.
The model  should be made with a flat pitch.
It (and the associated base) need to be oriented towards 0.
Use "angle" to set the starting angle.

"speed"      default 50
"dmg"      default 10
"angle"      point this forward
"target"   point this at an info_notnull at the muzzle tip
"minpitch"   min acceptable pitch angle : default -30
"maxpitch"   max acceptable pitch angle : default 30
"minyaw"   min acceptable yaw angle   : default 0
"maxyaw"   max acceptable yaw angle   : default 360
}

procedure turret_breach_fire(self : edict_p);
var
  f, r, u : vec3_t;
  start   : vec3_t;
  damage  : integer;
  speed   : integer;
begin
  AngleVectors(self^.s.angles, @f, @r, @u);
  VectorMA(self^.s.origin, self^.move_origin[0], f, start);
  VectorMA(start, self^.move_origin[1], r, start);
  VectorMA(start, self^.move_origin[2], u, start);

  damage := 100 + trunc(_random() * 50);
  speed := 550 + 50 * trunc(skill^.Value);
  fire_rocket(self^.teammaster^.owner, start, f, damage, speed, 150, damage);
  gi.positioned_sound(@start, self, CHAN_WEAPON, gi.soundindex('weapons/rocklf1a.wav'), 1, ATTN_NORM, 0);
end;

procedure turret_breach_think(self : edict_p);
var
  ent            : edict_p;
  current_angles : vec3_t;
  delta          : vec3_t;

  dmin, dmax     : single;

  angle          : single;
  target_z       : single;
  diff           : single;
  target         : vec3_t;
  dir            : vec3_t;
begin
  VectorCopy(self^.s.angles, current_angles);
  AnglesNormalize(current_angles);

  AnglesNormalize(self^.move_angles);
  if self^.move_angles[PITCH] > 180 then
    self^.move_angles[PITCH] := self^.move_angles[PITCH] - 360;

  // clamp angles to mins & maxs
  if self^.move_angles[PITCH] > self^.pos1[PITCH] then
    self^.move_angles[PITCH] := self^.pos1[PITCH]
  else if self^.move_angles[PITCH] < self^.pos2[PITCH] then
    self^.move_angles[PITCH] := self^.pos2[PITCH];

  if (self^.move_angles[YAW] < self^.pos1[YAW]) or (self^.move_angles[YAW] > self^.pos2[YAW]) then
  begin
    dmin := fabs(self^.pos1[YAW] - self^.move_angles[YAW]);
    if dmin < -180 then
      dmin := dmin + 360
    else if dmin > 180 then
      dmin := dmin - 360;
    dmax := fabs(self^.pos2[YAW] - self^.move_angles[YAW]);
    if dmax < -180 then
      dmax := dmax + 360
    else if dmax > 180 then
      dmax := dmax - 360;
    if fabs(dmin) < fabs(dmax) then
      self^.move_angles[YAW] := self^.pos1[YAW]
    else
      self^.move_angles[YAW] := self^.pos2[YAW];
  end;

  VectorSubtract(self^.move_angles, current_angles, delta);
  if delta[0] < -180 then
    delta[0] := delta[0] + 360
  else if delta[0] > 180 then
    delta[0] := delta[0] - 360;
  if delta[1] < -180 then
    delta[1] := delta[1] + 360
  else if delta[1] > 180 then
    delta[1] := delta[1] - 360;
  delta[2] := 0;

  if delta[0] > (self^.speed * FRAMETIME) then
    delta[0] := self^.speed * FRAMETIME;
  if delta[0] < (-1 * self^.speed * FRAMETIME) then
    delta[0] := -1 * self^.speed * FRAMETIME;
  if delta[1] > (self^.speed * FRAMETIME) then
    delta[1] := self^.speed * FRAMETIME;
  if delta[1] < (-1 * self^.speed * FRAMETIME) then
    delta[1] := -1 * self^.speed * FRAMETIME;

  VectorScale(delta, 1.0/FRAMETIME, self^.avelocity);

  self^.nextthink := level.time + FRAMETIME;

  ent := self^.teammaster;
  while (ent <> nil) do
  begin
    ent^.avelocity[1] := self^.avelocity[1];
    ent := ent^.teamchain;
  end;

  // if we have adriver, adjust his velocities
  if self^.owner <> nil then
  begin
    // angular is easy, just copy ours
    self^.owner^.avelocity[0] := self^.avelocity[0];
    self^.owner^.avelocity[1] := self^.avelocity[1];

    // x & y
    angle := self^.s.angles[1] + self^.owner^.move_origin[1];
    angle := angle * (M_PI*2 / 360);
    target[0] := SnapToEights(self^.s.origin[0] + cos(angle) * self^.owner^.move_origin[0]);
    target[1] := SnapToEights(self^.s.origin[1] + sin(angle) * self^.owner^.move_origin[0]);
    target[2] := self^.owner^.s.origin[2];

    VectorSubtract(target, self^.owner^.s.origin, dir);
    self^.owner^.velocity[0] := dir[0] * 1.0 / FRAMETIME;
    self^.owner^.velocity[1] := dir[1] * 1.0 / FRAMETIME;

    // z
    angle := self^.s.angles[PITCH] * (M_PI*2 / 360);
    target_z := SnapToEights(self^.s.origin[2] + self^.owner^.move_origin[0] * tan(angle) + self^.owner^.move_origin[2]);

    diff := target_z - self^.owner^.s.origin[2];
    self^.owner^.velocity[2] := diff * 1.0 / FRAMETIME;

    if (self^.spawnflags and 65536) <> 0 then
    begin
      turret_breach_fire(self);
      self^.spawnflags := self^.spawnflags and (NOT 65536);
    end;
  end;
end;

procedure turret_breach_finish_init(self : edict_p);
begin
  // get and save info for muzzle location
  if (self^.target = nil) then
    gi.dprintf('%s at %s needs a target', self^.classname, vtos(self^.s.origin))
  else
  begin
    self^.target_ent := G_PickTarget(self^.target);
    VectorSubtract(self^.target_ent^.s.origin, self^.s.origin, self^.move_origin);
    G_FreeEdict(self^.target_ent);
  end;

  self^.teammaster^.dmg := self^.dmg;
  self^.think := turret_breach_think;
  self^.think(self);
end;

procedure SP_turret_breach(self : edict_p);
begin
  self^.solid := SOLID_BSP;
  self^.movetype := MOVETYPE_PUSH;
  gi.setmodel(self, self^.model);

  if (self^.speed = 0) then
    self^.speed := 50;
  if (self^.dmg = 0) then
    self^.dmg := 10;

  if (st.minpitch = 0) then
    st.minpitch := -30;
  if (st.maxpitch = 0) then
    st.maxpitch := 30;
  if (st.maxyaw = 0) then
    st.maxyaw := 360;

  self^.pos1[PITCH] := -1 * st.minpitch;
  self^.pos1[YAW]   := st.minyaw;
  self^.pos2[PITCH] := -1 * st.maxpitch;
  self^.pos2[YAW]   := st.maxyaw;

  self^.ideal_yaw := self^.s.angles[YAW];
  self^.move_angles[YAW] := self^.ideal_yaw;

  self^.blocked := turret_blocked;

  self^.think := turret_breach_finish_init;
  self^.nextthink := level.time + FRAMETIME;
  gi.linkentity(self);
end;


{QUAKED turret_base (0 0 0) ?
This portion of the turret changes yaw only.
MUST be teamed with a turret_breach.
}

procedure SP_turret_base(self : edict_p);
begin
  self^.solid := SOLID_BSP;
  self^.movetype := MOVETYPE_PUSH;
  gi.setmodel(self, self^.model);
  self^.blocked := turret_blocked;
  gi.linkentity(self);
end;


{QUAKED turret_driver (1 .5 0) (-16 -16 -24) (16 16 32)
Must NOT be on the team with the rest of the turret parts.
Instead it must target the turret_breach.
}

procedure turret_driver_die(self, inflictor, attacker : edict_p; damage : integer; const point : vec3_t);
var
  ent : edict_p;
begin

  // level the gun
  self^.target_ent^.move_angles[0] := 0;

  // remove the driver from the end of them team chain
  ent := self^.target_ent^.teammaster;
  while (ent^.teamchain <> self) do
  begin
    ent := ent^.teamchain;
  end;
  ent^.teamchain := nil;
  self^.teammaster := nil;
  self^.flags := self^.flags and (NOT FL_TEAMSLAVE);

  self^.target_ent^.owner := nil;
  self^.target_ent^.teammaster^.owner := nil;

  infantry_die(self, inflictor, attacker, damage, point);
end;

procedure turret_driver_think(self : edict_p); cdecl;
var
  target        : vec3_t;
  dir           : vec3_t;
  reaction_time : single;
begin
  self^.nextthink := level.time + FRAMETIME;

  if (self^.enemy <> nil) and ((not self^.enemy^.inuse) or (self^.enemy^.health <= 0)) then
    self^.enemy := nil;

  if (self^.enemy = nil) then
  begin
    if not(FindTarget(self)) then
      Exit;
    self^.monsterinfo.trail_time := level.time;
    self^.monsterinfo.aiflags := self^.monsterinfo.aiflags and (NOT AI_LOST_SIGHT);
  end
  else
  begin
    if visible(self, self^.enemy) then
    begin
      if (self^.monsterinfo.aiflags and AI_LOST_SIGHT) <> 0 then
      begin
        self^.monsterinfo.trail_time := level.time;
        self^.monsterinfo.aiflags := self^.monsterinfo.aiflags and (NOT AI_LOST_SIGHT);
      end;
    end
    else
    begin
      self^.monsterinfo.aiflags := self^.monsterinfo.aiflags or AI_LOST_SIGHT;
      Exit;
    end;
  end;

  // let the turret know where we want it to aim
  VectorCopy(self^.enemy^.s.origin, target);
  target[2] := target[2] + self^.enemy^.viewheight;
  VectorSubtract(target, self^.target_ent^.s.origin, dir);
  vectoangles(dir, self^.target_ent^.move_angles);

  // decide if we should shoot
  if level.time < self^.monsterinfo.attack_finished then
    Exit;

  reaction_time := (3 - skill^.value) * 1.0;
  if (level.time - self^.monsterinfo.trail_time) < reaction_time then
    Exit;

  self^.monsterinfo.attack_finished := level.time + reaction_time + 1.0;
  //FIXME how do we really want to pass this along?
  self^.target_ent^.spawnflags := self^.target_ent^.spawnflags or 65536;
end;

procedure turret_driver_link(self : edict_p);
var
  vec : vec3_t;
  ent : edict_p;
begin
  self^.think := turret_driver_think;
  self^.nextthink := level.time + FRAMETIME;

  self^.target_ent := G_PickTarget(self^.target);
  self^.target_ent^.owner := self;
  self^.target_ent^.teammaster^.owner := self;
  VectorCopy(self^.target_ent^.s.angles, self^.s.angles);

  vec[0] := self^.target_ent^.s.origin[0] - self^.s.origin[0];
  vec[1] := self^.target_ent^.s.origin[1] - self^.s.origin[1];
  vec[2] := 0;
  self^.move_origin[0] := VectorLength(vec);

  VectorSubtract(self^.s.origin, self^.target_ent^.s.origin, vec);
  vectoangles(vec, vec);
  AnglesNormalize(vec);
  self^.move_origin[1] := vec[1];

  self^.move_origin[2] := self^.s.origin[2] - self^.target_ent^.s.origin[2];

  // add the driver to the end of them team chain
  ent := self^.target_ent^.teammaster;
  while (ent^.teamchain <> nil) do
    ent := ent^.teamchain;

  ent^.teamchain := self;
  self^.teammaster := self^.target_ent^.teammaster;
  self^.flags := self^.flags or FL_TEAMSLAVE;
end;

procedure SP_turret_driver(self : edict_p);
begin
  if deathmatch^.value <> 0 then
  begin
    G_FreeEdict(self);
    Exit;
  end;

  self^.movetype := MOVETYPE_PUSH;
  self^.solid := SOLID_BBOX;
  self^.s.modelindex := gi.modelindex('models/monsters/infantry/tris.md2');
  VectorSet(self^.mins, -16, -16, -24);
  VectorSet(self^.maxs, 16, 16, 32);

  self^.health := 100;
  self^.gib_health := 0;
  self^.mass := 200;
  self^.viewheight := 24;

  self^.die := turret_driver_die;
  self^.monsterinfo.stand := infantry_stand;

  self^.flags := self^.flags or FL_NO_KNOCKBACK;

  level.total_monsters := level.total_monsters + 1;

  self^.svflags := self^.svflags or SVF_MONSTER;
  self^.s.renderfx := self^.s.renderfx or RF_FRAMELERP;
  self^.takedamage := DAMAGE_AIM;
  self^.use := monster_use;
  self^.clipmask := MASK_MONSTERSOLID;
  VectorCopy(self^.s.origin, self^.s.old_origin);
  self^.monsterinfo.aiflags := self^.monsterinfo.aiflags or (AI_STAND_GROUND or AI_DUCKED);

  if st.item <> nil then
  begin
    self^.item := FindItemByClassname(st.item);
    if (self^.item = nil) then
      gi.dprintf('%s at %s has bad item: %s'#10, self^.classname, vtos(self^.s.origin), st.item);
  end;

  self^.think := turret_driver_link;
  self^.nextthink := level.time + FRAMETIME;

  gi.linkentity(self);
end;

end.
