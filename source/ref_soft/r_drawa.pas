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

//100%
{$ALIGN 8}{$MINENUMSIZE 4}
{----------------------------------------------------------------------------}
{                                                                            }
{ File(s): r_drawa.asm                                                       }
{                                                                            }
{ Initial conversion by : Carl Kenner (carl_kenner@hotmail.com)              }
{ Initial conversion on : 25-Feb-2002                                        }
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
{ none                                                                       }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{ Test it!!!!                                                                }
{----------------------------------------------------------------------------}
unit r_drawa;

{$DEFINE NODEPEND}

interface

procedure R_ClipEdge;

implementation
uses Windows,
  r_rast,
  r_local,
{$IFNDEF NODEPEND}rw_Imp,
{$ENDIF}qasm_inc,
  d_if_inc,
  r_varsa;
{$DEFINE id386}
{$IFDEF id386}

{$IFDEF NODEPEND}
var
  fpu_ceil_cw, fpu_chop_cw, fpu_full_cw, fpu_cw, fpu_pushed_cw: Word;
  fpu_sp24_cw, fpu_sp24_ceil_cw: Word;

// CAK - This function calculates the floating point control words
// CAK - needed for various floating point modes (rounding, truncating, etc.)
// CAK - and stores them in the variables.
// CAK - This function doesn't actually change the floating point control word
// CAK - in the Maths coprocessor, or do anything harmful.

procedure Sys_SetFPCW; assembler;
asm
  xor eax, eax                  // CAK   eax = 0
  fnstcw  word ptr fpu_cw       // CAK   fpu_cw = Maths Coprocessor's Floating Point Control Word
  mov ax, word ptr fpu_cw       // CAK   ax = fpu_cw

  and ah, 0f0h
  or  ah, 003h          // round to nearest mode, extended precision
  mov fpu_full_cw, ax

  and ah, 0f0h
  or  ah, 00fh          // RTZ/truncate/chop mode, extended precision
  mov fpu_chop_cw, ax

  and ah, 0f0h
  or  ah, 00bh          // ceil mode, extended precision
  mov fpu_ceil_cw, ax

  and ah, 0f0h          // round to nearest, 24-bit single precision
  mov fpu_sp24_cw, ax

  and ah, 0f0h          // ceil mode, 24-bit single precision
  or  ah, 008h          //
  mov fpu_sp24_ceil_cw, ax
end;

{$ENDIF}

// !!! if these are changed, they must be changed in r_draw.c too !!!
const
  FULLY_CLIPPED_CACHED = $80000000;
  FRAMECOUNT_MASK = $7FFFFFFF;

var
  Ld0: Single = 0.0;
  Ld1: Single = 0.0;
  Lstack: LongInt = 0;
  Lfp_near_clip: Single = NEAR_CLIP;
  Lceilv0: LongInt = 0;
  Lv: LongInt = 0;
  Lu0: LongInt = 0;
  Lv0: LongInt = 0;
  Lzi0: LongInt = 0;

//----------------------------------------------------------------------
// edge clipping code
//----------------------------------------------------------------------

const
  pv0 = 4 + 12;
  pv1 = 8 + 12;
  clip = 12 + 12;

// align 4

procedure R_ClipEdge; assembler;
label
  Lemit, Lcliploop, Lcontinue, LCalcFirst, LCalcSecond;
label
  LTransformAndProject, LPop5AndDone, LDoPop, Ldone;
label
  LSide0, LSide1, LSideDone, LNotFirst, LDoFirst;
label
  LSetRemove, LFindInsertLoop, LInsertFound;
label
  LP0, LP1, LP2, LP4, LP5;
label
  Lp1_, Lp2_, Lp3_;
label
  Ltestright, Ltestright2, LNoClip;
label
  LClampP0, LClampP1, LClampP2, LClampP3;
asm
  push esi   // preserve register variables
  push edi
  push ebx
  mov ds:dword ptr[Lstack],esp   // for clearing the stack later

//   float      d0, d1, f;
//   mvertex_t   clipvert;

  mov ebx,ds:dword ptr[clip+esp]
  mov esi,ds:dword ptr[pv0+esp]
  mov edx,ds:dword ptr[pv1+esp]

