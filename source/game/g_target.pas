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
{ File(s): g_target.pas                                                      }
{                                                                            }
{ Initial conversion by : Jose M. Navarro (jose.man@airtel.net)              }
{ Initial conversion on : 10-Jul-2002                                        }
{                                                                            }
{ NOTE: This file (Game\g_target.pas) is compatible with same name file in   } 
{ CTF directory (CTF\g_target.pas)                                           } 
{                                                                            }
{ This File contains part of convertion of Quake2 source to ObjectPascal.    }
{ More information about this project can be found at:                       }
{ http://www.sulaco.co.za/quake2/                                            }
{                                                                            }
{ Copyright (C) 1997-2001 Id Software, Inc.                                  }
{                                                                            }
{ This program is free software; you can redistribute it and/or              }
{ modify it under the terms of the GNU General Public License                }
{ as puC:\Documents and Settings\PCDELPHI4.PC-DELPHI4\Escritorio\g_target.c
blished by the Free Software Foundation; either version 2             }
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
unit g_target;

interface

uses
  g_local,
  GameUnit,
  q_shared;

{$Include ..\JEDI.inc}

//==========================================================
procedure Use_Target_Tent(ent: edict_p; other: edict_p; activator: edict_p); cdecl;
procedure SP_target_temp_entity(ent: edict_p); cdecl;

//==========================================================
// QUAKED target_speaker
procedure Use_Target_Speaker(ent: edict_p; other: edict_p; activator: edict_p); cdecl;
procedure SP_target_speaker(ent: edict_p); cdecl;

//==========================================================
// QUAKED target_help
procedure Use_Target_Help(ent: edict_p; other: edict_p; activator: edict_p); cdecl;
procedure SP_target_help(ent: edict_p); cdecl;

//==========================================================
// QUAKED target_secret
procedure use_target_secret(ent: edict_p; other: edict_p; activator: edict_p); cdecl;
procedure SP_target_secret(ent: edict_p); cdecl;

//==========================================================
// QUAKED target_goal
procedure use_target_goal(ent: edict_p; other: edict_p; activator: edict_p); cdecl;
procedure SP_target_goal(ent: edict_p); cdecl;

//==========================================================
// QUAKED target_explosion
procedure target_explosion_explode(self: edict_p); cdecl;
procedure use_target_explosion(self: edict_p; other: edict_p; activator: edict_p); cdecl;
procedure SP_target_explosion(ent: edict_p); cdecl;


//==========================================================
// QUAKED target_changelevel
procedure use_target_changelevel(self: edict_p; other: edict_p; activator: edict_p); cdecl;
procedure SP_target_changelevel(ent: edict_p); cdecl;

//==========================================================
// QUAKED target_splash
procedure use_target_splash(self: edict_p; other: edict_p; activator: edict_p); cdecl;
procedure SP_target_splash(self: edict_p); cdecl;

//==========================================================
// QUAKED target_spawner
procedure use_target_spawner(self: edict_p; other: edict_p; activator: edict_p); cdecl;
procedure SP_target_spawner(self: edict_p); cdecl;

//==========================================================
// QUAKED target_blaster
procedure use_target_blaster(self: edict_p; other: edict_p; activator: edict_p); cdecl;
procedure SP_target_blaster(self: edict_p); cdecl;

//==========================================================
// QUAKED target_crosslevel_trigger
procedure trigger_crosslevel_trigger_use(self: edict_p; other: edict_p; activator: edict_p); cdecl;
procedure SP_target_crosslevel_trigger(self: edict_p); cdecl;

//==========================================================
// QUAKED target_crosslevel_target
procedure target_crosslevel_target_think(self: edict_p); cdecl;
procedure SP_target_crosslevel_target(self: edict_p); cdecl;

//==========================================================
// QUAKED target_laser
procedure target_laser_think(self: edict_p); cdecl;
procedure target_laser_on(self: edict_p); cdecl;
procedure target_laser_off(self: edict_p); cdecl;
procedure target_laser_use(self: edict_p; other: edict_p; activator: edict_p); cdecl;
procedure target_laser_start(self: edict_p); cdecl;
procedure SP_target_laser(self: edict_p); cdecl;

//==========================================================
// QUAKED target_lightramp
procedure target_lightramp_think(self: edict_p); cdecl;
procedure target_lightramp_use(self: edict_p; other: edict_p; activator: edict_p); cdecl;
procedure SP_target_lightramp(self: edict_p); cdecl;

//==========================================================
// QUAKED target_earthquake
procedure target_earthquake_think(self: edict_p); cdecl;
procedure target_earthquake_use(self: edict_p; other: edict_p; activator: edict_p); cdecl;
procedure SP_target_earthquake(self: edict_p); cdecl;

implementation

uses
  SysUtils,
  g_utils,
  g_combat,
  p_hud,
  p_weapon,
  g_save,
  q_shared_add,
  g_main,
  g_weapon,
  g_local_add,
  game_add, CPas, g_spawn;

//==========================================================
{QUAKED target_temp_entity (1 0 0) (-8 -8 -8) (8 8 8)
Fire an origin based temp entity event to the clients.
"style"      type byte
}
procedure Use_Target_Tent(ent: edict_p; other: edict_p; activator: edict_p);
begin
  gi.WriteByte(svc_temp_entity);
  gi.WriteByte(ent^.style);
  gi.WritePosition(ent^.s.origin);
  gi.multicast(@ent^.s.origin, MULTICAST_PVS);
end;

procedure SP_target_temp_entity(ent: edict_p);
begin
  ent^.use := Use_Target_Tent;
end;


//==========================================================
{ QUAKED target_speaker (1 0 0) (-8 -8 -8) (8 8 8) looped-on looped-off reliable
"noise"      wav file to play
"attenuation"
-1 = none, send to whole level
1 = normal fighting sounds
2 = idle sound level
3 = ambient sound level
"volume"   0.0 to 1.0

Normal sounds play each time the target is used.  The reliable flag can be set for crucial voiceovers.

Looped sounds are allways atten 3 / vol 1, and the use function toggles it on/off.
Multiple identical looping sounds will just increase volume without any speed cost.
}
procedure Use_Target_Speaker(ent: edict_p; other: edict_p; activator: edict_p);
var
  chan: integer;
begin
  if (ent^.spawnflags and 3) <> 0 then
  begin  // looping sound toggles
    if ent^.s.sound <> 0 then
      ent^.s.sound := 0   // turn it off
    else
      ent^.s.sound := ent^.noise_index;   // start it
  end
  else
  begin  // normal sound
    if (ent^.spawnflags and 4) <> 0 then
      chan := CHAN_VOICE or CHAN_RELIABLE
    else
      chan := CHAN_VOICE;
    // use a positioned_sound, because this entity won't normally be
    // sent to any clients because it is invisible
    gi.positioned_sound(@ent^.s.origin, ent, chan, ent^.noise_index, ent^.volume, ent^.attenuation, 0);
  end;
end;

procedure SP_target_speaker(ent: edict_p); cdecl;
var
  buffer: array[0..MAX_QPATH-1] of char;
begin
  if st.noise = nil then
  begin
    gi.dprintf('target_speaker with no noise set at %s'#10, vtos(ent^.s.origin));
    exit;
  end;
  if strstr(st.noise, '.wav') = nil then
    Com_sprintf(buffer, sizeof(buffer), '%s.wav', [st.noise])
  else
    strncpy(buffer, st.noise, sizeof(buffer));
  ent^.noise_index := gi.soundindex(buffer);

  if ent^.volume = 0 then
    ent^.volume := 1.0;

  if ent^.attenuation = 0 then
    ent^.attenuation := 1.0
  else if ent^.attenuation = -1 then   // use -1 so 0 defaults to 1
    ent^.attenuation := 0;

  // check for prestarted looping sound
  if (ent^.spawnflags and 1) <> 0 then
    ent^.s.sound := ent^.noise_index;

  ent^.use := Use_Target_Speaker;

  // must link the entity so we get areas and clusters so
  // the server can determine who to send updates to
  gi.linkentity(ent);
end;


//==========================================================
{ QUAKED target_help (1 0 1) (-16 -16 -24) (16 16 24) help1
When fired, the "message" key becomes the current personal computer string, and the message light will be set on all clients status bars.
}
procedure Use_Target_Help(ent: edict_p; other: edict_p; activator: edict_p);
begin
  if (ent^.spawnflags and 1) <> 0 then
    strncpy(game.helpmessage1, ent^._message, sizeof(game.helpmessage2) - 1)
  else
    strncpy(game.helpmessage2, ent^._message, sizeof(game.helpmessage1) - 1);

  Inc(game.helpchanged);
end;

procedure SP_target_help(ent: edict_p);
begin
  if deathmatch^.Value <> 0 then
  begin  // auto-remove for deathmatch
    G_FreeEdict(ent);
    exit;
  end;

  if ent^._message = nil then
  begin
    gi.dprintf('%s with no message at %s'#10, ent^.classname, vtos(ent^.s.origin));
    G_FreeEdict(ent);
    exit;
  end;
  ent^.use := Use_Target_Help;
end;


//==========================================================
{ QUAKED target_secret (1 0 1) (-8 -8 -8) (8 8 8)
Counts a secret found.
These are single use targets.
}
procedure use_target_secret(ent: edict_p; other: edict_p; activator: edict_p);
begin
  gi.sound(ent, CHAN_VOICE, ent^.noise_index, 1, ATTN_NORM, 0);

  Inc(level.found_secrets);

  G_UseTargets(ent, activator);
  G_FreeEdict(ent);
end;

procedure SP_target_secret(ent: edict_p);
begin
  if deathmatch^.Value <> 0 then
  begin   // auto-remove for deathmatch
    G_FreeEdict(ent);
    exit;
  end;

  ent^.use := use_target_secret;
  if st.noise = nil then
    st.noise := 'misc/secret.wav';
  ent^.noise_index := gi.soundindex(st.noise);
  ent^.svflags := SVF_NOCLIENT;
  Inc(level.total_secrets);
  // map bug hack
  if (Q_stricmp(level.mapname, 'mine3') = 0) and (ent^.s.origin[0] = 280) and
     (ent^.s.origin[1] = -2048) and (ent^.s.origin[2] = -624) then
  begin
    ent^._message := 'You have found a secret area.';
  end;
end;

//==========================================================

{QUAKED target_goal (1 0 1) (-8 -8 -8) (8 8 8)
Counts a goal completed.
These are single use targets.
}
procedure use_target_goal(ent: edict_p; other: edict_p; activator: edict_p);
begin
  gi.sound(ent, CHAN_VOICE, ent^.noise_index, 1, ATTN_NORM, 0);

  Inc(level.found_goals);

  if level.found_goals = level.total_goals then
    gi.configstring(CS_CDTRACK, '0');

  G_UseTargets(ent, activator);
  G_FreeEdict(ent);
end;

procedure SP_target_goal(ent: edict_p);
begin
  if deathmatch^.Value <> 0 then
  begin   // auto-remove for deathmatch
    G_FreeEdict(ent);
    exit;
  end;

  ent^.use := use_target_goal;
  if st.noise = nil then
    st.noise := 'misc/secret.wav';
  ent^.noise_index := gi.soundindex(st.noise);
  ent^.svflags := SVF_NOCLIENT;
  Inc(level.total_goals);
end;

//==========================================================

{ QUAKED target_explosion (1 0 0) (-8 -8 -8) (8 8 8)
Spawns an explosion temporary entity when used.

"delay"      wait this long before going off
"dmg"      how much radius damage should be done, defaults to 0
}
procedure target_explosion_explode(self: edict_p);
var
  save: Single;
begin
  gi.WriteByte(svc_temp_entity);
  gi.WriteByte(Integer(TE_EXPLOSION1)); // cast from temp_event_t to Integer must be done
  gi.WritePosition(self^.s.origin);
  gi.multicast(@self^.s.origin, MULTICAST_PHS);

  T_RadiusDamage(self, self^.activator, self^.dmg, nil, self^.dmg + 40, MOD_EXPLOSIVE);

  save := self^.delay;
  self^.delay := 0;
  G_UseTargets(self, self^.activator);
  self^.delay := save;
end;

procedure use_target_explosion(self: edict_p; other: edict_p; activator: edict_p);
begin
  self^.activator := activator;

  if self^.delay = 0 then
  begin
    target_explosion_explode(self);
    exit;
  end;

  self^.think := target_explosion_explode;
  self^.nextthink := level.time + self^.delay;
end;

procedure SP_target_explosion(ent: edict_p);
begin
  ent^.use := use_target_explosion;
  ent^.svflags := SVF_NOCLIENT;
end;


//==========================================================

{ QUAKED target_changelevel (1 0 0) (-8 -8 -8) (8 8 8)
Changes level to "map" when fired
}
procedure use_target_changelevel(self: edict_p; other: edict_p; activator: edict_p);
begin
  if level.intermissiontime <> 0 then
    exit;      // already activated

  if (deathmatch^.Value = 0) and (coop^.Value =0) then
  begin
    if g_edicts[1].health <= 0 then
      exit;
  end;

  // if noexit, do a ton of damage to other
  if (deathmatch^.value <> 0) and not ((trunc(dmflags^.value) and DF_ALLOW_EXIT) <> 0) and (other <> world) then
  begin
    T_Damage(other, self, self, vec3_origin, other^.s.origin, vec3_origin, 10 * other^.max_health, 1000, 0, MOD_EXIT);
    exit;
  end;

  // if multiplayer, let everyone know who hit the exit
  if deathmatch^.Value <> 0 then
  begin
    // cast to interger must be done for mask operation
    if (Integer(activator) and Integer(activator^.client)) <> 0 then
     gi.bprintf(PRINT_HIGH, '%s exited the level.'#10, activator^.client^.pers.netname);
  end;

  // if going to a new unit, clear cross triggers
  if strstr(self^.map, '*') <> nil then
    game.serverflags := game.serverflags and not SFL_CROSS_TRIGGER_MASK;

  BeginIntermission(self);
end;

procedure SP_target_changelevel(ent: edict_p);
begin
  if ent^.map = nil then
  begin
    gi.dprintf('target_changelevel with no map at %s'#10, vtos(ent^.s.origin));
    G_FreeEdict(ent);
    exit;
  end;

  // ugly hack because *SOMEBODY* screwed up their map
  if (Q_stricmp(level.mapname, 'fact1') = 0) and (Q_stricmp(ent^.map, 'fact3') = 0) then
    ent^.map := 'fact3$secret1';

  ent^.use     := use_target_changelevel;
  ent^.svflags := SVF_NOCLIENT;
end;


//==========================================================
{ QUAKED target_splash (1 0 0) (-8 -8 -8) (8 8 8)
Creates a particle splash effect when used.

Set "sounds" to one of the following:
  1) sparks
  2) blue water
  3) brown water
  4) slime
  5) lava
  6) blood

