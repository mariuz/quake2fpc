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

unit r_surf8;
{----------------------------------------------------------------------------}
{                                                                            }
{ File(s): r_surf8.asm                                                       }
{                                                                            }
{ Initial conversion by : CodeFusion (michael@skovslund.dk)                  }
{ Initial conversion on : 16-July-2002                                       }
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
{ Updated on :                                                               }
{ Updated by :                                                               }
{                                                                            }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{  r_surf.pas                                                                }
{----------------------------------------------------------------------------}
{  These variables has been moved from r_surf.pas to this one because        }
{  otherwise we would have had circular references.                          }
{                                                                            }
{  edge_head           : edge_t;                                             }
{  edge_tail           : edge_t;                                             }
{  edge_aftertail      : edge_t;                                             }
{  edge_head_u_shift20 : Integer;                                            }
{  edge_tail_u_shift20 : Integer;                                            }
{  current_iv          : Integer;                                            }
{  fv                  : Single;                                             }
{  span_p              : espan_p;                                            }
{    surfaces            : surf_p;                                             }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{ Types and variables has been created here for the source to compile.       }
{ Remove all lines marked with (*R*).                                        }
{                                                                            }
{             REMEMBER : THIS FILE ARE NOT USED YET!                         }
{                                                                            }
{----------------------------------------------------------------------------}

interface

uses
//  r_main, // needs variable: colormap (pointer)
  r_local,
  qasm_inc;

type
  PCardinal = ^Cardinal;
  PByte = ^Byte;

var
//(*R*)  colormap        : pointer; // found in r_main.pas

  r_drawsurf: drawsurf_t;
  lightleft: Integer;
  sourcesstep: Integer;
  blocksize: Integer;
  sourcetstep: Integer;
  lightdelta: Integer;
  lightdeltastep: Integer;
  lightright: Integer;
  lightleftstep: Integer;
  lightrightstep: Integer;
  blockdivshift: Integer;

  blockdivmask: Cardinal;
  prowdestbase: Pointer;
  pbasesource: PByte;
  surfrowbytes: Integer; // used by ASM files
  r_lightptr: PCardinal;
  r_stepback: Integer;
  r_lightwidth: Integer;
  r_numhblocks: Integer;
  r_numvblocks: Integer;
  r_source: PByte;
  r_sourcemax: PByte;

{$IFDEF   id386}
type
  TR_SurfProc = procedure;

var
  sb_v: Integer;
  R_Surf8Start: TR_SurfProc;
  R_Surf8End: TR_SurfProc;

procedure R_DrawSurfaceBlock8_mip0;
procedure R_DrawSurfaceBlock8_mip1;
procedure R_DrawSurfaceBlock8_mip2;
procedure R_DrawSurfaceBlock8_mip3;
procedure R_Surf8Patch;

{$ENDIF}

implementation

{$IFDEF   id386}

var
  Patch: Cardinal;

{$ALIGN 4}

procedure R_DrawSurfaceBlock8_mip0;
asm
  push    ebp   // preserve caller's stack frame
  push    edi
  push    esi   // preserve register variables
  push    ebx

//      for (v=0 ; v<numvblocks ; v++)
//
  mov     ebx,ds:dword ptr[r_lightptr]
  mov     eax,ds:dword ptr[r_numvblocks]

  mov     ds:dword ptr[sb_v],eax
  mov     edi,ds:dword ptr[prowdestbase]

  mov     esi,ds:dword ptr[pbasesource]

@Lv_loop_mip0:

//         lightleft = lightptr[0];
//         lightright = lightptr[1];
//         lightdelta = (lightleft - lightright) & 0xFFFFF;
  mov     eax,ds:dword ptr[ebx]   // lightleft
  mov     edx,ds:dword ptr[4+ebx]   // lightright

  mov     ebp,eax
  mov     ecx,ds:dword ptr[r_lightwidth]

  mov     ds:dword ptr[lightright],edx
  sub     ebp,edx

  and     ebp,0FFFFFh
  lea     ebx,ds:dword ptr[ebx+ecx*4]

//         lightptr += lightwidth;
  mov     ds:dword ptr[r_lightptr],ebx

