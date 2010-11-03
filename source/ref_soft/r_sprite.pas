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

unit r_sprite;
{----------------------------------------------------------------------------}
{                                                                            }
{ File(s): r_sprite.c                                                        }
{                                                                            }
{ Initial conversion by : YgriK (Igor Karpov) - glYgriK@hotbox.ru            }
{ Initial conversion on : 04-Feb-2002                                        }
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
{ Updated on : 19-july-2002                                                  }
{ Updated by : CodeFusion (michael@skovslund.dk)                             }
{                                                                            }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{  None.                                                                     }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{----------------------------------------------------------------------------}

interface

uses
  r_local,
  qfiles,
  r_poly;

procedure R_DrawSprite;

implementation

uses
  q_shared,
  r_main,
  r_bsp_c;

(*
** R_DrawSprite
**
** Draw currententity / currentmodel as a single texture
** mapped polygon
*)

procedure R_DrawSprite;
var
  left, up: vec3_t;
  right, down: vec3_t;
  s_psprite: dsprite_p;
  s_psprframe: dsprframe_p;
begin
  s_psprite := dsprite_p(currentmodel^.extradata);
{$IF false}
  if ((currententity^.frame >= s_psprite^.numframes) or (currententity^.frame < 0)) then
  begin
    ri.Con_Printf(PRINT_ALL, PChar('No such sprite frame ' + IntToStr(currententity^.frame) + #13#10);
      currententity^.frame := 0;
  end;
{$IFEND}
  currententity^.frame := currententity^.frame mod s_psprite^.numframes;

  s_psprframe := @s_psprite^.frames[currententity^.frame];
  r_polydesc.pixels := currentmodel^.skins[currententity^.frame]^.pixels[0];
  r_polydesc.pixel_width := s_psprframe^.width;
  r_polydesc.pixel_height := s_psprframe^.height;
  r_polydesc.dist := 0;

  // generate the sprite's axes, completely parallel to the viewplane.
  VectorCopy(vup, r_polydesc.vup);
  VectorCopy(vright, r_polydesc.vright);
  VectorCopy(vpn, r_polydesc.vpn);

// build the sprite poster in worldspace
  VectorScale(r_polydesc.vright, s_psprframe^.width - s_psprframe^.origin_x, right);
  VectorScale(r_polydesc.vup, s_psprframe^.height - s_psprframe^.origin_y, up);
  VectorScale(r_polydesc.vright, -s_psprframe^.origin_x, left);
  VectorScale(r_polydesc.vup, -s_psprframe^.origin_y, down);

  // invert UP vector for sprites
  VectorInverse(r_polydesc.vup);

  r_clip_verts[0, 0][0] := r_entorigin[0] + up[0] + left[0];
  r_clip_verts[0, 0][1] := r_entorigin[1] + up[1] + left[1];
  r_clip_verts[0, 0][2] := r_entorigin[2] + up[2] + left[2];
  r_clip_verts[0, 0][3] := 0;
  r_clip_verts[0, 0][4] := 0;

  r_clip_verts[0, 1][0] := r_entorigin[0] + up[0] + right[0];
  r_clip_verts[0, 1][1] := r_entorigin[1] + up[1] + right[1];
  r_clip_verts[0, 1][2] := r_entorigin[2] + up[2] + right[2];
  r_clip_verts[0, 1][3] := s_psprframe^.width;
  r_clip_verts[0, 1][4] := 0;

  r_clip_verts[0, 2][0] := r_entorigin[0] + down[0] + right[0];
  r_clip_verts[0, 2][1] := r_entorigin[1] + down[1] + right[1];
  r_clip_verts[0, 2][2] := r_entorigin[2] + down[2] + right[2];
  r_clip_verts[0, 2][3] := s_psprframe^.width;
  r_clip_verts[0, 2][4] := s_psprframe^.height;

  r_clip_verts[0, 3][0] := r_entorigin[0] + down[0] + left[0];
  r_clip_verts[0, 3][1] := r_entorigin[1] + down[1] + left[1];
  r_clip_verts[0, 3][2] := r_entorigin[2] + down[2] + left[2];
  r_clip_verts[0, 3][3] := 0;
  r_clip_verts[0, 3][4] := s_psprframe^.height;

  r_polydesc.nump := 4;
  r_polydesc.s_offset := (r_polydesc.pixel_width shr 1);
  r_polydesc.t_offset := (r_polydesc.pixel_height shr 1);
  VectorCopy(modelorg, vec3_p(@r_polydesc.viewer_position)^);

  r_polydesc.stipple_parity := 1;
  if (currententity^.flags and RF_TRANSLUCENT) <> 0 then
    R_ClipAndDrawPoly(currententity^.alpha, 0, true)
  else
    R_ClipAndDrawPoly(1.0, 0, true);
  r_polydesc.stipple_parity := 0;
end;

end.
