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
{$ALIGN ON}{$MINENUMSIZE 4}
{----------------------------------------------------------------------------}
{                                                                            }
{ File(s): game\g_monster.c                                                  }
{                                                                            }
{ Initial conversion by : Clairebear ()                                      }
{ Initial conversion on : Jan-2002                                           }
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
{ Updated on : 12-July-2002                                                  }
{ Updated by : Scott Price (scott.price@totalise.co.uk)                      }
{ Updated on : 25-Sep-2002                                                   }
{ Updated by : Fabrizio Rossini                                              }
{ Updated on : 14-May-2003                                                   }
{ Updated by : Scott Price (scott.price@totalise.co.uk)                      }
{                                                                            }
{----------------------------------------------------------------------------}
{ Original Conversion Header Comments:                                       }
{ Comments                                                                   }
{ All original comments retained                                             }
{                                                                            }
{ procedure M_FliesOn (self pedict_t);                                       }
{ There's a string with a forward slash in it. Looks like a file name but    }
{ I havent changed the / to a \.                                             }
{ Removed "Static" declarations for some of the functions but left the       }
{ commented out original header for these in case it makes a difference      }
{                                                                            }
{ LOGIC PRECEDENCE WORRIES                                                   }
{ m_dropToFloor function                                                     }
{ if (trace.fraction == 1 || trace.allsolid)                                 }
{ procedure M_MoveFrame (self : pedict_t);                                   }
{ if (self->s.frame < move->firstframe || self->s.frame > move->lastframe)   }
{ NOTES:                                                                     }
{ ======                                                                     }
{ - function/procedures had been organised nicely in alphabetical.  This is  }
{   a bit of a pain when trying to compare to the original and debug the     }
{   code. Have re-arranged in the order of the .c source file.  Once         }
{   debugged it can be rearranged again in a nice alphabetical order.        }
{ - Have continued the conversion to completion.                             }
{ - Some routine declarations in the Interface have been left-out at present.}
{   Determine which are Static implementations and which are visible.        }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{----------------------------------------------------------------------------}
unit g_monster;


interface


uses
  q_shared,
  q_shared_add,
  g_local,
  g_local_add;


procedure monster_fire_bullet(self: edict_p; var start, dir: vec3_t; damage, kick,
  hspread, vspread, flashtype: Integer);
procedure monster_fire_shotgun(self: edict_p; var start, aimdir: vec3_t; damage,
  kick, hspread, vspread, count, flashtype: Integer);
procedure monster_fire_blaster(self: edict_p; var start, dir: vec3_t; damage, speed,
  flashtype, effect: Integer);
procedure monster_fire_grenade(self: edict_p; const start, aimdir: vec3_t; damage,
  speed, flashtype: Integer);
procedure monster_fire_rocket(self: edict_p; const start, dir: vec3_t; damage,
  speed, flashtype: Integer);
procedure monster_fire_railgun(self: edict_p; var start, aimdir: vec3_t; damage,
  kick, flashtype: Integer);
procedure monster_fire_bfg(self: edict_p; const start, aimdir: vec3_t; damage, speed,
  kick: Integer; damage_radius: single; flashtype: Integer);

procedure M_FlyCheck(self: edict_p);
procedure AttackFinished(self: edict_p; time: single);
procedure M_CheckGround(ent: edict_p);
procedure M_CatagorizePosition(ent: edict_p);
procedure M_WorldEffects(ent: edict_p);
procedure M_droptofloor(ent: edict_p); cdecl;
procedure M_SetEffects(ent: edict_p);
procedure M_MoveFrame(self: edict_p);

procedure monster_think(self: edict_p); cdecl;
procedure monster_use(self, other, activator: edict_p); cdecl;
procedure monster_triggered_spawn(self: edict_p); cdecl;
procedure monster_triggered_spawn_use(self, other, activator: edict_p); cdecl;
procedure monster_triggered_start(self: edict_p); cdecl;

procedure monster_death_use(self: edict_p);

function monster_start(self: edict_p): qboolean; { ???:  This is declared with no body?  Strange }

procedure monster_start_go(self: edict_p); cdecl;
procedure walkmonster_start_go(self: edict_p); cdecl;
procedure walkmonster_start(self: edict_p);
procedure flymonster_start_go(self: edict_p); cdecl;
procedure flymonster_start(self: edict_p);
procedure swimmonster_start_go(self: edict_p); cdecl;
procedure swimmonster_start(self: edict_p);

implementation

uses
  g_weapon,
  gameunit,
  game_add,
  g_main,
  g_combat,
  g_ai,
  g_utils,
  g_save,
  Cpas,
  m_move,
  g_items;

//
// monster weapons
//

//FIXME mosnters should call these with a totally accurate direction
// and we can mess it up based on skill.  Spread should be for normal
// and we can tighten or loosen based on skill.  We could muck with
// the damages too, but I'm not sure that's such a good idea.
procedure monster_fire_bullet(self: edict_p; var start, dir: vec3_t; damage, kick,
  hspread, vspread, flashtype: Integer);
begin
  fire_bullet(self, start, dir, damage, kick, hspread, vspread, MOD_UNKNOWN);

  gi.WriteByte(svc_muzzleflash2);
  gi.WriteShort((Cardinal(self) - Cardinal(g_edicts)) div sizeof(edict_t));
  gi.WriteByte(flashtype);
  gi.multicast(@start, MULTICAST_PVS);
end;

procedure monster_fire_shotgun(self: edict_p; var start, aimdir: vec3_t; damage,
  kick, hspread, vspread, count, flashtype: Integer);
begin
  fire_shotgun(self, start, aimdir, damage, kick, hspread, vspread, count, MOD_UNKNOWN);

  gi.WriteByte(svc_muzzleflash2);
  gi.WriteShort((Cardinal(self) - Cardinal(g_edicts)) div sizeof(edict_t));
  gi.WriteByte(flashtype);
  gi.multicast(@start, MULTICAST_PVS);
end;

procedure monster_fire_blaster(self: edict_p; var start, dir: vec3_t; damage, speed,
  flashtype, effect: Integer);
begin
  fire_blaster(self, start, dir, damage, speed, effect, false);

  gi.WriteByte(svc_muzzleflash2);
  gi.WriteShort((Cardinal(self) - Cardinal(g_edicts)) div sizeof(edict_t));
  gi.WriteByte(flashtype);
  gi.multicast(@start, MULTICAST_PVS);
end;

procedure monster_fire_grenade(self: edict_p; const start, aimdir: vec3_t; damage,
  speed, flashtype: Integer);
begin
  fire_grenade(self, start, aimdir, damage, speed, 2.5, damage+40);

  gi.WriteByte(svc_muzzleflash2);
  gi.WriteShort((Cardinal(self) - Cardinal(g_edicts)) div sizeof(edict_t));
  gi.WriteByte(flashtype);
  gi.multicast(@start, MULTICAST_PVS);
end;

procedure monster_fire_rocket(self: edict_p; const start, dir: vec3_t; damage,
  speed, flashtype: Integer);
begin
  fire_rocket(self, start, dir, damage, speed, damage+20, damage);

  gi.WriteByte(svc_muzzleflash2);
  gi.WriteShort((Cardinal(self) - Cardinal(g_edicts)) div sizeof(edict_t));
  gi.WriteByte(flashtype);
  gi.multicast(@start, MULTICAST_PVS);
end;

procedure monster_fire_railgun(self: edict_p; var start, aimdir: vec3_t; damage,
  kick, flashtype: Integer);
begin
  fire_rail(self, start, aimdir, damage, kick);

  gi.WriteByte(svc_muzzleflash2);
  gi.WriteShort((Cardinal(self) - Cardinal(g_edicts)) div sizeof(edict_t));
  gi.WriteByte(flashtype);
  gi.multicast(@start, MULTICAST_PVS);
end;

procedure monster_fire_bfg(self: edict_p; const start, aimdir: vec3_t; damage, speed,
  kick: Integer; damage_radius: single; flashtype: Integer);
begin
  fire_bfg(self, start, aimdir, damage, speed, damage_radius);

  gi.WriteByte(svc_muzzleflash2);
  gi.WriteShort((Cardinal(self) - Cardinal(g_edicts)) div sizeof(edict_t));
  gi.WriteByte(flashtype);
  gi.multicast(@start, MULTICAST_PVS);
end;


//
// Monster utility functions
//
procedure M_FliesOff(self: edict_p); cdecl;
begin
  self^.s.effects := self^.s.effects and (not EF_FLIES);
  self^.s.sound := 0;
end;

procedure M_FliesOn(self: edict_p); cdecl;
begin
  if (self^.waterlevel <> 0) then
    Exit;
  self^.s.effects := self^.s.effects or EF_FLIES;
  self^.s.sound := gi.soundindex('infantry/inflies1.wav');
  self^.think := M_FliesOff;
  self^.nextthink := level.time + 60;
end;


procedure M_FlyCheck(self: edict_p);
begin
  if (self^.waterlevel <> 0) then
    Exit;

  if _random() > 0.5 then
    Exit;

  self^.think := M_FliesOn;
  self^.nextthink := level.time + 5 + 10 * _random();
end;

procedure AttackFinished(self: edict_p; time: single);
begin
  self^.monsterinfo.attack_finished := level.time + time;
end;

procedure M_CheckGround (ent : edict_p);
var
  point: vec3_t;
  trace: trace_t;
begin
  if (ent^.flags and (FL_SWIM or FL_FLY)) <> 0 then
    Exit;

  if (ent^.velocity[2] > 100) then
  begin
    Ent^.groundentity := Nil;
    Exit;
  end;

  // if the hull point one-quarter unit down is solid the entity is on ground
  point[0] := ent^.s.origin[0];
  point[1] := ent^.s.origin[1];
  point[2] := ent^.s.origin[2] - 0.25;

  trace := gi.trace(@ent^.s.origin, @ent^.mins, @ent^.maxs, @point, ent, MASK_MONSTERSOLID);

  // check steepness
  if (trace.plane.normal[2] < 0.7) and (not trace.startsolid) then
  begin
    ent^.groundentity := Nil;
    Exit;
  end;

  //   ent->groundentity = trace.ent;
  //   ent->groundentity_linkcount = trace.ent->linkcount;
  //   if (!trace.startsolid && !trace.allsolid)
  //      VectorCopy (trace.endpos, ent->s.origin);

  if (not trace.startsolid) and (not trace.allsolid) then
  begin
    VectorCopy(trace.endpos, ent^.s.origin);
    ent^.groundentity := trace.ent;
    ent^.groundentity_linkcount := edict_p(trace.ent)^.linkcount;
    ent^.velocity[2] := 0;
  end;
end;

procedure M_CatagorizePosition (ent : edict_p);
var
  point: vec3_t;
  cont: integer;
begin
  //
  // get waterlevel
  //
  point[0] := ent^.s.origin[0];
  point[1] := ent^.s.origin[1];
  point[2] := ent^.s.origin[2] + ent^.mins[2] + 1;
  cont := gi.pointcontents(point);

  if ((cont and MASK_WATER) = 0) then
  begin
    ent^.waterlevel := 0;
    ent^.watertype := 0;
    Exit;
  end;

  ent^.watertype := cont;
  ent^.waterlevel := 1;
  point[2] := point[2] + 26;
  cont := gi.pointcontents(point);
  if ((cont and MASK_WATER) = 0) then
    Exit;

  ent^.waterlevel := 2;
  point[2] := point[2] + 22;
  cont := gi.pointcontents(point);
  if (Cont and MASK_WATER) <> 0 then
    ent^.waterlevel := 3;
end;

procedure M_WorldEffects (ent : edict_p);
var
  dmg: integer;
begin
  if (ent^.health > 0) then
  begin
    if (ent^.flags and FL_SWIM) = 0 then
    begin
      if (ent^.waterlevel < 3) then
      begin
        ent^.air_finished := level.time + 12
      end
      else if (ent^.air_finished < level.time) then
      begin// drown!
        if (ent^.pain_debounce_time < level.time) then
        begin
          dmg := 2 + 2 * floor(level.time - ent^.air_finished);
          if (dmg > 15) then
            dmg := 15;
          T_Damage(ent, world, world, vec3_origin, ent^.s.origin, vec3_origin, dmg, 0, DAMAGE_NO_ARMOR, MOD_WATER);
          ent^.pain_debounce_time := level.time + 1;
        end;
      end;
    end
    else
    begin
      if (ent^.waterlevel > 0) then
      begin
        ent^.air_finished := level.time + 9;
      end
      else if (ent^.air_finished < level.time) then
      begin   // suffocate!
        if (ent^.pain_debounce_time < level.time) then
        begin
          dmg := 2 + 2 * floor(level.time - ent^.air_finished);
          if (dmg > 15) then
            dmg := 15;
          T_Damage(ent, world, world, vec3_origin, ent^.s.origin, vec3_origin, dmg, 0, DAMAGE_NO_ARMOR, MOD_WATER);
          ent^.pain_debounce_time := level.time + 1;
        end;
      end;
    end;
  end;

  if (ent^.waterlevel = 0) then
  begin
    if (ent^.flags and FL_INWATER) <> 0 then
    begin
      gi.sound(ent, CHAN_BODY, gi.soundindex('player/watr_out.wav'), 1, ATTN_NORM, 0);
      ent^.flags := ent^.flags AND (NOT FL_INWATER);
    end;

    Exit;
  end;

  if ((ent^.watertype and CONTENTS_LAVA) <> 0) and ((ent^.flags and FL_IMMUNE_LAVA) = 0) then
  begin
    if (ent^.damage_debounce_time < level.time) then
    begin
      ent^.damage_debounce_time := level.time + 0.2;
      T_Damage(ent, world, world, vec3_origin, ent^.s.origin, vec3_origin, 10 * ent^.waterlevel, 0, 0, MOD_LAVA);
    end;
  end;
  if ((ent^.watertype and CONTENTS_SLIME) <> 0) and ((ent^.flags and FL_IMMUNE_SLIME) = 0) then
  begin
    if (ent^.damage_debounce_time < level.time) then
    begin
      ent^.damage_debounce_time := level.time + 1;
      T_Damage(ent, world, world, vec3_origin, ent^.s.origin, vec3_origin, 4 * ent^.waterlevel, 0, 0, MOD_SLIME);
    end;
  end;

  if (ent^.flags and FL_INWATER) = 0 then
  begin
    if (ent^.svflags and SVF_DEADMONSTER) = 0 then
    begin
      if ((ent^.watertype and CONTENTS_LAVA) <> 0) then
      begin
        if (_random() <= 0.5) then
          gi.sound(ent, CHAN_BODY, gi.soundindex('player/lava1.wav'), 1, ATTN_NORM, 0)
        else
          gi.sound(ent, CHAN_BODY, gi.soundindex('player/lava2.wav'), 1, ATTN_NORM, 0);
      end
      else if (ent^.watertype and CONTENTS_SLIME) <> 0 then
        gi.sound(ent, CHAN_BODY, gi.soundindex('player/watr_in.wav'), 1, ATTN_NORM, 0)
      else if (ent^.watertype and CONTENTS_WATER) <> 0 then
        gi.sound(ent, CHAN_BODY, gi.soundindex('player/watr_in.wav'), 1, ATTN_NORM, 0);
    end;

    ent^.flags := ent^.flags or FL_INWATER;
    ent^.damage_debounce_time := 0;
  end;
end;

procedure M_droptofloor(ent: edict_p);
var
  end_: vec3_t;
  trace: trace_t;
begin
  ent^.s.origin[2] := ent^.s.origin[2] + 1;
  VectorCopy(ent^.s.origin, end_);
  end_[2] := end_[2] - 256;

  trace := gi.trace(@ent^.s.origin, @ent^.mins, @ent^.maxs, @end_, ent, MASK_MONSTERSOLID);

  if (trace.fraction = 1) or (trace.allsolid) then
    Exit;

  VectorCopy(trace.endpos, ent^.s.origin);

  gi.linkentity(ent);
  M_CheckGround(ent);
  M_CatagorizePosition(ent);
end;

procedure M_SetEffects(ent: edict_p);
begin
  ent^.s.effects := ent^.s.effects and (not (EF_COLOR_SHELL or EF_POWERSCREEN));
  ent^.s.renderfx := ent^.s.renderfx and (not (RF_SHELL_RED or RF_SHELL_GREEN or RF_SHELL_BLUE));

  if (ent^.monsterinfo.aiflags and AI_RESURRECTING) <> 0 then
  begin
    ent^.s.effects := ent^.s.effects or EF_COLOR_SHELL;
    ent^.s.renderfx := ent^.s.renderfx or RF_SHELL_RED;
  end;

  if (ent^.health <= 0) then
    Exit;

  if (ent^.powerarmor_time > level.time) then
  begin
    if (ent^.monsterinfo.power_armor_type = POWER_ARMOR_SCREEN) then
    begin
      ent^.s.effects := ent^.s.effects or EF_POWERSCREEN;
    end
    else if (ent^.monsterinfo.power_armor_type = POWER_ARMOR_SHIELD) then
    begin
      ent^.s.effects := ent^.s.effects or EF_COLOR_SHELL;
      ent^.s.renderfx := ent^.s.renderfx or RF_SHELL_GREEN;
    end;
  end;
end;

procedure M_MoveFrame(self: edict_p);
var
  move: mmove_p;
  index: integer;
begin
  move := self^.monsterinfo.currentmove;
  self^.nextthink := level.time + FRAMETIME;

  if ((self^.monsterinfo.nextframe <> 0) and (self^.monsterinfo.nextframe >= move^.firstframe)
  and (self^.monsterinfo.nextframe <= move^.lastframe)) then
  begin
    self^.s.frame := self^.monsterinfo.nextframe;
    self^.monsterinfo.nextframe := 0;
  end
  else
  begin
    if (self^.s.frame = move^.lastframe)then
    begin
      if Assigned(move^.endfunc) then
      begin
        move^.endfunc(self);

        // regrab move, endfunc is very likely to change it
        move := self^.monsterinfo.currentmove;

        // check for death
        if (self^.svflags and SVF_DEADMONSTER) <> 0 then
          Exit;
      end;
    end;

    if (self^.s.frame < move^.firstframe) or (self^.s.frame > move^.lastframe) then
    begin
      self^.monsterinfo.aiflags := self^.monsterinfo.aiflags and (not AI_HOLD_FRAME);
      self^.s.frame := move^.firstframe;
    end
    else
    begin
      if (self^.monsterinfo.aiflags AND AI_HOLD_FRAME) = 0 then
      begin
        Inc(self^.s.frame);
        if (self^.s.frame > move^.lastframe) then
          self^.s.frame := move^.firstframe;
      end;
    end;
  end;

  index := self^.s.frame - move^.firstframe;
  if (@mframe_a(move^.frame)[index].aifunc)<> nil then
    if (self^.monsterinfo.aiflags and AI_HOLD_FRAME) = 0 then
      mframe_a(move^.frame)[index].aifunc (self , mframe_a(move^.frame)[index].dist * self^.monsterinfo.scale)
    else
      mframe_a(move^.frame)[index].aifunc(self, 0);

  if Assigned(mframe_a(move^.frame)[index].thinkfunc) then
    mframe_a(move^.frame)[index].thinkfunc(self);
end;

procedure monster_think(self: edict_p);
begin
  M_MoveFrame(self);
  if (self^.linkcount <> self^.monsterinfo.linkcount) then
  begin
    self^.monsterinfo.linkcount := self^.linkcount;
    M_CheckGround(self);
  end;

  M_CatagorizePosition(self);
  M_WorldEffects(self);
  M_SetEffects(self);
end;

{ ================
monster_use

Using a monster makes it angry at the current activator
================ }

procedure monster_use(self, other, activator: edict_p);
begin
  if (self^.enemy <> nil)then
    Exit;
  if (self^.health <= 0)then
    Exit;
  if (activator^.flags and FL_NOTARGET) <> 0 then
    Exit;
  if (activator^.client = nil) and ((activator^.monsterinfo.aiflags and AI_GOOD_GUY) = 0) then
    Exit;

  // delay reaction so if the monster is teleported, its sound is still heard
  self^.enemy := activator;
  FoundTarget(self);
end;

procedure monster_triggered_spawn(self: edict_p);
begin
  self^.s.origin[2] := self^.s.origin[2] + 1;
  KillBox(self);

  self^.solid := SOLID_BBOX;
  self^.movetype := MOVETYPE_STEP;
  self^.svflags := self^.svflags and (NOT SVF_NOCLIENT);
  self^.air_finished := level.time + 12;
  gi.linkentity(self);

  monster_start_go(self);

  if (self^.enemy <> nil) and ((self^.spawnflags and 1) = 0) and ((self^.enemy^.flags and FL_NOTARGET) = 0) then
  begin
    FoundTarget(self)
  end
  else
  begin
    self^.enemy := Nil;
  end;
end;

procedure monster_triggered_spawn_use(self, other, activator: edict_p);
begin
  // we have a one frame delay here so we don't telefrag the guy who activated us
  self^.think := monster_triggered_spawn;
  self^.nextthink := level.time + FRAMETIME;
  if Assigned(activator^.client) then
    self^.enemy := activator;
  self^.use := monster_use;
end;

procedure monster_triggered_start(self: edict_p);
begin
  self^.solid := SOLID_NOT;
  self^.movetype := MOVETYPE_NONE;
  self^.svflags := self^.svflags or SVF_NOCLIENT;
  self^.nextthink := 0;
  self^.use := monster_triggered_spawn_use;
end;

{ ================
monster_death_use

When a monster dies, it fires all of its targets with the current
enemy as activator.
================ }

procedure monster_death_use(self : edict_p);
begin
  self^.flags := self^.flags and (NOT (FL_FLY or FL_SWIM));
  self^.monsterinfo.aiflags := self^.monsterinfo.aiflags and AI_GOOD_GUY;

  if Assigned(self^.item) then
  begin
    Drop_Item(self, self^.item);
    self^.item := Nil;
  end;

  if (self^.deathtarget <> nil)then
    self^.target := self^.deathtarget;

  if (self^.target = Nil) then
    Exit;

  G_UseTargets(self, self^.enemy);
end;

//============================================================================

function monster_start(self: edict_p): qboolean;
begin
  if (deathmatch^.value <> 0) then
  begin
    G_FreeEdict(self);
    Result := false;
    Exit;
  end;

  if ((self^.spawnflags and 4) <> 0) and ((self^.monsterinfo.aiflags and AI_GOOD_GUY) = 0) then
  begin
    self^.spawnflags := self^.spawnflags and (not 4);
    self^.spawnflags := self^.spawnflags or 1;
    { The following line was originally commented out }
//  gi.dprintf("fixed spawnflags on %s at %s\n", self->classname, vtos(self->s.origin));
  end;

  if (self^.monsterinfo.aiflags and AI_GOOD_GUY) = 0 then
    Inc(level.total_monsters);

  self^.nextthink := level.time + FRAMETIME;
  self^.svflags := self^.svflags or SVF_MONSTER;
  self^.s.renderfx := self^.s.renderfx or RF_FRAMELERP;
  self^.takedamage := DAMAGE_AIM;
  self^.air_finished := level.time + 12;
  self^.use := monster_use;
  self^.max_health := self^.health;
  self^.clipmask := MASK_MONSTERSOLID;

  self^.s.skinnum := 0;
  self^.deadflag := DEAD_NO;
  self^.svflags := self^.svflags and (not SVF_DEADMONSTER);

  if (@self^.monsterinfo.checkattack = nil) then
    self^.monsterinfo.checkattack := M_CheckAttack;

  VectorCopy(self^.s.origin, self^.s.old_origin);

  if (st.item <> nil) then
  begin
    self^.item := FindItemByClassname(st.item);
    if (self^.item = nil) then
      gi.dprintf('%s at %s has bad item: %s'#10, self^.classname, vtos(self^.s.origin), st.item);
  end;

  // randomize what frame they start on
  if (self^.monsterinfo.currentmove <> nil) then
    self^.s.frame := self^.monsterinfo.currentmove^.firstframe +
                      (rand() mod (self^.monsterinfo.currentmove^.lastframe
                      - self^.monsterinfo.currentmove^.firstframe + 1));

  Result := True;
end;

procedure monster_start_go(self: edict_p);
var
  v: vec3_t;
  notcombat, fixup: qboolean;
  target: edict_p;
begin
  if (self^.health <= 0) then
    Exit;

  // check for target to combat_point and change to combattarget
  if (self^.target <> nil) then
  begin
    target := Nil;
    notcombat := False;
    fixup := False;

    { NOTE(SP):  Removed the TRY..FINALLY block that ensured the next call to
                 G_Find occured, due to possible performance issues with
                 try blocks. }
    target := G_Find(target, FOFS_targetname, self^.target);
    while (target <> Nil) do
    begin
      if (strcmp(target^.classname, 'point_combat') = 0) then
      begin
        self^.combattarget := self^.target;
        fixup := True;
      end
      else
        notcombat := True;

      target := G_Find(target, FOFS_targetname, self^.target);
    end;
    if notcombat AND (self^.combattarget <> nil) then
      gi.dprintf('%s at %s has target with mixed types'#10, self^.classname, vtos(self^.s.origin));
    if fixup then
      self^.target := Nil;
  end;

  // validate combattarget
  if (self^.combattarget <> nil) then
  begin
    target := Nil;
    { NOTE(SP):  Removed the TRY..FINALLY block that ensured the next call to
                 G_Find occured, due to possible performance issues with
                 try blocks. }
    target := G_Find(target, FOFS_targetname , self^.combattarget);
    while (target <> Nil) do
    begin
      if (strcmp(target^.classname, 'point_combat') <> 0) then
      begin
        gi.dprintf('%s at (%i %i %i) has a bad combattarget %s : %s at (%i %i %i)'#10,
          self^.classname, Trunc(self^.s.origin[0]), Trunc(self^.s.origin[1]), Trunc(self^.s.origin[2]),
          self^.combattarget, target^.classname, Trunc(target^.s.origin[0]), Trunc(target^.s.origin[1]),
          Trunc(target^.s.origin[2]));
      end;

      target := G_Find(target, FOFS_targetname , self^.combattarget);
    end;
  end;

  if (self^.target <> nil) then
  begin
    self^.movetarget := G_PickTarget(self^.target);
    self^.goalentity := self^.movetarget;
    if (self^.movetarget = nil) then
    begin
      gi.dprintf ('%s can''t find target %s at %s'#10, self^.classname, self^.target, vtos(self^.s.origin));
      self^.target := Nil;
      self^.monsterinfo.pausetime := 100000000;
      self^.monsterinfo.stand(self);
    end
    else if (strcmp(self^.movetarget^.classname, 'path_corner') = 0) then
    begin
      VectorSubtract(self^.goalentity^.s.origin, self^.s.origin, v);
      self^.s.angles[YAW] := vectoyaw(v);
      self^.ideal_yaw := self^.s.angles[YAW];
      self^.monsterinfo.walk(self);
      self^.target := Nil;
    end
    else
    begin
      self^.movetarget := Nil;
      self^.goalentity := self^.movetarget;
      self^.monsterinfo.pausetime := 100000000;
      self^.monsterinfo.stand(self);
    end;
  end
  else
  begin
    self^.monsterinfo.pausetime := 100000000;
    self^.monsterinfo.stand(self);
  end;

  self^.think := monster_think;
  self^.nextthink := level.time + FRAMETIME;
end;

procedure walkmonster_start_go(self: edict_p);
begin
  if ((self^.spawnflags AND 2) = 0) AND (level.time < 1) then
  begin
    M_droptofloor(self);

    if (self^.groundentity <> nil) then
      if not (M_walkmove(self, 0, 0)) then
        gi.dprintf('%s in solid at %s'#10, self^.classname, vtos(self^.s.origin));
  end;

  if (self^.yaw_speed = 0) then
    self^.yaw_speed := 20;
  self^.viewheight := 25;

  monster_start_go(self);

  if (self^.spawnflags AND 2) <> 0 then
    monster_triggered_start(self);
end;

procedure walkmonster_start(self: edict_p);
begin
  self^.think := walkmonster_start_go;
  monster_start(self);
end;

procedure flymonster_start_go(self: edict_p);
begin
  if not(M_walkmove(self, 0, 0)) then
    gi.dprintf('%s in solid at %s'#10, self^.classname, vtos(self^.s.origin));

  if (self^.yaw_speed = 0) then
    self^.yaw_speed := 10;
  self^.viewheight := 25;

  monster_start_go(self);

  if (self^.spawnflags AND 2) <> 0 then
    monster_triggered_start(self);
end;

procedure flymonster_start(self: edict_p);
begin
  self^.flags := self^.flags OR FL_FLY;
  self^.think := flymonster_start_go;
  monster_start(self);
end;

procedure swimmonster_start_go(self: edict_p);
begin
  if (self^.yaw_speed = 0) then
    self^.yaw_speed := 10;

  self^.viewheight := 10;

  monster_start_go(self);

  if (self^.spawnflags AND 2) <> 0 then
    monster_triggered_start(self);
end;

procedure swimmonster_start(self: edict_p);
begin
  self^.flags := self^.flags OR FL_SWIM;
  self^.think := swimmonster_start_go;
  monster_start(self);
end;

end.
