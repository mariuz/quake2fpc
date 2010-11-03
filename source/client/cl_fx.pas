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


{100%}
{----------------------------------------------------------------------------}
{                                                                            }
{ File(s): cl_fx.c                                                        }
{ Content: Quake2\Client - builds an intended movement command to send to the server }
{                                                                            }
{ Initial conversion by : Juha Hartikainen - juha@linearteam.org             }
{ Initial conversion on : 03-Jun-2002                                        }
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
{ Updates:                                                                   }
{                                                                            }
{ 27-Jun-2002 Steve 'Sly' Williams                                           }
{ - Fix hints and warnings                                                   }
{                                                                            }
{----------------------------------------------------------------------------}
// cl_fx.c -- entity effects parsing and management

unit cl_fx;

interface

uses
  CPas,
  Common,
  Client,
  ref,
  q_shared,
  q_shared_add,
  m_flash;

procedure CL_LogoutEffect(const org: vec3_t; type_: Integer);
procedure CL_ItemRespawnParticles(const org: vec3_t);
procedure CL_ParticleEffect(const org, dir: vec3_t; color, count: Integer);
procedure CL_EntityEvent(ent: entity_state_p);
procedure CL_TeleporterParticles(ent: entity_state_p);
procedure CL_RocketTrail(const start, end_: vec3_t; old: centity_p);
procedure CL_BlasterTrail(const start, end_: vec3_t);
procedure CL_DiminishingTrail(const start, end_: vec3_t; old: centity_p; flags: integer);
procedure CL_FlyEffect(ent: centity_p; const origin: vec3_t);
procedure CL_BfgParticles(ent: entity_p);
procedure CL_TrapParticles(ent: entity_p);
procedure CL_FlagTrail(const start, end_: vec3_t; color: single);
procedure CL_IonripperTrail(const start, ent: vec3_t);
procedure CL_AddParticles;
procedure CL_AddDLights;
procedure CL_AddLightStyles;
procedure CL_ClearEffects;
procedure CL_RunDLights;
procedure CL_RunLightStyles;
procedure CL_ParticleEffect2(const org, dir: vec3_t; color, count: integer);
procedure CL_RailTrail(const start, end_: vec3_t);
procedure CL_BubbleTrail(const start, end_: vec3_t);
procedure CL_BigTeleportParticles(const org: vec3_t);
procedure CL_ParticleEffect3(const org, dir: vec3_t; color, count: integer);
procedure CL_TeleportParticles(const org: vec3_t);
procedure CL_BlasterParticles(const org, dir: vec3_t);
procedure CL_ExplosionParticles(const org: vec3_t);
procedure CL_BFGExplosionParticles(const org: vec3_t);
function CL_AllocDlight(key: Integer): cdlight_p;
procedure CL_SetLightstyle(i: integer);
procedure MakeNormalVectors(var forward_, right, up: vec3_t);
procedure CL_ParseMuzzleFlash;
procedure CL_ParseMuzzleFlash2;

var
  avelocities: array[0..NUMVERTEXNORMALS - 1] of vec3_t;
  active_particles,
    free_particles: cparticle_p;

  particles: array[0..MAX_PARTICLES - 1] of cparticle_t;
  cl_numparticles: integer = MAX_PARTICLES;

  (*
  ==============================================================

  LIGHT STYLE MANAGEMENT

  ==============================================================
  *)

type
  clightstyle_p = ^clightstyle_t;
  clightstyle_t = record
    length: integer;
    value: array[0..2] of single;
    map: array[0..MAX_QPATH - 1] of single;
  end;
  pclightstyle_t = ^clightstyle_t;

var
  cl_lightstyle: array[0..MAX_LIGHTSTYLES - 1] of clightstyle_t;
  lastofs: integer;

implementation

uses
  cl_main,
  cl_view,
  net_chan,
  cl_tent,
  snd_dma;

(*
================
CL_ClearLightStyles
================
*)

procedure CL_ClearLightStyles;
begin
  FillChar(cl_lightstyle, sizeof(cl_lightstyle), 0);
  lastofs := -1;
end;

(*
================
CL_RunLightStyles
================
*)

procedure CL_RunLightStyles;
var
  ofs: integer;
  i: integer;
  ls: clightstyle_p;
label
  cont;
begin
  ofs := round(cl.time / 100);
  if (ofs = lastofs) then
    exit;
  lastofs := ofs;

  ls := @cl_lightstyle;
  i := 0;
  while (i < MAX_LIGHTSTYLES) do
  begin
    if (ls.length = 0) then
    begin
      ls.value[0] := 1.0;
      ls.value[1] := 1.0;
      ls.value[2] := 1.0;
      goto cont;
    end;
    if (ls.length = 1) then
    begin
      ls.value[0] := ls.map[0];
      ls.value[1] := ls.map[0];
      ls.value[2] := ls.map[0];
    end
    else
    begin
      ls.value[0] := ls.map[ofs mod ls.length];
      ls.value[1] := ls.map[ofs mod ls.length];
      ls.value[2] := ls.map[ofs mod ls.length];
    end;
    cont:
    Inc(i);
    Inc(ls);
  end;
end;

procedure CL_SetLightstyle(i: integer);
var
  s: pchar;
  j, k: integer;
begin
  s := cl.configstrings[i + CS_LIGHTS];

  j := strlen(s);
  if (j >= MAX_QPATH) then
    Com_Error(ERR_DROP, 'svc_lightstyle length=%d', [j]);

  cl_lightstyle[i].length := j;

  for k := 0 to j - 1 do
    cl_lightstyle[i].map[k] := (byte(s[k]) - byte('a')) / (byte('m') - byte('a'));
end;

(*
================
CL_AddLightStyles
================
*)

procedure CL_AddLightStyles;
var
  i: Integer;
  ls: clightstyle_p;
begin
  ls := @cl_lightstyle;
  for i := 0 to MAX_LIGHTSTYLES - 1 do
  begin
    V_AddLightStyle(i, ls.value[0], ls.value[1], ls.value[2]);
    Inc(ls);
  end;
end;

(*
==============================================================

DLIGHT MANAGEMENT

==============================================================
*)

var
  cl_dlights: array[0..MAX_DLIGHTS - 1] of cdlight_t;

  (*
  ================
  CL_ClearDlights
  ================
  *)

procedure CL_ClearDlights;
begin
  FillChar(cl_dlights, sizeof(cl_dlights), 0);
end;

(*
===============
CL_AllocDlight

===============
*)

function CL_AllocDlight(key: Integer): cdlight_p;
var
  i: Integer;
  dl: cdlight_p;
begin
  // first look for an exact key match
  if (key <> 0) then
  begin
    dl := @cl_dlights;
    for i := 0 to MAX_DLIGHTS - 1 do
    begin
      if (dl.key = key) then
      begin
        FillChar(dl^, sizeof(cdlight_t), 0);
        dl.key := key;
        Result := dl;
        exit;
      end;
      Inc(dl);
    end;
  end;

  // then look for anything else
  dl := @cl_dlights;
  for i := 0 to MAX_DLIGHTS - 1 do
  begin
    if (dl.die < cl.time) then
    begin
      FillChar(dl^, sizeof(cdlight_t), 0);
      dl.key := key;
      Result := dl;
      exit;
    end;
    Inc(dl);
  end;

  dl := @cl_dlights[0];
  FillChar(dl^, sizeof(cdlight_t), 0);
  dl.key := key;
  Result := dl;
end;

(*
===============
CL_NewDlight
===============
*)

procedure CL_NewDlight(key: Integer; x, y, z, radius: Single; time: Single);
var
  dl: cdlight_p;
begin
  dl := CL_AllocDlight(key);
  dl.origin[0] := x;
  dl.origin[1] := y;
  dl.origin[2] := z;
  dl.radius := radius;
  dl.die := cl.time + time;
end;

(*
===============
CL_RunDLights

===============
*)

procedure CL_RunDLights;
var
  i: Integer;
  dl: cdlight_p;
label
  continue_;
begin
  dl := @cl_dlights;
  for i := 0 to MAX_DLIGHTS - 1 do
  begin
    if (dl.radius = 0) then
      goto continue_;

    if (dl.die < cl.time) then
    begin
      dl.radius := 0;
      exit;
    end;
    dl.radius := dl.radius - cls.frametime * dl.decay;
    if (dl.radius < 0) then
      dl.radius := 0;
    continue_:
    Inc(dl);
  end;
end;

(*
==============
CL_ParseMuzzleFlash
==============
*)

procedure CL_ParseMuzzleFlash;
var
  fv, rv: vec3_t;
  dl: cdlight_p;
  i, weapon: Integer;
  pl: centity_p;
  silenced: Integer;
  volume: single;
  soundname: array[0..64 - 1] of char;
