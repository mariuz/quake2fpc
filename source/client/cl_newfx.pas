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
// cl_newfx.c -- MORE entity effects parsing and management

unit cl_newfx;

interface

uses
  q_shared,
  ref,
  Client;

procedure CL_Flashlight(ent: Integer; const pos: vec3_t);
procedure CL_ColorFlash(const pos: vec3_t; ent, intensity: Integer; r, g, b: Single);
procedure CL_DebugTrail(const start, end_: vec3_t);
procedure CL_SmokeTrail(const start, end_: vec3_t; colorStart, colorRun, spacing: Integer);
procedure CL_ForceWall(const start, end_: vec3_t; color: Integer);
procedure CL_FlameEffects(ent: centity_p; const origin: vec3_t);
procedure CL_GenericParticleEffect(const org, dir: vec3_t; color, count, numcolors, dirspread: Integer; alphavel: Single);
procedure CL_BubbleTrail2(const start, end_: vec3_t; dist: Integer);
procedure CL_Heatbeam(const start, forward_: vec3_t);
procedure CL_ParticleSteamEffect(var org, dir: vec3_t; color, count, magnitude: Integer);
procedure CL_ParticleSteamEffect2(self: cl_sustain_p); cdecl;
procedure CL_TrackerTrail(const start, end_: vec3_t; particleColor: Integer);
procedure CL_Tracker_Shell(const origin: vec3_t);
procedure CL_MonsterPlasma_Shell(const origin: vec3_t);
procedure CL_Widowbeamout(self: cl_sustain_p); cdecl;
procedure CL_Nukeblast(self: cl_sustain_p); cdecl;
procedure CL_WidowSplash(const org: vec3_t);
procedure CL_Tracker_Explode(const origin: vec3_t);
procedure CL_TagTrail(const start, end_: vec3_t; color: Single);
procedure CL_ColorExplosionParticles(const org: vec3_t; color, run: Integer);
procedure CL_ParticleSmokeEffect(var org, dir: vec3_t; color, count, magnitude: Integer);
procedure CL_BlasterParticles2(const org, dir: vec3_t; color: Cardinal);
procedure CL_BlasterTrail2(const start, end_: vec3_t);

implementation

uses
  cl_fx,
  cl_main,
  Common,
  Math;

function fmod(a, b: single): single;
begin
  result := a - (b * int(a / b));
end;

(*
======
vectoangles2 - this is duplicated in the game DLL, but I need it here.
======
*)

procedure vectoangles2(var value1, angles: vec3_t);
var
  forward_: Single;
  yaw_, pitch_: Single;
begin
  if (value1[1] = 0.0) and (value1[0] = 0.0) then
  begin
    yaw_ := 0.0;
    if (value1[2] > 0.0) then
      pitch_ := 90.0
    else
      pitch_ := 270.0;
  end
  else
  begin
    // PMM - fixed to correct for pitch of 0
    if (value1[0] <> 0.0) then
      yaw_ := (ArcTan2(value1[1], value1[0]) * 180.0 / M_PI)
    else if (value1[1] > 0.0) then
      yaw_ := 90
    else
      yaw_ := 270;

    if (yaw_ < 0.0) then
      yaw_ := yaw_ + 360.0;

    forward_ := Sqrt(value1[0] * value1[0] + value1[1] * value1[1]);
    pitch_ := (ArcTan2(value1[2], forward_) * 180.0 / M_PI);
    if (pitch_ < 0.0) then
      pitch_ := pitch_ + 360;
  end;

  angles[PITCH] := -pitch_;
  angles[YAW] := yaw_;
  angles[ROLL] := 0.0;
end;

//=============
//=============

procedure CL_Flashlight(ent: Integer; const pos: vec3_t);
var
  dl: cdlight_p;
begin
  dl := CL_AllocDlight(ent);
  VectorCopy(pos, dl^.origin);
  dl^.radius := 400;
  dl^.minlight := 250;
  dl^.die := cl.time + 100;
  dl^.color[0] := 1;
  dl^.color[1] := 1;
  dl^.color[2] := 1;
end;

(*
======
CL_ColorFlash - flash of light
======
*)

procedure CL_ColorFlash(const pos: vec3_t; ent, intensity: Integer; r, g, b: Single);
var
  dl: cdlight_p;
begin
  if ((vidref_val = VIDREF_SOFT) and ((r < 0) or (g < 0) or (b < 0))) then
  begin
    intensity := -intensity;
    r := -r;
    g := -g;
    b := -b;
  end;

  dl := CL_AllocDlight(ent);
  VectorCopy(pos, dl^.origin);
  dl^.radius := intensity;
  dl^.minlight := 250;
  dl^.die := cl.time + 100;
  dl^.color[0] := r;
  dl^.color[1] := g;
  dl^.color[2] := b;
