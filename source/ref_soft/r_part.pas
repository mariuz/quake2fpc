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
{ File(s): r_part.c                                                          }
{                                                                            }
{ Initial conversion by : Gargoylle[LtK](gargoylle_ltk@hotmail.com           }
{ Initial conversion on : 09-Jul-2002                                        }
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
{ * Still dependent (to compile correctly) on:                               }
{ r_main                                                                     }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{ * VERRY IMPORTANT: some of the routines in r_part.c are declared as        }
{      __declspec(naked). As far as I know this means that no frame stack    }
{      is created for them. I however have no knoledge of how to do this     }
{      in Delphi so currently __declspec(naked) is IGNORED and the routines  }
{      are just declared as any other normal routines. A suitable solution   }
{      must however be found.                                                }
{ * conversion started on 09-Jul-2002                                        }
{----------------------------------------------------------------------------}

// =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
//
//  PLEASE NOTE:
//   1) all original comments will be retained. My own comments will begin with
//      "GARGO".
//   2) this file does not have a .H file to go with it
//
// =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

unit r_part;

interface

uses
  q_shared,
  ref,
  r_local,
  rw_imp; // see the note at R_DrawParticles

{$IFDEF id386}
{$IFNDEF __linux__}

// GARGO: GARGO_ByteFunc required to declare variables needed by R_DrawParticle
type
  GARGO_ByteFunc = function: byte;

var
  s_prefetch_address: Cardinal;

  // GARGO: the following are the routines declared in r_part.c
  //   As I have mentioned before, some are originally declared
  //   as __declspec(naked). Currently I have ignored it so the
  //   routines are declared as any normal routine would be.
//   procedure BlendParticle33;
//   procedure BlendParticle66;
//   procedure BlendParticle100;
{$ENDIF} // __linux__
{$ELSE}
//   procedure BlendParticle33;
//   procedure BlendParticle66;
//   procedure BlendParticle100;
{$ENDIF}

procedure R_DrawParticles;

implementation

uses
  r_misc,
  r_main,
  DelphiTypes,
  SysUtils;

const
  PARTICLE_33 = 0;
  PARTICLE_66 = 1;
  PARTICLE_OPAQUE = 2;

type
  partparms_p = ^partparms_t;
  ppartparms_t = partparms_p;
  partparms_t = record
    particle: particle_p;
    level: integer;
    color: integer;
  end;
  TPartParms = partparms_t;
  PPartParms = ppartparms_t;

var
  r_pright: vec3_t;
  r_pup: vec3_t;
  r_ppn: vec3_t;
  partparms: partparms_t;

{$IFDEF id386}
{$IFNDEF __linux__}
(*
** BlendParticleXX
**
** Inputs:
** EAX = color
** EDI = pdest
**
** Scratch:
** EBX = scratch (dstcolor)
** EBP = scratch
**
** Outputs:
** none
*)

procedure BlendParticle33;
asm
  //   return vid.alphamap[color + dstcolor*256];
  mov ebp, vid.alphamap
  xor ebx, ebx

  mov bl,  byte ptr [edi]
  shl ebx, 8

  add ebp, ebx
  add ebp, eax

  mov al,  byte ptr [ebp]

  mov byte ptr [edi], al
end;

procedure BlendParticle66;
asm
  //   return vid.alphamap[pcolor*256 + dstcolor];
  mov ebp, vid.alphamap
  xor ebx, ebx

  shl eax,  8
  mov bl,   byte ptr [edi]

  add ebp, ebx
  add ebp, eax

  mov al,  byte ptr [ebp]

  mov byte ptr [edi], al
end;

procedure BlendParticle100;
asm
  mov   byte ptr [edi], al
end;

{
** R_DrawParticle (asm version)
**
** Since we use __declspec( naked ) we don't have a stack frame
** that we can use.  Since I want to reserve EBP anyway, I tossed
** all the important variables into statics.  This routine isn't
** meant to be re-entrant, so this shouldn't cause any problems
** other than a slightly higher global memory footprint.
**
}

procedure R_DrawParticle;
// GARGO: labels must be defined before they are used, even in
//   assmebler code
label
  blendfunc_33;
label
  blendfunc_66;
label
  done_selecting_blend_func;
label
  check_pix_max;
label
  skip_pix_clamp;
label
  over;
label
  top_of_pix_vert_loop;
label
  top_of_pix_horiz_loop;
label
  end_of_horiz_loop;
label
  end_;
asm
    // GARGO: statics declared here moved to the interface area
    {
    ** save trashed variables
    }
    mov  ebpsave, ebp
    push esi
    push edi

    {
    ** transform the particle
    }
    // VectorSubtract (pparticle->origin, r_origin, local);
    mov  esi, partparms.particle
    fld  dword ptr [esi+0]          // p_o.x
    fsub dword ptr [r_origin+0]     // p_o.x-r_o.x
    fld  dword ptr [esi+4]          // p_o.y | p_o.x-r_o.x
    fsub dword ptr [r_origin+4]     // p_o.y-r_o.y | p_o.x-r_o.x
    fld  dword ptr [esi+8]          // p_o.z | p_o.y-r_o.y | p_o.x-r_o.x
    fsub dword ptr [r_origin+8]     // p_o.z-r_o.z | p_o.y-r_o.y | p_o.x-r_o.x
    fxch st(2)                      // p_o.x-r_o.x | p_o.y-r_o.y | p_o.z-r_o.z
    fstp dword ptr [local+0]        // p_o.y-r_o.y | p_o.z-r_o.z
    fstp dword ptr [local+4]        // p_o.z-r_o.z
    fstp dword ptr [local+8]        // (empty)

   // transformed[0] = DotProduct(local, r_pright);
   // transformed[1] = DotProduct(local, r_pup);
   // transformed[2] = DotProduct(local, r_ppn);
    fld  dword ptr [local+0]        // l.x
    fmul dword ptr [r_pright+0]     // l.x*pr.x
    fld  dword ptr [local+4]        // l.y | l.x*pr.x
    fmul dword ptr [r_pright+4]     // l.y*pr.y | l.x*pr.x
    fld  dword ptr [local+8]        // l.z | l.y*pr.y | l.x*pr.x
    fmul dword ptr [r_pright+8]     // l.z*pr.z | l.y*pr.y | l.x*pr.x
    fxch st(2)                      // l.x*pr.x | l.y*pr.y | l.z*pr.z
    faddp st(1), st                 // l.x*pr.x + l.y*pr.y | l.z*pr.z
    faddp st(1), st                 // l.x*pr.x + l.y*pr.y + l.z*pr.z
    fstp  dword ptr [transformed+0] // (empty)

    fld  dword ptr [local+0]        // l.x
    fmul dword ptr [r_pup+0]        // l.x*pr.x
    fld  dword ptr [local+4]        // l.y | l.x*pr.x
    fmul dword ptr [r_pup+4]        // l.y*pr.y | l.x*pr.x
    fld  dword ptr [local+8]        // l.z | l.y*pr.y | l.x*pr.x
    fmul dword ptr [r_pup+8]        // l.z*pr.z | l.y*pr.y | l.x*pr.x
    fxch st(2)                      // l.x*pr.x | l.y*pr.y | l.z*pr.z
    faddp st(1), st                 // l.x*pr.x + l.y*pr.y | l.z*pr.z
    faddp st(1), st                 // l.x*pr.x + l.y*pr.y + l.z*pr.z
    fstp  dword ptr [transformed+4] // (empty)

    fld  dword ptr [local+0]        // l.x
    fmul dword ptr [r_ppn+0]        // l.x*pr.x
    fld  dword ptr [local+4]        // l.y | l.x*pr.x
    fmul dword ptr [r_ppn+4]        // l.y*pr.y | l.x*pr.x
    fld  dword ptr [local+8]        // l.z | l.y*pr.y | l.x*pr.x
    fmul dword ptr [r_ppn+8]        // l.z*pr.z | l.y*pr.y | l.x*pr.x
    fxch st(2)                      // l.x*pr.x | l.y*pr.y | l.z*pr.z
    faddp st(1), st                 // l.x*pr.x + l.y*pr.y | l.z*pr.z
    faddp st(1), st                 // l.x*pr.x + l.y*pr.y + l.z*pr.z
    fstp  dword ptr [transformed+8] // (empty)

    {
    ** make sure that the transformed particle is not in front of
    ** the particle Z clip plane.  We can do the comparison in
    ** integer space since we know the sign of one of the inputs
    ** and can figure out the sign of the other easily enough.
    }
    //   if (transformed[2] < PARTICLE_Z_CLIP)
    //      return;

    mov  eax, dword ptr [transformed+8]
    and  eax, eax
    js   end_
    cmp  eax, particle_z_clip
    jl   end_

    {
    ** project the point by initiating the 1/z calc
    }
    //   zi = 1.0 / transformed[2];
    fld   one
    fdiv  dword ptr [transformed+8]

    {
    ** bind the blend function pointer to the appropriate blender
    ** while we're dividing
    }
    //if ( level == PARTICLE_33 )
    //   blendparticle = BlendParticle33;
    //else if ( level == PARTICLE_66 )
    //   blendparticle = BlendParticle66;
    //else
    //   blendparticle = BlendParticle100;

    cmp partparms.level, PARTICLE_66
    je  blendfunc_66
    jl  blendfunc_33
    lea ebx, BlendParticle100
    jmp done_selecting_blend_func
blendfunc_33:
    lea ebx, BlendParticle33
    jmp done_selecting_blend_func
blendfunc_66:
    lea ebx, BlendParticle66
done_selecting_blend_func:
    mov blendfunc, ebx

    // prefetch the next particle
    mov ebp, s_prefetch_address
    mov ebp, [ebp]

    // finish the above divide
    fstp  zi

    // u = (int)(xcenter + zi * transformed[0] + 0.5);
    // v = (int)(ycenter - zi * transformed[1] + 0.5);
    fld   zi                           // zi
    fmul  dword ptr [transformed+0]    // zi * transformed[0]
    fld   zi                           // zi | zi * transformed[0]
    fmul  dword ptr [transformed+4]    // zi * transformed[1] | zi * transformed[0]
    fxch  st(1)                        // zi * transformed[0] | zi * transformed[1]
    fadd  xcenter                      // xcenter + zi * transformed[0] | zi * transformed[1]
    fxch  st(1)                        // zi * transformed[1] | xcenter + zi * transformed[0]
    fld   ycenter                      // ycenter | zi * transformed[1] | xcenter + zi * transformed[0]
    fsubrp st(1), st(0)                // ycenter - zi * transformed[1] | xcenter + zi * transformed[0]
    fxch  st(1)                        // xcenter + zi * transformed[0] | ycenter + zi * transformed[1]
    fadd  point_five                   // xcenter + zi * transformed[0] + 0.5 | ycenter - zi * transformed[1]
    fxch  st(1)                        // ycenter - zi * transformed[1] | xcenter + zi * transformed[0] + 0.5
    fadd  point_five                   // ycenter - zi * transformed[1] + 0.5 | xcenter + zi * transformed[0] + 0.5
    fxch  st(1)                        // u | v
    fistp dword ptr [u]                // v
    fistp dword ptr [v]                // (empty)

    {
    ** clip out the particle
    }

    //   if ((v > d_vrectbottom_particle) ||
    //      (u > d_vrectright_particle) ||
    //      (v < d_vrecty) ||
    //      (u < d_vrectx))
    //   {
    //      return;
    //   }

    mov ebx, u
    mov ecx, v
    cmp ecx, d_vrectbottom_particle
    jg  end_
    cmp ecx, d_vrecty
    jl  end_
    cmp ebx, d_vrectright_particle
    jg  end_
    cmp ebx, d_vrectx
    jl  end_

    {
    ** compute addresses of zbuffer, framebuffer, and
    ** compute the Z-buffer reference value.
    **
    ** EBX      = U
    ** ECX      = V
    **
    ** Outputs:
    ** ESI = Z-buffer address
    ** EDI = framebuffer address
    }
    // ESI = d_pzbuffer + (d_zwidth * v) + u;
    mov esi, d_pzbuffer             // esi = d_pzbuffer
    mov eax, d_zwidth               // eax = d_zwidth
    mul ecx                         // eax = d_zwidth*v
    add eax, ebx                    // eax = d_zwidth*v+u
    shl eax, 1                      // eax = 2*(d_zwidth*v+u)
    add esi, eax                    // ; esi = ( short * ) ( d_pzbuffer + ( d_zwidth * v ) + u )

    // initiate
    // izi = (int)(zi * 0x8000);
    fld  zi
    fmul eight_thousand_hex

    // EDI = pdest = d_viewbuffer + d_scantable[v] + u;
    lea edi, [d_scantable+ecx*4]
    mov edi, [edi]
    add edi, d_viewbuffer
    add edi, ebx

    // complete
    // izi = (int)(zi * 0x8000);
    fistp tmp
    mov   eax, tmp
    mov   izi, ax

    {
    ** determine the screen area covered by the particle,
    ** which also means clamping to a min and max
    }
    //   pix = izi >> d_pix_shift;
    xor edx, edx
    mov dx, izi
    mov ecx, d_pix_shift
    shr dx, cl

    //   if (pix < d_pix_min)
    //      pix = d_pix_min;
    cmp edx, d_pix_min
    jge check_pix_max
    mov edx, d_pix_min
    jmp skip_pix_clamp

    //   else if (pix > d_pix_max)
    //      pix = d_pix_max;
check_pix_max:
    cmp edx, d_pix_max
    jle skip_pix_clamp
    mov edx, d_pix_max

skip_pix_clamp:

    {
    ** render the appropriate pixels
    **
    ** ECX = count (used for inner loop)
    ** EDX = count (used for outer loop)
    ** ESI = zbuffer
    ** EDI = framebuffer
    }
    mov ecx, edx

    cmp ecx, 1
    ja  over

over:

    {
    ** at this point:
    **
    ** ECX = count
    }
    push ecx
    push edi
    push esi

top_of_pix_vert_loop:

top_of_pix_horiz_loop:

    //   for ( ; count ; count--, pz += d_zwidth, pdest += screenwidth)
    //   {
    //      for (i=0 ; i<pix ; i++)
    //      {
    //         if (pz[i] <= izi)
    //         {
    //            pdest[i] = blendparticle( color, pdest[i] );
    //         }
    //      }
    //   }
    xor   eax, eax

    mov   ax, word ptr [esi]

    cmp   ax, izi
    jg    end_of_horiz_loop

{$ifdef ENABLE_ZWRITES_FOR_PARTICLES}
    mov   bp, izi
    mov   word ptr [esi], bp
{$endif}

    mov   eax, partparms.color

    call  [blendfunc]

    add   edi, 1
    add   esi, 2

end_of_horiz_loop:

    dec ecx
    jnz top_of_pix_horiz_loop

    pop esi
    pop edi

    mov ebp, d_zwidth
    shl ebp, 1

    add esi, ebp
    add edi, [r_screenwidth]

    pop ecx
    push ecx

    push edi
    push esi

    dec edx
    jnz top_of_pix_vert_loop

    pop ecx
    pop ecx
    pop ecx

end_:
    pop edi
    pop esi
    mov ebp, ebpsave
    ret
end;

{$ENDIF} // __linux__
{$ELSE}

type
  TBlendParticle = function(pcolor, dstcolor: Integer): Byte;

function BlendParticle33(pcolor, dstcolor: Integer): Byte;
begin
  Result := PByte(Integer(vid.alphamap) + (pcolor + dstcolor * 256))^;
end;

function BlendParticle66(pcolor, dstcolor: Integer): Byte;
begin
  Result := PByte(Integer(vid.alphamap) + (pcolor * 256 + dstcolor))^;
end;

function BlendParticle100(pcolor, dstcolor: Integer): Byte;
begin
  Result := pcolor;
end;

(*
** R_DrawParticle
**
** Yes, this is amazingly slow, but it's the C reference
** implementation and should be both robust and vaguely
** understandable.  The only time this path should be
** executed is if we're debugging on x86 or if we're
** recompiling and deploying on a non-x86 platform.
**
** To minimize error and improve readability I went the
** function pointer route.  This exacts some overhead, but
** it pays off in clean and easy to understand code.
*)

procedure R_DrawParticle;
var
  pparticle: particle_p;
  level: Integer;
  local: vec3_t;
  transformed: vec3_t;
  zi: Single;
  pdest: PByte;
  pz: PSmallInt;
  color: Integer;
  i, izi, pix: Integer;
  count, u, v: Integer;
//   blendparticle : TBlendParticle;
begin
  pparticle := partparms.particle;
  level := partparms.level;
  color := pparticle^.color;
 (*
 ** transform the particle
 *)
  VectorSubtract(pparticle^.origin, r_origin, local);

  transformed[0] := DotProduct(local, r_pright);
  transformed[1] := DotProduct(local, r_pup);
  transformed[2] := DotProduct(local, r_ppn);

  if (transformed[2] < PARTICLE_Z_CLIP) then
    Exit;

 (*
 ** bind the blend function pointer to the appropriate blender
 *)
(*   if (level = PARTICLE_33) then
  blendparticle := BlendParticle33
 else
  begin
    if (level = PARTICLE_66) then
    blendparticle := BlendParticle66
   else
    blendparticle := BlendParticle100;
  end;*)
 (*
 ** project the point
 *)
 // FIXME: preadjust xcenter and ycenter
  zi := 1.0 / transformed[2];
  u := Trunc(xcenter + zi * transformed[0] + 0.5);
  v := Trunc(ycenter - zi * transformed[1] + 0.5);

  if ((v > d_vrectbottom_particle) or (u > d_vrectright_particle) or (v < d_vrecty) or (u < d_vrectx)) then
    Exit;

 (*
 ** compute addresses of zbuffer, framebuffer, and
 ** compute the Z-buffer reference value.
 *)
  pz := PSmallInt(Integer(d_pzbuffer) + (((Integer(d_zwidth) * v) + u) * SizeOf(SmallInt)));
  pdest := PByte(Integer(d_viewbuffer) + (d_scantable[v] + u));
  izi := Trunc(zi * $8000);

 (*
 ** determine the screen area covered by the particle,
 ** which also means clamping to a min and max
 *)
  pix := _SAR(izi, d_pix_shift);
  if (pix < d_pix_min) then
    pix := d_pix_min
  else
    if (pix > d_pix_max) then
      pix := d_pix_max;

 (*
 ** render the appropriate pixels
 *)
  count := pix;
  case (level) of
    PARTICLE_33:
      begin
        while (count > 0) do
        begin
          //FIXME--do it in blocks of 8?
          for I := 0 to pix - 1 do
          begin
            if (PSmallIntArray(pz)^[i] <= izi) then
            begin
              PSmallIntArray(pz)^[i] := izi;
              PByteArray(pdest)^[i] := PByteArray(vid.alphamap)^[color + (Integer(PByteArray(pdest)^[i]) shl 8)];
            end;
          end;
          Inc(Cardinal(pz), d_zwidth * SizeOf(SmallInt));
          Inc(Integer(pdest), r_screenwidth);
          Dec(count);
        end;
      end;
    PARTICLE_66:
      begin
        while (count > 0) do
        begin
          for I := 0 to pix - 1 do
          begin
            if (PSmallIntArray(pz)^[i] <= izi) then
            begin
              PSmallIntArray(pz)^[i] := izi;
              PByteArray(pdest)^[i] := PByteArray(vid.alphamap)^[(color shl 8) + Integer(PByteArray(pdest)^[i])];
            end;
          end;
          Inc(Cardinal(pz), d_zwidth * SizeOf(SmallInt));
          Inc(Integer(pdest), r_screenwidth);
          Dec(count);
        end;
      end;
  else //100
    begin
      while (count > 0) do
      begin
        for I := 0 to pix - 1 do
        begin
          if (PSmallIntArray(pz)^[i] <= izi) then
          begin
            PSmallIntArray(pz)^[i] := izi;
            PByteArray(pdest)^[i] := color;
          end;
        end;
        Inc(Cardinal(pz), d_zwidth * SizeOf(SmallInt));
        Inc(Integer(pdest), r_screenwidth);
        Dec(count);
      end;
    end;
  end;
end;

{$ENDIF} // id386

(*
** R_DrawParticles
**
** Responsible for drawing all of the particles in the particle list
** throughout the world.  Doesn't care if we're using the C path or
** if we're using the asm path, it simply assigns a function pointer
** and goes.
*)

procedure R_DrawParticles;
var
  p: particle_p;
  i: Integer;
//   extern unsigned long fpu_sp24_cw, fpu_chop_cw;
begin
  VectorScale(vright, xscaleshrink, r_pright);
  VectorScale(vup, yscaleshrink, r_pup);
  VectorCopy(vpn, r_ppn);

{$IFDEF id386}
{$IFNDEF __linux__}
  asm
    fldcw word ptr [fpu_sp24_cw]
  end;
{$ENDIF}
{$ENDIF}
  p := r_newrefdef.particles;
  for i := 0 to r_newrefdef.num_particles - 1 do
  begin
    if (p^.alpha > 0.66) then
      partparms.level := PARTICLE_OPAQUE
    else
    begin
      if (p^.alpha > 0.33) then
        partparms.level := PARTICLE_66
      else
        partparms.level := PARTICLE_33;
    end;
    partparms.particle := p;
    partparms.color := p^.color;
{$IFDEF id386}
    if (i < r_newrefdef.num_particles - 1) then
      s_prefetch_address := Integer(p) + 1
    else
      s_prefetch_address := Integer(r_newrefdef.particles);
{$ENDIF}
    R_DrawParticle;
    Inc(Integer(p), SizeOf(particle_t));
  end;
{$IFDEF id386}
  asm
    __asm fldcw word ptr [fpu_chop_cw]
  end;
{$ENDIF}

(*  r_newrefdef.particles
 for (p=r_newrefdef.particles, i=0 ; i<r_newrefdef.num_particles ; i++,p++)
 for (p=r_newrefdef.particles, i=0 ; i<r_newrefdef.num_particles ; i++,p++)
 {

  if ( p->alpha > 0.66 )
   partparms.level = PARTICLE_OPAQUE;
  else if ( p->alpha > 0.33 )
   partparms.level = PARTICLE_66;
  else
   partparms.level = PARTICLE_33;

  partparms.particle = p;
  partparms.color    = p->color;

#if id386 && !defined __linux__
  if ( i < r_newrefdef.num_particles-1 )
   s_prefetch_address = ( unsigned int ) ( p + 1 );
  else
   s_prefetch_address = ( unsigned int ) r_newrefdef.particles;
#endif

  R_DrawParticle;
 end;

#if id386 && !defined __linux__
 __asm fldcw word ptr [fpu_chop_cw]
#endif*)
end;

end.
