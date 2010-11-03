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
{ File(s): g_combat.c                                                        }
{ Content:                                                                   }
{                                                                            }
{ Initial conversion by : ???                                                }
{ Initial conversion on : ???                                                }
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
{ Updated on :  2003-Sept-18                                                 }
{ Updated by :  Scott Price (scott.price@totalise.co.uk)                     }
{ Updated on :  2002-Sept-25                                                 }
{ Updated by :  FAB (Fabrizio Rossini)                                       }
{                                                                            }
{----------------------------------------------------------------------------}
{ Notes:                                                                     }
{ - Review this code and assure we have not missed some Assignments in IF    }
{   statements, and accidentally interpretted them as Comparasons            }
{----------------------------------------------------------------------------}

unit g_combat;


interface

uses
  q_shared,
  q_shared_add,
  g_local,
  g_local_add;

function CanDamage(targ, inflictor: edict_p): qboolean;
procedure Killed(targ, inflictor, attacker: edict_p; damage: Integer; const point: vec3_t);
procedure SpawnDamage(dmgtype: Integer; const origin, normal: vec3_t; damage: Integer);
procedure M_ReactToDamage(targ, attacker: edict_p);
function CheckTeamDamage(targ, attacker: edict_p): qboolean;
procedure T_Damage(targ, inflictor, attacker: edict_p; var dir, point, normal: vec3_t; damage, knockback, dflags, mofd: Integer);
procedure T_RadiusDamage(inflictor, attacker: edict_p; damage: Single; ignore: edict_p; radius: Single; mofd: Integer);



implementation

uses
  GameUnit,
  g_main,
  cpas,
  g_monster,
  g_items,
  g_ai,
  g_cmds,
  g_utils;   // added by FAB

(* ============
CanDamage

Returns true if the inflictor can directly damage the target.  Used for
explosions and melee attacks.
============ *)
function CanDamage(targ, inflictor: edict_p): qboolean;
var
  dest: vec3_t;
  trace: trace_t;
begin
{ Following line originally commented out }
// bmodels need special checking because their origin is 0,0,0
  if (targ^.movetype = MOVETYPE_PUSH) then
  begin
    VectorAdd(targ^.absmin, targ^.absmax, dest);
    VectorScale(dest, 0.5, dest);
    trace := gi.trace(@inflictor^.s.origin, @vec3_origin, @vec3_origin, @dest, inflictor, MASK_SOLID);

    if (trace.fraction = 1.0) then
    begin
      Result := True;
      Exit;
    end;

    if (trace.ent = targ) then
    begin
      Result := True;
      Exit;
    end;

    Result := False;
    Exit;
  end;

  trace := gi.trace (@inflictor^.s.origin, @vec3_origin, @vec3_origin, @targ^.s.origin, inflictor, MASK_SOLID);
  if (trace.fraction = 1.0) then
  begin
    Result := True;
    Exit;
  end;

  VectorCopy(targ^.s.origin, dest);
  dest[0] := dest[0] + 15.0;
  dest[1] := dest[1] + 15.0;
  trace := gi.trace(@inflictor^.s.origin, @vec3_origin, @vec3_origin, @dest, inflictor, MASK_SOLID);
  if (trace.fraction = 1.0) then
  begin
    Result := True;
    Exit;
  end;

  VectorCopy(targ^.s.origin, dest);
  dest[0] := dest[0] + 15.0;
  dest[1] := dest[1] - 15.0;
  trace := gi.trace(@inflictor^.s.origin, @vec3_origin, @vec3_origin, @dest, inflictor, MASK_SOLID);
  if (trace.fraction = 1.0) then
  begin
    Result := True;
    Exit;
  end;

  VectorCopy(targ^.s.origin, dest);
  dest[0] := dest[0] - 15.0;
  dest[1] := dest[1] + 15.0;
  trace := gi.trace(@inflictor^.s.origin, @vec3_origin, @vec3_origin, @dest, inflictor, MASK_SOLID);
  if (trace.fraction = 1.0) then
  begin
    Result := True;
    Exit;
  end;

  VectorCopy(targ^.s.origin, dest);
  dest[0] := dest[0] - 15.0;
  dest[1] := dest[1] - 15.0;
  trace := gi.trace(@inflictor^.s.origin, @vec3_origin, @vec3_origin, @dest, inflictor, MASK_SOLID);
  if (trace.fraction = 1.0) then
  begin
    Result := True;
    Exit;
  end;

  Result := False;
