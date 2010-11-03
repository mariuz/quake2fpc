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
{----------------------------------------------------------------------------}
{                                                                            }
{ File(s): g_spawn.c - nil system driver to aid porting efforts              }
{                                                                            }
{ Initial conversion by : Mani (mani246yahoo.com)                            }
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
{ Updated on :                                                               }
{ Updated by :                                                               }
{                                                                            }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{ 1) g_local.h                                                               }
{ 2)                                                                         }
{ 3)                                                                         }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{                                                                            }
{----------------------------------------------------------------------------}
unit g_spawn;

interface


uses
  g_local,
  g_items,
  q_shared,
  g_save,
  g_func,
  g_misc,
  g_trigger,
  CPas,
  DelphiTypes,
  m_insane,
  m_berserk,
  m_gladiator,
  m_gunner,
  m_infantry,
  m_soldier,
  m_tank,
  m_medic,
  m_flipper,
  m_chick,
  m_parasite,
  m_flyer,
  p_client,
  m_actor,
  m_brain,
  m_float,
  m_hover,
  m_mutant,
  m_supertank,
  m_boss2,
  m_boss3,
  m_boss31,
  g_turret,
  g_main,
  g_target;

type
  spawn_t = record
    name: pchar;
    spawn: procedure(ent: edict_p); cdecl;
  end;
  spawn_p = ^spawn_t;

procedure SP_worldspawn(ent: edict_p); cdecl;
procedure ED_CallSpawn(ent: edict_p); cdecl;
procedure SpawnEntities(mapname: pchar;  entities: pchar;  spawnpoint: pchar); cdecl;

var
  spawns: array [0..108] of spawn_t =
