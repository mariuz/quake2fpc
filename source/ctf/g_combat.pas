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


unit g_combat;

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
// g_combat.c

// TODO:  #include "g_local.h"



{ NOTES (For Scott):
  ==================
  - Review this code and assure we have not missed some Assignments in IF
    statements, and accidentally interpretted them as Comparasons }



interface



function CanDamage(targ, inflictor: Pedict_t): qboolean;
procedure Killed(targ, inflictor, attacker: Pedict_t; damage: Integer; point: vec3_t);
procedure SpawnDamage(dmgtype: Integer; origin, normal: vec3_t; damage: Integer);
procedure M_ReactToDamage(targ, attacker: Pedict_t);
function CheckTeamDamage(targ, attacker: Pedict_t): qboolean;
procedure T_Damage(targ, inflictor, attacker: Pedict_t; dir, point, normal: vec3_t; damage, knockback, dflags, mofd: Integer);
procedure T_RadiusDamage(inflictor, attacker: Pedict_t; damage: float; ignore: Pedict_t; radius: float; mofd: Integer);



implementation



(* ============
CanDamage

Returns true if the inflictor can directly damage the target.  Used for
explosions and melee attacks.
============ *)
function CanDamage(targ, inflictor: Pedict_t): qboolean;
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
    trace := gi.trace(inflictor^.s.origin, vec3_origin, vec3_origin, dest, inflictor, MASK_SOLID);

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

  trace := gi.trace (inflictor^.s.origin, vec3_origin, vec3_origin, targ^.s.origin, inflictor, MASK_SOLID);
  if (trace.fraction = 1.0) then
  begin
    Result := True;
    Exit;
  end;

  VectorCopy(targ^.s.origin, dest);
  dest[0] := dest[0] + 15.0;
  dest[1] := dest[1] + 15.0;
  trace := gi.trace(inflictor^.s.origin, vec3_origin, vec3_origin, dest, inflictor, MASK_SOLID);
  if (trace.fraction = 1.0) then
  begin
    Result := True;
    Exit;
  end;

  VectorCopy(targ^.s.origin, dest);
  dest[0] := dest[0] + 15.0;
  dest[1] := dest[1] - 15.0;
  trace := gi.trace(inflictor^.s.origin, vec3_origin, vec3_origin, dest, inflictor, MASK_SOLID);
  if (trace.fraction = 1.0) then
  begin
    Result := True;
    Exit;
  end;

  VectorCopy(targ^.s.origin, dest);
  dest[0] := dest[0] - 15.0;
  dest[1] := dest[1] + 15.0;
  trace := gi.trace(inflictor^.s.origin, vec3_origin, vec3_origin, dest, inflictor, MASK_SOLID);
  if (trace.fraction = 1.0) then
  begin
    Result := True;
    Exit;
  end;

  VectorCopy(targ^.s.origin, dest);
  dest[0] := dest[0] - 15.0;
  dest[1] := dest[1] - 15.0;
  trace := gi.trace(inflictor^.s.origin, vec3_origin, vec3_origin, dest, inflictor, MASK_SOLID);
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
procedure Killed(targ, inflictor, attacker: Pedict_t; damage: Integer; point: vec3_t);
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
      if (coop^.value AND attacker^.client) then
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
procedure SpawnDamage(dmgtype: Integer; origin, normal: vec3_t; damage: Integer);
begin
  if (damage > 255) then
    damage := 255;
  gi.WriteByte(svc_temp_entity);
  gi.WriteByte(dmgtype);
{ Following line originally commented out }
//   gi.WriteByte (damage);
  gi.WritePosition(origin);
  gi.WriteDir(normal);
  gi.multicast(origin, MULTICAST_PVS);
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
function CheckPowerArmor(ent: Pedict_t; point, normal: vec3_t; damage, dflags: Integer): Integer;
var
  client: Pgclient_t;
  save, power_armor_type, index, damagePerCell, pa_te_type, power, power_used: Integer;
  vec, forwards: vec3_t;
  dot: float;
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
    { The variable 'forward' has been renamed to 'forwards' }
    // only works if damage point is in front
    AngleVectors(ent^.s.angles, forwards, Nil, Nil);
    VectorSubtract(point, ent^.s.origin, vec);
    VectorNormalize(vec);
    dot := DotProduct(vec, forwards);
    if (dot <= 0.3) then
    begin
      Result := 0;
      Exit;
    end;

    damagePerCell := 1;
    pa_te_type := TE_SCREEN_SPARKS;
    { TODO:  The following commented line is a Delphi Safe alternative }
    //damage := damage div 3;
    damage := damage / 3;
  end
  else
  begin
    damagePerCell := 2;
    pa_te_type := TE_SHIELD_SPARKS;
    { TODO:  The following commented line is a Delphi Safe alternative }
    //damage := (2 * damage) div 3;
    damage := (2 * damage) / 3;
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

  power_used := save / damagePerCell;

  if (client <> Nil) then
    client^.pers.inventory[index] := client^.pers.inventory[index] - power_used;
  else
    ent^.monsterinfo.power_armor_power := ent^.monsterinfo.power_armor_power - power_used;

  Result := save;
end;

{ This Routine is only visible in-side this unit }
function CheckArmor(ent: Pedict_t; point, normal: vec3_t; damage, te_sparks, dflags: Integer): Integer;
var
  client: Pgclient_t;
  save, index: Integer;
  armor: Pgitem_t;
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

  if (dflags AND DAMAGE_ENERGY) <> 0 then
    save := ceil((Pgitem_armor_t(armor)^.info)^.energy_protection * damage);
  else
    save := ceil((Pgitem_armor_t(armor)^.info)^.normal_protection * damage);

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

