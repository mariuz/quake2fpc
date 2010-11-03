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
{ File(s): Console.h,Console.c - Console                                     }
{                                                                            }
{                                                                            }
{ Initial conversion by : ggs (tazipper@lyocs.com)                           }
{ Initial conversion on : -Jan-2002                                          }
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
unit Console;

interface

uses
  Client,
  cl_scrn,
  q_shared;

//
// console
//
const
  NUM_CON_TIMES = 4;
  CON_TEXTSIZE = 32768;
type
  console_t = record
    initialized: qboolean;
    text: array[0..CON_TEXTSIZE - 1] of char;
    current: integer;                   // line where next message will be printed
    x: integer;                         // offset in current line for next print
    display: integer;                   // bottom of console displays this line
    ormask: integer;                    // high bit mask for colored characters
    linewidth: integer;                 // characters across screen
    totallines: integer;                // total lines in console scrollback
    cursorspeed: single;
    vislines: integer;
    Times: array[0..NUM_CON_TIMES - 1] of single; // cls.realtime time the line was generated
    // for transparent notify lines
  end;                                  {console_t}

var
  con: console_t;
  { TODO -cTranslation : Isnt implemented in original version! }
  // Procedure Con_DrawCharacter(cx,line,num : integer);

procedure Con_CheckResize;
procedure Con_Init;
procedure Con_DrawConsole(frac: single);
procedure Con_Print(txt: pchar);
procedure Con_CenteredPrint(text: pchar);
procedure Con_Clear_f; cdecl;
procedure Con_DrawNotify;
procedure Con_ClearNotify;
procedure Con_ToggleConsole_f; cdecl;
procedure Key_ClearTyping;

procedure DrawString(x, y: integer; s: pchar);
procedure DrawAltString(x, y: integer; s: pchar);

implementation

uses
  Sysutils,
  Common,
  CVar,
  CPas,
  Cmd,
  menu,
  cl_main,
  Keys,
  {$IFDEF WIN32}
  vid_dll,
  {$ELSE}
  vid_so,
  {$ENDIF}
  files;

var
  con_notifytime: cvar_p;

procedure DrawString(x, y: integer; s: pchar);
begin
  while s[0] <> #0 do
  begin
    re.DrawChar(x, y, byte(s[0]));
    x := x + 8;
    inc(s);
  end;
end;                                    {DrawString}

procedure DrawAltString(x, y: integer; s: pchar);
begin
  while s[0] <> #0 do
  begin
    re.DrawChar(x, y, byte(Ord(s[0]) xor $80));
    Inc(x, 8);
    inc(s);
  end;
end;                                    {DrawAltString}

procedure Key_ClearTyping;
begin
  key_lines[edit_line][1] := #0;        // clear any typing
  key_linepos := 1;
end;                                    {Key_ClearTyping}

{
================
Con_ToggleConsole_f
================
}