( (name:'item_health'; spawn:SP_item_health),
  (name:'item_health_small'; spawn:SP_item_health_small),
  (name:'item_health_large'; spawn:SP_item_health_large),
  (name:'item_health_mega'; spawn:SP_item_health_mega),

  (name:'info_player_start'; spawn:SP_info_player_start),
  (name:'info_player_deathmatch'; spawn:SP_info_player_deathmatch),
  (name:'info_player_coop'; spawn:SP_info_player_coop),
  (name:'info_player_intermission'; spawn:SP_info_player_intermission),

  (name:'func_plat'; spawn:SP_func_plat),
  (name:'func_button'; spawn:SP_func_button),
  (name:'func_door'; spawn:SP_func_door),
  (name:'func_door_secret'; spawn:SP_func_door_secret),
  (name:'func_door_rotating'; spawn:SP_func_door_rotating),
  (name:'func_rotating'; spawn:SP_func_rotating),
  (name:'func_train'; spawn:SP_func_train),
  (name:'func_water'; spawn:SP_func_water),
  (name:'func_conveyor'; spawn:SP_func_conveyor),
  (name:'func_areaportal'; spawn:SP_func_areaportal),
  (name:'func_clock'; spawn:SP_func_clock),
  (name:'func_wall'; spawn:SP_func_wall),
  (name:'func_object'; spawn:SP_func_object),
  (name:'func_timer'; spawn:SP_func_timer),
  (name:'func_explosive'; spawn:SP_func_explosive),
  (name:'func_killbox'; spawn:SP_func_killbox),

  (name:'trigger_always'; spawn:SP_trigger_always),
  (name:'trigger_once'; spawn:SP_trigger_once),
  (name:'trigger_multiple'; spawn:SP_trigger_multiple),
  (name:'trigger_relay'; spawn:SP_trigger_relay),
  (name:'trigger_push'; spawn:SP_trigger_push),
  (name:'trigger_hurt'; spawn:SP_trigger_hurt),
  (name:'trigger_key'; spawn:SP_trigger_key),
  (name:'trigger_counter'; spawn:SP_trigger_counter),
  (name:'trigger_elevator'; spawn:SP_trigger_elevator),
  (name:'trigger_gravity'; spawn:SP_trigger_gravity),
  (name:'trigger_monsterjump'; spawn:SP_trigger_monsterjump),

  (name:'target_temp_entity'; spawn:SP_target_temp_entity),
  (name:'target_speaker'; spawn:SP_target_speaker),
  (name:'target_explosion'; spawn:SP_target_explosion),
  (name:'target_changelevel'; spawn:SP_target_changelevel),
  (name:'target_secret'; spawn:SP_target_secret),
  (name:'target_goal'; spawn:SP_target_goal),
  (name:'target_splash'; spawn:SP_target_splash),
  (name:'target_spawner'; spawn:SP_target_spawner),
  (name:'target_blaster'; spawn:SP_target_blaster),
  (name:'target_crosslevel_trigger'; spawn:SP_target_crosslevel_trigger),
  (name:'target_crosslevel_target'; spawn:SP_target_crosslevel_target),
  (name:'target_laser'; spawn:SP_target_laser),
  (name:'target_help'; spawn:SP_target_help),
  (name:'target_actor'; spawn:SP_target_actor),
  (name:'target_lightramp'; spawn:SP_target_lightramp),
  (name:'target_earthquake'; spawn:SP_target_earthquake),
  (name:'target_character'; spawn:SP_target_character),
  (name:'target_string'; spawn:SP_target_string),

  (name:'worldspawn'; spawn:SP_worldspawn),
  (name:'viewthing'; spawn:SP_viewthing),

  (name:'light'; spawn:SP_light),
  (name:'light_mine1'; spawn:SP_light_mine1),
  (name:'light_mine2'; spawn:SP_light_mine2),
  (name:'info_null'; spawn:SP_info_null),
  (name:'func_group'; spawn:SP_info_null),
  (name:'info_notnull'; spawn:SP_info_notnull),
  (name:'path_corner'; spawn:SP_path_corner),
  (name:'point_combat'; spawn:SP_point_combat),

  (name:'misc_explobox'; spawn:SP_misc_explobox),
  (name:'misc_banner'; spawn:SP_misc_banner),
  (name:'misc_satellite_dish'; spawn:SP_misc_satellite_dish),
  (name:'misc_actor'; spawn:SP_misc_actor),
  (name:'misc_gib_arm'; spawn:SP_misc_gib_arm),
  (name:'misc_gib_leg'; spawn:SP_misc_gib_leg),
  (name:'misc_gib_head'; spawn:SP_misc_gib_head),
  (name:'misc_insane'; spawn:SP_misc_insane),
  (name:'misc_deadsoldier'; spawn:SP_misc_deadsoldier),
  (name:'misc_viper'; spawn:SP_misc_viper),
  (name:'misc_viper_bomb'; spawn:SP_misc_viper_bomb),
  (name:'misc_bigviper'; spawn:SP_misc_bigviper),
  (name:'misc_strogg_ship'; spawn:SP_misc_strogg_ship),
  (name:'misc_teleporter'; spawn:SP_misc_teleporter),
  (name:'misc_teleporter_dest'; spawn:SP_misc_teleporter_dest),
  (name:'misc_blackhole'; spawn:SP_misc_blackhole),
  (name:'misc_eastertank'; spawn:SP_misc_eastertank),
  (name:'misc_easterchick'; spawn:SP_misc_easterchick),
  (name:'misc_easterchick2'; spawn:SP_misc_easterchick2),

  (name:'monster_berserk'; spawn:SP_monster_berserk),
  (name:'monster_gladiator'; spawn:SP_monster_gladiator),
  (name:'monster_gunner'; spawn:SP_monster_gunner),
  (name:'monster_infantry'; spawn:SP_monster_infantry),
  (name:'monster_soldier_light'; spawn:SP_monster_soldier_light),
  (name:'monster_soldier'; spawn:SP_monster_soldier),
  (name:'monster_soldier_ss'; spawn:SP_monster_soldier_ss),
  (name:'monster_tank'; spawn:SP_monster_tank),
  (name:'monster_tank_commander'; spawn:SP_monster_tank),
  (name:'monster_medic'; spawn:SP_monster_medic),
  (name:'monster_flipper'; spawn:SP_monster_flipper),
  (name:'monster_chick'; spawn:SP_monster_chick),
  (name:'monster_parasite'; spawn:SP_monster_parasite),
  (name:'monster_flyer'; spawn:SP_monster_flyer),
  (name:'monster_brain'; spawn:SP_monster_brain),
  (name:'monster_floater'; spawn:SP_monster_floater),
  (name:'monster_hover'; spawn:SP_monster_hover),
  (name:'monster_mutant'; spawn:SP_monster_mutant),
  (name:'monster_supertank'; spawn:SP_monster_supertank),
  (name:'monster_boss2'; spawn:SP_monster_boss2),
  (name:'monster_boss3_stand'; spawn:SP_monster_boss3_stand),
  (name:'monster_jorg'; spawn:SP_monster_jorg),
  (name:'monster_commander_body'; spawn:SP_monster_commander_body),

  (name:'turret_breach'; spawn:SP_turret_breach),
  (name:'turret_base'; spawn:SP_turret_base),
  (name:'turret_driver'; spawn:SP_turret_driver),
  (Name:nil; spawn:nil));