//   if (clip)
//   {
  test ebx,ebx
  jz Lemit

//      do
//      {

Lcliploop:

//         d0 = DotProduct (pv0->position, clip->normal) - clip->dist;
//         d1 = DotProduct (pv1->position, clip->normal) - clip->dist;
  fld ds:dword ptr[mv_position+0+esi]
  fmul ds:dword ptr[cp_normal+0+ebx]
  fld ds:dword ptr[mv_position+4+esi]
  fmul ds:dword ptr[cp_normal+4+ebx]
  fld ds:dword ptr[mv_position+8+esi]
  fmul ds:dword ptr[cp_normal+8+ebx]
  fxch st(1)
  faddp st(2),st(0)   // d0mul2 | d0add0

  fld ds:dword ptr[mv_position+0+edx]
  fmul ds:dword ptr[cp_normal+0+ebx]
  fld ds:dword ptr[mv_position+4+edx]
  fmul ds:dword ptr[cp_normal+4+ebx]
  fld ds:dword ptr[mv_position+8+edx]
  fmul ds:dword ptr[cp_normal+8+ebx]
  fxch st(1)
  faddp st(2),st(0)   // d1mul2 | d1add0 | d0mul2 | d0add0
  fxch st(3)   // d0add0 | d1add0 | d0mul2 | d1mul2

  faddp st(2),st(0)   // d1add0 | dot0 | d1mul2
  faddp st(2),st(0)   // dot0 | dot1

  fsub ds:dword ptr[cp_dist+ebx]   // d0 | dot1
  fxch st(1)   // dot1 | d0
  fsub ds:dword ptr[cp_dist+ebx]   // d1 | d0
  fxch st(1)
  fstp ds:dword ptr[Ld0]
  fstp ds:dword ptr[Ld1]

//         if (d0 >= 0)
//         {
  mov eax,ds:dword ptr[Ld0]
  mov ecx,ds:dword ptr[Ld1]
  or ecx,eax
  js Lp2_

// both points are unclipped

Lcontinue:

//
//            R_ClipEdge (&clipvert, pv1, clip->next);
//            return;
//         }
//      } while ((clip = clip->next) != NULL);
  mov ebx,ds:dword ptr[cp_next+ebx]
  test ebx,ebx
  jnz Lcliploop

//   }

//// add the edge
//   R_EmitEdge (pv0, pv1);
Lemit:

//
// set integer rounding to ceil mode, set to single precision
//
// FIXME: do away with by manually extracting integers from floats?
// FIXME: set less often
  fldcw ds:word ptr[fpu_ceil_cw]

//   edge_t   *edge, *pcheck;
//   int      u_check;
//   float   u, u_step;
//   vec3_t   local, transformed;
//   float   *world;
//   int      v, v2, ceilv0;
//   float   scale, lzi0, u0, v0;
//   int      side;

//   if (r_lastvertvalid)
//   {
  cmp ds:dword ptr[r_lastvertvalid],0
  jz LCalcFirst

//      u0 = r_u1;
//      v0 = r_v1;
//      lzi0 = r_lzi1;
//      ceilv0 = r_ceilv1;
  mov eax,ds:dword ptr[r_lzi1]
  mov ecx,ds:dword ptr[r_u1]
  mov ds:dword ptr[Lzi0],eax
  mov ds:dword ptr[Lu0],ecx
  mov ecx,ds:dword ptr[r_v1]
  mov eax,ds:dword ptr[r_ceilv1]
  mov ds:dword ptr[Lv0],ecx
  mov ds:dword ptr[Lceilv0],eax
  jmp LCalcSecond

//   }

LCalcFirst:

//   else
//   {
//      world = &pv0->position[0];

  call LTransformAndProject   // v0 | lzi0 | u0

  fst ds:dword ptr[Lv0]
  fxch st(2)   // u0 | lzi0 | v0
  fstp ds:dword ptr[Lu0]   // lzi0 | v0
  fstp ds:dword ptr[Lzi0]   // v0

//      ceilv0 = (int)(v0 - 2000) + 2000; // ceil(v0);
  fistp ds:dword ptr[Lceilv0]

//   }

LCalcSecond:

