unit vid_so;

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
(* Main windowed and fullscreen graphics interface module. This module*)
(* is used for both the software and OpenGL rendering versions of the*)
(* Quake refresh engine.*)

interface
uses q_shared_add, ref, vid_h ,q_shared,
        libc ,
        keys,
        rw_linux_h;


{.$include <assert.h>}
{.$include <dlfcn.h>  // ELF dl loader}
{.$include <sys/stat.h>}
{.$include <unistd.h>}
{.$include <errno.h>}

{.$include "../client/client.h"}

{.$include "../linux/rw_linux.h"}

type
vidmode_t = record
description: pchar; 
width: integer; 
height: integer; 
mode: integer; 
end;
vidmode_p = ^vidmode_t;

var
(* Structure containing functions exported from refresh DLL*)
re: refexport_t;
 
(* Console variables that we need to access from this module*)
vid_gamma: cvar_p; 
vid_ref:   cvar_p; (* Name of Refresh DLL loaded*)
vid_xpos:  cvar_p; (* X coordinate of window position*)
vid_ypos:  cvar_p; (* Y coordinate of window position*)
vid_fullscreen: cvar_p;
 
(* Global variables used internally by this module*)
viddef: viddef_t; (* global video state; used by other modules*)
reflib_library: Pointer ;//pinteger; (* Handle to refresh DLL *)
// reflib_library: LongWord; in windows
reflib_active: qboolean = False;

vid_modes: array [0..13] of vidmode_t = (
    (description: 'Mode 0: 320x240'; width: 320; height: 240; mode: 0),
    (description: 'Mode 1: 400x300'; width: 400; height: 300; mode: 1),
    (description: 'Mode 2: 512x384'; width: 512; height: 384; mode: 2),
    (description: 'Mode 3: 640x480'; width: 640; height: 480; mode: 3),
    (description: 'Mode 4: 800x600'; width: 800; height: 600; mode: 4),
    (description: 'Mode 5: 960x720'; width: 960; height: 720; mode: 5),
    (description: 'Mode 6: 1024x768'; width: 1024; height: 768; mode: 6),
    (description: 'Mode 7: 1152x864'; width: 1152; height: 864; mode: 7),
    (description: 'Mode 8: 1280x960'; width: 1280; height: 960; mode: 8),
    (description: 'Mode 9: 1600x1200'; width: 1600; height: 1200; mode: 9),
    (description: 'Mode 10: 2048x1536'; width: 2048; height: 1536; mode: 10),
    (description: 'Mode 11: 1024x480'; width: 1024; height: 480; mode: 11), //* Sony VAIO Pocketbook */
    (description: 'Mode 12: 1152x768'; width: 1152; height: 768; mode: 12), //* Apple TiBook */
    (description: 'Mode 13: 1280x854'; width: 1280; height: 854; mode: 13)  //* Apple TiBook */
    );

const
VID_NUM_MODES = (sizeof(vid_modes) div sizeof(vid_modes[0]));

//so_file: array [0..Pred(17)] of char = '/etc/quake2.conf';
 
(** KEYBOARD **************************************************************)


procedure Do_Key_Event(key: integer;  down: qboolean); 

var
KBD_Update_fp : function :pointer ;cdecl ;
KBD_Init_fp   : function (fp :Key_Event_fp_t ):pointer ;cdecl;
KBD_Close_fp  : function :pointer ;cdecl ;
//void(*KBD_Update_fp) (void); 
//void(*KBD_Init_fp)(Key_Event_fp_t fp); 
//void(*KBD_Close_fp)(void);



(** MOUSE *****************************************************************)

var
in_stat: in_state_t;  //changed from in_state  to  in_stat to avoid confusion ... by FAB

RW_IN_Init_fp :function (in_state_p :Pin_state_t ):pointer ; cdecl;
RW_IN_Shutdown_fp :function : pointer ;cdecl ;
RW_IN_Activate_fp :function (active : qboolean):pointer; cdecl;
RW_IN_Commands_fp :function : pointer ;cdecl ;
RW_IN_Move_fp :function (cmd : usercmd_p):pointer;cdecl ;
RW_IN_Frame_fp :function : pointer ;cdecl ;

//void (*RW_IN_Init_fp)(in_state_t *in_state_p);
//void (*RW_IN_Shutdown_fp)(void);
//void (*RW_IN_Activate_fp)(qboolean active);
//void (*RW_IN_Commands_fp)(void);
//void (*RW_IN_Move_fp)(usercmd_t *cmd);
//void (*RW_IN_Frame_fp)(void);

//** CLIPBOARD *************************************************************/
RW_Sys_GetClipboardData_fp : function :PChar ;cdecl;
//char *(*RW_Sys_GetClipboardData_fp)(void);

//*==========================================================================

procedure Real_IN_Init();
procedure VID_Printf(print_level: integer;  fmt: pchar; args: array of const );
procedure VID_Error(err_level: integer;  fmt: pchar; args: array of const);
procedure VID_CheckChanges();
procedure VID_Init();
procedure VID_Shutdown();
procedure IN_Frame();
procedure IN_Init();
procedure IN_Commands();
procedure IN_Shutdown();
function VID_CheckRefExists (ref : PChar): qboolean ;
function Sys_GetClipboardData :PChar ;
(*
==========================================================================

DLL GLUE

==========================================================================
*)

const
MAXPRINTMSG = 4096; 

implementation

 uses Common, SysUtils, sys_linux, cmd, files, Cvar,
      vid_menu ,cl_input, client , Console ,q_shlinux ,
      cl_main ,snd_dma;

var {was static}
inupdate: qboolean; 

procedure VID_Printf(print_level: integer;  fmt: pchar; args: array of const );
var
//argptr: va_list; 
msg: array [0..Pred(MAXPRINTMSG)] of char; 
begin
  {
  va_start(argptr,fmt); 
  vsprintf(msg,fmt,argptr); 
  va_end(argptr); 
  }
  DelphiStrFmt(msg, fmt, args);
  
  if print_level = PRINT_ALL then
  	 Com_Printf('%s', [msg])
  else
  	 Com_DPrintf('%s', [msg]);
end;


//var {was static}
//inupdate: qboolean; 

procedure VID_Error(err_level: integer;  fmt: pchar; args: array of const);
var
//argptr: va_list;
msg: array [0..Pred(MAXPRINTMSG)] of char; 
begin
  
  { 
  va_start(argptr,fmt); 
  vsprintf(msg,fmt,argptr); 
  va_end(argptr);
  }
  DelphiStrFmt(msg, fmt, args);
   
  Com_Error(err_level,'%s',[msg]); 
  
end;

(*==========================================================================*)
(*
============
VID_Restart_f

Console command to re-start the video mode and refresh DLL. We do this
simply by setting the modified flag for the vid_ref variable, which will
cause the entire video mode and refresh DLL to be reset on the next frame.
============
*)

procedure VID_Restart_f(); cdecl; 
begin
  vid_ref^.modified:= true; 
end;

(*
** VID_GetModeInfo
*)


function VID_GetModeInfo(width: pinteger;  height: pinteger;  mode: integer): qboolean; 
begin
  if (mode < 0) or (mode >= VID_NUM_MODES) then
  begin
    result:= false; 
    exit;  
  end;
  
  {*}width^:=vid_modes[mode].width; 
  {*}height^:=vid_modes[mode].height; 
  
  
   result:= true; 
  
end;

(*
** VID_NewWindow
*)

procedure VID_NewWindow(width: integer;  height: integer); 
begin
  viddef.width:= width; 
  viddef.height:= height; 
end;


procedure VID_FreeReflib(); 
begin
  if reflib_library <> nil then
  begin
    if KBD_Close_fp <> nil  then
    KBD_Close_fp();
    if RW_IN_Shutdown_fp <> nil then
    RW_IN_Shutdown_fp();
    dlclose(reflib_library);
	// FreeLibrary (reflib_library) ---- in windows
  end;

  KBD_Init_fp := nil;
  KBD_Update_fp:= nil;
  KBD_Close_fp:= nil;
  RW_IN_Init_fp:= nil;
  RW_IN_Shutdown_fp:= nil;
  RW_IN_Activate_fp:= nil;
  RW_IN_Commands_fp:= nil;
  RW_IN_Move_fp:= nil;
  RW_IN_Frame_fp:= nil;
  RW_Sys_GetClipboardData_fp := nil ;
  
  //memset (&re, 0, sizeof(re));
  FillChar(re, SizeOf(re), 0);

  reflib_library:= nil;
  reflib_active:= false;
end;

(*
==============
VID_LoadRefresh
==============
*)

function VID_LoadRefresh(name: pchar): qboolean; 
var
ri: refimport_t; 
GetRefAPI: GetRefAPI_t;
fn: array [0..Pred(MAX_OSPATH)] of char;
st : TstatBuf;
path : PChar;
//fp: PIOFile ;//File ;
begin 
  
  {saved_euid: uid_t; }{<= !!!5 external variable}
  
  if reflib_active then
  begin 
    if KBD_Close_fp<> nil then
    KBD_Close_fp();
    if RW_IN_Shutdown_fp<> nil then
    RW_IN_Shutdown_fp();
    KBD_Close_fp:= nil;
    RW_IN_Shutdown_fp:= nil;
    re.Shutdown(); 
    VID_FreeReflib(); 
  end;
  
  Com_Printf('------- Loading %s -------'#10, [name]);
  
  (*regain root*)
  seteuid(saved_euid); 
  

  //fp := fopen(so_file,'r');  // a libc.pas function
  //if fp = nil then
  path := Cvar_Get ('basedir', '.', CVAR_NOSET)^.string_;

  snprintf (fn, MAX_OSPATH, '%s/%s', path, name );
  
  if (stat (fn , st) = -1) then
  begin 
    Com_Printf('LoadLibrary(''%s'') failed: %s'#10, [name, strerror(errno)]);
    result:= false;
    exit;  
  end;
  
  //fgets(fn, sizeof(fn), fp); 
  //fclose(fp);
   
  //while ( fn <> nil) and (isspace(StrtoInt(fn[ strlen(fn) - 1])) <> 0)
  //do
  //fn[ strlen(fn)-1]:= #0;
  
   
  //strcat(fn,'/'); 
  
  //strcat(fn,name); 
  
  (* permission checking*)
  if ((strstr(fn,'softx')= nil)and (strstr(fn,'glx')= nil)and (strstr(fn,'softsdl')= nil)
     and (strstr(fn,'sdlgl')= nil))  then
  begin 
    // softx requires we give up root now
    setreuid(getuid(), getuid());
	setegid(getgid());
  end;	
   reflib_library := dlopen (fn , RTLD_LAZY) ; 
   if (reflib_library  = nil) then
    begin
	Com_Printf( 'LoadLibrary(''%s'') failed: %s'#10, [name , dlerror()]);
	result := False ;
	exit;
	end;

{$if false}// disabled code
   { if st.st_uid<>0 then
    begin 
      Com_Printf('LoadLibrary("%s") failed: ref is not owned by root'#13#10'',name); 
      begin
        result:= false; 
        exit;
      end;
    end;
    if (st.st_mode and $1FF) and  not $1C0
    then
    begin 
      Com_Printf('LoadLibrary("%s") failed: invalid permissions, must be 700 for security considerations'#13#10'',name); 
      
      result:= false; 
      exit;
    end;
    }
{$ifend}//end of disabled code

  
  
  Com_Printf('LoadLibrary(''%s'')'#10, [fn]);

  ri.Cmd_AddCommand:= Cmd_AddCommand;
  ri.Cmd_RemoveCommand:= Cmd_RemoveCommand; 
  ri.Cmd_Argc:= Cmd_Argc; 
  ri.Cmd_Argv:= Cmd_Argv; 
  ri.Cmd_ExecuteText:= Cbuf_ExecuteText; 
  ri.Con_Printf:= @VID_Printf;
  ri.Sys_Error:= @VID_Error;
  ri.FS_LoadFile:= FS_LoadFile; 
  ri.FS_FreeFile:= FS_FreeFile; 
  ri.FS_Gamedir:= FS_Gamedir; 
  ri.Cvar_Get:= Cvar_Get; 
  ri.Cvar_Set:= Cvar_Set; 
  ri.Cvar_SetValue:= Cvar_SetValue; 
  ri.Vid_GetModeInfo:= @VID_GetModeInfo;
  ri.Vid_MenuInit:= @VID_MenuInit;
  ri.Vid_NewWindow:= @VID_NewWindow;
  
  {$IFDEF QMAX}
  ri.SetParticlePics := SetParticleImages;
  {$ENDIF}
  
  //GetRefApi := GetProcAddress(reflib_library, 'GetRefAPI'); ---in windows
  GetRefApi := dlsym(reflib_library, 'GetRefAPI');
  if not Assigned (GetRefAPI) then
  Com_Error(ERR_FATAL,'dlsym failed on %s', [name]);
   
  re:= GetRefAPI(ri); 
  
  if re.api_version <> API_VERSION then
  begin 
    VID_FreeReflib();
    Com_Error(ERR_FATAL,'%s has incompatible api_version', [name]);
  end;
  
  (* Init IN (Mouse) *)
  // changed in_state to in_stat ... by fab
  in_stat.IN_CenterView_fp:= @IN_CenterView;
  in_stat.Key_Event_fp:= Do_Key_Event;
  in_stat.viewangles:= @cl.viewangles;
  in_stat.in_strafe_state:= @in_strafe.state;

  RW_IN_Init_fp := dlsym(reflib_library, 'RW_IN_Init');
  RW_IN_Shutdown_fp := dlsym(reflib_library, 'RW_IN_Shutdown');
  RW_IN_Activate_fp := dlsym(reflib_library, 'RW_IN_Activate');
  RW_IN_Commands_fp := dlsym(reflib_library, 'RW_IN_Commands');
  RW_IN_Move_fp := dlsym(reflib_library, 'RW_IN_Move');
  RW_IN_Frame_fp := dlsym(reflib_library, 'RW_IN_Frame');
  if ((not assigned (RW_IN_Init_fp) )
  	 or((RW_IN_Shutdown_fp =nil) or(not Assigned(RW_IN_Activate_fp))
	 or(RW_IN_Commands_fp =nil) or(not Assigned (RW_IN_Move_fp))
	 or(RW_IN_Frame_fp =nil))) then
  Sys_Error('No RW_IN functions in REF.'#10,[]);
  
  //* this one is optional */
  RW_Sys_GetClipboardData_fp := dlsym(reflib_library, 'RW_Sys_GetClipboardData');
  
  Real_IN_Init(); 
  
  
  if (re.Init(0,nil)= -1) then
  begin 
    re.Shutdown(); 
    VID_FreeReflib(); 
    
    result:= false; 
    exit;  
  end;
  
  (* Init KBD *)
{$ifdef 1}
  if (KBD_Init_fp:=dlsym(reflib_library,'KBD_Init'))=0{nil})or
     ((KBD_Update_fp:=dlsym(reflib_library,'KBD_Update'))=0{nil})or
     ((KBD_Close_fp:=dlsym(reflib_library,'KBD_Close'))=0{nil}
  then
  Sys_Error('No KBD functions in REF.'#13#10'');
{$else}
  begin 
    
    //procedure KBD_Init();

    //procedure KBD_Update();

    //procedure KBD_Close();
    
    //KBD_Init_fp:= KBD_Init;
    //KBD_Update_fp:= KBD_Update;
    //KBD_Close_fp:= KBD_Close;
  end;
{$endif}

  KBD_Init_fp(Do_Key_Event);
  
  Key_ClearStates();
  
  (* give up root now*)
  setreuid(getuid(),getuid()); 
  
  setegid(getgid()); 
  Com_Printf('------------------------------------'#10); 
  
  reflib_active:= true; 
  
 result:= true; 
end;

(*
============
VID_CheckChanges

This function gets called once just before drawing each frame, and it's sole purpose in life
is to check to see if any of the video mode parameters have changed, and if they have to 
update the rendering DLL and/or video mode to match.
============
*)

procedure VID_CheckChanges();
var
name: array [0..Pred(100)] of char; 
sw_mode: cvar_p; 
begin
  
  if vid_ref^.modified then
  begin 
    S_StopAllSounds();
  end;
  
  while vid_ref^.modified = true
  do
  begin 
    (*** refresh has changed*)
	
    vid_ref^.modified:= false; 
    vid_fullscreen^.modified:= true; 
    cl.refresh_prepped:= false;
    cls.disable_screen:= integer(true); 
	 
    sprintf(name,'ref_%s.so',vid_ref^.string_);
	//Com_sprintf(name, SizeOf(name), 'ref_%s.so', [vid_ref^.string_]);
    
    if (not VID_LoadRefresh(name)) then
    begin 
      if (strcmp(vid_ref^.string_,'soft')=0) or (strcmp(vid_ref^.string_,'softx')=0) then
      begin 
        Com_Printf('Refresh failed'#10); 
        sw_mode:= Cvar_Get('sw_mode','0',0); 
        if sw_mode^.value <> 0 then
        begin 
          Com_Printf('Trying mode 0'#10); 
          Cvar_SetValue('sw_mode',0);
		   
          if (not VID_LoadRefresh(name)) then
          Com_Error(ERR_FATAL,'Couldn''t fall back to software refresh!'); 
        end
        else
        Com_Error(ERR_FATAL,'Couldn''t fall back to software refresh!'); // ' --> #39 by fab
      end;
      //* prefer to fall back on X if active */
	  if (getenv ('DISPLAY')<> nil) then
	     CVar_Set ('vid_ref' , 'softx')
		else 
	     Cvar_Set('vid_ref','soft'); 
      
      
      (*
         ** drop the console if we fail to load a refresh
         *)
      if cls.key_dest <> key_console then

      Con_ToggleConsole_f();
      
    end;
    cls.disable_screen:= Integer(false); 
  end;
end;


(*
============
VID_Init
============
*)

procedure VID_Init();
begin
  (* Create the video variables so we know how to start the graphics drivers *)
  (* if DISPLAY is defined, try X*)

  if getenv('DISPLAY') <> nil then
  vid_ref:= Cvar_Get('vid_ref','softx',CVAR_ARCHIVE) 
  else
  vid_ref:= Cvar_Get('vid_ref','soft',CVAR_ARCHIVE);
   
  vid_xpos:= Cvar_Get('vid_xpos','3',CVAR_ARCHIVE); 
  vid_ypos:= Cvar_Get('vid_ypos','22',CVAR_ARCHIVE); 
  vid_fullscreen:= Cvar_Get('vid_fullscreen','0',CVAR_ARCHIVE); 
  vid_gamma:= Cvar_Get('vid_gamma','1',CVAR_ARCHIVE);
  
  (* Add some console commands that we want to handle *) 
  Cmd_AddCommand('vid_restart',VID_Restart_f);
  
  (* Disable the 3Dfx splash screen *) 
  putenv('FX_GLIDE_NO_SPLASH=0'); 
  
  (* Start the graphics mode and load refresh DLL *)
  VID_CheckChanges(); 
  
end;

(*
============
VID_Shutdown
============
*)

procedure VID_Shutdown();
begin
  if reflib_active then
  begin 
    if KBD_Close_fp <> nil  then
    KBD_Close_fp();
    if RW_IN_Shutdown_fp <> nil  then
    RW_IN_Shutdown_fp();
    KBD_Close_fp:= nil;
    RW_IN_Shutdown_fp:= nil;
    re.Shutdown();
    VID_FreeReflib();
  end;
  VID_MenuShutdown();
end;


(*****************************************************************************)
(* VID_CheckRefExists                                                        *)
(*                                                                           *)
(* Checks to see if the given ref_NAME.so exists.                            *)
(* Placed here to avoid complicating other code if the library .so files     *)
(* ever have their names changed.                                            *)
(*****************************************************************************)

function VID_CheckRefExists (ref : PChar): qboolean ;
var
fn: array [0..Pred(MAX_OSPATH)] of char;
st : TstatBuf;
path : PChar;

begin
  path := Cvar_Get ('basedir' , '.' , CVAR_NOSET )^.string_ ;
  
  snprintf (fn, MAX_OSPATH, '%s/ref_%s.so', path, ref );
  
  if (stat (fn , st ) = 0) then
     begin
	 result := true ;
	 exit;
	 end
	 else
	 result := false ;
	 exit;

end;
  


(*****************************************************************************)
(* INPUT                                                                     *)
(*****************************************************************************)

var
in_joystick: cvar_p;

 
(* This is fake, it's acutally done by the Refresh load*)
procedure IN_Init();
begin
  in_joystick:= Cvar_Get('in_joystick','0',CVAR_ARCHIVE); 
end;


procedure Real_IN_Init(); 
begin
  if Assigned (RW_IN_Init_fp)  then
  RW_IN_Init_fp (@in_stat);
end;


procedure IN_Shutdown();
begin
  if RW_IN_Shutdown_fp<> nil then
  RW_IN_Shutdown_fp();
end;


procedure IN_Commands();
begin
  if Assigned (RW_IN_Commands_fp) then
  RW_IN_Commands_fp();
end;


procedure IN_Move(cmd: usercmd_p); 
begin
  if Assigned (RW_IN_Move_fp) then
  RW_IN_Move_fp(cmd);
end;


procedure IN_Frame();
begin
  if Assigned (RW_IN_Activate_fp) then
  begin
    if (not cl.refresh_prepped) or (cls.key_dest = key_console) or (cls.key_dest = key_menu) then
    RW_IN_Activate_fp(false)
    else
    RW_IN_Activate_fp(true);
  end;
  
  if RW_IN_Frame_fp <> nil then
  RW_IN_Frame_fp();
end;


procedure IN_Activate(active: qboolean); 
begin
end;


procedure Do_Key_Event(key: integer;  down: qboolean); 
begin
  Key_Event(key, down, Sys_Milliseconds());
end;

function Sys_GetClipboardData :PChar ;
begin
 if (RW_Sys_GetClipboardData_fp <> nil) then
     result := RW_Sys_GetClipboardData_fp()
	else
	result := nil;
	  
end;

end.
