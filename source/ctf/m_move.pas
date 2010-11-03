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
{ File(s): m_move.pas                                                        }
{ Content: Monster movement commands                                         }
{                                                                            }
{ Initial conversion by : you_known - you_known@163.com                      }
{ Initial conversion on : 03-Feb-2002                                        }
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
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{                                                                            }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{                                                                            }
{----------------------------------------------------------------------------}

unit m_move;

interface

uses g_local;

type pedict_t = ^edict_t;
     qboolean =boolean;

const STEPSIZE = 18;

implementation
(*
=============
M_CheckBottom

Returns false if any part of the bottom of the entity is off an edge that
is not a staircase.

=============
*)
var c_yes,c_no: Smallint;

function M_CheckBottom(ent:pedict_t):qboolean;
label realcheck;
var   mins, maxs, start, stop: vec3_t;
      trace: trace_t;
      x,y: Smallint;
      mid,bottom: Single;
begin
      VectorAdd(ent^.s.origin,ent^.mins,mins);
      VectorAdd(ent^.s.origin,ent^.maxs,maxs);

// if all of the points under the corners are solid world, don't bother
// with the tougher checks
// the corners must be within 16 of the midpoint
       start[2] := mins[2] - 1;
       for x := 0 to 1 do
           for y := 0 to 1 do
     begin
                if x = 0 then
                 start[0] := mins[0] else start[0] := maxs[0];
                if y = 0 then
                 start[1] := mins[1] else start[1] := maxs[1];
                if gi.pointcontents(start) <> CONTENTS_SOLID then
                 goto realcheck;
     end;
       c_yes := c_yes + 1;
       result:=True;          // we got out easy

realcheck:

       c_no := c_no + 1;
//
// check it for real...
//
       start[2] := mins[2];
  
// the midpoint must be within 16 of the bottom
       stop[0] := (mins[0] + maxs[0])*0.5;
      start[0] := stop[0];
       stop[1] := (mins[1] + maxs[1])*0.5;
      start[1] := stop[1];
       stop[2] := start[2] - 2*STEPSIZE;
       trace := gi.trace (start, vec3_origin, vec3_origin, stop, ent, MASK_MONSTERSOLID);

       if trace.fraction = 1.0 then
              result := False;
       bottom := trace.endpos[2];
          mid := bottom;
// the corners must be within 16 of the midpoint
       for x := 0 to 1 do
           for y :=0 to 1 do
     begin
                if x = 0 then
                 stop[0] := mins[0] else stop[0] := maxs[0];
                 start[0] := stop[0];
                if y = 0 then
                 stop[1] := mins[1] else stop[1] := maxs[1];
                 start[1] := stop[1];

                trace := gi.trace (start, vec3_origin, vec3_origin, stop, ent, MASK_MONSTERSOLID);

                if (trace.fraction <> 1.0) and (trace.endpos[2] > bottom) then
                       bottom := trace.endpos[2];
                if (trace.fraction = 1.0) or (mid - trace.endpos[2] > STEPSIZE)
                       then result := False;
     end;

       c_yes := c_yes + 1;
       result := True;
end;



(*
=============
SV_movestep

Called by monster program code.
The move will be adjusted for slopes and stairs, but if the move isn't
possible, no move is done, false is returned, and
pr_global_struct->trace_normal is set to the normal of the blocking wall
=============
*)
//FIXME since we need to test end position contents here, can we avoid doing
//it again later in catagorize position?
function SV_movestep(ent:pedict_t; move:vec3_t; relink:qboolean):qboolean;
var  dz:Single;
     oldorg, neworg, vend:vec3_t; //We can not use 'end' here,so I used vend.
     trace:trace_t;
     i:Smallint;
     stepsizes:Single; //Well,case not sensitive,'stepsizes' replaced 'stepsize'.
     test:vec3_t;
     contents:smallint;
begin

// try the move  
       VectorCopy (ent^.s.origin, oldorg);
       VectorAdd (ent^.s.origin, move, neworg);