//   world = &pv1->position[0];
  mov esi,edx

  call LTransformAndProject   // v1 | lzi1 | u1

  fld ds:dword ptr[Lu0]   // u0 | v1 | lzi1 | u1
  fxch st(3)   // u1 | v1 | lzi1 | u0
  fld ds:dword ptr[Lzi0]   // lzi0 | u1 | v1 | lzi1 | u0
  fxch st(3)   // lzi1 | u1 | v1 | lzi0 | u0
  fld ds:dword ptr[Lv0]   // v0 | lzi1 | u1 | v1 | lzi0 | u0
  fxch st(3)   // v1 | lzi1 | u1 | v0 | lzi0 | u0

//   r_ceilv1 = (int)(r_v1 - 2000) + 2000; // ceil(r_v1);
  fist ds:dword ptr[r_ceilv1]

  fldcw ds:word ptr[fpu_chop_cw]   // put back normal floating-point state

  fst ds:dword ptr[r_v1]
  fxch st(4)   // lzi0 | lzi1 | u1 | v0 | v1 | u0

//   if (r_lzi1 > lzi0)
//      lzi0 = r_lzi1;
  fcom st(1)
  fnstsw ax
  test ah,1
  jz LP0
  fstp st(0)
  fld st(0)
LP0:

  fxch st(1)   // lzi1 | lzi0 | u1 | v0 | v1 | u0
  fstp ds:dword ptr[r_lzi1]   // lzi0 | u1 | v0 | v1 | u0
  fxch st(1)
  fst ds:dword ptr[r_u1]
  fxch st(1)

//   if (lzi0 > r_nearzi)   // for mipmap finding
//      r_nearzi = lzi0;
  fcom ds:dword ptr[r_nearzi]
  fnstsw ax
  test ah,045h
  jnz LP1
  fst ds:dword ptr[r_nearzi]
LP1:

// // for right edges, all we want is the effect on 1/z
//   if (r_nearzionly)
//      return;
  mov eax,ds:dword ptr[r_nearzionly]
  test eax,eax
  jz LP2
LPop5AndDone:
  mov eax,ds:dword ptr[cacheoffset]
  mov edx,ds:dword ptr[r_framecount]
  cmp eax,07FFFFFFFh
  jz LDoPop
  and edx,offset FRAMECOUNT_MASK
  or edx,offset FULLY_CLIPPED_CACHED
  mov ds:dword ptr[cacheoffset],edx

LDoPop:
  fstp st(0)   // u1 | v0 | v1 | u0
  fstp st(0)   // v0 | v1 | u0
  fstp st(0)   // v1 | u0
  fstp st(0)   // u0
  fstp st(0)
  jmp Ldone

LP2:

// // create the edge
//   if (ceilv0 == r_ceilv1)
//      return;      // horizontal edge
  mov ebx,ds:dword ptr[Lceilv0]
  mov edi,ds:dword ptr[_edge_p]    // CAK - the var not the type
  mov ecx,ds:dword ptr[r_ceilv1]
  mov edx,edi
  mov esi,ds:dword ptr[r_pedge]
  add edx,offset et_size
  cmp ebx,ecx
  jz LPop5AndDone

  mov eax,ds:dword ptr[r_pedge]
  mov ds:dword ptr[et_owner+edi],eax

//   side = ceilv0 > r_ceilv1;
//
//   edge->nearzi = lzi0;
  fstp ds:dword ptr[et_nearzi+edi]   // u1 | v0 | v1 | u0

//   if (side == 1)
//   {
  jc LSide0

LSide1:

//   // leading edge (go from p2 to p1)

//      u_step = ((u0 - r_u1) / (v0 - r_v1));
  fsubp st(3),st(0)   // v0 | v1 | u0-u1
  fsub st(0),st(1)   // v0-v1 | v1 | u0-u1
  fdivp st(2),st(0)   // v1 | ustep

//   r_emitted = 1;
  mov ds:dword ptr[r_emitted],1

//   edge = edge_p++;
  mov ds:dword ptr[_edge_p],edx

// pretouch next edge
  mov eax,ds:dword ptr[edx]

//      v2 = ceilv0 - 1;
//      v = r_ceilv1;
  mov eax,ecx
  lea ecx,ds:dword ptr[-1+ebx]
  mov ebx,eax

