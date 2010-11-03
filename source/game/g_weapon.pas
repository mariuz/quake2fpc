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
{ File(s): g_weapon.c                                                        }
{                                                                            }
{ Initial conversion by : YgriK (Igor Karpov) - glYgriK@hotbox.ru            }
{ Initial conversion on : 24-Jan-2002                                        }
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
{ Updated on : 20 Sept 2002                                                  }
{ Updated by : Fabrizio Rossini (FAB)                                        }
{ Completed translation                                                      }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{                                                                            }
{                                                                            }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{ 1) Do more tests and check for error                                       }
{                                                                            }
{----------------------------------------------------------------------------}

unit g_weapon;

interface

//...
uses
  q_shared,
  g_local,
  g_local_add;

procedure fire_grenade (self : edict_p; const start, aimdir : vec3_t; damage, speed : integer; timer, damage_radius : Single);
procedure fire_grenade2 (self : edict_p; const start, aimdir : vec3_t; damage, speed : integer; timer, damage_radius : Single; held : qboolean);
procedure fire_rocket (self : edict_p; const start, dir : vec3_t; damage, speed : integer; damage_radius : Single; radius_damage: Integer);
procedure fire_blaster (self : edict_p; var start, dir : vec3_t; damage, speed, effect : integer; hyper : qboolean);
procedure fire_bullet (self : edict_p; var start, aimdir : vec3_t; damage, kick, hspread, vspread, mod_ : integer);
procedure fire_shotgun (self : edict_p; var start, aimdir : vec3_t; damage, kick, hspread, vspread, count, mod_ : integer);
procedure fire_rail (self : edict_p; var start, aimdir : vec3_t; damage, kick : integer);
procedure fire_bfg (self : edict_p; const start, dir : vec3_t; damage, speed : integer; damage_radius : Single);
function fire_hit (self : edict_p; var aim : vec3_t; damage, kick : integer) : qboolean;



implementation

uses
  g_main,
  GameUnit,
  g_ai,
  g_combat,
  g_utils,
  p_weapon,
  g_misc,
  q_shared_add,
  game_add,
  CPas;


{*
=================
check_dodge

This is a support routine used when a client is firing
a non-instant attack weapon.  It checks to see if a
monster's dodge function should be called.
=================
*}
procedure check_dodge (self : edict_p; const start, dir : vec3_t; speed : integer);
var
  end_,
  v    : vec3_t;
  tr   : trace_t;
  eta  : Single;

begin
  // easy mode only ducks one quarter the time
  if (skill^.value = 0) then
    if (_random() > 0.25) then
      Exit;

  VectorMA (start, 8192, dir, end_);
  tr := gi.trace(@start, Nil, Nil, @end_, self, MASK_SHOT);
  if ( (tr.ent <> Nil) AND ((edict_p(tr.ent)^.svflags AND SVF_MONSTER) <> 0) AND
       (edict_p(tr.ent)^.health > 0) AND (@edict_p(tr.ent)^.monsterinfo.dodge <> Nil) AND (not infront(tr.ent, self)) ) then
  begin
    VectorSubtract (tr.endpos, start, v);
    eta := (VectorLength(v) - edict_p(tr.ent)^.maxs[0]) / speed;
    edict_p(tr.ent)^.monsterinfo.dodge (tr.ent, self, eta);
  end;
end;


{*
=================
fire_hit

Used for all impact (hit/punch/slash) attacks
=================
*}
//function fire_hit (edict_t *self, vec3_t aim, int damage, int kick) : qboolean;
function fire_hit (self : edict_p; var aim : vec3_t; damage, kick : integer) : qboolean;
var
  tr        : trace_t;
  forward_,
  right, up,
  v,
  point,
  dir       : vec3_t;
  range     : Single;
