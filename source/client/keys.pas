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


unit keys;
{----------------------------------------------------------------------------}
{                                                                            }
{ File(s): keys.h,Keys.c - Input handling                                    }
{                                                                            }
{                                                                            }
{ Initial conversion by : ggs (tazipper@lyocs.com)                           }
{ Initial conversion on : -Jan-2002                                        }
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
{ - added needed units to uses clause                                        }
{ - removed NODEPEND hack                                                    }
{}
{ Updated on : 04-jun-2002                                                   }
{ Updated by : Juha Hartikainen (juha@linearteam.org)                        }
{ - Moved keydown variable to globalscopy as qmenu.pas needs it}
{}
{ Updated on : 05-jun-2002                                                   }
{ Updated by : Juha Hartikainen (juha@linearteam.org)                        }
{ - conversion fixes}
{}
{ Updated on : 25-jul-2002                                                   }
{ Updated by : burnin (leonel@linuxbr.com.br)                                }
{ - Uncommented menu calls                                                   }
{----------------------------------------------------------------------------}
{  Key.h is used by Clients.h                                                }
{  Key.h is used by Clients.h                                                }
{ * Still dependent (to compile correctly) on:                               }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{----------------------------------------------------------------------------}

interface

uses
  {$IFDEF WIN32}
  Windows,
  {$ENDIF}
  Client,
  q_shared;

const
  //
  // these are the key numbers that should be passed to Key_Event
  //
  K_TAB = 9;
  K_ENTER = 13;
  K_ESCAPE = 27;
  K_SPACE = 32;

  // normal keys should be passed as lowercased ascii

  K_BACKSPACE = 127;
  K_UPARROW = 128;
  K_DOWNARROW = 129;
  K_LEFTARROW = 130;
  K_RIGHTARROW = 131;

  K_ALT = 132;
  K_CTRL = 133;
  K_SHIFT = 134;
  K_F1 = 135;
  K_F2 = 136;
  K_F3 = 137;
  K_F4 = 138;
  K_F5 = 139;
  K_F6 = 140;
  K_F7 = 141;
  K_F8 = 142;
  K_F9 = 143;
  K_F10 = 144;
  K_F11 = 145;
  K_F12 = 146;
  K_INS = 147;
  K_DEL = 148;
  K_PGDN = 149;
  K_PGUP = 150;
  K_HOME = 151;
  K_END = 152;

  K_KP_HOME = 160;
  K_KP_UPARROW = 161;
  K_KP_PGUP = 162;
  K_KP_LEFTARROW = 163;
  K_KP_5 = 164;
  K_KP_RIGHTARROW = 165;
  K_KP_END = 166;
  K_KP_DOWNARROW = 167;
  K_KP_PGDN = 168;
  K_KP_ENTER = 169;
  K_KP_INS = 170;
  K_KP_DEL = 171;
  K_KP_SLASH = 172;
  K_KP_MINUS = 173;
  K_KP_PLUS = 174;

  K_PAUSE = 255;

  //
  // mouse buttons generate virtual keys
  //
  K_MOUSE1 = 200;
  K_MOUSE2 = 201;
  K_MOUSE3 = 202;

  //
  // joystick buttons
  //
  K_JOY1 = 203;
  K_JOY2 = 204;
  K_JOY3 = 205;
  K_JOY4 = 206;

  //
  // aux keys are for multi-buttoned joysticks to generate so they can use
  // the normal binding process
  //
  K_AUX1 = 207;
  K_AUX2 = 208;
  K_AUX3 = 209;
  K_AUX4 = 210;
  K_AUX5 = 211;
  K_AUX6 = 212;
  K_AUX7 = 213;
  K_AUX8 = 214;
  K_AUX9 = 215;
  K_AUX10 = 216;
  K_AUX11 = 217;
  K_AUX12 = 218;
  K_AUX13 = 219;
  K_AUX14 = 220;
  K_AUX15 = 221;
  K_AUX16 = 222;
  K_AUX17 = 223;
  K_AUX18 = 224;
  K_AUX19 = 225;
  K_AUX20 = 226;
  K_AUX21 = 227;
  K_AUX22 = 228;
  K_AUX23 = 229;
  K_AUX24 = 230;
  K_AUX25 = 231;
  K_AUX26 = 232;
  K_AUX27 = 233;
  K_AUX28 = 234;
  K_AUX29 = 235;
  K_AUX30 = 236;
  K_AUX31 = 237;
  K_AUX32 = 238;

  K_MWHEELDOWN = 239;
  K_MWHEELUP = 240;