//         lightleftstep = (lightptr[0] - lightleft) >> blockdivshift;
//         lightrightstep = (lightptr[1] - lightright) >> blockdivshift;
//         lightdeltastep = ((lightleftstep - lightrightstep) & 0xFFFFF) |
//               0xF0000000;
  mov     ecx,ds:dword ptr[4+ebx]   // lightptr[1]
  mov     ebx,ds:dword ptr[ebx]   // lightptr[0]

  sub     ebx,eax
  sub     ecx,edx

  sar     ecx,4
  or      ebp,0F0000000h

  sar     ebx,4
  mov     ds:dword ptr[lightrightstep],ecx

  sub     ebx,ecx
  and     ebx,0FFFFFh

  or      ebx,0F0000000h
  sub     ecx,ecx   // high word must be 0 in loop for addressing

  mov     ds:dword ptr[lightdeltastep],ebx
  sub     ebx,ebx   // high word must be 0 in loop for addressing

@Lblockloop8_mip0:
  mov     ds:dword ptr[lightdelta],ebp
  mov     cl,ds:byte ptr[14+esi]

  sar     ebp,4
  mov     bh,dh

  mov     bl,ds:byte ptr[15+esi]
  add     edx,ebp

  mov     ch,dh
  add     edx,ebp

  add     ebx,Patch
//  mov     ah,ds:byte ptr[12345678h+ebx]
  mov     ah,ds:byte ptr[ebx]
@LBPatch0:
  mov     bl,ds:byte ptr[13+esi]

  add     ecx,Patch
//  mov     al,ds:byte ptr[12345678h+ecx]
  mov     al,ds:byte ptr[ecx]
@LBPatch1:
  mov     cl,ds:byte ptr[12+esi]

  mov     bh,dh
  add     edx,ebp

  ror     eax,16
  mov     ch,dh

  add     edx,ebp
  add     ebx,Patch
//  mov     ah,ds:byte ptr[12345678h+ebx]
  mov     ah,ds:byte ptr[ebx]
@LBPatch2:

  mov     bl,ds:byte ptr[11+esi]
  add     ecx,Patch
//  mov     al,ds:byte ptr[12345678h+ecx]
  mov     al,ds:byte ptr[ecx]
@LBPatch3:

  mov     cl,ds:byte ptr[10+esi]
  mov     ds:dword ptr[12+edi],eax

  mov     bh,dh
  add     edx,ebp

  mov     ch,dh
  add     edx,ebp

  add     ebx,Patch
//  mov     ah,ds:byte ptr[12345678h+ebx]
  mov     ah,ds:byte ptr[ebx]
@LBPatch4:
  mov     bl,ds:byte ptr[9+esi]

  add     ecx,Patch
//  mov     al,ds:byte ptr[12345678h+ecx]
  mov     al,ds:byte ptr[ecx]
@LBPatch5:
  mov     cl,ds:byte ptr[8+esi]

  mov     bh,dh
  add     edx,ebp

  ror     eax,16
  mov     ch,dh

  add     edx,ebp
  add     ebx,Patch
//  mov     ah,ds:byte ptr[12345678h+ebx]
  mov     ah,ds:byte ptr[ebx]
@LBPatch6:

  mov     bl,ds:byte ptr[7+esi]
  add     ecx,Patch
  mov     al,ds:byte ptr[ecx]
@LBPatch7:

  mov     cl,ds:byte ptr[6+esi]
  mov     ds:dword ptr[8+edi],eax

  mov     bh,dh
  add     edx,ebp

  mov     ch,dh
  add     edx,ebp

  add     ebx,Patch
//  mov     ah,ds:byte ptr[12345678h+ebx]
  mov     ah,ds:byte ptr[ebx]
@LBPatch8:
  mov     bl,ds:byte ptr[5+esi]

  add     ecx,Patch
//  mov     al,ds:byte ptr[12345678h+ecx]
  mov     al,ds:byte ptr[ecx]
@LBPatch9:
  mov     cl,ds:byte ptr[4+esi]

  mov     bh,dh
  add     edx,ebp

  ror     eax,16
  mov     ch,dh

  add     edx,ebp
  add     ebx,Patch
//  mov     ah,ds:byte ptr[12345678h+ebx]
  mov     ah,ds:byte ptr[ebx]
@LBPatch10:

  mov     bl,ds:byte ptr[3+esi]
  add     ecx,Patch
//  mov     al,ds:byte ptr[12345678h+ecx]
  mov     al,ds:byte ptr[ecx]
@LBPatch11:

  mov     cl,ds:byte ptr[2+esi]
  mov     ds:dword ptr[4+edi],eax

  mov     bh,dh
  add     edx,ebp

  mov     ch,dh
  add     edx,ebp

  add     ebx,Patch