begin
  //see if enemy is in range
  VectorSubtract (self.enemy^.s.origin, self.s.origin, dir);
  range := VectorLength(dir);
  if (range > aim[0]) then
  begin
    Result := false;
    Exit;
  end;

  if (aim[1] > self.mins[0]) AND (aim[1] < self.maxs[0])
  then begin
    // the hit is straight on so back the range up to the edge of their bbox
    range := range - self.enemy^.maxs[0];
  end
  else begin
    // this is a side hit so adjust the "right" value out to the edge of their bbox
    if (aim[1] < 0) then
      aim[1] := self.enemy^.mins[0]
    else
      aim[1] := self.enemy^.maxs[0];
  end;

  VectorMA (self.s.origin, range, dir, point);

  tr := gi.trace (@self.s.origin, Nil, Nil, @point, self, MASK_SHOT);
  if (tr.fraction < 1) then
  begin
    if (edict_p(tr.ent)^.takedamage = DAMAGE_NO ) then
    begin
      Result := false;
      Exit;
    end;
    // if it will hit any client/monster then hit the one we wanted to hit
    if ( ((edict_p(tr.ent)^.svflags AND SVF_MONSTER) <> 0) OR (edict_p(tr.ent)^.client <> Nil) ) then
      tr.ent := self.enemy;
  end;

  AngleVectors(self.s.angles, @forward_, @right, @up);
  VectorMA (self.s.origin, range, forward_, point);
  VectorMA (point, aim[1], right, point);
  VectorMA (point, aim[2], up, point);
  VectorSubtract (point, self.enemy^.s.origin, dir);

  // do the damage
  T_Damage (tr.ent, @self, @self, dir, point, vec3_origin, damage, kick div 2, DAMAGE_NO_KNOCKBACK, MOD_HIT);

  { if (!(tr.ent.svflags & SVF_MONSTER) and (!tr.ent.client)) then }
  if ( ((edict_p(tr.ent).svflags AND SVF_MONSTER) = 0) AND (edict_p(tr.ent).client = nil) ) then
  begin
    Result := false;
    Exit;
  end;

  // do our special form of knockback here
  VectorMA (self.enemy^.absmin, 0.5, self.enemy^.size, v);
  VectorSubtract (v, point, v);
  VectorNormalize (v);
  VectorMA (self.enemy^.velocity, kick, v, self.enemy^.velocity);
  if (self.enemy^.velocity[2] > 0) then
    self.enemy^.groundentity := Nil;
  Result := true;
end;

{*
=================
fire_lead

This is an internal support routine used for bullet/pellet based weapons.
=================
*}
procedure fire_lead (self : edict_p; var start, aimdir : vec3_t; damage, kick, te_impact, hspread, vspread, mod_ : integer);
var
  tr           : trace_t;
  dir,
  forward_,
  right, up,
  end_,
  water_start,
  pos          : vec3_t;
  r, u         : Single;
  water        : qboolean;
  color,
  content_mask : integer;
begin
{   qboolean   water = false;
   int         content_mask = MASK_SHOT | MASK_WATER;}
  water := false;
  content_mask := MASK_SHOT OR MASK_WATER;

  tr := gi.trace (@self.s.origin, Nil, Nil, @start, self, MASK_SHOT);
  if ((tr.fraction < 1.0) = False) then
  begin
      vectoangles (aimdir, dir);
      AngleVectors (dir, @forward_, @right, @up);

      r := crandom()*hspread;
      u := crandom()*vspread;
      VectorMA (start, 8192, forward_, end_);
      VectorMA (end_, r, right, end_);
      VectorMA (end_, u, up, end_);

      { if (gi.pointcontents (start) & MASK_WATER) then }
      if (gi.pointcontents (start) AND MASK_WATER) <> 0 then
      begin
        water := true;
        VectorCopy (start, water_start);
        content_mask := content_mask AND (NOT MASK_WATER);
      end;

      tr := gi.trace (@start, Nil, Nil, @end_, self, content_mask);

      // see if we hit water
      if (tr.contents AND MASK_WATER) <> 0 then
      begin
        water := true;
        VectorCopy (tr.endpos, water_start);

        if (VectorCompare (start, tr.endpos) = 0) then
        begin
          if (tr.contents AND CONTENTS_WATER) <> 0 then
          begin
            if (strcmp(tr.surface^.name, '*brwater') = 0) then
              color := SPLASH_BROWN_WATER
            else
              color := SPLASH_BLUE_WATER;
          end
          else if (tr.contents AND CONTENTS_SLIME) <> 0 then
            color := SPLASH_SLIME
          else if (tr.contents AND CONTENTS_LAVA) <> 0 then
            color := SPLASH_LAVA
          else
            color := SPLASH_UNKNOWN;

          if (color <> SPLASH_UNKNOWN) then
          begin
            gi.WriteByte (svc_temp_entity);
            gi.WriteByte (integer(TE_SPLASH)); 
            gi.WriteByte (8);
            gi.WritePosition (tr.endpos);
            gi.WriteDir (tr.plane.normal);
            gi.WriteByte (color);
            gi.multicast (@tr.endpos, MULTICAST_PVS);
          end;

          // change bullet's course when it enters water
          VectorSubtract (end_, start, dir);
          vectoangles (dir, dir);
          AngleVectors (dir, @forward_, @right, @up);
          r := crandom()*hspread*2;
          u := crandom()*vspread*2;
          VectorMA (water_start, 8192, forward_, end_);
          VectorMA (end_, r, right, end_);
          VectorMA (end_, u, up, end_);
        end;

        // re-trace ignoring water this time
        tr := gi.trace(@water_start, Nil, Nil, @end_, self, MASK_SHOT);
      end;
  end;

  // send gun puff / flash
  if NOT ( (tr.surface <> Nil) AND ((tr.surface^.flags AND SURF_SKY) <> 0) ) then
  begin
    if (tr.fraction < 1.0) then
      if (edict_p(tr.ent)^.takedamage <> DAMAGE_NO) then 
        T_Damage(tr.ent, self, self, aimdir, tr.endpos, tr.plane.normal, damage, kick, DAMAGE_BULLET, mod_)
      else
        if (strncmp (tr.surface^.name, 'sky', 3) <> 0) then
        begin
          gi.WriteByte (svc_temp_entity);
          gi.WriteByte (te_impact);
          gi.WritePosition (tr.endpos);
          gi.WriteDir (tr.plane.normal);
          gi.multicast (@tr.endpos, MULTICAST_PVS);

          if (self^.client <> nil) then
            PlayerNoise (self, tr.endpos, PNOISE_IMPACT);
        end;
  end;

  // if went through water, determine where the end and make a bubble trail
  if (water) then
  begin
    VectorSubtract (tr.endpos, water_start, dir);
    VectorNormalize (dir);
    VectorMA (tr.endpos, -2, dir, pos);
    if ((gi.pointcontents (pos) AND MASK_WATER) <> 0) then
      VectorCopy(pos, tr.endpos)
    else
      tr := gi.trace(@pos, Nil, Nil, @water_start, tr.ent, MASK_WATER);

    VectorAdd (water_start, tr.endpos, pos);
    VectorScale (pos, 0.5, pos);

    gi.WriteByte (svc_temp_entity);
    gi.WriteByte (integer(TE_BUBBLETRAIL));  
    gi.WritePosition (water_start);
    gi.WritePosition (tr.endpos);
    gi.multicast (@pos, MULTICAST_PVS);
  end;
