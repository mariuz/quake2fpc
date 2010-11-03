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


// Juha: For some reason Delphi(6 at least) compiler optimizations messes
// things up..
{$O-}
{----------------------------------------------------------------------------}
{                                                                            }
{ File(s): snd_mix.c                                                         }
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
{ Updated on : 03-jun-2002                                                   }
{ Updated by : Juha Hartikainen (juha@linearteam.org)                        }
{ - Language fixes to make this compile                                      }
{ Updated on : 18-jul-2002                                                   }
{ Updated by : Alexey Barkovoy (clootie@reactor.ru)                          }
{ - Fixes to "cracking sound bug"                                            }
{                                                                            }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{----------------------------------------------------------------------------}
// snd_mix.c -- portable code to mix sounds for snd_dma.c
unit snd_mix;

interface

uses
  DelphiTypes,
  SysUtils,
  snd_loc,
  snd_dma;

const
  PAINTBUFFER_SIZE = 2048;

var
  paintbuffer: array[0..PAINTBUFFER_SIZE - 1] of portable_samplepair_t;
  snd_scaletable: array[0..31, 0..255] of Integer;
  snd_p: PIntegerArray;
  snd_linear_count, snd_vol: Integer;
  snd_out: PSmallIntArray;              // short *name;

procedure S_WriteLinearBlastStereo16;
procedure S_PaintChannelFrom8(ch: channel_p; sc: sfxcache_p; count, offset: Integer);
procedure S_PaintChannelFrom16(ch: channel_p; sc: sfxcache_p; count, offset: Integer);
procedure S_InitScaletable;
procedure S_PaintChannels(endtime: Integer);

implementation

uses
  snd_mem;

procedure S_WriteLinearBlastStereo16;
var
  i, val: Integer;
begin
  i := 0;
  while (i < snd_linear_count) do
  begin
    // val = snd_p[i]>>8;
    asm
      mov eax, snd_p
      mov edx, i
      mov eax, [eax + edx*4]
      sar eax, 8
      mov val, eax
    end;
    if (val > $7FFF) then
      snd_out^[i] := $7FFF
    else if (val < SmallInt($8000)) then
      snd_out^[i] := SmallInt($8000)
    else
      snd_out^[i] := val;

    // val = snd_p[i+1]>>8;
    asm
      mov eax, snd_p
      mov edx, i
      mov eax, [eax + edx*4 + 4]
      sar eax, 8
      mov val, eax
    end;
    if (val > $7FFF) then
      snd_out^[i + 1] := $7FFF
    else if (val < SmallInt($8000)) then
      snd_out^[i + 1] := SmallInt($8000)
    else
      snd_out^[i + 1] := val;

    Inc(i, 2);
  end;
end;

(*
procedure S_WriteLinearBlastStereo16;
 asm
 push edi
 push ebx
 mov ecx,ds:dword ptr[snd_linear_count]
 mov ebx,ds:dword ptr[snd_p]
 mov edi,ds:dword ptr[snd_out]
@LWLBLoopTop:
 mov eax,ds:dword ptr[-8+ebx+ecx*4]
 sar eax,8
 cmp eax,07FFFh
 jg @LClampHigh
 cmp eax,0FFFF8000h
 jnl @LClampDone
 mov eax,0FFFF8000h
 jmp @LClampDone
@LClampHigh:
 mov eax,07FFFh
@LClampDone:
 mov edx,ds:dword ptr[-4+ebx+ecx*4]
 sar edx,8
 cmp edx,07FFFh
 jg @LClampHigh2
 cmp edx,0FFFF8000h
 jnl @LClampDone2
 mov edx,0FFFF8000h
 jmp @LClampDone2
@LClampHigh2:
 mov edx,07FFFh
@LClampDone2:
 shl edx,16
 and eax,0FFFFh
 or edx,eax
 mov ds:dword ptr[-4+edi+ecx*2],edx
 sub ecx,2
 jnz @LWLBLoopTop
 pop ebx
 pop edi
 ret
end;
*)

procedure S_TransferStereo16(pbuf: PCardinalArray; endtime: Integer);
var
  lpos,
    lpaintedtime: Integer;
