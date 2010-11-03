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
{ File(s): g_local.h (part), g_utils.c                                       }
{ Content: Quake2\(Game|CTF)\ misc utility functions for game module         }
{                                                                            }
{ Initial conversion by : Clootie (Alexey Barkovoy) - clootie@reactor.ru     }
{ Initial conversion on : 27-Feb-2002                                        }
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
{ 1) 03-Mar-2002 - Clootie (clootie@reactor.ru)                              }
{    Changed "G_FreeEdict" calling convention to "cdecl"                     }
{ 2) 12-Jun-2003 - Scott Price (scott.price@totalise.co.uk)                  }
{    Changed use of the forward keyword as a variable to alternative name.   }
{    Changed While..Loop with continues to follow usage styles elsewhere.    }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{                                                                            }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{----------------------------------------------------------------------------}

{$Include ..\JEDI.inc}

unit g_utils;

interface

uses
  q_shared, g_local, g_main{$IFNDEF COMPILER6_UP}, Windows{$ENDIF};

// g_utils.c -- misc utility functions for game module

//
// g_utils.c
//

function KillBox(ent: edict_p): qboolean;
procedure G_ProjectSource(const point, distance, forward_, right: vec3_t;
  out result: vec3_t);
function G_Find(from: edict_p; fieldofs: Integer; match: PChar): edict_p;
function findradius(from: edict_p; const org: vec3_t; rad: Single): edict_p;
function G_PickTarget(targetname: PChar): edict_p;
procedure G_UseTargets(ent: edict_p; activator: edict_p);
procedure G_SetMovedir(var angles: vec3_t; var movedir: vec3_t);

procedure G_InitEdict(e: edict_p);
function G_Spawn: edict_p;
procedure G_FreeEdict(ed: edict_p); cdecl;

procedure G_TouchTriggers(ent: edict_p); 
procedure G_TouchSolids(ent: edict_p);

function G_CopyString(in_: PChar): PChar;

function tv(x, y, z: Single): PSingle;
function vtos(const v: vec3_t): PChar;

function vectoyaw(const vec: vec3_t): Single;
procedure vectoangles(const value1: vec3_t; var angles: vec3_t);


implementation

uses
  Math,
  SysUtils,
  g_combat,
  g_save,
  GameUnit,
  CPas,
  Game_add;

procedure G_ProjectSource(const point, distance, forward_, right: vec3_t;
  out result: vec3_t);
begin
  result[0] := point[0] + forward_[0] * distance[0] + right[0] * distance[1];
  result[1] := point[1] + forward_[1] * distance[0] + right[1] * distance[1];
  result[2] := point[2] + forward_[2] * distance[0] + right[2] * distance[1] + distance[2];
end;


(*
=============
G_Find

Searches all active entities for the next one that holds
the matching string at fieldofs (use the FOFS() macro) in the structure.

Searches beginning at the edict after from, or the beginning if NULL
NULL will be returned if the end of the list is reached.

=============
*)
function G_Find(from: edict_p; fieldofs: Integer; match: PChar): edict_p;
var
  s: PChar;
label
  Continue__;
begin
  if (from = nil) then
    from := edict_p(g_edicts) //Clootie: we take first pointer of array
  else
    Inc(from); //Clootie: Shift to next element in pointer to array of "edict_t"

  while Integer(from) < Integer(@g_edicts^[globals.num_edicts]) do
  begin
    if (not from^.inuse) then
      goto Continue__;

    s := PPChar(Integer(from) + fieldofs)^;
    if (s = nil) then
      goto Continue__;

    if (Q_stricmp(s, match) = 0) then
    begin
      Result := from;
      Exit;
    end;

  Continue__:
    Inc(from);
  end;

  Result := nil;
end;


(*
=================
findradius

Returns entities that have origins within a spherical area

findradius (origin, radius)
=================
*)
function findradius(from: edict_p; const org: vec3_t; rad: Single): edict_p;
var
  eorg: vec3_t;
  j: Integer;
label
  Continue__;
begin
  if (from = nil) then
    from := edict_p(g_edicts) //Clootie: we take first pointer of array
  else
    Inc(from); //Clootie: Shift to next element in pointer to array of "edict_t"

  while Integer(from) < Integer(@g_edicts^[globals.num_edicts]) do // FAB ..Check This ..
  begin
    if (not from^.inuse) then
      goto Continue__;
    if (from^.solid = SOLID_NOT) then
      goto Continue__;

    for j := 0 to 2 do
      eorg[j] := org[j] - (from^.s.origin[j] + (from^.mins[j] + from^.maxs[j])*0.5);

    if (VectorLength(eorg) > rad) then
      goto Continue__;

    Result:= from;
    Exit;

  Continue__:
    Inc(from);
  end;

  Result := nil;