end;


{*
=================
fire_bullet

Fires a single round.  Used for machinegun and chaingun.  Would be fine for
pistols, rifles, etc....
=================
*}
procedure fire_bullet (self : edict_p; var start, aimdir : vec3_t; damage, kick, hspread, vspread, mod_ : integer);
begin
  fire_lead(self, start, aimdir, damage, kick, byte(TE_GUNSHOT), hspread, vspread, mod_);
end;


{*
=================
fire_shotgun

Shoots shotgun pellets.  Used by shotgun and super shotgun.
=================
*}
procedure fire_shotgun (self : edict_p; var start, aimdir : vec3_t; damage, kick, hspread, vspread, count, mod_ : integer);
var
  i : integer;
begin
  for i:= 0 to (count - 1) do
    fire_lead (self, start, aimdir, damage, kick, byte(TE_SHOTGUN), hspread, vspread, mod_);
end;


{*
=================
fire_blaster

Fires a single blaster bolt.  Used by the blaster and hyper blaster.
=================
*}
procedure blaster_touch (self, other : edict_p; plane : cplane_p; surf : csurface_p); cdecl;
var
  mod_ : integer;
begin
  if (other = self^.owner) then
    Exit;

  if ((surf <> Nil) AND ((surf^.flags AND SURF_SKY) <> 0)) then
  begin
    G_FreeEdict(self);
    Exit;
  end;

  if (self^.owner^.client <> Nil) then
    PlayerNoise (self^.owner, self^.s.origin, PNOISE_IMPACT);

  if (other^.takedamage <> DAMAGE_NO) then 
  begin
    if ((self^.spawnflags AND 1) <> 0) then
      mod_ := MOD_HYPERBLASTER
    else
      mod_ := MOD_BLASTER;
    T_Damage (other, self, self^.owner, self^.velocity, self^.s.origin, plane^.normal, self^.dmg, 1, DAMAGE_ENERGY, mod_);
  end
  else
  begin
    gi.WriteByte (svc_temp_entity);
    gi.WriteByte (integer(TE_BLASTER)); 
    gi.WritePosition (self^.s.origin);
    if (plane = Nil) then
      gi.WriteDir (vec3_origin)
    else
      gi.WriteDir (plane^.normal);
    gi.multicast (@self^.s.origin, MULTICAST_PVS);
  end;

  G_FreeEdict (self);
end;

procedure fire_blaster (self : edict_p; var start, dir : vec3_t; damage, speed, effect : integer; hyper : qboolean);
var
  bolt : edict_p;
  tr : trace_t;
