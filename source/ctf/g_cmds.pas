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


unit g_cmds;

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

{******************************************************************************
Initial Conversion Author   :    Scott Price
Initially Conversion Created:    01-July-2002
Language                    :    Object Pascal
Compiler Version            :    Delphi 3.02, 4.03, 5.01, 6.02 (UK)

VERSION  AUTHOR                DATE/TIME
===============================================================================
0.01     sprice                11-July-2002
         Initial conversion completed.  See notes and todo sections below.
===============================================================================
NOTES:
 - With the lack of my archive of emails being available I can not remember if
   the original C/C++ functions for things like String Length were being
   directly replace with the delphi equivalents, or left as-is and a Delphi
   named version being created for use.  As such I have left those lines as-is
   presently, awaiting what-ever decision is made.
===============================================================================
TODO:
 - replace/leave current 'strlen' type functions.
 - Add required units.
 - Complete the conversion.
******************************************************************************}



interface


{ TODO:  Add the Uses Clause }

// TODO:  #include "g_local.h"
// TODO:  #include "m_player.h"


function ClientTeam(ent: Pedict_t): PChar;
function OnSameTeam(ent1, ent2: Pedict_t): qboolean;
procedure SelectNextItem(ent: Pedict_t; itflags: Inetger);
procedure SelectPrevItem(ent: edict_t; itflags: Integer);
procedure ValidateSelectedItem(ent: Pedict_t);
procedure Cmd_Give_f(ent: Pedict_t);
procedure Cmd_God_f(ent: Pedict_t);
procedure Cmd_Notarget_f(ent: Pedict_t);
procedure Cmd_Noclip_f(ent: Pedict_t);
procedure Cmd_Use_f(ent: Pedict_t);
procedure Cmd_Drop_f(ent: Pedict_t);
procedure Cmd_Inven_f(ent: Pedict_t);
procedure Cmd_InvUse_f(ent: Pedict_t);
procedure Cmd_WeapPrev_f(ent: Pedict_t);
procedure Cmd_WeapNext_f(ent: Pedict_t);
procedure Cmd_WeapLast_f(ent: Pedict_t);
procedure Cmd_InvDrop_f(ent: Pedict_t);
procedure Cmd_Kill_f(ent: Pedict_t);
procedure Cmd_PutAway_f(ent: Pedict_t);
function PlayerSort(const a, b: Pointer): Integer;  { ???  Not sure about this one at all... }
procedure Cmd_Players_f(ent: Pedict_t);
procedure Cmd_Wave_f(ent: Pedict_t);
procedure Cmd_Say_f(ent: Pedict_t; team, arg0: qboolean);
procedure ClientCommand(ent: Pedict_t);



implementation



function ClientTeam(ent: Pedict_t): PChar;
{ TODO:  Open Compiler Options to Allow Assignable Constants in D6+ }
const
  value: array[0..512-1] of Char;
{ TODO:  Close Compiler Options to Allow Assignable Constants in D6+ }
var
  p: PChar;  { TODO:  Here do they mean Byte? }
begin
  Result := '';

  value[0] := 0;

  if (ent^.client = Nil) then
  begin
    Result := value{[0]}
    Exit;
  end;

  strcpy(value, Info_ValueForKey(ent^.client^.pers.userinfo, 'skin'));
  p := strchr(value, '/');
  if (p = Nil) then
  begin
    Result := value{[0]};
    Exit;
  end;

  if ((Integer(dmflags^.value) AND DF_MODELTEAMS) <> 0) then
  begin
    p^ := 0;
    Result := value{[0]};
  end;

  { NOTE:  The following line was already commented out }
  // if ((int)(dmflags->value) & DF_SKINTEAMS)

  { return ++p; }
  Inc(p);
  Result := p;
end;

function OnSameTeam(ent1, ent2: Pedict_t): qboolean;
var
  ent1Team: array[0..512-1] of Char;
  ent2Team: array[0..512-1] of Char;
