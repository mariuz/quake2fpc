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
{ File(s): cl_ents.c                                                        }
{ Content: Quake2\Client - builds an intended movement command to send to the server }
{                                                                            }
{ Initial conversion by : Dart - hanhpham@web.de                           }
{ Initial conversion on : 04-April-2002                                        }
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
{ * Updated:                                                                         }
{ 03-Jun-2002 Juha Hartikainen (juha@linearteam.org)                         }
{ - MANY language fixes                                                      }
{                                                                            }
{ 08-Jun-2002 Juha Hartikainen (juha@linearteam.org)                         }
{ - Finished conversion.                                                     }
{                                                                            }
{ * ToDo:                                                                    }
{ - All places with TODO define                                              }
{----------------------------------------------------------------------------}

{.$DEFINE TODO}
unit cl_ents;

interface

uses
  client,
  q_shared_add,
  q_shared;

procedure CL_AddEntities;
procedure CL_GetEntitySoundOrigin(ent: integer; var org: vec3_t);
function CL_ParseEntityBits(bits: PCardinal): integer;
procedure CL_ParseDelta(pfrom: entity_state_p; pto: entity_state_p; number: integer; bits: integer);
procedure CL_ParseFrame;

var
  //PGM
  vidref_val: integer;
  //PGM

implementation

uses
  Common,
  CPas,
  net_chan,
  cl_scrn,
  cl_pred,
  cl_main,
  cl_view,
  Files,
  ref,
  cl_parse,
  cl_newfx,
  cl_tent,
  {$IFDEF WIN32}
  vid_dll,
  {$ELSE}
  vid_so,
  {$ENDIF}
  cl_fx;

{*
=========================================================================

FRAME PARSING

=========================================================================
*}

{*
=================
CL_ParseEntityBits

Returns the entity number and the header bits
=================
*}
var
  bitcounts: array[0..32 - 1] of integer; /// just for protocol profiling

function CL_ParseEntityBits(bits: PCardinal): integer;
var
  b, total: Cardinal;
  i: integer;
  number: integer;
begin
  total := MSG_ReadByte(net_message);
  if (total and U_MOREBITS1 <> 0) then
  begin
    b := MSG_ReadByte(net_message);
    total := total or (b shl 8);
  end;
  if (total and U_MOREBITS2 <> 0) then
  begin
    b := MSG_ReadByte(net_message);
    total := total or (b shl 16);
  end;
  if (total and U_MOREBITS3 <> 0) then
  begin
    b := MSG_ReadByte(net_message);
    total := total or (b shl 24);
  end;
  // count the bits for net profiling
  for i := 0 to 32 - 1 do
    if (total and (1 shl i)) > 0 then
      inc(bitcounts[i]);
  if (total and U_NUMBER16 <> 0) then
    number := MSG_ReadShort(net_message)
  else
    number := MSG_ReadByte(net_message);
  bits^ := total;
  result := number;
end;

{*
==================
CL_ParseDelta

Can go from either a baseline or a previous packet_entity
==================
*}
procedure CL_ParseDelta(pfrom: entity_state_p; pto: entity_state_p; number: integer; bits: integer);
begin                                   // set everything to the state we are delta'ing from
  pto^ := pfrom^;

  VectorCopy(pfrom.origin, pto.old_origin);
  pto.number := number;

  if (bits and U_MODEL <> 0) then
    pto.modelindex := MSG_ReadByte(net_message);
  if (bits and U_MODEL2 <> 0) then
    pto.modelindex2 := MSG_ReadByte(net_message);
  if (bits and U_MODEL3 <> 0) then
    pto.modelindex3 := MSG_ReadByte(net_message);
  if (bits and U_MODEL4 <> 0) then
    pto.modelindex4 := MSG_ReadByte(net_message);
  if (bits and U_FRAME8 <> 0) then
    pto.frame := MSG_ReadByte(net_message);
  if (bits and U_FRAME16 <> 0) then
    pto.frame := MSG_ReadShort(net_message);

  if (bits and U_SKIN8 <> 0) and
    (bits and U_SKIN16 <> 0) then       //used for laser colors
    pto.skinnum := MSG_ReadLong(net_message)
  else if (bits and U_SKIN8 <> 0) then
    pto.skinnum := MSG_ReadByte(net_message)
  else if (bits and U_SKIN16 <> 0) then
    pto.skinnum := MSG_ReadShort(net_message);

  if ((bits and (U_EFFECTS8 or U_EFFECTS16)) = (U_EFFECTS8 or U_EFFECTS16)) then
    pto.effects := MSG_ReadLong(net_message)
  else if (bits and U_EFFECTS8 <> 0) then
    pto.effects := MSG_ReadByte(net_message)
  else if (bits and U_EFFECTS16 <> 0) then
    pto.effects := MSG_ReadShort(net_message);

  if ((bits and (U_RENDERFX8 or U_RENDERFX16)) = (U_RENDERFX8 or U_RENDERFX16)) then
    pto.renderfx := MSG_ReadLong(net_message)
  else if (bits and U_RENDERFX8 <> 0) then
    pto.renderfx := MSG_ReadByte(net_message)
  else if (bits and U_RENDERFX16 <> 0) then
    pto.renderfx := MSG_ReadShort(net_message);

  if (bits and U_ORIGIN1 <> 0) then
    pto.origin[0] := MSG_ReadCoord(net_message);
  if (bits and U_ORIGIN2 <> 0) then
    pto.origin[1] := MSG_ReadCoord(net_message);
  if (bits and U_ORIGIN3 <> 0) then
    pto.origin[2] := MSG_ReadCoord(net_message);

  if (bits and U_ANGLE1 <> 0) then
    pto.angles[0] := MSG_ReadAngle(net_message);
  if (bits and U_ANGLE2 <> 0) then
    pto.angles[1] := MSG_ReadAngle(net_message);
  if (bits and U_ANGLE3 <> 0) then
    pto.angles[2] := MSG_ReadAngle(net_message);

  if (bits and U_OLDORIGIN <> 0) then
    MSG_ReadPos(net_message, pto.old_origin);

  if (bits and U_SOUND <> 0) then
    pto.sound := MSG_ReadByte(net_message);

  if (bits and U_EVENT <> 0) then
    pto.event := entity_event_t(MSG_ReadByte(net_message))
  else
    pto.event := entity_event_t(0);

  if (bits and U_SOLID <> 0) then
    pto.solid := MSG_ReadShort(net_message);