procedure Key_Event(key: integer; Down: qboolean; time: Longword);
procedure Key_Init;
procedure Key_WriteBindings(var f: integer);
procedure Key_SetBinding(keynum: integer; binding: Pchar);
procedure Key_ClearStates;
function Key_GetKey: integer;
function Key_KeynumToString(keynum: Integer): Pchar;

// variable that need to be put in the Interface section
var
  chat_team: qboolean;
  chat_buffer: array[0..255] of char;
  chat_bufferlen: integer;
  anykeydown: integer;
  key_repeats: array[0..255] of Integer; // if > 1, it is autorepeating
  keybindings: array[0..255] of Pchar;  //char *keybindings[256];
  keydown: array[0..255] of qboolean;

const
  MaxCmdLine = 256;

var
  key_lines: array[0..32 - 1, 0..MAXCMDLINE - 1] of char;
  key_linepos: integer;
  edit_line: integer = 0;

implementation

uses
  Sysutils,
  Cmd,
  Common,
  CVar,
  Console,
  {$IFDEF WIN32}
  sys_win,
  {$ELSE}
  sys_linux,
  vid_so, //Sys_GetClipboardData
  {$ENDIF}
  cl_main,
  menu,
  cl_scrn;

// key up events are sent even if in console mode
var
  shift_down: qBoolean = false;         // int shift_down=false;

  history_line: integer = 0;

  key_waiting: integer;

  consolekeys: array[0..255] of qboolean; // if true, can't be rebound while in console
  menubound: array[0..255] of qboolean; // if true, can't be rebound while in menu
  keyshift: array[0..255] of Integer;   // key to map to if shift held down in console

type
  keyname_p = ^keyname_t;
  keyname_t = record
    name: pchar;
    keynum: integer;
  end;

