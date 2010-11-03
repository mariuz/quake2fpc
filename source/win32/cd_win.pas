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

unit cd_win;

{----------------------------------------------------------------------------}
{                                                                            }
{ File(s): cd_win.c                                                          }
{                                                                            }
{ Initial conversion by : Scott Price (scott.price@totalise.co.uk)           }
{ Initial conversion on : 23-Feb-2002                                        }
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
{ Updated on : 03-jun-2002                                                              }
{ Updated by : Juha Hartikainen                                                              }
{ - Added some units to uses clause to let this compile correctly            }
{ - Fixed miscellannous language errors }
{ - Declared (not yet all) procedures as global in interface section         }
{}
{ Updated on : 04-jun-2002                                                              }
{ Updated by : Juha Hartikainen                                                              }
{ - Declared some functions in interface part}
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{----------------------------------------------------------------------------}

interface

uses
  { Borland Standard Units }
  Windows,
  MMSystem,
  { Quake 2 Units }
  q_shared,
  vid_dll,
  Common,
  CVar,
  Client;

function CDAudio_Init: Integer;
procedure CDAudio_Pause;
procedure CDAudio_Stop;
procedure CDAudio_Eject;
procedure CDAudio_CloseDoor;
function CDAudio_GetAudioDiskInfo: Integer;
procedure CDAudio_Play2(track: Integer; looping: qboolean);
procedure CDAudio_Play(track: Integer; looping: qboolean);
procedure CDAudio_Activate(active: qboolean);
function CDAudio_MessageHandler(hWin: HWND; uMsg: Cardinal; wParam: WPARAM; lParam: LPARAM): Integer;
procedure CDAudio_Update;
procedure CDAudio_Shutdown;

var
  cd_nocd: cvar_p;
  cd_loopcount: cvar_p;
  cd_looptrack: cvar_p;

  wDeviceID: Cardinal;
  loopcounter: Integer;

implementation

uses
  SysUtils,
  Cmd;

var
  { Static Variables }
  cdValid: qboolean = false;
  playing: qboolean = false;
  wasPlaying: qboolean = false;
  initialized: qboolean = false;
  enabled: qboolean = false;
  playLooping: qboolean = false;
  { Byte Array?? }
  remap: array[0..99] of byte;
  playTrack: byte;
  maxTrack: byte;

procedure CDAudio_Eject;
var
  dwReturn: DWORD;
