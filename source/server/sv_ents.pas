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
// 25.07.2002 Juha: Proof-readed this unit
unit sv_ents;

interface

uses
  Common,
  Server;

procedure SV_BuildClientFrame(client: client_p);
procedure SV_WriteFrameToClient(client: client_p; msg: sizebuf_p);
procedure SV_RecordDemoMessage;

implementation

uses
  SysUtils,
  CModel,
  sv_init,
  sv_game,
  sv_main,
  GameUnit,
  q_shared;

(*=============================================================================

Encode a client frame onto the network channel

=============================================================================*)

(*

// because there can be a lot of projectiles, there is a special
// network protocol for them
const
  MAX_PROJECTILES = 64;

var
  projectiles: array[0..MAX_PROJECTILES-1] of edict_p;
  numprojs: Integer;
  sv_projectiles: cvar_p;

function SV_AddProjectileUpdate(ent: edict_p): qboolean;
begin
  if (sv_projectiles <> 0) then
    sv_projectiles := Cvar_Get('sv_projectiles', '1', 0);

  if (sv_projectiles^.value <> 0) then
  begin
    Result := false;
    Exit;
  end;

  if ((ent.svflags AND SVF_PROJECTILE) <> 0) then
  begin
    Result := false;
    Exit;
  end;

  if (numprojs = MAX_PROJECTILES) then
  begin
    Result := true;
    Exit;
  end;

  projectiles[numprojs] := @ent;
  Inc(numprojs);

  Result := true;
end;

procedure SV_EmitProjectileUpdate(var msg: sizebuf_t);
var
  bits: array[0..16-1] of byte;   // [modelindex] [48 bits] xyz p y 12 12 12 8 8 [entitynum] [e2]
  n, i: Integer;
  ent: edict_p;
  x, y, z, p, yaw: Integer;
  len: int;
begin
  if (numprojs = 0) then
    Exit;

  MSG_WriteByte(msg, numprojs);

  for n := 0 to (numprojs - 1) do
  begin
    ent := projectiles[n];
    x := ((ent^.s.origin[0] + 4096) shr 1);
    y := ((ent^.s.origin[1] + 4096) shr 1);
    z := ((ent^.s.origin[2] + 4096) shr 1);
    p := ((256 * ent^.s.angles[0] / 360) AND 255);
    yaw := ((256 * ent^.s.angles[1] / 360) AND 255);

    len := 0;
    bits[len] := x;
    Inc(len);
    bits[len] := (x shr 8) OR (y shl 4);
    Inc(len);
    bits[len] := (y shr 4);
    Inc(len);
    bits[len] := z;
    Inc(len);
    bits[len] := (z shr 8);
    Inc(len);
    if ((ent^.s.effects AND EF_BLASTER) <> 0) then
      bits[len-1] := bits[len-1] OR 64;

    if ((ent^.s.old_origin[0] <> ent^.s.origin[0]) OR
    (ent^.s.old_origin[1] <> ent^.s.origin[1]) OR
    (ent^.s.old_origin[2] <> ent^.s.origin[2])) then
    begin
      bits[len-1] := bits[len-1] OR 128;
      x := ((ent^.s.old_origin[0] + 4096) shr 1);
      y := ((ent^.s.old_origin[1] + 4096) shr 1);
      z := ((ent^.s.old_origin[2] + 4096) shr 1);
      bits[len] := x;
      Inc(len);
      bits[len] := (x shr 8) OR (y shl 4);
      Inc(len);
      bits[len] := (y shr 4);
      Inc(len);
      bits[len] := z;
      Inc(len);
      bits[len] := (z shr 8);
      Inc(len);
    end;

    bits[len] := p;
    Inc(len);
    bits[len] := yaw;
    Inc(len);
    bits[len] := ent^.s.modelindex;
    Inc(len);

    bits[len] := (ent^.s.number AND $7f);
    Inc(len);
    if (ent^.s.number > 255) then
    begin
      bits[len-1] := bits[len-1] OR 128;
      bits[len] := (ent^.s.number shr 7);
      Inc(len);
    end

    for i := 0 to (len - 1) do
      MSG_WriteByte(msg, bits[i]);
  end;
end;
*)

{
=============
SV_EmitPacketEntities

Writes a delta update of an entity_state_t list to the message.
=============
}

