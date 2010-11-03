unit snd_sdl;

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
uses Cvar,q_shared_add ,snd_loc;

{.$include <unistd.h>}
{.$include <fcntl.h>}
{.$include <stdlib.h>}
{.$include <sys/types.h>}
{.$include <sys/ioctl.h>}
{.$include <sys/mman.h>}
{.$include <sys/shm.h>}
{.$include <sys/wait.h>}
{.$include <linux/soundcard.h>}
{.$include <stdio.h>}

{.$include "../client/client.h"}
{.$include "../client/snd_loc.h"}

var
//audio_fd: integer;
snd_inited: integer;
sndbits: cvar_p;
sndspeed: cvar_p;
sndchannels: cvar_p;
snddevice: cvar_p;
shm : dma_p;

function SNDDMA_Init(): qboolean;
function SNDDMA_GetDMAPos(): integer;
procedure SNDDMA_Shutdown();
procedure SNDDMA_Submit();
procedure SNDDMA_BeginPainting();
//var {was static}
//tryrates: array [0..3] of integer = (11025,22051,44100,8000);

implementation
uses     SDL,snd_mix,Cpas,
         q_shared ,sys_linux,
     common ,client , q_shlinux;


procedure paint_audio (unused :pointer ;stream :PUINT8 ;len :integer);
begin
if shm <> nil then
        begin
        shm^.buffer := @stream ;
        shm^.samplepos := (shm^.samplepos + len) div (shm^.samplebits div 4);
        // Check for samplepos overflow?
        S_PaintChannels (shm^.samplepos);
        end;
end;

function SNDDMA_Init(): qboolean;
var
//rc: integer;
//fmt: integer;
//tmp: integer;
//i: integer;
//s: pchar;
//caps: integer;
dma : dma_t; //added by FAB
desired ,obtained :TSDL_AudioSpec;
desired_bits , freq : Integer;
begin


  if (SDL_WasInit(SDL_INIT_EVERYTHING) = 0) then
   begin
   if (SDL_Init(SDL_INIT_AUDIO) < 0) then
       begin
       Com_Printf ('Couldn''t init SDL audio: %s'#10, [SDL_GetError ()]);
       exit ;
       end;
   end
   else
   if (SDL_WasInit(SDL_INIT_AUDIO) = 0) then
      begin
      if (SDL_InitSubSystem(SDL_INIT_AUDIO) < 0) then
         begin
         Com_Printf ('Couldn''t init SDL audio: %s'#10,[ SDL_GetError ()]);
         exit;
         end;
      end;
   snd_inited := 0;
   desired_bits:= Trunc((Cvar_Get('sndbits','16',CVAR_ARCHIVE))^.value);
   

   //* Set up the desired format */
   freq := Trunc((Cvar_Get('s_khz', '0', CVAR_ARCHIVE))^.value) ;

   if freq = 44 then
      desired.freq := 44100
    else
    if freq = 22 then
      desired.freq := 22050
    else
      desired.freq := 11025;

    case (desired_bits) of
      8: begin
         desired.format := AUDIO_U8 ;
         end;
      16:begin
         if (SDL_BYTEORDER = SDL_BIG_ENDIAN) then
            desired.format := AUDIO_S16MSB
         else
            desired.format := AUDIO_S16LSB;
         end;
       else
         Com_Printf ('Unknown number of audio bits: %d'#10, [desired_bits]);
         exit;
     end;
    desired.channels := Trunc((Cvar_Get('sndchannels', '2', CVAR_ARCHIVE))^.value);

    if (desired.freq = 44100 ) then desired.samples := 2048
    else if (desired.freq = 22050) then desired.samples := 1024
    else desired.samples := 512;

    desired.callback := @paint_audio;

    //* Open the audio device */
    if (SDL_OpenAudio (@desired, @obtained) < 0) then
     begin
     Com_Printf ('Couldn''t open SDL audio: %s'#10, [SDL_GetError ()]);
     exit;
     end;

    //* Make sure we can support the audio format */
    case (obtained.format) of
    AUDIO_U8 : begin
               //* Supported */
               end;
    AUDIO_S16LSB,
    AUDIO_S16MSB: begin
                  if (((obtained.format = AUDIO_S16LSB) and (SDL_BYTEORDER = SDL_LIL_ENDIAN)
                                                        or  ((obtained.format = AUDIO_S16MSB)
                                                        and (SDL_BYTEORDER = SDL_BIG_ENDIAN)))) then
                  begin
                  //* Supported */
                  end;
                  end
     else
     //* Unsupported, fall through */
     begin
     //* Not supported -- force SDL to do our bidding */
     SDL_CloseAudio ();
     if (SDL_OpenAudio (@desired ,nil) < 0) then
        begin
        Com_Printf ('Couldn''t open SDL audio: %s'#10, [SDL_GetError ()]);
        exit;
        end;
     memcpy (@obtained , @desired, sizeof (desired));
     end;
  end;
 SDL_PauseAudio (0);

 //* Fill the audio DMA information block */
 shm := @dma ;
 shm^.samplebits := (obtained.format and $ff);
 shm^.speed := obtained.freq ;
 shm^.channels := obtained.channels;
 shm^.samples := obtained.samples * shm^.channels ;
 shm^.samplepos := 0;
 shm^.submission_chunk := 1;
 shm^.buffer := nil ;

 snd_inited := 1;

 result := true;
end;


function SNDDMA_GetDMAPos(): integer;
begin
  result := shm^.samplepos ;
end;


procedure SNDDMA_Shutdown();
begin

  if snd_inited <> 0 then
  begin 
    SDL_CloseAudio ();
    snd_inited:= 0; 
  end;
  if (SDL_WasInit(SDL_INIT_EVERYTHING) = SDL_INIT_AUDIO) then
     SDL_Quit ()
     else
     SDL_QuitSubSystem (SDL_INIT_AUDIO);


end;

(*
==============
SNDDMA_Submit

Send sound to device if buffer isn't really the dma buffer
===============
*)

procedure SNDDMA_Submit();
begin
end;


procedure SNDDMA_BeginPainting();
begin
end;


end.
