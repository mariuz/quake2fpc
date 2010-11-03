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
{ File(s): g_items.c                                                         }
{                                                                            }
{ Initial conversion by : Bob Janova (bob@redcorona.com)                     }
{ Initial conversion on : 30-Apr-2002                                        }
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
{                                                                            }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{ 1)                                                                         }
{ 2)                                                                         }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{                                                                            }
{----------------------------------------------------------------------------}

unit g_items;

interface

uses
  GameUnit,
  p_weapon,
  q_shared,
  g_local;


//function Pickup_Weapon (Ent,Other:Pedict_t): QBoolean;
function Drop_Item (ent: edict_p; item:gitem_p):edict_p;
function FindItemByClassname(classname: pchar): gitem_p;   //Added by FAB
procedure Use_Quad (ent:edict_p; item:gitem_p); cdecl;    //Added by FAB
function PowerArmorType(ent: edict_p):integer;       //Added by FAB
function ITEM_INDEX(x: gitem_p):integer; //added by FAB
function FindItem(pickup_name: pchar): gitem_p;  //added by FAB
procedure SetRespawn(Ent:edict_p; Delay: Single); //added by FAB
function Add_Ammo (ent:edict_p;item: gitem_p; count:integer):qboolean; //added by FAB
function GetItemByIndex(index: Integer): gitem_p;     //added by FAB
function ArmorIndex (ent:edict_p):integer;      //added by FAB
procedure Touch_Item (ent:edict_p;other:edict_p;plane: cplane_p;surf: csurface_p); cdecl;
procedure SpawnItem (ent:edict_p;item: gitem_p); cdecl;
procedure SetItemNames;
procedure PrecacheItem (it:gitem_p);
procedure InitItems;

procedure SP_item_health (self:edict_p); cdecl;
procedure SP_item_health_small (self:edict_p); cdecl;
procedure SP_item_health_large (self:edict_p); cdecl;
procedure SP_item_health_mega (self:edict_p); cdecl;


const JacketArmor_Info: GItem_Armor_t =
  (Base_Count:25; Max_Count:50; Normal_Protection:0.30; Energy_Protection: 0.00; Armor:ARMOR_JACKET);
 CombatArmor_Info: GItem_Armor_t =
  (Base_Count:50; Max_Count:100; Normal_Protection:0.60; Energy_Protection: 0.30; Armor:ARMOR_COMBAT);
 BodyArmor_Info: GItem_Armor_t =
  (Base_Count:100; Max_Count:200; Normal_Protection:0.80; Energy_Protection: 0.60; Armor:ARMOR_BODY);

var
  jacket_armor_index,
  combat_armor_index,
  body_armor_index,
  power_screen_index,
  power_shield_index: Integer;
  Quad_drop_timeout_hack: Integer;

const
  HEALTH_IGNORE_MAX = 1;
  HEALTH_TIMED = 2;

function Pickup_Armor (ent:edict_p;other: edict_p):qboolean; cdecl;
function Pickup_PowerArmor (ent:edict_p;other:edict_p):qboolean; cdecl;
procedure Use_PowerArmor(ent:edict_p;item: gitem_p); cdecl;
procedure Drop_PowerArmor(ent:edict_p;item: gitem_p); cdecl;
function Pickup_Ammo (ent:edict_p;other:edict_p): qboolean; cdecl;
procedure Drop_Ammo(ent:edict_p;item: gitem_p); cdecl;
function Pickup_Powerup (Ent, Other:edict_p): QBoolean; cdecl;
procedure Drop_General(Ent:edict_p;Item: GItem_p); cdecl;
procedure Use_Invulnerability(ent:edict_p;item: gitem_p); cdecl;
procedure Use_Silencer (ent:edict_p;item: gitem_p); cdecl;
procedure Use_Breather (ent:edict_p; item:gitem_p); cdecl;
procedure Use_Envirosuit(ent:edict_p;item:gitem_p); cdecl;
function Pickup_AncientHead (Ent, Other:edict_p): QBoolean; cdecl;
function Pickup_Adrenaline (Ent, Other:edict_p): QBoolean; cdecl;
function Pickup_Bandolier (Ent, Other:edict_p): QBoolean; cdecl;
function Pickup_Pack (Ent, Other:edict_p): QBoolean; cdecl;
function Pickup_Key (ent:edict_p;other:edict_p):qboolean; cdecl;
function Pickup_Health (ent:edict_p;other:edict_p):qboolean; cdecl;


// Burnin : the function hack didn't work since the pointer to itens were needed in some places

