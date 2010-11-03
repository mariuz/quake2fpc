unit snd_linux;

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
uses Cvar;

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
audio_fd: integer;
snd_inited: integer;
sndbits: cvar_p;
sndspeed: cvar_p;
sndchannels: cvar_p;
snddevice: cvar_p;

var {was static}
tryrates: array [0..3] of integer = (11025,22051,44100,8000);

implementation
uses q_shared_add , libc , q_shared ,sys_linux,
     common ,client ,snd_loc ,snd_dma, q_shlinux;

type
audio_buf_info = record
end;

function SNDDMA_Init(): qboolean;
var
rc: integer; 
fmt: integer; 
tmp: integer; 
i: integer; 
s: pchar; 
caps: integer; 
begin


  {saved_euid: uid_t; }{<= !!!5 external variable}
  if snd_inited<>0{nil} {<= !!!9} 
  then
  exit;
  
  if {not} snddevice = nil then
  begin 
    sndbits:= Cvar_Get('sndbits','16',CVAR_ARCHIVE); 
    sndspeed:= Cvar_Get('sndspeed','0',CVAR_ARCHIVE); 
    sndchannels:= Cvar_Get('sndchannels','2',CVAR_ARCHIVE); 
    snddevice:= Cvar_Get('snddevice','/dev/dsp',CVAR_ARCHIVE); 
  end;
  
  (* open /dev/dsp, confirm capability to mmap, and get size of dma buffer*)
  if {not} audio_fd = 0 then
  begin 
    seteuid(saved_euid);
    audio_fd:= open(snddevice.string_,O_RDWR);
    seteuid(getuid()); 
    
    
    
    if audio_fd<0
    then
    begin 
      perror(snddevice.string_);
      Com_Printf('Could not open %s'#10,[snddevice.string_]);
      begin
        result:= false;
        exit;
      end;
    end;
  end;
  rc:= ioctl(audio_fd,SNDCTL_DSP_RESET,0);
  if rc<0
  then
  begin 
    perror(snddevice.string_);
    Com_Printf('Could not reset %s'#10,[snddevice.string_]);
    __close(audio_fd);
    begin
      result:= false; 
      exit;
    end;
  end;
  
  if ioctl(audio_fd,SNDCTL_DSP_GETCAPS, @caps)=-1
  then
  begin 
    perror(snddevice.string_);
    Com_Printf('Sound driver too old'#10);
    __close(audio_fd);
    begin
      result:= false;
      exit;
    end;
  end;
  
  if {not}0=(caps and DSP_CAP_TRIGGER))or({not}0=(caps and DSP_CAP_MMAP)
  then
  begin 
    Com_Printf('Sorry but your soundcard can'#39't do this'#10);
    __close(audio_fd);
    begin
      result:= false;
      exit;
    end;
  end;
  
  if ioctl(audio_fd,SNDCTL_DSP_GETOSPACE,@info)=-1
  then
  begin 
    perror('GETOSPACE'); 
    Com_Printf('Um, can'#39't do GETOSPACE?'#10);
    __close(audio_fd);
    begin
      result:= false;
      exit;
    end;
  end;
  dma.samplebits:= Trunc(sndbits.value); (* set sample bits & speed*)
  if dma.samplebits<>16)and(dma.samplebits<>8
  then
  begin 
    ioctl(audio_fd,SNDCTL_DSP_GETFMTS, @fmt);
    if fmt and AFMT_S16_LE
    then
    dma.samplebits:= 16
    else
    if fmt and AFMT_U8
    then
    dma.samplebits:= 8; 
  end;
  dma.speed:= Trunc(sndspeed.value);
  if {not}0=dma.speed
  then
  begin 
    for{while} i:=0 to Pred(sizeof(tryrates) div 4) { i++}
    do
    if {not}0=ioctl(audio_fd,SNDCTL_DSP_SPEED,@tryrates[i])
    then
    break; {<= !!!b possible in "switch" - then remove this line}
    dma.speed:= tryrates[i]; 
  end;
  dma.channels:= Trunc(sndchannels.value);
  if dma.channels<1)or(dma.channels>2
  then
  dma.channels:= 2; 
  dma.samples:= info.fragstotal*info.fragsize div (dma.samplebits div 8); 
  dma.submission_chunk:= 1; 
  (* memory map the dma buffer*)
  if {not}0=dma.buffer
  then
  dma.buffer:= (unsignedchar* )mmap(0{nil},info.fragstotal*info.fragsize,PROT_WRITE,MAP_FILE or MAP_SHARED,audio_fd,0);
  if {not}0=dma.buffer
  then
  begin 
    perror(snddevice.string_);
    Com_Printf('Could not mmap %s'#10, [snddevice.string_]);
    __close(audio_fd);
    begin
      result:= false;
      exit;
    end;
  end;
  tmp:= 0; 
  if dma.channels=2
  then
  tmp:= 1; 
  rc:= ioctl(audio_fd,SNDCTL_DSP_STEREO,@tmp); 
  if rc<0
  then
  begin
    perror(snddevice.string_);
    Com_Printf('Could not set %s to stereo=%d', [snddevice.string_, dma.channels]);
    __close(audio_fd); 
    begin
      result:= false;
      exit;
    end;
  end;
  if tmp<>0{nil} {<= !!!9} 
  then
  dma.channels:= 2
  else
  dma.channels:= 1; 
  rc:= ioctl(audio_fd,SNDCTL_DSP_SPEED, @dma.speed);
  if rc < 0 then
  begin 
    perror(snddevice.string_);
    Com_Printf('Could not set %s speed to %d',[snddevice.string_, dma.speed]);
    __close(audio_fd);
    begin
      result:= false; 
      exit;
    end;
  end;
  
  if dma.samplebits=16
  then
  begin 
    rc:= AFMT_S16_LE; 
    rc:= ioctl(audio_fd,SNDCTL_DSP_SETFMT,@rc); 
    if rc<0
    then
    begin 
      perror(snddevice.string_);
      Com_Printf('Could not support 16-bit data.  Try 8-bit.'#10);
      __close(audio_fd);
      begin
        result:= 0; 
        exit;
      end;
    end;
  end
  else
  if dma.samplebits=8
  then
  begin 
    rc:= AFMT_U8; 
    rc:= ioctl(audio_fd,SNDCTL_DSP_SETFMT,@rc); 
    if rc<0
    then
    begin 
      perror(snddevice.string_);
      Com_Printf('Could not support 8-bit data.'#10); 
      __close(audio_fd);
      begin
        result:= 0; 
        exit;
      end;
    end;
  end;
  else
  begin 
    perror(snddevice.string_);
    Com_Printf('%d-bit sound not supported.', [dma.samplebits]);
    __close(audio_fd);
    begin
      result:= 0; 
      exit;
    end;
  end;
  tmp:= 0; 
  rc:= ioctl(audio_fd,SNDCTL_DSP_SETTRIGGER,@tmp); 
  (* toggle the trigger & start her up*)
  if rc<0
  then
  begin 
    perror(snddevice.string_);
    Com_Printf('Could not toggle.'#10);
    __close(audio_fd);
    begin
      result:= 0; 
      exit;
    end;
  end;
  tmp:= PCM_ENABLE_OUTPUT; 
  rc:= ioctl(audio_fd,SNDCTL_DSP_SETTRIGGER,@tmp); 
  if rc<0
  then
  begin 
    perror(snddevice.string_);
    Com_Printf('Could not toggle.'#10);
    __close(audio_fd);
    begin
      result:= 0; 
      exit;
    end;
  end;
  dma.samplepos:= 0; 
  snd_inited:= 1; 
  
  begin
    result:= 1; 
    exit;
    
  end;
end;

type
count_info = record
end;

function SNDDMA_GetDMAPos(): integer; 
begin
  if {not}0=snd_inited
  then
  begin
    result:= 0; 
    exit;
    
  end;
  if ioctl(audio_fd,SNDCTL_DSP_GETOPTR, @count)=-1
  then
  begin 
    perror(snddevice.string_);
    Com_Printf('Uh, sound dead.'#10);
    __close(audio_fd);
    snd_inited:= 0; 
    begin
      result:= 0; 
      exit;
    end;
  end;
  dma.samplepos:= count.ptr div (dma.samplebits div 8); 
  (* dma.samplepos = (count.bytes / (dma.samplebits / 8)) & (dma.samples-1);*)
  (* fprintf(stderr, "%d    \r", count.ptr);*)
  
  begin
    result:= dma.samplepos; 
    exit;
    
  end;
end;


procedure SNDDMA_Shutdown(); 
begin
  {$if 0}
  if snd_inited<>0{nil} {<= !!!9} 
  then
  begin 
    close(audio_fd); 
    snd_inited:= 0; 
  end;
  {$ifend}
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