//      edge->surfs[0] = 0;
//      edge->surfs[1] = surface_p - surfaces;
  mov eax,ds:dword ptr[surface_p]
  mov esi,ds:dword ptr[surfaces]
  sub edx,edx
  sub eax,esi
  shr eax,offset SURF_T_SHIFT
  mov ds:dword ptr[et_surfs+edi],edx
  mov ds:dword ptr[et_surfs+2+edi],eax

  sub esi,esi

//      u = r_u1 + ((float)v - r_v1) * u_step;
  mov ds:dword ptr[Lv],ebx
  fild ds:dword ptr[Lv]   // v | v1 | ustep
  fsubrp st(1),st(0)   // v-v1 | ustep
  fmul st(0),st(1)   // (v-v1)*ustep | ustep
  fadd ds:dword ptr[r_u1]   // u | ustep

  jmp LSideDone

//   }

LSide0:

//   else
//   {
//   // trailing edge (go from p1 to p2)

//      u_step = ((r_u1 - u0) / (r_v1 - v0));
  fsub st(0),st(3)   // u1-u0 | v0 | v1 | u0
  fxch st(2)   // v1 | v0 | u1-u0 | u0
  fsub st(0),st(1)   // v1-v0 | v0 | u1-u0 | u0
  fdivp st(2),st(0)   // v0 | ustep | u0

//   r_emitted = 1;
  mov ds:dword ptr[r_emitted],1

//   edge = edge_p++;
  mov ds:dword ptr[_edge_p],edx

// pretouch next edge
  mov eax,ds:dword ptr[edx]

//      v = ceilv0;
//      v2 = r_ceilv1 - 1;
  dec ecx

//      edge->surfs[0] = surface_p - surfaces;
//      edge->surfs[1] = 0;
  mov eax,ds:dword ptr[surface_p]
  mov esi,ds:dword ptr[surfaces]
  sub edx,edx
  sub eax,esi
  shr eax,offset SURF_T_SHIFT
  mov ds:dword ptr[et_surfs+2+edi],edx
  mov ds:dword ptr[et_surfs+edi],eax

  mov esi,1

//      u = u0 + ((float)v - v0) * u_step;
  mov ds:dword ptr[Lv],ebx
  fild ds:dword ptr[Lv]   // v | v0 | ustep | u0
  fsubrp st(1),st(0)   // v-v0 | ustep | u0
  fmul st(0),st(1)   // (v-v0)*ustep | ustep | u0
  faddp st(2),st(0)   // ustep | u
  fxch st(1)   // u | ustep

//   }

LSideDone:

//   edge->u_step = u_step*0x100000;
//   edge->u = u*0x100000 + 0xFFFFF;

  fmul ds:dword ptr[fp_1m]   // u*0x100000 | ustep
  fxch st(1)   // ustep | u*0x100000
  fmul ds:dword ptr[fp_1m]   // ustep*0x100000 | u*0x100000
  fxch st(1)   // u*0x100000 | ustep*0x100000
  fadd ds:dword ptr[fp_1m_minus_1]   // u*0x100000 + 0xFFFFF | ustep*0x100000
  fxch st(1)   // ustep*0x100000 | u*0x100000 + 0xFFFFF
  fistp ds:dword ptr[et_u_step+edi]   // u*0x100000 + 0xFFFFF
  fistp ds:dword ptr[et_u+edi]

// // we need to do this to avoid stepping off the edges if a very nearly
// // horizontal edge is less than epsilon above a scan, and numeric error
// // causes it to incorrectly extend to the scan, and the extension of the
// // line goes off the edge of the screen
// // FIXME: is this actually needed?
//   if (edge->u < r_refdef.vrect_x_adj_shift20)
//      edge->u = r_refdef.vrect_x_adj_shift20;
//   if (edge->u > r_refdef.vrectright_adj_shift20)
//      edge->u = r_refdef.vrectright_adj_shift20;
  mov eax,ds:dword ptr[et_u+edi]
  mov edx,ds:dword ptr[r_refdef+rd_vrect_x_adj_shift20]
  cmp eax,edx
  jl LP4
  mov edx,ds:dword ptr[r_refdef+rd_vrectright_adj_shift20]
  cmp eax,edx
  jng LP5