procedure M_ReactToDamage(targ, attacker: Pedict_t);
end;
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

    if ((targ^.monsterinfo.aiflags AND AI_DUCKED) = 0)
      FoundTarget(targ);
  end;

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

function CheckTeamDamage(targ, attacker: Pedict_t): qboolean;
begin
  //FIXME make the next line real and uncomment this block
  // if ((ability to damage a teammate == OFF) && (targ's team == attacker's team))
  Result := False;
end;

procedure T_Damage(targ, inflictor, attacker: Pedict_t; dir, point, normal: vec3_t; damage, knockback, dflags, mofd: Integer);
var
  client: Pgclient_t;
  take, save, asave, psave, te_sparks: Integer;
  kvel: vec3_t;
  mass: float;
begin
  if (targ^.takedamage = 0) then
    Exit;

  // friendly fire avoidance
  // if enabled you can't hurt teammates (but you can hurt yourself)
  // knockback still occurs
  if ((targ <> attacker) AND ((deathmatch^.value AND (Integer(dmflags^.value) AND (DF_MODELTEAMS OR DF_SKINTEAMS))) OR coop^.value)) then
  begin
    if (OnSameTeam(targ, attacker)) then
    begin
      if (Integer(dmflags^.value) AND DF_NO_FRIENDLY_FIRE) then
        damage := 0;
      else
        mofd := mofd OR MOD_FRIENDLY_FIRE;
    end;
  end;
  meansOfDeath := mofd;

  // easy mode takes half damage
  if (skill^.value = 0) AND (deathmatch^.value = 0) AND (targ^.client <> Nil) then
  begin
    damage := damage * 0.5;
    if (damage = 0) then
      damage := 1;
  end;

  client := targ^.client;

  if (dflags AND DAMAGE_BULLET) <> 0 then
    te_sparks := TE_BULLET_SPARKS;
  else
    te_sparks := TE_SPARKS;

  VectorNormalize(dir);

// bonus damage for suprising a monster
  if ((dflags AND DAMAGE_RADIUS) = 0) AND ((targ^.svflags AND SVF_MONSTER) <> 0) AND (attacker^.client <> Nil) AND (targ^.enemy = Nil) AND (targ^.health > 0) then
    damage := damage * 2;

  if (targ^.flags AND FL_NO_KNOCKBACK) <> 0 then
    knockback := 0;

// figure momentum add
  if ((dflags AND DAMAGE_NO_KNOCKBACK) = 0) then
  begin
    if ((knockback) && (targ->movetype != MOVETYPE_NONE) && (targ->movetype != MOVETYPE_BOUNCE) && (targ->movetype != MOVETYPE_PUSH) && (targ->movetype != MOVETYPE_STOP))
    begin
      if (targ^.mass < 50) then
        mass := 50;
      else
        mass := targ^.mass;

      if (targ^.client <> Nil) AND (attacker = targ) then
        VectorScale(dir, 1600.0 * float(knockback) / mass, kvel);   // the rocket jump hack...
      else
        VectorScale(dir, 500.0 * float(knockback) / mass, kvel);

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
    SpawnDamage(te_sparks, point, normal, save);
  end;

  // check for invincibility
  if (client <> Nil) AND (client^.invincible_framenum > level.framenum) AND ((dflags AND DAMAGE_NO_PROTECTION) = 0)
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

  asave = CheckArmor(targ, point, normal, take, te_sparks, dflags);
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
      SpawnDamage(TE_BLOOD, point, normal, take)
    else
      SpawnDamage(te_sparks, point, normal, take);

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
    if ((targ^.monsterinfo.aiflags AND AI_DUCKED) = 0) AND (take <> Nil) then
    begin
      targ^.pain(targ, attacker, knockback, take);
      // nightmare mode monsters don't go into pain frames often
      if (skill^.value = 3) then
        targ^.pain_debounce_time := level.time + 5;
    end;
  end
  else if (client <> Nil) then
  begin
    if ((targ^.flags AND FL_GODMODE) = 0) AND (take <> Nil) then
      targ^.pain(targ, attacker, knockback, take);
  end
  else if (take <> Nil) then
  begin
    if (targ^.pain <> Nil) then
      targ^.pain(targ, attacker, knockback, take);
  end

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

(* ============
T_RadiusDamage
============ *)
procedure T_RadiusDamage(inflictor, attacker: Pedict_t; damage: float; ignore: Pedict_t; radius: float; mofd: Integer);
var
  points: float;
  ent: Pedict_t;
  v, dir: vec3_t;
begin
  ent := Nil;

  { NOTE:  Original Code here used a WHILE loop to perform this operation, but
           made an assignment in the Logical Test, so I have altered to be a
           initally called, and then a TRY..FINALLY block to perform the
           operation again prior to the end of the Loop and ReTest - Scott Price }
  ent := findradius(ent, inflictor^.s.origin, radius);
  while (ent <> Nil) do
  begin
    { NOTE:  ADDED THE TRY FINALLY BLOCK TO COMPENSATE }
    TRY
      if (ent = ignore) then
        Continue;
      if (ent^.takedamage = 0) then
        Continue;

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
          T_Damage(ent, inflictor, attacker, dir, inflictor^.s.origin, vec3_origin, Integer(points), Integer(points), DAMAGE_RADIUS, mofd);
        end;
      end;
    FINALLY
      { NOTE:  ADDED THIS LINE TO COMPENSATE }
      ent := findradius(ent, inflictor^.s.origin, radius);
    END;
  end;
end;

end.