procedure SV_EmitPacketEntities(from: client_frame_p; to_: client_frame_p;
  var msg: sizebuf_t);
var
  oldent, newent: entity_state_p;
  oldindex, newindex: Integer;
  oldnum, newnum: Integer;
  from_num_entities: Integer;
  bits: Cardinal;
begin
  {
    if (numprojs <> 0) then
      MSG_WriteByte(msg, svc_packetentities2)
    else
  }
  MSG_WriteByte(msg, Integer(svc_packetentities));

  if (from = nil) then
    from_num_entities := 0
  else
    from_num_entities := from^.num_entities;

  newindex := 0;
  oldindex := 0;
  while (newindex < to_^.num_entities) or (oldindex < from_num_entities) do
  begin
    if (newindex >= to_^.num_entities) then
      newnum := 9999
    else
    begin
      newent := @svs.client_entities^[(to_^.first_entity + newindex) mod svs.num_client_entities];
      newnum := newent^.number;
    end;

    if (oldindex >= from_num_entities) then
      oldnum := 9999
    else
    begin
      oldent := @svs.client_entities^[(from^.first_entity + oldindex) mod svs.num_client_entities];
      oldnum := oldent^.number;
    end;

    if (newnum = oldnum) then
    begin
      // delta update from old position
      // because the force parm is false, this will not result
      // in any bytes being emited if the entity has not changed at all
      // note that players are always 'newentities', this updates their oldorigin always
      // and prevents warping
      MSG_WriteDeltaEntity(oldent^, newent^, msg, false, (newent^.number <= Trunc(maxclients^.value)));
      Inc(oldindex);
      Inc(newindex);
      continue;
    end;

    if (newnum < oldnum) then
    begin
      // this is a new entity, send it from the baseline
      MSG_WriteDeltaEntity(sv.baselines[newnum], newent^, msg, true, true);
      Inc(newindex);
      continue;
    end;

    if (newnum > oldnum) then
    begin
      // the old entity isn't present in the new message
      bits := U_REMOVE;
      if (oldnum >= 256) then
        bits := bits or U_NUMBER16 or U_MOREBITS1;

      MSG_WriteByte(msg, bits and 255);

      if ((bits and $0000FF00) <> 0) then
        MSG_WriteByte(msg, (bits shr 8) and 255);

      if ((bits and U_NUMBER16) <> 0) then
        MSG_WriteShort(msg, oldnum)
      else
        MSG_WriteByte(msg, oldnum);

      Inc(oldindex);
      continue;
    end;
  end;

  MSG_WriteShort(msg, 0);               // end of packetentities

  {
    if (numprojs) then
      SV_EmitProjectileUpdate(msg);
  }
end;

(*
=============
SV_WritePlayerstateToClient
=============
*)

procedure SV_WritePlayerstateToClient(from: client_frame_p; to_: client_frame_p;
  msg: sizebuf_p);
var
  i: integer;
  pflags: integer;
  ps, ops: player_state_p;
  dummy: player_state_t;
  statbits: integer;