// flying monsters don't step up
       if (ent^.flags and (FL_SWIM or FL_FLY)) then
        begin
        // try one move with vertical motion, then one without
    for i := 0 to 1 do
   begin
                    VectorAdd(ent^.s.origin, move ,neworg);
                    if (i = 0) and (ent^.enemy) then
       begin
                        if not ent^.goalentity then
                                 ent^.goalentity := ent^.enemy;
                        dz := ent^.s.origin[2] - ent^.goalentity^.s.origin[2];
                        if (ent^.goalentity^.client) then
           begin
                            if dz > 40 then
                                   neworg[2] := neworg[2] - 8;
                            if not ((ent^.flags and FL_SWIM) and (ent^.waterlevel < 2)) then
                                   if dz < 30 then
                                          neworg[2] := neworg[2] + 8;
                  end
                         else
           begin
                            if dz > 8 then
                                   neworg[2] := neworg[2] + 8
                            else if dz > 0 then
                                   neworg[2] := neworg[2] - dz
                            else if dz < -8 then
                                   neworg[2] := neworg[2] + 8
                            else   neworg[2] := neworg[2] + dz;
                  end;
              end;
                     trace := gi.trace (ent^.s.origin, ent^.mins, ent^.maxs, neworg, ent, MASK_MONSTERSOLID);

                     // fly monsters don't enter water voluntarily
                     if (ent^.flags and FL_FLY) then
        begin
                         if not ent^.waterlevel then
            begin
                             test[0] := trace.endpos[0];
                             test[1] := trace.endpos[1];
                             test[2] := trace.endpos[2] + ent^.mins[2] + 1;
                             contents := gi.pointcontents(test);
                             if (contents and MASK_WATER)=1 then
                                     result := False;
                   end;
               end;
                      // swim monsters don't exit water voluntarily
          if (ent^.flags and FL_SWIM)
         begin
        if (ent^.waterlevel < 2) then
             begin
            test[0] := trace.endpos[0];
            test[1] := trace.endpos[1];
            test[2] := trace.endpos[2] + ent^.mins[2] + 1;
            contents := gi.pointcontents(test);
                              if not (contents and MASK_WATER)=1 then
                                     result := False;
                    end;
                end;
                       if trace.fraction = 1 then
          begin
                           VectorCopy (trace.endpos, ent^.s.origin);
                           if relink then
              begin
                               gi.linkentity (ent);
                               G_TouchTriggers (ent);
                     end;
                            result := True;
                 end;

                        if not ent^.enemy then
                               break;
          end;
                 result := False;
        end;
// push down from a step height above the wished position
  if not ((ent^.monsterinfo.aiflags) and (AI_NOSTEP)) then
    stepsizes := STEPSIZE
  else
    stepsizes := 1;

        neworg[2] := neworg[2] + stepsizes;
        VectorCopy (neworg, vend);
        vend[2] := vend - stepsizes * 2;

        trace := gi.trace (neworg, ent^.mins, ent^.maxs, vend, ent, MASK_MONSTERSOLID);

        if trace.allsolid then
            result := False;
        if trace.startsolid then
  begin
            neworg[2] := neworg[2] - stepsizes;
            trace := gi.trace (neworg, ent^.mins, ent^.maxs, vend, ent, MASK_MONSTERSOLID);
            if (trace.allsolid or trace.startsolid) then
                    result := False;
  end;

         // don't go in to water
         if ent^.waterlevel = 0 then
   begin
       test[0] := trace.endpos[0];
       test[1] := trace.endpos[1];
       test[2] := trace.endpos[2] + ent^.mins[2] + 1;
       contents := gi.pointcontents(test);

             if (contents and MASK_WATER)
                     result := False;
   end;

          if trace.fraction = 1 then
    begin
           // if monster had the ground pulled out, go ahead and fall
              if (ent^.flags and FL_PARTIALGROUND) then
        begin
                  VectorAdd (ent^.s.origin, move, ent^.s.origin);
                  if relink then
     begin
                      gi.linkentity (ent);
                      G_TouchTriggers (ent);
            end;
                   ent^.groundentity := nil;
                   result := True;
        end;

               result := False;    // walked off an edge
    end;

