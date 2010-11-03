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
{ File(s): cl_inv.c                                                          }
{ Content: Quake2\ref_soft\ sound structures and constants                   }
{                                                                            }
{ Initial conversion by : Skaljac Bojan (Skaljac@Italy.Com)                  }
{ Initial conversion on : 17-Feb-2002                                        }
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
{ Updated on : 09-Jun-2002                                                              }
{ Updated by : Juha Hartikainen (juha@linearteam.org)                                                              }
{ - Finished conversion (now compiles)                                                                           }
{ - Fixed some conversion errors. }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{ 1. Some test of couple functions in this unit                              }
{----------------------------------------------------------------------------}
unit cl_inv;

interface

procedure CL_ParseInventory;
procedure Inv_DrawString(x, y: Integer; string_: PChar);
procedure CL_DrawInventory;

implementation

uses
  Common,
  q_shared,
  keys,
  client,
  {$IFDEF WIN32}
  vid_dll,
  {$ELSE}
  vid_so,
  {$ENDIF}
  cl_main,
  cl_scrn,
  net_chan,
  sysutils;

(*
================
CL_ParseInventory
================
*)

procedure CL_ParseInventory;
var
  i: Integer;
begin
  for i := 0 to MAX_ITEMS - 1 do
    cl.inventory[i] := MSG_ReadShort(net_message);
end;

(*
================
Inv_DrawString
================
*)

procedure Inv_DrawString(x, y: Integer; string_: PChar);
begin
  while (string_^ <> #0) do
  begin
    re.DrawChar(x, y, Byte(string_^));
    x := x + 8;
    Inc(string_);
  end;
end;

procedure SetStringHighBit(s: pchar);
begin
  while (s^ <> #0) do
  begin
    s^ := Char(Byte(s^) or 128);
    inc(s);
  end;
end;

(*
================
CL_DrawInventory
================
*)

const
  DISPLAY_ITEMS = 17;

procedure CL_DrawInventory;
var
  i, j: Integer;
  num, selected_num, item: Integer;
  index: array[0..MAX_ITEMS - 1] of Integer;
  String1: array[0..1024 - 1] of Char;
  x, y: Integer;
  binding: array[0..1024 - 1] of Char;
  bind: PChar;
  selected: Integer;
  top: Integer;
begin
  selected := cl.frame.playerstate.stats[STAT_SELECTED_ITEM];

  num := 0;
  selected_num := 0;
  for i := 0 to MAX_ITEMS - 1 do
  begin
    if (i = selected) then
      selected_num := num;
    if (cl.inventory[i] <> 0) then
    begin
      index[num] := i;
      Inc(num);
    end;
  end;

  // determine scroll point
  top := selected_num - DISPLAY_ITEMS div 2;
  if (num - top < DISPLAY_ITEMS) then
    top := num - DISPLAY_ITEMS;
  if (top < 0) then
    top := 0;

  x := (viddef.width - 256) div 2;
  y := (viddef.height - 240) div 2;

  // repaint everything next frame
  SCR_DirtyScreen();

  re.DrawPic(x, y + 8, 'inventory');

  y := y + 24;
  x := x + 24;
  Inv_DrawString(x, y, 'hotkey ### item');
  Inv_DrawString(x, y + 8, '------ --- ----');
  y := y + 16;
  //   for (i=top ; i<num && i < top+DISPLAY_ITEMS ; i++)
  i := top;
  while ((i < num) and (i < top + DISPLAY_ITEMS)) do
  begin
    item := index[i];
    // search for a binding
    Com_sprintf(binding, sizeof(binding), 'use %s', [cl.configstrings[CS_ITEMS + item]]);

    bind := '';
    for j := 0 to 255 do
      if (keybindings[j] <> nil) and (Q_stricmp(keybindings[j], binding) = 0) then
      begin
        bind := Key_KeynumToString(j);
        break;
      end;
    Com_sprintf(string1, sizeof(string1), '%6s %3i %s', [bind, cl.inventory[item],
      cl.configstrings[CS_ITEMS + item]]);
    if (item <> selected) then
      SetStringHighBit(string1)
    else                                // draw a blinky cursor by the selected item
    begin
      if (Trunc(cls.realtime * 10) and 1 <> 0) then
        re.DrawChar(x - 8, y, 15);
    end;
    Inv_DrawString(x, y, string1);
    y := y + 8;
    Inc(i);
  end;
end;

end.