"count"   how many pixels in the splash
"dmg"   if set, does a radius damage at this location when it splashes
      useful for lava/sparks
}
procedure use_target_splash(self: edict_p; other: edict_p; activator: edict_p);
begin
  gi.WriteByte(svc_temp_entity);
  gi.WriteByte(Integer(TE_SPLASH));
  gi.WriteByte(self^.count);
  gi.WritePosition(self^.s.origin);
  gi.WriteDir(self^.movedir);
  gi.WriteByte(self^.sounds);
  gi.multicast(@self^.s.origin, MULTICAST_PVS);

  if self^.dmg <> 0 then
    T_RadiusDamage(self, activator, self^.dmg, nil, self^.dmg + 40, MOD_SPLASH);
end;

procedure SP_target_splash(self: edict_p);
begin
  self^.use := use_target_splash;
  G_SetMovedir(self^.s.angles, self^.movedir);

  if self^.count = 0 then
    self^.count := 32;

  self^.svflags := SVF_NOCLIENT;
end;


//==========================================================
{ QUAKED target_spawner (1 0 0) (-8 -8 -8) (8 8 8)
Set target to the type of entity you want spawned.
Useful for spawning monsters and gibs in the factory levels.

For monsters:
   Set direction to the facing you want it to have.

For gibs:
   Set direction if you want it moving and
   speed how fast it should be moving otherwise it
   will just be dropped
}

