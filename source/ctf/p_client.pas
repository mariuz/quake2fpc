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


//This is "COMMON" file for \GAME\p_hud.pas & \CTF\p_hud.pas
{$DEFINE CTF}
{$IFDEF CTF}
{$ELSE}
{$ENDIF}

// PLEASE, don't modify this file
// 70% complete

{----------------------------------------------------------------------------}
{                                                                            }
{ File(s): p_client.c                                                        }
{                                                                            }
{ Initial conversion by : YgriK (Igor Karpov) - glYgriK@hotbox.ru            }
{ Initial conversion on : 04-Feb-2002                                        }
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
{ 1) g_local.??? (inc & pas)                                                 }
{                                                                            }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{ 1) Do more tests                                                           }
{                                                                            }
{----------------------------------------------------------------------------}

#include "g_local.h"
#include "m_player.h"

void ClientUserinfoChanged (edict_t *ent, char *userinfo);

void SP_misc_teleporter_dest (edict_t *ent);

//
// Gross, ugly, disgustuing hack section
//

// this function is an ugly as hell hack to fix some map flaws
//
// the coop spawn spots on some maps are SNAFU.  There are coop spots
// with the wrong targetname as well as spots with no name at all
//
// we use carnal knowledge of the maps to fix the coop spot targetnames to match
// that of the nearest named single player spot

// (GAME <> CTF)
static procedure SP_FixCoopSpots (edict_t *self);
var
   edict_t   *spot;
  d : vec3_t;
begin
  spot := NULL;

  while True do
  begin
    spot := G_Find(spot, FOFS(classname), 'info_player_start');
    if (!spot) then
      Exit;
    if (!spot.targetname) thne
      Continue;
    VectorSubtract(self.s.origin, spot.s.origin, d);
    if (VectorLength(d) < 384) then
    begin
{$IFDEF CTF}
      if ( (!self->targetname) || stricmp(self->targetname, spot->targetname) != 0)
{$ELSE}
      if ( (!self->targetname) || Q_stricmp(self->targetname, spot->targetname) != 0)
{$ENDIF}
      begin
//idsoft   gi.dprintf("FixCoopSpots changed %s at %s targetname from %s to %s\n", self->classname, vtos(self->s.origin), self->targetname, spot->targetname);
        self.targetname := spot.targetname;
      end;
      Exit;
    end;
  end;
end;//procedure (GAME <> CTF)


// now if that one wasn't ugly enough for you then try this one on for size
// some maps don't have any coop spots at all, so we need to create them
// where they should have been

// (GAME <> CTF)
static procedure SP_CreateCoopSpots (edict_t *self);
var
   edict_t   *spot;
begin
{$IFDEF CTF}
        if(stricmp(level.mapname, 'security') == 0)
{$ELSE}
   if(Q_stricmp(level.mapname, 'security') == 0)
{$ENDIF}
  begin
    spot := G_Spawn();
    spot.classname := 'info_player_coop';
    spot.s.origin[0] := 188 - 64;
    spot.s.origin[1] := -164;
    spot.s.origin[2] := 80;
    spot.targetname := 'jail3';
    spot.s.angles[1] := 90;

    spot := G_Spawn();
    spot.classname := 'info_player_coop';
    spot.s.origin[0] := 188 + 64;
    spot.s.origin[1] := -164;
    spot.s.origin[2] := 80;
    spot.targetname := 'jail3';
    spot.s.angles[1] := 90;

    spot := G_Spawn();
    spot.classname := 'info_player_coop';
    spot.s.origin[0] := 188 + 128;
    spot.s.origin[1] := -164;
    spot.s.origin[2] := 80;
    spot.targetname := 'jail3';
    spot.s.angles[1] := 90;

    Exit;
  end;//if
end;//procedure (GAME <> CTF)


{*QUAKED info_player_start (1 0 0) (-16 -16 -24) (16 16 32)
The normal starting point for a level.
*}
// (GAME <> CTF)
procedure SP_info_player_start(edict_t *self);
begin
  if (!coop.value) then
    Exit;
{$IFDEF CTF}
        if(stricmp(level.mapname, 'security') == 0)
{$ELSE}
   if(Q_stricmp(level.mapname, 'security') == 0)
{$ENDIF}
  begin
    // invoke one of our gross, ugly, disgusting hacks
    self.think := SP_CreateCoopSpots;
    self.nextthink := level.time + FRAMETIME;
  end;
end;//procedure (GAME <> CTF)


{*QUAKED info_player_deathmatch (1 0 1) (-16 -16 -24) (16 16 32)
potential spawning position for deathmatch games
*}
// (GAME=CTF)
procedure SP_info_player_deathmatch(edict_t *self);
begin
  if (!deathmatch.value) then
  begin
    G_FreeEdict (self);
    Exit;
  end;
  SP_misc_teleporter_dest (self);
end;//procedure (GAME=CTF)


{*QUAKED info_player_coop (1 0 1) (-16 -16 -24) (16 16 32)
potential spawning position for coop games
*}
// (GAME <> CTF)
procedure SP_info_player_coop(edict_t *self);
begin
  if (!coop.value) then
  begin
    G_FreeEdict (self);
    Exit;
  end;

{$IFDEF CTF}
   if((stricmp(level.mapname, "jail2") == 0)   ||
      (stricmp(level.mapname, "jail4") == 0)   ||
      (stricmp(level.mapname, "mine1") == 0)   ||
      (stricmp(level.mapname, "mine2") == 0)   ||
      (stricmp(level.mapname, "mine3") == 0)   ||
      (stricmp(level.mapname, "mine4") == 0)   ||
      (stricmp(level.mapname, "lab") == 0)     ||
      (stricmp(level.mapname, "boss1") == 0)   ||
      (stricmp(level.mapname, "fact3") == 0)   ||
      (stricmp(level.mapname, "biggun") == 0)  ||
      (stricmp(level.mapname, "space") == 0)   ||
      (stricmp(level.mapname, "command") == 0) ||
      (stricmp(level.mapname, "power2") == 0) ||
      (stricmp(level.mapname, "strike") == 0))

{$ELSE}
   if((Q_stricmp(level.mapname, "jail2") == 0)   ||
      (Q_stricmp(level.mapname, "jail4") == 0)   ||
      (Q_stricmp(level.mapname, "mine1") == 0)   ||
      (Q_stricmp(level.mapname, "mine2") == 0)   ||
      (Q_stricmp(level.mapname, "mine3") == 0)   ||
      (Q_stricmp(level.mapname, "mine4") == 0)   ||
      (Q_stricmp(level.mapname, "lab") == 0)     ||
      (Q_stricmp(level.mapname, "boss1") == 0)   ||
      (Q_stricmp(level.mapname, "fact3") == 0)   ||
      (Q_stricmp(level.mapname, "biggun") == 0)  ||
      (Q_stricmp(level.mapname, "space") == 0)   ||
      (Q_stricmp(level.mapname, "command") == 0) ||
      (Q_stricmp(level.mapname, "power2") == 0) ||
      (Q_stricmp(level.mapname, "strike") == 0))
{$ENDIF}
  begin
    // invoke one of our gross, ugly, disgusting hacks
    self.think := SP_FixCoopSpots;
    self.nextthink := level.time + FRAMETIME;
  end;
end;//procedure (GAME <> CTF)


{*QUAKED info_player_intermission (1 0 1) (-16 -16 -24) (16 16 32)
The deathmatch intermission point will be at one of these
Use 'angles' instead of 'angle', so you can set pitch or roll as well as yaw.  'pitch yaw roll'
*}
// (GAME=CTF)
procedure SP_info_player_intermission;
begin
end;//procedure (GAME=CTF)


//=======================================================================

// (GAME=CTF)
procedure player_pain (edict_t *self, edict_t *other, float kick, int damage);
begin
  // player pain is handled at the end of the frame in P_DamageFeedback
end;//procedure (GAME=CTF)


// (GAME <> CTF)
function IsFemale (edict_t *ent) : qboolean;
var
   char      *info;
begin
  if (!ent.client) then
  begin
    Result := false;
    Exit;
  end;

