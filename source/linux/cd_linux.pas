unit cd_linux;


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
(* Quake is a trademark of Id Software, Inc., (c) 1996 Id Software, Inc. All*)
(* rights reserved.*)

interface
uses q_shared_add , SDL;
{.$include <stdio.h>}
{.$include <unistd.h>}
{.$include <stdlib.h>}
{.$include <sys/ioctl.h>}
{.$include <sys/file.h>}
{.$include <sys/types.h>}
{.$include <fcntl.h>}
{.$include <string.h>}
{.$include <time.h>}
{.$include <errno.h>}

{.$include <linux/cdrom.h>}

{.$include "../client/client.h"}

var {was static}
cdValid: qboolean = false; 
playing: qboolean = false; 
wasPlaying: qboolean = false; 
initialized: qboolean = false; 
enabled: qboolean = true; 
playLooping: qboolean = false; 
cdvolume: Single; //float; 
//remap: array [0..Pred(100)] of byte;
playTrack: byte; 
maxTrack: byte;
lastTrack :integer = 0;
//cdfile: integer = -1;
///
cd_id : PSDL_CD ;

//originally commented 
(*static char cd_dev[64] = "/dev/cdrom";*)
var
cd_volume: cvar_p; 
cd_nocd: cvar_p; 
cd_dev: cvar_p; 

procedure CDAudio_Pause(); 
procedure CD_f();
procedure CDAudio_Stop();
procedure CDAudio_Play(track: integer;  looping: qboolean);
procedure CDAudio_Shutdown();
function CDAudio_Init(): integer;
procedure CDAudio_Update();
//procedure CDAudio_Eject();

implementation
uses //libc ,
     Cpas,
     Common ,client , cmd, q_shared, cvar;

