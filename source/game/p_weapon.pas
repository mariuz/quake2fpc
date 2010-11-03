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
{ File(s): p_weapon.c                                                        }
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
{ Updated on :  2003-03-24                                                   }
{ Updated by :  Scott Price                                                  }
{                                                                            }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{ x)                                                                         }
{----------------------------------------------------------------------------}
{ NOTES:                                                                     }
{ 1)  Whilst mostly complete, there are certain elements of this which       }
{     relate to the CTF define that have NOT been tidied or checked.  ONLY   }
{     items relating to game have been checked/reviewed.                     }
{                                                                            }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{ 1) Do more tests                                                           }
{ 2) <SP>  Tried to make sections more like the original C code.             }
{    Optomisations can occur later to the code.                              }
{                                                                            }
{----------------------------------------------------------------------------}

// p_weapon.c

unit p_weapon;

interface

uses
  q_shared,
  q_shared_add,
  GameUnit,
  g_local,
  g_local_add;

{$IFDEF CTF}
procedure P_ProjectSource (client : gclient_p; var point, distance, forward_, right, result : vec3_t); //only for CTF\g_ctf.c
{$ENDIF}
procedure PlayerNoise (who : edict_p; const where : vec3_t; type_ : integer); //a few files
function Pickup_Weapon (ent, other : edict_p) : qboolean; cdecl; //for g_items
procedure ChangeWeapon (ent : edict_p); //for p_client
procedure Think_Weapon (ent : edict_p); //for p_client
procedure Use_Weapon (ent : edict_p; item : gitem_p); cdecl; //for g_items
procedure Drop_Weapon (ent : edict_p; item : gitem_p); cdecl; //for g_items

procedure Weapon_Blaster (ent: edict_p); cdecl;
procedure Weapon_Shotgun (ent: edict_p); cdecl;
procedure Weapon_SuperShotgun (ent: edict_p); cdecl;
procedure Weapon_Machinegun (ent: edict_p); cdecl;
procedure Weapon_Chaingun (ent: edict_p); cdecl;
procedure Weapon_GrenadeLauncher (ent: edict_p); cdecl;
procedure Weapon_RocketLauncher (ent: edict_p); cdecl;
procedure Weapon_Hyperblaster (ent: edict_p); cdecl;
procedure Weapon_Railgun (ent: edict_p); cdecl;
procedure Weapon_BFG(ent: edict_p); cdecl;
procedure Weapon_Grenade (ent: edict_p); cdecl;


implementation

uses g_weapon,
    g_utils,
   g_items,
   m_player,
   g_main,
   CPas;


var
  is_quad : qboolean;
  is_silenced : byte;


procedure weapon_grenade_fire (ent : edict_p; held : qboolean); cdecl; forward;


{ (GAME <> CTF):
  GAME: static void P_ProjectSource
  CTF:  void P_ProjectSource }
//only for CTF\g_ctf.c
procedure P_ProjectSource (client : gclient_p; var point, distance, forward_, right, result : vec3_t);
var
  _distance : vec3_t;
begin
  VectorCopy (distance, _distance);
  if (client^.pers.hand = LEFT_HANDED) then
    _distance[1] := _distance[1] * -1
  else if (client^.pers.hand = CENTER_HANDED) then
    _distance[1] := 0;

  G_ProjectSource (point, _distance, forward_, right, result);
end;

{*
===============
PlayerNoise

Each player can have two noise objects associated with it:
a personal noise (jumping, pain, weapon firing), and a weapon
target noise (bullet wall impacts)

Monsters that don't directly see the player can move
to a noise in hopes of seeing the player from there.
===============
*}
// (GAME=CTF)
procedure PlayerNoise (who : edict_p; const where : vec3_t; type_ : integer); //a few files
var
  noise : edict_p;
begin
  if (type_ = PNOISE_WEAPON) then
    if (who^.client^.silencer_shots <> 0) then
      begin
        Dec(who^.client^.silencer_shots);
        Exit;
      end;

  if (deathmatch^.value <> 0) then
    Exit;

  if (who^.flags AND FL_NOTARGET) <> 0 then
    Exit;

  if (who^.mynoise = Nil) then
  begin
    noise := G_Spawn();
    noise^.classname := 'player_noise';
    VectorSet (noise^.mins, -8, -8, -8);
    VectorSet (noise^.maxs, 8, 8, 8);
    noise^.owner := who;
    noise^.svflags := SVF_NOCLIENT;
    who^.mynoise := noise;

    noise := G_Spawn();  // by FAB
    noise^.classname := 'player_noise';
    VectorSet (noise^.mins, -8, -8, -8);
    VectorSet (noise^.maxs, 8, 8, 8);
    noise^.owner := who;
    noise^.svflags := SVF_NOCLIENT;
    who^.mynoise2 := noise;
  end;

  if (type_ = PNOISE_SELF) OR (type_ = PNOISE_WEAPON) then
  begin
    noise := who^.mynoise;
    level.sound_entity := noise;
    level.sound_entity_framenum := level.framenum;
  end
  else // type == PNOISE_IMPACT
  begin
    noise := who^.mynoise2;
    level.sound2_entity := noise;
    level.sound2_entity_framenum := level.framenum;
  end;

  VectorCopy (where, noise^.s.origin);
  VectorSubtract (where, noise^.maxs, noise^.absmin);
  VectorAdd (where, noise^.maxs, noise^.absmax);
  noise^.teleport_time := level.time;
  gi.linkentity (noise);
end;

// (GAME=CTF)
function Pickup_Weapon (ent, other : edict_p) : qboolean; //for g_items
var
  index : integer;
  ammo  : gitem_p;
begin
  index := ITEM_INDEX(ent^.item); // by FAB

  if ( ( ((Trunc(dmflags^.value) AND DF_WEAPONS_STAY) <> 0) OR (coop^.value <> 0) ) AND
       (other^.client^.pers.inventory[index] <> 0) ) then
    if (ent^.spawnflags AND (DROPPED_ITEM OR DROPPED_PLAYER_ITEM) = 0) then
    begin
      Result := false;   // leave the weapon for others to pickup
      Exit;
    end;

  Inc(other^.client^.pers.inventory[index]);

  if ((ent^.spawnflags AND DROPPED_ITEM) = 0) then
  begin
    // give them some ammo with it
    ammo := FindItem (ent^.item^.ammo); // by FAB
   
    if ((Trunc(dmflags^.value ) AND DF_INFINITE_AMMO) <> 0) then
      Add_Ammo (other, ammo, 1000)
    else
      Add_Ammo (other, ammo, ammo^.quantity);

    if ((ent^.spawnflags AND DROPPED_PLAYER_ITEM) = 0) then
    begin
      if (deathmatch^.value <> 0) then
      begin
        if ((Trunc(dmflags^.value) AND DF_WEAPONS_STAY) <> 0) then
          ent^.flags := ent^.flags OR FL_RESPAWN
        else
          SetRespawn (ent, 30); // by FAB
      end;

      if (coop^.value <> 0) then
        ent^.flags := ent^.flags OR FL_RESPAWN;
    end;
  end;

  { 2003-03-14-SP:  The Deathmatch and next boolean result were supposed to have
                    an additional set of brackets around them.  Added. }
  if (other^.client^.pers.weapon <> ent^.item) AND (other^.client^.pers.inventory[index] = 1)
  AND ((deathmatch^.value = 0) OR (other^.client^.pers.weapon = FindItem('blaster')) ) then
    other^.client^.newweapon := ent^.item;

  Result := true;
end;


{*
===============
ChangeWeapon

The old weapon has been dropped all the way, so make the new one
current
===============
*}
// (GAME=CTF)
procedure ChangeWeapon (ent : edict_p);
var
  i : integer;