begin
  ps := @to_^.ps;
  if (from = nil) then
  begin
    FillChar(dummy, sizeof(dummy), 0);
    ops := @dummy;
  end
  else
    ops := @from^.ps;

  //
  // determine what needs to be sent
  //
  pflags := 0;

  if (ps^.pmove.pm_type <> ops^.pmove.pm_type) then
    pflags := pflags or PS_M_TYPE;

  if (ps^.pmove.origin[0] <> ops^.pmove.origin[0]) or
    (ps^.pmove.origin[1] <> ops^.pmove.origin[1]) or
    (ps^.pmove.origin[2] <> ops^.pmove.origin[2]) then
    pflags := pflags or PS_M_ORIGIN;

  if (ps^.pmove.velocity[0] <> ops^.pmove.velocity[0]) or
    (ps^.pmove.velocity[1] <> ops^.pmove.velocity[1]) or
    (ps^.pmove.velocity[2] <> ops^.pmove.velocity[2]) then
    pflags := pflags or PS_M_VELOCITY;

  if (ps^.pmove.pm_time <> ops^.pmove.pm_time) then
    pflags := pflags or PS_M_TIME;

  if (ps^.pmove.pm_flags <> ops^.pmove.pm_flags) then
    pflags := pflags or PS_M_FLAGS;

  if (ps^.pmove.gravity <> ops^.pmove.gravity) then
    pflags := pflags or PS_M_GRAVITY;

  if (ps^.pmove.delta_angles[0] <> ops^.pmove.delta_angles[0]) or
    (ps^.pmove.delta_angles[1] <> ops^.pmove.delta_angles[1]) or
    (ps^.pmove.delta_angles[2] <> ops^.pmove.delta_angles[2]) then
    pflags := pflags or PS_M_DELTA_ANGLES;

  if (ps^.viewoffset[0] <> ops^.viewoffset[0]) or
    (ps^.viewoffset[1] <> ops^.viewoffset[1]) or
    (ps^.viewoffset[2] <> ops^.viewoffset[2]) then
    pflags := pflags or PS_VIEWOFFSET;

  if (ps^.viewangles[0] <> ops^.viewangles[0]) or
    (ps^.viewangles[1] <> ops^.viewangles[1]) or
    (ps^.viewangles[2] <> ops^.viewangles[2]) then
    pflags := pflags or PS_VIEWANGLES;

  if (ps^.kick_angles[0] <> ops^.kick_angles[0]) or
    (ps^.kick_angles[1] <> ops^.kick_angles[1]) or
    (ps^.kick_angles[2] <> ops^.kick_angles[2]) then
    pflags := pflags or PS_KICKANGLES;

  if (ps^.blend[0] <> ops^.blend[0]) or
    (ps^.blend[1] <> ops^.blend[1]) or
    (ps^.blend[2] <> ops^.blend[2]) or
    (ps^.blend[3] <> ops^.blend[3]) then
    pflags := pflags or PS_BLEND;

  if (ps^.fov <> ops^.fov) then
    pflags := pflags or PS_FOV;

  if (ps^.rdflags <> ops^.rdflags) then
    pflags := pflags or PS_RDFLAGS;

  if (ps^.gunframe <> ops^.gunframe) then
    pflags := pflags or PS_WEAPONFRAME;

  pflags := pflags or PS_WEAPONINDEX;

  //
  // write it
  //
  MSG_WriteByte(msg^, Integer(svc_playerinfo));
  MSG_WriteShort(msg^, pflags);

  //
  // write the pmove_state_t
  //
  if (pflags and PS_M_TYPE) <> 0 then
    MSG_WriteByte(msg^, Integer(ps^.pmove.pm_type));

  if (pflags and PS_M_ORIGIN) <> 0 then
  begin
    MSG_WriteShort(msg^, ps^.pmove.origin[0]);
    MSG_WriteShort(msg^, ps^.pmove.origin[1]);
    MSG_WriteShort(msg^, ps^.pmove.origin[2]);
  end;

  if (pflags and PS_M_VELOCITY) <> 0 then
  begin
    MSG_WriteShort(msg^, ps^.pmove.velocity[0]);
    MSG_WriteShort(msg^, ps^.pmove.velocity[1]);
    MSG_WriteShort(msg^, ps^.pmove.velocity[2]);
  end;

  if (pflags and PS_M_TIME) <> 0 then
    MSG_WriteByte(msg^, ps^.pmove.pm_time);

  if (pflags and PS_M_FLAGS) <> 0 then
    MSG_WriteByte(msg^, ps^.pmove.pm_flags);

  if (pflags and PS_M_GRAVITY) <> 0 then
    MSG_WriteShort(msg^, ps^.pmove.gravity);

  if (pflags and PS_M_DELTA_ANGLES) <> 0 then
  begin
    MSG_WriteShort(msg^, ps^.pmove.delta_angles[0]);
    MSG_WriteShort(msg^, ps^.pmove.delta_angles[1]);
    MSG_WriteShort(msg^, ps^.pmove.delta_angles[2]);
  end;

  //
  // write the rest of the player_state_t
  //
  if (pflags and PS_VIEWOFFSET) <> 0 then
  begin
    MSG_WriteChar(msg^, Round(ps^.viewoffset[0] * 4));
    MSG_WriteChar(msg^, Round(ps^.viewoffset[1] * 4));
    MSG_WriteChar(msg^, Round(ps^.viewoffset[2] * 4));
  end;

  if (pflags and PS_VIEWANGLES) <> 0 then
  begin
    MSG_WriteAngle16(msg^, ps^.viewangles[0]);
    MSG_WriteAngle16(msg^, ps^.viewangles[1]);
    MSG_WriteAngle16(msg^, ps^.viewangles[2]);
  end;

  if (pflags and PS_KICKANGLES) <> 0 then
  begin
    MSG_WriteChar(msg^, Trunc(ps^.kick_angles[0] * 4));
    MSG_WriteChar(msg^, Trunc(ps^.kick_angles[1] * 4));
    MSG_WriteChar(msg^, Trunc(ps^.kick_angles[2] * 4));
  end;

  if (pflags and PS_WEAPONINDEX) <> 0 then
  begin
    MSG_WriteByte(msg^, ps^.gunindex);
  end;

  if (pflags and PS_WEAPONFRAME) <> 0 then
  begin
    MSG_WriteByte(msg^, ps^.gunframe);
    MSG_WriteChar(msg^, Trunc(ps^.gunoffset[0] * 4));
    MSG_WriteChar(msg^, Trunc(ps^.gunoffset[1] * 4));
    MSG_WriteChar(msg^, Trunc(ps^.gunoffset[2] * 4));
    MSG_WriteChar(msg^, Trunc(ps^.gunangles[0] * 4));
    MSG_WriteChar(msg^, Trunc(ps^.gunangles[1] * 4));
    MSG_WriteChar(msg^, Trunc(ps^.gunangles[2] * 4));
  end;

  if (pflags and PS_BLEND) <> 0 then
  begin
    MSG_WriteByte(msg^, Trunc(ps^.blend[0] * 255));
    MSG_WriteByte(msg^, Trunc(ps^.blend[1] * 255));
    MSG_WriteByte(msg^, Trunc(ps^.blend[2] * 255));
    MSG_WriteByte(msg^, Trunc(ps^.blend[3] * 255));
  end;
  if (pflags and PS_FOV) <> 0 then
    MSG_WriteByte(msg^, Trunc(ps^.fov));

  if (pflags and PS_RDFLAGS) <> 0 then
    MSG_WriteByte(msg^, ps^.rdflags);

  // send stats
  statbits := 0;
  for i := 0 to (MAX_STATS - 1) do
    if (ps^.stats[i] <> ops^.stats[i]) then
      statbits := statbits or (1 shl i);

  MSG_WriteLong(msg^, statbits);

  for i := 0 to (MAX_STATS - 1) do
    if (statbits and (1 shl i) <> 0) then
      MSG_WriteShort(msg^, ps^.stats[i]);
