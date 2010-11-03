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
{ File(s): p_hud.c                                                           }
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

{*
======================================================================

INTERMISSION

======================================================================
*}

// GAME=CTF
procedure MoveClientToIntermission (edict_t *ent);
begin
  if (deathmatch.value OR coop.value) then
    ent.client.showscores := true;
  VectorCopy (level.intermission_origin, ent.s.origin);
  ent.client.ps.pmove.origin[0] := level.intermission_origin[0] *8;
  ent.client.ps.pmove.origin[1] := level.intermission_origin[1] *8;
  ent.client.ps.pmove.origin[2] := level.intermission_origin[2] *8;
  VectorCopy (level.intermission_angle, ent.client.ps.viewangles);
  ent.client.ps.pmove.pm_type := PM_FREEZE;
  ent.client.ps.gunindex := 0;
  ent.client.ps.blend[3] := 0;
  ent.client.ps.rdflags := ent.client.ps.rdflags AND (NOT RDF_UNDERWATER);

  // clean up powerup info
  ent.client.quad_framenum := 0;
  ent.client.invincible_framenum := 0;
  ent.client.breather_framenum := 0;
  ent.client.enviro_framenum := 0;
  ent.client.grenade_blew_up := false;
  ent.client.grenade_time := 0;

  ent.viewheight := 0;
  ent.s.modelindex := 0;
  ent.s.modelindex2 := 0;
  ent.s.modelindex3 := 0;
  ent.s.modelindex := 0;
  ent.s.effects := 0;
  ent.s.sound := 0;
  ent.solid := SOLID_NOT;

  // add the layout

  if (deathmatch.value OR coop.value) then
  begin
    DeathmatchScoreboardMessage (ent, Nil);
    gi.unicast (ent, true);
  end;
end;//procedure (GAME=CTF)


// GAME <> CTF
procedure BeginIntermission (edict_t *targ);
var
  i, n : integer;
   edict_t   *ent, *client;
begin
  if (level.intermissiontime) then
    Exit;   // already activated

{$IFDEF CTF}  //only CTF
//ZOID
  if (deathmatch.value AND ctf.value) then
    CTFCalcScores();
//ZOID
{$ENDIF}

  game.autosaved = false;

  // respawn any dead clients
  for i:=0 to maxclients.value-1 do
  begin
    client := g_edicts + 1 + i;
    if (!client.inuse) then
      Continue;
    if (client.health <= 0) then
      respawn(client);
  end;

  level.intermissiontime := level.time;
  level.changemap := targ.map;

{Y}  if (strstr(level.changemap, '*')) then
    if (coop.value) then
      for i:=0 to maxclients.value-1 do
      begin
        client := g_edicts + 1 + i;
        if (!client.inuse) then
          Continue;
        // strip players of all keys between units
        for n:=0 to MAX_ITEMS-1 do
          if ((itemlist[n].flags AND IT_KEY) <> 0)
            client.client.pers.inventory[n] := 0;
      end;//for
  else
    if (!deathmatch.value) then
    begin
      level.exitintermission := 1;    // go immediately to the next level
      Exit;
    end;

  level.exitintermission = 0;

  // find an intermission spot
  ent := G_Find (NULL, FOFS(classname), 'info_player_intermission');
  if (!ent)
  then begin
    // the map creator forgot to put in an intermission point...
    ent := G_Find (NULL, FOFS(classname), 'info_player_start');
    if (!ent) then
      ent := G_Find (NULL, FOFS(classname), 'info_player_deathmatch');
  end
  else begin
    // chose one of four spots
    i := random(3);
//    while (i--)
    while (i <> 0) do
    begin
      ent := G_Find (ent, FOFS(classname), 'info_player_intermission');
      if (!ent)   then// wrap around the list
        ent := G_Find (ent, FOFS(classname), 'info_player_intermission');
      Dec(i);
    end;
  end;

  VectorCopy (ent.s.origin, level.intermission_origin);
  VectorCopy (ent.s.angles, level.intermission_angle);

  // move all clients to the intermission point
  for i:=0 to maxclients.value-1 do
  begin
    client := g_edicts + 1 + i;
    if (!client.inuse) then
      Continue;
    MoveClientToIntermission (client);
  end;