LP4:
  mov ds:dword ptr[et_u+edi],edx
  mov eax,edx
LP5:

// // sort the edge in normally
//   u_check = edge->u;
//
//   if (edge->surfs[0])
//      u_check++;   // sort trailers after leaders
  add eax,esi

//   if (!newedges[v] || newedges[v]->u >= u_check)
//   {
  mov esi,ds:dword ptr[newedges+ebx*4]
  test esi,esi
  jz LDoFirst
  cmp ds:dword ptr[et_u+esi],eax
  jl LNotFirst
LDoFirst:

//      edge->next = newedges[v];
//      newedges[v] = edge;
  mov ds:dword ptr[et_next+edi],esi
  mov ds:dword ptr[newedges+ebx*4],edi

  jmp LSetRemove

//   }

LNotFirst:

//   else
//   {
//      pcheck = newedges[v];
//
//      while (pcheck->next && pcheck->next->u < u_check)
//         pcheck = pcheck->next;
LFindInsertLoop:
  mov edx,esi
  mov esi,ds:dword ptr[et_next+esi]
  test esi,esi
  jz LInsertFound
  cmp ds:dword ptr[et_u+esi],eax
  jl LFindInsertLoop

LInsertFound:

//      edge->next = pcheck->next;
//      pcheck->next = edge;
  mov ds:dword ptr[et_next+edi],esi
  mov ds:dword ptr[et_next+edx],edi

//   }

LSetRemove:

//   edge->nextremove = removeedges[v2];
//   removeedges[v2] = edge;
  mov eax,ds:dword ptr[removeedges+ecx*4]
  mov ds:dword ptr[removeedges+ecx*4],edi
  mov ds:dword ptr[et_nextremove+edi],eax

Ldone:
  mov esp,ds:dword ptr[Lstack]   // clear temporary variables from stack

  pop ebx   // restore register variables
  pop edi
  pop esi
  ret

// at least one point is clipped

Lp2_:
  test eax,eax
  jns Lp1_

//         else
//         {
//         // point 0 is clipped

//            if (d1 < 0)
//            {
  mov eax,ds:dword ptr[Ld1]
  test eax,eax
  jns Lp3_

//            // both points are clipped
//            // we do cache fully clipped edges
//               if (!leftclipped)
  mov eax,ds:dword ptr[r_leftclipped]
  mov ecx,ds:dword ptr[r_pedge]
  test eax,eax
  jnz Ldone

//                  r_pedge->framecount = r_framecount;
  mov eax,ds:dword ptr[r_framecount]
  and eax,offset FRAMECOUNT_MASK
  or eax,offset FULLY_CLIPPED_CACHED
  mov ds:dword ptr[cacheoffset],eax

//               return;
  jmp Ldone

//            }

Lp1_:

//         // point 0 is unclipped
//            if (d1 >= 0)
//            {
//            // both points are unclipped
//               continue;

//         // only point 1 is clipped

//            f = d0 / (d0 - d1);
  fld ds:dword ptr[Ld0]
  fld ds:dword ptr[Ld1]
  fsubr st(0),st(1)

//         // we don't cache partially clipped edges
  mov ds:dword ptr[cacheoffset],07FFFFFFFh

  fdivp st(1),st(0)

  sub esp,offset mv_size   // allocate space for clipvert

//            clipvert.position[0] = pv0->position[0] +
//                  f * (pv1->position[0] - pv0->position[0]);
//            clipvert.position[1] = pv0->position[1] +
//                  f * (pv1->position[1] - pv0->position[1]);
//            clipvert.position[2] = pv0->position[2] +
//                  f * (pv1->position[2] - pv0->position[2]);
  fld ds:dword ptr[mv_position+8+edx]
  fsub ds:dword ptr[mv_position+8+esi]
  fld ds:dword ptr[mv_position+4+edx]
  fsub ds:dword ptr[mv_position+4+esi]
  fld ds:dword ptr[mv_position+0+edx]
  fsub ds:dword ptr[mv_position+0+esi]   // 0 | 1 | 2

