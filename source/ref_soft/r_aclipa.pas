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
{ File(s): r_aclipa.asm                                                      }
{                                                                            }
{ Initial conversion by : Carl Kenner (carl_kenner@hotmail.com)              }
{ Initial conversion on : 15-Feb-2002                                        }
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
{ r_local, r_model, ref                                                      }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{ CHECK IT!!!!!!!                                                            }
{ I had to mess with lots of stuff I didn't quite understand                 }
{----------------------------------------------------------------------------}

unit r_aclipa;
//
// r_aliasa.s
// x86 assembly-language Alias model transform and project code.
//

interface
uses Windows,
  qasm_inc,
  d_if_inc,
  r_varsa;

{$DEFINE id386}

{$IFDEF id386}
procedure _R_Alias_clip_bottom;
procedure _R_Alias_clip_top;
procedure _R_Alias_clip_right;
procedure _R_Alias_clip_left;
{$ENDIF}

implementation
uses r_local;

{$IFDEF id386}
var
  Ltemp0, Ltemp1: DWORD;

const
  pfv0 = 8 + 4;
  pfv1 = 8 + 8;
  outparm = 8 + 12;

procedure LDoForward; assembler;
label
  LDo3Forward;
asm
   sub ecx,edx
   sub eax,edx
   mov ds:dword ptr[Ltemp1],ecx
   mov ds:dword ptr[Ltemp0],eax
   fild ds:dword ptr[Ltemp1]
   fild ds:dword ptr[Ltemp0]
   mov edx,ds:dword ptr[outparm+esp]
   mov eax,2

   fdivrp st(1),st(0)   // scale

  LDo3Forward:
   fild ds:dword ptr[fv_v+0+esi]   // fv0v0 | scale
   fild ds:dword ptr[fv_v+0+edi]   // fv1v0 | fv0v0 | scale
   fild ds:dword ptr[fv_v+4+esi]   // fv0v1 | fv1v0 | fv0v0 | scale
   fild ds:dword ptr[fv_v+4+edi]   // fv1v1 | fv0v1 | fv1v0 | fv0v0 | scale
   fild ds:dword ptr[fv_v+8+esi]   // fv0v2 | fv1v1 | fv0v1 | fv1v0 | fv0v0 | scale
   fild ds:dword ptr[fv_v+8+edi]   // fv1v2 | fv0v2 | fv1v1 | fv0v1 | fv1v0 | fv0v0 |
  //  scale
   fxch st(5)   // fv0v0 | fv0v2 | fv1v1 | fv0v1 | fv1v0 | fv1v2 |
  //  scale
   fsub st(4),st(0)   // fv0v0 | fv0v2 | fv1v1 | fv0v1 | fv1v0-fv0v0 |
  //  fv1v2 | scale
   fxch st(3)   // fv0v1 | fv0v2 | fv1v1 | fv0v0 | fv1v0-fv0v0 |
  //  fv1v2 | scale
   fsub st(2),st(0)   // fv0v1 | fv0v2 | fv1v1-fv0v1 | fv0v0 |
  //  fv1v0-fv0v0 | fv1v2 | scale
   fxch st(1)   // fv0v2 | fv0v1 | fv1v1-fv0v1 | fv0v0 |
  //  fv1v0-fv0v0 | fv1v2 | scale
   fsub st(5),st(0)   // fv0v2 | fv0v1 | fv1v1-fv0v1 | fv0v0 |
  //  fv1v0-fv0v0 | fv1v2-fv0v2 | scale
   fxch st(6)   // scale | fv0v1 | fv1v1-fv0v1 | fv0v0 |
  //  fv1v0-fv0v0 | fv1v2-fv0v2 | fv0v2
   fmul st(4),st(0)   // scale | fv0v1 | fv1v1-fv0v1 | fv0v0 |
  //  (fv1v0-fv0v0)*scale | fv1v2-fv0v2 | fv0v2
   add edi,12
   fmul st(2),st(0)   // scale | fv0v1 | (fv1v1-fv0v1)*scale | fv0v0 |
  //  (fv1v0-fv0v0)*scale | fv1v2-fv0v2 | fv0v2
   add esi,12
   add edx,12
   fmul st(5),st(0)   // scale | fv0v1 | (fv1v1-fv0v1)*scale | fv0v0 |
  //  (fv1v0-fv0v0)*scale | (fv1v2-fv0v2)*scale |
  //  fv0v2
   fxch st(3)   // fv0v0 | fv0v1 | (fv1v1-fv0v1)*scale | scale |
  //  (fv1v0-fv0v0)*scale | (fv1v2-fv0v2)*scale |
  //  fv0v2
   faddp st(4),st(0)   // fv0v1 | (fv1v1-fv0v1)*scale | scale |
  //  fv0v0+(fv1v0-fv0v0)*scale |
  //  (fv1v2-fv0v2)*scale | fv0v2
   faddp st(1),st(0)   // fv0v1+(fv1v1-fv0v1)*scale | scale |
  //  fv0v0+(fv1v0-fv0v0)*scale |
  //  (fv1v2-fv0v2)*scale | fv0v2
   fxch st(4)   // fv0v2 | scale | fv0v0+(fv1v0-fv0v0)*scale |
  //  (fv1v2-fv0v2)*scale | fv0v1+(fv1v1-fv0v1)*scale
   faddp st(3),st(0)   // scale | fv0v0+(fv1v0-fv0v0)*scale |
  //  fv0v2+(fv1v2-fv0v2)*scale |
  //  fv0v1+(fv1v1-fv0v1)*scale
   fxch st(1)   // fv0v0+(fv1v0-fv0v0)*scale | scale |
  //  fv0v2+(fv1v2-fv0v2)*scale |
  //  fv0v1+(fv1v1-fv0v1)*scale
   fadd ds:dword ptr[float_point5]
   fxch st(3)   // fv0v1+(fv1v1-fv0v1)*scale | scale |
  //  fv0v2+(fv1v2-fv0v2)*scale |
  //  fv0v0+(fv1v0-fv0v0)*scale
   fadd ds:dword ptr[float_point5]
   fxch st(2)   // fv0v2+(fv1v2-fv0v2)*scale | scale |
  //  fv0v1+(fv1v1-fv0v1)*scale |
  //  fv0v0+(fv1v0-fv0v0)*scale
   fadd ds:dword ptr[float_point5]
   fxch st(3)   // fv0v0+(fv1v0-fv0v0)*scale | scale |
  //  fv0v1+(fv1v1-fv0v1)*scale |
  //  fv0v2+(fv1v2-fv0v2)*scale
   fistp ds:dword ptr[fv_v+0-12+edx]   // scale | fv0v1+(fv1v1-fv0v1)*scale |
  //  fv0v2+(fv1v2-fv0v2)*scale
   fxch st(1)   // fv0v1+(fv1v1-fv0v1)*scale | scale |
  //  fv0v2+(fv1v2-fv0v2)*scale | scale
   fistp ds:dword ptr[fv_v+4-12+edx]   // scale | fv0v2+(fv1v2-fv0v2)*scale
   fxch st(1)   // fv0v2+(fv1v2-fv0v2)*sc | scale
   fistp ds:dword ptr[fv_v+8-12+edx]   // scale

   dec eax
   jnz LDo3Forward

   fstp st(0)

   pop edi
   pop esi
end;

procedure LDoForwardOrBackward; assembler;
label
  LDoForward2;
asm
   mov edx,ds:dword ptr[fv_v+4+esi]
   mov ecx,ds:dword ptr[fv_v+4+edi]

   cmp edx,ecx
   jl LDoForward2

   mov ecx,ds:dword ptr[fv_v+4+esi]
   mov edx,ds:dword ptr[fv_v+4+edi]
   mov edi,ds:dword ptr[pfv0+esp]
   mov esi,ds:dword ptr[pfv1+esp]

  LDoForward2:
   jmp LDoForward
end;

procedure _R_Alias_clip_bottom; assembler;
asm
   push esi
   push edi

   mov esi,ds:dword ptr[pfv0+esp]
   mov edi,ds:dword ptr[pfv1+esp]

   mov eax,ds:dword ptr[r_refdef+rd_aliasvrectbottom]

   jmp LDoForwardOrBackward
end;

procedure _R_Alias_clip_top; assembler;
asm
   push esi
   push edi

   mov esi,ds:dword ptr[pfv0+esp]
   mov edi,ds:dword ptr[pfv1+esp]

   mov eax,ds:dword ptr[r_refdef+rd_aliasvrect+4]
   jmp LDoForwardOrBackward
end;

procedure LRightLeftEntry; assembler;
label
  LDoForward2;
asm
   mov edx,ds:dword ptr[fv_v+4+esi]
   mov ecx,ds:dword ptr[fv_v+4+edi]

   cmp edx,ecx
   mov edx,ds:dword ptr[fv_v+0+esi]

   mov ecx,ds:dword ptr[fv_v+0+edi]
   jl LDoForward2

   mov ecx,ds:dword ptr[fv_v+0+esi]
   mov edx,ds:dword ptr[fv_v+0+edi]
   mov edi,ds:dword ptr[pfv0+esp]
   mov esi,ds:dword ptr[pfv1+esp]

  LDoForward2:

   jmp LDoForward
end;

procedure _R_Alias_clip_right; assembler;
label
  LDoForward2;
asm
   push esi
   push edi

   mov esi,ds:dword ptr[pfv0+esp]
   mov edi,ds:dword ptr[pfv1+esp]

   mov eax,ds:dword ptr[r_refdef+rd_aliasvrectright]

   jmp LRightLeftEntry
end;

procedure _R_Alias_clip_left; assembler;
asm
   push esi
   push edi

   mov esi,ds:dword ptr[pfv0+esp]
   mov edi,ds:dword ptr[pfv1+esp]

   mov eax,ds:dword ptr[r_refdef+rd_aliasvrect+0]
   jmp LRightLeftEntry
end;

{$ENDIF} //id386

end.
