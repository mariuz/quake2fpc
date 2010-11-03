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
{ File(s): qmenu.c + qmenu.h                                                 }
{                                                                            }
{ Initial conversion by : YgriK (Igor Karpov) - glYgriK@hotbox.ru            }
{ Initial conversion on : 13-Feb-2002                                        }
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
{ Updated on : 04-jun-2002                                                              }
{ Updated by : Juha Hartikainen                                                               }
{ - Made this real unit }
{ - Added qmenu.h stuff }
{ - Finished conversion }
{ Updated on : 25-jul-2002                                                   }
{ Updated by : burnin (leonel@linuxbr.com.br)                                }
{ - Pointer renaming                                                         }
{                                                                            }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{                                                                            }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{ 1) Implement Field_key Paste from clipboard functionality                  }
{ 2) Error checking                                                          }
{----------------------------------------------------------------------------}
unit Qmenu;

interface

uses
    {$IFDEF LINUX}
    libc,
    {$ENDIF}
    q_shared;

const
  MAXMENUITEMS = 64;

  MTYPE_SLIDER = 0;
  MTYPE_LIST = 1;
  MTYPE_ACTION = 2;
  MTYPE_SPINCONTROL = 3;
  MTYPE_SEPARATOR = 4;
  MTYPE_FIELD = 5;

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

  QMF_LEFT_JUSTIFY = $00000001;
  QMF_GRAYED = $00000002;
  QMF_NUMBERSONLY = $00000004;

type
  menuframework_p = ^menuframework_s;
  menuframework_s = record
    x, y: Integer;
    cursor: Integer;

    nitems: Integer;
    nslots: Integer;
    items: array[0..64 - 1] of pointer;
    statusbar: pchar;
    cursordraw: procedure(menuframework: menuframework_p);
  end;

  menucommon_p = ^menucommon_s;
  menucommon_s = record
    type_: integer;
    name: pchar;
    x, y: integer;
    parent: menuframework_p;
    cursor_offset: integer;
    localdata: array[0..3] of integer;
    flags: Cardinal;

    statusbar: PChar;

    callback: procedure(Self: Pointer);
    statusbarfunc: procedure(Self: Pointer);
    ownerdraw: procedure(Self: Pointer);
    cursordraw: procedure(Self: Pointer);
  end;

  menufield_p = ^menufield_s;
  menufield_s = record
    generic: menucommon_s;
    buffer: array[0..80 - 1] of char;
    cursor: integer;
    length: integer;
    visible_length: integer;
    visible_offset: integer;
  end;

  menuslider_p = ^menuslider_s;
  menuslider_s = record
    generic: menucommon_s;
    minvalue: single;
    maxvalue: single;
    curvalue: single;
    range: single;
  end;

  menulist_p = ^menulist_s;
  menulist_s = record
    generic: menucommon_s;
    curvalue: integer;
    itemnames: PPCharArray;
  end;

  menuaction_p = ^menuaction_s;
  menuaction_s = record
    generic: menucommon_s;
  end;

  menuseparator_p = ^menuseparator_s;
  menuseparator_s = record
    generic: menucommon_s;
  end;

function Field_Key(f: menufield_p; key: integer): qboolean;

procedure Menu_AddItem(menu: menuframework_p; item: pointer);
procedure Menu_AdjustCursor(menu: menuframework_p; dir: integer);
procedure Menu_Center(menu: menuframework_p);
procedure Menu_Draw(menu: menuframework_p);
function Menu_ItemAtCursor(m: menuframework_p): pointer;
function Menu_SelectItem(s: menuframework_p): qboolean;
procedure Menu_SetStatusBar(m: menuframework_p; string_: pchar);
procedure Menu_SlideItem(s: menuframework_p; dir: integer);
function Menu_TallySlots(menu: menuframework_p): integer;

procedure Menu_DrawString(x, y: integer; string_: pchar);
procedure Menu_DrawStringDark(x, y: integer; string_: pchar);
procedure Menu_DrawStringR2L(x, y: integer; string_: pchar);
procedure Menu_DrawStringR2LDark(x, y: integer; string_: pchar);

implementation

uses
  {$IFDEF WIN32}
  q_shwin,
  sys_win,
  vid_dll,
  {$ELSE}
  q_shlinux,
  sys_linux,
  vid_so,
  {$ENDIF}
  keys,
  SysUtils,
  cpas;