procedure use_target_spawner(self: edict_p; other: edict_p; activator: edict_p);
var
  ent: edict_p;
begin
  ent := g_utils.G_Spawn;
  ent^.classname := self^.target;
  VectorCopy(self^.s.origin, ent^.s.origin);
  VectorCopy(self^.s.angles, ent^.s.angles);
  ED_CallSpawn(ent);
  gi.unlinkentity(ent);
  KillBox(ent);
  gi.linkentity(ent);
  if self^.speed <> 0 then
    VectorCopy(self^.movedir, ent^.velocity);
end;

procedure SP_target_spawner(self: edict_p);
begin
  self^.use := use_target_spawner;
  self^.svflags := SVF_NOCLIENT;
  if self^.speed <> 0 then
  begin
    G_SetMovedir(self^.s.angles, self^.movedir);
    VectorScale(self^.movedir, self^.speed, self^.movedir);
  end;
end;


//==========================================================
{ QUAKED target_blaster (1 0 0) (-8 -8 -8) (8 8 8) NOTRAIL NOEFFECTS
Fires a blaster bolt in the set direction when triggered.

dmg      default is 15
speed   default is 1000
}
procedure use_target_blaster(self: edict_p; other: edict_p; activator: edict_p);
var
  effect: integer;
begin
  if (self^.spawnflags and 2) <> 0 then
    effect := 0
  else if (self^.spawnflags and 1) <> 0 then
    effect := EF_HYPERBLASTER
  else
    effect := EF_BLASTER;

  // WARNING in this call. Some types could be wrong
  fire_blaster(self, self^.s.origin, self^.movedir, self^.dmg, trunc(self^.speed), EF_BLASTER, qboolean(MOD_TARGET_BLASTER));
  gi.sound(self, CHAN_VOICE, self^.noise_index, 1, ATTN_NORM, 0);
