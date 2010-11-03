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
{ File(s): menu.c                                                            }
{ Content: Quake2\Client\                                                    }
{                                                                            }
{ Initial conversion by : ???                                                }
{ Initial conversion on :                                                    }
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
{ Updated on : 25-jul-2002                                                   }
{ Updated by : Leonel Togniolli (leonel@linuxbr.com.br)                      }
{ - Fixed the code to make it compile                                        }
{----------------------------------------------------------------------------}

unit menu;

interface

uses
  d5compat,
  SysUtils,
  Client,
  Common,
  {$IFDEF LINUX}
  libc,     // for PPCharArray
  {$ENDIF}
  q_shared;

var
  m_main_cursor: Integer;

const
  NUM_CURSOR_FRAMES = 15;

var
  menu_in_sound: PChar = 'misc/menu1.wav';
  menu_move_sound: PChar = 'misc/menu2.wav';
  menu_out_sound: PChar = 'misc/menu3.wav';

procedure M_Menu_Main_f; cdecl;
procedure M_Menu_Game_f; cdecl;
procedure M_Menu_LoadGame_f; cdecl;
procedure M_Menu_SaveGame_f; cdecl;
procedure M_Menu_PlayerConfig_f; cdecl;
procedure M_Menu_DownloadOptions_f; cdecl;
procedure M_Menu_Credits_f; cdecl;
procedure M_Menu_Multiplayer_f; cdecl;
procedure M_Menu_JoinServer_f; cdecl;
procedure M_Menu_AddressBook_f; cdecl;
procedure M_Menu_StartServer_f; cdecl;
procedure M_Menu_DMOptions_f; cdecl;
procedure M_Menu_Video_f; cdecl;
procedure M_Menu_Options_f; cdecl;
procedure M_Menu_Keys_f; cdecl;
procedure M_Menu_Quit_f; cdecl;

procedure M_ForceMenuOff;
procedure M_AddToServerList(Adr: netadr_t; Info: PChar);
procedure M_Init;
procedure M_Keydown(Key: Integer);
procedure M_PopMenu;
procedure M_Draw;


type
  TKeyFunc = function(Key: Integer): PChar;

var
  m_entersound: qboolean;               // play after drawing a frame, so caching
  // won't disrupt the sound
  m_drawfunc: procedure;
  m_keyfunc: TKeyFunc;

  //=======================================
  { Support Routines }

const
  MAX_MENU_DEPTH = 8;
  MAX_DISPLAYNAME = 16;
  MAX_PLAYERMODELS = 1024;

type
  menulayer_t = record
    Draw: TProcedure;
    Key: TKeyFunc;
  end;

var
  m_layers: array[0..MAX_MENU_DEPTH - 1] of menulayer_t;
  m_menudepth: Integer;

type
  playermodelinfo_p = ^playermodelinfo_s;
  playermodelinfo_s = record
    nskins: Integer;
    skindisplaynames: PPCharArray;
    Displayname: array[0..MAX_DISPLAYNAME - 1] of Char;
    Directory: array[0..MAX_QPATH - 1] of Char;
  end;

implementation

uses
  {$IFDEF WIN32}
  vid_dll,
  q_shwin,
  in_win,
  net_wins,
  vid_menu, // win version
  {$ELSE}
  vid_so,
  q_shlinux,
  in_linux,
  vid_menu, //linux version  under /linux dir
  net_udp,
  {$ENDIF}
  CVar,
  cl_main,
  snd_dma,
  keys,
  CPas,
  qmenu,
  cmd,
  cl_input,
  cl_view,
  console,
  files,
  ref,
  cl_scrn;

procedure M_Banner(Name: PChar);
var
  w, h: Integer;
begin
  re.DrawGetPicSize(@w, @h, name);
  re.DrawPic(viddef.width div 2 - w div 2, viddef.height div 2 - 110, name);
end;

procedure M_PushMenu(Draw: TProcedure; Key: TKeyFunc);
var
  i: Integer;
begin
  if (Cvar_VariableValue('maxclients') = 1) and (Com_ServerState() <> 0) then
    Cvar_Set('paused', '1');

  // if this menu is already present, drop back to that level
  // to a procedure stacking menus by hotkeys
  i := 0;
  while i < m_menudepth do
  begin
    if (@m_layers[i].draw = @draw) and (@m_layers[i].key = @key) then
      m_menudepth := i;
    Inc(i);
  end;

  if (i = m_menudepth) then
  begin
    if (m_menudepth >= MAX_MENU_DEPTH) then
      Com_Error(ERR_FATAL, 'M_PushMenu: MAX_MENU_DEPTH');
    m_layers[m_menudepth].draw := m_drawfunc;
    m_layers[m_menudepth].key := m_keyfunc;
    Inc(m_menudepth);
  end;

  m_drawfunc := draw;
  m_keyfunc := key;

  m_entersound := true;

  cls.key_dest := key_menu;
end;

procedure M_ForceMenuOff;
begin
  m_drawfunc := nil;
  m_keyfunc := nil;
  cls.key_dest := key_game;
  m_menudepth := 0;
  Key_ClearStates();
  Cvar_Set('paused', '0');
end;

procedure M_PopMenu;
begin
  S_StartLocalSound(menu_out_sound);
  if (m_menudepth < 1) then
    Com_Error(ERR_FATAL, 'M_PopMenu: depth < 1');
  Dec(m_menudepth);

  m_drawfunc := m_layers[m_menudepth].draw;
  m_keyfunc := m_layers[m_menudepth].key;

  if m_menudepth = 0 then
    M_ForceMenuOff();
end;

function Default_MenuKey(m: menuframework_p; key: Integer): PChar;
var
  sound: PChar;
  Item: menucommon_p;
begin
  sound := nil;

  if m <> nil then
  begin
    item := Menu_ItemAtCursor(m);
    if item <> nil then
    begin
      if (item^.type_ = MTYPE_FIELD) then
      begin
        if (Field_Key(menufield_p(item), key)) then
        begin
          Result := nil;
          exit;
        end;
      end;
    end;

    case key of
      K_ESCAPE:
        begin
          M_PopMenu();
          Result := menu_out_sound;
          exit;
        end;
      K_KP_UPARROW, K_UPARROW:
        if m <> nil then
        begin
          m^.cursor := m^.cursor - 1;
          Menu_AdjustCursor(m, -1);
          sound := menu_move_sound;
        end;
      K_TAB:
        if m <> nil then
        begin
          m^.cursor := m^.cursor + 1;
          Menu_AdjustCursor(m, 1);
          sound := menu_move_sound;
        end;
      K_KP_DOWNARROW, K_DOWNARROW:
        if m <> nil then
        begin
          m^.cursor := m^.cursor + 1;
          Menu_AdjustCursor(m, 1);
          sound := menu_move_sound;
        end;
      K_KP_LEFTARROW, K_LEFTARROW:
        if m <> nil then
        begin
          Menu_SlideItem(m, -1);
          sound := menu_move_sound;
        end;
      K_KP_RIGHTARROW, K_RIGHTARROW:
        if m <> nil then
        begin
          Menu_SlideItem(m, 1);
          sound := menu_move_sound;
        end;
      K_MOUSE1, K_MOUSE2, K_MOUSE3,
        K_JOY1, K_JOY2, K_JOY3, K_JOY4,
        K_AUX1, K_AUX2, K_AUX3, K_AUX4, K_AUX5,
        K_AUX6, K_AUX7, K_AUX8, K_AUX9, K_AUX10,
        K_AUX11, K_AUX12, K_AUX13, K_AUX14, K_AUX15,
        K_AUX16, K_AUX17, K_AUX18, K_AUX19, K_AUX20,
        K_AUX21, K_AUX22, K_AUX23, K_AUX24, K_AUX25,
        K_AUX26, K_AUX27, K_AUX28, K_AUX29, K_AUX30,
        K_AUX31, K_AUX32,
        K_KP_ENTER, K_ENTER:
        begin
          if m <> nil then
            Menu_SelectItem(m);
          sound := menu_move_sound;
        end;
    end;

    Result := sound;
  end;
end;

{
========
M_DrawCharacter

Draws one solid graphics character
cx and cy are in 320*240 coordinates, and will be centered on
higher res screens.
========
}

procedure M_DrawCharacter(cx, cy, num: Integer);
begin
  re.DrawChar(cx + ((viddef.width - 320) shr 1), cy + ((viddef.height - 240) shr 1), num);
end;

procedure M_Print(cx, cy: integer; str: PChar);
begin
  while str^ <> #0 do
  begin
    M_DrawCharacter(cx, cy, Byte(str^) + 128);
    Inc(str);
    Inc(cx, 8);
  end;
end;

procedure M_PrintWhite(cx, cy: integer; str: PChar);
begin
  while str^ <> #0 do
  begin
    M_DrawCharacter(cx, cy, Byte(str^));
    Inc(str);
    Inc(cx, 8);
  end;
end;

procedure M_DrawPic(x, y: integer; pic: PChar);
begin
  re.DrawPic(x + ((viddef.width - 320) shr 1), y + ((viddef.height - 240) shr 1), pic);
end;

{
=======
M_DrawCursor

Draws an animating cursor with the point at
x,y.  The pic will extend to the left of x,
and both above and below y.
=======
}
var
  mdc_cached: qboolean = false;         // was "static qboolean cached" in procedure

procedure M_DrawCursor(x, y, f: Integer);
var
  cursorname: array[0..80 - 1] of Char;
  i: Integer;
begin
  if not mdc_cached then
  begin
    for i := 0 to NUM_CURSOR_FRAMES - 1 do
    begin
      Com_sprintf(cursorname, sizeof(cursorname), 'm_cursor%d', [i]);
      re.RegisterPic(cursorname);
    end;
    mdc_cached := true;
  end;

  Com_sprintf(cursorname, sizeof(cursorname), 'm_cursor%d', [f]);
  re.DrawPic(x, y, cursorname);
end;

procedure M_DrawTextBox(x, y, width, lines: Integer);
var
  cx, cy, n: Integer;
begin
  // draw left side
  cx := x;
  cy := y;
  M_DrawCharacter(cx, cy, 1);
  for n := 0 to lines - 1 do
  begin
    Inc(cy, 8);
    M_DrawCharacter(cx, cy, 4);
  end;
  M_DrawCharacter(cx, cy + 8, 7);

  // draw middle
  Inc(cx, 8);
  while (width > 0) do
  begin
    cy := y;
    M_DrawCharacter(cx, cy, 2);
    for n := 0 to lines - 1 do
    begin
      Inc(cy, 8);
      M_DrawCharacter(cx, cy, 5);
    end;
    M_DrawCharacter(cx, cy + 8, 8);
    Dec(width);
    Inc(cx, 8);
  end;

  // draw right side
  cy := y;
  M_DrawCharacter(cx, cy, 3);
  for n := 0 to lines - 1 do
  begin
    Inc(cy, 8);
    M_DrawCharacter(cx, cy, 6);
  end;
  M_DrawCharacter(cx, cy + 8, 9);
end;

{
====================================

MAIN MENU

====================================
}
const
  MAIN_ITEMS = 5;

procedure M_Main_Draw;
var
  i, w, h, ystart, xoffset, widest, totalheight: Integer;
  litname: array[0..80 - 1] of Char;
const
  names: array[0..4] of PChar = (
    'm_main_game',
    'm_main_multiplayer',
    'm_main_options',
    'm_main_video',
    'm_main_quit');
begin
  widest := -1;
  totalheight := 0;

  for i := 0 to 4 do
  begin
    re.DrawGetPicSize(@w, @h, names[i]);
    if (w > widest) then
      widest := w;
    Inc(totalheight, (h + 12));
  end;

  ystart := (viddef.height div 2 - 110);
  xoffset := (viddef.width - widest + 70) div 2;

  for i := 0 to 4 do
  begin
    if (i <> m_main_cursor) then
      re.DrawPic(xoffset, ystart + i * 40 + 13, names[i]);
  end;
  strcpy(litname, names[m_main_cursor]);
  strcat(litname, '_sel');
  re.DrawPic(xoffset, ystart + m_main_cursor * 40 + 13, litname);

  M_DrawCursor(xoffset - 25, ystart + (m_main_cursor * 40) + 11, (cls.realtime div 100) mod NUM_CURSOR_FRAMES);

  re.DrawGetPicSize(@w, @h, 'm_main_plaque');
  re.DrawPic(xoffset - 30 - w, ystart, 'm_main_plaque');

  re.DrawPic(xoffset - 30 - w, ystart + h + 5, 'm_main_logo');
end;

function M_Main_Key(key: Integer): PChar;
var
  sound: PChar;
begin
  sound := menu_move_sound;
  Result := sound;

  case key of
    K_ESCAPE: M_PopMenu();
    K_KP_DOWNARROW, K_DOWNARROW:
      begin
        Inc(m_main_cursor);
        if (m_main_cursor >= MAIN_ITEMS) then
          m_main_cursor := 0;
        exit;                           // return sound;
      end;
    K_KP_UPARROW, K_UPARROW:
      begin
        Dec(m_main_cursor);
        if (m_main_cursor < 0) then
          m_main_cursor := MAIN_ITEMS - 1;
        exit;                           // return sound;
      end;
    K_KP_ENTER, K_ENTER:
      begin
        m_entersound := true;

        case m_main_cursor of
          0: M_Menu_Game_f();
          1: M_Menu_Multiplayer_f();
          2: M_Menu_Options_f();
          3: M_Menu_Video_f();
          4: M_Menu_Quit_f();
        end;
      end;
  end;
  Result := nil;
end;

procedure M_Menu_Main_f;
begin
  M_PushMenu(M_Main_Draw, M_Main_Key);
end;

{
====================================

MULTIPLAYER MENU

====================================
}
var
  s_multiplayer_menu: menuframework_s;
  s_join_network_server_action,
    s_start_network_server_action,
    s_player_setup_action: menuaction_s;

procedure Multiplayer_MenuDraw;
begin
  M_Banner('m_banner_multiplayer');

  Menu_AdjustCursor(@s_multiplayer_menu, 1);
  Menu_Draw(@s_multiplayer_menu);
end;

procedure PlayerSetupFunc(Unused: Pointer);
begin
  M_Menu_PlayerConfig_f();
end;

procedure JoinNetworkServerFunc(Unused: Pointer);
begin
  M_Menu_JoinServer_f();
end;

procedure StartNetworkServerFunc(Unused: Pointer);
begin
  M_Menu_StartServer_f();
end;

procedure Multiplayer_MenuInit;
begin
  s_multiplayer_menu.x := viddef.width div 2 - 64;
  s_multiplayer_menu.nitems := 0;

  s_join_network_server_action.generic.type_ := MTYPE_ACTION;
  s_join_network_server_action.generic.flags := QMF_LEFT_JUSTIFY;
  s_join_network_server_action.generic.x := 0;
  s_join_network_server_action.generic.y := 0;
  s_join_network_server_action.generic.name := ' join network server';
  s_join_network_server_action.generic.callback := JoinNetworkServerFunc;

  s_start_network_server_action.generic.type_ := MTYPE_ACTION;
  s_start_network_server_action.generic.flags := QMF_LEFT_JUSTIFY;
  s_start_network_server_action.generic.x := 0;
  s_start_network_server_action.generic.y := 10;
  s_start_network_server_action.generic.name := ' start network server';
  s_start_network_server_action.generic.callback := StartNetworkServerFunc;

  s_player_setup_action.generic.type_ := MTYPE_ACTION;
  s_player_setup_action.generic.flags := QMF_LEFT_JUSTIFY;
  s_player_setup_action.generic.x := 0;
  s_player_setup_action.generic.y := 20;
  s_player_setup_action.generic.name := ' player setup';
  s_player_setup_action.generic.callback := PlayerSetupFunc;

  Menu_AddItem(@s_multiplayer_menu, @s_join_network_server_action);
  Menu_AddItem(@s_multiplayer_menu, @s_start_network_server_action);
  Menu_AddItem(@s_multiplayer_menu, @s_player_setup_action);

  Menu_SetStatusBar(@s_multiplayer_menu, nil);

  Menu_Center(@s_multiplayer_menu);
end;

function Multiplayer_MenuKey(Key: Integer): PChar;
begin
  result := Default_MenuKey(@s_multiplayer_menu, key);
end;

procedure M_Menu_Multiplayer_f;
begin
  Multiplayer_MenuInit();
  M_PushMenu(Multiplayer_MenuDraw, Multiplayer_MenuKey);
end;

{
====================================

KEYS MENU

====================================
}
const
  BindNames: array[0..23, 0..1] of PChar =
  (
    ('+attack', 'attack'),
    ('weapnext', 'next weapon'),
    ('+forward', 'walk forward'),
    ('+back', 'backpedal'),
    ('+left', 'turn left'),
    ('+right', 'turn right'),
    ('+speed', 'run'),
    ('+moveleft', 'step left'),
    ('+moveright', 'step right'),
    ('+strafe', 'sidestep'),
    ('+lookup', 'look up'),
    ('+lookdown', 'look down'),
    ('centerview', 'center view'),
    ('+mlook', 'mouse look'),
    ('+klook', 'keyboard look'),
    ('+moveup', 'up / jump'),
    ('+movedown', 'down / crouch'),

    ('inven', 'inventory'),
    ('invuse', 'use item'),
    ('invdrop', 'drop item'),
    ('invprev', 'prev item'),
    ('invnext', 'next item'),

    ('cmd help', 'help computer'),
    (nil, nil)                          // was (0,0); ... null entry at end
    );

var
  keys_cursor: Integer;
  bind_grab: Integer;                   // static

  s_keys_menu: menuframework_s;         // static
  s_keys_attack_action,
    s_keys_change_weapon_action,
    s_keys_walk_forward_action,
    s_keys_backpedal_action,
    s_keys_turn_left_action,
    s_keys_turn_right_action,
    s_keys_run_action,
    s_keys_step_left_action,
    s_keys_step_right_action,
    s_keys_sidestep_action,
    s_keys_look_up_action,
    s_keys_look_down_action,
    s_keys_center_view_action,
    s_keys_mouse_look_action,
    s_keys_keyboard_look_action,
    s_keys_move_up_action,
    s_keys_move_down_action,
    s_keys_inventory_action,
    s_keys_inv_use_action,
    s_keys_inv_drop_action,
    s_keys_inv_prev_action,
    s_keys_inv_next_action,
    s_keys_help_computer_action: menuaction_s; // all static

