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

unit r_edgea;
{----------------------------------------------------------------------------}
{                                                                            }
{ File(s): r_edgea.asm                                                          }
{                                                                            }
{ Initial conversion by : CodeFusion (michael@skovslund.dk)                  }
{ Initial conversion on : 16-July-2002                                        }
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
{  r_local,                                                                  }
{  r_main,                                                                   }
{  cvar,                                                                     }
{  r_model,                                                                  }
{----------------------------------------------------------------------------}
{  These variables has been moved from Edge.pas to this one because otherwise}
{  we would have had circular references.                                    }
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
{----------------------------------------------------------------------------}

interface

uses
  qasm_inc,
  r_local,
  r_main,
  r_model,
  r_varsa;

type
  TEdgeCode = procedure;

var
  edge_head: edge_t;
  edge_tail: edge_t;
  edge_aftertail: edge_t;
  edge_head_u_shift20: Integer;
  edge_tail_u_shift20: Integer;

  current_iv: Integer;
  fv: Single;
  span_p: espan_p;

  surfaces: surf_p;

{$IFDEF   id386}
var
  R_EdgeCodeStart: TEdgeCode;
  R_EdgeCodeEnd: TEdgeCode;

procedure R_InsertNewEdges(edgestoadd: edge_p; edgelist: edge_p);
procedure R_RemoveEdges(pedge: edge_p);
procedure R_StepActiveU(pedge: edge_p);
procedure R_GenerateSpans;
procedure R_SurfacePatch;
{$ENDIF}

implementation

{$IFDEF   id386}
var
  Ltemp: Integer; // 0
  float_1_div_0100000h: Single; //035800000h   ; 1.0/(float)0x100000
  float_point_999: Single; // 0.999
  float_1_point_001: Single; // 1.001

// FIX, for code self modification, used in original asm code.
  LPatch0_Value: Pointer;
  LPatch2_Value: Pointer;
  LPatch3_Value: Pointer;
  LPatch4_Value: Pointer;

procedure R_InsertNewEdges(edgestoadd: edge_p; edgelist: edge_p);
const
  edgestoadd_ = 4 + 8; //note odd stack offsets because of interleaving
  edgelist_ = 8 + 12; //with pushes
asm
@_R_EdgeCodeStart:
  push  edi
  push  esi   // preserve register variables

  mov   edx,ds:dword ptr[edgestoadd_+ebp]
  push  ebx
  mov   ecx,ds:dword ptr[edgelist_+ebp]

@LDoNextEdge:
  mov   eax,ds:dword ptr[et_u+edx]
  mov   edi,edx

@LContinueSearch:
  mov   ebx,ds:dword ptr[et_u+ecx]
  mov   esi,ds:dword ptr[et_next+ecx]
  cmp   eax,ebx
  jle   @LAddedge
  mov   ebx,ds:dword ptr[et_u+esi]
  mov   ecx,ds:dword ptr[et_next+esi]
  cmp   eax,ebx
  jle   @LAddedge2
  mov   ebx,ds:dword ptr[et_u+ecx]
  mov   esi,ds:dword ptr[et_next+ecx]
  cmp   eax,ebx
  jle   @LAddedge
  mov   ebx,ds:dword ptr[et_u+esi]
  mov   ecx,ds:dword ptr[et_next+esi]
  cmp   eax,ebx
  jg    @LContinueSearch

@LAddedge2:
  mov   edx,ds:dword ptr[et_next+edx]
  mov   ebx,ds:dword ptr[et_prev+esi]
  mov   ds:dword ptr[et_next+edi],esi
  mov   ds:dword ptr[et_prev+edi],ebx
  mov   ds:dword ptr[et_next+ebx],edi
  mov   ds:dword ptr[et_prev+esi],edi
  mov   ecx,esi

  cmp   edx,0
  jnz   @LDoNextEdge
  jmp   @LDone

  {$align 4}
@LAddedge:
  mov   edx,ds:dword ptr[et_next+edx]
  mov   ebx,ds:dword ptr[et_prev+ecx]
  mov   ds:dword ptr[et_next+edi],ecx
  mov   ds:dword ptr[et_prev+edi],ebx
  mov   ds:dword ptr[et_next+ebx],edi
  mov   ds:dword ptr[et_prev+ecx],edi

  cmp   edx,0
  jnz   @LDoNextEdge

