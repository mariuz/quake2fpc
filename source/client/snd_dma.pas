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
{ File(s): snd_dma.c                                                         }
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
{ Updated on : 03-jun-2002                                                              }
{ Updated by : Juha Hartikainen                                                              }
{ - Language fixes to make this (near to) compile.                           }
{}
{ Updated on : 06-jun-2002                                                   }
{ Updated by : Juha Hartikainen                                              }
{ - Fixed bug in S_StartSound.                                               }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{ 1. Some test of couple functions in this unit                              }
{ 2. Still some more little fixing }
{----------------------------------------------------------------------------}
// snd_dma.pas -- main control for any streaming sound output device
unit snd_dma;

interface

uses
  Snd_loc,
  q_shared,
  SysUtils,
  Classes;

procedure S_Init; cdecl;
procedure S_Play; cdecl;
procedure S_SoundList; cdecl;
procedure S_Update(const origin, _forward, right, up: vec3_t);
procedure S_Update_; cdecl;
procedure S_StopAllSounds; cdecl;
procedure S_IssuePlaysound(ps: playsound_p); cdecl;
procedure S_RawSamples(samples, rate, width, channels: Integer; data: PByte); cdecl;
procedure S_StartSound(origin: vec3_p; entnum, entchannel: Integer; sfx: sfx_p; fvol, attenuation, timeofs: Single); cdecl;
function S_RegisterSound(name: PChar): sfx_p; cdecl;
procedure S_Shutdown; cdecl;
procedure S_BeginRegistration;
procedure S_EndRegistration;
procedure S_StartLocalSound(sound: PChar);

// =======================================================================
// Internal sound data & structures
// =======================================================================
// only begin attenuating sound volumes when outside the FULLVOLUME range
const
  SOUND_FULLVOLUME = 80;
  SOUND_LOOPATTENUATE = 0.003;

var
  s_registration_sequence: Integer;

  channels: array[0..MAX_CHANNELS - 1] of channel_t;

  snd_initialized: qboolean = false;
  sound_started: Integer = 0;

  dma: dma_t;

  listener_origin: vec3_t;
  listener_forward: vec3_t;
  listener_right: vec3_t;
  listener_up: vec3_t;

  s_registering: QBoolean;

  soundtime: Integer;                   // sample PAIRS
  paintedtime: Integer;                 // sample PAIRS

  // during registration it is possible to have more sounds
  // than could actually be referenced during gameplay,
  // because we don't want to free anything until we are
  // sure we won't need it.
const
  MAX_SFX = (MAX_SOUNDS * 2);
  MAX_PLAYSOUNDS = 128;

var
  s_playsounds: array[0..MAX_PLAYSOUNDS - 1] of playsound_t;
  s_freeplays: playsound_t;
  s_pendingplays: playsound_t;

  s_beginofs: Integer;

  s_volume,
    s_testsound,
    s_loadas8bit,
    s_khz,
    s_show,
    s_mixahead,
    s_primary: cvar_p;

  s_rawend: Integer;

  s_rawsamples_: array[0..MAX_RAW_SAMPLES - 1] of portable_samplepair_t;

implementation

uses
  DelphiTypes,
  Client,
  CPas,
  cl_main,
  cl_ents,
  Common,
  CVar,
  Cmd,
  Files,
  {$IFDEF WIN32}
  snd_win,
  {$ELSE}
  //snd_linux, // i switched to SDL library due to difficult on translate this unit.. by FAB
  snd_sdl,
  {$ENDIF}
  snd_mix,
  snd_mem;

var
  known_sfx: array[0..MAX_SFX - 1] of sfx_t;
  num_sfx: Integer;

  // ====================================================================
  // User-setable variables
  // ====================================================================