begin
  i := MSG_ReadShort(net_message);
  if (i < 1) or (i >= MAX_EDICTS) then
    Com_Error(ERR_DROP, 'CL_ParseMuzzleFlash: bad entity', []);

  weapon := MSG_ReadByte(net_message);
  silenced := weapon and MZ_SILENCED;
  weapon := weapon and not MZ_SILENCED;

  pl := @cl_entities[i];

  dl := CL_AllocDlight(i);
  VectorCopy(pl.current.origin, dl.origin);
  AngleVectors(pl.current.angles, @fv, @rv, nil);
  VectorMA(dl.origin, 18, fv, dl.origin);
  VectorMA(dl.origin, 16, rv, dl.origin);
  if (silenced <> 0) then
    dl.radius := 100 + (rand() and 31)
  else
    dl.radius := 200 + (rand() and 31);
  dl.minlight := 32;
  dl.die := cl.time;                    // + 0.1;

  if (silenced <> 0) then
    volume := 0.2
  else
    volume := 1;

  case weapon of
    MZ_BLASTER:
      begin
        dl.color[0] := 1;
        dl.color[1] := 1;
        dl.color[2] := 0;
        S_StartSound(nil, i, CHAN_WEAPON, S_RegisterSound('weapons/blastf1a.wav'), volume, ATTN_NORM, 0);
      end;
    MZ_BLUEHYPERBLASTER:
      begin
        dl.color[0] := 0;
        dl.color[1] := 0;
        dl.color[2] := 1;
        S_StartSound(nil, i, CHAN_WEAPON, S_RegisterSound('weapons/hyprbf1a.wav'), volume, ATTN_NORM, 0);
      end;
    MZ_HYPERBLASTER:
      begin
        dl.color[0] := 1;
        dl.color[1] := 1;
        dl.color[2] := 0;
        S_StartSound(nil, i, CHAN_WEAPON, S_RegisterSound('weapons/hyprbf1a.wav'), volume, ATTN_NORM, 0);
      end;
    MZ_MACHINEGUN:
      begin
        dl.color[0] := 1;
        dl.color[1] := 1;
        dl.color[2] := 0;
        Com_sprintf(soundname, sizeof(soundname), 'weapons/machgf%db.wav', [(rand() mod 5) + 1]);
        S_StartSound(nil, i, CHAN_WEAPON, S_RegisterSound(soundname), volume, ATTN_NORM, 0);
      end;
    MZ_SHOTGUN:
      begin
        dl.color[0] := 1;
        dl.color[1] := 1;
        dl.color[2] := 0;
        S_StartSound(nil, i, CHAN_WEAPON, S_RegisterSound('weapons/shotgf1b.wav'), volume, ATTN_NORM, 0);
        S_StartSound(nil, i, CHAN_AUTO, S_RegisterSound('weapons/shotgr1b.wav'), volume, ATTN_NORM, 0.1);
      end;
    MZ_SSHOTGUN:
      begin
        dl.color[0] := 1;
        dl.color[1] := 1;
        dl.color[2] := 0;
        S_StartSound(nil, i, CHAN_WEAPON, S_RegisterSound('weapons/sshotf1b.wav'), volume, ATTN_NORM, 0);
      end;
    MZ_CHAINGUN1:
      begin
        dl.radius := 200 + (rand() and 31);
        dl.color[0] := 1;
        dl.color[1] := 0.25;
        dl.color[2] := 0;
        Com_sprintf(soundname, sizeof(soundname), 'weapons/machgf%db.wav', [(rand() mod 5) + 1]);
        S_StartSound(nil, i, CHAN_WEAPON, S_RegisterSound(soundname), volume, ATTN_NORM, 0);
      end;
    MZ_CHAINGUN2:
      begin
        dl.radius := 225 + (rand() and 31);
        dl.color[0] := 1;
        dl.color[1] := 0.5;
        dl.color[2] := 0;
        dl.die := cl.time + 0.1;        // long delay
        Com_sprintf(soundname, sizeof(soundname), 'weapons/machgf%db.wav', [(rand() mod 5) + 1]);
        S_StartSound(nil, i, CHAN_WEAPON, S_RegisterSound(soundname), volume, ATTN_NORM, 0);
        Com_sprintf(soundname, sizeof(soundname), 'weapons/machgf%db.wav', [(rand() mod 5) + 1]);
        S_StartSound(nil, i, CHAN_WEAPON, S_RegisterSound(soundname), volume, ATTN_NORM, 0.05);
      end;
    MZ_CHAINGUN3:
      begin
        dl.radius := 250 + (rand() and 31);
        dl.color[0] := 1;
        dl.color[1] := 1;
        dl.color[2] := 0;
        dl.die := cl.time + 0.1;        // long delay
        Com_sprintf(soundname, sizeof(soundname), 'weapons/machgf%db.wav', [(rand() mod 5) + 1]);
        S_StartSound(nil, i, CHAN_WEAPON, S_RegisterSound(soundname), volume, ATTN_NORM, 0);
        Com_sprintf(soundname, sizeof(soundname), 'weapons/machgf%db.wav', [(rand() mod 5) + 1]);
        S_StartSound(nil, i, CHAN_WEAPON, S_RegisterSound(soundname), volume, ATTN_NORM, 0.033);
        Com_sprintf(soundname, sizeof(soundname), 'weapons/machgf%db.wav', [(rand() mod 5) + 1]);
        S_StartSound(nil, i, CHAN_WEAPON, S_RegisterSound(soundname), volume, ATTN_NORM, 0.066);
      end;
    MZ_RAILGUN:
      begin
        dl.color[0] := 0.5;
        dl.color[1] := 0.5;
        dl.color[2] := 1.0;
        S_StartSound(nil, i, CHAN_WEAPON, S_RegisterSound('weapons/railgf1a.wav'), volume, ATTN_NORM, 0);
      end;
    MZ_ROCKET:
      begin
        dl.color[0] := 1;
        dl.color[1] := 0.5;
        dl.color[2] := 0.2;
        S_StartSound(nil, i, CHAN_WEAPON, S_RegisterSound('weapons/rocklf1a.wav'), volume, ATTN_NORM, 0);
        S_StartSound(nil, i, CHAN_AUTO, S_RegisterSound('weapons/rocklr1b.wav'), volume, ATTN_NORM, 0.1);
      end;
    MZ_GRENADE:
      begin
        dl.color[0] := 1;
        dl.color[1] := 0.5;
        dl.color[2] := 0;
        S_StartSound(nil, i, CHAN_WEAPON, S_RegisterSound('weapons/grenlf1a.wav'), volume, ATTN_NORM, 0);
        S_StartSound(nil, i, CHAN_AUTO, S_RegisterSound('weapons/grenlr1b.wav'), volume, ATTN_NORM, 0.1);
      end;
    MZ_BFG:
      begin
        dl.color[0] := 0;
        dl.color[1] := 1;
        dl.color[2] := 0;
        S_StartSound(nil, i, CHAN_WEAPON, S_RegisterSound('weapons/bfg__f1y.wav'), volume, ATTN_NORM, 0);
      end;

    MZ_LOGIN:
      begin
        dl.color[0] := 0;
        dl.color[1] := 1;
        dl.color[2] := 0;
        dl.die := cl.time + 1.0;
        S_StartSound(nil, i, CHAN_WEAPON, S_RegisterSound('weapons/grenlf1a.wav'), 1, ATTN_NORM, 0);
        CL_LogoutEffect(pl.current.origin, weapon);
      end;
    MZ_LOGOUT:
      begin
        dl.color[0] := 1;
        dl.color[1] := 0;
        dl.color[2] := 0;
        dl.die := cl.time + 1.0;
        S_StartSound(nil, i, CHAN_WEAPON, S_RegisterSound('weapons/grenlf1a.wav'), 1, ATTN_NORM, 0);
        CL_LogoutEffect(pl.current.origin, weapon);
      end;
    MZ_RESPAWN:
      begin
        dl.color[0] := 1;
        dl.color[1] := 1;
        dl.color[2] := 0;
        dl.die := cl.time + 1.0;
        S_StartSound(nil, i, CHAN_WEAPON, S_RegisterSound('weapons/grenlf1a.wav'), 1, ATTN_NORM, 0);
        CL_LogoutEffect(pl.current.origin, weapon);
      end;
    // RAFAEL
    MZ_PHALANX:
      begin
        dl.color[0] := 1;
        dl.color[1] := 0.5;
        dl.color[2] := 0.5;
        S_StartSound(nil, i, CHAN_WEAPON, S_RegisterSound('weapons/plasshot.wav'), volume, ATTN_NORM, 0);
      end;
    // RAFAEL
    MZ_IONRIPPER:
      begin
        dl.color[0] := 1;
        dl.color[1] := 0.5;
        dl.color[2] := 0.5;
        S_StartSound(nil, i, CHAN_WEAPON, S_RegisterSound('weapons/rippfire.wav'), volume, ATTN_NORM, 0);
      end;

    // ===============================00
    // PGM
    MZ_ETF_RIFLE:
      begin
        dl.color[0] := 0.9;
        dl.color[1] := 0.7;
        dl.color[2] := 0;
        S_StartSound(nil, i, CHAN_WEAPON, S_RegisterSound('weapons/nail1.wav'), volume, ATTN_NORM, 0);
      end;
    MZ_SHOTGUN2:
      begin
        dl.color[0] := 1;
        dl.color[1] := 1;
        dl.color[2] := 0;
        S_StartSound(nil, i, CHAN_WEAPON, S_RegisterSound('weapons/shotg2.wav'), volume, ATTN_NORM, 0);
      end;
    MZ_HEATBEAM:
      begin
        dl.color[0] := 1;
        dl.color[1] := 1;
        dl.color[2] := 0;
        dl.die := cl.time + 100;
        //      S_StartSound (nil, i, CHAN_WEAPON, S_RegisterSound('weapons/bfg__l1a.wav'), volume, ATTN_NORM, 0);
      end;
    MZ_BLASTER2:
      begin
        dl.color[0] := 0;
        dl.color[1] := 1;
        dl.color[2] := 0;
        // FIXME - different sound for blaster2 ??
        S_StartSound(nil, i, CHAN_WEAPON, S_RegisterSound('weapons/blastf1a.wav'), volume, ATTN_NORM, 0);
      end;
    MZ_TRACKER:
      begin
        // negative flashes handled the same in gl/soft until CL_AddDLights
        dl.color[0] := -1;
        dl.color[1] := -1;
        dl.color[2] := -1;
        S_StartSound(nil, i, CHAN_WEAPON, S_RegisterSound('weapons/disint2.wav'), volume, ATTN_NORM, 0);
      end;
    MZ_NUKE1:
      begin
        dl.color[0] := 1;
        dl.color[1] := 0;
        dl.color[2] := 0;
        dl.die := cl.time + 100;
      end;
    MZ_NUKE2:
      begin
        dl.color[0] := 1;
        dl.color[1] := 1;
        dl.color[2] := 0;
        dl.die := cl.time + 100;
      end;
    MZ_NUKE4:
      begin
        dl.color[0] := 0;
        dl.color[1] := 0;
        dl.color[2] := 1;
        dl.die := cl.time + 100;
      end;
    MZ_NUKE8:
      begin
        dl.color[0] := 0;
        dl.color[1] := 1;
        dl.color[2] := 1;
        dl.die := cl.time + 100;
      end;
  end;