end;

procedure SP_target_blaster(self: edict_p);
begin
  self^.use := use_target_blaster;
  G_SetMovedir(self^.s.angles, self^.movedir);
  self^.noise_index := gi.soundindex('weapons/laser2.wav');

  if self^.dmg = 0 then
    self^.dmg := 15
  else if self^.speed = 0 then
    self^.speed := 1000;

  self^.svflags := SVF_NOCLIENT;
end;


//==========================================================
{QUAKED target_crosslevel_trigger (.5 .5 .5) (-8 -8 -8) (8 8 8) trigger1 trigger2 trigger3 trigger4 trigger5 trigger6 trigger7 trigger8
Once this trigger is touched/used, any trigger_crosslevel_target with the same trigger number is automatically used when a level is started within the same unit.  It is OK to check multiple triggers.  Message, delay, target, and killtarget also work.
}
procedure trigger_crosslevel_trigger_use(self: edict_p; other: edict_p; activator: edict_p);
begin
  game.serverflags := game.serverflags or self^.spawnflags;
  G_FreeEdict(self);
end;

procedure SP_target_crosslevel_trigger(self: edict_p);
begin
  self^.svflags := SVF_NOCLIENT;
  self^.use    := trigger_crosslevel_trigger_use;
end;

{ QUAKED target_crosslevel_target (.5 .5 .5) (-8 -8 -8) (8 8 8) trigger1 trigger2 trigger3 trigger4 trigger5 trigger6 trigger7 trigger8
Triggered by a trigger_crosslevel elsewhere within a unit.  If multiple triggers are checked, all must be true.  Delay, target and
killtarget also work.

"delay"      delay before using targets if the trigger has been activated (default 1)
}
procedure target_crosslevel_target_think(self: edict_p);
begin
  if self^.spawnflags = (game.serverflags and SFL_CROSS_TRIGGER_MASK and self^.spawnflags) then
  begin
    G_UseTargets(self, self);
   G_FreeEdict(self);
  end;
