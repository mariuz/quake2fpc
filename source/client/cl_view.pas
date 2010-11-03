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
{ File(s): client\cl_view.c                                                  }
{                                                                            }
{ Initial conversion by : Ter Roshak                                         }
{ Initial conversion on : ?                                                  }
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
// cl_view.c -- player rendering positioning

unit cl_view;

interface

uses
  q_shared,
  Client,
  ref;

procedure V_ClearScene;
procedure V_AddLightStyle(style: integer; r, g, b: single);
procedure V_AddEntity(ent: entity_p);
procedure V_AddParticle(const org: vec3_t; color: integer; alpha: single);
procedure V_AddLight(const org: vec3_t; intensity: Single; r, g, b: Single);
procedure V_TestParticles;
procedure V_RenderView(stereo_separation: single);
procedure V_Init;

procedure CL_PrepRefresh;
function CalcFov(fov_x, width, height: Single): Single;

//=============
//
// development tools for weapons
//
var
  gun_frame: integer;
  gun_model: model_p;

  //=============

  crosshair: cvar_p;
  cl_testparticles: cvar_p;
  cl_testentities: cvar_p;
  cl_testlights: cvar_p;
  cl_testblend: cvar_p;

  cl_stats: cvar_p;

  r_numdlights: integer;
  r_dlights: array[0..MAX_DLIGHTS - 1] of dlight_t;

  r_numentities: integer;
  r_entities: array[0..MAX_ENTITIES - 1] of entity_t;

  r_numparticles: integer;
  r_particles: array[0..MAX_PARTICLES - 1] of particle_t;

  r_lightstyles: array[0..MAX_LIGHTSTYLES - 1] of lightstyle_t;

  cl_weaponmodels: array[0..MAX_CLIENTWEAPONMODELS - 1] of array[0..MAX_QPATH - 1] of char;
  num_cl_weaponmodels: integer;

implementation

uses
  cl_scrn,
  cl_main,
  {$IFDEF WIN32}
  sys_win,
  q_shwin,
  cd_win,
  vid_dll,
  {$ELSE}
  sys_linux,
  q_shlinux,
  cd_sdl,
  vid_so,
  {$ENDIF}
  CModel,
  CPas,
  Cmd,
  Common,
  cl_tent,
  cl_parse,
  cl_ents,
  CVar,
  Console,
  sysutils,
  math;

{
====================
V_ClearScene

Specifies the model that will be used as the world
====================
}

procedure V_ClearScene;
begin

  r_numdlights := 0;
  r_numentities := 0;
  r_numparticles := 0;

end;

{
=====================
V_AddEntity

=====================
}

procedure V_AddEntity(ent: entity_p);
begin

  if (r_numentities >= MAX_ENTITIES) then
    exit;
  r_entities[r_numentities] := ent^;
  inc(r_numentities);

end;

{
=====================
V_AddParticle

=====================
}

procedure V_AddParticle(const org: vec3_t; color: integer; alpha: single);
var
  p: particle_p;
begin
  if (r_numparticles >= MAX_PARTICLES) then
    exit;
  p := @r_particles[r_numparticles];
  inc(r_numparticles);
  VectorCopy(org, p^.origin);
  p^.color := color;
  p^.alpha := alpha;
end;

{
=====================
V_AddLight

=====================
}

procedure V_AddLight(const org: vec3_t; intensity: Single; r, g, b: Single);
var
  dl: dlight_p;
begin
  if (r_numdlights >= MAX_DLIGHTS) then
    exit;
  dl := @r_dlights[r_numdlights];
  inc(r_numdlights);
  VectorCopy(org, dl^.origin);
  dl^.intensity := intensity;
  dl^.color[0] := r;
  dl^.color[1] := g;
  dl^.color[2] := b;
end;

{
=====================
V_AddLightStyle

=====================
}

procedure V_AddLightStyle(style: integer; r, g, b: single);
var
  ls: lightstyle_p;
begin

  if ((style < 0) or (style > MAX_LIGHTSTYLES)) then
    Com_Error(ERR_DROP, 'Bad light style %d', [style]);
  ls := @r_lightstyles[style];

  ls^.white := r + b + g;
  ls^.rgb[0] := r;
  ls^.rgb[1] := g;
  ls^.rgb[2] := b;

end;

{
================
V_TestParticles

If cl_testparticles is set, create 4096 particles in the view
================
}

procedure V_TestParticles;
var
  p: particle_p;
  i, j: integer;
  d, r, u: Single;