const
  keynames: array[0..88] of keyname_t =
  (
    (name: 'TAB'; keynum: K_TAB),
    (name: 'ENTER'; keynum: K_ENTER),
    (name: 'ESCAPE'; keynum: K_ESCAPE),
    (name: 'SPACE'; keynum: K_SPACE),
    (name: 'BACKSPACE'; keynum: K_BACKSPACE),
    (name: 'UPARROW'; keynum: K_UPARROW),
    (name: 'DOWNARROW'; keynum: K_DOWNARROW),
    (name: 'LEFTARROW'; keynum: K_LEFTARROW),
    (name: 'RIGHTARROW'; keynum: K_RIGHTARROW),

    (name: 'ALT'; keynum: K_ALT),
    (name: 'CTRL'; keynum: K_CTRL),
    (name: 'SHIFT'; keynum: K_SHIFT),

    (name: 'F1'; keynum: K_F1),
    (name: 'F2'; keynum: K_F2),
    (name: 'F3'; keynum: K_F3),
    (name: 'F4'; keynum: K_F4),
    (name: 'F5'; keynum: K_F5),
    (name: 'F6'; keynum: K_F6),
    (name: 'F7'; keynum: K_F7),
    (name: 'F8'; keynum: K_F8),
    (name: 'F9'; keynum: K_F9),
    (name: 'F10'; keynum: K_F10),
    (name: 'F11'; keynum: K_F11),
    (name: 'F12'; keynum: K_F12),

    (name: 'INS'; keynum: K_INS),
    (name: 'DEL'; keynum: K_DEL),
    (name: 'PGDN'; keynum: K_PGDN),
    (name: 'PGUP'; keynum: K_PGUP),
    (name: 'HOME'; keynum: K_HOME),
    (name: 'END'; keynum: K_END),

    (name: 'MOUSE1'; keynum: K_MOUSE1),
    (name: 'MOUSE2'; keynum: K_MOUSE2),
    (name: 'MOUSE3'; keynum: K_MOUSE3),

    (name: 'JOY1'; keynum: K_JOY1),
    (name: 'JOY2'; keynum: K_JOY2),
    (name: 'JOY3'; keynum: K_JOY3),
    (name: 'JOY4'; keynum: K_JOY4),

    (name: 'AUX1'; keynum: K_AUX1),
    (name: 'AUX2'; keynum: K_AUX2),
    (name: 'AUX3'; keynum: K_AUX3),
    (name: 'AUX4'; keynum: K_AUX4),
    (name: 'AUX5'; keynum: K_AUX5),
    (name: 'AUX6'; keynum: K_AUX6),
    (name: 'AUX7'; keynum: K_AUX7),
    (name: 'AUX8'; keynum: K_AUX8),
    (name: 'AUX9'; keynum: K_AUX9),
    (name: 'AUX10'; keynum: K_AUX10),
    (name: 'AUX11'; keynum: K_AUX11),
    (name: 'AUX12'; keynum: K_AUX12),
    (name: 'AUX13'; keynum: K_AUX13),
    (name: 'AUX14'; keynum: K_AUX14),
    (name: 'AUX15'; keynum: K_AUX15),
    (name: 'AUX16'; keynum: K_AUX16),
    (name: 'AUX17'; keynum: K_AUX17),
    (name: 'AUX18'; keynum: K_AUX18),
    (name: 'AUX19'; keynum: K_AUX19),
    (name: 'AUX20'; keynum: K_AUX20),
    (name: 'AUX21'; keynum: K_AUX21),
    (name: 'AUX22'; keynum: K_AUX22),
    (name: 'AUX23'; keynum: K_AUX23),
    (name: 'AUX24'; keynum: K_AUX24),
    (name: 'AUX25'; keynum: K_AUX25),
    (name: 'AUX26'; keynum: K_AUX26),
    (name: 'AUX27'; keynum: K_AUX27),
    (name: 'AUX28'; keynum: K_AUX28),
    (name: 'AUX29'; keynum: K_AUX29),
    (name: 'AUX30'; keynum: K_AUX30),
    (name: 'AUX31'; keynum: K_AUX31),
    (name: 'AUX32'; keynum: K_AUX32),

    (name: 'KP_HOME'; keynum: K_KP_HOME),
    (name: 'KP_UPARROW'; keynum: K_KP_UPARROW),
    (name: 'KP_PGUP'; keynum: K_KP_PGUP),
    (name: 'KP_LEFTARROW'; keynum: K_KP_LEFTARROW),
    (name: 'KP_5'; keynum: K_KP_5),
    (name: 'KP_RIGHTARROW'; keynum: K_KP_RIGHTARROW),
    (name: 'KP_END'; keynum: K_KP_END),
    (name: 'KP_DOWNARROW'; keynum: K_KP_DOWNARROW),
    (name: 'KP_PGDN'; keynum: K_KP_PGDN),
    (name: 'KP_ENTER'; keynum: K_KP_ENTER),
    (name: 'KP_INS'; keynum: K_KP_INS),
    (name: 'KP_DEL'; keynum: K_KP_DEL),
    (name: 'KP_SLASH'; keynum: K_KP_SLASH),
    (name: 'KP_MINUS'; keynum: K_KP_MINUS),
    (name: 'KP_PLUS'; keynum: K_KP_PLUS),

    (name: 'MWHEELUP'; keynum: K_MWHEELUP),
    (name: 'MWHEELDOWN'; keynum: K_MWHEELDOWN),

    (name: 'PAUSE'; keynum: K_PAUSE),

    (name: 'SEMICOLON'; keynum: ord(';')), // because a raw semicolon seperates commands
    (name: nil; keynum: - 1)
    );

  {
  ==============================================================================

                        LINE TYPING INTO THE CONSOLE

  ==============================================================================
  }

procedure CompleteCommand;
var
  s, cmd: Pchar;                        // s,cmd : String;