const   itemlist:array[0..42] of gitem_t =  (

       (
       //   nil
       ),   // leave index 0 alone

   //
   // ARMOR
   //

{QUAKED item_armor_body (.3 .3 1) (-16 -16 -16) (16 16 16)
}
   (
           classname        : 'item_armor_body';
           pickup           : Pickup_Armor;
           use              : nil;
             drop             : nil;
           weaponthink      : nil;
           pickup_sound     : 'misc/ar1_pkup.wav';
           world_model      : 'models/items/armor/body/tris.md2';
                world_model_flags: EF_ROTATE;
             view_model       : nil;
{ icon }        icon             : 'i_bodyarmor';
{ pickup}   pickup_name      :'Body Armor';
{ width }   count_width      : 3;
      quantity         : 0;
      ammo             : nil;
      flags            : IT_ARMOR;
      weapmodel        : 0;
      info             : @bodyarmor_info;
           tag              : ARMOR_BODY;
{ precache }    precaches        : '';
   ),

{QUAKED item_armor_combat (.3 .3 1) (-16 -16 -16) (16 16 16)
}
       (

                classname        : 'item_armor_combat';
           pickup           : Pickup_Armor;
           use              : nil;
             drop             : nil;
           weaponthink      : nil;
           pickup_sound     : 'misc/ar1_pkup.wav';
           world_model      : 'models/items/armor/combat/tris.md2';
                world_model_flags: EF_ROTATE;
             view_model       : nil;
{ icon }        icon             : 'i_combatarmor';
{ pickup}   pickup_name      :'Combat Armor';
{ width }   count_width      : 3;
      quantity         : 0;
      ammo             : nil;
      flags            : IT_ARMOR;
      weapmodel        : 0;
      info             : @combatarmor_info;
           tag              : ARMOR_COMBAT;
{ precache }    precaches        : '';

        ),

{QUAKED item_armor_jacket (.3 .3 1) (-16 -16 -16) (16 16 16)
}
   (
                classname        : 'item_armor_jacket';
           pickup           : Pickup_Armor;
           use              : nil;
             drop             : nil;
           weaponthink      : nil;
           pickup_sound     : 'misc/ar1_pkup.wav';
           world_model      : 'models/items/armor/jacket/tris.md2';
                world_model_flags: EF_ROTATE;
             view_model       : nil;
{ icon }        icon             : 'i_jacketarmor';
{ pickup}   pickup_name      :'Jacket Armor';
{ width }   count_width      : 3;
      quantity         : 0;
      ammo             : nil;
      flags            : IT_ARMOR;
      weapmodel        : 0;
      info             : @jacketarmor_info;
           tag              : ARMOR_JACKET;
{ precache }    precaches        : '';

        ),

{QUAKED item_armor_shard (.3 .3 1) (-16 -16 -16) (16 16 16)
}
   (

                classname        : 'item_armor_shard';
           pickup           : Pickup_Armor;
           use              : nil;
             drop             : nil;
           weaponthink      : nil;
           pickup_sound     : 'misc/ar2_pkup.wav';
           world_model      : 'models/items/armor/shard/tris.md2';
                world_model_flags: EF_ROTATE;
             view_model       : nil;
{ icon }        icon             : 'i_jacketarmor';
{ pickup}   pickup_name      : 'Armor Shard';
{ width }   count_width      : 3;
      quantity         : 0;
      ammo             : nil;
      flags            : IT_ARMOR;
      weapmodel        : 0;
      info             : @jacketarmor_info;
           tag              : ARMOR_SHARD;
{ precache }    precaches        : '';


   ),


{QUAKED item_power_screen (.3 .3 1) (-16 -16 -16) (16 16 16)
}
   (
                classname        : 'item_power_screen';
           pickup           : Pickup_PowerArmor;
           use              : Use_PowerArmor;
             drop             : Drop_PowerArmor;
           weaponthink      : nil;
           pickup_sound     : 'misc/ar3_pkup.wav';
           world_model      : 'models/items/armor/screen/tris.md2';
                world_model_flags: EF_ROTATE;
             view_model       : nil;
{ icon }        icon             : 'i_powerscreen';
{ pickup}   pickup_name      : 'Power Screen';
{ width }   count_width      : 0;
      quantity         : 60;
      ammo             : nil;
      flags            : IT_ARMOR;
      weapmodel        : 0;
      info             : nil;
           tag              : 0;
{ precache }    precaches        : '';

      

   ),

{QUAKED item_power_shield (.3 .3 1) (-16 -16 -16) (16 16 16)
}
   (
                classname        : 'item_power_shield';
           pickup           : Pickup_PowerArmor;
           use              : Use_PowerArmor;
             drop             : Drop_PowerArmor;
           weaponthink      : nil;
           pickup_sound     : 'misc/ar3_pkup.wav';
           world_model      : 'models/items/armor/shield/tris.md2';
                world_model_flags: EF_ROTATE;
             view_model       : nil;
{ icon }        icon             : 'i_powershield';
{ pickup}   pickup_name      : 'Power Shield';
{ width }   count_width      : 0;
      quantity         : 60;
      ammo             : nil;
      flags            : IT_ARMOR;
      weapmodel        : 0;
      info             : nil;
           tag              : 0;
{ precache }    precaches        : 'misc/power2.wav misc/power1.wav';

   ),


   //
   // WEAPONS 
   //

{ weapon_blaster (.3 .3 1) (-16 -16 -16) (16 16 16)
always owned, never in the world
}
   (
                classname        : 'weapon_blaster';
           pickup           : nil;
           use              : Use_Weapon;
             drop             : nil;
           weaponthink      : Weapon_Blaster;
           pickup_sound     : 'misc/w_pkup.wav';
           world_model      : nil;
                world_model_flags: 0;
             view_model       : 'models/weapons/v_blast/tris.md2';
{ icon }        icon             : 'w_blaster';
{ pickup}   pickup_name      : 'Blaster';
{ width }   count_width      : 0;
      quantity         : 0;
      ammo             : nil;
      flags            : IT_WEAPON or IT_STAY_COOP;
      weapmodel        : WEAP_BLASTER;
      info             : nil;
           tag              : 0;
{ precache }    precaches        : 'weapons/blastf1a.wav misc/lasfly.wav';
   
   ),

{QUAKED weapon_shotgun (.3 .3 1) (-16 -16 -16) (16 16 16)
}
   (

                classname        : 'weapon_shotgun';
           pickup           : Pickup_Weapon;
           use              : Use_Weapon;
             drop             : Drop_Weapon;
           weaponthink      : Weapon_Shotgun;
           pickup_sound     : 'misc/w_pkup.wav';
           world_model      : 'models/weapons/g_shotg/tris.md2';
                world_model_flags: EF_ROTATE;
             view_model       : 'models/weapons/v_shotg/tris.md2';
{ icon }        icon             : 'w_shotgun';
{ pickup}   pickup_name      : 'Shotgun';
{ width }   count_width      : 0;
      quantity         : 1;
      ammo             : 'Shells';
      flags            : IT_WEAPON or IT_STAY_COOP;
      weapmodel        : WEAP_SHOTGUN;
      info             : nil;
           tag              : 0;
{ precache }    precaches        : 'weapons/shotgf1b.wav weapons/shotgr1b.wav';

   ),

{QUAKED weapon_supershotgun (.3 .3 1) (-16 -16 -16) (16 16 16)
}
   (
                classname        : 'weapon_supershotgun';
           pickup           : Pickup_Weapon;
           use              : Use_Weapon;
             drop             : Drop_Weapon;
           weaponthink      : Weapon_SuperShotgun;
           pickup_sound     : 'misc/w_pkup.wav';
           world_model      : 'models/weapons/g_shotg2/tris.md2';
                world_model_flags: EF_ROTATE;
             view_model       : 'models/weapons/v_shotg2/tris.md2';
{ icon }        icon             : 'w_sshotgun';
{ pickup}   pickup_name      : 'Super Shotgun';
{ width }   count_width      : 0;
      quantity         : 2;
      ammo             : 'Shells';
      flags            : IT_WEAPON or IT_STAY_COOP;
      weapmodel        : WEAP_SUPERSHOTGUN;
      info             : nil;
           tag              : 0;
{ precache }    precaches        : 'weapons/sshotgf1b.wav';
      
   ),

{QUAKED weapon_machinegun (.3 .3 1) (-16 -16 -16) (16 16 16)
}
   (
                classname        : 'weapon_machinegun';
           pickup           : Pickup_Weapon;
           use              : Use_Weapon;
             drop             : Drop_Weapon;
           weaponthink      : Weapon_Machinegun;
           pickup_sound     : 'misc/w_pkup.wav';
           world_model      : 'models/weapons/g_machn/tris.md2';
                world_model_flags: EF_ROTATE;
             view_model       : 'models/weapons/v_machn/tris.md2';
{ icon }        icon             : 'w_machinegun';
{ pickup}   pickup_name      : 'Machinegun';
{ width }   count_width      : 0;
      quantity         : 1;
      ammo             : 'Bullets';
      flags            : IT_WEAPON or IT_STAY_COOP;
      weapmodel        : WEAP_MACHINEGUN;
      info             : nil;
           tag              : 0;
{ precache }    precaches        : 'weapons/machgf1b.wav weapons/machgf2b.wav weapons/machgf3b.wav weapons/machgf4b.wav weapons/machgf5b.wav'

   ),

{QUAKED weapon_chaingun (.3 .3 1) (-16 -16 -16) (16 16 16)
}
   (
                classname        : 'weapon_chaingun';
           pickup           : Pickup_Weapon;
           use              : Use_Weapon;
             drop             : Drop_Weapon;
           weaponthink      : Weapon_Chaingun;
           pickup_sound     : 'misc/w_pkup.wav';
           world_model      : 'models/weapons/g_chain/tris.md2';
                world_model_flags: EF_ROTATE;
             view_model       : 'models/weapons/v_chain/tris.md2';
{ icon }        icon             : 'w_chaingun';
{ pickup}   pickup_name      : 'Chaingun';
{ width }   count_width      : 0;
      quantity         : 1;
      ammo             : 'Bullets';
      flags            : IT_WEAPON or IT_STAY_COOP;
      weapmodel        : WEAP_CHAINGUN;
      info             : nil;
           tag              : 0;
{ precache }    precaches        : 'weapons/chngnu1a.wav weapons/chngnl1a.wav weapons/machgf3b.wav` weapons/chngnd1a.wav'

          ),

{QUAKED ammo_grenades (.3 .3 1) (-16 -16 -16) (16 16 16)
}
   (
                classname        : 'ammo_grenades';
           pickup           : Pickup_Ammo;
           use              : Use_Weapon;
             drop             : Drop_Ammo;
           weaponthink      : Weapon_Grenade;
           pickup_sound     : 'misc/am_pkup.wav';
           world_model      : 'models/items/ammo/grenades/medium/tris.md2';
                world_model_flags: EF_ROTATE;
             view_model       : 'models/weapons/v_handgr/tris.md2';
{ icon }        icon             : 'a_grenades';
{ pickup}   pickup_name      : 'Grenades';
{ width }   count_width      : 3;
      quantity         : 5;
      ammo             : 'grenades';
      flags            : IT_AMMO or IT_WEAPON;
      weapmodel        : WEAP_GRENADES;
      info             : nil;
           tag              : ord(AMMO_GRENADES);
{ precache }    precaches        : 'weapons/hgrent1a.wav weapons/hgrena1b.wav weapons/hgrenc1b.wav weapons/hgrenb1a.wav weapons/hgrenb2a.wav '


   ),

{QUAKED weapon_grenadelauncher (.3 .3 1) (-16 -16 -16) (16 16 16)
}
   (
                classname        : 'weapon_grenadelauncher';
           pickup           : Pickup_Weapon;
           use              : Use_Weapon;
             drop             : Drop_Weapon;
           weaponthink      : Weapon_GrenadeLauncher;
           pickup_sound     : 'misc/w_pkup.wav';
           world_model      : 'models/weapons/g_launch/tris.md2';
                world_model_flags: EF_ROTATE;
             view_model       : 'models/weapons/v_launch/tris.md2';
{ icon }        icon             : 'w_glauncher';
{ pickup}   pickup_name      : 'Grenade Launcher';
{ width }   count_width      : 0;
      quantity         : 1;
      ammo             : 'Grenades';
      flags            : IT_WEAPON or IT_STAY_COOP;
      weapmodel        : WEAP_GRENADELAUNCHER;
      info             : nil;
           tag              : 0;
{ precache }    precaches        : 'models/objects/grenade/tris.md2 weapons/grenlf1a.wav weapons/grenlr1b.wav weapons/grenlb1b.wav'

          ),

{QUAKED weapon_rocketlauncher (.3 .3 1) (-16 -16 -16) (16 16 16)
}
   (
                classname        : 'weapon_rocketlauncher';
           pickup           : Pickup_Weapon;
           use              : Use_Weapon;
             drop             : Drop_Weapon;
           weaponthink      : Weapon_RocketLauncher;
           pickup_sound     : 'misc/w_pkup.wav';
           world_model      : 'models/weapons/g_rocket/tris.md2';
                world_model_flags: EF_ROTATE;
             view_model       : 'models/weapons/v_rocket/tris.md2';
{ icon }        icon             : 'w_rlauncher';
{ pickup}   pickup_name      : 'Rocket Launcher';
{ width }   count_width      : 0;
      quantity         : 1;
      ammo             : 'Rockets';
      flags            : IT_WEAPON or IT_STAY_COOP;
      weapmodel        : WEAP_ROCKETLAUNCHER;
      info             : nil;
           tag              : 0;
{ precache }    precaches        : 'models/objects/rocket/tris.md2 weapons/rockfly.wav weapons/rocklf1a.wav weapons/rocklr1b.wav models/objects/debris2/tris.md2'


         ),

{QUAKED weapon_hyperblaster (.3 .3 1) (-16 -16 -16) (16 16 16)
}
   (
                classname        : 'weapon_hyperblaster';
           pickup           : Pickup_Weapon;
           use              : Use_Weapon;
             drop             : Drop_Weapon;
           weaponthink      : Weapon_HyperBlaster;
           pickup_sound     : 'misc/w_pkup.wav';
           world_model      : 'models/weapons/g_hyperb/tris.md2';
                world_model_flags: EF_ROTATE;
             view_model       : 'models/weapons/v_hyperb/tris.md2';
{ icon }        icon             : 'w_hyperblaster';
{ pickup}   pickup_name      : 'HyperBlaster';
{ width }   count_width      : 0;
      quantity         : 1;
      ammo             : 'Cells';
      flags            : IT_WEAPON or IT_STAY_COOP;
      weapmodel        : WEAP_HYPERBLASTER;
      info             : nil;
           tag              : 0;
{ precache }    precaches        : 'weapons/hyprbu1a.wav weapons/hyprbl1a.wav weapons/hyprbf1a.wav weapons/hyprbd1a.wav misc/lasfly.wav'

    
   ),

{QUAKED weapon_railgun (.3 .3 1) (-16 -16 -16) (16 16 16)
}
       (

                classname        : 'weapon_railgun';
           pickup           : Pickup_Weapon;
           use              : Use_Weapon;
             drop             : Drop_Weapon;
           weaponthink      : Weapon_Railgun;
           pickup_sound     : 'misc/w_pkup.wav';
           world_model      : 'models/weapons/g_rail/tris.md2';
                world_model_flags: EF_ROTATE;
             view_model       : 'models/weapons/v_rail/tris.md2';
{ icon }        icon             : 'w_railgun';
{ pickup}   pickup_name      : 'Railgun';
{ width }   count_width      : 0;
      quantity         : 1;
      ammo             : 'Slugs';
      flags            : IT_WEAPON or IT_STAY_COOP;
      weapmodel        : WEAP_RAILGUN;
      info             : nil;
           tag              : 0;
{ precache }    precaches        : 'weapons/rg_hum.wav'
   
   ),

{QUAKED weapon_bfg (.3 .3 1) (-16 -16 -16) (16 16 16)
}
   (

                classname        : 'weapon_bfg';
           pickup           : Pickup_Weapon;
           use              : Use_Weapon;
             drop             : Drop_Weapon;
           weaponthink      : Weapon_BFG;
           pickup_sound     : 'misc/w_pkup.wav';
           world_model      : 'models/weapons/g_bfg/tris.md2';
                world_model_flags: EF_ROTATE;
             view_model       : 'models/weapons/v_bfg/tris.md2';
{ icon }        icon             : 'w_bfg';
{ pickup}   pickup_name      : 'BFG10K';
{ width }   count_width      : 0;
      quantity         : 50;
      ammo             : 'Cells';
      flags            : IT_WEAPON or IT_STAY_COOP;
      weapmodel        : WEAP_BFG;
      info             : nil;
           tag              : 0;
{ precache }    precaches        : 'sprites/s_bfg1.sp2 sprites/s_bfg2.sp2 sprites/s_bfg3.sp2 weapons/bfg__f1y.wav weapons/bfg__l1a.wav weapons/bfg__x1b.wav weapons/bfg_hum.wav'
      
   ),

   //
   // AMMO ITEMS
   //

{QUAKED ammo_shells (.3 .3 1) (-16 -16 -16) (16 16 16)
}
   (
                classname        : 'ammo_shells';
           pickup           : Pickup_Ammo;
           use              : nil;
             drop             : Drop_Ammo;
           weaponthink      : nil;
           pickup_sound     : 'misc/am_pkup.wav';
           world_model      : 'models/items/ammo/shells/medium/tris.md2';
                world_model_flags: 0;
             view_model       : nil;
{ icon }        icon             : 'a_shells';
{ pickup}   pickup_name      : 'Shells';
{ width }   count_width      : 3;
      quantity         : 10;
      ammo             : nil;
      flags            : IT_AMMO;
      weapmodel        : 0;
      info             : nil;
           tag              : ord(AMMO_SHELLS);
{ precache }    precaches        : '';


   ),

{QUAKED ammo_bullets (.3 .3 1) (-16 -16 -16) (16 16 16)
}
   (
                classname        : 'ammo_bullets';
           pickup           : Pickup_Ammo;
           use              : nil;
             drop             : Drop_Ammo;
           weaponthink      : nil;
           pickup_sound     : 'misc/am_pkup.wav';
           world_model      : 'models/items/ammo/bullets/medium/tris.md2';
                world_model_flags: 0;
             view_model       : nil;
{ icon }        icon             : 'a_bullets';
{ pickup}   pickup_name      : 'Bullets';
{ width }   count_width      : 3;
      quantity         : 50;
      ammo             : nil;
      flags            : IT_AMMO;
      weapmodel        : 0;
      info             : nil;
           tag              : ord(AMMO_BULLETS);
{ precache }    precaches        : '';

      
   ),

{QUAKED ammo_cells (.3 .3 1) (-16 -16 -16) (16 16 16)
}
   (
                classname        : 'ammo_cells';
           pickup           : Pickup_Ammo;
           use              : nil;
             drop             : Drop_Ammo;
           weaponthink      : nil;
           pickup_sound     : 'misc/am_pkup.wav';
           world_model      : 'models/items/ammo/cells/medium/tris.md2';
                world_model_flags: 0;
             view_model       : nil;
{ icon }        icon             : 'a_cells';
{ pickup}   pickup_name      : 'Cells';
{ width }   count_width      : 3;
      quantity         : 50;
      ammo             : nil;
      flags            : IT_AMMO;
      weapmodel        : 0;
      info             : nil;
           tag              : ord(AMMO_CELLS);
{ precache }    precaches        : '';

   
   ),

{QUAKED ammo_rockets (.3 .3 1) (-16 -16 -16) (16 16 16)
}
   (
                classname        : 'ammo_rockets';
           pickup           : Pickup_Ammo;
           use              : nil;
             drop             : Drop_Ammo;
           weaponthink      : nil;
           pickup_sound     : 'misc/am_pkup.wav';
           world_model      : 'models/items/ammo/rockets/medium/tris.md2';
                world_model_flags: 0;
             view_model       : nil;
{ icon }        icon             : 'a_rockets';
{ pickup}   pickup_name      : 'Rockets';
{ width }   count_width      : 3;
      quantity         : 5;
      ammo             : nil;
      flags            : IT_AMMO;
      weapmodel        : 0;
      info             : nil;
           tag              : ord(AMMO_ROCKETS);
{ precache }    precaches        : '';

      
   ),

{QUAKED ammo_slugs (.3 .3 1) (-16 -16 -16) (16 16 16)
}
   (
                classname        : 'ammo_slugs';
           pickup           : Pickup_Ammo;
           use              : nil;
             drop             : Drop_Ammo;
           weaponthink      : nil;
           pickup_sound     : 'misc/am_pkup.wav';
           world_model      : 'models/items/ammo/slugs/medium/tris.md2';
                world_model_flags: 0;
             view_model       : nil;
{ icon }        icon             : 'a_slugs';
{ pickup}   pickup_name      : 'Slugs';
{ width }   count_width      : 3;
      quantity         : 10;
      ammo             : nil;
      flags            : IT_AMMO;
      weapmodel        : 0;
      info             : nil;
           tag              : ord(AMMO_SLUGS);
{ precache }    precaches        : '';

   
   ),


   //
   // POWERUP ITEMS
   //
{QUAKED item_quad (.3 .3 1) (-16 -16 -16) (16 16 16)
}
   (
                classname        : 'item_quad';
           pickup           : Pickup_Powerup;
           use              : Use_Quad;
             drop             : Drop_General;
           weaponthink      : nil;
           pickup_sound     : 'items/pkup.wav';
           world_model      : 'models/items/quaddama/tris.md2';
                world_model_flags: EF_ROTATE;
             view_model       : nil;
{ icon }        icon             : 'p_quad';
{ pickup}   pickup_name      : 'Quad Damage';
{ width }   count_width      : 2;
      quantity         : 60;
      ammo             : nil;
      flags            : IT_POWERUP;
      weapmodel        : 0;
      info             : nil;
           tag              : 0;
{ precache }    precaches        : 'items/damage.wav items/damage2.wav items/damage3.wav';

   
   ),

{QUAKED item_invulnerability (.3 .3 1) (-16 -16 -16) (16 16 16)
}
   (
                classname        : 'item_invulnerability';
           pickup           : Pickup_Powerup;
           use              : Use_Invulnerability;
             drop             : Drop_General;
           weaponthink      : nil;
           pickup_sound     : 'items/pkup.wav';
           world_model      : 'models/items/invulner/tris.md2';
                world_model_flags: EF_ROTATE;
             view_model       : nil;
{ icon }        icon             : 'p_invulnerability';
{ pickup}   pickup_name      : 'Invulnerability';
{ width }   count_width      : 2;
      quantity         : 300;
      ammo             : nil;
      flags            : IT_POWERUP;
      weapmodel        : 0;
      info             : nil;
           tag              : 0;
{ precache }    precaches        : 'items/protect.wav items/protect2.wav items/protect4.wav';

   
   ),

{QUAKED item_silencer (.3 .3 1) (-16 -16 -16) (16 16 16)
}
   (
                classname        : 'item_silencer';
           pickup           : Pickup_Powerup;
           use              : Use_Silencer;
             drop             : Drop_General;
           weaponthink      : nil;
           pickup_sound     : 'items/pkup.wav';
           world_model      : 'models/items/silencer/tris.md2';
                world_model_flags: EF_ROTATE;
             view_model       : nil;
{ icon }        icon             : 'p_silencer';
{ pickup}   pickup_name      : 'Silencer';
{ width }   count_width      : 2;
      quantity         : 60;
      ammo             : nil;
      flags            : IT_POWERUP;
      weapmodel        : 0;
      info             : nil;
           tag              : 0;
{ precache }    precaches        : '';

   
   ),

{QUAKED item_breather (.3 .3 1) (-16 -16 -16) (16 16 16)
}
       (
                classname        : 'item_breather';
           pickup           : Pickup_Powerup;
           use              : Use_Breather;
             drop             : Drop_General;
           weaponthink      : nil;
           pickup_sound     : 'items/pkup.wav';
           world_model      : 'models/items/breather/tris.md2';
                world_model_flags: EF_ROTATE;
             view_model       : nil;
{ icon }        icon             : 'p_rebreather';
{ pickup}   pickup_name      : 'Rebreather';
{ width }   count_width      : 2;
      quantity         : 60;
      ammo             : nil;
      flags            : IT_STAY_COOP or IT_POWERUP;
      weapmodel        : 0;
      info             : nil;
           tag              : 0;
{ precache }    precaches        : 'items/airout.wav';


   ),

{QUAKED item_enviro (.3 .3 1) (-16 -16 -16) (16 16 16)
}
   (

                classname        : 'item_enviro';
           pickup           : Pickup_Powerup;
           use              : Use_Envirosuit;
             drop             : Drop_General;
           weaponthink      : nil;
           pickup_sound     : 'items/pkup.wav';
           world_model      : 'models/items/enviro/tris.md2';
                world_model_flags: EF_ROTATE;
             view_model       : nil;
{ icon }        icon             : 'p_envirosuit';
{ pickup}   pickup_name      : 'Environment Suit';
{ width }   count_width      : 2;
      quantity         : 60;
      ammo             : nil;
      flags            : IT_STAY_COOP or IT_POWERUP;
      weapmodel        : 0;
      info             : nil;
           tag              : 0;
{ precache }    precaches        : 'items/airout.wav';

   
   ),

{QUAKED item_ancient_head (.3 .3 1) (-16 -16 -16) (16 16 16)
Special item that gives +2 to maximum health
}
   (
                classname        : 'item_ancient_head';
           pickup           : Pickup_AncientHead;
           use              : nil;
             drop             : nil;
           weaponthink      : nil;
           pickup_sound     : 'items/pkup.wav';
           world_model      : 'models/items/c_head/tris.md2';
                world_model_flags: EF_ROTATE;
             view_model       : nil;
{ icon }        icon             : 'i_fixme';
{ pickup}   pickup_name      : 'Ancient Head';
{ width }   count_width      : 2;
      quantity         : 60;
      ammo             : nil;
      flags            : 0;
      weapmodel        : 0;
      info             : nil;
           tag              : 0;
{ precache }    precaches        : '';

       
   ),

{QUAKED item_adrenaline (.3 .3 1) (-16 -16 -16) (16 16 16)
gives +1 to maximum health
}
   (
                classname        : 'item_adrenaline';
           pickup           : Pickup_Adrenaline;
           use              : nil;
             drop             : nil;
           weaponthink      : nil;
           pickup_sound     : 'items/pkup.wav';
           world_model      : 'models/items/adrenal/tris.md2';
                world_model_flags: EF_ROTATE;
             view_model       : nil;
{ icon }        icon             : 'p_adrenaline';
{ pickup}   pickup_name      : 'Adrenaline';
{ width }   count_width      : 2;
      quantity         : 60;
      ammo             : nil;
      flags            : 0;
      weapmodel        : 0;
      info             : nil;
           tag              : 0;
{ precache }    precaches        : '';

   ),

{QUAKED item_bandolier (.3 .3 1) (-16 -16 -16) (16 16 16)
}
   (

                classname        : 'item_bandolier';
           pickup           : Pickup_Bandolier;
           use              : nil;
             drop             : nil;
           weaponthink      : nil;
           pickup_sound     : 'items/pkup.wav';
           world_model      : 'models/items/band/tris.md2';
                world_model_flags: EF_ROTATE;
             view_model       : nil;
{ icon }        icon             : 'p_bandolier';
{ pickup}   pickup_name      : 'Bandolier';
{ width }   count_width      : 2;
      quantity         : 60;
      ammo             : nil;
      flags            : 0;
      weapmodel        : 0;
      info             : nil;
           tag              : 0;
{ precache }    precaches        : '';

      
   ),

{QUAKED item_pack (.3 .3 1) (-16 -16 -16) (16 16 16)
}
   (
                classname        : 'item_pack';
           pickup           : Pickup_Pack;
           use              : nil;
             drop             : nil;
           weaponthink      : nil;
           pickup_sound     : 'items/pkup.wav';
           world_model      : 'models/items/pack/tris.md2';
                world_model_flags: EF_ROTATE;
             view_model       : nil;
{ icon }        icon             : 'i_pack';
{ pickup}   pickup_name      : 'Ammo Pack';
{ width }   count_width      : 2;
      quantity         : 100;
      ammo             : nil;
      flags            : 0;
      weapmodel        : 0;
      info             : nil;
           tag              : 0;
{ precache }    precaches        : '';


   ),

   //
   // KEYS
   //
{QUAKED key_data_cd (0 .5 .8) (-16 -16 -16) (16 16 16)
key for computer centers
}
   (
                classname        : 'key_data_cd';
           pickup           : Pickup_Key;
           use              : nil;
             drop             : Drop_General;
           weaponthink      : nil;
           pickup_sound     : 'items/pkup.wav';
           world_model      : 'models/items/keys/data_cd/tris.md2';
                world_model_flags: EF_ROTATE;
             view_model       : nil;
{ icon }        icon             : 'k_datacd';
{ pickup}   pickup_name      : 'Data CD';
{ width }   count_width      : 2;
      quantity         : 0;
      ammo             : nil;
      flags            : IT_STAY_COOP or IT_KEY;
      weapmodel        : 0;
      info             : nil;
           tag              : 0;
{ precache }    precaches        : '';


   ),

{QUAKED key_power_cube (0 .5 .8) (-16 -16 -16) (16 16 16) TRIGGER_SPAWN NO_TOUCH
warehouse circuits
}
       (
                classname        : 'key_power_cube';
           pickup           : Pickup_Key;
           use              : nil;
             drop             : Drop_General;
           weaponthink      : nil;
           pickup_sound     : 'items/pkup.wav';
           world_model      : 'models/items/keys/power/tris.md2';
                world_model_flags: EF_ROTATE;
             view_model       : nil;
{ icon }        icon             : 'k_powercube';
{ pickup}   pickup_name      : 'Power Cube';
{ width }   count_width      : 2;
      quantity         : 0;
      ammo             : nil;
      flags            : IT_STAY_COOP or IT_KEY;
      weapmodel        : 0;
      info             : nil;
           tag              : 0;
{ precache }    precaches        : '';

      
   ),

{QUAKED key_pyramid (0 .5 .8) (-16 -16 -16) (16 16 16)
key for the entrance of jail3
}
   (
                classname        : 'key_pyramid';
           pickup           : Pickup_Key;
           use              : nil;
             drop             : Drop_General;
           weaponthink      : nil;
           pickup_sound     : 'items/pkup.wav';
           world_model      : 'models/items/keys/pyramid/tris.md2';
                world_model_flags: EF_ROTATE;
             view_model       : nil;
{ icon }        icon             : 'k_pyramid';
{ pickup}   pickup_name      : 'Pyramid Key';
{ width }   count_width      : 2;
      quantity         : 0;
      ammo             : nil;
      flags            : IT_STAY_COOP or IT_KEY;
      weapmodel        : 0;
      info             : nil;
           tag              : 0;
{ precache }    precaches        : '';

        ),

{QUAKED key_data_spinner (0 .5 .8) (-16 -16 -16) (16 16 16)
key for the city computer
}
   (
                classname        : 'key_data_spinner';
           pickup           : Pickup_Key;
           use              : nil;
             drop             : Drop_General;
           weaponthink      : nil;
           pickup_sound     : 'items/pkup.wav';
           world_model      : 'models/items/keys/spinner/tris.md2';
                world_model_flags: EF_ROTATE;
             view_model       : nil;
{ icon }        icon             : 'k_dataspin';
{ pickup}   pickup_name      : 'Data Spinner';
{ width }   count_width      : 2;
      quantity         : 0;
      ammo             : nil;
      flags            : IT_STAY_COOP or IT_KEY;
      weapmodel        : 0;
      info             : nil;
           tag              : 0;
{ precache }    precaches        : '';
       
   ),

{QUAKED key_pass (0 .5 .8) (-16 -16 -16) (16 16 16)
security pass for the security level
}
   (
                classname        : 'key_pass';
           pickup           : Pickup_Key;
           use              : nil;
             drop             : Drop_General;
           weaponthink      : nil;
           pickup_sound     : 'items/pkup.wav';
           world_model      : 'models/items/keys/pass/tris.md2';
                world_model_flags: EF_ROTATE;
             view_model       : nil;
{ icon }        icon             : 'k_security';
{ pickup}   pickup_name      : 'Security Pass';
{ width }   count_width      : 2;
      quantity         : 0;
      ammo             : nil;
      flags            : IT_STAY_COOP or IT_KEY;
      weapmodel        : 0;
      info             : nil;
           tag              : 0;
{ precache }    precaches        : '';

   ),

{QUAKED key_blue_key (0 .5 .8) (-16 -16 -16) (16 16 16)
normal door key - blue
}
   (
                classname        : 'key_blue_key';
           pickup           : Pickup_Key;
           use              : nil;
             drop             : Drop_General;
           weaponthink      : nil;
           pickup_sound     : 'items/pkup.wav';
           world_model      : 'models/items/keys/key/tris.md2';
                world_model_flags: EF_ROTATE;
             view_model       : nil;
{ icon }        icon             : 'k_bluekey';
{ pickup}   pickup_name      : 'Blue Key';
{ width }   count_width      : 2;
      quantity         : 0;
      ammo             : nil;
      flags            : IT_STAY_COOP or IT_KEY;
      weapmodel        : 0;
      info             : nil;
           tag              : 0;
{ precache }    precaches        : '';

   ),

{QUAKED key_red_key (0 .5 .8) (-16 -16 -16) (16 16 16)
normal door key - red
}
   (
                classname        : 'key_red_key';
           pickup           : Pickup_Key;
           use              : nil;
             drop             : Drop_General;
           weaponthink      : nil;
           pickup_sound     : 'items/pkup.wav';
           world_model      : 'models/items/keys/red_key/tris.md2';
                world_model_flags: EF_ROTATE;
             view_model       : nil;
{ icon }        icon             : 'k_redkey';
{ pickup}   pickup_name      : 'Red Key';
{ width }   count_width      : 2;
      quantity         : 0;
      ammo             : nil;
      flags            : IT_STAY_COOP or IT_KEY;
      weapmodel        : 0;
      info             : nil;
           tag              : 0;
{ precache }    precaches        : '';
   
   ),

{QUAKED key_commander_head (0 .5 .8) (-16 -16 -16) (16 16 16)
tank commander's head
}
       (
                classname        : 'key_commander_head';
           pickup           : Pickup_Key;
           use              : nil;
             drop             : Drop_General;
           weaponthink      : nil;
           pickup_sound     : 'items/pkup.wav';
           world_model      : 'models/monsters/commandr/head/tris.md2';
                world_model_flags: EF_GIB;
             view_model       : nil;
{ icon }        icon             : 'k_comhead';
{ pickup}   pickup_name      : 'Commander Head';
{ width }   count_width      : 2;
      quantity         : 0;
      ammo             : nil;
      flags            : IT_STAY_COOP or IT_KEY;
      weapmodel        : 0;
      info             : nil;
           tag              : 0;
{ precache }    precaches        : '';

   ),

{QUAKED key_airstrike_target (0 .5 .8) (-16 -16 -16) (16 16 16)
tank commander's head
}
       (
                classname        : 'key_airstrike_target';
           pickup           : Pickup_Key;
           use              : nil;
             drop             : Drop_General;
           weaponthink      : nil;
           pickup_sound     : 'items/pkup.wav';
           world_model      : 'models/items/keys/target/tris.md2';
                world_model_flags: EF_ROTATE;
             view_model       : nil;
{ icon }        icon             : 'i_airstrike';
{ pickup}   pickup_name      : 'Airstrike Marker';
{ width }   count_width      : 2;
      quantity         : 0;
      ammo             : nil;
      flags            : IT_STAY_COOP or IT_KEY;
      weapmodel        : 0;
      info             : nil;
           tag              : 0;
{ precache }    precaches        : '';

   ),

   (
                classname        : nil;
           pickup           : Pickup_Health;
           use              : nil;
             drop             : nil;
           weaponthink      : nil;
           pickup_sound     : 'items/pkup.wav';
           world_model      : nil;
                world_model_flags: 0;
             view_model       : nil;
{ icon }        icon             : 'i_health';
{ pickup}   pickup_name      : 'Health';
{ width }   count_width      : 3;
      quantity         : 0;
      ammo             : nil;
      flags            : 0;
      weapmodel        : 0;
      info             : nil;
           tag              : 0;
{ precache }    precaches        : 'items/s_health.wav items/n_health.wav items/l_health.wav items/m_health.wav';

   ),

   // end of list marker
   (
        //nil
        )
 );


