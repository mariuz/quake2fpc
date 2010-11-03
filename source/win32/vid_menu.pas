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
{ File(s): vid_menu.c, client.h, qmenu.h                                     }
{ Content: Quake2\Win32\ support for qhost                                   }
{                                                                            }
{ Initial conversion by : Mani - mani246@yahoo.com                           }
{ Initial conversion on : 14-Mar-2002                                        }
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
{ * Updated 04-jun-2002 Juha Hartikainen (juha@linearteam.org)               }
{ - Language fixes                                                                           }
{}
{ * TODO}
{ - Declare needed functions in interface section }
{----------------------------------------------------------------------------}

unit vid_menu;

interface

// conproc.h -- support for qhost

procedure VID_MenuInit; cdecl;
procedure VID_MenuDraw;
function VID_MenuKey(key: integer): PChar;

implementation

uses
  Windows,
  SysUtils,
  q_shared,
  client,
  cvar,
  cpas,
  keys,
  cl_scrn,
  vid_dll,
  menu,
  qmenu;

const
  REF_SOFT = 0;
  REF_OPENGL = 1;
  REF_3DFX = 2;
  REF_POWERVR = 3;
  REF_VERITE = 4;

  {extern}{vid_ref, vid_fullscreen, vid_gamma, scr_viewsize,}
var
  {static}
  gl_mode, gl_driver, gl_picmip, gl_ext_palettedtexture, gl_finish,
    sw_mode, sw_stipplealpha: cvar_p;

  {extern}//procedure M_ForceMenuOff; - function will be called as the unit is mentioned in the uses clause

  (*
  ====================================================================

  MENU INTERACTION

  ====================================================================
  *)
const
  SOFTWARE_MENU = 0;
  OPENGL_MENU = 1;

var
  {static}
  s_software_menu,
    s_opengl_menu: menuframework_s;
  s_current_menu: menuframework_p;

  s_current_menu_index: integer;

  s_mode_list,
    s_ref_list: array[0..1] of menulist_s;

  s_tq_slider: menuslider_s;
  s_screensize_slider,
    s_brightness_slider: array[0..1] of menuslider_s;

  s_fs_box: array[0..1] of menulist_s;
  s_stipple_box,
    s_paletted_texture_box,
    s_finish_box: menulist_s;

  s_cancel_action,
    s_defaults_action: array[0..1] of menuaction_s;

  {static void}

procedure DriverCallback(unused: pointer);
begin
  s_ref_list[Integer(not Boolean(s_current_menu_index))].curvalue := s_ref_list[s_current_menu_index].curvalue;

  if (s_ref_list[s_current_menu_index].curvalue = 0) then
  begin
    s_current_menu := @s_software_menu;
    s_current_menu_index := 0;
  end
  else
  begin
    s_current_menu := @s_opengl_menu;
    s_current_menu_index := 1;
  end;
end;

{static void}

procedure ScreenSizeCallback(s: pointer); //( void *s )
var
  slider: menuslider_p;
begin
  slider := menuslider_p(s);
  Cvar_SetValue('viewsize', slider^.curvalue * 10);
end;

{static void}

procedure BrightnessCallback(s: pointer); //( void *s )
var
  slider: menuslider_p;
  gamma: single;
begin
  slider := menuslider_p(s);
  if (s_current_menu_index = SOFTWARE_MENU) then
    s_brightness_slider[1].curvalue := s_brightness_slider[0].curvalue
  else
    s_brightness_slider[0].curvalue := s_brightness_slider[1].curvalue;

  if (strcomp(vid_ref^.string_, 'soft') = 0) then
  begin
    gamma := (0.8 - (slider^.curvalue / 10.0 - 0.5)) + 0.5;
    Cvar_SetValue('vid_gamma', gamma);
  end;
end;

{static void}

procedure ResetDefaults(unused: pointer); //( void *unused )
begin
  VID_MenuInit();
end;

{static void}

procedure ApplyChanges(unused: pointer); //( void *unused )
var
  gamma, g: single;
  // envbuffer: array[0..1024-1] of Char; Juha: Not needed, made this differently from original