begin
  // TODO : Conferm string handling translation
  s := @key_lines[edit_line][1];        // key_lines[edit_line]+1; this works to, but isnt clear
  if (s[0] = '/') or (s[0] = '\') then
    Inc(s);
  cmd := Cmd_CompleteCommand(s);
  if cmd = nil then
    cmd := Cvar_CompleteVariable(s);
  if cmd <> nil then
  begin
    key_lines[edit_line][1] := '/';
    strcopy(@key_lines[edit_line][2], cmd); //  strcpy (key_lines[edit_line]+2, cmd);
    key_linepos := strlen(cmd) + 2;
    key_lines[edit_line][key_linepos] := ' ';
    Inc(key_linepos);
    key_lines[edit_line][key_linepos] := #0;
  end;
end;                                    {CompleteCommand}

{
====================
Key_Console

Interactive line editing and console scrollback
====================
void Key_Console (int key)
}

procedure Key_Console(Key: integer);
var
  cbd: pchar;
  Index: integer;
begin
  case key of
    K_KP_SLASH: key := Ord('/');
    K_KP_MINUS: key := Ord('-');
    K_KP_PLUS: key := Ord('+');
    K_KP_HOME: key := Ord('7');
    K_KP_UPARROW: key := Ord('8');
    K_KP_PGUP: key := Ord('9');
    K_KP_LEFTARROW: key := Ord('4');
    K_KP_5: key := Ord('5');
    K_KP_RIGHTARROW: key := Ord('6');
    K_KP_END: key := Ord('1');
    K_KP_DOWNARROW: key := Ord('2');
    K_KP_PGDN: key := Ord('3');
    K_KP_INS: key := Ord('0');
    K_KP_DEL: key := Ord('.');
  end;                                  {case}

  if ((UpCase(Char(key)) = 'V') and keydown[K_CTRL]) or
    (((key = K_INS) or (key = K_KP_INS)) and keydown[K_SHIFT]) then
  begin
    cbd := Sys_GetClipboardData;
    if cbd <> nil then
    begin
      // TODO : doesnt use the function result!
     //StrScan( cbd, #10#13#08); // strtok( cbd, "\n\r\b" );

      Index := strlen(cbd);
      if Index + key_linepos >= MAXCMDLINE then
        Index := MAXCMDLINE - key_linepos;

      if Index > 0 then
      begin
        cbd[Index] := #0;
        strcat(key_lines[edit_line], cbd);
        Inc(key_linepos, Index);
      end;
      FreeMem(cbd);
    end;
    exit;
  end;

  if (key = Ord('l')) and keydown[K_CTRL] then
  begin
    Cbuf_AddText('clear'#10);
    Exit;
  end;

  if (key = K_ENTER) or (key = K_KP_ENTER) then
  begin
    // backslash text are commands, else chat
    if (key_lines[edit_line][1] = '\') or (key_lines[edit_line][1] = '/') then
      Cbuf_AddText(@key_lines[edit_line][2]) //(key_lines[edit_line]+2)   // skip the >
    else
      Cbuf_AddText(@key_lines[edit_line][1]); //(key_lines[edit_line]+1); // valid command

    Cbuf_AddText(#10);
    Com_Printf('%s'#10, [key_lines[edit_line]]); //  Com_Printf ("%s\n",key_lines[edit_line]);

    edit_line := (edit_line + 1) and 31;
    history_line := edit_line;
    key_lines[edit_line][0] := ']';
    key_linepos := 1;
    if (cls.state = ca_disconnected) then
      // force an update, because the command. may take some time
      SCR_UpdateScreen();
    exit;
  end;

  if key = K_TAB then
  begin                                 // command completion
    CompleteCommand();
    Exit;
  end;

  if (key = K_BACKSPACE) or (key = K_LEFTARROW) or (key = K_KP_LEFTARROW) or
    ((UpCase(char(key)) = 'H') and keydown[K_CTRL]) then
  begin
    if key_linepos > 1 then
      Dec(key_linepos);
    exit;
  end;

  if (key = K_UPARROW) or (key = K_KP_UPARROW) or
    ((char(key) = 'p') and keydown[K_CTRL]) then
  begin
    repeat
      history_line := (history_line - 1) and 31;
    until not ((history_line <> edit_line) and (key_lines[history_line][1] = #0));
    if history_line = edit_line then
      history_line := (edit_line + 1) and 31;
    strcopy(key_lines[edit_line], key_lines[history_line]);
    key_linepos := strlen(key_lines[edit_line]);
    exit;
  end;

  if (key = K_DOWNARROW) or (key = K_KP_DOWNARROW) or
    ((char(key) = 'n') and keydown[K_CTRL]) then
  begin
    if history_line = edit_line then
      exit;
    repeat
      history_line := (history_line + 1) and 31;
    until not ((history_line <> edit_line) and (key_lines[history_line][1] = #0));
    if history_line = edit_line then
    begin
      key_lines[edit_line][0] := ']';
      key_linepos := 1;
    end
    else
    begin
      strcopy(key_lines[edit_line], key_lines[history_line]);
      key_linepos := strlen(key_lines[edit_line]);
    end;
    exit;
  end;

  if (key = K_PGUP) or (key = K_KP_PGUP) then
  begin
    con.display := con.display - 2;
    exit;
  end;

  if (key = K_PGDN) or (key = K_KP_PGDN) then
  begin
    con.display := con.display + 2;
    if (con.display > con.current) then
      con.display := con.current;
    exit;
  end;

  if (key = K_HOME) or (key = K_KP_HOME) then
  begin
    con.display := con.current - con.totallines + 10;
    exit;
  end;

  if (key = K_END) or (key = K_KP_END) then
  begin
    con.display := con.current;
    exit;
  end;

  if (key < 32) or (key > 127) then
    exit;                               // non printable

  if (key_linepos < MAXCMDLINE - 1) then
  begin
    key_lines[edit_line][key_linepos] := Char(key);
    Inc(key_linepos);
    key_lines[edit_line][key_linepos] := #0;
  end;
end;                                    {Key_Console}

//============================================================================

procedure Key_Message(key: integer);
begin
  if (key = K_ENTER) or (key = K_KP_ENTER) then
  begin
    if chat_team then
      Cbuf_AddText('say_team "')
    else
      Cbuf_AddText('say "');
    Cbuf_AddText(chat_buffer);
    Cbuf_AddText('"'#10);
    cls.key_dest := Client.key_game;
    chat_bufferlen := 0;
    chat_buffer[0] := #0;
    exit;
  end;

  if (key = K_ESCAPE) then
  begin
    cls.key_dest := Client.key_game;
    chat_bufferlen := 0;
    chat_buffer[0] := #0;
    exit;
  end;

  if (key < 32) or (key > 127) then
    exit;                               // non printable

  if (key = K_BACKSPACE) then
  begin
    if chat_bufferlen <> 0 then
    begin
      Dec(chat_bufferlen);
      chat_buffer[chat_bufferlen] := #0;
    end;
    exit;
  end;

  if (chat_bufferlen = sizeof(chat_buffer) - 1) then
    exit;                               // all full

  chat_buffer[chat_bufferlen] := Char(key);
  inc(chat_bufferlen);
  chat_buffer[chat_bufferlen] := #0;
end;                                    {Key_Message}

//============================================================================

{
===================
Key_StringToKeynum

Returns a key number to be used to index keybindings[] by looking at
the given string.  Single ascii characters return themselves, while
the K_* names are matched up.
===================
int Key_StringToKeynum (char *str)
}

function Key_StringToKeynum(str: PChar): integer;
var
  kn: keyname_p;
begin
  if (str = nil) or (str[0] = #0) then
  begin
    Result := -1;
    exit;
  end;

  if str[1] = #0 then
  begin
    Result := Ord(str[0]);
    exit;
  end;

  kn := @keynames[0];
  while kn.name <> nil do
  begin
    // TODO -cDependancy : Check to see if Q_strcasecmp is case sensitive
 //   if StrIComp(str,kn.name) = 0 then // case insensitive version
    if StrComp(str, kn.name) = 0 then
    begin
      Result := kn.keynum;
      exit;
    end;
    Inc(kn);
  end;
  Result := -1;
end;                                    {Key_StringToKeynum}

{
===================
Key_KeynumToString

Returns a string (either a single ascii char, or a K_* name) for the
given keynum.
FIXME: handle quote special (general escape sequence?)
===================
char *Key_KeynumToString (int keynum)
}
var                                     // TODO : This Should be replaced with a delphi string!
  tinystr: array[0..1] of char = (' ', ' ');

function Key_KeynumToString(keynum: Integer): Pchar;
var
  kn: keyname_p;
begin
  if (keynum = -1) then
  begin
    result := '<KEY NOT FOUND>';
    exit;
  end;

  if (keynum > 32) and (keynum < 127) then
  begin                                 // printable ascii
    tinystr[0] := Char(keynum);
    tinystr[1] := #0;
    result := tinystr;
    exit;
  end;

  kn := @keynames[0];
  while kn.name <> nil do
  begin
    if keynum = kn.keynum then
    begin
      Result := kn.name;
      exit;
    end;
    Inc(kn);
  end;
  Result := '<UNKNOWN KEYNUM>';
end;                                    {Key_KeynumToString}

{
===================
Key_SetBinding
===================
void Key_SetBinding (int keynum, char *binding)
}

procedure Key_SetBinding(keynum: integer; binding: PChar);
var
  new: Pchar;
  size: integer;
begin
  if keynum = -1 then
    exit;

  // free old bindings
  if keybindings[keynum] <> nil then
  begin
    Z_Free(keybindings[keynum]);
    keybindings[keynum] := nil;
  end;

  // allocate memory for new binding
  size := strlen(binding);
  if size <> 0 then
  begin
    new := Z_Malloc(size + 1);
    strcopy(new, binding);
    new[size] := #0;
    keybindings[keynum] := new;
  end;
end;                                    {Key_SetBinding}

{
===================
Key_Unbind_f
===================
void Key_Unbind_f (void)
}

procedure Key_Unbind_f; cdecl;
var
  B: integer;
  keystr: Pchar;
begin
  if Cmd_Argc <> 2 then
  begin
    Com_Printf('unbind <key> : remove commands from a key'#10, []);
    exit;
  end;

  keystr := Cmd_Argv(1);
  b := Key_StringToKeynum(keystr);
  if b = -1 then
  begin
    Com_Printf('"%d" isn''t a valid key'#10, [keystr]);
    exit;
  end;
  Key_SetBinding(b, '');
end;                                    {Key_Unbind_f}

procedure Key_Unbindall_f; cdecl;
var
  Index: integer;
begin
  for index := 0 to 255 do
    if keybindings[index] <> nil then
      Key_SetBinding(Index, '');
end;                                    {Key_Unbindall_f}

{
===================
Key_Bind_f
===================
void Key_Bind_f (void)
}

procedure Key_Bind_f; cdecl;
var
  index, count, Keynum: integer;
  cmd: array[0..1023] of char;
  keystr: Pchar;
begin
  count := Cmd_Argc();

  if count < 2 then
  begin
    Com_Printf('bind <key> [command] : attach a command to a key'#10, []);
    exit;
  end;

  keystr := Cmd_Argv(1);
  Keynum := Key_StringToKeynum(keystr);
  if Keynum = -1 then
  begin
    Com_Printf('"%s" isn''t a valid key'#10, [keystr]);
    exit;
  end;

  if count = 2 then
  begin
    if (keybindings[Keynum] <> nil) then
      Com_Printf('"%s" = "%s"'#10, [keystr, keybindings[Keynum]])
    else
      Com_Printf('"%s" is not bound'#10, [Cmd_Argv(1)]);
    exit;
  end;

  // copy the rest of the command line
  cmd[0] := #0;                         // start out with a null string
  for index := 2 to count - 1 do
  begin
    strcat(cmd, Cmd_Argv(index));
    if index <> count - 1 then
      strcat(cmd, ' ');
  end;
  Key_SetBinding(Keynum, cmd);
end;                                    {Key_Bind_f}

{
============
Key_WriteBindings

Writes lines containing "bind key value"
============
void Key_WriteBindings (FILE *f);
}

procedure Key_WriteBindings(var f: integer);
var
  Index: integer;
  tmp: string;
begin
  for index := 0 to 255 do
    if (keybindings[index] <> nil) and (keybindings[index][0] <> #0) then
    begin
      tmp := 'bind ' + Key_KeynumToString(index) + ' "' + keybindings[index] + '"' + #13#10;
      FileWrite(f, tmp[1], Length(tmp));
    end;
end;                                    {Key_WriteBindings}

{
============
Key_Bindlist_f
============
void Key_Bindlist_f (void)
}

procedure Key_Bindlist_f; cdecl;
var
  Index: integer;
begin
  for index := 0 to 255 do
    if (keybindings[index] <> nil) and (keybindings[index][0] <> #0) then
      Com_Printf('%s "%s"'#10, [Key_KeynumToString(index), keybindings[index]]);
end;                                    {Key_Bindlist_f}

{
===================
Key_Init
===================
void Key_Init (void);
}

procedure Key_Init;
var
  Index: integer;
begin
  for Index := 0 to 31 do
  begin
    key_lines[Index][0] := ']';
    key_lines[Index][1] := #0;
  end;
  key_linepos := 1;

  //
  // init ascii characters in console mode
  //
  for Index := 32 to 127 do
    consolekeys[Index] := true;
  consolekeys[K_ENTER] := true;
  consolekeys[K_KP_ENTER] := true;
  consolekeys[K_TAB] := true;
  consolekeys[K_LEFTARROW] := true;
  consolekeys[K_KP_LEFTARROW] := true;
  consolekeys[K_RIGHTARROW] := true;
  consolekeys[K_KP_RIGHTARROW] := true;
  consolekeys[K_UPARROW] := true;
  consolekeys[K_KP_UPARROW] := true;
  consolekeys[K_DOWNARROW] := true;
  consolekeys[K_KP_DOWNARROW] := true;
  consolekeys[K_BACKSPACE] := true;
  consolekeys[K_HOME] := true;
  consolekeys[K_KP_HOME] := true;
  consolekeys[K_END] := true;
  consolekeys[K_KP_END] := true;
  consolekeys[K_PGUP] := true;
  consolekeys[K_KP_PGUP] := true;
  consolekeys[K_PGDN] := true;
  consolekeys[K_KP_PGDN] := true;
  consolekeys[K_SHIFT] := true;
  consolekeys[K_INS] := true;
  consolekeys[K_KP_INS] := true;
  consolekeys[K_KP_DEL] := true;
  consolekeys[K_KP_SLASH] := true;
  consolekeys[K_KP_PLUS] := true;
  consolekeys[K_KP_MINUS] := true;
  consolekeys[K_KP_5] := true;

  consolekeys[Ord('`')] := false;
  consolekeys[Ord('~')] := false;

  for Index := 0 to 255 do
    keyshift[Index] := Index;
  for Index := ord('a') to ord('z') do
    keyshift[Index] := Index - Ord('a') + Ord('A');
  keyshift[Ord('1')] := Ord('!');
  keyshift[Ord('2')] := Ord('@');
  keyshift[Ord('3')] := Ord('#');
  keyshift[Ord('4')] := Ord('$');
  keyshift[Ord('5')] := Ord('%');
  keyshift[Ord('6')] := Ord('^');
  keyshift[Ord('7')] := Ord('&');
  keyshift[Ord('8')] := Ord('*');
  keyshift[Ord('9')] := Ord('(');
  keyshift[Ord('0')] := Ord(')');
  keyshift[Ord('-')] := Ord('_');
  keyshift[Ord('=')] := Ord('+');
  keyshift[Ord(',')] := Ord('<');
  keyshift[Ord('.')] := Ord('>');
  keyshift[Ord('/')] := Ord('?');
  keyshift[Ord(';')] := Ord(':');
  keyshift[Ord('''')] := Ord('"');
  keyshift[Ord('[')] := Ord('{');
  keyshift[Ord(']')] := Ord('}');
  keyshift[Ord('`')] := Ord('~');
  keyshift[Ord('\')] := Ord('|');

  menubound[K_ESCAPE] := true;
  for Index := 0 to 12 do
    menubound[K_F1 + Index] := true;

  //
  // register our functions
  //
  Cmd_AddCommand('bind', @Key_Bind_f);
  Cmd_AddCommand('unbind', @Key_Unbind_f);
  Cmd_AddCommand('unbindall', @Key_Unbindall_f);
  Cmd_AddCommand('bindlist', @Key_Bindlist_f);
end;                                    {Key_Init}

{
===================
Key_Event

Called by the system between frames for both key up and key down events
Should NOT be called during an interrupt!
===================
void Key_Event (int key, qboolean down, unsigned time);
}

procedure Key_Event(key: integer; Down: qboolean; time: Longword);
var
  kb: pchar;
var
  cmd: array[0..1023] of char;
begin
  // hack for modal presses
  if key_waiting = -1 then
  begin
    if down then
      key_waiting := key;
    exit;
  end;

  // update auto-repeat status
  if down then
  begin
    Inc(key_repeats[key]);
    if (key <> K_BACKSPACE) and
      (key <> K_PAUSE) and
      (key <> K_PGUP) and
      (key <> K_KP_PGUP) and
      (key <> K_PGDN) and
      (key <> K_KP_PGDN) and
      (key_repeats[key] > 1) then
      exit;                             // ignore most autorepeats

    if (key >= 200) and (keybindings[key] = nil) then
      Com_Printf('%s is unbound, hit F4 to set.'#10, [Key_KeynumToString(key)]);
  end
  else
    key_repeats[key] := 0;

  if (key = K_SHIFT) then
    shift_down := down;

  // console key is hardcoded, so the user can never unbind it
  if (key = ord('`')) or (key = ord('~')) then
  begin
    if not down then
      exit;
    Con_ToggleConsole_f();
    exit;
  end;

  // any key during the attract mode will bring up the menu
  if cl.attractloop and (cls.key_dest <> Client.key_menu) and
    not ((key >= K_F1) and (key <= K_F12)) then
    key := K_ESCAPE;
  // menu key is hardcoded, so the user can never unbind it
  if key = K_ESCAPE then
  begin
    if not down then
      exit;
    if (cl.frame.playerstate.stats[STAT_LAYOUTS] <> 0) and (cls.key_dest = Client.key_game) then
    begin                               // put away help computer / inventory
      Cbuf_AddText('cmd putaway'#10);
      exit;
    end;

    case cls.key_dest of
      Client.key_message: Key_Message(key);
      Client.key_menu: M_Keydown(key);
      Client.key_game,
        Client.key_console: M_Menu_Main_f();
    else
      Com_Error(ERR_FATAL, 'Bad cls.key_dest', []);
    end;
    exit;
  end;

  // track if any key is down for BUTTON_ANY
  keydown[key] := down;
  if down then
  begin
    if (key_repeats[key] = 1) then
      inc(anykeydown);
  end
  else
  begin
    Dec(anykeydown);
    if anykeydown < 0 then
      anykeydown := 0;
  end;

  //
  // key up events only generate commands if the game key binding is
  // a button command (leading + sign).  These will occur even in console mode,
  // to keep the character from continuing an action started before a console
  // switch.  Button commands include the kenum as a parameter, so multiple
  // downs can be matched with ups
  //
  if not down then
  begin
    kb := keybindings[key];
    if (kb <> nil) and (kb[0] = '+') then
    begin
      Com_sprintf(cmd, sizeof(cmd), '-%s %d %d'#10, [kb + 1, key, time]);
      Cbuf_AddText(@cmd[0]);
    end;
    if (keyshift[key] <> key) then
    begin
      kb := keybindings[keyshift[key]];
      if (kb <> nil) and (kb[0] = '+') then
      begin
        Com_sprintf(cmd, sizeof(cmd), '-%s %d %d'#10, [kb + 1, key, time]);
        Cbuf_AddText(@cmd[0]);
      end;
    end;
    exit;
  end;

  //
  // if not a consolekey, send to the interpreter no matter what mode is
  //
  if ((cls.key_dest = Client.key_menu) and menubound[key]) or
    ((cls.key_dest = Client.key_console) and (not consolekeys[key])) or
    ((cls.key_dest = Client.key_game) and ((cls.state = ca_active) or (not consolekeys[key]))) then
  begin
    kb := keybindings[key];
    if (kb <> nil) then
    begin
      if (kb[0] = '+') then
      begin
        // button commands add keynum and time as a parm
        Com_sprintf(cmd, sizeof(cmd), '%s %d %d'#10, [kb, key, time]);
        Cbuf_AddText(cmd);
      end
      else
      begin
        Cbuf_AddText(kb);
        Cbuf_AddText(#10);
      end;
    end;
    exit;
  end;

  if not down then
    exit;                               // other systems only care about key down events

  if shift_down then
    key := keyshift[key];
  case cls.key_dest of
    Client.key_message: Key_Message(key);
    Client.key_menu: M_Keydown(key);
    Client.key_game,
      Client.key_console: Key_Console(key);
  else
    Com_Error(ERR_FATAL, 'Bad cls.key_dest', []);
  end;
end;                                    {Key_Event}

{
==========
Key_ClearStates
==========
void Key_ClearStates (void);
}

procedure Key_ClearStates;
var
  Index: integer;
begin
  anykeydown := 0;
  for index := 0 to 255 do
  begin
    if keydown[index] and (key_repeats[index] <> 0) then
      Key_Event(index, false, 0);
    keydown[index] := false;
    key_repeats[index] := 0;
  end;
end;                                    {Key_ClearStates}

{
==========
Key_GetKey
==========
int Key_GetKey (void);
}

function Key_GetKey: integer;
begin
  key_waiting := -1;
  while key_waiting = -1 do
    Sys_SendKeyEvents;
  result := key_waiting;
end;

initialization
finalization
  // make sure the memory allocated for the key bindings is freed
  Key_Unbindall_f;

end.