begin
  snd_p := @paintbuffer;
  lpaintedtime := paintedtime;

  while (lpaintedtime < endtime) do
  begin
    // handle recirculating buffer issues
    lpos := lpaintedtime and ((dma.samples shr 1) - 1);

    snd_out := Pointer(Cardinal(pbuf) + (lpos shl 1) * SizeOf(SmallInt));

    snd_linear_count := (dma.samples shr 1) - lpos;
    if (lpaintedtime + snd_linear_count > endtime) then
      snd_linear_count := endtime - lpaintedtime;

    snd_linear_count := snd_linear_count shl 1;

    // write a linear blast of samples
    S_WriteLinearBlastStereo16();

    snd_p := Pointer(Cardinal(snd_p) + snd_linear_count * SizeOf(Cardinal));
    lpaintedtime := lpaintedtime + (snd_linear_count shr 1);
  end;
end;

(*
===================
S_TransferPaintBuffer

===================
*)

procedure S_TransferPaintBuffer(endtime: Integer);
var
  out_idx,
    count,
    out_mask,
    step,
    val: Integer;
  p: PIntegerArray;
  pbuf: PCardinalArray;
  i: Integer;
  out8: PByteArray;
  out16: PSmallIntArray;
begin
  pbuf := PCardinalArray(dma.buffer);

  if (s_testsound^.value <> 0) then
  begin
    // write a fixed sine wave
    count := (endtime - paintedtime);
    for i := 0 to count - 1 do
    begin
      paintbuffer[i].left := Trunc(sin((paintedtime + i) * 0.1) * 20000 * 256);
      paintbuffer[i].right := paintbuffer[i].left;
    end;
  end;

  if ((dma.samplebits = 16) and (dma.channels = 2)) then
  begin                                 // optimized case
    S_TransferStereo16(pbuf, endtime);
  end
  else
  begin                                 // general case
    p := @paintbuffer;
    count := (endtime - paintedtime) * dma.channels;
    out_mask := dma.samples - 1;
    out_idx := paintedtime * dma.channels and out_mask;
    step := 3 - dma.channels;

    if (dma.samplebits = 16) then
    begin
      out16 := PSmallIntArray(pbuf);
      while (count <> 0) do
      begin
        Dec(Count);
        val := p[0] shr 8;
        p := Pointer(Cardinal(p) + step * SizeOf(Integer));
        if (val > $7FFF) then
          val := $7FFF
        else if (val < SmallInt($8000)) then
          val := SmallInt($8000);
        out16[out_idx] := val;
        out_idx := (out_idx + 1) and out_mask;
      end;
    end
    else if (dma.samplebits = 8) then
    begin
      out8 := PByteArray(pbuf);
      while (count <> 0) do
      begin
        Dec(Count);
        val := p[0] shr 8;
        p := Pointer(Cardinal(p) + step * SizeOf(Byte));
        if (val > $7FFF) then
          val := $7FFF
        else if (val < SmallInt($8000)) then
          val := $8000;
        out8[out_idx] := (val shr 8) + 128;
        out_idx := (out_idx + 1) and out_mask;
      end;
    end;
  end;
end;

(*
===============================================================================

CHANNEL MIXING

===============================================================================
*)

procedure S_PaintChannels(endtime: Integer);
var
  i, _end: Integer;
  sc: sfxcache_p;
  ltime, count: Integer;
  ps: playsound_p;
  s, stop: Integer;