end;

{*
==================
CL_DeltaEntity

Parses deltas from the given base and adds the resulting entity
to the current frame
==================
*}
procedure CL_DeltaEntity(frame: frame_p; newnum: integer; old: entity_state_p; bits: integer);
var
  ent: centity_p;
  state: entity_state_p;
begin
  ent := @cl_entities[newnum];

  state := @cl_parse_entities[cl.parse_entities and (MAX_PARSE_ENTITIES - 1)];
  inc(cl.parse_entities);
  inc(frame.num_entities);
  CL_ParseDelta(old, state, newnum, bits);

  // some data changes will force no lerping
  if (state.modelindex <> ent.current.modelindex) or
    (state.modelindex2 <> ent.current.modelindex2) or
    (state.modelindex3 <> ent.current.modelindex3) or
    (state.modelindex4 <> ent.current.modelindex4) or
    (abs(state.origin[0] - ent.current.origin[0]) > 512) or
    (abs(state.origin[1] - ent.current.origin[1]) > 512) or
    (abs(state.origin[2] - ent.current.origin[2]) > 512) or
    (state.event = EV_PLAYER_TELEPORT) or
    (state.event = EV_OTHER_TELEPORT) then
    ent.serverframe := -99;

  if (ent.serverframe <> cl.frame.serverframe - 1) then
  begin                                 // wasn't in last update, so initialize some things
    ent.trailcount := 1024;             // for diminishing rocket / grenade trails
    // duplicate the current state so lerping doesn't hurt anything
    ent.prev := state^;
    if (state.event = EV_OTHER_TELEPORT) then
    begin
      VectorCopy(state.origin, ent.prev.origin);
      VectorCopy(state.origin, ent.lerp_origin);
    end
    else
    begin
      VectorCopy(state.old_origin, ent.prev.origin);
      VectorCopy(state.old_origin, ent.lerp_origin);
    end;
  end
  else
  begin                                 // shuffle the last state to previous
    ent.prev := ent.current;
  end;

  ent.serverframe := cl.frame.serverframe;
  ent.current := state^;
end;

{*
==================
CL_ParsePacketEntities

An svc_packetentities has just been parsed, deal with the
rest of the data stream.
==================
*}
procedure CL_ParsePacketEntities(oldframe: frame_p; newframe: frame_p);
var
  newnum: integer;
  bits: Cardinal;
  oldstate: entity_state_p;
  oldindex, oldnum: integer;