begin
  VectorNormalize (dir);

  bolt := G_Spawn();

  bolt^.svflags := SVF_DEADMONSTER;
  // yes, I know it looks weird that projectiles are deadmonsters
  // what this means is that when prediction is used against the object
  // (blaster/hyperblaster shots), the player won't be solid clipped against
  // the object.  Right now trying to run into a firing hyperblaster
  // is very jerky since you are predicted 'against' the shots.

  VectorCopy (start, bolt^.s.origin);
  VectorCopy (start, bolt^.s.old_origin);
  vectoangles (dir, bolt^.s.angles);
  VectorScale (dir, speed, bolt^.velocity);
  bolt^.movetype := MOVETYPE_FLYMISSILE;
  bolt^.clipmask := MASK_SHOT;
  bolt^.solid := SOLID_BBOX;
  bolt^.s.effects := bolt^.s.effects OR effect;
  VectorClear (bolt^.mins);
  VectorClear (bolt^.maxs);
  bolt^.s.modelindex := gi.modelindex ('models/objects/laser/tris.md2');
  bolt^.s.sound := gi.soundindex ('misc/lasfly.wav');
  bolt^.owner := self;
  bolt^.touch := blaster_touch;
  bolt^.nextthink := level.time + 2;
  bolt^.think := G_FreeEdict;
  bolt^.dmg := damage;
  bolt^.classname := 'bolt';
  if (hyper) then
    bolt^.spawnflags := 1;
  gi.linkentity (bolt);

  if (self^.client <> Nil) then
    check_dodge (self, bolt^.s.origin, dir, speed);

  tr := gi.trace (@self^.s.origin, Nil, Nil, @bolt^.s.origin, bolt, MASK_SHOT);
  if (tr.fraction < 1.0) then
  begin
    VectorMA (bolt^.s.origin, -10, dir, bolt^.s.origin);
    bolt^.touch (bolt, tr.ent, Nil, Nil);
  end;
end;


{*
=================
fire_grenade
=================
*}
procedure Grenade_Explode (ent : edict_p); cdecl;
var
  origin : vec3_t;
  mod_   : integer;
  points : Single;
  v,
  dir    : vec3_t;
begin
  if (ent^.owner^.client <> Nil) then
    PlayerNoise (ent^.owner, ent^.s.origin, PNOISE_IMPACT);

  { Original Code Comment Below: }
  //FIXME: if we are onground then raise our Z just a bit since we are a point?
  if (ent^.enemy <> Nil) then
  begin
    VectorAdd (ent^.enemy^.mins, ent^.enemy^.maxs, v);
    VectorMA (ent^.enemy^.s.origin, 0.5, v, v);
    VectorSubtract (ent^.s.origin, v, v);
    points := ent^.dmg - 0.5 * VectorLength (v);
    VectorSubtract (ent^.enemy^.s.origin, ent^.s.origin, dir);
    if ((ent^.spawnflags AND 1) <> 0) then
      mod_ := MOD_HANDGRENADE
    else
      mod_ := MOD_GRENADE;
    T_Damage (ent^.enemy, ent, ent^.owner, dir, ent^.s.origin, vec3_origin, trunc(points), trunc(points), DAMAGE_RADIUS, mod_);
  end;

  if ((ent^.spawnflags AND 2) <> 0) then
    mod_ := MOD_HELD_GRENADE
  else if ((ent.spawnflags AND 1) <> 0) then
    mod_ := MOD_HG_SPLASH
  else
    mod_ := MOD_G_SPLASH;
  T_RadiusDamage(ent, ent^.owner, ent^.dmg, ent^.enemy, ent^.dmg_radius, mod_);

  VectorMA (ent^.s.origin, -0.02, ent^.velocity, origin);
  gi.WriteByte (svc_temp_entity);
  if (ent^.waterlevel <> 0) then
  begin
    if (ent^.groundentity <> Nil) then
      gi.WriteByte (integer(TE_GRENADE_EXPLOSION_WATER))  
    else
      gi.WriteByte (integer(TE_ROCKET_EXPLOSION_WATER));  
  end
  else
  begin
    if (ent^.groundentity <> nil) then
      gi.WriteByte (integer(TE_GRENADE_EXPLOSION)) 
    else
      gi.WriteByte (integer(TE_ROCKET_EXPLOSION)); 
  end;
  gi.WritePosition (origin);
  gi.multicast (@ent^.s.origin, MULTICAST_PHS);

  G_FreeEdict (ent);
end;

