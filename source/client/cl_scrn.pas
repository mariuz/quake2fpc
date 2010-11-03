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
{$ALIGN ON}{$MINENUMSIZE 4}
{----------------------------------------------------------------------------}
{                                                                            }
{ File(s): client\cl_scrn.c                                                    }
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
{ Updated on : 04-jun-2002                                                   }
{ Updated by : Juha Hartikainen (juha@linearteam.org)                        }
{ - moved some variables to interface section                                }
{                                                                            }
{ Updated on : 09-jun-2002                                                   }
{ Updated by : Juha Hartikainen (juha@linearteam.org)                        }
{ - Finished conversion                                                      }
{                                                                            }
{----------------------------------------------------------------------------}
// cl_scrn.c -- master for refresh, status bar, console, chat, notify, etc

(*

  full screen console
  put up loading plaque
  blanked background with loading plaque
  blanked background with menu
  cinematics
  full screen image for quit and victory

  end of unit intermissions

*)

unit cl_scrn;

interface

uses
  Client,
  CPas,
  ref,
  vid_h,
  q_shared;

procedure SCR_Init;
procedure SCR_TimeRefresh_f; cdecl;
procedure SCR_Loading_f; cdecl;
procedure SCR_DebugGraph(value: single; color: Integer); cdecl;
procedure SCR_AddDirtyPoint(x, y: Integer);
procedure SCR_DirtyScreen;
procedure SCR_UpdateScreen;
procedure SCR_BeginLoadingPlaque;
procedure SCR_EndLoadingPlaque;
procedure SCR_TouchPics;
procedure SCR_RunConsole;
procedure SCR_CenterPrint(str: pchar);
procedure CL_AddNetgraph;

function entitycmpfnc(const a, b: entity_p): integer;

var
  scr_con_current: single;              // aproaches scr_conlines at scr_conspeed
  scr_conlines: single;                 // 0.0 to 1.0 lines of console to display

  scr_initialized: qboolean;            // ready to draw

  scr_draw_loading: integer;

  scr_vrect: vrect_t;                   // position of render window on screen

  scr_viewsize,
    scr_conspeed,
    scr_centertime,
    scr_showturtle,
    scr_showpause,
    scr_printspeed,

  scr_netgraph,
    scr_timegraph,
    scr_debuggraph_,
    scr_graphheight,
    scr_graphscale,
    scr_graphshift,
    scr_drawall: cvar_p;

  crosshair_pic: array[0..MAX_QPATH - 1] of char;
  crosshair_width, crosshair_height: Integer;

implementation

uses
  SysUtils,
  Cmd,
  Common,
  Console,
  CVar,
  cl_cin,
  cl_inv,
  {$IFDEF WIN32}
  cd_win,
  q_shwin,
  vid_dll,
  {$ELSE}
  cd_sdl,
  q_shlinux,
  vid_so,
  {$ENDIF}
  snd_dma,
  cl_main,
  cl_view,
  menu;

type
  dirty_t = record
    x1, y1, x2, y2: Integer;
  end;

var
  scr_dirty: dirty_t;
  scr_old_dirty: array[0..1] of dirty_t;

  (*
  ===============================================================================

  BAR GRAPHS

  ===============================================================================
  *)

  (*
  ==============
  CL_AddNetgraph

  A new packet was just parsed
  ==============
  *)

procedure CL_AddNetgraph;
var
  i: Integer;
  in_: integer;
  ping: integer;
begin
  // if using the debuggraph for something else, don't
  // add the net lines
  if (scr_debuggraph_.value <> 0) or (scr_timegraph.value <> 0) then
    exit;

  for i := 0 to cls.netchan.dropped - 1 do
    SCR_DebugGraph(30, $40);

  for i := 0 to cl.surpressCount - 1 do
    SCR_DebugGraph(30, $DF);

  // see what the latency was on this packet
  in_ := cls.netchan.incoming_acknowledged and (CMD_BACKUP - 1);
  ping := cls.realtime - cl.cmd_time[in_];
  ping := round(ping / 30);
  if (ping > 30) then
    ping := 30;
  SCR_DebugGraph(ping, $D0);
end;

type
  graphsamp_t = packed record
    value: single;
    color: integer;
  end;

var
  current: integer;
  values: array[0..1024 - 1] of graphsamp_t;

  (*
  ==============
  SCR_DebugGraph
  ==============
  *)

procedure SCR_DebugGraph(value: single; color: Integer);
begin
  values[current and 1023].value := value;
  values[current and 1023].color := color;
  Inc(current);
end;

(*
==============
SCR_DrawDebugGraph
==============
*)

procedure SCR_DrawDebugGraph;
var
  a, x, y, w, i, h: integer;
  v: single;
  color: integer;