{$IFDEF CTF}
  info := Info_ValueForKey (ent.client.pers.userinfo, 'skin');
{$ELSE}
  info := Info_ValueForKey (ent.client.pers.userinfo, 'gender');
{$ENDIF}
  if (info[0] = 'f' OR info[0] = 'F') then
  begin
    Result := true;
    Exit;
  end;
  Result := false;
end;//procedure (GAME <> CTF)


{$IFNDEF CTF}  //onlyGAME (none CTF)
// (GAME <> CTF)
function IsNeutral (edict_t *ent) : qboolean;
var
   char      *info;
begin
  if (!ent.lient) then
  begin
    Result := false;
    Exit;
  end;

  info := Info_ValueForKey (ent.client.pers.userinfo, 'gender');
  if (info[0] <> 'f' AND info[0] <> 'F' AND info[0] <> 'm' AND info[0] <> 'M') then
  begin
  begin
    Result := true;
    Exit;
  end;
  Result := false;
end;//procedure (GAME <> CTF)
{$ENDIF}

// (GAME <> CTF)
procedure ClientObituary (edict_t *self, edict_t *inflictor, edict_t *attacker);
var
  mod_ : integer;
   char      *message;
   char      *message2;
  ff   : qboolean;
begin
  if (coop.value AND attacker.client) then
    meansOfDeath := meansOfDeath OR MOD_FRIENDLY_FIRE;

  if (deathmatch.value OR coop.value) then
  begin
    ff := meansOfDeath AND MOD_FRIENDLY_FIRE;
    mod_ := meansOfDeath AND (NOT MOD_FRIENDLY_FIRE);
    message := NULL;  //Nil _OR_ ''
    message2 := '';

    Case mod_ of
      MOD_SUICIDE:       message := 'suicides';
      MOD_FALLING:       message := 'cratered';
      MOD_CRUSH:         message := 'was squished';
      MOD_WATER:         message := 'sank like a rock';
      MOD_SLIME:         message := 'melted';
      MOD_LAVA:          message := 'does a back flip into the lava';
      MOD_EXPLOSIVE,
      MOD_BARREL:        message := 'blew up';
      MOD_EXIT:          message := 'found a way out';
      MOD_TARGET_LASER:  message := 'saw the light';
      MOD_TARGET_BLASTER:message := 'got blasted';
      MOD_BOMB:
      MOD_SPLASH:
      MOD_TRIGGER_HURT:  message := 'was in the wrong place';
    end;//case
    if (attacker = self) then
    begin
      Case mod_ of
        MOD_HELD_GRENADE: message := 'tried to put the pin back in';
        MOD_HG_SPLASH,
        MOD_G_SPLASH:     begin
{$IFNDEF CTF}  //onlyGAME (none CTF)
                            if IsNeutral(self)
                            then message := 'tripped on its own grenade'
                            else
{$ENDIF}
                            if (IsFemale(self)
                            then message := 'tripped on her own grenade'
                            else message := 'tripped on his own grenade';
                          end;
        MOD_R_SPLASH:     begin
{$IFNDEF CTF}  //onlyGAME (none CTF)
                            if IsNeutral(self)
                            then message := 'blew itself up';
                            else
{$ENDIF}
                            if IsFemale(self)
                            then message := 'blew herself up';
                            else message := 'blew himself up';
                          end;

        MOD_BFG_BLAST:    message := 'should have used a smaller gun';
        else              begin
{$IFNDEF CTF}  //onlyGAME (none CTF)
                            if IsNeutral(self)
                            then message := 'killed itself';
                            else
{$ENDIF}
                            if IsFemale(self)
                            then message := 'killed herself'
                            else message := 'killed himself';
                          end;
      end;//case
    end;//if
    if (message) then
    begin
      gi.bprintf (PRINT_MEDIUM, '%s %s.\n', self.client.pers.netname, message);
      if (deathmatch.value) then
        self.client.resp.score--;
      self.enemy := NULL;
      Exit;
    end;

    self.enemy := attacker;
    if (attacker AND attacker.client) then
    begin
      Case mod_ of
        MOD_BLASTER:    message := 'was blasted by';
        MOD_SHOTGUN:    message := 'was gunned down by';
        MOD_SSHOTGUN:   begin
                          message := 'was blown away by';
                          message2 := '"s super shotgun';
                        end;
        MOD_MACHINEGUN: message := 'was machinegunned by';
        MOD_CHAINGUN:   begin
                          message := 'was cut in half by';
                          message2 := '"s chaingun';
                        end;
        MOD_GRENADE:    begin
                          message := 'was popped by';
                          message2 := '"s grenade';
                        end;
        MOD_G_SPLASH:   begin
                          message := 'was shredded by';
                          message2 := '"s shrapnel';
                        end;
        MOD_ROCKET:     begin
                          message := 'ate';
                          message2 := '"s rocket';
                        end;
        MOD_R_SPLASH:   begin
                          message := 'almost dodged';
                          message2 := '"s rocket';
                        end;
        MOD_HYPERBLASTER:begin
                           message := 'was melted by';
                           message2 := '"s hyperblaster';
                         end;
        MOD_RAILGUN:    message := 'was railed by';
        MOD_BFG_LASER:  begin
                          message := 'saw the pretty lights from';
                          message2 := '"s BFG';
                        end;
        MOD_BFG_BLAST:  begin
                          message := 'was disintegrated by';
                          message2 := '"s BFG blast';
                        end;
        MOD_BFG_EFFECT: begin
                          message := 'couldn't hide from';
                          message2 := '"s BFG';
                        end;
        MOD_HANDGRENADE:begin
                          message := 'caught';
                          message2 := '"s handgrenade';
                        end;
        MOD_HG_SPLASH:  begin
                          message := 'didn"t see';
                          message2 := '"s handgrenade';
                        end;
        MOD_HELD_GRENADE:begin
                           message := 'feels';
                           message2 := '"s pain';
                         end;
        MOD_TELEFRAG:   begin
                          message := 'tried to invade';
                          message2 := '"s personal space';
                        end;
{$IFDEF CTF}  //onlyCTF
//ZOID
        MOD_GRAPPLE:    begin
                          message := 'was caught by';
                          message2 := '"s grapple';
                        end;
//ZOID
{$ENDIF}
      end;//case

      if (message) then
      begin
        gi.bprintf (PRINT_MEDIUM, '%s %s %s%s\n', self.client.pers.netname, message, attacker.client.pers.netname, message2);
        if (deathmatch.value) then
          if (ff)
          then attacker->client->resp.score--;
          else attacker->client->resp.score++;
        Exit;
      end;
    end;//if
  end;//if

  gi.bprintf (PRINT_MEDIUM, '%s died.\n', self.client.pers.netname);
  if (deathmatch.value) then
    self->client->resp.score--;
end;//procedure (GAME <> CTF)

//Y: ???
void Touch_Item (edict_t *ent, edict_t *other, cplane_t *plane, csurface_t *surf);

// (GAME=CTF)
procedure TossClientWeapon (edict_t *self);
var
   gitem_t      *item;
   edict_t      *drop;
  quad   : qboolean;
  spread : float;
begin
  if (!deathmatch.value) then
    Exit;

  item := self.client.pers.weapon;
  if (! self.client.pers.inventory[self.client.ammo_index] ) then
    item = NULL;
  if (item && (strcmp (item.pickup_name, 'Blaster') == 0)) then
    item = NULL;

  if (!((int)(dmflags.value) & DF_QUAD_DROP))
  then quad := false
  else quad := (self.client.quad_framenum > (level.framenum + 10));

  if (item AND quad)
  then spread := 22.5
  else spread := 0.0;

  if (item) then
  begin
    self.client.v_angle[YAW] := self.client.v_angle[YAW] - spread;
    drop := Drop_Item (self, item);
    self.client.v_angle[YAW] := self.client.v_angle[YAW] + spread;
    drop.spawnflags := DROPPED_PLAYER_ITEM;
  end;

  if (quad) then
  begin
    self.client.v_angle[YAW] := self.client.v_angle[YAW] + spread;
    drop := Drop_Item (self, FindItemByClassname ('item_quad'));
    self.client.v_angle[YAW] := self.client.v_angle[YAW] - spread;
    drop.spawnflags := drop.spawnflags OR DROPPED_PLAYER_ITEM;

    drop.touch := Touch_Item;
    drop.nextthink := level.time + (self.client.quad_framenum - level.framenum) * FRAMETIME;
    drop.think := G_FreeEdict;
  end;
end;//procedure (GAME=CTF)


{*
==================
LookAtKiller
==================
*}
// (GAME=CTF)
procedure LookAtKiller (edict_t *self, edict_t *inflictor, edict_t *attacker);
var
  dir : vec3_t;
begin
  if (attacker) AND (attacker <> world) AND (attacker <> self)
  then VectorSubtract (attacker.s.origin, self.s.origin, dir)
  else
    if (inflictor) AND (inflictor <> world) AND (inflictor <> self)
    then VectorSubtract (inflictor.s.origin, self.s.origin, dir)
    else begin
      self.client.killer_yaw := self.s.angles[YAW];
      Exit;
    end;

  if (dir[0])
  then self.client.killer_yaw := 180/M_PI*atan2(dir[1], dir[0])
  else begin
    self.client.killer_yaw := 0;
    if (dir[1] > 0)
    then self.client.killer_yaw := 90
    else
      if (dir[1] < 0) then
        self.client.killer_yaw := -90;
  end;
  if (self.client.killer_yaw < 0) then
    self.client.killer_yaw := self.client.killer_yaw + 360;
end;//procedure (GAME=CTF)


{*
==================
player_die
==================
*}
// (GAME <> CTF)
procedure player_die (edict_t *self, edict_t *inflictor, edict_t *attacker, int damage, vec3_t point);
var
  n : integer;
        static int i;

begin
  VectorClear (self.avelocity);

  self.takedamage := DAMAGE_YES;
  self.movetype := MOVETYPE_TOSS;

  self.s.modelindex2 := 0;   // remove linked weapon model

{$IFDEF CTF}  //onlyCTF
//ZOID
  self.s.modelindex3 := 0;        // remove linked ctf flag
//ZOID
{$ENDIF}

  self.s.angles[0] := 0;
  self.s.angles[2] := 0;

  self.s.sound := 0;
  self.client.weapon_sound := 0;

  self.maxs[2] := -8;

//idsoft   self->solid = SOLID_NOT;
  self.svflags := self.svflags OR SVF_DEADMONSTER;

  if (!self.deadflag) then
  begin
    self.client.respawn_time := level.time + 1.0;
    LookAtKiller (self, inflictor, attacker);
    self.client.ps.pmove.pm_type := PM_DEAD;
    ClientObituary (self, inflictor, attacker);

{$IFDEF CTF}  //onlyCTF
//ZOID
    // if at start and same team, clear
    if (ctf->value && meansOfDeath == MOD_TELEFRAG) AND
       (self.client.resp.ctf_state < 2) AND
       (self.client.resp.ctf_team = attacker.client.resp.ctf_team) then
    begin
      attacker->client->resp.score--;
      self.client.resp.ctf_state := 0;
    end;

    CTFFragBonuses(self, inflictor, attacker);
//ZOID
{$ENDIF}

    TossClientWeapon (self);

{$IFDEF CTF}
//ZOID
    CTFPlayerResetGrapple(self);
    CTFDeadDropFlag(self);
    CTFDeadDropTech(self);
//ZOID
    if (deathmatch->value && !self->client->showscores) then
      Cmd_Help_f (self);              // show scores
{$ELSE}
    if (deathmatch,value) then
      Cmd_Help_f (self);      // show scores

    // clear inventory
    // this is kind of ugly, but it's how we want to handle keys in coop
    for n:=0 to game.num_items-1 do
    begin
      if (coop->value && itemlist[n].flags & IT_KEY) then
        self.client.resp.coop_respawn.inventory[n] := self.client.pers.inventory[n];
      self.client.pers.inventory[n] := 0;
    end;//for
{$ENDIF}
  end;//if

  // remove powerups
  self.client.quad_framenum := 0;
  self.client.invincible_framenum := 0;
  self.client.breather_framenum := 0;
  self.client.enviro_framenum := 0;

{$IFDEF CTF}
  // clear inventory
  memset(self->client->pers.inventory, 0, sizeof(self->client->pers.inventory));
{$ELSE}
  self.flags := self.flags AND (NOT FL_POWER_ARMOR);
{$ENDIF}

  if (self.health < -40)
  then begin
    // gib
    gi.sound (self, CHAN_BODY, gi.soundindex ('misc/udeath.wav'), 1, ATTN_NORM, 0);
    for n:=0 to 3 do
      ThrowGib (self, 'models/objects/gibs/sm_meat/tris.md2', damage, GIB_ORGANIC);
    ThrowClientHead (self, damage);

{$IFDEF CTF}  //onlyCTF
//ZOID
    self.client.anim_priority := ANIM_DEATH;
    self.client.anim_end := 0;
//ZOID
{$ENDIF}

    self.takedamage := DAMAGE_NO;
  end
  else begin
    // normal death
    if (!self.deadflag) then
    begin
//Y      i = (i+1)%3;
      i := (i+1) MOD 3;
      // start a death animation
      self.client.anim_priority := ANIM_DEATH;
      if (self->client->ps.pmove.pm_flags & PMF_DUCKED)
      then begin
        self.s.frame := FRAME_crdeath1-1;
        self.client.anim_end := FRAME_crdeath5;
      end
      else begin
        Case i of
          0: begin
               self.s.frame := FRAME_death101-1;
               self.client.anim_end := FRAME_death106;
             end;
          1: begin
               self.s.frame := FRAME_death201-1;
               self.client.anim_end := FRAME_death206;
             end;
          2: begin
               self.s.frame := FRAME_death301-1;
               self.client.anim_end := FRAME_death308;
             end;
        end;//case
      end;
      gi.sound (self, CHAN_VOICE, gi.soundindex(va('*death%i.wav', (rand()%4)+1)), 1, ATTN_NORM, 0);
    end;
  end;//else

  self.deadflag := DEAD_DEAD;

  gi.linkentity (self);
end;//procedure (GAME <> CTF)


//=======================================================================

{*
==============
InitClientPersistant

This is only called when the game first initializes in single player,
but is called after each death and level change in deathmatch
==============
*}
// (GAME <> CTF)
procedure InitClientPersistant (gclient_t *client);
var
   gitem_t      *item;
begin
  memset (&client->pers, 0, sizeof(client->pers));

  item := FindItem('Blaster');
  client.pers.selected_item := ITEM_INDEX(item);
  client.pers.inventory[client.pers.selected_item] := 1;

  client.pers.weapon := item;

{$IFDEF CTF}  //onlyCTF
//ZOID
  client.pers.lastweapon := item;

  item := FindItem('Grapple');
  client.pers.inventory[ITEM_INDEX(item)] := 1;
//ZOID
{$ENDIF}

  client.pers.health      := 100;
  client.pers.max_health   := 100;

  client.pers.max_bullets  := 200;
  client.pers.max_shells   := 100;
  client.pers.max_rockets  := 50;
  client.pers.max_grenades := 50;
  client.pers.max_cells    := 200;
  client.pers.max_slugs    := 50;

  client.pers.connected := true;
end;//procedure (GAME <> CTF)

// (GAME <> CTF)
procedure InitClientResp (gclient_t *client);
begin
{$IFDEF CTF}  //onlyCTF
//ZOID
  int ctf_team = client->resp.ctf_team;
  qboolean id_state = client->resp.id_state;
//ZOID
{$ENDIF}

  memset (&client->resp, 0, sizeof(client->resp));

{$IFDEF CTF}  //onlyCTF
//ZOID
  client.resp.ctf_team := ctf_team;
  client.resp.id_state := id_state;
//ZOID
{$ENDIF}

  client.resp.enterframe := level.framenum;
  client.resp.coop_respawn := client.pers;

{$IFDEF CTF}  //onlyCTF
//ZOID
  if (ctf->value && client->resp.ctf_team < CTF_TEAM1) then
    CTFAssignTeam(client);
//ZOID
{$ENDIF}
end;//procedure (GAME <> CTF)


{*
==================
SaveClientData

Some information that should be persistant, like health,
is still stored in the edict structure, so it needs to
be mirrored out to the client structure before all the
edicts are wiped.
==================
*}
// (GAME <> CTF)
procedure SaveClientData;
var
  i : integer;
   edict_t   *ent;
begin
  for i:=0 to game.maxclients-1 do
  begin
    ent = &g_edicts[1+i];
    if (!ent.inuse) then
      Continue;
    game.clients[i].pers.health := ent.health;
    game.clients[i].pers.max_health := ent.max_health;

{$IFDEF CTF}
    game.clients[i].pers.powerArmorActive := (ent.flags AND FL_POWER_ARMOR);
{$ELSE}
    game.clients[i].pers.savedFlags := (ent.flags AND (FL_GODMODE OR FL_NOTARGET OR FL_POWER_ARMOR));
{$ENDIF}

    if (coop.value) then
      game.clients[i].pers.score := ent.client.resp.score;
  end;//for
end;//procedure (GAME <> CTF)

// (GAME <> CTF)
procedure FetchClientEntData (edict_t *ent);
begin
  ent.health := ent.client.pers.health;
  ent.max_health := ent.client.pers.max_health;

{$IFDEF CTF}
  if (ent.client.pers.powerArmorActive) then
    ent.flags := ent.flags OR FL_POWER_ARMOR;
{$ELSE}
  ent.flags := ent.flags OR ent.client.pers.savedFlags;
{$ENDIF}

  if (coop.value) then
    ent.client.resp.score := ent.client.pers.score;
end;//procedure (GAME <> CTF)


{*
=======================================================================

  SelectSpawnPoint

=======================================================================
*}

{*
================
PlayersRangeFromSpot

Returns the distance to the nearest player from the given spot
================
*}
// (GAME=CTF)
function PlayersRangeFromSpot (edict_t *spot) : float;
var
   edict_t   *player;
  bestplayerdistance,
  playerdistance     : float;
  v : vec3_t;
  n : integer;
begin
  bestplayerdistance = 9999999;

  for n:=1 to maxclients.value do
  begin
    player = &g_edicts[n];

    if (!player.inuse) then
      Continue;

    if (player.health <= 0) then
      Continue;

    VectorSubtract (spot.s.origin, player.s.origin, v);
    playerdistance := VectorLength (v);

    if (playerdistance < bestplayerdistance) then
      bestplayerdistance := playerdistance;
  end;

  Result := bestplayerdistance;
end;//procedure (GAME=CTF)


{*
================
SelectRandomDeathmatchSpawnPoint

go to a random point, but NOT the two points closest
to other players
================
*}
// (GAME=CTF)
function SelectRandomDeathmatchSpawnPoint : edict_t;
var
   edict_t   *spot, *spot1, *spot2;
   int      count = 0;
  selection             : integer;
  range, range1, range2 : float;
begin
  spot = NULL;
//  range1 = range2 = 99999;
  range2 := 99999;
  range1 := range2;
  spot1 = spot2 = NULL;

//  while ((spot = G_Find (spot, FOFS(classname), 'info_player_deathmatch')) != NULL)
  spot := G_Find (spot, FOFS(classname), 'info_player_deathmatch'));
  while (spot <> Nil) do
  begin
    Inc(count);
    range := PlayersRangeFromSpot(spot);
    if (range < range1)
    then begin
      range1 := range;
      spot1 := spot;
    end
    else
      if (range < range2) then
      begin
        range2 := range;
        spot2 := spot;
      end;
  end;

  if (!count) then
  begin
    Result := Nil;
    Exit;
  end;

  if (count <= 2)
  then begin
         spot1 = spot2 = NULL;
  end
  else
    Dec (count, 2);