begin
  (*
  ** make values consistent
  *)
  s_fs_box[not s_current_menu_index].curvalue := s_fs_box[s_current_menu_index].curvalue;
  s_brightness_slider[not s_current_menu_index].curvalue := s_brightness_slider[s_current_menu_index].curvalue;
  s_ref_list[not s_current_menu_index].curvalue := s_ref_list[s_current_menu_index].curvalue;

  (*
  ** invert sense so greater:= brighter, and scale to a range of 0.5 to 1.3
  *)
  gamma := (0.8 - (s_brightness_slider[s_current_menu_index].curvalue / 10.0 - 0.5)) + 0.5;

  Cvar_SetValue('vid_gamma', gamma);
  Cvar_SetValue('sw_stipplealpha', s_stipple_box.curvalue);
  Cvar_SetValue('gl_picmip', 3 - s_tq_slider.curvalue);
  Cvar_SetValue('vid_fullscreen', s_fs_box[s_current_menu_index].curvalue);
  Cvar_SetValue('gl_ext_palettedtexture', s_paletted_texture_box.curvalue);
  Cvar_SetValue('gl_finish', s_finish_box.curvalue);
  Cvar_SetValue('sw_mode', s_mode_list[SOFTWARE_MENU].curvalue);
  Cvar_SetValue('gl_mode', s_mode_list[OPENGL_MENU].curvalue);

  case (s_ref_list[s_current_menu_index].curvalue) of
    REF_SOFT:
      begin
        Cvar_Set('vid_ref', 'soft');
      end;
    REF_OPENGL:
      begin
        Cvar_Set('vid_ref', 'gl');
        Cvar_Set('gl_driver', 'opengl32');
      end;
    REF_3DFX:
      begin
        Cvar_Set('vid_ref', 'gl');
        Cvar_Set('gl_driver', '3dfxgl');
      end;
    REF_POWERVR:
      begin
        Cvar_Set('vid_ref', 'gl');
        Cvar_Set('gl_driver', 'pvrgl');
      end;
    REF_VERITE:
      begin
        Cvar_Set('vid_ref', 'gl');
        Cvar_Set('gl_driver', 'veritegl');
      end;
  end;

  (*
  ** update appropriate stuff if we're running OpenGL and gamma
  ** has been modified
  *)
  if (strcmp(vid_ref^.string_, 'gl') = 0) then
  begin
    if (vid_gamma^.modified) then
    begin
      vid_ref^.modified := true;
      if (strcmp(gl_driver.string_, '3dfxgl') = 0) then
      begin
        vid_ref^.modified := true;

        g := 2.00 * (0.8 - (vid_gamma^.value - 0.5)) + 1.0 {F};
        Windows.SetEnvironmentVariable('SSTV2_GAMMA', PChar(Format('%f', [g])));
        Windows.SetEnvironmentVariable('SST_GAMMA', PChar(Format('%f', [g])));
        vid_gamma^.modified := false;
      end;
    end;

    if (gl_driver.modified) then
      vid_ref^.modified := true;
  end;

  M_ForceMenuOff();
end;

{static void}

procedure OnCancelChanges(unused: pointer); //( void *unused )
begin
  M_PopMenu();                          // declared and defined in another unit check uses clause
end;

(*
** VID_MenuInit
*)
{void}

procedure VID_MenuInit;
var
  i: integer;
const
  resolutions: array[0..11] of PChar = (
    '[320 240  ]',
    '[400 300  ]',
    '[512 384  ]',
    '[640 480  ]',
    '[800 600  ]',
    '[960 720  ]',
    '[1024 768 ]',
    '[1152 864 ]',
    '[1280 960 ]',
    '[1600 1200]',
    '[2048 1536]',
    nil);

  refs: array[0..4] of PChar = (
    '[software      ]',
    '[default OpenGL]',
    '[3Dfx OpenGL   ]',
    '[PowerVR OpenGL]',
    nil);

  yesno_names: array[0..2] of PChar = (
    'no',
    'yes',
    nil);