begin
  //
  // draw the graph
  //
  w := scr_vrect.width;

  x := scr_vrect.x;
  y := scr_vrect.y + scr_vrect.height;
  re.DrawFill(x, round(y - scr_graphheight.value),
    w, round(scr_graphheight.value), 8);

  for a := 0 to w - 1 do
  begin
    i := (current - 1 - a + 1024) and 1023;
    v := values[i].value;
    color := values[i].color;
    v := v * scr_graphscale.value + scr_graphshift.value;

    if (v < 0) then
      v := v + scr_graphheight.value * (1 + round(-v / scr_graphheight.value));
    h := Round(v) mod round(scr_graphheight.value);
    re.DrawFill(x + w - 1 - a, y - h, 1, h, color);
  end;
end;

(*
===============================================================================

CENTER PRINTING

===============================================================================
*)

var
  scr_centerstring: array[0..1024 - 1] of char;
  scr_centertime_start: single;         // for slow victory printing
  scr_centertime_off: single;
  scr_center_lines: integer;
  scr_erase_center: integer;

  (*
  ==============
  SCR_CenterPrint

  Called for important messages that should stay in the center of the screen
  for a few moments
  ==============
  *)

procedure SCR_CenterPrint(str: pchar);
var
  s: pchar;
  line: array[0..64 - 1] of char;
  i, j, l: integer;