procedure M_UnbindCommand(command: PChar); // static
var
  j, l: Integer;
  b: PChar;
begin
  l := strlen(command);

  for j := 0 to 255 do
  begin
    b := keybindings[j];
    if b = nil then
      continue;
    if (strncmp(b, command, l) = 0) then
      Key_SetBinding(j, '');
  end;
end;

procedure M_FindKeysForCommand(command: PChar; twokeys: PIntegerArray); // static
var
  count, j, l: Integer;
  b: PChar;
begin
  twokeys^[0] := -1;
  twokeys^[1] := -1;
  l := strlen(command);
  count := 0;

  for j := 0 to 255 do
  begin
    b := keybindings[j];
    if b = nil then
      continue;
    if strncmp(b, command, l) = 0 then
    begin
      twokeys[count] := j;
      Inc(count);
      if (count = 2) then
        break;
    end;
  end;
end;

procedure KeyCursorDrawFunc(menu: menuframework_p); // static
begin
  if (bind_grab <> 0) then
    re.DrawChar(menu^.x, menu^.y + menu^.cursor * 9, Byte('='))
  else
    re.DrawChar(menu^.x, menu^.y + menu^.cursor * 9, 12 + (Sys_Milliseconds() div 250) and 1);
end;

procedure DrawKeyBindingFunc(Self: Pointer); // static
var
  keys: array[0..1] of integer;
  a: menuaction_p;
  x: Integer;
  Name: PChar;
begin
  a := menuaction_p(self);

  M_FindKeysForCommand(bindnames[a^.generic.localdata[0]][0], @keys);

  if (keys[0] = -1) then
  begin
    Menu_DrawString(a^.generic.x + a^.generic.parent^.x + 16, a^.generic.y +
      a^.generic.parent^.y, '???');
  end
  else
  begin
    name := Key_KeynumToString(keys[0]);
    Menu_DrawString(a^.generic.x + a^.generic.parent^.x + 16, a^.generic.y +
      a^.generic.parent^.y, name);
    x := strlen(name) * 8;

    if (keys[1] <> -1) then
    begin
      Menu_DrawString(a^.generic.x + a^.generic.parent^.x + 24 + x, a^.generic.y
        + a^.generic.parent^.y, 'or');
      Menu_DrawString(a^.generic.x + a^.generic.parent^.x + 48 + x, a^.generic.y
        + a^.generic.parent^.y, Key_KeynumToString(keys[1]));
    end;
  end;
end;

procedure KeyBindingFunc(Self: Pointer); // static
var
  keys: array[0..1] of integer;
  a: menuaction_p;
begin
  a := menuaction_p(self);

  M_FindKeysForCommand(bindnames[a^.generic.localdata[0]][0], @keys);

  if (keys[1] <> -1) then
    M_UnbindCommand(bindnames[a^.generic.localdata[0]][0]);

  bind_grab := Integer(True);

  Menu_SetStatusBar(@s_keys_menu, 'press a key or button for this action');
end;

procedure Keys_MenuInit;                // static
var
  i, y: Integer;
begin
  y := 0;
  i := 0;

  s_keys_menu.x := viddef.width div 2;
  s_keys_menu.nitems := 0;
  s_keys_menu.cursordraw := @KeyCursorDrawFunc;

  s_keys_attack_action.generic.type_ := MTYPE_ACTION;
  s_keys_attack_action.generic.flags := QMF_GRAYED;
  s_keys_attack_action.generic.x := 0;
  s_keys_attack_action.generic.y := y;
  s_keys_attack_action.generic.ownerdraw := DrawKeyBindingFunc;
  s_keys_attack_action.generic.localdata[0] := i;
  s_keys_attack_action.generic.name :=
    bindnames[s_keys_attack_action.generic.localdata[0]][1];

  s_keys_change_weapon_action.generic.type_ := MTYPE_ACTION;
  s_keys_change_weapon_action.generic.flags := QMF_GRAYED;
  s_keys_change_weapon_action.generic.x := 0;
  inc(y, 9);
  s_keys_change_weapon_action.generic.y := y;
  s_keys_change_weapon_action.generic.ownerdraw := DrawKeyBindingFunc;
  inc(i);
  s_keys_change_weapon_action.generic.localdata[0] := i;
  s_keys_change_weapon_action.generic.name :=
    bindnames[s_keys_change_weapon_action.generic.localdata[0]][1];

  s_keys_walk_forward_action.generic.type_ := MTYPE_ACTION;
  s_keys_walk_forward_action.generic.flags := QMF_GRAYED;
  s_keys_walk_forward_action.generic.x := 0;
  inc(y, 9);
  s_keys_walk_forward_action.generic.y := y;
  s_keys_walk_forward_action.generic.ownerdraw := DrawKeyBindingFunc;
  inc(i);
  s_keys_walk_forward_action.generic.localdata[0] := i;
  s_keys_walk_forward_action.generic.name :=
    bindnames[s_keys_walk_forward_action.generic.localdata[0]][1];

  s_keys_backpedal_action.generic.type_ := MTYPE_ACTION;
  s_keys_backpedal_action.generic.flags := QMF_GRAYED;
  s_keys_backpedal_action.generic.x := 0;
  inc(y, 9);
  s_keys_backpedal_action.generic.y := y;
  s_keys_backpedal_action.generic.ownerdraw := DrawKeyBindingFunc;
  inc(i);
  s_keys_backpedal_action.generic.localdata[0] := i;
  s_keys_backpedal_action.generic.name :=
    bindnames[s_keys_backpedal_action.generic.localdata[0]][1];

  s_keys_turn_left_action.generic.type_ := MTYPE_ACTION;
  s_keys_turn_left_action.generic.flags := QMF_GRAYED;
  s_keys_turn_left_action.generic.x := 0;
  inc(y, 9);
  s_keys_turn_left_action.generic.y := y;
  s_keys_turn_left_action.generic.ownerdraw := DrawKeyBindingFunc;
  inc(i);
  s_keys_turn_left_action.generic.localdata[0] := i;
  s_keys_turn_left_action.generic.name :=
    bindnames[s_keys_turn_left_action.generic.localdata[0]][1];

  s_keys_turn_right_action.generic.type_ := MTYPE_ACTION;
  s_keys_turn_right_action.generic.flags := QMF_GRAYED;
  s_keys_turn_right_action.generic.x := 0;
  inc(y, 9);
  s_keys_turn_right_action.generic.y := y;
  s_keys_turn_right_action.generic.ownerdraw := DrawKeyBindingFunc;
  inc(i);
  s_keys_turn_right_action.generic.localdata[0] := i;
  s_keys_turn_right_action.generic.name :=
    bindnames[s_keys_turn_right_action.generic.localdata[0]][1];

  s_keys_run_action.generic.type_ := MTYPE_ACTION;
  s_keys_run_action.generic.flags := QMF_GRAYED;
  s_keys_run_action.generic.x := 0;
  inc(y, 9);
  s_keys_run_action.generic.y := y;
  s_keys_run_action.generic.ownerdraw := DrawKeyBindingFunc;
  inc(i);
  s_keys_run_action.generic.localdata[0] := i;
  s_keys_run_action.generic.name :=
    bindnames[s_keys_run_action.generic.localdata[0]][1];

  s_keys_step_left_action.generic.type_ := MTYPE_ACTION;
  s_keys_step_left_action.generic.flags := QMF_GRAYED;
  s_keys_step_left_action.generic.x := 0;
  inc(y, 9);
  s_keys_step_left_action.generic.y := y;
  s_keys_step_left_action.generic.ownerdraw := DrawKeyBindingFunc;
  inc(i);
  s_keys_step_left_action.generic.localdata[0] := i;
  s_keys_step_left_action.generic.name :=
    bindnames[s_keys_step_left_action.generic.localdata[0]][1];

  s_keys_step_right_action.generic.type_ := MTYPE_ACTION;
  s_keys_step_right_action.generic.flags := QMF_GRAYED;
  s_keys_step_right_action.generic.x := 0;
  inc(y, 9);
  s_keys_step_right_action.generic.y := y;
  s_keys_step_right_action.generic.ownerdraw := DrawKeyBindingFunc;
  inc(i);
  s_keys_step_right_action.generic.localdata[0] := i;
  s_keys_step_right_action.generic.name :=
    bindnames[s_keys_step_right_action.generic.localdata[0]][1];

  s_keys_sidestep_action.generic.type_ := MTYPE_ACTION;
  s_keys_sidestep_action.generic.flags := QMF_GRAYED;
  s_keys_sidestep_action.generic.x := 0;
  inc(y, 9);
  s_keys_sidestep_action.generic.y := y;
  s_keys_sidestep_action.generic.ownerdraw := DrawKeyBindingFunc;
  inc(i);
  s_keys_sidestep_action.generic.localdata[0] := i;
  s_keys_sidestep_action.generic.name :=
    bindnames[s_keys_sidestep_action.generic.localdata[0]][1];

  s_keys_look_up_action.generic.type_ := MTYPE_ACTION;
  s_keys_look_up_action.generic.flags := QMF_GRAYED;
  s_keys_look_up_action.generic.x := 0;
  inc(y, 9);
  s_keys_look_up_action.generic.y := y;
  s_keys_look_up_action.generic.ownerdraw := DrawKeyBindingFunc;
  inc(i);
  s_keys_look_up_action.generic.localdata[0] := i;
  s_keys_look_up_action.generic.name :=
    bindnames[s_keys_look_up_action.generic.localdata[0]][1];

  s_keys_look_down_action.generic.type_ := MTYPE_ACTION;
  s_keys_look_down_action.generic.flags := QMF_GRAYED;
  s_keys_look_down_action.generic.x := 0;
  inc(y, 9);
  s_keys_look_down_action.generic.y := y;
  s_keys_look_down_action.generic.ownerdraw := DrawKeyBindingFunc;
  inc(i);
  s_keys_look_down_action.generic.localdata[0] := i;
  s_keys_look_down_action.generic.name :=
    bindnames[s_keys_look_down_action.generic.localdata[0]][1];

  s_keys_center_view_action.generic.type_ := MTYPE_ACTION;
  s_keys_center_view_action.generic.flags := QMF_GRAYED;
  s_keys_center_view_action.generic.x := 0;
  inc(y, 9);
  s_keys_center_view_action.generic.y := y;
  s_keys_center_view_action.generic.ownerdraw := DrawKeyBindingFunc;
  inc(i);
  s_keys_center_view_action.generic.localdata[0] := i;
  s_keys_center_view_action.generic.name :=
    bindnames[s_keys_center_view_action.generic.localdata[0]][1];

  s_keys_mouse_look_action.generic.type_ := MTYPE_ACTION;
  s_keys_mouse_look_action.generic.flags := QMF_GRAYED;
  s_keys_mouse_look_action.generic.x := 0;
  inc(y, 9);
  s_keys_mouse_look_action.generic.y := y;
  s_keys_mouse_look_action.generic.ownerdraw := DrawKeyBindingFunc;
  inc(i);
  s_keys_mouse_look_action.generic.localdata[0] := i;
  s_keys_mouse_look_action.generic.name :=
    bindnames[s_keys_mouse_look_action.generic.localdata[0]][1];

  s_keys_keyboard_look_action.generic.type_ := MTYPE_ACTION;
  s_keys_keyboard_look_action.generic.flags := QMF_GRAYED;
  s_keys_keyboard_look_action.generic.x := 0;
  inc(y, 9);
  s_keys_keyboard_look_action.generic.y := y;
  s_keys_keyboard_look_action.generic.ownerdraw := DrawKeyBindingFunc;
  inc(i);
  s_keys_keyboard_look_action.generic.localdata[0] := i;
  s_keys_keyboard_look_action.generic.name :=
    bindnames[s_keys_keyboard_look_action.generic.localdata[0]][1];

  s_keys_move_up_action.generic.type_ := MTYPE_ACTION;
  s_keys_move_up_action.generic.flags := QMF_GRAYED;
  s_keys_move_up_action.generic.x := 0;
  inc(y, 9);
  s_keys_move_up_action.generic.y := y;
  s_keys_move_up_action.generic.ownerdraw := DrawKeyBindingFunc;
  inc(i);
  s_keys_move_up_action.generic.localdata[0] := i;
  s_keys_move_up_action.generic.name :=
    bindnames[s_keys_move_up_action.generic.localdata[0]][1];

  s_keys_move_down_action.generic.type_ := MTYPE_ACTION;
  s_keys_move_down_action.generic.flags := QMF_GRAYED;
  s_keys_move_down_action.generic.x := 0;
  inc(y, 9);
  s_keys_move_down_action.generic.y := y;
  s_keys_move_down_action.generic.ownerdraw := DrawKeyBindingFunc;
  inc(i);
  s_keys_move_down_action.generic.localdata[0] := i;
  s_keys_move_down_action.generic.name :=
    bindnames[s_keys_move_down_action.generic.localdata[0]][1];

  s_keys_inventory_action.generic.type_ := MTYPE_ACTION;
  s_keys_inventory_action.generic.flags := QMF_GRAYED;
  s_keys_inventory_action.generic.x := 0;
  inc(y, 9);
  s_keys_inventory_action.generic.y := y;
  s_keys_inventory_action.generic.ownerdraw := DrawKeyBindingFunc;
  inc(i);
  s_keys_inventory_action.generic.localdata[0] := i;
  s_keys_inventory_action.generic.name :=
    bindnames[s_keys_inventory_action.generic.localdata[0]][1];

  s_keys_inv_use_action.generic.type_ := MTYPE_ACTION;
  s_keys_inv_use_action.generic.flags := QMF_GRAYED;
  s_keys_inv_use_action.generic.x := 0;
  inc(y, 9);
  s_keys_inv_use_action.generic.y := y;
  s_keys_inv_use_action.generic.ownerdraw := DrawKeyBindingFunc;
  inc(i);
  s_keys_inv_use_action.generic.localdata[0] := i;
  s_keys_inv_use_action.generic.name :=
    bindnames[s_keys_inv_use_action.generic.localdata[0]][1];

  s_keys_inv_drop_action.generic.type_ := MTYPE_ACTION;
  s_keys_inv_drop_action.generic.flags := QMF_GRAYED;
  s_keys_inv_drop_action.generic.x := 0;
  inc(y, 9);
  s_keys_inv_drop_action.generic.y := y;
  s_keys_inv_drop_action.generic.ownerdraw := DrawKeyBindingFunc;
  s_keys_inv_drop_action.generic.localdata[0] := i + 1;
  inc(i);
  s_keys_inv_drop_action.generic.name :=
    bindnames[s_keys_inv_drop_action.generic.localdata[0]][1];

  s_keys_inv_prev_action.generic.type_ := MTYPE_ACTION;
  s_keys_inv_prev_action.generic.flags := QMF_GRAYED;
  s_keys_inv_prev_action.generic.x := 0;
  inc(y, 9);
  s_keys_inv_prev_action.generic.y := y;
  s_keys_inv_prev_action.generic.ownerdraw := DrawKeyBindingFunc;
  s_keys_inv_prev_action.generic.localdata[0] := i + 1;
  inc(i);
  s_keys_inv_prev_action.generic.name :=
    bindnames[s_keys_inv_prev_action.generic.localdata[0]][1];

  s_keys_inv_next_action.generic.type_ := MTYPE_ACTION;
  s_keys_inv_next_action.generic.flags := QMF_GRAYED;
  s_keys_inv_next_action.generic.x := 0;
  inc(y, 9);
  s_keys_inv_next_action.generic.y := y;
  s_keys_inv_next_action.generic.ownerdraw := DrawKeyBindingFunc;
  s_keys_inv_next_action.generic.localdata[0] := i + 1;
  inc(i);
  s_keys_inv_next_action.generic.name :=
    bindnames[s_keys_inv_next_action.generic.localdata[0]][1];

  s_keys_help_computer_action.generic.type_ := MTYPE_ACTION;
  s_keys_help_computer_action.generic.flags := QMF_GRAYED;
  s_keys_help_computer_action.generic.x := 0;
  inc(y, 9);
  s_keys_help_computer_action.generic.y := y;
  s_keys_help_computer_action.generic.ownerdraw := DrawKeyBindingFunc;
  s_keys_help_computer_action.generic.localdata[0] := i + 1;
  inc(i);
  s_keys_help_computer_action.generic.name :=
    bindnames[s_keys_help_computer_action.generic.localdata[0]][1];

  Menu_AddItem(@s_keys_menu, @s_keys_attack_action);
  Menu_AddItem(@s_keys_menu, @s_keys_change_weapon_action);
  Menu_AddItem(@s_keys_menu, @s_keys_walk_forward_action);
  Menu_AddItem(@s_keys_menu, @s_keys_backpedal_action);
  Menu_AddItem(@s_keys_menu, @s_keys_turn_left_action);
  Menu_AddItem(@s_keys_menu, @s_keys_turn_right_action);
  Menu_AddItem(@s_keys_menu, @s_keys_run_action);
  Menu_AddItem(@s_keys_menu, @s_keys_step_left_action);
  Menu_AddItem(@s_keys_menu, @s_keys_step_right_action);
  Menu_AddItem(@s_keys_menu, @s_keys_sidestep_action);
  Menu_AddItem(@s_keys_menu, @s_keys_look_up_action);
  Menu_AddItem(@s_keys_menu, @s_keys_look_down_action);
  Menu_AddItem(@s_keys_menu, @s_keys_center_view_action);
  Menu_AddItem(@s_keys_menu, @s_keys_mouse_look_action);
  Menu_AddItem(@s_keys_menu, @s_keys_keyboard_look_action);
  Menu_AddItem(@s_keys_menu, @s_keys_move_up_action);
  Menu_AddItem(@s_keys_menu, @s_keys_move_down_action);

  Menu_AddItem(@s_keys_menu, @s_keys_inventory_action);
  Menu_AddItem(@s_keys_menu, @s_keys_inv_use_action);
  Menu_AddItem(@s_keys_menu, @s_keys_inv_drop_action);
  Menu_AddItem(@s_keys_menu, @s_keys_inv_prev_action);
  Menu_AddItem(@s_keys_menu, @s_keys_inv_next_action);

  Menu_AddItem(@s_keys_menu, @s_keys_help_computer_action);

  Menu_SetStatusBar(@s_keys_menu, 'enter to change, backspace to clear');
  Menu_Center(@s_keys_menu);