begin
  dwReturn := mciSendCommand(wDeviceID, MCI_SET, MCI_SET_DOOR_OPEN, 0);
  if dwReturn <> 0 then
    Com_DPrintf('MCI_SET_DOOR_OPEN failed (%d)'#10, [dwReturn]);
end;

procedure CDAudio_CloseDoor;
var
  dwReturn: DWORD;
begin
  dwReturn := mciSendCommand(wDeviceID, MCI_SET, MCI_SET_DOOR_CLOSED, 0);
  if dwReturn <> 0 then
    Com_DPrintf('MCI_SET_DOOR_CLOSED failed (%d)'#10, [dwReturn]);
end;

function CDAudio_GetAudioDiskInfo: Integer;
var
  dwReturn: DWORD;
  mciStatusParms: MCI_STATUS_PARMS;
begin
  Result := -1;
  cdValid := false;

  mciStatusParms.dwItem := MCI_STATUS_READY;
  dwReturn := mciSendCommand(wDeviceID, MCI_STATUS, MCI_STATUS_ITEM or MCI_WAIT, DWORD(@mciStatusParms));
  if (dwReturn <> 0) then
  begin
    Com_DPrintf('CDAudio: drive ready test - get status failed'#10, []);
    Exit;
  end;
  if (mciStatusParms.dwReturn = 0) then
  begin
    Com_DPrintf('CDAudio: drive not ready'#10, []);
    Exit;
  end;

  mciStatusParms.dwItem := MCI_STATUS_NUMBER_OF_TRACKS;
  dwReturn := mciSendCommand(wDeviceID, MCI_STATUS, MCI_STATUS_ITEM or MCI_WAIT, dword(@mciStatusParms));
  if (dwReturn <> 0) then
  begin
    Com_DPrintf('CDAudio: get tracks - status failed'#10, []);
    Exit;
  end;
  if (mciStatusParms.dwReturn < 1) then
  begin
    Com_DPrintf('CDAudio: no music tracks'#10, []);
    Exit;
  end;

  cdValid := true;
  maxTrack := mciStatusParms.dwReturn;

  Result := 0;
end;

procedure CDAudio_Play2(track: Integer; looping: qboolean);
var
  dwReturn: DWORD;
  mciPlayParms: MCI_PLAY_PARMS;
  mciStatusParms: MCI_STATUS_PARMS;
begin
  if (not enabled) then
    Exit;

  if (not cdValid) then
  begin
    CDAudio_GetAudioDiskInfo;
    if (not cdValid) then
      Exit;
  end;

  track := remap[track];

  if (track < 1) or (track > maxTrack) then
  begin
    CDAudio_Stop;
    Exit;
  end;

  { don't try to play a non-audio track }
  mciStatusParms.dwItem := MCI_CDA_STATUS_TYPE_TRACK;
  mciStatusParms.dwTrack := track;
  dwReturn := mciSendCommand(wDeviceID, MCI_STATUS, MCI_STATUS_ITEM or MCI_TRACK or MCI_WAIT, dword(@mciStatusParms));
  if (dwReturn <> 0) then
  begin
    Com_DPrintf('MCI_STATUS failed (%d)'#10, [dwReturn]);
    Exit;
  end;
  if (mciStatusParms.dwReturn <> MCI_CDA_TRACK_AUDIO) then
  begin
    Com_Printf('CDAudio: track %d is not audio'#10, [track]);
    Exit;
  end;

  { get the length of the track to be played }
  mciStatusParms.dwItem := MCI_STATUS_LENGTH;
  mciStatusParms.dwTrack := track;
  dwReturn := mciSendCommand(wDeviceID, MCI_STATUS, MCI_STATUS_ITEM or MCI_TRACK or MCI_WAIT, dword(@mciStatusParms));
  if (dwReturn <> 0) then
  begin
    Com_DPrintf('MCI_STATUS failed (%d)'#10, [dwReturn]);
    Exit;
  end;

  if (playing) then
  begin
    if (playTrack = track) then
      Exit;

    CDAudio_Stop;
  end;

  mciPlayParms.dwFrom := MCI_MAKE_TMSF(track, 0, 0, 0);
  mciPlayParms.dwTo := (mciStatusParms.dwReturn shl 8) or Cardinal(track);
  mciPlayParms.dwCallback := cl_hwnd;

  dwReturn := mciSendCommand(wDeviceID, MCI_PLAY, MCI_NOTIFY or MCI_FROM or MCI_TO, dword(@mciPlayParms));
  if (dwReturn <> 0) then
  begin
    Com_DPrintf('CDAudio: MCI_PLAY failed (%d)', [dwReturn]);
    Exit;
  end;

  playLooping := looping;
  playTrack := track;
  playing := true;

  if Cvar_VariableValue('cd_nocd') <> 0 then
    CDAudio_Pause;
end;

procedure CDAudio_Play(track: Integer; looping: qboolean);
begin
  { set a loop counter so that this track will change to the looptrack later }
  loopcounter := 0;
  CDAudio_Play2(track, looping);
end;

procedure CDAudio_Stop;
var
  dwReturn: DWORD;
begin
  if (not enabled) then
    Exit;

  if (not playing) then
    Exit;

  dwReturn := mciSendCommand(wDeviceID, MCI_STOP, 0, 0);
  if (dwReturn <> 0) then
    Com_DPrintf('MCI_STOP failed (%d)', [dwReturn]);

  wasPlaying := false;
  playing := false;
end;

procedure CDAudio_Pause;
var
  dwReturn: DWORD;
  mciGenericParms: MCI_GENERIC_PARMS;
begin
  if (not enabled) then
    Exit;

  if (not playing) then
    Exit;

  mciGenericParms.dwCallback := cl_hwnd;
  dwReturn := mciSendCommand(wDeviceID, MCI_PAUSE, 0, dword(@mciGenericParms));
  if (dwReturn <> 0) then
    Com_DPrintf('MCI_PAUSE failed (%d)', [dwReturn]);

  wasPlaying := playing;
  playing := false;
end;

procedure CDAudio_Resume;
var
  dwReturn: DWORD;
  mciPlayParms: MCI_PLAY_PARMS;
begin
  if (not enabled) then
    Exit;

  if (not cdValid) then
    Exit;

  if (not wasPlaying) then
    Exit;

  mciPlayParms.dwFrom := MCI_MAKE_TMSF(playTrack, 0, 0, 0);
  mciPlayParms.dwTo := MCI_MAKE_TMSF(playTrack + 1, 0, 0, 0);
  mciPlayParms.dwCallback := cl_hwnd;
  dwReturn := mciSendCommand(wDeviceID, MCI_PLAY, MCI_TO or MCI_NOTIFY, dword(@mciPlayParms));

  if (dwReturn <> 0) then
  begin
    Com_DPrintf('CDAudio: MCI_PLAY failed (%d)'#10, [dwReturn]);
    exit;
  end;

  playing := true;
end;

procedure CD_f; cdecl;
const
  pscLooping: PChar = 'looping';
  pscPlaying: PChar = 'playing';
var
  command, DisplayMes: PChar;
  ret, n: Integer;
begin
  if (Cmd_Argc < 2) then
    Exit;

  command := Cmd_Argv(1);

  { TODO:  if (Q_strcasecmp(command, 'on') == 0) }
  if (StrComp(command, 'on') = 0) then
  begin
    enabled := true;
    Exit;
  end;

  { TODO:  if (Q_strcasecmp(command, 'off') == 0) }
  if (StrComp(command, 'off') = 0) then
  begin
    if playing then
      CDAudio_Stop;

    enabled := false;
    Exit;
  end;

  { TODO:  if (Q_strcasecmp(command, "reset") == 0) }
  if (StrComp(command, 'reset') = 0) then
  begin
    enabled := true;
    if playing then
      CDAudio_Stop();

    for n := 0 to 99 do
      remap[n] := n;

    CDAudio_GetAudioDiskInfo;
    Exit;
  end;

  { TODO:  if (Q_strcasecmp(command, "remap") == 0) }
  if (StrComp(command, 'remap') = 0) then
  begin
    ret := Cmd_Argc - 2;
    if (ret <= 0) then
    begin
      for n := 1 to 99 do
        if (remap[n] <> n) then
          Com_Printf('  %u -> %u'#10, [n, remap[n]]);
      Exit;
    end;

    for n := 1 to (ret - 1) do
      remap[n] := StrToInt(Cmd_Argv(n + 1));

    Exit;
  end;

  { TODO:  if (Q_strcasecmp(command, "close") == 0) }
  if (StrComp(command, 'close') = 0) then
  begin
    CDAudio_CloseDoor;
    Exit;
  end;

  if (not cdValid) then
  begin
    CDAudio_GetAudioDiskInfo;
    if (not cdValid) then
    begin
      Com_Printf('No CD in player.'#10, []);
      Exit;
    end;
  end;

  { TODO:  if (Q_strcasecmp(command, "play") == 0) }
  if (StrComp(command, 'play') = 0) then
  begin
    CDAudio_Play(StrToInt(Cmd_Argv(2)), false);
    Exit;
  end;

  { TODO:  if (Q_strcasecmp(command, "loop") == 0) }
  if (StrComp(command, 'loop') = 0) then
  begin
    CDAudio_Play(StrToInt(Cmd_Argv(2)), true);
    Exit;
  end;

  { TODO:  if (Q_strcasecmp(command, "stop") == 0) }
  if (StrComp(command, 'stop') = 0) then
  begin
    CDAudio_Stop;
    Exit;
  end;

  { TODO:  if (Q_strcasecmp(command, "pause") == 0) }
  if (StrComp(command, 'pause') = 0) then
  begin
    CDAudio_Pause;
    Exit;
  end;

  { TODO:  if (Q_strcasecmp(command, "resume") == 0) }
  if (StrComp(command, 'resume') = 0) then
  begin
    CDAudio_Resume;
    Exit;
  end;

  { TODO:  if (Q_strcasecmp(command, "eject") == 0) }
  if (StrComp(command, 'eject') = 0) then
  begin
    if (playing) then
      CDAudio_Stop;

    CDAudio_Eject;
    cdValid := false;
    Exit;
  end;

  { TODO:  if (Q_strcasecmp(command, "info") == 0) }
  if (StrComp(command, 'info') = 0) then
  begin
    Com_Printf('%u tracks'#10, [maxTrack]);
    if (playing) then
    begin
      if playLooping then
        DisplayMes := pscLooping
      else
        DisplayMes := pscPlaying;

      Com_Printf('Currently %s track %u'#10, [DisplayMes, playTrack]);
    end
    else if (wasPlaying) then
    begin
      if playLooping then
        DisplayMes := pscLooping
      else
        DisplayMes := pscPlaying;

      Com_Printf('Paused %s track %u'#10, [DisplayMes, playTrack]);
    end;
  end;
end;

function CDAudio_MessageHandler(hWin: HWND; uMsg: Cardinal; wParam: WPARAM; lParam: LPARAM): Integer;
begin
  if (lParam <> Integer(wDeviceID)) then
  begin
    Result := 1;
    Exit;
  end;

  case wParam of
    MCI_NOTIFY_SUCCESSFUL:
      begin
        if playing then
        begin
          playing := false;
          if playLooping then
          begin
            { if the track has played the given number of times,
              go to the ambient track }
            Inc(loopcounter);
            if (loopcounter >= cd_loopcount.value) then
              CDAudio_Play2(Round(cd_looptrack.value), true)
            else
              CDAudio_Play2(playTrack, true);
          end;
        end;
      end;
    MCI_NOTIFY_ABORTED, MCI_NOTIFY_SUPERSEDED:
      begin
        { Do Nothing - especially not default }
      end;
    MCI_NOTIFY_FAILURE:
      begin
        Com_DPrintf('MCI_NOTIFY_FAILURE'#10, []);
        CDAudio_Stop;
        cdValid := false;
      end;
  else
    Com_DPrintf('Unexpected MM_MCINOTIFY type (%d)'#10, [wParam]);
    Result := 1;
    Exit;
  end;

  Result := 0;
end;

procedure CDAudio_Update;
begin
  if (cd_nocd.value <> Integer(not enabled)) then
  begin
    if (cd_nocd.value <> 0) then
    begin
      CDAudio_Stop;
      enabled := false;
    end
    else
    begin
      enabled := true;
      CDAudio_Resume;
    end;
  end;
end;

function CDAudio_Init: Integer;
var
  dwReturn: DWORD;
  mciOpenParms: MCI_OPEN_PARMS;
  mciSetParms: MCI_SET_PARMS;
  n: Integer;
begin
  Result := -1;
  cd_nocd := Cvar_Get('cd_nocd', '0', CVAR_ARCHIVE);
  cd_loopcount := Cvar_Get('cd_loopcount', '4', 0);
  cd_looptrack := Cvar_Get('cd_looptrack', '11', 0);
  if (cd_nocd.value <> 0) then
    Exit;

  mciOpenParms.lpstrDeviceType := 'cdaudio';
  dwReturn := mciSendCommand(0, MCI_OPEN, MCI_OPEN_TYPE or MCI_OPEN_SHAREABLE, dword(@mciOpenParms));
  if (dwReturn <> 0) then
  begin
    Com_Printf('CDAudio_Init: MCI_OPEN failed (%d)'#10, [dwReturn]);
    Exit;
  end;

  wDeviceID := mciOpenParms.wDeviceID;

  { Set the time format to track/minute/second/frame (TMSF). }
  mciSetParms.dwTimeFormat := MCI_FORMAT_TMSF;
  dwReturn := mciSendCommand(wDeviceID, MCI_SET, MCI_SET_TIME_FORMAT, dword(@mciSetParms));
  if (dwReturn <> 0) then
  begin
    Com_Printf('MCI_SET_TIME_FORMAT failed (%d)'#10, [dwReturn]);
    mciSendCommand(wDeviceID, MCI_CLOSE, 0, 0);
    Exit;
  end;

  for n := 0 to 99 do
    remap[n] := n;

  initialized := true;
  enabled := true;

  if CDAudio_GetAudioDiskInfo <> 0 then
  begin
    // Com_Printf('CDAudio_Init: No CD in player.'#10);
    cdValid := false;
    enabled := false;
  end;

  Cmd_AddCommand('cd', CD_f);

  Com_Printf('CD Audio Initialized'#10, []);

  Result := 0;
end;

procedure CDAudio_Shutdown;
begin
  if (not initialized) then
    Exit;

  CDAudio_Stop;
  if (mciSendCommand(wDeviceID, MCI_CLOSE, MCI_WAIT, 0) <> 0) then
    Com_DPrintf('CDAudio_Shutdown: MCI_CLOSE failed'#10, []);
end;

(*
===========
CDAudio_Activate

Called when the main window gains or loses focus.
The window have been destroyed and recreated
between a deactivate and an activate.
===========
*)

procedure CDAudio_Activate(active: qboolean);
begin
  if active then
    CDAudio_Resume
  else
    CDAudio_Pause;
end;

end.
