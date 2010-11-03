unit sys_linux;

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

uses q_shared_add , SysUtils , Common;

{.$include <unistd.h>}
{.$include <signal.h>}
{.$include <stdlib.h>}
{.$include <limits.h>}
{.$include <sys/time.h>}
{.$include <sys/types.h>}
{.$include <unistd.h>}
{.$include <fcntl.h>}
{.$include <stdarg.h>}
{.$include <stdio.h>}
{.$include <sys/ipc.h>}
{.$include <sys/shm.h>}
{.$include <sys/stat.h>}
{.$include <string.h>}
{.$include <ctype.h>}
{.$include <sys/wait.h>}
{.$include <sys/mman.h>}
{.$include <errno.h>}
{.$include <mntent.h>}

{.$include <dlfcn.h>}

{.$include "../qcommon/qcommon.h"}

{.$include "../linux/rw_linux.h"}

var
stdout : PIOFile ; // added by FAB
nostdout: cvar_p;
sys_frame_time: Cardinal ;//UINT;
saved_euid: uid_t;
stdin_active: qboolean = true;
//var {was static}
game_library: pointer; //  ---- HINST in windows
checked: qboolean;

procedure Sys_ConsoleOutput(_string: pchar);
procedure Sys_Error(error: PChar; args: array of const);
procedure Sys_Quit;
procedure Sys_Init;
procedure Sys_Warn(warning: pchar; args: array of const);
function Sys_FileTime(path: pchar): integer;
function Sys_ConsoleInput: PChar;
procedure Sys_Unloadgame;
procedure Sys_SendKeyEvents;
procedure Sys_AppActivate;
function main(argc: integer; argv: pchar): integer;
//function Sys_GetClipboardData: PChar;
//procedure Sys_CopyProtect;
function Sys_GetGameAPI(parms: Pointer): Pointer ;


(* =======================================================================*)
(* General routines*)
(* =======================================================================*)

implementation

uses q_shlinux,q_shared,cpas,cl_main,Cvar,Classes ,
      Files,SysUtils , vid_so ;

procedure Sys_ConsoleOutput(_string: pchar);
begin
  if (nostdout <> nil) and (nostdout^.value <> 0) then
  exit;

  //fputs(_string, stdout); //original
  puts (_string );          // changed by FAB
end;


procedure Sys_Printf(fmt: pchar; args: array of const ); 
var
//argptr: va_list;
text: array [0..Pred(1024)] of char; 
p: pchar; 
begin
  

  //va_start(args,fmt);
  //vsprintf(text,fmt,argptr);
  //vsnprintf (text,1024,fmt,argptr);
  //va_end(argptr);
  DelphiStrFmt(text, fmt, args);

  //if strlen(text) > sizeof(text) then
  //Sys_Error('memory overwrite in Sys_Printf',[]);
  
  if (nostdout <> nil) and (nostdout^.value <> 0) then
  exit;  
  
  // for (p = (unsigned char *)text; *p; p++)
  p:= text; 
  
  while p <> #0  do
  begin 
     p^ := Chr(StrToInt(p^) and $7f);
     //p^ := p^ and $7f ;

    if ( ord(p^) > 128) or (( Ord(p^) < 32) and ( Ord(p^) <> 10) and ( Ord(p^) <> 13) and( Ord(p^) <> 9))
    then
    printf('[%02x]', p^ )
    else
    putc( StrToInt(p^), stdout);
	
    inc(p);
  end;
end;


procedure Sys_Quit(); 
begin
  CL_Shutdown();
  Qcommon_Shutdown();

  fcntl(0, F_SETFL, fcntl(0, F_GETFL, 0) and  not FNDELAY);
  _exit(0);
end;


procedure Sys_Init();
begin
  {$if id386}
  (* Sys_SetFPCW();*)
  {$ifend}
end;


