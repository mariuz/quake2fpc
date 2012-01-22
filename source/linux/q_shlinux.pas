unit q_shlinux;

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

{.$include "../linux/glob.h"}

{.$include "../qcommon/qcommon.h"}

(*===============================================================================*)
var
membase: pbyte;
maxhunksize: integer; 
curhunksize: integer; 
var
curtime: integer;  // global var

function Sys_Milliseconds : integer;
procedure Sys_Mkdir(path: pchar);
function Sys_FindFirst(path: pchar;  musthave: Cardinal;  canhave: Cardinal): pchar;
function Sys_FindNext(musthave: Cardinal;  canhave: Cardinal): pchar;
procedure Sys_FindClose ;


implementation

uses SysUtils, q_shared_add, q_shared, Common, cpas, sys_linux , glob , baseunix, unix ;


function Hunk_Begin(maxsize: integer):integer;
begin
  (* reserve a huge chunk of memory, but don't commit any yet*)
  maxhunksize:= maxsize + sizeof(integer); 
  curhunksize:= 0;
  membase:= fpmmap(nil, maxhunksize, (PROT_READ or PROT_WRITE),(MAP_PRIVATE or MAP_ANONYMOUS), -1, 0);
  
  if (membase = nil)or(membase = PByte(-1)) then
  Sys_Error('unable to virtual allocate %d bytes',[maxsize]);
  Integer(membase):= curhunksize;
  
  
  result:= Integer(membase) + sizeof(integer);
    
end;


function Hunk_Alloc(size: integer):PByte;
var
buf: pbyte; 
(* round to cacheline*)
begin
  size:= (size+31) and (not 31); 
  if ((curhunksize + size) > maxhunksize ) then
  Sys_Error('Hunk_Alloc overflow',[]);
  buf:= PByte(Integer(membase) + sizeof(integer)+ curhunksize);
  curhunksize:= curhunksize + (size); 
  result:= buf;
    
end;


function Hunk_End(): integer; 
var
n: pbyte; 
begin
  n:= fpremap(membase,maxhunksize,curhunksize+sizeof(integer),0);
  if n <> membase then
  Sys_Error('Hunk_End:  Could not remap virtual block (%d)', [errno]); 
  //*({!!!a type cast? =>} {pinteger(}membase):=curhunksize+sizeof(int);
  Integer(membase) := curhunksize + sizeof(integer);
  result:= curhunksize; 
    
end;


procedure Hunk_Free(base: pointer); 
var
m: pbyte; 
begin
  if base<> nil  then
  begin
    //m:= ({!!!a type cast? =>} {pbyte(}base)-sizeof(int);
    m := PByte(Integer(base) - sizeof(Integer));
    //if munmap(m,*({!!!a type cast? =>} {pinteger(}m))
    if fpmunmap (m , Integer(m))<> 0 then
    Sys_Error('Hunk_Free: munmap failed (%d)',[errno]); 
  end;
end;

(*===============================================================================*)

(*
================
Sys_Milliseconds
================
*)
//type
//timeval = tp
//end;
//timezone = tzp
//end;
//var {was static}
//secbase: integer; 

function Sys_Milliseconds(): integer; 
var
secbase: integer; {was static}
tp :Timeval;
tzp :Timezone;
begin

  gettimeofday(tp,tzp);

  if secbase = 0 then
  begin 
    secbase:= tp.tv_sec; 
    result:= tp.tv_usec div 1000; 
    exit; 
  end;
  
  curtime:= (tp.tv_sec - secbase) * 1000 + tp.tv_usec div 1000;
  result:= curtime; 
   
end;


procedure Sys_Mkdir(path: pchar);
begin
  FpMkdir(path ,0777);// $1FF);
end;


(*============================================*)
var {was static}
findbase: array [0..Pred(MAX_OSPATH)] of char;
findpath: array [0..Pred(MAX_OSPATH)] of char; 
findpattern: array [0..Pred(MAX_OSPATH)] of char; 
fdir: pDIR; //pDIR;


function CompareAttributes(path: pchar;  name: pchar;  musthave: Cardinal;  canthave: Cardinal): qboolean;
var
fn: array [0..Pred(MAX_OSPATH)] of char;
st : TStatBuf ;

begin
   (* . and .. never match*)
  if (strcmp(name,'.') = 0) or (strcmp(name,'..') = 0) then
  begin
    result:= false; 
    exit;
  end;


  //result:= true;

  if stat(fn,st)=-1 then
  begin
    result:= false; 
    exit;
    (* shouldn't happen*)
  end;

  if ((st.st_mode and S_IFDIR)<> 0)and((canthave and SFF_SUBDIR)<> 0) then
  begin
    result:= false; 
    exit;
  end;

  if ((musthave and SFF_SUBDIR)<> 0)and({not} (st.st_mode and S_IFDIR)= 0) then
  begin
    result:= false; 
    exit;
  end;


  result:= true; 

end;



function Sys_FindFirst(path: pchar;  musthave: Cardinal;  canhave: Cardinal): pchar;
var
p: pchar;
d : PDirEnt;
begin
  
  if fdir<> nil then
  Sys_Error('Sys_BeginFind without close',[]);
  strcpy(findbase,path);
  
  (* COM_FilePath (path, findbase);*)
  p := strrchr(findbase,StrtoInt('/'));
  //if (p:=strrchr(findbase,'/'))<>0{nil}
  if (p <> nil) then
  begin 
    {*}p^:= #0;
    strcpy(findpattern,p+1); 
  end
  else
  strcpy(findpattern,'*'); 
  
  if strcmp(findpattern,'*.*') = 0 then
  strcpy(findpattern,'*');

  fdir:=opendir(findbase);
  //if (fdir:=opendir(findbase))=0{nil}
  if fdir = nil then
  begin
    result:= nil; 
    exit;
  end;

  d:=readdir(fdir);
  //while (d:=readdir(fdir))<>0{nil}
  while d <> nil do
  begin
    //if {not}0=*findpattern)or(glob_match(findpattern,d.d_name)
    if (findpattern = nil) or (glob_match(findpattern,d^.d_name)<> 0) then
    begin 
      (*   if ( *findpattern)*)
      (*    printf("%s matched %s\n", findpattern, d->d_name);*)
      if CompareAttributes(findbase,d^.d_name,musthave,canhave)
      then
      begin 
        sprintf(findpath,'%s/%s',findbase,d^.d_name);
        begin
          result:= findpath; 
          exit;
        end;
      end;
    end;
  end;

  result:= nil;

end;


function Sys_FindNext(musthave: Cardinal;  canhave: Cardinal): pchar;
var
d : PDirEnt;
begin
  if fdir = nil then
  begin
    result:= nil;
    exit;
  end;

  d:=readdir(fdir);
  //while (d:=readdir(fdir))<>0{nil}
  while d <> nil do
  begin
    //if {not}0=*findpattern)or(glob_match(findpattern,d.d_name)
    if (findpattern = nil) or (glob_match(findpattern,d^.d_name)<> 0) then
    begin 
      (*   if ( *findpattern)*)
      (*    printf("%s matched %s\n", findpattern, d->d_name);*)
      if CompareAttributes(findbase,d^.d_name,musthave,canhave)
      then
      begin 
        sprintf(findpath,'%s/%s',findbase,d^.d_name);
        begin
          result:= findpath; 
          exit;
        end;
      end;
    end;
  end;

  result:= nil;

end;


procedure Sys_FindClose();
begin
  if fdir<>nil then
  closedir(fdir);
  fdir:= nil;
end;


(*============================================*)

end.
