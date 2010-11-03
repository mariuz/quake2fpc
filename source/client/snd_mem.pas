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
{ File(s): snd_mem.c                                                         }
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
unit snd_mem;

interface

uses
  snd_loc;

function S_LoadSound(s: sfx_p): sfxcache_p;
function GetWavinfo(name: pchar; wav: PByte; wavlength: Integer): wavinfo_t;

var
  cache_full_cycle: Integer;

implementation

uses
  DelphiTypes,
  CPas,
  SysUtils,
  q_shared,
  snd_dma,
  Common,
  Files;

(*
================
ResampleSfx
================
*)

procedure ResampleSfx(sfx: sfx_p; inrate, inwidth: Integer; Data: PByteArray);
var
  outcount: Integer;
  srcsample: Integer;
  stepscale: Single;
  i: Integer;
  sample, samplefrac, fracstep: Integer;
  sc: sfxcache_p;
begin
  sc := sfx.cache;
  if (sc = nil) then
    exit;

  stepscale := inrate / dma.speed;      // this is usually 0.5, 1, or 2

  outcount := sc^.length div Trunc(stepscale);
  sc^.length := outcount;
  if (sc^.loopstart <> -1) then
    sc^.loopstart := Trunc(sc^.loopstart / stepscale);

  sc^.speed := dma.speed;
  if (s_loadas8bit^.value <> 0) then
    sc^.width := 1
  else
    sc^.width := inwidth;
  sc^.stereo := 0;

  // resample / decimate to the current source rate

  if ((stepscale = 1) and (inwidth = 1) and (sc^.width = 1)) then
  begin
    // fast special case
    for i := 0 to outcount - 1 do
      PShortIntArray(@sc^.data)[i] := (data^[i] - 128);
  end
  else
  begin
    // general case
    samplefrac := 0;
    fracstep := Trunc(stepscale * 256);
    for i := 0 to outcount - 1 do
    begin
      srcsample := samplefrac shr 8;
      samplefrac := samplefrac + fracstep;
      if (inwidth = 2) then
        sample := LittleShort(PSmallIntArray(data)[srcsample])
      else
        sample := Integer((data[srcsample] - 128) shl 8);
      if (sc^.width = 2) then
        PSmallIntArray(@sc^.data)[i] := sample
      else
        PShortIntArray(@sc^.data)[i] := sample shr 8;
    end;
  end;
end;

//=============================================================================

(*
==============
S_LoadSound
==============
*)

function S_LoadSound(s: sfx_p): sfxcache_p;
var
  namebuffer: array[0..MAX_QPATH - 1] of Char;
  Data: PByteArray;
  info: wavinfo_t;
  len, size: Integer;
  stepscale: Single;
  sc: sfxcache_p;
  name: PChar;