end;//procedure (GAME <> CTF)


{*
==================
DeathmatchScoreboardMessage
==================
*}
// GAME <> CTF
procedure DeathmatchScoreboardMessage (edict_t *ent, edict_t *killer);
var
   char   entry[1024];
   char   string[1400];

  stringlength,        
  i, j, k,
  score, total,
  x, y,
  picnum        : integer;

  sorted,
  sortedscores  : array [0..MAX_CLIENTS-1] of integer;

   gclient_t   *cl;
   edict_t      *cl_ent;
   char   *tag;
begin
{$IFDEF CTF}  //only CTF
//ZOID
  if (ctf.value) then
  begin
    CTFScoreboardMessage (ent, killer);
    Exit;
  end;
//ZOID
{$ENDIF}

  // sort the clients by score
  total := 0;
  for i:=0 to game.maxclients-1 do
  begin
    cl_ent := g_edicts + 1 + i;

{$IFDEF CTF}
    if (!cl_ent.inuse) then
      Continue;
{$ELSE}
    if (!cl_ent.inuse OR game.clients[i].resp.spectator) then
      Continue;
{$ENDIF}

    score := game.clients[i].resp.score;
    for j:=0 to total-1 do
      if (score > sortedscores[j])
        Break;
(*{Y:}    for (k=total ; k>j ; k--)
    {
        sorted[k] := sorted[k-1];
        sortedscores[k] := sortedscores[k-1];
    }*)
k := total;
while k>j do
begin
  sorted[k] := sorted[k-1];
  sortedscores[k] := sortedscores[k-1];

  Dec(k);
end;

    sorted[j] := i;
    sortedscores[j] := score;
    total++;
  end;//for

  // print level name and exit rules
  string[0] := 0;

  stringlength := strlen(string);

  // add the clients in sorted order
  if (total > 12) then
    total := 12;

  for i:=0 to total-1 do
  begin
    cl = &game.clients[sorted[i]];
    cl_ent := g_edicts + 1 + sorted[i];

    picnum := gi.imageindex ('i_fixme');
(*    x = (i>=6) ? 160 : 0;
    y = 32 + 32 * (i%6);*)

    if (i>=6)

    then x := 160

    else x := 0;

    y := 32 + 32 * (i MOD 6);

    // add a dogtag
    if (cl_ent = ent)
    then tag := 'tag1';
    else
      if (cl_ent = killer)
      then tag := 'tag2';
      else tag := NULL;
    if (tag) then
    begin
      Com_sprintf (entry, sizeof(entry), 'xv %i yv %i picn %s ',x+32, y, tag);
      j := strlen(entry);
      if (stringlength + j > 1024) then
        Break;
      strcpy (string + stringlength, entry);
      stringlength += j;
    end;

    // send the layout
    Com_sprintf (entry, sizeof(entry),
                 'client %i %i %i %i %i %i ',
                 x, y, sorted[i], cl.resp.score, cl.ping, (level.framenum - cl.resp.enterframe)/600);
    j := strlen(entry);
    if (stringlength + j > 1024) then
      Break;
    strcpy (string + stringlength, entry);
    Inc(stringlength, j);
  end;//for

  gi.WriteByte (svc_layout);
  gi.WriteString (string);
end;//procedure (GAME <> CTF)


{*
==================
DeathmatchScoreboard

Draw instead of help message.
Note that it isn't that hard to overflow the 1400 byte message limit!
==================
*}
// (GAME=CTF)
procedure DeathmatchScoreboard (edict_t *ent);
begin
  DeathmatchScoreboardMessage (ent, ent.enemy);
  gi.unicast (ent, true);
end;//procedure (GAME=CTF)


{*
==================
Cmd_Score_f

Display the scoreboard
==================
*}
// GAME <> CTF
procedure Cmd_Score_f (edict_t *ent);
begin
  ent.client.showinventory := false;
  ent.client.showhelp := false;