begin
  if (ent^.client^.grenade_time <> 0) then
  begin
    ent^.client^.grenade_time := level.time;
    ent^.client^.weapon_sound := 0;
    weapon_grenade_fire (ent, false);
    ent^.client^.grenade_time := 0;
  end;

  ent^.client^.pers.lastweapon  := ent^.client^.pers.weapon;
  ent^.client^.pers.weapon := ent^.client^.newweapon;
  ent^.client^.newweapon := Nil;
  ent^.client^.machinegun_shots := 0;

  // set visible model
  if (ent^.s.modelindex = 255) then
  begin
    if (ent^.client^.pers.weapon <> Nil) then
      i := ((ent^.client^.pers.weapon^.weapmodel AND $FF) SHL 8)
    else
      i := 0;

    ent^.s.skinnum := (Cardinal(ent) - Cardinal(g_edicts) - 1 * SizeOf(edict_t)) OR i;
  end;

  if (ent^.client^.pers.weapon <> Nil) AND (ent^.client^.pers.weapon^.ammo <> '') then
    ent^.client^.ammo_index := ITEM_INDEX(FindItem(ent^.client^.pers.weapon^.ammo))
  else
    ent^.client^.ammo_index := 0;

  if (ent^.client^.pers.weapon = Nil) then
  begin
    // dead
    ent^.client^.ps.gunindex := 0;
    Exit;
  end;

  ent^.client^.weaponstate := WEAPON_ACTIVATING;
  ent^.client^.ps.gunframe := 0;
  ent^.client^.ps.gunindex := gi.modelindex(ent^.client^.pers.weapon^.view_model);

  ent^.client^.anim_priority := ANIM_PAIN;
  if (ent^.client^.ps.pmove.pm_flags AND PMF_DUCKED) <> 0 then
  begin
    ent^.s.frame := FRAME_crpain1;       // by FAB
    ent^.client^.anim_end := FRAME_crpain4;  // by FAB
  end
  else begin
    ent^.s.frame := FRAME_pain301;  // by FAB
    ent^.client^.anim_end := FRAME_pain304; // by FAB
  end;
end;

{*
=================
NoAmmoWeaponChange
=================
*}
// (GAME=CTF)
procedure NoAmmoWeaponChange (ent : edict_p); //???only imp
begin
  if (ent^.client^.pers.inventory[ITEM_INDEX(FindItem('slugs'))] AND
  ent^.client^.pers.inventory[ITEM_INDEX(FindItem('railgun'))]) <> 0 then  // check this ..by FAB
  begin
    ent^.client^.newweapon := FindItem ('railgun');
    Exit;
  end;

  if (ent^.client^.pers.inventory[ITEM_INDEX(FindItem('cells'))] AND
  ent^.client^.pers.inventory[ITEM_INDEX(FindItem('hyperblaster'))]) <> 0 then  // check this ..by FAB
  begin
    ent^.client^.newweapon := FindItem ('hyperblaster');
    Exit;
  end;

  if (ent^.client^.pers.inventory[ITEM_INDEX(FindItem('bullets'))] AND
  ent^.client^.pers.inventory[ITEM_INDEX(FindItem('chaingun'))]) <> 0 then   // check this ..by FAB
  begin
    ent^.client^.newweapon := FindItem ('chaingun');
    Exit;
  end;

  if (ent^.client^.pers.inventory[ITEM_INDEX(FindItem('bullets'))] AND
  ent^.client^.pers.inventory[ITEM_INDEX(FindItem('machinegun'))]) <> 0 then  // check this ..by FAB
  begin
    ent^.client^.newweapon := FindItem ('machinegun');
    Exit;
  end;

  if (ent^.client^.pers.inventory[ITEM_INDEX(FindItem('shells'))] AND
  ent^.client^.pers.inventory[ITEM_INDEX(FindItem('super shotgun'))]) <> 0 then  // check this ..by FAB
  begin
    ent^.client^.newweapon := FindItem ('super shotgun');
    Exit;
  end;

  if (ent^.client^.pers.inventory[ITEM_INDEX(FindItem('shells'))] AND
  ent^.client^.pers.inventory[ITEM_INDEX(FindItem('shotgun'))]) <> 0 then     // check this ..by FAB
  begin
    ent^.client^.newweapon := FindItem ('shotgun');
    Exit;
  end;

  ent^.client^.newweapon := FindItem ('blaster');
end;

{*
=================
Think_Weapon

Called by ClientBeginServerFrame and ClientThink
=================
*}
// (GAME=CTF)
procedure Think_Weapon (ent : edict_p);
begin
  // if just died, put the weapon away
  if (ent^.health < 1) then
  begin
    ent^.client^.newweapon := Nil;
    ChangeWeapon (ent);
  end;

  // call active weapon think routine
  if (ent^.client^.pers.weapon <> Nil) AND Assigned(ent^.client^.pers.weapon^.weaponthink) then
  begin
    is_quad := (ent^.client^.quad_framenum > level.framenum);
    if (ent^.client^.silencer_shots <> 0) then
      is_silenced := MZ_SILENCED
    else
      is_silenced := 0;
    ent^.client^.pers.weapon^.weaponthink (ent);
  end;
end;


{*
================
Use_Weapon

Make the weapon ready if there is ammo
================
*}
// (GAME=CTF)
procedure Use_Weapon (ent : edict_p; item : gitem_p);
var
  ammo_index : integer;
  ammo_item  : gitem_p;