procedure Sys_Error(error: pchar; args: array of const ); 
var
//argptr: va_list;
_string: array [0..Pred(1024)] of char;
//stderr : TStream ; //PIOFile ; //added by FAB
begin
  (* change stdin to non blocking*)
  fcntl(0, F_SETFL, fcntl(0, F_GETFL, 0) and  not FNDELAY); 
  CL_Shutdown(); 
  
  Qcommon_Shutdown();

  //va_start(argptr,error);
  //vsprintf(_string,error,argptr);
  //vsnprintf (text,1024,error,argptr);
  //va_end(argptr);
  DelphiStrFmt(_string, error, args);

   //fprintf(stderr,'Error: %s'#10,_string); // original
   printf ('Error : %s'#10 , _string);       // changed by FAB
   
  _exit(1); 
  
end;


// is possible to disable this procedure since is not used ...by FAB
procedure Sys_Warn(warning: pchar; args: array of const ); 
var
//argptr: va_list;
_string: array [0..Pred(1024)] of char;
stderr : PIOFile ; //added by FAB
begin
  

  //va_start(argptr,warning);
  //vsprintf(_string,warning,argptr);
  //vsnprintf (string,1024,warning,argptr);
  //va_end(argptr);
  DelphiStrFmt(_string, warning , args);

  fprintf(stderr,'Warning: %s',_string);
end;

(*
============
Sys_FileTime

returns -1 if not present
============
*)
 

function Sys_FileTime(path: pchar): integer;
var
 i : integer;
 buf :TStatBuf ;
begin

   i:= stat(path , buf);

  //if stat(path, @buf) = -1 then
  if i = -1 then
  begin
    result:= -1; 
    exit;
  end;
 
  result:= buf.st_mtime;
   
end;


procedure floating_point_exception_handler(whatever: integer); 
begin
   signal(SIGFPE, @floating_point_exception_handler);
  (* Sys_Warn("floating point exception\n");*)
end;

 

function Sys_ConsoleInput(): pchar; 

var
text: array [0..Pred(256)] of char; {was static}
len: integer; 
fdset: TFdSet ;//fd_set;
timeout : timeval;
begin
   
  if (dedicated = nil) or(dedicated^.value = 0) then
  begin
    result:= nil; 
    exit;   
  end;
  
  if not stdin_active then
  begin
    result:= nil; 
    exit;  
  end;
  
  FD_ZERO( fdset);
  FD_SET(0, fdset); (* stdin*)
  timeout.tv_sec:= 0;
  timeout.tv_usec:= 0; 
  
  if (select(1, @fdset, nil, nil,@timeout) = -1) or (not FD_ISSET(0, fdset)) then
  begin
    result:= nil; 
    exit;  
  end;

  len:= __read(0, text, sizeof(text));
   
  if len =0 then  (* eof!*)
  begin  
    stdin_active:= false; 
    result:= nil; 
    exit;
  end;
  
  if len < 1 then
  begin
    result:= nil; 
    exit;
  end;
  
  text[len-1]:= #0; (* rip off the /n and terminate*)
  
  result:= text; 
    
end;

(*****************************************************************************)
(*
=================
Sys_UnloadGame
=================
*)


procedure Sys_UnloadGame(); 
begin
  if game_library <> nil  then
  dlclose(game_library);
   
  game_library:= nil; 
end;

(*
=================
Sys_GetGameAPI

Loads the game dll
=================
*)
// in win ---function Sys_GetGameAPI(parms: Pointer): Pointer;
function Sys_GetGameAPI(parms: Pointer): Pointer ;
const
gamename: pchar = 'gamei386.so';

var
GetGameAPI: function(parms: Pointer): Pointer; cdecl;
name: array [0..Pred(MAX_OSPATH)] of char;
fp : PIOFile ;
str_p : PChar ; 
//curpath: array [0..Pred(MAX_OSPATH)] of char; 
path: pchar;

begin

  setreuid(getuid(),getuid()); 
  setegid(getgid()); 
  
  if game_library <> nil  then
  Com_Error(ERR_FATAL,'Sys_GetGameAPI without Sys_UnloadingGame');
   
  //getcwd(curpath, sizeof(curpath)); 
  
  Com_Printf('------- Loading %s -------'#10, [gamename]);
  
  path:= nil; 
  (* now run through the search paths*)
  while True // (1)
  do
  begin 
    path:= FS_NextPath(path);
    if {not} path= nil then
    begin
      result:= nil;(* couldn't find one anywhere*)
      exit;
    end;
    //sprintf(name,'%s/%s/%s', curpath, path, gamename);
	////////////
	snprintf (name, MAX_OSPATH, '%s/%s', path, gamename);
	fp := fopen (name ,'rb');
	if fp = nil then
	   	  continue;
	fclose (fp);
	///////////////
	 
    
	//game_library:= dlopen(name, RTLD_LAZY);
	game_library:= dlopen(name, RTLD_NOW);
	// on win ---game_library := LoadLibrary(name);
	 
    if game_library <> nil  then
	begin
	   //Com_MDPrintf ('LoadLibrary (%s)'#10 ,[name]);
           Com_Printf('LoadLibrary (%s)'#10, [name]);
	   break;
	end
	else
    begin 
      Com_Printf('LoadLibrary (%s):'#10, [name]);

	  path := dlerror ();
	  str_p := strchr (path , Ord(':')); // skip the path (already shown)
	  if str_p = nil then 
	     str_p := path 
	  else
	     inc(str_p);
	  Com_Printf ('%s'#10, [str_p]);
	   result := nil ;
	   exit; //??
    end;
  end;
  // on win --- GetGameAPI := GetProcAddress(game_library, 'GetGameAPI');
  GetGameAPI:=  dlsym(game_library,'GetGameAPI'); 
  
  if not Assigned (GetGameAPI) then
  begin 
    Sys_UnloadGame(); 
    result:= nil; 
    exit;
  end;
  
  result:= GetGameAPI(parms);   
end;

(*****************************************************************************)


procedure Sys_AppActivate(); 
begin
end;


procedure Sys_SendKeyEvents(); 
begin
{$ifndef DEDICATED_ONLY}
  if KBD_Update_fp <> nil then
  KBD_Update_fp();
{$endif}

  (* grab frame time *)
  sys_frame_time:= Sys_Milliseconds(); 
  
end;

(*****************************************************************************)


//function Sys_GetClipboardData(): pchar; 
//begin  
//result:= nil;  
//end;

// int main (int argc, char **argv)
function main(argc: integer; argv: pchar): integer;
var
time: integer; 
oldtime: integer;
newtime: integer; 

begin
  
  (* go back to real user for config loads*)
  saved_euid:= geteuid(); 
  seteuid(getuid());
  /////////////
  //printf ('Quake 2 -- Version %s'#10, [LINUX_VERSION]);
  printf ('Quake 2 -- Version 3.21 Kylix'#10,[]);  //changed by FAB
  /////////
  
  Qcommon_Init(argc,@argv);
  
  fcntl(0,F_SETFL,fcntl(0,F_GETFL,0) or FNDELAY); 
  
  nostdout:= Cvar_Get('nostdout','0',0);
  if nostdout^.value =0 then
  begin 
    fcntl(0,F_SETFL,fcntl(0,F_GETFL,0) or FNDELAY);
	(*  printf ("Linux Quake -- Version %0.3f\n", LINUX_VERSION);*) 
  end;
  
  oldtime:= Sys_Milliseconds(); 
  while True // (1)
   do
  begin 
    (* find time spent rendering last frame*)
    repeat
    
      newtime:= Sys_Milliseconds(); 
      time:= newtime-oldtime; 
    
    //until not {0=}(time<1);
	until (time >= 1);
	
    Qcommon_Frame(time); 
    oldtime:= newtime; 
  end;
  // on win --- Result := 1;
  result := 1;  // added by FAB
end;


{$IFDEF False} 
 
procedure Sys_CopyProtect(); 
//type
//ent = pmntent ; //struct mntent *ent;
//st = stat;

var
mnt: PIOFile ;  //pFILE;
path: array [0..Pred(MAX_OSPATH)] of char; 
found_cd: qboolean;
st : TStatBuf;
ent :PMountEntry;
begin
  
  found_cd:=false; 
  checked:=false;
   
  if checked  then
  exit;

  mnt := setmntent('/etc/mtab','r') ;
  if (mnt = nil) then
  Com_Error(ERR_FATAL,'Can''t read mount table to determine mounted cd location.'); 
  
 
  ent:=getmntent(mnt);
  
  while ent <> nil do
  begin 
    if strcmp(ent^.mnt_type,'iso9660') =0 then
    begin 
      (* found a cd file system*)
      found_cd:= true; 
      sprintf(path,'%s/%s', ent^.mnt_dir,'install/data/quake2.exe'); 
      if stat(path, st)=0 then
      begin 
        (* found it*)
        checked:= true; 
      	endmntent(@mnt);
      	exit;
      end;
	  
    sprintf(path,'%s/%s', ent^.mnt_dir, 'Install/Data/quake2.exe'); 
    if stat(path, st) = 0 then
    begin 
      (* found it*)
    checked:= true; 
    endmntent(@mnt);
    exit;
    end;
  sprintf(path, '%s/%s', ent^.mnt_dir, 'quake2.exe'); 
  if stat(path,st) = 0 then
  begin 
    (* found it*)
  checked:= true; 
  endmntent(@mnt);
  exit;
  end;
end;
end;
endmntent(@mnt); 

if (found_cd) then   
Com_Error(ERR_FATAL,'Could not find a Quake2 CD in your CD drive.'); 
Com_Error(ERR_FATAL,'Unable to find a mounted iso9660 file system.'#10'You must mount the Quake2 CD in a cdrom drive in order to play.'); 
end;
{$ENDIF}


{.$if 0} // originally disabled code
(*
================
Sys_MakeCodeWriteable
================
*)
{
procedure Sys_MakeCodeWriteable(startaddr: UINT;  length: UINT); 
var
r: integer; 
addr: UINT; 
psize: integer;
 
begin
  
  
  psize:=getpagesize(); 
  addr:= (startaddr and  not (psize-1))-psize; 
  r:= mprotect({!!!a type cast? =>} {pchar(addr,length+startaddr-addr+psize,7); 
  (* fprintf(stderr, "writable code %lx(%lx)-%lx, length=%lx\n", startaddr,*)
  (*   addr, startaddr+length, length);*)
{  
  if r<0
  then
  Sys_Error('Protection change failed'#13#10''); 
end;

}
{.$endif}

end.