begin
  if ((Integer(dmflags^.value) AND (DF_MODELTEAMS OR DF_SKINTEAMS)) = 0) then
  begin
    Result := False;
    Exit;
  end;

  strcpy(ent1Team, ClientTeam(ent1));
  strcpy(ent2Team, ClientTeam(ent2));

  if (strcmp(ent1Team, ent2Team) = 0) then
  begin
    Result := True;
    Exit;
  end;

  Result := False;
end;

procedure SelectNextItem(ent: Pedict_t; itflags: Inetger);
var
  cl: Pgclient_t;
  i, index: Integer;
  it: Pgitem_t;
begin
  cl := ent^.client;

  if (cl^.chase_target) then
  begin
    ChaseNext(ent);
    Exit;
  end;

  // scan  for the next valid one
  for i := 1 to (MAX_ITEMS - 1) do
  begin
    index := (cl^.pers.selected_item + i) mod MAX_ITEMS;
    if (cl^.pers.inventory[index] = 0) then
      Continue;

    it := @itemlist[index];
    if (it^.use = Nil) then
      Continue;

    if ((it^.flags AND itflags) = 0) then
      Continue;

    cl^.pers.selected_item := index;
    Exit;
  end;

  cl^.pers.selected_item := -1;
end;

procedure SelectPrevItem(ent: edict_t; itflags: Integer);
var
  cl: Pgclient_t;
  i, index: Integer;
  it: Pgitem_t;
begin
  cl := ent^.client;

  if (cl^.chase_target <> Nil) then
  begin
    ChasePrev(ent);
    Exit;
  end;

  // scan  for the next valid one
  for i := 1 to (MAX_ITEMS - 1) do
  begin
    index := (cl^.pers.selected_item + MAX_ITEMS - i) mod MAX_ITEMS;
    if (cl^.pers.inventory[index] = 0) then
      Continue;

    it := @itemlist[index];
    if (it^.use = Nil) then
      Continue;

    if ((it^.flags AND itflags) = 0) then
      Continue;

    cl^.pers.selected_item := index;
    Exit;
  end;

  cl^.pers.selected_item := -1;
end;

procedure ValidateSelectedItem(ent: Pedict_t);
var
  cl: Pgclient_t;
begin
  cl := ent^.client;

  if (cl^.pers.inventory[cl^.pers.selected_item] <> 0) then
    Exit;  // valid

  SelectNextItem(ent, -1);
end;

{ TODO:  A LOT of these procedures use the same string time and again, we should
         create a list of PChar Constants in this Implemenation that use these
         constants instead of the same thing time and time again. Easier to
         change then!  (Scott Price) } 

(* ==================
Cmd_Give_f

Give items to a client
================== *)
procedure Cmd_Give_f(ent: Pedict_t);
var
  name: PChar;
  it: Pgitem_t;
  index, i: Integer;
  give_all: qboolean;
  it_ent: Pedict_t;
  info: Pgitem_armor_t;