//  mov     ah,ds:byte ptr[12345678h+ebx]
  mov     ah,ds:byte ptr[ebx]
@LBPatch12:
  mov     bl,ds:byte ptr[1+esi]

  add     ecx,Patch
//  mov     al,ds:byte ptr[12345678h+ecx]
  mov     al,ds:byte ptr[ecx]
@LBPatch13:
  mov     cl,ds:byte ptr[esi]

  mov     bh,dh
  add     edx,ebp

  ror     eax,16
  mov     ch,dh

  add     ebx,Patch
//  mov     ah,ds:byte ptr[12345678h+ebx]
  mov     ah,ds:byte ptr[ebx]
@LBPatch14:
  mov     edx,ds:dword ptr[lightright]

  add     ecx,Patch
//  mov     al,ds:byte ptr[12345678h+ecx]
  mov     al,ds:byte ptr[ecx]
@LBPatch15:
  mov     ebp,ds:dword ptr[lightdelta]

  mov     ds:dword ptr[edi],eax

  add     esi,ds:dword ptr[sourcetstep]
  add     edi,ds:dword ptr[surfrowbytes]

  add     edx,ds:dword ptr[lightrightstep]
  add     ebp,ds:dword ptr[lightdeltastep]

  mov     ds:dword ptr[lightright],edx
  jc      @Lblockloop8_mip0

//         if (pbasesource >= r_sourcemax)
//            pbasesource -= stepback;

  cmp     esi,ds:dword ptr[r_sourcemax]
  jb      @LSkip_mip0
  sub     esi,ds:dword ptr[r_stepback]
@LSkip_mip0:

  mov     ebx,ds:dword ptr[r_lightptr]
  dec     ds:dword ptr[sb_v]

  jnz     @Lv_loop_mip0

  pop     ebx   // restore register variables
  pop     esi
  pop     edi
  pop     ebp   // restore the caller's stack frame
end;

//----------------------------------------------------------------------
// Surface block drawer for mip level 1
//----------------------------------------------------------------------
{$ALIGN 4}

procedure R_DrawSurfaceBlock8_mip1;
asm
  push    ebp   // preserve caller's stack frame
  push    edi
  push    esi   // preserve register variables
  push    ebx

//      for (v=0 ; v<numvblocks ; v++)
  mov     ebx,ds:dword ptr[r_lightptr]
  mov     eax,ds:dword ptr[r_numvblocks]

  mov     ds:dword ptr[sb_v],eax
  mov     edi,ds:dword ptr[prowdestbase]

  mov     esi,ds:dword ptr[pbasesource]

@Lv_loop_mip1:

//         lightleft = lightptr[0];
//         lightright = lightptr[1];
//         lightdelta = (lightleft - lightright) & 0xFFFFF;
  mov     eax,ds:dword ptr[ebx]   // lightleft
  mov     edx,ds:dword ptr[4+ebx]   // lightright

  mov     ebp,eax
  mov     ecx,ds:dword ptr[r_lightwidth]

  mov     ds:dword ptr[lightright],edx
  sub     ebp,edx

  and     ebp,0FFFFFh
  lea     ebx,ds:dword ptr[ebx+ecx*4]

//         lightptr += lightwidth;
  mov     ds:dword ptr[r_lightptr],ebx

//         lightleftstep = (lightptr[0] - lightleft) >> blockdivshift;
//         lightrightstep = (lightptr[1] - lightright) >> blockdivshift;
//         lightdeltastep = ((lightleftstep - lightrightstep) & 0xFFFFF) |
//               0xF0000000;
  mov     ecx,ds:dword ptr[4+ebx]   // lightptr[1]
  mov     ebx,ds:dword ptr[ebx]   // lightptr[0]

  sub     ebx,eax
  sub     ecx,edx

  sar     ecx,3
  or      ebp,070000000h

  sar     ebx,3
  mov     ds:dword ptr[lightrightstep],ecx

  sub     ebx,ecx
  and     ebx,0FFFFFh

  or      ebx,0F0000000h
  sub     ecx,ecx   // high word must be 0 in loop for addressing

  mov     ds:dword ptr[lightdeltastep],ebx
  sub     ebx,ebx   //high word must be 0 in loop for addressing

@Lblockloop8_mip1:
  mov     ds:dword ptr[lightdelta],ebp
  mov     cl,ds:byte ptr[6+esi]

  sar     ebp,3
  mov     bh,dh

  mov     bl,ds:byte ptr[7+esi]
  add     edx,ebp

  mov     ch,dh
  add     edx,ebp

  add     ebx,Patch
