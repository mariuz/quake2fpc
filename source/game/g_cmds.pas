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
{ File(s): g_cmds.h                                                          }
{                                                                            }
{ Initial conversion by : Burnin (Leonel Togniolli) - leonel@linuxbr.com.br  }
{ Initial conversion on : 26-Jan-2002                                        }
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

unit g_cmds;

interface

uses
  CPas,
  g_local,
  q_shared;

procedure ClientCommand(ent : edict_p); cdecl;
function OnSameTeam (ent1 : edict_p;ent2 : edict_p): qboolean; // added by FAB
procedure ValidateSelectedItem(ent : edict_p);


implementation

uses
  sysutils,
  g_chase,
  p_hud,
  g_items,
  g_utils,
  m_player,
  gameUnit,
  g_main,
  p_client,
  g_local_add;



function ClientTeam(ent : edict_p): PChar;
var   p : PChar;
      Value : array[0..512-1] of char;
begin
  Value := '';

  if not Assigned(ent.client) then
  begin
    Result := Value;
    Exit;
  end;

  strpcopy(Value,Info_ValueForKey(ent.client.pers.userinfo,'skin'));

  p := StrPos(Value,'/');
  if p = nil then
  begin
    Result := Value;
    Exit;
  end;

  if trunc(dmflags.Value) and DF_MODELTEAMS <> 0 then
  begin
    p^ := #0;
    Result := Value;
    Exit;
  end;

  //if trunc(dmflags.Value) and DF_SKINTEAMS <> 0 then {Originally commented}
  Inc(p);
  Result := p;
end;


function OnSameTeam (ent1 : edict_p;ent2 : edict_p): qboolean;
var ent1Team,
    ent2Team  : array[0..512-1] of char;
begin
  if trunc(dmflags.Value) and (DF_MODELTEAMS or DF_SKINTEAMS) = 0 then
  begin
    Result := False;
    Exit;
  end;

  strpcopy(ent1Team,ClientTeam(ent1));
  strpcopy(ent2Team,ClientTeam(ent2));

  Result := strcomp(ent1Team,ent2Team) = 0;
end;

procedure SelectNextItem(ent : edict_p;itflags : Integer);
var cl : gclient_p;
    i,Index : Integer;
    it : gitem_p;
begin
  cl := ent.client;
  if assigned(cl.chase_target) then
  begin
    ChaseNext(ent);
    Exit;
  end;
  // scan  for the next valid one
  for i := 1 to MAX_ITEMS do
  begin
    Index := (cl.pers.selected_item + i) mod MAX_ITEMS;
    if cl.pers.inventory[Index] = 0 then
      continue;
    it := @itemlist[Index];
    if not assigned(it.use) then
      continue;
    if it.flags and itflags = 0 then
      continue;

    cl.pers.selected_item := Index;
    Exit;
  end;

  cl.pers.selected_item := -1;
end;

procedure SelectPrevItem(ent : edict_p;itflags : Integer);
var cl : gclient_p;
    i,Index : integer;
    it : gitem_p;
begin
  cl := ent.client;
  if Assigned(cl.chase_target) then
  begin
    ChasePrev(ent);
    Exit;
  end;
  // scan  for the next valid one
  for i := 1 to MAX_ITEMS do
  begin
    Index := (cl.pers.selected_item + MAX_ITEMS - i) mod MAX_ITEMS;
    if cl.pers.inventory[Index] = 0 then
      continue;
    it := @itemlist[Index];
    if not assigned(it.use) then
      continue;
    if it.flags and itflags = 0 then
      continue;

    cl.pers.selected_item := Index;
    Exit;
  end;

  cl.pers.selected_item := -1;
end;

procedure ValidateSelectedItem(ent : edict_p);
var cl : gclient_p;
begin
  cl := ent.client;
  if cl.pers.inventory[cl.pers.selected_item] <> 0 then
    Exit;       // valid
  SelectNextItem(ent, -1);
end;

//=================================================================================

{
==================
Cmd_Give_f

Give items to a client
==================
}