// replace pv1 with the clip point
  mov edx,esp
  mov eax,ds:dword ptr[cp_leftedge+ebx]
  test al,al

  fmul st(0),st(3)
  fxch st(1)   // 1 | 0 | 2
  fmul st(0),st(3)
  fxch st(2)   // 2 | 0 | 1
  fmulp st(3),st(0)   // 0 | 1 | 2
  fadd ds:dword ptr[mv_position+0+esi]
  fxch st(1)   // 1 | 0 | 2
  fadd ds:dword ptr[mv_position+4+esi]
  fxch st(2)   // 2 | 0 | 1
  fadd ds:dword ptr[mv_position+8+esi]
  fxch st(1)   // 0 | 2 | 1
  fstp ds:dword ptr[mv_position+0+esp]   // 2 | 1
  fstp ds:dword ptr[mv_position+8+esp]   // 1
  fstp ds:dword ptr[mv_position+4+esp]

//            if (clip->leftedge)
//            {
  jz Ltestright

//               r_leftclipped = true;
//               r_leftexit = clipvert;
  mov ds:dword ptr[r_leftclipped],1
  mov eax,ds:dword ptr[mv_position+0+esp]
  mov ds:dword ptr[r_leftexit+mv_position+0],eax
  mov eax,ds:dword ptr[mv_position+4+esp]
  mov ds:dword ptr[r_leftexit+mv_position+4],eax
  mov eax,ds:dword ptr[mv_position+8+esp]
  mov ds:dword ptr[r_leftexit+mv_position+8],eax

  jmp Lcontinue

//            }

Ltestright:
//            else if (clip->rightedge)
//            {
  test ah,ah
  jz Lcontinue

//               r_rightclipped = true;
//               r_rightexit = clipvert;
  mov ds:dword ptr[r_rightclipped],1
  mov eax,ds:dword ptr[mv_position+0+esp]
  mov ds:dword ptr[r_rightexit+mv_position+0],eax
  mov eax,ds:dword ptr[mv_position+4+esp]
  mov ds:dword ptr[r_rightexit+mv_position+4],eax
  mov eax,ds:dword ptr[mv_position+8+esp]
  mov ds:dword ptr[r_rightexit+mv_position+8],eax

//            }
//
//            R_ClipEdge (pv0, &clipvert, clip->next);
//            return;
//         }
  jmp Lcontinue

//         }

Lp3_:

//         // only point 0 is clipped
//            r_lastvertvalid = false;

  mov ds:dword ptr[r_lastvertvalid],0

//            f = d0 / (d0 - d1);
  fld ds:dword ptr[Ld0]
  fld ds:dword ptr[Ld1]
  fsubr st(0),st(1)

//         // we don't cache partially clipped edges
  mov ds:dword ptr[cacheoffset],07FFFFFFFh

  fdivp st(1),st(0)

  sub esp,offset mv_size   // allocate space for clipvert

//            clipvert.position[0] = pv0->position[0] +
//                  f * (pv1->position[0] - pv0->position[0]);
//            clipvert.position[1] = pv0->position[1] +
//                  f * (pv1->position[1] - pv0->position[1]);
//            clipvert.position[2] = pv0->position[2] +
//                  f * (pv1->position[2] - pv0->position[2]);
  fld ds:dword ptr[mv_position+8+edx]
  fsub ds:dword ptr[mv_position+8+esi]
  fld ds:dword ptr[mv_position+4+edx]
  fsub ds:dword ptr[mv_position+4+esi]
  fld ds:dword ptr[mv_position+0+edx]
  fsub ds:dword ptr[mv_position+0+esi]   // 0 | 1 | 2

  mov eax,ds:dword ptr[cp_leftedge+ebx]
  test al,al

  fmul st(0),st(3)
  fxch st(1)   // 1 | 0 | 2
  fmul st(0),st(3)
  fxch st(2)   // 2 | 0 | 1
  fmulp st(3),st(0)   // 0 | 1 | 2
  fadd ds:dword ptr[mv_position+0+esi]
  fxch st(1)   // 1 | 0 | 2
  fadd ds:dword ptr[mv_position+4+esi]
  fxch st(2)   // 2 | 0 | 1
  fadd ds:dword ptr[mv_position+8+esi]
  fxch st(1)   // 0 | 2 | 1
  fstp ds:dword ptr[mv_position+0+esp]   // 2 | 1
  fstp ds:dword ptr[mv_position+8+esp]   // 1
  fstp ds:dword ptr[mv_position+4+esp]