end;

(*
==============
CL_ParseMuzzleFlash2
==============
*)

procedure CL_ParseMuzzleFlash2;
var
  ent: Integer;
  origin: vec3_t;
  flash_number: integer;
  dl: cdlight_p;
  forward_, right: vec3_t;
  soundname: array[0..64 - 1] of char;
begin
  ent := MSG_ReadShort(net_message);
  if (ent < 1) or (ent >= MAX_EDICTS) then
    Com_Error(ERR_DROP, 'CL_ParseMuzzleFlash2: bad entity', []);

  flash_number := MSG_ReadByte(net_message);

  // locate the origin
  AngleVectors(cl_entities[ent].current.angles, @forward_, @right, nil);
  origin[0] := cl_entities[ent].current.origin[0] + forward_[0] * monster_flash_offset[flash_number][0] + right[0] * monster_flash_offset[flash_number][1];
  origin[1] := cl_entities[ent].current.origin[1] + forward_[1] * monster_flash_offset[flash_number][0] + right[1] * monster_flash_offset[flash_number][1];
  origin[2] := cl_entities[ent].current.origin[2] + forward_[2] * monster_flash_offset[flash_number][0] + right[2] * monster_flash_offset[flash_number][1] + monster_flash_offset[flash_number][2];

  dl := CL_AllocDlight(ent);
  VectorCopy(origin, dl.origin);
  dl.radius := 200 + (rand() and 31);
  dl.minlight := 32;
  dl.die := cl.time;                    // + 0.1;

  case flash_number of
    MZ2_INFANTRY_MACHINEGUN_1,
      MZ2_INFANTRY_MACHINEGUN_2,
      MZ2_INFANTRY_MACHINEGUN_3,
      MZ2_INFANTRY_MACHINEGUN_4,
      MZ2_INFANTRY_MACHINEGUN_5,
      MZ2_INFANTRY_MACHINEGUN_6,
      MZ2_INFANTRY_MACHINEGUN_7,
      MZ2_INFANTRY_MACHINEGUN_8,
      MZ2_INFANTRY_MACHINEGUN_9,
      MZ2_INFANTRY_MACHINEGUN_10,
      MZ2_INFANTRY_MACHINEGUN_11,
      MZ2_INFANTRY_MACHINEGUN_12,
      MZ2_INFANTRY_MACHINEGUN_13:
      begin
        dl.color[0] := 1;
        dl.color[1] := 1;
        dl.color[2] := 0;
        CL_ParticleEffect(origin, vec3_origin, 0, 40);
        CL_SmokeAndFlash(origin);
        S_StartSound(nil, ent, CHAN_WEAPON, S_RegisterSound('infantry/infatck1.wav'), 1, ATTN_NORM, 0);
      end;

    MZ2_SOLDIER_MACHINEGUN_1,
      MZ2_SOLDIER_MACHINEGUN_2,
      MZ2_SOLDIER_MACHINEGUN_3,
      MZ2_SOLDIER_MACHINEGUN_4,
      MZ2_SOLDIER_MACHINEGUN_5,
      MZ2_SOLDIER_MACHINEGUN_6,
      MZ2_SOLDIER_MACHINEGUN_7,
      MZ2_SOLDIER_MACHINEGUN_8:
      begin
        dl.color[0] := 1;
        dl.color[1] := 1;
        dl.color[2] := 0;
        CL_ParticleEffect(origin, vec3_origin, 0, 40);
        CL_SmokeAndFlash(origin);
        S_StartSound(nil, ent, CHAN_WEAPON, S_RegisterSound('soldier/solatck3.wav'), 1, ATTN_NORM, 0);
      end;

    MZ2_GUNNER_MACHINEGUN_1,
      MZ2_GUNNER_MACHINEGUN_2,
      MZ2_GUNNER_MACHINEGUN_3,
      MZ2_GUNNER_MACHINEGUN_4,
      MZ2_GUNNER_MACHINEGUN_5,
      MZ2_GUNNER_MACHINEGUN_6,
      MZ2_GUNNER_MACHINEGUN_7,
      MZ2_GUNNER_MACHINEGUN_8:
      begin
        dl.color[0] := 1;
        dl.color[1] := 1;
        dl.color[2] := 0;
        CL_ParticleEffect(origin, vec3_origin, 0, 40);
        CL_SmokeAndFlash(origin);
        S_StartSound(nil, ent, CHAN_WEAPON, S_RegisterSound('gunner/gunatck2.wav'), 1, ATTN_NORM, 0);
      end;

    MZ2_ACTOR_MACHINEGUN_1,
      MZ2_SUPERTANK_MACHINEGUN_1,
      MZ2_SUPERTANK_MACHINEGUN_2,
      MZ2_SUPERTANK_MACHINEGUN_3,
      MZ2_SUPERTANK_MACHINEGUN_4,
      MZ2_SUPERTANK_MACHINEGUN_5,
      MZ2_SUPERTANK_MACHINEGUN_6,
      MZ2_TURRET_MACHINEGUN:            // PGM
      begin
        dl.color[0] := 1;
        dl.color[1] := 1;
        dl.color[2] := 0;

        CL_ParticleEffect(origin, vec3_origin, 0, 40);
        CL_SmokeAndFlash(origin);
        S_StartSound(nil, ent, CHAN_WEAPON, S_RegisterSound('infantry/infatck1.wav'), 1, ATTN_NORM, 0);
      end;

    MZ2_BOSS2_MACHINEGUN_L1,
      MZ2_BOSS2_MACHINEGUN_L2,
      MZ2_BOSS2_MACHINEGUN_L3,
      MZ2_BOSS2_MACHINEGUN_L4,
      MZ2_BOSS2_MACHINEGUN_L5,
      MZ2_CARRIER_MACHINEGUN_L1,        // PMM
    MZ2_CARRIER_MACHINEGUN_L2:          // PMM
      begin
        dl.color[0] := 1;
        dl.color[1] := 1;
        dl.color[2] := 0;

        CL_ParticleEffect(origin, vec3_origin, 0, 40);
        CL_SmokeAndFlash(origin);
        S_StartSound(nil, ent, CHAN_WEAPON, S_RegisterSound('infantry/infatck1.wav'), 1, ATTN_NONE, 0);
      end;

    MZ2_SOLDIER_BLASTER_1,
      MZ2_SOLDIER_BLASTER_2,
      MZ2_SOLDIER_BLASTER_3,
      MZ2_SOLDIER_BLASTER_4,
      MZ2_SOLDIER_BLASTER_5,
      MZ2_SOLDIER_BLASTER_6,
      MZ2_SOLDIER_BLASTER_7,
      MZ2_SOLDIER_BLASTER_8,
      MZ2_TURRET_BLASTER:               // PGM
      begin
        dl.color[0] := 1;
        dl.color[1] := 1;
        dl.color[2] := 0;
        S_StartSound(nil, ent, CHAN_WEAPON, S_RegisterSound('soldier/solatck2.wav'), 1, ATTN_NORM, 0);
      end;

    MZ2_FLYER_BLASTER_1,
      MZ2_FLYER_BLASTER_2:
      begin
        dl.color[0] := 1;
        dl.color[1] := 1;
        dl.color[2] := 0;
        S_StartSound(nil, ent, CHAN_WEAPON, S_RegisterSound('flyer/flyatck3.wav'), 1, ATTN_NORM, 0);
      end;

    MZ2_MEDIC_BLASTER_1:
      begin
        dl.color[0] := 1;
        dl.color[1] := 1;
        dl.color[2] := 0;
        S_StartSound(nil, ent, CHAN_WEAPON, S_RegisterSound('medic/medatck1.wav'), 1, ATTN_NORM, 0);
      end;

    MZ2_HOVER_BLASTER_1:
      begin
        dl.color[0] := 1;
        dl.color[1] := 1;
        dl.color[2] := 0;
        S_StartSound(nil, ent, CHAN_WEAPON, S_RegisterSound('hover/hovatck1.wav'), 1, ATTN_NORM, 0);
      end;

    MZ2_FLOAT_BLASTER_1:
      begin
        dl.color[0] := 1;
        dl.color[1] := 1;
        dl.color[2] := 0;
        S_StartSound(nil, ent, CHAN_WEAPON, S_RegisterSound('floater/fltatck1.wav'), 1, ATTN_NORM, 0);
      end;

    MZ2_SOLDIER_SHOTGUN_1,
      MZ2_SOLDIER_SHOTGUN_2,
      MZ2_SOLDIER_SHOTGUN_3,
      MZ2_SOLDIER_SHOTGUN_4,
      MZ2_SOLDIER_SHOTGUN_5,
      MZ2_SOLDIER_SHOTGUN_6,
      MZ2_SOLDIER_SHOTGUN_7,
      MZ2_SOLDIER_SHOTGUN_8:
      begin
        dl.color[0] := 1;
        dl.color[1] := 1;
        dl.color[2] := 0;
        CL_SmokeAndFlash(origin);
        S_StartSound(nil, ent, CHAN_WEAPON, S_RegisterSound('soldier/solatck1.wav'), 1, ATTN_NORM, 0);
      end;

    MZ2_TANK_BLASTER_1,
      MZ2_TANK_BLASTER_2,
      MZ2_TANK_BLASTER_3:
      begin
        dl.color[0] := 1;
        dl.color[1] := 1;
        dl.color[2] := 0;
        S_StartSound(nil, ent, CHAN_WEAPON, S_RegisterSound('tank/tnkatck3.wav'), 1, ATTN_NORM, 0);
      end;

    MZ2_TANK_MACHINEGUN_1,
      MZ2_TANK_MACHINEGUN_2,
      MZ2_TANK_MACHINEGUN_3,
      MZ2_TANK_MACHINEGUN_4,
      MZ2_TANK_MACHINEGUN_5,
      MZ2_TANK_MACHINEGUN_6,
      MZ2_TANK_MACHINEGUN_7,
      MZ2_TANK_MACHINEGUN_8,
      MZ2_TANK_MACHINEGUN_9,
      MZ2_TANK_MACHINEGUN_10,
      MZ2_TANK_MACHINEGUN_11,
      MZ2_TANK_MACHINEGUN_12,
      MZ2_TANK_MACHINEGUN_13,
      MZ2_TANK_MACHINEGUN_14,
      MZ2_TANK_MACHINEGUN_15,
      MZ2_TANK_MACHINEGUN_16,
      MZ2_TANK_MACHINEGUN_17,
      MZ2_TANK_MACHINEGUN_18,
      MZ2_TANK_MACHINEGUN_19:
      begin
        dl.color[0] := 1;
        dl.color[1] := 1;
        dl.color[2] := 0;
        CL_ParticleEffect(origin, vec3_origin, 0, 40);
        CL_SmokeAndFlash(origin);
        Com_sprintf(soundname, sizeof(soundname), 'tank/tnkatk2%c.wav', [char(byte('a') + rand() mod 5)]);
        S_StartSound(nil, ent, CHAN_WEAPON, S_RegisterSound(soundname), 1, ATTN_NORM, 0);
      end;

    MZ2_CHICK_ROCKET_1,
      MZ2_TURRET_ROCKET:                // PGM
      begin
        dl.color[0] := 1;
        dl.color[1] := 0.5;
        dl.color[2] := 0.2;
        S_StartSound(nil, ent, CHAN_WEAPON, S_RegisterSound('chick/chkatck2.wav'), 1, ATTN_NORM, 0);
      end;

    MZ2_TANK_ROCKET_1,
      MZ2_TANK_ROCKET_2,
      MZ2_TANK_ROCKET_3:
      begin
        dl.color[0] := 1;
        dl.color[1] := 0.5;
        dl.color[2] := 0.2;
        S_StartSound(nil, ent, CHAN_WEAPON, S_RegisterSound('tank/tnkatck1.wav'), 1, ATTN_NORM, 0);
      end;

    MZ2_SUPERTANK_ROCKET_1,
      MZ2_SUPERTANK_ROCKET_2,
      MZ2_SUPERTANK_ROCKET_3,
      MZ2_BOSS2_ROCKET_1,
      MZ2_BOSS2_ROCKET_2,
      MZ2_BOSS2_ROCKET_3,
      MZ2_BOSS2_ROCKET_4,
      MZ2_CARRIER_ROCKET_1:
      //   MZ2_CARRIER_ROCKET_2:
      //   MZ2_CARRIER_ROCKET_3:
      //   MZ2_CARRIER_ROCKET_4:
      begin
        dl.color[0] := 1;
        dl.color[1] := 0.5;
        dl.color[2] := 0.2;
        S_StartSound(nil, ent, CHAN_WEAPON, S_RegisterSound('tank/rocket.wav'), 1, ATTN_NORM, 0);
      end;

    MZ2_GUNNER_GRENADE_1,
      MZ2_GUNNER_GRENADE_2,
      MZ2_GUNNER_GRENADE_3,
      MZ2_GUNNER_GRENADE_4:
      begin
        dl.color[0] := 1;
        dl.color[1] := 0.5;
        dl.color[2] := 0;
        S_StartSound(nil, ent, CHAN_WEAPON, S_RegisterSound('gunner/gunatck3.wav'), 1, ATTN_NORM, 0);
      end;

    MZ2_GLADIATOR_RAILGUN_1,
      // PMM
    MZ2_CARRIER_RAILGUN,
      MZ2_WIDOW_RAIL:
      // pmm
      begin
        dl.color[0] := 0.5;
        dl.color[1] := 0.5;
        dl.color[2] := 1.0;
      end;

    // --- Xian's shit starts ---
    MZ2_MAKRON_BFG:
      begin
        dl.color[0] := 0.5;
        dl.color[1] := 1;
        dl.color[2] := 0.5;
        //S_StartSound (nil, ent, CHAN_WEAPON, S_RegisterSound('makron/bfg_fire.wav'), 1, ATTN_NORM, 0);
      end;

    MZ2_MAKRON_BLASTER_1,
      MZ2_MAKRON_BLASTER_2,
      MZ2_MAKRON_BLASTER_3,
      MZ2_MAKRON_BLASTER_4,
      MZ2_MAKRON_BLASTER_5,
      MZ2_MAKRON_BLASTER_6,
      MZ2_MAKRON_BLASTER_7,
      MZ2_MAKRON_BLASTER_8,
      MZ2_MAKRON_BLASTER_9,
      MZ2_MAKRON_BLASTER_10,
      MZ2_MAKRON_BLASTER_11,
      MZ2_MAKRON_BLASTER_12,
      MZ2_MAKRON_BLASTER_13,
      MZ2_MAKRON_BLASTER_14,
      MZ2_MAKRON_BLASTER_15,
      MZ2_MAKRON_BLASTER_16,
      MZ2_MAKRON_BLASTER_17:
      begin
        dl.color[0] := 1;
        dl.color[1] := 1;
        dl.color[2] := 0;
        S_StartSound(nil, ent, CHAN_WEAPON, S_RegisterSound('makron/blaster.wav'), 1, ATTN_NORM, 0);
      end;

    MZ2_JORG_MACHINEGUN_L1,
      MZ2_JORG_MACHINEGUN_L2,
      MZ2_JORG_MACHINEGUN_L3,
      MZ2_JORG_MACHINEGUN_L4,
      MZ2_JORG_MACHINEGUN_L5,
      MZ2_JORG_MACHINEGUN_L6:
      begin
        dl.color[0] := 1;
        dl.color[1] := 1;
        dl.color[2] := 0;
        CL_ParticleEffect(origin, vec3_origin, 0, 40);
        CL_SmokeAndFlash(origin);
        S_StartSound(nil, ent, CHAN_WEAPON, S_RegisterSound('boss3/xfire.wav'), 1, ATTN_NORM, 0);
      end;

    MZ2_JORG_MACHINEGUN_R1,
      MZ2_JORG_MACHINEGUN_R2,
      MZ2_JORG_MACHINEGUN_R3,
      MZ2_JORG_MACHINEGUN_R4,
      MZ2_JORG_MACHINEGUN_R5,
      MZ2_JORG_MACHINEGUN_R6:
      begin
        dl.color[0] := 1;
        dl.color[1] := 1;
        dl.color[2] := 0;
        CL_ParticleEffect(origin, vec3_origin, 0, 40);
        CL_SmokeAndFlash(origin);
      end;

    MZ2_JORG_BFG_1:
      begin
        dl.color[0] := 0.5;
        dl.color[1] := 1;
        dl.color[2] := 0.5;
      end;

    MZ2_BOSS2_MACHINEGUN_R1,
      MZ2_BOSS2_MACHINEGUN_R2,
      MZ2_BOSS2_MACHINEGUN_R3,
      MZ2_BOSS2_MACHINEGUN_R4,
      MZ2_BOSS2_MACHINEGUN_R5,
      MZ2_CARRIER_MACHINEGUN_R1,        // PMM
    MZ2_CARRIER_MACHINEGUN_R2:          // PMM
      begin
        dl.color[0] := 1;
        dl.color[1] := 1;
        dl.color[2] := 0;

        CL_ParticleEffect(origin, vec3_origin, 0, 40);
        CL_SmokeAndFlash(origin);
      end;

    // ======
    // ROGUE
    MZ2_STALKER_BLASTER,
      MZ2_DAEDALUS_BLASTER,
      MZ2_MEDIC_BLASTER_2,
      MZ2_WIDOW_BLASTER,
      MZ2_WIDOW_BLASTER_SWEEP1,
      MZ2_WIDOW_BLASTER_SWEEP2,
      MZ2_WIDOW_BLASTER_SWEEP3,
      MZ2_WIDOW_BLASTER_SWEEP4,
      MZ2_WIDOW_BLASTER_SWEEP5,
      MZ2_WIDOW_BLASTER_SWEEP6,
      MZ2_WIDOW_BLASTER_SWEEP7,
      MZ2_WIDOW_BLASTER_SWEEP8,
      MZ2_WIDOW_BLASTER_SWEEP9,
      MZ2_WIDOW_BLASTER_100,
      MZ2_WIDOW_BLASTER_90,
      MZ2_WIDOW_BLASTER_80,
      MZ2_WIDOW_BLASTER_70,
      MZ2_WIDOW_BLASTER_60,
      MZ2_WIDOW_BLASTER_50,
      MZ2_WIDOW_BLASTER_40,
      MZ2_WIDOW_BLASTER_30,
      MZ2_WIDOW_BLASTER_20,
      MZ2_WIDOW_BLASTER_10,
      MZ2_WIDOW_BLASTER_0,
      MZ2_WIDOW_BLASTER_10L,
      MZ2_WIDOW_BLASTER_20L,
      MZ2_WIDOW_BLASTER_30L,
      MZ2_WIDOW_BLASTER_40L,
      MZ2_WIDOW_BLASTER_50L,
      MZ2_WIDOW_BLASTER_60L,
      MZ2_WIDOW_BLASTER_70L,
      MZ2_WIDOW_RUN_1,
      MZ2_WIDOW_RUN_2,
      MZ2_WIDOW_RUN_3,
      MZ2_WIDOW_RUN_4,
      MZ2_WIDOW_RUN_5,
      MZ2_WIDOW_RUN_6,
      MZ2_WIDOW_RUN_7,
      MZ2_WIDOW_RUN_8:
      begin
        dl.color[0] := 0;
        dl.color[1] := 1;
        dl.color[2] := 0;
        S_StartSound(nil, ent, CHAN_WEAPON, S_RegisterSound('tank/tnkatck3.wav'), 1, ATTN_NORM, 0);
      end;

    MZ2_WIDOW_DISRUPTOR:
      begin
        dl.color[0] := -1;
        dl.color[1] := -1;
        dl.color[2] := -1;
        S_StartSound(nil, ent, CHAN_WEAPON, S_RegisterSound('weapons/disint2.wav'), 1, ATTN_NORM, 0);
      end;

    MZ2_WIDOW_PLASMABEAM,
      MZ2_WIDOW2_BEAMER_1,
      MZ2_WIDOW2_BEAMER_2,
      MZ2_WIDOW2_BEAMER_3,
      MZ2_WIDOW2_BEAMER_4,
      MZ2_WIDOW2_BEAMER_5,
      MZ2_WIDOW2_BEAM_SWEEP_1,
      MZ2_WIDOW2_BEAM_SWEEP_2,
      MZ2_WIDOW2_BEAM_SWEEP_3,
      MZ2_WIDOW2_BEAM_SWEEP_4,
      MZ2_WIDOW2_BEAM_SWEEP_5,
      MZ2_WIDOW2_BEAM_SWEEP_6,
      MZ2_WIDOW2_BEAM_SWEEP_7,
      MZ2_WIDOW2_BEAM_SWEEP_8,
      MZ2_WIDOW2_BEAM_SWEEP_9,
      MZ2_WIDOW2_BEAM_SWEEP_10,
      MZ2_WIDOW2_BEAM_SWEEP_11:
      begin
        dl.radius := 300 + (rand() and 100);
        dl.color[0] := 1;
        dl.color[1] := 1;
        dl.color[2] := 0;
        dl.die := cl.time + 200;
      end;
    // ROGUE
    // ======

    // --- Xian's shit ends ---

  end;