procedure Cmd_Give_f(ent : edict_p);
var Name     : PChar;
    it       : gitem_p;
    Index    : Integer;
    i        : Integer;
    give_all : qboolean;
    it_ent   : edict_p;
    info     : gitem_armor_p;

begin
  if (trunc(deathmatch.Value) <> 0) and (trunc(sv_cheats.Value) = 0) then
  begin
    gi.cprintf(ent,PRINT_HIGH,'You must run the server with ''+set cheats 1'' to enable this command.'+#10);
    Exit;
  end;

  Name := gi.args();

  if q_stricmp(Name,'all') = 0 then
    give_all := True
  else
    give_all := False;
  if give_all or (q_stricmp(gi.argv(1),'health') = 0) then
  begin
    if gi.argc() = 3 then
      ent.health := StrToInt(gi.argv(2))
    else
      ent.health := ent.max_health;
    if not give_all then
      Exit;
  end;

  if give_all or (q_stricmp(name,'weapons') = 0) then
  begin
    for i := 0 to game.num_items - 1 do
    begin
      it := @itemlist[i];
      if not Assigned(it.pickup) then
        continue;
      if (it.flags and IT_WEAPON) = 0 then
        continue;
      ent.client.pers.inventory[i] := ent.client.pers.inventory[i] + 1;
    end;
    if not give_all then
      Exit;
  end;

  if give_all or (q_stricmp(name,'ammo') = 0) then
  begin
    for i := 0 to game.num_items - 1 do
    begin
      it := @itemlist[i];
      if not Assigned(it.pickup) then
        continue;
      if (it.flags and IT_AMMO) = 0 then
        continue;
      Add_Ammo(ent,it,1000);
    end;
    if not give_all then
      exit;
  end;

  if give_all or (q_stricmp(name,'armor') = 0) then
  begin
    it := FindItem('Jacket Armor');
    ent.client.pers.inventory[ITEM_INDEX(it)] := 0;

    it := FindItem('Combat Armor');
    ent.client.pers.inventory[ITEM_INDEX(it)] := 0;

    it := FindItem('Body Armor');
    info := gitem_armor_p(it.info);
    ent.client.pers.inventory[ITEM_INDEX(it)] := info.max_count;

    if not give_all then
      Exit;
  end;

  if give_all or (q_stricmp(name,'Power Shield') = 0) then
  begin
    it := FindItem('Power Shield');
    it_ent := G_Spawn;
    it_ent.classname := it.classname;
    SpawnItem(it_ent, it);
    Touch_Item(it_ent,ent, nil, nil);
    if it_ent.inuse then
      G_FreeEdict(it_ent);

    if not give_all then
      Exit;
  end;

  if give_all then
  begin
    for i := 0 to game.num_items - 1 do
    begin
      it := @itemlist[i];
      if not Assigned(it.pickup) then
        continue;
      if (it.flags and (IT_AMMO or IT_WEAPON or IT_AMMO)) <> 0 then
        continue;
      ent.client.pers.inventory[i] := 1;
    end;
    Exit;
  end;

  it := FindItem(Name);
  if not Assigned(it) then
  begin
    Name := gi.argv(1);
    it := FindItem(Name);
    if not Assigned(it) then
    begin
      gi.cprintf(ent,PRINT_HIGH,'unknown item'+#10);
      Exit;
    end;
  end;

  if not Assigned(it.pickup) then
  begin
    gi.cprintf(ent,PRINT_HIGH,'non-pickup item'+#10);
    Exit;
  end;

  index := ITEM_INDEX(it);

  if (it.flags and IT_AMMO) <> 0 then
  begin
    if gi.argc() = 3 then
      ent.client.pers.inventory[Index] := StrToInt(gi.argv(2))
    else
      ent.client.pers.inventory[Index] := ent.client.pers.inventory[Index] + it.quantity;
  end else
  begin
    it_ent := G_Spawn;
    it_ent.classname := it.classname;
    SpawnItem(it_ent,it);
    Touch_Item(it_ent,ent,nil,nil);
    if it_ent.inuse then
      G_FreeEdict(it_ent);
  end;
end;

{
==================
Cmd_God_f

Sets client to godmode

argv(0) god
==================
}
procedure Cmd_God_f (ent : edict_p);
var Msg : PChar;
begin
  if (trunc(deathmatch.Value) <> 0) and (trunc(sv_cheats.Value) = 0) then
  begin
    gi.cprintf(ent,PRINT_HIGH,'You must run the server with ''+set cheats 1'' to enable this command.'+#10);
    Exit;
  end;
  ent.flags := ent.flags xor FL_GODMODE;
  if (ent.flags and FL_GODMODE) = 0 then
    Msg := 'godmode OFF'+#10
  else
    Msg := 'godmode ON'+#10;

  gi.cprintf(ent,PRINT_HIGH,Msg);
end;


{
==================
Cmd_Notarget_f

Sets client to notarget

argv(0) notarget
==================
}
procedure Cmd_Notarget_f(ent : edict_p);
var Msg : PChar;
begin
  if (trunc(deathmatch.Value) <> 0) and (trunc(sv_cheats.Value) = 0) then
  begin
    gi.cprintf(ent,PRINT_HIGH,'You must run the server with ''+set cheats 1'' to enable this command.'+#10);
    Exit;
  end;
  ent.flags := ent.flags xor FL_NOTARGET;
  if (ent.flags and FL_NOTARGET) = 0 then
    Msg := 'notarget OFF'+#10
  else
    Msg := 'notarget ON'+#10;

  gi.cprintf(ent,PRINT_HIGH,Msg);
end;

{
==================
Cmd_Noclip_f

argv(0) noclip
==================
}
procedure Cmd_Noclip_f(ent : edict_p);
var Msg : PChar;
begin
  if (trunc(deathmatch.Value) <> 0) and (trunc(sv_cheats.Value) = 0) then
  begin
    gi.cprintf(ent,PRINT_HIGH,'You must run the server with ''+set cheats 1'' to enable this command.'+#10);
    Exit;
  end;
  if ent.movetype = MOVETYPE_NOCLIP then
  begin
    ent.movetype := MOVETYPE_WALK;
    Msg := 'noclip OFF'+#10;
  end else
  begin
    ent.movetype := MOVETYPE_NOCLIP;
    Msg := 'noclip ON'+#10;
  end;
  gi.cprintf(ent,PRINT_HIGH,Msg);
end;


{
==================
Cmd_Use_f

Use an inventory item
==================
}
procedure Cmd_Use_f(ent : edict_p);
var Index : Integer;
    it    : gitem_p;
    s     : PChar;
begin
  s := gi.args;
  it := FindItem(s);
  if it = nil then
  begin
    gi.cprintf(ent,PRINT_HIGH,'unknown item : %s'+#10,s);
    Exit;
  end;
  if @it.use = nil then
  begin
    gi.cprintf(ent, PRINT_HIGH, 'Item is not usable.'+#10);
    Exit;
  end;
  Index := ITEM_INDEX(it);
  if ent.client.pers.inventory[Index] = 0 then
  begin
    gi.cprintf(ent, PRINT_HIGH, 'Out of item: %s'+#10, s);
    Exit;
  end;
  it.use(ent,it);
end;

{
==================
Cmd_Drop_f

Drop an inventory item
==================
}
procedure Cmd_Drop_f(ent : edict_p);
var Index : Integer;
    it    : gitem_p;
    s     : PChar;
begin
  S := gi.args;
  it := FindItem(s);
  if not Assigned(It) then
  begin
    gi.cprintf(ent,PRINT_HIGH,'unknown item : %s'+#10,s);
    Exit;
  end;
  if not Assigned(it.drop) then
  begin
    gi.cprintf(ent, PRINT_HIGH, 'Item is not dropable.'+#10);
    Exit;
  end;
  Index := ITEM_INDEX(it);
  if ent.client.pers.inventory[Index] = 0 then
  begin
    gi.cprintf(ent, PRINT_HIGH, 'Out of item: %s'+#10, s);
    Exit;
  end;
  it.drop(ent,it);
end;


{
=================
Cmd_Inven_f
=================
}
procedure Cmd_Inven_f(ent : edict_p);
var i : Integer;
    cl : gclient_p;
begin
  cl := ent.client;

  cl.showscores := False;
  cl.showhelp := False;
  if cl.showinventory then
  begin
    cl.showinventory := False;
    Exit;
  end;

  cl.showinventory :=  True;
  gi.WriteByte(svc_inventory);

  for i := 0 to MAX_ITEMS - 1 do
  begin
    gi.WriteShort(cl.pers.inventory[i]);
  end;
  gi.unicast(ent,True);
end;

{
=================
Cmd_InvUse_f
=================
}
procedure Cmd_InvUse_f(ent : edict_p);
var it : gitem_p;
begin
  ValidateSelectedItem(ent);

  if ent.client.pers.selected_item = -1 then
  begin
    gi.cprintf (ent, PRINT_HIGH, 'No item to use.'+#10);
    Exit;
  end;

  it := @itemlist[ent.client.pers.selected_item];

  if not Assigned(it.use) then
  begin
    gi.cprintf(ent, PRINT_HIGH, 'Item is not usable.'+#10);
    Exit;
  end;

  it.use(ent,it);
end;

{
=================
Cmd_WeapPrev_f
=================
}
procedure Cmd_WeapPrev_f(ent :edict_p);
var cl : gclient_p;
    i,Index : Integer;
    it : gitem_p;
    selected_weapon : Integer;
begin
  cl := ent.client;
  if not Assigned(cl.pers.weapon) then
    Exit;

  selected_weapon := ITEM_INDEX(cl.pers.weapon);

  //scan for the next valid one
  for i := 1 to MAX_ITEMS do
  begin
    Index := (selected_weapon + i) mod MAX_ITEMS;
    if cl.pers.inventory[Index] = 0 then
      continue;
    it := @itemlist[Index];
    if not assigned(it.use) then
      continue;
    if it.flags and IT_WEAPON = 0 then
      continue;

    it.use(ent,it);

    if cl.pers.weapon = it then
      Exit;  // succesfull
  end;
end;

{
=================
Cmd_WeapNext_f
=================
}
procedure Cmd_WeapNext_f (ent : edict_p);
var cl : gclient_p;
    i,Index : Integer;
    it : gitem_p;
    selected_weapon : Integer;
begin
  cl := ent.client;
  if not Assigned(cl.pers.weapon) then
    Exit;

  selected_weapon := ITEM_INDEX(cl.pers.weapon);

  //scan for the next valid one
  for i := 1 to MAX_ITEMS do
  begin
    Index := (selected_weapon + MAX_ITEMS - i) mod MAX_ITEMS;
    if cl.pers.inventory[Index] = 0 then
      continue;
    it := @itemlist[Index];
    if not assigned(it.use) then
      continue;
    if it.flags and IT_WEAPON = 0 then
      continue;

    it.use(ent,it);
    if cl.pers.weapon = it then
      Exit;  // succesfull
  end;
end;

{
=================
Cmd_WeapLast_f
=================
}
procedure Cmd_WeapLast_f(ent : edict_p);
var cl : gclient_p;
    Index : Integer;
    it : gitem_p;
begin
  cl := ent.client;
  if (not Assigned(cl.pers.weapon)) or (not Assigned(cl.pers.lastweapon)) then
    Exit;
  Index := ITEM_INDEX(cl.pers.lastweapon);
  if cl.pers.inventory[Index] = 0 then
    Exit;
  it := @itemlist[Index];
  if not Assigned(it.use) then
    Exit;
  if it.flags and IT_WEAPON = 0 then
    Exit;
  it.use(ent,it);
end;

{
=================
Cmd_InvDrop_f
=================
}
procedure Cmd_InvDrop_f (ent : edict_p);
var it : gitem_p;
begin
  ValidateSelectedItem(ent);
  if ent.client.pers.selected_item = -1 then
  begin
    gi.cprintf(ent, PRINT_HIGH, 'No item to drop.'+#10);
    Exit;
  end;
  it := @itemlist[ent.client.pers.selected_item];
  if not Assigned(it.drop) then
  begin
    gi.cprintf (ent, PRINT_HIGH, 'Item is not dropable.'+#10);
    Exit;
  end;
  it.drop(ent,it);
end;

{
=================
Cmd_Kill_f
=================
}
procedure Cmd_Kill_f(ent : edict_p);
begin
  if level.time - ent.client.respawn_time < 5 then
    Exit;
  ent.flags := ent.flags and not FL_GODMODE;
  ent.health := 0;
  meansOfDeath := MOD_SUICIDE;
  player_die(ent,ent,ent,100000,vec3_origin);
end;

{
=================
Cmd_PutAway_f
=================
}
procedure Cmd_PutAway_f(ent : edict_p);
begin
  ent.client.showscores := False;
  ent.client.showhelp := False;
  ent.client.showinventory := False;
end;


function PlayerSort (const a, b : Pointer) : integer;
var anum,bnum :Integer;
begin
  anum := PInteger(a)^;
  bnum := pinteger(b)^;
  anum := gclient_a(game.clients)[anum].ps.stats[STAT_FRAGS];
  bnum := gclient_a(game.clients)[bnum].ps.stats[STAT_FRAGS];
  if anum < bnum then
  begin
    Result := -1;
    Exit;
  end;
  if anum > bnum then
  begin
    Result := 1;
    Exit;
  end;
  Result := 0;
end;


{
=================
Cmd_Players_f
=================
}
procedure Cmd_Players_f(ent : edict_p);
var i : Integer;
    Count : Integer;
    small : array[0..64-1] of char;
    large : array[0..1280-1] of char;
    Index : array[0..256-1] of Integer;
begin
  Count := 0;
  for i := 0 to trunc(MaxClients.Value) - 1 do
  begin
    if gclient_a(game.clients)[i].pers.connected then
    begin
      Index[Count] := i;
      Inc(Count);
    end;
  end;
  //sort by frags
  qsort(@Index,Count,SizeOf(Index[0]),PlayerSort);
  // print information
  large[0] := #0;

  for i := 0 to Count - 1 do
  begin
    Com_sprintf(small, SizeOf(small),'%3i %s'+#10,
          [gclient_a(game.clients)[index[i]].ps.stats[STAT_FRAGS],
         gclient_a(game.clients)[index[i]].pers.netname]);
    if strlen(small) + strlen(large) > SizeOf(large) - 100 then
    begin // can't print all of them in one packet
      strcat(large,'...'+#10);
      break;
    end;
    strcat(large,small);
  end;
  gi.cprintf(ent,PRINT_HIGH,'%s'#10'%i players'+#10,large,Count);
end;


{
=================
Cmd_Wave_f
=================
}
procedure Cmd_Wave_f(ent : edict_p);
var i : Integer;
begin
  i := StrToInt(gi.argv(1));
  //can't wave when ducked
  if ent.client.ps.pmove.pm_flags and PMF_DUCKED <> 0 then
    Exit;
  if ent.client.anim_priority > ANIM_WAVE then
    Exit;

  ent.client.anim_priority := ANIM_WAVE;

  case i of
    0 :
    begin
      gi.cprintf(ent,PRINT_HIGH,'flipoff'+#10);
      ent.s.frame := FRAME_flip01-1;
      ent.client.anim_end := FRAME_flip12;
    end;
    1 :
    begin
      gi.cprintf(ent,PRINT_HIGH,'salute'+#10);
      ent.s.frame := FRAME_salute01-1;
      ent.client.anim_end := FRAME_salute11;
    end;
    2 :
    begin
      gi.cprintf(ent,PRINT_HIGH,'taunt'+#10);
      ent.s.frame := FRAME_taunt01-1;
      ent.client.anim_end := FRAME_taunt17;
    end;
    3 :
    begin
      gi.cprintf(ent,PRINT_HIGH,'wave'+#10);
      ent.s.frame := FRAME_wave01-1;
      ent.client.anim_end := FRAME_wave11;
    end;
    4 :
    begin
      gi.cprintf(ent,PRINT_HIGH,'point'+#10);
      ent.s.frame := FRAME_point01-1;
      ent.client.anim_end := FRAME_point12;
    end;
  end;
end;

{
==================
Cmd_Say_f
==================
}
procedure Cmd_Say_f(ent : edict_p;team : qboolean;arg0 : qboolean);
var i,j : Integer;
    other : edict_p;
    p     : PChar;
    Text  : array[0..2048-1] of char;
    cl    : gclient_p;
begin
  if (gi.argc < 2) and not(arg0) then
    Exit;
  if trunc(dmflags.Value) and (DF_MODELTEAMS or DF_SKINTEAMS) = 0 then
    team := False;
  if team then
    Com_sprintf(text, sizeof(text), '(%s): ', [ent.client.pers.netname])
  else
    Com_sprintf(text, sizeof(text), '%s: ', [ent.client.pers.netname]);
  if arg0 then
  begin
    strcat(Text, gi.argv(0));
    strcat(Text, ' ');
    strcat(Text,gi.args);
  end else
  begin
    p := gi.args();
    if p^ = '"' then
    begin
      Inc(p);
      p[strlen(p)-1] := #0;
    end;
    strcat(Text,p);
  end;
  // don't let text be too long for malicious reasons
  if strlen(text) > 150 then
    text[150] := #0;
  strcat(Text,''+#10);
  if flood_msgs.Value <> 0 then
  begin
    cl := ent.client;
    if level.time < cl.flood_locktill then
    begin
      gi.cprintf(ent, PRINT_HIGH, 'You can''t talk for %d more seconds'+#10,trunc((cl.flood_locktill - level.time)));
      Exit;
    end;
    i := trunc(cl.flood_whenhead - flood_msgs.Value + 1);
    if i < 0 then
      i := (SizeOf(cl.flood_when) div SizeOf(cl.flood_when[0])) + i;
    if (cl.flood_when[i] <> 0) and (level.time - cl.flood_when[i] < flood_persecond.Value) then
    begin
      cl.flood_locktill := level.time + flood_waitdelay.Value;
      gi.cprintf(ent, PRINT_CHAT, 'Flood protection:  You can''t talk for %d seconds.'+#10,trunc(flood_waitdelay.Value));
      Exit;
    end;
    cl.flood_whenhead := (cl.flood_whenhead + 1) mod trunc(sizeof(cl.flood_when)/sizeof(cl.flood_when[0]));
    cl.flood_when[cl.flood_whenhead] := level.time;
  end;

  if dedicated.Value <> 0 then
    gi.cprintf(nil, PRINT_CHAT, '%s', Text);

  for j := 1 to game.maxclients do
  begin
    other := @g_edicts[j];
    if not other.inuse then
      continue;
    if not Assigned(other.client) then
      continue;
    if team then
    begin
      if not OnSameTeam(ent,other) then
        continue;
    end;
    gi.cprintf(other, PRINT_CHAT, '%s', Text);
  end;
end;


procedure Cmd_PlayerList_f(ent : edict_p);
var i   : Integer;
    st  : array[0..80-1] of char;
    Text : array[0..1400-1] of char;
    e2   : edict_p;
    Spec : string; //delphi specific
begin
  // connect time, ping, score, name
  Text[0] := #0;
  e2 := @g_edicts[1];
  for i := 0 to trunc(maxclients.Value) - 1 do
  begin
    if not e2.inuse then
    begin
      Inc(e2);
      continue;
    end;
    if e2.client.resp.spectator then
      Spec := ' (spectator)'
    else
      Spec := '';
    Com_sprintf(st, sizeof(st), '%02d:%02d %4d %3d %s%s'+#10,
         [(level.framenum - e2.client.resp.enterframe) / 600,
         ((level.framenum - e2.client.resp.enterframe) mod 600)/10,
         e2.client.ping,
         e2.client.resp.score,
         e2.client.pers.netname,
         Spec]);
    if strlen(Text) + strlen(st) > SizeOf(Text) - 50 then
    begin
      // format? was sprintf
      Format(Text+strlen(Text), ['And more...\']);
      gi.cprintf(ent,PRINT_HIGH,'%s', Text);
      Exit;
    end;
    Inc(e2);
  end;
  gi.cprintf(ent, PRINT_HIGH, '%s', Text);
end;

{
=================
ClientCommand
=================
}
procedure ClientCommand(ent : edict_p);
var cmd : PChar;
begin
  if not Assigned(ent.client) then
    Exit;  // not fully in the game yet
  cmd := gi.argv(0);
  if q_stricmp(cmd,'players') = 0 then
  begin
    Cmd_Players_f(ent);
    Exit;
  end;
  if (Q_stricmp (cmd, 'say') = 0) then
  begin
    Cmd_Say_f (ent, false, false);
    exit;
  end;
  if (Q_stricmp (cmd, 'say_team') = 0) then
  begin
    Cmd_Say_f (ent, true, false);
    exit;
  end;
  if (Q_stricmp (cmd, 'score') = 0) then
  begin
    Cmd_Score_f(ent);
    exit;
  end;
  if (Q_stricmp (cmd, 'help') = 0) then
  begin
    Cmd_Help_f(ent);
    exit;
  end;

  if level.intermissiontime <> 0 then
    exit;

  if (Q_stricmp (cmd, 'use') = 0) then
    Cmd_Use_f (ent)
  else if (Q_stricmp (cmd, 'drop') = 0) then
     Cmd_Drop_f (ent)
  else if (Q_stricmp (cmd, 'give') = 0) then
    Cmd_Give_f (ent)
  else if (Q_stricmp (cmd, 'god') = 0) then
     Cmd_God_f (ent)
  else if (Q_stricmp (cmd, 'notarget') = 0) then
     Cmd_Notarget_f (ent)
  else if (Q_stricmp (cmd, 'noclip') = 0) then
    Cmd_Noclip_f (ent)
  else if (Q_stricmp (cmd, 'inven') = 0) then
    Cmd_Inven_f (ent)
  else if (Q_stricmp (cmd, 'invnext') = 0) then
    SelectNextItem (ent, -1)
  else if (Q_stricmp (cmd, 'invprev') = 0) then
    SelectPrevItem (ent, -1)
  else if (Q_stricmp (cmd, 'invnextw') = 0) then
    SelectNextItem (ent, IT_WEAPON)
  else if (Q_stricmp (cmd, 'invprevw') = 0) then
    SelectPrevItem (ent, IT_WEAPON)
  else if (Q_stricmp (cmd, 'invnextp') = 0) then
    SelectNextItem (ent, IT_POWERUP)
  else if (Q_stricmp (cmd, 'invprevp') = 0) then
    SelectPrevItem (ent, IT_POWERUP)
  else if (Q_stricmp (cmd, 'invuse') = 0) then
    Cmd_InvUse_f (ent)
  else if (Q_stricmp (cmd, 'invdrop') = 0) then
    Cmd_InvDrop_f (ent)
  else if (Q_stricmp (cmd, 'weapprev') = 0) then
    Cmd_WeapPrev_f (ent)
  else if (Q_stricmp (cmd, 'weapnext') = 0) then
    Cmd_WeapNext_f (ent)
  else if (Q_stricmp (cmd, 'weaplast') = 0) then
    Cmd_WeapLast_f (ent)
  else if (Q_stricmp (cmd, 'kill') = 0) then
    Cmd_Kill_f (ent)
  else if (Q_stricmp (cmd, 'putaway') = 0) then
    Cmd_PutAway_f (ent)
  else if (Q_stricmp (cmd, 'wave') = 0) then
    Cmd_Wave_f (ent)
  else if (Q_stricmp(cmd, 'playerlist') = 0) then
    Cmd_PlayerList_f(ent)
  else   // anything that doesn't match a command will be a chat
    Cmd_Say_f (ent, false, true);
end;

end.