@LDone:
  pop   ebx   // restore register variables
  pop   esi
  pop   edi
end;

procedure R_RemoveEdges(pedge: edge_p);
const
  predge = 4 + 4;
asm
  push  ebx
  mov   eax,ds:dword ptr[predge+ebp]

@Lre_loop:
  mov   ecx,ds:dword ptr[et_next+eax]
  mov   ebx,ds:dword ptr[et_nextremove+eax]
  mov   edx,ds:dword ptr[et_prev+eax]
  test  ebx,ebx
  mov   ds:dword ptr[et_prev+ecx],edx
  jz    @Lre_done
  mov   ds:dword ptr[et_next+edx],ecx

  mov   ecx,ds:dword ptr[et_next+ebx]
  mov   edx,ds:dword ptr[et_prev+ebx]
  mov   eax,ds:dword ptr[et_nextremove+ebx]
  mov   ds:dword ptr[et_prev+ecx],edx
  test  eax,eax
  mov   ds:dword ptr[et_next+edx],ecx
  jnz   @Lre_loop

  jmp   @Done

@Lre_done:
  mov   ds:dword ptr[et_next+edx],ecx
@Done:
  pop   ebx
end;

procedure R_StepActiveU(pedge: edge_p);
const
  pedgelist = 4 + 4; // note odd stack offset because of interleaving
                    // with pushes
asm
  push  edi
  mov   edx,ds:dword ptr[pedgelist+ebp]
  push  esi   // preserve register variables
  push  ebx

  mov   esi,ds:dword ptr[et_prev+edx]

@LNewEdge:
  mov   edi,ds:dword ptr[et_u+esi]

@LNextEdge:
  mov   eax,ds:dword ptr[et_u+edx]
  mov   ebx,ds:dword ptr[et_u_step+edx]
  add   eax,ebx
  mov   esi,ds:dword ptr[et_next+edx]
  mov   ds:dword ptr[et_u+edx],eax
  cmp   eax,edi
  jl    @LPushBack

  mov   edi,ds:dword ptr[et_u+esi]
  mov   ebx,ds:dword ptr[et_u_step+esi]
  add   edi,ebx
  mov   edx,ds:dword ptr[et_next+esi]
  mov   ds:dword ptr[et_u+esi],edi
  cmp   edi,eax
  jl    @LPushBack2

  mov   eax,ds:dword ptr[et_u+edx]
  mov   ebx,ds:dword ptr[et_u_step+edx]
  add   eax,ebx
  mov   esi,ds:dword ptr[et_next+edx]
  mov   ds:dword ptr[et_u+edx],eax
  cmp   eax,edi
  jl    @LPushBack

  mov   edi,ds:dword ptr[et_u+esi]
  mov   ebx,ds:dword ptr[et_u_step+esi]
  add   edi,ebx
  mov   edx,ds:dword ptr[et_next+esi]
  mov   ds:dword ptr[et_u+esi],edi
  cmp   edi,eax
  jnl   @LNextEdge

@LPushBack2:
  mov   ebx,edx
  mov   eax,edi
  mov   edx,esi
  mov   esi,ebx

@LPushBack:
// push it back to keep it sorted
  mov   ecx,ds:dword ptr[et_prev+edx]
  mov   ebx,ds:dword ptr[et_next+edx]

// done if the -1 in edge_aftertail triggered this
  cmp   edx,offset edge_aftertail
  jz    @LUDone

// pull the edge out of the edge list
  mov   edi,ds:dword ptr[et_prev+ecx]
  mov   ds:dword ptr[et_prev+esi],ecx
  mov   ds:dword ptr[et_next+ecx],ebx

// find out where the edge goes in the edge list
@LPushBackLoop:
  mov   ecx,ds:dword ptr[et_prev+edi]
  mov   ebx,ds:dword ptr[et_u+edi]
  cmp   eax,ebx
  jnl   @LPushBackFound

  mov   edi,ds:dword ptr[et_prev+ecx]
  mov   ebx,ds:dword ptr[et_u+ecx]
  cmp   eax,ebx
  jl    @LPushBackLoop

  mov   edi,ecx