procedure CDAudio_Eject(); 
begin
  //if (cdfile= -1)or(not enabled) then
  if ((cd_id = nil) or (not enabled)) then
  exit;
  (* no cd init'd *)
  
  //if ioctl(cdfile,CDROMEJECT)=-1 then
  if (SDL_CDEject(cd_id) <> 0) then
  //Com_DPrintf('ioctl cdromeject failed'#10);
  Com_DPrintf('Unable to eject CD-ROM tray.'#10);
end;



//procedure CDAudio_CloseDoor();
//begin
//  if (cdfile=-1) or (not enabled) then
//  exit;
  (* no cd init'd *)

//  if ioctl(cdfile,CDROMCLOSETRAY)=-1 then
//  Com_DPrintf('ioctl cdromclosetray failed'#10);
//end;


//function CDAudio_GetAudioDiskInfo(): integer;
//var
//tochdr : cdrom_tochdr;

//begin

//  cdValid:= false;

//  if ioctl(cdfile,CDROMREADTOCHDR,@tochdr)=-1 then
//  begin
//    Com_DPrintf('ioctl cdromreadtochdr failed'#10);

//    result:= -1;
//    exit;

//  end;

//  if (tochdr.cdth_trk0 < 1) then
//  begin
//    Com_DPrintf('CDAudio: no music tracks'#10);

//    result:= -1;
//    exit;

//  end;
//  cdValid:= true;
//  maxTrack:= tochdr.cdth_trk1;

//  result:= 0;

//end;



procedure CDAudio_Play(track: integer;  looping: qboolean);
var
//entry : cdrom_tocentry ;
//ti    : cdrom_ti ;
cd_stat : TSDL_CDstatus ;


begin

  lastTrack := track + 1;
  //if (cdfile=-1)or(not enabled) then exit;
  if ((cd_id = nil) or (not enabled)) then exit;
  cd_stat := SDL_CDStatus (cd_id);

  if (not cdValid) then
  begin

  //  CDAudio_GetAudioDiskInfo();
  //  if (not cdValid) then
  //  exit;
  //end;
  if ( SDL_CDInDrive(cd_stat) = false) or (cd_id^.numtracks = 0) then exit;
  cdValid := true ;
  end;
  //track:= remap[track];

  if (track <1 ) or (track >= cd_id^.numtracks) then
  begin
    Com_DPrintf('CDAudio: Bad track number %d.'#10, [track]);
    exit;
  end;
  dec (track); //* Convert track from person to SDL value */

  (* don't try to play a non-audio track*)
  //entry.cdte_track:= track;
  //entry.cdte_format:= CDROM_MSF;

  //if ioctl(cdfile,CDROMREADTOCENTRY, @entry)=-1 then
  //begin
  //  Com_DPrintf('ioctl cdromreadtocentry failed'#10);
  //  exit;
  //end;
  //if entry.cdte_ctrl=CDROM_DATA_TRACK then
  //begin
  //  Com_Printf('CDAudio: track %i is not audio'#10,[track]);
  //  exit;
  //end;
  if(cd_stat = CD_PLAYING) then
  begin
   if (cd_id^.cur_track = track) then exit;
   CDAudio_Stop;
  end;

  //ti.cdti_trk0:= track;
  //ti.cdti_trk1:= track;
  //ti.cdti_ind0:= 1;
  //ti.cdti_ind1:= 99;

  if (SDL_CDPlay (cd_id , cd_id^.track[track].offset ,cd_id^.track[track].length) <> 0) then
  begin
  Com_DPrintf('CDAudio_Play: Unable to play track: %d (%s)', [track+1, SDL_GetError()]);
  exit;
  end;

  playLooping := looping ;

  //if ioctl(cdfile,CDROMPLAYTRKIND,@ti)=-1 then
  //begin
  //  Com_DPrintf('ioctl cdromplaytrkind failed'#10);
  //  exit;
  //end;

  //if ioctl(cdfile,CDROMRESUME)=-1 then
  //Com_DPrintf('ioctl cdromresume failed'#10);
  //playLooping:= looping;
  //playTrack:= track;
  //playing:= true;

  //if cd_volume^.value=0.0 then
  //CDAudio_Pause();
end;



procedure CDAudio_Stop();
var
cdstate :integer ;
begin
  //if (cdfile=-1)or(not enabled) then
  //exit;
  //if (not playing) then
  //exit;
  if ((cd_id = nil) or (not enabled)) then exit;
  cdstate := Integer(SDL_CDStatus(cd_id));

  if ((cdstate <> Integer(CD_PLAYING)) and (cdstate <> Integer(CD_PAUSED))) then exit;
  //if ioctl(cdfile,CDROMSTOP)=-1 then
  //Com_DPrintf('ioctl cdromstop failed (%d)'#10, [errno]);
  //wasPlaying:= false;
  //playing:= false;
  if (SDL_CDStop (cd_id))<> 0 then
     Com_DPrintf('CDAudio_Stop: Failed to stop track.'#10);
  playLooping := false;

end;


procedure CDAudio_Pause(); 
begin
  //if (cdfile=-1)or(not enabled) then
  //exit;
  if ((cd_id = nil) or (not enabled)) then exit;

  //if (not playing) then
  //exit;
  if (SDL_CDStatus (cd_id) <> CD_PLAYING) then exit;

  //if ioctl(cdfile,CDROMPAUSE)=-1 then
  //Com_DPrintf('ioctl cdrompause failed'#10);
  //wasPlaying:= playing;
  //playing:= false;
  if (SDL_CDPause(cd_id) <> 0) then
    Com_DPrintf('CDAudio_Pause: Failed to pause track.'#10);

end;



procedure CDAudio_Resume(); 
begin
  //if (cdfile=-1)or(not enabled) then
  //exit;
  if ((cd_id = nil) or (not enabled)) then exit;

  //if (not cdValid) then
  //exit;
  if (SDL_CDStatus (cd_id) <> CD_PAUSED ) then exit;

  if (SDL_CDResume (cd_id) <> 0) then
    Com_DPrintf('CDAudio_Resume: Failed to resume track.'#10);

  //if (not wasPlaying) then
  //exit;
  //if ioctl(cdfile,CDROMRESUME)=-1
  //then
  //Com_DPrintf('ioctl cdromresume failed'#10);
  //playing:= true;
end;


procedure CD_f(); 
var
command: pchar; 
//ret: integer;
cdstate :integer;
n: integer; 
begin
    
  if Cmd_Argc() < 2 then
  exit;
  
  command:= Cmd_Argv(1); 
  if Q_strcasecmp(command,'on') = 0 then
  begin 
    enabled:= true; 
    //exit;
  end;
  
  if Q_strcasecmp(command,'off') = 0 then
  begin 
    //if playing <>0{nil or True}  then
    if (cd_id =  nil) then exit;
    cdstate := Integer(SDL_CDStatus(cd_id));
    if ((cdstate = Integer(CD_PLAYING)) or (cdstate = Integer(CD_PAUSED))) then
    CDAudio_Stop();
    enabled:= false; 
    exit;
  end;
  
  if Q_strcasecmp(command,'play') = 0 then
  begin
    CDAudio_Play(atoi(Cmd_Argv(2)),false);
    exit;
  end;

  if Q_strcasecmp(command,'loop') = 0 then
  begin
    CDAudio_Play(atoi(Cmd_Argv(2)),true);
    exit;
  end;

  if Q_strcasecmp(command,'stop') = 0 then
  begin
    CDAudio_Stop();
    exit;
  end;

  if Q_strcasecmp(command,'pause') = 0 then
  begin
    CDAudio_Pause();
    exit;
  end;

  if Q_strcasecmp(command,'resume') = 0 then
  begin
    CDAudio_Resume();
    exit;
  end;

  if Q_strcasecmp(command,'eject') = 0 then
  begin
    CDAudio_Eject();
    exit;
  end;


  
  if Q_strcasecmp(command,'info') = 0 then
  begin
   if (cd_id = nil) then exit;
   cdstate := Integer(SDL_CDStatus (cd_id));

    Com_Printf('%d tracks'#10 , [cd_id^.numtracks]);
    if (cdstate = Integer(CD_PLAYING))  then
    if (playLooping ) then
    Com_Printf('Currently %s track %d'#10 , ['looping', cd_id^.cur_track +1])
    else
    Com_Printf('Currently %s track %d'#10 , ['playing',cd_id^.cur_track +1])
    //Com_Printf('Currently %s track %d'#10 , [playLooping {was ?}if  then 'looping' {was :}else 'playing',playTrack);
    else
    if (cdstate = Integer(CD_PAUSED))  then
     if (playLooping ) then
        Com_Printf('Currently %s track %d'#10 , ['looping',cd_id^.cur_track +1])
        else
        Com_Printf('Currently %s track %d'#10 , ['playing',cd_id^.cur_track +1]);

    exit;
  end;
end;



//var {was static}
//lastchk: time_t;

procedure CDAudio_Update(); 
//type
//subchnl :cdrom_subchnl ;

begin
  
  //if (cdfile=-1) or (not enabled) then
  //exit;
  if ((cd_id = nil) or (not enabled)) then exit;

  if (cd_volume <> nil)and(cd_volume^.value <> cdvolume) then
  begin 
    if cdvolume <> 0 {nil} then
    begin 
      Cvar_SetValue('cd_volume',0.0);
      //cdvolume:= cd_volume^.value;
      CDAudio_Pause(); 
    end
    else
    begin 
      Cvar_SetValue('cd_volume',1.0); 
      //cdvolume:= cd_volume^.value;
      CDAudio_Resume();
    end;
    cdvolume:= cd_volume^.value;
    exit;
  end;

  if (cd_nocd^.value <> 0) then
   begin
   CDAudio_Stop ;
   exit;
   end;
  if (playLooping and ((SDL_CDStatus (cd_id) <> CD_PLAYING) and
                        (SDL_CDStatus (cd_id) <> CD_PAUSED))) then
    begin
    CDAudio_Play(lastTrack, true);
    end;
    
end;


function CDAudio_Init(): integer; 
var
i: integer; 
cv: cvar_p; 
begin
  
  {saved_euid: uid_t; }{<= !!!5 external variable}
  
  cv:= Cvar_Get('nocdaudio', '0', CVAR_NOSET); 
  if cv^.value <> 0 {nil} then
  begin
    result:= -1; 
    exit;  
  end;
  
  cd_nocd:= Cvar_Get('cd_nocd', '0', CVAR_ARCHIVE); 
  if cd_nocd^.value <> 0 {nil } then
  begin
    result:= -1; 
    exit;  
  end;
  
  cd_volume:= Cvar_Get('cd_volume', '1', CVAR_ARCHIVE);
   
  //cd_dev:= Cvar_Get('cd_dev', '/dev/cdrom', CVAR_ARCHIVE);

  //seteuid(saved_euid);
  if (SDL_WasInit(SDL_INIT_EVERYTHING) = 0) then
    begin
    if (SDL_Init(SDL_INIT_CDROM) < 0) then
        begin
        Com_Printf ('Couldn''t init SDL cdrom: %s'#10,[ SDL_GetError ()]);
        result := -1 ;
        end;
    end
    else
    if (SDL_WasInit(SDL_INIT_CDROM) = 0) then
       begin
        if (SDL_InitSubSystem(SDL_INIT_CDROM) < 0) then
           begin
           Com_Printf ('Couldn''t init SDL cdrom: %s'#10,[ SDL_GetError ()]);
           result := -1 ;
           end;
        end;

   cd_id := SDL_CDOpen(0);
  //cdfile:= open(cd_dev^.string, O_RDONLY);

  //seteuid(getuid());

  //if cdfile=-1 then
  if cd_id = nil then
  begin 
    //Com_Printf("CDAudio_Init: open of \"%s\" failed (%i)\n", cd_dev->string, errno);
    //Com_Printf('CDAudio_Init: open of \%s\ failed (%i)'#10, cd_dev^.string, errno);
    //cdfile:= -1;
    Com_Printf('CDAudio_Init: Unable to open default CD-ROM drive: %s'#10, [SDL_GetError()]);
    result:= -1; 
  end;
  
  //for{while} i:=0 to Pred(100) { i++}
  //do
  //remap[i]:= i;
  initialized:= true;
  enabled := true;
  cdValid := true;
  //if CDAudio_GetAudioDiskInfo() then
  //begin
  //  Com_Printf('CDAudio_Init: No CD in player.'#10);
  //  cdValid:= false;
  //end;
  if ( SDL_CDInDrive (SDL_CDStatus(cd_id))= false) then
  begin
   Com_Printf('CDAudio_Init: No CD in drive.'#10);
   cdValid := false;
  end;

  if (cd_id^.numtracks = 0) then
   begin
    Com_Printf('CDAudio_Init: CD contains no audio tracks.'#10);
    cdValid := false;
   end;

  Cmd_AddCommand('cd', @CD_f);
  
  Com_Printf('CD Audio Initialized'#10);

  result:= 0; 

end;


procedure CDAudio_Activate(active: qboolean); 
begin
  if active  then
  CDAudio_Resume() 
  else
  CDAudio_Pause(); 
end;


procedure CDAudio_Shutdown(); 
begin
  //if not initialized then
  if (cd_id = nil) then
  exit;
  
  CDAudio_Stop(); 
  //close(cdfile);
  //cdfile:= -1;
  SDL_CDClose (cd_id);
  cd_id := nil;

  if (SDL_WasInit(SDL_INIT_EVERYTHING) = SDL_INIT_CDROM) then
   SDL_Quit
  else
   SDL_QuitSubSystem (SDL_INIT_CDROM);

   initialized := false ;

end;

end.