begin
  snd_vol := Trunc(s_volume^.value * 256);

  //Com_Printf ("%i to %i\n", paintedtime, endtime);
  while (paintedtime < endtime) do
  begin
    // if paintbuffer is smaller than DMA buffer
    _end := endtime;
    if (endtime - paintedtime > PAINTBUFFER_SIZE) then
      _end := paintedtime + PAINTBUFFER_SIZE;

    // start any playsounds
    while (True) do
    begin
      ps := s_pendingplays.next;
      if (ps = @s_pendingplays) then
        break;                          // no more pending sounds
      if (ps^._begin <= paintedtime) then
      begin
        S_IssuePlaysound(ps);
        continue;
      end;

      if (ps^._begin < _end) then
        _end := ps^._begin;             // stop here
      break;
    end;

    // clear the paint buffer
    if (s_rawend < paintedtime) then
    begin
      //         Com_Printf ("clear\n");
      FillChar(paintbuffer, (_end - paintedtime) * sizeof(portable_samplepair_t), 0);
    end
    else
    begin                               // copy from the streaming sound source
      //stop := (_end < s_rawend) ? _end : s_rawend;
      if (_end < s_rawend) then
        stop := _end
      else
        stop := s_rawend;

      for i := paintedtime to stop - 1 do
      begin
        s := i and (MAX_RAW_SAMPLES - 1);
        paintbuffer[i - paintedtime] := s_rawsamples_[s];
      end;
      //      if (i != end)
      //         Com_Printf ("partial stream\n");
      //      else
      //         Com_Printf ("full stream\n");
      for i := stop to _end - 1 do
      begin
        paintbuffer[i - paintedtime].left := 0;
        paintbuffer[i - paintedtime].right := 0;
      end;
    end;

    // paint in the channels.
    for i := 0 to MAX_CHANNELS - 1 do   //i++, ch++)
    begin
      ltime := paintedtime;

      while (ltime < _end) do
      begin
        if ((channels[i].sfx = nil) or ((channels[i].leftvol = 0) and (channels[i].rightvol = 0))) then
          break;

        // max painting is to the end of the buffer
        count := _end - ltime;

        // might be stopped by running out of data
        if (channels[i]._end - ltime < count) then
          count := channels[i]._end - ltime;

        sc := S_LoadSound(channels[i].sfx);
        if (sc = nil) then
          break;

        if ((count > 0) and (channels[i].sfx <> nil)) then
        begin
          if (sc^.width = 1) then       // FIXME; 8 bit asm is wrong now
            S_PaintChannelFrom8(@channels[i], sc, count, ltime - paintedtime)
          else
            S_PaintChannelFrom16(@channels[i], sc, count, ltime - paintedtime);

          Inc(ltime, count);
        end;

        // if at end of loop, restart
        if (ltime >= channels[i]._end) then
        begin
          if (channels[i].autosound) then
          begin                         // autolooping sounds always go back to start
            channels[i].pos := 0;
            channels[i]._end := ltime + sc^.length;
          end
          else if (sc^.loopstart >= 0) then
          begin
            channels[i].pos := sc^.loopstart;
            channels[i]._end := ltime + sc^.length - channels[i].pos;
          end
          else
          begin                         // channel just stopped
            channels[i].sfx := nil;
          end;
        end;
      end;

    end;

    // transfer out according to DMA format
    S_TransferPaintBuffer(_end);
    paintedtime := _end;
  end;
end;

procedure S_InitScaletable;
var
  i, j, scale: Integer;
begin
  s_volume^.modified := false;
  for i := 0 to 31 do
  begin
    scale := Trunc(i * 8 * 256 * s_volume^.value);
    for j := 0 to 255 do
      snd_scaletable[i][j] := ShortInt(j) * scale;
  end;
end;

procedure S_PaintChannelFrom8(ch: channel_p; sc: sfxcache_p; count, offset: Integer);
var
  data, i: Integer;
  lscale, rscale: PIntegerArray;
  sfx: PByteArray;
  samp: portable_samplepair_p;
begin
  if (ch^.leftvol > 255) then
    ch^.leftvol := 255;
  if (ch^.rightvol > 255) then
    ch^.rightvol := 255;

  //ZOID--  shr 11 has been changed to  shr 3,  shr 11 didn't make much sense
  //as it would always be zero.
  lscale := @snd_scaletable[ch^.leftvol shr 3];
  rscale := @snd_scaletable[ch^.rightvol shr 3];
  sfx := Pointer(Cardinal(@sc^.data) + ch^.pos);

  samp := @paintbuffer[offset];
  for i := 0 to count - 1 do
  begin
    data := sfx[i];
    samp.left := samp.left + lscale[data];
    samp.right := samp.right + rscale[data];
    Inc(samp);
  end;

  ch^.pos := ch^.pos + count;