end;

(*
==================
SV_WriteFrameToClient
==================
*)

procedure SV_WriteFrameToClient(client: client_p; msg: sizebuf_p);
var
  frame, oldframe: client_frame_p;
  lastframe: Integer;
begin
  { Following line commented in Original Source }
  //Com_Printf ("%i -> %i\n", client->lastframe, sv.framenum);
    // this is the frame we are creating
  frame := @client^.frames[sv.framenum and UPDATE_MASK];

  if (client^.lastframe <= 0) then
  begin
    // client is asking for a retransmit
    oldframe := nil;
    lastframe := -1;
  end
  else if (sv.framenum - client^.lastframe >= (UPDATE_BACKUP - 3)) then
  begin
    // client hasn't gotten a good message through in a long time
    { Following line commented in Original Source }
    // Com_Printf ("%s: Delta request from out-of-date packet.\n", client->name);
    oldframe := nil;
    lastframe := -1;
  end
  else
  begin
    // we have a valid message to delta from
    oldframe := @client^.frames[client^.lastframe and UPDATE_MASK];
    lastframe := client^.lastframe;
  end;

  MSG_WriteByte(msg^, Integer(svc_frame));
  MSG_WriteLong(msg^, sv.framenum);
  MSG_WriteLong(msg^, lastframe);       // what we are delta'ing from
  MSG_WriteByte(msg^, client^.surpressCount); // rate dropped packets
  client^.surpressCount := 0;

  // send over the areabits
  MSG_WriteByte(msg^, frame^.areabytes);
  SZ_Write(msg^, @frame^.areabits, frame^.areabytes);

  // delta encode the playerstate
  SV_WritePlayerstateToClient(oldframe, frame, msg);

  // delta encode the entities
  SV_EmitPacketEntities(oldframe, frame, msg^);
