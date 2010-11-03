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
{ File(s): game\g_misc.c                                                     }
{ Content: Saving and loading games                                          }
{                                                                            }
{ Initial conversion by: Carl A Kenner (carlkenner@hotmail.com)              }
{ Initial conversion on: 1-Mar-2002                                          }
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
{ Updated on: 3-Mar-2002                                                     }
{ Updated by: Carl A Kenner                                                  }
{                                                                            }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{ g_utils.G_FreeEdict, g_combat, m_move, g_func                              }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{ Remaining functions                                                        }
{----------------------------------------------------------------------------}
unit g_misc;


interface

uses
  g_combat,
  m_move,
  g_func,
  q_shared,
  q_shared_add,
  game_add,
  GameUnit,
  g_save,
  g_utils,
  g_local_add,
  g_local;


procedure ThrowGib(self: edict_p; gibname: PChar; damage, _type: Integer);
procedure ThrowHead(self: edict_p; gibname: PChar; damage, _type: integer);
procedure ThrowClientHead(self: edict_p; damage: Integer);

procedure ThrowDebris(self: edict_p; modelname: PChar; speed: Single; const origin: vec3_t);

procedure BecomeExplosion1(self: edict_p);

procedure SP_func_areaportal(ent: edict_p); cdecl;
procedure SP_path_corner(self: edict_p); cdecl;
procedure SP_point_combat(self: edict_p); cdecl;
procedure SP_viewthing(ent: edict_p); cdecl;
procedure SP_info_null(self: edict_p); cdecl;
procedure SP_info_notnull(self: edict_p); cdecl;
procedure SP_light(self: edict_p); cdecl;
procedure SP_func_wall(self: edict_p); cdecl;
procedure SP_func_object(self: edict_p); cdecl;
procedure SP_func_explosive(self: edict_p); cdecl;
procedure SP_misc_explobox(self: edict_p); cdecl;
procedure SP_misc_blackhole(ent: edict_p); cdecl;
procedure SP_misc_eastertank(ent: edict_p); cdecl;
procedure SP_misc_easterchick(ent: edict_p); cdecl;
procedure SP_misc_easterchick2(ent: edict_p); cdecl;
procedure SP_monster_commander_body(self: edict_p); cdecl;
procedure SP_misc_banner(ent: edict_p); cdecl;
procedure SP_misc_deadsoldier(ent: edict_p); cdecl;
procedure SP_misc_viper (ent: edict_p); cdecl;
procedure SP_misc_bigviper(ent: edict_p); cdecl;
procedure SP_misc_viper_bomb(self: edict_p); cdecl;
procedure SP_misc_strogg_ship(ent: edict_p); cdecl;
procedure SP_misc_satellite_dish(ent: edict_p); cdecl;
procedure SP_light_mine1(ent: edict_p); cdecl;
procedure SP_light_mine2(ent: edict_p); cdecl;
procedure SP_misc_gib_arm(ent: edict_p); cdecl;
procedure SP_misc_gib_leg(ent: edict_p); cdecl;
procedure SP_misc_gib_head(ent: edict_p); cdecl;
procedure SP_target_character(self: edict_p); cdecl;
procedure SP_target_string(self: edict_p); cdecl;
procedure SP_func_clock(self: edict_p); cdecl;
procedure SP_misc_teleporter(ent: edict_p); cdecl;
procedure SP_misc_teleporter_dest(ent: edict_p); cdecl;

implementation

Uses
  SysUtils,
  DateUtils,
  g_monster,
  g_main,
  CPas;



// g_misc.c

(*QUAKED func_group (0 0 0) ?
Used to group brushes together just for editor convenience.
*)

//====================================================:=

procedure Use_Areaportal(ent, other, activator: edict_p); cdecl;
begin
  ent.count := ent.count XOR 1;   // toggle state
//  gi_dprintf('portalstate: %i = %i\n', [ent.style, ent.count]);
  gi.SetAreaPortalState(ent.style, ent.count<>0);
end;

(*QUAKED func_areaportal (0 0 0) ?

This is a non-visible object that divides the world into
areas that are seperated when this portal is not activated.
Usually enclosed in the middle of a door.
*)
procedure SP_func_areaportal(ent: edict_p); {cdecl;}
begin
  ent.use := Use_Areaportal;
  ent.count := 0; // always start closed;
end;

//=====================================================


(*
=================
Misc functions
=================
*)
procedure VelocityForDamage(damage: Integer; var v: vec3_t);
begin
  v[0] := 100.0 * crandom();
  v[1] := 100.0 * crandom();
  v[2] := 200.0 + 100.0 * _random();

  if damage < 50 then
    VectorScale (v, 0.7, v)
  else
    VectorScale (v, 1.2, v);
end;

procedure ClipGibVelocity(ent: edict_p);
begin
  if ent.velocity[0] < -300 then
    ent.velocity[0] := -300
  else if ent.velocity[0] > 300 then
    ent.velocity[0] := 300;
  if ent.velocity[1] < -300 then
    ent.velocity[1] := -300
  else if ent.velocity[1] > 300 then
    ent.velocity[1] := 300;
  if ent.velocity[2] < 200 then
    ent.velocity[2] := 200 // always some upwards
  else if ent.velocity[2] > 500 then
    ent.velocity[2] := 500;
end;


(*
=================
gibs
=================
*)
procedure gib_think(self: edict_p); cdecl;
begin
  Inc(self.s.frame);
  self.nextthink := level.time + FRAMETIME;

  if self.s.frame = 10 then
  begin
    self.think := G_FreeEdict;
    self.nextthink := level.time + 8 + _random()*10;
  end;
end;

procedure gib_touch(self, other: edict_p; plane: cplane_p; surf: csurface_p); cdecl;
Var normal_angles, right: vec3_t;
begin
  if self.groundentity=Nil then
    exit;

  self.touch := Nil;

  if plane<>Nil then
  begin
    gi.sound (self, CHAN_VOICE, gi.soundindex ('misc/fhit3.wav'), 1, ATTN_NORM, 0);

    vectoangles(plane.normal, normal_angles);
    AngleVectors(normal_angles, Nil, @right, Nil);
    vectoangles (right, self.s.angles);

    if self.s.modelindex = sm_meat_index then
    begin
      inc(self.s.frame);
      self.think := gib_think;
      self.nextthink := level.time + FRAMETIME;
    end;
  end;
end;

procedure gib_die(self, inflictor, attacker: edict_p; damage: Integer; const point: vec3_t); cdecl;
begin
  G_FreeEdict(self);
end;

procedure ThrowGib(self: edict_p; gibname: PChar; damage, _type: Integer);
Var gib: edict_p; vd, origin, size: vec3_t; vscale: Single;
begin
  gib := G_Spawn();

  VectorScale(self.size, 0.5, size);
  VectorAdd(self.absmin, size, origin);
  gib.s.origin[0] := origin[0] + crandom() * size[0];
  gib.s.origin[1] := origin[1] + crandom() * size[1];
  gib.s.origin[2] := origin[2] + crandom() * size[2];

  gi.setmodel(gib, gibname);
  gib.solid := SOLID_NOT;
  gib.s.effects := gib.s.effects OR EF_GIB;
  gib.flags := gib.flags OR FL_NO_KNOCKBACK;
  gib.takedamage := DAMAGE_YES;
  gib.die := gib_die;

  if _type = GIB_ORGANIC then
  begin
    gib.movetype := MOVETYPE_TOSS;
    gib.touch := gib_touch;
    vscale := 0.5;
  end
  else
  begin
    gib.movetype := MOVETYPE_BOUNCE;
    vscale := 1.0;
  end;

  VelocityForDamage(damage, vd);
  VectorMA(self.velocity, vscale, vd, gib.velocity);
  ClipGibVelocity(gib);
  gib.avelocity[0] := _random()*600;
  gib.avelocity[1] := _random()*600;
  gib.avelocity[2] := _random()*600;

  gib.think := G_FreeEdict;
  gib.nextthink := level.time + 10 + _random()*10;

  gi.linkentity(gib);
end;