const
  RCOLUMN_OFFSET = 16;
  LCOLUMN_OFFSET = -16;

  { JUHA: MACRO REPLACEMENTS }

function VID_WIDTH: integer;
begin
  Result := viddef.width;
end;

function VID_HEIGHT: integer;
begin
  Result := viddef.height;
end;
(*

#define re.DrawChar re.DrawChar
#define Draw_Fill re.DrawFill
*)

procedure Slider_Draw(s: menuslider_p); forward;
procedure MenuList_Draw(l: menulist_p); forward;
procedure SpinControl_Draw(s: menulist_p); forward;
procedure Separator_Draw(s: menuseparator_p); forward;
procedure Menu_DrawStatusBar(string_: PChar); forward;
procedure Slider_DoSlide(s: menuslider_p; dir: integer); forward;
procedure SpinControl_DoSlide(s: menulist_p; dir: integer); forward;

procedure Action_DoEnter(a: menuaction_p);
begin
  if @a.generic.callback <> nil then
    a.generic.callback(a);
end;

procedure Action_Draw(a: menuaction_p);
begin
  if (a^.generic.flags and QMF_LEFT_JUSTIFY) <> 0 then
  begin
    if (a^.generic.flags and QMF_GRAYED) <> 0 then
      Menu_DrawStringDark(a^.generic.x + a^.generic.parent.x + LCOLUMN_OFFSET, a^.generic.y + a^.generic.parent.y, a^.generic.name)
    else
      Menu_DrawString(a^.generic.x + a^.generic.parent.x + LCOLUMN_OFFSET, a^.generic.y + a^.generic.parent.y, a^.generic.name);
  end
  else
  begin
    if (a^.generic.flags and QMF_GRAYED) <> 0 then
      Menu_DrawStringR2LDark(a^.generic.x + a^.generic.parent.x + LCOLUMN_OFFSET, a^.generic.y + a^.generic.parent.y, a^.generic.name)
    else
      Menu_DrawStringR2L(a^.generic.x + a^.generic.parent.x + LCOLUMN_OFFSET, a^.generic.y + a^.generic.parent.y, a^.generic.name);
  end;
  if @a^.generic.ownerdraw <> nil then
    a^.generic.ownerdraw(a);
end;

function Field_DoEnter(f: menufield_p): qboolean;
begin
  if @f^.generic.callback <> nil then
  begin
    f^.generic.callback(f);
    Result := true;
    Exit;
  end;
  Result := false;
end;

procedure Field_Draw(f: menufield_p);
var
  i, offset: Integer;
  tempbuffer: array[0..128 - 1] of Char;
begin
  FillChar(tempbuffer, sizeof(tempbuffer), 0);
  if f^.generic.name <> nil then
    Menu_DrawStringR2LDark(f^.generic.x + f^.generic.parent.x + LCOLUMN_OFFSET, f^.generic.y + f^.generic.parent.y, f^.generic.name);

  strncpy(tempbuffer, f^.buffer + f^.visible_offset, f^.visible_length);

  re.DrawChar(f^.generic.x + f^.generic.parent.x + 16, f^.generic.y + f^.generic.parent.y - 4, 18);
  re.DrawChar(f^.generic.x + f^.generic.parent.x + 16, f^.generic.y + f^.generic.parent.y + 4, 24);

  re.DrawChar(f^.generic.x + f^.generic.parent.x + 24 + f^.visible_length * 8, f^.generic.y + f^.generic.parent.y - 4, 20);
  re.DrawChar(f^.generic.x + f^.generic.parent.x + 24 + f^.visible_length * 8, f^.generic.y + f^.generic.parent.y + 4, 26);

  for i := 0 to f^.visible_length - 1 do
  begin
    re.DrawChar(f^.generic.x + f^.generic.parent.x + 24 + i * 8, f^.generic.y + f^.generic.parent.y - 4, 19);
    re.DrawChar(f^.generic.x + f^.generic.parent.x + 24 + i * 8, f^.generic.y + f^.generic.parent.y + 4, 25);
  end;

  Menu_DrawString(f^.generic.x + f^.generic.parent.x + 24, f^.generic.y + f^.generic.parent.y, tempbuffer);

  if (Menu_ItemAtCursor(f^.generic.parent) = f) then
  begin
    if (f^.visible_offset <> 0) then
      offset := f^.visible_length
    else
      offset := f^.cursor;

    if ((Sys_Milliseconds() div 250) and 1 <> 0) then
      re.DrawChar(f^.generic.x + f^.generic.parent.x + (offset + 2) * 8 + 8,
        f^.generic.y + f^.generic.parent.y,
        11)
    else
      re.DrawChar(f^.generic.x + f^.generic.parent.x + (offset + 2) * 8 + 8,
        f^.generic.y + f^.generic.parent.y,
        Byte(' '));
  end;