begin
  // see if we're already using it
  if (item = ent^.client^.pers.weapon) then
    Exit;

  if ( (item^.ammo <> nil) AND (g_select_empty^.Value = 0) AND ((item^.flags AND IT_AMMO) = 0) ) then
  begin
    ammo_item  := FindItem(item^.ammo);
    ammo_index := ITEM_INDEX(ammo_item);

    if (ent^.client^.pers.inventory[ammo_index]) = 0 then
    begin
      gi.cprintf (ent, PRINT_HIGH, 'No %s for %s.'#10 , ammo_item^.pickup_name, item^.pickup_name  );
      Exit;
    end;

    if (ent^.client^.pers.inventory[ammo_index] < item^.quantity) then
    begin
      gi.cprintf (ent, PRINT_HIGH, 'Not enough %s for %s.'#10 , ammo_item^.pickup_name, item^.pickup_name );
      Exit;
    end;
  end;

  // change to this weapon when down
  ent^.client^.newweapon := item;
end;


{*
================
Drop_Weapon
================
*}
// (GAME=CTF)
procedure Drop_Weapon (ent : edict_p; item : gitem_p);
var
  index : integer;
begin
  if ((Trunc(dmflags^.value) AND DF_WEAPONS_STAY) <> 0) then
    Exit;

  index := ITEM_INDEX(item); 
  // see if we're already using it
  if ( ((item = ent^.client^.pers.weapon) OR (item = ent^.client^.newweapon)) AND
       (ent^.client^.pers.inventory[index] = 1) ) then
  begin
    gi.cprintf (ent, PRINT_HIGH, 'Can''t drop current weapon'#10);
    Exit;
  end;

  Drop_Item (ent, item);
  Dec(ent^.client^.pers.inventory[index]);
end;


{*
================
Weapon_Generic

A generic function to handle the basics of weapon thinking
================
*}
//const
//  FRAME_FIRE_FIRST    = (FRAME_ACTIVATE_LAST + 1);
//  FRAME_IDLE_FIRST    = (FRAME_FIRE_LAST + 1);
//  FRAME_DEACTIVATE_FIRST = (FRAME_IDLE_LAST + 1);

// (GAME <> CTF)
{$IFDEF CTF}
{procedure static void Weapon_Generic2 (edict_t *ent,
                                       int FRAME_ACTIVATE_LAST, int FRAME_FIRE_LAST, int FRAME_IDLE_LAST, int FRAME_DEACTIVATE_LAST,
                                       int *pause_frames, int *fire_frames, void ( *fire)(edict_t *ent));}
procedure Weapon_Generic2 (ent : edict_p;
                           FRAME_ACTIVATE_LAST, FRAME_FIRE_LAST, FRAME_IDLE_LAST, FRAME_DEACTIVATE_LAST : integer;
                           pause_frames, fire_frames : array of integer{;, void ( *fire)(edict_t *ent)});
var
  n : integer;
begin
  if (ent.deadflag <> 0) OR (ent.s.modelindex <> 255) then // VWep animations screw up corpses
    Exit;

  if (ent.client.weaponstate = WEAPON_DROPPING) then
  begin
    if (ent.client.ps.gunframe = FRAME_DEACTIVATE_LAST)
    then begin
      ChangeWeapon (ent);
      Exit;
    end
    else begin
      if ((FRAME_DEACTIVATE_LAST - ent.client.ps.gunframe) = 4) then
      begin
        ent.client.anim_priority := ANIM_REVERSE;
        if ((ent.client.ps.pmove.pm_flags AND PMF_DUCKED) <> 0)
        then begin
          ent.s.frame := FRAME_crpain4+1; // by FAB
          ent.client.anim_end := FRAME_crpain1;  // by FAB
        end
        else begin
          ent.s.frame := FRAME_pain304+1;     // by FAB
          ent.client.anim_end := FRAME_pain301;  // by FAB
        end;
      end;
    end;//else

    Inc(ent.client.ps.gunframe);
    Exit;
  end;

  if (ent.client.weaponstate = WEAPON_ACTIVATING) then
  begin
    if (ent.client.ps.gunframe = FRAME_ACTIVATE_LAST) OR (instantweap.value <> 0) then  // by FAB
    begin
      ent.client.weaponstate := WEAPON_READY;
      ent.client.ps.gunframe := FRAME_IDLE_FIRST;  // by FAB
      // we go recursive here to instant ready the weapon
      Weapon_Generic2 (ent, FRAME_ACTIVATE_LAST, FRAME_FIRE_LAST,
                       FRAME_IDLE_LAST, FRAME_DEACTIVATE_LAST, pause_frames,
                       fire_frames{, fire});
      Exit;
    end;

    Inc(ent.client.ps.gunframe);
    Exit;
  end;

//  if ((ent->client->newweapon) && (ent->client->weaponstate != WEAPON_FIRING)) then
  if (ent.client.newweapon <> Nil) AND (ent.client.weaponstate <> WEAPON_FIRING) then
  begin
    ent.client.weaponstate := WEAPON_DROPPING;
    if (instantweap.value <> 0) // by FAB
    then begin
      ChangeWeapon(ent);
      Exit;
    end
    else
      ent.client.ps.gunframe := FRAME_DEACTIVATE_FIRST ; //by FAB

    if ((FRAME_DEACTIVATE_LAST - FRAME_DEACTIVATE_FIRST) < 4) then //by FAB
    begin
      ent.client.anim_priority := ANIM_REVERSE;
      if ((ent.client.ps.pmove.pm_flags AND PMF_DUCKED) <> 0)
      then begin
        ent.s.frame := FRAME_crpain4+1;  // by FAB
        ent.client.anim_end := FRAME_crpain1; // by FAB
      end
      else begin
        ent.s.frame := FRAME_pain304+1;    // by FAB
        ent.client.anim_end := FRAME_pain301; //by FAB
      end;
    end;
    Exit;
  end;

  if (ent.client.weaponstate = WEAPON_READY) then
  begin
//    if ( ((ent.client.latched_buttons|ent.client.buttons) & BUTTON_ATTACK) )
    if ( ((ent.client.latched_buttons OR ent.client.buttons) AND BUTTON_ATTACK) <> 0 )
    then begin
      ent.client.latched_buttons := ent.client.latched_buttons AND (NOT BUTTON_ATTACK);
      if ( (ent.client.ammo_index=0) OR
           (ent.client.pers.inventory[ent.client.ammo_index] >= ent.client.pers.weapon.quantity) )
      then begin
        ent.client.ps.gunframe := FRAME_FIRE_FIRST; // by FAB
        ent.client.weaponstate := WEAPON_FIRING;    // by FAB

        // start the animation
        ent.client.anim_priority := ANIM_ATTACK;
        if ((ent.client.ps.pmove.pm_flags AND PMF_DUCKED) <> 0)
        then begin
          ent.s.frame := FRAME_crattak1-1;   // by FAB
          ent.client.anim_end := FRAME_crattak9; //by FAB
        end
        else begin
          ent.s.frame := FRAME_attack1-1;    //by FAB
          ent.client.anim_end := FRAME_attack8;  //by FAB
        end;
      end
      else begin
        if (level.time >= ent.pain_debounce_time) then
        begin
          gi.sound(ent, CHAN_VOICE, gi.soundindex('weapons/noammo.wav'), 1, ATTN_NORM, 0);
          ent.pain_debounce_time := level.time + 1;
        end;
        NoAmmoWeaponChange (ent);
      end;//else
    end
    else begin
      if (ent.client.ps.gunframe = FRAME_IDLE_LAST) then
      begin
        ent.client.ps.gunframe := FRAME_IDLE_FIRST; // by FAB
        Exit;
      end;

     if (pause_frames) then
     begin
        //for (n = 0; pause_frames[n]; n++)
        for n:=0 to pause_frames [n]-1 do
        begin
          if (ent.client.ps.gunframe = pause_frames[n]) then
            if (rand() and 15) <> 0 then
              Exit;
         end;
      end;
      Inc(ent.client.ps.gunframe);
      Exit;
    end;//else
  end;//if

  if (ent.client.weaponstate = WEAPON_FIRING) then
  begin
    for (n = 0; fire_frames[n]; n++)
        for n:= 0 to fire_frames[n]-1 do
        begin
      if (ent.client.ps.gunframe = fire_frames[n]) then
      begin
//ZOID
(*        if (!CTFApplyStrengthSound(ent)) then *)
//ZOID
          if (ent.client.quad_framenum > level.framenum) then
            gi.sound(ent, CHAN_ITEM, gi.soundindex('items/damage3.wav'), 1, ATTN_NORM, 0);
//ZOID
(*        CTFApplyHasteSound(ent); *)
//ZOID

        fire (ent);
        exit ; //Break;
      end;
    end;
//    if (!fire_frames[n]) then
    if (fire_frames[n]=0) then
      Inc(ent.client.ps.gunframe);

    if (ent.client.ps.gunframe = FRAME_IDLE_FIRST+1) then // by FAB
      ent.client.weaponstate := WEAPON_READY;
  end;//if
end;//procedure onlyCTF

//ZOID
{procedure Weapon_Generic (edict_t *ent,
                          int FRAME_ACTIVATE_LAST, int FRAME_FIRE_LAST, int FRAME_IDLE_LAST, int FRAME_DEACTIVATE_LAST,
                          int *pause_frames, int *fire_frames, void ( *fire)(edict_t *ent))}
procedure Weapon_Generic (ent : edict_p;
                          FRAME_ACTIVATE_LAST, FRAME_FIRE_LAST, FRAME_IDLE_LAST, FRAME_DEACTIVATE_LAST : integer;
                          pause_frames, fire_frames : array of integer{;, void ( *fire)(edict_t *ent)});
var
  oldstate : integer;
begin
  oldstate := ent^.client^.weaponstate; // by FAB

  Weapon_Generic2 (ent, FRAME_ACTIVATE_LAST, FRAME_FIRE_LAST,
                   FRAME_IDLE_LAST, FRAME_DEACTIVATE_LAST, pause_frames,
                   fire_frames{, fire});

  // run the weapon frame again if hasted
  if (*((stricmp(ent.client.pers.weapon.pickup_name, 'Grapple') = 0) AND
     (ent.client.weaponstate = WEAPON_FIRING) then
    Exit;

(*if ((CTFApplyHaste(ent) ||
      (Q_stricmp(ent->client->pers.weapon->pickup_name, "Grapple") == 0 &&
      ent->client->weaponstate != WEAPON_FIRING))
      && oldstate == ent->client->weaponstate)* )

  if ( CTFApplyHaste(ent) OR
       ( (Q_stricmp(ent.client.pers.weapon.pickup_name, 'Grapple') = 0) AND
         (ent.client.weaponstate <> WEAPON_FIRING) )
     ) AND
     (oldstate = ent.client.weaponstate) then*)
    Weapon_Generic2 (ent, FRAME_ACTIVATE_LAST, FRAME_FIRE_LAST,
                     FRAME_IDLE_LAST, FRAME_DEACTIVATE_LAST, pause_frames,
                     fire_frames{, fire});
end;//procedure onlyCTF
//ZOID*)
{$ELSE}
procedure Weapon_Generic (ent : edict_p;
                          FRAME_ACTIVATE_LAST, FRAME_FIRE_LAST, FRAME_IDLE_LAST, FRAME_DEACTIVATE_LAST : integer;
                          pause_frames, fire_frames : PIntegerArray; fire : Proc_edit_s);
var
  FRAME_FIRE_FIRST,
  FRAME_IDLE_FIRST,
  FRAME_DEACTIVATE_FIRST,
  n : integer;
begin
  if (ent^.deadflag <> 0) OR (ent^.s.modelindex <> 255) then // VWep animations screw up corpses
    Exit;

  FRAME_FIRE_FIRST    := (FRAME_ACTIVATE_LAST + 1);
  FRAME_IDLE_FIRST    := (FRAME_FIRE_LAST + 1);
  FRAME_DEACTIVATE_FIRST := (FRAME_IDLE_LAST + 1);

  if (ent^.client^.weaponstate = WEAPON_DROPPING) then
  begin
    if (ent^.client^.ps.gunframe = FRAME_DEACTIVATE_LAST) then
    begin
      ChangeWeapon (ent);
      Exit;
    end
    else if ((FRAME_DEACTIVATE_LAST - ent^.client^.ps.gunframe) = 4) then
    begin
      ent^.client^.anim_priority := ANIM_REVERSE;
      if ((ent^.client^.ps.pmove.pm_flags AND PMF_DUCKED) <> 0) then
      begin
        ent^.s.frame := FRAME_crpain4 + 1; // by FAB
        ent^.client^.anim_end := FRAME_crpain1; //by FAB
      end
      else begin
        ent^.s.frame := FRAME_pain304 + 1;  //by FAB
        ent^.client^.anim_end := FRAME_pain301; //by FAB
      end;
    end;

    Inc(ent^.client^.ps.gunframe);
    Exit;
  end;

  if (ent^.client^.weaponstate = WEAPON_ACTIVATING) then
  begin
    if (ent^.client^.ps.gunframe = FRAME_ACTIVATE_LAST) then
    begin
      ent^.client^.weaponstate := WEAPON_READY;
      ent^.client^.ps.gunframe := FRAME_IDLE_FIRST;
      Exit;
    end;

    Inc(ent^.client^.ps.gunframe);
    Exit;
  end;

  if (ent^.client^.newweapon <> Nil) AND (ent^.client^.weaponstate <> WEAPON_FIRING) then
  begin
    ent^.client^.weaponstate := WEAPON_DROPPING;
    ent^.client^.ps.gunframe := FRAME_DEACTIVATE_FIRST;

    if ((FRAME_DEACTIVATE_LAST - FRAME_DEACTIVATE_FIRST) < 4) then
    begin
      ent^.client^.anim_priority := ANIM_REVERSE;
      if (ent^.client^.ps.pmove.pm_flags AND PMF_DUCKED) <> 0 then
      begin
        ent^.s.frame := FRAME_crpain4 + 1;  // by FAB
        ent^.client^.anim_end := FRAME_crpain1;  //by FAB
      end
      else begin
        ent^.s.frame := FRAME_pain304 + 1;  //by FAB
        ent^.client^.anim_end := FRAME_pain301; //by FAB
      end;
    end;
    Exit;
  end;

  if (ent^.client^.weaponstate = WEAPON_READY) then
  begin
//    if ( ((ent.client.latched_buttons OR ent.client.buttons) & BUTTON_ATTACK) )
    if ( ((ent^.client^.latched_buttons OR ent^.client^.buttons) AND BUTTON_ATTACK) <> 0 ) then
    begin
      ent^.client^.latched_buttons := ent^.client^.latched_buttons AND (NOT BUTTON_ATTACK);
      if ( (ent^.client^.ammo_index = 0) OR
           (ent^.client^.pers.inventory[ent^.client^.ammo_index] >= ent^.client^.pers.weapon^.quantity) ) then
      begin
        ent^.client^.ps.gunframe := FRAME_FIRE_FIRST;
        ent^.client^.weaponstate := WEAPON_FIRING; // by FAB

        // start the animation
        ent^.client^.anim_priority := ANIM_ATTACK;
        if ((ent^.client^.ps.pmove.pm_flags AND PMF_DUCKED) <> 0) then
        begin
          ent^.s.frame := FRAME_crattak1 - 1; //by FAB
          ent^.client^.anim_end := FRAME_crattak9;// by FAB
        end
        else begin
          ent^.s.frame := FRAME_attack1 - 1;  //by FAB
          ent^.client^.anim_end := FRAME_attack8; //by FAB
        end;
      end
      else begin
        if (level.time >= ent^.pain_debounce_time) then
        begin
          gi.sound(ent, CHAN_VOICE, gi.soundindex('weapons/noammo.wav'), 1, ATTN_NORM, 0);
          ent^.pain_debounce_time := level.time + 1;
        end;
        NoAmmoWeaponChange (ent);
      end;
    end
    else begin
      if (ent^.client^.ps.gunframe = FRAME_IDLE_LAST) then
      begin
        ent^.client^.ps.gunframe := FRAME_IDLE_FIRST;
        Exit;
      end;

      if (pause_frames <> nil) then
      begin
        n := 0;
        while pause_frames[n] <> 0 do
        begin
          if (ent^.client^.ps.gunframe = pause_frames[n]) then
            if (rand() and 15) <> 0 then
              Exit;
          n := n + 1;
        end;
      end;

      Inc(ent^.client^.ps.gunframe);
      Exit;
    end;
  end;

  if (ent^.client^.weaponstate = WEAPON_FIRING) then
  begin
    n := 0;
    while fire_frames[n] <> 0 do
    begin
        if (ent^.client^.ps.gunframe = fire_frames[n]) then
        begin
          if (ent^.client^.quad_framenum > level.framenum) then
            gi.sound(ent, CHAN_ITEM, gi.soundindex('items/damage3.wav'), 1, ATTN_NORM, 0);

          fire (ent);
          Break;
        end;
        n := n + 1;
    end;

    if (fire_frames[n] = 0) then
      Inc(ent^.client^.ps.gunframe);

    if (ent^.client^.ps.gunframe = FRAME_IDLE_FIRST+1) then
      ent^.client^.weaponstate := WEAPON_READY;
  end;
end;
{$ENDIF}


{*
======================================================================

GRENADE

======================================================================
*}
const
  GRENADE_TIMER      = 3.0;
  GRENADE_MINSPEED = 400;
  GRENADE_MAXSPEED = 800;

procedure weapon_grenade_fire (ent : edict_p; held : qboolean); cdecl;
var
  offset,
  forward_, right,
  start           : vec3_t;
  timer,
  radius          : Single; // was Float ...by FAB
  speed, damage : integer;
begin
  damage := 125;  

  radius := damage + 40;
  if (is_quad) then
    damage := damage * 4;

  VectorSet(offset, 8, 8, ent^.viewheight-8);
  AngleVectors (ent^.client^.v_angle, @forward_, @right, NIL);  //..by FAB
  P_ProjectSource (ent^.client, ent^.s.origin, offset, forward_, right, start);

  timer := ent^.client^.grenade_time - level.time;
  (* speed = GRENADE_MINSPEED + (GRENADE_TIMER - timer) * ((GRENADE_MAXSPEED - GRENADE_MINSPEED) / GRENADE_TIMER); *)
  speed := Trunc(GRENADE_MINSPEED + (GRENADE_TIMER - timer) * ((GRENADE_MAXSPEED - GRENADE_MINSPEED) / GRENADE_TIMER));
  fire_grenade2 (ent, start, forward_, damage, speed, timer, radius, held);

  if ( (Trunc(dmflags^.value) AND DF_INFINITE_AMMO) = 0 ) then
    Dec(ent^.client^.pers.inventory[ent^.client^.ammo_index]);

  ent^.client^.grenade_time := level.time + 1.0;

  if (ent^.deadflag <> 0) OR (ent^.s.modelindex <> 255) then // VWep animations screw up corpses
    Exit;

{$IFNDEF CTF}  //onlyGAME
  if (ent^.health <= 0) then
    Exit;
{$ENDIF}

  if ((ent^.client^.ps.pmove.pm_flags AND PMF_DUCKED) <> 0)
  then begin
    ent^.client^.anim_priority := ANIM_ATTACK;
    ent^.s.frame := FRAME_crattak1-1;
    ent^.client^.anim_end := FRAME_crattak3; //by ..FAB
  end
  else begin
    ent^.client^.anim_priority := ANIM_REVERSE;
    ent^.s.frame := FRAME_wave08;
    ent^.client^.anim_end := FRAME_wave01;  // by.. FAB
  end;
end;


procedure Weapon_Grenade (ent : edict_p); //for g_items
begin
  if ((ent^.client^.newweapon <> Nil) AND (ent^.client^.weaponstate = WEAPON_READY)) then
  begin
    ChangeWeapon (ent);
    Exit;
  end;

  if (ent^.client^.weaponstate = WEAPON_ACTIVATING) then
  begin
    ent^.client^.weaponstate := WEAPON_READY;
    ent^.client^.ps.gunframe := 16;
    Exit;
  end;

  if (ent^.client^.weaponstate = WEAPON_READY) then
  begin
    if ( ((ent^.client^.latched_buttons OR ent^.client^.buttons) AND BUTTON_ATTACK) <> 0 ) then
    begin
      ent^.client^.latched_buttons := ent^.client^.latched_buttons AND (NOT BUTTON_ATTACK);
      if (ent^.client^.pers.inventory[ent^.client^.ammo_index] <> 0) then
      begin
        ent^.client^.ps.gunframe := 1;
        ent^.client^.weaponstate := WEAPON_FIRING;
        ent^.client^.grenade_time := 0;
      end
      else begin
        if (level.time >= ent^.pain_debounce_time) then
        begin
          gi.sound(ent, CHAN_VOICE, gi.soundindex('weapons/noammo.wav'), 1, ATTN_NORM, 0);
          ent^.pain_debounce_time := level.time + 1;
        end;
        NoAmmoWeaponChange (ent);
      end;
      Exit;
    end;

    if ((ent^.client^.ps.gunframe = 29) OR (ent^.client^.ps.gunframe = 34) OR
        (ent^.client^.ps.gunframe = 39) OR (ent^.client^.ps.gunframe = 48)) then
      if (rand() AND 15) <> 0 then
        Exit;

    Inc(ent^.client^.ps.gunframe);
    if (ent^.client^.ps.gunframe > 48) then
      ent^.client^.ps.gunframe := 16;
    Exit;
  end;

  if (ent^.client^.weaponstate = WEAPON_FIRING) then
  begin
    if (ent^.client^.ps.gunframe = 5) then
      gi.sound (ent, CHAN_WEAPON, gi.soundindex('weapons/hgrena1b.wav'), 1, ATTN_NORM, 0);

    if (ent^.client^.ps.gunframe = 11) then
    begin
      if (ent^.client^.grenade_time = 0) then
      begin
        ent^.client^.grenade_time := level.time + GRENADE_TIMER + 0.2;
        ent^.client^.weapon_sound := gi.soundindex('weapons/hgrenc1b.wav');
      end;

      // they waited too long, detonate it in their hand
      if (NOT ent^.client^.grenade_blew_up) AND (level.time >= ent^.client^.grenade_time) then
      begin
        ent^.client^.weapon_sound := 0;
        weapon_grenade_fire (ent, true);
        ent^.client^.grenade_blew_up := true;
      end;

      if ((ent^.client^.buttons AND BUTTON_ATTACK) <> 0) then
        Exit;

      if (ent^.client^.grenade_blew_up) then
        if (level.time >= ent^.client^.grenade_time) then
        begin
          ent^.client^.ps.gunframe := 15;
          ent^.client^.grenade_blew_up := false;
        end
        else
          Exit;
    end;

    if (ent^.client^.ps.gunframe = 12) then
    begin
      ent^.client^.weapon_sound := 0;
      weapon_grenade_fire (ent, false);
    end;

    if ((ent^.client^.ps.gunframe = 15) AND (level.time < ent^.client^.grenade_time)) then
      Exit;

    Inc(ent^.client^.ps.gunframe);

    if (ent^.client^.ps.gunframe = 16) then
    begin
      ent^.client^.grenade_time := 0;
      ent^.client^.weaponstate := WEAPON_READY;
    end;
  end;
end;


{*
======================================================================

GRENADE LAUNCHER

======================================================================
*}
procedure weapon_grenadelauncher_fire (ent : edict_p); cdecl;
var
  offset,
  forward_, right,
  start           : vec3_t;
  radius          : Single; // was Float ..by FAB
  damage : integer;
begin
  damage := 120;

  radius := damage + 40;
  if (is_quad) then
    damage := damage * 4;

  VectorSet(offset, 8, 8, ent^.viewheight-8);
  AngleVectors (ent^.client^.v_angle, @forward_, @right, NIL); // by..FAB
  P_ProjectSource (ent^.client, ent^.s.origin, offset, forward_, right, start);

  VectorScale (forward_, -2, ent^.client^.kick_origin);
  ent^.client^.kick_angles[0] := -1;

  fire_grenade (ent, start, forward_, damage, 600, 2.5, radius);

  gi.WriteByte (svc_muzzleflash);
  { According with last Juha help on convert it }
  //gi.WriteShort (ent-g_edicts);  ...by FAB
  gi.WriteShort((Cardinal(ent) - Cardinal(g_edicts))div sizeof(edict_t));
  gi.WriteByte (MZ_GRENADE OR is_silenced);
  gi.multicast (@ent^.s.origin, MULTICAST_PVS); // Added @ ..by FAB

  Inc(ent^.client^.ps.gunframe);

  PlayerNoise(ent, start, PNOISE_WEAPON);

  if ( (Trunc(dmflags^.value) AND DF_INFINITE_AMMO) = 0 ) then
    Dec(ent^.client^.pers.inventory[ent^.client^.ammo_index]);
end;

procedure Weapon_GrenadeLauncher (ent : edict_p); //for g_items
const
  pause_frames : array [0..3] of integer = (34, 51, 59, 0);
  fire_frames  : array [0..1] of integer = (6, 0);
begin
  Weapon_Generic (ent, 5, 16, 59, 64, @pause_frames, @fire_frames, weapon_grenadelauncher_fire);
end;


{*
======================================================================

ROCKET

======================================================================
*}

procedure Weapon_RocketLauncher_Fire (ent : edict_p); cdecl;
var
  offset, start,
  forward_, right : vec3_t;
  damage_radius   : Single;
  damage,
  radius_damage   : integer;
begin
  damage := 100 + Trunc(_random() * 20.0);
  radius_damage := 120;
  damage_radius := 120;
  if (is_quad) then
  begin
    damage := damage *4;
    radius_damage := radius_damage *4;
  end;

  AngleVectors (ent^.client^.v_angle, @forward_, @right, Nil);

  VectorScale (forward_, -2, ent^.client^.kick_origin);
  ent^.client^.kick_angles[0] := -1;

  VectorSet(offset, 8, 8, ent^.viewheight-8);
  P_ProjectSource (ent^.client, ent^.s.origin, offset, forward_, right, start);
  fire_rocket (ent, start, forward_, damage, 650, damage_radius, radius_damage);

  // send muzzle flash
  gi.WriteByte (svc_muzzleflash);
  { According with last Juha help on convert it }
  gi.WriteShort ((Cardinal(ent)-Cardinal(g_edicts)) div SizeOf(edict_p));
  gi.WriteByte (MZ_ROCKET OR is_silenced);
  gi.multicast (@ent^.s.origin, MULTICAST_PVS);

  Inc(ent^.client^.ps.gunframe);

  PlayerNoise(ent, start, PNOISE_WEAPON);

  if ( (Trunc(dmflags^.value) AND DF_INFINITE_AMMO) = 0 ) then
    Dec(ent^.client^.pers.inventory[ent^.client^.ammo_index]);
end;


procedure Weapon_RocketLauncher (ent : edict_p); //for g_items
const
  pause_frames : array [0..4] of integer = (25, 33, 42, 50, 0);
  fire_frames  : array [0..1] of integer = (5, 0);
begin
  Weapon_Generic (ent, 4, 12, 50, 54, @pause_frames, @fire_frames, Weapon_RocketLauncher_Fire);
end;


{*
======================================================================

BLASTER / HYPERBLASTER

======================================================================
*}

procedure Blaster_Fire (ent : edict_p; const g_offset : vec3_t; damage : integer; hyper : qboolean; effect : integer); cdecl;
var
  forward_, right,
  start,
  offset          : vec3_t;
begin
  if (is_quad) then
    damage := damage *4;
  AngleVectors (ent^.client^.v_angle, @forward_, @right, Nil);
  VectorSet(offset, 24, 8, ent^.viewheight-8);
  VectorAdd (offset, g_offset, offset);
  P_ProjectSource (ent^.client, ent^.s.origin, offset, forward_, right, start);

  VectorScale (forward_, -2, ent^.client^.kick_origin);
  ent^.client^.kick_angles[0] := -1;

  fire_blaster (ent, start, forward_, damage, 1000, effect, hyper);

  // send muzzle flash
  gi.WriteByte (svc_muzzleflash);
  { According with last Juha help on convert it }
  gi.WriteShort((Cardinal(ent) - Cardinal(g_edicts))div sizeof(edict_t));
  if (hyper) then
    gi.WriteByte (MZ_HYPERBLASTER OR is_silenced)
  else
    gi.WriteByte (MZ_BLASTER OR is_silenced);
  gi.multicast (@ent^.s.origin, MULTICAST_PVS); //added @ ..by FAB

  PlayerNoise(ent, start, PNOISE_WEAPON);
end;

procedure Weapon_Blaster_Fire (ent : edict_p); cdecl;
var
  damage : integer;
begin
  if (deathmatch^.value <> 0) then
    damage := 15
  else
    damage := 10;
  Blaster_Fire (ent, vec3_origin, damage, false, EF_BLASTER);
  Inc(ent^.client^.ps.gunframe);
end;

procedure Weapon_Blaster (ent : edict_p); //for g_items
const
  pause_frames : array [0..2] of integer = (19, 32, 0);
  fire_frames  : array [0..1] of integer = (5, 0);
begin
  Weapon_Generic (ent, 4, 8, 52, 55, @pause_frames, @fire_frames, Weapon_Blaster_Fire);
end;

procedure Weapon_HyperBlaster_Fire (ent : edict_p); cdecl;
var
  rotation : Single; //was Float ..by FAB
  offset   : vec3_t;
  effect,
  damage   : integer;
begin
  ent^.client^.weapon_sound := gi.soundindex('weapons/hyprbl1a.wav');

  if ( (ent^.client^.buttons AND BUTTON_ATTACK) = 0 ) then
  begin
    Inc(ent^.client^.ps.gunframe);
  end
  else begin
    if (ent^.client^.pers.inventory[ent^.client^.ammo_index] = 0) then
    begin
      if (level.time >= ent^.pain_debounce_time) then
      begin
        gi.sound(ent, CHAN_VOICE, gi.soundindex('weapons/noammo.wav'), 1, ATTN_NORM, 0);
        ent^.pain_debounce_time := level.time + 1;
      end;
      NoAmmoWeaponChange (ent);
    end
    else begin
      rotation := (ent^.client^.ps.gunframe - 5) * 2*M_PI/6;
      offset[0] := -4 * sin(rotation);
      offset[1] := 0;
      offset[2] := 4 * cos(rotation);

      if ((ent^.client^.ps.gunframe = 6) OR (ent^.client^.ps.gunframe = 9)) then
        effect := EF_HYPERBLASTER
      else
        effect := 0;

      if (deathmatch^.value <> 0) then
        damage := 15
      else
        damage := 20;

      Blaster_Fire (ent, offset, damage, true, effect);
      if ( (Trunc(dmflags^.value) AND DF_INFINITE_AMMO) = 0 ) then
        Dec(ent^.client^.pers.inventory[ent^.client^.ammo_index]);

      ent^.client^.anim_priority := ANIM_ATTACK;
      if (ent^.client^.ps.pmove.pm_flags AND PMF_DUCKED) <> 0 then
      begin
        ent^.s.frame := FRAME_crattak1 - 1;
        ent^.client^.anim_end := FRAME_crattak9; // by FAB
      end
      else begin
        ent^.s.frame := FRAME_attack1 - 1;
        ent^.client^.anim_end := FRAME_attack8;  // by FAB
      end;
    end;

    Inc(ent^.client^.ps.gunframe);
    if (ent^.client^.ps.gunframe = 12) AND (ent^.client^.pers.inventory[ent^.client^.ammo_index] <> 0) then
      ent^.client^.ps.gunframe := 6;
  end;

  if (ent^.client^.ps.gunframe = 12) then
  begin
    gi.sound(ent, CHAN_AUTO, gi.soundindex('weapons/hyprbd1a.wav'), 1, ATTN_NORM, 0);
    ent^.client^.weapon_sound := 0;
  end;
end;

procedure Weapon_HyperBlaster (ent : edict_p); //for g_items
const
  pause_frames : array [0..0] of integer = (0); //OR pause_frames : integer = 0;
  fire_frames  : array [0..6] of integer = (6, 7, 8, 9, 10, 11, 0);
begin
  Weapon_Generic (ent, 5, 20, 49, 53, @pause_frames, @fire_frames, Weapon_HyperBlaster_Fire);
end;

{*
======================================================================

MACHINEGUN / CHAINGUN

======================================================================
*}

procedure Machinegun_Fire (ent : edict_p); cdecl;
var
  i : integer;
  start,
  forward_, right,
  angles,
  offset         : vec3_t;
  damage, kick : integer;
begin
  damage := 8;
  kick   := 2;

  if ( (ent^.client^.buttons AND BUTTON_ATTACK) = 0 ) then
  begin
    ent^.client^.machinegun_shots := 0;
    Inc(ent^.client^.ps.gunframe);
    Exit;
  end;

  if (ent^.client^.ps.gunframe = 5) then
    ent^.client^.ps.gunframe := 4
  else
    ent^.client^.ps.gunframe := 5;

  if (ent^.client^.pers.inventory[ent^.client^.ammo_index] < 1) then
  begin
    ent^.client^.ps.gunframe := 6;
    if (level.time >= ent^.pain_debounce_time) then
    begin
      gi.sound(ent, CHAN_VOICE, gi.soundindex('weapons/noammo.wav'), 1, ATTN_NORM, 0);
      ent^.pain_debounce_time := level.time + 1;
    end;
    NoAmmoWeaponChange (ent);
    Exit;
  end;

  if (is_quad) then
  begin
    damage := damage *4;
    kick := kick *4;
  end;

  for i := 1 to 2 do
  begin
    ent^.client^.kick_origin[i] := crandom() * 0.35;
    ent^.client^.kick_angles[i] := crandom() * 0.7;
  end;
  ent^.client^.kick_origin[0] := crandom() * 0.35;
  ent^.client^.kick_angles[0] := ent^.client^.machinegun_shots * -1.5;

  // raise the gun as it is firing
  if (deathmatch^.value=0) then
  begin
    Inc(ent^.client^.machinegun_shots);
    if (ent^.client^.machinegun_shots > 9) then
      ent^.client^.machinegun_shots := 9;
  end;

  // get start / end positions
  VectorAdd (ent^.client^.v_angle, ent^.client^.kick_angles, angles);
  AngleVectors (angles, @forward_, @right, Nil);
  VectorSet(offset, 0, 8, ent^.viewheight-8);
  P_ProjectSource (ent^.client, ent^.s.origin, offset, forward_, right, start);
  fire_bullet (ent, start, forward_, damage, kick, DEFAULT_BULLET_HSPREAD, DEFAULT_BULLET_VSPREAD, MOD_MACHINEGUN);

  gi.WriteByte (svc_muzzleflash);
  { According with last Juha help on convert it }
  gi.WriteShort((Cardinal(ent) - Cardinal(g_edicts))div sizeof(edict_t));
  gi.WriteByte (MZ_MACHINEGUN OR is_silenced);
  gi.multicast (@ent^.s.origin, MULTICAST_PVS);

  PlayerNoise(ent, start, PNOISE_WEAPON);

  if ( (Trunc(dmflags^.value) AND DF_INFINITE_AMMO) = 0 ) then
    Dec(ent^.client^.pers.inventory[ent^.client^.ammo_index]);

  ent^.client^.anim_priority := ANIM_ATTACK;
  if ((ent^.client^.ps.pmove.pm_flags AND PMF_DUCKED) <> 0) then
  begin
    ent^.s.frame := FRAME_crattak1 -  trunc((_random()+0.25));
    ent^.client^.anim_end := FRAME_crattak9;
  end
  else begin
    ent^.s.frame := FRAME_attack1 -  trunc(_random()+0.25);
    ent^.client^.anim_end := FRAME_attack8;
  end;
end;

procedure Weapon_Machinegun (ent : edict_p); //for g_items
const
  pause_frames : array [0..2] of integer = (23, 45, 0);
  fire_frames  : array [0..2] of integer = (4, 5, 0);
begin
  Weapon_Generic (ent, 3, 5, 45, 49, @pause_frames, @fire_frames, Machinegun_Fire);
end;


procedure Chaingun_Fire (ent : edict_p); cdecl;
var
  i,
  shots,
  damage              : integer;
  start,
  forward_, right, up,
  offset              : vec3_t;
  r, u                : Single; //was Float ..by FAB
  kick : integer;
begin
  kick := 2; 

  if (deathmatch^.value <> 0) then
    damage := 6
  else
    damage := 8;

  if (ent^.client^.ps.gunframe = 5) then
    gi.sound(ent, CHAN_AUTO, gi.soundindex('weapons/chngnu1a.wav'), 1, ATTN_IDLE, 0);

  if (ent^.client^.ps.gunframe = 14) AND ((ent^.client^.buttons AND BUTTON_ATTACK) = 0) then
  begin
    ent^.client^.ps.gunframe := 32;
    ent^.client^.weapon_sound := 0;
    Exit;
  end
  else if ( (ent^.client^.ps.gunframe = 21) AND ((ent^.client^.buttons AND BUTTON_ATTACK) <> 0) AND
  (ent^.client^.pers.inventory[ent^.client^.ammo_index] <> 0) ) then
    ent^.client^.ps.gunframe := 15
  else
    Inc(ent^.client^.ps.gunframe);

  if (ent^.client^.ps.gunframe = 22) then     // by FAB
  begin
    ent^.client^.weapon_sound := 0;
    gi.sound(ent, CHAN_AUTO, gi.soundindex('weapons/chngnd1a.wav'), 1, ATTN_IDLE, 0);
  end
  else
    ent^.client^.weapon_sound := gi.soundindex('weapons/chngnl1a.wav');  // by FAB

  ent^.client^.anim_priority := ANIM_ATTACK;
  if (ent^.client^.ps.pmove.pm_flags AND PMF_DUCKED) <> 0 then
  begin
    ent^.s.frame := FRAME_crattak1 - (ent^.client^.ps.gunframe and 1);
    ent^.client^.anim_end := FRAME_crattak9;
  end
  else begin
    ent^.s.frame := FRAME_attack1 - (ent^.client^.ps.gunframe and 1);
    ent^.client^.anim_end := FRAME_attack8;
  end;

  if (ent^.client^.ps.gunframe <= 9) then
    shots := 1
  else if (ent^.client^.ps.gunframe <= 14) then
  begin
    if (ent^.client^.buttons AND BUTTON_ATTACK) <> 0 then
      shots := 2
    else
      shots := 1;
  end
  else
    shots := 3;

  if (ent^.client^.pers.inventory[ent^.client^.ammo_index] < shots) then
    shots := ent^.client^.pers.inventory[ent^.client^.ammo_index];

  if (shots = 0) then
  begin
    if (level.time >= ent^.pain_debounce_time) then
    begin
      gi.sound(ent, CHAN_VOICE, gi.soundindex('weapons/noammo.wav'), 1, ATTN_NORM, 0);
      ent^.pain_debounce_time := level.time + 1;
    end;
    NoAmmoWeaponChange (ent);
    Exit;
  end;

  if (is_quad) then
  begin
    damage := damage *4;
    kick := kick *4;
  end;

  for i := 0 to 2 do
  begin
    ent^.client^.kick_origin[i] := crandom() * 0.35;
    ent^.client^.kick_angles[i] := crandom() * 0.7;
  end;

  for i := 0 to (shots - 1) do
  begin
    // get start / end positions
    AngleVectors (ent^.client^.v_angle, @forward_, @right, @up);
    r := 7 + crandom()*4;
    u := crandom()*4;
    VectorSet(offset, 0, r, u + ent^.viewheight-8);
    P_ProjectSource (ent^.client, ent^.s.origin, offset, forward_, right, start);

    fire_bullet (ent, start, forward_, damage, kick, DEFAULT_BULLET_HSPREAD, DEFAULT_BULLET_VSPREAD, MOD_CHAINGUN);
  end;

  // send muzzle flash
  gi.WriteByte (svc_muzzleflash);
  { According with last Juha help on convert it }
  gi.WriteShort((Cardinal(ent) - Cardinal(g_edicts))div sizeof(edict_t));
  gi.WriteByte ((MZ_CHAINGUN1 + shots - 1) OR is_silenced);
  gi.multicast (@ent^.s.origin, MULTICAST_PVS); //added @ ..by FAB

  PlayerNoise(ent, start, PNOISE_WEAPON);

  if ( (Trunc(dmflags^.value) AND DF_INFINITE_AMMO) = 0 ) then
    ent^.client^.pers.inventory[ent^.client^.ammo_index] := ent^.client^.pers.inventory[ent^.client^.ammo_index] -shots;
end;

procedure Weapon_Chaingun (ent : edict_p); //for g_items
const
  pause_frames : array [0..4] of integer = (38, 43, 51, 61, 0);
  fire_frames  : array [0..17] of integer = (5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 0);
begin
  Weapon_Generic (ent, 4, 31, 61, 64, @pause_frames, @fire_frames, Chaingun_Fire);
end;


{*
======================================================================

SHOTGUN / SUPERSHOTGUN

======================================================================
*}

procedure weapon_shotgun_fire (ent : edict_p); cdecl;
var
  start,
  forward_, right,
  offset         : vec3_t;
  damage, kick : integer;
begin
  damage := 4;
  kick   := 8;

  if (ent^.client^.ps.gunframe = 9) then
  begin
    Inc(ent^.client^.ps.gunframe);
    Exit;
  end;

  AngleVectors (ent^.client^.v_angle, @forward_, @right, Nil);

  VectorScale (forward_, -2, ent^.client^.kick_origin);
  ent^.client^.kick_angles[0] := -2;

  VectorSet(offset, 0, 8,  ent^.viewheight-8);
  P_ProjectSource (ent^.client, ent^.s.origin, offset, forward_, right, start);

  if (is_quad) then
  begin
    damage := damage *4;
    kick := kick *4;
  end;

  if (deathmatch^.value <> 0) then
    fire_shotgun (ent, start, forward_, damage, kick, 500, 500, DEFAULT_DEATHMATCH_SHOTGUN_COUNT, MOD_SHOTGUN)
  else
    fire_shotgun (ent, start, forward_, damage, kick, 500, 500, DEFAULT_SHOTGUN_COUNT, MOD_SHOTGUN);

  // send muzzle flash
  gi.WriteByte (svc_muzzleflash);
  { According with last Juha help on convert it }
  gi.WriteShort((Cardinal(ent) - Cardinal(g_edicts))div sizeof(edict_t));
  gi.WriteByte (MZ_SHOTGUN or is_silenced);
  gi.multicast (@ent^.s.origin, MULTICAST_PVS);

  Inc(ent^.client^.ps.gunframe);
  PlayerNoise(ent, start, PNOISE_WEAPON);

  if ( (Trunc(dmflags^.value) AND DF_INFINITE_AMMO) = 0 ) then
    Dec(ent^.client^.pers.inventory[ent^.client^.ammo_index]);
end;


procedure Weapon_Shotgun (ent : edict_p); //for g_items
const
  pause_frames : array [0..3] of integer = (22, 28, 34, 0);
  fire_frames  : array [0..2] of integer = (8, 9, 0);
begin
  Weapon_Generic (ent, 7, 18, 36, 39, @pause_frames, @fire_frames, weapon_shotgun_fire);
end;


procedure weapon_supershotgun_fire (ent : edict_p); cdecl;
var
  start,
  forward_, right,
  offset,
  v              : vec3_t;
  damage, kick : integer;
begin
  damage := 6;
  kick   := 12;

  AngleVectors (ent^.client^.v_angle, @forward_, @right, Nil);

  VectorScale (forward_, -2, ent^.client^.kick_origin);
  ent^.client^.kick_angles[0] := -2;

  VectorSet(offset, 0, 8,  ent^.viewheight-8);
  P_ProjectSource (ent^.client, ent^.s.origin, offset, forward_, right, start);

  if (is_quad) then
  begin
    damage := damage *4;
    kick := kick *4;
  end;

  v[PITCH] := ent^.client^.v_angle[PITCH];
  v[YAW]   := ent^.client^.v_angle[YAW] - 5;
  v[ROLL]  := ent^.client^.v_angle[ROLL];
  AngleVectors (v, @forward_, Nil, Nil);
  fire_shotgun (ent, start, forward_, damage, kick, DEFAULT_SHOTGUN_HSPREAD, DEFAULT_SHOTGUN_VSPREAD, DEFAULT_SSHOTGUN_COUNT DIV 2, MOD_SSHOTGUN);
  v[YAW]   := ent^.client^.v_angle[YAW] + 5;
  AngleVectors (v, @forward_, Nil, Nil);
  fire_shotgun (ent, start, forward_, damage, kick, DEFAULT_SHOTGUN_HSPREAD, DEFAULT_SHOTGUN_VSPREAD, DEFAULT_SSHOTGUN_COUNT DIV 2, MOD_SSHOTGUN);

  // send muzzle flash
  gi.WriteByte (svc_muzzleflash);
  { According with last Juha help on convert it }
  gi.WriteShort((Cardinal(ent) - Cardinal(g_edicts))div sizeof(edict_t));
  gi.WriteByte (MZ_SSHOTGUN or is_silenced);
  gi.multicast (@ent^.s.origin, MULTICAST_PVS);

  Inc(ent^.client^.ps.gunframe);
  PlayerNoise(ent, start, PNOISE_WEAPON);

  if ( (Trunc(dmflags^.value) AND DF_INFINITE_AMMO) = 0 ) then
    ent^.client^.pers.inventory[ent^.client^.ammo_index] := ent^.client^.pers.inventory[ent^.client^.ammo_index] -2;
end;


procedure Weapon_SuperShotgun (ent : edict_p); //for g_items
const
  pause_frames : array [0..3] of integer = (29, 42, 57, 0);
  fire_frames  : array [0..1] of integer = (7, 0);
begin
  Weapon_Generic (ent, 6, 17, 57, 61, @pause_frames, @fire_frames, weapon_supershotgun_fire);
end;


{*
======================================================================

RAILGUN

======================================================================
*}

procedure weapon_railgun_fire (ent : edict_p); cdecl;
var
  start,
  forward_, right,
  offset          : vec3_t;
  damage,
  kick            : integer;
begin
  if (deathmatch^.value <> 0) then
  begin
  // normal damage is too extreme in dm
    damage := 100;
    kick := 200;
  end
  else begin
    damage := 150;
    kick := 250;
  end;

  if (is_quad) then
  begin
    damage := damage *4;
    kick := kick *4;
  end;

  AngleVectors (ent^.client^.v_angle, @forward_, @right, Nil);

  VectorScale (forward_, -3, ent^.client^.kick_origin);
  ent^.client^.kick_angles[0] := -3;

  VectorSet(offset, 0, 7,  ent^.viewheight-8);
  P_ProjectSource (ent^.client, ent^.s.origin, offset, forward_, right, start);
  fire_rail (ent, start, forward_, damage, kick);

  // send muzzle flash
  gi.WriteByte (svc_muzzleflash);
  { According with last Juha help on convert it }
  gi.WriteShort((Cardinal(ent) - Cardinal(g_edicts))div sizeof(edict_t));
  gi.WriteByte (MZ_RAILGUN or is_silenced);
  gi.multicast (@ent^.s.origin, MULTICAST_PVS); //added @ ..by FAB

  Inc(ent^.client^.ps.gunframe);
  PlayerNoise(ent, start, PNOISE_WEAPON);

  if ( (Trunc(dmflags^.value) AND DF_INFINITE_AMMO) = 0 ) then
    Dec(ent^.client^.pers.inventory[ent^.client^.ammo_index]);
end;


procedure Weapon_Railgun (ent : edict_p); //for g_items
const
  pause_frames : array [0..1] of integer = (56, 0);
  fire_frames  : array [0..1] of integer = (4, 0);
begin
  Weapon_Generic (ent, 3, 18, 56, 61, @pause_frames, @fire_frames, weapon_railgun_fire);
end;


{*
======================================================================

BFG10K

======================================================================
*}

procedure weapon_bfg_fire (ent : edict_p); cdecl;
var
  offset, start,
  forward_, right  : vec3_t;
  damage           : integer;
  damage_radius: Single;
begin
  damage_radius := 1000;
  
  if (deathmatch^.value <> 0) then
    damage := 200
  else
    damage := 500;

  if (ent^.client^.ps.gunframe = 9) then
  begin
    // send muzzle flash
    gi.WriteByte (svc_muzzleflash);
    { According with last Juha help on convert it }
    gi.WriteShort((Cardinal(ent) - Cardinal(g_edicts))div sizeof(edict_t));
    gi.WriteByte (MZ_BFG or is_silenced);
    gi.multicast (@ent^.s.origin, MULTICAST_PVS); //added @ ..by FAB

    Inc(ent^.client^.ps.gunframe);

    PlayerNoise(ent, ent^.s.origin, PNOISE_WEAPON);
    Exit;
  end;

  // cells can go down during windup (from power armor hits), so
  // check again and abort firing if we don't have enough now
  if (ent^.client^.pers.inventory[ent^.client^.ammo_index] < 50) then
  begin
    Inc(ent^.client^.ps.gunframe);
    Exit;
  end;

  if (is_quad) then
    damage := damage *4;

  AngleVectors (ent^.client^.v_angle, @forward_, @right, Nil);

  VectorScale (forward_, -2, ent^.client^.kick_origin);

  // make a big pitch kick with an inverse fall
  ent.client.v_dmg_pitch := -40;
  ent.client.v_dmg_roll := crandom()*8;
  ent.client.v_dmg_time := level.time + DAMAGE_TIME;

  VectorSet(offset, 8, 8, ent^.viewheight-8);
  P_ProjectSource (ent^.client, ent^.s.origin, offset, forward_, right, start);
  fire_bfg (ent, start, forward_, damage, 400, damage_radius);

  Inc(ent^.client^.ps.gunframe);

  PlayerNoise(ent, start, PNOISE_WEAPON);

  if ( (Trunc(dmflags^.value) AND DF_INFINITE_AMMO) = 0 ) then
    ent^.client^.pers.inventory[ent^.client^.ammo_index] := ent^.client^.pers.inventory[ent^.client^.ammo_index] -50;
end;


procedure Weapon_BFG (ent : edict_p); //for g_items
const
  pause_frames : array [0..4] of integer = (39, 45, 50, 55, 0);
  fire_frames  : array [0..2] of integer = (9, 17, 0);
begin
  Weapon_Generic (ent, 8, 32, 55, 58, @pause_frames, @fire_frames , weapon_bfg_fire );
end;


//======================================================================

// End of file
//end.


{
My current problems:
--------------------
1) C2PAS: "if" & "for"

   C-code:
     if (pause_frames) then
      for (n = 0; pause_frames[n]; n++)
   PAS-code:
     if Assigned(pause_frames) then
     begin
       n := 0;
       while pause_frames[n] <> 0 do
       begin
         ...
         Inc(n);
       end;
     end;

2) OK!
}

end.