// put the edge back into the edge list
@LPushBackFound:
  mov   ebx,ds:dword ptr[et_next+edi]
  mov   ds:dword ptr[et_prev+edx],edi
  mov   ds:dword ptr[et_next+edx],ebx
  mov   ds:dword ptr[et_next+edi],edx
  mov   ds:dword ptr[et_prev+ebx],edx

  mov   edx,esi
  mov   esi,ds:dword ptr[et_prev+esi]

  cmp   edx,offset edge_tail
  jnz   @LNewEdge

@LUDone:
  pop   ebx   // restore register variables
  pop   esi
  pop   edi
end;

procedure R_GenerateSpans;
const
  surf = 4; // note this is loaded before any pushes
asm
  jmp     @_R_GenerateSpans

  {$align 4}
// Called within this function
@TrailingEdge:
  mov     eax,ds:dword ptr[st_spanstate+esi]   // check for edge inversion
  dec     eax
  jnz     @LInverted

  mov     ds:dword ptr[st_spanstate+esi],eax
  mov     ecx,ds:dword ptr[st_insubmodel+esi]
//  mov     edx,ds:dword ptr[12345678h]   // surfaces[1].st_next
  mov     edx,ds:dword ptr[LPatch0_Value]   // surfaces[1].st_next

@LPatch0:
  mov     eax,ds:dword ptr[_r_bmodelactive]
  sub     eax,ecx
  cmp     edx,esi
  mov     ds:dword ptr[_r_bmodelactive],eax
  jnz     @LNoEmit   // surface isn't on top, just remove

// emit a span (current top going away)
  mov     eax,ds:dword ptr[et_u+ebx]
  shr     eax,20   // iu = integral pixel u
  mov     edx,ds:dword ptr[st_last_u+esi]
  mov     ecx,ds:dword ptr[st_next+esi]
  cmp     eax,edx
  jle     @LNoEmit2   // iu <= surf->last_u, so nothing to emit

  mov     ds:dword ptr[st_last_u+ecx],eax   // surf->next->last_u = iu;
  sub     eax,edx
  mov     ds:dword ptr[espan_t_u+ebp],edx   // span->u = surf->last_u;

  mov     ds:dword ptr[espan_t_count+ebp],eax   // span->count = iu - span->u;
  mov     eax,ds:dword ptr[current_iv]
  mov     ds:dword ptr[espan_t_v+ebp],eax   // span->v = current_iv;
  mov     eax,ds:dword ptr[st_spans+esi]
  mov     ds:dword ptr[espan_t_pnext+ebp],eax   // span->pnext = surf->spans;
  mov     ds:dword ptr[st_spans+esi],ebp   // surf->spans = span;
  add     ebp,offset espan_t_size

  mov     edx,ds:dword ptr[st_next+esi]   // remove the surface from the surface
  mov     esi,ds:dword ptr[st_prev+esi]   // stack

  mov     ds:dword ptr[st_next+esi],edx
  mov     ds:dword ptr[st_prev+edx],esi
  ret

@LNoEmit2:
  mov     ds:dword ptr[st_last_u+ecx],eax   // surf->next->last_u = iu;
  mov     edx,ds:dword ptr[st_next+esi]   // remove the surface from the surface
  mov     esi,ds:dword ptr[st_prev+esi]   // stack

  mov     ds:dword ptr[st_next+esi],edx
  mov     ds:dword ptr[st_prev+edx],esi
  ret

@LNoEmit:
  mov     edx,ds:dword ptr[st_next+esi]   // remove the surface from the surface
  mov     esi,ds:dword ptr[st_prev+esi]   // stack

  mov     ds:dword ptr[st_next+esi],edx
  mov     ds:dword ptr[st_prev+edx],esi
  ret

@LInverted:
  mov     ds:dword ptr[st_spanstate+esi],eax
  ret

//--------------------------------------------------------------------

// trailing edge only
@Lgs_trailing:
  push    offset @Lgs_nextedge
  jmp     @TrailingEdge

// Entry point for this function.
{$align 4}
@_R_GenerateSpans:
  push    ebp   // preserve caller's stack frame
  push    edi
  push    esi   // preserve register variables
  push    ebx

// clear active surfaces to just the background surface
  mov     eax,ds:dword ptr[surfaces]
  mov     edx,ds:dword ptr[edge_head_u_shift20]
  add     eax,offset st_size
