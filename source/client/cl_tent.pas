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


{$ALIGN ON}{$MINENUMSIZE 4}
{----------------------------------------------------------------------------}
{                                                                            }
{ File(s): client\cl_tent.c                                                  }
{                                                                            }
{ Initial conversion by : Juha Hartikainen (juha@linearteam.org)             }
{ Initial conversion on : 02-Jun-2002                                        }
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
// cl_tent.c -- client side temporary entities
unit cl_tent;

interface

uses
  client,
  ref,
  {$IFDEF WIN32}
  Windows,
  vid_dll,
  {$ELSE}
  vid_so,
  {$ENDIF}
  Cpas,
  Math,
  Common,
  q_shared,
  snd_dma,
  snd_loc;

type
  ExpType_t = (ex_free, ex_explosion, ex_misc, ex_flash, ex_mflash, ex_poly, ex_poly2);

  explosion_p = ^explosion_t;
  explosion_t = record
    type_: ExpType_t;
    ent: Entity_t;

    Frames: Integer;
    Light: Single;
    LightColor: vec3_t;
    Start: Single;
    BaseFrame: Integer;
  end;

const
  MAX_EXPLOSIONS = 32;

var
  cl_explosions: array[0..MAX_EXPLOSIONS - 1] of explosion_t;

const
  MAX_BEAMS = 32;

type
  beam_p = ^beam_t;
  beam_t = record
    Entity, Dest_Entity: Integer;
    Model: Model_p;
    EndTime: Integer;
    Offset, Start, End_: vec3_t;
  end;

var
  cl_beams, cl_playerbeams: array[0..MAX_BEAMS - 1] of beam_t;
  //PMM - added this [cl_playerbeams] for player-linked beams.  Currently only used by the plasma beam

const
  MAX_LASERS = 32;

type
  laser_p = ^laser_t;
  laser_t = record
    Ent: entity_t;
    EndTime: Integer;
  end;

var
  cl_lasers: array[0..MAX_LASERS - 1] of laser_t;

  //ROGUE
  cl_sustains: array[0..MAX_SUSTAINS - 1] of cl_sustain_t;
  //ROGUE

var
  cl_sfx_ric1, cl_sfx_ric2, cl_sfx_ric3,
    cl_sfx_lashit,
    cl_sfx_spark5, cl_sfx_spark6, cl_sfx_spark7,
    cl_sfx_railg,
    cl_sfx_rockexp, cl_sfx_grenexp, cl_sfx_watrexp,
    // RAFAEL
  cl_sfx_plasexp: sfx_p;
  cl_sfx_footsteps: array[0..3] of sfx_p;

  cl_mod_explode, cl_mod_smoke, cl_mod_flash,
    cl_mod_parasite_segment,
    cl_mod_grapple_cable,
    cl_mod_parasite_tip,
    cl_mod_explo4, cl_mod_bfg_explo,
    cl_mod_powerscreen,
    // RAFAEL
  cl_mod_plasmaexplo: model_p;

  //ROGUE
  cl_sfx_lightning, cl_sfx_disrexp: sfx_p;
  cl_mod_lightning, cl_mod_heatbeam,
    cl_mod_monster_heatbeam,
    cl_mod_explo4_big: model_p;
  //ROGUE

procedure CL_RegisterTEntModels;
procedure CL_AddTEnts;
procedure CL_ClearTEnts;
procedure CL_SmokeAndFlash(const Origin: vec3_t);
procedure CL_RegisterTEntSounds;
procedure CL_ParseTEnt;

implementation

uses
  net_chan,
  cl_fx,
  cl_view,
  cl_newfx,
  cl_main;

{
=========
CL_RegisterTEntSounds
=========
}

procedure CL_RegisterTEntSounds;
var
  i: Integer;
  Name: array[0..MAX_QPATH - 1] of char;
begin

  // PMM - version stuff
  //Com_Printf ('%s'#10, ROGUE_VERSION_STRING);
  // PMM
  cl_sfx_ric1 := S_RegisterSound('world/ric1.wav');
  cl_sfx_ric2 := S_RegisterSound('world/ric2.wav');
  cl_sfx_ric3 := S_RegisterSound('world/ric3.wav');
  cl_sfx_lashit := S_RegisterSound('weapons/lashit.wav');
  cl_sfx_spark5 := S_RegisterSound('world/spark5.wav');
  cl_sfx_spark6 := S_RegisterSound('world/spark6.wav');
  cl_sfx_spark7 := S_RegisterSound('world/spark7.wav');
  cl_sfx_railg := S_RegisterSound('weapons/railgf1a.wav');
  cl_sfx_rockexp := S_RegisterSound('weapons/rocklx1a.wav');
  cl_sfx_grenexp := S_RegisterSound('weapons/grenlx1a.wav');
  cl_sfx_watrexp := S_RegisterSound('weapons/xpld_wat.wav');
  // RAFAEL
  // cl_sfx_plasexp := S_RegisterSound ('weapons/plasexpl.wav');
  S_RegisterSound('player/land1.wav');

  S_RegisterSound('player/fall2.wav');
  S_RegisterSound('player/fall1.wav');

  for i := 0 to 3 do
  begin
    Com_sprintf(name, sizeof(name), 'player/step%d.wav', [i + 1]);
    cl_sfx_footsteps[i] := S_RegisterSound(name);
  end;

  //PGM
  cl_sfx_lightning := S_RegisterSound('weapons/tesla.wav');
  cl_sfx_disrexp := S_RegisterSound('weapons/disrupthit.wav');
  // version stuff
  //sprintf (name, 'weapons/sound%d.wav', ROGUE_VERSION_ID);
  //if (name[0] = 'w')
  // name[0] := 'W';
  //PGM
end;

{
=========
CL_RegisterTEntModels
=========
}

procedure CL_RegisterTEntModels;
begin
  cl_mod_explode := re.RegisterModel('models/objects/explode/tris.md2');
  cl_mod_smoke := re.RegisterModel('models/objects/smoke/tris.md2');
  cl_mod_flash := re.RegisterModel('models/objects/flash/tris.md2');
  cl_mod_parasite_segment := re.RegisterModel('models/monsters/parasite/segment/tris.md2');
  cl_mod_grapple_cable := re.RegisterModel('models/ctf/segment/tris.md2');
  cl_mod_parasite_tip := re.RegisterModel('models/monsters/parasite/tip/tris.md2');
  cl_mod_explo4 := re.RegisterModel('models/objects/r_explode/tris.md2');
  cl_mod_bfg_explo := re.RegisterModel('sprites/s_bfg2.sp2');
  cl_mod_powerscreen := re.RegisterModel('models/items/armor/effect/tris.md2');

  re.RegisterModel('models/objects/laser/tris.md2');
  re.RegisterModel('models/objects/grenade2/tris.md2');
  re.RegisterModel('models/weapons/v_machn/tris.md2');
  re.RegisterModel('models/weapons/v_handgr/tris.md2');
  re.RegisterModel('models/weapons/v_shotg2/tris.md2');
  re.RegisterModel('models/objects/gibs/bone/tris.md2');
  re.RegisterModel('models/objects/gibs/sm_meat/tris.md2');
  re.RegisterModel('models/objects/gibs/bone2/tris.md2');
  // RAFAEL
  // re.RegisterModel ('models/objects/blaser/tris.md2');

  re.RegisterPic('w_machinegun');
  re.RegisterPic('a_bullets');
  re.RegisterPic('i_health');
  re.RegisterPic('a_grenades');

  //ROGUE
  cl_mod_explo4_big := re.RegisterModel('models/objects/r_explode2/tris.md2');
  cl_mod_lightning := re.RegisterModel('models/proj/lightning/tris.md2');
  cl_mod_heatbeam := re.RegisterModel('models/proj/beam/tris.md2');
  cl_mod_monster_heatbeam := re.RegisterModel('models/proj/widowbeam/tris.md2');
  //ROGUE