end;

function Field_Key(f: menufield_p; key: integer): qboolean;
var
  cbd: PChar;
begin
  case key of
    K_KP_SLASH: key := byte('/');
    K_KP_MINUS: key := byte('-');
    K_KP_PLUS: key := byte('+');
    K_KP_HOME: key := byte('7');
    K_KP_UPARROW: key := byte('8');
    K_KP_PGUP: key := byte('9');
    K_KP_LEFTARROW: key := byte('4');
    K_KP_5: key := byte('5');
    K_KP_RIGHTARROW: key := byte('6');
    K_KP_END: key := byte('1');
    K_KP_DOWNARROW: key := byte('2');
    K_KP_PGDN: key := byte('3');
    K_KP_INS: key := byte('0');
    K_KP_DEL: key := byte('.');
  end;                                  //case

  if (key > 127) then
  begin
    Result := false;
    Exit;
  end;

  {*
  ** support pasting from the clipboard
  *}
  if ((UpperCase(char(key)) = 'V') and (keydown[K_CTRL]) or
    (((key = K_INS) or (key = K_KP_INS)) and keydown[K_SHIFT])) then
  begin
    cbd := Sys_GetClipboardData();
    if (cbd <> nil) then
    begin
      strtok(cbd, #10#13#08);
      strncpy(f^.buffer, cbd, f^.length - 1);
      f^.cursor := strlen(f^.buffer);
      f^.visible_offset := f^.cursor - f^.visible_length;
      if (f^.visible_offset < 0) then
        f^.visible_offset := 0;
      FreeMem(cbd);
    end;
    Result := true;
    Exit;
  end;

  case key of
    K_KP_LEFTARROW,
      K_LEFTARROW,
      K_BACKSPACE: if (f^.cursor > 0) then
      begin
        Move(f^.buffer[f^.cursor], f^.buffer[f^.cursor - 1], strlen(@f^.buffer[f^.cursor]) + 1);
        Dec(f^.cursor);
        if (f^.visible_offset <> 0) then
          Dec(f^.visible_offset);
      end;
    K_KP_DEL,
      K_DEL: Move(f^.buffer[f^.cursor + 1], f^.buffer[f^.cursor], strlen(@f^.buffer[f^.cursor + 1]) + 1);

    K_KP_ENTER,
      K_ENTER,
      K_ESCAPE,
      K_TAB:
      begin
        Result := false;
        Exit;
      end;

    {K_SPACE, }
  else if (isdigit(key) = 0) and
    ((f^.generic.flags and QMF_NUMBERSONLY) <> 0) then
  begin
    Result := false;
    Exit;
  end;

  if (f^.cursor < f^.length) then
  begin
    //                    f->buffer[f->cursor++] = key;
    f^.buffer[f^.cursor] := Char(key);
    Inc(f^.cursor);

    f^.buffer[f^.cursor] := #0;

    if (f^.cursor > f^.visible_length) then
      Inc(f^.visible_offset);
  end;
  end;                                  //case

  Result := true;
end;

procedure Menu_AddItem(menu: menuframework_p; item: pointer);
begin
  if (menu^.nitems = 0) then
    menu^.nslots := 0;

  if (menu^.nitems < MAXMENUITEMS) then
  begin
    menu^.items[menu^.nitems] := item;
    menucommon_p(menu^.items[menu.nitems]).parent := menu;
    Inc(menu.nitems);
  end;

  menu^.nslots := Menu_TallySlots(menu);
end;

{*
** Menu_AdjustCursor
**
** This function takes the given menu, the direction, and attempts
** to adjust the menu's cursor so that it's at the next available
** slot.
*}

procedure Menu_AdjustCursor(menu: menuframework_p; dir: integer);
var
  citem: menucommon_p;
begin
  {*
  ** see if it's in a valid spot
  *}
  if (menu^.cursor >= 0) and (menu^.cursor < menu^.nitems) then
  begin
    citem := Menu_ItemAtCursor(menu);
    if citem <> nil then
      if (citem^.type_ <> MTYPE_SEPARATOR) then
        Exit;
  end;

  {*
  ** it's not in a valid spot, so crawl in the direction indicated until we
  ** find a valid spot
  *}
  if (dir = 1) then
    while True do
    begin
      citem := Menu_ItemAtCursor(menu);
      if citem <> nil then
        if (citem^.type_ <> MTYPE_SEPARATOR) then
          Break;
      menu^.cursor := menu^.cursor + dir;
      if (menu^.cursor >= menu^.nitems) then
        menu^.cursor := 0;
    end
  else
    while True do
    begin
      citem := Menu_ItemAtCursor(menu);
      if citem <> nil then
        if (citem^.type_ <> MTYPE_SEPARATOR) then
          Break;
      menu^.cursor := menu^.cursor + dir;
      if (menu^.cursor < 0) then
        menu^.cursor := menu^.nitems - 1;
    end;
end;

procedure Menu_Center(menu: menuframework_p);
var
  height: integer;
begin
  height := menucommon_p(menu.items[menu.nitems - 1]).y;
  Inc(height, 10);

  menu.y := (VID_HEIGHT - height) div 2;
end;

procedure Menu_Draw(menu: menuframework_p);
var
  i: integer;
  item: menucommon_p;
begin
  {*
  ** draw contents
  *}
  for i := 0 to menu^.nitems - 1 do
  begin
    case menucommon_p(menu^.items[i])^.type_ of
      MTYPE_FIELD: Field_Draw(menufield_p(menu.items[i]));
      MTYPE_SLIDER: Slider_Draw(menuslider_p(menu.items[i]));
      MTYPE_LIST: MenuList_Draw(menulist_p(menu.items[i]));
      MTYPE_SPINCONTROL: SpinControl_Draw(menulist_p(menu.items[i]));
      MTYPE_ACTION: Action_Draw(menuaction_p(menu.items[i]));
      MTYPE_SEPARATOR: Separator_Draw(menuseparator_p(menu.items[i]));
    end;                                //case
  end;

  item := Menu_ItemAtCursor(menu);

  if (item <> nil) and Assigned(item^.cursordraw) then
    item^.cursordraw(item)
  else if (@menu^.cursordraw <> nil) then
    menu.cursordraw(menu)
  else if (item <> nil) and (item^.type_ <> MTYPE_FIELD) then
    if (item.flags and QMF_LEFT_JUSTIFY) <> 0 then
      re.DrawChar(menu.x + item.x - 24 + item.cursor_offset, menu.y + item.y, 12 + (Round(Sys_Milliseconds() / 250) and 1))
    else
      re.DrawChar(menu.x + item.cursor_offset, menu.y + item.y, 12 + (Round(Sys_Milliseconds() / 250) and 1));

  if (item <> nil) then
    if (@item^.statusbarfunc <> nil) then
      item^.statusbarfunc(item)
    else if (item^.statusbar <> nil) then
      Menu_DrawStatusBar(item^.statusbar)
    else
      Menu_DrawStatusBar(menu^.statusbar)
  else
    Menu_DrawStatusBar(menu.statusbar);
end;

//procedure Menu_DrawStatusBar ( const char *string );

procedure Menu_DrawStatusBar(string_: PChar);
var
  l,
    //  maxrow,
  maxcol,
    col: integer;
begin
  if (string_ <> nil) then
  begin
    l := strlen(string_);
    //    maxrow := VID_HEIGHT div 8;
    maxcol := VID_WIDTH div 8;
    col := maxcol div 2 - l div 2;

    re.DrawFill(0, VID_HEIGHT - 8, VID_WIDTH, 8, 4);
    Menu_DrawString(col * 8, VID_HEIGHT - 8, string_);
  end
  else
    re.DrawFill(0, VID_HEIGHT - 8, VID_WIDTH, 8, 0);
end;

//procedure Menu_DrawString ( int x, int y, const char *string )

procedure Menu_DrawString(x, y: integer; string_: PChar);
var
  i: Integer;
begin
  for i := 0 to strlen(string_) - 1 do
    re.DrawChar(x + i * 8, y, Byte(string_[i]));
end;

procedure Menu_DrawStringDark(x, y: integer; string_: PChar);
var
  i: integer;
begin
  for i := 0 to strlen(string_) - 1 do
    re.DrawChar(x + i * 8, y, Byte(string_[i]) + 128);
end;

procedure Menu_DrawStringR2L(x, y: integer; string_: PChar);
var
  i: integer;
begin
  for i := 0 to strlen(string_) do
    re.DrawChar(x - i * 8, y, byte(string_[strlen(string_) - i - 1]));
end;

procedure Menu_DrawStringR2LDark(x, y: integer; string_: PChar);
var
  i: integer;
begin
  for i := 0 to strlen(string_) - 1 do
    re.DrawChar(x - i * 8, y, byte(string_[strlen(string_) - i - 1]) + 128);
end;

function Menu_ItemAtCursor(m: menuframework_p): pointer;
begin
  if (m.cursor < 0) or (m.cursor >= m.nitems) then
  begin
    Result := nil;
    Exit;
  end;

  Result := m.items[m.cursor];
end;

function Menu_SelectItem(s: menuframework_p): qboolean;
var
  item: menucommon_p;
begin
  item := menucommon_p(Menu_ItemAtCursor(s));

  if item <> nil then
    case item.type_ of
      MTYPE_FIELD:
        begin
          Result := Field_DoEnter(menufield_p(item));
          Exit;
        end;
      MTYPE_ACTION:
        begin
          Action_DoEnter(menuaction_p(item));
          Result := true;
          Exit;
        end;
      MTYPE_LIST:
        //idsoft    Menulist_DoEnter( ( menulist_s * ) item );
        begin
          Result := false;
          exit;
        end;
      MTYPE_SPINCONTROL:
        //idsoft    SpinControl_DoEnter( ( menulist_s * ) item );
        begin
          Result := false;
          exit;
        end;
    end;                                //case

  Result := false;
end;

procedure Menu_SetStatusBar(m: menuframework_p; string_: pchar);
begin
  m.statusbar := string_;
end;

procedure Menu_SlideItem(s: menuframework_p; dir: integer);
var
  item: menucommon_p;
begin
  item := menucommon_p(Menu_ItemAtCursor(s));
  if (item <> nil) then
    case item.type_ of
      MTYPE_SLIDER: Slider_DoSlide(menuslider_p(item), dir);
      MTYPE_SPINCONTROL: SpinControl_DoSlide(menulist_p(item), dir);
    end;                                //case
end;

function Menu_TallySlots(menu: menuframework_p): integer;
var
  i, total, nitems: integer;
  n: PPChar;
begin
  total := 0;
  for i := 0 to menu.nitems - 1 do
    if (menucommon_p(menu.items[i]).type_ = MTYPE_LIST) then
    begin
      nitems := 0;
      n := PPChar(@menulist_p(menu.items[i]).itemnames^[0]);

      while (n <> nil) do
      begin
        Inc(nitems);
        Inc(n);
      end;

      Inc(total, nitems);
    end
    else
      Inc(total);

  Result := total;
end;

procedure Menulist_DoEnter(l: menulist_p);
var
  start: integer;
begin
  start := l^.generic.y div 10 + 1;

  l^.curvalue := l^.generic.parent.cursor - start;

  if (@l.generic.callback <> nil) then
    l^.generic.callback(l);
end;

procedure MenuList_Draw(l: menulist_p);
var
  y: integer;
  n: PPChar;
begin
  y := 0;
  Menu_DrawStringR2LDark(l.generic.x + l.generic.parent.x + LCOLUMN_OFFSET, l.generic.y + l.generic.parent.y, l.generic.name);

  n := PPChar(l.itemnames);

  re.DrawFill(l.generic.x - 112 + l.generic.parent.x, l.generic.parent.y + l.generic.y + l.curvalue * 10 + 10, 128, 10, 16);
  while (n^ <> nil) do
  begin
    Menu_DrawStringR2LDark(l.generic.x + l.generic.parent.x + LCOLUMN_OFFSET, l.generic.y + l.generic.parent.y + y + 10, n^);

    Inc(n);
    Inc(y, 10);
  end;
end;

procedure Separator_Draw(s: menuseparator_p);
begin
  if (s.generic.name <> nil) then
    Menu_DrawStringR2LDark(s.generic.x + s.generic.parent.x, s.generic.y + s.generic.parent.y, s.generic.name);
end;

procedure Slider_DoSlide(s: menuslider_p; dir: integer);
begin
  s^.curvalue := s^.curvalue + dir;

  if (s^.curvalue > s^.maxvalue) then
    s^.curvalue := s^.maxvalue
  else if (s^.curvalue < s^.minvalue) then
    s^.curvalue := s^.minvalue;

  if (@s^.generic.callback <> nil) then
    s^.generic.callback(s);
end;

const
  SLIDER_RANGE = 10;

procedure Slider_Draw(s: menuslider_p);
var
  i: integer;
begin
  Menu_DrawStringR2LDark(s.generic.x + s.generic.parent.x + LCOLUMN_OFFSET,
    s.generic.y + s.generic.parent.y,
    s.generic.name);

  s.range := (s.curvalue - s.minvalue) / (s.maxvalue - s.minvalue);

  if (s.range < 0) then
    s.range := 0;
  if (s.range > 1) then
    s.range := 1;
  re.DrawChar(s.generic.x + s.generic.parent.x + RCOLUMN_OFFSET, s.generic.y + s.generic.parent.y, 128);
  for i := 0 to SLIDER_RANGE do
    re.DrawChar(RCOLUMN_OFFSET + s.generic.x + i * 8 + s.generic.parent.x + 8, s.generic.y + s.generic.parent.y, 129);
  i := SLIDER_RANGE;
  re.DrawChar(RCOLUMN_OFFSET + s.generic.x + i * 8 + s.generic.parent.x + 8, s.generic.y + s.generic.parent.y, 130);
  re.DrawChar(Round(8 + RCOLUMN_OFFSET + s.generic.parent.x + s.generic.x + (SLIDER_RANGE - 1) * 8 * s.range), s.generic.y + s.generic.parent.y, 131);
end;

procedure SpinControl_DoEnter(s: menulist_p);
begin
  Inc(s^.curvalue);
  if (s^.itemnames^[s^.curvalue] = nil) then
    s^.curvalue := 0;

  if (@s^.generic.callback <> nil) then
    s^.generic.callback(s);
end;

procedure SpinControl_DoSlide(s: menulist_p; dir: integer);
begin
  s^.curvalue := s^.curvalue + dir;

  if (s^.curvalue < 0) then
    s^.curvalue := 0
  else if (s^.itemnames^[s^.curvalue] = nil) then
    dec(s^.curvalue);

  if (@s^.generic.callback <> nil) then
    s^.generic.callback(s);
end;

procedure SpinControl_Draw(s: menulist_p);
var
  buffer: array[0..100 - 1] of char;
begin
  if (s^.generic.name <> nil) then
    Menu_DrawStringR2LDark(s^.generic.x + s^.generic.parent.x + LCOLUMN_OFFSET,
      s^.generic.y + s^.generic.parent.y,
      s^.generic.name);

  if (strstr(s^.itemnames^[s^.curvalue], #10) = nil) then
    Menu_DrawString(RCOLUMN_OFFSET + s^.generic.x + s^.generic.parent.x, s^.generic.y + s^.generic.parent.y, s^.itemnames^[s^.curvalue])
  else
  begin
    strcpy(buffer, s^.itemnames^[s^.curvalue]);
    strchr(buffer, Byte(#10))^ := #0;
    Menu_DrawString(RCOLUMN_OFFSET + s^.generic.x + s^.generic.parent.x, s^.generic.y + s^.generic.parent.y, buffer);
    strcpy(buffer, strchr(s^.itemnames^[s^.curvalue], Byte(#10)) + 1);
    Menu_DrawString(RCOLUMN_OFFSET + s^.generic.x + s^.generic.parent.x, s^.generic.y + s^.generic.parent.y + 10, buffer);
  end;
end;

// End of file
end.
