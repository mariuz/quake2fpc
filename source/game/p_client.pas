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


//98% Reviewed
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
{ Updated on :  2003-05-09                                                   }
{ Updated by :  Scott Price                                                  }
{                                                                            }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{ x)                                                                         }
{                                                                            }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{ 1) Not all CTF Sections tested or altered                                  }
{                                                                            }
{----------------------------------------------------------------------------}


unit p_client;

interface

uses
  q_shared,
  g_local_add,
  GameUnit;

procedure SP_info_player_start (self : edict_p); cdecl;
procedure SP_info_player_deathmatch (self : edict_p); cdecl;
procedure SP_info_player_coop (self : edict_p); cdecl;
procedure SP_info_player_intermission(self : edict_p); cdecl;

procedure player_die (self, inflictor, attacker : edict_p; damage : integer; const point : vec3_t); cdecl;//a few files
procedure SaveClientData; //a few files

procedure InitBodyQue; //g_spawn

procedure ClientBeginServerFrame (ent : edict_p); cdecl;
procedure ClientBegin (ent : edict_p); cdecl; //g_main
procedure ClientUserinfoChanged (ent : edict_p; userinfo : PChar); cdecl; //g_main
function  ClientConnect (ent : edict_p; userinfo : PChar) : qboolean; cdecl; //g_main
procedure ClientDisconnect (ent : edict_p); cdecl; //g_main

procedure ClientThink (ent : edict_p; ucmd : usercmd_p); cdecl;

procedure respawn (self : edict_p);

implementation

uses
  p_weapon,
  g_utils,
  g_save,
  g_main,
  g_misc,
  g_items,
  p_hud,
  p_view,
  q_shared_add,
  CPas,
  game_add,
  g_local,
  m_player,
  g_svcmds,
  SysUtils,
  g_chase,
  g_ai,
  p_trail,
  math;


{$IFNDEF CTF}
  procedure PutClientInServer (ent : edict_p); forward; //INTERFACE: only g_ctf
{$ENDIF}


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

procedure SP_FixCoopSpots (self : edict_p); cdecl;
var
  spot : edict_p;
  d : vec3_t;
begin
  spot := Nil;

  while True do
  begin
    spot := G_Find(spot, FOFS_classname, 'info_player_start');
    if (spot = Nil) then
      Exit;
    if (spot^.targetname = '') then
      Continue;
    VectorSubtract(self^.s.origin, spot^.s.origin, d);
    if (VectorLength(d) < 384) then
    begin
      if ( (Self^.targetname = nil) or (Q_stricmp(Self^.targetname, spot^.targetname) <> 0)) then
      begin
//idsoft   gi.dprintf("FixCoopSpots changed %s at %s targetname from %s to %s\n", self->classname, vtos(self->s.origin), self->targetname, spot->targetname);
        self^.targetname := spot^.targetname;
      end;
      Exit;
    end;
  end;
end;


// now if that one wasn't ugly enough for you then try this one on for size
// some maps don't have any coop spots at all, so we need to create them
// where they should have been

procedure SP_CreateCoopSpots (self : edict_p); cdecl;
var
  spot : edict_p;
begin
  if (Q_stricmp(level.mapname, 'security') = 0) then
  begin
    spot := G_Spawn();
    spot^.classname := 'info_player_coop';
    spot^.s.origin[0] := 188 - 64;
    spot^.s.origin[1] := -164;
    spot^.s.origin[2] := 80;
    spot^.targetname := 'jail3';
    spot^.s.angles[1] := 90;

    spot := G_Spawn();
    spot^.classname := 'info_player_coop';
    spot^.s.origin[0] := 188 + 64;
    spot^.s.origin[1] := -164;
    spot^.s.origin[2] := 80;
    spot^.targetname := 'jail3';
    spot^.s.angles[1] := 90;

    spot := G_Spawn();
    spot^.classname := 'info_player_coop';
    spot^.s.origin[0] := 188 + 128;
    spot^.s.origin[1] := -164;
    spot^.s.origin[2] := 80;
    spot^.targetname := 'jail3';
    spot^.s.angles[1] := 90;

    Exit;
  end;
end;


{*QUAKED info_player_start (1 0 0) (-16 -16 -24) (16 16 32)
The normal starting point for a level.
*}
procedure SP_info_player_start (self : edict_p);  //g_spawn
begin
  if (coop^.value = 0) then
    Exit;
  if (Q_stricmp(level.mapname, 'security') = 0) then
  begin
    // invoke one of our gross, ugly, disgusting hacks
    self^.think := SP_CreateCoopSpots;
    self^.nextthink := level.time + FRAMETIME;
  end;
end;


{*QUAKED info_player_deathmatch (1 0 1) (-16 -16 -24) (16 16 32)
potential spawning position for deathmatch games
*}
procedure SP_info_player_deathmatch (self : edict_p);  //g_spawn
begin
  if (deathmatch^.value = 0) then
  begin
    G_FreeEdict (self);
    Exit;
  end;
  SP_misc_teleporter_dest (self);
end;


{*QUAKED info_player_coop (1 0 1) (-16 -16 -24) (16 16 32)
potential spawning position for coop games
*}

procedure SP_info_player_coop (self : edict_p);  //g_spawn
begin
  if (coop^.value = 0) then
  begin
    G_FreeEdict (self);
    Exit;
  end;

  if((Q_stricmp(level.mapname, 'jail2') = 0)   or
     (Q_stricmp(level.mapname, 'jail4') = 0)   or
     (Q_stricmp(level.mapname, 'mine1') = 0)   or
     (Q_stricmp(level.mapname, 'mine2') = 0)   or
     (Q_stricmp(level.mapname, 'mine3') = 0)   or
     (Q_stricmp(level.mapname, 'mine4') = 0)   or
     (Q_stricmp(level.mapname, 'lab') = 0)     or
     (Q_stricmp(level.mapname, 'boss1') = 0)   or
     (Q_stricmp(level.mapname, 'fact3') = 0)   or
     (Q_stricmp(level.mapname, 'biggun') = 0)  or
     (Q_stricmp(level.mapname, 'space') = 0)   or
     (Q_stricmp(level.mapname, 'command') = 0) or
     (Q_stricmp(level.mapname, 'power2') = 0) or
     (Q_stricmp(level.mapname, 'strike') = 0)) then
  begin
    // invoke one of our gross, ugly, disgusting hacks
    self^.think := SP_FixCoopSpots;
    self^.nextthink := level.time + FRAMETIME;
  end;
end;


{*QUAKED info_player_intermission (1 0 1) (-16 -16 -24) (16 16 32)
The deathmatch intermission point will be at one of these
Use 'angles' instead of 'angle', so you can set pitch or roll as well as yaw.  'pitch yaw roll'
*}
procedure SP_info_player_intermission(self : edict_p);   //g_spawn
begin
end;


//=======================================================================


procedure player_pain (self, other : edict_p; kick : single; damage : integer); cdecl;
begin
  // player pain is handled at the end of the frame in P_DamageFeedback
end;




function IsFemale (ent : edict_p) : qboolean; //only imp
var
  info : PChar;
begin
  if (ent^.client = Nil) then
  begin
    Result := false;
    Exit;
  end;

  info := Info_ValueForKey (ent^.client^.pers.userinfo, 'gender');
  if (info[0] = 'f') OR (info[0] = 'F') then
  begin
    Result := true;
    Exit;
  end;
  Result := false;
end;


{$IFNDEF CTF}  //onlyGAME (none CTF)
function IsNeutral (ent : edict_p) : qboolean; //only imp
var
  info : PChar;
begin
  if (ent^.client = Nil) then
  begin
    Result := false;
    Exit;
  end;

  info := Info_ValueForKey (ent^.client^.pers.userinfo, 'gender');
  if (info[0] <> 'f') and (info[0] <> 'F') and (info[0] <> 'm') and (info[0] <> 'M') then
  begin
    Result := true;
    Exit;
  end;
  Result := false;