procedure Grenade_Touch (ent, other : edict_p; plane : cplane_p; surf : csurface_p); cdecl;
begin
  if (other = ent^.owner) then
    Exit;

  if ((surf <> Nil) AND ((surf^.flags AND SURF_SKY) <> 0)) then
  begin
    G_FreeEdict (ent);
    Exit;
  end;

  if (other^.takedamage = DAMAGE_NO) then
  begin
    if ((ent^.spawnflags AND 1) <> 0) then
    begin
      if (_random() > 0.5) then
        gi.sound (ent, CHAN_VOICE, gi.soundindex ('weapons/hgrenb1a.wav'), 1, ATTN_NORM, 0)
      else
        gi.sound (ent, CHAN_VOICE, gi.soundindex ('weapons/hgrenb2a.wav'), 1, ATTN_NORM, 0)
    end else
      gi.sound (ent, CHAN_VOICE, gi.soundindex ('weapons/grenlb1b.wav'), 1, ATTN_NORM, 0);

    Exit;
  end;

  ent^.enemy := other;
  Grenade_Explode (ent);
end;

procedure fire_grenade (self : edict_p; const start, aimdir : vec3_t; damage, speed : integer; timer, damage_radius : Single);
var
  grenade : edict_p;
  dir,
  forward_, right, up : vec3_t;
begin
  vectoangles (aimdir, dir);
  AngleVectors (dir, @forward_, @right, @up);

  grenade := G_Spawn();
  VectorCopy (start, grenade^.s.origin);
  VectorScale (aimdir, speed, grenade^.velocity);
  VectorMA (grenade^.velocity, 200 + crandom() * 10.0, up, grenade^.velocity);
  VectorMA (grenade^.velocity, crandom() * 10.0, right, grenade^.velocity);
  VectorSet (grenade^.avelocity, 300, 300, 300);
  grenade^.movetype := MOVETYPE_BOUNCE;
  grenade^.clipmask := MASK_SHOT;
  grenade^.solid := SOLID_BBOX;
  grenade^.s.effects := grenade^.s.effects OR EF_GRENADE;
  VectorClear (grenade^.mins);
  VectorClear (grenade^.maxs);
  grenade^.s.modelindex := gi.modelindex ('models/objects/grenade/tris.md2');
  grenade^.owner := self;
  grenade^.touch := Grenade_Touch;
  grenade^.nextthink := level.time + timer;
  grenade^.think := Grenade_Explode;
  grenade^.dmg := damage;
  grenade^.dmg_radius := damage_radius;
  grenade^.classname := 'grenade';

  gi.linkentity (grenade);
end;

procedure fire_grenade2 (self : edict_p; const start, aimdir : vec3_t; damage, speed : integer; timer, damage_radius : Single; held : qboolean);
var
  grenade : edict_p;
  dir,
  forward_, right, up : vec3_t;
begin
  vectoangles (aimdir, dir);
  AngleVectors (dir, @forward_, @right, @up);

  grenade := G_Spawn();
  VectorCopy (start, grenade^.s.origin);
  VectorScale (aimdir, speed, grenade^.velocity);
  VectorMA (grenade^.velocity, 200 + crandom() * 10.0, up, grenade^.velocity);
  VectorMA (grenade^.velocity, crandom() * 10.0, right, grenade^.velocity);
  VectorSet (grenade^.avelocity, 300, 300, 300);
  grenade^.movetype := MOVETYPE_BOUNCE;
  grenade^.clipmask := MASK_SHOT;
  grenade^.solid := SOLID_BBOX;
  grenade^.s.effects := grenade^.s.effects OR EF_GRENADE;
  VectorClear (grenade^.mins);
  VectorClear (grenade^.maxs);
  grenade^.s.modelindex := gi.modelindex ('models/objects/grenade2/tris.md2');
  grenade^.owner := self;
  grenade^.touch := Grenade_Touch;
  grenade^.nextthink := level.time + timer;
  grenade^.think := Grenade_Explode;
  grenade^.dmg := damage;
  grenade^.dmg_radius := damage_radius;
  grenade^.classname := 'hgrenade';
  if (held) then
    grenade^.spawnflags := 3
  else
    grenade^.spawnflags := 1;
  grenade^.s.sound := gi.soundindex('weapons/hgrenc1b.wav');

  if (timer <= 0.0) then
    Grenade_Explode (grenade)
  else
  begin
    gi.sound (self, CHAN_WEAPON, gi.soundindex ('weapons/hgrent1a.wav'), 1, ATTN_NORM, 0);
    gi.linkentity (grenade);
  end;
end;

{*
=================
fire_rocket
=================
*}
procedure rocket_touch (ent, other : edict_p; plane : cplane_p; surf : csurface_p); cdecl;
var
  origin : vec3_t;
  n      : integer;