// %ebp = span_p throughout
  mov     ebp,ds:dword ptr[span_p]

  mov     ds:dword ptr[_r_bmodelactive],0

  mov     ds:dword ptr[st_next+eax],eax
  mov     ds:dword ptr[st_prev+eax],eax
  mov     ds:dword ptr[st_last_u+eax],edx
  mov     ebx,ds:dword ptr[edge_head+et_next]   // edge=edge_head.next

// generate spans
  cmp     ebx,offset edge_tail   // done if empty list
  jz      @Lgs_lastspan

@Lgs_edgeloop:
  mov     edi,ds:dword ptr[et_surfs+ebx]
  mov     eax,ds:dword ptr[surfaces]
  mov     esi,edi
  and     edi,0FFFF0000h
  and     esi,0FFFFh
  jz      @Lgs_leading   // not a trailing edge

// it has a left surface, so a surface is going away for this span
  shl     esi,offset SURF_T_SHIFT
  add     esi,eax
  test    edi,edi
  jz      @Lgs_trailing

// both leading and trailing
  call    @TrailingEdge
  mov     eax,ds:dword ptr[surfaces]

// ---------------------------------------------------------------
// handle a leading edge
// ---------------------------------------------------------------

@Lgs_leading:
  shr     edi,16-SURF_T_SHIFT
  mov     eax,ds:dword ptr[surfaces]
  add     edi,eax
//  mov     esi,ds:dword ptr[12345678h]   // surf2 = surfaces[1].next;
  mov     esi,ds:dword ptr[LPatch2_Value]   // surf2 = surfaces[1].next;
@LPatch2:
  mov     edx,ds:dword ptr[st_spanstate+edi]
  mov     eax,ds:dword ptr[st_insubmodel+edi]
  test    eax,eax
  jnz     @Lbmodel_leading

// handle a leading non-bmodel edge

// don't start a span if this is an inverted span, with the end edge preceding
// the start edge (that is, we've already seen the end edge)
  test    edx,edx
  jnz     @Lxl_done


// if (surf->key < surf2->key)
//      goto newtop;
  inc     edx
  mov     eax,ds:dword ptr[st_key+edi]
  mov     ds:dword ptr[st_spanstate+edi],edx
  mov     ecx,ds:dword ptr[st_key+esi]
  cmp     eax,ecx
  jl      @Lnewtop

// main sorting loop to search through surface stack until insertion point
// found. Always terminates because background surface is sentinel
// do
// {
//       surf2 = surf2->next;
// } while (surf->key >= surf2->key);
@Lsortloopnb:
  mov     esi,ds:dword ptr[st_next+esi]
  mov     ecx,ds:dword ptr[st_key+esi]
  cmp     eax,ecx
  jge     @Lsortloopnb

  jmp     @LInsertAndExit


// handle a leading bmodel edge
 {$align 4}
@Lbmodel_leading:

// don't start a span if this is an inverted span, with the end edge preceding
// the start edge (that is, we've already seen the end edge)
  test    edx,edx
  jnz     @Lxl_done

  mov     ecx,ds:dword ptr[_r_bmodelactive]
  inc     edx
  inc     ecx
  mov     ds:dword ptr[st_spanstate+edi],edx
  mov     ds:dword ptr[_r_bmodelactive],ecx

// if (surf->key < surf2->key)
//      goto newtop;
  mov     eax,ds:dword ptr[st_key+edi]
  mov     ecx,ds:dword ptr[st_key+esi]
  cmp     eax,ecx
  jl      @Lnewtop

// if ((surf->key == surf2->key) && surf->insubmodel)
// {
  jz      @Lzcheck_for_newtop

// main sorting loop to search through surface stack until insertion point
// found. Always terminates because background surface is sentinel
// do
// {
//       surf2 = surf2->next;
// } while (surf->key > surf2->key);
@Lsortloop:
  mov     esi,ds:dword ptr[st_next+esi]
  mov     ecx,ds:dword ptr[st_key+esi]
  cmp     eax,ecx
  jg      @Lsortloop

  jne     @LInsertAndExit

// Do 1/z sorting to see if we've arrived in the right position
  mov     eax,ds:dword ptr[et_u+ebx]
  sub     eax,0FFFFFh
  mov     ds:dword ptr[Ltemp],eax
  fild    ds:dword ptr[Ltemp]

  fmul    ds:dword ptr[float_1_div_0100000h]   // fu = (float)(edge->u - 0xFFFFF) *
