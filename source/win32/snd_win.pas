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
{ File(s): snd_win.c                                                         }
{ Content:  Quake2\win32\ sound & sound FX routines                          }
{                                                                            }
{ Initial conversion by : Massimo Soricetti (max-67@libero.it)               }
{ Initial conversion on : 09-Jan-2002                                        }
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
{ Updated on : 03-jun-2002                                                   }
{ Updated by : Juha Hartikainen                                              }
{ - Added needed units to uses clause                                        }
{ - Fixed some language errors                                               }
{                                                                            }
{ Updated on : 04-jun-2002                                                   }
{ Updated by : Juha Hartikainen                                              }
{ - Moved some functions to interface                                        }
{                                                                            }
{ Updated on : 05-jul-2002                                                   }
{ Updated by : Sly                                                           }
{ - Added some stub functions because the sound code tends to crash          }
{                                                                            }
{ Updated on : 05-jul-2002                                                   }
{ Updated by : Sly                                                           }
{ - Removed stub functions.  Seems to be not crashing.                       }
{                                                                            }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{ none                                                                       }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{ none                                                                       }
{----------------------------------------------------------------------------}

unit snd_win;

interface

uses
  Windows,
  MMsystem,
  q_shared,
  snd_loc,
  client,
  DirectSound;

// 64K is > 1 second at 16-bit, 22050 Hz

function SNDDMA_Init(): boolean;
function SNDDMA_GetDMAPos(): integer;
procedure SNDDMA_BeginPainting();
procedure SNDDMA_Submit();
procedure SNDDMA_Shutdown();

procedure S_Activate(active: qboolean);
procedure FreeSound();

const
  WAV_BUFFERS = 64;
  WAV_MASK = $3F;
  WAV_BUFFER_SIZE = $0400;
  SECONDARY_BUFFER_SIZE = $10000;

type
  sndinitstat = (SIS_SUCCESS, SIS_FAILURE, SIS_NOTAVAIL);

  TWaveHDRArray = array[0..WAV_BUFFERS - 1] of WAVEHDR;

var

  { * Global variables. Must be visible to window-procedure function
    *  so it can unlock and free the data block after it has been played. }

  hData: THANDLE;
  lpData, lpData2: Pointer;
  hWaveHdr: HGLOBAL;                    // GlobalAlloc handle
  lpWaveHdr: ^TWaveHDRArray;
  hWaveOut_: HWAVEOUT;
  wavecaps: WAVEOUTCAPS;
  gSndBufSize: DWORD;

  mmstarttime: MMTIME;

  pDS: IDIRECTSOUND;
  pDSBuf, pDSPBuf: IDIRECTSOUNDBUFFER;

  //  hInstDS: DWORD;

implementation

uses
  Cmd,
  CVar,
  Common,
  vid_dll,
  snd_dma;

var
  s_wavonly: cvar_p;

  dsound_init,
    wav_init: qboolean;
  snd_firsttime: qboolean = true;
  snd_isdirect, snd_iswave,
    primary_format_set: qboolean;

  // starts at 0 for disabled
  snd_buffer_count: integer = 0;
  sample16,
    snd_sent, snd_completed: integer;

function DSoundError(error: integer): Pchar;
begin
  case error of
    DSERR_BUFFERLOST: Result := 'DSERR_BUFFERLOST';
    DSERR_INVALIDCALL: Result := 'DSERR_INVALIDCALLS';
    DSERR_INVALIDPARAM: Result := 'DSERR_INVALIDPARAM';
    DSERR_PRIOLEVELNEEDED: Result := 'DSERR_PRIOLEVELNEEDED';
  else
    Result := 'unknown';
  end;
end;

{
** DS_CreateBuffers
}

function DS_CreateBuffers(): qboolean;
var
  dsbuf: TDSBUFFERDESC;
  dsbcaps: TDSBCAPS;
  pformat, format: TWAVEFORMATEX;
  dwWrite: DWORD;