end;

(* =============================================================================

Build a client frame structure

============================================================================= *)

var
  fatpvs: array[0..(65536 div 8) - 1] of byte; // 32767 is MAX_MAP_LEAFS

  (*
  ============
  SV_FatPVS

  The client will interpolate the view position,
  so we can't use a single PVS point
  ===========
  *)

procedure SV_FatPVS(const org: vec3_t);
var
  leafs: array[0..64 - 1] of Integer;
  i, j, count: Integer;
  longs: Integer;
  src: PIntegerArray;
  mins, maxs: vec3_t;
begin
  for i := 0 to 2 do
  begin
    mins[i] := org[i] - 8;
    maxs[i] := org[i] + 8;
  end;

  count := CM_BoxLeafnums(mins, maxs, @leafs, 64, nil);
  if (count < 1) then
    Com_Error(ERR_FATAL, 'SV_FatPVS: count < 1', []);

  longs := (CM_NumClusters + 31) shr 5;

  // convert leafs to clusters
  for i := 0 to (count - 1) do
    leafs[i] := CM_LeafCluster(leafs[i]);

  move(CM_ClusterPVS(leafs[0])^, fatpvs, longs shl 2);
  // or in all the other leaf bits
  for i := 1 to (count - 1) do
  begin
    for j := 0 to (i - 1) do
      if (leafs[i] = leafs[j]) then
        Break;

    if (j <> i) then
      Continue;                         // already have the cluster we want

    src := PIntegerArray(CM_ClusterPVS(leafs[i]));
    for j := 0 to (longs - 1) do
      PIntegerArray(@fatpvs)^[j] := PIntegerArray(@fatpvs)^[j] or src[j];
  end;
end;

(*
=============
SV_BuildClientFrame

Decides which entities are going to be visible to the client, and
copies off the playerstat and areabits.
=============
*)

procedure SV_BuildClientFrame(client: client_p);
var
  e, i: Integer;
  org: vec3_t;
  ent: edict_p;
  clent: edict_p;
  frame: client_frame_p;
  state: entity_state_p;
  l: Integer;
  clientarea, clientcluster: Integer;
  leafnum: Integer;
  c_fullsend: Integer;
  clientphs: PByteArray;
  bitvector: PByteArray;
  delta: vec3_t;
  len: single;