//  mov     ah,ds:byte ptr[12345678h+ebx]
  mov     ah,ds:byte ptr[ebx]
@LBPatch22:
  mov     bl,ds:byte ptr[5+esi]

  add     ecx,Patch
//  mov     al,ds:byte ptr[12345678h+ecx]
  mov     al,ds:byte ptr[ecx]
@LBPatch23:
  mov     cl,ds:byte ptr[4+esi]

  mov     bh,dh
  add     edx,ebp

  ror     eax,16
  mov     ch,dh

  add     edx,ebp
  add     ebx,Patch
//  mov     ah,ds:byte ptr[12345678h+ebx]
  mov     ah,ds:byte ptr[ebx]
@LBPatch24:

  mov     bl,ds:byte ptr[3+esi]
  add     ecx,Patch
//  mov     al,ds:byte ptr[12345678h+ecx]
  mov     al,ds:byte ptr[ecx]
@LBPatch25:

  mov     cl,ds:byte ptr[2+esi]
  mov     ds:dword ptr[4+edi],eax

  mov     bh,dh
  add     edx,ebp

  mov     ch,dh
  add     edx,ebp

  add     ebx,Patch
//  mov     ah,ds:byte ptr[12345678h+ebx]
  mov     ah,ds:byte ptr[ebx]
@LBPatch26:
  mov     bl,ds:byte ptr[1+esi]

  add     ecx,Patch
//  mov     al,ds:byte ptr[12345678h+ecx]
  mov     al,ds:byte ptr[ecx]
@LBPatch27:
  mov     cl,ds:byte ptr[esi]

  mov     bh,dh
  add     edx,ebp

  ror     eax,16
  mov     ch,dh

  add     ebx,Patch
//  mov     ah,ds:byte ptr[12345678h+ebx]
  mov     ah,ds:byte ptr[ebx]
@LBPatch28:
  mov     edx,ds:dword ptr[lightright]

  add     ecx,Patch
//  mov     al,ds:byte ptr[12345678h+ecx]
  mov     al,ds:byte ptr[ecx]
@LBPatch29:
  mov     ebp,ds:dword ptr[lightdelta]

  mov     ds:dword ptr[edi],eax
  mov     eax,ds:dword ptr[sourcetstep]

  add     esi,eax
  mov     eax,ds:dword ptr[surfrowbytes]

  add     edi,eax
  mov     eax,ds:dword ptr[lightrightstep]

  add     edx,eax
  mov     eax,ds:dword ptr[lightdeltastep]

  add     ebp,eax
  mov     ds:dword ptr[lightright],edx

  jc      @Lblockloop8_mip1

//         if (pbasesource >= r_sourcemax)
//            pbasesource -= stepback;

  cmp     esi,ds:dword ptr[r_sourcemax]
  jb      @LSkip_mip1
  sub     esi,ds:dword ptr[r_stepback]
@LSkip_mip1:

  mov     ebx,ds:dword ptr[r_lightptr]
  dec     ds:dword ptr[sb_v]

  jnz     @Lv_loop_mip1

  pop     ebx   //restore register variables
  pop     esi
  pop     edi
  pop     ebp   //restore the caller's stack frame
end;

//----------------------------------------------------------------------
// Surface block drawer for mip level 2
//----------------------------------------------------------------------
{$ALIGN 4}

procedure R_DrawSurfaceBlock8_mip2;
asm
  push    ebp   // preserve caller's stack frame
  push    edi
  push    esi   // preserve register variables
  push    ebx

//      for (v=0 ; v<numvblocks ; v++)
  mov     ebx,ds:dword ptr[r_lightptr]
  mov     eax,ds:dword ptr[r_numvblocks]

  mov     ds:dword ptr[sb_v],eax
  mov     edi,ds:dword ptr[prowdestbase]

  mov     esi,ds:dword ptr[pbasesource]

@Lv_loop_mip2:

//         lightleft = lightptr[0];
//         lightright = lightptr[1];
//         lightdelta = (lightleft - lightright) & 0xFFFFF;
  mov     eax,ds:dword ptr[ebx]   // lightleft
  mov     edx,ds:dword ptr[4+ebx]   // lightright

  mov     ebp,eax
  mov     ecx,ds:dword ptr[r_lightwidth]

  mov     ds:dword ptr[lightright],edx
  sub     ebp,edx

  and     ebp,0FFFFFh
  lea     ebx,ds:dword ptr[ebx+ecx*4]