begin
  FillChar(format, sizeof(format), 0);
  format.wFormatTag := WAVE_FORMAT_PCM;
  format.nChannels := dma.channels;
  format.wBitsPerSample := dma.samplebits;
  format.nSamplesPerSec := dma.speed;
  format.nBlockAlign := format.nChannels * format.wBitsPerSample div 8;
  format.cbSize := 0;
  format.nAvgBytesPerSec := format.nSamplesPerSec * format.nBlockAlign;

  Com_Printf('Creating DS buffers'#10, []);

  Com_DPrintf('...setting EXCLUSIVE coop level: ', []);
  if DS_OK <> pDS.SetCooperativeLevel(cl_hwnd, DSSCL_EXCLUSIVE) then
  begin
    Com_Printf('failed'#10, []);
    FreeSound();
    Result := false;
    Exit;
  end;
  Com_DPrintf('ok'#10, []);

  // get access to the primary buffer, if possible, so we can set the
  // sound hardware format
  FillChar(dsbuf, sizeof(dsbuf), 0);
  dsbuf.dwSize := sizeof(TDSBUFFERDESC);
  dsbuf.dwFlags := DSBCAPS_PRIMARYBUFFER;
  dsbuf.dwBufferBytes := 0;
  dsbuf.lpwfxFormat := nil;

  FillChar(dsbcaps, sizeof(dsbcaps), 0);
  dsbcaps.dwSize := sizeof(dsbcaps);
  primary_format_set := false;

  Com_DPrintf('...creating primary buffer: ', []);
  if DS_OK = pDS.CreateSoundBuffer(dsbuf, pDSPBuf, nil) then
  begin
    pformat := format;

    Com_DPrintf('ok'#10, []);
    if (DS_OK <> pDSPBuf.SetFormat(@pformat)) then
    begin
      if snd_firsttime then
        Com_DPrintf('...setting primary sound format: failed'#10, []);
    end
    else
    begin
      if snd_firsttime then
        Com_DPrintf('...setting primary sound format: ok'#10, []);
      primary_format_set := true;
    end;
  end
  else
    Com_Printf('failed'#10, []);

  if (not primary_format_set) or (s_primary^.value = 0) then
  begin
    // create the secondary buffer we'll actually work with
    FillChar(dsbuf, sizeof(dsbuf), 0);
    dsbuf.dwSize := sizeof(TDSBUFFERDESC);
    dsbuf.dwFlags := DSBCAPS_CTRLFREQUENCY and DSBCAPS_LOCSOFTWARE;
    dsbuf.dwBufferBytes := SECONDARY_BUFFER_SIZE;
    dsbuf.lpwfxFormat := @format;

    FillChar(dsbcaps, sizeof(dsbcaps), 0);
    dsbcaps.dwSize := sizeof(dsbcaps);
    Com_DPrintf('...creating secondary buffer: ', []);
    if (DS_OK <> pDS.CreateSoundBuffer(dsbuf, pDSBuf, nil)) then
    begin
      Com_Printf('failed'#10, []);
      FreeSound();
      Result := false;
      Exit;
    end;
    Com_DPrintf('ok'#10, []);

    dma.channels := format.nChannels;
    dma.samplebits := format.wBitsPerSample;
    dma.speed := format.nSamplesPerSec;

    if (DS_OK <> pDSBuf.GetCaps(dsbcaps)) then
    begin
      Com_Printf('*** GetCaps failed ***'#10, []);
      FreeSound();
      result := false;
      exit;
    end;

    Com_Printf('...using secondary sound buffer'#10, []);
  end
  else
  begin
    Com_Printf('...using primary buffer'#10, []);
    Com_DPrintf('...setting WRITEPRIMARY coop level: ', []);
    if (DS_OK <> pDS.SetCooperativeLevel(cl_hwnd, DSSCL_WRITEPRIMARY)) then
    begin
      Com_Printf('failed'#10, []);
      FreeSound();
      Result := False;
      Exit;
    end;
    Com_DPrintf('ok'#10, []);
    if DS_OK <> pDSPBuf.GetCaps(dsbcaps) then
    begin
      Com_Printf('*** GetCaps failed ***'#10, []);
      Result := false;
      Exit;
    end;

    pDSBuf := pDSPBuf;
  end;

  // Make sure mixer is active
  pDSBuf.Play(0, 0, DSBPLAY_LOOPING);
  if snd_firsttime then
    Com_Printf('   %d channel(s)'#10 +
      '   %d bits/sample'#10 +
      '   %d bytes/sec'#10, [dma.channels, dma.samplebits, dma.speed]);

  gSndBufSize := dsbcaps.dwBufferBytes;

  // we don't want anyone to access the buffer directly w/o locking it first.
  lpData := nil;

  pDSBuf.Stop();
  pDSBuf.GetCurrentPosition(@mmstarttime.sample, @dwWrite);
  pDSBuf.Play(0, 0, DSBPLAY_LOOPING);

  dma.samples := gSndBufSize div (dma.samplebits div 8);
  dma.samplepos := 0;
  dma.submission_chunk := 1;
  dma.buffer := lpData;
  sample16 := dma.samplebits div 8 - 1;

  Result := true;
end;

{
** DS_DestroyBuffers
}

procedure DS_DestroyBuffers();
begin
  Com_DPrintf('Destroying DS buffers'#10, []);
  if Assigned(pDS) then
  begin
    Com_DPrintf('...setting NORMAL coop level'#10, []);
    pDS.SetCooperativeLevel(cl_hwnd, DSSCL_NORMAL);
  end;

  if Assigned(pDSBuf) then
  begin
    Com_DPrintf('...stopping and releasing sound buffer'#10, []);
    pDSBuf.Stop();
    //pDSBuf._Release();
    pDSBuf := nil;
  end;

  // only release primary buffer if it's not also the mixing buffer we just released
  if Assigned(pDSPBuf) and (pDSBuf <> pDSPBuf) then
  begin
    Com_DPrintf('...releasing primary buffer'#10, []);
    //pDSPBuf._Release( );
    pDSPBuf := nil;
  end;
  dma.buffer := nil;
end;

{
=========
FreeSound
=========
}

procedure FreeSound();
var
  i: integer;
begin
  Com_DPrintf('Shutting down sound system'#10, []);

  if pDS <> nil then
    DS_DestroyBuffers();

  if hWaveOut_ <> 0 then
  begin
    Com_DPrintf('...resetting waveOut'#10, []);
    waveOutReset(hWaveOut_);

    if lpWaveHdr <> nil then
    begin
      Com_DPrintf('...unpreparing headers'#10, []);
      for i := 0 to WAV_BUFFERS - 1 do
        waveOutUnprepareHeader(hWaveOut_, @lpWaveHdr[i], sizeof(WAVEHDR));
    end;

    Com_DPrintf('...closing waveOut'#10, []);
    waveOutClose(hWaveOut_);

    if hWaveHdr <> 0 then
    begin
      Com_DPrintf('...freeing WAV header'#10, []);
      GlobalUnlock(hWaveHdr);
      GlobalFree(hWaveHdr);
    end;

    if hData <> 0 then
    begin
      Com_DPrintf('...freeing WAV buffer'#10, []);
      GlobalUnlock(hData);
      GlobalFree(hData);
    end;

  end;

  if pDS <> nil then
  begin
    Com_DPrintf('...releasing DS object'#10, []);
    pDS := nil;
  end;

  Com_DPrintf('...freeing DSOUND.DLL'#10, []);

  hWaveOut_ := 0;
  hData := 0;
  hWaveHdr := 0;
  lpData := nil;
  lpWaveHdr := nil;
  dsound_init := false;
  wav_init := false;
end;

{
=========
SNDDMA_InitDirect

Direct-Sound support
=========
}

function SNDDMA_InitDirect(): sndinitstat;
var
  dscaps: TDSCAPS;
  hresult_: HRESULT;
begin
  dma.channels := 2;
  dma.samplebits := 16;

  if Trunc(s_khz^.value) = 44 then
    dma.speed := 44100;
  if Trunc(s_khz^.value) = 22 then
    dma.speed := 22050
  else
    dma.speed := 11025;

  Com_Printf('Initializing DirectSound'#10, []);

  // Juha: This doesn't look original, since DirectSound.pas does this already
  Com_DPrintf('...loading dsound.dll: ', []);
  if DSoundDLL = 0 then
  begin
    Com_Printf('failed'#10, []);
    Result := SIS_FAILURE;
    Exit;
  end;

  Com_DPrintf('ok'#10, []);

  if @DirectSoundCreate = nil then
  begin
    Com_Printf('*** couldn''t get DS proc addr ***'#10, []);
    Result := SIS_FAILURE;
    Exit;
  end;

  Com_DPrintf('...creating DS object: ', []);

  hresult_ := DirectSoundCreate(nil, pDS, nil);

  while hresult_ <> DS_OK do
  begin
    if hresult_ <> DSERR_ALLOCATED then
    begin
      Com_Printf('failed'#10, []);
      Result := SIS_FAILURE;
      Exit;
    end;

    if (MessageBox(0, 'The sound hardware is in use by another app.'#10#10 +
      'Select Retry to try to start sound again or Cancel to run Quake with no sound.',
      'Sound not available',
      MB_RETRYCANCEL or MB_SETFOREGROUND or MB_ICONEXCLAMATION) <> IDRETRY) then
    begin
      Com_Printf('failed, hardware already in use'#10, []);
      Result := SIS_NOTAVAIL;
      Exit;
    end;
  end;
  Com_DPrintf('ok'#10, []);

  dscaps.dwSize := sizeof(dscaps);

  if DS_OK <> pDS.GetCaps(dscaps) then
    Com_Printf('*** couldn''t get DS caps ***'#10, []);

  if (dscaps.dwFlags and DSCAPS_EMULDRIVER <> 0) then
  begin
    Com_DPrintf('...no DSound driver found'#10, []);
    FreeSound();
    Result := SIS_FAILURE;
    Exit;
  end;

  if not DS_CreateBuffers() then
  begin
    Result := SIS_FAILURE;
    Exit;
  end;
  dsound_init := true;
  Com_DPrintf('...completed successfully'#10, []);
  Result := SIS_SUCCESS;
end;

{
=========
SNDDM_InitWav

Crappy windows multimedia base
=========
}

function SNDDMA_InitWav(): boolean;
var
  format: TWAVEFORMATEX;
  i: integer;
  hr: HRESULT;
begin
  Com_Printf('Initializing wave sound'#10, []);

  snd_sent := 0;
  snd_completed := 0;

  dma.channels := 2;
  dma.samplebits := 16;

  if Trunc(s_khz^.value) = 44 then
    dma.speed := 44100;
  if Trunc(s_khz^.value) = 22 then
    dma.speed := 22050
  else
    dma.speed := 11025;

  FillChar(format, sizeof(format), 0);
  format.wFormatTag := WAVE_FORMAT_PCM;
  format.nChannels := dma.channels;
  format.wBitsPerSample := dma.samplebits;
  format.nSamplesPerSec := dma.speed;
  format.nBlockAlign := format.nChannels * format.wBitsPerSample div 8;
  format.cbSize := 0;
  format.nAvgBytesPerSec := format.nSamplesPerSec * format.nBlockAlign;

  { Open a waveform device for output using window callback. }
  Com_DPrintf('...opening waveform device: ', []);
  hr := waveOutOpen(@hWaveOut_, WAVE_MAPPER,
    @format, 0, 0, CALLBACK_NULL);
  while hr <> MMSYSERR_NOERROR do
  begin
    if hr <> MMSYSERR_ALLOCATED then
    begin
      Com_Printf('failed'#10, []);
      Result := false;
      Exit;
    end;

    if MessageBox(0, 'The sound hardware is in use by another app.'#10#10 +
      'Select Retry to try to start sound again or Cancel to run Quake 2 with no sound.',
      'Sound not available', MB_RETRYCANCEL or MB_SETFOREGROUND or MB_ICONEXCLAMATION) <> IDRETRY then
    begin
      Com_Printf('hw in use'#10, []);
      Result := false;
      Exit;
    end;
  end;
  Com_DPrintf('ok'#10, []);

  {
   * Allocate and lock memory for the waveform data. The memory
   * for waveform data must be globally allocated with
   * GMEM_MOVEABLE and GMEM_SHARE flags.

  }
  Com_DPrintf('...allocating waveform buffer: ', []);
  gSndBufSize := WAV_BUFFERS * WAV_BUFFER_SIZE;
  hData := GlobalAlloc(GMEM_MOVEABLE or GMEM_SHARE, gSndBufSize);
  if (hData = 0) then
  begin
    Com_Printf(' failed'#10, []);
    FreeSound();
    Result := false;
    Exit;
  end;
  Com_DPrintf('ok'#10, []);

  Com_DPrintf('...locking waveform buffer: ', []);
  lpData := GlobalLock(hData);
  if lpData = nil then
  begin
    Com_Printf(' failed'#10, []);
    FreeSound();
    Result := false;
    Exit;
  end;
  FillChar(lpData^, gSndBufSize, 0);
  Com_DPrintf('ok'#10, []);

  {
   * Allocate and lock memory for the header. This memory must
   * also be globally allocated with GMEM_MOVEABLE and
   * GMEM_SHARE flags.
   }
  Com_DPrintf('...allocating waveform header: ', []);
  hWaveHdr := GlobalAlloc(GMEM_MOVEABLE or GMEM_SHARE,
    DWORD(sizeof(WAVEHDR) * WAV_BUFFERS));

  if hWaveHdr = 0 then
  begin
    Com_Printf('failed'#10, []);
    FreeSound();
    Result := false;
    Exit;
  end;
  Com_DPrintf('ok'#10, []);

  Com_DPrintf('...locking waveform header: ', []);
  lpWaveHdr := GlobalLock(hWaveHdr);

  if lpWaveHdr = nil then
  begin
    Com_Printf('failed'#10, []);
    FreeSound();
    Result := false;
    Exit;
  end;
  FillChar(lpWaveHdr^, sizeof(WAVEHDR) * WAV_BUFFERS, 0);
  Com_DPrintf('ok'#10, []);

  { After allocation, set up and prepare headers. }
  Com_DPrintf('...preparing headers: ', []);
  for i := 0 to WAV_BUFFERS - 1 do
  begin
    lpWaveHdr[i].dwBufferLength := WAV_BUFFER_SIZE;
    lpWaveHdr[i].lpData := Pointer(Cardinal(lpData) + i * WAV_BUFFER_SIZE);

    if waveOutPrepareHeader(hWaveOut_, @lpWaveHdr[i], sizeof(WAVEHDR)) <>
      MMSYSERR_NOERROR then
    begin
      Com_Printf('failed'#10, []);
      FreeSound();
      Result := False;
      Exit;
    end;
  end;
  Com_DPrintf('ok'#10, []);

  dma.samples := gSndBufSize div (dma.samplebits div 8);
  dma.samplepos := 0;
  dma.submission_chunk := 512;
  dma.buffer := PByte(lpData);
  sample16 := dma.samplebits div 8 - 1;
  wav_init := True;
  Result := True;
end;

{
=========
SNDDMA_Init

Try to find a sound device to mix for.
Returns false if nothing is found.
=========
}

function SNDDMA_Init(): boolean;
var
  stat: sndinitstat;

begin
  FillChar(dma, sizeof(dma), 0);
  s_wavonly := Cvar_Get('s_wavonly', '0', 0);
  dsound_init := false;
  wav_init := false;
  stat := SIS_FAILURE;                  // assume DirectSound won't initialize
  { Init DirectSound }
  if s_wavonly^.value = 0 then
  begin
    if (snd_firsttime or snd_isdirect) then
    begin
      stat := SNDDMA_InitDirect();
      if stat = SIS_SUCCESS then
      begin
        snd_isdirect := true;
        if snd_firsttime then
          Com_Printf('dsound init succeeded'#10, []);
      end
      else
      begin
        snd_isdirect := false;
        Com_Printf('*** dsound init failed ***'#10, []);
      end;
    end;
  end;

  // if DirectSound didn't succeed in initializing, try to initialize
  // waveOut sound, unless DirectSound failed because the hardware is
  // already allocated (in which case the user has already chosen not
  // to have sound)
  if (not dsound_init) and (stat <> SIS_NOTAVAIL) then
  begin
    if snd_firsttime or snd_iswave then
    begin
      snd_iswave := SNDDMA_InitWav();
      if snd_iswave then
      begin
        if (snd_firsttime) then
          Com_Printf('Wave sound init succeeded'#10, []);
      end
      else
        Com_Printf('Wave sound init failed'#10, []);
    end;
  end;

  snd_firsttime := false;
  snd_buffer_count := 1;
  if (not dsound_init) and (not wav_init) then
  begin
    if snd_firsttime then
      Com_Printf('*** No sound device initialized ***'#10, []);
    Result := False;
    Exit;
  end;
  Result := True;
end;

{
=======
SNDDMA_GetDMAPos

return the current sample position (in mono samples read)
inside the recirculating dma buffer, so the mixing code will know
how many sample are required to fill it up.
========
}

function SNDDMA_GetDMAPos(): integer;
var
  mmtime_: MMTIME;
  s: Integer;
  dwWrite: DWORD;
begin
  if dsound_init then
  begin
    mmtime_.wType := TIME_SAMPLES;
    pDSBuf.GetCurrentPosition(@mmtime_.sample, @dwWrite);
    s := Integer(mmtime_.sample) - mmstarttime.sample;
  end
  else if wav_init then
  begin
    s := snd_sent * WAV_BUFFER_SIZE;
  end;

  s := s shr sample16;
  s := s and (dma.samples - 1);
  Result := s;
end;

{
=======
SNDDMA_BeginPainting

Makes sure dma.buffer is valid
========
}
var
  locksize: DWORD;

procedure SNDDMA_BeginPainting();
var
  reps: integer;
  dwSize2: DWORD;
  pbuf, pbuf2: Pointer;
  hresult_: HRESULT;
  dwStatus: DWORD;
begin
  if Assigned(pDSBuf) then
  begin
    // if the buffer was lost or stopped, restore it and/or restart it
    if pDSBuf.GetStatus(dwStatus) <> DS_OK then
      Com_Printf('Couldn''t get sound buffer status'#10, []);

    if (dwStatus and DSBSTATUS_BUFFERLOST <> 0) then
      pDSBuf.Restore();

    if not (dwStatus and DSBSTATUS_PLAYING <> 0) then
      pDSBuf.Play(0, 0, DSBPLAY_LOOPING);

    // lock the dsound buffer

    reps := 0;
    dma.buffer := nil;
    hresult_ := pDSBuf.Lock(0, gSndBufSize, pbuf,
      locksize, pbuf2, dwSize2, 0);
    while hresult_ <> DS_OK do
    begin
      if hresult_ <> DSERR_BUFFERLOST then
      begin
        Com_Printf('S_TransferStereo16: Lock failed with error "%s"'#10, [DSoundError(hresult_)]);
        S_Shutdown();
        Exit;
      end
      else
      begin
        pDSBuf.Restore();
      end;
      Inc(reps);
      if (reps > 2) then
        Exit;
      hresult_ := pDSBuf.Lock(0, gSndBufSize, pbuf,
        locksize, pbuf2, dwSize2, 0);
    end;
    dma.buffer := PByte(pbuf);
  end;
end;

{
=======
SNDDMA_Submit

Send sound to device if buffer isn't really the dma buffer
Also unlocks the dsound buffer
========
}

procedure SNDDMA_Submit();
var
  h: PWAVEHDR;
  wResult: integer;
begin
  if dma.buffer <> nil then
  begin
    // unlock the dsound buffer
    if pDSBuf <> nil then
      pDSBuf.Unlock(dma.buffer, locksize, nil, 0);

    if wav_init then
    begin
      //
      // find which sound blocks have completed
      //
      while 1 > 0 do
      begin
        if (snd_completed = snd_sent) then
        begin
          Com_DPrintf('Sound overrun'#10, []);
          exit;
        end;
        if not (lpWaveHdr[snd_completed and WAV_MASK].dwFlags and WHDR_DONE <> 0) then
          break;
        snd_completed := snd_completed + 1; // this buffer has been played
      end;

      //Com_Printf ('completed %i'#10, snd_completed); break
      //
      // submit a few new sound blocks
      //
      while (((snd_sent - snd_completed) shr sample16) < 8) do
      begin
        h := @lpWaveHdr[(snd_sent and WAV_MASK)];
        if (paintedtime / 256 <= snd_sent) then
          break;                        //   Com_Printf ('submit overrun'#10);
        //Com_Printf ('send %i'#10, snd_sent);
        snd_sent := snd_sent + 1;
        {
         * Now the data block can be sent to the output device. The
         * waveOutWrite function returns immediately and waveform
         * data is sent to the output device in the background.
         }
        wResult := waveOutWrite(hWaveOut_, h, sizeof(WAVEHDR));

        if wResult <> MMSYSERR_NOERROR then
        begin
          Com_Printf('Failed to write block to device'#10, []);
          FreeSound();
          exit;
        end;
      end;
    end;
  end;
end;

{
=======
SNDDMA_Shutdown

Reset the sound device for exiting
========
}

procedure SNDDMA_Shutdown();
begin
  FreeSound();
end;

{
======
S_Activate

Called when the main window gains or loses focus.
The window have been destroyed and recreated
between a deactivate and an activate.
======
}

procedure S_Activate(active: qboolean);
begin
  if active then
  begin
    if (pDS <> nil) and (cl_hwnd <> 0) and (snd_isdirect) then
      DS_CreateBuffers();
  end
  else
  begin
    if (pDS <> nil) and (cl_hwnd <> 0) and (snd_isdirect) then
      DS_DestroyBuffers();
  end;
end;

end.