{$IFDEF CTF}  //only CTF
//ZOID
  if (ent.client.menu) then
    PMenu_Close(ent);
//ZOID
{$ENDIF}

  if (!deathmatch.value AND !coop.value) then
    Exit;

  if (ent.client.showscores) then
  begin
    ent.client.showscores := false;
{$IFDEF CTF}  //only CTF
    ent.client.update_chase := true;
{$ENDIF}
    Exit;
  end;

  ent.client.showscores := true;

  DeathmatchScoreboard (ent);
end;//procedure (GAME <> CTF)


// (GAME=CTF)
{*
==================
HelpComputer

Draw help computer.
==================
*}
procedure HelpComputer (edict_t *ent);
var
   char   string[1024];
   char   *sk;
begin
  if (skill.value = 0)
  then sk := 'easy'
  else
    if (skill.value = 1)
    then sk := 'medium'
    else
      if (skill.value = 2)
      then sk := 'hard'
      else sk := 'hard+';
(*
//Y-code
Case skill.value od
  0:
  1:
  2:
  else
end;
*)

  // send the layout
(*  Com_sprintf (string, sizeof(string),
               "xv 32 yv 8 picn help "         // background
               "xv 202 yv 12 string2 \"%s\" "      // skill
               "xv 0 yv 24 cstring2 \"%s\" "      // level name
               "xv 0 yv 54 cstring2 \"%s\" "      // help 1
               "xv 0 yv 110 cstring2 \"%s\" "      // help 2
               "xv 50 yv 164 string2 \" kills     goals    secrets\" "
               "xv 50 yv 172 string2 \"%3i/%3i     %i/%i       %i/%i\" ",
               sk,
               level.level_name,
               game.helpmessage1,
               game.helpmessage2,
               level.killed_monsters, level.total_monsters,
               level.found_goals, level.total_goals,
               level.found_secrets, level.total_secrets);*)
//Y-check: EOL-marker???
  Com_sprintf (string, sizeof(string),
               'xv 32 yv 8 picn help '         // background
               'xv 202 yv 12 string2 \"%s\" '      // skill
               'xv 0 yv 24 cstring2 \"%s\" '      // level name
               'xv 0 yv 54 cstring2 \"%s\" '      // help 1
               'xv 0 yv 110 cstring2 \"%s\" '      // help 2
               'xv 50 yv 164 string2 \" kills     goals    secrets\" '
               'xv 50 yv 172 string2 \"%3i/%3i     %i/%i       %i/%i\" ',
               [sk,
                level.level_name,
                game.helpmessage1,
                game.helpmessage2,
                level.killed_monsters, level.total_monsters,
                level.found_goals, level.total_goals,
                level.found_secrets, level.total_secrets]);

  gi.WriteByte (svc_layout);
  gi.WriteString (string);
  gi.unicast (ent, true);
end;//procedure (GAME=CTF)


// GAME <> CTF
{*
==================
Cmd_Help_f

Display the current help message
==================
*}
procedure Cmd_Help_f (edict_t *ent);
begin
  // this is for backwards compatability
  if (deathmatch.value) then
  begin
    Cmd_Score_f (ent);
    Exit;
  end;

  ent.client.showinventory := false;
  ent.client.showscores := false;

{$IFDEF CTF}
  if (ent.client.showhelp AND (ent.client.resp.game_helpchanged = game.helpchanged)) then
{$ELSE}
  if (ent.client.showhelp AND (ent.client.pers.game_helpchanged = game.helpchanged)) then
{$ENDIF}
  begin
    ent.client.showhelp := false;
    Exit;
  end;

  ent.client.showhelp := true;

{$IFDEF CTF}
  ent.client.resp.helpchanged := 0;
{$ELSE}
  ent.client.pers.helpchanged := 0;
{$ENDIF}

  HelpComputer (ent);
end;//procedure (GAME <> CTF)


//=======================================================================

// GAME <> CTF
{*
===============
G_SetStats
===============
*}
procedure G_SetStats (edict_t *ent)
var
   gitem_t      *item;
  index, cells,
  power_armor_type : integer;