implementation

uses
  g_cmds,
  g_utils,
  Cpas, g_main, game_add, q_shared_add, g_local_add;



//===================================

{
========
GetItemByIndex
========
}
function GetItemByIndex(index: Integer):GItem_p;
begin
  Result := nil;
  if (index = 0) or (index >= game.num_items) then exit;
  result := @itemlist[index];
end;


{
========
FindItemByClassname

========
}
function FindItemByClassname(classname: pchar):GItem_p;
var i:Integer;
 It: GItem_p;
begin
for i := 0 to game.num_items - 1 do begin
 it := @itemlist[i];
 if it^.classname = '' then continue;
 //if (CompareText(it^.classname, classname)) = 0 then begin
  if Q_stricmp(it^.classname, classname) = 0 then
  begin
   Result := it;
   exit;
 end;
end;

result := nil;
end;

{
========
FindItem

========
}
function FindItem(pickup_name: pchar):GItem_p;
var
  i:Integer;
  It: GItem_p;
begin
  for i := 0 to game.num_items - 1 do begin
    it := @itemlist[i];
    if it^.pickup_name = '' then continue;
    if (Q_stricmp(it^.pickup_name, pickup_name)) = 0   then
    begin
      Result := it;
      exit;
    end;
  end;
  
  Result := Nil;