end;

procedure Keys_MenuDraw;                // static
begin
  Menu_AdjustCursor(@s_keys_menu, 1);
  Menu_Draw(@s_keys_menu);
end;

function Keys_MenuKey(Key: Integer): PChar;
var
  item: menuAction_p;
  cmd: array[0..1024 - 1] of Char;
begin
  item := menuaction_p(Menu_ItemAtCursor(@s_keys_menu));

  if (bind_grab <> 0) then
  begin
    if (key <> K_ESCAPE) and (key <> ord('`')) then
    begin
      Com_sprintf(cmd, sizeof(cmd), 'bind "%s" "%s"'#10,
        [Key_KeynumToString(key), bindnames[item^.generic.localdata[0]][0]]);
      Cbuf_InsertText(cmd);
    end;

    Menu_SetStatusBar(@s_keys_menu, 'enter to change, backspace to clear');
    bind_grab := Integer(False);
    result := menu_out_sound;
    exit;
  end;

  case key of
    K_KP_ENTER, K_ENTER:
      begin
        KeyBindingFunc(item);
        Result := menu_in_sound;
        exit;
      end;
    K_BACKSPACE, K_DEL, K_KP_DEL:
      begin                             // delete bindings
        M_UnbindCommand(bindnames[item^.generic.localdata[0]][0]);
        Result := menu_out_sound;
        exit;
      end;
  else
    result := Default_MenuKey(@s_keys_menu, key);
  end;
end;

procedure M_Menu_Keys_f;
begin
  Keys_MenuInit();
  M_PushMenu(@Keys_MenuDraw, @Keys_MenuKey);
end;

{
====================================

CONTROLS MENU

====================================
}
// ALL VARS ARE STATIC HERE
var
  win_noalttab: cvar_p;

  s_options_menu: MenuFramework_s;
  s_options_defaults_action, s_options_customize_options_action: menuaction_s;
  s_options_sensitivity_slider: menuslider_s;
  s_options_freelook_box, s_options_noalttab_box,
    s_options_alwaysrun_box,
    s_options_invertmouse_box,
    s_options_lookspring_box,
    s_options_lookstrafe_box,
    s_options_crosshair_box: menulist_s;
  s_options_sfxvolume_slider: menuslider_s;
  s_options_joystick_box,
    s_options_cdvolume_box,
    s_options_quality_list,
    s_options_compatibility_list,
    s_options_console_action: menulist_s;

procedure CrosshairFunc(Unused: Pointer); // static
begin
  Cvar_SetValue('crosshair', s_options_crosshair_box.curvalue);
end;

procedure JoystickFunc(Unused: Pointer); // static
begin
  Cvar_SetValue('in_joystick', s_options_joystick_box.curvalue);
end;

procedure CustomizeControlsFunc(Unused: Pointer); // static
begin
  M_Menu_Keys_f();
end;

procedure AlwaysRunFunc(Unused: Pointer); // static
begin
  Cvar_SetValue('cl_run', s_options_alwaysrun_box.curvalue);
end;

procedure FreeLookFunc(Unused: Pointer); // static
begin
  Cvar_SetValue('freelook', s_options_freelook_box.curvalue);
end;

procedure MouseSpeedFunc(Unused: Pointer); // static
begin
  Cvar_SetValue('sensitivity', s_options_sensitivity_slider.curvalue / 2);
end;

procedure NoAltTabFunc(Unused: Pointer); // static
begin
  Cvar_SetValue('win_noalttab', s_options_noalttab_box.curvalue);
end;

function ClampCvar(Min, Max, Value: Single): Single; // static
begin
  if (value < min) then
    result := min
  else if (value > max) then
    result := max
  else
    result := value;
end;

procedure ControlsSetMenuItemValues;    // static
begin
  s_options_sfxvolume_slider.curvalue := Cvar_VariableValue('s_volume') * 10;
  s_options_cdvolume_box.curvalue := Integer(Cvar_VariableValue('cd_nocd') = 0);
  s_options_quality_list.curvalue := Integer(Cvar_VariableValue('s_loadas8bit') = 0);
  s_options_sensitivity_slider.curvalue := (sensitivity^.value) * 2;

  Cvar_SetValue('cl_run', ClampCvar(0, 1, cl_run^.value));
  s_options_alwaysrun_box.curvalue := trunc(cl_run^.Value);

  s_options_invertmouse_box.curvalue := Integer(m_pitch^.value < 0);

  Cvar_SetValue('lookspring', ClampCvar(0, 1, lookspring^.value));
  s_options_lookspring_box.curvalue := trunc(lookspring^.Value);

  Cvar_SetValue('lookstrafe', ClampCvar(0, 1, lookstrafe^.value));
  s_options_lookstrafe_box.curvalue := trunc(lookstrafe^.Value);

  Cvar_SetValue('freelook', ClampCvar(0, 1, freelook^.value));
  s_options_freelook_box.curvalue := trunc(freelook^.Value);

  Cvar_SetValue('crosshair', ClampCvar(0, 3, crosshair^.value));
  s_options_crosshair_box.curvalue := trunc(crosshair^.Value);

  Cvar_SetValue('in_joystick', ClampCvar(0, 1, in_joystick^.value));
  s_options_joystick_box.curvalue := trunc(in_joystick^.Value);

  s_options_noalttab_box.curvalue := trunc(win_noalttab^.Value);
end;