//  selection = rand() % count;
  selection := random(count);

  spot = NULL;
(*  do
  {
        spot = G_Find (spot, FOFS(classname), 'info_player_deathmatch');
        if (spot = spot1) OR (spot = spot2) then
                selection++;
  } while(selection--);
*)
  repeat
    spot := G_Find (spot, FOFS(classname), 'info_player_deathmatch');
    if (spot = spot1) OR (spot = spot2) then
      Inc(selection);

    Dec(selection);
  until selection=0; //C2Pas ???

  Result := spot;
end;//procedure (GAME=CTF)


{*
================
SelectFarthestDeathmatchSpawnPoint

================
*}
// (GAME=CTF)
function SelectFarthestDeathmatchSpawnPoint : edict_t;
var
   edict_t   *bestspot;
  bestdistance,
  bestplayerdistance : float;
   edict_t   *spot;
begin
  spot = NULL;
  bestspot = NULL;
  bestdistance := 0;
//  while ((spot = G_Find (spot, FOFS(classname), 'info_player_deathmatch')) != NULL)
  spot := G_Find (spot, FOFS(classname), 'info_player_deathmatch'));
  while (spot <> NULL) do
  begin
    bestplayerdistance := PlayersRangeFromSpot (spot);

    if (bestplayerdistance > bestdistance) then
    begin
      bestspot := spot;
      bestdistance := bestplayerdistance;
    end;
  end;

  if (bestspot) then
  begin
    Result := bestspot;
    Exit;
  end;

  // if there is a player just spawned on each and every start spot
  // we have no choice to turn one into a telefrag meltdown
  spot := G_Find (NULL, FOFS(classname), 'info_player_deathmatch');

  Result := spot;