//      (1.0 / 0x100000);

  fld     st(0)   // fu | fu
  fmul    ds:dword ptr[st_d_zistepu+edi]   // fu*surf->d_zistepu | fu
  fld     ds:dword ptr[fv]   // fv | fu*surf->d_zistepu | fu
  fmul    ds:dword ptr[st_d_zistepv+edi]   // fv*surf->d_zistepv | fu*surf->d_zistepu | fu
  fxch    st(1)   // fu*surf->d_zistepu | fv*surf->d_zistepv | fu
  fadd    ds:dword ptr[st_d_ziorigin+edi]   // fu*surf->d_zistepu + surf->d_ziorigin |
//  fv*surf->d_zistepv | fu

  fld     ds:dword ptr[st_d_zistepu+esi]   // surf2->d_zistepu |
//  fu*surf->d_zistepu + surf->d_ziorigin |
//  fv*surf->d_zistepv | fu
  fmul    st(0),st(3)   // fu*surf2->d_zistepu |
//  fu*surf->d_zistepu + surf->d_ziorigin |
//  fv*surf->d_zistepv | fu
  fxch    st(1)   // fu*surf->d_zistepu + surf->d_ziorigin |
//  fu*surf2->d_zistepu |
//  fv*surf->d_zistepv | fu
  faddp   st(2),st(0)   // fu*surf2->d_zistepu | newzi | fu

  fld     ds:dword ptr[fv]   // fv | fu*surf2->d_zistepu | newzi | fu
  fmul    ds:dword ptr[st_d_zistepv+esi]   // fv*surf2->d_zistepv |
//  fu*surf2->d_zistepu | newzi | fu
  fld     st(2)   // newzi | fv*surf2->d_zistepv |
//  fu*surf2->d_zistepu | newzi | fu
  fmul    ds:dword ptr[float_point_999]   // newzibottom | fv*surf2->d_zistepv |
//  fu*surf2->d_zistepu | newzi | fu

  fxch    st(2)   // fu*surf2->d_zistepu | fv*surf2->d_zistepv |
//  newzibottom | newzi | fu
  fadd    ds:dword ptr[st_d_ziorigin+esi]   // fu*surf2->d_zistepu + surf2->d_ziorigin |
//  fv*surf2->d_zistepv | newzibottom | newzi |
//  fu
  faddp   st(1),st(0)   // testzi | newzibottom | newzi | fu
  fxch    st(1)   // newzibottom | testzi | newzi | fu

// if (newzibottom >= testzi)
//     goto Lgotposition;

  fcomp   st(1)   // testzi | newzi | fu

  fxch    st(1)   // newzi | testzi | fu
  fmul    ds:dword ptr[float_1_point_001]   // newzitop | testzi | fu
  fxch    st(1)   // testzi | newzitop | fu

  fnstsw  ax
  test    ah,001h
  jz      @Lgotposition_fpop3

// if (newzitop >= testzi)
// {

  fcomp   st(1)   // newzitop | fu
  fnstsw  ax
  test    ah,045h
  jz      @Lsortloop_fpop2

// if (surf->d_zistepu >= surf2->d_zistepu)
//     goto newtop;

  fld     ds:dword ptr[st_d_zistepu+edi]   // surf->d_zistepu | newzitop| fu
  fcomp   ds:dword ptr[st_d_zistepu+esi]   // newzitop | fu
  fnstsw  ax
  test    ah,001h
  jz      @Lgotposition_fpop2

  fstp    st(0)   // clear the FPstack
  fstp    st(0)
  mov     eax,ds:dword ptr[st_key+edi]
  jmp     @Lsortloop


@Lgotposition_fpop3:
  fstp    st(0)
@Lgotposition_fpop2:
  fstp    st(0)
  fstp    st(0)
  jmp     @LInsertAndExit


// emit a span (obscures current top)

@Lnewtop_fpop3:
  fstp    st(0)
@Lnewtop_fpop2:
  fstp    st(0)
  fstp    st(0)
  mov     eax,ds:dword ptr[st_key+edi]   // reload the sorting key