begin
  clent := client.edict;
  if (clent.client = nil) then
    Exit;                               // not in game yet

  {
    numprojs := 0; // no projectiles yet
  }

    // this is the frame we are creating
  frame := @client.frames[sv.framenum and UPDATE_MASK];

  frame.senttime := svs.realtime;       // save it for ping calc later

  // find the client's PVS
  for i := 0 to 2 do
    org[i] := (clent.client^.ps.pmove.origin[i] * 0.125) + clent.client^.ps.viewoffset[i];

  leafnum := CM_PointLeafnum(org);
  clientarea := CM_LeafArea(leafnum);
  clientcluster := CM_LeafCluster(leafnum);

  // calculate the visible areas
  frame.areabytes := CM_WriteAreaBits(@frame.areabits, clientarea);

  // grab the current player_state_t
  frame.ps := clent.client^.ps;

  SV_FatPVS(org);
  clientphs := PByteArray(CM_ClusterPHS(clientcluster));

  // build up the list of visible entities
  frame.num_entities := 0;
  frame.first_entity := svs.next_client_entities;

  c_fullsend := 0;

  for e := 1 to (ge.num_edicts - 1) do
  begin
    ent := EDICT_NUM(e);

    // ignore ents without visible models
    if (ent.svflags and SVF_NOCLIENT) <> 0 then
      Continue;

    // ignore ents without visible models unless they have an effect
    if ((ent.s.modelindex = 0) and (ent.s.effects = 0) and (ent.s.sound = 0) and
      (Integer(ent.s.event) = 0)) then
      Continue;

    // ignore if not touching a PV leaf
    if (ent <> clent) then
    begin
      // check area
      if (not CM_AreasConnected(clientarea, ent^.areanum)) then
      begin
        // doors can legally straddle two areas, so
         // we may need to check another one
        if (ent^.areanum2 = 0) or (not CM_AreasConnected(clientarea, ent^.areanum2)) then
          Continue;                     // blocked by a door
      end;

      // beams just check one point for PHS
      if (ent^.s.renderfx and RF_BEAM) <> 0 then
      begin
        l := ent^.clusternums[0];
        if ((clientphs[l shr 3] and (1 shl (l and 7))) = 0) then
          Continue;
      end
      else
      begin
        // FIXME: if an ent has a model and a sound, but isn't
        // in the PVS, only the PHS, clear the model
        if (ent^.s.sound <> 0) then
        begin
          bitvector := @fatpvs;         //clientphs;
        end
        else
          bitvector := @fatpvs;

        if (ent^.num_clusters = -1) then
        begin
          // too many leafs for individual check, go by headnode
          if (not CM_HeadnodeVisible(ent^.headnode, bitvector)) then
            Continue;
          Inc(c_fullsend);
        end
        else
        begin
          // check individual leafs
          i := 0;
          while (i < ent^.num_clusters) do
          begin
            l := ent^.clusternums[i];
            if (bitvector[l shr 3] and (1 shl (l and 7))) <> 0 then
              Break;
            inc(i);
          end;

          if (i = ent^.num_clusters) then
            Continue;                   // not visible
        end;

        if (ent^.s.modelindex = 0) then
        begin
          // don't send sounds if they will be attenuated away
          VectorSubtract(org, ent^.s.origin, delta);
          len := VectorLength(delta);
          if (len > 400) then
            Continue;
        end;
      end;
    end;

    {
        if (SV_AddProjectileUpdate(ent) <> 0) then
          Continue; // added as a special projectile
    }

        // add it to the circular client_entities array
    state := @svs.client_entities^[svs.next_client_entities mod svs.num_client_entities];
    if (ent^.s.number <> e) then
    begin
      Com_DPrintf('FIXING ENT->S.NUMBER!!!'#10, []);
      ent^.s.number := e;
    end;

    state^ := ent^.s;

    // don't mark players missiles as solid
    if (ent^.owner = client^.edict) then
      state^.solid := 0;

    Inc(svs.next_client_entities);
    Inc(frame^.num_entities);
  end;
end;

(*
==================
SV_RecordDemoMessage

Save everything in the world out without deltas.
Used for recording footage for merged or assembled demos
==================
*)

procedure SV_RecordDemoMessage;
var
  e: Integer;
  ent: edict_p;
  nostate: entity_state_t;
  buf: sizebuf_t;
  buf_data: array[0..32768 - 1] of byte;
  len: Integer;
begin
  if (svs.demofile <= 0) then
    Exit;

  FillChar(nostate, SizeOf(nostate), 0);
  SZ_Init(buf, @buf_data, SizeOf(buf_data));

  // write a frame message that doesn't contain a player_state_t
  MSG_WriteByte(buf, Integer(svc_frame));
  MSG_WriteLong(buf, sv.framenum);

  MSG_WriteByte(buf, Integer(svc_packetentities));

  e := 1;
  ent := EDICT_NUM(e);
  while (e < ge^.num_edicts) do
  begin
    // ignore ents without visible models unless they have an effect
    if (ent^.inuse) and (ent^.s.number <> 0) and ((ent^.s.modelindex <> 0) or (ent^.s.effects <> 0) or (ent^.s.sound <> 0) or (Integer(ent^.s.event) <> 0)) and
      ((ent^.svflags and SVF_NOCLIENT) = 0) then
      MSG_WriteDeltaEntity(nostate, ent^.s, buf, false, true);

    Inc(e);
    ent := EDICT_NUM(e);
  end;

  MSG_WriteShort(buf, 0);               // end of packetentities

  // now add the accumulated multicast information
  SZ_Write(buf, svs.demo_multicast.data, svs.demo_multicast.cursize);
  SZ_Clear(svs.demo_multicast);

  // now write the entire message to the file, prefixed by the length
  len := LittleLong(buf.cursize);
  FileWrite(svs.demofile, len, 4);
  FileWrite(svs.demofile, buf.data, buf.cursize);
end;

end.