end;


(*
=============
G_PickTarget

Searches all active entities for the next one that holds
the matching string at fieldofs (use the FOFS() macro) in the structure.

Searches beginning at the edict after from, or the beginning if NULL
NULL will be returned if the end of the list is reached.

=============
*)
const
  MAXCHOICES    = 8;

function G_PickTarget(targetname: PChar): edict_p;
var
  ent: edict_p;
  num_choices: Integer;
  choice: array [0..MAXCHOICES-1] of edict_p;
begin
  ent := nil;
  num_choices := 0;

  if (targetname = nil) then
  begin
    gi.dprintf('G_PickTarget called with NULL targetname'#10);
    Result := nil;
    Exit;
  end;

  while True do
  begin
    ent := G_Find(ent, FOFS_targetname, targetname);
    if (ent = nil) then
      Break;
    choice[num_choices] := ent;
    Inc(num_choices);
    if (num_choices = MAXCHOICES) then
      Break;
  end;

  if (num_choices = 0) then
  begin
    gi.dprintf('G_PickTarget: target %s not found'#10, targetname);
    Result := nil;
    Exit;
  end;

  Result:= choice[rand() mod num_choices];
end;

procedure Think_Delay(ent: edict_p); cdecl;
begin
  G_UseTargets(ent, ent^.activator);
  G_FreeEdict(ent);
end;


(*
==============================
G_UseTargets

the global "activator" should be set to the entity that initiated the firing.

If self.delay is set, a DelayedUse entity will be created that will actually
do the SUB_UseTargets after that many seconds have passed.

Centerprints any self.message to the activator.

Search for (string)targetname in all entities that
match (string)self.target and call their .use function

==============================
*)
procedure G_UseTargets(ent: edict_p; activator: edict_p);
var
  t: edict_p;
label
  continue_;
begin
//
// check for a delay
//
  if (ent^.delay <> 0) then
  begin
  // create a temp object to fire at a later time
    t := G_Spawn;
    t^.classname := 'DelayedUse';
    t^.nextthink := level.time + ent^.delay;
    t^.think := Think_Delay;
    t^.activator := activator;
    if (activator = nil) then
      gi.dprintf('Think_Delay with no activator'#10, []);
    t^._message := ent^._message;
    t^.target := ent^.target;
    t^.killtarget := ent^.killtarget;
    Exit;
  end;


//
// print the message
//
  if (ent^._message <> nil) and ((activator^.svflags and SVF_MONSTER) = 0) then
  begin
    gi.centerprintf(activator, '%s', ent^._message);
    if (ent^.noise_index <> 0) then
      gi.sound(activator, CHAN_AUTO, ent^.noise_index, 1, ATTN_NORM, 0)
    else
      gi.sound(activator, CHAN_AUTO, gi.soundindex('misc/talk1.wav'), 1, ATTN_NORM, 0);
  end;

//
// kill killtargets
//
  if (ent^.killtarget <> nil) then
  begin
    t := nil;
    t := G_Find(t, FOFS_targetname, ent^.killtarget);
    while (t <> nil) do
    begin
      G_FreeEdict(t);
      if not ent^.inuse then
      begin
        gi.dprintf('entity was removed while using killtargets'#10, []);
        Exit;
      end;
      t := G_Find(t, FOFS_targetname, ent^.killtarget);
    end;
  end;

//
// fire targets
//
  if (ent^.target <> nil) then
  begin
    t := nil;
    t := G_Find(t, FOFS_targetname, ent^.target);
    while (t <> nil) do
    begin
      // doors fire area portals in a specific way
      if (Q_stricmp(t^.classname, 'func_areaportal') = 0) and
         ((Q_stricmp(ent^.classname, 'func_door') = 0) or
          (Q_stricmp(ent^.classname, 'func_door_rotating') = 0))
      then
        goto continue_;

      if (t = ent) then
      begin
        gi.dprintf('WARNING: Entity used itself.'#10, []);
      end else
      begin
        if (@t^.use <> nil) then
          t^.use(t, ent, activator);
      end;
      if not ent^.inuse then
      begin
        gi.dprintf('entity was removed while using targets'#10, []);
        Exit;
      end;
    continue_:
      t := G_Find(t, FOFS_targetname, ent^.target);
    end;
  end;
end;


(*
=============
TempVector

This is just a convenience function
for making temporary vectors for function calls
=============
*)
function tv(x, y, z: Single): PSingle;
{$IFDEF COMPILER6_UP}{$WRITEABLECONST ON}{$ENDIF}
const
  index: Integer = 0;
  vecs: array[0..7] of vec3_t =
    ((0,0,0),(0,0,0),(0,0,0),(0,0,0),(0,0,0),(0,0,0),(0,0,0),(0,0,0));
{$IFDEF COMPILER6_UP}{$WRITEABLECONST OFF}{$ENDIF}
var
  v: vec3_p;
begin
  // use an array so that multiple tempvectors won't collide
  // for a while
  v := @vecs[index];
  index := (index + 1) and 7;

  v[0] := x;
  v[1] := y;
  v[2] := z;

  Result:= PSingle(v);
end;


(*
=============
VectorToString

This is just a convenience function
for printing vectors
=============
*)
function vtos(const v: vec3_t): PChar;
{$IFDEF COMPILER6_UP}{$WRITEABLECONST ON}{$ENDIF}
const
  index: Integer = 0;
  str: array[0..7, 0..31] of Char = (
    #0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0,
    #0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0,
    #0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0,
    #0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0,
    #0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0,
    #0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0,
    #0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0,
    #0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0#0
  );
{$IFDEF COMPILER6_UP}{$WRITEABLECONST OFF}{$ENDIF}
var
  s: PChar;
begin
  // use an array so that multiple vtos won't collide
  s := str[index];
  index := (index + 1) and 7;

  Com_sprintf(s, 32, '(%d %d %d)', [{Round}Trunc(v[0]), {Round}Trunc(v[1]), {Round}Trunc(v[2])]);

  Result:= s;
end;

var
  VEC_UP        : vec3_t        = (0, -1, 0);
  MOVEDIR_UP    : vec3_t         = (0, 0, 1);
  VEC_DOWN      : vec3_t        = (0, -2, 0);
  MOVEDIR_DOWN  : vec3_t        = (0, 0, -1);

procedure G_SetMovedir(var angles: vec3_t; var movedir: vec3_t);
begin
  if VectorCompare(angles, VEC_UP) <> 0 then
  begin
    VectorCopy(MOVEDIR_UP, movedir);
  end
  else if VectorCompare(angles, VEC_DOWN) <> 0 then
  begin
    VectorCopy(MOVEDIR_DOWN, movedir);
  end
  else
  begin
    AngleVectors(angles, @movedir, nil, nil);
  end;

  VectorClear(angles);
end;


function vectoyaw(const vec: vec3_t): Single;
var
  yaw: Single;
begin
  if ((* vec[q_shared.YAW] == 0 && *) vec[q_shared.PITCH] = 0) then
  begin
    yaw := 0;
    if (vec[q_shared.YAW] > 0) then
      yaw := 90
    else if (vec[q_shared.YAW] < 0) then
      yaw := -90;
  end else
  begin
    yaw := {Round}Trunc((ArcTan2(vec[q_shared.YAW], vec[q_shared.PITCH]) * 180 / M_PI));
    if (yaw < 0) then
      yaw := yaw + 360;
  end;

  Result:= yaw;
end;


procedure vectoangles(const value1: vec3_t; var angles: vec3_t);
var
  forward_: Single;
  yaw, pitch: Single;
begin
  if (value1[1] = 0) and (value1[0] = 0) then
  begin
    yaw := 0;
    if (value1[2] > 0) then
      pitch := 90
    else
      pitch := 270;
  end
  else
  begin
    if (value1[0] <> 0) then
      yaw := {Round}Trunc(ArcTan2(value1[1], value1[0]) * 180 / M_PI)
    else if (value1[1] > 0) then
      yaw := 90
    else
      yaw := -90;
    if (yaw < 0) then
      yaw := yaw + 360;

    forward_ := sqrt(value1[0]*value1[0] + value1[1]*value1[1]);
    pitch := {Round}Trunc(ArcTan2(value1[2], forward_) * 180 / M_PI);
    if (pitch < 0) then
      pitch := pitch + 360;
  end;

  angles[q_shared.PITCH] := -pitch;
  angles[q_shared.YAW] := yaw;
  angles[q_shared.ROLL] := 0;
end;

function G_CopyString(in_: PChar): PChar;
begin
  Result := gi.TagMalloc(StrLen(in_)+1, TAG_LEVEL);
  StrCopy(Result, in_);
end;


procedure G_InitEdict(e: edict_p);
begin
  e^.inuse := True;
  e^.classname := 'noclass';
  e^.gravity := 1.0;
  e^.s.number := (Integer(e) - Integer(g_edicts)) div SizeOf(edict_t);
end;

(*
=================
G_Spawn

Either finds a free edict, or allocates a new one.
Try to avoid reusing an entity that was recently freed, because it
can cause the client to think the entity morphed into something else
instead of being removed and recreated, which can cause interpolated
angles and bad trails.
=================
*)
function G_Spawn: edict_p;
var
  i, i_hack: Integer; //Clootie: i_hack - is Delphi local cycle variable hack
  e: edict_p;

begin

  e := @g_edicts^[{Round}Trunc(maxclients^.value)+1] ;

  i_hack := 0;
  for i := {Round}Trunc(maxclients^.value)+1 to globals.num_edicts - 1 do
  begin
    // the first couple seconds of server time can involve a lot of
    // freeing and allocating, so relax the replacement policy
    if not e^.inuse and ((e^.freetime < 2) or (level.time - e^.freetime > 0.5)) then
    begin
      G_InitEdict(e);
      Result := e;
      Exit;
    end;
    Inc(e); // i++, e++)
    i_hack := i + 1;
  end;

  if (i_hack = game.maxentities) then
    gi.error('ED_Alloc: no free edicts', []);

  Inc(globals.num_edicts);
  G_InitEdict(e);
  Result := e;
end;

(*
=================
G_FreeEdict

Marks the edict as free
=================
*)
procedure G_FreeEdict(ed: edict_p);
begin
  gi.unlinkentity(ed);      // unlink from world

  if ((Integer(ed) - Integer(g_edicts)) div SizeOf(edict_t) <=
     (maxclients^.value + BODY_QUEUE_SIZE)) then
  begin
//  gi.dprintf("tried to free special edict\n");
    Exit;
  end;

  FillChar(ed^, SizeOf(ed^), 0);
  ed^.classname := 'freed';
  ed^.freetime := level.time;
  ed^.inuse := false;
end;


(*
============
G_TouchTriggers

============
*)
procedure G_TouchTriggers(ent: edict_p);
var
  i, num: Integer;
  touch: array [0..MAX_EDICTS-1] of edict_p;
  hit: edict_p;
begin
  // dead things don't activate triggers!
  if ((ent^.client <> nil) or (ent^.svflags and SVF_MONSTER <> 0)) and
  (ent^.health <= 0) then
    Exit;

  num := gi.BoxEdicts(@ent^.absmin, @ent^.absmax, @touch, MAX_EDICTS, AREA_TRIGGERS);

  // be careful, it is possible to have an entity in this
  // list removed before we get to it (killtriggered)
  for i := 0 to num - 1 do
  begin
    hit := touch[i];
    if not hit^.inuse then
      Continue;
    if (@hit^.touch = nil) then
      Continue;
    hit^.touch(hit, ent, nil, nil);
  end;
end;

(*
============
G_TouchSolids

Call after linking a new trigger in during gameplay
to force all entities it covers to immediately touch it
============
*)
procedure G_TouchSolids(ent: edict_p);
var
  i, num: Integer;
  touch: array [0..MAX_EDICTS-1] of edict_p;
  hit: edict_p;
begin
  num := gi.BoxEdicts(@ent^.absmin, @ent^.absmax, @touch, MAX_EDICTS, AREA_SOLID);

  // be careful, it is possible to have an entity in this
  // list removed before we get to it (killtriggered)
  for i := 0 to num - 1 do
  begin
    hit := touch[i];

    if not hit^.inuse then
      Continue;
    if (@hit^.touch <> nil) then
      hit^.touch(hit, ent, nil, nil);
    if not ent^.inuse then
      Break;
  end;
end;




(*
==============================================================================

Kill box

==============================================================================
*)

(*
=================
KillBox

Kills all entities that would touch the proposed new positioning
of ent.  Ent should be unlinked before calling this!
=================
*)
function KillBox(ent: edict_p): qboolean;
var
  tr: trace_t;
begin
  while True do
  begin
    tr := gi.trace(@ent^.s.origin, @ent^.mins, @ent^.maxs, @ent^.s.origin, nil, MASK_PLAYERSOLID);
    if (tr.ent = nil) then
      Break;

    // nail it
    T_Damage(tr.ent, ent, ent, vec3_origin, ent^.s.origin, vec3_origin, 100000,
      0, DAMAGE_NO_PROTECTION, MOD_TELEFRAG);

    // if we didn't kill it, fail
    if (edict_p(tr.ent)^.solid <> SOLID_NOT) then
    begin
      Result := False;
      Exit;
    end;
  end;

  Result := True;      // all clear
end;

end.