end;//procedure (GAME=CTF)

// (GAME=CTF)
function SelectDeathmatchSpawnPoint : edict_t;
begin
  if ( (int)(dmflags->value) & DF_SPAWN_FARTHEST)
  then Result := SelectFarthestDeathmatchSpawnPoint ()
  else Result := SelectRandomDeathmatchSpawnPoint ();
end;//procedure (GAME=CTF)


// (GAME=CTF)
function SelectCoopSpawnPoint (edict_t *ent) : edict_t;
var
  index : integer;
   edict_t   *spot = NULL;
   char   *target;
begin
  index := ent.client - game.clients;

  // player 0 starts in normal player spawn point
  if (!index) then
  begin
    Result := NULL;
    Exit;
  end; 

  spot = NULL;

  // assume there are four coop spots at each spawnpoint
  while (1)
  begin
    spot := G_Find (spot, FOFS(classname), 'info_player_coop');
    if (!spot) then
    begin
      Result := NULL;  // we didn't have enough...
      Exit;
    end;  

    target := spot.targetname;
    if (!target) then
      target := '';
    if (Q_stricmp(game.spawnpoint, target) = 0) then
    begin
      // this is a coop spawn point for one of the clients here
      Dec(index);
      if (!index) then
      begin
        Result := spot;    // this is it
        Exit;
      end;  
    end;
  end;

  Result := spot;
end;//procedure (GAME=CTF)


{*
===========
SelectSpawnPoint

Chooses a player start, deathmatch start, coop start, etc
============
*}
// (GAME <> CTF)
procedure SelectSpawnPoint (edict_t *ent, vec3_t origin, vec3_t angles);
begin
  edict_t   *spot = NULL;

  if (deathmatch.value)
{$IFDEF CTF}
//ZOID
  then
    if (ctf.value)
    then spot := SelectCTFSpawnPoint(ent)
    else spot := SelectDeathmatchSpawnPoint ();
//ZOID
{$ELSE}
  then spot := SelectDeathmatchSpawnPoint ()
{$ENDIF}
  else
    if (coop.value) then
      spot := SelectCoopSpawnPoint (ent);

  // find a single player start spot
  if (!spot) then
  begin
//      while ((spot = G_Find (spot, FOFS(classname), 'info_player_start')) != NULL)
      spot := G_Find (spot, FOFS(classname), 'info_player_start');
      while (spot <> Nil) do
      begin
        if (!game.spawnpoint[0]) AND (!spot.targetname) then
          Break;

        if (!game.spawnpoint[0]) OR (!spot.targetname) then
          Continue;

        if (Q_stricmp(game.spawnpoint, spot.targetname) = 0) then
          Break;
      end;

      if (!spot) then
      begin
        if (!game.spawnpoint[0]) then
          // there wasn't a spawnpoint without a target, so use any
          spot := G_Find (spot, FOFS(classname), 'info_player_start');
        if (!spot) then
          gi.error ('Couldn"t find spawn point %s\n', game.spawnpoint);
      end;
  end;

  VectorCopy (spot.s.origin, origin);
  origin[2] := origin[2] +9;
  VectorCopy (spot.s.angles, angles);
end;//procedure (GAME <> CTF)


//======================================================================