procedure ThrowHead(self: edict_p; gibname: PChar; damage, _type: integer);
Var vd: vec3_t; vscale: Single;
begin
  self.s.skinnum := 0;
  self.s.frame := 0;
  VectorClear(self.mins);
  VectorClear(self.maxs);

  self.s.modelindex2 := 0;
  gi.setmodel(self, gibname);
  self.solid := SOLID_NOT;
  self.s.effects := self.s.effects OR EF_GIB;
  self.s.effects := self.s.effects AND (NOT EF_FLIES);
  self.s.sound := 0;
  self.flags := self.flags OR FL_NO_KNOCKBACK;
  self.svflags := self.svflags AND (NOT SVF_MONSTER);
  self.takedamage := DAMAGE_YES;
  self.die := gib_die;

  if _type = GIB_ORGANIC then
  begin
    self.movetype := MOVETYPE_TOSS;
    self.touch := gib_touch;
    vscale := 0.5;
  end
  else
  begin
    self.movetype := MOVETYPE_BOUNCE;
    vscale := 1.0;
  end;

  VelocityForDamage(damage, vd);
  VectorMA(self.velocity, vscale, vd, self.velocity);
  ClipGibVelocity(self);

  self.avelocity[YAW] := crandom()*600;

  self.think := G_FreeEdict;
  self.nextthink := level.time + 10 + _random()*10;

  gi.linkentity (self);
end;


procedure ThrowClientHead(self: edict_p; damage: Integer);
var
  vd: vec3_t;
  gibname: PChar;
begin
  if (rand() AND 1) <> 0 then
  begin
    gibname := 'models/objects/gibs/head2/tris.md2';
    self^.s.skinnum := 1; // second skin is player
  end
  else
  begin
    gibname := 'models/objects/gibs/skull/tris.md2';
    self^.s.skinnum := 0;
  end;

  self^.s.origin[2] := self^.s.origin[2] + 32;
  self^.s.frame := 0;
  gi.setmodel(self, gibname);
  VectorSet(self^.mins, -16, -16, 0);
  VectorSet(self^.maxs, 16, 16, 16);

  self^.takedamage := DAMAGE_NO;
  self^.solid := SOLID_NOT;
  self^.s.effects := EF_GIB;
  self^.s.sound := 0;
  self^.flags := self^.flags OR FL_NO_KNOCKBACK;

  self^.movetype := MOVETYPE_BOUNCE;
  VelocityForDamage (damage, vd);
  VectorAdd (self^.velocity, vd, self^.velocity);

  if self^.client <> Nil then
  begin // bodies in the queue don't have a client anymore
    self^.client^.anim_priority := ANIM_DEATH;
    self^.client^.anim_end := self^.s.frame;
  end else
  begin
    self^.think := Nil;
    self^.nextthink := 0;
  end;

  gi.linkentity(self);
end;


(*
=================
debris
=================
*)
procedure debris_die(self, inflictor, attacker: edict_p; damage: integer; const point: vec3_t); cdecl;
begin
  G_FreeEdict(self);
end;

procedure ThrowDebris(self: edict_p; modelname: PChar; speed: Single; const origin: vec3_t);
Var chunk: edict_p; v: vec3_t;
begin
  chunk := G_Spawn();
  VectorCopy(origin, chunk.s.origin);
  gi.setmodel(chunk, modelname);
  v[0] := 100 * crandom();
  v[1] := 100 * crandom();
  v[2] := 100 + 100 * crandom();
  VectorMA(self.velocity, speed, v, chunk.velocity);
  chunk.movetype := MOVETYPE_BOUNCE;
  chunk.solid := SOLID_NOT;
  chunk.avelocity[0] := _random()*600;
  chunk.avelocity[1] := _random()*600;
  chunk.avelocity[2] := _random()*600;
  chunk.think := G_FreeEdict;
  chunk.nextthink := level.time + 5 + _random()*5;
  chunk.s.frame := 0;
  chunk.flags := 0;
  chunk.classname := 'debris';
  chunk.takedamage := DAMAGE_YES;
  chunk.die := debris_die;
  gi.linkentity(chunk);
end;


procedure BecomeExplosion1(self: edict_p);
begin
  gi.WriteByte(svc_temp_entity);
  gi.WriteByte(Ord(TE_EXPLOSION1));
  gi.WritePosition(self.s.origin);
  gi.multicast(@self.s.origin, MULTICAST_PVS);

  G_FreeEdict(self);
end;


procedure BecomeExplosion2(self: edict_p);
begin
  gi.WriteByte (svc_temp_entity);
  gi.WriteByte(Ord(TE_EXPLOSION2));
  gi.WritePosition (self.s.origin);
  gi.multicast (@self.s.origin, MULTICAST_PVS);

  G_FreeEdict (self);
end;


(*QUAKED path_corner (.5 .3 0) (-8 -8 -8) (8 8 8) TELEPORT
Target: next path corner
Pathtarget: gets used when an entity that has
  this path_corner targeted touches it
*)

procedure path_corner_touch(self, other: edict_p; plane: cplane_p; surf: csurface_p); cdecl;
Var v: vec3_t; next: edict_p; savetarget: PChar;
begin
  if other.movetarget <> self then
    exit;

  if other.enemy<>Nil then
    exit;

  if self.pathtarget<>Nil then
  begin
    savetarget := self.target;
    self.target := self.pathtarget;
    G_UseTargets(self, other);
    self.target := savetarget;
  end;

  if self.target<>Nil then
    next := G_PickTarget(self.target)
  else
    next := Nil;

  if (next<>Nil) and ((next.spawnflags AND 1)<>0) then
  begin
    VectorCopy (next.s.origin, v);
    v[2] := v[2] + next.mins[2];
    v[2] := v[2] - other.mins[2];
    VectorCopy(v, other.s.origin);
    next := G_PickTarget(next.target);
    other.s.event := EV_OTHER_TELEPORT;
  end;

  other.goalentity := next;
  other.movetarget := next;

  if self.wait<>0 then
  begin
    other.monsterinfo.pausetime := level.time + self.wait;
    other.monsterinfo.stand(other);
    exit;
  end;

  if other.movetarget=Nil then
  begin
    other.monsterinfo.pausetime := level.time + 100000000;
    other.monsterinfo.stand (other);
  end
  else
  begin
    VectorSubtract (other.goalentity.s.origin, other.s.origin, v);
    other.ideal_yaw := vectoyaw (v);
  end;
end;

