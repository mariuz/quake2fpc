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


//70%
{$ALIGN 8}{$MINENUMSIZE 4}
{----------------------------------------------------------------------------}
{                                                                            }
{ File(s): ctf\p_menu.h, ctf\p_menu.c                                        }
{ Content:                                                                   }
{                                                                            }
{ Initial conversion by : dArkteMplaR (amreshr@hotmail.com)                  }
{ Initial conversion on : 17-Jan-2002                                        }
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
{ Updated on : 24-Feb-2002                                                   }
{ Updated by : Carl A Kenner (carl_kenner@hotmail.com)                       }
{                                                                            }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{----------------------------------------------------------------------------}
{ * TODO:  This file is incomplete                                           }
{ This is not a compiled file. It still has to be compiled and tested        }
{ Follow the //TODO: statements and correct                                  }
{----------------------------------------------------------------------------}
unit p_menu;

interface

uses Sysutils, g_local;

const
   PMENU_ALIGN_LEFT            = 0;
   PMENU_ALIGN_CENTER          = 1;
   PMENU_ALIGN_RIGHT           = 2;

type
//MOVED TO g_local
  pmenu_p = g_local.pmenu_p;

  pmenuhnd_p = g_local.pmenuhnd_p;
  pmenuhnd_s = g_local.pmenuhnd_s;
  pmenuhnd_t = g_local.pmenuhnd_t;
  pmenuhnd_at = g_local.pmenuhnd_at;
  pmenuhnd_a = g_local.pmenuhnd_a;
  TPMenuHnd = g_local.TPMenuHnd;
  PPMenuHnd = g_local.PPMenuHnd;
  TPMenuHndArray = g_local.TPMenuHndArray;
  PPMenuHndArray = g_local.PPMenuHndArray;

  SelectFunc_t = g_local.SelectFunc_t;

  ppmenu_s = g_local.pmenu_p;
  pmenu_s = g_local.pmenu_s;
  pmenu_t = g_local.pmenu_t;
  pmenu_at = g_local.pmenu_at;
  pmenu_a = g_local.pmenu_a;
  TPMenu = g_local.TPMenu;
  PPMenu = g_local.PPMenu;
  TPMenuArray = g_local.TPMenuArray;
  PPMenuArray = g_local.PPMenuArray;

function PMenu_Open(ent: edict_p; entries: pmenu_p; cur: integer; num: integer;
  arg: Pointer): pmenuhnd_p;
procedure PMenu_Close(ent: edict_p);
procedure PMenu_UpdateEntry(entry: pmenu_p; text: PChar; align: Integer;
  SelectFunc: SelectFunc_t);
procedure PMenu_Do_Update(ent: edict_p);
procedure PMenu_Update(ent: edict_p);
procedure PMenu_Next(ent: edict_p);
procedure PMenu_Prev(ent: edict_p);
procedure PMenu_Select(ent: edict_p);

implementation
Uses GameUnit;
// Note that the pmenu entries are duplicated
// this is so that a static set of pmenu entries can be used
// for multiple clients and changed without interference
// note that arg will be freed when the menu is closed, it must be allocated memory

function strdup(p: PChar): PChar;
begin
  GetMem(Result,strlen(p)+1);
  move(p^,Result^,strlen(p)+1);
end;

function PMenu_Open(ent: edict_p; entries: pmenu_p; cur: integer; num: integer;
  arg: Pointer): pmenuhnd_p;
var
  hnd                         : pmenuhnd_p;
  p                           : pmenu_p;
  i                           : integer;
begin
  if ent.Client = nil then
   begin
      Result := nil;
      exit;
   end;

   if (ent.client.menu = nil) then
   begin
      gi.dprintf('warning, ent already has a menu');
      PMenu_Close(ent);
   end;

   hnd := AllocMem(sizeof(pmenuhnd_p));

   hnd.arg := arg;
   hnd.entries := AllocMem(sizeof(pmenu_t) * num);

   hnd.entries := AllocMem(sizeof(pmenu_t) * num);
        move(entries^,hnd.entries^,sizeof(pmenu_t) * num);

// duplicate the strings since they may be from static memory
   for i := 0 to num do
          if pmenu_a(entries)[i].text<>nil then
            pmenu_a(hnd.entries)[i].text := strdup(pmenu_a(entries)[i].text);

   hnd.num := num;

   if (cur < 0) or Assigned(pmenu_a(entries)[cur].SelectFunc) then begin
      p := entries;
      for i := 0 to num do
      begin
         if (@p.SelectFunc=nil) then
            break;
         Inc(p);
      end;
   end else
      i := cur;

   if (i >= num) then
      hnd.cur := -1
   else
      hnd.cur := i;

   ent.client.showscores := true;
   ent.client.inmenu := true;
   ent.client.menu := hnd;

   PMenu_Do_Update(ent);
   gi.unicast(ent, true);

   Result := hnd;
end;

procedure PMenu_Close(ent: edict_p);
var
   i                           : integer;
   hnd                         : pmenuhnd_p;
begin
   if ent.Client.menu = nil then
      exit;

   hnd := ent.Client.menu;
   for i := 0 to hnd.num do
   begin
      if pmenu_a(hnd.entries)[i].text <> nil then
         dispose(pmenu_a(hnd.entries)[i].text);
   end;
   dispose(hnd.entries);
   if hnd.arg <> nil then
      dispose(hnd.arg);
   dispose(hnd);
   ent.client.menu := nil;
   ent.client.showscores := false;
end;

// only use on pmenu's that have been called with PMenu_Open

procedure PMenu_UpdateEntry(entry: pmenu_p; text: PChar; align: Integer;
   SelectFunc: SelectFunc_t);
begin
   if (entry.text<>nil) then
      Dispose(entry.text);
   entry.text := strdup(text);
   entry.align := align;
   entry.SelectFunc := SelectFunc;
end;

procedure PMenu_Do_Update(ent: edict_p);
var
   string_: array [0..1400] of char;
   //TODO: I think that the above should be a string
   i: integer;
   p: pmenu_p;
   x: integer;
   hnd: pmenuhnd_p;
   t: PChar;
   alt: qboolean;
begin
   alt := false;
   if (ent.client.menu = nil) then
   begin
      gi.dprintf('warning:  ent has no menu');
      exit;
   end;

   hnd := ent.client.menu;

   //TODO:
   strcopy(string_, 'xv 32 yv 8 picn inventory ');

   p := hnd.entries;
   for i := 0 to hnd.num do
   begin
      if (p.text=nil) then
         continue; // blank line
      t := p.text;
      if ( t = '*') then
      begin
         alt := true;
         Inc(t);
      end;
      //TODO:
      //sprintf(string + strlen(string), "yv %d ", 32 + i * 8);
//      if (p.align = PMENU_ALIGN_CENTER) then
//         x := 196/2 - length(t)*4 + 64
//      else if (p.align = PMENU_ALIGN_RIGHT) then
//         x := 64 + (196 - lenght(t)*8)
//      else
//         x := 64;

//      sprintf(string + strlen(string), "xv %d ",
//         x - ((hnd->cur == i) ? 8 : 0));

//      if (hnd.cur = i)
//         sprintf(string + strlen(string), "string2 \"\x0d%s\" ", t);
//      else if (alt)
//         sprintf(string + strlen(string), "string2 \"%s\" ", t);
//      else
//         sprintf(string + strlen(string), "string \"%s\" ", t);
      alt := false;
      Inc(p);
   end;
   gi.WriteByte (svc_layout);
   gi.WriteString (string_);
end;

procedure PMenu_Update(ent: edict_p);
begin
   if (ent.client.menu<>nil) then
   begin
      gi.dprintf('warning:  ent has no menu');
      exit;
   end;

   if (level.time - ent.client.menutime >= 1.0) then
   begin
      // been a second or more since last update, update now
      PMenu_Do_Update(ent);
      gi.unicast (ent, true);
      ent.client.menutime := level.time;
      ent.client.menudirty := false;
   end;
   ent.client.menutime := level.time + 0.2;
   ent.client.menudirty := true;
end;

procedure PMenu_Next(ent: edict_p);
var
   hnd                         : pmenuhnd_p;
   i                           : integer;
   p                           : pmenu_p;
begin
   if (ent.client.menu=nil) then
   begin
      gi.dprintf('warning:  ent has no menu\n');
      exit;
   end;

   hnd := ent.client.menu;

   if (hnd.cur < 0) then
      exit; // no selectable entries

   i := hnd.cur;
   p := @pmenu_a(hnd.entries)[hnd.cur];
   repeat
      Inc(i);
      Inc(p);
      if (i = hnd.num) then
      begin
         i := 0;
         p := hnd.entries;
      end;
      if (@p.SelectFunc<>nil) then
         break;
   until (i <> hnd.cur);

   hnd.cur := i;

   PMenu_Update(ent);
end;

procedure PMenu_Prev(ent: edict_p);
var
   hnd                         : pmenuhnd_p;
   i                           : integer;
   p                           : pmenu_p;
begin
   if (ent.client.menu = nil) then
   begin
      gi.dprintf('warning:  ent has no menu');
      exit
   end;

   hnd := ent.client.menu;

   if (hnd.cur < 0) then
      exit; // no selectable entries

   i := hnd.cur;
   p := @pmenu_a(hnd.entries)[hnd.cur];
   repeat
      if (i = 0) then
      begin
         i := hnd.num - 1;
         p := @pmenu_a(hnd.entries)[i];
      end else
      begin
         Dec(i);
         Dec(p);
      end;
      if (@p.SelectFunc <> nil) then
         break;
   until (i = hnd.cur);

   hnd.cur := i;

   PMenu_Update(ent);
end;

procedure PMenu_Select(ent: edict_p);
var
   hnd                         : pmenuhnd_p;
   p                           : pmenu_p;
begin
   if (ent.client.menu = nil) then
   begin
      gi.dprintf('warning:  ent has no menu');
      exit;
   end;

   hnd := ent.client.menu;

   if (hnd.cur < 0)
      then exit; // no selectable entries

   p := @pmenu_a(hnd.entries)[hnd.cur];
   if (@p.SelectFunc <> nil) then
      p.SelectFunc(ent, hnd);
end;


initialization
// Check the size of types defined in p_menu.h
  Assert(sizeof(pmenu_t)=12);
  Assert(sizeof(pmenuhnd_t)=16);
end.

);
var
   hnd                         : pmenuhnd_p;
   p                           : pmenu_p;
begin
   if (ent.client.menu = nil) then
   begin
      gi.dprintf('warning:  ent has no menu');
      exit;
   end;

   hnd := ent.client.menu;

   if (hnd.cur < 0)
      then exit; // no selectable entries

   p := hnd.entries + hnd.cur;
   if (@p.SelectFunc <> nil) then
      p.SelectFunc(ent, hnd);
end;

end.