end;

(*
===============
CL_AddDLights

===============
*)

procedure CL_AddDLights;
var
  i: integer;
  dl: cdlight_p;
label
  continue1, continue2;
begin
  dl := @cl_dlights;

  //=====
  //PGM
  if (vidref_val = VIDREF_GL) then
  begin
    for i := 0 to MAX_DLIGHTS - 1 do
    begin
      if (dl.radius = 0) then
        goto continue1;
      V_AddLight(dl.origin, dl.radius,
        dl.color[0], dl.color[1], dl.color[2]);
      continue1:
      Inc(dl);
    end;
  end
  else
  begin
    for i := 0 to MAX_DLIGHTS - 1 do
    begin
      if (dl.radius = 0) then
        goto continue2;

      // negative light in software. only black allowed
      if ((dl.color[0] < 0) or (dl.color[1] < 0) or (dl.color[2] < 0)) then
      begin
        dl.radius := -(dl.radius);
        dl.color[0] := 1;
        dl.color[1] := 1;
        dl.color[2] := 1;
      end;
      V_AddLight(dl.origin, dl.radius,
        dl.color[0], dl.color[1], dl.color[2]);
      continue2:
      Inc(dl);
    end;
  end;
  //PGM
  //=====
end;

(*
==============================================================

PARTICLE MANAGEMENT

==============================================================
*)

  (*
  ===============
  CL_ClearParticles
  ===============
  *)