// (GAME=CTF)
procedure InitBodyQue;
var
  i : integer;
   edict_t   *ent;
begin
  level.body_que = 0;
  for i:=0 to BODY_QUEUE_SIZE-1 do
  begin
    ent := G_Spawn();
    ent.classname := 'bodyque';
  end;
end;//procedure (GAME=CTF)

// (GAME=CTF)
procedure body_die (edict_t *self, edict_t *inflictor, edict_t *attacker, int damage, vec3_t point);
var
  n : integer;
begin
  if (self.health < -40) then
  begin
    gi.sound (self, CHAN_BODY, gi.soundindex ('misc/udeath.wav'), 1, ATTN_NORM, 0);
    for n:=0 to 3 do
      ThrowGib (self, 'models/objects/gibs/sm_meat/tris.md2', damage, GIB_ORGANIC);
    self.s.origin[2] := self.s.origin[2] -48;
    ThrowClientHead (self, damage);
    self.takedamage := DAMAGE_NO;
  end;
end;//procedure (GAME=CTF)

// (GAME=CTF)
procedure CopyToBodyQue (edict_t *ent);
var
   edict_t      *body;
begin
  // grab a body que and cycle to the next one
  body = &g_edicts[(int)maxclients->value + level.body_que + 1];
  level.body_que := (level.body_que + 1) MOD BODY_QUEUE_SIZE;

  // FIXME: send an effect on the removed body

  gi.unlinkentity (ent);

  gi.unlinkentity (body);
  body.s := ent.s;
  body.s.number := body - g_edicts;

  body.svflags := ent.svflags;
  VectorCopy (ent.mins, body.mins);
  VectorCopy (ent.maxs, body.maxs);
  VectorCopy (ent.absmin, body.absmin);
  VectorCopy (ent.absmax, body.absmax);
  VectorCopy (ent.size, body.size);
  body.solid := ent.solid;
  body.clipmask := ent.clipmask;
  body.owner := ent.owner;
  body.movetype := ent.movetype;

  body.die := body_die;
  body.takedamage := DAMAGE_YES;

  gi.linkentity (body);
end;//procedure (GAME=CTF)


// (GAME <> CTF)
procedure respawn (edict_t *self);
begin
  if (deathmatch.value OR coop.value) then
  begin
{$IFDEF CTF}
//Y: none comments
{$ELSE}
    // spectator's don't leave bodies
{$ENDIF}
    if (self.movetype <> MOVETYPE_NOCLIP) then
      CopyToBodyQue (self);
    self.svflags := self.svflags AND (NOT SVF_NOCLIENT);
    PutClientInServer (self);

    // add a teleportation effect
    self.s.event := EV_PLAYER_TELEPORT;

    // hold in place briefly
    self.client.ps.pmove.pm_flags := PMF_TIME_TELEPORT;
    self.client.ps.pmove.pm_time := 14;

    self.client.respawn_time := level.time;

    Exit;
  end;

  // restart the entire server
  gi.AddCommandString ('menu_loadgame\n');
end;//procedure (GAME <> CTF)


{$IFNDEF CTF}  //onlyGAME (noneCTF)
{*
 * only called when pers.spectator changes
 * note that resp.spectator should be the opposite of pers.spectator here
 *}
// (GAME <> CTF)
procedure spectator_respawn (edict_t *ent);
var
  i, numspec : integer;
begin
  // if the user wants to become a spectator, make sure he doesn't
  // exceed max_spectators

  if (ent.client.pers.spectator)
  then begin
    char *value := Info_ValueForKey (ent.client.pers.userinfo, 'spectator');
    if ( *spectator_password.string AND
         strcmp(spectator_password.string, 'none') AND
         strcmp(spectator_password.string, value) ) then
    begin
      gi.cprintf(ent, PRINT_HIGH, 'Spectator password incorrect.\n');
      ent.client.pers.spectator := false;
      gi.WriteByte (svc_stufftext);
      gi.WriteString ('spectator 0\n');
      gi.unicast(ent, true);
      Exit;
    end;

    // count spectators
//    for (i = 1, numspec = 0; i <= maxclients->value; i++)
    numspec := 0;
    for i:=1 to maxclients.value do
      if (g_edicts[i].inuse) AND (g_edicts[i].client.pers.spectator) then
        Inc(numspec);

    if (numspec >= maxspectators.value) then
    begin
      gi.cprintf(ent, PRINT_HIGH, 'Server spectator limit is full.');
      ent.client.pers.spectator := false;
      // reset his spectator var
      gi.WriteByte (svc_stufftext);
      gi.WriteString ('spectator 0\n');
      gi.unicast(ent, true);
      Exit;
    end;
  end
  else begin
    // he was a spectator and wants to join the game
    // he must have the right password
    char *value := Info_ValueForKey (ent->client->pers.userinfo, "password");
    if ( *password.string AND
         strcmp(password.string, 'none') AND
         strcmp(password.string, value) ) then
    begin
      gi.cprintf(ent, PRINT_HIGH, 'Password incorrect.\n');
      ent.client.pers.spectator := true;
      gi.WriteByte (svc_stufftext);
      gi.WriteString ('spectator 1\n');
      gi.unicast(ent, true);
      Exit;
    end;
  end;

  // clear score on respawn
//  ent->client->pers.score = ent->client->resp.score = 0;
  ent.client.resp.score := 0;
  ent.client.pers.score := ent.client.resp.score;

  ent.svflags := ent.svflags AND (NOT SVF_NOCLIENT);
  PutClientInServer (ent);

  // add a teleportation effect
  if (!ent.client.pers.spectator) then
  begin
    // send effect
    gi.WriteByte (svc_muzzleflash);
    gi.WriteShort (ent-g_edicts);
    gi.WriteByte (MZ_LOGIN);
    gi.multicast (ent.s.origin, MULTICAST_PVS);

    // hold in place briefly
    ent.client.ps.pmove.pm_flags := PMF_TIME_TELEPORT;
    ent.client.ps.pmove.pm_time := 14;
  end;

  ent.client.respawn_time := level.time;

  if (ent.client.pers.spectator)
  then gi.bprintf (PRINT_HIGH, '%s has moved to the sidelines\n', ent.client.pers.netname)
  else gi.bprintf (PRINT_HIGH, '%s joined the game\n', ent.client.pers.netname);
end;//procedure (GAME <> CTF)
{$ENDIF}

//==============================================================


{*
===========
PutClientInServer

Called when a player connects to a server or respawns in
a deathmatch.
============
*}
// (GAME <> CTF)
procedure PutClientInServer (edict_t *ent);
const
  mins : vec3_t = (-16, -16, -24);
  maxs : vec3_t = ( 16,  16,  32);
var
{Y}  index   : integer;
  spawn_origin,
  spawn_angles  : vec3_t;
   gclient_t                 *client;
  i, n          : integer;
   client_persistant_t   saved;
   client_respawn_t   resp;

    char      userinfo[MAX_INFO_STRING];

begin
  // find a spawn point
  // do it before setting health back up, so farthest
  // ranging doesn't count this client
  SelectSpawnPoint (ent, spawn_origin, spawn_angles);

{Y}  index := ent-g_edicts-1;
  client := ent.client;

  // deathmatch wipes most client data every spawn
  if (deathmatch.value)
  then begin
    resp := client.resp;
    memcpy (userinfo, client->pers.userinfo, sizeof(userinfo));
    InitClientPersistant (client);
    ClientUserinfoChanged (ent, userinfo);
  end
  else
    if (coop.value)
    then begin
      resp := client.resp;
      memcpy (userinfo, client->pers.userinfo, sizeof(userinfo));

{$IFDEF CTF}
      for n:=0 to MAX_ITEMS-1 do
        if (itemlist[n].flags & IT_KEY) then
          resp.coop_respawn.inventory[n] := client.pers.inventory[n];

{$ELSE}
      // this is kind of ugly, but it's how we want to handle keys in coop