end;

{
=========
CL_ClearTEnts
=========
}

procedure CL_ClearTEnts;
begin
  // it's possible to eliminate the def and use only the memset instruction ..by FAB
  {$IFDEF WIN32}
  ZeroMemory(@cl_beams, sizeof(cl_beams));
  ZeroMemory(@cl_explosions, sizeof(cl_explosions));
  ZeroMemory(@cl_lasers, sizeof(cl_lasers));
  {$ELSE}
  memset (@cl_beams, 0, sizeof(cl_beams));
  memset (@cl_explosions, 0, sizeof(cl_explosions));
  memset (@cl_lasers, 0, sizeof(cl_lasers));
  {$ENDIF}

  //ROGUE
  {$IFDEF WIN32}
  ZeroMemory(@cl_playerbeams, sizeof(cl_playerbeams));
  ZeroMemory(@cl_sustains, sizeof(cl_sustains));
  {$ELSE}
  memset (@cl_playerbeams, 0, sizeof(cl_playerbeams));
  memset (@cl_sustains, 0, sizeof(cl_sustains));
  {$ENDIF}
  //ROGUE}
end;

{
=========
CL_AllocExplosion
=========
}

function CL_AllocExplosion: Explosion_p;
var
  i, time, index: Integer;
begin
  for i := 0 to MAX_EXPLOSIONS - 1 do
  begin
    if (cl_explosions[i].type_ = ex_free) then
    begin
      FillChar(cl_explosions[i], SizeOf(cl_explosions[i]), 0);
      Result := @cl_explosions[i];
      Exit;
    end;
  end;
  // find the oldest explosion
  time := cl.time;
  index := 0;

  for i := 0 to MAX_EXPLOSIONS - 1 do
    if (cl_explosions[i].start < time) then
    begin
      time := Round(cl_explosions[i].start);
      index := i;
    end;
  FillChar(cl_explosions[index], SizeOf(cl_explosions[index]), 0);
  Result := @cl_explosions[index];
end;

{
=========
CL_SmokeAndFlash
=========
}

procedure CL_SmokeAndFlash(const Origin: vec3_t);
var
  ex: Explosion_p;
begin
  ex := CL_AllocExplosion();
  VectorCopy(origin, vec3_t(ex^.ent.origin));
  ex^.type_ := ex_misc;
  ex^.frames := 4;
  ex^.ent.flags := RF_TRANSLUCENT;
  ex^.start := cl.frame.servertime - 100;
  ex^.ent.model := cl_mod_smoke;

  ex := CL_AllocExplosion();
  VectorCopy(origin, vec3_t(ex^.ent.origin));
  ex^.type_ := ex_flash;
  ex^.ent.flags := RF_FULLBRIGHT;
  ex^.frames := 2;
  ex^.start := cl.frame.servertime - 100;
  ex^.ent.model := cl_mod_flash;
end;

{
=========
CL_ParseParticles
=========
}

procedure CL_ParseParticles;
var
  Color, Count: Integer;
  Pos, Dir: vec3_t;
begin
  MSG_ReadPos(net_message, pos);
  MSG_ReadDir(net_message, dir);

  color := MSG_ReadByte(net_message);
  count := MSG_ReadByte(net_message);

  CL_ParticleEffect(pos, dir, color, count);
end;

{
=========
CL_ParseBeam / CL_ParseBeam2
=========
}

function CL_ParseBeam(Model: Model_p): Integer;
var
  ent: Integer;
  start, end_: vec3_t;
  b: beam_p;
  i: Integer;