begin
  //
  // health
  //
  ent.client.ps.stats[STAT_HEALTH_ICON] := level.pic_health;
  ent.client.ps.stats[STAT_HEALTH] := ent.health;

  //
  // ammo
  //
  if (!ent.client.ammo_index (*idsoft/* || !ent->client->pers.inventory[ent->client->ammo_index] */*))
  then
    ent.client.ps.stats[STAT_AMMO_ICON] := 0;
    ent.client.ps.stats[STAT_AMMO] := 0;
  end
  else begin
    item = &itemlist[ent.client.ammo_index];
    ent.client.ps.stats[STAT_AMMO_ICON] := gi.imageindex (item.icon);
    ent.client.ps.stats[STAT_AMMO] := ent.client.pers.inventory[ent.client.ammo_index];
  end;

  //
  // armor
  //
  power_armor_type := PowerArmorType (ent);
  if (power_armor_type) then
  begin
    cells := ent.client.pers.inventory[ITEM_INDEX(FindItem ('cells'))];
    if (cells = 0) then
    begin
      // ran out of cells for power armor
//      ent->flags &= ~FL_POWER_ARMOR;
      ent.flags := ent.flags AND (NOT FL_POWER_ARMOR);
      gi.sound(ent, CHAN_ITEM, gi.soundindex('misc/power2.wav'), 1, ATTN_NORM, 0);
      power_armor_type := 0;;
    end;
  end;

  index := ArmorIndex (ent);
  if (power_armor_type AND (!index OR (level.framenum AND 8) ) )
  then begin
    // flash between power armor and other armor icon
    ent.client.ps.stats[STAT_ARMOR_ICON] := gi.imageindex ('i_powershield');
    ent.client.ps.stats[STAT_ARMOR] := cells;
  end
  else
    if (index<>0)
    then begin
      item = GetItemByIndex (index);
      ent.client.ps.stats[STAT_ARMOR_ICON] := gi.imageindex (item.icon);
      ent.client.ps.stats[STAT_ARMOR] := ent.client.pers.inventory[index];
    end
    else begin
     ent.client.ps.stats[STAT_ARMOR_ICON] := 0;
     ent.client.ps.stats[STAT_ARMOR] := 0;
    end;

  //
  // pickup message
  //
  if (level.time > ent.client.pickup_msg_time) then
  begin
    ent.client.ps.stats[STAT_PICKUP_ICON] := 0;
    ent.client.ps.stats[STAT_PICKUP_STRING] := 0;
  end;

  //
  // timers
  //
  if (ent.client.quad_framenum > level.framenum)
  then begin
    ent.client.ps.stats[STAT_TIMER_ICON] := gi.imageindex ('p_quad');
    ent.client.ps.stats[STAT_TIMER] := (ent.client.quad_framenum - level.framenum)/10;
  end
  else
    if (ent.client.invincible_framenum > level.framenum)
    then begin
      ent.client.ps.stats[STAT_TIMER_ICON] := gi.imageindex ('p_invulnerability');
      ent.client.ps.stats[STAT_TIMER] := (ent.client.invincible_framenum - level.framenum)/10;
    end
    else
      if (ent.client.enviro_framenum > level.framenum)
      then begin
        ent.client.ps.stats[STAT_TIMER_ICON] := gi.imageindex ('p_envirosuit');
        ent.client.ps.stats[STAT_TIMER] := (ent.client.enviro_framenum - level.framenum)/10;
      end
      else
        if (ent.client.breather_framenum > level.framenum)
        then begin
          ent.client.ps.stats[STAT_TIMER_ICON] := gi.imageindex ('p_rebreather');
          ent.client.ps.stats[STAT_TIMER] := (ent.client.breather_framenum - level.framenum)/10;
        end
        else begin
          ent.client.ps.stats[STAT_TIMER_ICON] := 0;
          ent.client.ps.stats[STAT_TIMER] := 0;
        end;

  //
  // selected item
  //
  if (ent.client.pers.selected_item = -1)
  then ent.client.ps.stats[STAT_SELECTED_ICON] := 0
  else ent.client.ps.stats[STAT_SELECTED_ICON] := gi.imageindex (itemlist[ent.client.pers.selected_item].icon);

  ent.client.ps.stats[STAT_SELECTED_ITEM] := ent.client.pers.selected_item;

  //
  // layouts
  //
  ent.client.ps.stats[STAT_LAYOUTS] := 0;

  if (deathmatch.value)
  then begin
    if (ent.client.pers.health <= 0 OR level.intermissiontime OR ent.client.showscores) then
      ent.client.ps.stats[STAT_LAYOUTS] := ent.client.ps.stats[STAT_LAYOUTS] OR 1;
    if (ent.client.showinventory AND ent.client.pers.health > 0) then
      ent.client.ps.stats[STAT_LAYOUTS] := ent.client.ps.stats[STAT_LAYOUTS] OR 2;
  end
  else begin
    if (ent.client.showscores OR ent.client.showhelp) then
      ent.client.ps.stats[STAT_LAYOUTS] := ent.client.ps.stats[STAT_LAYOUTS] OR 1;
    if (ent.client.showinventory AND ent.client.pers.health > 0) then
      ent.client.ps.stats[STAT_LAYOUTS] := ent.client.ps.stats[STAT_LAYOUTS] OR 2;
  end;

  //
  // frags
  //
  ent.client.ps.stats[STAT_FRAGS] := ent.client.resp.score;

  //
  // help icon / current weapon if not shown
  //