//         lightptr += lightwidth;
  mov     ds:dword ptr[r_lightptr],ebx

//         lightleftstep = (lightptr[0] - lightleft) >> blockdivshift;
//         lightrightstep = (lightptr[1] - lightright) >> blockdivshift;
//         lightdeltastep = ((lightleftstep - lightrightstep) & 0xFFFFF) |
//               0xF0000000;
  mov     ecx,ds:dword ptr[4+ebx]   // lightptr[1]
  mov     ebx,ds:dword ptr[ebx]   // lightptr[0]

  sub     ebx,eax
  sub     ecx,edx

  sar     ecx,2
  or      ebp,030000000h

  sar     ebx,2
  mov     ds:dword ptr[lightrightstep],ecx

  sub     ebx,ecx

  and     ebx,0FFFFFh

  or      ebx,0F0000000h
  sub     ecx,ecx   // high word must be 0 in loop for addressing

  mov     ds:dword ptr[lightdeltastep],ebx
  sub     ebx,ebx   // high word must be 0 in loop for addressing

@Lblockloop8_mip2:
  mov     ds:dword ptr[lightdelta],ebp
  mov     cl,ds:byte ptr[2+esi]

  sar     ebp,2
  mov     bh,dh

  mov     bl,ds:byte ptr[3+esi]
  add     edx,ebp

  mov     ch,dh
  add     edx,ebp

  add     ebx,Patch
//  mov     ah,ds:byte ptr[12345678h+ebx]
  mov     ah,ds:byte ptr[ebx]
@LBPatch18:
  mov     bl,ds:byte ptr[1+esi]

  add     ecx,Patch
//  mov     al,ds:byte ptr[12345678h+ecx]
  mov     al,ds:byte ptr[ecx]
@LBPatch19:
  mov     cl,ds:byte ptr[esi]

  mov     bh,dh
  add     edx,ebp

  ror     eax,16
  mov     ch,dh

  add     ebx,Patch
//  mov     ah,ds:byte ptr[12345678h+ebx]
  mov     ah,ds:byte ptr[ebx]
@LBPatch20:
  mov     edx,ds:dword ptr[lightright]

  add     ecx,Patch
//  mov     al,ds:byte ptr[12345678h+ecx]
  mov     al,ds:byte ptr[ecx]
@LBPatch21:
  mov     ebp,ds:dword ptr[lightdelta]

  mov     ds:dword ptr[edi],eax
  mov     eax,ds:dword ptr[sourcetstep]

  add     esi,eax
  mov     eax,ds:dword ptr[surfrowbytes]

  add     edi,eax
  mov     eax,ds:dword ptr[lightrightstep]

  add     edx,eax
  mov     eax,ds:dword ptr[lightdeltastep]

  add     ebp,eax
  mov     ds:dword ptr[lightright],edx

  jc      @Lblockloop8_mip2

//         if (pbasesource >= r_sourcemax)
//            pbasesource -= stepback;

  cmp     esi,ds:dword ptr[r_sourcemax]
  jb      @LSkip_mip2
  sub     esi,ds:dword ptr[r_stepback]
@LSkip_mip2:

  mov     ebx,ds:dword ptr[r_lightptr]
  dec     ds:dword ptr[sb_v]

  jnz     @Lv_loop_mip2

  pop     ebx   // restore register variables
  pop     esi
  pop     edi
  pop     ebp   // restore the caller's stack frame
end;

//----------------------------------------------------------------------
// Surface block drawer for mip level 3
//----------------------------------------------------------------------
{$ALIGN 4}

procedure R_DrawSurfaceBlock8_mip3;
asm
  push    ebp // preserve caller's stack frame
  push    edi
  push    esi // preserve register variables
  push    ebx

//   for (v=0 ; v<numvblocks ; v++)
  mov     ebx,ds:dword ptr[r_lightptr]
  mov     eax,ds:dword ptr[r_numvblocks]

  mov     ds:dword ptr[sb_v],eax
  mov     edi,ds:dword ptr[prowdestbase]

  mov     esi,ds:dword ptr[pbasesource]

@Lv_loop_mip3:

//         lightleft = lightptr[0];
//         lightright = lightptr[1];
//         lightdelta = (lightleft - lightright) & 0xFFFFF;
  mov     eax,ds:dword ptr[ebx]   // lightleft
  mov     edx,ds:dword ptr[4+ebx]   // lightright

  mov     ebp,eax
  mov     ecx,ds:dword ptr[r_lightwidth]

  mov     ds:dword ptr[lightright],edx
  sub     ebp,edx

  and     ebp,0FFFFFh
  lea     ebx,ds:dword ptr[ebx+ecx*4]

  mov     ds:dword ptr[lightdelta],ebp