// replace pv0 with the clip point
  mov esi,esp

//            if (clip->leftedge)
//            {
  jz Ltestright2

//               r_leftclipped = true;
//               r_leftenter = clipvert;
  mov ds:dword ptr[r_leftclipped],1
  mov eax,ds:dword ptr[mv_position+0+esp]
  mov ds:dword ptr[r_leftenter+mv_position+0],eax
  mov eax,ds:dword ptr[mv_position+4+esp]
  mov ds:dword ptr[r_leftenter+mv_position+4],eax
  mov eax,ds:dword ptr[mv_position+8+esp]
  mov ds:dword ptr[r_leftenter+mv_position+8],eax

  jmp Lcontinue

//            }

Ltestright2:
//            else if (clip->rightedge)
//            {
  test ah,ah
  jz Lcontinue

//               r_rightclipped = true;
//               r_rightenter = clipvert;
  mov ds:dword ptr[r_rightclipped],1
  mov eax,ds:dword ptr[mv_position+0+esp]
  mov ds:dword ptr[r_rightenter+mv_position+0],eax
  mov eax,ds:dword ptr[mv_position+4+esp]
  mov ds:dword ptr[r_rightenter+mv_position+4],eax
  mov eax,ds:dword ptr[mv_position+8+esp]
  mov ds:dword ptr[r_rightenter+mv_position+8],eax

//            }
  jmp Lcontinue

// %esi = vec3_t point to transform and project
// %edx preserved
LTransformAndProject:

//   // transform and project
//      VectorSubtract (world, modelorg, local);
  fld ds:dword ptr[mv_position+0+esi]
  fsub ds:dword ptr[modelorg+0]
  fld ds:dword ptr[mv_position+4+esi]
  fsub ds:dword ptr[modelorg+4]
  fld ds:dword ptr[mv_position+8+esi]
  fsub ds:dword ptr[modelorg+8]
  fxch st(2)   // local[0] | local[1] | local[2]

//      TransformVector (local, transformed);
//
//      if (transformed[2] < NEAR_CLIP)
//         transformed[2] = NEAR_CLIP;
//
//      lzi0 = 1.0 / transformed[2];
  fld st(0)   // local[0] | local[0] | local[1] | local[2]
  fmul ds:dword ptr[vpn+0]   // zm0 | local[0] | local[1] | local[2]
  fld st(1)   // local[0] | zm0 | local[0] | local[1] |
//  local[2]
  fmul ds:dword ptr[vright+0]   // xm0 | zm0 | local[0] | local[1] | local[2]
  fxch st(2)   // local[0] | zm0 | xm0 | local[1] | local[2]
  fmul ds:dword ptr[vup+0]   // ym0 |  zm0 | xm0 | local[1] | local[2]
  fld st(3)   // local[1] | ym0 |  zm0 | xm0 | local[1] |
//  local[2]
  fmul ds:dword ptr[vpn+4]   // zm1 | ym0 | zm0 | xm0 | local[1] |
//  local[2]
  fld st(4)   // local[1] | zm1 | ym0 | zm0 | xm0 |
//  local[1] | local[2]
  fmul ds:dword ptr[vright+4]   // xm1 | zm1 | ym0 |  zm0 | xm0 |
//  local[1] | local[2]
  fxch st(5)   // local[1] | zm1 | ym0 | zm0 | xm0 |
//  xm1 | local[2]
  fmul ds:dword ptr[vup+4]   // ym1 | zm1 | ym0 | zm0 | xm0 |
//  xm1 | local[2]
  fxch st(1)   // zm1 | ym1 | ym0 | zm0 | xm0 |
