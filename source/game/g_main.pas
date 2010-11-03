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
{ File(s): g_local.h (part), g_main.c                                        }
{ Content: Quake2\Game-CTF\ game interface initialization / management       }
{                                                                            }
{ Initial conversion by : Clootie (Alexey Barkovoy) - clootie@reactor.ru     }
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
{ * Updated:                                                                 }
{ 1) 27-Jan-2002 - Clootie (clootie@reactor.ru)                              }
{    Corrected "strtok" function.                                            }
{ 2) 28-Jan-2002 - Clootie (clootie@reactor.ru)                              }
{    Linked to "g_svcmnds.pas" unit.                                         }
{ 3) 25-Feb-2002 - Clootie (clootie@reactor.ru)                              }
{    Resolved all dependency to G_Local.pas and G_Utils.pas.                 }
{ 4) 3-Mar-2002 - Carl Kenner (carl_kenner@hotmail.com)                      }
{    Made compatible with Capture The Flag and g_save                        }
{    Removed redefinitions of g_local stuff                                  }
{ 5) 14-May-2003 - Scott Price (scott.price@totalise.co.uk)                  }
{    Made pointer dereference alterations, and altered some calls to Round ()}
{    to be Trunc() instead to remain with the previous conventions, and      }
{    fixed a minor conversion bug.  Not compared CTF code, just concentrated }
{    on GAME units sections.                                                 }
{                                                                            }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{ -- Implementation: g_phys, p_client, g_spawn                               }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{ Clootie: "GAME_HARD_LINKED" on what project it should be defined ?         }
{----------------------------------------------------------------------------}
{ * NOTES:  --== Clootie ==--                                                }
{           This unit designed to be compatible with both Game and CTF build }
{           targets. By default unit compiles to GAME build target. To build }
{           for CTF one should define "CTF" global conditional define.       }
{----------------------------------------------------------------------------}

unit g_main;

interface

uses
  CPas,
  Q_Shared,
  G_Local,
  GameUnit;

type
  edict_arr = array[0..MaxInt div SizeOf(edict_t) - 1] of edict_t;

var
  game: game_locals_t;
  level: level_locals_t;
  gi: game_import_t;
  globals: game_export_t;
  st: spawn_temp_t;

  sm_meat_index,
  snd_fry,
  meansOfDeath: Integer;


  g_edicts: ^edict_arr;

  deathmatch,
  coop,
  dmflags,
  skill,
  fraglimit,
  timelimit,
  password,
  spectator_password,
  needpass,
  maxclients,
  maxspectators,
  maxentities,
  g_select_empty,
  dedicated,

  filterban,

  sv_maxvelocity,
  sv_gravity,

  sv_rollspeed,
  sv_rollangle,
  gun_x,
  gun_y,
  gun_z,

  run_pitch,
  run_roll,
  bob_up,
  bob_pitch,
  bob_roll,

  sv_cheats,

  flood_msgs,
  flood_persecond,
  flood_waitdelay,

  sv_maplist: cvar_p;


procedure G_RunFrame; cdecl;
function GetGameApi(const import: game_import_t): game_export_p; cdecl;

{$IFNDEF GAME_HARD_LINKED}
// this is only here so the functions in q_shared.c and q_shwin.c can link
procedure Sys_Error(error: PChar; args: array of const); overload;
procedure Sys_Error(error: PChar); overload;
procedure Com_Printf(msg: PChar; args: array of const); overload;
procedure Com_Printf(fmt: PChar); overload;
{$ENDIF}

function world: edict_p;

implementation

uses
  SysUtils,
  Math,
  g_svcmds,
  g_save,
  g_spawn,
  g_utils
{.$IFDEF GAME_HARD_LINKED}
  , g_ai
{$IFDEF CTF}
  , g_ctf
{$ENDIF}
{.$ENDIF}
   , p_client, g_cmds, p_view, p_hud, g_monster, g_phys;

function world: edict_p;
begin
  Result := @g_edicts^[0];
end;

//===================================================================