procedure CL_ClearParticles;
var
  i: integer;
begin
  free_particles := @particles[0];
  active_particles := nil;

  for i := 0 to cl_numparticles - 2 do
    particles[i].next := @particles[i + 1];
  particles[cl_numparticles - 1].next := nil;
end;

(*
===============
CL_ParticleEffect

Wall impact puffs
===============
*)

procedure CL_ParticleEffect(const org, dir: vec3_t; color, count: Integer);
var
  i, j: integer;
  p: cparticle_p;
  d: single;
begin
  for i := 0 to count - 1 do
  begin
    if (free_particles = nil) then
      exit;
    p := free_particles;
    free_particles := p.next;
    p.next := active_particles;
    active_particles := p;

    p.time := cl.time;
    p.color := color + (rand() and 7);

    d := rand() and 31;
    for j := 0 to 2 do
    begin
      p.org[j] := org[j] + ((rand() and 7) - 4) + d * dir[j];
      p.vel[j] := crand() * 20;
    end;

    p.accel[0] := 0;
    p.accel[1] := 0;
    p.accel[2] := -PARTICLE_GRAVITY;
    p.alpha := 1.0;

    p.alphavel := -1.0 / (0.5 + frand() * 0.3);
  end;
end;

(*
===============
CL_ParticleEffect2
===============
*)

procedure CL_ParticleEffect2(const org, dir: vec3_t; color, count: integer);
var
  i, j: integer;
  p: cparticle_p;
  d: single;
begin
  for i := 0 to count - 1 do
  begin
    if (free_particles = nil) then
      exit;
    p := free_particles;
    free_particles := p.next;
    p.next := active_particles;
    active_particles := p;

    p.time := cl.time;
    p.color := color;

    d := rand() and 7;
    for j := 0 to 2 do
    begin
      p.org[j] := org[j] + ((rand() and 7) - 4) + d * dir[j];
      p.vel[j] := crand() * 20;
    end;

    p.accel[0] := 0;
    p.accel[1] := 0;
    p.accel[2] := -PARTICLE_GRAVITY;
    p.alpha := 1.0;

    p.alphavel := -1.0 / (0.5 + frand() * 0.3);
  end;
end;

// RAFAEL
(*
===============
CL_ParticleEffect3
===============
*)

procedure CL_ParticleEffect3(const org, dir: vec3_t; color, count: integer);
var
  i, j: integer;
  p: cparticle_p;
  d: single;
begin
  for i := 0 to count - 1 do
  begin
    if (free_particles = nil) then
      exit;
    p := free_particles;
    free_particles := p.next;
    p.next := active_particles;
    active_particles := p;

    p.time := cl.time;
    p.color := color;

    d := rand() and 7;
    for j := 0 to 2 do
    begin
      p.org[j] := org[j] + ((rand() and 7) - 4) + d * dir[j];
      p.vel[j] := crand() * 20;
    end;

    p.accel[0] := 0;
    p.accel[1] := 0;
    p.accel[2] := PARTICLE_GRAVITY;
    p.alpha := 1.0;

    p.alphavel := -1.0 / (0.5 + frand() * 0.3);
  end;
end;

(*
===============
CL_TeleporterParticles
===============
*)

procedure CL_TeleporterParticles(ent: entity_state_p);
var
  i, j: integer;
  p: cparticle_p;
begin
  for i := 0 to 7 do
  begin
    if (free_particles = nil) then
      exit;
    p := free_particles;
    free_particles := p.next;
    p.next := active_particles;
    active_particles := p;

    p.time := cl.time;
    p.color := $DB;

    for j := 0 to 1 do
    begin
      p.org[j] := ent.origin[j] - 16 + (rand() and 31);
      p.vel[j] := crand() * 14;
    end;

    p.org[2] := ent.origin[2] - 8 + (rand() and 7);
    p.vel[2] := 80 + (rand() and 7);

    p.accel[0] := 0;
    p.accel[1] := 0;
    p.accel[2] := -PARTICLE_GRAVITY;
    p.alpha := 1.0;

    p.alphavel := -0.5;
  end;
end;

(*
===============
CL_LogoutEffect

===============
*)

procedure CL_LogoutEffect(const org: vec3_t; type_: integer);
var
  i, j: integer;
  p: cparticle_p;
begin
  for i := 0 to 500 - 1 do
  begin
    if (free_particles = nil) then
      exit;
    p := free_particles;
    free_particles := p.next;
    p.next := active_particles;
    active_particles := p;

    p.time := cl.time;

    if (type_ = MZ_LOGIN) then
      p.color := $D0 + (rand() and 7)   // green
    else if (type_ = MZ_LOGOUT) then
      p.color := $40 + (rand() and 7)   // red
    else
      p.color := $E0 + (rand() and 7);  // yellow

    p.org[0] := org[0] - 16 + frand() * 32;
    p.org[1] := org[1] - 16 + frand() * 32;
    p.org[2] := org[2] - 24 + frand() * 56;

    for j := 0 to 2 do
      p.vel[j] := crand() * 20;

    p.accel[0] := 0;
    p.accel[1] := 0;
    p.accel[2] := -PARTICLE_GRAVITY;
    p.alpha := 1.0;

    p.alphavel := -1.0 / (1.0 + frand() * 0.3);
  end;
end;

(*
===============
CL_ItemRespawnParticles

===============
*)

procedure CL_ItemRespawnParticles(const org: vec3_t);
var
  i, j: integer;
  p: cparticle_p;
begin
  for i := 0 to 64 - 1 do
  begin
    if (free_particles = nil) then
      exit;
    p := free_particles;
    free_particles := p.next;
    p.next := active_particles;
    active_particles := p;

    p.time := cl.time;

    p.color := $D4 + (rand() and 3);    // green

    p.org[0] := org[0] + crand() * 8;
    p.org[1] := org[1] + crand() * 8;
    p.org[2] := org[2] + crand() * 8;

    for j := 0 to 2 do
      p.vel[j] := crand() * 8;

    p.accel[0] := 0;
    p.accel[1] := 0;
    p.accel[2] := -PARTICLE_GRAVITY * 0.2;
    p.alpha := 1.0;

    p.alphavel := -1.0 / (1.0 + frand() * 0.3);
  end;
