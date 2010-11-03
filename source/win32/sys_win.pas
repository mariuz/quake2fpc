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
{ File(s): sys_win.c                                                         }
{                                                                            }
{ Initial conversion by : Softland (softland_gh@ureach.com)                  }
{ Initial conversion on : 07-Jan-2002                                        }
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
{ Updated by : Juha Hartikainen (juha@linearteam.org)                        }
{ - Fixed uses clause                                                        }
{----------------------------------------------------------------------------}

unit sys_win;

interface

uses
  Windows,
  q_shared;

const
  MINIMUM_WIN_MEMORY = $0A00000;
  MAXIMUM_WIN_MEMORY = $1000000;
  MAX_NUM_ARGVS = 128;

var
  s_win95: qboolean;
  starttime: Integer;
  ActiveApp: Integer;
  Minimized: qboolean;
  hinput: THandle;
  houtput: THandle;
  sys_msg_time: Cardinal;
  sys_frame_time: Cardinal;
  qwclsemaphore: THandle;
  argc: Integer;
  argv: array[0..MAX_NUM_ARGVS - 1] of PChar;
  console_text: array[0..255] of Char;
  console_textlen: Integer;
  game_library: HINST;
  global_hInstance: HINST;

procedure Sys_Error(error: PChar; args: array of const);
procedure Sys_Quit;
function Sys_ScanForCD: PChar;
procedure Sys_CopyProtect;
procedure Sys_Init;
function Sys_ConsoleInput: PChar;
procedure Sys_ConsoleOutput(aString: PChar);
procedure Sys_SendKeyEvents;
function Sys_GetClipboardData: PChar;
procedure Sys_AppActivate;
procedure Sys_Unloadgame;
function Sys_GetGameAPI(parms: Pointer): Pointer;

procedure WinError;
procedure ParseCommandLine(lpCmdLine: LPSTR);
function WinMain(hInstance, hPrevInstance: HINST; lpCmdLine: LPSTR; nCmdShow: Integer): Integer; stdcall;

implementation

uses
  SysUtils,
  MMSystem,
  Math,
  Files,
  Common,
  cl_main,
  conproc,
  vid_dll,
  q_shwin;

var

  // Those are only used by Sys_ScanForCD.
  cddir: array[0..MAX_OSPATH - 1] of Char;
  done: qboolean;

procedure Sys_Error(error: PChar; args: array of const);
var
  text: string;
begin
  CL_Shutdown;
  Qcommon_Shutdown;

  // Report error.
  text := Format(error, args);
  MessageBox(0, PChar(text), 'Error', 0 { MB_OK});

  if qwclsemaphore <> 0 then
    CloseHandle(qwclsemaphore);
  DeinitConProc;

  Halt(1);
end;

procedure Sys_Quit;
begin
  timeEndPeriod(1);
  CL_Shutdown;
  Qcommon_Shutdown;
  CloseHandle(qwclsemaphore);
  if (dedicated <> nil) and (dedicated.value <> 0) then
    FreeConsole;
  DeinitConProc();

  Halt(0);
end;

procedure WinError;
var
  lpMsgBuf: PChar;
begin
  FormatMessage(
    FORMAT_MESSAGE_ALLOCATE_BUFFER or FORMAT_MESSAGE_FROM_SYSTEM,
    nil,
    GetLastError,
    (SUBLANG_DEFAULT shl 10) or LANG_NEUTRAL,
    PChar(@lpMsgBuf),
    0,
    nil);
  MessageBox(0, lpMsgBuf, 'GetLastError', MB_OK or MB_ICONINFORMATION);
  LocalFree(HLOCAL(lpMsgBuf));          // Frees the buffer allocated by FormatMessage.
end;

function Sys_ScanForCD: PChar;

{$IFNDEF DEMO}

var
  path: string;
  drive: string;

{$ENDIF}

begin