end;

(* ============
Killed
============ *)
procedure Killed(targ, inflictor, attacker: edict_p; damage: Integer; const point: vec3_t);
begin
  if (targ^.health < -999) then
    targ^.health := -999;

  targ^.enemy := attacker;

  if (((targ^.svflags AND SVF_MONSTER) <> 0) AND (targ^.deadflag <> DEAD_DEAD)) then
  begin
{ Following line originally commented out }
//      targ->svflags |= SVF_DEADMONSTER;   // now treat as a different content type
    if ((targ^.monsterinfo.aiflags AND AI_GOOD_GUY) = 0) then
    begin
      Inc(level.killed_monsters);
      if (coop^.value <> 0) AND (attacker^.client <> nil) then
        Inc(attacker^.client^.resp.score);
      // medics won't heal monsters that they kill themselves
      if (strcmp(attacker^.classname, 'monster_medic') = 0) then
        targ^.owner := attacker;
    end;
  end;

  if ((targ^.movetype = MOVETYPE_PUSH) OR (targ^.movetype = MOVETYPE_STOP) OR (targ^.movetype = MOVETYPE_NONE)) then
  begin   // doors, triggers, etc
    targ^.die(targ, inflictor, attacker, damage, point);
    Exit;
  end;

  if (((targ^.svflags AND SVF_MONSTER) <> 0) AND (targ^.deadflag <> DEAD_DEAD)) then
  begin
    targ^.touch := Nil;
    monster_death_use(targ);
  end;

  targ^.die(targ, inflictor, attacker, damage, point);
end;


(* ================
SpawnDamage
================ *)
procedure SpawnDamage(dmgtype: Integer; const origin, normal: vec3_t; damage: Integer);
begin
  if (damage > 255) then
    damage := 255;
  gi.WriteByte(svc_temp_entity);
  gi.WriteByte(dmgtype);
{ Following line originally commented out }
//   gi.WriteByte (damage);
  gi.WritePosition(origin);
  gi.WriteDir(normal);
  gi.multicast(@origin, MULTICAST_PVS);
end;

{ This Routine is only visible in-side this unit }
(* ============
T_Damage

targ      entity that is being damaged
inflictor   entity that is causing the damage
attacker   entity that caused the inflictor to damage targ
   example: targ=monster, inflictor=rocket, attacker=player

dir         direction of the attack
point      point at which the damage is being inflicted
normal      normal vector from that point
damage      amount of damage being inflicted
knockback   force to be applied against targ as a result of the damage

dflags      these flags are used to control how T_Damage works
   DAMAGE_RADIUS         damage was indirect (from a nearby explosion)
   DAMAGE_NO_ARMOR         armor does not protect from this damage
   DAMAGE_ENERGY         damage is from an energy based weapon
   DAMAGE_NO_KNOCKBACK      do not affect velocity, just view angles
   DAMAGE_BULLET         damage is from a bullet (used for ricochets)
   DAMAGE_NO_PROTECTION   kills godmode, armor, everything
============ *)
function CheckPowerArmor(ent: edict_p; const point, normal: vec3_t; damage, dflags: Integer): Integer;
var
  client: gclient_p;
  save, power_armor_type, index, damagePerCell, pa_te_type, power, power_used: Integer;
  vec, forward_: vec3_t;
  dot: Single;