end;

(*
procedure S_PaintChannelFrom8(ch : channel_p; sc : sfxcache_p; count, offset: Integer);
asm
 push esi
 push edi
 push ebx
 push ebp
 mov ebx,ds:dword ptr[4+16+esp]
 mov esi,ds:dword ptr[8+16+esp]
 mov eax,ds:dword ptr[4+ebx]
 mov edx,ds:dword ptr[8+ebx]
 cmp eax,255
 jna @LLeftSet
 mov eax,255
@LLeftSet:
 cmp edx,255
 jna @LRightSet
 mov edx,255
@LRightSet:
 and eax,0F8h
 add esi,20
 and edx,0F8h
 mov edi,ds:dword ptr[16+ebx]
 mov ecx,ds:dword ptr[12+16+esp]
 add esi,edi
 shl eax,7
 add edi,ecx
 shl edx,7
 mov ds:dword ptr[16+ebx],edi
 add eax,offset snd_scaletable
 add edx,offset snd_scaletable
 sub ebx,ebx
 mov bl,ds:byte ptr[-1+esi+ecx*1]
 test ecx,1
 jz @LMix8Loop
 mov edi,ds:dword ptr[eax+ebx*4]
 mov ebp,ds:dword ptr[edx+ebx*4]
 add edi,ds:dword ptr[paintbuffer+0-8+ecx*8]
 add ebp,ds:dword ptr[paintbuffer+4-8+ecx*8]
 mov ds:dword ptr[paintbuffer+0-8+ecx*8],edi
 mov ds:dword ptr[paintbuffer+4-8+ecx*8],ebp
 mov bl,ds:byte ptr[-2+esi+ecx*1]
 dec ecx
 jz @LDone
@LMix8Loop:
 mov edi,ds:dword ptr[eax+ebx*4]
 mov ebp,ds:dword ptr[edx+ebx*4]
 add edi,ds:dword ptr[paintbuffer+0-8+ecx*8]
 add ebp,ds:dword ptr[paintbuffer+4-8+ecx*8]
 mov bl,ds:byte ptr[-2+esi+ecx*1]
 mov ds:dword ptr[paintbuffer+0-8+ecx*8],edi
 mov ds:dword ptr[paintbuffer+4-8+ecx*8],ebp
 mov edi,ds:dword ptr[eax+ebx*4]
 mov ebp,ds:dword ptr[edx+ebx*4]
 mov bl,ds:byte ptr[-3+esi+ecx*1]
 add edi,ds:dword ptr[paintbuffer+0-8*2+ecx*8]
 add ebp,ds:dword ptr[paintbuffer+4-8*2+ecx*8]
 mov ds:dword ptr[paintbuffer+0-8*2+ecx*8],edi
 mov ds:dword ptr[paintbuffer+4-8*2+ecx*8],ebp
 sub ecx,2
 jnz @LMix8Loop
@LDone:
 pop ebp
 pop ebx
 pop edi
 pop esi
 ret
end;
*)

procedure S_PaintChannelFrom16(ch: channel_p; sc: sfxcache_p; count, offset: Integer);
var
  data,
    left,
    right,
    leftvol,
    rightvol,
    i: Integer;
  sfx: PSmallIntArray;
  samp: portable_samplepair_p;
begin
  leftvol := ch^.leftvol * snd_vol;
  rightvol := ch^.rightvol * snd_vol;
  sfx := Pointer(Cardinal(@sc^.data) + ch^.pos * SizeOf(SmallInt));

  samp := @paintbuffer[offset];
  for i := 0 to count - 1 do
  begin
    data := sfx[i];
    asm
      mov edi, data

      // left = (data * leftvol)>>8;
      mov  eax, edi // data
      imul leftvol
      sar  eax, 8
      mov  left, eax

      // right = (data * rightvol)>>8;
      mov  eax, edi // data
      imul rightvol
      sar  eax, 8
      mov  right, eax
    end;
    samp.left := samp.left + left;
    samp.right := samp.right + right;
    Inc(samp);
  end;

  ch^.pos := ch^.pos + count;
end;

end.