begin
  if (other = ent^.owner) then
    Exit;

  if ((surf <> Nil) AND ((surf^.flags AND SURF_SKY) <> 0)) then
  begin
    G_FreeEdict (ent);
    Exit;
  end;

  if (ent^.owner^.client <> Nil) then
    PlayerNoise (ent^.owner, ent^.s.origin, PNOISE_IMPACT);

  { Original Code Comment Below: }
  // calculate position for the explosion entity
  VectorMA (ent^.s.origin, -0.02, ent^.velocity, origin);

  if (other^.takedamage <> DAMAGE_NO) then  
    T_Damage (other, ent, ent^.owner, ent^.velocity, ent^.s.origin, plane^.normal, ent^.dmg, 0, 0, MOD_ROCKET)
  else
  begin
    { Original Code Comment Below: }
    // don't throw any debris in net games
    if (deathmatch^.value = 0) AND (coop^.value = 0) then
    begin
      if ((surf <> Nil) AND (surf^.flags AND (SURF_WARP OR SURF_TRANS33 OR SURF_TRANS66 OR SURF_FLOWING) = 0)) then
      begin
        n := rand() mod 5;

        while (n <> 0) do
          try
            ThrowDebris (ent, 'models/objects/debris2/tris.md2', 2, ent^.s.origin);
          finally
            Dec(n);
          end;
      end;
    end;
  end;

  T_RadiusDamage (ent, ent^.owner, ent^.radius_dmg, other, ent^.dmg_radius, MOD_R_SPLASH);

  gi.WriteByte (svc_temp_entity);
  if (ent^.waterlevel <> 0) then
    gi.WriteByte (integer(TE_ROCKET_EXPLOSION_WATER)) 
  else
    gi.WriteByte (integer(TE_ROCKET_EXPLOSION));  
  gi.WritePosition (origin);
  gi.multicast (@ent^.s.origin, MULTICAST_PHS);

  G_FreeEdict (ent);
end;

procedure fire_rocket (self : edict_p; const start, dir : vec3_t; damage, speed : integer; damage_radius : Single; radius_damage: Integer);
var
  rocket : edict_p;
begin
  rocket := G_Spawn();
  VectorCopy (start, rocket^.s.origin);
  VectorCopy (dir, rocket^.movedir);
  vectoangles (dir, rocket^.s.angles);
  VectorScale (dir, speed, rocket^.velocity);
  rocket^.movetype := MOVETYPE_FLYMISSILE;
  rocket^.clipmask := MASK_SHOT;
  rocket^.solid := SOLID_BBOX;
  rocket^.s.effects := rocket^.s.effects OR EF_ROCKET;
  VectorClear (rocket^.mins);
  VectorClear (rocket^.maxs);
  rocket^.s.modelindex := gi.modelindex ('models/objects/rocket/tris.md2');
  rocket^.owner := self;
  rocket^.touch := rocket_touch;
  rocket^.nextthink := level.time + 8000/speed;
  rocket^.think := G_FreeEdict;
  rocket^.dmg := damage;
  rocket^.radius_dmg := radius_damage;
  rocket^.dmg_radius := damage_radius;
  rocket^.s.sound := gi.soundindex ('weapons/rockfly.wav');
  rocket^.classname := 'rocket';

  if (self^.client <> Nil) then
    check_dodge (self, rocket^.s.origin, dir, speed);

  gi.linkentity (rocket);
end;

{*
=================
fire_rail
=================
*}
procedure fire_rail (self : edict_p; var start, aimdir : vec3_t; damage, kick : integer);
var
  from,
  end_   : vec3_t;
  tr     : trace_t;
  ignore : edict_p;
  mask   : integer;
  water  : qboolean;
begin
  VectorMA (start, 8192, aimdir, end_);
  VectorCopy (start, from);
  ignore := self;
  water := false;
  mask := MASK_SHOT or CONTENTS_SLIME OR CONTENTS_LAVA;
  while (ignore <> Nil) do
  begin
    tr := gi.trace (@from, Nil, Nil, @end_, ignore, mask);

    if ( (tr.contents AND (CONTENTS_SLIME OR CONTENTS_LAVA)) <> 0 ) then
    begin
      mask := mask AND (NOT (CONTENTS_SLIME OR CONTENTS_LAVA));
      water := true;
    end
    else
    begin
      { Original Code Comment Below: }
      //ZOID--added so rail goes through SOLID_BBOX entities (gibs, etc)
      if ( ((edict_p(tr.ent)^.svflags AND SVF_MONSTER) <> 0) OR (edict_p(tr.ent)^.client <> Nil) OR (edict_p(tr.ent)^.solid = SOLID_BBOX)) then
        ignore := tr.ent
      else
        ignore := Nil;

      if ((tr.ent <> self) AND (edict_p(tr.ent)^.takedamage <> DAMAGE_NO)) then   
        T_Damage (tr.ent, self, self, aimdir, tr.endpos, tr.plane.normal, damage, kick, 0, MOD_RAILGUN);
    end;

    VectorCopy (tr.endpos, from);
  end;

  { Original Code Comment Below: }
  // send gun puff / flash
  gi.WriteByte (svc_temp_entity);
  gi.WriteByte (integer(TE_RAILTRAIL));  
  gi.WritePosition (start);
  gi.WritePosition (tr.endpos);
  gi.multicast (@self^.s.origin, MULTICAST_PHS);
{ Original Code Comment Below: }
//  gi.multicast (start, MULTICAST_PHS);
  if (water) then
  begin
    gi.WriteByte (svc_temp_entity);
    gi.WriteByte (integer(TE_RAILTRAIL));  
    gi.WritePosition (start);
    gi.WritePosition (tr.endpos);
    gi.multicast (@tr.endpos, MULTICAST_PHS);
  end;

  if (self.client <> Nil) then
    PlayerNoise (self, tr.endpos, PNOISE_IMPACT);