{$IFDEF CTF}
  if (ent.client.resp.helpchanged && (level.framenum&8) )
{$ELSE}
  if (ent.client.pers.helpchanged && (level.framenum&8) )
{$ENDIF}
  then ent.client.ps.stats[STAT_HELPICON] := gi.imageindex ('i_help');
  else
    if ( (ent.client.pers.hand = CENTER_HANDED OR ent.client.ps.fov > 91) && ent.client.pers.weapon)
    then ent.client.ps.stats[STAT_HELPICON] := gi.imageindex (ent.client.pers.weapon.icon);
    else ent.client.ps.stats[STAT_HELPICON] := 0;

{$IFDEF CTF}
//ZOID
  SetCTFStats(ent);
//ZOID
{$ELSE}
  ent.client.ps.stats[STAT_SPECTATOR] := 0;
{$ENDIF}
end;//procedure (GAME <> CTF)


{$IFNEF CTF}
{*
===============
G_CheckChaseStats
===============
*}
//only GAME
procedure G_CheckChaseStats (edict_t *ent);
var
  i : integer;
   gclient_t *cl;
begin
  for i:=1 to maxclients.value do
  begin
    cl := g_edicts[i].client;
    if (!g_edicts[i].inuse) OR (cl.chase_target <> ent)
      Continue;
    memcpy(cl->ps.stats, ent->client->ps.stats, sizeof(cl->ps.stats));
    G_SetSpectatorStats(g_edicts + i);
  end;
end;//procedure (onlyGAME)

//only GAME
{*
===============
G_SetSpectatorStats
===============
*}
procedure G_SetSpectatorStats (edict_t *ent);
begin
  gclient_t *cl = ent->client;

  if (!cl.chase_target) then
    G_SetStats (ent);

  cl.ps.stats[STAT_SPECTATOR] := 1;

  // layouts are independant in spectator
  cl.ps.stats[STAT_LAYOUTS] := 0;
  if (cl.pers.health <= 0 OR level.intermissiontime OR cl.showscores) then
    cl.ps.stats[STAT_LAYOUTS] := cl.ps.stats[STAT_LAYOUTS] OR 1;
  if (cl.showinventory AND cl.pers.health > 0) then
    cl.ps.stats[STAT_LAYOUTS] := cl.ps.stats[STAT_LAYOUTS] OR 2;

  if (cl.chase_target && cl.chase_target.inuse)
  then cl.ps.stats[STAT_CHASE] := CS_PLAYERSKINS + (cl.chase_target - g_edicts) - 1
  else cl.ps.stats[STAT_CHASE] := 0;
end;//procedure (onlyGAME)
{$ENDIF}

// End of file