end;
//===================================
procedure DoRespawn(Ent:edict_p); cdecl;
var
 Master: edict_p;
 Count, Choice: Integer;
begin
if (ent^.team <> nil) then
begin // pick a random team member
 master := ent^.teammaster;

 count := 0;
 ent := master;
 while ent <> nil do
 begin
  ent := ent^.chain; Inc(count);
 end;
 choice := rand() mod count;

 count := 0; ent := master;
 while count < choice do
 begin
  ent := ent^.chain; Inc(count);
 end;
end;

ent^.svflags :=ent^.svflags and not(SVF_NOCLIENT);
ent^.solid := SOLID_TRIGGER;
gi.linkentity (ent);

// send an effect
ent^.s.event := EV_ITEM_RESPAWN;
end;

procedure SetRespawn(Ent:edict_p; Delay: Single);
begin
ent^.flags := ent^.flags or FL_RESPAWN;
ent^.svflags := ent^.svflags or SVF_NOCLIENT;
ent^.solid := SOLID_NOT;
ent^.nextthink := level.time + delay;
ent^.think := DoRespawn;
gi.linkentity (ent);
end;


//===================================


function Pickup_Powerup (Ent, Other:edict_p): QBoolean; cdecl;
var Quantity: Integer;
begin
// Check quantity: 3.20
Result := false;
Quantity := other^.client^.pers.inventory[ITEM_INDEX(ent^.item)];
if ((skill^.value = 1) and (quantity >= 2)) or ((skill^.value >= 2) and (quantity >= 1)) then Exit;
if (coop^.value <> 0) and ((ent^.item^.flags and IT_STAY_COOP) > 0)
     and (quantity > 0) then exit;

