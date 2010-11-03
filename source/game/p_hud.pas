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


//99%
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
{ Updated on :  2003-04-07                                                   }
{ Updated by :  Scott price                                                  }
{                                                                            }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{ 1) unit g_local                                                            }
{                                                                            }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{ 1) Do more tests                                                           }
{ 2) Checks of the CTF Code still left                                       }
{                                                                            }
{----------------------------------------------------------------------------}

unit p_hud;

interface

uses
  q_shared,
  g_local;

procedure MoveClientToIntermission (ent : edict_p);  //for p_client

procedure DeathmatchScoreboardMessage (ent, killer : edict_p);  //for p_view
procedure G_SetStats (ent : edict_p);  //for p_view
procedure Cmd_Help_f (ent : edict_p);
procedure BeginIntermission (targ : edict_p);
procedure Cmd_Score_f (ent : edict_p);

{$IFNDEF CTF}
procedure G_CheckChaseStats (ent : edict_p);  //for p_view
procedure G_SetSpectatorStats (ent : edict_p);  //for p_view
{$ENDIF}


implementation

uses
  GameUnit,
  q_shared_add,
  game_add,
  g_main,
  g_items,
  p_client,
  CPas,
  g_utils,
  g_save;


{*
======================================================================

INTERMISSION

======================================================================
*}

procedure MoveClientToIntermission (ent : edict_p);
begin
  if (deathmatch^.value <> 0) OR (coop^.value <> 0) then
    ent^.client^.showscores := true;
  VectorCopy (level.intermission_origin, ent^.s.origin);
  ent^.client^.ps.pmove.origin[0] := trunc(level.intermission_origin[0] *8);
  ent^.client^.ps.pmove.origin[1] := trunc(level.intermission_origin[1] *8);
  ent^.client^.ps.pmove.origin[2] := trunc(level.intermission_origin[2] *8);
  VectorCopy (level.intermission_angle, ent^.client^.ps.viewangles);
  ent^.client^.ps.pmove.pm_type := PM_FREEZE;
  ent^.client^.ps.gunindex := 0;
  ent^.client^.ps.blend[3] := 0;
  ent^.client^.ps.rdflags := ent^.client^.ps.rdflags AND (NOT RDF_UNDERWATER);

  // clean up powerup info
  ent^.client^.quad_framenum := 0;
  ent^.client^.invincible_framenum := 0;
  ent^.client^.breather_framenum := 0;
  ent^.client^.enviro_framenum := 0;
  ent^.client^.grenade_blew_up := false;
  ent^.client^.grenade_time := 0;

  ent^.viewheight := 0;
  ent^.s.modelindex := 0;
  ent^.s.modelindex2 := 0;
  ent^.s.modelindex3 := 0;
  ent^.s.modelindex := 0;
  ent^.s.effects := 0;
  ent^.s.sound := 0;
  ent^.solid := SOLID_NOT;

  // add the layout

  if (deathmatch^.value <> 0) OR (coop^.value <> 0) then
  begin
    DeathmatchScoreboardMessage (ent, Nil);
    gi.unicast (ent, true);
  end;
end;


procedure BeginIntermission (targ : edict_p);
var
  i, n : integer;
  ent, client : edict_p;
begin
  if (level.intermissiontime <> 0) then
    Exit;   // already activated