@Lnewtop:
  mov     eax,ds:dword ptr[et_u+ebx]
  mov     edx,ds:dword ptr[st_last_u+esi]
  shr     eax,20   // iu = integral pixel u
  mov     ds:dword ptr[st_last_u+edi],eax   // surf->last_u = iu;
  cmp     eax,edx
  jle     @LInsertAndExit   // iu <= surf->last_u, so nothing to emit

  sub     eax,edx
  mov     ds:dword ptr[espan_t_u+ebp],edx   // span->u = surf->last_u;

  mov     ds:dword ptr[espan_t_count+ebp],eax   // span->count = iu - span->u;
  mov     eax,ds:dword ptr[current_iv]
  mov     ds:dword ptr[espan_t_v+ebp],eax   // span->v = current_iv;
  mov     eax,ds:dword ptr[st_spans+esi]
  mov     ds:dword ptr[espan_t_pnext+ebp],eax   // span->pnext = surf->spans;
  mov     ds:dword ptr[st_spans+esi],ebp   // surf->spans = span;
  add     ebp,offset espan_t_size

@LInsertAndExit:
// insert before surf2
  mov     ds:dword ptr[st_next+edi],esi   // surf->next = surf2;
  mov     eax,ds:dword ptr[st_prev+esi]
  mov     ds:dword ptr[st_prev+edi],eax   // surf->prev = surf2->prev;
  mov     ds:dword ptr[st_prev+esi],edi   // surf2->prev = surf;
  mov     ds:dword ptr[st_next+eax],edi   // surf2->prev->next = surf;

// ---------------------------------------------------------------
// leading edge done
// ---------------------------------------------------------------

// ---------------------------------------------------------------
// see if there are any more edges
// ---------------------------------------------------------------

@Lgs_nextedge:
  mov     ebx,ds:dword ptr[et_next+ebx]
  cmp     ebx,offset edge_tail
  jnz     @Lgs_edgeloop

// clean up at the right edge
@Lgs_lastspan:

// now that we've reached the right edge of the screen, we're done with any
// unfinished surfaces, so emit a span for whatever's on top
//  mov     esi,ds:dword ptr[12345678h]   // surfaces[1].st_next
  mov     esi,ds:dword ptr[LPatch3_Value]   // surfaces[1].st_next
@LPatch3:
  mov     eax,ds:dword ptr[edge_tail_u_shift20]
  xor     ecx,ecx
  mov     edx,ds:dword ptr[st_last_u+esi]
  sub     eax,edx
  jle     @Lgs_resetspanstate

  mov     ds:dword ptr[espan_t_u+ebp],edx
  mov     ds:dword ptr[espan_t_count+ebp],eax
  mov     eax,ds:dword ptr[current_iv]
  mov     ds:dword ptr[espan_t_v+ebp],eax
  mov     eax,ds:dword ptr[st_spans+esi]
  mov     ds:dword ptr[espan_t_pnext+ebp],eax
  mov     ds:dword ptr[st_spans+esi],ebp
  add     ebp,offset espan_t_size

// reset spanstate for all surfaces in the surface stack
@Lgs_resetspanstate:
  mov     ds:dword ptr[st_spanstate+esi],ecx
  mov     esi,ds:dword ptr[st_next+esi]
//  cmp     esi,012345678h   // &surfaces[1]
  cmp     esi,ds:dword ptr[LPatch4_Value]
@LPatch4:
  jnz     @Lgs_resetspanstate

// store the final span_p
  mov     ds:dword ptr[span_p],ebp

  pop     ebx   // restore register variables
  pop     esi
  pop     edi
  pop     ebp   // restore the caller's stack frame
  jmp     @Exit_Func


// ---------------------------------------------------------------
// 1/z sorting for bmodels in the same leaf
// ---------------------------------------------------------------
 {$align 4}
@Lxl_done:
  inc     edx
  mov     ds:dword ptr[st_spanstate+edi],edx

  jmp     @Lgs_nextedge


 {$align 4}
@Lzcheck_for_newtop:
  mov     eax,ds:dword ptr[et_u+ebx]
  sub     eax,0FFFFFh
  mov     ds:dword ptr[Ltemp],eax
  fild    ds:dword ptr[Ltemp]

  fmul    ds:dword ptr[float_1_div_0100000h]   // fu = (float)(edge->u - 0xFFFFF) *
//      (1.0 / 0x100000)//

  fld     st(0)   // fu | fu
  fmul    ds:dword ptr[st_d_zistepu+edi]   // fu*surf->d_zistepu | fu
  fld     ds:dword ptr[fv]   // fv | fu*surf->d_zistepu | fu
  fmul    ds:dword ptr[st_d_zistepv+edi]   // fv*surf->d_zistepv | fu*surf->d_zistepu | fu
  fxch    st(1)   // fu*surf->d_zistepu | fv*surf->d_zistepv | fu
  fadd    ds:dword ptr[st_d_ziorigin+edi]   // fu*surf->d_zistepu + surf->d_ziorigin |