end;

(*
===============
CL_ExplosionParticles
===============
*)

procedure CL_ExplosionParticles(const org: vec3_t);
var
  i, j: integer;
  p: cparticle_p;
begin
  for i := 0 to 256 - 1 do
  begin
    if (free_particles = nil) then
      exit;
    p := free_particles;
    free_particles := p.next;
    p.next := active_particles;
    active_particles := p;

    p.time := cl.time;
    p.color := $E0 + (rand() and 7);

    for j := 0 to 2 do
    begin
      p.org[j] := org[j] + ((rand() mod 32) - 16);
      p.vel[j] := (rand() mod 384) - 192;
    end;

    p.accel[0] := 0;
    p.accel[1] := 0;
    p.accel[2] := -PARTICLE_GRAVITY;
    p.alpha := 1.0;

    p.alphavel := -0.8 / (0.5 + frand() * 0.3);
  end;
end;

(*
===============
CL_BigTeleportParticles
===============
*)

var
  colortable: array[0..3] of integer = (2 * 8, 13 * 8, 21 * 8, 18 * 8);

procedure CL_BigTeleportParticles(const org: vec3_t);
var
  i: integer;
  p: cparticle_p;
  angle, dist: single;
begin
  for i := 0 to 4096 - 1 do
  begin
    if (free_particles = nil) then
      exit;
    p := free_particles;
    free_particles := p.next;
    p.next := active_particles;
    active_particles := p;

    p.time := cl.time;

    p.color := colortable[rand() and 3];

    angle := M_PI * 2 * (rand() and 1023) / 1023.0;
    dist := rand() and 31;
    p.org[0] := org[0] + cos(angle) * dist;
    p.vel[0] := cos(angle) * (70 + (rand() and 63));
    p.accel[0] := -cos(angle) * 100;

    p.org[1] := org[1] + sin(angle) * dist;
    p.vel[1] := sin(angle) * (70 + (rand() and 63));
    p.accel[1] := -sin(angle) * 100;

    p.org[2] := org[2] + 8 + (rand() mod 90);
    p.vel[2] := -100 + (rand() and 31);
    p.accel[2] := PARTICLE_GRAVITY * 4;
    p.alpha := 1.0;

    p.alphavel := -0.3 / (0.5 + frand() * 0.3);
  end;
end;

(*
===============
CL_BlasterParticles

Wall impact puffs
===============
*)

procedure CL_BlasterParticles(const org, dir: vec3_t);
var
  i, j: integer;
  p: cparticle_p;
  d: single;
  count: integer;
begin
  count := 40;
  for i := 0 to count - 1 do
  begin
    if (free_particles = nil) then
      exit;
    p := free_particles;
    free_particles := p.next;
    p.next := active_particles;
    active_particles := p;

    p.time := cl.time;
    p.color := $E0 + (rand() and 7);

    d := rand() and 15;
    for j := 0 to 2 do
    begin
      p.org[j] := org[j] + ((rand() and 7) - 4) + d * dir[j];
      p.vel[j] := dir[j] * 30 + crand() * 40;
    end;

    p.accel[0] := 0;
    p.accel[1] := 0;
    p.accel[2] := -PARTICLE_GRAVITY;
    p.alpha := 1.0;

    p.alphavel := -1.0 / (0.5 + frand() * 0.3);
  end;
end;

(*
===============
CL_BlasterTrail

===============
*)

procedure CL_BlasterTrail(const start, end_: vec3_t);
var
  move, vec: vec3_t;
  len: single;
  j: integer;
  p: cparticle_p;
  dec: integer;
begin
  VectorCopy(start, move);
  VectorSubtract(end_, start, vec);
  len := VectorNormalize(vec);

  dec := 5;
  VectorScale(vec, 5, vec);

  // FIXME: this is a really silly way to have a loop
  while (len > 0) do
  begin
    len := len - dec;

    if (free_particles = nil) then
      exit;
    p := free_particles;
    free_particles := p.next;
    p.next := active_particles;
    active_particles := p;
    VectorClear(p.accel);

    p.time := cl.time;

    p.alpha := 1.0;
    p.alphavel := -1.0 / (0.3 + frand() * 0.2);
    p.color := $E0;
    for j := 0 to 2 do
    begin
      p.org[j] := move[j] + crand();
      p.vel[j] := crand() * 5;
      p.accel[j] := 0;
    end;

    VectorAdd(move, vec, move);
  end;
end;

(*
===============
CL_QuadTrail

===============
*)

procedure CL_QuadTrail(const start, end_: vec3_t);
var
  move, vec: vec3_t;
  len: single;
  j: integer;
  p: cparticle_p;
  dec: integer;
begin
  VectorCopy(start, move);
  VectorSubtract(end_, start, vec);
  len := VectorNormalize(vec);

  dec := 5;
  VectorScale(vec, 5, vec);

  while (len > 0) do
  begin
    len := len - dec;

    if (free_particles = nil) then
      exit;
    p := free_particles;
    free_particles := p.next;
    p.next := active_particles;
    active_particles := p;
    VectorClear(p.accel);

    p.time := cl.time;

    p.alpha := 1.0;
    p.alphavel := -1.0 / (0.8 + frand() * 0.2);
    p.color := 115;
    for j := 0 to 2 do
    begin
      p.org[j] := move[j] + crand() * 16;
      p.vel[j] := crand() * 5;
      p.accel[j] := 0;
    end;

    VectorAdd(move, vec, move);
  end;
end;

(*
===============
CL_FlagTrail

===============
*)

procedure CL_FlagTrail(const start, end_: vec3_t; color: single);
var
  move: vec3_t;
  vec: vec3_t;
  len: single;
  j: integer;
  p: cparticle_p;
  dec_: integer;
begin
  VectorCopy(start, move);
  VectorSubtract(end_, start, vec);
  len := VectorNormalize(vec);

  dec_ := 5;
  VectorScale(vec, 5, vec);

  while (len > 0) do
  begin
    len := len - dec_;

    if (free_particles = nil) then
      exit;
    p := free_particles;
    free_particles := p.next;
    p.next := active_particles;
    active_particles := p;
    VectorClear(p.accel);

    p.time := cl.time;

    p.alpha := 1.0;
    p.alphavel := -1.0 / (0.8 + frand() * 0.2);
    p.color := color;
    for j := 0 to 2 do
    begin
      p.org[j] := move[j] + crand() * 16;
      p.vel[j] := crand() * 5;
      p.accel[j] := 0;
    end;

    VectorAdd(move, vec, move);
  end;
end;

(*
===============
CL_DiminishingTrail

===============
*)

procedure CL_DiminishingTrail(const start, end_: vec3_t; old: centity_p; flags: integer);
var
  move_: vec3_t;
  vec: vec3_t;
  len: single;
  j: integer;
  p: cparticle_p;
  dec_,
    orgscale,
    velscale: single;
begin
  VectorCopy(start, move_);
  VectorSubtract(end_, start, vec);
  len := VectorNormalize(vec);

  dec_ := 0.5;
  VectorScale(vec, dec_, vec);

  if (old.trailcount > 900) then
  begin
    orgscale := 4;
    velscale := 15;
  end
  else if (old.trailcount > 800) then
  begin
    orgscale := 2;
    velscale := 10;
  end
  else
  begin
    orgscale := 1;
    velscale := 5;
  end;

  while (len > 0) do
  begin
    len := len - dec_;

    if (free_particles = nil) then
      exit;

    // drop less particles as it flies
    if ((rand() and 1023) < old.trailcount) then
    begin
      p := free_particles;
      free_particles := p.next;
      p.next := active_particles;
      active_particles := p;
      VectorClear(p.accel);

      p.time := cl.time;

      if (flags and EF_GIB <> 0) then
      begin
        p.alpha := 1.0;
        p.alphavel := -1.0 / (1 + frand() * 0.4);
        p.color := $E8 + (rand() and 7);
        for j := 0 to 2 do
        begin
          p.org[j] := move_[j] + crand() * orgscale;
          p.vel[j] := crand() * velscale;
          p.accel[j] := 0;
        end;
        p.vel[2] := p.vel[2] - PARTICLE_GRAVITY;
      end
      else if (flags and EF_GREENGIB <> 0) then
      begin
        p.alpha := 1.0;
        p.alphavel := -1.0 / (1 + frand() * 0.4);
        p.color := $DB + (rand() and 7);
        for j := 0 to 2 do
        begin
          p.org[j] := move_[j] + crand() * orgscale;
          p.vel[j] := crand() * velscale;
          p.accel[j] := 0;
        end;
        p.vel[2] := p.vel[2] - PARTICLE_GRAVITY;
      end
      else
      begin
        p.alpha := 1.0;
        p.alphavel := -1.0 / (1 + frand() * 0.2);
        p.color := 4 + (rand() and 7);
        for j := 0 to 2 do
        begin
          p.org[j] := move_[j] + crand() * orgscale;
          p.vel[j] := crand() * velscale;
        end;
        p.accel[2] := 20;
      end;
    end;

    old.trailcount := old.trailcount - 5;
    if (old.trailcount < 100) then
      old.trailcount := 100;
    VectorAdd(move_, vec, move_);
  end;
end;

procedure MakeNormalVectors(var forward_, right, up: vec3_t);
var
  d: single;