procedure SP_path_corner(self: edict_p); {cdecl;}
begin
  if self.targetname=Nil then
  begin
    gi.dprintf('path_corner with no targetname at %s'#10, vtos(self.s.origin));
    G_FreeEdict (self);
    exit;
  end;

  self.solid := SOLID_TRIGGER;
  self.touch := path_corner_touch;
  VectorSet (self.mins, -8, -8, -8);
  VectorSet (self.maxs, 8, 8, 8);
  self.svflags := self.svflags OR SVF_NOCLIENT;
  gi.linkentity (self);
end;


(*QUAKED point_combat (0.5 0.3 0) (-8 -8 -8) (8 8 8) Hold
Makes this the target of a monster and it will head here
when first activated before going after the activator.  If
hold is selected, it will stay here.
*)
procedure point_combat_touch(self, other: edict_p; plane: cplane_p; surf: csurface_p); cdecl;
Var activator: edict_p; savetarget: PChar;
begin
  if other.movetarget <> self then
    exit;

  if self.target<>Nil then
  begin
    other.target := self.target;
    other.movetarget := G_PickTarget(other.target);
    other.goalentity := other.movetarget;
    if other.goalentity=Nil then
    begin
      gi.dprintf('%s at %s target %s does not exist'#10, self.classname, vtos(self.s.origin), self.target);
      other.movetarget := self;
    end;
    self.target := Nil;
  end
  else if ((self.spawnflags AND 1)<>0) and ((other.flags AND (FL_SWIM OR FL_FLY))=0) then
  begin
    other.monsterinfo.pausetime := level.time + 100000000;
    other.monsterinfo.aiflags := other.monsterinfo.aiflags OR AI_STAND_GROUND;
    other.monsterinfo.stand(other);
  end;

  if other.movetarget = self then
  begin
    other.target := Nil;
    other.movetarget := Nil;
    other.goalentity := other.enemy;
    other.monsterinfo.aiflags := other.monsterinfo.aiflags AND NOT AI_COMBAT_POINT;
  end;

  if self.pathtarget<>Nil then
  begin
    savetarget := self.target;
    self.target := self.pathtarget;
    if (other.enemy<>Nil) and (other.enemy.client<>Nil) then
      activator := other.enemy
    else if (other.oldenemy<>Nil) and (other.oldenemy.client<>Nil) then
      activator := other.oldenemy
    else if (other.activator<>Nil) and (other.activator.client<>Nil) then
      activator := other.activator
    else
      activator := other;
    G_UseTargets(self, activator);
    self.target := savetarget;
  end;
end;

procedure SP_point_combat(self: edict_p); {cdecl;}
begin
  if deathmatch.value<>0 then
  begin
    G_FreeEdict(self);
    exit;
  end;
  self.solid := SOLID_TRIGGER;
  self.touch := point_combat_touch;
  VectorSet(self.mins, -8, -8, -16);
  VectorSet(self.maxs, 8, 8, 16);
  self.svflags := SVF_NOCLIENT;
  gi.linkentity(self);
end;


(*QUAKED viewthing (0 .5 .8) (-8 -8 -8) (8 8 8)
Just for the debugging level.  Don't use
*)
procedure TH_viewthing(ent: edict_p); cdecl;
begin
  ent.s.frame := (ent.s.frame + 1) mod 7;
  ent.nextthink := level.time + FRAMETIME;
end;

procedure SP_viewthing(ent: edict_p); {cdecl;}
begin
  gi.dprintf ('viewthing spawned'#10);

  ent.movetype := MOVETYPE_NONE;
  ent.solid := SOLID_BBOX;
  ent.s.renderfx := RF_FRAMELERP;
  VectorSet (ent.mins, -16, -16, -24);
  VectorSet (ent.maxs, 16, 16, 32);
  ent.s.modelindex := gi.modelindex('models/objects/banner/tris.md2');
  gi.linkentity(ent);
  ent.nextthink := level.time + 0.5;
  ent.think := TH_viewthing;
//  exit;  CAK - what's the point of this???
end;


(*QUAKED info_null (0 0.5 0) (-4 -4 -4) (4 4 4)
Used as a positional target for spotlights, etc.
*)
procedure SP_info_null(self: edict_p); {cdecl;}
begin
  G_FreeEdict(self);
end;


(*QUAKED info_notnull (0 0.5 0) (-4 -4 -4) (4 4 4)
Used as a positional target for lightning.
*)
procedure SP_info_notnull(self: edict_p); {cdecl;}
begin
  VectorCopy(self.s.origin, self.absmin);
  VectorCopy(self.s.origin, self.absmax);
end;


(*QUAKED light (0 1 0) (-8 -8 -8) (8 8 8) START_OFF
Non-displayed light.
Default light value is 300.
Default style is 0.
If targeted, will toggle between on and off.
Default _cone value is 10 (used to set size of light for spotlights)
*)

const
  START_OFF = 1;

// CAK - static, so not in interface!!!
procedure light_use(self, other, activator: edict_p); cdecl;
begin
  if (self.spawnflags AND START_OFF)<>0 then
  begin
    gi.configstring(CS_LIGHTS+self.style, 'm');
    self.spawnflags := self.spawnflags AND NOT START_OFF;
  end
  else
  begin
    gi.configstring(CS_LIGHTS+self.style, 'a');
    self.spawnflags := self.spawnflags OR START_OFF;
  end;
end;

procedure SP_light(self: edict_p); {cdecl;}
begin
  // no targeted lights in deathmatch, because they cause global messages
  if (self.targetname=Nil) or (deathmatch.value<>0) then
  begin
    G_FreeEdict(self);
    exit;
  end;

  if self.style >= 32 then
  begin
    self.use := light_use;
    if (self.spawnflags AND START_OFF)<>0 then
      gi.configstring (CS_LIGHTS+self.style, 'a')
    else
      gi.configstring (CS_LIGHTS+self.style, 'm');
  end;
end;


(*QUAKED func_wall (0 .5 .8) ? TRIGGER_SPAWN TOGGLE START_ON ANIMATED ANIMATED_FAST
This is just a solid wall if not inhibited

TRIGGER_SPAWN  the wall will not be present until triggered
        it will then blink in to existance; it will
        kill anything that was in it's way

TOGGLE      only valid for TRIGGER_SPAWN walls
        this allows the wall to be turned on and off

START_ON    only valid for TRIGGER_SPAWN walls
        the wall will initially be present
*)

procedure func_wall_use(self, other, activator: edict_p); cdecl;
begin
  if self.solid = SOLID_NOT then
  begin
    self.solid := SOLID_BSP;
    self.svflags := self.svflags AND NOT SVF_NOCLIENT;
    KillBox (self);
  end
  else
  begin
    self.solid := SOLID_NOT;
    self.svflags := self.svflags OR SVF_NOCLIENT;
  end;
  gi.linkentity (self);

  if (self.spawnflags AND 2)=0 then
    self.use := Nil;
end;

procedure SP_func_wall(self: edict_p); {cdecl;}
begin
  self.movetype := MOVETYPE_PUSH;
  gi.setmodel(self, self.model);

  if (self.spawnflags AND 8)<>0 then
    self.s.effects := self.s.effects OR EF_ANIM_ALL;
  if (self.spawnflags AND 16)<>0 then
    self.s.effects := self.s.effects OR EF_ANIM_ALLFAST;

  // just a wall
  if (self.spawnflags AND 7) = 0 then
  begin
    self.solid := SOLID_BSP;
    gi.linkentity (self);
    exit;
  end;

  // it must be TRIGGER_SPAWN
  if (self.spawnflags AND 1)=0 then
  begin
//    gi.dprintf('func_wall missing TRIGGER_SPAWN'#10);
    self.spawnflags := self.spawnflags OR 1;
  end;

  // yell if the spawnflags are odd
  if (self.spawnflags AND 4)<>0 then
  begin
    if (self.spawnflags AND 2)=0 then
    begin
      gi.dprintf('func_wall START_ON without TOGGLE'#10);
      self.spawnflags := self.spawnflags OR 2;
    end;
  end;

  self.use := func_wall_use;
  if (self.spawnflags AND 4)>0 then
  begin
    self.solid := SOLID_BSP;
  end
  else
  begin
    self.solid := SOLID_NOT;
    self.svflags := self.svflags OR SVF_NOCLIENT;
  end;
  gi.linkentity(self);
end;


(*QUAKED func_object (0 .5 .8) ? TRIGGER_SPAWN ANIMATED ANIMATED_FAST
This is solid bmodel that will fall if it's support it removed.
*)

procedure func_object_touch(self, other: edict_p; plane: cplane_p; surf: csurface_p); cdecl;
begin
  // only squash thing we fall on top of
  if plane=Nil then
    exit;
  if plane.normal[2] < 1.0 then
    exit;
  if other.takedamage = DAMAGE_NO then
    exit;
  T_Damage(other, self, self, vec3_origin, self.s.origin, vec3_origin, self.dmg, 1, 0, MOD_CRUSH);
end;

procedure func_object_release(self: edict_p); cdecl;
begin
  self.movetype := MOVETYPE_TOSS;
  self.touch := func_object_touch;
end;

procedure func_object_use(self, other, activator: edict_p); cdecl;
begin
  self.solid := SOLID_BSP;
  self.svflags := self.svflags AND NOT SVF_NOCLIENT;
  self.use := Nil;
  KillBox(self);
  func_object_release(self);
end;

procedure SP_func_object(self: edict_p); {cdecl;}
begin
  gi.setmodel (self, self.model);

  self.mins[0] := self.mins[0] + 1;
  self.mins[1] := self.mins[1] + 1;
  self.mins[2] := self.mins[2] + 1;
  self.maxs[0] := self.maxs[0] - 1;
  self.maxs[1] := self.maxs[1] - 1;
  self.maxs[2] := self.maxs[2] - 1;

  if self.dmg=0 then
    self.dmg := 100;

  if self.spawnflags = 0 then
  begin
    self.solid := SOLID_BSP;
    self.movetype := MOVETYPE_PUSH;
    self.think := func_object_release;
    self.nextthink := level.time + 2 * FRAMETIME;
  end
  else
  begin
    self.solid := SOLID_NOT;
    self.movetype := MOVETYPE_PUSH;
    self.use := func_object_use;
    self.svflags := self.svflags OR SVF_NOCLIENT;
  end;

  if (self.spawnflags AND 2)<>0 then
    self.s.effects := self.s.effects OR EF_ANIM_ALL;
  if (self.spawnflags AND 4)<>0 then
    self.s.effects := self.s.effects OR EF_ANIM_ALLFAST;

  self.clipmask := MASK_MONSTERSOLID;

  gi.linkentity(self);
end;


(*QUAKED func_explosive (0 .5 .8) ? Trigger_Spawn ANIMATED ANIMATED_FAST
Any brush that you want to explode or break apart.  If you want an
ex0plosion, set dmg and it will do a radius explosion of that amount
at the center of the bursh.

If targeted it will not be shootable.

health defaults to 100.

mass defaults to 75.  This determines how much debris is emitted when
it explodes.  You get one large chunk per 100 of mass (up to 8) and
one small chunk per 25 of mass (up to 16).  So 800 gives the most.
*)
procedure func_explosive_explode(self, inflictor, attacker: edict_p; damage: Integer; const point: vec3_t); cdecl;
Var origin, chunkorigin, size: vec3_t; count, mass: Integer;
begin
  // bmodel origins are (0 0 0), we need to adjust that here
  VectorScale(self.size, 0.5, size);
  VectorAdd(self.absmin, size, origin);
  VectorCopy(origin, self.s.origin);

  self.takedamage := DAMAGE_NO;

  if self.dmg<>0 then
    T_RadiusDamage(self, attacker, self.dmg, Nil, self.dmg+40, MOD_EXPLOSIVE);

  VectorSubtract(self.s.origin, inflictor.s.origin, self.velocity);
  VectorNormalize(self.velocity);
  VectorScale(self.velocity, 150, self.velocity);

  // start chunks towards the center
  VectorScale (size, 0.5, size);

  mass := self.mass;
  if mass=0 then
    mass := 75;

  // big chunks
  if mass >= 100 then
  begin
    count := mass div 100;
    if count > 8 then
      count := 8;
    while count<>0 do
    begin
      dec(count);
      chunkorigin[0] := origin[0] + crandom() * size[0];
      chunkorigin[1] := origin[1] + crandom() * size[1];
      chunkorigin[2] := origin[2] + crandom() * size[2];
      ThrowDebris(self, 'models/objects/debris1/tris.md2', 1, chunkorigin);
    end;
  end;

  // small chunks
  count := mass div 25;
  if count > 16 then
    count := 16;
  while count<>0 do
  begin
    dec(count);
    chunkorigin[0] := origin[0] + crandom() * size[0];
    chunkorigin[1] := origin[1] + crandom() * size[1];
    chunkorigin[2] := origin[2] + crandom() * size[2];
    ThrowDebris (self, 'models/objects/debris2/tris.md2', 2, chunkorigin);
  end;

  G_UseTargets(self, attacker);

  if self.dmg<>0 then
    BecomeExplosion1(self)
  else
    G_FreeEdict(self);
end;

procedure func_explosive_use(self, other, activator: edict_p); cdecl;
begin
  func_explosive_explode (self, self, other, self.health, vec3_origin);
end;

procedure func_explosive_spawn(self, other, activator: edict_p); cdecl;
begin
  self.solid := SOLID_BSP;
  self.svflags := self.svflags AND NOT SVF_NOCLIENT;
  self.use := Nil;
  KillBox(self);
  gi.linkentity(self);
end;

procedure SP_func_explosive(self: edict_p); {cdecl;}
begin
  if deathmatch.value<>0 then
  begin  // auto-remove for deathmatch
    G_FreeEdict(self);
    exit;
  end;

  self.movetype := MOVETYPE_PUSH;

  gi.modelindex ('models/objects/debris1/tris.md2');
  gi.modelindex ('models/objects/debris2/tris.md2');

  gi.setmodel(self, self.model);

  if (self.spawnflags AND 1)<>0 then
  begin
    self.svflags := self.svflags OR SVF_NOCLIENT;
    self.solid := SOLID_NOT;
    self.use := func_explosive_spawn;
  end
  else
  begin
    self.solid := SOLID_BSP;
    if self.targetname<>Nil then
      self.use := func_explosive_use;
  end;

  if (self.spawnflags AND 2)<>0 then
    self.s.effects := self.s.effects OR EF_ANIM_ALL;
  if (self.spawnflags AND 4)<>0 then
    self.s.effects := self.s.effects OR EF_ANIM_ALLFAST;

  if @self.use <> @func_explosive_use then
  begin
    if self.health=0 then
      self.health := 100;
    self.die := func_explosive_explode;
    self.takedamage := DAMAGE_YES;
  end;

  gi.linkentity(self);
end;


(*QUAKED misc_explobox (0 .5 .8) (-16 -16 0) (16 16 40)
Large exploding box.  You can override its mass (100),
health (80), and dmg (150).
*)

procedure barrel_touch(self, other: edict_p; plane: cplane_p; surf: csurface_p); cdecl;
Var ratio: Single; v: vec3_t;
begin
  if (other.groundentity=Nil) or (other.groundentity = self) then
    exit;

  ratio := other.mass / self.mass;
  VectorSubtract(self.s.origin, other.s.origin, v);
  M_walkmove(self, vectoyaw(v), 20 * ratio * FRAMETIME);
end;

procedure barrel_explode(self: edict_p); cdecl;
Var org: vec3_t; spd: Single; save: vec3_t;
begin
  T_RadiusDamage (self, self.activator, self.dmg, Nil, self.dmg+40, MOD_BARREL);

  VectorCopy(self.s.origin, save);
  VectorMA(self.absmin, 0.5, self.size, self.s.origin);

  // a few big chunks
  spd := 1.5 * self.dmg / 200;
  org[0] := self.s.origin[0] + crandom() * self.size[0];
  org[1] := self.s.origin[1] + crandom() * self.size[1];
  org[2] := self.s.origin[2] + crandom() * self.size[2];
  ThrowDebris(self, 'models/objects/debris1/tris.md2', spd, org);
  org[0] := self.s.origin[0] + crandom() * self.size[0];
  org[1] := self.s.origin[1] + crandom() * self.size[1];
  org[2] := self.s.origin[2] + crandom() * self.size[2];
  ThrowDebris(self, 'models/objects/debris1/tris.md2', spd, org);

  // bottom corners
  spd := 1.75 * self.dmg / 200;
  VectorCopy(self.absmin, org);
  ThrowDebris(self, 'models/objects/debris3/tris.md2', spd, org);
  VectorCopy(self.absmin, org);
  org[0] := org[0] + self.size[0];
  ThrowDebris(self, 'models/objects/debris3/tris.md2', spd, org);
  VectorCopy(self.absmin, org);
  org[1] := org[1] + self.size[1];
  ThrowDebris(self, 'models/objects/debris3/tris.md2', spd, org);
  VectorCopy(self.absmin, org);
  org[0] := org[0] + self.size[0];
  org[1] := org[1] + self.size[1];
  ThrowDebris(self, 'models/objects/debris3/tris.md2', spd, org);

  // a bunch of little chunks
  spd := 2 * self.dmg / 200;
  org[0] := self.s.origin[0] + crandom() * self.size[0];
  org[1] := self.s.origin[1] + crandom() * self.size[1];
  org[2] := self.s.origin[2] + crandom() * self.size[2];
  ThrowDebris(self, 'models/objects/debris2/tris.md2', spd, org);
  org[0] := self.s.origin[0] + crandom() * self.size[0];
  org[1] := self.s.origin[1] + crandom() * self.size[1];
  org[2] := self.s.origin[2] + crandom() * self.size[2];
  ThrowDebris(self, 'models/objects/debris2/tris.md2', spd, org);
  org[0] := self.s.origin[0] + crandom() * self.size[0];
  org[1] := self.s.origin[1] + crandom() * self.size[1];
  org[2] := self.s.origin[2] + crandom() * self.size[2];
  ThrowDebris(self, 'models/objects/debris2/tris.md2', spd, org);
  org[0] := self.s.origin[0] + crandom() * self.size[0];
  org[1] := self.s.origin[1] + crandom() * self.size[1];
  org[2] := self.s.origin[2] + crandom() * self.size[2];
  ThrowDebris(self, 'models/objects/debris2/tris.md2', spd, org);
  org[0] := self.s.origin[0] + crandom() * self.size[0];
  org[1] := self.s.origin[1] + crandom() * self.size[1];
  org[2] := self.s.origin[2] + crandom() * self.size[2];
  ThrowDebris(self, 'models/objects/debris2/tris.md2', spd, org);
  org[0] := self.s.origin[0] + crandom() * self.size[0];
  org[1] := self.s.origin[1] + crandom() * self.size[1];
  org[2] := self.s.origin[2] + crandom() * self.size[2];
  ThrowDebris(self, 'models/objects/debris2/tris.md2', spd, org);
  org[0] := self.s.origin[0] + crandom() * self.size[0];
  org[1] := self.s.origin[1] + crandom() * self.size[1];
  org[2] := self.s.origin[2] + crandom() * self.size[2];
  ThrowDebris(self, 'models/objects/debris2/tris.md2', spd, org);
  org[0] := self.s.origin[0] + crandom() * self.size[0];
  org[1] := self.s.origin[1] + crandom() * self.size[1];
  org[2] := self.s.origin[2] + crandom() * self.size[2];
  ThrowDebris(self, 'models/objects/debris2/tris.md2', spd, org);

  VectorCopy(save, self.s.origin);
  if self.groundentity<>Nil then
    BecomeExplosion2(self)
  else
    BecomeExplosion1(self);
end;

procedure barrel_delay(self, inflictor, attacker: edict_p; damage: Integer; const point: vec3_t); cdecl;
begin
  self.takedamage := DAMAGE_NO;
  self.nextthink := level.time + 2 * FRAMETIME;
  self.think := barrel_explode;
  self.activator := attacker;
end;

procedure SP_misc_explobox(self: edict_p); {cdecl;}
begin
  if deathmatch.value<>0 then
  begin  // auto-remove for deathmatch
    G_FreeEdict(self);
    exit;
  end;

  gi.modelindex('models/objects/debris1/tris.md2');
  gi.modelindex('models/objects/debris2/tris.md2');
  gi.modelindex('models/objects/debris3/tris.md2');

  self.solid := SOLID_BBOX;
  self.movetype := MOVETYPE_STEP;

  self.model := 'models/objects/barrels/tris.md2';
  self.s.modelindex := gi.modelindex(self.model);
  VectorSet(self.mins, -16, -16, 0);
  VectorSet(self.maxs, 16, 16, 40);

  if self.mass = 0 then
    self.mass := 400;
  if self.health = 0 then
    self.health := 10;
  if self.dmg = 0 then
    self.dmg := 150;

  self.die := barrel_delay;
  self.takedamage := DAMAGE_YES;
  self.monsterinfo.aiflags := AI_NOSTEP;

  self.touch := barrel_touch;

  self.think := M_droptofloor;
  self.nextthink := level.time + 2 * FRAMETIME;

  gi.linkentity(self);
end;


//
// miscellaneous specialty items
//

(*QUAKED misc_blackhole (1 .5 0) (-8 -8 -8) (8 8 8)
*)

procedure misc_blackhole_use(ent, other, activator: edict_p); cdecl;
begin
  (*
  gi.WriteByte(svc_temp_entity);
  gi.WriteByte(TE_BOSSTPORT);
  gi.WritePosition(ent.s.origin);
  gi.multicast(ent.s.origin, MULTICAST_PVS);
  *)
  G_FreeEdict(ent);
end;

procedure misc_blackhole_think(self: edict_p); cdecl;
begin
  Inc(self.s.frame);
  if self.s.frame < 19 then
    self.nextthink := level.time + FRAMETIME

  else
  begin
    self.s.frame := 0;
    self.nextthink := level.time + FRAMETIME;
  end;
end;

procedure SP_misc_blackhole(ent: edict_p); {cdecl;}
begin
  ent.movetype := MOVETYPE_NONE;
  ent.solid := SOLID_NOT;
  VectorSet (ent.mins, -64, -64, 0);
  VectorSet (ent.maxs, 64, 64, 8);
  ent.s.modelindex := gi.modelindex('models/objects/black/tris.md2');
  ent.s.renderfx := RF_TRANSLUCENT;
  ent.use := misc_blackhole_use;
  ent.think := misc_blackhole_think;
  ent.nextthink := level.time + 2 * FRAMETIME;
  gi.linkentity(ent);
end;

(*QUAKED misc_eastertank (1 .5 0) (-32 -32 -16) (32 32 32)
*)

procedure misc_eastertank_think(self: edict_p); cdecl;
begin
  Inc (self.s.frame);
  if self.s.frame < 293 then
    self.nextthink := level.time + FRAMETIME

  else
  begin
    self.s.frame := 254;
    self.nextthink := level.time + FRAMETIME;
  end;
end;

procedure SP_misc_eastertank(ent: edict_p); {cdecl;}
begin
  ent.movetype := MOVETYPE_NONE;
  ent.solid := SOLID_BBOX;
  VectorSet (ent.mins, -32, -32, -16);
  VectorSet (ent.maxs, 32, 32, 32);
  ent.s.modelindex := gi.modelindex ('models/monsters/tank/tris.md2');
  ent.s.frame := 254;
  ent.think := misc_eastertank_think;
  ent.nextthink := level.time + 2 * FRAMETIME;
  gi.linkentity (ent);
end;

(*QUAKED misc_easterchick (1 .5 0) (-32 -32 0) (32 32 32)
*)


procedure misc_easterchick_think(self: edict_p); cdecl;
begin
  Inc(self.s.frame);
  if self.s.frame < 247 then
    self.nextthink := level.time + FRAMETIME

  else
  begin
    self.s.frame := 208;
    self.nextthink := level.time + FRAMETIME;
  end;
end;

procedure SP_misc_easterchick(ent: edict_p); {cdecl;}
begin
  ent.movetype := MOVETYPE_NONE;
  ent.solid := SOLID_BBOX;
  VectorSet (ent.mins, -32, -32, 0);
  VectorSet (ent.maxs, 32, 32, 32);
  ent.s.modelindex := gi.modelindex ('models/monsters/bitch/tris.md2');
  ent.s.frame := 208;
  ent.think := misc_easterchick_think;
  ent.nextthink := level.time + 2 * FRAMETIME;
  gi.linkentity(ent);
end;

(*QUAKED misc_easterchick2 (1 .5 0) (-32 -32 0) (32 32 32)
*)


procedure misc_easterchick2_think (self: edict_p); cdecl;
begin
  Inc(self.s.frame);
  if self.s.frame < 287 then
    self.nextthink := level.time + FRAMETIME

  else
  begin
    self.s.frame := 248;
    self.nextthink := level.time + FRAMETIME;
  end;
end;

procedure SP_misc_easterchick2(ent: edict_p); {cdecl;}
begin
  ent.movetype := MOVETYPE_NONE;
  ent.solid := SOLID_BBOX;
  VectorSet (ent.mins, -32, -32, 0);
  VectorSet (ent.maxs, 32, 32, 32);
  ent.s.modelindex := gi.modelindex ('models/monsters/bitch/tris.md2');
  ent.s.frame := 248;
  ent.think := misc_easterchick2_think;
  ent.nextthink := level.time + 2 * FRAMETIME;
  gi.linkentity(ent);
end;


(*QUAKED monster_commander_body (1 .5 0) (-32 -32 0) (32 32 48)
Not really a monster, this is the Tank Commander's decapitated body.
There should be a item_commander_head that has this as it's target.
*)

procedure commander_body_think(self: edict_p); cdecl;
begin
  Inc (self.s.frame);
  if self.s.frame < 24 then
    self.nextthink := level.time + FRAMETIME
  else
    self.nextthink := 0;

  if self.s.frame = 22 then
    gi.sound(self, CHAN_BODY, gi.soundindex('tank/thud.wav'), 1, ATTN_NORM, 0);
end;

procedure commander_body_use(self, other, activator: edict_p); cdecl;
begin
  self.think := commander_body_think;
  self.nextthink := level.time + FRAMETIME;
  gi.sound (self, CHAN_BODY, gi.soundindex ('tank/pain.wav'), 1, ATTN_NORM, 0);
end;

procedure commander_body_drop(self: edict_p); cdecl;
begin
  self.movetype := MOVETYPE_TOSS;
  self.s.origin[2] := self.s.origin[2] + 2;
end;

procedure SP_monster_commander_body(self: edict_p); {cdecl;}
begin
  self.movetype := MOVETYPE_NONE;
  self.solid := SOLID_BBOX;
  self.model := 'models/monsters/commandr/tris.md2';
  self.s.modelindex := gi.modelindex (self.model);
  VectorSet (self.mins, -32, -32, 0);
  VectorSet (self.maxs, 32, 32, 48);
  self.use := commander_body_use;
  self.takedamage := DAMAGE_YES;
  self.flags := FL_GODMODE;
  self.s.renderfx := self.s.renderfx OR RF_FRAMELERP;
  gi.linkentity (self);

  gi.soundindex ('tank/thud.wav');
  gi.soundindex ('tank/pain.wav');

  self.think := commander_body_drop;
  self.nextthink := level.time + 5 * FRAMETIME;
end;


(*QUAKED misc_banner (1 .5 0) (-4 -4 -4) (4 4 4)
The origin is the bottom of the banner.
The banner is 128 tall.
*)
procedure misc_banner_think(ent: edict_p); cdecl;
begin
  ent.s.frame := (ent.s.frame + 1) mod 16;
  ent.nextthink := level.time + FRAMETIME;
end;

procedure SP_misc_banner(ent: edict_p); {cdecl;}
begin
  ent^.movetype := MOVETYPE_NONE;
  ent^.solid := SOLID_NOT;
  ent^.s.modelindex := gi.modelindex ('models/objects/banner/tris.md2');
  ent^.s.frame := rand() mod 16;
  gi.linkentity (ent);

  ent^.think := misc_banner_think;
  ent^.nextthink := level.time + FRAMETIME;
end;

(*QUAKED misc_deadsoldier (1 .5 0) (-16 -16 0) (16 16 16) ON_BACK ON_STOMACH BACK_DECAP FETAL_POS SIT_DECAP IMPALED
This is the dead player model. Comes in 6 exciting different poses!
*)
procedure misc_deadsoldier_die(self, inflictor, attacker: edict_p; damage: Integer; const point: vec3_t); cdecl;
Var n: Integer;
begin
  if self.health > -80 then
    exit;

  gi.sound (self, CHAN_BODY, gi.soundindex ('misc/udeath.wav'), 1, ATTN_NORM, 0);
  for n:=0 to 3 do
    ThrowGib(self, 'models/objects/gibs/sm_meat/tris.md2', damage, GIB_ORGANIC);
  ThrowHead(self, 'models/objects/gibs/head2/tris.md2', damage, GIB_ORGANIC);
end;

procedure SP_misc_deadsoldier(ent: edict_p); {cdecl;}
begin
  if deathmatch.value <> 0 then
  begin  // auto-remove for deathmatch
    G_FreeEdict (ent);
    exit;
  end;

  ent.movetype := MOVETYPE_NONE;
  ent.solid := SOLID_BBOX;
  ent.s.modelindex:=gi.modelindex('models/deadbods/dude/tris.md2');

  // Defaults to frame 0
  if (ent.spawnflags AND 2)<>0 then
    ent.s.frame := 1
  else if (ent.spawnflags AND 4)<>0 then
    ent.s.frame := 2
  else if (ent.spawnflags AND 8)<>0 then
    ent.s.frame := 3
  else if (ent.spawnflags AND 16)<>0 then
    ent.s.frame := 4
  else if (ent.spawnflags AND 32)<>0 then
    ent.s.frame := 5
  else
    ent.s.frame := 0;

  VectorSet(ent.mins, -16, -16, 0);
  VectorSet(ent.maxs, 16, 16, 16);
  ent.deadflag := DEAD_DEAD;
  ent.takedamage := DAMAGE_YES;
  ent.svflags := ent.svflags OR SVF_MONSTER OR SVF_DEADMONSTER;
  ent.die := misc_deadsoldier_die;
  ent.monsterinfo.aiflags := ent.monsterinfo.aiflags OR AI_GOOD_GUY;

  gi.linkentity (ent);
end;

(*QUAKED misc_viper (1 .5 0) (-16 -16 0) (16 16 32)
This is the Viper for the flyby bombing.
It is trigger_spawned, so you must have something use it for it to show up.
There must be a path for it to follow once it is activated.

'speed'    How fast the Viper should fly
*)

procedure misc_viper_use(self, other, activator: edict_p); cdecl;
begin
  self.svflags := self.svflags AND NOT SVF_NOCLIENT;
  self.use := train_use;
  train_use (self, other, activator);
end;

procedure SP_misc_viper (ent: edict_p); {cdecl;}
begin
  if ent.target=Nil then
  begin
    gi.dprintf('misc_viper without a target at %s'#10, vtos(ent.absmin));
    G_FreeEdict(ent);
    exit;
  end;

  if ent.speed = 0 then
    ent.speed := 300;

  ent.movetype := MOVETYPE_PUSH;
  ent.solid := SOLID_NOT;
  ent.s.modelindex := gi.modelindex('models/ships/viper/tris.md2');
  VectorSet(ent.mins, -16, -16, 0);
  VectorSet(ent.maxs, 16, 16, 32);

  ent.think := func_train_find;
  ent.nextthink := level.time + FRAMETIME;
  ent.use := misc_viper_use;
  ent.svflags := ent.svflags OR SVF_NOCLIENT;
  ent.moveinfo.accel := ent.speed;
  ent.moveinfo.decel := ent.speed;
  ent.moveinfo.speed := ent.speed;

  gi.linkentity(ent);
end;


(*QUAKED misc_bigviper (1 .5 0) (-176 -120 -24) (176 120 72)
This is a large stationary viper as seen in Paul's intro
*)
procedure SP_misc_bigviper(ent: edict_p); {cdecl;}
begin
  ent.movetype := MOVETYPE_NONE;
  ent.solid := SOLID_BBOX;
  VectorSet(ent.mins, -176, -120, -24);
  VectorSet(ent.maxs, 176, 120, 72);
  ent.s.modelindex := gi.modelindex('models/ships/bigviper/tris.md2');
  gi.linkentity(ent);
end;


(*QUAKED misc_viper_bomb (1 0 0) (-8 -8 -8) (8 8 8)
'dmg'  how much boom should the bomb make?
*)
procedure misc_viper_bomb_touch(self, other: edict_p; plane: cplane_p; surf: csurface_p); cdecl;
begin
  G_UseTargets (self, self.activator);

  self.s.origin[2] := self.absmin[2] + 1;
  T_RadiusDamage(self, self, self.dmg, Nil, self.dmg+40, MOD_BOMB);
  BecomeExplosion2(self);
end;

procedure misc_viper_bomb_prethink(self: edict_p); cdecl;
Var v: vec3_t; diff: Single;
begin
  self.groundentity := Nil;

  diff := self.timestamp - level.time;
  if diff < -1.0 then
    diff := -1.0;

  VectorScale(self.moveinfo.dir, 1.0 + diff, v);
  v[2] := diff;

  diff := self.s.angles[2];
  vectoangles(v, self.s.angles);
  self.s.angles[2] := diff + 10;
end;

procedure misc_viper_bomb_use(self, other, activator: edict_p); cdecl;
Var viper: edict_p;
begin
  self.solid := SOLID_BBOX;
  self.svflags := self.svflags AND NOT SVF_NOCLIENT;
  self.s.effects := self.s.effects OR EF_ROCKET;
  self.use := Nil;
  self.movetype := MOVETYPE_TOSS;
  self.prethink := misc_viper_bomb_prethink;
  self.touch := misc_viper_bomb_touch;
  self.activator := activator;

  viper := G_Find(Nil, FOFS_classname, 'misc_viper');
  VectorScale (viper.moveinfo.dir, viper.moveinfo.speed, self.velocity);

  self.timestamp := level.time;
  VectorCopy (viper.moveinfo.dir, self.moveinfo.dir);
end;

procedure SP_misc_viper_bomb(self: edict_p); {cdecl;}
begin
  self.movetype := MOVETYPE_NONE;
  self.solid := SOLID_NOT;
  VectorSet(self.mins, -8, -8, -8);
  VectorSet(self.maxs, 8, 8, 8);

  self.s.modelindex := gi.modelindex ('models/objects/bomb/tris.md2');

  if self.dmg = 0 then
    self.dmg := 1000;

  self.use := misc_viper_bomb_use;
  self.svflags := self.svflags OR SVF_NOCLIENT;

  gi.linkentity(self);
end;


(*QUAKED misc_strogg_ship (1 .5 0) (-16 -16 0) (16 16 32)
This is a Storgg ship for the flybys.
It is trigger_spawned, so you must have something use it for it to show up.
There must be a path for it to follow once it is activated.

'speed'    How fast it should fly
*)

procedure misc_strogg_ship_use (self, other, activator: edict_p); cdecl;
begin
  self.svflags := self.svflags AND NOT SVF_NOCLIENT;
  self.use := train_use;
  train_use(self, other, activator);
end;

procedure SP_misc_strogg_ship(ent: edict_p); {cdecl;}
begin
  if ent.target=Nil then
  begin
    gi.dprintf('%s without a target at %s'#10, ent.classname, vtos(ent.absmin));
    G_FreeEdict(ent);
    exit;
  end;

  if ent.speed = 0 then
    ent.speed := 300;

  ent.movetype := MOVETYPE_PUSH;
  ent.solid := SOLID_NOT;
  ent.s.modelindex := gi.modelindex('models/ships/strogg1/tris.md2');
  VectorSet(ent.mins, -16, -16, 0);
  VectorSet(ent.maxs, 16, 16, 32);

  ent.think := func_train_find;
  ent.nextthink := level.time + FRAMETIME;
  ent.use := misc_strogg_ship_use;
  ent.svflags := ent.svflags OR SVF_NOCLIENT;
  ent.moveinfo.accel := ent.speed;
  ent.moveinfo.decel := ent.speed;
  ent.moveinfo.speed := ent.speed;

  gi.linkentity(ent);
end;


(*QUAKED misc_satellite_dish (1 .5 0) (-64 -64 0) (64 64 128)
*)
procedure misc_satellite_dish_think(self: edict_p); cdecl;
begin
  Inc(self.s.frame);
  if self.s.frame < 38 then
    self.nextthink := level.time + FRAMETIME;
end;

procedure misc_satellite_dish_use(self, other, activator: edict_p); cdecl;
begin
  self.s.frame := 0;
  self.think := misc_satellite_dish_think;
  self.nextthink := level.time + FRAMETIME;
end;

procedure SP_misc_satellite_dish(ent: edict_p); {cdecl;}
begin
  ent.movetype := MOVETYPE_NONE;
  ent.solid := SOLID_BBOX;
  VectorSet(ent.mins, -64, -64, 0);
  VectorSet(ent.maxs, 64, 64, 128);
  ent.s.modelindex := gi.modelindex('models/objects/satellite/tris.md2');
  ent.use := misc_satellite_dish_use;
  gi.linkentity(ent);
end;


(*QUAKED light_mine1 (0 1 0) (-2 -2 -12) (2 2 12)
*)
procedure SP_light_mine1(ent: edict_p); {cdecl;}
begin
  ent.movetype := MOVETYPE_NONE;
  ent.solid := SOLID_BBOX;
  ent.s.modelindex := gi.modelindex('models/objects/minelite/light1/tris.md2');
  gi.linkentity(ent);
end;


(*QUAKED light_mine2 (0 1 0) (-2 -2 -12) (2 2 12)
*)
procedure SP_light_mine2(ent: edict_p); {cdecl;}
begin
  ent.movetype := MOVETYPE_NONE;
  ent.solid := SOLID_BBOX;
  ent.s.modelindex := gi.modelindex('models/objects/minelite/light2/tris.md2');
  gi.linkentity(ent);
end;


(*QUAKED misc_gib_arm (1 0 0) (-8 -8 -8) (8 8 8)
Intended for use with the target_spawner
*)
procedure SP_misc_gib_arm(ent: edict_p); {cdecl;}
begin
  gi.setmodel(ent, 'models/objects/gibs/arm/tris.md2');
  ent.solid := SOLID_NOT;
  ent.s.effects := ent.s.effects OR EF_GIB;
  ent.takedamage := DAMAGE_YES;
  ent.die := gib_die;
  ent.movetype := MOVETYPE_TOSS;
  ent.svflags := ent.svflags OR SVF_MONSTER;
  ent.deadflag := DEAD_DEAD;
  ent.avelocity[0] := _random()*200;
  ent.avelocity[1] := _random()*200;
  ent.avelocity[2] := _random()*200;
  ent.think := G_FreeEdict;
  ent.nextthink := level.time + 30;
  gi.linkentity (ent);
end;

(*QUAKED misc_gib_leg (1 0 0) (-8 -8 -8) (8 8 8)
Intended for use with the target_spawner
*)
procedure SP_misc_gib_leg(ent: edict_p); {cdecl;}
begin
  gi.setmodel (ent, 'models/objects/gibs/leg/tris.md2');
  ent.solid := SOLID_NOT;
  ent.s.effects := ent.s.effects OR EF_GIB;
  ent.takedamage := DAMAGE_YES;
  ent.die := gib_die;
  ent.movetype := MOVETYPE_TOSS;
  ent.svflags := ent.svflags OR SVF_MONSTER;
  ent.deadflag := DEAD_DEAD;
  ent.avelocity[0] := _random()*200;
  ent.avelocity[1] := _random()*200;
  ent.avelocity[2] := _random()*200;
  ent.think := G_FreeEdict;
  ent.nextthink := level.time + 30;
  gi.linkentity (ent);
end;

(*QUAKED misc_gib_head (1 0 0) (-8 -8 -8) (8 8 8)
Intended for use with the target_spawner
*)
procedure SP_misc_gib_head(ent: edict_p); {cdecl;}
begin
  gi.setmodel (ent, 'models/objects/gibs/head/tris.md2');
  ent.solid := SOLID_NOT;
  ent.s.effects := ent.s.effects OR EF_GIB;
  ent.takedamage := DAMAGE_YES;
  ent.die := gib_die;
  ent.movetype := MOVETYPE_TOSS;
  ent.svflags := ent.svflags OR SVF_MONSTER;
  ent.deadflag := DEAD_DEAD;
  ent.avelocity[0] := _random()*200;
  ent.avelocity[1] := _random()*200;
  ent.avelocity[2] := _random()*200;
  ent.think := G_FreeEdict;
  ent.nextthink := level.time + 30;
  gi.linkentity (ent);
end;

//============================

(*QUAKED target_character (0 0 1) ?
used with target_string (must be on same 'team')
'count' is position in the string (starts at 1)
*)

procedure SP_target_character(self: edict_p); {cdecl;}
begin
  self.movetype := MOVETYPE_PUSH;
  gi.setmodel (self, self.model);
  self.solid := SOLID_BSP;
  self.s.frame := 12;
  gi.linkentity (self);
  exit;
end;


(*QUAKED target_string (0 0 1) (-8 -8 -8) (8 8 8)
*)

procedure target_string_use(self, other, activator: edict_p); cdecl;
Var e: edict_p; n, l: Integer; c: Char;
begin
  l := strlen(self._message);
  e := self.teammaster;
  while e<>Nil do begin
    if e.count = 0 then
    begin
      e := e.teamchain;
      continue;
    end;
    n := e.count - 1;
    if n > l then
    begin
      e.s.frame := 12;
      e := e.teamchain;
      continue;
    end;

    c := self._message[n];
    if (c >= '0') and (c <= '9') then
      e.s.frame := Ord(c) - Ord('0')
    else if (c = '-') then
      e.s.frame := 10
    else if (c = ':') then
      e.s.frame := 11
    else
      e.s.frame := 12;

    e := e.teamchain;
  end;
end;

procedure SP_target_string(self: edict_p); {cdecl;}
begin
  if self._message = Nil then
    self._message := '';
  self.use := target_string_use;
end;


(*QUAKED func_clock (0 0 1) (-8 -8 -8) (8 8 8) TIMER_UP TIMER_DOWN START_OFF MULTI_USE
target a target_string with this

The default is to be a time of day clock

TIMER_UP and TIMER_DOWN run for 'count' seconds and the fire 'pathtarget'
If START_OFF, this entity must be used before it starts

'style'    0 'xx'
      1 'xx:xx'
      2 'xx:xx:xx'
*)

Const
  CLOCK_MESSAGE_SIZE = 16;

// don't let field width of any clock messages change, or it
// could cause an overwrite after a game load

// CAK - static, so don't put in interface
procedure func_clock_reset(self: edict_p);
begin
  self.activator := Nil;
  if (self.spawnflags AND 1)<>0 then
  begin
    self.health := 0;
    self.wait := self.count;
  end
  else if (self.spawnflags AND 2)<>0 then
  begin
    self.health := self.count;
    self.wait := 0;
  end;
end;

// CAK - static, so don't put in interface
procedure func_clock_format_countdown(self: edict_p);
begin
  if self.style = 0 then
  begin
    Com_sprintf(self._message, CLOCK_MESSAGE_SIZE, '%2i', [self.health]);
    exit;
  end;

  if self.style = 1 then
  begin
    Com_sprintf(self._message, CLOCK_MESSAGE_SIZE, '%2i:%2i', [self.health div 60, self.health mod 60]);
    if self._message[3] = ' ' then
      self._message[3] := '0';
    exit;
  end;

  if self.style = 2 then
  begin
    Com_sprintf(self._message, CLOCK_MESSAGE_SIZE, '%2i:%2i:%2i', [self.health div 3600, (self.health - (self.health div 3600) * 3600) div 60, self.health mod 60]);
    if self._message[3] = ' ' then
      self._message[3] := '0';
    if self._message[6] = ' ' then
      self._message[6] := '0';
    exit;
  end;
end;

procedure func_clock_think(self: edict_p); cdecl;
Var ltime: TDateTime; Year, Month, Day, Hour, Minute, Second, MilliSecond: Word;
savetarget, savemessage: PChar;
begin
  if self.enemy = Nil then
  begin
    self.enemy := G_Find(Nil, FOFS_targetname, self.target);
    if self.enemy = Nil then
      exit;
  end;

  if (self.spawnflags AND 1)<>0 then
  begin
    func_clock_format_countdown(self);
    inc(self.health);
  end
  else if (self.spawnflags AND 2)<>0 then
  begin
    func_clock_format_countdown(self);
    dec(self.health);
  end
  else
  begin
    ltime := time();
    DecodeDateTime(ltime, Year, Month, Day, Hour, Minute, Second, MilliSecond);
    Com_sprintf(self._message, CLOCK_MESSAGE_SIZE, '%2i:%2i:%2i', [Hour, Minute, Second]);
    if self._message[3] = ' ' then
      self._message[3] := '0';
    if self._message[6] = ' ' then
      self._message[6] := '0'
  end;

  self.enemy._message := self._message;
  self.enemy.use(self.enemy, self, self);

  if (((self.spawnflags AND 1)<>0) and (self.health > self.wait))
  or (((self.spawnflags AND 2)<>0) and (self.health < self.wait)) then
  begin
    if self.pathtarget<>Nil then
    begin
      savetarget := self.target;
      savemessage := self._message;
      self.target := self.pathtarget;
      self._message := Nil;
      G_UseTargets(self, self.activator);
      self.target := savetarget;
      self._message := savemessage;
    end;

    if (self.spawnflags AND 8)=0 then
      exit;

    func_clock_reset (self);

    if (self.spawnflags AND 4)<>0 then
      exit;
  end;

  self.nextthink := level.time + 1;
end;

procedure func_clock_use(self, other, activator: edict_p); cdecl;
begin
  if (self.spawnflags AND 8)=0 then
    self.use := Nil;
  if self.activator<>Nil then
    exit;
  self.activator := activator;
  self.think(self);
end;

procedure SP_func_clock(self: edict_p); {cdecl;}
begin
  if self.target = Nil then
  begin
    gi.dprintf('%s with no target at %s'#10, self.classname, vtos(self.s.origin));
    G_FreeEdict(self);
    exit;
  end;

  if ((self.spawnflags AND 2)<>0) and (self.count=0) then
  begin
    gi.dprintf('%s with no count at %s'#10, self.classname, vtos(self.s.origin));
    G_FreeEdict(self);
    exit;
  end;

  if ((self.spawnflags AND 1)<>0) and (self.count=0) then
    self.count := 60*60;;

  func_clock_reset(self);

  self._message := gi.TagMalloc(CLOCK_MESSAGE_SIZE, TAG_LEVEL);

  self.think := func_clock_think;

  if (self.spawnflags AND 4)<>0 then
    self.use := func_clock_use
  else
    self.nextthink := level.time + 1;
end;

//=========================================

procedure teleporter_touch(self, other: edict_p; plane: cplane_p; surf: csurface_p); cdecl;
Var dest: edict_p; i: Integer;
begin
  if other.client=Nil then
    exit;
  dest := G_Find(Nil, FOFS_targetname, self.target);
  if dest = Nil then
  begin
    gi.dprintf('Couldn''t find destination'#10);
    exit;
  end;

  // unlink to make sure it can't possibly interfere with KillBox
  gi.unlinkentity(other);

  VectorCopy(dest.s.origin, other.s.origin);
  VectorCopy(dest.s.origin, other.s.old_origin);
  other.s.origin[2] := other.s.origin[2] + 10;

  // clear the velocity and hold them in place briefly
  VectorClear(other.velocity);
  other.client.ps.pmove.pm_time := 160 shr 3;    // hold time
  other.client.ps.pmove.pm_flags := other.client.ps.pmove.pm_flags OR PMF_TIME_TELEPORT;

  // draw the teleport splash at source and on the player
  self.owner.s.event := EV_PLAYER_TELEPORT;
  other.s.event := EV_PLAYER_TELEPORT;

  // set angles
  for i:=0 to 2 do
  begin
    other.client.ps.pmove.delta_angles[i] := ANGLE2SHORT(dest.s.angles[i] - other.client.resp.cmd_angles[i]);
  end;

  VectorClear(other.s.angles);
  VectorClear(other.client.ps.viewangles);
  VectorClear(other.client.v_angle);

  // kill anything at the destination
  KillBox(other);

  gi.linkentity(other);
end;

(*QUAKED misc_teleporter (1 0 0) (-32 -32 -24) (32 32 -16)
Stepping onto this disc will teleport players to the targeted misc_teleporter_dest object.
*)
procedure SP_misc_teleporter(ent: edict_p); {cdecl;}
Var trig: edict_p;
begin
  if ent.target = Nil then
  begin
    gi.dprintf('teleporter without a target.'#10);
    G_FreeEdict(ent);
    exit;
  end;

  gi.setmodel(ent, 'models/objects/dmspot/tris.md2');
  ent.s.skinnum := 1;
  ent.s.effects := EF_TELEPORTER;
  ent.s.sound := gi.soundindex('world/amb10.wav');
  ent.solid := SOLID_BBOX;

  VectorSet(ent.mins, -32, -32, -24);
  VectorSet(ent.maxs, 32, 32, -16);
  gi.linkentity(ent);

  trig := G_Spawn();
  trig.touch := teleporter_touch;
  trig.solid := SOLID_TRIGGER;
  trig.target := ent.target;
  trig.owner := ent;
  VectorCopy(ent.s.origin, trig.s.origin);
  VectorSet(trig.mins, -8, -8, 8);
  VectorSet(trig.maxs, 8, 8, 24);
  gi.linkentity(trig);
end;

(*QUAKED misc_teleporter_dest (1 0 0) (-32 -32 -24) (32 32 -16)
Point teleporters at these.
*)
procedure SP_misc_teleporter_dest(ent: edict_p); {cdecl;}
begin
  gi.setmodel(ent, 'models/objects/dmspot/tris.md2');
  ent.s.skinnum := 0;
  ent.solid := SOLID_BBOX;
//  ent.s.effects := ent.s.effects OR EF_FLIES;
  VectorSet(ent.mins, -32, -32, -24);
  VectorSet(ent.maxs, 32, 32, -16);
  gi.linkentity(ent);
end;


end.