(*idsoft
//      for (n = 0; n < game.num_items; n++)
//      {
//         if (itemlist[n].flags & IT_KEY)
//            resp.coop_respawn.inventory[n] = client->pers.inventory[n];
//      }
*)
      resp.coop_respawn.game_helpchanged := client.pers.game_helpchanged;
      resp.coop_respawn.helpchanged := client.pers.helpchanged;
{$ENDIF}

      client.pers := resp.coop_respawn;
      ClientUserinfoChanged (ent, userinfo);
      if (resp.score > client.pers.score) then
        client.pers.score := resp.score;
    end
    else
      memset (&resp, 0, sizeof(resp));

  // clear everything but the persistant data
  saved := client.pers;
  memset (client, 0, sizeof( *client));
  client.pers := saved;
  if (client.pers.health <= 0) then
    InitClientPersistant(client);
  client.resp := resp;

  // copy some data from the client to the entity
  FetchClientEntData (ent);

  // clear entity values
  ent.groundentity = NULL;
  ent.client = &game.clients[index];
  ent.takedamage := DAMAGE_AIM;
  ent.movetype := MOVETYPE_WALK;
  ent.viewheight := 22;
  ent.inuse := true;
  ent.classname = 'player';
  ent.mass := 200;
  ent.solid := SOLID_BBOX;
  ent.deadflag := DEAD_NO;
  ent.air_finished := level.time + 12;
  ent.clipmask := MASK_PLAYERSOLID;
  ent.model := 'players/male/tris.md2';
  ent.pain := player_pain;
  ent.die := player_die;
  ent.waterlevel := 0;
  ent.watertype := 0;
  ent.flags := ent.flags AND (NOT FL_NO_KNOCKBACK);
  ent.svflags := ent.svflags AND (NOT SVF_DEADMONSTER);

  VectorCopy (mins, ent.mins);
  VectorCopy (maxs, ent.maxs);
  VectorClear (ent.velocity);

  // clear playerstate values
  memset (&ent->client->ps, 0, sizeof(client->ps));

  client.ps.pmove.origin[0] := spawn_origin[0]*8;
  client.ps.pmove.origin[1] := spawn_origin[1]*8;
  client.ps.pmove.origin[2] := spawn_origin[2]*8;

{$IFDEF CTF}  //onlyCTF
//ZOID
  client.ps.pmove.pm_flags := client.ps.pmove.pm_flags AND (NOT PMF_NO_PREDICTION);
//ZOID
{$ENDIF}

  if (deathmatch->value && ((int)dmflags->value & DF_FIXED_FOV))
  then client.ps.fov := 90
  else begin
    client.ps.fov := atoi(Info_ValueForKey(client.pers.userinfo, 'fov'));
    if (client.ps.fov < 1)
    then client.ps.fov := 90
    else
      if (client.ps.fov > 160) then
        client.ps.fov := 160;
  end;

  client.ps.gunindex := gi.modelindex(client.pers.weapon.view_model);

  // clear entity state values
  ent.s.effects := 0;

{$IFDEF CTF}  //onlyCTF
  ent.s.skinnum := ent - g_edicts - 1;
{$ENDIF}

  ent.s.modelindex := 255;      // will use the skin specified model
  ent.s.modelindex2 := 255;      // custom gun model
  // sknum is player num and weapon number
  // weapon number will be added in changeweapon
  ent.s.skinnum := ent - g_edicts - 1;

  ent.s.frame := 0;
  VectorCopy (spawn_origin, ent.s.origin);
  ent.s.origin[2] := ent.s.origin[2] +1;   // make sure off ground
  VectorCopy (ent.s.origin, ent.s.old_origin);

  // set the delta angle
  for i:=0 to 2 do
    client.ps.pmove.delta_angles[i] := ANGLE2SHORT(spawn_angles[i] - client.resp.cmd_angles[i]);

  ent.s.angles[PITCH] := 0;
  ent.s.angles[YAW] := spawn_angles[YAW];
  ent.s.angles[ROLL] := 0;
  VectorCopy (ent.s.angles, client.ps.viewangles);
  VectorCopy (ent.s.angles, client.v_angle);

{$IFDEF CTF}
//ZOID
  if (CTFStartClient(ent)) then
    Exit;
//ZOID
{$ELSE}
  // spawn a spectator
  if (client.pers.spectator)
  then begin
    client.chase_target := NULL;

    client.resp.spectator := true;

    ent.movetype := MOVETYPE_NOCLIP;
    ent.solid := SOLID_NOT;
    ent.svflags := ent.svflags OR SVF_NOCLIENT;
    ent.client.ps.gunindex := 0;
    gi.linkentity (ent);
    Exit;
  else
    client.resp.spectator := false;
{$ENDIF}

  if (!KillBox (ent))
  {   // could't spawn in?
  }

  gi.linkentity (ent);

  // force the current weapon up
  client.newweapon := client.pers.weapon;
  ChangeWeapon (ent);
end;//procedure (GAME <> CTF)


{*
=====================
ClientBeginDeathmatch

A client has just connected to the server in
deathmatch mode, so clear everything out before starting them.
=====================
*}
// (GAME=CTF)
procedure ClientBeginDeathmatch (edict_t *ent)
begin
  G_InitEdict (ent);

  InitClientResp (ent.client);

  // locate ent at a spawn point
  PutClientInServer (ent);

  // send effect
  gi.WriteByte (svc_muzzleflash);
  gi.WriteShort (ent-g_edicts);
  gi.WriteByte (MZ_LOGIN);
  gi.multicast (ent.s.origin, MULTICAST_PVS);

  gi.bprintf (PRINT_HIGH, '%s entered the game\n', ent.client.pers.netname);

  // make sure all view stuff is valid
  ClientEndServerFrame (ent);
end;//procedure (GAME=CTF)


{*
===========
ClientBegin

called when a client has finished connecting, and is ready
to be placed into the game.  This will happen every level load.
============
*}
// (GAME=CTF)
procedure ClientBegin (edict_t *ent)
var
  i : integer;
begin
  ent.client := game.clients + (ent - g_edicts - 1);

  if (deathmatch.value) then
  begin
    ClientBeginDeathmatch (ent);
    Exit;
  end;

  // if there is already a body waiting for us (a loadgame), just
  // take it, otherwise spawn one from scratch
  if (ent.inuse = true)
  then begin
    // the client has cleared the client side viewangles upon
    // connecting to the server, which is different than the
    // state when the game is saved, so we need to compensate
    // with deltaangles
    for i:=0 to 2 do
      ent.client.ps.pmove.delta_angles[i] := ANGLE2SHORT(ent.client.ps.viewangles[i]);
  end
  else begin
    // a spawn point will completely reinitialize the entity
    // except for the persistant data that was initialized at
    // ClientConnect() time
    G_InitEdict (ent);
    ent.classname := 'player';
    InitClientResp (ent.client);
    PutClientInServer (ent);
  end;

  if (level.intermissiontime)
  then MoveClientToIntermission (ent)
  else
    // send effect if in a multiplayer game
    if (game.maxclients > 1) then
    begin
      gi.WriteByte (svc_muzzleflash);
      gi.WriteShort (ent-g_edicts);
      gi.WriteByte (MZ_LOGIN);
      gi.multicast (ent.s.origin, MULTICAST_PVS);

      gi.bprintf (PRINT_HIGH, '%s entered the game\n', ent.client.pers.netname);
    end;

  // make sure all view stuff is valid
  ClientEndServerFrame (ent);
end;//procedure (GAME=CTF)


{*
===========
ClientUserInfoChanged

called whenever the player updates a userinfo variable.

The game can override any of the settings in place
(forcing skins or names, etc) before copying it off.
============
*}
// (GAME <> CTF)
procedure ClientUserinfoChanged (edict_t *ent, char *userinfo);
var
   char   *s;
{Y}  playernum : integer;
begin
  // check for malformed or illegal info strings
  if (!Info_Validate(userinfo)) then
          strcpy (userinfo, '\\name\\badinfo\\skin\\male/grunt');

  // set name
  s := Info_ValueForKey (userinfo, 'name');
  strncpy (ent->client->pers.netname, s, sizeof(ent->client->pers.netname)-1);

{$IFNDEF CTF}  //onlyGAME (noneCTF)
  // set spectator
  s := Info_ValueForKey (userinfo, 'spectator');
  // spectators are only supported in deathmatch
  if (deathmatch->value && *s && strcmp(s, '0'))
  then ent.client.pers.spectator := true;
  else ent.client.pers.spectator := false;
{$ENDIF}

  // set skin
  s := Info_ValueForKey (userinfo, 'skin');