procedure ControlsResetDefaultsFunc(Unused: Pointer); // static
begin
  Cbuf_AddText('exec default.cfg'#10);
  Cbuf_Execute();

  ControlsSetMenuItemValues();
end;

procedure InvertMouseFunc(Unused: Pointer); // static
begin
  Cvar_SetValue('m_pitch', -m_pitch^.value);
end;

procedure LookspringFunc(Unused: Pointer); // static
begin
  Cvar_SetValue('lookspring', Integer(Trunc(lookspring^.value) = 0));
end;

procedure LookstrafeFunc(Unused: Pointer); // static
begin
  Cvar_SetValue('lookstrafe', Integer(Trunc(lookstrafe^.value) = 0));
end;

procedure UpdateVolumeFunc(Unused: Pointer); // static
begin
  Cvar_SetValue('s_volume', s_options_sfxvolume_slider.curvalue / 10);
end;

procedure UpdateCDVolumeFunc(Unused: Pointer); // static
begin
  Cvar_SetValue('cd_nocd', Integer(Trunc(s_options_cdvolume_box.curvalue) = 0));
end;

procedure ConsoleFunc(Unused: Pointer); // static
begin
  {
  ** the proper way to do this is probably to have ToggleConsole_f accept a parameter
  }

  if cl.attractloop then
  begin
    Cbuf_AddText('killserver'#10);
    exit;
  end;

  Key_ClearTyping();
  Con_ClearNotify();

  M_ForceMenuOff();
  cls.key_dest := key_console;
end;

procedure UpdateSoundQualityFunc(Unused: Pointer); // static
begin
  if Trunc(s_options_quality_list.curvalue) <> 0 then
  begin
    Cvar_SetValue('s_khz', 22);
    Cvar_SetValue('s_loadas8bit', Integer(False));
  end
  else
  begin
    Cvar_SetValue('s_khz', 11);
    Cvar_SetValue('s_loadas8bit', Integer(True));
  end;

  Cvar_SetValue('s_primary', s_options_compatibility_list.curvalue);

  M_DrawTextBox(8, 120 - 48, 36, 3);
  M_Print(16 + 16, 120 - 48 + 8, 'Restarting the sound system. This');
  M_Print(16 + 16, 120 - 48 + 16, 'could take up to a minute, so');
  M_Print(16 + 16, 120 - 48 + 24, 'please be patient.');

  // the text box won't show up unless we do a buffer swap
  re.EndFrame();

  CL_Snd_Restart_f();
end;

const
  cd_music_items: array[0..2] of PChar = ('disabled', 'enabled', nil);
  quality_items: array[0..2] of PChar = ('low', 'high', nil);
  compatibility_items: array[0..2] of PChar = ('max compatibilty', 'max performance', nil);
  yesno_names: array[0..2] of PChar = ('no', 'yes', nil);
  crosshair_names: array[0..4] of PChar = ('none', 'cross', 'dot', 'angle', nil);

procedure Options_MenuInit;
begin
  win_noalttab := Cvar_Get('win_noalttab', '0', CVAR_ARCHIVE);

  {
  ** configure controls menu and menu items
  }
  s_options_menu.x := viddef.Width div 2;
  s_options_menu.y := viddef.Height div 2 - 58;
  s_options_menu.nitems := 0;

  s_options_sfxvolume_slider.generic.type_ := MTYPE_SLIDER;
  s_options_sfxvolume_slider.generic.x := 0;
  s_options_sfxvolume_slider.generic.y := 0;
  s_options_sfxvolume_slider.generic.name := 'effects volume';
  s_options_sfxvolume_slider.generic.callback := UpdateVolumeFunc;
  s_options_sfxvolume_slider.minvalue := 0;
  s_options_sfxvolume_slider.maxvalue := 10;
  s_options_sfxvolume_slider.curvalue := Cvar_VariableValue('s_volume') * 10;

  s_options_cdvolume_box.generic.type_ := MTYPE_SPINCONTROL;
  s_options_cdvolume_box.generic.x := 0;
  s_options_cdvolume_box.generic.y := 10;
  s_options_cdvolume_box.generic.name := 'CD music';
  s_options_cdvolume_box.generic.callback := UpdateCDVolumeFunc;
  s_options_cdvolume_box.itemnames := @cd_music_items;
  s_options_cdvolume_box.curvalue := Integer(Cvar_VariableValue('cd_nocd') = 0);

  s_options_quality_list.generic.type_ := MTYPE_SPINCONTROL;
  s_options_quality_list.generic.x := 0;
  s_options_quality_list.generic.y := 20;
  ;
  s_options_quality_list.generic.name := 'sound quality';
  s_options_quality_list.generic.callback := UpdateSoundQualityFunc;
  s_options_quality_list.itemnames := @quality_items;
  s_options_quality_list.curvalue := Integer(Cvar_VariableValue('s_loadas8bit') = 0);

  s_options_compatibility_list.generic.type_ := MTYPE_SPINCONTROL;
  s_options_compatibility_list.generic.x := 0;
  s_options_compatibility_list.generic.y := 30;
  s_options_compatibility_list.generic.name := 'sound compatibility';
  s_options_compatibility_list.generic.callback := UpdateSoundQualityFunc;
  s_options_compatibility_list.itemnames := @compatibility_items;
  s_options_compatibility_list.curvalue := Integer(Cvar_VariableValue('s_primary') <> 0);

  s_options_sensitivity_slider.generic.type_ := MTYPE_SLIDER;
  s_options_sensitivity_slider.generic.x := 0;
  s_options_sensitivity_slider.generic.y := 50;
  s_options_sensitivity_slider.generic.name := 'mouse speed';
  s_options_sensitivity_slider.generic.callback := MouseSpeedFunc;
  s_options_sensitivity_slider.minvalue := 2;
  s_options_sensitivity_slider.maxvalue := 22;

  s_options_alwaysrun_box.generic.type_ := MTYPE_SPINCONTROL;
  s_options_alwaysrun_box.generic.x := 0;
  s_options_alwaysrun_box.generic.y := 60;
  s_options_alwaysrun_box.generic.name := 'always run';
  s_options_alwaysrun_box.generic.callback := AlwaysRunFunc;
  s_options_alwaysrun_box.itemnames := @yesno_names;

  s_options_invertmouse_box.generic.type_ := MTYPE_SPINCONTROL;
  s_options_invertmouse_box.generic.x := 0;
  s_options_invertmouse_box.generic.y := 70;
  s_options_invertmouse_box.generic.name := 'invert mouse';
  s_options_invertmouse_box.generic.callback := InvertMouseFunc;
  s_options_invertmouse_box.itemnames := @yesno_names;

  s_options_lookspring_box.generic.type_ := MTYPE_SPINCONTROL;
  s_options_lookspring_box.generic.x := 0;
  s_options_lookspring_box.generic.y := 80;
  s_options_lookspring_box.generic.name := 'lookspring';
  s_options_lookspring_box.generic.callback := LookspringFunc;
  s_options_lookspring_box.itemnames := @yesno_names;

  s_options_lookstrafe_box.generic.type_ := MTYPE_SPINCONTROL;
  s_options_lookstrafe_box.generic.x := 0;
  s_options_lookstrafe_box.generic.y := 90;
  s_options_lookstrafe_box.generic.name := 'lookstrafe';
  s_options_lookstrafe_box.generic.callback := LookstrafeFunc;
  s_options_lookstrafe_box.itemnames := @yesno_names;

  s_options_freelook_box.generic.type_ := MTYPE_SPINCONTROL;
  s_options_freelook_box.generic.x := 0;
  s_options_freelook_box.generic.y := 100;
  s_options_freelook_box.generic.name := 'free look';
  s_options_freelook_box.generic.callback := FreeLookFunc;
  s_options_freelook_box.itemnames := @yesno_names;

  s_options_crosshair_box.generic.type_ := MTYPE_SPINCONTROL;
  s_options_crosshair_box.generic.x := 0;
  s_options_crosshair_box.generic.y := 110;
  s_options_crosshair_box.generic.name := 'crosshair';
  s_options_crosshair_box.generic.callback := CrosshairFunc;
  s_options_crosshair_box.itemnames := @crosshair_names;
  {
   s_options_noalttab_box.generic.type_ := MTYPE_SPINCONTROL;
   s_options_noalttab_box.generic.x   := 0;
   s_options_noalttab_box.generic.y   := 110;
   s_options_noalttab_box.generic.name   := 'disable alt-tab';
   s_options_noalttab_box.generic.callback := NoAltTabFunc;
   s_options_noalttab_box.itemnames := @yesno_names;
  }
  s_options_joystick_box.generic.type_ := MTYPE_SPINCONTROL;
  s_options_joystick_box.generic.x := 0;
  s_options_joystick_box.generic.y := 120;
  s_options_joystick_box.generic.name := 'use joystick';
  s_options_joystick_box.generic.callback := JoystickFunc;
  s_options_joystick_box.itemnames := @yesno_names;

  s_options_customize_options_action.generic.type_ := MTYPE_ACTION;
  s_options_customize_options_action.generic.x := 0;
  s_options_customize_options_action.generic.y := 140;
  s_options_customize_options_action.generic.name := 'customize controls';
  s_options_customize_options_action.generic.callback := CustomizeControlsFunc;

  s_options_defaults_action.generic.type_ := MTYPE_ACTION;
  s_options_defaults_action.generic.x := 0;
  s_options_defaults_action.generic.y := 150;
  s_options_defaults_action.generic.name := 'reset defaults';
  s_options_defaults_action.generic.callback := ControlsResetDefaultsFunc;

  s_options_console_action.generic.type_ := MTYPE_ACTION;
  s_options_console_action.generic.x := 0;
  s_options_console_action.generic.y := 160;
  s_options_console_action.generic.name := 'go to console';
  s_options_console_action.generic.callback := ConsoleFunc;

  ControlsSetMenuItemValues();

  Menu_AddItem(@s_options_menu, @s_options_sfxvolume_slider);
  Menu_AddItem(@s_options_menu, @s_options_cdvolume_box);
  Menu_AddItem(@s_options_menu, @s_options_quality_list);
  Menu_AddItem(@s_options_menu, @s_options_compatibility_list);
  Menu_AddItem(@s_options_menu, @s_options_sensitivity_slider);
  Menu_AddItem(@s_options_menu, @s_options_alwaysrun_box);
  Menu_AddItem(@s_options_menu, @s_options_invertmouse_box);
  Menu_AddItem(@s_options_menu, @s_options_lookspring_box);
  Menu_AddItem(@s_options_menu, @s_options_lookstrafe_box);
  Menu_AddItem(@s_options_menu, @s_options_freelook_box);
  Menu_AddItem(@s_options_menu, @s_options_crosshair_box);
  Menu_AddItem(@s_options_menu, @s_options_joystick_box);
  Menu_AddItem(@s_options_menu, @s_options_customize_options_action);
  Menu_AddItem(@s_options_menu, @s_options_defaults_action);
  Menu_AddItem(@s_options_menu, @s_options_console_action);
end;

procedure Options_MenuDraw;
begin
  M_Banner('m_banner_options');
  Menu_AdjustCursor(@s_options_menu, 1);
  Menu_Draw(@s_options_menu);
end;

function Options_MenuKey(Key: Integer): PChar;
begin
  result := Default_MenuKey(@s_options_menu, key);
end;

procedure M_Menu_Options_f;
begin
  Options_MenuInit();
  M_PushMenu(@Options_MenuDraw, @Options_MenuKey);
end;

{
====================================

VIDEO MENU

====================================
}

procedure M_Menu_Video_f;
begin
  VID_MenuInit();
  M_PushMenu(@VID_MenuDraw, @VID_MenuKey);
end;

{
=======================================

END GAME MENU

=======================================
}
// All static
var
  credits_start_time: Integer;
  credits: PPChar;
  creditsIndex: array[0..255] of Char;
  creditsBuffer: PChar;

const
  idcredits: array[0..86] of PChar = (
    '+QUAKE II BY ID SOFTWARE',
    '',
    '+PROGRAMMING',
    'John Carmack',
    'John Cash',
    'Brian Hook',
    '',
    '+ART',
    'Adrian Carmack',
    'Kevin Cloud',
    'Paul Steed',
    '',
    '+LEVEL DESIGN',
    'Tim Willits',
    'American McGee',
    'Christian Antkow',
    'Paul Jaquays',
    'Brandon James',
    '',
    '+BIZ',
    'Todd Hollenshead',
    'Barrett (Bear) Alexander',
    'Donna Jackson',
    '',
    '',
    '+SPECIAL THANKS',
    'Ben Donges for beta testing',
    '',
    '',
    '',
    '',
    '',
    '',
    '+ADDITIONAL SUPPORT',
    '',
    '+LINUX PORT AND CTF',
    'Dave "Zoid" Kirsch',
    '',
    '+CINEMATIC SEQUENCES',
    'Ending Cinematic by Blur Studio - ',
    'Venice, CA',
    '',
    'Environment models for Introduction',
    'Cinematic by Karl Dolgener',
    '',
    'Assistance with environment design',
    'by Cliff Iwai',
    '',
    '+SOUND EFFECTS AND MUSIC',
    'Sound Design by Soundelux Media Labs.',
    'Music Composed and Produced by',
    'Soundelux Media Labs.  Special thanks',
    'to Bill Brown, Tom Ozanich, Brian',
    'Celano, Jeff Eisner, and The Soundelux',
    'Players.',
    '',
    '"Level Music" by Sonic Mayhem',
    'www.sonicmayhem.com',
    '',
    '"Quake II Theme Song"',
    '(C) 1997 Rob Zombie. All Rights',
    'Reserved.',
    '',
    'Track 10 ("Climb") by Jer Sypult',
    '',
    'Voice of computers by',
    'Carly Staehlin-Taylor',
    '',
    '+THANKS TO ACTIVISION',
    '+IN PARTICULAR:',
    '',
    'John Tam',
    'Steve Rosenthal',
    'Marty Stratton',
    'Henk Hartong',
    '',
    'Quake II(tm) (C)1997 Id Software, Inc.',
    'All Rights Reserved.  Distributed by',
    'Activision, Inc. under license.',
    'Quake II(tm), the Id Software name,',
    'the "Q II"(tm) logo and id(tm)',
    'logo are trademarks of Id Software,',
    'Inc. Activision(R) is a registered',
    'trademark of Activision, Inc. All',
    'other trademarks and trade names are',
    'properties of their respective owners.',
    nil
    );

  q2d_credits: array[0..60] of PChar = (
    '+QUAKE II DELPHI CONVERSION',
    '',
    'This project is dedicated to loving',
    'memory of Jan Horn. Jan started the',
    'Quake2 Delphi conversion, and put',
    'up excellent site (sulaco) for',
    'maintaining the project.',
    '',
    '+CORE DEVELOPMENT TEAM',
    'Juha Hartikainen',
    'Steve "Sly" Williams',
    'Alexey "Clootie" Barkovoy',
    'Michael "Code Fusion" Skovslund',
    'Scott Price',
    'Carl Kenner',
    'Leonel "burnin" Togniolli',
    '',              
    '+WEB SITE',
    'Maarten "McClaw" Kronberger (sulaco)',
    'Juha Hartikainen (sourceforge)',
    '',
    '+DEVELOPERS',
    'Ben Watt',
    'Massimo Soricetti',
    'Yuisi Kyo',
    'Skaljac Bojan',
    'Lavergne Thomas',
    'Jan Horn',
    'Jose M. Navarro',
    'Richard Smith',
    'Fabrizio Rossini',
    'Lars Middendorf',
    'John Clements',
    'Slavisa Milojkovic',
    'Maxime Delorme',
    'Amresh Ramachandran',
    'Dia Ragab',
    'Leonte Ionut',
    'Neil White',
    'Dominique Louis',
    'George Melekos',
    'Skybuck Flying',
    'Igor Karpov',
    'Adam Kurek',
    'David Caouette',
    'Matheus Degiovani',
    'Samuel Simon',
    'Christian Bendl',
    'Bob Janova',
    'Marcus Knight',
    '',
    '',
    '',
    '+YOU CAN REACH US AT',
    '',
    'http://sf.net/projects/quake2delphi/',
    '',
    '+OR',
    '',
    'http://www.sulaco.co.za/quake2/',
    nil
    );

  xatcredits: array[0..136] of PChar = (
    '+QUAKE II MISSION PACK: THE RECKONING',
    '+BY',
    '+XATRIX ENTERTAINMENT, INC.',
    '',
    '+DESIGN AND DIRECTION',
    'Drew Markham',
    '',
    '+PRODUCED BY',
    'Greg Goodrich',
    '',
    '+PROGRAMMING',
    'Rafael Paiz',
    '',
    '+LEVEL DESIGN / ADDITIONAL GAME DESIGN',
    'Alex Mayberry',
    '',
    '+LEVEL DESIGN',
    'Mal Blackwell',
    'Dan Koppel',
    '',
    '+ART DIRECTION',
    'Michael "Maxx" Kaufman',
    '',
    '+COMPUTER GRAPHICS SUPERVISOR AND',
    '+CHARACTER ANIMATION DIRECTION',
    'Barry Dempsey',
    '',
    '+SENIOR ANIMATOR AND MODELER',
    'Jason Hoover',
    '',
    '+CHARACTER ANIMATION AND',
    '+MOTION CAPTURE SPECIALIST',
    'Amit Doron',
    '',
    '+ART',
    'Claire Praderie-Markham',
    'Viktor Antonov',
    'Corky Lehmkuhl',
    '',
    '+INTRODUCTION ANIMATION',
    'Dominique Drozdz',
    '',
    '+ADDITIONAL LEVEL DESIGN',
    'Aaron Barber',
    'Rhett Baldwin',
    '',
    '+3D CHARACTER ANIMATION TOOLS',
    'Gerry Tyra, SA Technology',
    '',
    '+ADDITIONAL EDITOR TOOL PROGRAMMING',
    'Robert Duffy',
    '',
    '+ADDITIONAL PROGRAMMING',
    'Ryan Feltrin',
    '',
    '+PRODUCTION COORDINATOR',
    'Victoria Sylvester',
    '',
    '+SOUND DESIGN',
    'Gary Bradfield',
    '',
    '+MUSIC BY',
    'Sonic Mayhem',
    '',
    '',
    '',
    '+SPECIAL THANKS',
    '+TO',
    '+OUR FRIENDS AT ID SOFTWARE',
    '',
    'John Carmack',
    'John Cash',
    'Brian Hook',
    'Adrian Carmack',
    'Kevin Cloud',
    'Paul Steed',
    'Tim Willits',
    'Christian Antkow',
    'Paul Jaquays',
    'Brandon James',
    'Todd Hollenshead',
    'Barrett (Bear) Alexander',
    'Dave "Zoid" Kirsch',
    'Donna Jackson',
    '',
    '',
    '',
    '+THANKS TO ACTIVISION',
    '+IN PARTICULAR:',
    '',
    'Marty Stratton',
    'Henk "The Original Ripper" Hartong',
    'Kevin Kraff',
    'Jamey Gottlieb',
    'Chris Hepburn',
    '',
    '+AND THE GAME TESTERS',
    '',
    'Tim Vanlaw',
    'Doug Jacobs',
    'Steven Rosenthal',
    'David Baker',
    'Chris Campbell',
    'Aaron Casillas',
    'Steve Elwell',
    'Derek Johnstone',
    'Igor Krinitskiy',
    'Samantha Lee',
    'Michael Spann',
    'Chris Toft',
    'Juan Valdes',
    '',
    '+THANKS TO INTERGRAPH COMPUTER SYTEMS',
    '+IN PARTICULAR:',
    '',
    'Michael T. Nicolaou',
    '',
    '',
    'Quake II Mission Pack: The Reckoning',
    '(tm) (C)1998 Id Software, Inc. All',
    'Rights Reserved. Developed by Xatrix',
    'Entertainment, Inc. for Id Software,',
    'Inc. Distributed by Activision Inc.',
    'under license. Quake(R) is a',
    'registered trademark of Id Software,',
    'Inc. Quake II Mission Pack: The',
    'Reckoning(tm), Quake II(tm), the Id',
    'Software name, the ''Q II''(tm) logo',
    'and id(tm) logo are trademarks of Id',
    'Software, Inc. Activision(R) is a',
    'registered trademark of Activision,',
    'Inc. Xatrix(R) is a registered',
    'trademark of Xatrix Entertainment,',
    'Inc. All other trademarks and trade',
    'names are properties of their',
    'respective owners.', nil
    );

  roguecredits: array[0..109] of PChar = (
    '+QUAKE II MISSION PACK 2: GROUND ZERO',
    '+BY',
    '+ROGUE ENTERTAINMENT, INC.',
    '',
    '+PRODUCED BY',
    'Jim Molinets',
    '',
    '+PROGRAMMING',
    'Peter Mack',
    'Patrick Magruder',
    '',
    '+LEVEL DESIGN',
    'Jim Molinets',
    'Cameron Lamprecht',
    'Berenger Fish',
    'Robert Selitto',
    'Steve Tietze',
    'Steve Thoms',
    '',
    '+ART DIRECTION',
    'Rich Fleider',
    '',
    '+ART',
    'Rich Fleider',
    'Steve Maines',
    'Won Choi',
    '',
    '+ANIMATION SEQUENCES',
    'Creat Studios',
    'Steve Maines',
    '',
    '+ADDITIONAL LEVEL DESIGN',
    'Rich Fleider',
    'Steve Maines',
    'Peter Mack',
    '',
    '+SOUND',
    'James Grunke',
    '',
    '+GROUND ZERO THEME',
    '+AND',
    '+MUSIC BY',
    'Sonic Mayhem',
    '',
    '+VWEP MODELS',
    'Brent "Hentai" Dill',
    '',
    '',
    '',
    '+SPECIAL THANKS',
    '+TO',
    '+OUR FRIENDS AT ID SOFTWARE',
    '',
    'John Carmack',
    'John Cash',
    'Brian Hook',
    'Adrian Carmack',
    'Kevin Cloud',
    'Paul Steed',
    'Tim Willits',
    'Christian Antkow',
    'Paul Jaquays',
    'Brandon James',
    'Todd Hollenshead',
    'Barrett (Bear) Alexander',
    'Katherine Anna Kang',
    'Donna Jackson',
    'Dave "Zoid" Kirsch',
    '',
    '',
    '',
    '+THANKS TO ACTIVISION',
    '+IN PARTICULAR:',
    '',
    'Marty Stratton',
    'Henk Hartong',
    'Mitch Lasky',
    'Steve Rosenthal',
    'Steve Elwell',
    '',
    '+AND THE GAME TESTERS',
    '',
    'The Ranger Clan',
    'Dave "Zoid" Kirsch',
    'Nihilistic Software',
    'Robert Duffy',
    '',
    'And Countless Others',
    '',
    '',
    '',
    'Quake II Mission Pack 2: Ground Zero',
    '(tm) (C)1998 Id Software, Inc. All',
    'Rights Reserved. Developed by Rogue',
    'Entertainment, Inc. for Id Software,',
    'Inc. Distributed by Activision Inc.',
    'under license. Quake(R) is a',
    'registered trademark of Id Software,',
    'Inc. Quake II Mission Pack 2: Ground',
    'Zero(tm), Quake II(tm), the Id',
    'Software name, the "Q II"(tm) logo',
    'and id(tm) logo are trademarks of Id',
    'Software, Inc. Activision(R) is a',
    'registered trademark of Activision,',
    'Inc. Rogue(R) is a registered',
    'trademark of Rogue Entertainment,',
    'Inc. All other trademarks and trade',
    'names are properties of their',
    'respective owners.', nil
    );

procedure M_Credits_MenuDraw;
var
  i, x, y, j, stringoffset: Integer;
  Bold: QBoolean;
label
  continue_;
begin
  {
  ** draw the credits
  }
  y := viddef.height - ((cls.realtime - credits_start_time) div 40);
  i := 0;
  while (PPCharArray(Credits)[i] <> nil) and (y < viddef.height) do
  begin
    stringoffset := 0;
    bold := False;

    if (y <= -8) then
      goto continue_;

    if (PPCharArray(credits)[i][0] = '+') then
    begin
      bold := True;
      stringoffset := 1;
    end
    else
      StringOffset := 0;

    j := 0;
    while PPCharArray(Credits)[i][j + stringoffset] <> #0 do
    begin
      x := (viddef.width - length(PPCharArray(credits)[i]) * 8 - stringoffset * 8) div 2 + (j +
        stringoffset) * 8;

      if bold then
        re.DrawChar(x, y, ord(PPCharArray(credits)[i][j + stringoffset]) + 128)
      else
        re.DrawChar(x, y, Ord(PPCharArray(credits)[i][j + stringoffset]));
      Inc(j);
    end;
    continue_:
    Inc(y, 10);
    Inc(i);
  end;

  if (y < 0) then
    credits_start_time := cls.realtime;
end;

function M_Credits_Key(Key: Integer): PChar;
begin
  case key of
    K_ESCAPE:
      begin
        if (creditsBuffer <> nil) then
          FS_FreeFile(creditsBuffer);
        M_PopMenu();
      end;
  end;

  result := menu_out_sound;
end;

procedure M_Menu_Credits_f;
var
  n, count, si: Integer;
  p: PChar;
  isDeveloper: Integer;
begin
  isDeveloper := 0;

  creditsBuffer := '';
  count := FS_LoadFile('credits', @creditsBuffer);
  if (count <> -1) then
  begin
    p := creditsBuffer;
    si := 0;                            // String index
    n := 0;
    for n := 0 to 254 do
    begin
      creditsIndex[n] := p[si];
      while not (p[si] in [#13, #10]) do
      begin                             // \r and \n
        Inc(si);                        //   p++;
        Dec(Count);
        if (count = 0) then
          Break;
      end;
      {  if (p[si] = '\r') then begin
          *p++ := 0;
          if (--count = 0)
           break;
         end;}
      p[si] := #0;
      Inc(si);                          // *p++ := 0;
      Dec(Count);
      if (count = 0) then
        Break;
    end;
    Inc(n);
    creditsIndex[n] := #0;              // Dangerous!
    credits := @creditsIndex;           // ?? What should this do?
  end
  else
  begin
    isdeveloper := Developer_searchpath(1);

    case isdeveloper of
      1: credits := @xatcredits;        // xatrix
      2: credits := @roguecredits;      // Rogue
    else
      // In Delphi conversion we show "our" credits
      //credits := @idcredits;
      credits := @q2d_credits;
    end;

    credits_start_time := cls.realtime;
    M_PushMenu(@M_Credits_MenuDraw, @M_Credits_Key);
  end;
end;

{
=======================================

GAME MENU

=======================================
}

// All vars static

var
  m_game_cursor: Integer;

  s_game_menu: menuframework_s;
  s_easy_game_action,
    s_medium_game_action,
    s_hard_game_action,
    s_load_game_action,
    s_save_game_action,
    s_credits_action: MenuAction_s;
  s_blankline: menuseparator_s;

procedure StartGame;                    // static
begin
  // disable updates and start the cinematic going
  cl.servercount := -1;
  M_ForceMenuOff();
  Cvar_SetValue('deathmatch', 0);
  Cvar_SetValue('coop', 0);

  Cvar_SetValue('gamerules', 0);        //PGM

  Cbuf_AddText('loading ; killserver ; wait ; newgame'#10);
  cls.key_dest := key_game;
end;

procedure EasyGameFunc(Data: Pointer);  // static
begin
  Cvar_ForceSet('skill', '0');
  StartGame();
end;

procedure MediumGameFunc(Data: Pointer); // static
begin
  Cvar_ForceSet('skill', '1');
  StartGame();
end;

procedure HardGameFunc(Data: Pointer);  // static
begin
  Cvar_ForceSet('skill', '2');
  StartGame();
end;

procedure LoadGameFunc(Data: Pointer);  // static
begin
  M_Menu_LoadGame_f();
end;

procedure SaveGameFunc(Data: Pointer);  // static
begin
  M_Menu_SaveGame_f();
end;

procedure CreditsFunc(Data: Pointer);   // static
begin
  M_Menu_Credits_f();
end;

procedure Game_MenuInit;
const
  Difficulty_names: array[0..3] of PChar =
  ('Easy', 'Medium', 'Hard', nil);
begin
  s_game_menu.x := viddef.width div 2;
  s_game_menu.nitems := 0;

  s_easy_game_action.generic.type_ := MTYPE_ACTION;
  s_easy_game_action.generic.flags := QMF_LEFT_JUSTIFY;
  s_easy_game_action.generic.x := 0;
  s_easy_game_action.generic.y := 0;
  s_easy_game_action.generic.name := 'easy';
  s_easy_game_action.generic.callback := EasyGameFunc;

  s_medium_game_action.generic.type_ := MTYPE_ACTION;
  s_medium_game_action.generic.flags := QMF_LEFT_JUSTIFY;
  s_medium_game_action.generic.x := 0;
  s_medium_game_action.generic.y := 10;
  s_medium_game_action.generic.name := 'medium';
  s_medium_game_action.generic.callback := MediumGameFunc;

  s_hard_game_action.generic.type_ := MTYPE_ACTION;
  s_hard_game_action.generic.flags := QMF_LEFT_JUSTIFY;
  s_hard_game_action.generic.x := 0;
  s_hard_game_action.generic.y := 20;
  s_hard_game_action.generic.name := 'hard';
  s_hard_game_action.generic.callback := HardGameFunc;

  s_blankline.generic.type_ := MTYPE_SEPARATOR;

  s_load_game_action.generic.type_ := MTYPE_ACTION;
  s_load_game_action.generic.flags := QMF_LEFT_JUSTIFY;
  s_load_game_action.generic.x := 0;
  s_load_game_action.generic.y := 40;
  s_load_game_action.generic.name := 'load game';
  s_load_game_action.generic.callback := LoadGameFunc;

  s_save_game_action.generic.type_ := MTYPE_ACTION;
  s_save_game_action.generic.flags := QMF_LEFT_JUSTIFY;
  s_save_game_action.generic.x := 0;
  s_save_game_action.generic.y := 50;
  s_save_game_action.generic.name := 'save game';
  s_save_game_action.generic.callback := SaveGameFunc;

  s_credits_action.generic.type_ := MTYPE_ACTION;
  s_credits_action.generic.flags := QMF_LEFT_JUSTIFY;
  s_credits_action.generic.x := 0;
  s_credits_action.generic.y := 60;
  s_credits_action.generic.name := 'credits';
  s_credits_action.generic.callback := CreditsFunc;

  Menu_AddItem(@s_game_menu, @s_easy_game_action);
  Menu_AddItem(@s_game_menu, @s_medium_game_action);
  Menu_AddItem(@s_game_menu, @s_hard_game_action);
  Menu_AddItem(@s_game_menu, @s_blankline);
  Menu_AddItem(@s_game_menu, @s_load_game_action);
  Menu_AddItem(@s_game_menu, @s_save_game_action);
  Menu_AddItem(@s_game_menu, @s_blankline);
  Menu_AddItem(@s_game_menu, @s_credits_action);

  Menu_Center(@s_game_menu);
end;

procedure Game_MenuDraw;
begin
  M_Banner('m_banner_game');
  Menu_AdjustCursor(@s_game_menu, 1);
  Menu_Draw(@s_game_menu);
end;

function Game_MenuKey(Key: Integer): PChar;
begin
  result := Default_MenuKey(@s_game_menu, key);
end;

procedure M_Menu_Game_f;
begin
  Game_MenuInit();
  M_PushMenu(@Game_MenuDraw, @Game_MenuKey);
  m_game_cursor := 1;
end;

{
=======================================

LOADGAME MENU

=======================================
}

const
  MAX_SAVEGAMES = 15;

var
  // These vars static
  s_loadgame_menu: menuframework_s;
  s_loadgame_actions: array[0..MAX_SAVEGAMES - 1] of menuaction_s;

  s_savegame_menu: menuframework_s;
  s_savegame_actions: array[0..MAX_SAVEGAMES - 1] of menuaction_s;

  // These not static
  m_savestrings: array[0..MAX_SAVEGAMES - 1, 0..31] of char;
  m_savevalid: array[0..MAX_SAVEGAMES - 1] of QBoolean;

procedure Create_Savestrings;
var
  i, f: Integer;                        // f was FILE *
  name: array[0..MAX_OSPATH - 1] of char;
begin
  for i := 0 to MAX_SAVEGAMES - 1 do
  begin
    Com_sprintf(name, sizeof(name), '%s/save/save%d/server.ssv', [FS_Gamedir(),
      i]);
    f := FileOpen(name, fmOpenRead);
    if f < 0 then
    begin
      m_savestrings[i] := '<EMPTY>';
      m_savevalid[i] := False;
    end
    else
    begin
      FS_Read(@m_savestrings[i], sizeof(m_savestrings[i]), f);
      FileClose(f);
      m_savevalid[i] := True;
    end;
  end;
end;

procedure LoadGameCallback(Self: Pointer);
var
  a: MenuAction_p;
begin
  a := menuaction_p(self);

  if (m_savevalid[a^.generic.localdata[0]]) then
    Cbuf_AddText(va('load save%d'#10, [a^.generic.localdata[0]]));
  M_ForceMenuOff();
end;

procedure LoadGame_MenuInit;
var
  i: Integer;
begin
  s_loadgame_menu.x := viddef.Width div 2 - 120;
  s_loadgame_menu.y := viddef.Height div 2 - 58;
  s_loadgame_menu.nitems := 0;

  Create_Savestrings();

  for i := 0 to MAX_SAVEGAMES - 1 do
  begin
    s_loadgame_actions[i].generic.name := m_savestrings[i];
    s_loadgame_actions[i].generic.flags := QMF_LEFT_JUSTIFY;
    s_loadgame_actions[i].generic.localdata[0] := i;
    s_loadgame_actions[i].generic.callback := LoadGameCallback;

    s_loadgame_actions[i].generic.x := 0;
    s_loadgame_actions[i].generic.y := (i) * 10;
    if (i > 0) then                     // separate from autosave
      s_loadgame_actions[i].generic.y := s_loadgame_actions[i].generic.y + 10;

    s_loadgame_actions[i].generic.type_ := MTYPE_ACTION;

    Menu_AddItem(@s_loadgame_menu, @s_loadgame_actions[i]);
  end;
end;

procedure LoadGame_MenuDraw;
begin
  M_Banner('m_banner_load_game');
  //Menu_AdjustCursor( @s_loadgame_menu, 1 );
  Menu_Draw(@s_loadgame_menu);
end;

function LoadGame_MenuKey(Key: Integer): PChar;
begin
  if key in [K_ESCAPE, K_ENTER] then
  begin
    s_savegame_menu.cursor := s_loadgame_menu.cursor - 1;
    if (s_savegame_menu.cursor < 0) then
      s_savegame_menu.cursor := 0;
  end;
  result := Default_MenuKey(@s_loadgame_menu, key);
end;

procedure M_Menu_LoadGame_f;
begin
  LoadGame_MenuInit();
  M_PushMenu(@LoadGame_MenuDraw, @LoadGame_MenuKey);
end;

{
=======================================

SAVEGAME MENU

=======================================
}

procedure SaveGameCallback(Self: Pointer);
var
  a: MenuAction_p;
begin
  a := menuaction_p(self);

  Cbuf_AddText(va('save save%d'#10, [a^.generic.localdata[0]]));
  M_ForceMenuOff();
end;

procedure SaveGame_MenuDraw;
begin
  M_Banner('m_banner_save_game');
  Menu_AdjustCursor(@s_savegame_menu, 1);
  Menu_Draw(@s_savegame_menu);
end;

procedure SaveGame_MenuInit;
var
  i: Integer;
begin
  s_savegame_menu.x := viddef.Width div 2 - 120;
  s_savegame_menu.y := viddef.Height div 2 - 58;
  s_savegame_menu.nitems := 0;

  Create_Savestrings();

  // don't include the autosave slot
  for i := 0 to MAX_SAVEGAMES - 2 do
  begin
    s_savegame_actions[i].generic.name := m_savestrings[i + 1];
    s_savegame_actions[i].generic.localdata[0] := i + 1;
    s_savegame_actions[i].generic.flags := QMF_LEFT_JUSTIFY;
    s_savegame_actions[i].generic.callback := SaveGameCallback;

    s_savegame_actions[i].generic.x := 0;
    s_savegame_actions[i].generic.y := (i) * 10;

    s_savegame_actions[i].generic.type_ := MTYPE_ACTION;

    Menu_AddItem(@s_savegame_menu, @s_savegame_actions[i]);
  end;
end;

function SaveGame_MenuKey(Key: Integer): PChar;
begin
  if key in [K_ENTER, K_ESCAPE] then
  begin
    s_loadgame_menu.cursor := s_savegame_menu.cursor - 1;
    if (s_loadgame_menu.cursor < 0) then
      s_loadgame_menu.cursor := 0;
  end;
  result := Default_MenuKey(@s_savegame_menu, key);
end;

procedure M_Menu_SaveGame_f;
begin
  if Com_ServerState() = 0 then
    exit;                               // not playing a game

  SaveGame_MenuInit();
  M_PushMenu(@SaveGame_MenuDraw, @SaveGame_MenuKey);
  Create_Savestrings();
end;

{
=======================================

JOIN SERVER MENU

=======================================
}
const
  MAX_LOCAL_SERVERS = 8;

  // Menu vars are static
var
  s_joinserver_menu: menuframework_s;
  s_joinserver_server_title: menuseparator_s;
  s_joinserver_search_action, s_joinserver_address_book_action: menuaction_s;
  s_joinserver_server_actions: array[0..MAX_LOCAL_SERVERS - 1] of MenuAction_s;

  m_num_servers: Integer;               // NOT static
const
  NO_SERVER_STRING = '<no server>';

  // user readable information (static)
const
  SERVER_NAME_SIZE = 80;
var
  local_server_names: array[0..MAX_LOCAL_SERVERS - 1, 0..SERVER_NAME_SIZE - 1] of char;

  // network address (static)
  local_server_netadr: array[0..MAX_LOCAL_SERVERS - 1] of netadr_t;

procedure M_AddToServerList(Adr: netadr_t; Info: PChar);
var
  i: Integer;
begin
  if (m_num_servers = MAX_LOCAL_SERVERS) then
    exit;

  while info^ = ' ' do
    Inc(info);

  // ignore if duplicated
  for i := 0 to m_num_servers - 1 do
    if (strcmp(info, local_server_names[i]) = 0) then
      Exit;

  local_server_netadr[m_num_servers] := adr;
  strncpy(local_server_names[m_num_servers], info, sizeof(local_server_names[0]) - 1);
  Inc(m_num_servers);
end;

procedure JoinServerFunc(Self: Pointer);
var
  buffer: array[0..127] of Char;
  index: Integer;
begin
  index := (Cardinal(Self) - Cardinal(@s_joinserver_server_actions)) div SizeOf(MenuAction_s);

  if local_server_names[index] = NO_SERVER_STRING then
    exit;
  if (index >= m_num_servers) then
    exit;
  Com_sprintf(buffer, sizeof(buffer), 'connect %s'#10,
    [NET_AdrToString(local_server_netadr[index])]);
  Cbuf_AddText(buffer);
  M_ForceMenuOff();
end;

procedure AddressBookFunc(Self: Pointer);
begin
  M_Menu_AddressBook_f();
end;

procedure SearchLocalGames;
var
  i: Integer;
begin
  m_num_servers := 0;
  for i := 0 to MAX_LOCAL_SERVERS - 1 do
    local_server_names[i] := NO_SERVER_STRING;

  M_DrawTextBox(8, 120 - 48, 36, 3);
  M_Print(16 + 16, 120 - 48 + 8, 'Searching for local servers, this');
  M_Print(16 + 16, 120 - 48 + 16, 'could take up to a minute, so');
  M_Print(16 + 16, 120 - 48 + 24, 'please be patient.');

  // the text box won't show up unless we do a buffer swap
  re.EndFrame();

  // send out info packets
  CL_PingServers_f();
end;

procedure SearchLocalGamesFunc(Self: pointer);
begin
  SearchLocalGames();
end;

procedure JoinServer_MenuInit;
var
  i: Integer;
begin
  s_joinserver_menu.x := trunc(viddef.width * 0.50 - 120);
  s_joinserver_menu.nitems := 0;

  s_joinserver_address_book_action.generic.type_ := MTYPE_ACTION;
  s_joinserver_address_book_action.generic.name := 'address book';
  s_joinserver_address_book_action.generic.flags := QMF_LEFT_JUSTIFY;
  s_joinserver_address_book_action.generic.x := 0;
  s_joinserver_address_book_action.generic.y := 0;
  s_joinserver_address_book_action.generic.callback := AddressBookFunc;

  s_joinserver_search_action.generic.type_ := MTYPE_ACTION;
  s_joinserver_search_action.generic.name := 'refresh server list';
  s_joinserver_search_action.generic.flags := QMF_LEFT_JUSTIFY;
  s_joinserver_search_action.generic.x := 0;
  s_joinserver_search_action.generic.y := 10;
  s_joinserver_search_action.generic.callback := SearchLocalGamesFunc;
  s_joinserver_search_action.generic.statusbar := 'search for servers';

  s_joinserver_server_title.generic.type_ := MTYPE_SEPARATOR;
  s_joinserver_server_title.generic.name := 'connect to...';
  s_joinserver_server_title.generic.x := 80;
  s_joinserver_server_title.generic.y := 30;

  for i := 0 to MAX_LOCAL_SERVERS - 1 do
  begin
    s_joinserver_server_actions[i].generic.type_ := MTYPE_ACTION;
    strcpy(local_server_names[i], NO_SERVER_STRING);
    s_joinserver_server_actions[i].generic.name := local_server_names[i];
    s_joinserver_server_actions[i].generic.flags := QMF_LEFT_JUSTIFY;
    s_joinserver_server_actions[i].generic.x := 0;
    s_joinserver_server_actions[i].generic.y := 40 + i * 10;
    s_joinserver_server_actions[i].generic.callback := JoinServerFunc;
    s_joinserver_server_actions[i].generic.statusbar :=
      'press ENTER to connect';
  end;

  Menu_AddItem(@s_joinserver_menu, @s_joinserver_address_book_action);
  Menu_AddItem(@s_joinserver_menu, @s_joinserver_server_title);
  Menu_AddItem(@s_joinserver_menu, @s_joinserver_search_action);

  for i := 0 to 7 do
    Menu_AddItem(@s_joinserver_menu, @s_joinserver_server_actions[i]);

  Menu_Center(@s_joinserver_menu);

  SearchLocalGames();
end;

procedure JoinServer_MenuDraw;
begin
  M_Banner('m_banner_join_server');
  Menu_Draw(@s_joinserver_menu);
end;

function JoinServer_MenuKey(Key: Integer): PChar;
begin
  Result := Default_MenuKey(@s_joinserver_menu, key);
end;

procedure M_Menu_JoinServer_f;
begin
  JoinServer_MenuInit();
  M_PushMenu(@JoinServer_MenuDraw, @JoinServer_MenuKey);
end;

{
=======================================

START SERVER MENU

=======================================
}

// all menu vars are static
var
  s_startserver_menu: menuframework_s;
  mapnames: PPCharArray;
  nummaps: Integer;

  s_startserver_start_action, s_startserver_dmoptions_action: menuaction_s;
  s_timelimit_field, s_fraglimit_field,
    s_maxclients_field, s_hostname_field: menufield_s;
  s_startmap_list, s_rules_box: menulist_s;

procedure DMOptionsFunc(Self: Pointer);
begin
  if (s_rules_box.curvalue = 1) then
    exit;
  M_Menu_DMOptions_f();
end;

procedure RulesChangeFunc(Self: Pointer);
begin
  // DM
  if (s_rules_box.curvalue = 0) then
  begin
    s_maxclients_field.generic.statusbar := nil;
    s_startserver_dmoptions_action.generic.statusbar := nil;
  end
  else if (s_rules_box.curvalue = 1) then
  begin                                 // coop            // PGM
    s_maxclients_field.generic.statusbar := '4 maximum for cooperative';
    if (StrToInt(s_maxclients_field.buffer) > 4) then
      s_maxclients_field.buffer := '4';
    s_startserver_dmoptions_action.generic.statusbar := 'N/A for cooperative';
  end
    //===
    //PGM
    // ROGUE GAMES
  else if (Developer_searchpath(2) = 2) then
  begin
    if (s_rules_box.curvalue = 2) then
    begin                               // tag
      s_maxclients_field.generic.statusbar := nil;
      s_startserver_dmoptions_action.generic.statusbar := nil;
      {
           end   else if(s_rules_box.curvalue = 3)      // deathball
        begin
         s_maxclients_field.generic.statusbar := nil;
         s_startserver_dmoptions_action.generic.statusbar := nil;
      }
    end;
  end;
  //PGM
  //===
end;

procedure StartServerActionFunc(Self: Pointer);
var
  startmap: array[0..1024 - 1] of char;
  timelimit, fraglimit, maxclients: Integer;
  spot, mn: PChar;
begin
  strcpy(startmap, strchr(PPCharArray(mapnames)[s_startmap_list.curvalue], 10) + 1);

  maxclients := atoi(s_maxclients_field.buffer);
  timelimit := atoi(s_timelimit_field.buffer);
  fraglimit := atoi(s_fraglimit_field.buffer);

  Cvar_SetValue('maxclients', ClampCvar(0, maxclients, maxclients));
  Cvar_SetValue('timelimit', ClampCvar(0, timelimit, timelimit));
  Cvar_SetValue('fraglimit', ClampCvar(0, fraglimit, fraglimit));
  Cvar_Set('hostname', s_hostname_field.buffer);
  //   Cvar_SetValue ('deathmatch', not s_rules_box.curvalue );
  //   Cvar_SetValue ('coop', s_rules_box.curvalue );

  //PGM
  if (s_rules_box.curvalue < 2) or (Developer_searchpath(2) <> 2) then
  begin
    Cvar_SetValue('deathmatch', Integer(not
      QBoolean(Trunc(s_rules_box.curvalue))));
    Cvar_SetValue('coop', s_rules_box.curvalue);
    Cvar_SetValue('gamerules', 0);
  end
  else
  begin
    Cvar_SetValue('deathmatch', 1);     // deathmatch is always Integer(True) for rogue games, right?
    Cvar_SetValue('coop', 0);           // FIXME - this might need to depend on which game we're running
    Cvar_SetValue('gamerules', s_rules_box.curvalue);
  end;
  //PGM

  spot := nil;
  if (s_rules_box.curvalue = 1) then
  begin                                 // PGM
    if (Q_stricmp(startmap, 'bunk1') = 0) then
      spot := 'start'
    else if (Q_stricmp(startmap, 'mintro') = 0) then
      spot := 'start'
    else if (Q_stricmp(startmap, 'fact1') = 0) then
      spot := 'start'
    else if (Q_stricmp(startmap, 'power1') = 0) then
      spot := 'pstart'
    else if (Q_stricmp(startmap, 'biggun') = 0) then
      spot := 'bstart'
    else if (Q_stricmp(startmap, 'hangar1') = 0) then
      spot := 'unitstart'
    else if (Q_stricmp(startmap, 'city1') = 0) then
      spot := 'unitstart'
    else if (Q_stricmp(startmap, 'boss1') = 0) then
      spot := 'bosstart';
  end;

  if spot <> nil then
  begin
    if Com_ServerState() <> 0 then
      Cbuf_AddText('disconnect'#10);
    Cbuf_AddText(va('gamemap "*%s$%s"'#10, [startmap, spot]));
  end
  else
    Cbuf_AddText(va('map %s'#10, [startmap]));

  M_ForceMenuOff();
end;

procedure StartServer_MenuInit;
const
  dm_coop_names: array[0..2] of PChar =
  ('deathmatch', 'cooperative', nil);
  dm_coop_names_rogue: array[0..3] of PChar =
  ('deathmatch', 'cooperative', 'tag' {, 'deathball'}, nil);
var
  scratch: array[0..200 - 1] of Char;
  buffer: PChar;
  mapsname: array[0..1024 - 1] of Char;
  s: PChar;
  length, i, j, l: Integer;
  FP: Integer;                          // was FILE *
  Shortname,
    Longname: array[0..MAX_TOKEN_CHARS - 1] of Char;
begin
  {
  ** load the list of map names
  }
  Com_sprintf(mapsname, sizeof(mapsname), '%s/maps.lst', [FS_Gamedir()]);
  fp := FileOpen(mapsname, fmOpenRead);
  if fp <= 0 then
  begin
    length := FS_LoadFile('maps.lst', @buffer);
    if length = -1 then
      Com_Error(ERR_DROP, 'couldn''t find maps.lst'#10);
  end
  else
  begin
    length := FileSeek(fp, 0, 2);
    FileSeek(fp, 0, 0);
    buffer := AllocMem(length);
    FileRead(fp, buffer^, length);      // was "fread( buffer, length, 1, fp );"
  end;

  s := buffer;
  i := 0;
  while i < length do
  begin
    if s[i] = #13 then
      Inc(nummaps);
    Inc(i);
  end;

  if nummaps = 0 then
    Com_Error(ERR_DROP, 'no maps in maps.lst'#10);

  mapnames := AllocMem(SizeOf(pchar) * (nummaps + 1));
  FillChar(mapnames^, SizeOf(pchar) * (nummaps + 1), 0);

  s := buffer;

  for i := 0 to nummaps - 1 do
  begin
    strcpy(shortname, COM_Parse(s));
    l := strlen(shortname);
    for j := 0 to l - 1 do
      shortname[j] := upcase(shortname[j]);

    strcpy(longname, COM_Parse(s));
    Com_sprintf(scratch, sizeof(scratch), '%s'#10'%s', [longname, shortname]);

    mapnames[i] := AllocMem(strlen(scratch) + 1);
    strcpy(mapnames[i], scratch);
  end;
  MapNames[nummaps] := nil;

  if fp > 0 then
  begin
    fp := 0;
    FreeMem(buffer);
  end
  else
  begin
    FS_FreeFile(buffer);
  end;

  {
  ** initialize the menu stuff
  }
  s_startserver_menu.x := trunc(viddef.width * 0.50);
  s_startserver_menu.nitems := 0;

  s_startmap_list.generic.type_ := MTYPE_SPINCONTROL;
  s_startmap_list.generic.x := 0;
  s_startmap_list.generic.y := 0;
  s_startmap_list.generic.name := 'initial map';
  s_startmap_list.itemnames := mapnames;

  s_rules_box.generic.type_ := MTYPE_SPINCONTROL;
  s_rules_box.generic.x := 0;
  s_rules_box.generic.y := 20;
  s_rules_box.generic.name := 'rules';

  //PGM - rogue games only available with rogue DLL.
  if (Developer_searchpath(2) = 2) then
    s_rules_box.itemnames := @dm_coop_names_rogue
  else
    s_rules_box.itemnames := @dm_coop_names;
  //PGM

  if (Cvar_VariableValue('coop') <> 0) then
    s_rules_box.curvalue := 1
  else
    s_rules_box.curvalue := 0;
  s_rules_box.generic.callback := RulesChangeFunc;

  s_timelimit_field.generic.type_ := MTYPE_FIELD;
  s_timelimit_field.generic.name := 'time limit';
  s_timelimit_field.generic.flags := QMF_NUMBERSONLY;
  s_timelimit_field.generic.x := 0;
  s_timelimit_field.generic.y := 36;
  s_timelimit_field.generic.statusbar := '0 := no limit';
  s_timelimit_field.length := 3;
  s_timelimit_field.visible_length := 3;
  strcpy(s_timelimit_field.buffer, Cvar_VariableString('timelimit'));

  s_fraglimit_field.generic.type_ := MTYPE_FIELD;
  s_fraglimit_field.generic.name := 'frag limit';
  s_fraglimit_field.generic.flags := QMF_NUMBERSONLY;
  s_fraglimit_field.generic.x := 0;
  s_fraglimit_field.generic.y := 54;
  s_fraglimit_field.generic.statusbar := '0 := no limit';
  s_fraglimit_field.length := 3;
  s_fraglimit_field.visible_length := 3;
  strcpy(s_fraglimit_field.buffer, Cvar_VariableString('fraglimit'));

  {
  ** maxclients determines the maximum number of players that can join
  ** the game.  If maxclients is only '1' then we should default the menu
  ** option to 8 players, otherwise use whatever its current value is.
  ** Clamping will be done when the server is actually started.
  }
  s_maxclients_field.generic.type_ := MTYPE_FIELD;
  s_maxclients_field.generic.name := 'max players';
  s_maxclients_field.generic.flags := QMF_NUMBERSONLY;
  s_maxclients_field.generic.x := 0;
  s_maxclients_field.generic.y := 72;
  s_maxclients_field.generic.statusbar := nil;
  s_maxclients_field.length := 3;
  s_maxclients_field.visible_length := 3;
  if (Cvar_VariableValue('maxclients') = 1) then
    strcpy(s_maxclients_field.buffer, '8')
  else
    strcpy(s_maxclients_field.buffer, Cvar_VariableString('maxclients'));

  s_hostname_field.generic.type_ := MTYPE_FIELD;
  s_hostname_field.generic.name := 'hostname';
  s_hostname_field.generic.flags := 0;
  s_hostname_field.generic.x := 0;
  s_hostname_field.generic.y := 90;
  s_hostname_field.generic.statusbar := nil;
  s_hostname_field.length := 12;
  s_hostname_field.visible_length := 12;
  strcpy(s_hostname_field.buffer, Cvar_VariableString('hostname'));

  s_startserver_dmoptions_action.generic.type_ := MTYPE_ACTION;
  s_startserver_dmoptions_action.generic.name := ' deathmatch flags';
  s_startserver_dmoptions_action.generic.flags := QMF_LEFT_JUSTIFY;
  s_startserver_dmoptions_action.generic.x := 24;
  s_startserver_dmoptions_action.generic.y := 108;
  s_startserver_dmoptions_action.generic.statusbar := nil;
  s_startserver_dmoptions_action.generic.callback := DMOptionsFunc;

  s_startserver_start_action.generic.type_ := MTYPE_ACTION;
  s_startserver_start_action.generic.name := ' begin';
  s_startserver_start_action.generic.flags := QMF_LEFT_JUSTIFY;
  s_startserver_start_action.generic.x := 24;
  s_startserver_start_action.generic.y := 128;
  s_startserver_start_action.generic.callback := StartServerActionFunc;

  Menu_AddItem(@s_startserver_menu, @s_startmap_list);
  Menu_AddItem(@s_startserver_menu, @s_rules_box);
  Menu_AddItem(@s_startserver_menu, @s_timelimit_field);
  Menu_AddItem(@s_startserver_menu, @s_fraglimit_field);
  Menu_AddItem(@s_startserver_menu, @s_maxclients_field);
  Menu_AddItem(@s_startserver_menu, @s_hostname_field);
  Menu_AddItem(@s_startserver_menu, @s_startserver_dmoptions_action);
  Menu_AddItem(@s_startserver_menu, @s_startserver_start_action);

  Menu_Center(@s_startserver_menu);

  // call this now to set proper inital state
  RulesChangeFunc(nil);
end;

procedure StartServer_MenuDraw;
begin
  Menu_Draw(@s_startserver_menu);
end;

function StartServer_MenuKey(Key: Integer): PChar;
var
  i: Integer;
begin
  if key = K_ESCAPE then
  begin
    if mapnames <> nil then
    begin
      for i := 0 to nummaps - 1 do
        FreeMem(mapnames[i]);
      FreeMem(mapnames);
    end;
    nummaps := 0;
  end;

  result := Default_MenuKey(@s_startserver_menu, key);
end;

procedure M_Menu_StartServer_f;
begin
  StartServer_MenuInit();
  M_PushMenu(@StartServer_MenuDraw, @StartServer_MenuKey);
end;

{
=======================================

DMOPTIONS BOOK MENU

=======================================
}
// All static
var
  dmoptions_statusbar: array[0..127] of Char;

  s_dmoptions_menu: menuframework_s;

  s_friendlyfire_box,
    s_falls_box,
    s_weapons_stay_box,
    s_instant_powerups_box,
    s_powerups_box,
    s_health_box,
    s_spawn_farthest_box,
    s_teamplay_box,
    s_samelevel_box,
    s_force_respawn_box,
    s_armor_box,
    s_allow_exit_box,
    s_infinite_ammo_box,
    s_fixed_fov_box,
    s_quad_drop_box: MenuList_s;

  //ROGUE
  s_no_mines_box,
    s_no_nukes_box,
    s_stack_double_box,
    s_no_spheres_box: MenuList_S;
  //ROGUE

procedure DMFlagCallback(Self: Pointer); // static
var
  f: MenuList_p;
  flags, bit: Integer;
begin
  f := menulist_p(self);
  bit := 0;

  flags := trunc(Cvar_VariableValue('dmflags'));

  if f = @s_friendlyfire_box then
  begin
    if f^.curvalue <> 0 then
      flags := flags and (not DF_NO_FRIENDLY_FIRE)
    else
      flags := flags or DF_NO_FRIENDLY_FIRE;
  end
  else if f = @s_falls_box then
  begin
    if f^.curvalue <> 0 then
      flags := flags and (not DF_NO_FALLING)
    else
      flags := flags or DF_NO_FALLING;
  end
  else if f = @s_weapons_stay_box then
  begin
    bit := DF_WEAPONS_STAY;
  end
  else if (f = @s_instant_powerups_box) then
    bit := DF_INSTANT_ITEMS
  else if (f = @s_allow_exit_box) then
    bit := DF_ALLOW_EXIT
  else if (f = @s_powerups_box) then
  begin
    if f^.curvalue <> 0 then
      flags := flags and (not DF_NO_ITEMS)
    else
      flags := flags or DF_NO_ITEMS;
  end
  else if (f = @s_health_box) then
  begin
    if f^.curvalue <> 0 then
      flags := flags and (not DF_NO_HEALTH)
    else
      flags := flags or DF_NO_HEALTH;
  end
  else if (f = @s_spawn_farthest_box) then
    bit := DF_SPAWN_FARTHEST
  else if (f = @s_teamplay_box) then
  begin
    case f^.curvalue of
      1:
        begin
          flags := flags or DF_SKINTEAMS;
          flags := flags and (not DF_MODELTEAMS);
        end;
      2:
        begin
          flags := flags or DF_MODELTEAMS;
          flags := flags and (not DF_SKINTEAMS);
        end;
    else
      flags := flags and (not (DF_MODELTEAMS or DF_SKINTEAMS));
    end;
  end
  else if (f = @s_samelevel_box) then
    bit := DF_SAME_LEVEL
  else if (f = @s_force_respawn_box) then
    bit := DF_FORCE_RESPAWN
  else if (f = @s_armor_box) then
  begin
    if f^.curvalue <> 0 then
      flags := flags and (not DF_NO_ARMOR)
    else
      flags := flags or DF_NO_ARMOR;
  end
  else if (f = @s_infinite_ammo_box) then
    bit := DF_INFINITE_AMMO
  else if (f = @s_fixed_fov_box) then
    bit := DF_FIXED_FOV
  else if (f = @s_quad_drop_box) then
    bit := DF_QUAD_DROP

    //====
    //ROGUE
  else if (Developer_searchpath(2) = 2) then
  begin
    if (f = @s_no_mines_box) then
      bit := DF_NO_MINES
    else if (f = @s_no_nukes_box) then
      bit := DF_NO_NUKES
    else if (f = @s_stack_double_box) then
      bit := DF_NO_STACK_DOUBLE
    else if (f = @s_no_spheres_box) then
    begin
      bit := DF_NO_SPHERES
    end;
  end;
  //ROGUE (end)
  //====

  if (f <> nil) and (bit <> 0) then
  begin
    if (f^.curvalue = 0) then
      Flags := Flags and (not bit)
    else
      Flags := Flags or bit;
  end;

  Cvar_SetValue('dmflags', flags);
  Com_sprintf(dmoptions_statusbar, sizeof(dmoptions_statusbar), 'dmflags := %d',
    [flags]);
end;

procedure DMOptions_MenuInit;
const
  yes_no_names: array[0..2] of PChar =
  ('no', 'yes', nil);
  teamplay_names: array[0..3] of PChar =
  ('disabled', 'by skin', 'by model', nil);
var
  dmflags, y: Integer;
begin
  dmflags := trunc(Cvar_VariableValue('dmflags'));
  y := 0;

  s_dmoptions_menu.x := trunc(viddef.width * 0.50);
  s_dmoptions_menu.nitems := 0;

  s_falls_box.generic.type_ := MTYPE_SPINCONTROL;
  s_falls_box.generic.x := 0;
  s_falls_box.generic.y := y;
  s_falls_box.generic.name := 'falling damage';
  s_falls_box.generic.callback := DMFlagCallback;
  s_falls_box.itemnames := @yes_no_names;
  s_falls_box.curvalue := Integer((dmflags and DF_NO_FALLING) = 0);

  s_weapons_stay_box.generic.type_ := MTYPE_SPINCONTROL;
  s_weapons_stay_box.generic.x := 0;
  s_weapons_stay_box.generic.y := y + 10;
  Inc(y, 10);
  s_weapons_stay_box.generic.name := 'weapons stay';
  s_weapons_stay_box.generic.callback := DMFlagCallback;
  s_weapons_stay_box.itemnames := @yes_no_names;
  s_weapons_stay_box.curvalue := Integer((dmflags and DF_WEAPONS_STAY) <> 0);

  s_instant_powerups_box.generic.type_ := MTYPE_SPINCONTROL;
  s_instant_powerups_box.generic.x := 0;
  s_instant_powerups_box.generic.y := y + 10;
  Inc(y, 10);
  s_instant_powerups_box.generic.name := 'instant powerups';
  s_instant_powerups_box.generic.callback := DMFlagCallback;
  s_instant_powerups_box.itemnames := @yes_no_names;
  s_instant_powerups_box.curvalue := Integer((dmflags and DF_INSTANT_ITEMS) <> 0);

  s_powerups_box.generic.type_ := MTYPE_SPINCONTROL;
  s_powerups_box.generic.x := 0;
  s_powerups_box.generic.y := y + 10;
  Inc(y, 10);
  s_powerups_box.generic.name := 'allow powerups';
  s_powerups_box.generic.callback := DMFlagCallback;
  s_powerups_box.itemnames := @yes_no_names;
  s_powerups_box.curvalue := Integer((dmflags and DF_NO_ITEMS) = 0);

  s_health_box.generic.type_ := MTYPE_SPINCONTROL;
  s_health_box.generic.x := 0;
  s_health_box.generic.y := y + 10;
  Inc(y, 10);
  s_health_box.generic.callback := DMFlagCallback;
  s_health_box.generic.name := 'allow health';
  s_health_box.itemnames := @yes_no_names;
  s_health_box.curvalue := Integer((dmflags and DF_NO_HEALTH) = 0);

  s_armor_box.generic.type_ := MTYPE_SPINCONTROL;
  s_armor_box.generic.x := 0;
  s_armor_box.generic.y := y + 10;
  Inc(y, 10);
  s_armor_box.generic.name := 'allow armor';
  s_armor_box.generic.callback := DMFlagCallback;
  s_armor_box.itemnames := @yes_no_names;
  s_armor_box.curvalue := Integer((dmflags and DF_NO_ARMOR) = 0);

  s_spawn_farthest_box.generic.type_ := MTYPE_SPINCONTROL;
  s_spawn_farthest_box.generic.x := 0;
  s_spawn_farthest_box.generic.y := y + 10;
  Inc(y, 10);
  s_spawn_farthest_box.generic.name := 'spawn farthest';
  s_spawn_farthest_box.generic.callback := DMFlagCallback;
  s_spawn_farthest_box.itemnames := @yes_no_names;
  s_spawn_farthest_box.curvalue := Integer((dmflags and DF_SPAWN_FARTHEST) <> 0);

  s_samelevel_box.generic.type_ := MTYPE_SPINCONTROL;
  s_samelevel_box.generic.x := 0;
  s_samelevel_box.generic.y := y + 10;
  Inc(y, 10);
  s_samelevel_box.generic.name := 'same map';
  s_samelevel_box.generic.callback := DMFlagCallback;
  s_samelevel_box.itemnames := @yes_no_names;
  s_samelevel_box.curvalue := Integer((dmflags and DF_SAME_LEVEL) <> 0);

  s_force_respawn_box.generic.type_ := MTYPE_SPINCONTROL;
  s_force_respawn_box.generic.x := 0;
  s_force_respawn_box.generic.y := y + 10;
  Inc(y, 10);
  s_force_respawn_box.generic.name := 'force respawn';
  s_force_respawn_box.generic.callback := DMFlagCallback;
  s_force_respawn_box.itemnames := @yes_no_names;
  s_force_respawn_box.curvalue := Integer((dmflags and DF_FORCE_RESPAWN) <> 0);

  s_teamplay_box.generic.type_ := MTYPE_SPINCONTROL;
  s_teamplay_box.generic.x := 0;
  s_teamplay_box.generic.y := y + 10;
  Inc(y, 10);
  s_teamplay_box.generic.name := 'teamplay';
  s_teamplay_box.generic.callback := DMFlagCallback;
  s_teamplay_box.itemnames := @teamplay_names;

  s_allow_exit_box.generic.type_ := MTYPE_SPINCONTROL;
  s_allow_exit_box.generic.x := 0;
  s_allow_exit_box.generic.y := y + 10;
  Inc(y, 10);
  s_allow_exit_box.generic.name := 'allow exit';
  s_allow_exit_box.generic.callback := DMFlagCallback;
  s_allow_exit_box.itemnames := @yes_no_names;
  s_allow_exit_box.curvalue := Integer((dmflags and DF_ALLOW_EXIT) <> 0);

  s_infinite_ammo_box.generic.type_ := MTYPE_SPINCONTROL;
  s_infinite_ammo_box.generic.x := 0;
  s_infinite_ammo_box.generic.y := y + 10;
  Inc(y, 10);
  s_infinite_ammo_box.generic.name := 'infinite ammo';
  s_infinite_ammo_box.generic.callback := DMFlagCallback;
  s_infinite_ammo_box.itemnames := @yes_no_names;
  s_infinite_ammo_box.curvalue := Integer((dmflags and DF_INFINITE_AMMO) <> 0);

  s_fixed_fov_box.generic.type_ := MTYPE_SPINCONTROL;
  s_fixed_fov_box.generic.x := 0;
  s_fixed_fov_box.generic.y := y + 10;
  Inc(y, 10);
  s_fixed_fov_box.generic.name := 'fixed FOV';
  s_fixed_fov_box.generic.callback := DMFlagCallback;
  s_fixed_fov_box.itemnames := @yes_no_names;
  s_fixed_fov_box.curvalue := Integer((dmflags and DF_FIXED_FOV) <> 0);

  s_quad_drop_box.generic.type_ := MTYPE_SPINCONTROL;
  s_quad_drop_box.generic.x := 0;
  s_quad_drop_box.generic.y := y + 10;
  Inc(y, 10);
  s_quad_drop_box.generic.name := 'quad drop';
  s_quad_drop_box.generic.callback := DMFlagCallback;
  s_quad_drop_box.itemnames := @yes_no_names;
  s_quad_drop_box.curvalue := Integer((dmflags and DF_QUAD_DROP) <> 0);

  s_friendlyfire_box.generic.type_ := MTYPE_SPINCONTROL;
  s_friendlyfire_box.generic.x := 0;
  s_friendlyfire_box.generic.y := y + 10;
  Inc(y, 10);
  s_friendlyfire_box.generic.name := 'friendly fire';
  s_friendlyfire_box.generic.callback := DMFlagCallback;
  s_friendlyfire_box.itemnames := @yes_no_names;
  s_friendlyfire_box.curvalue := Integer((dmflags and DF_NO_FRIENDLY_FIRE) = 0);

  //======
  //ROGUE
  if (Developer_searchpath(2) = 2) then
  begin
    s_no_mines_box.generic.type_ := MTYPE_SPINCONTROL;
    s_no_mines_box.generic.x := 0;
    s_no_mines_box.generic.y := y + 10;
    Inc(y, 10);
    s_no_mines_box.generic.name := 'remove mines';
    s_no_mines_box.generic.callback := DMFlagCallback;
    s_no_mines_box.itemnames := @yes_no_names;
    s_no_mines_box.curvalue := Integer((dmflags and DF_NO_MINES) <> 0);

    s_no_nukes_box.generic.type_ := MTYPE_SPINCONTROL;
    s_no_nukes_box.generic.x := 0;
    s_no_nukes_box.generic.y := y + 10;
    Inc(y, 10);
    s_no_nukes_box.generic.name := 'remove nukes';
    s_no_nukes_box.generic.callback := DMFlagCallback;
    s_no_nukes_box.itemnames := @yes_no_names;
    s_no_nukes_box.curvalue := Integer((dmflags and DF_NO_NUKES) <> 0);

    s_stack_double_box.generic.type_ := MTYPE_SPINCONTROL;
    s_stack_double_box.generic.x := 0;
    s_stack_double_box.generic.y := y + 10;
    Inc(y, 10);
    s_stack_double_box.generic.name := '2x/4x stacking off';
    s_stack_double_box.generic.callback := DMFlagCallback;
    s_stack_double_box.itemnames := @yes_no_names;
    s_stack_double_box.curvalue := Integer((dmflags and DF_NO_STACK_DOUBLE) <> 0);

    s_no_spheres_box.generic.type_ := MTYPE_SPINCONTROL;
    s_no_spheres_box.generic.x := 0;
    s_no_spheres_box.generic.y := y + 10;
    Inc(y, 10);
    s_no_spheres_box.generic.name := 'remove spheres';
    s_no_spheres_box.generic.callback := DMFlagCallback;
    s_no_spheres_box.itemnames := @yes_no_names;
    s_no_spheres_box.curvalue := Integer((dmflags and DF_NO_SPHERES) <> 0);

  end;
  //ROGUE
  //======

  Menu_AddItem(@s_dmoptions_menu, @s_falls_box);
  Menu_AddItem(@s_dmoptions_menu, @s_weapons_stay_box);
  Menu_AddItem(@s_dmoptions_menu, @s_instant_powerups_box);
  Menu_AddItem(@s_dmoptions_menu, @s_powerups_box);
  Menu_AddItem(@s_dmoptions_menu, @s_health_box);
  Menu_AddItem(@s_dmoptions_menu, @s_armor_box);
  Menu_AddItem(@s_dmoptions_menu, @s_spawn_farthest_box);
  Menu_AddItem(@s_dmoptions_menu, @s_samelevel_box);
  Menu_AddItem(@s_dmoptions_menu, @s_force_respawn_box);
  Menu_AddItem(@s_dmoptions_menu, @s_teamplay_box);
  Menu_AddItem(@s_dmoptions_menu, @s_allow_exit_box);
  Menu_AddItem(@s_dmoptions_menu, @s_infinite_ammo_box);
  Menu_AddItem(@s_dmoptions_menu, @s_fixed_fov_box);
  Menu_AddItem(@s_dmoptions_menu, @s_quad_drop_box);
  Menu_AddItem(@s_dmoptions_menu, @s_friendlyfire_box);

  //====
  //ROGUE
  if (Developer_searchpath(2) = 2) then
  begin
    Menu_AddItem(@s_dmoptions_menu, @s_no_mines_box);
    Menu_AddItem(@s_dmoptions_menu, @s_no_nukes_box);
    Menu_AddItem(@s_dmoptions_menu, @s_stack_double_box);
    Menu_AddItem(@s_dmoptions_menu, @s_no_spheres_box);
  end;
  //ROGUE
  //====

  Menu_Center(@s_dmoptions_menu);

  // set the original dmflags statusbar
  DMFlagCallback(nil);
  Menu_SetStatusBar(@s_dmoptions_menu, dmoptions_statusbar);
end;

procedure DMOptions_MenuDraw;
begin
  Menu_Draw(@s_dmoptions_menu);
end;

function DMOptions_MenuKey(Key: Integer): PChar;
begin
  Result := Default_MenuKey(@s_dmoptions_menu, key);
end;

procedure M_Menu_DMOptions_f;
begin
  DMOptions_MenuInit();
  M_PushMenu(@DMOptions_MenuDraw, @DMOptions_MenuKey);
end;

{
=======================================

DOWNLOADOPTIONS BOOK MENU

=======================================
}
// all static
var
  s_downloadoptions_menu: menuframework_s;

  s_download_title: menuseparator_s;
  s_allow_download_box, s_allow_download_maps_box,
    s_allow_download_models_box, s_allow_download_players_box,
    s_allow_download_sounds_box: MenuList_s;

procedure DownloadCallback(Self: Pointer); // static
var
  f: MenuList_p;
begin
  f := menulist_p(self);

  if (f = @s_allow_download_box) then
    Cvar_SetValue('allow_download', f^.curvalue)
  else if (f = @s_allow_download_maps_box) then
    Cvar_SetValue('allow_download_maps', f^.curvalue)
  else if (f = @s_allow_download_models_box) then
    Cvar_SetValue('allow_download_models', f^.curvalue)
  else if (f = @s_allow_download_players_box) then
    Cvar_SetValue('allow_download_players', f^.curvalue)
  else if (f = @s_allow_download_sounds_box) then
    Cvar_SetValue('allow_download_sounds', f^.curvalue);
end;

procedure DownloadOptions_MenuInit;
const
  yes_no_names: array[0..2] of PChar = ('no', 'yes', nil);
var
  y: Integer;
begin
  y := 0;
  s_downloadoptions_menu.x := trunc(viddef.width * 0.50);
  s_downloadoptions_menu.nitems := 0;

  s_download_title.generic.type_ := MTYPE_SEPARATOR;
  s_download_title.generic.name := 'Download Options';
  s_download_title.generic.x := 48;
  s_download_title.generic.y := y;

  s_allow_download_box.generic.type_ := MTYPE_SPINCONTROL;
  s_allow_download_box.generic.x := 0;
  s_allow_download_box.generic.y := y + 20;
  Inc(y, 20);
  s_allow_download_box.generic.name := 'allow downloading';
  s_allow_download_box.generic.callback := DownloadCallback;
  s_allow_download_box.itemnames := @yes_no_names;
  s_allow_download_box.curvalue := Integer(Cvar_VariableValue('allow_download') <> 0);

  s_allow_download_maps_box.generic.type_ := MTYPE_SPINCONTROL;
  s_allow_download_maps_box.generic.x := 0;
  s_allow_download_maps_box.generic.y := y + 20;
  Inc(y, 20);
  s_allow_download_maps_box.generic.name := 'maps';
  s_allow_download_maps_box.generic.callback := DownloadCallback;
  s_allow_download_maps_box.itemnames := @yes_no_names;
  s_allow_download_maps_box.curvalue := Integer(Cvar_VariableValue('allow_download_maps') <> 0);

  s_allow_download_players_box.generic.type_ := MTYPE_SPINCONTROL;
  s_allow_download_players_box.generic.x := 0;
  s_allow_download_players_box.generic.y := y + 10;
  Inc(y, 10);
  s_allow_download_players_box.generic.name := 'player models/skins';
  s_allow_download_players_box.generic.callback := DownloadCallback;
  s_allow_download_players_box.itemnames := @yes_no_names;
  s_allow_download_players_box.curvalue := Integer(Cvar_VariableValue('allow_download_players') <> 0);

  s_allow_download_models_box.generic.type_ := MTYPE_SPINCONTROL;
  s_allow_download_models_box.generic.x := 0;
  s_allow_download_models_box.generic.y := y + 10;
  Inc(y, 10);
  s_allow_download_models_box.generic.name := 'models';
  s_allow_download_models_box.generic.callback := DownloadCallback;
  s_allow_download_models_box.itemnames := @yes_no_names;
  s_allow_download_models_box.curvalue := Integer(Cvar_VariableValue('allow_download_models') <> 0);

  s_allow_download_sounds_box.generic.type_ := MTYPE_SPINCONTROL;
  s_allow_download_sounds_box.generic.x := 0;
  s_allow_download_sounds_box.generic.y := y + 10;
  Inc(y, 10);
  s_allow_download_sounds_box.generic.name := 'sounds';
  s_allow_download_sounds_box.generic.callback := DownloadCallback;
  s_allow_download_sounds_box.itemnames := @yes_no_names;
  s_allow_download_sounds_box.curvalue := Integer(Cvar_VariableValue('allow_download_sounds') <> 0);

  Menu_AddItem(@s_downloadoptions_menu, @s_download_title);
  Menu_AddItem(@s_downloadoptions_menu, @s_allow_download_box);
  Menu_AddItem(@s_downloadoptions_menu, @s_allow_download_maps_box);
  Menu_AddItem(@s_downloadoptions_menu, @s_allow_download_players_box);
  Menu_AddItem(@s_downloadoptions_menu, @s_allow_download_models_box);
  Menu_AddItem(@s_downloadoptions_menu, @s_allow_download_sounds_box);

  Menu_Center(@s_downloadoptions_menu);

  // skip over title
  if (s_downloadoptions_menu.cursor = 0) then
    s_downloadoptions_menu.cursor := 1;
end;

procedure DownloadOptions_MenuDraw;
begin
  Menu_Draw(@s_downloadoptions_menu);
end;

function DownloadOptions_MenuKey(Key: Integer): PChar;
begin
  Result := Default_MenuKey(@s_downloadoptions_menu, key);
end;

procedure M_Menu_DownloadOptions_f;
begin
  DownloadOptions_MenuInit();
  M_PushMenu(@DownloadOptions_MenuDraw, @DownloadOptions_MenuKey);
end;
{
=======================================

ADDRESS BOOK MENU

=======================================
}
const
  NUM_ADDRESSBOOK_ENTRIES = 9;

  // static vars
var
  s_addressbook_menu: menuframework_s;
  s_addressbook_fields: array[0..NUM_ADDRESSBOOK_ENTRIES - 1] of MenuField_s;

procedure AddressBook_MenuInit;
var
  i: Integer;
  Adr: CVar_p;
  Buffer: array[0..19] of Char;
begin
  s_addressbook_menu.x := viddef.Width div 2 - 142;
  s_addressbook_menu.y := viddef.Height div 2 - 58;
  s_addressbook_menu.nitems := 0;

  for i := 0 to NUM_ADDRESSBOOK_ENTRIES - 1 do
  begin
    Com_sprintf(buffer, sizeof(buffer), 'adr%d', [i]);

    adr := Cvar_Get(buffer, '', CVAR_ARCHIVE);

    s_addressbook_fields[i].generic.type_ := MTYPE_FIELD;
    s_addressbook_fields[i].generic.name := nil;
    s_addressbook_fields[i].generic.callback := nil;
    s_addressbook_fields[i].generic.x := 0;
    s_addressbook_fields[i].generic.y := i * 18 + 0;
    s_addressbook_fields[i].generic.localdata[0] := i;
    s_addressbook_fields[i].cursor := 0;
    s_addressbook_fields[i].length := 60;
    s_addressbook_fields[i].visible_length := 30;

    strcpy(s_addressbook_fields[i].buffer, adr^.string_);

    Menu_AddItem(@s_addressbook_menu, @s_addressbook_fields[i]);
  end;
end;

function AddressBook_MenuKey(Key: Integer): PChar;
var
  index: Integer;
  Buffer: array[0..19] of Char;
begin
  if key = K_ESCAPE then
  begin
    for index := 0 to NUM_ADDRESSBOOK_ENTRIES - 1 do
    begin
      Com_sprintf(buffer, sizeof(buffer), 'adr%d', [index]);
      Cvar_Set(buffer, s_addressbook_fields[index].buffer);
    end;
  end;
  Result := Default_MenuKey(@s_addressbook_menu, key);
end;

procedure AddressBook_MenuDraw;
begin
  M_Banner('m_banner_addressbook');
  Menu_Draw(@s_addressbook_menu);
end;

procedure M_Menu_AddressBook_f;
begin
  AddressBook_MenuInit();
  M_PushMenu(@AddressBook_MenuDraw, @AddressBook_MenuKey);
end;

{
=======================================

PLAYER CONFIG MENU

=======================================
}
// Static menu vars
var
  s_player_config_menu: menuframework_s;
  s_player_name_field: menufield_s;
  s_player_model_box, s_player_skin_box, s_player_handedness_box,
    s_player_rate_box: MenuList_s;
  s_player_skin_title, s_player_model_title, s_player_hand_title,
    s_player_rate_title: menuseparator_s;
  s_player_download_action: menuaction_s;

var
  // Also static
  s_pmi: array[0..MAX_PLAYERMODELS - 1] of playermodelinfo_s;
  s_pmnames: array[0..MAX_PLAYERMODELS] of PChar;
  s_numplayermodels: Integer;

const
  rate_tbl: array[0..4] of Integer =
  (2500, 3200, 5000, 10000, 25000);
  rate_names: array[0..6] of PChar =
  ('28.8 Modem', '33.6 Modem', 'Single ISDN',
    'Dual ISDN/Cable', 'T1/LAN', 'User defined', nil);

procedure DownloadOptionsFunc(Self: Pointer);
begin
  M_Menu_DownloadOptions_f();
end;

procedure HandednessCallback(Self: Pointer); // static
begin
  Cvar_SetValue('hand', s_player_handedness_box.curvalue);
end;

procedure RateCallback(Self: Pointer);  // static
begin
  // if (s_player_rate_box.curvalue <> sizeof(rate_tbl) / sizeof(*rate_tbl) - 1)
  if s_player_rate_box.curvalue <> length(rate_tbl) then
    Cvar_SetValue('rate', rate_tbl[s_player_rate_box.curvalue]);
end;

procedure ModelCallback(Self: Pointer); // static
begin
  s_player_skin_box.itemnames := s_pmi[s_player_model_box.curvalue].skindisplaynames;
  s_player_skin_box.curvalue := 0;
end;

procedure FreeFileList(List: PPCharArray; n: Integer); // static
var
  i: Integer;
begin
  for i := 0 to n - 1 do
  begin
    if list[i] <> nil then
    begin
      StrDispose(list[i]);
      list[i] := nil;
    end;
  end;
  FreeMem(list);
end;

function IconOfSkinExists(Skin: PChar; PCXFiles: PPCharArray; npcxfiles: Integer):
  QBoolean;
var
  i, a, b: Integer;
  scratch: array[0..1024 - 1] of Char;
  c: PChar;
begin
  strcpy(scratch, skin);
  strrchr(scratch, Byte('.'))^ := #0;
  strcat(scratch, '_i.pcx');

  for i := 0 to npcxfiles - 1 do
  begin
    if (strcmp(pcxfiles[i], scratch) = 0) then
    begin
      Result := True;
      exit;
    end;
    Result := False;
  end;
end;

function PlayerConfig_ScanDirectories: QBoolean; // static
var
  findname, scratch: array[0..1023] of Char;
  ndirs, npms, i, k, s, npcxfiles, nskins: Integer;
  dirnames,
    pcxnames,
    skinnames: PPCharArray;
  path, a, b, c: PChar;
begin
  ndirs := 0;
  npms := 0;
  path := nil;

  s_numplayermodels := 0;

  {
  ** get a list of directories
  }
  repeat
    path := FS_NextPath(path);
    Com_sprintf(findname, sizeof(findname), '%s/players/*.*', [path]);

    dirnames := FS_ListFiles(findname, ndirs, SFF_SUBDIR, 0);
    if (dirnames <> nil) then
      break;
  until (path = nil);

  if dirnames = nil then
  begin
    Result := False;
    exit;
  end;

  {
  ** go through the subdirectories
  }
  npms := ndirs;
  if (npms > MAX_PLAYERMODELS) then
    npms := MAX_PLAYERMODELS;

  for i := 0 to npms - 1 do
  begin
    nskins := 0;

    if dirnames[i] = nil then
      continue;

    // verify the existence of tris.md2
    strcpy(scratch, dirnames[i]);
    strcat(scratch, '/tris.md2');
    if Sys_FindFirst(scratch, 0, SFF_SUBDIR or SFF_HIDDEN or SFF_SYSTEM) = nil then
    begin
      StrDispose(dirnames[i]);
      dirnames[i] := nil;
      Sys_FindClose();
      continue;
    end;
    Sys_FindClose();

    // verify the existence of at least one pcx skin
    strcpy(scratch, dirnames[i]);
    strcat(scratch, '/*.pcx');
    pcxnames := FS_ListFiles(scratch, npcxfiles, 0, SFF_SUBDIR or SFF_HIDDEN or SFF_SYSTEM);

    if pcxnames = nil then
    begin
      StrDispose(dirnames[i]);
      dirnames[i] := nil;
      continue;
    end;

    // count valid skins, which consist of a skin with a matching '_i' icon
    for k := 0 to npcxfiles - 2 do
    begin
      if strstr('_i.pcx', pcxnames[k]) = nil then
      begin
        if (IconOfSkinExists(pcxnames[k], pcxnames, npcxfiles - 1)) then
          Inc(nskins);
      end;
    end;
    if nskins = 0 then
      continue;

    skinnames := AllocMem(SizeOf(pchar) * (nskins + 1));
    FillChar(skinnames^, SizeOf(pchar) * (nskins + 1), 0);

    // copy the valid skins
    s := 0;
    for k := 0 to npcxfiles - 2 do
    begin
      if (strstr(pcxnames[k], '_i.pcx') = nil) then
      begin                             // was ( !strstr( pcxnames[k], '_i.pcx' ) )
        if (IconOfSkinExists(pcxnames[k], pcxnames, npcxfiles - 1)) then
        begin
          a := strrchr(pcxnames[k], ord('/'));
          b := strrchr(pcxnames[k], ord('\')); //was '\\'
          if (a > b) then
            c := a
          else
            c := b;

          strcpy(scratch, c + 1);

          if (strrchr(scratch, ord('.')) <> nil) then
            strrchr(scratch, ord('.'))^ := #0;

          skinnames[s] := strnew(scratch);
          Inc(s);
        end;
      end;
    end;

    // at this point we have a valid player model
    s_pmi[s_numplayermodels].nskins := nskins;
    s_pmi[s_numplayermodels].skindisplaynames := skinnames;

    // make short name for the model
    a := strrchr(dirnames[i], ord('/'));
    b := strrchr(dirnames[i], ord('\'));

    if (a > b) then
      c := a
    else
      c := b;

    strncpy(s_pmi[s_numplayermodels].displayname, c + 1, MAX_DISPLAYNAME - 1);
    strcpy(s_pmi[s_numplayermodels].directory, c + 1);

    FreeFileList(pcxnames, npcxfiles);
    Inc(s_numplayermodels);
  end;

  if Dirnames <> nil then
    //if length(dirnames) > 0 then
    FreeFileList(dirnames, ndirs);
end;

function pmicmpfnc(const _a, _b: Pointer): Integer; // static
var
  a, b: PlayerModelInfo_p;
begin
  a := playermodelinfo_p(_a);
  b := playermodelinfo_p(_b);

  {
  ** sort by male, female, then alphabetical
  }
  Result := 0;
  if a^.directory = 'male' then
    Result := -1
  else if b^.directory = 'male' then
    Result := 1;

  if a^.directory = 'female' then
    Result := -1
  else if b^.directory = 'female' then
    Result := 1;

  if Result = 0 then
    Result := CompareStr(a^.directory, b^.directory);
end;

function PlayerConfig_MenuInit: QBoolean;
var
  CurrentDirectory, CurrentSkin: array[0..1024 - 1] of Char;
  i, p, j, CurrentDirectoryIndex, CurrentSkinIndex: Integer;
  hand: cvar_p;
const
  handedness: array[0..3] of PChar =
  ('right', 'left', 'middle', nil);
begin
  i := 0;

  currentdirectoryindex := 0;
  currentskinindex := 0;

  hand := Cvar_Get('hand', '0', CVAR_USERINFO or CVAR_ARCHIVE);

  PlayerConfig_ScanDirectories();

  Result := False;
  if (s_numplayermodels = 0) then
    exit;

  if (hand^.value < 0) or (hand^.value > 2) then
    Cvar_SetValue('hand', 0);

  strcpy(currentdirectory, skin^.string_);

  if (strchr(currentdirectory, ord('/')) <> nil) then
  begin
    strcpy(currentskin, strchr(currentdirectory, ord('/')) + 1);
    strchr(currentdirectory, ord('/'))^ := #0;
  end
  else if (strchr(currentdirectory, ord('\')) <> nil) then
  begin
    strcpy(currentskin, strchr(currentdirectory, ord('\')) + 1);
    strchr(currentdirectory, ord('\'))^ := #0;
  end
  else
  begin
    strcpy(currentdirectory, 'male');
    strcpy(currentskin, 'grunt');
  end;

  qsort(@s_pmi, s_numplayermodels, sizeof(s_pmi[0]), pmicmpfnc);

  FillChar(s_pmnames, sizeof(s_pmnames), 0);
  for i := 0 to s_numplayermodels - 1 do
  begin
    s_pmnames[i] := s_pmi[i].displayname;
    if (Q_stricmp(s_pmi[i].directory, currentdirectory) = 0) then
    begin
      currentdirectoryindex := i;
      for j := 0 to s_pmi[i].nskins - 1 do
      begin
        if (Q_stricmp(s_pmi[i].skindisplaynames[j], currentskin) = 0) then
        begin
          currentskinindex := j;
          break;
        end;
      end;
    end;
  end;

  s_player_config_menu.x := viddef.Width div 2 - 95;
  s_player_config_menu.y := viddef.Height div 2 - 97;
  s_player_config_menu.nitems := 0;

  s_player_name_field.generic.type_ := MTYPE_FIELD;
  s_player_name_field.generic.name := 'name';
  s_player_name_field.generic.callback := nil;
  s_player_name_field.generic.x := 0;
  s_player_name_field.generic.y := 0;
  s_player_name_field.length := 20;
  s_player_name_field.visible_length := 20;
  strcpy(s_player_name_field.buffer, Name^.string_);
  s_player_name_field.cursor := strlen(Name^.string_);

  s_player_model_title.generic.type_ := MTYPE_SEPARATOR;
  s_player_model_title.generic.name := 'model';
  s_player_model_title.generic.x := -8;
  s_player_model_title.generic.y := 60;

  s_player_model_box.generic.type_ := MTYPE_SPINCONTROL;
  s_player_model_box.generic.x := -56;
  s_player_model_box.generic.y := 70;
  s_player_model_box.generic.callback := ModelCallback;
  s_player_model_box.generic.cursor_offset := -48;
  s_player_model_box.curvalue := currentdirectoryindex;
  s_player_model_box.itemnames := @s_pmnames;

  s_player_skin_title.generic.type_ := MTYPE_SEPARATOR;
  s_player_skin_title.generic.name := 'skin';
  s_player_skin_title.generic.x := -16;
  s_player_skin_title.generic.y := 84;

  s_player_skin_box.generic.type_ := MTYPE_SPINCONTROL;
  s_player_skin_box.generic.x := -56;
  s_player_skin_box.generic.y := 94;
  s_player_skin_box.generic.name := nil;
  s_player_skin_box.generic.callback := nil;
  s_player_skin_box.generic.cursor_offset := -48;
  s_player_skin_box.curvalue := currentskinindex;
  s_player_skin_box.itemnames := s_pmi[currentdirectoryindex].skindisplaynames;

  s_player_hand_title.generic.type_ := MTYPE_SEPARATOR;
  s_player_hand_title.generic.name := 'handedness';
  s_player_hand_title.generic.x := 32;
  s_player_hand_title.generic.y := 108;

  s_player_handedness_box.generic.type_ := MTYPE_SPINCONTROL;
  s_player_handedness_box.generic.x := -56;
  s_player_handedness_box.generic.y := 118;
  s_player_handedness_box.generic.name := nil;
  s_player_handedness_box.generic.cursor_offset := -48;
  s_player_handedness_box.generic.callback := HandednessCallback;
  s_player_handedness_box.curvalue := Integer(Cvar_VariableValue('hand') <> 0);
  s_player_handedness_box.itemnames := @handedness;

  // Was for (i := 0; i < sizeof(rate_tbl) / sizeof(*rate_tbl) - 1; i++)
  i := 0;
  for j := 0 to length(Rate_tbl) - 1 do
    if (Cvar_VariableValue('rate') = rate_tbl[j]) then
    begin
      i := j;
      break;
    end;

  s_player_rate_title.generic.type_ := MTYPE_SEPARATOR;
  s_player_rate_title.generic.name := 'connect speed';
  s_player_rate_title.generic.x := 56;
  s_player_rate_title.generic.y := 156;

  s_player_rate_box.generic.type_ := MTYPE_SPINCONTROL;
  s_player_rate_box.generic.x := -56;
  s_player_rate_box.generic.y := 166;
  s_player_rate_box.generic.name := nil;
  s_player_rate_box.generic.cursor_offset := -48;
  s_player_rate_box.generic.callback := RateCallback;
  s_player_rate_box.curvalue := i;
  s_player_rate_box.itemnames := @rate_names;

  s_player_download_action.generic.type_ := MTYPE_ACTION;
  s_player_download_action.generic.name := 'download options';
  s_player_download_action.generic.flags := QMF_LEFT_JUSTIFY;
  s_player_download_action.generic.x := -24;
  s_player_download_action.generic.y := 186;
  s_player_download_action.generic.statusbar := nil;
  s_player_download_action.generic.callback := DownloadOptionsFunc;

  Menu_AddItem(@s_player_config_menu, @s_player_name_field);
  Menu_AddItem(@s_player_config_menu, @s_player_model_title);
  Menu_AddItem(@s_player_config_menu, @s_player_model_box);
  if s_player_skin_box.itemnames <> nil then
  begin
    Menu_AddItem(@s_player_config_menu, @s_player_skin_title);
    Menu_AddItem(@s_player_config_menu, @s_player_skin_box);
  end;
  Menu_AddItem(@s_player_config_menu, @s_player_hand_title);
  Menu_AddItem(@s_player_config_menu, @s_player_handedness_box);
  Menu_AddItem(@s_player_config_menu, @s_player_rate_title);
  Menu_AddItem(@s_player_config_menu, @s_player_rate_box);
  Menu_AddItem(@s_player_config_menu, @s_player_download_action);

  result := True;
end;

var
  yaw: Integer;                         // was static inside proc

procedure PlayerConfig_MenuDraw;
var
  refdef: refdef_t;
  scratch: array[0..MAX_QPATH - 1] of Char;
  maxframe: Integer;
  entity: entity_t;
begin
  FillChar(refdef, sizeof(refdef), 0);

  refdef.x := viddef.Width div 2;
  refdef.y := viddef.Height div 2 - 72;
  refdef.width := 144;
  refdef.height := 168;
  refdef.fov_x := 40;
  refdef.fov_y := CalcFov(refdef.fov_x, refdef.width, refdef.height);
  refdef.time := cls.realtime * 0.001;

  if s_pmi[s_player_model_box.curvalue].skindisplaynames <> nil then
  begin
    maxframe := 29;
    FillChar(entity, sizeof(entity), 0);

    Com_sprintf(scratch, sizeof(scratch), 'players/%s/tris.md2',
      [s_pmi[s_player_model_box.curvalue].directory]);
    entity.model := re.RegisterModel(scratch);
    Com_sprintf(scratch, sizeof(scratch), 'players/%s/%s.pcx',
      [s_pmi[s_player_model_box.curvalue].directory,
      s_pmi[s_player_model_box.curvalue].skindisplaynames[s_player_skin_box.curvalue]]);
    entity.skin := re.RegisterSkin(scratch);
    entity.flags := RF_FULLBRIGHT;
    entity.origin[0] := 80;
    entity.origin[1] := 0;
    entity.origin[2] := 0;
    VectorCopy(vec3_t(entity.origin), vec3_t(entity.oldorigin));
    entity.frame := 0;
    entity.oldframe := 0;
    entity.backlerp := 0.0;
    entity.angles[1] := yaw;
    Inc(yaw, 2);
    if yaw > 360 then
      Dec(yaw, 360);

    refdef.areabits := nil;
    refdef.num_entities := 1;
    refdef.entities := @entity;
    refdef.lightstyles := nil;
    refdef.rdflags := RDF_NOWORLDMODEL;

    Menu_Draw(@s_player_config_menu);

    M_DrawTextBox(Trunc((refdef.x) * (320 / viddef.width)) - 8, Trunc((viddef.Height div 2) *
      (240 / viddef.height)) - 77, refdef.Width div 8, refdef.Height div 8);
    Inc(refdef.height, 4);

    re.RenderFrame(@refdef);

    Com_sprintf(scratch, sizeof(scratch), '/players/%s/%s_i.pcx', [
      s_pmi[s_player_model_box.curvalue].directory,
        s_pmi[s_player_model_box.curvalue].skindisplaynames[s_player_skin_box.curvalue]]);
    re.DrawPic(s_player_config_menu.x - 40, refdef.y, scratch);
  end;
end;

function PlayerConfig_MenuKey(key: Integer): PChar;
var
  i, j: Integer;
  scratch: array[0..1023] of Char;
begin
  if (key = K_ESCAPE) then
  begin
    Cvar_Set('name', s_player_name_field.buffer);

    Com_sprintf(scratch, sizeof(scratch), '%s/%s', [
      s_pmi[s_player_model_box.curvalue].directory,
        s_pmi[s_player_model_box.curvalue].skindisplaynames[s_player_skin_box.curvalue]]);

    Cvar_Set('skin', scratch);

    for i := 0 to s_numplayermodels - 1 do
    begin
      for j := 0 to s_pmi[i].nskins - 1 do
      begin
        if s_pmi[i].skindisplaynames[j] <> nil then
          StrDispose(s_pmi[i].skindisplaynames[j]);
        s_pmi[i].skindisplaynames[j] := nil;
      end;
      FreeMem(s_pmi[i].skindisplaynames);
      s_pmi[i].skindisplaynames := nil;
      s_pmi[i].nskins := 0;
    end;
  end;
  result := Default_MenuKey(@s_player_config_menu, key);
end;

procedure M_Menu_PlayerConfig_f;
begin
  if not PlayerConfig_MenuInit() then
  begin
    Menu_SetStatusBar(@s_multiplayer_menu, 'No valid player models found');
    exit;
  end;
  Menu_SetStatusBar(@s_multiplayer_menu, nil);
  M_PushMenu(@PlayerConfig_MenuDraw, @PlayerConfig_MenuKey);
end;

{
====================================

GALLERY MENU

====================================
}
{

procedure M_Menu_Gallery_f;
begin
  M_PushMenu(@Gallery_MenuDraw, @Gallery_MenuKey);
end;
}

{
====================================

QUIT MENU

====================================
}

function M_Quit_Key(key: Integer): PChar;
begin
  if key in [K_ESCAPE, ord('n'), ord('N')] then
    M_PopMenu
  else if key in [ord('y'), ord('Y')] then
  begin
    cls.key_dest := key_console;
    CL_Quit_f();
  end;

  Result := nil;
end;

procedure M_Quit_Draw;
var
  w, h: Integer;
begin
  re.DrawGetPicSize(@w, @h, 'quit');
  re.DrawPic((viddef.width - w) div 2, (viddef.height - h) div 2, 'quit');
end;

procedure M_Menu_Quit_f;
begin
  M_PushMenu(@M_Quit_Draw, @M_Quit_Key);
end;

//=======================================
{ Menu Subsystem }

{
=========
M_Init
=========
}

procedure M_Init;
begin
  Cmd_AddCommand('menu_main', M_Menu_Main_f);
  Cmd_AddCommand('menu_game', M_Menu_Game_f);
  Cmd_AddCommand('menu_loadgame', M_Menu_LoadGame_f);
  Cmd_AddCommand('menu_savegame', M_Menu_SaveGame_f);
  Cmd_AddCommand('menu_joinserver', M_Menu_JoinServer_f);
  Cmd_AddCommand('menu_addressbook', M_Menu_AddressBook_f);
  Cmd_AddCommand('menu_startserver', M_Menu_StartServer_f);
  Cmd_AddCommand('menu_dmoptions', M_Menu_DMOptions_f);
  Cmd_AddCommand('menu_playerconfig', M_Menu_PlayerConfig_f);
  Cmd_AddCommand('menu_downloadoptions', M_Menu_DownloadOptions_f);
  Cmd_AddCommand('menu_credits', M_Menu_Credits_f);
  Cmd_AddCommand('menu_multiplayer', M_Menu_Multiplayer_f);
  Cmd_AddCommand('menu_video', M_Menu_Video_f);
  Cmd_AddCommand('menu_options', M_Menu_Options_f);
  Cmd_AddCommand('menu_keys', M_Menu_Keys_f);
  Cmd_AddCommand('menu_quit', M_Menu_Quit_f);
end;

{
=========
M_Draw
=========
}

procedure M_Draw;
begin
  if (cls.key_dest <> key_menu) then
    exit;

  // repaint everything next frame
  SCR_DirtyScreen();

  // dim everything behind it down
  if (cl.cinematictime > 0) then
    re.DrawFill(0, 0, viddef.width, viddef.height, 0)
  else
    re.DrawFadeScreen();

  m_drawfunc();

  // delay playing the enter sound until after the
  // menu has been drawn, to aprocedure delay while
  // caching images
  if m_entersound then
  begin
    S_StartLocalSound(menu_in_sound);
    m_entersound := False;
  end;
end;

{
=========
M_Keydown
=========
}

procedure M_Keydown(Key: Integer);
var
  s: PChar;
begin
  if @m_keyfunc <> nil then
  begin
    s := m_keyfunc(Key);
    if s <> nil then
      S_StartLocalSound(s);
  end;
end;

end.