begin
  newframe^.parse_entities := cl.parse_entities;
  newframe^.num_entities := 0;

  // delta from the entities present in oldframe
  oldindex := 0;
  if (oldframe = nil) then
    oldnum := 99999
  else
  begin
    if (oldindex >= oldframe^.num_entities) then
      oldnum := 99999
    else
    begin
      oldstate := @cl_parse_entities[(oldframe^.parse_entities + oldindex) and (MAX_PARSE_ENTITIES - 1)];
      oldnum := oldstate^.number;
    end;
  end;

  while (true) do
  begin
    newnum := CL_ParseEntityBits(@bits);
    if (newnum >= MAX_EDICTS) then
      Com_Error(ERR_DROP, 'CL_ParsePacketEntities: bad number:%d', [newnum]);

    if (net_message.readcount > net_message.cursize) then
      Com_Error(ERR_DROP, 'CL_ParsePacketEntities: end of message', []);

    if (newnum = 0) then
      break;

    while (oldnum < newnum) do
    begin                               // one or more entities from the old packet are unchanged
      if (cl_shownet.value = 3) then
        Com_Printf('   unchanged: %d'#10, [oldnum]);
      CL_DeltaEntity(newframe, oldnum, oldstate, 0);

      inc(oldindex);

      if (oldindex >= oldframe^.num_entities) then
        oldnum := 99999
      else
      begin
        oldstate := @cl_parse_entities[(oldframe^.parse_entities + oldindex) and (MAX_PARSE_ENTITIES - 1)];
        oldnum := oldstate.number;
      end;
    end;

    if (bits and U_REMOVE <> 0) then
    begin                               // the entity present in oldframe is not in the current frame
      if (cl_shownet.value = 3) then
        Com_Printf('   remove: %d'#10, [newnum]);
      if (oldnum <> newnum) then
        Com_Printf('U_REMOVE: oldnum != newnum'#10, []);

      inc(oldindex);

      if (oldindex >= oldframe.num_entities) then
        oldnum := 99999
      else
      begin
        oldstate := @cl_parse_entities[(oldframe^.parse_entities + oldindex) and (MAX_PARSE_ENTITIES - 1)];
        oldnum := oldstate^.number;
      end;
      continue;
    end;

    if (oldnum = newnum) then
    begin                               // delta from previous state
      if (cl_shownet.value = 3) then
        Com_Printf('   delta: %d'#10, [newnum]);
      CL_DeltaEntity(newframe, newnum, oldstate, bits);

      inc(oldindex);

      if (oldindex >= oldframe^.num_entities) then
        oldnum := 99999
      else
      begin
        oldstate := @cl_parse_entities[(oldframe^.parse_entities + oldindex) and (MAX_PARSE_ENTITIES - 1)];
        oldnum := oldstate^.number;
      end;
      continue;
    end;

    if (oldnum > newnum) then
    begin                               // delta from baseline
      if (cl_shownet.value = 3) then
        Com_Printf('   baseline: %d'#10, [newnum]);
      CL_DeltaEntity(newframe, newnum, @cl_entities[newnum].baseline, bits);
      continue;
    end;

  end;

  // any remaining entities in the old frame are copied over
  while (oldnum <> 99999) do
  begin                                 // one or more entities from the old packet are unchanged
    if (cl_shownet.value = 3) then
      Com_Printf('   unchanged: %d'#10, [oldnum]);
    CL_DeltaEntity(newframe, oldnum, oldstate, 0);

    inc(oldindex);

    if (oldindex >= oldframe.num_entities) then
      oldnum := 99999
    else
    begin
      oldstate := @cl_parse_entities[(oldframe^.parse_entities + oldindex) and (MAX_PARSE_ENTITIES - 1)];
      oldnum := oldstate.number;
    end;
  end;
end;

{*
===================
CL_ParsePlayerstate
===================
*}
procedure CL_ParsePlayerstate(oldframe: frame_p; newframe: frame_p);
var
  flags: integer;
  state: player_state_p;
  i: integer;
  statbits: integer;
begin
  state := @newframe.playerstate;

  // clear to old value before delta parsing
  if (oldframe <> nil) then
    state^ := oldframe.playerstate
  else
    FillChar(state^, sizeof(player_state_t), 0);

  flags := MSG_ReadShort(net_message);

  //
  // parse the pmove_state_t
  //
  if (flags and PS_M_TYPE <> 0) then
    state.pmove.pm_type := pmtype_t(MSG_ReadByte(net_message));

  if (flags and PS_M_ORIGIN <> 0) then
  begin
    state.pmove.origin[0] := MSG_ReadShort(net_message);
    state.pmove.origin[1] := MSG_ReadShort(net_message);
    state.pmove.origin[2] := MSG_ReadShort(net_message);
  end;

  if (flags and PS_M_VELOCITY <> 0) then
  begin
    state.pmove.velocity[0] := MSG_ReadShort(net_message);
    state.pmove.velocity[1] := MSG_ReadShort(net_message);
    state.pmove.velocity[2] := MSG_ReadShort(net_message);
  end;

  if (flags and PS_M_TIME <> 0) then
    state.pmove.pm_time := MSG_ReadByte(net_message);

  if (flags and PS_M_FLAGS <> 0) then
    state.pmove.pm_flags := MSG_ReadByte(net_message);

  if (flags and PS_M_GRAVITY <> 0) then
    state.pmove.gravity := MSG_ReadShort(net_message);

  if (flags and PS_M_DELTA_ANGLES <> 0) then
  begin
    state.pmove.delta_angles[0] := MSG_ReadShort(net_message);
    state.pmove.delta_angles[1] := MSG_ReadShort(net_message);
    state.pmove.delta_angles[2] := MSG_ReadShort(net_message);
  end;

  if (cl.attractloop) then
    state.pmove.pm_type := PM_FREEZE;   // demo playback

  //
  // parse the rest of the player_state_t
  //
  if (flags and PS_VIEWOFFSET <> 0) then
  begin
    state.viewoffset[0] := MSG_ReadChar(net_message) * 0.25;
    state.viewoffset[1] := MSG_ReadChar(net_message) * 0.25;
    state.viewoffset[2] := MSG_ReadChar(net_message) * 0.25;
  end;

  if (flags and PS_VIEWANGLES <> 0) then
  begin
    state.viewangles[0] := MSG_ReadAngle16(net_message);
    state.viewangles[1] := MSG_ReadAngle16(net_message);
    state.viewangles[2] := MSG_ReadAngle16(net_message);
  end;

  if (flags and PS_KICKANGLES <> 0) then
  begin
    state.kick_angles[0] := MSG_ReadChar(net_message) * 0.25;
    state.kick_angles[1] := MSG_ReadChar(net_message) * 0.25;
    state.kick_angles[2] := MSG_ReadChar(net_message) * 0.25;
  end;

  if (flags and PS_WEAPONINDEX <> 0) then
  begin
    state.gunindex := MSG_ReadByte(net_message);
  end;

  if (flags and PS_WEAPONFRAME <> 0) then
  begin
    state.gunframe := MSG_ReadByte(net_message);
    state.gunoffset[0] := MSG_ReadChar(net_message) * 0.25;
    state.gunoffset[1] := MSG_ReadChar(net_message) * 0.25;
    state.gunoffset[2] := MSG_ReadChar(net_message) * 0.25;
    state.gunangles[0] := MSG_ReadChar(net_message) * 0.25;
    state.gunangles[1] := MSG_ReadChar(net_message) * 0.25;
    state.gunangles[2] := MSG_ReadChar(net_message) * 0.25;
  end;

  if (flags and PS_BLEND <> 0) then
  begin
    state.blend[0] := MSG_ReadByte(net_message) / 255.0;
    state.blend[1] := MSG_ReadByte(net_message) / 255.0;
    state.blend[2] := MSG_ReadByte(net_message) / 255.0;
    state.blend[3] := MSG_ReadByte(net_message) / 255.0;
  end;

  if (flags and PS_FOV <> 0) then
    state.fov := MSG_ReadByte(net_message);

  if (flags and PS_RDFLAGS <> 0) then
    state.rdflags := MSG_ReadByte(net_message);

  // parse stats
  statbits := MSG_ReadLong(net_message);
  for i := 0 to MAX_STATS - 1 do
    if (statbits and (1 shl i) <> 0) then
      state.stats[i] := MSG_ReadShort(net_message);
end;

{*
==================
CL_FireEntityEvents

==================
*}
procedure CL_FireEntityEvents(frame: frame_p);
var
  s1: entity_state_p;
  pnum, num: integer;
begin
  for pnum := 0 to frame.num_entities - 1 do
  begin
    num := (frame.parse_entities + pnum) and (MAX_PARSE_ENTITIES - 1);
    s1 := @cl_parse_entities[num];
    if (Integer(s1.event) <> 0) then
      CL_EntityEvent(s1);
    // EF_TELEPORTER acts like an event, but is not cleared each frame
    if (s1.effects and EF_TELEPORTER <> 0) then
      CL_TeleporterParticles(s1);
  end;
end;

{*
================
CL_ParseFrame
================
*}
procedure CL_ParseFrame;
var
  cmd: integer;
  len: integer;
  old: frame_p;
begin
  fillchar(cl.frame, sizeof(cl.frame), 0);

  {
   CL_ClearProjectiles(); // clear projectiles for new frame
  }

  cl.frame.serverframe := MSG_ReadLong(net_message);
  cl.frame.deltaframe := MSG_ReadLong(net_message);
  cl.frame.servertime := cl.frame.serverframe * 100;

  // BIG HACK to let old demos continue to work
  if (cls.serverProtocol <> 26) then
    cl.surpressCount := MSG_ReadByte(net_message);

  if (cl_shownet.value = 3) then
    Com_Printf('   frame:%d  delta:%d'#10, [cl.frame.serverframe,
      cl.frame.deltaframe]);

  // If the frame is delta compressed from data that we
  // no longer have available, we must suck up the rest of
  // the frame, but not use it, then ask for a non-compressed
  // message
  if (cl.frame.deltaframe <= 0) then
  begin
    cl.frame.valid := true;             // uncompressed frame
    old := nil;
    cls.demowaiting := false;           // we can start recording now
  end
  else
  begin
    old := @cl.frames[cl.frame.deltaframe and UPDATE_MASK];
    if (not old.valid) then
    begin                               // should never happen
      Com_Printf('Delta from invalid frame (not supposed to happen!).'#10, []);
    end;
    if (old.serverframe <> cl.frame.deltaframe) then
    begin                               // The frame that the server did the delta from
      // is too old, so we can't reconstruct it properly.
      Com_Printf('Delta frame too old.'#10, []);
    end
    else if (cl.parse_entities - old.parse_entities > MAX_PARSE_ENTITIES - 128) then
    begin
      Com_Printf('Delta parse_entities too old.'#10, []);
    end
    else
      cl.frame.valid := true;           // valid delta parse
  end;

  // clamp time
  if (cl.time > cl.frame.servertime) then
    cl.time := cl.frame.servertime
  else if (cl.time < cl.frame.servertime - 100) then
    cl.time := cl.frame.servertime - 100;

  // read areabits
  len := MSG_ReadByte(net_message);
  MSG_ReadData(net_message, @cl.frame.areabits, len);

  // read playerinfo
  cmd := MSG_ReadByte(net_message);
  SHOWNET(svc_strings[cmd]);
  if (cmd <> Integer(svc_playerinfo)) then
    Com_Error(ERR_DROP, 'CL_ParseFrame: not playerinfo', []);
  CL_ParsePlayerstate(old, @cl.frame);

  // read packet entities
  cmd := MSG_ReadByte(net_message);
  SHOWNET(svc_strings[cmd]);
  if (cmd <> Integer(svc_packetentities)) then
    Com_Error(ERR_DROP, 'CL_ParseFrame: not packetentities', []);
  CL_ParsePacketEntities(old, @cl.frame);

  {
   if (cmd = svc_packetentities2) then
    CL_ParseProjectiles();
  }

   // save the frame off in the backup array for later delta comparisons
  cl.frames[cl.frame.serverframe and UPDATE_MASK] := cl.frame;

  if (cl.frame.valid) then
  begin                                 // getting a valid frame message ends the connection process
    if (cls.state <> ca_active) then
    begin
      cls.state := ca_active;
      cl.force_refdef := true;
      cl.predicted_origin[0] := cl.frame.playerstate.pmove.origin[0] * 0.125;
      cl.predicted_origin[1] := cl.frame.playerstate.pmove.origin[1] * 0.125;
      cl.predicted_origin[2] := cl.frame.playerstate.pmove.origin[2] * 0.125;
      VectorCopy(cl.frame.playerstate.viewangles, cl.predicted_angles);
      if (cls.disable_servercount <> cl.servercount) and
        (cl.refresh_prepped) then
        SCR_EndLoadingPlaque();         // get rid of loading plaque
    end;
    cl.sound_prepped := true;           // can start mixing ambient sounds

    // fire entity events
    CL_FireEntityEvents(@cl.frame);
    CL_CheckPredictionError();
  end;
end;

{*
==========================================================================

INTERPOLATE BETWEEN FRAMES TO GET RENDERING PARMS

==========================================================================
*}

function S_RegisterSexedModel(ent: entity_state_p; base: pchar): model_p;
var
  n: integer;
  p: pchar;
  mdl: model_p;
  model: array[0..MAX_QPATH - 1] of char;
  buffer: array[0..MAX_QPATH - 1] of char;
begin
  // determine what model the client is using
  model[0] := #0;
  n := CS_PLAYERSKINS + ent.number - 1;
  if (cl.configstrings[n][0] <> #0) then
  begin
    p := strchr(cl.configstrings[n], Byte('\'));
    if (p <> nil) then
    begin
      p := p + 1;
      strcpy(model, p);
      p := strchr(model, Byte('/'));
      if (p <> nil) then
        p^ := #0;
    end;
  end;
  // if we can't figure it out, they're male
  if (model[0] = #0) then
    strcpy(model, 'male');

  Com_sprintf(buffer, sizeof(buffer), 'players/%s/%s', [model, base + 1]);
  mdl := re.RegisterModel(buffer);
  if (mdl = nil) then
  begin
    // not found, try default weapon model
    Com_sprintf(buffer, sizeof(buffer), 'players/%s/weapon.md2', [model]);
    mdl := re.RegisterModel(buffer);
    if (mdl = nil) then
    begin
      // no, revert to the male model
      Com_sprintf(buffer, sizeof(buffer), 'players/%s/%s', ['male', base + 1]);
      mdl := re.RegisterModel(buffer);
      if (mdl = nil) then
      begin
        // last try, default male weapon.md2
        Com_sprintf(buffer, sizeof(buffer), 'players/male/weapon.md2', []);
        mdl := re.RegisterModel(buffer);
      end;
    end;
  end;

  Result := mdl;
end;

{*
===============
CL_AddPacketEntities

===============
*}
var
  bfg_lightramp: array[0..5] of integer = (300, 400, 600, 300, 150, 75);

procedure CL_AddPacketEntities(frame: frame_p);
var
  ent: entity_t;
  s1: entity_state_p;
  autorotate: single;
  i: integer;
  pnum: integer;
  cent: centity_p;
  autoanim: integer;
  ci: clientinfo_p;
  effects, renderfx: LongWord;
  forward_, start: vec3_t;
  a1, a2: single;
  intensity: single;
begin
  // bonus items rotate at a fixed rate
  autorotate := anglemod(cl.time / 10);

  // brush models can auto animate their frames
  autoanim := Trunc(2 * cl.time / 1000);

  FillChar(ent, sizeof(ent), #0);

  for pnum := 0 to frame.num_entities - 1 do
  begin
    s1 := @cl_parse_entities[(frame.parse_entities + pnum) and (MAX_PARSE_ENTITIES - 1)];

    cent := @cl_entities[s1.number];

    effects := s1.effects;
    renderfx := s1.renderfx;

    // set frame
    if (effects and EF_ANIM01 <> 0) then
      ent.frame := autoanim and 1
    else if (effects and EF_ANIM23 <> 0) then
      ent.frame := 2 + (autoanim and 1)
    else if (effects and EF_ANIM_ALL <> 0) then
      ent.frame := autoanim
    else if (effects and EF_ANIM_ALLFAST <> 0) then
      ent.frame := Trunc(cl.time / 100)
    else
      ent.frame := s1.frame;

    // quad and pent can do different things on client
    if (effects and EF_PENT <> 0) then
    begin
      effects := effects and (not EF_PENT);
      effects := effects or EF_COLOR_SHELL;
      renderfx := renderfx or RF_SHELL_RED;
    end;

    if (effects and EF_QUAD <> 0) then
    begin
      effects := effects and (not EF_QUAD);
      effects := effects or EF_COLOR_SHELL;
      renderfx := renderfx or RF_SHELL_BLUE;
    end;
    //======
    // PMM
    if (effects and EF_DOUBLE <> 0) then
    begin
      effects := effects and (not EF_DOUBLE);
      effects := effects or EF_COLOR_SHELL;
      renderfx := renderfx or RF_SHELL_DOUBLE;
    end;

    if (effects and EF_HALF_DAMAGE <> 0) then
    begin
      effects := effects and (not EF_HALF_DAMAGE);
      effects := effects or EF_COLOR_SHELL;
      renderfx := effects or RF_SHELL_HALF_DAM;
    end;
    // pmm
    //======
    ent.oldframe := cent.prev.frame;
    ent.backlerp := 1.0 - cl.lerpfrac;

    if ((renderfx and (RF_FRAMELERP or RF_BEAM)) <> 0) then
    begin
      // step origin discretely, because the frames
      // do the animation properly
      VectorCopy(cent.current.origin, vec3_t(ent.origin));
      VectorCopy(cent.current.old_origin, vec3_t(ent.oldorigin));
    end
    else
    begin                               // interpolate origin
      for i := 0 to 2 do
      begin
        ent.origin[i] := cent.prev.origin[i] + cl.lerpfrac *
          (cent.current.origin[i] - cent.prev.origin[i]);
        ent.oldorigin[i] := ent.origin[i];
      end;
    end;

    // create a new entity

    // tweak the color of beams
    if ((renderfx and RF_BEAM) <> 0) then
    begin
      // the four beam colors are encoded in 32 bits of skinnum (hack)
      ent.alpha := 0.30;
      ent.skinnum := (s1.skinnum shr ((rand() mod 4) * 8)) and $FF;
      ent.model := nil;
    end
    else
    begin
      // set skin
      if (s1.modelindex = 255) then
      begin
        // use custom player skin
        ent.skinnum := 0;
        ci := @cl.clientinfo[s1.skinnum and $FF];
        ent.skin := ci.skin;
        ent.model := ci.model;
        if (ent.skin = nil) or (ent.model = nil) then
        begin
          ent.skin := cl.baseclientinfo.skin;
          ent.model := cl.baseclientinfo.model;
        end;

        //============
        //PGM
        if ((renderfx and RF_USE_DISGUISE) <> 0) then
        begin
          if (strncmp(ent.skin, 'players/male', 12) = 0) then
          begin
            ent.skin := re.RegisterSkin('players/male/disguise.pcx');
            ent.model := re.RegisterModel('players/male/tris.md2');
          end
          else if (strncmp(ent.skin, 'players/female', 14) = 0) then
          begin
            ent.skin := re.RegisterSkin('players/female/disguise.pcx');
            ent.model := re.RegisterModel('players/female/tris.md2');
          end
          else if (strncmp(ent.skin, 'players/cyborg', 14) = 0) then
          begin
            ent.skin := re.RegisterSkin('players/cyborg/disguise.pcx');
            ent.model := re.RegisterModel('players/cyborg/tris.md2');
          end;
        end;
        //PGM
        //============
      end
      else
      begin
        ent.skinnum := s1.skinnum;
        ent.skin := nil;
        ent.model := cl.model_draw[s1.modelindex];
      end;
    end;

    // only used for black hole model right now, FIXME: do better
    if (renderfx = RF_TRANSLUCENT) then
      ent.alpha := 0.70;

    // render effects (fullbright, translucent, etc)
    if ((effects and EF_COLOR_SHELL) <> 0) then
      ent.flags := 0                    // renderfx go on color shell entity
    else
      ent.flags := renderfx;

    // calculate angles
    if ((effects and EF_ROTATE) <> 0) then
    begin
      // some bonus items auto-rotate
      ent.angles[0] := 0;
      ent.angles[1] := autorotate;
      ent.angles[2] := 0;
    end
      // RAFAEL
    else if ((effects and EF_SPINNINGLIGHTS) <> 0) then
    begin
      ent.angles[0] := 0;
      ent.angles[1] := anglemod(cl.time / 2) + s1.angles[1];
      ent.angles[2] := 180;
      begin
        AngleVectors(vec3_t(ent.angles), @forward_, nil, nil);
        VectorMA(vec3_t(ent.origin), 64, forward_, start);
        V_AddLight(start, 100, 1, 0, 0);
      end;
    end
    else
    begin                               // interpolate angles
      for i := 0 to 2 do
      begin
        a1 := cent.current.angles[i];
        a2 := cent.prev.angles[i];
        ent.angles[i] := LerpAngle(a2, a1, cl.lerpfrac);
      end;
    end;

    if (s1.number = cl.playernum + 1) then
    begin
      ent.flags := ent.flags or RF_VIEWERMODEL; // only draw from mirrors
      // FIXME: still pass to refresh

      if (effects and EF_FLAG1 <> 0) then
        V_AddLight(vec3_t(ent.origin), 225, 1.0, 0.1, 0.1)
      else if (effects and EF_FLAG2 <> 0) then
        V_AddLight(vec3_t(ent.origin), 225, 0.1, 0.1, 1.0)
      else if (effects and EF_TAGTRAIL <> 0) then //PGM
        V_AddLight(vec3_t(ent.origin), 225, 1.0, 1.0, 0.0) //PGM
      else if (effects and EF_TRACKERTRAIL <> 0) then //PGM
        V_AddLight(vec3_t(ent.origin), 225, -1.0, -1.0, -1.0); //PGM

      continue;
    end;

    // if set to invisible, skip
    if (s1.modelindex = 0) then
      continue;

    if ((effects and EF_BFG) <> 0) then
    begin
      ent.flags := ent.flags or RF_TRANSLUCENT;
      ent.alpha := 0.30;
    end;

    // RAFAEL
    if ((effects and EF_PLASMA) <> 0) then
    begin
      ent.flags := ent.flags or RF_TRANSLUCENT;
      ent.alpha := 0.6;
    end;

    if ((effects and EF_SPHERETRANS) <> 0) then
    begin
      ent.flags := ent.flags or RF_TRANSLUCENT;
      // PMM - *sigh*  yet more EF overloading
      if ((effects and EF_TRACKERTRAIL) <> 0) then
        ent.alpha := 0.6
      else
        ent.alpha := 0.3;
    end;
    //pmm

      // add to refresh list
    V_AddEntity(@ent);

    // color shells generate a seperate entity for the main model
    if ((effects and EF_COLOR_SHELL) <> 0) then
    begin
      // PMM - at this point, all of the shells have been handled
      // if we're in the rogue pack, set up the custom mixing, otherwise just
      // keep going
   //         if(Developer_searchpath(2) == 2)
   //         {
       // all of the solo colors are fine.  we need to catch any of the combinations that look bad
       // (double & half) and turn them into the appropriate color, and make double/quad something special
      if ((renderfx and RF_SHELL_HALF_DAM) <> 0) then
      begin
        if (Developer_searchpath(2) = 2) then
        begin
          // ditch the half damage shell if any of red, blue, or double are on
          if (renderfx and (RF_SHELL_RED or RF_SHELL_BLUE or RF_SHELL_DOUBLE) <> 0) then
            renderfx := renderfx and (not RF_SHELL_HALF_DAM);
        end;
      end;

      if (renderfx and RF_SHELL_DOUBLE <> 0) then
      begin
        if (Developer_searchpath(2) = 2) then
        begin
          // lose the yellow shell if we have a red, blue, or green shell
          if (renderfx and (RF_SHELL_RED or RF_SHELL_BLUE or RF_SHELL_DOUBLE) <> 0) then
            renderfx := renderfx and (not RF_SHELL_DOUBLE);
          // if we have a red shell, turn it to purple by adding blue
          if (renderfx and RF_SHELL_RED <> 0) then
            renderfx := renderfx or RF_SHELL_BLUE
              // if we have a blue shell (and not a red shell), turn it to cyan by adding green
          else if (renderfx and RF_SHELL_BLUE <> 0) then
            // go to green if it's on already, otherwise do cyan (flash green)
            if (renderfx and RF_SHELL_GREEN <> 0) then
              renderfx := renderfx and (not RF_SHELL_BLUE)
            else
              renderfx := renderfx or RF_SHELL_GREEN;
        end;
      end;
      //         }
         // pmm
      ent.flags := renderfx or RF_TRANSLUCENT;
      ent.alpha := 0.30;
      V_AddEntity(@ent);
    end;

    ent.skin := nil;                    // never use a custom skin on others
    ent.skinnum := 0;
    ent.flags := 0;
    ent.alpha := 0;

    // duplicate for linked models
    if (s1.modelindex2 <> 0) then
    begin
      if (s1.modelindex2 = 255) then
      begin
        // custom weapon
        ci := @cl.clientinfo[s1.skinnum and $FF];
        i := (s1.skinnum shr 8);        // 0 is default weapon model
        if (cl_vwep.value = 0) or (i > MAX_CLIENTWEAPONMODELS - 1) then
          i := 0;
        ent.model := ci.weaponmodel[i];
        if (ent.model = nil) then
        begin
          if (i <> 0) then
            ent.model := ci.weaponmodel[0];
          if (ent.model = nil) then
            ent.model := cl.baseclientinfo.weaponmodel[0];
        end;
      end
      else
        ent.model := cl.model_draw[s1.modelindex2];

      // PMM - check for the defender sphere shell .. make it translucent
      // replaces the previous version which used the high bit on modelindex2 to determine transparency
      if (Q_strcasecmp(cl.configstrings[CS_MODELS + (s1.modelindex2)], 'models/items/shell/tris.md2') = 0) then
      begin
        ent.alpha := 0.32;
        ent.flags := RF_TRANSLUCENT;
      end;
      // pmm

      V_AddEntity(@ent);

      //PGM - make sure these get reset.
      ent.flags := 0;
      ent.alpha := 0;
      //PGM
    end;
    if (s1.modelindex3 <> 0) then
    begin
      ent.model := cl.model_draw[s1.modelindex3];
      V_AddEntity(@ent);
    end;
    if (s1.modelindex4 <> 0) then
    begin
      ent.model := cl.model_draw[s1.modelindex4];
      V_AddEntity(@ent);
    end;

    if (effects and EF_POWERSCREEN <> 0) then
    begin
      ent.model := cl_mod_powerscreen;
      ent.oldframe := 0;
      ent.frame := 0;
      ent.flags := ent.flags or (RF_TRANSLUCENT or RF_SHELL_GREEN);
      ent.alpha := 0.30;
      V_AddEntity(@ent);
    end;

    // add automatic particle trails
    if (effects and (not EF_ROTATE) <> 0) then
    begin
      if (effects and EF_ROCKET <> 0) then
      begin
        CL_RocketTrail(cent.lerp_origin, vec3_t(ent.origin), cent);
        V_AddLight(vec3_t(ent.origin), 200, 1, 1, 0);
      end
        // PGM - Do not reorder EF_BLASTER and EF_HYPERBLASTER.
        // EF_BLASTER | EF_TRACKER is a special case for EF_BLASTER2... Cheese!
      else if (effects and EF_BLASTER <> 0) then
      begin
        //            CL_BlasterTrail (cent.lerp_origin, ent.origin);
        //PGM
        if (effects and EF_TRACKER <> 0) then
        begin                           // lame... problematic?
          CL_BlasterTrail2(cent.lerp_origin, vec3_t(ent.origin));
          V_AddLight(vec3_t(ent.origin), 200, 0, 1, 0);
        end
        else
        begin
          CL_BlasterTrail(cent.lerp_origin, vec3_t(ent.origin));
          V_AddLight(vec3_t(ent.origin), 200, 1, 1, 0);
        end;
        //PGM
      end
      else if (effects and EF_HYPERBLASTER <> 0) then
      begin
        if (effects and EF_TRACKER <> 0) then // PGM   overloaded for blaster2.
          V_AddLight(vec3_t(ent.origin), 200, 0, 1, 0) // PGM
        else                            // PGM
          V_AddLight(vec3_t(ent.origin), 200, 1, 1, 0);
      end
      else if (effects and EF_GIB <> 0) then
      begin
        CL_DiminishingTrail(cent.lerp_origin, vec3_t(ent.origin), cent, effects);
      end
      else if (effects and EF_GRENADE <> 0) then
      begin
        CL_DiminishingTrail(cent.lerp_origin, vec3_t(ent.origin), cent, effects);
      end
      else if (effects and EF_FLIES <> 0) then
      begin
        CL_FlyEffect(cent, vec3_t(ent.origin));
      end
      else if (effects and EF_BFG <> 0) then
      begin

        if (effects and EF_ANIM_ALLFAST <> 0) then
        begin
          CL_BfgParticles(@ent);
          i := 200;
        end
        else
        begin
          i := bfg_lightramp[s1.frame];
        end;
        V_AddLight(vec3_t(ent.origin), i, 0, 1, 0);
      end
        // RAFAEL
      else if (effects and EF_TRAP <> 0) then
      begin
        ent.origin[2] := ent.origin[2] + 32;
        CL_TrapParticles(@ent);
        i := (rand() mod 100) + 100;
        V_AddLight(vec3_t(ent.origin), i, 1, 0.8, 0.1);
      end
      else if (effects and EF_FLAG1 <> 0) then
      begin
        CL_FlagTrail(cent.lerp_origin, vec3_t(ent.origin), 242);
        V_AddLight(vec3_t(ent.origin), 225, 1, 0.1, 0.1);
      end
      else if (effects and EF_FLAG2 <> 0) then
      begin
        CL_FlagTrail(cent.lerp_origin, vec3_t(ent.origin), 115);
        V_AddLight(vec3_t(ent.origin), 225, 0.1, 0.1, 1);
      end
        //======
        //ROGUE
      else if (effects and EF_TAGTRAIL <> 0) then
      begin
        CL_TagTrail(cent.lerp_origin, vec3_t(ent.origin), 220);
        V_AddLight(vec3_t(ent.origin), 225, 1.0, 1.0, 0.0);
      end
      else if (effects and EF_TRACKERTRAIL <> 0) then
      begin
        if (effects and EF_TRACKER <> 0) then
        begin
          intensity := 50 + (500 * (sin(cl.time / 500.0) + 1.0));
          // FIXME - check out this effect in rendition
          if (vidref_val = VIDREF_GL) then
            V_AddLight(vec3_t(ent.origin), intensity, -1.0, -1.0, -1.0)
          else
            V_AddLight(vec3_t(ent.origin), -1.0 * intensity, 1.0, 1.0, 1.0);
        end
        else
        begin
          CL_Tracker_Shell(cent.lerp_origin);
          V_AddLight(vec3_t(ent.origin), 155, -1.0, -1.0, -1.0);
        end;
      end
      else if (effects and EF_TRACKER <> 0) then
      begin
        CL_TrackerTrail(cent.lerp_origin, vec3_t(ent.origin), 0);
        // FIXME - check out this effect in rendition
        if (vidref_val = VIDREF_GL) then
          V_AddLight(vec3_t(ent.origin), 200, -1, -1, -1)
        else
          V_AddLight(vec3_t(ent.origin), -200, 1, 1, 1);
      end
        //ROGUE
        //======
           // RAFAEL
      else if (effects and EF_GREENGIB <> 0) then
      begin
        CL_DiminishingTrail(cent.lerp_origin, vec3_t(ent.origin), cent, effects);
      end
        // RAFAEL
      else if (effects and EF_IONRIPPER <> 0) then
      begin
        CL_IonripperTrail(cent.lerp_origin, vec3_t(ent.origin));
        V_AddLight(vec3_t(ent.origin), 100, 1, 0.5, 0.5);
      end
        // RAFAEL
      else if (effects and EF_BLUEHYPERBLASTER <> 0) then
      begin
        V_AddLight(vec3_t(ent.origin), 200, 0, 0, 1);
      end
        // RAFAEL
      else if (effects and EF_PLASMA <> 0) then
      begin
        if (effects and EF_ANIM_ALLFAST <> 0) then
        begin
          CL_BlasterTrail(cent.lerp_origin, vec3_t(ent.origin));
        end;
        V_AddLight(vec3_t(ent.origin), 130, 1, 0.5, 0.5);
      end;
    end;

    VectorCopy(vec3_t(ent.origin), cent.lerp_origin);
  end;
end;

{*
==============
CL_AddViewWeapon
==============
*}
procedure CL_AddViewWeapon(ps: player_state_p; ops: player_state_p);
var
  gun: entity_t;                        // view model
  i: integer;
begin
  // allow the gun to be completely removed
  if (cl_gun.value = 0) then
    exit;

  // don't draw gun if in wide angle view
  if (ps.fov > 90) then
    exit;

  FillChar(gun, sizeof(gun), #0);

  if (gun_model <> nil) then
    gun.model := gun_model              // development tool
  else
    gun.model := cl.model_draw[ps.gunindex];
  if (gun.model = nil) then
    exit;

  // set up gun position
  for i := 0 to 2 do
  begin
    gun.origin[i] := cl.refdef.vieworg[i] + ops.gunoffset[i]
      + cl.lerpfrac * (ps.gunoffset[i] - ops.gunoffset[i]);
    gun.angles[i] := cl.refdef.viewangles[i] + LerpAngle(ops.gunangles[i],
      ps.gunangles[i], cl.lerpfrac);
  end;

  if (gun_frame <> 0) then
  begin
    gun.frame := gun_frame;             // development tool
    gun.oldframe := gun_frame;          // development tool
  end
  else
  begin
    gun.frame := ps.gunframe;
    if (gun.frame = 0) then
      gun.oldframe := 0                 // just changed weapons, don't lerp from old
    else
      gun.oldframe := ops.gunframe;
  end;

  gun.flags := RF_MINLIGHT or RF_DEPTHHACK or RF_WEAPONMODEL;
  gun.backlerp := 1.0 - cl.lerpfrac;
  VectorCopy(vec3_t(gun.origin), vec3_t(gun.oldorigin)); // don't lerp at all
  V_AddEntity(@gun);
end;

{*
===============
CL_CalcViewValues

Sets cl.refdef view values
===============
*}
procedure CL_CalcViewValues;
var
  i: integer;
  lerp, backlerp: single;
  ent: centity_p;
  oldframe: frame_p;
  ps, ops: player_state_p;
  delta: word;
begin
  // find the previous frame to interpolate from
  ps := @cl.frame.playerstate;
  i := (cl.frame.serverframe - 1) and UPDATE_MASK;
  oldframe := @cl.frames[i];
  if (oldframe.serverframe <> cl.frame.serverframe - 1) and (not oldframe.valid) then
    oldframe := @cl.frame;              // previous frame was dropped or involid
  ops := @oldframe.playerstate;

  // see if the player entity was teleported this frame
  if (fabs(ops.pmove.origin[0] - ps.pmove.origin[0]) > 256 * 8)
    or (abs(ops.pmove.origin[1] - ps.pmove.origin[1]) > 256 * 8)
    or (abs(ops.pmove.origin[2] - ps.pmove.origin[2]) > 256 * 8) then
    ops := ps;                          // don't interpolate

  ent := @cl_entities[cl.playernum + 1];
  lerp := cl.lerpfrac;

  // calculate the origin
  if ((cl_predict.value <> 0) and (cl.frame.playerstate.pmove.pm_flags and PMF_NO_PREDICTION = 0)) then
  begin
    // use predicted values

    backlerp := 1.0 - lerp;
    for i := 0 to 2 do
    begin
      cl.refdef.vieworg[i] := cl.predicted_origin[i] + ops.viewoffset[i]
        + cl.lerpfrac * (ps.viewoffset[i] - ops.viewoffset[i])
        - backlerp * cl.prediction_error[i];
    end;

    // smooth out stair climbing
    delta := cls.realtime - cl.predicted_step_time;
    if (delta < 100) then
      cl.refdef.vieworg[2] := cl.refdef.vieworg[2] - cl.predicted_step * (100 - delta) * 0.01;
  end
  else
  begin                                 // just use interpolated values
    for i := 0 to 2 do
      cl.refdef.vieworg[i] := ops.pmove.origin[i] * 0.125 + ops.viewoffset[i]
        + lerp * (ps.pmove.origin[i] * 0.125 + ps.viewoffset[i]
        - (ops.pmove.origin[i] * 0.125 + ops.viewoffset[i]));
  end;

  // if not running a demo or on a locked frame, add the local angle movement
  if (cl.frame.playerstate.pmove.pm_type < PM_DEAD) then
  begin
    // use predicted values
    for i := 0 to 2 do
      cl.refdef.viewangles[i] := cl.predicted_angles[i];
  end
  else
  begin                                 // just use interpolated values
    for i := 0 to 2 do
      cl.refdef.viewangles[i] := LerpAngle(ops.viewangles[i], ps.viewangles[i], lerp);
  end;

  for i := 0 to 2 do
    cl.refdef.viewangles[i] := cl.refdef.viewangles[i] + LerpAngle(ops.kick_angles[i], ps.kick_angles[i], lerp);

  AngleVectors(vec3_t(cl.refdef.viewangles), @cl.v_forward, @cl.v_right, @cl.v_up);

  // interpolate field of view
  cl.refdef.fov_x := ops.fov + lerp * (ps.fov - ops.fov);

  // don't interpolate blend color
  for i := 0 to 3 do
    cl.refdef.blend[i] := ps.blend[i];

  // add the weapon
  CL_AddViewWeapon(ps, ops);
end;

{*
===============
CL_AddEntities

Emits all entities, particles, and lights to the refresh
===============
*}
procedure CL_AddEntities;
begin
  if (cls.state <> ca_active) then
    exit;

  if (cl.time > cl.frame.servertime) then
  begin
    if (cl_showclamp.value <> 0) then
      Com_Printf('high clamp %d'#10, [cl.time - cl.frame.servertime]);
    cl.time := cl.frame.servertime;
    cl.lerpfrac := 1.0;
  end
  else if (cl.time < cl.frame.servertime - 100) then
  begin
    if (cl_showclamp.value <> 0) then
      Com_Printf('low clamp %d'#10, [cl.frame.servertime - 100 - cl.time]);
    cl.time := cl.frame.servertime - 100;
    cl.lerpfrac := 0;
  end
  else
    cl.lerpfrac := 1.0 - (cl.frame.servertime - cl.time) * 0.01;

  if (cl_timedemo.value <> 0) then
    cl.lerpfrac := 1.0;

  //   CL_AddPacketEntities (&cl.frame);
  //   CL_AddTEnts ();
  //   CL_AddParticles ();
  //   CL_AddDLights ();
  //   CL_AddLightStyles ();

  CL_CalcViewValues();
  // PMM - moved this here so the heat beam has the right values for the vieworg, and can lock the beam to the gun
  CL_AddPacketEntities(@cl.frame);
  {
   CL_AddProjectiles ();
  }
  CL_AddTEnts();
  CL_AddParticles();
  CL_AddDLights();
  CL_AddLightStyles();
end;

{*
===============
CL_GetEntitySoundOrigin

Called to get the sound spatialization origin
===============
*}
procedure CL_GetEntitySoundOrigin(ent: integer; var org: vec3_t);
var
  old: centity_p;
begin
  if (ent < 0) or (ent >= MAX_EDICTS) then
    Com_Error(ERR_DROP, 'CL_GetEntitySoundOrigin: bad ent', []);
  old := @cl_entities[ent];
  VectorCopy(old.lerp_origin, org);

  // FIXME: bmodel issues...
end;

end.