{Y}  playernum := ent-g_edicts-1;

  // combine name and skin into a configstring
{$IFDEF CTF}  //onlyCTF
//ZOID
  if (ctf.value)
  then CTFAssignSkin(ent, s)
  else
//ZOID
{$ENDIF}
    gi.configstring (CS_PLAYERSKINS+playernum, va('%s\\%s', ent.client.pers.netname, s));

  // fov
  if (deathmatch->value && ((int)dmflags->value & DF_FIXED_FOV))
  then ent.client.ps.fov := 90
  else begin
    ent.client.ps.fov := atoi(Info_ValueForKey(userinfo, 'fov'));
    if (ent.client.ps.fov < 1)
    then ent.client.ps.fov := 90;
    else
      if (ent.client.ps.fov > 160) then
       ent.client.ps.fov := 160;
  end;

  // handedness
  s := Info_ValueForKey (userinfo, 'hand');
  if (strlen(s)) then
    ent.client.pers.hand := atoi(s);

  // save off the userinfo in case we want to check something later
  strncpy (ent->client->pers.userinfo, userinfo, sizeof(ent->client->pers.userinfo)-1);
end;//procedure (GAME <> CTF)


{*
===========
ClientConnect

Called when a player begins connecting to the server.
The game can refuse entrance to a client by returning false.
If the client is allowed, the connection process will continue
and eventually get to ClientBegin()
Changing levels will NOT cause this to be called again, but
loadgames will.
============
*}
// (GAME <> CTF)
function ClientConnect (edict_t *ent, char *userinfo) : qboolean;
var
   char   *value;
          int i, numspec;
begin
  // check to see if they are on the banned IP list
  value := Info_ValueForKey (userinfo, 'ip');

{$IFТDEF CTF}  //onlyGAME (noneCTF)
  if (SV_FilterPacket(value))
  then begin
    Info_SetValueForKey (userinfo, 'rejmsg', 'Banned.');
    Result := false;
    Exit;
  end;

  // check for a spectator
  value := Info_ValueForKey (userinfo, 'spectator');
  if (deathmatch->value && *value && strcmp(value, '0'))
  then begin
    if ( *spectator_password.string AND
         strcmp(spectator_password.string, 'none') AND
         strcmp(spectator_password.string, value))
    then begin
      Info_SetValueForKey(userinfo, 'rejmsg', 'Spectator password required or incorrect.');
      Result := false;
      Exit;
    end;

    // count spectators
//    for (i = numspec = 0; i < maxclients->value; i++)
    numspec := 0;
    for i:=0 to maxclients.value-1 do
      if (g_edicts[i+1].inuse) AND (g_edicts[i+1].client.pers.spectator) then
        Inc(numspec);

    if (numspec >= maxspectators.value) then
    begin
      Info_SetValueForKey(userinfo, 'rejmsg', 'Server spectator limit is full.');
      Result := false;
      Exit;
    end;
  end
  else begin
{$ENDIF}
    // check for a password
    value := Info_ValueForKey (userinfo, 'password');
    if ( *password.string AND
         strcmp(password.string, 'none') AND
         strcmp(password.string, value))
    then begin
      Info_SetValueForKey(userinfo, 'rejmsg', 'Password required or incorrect.');
      Result := false;
      Exit;
    end;
//смотри условие ВЫШЕ
{$IFDEF CTF}
{$ELSE}
  end;//else
{$ENDIF}


  // they can connect
  ent.client := game.clients + (ent - g_edicts - 1);

  // if there is already a body waiting for us (a loadgame), just
  // take it, otherwise spawn one from scratch
  if (ent.inuse = false) then
  begin
    // clear the respawning variables

{$IFDEF CTF}  //onlyCTF
//ZOID -- force team join
    ent.client.resp.ctf_team := -1;
    ent.client.resp.id_state := false;
//ZOID
{$ENDIF}

    InitClientResp (ent.client);
    if (!game.autosaved) OR (!ent.client.pers.weapon) then
     InitClientPersistant (ent.client);
  end;

  ClientUserinfoChanged (ent, userinfo);

  if (game.maxclients > 1) then
    gi.dprintf ('%s connected\n', ent.client.pers.netname);

  ent.client.pers.connected := true;
  Result := true;
end;//procedure (GAME <> CTF)


{*
===========
ClientDisconnect

Called when a player drops from the server.
Will not be called between levels.
============
*}
// (GAME <> CTF)
procedure ClientDisconnect (edict_t *ent);
var
   int      playernum;
begin
  if (!ent.client) then
    Exit;

  gi.bprintf (PRINT_HIGH, '%s disconnected\n', ent.client.pers.netname);

{$IFDEF CTF}  //onlyCTF
//ZOID
  CTFDeadDropFlag(ent);
  CTFDeadDropTech(ent);
//ZOID
{$ENDIF}

  // send effect
  gi.WriteByte (svc_muzzleflash);
  gi.WriteShort (ent-g_edicts);
  gi.WriteByte (MZ_LOGOUT);
  gi.multicast (ent.s.origin, MULTICAST_PVS);

  gi.unlinkentity (ent);
  ent.s.modelindex := 0;
  ent.solid := SOLID_NOT;
  ent.inuse := false;
  ent.classname := 'disconnected';
  ent.client.pers.connected := false;

  playernum := ent-g_edicts-1;
  gi.configstring (CS_PLAYERSKINS+playernum, '');
end;//procedure (GAME <> CTF)


//==============================================================


edict_t   *pm_passent;

// pmove doesn't need to know about passent and contentmask
// (GAME=CTF)
function PM_trace (vec3_t start, vec3_t mins, vec3_t maxs, vec3_t end_) : trace_t;
begin
  if (pm_passent.health > 0)
  then Result := gi.trace (start, mins, maxs, end_, pm_passent, MASK_PLAYERSOLID)
  else Result := gi.trace (start, mins, maxs, end_, pm_passent, MASK_DEADSOLID);
end;//procedure (GAME=CTF)


// (GAME=CTF)
unsigned CheckBlock (void *b, int c)
var
  v, i : integer;
begin
  v := 0;
  for i:=0 to c-1 do
//    v+= ((byte *)b)[i];
    Inc(v, b[i]);
  Result := v;
end;//procedure (GAME=CTF)

// (GAME=CTF)
procedure PrintPmove (pmove_t *pm);
var
   unsigned   c1, c2;
begin
  c1 := CheckBlock (&pm.s,   sizeof(pm.s));
  c2 := CheckBlock (&pm.cmd, sizeof(pm.cmd));
  Com_Printf ('sv %3i:%i %i\n', pm.cmd.impulse, c1, c2);
end;//procedure (GAME=CTF)


// (GAME <> CTF)
{*
==============
ClientThink

This will be called once for each client frame, which will
usually be a couple times for each server frame.
==============
*}
procedure ClientThink (edict_t *ent, usercmd_t *ucmd);
var
   gclient_t   *client;
   edict_t   *other;
  i, j : integer;
   pmove_t   pm;
begin
  level.current_entity := ent;
  client := ent.client;

  if (level.intermissiontime) then
  begin
    client.ps.pmove.pm_type := PM_FREEZE;
    // can exit intermission after five seconds
    if (level.time > level.intermissiontime + 5.0) AND
       (ucmd->buttons & BUTTON_ANY) then
       level.exitintermission := true;
    Exit;
  end;

  pm_passent := ent;

  if (ent.client.chase_target) then
  begin
    client.resp.cmd_angles[0] := SHORT2ANGLE( ucmd.angles[0]);
    client.resp.cmd_angles[1] := SHORT2ANGLE (ucmd.angles[1]);
    client.resp.cmd_angles[2] := SHORT2ANGLE (ucmd.angles[2]);

{$IFDEF CTF}
//ZOID
    Exit;
  end;
{$ELSE}
  end
  else begin
{$ENDIF}

    // set up for pmove
    memset (&pm, 0, sizeof(pm));

    if (ent.movetype = MOVETYPE_NOCLIP)
    then client.ps.pmove.pm_type := PM_SPECTATOR
    else
      if (ent.s.modelindex <> 255)
      then client.ps.pmove.pm_type := PM_GIB
      else
        if (ent.deadflag)
        then client.ps.pmove.pm_type := PM_DEAD
        else client.ps.pmove.pm_type := PM_NORMAL;

    client.ps.pmove.gravity := sv_gravity.value;
    pm.s := client.ps.pmove;

    for i:=0 to 2 do
    begin
      pm.s.origin[i] := ent.s.origin[i]*8;
      pm.s.velocity[i] := ent.velocity[i]*8;
    end;

    if (memcmp(&client->old_pmove, &pm.s, sizeof(pm.s))) then
    begin
      pm.snapinitial := true;