begin
  if (deathmatch^.value <> 0) AND (sv_cheats^.value = 0) then
  begin
    gi.cprintf(ent, PRINT_HIGH, 'You must run the server with ''+set cheats 1'' to enable this command.'#10);
    Exit;
  end;

  name := gi.args();

  if (Q_stricmp(name, 'all') = 0) then
    give_all := True
  else
    give_all := False;

  if give_all OR (Q_stricmp(gi.argv(1), 'health') = 0) then
  begin
    if (gi.argc() = 3) then
      ent^.health := atoi(gi.argv(2))
    else
      ent^.health := ent^.max_health;
    if (give_all = False) then
      Exit;
  end;

  if give_all OR (Q_stricmp(name, 'weapons') = 0) then
  begin
    for i := 0 to (game.num_items - 1) do
    begin
      it := itemlist + i;
      if (it^.pickup = 0) then
        Continue;

      if ((it^.flags AND IT_WEAPON) = 0)
        Continue;

      ent^.client^.pers.inventory[i] := ent^.client^.pers.inventory[i] + 1;
    end;
    if (give_all = False) then
      Exit;
  end;

  if give_all OR (Q_stricmp(name, 'ammo') = 0) then
  begin
    for i := 0 to (game.num_items - 1) do
    begin
      it := itemlist + i;
      if (it^.pickup = 0) then
        Continue;

      if ((it^.flags AND IT_AMMO) = 0) then
        Continue;
      Add_Ammo(ent, it, 1000);
    end;
    if (give_all = False) then
      Exit;
  end;

  if give_all OR (Q_stricmp(name, 'armor') = 0) then
  begin
    it := FindItem('Jacket Armor');
    ent^.client^.pers.inventory[ITEM_INDEX(it)] := 0;

    it := FindItem('Combat Armor');
    ent^.client^.pers.inventory[ITEM_INDEX(it)] := 0;

    it := FindItem('Body Armor');
    info := Pgitem_armor_t(it)^.info;
    ent^.client^.pers.inventory[ITEM_INDEX(it)] := info^.max_count;

    if (give_all = False) then
      Exit;
  end;

  if give_all OR (Q_stricmp(name, 'Power Shield') = 0) then
  begin
    it := FindItem('Power Shield');
    it_ent := G_Spawn();
    it_ent^.classname := it^.classname;
    SpawnItem(it_ent, it);
    Touch_Item(it_ent, ent, Nil, Nil);
    if (it_ent^.inuse) then
      G_FreeEdict(it_ent);

    if (give_all = False) then
      Exit;
  end;

  if give_all then
  begin
    for i := 0 to (game.num_items - 1) do
    begin
      it := itemlist + i;
      if (it^.pickup = 0) then
        Continue;

      if (it^.flags AND (IT_ARMOR OR IT_WEAPON OR IT_AMMO) <> 0) then
        Continue;
      ent^.client^.pers.inventory[i] := 1;
    end;

    Exit;
  end;

  it := FindItem(name);
  if (it = Nil) then
  begin
    name := gi.argv(1);
    it := FindItem(name);
    if (it = Nil) then
    begin
      gi.cprintf(ent, PRINT_HIGH, 'unknown item'#10);
      Exit;
    end;
  end;

  if (it^.pickup = Nil) then
  begin
    gi.cprintf(ent, PRINT_HIGH, 'non-pickup item'#10);
    Exit;
  end;

  index := ITEM_INDEX(it);

  if (it^.flags AND IT_AMMO) <> 0 then
  begin
    if (gi.argc() = 3) then
      ent^.client^.pers.inventory[index] := atoi(gi.argv(2))
    else
      ent^.client^.pers.inventory[index] := ent^.client^.pers.inventory[index] + it^.quantity;
  end
  else
  begin
    it_ent := G_Spawn();
    it_ent^.classname := it^.classname;
    SpawnItem(it_ent, it);
    Touch_Item(it_ent, ent, Nil, Nil);
    if (it_ent^.inuse) then
      G_FreeEdict(it_ent);
  end;
end;

(* ==================
Cmd_God_f

Sets client to godmode

argv(0) god
================== *)
procedure Cmd_God_f(ent: Pedict_t);
var
  msg: PChar;
begin
  if (deathmatch^.value AND (sv_cheats^.value = 0)) then
  begin
    gi.cprintf(ent, PRINT_HIGH, 'You must run the server with ''+set cheats 1'' to enable this command.'#10);
    Exit;
  end;

  ent^.flags := ent^.flags XOR FL_GODMODE;
  if ((ent^.flags AND FL_GODMODE) = 0) then
    msg := 'godmode OFF'#10
  else
    msg := 'godmode ON'#10;

  gi.cprintf(ent, PRINT_HIGH, msg);
end;

(* ==================
Cmd_Notarget_f

Sets client to notarget

argv(0) notarget
================== *)
procedure Cmd_Notarget_f(ent: Pedict_t);
var
  msg: PChar;
begin
  if (deathmatch^.value <> 0) AND (sv_cheats^.value = 0) then
  begin
    gi.cprintf(ent, PRINT_HIGH, 'You must run the server with ''+set cheats 1'' to enable this command.'#10);
    Exit;
  end;

  ent^.flags := ent^.flags XOR FL_NOTARGET;
  if ((ent^.flags AND FL_NOTARGET) = 0) then
    msg := 'notarget OFF'#10
  else
    msg := 'notarget ON'#10;

  gi.cprintf(ent, PRINT_HIGH, msg);
end;

(* ==================
Cmd_Noclip_f

argv(0) noclip
================== *)
procedure Cmd_Noclip_f(ent: Pedict_t);
var
  msg: PChar;
begin
  if (deathmatch^.value <> 0) AND (sv_cheats^.value = 0) then
  begin
    gi.cprintf(ent, PRINT_HIGH, 'You must run the server with ''+set cheats 1'' to enable this command.'#10);
    Exit;
  end;

  if (ent^.movetype = MOVETYPE_NOCLIP) then
  begin
    ent^.movetype := MOVETYPE_WALK;
    msg := 'noclip OFF'#10;
  end
  else
  begin
    ent^.movetype := MOVETYPE_NOCLIP;
    msg := 'noclip ON'#10;
  end;

  gi.cprintf(ent, PRINT_HIGH, msg);
end;

(* ==================
Cmd_Use_f

Use an inventory item
================== *)
procedure Cmd_Use_f(ent: Pedict_t);
var
  index: Integer;
  it: Pgitem_t;
  s: PChar;
begin
  s := gi.args();
  it := FindItem(s);
  if (it = Nil) then
  begin
    gi.cprintf(ent, PRINT_HIGH, 'unknown item: %s'#10, s);
    Exit;
  end;
  if (it^.use = 0) then
  begin
    gi.cprintf(ent, PRINT_HIGH, 'Item is not usable.'#10);
    Exit;
  end;
  index := ITEM_INDEX(it);
  if (ent^.client^.pers.inventory[index] = 0) then
  begin
    gi.cprintf(ent, PRINT_HIGH, 'Out of item: %s'#10, s);
    Exit;
  end;

  it^.use(ent, it);
end;

(* ==================
Cmd_Drop_f

Drop an inventory item
================== *)
procedure Cmd_Drop_f(ent: Pedict_t);
var
  index: Integer;
  it: Pgitem_t;
  s: PChar;
begin
  s := gi.args();
  it := FindItem(s);
  if (it = Nil) then
  begin
    gi.cprintf(ent, PRINT_HIGH, 'unknown item: %s'#10, s);
    Exit;
  end;
  if (it^.drop = 0) then
  begin
    gi.cprintf(ent, PRINT_HIGH, 'Item is not dropable.'#10);
    Exit;
  end;
  index := ITEM_INDEX(it);
  if (ent^.client^.pers.inventory[index] = 0) then
  begin
    gi.cprintf (ent, PRINT_HIGH, 'Out of item: %s'#10, s);
    Exit;
  end;

  it^.drop(ent, it);
end;

(* =================
Cmd_Inven_f
================= *)
procedure Cmd_Inven_f(ent: Pedict_t);
var
  i: Integer;
  cl: Pgclient_t;
begin
  cl := ent^.client;

  cl^.showscores := false;
  cl^.showhelp := false;

  if (cl^.showinventory = True) then
  begin
    cl^.showinventory := False;
    Exit;
  end;

  cl^.showinventory := True;

  gi.WriteByte(svc_inventory);
  for i := 0 to (MAX_ITEMS - 1) do
    gi.WriteShort(cl^.pers.inventory[i]);

  gi.unicast(ent, True);
end;

(* =================
Cmd_InvUse_f
================= *)
procedure Cmd_InvUse_f(ent: Pedict_t);
var
  it: Pgitem_t;
begin
  ValidateSelectedItem(ent);

  if (ent^.client^.pers.selected_item = -1) then
  begin
    gi.cprintf(ent, PRINT_HIGH, 'No item to use.'#10);
    Exit;
  end;

  it := @itemlist[ent^.client^.pers.selected_item];
  if (it^.use = 0) then
  begin
    gi.cprintf(ent, PRINT_HIGH, 'Item is not usable.'#10);
    Exit;
  end;
  it^.use(ent, it);
end;

(* =================
Cmd_WeapPrev_f
================= *)
procedure Cmd_WeapPrev_f(ent: Pedict_t);
var
  cl: gclient_t;
  i, index, selected_weapon: Integer;
  it: Pgitem_t;
begin
  cl := ent^.client;

  if (cl^.pers.weapon = 0) then
    Exit;

  selected_weapon := ITEM_INDEX(cl^.pers.weapon);

  // scan  for the next valid one
  for i := 1 to (MAX_ITEMS - 1) do
  begin
    index := (selected_weapon + i) mod MAX_ITEMS;
    if (cl^.pers.inventory[index] = Nil) then
      Continue;

    it := @itemlist[index];
    if (it^.use = 0)
      Continue;

    if ((it^.flags AND IT_WEAPON) = 0)
      Continue;

    it^.use(ent, it);
    if (cl^.pers.weapon = it) then
      Exit;   // successful
  end;
end;

(* =================
Cmd_WeapNext_f
================= *)
procedure Cmd_WeapNext_f(ent: Pedict_t);
var
  cl: Pgclient_t;
  i, index, selected_weapon: Integer;
  it: Pgitem_t;
begin
  cl := ent^.client;

  if (cl^.pers.weapon = 0) then
    Exit;

  selected_weapon := ITEM_INDEX(cl^.pers.weapon);

  // scan  for the next valid one
  for i := 1 to (MAX_ITEMS - 1) do
  begin
    index := (selected_weapon + MAX_ITEMS - i) mod MAX_ITEMS;
    if (cl^.pers.inventory[index] = 0) then
      Continue;

    it := @itemlist[index];
    if (it^.use = 0) then
      Continue;

    if ((it^.flags AND IT_WEAPON) = 0) then
      Continue;

    it^.use(ent, it);
    if (cl^.pers.weapon = it) then
      Exit;   // successful
  end;
end;

(* =================
Cmd_WeapLast_f
================= *)
procedure Cmd_WeapLast_f(ent: Pedict_t);
var
  cl: Pgclient_t;
  index: Integer;
  it: Pgitem_t;
begin
  cl := ent^.client;

  if (cl^.pers.weapon = 0) OR (cl^.pers.lastweapon = 0) then // ???:  Should these be Nil?
    Exit;

  index := ITEM_INDEX(cl^.pers.lastweapon);
  if (cl^.pers.inventory[index] = 0) then
    Exit;

  it := @itemlist[index];

  if (it^.use = 0) then
    Exit;
  if ((it^.flags AND IT_WEAPON) = 0) then
    Exit;

  it^.use(ent, it);
end;

(* =================
Cmd_InvDrop_f
================= *)
procedure Cmd_InvDrop_f(ent: Pedict_t);
var
  it: Pgitem_t;
begin
  ValidateSelectedItem(ent);

  if (ent^.client^.pers.selected_item = -1) then
  begin
    gi.cprintf(ent, PRINT_HIGH, 'No item to drop.'#10);
    Exit;
  end;

  it := @itemlist[ent^.client^.pers.selected_item];
  if (it^.drop = 0) then
  begin
    gi.cprintf(ent, PRINT_HIGH, 'Item is not dropable.'#10);
    Exit;
  end;
  it^.drop(ent, it);
end;

(* =================
Cmd_Kill_f
================= *)
procedure Cmd_Kill_f(ent: Pedict_t);
begin
  if ((level.time - ent^.client^.respawn_time) < 5) then
    Exit;

  ent^.flags := ent^.flags AND (NOT FL_GODMODE);
  ent^.health := 0;
  meansOfDeath := MOD_SUICIDE;
  player_die(ent, ent, ent, 100000, vec3_origin);
end;

(* =================
Cmd_PutAway_f
================= *)
procedure Cmd_PutAway_f(ent: Pedict_t);
begin
  ent^.client^.showscores := False;
  ent^.client^.showhelp := False;
  ent^.client^.showinventory := False;
end;

{ TODO: Convert  -  int PlayerSort (void const *a, void const *b) }
function PlayerSort(const a, b: Pointer): Integer;  { ???  Not sure about this one at all... }
var
  anum, bnum: Integer;
begin
  anum := PInteger(a)^;
  bnum = PInteger(b)^;

  anum := game.clients[anum].ps.stats[STAT_FRAGS];
  bnum := game.clients[bnum].ps.stats[STAT_FRAGS];

  if (anum < bnum) then
  begin
    Result := -1;
    Exit;
  end;
  if (anum > bnum) then
  begin
    Result := 1;
    Exit;
  end;
  Result := 0;
end;

(* =================
Cmd_Players_f
================= *)
procedure Cmd_Players_f(ent: Pedict_t);
var
  i, count: Integer;
  small: array[0..64-1] of char;
  large: array[0..1280-1] of char;
  index: array[0..256-1] of Integer;
begin
  count := 0;
  for i := 0 to (maxclients^.value - 1) do
    if (game.clients[i].pers.connected <> 0) then
    begin
      index[count] := i;
      Inc(count);
    end;

  // sort by frags
  qsort(index, count, SizeOf(index[0]), PlayerSort);

  // print information
  large[0] := 0;

  for i := 0 to (count - 1) do
  begin
    Com_sprintf(small, sizeof(small), '%3i %s'#10,  { TODO:  What does '%3i' translate to? }
            game.clients[index[i]].ps.stats[STAT_FRAGS],
            game.clients[index[i]].pers.netname);
    if (strlen(small) + strlen(large)) > (sizeof(large) - 100) then
    begin
      // can't print all of them in one packet
      strcat (large, '...'#10);
      Break;
    end;
    strcat(large, small);
  end;

  gi.cprintf(ent, PRINT_HIGH, PChar('%s'#10 + '%i players'#10), large, count);
end;

(* =================
Cmd_Wave_f
================= *)
procedure Cmd_Wave_f(ent: Pedict_t);
var
  i: Integer;
begin
  i := atoi(gi.argv(1));

  // can't wave when ducked
  if (ent^.client^.ps.pmove.pm_flags AND PMF_DUCKED) <> 0 then
    Exit;

  if (ent^.client^.anim_priority > ANIM_WAVE) then
    Exit;

  ent^.client^.anim_priority := ANIM_WAVE;

  case i of
    0:  begin
      gi.cprintf(ent, PRINT_HIGH, 'flipoff'#10);
      ent^.s.frame := FRAME_flip01 - 1;
      ent^.client^.anim_end := FRAME_flip12;
      //Break;
    end;
    1:  begin
      gi.cprintf(ent, PRINT_HIGH, 'salute'#10);
      ent^.s.frame := FRAME_salute01 - 1;
      ent^.client^.anim_end := FRAME_salute11;
      //Break;
    end;
    2:  begin
      gi.cprintf(ent, PRINT_HIGH, 'taunt'#10);
      ent^.s.frame := FRAME_taunt01 - 1;
      ent^.client^.anim_end := FRAME_taunt17;
      //Break;
    end;
    3:  begin
      gi.cprintf(ent, PRINT_HIGH, 'wave'#10);
      ent^.s.frame := FRAME_wave01 - 1;
      ent^.client^.anim_end := FRAME_wave11;
      //Break;
    end;
  else
    gi.cprintf(ent, PRINT_HIGH, 'point'#10);
    ent^.s.frame := FRAME_point01-1;
    ent^.client^.anim_end := FRAME_point12;
    //Break;
  end;
end;

(* ==================
Cmd_Say_f
================== *)
procedure Cmd_Say_f(ent: Pedict_t; team, arg0: qboolean);
var
  i, j: Integer;
  other: Pedict_t;
  p: PChar;
  text: array[0..2048-1] of Char;
  cl: Pgclient_t;
begin
  if (gi.argc < 2) AND (NOT arg0) then
    Exit;

  if ((integer(dmflags^.value) AND (DF_MODELTEAMS OR DF_SKINTEAMS)) = 0) then
    team := False;

  if team then
    Com_sprintf(text, sizeof(text), '(%s): ', ent^.client^.pers.netname)
  else
    Com_sprintf(text, sizeof(text), '%s: ', ent^.client^.pers.netname);

  if (arg0) then
  begin
    strcat(text, gi.argv(0));
    strcat(text, ' ');
    strcat(text, gi.args());
  end
  else
  begin
    p := gi.args();

    if (p^ = '"') then
    begin
      Inc(p);
      p[strlen(p)-1] := 0;
    end;
    strcat(text, p);
  end;

  // don't let text be too long for malicious reasons
  if (strlen(text) > 150) then
    text[150] := 0;

  strcat(text, '\n');

  if (flood_msgs^.value) then
  begin
    cl := ent^.client;

    if (level.time < cl^.flood_locktill) then
    begin
        gi.cprintf(ent, PRINT_HIGH, 'You can''t talk for %d more seconds'#10,
          Integer(cl^.flood_locktill - level.time));
        Exit;
    end;
    i := cl^.flood_whenhead - flood_msgs^.value + 1;
    if (i < 0) then
        i := (SizeOf(cl^.flood_when) div SizeOf(cl^.flood_when[0])) + i;

    if (cl^.flood_when[i] <> 0) AND
    (level.time - cl^.flood_when[i] < flood_persecond^.value) then
    begin
      cl^.flood_locktill := level.time + flood_waitdelay^.value;
      gi.cprintf(ent, PRINT_CHAT, 'Flood protection:  You can''t talk for %d seconds.'#10,
        Integer(flood_waitdelay^.value));
      Exit;
    end;
    cl^.flood_whenhead := (cl^.flood_whenhead + 1) mod
            (SizeOf(cl^.flood_when) div sizeof(cl^.flood_when[0]));
    cl^.flood_when[cl^.flood_whenhead] := level.time;
  end;

  if (dedicated^.value <> 0) then
    gi.cprintf(Nil, PRINT_CHAT, '%s', text);

  for j := 1 to game.maxclients do
  begin
    other := @g_edicts[j];
    if (other^.inuse = 0) then
      Continue;
    if (other^.client = Nil)
      Continue;
    if (team) then
    begin
      if (NOT OnSameTeam(ent, other)) then
        Continue;
    end;
    gi.cprintf(other, PRINT_CHAT, '%s', text);
  end;
end;

procedure Cmd_PlayerList_f(ent: Pedict_t);
{ TODO:  Check this conversion! }
var
  i: Integer;
  st: array[0..80-1] of Char;
  text: array[0..1400-1] of Char;
  e2: Pedict_t;
  pcSpectator: PChar;
begin
  { TODO:  Check this conversion! }
  // connect time, ping, score, name
  { TODO:  Don't think this line will compile in Delphi }
  text^ := 0;

  { TODO:  Don't think this line will compile in Delphi }
  e2 := g_edicts + 1;  { Try converting to:  Pedict_t(Integer(@g_edicts) + 1) }
  for i := 0 to (maxclients^.value - 1) do begin
    TRY
      if (e2^.inuse = 0) then
        Continue;

      { This is an addition to resolve the following line:
          e2^.client^.resp.spectator ? ' (spectator)' : '');
      }
      if e2^.client^.resp.spectator <> 0 then
        pcSpectator := ' (spectator)'
      else
        pcSpectator := '';

      Com_sprintf(st, SizeOf(st), '%02d:%02d %4d %3d %s%s'#10,
              (level.framenum - e2^.client^.resp.enterframe) / 600,
              ((level.framenum - e2^.client^.resp.enterframe) mod 600) / 10,
              e2^.client^.ping,
              e2^.client^.resp.score,
              e2^.client^.pers.netname,
              { TODO:  Convert the following Line >>>> }
              //e2^.client^.resp.spectator ? ' (spectator)' : '');
              pcSpectator);

      if (strlen(text) + strlen(st)) > (sizeof(text) - 50) then
      begin
        sprintf(text + strlen(text), 'And more...'#10);
        gi.cprintf(ent, PRINT_HIGH, '%s', text);
        Exit;
      end;
      strcat(text, st);
    FINALLY
      Inc(e2);
    END;
  end;

  gi.cprintf(ent, PRINT_HIGH, '%s', text);
end;

(* =================
ClientCommand
================= *)
procedure ClientCommand(ent: Pedict_t);
var
  cmd: PChar;
begin
  if (ent^.client = Nil) then
    Exit;      // not fully in game yet

  cmd := gi.argv(0);  { TODO:  Replace with??:  ParamStr(0) or Application.ExeName }

  if (Q_stricmp(cmd, 'players') = 0) then
  begin
    Cmd_Players_f(ent);
    Exit;
  end;
  if (Q_stricmp(cmd, 'say') = 0) then
  begin
    Cmd_Say_f(ent, False, False);
    Exit;
  end;
  if (Q_stricmp(cmd, 'say_team') = 0) then
  begin
    Cmd_Say_f(ent, True, False);
    Exit;
  end;
  if (Q_stricmp(cmd, 'score') = 0) then
  begin
    Cmd_Score_f(ent);
    Exit;
  end;
  if (Q_stricmp(cmd, 'help') = 0) then
  begin
    Cmd_Help_f(ent);
    Exit;
  end;

  if (level.intermissiontime <> 0) then
    Exit;

  if (Q_stricmp(cmd, 'use') = 0) then
    Cmd_Use_f(ent)
  else if (Q_stricmp(cmd, 'drop') = 0) then
    Cmd_Drop_f(ent)
  else if (Q_stricmp(cmd, 'give') = 0) then
    Cmd_Give_f(ent)
  else if (Q_stricmp(cmd, 'god') = 0) then
    Cmd_God_f(ent)
  else if (Q_stricmp(cmd, 'notarget') = 0) then
    Cmd_Notarget_f(ent)
  else if (Q_stricmp(cmd, 'noclip') = 0) then
    Cmd_Noclip_f(ent)
  else if (Q_stricmp(cmd, 'inven') = 0) then
    Cmd_Inven_f(ent)
  else if (Q_stricmp(cmd, 'invnext') = 0) then
    SelectNextItem(ent, -1)
  else if (Q_stricmp(cmd, 'invprev') = 0) then
    SelectPrevItem(ent, -1)
  else if (Q_stricmp(cmd, 'invnextw') = 0) then
    SelectNextItem(ent, IT_WEAPON)
  else if (Q_stricmp(cmd, 'invprevw') = 0) then
    SelectPrevItem(ent, IT_WEAPON)
  else if (Q_stricmp(cmd, 'invnextp') = 0) then
    SelectNextItem(ent, IT_POWERUP)
  else if (Q_stricmp(cmd, 'invprevp') = 0) then
    SelectPrevItem(ent, IT_POWERUP)
  else if (Q_stricmp(cmd, 'invuse') = 0) then
    Cmd_InvUse_f(ent)
  else if (Q_stricmp(cmd, 'invdrop') = 0) then
    Cmd_InvDrop_f(ent)
  else if (Q_stricmp(cmd, 'weapprev') = 0) then
    Cmd_WeapPrev_f(ent)
  else if (Q_stricmp(cmd, 'weapnext') = 0) then
    Cmd_WeapNext_f(ent)
  else if (Q_stricmp(cmd, 'weaplast') = 0) then
    Cmd_WeapLast_f(ent)
  else if (Q_stricmp(cmd, 'kill') = 0) then
    Cmd_Kill_f(ent)
  else if (Q_stricmp(cmd, 'putaway') = 0) then
    Cmd_PutAway_f(ent)
  else if (Q_stricmp(cmd, 'wave') = 0) then
    Cmd_Wave_f(ent)
  else if (Q_stricmp(cmd, 'playerlist') = 0) then
    Cmd_PlayerList_f(ent)
  else
    // anything that doesn't match a command will be a chat
    Cmd_Say_f(ent, False, True);
end;

end.