Inc(other^.client^.pers.inventory[ITEM_INDEX(ent^.item)]);

if (deathmatch^.value <> 0) then begin
 if (ent^.spawnflags and DROPPED_ITEM) = 0 then
  SetRespawn (ent, ent^.item^.quantity);
 if ((round(dmflags^.value) and DF_INSTANT_ITEMS) > 0) or (@ent^.item^.use = @Use_Quad) and ((ent^.spawnflags and DROPPED_PLAYER_ITEM) > 0) then
 begin
  if (@ent^.item^.use = @Use_Quad) and ((ent^.spawnflags and DROPPED_PLAYER_ITEM) > 0) then
   quad_drop_timeout_hack := round((ent^.nextthink - level.time) / FRAMETIME);
  // use it immediately
  ent^.item^.use (other, ent^.item);
 end;
end;

Result := true;
end;

procedure Drop_General(Ent:edict_p;Item: GItem_p); cdecl;
begin
Drop_Item(ent, item);
Dec(ent^.client^.pers.inventory[ITEM_INDEX(item)]);
ValidateSelectedItem (ent);
end;

//===================================

function Pickup_Adrenaline (Ent, Other:edict_p): QBoolean; cdecl;
begin
if (deathmatch^.value=0) then Inc(other^.max_health);
if (other^.health < other^.max_health) then other^.health := other^.max_health;

if (ent^.spawnflags and DROPPED_ITEM= 0) and (deathmatch^.value<>0) then
 SetRespawn (ent, ent^.item^.quantity);

Result := True;
end;

function Pickup_AncientHead (Ent, Other:edict_p): QBoolean; cdecl;
begin
Inc(other^.max_health, 2);

if (ent^.spawnflags and DROPPED_ITEM = 0) and (deathmatch^.value<>0) then
 SetRespawn (ent, ent^.item^.quantity);

Result := True;
end;

function Pickup_Bandolier (Ent, Other:edict_p): QBoolean; cdecl;
var item: GItem_p;
    Index:Integer;
begin
if (other^.client^.pers.max_bullets < 250) then other^.client^.pers.max_bullets := 250;
if (other^.client^.pers.max_shells < 150) then other^.client^.pers.max_shells := 150;
if (other^.client^.pers.max_cells < 250) then other^.client^.pers.max_cells := 250;
if (other^.client^.pers.max_slugs < 75) then other^.client^.pers.max_slugs := 75;

item := FindItem('Bullets');
if item <> nil then
begin
 index := ITEM_INDEX(item);
 Inc(other^.client^.pers.inventory[index], item^.quantity);
 if (other^.client^.pers.inventory[index] > other^.client^.pers.max_bullets) then
  other^.client^.pers.inventory[index] := other^.client^.pers.max_bullets;
end;

item := FindItem('Shells');
if item <> nil then begin
 index := ITEM_INDEX(item);
 Inc(other^.client^.pers.inventory[index], item^.quantity);
 if (other^.client^.pers.inventory[index] > other^.client^.pers.max_shells) then
  other^.client^.pers.inventory[index] := other^.client^.pers.max_shells;
end;

if (ent^.spawnflags and DROPPED_ITEM=0) and (deathmatch^.value<>0) then

 SetRespawn (ent, ent^.item^.quantity);

Result := True;
end;

function Pickup_Pack (Ent, Other:edict_p): QBoolean; cdecl;
var item: GItem_p;
    Index:Integer;
begin
if (other^.client^.pers.max_bullets < 300) then other^.client^.pers.max_bullets := 300;
if (other^.client^.pers.max_shells < 200) then other^.client^.pers.max_shells := 200;
if (other^.client^.pers.max_rockets < 100) then other^.client^.pers.max_rockets := 100;
if (other^.client^.pers.max_grenades < 100) then other^.client^.pers.max_grenades := 100;
if (other^.client^.pers.max_cells < 300) then other^.client^.pers.max_cells := 300;
if (other^.client^.pers.max_slugs < 100) then other^.client^.pers.max_slugs := 100;

item := FindItem('Bullets');
if item <> nil then
begin
 index := ITEM_INDEX(item);
 Inc(other^.client^.pers.inventory[index], item^.quantity);
 if (other^.client^.pers.inventory[index] > other^.client^.pers.max_bullets) then
  other^.client^.pers.inventory[index] := other^.client^.pers.max_bullets;
end;

item := FindItem('Shells');
if item <> nil then
begin
 index := ITEM_INDEX(item);
 Inc(other^.client^.pers.inventory[index], item^.quantity);
 if (other^.client^.pers.inventory[index] > other^.client^.pers.max_shells) then
  other^.client^.pers.inventory[index] := other^.client^.pers.max_shells;
end;

item := FindItem('Cells');
if item <> nil then
begin
 index := ITEM_INDEX(item);
 Inc(other^.client^.pers.inventory[index], item^.quantity);
 if (other^.client^.pers.inventory[index] > other^.client^.pers.max_cells) then
  other^.client^.pers.inventory[index] := other^.client^.pers.max_cells;
end;

if item <> nil then
begin
 item := FindItem('Grenades');
 index := ITEM_INDEX(item);
 Inc(other^.client^.pers.inventory[index], item^.quantity);
 if (other^.client^.pers.inventory[index] > other^.client^.pers.max_grenades) then
  other^.client^.pers.inventory[index] := other^.client^.pers.max_grenades;
end;

item := FindItem('Rockets');
if item <> nil then
begin
 index := ITEM_INDEX(item);
 Inc(other^.client^.pers.inventory[index], item^.quantity);
 if (other^.client^.pers.inventory[index] > other^.client^.pers.max_rockets) then
  other^.client^.pers.inventory[index] := other^.client^.pers.max_rockets;
end;

item := FindItem('Slugs');
if item <> nil then
begin
 index := ITEM_INDEX(item);
 Inc(other^.client^.pers.inventory[index], item^.quantity);
 if (other^.client^.pers.inventory[index] > other^.client^.pers.max_slugs) then
  other^.client^.pers.inventory[index] := other^.client^.pers.max_slugs;
end;

if (ent^.spawnflags and DROPPED_ITEM = 0) and (deathmatch^.value<>0) then
 SetRespawn (ent, ent^.item^.quantity);

Result := True;
end;

//===================================

procedure Use_Quad (ent:edict_p; item:gitem_p); 
var
  timeout:integer;
begin


   dec(ent^.client^.pers.inventory[ITEM_INDEX(item)]);
   ValidateSelectedItem (ent);

   if (quad_drop_timeout_hack<>0) then
   begin
      timeout := quad_drop_timeout_hack;
      quad_drop_timeout_hack := 0;
   end
   else
   begin
     timeout := 300;
   end;

   if (ent^.client^.quad_framenum > level.framenum)  then
      ent^.client^.quad_framenum :=ent^.client^.quad_framenum + timeout
   else
      ent^.client^.quad_framenum := level.framenum + timeout;

   gi.sound(ent, CHAN_ITEM, gi.soundindex('items/damage.wav'), 1, ATTN_NORM, 0);
end;

//===================================