// check point traces down for dangling corners
          VectorCopy (trace.endpos, ent^.s.origin);

          if not (M_CheckBottom (ent)) then
    begin
              if (ent^.flags and FL_PARTIALGROUND) then
        begin
                   // entity had floor mostly pulled out from underneath it
       // and is trying to correct
                   if relink then
      begin
                       gi.linkentity (ent);
                       G_TouchTriggers (ent);
             end;
                    result := True;
        end;
               VectorCopy (oldorg, ent^.s.origin);
               result := False;
    end;
          if (ent^.flags and FL_PARTILGROUND) then
    begin
              ent^.flags := ent^.flags and (not FL_PARTILGROUND);
    end;
           ent^.groundentity := trace.ent;
           ent^.groundentity_linkcount := trace.ent^.linkcount;

// the move is ok
          if relink then
    begin
              gi.linkentity (ent);
              G_TouchTriggers (ent);
    end;
           result := True;
end;

//============================================================================

(*
===============
M_ChangeYaw

===============
*)
procedure M_ChangeYaw (ent:pedict);
var  ideal:single;
     current:single;
     move:single;
     speed:single;
begin
     current := anglemod (ent^.s.angles[YAW]);
     ideal := ent^.ideal_yaw;

     if current = ideal then
            exit;

     move := ideal - current;
     speed := ent^.yaw_speed;
     if ideal > current then
      begin
         if move >= 180 then
               move := move - 360;
      end
      else
      begin
         if move <= -180 then
               move := move + 360;
      end;
     if move >0 then
      begin
         if move > speed then
               move := speed;
      end
      else
      begin
         if move < -speed then
               move := -speed;
      end;

      ent^.s.angles[YAW] := anglemod (current + move);
end;

(*
======================
SV_StepDirection

Turns to the movement direction, and walks the current distance if
facing it.

======================
*)
function SV_StepDirection (ent:pedict_t; yaw:single; dist:single):qboolean;
var   move, oldorigin:vec3_t;
      delta:single;
begin
  ent^.ideal_yaw := yaw;
  M_ChangeYaw (ent);
  
  yaw := yaw*M_PI*2 / 360;
  move[0] := cos(yaw)*dist;
  move[1] := sin(yaw)*dist;
  move[2] := 0;

  VectorCopy (ent^.s.origin, oldorigin);
  if (SV_movestep (ent, move, false))
  begin
    delta := ent^s.angles[YAW] - ent^.ideal_yaw;
    if ((delta > 45) and (delta < 315))
     begin    // not turned far enough, so don't take the step
      VectorCopy (oldorigin, ent^.s.origin);
          end;
    gi.linkentity (ent);
    G_TouchTriggers (ent);
    result := True;
  end;
  gi.linkentity (ent);
  G_TouchTriggers (ent);
  result := False;
end;

(*
======================
SV_FixCheckBottom

======================
*)
procedure SV_FixCheckBottom (ent:pedict_t);
begin
  ent^.flags := ent^.flags or FL_PARTIALGROUND;
end;

(*
================
SV_NewChaseDir

================
*)
const  DI_NODIR = -1;
procedure SV_NewChaseDir (actor:pedict_t; enemy:pedict_t; dist:single);
var  deltax,deltay:single;
     d[3]:single;
     tdir, olddir, turnaround:single;
begin
  //FIXME: how did we get here with no enemy
  if not (enemy) then
    exit;

  olddir := anglemod( int((actor^.ideal_yaw/45)*45) );
  turnaround := anglemod(olddir - 180);

  deltax := enemy^.s.origin[0] - actor^.s.origin[0];
  deltay := enemy^.s.origin[1] - actor^.s.origin[1];
  if (deltax>10) then
    d[1] := 0;
  else if (deltax<-10) then
    d[1] := 180;
  else
    d[1] := DI_NODIR;
  if (deltay<-10) then
    d[2] := 270;
  else if (deltay>10) then
    d[2] := 90;
  else
    d[2] := DI_NODIR;