end;
{$ENDIF}


procedure ClientObituary (self, inflictor, attacker : edict_p); //only imp
var
  mod_ : integer;
  _message,
  message2 : PChar;
  ff   : qboolean;
begin
  if (coop^.value <> 0) AND (attacker^.client <> Nil) then
    meansOfDeath := meansOfDeath OR MOD_FRIENDLY_FIRE;

  if (deathmatch^.value <> 0) OR (coop^.value <> 0) then
  begin
    ff := (meansOfDeath AND MOD_FRIENDLY_FIRE) <> 0;
    mod_ := meansOfDeath AND (NOT MOD_FRIENDLY_FIRE);
    _message := Nil;  //Nil _OR_ ''
    message2 := '';

    Case mod_ of
      MOD_SUICIDE:       _message := 'suicides';
      MOD_FALLING:       _message := 'cratered';
      MOD_CRUSH:         _message := 'was squished';
      MOD_WATER:         _message := 'sank like a rock';
      MOD_SLIME:         _message := 'melted';
      MOD_LAVA:          _message := 'does a back flip into the lava';
      MOD_EXPLOSIVE,
      MOD_BARREL:        _message := 'blew up';
      MOD_EXIT:          _message := 'found a way out';
      MOD_TARGET_LASER:  _message := 'saw the light';
      MOD_TARGET_BLASTER:_message := 'got blasted';
      MOD_BOMB,
      MOD_SPLASH,
      MOD_TRIGGER_HURT:  _message := 'was in the wrong place';
    end;
    if (attacker = self) then
    begin
      Case mod_ of
        MOD_HELD_GRENADE: _message := 'tried to put the pin back in';
        MOD_HG_SPLASH,
        MOD_G_SPLASH:     begin
                            if IsNeutral(Self) then
                              _message := 'tripped on its own grenade'
                            else if IsFemale(Self) then
                              _message := 'tripped on her own grenade'
                            else
                              _message := 'tripped on his own grenade';
                          end;
        MOD_R_SPLASH:     begin
                            if IsNeutral(Self) then
                              _message := 'blew itself up'
                            else if IsFemale(Self) then
                              _message := 'blew herself up'
                            else
                              _message := 'blew himself up';
                          end;

        MOD_BFG_BLAST:    _message := 'should have used a smaller gun';
      else
        if IsNeutral(Self) then
          _message := 'killed itself'
        else if IsFemale(Self) then
          _message := 'killed herself'
        else
          _message := 'killed himself';
      end;
    end;
    if (_message <> nil) then
    begin
      gi.bprintf (PRINT_MEDIUM, '%s %s.'#10, self^.client^.pers.netname, _message);
      if (deathmatch^.value <> 0) then
        Dec(self^.client^.resp.score);
      self^.enemy := Nil;
      Exit;
    end;

    self^.enemy := attacker;
    if (attacker <> Nil) AND (attacker^.client <> Nil) then
    begin
      Case mod_ of
        MOD_BLASTER:    _message := 'was blasted by';
        MOD_SHOTGUN:    _message := 'was gunned down by';
        MOD_SSHOTGUN:   begin
                          _message := 'was blown away by';
                          message2 := '''s super shotgun';
                        end;
        MOD_MACHINEGUN: _message := 'was machinegunned by';
        MOD_CHAINGUN:   begin
                          _message := 'was cut in half by';
                          message2 := '''s chaingun';
                        end;
        MOD_GRENADE:    begin
                          _message := 'was popped by';
                          message2 := '''s grenade';
                        end;
        MOD_G_SPLASH:   begin
                          _message := 'was shredded by';
                          message2 := '''s shrapnel';
                        end;
        MOD_ROCKET:     begin
                          _message := 'ate';
                          message2 := '''s rocket';
                        end;
        MOD_R_SPLASH:   begin
                          _message := 'almost dodged';
                          message2 := '''s rocket';
                        end;
        MOD_HYPERBLASTER:begin
                           _message := 'was melted by';
                           message2 := '''s hyperblaster';
                         end;
        MOD_RAILGUN:    _message := 'was railed by';
        MOD_BFG_LASER:  begin
                          _message := 'saw the pretty lights from';
                          message2 := '''s BFG';
                        end;
        MOD_BFG_BLAST:  begin
                          _message := 'was disintegrated by';
                          message2 := '''s BFG blast';
                        end;
        MOD_BFG_EFFECT: begin
                          _message := 'couldn''t hide from';
                          message2 := '''s BFG';
                        end;
        MOD_HANDGRENADE:begin
                          _message := 'caught';
                          message2 := '''s handgrenade';
                        end;
        MOD_HG_SPLASH:  begin
                          _message := 'didn''t see';
                          message2 := '''s handgrenade';
                        end;
        MOD_HELD_GRENADE:begin
                           _message := 'feels';
                           message2 := '''s pain';
                         end;
        MOD_TELEFRAG:   begin
                          _message := 'tried to invade';
                          message2 := '''s personal space';
                        end;
      end;

      if (_message <> nil) then
      begin
        gi.bprintf (PRINT_MEDIUM, '%s %s %s%s'#10, self^.client^.pers.netname, _message, attacker^.client^.pers.netname, message2);
        if (deathmatch^.value <> 0) then
          if (ff) then
            Dec(attacker^.client^.resp.score)
          else
            Inc(attacker^.client^.resp.score);
        Exit;
      end;
    end;
  end;

  gi.bprintf (PRINT_MEDIUM, '%s died.'#10, self^.client^.pers.netname);
  if (deathmatch^.value <> 0) then
    Dec(self^.client^.resp.score);
end;

procedure TossClientWeapon (self : edict_p); //only imp
var
  item   : gitem_p;
  drop   : edict_p;
  quad   : qboolean;
  spread : Single;
begin
  if (deathmatch^.value = 0) then
    Exit;

  item := self^.client^.pers.weapon;
  if (self^.client^.pers.inventory[self^.client^.ammo_index] = 0) then
    item := nil;
  if (item <> nil) and (strcmp (item^.pickup_name, 'Blaster') = 0) then
    item := nil;

  if (trunc(dmflags^.Value) and DF_QUAD_DROP) = 0 then
    quad := false
  else
    quad := (self^.client^.quad_framenum > (level.framenum + 10));

  if (item <> nil) AND (quad) then
    spread := 22.5
  else
    spread := 0.0;

  if (item <> Nil) then
  begin
    self^.client^.v_angle[YAW] := self^.client^.v_angle[YAW] - spread;
    drop := Drop_Item(self, item);
    self^.client^.v_angle[YAW] := self^.client^.v_angle[YAW] + spread;
    drop^.spawnflags := DROPPED_PLAYER_ITEM;
  end;

  if (quad) then
  begin
    self^.client^.v_angle[YAW] := self^.client^.v_angle[YAW] + spread;
    drop := Drop_Item (self, FindItemByClassname ('item_quad'));
    self^.client^.v_angle[YAW] := self^.client^.v_angle[YAW] - spread;
    drop^.spawnflags := drop^.spawnflags OR DROPPED_PLAYER_ITEM;

    drop^.touch := Touch_Item;
    drop^.nextthink := level.time + (self^.client^.quad_framenum - level.framenum) * FRAMETIME;
    drop^.think := G_FreeEdict;
  end;
end;


{*
==================
LookAtKiller
==================
*}
procedure LookAtKiller (self, inflictor, attacker : edict_p); //only imp
var
  dir : vec3_t;
begin
  if (attacker <> Nil) AND (attacker <> world) AND (attacker <> Self) then
  begin
    VectorSubtract (attacker^.s.origin, self^.s.origin, dir);
  end
  else if (inflictor <> Nil) AND (inflictor <> world) AND (inflictor <> Self) then
    VectorSubtract (inflictor^.s.origin, self^.s.origin, dir)
  else
  begin
    self^.client^.killer_yaw := self^.s.angles[YAW];
    Exit;
  end;

  if (dir[0] <> 0) then
    self^.client^.killer_yaw := 180/M_PI  * arctan2(dir[1], dir[0])
  else
  begin
    self^.client^.killer_yaw := 0;
    if (dir[1] > 0) then
      self^.client^.killer_yaw := 90
    else if (dir[1] < 0) then
      self^.client^.killer_yaw := -90;
  end;
  if (self^.client^.killer_yaw < 0) then
    self^.client^.killer_yaw := self^.client^.killer_yaw + 360;
end;


{*
==================
player_die
==================
*}
var
  i : integer = 0;

procedure player_die (self, inflictor, attacker : edict_p; damage : integer; const point : vec3_t); //a few files
var
  n : integer;
begin
  VectorClear (self^.avelocity);

  self^.takedamage := DAMAGE_YES;
  self^.movetype := MOVETYPE_TOSS;

  self^.s.modelindex2 := 0;   // remove linked weapon model

  self^.s.angles[0] := 0;
  self^.s.angles[2] := 0;

  self^.s.sound := 0;
  self^.client^.weapon_sound := 0;

  self^.maxs[2] := -8;

//idsoft   self->solid = SOLID_NOT;
  self^.svflags := self^.svflags OR SVF_DEADMONSTER;

  if (self^.deadflag = 0) then
  begin
    self^.client^.respawn_time := level.time + 1.0;
    LookAtKiller (self, inflictor, attacker);
    self^.client^.ps.pmove.pm_type := PM_DEAD;
    ClientObituary (self, inflictor, attacker);

    TossClientWeapon (self);

    if (deathmatch^.value <> 0) then
      Cmd_Help_f (self);      // show scores

    // clear inventory
    // this is kind of ugly, but it's how we want to handle keys in coop
    for n := 0 to game.num_items-1 do
    begin
      if (coop^.value <> 0) AND ((itemlist[n].flags AND IT_KEY) <> 0) then
        self^.client^.resp.coop_respawn.inventory[n] := self^.client^.pers.inventory[n];
      self^.client^.pers.inventory[n] := 0;
    end;
  end;

  // remove powerups
  self^.client^.quad_framenum := 0;
  self^.client^.invincible_framenum := 0;
  self^.client^.breather_framenum := 0;
  self^.client^.enviro_framenum := 0;
  self^.flags := self^.flags AND (NOT FL_POWER_ARMOR);

  if (self^.health < -40) then
  begin
    // gib
    gi.sound (self, CHAN_BODY, gi.soundindex ('misc/udeath.wav'), 1, ATTN_NORM, 0);
    for n := 0 to 3 do
      ThrowGib (self, 'models/objects/gibs/sm_meat/tris.md2', damage, GIB_ORGANIC);
    ThrowClientHead (self, damage);

    self^.takedamage := DAMAGE_NO;
  end
  else
  begin  // normal death
    if (self^.deadflag = 0) then
    begin
      i := (i+1) MOD 3;
      // start a death animation
      self^.client^.anim_priority := ANIM_DEATH;
      if (self^.client^.ps.pmove.pm_flags AND PMF_DUCKED) <> 0 then
      begin
        self^.s.frame := FRAME_crdeath1-1;
        self^.client^.anim_end := FRAME_crdeath5;
      end
      else
      begin
        Case i of
          0: begin
               self^.s.frame := FRAME_death101-1;
               self^.client^.anim_end := FRAME_death106;
             end;
          1: begin
               self^.s.frame := FRAME_death201-1;
               self^.client^.anim_end := FRAME_death206;
             end;
          2: begin
               self^.s.frame := FRAME_death301-1;
               self^.client^.anim_end := FRAME_death308;
             end;
        end;
      end;
      gi.sound (self, CHAN_VOICE,
                gi.soundindex(va('*death%i.wav', [(rand() mod 4)+1])),
                1, ATTN_NORM, 0);
    end;
  end;

  self^.deadflag := DEAD_DEAD;

  gi.linkentity (self);
end;


//=======================================================================

{*
==============
InitClientPersistant

This is only called when the game first initializes in single player,
but is called after each death and level change in deathmatch
==============
*}
procedure InitClientPersistant (client : gclient_p);
var
  item : gitem_p;
begin
  FillChar(client^.pers, SizeOf(client^.pers), 0);

  item := FindItem('Blaster');
  client^.pers.selected_item := ITEM_INDEX(item);
  client^.pers.inventory[client^.pers.selected_item] := 1;

  client^.pers.weapon := item;

  client^.pers.health      := 100;
  client^.pers.max_health   := 100;

  client^.pers.max_bullets  := 200;
  client^.pers.max_shells   := 100;
  client^.pers.max_rockets  := 50;
  client^.pers.max_grenades := 50;
  client^.pers.max_cells    := 200;
  client^.pers.max_slugs    := 50;

  client^.pers.connected := true;
end;

procedure InitClientResp (client : gclient_p);
begin
  FillChar(client^.resp, SizeOf(client^.resp), 0);

  client^.resp.enterframe := level.framenum;
  client^.resp.coop_respawn := client^.pers;
end;


{*
==================
SaveClientData

Some information that should be persistant, like health,
is still stored in the edict structure, so it needs to
be mirrored out to the client structure before all the
edicts are wiped.
==================
*}
procedure SaveClientData; //a few files
var
  i : integer;
  ent :   edict_p;
begin
  for i := 0 to game.maxclients-1 do
  begin
    ent := @g_edicts^[1+i];
    if (NOT ent^.inuse) then
      Continue;
    gclient_a(game.clients)[i].pers.health := ent^.health;
    gclient_a(game.clients)[i].pers.max_health := ent^.max_health;

    gclient_a(game.clients)[i].pers.savedFlags := (ent^.flags AND (FL_GODMODE OR FL_NOTARGET OR FL_POWER_ARMOR));

    if (coop^.Value <> 0) then
      gclient_a(game.clients)[i].pers.score := ent^.client^.resp.score;
  end;
end;

procedure FetchClientEntData (ent : edict_p);
begin
  ent^.health := ent^.client^.pers.health;
  ent^.max_health := ent^.client^.pers.max_health;

  ent^.flags := ent^.flags OR ent^.client^.pers.savedFlags;

  if (coop^.value <> 0) then
    ent^.client^.resp.score := ent^.client^.pers.score;
end;


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
function PlayersRangeFromSpot (spot : edict_p) : Single;
var
  player              : edict_p;
  bestplayerdistance,
  playerdistance      : Single;
  v                   : vec3_t;
  n                   : integer;
begin
  bestplayerdistance := 9999999;

  for n := 1 to trunc(maxclients^.Value) do
  begin
    player := @g_edicts^[n];

    if (NOT player^.inuse) then
      Continue;

    if (player^.health <= 0) then
      Continue;

    VectorSubtract (spot^.s.origin, player^.s.origin, v);
    playerdistance := VectorLength (v);

    if (playerdistance < bestplayerdistance) then
      bestplayerdistance := playerdistance;
  end;

  Result := bestplayerdistance;
end;

{*
================
SelectRandomDeathmatchSpawnPoint

go to a random point, but NOT the two points closest
to other players
================
*}
function SelectionTest(var iSelection: Integer): Boolean;
begin
  Result := (iSelection = 0);
  Dec(iSelection);
end;

function SelectRandomDeathmatchSpawnPoint : edict_p;
var
  spot, spot1, spot2 : edict_p;
  selection : integer;
  range, range1, range2 : Single;
  count : integer;
begin
  count := 0;

  spot := Nil;
  range2 := 99999;
  range1 := range2;
  spot2 := Nil;
  spot1 := spot2;

  spot := G_Find (spot, FOFS_classname, 'info_player_deathmatch');
  while (spot <> Nil) do
  begin
    Inc(count);
    range := PlayersRangeFromSpot(spot);
    if (range < range1)
    then
    begin
      range1 := range;
      spot1 := spot;
    end
    else if (range < range2) then
    begin
      range2 := range;
      spot2 := spot;
    end;
    spot := G_Find (spot, FOFS_classname, 'info_player_deathmatch')
  end;

  if (count = 0) then
  begin
    Result := Nil;
    Exit;
  end;

  if (count <= 2) then
  begin
    spot2 := Nil;
    spot1 := spot2;
  end
  else
    Dec (count, 2);

  selection := rand() mod count;

  spot := Nil;

  { NOTE:  Changed this section to react to exactly the C code, which actually
           would decrement the selection After the evaluation of the code, which
           meant that the Dec(selection) before hand was incorrect }
  repeat
    spot := G_Find (spot, FOFS_classname, 'info_player_deathmatch');
    if (spot = spot1) OR (spot = spot2) then
      Inc(selection);
  until SelectionTest(selection);

  Result := spot;
end;


{*
================
SelectFarthestDeathmatchSpawnPoint

================
*}
function SelectFarthestDeathmatchSpawnPoint : edict_p;
var
  bestspot,  spot    : edict_p;
  bestdistance,
  bestplayerdistance : single;
begin
  spot := Nil;
  bestspot := Nil;
  bestdistance := 0;
  spot := G_Find (spot, FOFS_classname, 'info_player_deathmatch');
  while (spot <> Nil) do
  begin
    bestplayerdistance := PlayersRangeFromSpot (spot);

    if (bestplayerdistance > bestdistance) then
    begin
      bestspot := spot;
      bestdistance := bestplayerdistance;
    end;
    spot := G_Find (spot, FOFS_classname, 'info_player_deathmatch');
  end;

  if (bestspot <> Nil) then
  begin
    Result := bestspot;
    Exit;
  end;

  // if there is a player just spawned on each and every start spot
  // we have no choice to turn one into a telefrag meltdown
  spot := G_Find (nil, FOFS_classname, 'info_player_deathmatch');

  Result := spot;
end;

function SelectDeathmatchSpawnPoint : edict_p;
begin
  if (Trunc(dmflags^.value) AND DF_SPAWN_FARTHEST) <> 0 then
    Result := SelectFarthestDeathmatchSpawnPoint ()
  else
    Result := SelectRandomDeathmatchSpawnPoint ();
end;


function SelectCoopSpawnPoint (ent : edict_p) : edict_p;
var
  index  : integer;
  target : PChar;
  spot   : edict_p;
begin
//  spot := nil;

  index := (Cardinal(ent^.client) - Cardinal(game.clients)) div SizeOf(edict_t);

  // player 0 starts in normal player spawn point
  if (index = 0) then
  begin
    Result := Nil;
    Exit;
  end;

  spot := nil;

  // assume there are four coop spots at each spawnpoint
  while True do
  begin
    spot := G_Find (spot, FOFS_classname, 'info_player_coop');
    if (spot = Nil) then
    begin
      Result := Nil;  // we didn't have enough...
      Exit;
    end;

    target := spot^.targetname;
    if (target = nil) then
      target := '';
    if (Q_stricmp(game.spawnpoint, target) = 0) then
    begin
      // this is a coop spawn point for one of the clients here
      Dec(index);
      if (index = 0) then
      begin
        Result := spot;    // this is it
        Exit;
      end;
    end;
  end;

  Result := spot;
end;


{*
===========
SelectSpawnPoint

Chooses a player start, deathmatch start, coop start, etc
============
*}
procedure SelectSpawnPoint (ent : edict_p; var origin, angles : vec3_t);
var
  spot : edict_p;
label
  continue_;
begin
  spot := Nil;

  if (deathmatch^.value <> 0) then
    spot := SelectDeathmatchSpawnPoint ()
  else if (coop^.value <> 0) then
    spot := SelectCoopSpawnPoint (ent);

  // find a single player start spot
  if (spot = Nil) then
  begin
      spot := G_Find (spot, FOFS_classname, 'info_player_start');
      while (spot <> Nil) do
      begin
        if (game.spawnpoint[0] = #0) AND (spot^.targetname = nil) then
          Break;

        if (game.spawnpoint[0] = #0) OR (spot^.targetname = nil) then
          goto continue_;

        if (Q_stricmp(game.spawnpoint, spot^.targetname) = 0) then
          Break;

      continue_:
        spot := G_Find (spot, FOFS_classname, 'info_player_start');
      end;

      if (spot = Nil) then
      begin
        if (game.spawnpoint[0] = #0) then
          // there wasn't a spawnpoint without a target, so use any
          spot := G_Find (spot, FOFS_classname, 'info_player_start');
        if (spot = Nil) then
          gi.error ('Couldn''t find spawn point %s'#10, game.spawnpoint);
      end;
  end;

  VectorCopy (spot^.s.origin, origin);
  origin[2] := origin[2] + 9;
  VectorCopy (spot^.s.angles, angles);
end;


//======================================================================


procedure InitBodyQue; //g_spawn
var
  i   : integer;
  ent : edict_p;
begin
  level.body_que := 0;
  for i := 0 to BODY_QUEUE_SIZE-1 do
  begin
    ent := G_Spawn();
    ent^.classname := 'bodyque';
  end;
end;

procedure body_die (self, inflictor, attacker : edict_p; damage : integer; const point : vec3_t); cdecl;
var
  n : integer;
begin
  if (self^.health < -40) then
  begin
    gi.sound (self, CHAN_BODY, gi.soundindex ('misc/udeath.wav'), 1, ATTN_NORM, 0);
    for n := 0 to 3 do
      ThrowGib (self, 'models/objects/gibs/sm_meat/tris.md2', damage, GIB_ORGANIC);
    self^.s.origin[2] := self^.s.origin[2] -48;
    ThrowClientHead (self, damage);
    self^.takedamage := DAMAGE_NO;
  end;
end;

procedure CopyToBodyQue (ent : edict_p);
var
  body : edict_p;
begin
  // grab a body que and cycle to the next one
  body := @g_edicts^[trunc(maxclients^.Value) + level.body_que + 1];
  level.body_que := (level.body_que + 1) MOD BODY_QUEUE_SIZE;

  // FIXME: send an effect on the removed body

  gi.unlinkentity (ent);

  gi.unlinkentity (body);
  body^.s := ent^.s;
  body^.s.number := (Cardinal(body) - Cardinal(g_edicts)) div SizeOf(edict_t);

  body^.svflags := ent^.svflags;
  VectorCopy (ent^.mins, body^.mins);
  VectorCopy (ent^.maxs, body^.maxs);
  VectorCopy (ent^.absmin, body^.absmin);
  VectorCopy (ent^.absmax, body^.absmax);
  VectorCopy (ent^.size, body^.size);
  body^.solid := ent^.solid;
  body^.clipmask := ent^.clipmask;
  body^.owner := ent^.owner;
  body^.movetype := ent^.movetype;

  body^.die := body_die;
  body^.takedamage := DAMAGE_YES;

  gi.linkentity (body);
end;


procedure respawn (self : edict_p);
begin
  if (deathmatch^.value <> 0) OR (coop^.value <> 0) then
  begin
    // spectator's don't leave bodies
    if (self^.movetype <> MOVETYPE_NOCLIP) then
      CopyToBodyQue (self);
    self^.svflags := self^.svflags AND (NOT SVF_NOCLIENT);
    PutClientInServer (self);

    // add a teleportation effect
    self^.s.event := EV_PLAYER_TELEPORT;

    // hold in place briefly
    self^.client^.ps.pmove.pm_flags := PMF_TIME_TELEPORT;
    self^.client^.ps.pmove.pm_time := 14;

    self^.client^.respawn_time := level.time;

    Exit;
  end;

  // restart the entire server
  gi.AddCommandString ('menu_loadgame'#10);
end;


{$IFNDEF CTF}  //onlyGAME (noneCTF)
{*
 * only called when pers.spectator changes
 * note that resp.spectator should be the opposite of pers.spectator here
 *}
procedure spectator_respawn (ent : edict_p); //imp
var
  i, numspec : integer;
  value      : PChar;
begin
  // if the user wants to become a spectator, make sure he doesn't
  // exceed max_spectators

  if (ent^.client^.pers.spectator) then
  begin
    value := Info_ValueForKey (ent^.client^.pers.userinfo, 'spectator');
    if ( (spectator_password^.string_ <> nil) AND
         (strcmp(spectator_password^.string_, 'none') <> 0) AND
         (strcmp(spectator_password^.string_, value) <> 0)) then
    begin
      gi.cprintf(ent, PRINT_HIGH, 'Spectator password incorrect.'#10);
      ent^.client^.pers.spectator := false;
      gi.WriteByte (svc_stufftext);
      gi.WriteString ('spectator 0'#10);
      gi.unicast(ent, true);
      Exit;
    end;

    // count spectators
//    for (i = 1, numspec = 0; i <= maxclients->value; i++)
    numspec := 0;
    for i := 1 to trunc(maxclients^.Value) do
      if (g_edicts^[i].inuse) AND (g_edicts^[i].client^.pers.spectator) then
        Inc(numspec);

    if (numspec >= maxspectators^.value) then
    begin
      gi.cprintf(ent, PRINT_HIGH, 'Server spectator limit is full.');
      ent^.client^.pers.spectator := false;
      // reset his spectator var
      gi.WriteByte (svc_stufftext);
      gi.WriteString ('spectator 0'#10);
      gi.unicast(ent, true);
      Exit;
    end;
  end
  else
  begin
    // he was a spectator and wants to join the game
    // he must have the right password
    value := Info_ValueForKey (ent^.client^.pers.userinfo, 'password');
    { if ( (password^.string_^ <> #0) AND   // <<-- Truer to Original Conversion }
    if ( (password^.string_ <> nil) AND
         (strcmp(password^.string_, 'none') <> 0) AND
         (strcmp(password^.string_, value) <> 0)) then
    begin
      gi.cprintf(ent, PRINT_HIGH, 'Password incorrect.'#10);
      ent^.client^.pers.spectator := true;
      gi.WriteByte (svc_stufftext);
      gi.WriteString ('spectator 1'#10);
      gi.unicast(ent, true);
      Exit;
    end;
  end;

  // clear score on respawn
//  ent->client->resp.score = ent->client->pers.score = 0;
  ent^.client^.pers.score := 0;
  ent.client.resp.score := ent^.client^.pers.score;

  ent^.svflags := ent^.svflags AND (NOT SVF_NOCLIENT);
  PutClientInServer (ent);

  // add a teleportation effect
  if (NOT ent^.client^.pers.spectator) then
  begin
    // send effect
    gi.WriteByte (svc_muzzleflash);
    gi.WriteShort ((Cardinal(ent)-Cardinal(g_edicts)) div SizeOf(edict_t));
    gi.WriteByte (MZ_LOGIN);
    gi.multicast (@ent^.s.origin, MULTICAST_PVS);

    // hold in place briefly
    ent^.client^.ps.pmove.pm_flags := PMF_TIME_TELEPORT;
    ent^.client^.ps.pmove.pm_time := 14;
  end;

  ent^.client^.respawn_time := level.time;

  if (ent^.client^.pers.spectator) then
    gi.bprintf (PRINT_HIGH, '%s has moved to the sidelines'#10, ent^.client^.pers.netname)
  else
    gi.bprintf (PRINT_HIGH, '%s joined the game'#10, ent^.client^.pers.netname);
end;
{$ENDIF}

//==============================================================


{*
===========
PutClientInServer

Called when a player connects to a server or respawns in
a deathmatch.
============
*}
procedure PutClientInServer (ent : edict_p);
const
  mins : vec3_t = (-16, -16, -24);
  maxs : vec3_t = ( 16,  16,  32);
var
  index   : integer;
  spawn_origin,
  spawn_angles  : vec3_t;
  client        : gclient_p;
  i             : integer;
  saved         : client_persistant_t;
  resp          : client_respawn_t;

  userinfo      : array[0..MAX_INFO_STRING-1] of char;

begin
  // find a spawn point
  // do it before setting health back up, so farthest
  // ranging doesn't count this client
  SelectSpawnPoint (ent, spawn_origin, spawn_angles);

  index := (Cardinal(ent) - Cardinal(g_edicts)) div SizeOf(edict_t) - 1;
  client := ent^.client;

  // deathmatch wipes most client data every spawn
  if (deathmatch^.value <> 0) then
  begin
    resp := client^.resp;
    memcpy (@userinfo, @client^.pers.userinfo, SizeOf(userinfo));
    InitClientPersistant (client);
    ClientUserinfoChanged (ent, userinfo);
  end
  else if (coop^.value <> 0) then
  begin
    resp := client^.resp;
    memcpy (@userinfo, @client^.pers.userinfo, SizeOf(userinfo));

{$IFDEF CTF}
    for n:=0 to MAX_ITEMS-1 do
      if ((itemlist[n].flags AND IT_KEY) <> 0) then
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
    resp.coop_respawn.game_helpchanged := client^.pers.game_helpchanged;
    resp.coop_respawn.helpchanged := client^.pers.helpchanged;
{$ENDIF}

    client^.pers := resp.coop_respawn;
    ClientUserinfoChanged (ent, userinfo);
    if (resp.score > client^.pers.score) then
      client^.pers.score := resp.score;
  end
  else
    FillChar(resp, SizeOf(resp), 0);

  // clear everything but the persistant data
  saved := client^.pers;
  FillChar(client^, SizeOf(gclient_t), 0);
  client^.pers := saved;
  if (client^.pers.health <= 0) then
    InitClientPersistant(client);
  client^.resp := resp;

  // copy some data from the client to the entity
  FetchClientEntData (ent);

  // clear entity values
  ent^.groundentity := Nil;
  ent^.client := @gclient_a(game.clients)[index];
  ent^.takedamage := DAMAGE_AIM;
  ent^.movetype := MOVETYPE_WALK;
  ent^.viewheight := 22;
  ent^.inuse := true;
  ent^.classname := 'player';
  ent^.mass := 200;
  ent^.solid := SOLID_BBOX;
  ent^.deadflag := DEAD_NO;
  ent^.air_finished := level.time + 12;
  ent^.clipmask := MASK_PLAYERSOLID;
  ent^.model := 'players/male/tris.md2';
  ent^.pain := player_pain;
  ent^.die := player_die;
  ent^.waterlevel := 0;
  ent^.watertype := 0;
  ent^.flags := ent^.flags AND (NOT FL_NO_KNOCKBACK);
  ent^.svflags := ent^.svflags AND (NOT SVF_DEADMONSTER);

  VectorCopy (mins, ent^.mins);
  VectorCopy (maxs, ent^.maxs);
  VectorClear (ent^.velocity);

  // clear playerstate values
  FillChar(ent^.client^.ps, SizeOf(client^.ps), 0);

  client^.ps.pmove.origin[0] := trunc(spawn_origin[0]*8);
  client^.ps.pmove.origin[1] := trunc(spawn_origin[1]*8);
  client^.ps.pmove.origin[2] := trunc(spawn_origin[2]*8);

{$IFDEF CTF}  //onlyCTF
//ZOID
  client^.ps.pmove.pm_flags := client^.ps.pmove.pm_flags AND (NOT PMF_NO_PREDICTION);
//ZOID
{$ENDIF}

  if (deathmatch^.Value <> 0) AND ((trunc(dmflags^.Value) and DF_FIXED_FOV) <> 0) then
  begin
    client^.ps.fov := 90
  end
  else
  begin
    client^.ps.fov := atoi(Info_ValueForKey(client^.pers.userinfo, 'fov'));
    if (client^.ps.fov < 1) then
      client^.ps.fov := 90
    else if (client^.ps.fov > 160) then
      client^.ps.fov := 160;
  end;

  client^.ps.gunindex := gi.modelindex(client^.pers.weapon^.view_model);

  // clear entity state values
  ent^.s.effects := 0;
  ent^.s.modelindex := 255;      // will use the skin specified model
  ent^.s.modelindex2 := 255;      // custom gun model
  // sknum is player num and weapon number
  // weapon number will be added in changeweapon
  ent^.s.skinnum := (Cardinal(ent) - Cardinal(g_edicts)) div SizeOf(edict_t) - 1;

  ent^.s.frame := 0;
  VectorCopy (spawn_origin, ent^.s.origin);
  ent^.s.origin[2] := ent^.s.origin[2] +1;   // make sure off ground
  VectorCopy (ent^.s.origin, ent^.s.old_origin);

  // set the delta angle
  for i := 0 to 2 do
    client^.ps.pmove.delta_angles[i] := ANGLE2SHORT(spawn_angles[i] - client^.resp.cmd_angles[i]);

  ent^.s.angles[PITCH] := 0;
  ent^.s.angles[YAW] := spawn_angles[YAW];
  ent^.s.angles[ROLL] := 0;
  VectorCopy (ent^.s.angles, client^.ps.viewangles);
  VectorCopy (ent^.s.angles, client^.v_angle);

{$IFDEF CTF}
(*Y//ZOID
  if (CTFStartClient(ent)) then
    Exit;
//ZOID*)
{$ELSE}
  // spawn a spectator
  if (client^.pers.spectator) then
  begin
    client^.chase_target := Nil;

    client^.resp.spectator := true;

    ent^.movetype := MOVETYPE_NOCLIP;
    ent^.solid := SOLID_NOT;
    ent^.svflags := ent^.svflags OR SVF_NOCLIENT;
    ent^.client^.ps.gunindex := 0;
    gi.linkentity (ent);
    Exit;
  end
  else
    client^.resp.spectator := false;
{$ENDIF}

  if (not KillBox (ent)) then
  begin
    // could't spawn in?
  end;

  gi.linkentity (ent);

  // force the current weapon up
  client^.newweapon := client^.pers.weapon;
  ChangeWeapon (ent);
end;


{*
=====================
ClientBeginDeathmatch

A client has just connected to the server in
deathmatch mode, so clear everything out before starting them.
=====================
*}
procedure ClientBeginDeathmatch (ent : edict_p);
begin
  G_InitEdict (ent);

  InitClientResp (ent^.client);

  // locate ent at a spawn point
  PutClientInServer (ent);

  if (level.intermissiontime <> 0) then
  begin
    MoveClientToIntermission (ent);
  end
  else
  begin
    // send effect
    gi.WriteByte (svc_muzzleflash);
    gi.WriteShort ((Cardinal(ent) - Cardinal(g_edicts)) div SizeOf(edict_t));
    gi.WriteByte (MZ_LOGIN);
    gi.multicast (@ent^.s.origin, MULTICAST_PVS);
  end;

  gi.bprintf (PRINT_HIGH, '%s entered the game'#10, ent^.client^.pers.netname);

  // make sure all view stuff is valid
  ClientEndServerFrame (ent);
end;


{*
===========
ClientBegin

called when a client has finished connecting, and is ready
to be placed into the game.  This will happen every level load.
============
*}
procedure ClientBegin (ent : edict_p); //g_main
var
  i : integer;
begin
  ent^.client := @gclient_a(game.clients)[((Cardinal(ent) - Cardinal(g_edicts)) div sizeof(edict_t)- 1)];

  if (deathmatch^.value <> 0) then
  begin
    ClientBeginDeathmatch (ent);
    Exit;
  end;

  // if there is already a body waiting for us (a loadgame), just
  // take it, otherwise spawn one from scratch
  if (ent^.inuse = true) then
  begin
    // the client has cleared the client side viewangles upon
    // connecting to the server, which is different than the
    // state when the game is saved, so we need to compensate
    // with deltaangles
    for i := 0 to 2 do
      ent^.client^.ps.pmove.delta_angles[i] := ANGLE2SHORT(ent^.client^.ps.viewangles[i]);
  end
  else
  begin
    // a spawn point will completely reinitialize the entity
    // except for the persistant data that was initialized at
    // ClientConnect() time
    G_InitEdict (ent);
    ent^.classname := 'player';
    InitClientResp (ent^.client);
    PutClientInServer (ent);
  end;

  if (level.intermissiontime <> 0) then
  begin
    MoveClientToIntermission (ent)
  end
  else
  begin
    // send effect if in a multiplayer game
    if (game.maxclients > 1) then
    begin
      gi.WriteByte (svc_muzzleflash);
      gi.WriteShort (Cardinal(ent)-Cardinal(g_edicts) div SizeOf(edict_t));
      gi.WriteByte (MZ_LOGIN);
      gi.multicast (@ent^.s.origin, MULTICAST_PVS);

      gi.bprintf (PRINT_HIGH, '%s entered the game'#10, ent^.client^.pers.netname);
    end;
  end;

  // make sure all view stuff is valid
  ClientEndServerFrame (ent);
end;


{*
===========
ClientUserInfoChanged

called whenever the player updates a userinfo variable.

The game can override any of the settings in place
(forcing skins or names, etc) before copying it off.
============
*}
procedure ClientUserinfoChanged (ent : edict_p; userinfo : PChar); //g_main
var
  s : PChar;
  playernum : integer;
begin
  // check for malformed or illegal info strings
  if (not Info_Validate(userinfo)) then
    strcpy (userinfo, '\name\badinfo\skin\male/grunt');

  // set name
  s := Info_ValueForKey (userinfo, 'name');
  strncpy (ent^.client^.pers.netname, s, sizeof(ent^.client^.pers.netname)-1);

{$IFNDEF CTF}  //onlyGAME (noneCTF)
  // set spectator
  s := Info_ValueForKey (userinfo, 'spectator');
  // spectators are only supported in deathmatch
  { 2003-05-08-SP:  Alternative more Literal Conversion in case chosen option is under doubt
  if (deathmatch^.value <> 0) and (s^ <> #0) and (strcmp(s, '0') <> 0) then }
  if (deathmatch^.value <> 0) and (s <> nil) and (strcmp(s, '0') <> 0) then
    ent^.client^.pers.spectator := true
  else
    ent^.client^.pers.spectator := false;
{$ENDIF}

  // set skin
  s := Info_ValueForKey (userinfo, 'skin');

  playernum := ((Cardinal(ent) - Cardinal(g_edicts)) div SizeOf(edict_t)) - 1;

  // combine name and skin into a configstring
{$IFDEF CTF}  //onlyCTF
(*Y//ZOID
  if (ctf.value)
  then CTFAssignSkin(ent, s)
  else
//ZOID*)
{$ENDIF}
    gi.configstring (CS_PLAYERSKINS+playernum, va('%s\%s', [ent^.client^.pers.netname, s]));

  // fov
  if (deathmatch^.value <> 0)  AND ((trunc(dmflags^.Value) and DF_FIXED_FOV) <> 0) then
  begin
    ent^.client^.ps.fov := 90
  end
  else
  begin
    ent^.client^.ps.fov := atoi(Info_ValueForKey(userinfo, 'fov'));
    if (ent^.client^.ps.fov < 1) then
      ent^.client^.ps.fov := 90
    else if (ent^.client^.ps.fov > 160) then
      ent^.client^.ps.fov := 160;
  end;

  // handedness
  s := Info_ValueForKey (userinfo, 'hand');
  if (strlen(s) <> 0) then
    ent^.client^.pers.hand := atoi(s);

  // save off the userinfo in case we want to check something later
  strncpy (ent^.client^.pers.userinfo, userinfo, sizeof(ent^.client^.pers.userinfo)-1);
end;


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
function ClientConnect (ent : edict_p; userinfo : PChar) : qboolean; //g_main
var
  value      : PChar;
  i, numspec : Integer;
begin
  // check to see if they are on the banned IP list
  value := Info_ValueForKey (userinfo, 'ip');

{$IFNDEF CTF}  //onlyGAME (noneCTF)
  if (SV_FilterPacket(value)) then
  begin
    Info_SetValueForKey (userinfo, 'rejmsg', 'Banned.');
    Result := false;
    Exit;
  end;

  // check for a spectator
  value := Info_ValueForKey (userinfo, 'spectator');
  { 2003-05-08-SP:  Alternative more Literal Conversion in case chosen option is under doubt
  if (deathmatch^.Value <> 0) and (value^ <> #0) and (strcmp(value, '0') <> 0) then }
  if (deathmatch^.Value <> 0) and (value <> nil) and (strcmp(value, '0') <> 0) then
  begin
    { 2003-05-08-SP:  Alternative more Literal Conversion in case chosen option is under doubt
    if ( (spectator_password^.string_^ <> #0) AND }
    if ( (spectator_password^.string_ <> nil) AND
         (strcmp(spectator_password^.string_, 'none') <> 0) AND
         (strcmp(spectator_password^.string_, value) <> 0)) then
    begin
      Info_SetValueForKey(userinfo, 'rejmsg', 'Spectator password required or incorrect.');
      Result := false;
      Exit;
    end;

    // count spectators
    numspec := 0;
    for i := 0 to trunc(maxclients^.Value)-1 do
      if (g_edicts^[i+1].inuse) AND (g_edicts^[i+1].client^.pers.spectator) then
        Inc(numspec);

    if (numspec >= maxspectators^.value) then
    begin
      Info_SetValueForKey(userinfo, 'rejmsg', 'Server spectator limit is full.');
      Result := false;
      Exit;
    end;
  end
  else
  begin
{$ENDIF}
    // check for a password
    value := Info_ValueForKey (userinfo, 'password');
    { 2003-05-08-SP:  Alternative more Literal Conversion in case chosen option is under doubt
    if ( (password.string_^ <> #0) AND }
    if ( (password^.string_ <> nil) AND
         (strcmp(password^.string_, 'none') <> 0) AND
         (strcmp(password^.string_, value) <> 0)) then
    begin
      Info_SetValueForKey(userinfo, 'rejmsg', 'Password required or incorrect.');
      Result := false;
      Exit;
    end;
{$IFNDEF CTF}
  end;
{$ENDIF}


  // they can connect
  ent^.client := @gclient_a(game.clients)[((Cardinal(ent) - Cardinal(g_edicts)) div SizeOf(edict_t)) - 1];

  // if there is already a body waiting for us (a loadgame), just
  // take it, otherwise spawn one from scratch
  if (ent^.inuse = false) then
  begin
    // clear the respawning variables

{$IFDEF CTF}  //onlyCTF
//ZOID -- force team join
    ent^.client^.resp.ctf_team := -1;
    ent.^client^.resp.id_state := false;
//ZOID
{$ENDIF}

    InitClientResp (ent^.client);
    if (not game.autosaved) OR (ent^.client^.pers.weapon = nil) then
      InitClientPersistant (ent^.client);
  end;

  ClientUserinfoChanged (ent, userinfo);

  if (game.maxclients > 1) then
    gi.dprintf ('%s connected'#10, ent^.client^.pers.netname);

  ent^.svflags := 0;
  ent^.client^.pers.connected := true;
  Result := true;
end;


{*
===========
ClientDisconnect

Called when a player drops from the server.
Will not be called between levels.
============
*}
procedure ClientDisconnect (ent : edict_p); //g_main
var
  playernum : integer;
begin
  if (ent^.client = Nil) then
    Exit;

  gi.bprintf (PRINT_HIGH, '%s disconnected'#10, ent^.client^.pers.netname);

{$IFDEF CTF}  //onlyCTF
(*Y//ZOID
  CTFDeadDropFlag(ent);
  CTFDeadDropTech(ent);
//ZOID*)
{$ENDIF}

  // send effect
  gi.WriteByte (svc_muzzleflash);
  gi.WriteShort ((Cardinal(ent) - Cardinal(g_edicts)) div SizeOf(edict_t));
  gi.WriteByte (MZ_LOGOUT);
  gi.multicast (@ent^.s.origin, MULTICAST_PVS);

  gi.unlinkentity (ent);
  ent^.s.modelindex := 0;
  ent^.solid := SOLID_NOT;
  ent^.inuse := false;
  ent^.classname := 'disconnected';
  ent^.client^.pers.connected := false;

  playernum := (Cardinal(ent) - Cardinal(g_edicts)) div SizeOf(edict_t) - 1;
  gi.configstring (CS_PLAYERSKINS+playernum, '');
end;


//==============================================================


var
  pm_passent : edict_p;

// pmove doesn't need to know about passent and contentmask
function PM_trace (var start, mins, maxs, end_: vec3_t) : trace_t; cdecl;
begin
  if (pm_passent^.health > 0) then
    Result := gi.trace (@start, @mins, @maxs, @end_, pm_passent, MASK_PLAYERSOLID)
  else
    Result := gi.trace (@start, @mins, @maxs, @end_, pm_passent, MASK_DEADSOLID);
end;


function CheckBlock (b : PByteArray; c : integer) : integer;
var
  v, i : integer;
begin
  v := 0;
  for i := 0 to c-1 do
    Inc(v, b^[i]);
  Result := v;
end;

procedure PrintPmove (pm : pmove_p);
var
  c1, c2 : cardinal;
begin
  c1 := CheckBlock (@pm^.s,   sizeof(pm^.s));
  c2 := CheckBlock (@pm^.cmd, sizeof(pm^.cmd));
  Com_Printf ('sv %3i:%i %i'#10, [pm^.cmd.impulse, c1, c2]);
end;


{*
==============
ClientThink

This will be called once for each client frame, which will
usually be a couple times for each server frame.
==============
*}
procedure ClientThink (ent : edict_p; ucmd : usercmd_p);
var
  client : gclient_p;
  other  : edict_p;
  i, j   : integer;
  pm     : pmove_t;
begin
  level.current_entity := ent;
  client := ent^.client;

  if (level.intermissiontime <> 0) then
  begin
    client^.ps.pmove.pm_type := PM_FREEZE;
    // can exit intermission after five seconds
    if (level.time > level.intermissiontime + 5.0) AND ((ucmd^.buttons AND BUTTON_ANY) <> 0) then
      level.exitintermission := Integer(True);
    Exit;
  end;

  pm_passent := ent;

  if (ent^.client^.chase_target <> Nil) then
  begin
    client^.resp.cmd_angles[0] := SHORT2ANGLE(ucmd^.angles[0]);
    client^.resp.cmd_angles[1] := SHORT2ANGLE(ucmd^.angles[1]);
    client^.resp.cmd_angles[2] := SHORT2ANGLE(ucmd^.angles[2]);

{$IFDEF CTF}
//ZOID
    Exit;
  end;
{$ELSE}
  end
  else
  begin
{$ENDIF}

    // set up for pmove
    FillChar(pm, sizeof(pm), 0);

    if (ent^.movetype = MOVETYPE_NOCLIP) then
      client^.ps.pmove.pm_type := PM_SPECTATOR
    else if (ent^.s.modelindex <> 255) then
      client^.ps.pmove.pm_type := PM_GIB
    else if (ent^.deadflag <> 0) then
      client^.ps.pmove.pm_type := PM_DEAD
    else
      client^.ps.pmove.pm_type := PM_NORMAL;

    client^.ps.pmove.gravity := trunc(sv_gravity^.Value);
    pm.s := client^.ps.pmove;

    for i := 0 to 2 do
    begin
      pm.s.origin[i] := trunc(ent^.s.origin[i]*8);
      pm.s.velocity[i] := trunc(ent^.velocity[i]*8);
    end;

    if (memcmp(@client^.old_pmove, @pm.s, sizeof(pm.s)) <> 0) then
    begin
      pm.snapinitial := true;
//idsoft   gi.dprintf ("pmove changed!\n");
    end;

    pm.cmd := ucmd^;

    pm.trace := PM_trace;   // adds default parms
    pm.pointcontents := gi.pointcontents;

    // perform a pmove
    gi.Pmove (@pm);

    // save results of pmove
    client^.ps.pmove := pm.s;
    client^.old_pmove := pm.s;

    for i := 0 to 2 do
    begin
      ent^.s.origin[i] := pm.s.origin[i]*0.125;
      ent^.velocity[i] := pm.s.velocity[i]*0.125;
    end;

    VectorCopy (pm.mins, ent^.mins);
    VectorCopy (pm.maxs, ent^.maxs);

    client^.resp.cmd_angles[0] := SHORT2ANGLE(ucmd^.angles[0]);
    client^.resp.cmd_angles[1] := SHORT2ANGLE(ucmd^.angles[1]);
    client^.resp.cmd_angles[2] := SHORT2ANGLE(ucmd^.angles[2]);

    if (ent^.groundentity <> Nil) AND (pm.groundentity = Nil) AND (pm.cmd.upmove >= 10) AND (pm.waterlevel = 0) then
    begin
      gi.sound (ent, CHAN_VOICE, gi.soundindex('*jump1.wav'), 1, ATTN_NORM, 0);
      PlayerNoise (ent, ent^.s.origin, PNOISE_SELF);
    end;

    ent^.viewheight := trunc(pm.viewheight);
    ent^.waterlevel := pm.waterlevel;
    ent^.watertype := pm.watertype;
    ent^.groundentity := pm.groundentity;
    if (pm.groundentity <> Nil) then
      ent^.groundentity_linkcount := edict_p(pm.groundentity)^.linkcount;

    if (ent^.deadflag <> 0) then
    begin
      client^.ps.viewangles[ROLL] := 40;
      client^.ps.viewangles[PITCH] := -15;
      client^.ps.viewangles[YAW] := client^.killer_yaw;
    end
    else
    begin
      VectorCopy (pm.viewangles, client^.v_angle);
      VectorCopy (pm.viewangles, client^.ps.viewangles);
    end;

{$IFDEF CTF}  //onlyCTF
(*Y//ZOID
  if (client.ctf_grapple <> Nil) then
    CTFGrapplePull (client.ctf_grapple);
//ZOID*)
{$ENDIF}

    gi.linkentity (ent);

    if (ent^.movetype <> MOVETYPE_NOCLIP) then
      G_TouchTriggers (ent);

    // touch other objects
    for i := 0 to pm.numtouch-1 do
    begin
      other := pm.touchents[i];
      j := 0;
      while j < i do
      begin
        if (pm.touchents[j] = other) then
          Break;

        Inc(j);
      end;
      if (j <> i) then
        Continue;  // duplicated
      if NOT Assigned(other^.touch) then
        Continue;
      other^.touch (other, ent, Nil, Nil);
    end;

{$IFNDEF CTF}
  end;
{$ENDIF}

  client^.oldbuttons := client^.buttons;
  client^.buttons := ucmd^.buttons;
  client^.latched_buttons := client^.latched_buttons OR (client^.buttons AND (NOT client^.oldbuttons));

  // save light level the player is standing on for
  // monster sighting AI
  ent^.light_level := ucmd^.lightlevel;

  // fire weapon from final position if needed
{$IFDEF CTF}
  if ((client^.latched_buttons AND BUTTON_ATTACK) <> 0)
//ZOID
     AND (ent^.movetype <> MOVETYPE_NOCLIP
//ZOID
     )
  then
    if (NOT client^.weapon_thunk) then
    begin
      client^.weapon_thunk := true;
      Think_Weapon (ent);
    end;
{$ELSE}
  if (client^.latched_buttons AND BUTTON_ATTACK) <> 0 then
  begin
    if (client^.resp.spectator) then
    begin
      client^.latched_buttons := 0;

      if (client^.chase_target <> Nil) then
      begin
        client^.chase_target := Nil;
        client^.ps.pmove.pm_flags := client^.ps.pmove.pm_flags AND (NOT PMF_NO_PREDICTION);
      end
      else
        GetChaseTarget(ent);
    end
    else if (NOT client^.weapon_thunk) then
    begin
      client^.weapon_thunk := true;
      Think_Weapon (ent);
    end;
  end;
{$ENDIF}


{$IFDEF CTF}
(*Y//ZOID
//regen tech
  CTFApplyRegeneration(ent);
//ZOID*)

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
  if (client^.resp.spectator) then
  begin
    if (ucmd^.upmove >= 10) then
    begin
      if (client^.ps.pmove.pm_flags AND PMF_JUMP_HELD) = 0 then
      begin
        client^.ps.pmove.pm_flags := client^.ps.pmove.pm_flags OR PMF_JUMP_HELD;
        if (client^.chase_target <> nil) then
          ChaseNext(ent)
        else
          GetChaseTarget(ent);
      end;
    end
    else
      client^.ps.pmove.pm_flags := client^.ps.pmove.pm_flags AND (NOT PMF_JUMP_HELD);
  end;

  // update chase cam if being followed
  for i := 1 to trunc(maxclients^.Value) do
  begin
    other := @g_edicts^[i];
    if (other^.inuse) AND (other^.client^.chase_target = ent) then
      UpdateChaseCam(other);
  end;
{$ENDIF}
end;


{*
==============
ClientBeginServerFrame

This will be called once for each server frame, before running
any other entities in the world.
==============
*}
procedure ClientBeginServerFrame (ent : edict_p);
var
  client : gclient_p;
  buttonMask : integer;
begin
  if (level.intermissiontime <> 0) then
    Exit;

  client := ent^.client;


{$IFDEF CTF}
  // run weapon animations if it hasn't been done by a ucmd_t
  if (NOT client.weapon_thunk)
//ZOID
     AND (ent.movetype <> MOVETYPE_NOCLIP
//ZOID
          )
  then Think_Weapon (ent)
  else client.weapon_thunk := false;
{$ELSE}
  if (deathmatch^.value <> 0) AND
     (client^.pers.spectator <> client^.resp.spectator) AND
     ((level.time - client^.respawn_time) >= 5) then
  begin
    spectator_respawn(ent);
    Exit;
  end;

  // run weapon animations if it hasn't been done by a ucmd_t
  if (NOT client^.weapon_thunk) AND (NOT client^.resp.spectator) then
    Think_Weapon (ent)
  else
    client^.weapon_thunk := false;
{$ENDIF}

  if (ent^.deadflag <> 0) then
  begin
    // wait for any button just going down
    if (level.time > client^.respawn_time) then
    begin
      // in deathmatch, only wait for attack button
      if (deathmatch^.value <> 0) then
        buttonMask := BUTTON_ATTACK
      else
        buttonMask := -1;

{$IFDEF CTF}
      if ((client.latched_buttons AND buttonMask) <> 0) OR
         ( (deathmatch.value <> 0) AND (({(int)}Trunc(dmflags.value) AND DF_FORCE_RESPAWN) <> 0) ) (*YOR
         CTFMatchOn()*) then
{$ELSE}
      if ((client^.latched_buttons AND buttonMask) <> 0) OR
         ( (deathmatch^.value <> 0) AND ((Trunc(dmflags^.value) AND DF_FORCE_RESPAWN) <> 0) ) then
{$ENDIF}
      begin
        respawn(ent);
        client^.latched_buttons := 0;
      end;
    end;
    Exit;
  end;

  // add player trail so monsters can follow
  if (deathmatch^.value = 0) then
    if (not visible (ent, PlayerTrail_LastSpot())) then
      PlayerTrail_Add (ent^.s.old_origin);

  client^.latched_buttons := 0;
end;

end.