procedure Use_Breather (ent:edict_p; item:gitem_p); cdecl;
begin
   dec(ent^.client^.pers.inventory[ITEM_INDEX(item)]);
   ValidateSelectedItem (ent);

   if (ent^.client^.breather_framenum > level.framenum) then
      ent^.client^.breather_framenum:=ent^.client^.breather_framenum + 300
   else
      ent^.client^.breather_framenum := level.framenum + 300;

//   gi.sound(ent, CHAN_ITEM, gi.soundindex('items/damage.wav'), 1, ATTN_NORM, 0);
end;

//===================================

procedure Use_Envirosuit(ent:edict_p;item:gitem_p); cdecl;
begin
   dec(ent^.client^.pers.inventory[ITEM_INDEX(item)]);
   ValidateSelectedItem (ent);

   if (ent^.client^.enviro_framenum > level.framenum) then
      ent^.client^.enviro_framenum := ent^.client^.enviro_framenum + 300
   else
      ent^.client^.enviro_framenum := level.framenum + 300;

//   gi.sound(ent, CHAN_ITEM, gi.soundindex('items/damage.wav'), 1, ATTN_NORM, 0);
end;

//===================================

procedure Use_Invulnerability(ent:edict_p;item: gitem_p); cdecl;
begin
   dec(ent^.client^.pers.inventory[ITEM_INDEX(item)]);
   ValidateSelectedItem (ent);

   if (ent^.client^.invincible_framenum > level.framenum) then
      ent^.client^.invincible_framenum :=ent^.client^.invincible_framenum + 300
   else
      ent^.client^.invincible_framenum := level.framenum + 300;

   gi.sound(ent, CHAN_ITEM, gi.soundindex('items/protect.wav'), 1, ATTN_NORM, 0);
end;

//===================================

procedure Use_Silencer (ent:edict_p;item: gitem_p); cdecl;
begin
   dec(ent^.client^.pers.inventory[ITEM_INDEX(item)]);
   ValidateSelectedItem (ent);
   ent^.client^.silencer_shots := ent^.client^.silencer_shots + 30;

//   gi.sound(ent, CHAN_ITEM, gi.soundindex('items/damage.wav'), 1, ATTN_NORM, 0);
end;

//===================================

function Pickup_Key (ent:edict_p;other:edict_p):qboolean; cdecl;
begin
  if (coop^.value <> 0)then
  begin
    if (strcmp(ent^.classname, 'key_power_cube') = 0) then
    begin
      if (other^.client^.pers.power_cubes and ((ent^.spawnflags and $0000ff00) shr 8)) <> 0 then
      begin
        Result := False;
        Exit;
      end;
      inc(other^.client^.pers.inventory[ITEM_INDEX(ent^.item)]);
      other^.client^.pers.power_cubes := other^.client^.pers.power_cubes or ((ent^.spawnflags and $0000ff00) shr 8);
    end
    else
    begin
      if (other^.client^.pers.inventory[ITEM_INDEX(ent^.item)] <> 0) then
      begin
        Result := False;
        Exit;
      end;
      other^.client^.pers.inventory[ITEM_INDEX(ent^.item)] := 1;
    end;

    Result := True;
    Exit;
  end;
  inc(other^.client^.pers.inventory[ITEM_INDEX(ent^.item)]);
  Result := True;
end;

//===================================

function Add_Ammo (ent:edict_p;item: gitem_p; count:integer):qboolean;
var
  index:integer;
  max:integer;
begin
     result:= true;

   if (ent^.client=nil)  then
        begin
     result:= false;
          exit;
        end;
   if (item^.tag = ord(AMMO_BULLETS)) then
      max := ent^.client^.pers.max_bullets
   else if (item^.tag = ord(AMMO_SHELLS)) then
      max := ent^.client^.pers.max_shells
   else if (item^.tag = ord(AMMO_ROCKETS))  then
      max := ent^.client^.pers.max_rockets
   else if (item^.tag = ord(AMMO_GRENADES)) then
      max := ent^.client^.pers.max_grenades
   else if (item^.tag = ord(AMMO_CELLS))  then
      max := ent^.client^.pers.max_cells
   else if (item^.tag = ord(AMMO_SLUGS))  then
      max := ent^.client^.pers.max_slugs
   else
              begin
      result:= false;
                exit;
              end;

   index := ITEM_INDEX(item);

   if (ent^.client^.pers.inventory[index] = max) then
                begin
            result:= false;
                 exit;
                end;

   ent^.client^.pers.inventory[index] :=ent^.client^.pers.inventory[index]+  count;

   if (ent^.client^.pers.inventory[index] > max) then
      ent^.client^.pers.inventory[index] := max;


end;

function Pickup_Ammo (ent:edict_p;other:edict_p): qboolean; cdecl;
var
  oldcount:integer;
  count:integer;
  weapon:qboolean;

begin
    weapon := (ent^.item^.flags and IT_WEAPON<>0);
   if ( weapon) and (round(dmflags^.value) and DF_INFINITE_AMMO <>0 ) then
      count := 1000
   else if (ent^.count<>0)  then
      count := ent^.count
   else
      count := ent^.item^.quantity;

   oldcount := other^.client^.pers.inventory[ITEM_INDEX(ent^.item)];

   if not(Add_Ammo (other, ent^.item, count)) then
             begin
      result:= false;
                exit;
                end;
   if (weapon )and (oldcount<>0) then
   begin
  if (other^.client^.pers.weapon <> ent^.item) and
  ( deathmatch^.value=0) or (other^.client^.pers.weapon = FindItem('blaster') ) then
     other^.client^.newweapon := ent^.item;
   end;

   if (ent^.spawnflags and (DROPPED_ITEM or DROPPED_PLAYER_ITEM)=0) and (deathmatch^.value<>0)  then
      SetRespawn (ent, 30);

   result:= true;
end;

procedure Drop_Ammo(ent:edict_p;item: gitem_p); cdecl;
var
  dropped:edict_p;
  index:integer;