begin
  if (damage = 0) then
  begin
    Result := 0;
    Exit;
  end;

  client := ent^.client;

  if (dflags AND DAMAGE_NO_ARMOR) <> 0 then
  begin
    Result := 0;
    Exit;
  end;

  if (client <> Nil) then
  begin
    power_armor_type := PowerArmorType(ent);
    if (power_armor_type <> POWER_ARMOR_NONE) then
    begin
      index := ITEM_INDEX(FindItem('Cells'));
      power := client^.pers.inventory[index];
    end
  end
  else if (ent^.svflags AND SVF_MONSTER) <> 0 then
  begin
    power_armor_type := ent^.monsterinfo.power_armor_type;
    power := ent^.monsterinfo.power_armor_power;
  end
  else
  begin
    Result := 0;
    Exit;
  end;

  if (power_armor_type = POWER_ARMOR_NONE) then
  begin
    Result := 0;
    Exit;
  end;

  if (power = 0) then
  begin
    Result := 0;
    Exit;
  end;

  if (power_armor_type = POWER_ARMOR_SCREEN) then
  begin
    // only works if damage point is in front
    AngleVectors(ent^.s.angles, @forward_, Nil, Nil);
    VectorSubtract(point, ent^.s.origin, vec);
    VectorNormalize(vec);
    dot := DotProduct(vec, forward_);
    if (dot <= 0.3) then
    begin
      Result := 0;
      Exit;
    end;

    damagePerCell := 1;
    pa_te_type := Ord(TE_SCREEN_SPARKS);  // Check this typecast ...by FAB
    damage := damage div 3;
  end
  else
  begin
    damagePerCell := 2;
    pa_te_type := Ord(TE_SHIELD_SPARKS);   // Check this typecast ...by FAB
    damage := (2 * damage) div 3;
  end;

  save := power * damagePerCell;
  if (save = 0) then
  begin
    Result := 0;
    Exit;
  end;

  if (save > damage) then
    save := damage;

  SpawnDamage(pa_te_type, point, normal, save);
  ent^.powerarmor_time := level.time + 0.2;

  //power_used := save / damagePerCell;
  power_used := save mod damagePerCell;

  if (client <> Nil) then
    client^.pers.inventory[index] := client^.pers.inventory[index] - power_used
  else
    ent^.monsterinfo.power_armor_power := ent^.monsterinfo.power_armor_power - power_used;

  Result := save;
end;

{ This Routine is only visible in-side this unit }
function CheckArmor(ent: edict_p; const point, normal: vec3_t; damage, te_sparks, dflags: Integer): Integer;
var
  client: gclient_p;
  save, index: Integer;
  armor: gitem_p;