end;

{*
=================
fire_bfg
=================
*}

procedure bfg_explode (self : edict_p); cdecl;
var
  ent    : edict_p;
  v      : vec3_t;
  points,
  dist   : Single;
label __Continue;
begin
  if (self^.s.frame = 0) then
  begin
    { Original Code Comment Below: }
    // the BFG effect
    ent := Nil; 
    ent := findradius(ent, self^.s.origin, self^.dmg_radius);
    while (ent <> Nil) do
    begin
      if (ent^.takedamage = DAMAGE_NO) then
        goto __Continue;
      if (ent = self^.owner) then
        goto __Continue;
      if (NOT CanDamage(ent, self)) then
        goto __Continue;
      if (NOT CanDamage(ent, self^.owner)) then
        goto __Continue;

      VectorAdd (ent^.mins, ent^.maxs, v);
      VectorMA (ent^.s.origin, 0.5, v, v);
      VectorSubtract (self^.s.origin, v, v);
      dist := VectorLength(v);
      points := self^.radius_dmg * (1.0 - sqrt(dist/self^.dmg_radius));
      if (ent = self^.owner) then
        points := points * 0.5;

      gi.WriteByte (svc_temp_entity);
      gi.WriteByte (integer(TE_BFG_EXPLOSION));
      gi.WritePosition (ent^.s.origin);
      gi.multicast (@ent^.s.origin, MULTICAST_PHS);
      T_Damage (ent, self, self^.owner, self^.velocity, ent^.s.origin, vec3_origin, trunc(points), 0, DAMAGE_ENERGY, MOD_BFG_EFFECT);

    __Continue:
      ent := findradius(ent, self^.s.origin, self^.dmg_radius);
    end;
  end;

  self^.nextthink := level.time + FRAMETIME;
  Inc(self^.s.frame);
  if (self^.s.frame = 5) then
    self^.think := G_FreeEdict;
end;

procedure bfg_touch (self, other : edict_p; plane : cplane_p; surf : csurface_p); cdecl;
begin
  if (other = self^.owner) then
    Exit;

  if (surf <> Nil) AND ((surf^.flags AND SURF_SKY) <> 0) then
  begin
    G_FreeEdict (self);
    Exit;
  end;

  if (self^.owner^.client <> Nil) then
    PlayerNoise (self^.owner, self^.s.origin, PNOISE_IMPACT);


  // core explosion - prevents firing it into the wall/floor

  if (other^.takedamage <> DAMAGE_NO) then 
    T_Damage (other, self, self^.owner, self^.velocity, self^.s.origin, plane^.normal, 200, 0, 0, MOD_BFG_BLAST);
  T_RadiusDamage(self, self^.owner, 200, other, 100, MOD_BFG_BLAST);

  gi.sound (self, CHAN_VOICE, gi.soundindex ('weapons/bfg__x1b.wav'), 1, ATTN_NORM, 0);
  self^.solid := SOLID_NOT;
  self^.touch := Nil;
  VectorMA (self^.s.origin, -1 * FRAMETIME, self^.velocity, self^.s.origin);
  VectorClear (self^.velocity);
  self^.s.modelindex := gi.modelindex ('sprites/s_bfg3.sp2');
  self^.s.frame := 0;
  self^.s.sound := 0;
  self^.s.effects := self^.s.effects AND (NOT EF_ANIM_ALLFAST);
  self^.think := bfg_explode;
  self^.nextthink := level.time + FRAMETIME;
  self^.enemy := other;

  gi.WriteByte (svc_temp_entity);
  gi.WriteByte (integer(TE_BFG_BIGEXPLOSION)); 
  gi.WritePosition (self^.s.origin);
  gi.multicast (@self^.s.origin, MULTICAST_PVS);