begin
  strncpy(scr_centerstring, str, sizeof(scr_centerstring) - 1);
  scr_centertime_off := scr_centertime.value;
  scr_centertime_start := cl.time;

  // count the number of lines for centering
  scr_center_lines := 1;
  s := str;
  while (s^ <> #0) do
  begin
    if (s^ = #10) then
      Inc(scr_center_lines);
    Inc(s);
  end;

  // echo it to the console
  Com_Printf(#10#10#29#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#31#10#10, []);

  s := str;
  repeat
    // scan the width of the line
    l := 0;
    while (l < 40) do
    begin
      if (s[l] = #10) or (s[l] = #0) then
        Break;
      Inc(l);
    end;
    i := 0;
    while (i < (40 - l) div 2) do
    begin
      line[i] := ' ';
      Inc(i);
    end;

    for j := 0 to l - 1 do
    begin
      line[i] := s[j];
      Inc(i);
    end;

    line[i] := #10;
    line[i + 1] := #0;

    Com_Printf('%s', [line]);

    while (s^ <> #0) and (s^ <> #10) do
      Inc(s);

    if (s^ = #0) then
      break;
    Inc(s);                             // skip the \n
  until false;
  Com_Printf(#10#10#29#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#31#10#10, []);
  Con_ClearNotify();
end;

procedure SCR_DrawCenterString;
var
  start: pchar;
  l: integer;
  j: integer;
  x, y: integer;
  remaining: integer;
begin
  // the finale prints the characters one at a time
  remaining := 9999;

  scr_erase_center := 0;
  start := scr_centerstring;

  if (scr_center_lines <= 4) then
    y := Round(viddef.height * 0.35)
  else
    y := 48;

  while true do
  begin
    // scan the width of the line
    for l := 0 to 40 - 1 do
      if (start[l] = #10) or (start[l] = #0) then
        break;
    x := Round((viddef.width - l * 8) / 2);
    SCR_AddDirtyPoint(x, y);
    j := 0;
    while (j < l) do
    begin
      re.DrawChar(x, y, Byte(start[j]));
      Dec(remaining);
      if (remaining = 0) then
        exit;

      x := x + 8;
      Inc(j);
    end;
    SCR_AddDirtyPoint(x, y + 8);

    y := y + 8;

    while (start^ <> #0) and (start^ <> #10) do
      Inc(start);

    if (start^ = #0) then
      break;
    Inc(start);                         // skip the \n
  end;
end;

procedure SCR_CheckDrawCenterString;
begin
  scr_centertime_off := scr_centertime_off - cls.frametime;

  if (scr_centertime_off <= 0) then
    exit;

  SCR_DrawCenterString();
end;

//=============================================================================

(*
=================
SCR_CalcVrect

Sets scr_vrect, the coordinates of the rendered window
=================
*)

procedure SCR_CalcVrect;
var
  size: integer;
begin
  // bound viewsize
  if (scr_viewsize.value < 40) then
    Cvar_Set('viewsize', '40');
  if (scr_viewsize.value > 100) then
    Cvar_Set('viewsize', '100');

  size := Round(scr_viewsize.value);

  scr_vrect.width := Round(viddef.width * size / 100);
  scr_vrect.width := scr_vrect.width and (not 7);

  scr_vrect.height := Round(viddef.height * size / 100);
  scr_vrect.height := scr_vrect.height and (not 1);

  scr_vrect.x := Round((viddef.width - scr_vrect.width) / 2);
  scr_vrect.y := Round((viddef.height - scr_vrect.height) / 2);
end;

(*
=================
SCR_SizeUp_f

Keybinding command
=================
*)

procedure SCR_SizeUp_f; cdecl;
begin
  Cvar_SetValue('viewsize', scr_viewsize.value + 10);
end;

(*
=================
SCR_SizeDown_f

Keybinding command
=================
*)

procedure SCR_SizeDown_f; cdecl;
begin
  Cvar_SetValue('viewsize', scr_viewsize.value - 10);
end;

(*
=================
SCR_Sky_f

Set a specific sky and rotation speed
=================
*)

procedure SCR_Sky_f; cdecl;
var
  rotate: single;
  axis: vec3_t;
begin
  if (Cmd_Argc() < 2) then
  begin
    Com_Printf('Usage: sky <basename> <rotate> <axis x y z>'#10, []);
    exit;
  end;
  if (Cmd_Argc() > 2) then
    rotate := StrToFloat(Cmd_Argv(2))
  else
    rotate := 0;
  if (Cmd_Argc() = 6) then
  begin
    axis[0] := StrToFloat(Cmd_Argv(3));
    axis[1] := StrToFloat(Cmd_Argv(4));
    axis[2] := StrToFloat(Cmd_Argv(5));
  end
  else
  begin
    axis[0] := 0;
    axis[1] := 0;
    axis[2] := 1;
  end;

  re.SetSky(Cmd_Argv(1), rotate, @axis);
end;

//============================================================================

(*
==================
SCR_Init
==================
*)

procedure SCR_Init;
begin
  scr_viewsize := Cvar_Get('viewsize', '100', CVAR_ARCHIVE);
  scr_conspeed := Cvar_Get('scr_conspeed', '3', 0);
  scr_showturtle := Cvar_Get('scr_showturtle', '0', 0);
  scr_showpause := Cvar_Get('scr_showpause', '1', 0);
  scr_centertime := Cvar_Get('scr_centertime', '2.5', 0);
  scr_printspeed := Cvar_Get('scr_printspeed', '8', 0);
  scr_netgraph := Cvar_Get('netgraph', '0', 0);
  scr_timegraph := Cvar_Get('timegraph', '0', 0);
  scr_debuggraph_ := Cvar_Get('debuggraph', '0', 0);
  scr_graphheight := Cvar_Get('graphheight', '32', 0);
  scr_graphscale := Cvar_Get('graphscale', '1', 0);
  scr_graphshift := Cvar_Get('graphshift', '0', 0);
  scr_drawall := Cvar_Get('scr_drawall', '0', 0);

  //
  // register our commands
  //
  Cmd_AddCommand('timerefresh', SCR_TimeRefresh_f);
  Cmd_AddCommand('loading', SCR_Loading_f);
  Cmd_AddCommand('sizeup', SCR_SizeUp_f);
  Cmd_AddCommand('sizedown', SCR_SizeDown_f);
  Cmd_AddCommand('sky', SCR_Sky_f);

  scr_initialized := true;
end;

(*
==============
SCR_DrawNet
==============
*)

procedure SCR_DrawNet;
begin
  if (cls.netchan.outgoing_sequence - cls.netchan.incoming_acknowledged < CMD_BACKUP - 1) then
    exit;

  re.DrawPic(scr_vrect.x + 64, scr_vrect.y, 'net');
end;

(*
==============
SCR_DrawPause
==============
*)

procedure SCR_DrawPause;
var
  w, h: integer;
begin
  if (scr_showpause.value = 0) then     // turn off for screenshots
    exit;

  if (cl_paused.value = 0) then
    exit;

  re.DrawGetPicSize(@w, @h, 'pause');
  re.DrawPic((viddef.width - w) div 2, viddef.height div 2 + 8, 'pause');
end;

(*
==============
SCR_DrawLoading
==============
*)

procedure SCR_DrawLoading;
var
  w, h: integer;
begin
  if (scr_draw_loading = 0) then
    exit;

  scr_draw_loading := Integer(False);
  re.DrawGetPicSize(@w, @h, 'loading');
  re.DrawPic((viddef.width - w) div 2, (viddef.height - h) div 2, 'loading');
end;

//=============================================================================

(*
==================
SCR_RunConsole

Scroll it up or down
==================
*)

procedure SCR_RunConsole;
begin
  // decide on the height of the console
  if (cls.key_dest = key_console) then
    scr_conlines := 0.5                 // half screen
  else
    scr_conlines := 0;                  // none visible

  if (scr_conlines < scr_con_current) then
  begin
    scr_con_current := scr_con_current - scr_conspeed.value * cls.frametime;
    if (scr_conlines > scr_con_current) then
      scr_con_current := scr_conlines;
  end
  else if (scr_conlines > scr_con_current) then
  begin
    scr_con_current := scr_con_current + scr_conspeed.value * cls.frametime;
    if (scr_conlines < scr_con_current) then
      scr_con_current := scr_conlines;
  end;
end;

(*
==================
SCR_DrawConsole
==================
*)

procedure SCR_DrawConsole;
begin
  Con_CheckResize();

  if (cls.state = ca_disconnected) or (cls.state = ca_connecting) then
  begin
    // forced full screen console
    Con_DrawConsole(1);
    exit;
  end;

  if (cls.state <> ca_active) or (not cl.refresh_prepped) then
  begin
    // connected, but can't render
    Con_DrawConsole(0.5);
    re.DrawFill(0, viddef.height div 2, viddef.width, viddef.height div 2, 0);
    exit;
  end;

  if (scr_con_current <> 0) then
  begin
    Con_DrawConsole(scr_con_current);
  end
  else
  begin
    if (cls.key_dest = key_game) or (cls.key_dest = key_message) then
      Con_DrawNotify();                 // only draw notify in game
  end;
end;

//=============================================================================

(*
================
SCR_BeginLoadingPlaque
================
*)

procedure SCR_BeginLoadingPlaque;
begin
  S_StopAllSounds();
  cl.sound_prepped := false;            // don't play ambients
  CDAudio_Stop();
  if (cls.disable_screen <> 0) then
    exit;
  if (developer.value <> 0) then
    exit;
  if (cls.state = ca_disconnected) then
    exit;                               // if at console, don't bring up the plaque
  if (cls.key_dest = key_console) then
    exit;
  if (cl.cinematictime > 0) then
    scr_draw_loading := 2               // clear to balack first
  else
    scr_draw_loading := 1;
  SCR_UpdateScreen();
  cls.disable_screen := Sys_Milliseconds();
  cls.disable_servercount := cl.servercount;
end;

(*
================
SCR_EndLoadingPlaque
================
*)

procedure SCR_EndLoadingPlaque;
begin
  cls.disable_screen := 0;
  Con_ClearNotify();
end;

(*
================
SCR_Loading_f
================
*)

procedure SCR_Loading_f;
begin
  SCR_BeginLoadingPlaque();
end;

(*
================
SCR_TimeRefresh_f
================
*)

function entitycmpfnc(const a, b: entity_p): integer;
begin
  (*
  ** all other models are sorted by model then skin
  *)
  if (a.model = b.model) then
  begin
    Result := Cardinal(a.skin) - Cardinal(b.skin);
  end
  else
  begin
    Result := Cardinal(a.model) - Cardinal(b.model);
  end;
end;

procedure SCR_TimeRefresh_f;
var
  i: Integer;
  start, stop: integer;
  time: single;
begin
  if (cls.state <> ca_active) then
    exit;

  start := Sys_Milliseconds();

  if (Cmd_Argc() = 2) then
  begin
    // run without page flipping
    re.BeginFrame(0);
    for i := 0 to 128 - 1 do
    begin
      cl.refdef.viewangles[1] := i / 128.0 * 360.0;
      re.RenderFrame(@cl.refdef);
    end;
    re.EndFrame();
  end
  else
  begin
    for i := 0 to 128 - 1 do
    begin
      cl.refdef.viewangles[1] := i / 128.0 * 360.0;

      re.BeginFrame(0);
      re.RenderFrame(@cl.refdef);
      re.EndFrame();
    end;
  end;

  stop := Sys_Milliseconds();
  time := (stop - start) / 1000.0;
  Com_Printf('%f seconds (%f fps)'#10, [time, 128 / time]);
end;

(*
=================
SCR_AddDirtyPoint
=================
*)

procedure SCR_AddDirtyPoint(x, y: integer);
begin
  if (x < scr_dirty.x1) then
    scr_dirty.x1 := x;
  if (x > scr_dirty.x2) then
    scr_dirty.x2 := x;
  if (y < scr_dirty.y1) then
    scr_dirty.y1 := y;
  if (y > scr_dirty.y2) then
    scr_dirty.y2 := y;
end;

procedure SCR_DirtyScreen;
begin
  SCR_AddDirtyPoint(0, 0);
  SCR_AddDirtyPoint(viddef.width - 1, viddef.height - 1);
end;

(*
==============
SCR_TileClear

Clear any parts of the tiled background that were drawn on last frame
==============
*)

procedure SCR_TileClear;
var
  i: integer;
  top, bottom, left, right: integer;
  clear: dirty_t;
begin
  if (scr_drawall.value <> 0) then
    SCR_DirtyScreen();                  // for power vr or broken page flippers...

  if (scr_con_current = 1.0) then
    exit;                               // full screen console
  if (scr_viewsize.value = 100) then
    exit;                               // full screen rendering
  if (cl.cinematictime > 0) then
    exit;                               // full screen cinematic

  // erase rect will be the union of the past three frames
  // so tripple buffering works properly
  clear := scr_dirty;
  for i := 0 to 1 do
  begin
    if (scr_old_dirty[i].x1 < clear.x1) then
      clear.x1 := scr_old_dirty[i].x1;
    if (scr_old_dirty[i].x2 > clear.x2) then
      clear.x2 := scr_old_dirty[i].x2;
    if (scr_old_dirty[i].y1 < clear.y1) then
      clear.y1 := scr_old_dirty[i].y1;
    if (scr_old_dirty[i].y2 > clear.y2) then
      clear.y2 := scr_old_dirty[i].y2;
  end;

  scr_old_dirty[1] := scr_old_dirty[0];
  scr_old_dirty[0] := scr_dirty;

  scr_dirty.x1 := 9999;
  scr_dirty.x2 := -9999;
  scr_dirty.y1 := 9999;
  scr_dirty.y2 := -9999;

  // don't bother with anything convered by the console)
  top := Round(scr_con_current * viddef.height);
  if (top >= clear.y1) then
    clear.y1 := top;

  if (clear.y2 <= clear.y1) then
    exit;                               // nothing disturbed

  top := scr_vrect.y;
  bottom := top + scr_vrect.height - 1;
  left := scr_vrect.x;
  right := left + scr_vrect.width - 1;

  if (clear.y1 < top) then
  begin
    // clear above view screen
    if (clear.y2 < top - 1) then
      i := clear.y2
    else
      i := top - 1;
    re.DrawTileClear(clear.x1, clear.y1,
      clear.x2 - clear.x1 + 1, i - clear.y1 + 1, 'backtile');
    clear.y1 := top;
  end;
  if (clear.y2 > bottom) then
  begin
    // clear below view screen
    if (clear.y1 > bottom + 1) then
      i := clear.y1
    else
      i := bottom + 1;
    re.DrawTileClear(clear.x1, i,
      clear.x2 - clear.x1 + 1, clear.y2 - i + 1, 'backtile');
    clear.y2 := bottom;
  end;
  if (clear.x1 < left) then
  begin
    // clear left of view screen
    if (clear.x2 < left - 1) then
      i := clear.x2
    else
      i := left - 1;
    re.DrawTileClear(clear.x1, clear.y1,
      i - clear.x1 + 1, clear.y2 - clear.y1 + 1, 'backtile');
    clear.x1 := left;
  end;
  if (clear.x2 > right) then
  begin
    // clear left of view screen
    if (clear.x1 > right + 1) then
      i := clear.x1
    else
      i := right + 1;
    re.DrawTileClear(i, clear.y1,
      clear.x2 - i + 1, clear.y2 - clear.y1 + 1, 'backtile');
    clear.x2 := right;
  end;
end;

//===============================================================

const
  STAT_MINUS = 10;                      // num frame for '-' stats digit

var
  sb_nums: array[0..1, 0..10] of pchar =
  (
    ('num_0', 'num_1', 'num_2', 'num_3', 'num_4', 'num_5',
    'num_6', 'num_7', 'num_8', 'num_9', 'num_minus'),
    ('anum_0', 'anum_1', 'anum_2', 'anum_3', 'anum_4', 'anum_5',
    'anum_6', 'anum_7', 'anum_8', 'anum_9', 'anum_minus')
    );

const
  ICON_WIDTH = 24;
  ICON_HEIGHT = 24;
  CHAR_WIDTH = 16;
  ICON_SPACE = 8;

  (*
  ================
  SizeHUDString

  Allow embedded \n(#10) in the string
  ================
  *)

procedure SizeHUDString(string_: pchar; w, h: pinteger);
var
  lines, width, current: integer;
begin
  lines := 1;
  width := 0;

  current := 0;
  while (string_^ <> #0) do
  begin
    if (string_^ = #10) then
    begin
      Inc(Lines);
      current := 0;
    end
    else
    begin
      Inc(current);
      if (current > width) then
        width := current;
    end;
    Inc(string_);
  end;

  w^ := width * 8;
  h^ := lines * 8;
end;

procedure DrawHUDString(string_: pchar; x, y, centerwidth, xor_: integer);
var
  margin: integer;
  line: array[0..1024 - 1] of char;
  width: integer;
  i: integer;
begin
  margin := x;

  while (string_^ <> #0) do
  begin
    // scan out one line of text from the string
    width := 0;
    while (string_^ <> #0) and (string_^ <> #10) do
    begin
      line[width] := string_^;
      Inc(string_);
      Inc(width);
    end;
    line[width] := #0;

    if (centerwidth <> 0) then
      x := margin + (centerwidth - width * 8) div 2
    else
      x := margin;
    for i := 0 to width - 1 do
    begin
      re.DrawChar(x, y, byte(line[i]) xor xor_);
      x := x + 8;
    end;
    if (string_^ <> #0) then
    begin
      Inc(string_);                     // skip the \n
      x := margin;
      y := y + 8;
    end;
  end;
end;

(*
==============
SCR_DrawField
==============
*)

procedure SCR_DrawField(x, y, color, width, value: integer);
var
  num: array[0..16 - 1] of char;
  ptr: pchar;
  l: integer;
  frame: integer;
begin
  if (width < 1) then
    exit;

  // draw number string
  if (width > 5) then
    width := 5;

  SCR_AddDirtyPoint(x, y);
  SCR_AddDirtyPoint(x + width * CHAR_WIDTH + 2, y + 23);

  Com_sprintf(num, sizeof(num), '%d', [value]);
  l := strlen(num);
  if (l > width) then
    l := width;
  x := x + 2 + CHAR_WIDTH * (width - l);

  ptr := num;
  while (ptr^ <> #0) and (l <> 0) do
  begin
    if (ptr^ = '-') then
      frame := STAT_MINUS
    else
      frame := Byte(ptr^) - Byte('0');

    re.DrawPic(x, y, sb_nums[color][frame]);
    x := x + CHAR_WIDTH;
    Inc(Ptr);
    Dec(l);
  end;
end;

(*
===============
SCR_TouchPics

Allows rendering code to cache all needed sbar graphics
===============
*)

procedure SCR_TouchPics;
var
  i, j: integer;
begin
  for i := 0 to 1 do
    for j := 0 to 10 do
      re.RegisterPic(sb_nums[i][j]);

  if (crosshair.value <> 0) then
  begin
    if (crosshair.value > 3) or (crosshair.value < 0) then
      crosshair.value := 3;

    Com_sprintf(crosshair_pic, sizeof(crosshair_pic), 'ch%d', [Round(crosshair.value)]);
    re.DrawGetPicSize(@crosshair_width, @crosshair_height, crosshair_pic);
    if (crosshair_width = 0) then
      crosshair_pic[0] := #0;
  end;
end;

(*
================
SCR_ExecuteLayoutString

================
*)

procedure SCR_ExecuteLayoutString(s: pchar);
var
  x, y: integer;
  value: integer;
  token: pchar;
  width: integer;
  index: integer;
  ci: clientinfo_p;
  score, ping, time: integer;
  block: array[0..80 - 1] of char;
  color: integer;
  tmps: string;
begin
  if (cls.state <> ca_active) or (not cl.refresh_prepped) then
    exit;

  if (s^ = #0) then
    exit;

  x := 0;
  y := 0;
  width := 3;

  while (s <> nil) do
  begin
    token := COM_Parse(s);
    if (strcmp(token, 'xl') = 0) then
    begin
      token := COM_Parse(s);
      x := StrToInt(token);
      continue;
    end;
    if (strcmp(token, 'xr') = 0) then
    begin
      token := COM_Parse(s);
      x := viddef.width + StrToInt(token);
      continue;
    end;
    if (strcmp(token, 'xv') = 0) then
    begin
      token := COM_Parse(s);
      x := viddef.width div 2 - 160 + StrToInt(token);
      continue;
    end;
    if (strcmp(token, 'yt') = 0) then
    begin
      token := COM_Parse(s);
      y := StrToInt(token);
      continue;
    end;
    if (strcmp(token, 'yb') = 0) then
    begin
      token := COM_Parse(s);
      y := viddef.height + StrToInt(token);
      continue;
    end;
    if (strcmp(token, 'yv') = 0) then
    begin
      token := COM_Parse(s);
      y := viddef.height div 2 - 120 + StrToInt(token);
      continue;
    end;

    if (strcmp(token, 'pic') = 0) then
    begin
      // draw a pic from a stat number
      token := COM_Parse(s);
      value := cl.frame.playerstate.stats[StrToInt(token)];
      if (value >= MAX_IMAGES) then
        Com_Error(ERR_DROP, 'Pic >= MAX_IMAGES', []);
      if (cl.configstrings[CS_IMAGES + value] <> nil) then
      begin
        SCR_AddDirtyPoint(x, y);
        SCR_AddDirtyPoint(x + 23, y + 23);
        re.DrawPic(x, y, cl.configstrings[CS_IMAGES + value]);
      end;
      continue;
    end;

    if (strcmp(token, 'client') = 0) then
    begin
      // draw a deathmatch client block

      token := COM_Parse(s);
      x := viddef.width div 2 - 160 + StrToInt(token);
      token := COM_Parse(s);
      y := viddef.height div 2 - 120 + StrToInt(token);
      SCR_AddDirtyPoint(x, y);
      SCR_AddDirtyPoint(x + 159, y + 31);

      token := COM_Parse(s);
      value := StrToInt(token);
      if (value >= MAX_CLIENTS) or (value < 0) then
        Com_Error(ERR_DROP, 'client >= MAX_CLIENTS', []);
      ci := @cl.clientinfo[value];

      token := COM_Parse(s);
      score := StrToInt(token);

      token := COM_Parse(s);
      ping := StrToInt(token);

      token := COM_Parse(s);
      time := StrToInt(token);

      DrawAltString(x + 32, y, ci.name);
      DrawString(x + 32, y + 8, 'Score: ');
      DrawAltString(x + 32 + 7 * 8, y + 8, va('%d', [score]));
      DrawString(x + 32, y + 16, va('Ping:  %d', [ping]));
      DrawString(x + 32, y + 24, va('Time:  %d', [time]));

      if (ci.icon = nil) then
        ci := @cl.baseclientinfo;
      re.DrawPic(x, y, ci.iconname);
      continue;
    end;

    if (strcmp(token, 'ctf') = 0) then
    begin
      // draw a ctf client block
      token := COM_Parse(s);
      x := viddef.width div 2 - 160 + StrToInt(token);
      token := COM_Parse(s);
      y := viddef.height div 2 - 120 + StrToInt(token);
      SCR_AddDirtyPoint(x, y);
      SCR_AddDirtyPoint(x + 159, y + 31);

      token := COM_Parse(s);
      value := StrToInt(token);
      if (value >= MAX_CLIENTS) or (value < 0) then
        Com_Error(ERR_DROP, 'client >= MAX_CLIENTS', []);
      ci := @cl.clientinfo[value];

      token := COM_Parse(s);
      score := StrToInt(token);

      token := COM_Parse(s);
      ping := StrToInt(token);
      if (ping > 999) then
        ping := 999;

      FillChar(block, sizeof(block), 0);
      tmps := PChar(Format('%3d %3d %-12.12s', [score, ping, ci.name]));
      move(tmps[1], block[0], length(tmps));

      if (value = cl.playernum) then
        DrawAltString(x, y, block)
      else
        DrawString(x, y, block);
      continue;
    end;

    if (strcmp(token, 'picn') = 0) then
    begin
      // draw a pic from a name
      token := COM_Parse(s);
      SCR_AddDirtyPoint(x, y);
      SCR_AddDirtyPoint(x + 23, y + 23);
      re.DrawPic(x, y, token);
      continue;
    end;

    if (strcmp(token, 'num') = 0) then
    begin
      // draw a number
      token := COM_Parse(s);
      width := StrToInt(token);
      token := COM_Parse(s);
      value := cl.frame.playerstate.stats[StrToInt(token)];
      SCR_DrawField(x, y, 0, width, value);
      continue;
    end;

    if (strcmp(token, 'hnum') = 0) then
    begin
      // health number

      width := 3;
      value := cl.frame.playerstate.stats[STAT_HEALTH];
      if (value > 25) then
        color := 0                      // green
      else if (value > 0) then
        color := (cl.frame.serverframe shr 2) and 1 // flash
      else
        color := 1;

      if (cl.frame.playerstate.stats[STAT_FLASHES] and 1 <> 0) then
        re.DrawPic(x, y, 'field_3');

      SCR_DrawField(x, y, color, width, value);
      continue;
    end;

    if (strcmp(token, 'anum') = 0) then
    begin
      // ammo number

      width := 3;
      value := cl.frame.playerstate.stats[STAT_AMMO];
      if (value > 5) then
        color := 0                      // green
      else if (value >= 0) then
        color := (cl.frame.serverframe shr 2) and 1 // flash
      else
        continue;                       // negative number = don't show

      if (cl.frame.playerstate.stats[STAT_FLASHES] and 4 > 0) then
        re.DrawPic(x, y, 'field_3');

      SCR_DrawField(x, y, color, width, value);
      continue;
    end;

    if (strcmp(token, 'rnum') = 0) then
    begin
      // armor number

      width := 3;
      value := cl.frame.playerstate.stats[STAT_ARMOR];
      if (value < 1) then
        continue;

      color := 0;                       // green

      if (cl.frame.playerstate.stats[STAT_FLASHES] and 2 > 0) then
        re.DrawPic(x, y, 'field_3');

      SCR_DrawField(x, y, color, width, value);
      continue;
    end;

    if (strcmp(token, 'stat_string') = 0) then
    begin
      token := COM_Parse(s);
      index := StrToInt(token);
      if (index < 0) or (index >= MAX_CONFIGSTRINGS) then
        Com_Error(ERR_DROP, 'Bad stat_string index', []);
      index := cl.frame.playerstate.stats[index];
      if (index < 0) or (index >= MAX_CONFIGSTRINGS) then
        Com_Error(ERR_DROP, 'Bad stat_string index', []);
      DrawString(x, y, cl.configstrings[index]);
      continue;
    end;

    if (strcmp(token, 'cstring') = 0) then
    begin
      token := COM_Parse(s);
      DrawHUDString(token, x, y, 320, 0);
      continue;
    end;

    if (strcmp(token, 'string') = 0) then
    begin
      token := COM_Parse(s);
      DrawString(x, y, token);
      continue;
    end;

    if (strcmp(token, 'cstring2') = 0) then
    begin
      token := COM_Parse(s);
      DrawHUDString(token, x, y, 320, $80);
      continue;
    end;

    if (strcmp(token, 'string2') = 0) then
    begin
      token := COM_Parse(s);
      DrawAltString(x, y, token);
      continue;
    end;

    if (strcmp(token, 'if') = 0) then
    begin
      // draw a number
      token := COM_Parse(s);
      value := cl.frame.playerstate.stats[StrToInt(token)];
      if (value = 0) then
      begin
        // skip to endif
        while (s <> nil) and (strcmp(token, 'endif') <> 0) do
        begin
          token := COM_Parse(s);
        end;
      end;

      continue;
    end;
  end;
end;

(*
================
SCR_DrawStats

The status bar is a small layout program that
is based on the stats array
================
*)

procedure SCR_DrawStats;
begin
  SCR_ExecuteLayoutString(cl.configstrings[CS_STATUSBAR]);
end;

(*
================
SCR_DrawLayout

================
*)
const
  STAT_LAYOUTS = 13;

procedure SCR_DrawLayout;
begin
  if (cl.frame.playerstate.stats[STAT_LAYOUTS] = 0) then
    exit;
  SCR_ExecuteLayoutString(cl.layout);
end;

//=======================================================

(*
==================
SCR_UpdateScreen

This is called every frame, and can also be called explicitly to flush
text to the screen.
==================
*)

procedure SCR_UpdateScreen;
var
  numframes: integer;
  i: integer;
  separation: array[0..1] of single;
  w, h: integer;
begin
  separation[0] := 0;
  separation[1] := 0;
  // if the screen is disabled (loading plaque is up, or vid mode changing)
  // do nothing at all
  if (cls.disable_screen <> 0) then
  begin
    if (Sys_Milliseconds() - cls.disable_screen > 120000) then
    begin
      cls.disable_screen := 0;
      Com_Printf('Loading plaque timed out.'#10, []);
    end;
    exit;
  end;

  if (not scr_initialized) or (not con.initialized) then
    exit;                               // not initialized yet

  (*
  ** range check cl_camera_separation so we don't inadvertently fry someone's
  ** brain
  *)
  if (cl_stereo_separation.value > 1.0) then
    Cvar_SetValue('cl_stereo_separation', 1.0)
  else if (cl_stereo_separation.value < 0) then
    Cvar_SetValue('cl_stereo_separation', 0.0);

  if (cl_stereo.value <> 0) then
  begin
    numframes := 2;
    separation[0] := -cl_stereo_separation.value / 2;
    separation[1] := cl_stereo_separation.value / 2;
  end
  else
  begin
    separation[0] := 0;
    separation[1] := 0;
    numframes := 1;
  end;

  for i := 0 to numframes - 1 do
  begin
    re.BeginFrame(separation[i]);

    if (scr_draw_loading = 2) then
    begin
      //  loading plaque over black screen

      re.CinematicSetPalette(nil);
      scr_draw_loading := Integer(false);
      re.DrawGetPicSize(@w, @h, 'loading');
      re.DrawPic((viddef.width - w) div 2, (viddef.height - h) div 2, 'loading');
      //         re.EndFrame();
      //         exit;
    end
      // if a cinematic is supposed to be running, handle menus
      // and console specially
    else if (cl.cinematictime > 0) then
    begin
      if (cls.key_dest = key_menu) then
      begin
        if (cl.cinematicpalette_active) then
        begin
          re.CinematicSetPalette(nil);
          cl.cinematicpalette_active := false;
        end;
        M_Draw();
        //            re.EndFrame();
        //            exit;
      end
      else if (cls.key_dest = key_console) then
      begin
        if (cl.cinematicpalette_active) then
        begin
          re.CinematicSetPalette(nil);
          cl.cinematicpalette_active := false;
        end;
        SCR_DrawConsole();
        //            re.EndFrame();
        //            exit;
      end
      else
      begin
        SCR_DrawCinematic();
        //            re.EndFrame();
        //            exit;
      end
    end
    else
    begin

      // make sure the game palette is active
      if (cl.cinematicpalette_active) then
      begin
        re.CinematicSetPalette(nil);
        cl.cinematicpalette_active := false;
      end;

      // do 3D refresh drawing, and then update the screen
      SCR_CalcVrect();

      // clear any dirty part of the background
      SCR_TileClear();

      V_RenderView(separation[i]);

      SCR_DrawStats();
      if (cl.frame.playerstate.stats[STAT_LAYOUTS] and 1 > 0) then
        SCR_DrawLayout();
      if (cl.frame.playerstate.stats[STAT_LAYOUTS] and 2 > 0) then
        CL_DrawInventory();

      SCR_DrawNet();
      SCR_CheckDrawCenterString();

      if (scr_timegraph.value <> 0) then
        SCR_DebugGraph(cls.frametime * 300, 0);

      if (scr_debuggraph_.value <> 0) or (scr_timegraph.value <> 0) or
        (scr_netgraph.value <> 0) then
        SCR_DrawDebugGraph();

      SCR_DrawPause();

      SCR_DrawConsole();

      M_Draw();

      SCR_DrawLoading();
    end;
  end;
  re.EndFrame();
end;

end.