end;

(*
======
CL_DebugTrail
======
*)

procedure CL_DebugTrail(const start, end_: vec3_t);
var
  move, vec: vec3_t;
  len: Single;
  //  j: Integer;
  p: cparticle_p;
  dec: Single;
  right, up: vec3_t;
begin
  VectorCopy(start, move);
  VectorSubtract(end_, start, vec);
  len := VectorNormalize(vec);

  MakeNormalVectors(vec, right, up);

  //   VectorScale(vec, RT2_SKIP, vec);

  //   dec = 1.0;
  //   dec = 0.75;
  dec := 3;
  VectorScale(vec, dec, vec);
  VectorCopy(start, move);

  while (len > 0) do
  begin
    len := len - dec;

    if (free_particles = nil) then
      Exit;
    p := free_particles;
    free_particles := p^.next;
    p^.next := active_particles;
    active_particles := p;

    p^.time := cl.time;
    VectorClear(p^.accel);
    VectorClear(p^.vel);
    p^.alpha := 1.0;
    p^.alphavel := -0.1;
    //      p^.alphavel := 0;
    p^.color := $74 + (rand() and 7);
    VectorCopy(move, p^.org);
    {
      for j := 0 to 2 do
      begin
       p^.org[j] := move[j] + crand()*2;
       p^.vel[j] := crand()*3;
       p^.accel[j] := 0;
      end;
    }
    VectorAdd(move, vec, move);
  end;
end;

(*
===============
CL_SmokeTrail
===============
*)

procedure CL_SmokeTrail(const start, end_: vec3_t; colorStart, colorRun, spacing: Integer);
var
  move, vec: vec3_t;
  len: Single;
  j: Integer;
  p: cparticle_p;
begin
  VectorCopy(start, move);
  VectorSubtract(end_, start, vec);
  len := VectorNormalize(vec);

  VectorScale(vec, spacing, vec);

  // FIXME: this is a really silly way to have a loop
  while (len > 0) do
  begin
    len := len - spacing;

    if (free_particles = nil) then
      Exit;
    p := free_particles;
    free_particles := p^.next;
    p^.next := active_particles;
    active_particles := p;
    VectorClear(p^.accel);

    p^.time := cl.time;

    p^.alpha := 1.0;
    p^.alphavel := -1.0 / (1 + frand() * 0.5);
    p^.color := colorStart + (rand() mod colorRun);
    for j := 0 to 2 do
    begin
      p^.org[j] := move[j] + crand() * 3;
      p^.accel[j] := 0;
    end;
    p^.vel[2] := 20 + crand() * 5;

    VectorAdd(move, vec, move);
  end;
end;

procedure CL_ForceWall(const start, end_: vec3_t; color: Integer);
var
  move, vec: vec3_t;
  len: Single;
  j: Integer;
  p: cparticle_p;
begin
  VectorCopy(start, move);
  VectorSubtract(end_, start, vec);
  len := VectorNormalize(vec);

  VectorScale(vec, 4, vec);

  // FIXME: this is a really silly way to have a loop
  while (len > 0) do
  begin
    len := len - 4;

    if (free_particles = nil) then
      Exit;

    if (frand() > 0.3) then
    begin
      p := free_particles;
      free_particles := p^.next;
      p^.next := active_particles;
      active_particles := p;
      VectorClear(p^.accel);

      p^.time := cl.time;

      p^.alpha := 1.0;
      p^.alphavel := -1.0 / (3.0 + frand() * 0.5);
      p^.color := color;
      for j := 0 to 2 do
      begin
        p^.org[j] := move[j] + crand() * 3;
        p^.accel[j] := 0;
      end;
      p^.vel[0] := 0;
      p^.vel[1] := 0;
      p^.vel[2] := -40 - (crand() * 10);
    end;

    VectorAdd(move, vec, move);
  end;
end;

procedure CL_FlameEffects(ent: centity_p; const origin: vec3_t);
var
  n, count, j: Integer;
  p: cparticle_p;