procedure Con_ToggleConsole_f; cdecl;
begin
  SCR_EndLoadingPlaque();               // get rid of loading plaque

  if cl.attractloop then
  begin
    Cbuf_AddText('killserver'#10);
    exit;
  end;

  if cls.state = ca_disconnected then
  begin                                 // start the demo loop again
    Cbuf_AddText('d1'#10);
    exit;
  end;

  Key_ClearTyping;
  Con_ClearNotify;

  if (cls.key_dest = Client.key_console) then
  begin
    M_ForceMenuOff;
    Cvar_Set('paused', '0');
  end
  else
  begin
    M_ForceMenuOff;
    cls.key_dest := Client.key_console;
    if (Cvar_VariableValue('maxclients') = 1) and (Com_ServerState <> 0) then
      Cvar_Set('paused', '1');
  end;
end;                                    {Con_ToggleConsole_f}

{
================
Con_ToggleChat_f
================
}

procedure Con_ToggleChat_f; cdecl;
begin
  Key_ClearTyping;
  if cls.key_dest = Client.key_console then
  begin
    if cls.state = ca_active then
    begin
      M_ForceMenuOff;
      cls.key_dest := Client.key_game;
    end;
  end
  else
    cls.key_dest := Client.key_console;

  Con_ClearNotify;
end;                                    {Con_ToggleChat_f}

{
================
Con_Clear_f
================
}

procedure Con_Clear_f; cdecl;
begin
  FillChar(con.text[0], CON_TEXTSIZE, Ord(' '));
end;                                    {Con_Clear_f}

{
================
Con_Dump_f

Save the console contents out to a file
================
}

procedure Con_Dump_f; cdecl;
var
  index, index2, x: integer;
  line: pchar;
  f: Integer;
  Buffer: array[0..1024 - 1] of char;
  name: array[0..MAX_OSPATH - 1] of char;
  NEWLINE: char;
begin
  NEWLINE := #10;
  if Cmd_Argc <> 2 then
  begin
    Com_Printf('usage: condump <filename>'#10, []);
    exit;
  end;

  Com_sprintf(name, sizeof(name), '%s/%s.txt', [FS_Gamedir(), Cmd_Argv(1)]);
  Com_Printf('Dumped console text to %s.'#10, [name]);
  FS_CreatePath(name);

  f := FileOpen(name, fmOpenReadWrite);
  if (f = -1) then
    f := FileCreate(name);
  if f = -1 then
  begin
    Com_Printf('ERROR: couldn''t open.'#10, []);
    exit;
  end;
  index2 := con.current;
  // skip empty lines
  for Index := con.current - con.totallines + 1 to con.current do
  begin
    index2 := Index;
    { TODO -cTranslation : How do THIS translate! (lots items rely on this)}
    //  line = con.text + (Index % con.totallines)*con.linewidth;
    line := con.text + (Index mod con.totallines) * con.linewidth;
    for x := 0 to con.linewidth - 1 do
      if Line[x] <> ' ' then
        break;
    if x <> Con.linewidth then
      break;
  end;

  // write the remaining lines
  buffer[con.linewidth] := #0;
  for Index := index2 to con.current do
  begin
    line := con.text + (Index mod con.totallines) * con.linewidth;
    StrLCopy(buffer, line, con.linewidth);
    for X := con.linewidth - 1 downto 0 do
    begin
      if (buffer[x] = ' ') then
        buffer[x] := #0
      else
        break;
    end;
    X := 0;
    while buffer[x] <> #0 do
    begin
      buffer[x] := Char(Ord(buffer[x]) and $7F);
      inc(x);
    end;

    FileWrite(f, buffer, x);
    FileWrite(f, NEWLINE, 1);
  end;
  FileClose(f);
end;                                    {Con_Dump_f}

{
================
Con_ClearNotify
================
}

procedure Con_ClearNotify;
var
  Index: integer;
begin
  for Index := 0 to NUM_CON_TIMES - 1 do
  begin
    con.times[Index] := 0;
  end;
end;                                    {Con_ClearNotify}

{
================
Con_MessageMode_f
================
}

procedure Con_MessageMode_f; cdecl;
begin
  chat_team := false;
  cls.key_dest := Client.key_message;
end;                                    {Con_MessageMode_f}

{
================
Con_MessageMode2_f
================
}

procedure Con_MessageMode2_f; cdecl;
begin
  chat_team := true;
  cls.key_dest := Client.key_message;
end;                                    {Con_MessageMode2_f}

{
================
Con_CheckResize

If the line width has changed, reformat the buffer.
================
}

procedure Con_CheckResize;
var
  i, j, width, oldwidth, oldtotallines, numlines, numchars: integer;
  tbuf: array[0..CON_TEXTSIZE - 1] of char;
begin
  width := (viddef.width shr 3) - 2;

  if width = con.linewidth then
    exit;

  if (width < 1) then                   // video hasn't been initialized yet
  begin
    width := 38;
    con.linewidth := width;
    con.totallines := CON_TEXTSIZE div con.linewidth;
    FillChar(con.text[0], CON_TEXTSIZE, Ord(' '));
  end
  else
  begin
    oldwidth := con.linewidth;
    con.linewidth := width;
    oldtotallines := con.totallines;
    con.totallines := CON_TEXTSIZE div con.linewidth;
    numlines := oldtotallines;

    if con.totallines < numlines then
      numlines := con.totallines;

    numchars := oldwidth;

    if con.linewidth < numchars then
      numchars := con.linewidth;

    memcpy(@tbuf, @con.text, CON_TEXTSIZE);
    FillChar(con.text[0], CON_TEXTSIZE, Ord(' '));

    for i := 0 to numlines - 1 do
    begin
      for j := 0 to numchars - 1 do
      begin
        con.text[(con.totallines - 1 - i) * con.linewidth + j] :=
          tbuf[((con.current - i + oldtotallines) mod oldtotallines) * oldwidth + j];
      end;
    end;

    Con_ClearNotify;
  end;

  con.current := con.totallines - 1;
  con.display := con.current;
end;                                    {Con_CheckResize}

{
================
Con_Init
================
}

procedure Con_Init;
begin
  con.linewidth := -1;
  Con_CheckResize;
  Com_Printf('Console initialized.'#10, []);
  //
  // register our commands
  //
  con_notifytime := Cvar_Get('con_notifytime', '3', 0);

  Cmd_AddCommand('toggleconsole', Con_ToggleConsole_f);
  Cmd_AddCommand('togglechat', Con_ToggleChat_f);
  Cmd_AddCommand('messagemode', Con_MessageMode_f);
  Cmd_AddCommand('messagemode2', Con_MessageMode2_f);
  Cmd_AddCommand('clear', Con_Clear_f);
  Cmd_AddCommand('condump', Con_Dump_f);
  con.initialized := true;
end;                                    {Con_Init}

{
===============
Con_Linefeed
===============
}

procedure Con_Linefeed;
begin
  con.x := 0;
  if (con.display = con.current) then
    Inc(con.display);
  Inc(con.current);
  Fillchar(con.text[(con.current mod con.totallines) * con.linewidth], con.linewidth, ' ');
end;                                    {Con_Linefeed}

{
================
Con_Print

Handles cursor positioning, line wrapping, etc
All console printing must go through this in order to be logged to disk
If no console is visible, the text will appear at the top of the game window
================
}
var
  cr: boolean = false;

procedure Con_Print(txt: Pchar);
var
  y, l, mask: integer;
  ch: char;
begin
  if not con.initialized then
    exit;

  if (txt[0] = #1) or (txt[0] = #2) then
  begin
    mask := 128;                        // go to colored text
    inc(txt);
  end
  else
    mask := 0;

  ch := txt[0];
  while ch <> #0 do
  begin
    // count word length
    for l := 0 to con.linewidth - 1 do
      if Ord(txt[l]) <= Ord(' ') then
        break;
    // word wrap
    if (l <> con.linewidth) and (con.x + l > con.linewidth) then
      con.x := 0;

    inc(txt);

    if cr then
    begin
      dec(con.current);
      cr := false;
    end;

    if con.x = 0 then
    begin
      Con_Linefeed;
      // mark time for transparent overlay
      if con.current >= 0 then
        con.times[con.current mod NUM_CON_TIMES] := cls.realtime;
    end;

    case ch of
      #10: con.x := 0;
      #13:
        begin
          con.x := 0;
          cr := true;
        end;
    else                                // display character and advance
      begin
        y := con.current mod con.totallines;
        con.text[y * con.linewidth + con.x] := Char(Ord(ch) or mask or con.ormask);
        Inc(con.x);
        if con.x >= con.linewidth then
          con.x := 0;
      end;
    end;
    ch := txt[0];
  end;
end;                                    {Con_Print}

{
==============
Con_CenteredPrint
==============
}

procedure Con_CenteredPrint(text: Pchar);
var
  Len: integer;
  buffer: array[0..1024 - 1] of char;
begin
  Len := strlen(text);
  Len := (con.linewidth - Len) div 2;
  if Len < 0 then
    Len := 0;
  Fillchar(buffer, Len, Ord(' '));
  strcpy(buffer + Len, text);
  strcat(buffer, #10);
  Con_Print(buffer);
end;                                    {Con_CenteredPrint}

{
==============================================================================

DRAWING

==============================================================================
}

{
================
Con_DrawInput

The input line scrolls horizontally if typing goes beyond the right edge
================
}

procedure Con_DrawInput;
var
  Index, y: integer;
  text: pchar;
begin
  if cls.key_dest = Client.key_menu then
    exit;
  if (cls.key_dest <> Client.key_console) and (cls.state = ca_active) then
    exit;                               // don't draw anything (always draw if not active)

  text := key_lines[edit_line];

  // add the cursor frame
  text[key_linepos] := Char(10 + (cls.realtime shr 8) and 1);

  // fill out remainder with spaces
  for Index := key_linepos + 1 to con.linewidth - 1 do
    text[Index] := ' ';

  //  prestep if horizontally scrolling
  if key_linepos >= con.linewidth then
    text := text + 1 + key_linepos - con.linewidth;

  // draw it
  y := con.vislines - 16;
  for Index := 0 to con.linewidth - 1 do
    re.DrawChar((Index + 1) shl 3, con.vislines - 22, byte(text[Index]));

  // remove cursor
  key_lines[edit_line][key_linepos] := #0;
end;                                    {Con_DrawInput}

{
================
Con_DrawNotify

Draws the last few lines of output transparently over the game top
================
}

procedure Con_DrawNotify;
var
  x, v, index, skip: integer;
  time: integer;
  Text, s: pchar;
begin
  v := 0;
  for index := con.current - NUM_CON_TIMES + 1 to con.current do
  begin
    if index < 0 then
      continue;
    time := Round(con.times[index mod NUM_CON_TIMES]);
    if time = 0 then
      continue;
    time := cls.realtime - time;
    if time > con_notifytime^.value * 1000 then
      continue;
    text := con.text + (index mod con.totallines) * con.linewidth;

    for x := 0 to con.linewidth - 1 do
      re.DrawChar((x + 1) shl 3, v, byte(text[x]));

    inc(v, 8);
  end;

  if cls.key_dest = Client.key_message then
  begin
    if chat_team then
    begin
      DrawString(8, v, 'say_team:');
      skip := 11;
    end
    else
    begin
      DrawString(8, v, 'say:');
      skip := 5;
    end;

    s := chat_buffer;
    if chat_bufferlen > (viddef.width shr 3) - (skip + 1) then
      s := s + chat_bufferlen - ((viddef.width shr 3) - (skip + 1));
    x := 0;
    while s[x] <> #0 do
    begin
      re.DrawChar((x + skip) shl 3, v, byte(s[x]));
      Inc(x);
    end;
    re.DrawChar((x + skip) shl 3, v, Byte(10 + ((cls.realtime shr 8) and 1)));
    inc(v, 8);
  end;

  if v <> 0 then
  begin
    SCR_AddDirtyPoint(0, 0);
    SCR_AddDirtyPoint(viddef.width - 1, v);
  end;
end;                                    {Con_DrawNotify}

{
================
Con_DrawConsole

Draws the console with the solid background
================
}

procedure Con_DrawConsole(frac: Single);
var
  index, j, x, y, n: integer;
  rows, row, lines: integer;
  text: Pchar;
  VersionStr: array[0..63] of char;
  dlbar: array[0..1023] of char;
begin
  lines := Round(viddef.height * frac);
  if lines <= 0 then
    exit;

  if lines > viddef.height then
    lines := viddef.height;

  // draw the background
  re.DrawStretchPic(0, -viddef.height + lines, viddef.width, viddef.height, 'conback');
  SCR_AddDirtyPoint(0, 0);
  SCR_AddDirtyPoint(viddef.width - 1, lines - 1);

  Com_sprintf(VersionStr, sizeof(VersionStr), 'v%4.2f[delphi]', [VERSION]);
  for x := 0 to 12 do
    re.DrawChar(viddef.width - (13 * 8) - 4 + x * 8, lines - 12, Byte(128 + Ord(VersionStr[x])));

  // draw the text
  con.vislines := lines;

  {
  rows := (lines-8) Shr 3;      // rows of text to draw
  y := lines - 24;
  }
  rows := (lines - 22) shr 3;           // rows of text to draw
  y := lines - 30;

  // draw from the bottom up
  if (con.display <> con.current) then
  begin
    // draw arrows to show the buffer is backscrolled
    x := 0;
    while x < con.linewidth do
    begin
      re.DrawChar((x + 1) shl 3, y, Byte('^'));
      inc(x, 4)
    end;
    dec(y, 8);
    dec(rows);
  end;

  row := con.display;
  for index := 0 to rows - 1 do
  begin
    if row < 0 then
      break;
    if con.current - row >= con.totallines then
      break;                            // past scrollback wrap point
    text := con.text + (row mod con.totallines) * con.linewidth;

    for x := 0 to con.linewidth - 1 do
      re.DrawChar((x + 1) shl 3, y, Byte(text[x]));
    dec(y, 8);
    dec(row);
  end;

  //ZOID

  // draw the download bar
  // figure out width
  if cls.download > 0 then
  begin
    text := strrchr(cls.downloadname, Byte('/'));
    if (text <> nil) then
      Inc(text)
    else
      text := cls.downloadname;

    x := con.linewidth - ((con.linewidth * 7) div 40);
    y := x - Integer(strlen(text)) - 8;
    index := con.linewidth div 3;
    if Integer(strlen(text)) > index then
    begin
      y := x - index - 11;
      strncpy(dlbar, text, index);
      dlbar[index] := #0;
      strcat(dlbar, '...');
    end
    else
      strcopy(dlbar, text);
    strcat(dlbar, ': ');
    index := strlen(dlbar);
    dlbar[index] := #$80;               // dlbar[i++] = '\x80';
    Inc(Index);
    // where's the dot go?
    if cls.downloadpercent = 0 then
      n := 0
    else
      n := y * cls.downloadpercent div 100;

    for j := 0 to y - 1 do
    begin
      if j = n then
        dlbar[index] := #$83
      else
        dlbar[index] := #$81;
      inc(index);
    end;
    dlbar[index] := #$82;
    inc(index);
    dlbar[index] := #0;

    StrFmt(dlbar + strlen(dlbar), ' %02d%%', [cls.downloadpercent]);

    // draw it
    y := con.vislines - 12;
    for index := 0 to strlen(dlbar) - 1 do
      re.DrawChar((index + 1) shl 3, y, Byte(dlbar[index]));
  end;
  //ZOID

  // draw the input prompt, user text, and cursor if desired
  Con_DrawInput;
end;                                    {Con_DrawConsole}

end.