//         lightptr += lightwidth;
  mov     ds:dword ptr[r_lightptr],ebx

//         lightleftstep = (lightptr[0] - lightleft) >> blockdivshift;
//         lightrightstep = (lightptr[1] - lightright) >> blockdivshift;
//         lightdeltastep = ((lightleftstep - lightrightstep) & 0xFFFFF) |
//               0xF0000000;
  mov     ecx,ds:dword ptr[4+ebx]   // lightptr[1]
  mov     ebx,ds:dword ptr[ebx]   // lightptr[0]

  sub     ebx,eax
  sub     ecx,edx

  sar     ecx,1

  sar     ebx,1
  mov     ds:dword ptr[lightrightstep],ecx

  sub     ebx,ecx
  and     ebx,0FFFFFh

  sar     ebp,1
  or      ebx,0F0000000h

  mov     ds:dword ptr[lightdeltastep],ebx
  sub     ebx,ebx   // high word must be 0 in loop for addressing

  mov     bl,ds:byte ptr[1+esi]
  sub     ecx,ecx   // high word must be 0 in loop for addressing

  mov     bh,dh
  mov     cl,ds:byte ptr[esi]

  add     edx,ebp
  mov     ch,dh

  add     ebx,Patch
//  mov     al,ds:byte ptr[12345678h+ebx]
  mov     al,ds:byte ptr[ebx]
@LBPatch16:
  mov     edx,ds:dword ptr[lightright]

  mov     ds:byte ptr[1+edi],al
  add     ecx,Patch
//  mov     al,ds:byte ptr[12345678h+ecx]
  mov     al,ds:byte ptr[ecx]
@LBPatch17:

  mov     ds:byte ptr[edi],al
  mov     eax,ds:dword ptr[sourcetstep]

  add     esi,eax
  mov     eax,ds:dword ptr[surfrowbytes]

  add     edi,eax
  mov     eax,ds:dword ptr[lightdeltastep]

  mov     ebp,ds:dword ptr[lightdelta]
  mov     cl,ds:byte ptr[esi]

  add     ebp,eax
  mov     eax,ds:dword ptr[lightrightstep]

  sar     ebp,1
  add     edx,eax

  mov     bh,dh
  mov     bl,ds:byte ptr[1+esi]

  add     edx,ebp
  mov     ch,dh

  add     ebx,Patch
//  mov     al,ds:byte ptr[12345678h+ebx]
  mov     al,ds:byte ptr[ebx]
@LBPatch30:
  mov     edx,ds:dword ptr[sourcetstep]

  mov     ds:byte ptr[1+edi],al
  add     ecx,Patch
//  mov     al,ds:byte ptr[12345678h+ecx]
  mov     al,ds:byte ptr[ecx]
@LBPatch31:

  mov     ds:byte ptr[edi],al
  mov     ebp,ds:dword ptr[surfrowbytes]

  add     esi,edx
  add     edi,ebp

//         if (pbasesource >= r_sourcemax)
//            pbasesource -= stepback;

  cmp     esi,ds:dword ptr[r_sourcemax]
  jb      @LSkip_mip3
  sub     esi,ds:dword ptr[r_stepback]
@LSkip_mip3:

  mov     ebx,ds:dword ptr[r_lightptr]
  dec     ds:dword ptr[sb_v]

  jnz     @Lv_loop_mip3

  pop     ebx   // restore register variables
  pop     esi
  pop     edi
  pop     ebp   // restore the caller's stack frame
end;

{$ALIGN 4}

procedure R_Surf8Patch;
begin
  Patch := Cardinal(colormap);
(*  push    ebx

  mov     eax,ds:dword ptr[_colormap]
  mov     ebx,offset LPatchTable8
  mov     ecx,32
@LPatchLoop8:
  mov     edx,ds:dword ptr[ebx]
  add     ebx,4
  mov     ds:dword ptr[edx],eax
  dec     ecx
  jnz     @LPatchLoop8

  pop     ebx*)
end;

initialization
  R_Surf8Start := TR_SurfProc(Addr(R_DrawSurfaceBlock8_mip0));
  R_Surf8End := TR_SurfProc(Addr(R_Surf8Patch));

{$ENDIF}

end.