begin
  count := rand() and $F;

  for n := 0 to count - 1 do
  begin
    if (free_particles = nil) then
      Exit;

    p := free_particles;
    free_particles := p^.next;
    p^.next := active_particles;
    active_particles := p;

    VectorClear(p^.accel);
    p^.time := cl.time;

    p^.alpha := 1.0;
    p^.alphavel := -1.0 / (1 + frand() * 0.2);
    p^.color := 226 + (rand() mod 4);
    for j := 0 to 2 do
    begin
      p^.org[j] := origin[j] + crand() * 5;
      p^.vel[j] := crand() * 5;
    end;
    p^.vel[2] := crand() * -10;
    p^.accel[2] := -PARTICLE_GRAVITY;
  end;

  count := rand() and $7;

  for n := 0 to count - 1 do
  begin
    if (free_particles = nil) then
      Exit;
    p := free_particles;
    free_particles := p^.next;
    p^.next := active_particles;
    active_particles := p;
    VectorClear(p^.accel);

    p^.time := cl.time;

    p^.alpha := 1.0;
    p^.alphavel := -1.0 / (1 + frand() * 0.5);
    p^.color := 0 + (rand() mod 4);
    for j := 0 to 2 do
    begin
      p^.org[j] := origin[j] + crand() * 3;
    end;
    p^.vel[2] := 20 + crand() * 5;
  end;
end;

(*
===============
CL_GenericParticleEffect
===============
*)

procedure CL_GenericParticleEffect(const org, dir: vec3_t; color, count, numcolors, dirspread: Integer; alphavel: Single);
var
  i, j: Integer;
  p: cparticle_p;
  d: Single;
begin
  for i := 0 to count - 1 do
  begin
    if (free_particles = nil) then
      Exit;
    p := free_particles;
    free_particles := p^.next;
    p^.next := active_particles;
    active_particles := p;

    p^.time := cl.time;
    if (numcolors > 1) then
      p^.color := color + (rand() and numcolors)
    else
      p^.color := color;

    d := rand() and dirspread;
    for j := 0 to 2 do
    begin
      p^.org[j] := org[j] + ((rand() and 7) - 4) + d * dir[j];
      p^.vel[j] := crand() * 20;
    end;

    p^.accel[0] := 0.0;
    p^.accel[1] := 0.0;
    p^.accel[2] := -PARTICLE_GRAVITY;
    //      VectorCopy (accel, p^.accel);
    p^.alpha := 1.0;

    p^.alphavel := -1.0 / (0.5 + frand() * alphavel);
    //      p^.alphavel := alphavel;
  end;
end;