begin

  r_numparticles := MAX_PARTICLES;
  for i := 0 to r_numparticles - 1 do
  begin
    d := i * 0.25;
    r := 4 * ((i and 7) - 3.5);
    u := 4 * (((i shr 3) and 7) - 3.5);
    p := @r_particles[i];

    for j := 0 to 2 do
      p^.origin[j] := cl.refdef.vieworg[j] + cl.v_forward[j] * d +
        cl.v_right[j] * r + cl.v_up[j] * u;

    p^.color := 8;
    p^.alpha := cl_testparticles^.value;
  end;

end;

{
================
V_TestEntities

If cl_testentities is set, create 32 player models
================
}

procedure V_TestEntities;
var
  i, j: integer;
  f, r: Single;
  ent: entity_p;
begin

  r_numentities := 32;
  FillChar(r_entities, sizeof(r_entities), 0);

  for i := 0 to r_numentities - 1 do
  begin
    ent := @r_entities[i];

    r := 64 * ((i mod 4) - 1.5);
    f := 64 * (i / 4) + 128;

    for j := 0 to 2 do
      ent^.origin[j] := cl.refdef.vieworg[j] + cl.v_forward[j] * f +
        cl.v_right[j] * r;
    ent^.model := cl.baseclientinfo.model;
    ent^.skin := cl.baseclientinfo.skin;
  end;

end;

{
================
V_TestLights

If cl_testlights is set, create 32 lights models
================
}

procedure V_TestLights;
var
  i, j: integer;
  f, r: Single;
  dl: dlight_p;
begin

  r_numdlights := 32;
  FillChar(r_dlights, sizeof(r_dlights), 0);

  for i := 0 to r_numdlights - 1 do
  begin
    dl := @r_dlights[i];

    r := 64 * ((i mod 4) - 1.5);
    f := 64 * (i / 4) + 128;

    for j := 0 to 2 do
      dl^.origin[j] := cl.refdef.vieworg[j] + cl.v_forward[j] * f + cl.v_right[j] * r;

    dl^.color[0] := ((i mod 6) + 1) and 1;
    dl^.color[1] := (((i mod 6) + 1) and 2) shr 1;
    dl^.color[2] := (((i mod 6) + 1) and 4) shr 2;
    dl^.intensity := 200;
  end;

end;

//===================================================================

{
=================
CL_PrepRefresh

Call before entering a new level, or after changing dlls
=================
}

procedure CL_PrepRefresh;
var
  mapname: array[0..31] of char;
  i: integer;
  name: array[0..MAX_QPATH - 1] of char;
  rotate: Single;
  axis: vec3_t;