{$IFNDEF DEMO}

  // Don't re-check.
  if done then
  begin
    Result := cddir;
    Exit;
  end;

  // no abort/retry/fail errors
  SetErrorMode(SEM_FAILCRITICALERRORS);

  drive := 'c:\';
  done := True;

  // Start scanning for the CD-ROM drive on which "quake2.exe" exists.
  while drive[1] <= 'z' do
  begin
    path := drive + 'install\data';
    Move(PChar(path)^, cddir, Length(path));
    if FileExists(path + '\quake2.exe') then
      if GetDriveType(PChar(drive)) = DRIVE_CDROM then
      begin
        Result := cddir;
        Exit;
      end;
    Inc(drive[1]);
  end;

{$ENDIF}

  cddir[0] := #0;
  Result := nil;
end;

procedure Sys_CopyProtect;

{$IFNDEF DEMO}

var
  cddir: PChar;

{$ENDIF}

begin

{$IFNDEF DEMO}

  cddir := Sys_ScanForCD;
  if cddir^ = #0 then
    Com_Error(ERR_FATAL, 'You must have the Quake2 CD in the drive to play.');

{$ENDIF}

end;

procedure Sys_Init;
var
  vinfo: OSVERSIONINFO;
begin
  {

    // Mutex will fail if semaphore already exists.
    qwclsemaphore := CreateMutex(nil, False, 'qwcl');
    if qwclsemaphore = 0 then
      Sys_Error('QWCL is already running on this system', []);
    CloseHandle(qwclsemaphore);

    // Allocate a named semaphore on the client,
    // so that the front end can tell if it is alive.
    qwclsemaphore := CreateSemaphore(nil, 0, 1, 'qwcl');

  }

    // Juha: Needed for Delphi.
  Randomize;

  timeBeginPeriod(1);

  // Vhecking version information.
  vinfo.dwOSVersionInfoSize := SizeOf(vinfo);
  if not GetVersionEx(vinfo) then
    Sys_Error('Couldn''t get OS info', []);
  if vinfo.dwMajorVersion < 4 then
    Sys_Error('Quake2 requires windows version 4 or greater', []);
  if vinfo.dwPlatformId = VER_PLATFORM_WIN32s then
    Sys_Error('Quake2 doesn''t run on Win32s', [])
  else if vinfo.dwPlatformId = VER_PLATFORM_WIN32_WINDOWS then
    s_win95 := True;

  if dedicated.value <> 0 then
  begin
    if not AllocConsole then
      Sys_Error('Couldn''t create dedicated server console', []);
    hinput := GetStdHandle(STD_INPUT_HANDLE);
    houtput := GetStdHandle(STD_OUTPUT_HANDLE);
    InitConProc(argc, @argv[0]);
  end;
end;

function Sys_ConsoleInput: PChar;
var
  recs: array[0..1023] of INPUT_RECORD;
  dummy: Integer;
  ch, numread, numevents: Integer;