end;

procedure SP_target_crosslevel_target(self: edict_p);
begin
  if self^.delay = 0 then
    self^.delay := 1;
  self^.svflags := SVF_NOCLIENT;

  self^.think := target_crosslevel_target_think;
  self^.nextthink := level.time + self^.delay;
end;


//==========================================================
{ QUAKED target_laser (0 .5 .8) (-8 -8 -8) (8 8 8) START_ON RED GREEN BLUE YELLOW ORANGE FAT
When triggered, fires a laser.  You can either set a target
or a direction.
}
procedure target_laser_think (self: edict_p);
var
  ignore:       edict_p;
  start:        vec3_t;
  EndVar:   vec3_t; // original variable name: end
  tr:         trace_t;
  point:        vec3_t;
  last_movedir: vec3_t;
  count:        integer;
begin
  if (self^.spawnflags and $80000000) <> 0 then
    count := 8
  else
    count := 4;

  if self^.enemy <> nil then
  begin
    VectorCopy(self^.movedir, last_movedir);
    VectorMA(self^.enemy^.absmin, 0.5, self^.enemy^.size, point);
    VectorSubtract(point, self^.s.origin, self^.movedir);
    VectorNormalize(self^.movedir);
    if VectorCompare(self^.movedir, last_movedir) = 0 then
      self^.spawnflags := self^.spawnflags or $80000000;
  end;

  ignore := self;
  VectorCopy(self^.s.origin, start);
  VectorMA(start, 2048, self^.movedir, EndVar);
  while true do
  begin
    tr := gi.trace(@start, nil, nil, @EndVar, ignore, CONTENTS_SOLID or CONTENTS_MONSTER or CONTENTS_DEADMONSTER);

    if tr.ent = nil then
      break;

    // hurt it if we can
    if (edict_p(tr.ent)^.takedamage <> DAMAGE_NO) and ((edict_p(tr.ent)^.flags and FL_IMMUNE_LASER) = 0) then
      T_Damage(tr.ent, self, self^.activator, self^.movedir, tr.endpos, vec3_origin, self^.dmg, 1, DAMAGE_ENERGY, MOD_TARGET_LASER);

    // if we hit something that's not a monster or player or is immune to lasers, we're done
    if ((edict_p(tr.ent)^.svflags and SVF_MONSTER) = 0) and (edict_p(tr.ent)^.client = nil) then
    begin
      if (self^.spawnflags and $80000000) <> 0 then
      begin
        self^.spawnflags := self^.spawnflags and not $80000000;
        gi.WriteByte(svc_temp_entity);
        gi.WriteByte(Integer(TE_LASER_SPARKS)); // cast to Integer done
        gi.WriteByte(count);
        gi.WritePosition(tr.endpos);
        gi.WriteDir(tr.plane.normal);
        gi.WriteByte(self^.s.skinnum);
        gi.multicast(@tr.endpos, MULTICAST_PVS);
      end;
      break;
    end;

    ignore := tr.ent;
    VectorCopy(tr.endpos, start);
  end;

  VectorCopy(tr.endpos, self^.s.old_origin);

  self^.nextthink := level.time + FRAMETIME;