begin
  if (cl.configstrings[CS_MODELS + 1][0] = #0) then
    exit;                               // no map loaded

  SCR_AddDirtyPoint(0, 0);
  SCR_AddDirtyPoint(viddef.width - 1, viddef.height - 1);

  // let the render dll load the map
  strcpy(mapname, cl.configstrings[CS_MODELS + 1] + 5); // skip "maps/"
  mapname[strlen(mapname) - 4] := #0;   // cut off ".bsp"

  // register models, pics, and skins
  Com_Printf('Map: %s'#13, [mapname]);
  SCR_UpdateScreen;
  re.BeginRegistration(mapname);
  Com_Printf('                                     '#13, []);

  // precache status bar pics
  Com_Printf('pics'#13, []);
  SCR_UpdateScreen;
  SCR_TouchPics;
  Com_Printf('                                     '#13, []);

  CL_RegisterTEntModels;

  num_cl_weaponmodels := 1;
  strcpy(cl_weaponmodels[0], 'weapon.md2');

  i := 1;
  while (i < MAX_MODELS) and (cl.configstrings[CS_MODELS + i][0] <> #0) do
  begin
    strcpy(name, cl.configstrings[CS_MODELS + i]);
    name[37] := #0;                     // never go beyond one line
    if (name[0] <> '*') then
      Com_Printf('%s'#13, [name]);
    SCR_UpdateScreen;
    Sys_SendKeyEvents;                  // pump message loop

    if (name[0] = '#') then
    begin
      // special player weapon model
      if (num_cl_weaponmodels < MAX_CLIENTWEAPONMODELS) then
      begin
        strncpy(cl_weaponmodels[num_cl_weaponmodels], cl.configstrings[CS_MODELS + i] + 1,
          sizeof(cl_weaponmodels[num_cl_weaponmodels]) - 1);
        inc(num_cl_weaponmodels);
      end;
    end
    else
    begin
      cl.model_draw[i] := re.RegisterModel(cl.configstrings[CS_MODELS + i]);
      if (name[0] = '*') then
        cl.model_clip[i] := CM_InlineModel(cl.configstrings[CS_MODELS + i])
      else
        cl.model_clip[i] := nil;
    end;

    if (name[0] <> '*') then
      Com_Printf('                                     '#13, []);
    Inc(i);
  end;

  Com_Printf('images'#13, []);
  SCR_UpdateScreen;

  i := 1;
  while (i < MAX_IMAGES) and (cl.configstrings[CS_IMAGES + i][0] <> #0) do
  begin
    cl.image_precache[i] := re.RegisterPic(cl.configstrings[CS_IMAGES + i]);
    Sys_SendKeyEvents;                  // pump message loop
    inc(i);
  end;

  Com_Printf('                                     '#13, []);

  i := 0;
  while i < MAX_CLIENTS do
  begin
    if (cl.configstrings[CS_PLAYERSKINS + i][0] = #0) then
    begin
      Inc(i);
      Continue;
    end;
    Com_Printf('client %i'#13, [i]);
    SCR_UpdateScreen;
    Sys_SendKeyEvents;                  // pump message loop
    CL_ParseClientinfo(i);
    Com_Printf('                                     '#13, []);
    Inc(i);
  end;

  CL_LoadClientinfo(@cl.baseclientinfo, 'unnamed\male/grunt');
  // set sky textures and speed
  Com_Printf('sky'#13, []);
  SCR_UpdateScreen;
  rotate := atof(cl.configstrings[CS_SKYROTATE]);

  sscanf(cl.configstrings[CS_SKYAXIS], '%f %f %f', [@axis[0], @axis[1], @axis[2]]);

  re.SetSky(cl.configstrings[CS_SKY], rotate, @axis);
  Com_Printf('                                     '#13, []);

  // the renderer can now free unneeded stuff
  re.EndRegistration;

  // clear any lines of console text
  Con_ClearNotify;

  SCR_UpdateScreen();
  cl.refresh_prepped := true;
  cl.force_refdef := true;              // make sure we have a valid refdef

  // start the cd track
  CDAudio_Play(atoi(cl.configstrings[CS_CDTRACK]), true);

end;

{
====================
CalcFov
====================
}

function CalcFov(fov_x, width, height: Single): Single;
var
  a, x: Single;
begin

  if (fov_x < 1) or (fov_x > 179) then
    Com_Error(ERR_DROP, 'Bad fov: %f', [fov_x]);

  x := width / tan(fov_x / 360 * M_PI);

  a := arctan(height / x);

  a := a * 360 / M_PI;

  result := a;

end;

//============================================================================

// gun frame debugging functions

procedure V_Gun_Next_f; cdecl;
begin
  inc(gun_frame);
  Com_Printf('frame %d'#10, [gun_frame]);
end;

procedure V_Gun_Prev_f; cdecl;
begin
  dec(gun_frame);
  if (gun_frame < 0) then
    gun_frame := 0;
  Com_Printf('frame %d'#10, [gun_frame]);
end;

procedure V_Gun_Model_f; cdecl;
var
  name: array[0..MAX_QPATH - 1] of char;
begin
  if (Cmd_Argc <> 2) then
  begin
    gun_model := nil;
    exit;
  end;
  Com_sprintf(name, sizeof(name), 'models/%s/tris.md2', [Cmd_Argv(1)]);
  gun_model := re.RegisterModel(name);
end;

//============================================================================

{
=================
SCR_DrawCrosshair
=================
}

procedure SCR_DrawCrosshair;
begin
  if (crosshair^.value = 0) then
    exit;

  if crosshair^.modified then
  begin
    crosshair^.modified := false;
    SCR_TouchPics;
  end;

  if (crosshair_pic[0] = #0) then
    exit;                               //TER: same as above , first check value (0 = false, !0 = true)

  re.DrawPic(scr_vrect.x + ((scr_vrect.width - crosshair_width) shr 1),
    scr_vrect.y + ((scr_vrect.height - crosshair_height) shr 1), crosshair_pic);

end;

{
==================
V_RenderView

==================
}

procedure V_RenderView(stereo_separation: single);
var
  tmp: vec3_t;
begin
  if (cls.state <> ca_active) then
    exit;

  if (not cl.refresh_prepped) then
    exit;                               // still loading

  if (cl_timedemo^.value <> 0) then
  begin
    if (cl.timedemo_start = 0) then
      cl.timedemo_start := Sys_Milliseconds();
    Inc(cl.timedemo_frames);
  end;

  // an invalid frame will just use the exact previous refdef
  // we can't use the old frame if the video mode has changed, though...
  if (cl.frame.valid and (cl.force_refdef or (cl_paused.value = 0))) then
  begin
    cl.force_refdef := false;

    V_ClearScene();

    // build a refresh entity list and calc cl.sim*
    // this also calls CL_CalcViewValues which loads
    // v_forward, etc.
    CL_AddEntities();

    if (cl_testparticles.value <> 0) then
      V_TestParticles();
    if (cl_testentities.value <> 0) then
      V_TestEntities();
    if (cl_testlights.value <> 0) then
      V_TestLights();
    if (cl_testblend.value <> 0) then
    begin
      cl.refdef.blend[0] := 1;
      cl.refdef.blend[1] := 0.5;
      cl.refdef.blend[2] := 0.25;
      cl.refdef.blend[3] := 0.5;
    end;

    // offset vieworg appropriately if we're doing stereo separation
    if (stereo_separation <> 0) then
    begin
      VectorScale(cl.v_right, stereo_separation, tmp);
      VectorAdd(vec3_t(cl.refdef.vieworg), tmp, vec3_t(cl.refdef.vieworg));
    end;

    // never let it sit exactly on a node line, because a water plane can
    // dissapear when viewed with the eye exactly on it.
    // the server protocol only specifies to 1/8 pixel, so add 1/16 in each axis
    cl.refdef.vieworg[0] := cl.refdef.vieworg[0] + 1.0 / 16;
    cl.refdef.vieworg[1] := cl.refdef.vieworg[1] + 1.0 / 16;
    cl.refdef.vieworg[2] := cl.refdef.vieworg[2] + 1.0 / 16;

    cl.refdef.x := scr_vrect.x;
    cl.refdef.y := scr_vrect.y;
    cl.refdef.width := scr_vrect.width;
    cl.refdef.height := scr_vrect.height;
    cl.refdef.fov_y := CalcFov(cl.refdef.fov_x, cl.refdef.width, cl.refdef.height);
    cl.refdef.time := cl.time * 0.001;

    cl.refdef.areabits := @cl.frame.areabits[0];

    if (cl_add_entities^.value = 0) then
      r_numentities := 0;
    if (cl_add_particles^.value = 0) then
      r_numparticles := 0;
    if (cl_add_lights^.value = 0) then
      r_numdlights := 0;
    if (cl_add_blend^.value = 0) then
    begin
      VectorClear(vec3_p(@cl.refdef.blend)^);
    end;

    cl.refdef.num_entities := r_numentities;
    cl.refdef.entities := @r_entities;
    cl.refdef.num_particles := r_numparticles;
    cl.refdef.particles := @r_particles;
    cl.refdef.num_dlights := r_numdlights;
    cl.refdef.dlights := @r_dlights;
    cl.refdef.lightstyles := @r_lightstyles;

    cl.refdef.rdflags := cl.frame.playerstate.rdflags;

    // sort entities for better cache locality
    qsort(cl.refdef.entities, cl.refdef.num_entities, sizeof(cl.refdef.entities^), @entitycmpfnc);
  end;

  re.RenderFrame(@cl.refdef);
  if (cl_stats.value <> 0) then
    Com_Printf('ent:%d  lt:%d  part:%d'#10, [r_numentities, r_numdlights, r_numparticles]);
  if (log_stats.value <> 0) and (log_stats_file <> 0) then
    Write(log_stats_file,
      format('%d,%d,%d,', [r_numentities, r_numdlights, r_numparticles]));

  SCR_AddDirtyPoint(scr_vrect.x, scr_vrect.y);
  SCR_AddDirtyPoint(scr_vrect.x + scr_vrect.width - 1,
    scr_vrect.y + scr_vrect.height - 1);

  SCR_DrawCrosshair();
end;

{
=============
V_Viewpos_f
=============
}

procedure V_Viewpos_f; cdecl;
begin
  Com_Printf('(%d %d %d) : %d'#10, [cl.refdef.vieworg[0],
    cl.refdef.vieworg[1], cl.refdef.vieworg[2],
      cl.refdef.viewangles[YAW]]);
end;

{
=============
V_Init
=============
}

procedure V_Init;
begin

  Cmd_AddCommand('gun_next', V_Gun_Next_f);
  Cmd_AddCommand('gun_prev', V_Gun_Prev_f);
  Cmd_AddCommand('gun_model', V_Gun_Model_f);

  Cmd_AddCommand('viewpos', V_Viewpos_f);

  crosshair := Cvar_Get('crosshair', '0', CVAR_ARCHIVE);

  cl_testblend := Cvar_Get('cl_testblend', '0', 0);
  cl_testparticles := Cvar_Get('cl_testparticles', '0', 0);
  cl_testentities := Cvar_Get('cl_testentities', '0', 0);
  cl_testlights := Cvar_Get('cl_testlights', '0', 0);

  cl_stats := Cvar_Get('cl_stats', '0', 0);

end;

end.
