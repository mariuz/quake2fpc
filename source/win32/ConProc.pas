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
{ File(s): conproc.h, conproc.c                                              }
{ Content: Quake2\Win32\ support for qhost                                   }
{                                                                            }
{ Initial conversion by : Clootie (Alexey Barkovoy) - clootie@reactor.ru     }
{ Initial conversion on : 06-Mar-2002                                        }
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
{ * Updated:                                                                 }
{                                                                            }
{----------------------------------------------------------------------------}

unit ConProc;

interface

// conproc.h -- support for qhost

procedure InitConProc(argc: Integer; argv: PPChar);
procedure DeinitConProc;

implementation

uses
  Windows,
  SysUtils;

const
  CCOM_WRITE_TEXT = $2;
  // Param1 : Text

  CCOM_GET_TEXT = $3;
  // Param1 : Begin line
  // Param2 : End line

  CCOM_GET_SCR_LINES = $4;
  // No params

  CCOM_SET_SCR_LINES = $5;
  // Param1 : Number of lines

var
  heventDone: THandle;
  hfileBuffer: THandle;
  heventChildSend: THandle;
  heventParentSend: THandle;
  hStdout: THandle;
  hStdin: THandle;

  //Clootie: no need if we call Delphi's BeginThread
  //function RequestProc(arg: Pointer): Cardinal; stdcall;  forward;
function RequestProc(arg: Pointer): Integer; forward;
function GetMappedBuffer(hfileBuffer: THandle): Pointer; forward;
procedure ReleaseMappedBuffer(pBuffer: Pointer); forward;
function GetScreenBufferLines(out piLines: Integer): LongBool; forward;
function SetScreenBufferLines(iLines: Integer): LongBool; forward;
function ReadText(pszText: PChar; iBeginLine, iEndLine: Integer): LongBool; forward;
function WriteText(szText: PChar): LongBool; forward;
function CharToCode(c: Char): Integer; forward;
function SetConsoleCXCY(hStdout: THandle; cx, cy: Integer): LongBool; forward;

type
  //Clootie: Object Pascal introduced types
  PComArgvArray = ^TComArgvArray;
  TComArgvArray = array[0..MaxInt div SizeOf(PChar) - 1] of PChar;

var
  ccom_argc: Integer;
  ccom_argv: PComArgvArray;

  (*
  ================
  CCheckParm

  Returns the position (1 to argc-1) in the program's argument list
  where the given parameter apears, or 0 if not present
  ================
  *)

function CCheckParm(parm: PChar): Integer;
var
  i: Integer;
begin
  for i := 1 to ccom_argc - 1 do
  begin
    if (ccom_argv[i] = nil) then
      Continue;

    if (StrComp(parm, ccom_argv[i]) = 0) then
    begin
      Result := i;
      Exit;
    end;
  end;

  Result := 0;
end;

procedure InitConProc(argc: Integer; argv: PPChar);
var
  threadAddr: Cardinal;
  hFile: THandle;
  heventParent: THandle;
  heventChild: THandle;
  t: Integer;