begin


   index := ITEM_INDEX(item);
   dropped := Drop_Item (ent, item);
   if (ent^.client^.pers.inventory[index] >= item^.quantity)   then
      dropped^.count := item^.quantity
   else
      dropped^.count := ent^.client^.pers.inventory[index];

   if (ent^.client^.pers.weapon<>nil) and
      (ent^.client^.pers.weapon^.tag = ord(AMMO_GRENADES)) and
          (item^.tag = ord(AMMO_GRENADES)) and
      (ent^.client^.pers.inventory[index] - dropped^.count <= 0) then
               begin
       gi.cprintf (ent, PRINT_HIGH, 'Can t drop current weapon'#10);
            G_FreeEdict(dropped);
            exit;
            end;

   ent^.client^.pers.inventory[index] :=ent^.client^.pers.inventory[index] - dropped^.count;
   ValidateSelectedItem (ent);
end;


//===================================

procedure MegaHealth_think (self:edict_p); cdecl;
begin
   if (self^.owner^.health > self^.owner^.max_health) then
   begin
      self^.nextthink := level.time + 1;
      self^.owner^.health :=self^.owner^.health - 1;
      exit;
   end;

   if (self^.spawnflags and DROPPED_ITEM=0) and (deathmatch^.value<>0)  then
      SetRespawn (self, 20)
   else
       G_FreeEdict (self);
end;

function Pickup_Health (ent:edict_p;other:edict_p):qboolean; cdecl;
begin
   if (ent^.style and HEALTH_IGNORE_MAX=0)   then
      if (other^.health >= other^.max_health)  then
                       begin
                result:= false;
                          exit;
                        end;
   other^.health:=other^.health + ent^.count;

   if (ent^.style and HEALTH_IGNORE_MAX=0)  then
   begin
      if (other^.health > other^.max_health)then
         other^.health := other^.max_health;
   end;

   if (ent^.style and HEALTH_TIMED<>0)   then
   begin
      ent^.think := MegaHealth_think;
      ent^.nextthink := level.time + 5;
      ent^.owner := other;
      ent^.flags :=ent^.flags or FL_RESPAWN;
      ent^.svflags :=ent^.svflags or SVF_NOCLIENT;
      ent^.solid := SOLID_NOT;
   end
   else
   begin
      if (ent^.spawnflags and DROPPED_ITEM=0) and (deathmatch^.value<>0) then
         SetRespawn (ent, 30);
   end;

   result:=true;
end;

//===================================

function ArmorIndex (ent:edict_p):integer;
begin
         result:= 0;
   if (ent^.client=nil) then
      exit;

   if (ent^.client^.pers.inventory[jacket_armor_index] > 0) then
              begin
            result:= jacket_armor_index;
                 exit;
                end;
   if (ent^.client^.pers.inventory[combat_armor_index] > 0) then
                begin
       result:= combat_armor_index;
                 exit;
                end;
   if (ent^.client^.pers.inventory[body_armor_index] > 0) then
               begin
       result:= body_armor_index;
                 exit;
                end;

end;

function Pickup_Armor (ent:edict_p;other: edict_p):qboolean; cdecl;
var
  old_armor_index:integer;
  oldinfo:gitem_armor_p;
  newinfo:gitem_armor_p;
  newcount:integer;
  salvage:single;
  salvagecount:integer;
begin
   result:=true;
   // get info on new armor
   newinfo := gitem_armor_p(ent^.item^.info);

   old_armor_index := ArmorIndex (other);

   // handle armor shards specially
   if (ent^.item^.tag = ARMOR_SHARD) then
   begin
      if (old_armor_index=0)  then
         other^.client^.pers.inventory[jacket_armor_index] := 2
      else
         other^.client^.pers.inventory[old_armor_index] :=other^.client^.pers.inventory[old_armor_index] + 2;
   end

   // if player has no armor, just use it
   else if (old_armor_index=0) then
   begin
      other^.client^.pers.inventory[ITEM_INDEX(ent^.item)] := newinfo^.base_count;
   end

   // use the better armor
   else
   begin
      // get info on old armor
      if (old_armor_index = jacket_armor_index)  then
         oldinfo := @jacketarmor_info
      else if (old_armor_index = combat_armor_index)  then
         oldinfo := @combatarmor_info
      else // (old_armor_index = body_armor_index)
         oldinfo := @bodyarmor_info;

      if (newinfo^.normal_protection > oldinfo^.normal_protection) then
      begin
         // calc new armor values
         salvage := oldinfo^.normal_protection / newinfo^.normal_protection;
         salvagecount := round(salvage) * other^.client^.pers.inventory[old_armor_index];
         newcount := newinfo^.base_count + salvagecount;
         if (newcount > newinfo^.max_count)   then
            newcount := newinfo^.max_count;

         // zero count of old armor so it goes away
         other^.client^.pers.inventory[old_armor_index] := 0;

         // change armor to new item with computed value
         other^.client^.pers.inventory[ITEM_INDEX(ent^.item)] := newcount;
      end
      else
      begin
         // calc new armor values
         salvage := newinfo^.normal_protection / oldinfo^.normal_protection;
         salvagecount := round(salvage )* newinfo^.base_count;
         newcount := other^.client^.pers.inventory[old_armor_index] + salvagecount;
         if (newcount > oldinfo^.max_count)  then
            newcount := oldinfo^.max_count;

         // if we're already maxed out then we don't need the new armor
         if (other^.client^.pers.inventory[old_armor_index] >= newcount)  then
                              begin
             result:= false;
                                 exit;
                                end;
         // update current armor value
         other^.client^.pers.inventory[old_armor_index] := newcount;
      end;
   end;

   if (ent^.spawnflags and DROPPED_ITEM=0) and (deathmatch^.value<>0)   then
      SetRespawn (ent, 20);

   result:=true;
end;

//===================================

function PowerArmorType(ent:edict_p):integer;
begin
  Result := POWER_ARMOR_NONE;

  if (ent^.client = nil) then
  begin
    Result := POWER_ARMOR_NONE;  { 2003-05-01: NOTE (SP):  Could just be exit }
    Exit;
  end;

  if (ent^.flags and FL_POWER_ARMOR) = 0 then
  begin
    Result := POWER_ARMOR_NONE;  { 2003-05-01: NOTE (SP):  Could just be exit }
    Exit;
  end;

  if (ent^.client^.pers.inventory[power_shield_index] > 0) then
  begin
    Result := POWER_ARMOR_SHIELD;
    Exit;
  end;

  if (ent^.client^.pers.inventory[power_screen_index] > 0) then
  begin
    Result := POWER_ARMOR_SCREEN;
    Exit;
  end;
end;

procedure Use_PowerArmor(ent:edict_p;item: gitem_p); cdecl;
var
   index:integer;
begin


   if (ent^.flags and FL_POWER_ARMOR<>0) then
   begin
      ent^.flags :=ent^.flags and not(FL_POWER_ARMOR);
      gi.sound(ent, CHAN_AUTO, gi.soundindex('misc/power2.wav'), 1, ATTN_NORM, 0);
   end
   else
   begin
      index := ITEM_INDEX(FindItem('cells'));
      if (ent^.client^.pers.inventory[index]=0)  then
      begin
         gi.cprintf (ent, PRINT_HIGH, 'No cells for power armor.'#10);
         exit;
      end;
      ent^.flags :=ent^.flags or FL_POWER_ARMOR;
      gi.sound(ent, CHAN_AUTO, gi.soundindex('misc/power1.wav'), 1, ATTN_NORM, 0);
   end;
end;

function Pickup_PowerArmor (ent:edict_p;other:edict_p):qboolean; cdecl;
var
  quantity:integer;
begin


   quantity := other^.client^.pers.inventory[ITEM_INDEX(ent^.item)];

   inc(other^.client^.pers.inventory[ITEM_INDEX(ent^.item)]);

   if (deathmatch^.value<>0)  then
   begin
      if (ent^.spawnflags and DROPPED_ITEM=0) then
         SetRespawn (ent, ent^.item^.quantity);
      // auto-use for DM only if we didn't already have one
      if (quantity<>0) then
         ent^.item^.use (other, ent^.item);
   end;

   result:= true;
end;

procedure Drop_PowerArmor(ent:edict_p;item: gitem_p); cdecl;
begin
  if (ent^.flags and FL_POWER_ARMOR<>0) and (ent^.client^.pers.inventory[ITEM_INDEX(item)] = 1) then
      Use_PowerArmor (ent, item);
   Drop_General (ent, item);
end;

//===================================

{
========
Touch_Item
========
}
procedure Touch_Item (ent:edict_p;other:edict_p;plane: cplane_p;surf: csurface_p);
var
  taken:qboolean;
begin


   if (other^.client=nil) then
          exit;
   if (other^.health < 1) then
      exit;      // dead people can't pickup
   if (@ent^.item^.pickup=nil)  then
      exit;      // not a grabbable item?

   taken := ent^.item^.pickup(ent, other);

   if (taken) then
   begin
      // flash the screen
      other^.client^.bonus_alpha := 0.25;

      // show icon and name on status bar
      other^.client^.ps.stats[STAT_PICKUP_ICON] := gi.imageindex(ent^.item^.icon);
      other^.client^.ps.stats[STAT_PICKUP_STRING] := CS_ITEMS+ITEM_INDEX(ent^.item);
      other^.client^.pickup_msg_time := level.time + 3.0;

      // change selected item
      if (@ent^.item^.use<>nil) then
       other^.client^.pers.selected_item := ITEM_INDEX(ent^.item);
                 other^.client^.ps.stats[STAT_SELECTED_ITEM] := ITEM_INDEX(ent^.item);

      if (@ent^.item^.pickup = @Pickup_Health)  then
      begin
         if (ent^.count = 2)  then
            gi.sound(other, CHAN_ITEM, gi.soundindex('items/s_health.wav'), 1, ATTN_NORM, 0)
         else if (ent^.count = 10)then
            gi.sound(other, CHAN_ITEM, gi.soundindex('items/n_health.wav'), 1, ATTN_NORM, 0)
         else if (ent^.count = 25)then
            gi.sound(other, CHAN_ITEM, gi.soundindex('items/l_health.wav'), 1, ATTN_NORM, 0)
         else // (ent^.count = 100)
            gi.sound(other, CHAN_ITEM, gi.soundindex('items/m_health.wav'), 1, ATTN_NORM, 0);
      end
      else if (ent^.item^.pickup_sound<>nil) then
      begin
       gi.sound(other, CHAN_ITEM, gi.soundindex(ent^.item^.pickup_sound), 1, ATTN_NORM, 0);
      end;
   end;

   if (ent^.spawnflags and ITEM_TARGETS_USED=0) then
   begin
      G_UseTargets (ent, other);
      ent^.spawnflags :=ent^.spawnflags or ITEM_TARGETS_USED;
   end;

   if not(taken)  then
      exit;

   if not((coop^.value<>0) and (ent^.item^.flags and IT_STAY_COOP<>0)) or (ent^.spawnflags and (DROPPED_ITEM or DROPPED_PLAYER_ITEM)<>0) then
   begin
      if (ent^.flags and FL_RESPAWN<>0)  then
         ent^.flags :=ent^.flags and not (FL_RESPAWN)
      else
         G_FreeEdict (ent);
   end;
end;

//===================================

procedure drop_temp_touch (ent:edict_p;other:edict_p;plane: cplane_p;surf:csurface_p); cdecl;
begin
   if (other = ent^.owner) then
      exit;

   Touch_Item (ent, other, plane, surf);
end;

procedure drop_make_touchable (ent:edict_p); cdecl;
begin
   ent^.touch := Touch_Item;
   if (deathmatch^.value<>0)  then
   begin
      ent^.nextthink := level.time + 29;
      ent^.think := G_FreeEdict;
   end;
end;

function Drop_Item (ent:edict_p;item:gitem_p):edict_p;
var
 dropped: edict_p;
 forwardd, right:vec3_t;
 offset:vec3_t;
 trace:   trace_t;
begin


   dropped := G_Spawn;

   dropped^.classname := item^.classname;
   dropped^.item := item;
   dropped^.spawnflags := DROPPED_ITEM;
   dropped^.s.effects := item^.world_model_flags;
   dropped^.s.renderfx := RF_GLOW;
   VectorSet (dropped^.mins, -15, -15, -15);
   VectorSet (dropped^.maxs, 15, 15, 15);
   gi.setmodel (dropped, dropped^.item^.world_model);
   dropped^.solid := SOLID_TRIGGER;
   dropped^.movetype := MOVETYPE_TOSS;
   dropped^.touch := drop_temp_touch;
   dropped^.owner := ent;

   if (ent^.client<>nil) then
   begin


      AngleVectors (ent^.client^.v_angle, @forwardd, @right, nil);
      VectorSet(offset, 24, 0, -16);
      G_ProjectSource (ent^.s.origin, offset, forwardd, right, dropped^.s.origin);
      trace := gi.trace (@ent^.s.origin, @dropped^.mins, @dropped^.maxs,
         @dropped^.s.origin, ent, CONTENTS_SOLID);
      VectorCopy (trace.endpos, dropped^.s.origin);
   end
   else
   begin
      AngleVectors (ent^.s.angles, @forwardd, @right, nil);
      VectorCopy (ent^.s.origin, dropped^.s.origin);
   end;

   VectorScale (forwardd, 100, dropped^.velocity);
   dropped^.velocity[2] := 300;

   dropped^.think := drop_make_touchable;
   dropped^.nextthink := level.time + 1;

   gi.linkentity (dropped);

   result:= dropped;
end;

procedure Use_Item (ent:edict_p;other:edict_p;activator:edict_p); cdecl;
begin
   ent^.svflags :=ent^.svflags and not(SVF_NOCLIENT);
   ent^.use := nil;

   if (ent^.spawnflags and ITEM_NO_TOUCH<>0) then
   begin
      ent^.solid := SOLID_BBOX;
      ent^.touch := nil;
   end
   else
   begin
      ent^.solid := SOLID_TRIGGER;
      ent^.touch := Touch_Item;
   end;

   gi.linkentity (ent);
end;

//===================================

{
========
droptofloor
========
}
procedure droptofloor (ent:edict_p); cdecl;
var
    tr:trace_t;
   dest{,temp}:vec3_t;
   v:vec3_t;//pSingle;
begin


        v := vec3_p(tv(-15,-15,-15))^;
   VectorCopy (v, ent^.mins);
   v := vec3_p(tv(15,15,15))^;
   VectorCopy (v, ent^.maxs);

   if (ent^.model<>nil) then
      gi.setmodel (ent, ent^.model)
   else
      gi.setmodel (ent, ent^.item^.world_model);
   ent^.solid := SOLID_TRIGGER;
   ent^.movetype := MOVETYPE_TOSS;  
   ent^.touch := Touch_Item;

   v := vec3_p(tv(0,0,-128))^;
   VectorAdd (ent^.s.origin, v, dest);

   tr := gi.trace (@ent^.s.origin, @ent^.mins, @ent^.maxs, @dest, ent, MASK_SOLID);
   if (tr.startsolid)   then
   begin
      gi.dprintf ('droptofloor: %s startsolid at %s'#10,ent^.classname, vtos(ent^.s.origin));
      G_FreeEdict (ent);
      exit;
   end;

   VectorCopy (tr.endpos, ent^.s.origin);

   if (ent^.team<>nil)  then
   begin
      ent^.flags :=ent^.flags and not(FL_TEAMSLAVE);
      ent^.chain := ent^.teamchain;
      ent^.teamchain := nil;

      ent^.svflags :=ent^.svflags or SVF_NOCLIENT;
      ent^.solid := SOLID_NOT;
      if (ent = ent^.teammaster) then
      begin
         ent^.nextthink := level.time + FRAMETIME;
         ent^.think := DoRespawn;
      end;
   end;

   if (ent^.spawnflags and ITEM_NO_TOUCH<>0)  then
   begin
      ent^.solid := SOLID_BBOX;
      ent^.touch := nil;
      ent^.s.effects :=ent^.s.effects and not(EF_ROTATE);
      ent^.s.renderfx :=ent^.s.renderfx and not(RF_GLOW);
   end;

   if (ent^.spawnflags and ITEM_TRIGGER_SPAWN<>0)  then
   begin
      ent^.svflags :=ent^.svflags or SVF_NOCLIENT;
      ent^.solid := SOLID_NOT;
      ent^.use := Use_Item;
   end;

   gi.linkentity (ent);
end;


{
========
PrecacheItem

Precaches all data needed for a given item.
This will be called for each item spawned in a level,
and for each item in each client's inventory.
========
}
procedure PrecacheItem (it:gitem_p);
var
  s,start:pchar;
  data:array[0..MAX_QPATH-1] of char;
  len:integer;
  ammo:   gitem_p;


begin


   if (it=nil)  then
      exit;

   if (it^.pickup_sound<>nil) then
      gi.soundindex (it^.pickup_sound);
   if (it^.world_model<>nil)  then
      gi.modelindex (it^.world_model);
   if (it^.view_model<>nil)  then
      gi.modelindex (it^.view_model);
   if (it^.icon<>nil)       then
      gi.imageindex (it^.icon);

   // parse everything for its ammo
   if (it^.ammo<>nil) and (it^.ammo[0]<>'') then
   begin
      ammo := FindItem (it^.ammo);
      if (ammo <> it) then
         PrecacheItem (ammo);
   end;

   // parse the space seperated precache string for other items
   s := it^.precaches;
   if (s=nil) or (s[0]<>'')  then
      exit;

   while (s^ <> #0) do
   begin
      start := s;
      while (s^ <> #0) and (s^ <>' ') do
         inc(s);

      len := s-start;
      if (len >= MAX_QPATH) or( len < 5)  then
         gi.error ('PrecacheItem: %s has bad precache string', it^.classname);
      memcpy (@data, start, len);
      data[len] := #0;
      if (s^ <> #0)  then
         inc(s);

      // determine type based on extension
      if (strcmp(data+len-3, 'md2')=0) then
         gi.modelindex (data)
      else if (strcmp(data+len-3, 'sp2')=0) then
         gi.modelindex (data)
      else if (strcmp(data+len-3, 'wav')=0) then
         gi.soundindex (data);
      if (strcmp(data+len-3, 'pcx')=0) then
         gi.imageindex (data);
   end;
end;

{
======
SpawnItem

Sets the clipping size and plants the object on the floor.

Items can't be immediately dropped to floor, because they might
be on an entity that hasn't spawned yet.
======
}
procedure SpawnItem (ent:edict_p;item: gitem_p);
begin
   PrecacheItem (item);

   if (ent^.spawnflags<>0)  then
   begin
      if (strcmp(ent^.classname, 'key_power_cube') <> 0)  then
      begin
         ent^.spawnflags := 0;
         gi.dprintf('%s at %s has invalid spawnflags set'#10, ent^.classname, vtos(ent^.s.origin));
      end;
   end;

   // some items will be prevented in deathmatch
   if (deathmatch^.value<>0)   then
   begin
      if ( round(dmflags^.value) and DF_NO_ARMOR <>0)  then
      begin
             if (@item^.pickup = @Pickup_Armor) or (@item^.pickup = @Pickup_PowerArmor)  then
         begin
            G_FreeEdict (ent);
            exit;
         end;
      end;
      if ( round(dmflags^.value) and DF_NO_ITEMS <>0)   then
      begin
         if (@item^.pickup = @Pickup_Powerup)  then
         begin
            G_FreeEdict (ent);
            exit;
         end;
      end;
      if ( round(dmflags^.value) and DF_NO_HEALTH <>0)  then
      begin
         if (@item^.pickup = @Pickup_Health) or (@item^.pickup = @Pickup_Adrenaline )or (@item^.pickup = @Pickup_AncientHead)  then
         begin
            G_FreeEdict (ent);
            exit;
         end;
      end;
      if ( round(dmflags^.value) and DF_INFINITE_AMMO <>0)    then
      begin
         if ( item^.flags = IT_AMMO) or (strcmp(ent^.classname, 'weapon_bfg') = 0 )  then
         begin
            G_FreeEdict (ent);
            exit;
         end;
      end;
   end;

   if (coop^.value<>0) and (strcmp(ent^.classname, 'key_power_cube') = 0) then
   begin
      ent^.spawnflags :=ent^.spawnflags or  (1 shl (8 + level.power_cubes));
      inc(level.power_cubes);
   end;

   // don't let them drop items that stay in a coop game
   if (coop^.value<>0) and (item^.flags and IT_STAY_COOP<>0) then
   begin
      item^.drop := nil;
   end;

   ent^.item := item;
   ent^.nextthink := level.time + 2 * FRAMETIME;    // items start after other solids
   ent^.think := droptofloor;
   ent^.s.effects := item^.world_model_flags;
   ent^.s.renderfx := RF_GLOW;
   if (ent^.model<>nil)   then
      gi.modelindex (ent^.model);
end;
(*
//===================================
 type  gitem_p =record
    classname: PChar;  // spawning name
    pickup: BoolFunc_2edict_s;
    use: Proc_edit_s__gitem_s;
    drop: Proc_edit_s__gitem_s;
    weaponthink: Proc_edit_s;
    pickup_sound: PChar;
    world_model: PChar;
    world_model_flags: integer;
    view_model: PChar;

    // client side info
    icon: PChar;
    pickup_name: PChar;   // for printing on pickup
    count_width: integer; // number of digits to display by icon

    quantity: integer;   // for ammo how much, for weapons how much is used per shot
    ammo: PChar;    // for weapons
    flags: integer;   // IT_* flags

    weapmodel: integer;   // weapon model index (for weapons)

    info: Pointer;
    tag: integer;

    precaches: PChar; // string of all models, sounds, and images this item will use *)


{function itemlist: gitem_arr;
begin
  result := itemlist_;
end;}


//#define   ITEM_INDEX(x) ((x)-itemlist)

function ITEM_INDEX(x:GItem_p):integer;
begin
  result:=(integer(x)-integer(@itemlist)) div SizeOf(gitem_t);
end;


{QUAKED item_health (.3 .3 1) (-16 -16 -16) (16 16 16)
}
procedure SP_item_health (self:edict_p);
begin
   if ( deathmatch^.value<>0) and (round(dmflags^.value) and DF_NO_HEALTH<>0)   then
   begin
      G_FreeEdict(self);
      exit;
   end;

   self^.model := 'models/items/healing/medium/tris.md2';
   self^.count := 10;
   SpawnItem (self, FindItem ('Health'));
   gi.soundindex ('items/n_health.wav');
end;

{QUAKED item_health_small (.3 .3 1) (-16 -16 -16) (16 16 16)
}
procedure SP_item_health_small (self:edict_p);
begin
   if ( deathmatch^.value<>0) and (round(dmflags^.value) and DF_NO_HEALTH<>0)    then
   begin
      G_FreeEdict(self);
      exit;
   end;

   self^.model := 'models/items/healing/stimpack/tris.md2';
   self^.count := 2;
   SpawnItem (self, FindItem ('Health'));
   self^.style := HEALTH_IGNORE_MAX;
   gi.soundindex ('items/s_health.wav');
end;

{QUAKED item_health_large (.3 .3 1) (-16 -16 -16) (16 16 16)
}
procedure SP_item_health_large (self:edict_p);
begin
   if ( deathmatch^.value<>0) and (round(dmflags^.value) and DF_NO_HEALTH<>0)   then
   begin
      G_FreeEdict (self);
      exit;
   end;

   self^.model := 'models/items/healing/large/tris.md2';
   self^.count := 25;
   SpawnItem (self, FindItem ('Health'));
   gi.soundindex ('items/l_health.wav');
end;

{QUAKED item_health_mega (.3 .3 1) (-16 -16 -16) (16 16 16)
}
procedure SP_item_health_mega(self:edict_p);
begin
   if ( deathmatch^.value<>0) and (round(dmflags^.value) and DF_NO_HEALTH<>0 )   then
   begin
      G_FreeEdict(self);
      exit;
   end;

   self^.model := 'models/items/mega_h/tris.md2';
   self^.count := 100;
   SpawnItem (self, FindItem ('Health'));
   gi.soundindex ('items/m_health.wav');
   self^.style := HEALTH_IGNORE_MAX or HEALTH_TIMED;
end;


procedure InitItems;
begin
  game.num_items := sizeof(itemlist) div sizeof(itemlist[0]) - 1;
end;



{
========
SetItemNames

Called by worldspawn
========
}
procedure SetItemNames;
var
 i:integer;
 it:gitem_p;
begin


   for i:=0 to game.num_items-1 do
   begin
      it := @itemlist[i];
      gi.configstring (CS_ITEMS+i, it^.pickup_name);
   end;

   jacket_armor_index := ITEM_INDEX(FindItem('Jacket Armor'));
   combat_armor_index := ITEM_INDEX(FindItem('Combat Armor'));
   body_armor_index   := ITEM_INDEX(FindItem('Body Armor'));
   power_screen_index := ITEM_INDEX(FindItem('Power Screen'));
   power_shield_index := ITEM_INDEX(FindItem('Power Shield'));
end;


end.