implementation



uses
  g_utils,
  p_trail,
  g_local_add,
  game_add,
  SysUtils;


(*
===============
ED_CallSpawn

Finds the spawn function for the entity and calls it
===============
*)
procedure ED_CallSpawn(ent: edict_p);
var
  s: spawn_p;
  item: gitem_p;
  i: integer;
label
  continue_;
begin
  if (ent^.classname = nil) then
  begin
    gi.dprintf('ED_CallSpawn: NULL classname'#10);
    Exit;
  end;

  // check item spawn functions
  i:=0;
  item:= @itemlist;
  while i < game.num_items do
  begin
    if item^.classname = nil then
      goto continue_;

    if StrComp(item^.classname, ent^.classname) = 0 then
    begin
      // found it
      SpawnItem(ent, item);
      Exit;
    end;
  continue_:
    inc(i);
    inc(item);
  end;

  // check normal spawn functions
  s := @spawns;
  while s^.name <> nil do
  begin
    if StrComp(s^.name, ent^.classname) = 0 then
    begin
      // found it
      s^.spawn(ent);
      Exit;
    end;
    Inc(s);
  end;
  gi.dprintf('%s doesn''t have a spawn function'#10, ent^.classname);
end;

(*
=============
ED_NewString
=============
*)
function ED_NewString(string_: pchar): pchar;
var
  newb, new_p: pchar;
  I, L: integer;
begin
  L := StrLen(string_) + 1;
  newb := gi.TagMalloc(L, TAG_LEVEL);
  new_p := newb;

  i := 0;
  while i < (L - 1) do
  begin
    if (string_[I] = '\'{#92}) and (I < L - 1) then
    begin
      Inc(I);
      if string_[I] = 'n' then
      begin
        new_p^ := #10;
        Inc(new_p);
      end
      else
      begin
        new_p^ := '\'{#92};
        Inc(new_p);
      end;
    end
    else
    begin
      new_p^ := string_[I];
      Inc(new_p);
    end;
    Inc(i);
  end;

  Result := newb;
end;


(*
===============
ED_ParseField

Takes a key/value pair and sets the binary values
in an edict
===============
*)    
procedure ED_ParseField(key: pchar;  value: pchar;  ent: edict_p);
var
  f: field_p;
  b: pbyte;
  v: single;
  vec: vec3_t;
begin
  f := @fields;
  while f^.name <> nil do
  begin
    if ((f^.flags and FFL_NOSPAWN) = 0) and (Q_stricmp(f^.name, key) = 0) then
    begin
      // found it
      if (f^.flags and FFL_SPAWNTEMP) <> 0 then
        b := PByte(@st)
      else
        b := PByte(ent);

      case f^._type of
        F_LSTRING:  begin
          PPChar(Integer(b) + f^.ofs)^ := ED_NewString(value);
        end;
        F_VECTOR:  begin
          sscanf(value, '%f %f %f', [@vec[0], @vec[1], @vec[2]]);
          PSingleArray(Integer(b) + f^.ofs)[0] := vec[0];
          PSingleArray(Integer(b) + f^.ofs)[1] := vec[1];
          PSingleArray(Integer(b) + f^.ofs)[2] := vec[2];
        end;
        F_INT:  begin
          PInteger(Integer(b) + f^.ofs)^ := atoi(value);
        end;
        F_FLOAT:  begin
          PSingle(Integer(b) + f^.ofs)^ := atof(value);
        end;
        F_ANGLEHACK:  begin
          v := atof(value);
          PSingleArray(Integer(b) + f^.ofs)[0] := 0;
          PSingleArray(Integer(b) + f^.ofs)[1] := v;
          PSingleArray(Integer(b) + f^.ofs)[2] := 0;
        end;
        F_IGNORE: ;
      end;
      Exit;
    end;
    Inc(f);
  end;
  gi.dprintf('%s is not a field'#10, key);
end;

(*
====================
ED_ParseEdict

Parses an edict out of the given string, returning the new position
ed should be a properly initialized empty edict.
====================
*)    
function ED_ParseEdict(data: pchar;  ent: edict_p): pchar;
var
  init: QBoolean;
  keyname: array [0..(256 - 1)] of Char;
  com_token: PChar;
begin
  init := false;
  FillChar(st, SizeOf(st),0);

  (* go through all the dictionary pairs*)
  while True do
  begin
    (* parse key*)
    com_token := COM_Parse(data);
    if com_token[0] = '}' then
      Break;
    if data = nil then
      gi.error('ED_ParseEntity: EOF without closing brace');

    strncpy(keyname, com_token, SizeOf(keyname)-1);

    // parse value
    com_token := COM_Parse(data);
    if data = nil then
      gi.error('ED_ParseEntity: EOF without closing brace');

    if com_token[0] = '}' then
      gi.error('ED_ParseEntity: closing brace without data');

    init := true;

    (* keynames with a leading underscore are used for utility comments,*)
    (* and are immediately discarded by quake*)
    if keyname[0] = '_' then
      Continue;
      
    ED_ParseField(keyname, com_token, ent);
  end;
  
  if not init then
    FillChar(ent, SizeOf(ent^), 0);   { <<-- Perhaps SizeOf(edict_t) }

  Result := data;
end;


(*
================
G_FindTeams

Chain together all entities with a matching team field.

All but the first will have the FL_TEAMSLAVE flag set.
All but the last will have the teamchain field set to the next one
================
*)
procedure G_FindTeams();
var
  e, e2, chain: edict_p;
  i, j, c, c2: integer;
label
  Continue_, Continue_J;
begin
  c := 0;
  c2 := 0;
  e:= @g_edicts^[1];
  for i := 1 to globals.num_edicts-1 do
  begin
    if not e^.inuse then
      goto Continue_;
    if e^.team = nil then
      goto Continue_;
    if (e^.flags and FL_TEAMSLAVE) <> 0 then
      goto Continue_;

    chain := e;
    e^.teammaster := e;
    inc(c);
    inc(c2);
    e2 := edict_p(Cardinal(e) + 1 * SizeOf(edict_t));
    for j:= i + 1 to globals.num_edicts-1 do
    begin
      if not e2^.inuse then
        goto Continue_J;
      if e2^.team = nil then
        goto Continue_J;
      if (e2^.flags and FL_TEAMSLAVE) <> 0 then
        goto Continue_J;

      if strcmp(e^.team, e2^.team) = 0 then
      begin
        inc(c2);
        chain^.teamchain := e2;
        e2^.teammaster := e;
        chain := e2;
        e2^.flags := e2^.flags or FL_TEAMSLAVE;
      end;
    Continue_J:
      inc(e2);
    end;
  Continue_:
    inc(e);
  end;

  gi.dprintf('%i teams with %i entities'#10, c, c2);
end;

(*
==============
SpawnEntities

Creates a server's entity / program execution context by
parsing textual entity definitions out of an ent file.
==============
*)   
procedure SpawnEntities(mapname: pchar;  entities: pchar;  spawnpoint: pchar);
var
  ent: edict_p;
  inhibit: integer;
  com_token: pchar;
  i: integer;
  skill_level: single;
begin
  skill_level := floor(skill^.value);
  if skill_level < 0 then
    skill_level := 0;
  if skill_level > 3 then
    skill_level := 3;
  if skill^.value <> skill_level then
    gi.cvar_forceset('skill', va('%f', [skill_level]));

  SaveClientData();

  gi.FreeTags(TAG_LEVEL);

  FillChar(level, SizeOf(level), 0);
  FillChar(g_edicts^, game.maxentities * SizeOf(g_edicts^[0]), 0);

  strncpy(level.mapname, mapname, SizeOf(level.mapname)-1);
  strncpy(game.spawnpoint, spawnpoint, SizeOf(game.spawnpoint)-1);

  (* set client fields on player ents*)
  for i := 0 to (game.maxclients - 1) do
    g_edicts^[i + 1].client := @gclient_a(game.clients)^[i];

  ent := Nil;
  inhibit := 0;

  (* parse ents*)
  while True do
  begin
    (* parse the opening brace *)
    com_token := COM_Parse(entities);
    if entities = nil then
      Break;  //if (!entities)

    if com_token[0] <> '{' then
      gi.error('ED_LoadFromFile: found %s when expecting {', com_token);

    if ent = nil then
      ent := @g_edicts^[0] //if (!ent)
    else
      ent := g_utils.G_Spawn();
    entities := ED_ParseEdict(entities, ent);

    (* yet another map hack*)
    if (Q_stricmp(level.mapname, 'command') = 0) and (Q_stricmp(ent^.classname, 'trigger_once') = 0) and (Q_stricmp(ent^.model, '*27') = 0) then
      ent^.spawnflags := ent^.spawnflags and (not SPAWNFLAG_NOT_HARD);

    (* remove things (except the world) from different skill levels or deathmatch*)
    if ent <> @g_edicts^[0] then
    begin
      if deathmatch^.value <> 0 then
      begin
        if (ent^.spawnflags and SPAWNFLAG_NOT_DEATHMATCH) <> 0 then
        begin
          G_FreeEdict(ent);
          inc(inhibit);
          Continue;
        end;
      end
      else
      begin
        if ((skill^.value = 0) and ((ent^.spawnflags and SPAWNFLAG_NOT_EASY) <> 0)) or
           ((skill^.value = 1) and ((ent^.spawnflags and SPAWNFLAG_NOT_MEDIUM) <> 0)) or
           (((skill^.value = 2) or  (skill^.value = 3)) and ((ent^.spawnflags and SPAWNFLAG_NOT_HARD) <> 0)) then
        begin
          G_FreeEdict(ent);
          inc(inhibit);
          Continue;
        end;
      end;
      ent^.spawnflags := ent^.spawnflags and (not (SPAWNFLAG_NOT_EASY or SPAWNFLAG_NOT_MEDIUM or SPAWNFLAG_NOT_HARD or SPAWNFLAG_NOT_COOP or SPAWNFLAG_NOT_DEATHMATCH));
    end;

    ED_CallSpawn(ent);
  end;

  gi.dprintf('%i entities inhibited'#10,inhibit);

{$ifdef DEBUG}
  i := 1;
  ent := EDICT_NUM(i);
  while i < globals.num_edicts do
  begin
    if (ent^.inuse <> 0) or (ent^.inuse <> 1) then
      Com_DPrintf('Invalid entity %d'#10, i);
    inc(i);
    inc(ent);
  end;
{$endif}

  G_FindTeams();

  PlayerTrail_Init();
end;

{  |  |                           |  |   }
{  V  V   ToDo:  Scott from Here  V  V   }

(*===================================================================*)
{$ifdef 0}
{   (* cursor positioning*)
   xl <value>
   xr <value>
   yb <value>
   yt <value>
   xv <value>
   yv<value>

   (* drawing*)
   statpic <name>
   pic <stat>
   num< fieldwidth> <stat>
   string_ <stat>

   (* control*)
   if <stat>
     ifeq <stat> <value>
     ifbit <stat> <value>
   endif;}
{$endif}

var
  single_statusbar: PChar = 'yb -24 '+
(* health*)
 'xv 0 '+
 'hnum '+
 'xv 50 '+
 'pic 0 '+

(* ammo*)
 'if 2 '+
   ' xv 100 '+
   ' anum '+
   ' xv 150 '+
   ' pic 2 '+
 'endif '+

 (* armor*)
 'if 4 '+
   ' xv 200 '+
   ' rnum '+
   ' xv 250 '+
   ' pic 4 '+
 'endif '+

 (* selected item*)
 'if 6 '+
   ' xv 296 '+
   ' pic 6 '+
 'endif '+

 'yb -50 '+

 (* picked up item*)
 'if 7 '+
   ' xv 0 '+
   ' pic 7 '+
   ' xv 26 '+
   ' yb -42 '+
   ' stat_string 8 '+
   ' yb -50 '+
 'endif '+

 (* timer*)
 'if 9 '+
   ' xv 262 '+
   ' num 2 10 '+
   ' xv 296 '+
   ' pic 9 '+
 'endif '+

 (*  help / weapon icon *)
 'if 11 '+
   ' xv 148 '+
   ' pic 11 '+
 'endif ';

 dm_statusbar: pchar =
 'yb -24 '+

 (* health*)
 'xv 0 '+
 'hnum '+
 'xv 50 '+
 'pic 0 '+

 (* ammo*)
 'if 2 '+
   ' xv 100 '+
   ' anum '+
   ' xv 150 '+
   ' pic 2 '+
 'endif '+

 (* armor*)
 'if 4 '+
   ' xv 200 '+
   ' rnum '+
   ' xv 250 '+
   ' pic 4 '+
 'endif '+

  (* selected item*)
 'if 6 '+
   ' xv 296 '+
   ' pic 6 '+
 'endif '+

 'yb -50 '+

 (* picked up item*)
 'if 7 '+
   ' xv 0 '+
   ' pic 7 '+
   ' xv 26 '+
   ' yb -42 '+
   ' stat_string 8 '+
   ' yb -50 '+
 'endif '+

 (* timer*)
 'if 9 '+
   ' xv 246 '+
   ' num 2 10 '+
   ' xv 296 '+
   ' pic 9 '+
 'endif '+

 (*  help / weapon icon *)
 'if 11 '+
   ' xv 148 '+
   ' pic 11 '+
 'endif '+

 (*  frags*)
 'xr -50 '+
 'yt 2 '+
 'num 3 14 '+

 (* spectator*)
 'if 17 '+
   'xv 0 '+
   'yb -58 '+
   'string2 "SPECTATOR MODE" '+
 'endif '+

 (* chase camera*)
 'if 16 '+
   'xv 0 '+
   'yb -68 '+
   'string "Chasing" '+
   'xv 64 '+
   'stat_string 16 '+
 'endif ';


(*QUAKED worldspawn (0 0 0) ?

Only used for the world.
"sky" environment map name
"skyaxis" vector axis for rotating sky
"skyrotate" speed of rotation in degrees/second
"sounds" music cd track number
"gravity" 800 is default gravity
"message" text to print at user logon
*)


procedure SP_worldspawn(ent: edict_p);
begin
  ent^.movetype := MOVETYPE_PUSH;
  ent^.solid := SOLID_BSP;
  ent^.inuse := true;
  ent^.s.modelindex := 1;
  (* since the world doesn't use G_Spawn()*)
  (* world model is always index 1*)
  (*---------------*)
  (* reserve some spots for dead player bodies for coop / deathmatch*)
  InitBodyQue();

  (* set configstrings for items*)
  SetItemNames;

  if st.nextmap <> nil then
    strcpy(level.nextmap, st.nextmap); // if (st.nextmap)

  (* make some data visible to the server*)
  if (ent^._message <> nil) and (ent^._message[0] <> #0)then
  begin
    gi.configstring(CS_NAME, ent^._message);
    strncpy(level.level_name, ent^._message, SizeOf(level.level_name));
  end
  else
    strncpy(level.level_name, level.mapname, SizeOf(level.level_name));

  if (st.sky <> nil) and (st.sky[0] <> #0) then
    gi.configstring(CS_SKY, st.sky)
  else
    gi.configstring(CS_SKY, 'unit1_');

  gi.configstring(CS_SKYROTATE, va('%f', [st.skyrotate]));

  gi.configstring(CS_SKYAXIS, va('%f %f %f', [st.skyaxis[0], st.skyaxis[1], st.skyaxis[2]]));

  gi.configstring(CS_CDTRACK, va('%i', [ent^.sounds]));

  gi.configstring(CS_MAXCLIENTS, va('%i', [trunc(maxclients^.Value)]));


  (* status bar program*)
  if deathmatch^.value <> 0 then
    gi.configstring(CS_STATUSBAR, dm_statusbar)
  else
    gi.configstring(CS_STATUSBAR, single_statusbar);
  (*---------------*)

  (* help icon for statusbar*)
  gi.imageindex('i_help');
  level.pic_health := gi.imageindex('i_health');
  gi.imageindex('help');
  gi.imageindex('field_3');

  if st.gravity = nil then
    gi.cvar_set('sv_gravity', '800')
  else
    gi.cvar_set('sv_gravity', st.gravity);

  snd_fry := gi.soundindex('player/fry.wav'); (* standing in lava / slime*)

  PrecacheItem(FindItem('Blaster'));

  gi.soundindex('player/lava1.wav');
  gi.soundindex('player/lava2.wav');

  gi.soundindex('misc/pc_up.wav');
  gi.soundindex('misc/talk1.wav');

  gi.soundindex('misc/udeath.wav');

  (* gibs*)
  gi.soundindex('items/respawn1.wav');

  (* sexed sounds*)
  gi.soundindex('*death1.wav');
  gi.soundindex('*death2.wav');
  gi.soundindex('*death3.wav');
  gi.soundindex('*death4.wav');
  gi.soundindex('*fall1.wav');
  gi.soundindex('*fall2.wav');
  (* drowning damage*)
  gi.soundindex('*gurp1.wav');
  gi.soundindex('*gurp2.wav');
  (* player jump*)
  gi.soundindex('*jump1.wav');
  gi.soundindex('*pain25_1.wav');
  gi.soundindex('*pain25_2.wav');
  gi.soundindex('*pain50_1.wav');
  gi.soundindex('*pain50_2.wav');
  gi.soundindex('*pain75_1.wav');
  gi.soundindex('*pain75_2.wav');
  gi.soundindex('*pain100_1.wav');
  gi.soundindex('*pain100_2.wav');

  (* sexed models*)
  (* THIS ORDER MUST MATCH THE DEFINES IN g_local.h*)
  (* you can add more, max 15*)
  gi.modelindex('#w_blaster.md2');
  gi.modelindex('#w_shotgun.md2');
  gi.modelindex('#w_sshotgun.md2');
  gi.modelindex('#w_machinegun.md2');
  gi.modelindex('#w_chaingun.md2');
  gi.modelindex('#a_grenades.md2');
  gi.modelindex('#w_glauncher.md2');
  gi.modelindex('#w_rlauncher.md2');
  gi.modelindex('#w_hyperblaster.md2');
  gi.modelindex('#w_railgun.md2');
  gi.modelindex('#w_bfg.md2');

  (*-------------------*)
  gi.soundindex('player/gasp1.wav');    (* gasping for air*)
  gi.soundindex('player/gasp2.wav');    (* head breaking surface, not gasping*)

  gi.soundindex('player/watr_in.wav');  (* feet hitting water*)
  gi.soundindex('player/watr_out.wav');  (* feet leaving water*)

  gi.soundindex('player/watr_un.wav');  (* head going underwater*)

  gi.soundindex('player/u_breath1.wav');
  gi.soundindex('player/u_breath2.wav');

  gi.soundindex('items/pkup.wav');  (* bonus item pickup*)
  gi.soundindex('world/land.wav');  (* landing thud*)
  gi.soundindex('misc/h2ohit1.wav');  (* landing splash*)

  gi.soundindex('items/damage.wav');
  gi.soundindex('items/protect.wav');
  gi.soundindex('items/protect4.wav');
  gi.soundindex('weapons/noammo.wav');

  gi.soundindex('infantry/inflies1.wav');

  sm_meat_index := gi.modelindex('models/objects/gibs/sm_meat/tris.md2');
  gi.modelindex('models/objects/gibs/arm/tris.md2');
  gi.modelindex('models/objects/gibs/bone/tris.md2');
  gi.modelindex('models/objects/gibs/bone2/tris.md2');
  gi.modelindex('models/objects/gibs/chest/tris.md2');
  gi.modelindex('models/objects/gibs/skull/tris.md2');
  gi.modelindex('models/objects/gibs/head2/tris.md2');

  (**)
  (* Setup light animation tables. 'a' is total darkness, 'z' is doublebright.*)
  (**)
  (* 0 normal*)
  gi.configstring(CS_LIGHTS + 0, 'm');
  (* 1 FLICKER (first variety)*)
  gi.configstring(CS_LIGHTS + 1, 'mmnmmommommnonmmonqnmmo');
  (* 2 SLOW STRONG PULSE*)
  gi.configstring(CS_LIGHTS + 2, 'abcdefghijklmnopqrstuvwxyzyxwvutsrqponmlkjihgfedcba');
  (* 3 CANDLE (first variety)*)
  gi.configstring(CS_LIGHTS + 3, 'mmmmmaaaaammmmmaaaaaabcdefgabcdefg');
  (* 4 FAST STROBE*)
  gi.configstring(CS_LIGHTS + 4, 'mamamamamama');
  (* 5 GENTLE PULSE 1*)
  gi.configstring(CS_LIGHTS + 5, 'jklmnopqrstuvwxyzyxwvutsrqponmlkj');
  (* 6 FLICKER (second variety)*)
  gi.configstring(CS_LIGHTS + 6, 'nmonqnmomnmomomno');
  (* 7 CANDLE (second variety)*)
  gi.configstring(CS_LIGHTS + 7, 'mmmaaaabcdefgmmmmaaaammmaamm');
  (* 8 CANDLE (third variety)*)
  gi.configstring(CS_LIGHTS + 8, 'mmmaaammmaaammmabcdefaaaammmmabcdefmmmaaaa');
  (* 9 SLOW STROBE (fourth variety)*)
  gi.configstring(CS_LIGHTS + 9, 'aaaaaaaazzzzzzzz');
  (* 10 FLUORESCENT FLICKER*)
  gi.configstring(CS_LIGHTS + 10, 'mmamammmmammamamaaamammma');
  (* 11 SLOW PULSE NOT FADE TO BLACK*)
  gi.configstring(CS_LIGHTS + 11, 'abcdefghijklmnopqrrqponmlkjihgfedcba');

  (* styles 32-62 are assigned by the light program for switchable lights*)
  (* 63 testing*)
  gi.configstring(CS_LIGHTS + 63, 'a');
end;


end.