begin
  Result := nil;
  if (dedicated = nil) or (dedicated.value = 0) then
    Exit;

  while True do
  begin

    // End the loop, if there are no console input events.
    if not GetNumberOfConsoleInputEvents(hinput, Cardinal(numevents)) then
      Sys_Error('Error getting # of console events', []);
    if numevents <= 0 then
      Break;

    // Read console input.
    if not ReadConsoleInput(hinput, recs[0], 1, Cardinal(numread)) then
      Sys_Error('Error reading console input', []);
    if numread <> 1 then
      Sys_Error('Couldn''t read console input', []);

    // Process console input.
    if recs[0].EventType = KEY_EVENT then
      if not recs[0].Event.KeyEvent.bKeyDown then
      begin
        ch := Integer(recs[0].Event.KeyEvent.AsciiChar);
        case ch of
          13:                           // Pressed key = [Enter]
            begin
              WriteFile(houtput, #13#10, 2, Cardinal(dummy), nil);
              if console_textlen <> 0 then
              begin
                console_text[console_textlen] := #0;
                console_textlen := 0;
                Result := console_text;
                Exit;
              end;
            end;
          08:                           // Pressed key = [BACK SPACE]
            if console_textlen > 0 then
            begin
              Dec(console_textlen);
              WriteFile(houtput, #8#32#8, 3, Cardinal(dummy), nil);
            end;
        else                            // Otherwise
          if ch >= 32 then
            if console_textlen < (SizeOf(console_textlen) - 2) then
            begin
              WriteFile(houtput, ch, 1, Cardinal(dummy), nil);
              console_text[console_textlen] := Chr(ch);
              Inc(console_textlen);
            end;
        end;
      end;
  end;
end;

procedure Sys_ConsoleOutput(aString: PChar);
var
  dummy: Integer;
  text: array[0..255] of Char;
begin
  if (dedicated = nil) or (dedicated.value = 0) then
    Exit;

  // Erase what currently appears on the console's command line.
  if console_textlen <> 0 then
  begin
    text[0] := #13;
    FillChar(text[1], console_textlen, ' ');
    text[console_textlen + 1] := #13;
    text[console_textlen + 2] := #0;
    WriteFile(houtput, text, console_textlen + 2, Cardinal(dummy), nil);
  end;

  // Output the string.
  WriteFile(houtput, aString^, StrLen(aString), Cardinal(dummy), nil);

  // Re-type what has been erased.
  if console_textlen <> 0 then
    WriteFile(houtput, console_text, console_textlen, Cardinal(dummy), nil);
end;

procedure Sys_SendKeyEvents;
var
  aMsg: TMSG;
begin
  while PeekMessage(aMsg, 0, 0, 0, PM_NOREMOVE) do
  begin
    if not GetMessage(aMsg, 0, 0, 0) then
      Sys_Quit;
    sys_msg_time := aMsg.time;
    TranslateMessage(aMsg);
    DispatchMessage(aMsg);
  end;
  sys_frame_time := timeGetTime;
end;

function Sys_GetClipboardData: PChar;
var
  data: PChar;
  cliptext: PChar;
  hClipboardData: THandle;
begin
  data := nil;
  if OpenClipboard(0) then
  begin
    hClipboardData := GetClipboardData(CF_TEXT);
    if hClipboardData <> 0 then
    begin
      cliptext := GlobalLock(hClipboardData);
      if cliptext <> nil then
      begin
        GetMem(data, GlobalSize(hClipboardData) + 1);
        StrCopy(data, cliptext);
        GlobalUnlock(hClipboardData);
      end;
    end;
    CloseClipboard;
  end;
  Result := data;
end;

procedure Sys_AppActivate;
begin
  ShowWindow(cl_hwnd, SW_RESTORE);
  SetForegroundWindow(cl_hwnd);
end;

procedure Sys_Unloadgame;
begin
  if not FreeLibrary(game_library) then
    Com_Error(ERR_FATAL, 'FreeLibrary failed for game library');
  game_library := 0;
end;

function Sys_GetGameAPI(parms: Pointer): Pointer;
var
  GetGameAPI: function(parms: Pointer): Pointer; cdecl;
  name: array[0..MAX_OSPATH - 1] of Char;
  cwd: array[0..MAX_OSPATH - 1] of Char;
  path: PChar;

const
  gamename: PChar = 'gamex86.dll';
{$IFNDEF DEBUG}
  debugdir: PChar = 'release';
{$ELSE}
  debugdir: PChar = 'debug';
{$ENDIF}

begin
  if game_library <> 0 then
    Com_Error(ERR_FATAL, 'Sys_GetGameAPI without Sys_UnloadingGame');

  // Check the current debug directory first, for development purposes.
  GetCurrentDirectory(SizeOf(cwd), @cwd);
  Com_sprintf(name, SizeOf(name), '%s/%s/%s', [cwd, debugdir, gamename]);
  game_library := LoadLibrary(name);
  if game_library <> 0 then
    Com_DPrintf('LoadLibrary (%s)'#10, [name])
  else
  begin

{$IFDEF DEBUG}

    // Not found? Check the current directory, for other development purposes
    Com_sprintf(name, SizeOf(name), '%s/%s', [cwd, gamename]);
    game_library := LoadLibrary(name);
    if game_library <> 0 then
      Com_DPrintf('LoadLibrary (%s)'#10, [name])
    else

{$ENDIF}

    begin

      // Still not found? Run through the search paths
      path := nil;
      while True do
      begin
        path := FS_NextPath(path);
        if path = nil then
        begin
          Result := nil;
          Exit;
        end;
        Com_sprintf(name, SizeOf(name), '%s/%s', [path, gamename]);
        game_library := LoadLibrary(name);
        if game_library <> 0 then
        begin
          Com_DPrintf('LoadLibrary (%s)'#10, [name]);
          Break;
        end;
      end;

    end;

  end;

  // Gets here, if the library was found.
  GetGameAPI := GetProcAddress(game_library, 'GetGameAPI');
  if not Assigned(GetGameAPI) then
  begin
    Sys_Unloadgame;
    Result := nil;
    Exit;
  end;

  Result := GetGameAPI(parms);
end;

procedure ParseCommandLine(lpCmdLine: LPSTR);
begin
  argc := 1;
  argv[0] := 'exe';

  // This is to break the command line string down to one or more sub-strings,
  // so that each sub-string contains one argument.
  // In addition, it calculates the number of the arguments.
  while (lpCmdLine^ <> #0) and (argc < MAX_NUM_ARGVS) do
  begin
    // Skip "white-space" to the first/next argument.
    while (lpCmdLine^ <> #0) and ((Ord(lpCmdLine^) <= 32) or (Ord(lpCmdLine^) > 126)) do
      Inc(lpCmdLine);

    // Check to see if it's the end of the command line.
    if lpCmdLine^ <> #0 then
    begin
      // Keep a new reference (pointer) to the argument
      argv[argc] := lpCmdLine;
      Inc(argc);

      // Skip the argument to the next white space.
      while (lpCmdLine^ <> #0) and ((Ord(lpCmdLine^) > 32) and (Ord(lpCmdLine^) <= 126)) do
        Inc(lpCmdLine);

      // Split the command line between the arguments,
      // by placing a zero after the end of each argument.
      if lpCmdLine^ <> #0 then
      begin
        lpCmdLine^ := #0;
        Inc(lpCmdLine);
      end;
    end;
  end;
end;

function WinMain(hInstance, hPrevInstance: HINST; lpCmdLine: LPSTR; nCmdShow: Integer): Integer; stdcall;
var
  aMsg: TMSG;
  time, oldtime, newtime: Integer;
  cddir: PChar;
  i: Integer;
begin

  // This is to make sure that previous instances do not exist.
  if hPrevInstance <> 0 then
  begin
    Result := 0;
    Exit;
  end;

  global_hInstance := hInstance;
  ParseCommandLine(lpCmdLine);
  cddir := Sys_ScanForCD;

  if (cddir <> nil) and (argc < MAX_NUM_ARGVS - 3) then
  begin
    i := 0;

    // Search for "cddir" in the command line.
    while i < argc do
    begin
      if StrComp(argv[i], 'cddir') = 0 then
        Break;
      i := i + 1;
    end;

    // If "cddir" is not in the command line,
    // add the following arguments: "+set", "cddir" and the value of cddir.
    if i = argc then
    begin
      argv[argc] := '+set';
      Inc(argc);
      argv[argc] := 'cddir';
      Inc(argc);
      argv[argc] := cddir;
      Inc(argc);
    end;
  end;

  // Initialize Quake2.
  Qcommon_Init(argc, @argv[0]);
  oldtime := Sys_Milliseconds;

  // The main window message loop.
  while True do
  begin
    if Minimized or ((dedicated <> nil) and (dedicated.value <> 0)) then
      Sleep(1);

    // Process messages.
    while PeekMessage(aMsg, 0, 0, 0, PM_NOREMOVE) do
    begin
      if not GetMessage(aMsg, 0, 0, 0) then
        Com_Quit;
      sys_msg_time := aMsg.time;
      TranslateMessage(aMsg);
      DispatchMessage(aMsg);
    end;

    // Wait more than 1 ms.
    repeat
      newtime := Sys_Milliseconds;
      time := newtime - oldtime;
    until time >= 1;

    {
    Con_Printf('time:%5.2f - %5.2f = %5.2f'#10, [newtime, oldtime, time]);
    SetExceptionMask([exDenormalized, exOverflow, exUnderflow, exPrecision]);
    }

    SetPrecisionMode(pmExtended);
    Qcommon_Frame(time);

    oldtime := newtime;
  end;

  Result := 1;
end;

end.
