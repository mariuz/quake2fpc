unit rw_linux_h;

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
interface
uses q_shared_add;

type
Key_Event_fp_t = procedure(key: integer;  down: qboolean); 

//extern void (*KBD_Update_fp)(void);
//extern void (*KBD_Init_fp)(Key_Event_fp_t fp);
//extern void (*KBD_Close_fp)(void);
//external ????

//procedure KBD_Update_fp();

//procedure KBD_Init_fp(fp: Key_Event_fp_t);

//procedure KBD_Close_fp();

type
in_state = record
        IN_CenterView_fp: procedure(); 
        (* Pointers to functions back in client, set by vid_so*)
        Key_Event_fp: Key_Event_fp_t;
        viewangles: vec_p ; //pvec_t;
        in_strafe_state: Pointer; //pointer
        end;
in_state_t = in_state;
Pin_state_t = ^in_state_t ;


implementation


end.