begin
  if (gl_driver = nil) then
    gl_driver := Cvar_Get('gl_driver', 'opengl32', 0);
  if (gl_picmip = nil) then
    gl_picmip := Cvar_Get('gl_picmip', '0', 0);
  if (gl_mode = nil) then
    gl_mode := Cvar_Get('gl_mode', '3', 0);
  if (sw_mode = nil) then
    sw_mode := Cvar_Get('sw_mode', '0', 0);
  if (gl_ext_palettedtexture = nil) then
    gl_ext_palettedtexture := Cvar_Get('gl_ext_palettedtexture', '1', CVAR_ARCHIVE);
  if (gl_finish = nil) then
    gl_finish := Cvar_Get('gl_finish', '0', CVAR_ARCHIVE);

  if (sw_stipplealpha = nil) then
    sw_stipplealpha := Cvar_Get('sw_stipplealpha', '0', CVAR_ARCHIVE);

  s_mode_list[SOFTWARE_MENU].curvalue := Trunc(sw_mode^.value);
  s_mode_list[OPENGL_MENU].curvalue := Trunc(gl_mode^.value);

  if (scr_viewsize = nil) then
    scr_viewsize := Cvar_Get('viewsize', '100', CVAR_ARCHIVE);

  s_screensize_slider[SOFTWARE_MENU].curvalue := scr_viewsize^.value / 10;
  s_screensize_slider[OPENGL_MENU].curvalue := scr_viewsize^.value / 10;

  if (strcmp(vid_ref^.string_, 'soft') = 0) then
  begin
    s_current_menu_index := SOFTWARE_MENU;
    s_ref_list[0].curvalue := REF_SOFT;
    s_ref_list[1].curvalue := REF_SOFT;
  end
  else if (strcmp(vid_ref^.string_, 'gl') = 0) then
  begin
    s_current_menu_index := OPENGL_MENU;
    if (strcmp(gl_driver^.string_, '3dfxgl') = 0) then
      s_ref_list[s_current_menu_index].curvalue := REF_3DFX
    else if (strcmp(gl_driver^.string_, 'pvrgl') = 0) then
      s_ref_list[s_current_menu_index].curvalue := REF_POWERVR
    else if (strcmp(gl_driver^.string_, 'opengl32') = 0) then
      s_ref_list[s_current_menu_index].curvalue := REF_OPENGL
    else
      //    s_ref_list[s_current_menu_index].curvalue:= REF_VERITE;
      s_ref_list[s_current_menu_index].curvalue := REF_OPENGL;
  end;

  s_software_menu.x := viddef.width div 2;
  s_software_menu.nitems := 0;
  s_opengl_menu.x := viddef.width div 2;
  s_opengl_menu.nitems := 0;

  for i := 0 to 1 do
  begin
    s_ref_list[i].generic.type_ := MTYPE_SPINCONTROL;
    s_ref_list[i].generic.name := 'driver';
    s_ref_list[i].generic.x := 0;
    s_ref_list[i].generic.y := 0;
    s_ref_list[i].generic.callback := DriverCallback;
    s_ref_list[i].itemnames := @refs;

    s_mode_list[i].generic.type_ := MTYPE_SPINCONTROL;
    s_mode_list[i].generic.name := 'video mode';
    s_mode_list[i].generic.x := 0;
    s_mode_list[i].generic.y := 10;
    s_mode_list[i].itemnames := @resolutions;

    s_screensize_slider[i].generic.type_ := MTYPE_SLIDER;
    s_screensize_slider[i].generic.x := 0;
    s_screensize_slider[i].generic.y := 20;
    s_screensize_slider[i].generic.name := 'screen size';
    s_screensize_slider[i].minvalue := 3;
    s_screensize_slider[i].maxvalue := 12;
    s_screensize_slider[i].generic.callback := @ScreenSizeCallback;

    s_brightness_slider[i].generic.type_ := MTYPE_SLIDER;
    s_brightness_slider[i].generic.x := 0;
    s_brightness_slider[i].generic.y := 30;
    s_brightness_slider[i].generic.name := 'brightness';
    s_brightness_slider[i].generic.callback := @BrightnessCallback;
    s_brightness_slider[i].minvalue := 5;
    s_brightness_slider[i].maxvalue := 13;
    s_brightness_slider[i].curvalue := (1.3 - vid_gamma^.value + 0.5) * 10;

    s_fs_box[i].generic.type_ := MTYPE_SPINCONTROL;
    s_fs_box[i].generic.x := 0;
    s_fs_box[i].generic.y := 40;
    s_fs_box[i].generic.name := 'fullscreen';
    s_fs_box[i].itemnames := @yesno_names;
    s_fs_box[i].curvalue := Round(vid_fullscreen^.value);

    s_defaults_action[i].generic.type_ := MTYPE_ACTION;
    s_defaults_action[i].generic.name := 'reset to defaults';
    s_defaults_action[i].generic.x := 0;
    s_defaults_action[i].generic.y := 90;
    s_defaults_action[i].generic.callback := @ResetDefaults;

    s_cancel_action[i].generic.type_ := MTYPE_ACTION;
    s_cancel_action[i].generic.name := 'cancel';
    s_cancel_action[i].generic.x := 0;
    s_cancel_action[i].generic.y := 100;
    s_cancel_action[i].generic.callback := @OnCancelChanges;
  end;

  s_stipple_box.generic.type_ := MTYPE_SPINCONTROL;
  s_stipple_box.generic.x := 0;
  s_stipple_box.generic.y := 60;
  s_stipple_box.generic.name := 'stipple alpha';
  s_stipple_box.curvalue := Trunc(sw_stipplealpha^.value);
  s_stipple_box.itemnames := @yesno_names;

  s_tq_slider.generic.type_ := MTYPE_SLIDER;
  s_tq_slider.generic.x := 0;
  s_tq_slider.generic.y := 60;
  s_tq_slider.generic.name := 'texture quality';
  s_tq_slider.minvalue := 0;
  s_tq_slider.maxvalue := 3;
  s_tq_slider.curvalue := 3 - gl_picmip^.value;

  s_paletted_texture_box.generic.type_ := MTYPE_SPINCONTROL;
  s_paletted_texture_box.generic.x := 0;
  s_paletted_texture_box.generic.y := 70;
  s_paletted_texture_box.generic.name := '8-bit textures';
  s_paletted_texture_box.itemnames := @yesno_names;
  s_paletted_texture_box.curvalue := Trunc(gl_ext_palettedtexture^.value);

  s_finish_box.generic.type_ := MTYPE_SPINCONTROL;
  s_finish_box.generic.x := 0;
  s_finish_box.generic.y := 80;
  s_finish_box.generic.name := 'sync every frame';
  s_finish_box.curvalue := Trunc(gl_finish^.value);
  s_finish_box.itemnames := @yesno_names;

  Menu_AddItem(@s_software_menu, @s_ref_list[SOFTWARE_MENU]);
  Menu_AddItem(@s_software_menu, @s_mode_list[SOFTWARE_MENU]);
  Menu_AddItem(@s_software_menu, @s_screensize_slider[SOFTWARE_MENU]);
  Menu_AddItem(@s_software_menu, @s_brightness_slider[SOFTWARE_MENU]);
  Menu_AddItem(@s_software_menu, @s_fs_box[SOFTWARE_MENU]);
  Menu_AddItem(@s_software_menu, @s_stipple_box);

  Menu_AddItem(@s_opengl_menu, @s_ref_list[OPENGL_MENU]);
  Menu_AddItem(@s_opengl_menu, @s_mode_list[OPENGL_MENU]);
  Menu_AddItem(@s_opengl_menu, @s_screensize_slider[OPENGL_MENU]);
  Menu_AddItem(@s_opengl_menu, @s_brightness_slider[OPENGL_MENU]);
  Menu_AddItem(@s_opengl_menu, @s_fs_box[OPENGL_MENU]);
  Menu_AddItem(@s_opengl_menu, @s_tq_slider);
  Menu_AddItem(@s_opengl_menu, @s_paletted_texture_box);
  Menu_AddItem(@s_opengl_menu, @s_finish_box);

  Menu_AddItem(@s_software_menu, @s_defaults_action[SOFTWARE_MENU]);
  Menu_AddItem(@s_software_menu, @s_cancel_action[SOFTWARE_MENU]);
  Menu_AddItem(@s_opengl_menu, @s_defaults_action[OPENGL_MENU]);
  Menu_AddItem(@s_opengl_menu, @s_cancel_action[OPENGL_MENU]);

  Menu_Center(@s_software_menu);
  Menu_Center(@s_opengl_menu);
  s_opengl_menu.x := s_opengl_menu.x - 8;
  s_software_menu.x := s_software_menu.x - 8;