(*
===============
CL_BubbleTrail2 (lets you control the # of bubbles by setting the distance between the spawns)

===============
*)

procedure CL_BubbleTrail2(const start, end_: vec3_t; dist: Integer);
var
  move, vec: vec3_t;
  len: Single;
  i: Single;
  j: Integer;
  p: cparticle_p;
  dec: Single;
begin
  VectorCopy(start, move);
  VectorSubtract(end_, start, vec);
  len := VectorNormalize(vec);

  dec := dist;
  VectorScale(vec, dec, vec);

  i := 0;
  while (i < len) do
  begin
    if (free_particles = nil) then
      Exit;

    p := free_particles;
    free_particles := p^.next;
    p^.next := active_particles;
    active_particles := p;

    VectorClear(p^.accel);
    p^.time := cl.time;

    p^.alpha := 1.0;
    p^.alphavel := -1.0 / (1 + frand() * 0.1);
    p^.color := 4 + (rand() and 7);
    for j := 0 to 2 do
    begin
      p^.org[j] := move[j] + crand() * 2;
      p^.vel[j] := crand() * 10;
    end;
    p^.org[2] := p^.org[2] - 4;
    //      p^.vel[2] := p^.vel[2] + 6;
    p^.vel[2] := p^.vel[2] + 20;

    VectorAdd(move, vec, move);

    i := i + dec;
  end;
end;

{.$DEFINE CORKSCREW}
{.$DEFINE DOUBLE_SCREW}
{$DEFINE RINGS}
{.$DEFINE SPRAY}

{$IFDEF CORKSCREW}

procedure CL_Heatbeam(const start, end_: vec3_t);
var
  move, vec: vec3_t;
  len: Single;
  j, k: Integer;
  p: cparticle_p;
  right, up: vec3_t;
  i: Integer;
  d, c, s: Single;
  dir: vec3_t;
  ltime: Single;
  step: Integer;
begin
  step := 5;
  VectorCopy(start, move);
  VectorSubtract(end_, start, vec);
  len := VectorNormalize(vec);

  //   MakeNormalVectors (vec, right, up);
  VectorCopy(cl.v_right, right);
  VectorCopy(cl.v_up, up);
  VectorMA(move, -1, right, move);
  VectorMA(move, -1, up, move);

  VectorScale(vec, step, vec);
  ltime := cl.time / 1000.0;

  //   for i := 0 to len - 1 do
  i := 0;
  while (i < len) do
  begin
    d := i * 0.1 - fmod(ltime, 16.0) * M_PI;
    c := cos(d) / 1.75;
    s := sin(d) / 1.75;
{$IFDEF DOUBLE_SCREW}
    k := -1;
    while (k < 2) do
    begin
{$ELSE}
    k := 1;
{$ENDIF}
    if (free_particles = nil) then
      Exit;

    p := free_particles;
    free_particles := p^.next;
    p^.next := active_particles;
    active_particles := p;

    p^.time := cl.time;
    VectorClear(p^.accel);

    p^.alpha := 0.5;
    //      p^.alphavel := -1.0 / (1+frand()*0.2);
      // only last one frame!
    p^.alphavel := INSTANT_PARTICLE;
    //      p^.color := $74 + (rand() and 7);
   //         p^.color := 223 - (rand() and 7);
    p^.color := 223;
    //         p^.color := 240;

       // trim it so it looks like it's starting at the origin
    if (i < 10) then
    begin
      VectorScale(right, c * (i / 10.0) * k, dir);
      VectorMA(dir, s * (i / 10.0) * k, up, dir);
    end
    else
    begin
      VectorScale(right, c * k, dir);
      VectorMA(dir, s * k, up, dir);
    end;

    for j := 0 to 2 do
    begin
      p^.org[j] := move[j] + dir[j] * 3;
      //         p^.vel[j] := dir[j]*6;
      p^.vel[j] := 0;
    end;
{$IFDEF DOUBLE_SCREW}
    k := k + 2;
  end;
{$ENDIF}
  VectorAdd(move, vec, move);

  i := i + step;
end;
end;
{$ENDIF}
{$IFDEF RINGS}
//procedure CL_Heatbeam (vec3_t start, vec3_t end)

procedure CL_Heatbeam(const start, forward_: vec3_t);
var
  move: vec3_t;
  vec: vec3_t;
  len: Single;
  j: Integer;
  p: cparticle_p;
  right, up: vec3_t;
  i: Single;
  c, s: Single;
  dir: vec3_t;
  ltime: Single;
  step, rstep: Single;
  start_pt: Single;
  rot: Single;
  variance: Single;
  end_: vec3_t;
begin
  step := 32.0;
  VectorMA(start, 4096, forward_, end_);

  VectorCopy(start, move);
  VectorSubtract(end_, start, vec);
  len := VectorNormalize(vec);

  // FIXME - pmm - these might end up using old values?
 //   MakeNormalVectors (vec, right, up);
  VectorCopy(cl.v_right, right);
  VectorCopy(cl.v_up, up);
  if (vidref_val = VIDREF_GL) then
  begin                                 // GL mode
    VectorMA(move, -0.5, right, move);
    VectorMA(move, -0.5, up, move);
  end;
  // otherwise assume SOFT

  ltime := cl.time / 1000.0;
  start_pt := fmod(ltime * 96.0, step);
  VectorMA(move, start_pt, vec, move);

  VectorScale(vec, step, vec);

  //   Com_Printf ("%f"#10, ltime);
  rstep := M_PI / 10.0;
  i := start_pt;
  while (i < len) do
  begin
    if (i > step * 5) then              // don't bother after the 5th ring
      break;

    rot := 0.0;
    while (rot < M_PI * 2) do
    begin

      if (free_particles = nil) then
        Exit;

      p := free_particles;
      free_particles := p^.next;
      p^.next := active_particles;
      active_particles := p;

      p^.time := cl.time;
      VectorClear(p^.accel);
      //         rot := rot + fmod(ltime, 12.0)*M_PI;
      //         c := cos(rot)/2.0;
      //         s := sin(rot)/2.0;
      //         variance := 0.4 + ((float)rand()/(float)RAND_MAX) *0.2;
      variance := 0.5;
      c := cos(rot) * variance;
      s := sin(rot) * variance;

      // trim it so it looks like it's starting at the origin
      if (i < 10) then
      begin
        VectorScale(right, c * (i / 10.0), dir);
        VectorMA(dir, s * (i / 10.0), up, dir);
      end
      else
      begin
        VectorScale(right, c, dir);
        VectorMA(dir, s, up, dir);
      end;

      p^.alpha := 0.5;
      //      p^.alphavel := -1.0 / (1+frand()*0.2);
      p^.alphavel := -1000.0;
      //      p^.color := 0x74 + (rand()&7);
      p^.color := 223 - (rand() and 7);
      for j := 0 to 2 do
      begin
        p^.org[j] := move[j] + dir[j] * 3;
        //         p^.vel[j] := dir[j]*6;
        p^.vel[j] := 0;
      end;

      rot := rot + rstep;
    end;
    VectorAdd(move, vec, move);

    i := i + step;
  end;
end;
{$ENDIF}
{$IFDEF SPRAY}

procedure CL_Heatbeam(const start, end_: vec3_t);
var
  move: vec3_t;
  vec: vec3_t;
  len: Single;
  j: Integer;
  p: cparticle_p;
  forward_, right, up: vec3_t;
  i: Integer;
  d, c, s: Single;
  dir: vec3_t;
  ltime: SIngle;
  step, rstep: Single;
  start_pt: Single;
  rot: Single;
begin
  step := 32.0;
  VectorCopy(start, move);
  VectorSubtract(end_, start, vec);
  len := VectorNormalize(vec);

  //   MakeNormalVectors (vec, right, up);
  VectorCopy(cl.v_forward, forward_);
  VectorCopy(cl.v_right, right);
  VectorCopy(cl.v_up, up);
  VectorMA(move, -0.5, right, move);
  VectorMA(move, -0.5, up, move);

  for i := 0 to 7 do
  begin
    if (free_particles = nil) then
      Exit;

    p := free_particles;
    free_particles := p^.next;
    p^.next := active_particles;
    active_particles := p;

    p^.time := cl.time;
    VectorClear(p^.accel);

    d := crand() * M_PI;
    c := cos(d) * 30;
    s := sin(d) * 30;

    p^.alpha := 1.0;
    p^.alphavel := -5.0 / (1 + frand());
    p^.color := 223 - (rand() and 7);

    for j := 0 to 2 do
    begin
      p^.org[j] := move[j];
    end;
    VectorScale(vec, 450, p^.vel);
    VectorMA(p^.vel, c, right, p^.vel);
    VectorMA(p^.vel, s, up, p^.vel);
  end;
  // Sly 30-Jun-2002 This section was commented in the original source
  (*

   ltime = (float) cl.time/1000.0;
   start_pt = fmod(ltime*16.0,step);
   VectorMA (move, start_pt, vec, move);

   VectorScale (vec, step, vec);

  //   Com_Printf ("%f"#10, ltime);
   rstep = M_PI/12.0;
   for (i=start_pt ; i<len ; i+=step)
   begin
    if (i>step*5) // don't bother after the 5th ring
     break;

    for (rot = 0; rot < M_PI*2; rot += rstep)
    begin
     if (!free_particles)
      return;

     p = free_particles;
     free_particles = p^.next;
     p^.next = active_particles;
     active_particles = p;

     p^.time = cl.time;
     VectorClear (p^.accel);
  //         rot+= fmod(ltime, 12.0)*M_PI;
  //         c = cos(rot)/2.0;
  //         s = sin(rot)/2.0;
     c = cos(rot)/1.5;
     s = sin(rot)/1.5;

     // trim it so it looks like it's starting at the origin
     if (i < 10)
     begin
      VectorScale (right, c*(i/10.0), dir);
      VectorMA (dir, s*(i/10.0), up, dir);
     end;
     else
     begin
      VectorScale (right, c, dir);
      VectorMA (dir, s, up, dir);
     end;

     p^.alpha = 0.5;
   //      p^.alphavel = -1.0 / (1+frand()*0.2);
     p^.alphavel = -1000.0;
   //      p^.color = 0x74 + (rand()&7);
     p^.color = 223 - (rand()&7);
     for (j=0 ; j<3 ; j++)
     begin
      p^.org[j] = move[j] + dir[j]*3;
   //         p^.vel[j] = dir[j]*6;
      p^.vel[j] = 0;
     end;
    end;
    VectorAdd (move, vec, move);
   end;
  *)
end;
{$ENDIF}

(*
===============
CL_ParticleSteamEffect

Puffs with velocity along direction, with some randomness thrown in
===============
*)

procedure CL_ParticleSteamEffect(var org, dir: vec3_t; color, count, magnitude: Integer);
var
  i, j: Integer;
  p: cparticle_p;
  d: Single;
  r, u: vec3_t;
begin
  //   vectoangles2 (dir, angle_dir);
  //   AngleVectors (angle_dir, f, r, u);

  MakeNormalVectors(dir, r, u);

  for i := 0 to count - 1 do
  begin
    if (free_particles = nil) then
      Exit;
    p := free_particles;
    free_particles := p^.next;
    p^.next := active_particles;
    active_particles := p;

    p^.time := cl.time;
    p^.color := color + (rand() and 7);

    for j := 0 to 2 do
    begin
      p^.org[j] := org[j] + magnitude * 0.1 * crand();
      //         p^.vel[j] := dir[j]*magnitude;
    end;
    VectorScale(dir, magnitude, p^.vel);
    d := crand() * magnitude / 3;
    VectorMA(p^.vel, d, r, p^.vel);
    d := crand() * magnitude / 3;
    VectorMA(p^.vel, d, u, p^.vel);

    p^.accel[0] := 0;
    p^.accel[1] := 0;
    p^.accel[2] := -PARTICLE_GRAVITY / 2;
    p^.alpha := 1.0;

    p^.alphavel := -1.0 / (0.5 + frand() * 0.3);
  end;
end;

procedure CL_ParticleSteamEffect2(self: cl_sustain_p);
//vec3_t org, vec3_t dir, int color, int count, int magnitude)
var
  i, j: Integer;
  p: cparticle_p;
  d: Single;
  r, u: vec3_t;
  dir: vec3_t;
begin
  //   vectoangles2 (dir, angle_dir);
  //   AngleVectors (angle_dir, f, r, u);

  VectorCopy(self^.dir, dir);
  MakeNormalVectors(dir, r, u);

  for i := 0 to self^.count - 1 do
  begin
    if (free_particles = nil) then
      Exit;
    p := free_particles;
    free_particles := p^.next;
    p^.next := active_particles;
    active_particles := p;

    p^.time := cl.time;
    p^.color := self^.color + (rand() and 7);

    for j := 0 to 2 do
    begin
      p^.org[j] := self^.org[j] + self^.magnitude * 0.1 * crand();
      //         p^.vel[j] := dir[j]*magnitude;
    end;
    VectorScale(dir, self^.magnitude, p^.vel);
    d := crand() * self^.magnitude / 3;
    VectorMA(p^.vel, d, r, p^.vel);
    d := crand() * self^.magnitude / 3;
    VectorMA(p^.vel, d, u, p^.vel);

    p^.accel[0] := 0;
    p^.accel[1] := 0;
    p^.accel[2] := -PARTICLE_GRAVITY / 2;
    p^.alpha := 1.0;

    p^.alphavel := -1.0 / (0.5 + frand() * 0.3);
  end;
  self^.nextthink := self^.nextthink + self^.thinkinterval;
end;

(*
===============
CL_TrackerTrail
===============
*)

procedure CL_TrackerTrail(const start, end_: vec3_t; particleColor: Integer);
var
  move: vec3_t;
  vec: vec3_t;
  forward_, right, up, angle_dir: vec3_t;
  len: Single;
  j: Integer;
  p: cparticle_p;
  dec: Integer;
  dist: Single;
begin
  VectorCopy(start, move);
  VectorSubtract(end_, start, vec);
  len := VectorNormalize(vec);

  VectorCopy(vec, forward_);
  vectoangles2(forward_, angle_dir);
  AngleVectors(angle_dir, @forward_, @right, @up);

  dec := 3;
  VectorScale(vec, 3, vec);

  // FIXME: this is a really silly way to have a loop
  while (len > 0) do
  begin
    len := len - dec;

    if (free_particles = nil) then
      Exit;
    p := free_particles;
    free_particles := p^.next;
    p^.next := active_particles;
    active_particles := p;
    VectorClear(p^.accel);

    p^.time := cl.time;

    p^.alpha := 1.0;
    p^.alphavel := -2.0;
    p^.color := particleColor;
    dist := DotProduct(move, forward_);
    VectorMA(move, 8 * cos(dist), up, p^.org);
    for j := 0 to 2 do
    begin
      //         p^.org[j] := move[j] + crand();
      p^.vel[j] := 0;
      p^.accel[j] := 0;
    end;
    p^.vel[2] := 5;

    VectorAdd(move, vec, move);
  end;
end;

procedure CL_Tracker_Shell(const origin: vec3_t);
var
  dir: vec3_t;
  i: Integer;
  p: cparticle_p;
begin
  for i := 0 to 299 do
  begin
    if (free_particles = nil) then
      Exit;
    p := free_particles;
    free_particles := p^.next;
    p^.next := active_particles;
    active_particles := p;
    VectorClear(p^.accel);

    p^.time := cl.time;

    p^.alpha := 1.0;
    p^.alphavel := INSTANT_PARTICLE;
    p^.color := 0;

    dir[0] := crand();
    dir[1] := crand();
    dir[2] := crand();
    VectorNormalize(dir);

    VectorMA(origin, 40, dir, p^.org);
  end;
end;

procedure CL_MonsterPlasma_Shell(const origin: vec3_t);
var
  dir: vec3_t;
  i: Integer;
  p: cparticle_p;
begin
  for i := 0 to 39 do
  begin
    if (free_particles = nil) then
      Exit;
    p := free_particles;
    free_particles := p^.next;
    p^.next := active_particles;
    active_particles := p;
    VectorClear(p^.accel);

    p^.time := cl.time;

    p^.alpha := 1.0;
    p^.alphavel := INSTANT_PARTICLE;
    p^.color := $E0;

    dir[0] := crand();
    dir[1] := crand();
    dir[2] := crand();
    VectorNormalize(dir);

    VectorMA(origin, 10, dir, p^.org);
    //      VectorMA(origin, 10*(((rand () & 0x7fff) / ((float)0x7fff))), dir, p^.org);
  end;
end;

procedure CL_Widowbeamout(self: cl_sustain_p);
const
  colortable: array[0..3] of Integer = (2 * 8, 13 * 8, 21 * 8, 18 * 8);
var
  dir: vec3_t;
  i: Integer;
  p: cparticle_p;
  ratio: Single;
begin
  ratio := 1.0 - ((self^.endtime - cl.time) / 2100.0);

  for i := 0 to 299 do
  begin
    if (free_particles = nil) then
      Exit;
    p := free_particles;
    free_particles := p^.next;
    p^.next := active_particles;
    active_particles := p;
    VectorClear(p^.accel);

    p^.time := cl.time;

    p^.alpha := 1.0;
    p^.alphavel := INSTANT_PARTICLE;
    p^.color := colortable[rand() and 3];

    dir[0] := crand();
    dir[1] := crand();
    dir[2] := crand();
    VectorNormalize(dir);

    VectorMA(self^.org, (45.0 * ratio), dir, p^.org);
    //      VectorMA(origin, 10*(((rand () & 0x7fff) / ((float)0x7fff))), dir, p^.org);
  end;
end;

procedure CL_Nukeblast(self: cl_sustain_p);
const
  colortable: array[0..3] of Integer = (110, 112, 114, 116);
var
  dir: vec3_t;
  i: Integer;
  p: cparticle_p;
  ratio: Single;
begin
  ratio := 1.0 - ((self^.endtime - cl.time) / 1000.0);

  for i := 0 to 699 do
  begin
    if (free_particles = nil) then
      Exit;
    p := free_particles;
    free_particles := p^.next;
    p^.next := active_particles;
    active_particles := p;
    VectorClear(p^.accel);

    p^.time := cl.time;

    p^.alpha := 1.0;
    p^.alphavel := INSTANT_PARTICLE;
    p^.color := colortable[rand() and 3];

    dir[0] := crand();
    dir[1] := crand();
    dir[2] := crand();
    VectorNormalize(dir);

    VectorMA(self^.org, (200.0 * ratio), dir, p^.org);
    //      VectorMA(origin, 10*(((rand () & 0x7fff) / ((float)0x7fff))), dir, p^.org);
  end;
end;

procedure CL_WidowSplash(const org: vec3_t);
const
  colortable: array[0..3] of Integer = (2 * 8, 13 * 8, 21 * 8, 18 * 8);
var
  i: Integer;
  p: cparticle_p;
  dir: vec3_t;
begin
  for i := 0 to 255 do
  begin
    if (free_particles = nil) then
      Exit;
    p := free_particles;
    free_particles := p^.next;
    p^.next := active_particles;
    active_particles := p;

    p^.time := cl.time;
    p^.color := colortable[rand() and 3];

    dir[0] := crand();
    dir[1] := crand();
    dir[2] := crand();
    VectorNormalize(dir);
    VectorMA(org, 45.0, dir, p^.org);
    VectorMA(vec3_origin, 40.0, dir, p^.vel);

    p^.accel[0] := 0;
    p^.accel[1] := 0;
    p^.alpha := 1.0;

    p^.alphavel := -0.8 / (0.5 + frand() * 0.3);
  end;

end;

procedure CL_Tracker_Explode(const origin: vec3_t);
var
  dir, backdir: vec3_t;
  i: Integer;
  p: cparticle_p;
begin
  for i := 0 to 299 do
  begin
    if (free_particles = nil) then
      Exit;
    p := free_particles;
    free_particles := p^.next;
    p^.next := active_particles;
    active_particles := p;
    VectorClear(p^.accel);

    p^.time := cl.time;

    p^.alpha := 1.0;
    p^.alphavel := -1.0;
    p^.color := 0;

    dir[0] := crand();
    dir[1] := crand();
    dir[2] := crand();
    VectorNormalize(dir);
    VectorScale(dir, -1, backdir);

    VectorMA(origin, 64, dir, p^.org);
    VectorScale(backdir, 64, p^.vel);
  end;

end;

(*
===============
CL_TagTrail

===============
*)

procedure CL_TagTrail(const start, end_: vec3_t; color: Single);
var
  move: vec3_t;
  vec: vec3_t;
  len: Single;
  j: Integer;
  p: cparticle_p;
  dec: Integer;
begin
  VectorCopy(start, move);
  VectorSubtract(end_, start, vec);
  len := VectorNormalize(vec);

  dec := 5;
  VectorScale(vec, 5, vec);

  while (len >= 0) do
  begin
    len := len - dec;

    if (free_particles = nil) then
      Exit;
    p := free_particles;
    free_particles := p^.next;
    p^.next := active_particles;
    active_particles := p;
    VectorClear(p^.accel);

    p^.time := cl.time;

    p^.alpha := 1.0;
    p^.alphavel := -1.0 / (0.8 + frand() * 0.2);
    p^.color := color;
    for j := 0 to 2 do
    begin
      p^.org[j] := move[j] + crand() * 16;
      p^.vel[j] := crand() * 5;
      p^.accel[j] := 0;
    end;

    VectorAdd(move, vec, move);
  end;
end;

(*
===============
CL_ColorExplosionParticles
===============
*)

procedure CL_ColorExplosionParticles(const org: vec3_t; color, run: Integer);
var
  i, j: Integer;
  p: cparticle_p;
begin
  for i := 0 to 127 do
  begin
    if (free_particles = nil) then
      Exit;
    p := free_particles;
    free_particles := p^.next;
    p^.next := active_particles;
    active_particles := p;

    p^.time := cl.time;
    p^.color := color + (rand() mod run);

    for j := 0 to 2 do
    begin
      p^.org[j] := org[j] + ((rand() mod 32) - 16);
      p^.vel[j] := (rand() mod 256) - 128;
    end;

    p^.accel[0] := 0;
    p^.accel[1] := 0;
    p^.accel[2] := -PARTICLE_GRAVITY;
    p^.alpha := 1.0;

    p^.alphavel := -0.4 / (0.6 + frand() * 0.2);
  end;
end;

(*
===============
CL_ParticleSmokeEffect - like the steam effect, but unaffected by gravity
===============
*)

procedure CL_ParticleSmokeEffect(var org, dir: vec3_t; color, count, magnitude: Integer);
var
  i, j: Integer;
  p: cparticle_p;
  d: Single;
  r, u: vec3_t;
begin
  MakeNormalVectors(dir, r, u);

  for i := 0 to count - 1 do
  begin
    if (free_particles = nil) then
      Exit;
    p := free_particles;
    free_particles := p^.next;
    p^.next := active_particles;
    active_particles := p;

    p^.time := cl.time;
    p^.color := color + (rand() and 7);

    for j := 0 to 2 do
    begin
      p^.org[j] := org[j] + magnitude * 0.1 * crand();
      //         p^.vel[j] := dir[j]*magnitude;
    end;
    VectorScale(dir, magnitude, p^.vel);
    d := crand() * magnitude / 3;
    VectorMA(p^.vel, d, r, p^.vel);
    d := crand() * magnitude / 3;
    VectorMA(p^.vel, d, u, p^.vel);

    p^.accel[0] := 0;
    p^.accel[1] := 0;
    p^.accel[2] := 0;
    p^.alpha := 1.0;

    p^.alphavel := -1.0 / (0.5 + frand() * 0.3);
  end;
end;

(*
===============
CL_BlasterParticles2

Wall impact puffs (Green)
===============
*)

procedure CL_BlasterParticles2(const org, dir: vec3_t; color: Cardinal);
var
  i, j: Integer;
  p: cparticle_p;
  d: Single;
  count: Integer;
begin
  count := 40;
  for i := 0 to count - 1 do
  begin
    if (free_particles = nil) then
      Exit;
    p := free_particles;
    free_particles := p^.next;
    p^.next := active_particles;
    active_particles := p;

    p^.time := cl.time;
    p^.color := color + Cardinal(rand() and 7);

    d := rand() and 15;
    for j := 0 to 2 do
    begin
      p^.org[j] := org[j] + ((rand() and 7) - 4) + d * dir[j];
      p^.vel[j] := dir[j] * 30 + crand() * 40;
    end;

    p^.accel[0] := 0;
    p^.accel[1] := 0;
    p^.accel[2] := -PARTICLE_GRAVITY;
    p^.alpha := 1.0;

    p^.alphavel := -1.0 / (0.5 + frand() * 0.3);
  end;
end;

(*
===============
CL_BlasterTrail2

Green!
===============
*)

procedure CL_BlasterTrail2(const start, end_: vec3_t);
var
  move: vec3_t;
  vec: vec3_t;
  len: Single;
  j: Integer;
  p: cparticle_p;
  dec: Integer;
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
      Exit;
    p := free_particles;
    free_particles := p^.next;
    p^.next := active_particles;
    active_particles := p;
    VectorClear(p^.accel);

    p^.time := cl.time;

    p^.alpha := 1.0;
    p^.alphavel := -1.0 / (0.3 + frand() * 0.2);
    p^.color := $D0;
    for j := 0 to 2 do
    begin
      p^.org[j] := move[j] + crand();
      p^.vel[j] := crand() * 5;
      p^.accel[j] := 0;
    end;

    VectorAdd(move, vec, move);
  end;
end;

end.