end;

procedure bfg_think (self : edict_p); cdecl;
var
  ent,
  ignore : edict_p;
  point,
  dir,
  start,
  end_   : vec3_t;
  dmg    : integer;
  tr     : trace_t;
label __Continue;
begin
  if (deathmatch^.value <> 0) then
    dmg := 5
  else
    dmg := 10;

  ent := nil;
  ent := findradius(ent, self^.s.origin, 256);
  while (ent <> Nil) do
  begin
    if (ent = self) then
      goto __Continue;

    if (ent = self^.owner) then
      goto __Continue;

    if (ent^.takedamage = DAMAGE_NO) then
      goto __Continue;

    if ( ((ent^.svflags AND SVF_MONSTER) = 0) AND
         (ent^.client = Nil) AND
         (strcmp(ent^.classname, 'misc_explobox') <> 0) ) then
      goto __Continue;

    VectorMA (ent^.absmin, 0.5, ent^.size, point);

    VectorSubtract (point, self^.s.origin, dir);
    VectorNormalize (dir);

    ignore := self;
    VectorCopy (self^.s.origin, start);
    VectorMA (start, 2048, dir, end_);
    while True do
    begin
      tr := gi.trace (@start, Nil, Nil, @end_, ignore, CONTENTS_SOLID or CONTENTS_MONSTER or CONTENTS_DEADMONSTER);

      if (tr.ent = Nil) then
        Break;

      // hurt it if we can
      if ( (edict_p(tr.ent)^.takedamage <> DAMAGE_NO) AND
           ((edict_p(tr.ent)^.flags AND FL_IMMUNE_LASER) = 0) AND
           (tr.ent <> self^.owner) ) then
        T_Damage (tr.ent, self, self^.owner, dir, tr.endpos, vec3_origin, dmg, 1, DAMAGE_ENERGY, MOD_BFG_LASER);

      // if we hit something that's not a monster or player we're done
      if ( ((edict_p(tr.ent)^.svflags AND SVF_MONSTER) = 0) AND (edict_p(tr.ent)^.client = Nil) ) then
      begin
        gi.WriteByte (svc_temp_entity);
        gi.WriteByte (integer(TE_LASER_SPARKS));
        gi.WriteByte (4);
        gi.WritePosition (tr.endpos);
        gi.WriteDir (tr.plane.normal);
        gi.WriteByte (self^.s.skinnum);
        gi.multicast (@tr.endpos, MULTICAST_PVS);
        Break;
      end;

      ignore := tr.ent;
      VectorCopy (tr.endpos, start);
    end;
    gi.WriteByte (svc_temp_entity);
    gi.WriteByte (integer(TE_BFG_LASER));
    gi.WritePosition (self^.s.origin);
    gi.WritePosition (tr.endpos);
    gi.multicast (@self^.s.origin, MULTICAST_PHS);
    
  __Continue:
    ent := findradius(ent, self^.s.origin, 256);
  end;

  self^.nextthink := level.time + FRAMETIME;
end;

procedure fire_bfg (self : edict_p; const start, dir : vec3_t; damage, speed : integer; damage_radius : Single);
var
  bfg : edict_p;
begin
  bfg := G_Spawn();
  VectorCopy (start, bfg^.s.origin);
  VectorCopy (dir, bfg^.movedir);
  vectoangles (dir, bfg^.s.angles);
  VectorScale (dir, speed, bfg^.velocity);
  bfg^.movetype := MOVETYPE_FLYMISSILE;
  bfg^.clipmask := MASK_SHOT;
  bfg^.solid := SOLID_BBOX;
  bfg^.s.effects := bfg^.s.effects OR EF_BFG OR EF_ANIM_ALLFAST;
  VectorClear (bfg^.mins);
  VectorClear (bfg^.maxs);
  bfg^.s.modelindex := gi.modelindex ('sprites/s_bfg1.sp2');
  bfg^.owner := self;
  bfg^.touch := bfg_touch;
  bfg^.nextthink := level.time + 8000/speed;
  bfg^.think := G_FreeEdict;
  bfg^.radius_dmg := damage;
  bfg^.dmg_radius := damage_radius;
  bfg^.classname := 'bfg blast';
  bfg^.s.sound := gi.soundindex ('weapons/bfg__l1a.wav');

  bfg^.think := bfg_think;
  bfg^.nextthink := level.time + FRAMETIME;
  bfg^.teammaster := bfg;
  bfg^.teamchain := Nil;

  if (self^.client <> Nil) then
    check_dodge (self, bfg^.s.origin, dir, speed);

  gi.linkentity (bfg);
end;

end.