begin
  hFile := 0;
  heventParent := 0;
  heventChild := 0;

  ccom_argc := argc;
  ccom_argv := PComArgvArray(argv);

  // give QHOST a chance to hook into the console
  t := CCheckParm('-HFILE');
  if (t > 0) then
  begin
    if (t < argc) then
      hFile := StrToInt(ccom_argv[t + 1]);
  end;

  t := CCheckParm('-HPARENT');
  if (t > 0) then
  begin
    if (t < argc) then
      heventParent := StrToInt(ccom_argv[t + 1]);
  end;

  t := CCheckParm('-HCHILD');
  if (t > 0) then
  begin
    if (t < argc) then
      heventChild := StrToInt(ccom_argv[t + 1]);
  end;

  // ignore if we don't have all the events.
  if (hFile = 0) or (heventParent = 0) or (heventChild = 0) then
  begin
    Write('Qhost not present.'#10);     // printf(...)
    Exit;
  end;

  Write('Initializing for qhost.'#10);  // printf(...)

  hfileBuffer := hFile;
  heventParentSend := heventParent;
  heventChildSend := heventChild;

  // so we'll know when to go away.
  heventDone := CreateEvent(nil, False, False, nil);

  if (heventDone = 0) then
  begin
    Write('Couldn''t create heventDone'#10); // printf(...)
    Exit;
  end;

  //todo: Clootie: Watch do we need to adopt C way of thread sync
  // if (!_beginthreadex (NULL, 0, RequestProc, NULL, 0, &threadAddr))
  if (BeginThread(nil, 0, RequestProc, nil, 0, threadAddr) <> 0) then
  begin
    CloseHandle(heventDone);
    Write('Couldn''t create QHOST thread'#10); // printf(...)
    Exit;
  end;

  // save off the input/output handles.
    //Clootie: What it will do with Delphi "in/out" std files?
  hStdout := GetStdHandle(STD_OUTPUT_HANDLE);
  hStdin := GetStdHandle(STD_INPUT_HANDLE);

  // force 80 character width, at least 25 character height
  SetConsoleCXCY(hStdout, 80, 25);
end;

procedure DeinitConProc;
begin
  if (heventDone <> 0) then
    SetEvent(heventDone);
end;

function RequestProc(arg: Pointer): Integer;
var
  pBuffer: PIntegerArray;
  dwRet: DWORD;
  heventWait: array[0..1] of THandle;
  iBeginLine, iEndLine: Integer;
begin
  heventWait[0] := heventParentSend;
  heventWait[1] := heventDone;

  while True do
  begin
    dwRet := WaitForMultipleObjects(2, @heventWait, False, INFINITE);

    // heventDone fired, so we're exiting.
    if (dwRet = WAIT_OBJECT_0 + 1) then
      Break;

    pBuffer := GetMappedBuffer(hfileBuffer);

    // hfileBuffer is invalid.  Just leave.
    if (pBuffer = nil) then
    begin
      Write('Invalid hfileBuffer'#10);  // printf(...)
      Break;
    end;

    case pBuffer[0] of
      CCOM_WRITE_TEXT:
        // Param1 : Text
        pBuffer[0] := Integer(WriteText(PChar(pBuffer) + 1));

      CCOM_GET_TEXT:
        // Param1 : Begin line
        // Param2 : End line
        begin
          iBeginLine := pBuffer[1];
          iEndLine := pBuffer[2];
          pBuffer[0] := Integer(ReadText(PChar(pBuffer) + 1, iBeginLine, iEndLine));
        end;

      CCOM_GET_SCR_LINES:
        // No params
        pBuffer[0] := Integer(GetScreenBufferLines(pBuffer[1]));

      CCOM_SET_SCR_LINES:
        // Param1 : Number of lines
        pBuffer[0] := Integer(SetScreenBufferLines(pBuffer[1]));
    end;

    ReleaseMappedBuffer(pBuffer);
    SetEvent(heventChildSend);
  end;

  // _endthreadex (0);
  ExitThread(0);
  Result := 0;
end;

function GetMappedBuffer(hfileBuffer: THandle): Pointer;
begin
  Result := MapViewOfFile(hfileBuffer, FILE_MAP_READ or FILE_MAP_WRITE, 0, 0, 0);
end;

procedure ReleaseMappedBuffer(pBuffer: Pointer);
begin
  UnmapViewOfFile(pBuffer);
end;

function GetScreenBufferLines(out piLines: Integer): LongBool;
var
  info: CONSOLE_SCREEN_BUFFER_INFO;
begin
  Result := GetConsoleScreenBufferInfo(hStdout, info);

  if Result then
    piLines := info.dwSize.Y;
end;

function SetScreenBufferLines(iLines: Integer): LongBool;
begin
  Result := SetConsoleCXCY(hStdout, 80, iLines);
end;

function ReadText(pszText: PChar; iBeginLine, iEndLine: Integer): LongBool;
var
  coord: TCoord;
  dwRead: DWORD;
begin
  coord.X := 0;
  coord.Y := iBeginLine;

  Result := ReadConsoleOutputCharacter(
    hStdout,
    pszText,
    80 * (iEndLine - iBeginLine + 1),
    coord,
    dwRead);

  // Make sure it's null terminated.
  if Result then
    pszText[dwRead] := #0;
end;

function WriteText(szText: PChar): LongBool;
var
  dwWritten: DWORD;
  rec: INPUT_RECORD;
  upper: Char;
  sz: PChar;
begin
  sz := szText;

  while (sz^ <> #0) do
  begin
    // 13 is the code for a carriage return (\n) instead of 10.
    if (sz^ = #10) then
      sz^ := #13;

    upper := UpCase(sz^);

    rec.EventType := KEY_EVENT;
    rec.Event.KeyEvent.bKeyDown := True;
    rec.Event.KeyEvent.wRepeatCount := 1;
    rec.Event.KeyEvent.wVirtualKeyCode := Byte(upper);
    rec.Event.KeyEvent.wVirtualScanCode := CharToCode(sz^);
    rec.Event.KeyEvent. {uChar.} AsciiChar := sz^;
    //Clootie: no need for "UnicodeChar" (in-memory values in record are overlapping)
    // rec.Event.KeyEvent.{uChar.}UnicodeChar := sz^;
    // rec.Event.KeyEvent.dwControlKeyState := isupper(*sz) ? 0x80 : 0x0;
    if (upper = sz^) then
      rec.Event.KeyEvent.dwControlKeyState := $80
    else
      rec.Event.KeyEvent.dwControlKeyState := $00;

    WriteConsoleInput(
      hStdin,
      rec,
      1,
      dwWritten);

    rec.Event.KeyEvent.bKeyDown := False;

    WriteConsoleInput(
      hStdin,
      rec,
      1,
      dwWritten);

    Inc(sz);
  end;

  Result := True;
end;

function CharToCode(c: Char): Integer;
const
  Alpha = ['A'..'Z', 'a'..'z', '_'];
  Digit = ['0'..'9'];
var
  upper: Char;
begin
  upper := UpCase(c);

  if c = #13 then
  begin
    Result := 28;
    Exit;
  end;

  if (c in Alpha) then
  begin
    Result := (30 + Byte(upper) - 65);
    Exit;
  end;

  if (c in Digit) then
  begin
    Result := (1 + Byte(upper) - 47);
    Exit;
  end;

  Result := Byte(c);
end;

function SetConsoleCXCY(hStdout: THandle; cx, cy: Integer): LongBool;
var
  info: CONSOLE_SCREEN_BUFFER_INFO;
  coordMax: TCoord;
begin
  Result := False;

  coordMax := GetLargestConsoleWindowSize(hStdout);

  if (cy > coordMax.Y) then
    cy := coordMax.Y;

  if (cx > coordMax.X) then
    cx := coordMax.X;

  if GetConsoleScreenBufferInfo(hStdout, info) then
    Exit;

  // height
  info.srWindow.Left := 0;
  info.srWindow.Right := info.dwSize.X - 1;
  info.srWindow.Top := 0;
  info.srWindow.Bottom := cy - 1;

  if (cy < info.dwSize.Y) then
  begin
    if SetConsoleWindowInfo(hStdout, True, info.srWindow) then
      Exit;

    info.dwSize.Y := cy;

    if SetConsoleScreenBufferSize(hStdout, info.dwSize) then
      Exit;
  end
  else if (cy > info.dwSize.Y) then
  begin
    info.dwSize.Y := cy;

    if SetConsoleScreenBufferSize(hStdout, info.dwSize) then
      Exit;

    if SetConsoleWindowInfo(hStdout, True, info.srWindow) then
      Exit;
  end;

  if GetConsoleScreenBufferInfo(hStdout, info) then
    Exit;

  // width
  info.srWindow.Left := 0;
  info.srWindow.Right := cx - 1;
  info.srWindow.Top := 0;
  info.srWindow.Bottom := info.dwSize.Y - 1;

  if (cx < info.dwSize.X) then
  begin
    if SetConsoleWindowInfo(hStdout, True, info.srWindow) then
      Exit;

    info.dwSize.X := cx;

    if SetConsoleScreenBufferSize(hStdout, info.dwSize) then
      Exit;
  end
  else if (cx > info.dwSize.X) then
  begin
    info.dwSize.X := cx;

    if SetConsoleScreenBufferSize(hStdout, info.dwSize) then
      Exit;

    if SetConsoleWindowInfo(hStdout, True, info.srWindow) then
      Exit;
  end;

  Result := True;
end;

end.