end;

(*
================
VID_MenuDraw
================
*)
{void}

procedure VID_MenuDraw;                 // (void)
var
  w, h: integer;
begin
  if (s_current_menu_index = 0) then
    s_current_menu := @menuframework_s(s_software_menu)
  else
    s_current_menu := @menuframework_s(s_opengl_menu);

  (*
  ** draw the banner
  *)
  re.DrawGetPicSize(@w, @h, 'm_banner_video');
  re.DrawPic(viddef.width div 2 - w div 2, viddef.height div 2 - 110, 'm_banner_video');

  (*
  ** move cursor to a reasonable starting position
  *)
  Menu_AdjustCursor(s_current_menu, 1);

  (*
  ** draw the menu
  *)
  Menu_Draw(s_current_menu);
end;

(*
================
VID_MenuKey
================
*)

function VID_MenuKey(key: integer): PChar;
const
  sound: PChar = 'misc/menu1.wav';
var
  m: menuframework_p;
begin
  m := s_current_menu;

  Result := sound;

  case (key) of
    K_ESCAPE:
      begin
        ApplyChanges(m);
        Result := nil;
      end;
    K_KP_UPARROW,
      K_UPARROW:
      begin
        dec(m^.cursor);
        Menu_AdjustCursor(m, -1);
      end;
    K_KP_DOWNARROW,
      K_DOWNARROW:
      begin
        inc(m^.cursor);
        Menu_AdjustCursor(m, 1);
      end;
    K_KP_LEFTARROW,
      K_LEFTARROW:
      Menu_SlideItem(m, -1);
    K_KP_RIGHTARROW,
      K_RIGHTARROW:
      Menu_SlideItem(m, 1);
    K_KP_ENTER,
      K_ENTER:
      if (not Menu_SelectItem(m)) then
        ApplyChanges(m);
  end;
end;

end.