//  xm1 | local[2]
  faddp st(3),st(0)   // ym1 | ym0 | zm2 | xm0 | xm1 | local[2]
  fxch st(3)   // xm0 | ym0 | zm2 | ym1 | xm1 | local[2]
  faddp st(4),st(0)   // ym0 | zm2 | ym1 | xm2 | local[2]
  faddp st(2),st(0)   // zm2 | ym2 | xm2 | local[2]
  fld st(3)   // local[2] | zm2 | ym2 | xm2 | local[2]
  fmul ds:dword ptr[vpn+8]   // zm3 | zm2 | ym2 | xm2 | local[2]
  fld st(4)   // local[2] | zm3 | zm2 | ym2 | xm2 | local[2]
  fmul ds:dword ptr[vright+8]   // xm3 | zm3 | zm2 | ym2 | xm2 | local[2]
  fxch st(5)   // local[2] | zm3 | zm2 | ym2 | xm2 | xm3
  fmul ds:dword ptr[vup+8]   // ym3 | zm3 | zm2 | ym2 | xm2 | xm3
  fxch st(1)   // zm3 | ym3 | zm2 | ym2 | xm2 | xm3
  faddp st(2),st(0)   // ym3 | zm4 | ym2 | xm2 | xm3
  fxch st(4)   // xm3 | zm4 | ym2 | xm2 | ym3
  faddp st(3),st(0)   // zm4 | ym2 | xm4 | ym3
  fxch st(1)   // ym2 | zm4 | xm4 | ym3
  faddp st(3),st(0)   // zm4 | xm4 | ym4

  fcom ds:dword ptr[Lfp_near_clip]
  fnstsw ax
  test ah,1
  jz LNoClip
  fstp st(0)
  fld ds:dword ptr[Lfp_near_clip]

LNoClip:

  fdivr ds:dword ptr[float_1]   // lzi0 | x | y
  fxch st(1)   // x | lzi0 | y

//   // FIXME: build x/yscale into transform?
//      scale = xscale * lzi0;
//      u0 = (xcenter + scale*transformed[0]);
  fld ds:dword ptr[xscale]   // xscale | x | lzi0 | y
  fmul st(0),st(2)   // scale | x | lzi0 | y
  fmulp st(1),st(0)   // scale*x | lzi0 | y
  fadd ds:dword ptr[xcenter]   // u0 | lzi0 | y

//      if (u0 < r_refdef.fvrectx_adj)
//         u0 = r_refdef.fvrectx_adj;
//      if (u0 > r_refdef.fvrectright_adj)
//         u0 = r_refdef.fvrectright_adj;
// FIXME: use integer compares of floats?
  fcom ds:dword ptr[r_refdef+rd_fvrectx_adj]
  fnstsw ax
  test ah,1
  jz LClampP0
  fstp st(0)
  fld ds:dword ptr[r_refdef+rd_fvrectx_adj]
LClampP0:
  fcom ds:dword ptr[r_refdef+rd_fvrectright_adj]
  fnstsw ax
  test ah,045h
  jnz LClampP1
  fstp st(0)
  fld ds:dword ptr[r_refdef+rd_fvrectright_adj]
LClampP1:

  fld st(1)   // lzi0 | u0 | lzi0 | y

//      scale = yscale * lzi0;
//      v0 = (ycenter - scale*transformed[1]);
  fmul ds:dword ptr[yscale]   // scale | u0 | lzi0 | y
  fmulp st(3),st(0)   // u0 | lzi0 | scale*y
  fxch st(2)   // scale*y | lzi0 | u0
  fsubr ds:dword ptr[ycenter]   // v0 | lzi0 | u0

//      if (v0 < r_refdef.fvrecty_adj)
//         v0 = r_refdef.fvrecty_adj;
//      if (v0 > r_refdef.fvrectbottom_adj)
//         v0 = r_refdef.fvrectbottom_adj;
// FIXME: use integer compares of floats?
  fcom ds:dword ptr[r_refdef+rd_fvrecty_adj]
  fnstsw ax
  test ah,1
  jz LClampP2
  fstp st(0)
  fld ds:dword ptr[r_refdef+rd_fvrecty_adj]
LClampP2:
  fcom ds:dword ptr[r_refdef+rd_fvrectbottom_adj]
  fnstsw ax
  test ah,045h
  jnz LClampP3
  fstp st(0)
  fld ds:dword ptr[r_refdef+rd_fvrectbottom_adj]
LClampP3:
  ret
end;

{$ENDIF}

initialization
  Sys_SetFPCW;
end.
