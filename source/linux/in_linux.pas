unit in_linux;

//Initial conversion by : Fabrizio Rossini ( FAB )
//
{ This File contains part of convertion of Quake2 source to ObjectPascal.    }
{ More information about this project can be found at:                       }
{ http://www.sulaco.co.za/quake2/                                            }


(*
Copyright (C) 1997-2001 Id Software, Inc.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  

See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

*)
(* in_null.c -- for systems without a mouse*)
{.include "../client/client.h"}
interface
uses Cvar,q_shared_add;

var
in_mouse: cvar_p; 
in_joystick: cvar_p;

procedure IN_Move(cmd: usercmd_p);

implementation
uses q_shared ;

procedure IN_Init(); 
begin
  in_mouse:= Cvar_Get('in_mouse', '1', CVAR_ARCHIVE);
  in_joystick:= Cvar_Get('in_joystick', '0', CVAR_ARCHIVE); 
end;


procedure IN_Shutdown(); 
begin
end;


procedure IN_Commands(); 
begin
end;


procedure IN_Move(cmd: usercmd_p);
begin
end;


procedure IN_Activate(active: qboolean); 
begin
end;


end.