procedure S_SoundInfo_f; cdecl;
begin
  if (sound_started = 0) then
  begin
    Com_Printf('sound system not started'#10, []);
    exit;
  end;
  Com_Printf('%5d stereo'#10, [dma.channels - 1]);
  Com_Printf('%5d samples'#10, [dma.samples]);
  Com_Printf('%5d samplepos'#10, [dma.samplepos]);
  Com_Printf('%5d samplebits'#10, [dma.samplebits]);
  Com_Printf('%5d submission_chunk'#10, [dma.submission_chunk]);
  Com_Printf('%5d speed'#10, [dma.speed]);
  Com_Printf('$%x dma buffer'#10, [Cardinal(dma.buffer)]);
end;

(*
================
S_Init
================
*)

procedure S_Init;
var
  cv: cvar_p;
begin
  Com_Printf(#10'------- sound initialization -------'#10, []);

  cv := Cvar_Get('s_initsound', '1', 0);
  if (cv.value = 0) then
    Com_Printf('not initializing.'#10, [])
  else
  begin
    s_volume := Cvar_Get('s_volume', '0.7', CVAR_ARCHIVE);
    s_khz := Cvar_Get('s_khz', '11', CVAR_ARCHIVE);
    s_loadas8bit := Cvar_Get('s_loadas8bit', '1', CVAR_ARCHIVE);
    s_mixahead := Cvar_Get('s_mixahead', '0.2', CVAR_ARCHIVE);
    s_show := Cvar_Get('s_show', '0', 0);
    s_testsound := Cvar_Get('s_testsound', '0', 0);
    s_primary := Cvar_Get('s_primary', '0', CVAR_ARCHIVE); // win32 specific

    Cmd_AddCommand('play', S_Play);
    Cmd_AddCommand('stopsound', S_StopAllSounds);
    Cmd_AddCommand('soundlist', S_SoundList);
    Cmd_AddCommand('soundinfo', S_SoundInfo_f);

    if (not SNDDMA_Init) then
      exit;

    S_InitScaletable;

    sound_started := 1;
    num_sfx := 0;

    soundtime := 0;
    paintedtime := 0;

    Com_Printf('sound sampling rate: %d'#10, [dma.speed]);

    S_StopAllSounds;
  end;

  Com_Printf(#10'------------------------------------'#10, []);
end;

// =======================================================================
// Shutdown sound engine
// =======================================================================

procedure S_Shutdown;
var
  i: Integer;
begin
  if (sound_started = 0) then
    exit;

  SNDDMA_Shutdown;

  sound_started := 0;

  Cmd_RemoveCommand('play');
  Cmd_RemoveCommand('stopsound');
  Cmd_RemoveCommand('soundlist');
  Cmd_RemoveCommand('soundinfo');

  // free all sounds
  for i := 0 to num_sfx - 1 do
  begin
    if (known_sfx[i].name[0] = #0) then
      continue;
    if (known_sfx[i].cache <> nil) then
      Z_Free(known_sfx[i].cache);
    FillChar(known_sfx[i], sizeof(sfx_t), 0);
  end;

  num_sfx := 0;
end;

// =======================================================================
// Load a sound
// =======================================================================

(*
==================
S_FindName

==================
*)

function S_FindName(name: PChar; create: QBoolean): sfx_p;
var
  i: Integer;
  sfx: sfx_p;
begin
  if (name = nil) then
    Com_Error(ERR_FATAL, 'S_FindName: NULL'#10, []);
  if (name[0] = #0) then
    Com_Error(ERR_FATAL, 'S_FindName: empty name'#10, []);

  if (strlen(name) >= MAX_QPATH) then
    Com_Error(ERR_FATAL, 'Sound name too long: %s', [name]);

  // see if already loaded
  for i := 0 to num_sfx - 1 do
    if not (strcmp(known_sfx[i].name, name) <> 0) then
    begin
      Result := @known_sfx[i];
      exit;
    end;

  if (not create) then
  begin
    Result := nil;
    exit;
  end;

  // find a free sfx
  i := 0;
  while (i < num_sfx) do
  begin
    if (known_sfx[i].name[0] = #0) then
      //         registration_sequence < s_registration_sequence)
      break;
    Inc(i);
  end;

  if (i = num_sfx) then
  begin
    if (num_sfx = MAX_SFX) then
      Com_Error(ERR_FATAL, 'S_FindName: out of sfx_t', []);
    Inc(num_sfx);
  end;

  sfx := @known_sfx[i];
  FillChar(sfx^, sizeof(sfx_t), 0);
  strcpy(sfx^.name, name);
  sfx^.registration_sequence := s_registration_sequence;

  result := sfx;
end;

(*
==================
S_AliasName

==================
*)

function S_AliasName(aliasname: PChar; truename: PChar): sfx_p;
var
  sfx: sfx_p;
  s: PChar;
  i: Integer;
begin
  s := Z_Malloc(MAX_QPATH);
  strcpy(s, truename);
  // find a free sfx
  i := 0;
  while (i < num_sfx) do
  begin
    if (known_sfx[i].name[0] = #0) then
      break;
    Inc(i);
  end;

  if (i = num_sfx) then
  begin
    if (num_sfx = MAX_SFX) then
      Com_Error(ERR_FATAL, 'S_FindName: out of sfx_t', []);
    Inc(num_sfx);
  end;

  sfx := @known_sfx[i];
  FillChar(sfx^, sizeof(sfx_t), 0);
  strcpy(sfx^.name, aliasname);

  sfx^.registration_sequence := s_registration_sequence;
  sfx^.truename := s;

  Result := sfx;
end;

(*
=====================
S_BeginRegistration

=====================
*)

procedure S_BeginRegistration;
begin
  Inc(s_registration_sequence);
  s_registering := true;
end;

(*
==================
S_RegisterSound

==================
*)

function S_RegisterSound(name: PChar): sfx_p;
var
  sfx: sfx_p;
begin
  if (sound_started = 0) then
  begin
    result := nil;
    exit;
  end;

  sfx := S_FindName(name, true);
  sfx^.registration_sequence := s_registration_sequence;

  if (not s_registering) then
    S_LoadSound(sfx);

  result := sfx;
end;

(*
=====================
S_EndRegistration

=====================
*)

procedure S_EndRegistration;
var
  i, size: Integer;
begin
  // free any sounds not from this registration sequence
  for i := 0 to num_sfx - 1 do
  begin
    if (known_sfx[i].name[0] = #0) then
      continue;
    if (known_sfx[i].registration_sequence <> s_registration_sequence) then
    begin                               // don't need this sound
      if (known_sfx[i].cache <> nil) then // it is possible to have a leftover
        Z_Free(known_sfx[i].cache);     // from a server that didn't finish loading
      FillChar(known_sfx[i], sizeof(sfx_t), 0);
    end
    else
    begin                               // make sure it is paged in
      if (known_sfx[i].cache <> nil) then
      begin
        size := known_sfx[i].cache.length * known_sfx[i].cache.width;
        Com_PageInMemory(PByte(known_sfx[i].cache), size);
      end;
    end;

  end;

  // load everything in
  for i := 0 to num_sfx - 1 do
  begin
    if (known_sfx[i].name[0] = #0) then
      continue;
    S_LoadSound(@known_sfx[i]);
  end;

  s_registering := false;
end;

//=============================================================================

(*
=================
S_PickChannel
=================
*)

function S_PickChannel(entnum, entchannel: Integer): channel_p;
var
  ch_idx,
    first_to_die,
    life_left: Integer;
  ch: channel_p;
begin
  if (entchannel < 0) then
    Com_Error(ERR_DROP, 'S_PickChannel: entchannel<0', []);

  // Check for replacement sound, or find the best one to replace
  first_to_die := -1;
  life_left := $7FFFFFFF;
  for ch_idx := 0 to MAX_CHANNELS - 1 do
  begin
    if ((entchannel <> 0) and           // channel 0 never overrides
      (channels[ch_idx].entnum = entnum) and
      (channels[ch_idx].entchannel = entchannel)) then
    begin                               // always override sound from same entity
      first_to_die := ch_idx;
      break;
    end;

    // don't let monster sounds override player sounds
    if ((channels[ch_idx].entnum = cl.playernum + 1) and
      (entnum <> cl.playernum + 1) and
      (channels[ch_idx].sfx <> nil)) then
      continue;

    if (channels[ch_idx]._end - paintedtime < life_left) then
    begin
      life_left := channels[ch_idx]._end - paintedtime;
      first_to_die := ch_idx;
    end;
  end;

  if (first_to_die = -1) then
  begin
    Result := nil;
    Exit;
  end;

  ch := @channels[first_to_die];
  FillChar(ch^, sizeof(channel_t), 0);

  Result := ch;
end;

(*
=================
S_SpatializeOrigin

Used for spatializing channels and autosounds
=================
*)

procedure S_SpatializeOrigin(const origin: vec3_t; master_vol, dist_mult: Single; var left_vol: Integer; var right_vol: Integer);
var
  dot,
    dist,
    lscale, rscale, scale: vec_t;
  source_vec: vec3_t;
begin
  if (cls.state <> ca_active) then
  begin
    left_vol := 255;
    right_vol := 255;
    exit;
  end;

  // calculate stereo seperation and distance attenuation
  VectorSubtract(origin, listener_origin, source_vec);

  dist := VectorNormalize(source_vec);
  dist := dist - SOUND_FULLVOLUME;
  if (dist < 0) then
    dist := 0;                          // close enough to be at full volume
  dist := dist * dist_mult;             // different attenuation levels

  dot := DotProduct(listener_right, source_vec);

  if ((dma.channels = 1) or (dist_mult = 0)) then
  begin                                 // no attenuation:=no spatialization
    rscale := 1.0;
    lscale := 1.0;
  end
  else
  begin
    rscale := 0.5 * (1.0 + dot);
    lscale := 0.5 * (1.0 - dot);
  end;

  // add in distance effect
  scale := (1.0 - dist) * rscale;
  right_vol := Trunc(master_vol * scale);
  if (right_vol < 0) then
    right_vol := 0;

  scale := (1.0 - dist) * lscale;
  left_vol := Trunc(master_vol * scale);
  if (left_vol < 0) then
    left_vol := 0;
end;

(*
=================
S_Spatialize
=================
*)

procedure S_Spatialize(ch: channel_p);
var
  origin: vec3_t;
begin
  // anything coming from the view entity will always be full volume
  if (ch^.entnum = cl.playernum + 1) then
  begin
    ch^.leftvol := ch^.master_vol;
    ch^.rightvol := ch^.master_vol;
    exit;
  end;

  if (ch^.fixed_origin) then
  begin
    VectorCopy(ch^.origin, origin);
  end
  else
    CL_GetEntitySoundOrigin(ch^.entnum, origin);

  S_SpatializeOrigin(origin, ch^.master_vol, ch^.dist_mult, ch^.leftvol, ch^.rightvol);
end;

(*
=================
S_AllocPlaysound
=================
*)

function S_AllocPlaysound: playsound_p;
var
  ps: playsound_p;
begin
  ps := s_freeplays.next;
  if (ps = @s_freeplays) then
  begin
    Result := nil;                      // no free playsounds
    Exit;
  end;

  // unlink from freelist
  ps^.prev^.next := ps^.next;
  ps^.next^.prev := ps^.prev;

  Result := ps;
end;

(*
=================
S_FreePlaysound
=================
*)

procedure S_FreePlaysound(ps: playsound_p);
begin
  // unlink from channel
  ps^.prev^.next := ps^.next;
  ps^.next^.prev := ps^.prev;

  // add to free list
  ps^.next := s_freeplays.next;
  s_freeplays.next^.prev := ps;
  ps^.prev := @s_freeplays;
  s_freeplays.next := ps;
end;

(*
===============
S_IssuePlaysound

Take the next playsound and begin it on the channel
This is never called directly by S_Play*, but only
by the update loop.
===============
*)

procedure S_IssuePlaysound(ps: playsound_p);
var
  ch: channel_p;
  sc: sfxcache_p;
begin
  if (s_show^.value <> 0) then
    Com_Printf('Issue %d'#10, [ps^._begin]);
  // pick a channel to play on
  ch := S_PickChannel(ps^.entnum, ps^.entchannel);
  if (ch = nil) then
  begin
    S_FreePlaysound(ps);
    exit;
  end;

  // spatialize
  if (ps^.attenuation = ATTN_STATIC) then
    ch^.dist_mult := ps^.attenuation * 0.001
  else
    ch^.dist_mult := ps^.attenuation * 0.0005;
  ch^.master_vol := Trunc(ps^.volume);
  ch^.entnum := ps^.entnum;
  ch^.entchannel := ps^.entchannel;
  ch^.sfx := ps^.sfx;
  VectorCopy(ps^.origin, ch^.origin);
  ch^.fixed_origin := ps^.fixed_origin;

  S_Spatialize(ch);

  ch^.pos := 0;
  sc := S_LoadSound(ch^.sfx);
  ch^._end := paintedtime + sc^.length;

  // free the playsound
  S_FreePlaysound(ps);
end;

//struct sfx_s *S_RegisterSexedSound (entity_state_t *ent, char *base);

function S_RegisterSexedSound(ent: entity_state_p; base: PChar): sfx_p;
var
  n: Integer;
  p: PChar;
  sfx: sfx_p;                           //struct sfx_s   *sfx;
  f: integer;
  model: array[0..MAX_QPATH - 1] of Char;
  sexedFilename: array[0..MAX_QPATH - 1] of Char;
  maleFilename: array[0..MAX_QPATH - 1] of Char;
begin
  // determine what model the client is using
  model[0] := #0;
  n := CS_PLAYERSKINS + ent^.number - 1;
  if (cl.configstrings[n][0] <> #0) then
  begin
    p := strchr(cl.configstrings[n], Byte('\'));
    if (p <> nil) then
    begin
      p := p + 1;
      strcpy(model, p);
      p := strchr(model, Byte('/'));
      if (p <> nil) then
        p^ := #0;
    end;
  end;
  // if we can't figure it out, they're male
  if (model[0] = #0) then
    strcpy(model, 'male');

  // see if we already know of the model specific sound
  Com_sprintf(sexedFilename, sizeof(sexedFilename), '#players/%s/%s', [model, base + 1]);
  sfx := S_FindName(sexedFilename, false);

  if (sfx = nil) then
  begin
    // no, so see if it exists
    if FS_FOpenFile(sexedFilename, f) > 0 then
    begin
      // yes, close the file and register it
      FS_FCloseFile(f);
      sfx := S_RegisterSound(sexedFilename);
    end
    else
    begin
      // no, revert to the male sound in the pak0.pak
      Com_sprintf(maleFilename, sizeof(maleFilename), 'player/%s/%s', ['male', base + 1]);
      sfx := S_AliasName(sexedFilename, maleFilename);
    end;
  end;

  Result := sfx;
end;

// =======================================================================
// Start a sound effect
// =======================================================================

(*
====================
S_StartSound

Validates the parms and ques the sound up
if pos is nil, the sound will be dynamically sourced from the entity
Entchannel 0 will never override a playing sound
====================
*)

procedure S_StartSound(origin: vec3_p; entnum, entchannel: Integer; sfx: sfx_p; fvol, attenuation, timeofs: Single);
var
  sc: sfxcache_p;
  vol, start: Integer;
  ps, sort: playsound_p;
begin
  if (sound_started = 0) then
    exit;

  if (sfx = nil) then
    exit;

  if (sfx^.name[0] = '*') then
    sfx := S_RegisterSexedSound(@cl_entities[entnum].current, sfx^.name);

  // make sure the sound is loaded
  sc := S_LoadSound(sfx);
  if (sc = nil) then
    exit;                               // couldn't load the sound's data

  vol := Trunc(fvol * 255);

  // make the playsound_t
  ps := S_AllocPlaysound();
  if (ps = nil) then
    exit;

  if (origin <> nil) then
  begin
    VectorCopy(origin^, ps^.origin);
    ps^.fixed_origin := true;
  end
  else
    ps^.fixed_origin := false;

  ps^.entnum := entnum;
  ps^.entchannel := entchannel;
  ps^.attenuation := attenuation;
  ps^.volume := vol;
  ps^.sfx := sfx;

  // drift s_beginofs
  start := Trunc(cl.frame.servertime * 0.001 * dma.speed) + s_beginofs;
  if (start < paintedtime) then
  begin
    start := paintedtime;
    s_beginofs := start - Trunc(cl.frame.servertime * 0.001 * dma.speed);
  end
  else if (start > paintedtime + 0.3 * dma.speed) then
  begin
    start := paintedtime + Trunc(0.1 * dma.speed);
    s_beginofs := start - Trunc(cl.frame.servertime * 0.001 * dma.speed);
  end
  else
  begin
    s_beginofs := s_beginofs - 10;
  end;

  if (timeofs = 0) then
    ps^._begin := paintedtime
  else
    ps^._begin := start + Trunc(timeofs * dma.speed);

  // sort into the pending sound list
 //   for (sort:=s_pendingplays.next ;
 //      sort != &s_pendingplays && sort^._begin < ps^._begin ;
 //      sort:=sort^.next);

  sort := s_pendingplays.next;
  while ((sort <> @s_pendingplays) and (sort^._begin < ps^._begin)) do
  begin
    sort := sort^.next;
  end;

  ps^.next := sort;
  ps^.prev := sort^.prev;

  ps^.next^.prev := ps;
  ps^.prev^.next := ps;
end;

(*
==================
S_StartLocalSound
==================
*)

procedure S_StartLocalSound(sound: PChar);
var
  sfx: sfx_p;
begin
  if (sound_started = 0) then
    exit;

  sfx := S_RegisterSound(sound);
  if (sfx = nil) then
  begin
    Com_Printf('S_StartLocalSound: can''t cache %s'#10, [sound]);
    exit;
  end;
  S_StartSound(nil, cl.playernum + 1, 0, sfx, 1, 1, 0);
end;

(*
==================
S_ClearBuffer
==================
*)

procedure S_ClearBuffer;
var
  clear: Integer;
begin
  if (sound_started = 0) then
    exit;

  s_rawend := 0;

  if (dma.samplebits = 8) then
    clear := $80
  else
    clear := 0;

  SNDDMA_BeginPainting();
  if (dma.buffer <> nil) then
    FillChar(dma.buffer^, dma.samples * dma.samplebits div 8, clear);
  SNDDMA_Submit();
end;

(*
==================
S_StopAllSounds
==================
*)

procedure S_StopAllSounds;
var
  i: Integer;
begin
  if (sound_started = 0) then
    exit;

  // clear all the playsounds
  FillChar(s_playsounds, sizeof(s_playsounds), 0);
  s_freeplays.next := @s_freeplays;
  s_freeplays.prev := @s_freeplays;
  s_pendingplays.next := @s_pendingplays;
  s_pendingplays.prev := @s_pendingplays;

  for i := 0 to MAX_PLAYSOUNDS - 1 do
  begin
    s_playsounds[i].prev := @s_freeplays;
    s_playsounds[i].next := s_freeplays.next;
    s_playsounds[i].prev^.next := @s_playsounds[i];
    s_playsounds[i].next^.prev := @s_playsounds[i];
  end;

  // clear all the channels
  FillChar(channels, sizeof(channels), 0);

  S_ClearBuffer();
end;

(*
==================
S_AddLoopSounds

Entities with a ->sound field will generated looped sounds
that are automatically started, stopped, and merged together
as the entities are sent to the client
==================
*)

procedure S_AddLoopSounds;
var
  i, j, num: Integer;
  sounds: array[0..MAX_EDICTS - 1] of Integer;
  left, right, left_total, right_total: Integer;
  ch: channel_p;
  sfx: sfx_p;
  sc: sfxcache_p;
  ent: entity_state_p;
begin
  if (cl_paused^.value <> 0) then
    exit;

  if (cls.state <> ca_active) then
    exit;

  if (not cl.sound_prepped) then
    exit;

  for i := 0 to cl.frame.num_entities - 1 do
  begin
    num := (cl.frame.parse_entities + i) and (MAX_PARSE_ENTITIES - 1);
    ent := @cl_parse_entities[num];
    sounds[i] := ent^.sound;
  end;

  for i := 0 to cl.frame.num_entities - 1 do
  begin
    if (sounds[i] = 0) then
      continue;

    sfx := cl.sound_precache[sounds[i]];
    if (sfx = nil) then
      continue;                         // bad sound effect
    sc := sfx^.cache;
    if (sc = nil) then
      continue;

    num := (cl.frame.parse_entities + i) and (MAX_PARSE_ENTITIES - 1);
    ent := @cl_parse_entities[num];

    // find the total contribution of all sounds of this type
    S_SpatializeOrigin(ent^.origin, 255.0, SOUND_LOOPATTENUATE,
      left_total, right_total);
    for j := i + 1 to cl.frame.num_entities - 1 do
    begin
      if (sounds[j] <> sounds[i]) then
        continue;
      sounds[j] := 0;                   // don't check this again later

      num := (cl.frame.parse_entities + j) and (MAX_PARSE_ENTITIES - 1);
      ent := @cl_parse_entities[num];

      S_SpatializeOrigin(ent^.origin, 255.0, SOUND_LOOPATTENUATE,
        left, right);
      left_total := left_total + left;
      right_total := right_total + right;
    end;

    if ((left_total = 0) and (right_total = 0)) then
      continue;                         // not audible

    // allocate a channel
    ch := S_PickChannel(0, 0);
    if (ch = nil) then
      exit;

    if (left_total > 255) then
      left_total := 255;
    if (right_total > 255) then
      right_total := 255;
    ch^.leftvol := left_total;
    ch^.rightvol := right_total;
    ch^.autosound := true;              // remove next frame
    ch^.sfx := sfx;
    ch^.pos := paintedtime mod sc^.length;
    ch^._end := paintedtime + sc^.length - ch^.pos;
  end;
end;

//=============================================================================

(*
============
S_RawSamples

Cinematic streaming and voice over network
============
*)

procedure S_RawSamples(samples, rate, width, channels: Integer; data: PByte);
var
  i, src, dst: Integer;
  scale: Single;
begin
  if (sound_started = 0) then
    exit;

  if (s_rawend < paintedtime) then
    s_rawend := paintedtime;
  scale := rate / dma.speed;

  //Com_Printf ("%d < %d < %d"#10, soundtime, paintedtime, s_rawend);
  if ((channels = 2) and (width = 2)) then
  begin
    if (scale = 1.0) then
    begin                               // optimized case
      for i := 0 to samples - 1 do
      begin
        dst := s_rawend and (MAX_RAW_SAMPLES - 1);
        Inc(s_rawend);
        s_rawsamples_[dst].left :=
          LittleShort(PSmallIntArray(data)[i * 2]) shl 8;
        s_rawsamples_[dst].right :=
          LittleShort(PSmallIntArray(data)[i * 2 + 1]) shl 8;
      end;
    end
    else
    begin
      i := 0;
      while (True) do
      begin
        src := Trunc(i * scale);
        if (src >= samples) then
          break;
        dst := s_rawend and (MAX_RAW_SAMPLES - 1);
        Inc(s_rawend);
        s_rawsamples_[dst].left :=
          LittleShort(PSmallIntArray(data)[src * 2]) shl 8;
        s_rawsamples_[dst].right :=
          LittleShort(PSmallIntArray(data)[src * 2 + 1]) shl 8;
        Inc(i);
      end;
    end;
  end
  else if ((channels = 1) and (width = 2)) then
  begin
    i := 0;
    while (True) do
    begin
      src := Trunc(i * scale);
      if (src >= samples) then
        break;
      dst := s_rawend and (MAX_RAW_SAMPLES - 1);
      Inc(s_rawend);
      s_rawsamples_[dst].left :=
        LittleShort(PSmallIntArray(data)[src]) shl 8;
      s_rawsamples_[dst].right :=
        LittleShort(PSmallIntArray(data)[src]) shl 8;
      Inc(i);
    end;
  end
  else if ((channels = 2) and (width = 1)) then
  begin
    i := 0;
    while (True) do
    begin
      src := Trunc(i * scale);
      if (src >= samples) then
        break;
      dst := s_rawend and (MAX_RAW_SAMPLES - 1);
      Inc(s_rawend);
      s_rawsamples_[dst].left :=
        PShortIntArray(data)[src * 2] shl 16;
      s_rawsamples_[dst].right :=
        PShortIntArray(data)[src * 2 + 1] shl 16;
      Inc(i);
    end;
  end
  else if ((channels = 1) and (width = 1)) then
  begin
    i := 0;
    while (True) do
    begin
      src := Trunc(i * scale);
      if (src >= samples) then
        break;
      dst := s_rawend and (MAX_RAW_SAMPLES - 1);
      Inc(s_rawend);
      s_rawsamples_[dst].left :=
        (PByteArray(data)[src] - 128) shl 16;
      s_rawsamples_[dst].right :=
        (PByteArray(data)[src] - 128) shl 16;
      Inc(i);
    end;
  end;
end;

//=============================================================================

(*
============
S_Update

Called once each time through the main loop
============
*)

procedure S_Update(const origin, _forward, right, up: vec3_t);
var
  i, total: Integer;
  ch, combine: channel_p;
label
  continue_;
begin
  if (sound_started = 0) then
    exit;

  // if the laoding plaque is up, clear everything
  // out to make sure we aren't looping a dirty
  // dma buffer while loading
  if (cls.disable_screen <> 0) then
  begin
    S_ClearBuffer;
    exit;
  end;

  // rebuild scale tables if volume is modified
  if (s_volume^.modified) then
    S_InitScaletable;

  VectorCopy(origin, listener_origin);
  VectorCopy(_forward, listener_forward);
  VectorCopy(right, listener_right);
  VectorCopy(up, listener_up);

  combine := nil;

  // update spatialization for dynamic sounds
  ch := @channels;
  for i := 0 to MAX_CHANNELS - 1 do
  begin
    if (ch^.sfx = nil) then
      goto continue_;
    if (ch^.autosound) then
    begin                               // autosounds are regenerated fresh each frame
      FillChar(ch^, sizeof(channel_t), 0);
      goto continue_;
    end;
    S_Spatialize(ch);                   // respatialize channel
    if ((ch^.leftvol = 0) and (ch^.rightvol = 0)) then
    begin
      FillChar(ch^, sizeof(channel_t), 0);
      goto continue_;
    end;
    continue_:
    inc(ch);
  end;

  // add loopsounds
  S_AddLoopSounds;

  //
  // debugging output
  //
  if (s_show^.value <> 0) then
  begin
    total := 0;
    ch := @channels;
    for i := 0 to MAX_CHANNELS - 1 do
    begin
      if ((ch^.sfx <> nil) and ((ch^.leftvol <> 0) or (ch^.rightvol <> 0))) then
      begin
        Com_Printf('%3d %3d %s'#10, [ch^.leftvol, ch^.rightvol, ch^.sfx^.name]);
        Inc(total);
      end;
      Inc(ch);
    end;
    Com_Printf('----(%d)---- painted: %d'#10, [total, paintedtime]);
  end;

  // mix some sound
  S_Update_();
end;

var
  buffers: Integer = 0;
  oldsamplepos: Integer = 0;

procedure GetSoundtime;
var
  samplepos: Integer;
  fullsamples: Integer;
begin
  fullsamples := dma.samples div dma.channels;

  // it is possible to miscount buffers if it has wrapped twice between
  // calls to S_Update.  Oh well.
  samplepos := SNDDMA_GetDMAPos();

  if (samplepos < oldsamplepos) then
  begin
    Inc(buffers);                       // buffer wrapped

    if (paintedtime > $40000000) then
    begin                               // time to chop things off to aprocedure 32 bit limits
      buffers := 0;
      paintedtime := fullsamples;
      S_StopAllSounds;
    end;
  end;
  oldsamplepos := samplepos;

  soundtime := buffers * fullsamples + samplepos div dma.channels;
end;

procedure S_Update_;
var
  endtime: Cardinal;
  samps: Integer;
begin
  if (sound_started = 0) then
    exit;

  SNDDMA_BeginPainting;

  if (dma.buffer = nil) then
    exit;

  // Updates DMA time
  GetSoundtime();

  // check to make sure that we haven't overshot
  if (paintedtime < soundtime) then
  begin
    Com_DPrintf('S_Update_ : overflow'#10, []);
    paintedtime := soundtime;
  end;

  // mix ahead of current position
  endtime := Trunc(soundtime + s_mixahead^.value * dma.speed);
  //endtime:=(soundtime + 4096) & ~4095;

   // mix to an even submission block size
  endtime := (endtime + dma.submission_chunk - 1) and
    not (dma.submission_chunk - 1);
  samps := dma.samples shr (dma.channels - 1);
  if (endtime - soundtime > samps) then
    endtime := soundtime + samps;

  S_PaintChannels(endtime);

  SNDDMA_Submit();
end;

(*
===============================================================================

console functions

===============================================================================
*)

procedure S_Play;
var
  i: Integer;
  name: array[0..255] of Char;
  sfx: sfx_p;
begin
  i := 1;
  while (i < Cmd_Argc()) do
  begin
    if not (strchr(Cmd_Argv(i), Byte('.')) <> nil) then
    begin
      strcpy(name, Cmd_Argv(i));
      strcat(name, '.wav');
    end
    else
      strcpy(name, Cmd_Argv(i));
    sfx := S_RegisterSound(name);
    S_StartSound(nil, cl.playernum + 1, 0, sfx, 1.0, 1.0, 0);
    Inc(i);
  end;
end;

procedure S_SoundList;
var
  i: Integer;
  sc: sfxcache_p;
  size: Integer;
  total: Integer;
begin
  total := 0;
  for i := 0 to num_sfx - 1 do
  begin
    if (known_sfx[i].registration_sequence = 0) then
      continue;
    sc := known_sfx[i].cache;
    if (sc <> nil) then
    begin
      size := sc^.length * sc^.width * (sc^.stereo + 1);
      total := total + size;
      if (sc^.loopstart >= 0) then
        Com_Printf('L', [])
      else
        Com_Printf(' ', []);
      Com_Printf('(%2db) %6i : %s'#10, [sc^.width * 8, size, known_sfx[i].name]);
    end
    else
    begin
      if (known_sfx[i].name[0] = '*') then
        Com_Printf('  placeholder : %s'#10, [known_sfx[i].name])
      else
        Com_Printf('  not loaded  : %s'#10, [known_sfx[i].name]);
    end;
  end;
  Com_Printf('Total resident: %d'#10, [total]);
end;

end.