//idsoft   gi.dprintf ("pmove changed!\n");
    end;

    pm.cmd = *ucmd;

    pm.trace := PM_trace;   // adds default parms
    pm.pointcontents := gi.pointcontents;

    // perform a pmove
    gi.Pmove (&pm);

    // save results of pmove
    client.ps.pmove := pm.s;
    client.old_pmove := pm.s;

    for i:=0 to 2 do
    begin
      ent.s.origin[i] := pm.s.origin[i]*0.125;
      ent.velocity[i] := pm.s.velocity[i]*0.125;
    end;

    VectorCopy (pm.mins, ent.mins);
    VectorCopy (pm.maxs, ent.maxs);

    client.resp.cmd_angles[0] := SHORT2ANGLE (ucmd.angles[0]);
    client.resp.cmd_angles[1] := SHORT2ANGLE (ucmd.angles[1]);
    client.resp.cmd_angles[2] := SHORT2ANGLE (ucmd.angles[2]);

    if (ent.groundentity) AND (!pm.groundentity) AND (pm.cmd.upmove >= 10) AND (pm.waterlevel = 0)) then
    begin
      gi.sound (ent, CHAN_VOICE, gi.soundindex('*jump1.wav'), 1, ATTN_NORM, 0);
      PlayerNoise (ent, ent.s.origin, PNOISE_SELF);
    end;

    ent.viewheight := pm.viewheight;
    ent.waterlevel := pm.waterlevel;
    ent.watertype := pm.watertype;
    ent.groundentity := pm.groundentity;
    if (pm.groundentity) then
      ent.groundentity_linkcount := pm.groundentity.linkcount;

    if (ent.deadflag)
    then begin
      client.ps.viewangles[ROLL] := 40;
      client.ps.viewangles[PITCH] := -15;
      client.ps.viewangles[YAW] := client.killer_yaw;
    end
    else begin
      VectorCopy (pm.viewangles, client.v_angle);
      VectorCopy (pm.viewangles, client.ps.viewangles);
    end;

{$IFDEF CTF}  //onlyCTF
//ZOID
  if (client.ctf_grapple) then
    CTFGrapplePull(client.ctf_grapple);
//ZOID
{$ENDIF}

  gi.linkentity (ent);

  if (ent.movetype <> MOVETYPE_NOCLIP) then
    G_TouchTriggers (ent);

  // touch other objects
  for i:=0 to pm.numtouch-1 do
  begin
    other := pm.touchents[i];
    for j:=0 to i-1 do
      if (pm.touchents[j] = other) then
        Break;
    if (j <> i) then
      Continue;  // duplicated
    if (!other.touch) then
      Continue;
    other.touch (other, ent, NULL, NULL);
  end;

//смотри условие ВЫШЕ
{$IFDEF CTF}
{$ELSE}
  end;//else
{$ENDIF}

  client.oldbuttons := client.buttons;
  client.buttons := ucmd.buttons;
  client.latched_buttons := client.latched_buttons OR (client.buttons AND (NOT client.oldbuttons));

  // save light level the player is standing on for
  // monster sighting AI
  ent.light_level := ucmd.lightlevel;

  // fire weapon from final position if needed
{$IFDEF CTF}
  if (client->latched_buttons & BUTTON_ATTACK
//ZOID
          && ent->movetype != MOVETYPE_NOCLIP
//ZOID
     )
  then
    if (!client.weapon_thunk) then
    begin
      client.weapon_thunk := true;
      Think_Weapon (ent);
    end;
{$ELSE}
  if (client->latched_buttons & BUTTON_ATTACK)
  then
    if (client.resp.spectator)
    then begin
      client.latched_buttons := 0;

      if (client.chase_target)
      then begin
        client.chase_target := NULL;
        client.ps.pmove.pm_flags := client.ps.pmove.pm_flags AND (NOT PMF_NO_PREDICTION);
      end
      else
        GetChaseTarget(ent);
    end
    else
      if (!client.weapon_thunk) then
      begin
        client.weapon_thunk := true;
        Think_Weapon (ent);
      end;
{$ENDIF}


{$IFDEF CTF}
//ZOID
//regen tech
  CTFApplyRegeneration(ent);
//ZOID

//ZOID
  for i:=1 to maxclients.value do
  begin
    other := g_edicts + i;
    if (other.inuse) AND (other.client.chase_target = ent) then
      UpdateChaseCam(other);
  end;

  if (client.menudirty) AND (client.menutime <= level.time) then
  begin
    PMenu_Do_Update(ent);
    gi.unicast (ent, true);
    client.menutime := level.time;
    client.menudirty := false;
  end;
//ZOID
{$ELSE}
  if (client.resp.spectator) then
    if (ucmd.upmove >= 10)
    then
      if (!(client->ps.pmove.pm_flags & PMF_JUMP_HELD)) then
      begin
        client.ps.pmove.pm_flags := client.ps.pmove.pm_flags OR PMF_JUMP_HELD;
        if (client.chase_target)
        then ChaseNext(ent)
        else GetChaseTarget(ent);
      end
    else
      client.ps.pmove.pm_flags := client.ps.pmove.pm_flags AND (NOT PMF_JUMP_HELD);

  // update chase cam if being followed
  for i:=1 to maxclients.value do
  begin
    other = g_edicts + i;
    if (other.inuse) AND (other.client.chase_target = ent) then
      UpdateChaseCam(other);
  end;
{$ENDIF}
end;//procedure (GAME <> CTF)


{*
==============
ClientBeginServerFrame

This will be called once for each server frame, before running
any other entities in the world.
==============
*}
// (GAME <> CTF)
procedure ClientBeginServerFrame (edict_t *ent);
var
   gclient_t   *client;
  buttonMask : integer;
begin
  if (level.intermissiontime) then
    Exit;

  client := ent.client;


{$IFDEF CTF}
  // run weapon animations if it hasn't been done by a ucmd_t
  if (!client->weapon_thunk
//ZOID
          && ent->movetype != MOVETYPE_NOCLIP
//ZOID
          )
  then Think_Weapon (ent)
  else client.weapon_thunk := false;
{$ELSE}
  if (deathmatch.value) AND
     (client.pers.spectator <> client.resp.spectator) AND
     ((level.time - client.respawn_time) >= 5) then
  begin
    spectator_respawn(ent);
    Exit;
  end;

  // run weapon animations if it hasn't been done by a ucmd_t
  if (!client.weapon_thunk) AND (!client.resp.spectator)
  then Think_Weapon (ent)
  else client.weapon_thunk := false;
{$ENDIF}


  if (ent.deadflag) then
  begin
    // wait for any button just going down
    if (level.time > client.respawn_time) then
    begin
      // in deathmatch, only wait for attack button
      if (deathmatch.value)
      then buttonMask := BUTTON_ATTACK
      else buttonMask := -1;

{$IFDEF CTF}
      if ( (client->latched_buttons & buttonMask) ||
           (deathmatch->value && ((int)dmflags->value & DF_FORCE_RESPAWN)) ||
           CTFMatchOn() ) then
{$ELSE}
      if ( (client->latched_buttons & buttonMask) ||
           (deathmatch->value && ((int)dmflags->value & DF_FORCE_RESPAWN)) ) then
{$ENDIF}
      begin
        respawn(ent);
        client.latched_buttons := 0;
      end;
    end;
    Exit;
  end;

  // add player trail so monsters can follow
  if (!deathmatch.value) then
    if (!visible (ent, PlayerTrail_LastSpot())) then
      PlayerTrail_Add (ent.s.old_origin);

  client.latched_buttons := 0;
end;//procedure (GAME <> CTF)

// End of file


My current problems:
--------------------
1)   stricmp()
   Q_stricmp()    --> q_shared.c

2) all "if"

3) OK!