begin
  if (damage = 0) then
  begin
    Result := 0;
    Exit;
  end;

  client := ent^.client;

  if (client = Nil) then
  begin
    Result := 0;
    Exit;
  end;

  if (dflags AND DAMAGE_NO_ARMOR) <> 0 then
  begin
    Result := 0;
    Exit;
  end;

  index := ArmorIndex(ent);
  if (index = 0) then
  begin
    Result := 0;
    Exit;
  end;

  armor := GetItemByIndex(index);

  { NOTE:  2003-09-18-Scott Price:
           Commented out FAB's conversion, and corrected the original which was
           almost correct - I hope :) }
  if (dflags AND DAMAGE_ENERGY) <> 0 then
    save := ceil(gitem_armor_p(armor^.info)^.energy_protection * damage)
    { save := ceil((gitem_armor_p(armor)^.energy_protection * damage)) //check this by FAB .. }
  else
    save := ceil(gitem_armor_p(armor^.info)^.normal_protection * damage);
    { save := ceil((gitem_armor_p(armor)^.normal_protection * damage)); //check this by FAB .. }

  if (save >= client^.pers.inventory[index]) then
    save := client^.pers.inventory[index];

  if (save = 0) then
  begin
    Result := 0;
    Exit;
  end;

  client^.pers.inventory[index] := client^.pers.inventory[index] - save;
  SpawnDamage(te_sparks, point, normal, save);

  Result := save;
end;

procedure M_ReactToDamage(targ, attacker: edict_p);
begin
  if (attacker^.client = Nil) AND ((attacker^.svflags AND SVF_MONSTER) = 0) then
    Exit;

  if (attacker = targ) OR (attacker = targ^.enemy) then
    Exit;

  // if we are a good guy monster and our attacker is a player
  // or another good guy, do not get mad at them
  if (targ^.monsterinfo.aiflags AND AI_GOOD_GUY) <> 0 then
  begin
    if (attacker^.client <> Nil) OR ((attacker^.monsterinfo.aiflags AND AI_GOOD_GUY) <> 0) then
      Exit;
  end;

  // we now know that we are not both good guys

  // if attacker is a client, get mad at them because he's good and we're not
  if (attacker^.client <> Nil) then
  begin
    targ^.monsterinfo.aiflags := targ^.monsterinfo.aiflags AND (NOT AI_SOUND_TARGET);

    // this can only happen in coop (both new and old enemies are clients)
    // only switch if can't see the current enemy
    if (targ^.enemy <> Nil) AND (targ^.enemy^.client <> Nil) then
    begin
      if (visible(targ, targ^.enemy)) then
      begin
        targ^.oldenemy := attacker;
        Exit;
      end;
      targ^.oldenemy := targ^.enemy;
    end;

    targ^.enemy := attacker;
    if ((targ^.monsterinfo.aiflags AND AI_DUCKED) = 0) then
      FoundTarget(targ);

    Exit;
  end;

  // it's the same base (walk/swim/fly) type and a different classname and it's not a tank
  // (they spray too much), get mad at them
  if (((targ^.flags AND (FL_FLY OR FL_SWIM)) = (attacker^.flags AND (FL_FLY OR FL_SWIM))) AND
           (strcmp(targ^.classname, attacker^.classname) <> 0) AND
           (strcmp(attacker^.classname, 'monster_tank') <> 0) AND
           (strcmp(attacker^.classname, 'monster_supertank') <> 0) AND
           (strcmp(attacker^.classname, 'monster_makron') <> 0) AND
           (strcmp(attacker^.classname, 'monster_jorg') <> 0) ) then
  begin
    if (targ^.enemy <> Nil) AND (targ^.enemy^.client <> Nil) then
      targ^.oldenemy := targ^.enemy;

    targ^.enemy := attacker;

    if ((targ^.monsterinfo.aiflags AND AI_DUCKED) = 0) then
      FoundTarget(targ);
  end
  // if they *meant* to shoot us, then shoot back
  else if (attacker^.enemy = targ) then
  begin
    if (targ^.enemy <> Nil) AND (targ^.enemy^.client <> Nil) then
      targ^.oldenemy := targ^.enemy;

    targ^.enemy := attacker;

    if ((targ^.monsterinfo.aiflags AND AI_DUCKED) = 0) then
      FoundTarget(targ);
  end
  // otherwise get mad at whoever they are mad at (help our buddy) unless it is us!
  else if (attacker^.enemy <> Nil) AND (attacker^.enemy <> targ) then
  begin
    if (targ^.enemy <> Nil) AND (targ^.enemy^.client <> Nil) then
      targ^.oldenemy := targ^.enemy;

    targ^.enemy := attacker^.enemy;
    if ((targ^.monsterinfo.aiflags AND AI_DUCKED) = 0) then
      FoundTarget(targ);
  end;
end;

function CheckTeamDamage(targ, attacker: edict_p): qboolean;
begin
   // these 2 lines originally commented
  //FIXME make the next line real and uncomment this block
  // if ((ability to damage a teammate == OFF) && (targ's team == attacker's team))
  Result := False;
end;

procedure T_Damage(targ, inflictor, attacker: edict_p; var dir, point, normal: vec3_t; damage, knockback, dflags, mofd: Integer);
var
  client: gclient_p;
  take, save, asave, psave, te_sparks_: Integer;
  kvel: vec3_t;
  mass: Single;
begin
  if (targ^.takedamage = DAMAGE_NO) then    // check this .. by FAB
    Exit;

  // friendly fire avoidance
  // if enabled you can't hurt teammates (but you can hurt yourself)
  // knockback still occurs
  //
  //if ((targ != attacker) && ((deathmatch->value && ((int)(dmflags->value) & (DF_MODELTEAMS | DF_SKINTEAMS))) || coop->value))

  { NOTE:  2003-09-18:  Scott Price
           I think the original works something like the following:

   (<first expression> AND (<second expression> AND <third expression>) OR <fourth expression>) }
  if ((targ <> attacker) and (((deathmatch^.value <> 0) and ((trunc(dmflags^.value) AND (DF_MODELTEAMS OR DF_SKINTEAMS)) <> 0))) or (coop^.value <> 0)) then
  begin
    if (OnSameTeam(targ, attacker)) then
    begin
      if (trunc(dmflags^.value) AND DF_NO_FRIENDLY_FIRE) <> 0 then
        damage := 0
      else
        mofd := mofd OR MOD_FRIENDLY_FIRE;
    end;
  end;
  meansOfDeath := mofd;

  // easy mode takes half damage
  if (skill^.value = 0) AND (deathmatch^.value = 0) AND (targ^.client <> Nil) then
  begin
    //damage := damage * 0.5;
    damage := damage div 2; // Check this ...by FAB   // SP:  Should be ok
    if (damage = 0) then
      damage := 1;
  end;

  client := targ^.client;

  if (dflags AND DAMAGE_BULLET) <> 0 then
    te_sparks_ := Ord(TE_BULLET_SPARKS) // Check this typecast ...by FAB
  else
    te_sparks_ := Ord(TE_SPARKS);       // Check this typecast ...by FAB

  VectorNormalize(dir);

// bonus damage for suprising a monster
  if ((dflags AND DAMAGE_RADIUS) = 0) AND ((targ^.svflags AND SVF_MONSTER) <> 0) AND (attacker^.client <> Nil) AND (targ^.enemy = Nil) AND (targ^.health > 0) then
    damage := damage * 2;

  if (targ^.flags AND FL_NO_KNOCKBACK) <> 0 then
    knockback := 0;

// figure momentum add
  if ((dflags AND DAMAGE_NO_KNOCKBACK) = 0) then
  begin
    //if ((knockback) && (targ->movetype != MOVETYPE_NONE) && (targ->movetype != MOVETYPE_BOUNCE) && (targ->movetype != MOVETYPE_PUSH) && (targ->movetype != MOVETYPE_STOP))
    if (knockback <> 0) AND (targ^.movetype <> MOVETYPE_NONE) AND (targ^.movetype <> MOVETYPE_BOUNCE) AND (targ^.movetype <> MOVETYPE_PUSH) AND (targ^.movetype <> MOVETYPE_STOP) then
    begin
      if (targ^.mass < 50) then
        mass := 50
      else
        mass := targ^.mass;

      if (targ^.client <> Nil) AND (attacker = targ) then
        VectorScale(dir, 1600.0 * knockback / mass, kvel)   // the rocket jump hack...
      else
        VectorScale(dir, 500.0 * knockback / mass, kvel);

      VectorAdd(targ^.velocity, kvel, targ^.velocity);
    end;
  end;

  take := damage;
  save := 0;

  // check for godmode
  if ((targ^.flags AND FL_GODMODE) <> 0) AND ((dflags AND DAMAGE_NO_PROTECTION) = 0) then
  begin
    take := 0;
    save := damage;
    SpawnDamage(te_sparks_, point, normal, save);
  end;

  // check for invincibility
  if ((client <> Nil) AND (client^.invincible_framenum > level.framenum))  AND ((dflags AND DAMAGE_NO_PROTECTION) = 0) then
  begin
    if (targ^.pain_debounce_time < level.time) then
    begin
      gi.sound(targ, CHAN_ITEM, gi.soundindex('items/protect4.wav'), 1, ATTN_NORM, 0);
      targ^.pain_debounce_time := level.time + 2;
    end;
    take := 0;
    save := damage;
  end;

  psave := CheckPowerArmor(targ, point, normal, take, dflags);
  take := take - psave;

  asave := CheckArmor(targ, point, normal, take, te_sparks_, dflags);
  take := take - asave;

  //treat cheat/powerup savings the same as armor
  asave := asave + save;

  // team damage avoidance
  if ((dflags AND DAMAGE_NO_PROTECTION) = 0) AND CheckTeamDamage(targ, attacker) then
    Exit;

// do the damage
  if (take <> 0) then
  begin
    if ((targ^.svflags AND SVF_MONSTER) <> 0) OR (client <> Nil) then
      SpawnDamage(Ord(TE_BLOOD), point, normal, take)
    else
      SpawnDamage(te_sparks_, point, normal, take);

    targ^.health := targ^.health - take;

    if (targ^.health <= 0) then
    begin
      if ((targ^.svflags AND SVF_MONSTER) <> 0) OR (client <> Nil) then
        targ^.flags := targ^.flags OR FL_NO_KNOCKBACK;
      Killed(targ, inflictor, attacker, take, point);
      Exit;
    end;
  end;

  if (targ^.svflags AND SVF_MONSTER) <> 0 then
  begin
    M_ReactToDamage(targ, attacker);
    if ((targ^.monsterinfo.aiflags AND AI_DUCKED) = 0) AND (take <> 0) then
    begin
      targ^.pain(targ, attacker, knockback, take);
      // nightmare mode monsters don't go into pain frames often
      if (skill^.value = 3) then
        targ^.pain_debounce_time := level.time + 5;
    end;
  end
  else if (client <> Nil) then
  begin
    if ((targ^.flags AND FL_GODMODE) = 0) AND (take <> 0) then
      targ^.pain(targ, attacker, knockback, take);
  end
  else if (take <> 0) then
  begin
    if (@targ^.pain <> Nil) then
      targ^.pain(targ, attacker, knockback, take);
  end;

  // add to the damage inflicted on a player this frame
  // the total will be turned into screen blends and view angle kicks
  // at the end of the frame
  if (client <> Nil) then
  begin
    client^.damage_parmor := client^.damage_parmor + psave;
    client^.damage_armor := client^.damage_armor + asave;
    client^.damage_blood := client^.damage_blood + take;
    client^.damage_knockback := client^.damage_knockback + knockback;
    VectorCopy(point, client^.damage_from);
  end;
end;

{  |  |                                        |  |   }
{  V  V   ToDo:  Scott to continue from Here   V  V   }


(* ============
T_RadiusDamage
============ *)
procedure T_RadiusDamage(inflictor, attacker: edict_p; damage: Single; ignore: edict_p; radius: Single; mofd: Integer);
var
  points: Single;
  ent: edict_p;
  v, dir: vec3_t;
label
  __Continue;
begin
  ent := Nil;

  { NOTE:  Original Code here used a WHILE loop to perform this operation, but
           made an assignment in the Logical Test, so I have altered to be a
           initally called, and then a TRY..FINALLY block to perform the
           operation again prior to the end of the Loop and ReTest - Scott Price }
  ent := findradius(ent, inflictor^.s.origin, radius);
  while (ent <> Nil) do
  begin
    if (ent = ignore) then
      goto __Continue;
    if (ent^.takedamage = DAMAGE_NO) then    // check this ...by FAB
      goto __Continue;

    VectorAdd(ent^.mins, ent^.maxs, v);
    VectorMA(ent^.s.origin, 0.5, v, v);
    VectorSubtract(inflictor^.s.origin, v, v);
    points := damage - 0.5 * VectorLength(v);

    if (ent = attacker) then
      points := points * 0.5;
    if (points > 0) then
    begin
      if CanDamage(ent, inflictor) then
      begin
        VectorSubtract(ent^.s.origin, inflictor^.s.origin, dir);
        T_Damage(ent, inflictor, attacker, dir, inflictor^.s.origin, vec3_origin, Trunc(points), Trunc(points), DAMAGE_RADIUS, mofd);
      end;
    end;

  __Continue:
    { NOTE:  ADDED THIS LINE TO COMPENSATE }
    ent := findradius(ent, inflictor^.s.origin, radius);
  end;
end;

end.