//  fv*surf->d_zistepv | fu

  fld     ds:dword ptr[st_d_zistepu+esi]   // surf2->d_zistepu |
//  fu*surf->d_zistepu + surf->d_ziorigin |
//  fv*surf->d_zistepv | fu
  fmul    st(0),st(3)   // fu*surf2->d_zistepu |
//  fu*surf->d_zistepu + surf->d_ziorigin |
//  fv*surf->d_zistepv | fu
  fxch    st(1)   // fu*surf->d_zistepu + surf->d_ziorigin |
//  fu*surf2->d_zistepu |
//  fv*surf->d_zistepv | fu
  faddp   st(2),st(0)   // fu*surf2->d_zistepu | newzi | fu

  fld     ds:dword ptr[fv]   // fv | fu*surf2->d_zistepu | newzi | fu
  fmul    ds:dword ptr[st_d_zistepv+esi]   // fv*surf2->d_zistepv |
//  fu*surf2->d_zistepu | newzi | fu
  fld     st(2)   // newzi | fv*surf2->d_zistepv |
//  fu*surf2->d_zistepu | newzi | fu
  fmul    ds:dword ptr[float_point_999]   // newzibottom | fv*surf2->d_zistepv |
//  fu*surf2->d_zistepu | newzi | fu

  fxch    st(2)   // fu*surf2->d_zistepu | fv*surf2->d_zistepv |
//  newzibottom | newzi | fu
  fadd    ds:dword ptr[st_d_ziorigin+esi]   // fu*surf2->d_zistepu + surf2->d_ziorigin |
//  fv*surf2->d_zistepv | newzibottom | newzi |
//  fu
  faddp   st(1),st(0)   // testzi | newzibottom | newzi | fu
  fxch    st(1)   // newzibottom | testzi | newzi | fu

// if (newzibottom >= testzi)
//     goto newtop//

  fcomp   st(1)   // testzi | newzi | fu

  fxch    st(1)   // newzi | testzi | fu
  fmul    ds:dword ptr[float_1_point_001]   // newzitop | testzi | fu
  fxch    st(1)   // testzi | newzitop | fu

  fnstsw  ax
  test    ah,001h
  jz      @Lnewtop_fpop3

// if (newzitop >= testzi)
//

  fcomp   st(1)   // newzitop | fu
  fnstsw  ax
  test    ah,045h
  jz      @Lsortloop_fpop2

// if (surf->d_zistepu >= surf2->d_zistepu)
//     goto newtop//

  fld     ds:dword ptr[st_d_zistepu+edi]   // surf->d_zistepu | newzitop | fu
  fcomp   ds:dword ptr[st_d_zistepu+esi]   // newzitop | fu
  fnstsw  ax
  test    ah,001h
  jz      @Lnewtop_fpop2

@Lsortloop_fpop2:
  fstp    st(0)   // clear the FP stack
  fstp    st(0)
  mov     eax,ds:dword ptr[st_key+edi]
  jmp     @Lsortloop

@Exit_Func:
end;

//----------------------------------------------------------------------
// Surface array address code patching routine
//----------------------------------------------------------------------

procedure R_SurfacePatch;
asm
{$align 4}
 mov eax,ds:dword ptr[surfaces]
 add eax,offset st_size
 mov ds:dword ptr[LPatch4_Value-4],eax

 add eax,offset st_next
 mov ds:dword ptr[LPatch0_Value-4],eax
 mov ds:dword ptr[LPatch2_Value-4],eax
 mov ds:dword ptr[LPatch3_Value-4],eax
end;
{$ENDIF}

initialization
{$IFDEF   id386}
  Ltemp := 0;
  float_1_div_0100000h := $035800000; //1.0/(float)0x100000
  float_point_999 := 0.999;
  float_1_point_001 := 1.001;
// these routines should not be called.
  R_EdgeCodeStart := TEdgeCode(Addr(R_InsertNewEdges));
  R_EdgeCodeEnd := TEdgeCode(Addr(R_SurfacePatch));
{$ENDIF}

end.