end;

procedure target_laser_on(self: edict_p);
begin
  if self^.activator = nil then
    self^.activator := self;

  self^.spawnflags := self^.spawnflags or $80000001;
  self^.svflags    := self^.svflags and not SVF_NOCLIENT;
  target_laser_think(self);
end;

procedure target_laser_off(self: edict_p);
begin
  self^.spawnflags := self^.spawnflags and not 1;
  self^.svflags    := self^.svflags or SVF_NOCLIENT;
  self^.nextthink  := 0;
end;

procedure target_laser_use(self: edict_p; other: edict_p; activator: edict_p);
begin
  self^.activator := activator;
  if (self^.spawnflags and 1) <> 0 then
    target_laser_off(self)
  else
    target_laser_on(self);
end;

procedure target_laser_start(self: edict_p);
var
  ent: edict_p;
begin
  self^.movetype     := MOVETYPE_NONE;
  self^.solid         := SOLID_NOT;
  self^.s.renderfx   := self^.s.renderfx or (RF_BEAM and RF_TRANSLUCENT);
  self^.s.modelindex := 1;         // must be non-zero

  // set the beam diameter
  if (self^.spawnflags and 64) <> 0 then
    self^.s.frame := 16
  else
    self^.s.frame := 4;

  // set the color
  if (self^.spawnflags and 2) <> 0 then
    self^.s.skinnum := $f2f2f0f0
  else if (self^.spawnflags and 4) <> 0 then
    self^.s.skinnum := $d0d1d2d3
  else if (self^.spawnflags and 8) <> 0 then
    self^.s.skinnum := $f3f3f1f1
  else if (self^.spawnflags and 16) <> 0 then
    self^.s.skinnum := $dcdddedf
  else if (self^.spawnflags and 32) <> 0 then
    self^.s.skinnum := $e0e1e2e3;

  if self^.enemy = nil then
  begin
    if self^.target <> nil then
    begin
      ent := G_Find(nil, FOFS_targetname, self^.target);
      if ent = nil then
        gi.dprintf('%s at %s: %s is a bad target'#10, self^.classname, vtos(self^.s.origin), self^.target);
      self^.enemy := ent;
    end
    else
    begin
      G_SetMovedir(self^.s.angles, self^.movedir);
    end;
  end;
  self^.use   := target_laser_use;
  self^.think := target_laser_think;

  if self^.dmg = 0 then
    self^.dmg := 1;

  VectorSet(self^.mins, -8, -8, -8);
  VectorSet(self^.maxs, 8, 8, 8);
  gi.linkentity(self);

  if (self^.spawnflags and 1) <> 0 then
    target_laser_on(self)
  else
    target_laser_off(self);
end;

procedure SP_target_laser(self: edict_p);
begin
  // let everything else get spawned before we start firing
  self^.think      := target_laser_start;
  self^.nextthink := level.time + 1;
end;


//==========================================================
{ QUAKED target_lightramp (0 .5 .8) (-8 -8 -8) (8 8 8) TOGGLE
speed      How many seconds the ramping will take
message      two letters; starting lightlevel and ending lightlevel
}
procedure target_lightramp_think(self: edict_p);
var
  style: array[0..1] of char;
  temp: single;
begin
  style[0] := chr(ord('a') + trunc(self^.movedir[0] + (level.time - self^.timestamp) / FRAMETIME * self^.movedir[2]));
  style[1] := #0;
  gi.configstring(CS_LIGHTS + self^.enemy^.style, style);

  if (level.time - self^.timestamp) < self^.speed then
  begin
    self^.nextthink := level.time + FRAMETIME;
  end
  else if (self^.spawnflags and 1) <> 0 then
  begin
    temp := self^.movedir[0];
    self^.movedir[0] := self^.movedir[1];
    self^.movedir[1] := temp;
    self^.movedir[2] := self^.movedir[2] * -1;
  end;
end;

procedure target_lightramp_use(self: edict_p; other: edict_p; activator: edict_p);
var
  e: edict_p;
begin
  if self^.enemy = nil then
  begin
    // check all the targets
    e := nil;
    while true do
    begin
      e := G_Find(e, FOFS_targetname, self^.target);
      if e = nil then
        break;
      if StrComp(e^.classname, 'light') <> 0 then
      begin
        gi.dprintf('%s at %s ', self^.classname, vtos(self^.s.origin));
        gi.dprintf('target %s (%s at %s) is not a light'#10, self^.target, e^.classname, vtos(e^.s.origin));
      end
      else
      begin
        self^.enemy := e;
      end;
    end;

    if self^.enemy = nil then
    begin
      gi.dprintf('%s target %s not found at %s'#10, self^.classname, self^.target, vtos(self^.s.origin));
      G_FreeEdict(self);
      exit;
    end;
  end;

  self^.timestamp := level.time;
  target_lightramp_think(self);
end;

procedure SP_target_lightramp(self: edict_p);
begin
  if (self^._message = nil)    or (StrLen(self^._message) <> 2) or
     (self^._message[0] < 'a') or (self^._message[0] > 'z')     or
     (self^._message[1] < 'a') or (self^._message[1] > 'z')     or
     (self^._message[0] = self^._message[1]) then
  begin
    gi.dprintf('target_lightramp has bad ramp (%s) at %s'#10, self^._message, vtos(self^.s.origin));
    G_FreeEdict(self);
    exit;
  end;

  if deathmatch^.Value <> 0 then
  begin
    G_FreeEdict(self);
    exit;
  end;

  if self^.target = nil then
  begin
    gi.dprintf('%s with no target at %s'#10, self^.classname, vtos(self^.s.origin));
    G_FreeEdict(self);
    exit;
  end;

  self^.svflags := self^.svflags or SVF_NOCLIENT;
  self^.use    := target_lightramp_use;
  self^.think    := target_lightramp_think;

  self^.movedir[0] := ord(self^._message[0]) - ord('a');
  self^.movedir[1] := ord(self^._message[1]) - ord('a');
  self^.movedir[2] := (self^.movedir[1] - self^.movedir[0]) / (self^.speed / FRAMETIME);
end;

//==========================================================
{ QUAKED target_earthquake (1 0 0) (-8 -8 -8) (8 8 8)
When triggered, this initiates a level-wide earthquake.
All players and monsters are affected.
"speed"      severity of the quake (default:200)
"count"      duration of the quake (default:5)
}
procedure target_earthquake_think(self: edict_p);
var
  i: integer;
  e: edict_p;
begin
  if self^.last_move_time < level.time then
  begin
    gi.positioned_sound(@self^.s.origin, self, CHAN_AUTO, self^.noise_index, 1.0, ATTN_NONE, 0);
    self^.last_move_time := level.time + 0.5;
  end;

  for I := 1 to globals.num_edicts - 1 do
  begin
    e := @g_edicts^[I]; // cast must be done

    if not e^.inuse then
      Continue;

    if e^.client = nil then
      Continue;

    if e^.groundentity = nil then
      Continue;

    e^.groundentity := nil;
    e^.velocity[0] := e^.velocity[0] + crandom() * 150;
    e^.velocity[1] := e^.velocity[1] + crandom() * 150;
    e^.velocity[2] := self^.speed * (100.0 / e^.mass);
  end;

  if level.time < self^.timestamp then
    self^.nextthink := level.time + FRAMETIME;
end;

procedure target_earthquake_use(self: edict_p; other: edict_p; activator: edict_p);
begin
  self^.timestamp := level.time + self^.count;
  self^.nextthink := level.time + FRAMETIME;
  self^.activator := activator;
  self^.last_move_time := 0;
end;

procedure SP_target_earthquake(self: edict_p);
begin
  if self^.targetname = nil then
    gi.dprintf('untargeted %s at %s'#10, self^.classname, vtos(self^.s.origin));

  if self^.count = 0 then
    self^.count := 5;

  if self^.speed = 0 then
    self^.speed := 200;

  self^.svflags := self^.svflags or SVF_NOCLIENT;
  self^.think    := target_earthquake_think;
  self^.use    := target_earthquake_use;

  self^.noise_index := gi.soundindex('world/quake.wav');
end;

end.

