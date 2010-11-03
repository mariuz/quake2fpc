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
{ File(s): cl_pred.c                                                         }
{ Content:                                                                   }
{                                                                            }
{ Initial conversion by : Skybuck Flying  (skybuck2000@hotmail.com)          }
{ Initial conversion on : 5-march-2002                                       }
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
{ Changes:                                                                   }
{ 08-Jun-2002 Juha Hartikainen:                                              }
{ - Completed conversion.                                                    }
{                                                                            }
{----------------------------------------------------------------------------}
// cl_pred.c
unit cl_pred;

interface

uses
  Client,
  q_shared;

procedure CL_CheckPredictionError;
procedure CL_ClipMoveToEntities(const start, mins, maxs, end_: vec3_t; tr: trace_p);
procedure CL_PredictMovement;

implementation

uses
  SysUtils,
  CPas,
  Common,
  CModel,
  GameUnit,
  PMoveUnit,
  cl_main;

{
===================
CL_CheckPredictionError
===================
}
procedure CL_CheckPredictionError;
var
  frame: integer;
  delta: array[0..2] of integer;
  i: integer;
  len: integer;
begin

  if (cl_predict^.value = 0) or
    (cl.frame.playerstate.pmove.pm_flags and PMF_NO_PREDICTION <> 0) then
    exit;

  // calculate the last usercmd_t we sent that the server has processed
  frame := cls.netchan.incoming_acknowledged;

  frame := frame and (CMD_BACKUP - 1);

  // compare what the server returned with what we had predicted it to be
  VectorSubtract(cl.frame.playerstate.pmove.origin, cl.predicted_origins[frame], delta);

  // save the prediction error for interpolation
  len := abs(delta[0]) + abs(delta[1]) + abs(delta[2]);
  if (len > 640) then                   // 80 world units
  begin
    // a teleport or something
    VectorClear(cl.prediction_error);
  end
  else
  begin
    if (cl_showmiss^.value <> 0) and ((delta[0] <> 0) or (delta[1] <> 0) or (delta[2] <> 0)) then
    begin
      Com_Printf('prediction miss on %d: %d'#10, [cl.frame.serverframe,
        delta[0] + delta[1] + delta[2]]);
    end;

    VectorCopy(cl.frame.playerstate.pmove.origin, cl.predicted_origins[frame]);

    // save for error itnerpolation
    for i := 0 to 2 do
    begin
      cl.prediction_error[i] := delta[i] * 0.125;
    end;
  end;
end;

{
====================
CL_ClipMoveToEntities

====================
}
procedure CL_ClipMoveToEntities(const start, mins, maxs, end_: vec3_t; tr: trace_p);
var
  i, x, zd, zu: integer;
  trace: trace_t;
  headnode: integer;
  angles: psingle;
  ent: entity_state_p;
  num: integer;
  cmodel: cmodel_p;
  bmins, bmaxs: vec3_t;
begin
  for i := 0 to cl.frame.num_entities - 1 do
  begin
    num := (cl.frame.parse_entities + i) and (MAX_PARSE_ENTITIES - 1);
    ent := @cl_parse_entities[num];

    if (ent^.solid = 0) then
      continue;

    if (ent^.number = cl.playernum + 1) then
      continue;

    if (ent^.solid = 31) then
    begin
      // special value for bmodel
      cmodel := cl.model_clip[ent^.modelindex];
      if (cmodel = nil) then
        continue;
      headnode := cmodel^.headnode;
      angles := @ent^.angles;
    end
    else
    begin
      // encoded bbox
      x := 8 * (ent^.solid and 31);
      zd := 8 * ((ent^.solid shr 5) and 31);
      zu := 8 * ((ent^.solid shr 10) and 63) - 32;

      bmins[0] := -x;
      bmins[1] := -x;
      bmaxs[0] := x;
      bmaxs[1] := x;
      bmins[2] := -zd;
      bmaxs[2] := zu;

      headnode := CM_HeadnodeForBox(bmins, bmaxs);
      angles := @vec3_origin;           // boxes don't rotate
    end;

    if (tr^.allsolid) then
      exit;

    trace := CM_TransformedBoxTrace(start, end_,
      mins, maxs, headnode, MASK_PLAYERSOLID, ent^.origin, vec3_p(angles)^);

    if (trace.allsolid or trace.startsolid or (trace.fraction < tr^.fraction)) then
    begin
      trace.ent := edict_p(ent);
      if (tr^.startsolid) then
      begin
        tr^ := trace;
        tr^.startsolid := true;
      end
      else
      begin
        tr^ := trace;
      end;
    end
    else
    begin
      if (trace.startsolid) then
      begin
        tr^.startsolid := true;
      end;
    end;
  end;