begin
  // this rotate and negat guarantees a vector
  // not colinear with the original
  right[1] := -forward_[0];
  right[2] := forward_[1];
  right[0] := forward_[2];

  d := DotProduct(right, forward_);
  VectorMA(right, -d, forward_, right);
  VectorNormalize(right);
  CrossProduct(right, forward_, up);
end;

(*
===============
CL_RocketTrail

===============
*)

procedure CL_RocketTrail(const start, end_: vec3_t; old: centity_p);
var
  move, vec: vec3_t;
  len: single;
  j: integer;
  p: cparticle_p;
  dec: single;
begin
  // smoke
  CL_DiminishingTrail(start, end_, old, EF_ROCKET);

  // fire
  VectorCopy(start, move);
  VectorSubtract(end_, start, vec);
  len := VectorNormalize(vec);

  dec := 1;
  VectorScale(vec, dec, vec);

  while (len > 0) do
  begin
    len := len - dec;

    if (free_particles = nil) then
      exit;

    if ((rand() and 7) = 0) then
    begin
      p := free_particles;
      free_particles := p.next;
      p.next := active_particles;
      active_particles := p;

      VectorClear(p.accel);
      p.time := cl.time;

      p.alpha := 1.0;
      p.alphavel := -1.0 / (1 + frand() * 0.2);
      p.color := $DC + (rand() and 3);
      for j := 0 to 2 do
      begin
        p.org[j] := move[j] + crand() * 5;
        p.vel[j] := crand() * 20;
      end;
      p.accel[2] := -PARTICLE_GRAVITY;
    end;
    VectorAdd(move, vec, move);
  end;
end;

(*
===============
CL_RailTrail

===============
*)

procedure CL_RailTrail(const start, end_: vec3_t);
var
  move, vec: vec3_t;
  len: single;
  j: integer;
  p: cparticle_p;
  dec: single;
  right, up: vec3_t;
  i: integer;
  d, c, s: single;
  dir: vec3_t;
  clr: byte;
begin
  clr := $74;
  VectorCopy(start, move);
  VectorSubtract(end_, start, vec);
  len := VectorNormalize(vec);

  MakeNormalVectors(vec, right, up);

  for i := 0 to round(len) - 1 do
  begin
    if (free_particles = nil) then
      exit;

    p := free_particles;
    free_particles := p.next;
    p.next := active_particles;
    active_particles := p;

    p.time := cl.time;
    VectorClear(p.accel);

    d := i * 0.1;
    c := cos(d);
    s := sin(d);

    VectorScale(right, c, dir);
    VectorMA(dir, s, up, dir);

    p.alpha := 1.0;
    p.alphavel := -1.0 / (1 + frand() * 0.2);
    p.color := clr + (rand() and 7);
    for j := 0 to 2 do
    begin
      p.org[j] := move[j] + dir[j] * 3;
      p.vel[j] := dir[j] * 6;
    end;

    VectorAdd(move, vec, move);
  end;

  dec := 0.75;
  VectorScale(vec, dec, vec);
  VectorCopy(start, move);

  while (len > 0) do
  begin
    len := len - dec;

    if (free_particles = nil) then
      exit;
    p := free_particles;
    free_particles := p.next;
    p.next := active_particles;
    active_particles := p;

    p.time := cl.time;
    VectorClear(p.accel);

    p.alpha := 1.0;
    p.alphavel := -1.0 / (0.6 + frand() * 0.2);
    p.color := $0 + rand() and 15;

    for j := 0 to 2 do
    begin
      p.org[j] := move[j] + crand() * 3;
      p.vel[j] := crand() * 3;
      p.accel[j] := 0;
    end;

    VectorAdd(move, vec, move);
  end;
end;

// RAFAEL
(*
===============
CL_IonripperTrail
===============
*)

procedure CL_IonripperTrail(const start, ent: vec3_t);
var
  move, vec: vec3_t;
  len: single;
  j: integer;
  p: cparticle_p;
  dec: integer;
  left: integer;
begin
  left := 0;
  VectorCopy(start, move);
  VectorSubtract(ent, start, vec);
  len := VectorNormalize(vec);

  dec := 5;
  VectorScale(vec, 5, vec);

  while (len > 0) do
  begin
    len := len - dec;

    if (free_particles = nil) then
      exit;
    p := free_particles;
    free_particles := p.next;
    p.next := active_particles;
    active_particles := p;
    VectorClear(p.accel);

    p.time := cl.time;
    p.alpha := 0.5;
    p.alphavel := -1.0 / (0.3 + frand() * 0.2);
    p.color := $E4 + (rand() and 3);

    for j := 0 to 2 do
    begin
      p.org[j] := move[j];
      p.accel[j] := 0;
    end;
    if (left <> 0) then
    begin
      left := 0;
      p.vel[0] := 10;
    end
    else
    begin
      left := 1;
      p.vel[0] := -10;
    end;

    p.vel[1] := 0;
    p.vel[2] := 0;

    VectorAdd(move, vec, move);
  end;
end;

(*
===============
CL_BubbleTrail

===============
*)

procedure CL_BubbleTrail(const start, end_: vec3_t);
var
  move, vec: vec3_t;
  len: single;
  i, j: integer;
  p: cparticle_p;
  dec: integer;
begin
  VectorCopy(start, move);
  VectorSubtract(end_, start, vec);
  len := VectorNormalize(vec);

  dec := 32;
  VectorScale(vec, dec, vec);

  i := 0;
  while (i < len) do
  begin
    if (free_particles = nil) then
      exit;

    p := free_particles;
    free_particles := p.next;
    p.next := active_particles;
    active_particles := p;

    VectorClear(p.accel);
    p.time := cl.time;

    p.alpha := 1.0;
    p.alphavel := -1.0 / (1 + frand() * 0.2);
    p.color := 4 + (rand() and 7);
    for j := 0 to 2 do
    begin
      p.org[j] := move[j] + crand() * 2;
      p.vel[j] := crand() * 5;
    end;
    p.vel[2] := p.vel[2] + 6;

    VectorAdd(move, vec, move);
    i := i + dec;
  end;
end;

(*
===============
CL_FlyParticles
===============
*)

const
  BEAMLENGTH = 16;

procedure CL_FlyParticles(const origin: vec3_t; count: integer);
var
  i: integer;
  p: cparticle_p;
  angle: single;
  // Sly 27-Jun-2002 These variables are not used
  //   sr, cr,
  sp, sy, cp, cy: single;
  forward_: vec3_t;
  dist: single;
  ltime: single;
begin
  // Sly 27-Jun-2002 These values are not used
  dist := 64;
  if (count > NUMVERTEXNORMALS) then
    count := NUMVERTEXNORMALS;

  if (avelocities[0][0] = 0) then
  begin
    for i := 0 to NUMVERTEXNORMALS * 3 - 1 do
      avelocities[0][i] := (rand() and 255) * 0.01;
  end;

  ltime := cl.time / 1000.0;
  i := 0;
  while (i < count) do
  begin
    angle := ltime * avelocities[i][0];
    sy := sin(angle);
    cy := cos(angle);
    angle := ltime * avelocities[i][1];
    sp := sin(angle);
    cp := cos(angle);
    // Sly 27-Jun-2002 These values are not used
    //      angle := ltime * avelocities[i][2];
    //      sr := sin(angle);
    //      cr := cos(angle);

    forward_[0] := cp * cy;
    forward_[1] := cp * sy;
    forward_[2] := -sp;

    if (free_particles = nil) then
      exit;
    p := free_particles;
    free_particles := p.next;
    p.next := active_particles;
    active_particles := p;

    p.time := cl.time;

    dist := sin(ltime + i) * 64;
    p.org[0] := origin[0] + bytedirs[i][0] * dist + forward_[0] * BEAMLENGTH;
    p.org[1] := origin[1] + bytedirs[i][1] * dist + forward_[1] * BEAMLENGTH;
    p.org[2] := origin[2] + bytedirs[i][2] * dist + forward_[2] * BEAMLENGTH;

    VectorClear(p.vel);
    VectorClear(p.accel);

    p.color := 0;
    p.colorvel := 0;

    p.alpha := 1;
    p.alphavel := -100;
    i := i + 2;
  end;
end;

procedure CL_FlyEffect(ent: centity_p; const origin: vec3_t);
var
  n: integer;
  count: integer;
  starttime: integer;
begin
  if (ent.fly_stoptime < cl.time) then
  begin
    starttime := cl.time;
    ent.fly_stoptime := cl.time + 60000;
  end
  else
  begin
    starttime := ent.fly_stoptime - 60000;
  end;

  n := cl.time - starttime;
  if (n < 20000) then
    count := Round(n * 162 / 20000.0)
  else
  begin
    n := ent.fly_stoptime - cl.time;
    if (n < 20000) then
      count := Round(n * 162 / 20000.0)
    else
      count := 162;
  end;

  CL_FlyParticles(origin, count);
end;

(*
===============
CL_BfgParticles
===============
*)

procedure CL_BfgParticles(ent: entity_p);
var
  i: integer;
  p: cparticle_p;
  angle: single;
  // Sly 27-Jun-2002 These variables are not used
  //   sr, cr,
  sp, sy, cp, cy: single;
  forward_: vec3_t;
  dist: single;
  v: vec3_t;
  ltime: single;
