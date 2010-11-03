unit vid_menu;

//Initial conversion by : Fabrizio Rossini ( FAB )
//
{ This File contains part of convertion of Quake2 source to ObjectPascal.    }
{ More information about this project can be found at:                       }
{ http://www.sulaco.co.za/quake2/                                            }


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

interface
uses Cvar,Qmenu ;
{.$include "../client/client.h"}
{.$include "../client/qmenu.h"}

{REF stuff ...
Used to dynamically load the menu with only those vid_ref's that
are present on this system}


const

//* this will have to be updated if ref's are added/removed from ref_t */
NUMBER_OF_REFS = 5;

//* all the refs should be initially set to 0 */
refs : array [0..Pred(NUMBER_OF_REFS+1)] of pchar = (nil,nil,nil,nil,nil,nil);
var
(* make all these have illegal values, as they will be redefined *)
REF_SOFT: integer = NUMBER_OF_REFS; 
REF_SOFTX11: integer = NUMBER_OF_REFS; 
REF_SOFTSDL: integer = NUMBER_OF_REFS; 
REF_GLX: integer = NUMBER_OF_REFS; 
REF_SDLGL: integer = NUMBER_OF_REFS; 
(*static int REF_FXGL    = NUMBER_OF_REFS;*)
GL_REF_START: integer = NUMBER_OF_REFS; 

type
ref_t = record
menuname: array [0..Pred(32)] of char; 
realname: array [0..Pred(32)] of char; 
pointerr: pointer; 
end;

var {was static}
gl_mode: cvar_p; 
gl_driver: cvar_p; 
gl_picmip: cvar_p; 
gl_ext_palettedtexture: cvar_p; 
sw_mode: cvar_p; 
sw_stipplealpha: cvar_p; 
_windowed_mouse: cvar_p; 

 
procedure VID_MenuInit();
procedure VID_MenuDraw();
function VID_MenuKey(key: integer): pchar;
procedure VID_MenuShutdown();

(*
====================================================================

MENU INTERACTION

====================================================================
*)
const
SOFTWARE_MENU = 0; 
OPENGL_MENU = 1; 

var {was static}
s_software_menu: menuframework_s;
s_opengl_menu: menuframework_s; 
s_current_menu: menuframework_p; 
s_current_menu_index: integer; 
s_mode_list: array [0..Pred(2)] of menulist_s; 
s_ref_list: array [0..Pred(2)] of menulist_s; 
s_tq_slider: menuslider_s; 
s_screensize_slider: array [0..Pred(2)] of menuslider_s; 
s_brightness_slider: array [0..Pred(2)] of menuslider_s; 
s_fs_box: array [0..Pred(2)] of menulist_s; 
s_stipple_box: menulist_s; 
s_paletted_texture_box: menulist_s; 
s_windowed_mouse: menulist_s; 
s_apply_action: array [0..Pred(2)] of menuaction_s; 
s_defaults_action: array [0..Pred(2)] of menuaction_s; 

implementation

uses SysUtils ,vid_so ,q_shared , cl_scrn , menu, libc; //Cpas ;

procedure DriverCallback(unused: Pointer {pinteger}); 
begin
  s_ref_list[not s_current_menu_index].curvalue:= s_ref_list[s_current_menu_index].curvalue; 
  if s_ref_list[s_current_menu_index].curvalue < GL_REF_START then
  begin 
    s_current_menu:= @s_software_menu; 
    s_current_menu_index:= 0; 
  end
  else
  begin 
    s_current_menu:= @s_opengl_menu; 
    s_current_menu_index:= 1; 
  end;
end;



procedure ScreenSizeCallback(s: pointer);
var
slider: menuslider_p;
 
begin
  //slider:=(menuslider_s*)s;
  slider:=menuslider_p (s); 
  Cvar_SetValue('viewsize',slider^.curvalue * 10); 
end;


procedure BrightnessCallback(s: pointer);
var
slider: menuslider_p;
 
gamma: Single; 
 
begin
  //slider:=(menuslider_s*)s;
  slider:=menuslider_p (s); 
  if s_current_menu_index =0 then
  s_brightness_slider[1].curvalue:= s_brightness_slider[0].curvalue
  else
  s_brightness_slider[0].curvalue:= s_brightness_slider[1].curvalue;
   
  if (stricomp(vid_ref^.string_,'soft')=0) or (stricomp(vid_ref^.string_,'softx')=0) or (stricomp(vid_ref^.string_,'softsdl')=0) or (stricomp(vid_ref^.string_,'glx')=0) then
  begin
    gamma:=(0.8-(slider^.curvalue / 10.0 - 0.5))+0.5; 
    Cvar_SetValue('vid_gamma',gamma); 
  end;
end;


procedure ResetDefaults(unused: pointer);
begin
  VID_MenuInit();
end;


procedure ApplyChanges(unused: pointer);
var
gamma: Single; //float;
ref: integer; 
(*
 ** make values consistent
 *)
//envbuffer: array [0..Pred(1024)] of char;
//g: Single; //float; 
begin
  s_fs_box[not s_current_menu_index].curvalue:= s_fs_box[s_current_menu_index].curvalue; 
  s_brightness_slider[not s_current_menu_index].curvalue:= s_brightness_slider[s_current_menu_index].curvalue; 
  s_ref_list[not s_current_menu_index].curvalue:= s_ref_list[s_current_menu_index].curvalue; 
   
  
  (*
   ** invert sense so greater = brighter, and scale to a range of 0.5 to 1.3
   *)
  gamma:= (0.8-(s_brightness_slider[s_current_menu_index].curvalue / 10.0-0.5))+0.5;
   
  Cvar_SetValue('vid_gamma',gamma);
  Cvar_SetValue('sw_stipplealpha',s_stipple_box.curvalue); 
  Cvar_SetValue('gl_picmip',3 - s_tq_slider.curvalue); 
  Cvar_SetValue('vid_fullscreen',s_fs_box[s_current_menu_index].curvalue); 
  Cvar_SetValue('gl_ext_palettedtexture',s_paletted_texture_box.curvalue); 
  Cvar_SetValue('sw_mode',s_mode_list[SOFTWARE_MENU].curvalue); 
  Cvar_SetValue('gl_mode',s_mode_list[OPENGL_MENU].curvalue); 
  Cvar_SetValue('_windowed_mouse',s_windowed_mouse.curvalue); 
  ref:= s_ref_list[s_current_menu_index].curvalue;
  (*
   ** must use an if here (instead of a switch), since the REF_'s are now variables
   ** and not #DEFINE's (constants)
   *)
  //case s_ref_list[s_current_menu_index].curvalue of
   if ref = REF_SOFT then
    begin
      Cvar_Set('vid_ref','soft'); 
    end;
	

  if ref=REF_SOFTX11
  then
  begin 
    Cvar_Set('vid_ref','softx'); 
  end
  else
  if ref=REF_SOFTSDL
  then
  begin 
    Cvar_Set('vid_ref','softsdl'); 
  end
  else
  if ref=REF_GLX
  then
  begin 
    Cvar_Set('vid_ref','glx'); 
    Cvar_Get('gl_driver','libGL.so',CVAR_ARCHIVE); 
    (* below is wrong if we use different libs for different GL reflibs*)
    (* ??? create if it doesn't exit*)
    if gl_driver.modified then
    vid_ref.modified:= true; 
  end
  else
  if ref=REF_SDLGL
  then
  begin 
    Cvar_Set('vid_ref','sdlgl'); 
    Cvar_Get('gl_driver','libGL.so',CVAR_ARCHIVE); 
    (* below is wrong if we use different libs for different GL reflibs*)
    (* ??? create if it doesn't exist*)
    if gl_driver.modified then
    vid_ref.modified:= true; 
  end;
  
    
 // end;
  
{$if false}
  (*
   ** update appropriate stuff if we're running OpenGL and gamma
   ** has been modified
   *)
  if stricmp(vid_ref._string,'gl')=0
  then
  begin 
    if vid_gamma.modified<>0{nil} {<= !!!9} 
    then
    begin 
      vid_ref.modified:= true; 
      if stricmp(gl_driver._string,'3dfxgl')=0
      then
      begin 
        
        vid_ref.modified:= true; 
        g:= 2.0*(0.8-(vid_gamma.value-0.5))+1.0F; 
        Com_sprintf(envbuffer,sizeof(envbuffer),'SST_GAMMA=%f',g); 
        
        putenv(envbuffer); 
        vid_gamma.modified:= false; 
        
      end;
    end;
  end;
  {$ifend}
  M_ForceMenuOff(); 
  
end;

(*
** VID_MenuInit
*)

procedure VID_MenuInit();
const
resolutions: array [0..Pred(15)] of pchar = ('[320 240  ]',
                                             '[400 300  ]',
                                             '[512 384  ]',
                                             '[640 480  ]',
                                             '[800 600  ]',
                                             '[960 720  ]',
                                             '[1024 768 ]',
                                             '[1152 864 ]',
                                             '[1280 1024]',											
                                             '[1600 1200]',
                                             '[2048 1536]',
                                             '[1024 480 ]', //* sony vaio pocketbook */
                                             '[1152 768 ]', //* Apple TiBook */
                                             '[1280 854 ]', //* Apple TiBook */
                                             nil);
											  
refs: array [0..6] of pchar = ('[software       ]',
                               '[software X11   ]',
                               '[Mesa 3-D 3DFX  ]',
                               '[3DFXGL Miniport]',
                               '[OpenGL glX     ]',
                               '[Mesa 3-D glX   ]',
                                      nil);

possible_refs: array [0..Pred(NUMBER_OF_REFS)] of ref_t = ((menuname :'[software      ]'; realname :'soft'    ;pointerr : @REF_SOFT),
                                                           (menuname :'[software X11  ]'; realname :'softx'   ;pointerr : @REF_SOFTX11),
                                                           (menuname :'[software SDL  ]'; realname :'softsdl' ;pointerr : @REF_SOFTSDL),
                                                           (menuname :'[OpenGL GLX    ]'; realname :'glx'     ;pointerr : @REF_GLX),
                                                           (menuname :'[SDL OpenGL    ]'; realname :'sdlgl'   ;pointerr : @REF_SDLGL));
														    
                                      
yesno_names: array [0..Pred(3)] of pchar = ('no','yes',nil);
 
var
i: integer;
counter :integer ;
 
begin
  
  (* make sure these are invalided before showing the menu again *)
  REF_SOFT:= NUMBER_OF_REFS; 
  REF_SOFTX11:= NUMBER_OF_REFS; 
  REF_SOFTSDL:= NUMBER_OF_REFS; 
  REF_GLX:= NUMBER_OF_REFS; 
  REF_SDLGL:= NUMBER_OF_REFS;
  (*REF_FXGL    = NUMBER_OF_REFS;*)
   
  GL_REF_START:= NUMBER_OF_REFS;
  
  //* now test to see which ref's are present */ 
  counter:=0;
  i := counter; 
  while i < NUMBER_OF_REFS do
  begin 
    if VID_CheckRefExists(possible_refs[i].realname) then
    begin
      Cardinal(possible_refs[i].pointerr^) := counter ;
	  
	  (* free any previous string *)
      if refs[i]<> nil   then
      free(refs[i]);

      refs[counter]^:= Char(strdup(possible_refs[i].menuname));
	  (*
         ** if we reach the 3rd item in the list, this indicates that a
         ** GL ref has been found; this will change if more software
         ** modes are added to the possible_ref's array
         *)
      if i=3 then
      GL_REF_START:= counter; 
      inc(counter); 
      
    end;
    inc(i); 
  end;
  
  refs[counter]^:= Char(0);

  
  if {not} gl_driver = nil then
  gl_driver:= Cvar_Get('gl_driver','libGL.so',0); 
  if {not} gl_picmip = nil then
  gl_picmip:= Cvar_Get('gl_picmip','0',0); 
  if {not} gl_mode = nil then
  gl_mode:= Cvar_Get('gl_mode','3',0); 
  if {not} sw_mode = nil then
  sw_mode:= Cvar_Get('sw_mode','0',0); 
  if {not} gl_ext_palettedtexture = nil then
  gl_ext_palettedtexture:= Cvar_Get('gl_ext_palettedtexture','1',CVAR_ARCHIVE); 
  if {not} sw_stipplealpha = nil then
  sw_stipplealpha:= Cvar_Get('sw_stipplealpha','0',CVAR_ARCHIVE); 
  if {not} _windowed_mouse = nil then
  _windowed_mouse:= Cvar_Get('_windowed_mouse','0',CVAR_ARCHIVE);
  
  s_mode_list[SOFTWARE_MENU].curvalue:= Trunc(sw_mode^.value);
  s_mode_list[OPENGL_MENU].curvalue:= Trunc(gl_mode^.value);
  
  if scr_viewsize = nil then
  scr_viewsize:= Cvar_Get('viewsize','100',CVAR_ARCHIVE); 
  s_screensize_slider[SOFTWARE_MENU].curvalue:= scr_viewsize^.value / 10; 
  s_screensize_slider[OPENGL_MENU].curvalue:= scr_viewsize^.value / 10; 
  
  if ( {lstrcmp} strcomp(vid_ref^.string_,'soft')=0 ) then
  begin 
    s_current_menu_index:= SOFTWARE_MENU; 
    s_ref_list[0].curvalue:= REF_SOFT;
    s_ref_list[1].curvalue:= REF_SOFT;
  end
  else
  if {lstrcmp} strcomp(vid_ref^.string_,'softx') =0 then
  begin 
    s_current_menu_index:= SOFTWARE_MENU; 
    s_ref_list[0].curvalue:= REF_SOFTX11;
    s_ref_list[1].curvalue:= REF_SOFTX11;
  end
  else
  {if strcomp(vid_ref^.string_,'gl')= 0 then
  begin 
    s_current_menu_index:= OPENGL_MENU; 
    if strcomp(gl_driver^.string_,'lib3dfxgl.so')= 0 then
    s_ref_list[s_current_menu_index].curvalue:= REF_3DFXGL
    else
    s_ref_list[s_current_menu_index].curvalue:= REF_MESA3D; 
  end
  }
  if strcomp(vid_ref^.string_,'softsdl')= 0 then
  begin 
    s_current_menu_index:= SOFTWARE_MENU;
	s_ref_list[0].curvalue:= REF_SOFTSDL;
    s_ref_list[1].curvalue:= REF_SOFTSDL;
  end 
  else
  if strcomp(vid_ref^.string_,'glx')= 0 then
  begin 
    s_current_menu_index:= OPENGL_MENU; 
    s_ref_list[s_current_menu_index].curvalue:= REF_GLX; 
  end
  else
  if strcomp(vid_ref^.string_,'sdlgl')= 0 then
  begin 
    s_current_menu_index:= OPENGL_MENU; 
    s_ref_list[s_current_menu_index].curvalue:= REF_SDLGL;
  end;
  
  s_software_menu.x:= viddef.width div 2 ; //* 0.50;
  s_software_menu.nitems:= 0; 
  s_opengl_menu.x:= viddef.width div 2 ; //* 0.50;
  s_opengl_menu.nitems:= 0; 
  
  for{while} i:=0 to Pred(2) { i++ } do
  begin 
    s_ref_list[i].generic.type_:= MTYPE_SPINCONTROL;
    s_ref_list[i].generic.name:= 'driver'; 
    s_ref_list[i].generic.x:= 0; 
    s_ref_list[i].generic.y:= 0; 
    s_ref_list[i].generic.callback:= DriverCallback; 
    s_ref_list[i].itemnames:= @refs;

    s_mode_list[i].generic.type_:= MTYPE_SPINCONTROL;
    s_mode_list[i].generic.name:= 'video mode'; 
    s_mode_list[i].generic.x:= 0; 
    s_mode_list[i].generic.y:= 10; 
    s_mode_list[i].itemnames:= @resolutions;
	 
    s_screensize_slider[i].generic.type_:= MTYPE_SLIDER;
    s_screensize_slider[i].generic.x:= 0; 
    s_screensize_slider[i].generic.y:= 20; 
    s_screensize_slider[i].generic.name:= 'screen size'; 
    s_screensize_slider[i].minvalue:= 3; 
    s_screensize_slider[i].maxvalue:= 12; 
    s_screensize_slider[i].generic.callback:= ScreenSizeCallback;
	 
    s_brightness_slider[i].generic.type_:= MTYPE_SLIDER;
    s_brightness_slider[i].generic.x:= 0; 
    s_brightness_slider[i].generic.y:= 30; 
    s_brightness_slider[i].generic.name:= 'brightness'; 
    s_brightness_slider[i].generic.callback:= BrightnessCallback; 
    s_brightness_slider[i].minvalue:= 5; 
    s_brightness_slider[i].maxvalue:= 13; 
    s_brightness_slider[i].curvalue:= (1.3 - vid_gamma^.value + 0.5)*10;
	 
    s_fs_box[i].generic.type_:= MTYPE_SPINCONTROL;
    s_fs_box[i].generic.x:= 0; 
    s_fs_box[i].generic.y:= 40; 
    s_fs_box[i].generic.name:= 'fullscreen'; 
    s_fs_box[i].itemnames:= @yesno_names; 
    s_fs_box[i].curvalue:= Trunc(vid_fullscreen^.value);
	 
    s_defaults_action[i].generic.type_:= MTYPE_ACTION;
    s_defaults_action[i].generic.name:= 'reset to default';
    s_defaults_action[i].generic.x:= 0; 
    s_defaults_action[i].generic.y:= 90; 
    s_defaults_action[i].generic.callback:= ResetDefaults;
	 
    s_apply_action[i].generic.type_:= MTYPE_ACTION;
    s_apply_action[i].generic.name:= 'apply';
    s_apply_action[i].generic.x:= 0; 
    s_apply_action[i].generic.y:= 100; 
    s_apply_action[i].generic.callback:= ApplyChanges; 
      
  end;

  s_stipple_box.generic.type_:= MTYPE_SPINCONTROL;
  s_stipple_box.generic.x:= 0; 
  s_stipple_box.generic.y:= 60; 
  s_stipple_box.generic.name:= 'stipple alpha'; 
  s_stipple_box.curvalue:= Trunc(sw_stipplealpha^.value);
  s_stipple_box.itemnames:= @yesno_names;
   
  s_windowed_mouse.generic.type_:= MTYPE_SPINCONTROL;
  s_windowed_mouse.generic.x:= 0; 
  s_windowed_mouse.generic.y:= 72; 
  s_windowed_mouse.generic.name:= 'windowed mouse'; 
  s_windowed_mouse.curvalue:= Trunc( _windowed_mouse^.value);
  s_windowed_mouse.itemnames:= @yesno_names;
   
  s_tq_slider.generic.type_:= MTYPE_SLIDER;
  s_tq_slider.generic.x:= 0; 
  s_tq_slider.generic.y:= 60; 
  s_tq_slider.generic.name:= 'texture quality'; 
  s_tq_slider.minvalue:= 0; 
  s_tq_slider.maxvalue:= 3; 
  s_tq_slider.curvalue:= 3 - gl_picmip^.value;
   
  s_paletted_texture_box.generic.type_:= MTYPE_SPINCONTROL; 
  s_paletted_texture_box.generic.x:= 0; 
  s_paletted_texture_box.generic.y:= 70; 
  s_paletted_texture_box.generic.name:= '8-bit textures'; 
  s_paletted_texture_box.itemnames:= @yesno_names;
  s_paletted_texture_box.curvalue:= Trunc(gl_ext_palettedtexture^.value);

   
  Menu_AddItem(@s_software_menu,@s_ref_list[SOFTWARE_MENU]);
  Menu_AddItem(@s_software_menu,@s_mode_list[SOFTWARE_MENU]);
  Menu_AddItem(@s_software_menu,@s_screensize_slider[SOFTWARE_MENU]);
  Menu_AddItem(@s_software_menu,@s_brightness_slider[SOFTWARE_MENU]);
  Menu_AddItem(@s_software_menu,@s_fs_box[SOFTWARE_MENU]);
  Menu_AddItem(@s_software_menu,@s_stipple_box);
  Menu_AddItem(@s_software_menu,@s_windowed_mouse);
   
  Menu_AddItem(@s_opengl_menu,@s_ref_list[OPENGL_MENU]);
  Menu_AddItem(@s_opengl_menu,@s_mode_list[OPENGL_MENU]);
  Menu_AddItem(@s_opengl_menu,@s_screensize_slider[OPENGL_MENU]);
  Menu_AddItem(@s_opengl_menu,@s_brightness_slider[OPENGL_MENU]);
  Menu_AddItem(@s_opengl_menu,@s_fs_box[OPENGL_MENU]);
  Menu_AddItem(@s_opengl_menu,@s_tq_slider);
  Menu_AddItem(@s_opengl_menu,@s_paletted_texture_box);
   
  Menu_AddItem(@s_software_menu,@s_defaults_action[SOFTWARE_MENU]);
  Menu_AddItem(@s_software_menu,@s_apply_action[SOFTWARE_MENU]);
  Menu_AddItem(@s_opengl_menu,@s_defaults_action[OPENGL_MENU]);
  Menu_AddItem(@s_opengl_menu,@s_apply_action[OPENGL_MENU]);
   
  Menu_Center(@s_software_menu); 
  Menu_Center(@s_opengl_menu); 
  s_opengl_menu.x:= s_opengl_menu.x - 8; 
  s_software_menu.x:= s_software_menu.x - 8; 
end;

(*
================
VID_MenuShutdown
================
*)
procedure VID_MenuShutdown(); 
var
i: integer; 
begin
  for{while} i:=0 to Pred(NUMBER_OF_REFS) { i++ }
  do
  begin 
    if refs[i]<> nil
    then
    free(refs[i]); 
  end;
end;

(*
================
VID_MenuDraw
================
*)

procedure VID_MenuDraw();
var
w: integer; 
h: integer; 
begin
  
  if s_current_menu_index =0 then
  s_current_menu:= @s_software_menu
  else
  s_current_menu:= @s_opengl_menu; 
   
  (*
   ** draw the banner
   *)
  re.DrawGetPicSize(@w,@h,'m_banner_video'); 
  re.DrawPic(viddef.width div 2-w div 2,viddef.height div 2-110,'m_banner_video'); 
  
  (*
   ** move cursor to a reasonable starting position
   *)
  Menu_AdjustCursor(s_current_menu,1);
   
  
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

function VID_MenuKey(key: integer): pchar;
const
sound: pchar = 'misc/menu1.wav'; 
var
m: menuframework_p;
 
begin
  
  //procedure M_PopMenu(); 
  
  m:=s_current_menu; 
  case key of
    K_ESCAPE:
    begin
      M_PopMenu();
      result:= nil;//#0 
      exit;
    end;
    K_UPARROW:
    begin
      dec(m^.cursor); 
      Menu_AdjustCursor(m,-1); 
    end;
    K_DOWNARROW:
    begin
      inc(m^.cursor); 
      Menu_AdjustCursor(m,1); 
    end;
    K_LEFTARROW:
    begin
      Menu_SlideItem(m,-1); 
    end;
    K_RIGHTARROW:
    begin
      Menu_SlideItem(m,1); 
    end;
    K_ENTER:
    begin
      Menu_SelectItem(m); 
    end;
    
  end;{case?}
  
  
    result:= sound; 
end;



end.