begin
  ent := MSG_ReadShort(net_message);

  MSG_ReadPos(net_message, start);
  MSG_ReadPos(net_message, end_);

  // override any beam with the same entity
  b := @cl_beams;
  for i := 0 to MAX_BEAMS - 1 do
  begin
    if (b^.entity = ent) then
    begin
      b^.entity := ent;
      b^.model := model;
      b^.endtime := cl.time + 200;
      VectorCopy(start, b^.start);
      VectorCopy(end_, b^.end_);
      VectorClear(b^.offset);
      Result := ent;
      Exit;
    end;
    Inc(b);
  end;
  // find a free beam
  b := @cl_beams;
  for i := 0 to MAX_BEAMS - 1 do
  begin
    if (b^.model = nil) or (b^.endtime < cl.time) then
    begin
      b^.entity := ent;
      b^.model := model;
      b^.endtime := cl.time + 200;
      VectorCopy(start, b^.start);
      VectorCopy(end_, b^.end_);
      VectorClear(b^.offset);
      Result := ent;
      Exit;
    end;
    Inc(b);
  end;
  Com_Printf('beam list overflow!'#10);
  Result := ent;
end;

function CL_ParseBeam2(Model: Model_p): Integer;
var
  ent: Integer;
  start, end_, offset: vec3_t;
  b: beam_p;
  i: Integer;
begin
  ent := MSG_ReadShort(net_message);

  MSG_ReadPos(net_message, start);
  MSG_ReadPos(net_message, end_);
  MSG_ReadPos(net_message, offset);

  //   Com_Printf ("end- %f %f %f\n", end[0], end[1], end[2]);

  // override any beam with the same entity

  b := @cl_beams;
  for i := 0 to MAX_BEAMS - 1 do
  begin
    if (b^.entity = ent) then
    begin
      b^.entity := ent;
      b^.model := model;
      b^.endtime := cl.time + 200;
      VectorCopy(start, b^.start);
      VectorCopy(end_, b^.end_);
      VectorCopy(offset, b^.offset);
      Result := ent;
      Exit;
    end;
    Inc(b);
  end;
  // find a free beam
  b := @cl_beams;
  for i := 0 to MAX_BEAMS - 1 do
  begin
    if (b^.model = nil) or (b^.endtime < cl.time) then
    begin
      b^.entity := ent;
      b^.model := model;
      b^.endtime := cl.time + 200;
      VectorCopy(start, b^.start);
      VectorCopy(end_, b^.end_);
      VectorCopy(offset, b^.offset);
      Result := ent;
      Exit;
    end;
    Inc(b);
  end;
  Com_Printf('beam list overflow!'#10);
  Result := ent;
end;

// ROGUE
{
=========
CL_ParsePlayerBeam
  - adds to the cl_playerbeam array instead of the cl_beams array
=========
}

function CL_ParsePlayerBeam(Model: Model_p): Integer;
var
  Ent: Integer;
  Start, End_, Offset: Vec3_t;
  b: Beam_p;
  I: Integer;
begin
  ent := MSG_ReadShort(net_message);

  MSG_ReadPos(net_message, start);
  MSG_ReadPos(net_message, end_);
  // PMM - network optimization
  if (model = cl_mod_heatbeam) then
    VectorSet(offset, 2, 7, -3)
  else if (model = cl_mod_monster_heatbeam) then
  begin
    model := cl_mod_heatbeam;
    VectorSet(offset, 0, 0, 0);
  end
  else
    MSG_ReadPos(net_message, offset);

  // Com_Printf ('end- %f %f %f'#10, end[0], end[1], end[2]);

  // override any beam with the same entity
  // PMM - For player beams, we only want one per player (entity) so..
  b := @cl_playerbeams;
  for i := 0 to MAX_BEAMS - 1 do
  begin
    if (b^.entity = ent) then
    begin
      b^.entity := ent;
      b^.model := model;
      b^.endtime := cl.time + 200;
      VectorCopy(start, b^.start);
      VectorCopy(end_, b^.end_);
      VectorCopy(offset, b^.offset);
      Result := ent;
      exit;
    end;
    Inc(b);
  end;

  // find a free beam
  b := @cl_playerbeams;
  for i := 0 to MAX_BEAMS - 1 do
  begin
    if (b^.model = nil) or (b^.endtime < cl.time) then
    begin
      b^.entity := ent;
      b^.model := model;
      b^.endtime := cl.time + 100;      // PMM - this needs to be 100 to prevent multiple heatbeams
      VectorCopy(start, b^.start);
      VectorCopy(end_, b^.end_);
      VectorCopy(offset, b^.offset);
      Result := ent;
      exit;
    end;
    Inc(b);
  end;
  Com_Printf('beam list overflow!'#10);
  result := ent;
end;
//rogue

{
=========
CL_ParseLightning
=========
}

function CL_ParseLightning(Model: Model_p): Integer;
var
  srcEnt, destEnt, i: Integer;
  Start, End_: vec3_t;
  b: Beam_p;
begin
  srcEnt := MSG_ReadShort(net_message);
  destEnt := MSG_ReadShort(net_message);

  MSG_ReadPos(net_message, start);
  MSG_ReadPos(net_message, end_);

  // override any beam with the same source AND destination entities
  b := @cl_beams;
  for i := 0 to MAX_BEAMS - 1 do
  begin
    if (b^.entity = srcEnt) and (b^.dest_entity = destEnt) then
    begin
      //  Com_Printf('%d: OVERRIDE  %d ^. %d'#10, cl.time, srcEnt, destEnt);
      b^.entity := srcEnt;
      b^.dest_entity := destEnt;
      b^.model := model;
      b^.endtime := cl.time + 200;
      VectorCopy(start, b^.start);
      VectorCopy(end_, b^.end_);
      VectorClear(b^.offset);
      result := srcEnt;
      exit;
    end;
    Inc(b);
  end;

  // find a free beam
  b := @cl_beams;
  for i := 0 to MAX_BEAMS - 1 do
  begin
    if (b^.model = nil) or (b^.endtime < cl.time) then
    begin
      // Com_Printf('%d: NORMAL  %d ^. %d'#10, cl.time, srcEnt, destEnt);
      b^.entity := srcEnt;
      b^.dest_entity := destEnt;
      b^.model := model;
      b^.endtime := cl.time + 200;
      VectorCopy(start, b^.start);
      VectorCopy(end_, b^.end_);
      VectorClear(b^.offset);
      result := srcEnt;
      exit;
    end;
    Inc(b);
  end;
  Com_Printf('beam list overflow!'#10);
  result := srcEnt;
end;

{
=========
CL_ParseLaser
=========
}

procedure CL_ParseLaser(Colors: Integer);
var
  Start, End_: vec3_t;
  l: laser_p;
  i: Integer;
begin
  MSG_ReadPos(net_message, start);
  MSG_ReadPos(net_message, end_);

  l := @cl_lasers;
  for i := 0 to MAX_LASERS - 1 do
  begin
    if (l.endtime < cl.time) then
    begin
      l.ent.flags := RF_TRANSLUCENT or RF_BEAM;
      VectorCopy(start, vec3_t(l.ent.origin));
      VectorCopy(end_, vec3_t(l.ent.oldorigin));
      l.ent.alpha := 0.30;
      l.ent.skinnum := (colors shr ((rand() mod 4) * 8)) and $FF; // was (rand() % 4)
      l.ent.model := nil;
      l.ent.frame := 4;
      l.endtime := cl.time + 100;
      exit;
    end;
    Inc(l);
  end;
end;

//=======
//ROGUE

procedure CL_ParseSteam;
var
  pos, dir: vec3_t;
  id, i, r, cnt, color, magnitude: Integer;
  s, free_sustain: cl_sustain_p;
begin
  id := MSG_ReadShort(net_message);     // an id of -1 is an instant effect
  if (id <> -1) then
  begin                                 // sustains
    // Com_Printf ('Sustain effect id %d\n', id);
    free_sustain := nil;
    for i := 0 to MAX_SUSTAINS - 1 do
    begin
      s := @cl_sustains[i];
      if (s.id = 0) then
      begin
        free_sustain := s;
        break;
      end;
    end;
    if (free_sustain <> nil) then
    begin
      s.id := id;
      s.count := MSG_ReadByte(net_message);
      MSG_ReadPos(net_message, s.org);
      MSG_ReadDir(net_message, s.dir);
      r := MSG_ReadByte(net_message);
      s.color := r and $FF;
      s.magnitude := MSG_ReadShort(net_message);
      s.endtime := cl.time + MSG_ReadLong(net_message);
      s.think := CL_ParticleSteamEffect2;
      s.thinkinterval := 100;
      s.nextthink := cl.time;
    end
    else
    begin
      // Com_Printf ('No free sustains!\n');
      // FIXME - read the stuff anyway
      cnt := MSG_ReadByte(net_message);
      MSG_ReadPos(net_message, pos);
      MSG_ReadDir(net_message, dir);
      r := MSG_ReadByte(net_message);
      magnitude := MSG_ReadShort(net_message);
      magnitude := MSG_ReadLong(net_message); // really interval
    end;
  end
  else
  begin                                 // instant
    cnt := MSG_ReadByte(net_message);
    MSG_ReadPos(net_message, pos);
    MSG_ReadDir(net_message, dir);
    r := MSG_ReadByte(net_message);
    magnitude := MSG_ReadShort(net_message);
    color := r and $FF;
    CL_ParticleSteamEffect(pos, dir, color, cnt, magnitude);
    // S_StartSound (pos,  0, 0, cl_sfx_lashit, 1, ATTN_NORM, 0);
  end;
end;

procedure CL_ParseWidow;
var
  Pos: vec3_t;
  id, i: Integer;
  s, free_sustain: cl_sustain_p;
begin
  id := MSG_ReadShort(net_message);

  free_sustain := nil;
  for i := 0 to MAX_SUSTAINS - 1 do
  begin
    s := @cl_sustains[i];
    if (s.id = 0) then
    begin
      free_sustain := s;
      break;
    end;
  end;
  if (free_sustain <> nil) then
  begin
    s.id := id;
    MSG_ReadPos(net_message, s.org);
    s.endtime := cl.time + 2100;
    s.think := CL_Widowbeamout;
    s.thinkinterval := 1;
    s.nextthink := cl.time;
  end
  else
  begin                                 // no free sustains
    // FIXME - read the stuff anyway
    MSG_ReadPos(net_message, pos);
  end;
end;

procedure CL_ParseNuke;
var
  Pos: Vec3_t;
  id, i: Integer;
  s, free_sustain: cl_sustain_p;
begin
  free_sustain := nil;
  for i := 0 to MAX_SUSTAINS - 1 do
  begin
    s := @cl_sustains[i];
    if (s.id = 0) then
    begin
      free_sustain := s;
      break;
    end;
  end;
  if (free_sustain <> nil) then
  begin
    s.id := 21000;
    MSG_ReadPos(net_message, s.org);
    s.endtime := cl.time + 1000;
    s.think := CL_Nukeblast;
    s.thinkinterval := 1;
    s.nextthink := cl.time;
  end
  else
  begin                                 // no free sustains
    // FIXME - read the stuff anyway
    MSG_ReadPos(net_message, pos);
  end;
end;

//ROGUE
//=======

{
=========
CL_ParseTEnt
=========
}
const
  splash_color: array[0..6] of byte =
  ($00, $E0, $B0, $50, $D0, $E0, $E8);

procedure CL_ParseTEnt;
var
  type_: Integer;
  Pos, Pos2, Dir: vec3_t;
  Ex: Explosion_p;
  Cnt, Color, r, Ent, Magnitude: Integer;
begin
  type_ := MSG_ReadByte(net_message);

  case temp_event_t(type_) of
    TE_BLOOD:
      begin                             // bullet hitting flesh
        MSG_ReadPos(net_message, pos);
        MSG_ReadDir(net_message, dir);
        CL_ParticleEffect(pos, dir, $E8, 60);
      end;

    TE_GUNSHOT,                         // bullet hitting wall
    TE_SPARKS,
      TE_BULLET_SPARKS:
      begin
        MSG_ReadPos(net_message, pos);
        MSG_ReadDir(net_message, dir);
        if temp_event_t(type_) = TE_GUNSHOT then
          CL_ParticleEffect(pos, dir, 0, 40)
        else
          CL_ParticleEffect(pos, dir, $E0, 6);

        if (temp_event_t(type_) <> TE_SPARKS) then
        begin
          CL_SmokeAndFlash(pos);

          // impact sound
          cnt := rand() and 15;
          case cnt of
            1: S_StartSound(@pos, 0, 0, cl_sfx_ric1, 1, ATTN_NORM, 0);
            2: S_StartSound(@pos, 0, 0, cl_sfx_ric2, 1, ATTN_NORM, 0);
            3: S_StartSound(@pos, 0, 0, cl_sfx_ric3, 1, ATTN_NORM, 0);
          end;
        end;
      end;

    TE_SCREEN_SPARKS,
      TE_SHIELD_SPARKS:
      begin
        MSG_ReadPos(net_message, pos);
        MSG_ReadDir(net_message, dir);
        if temp_event_t(type_) = TE_SCREEN_SPARKS then
          CL_ParticleEffect(pos, dir, $D0, 40)
        else
          CL_ParticleEffect(pos, dir, $B0, 40);
        //FIXME : replace or remove this sound
        S_StartSound(@pos, 0, 0, cl_sfx_lashit, 1, ATTN_NORM, 0);
      end;

    TE_SHOTGUN:
      begin                             // bullet hitting wall
        MSG_ReadPos(net_message, pos);
        MSG_ReadDir(net_message, dir);
        CL_ParticleEffect(pos, dir, 0, 20);
        CL_SmokeAndFlash(pos);
      end;

    TE_SPLASH:
      begin                             // bullet hitting water
        cnt := MSG_ReadByte(net_message);
        MSG_ReadPos(net_message, pos);
        MSG_ReadDir(net_message, dir);
        r := MSG_ReadByte(net_message);
        if (r > 6) then
          color := $00
        else
          color := splash_color[r];
        CL_ParticleEffect(pos, dir, color, cnt);

        if (r = SPLASH_SPARKS) then
        begin
          r := rand() and 3;
          case r of
            0: S_StartSound(@pos, 0, 0, cl_sfx_spark5, 1, ATTN_STATIC, 0);
            1: S_StartSound(@pos, 0, 0, cl_sfx_spark6, 1, ATTN_STATIC, 0);
          else
            S_StartSound(@pos, 0, 0, cl_sfx_spark7, 1, ATTN_STATIC, 0);
          end;
        end;
      end;

    TE_LASER_SPARKS:
      begin
        cnt := MSG_ReadByte(net_message);
        MSG_ReadPos(net_message, pos);
        MSG_ReadDir(net_message, dir);
        color := MSG_ReadByte(net_message);
        CL_ParticleEffect2(pos, dir, color, cnt);
      end;

    // RAFAEL
    TE_BLUEHYPERBLASTER:
      begin
        MSG_ReadPos(net_message, pos);
        MSG_ReadPos(net_message, dir);
        CL_BlasterParticles(pos, dir);
      end;

    TE_BLASTER:
      begin                             // blaster hitting wall
        MSG_ReadPos(net_message, pos);
        MSG_ReadDir(net_message, dir);
        CL_BlasterParticles(pos, dir);

        ex := CL_AllocExplosion();
        VectorCopy(pos, vec3_t(ex^.ent.origin));
        ex^.ent.angles[0] := arccos(dir[2]) / M_PI * 180;
        // PMM - fixed to correct for pitch of 0
        if (dir[0] <> 0) then
          // was ex^.ent.angles[1] := atan2(dir[1], dir[0])/M_PI*180
          ex^.ent.angles[1] := ArcTan2(dir[1], dir[0]) / M_PI * 180 // ???
        else if (dir[1] > 0) then
          ex^.ent.angles[1] := 90
        else if (dir[1] < 0) then
          ex^.ent.angles[1] := 270
        else
          ex^.ent.angles[1] := 0;

        ex^.type_ := ex_misc;
        ex^.ent.flags := RF_FULLBRIGHT or RF_TRANSLUCENT;
        ex^.start := cl.frame.servertime - 100;
        ex^.light := 150;
        ex^.lightcolor[0] := 1;
        ex^.lightcolor[1] := 1;
        ex^.ent.model := cl_mod_explode;
        ex^.frames := 4;
        S_StartSound(@pos, 0, 0, cl_sfx_lashit, 1, ATTN_NORM, 0);
      end;

    TE_RAILTRAIL:
      begin                             // railgun effect
        MSG_ReadPos(net_message, pos);
        MSG_ReadPos(net_message, pos2);
        CL_RailTrail(pos, pos2);
        S_StartSound(@pos2, 0, 0, cl_sfx_railg, 1, ATTN_NORM, 0);
      end;

    TE_EXPLOSION2,
      TE_GRENADE_EXPLOSION,
      TE_GRENADE_EXPLOSION_WATER:
      begin
        MSG_ReadPos(net_message, pos);

        ex := CL_AllocExplosion();
        VectorCopy(pos, vec3_t(ex^.ent.origin));
        ex^.type_ := ex_poly;
        ex^.ent.flags := RF_FULLBRIGHT;
        ex^.start := cl.frame.servertime - 100;
        ex^.light := 350;
        ex^.lightcolor[0] := 1.0;
        ex^.lightcolor[1] := 0.5;
        ex^.lightcolor[2] := 0.5;
        ex^.ent.model := cl_mod_explo4;
        ex^.frames := 19;
        ex^.baseframe := 30;
        ex^.ent.angles[1] := rand() mod 360;
        CL_ExplosionParticles(pos);
        if (temp_event_t(type_) = TE_GRENADE_EXPLOSION_WATER) then
          S_StartSound(@pos, 0, 0, cl_sfx_watrexp, 1, ATTN_NORM, 0)
        else
          S_StartSound(@pos, 0, 0, cl_sfx_grenexp, 1, ATTN_NORM, 0);
      end;

    // RAFAEL
    TE_PLASMA_EXPLOSION:
      begin
        MSG_ReadPos(net_message, pos);
        ex := CL_AllocExplosion();
        VectorCopy(pos, vec3_t(ex^.ent.origin));
        ex^.type_ := ex_poly;
        ex^.ent.flags := RF_FULLBRIGHT;
        ex^.start := cl.frame.servertime - 100;
        ex^.light := 350;
        ex^.lightcolor[0] := 1.0;
        ex^.lightcolor[1] := 0.5;
        ex^.lightcolor[2] := 0.5;
        ex^.ent.angles[1] := rand() mod 360;
        ex^.ent.model := cl_mod_explo4;
        if Random < 0.5 then            // was (frand() < 0.5)
          ex^.baseframe := 15;
        ex^.frames := 15;
        CL_ExplosionParticles(pos);
        S_StartSound(@pos, 0, 0, cl_sfx_rockexp, 1, ATTN_NORM, 0);
      end;

    TE_EXPLOSION1,
      TE_EXPLOSION1_BIG,
      TE_ROCKET_EXPLOSION,
      TE_ROCKET_EXPLOSION_WATER,
      TE_EXPLOSION1_NP:
      begin                             // PMM
        MSG_ReadPos(net_message, pos);

        ex := CL_AllocExplosion();
        VectorCopy(pos, vec3_t(ex^.ent.origin));
        ex^.type_ := ex_poly;
        ex^.ent.flags := RF_FULLBRIGHT;
        ex^.start := cl.frame.servertime - 100;
        ex^.light := 350;
        ex^.lightcolor[0] := 1.0;
        ex^.lightcolor[1] := 0.5;
        ex^.lightcolor[2] := 0.5;
        ex^.ent.angles[1] := rand() mod 360;
        if (temp_event_t(type_) <> TE_EXPLOSION1_BIG) then // PMM
          ex^.ent.model := cl_mod_explo4 // PMM
        else
          ex^.ent.model := cl_mod_explo4_big;
        if Random < 0.5 then            // was (frand() < 0.5)
          ex^.baseframe := 15;
        ex^.frames := 15;
        if not (temp_event_t(type_) in [TE_EXPLOSION1_BIG, TE_EXPLOSION1_NP]) then // PMM
          CL_ExplosionParticles(pos);   // PMM
        if (temp_event_t(type_) = TE_ROCKET_EXPLOSION_WATER) then
          S_StartSound(@pos, 0, 0, cl_sfx_watrexp, 1, ATTN_NORM, 0)
        else
          S_StartSound(@pos, 0, 0, cl_sfx_rockexp, 1, ATTN_NORM, 0);
      end;

    TE_BFG_EXPLOSION:
      begin
        MSG_ReadPos(net_message, pos);
        ex := CL_AllocExplosion();
        VectorCopy(pos, vec3_t(ex^.ent.origin));
        ex^.type_ := ex_poly;
        ex^.ent.flags := RF_FULLBRIGHT;
        ex^.start := cl.frame.servertime - 100;
        ex^.light := 350;
        ex^.lightcolor[0] := 0.0;
        ex^.lightcolor[1] := 1.0;
        ex^.lightcolor[2] := 0.0;
        ex^.ent.model := cl_mod_bfg_explo;
        ex^.ent.flags := ex^.ent.flags or RF_TRANSLUCENT;
        ex^.ent.alpha := 0.30;
        ex^.frames := 4;
      end;

    TE_BFG_BIGEXPLOSION:
      begin
        MSG_ReadPos(net_message, pos);
        CL_BFGExplosionParticles(pos);
      end;

    TE_BFG_LASER: CL_ParseLaser($D0D1D2D3);

    TE_BUBBLETRAIL:
      begin
        MSG_ReadPos(net_message, pos);
        MSG_ReadPos(net_message, pos2);
        CL_BubbleTrail(pos, pos2);
      end;

    TE_PARASITE_ATTACK, TE_MEDIC_CABLE_ATTACK:
      ent := CL_ParseBeam(cl_mod_parasite_segment);

    TE_BOSSTPORT:
      begin                             // boss teleporting to station
        MSG_ReadPos(net_message, pos);
        CL_BigTeleportParticles(pos);
        S_StartSound(@pos, 0, 0, S_RegisterSound('misc/bigtele.wav'), 1, ATTN_NONE, 0);
      end;

    TE_GRAPPLE_CABLE: ent := CL_ParseBeam2(cl_mod_grapple_cable);

    // RAFAEL
    TE_WELDING_SPARKS:
      begin
        cnt := MSG_ReadByte(net_message);
        MSG_ReadPos(net_message, pos);
        MSG_ReadDir(net_message, dir);
        color := MSG_ReadByte(net_message);
        CL_ParticleEffect2(pos, dir, color, cnt);

        ex := CL_AllocExplosion();
        VectorCopy(pos, vec3_t(ex^.ent.origin));
        ex^.type_ := ex_flash;
        // note to self
        // we need a better no draw flag
        ex^.ent.flags := RF_BEAM;
        ex^.start := cl.frame.servertime - 0.1;
        ex^.light := 100 + (rand() mod 75);
        ex^.lightcolor[0] := 1.0;
        ex^.lightcolor[1] := 1.0;
        ex^.lightcolor[2] := 0.3;
        ex^.ent.model := cl_mod_flash;
        ex^.frames := 2;
      end;

    TE_GREENBLOOD:
      begin
        MSG_ReadPos(net_message, pos);
        MSG_ReadDir(net_message, dir);
        CL_ParticleEffect2(pos, dir, $DF, 30);
      end;

    // RAFAEL
    TE_TUNNEL_SPARKS:
      begin
        cnt := MSG_ReadByte(net_message);
        MSG_ReadPos(net_message, pos);
        MSG_ReadDir(net_message, dir);
        color := MSG_ReadByte(net_message);
        CL_ParticleEffect3(pos, dir, color, cnt);
      end;

    //=======
    //PGM
    // PMM -following code integrated for flechette (different color)
    TE_BLASTER2,                        // green blaster hitting wall
    TE_FLECHETTE:
      begin                             // flechette
        MSG_ReadPos(net_message, pos);
        MSG_ReadDir(net_message, dir);

        // PMM
        if (temp_event_t(type_) = TE_BLASTER2) then
          CL_BlasterParticles2(pos, dir, $D0)
        else
          CL_BlasterParticles2(pos, dir, $6F); // 75

        ex := CL_AllocExplosion();
        VectorCopy(pos, vec3_t(ex^.ent.origin));
        ex^.ent.angles[0] := arccos(dir[2]) / M_PI * 180;
        // PMM - fixed to correct for pitch of 0
        if (dir[0] <> 0) then
          // was ex^.ent.angles[1] := atan2(dir[1], dir[0])/M_PI*180
          ex^.ent.angles[1] := ArcTan2(dir[1], dir[0]) / M_PI * 180 // ???
        else if (dir[1] > 0) then
          ex^.ent.angles[1] := 90
        else if (dir[1] < 0) then
          ex^.ent.angles[1] := 270
        else
          ex^.ent.angles[1] := 0;

        ex^.type_ := ex_misc;
        ex^.ent.flags := RF_FULLBRIGHT or RF_TRANSLUCENT;

        // PMM
        if (temp_event_t(type_) = TE_BLASTER2) then
          ex^.ent.skinnum := 1
        else
          ex^.ent.skinnum := 2;         // flechette

        ex^.start := cl.frame.servertime - 100;
        ex^.light := 150;
        // PMM
        if (temp_event_t(type_) = TE_BLASTER2) then
          ex^.lightcolor[1] := 1
        else
        begin                           // flechette
          ex^.lightcolor[0] := 0.19;
          ex^.lightcolor[1] := 0.41;
          ex^.lightcolor[2] := 0.75;
        end;
        ex^.ent.model := cl_mod_explode;
        ex^.frames := 4;
        S_StartSound(@pos, 0, 0, cl_sfx_lashit, 1, ATTN_NORM, 0);
      end;

    TE_LIGHTNING:
      begin
        ent := CL_ParseLightning(cl_mod_lightning);
        S_StartSound(nil, ent, CHAN_WEAPON, cl_sfx_lightning, 1, ATTN_NORM, 0);
      end;

    TE_DEBUGTRAIL:
      begin
        MSG_ReadPos(net_message, pos);
        MSG_ReadPos(net_message, pos2);
        CL_DebugTrail(pos, pos2);
      end;

    TE_PLAIN_EXPLOSION:
      begin
        MSG_ReadPos(net_message, pos);

        ex := CL_AllocExplosion();
        VectorCopy(pos, vec3_t(ex^.ent.origin));
        ex^.type_ := ex_poly;
        ex^.ent.flags := RF_FULLBRIGHT;
        ex^.start := cl.frame.servertime - 100;
        ex^.light := 350;
        ex^.lightcolor[0] := 1.0;
        ex^.lightcolor[1] := 0.5;
        ex^.lightcolor[2] := 0.5;
        ex^.ent.angles[1] := rand() mod 360;
        ex^.ent.model := cl_mod_explo4;
        if Random < 0.5 then            // was 'if (frand() < 0.5)'
          ex^.baseframe := 15;
        ex^.frames := 15;
        if (temp_event_t(type_) = TE_ROCKET_EXPLOSION_WATER) then
          S_StartSound(@pos, 0, 0, cl_sfx_watrexp, 1, ATTN_NORM, 0)
        else
          S_StartSound(@pos, 0, 0, cl_sfx_rockexp, 1, ATTN_NORM, 0);
      end;

    TE_FLASHLIGHT:
      begin
        MSG_ReadPos(net_message, pos);
        ent := MSG_ReadShort(net_message);
        CL_Flashlight(ent, pos);
      end;

    TE_FORCEWALL:
      begin
        MSG_ReadPos(net_message, pos);
        MSG_ReadPos(net_message, pos2);
        color := MSG_ReadByte(net_message);
        CL_ForceWall(pos, pos2, color);
      end;

    TE_HEATBEAM: ent := CL_ParsePlayerBeam(cl_mod_heatbeam);
    TE_MONSTER_HEATBEAM: ent := CL_ParsePlayerBeam(cl_mod_monster_heatbeam);

    TE_HEATBEAM_SPARKS:
      begin
        // cnt := MSG_ReadByte (net_message);
        cnt := 50;
        MSG_ReadPos(net_message, pos);
        MSG_ReadDir(net_message, dir);
        // r := MSG_ReadByte (net_message);
        // magnitude := MSG_ReadShort (net_message);
        r := 8;
        magnitude := 60;
        color := r and $FF;
        CL_ParticleSteamEffect(pos, dir, color, cnt, magnitude);
        S_StartSound(@pos, 0, 0, cl_sfx_lashit, 1, ATTN_NORM, 0);
      end;

    TE_HEATBEAM_STEAM:
      begin
        // cnt := MSG_ReadByte (net_message);
        cnt := 20;
        MSG_ReadPos(net_message, pos);
        MSG_ReadDir(net_message, dir);
        // r := MSG_ReadByte (net_message);
        // magnitude := MSG_ReadShort (net_message);
        // color := r & $ff;
        color := $E0;
        magnitude := 60;
        CL_ParticleSteamEffect(pos, dir, color, cnt, magnitude);
        S_StartSound(@pos, 0, 0, cl_sfx_lashit, 1, ATTN_NORM, 0);
      end;

    TE_STEAM: CL_ParseSteam();

    TE_BUBBLETRAIL2:
      begin
        // cnt := MSG_ReadByte (net_message);
        cnt := 8;
        MSG_ReadPos(net_message, pos);
        MSG_ReadPos(net_message, pos2);
        CL_BubbleTrail2(pos, pos2, cnt);
        S_StartSound(@pos, 0, 0, cl_sfx_lashit, 1, ATTN_NORM, 0);
      end;

    TE_MOREBLOOD:
      begin
        MSG_ReadPos(net_message, pos);
        MSG_ReadDir(net_message, dir);
        CL_ParticleEffect(pos, dir, $E8, 250);
      end;

    TE_CHAINFIST_SMOKE:
      begin
        dir[0] := 0;
        dir[1] := 0;
        dir[2] := 1;
        MSG_ReadPos(net_message, pos);
        CL_ParticleSmokeEffect(pos, dir, 0, 20, 20);
      end;

    TE_ELECTRIC_SPARKS:
      begin
        MSG_ReadPos(net_message, pos);
        MSG_ReadDir(net_message, dir);
        // CL_ParticleEffect (pos, dir, 109, 40);
        CL_ParticleEffect(pos, dir, $75, 40);
        //FIXME : replace or remove this sound
        S_StartSound(@pos, 0, 0, cl_sfx_lashit, 1, ATTN_NORM, 0);
      end;

    TE_TRACKER_EXPLOSION:
      begin
        MSG_ReadPos(net_message, pos);
        CL_ColorFlash(pos, 0, 150, -1, -1, -1);
        CL_ColorExplosionParticles(pos, 0, 1);
        // CL_Tracker_Explode (pos);
        S_StartSound(@pos, 0, 0, cl_sfx_disrexp, 1, ATTN_NORM, 0);
      end;

    TE_TELEPORT_EFFECT, TE_DBALL_GOAL:
      begin
        MSG_ReadPos(net_message, pos);
        CL_TeleportParticles(pos);
      end;

    TE_WIDOWBEAMOUT: CL_ParseWidow();
    TE_NUKEBLAST: CL_ParseNuke();

    TE_WIDOWSPLASH:
      begin
        MSG_ReadPos(net_message, pos);
        CL_WidowSplash(pos);
      end;
    //PGM
    //=======
  else
    Com_Error(ERR_DROP, 'CL_ParseTEnt: bad type');
  end;
end;

{
=========
CL_AddBeams
=========
}

procedure CL_AddBeams;
var
  i, j: Integer;
  b: Beam_p;
  Dist, Org: Vec3_t;
  d: Single;
  Ent: Entity_t;
  Yaw, Pitch, Forward_, Len, Steps, Model_length: Single;
begin
  // update beams
  for i := 0 to MAX_BEAMS - 1 do
  begin
    b := @cl_beams[i];
    if (b^.model = nil) or (b^.endtime < cl.time) then
      continue;

    // if coming from the player, update the start position
    if b^.entity = (cl.playernum + 1) then
    begin                               // entity 0 is the world
      VectorCopy(vec3_t(cl.refdef.vieworg), b.start);
      b^.Start[2] := b^.Start[2] - 22;  // adjust for view height
    end;
    VectorAdd(b^.start, b^.offset, org);

    // calculate pitch and yaw
    VectorSubtract(b^.end_, org, dist);

    if (dist[1] = 0) and (dist[0] = 0) then
    begin
      yaw := 0;
      if (dist[2] > 0) then
        pitch := 90
      else
        pitch := 270;
    end
    else
    begin
      // PMM - fixed to correct for pitch of 0
      if (dist[0] <> 0) then
        // was yaw := (atan2(dist[1], dist[0]) * 180 / M_PI)
        yaw := (ArcTan2(dist[1], dist[0]) * 180 / M_PI)
      else if (dist[1] > 0) then
        yaw := 90
      else
        yaw := 270;
      if (yaw < 0) then
        Yaw := Yaw + 360;

      forward_ := sqrt(Sqr(dist[0]) + Sqr(dist[1]));
      pitch := (ArcTan(dist[2] / forward_) * -180.0 / M_PI);
      if (pitch < 0) then
        Pitch := Pitch + 360;
    end;

    // add new entities for the beams
    d := VectorNormalize(dist);

    FillChar(ent, sizeof(ent), 0);
    if (b.model = cl_mod_lightning) then
    begin
      model_length := 35.0;
      d := d - 20;                      // correction so it doesn't end in middle of tesla
    end
    else
      model_length := 30.0;

    steps := ceil(d / model_length);
    len := (d - model_length) / (steps - 1);

    // PMM - special case for lightning model .. if the real length is shorter than the model,
    // flip it around & draw it from the end to the start.  This prevents the model from going
    // through the tesla mine (instead it goes through the target)
    if (b.model = cl_mod_lightning) and (d <= model_length) then
    begin
      // Com_Printf ('special case'#10);
      VectorCopy(b^.end_, vec3_t(ent.origin));
      // offset to push beam outside of tesla model (negative because dist is from end to start
      // for this beam)
    // for j := 0 to 2 do
    //  ent.origin[j] := ent.origin[j] - (dist[j]*10.0);
      ent.model := b.model;
      ent.flags := RF_FULLBRIGHT;
      ent.angles[0] := pitch;
      ent.angles[1] := yaw;
      ent.angles[2] := random(360);
      V_AddEntity(@ent);
      exit;
    end;
    while (d > 0) do
    begin
      VectorCopy(org, vec3_t(ent.origin));
      ent.model := b.model;
      if (b.model = cl_mod_lightning) then
      begin
        ent.flags := RF_FULLBRIGHT;
        ent.angles[0] := -pitch;
        ent.angles[1] := yaw + 180.0;
        ent.angles[2] := rand() mod 360;
      end
      else
      begin
        ent.angles[0] := pitch;
        ent.angles[1] := yaw;
        ent.angles[2] := rand() mod 360;
      end;

      // Com_Printf('B: %d ^. %d'#10, b.entity, b.dest_entity);
      V_AddEntity(@ent);

      for j := 0 to 2 do
        org[j] := org[j] + (Dist[j] * len);
      d := d - model_length;
    end;
  end;
end;

{
=========
ROGUE - draw player locked beams
CL_AddPlayerBeams
=========
}

procedure CL_AddPlayerBeams;
var
  i, j: Integer;
  b: Beam_p;
  Dist, Org, F, R, U, Len: Vec3_t;
  d: Single;
  Framenum: Integer;
  Ent: entity_t;
  Yaw, Pitch, Forward_, Len_, Steps, Model_length: Single;
  Hand_Multiplier: Single;
  Oldframe: frame_p;
  PS, OPS: player_State_p;
begin
  //PMM
  if (hand <> nil) then
  begin
    if (hand^.value = 2) then
      hand_multiplier := 0
    else if (hand^.value = 1) then
      hand_multiplier := -1
    else
      hand_multiplier := 1;
  end
  else
    hand_multiplier := 1;
  //PMM

  // update beams
  for i := 0 to MAX_BEAMS - 1 do
  begin
    b := @cl_playerbeams[i];
    if (b^.model = nil) or (b^.endtime < cl.time) then
      continue;

    if (cl_mod_heatbeam <> nil) and (b.model = cl_mod_heatbeam) then
    begin
      // if coming from the player, update the start position
      if b.entity = (cl.playernum + 1) then
      begin                             // entity 0 is the world
        // set up gun position
        // code straight out of CL_AddViewWeapon
        ps := @cl.frame.playerstate;
        j := (cl.frame.serverframe - 1) and UPDATE_MASK;
        oldframe := @cl.frames[j];
        if (oldframe^.serverframe <> cl.frame.serverframe - 1) or (not oldframe^.valid) then
          oldframe := @cl.frame;        // previous frame was dropped or involid
        ops := @oldframe^.playerstate;
        for j := 0 to 2 do
          b.start[j] := cl.refdef.vieworg[j] + ops^.gunoffset[j]
            + cl.lerpfrac * (ps^.gunoffset[j] - ops^.gunoffset[j]);
        VectorMA(b.start, (hand_multiplier * b.offset[0]), cl.v_right, org);
        VectorMA(org, b.offset[1], cl.v_forward, org);
        VectorMA(org, b.offset[2], cl.v_up, org);
        if (hand <> nil) and (hand^.value = 2) then
          VectorMA(org, -1, cl.v_up, org);
        // FIXME - take these out when final
        VectorCopy(cl.v_right, r);
        VectorCopy(cl.v_forward, f);
        VectorCopy(cl.v_up, u);
      end
      else
        VectorCopy(b.start, org);
    end
    else
    begin
      // if coming from the player, update the start position
      if b.entity = (cl.playernum + 1) then
      begin                             // entity 0 is the world
        VectorCopy(vec3_t(cl.refdef.vieworg), b.start);
        b.start[2] := b.start[2] - 22;  // adjust for view height
      end;
      VectorAdd(b.start, b.offset, org);
    end;

    // calculate pitch and yaw
    VectorSubtract(b.end_, org, dist);

    //PMM
    if (cl_mod_heatbeam <> nil) and (b.model = cl_mod_heatbeam) and (b.entity = (cl.playernum + 1)) then
    begin
      len_ := VectorLength(dist);
      VectorScale(f, len_, dist);
      VectorMA(dist, (hand_multiplier * b.offset[0]), r, dist);
      VectorMA(dist, b.offset[1], f, dist);
      VectorMA(dist, b.offset[2], u, dist);
      if (hand <> nil) and (hand^.value = 2) then
        VectorMA(org, -1, cl.v_up, org);
    end;
    //PMM

    if (dist[1] = 0) and (dist[0] = 0) then
    begin
      yaw := 0;
      if (dist[2] > 0) then
        pitch := 90
      else
        pitch := 270;
    end
    else
    begin
      // PMM - fixed to correct for pitch of 0
      if (dist[0] <> 0) then
        // was yaw := (atan2(dist[1], dist[0]) * 180 / M_PI)
        yaw := (ArcTan2(dist[1], dist[0]) * 180 / M_PI)
      else if (dist[1] > 0) then
        yaw := 90
      else
        yaw := 270;
      if (yaw < 0) then
        Yaw := Yaw + 360;

      forward_ := sqrt(Sqr(dist[0]) + Sqr(dist[1]));
      pitch := (ArcTan(dist[2] / forward_) * -180.0 / M_PI);
      if (pitch < 0) then
        Pitch := Pitch + 360;
    end;

    if (cl_mod_heatbeam <> nil) and (b.model = cl_mod_heatbeam) then
    begin
      if b.entity <> (cl.playernum + 1) then
      begin
        Framenum := 2;
        //  Com_Printf ('Third person\n');
        ent.angles[0] := -pitch;
        ent.angles[1] := yaw + 180.0;
        ent.angles[2] := 0;
        //  Com_Printf ('%f %f - %f %f %f\n', -pitch, yaw+180.0, b.offset[0], b.offset[1], b.offset[2]);
        AngleVectors(vec3_t(ent.angles), @f, @r, @u);

        // if it's a non-origin offset, it's a player, so use the hardcoded player offset
        if 0 = VectorCompare(b.offset, vec3_origin) then
        begin
          VectorMA(org, -(b.offset[0]) + 1, r, org);
          VectorMA(org, -(b.offset[1]), f, org);
          VectorMA(org, -(b.offset[2]) - 10, u, org);
        end
        else
        begin
          // if it's a monster, do the particle effect
          CL_MonsterPlasma_Shell(b.start);
        end;
      end
      else
      begin
        framenum := 1;
      end;
    end;

    // if it's the heatbeam, draw the particle effect
    if (cl_mod_heatbeam <> nil) and (b.model = cl_mod_heatbeam) and (b.entity = (cl.playernum + 1)) then
    begin
      CL_Heatbeam(org, dist);
    end;

    // add new entities for the beams
    d := VectorNormalize(dist);

    FillChar(ent, sizeof(ent), 0);
    if (b.model = cl_mod_heatbeam) then
    begin
      model_length := 32.0
    end
    else if (b.model = cl_mod_lightning) then
    begin
      model_length := 35.0;
      d := d - 20.0;                    // correction so it doesn't end in middle of tesla
    end
    else
      model_length := 30.0;
    steps := ceil(d / model_length);
    len_ := (d - model_length) / (steps - 1);

    // PMM - special case for lightning model .. if the real length is shorter than the model,
    // flip it around & draw it from the end to the start.  This prevents the model from going
    // through the tesla mine (instead it goes through the target)
    if (b.model = cl_mod_lightning) and (d <= model_length) then
    begin
      // Com_Printf ('special case\n');
      VectorCopy(b.end_, vec3_t(ent.origin));
      // offset to push beam outside of tesla model (negative because dist is from end to start
      // for this beam)
    // for j := 0 to 2 do
    //  ent.origin[j] := ent.origin[j] - dist[j]*10.0;
      ent.model := b.model;
      ent.flags := RF_FULLBRIGHT;
      ent.angles[0] := pitch;
      ent.angles[1] := yaw;
      ent.angles[2] := random(360);
      V_AddEntity(@ent);
      exit;
    end;
    while (d > 0) do
    begin
      VectorCopy(org, vec3_t(ent.origin));
      ent.model := b.model;
      if (cl_mod_heatbeam <> nil) and (b.model = cl_mod_heatbeam) then
      begin
        //  ent.flags := RF_FULLBRIGHT or RF_TRANSLUCENT;
        //  ent.alpha := 0.3;
        ent.flags := RF_FULLBRIGHT;
        ent.angles[0] := -pitch;
        ent.angles[1] := yaw + 180.0;
        ent.angles[2] := (cl.time) mod 360;
        //  ent.angles[2] := rand()%360;
        ent.frame := framenum;
      end
      else if (b.model = cl_mod_lightning) then
      begin
        ent.flags := RF_FULLBRIGHT;
        ent.angles[0] := -pitch;
        ent.angles[1] := yaw + 180.0;
        ent.angles[2] := rand() mod 360;
      end
      else
      begin
        ent.angles[0] := pitch;
        ent.angles[1] := yaw;
        ent.angles[2] := rand() mod 360;
      end;

      //  Com_Printf('B: %d ^. %d\n', b.entity, b.dest_entity);
      V_AddEntity(@ent);

      for j := 0 to 2 do
        org[j] := org[j] + dist[j] * len_;
      d := d - model_length;
    end;
  end;
end;

{
=========
CL_AddExplosions
=========
}

procedure CL_AddExplosions;
var
  Ent: Entity_p;
  i, f: Integer;
  Ex: Explosion_p;
  Frac: Single;
begin
  FillChar(ent, sizeof(ent), 0);

  for i := 0 to MAX_EXPLOSIONS - 1 do
  begin
    ex := @cl_explosions[i];
    if (ex.type_ = ex_free) then
      continue;
    Frac := (cl.time - ex.start) / 100.0;
    f := floor(frac);

    ent := @ex.ent;

    case ex.type_ of
      ex_mflash: if (f >= ex.frames - 1) then
          ex.type_ := ex_free;
      ex_misc:
        if (f >= ex.frames - 1) then
          ex.type_ := ex_free
        else
          ent^.alpha := 1.0 - frac / (ex.frames - 1);
      ex_flash:
        if (f >= 1) then
          ex.type_ := ex_free
        else
          ent^.alpha := 1.0;
      ex_poly:
        begin
          if (f >= ex.frames - 1) then
            ex.type_ := ex_free
          else
          begin
            ent^.alpha := (16.0 - f) / 16.0;

            if (f < 10) then
            begin
              ent^.skinnum := (f shr 1);
              if (ent^.skinnum < 0) then
                ent^.skinnum := 0;
            end
            else
            begin
              ent^.flags := ent^.flags or RF_TRANSLUCENT;
              if (f < 13) then
                ent^.skinnum := 5
              else
                ent^.skinnum := 6;
            end;
          end;
        end;
      ex_poly2:
        if (f >= ex.frames - 1) then
          ex.type_ := ex_free
        else
        begin
          ent^.alpha := (5.0 - f) / 5.0;
          ent^.skinnum := 0;
          ent^.flags := ent^.flags or RF_TRANSLUCENT;
        end;
    end;

    if (ex.type_ = ex_free) then
      continue;
    if (ex.light <> 0) then
      V_AddLight(vec3_t(ent^.origin), ex.light * ent^.alpha, ex.lightcolor[0], ex.lightcolor[1], ex.lightcolor[2]);

    VectorCopy(vec3_t(ent^.origin), vec3_t(ent^.oldorigin));

    if (f < 0) then
      f := 0;
    ent^.frame := ex.baseframe + f + 1;
    ent^.oldframe := ex.baseframe + f;
    ent^.backlerp := 1.0 - cl.lerpfrac;

    V_AddEntity(ent);
  end;
end;

{
=========
CL_AddLasers
=========
}

procedure CL_AddLasers;
var
  l: Laser_p;
  i: Integer;
begin
  for i := 0 to MAX_LASERS - 1 do
  begin
    l := @cl_lasers[i];
    if (l^.endtime >= cl.time) then
      V_AddEntity(@l^.ent);
  end;
end;

{ PMM - CL_Sustains }

procedure CL_ProcessSustain();
var
  s: cl_sustain_p;
  i: Integer;
begin
  for i := 0 to MAX_SUSTAINS - 1 do
  begin
    s := @cl_sustains[i];
    if (s.id <> 0) then
      if ((s.endtime >= cl.time) and (cl.time >= s.nextthink)) then
      begin
        // Com_Printf ('think %d %d %d'#10, cl.time, s^.nextthink, s^.thinkinterval);
        s.think(s);
      end
      else if (s.endtime < cl.time) then
        s.id := 0;
  end;
end;

{
=========
CL_AddTEnts
=========
}

procedure CL_AddTEnts;
begin
  CL_AddBeams();
  // PMM - draw plasma beams
  CL_AddPlayerBeams();
  CL_AddExplosions();
  CL_AddLasers();
  // PMM - set up sustain
  CL_ProcessSustain();
end;

end.