begin
  if (s^.name[0] = '*') then
  begin
    Result := nil;
    exit;
  end;

  // see if still in memory
  sc := s^.cache;
  if (sc <> nil) then
  begin
    Result := sc;
    exit;
  end;

  //Com_Printf ("S_LoadSound: %x"#10, (int)stackbuf);
  // load it in
  if (s^.truename <> nil) then
    name := s^.truename
  else
    name := s^.name;

  if (name[0] = '#') then
  begin
    strcpy(namebuffer, name);
  end
  else
    Com_sprintf(namebuffer, sizeof(namebuffer), 'sound/%s', [name]);

  //   Com_Printf ("loading %s"#10,namebuffer);

  size := FS_LoadFile(namebuffer, @data);

  if (data = nil) then
  begin
    Com_DPrintf('Couldn''t load %s'#10, [namebuffer]);
    Result := nil;
    exit;
  end;

  info := GetWavinfo(s^.name, PByte(data), size);
  if (info.channels <> 1) then
  begin
    Com_Printf('%s is a stereo sample'#10, [s^.name]);
    FS_FreeFile(data);
    Result := nil;
    exit;
  end;

  stepscale := info.rate / dma.speed;
  len := Trunc(info.samples / stepscale);

  len := len * info.width * info.channels;

  sc := Z_Malloc(len + sizeof(sfxcache_t));
  s^.cache := sc;
  if (sc = nil) then
  begin
    FS_FreeFile(data);
    Result := nil;
    Exit;
  end;

  sc^.length := info.samples;
  sc^.loopstart := info.loopstart;
  sc^.speed := info.rate;
  sc^.width := info.width;
  sc^.stereo := info.channels;

  ResampleSfx(s, sc^.speed, sc^.width, @data^[info.dataofs]);

  FS_FreeFile(data);

  result := sc;
end;

(*
===============================================================================

WAV loading

===============================================================================
*)

var
  data_p: PByteArray;
  iff_end: PByteArray;
  last_chunk: PByteArray;
  iff_data: PByteArray;
  iff_chunk_len: Integer;

function GetLittleShort: SmallInt;
var
  val: SmallInt;
begin
  val := data_p[0];
  val := val + data_p[1] shl 8;
  data_p := Pointer(Cardinal(data_p) + 2);
  result := val;
end;

function GetLittleLong: Integer;
var
  val: Integer;
begin
  val := data_p[0];
  val := val + data_p[1] shl 8;
  val := val + data_p[2] shl 16;
  val := val + data_p[3] shl 24;
  data_p := Pointer(Cardinal(data_p) + 4);
  Result := val;
end;

procedure FindNextChunk(name: PChar);
begin
  while (True) do
  begin
    data_p := last_chunk;

    if (Cardinal(data_p) >= Cardinal(iff_end)) then
    begin                               // didn't find the chunk
      data_p := nil;
      exit;
    end;

    data_p := Pointer(Cardinal(data_p) + 4);
    iff_chunk_len := GetLittleLong;
    if (iff_chunk_len < 0) then
    begin
      data_p := nil;
      exit;
    end;
    //      if (iff_chunk_len > 1024*1024)
    //         Sys_Error ("FindNextChunk: %d length is past the 1 meg sanity limit", iff_chunk_len);

    data_p := Pointer(Cardinal(data_p) - 8);
    last_chunk := Pointer(Integer(data_p) + 8 + Integer((iff_chunk_len + 1) and not 1));
    if (strncmp(Pointer(data_p), name, 4) = 0) then
      exit;
  end;
end;

procedure FindChunk(name: PChar);
begin
  last_chunk := iff_data;
  FindNextChunk(name);
end;

procedure DumpChunks;
begin                                   // This is disabled in original Quake 2 Source Code so I have not translate it
  (*
   str[4] := 0;
   data_p:=iff_data;
       data_i:=iff_data_i;
       repeat
    move(data_p,str,4);
            BT:=4;
            data_p :=@ByteAry(data_p^)[BT];
            Inc(data_i,BT);
    iff_chunk_len = GetLittleLong();
    Com_Printf ('0x%x : %s (%d)',[ (data_p - 4), str, iff_chunk_len]);
            BT:=(iff_chunk_len + 1) and -2;
            data_p :=@ByteAry(data_p^)[BT];
            Inc(data_i,BT);
   until (data_i >= iff_end_i);
  *)
end;

(*
============
GetWavinfo
============
*)

function GetWavinfo(name: pchar; wav: PByte; wavlength: Integer): wavinfo_t;
var
  info: wavinfo_t;
  i,
    format,
    samples: Integer;
begin
  FillChar(info, SizeOf(info), 0);

  if (wav = nil) then
  begin
    result := info;
    exit;
  end;

  iff_data := PByteArray(wav);
  iff_end := Pointer(Cardinal(wav) + wavlength);

  // find "RIFF" chunk
  FindChunk('RIFF');
  if not ((data_p <> nil) and (not strncmp(Pointer(Cardinal(data_p) + 8), 'WAVE', 4) <> 0)) then
  begin
    Com_Printf('Missing RIFF/WAVE chunks'#10, []);
    result := info;
    exit;
  end;

  // get "fmt " chunk
  iff_data := Pointer(Cardinal(data_p) + 12);
  // DumpChunks ();

  FindChunk('fmt ');
  if (data_p = nil) then
  begin
    Com_Printf('Missing fmt chunk'#10, []);
    result := info;
    exit;
  end;
  data_p := Pointer(Cardinal(data_p) + 8);
  format := GetLittleShort();
  if (format <> 1) then
  begin
    Com_Printf('Microsoft PCM format only'#10, []);
    Result := info;
    exit;
  end;

  info.channels := GetLittleShort();
  info.rate := GetLittleLong();
  data_p := Pointer(Cardinal(data_p) + 4 + 2);
  info.width := GetLittleShort() div 8;

  // get cue chunk
  FindChunk('cue ');
  if (data_p <> nil) then
  begin
    data_p := Pointer(Cardinal(data_p) + 32);
    info.loopstart := GetLittleLong();
    //      Com_Printf("loopstart=%d"#10, sfx->loopstart);

     // if the next chunk is a LIST chunk, look for a cue length marker
    FindNextChunk('LIST');
    if (data_p <> nil) then
    begin
      if (not strncmp(Pointer(Cardinal(data_p) + 28), 'mark', 4) <> 0) then
      begin                             // this is not a proper parse, but it works with cooledit...
        data_p := Pointer(Cardinal(data_p) + 24);
        i := GetLittleLong;             // samples in loop
        info.samples := info.loopstart + i;
        //            Com_Printf('looped length: %d'#10, i);
      end;
    end;
  end
  else
    info.loopstart := -1;

  // find data chunk
  FindChunk('data');
  if (data_p = nil) then
  begin
    Com_Printf('Missing data chunk'#10, []);
    Result := info;
    exit;
  end;

  data_p := Pointer(Cardinal(data_p) + 4);
  samples := GetLittleLong div info.width;

  if (info.samples <> 0) then
  begin
    if (samples < info.samples) then
      Com_Error(ERR_DROP, 'Sound %s has a bad loop length', [name]);
  end
  else
    info.samples := samples;

  info.dataofs := Cardinal(data_p) - Cardinal(wav);

  Result := info;
end;

end.