// try direct route
  if ((d[1] <> DI_NODIR) and (d[2] <> DI_NODIR)) then
  begin
    if (d[1] = 0) then
     begin
       if d[2] = 90 then d[2] := 45
          else d[2] := 315;
       tdir := d[2];
          end
    else
   begin
    if d[2] = 90 then d[2] := 135
       else d[2] := 215;
  tdir := d[2];
    end;
      
    if ((tdir <> turnaround) and (SV_StepDirection(actor, tdir, dist))) then
      exit;
  end;

// try other directions
  if ( ((random(360)and 3) and 1) or  abs(deltay)>abs(deltax)) then //??
  begin
    tdir:=d[1];
    d[1]:=d[2];
    d[2]:=tdir;
  end;

  if ((d[1] <> DI_NODIR) and (d[1] <> turnaround)
  and (SV_StepDirection(actor, d[1], dist))) then
      exit;

  if ((d[2]<>DI_NODIR) and (d[2]<>turnaround)
  and (SV_StepDirection(actor, d[2], dist))) then
      exit;

(* there is no direct path to the player, so pick another direction *)

  if ((olddir <> DI_NODIR) and (SV_StepDirection(actor, olddir, dist))) then
      exit;

  if (random(360) and 1) then   (*randomly determine direction of search*)
  begin
    for  tdir := 0 to 315 do
   begin
                        tdir := tdir + 45;
      if ((tdir<>turnaround) and (SV_StepDirection(actor, tdir, dist)) ) then
          exit;
          end;
  end
  else
  begin
    for tdir :=315 downto 0 do
   begin
                        tdir := tdir - 45;
      if ((tdir<>turnaround) and (SV_StepDirection(actor, tdir, dist)) ) then
          exit;
          end;
  end;

  if ((turnaround <> DI_NODIR) and (SV_StepDirection(actor, turnaround, dist)) ) then
      exit;

  actor^.ideal_yaw = olddir;    // can't move

// if a bridge was pulled out from underneath a monster, it may not have
// a valid standing position at all

  if (not M_CheckBottom (actor)) then
    SV_FixCheckBottom (actor);
end;


(*
======================
SV_CloseEnough

======================
*)
function SV_CloseEnough (ent:pedict_t; goal:pedict_t; dist:single):qboolean;
var
      i:smallint;
begin
  for i:=0 to 2 do
  begin
    if (goal^.absmin[i] > ent^.absmax[i] + dist) then
      result := false;
    if (goal^.absmax[i] < ent^.absmin[i] - dist) then
      result := false;
  end;
  result :=true;
end;


(*
======================
M_MoveToGoal
======================
*)
procedure M_MoveToGoal (ent:pedict_t; dist:single);
var
  goal:pedict_t;
begin
  goal := ent^.goalentity;

  if (not ent^.groundentity and not(ent^.flags and (FL_FLY or FL_SWIM))) then
    exit;

// if the next step hits the enemy, return immediately
  if (ent^.enemy and  SV_CloseEnough (ent, ent^.enemy, dist) ) then
    exit;

// bump around...
  if ( (random(360)and 3)=1 or not SV_StepDirection (ent, ent^.ideal_yaw, dist)) then
  begin
    if (ent^.inuse) then
      SV_NewChaseDir (ent, goal, dist);
  end;
end;


(*
===============
M_walkmove
===============
*)
function M_walkmove (ent:pedict_t; yaw:single; dist:single):qboolean;
var
  move:vec3_t;
begin
  if (not ent^.groundentity and not(ent^.flags and (FL_FLY or FL_SWIM))) then
    result := false;

  yaw := yaw*M_PI*2 / 360;
  
  move[0] := cos(yaw)*dist;
  move[1] := sin(yaw)*dist;
  move[2] := 0;

  result := SV_movestep(ent, move, true);
end;


end.