procedure ShutdownGame; cdecl;
begin
  gi.dprintf('==== ShutdownGame ===='#10);

  gi.FreeTags(TAG_LEVEL);
  gi.FreeTags(TAG_GAME);
end;


(*
=================
GetGameAPI

Returns a pointer to the structure with all entry points
and global variables
=================
*)
function GetGameApi(const import: game_import_t): game_export_p; cdecl;
begin
  gi := import;

  globals.apiversion := GAME_API_VERSION;
  globals.Init := InitGame;
  globals.Shutdown := ShutdownGame;
  globals.SpawnEntities := SpawnEntities;

  globals.WriteGame := WriteGame;
  globals.ReadGame := ReadGame;
  globals.WriteLevel := WriteLevel;
  globals.ReadLevel := ReadLevel;

  globals.ClientThink := ClientThink;
  globals.ClientConnect := ClientConnect;
  globals.ClientUserinfoChanged := ClientUserinfoChanged;
  globals.ClientDisconnect := ClientDisconnect;
  globals.ClientBegin := ClientBegin;
  globals.ClientCommand := ClientCommand;

  globals.RunFrame := G_RunFrame;

  globals.ServerCommand := ServerCommand;

  globals.edict_size := SizeOf(edict_t);

  Result := @globals;
end;

{$IFNDEF GAME_HARD_LINKED}

// this is only here so the functions in q_shared.c and q_shwin.c can link
procedure Sys_Error(error: PChar; args: array of const);
var
  text: array [0..1023] of Char;
begin
  StrFmt(text, error, args);
  //Clootie: code error in C source file - probably it's never compiles
  //         - as Game.dll exist in all Quake-series games
  // gi.error(ERR_FATAL, '%s', [text]);
  gi.error({ERR_FATAL, }'%s', text);
end;

procedure Com_Printf(msg: PChar; args: array of const);
var
  text: array [0..1023] of Char;
begin
  StrFmt(text, msg, args);
  gi.dprintf('%s', text);
end;

procedure Com_Printf(fmt: PChar);
begin
  Com_Printf(fmt, []);
end;

procedure Sys_Error(error: PChar);
begin
  Sys_Error(error, []);
end;

{$ENDIF}

//======================================================================


(*
=================
ClientEndServerFrames
=================
*)
procedure ClientEndServerFrames;
var
  i: Integer;
  ent: edict_p;
begin
  // calc the player views now that all pushing
  // and damage has been added
  for i := 0 to {Round}Trunc(maxclients^.value) - 1 do
  begin
    { ent = g_edicts + 1 + i; }
    ent := @g_edicts^[1 + i];
    if (not ent^.inuse) or (ent^.client = nil) then
      Continue;
    ClientEndServerFrame(ent);
  end;
end;

(*
=================
CreateTargetChangeLevel

Returns the created target changelevel
=================
*)
function CreateTargetChangeLevel(map: PChar): edict_p;
var
  ent: edict_p;
begin
  ent := g_utils.G_Spawn;
  ent^.classname := 'target_changelevel';
  Com_sprintf(level.nextmap, sizeof(level.nextmap), '%s', [map]);
  ent^.map := level.nextmap;
  Result := ent;
end;


(*
=================
EndDMLevel

The timelimit or fraglimit has been exceeded
=================
*)
procedure EndDMLevel;
var
  ent: edict_p;
  s, t, f: PChar;
const
  seps = ' ,'#10#13; // static const char *
begin
  // stay on same level flag
  if ({Round}Trunc(dmflags^.value) and DF_SAME_LEVEL) <> 0 then
  begin
    BeginIntermission(CreateTargetChangeLevel(level.mapname));
    Exit;
  end;

{$IFDEF CTF}
  if (PChar(@level.forcemap)^ <> #0) then
  begin
    BeginIntermission(CreateTargetChangeLevel(level.forcemap));
    Exit;
  end;

{$ENDIF}
  // see if it's in the map list
  if (sv_maplist^.string_^ <> #0) then
  begin
     s := StrNew(sv_maplist^.string_);
     f := nil;
     t := strtok(s, seps);
     while (t <> nil) do
     begin
       if (Q_stricmp(t, level.mapname) = 0) then
       begin
         // it's in the list, go to the next one
         t := strtok(nil, seps);
         if (t = nil) then // end of list, go to first one
         begin
           if (f = nil) then // there isn't a first one, same level
             BeginIntermission(CreateTargetChangeLevel(level.mapname))
           else
             BeginIntermission(CreateTargetChangeLevel(f));
         end else
           BeginIntermission(CreateTargetChangeLevel(t));
         StrDispose(s);
         Exit;
       end;
       if (f = nil) then
         f := t;
       t := strtok(nil, seps);
     end;
     StrDispose(s);
  end;

  if (level.nextmap[0] <> #0) then // go to a specific map
    BeginIntermission(CreateTargetChangeLevel(level.nextmap))
  else
  begin   // search for a changelevel
    // #define FOFS(x) (int)&(((edict_t *)0)->x)
    // ent := G_Find(nil, FOFS(classname), 'target_changelevel');
    ent := G_Find(nil, Integer(@edict_p(nil).classname), 'target_changelevel');
    if (ent = nil) then
    begin   // the map designer didn't include a changelevel,
      // so create a fake ent that goes back to the same level
      BeginIntermission(CreateTargetChangeLevel(level.mapname));
      Exit;
    end;
    BeginIntermission(ent);
  end;
end;

{$IFNDEF CTF}

(*
=================
CheckNeedPass
=================
*)
procedure CheckNeedPass;
var
  need: Integer;
begin
  // if password or spectator_password has changed, update needpass
  // as needed
  if (password^.modified or spectator_password^.modified) then
  begin
    spectator_password^.modified := False;
    password^.modified := spectator_password^.modified;

    need := 0;

    { 2003-05-14 (SP):  In case a more literal translation is required:
    if (password^.string_^ <> #0) and }
    if (password^.string_ <> nil) and (Q_stricmp(password^.string_, 'none') <> 0) then
      need := need or 1;

    { 2003-05-14 (SP):  In case a more literal translation is required:
    if (spectator_password^.string_^ <> #0) and }
    if (spectator_password^.string_ <> nil) and (Q_stricmp(spectator_password^.string_, 'none') <> 0) then
      need := need or 2;

    gi.cvar_set('needpass', va('%d', [need]));
  end;
end;

{$ENDIF}

(*
=================
CheckDMRules
=================
*)
procedure CheckDMRules;
var
  i: Integer;
  cl: gclient_p;
begin
  if (level.intermissiontime <> 0) then
    Exit;

  if (deathmatch^.value = 0) then
    Exit;

{$IFDEF CTF}
//ZOID
  if (ctf.value <> 0) and (CTFCheckRules) then
  begin
    EndDMLevel;
    Exit;
  end;
  if CTFInMatch then
    Exit; // no checking in match mode
//ZOID

{$ENDIF}
  if (timelimit^.value <> 0) then
  begin
    if (level.time >= timelimit^.value * 60) then
    begin
      gi.bprintf(PRINT_HIGH, 'Timelimit hit.'#10, []);
      EndDMLevel;
      Exit;
    end;
  end;

  if (fraglimit^.value <> 0) then
  begin
    for i := 0 to {Round}Trunc(maxclients^.value) - 1 do
    begin
      { cl := game.clients + i; }
      cl := game.clients; Inc(cl, i);

      if g_edicts^[i+1].inuse then
        Continue;

      if (cl^.resp.score >= fraglimit^.value) then
      begin
        gi.bprintf(PRINT_HIGH, 'Fraglimit hit.'#10, []);
        EndDMLevel;
        Exit;
      end;
    end;
  end;
end;


(*
=============
ExitLevel
=============
*)
procedure ExitLevel;
var
  i: Integer;
  ent: edict_p;
  command: array [0..255] of Char;
begin
{$IFDEF CTF}
  level.exitintermission := 0;
  level.intermissiontime := 0;

  if CTFNextMap then Exit;

{$ENDIF}
  Com_sprintf(command, SizeOf(command), 'gamemap "%s"'#10, [level.changemap]);
  gi.AddCommandString(command);
{$IFNDEF CTF}
  level.changemap := nil;
  level.exitintermission := 0;
  level.intermissiontime := 0;
{$ENDIF}
  ClientEndServerFrames;

{$IFDEF CTF}
  level.changemap := nil;

{$ENDIF}
  // clear some things before going to next level
  for i := 0 to {Round}Trunc(maxclients^.value) - 1 do
  begin
    ent := @g_edicts^[1 + i];
    if (not ent^.inuse) then
      Continue;
    if (ent^.health > ent^.client^.pers.max_health) then
      ent^.health := ent^.client^.pers.max_health;
  end;
end;

(*
================
G_RunFrame

Advances the world by 0.1 seconds
================
*)
procedure G_RunFrame; cdecl;
var
  i: Integer;
  ent: edict_p;
label
  continue_;
begin
  Inc(level.framenum);
  level.time := level.framenum*FRAMETIME;

  // choose a client for monsters to target this frame
  AI_SetSightClient;

  // exit intermissions

  if (level.exitintermission <> 0) then 
  begin
    ExitLevel;
    Exit;
  end;

  //
  // treat each object in turn
  // even the world gets a chance to think
  //
  ent := @g_edicts^[0];
  for i := 0 to globals.num_edicts -1 do //; i++, ent++)
  begin
    if (not ent^.inuse) then
      goto Continue_;

    level.current_entity := ent;

    VectorCopy(ent^.s.origin, ent^.s.old_origin);

    // if the ground entity moved, make sure we are still on it
    if (ent^.groundentity <> nil) and
       (ent^.groundentity^.linkcount <> ent^.groundentity_linkcount) then
    begin
      ent^.groundentity := nil;
      if ((ent^.flags and (FL_SWIM or FL_FLY)) = 0) and
         ((ent^.svflags and SVF_MONSTER) <> 0) then
      begin
        M_CheckGround(ent);
      end;
    end;

    if (i > 0) and (i <= maxclients^.value) then
    begin
      ClientBeginServerFrame(ent);
      goto Continue_;
    end;

    G_RunEntity(ent);

  { Label to perform secondary increment }
  Continue_:
    Inc(ent);
  end;

  // see if it is time to end a deathmatch
  CheckDMRules;

{$IFNDEF CTF}
  // see if needpass needs updated
  CheckNeedPass;

{$ENDIF}
  // build the playerstate_t structures for all players
  ClientEndServerFrames;
end;

end.