end;

{
================
CL_PMTrace
================
}
function CL_PMTrace(const start, mins, maxs, _end: vec3_t): trace_t; cdecl;
var
  t: trace_t;
begin

  // check against world
  t := CM_BoxTrace(start, _end, mins, maxs, 0, MASK_PLAYERSOLID);
  if (t.fraction < 1.0) then
  begin
    t.ent := edict_p(1);
  end;

  // check all other solid models
  CL_ClipMoveToEntities(start, mins, maxs, _end, @t);

  result := t;
end;

function CL_PMpointcontents(const _point: vec3_t): integer; cdecl;
var
  i: integer;
  ent: entity_state_p;
  num: integer;
  cmodel: cmodel_p;
  contents: integer;
begin
  contents := CM_PointContents(_point, 0);

  for i := 0 to cl.frame.num_entities - 1 do
  begin

    num := (cl.frame.parse_entities + i) and (MAX_PARSE_ENTITIES - 1);
    ent := @cl_parse_entities[num];

    if (ent^.solid <> 31) then          // special value for bmodel
      continue;

    cmodel := cl.model_clip[ent^.modelindex];
    if (cmodel = nil) then
      continue;

    contents := contents or CM_TransformedPointContents(_point, cmodel^.headnode, ent^.origin, ent^.angles);
  end;

  result := contents;
end;

{
=================
CL_PredictMovement

Sets cl.predicted_origin and cl.predicted_angles
=================
}
procedure CL_PredictMovement;
var
  ack, current: integer;
  frame: integer;
  oldframe: integer;
  cmd: usercmd_p;
  pm: pmove_t;
  i: integer;
  step: integer;
  oldz: integer;
begin
  if (cls.state <> ca_active) then
    exit;

  if (cl_paused^.value <> 0) then
    exit;

  if (cl_predict.value = 0) or (cl.frame.playerstate.pmove.pm_flags and PMF_NO_PREDICTION <> 0) then
  begin
    // just set angles
    for i := 0 to 2 do
    begin
      cl.predicted_angles[i] := cl.viewangles[i] + SHORT2ANGLE(cl.frame.playerstate.pmove.delta_angles[i]);
    end;
    exit;
  end;

  ack := cls.netchan.incoming_acknowledged;
  current := cls.netchan.outgoing_sequence;

  // if we are too far out of date, just freeze
  if (current - ack >= CMD_BACKUP) then
  begin
    if (cl_showmiss.value <> 0) then
      Com_Printf('exceeded CMD_BACKUP'#10, []);
    exit;
  end;

  // copy current state to pmove
  FillChar(pm, sizeof(pm), #0);

  pm.trace := @CL_PMTrace;
  pm.pointcontents := CL_PMpointcontents;

  pm_airaccelerate := atof(cl.configstrings[CS_AIRACCEL]);

  pm.s := cl.frame.playerstate.pmove;

  //   SCR_DebugGraph (current - ack - 1, 0);

   // run frames
  Inc(ack);
  while (ack < current) do
  begin
    frame := ack and (CMD_BACKUP - 1);
    cmd := @cl.cmds[frame];

    pm.cmd := cmd^;
    Pmove(@pm);

    // save for debug checking
    VectorCopy(pm.s.origin, cl.predicted_origins[frame]);
    Inc(ack);
  end;

  oldframe := (ack - 2) and (CMD_BACKUP - 1);
  oldz := cl.predicted_origins[oldframe][2];
  step := pm.s.origin[2] - oldz;
  if (step > 63) and (step < 160) and (pm.s.pm_flags and PMF_ON_GROUND <> 0) then
  begin
    cl.predicted_step := step * 0.125;
    cl.predicted_step_time := Trunc(cls.realtime - cls.frametime * 500);
  end;

  // copy results out for rendering
  cl.predicted_origin[0] := pm.s.origin[0] * 0.125;
  cl.predicted_origin[1] := pm.s.origin[1] * 0.125;
  cl.predicted_origin[2] := pm.s.origin[2] * 0.125;

  VectorCopy(pm.viewangles, cl.predicted_angles);
end;

end.