begin
  // Sly 27-Jun-2002 These values are not used
  dist := 64;
  if (avelocities[0][0] = 0) then
  begin
    for i := 0 to NUMVERTEXNORMALS * 3 - 1 do
      avelocities[0][i] := (rand() and 255) * 0.01;
  end;

  ltime := cl.time / 1000.0;
  for i := 0 to NUMVERTEXNORMALS - 1 do
  begin
    angle := ltime * avelocities[i][0];
    sy := sin(angle);
    cy := cos(angle);
    angle := ltime * avelocities[i][1];
    sp := sin(angle);
    cp := cos(angle);
    // Sly 27-Jun-2002 These values are not used
    //      angle := ltime * avelocities[i][2];
    //      sr := sin(angle);
    //      cr := cos(angle);

    forward_[0] := cp * cy;
    forward_[1] := cp * sy;
    forward_[2] := -sp;

    if (free_particles = nil) then
      exit;
    p := free_particles;
    free_particles := p.next;
    p.next := active_particles;
    active_particles := p;

    p.time := cl.time;

    dist := sin(ltime + i) * 64;
    p.org[0] := ent.origin[0] + bytedirs[i][0] * dist + forward_[0] * BEAMLENGTH;
    p.org[1] := ent.origin[1] + bytedirs[i][1] * dist + forward_[1] * BEAMLENGTH;
    p.org[2] := ent.origin[2] + bytedirs[i][2] * dist + forward_[2] * BEAMLENGTH;

    VectorClear(p.vel);
    VectorClear(p.accel);

    VectorSubtract(p.org, vec3_t(ent.origin), v);
    dist := VectorLength(v) / 90.0;
    p.color := floor($D0 + dist * 7);
    p.colorvel := 0;

    p.alpha := 1.0 - dist;
    p.alphavel := -100;
  end;
end;

(*
===============
CL_TrapParticles
===============
*)
// RAFAEL

procedure CL_TrapParticles(ent: entity_p);
var
  move, vec: vec3_t;
  start, end_: vec3_t;
  len: single;
  i, j, k: integer;
  p: cparticle_p;
  dec: integer;
  vel: single;
  dir, org: vec3_t;
begin
  ent.origin[2] := ent.origin[2] - 14;
  VectorCopy(vec3_t(ent.origin), start);
  VectorCopy(vec3_t(ent.origin), end_);
  end_[2] := end_[2] + 64;

  VectorCopy(start, move);
  VectorSubtract(end_, start, vec);
  len := VectorNormalize(vec);

  dec := 5;
  VectorScale(vec, 5, vec);

  // FIXME: this is a really silly way to have a loop
  while (len > 0) do
  begin
    len := len - dec;

    if (free_particles = nil) then
      exit;
    p := free_particles;
    free_particles := p.next;
    p.next := active_particles;
    active_particles := p;
    VectorClear(p.accel);

    p.time := cl.time;

    p.alpha := 1.0;
    p.alphavel := -1.0 / (0.3 + frand() * 0.2);
    p.color := $E0;
    for j := 0 to 2 do
    begin
      p.org[j] := move[j] + crand();
      p.vel[j] := crand() * 15;
      p.accel[j] := 0;
    end;
    p.accel[2] := PARTICLE_GRAVITY;

    VectorAdd(move, vec, move);
  end;

  ent.origin[2] := ent.origin[2] + 14;
  VectorCopy(vec3_t(ent.origin), org);

  i := -2;
  while (i <= 2) do
  begin
    j := -2;
    while (j <= 2) do
    begin
      k := -2;
      while (k <= 4) do
      begin
        if (free_particles = nil) then
          exit;
        p := free_particles;
        free_particles := p.next;
        p.next := active_particles;
        active_particles := p;

        p.time := cl.time;
        p.color := $E0 + (rand() and 3);

        p.alpha := 1.0;
        p.alphavel := -1.0 / (0.3 + (rand() and 7) * 0.02);

        p.org[0] := org[0] + i + ((rand() and 23) * crand());
        p.org[1] := org[1] + j + ((rand() and 23) * crand());
        p.org[2] := org[2] + k + ((rand() and 23) * crand());

        dir[0] := j * 8;
        dir[1] := i * 8;
        dir[2] := k * 8;

        VectorNormalize(dir);
        vel := 50 + rand() and 63;
        VectorScale(dir, vel, p.vel);

        p.accel[0] := 0;
        p.accel[1] := 0;
        p.accel[2] := -PARTICLE_GRAVITY;
        k := k + 4;
      end;
      j := j + 4;
    end;
    i := i + 4;
  end;
end;

(*
===============
CL_BFGExplosionParticles
===============
*)
//FIXME combined with CL_ExplosionParticles

procedure CL_BFGExplosionParticles(const org: vec3_t);
var
  i, j: integer;
  p: cparticle_p;
begin
  for i := 0 to 256 - 1 do
  begin
    if (free_particles = nil) then
      exit;
    p := free_particles;
    free_particles := p.next;
    p.next := active_particles;
    active_particles := p;

    p.time := cl.time;
    p.color := $D0 + (rand() and 7);

    for j := 0 to 2 do
    begin
      p.org[j] := org[j] + ((rand() mod 32) - 16);
      p.vel[j] := (rand() mod 384) - 192;
    end;

    p.accel[0] := 0;
    p.accel[1] := 0;
    p.accel[2] := -PARTICLE_GRAVITY;
    p.alpha := 1.0;

    p.alphavel := -0.8 / (0.5 + frand() * 0.3);
  end;
end;

(*
===============
CL_TeleportParticles

===============
*)

procedure CL_TeleportParticles(const org: vec3_t);
var
  i, j, k: integer;
  p: cparticle_p;
  vel: single;
  dir: vec3_t;
begin
  i := -16;
  while (i <= 16) do
  begin
    j := -16;
    while (j <= 16) do
    begin
      k := -16;
      while (k <= 32) do
      begin
        if (free_particles = nil) then
          exit;
        p := free_particles;
        free_particles := p.next;
        p.next := active_particles;
        active_particles := p;

        p.time := cl.time;
        p.color := 7 + (rand() and 7);

        p.alpha := 1.0;
        p.alphavel := -1.0 / (0.3 + (rand() and 7) * 0.02);

        p.org[0] := org[0] + i + (rand() and 3);
        p.org[1] := org[1] + j + (rand() and 3);
        p.org[2] := org[2] + k + (rand() and 3);

        dir[0] := j * 8;
        dir[1] := i * 8;
        dir[2] := k * 8;

        VectorNormalize(dir);
        vel := 50 + (rand() and 63);
        VectorScale(dir, vel, p.vel);

        p.accel[0] := 0;
        p.accel[1] := 0;
        p.accel[2] := -PARTICLE_GRAVITY;
        k := k + 4;
      end;
      j := j + 4;
    end;
    i := i + 4;
  end;
end;

(*
===============
CL_AddParticles
===============
*)

procedure CL_AddParticles;
var
  p, next: cparticle_p;
  alpha: single;
  time, time2: single;
  org: vec3_t;
  color: integer;
  active, tail: cparticle_p;

label
  continue_;
begin
  active := nil;
  tail := nil;

  // Sly 27-Jun-2002 If time does not get assigned, then the calculation of time2 later on may be undefined
  time := 0.0;

  p := active_particles;
  while (p <> nil) do
  begin
    next := p.next;

    // PMM - added INSTANT_PARTICLE handling for heat beam
    if (p.alphavel <> INSTANT_PARTICLE) then
    begin
      time := (cl.time - p.time) * 0.001;
      alpha := p.alpha + time * p.alphavel;
      if (alpha <= 0) then
      begin
        // faded out
        p.next := free_particles;
        free_particles := p;
        goto continue_;
      end;
    end
    else
    begin
      alpha := p.alpha;
    end;

    p.next := nil;
    if (tail = nil) then
    begin
      active := p;
      tail := p;
    end
    else
    begin
      tail.next := p;
      tail := p;
    end;

    if (alpha > 1.0) then
      alpha := 1;
    color := Round(p.color);

    time2 := time * time;

    org[0] := p.org[0] + p.vel[0] * time + p.accel[0] * time2;
    org[1] := p.org[1] + p.vel[1] * time + p.accel[1] * time2;
    org[2] := p.org[2] + p.vel[2] * time + p.accel[2] * time2;

    V_AddParticle(org, color, alpha);
    // PMM
    if (p.alphavel = INSTANT_PARTICLE) then
    begin
      p.alphavel := 0.0;
      p.alpha := 0.0;
    end;
    continue_:
    p := next;
  end;

  active_particles := active;
end;

(*
==============
CL_EntityEvent

An entity has just been parsed that has an event value

the female events are there for backwards compatability
==============
*)

procedure CL_EntityEvent(ent: entity_state_p);
begin
  case ent.event of
    EV_ITEM_RESPAWN:
      begin
        S_StartSound(nil, ent.number, CHAN_WEAPON, S_RegisterSound('items/respawn1.wav'), 1, ATTN_IDLE, 0);
        CL_ItemRespawnParticles(ent.origin);
      end;
    EV_PLAYER_TELEPORT:
      begin
        S_StartSound(nil, ent.number, CHAN_WEAPON, S_RegisterSound('misc/tele1.wav'), 1, ATTN_IDLE, 0);
        CL_TeleportParticles(ent.origin);
      end;
    EV_FOOTSTEP:
      if (cl_footsteps.value <> 0) then
        S_StartSound(nil, ent.number, CHAN_BODY, cl_sfx_footsteps[rand() and 3], 1, ATTN_NORM, 0)
        ;
    EV_FALLSHORT:
      S_StartSound(nil, ent.number, CHAN_AUTO, S_RegisterSound('player/land1.wav'), 1, ATTN_NORM, 0);
    EV_FALL:
      S_StartSound(nil, ent.number, CHAN_AUTO, S_RegisterSound('*fall2.wav'), 1, ATTN_NORM, 0);
    EV_FALLFAR:
      S_StartSound(nil, ent.number, CHAN_AUTO, S_RegisterSound('*fall1.wav'), 1, ATTN_NORM, 0);
  end;
end;

(*
==============
CL_ClearEffects

==============
*)

procedure CL_ClearEffects;
begin
  CL_ClearParticles();
  CL_ClearDlights();
  CL_ClearLightStyles();
end;

end.