{$IFDEF CTF}  //only CTF
(*Y//ZOID
  if (deathmatch.value AND ctf.value) then
    CTFCalcScores();
//ZOID*)
{$ENDIF}

  game.autosaved := false;

  // respawn any dead clients
  for i := 0 to Trunc(maxclients^.value)-1 do
  begin
    client := @g_edicts^[1 + i];
    if (NOT client^.inuse) then
      Continue;
    if (client^.health <= 0) then
      respawn (client);
  end;

  level.intermissiontime := level.time;
  level.changemap := targ^.map;

  if (strstr(level.changemap, '*') <> nil) then
  begin
    if (coop^.value <> 0) then
      for i := 0 to Trunc(maxclients^.value)-1 do
      begin
        client := @g_edicts^[1 + i];
        if (NOT client^.inuse) then
          Continue;
        // strip players of all keys between units
        for n := 0 to MAX_ITEMS-1 do
          if (itemlist[n].flags AND IT_KEY) <> 0 then
            client^.client^.pers.inventory[n] := 0;
      end;
  end
  else
  begin
    if (deathmatch^.value = 0) then
    begin
      level.exitintermission := 1;    // go immediately to the next level
      Exit;
    end;
  end;

  level.exitintermission := 0;

  // find an intermission spot
  ent := G_Find (NULL, FOFS_classname, 'info_player_intermission');
  if (ent = Nil) then
  begin
    // the map creator forgot to put in an intermission point...
    ent := G_Find (NULL, FOFS_classname, 'info_player_start');
    if (ent = Nil) then
      ent := G_Find (NULL, FOFS_classname, 'info_player_deathmatch');
  end
  else
  begin
    // chose one of four spots
    i := rand() mod 3;
    while (i <> 0) do
    begin
      Dec(i);  { SP:  Operation really should occur immediately after evaluator }
      ent := G_Find (ent, FOFS_classname, 'info_player_intermission');
      if (ent = Nil) then // wrap around the list
        ent := G_Find (ent, FOFS_classname, 'info_player_intermission');
    end;
  end;

  VectorCopy (ent^.s.origin, level.intermission_origin);
  VectorCopy (ent^.s.angles, level.intermission_angle);

  // move all clients to the intermission point
  for i := 0 to Trunc(maxclients^.value)-1 do
  begin
    client := @g_edicts^[1 + i];
    if (NOT client^.inuse) then
      Continue;
    MoveClientToIntermission (client);
  end;
end;


{*
==================
DeathmatchScoreboardMessage
==================
*}
procedure DeathmatchScoreboardMessage (ent, killer : edict_p);
var
  entry : array[0..1024-1] of char;
  string_ : array[0..1400-1] of char;

  stringlength,
  i, j, k,
  score, total,
  x, y,
  picnum        : integer;

  sorted,
  sortedscores  : array [0..MAX_CLIENTS-1] of integer;

  cl : gclient_p;
  cl_ent : edict_p;
  tag : PChar;
begin
{$IFDEF CTF}  //only CTF
(*Y//ZOID
  if (ctf.value) then
  begin
    CTFScoreboardMessage (ent, killer);
    Exit;
  end;
//ZOID*)
{$ENDIF}

  // sort the clients by score
  total := 0;
  for i := 0 to game.maxclients-1 do
  begin
    cl_ent := @g_edicts^[1 + i];

{$IFDEF CTF}
    if (NOT cl_ent^.inuse) then
      Continue;
{$ELSE}
    if (not cl_ent^.inuse) OR (gclient_a(game.clients)[i].resp.spectator) then
      Continue;
{$ENDIF}

    score := gclient_a(game.clients)[i].resp.score;
    j := 0;
    while j < total do
    begin
      if (score > sortedscores[j]) then
        Break;

      Inc(j);
    end;

    k := total;
    while k > j do
    begin
      sorted[k] := sorted[k-1];
      sortedscores[k] := sortedscores[k-1];
      Dec(k);
    end;

    sorted[j] := i;
    sortedscores[j] := score;
    Inc(total);
  end;

  // print level name and exit rules
  string_[0] := #0;

  stringlength := strlen(string_);

  // add the clients in sorted order
  if (total > 12) then
    total := 12;

  for i := 0 to total-1 do
  begin
    cl := @gclient_a(game.clients)[sorted[i]];
    cl_ent := @g_edicts^[1 + sorted[i]];

    picnum := gi.imageindex ('i_fixme');

    if (i >= 6) then
      x := 160
    else
      x := 0;

    y := 32 + 32 * (i MOD 6);

    // add a dogtag
    if (cl_ent = ent) then
      tag := 'tag1'
    else if (cl_ent = killer) then
      tag := 'tag2'
    else
      tag := nil;
    if (tag <> nil) then
    begin
      Com_sprintf (entry, SizeOf(entry), 'xv %i yv %i picn %s ',[x+32, y, Tag]);
      j := strlen(entry);
      if (stringlength + j > 1024) then
        Break;
      strcpy (string_ + stringlength, entry);
      stringlength := stringlength + j;
    end;

    // send the layout
    Com_sprintf (entry, SizeOf(entry),
                 'client %i %i %i %i %i %i ',
                 [x, y, sorted[i], cl^.resp.score, cl^.ping, (level.framenum - cl^.resp.enterframe) div 600]);
    j := strlen(entry);
    if (stringlength + j > 1024) then
      Break;
    strcpy (string_ + stringlength, entry);
    Inc(stringlength, j);
  end;

  gi.WriteByte (svc_layout);
  gi.WriteString (string_);
end;


{*
==================
DeathmatchScoreboard

Draw instead of help message.
Note that it isn't that hard to overflow the 1400 byte message limit!
==================
*}
procedure DeathmatchScoreboard (ent : edict_p);
begin
  DeathmatchScoreboardMessage (ent, ent^.enemy);
  gi.unicast (ent, true);
end;


{*
==================
Cmd_Score_f

Display the scoreboard
==================
*}
procedure Cmd_Score_f (ent : edict_p);
begin
  ent^.client^.showinventory := false;
  ent^.client^.showhelp := false;

{$IFDEF CTF}  //only CTF
(*Y//ZOID
  if (ent.client.menu) then
    PMenu_Close(ent);
//ZOID*)
{$ENDIF}

  if (deathmatch^.value = 0) AND (coop^.value = 0) then
    Exit;

  if (ent^.client^.showscores) then
  begin
    ent^.client^.showscores := false;
{$IFDEF CTF}  //only CTF
    ent^.client^.update_chase := true;
{$ENDIF}
    Exit;
  end;

  ent^.client^.showscores := true;

  DeathmatchScoreboard (ent);
end;


{*
==================
HelpComputer

Draw help computer.
==================
*}
procedure HelpComputer (ent : edict_p);
var
  string_ : array [0..1023] of char;
  sk : PChar;
begin
  if (skill^.value = 0) then
    sk := 'easy'
  else if (skill^.value = 1) then
    sk := 'medium'
  else if (skill^.value = 2) then
    sk := 'hard'
  else
    sk := 'hard+';

  // send the layout
  Com_sprintf (string_, SizeOf(string_),
               'xv 32 yv 8 picn help '+         // background
               'xv 202 yv 12 string2 "%s" '+      // skill
               'xv 0 yv 24 cstring2 "%s" '+      // level name
               'xv 0 yv 54 cstring2 "%s" '+      // help 1
               'xv 0 yv 110 cstring2 "%s" '+      // help 2
               'xv 50 yv 164 string2 " kills     goals    secrets" '+
               'xv 50 yv 172 string2 "%3i/%3i     %i/%i       %i/%i" ',
               [sk,
                level.level_name,
                game.helpmessage1,
                game.helpmessage2,
                level.killed_monsters, level.total_monsters,
                level.found_goals, level.total_goals,
                level.found_secrets, level.total_secrets]);

  gi.WriteByte (svc_layout);
  gi.WriteString (string_);
  gi.unicast (ent, true);
end;


{*
==================
Cmd_Help_f

Display the current help message
==================
*}
procedure Cmd_Help_f (ent : edict_p);
begin
  // this is for backwards compatability
  if (deathmatch^.value <> 0) then
  begin
    Cmd_Score_f (ent);
    Exit;
  end;

  ent^.client^.showinventory := false;
  ent^.client^.showscores := false;

{$IFDEF CTF}
  if (ent^.client^.showhelp AND (ent^.client^.resp.game_helpchanged = game.helpchanged)) then
{$ELSE}
  if (ent^.client^.showhelp AND (ent^.client^.pers.game_helpchanged = game.helpchanged)) then
{$ENDIF}
  begin
    ent^.client^.showhelp := false;
    Exit;
  end;

  ent^.client^.showhelp := true;

{$IFDEF CTF}
  ent^.client^.resp.helpchanged := 0;
{$ELSE}
  ent^.client^.pers.helpchanged := 0;
{$ENDIF}

  HelpComputer (ent);
end;


//=======================================================================

{*
===============
G_SetStats
===============
*}
procedure G_SetStats (ent : edict_p);
var
  item : gitem_p;
  index, cells,
  power_armor_type : integer;
begin
  //
  // health
  //
  ent^.client^.ps.stats[STAT_HEALTH_ICON] := level.pic_health;
  ent^.client^.ps.stats[STAT_HEALTH] := ent^.health;

  //
  // ammo
  //
  if (ent^.client^.ammo_index = 0) then  //idsoft/* || !ent->client->pers.inventory[ent->client->ammo_index] */
  begin
    ent^.client^.ps.stats[STAT_AMMO_ICON] := 0;
    ent^.client^.ps.stats[STAT_AMMO] := 0;
  end
  else begin
    item := @itemlist[ent^.client^.ammo_index];
    ent^.client^.ps.stats[STAT_AMMO_ICON] := gi.imageindex (item^.icon);
    ent^.client^.ps.stats[STAT_AMMO] := ent^.client^.pers.inventory[ent^.client^.ammo_index];
  end;

  //
  // armor
  //
  power_armor_type := PowerArmorType (ent);
  if (power_armor_type <> 0) then
  begin
    cells := ent^.client^.pers.inventory[ITEM_INDEX(FindItem ('cells'))];
    if (cells = 0) then
    begin
      // ran out of cells for power armor
      ent^.flags := ent^.flags AND (NOT FL_POWER_ARMOR);
      gi.sound(ent, CHAN_ITEM, gi.soundindex('misc/power2.wav'), 1, ATTN_NORM, 0);
      power_armor_type := 0;
    end;
  end;

  index := ArmorIndex (ent);
  if (power_armor_type <> 0) AND
     ((index = 0) OR ((level.framenum AND 8) <> 0)) then
  begin
    // flash between power armor and other armor icon
    ent^.client^.ps.stats[STAT_ARMOR_ICON] := gi.imageindex ('i_powershield');
    ent^.client^.ps.stats[STAT_ARMOR] := cells;
  end
  else if (index <> 0) then
  begin
    item := GetItemByIndex (index);
    ent^.client^.ps.stats[STAT_ARMOR_ICON] := gi.imageindex (item^.icon);
    ent^.client^.ps.stats[STAT_ARMOR] := ent^.client^.pers.inventory[index];
  end
  else
  begin
    ent^.client^.ps.stats[STAT_ARMOR_ICON] := 0;
    ent^.client^.ps.stats[STAT_ARMOR] := 0;
  end;

  //
  // pickup message
  //
  if (level.time > ent^.client^.pickup_msg_time) then
  begin
    ent^.client^.ps.stats[STAT_PICKUP_ICON] := 0;
    ent^.client^.ps.stats[STAT_PICKUP_STRING] := 0;
  end;

  //
  // timers
  //
  if (ent^.client^.quad_framenum > level.framenum) then
  begin
    ent^.client^.ps.stats[STAT_TIMER_ICON] := gi.imageindex ('p_quad');
    ent^.client^.ps.stats[STAT_TIMER] := trunc((ent^.client^.quad_framenum - level.framenum)/10);
  end
  else if (ent^.client^.invincible_framenum > level.framenum) then
  begin
    ent^.client^.ps.stats[STAT_TIMER_ICON] := gi.imageindex ('p_invulnerability');
    ent^.client^.ps.stats[STAT_TIMER] := trunc((ent^.client^.invincible_framenum - level.framenum)/10);
  end
  else if (ent^.client^.enviro_framenum > level.framenum) then
  begin
    ent^.client^.ps.stats[STAT_TIMER_ICON] := gi.imageindex ('p_envirosuit');
    ent^.client^.ps.stats[STAT_TIMER] := trunc((ent^.client^.enviro_framenum - level.framenum)/10);
  end
  else if (ent^.client^.breather_framenum > level.framenum) then
  begin
    ent^.client^.ps.stats[STAT_TIMER_ICON] := gi.imageindex ('p_rebreather');
    ent^.client^.ps.stats[STAT_TIMER] := trunc((ent^.client^.breather_framenum - level.framenum)/10);
  end
  else
  begin
    ent^.client^.ps.stats[STAT_TIMER_ICON] := 0;
    ent^.client^.ps.stats[STAT_TIMER] := 0;
  end;

  //
  // selected item
  //
  if (ent^.client^.pers.selected_item = -1) then
    ent^.client^.ps.stats[STAT_SELECTED_ICON] := 0
  else
    ent^.client^.ps.stats[STAT_SELECTED_ICON] := gi.imageindex (itemlist[ent^.client^.pers.selected_item].icon);

  ent^.client^.ps.stats[STAT_SELECTED_ITEM] := ent^.client^.pers.selected_item;

  //
  // layouts
  //
  ent^.client^.ps.stats[STAT_LAYOUTS] := 0;

  if (deathmatch^.value <> 0) then
  begin
    if (ent^.client^.pers.health <= 0) OR (level.intermissiontime <> 0) OR
       (ent^.client^.showscores) then
      ent^.client^.ps.stats[STAT_LAYOUTS] := ent^.client^.ps.stats[STAT_LAYOUTS] OR 1;
    if (ent^.client^.showinventory) AND (ent^.client^.pers.health > 0) then
      ent^.client^.ps.stats[STAT_LAYOUTS] := ent^.client^.ps.stats[STAT_LAYOUTS] OR 2;
  end
  else begin
    if (ent^.client^.showscores OR ent^.client^.showhelp) then
      ent^.client^.ps.stats[STAT_LAYOUTS] := ent^.client^.ps.stats[STAT_LAYOUTS] OR 1;
    if (ent^.client^.showinventory) AND (ent^.client^.pers.health > 0) then
      ent^.client^.ps.stats[STAT_LAYOUTS] := ent^.client^.ps.stats[STAT_LAYOUTS] OR 2;
  end;

  //
  // frags
  //
  ent^.client^.ps.stats[STAT_FRAGS] := ent^.client^.resp.score;

  //
  // help icon / current weapon if not shown
  //
{$IFDEF CTF}
  if (ent^.client^.resp.helpchanged && (level.framenum&8) ) then
{$ELSE}
  if (ent^.client^.pers.helpchanged <> 0) and ((level.framenum and 8) <> 0) then
{$ENDIF}
    ent^.client^.ps.stats[STAT_HELPICON] := gi.imageindex ('i_help')
  else if ((ent^.client^.pers.hand = CENTER_HANDED) OR (ent^.client^.ps.fov > 91)) and (ent^.client^.pers.weapon <> nil) then
    ent^.client^.ps.stats[STAT_HELPICON] := gi.imageindex (ent^.client^.pers.weapon^.icon)
  else
    ent^.client^.ps.stats[STAT_HELPICON] := 0;

{$IFDEF CTF}
//ZOID
  SetCTFStats(ent);
//ZOID
{$ELSE}
  ent^.client^.ps.stats[STAT_SPECTATOR] := 0;
{$ENDIF}

end;


{$IFNDEF CTF}
{*
===============
G_CheckChaseStats
===============
*}
procedure G_CheckChaseStats (ent : edict_p);
var
  i : integer;
  cl : gclient_p;
begin
  for i := 1 to Trunc(maxclients^.value) do
  begin
    cl := g_edicts^[i].client;
    if (NOT g_edicts^[i].inuse) OR (cl^.chase_target <> ent) then
      Continue;
    memcpy(@cl^.ps.stats[0], @ent^.client^.ps.stats[0], sizeof(cl^.ps.stats));
    G_SetSpectatorStats(@g_edicts^[i]);
  end;
end;

{*
===============
G_SetSpectatorStats
===============
*}
procedure G_SetSpectatorStats (ent : edict_p);
var
  cl : gclient_p;
begin
  cl := ent^.client;

  if (cl^.chase_target = Nil) then
    G_SetStats (ent);

  cl^.ps.stats[STAT_SPECTATOR] := 1;

  // layouts are independant in spectator
  cl^.ps.stats[STAT_LAYOUTS] := 0;
  if (cl^.pers.health <= 0) OR (level.intermissiontime <> 0) OR (cl^.showscores) then
    cl^.ps.stats[STAT_LAYOUTS] := cl^.ps.stats[STAT_LAYOUTS] OR 1;
  if (cl^.showinventory) AND (cl^.pers.health > 0) then
    cl^.ps.stats[STAT_LAYOUTS] := cl^.ps.stats[STAT_LAYOUTS] OR 2;

  if (cl^.chase_target <> Nil) AND (cl^.chase_target^.inuse) then
    cl^.ps.stats[STAT_CHASE] := CS_PLAYERSKINS + (Cardinal(cl^.chase_target) - Cardinal(g_edicts)) div SizeOf(edict_t) - 1
  else
    cl^.ps.stats[STAT_CHASE] := 0;
end;
{$ENDIF}

// End of file
end.


