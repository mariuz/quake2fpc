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


{$ALIGN ON}{$MINENUMSIZE 4}
{----------------------------------------------------------------------------}
{                                                                            }
{ File(s): client\client.c                                                   }
{                                                                            }
{ Initial conversion by : ?                                                  }
{ Initial conversion on : ?                                                  }
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
unit Client;

interface

uses
  {$IFDEF WIN32}
  Windows,
  {$ENDIF}
  qfiles,
  Common,
  q_shared,
  snd_loc,
  ref,
  Sound_h;

{ Constants moved together }
const
  MAX_CLIENTWEAPONMODELS = 20;          { PGM -- upped from 16 to fit the chainfist vwep }
  CMD_BACKUP = 64;                      { allow a lot of command backups for very fast systems }

  { the cl_parse_entities must be large enough to hold UPDATE_BACKUP frames of }
  { entities, so that when a delta compressed message arives from the server }
  { it can be un-deltad from the original }
  MAX_PARSE_ENTITIES = 1024;

  MAX_SUSTAINS = 32;

  PARTICLE_GRAVITY = 40;
  BLASTER_PARTICLE_COLOR = $E0;
  { PMM }
  INSTANT_PARTICLE = -10000.0;
  { PGM }

{ Types Moved Together }
type
  { Juha: Added this type to make it a bit more clear that this is file
    handle, not just "integer" }
  TFileHandle = Integer;

  image_p = pointer;
  model_p = pointer;

  { frame_t }
  frame_p = ^frame_t;
  frame_t = packed record
    valid: QBOOLEAN;                    { cleared if delta parsing was invalid }
    serverframe: Integer;
    servertime: Integer;                { server time the message is valid for (in msec) }
    deltaframe: Integer;
    areabits: array[0..(MAX_MAP_AREAS shr 3) - 1] of BYTE; { portalarea visibility bits }
    playerstate: PLAYER_STATE_T;
    num_entities: Integer;
    parse_entities: Integer;            { non-masked index into cl_parse_entities array }
  end { frame_t };

  { centity_t }
  centity_p = ^centity_t;
  centity_t = packed record
    baseline: entity_state_t;           { delta from this if not from a previous frame }
    current: entity_state_t;
    prev: entity_state_t;               { will always be valid, but might just be a copy of current }
    serverframe: Integer;               { if not current, this ent isn't in the frame }
    trailcount: Integer;                { for diminishing grenade trails }
    lerp_origin: vec3_t;                { for trails (variable hz) }
    fly_stoptime: Integer;
  end { centity_t };

  { clientinfo_t }
  clientinfo_p = ^clientinfo_t;
  clientinfo_t = packed record
    name: array[0..MAX_QPATH - 1] of Char;
    cinfo: array[0..MAX_QPATH - 1] of Char;
    skin: image_p;
    icon: image_p;
    iconname: array[0..MAX_QPATH - 1] of Char;
    model: model_p;
    weaponmodel: array[0..MAX_CLIENTWEAPONMODELS - 1] of model_p;
  end { clientinfo_t };

  { client_state_t }
  { The client_state_t structure is wiped completely at every }
  { server map change }
  client_state_p = ^client_state_t;
  client_state_t = packed record
    timeoutcount: Integer;
    timedemo_frames: Integer;
    timedemo_start: Integer;
    refresh_prepped: QBOOLEAN;          { false if on new level or new ref dll }
    sound_prepped: QBOOLEAN;            { ambient sounds can start }
    force_refdef: QBOOLEAN;             { vid has changed, so we can't use a paused refdef }
    parse_entities: Integer;            { index (not anded off) into cl_parse_entities[] }
    cmd: USERCMD_T;
    cmds: array[0..CMD_BACKUP - 1] of USERCMD_T; { each mesage will send several old cmds }
    cmd_time: array[0..CMD_BACKUP - 1] of Integer; { time sent, for calculating pings }
    predicted_origins: array[0..CMD_BACKUP - 1] of array[0..3 - 1] of SmallInt; { for debug comparing against server }
    predicted_step: Single;             { for stair up smoothing }
    predicted_step_time: Word;
    predicted_origin: vec3_t;           { generated by CL_PredictMovement }
    predicted_angles: vec3_t;
    prediction_error: vec3_t;
    frame: FRAME_T;                     { received from server }
    surpressCount: Integer;             { number of messages rate supressed }
    frames: array[0..UPDATE_BACKUP - 1] of FRAME_T;
    { the client maintains its own idea of view angles, which are }
    { sent to the server each frame. It is cleared to 0 upon entering each level. }
    { the server sends a delta each frame which is added to the locally }
    { tracked view angles to account for standing on rotating objects, }
    { and teleport direction changes }
    viewangles: vec3_t;
    time: Integer;                      { this is the time value that the client }
    { is rendering at. always <= cls.realtime }
    lerpfrac: Single;                   { between oldframe and frame }
    refdef: REFDEF_T;
    v_forward, v_right, v_up: vec3_t;   { set when refdef.angles is set }
    {/// }
    { transient data from server }
    {/// }
    layout: array[0..1024 - 1] of Char; { general 2D overlay }
    inventory: array[0..MAX_ITEMS - 1] of Integer;
    {/// }
    { non-gameserver infornamtion }
    { FIXME: move this cinematic stuff into the cin_t structure }
    cinematic_file: TFileHandle;
    cinematictime: Integer;             { cls.realtime for first cinematic frame }
    cinematicframe: Integer;
    cinematicpalette: array[0..768 - 1] of Char;
    cinematicpalette_active: QBOOLEAN;
    {/// }
    { server state information }
    {/// }
    attractloop: QBOOLEAN;              { running the attract loop, any key will menu }
    servercount: Integer;               { server identification for prespawns }
    gamedir: array[0..MAX_QPATH - 1] of Char;
    playernum: Integer;
    configstrings: array[0..MAX_CONFIGSTRINGS - 1] of array[0..MAX_QPATH - 1] of Char;
    {/// }
    { locally derived information from server state }
    {/// }
    model_draw: array[0..MAX_MODELS - 1] of model_p;
    model_clip: array[0..MAX_MODELS - 1] of cmodel_p;
    sound_precache: array[0..MAX_SOUNDS - 1] of sfx_p;
    image_precache: array[0..MAX_IMAGES - 1] of image_p;
    clientinfo: array[0..MAX_CLIENTS - 1] of CLIENTINFO_T;
    baseclientinfo: CLIENTINFO_T;
  end { client_state_t };

  { ================================================================== }

  { the client_static_t structure is persistant through an arbitrary
  { number of server connections }

  { ================================================================== }

    { connstate_t enumeration }
  connstate_t = (ca_uninitialized, ca_disconnected, ca_connecting, ca_connected, ca_active);

  { dltype_t enumeration }
  dltype_t = (dl_none, dl_model, dl_sound, dl_skin, dl_single);

  { keydest_t enumeration }
  keydest_t = (key_game, key_console, key_message, key_menu);

  { client_static_t }
  client_static_t = packed record
    state: CONNSTATE_T;
    key_dest: KEYDEST_T;
    framecount: Integer;
    realtime: Integer;                  { always increasing, no clamping, etc }
    frametime: Single;                  { seconds since last frame }
    { screen rendering information }
    disable_screen: Single;             { showing loading plaque between levels }
    { or changing rendering dlls }
    { if time gets > 30 seconds ahead, break it }
    disable_servercount: Integer;       { when we receive a frame and cl.servercount }
    { > cls.disable_servercount, clear disable_screen }

{ connection information }
    servername: array[0..MAX_OSPATH - 1] of Char; { name of server from original connect }
    connect_time: Single;               { for connection retransmits }
    quakePort: Integer;                 { a 16 bit value that allows quake servers }
    { to work around address translating routers }
    netchan: NETCHAN_T;
    serverProtocol: Integer;            { in case we are doing some kind of version hack }
    challenge: Integer;                 { from the server to use for connecting }
    download: TFileHandle;              { file transfer from server }
    downloadtempname: array[0..MAX_OSPATH - 1] of Char;
    downloadname: array[0..MAX_OSPATH - 1] of Char;
    downloadnumber: Integer;
    downloadtype: DLTYPE_T;
    downloadpercent: Integer;
    { demo recording info must be here, so it isn't cleared on level change }
    demorecording: QBOOLEAN;
    demowaiting: QBOOLEAN;              { don't record until a non-delta message is received }
    demofile: TFileHandle;
  end { client_static_t };

  { cdlight_t }
  cdlight_p = ^cdlight_t;
  cdlight_t = packed record
    key: Integer;                       { so entities can reuse same entry }
    color: vec3_t;
    origin: vec3_t;
    radius: Single;
    die: Single;                        { stop lighting after this time }
    decay: Single;                      { drop this each second }
    minlight: Single;                   { don't add when contributing less }
  end { cdlight_t };

  { ROGUE }

  { cl_sustain }
  cl_sustain_p = ^cl_sustain_t;
  cl_sustain_t = record
    id: Integer;
    ttype: Integer;
    endtime: Integer;
    nextthink: Integer;
    thinkinterval: Integer;
    org: vec3_t;
    dir: vec3_t;
    color: Integer;
    count: Integer;
    magnitude: Integer;
    think: procedure(self: cl_sustain_p); cdecl;
  end { cl_sustain };

  { PGM }
  { cparticle_t }
  cparticle_p = ^cparticle_t;
  cparticle_t = record
    next: cparticle_p;
    time: Single;
    org: vec3_t;
    vel: vec3_t;
    accel: vec3_t;
    color: Single;
    colorvel: Single;
    alpha: Single;
    alphavel: Single;
  end { particle_s };

  {/// }
  {/// cl_input }
  {/// }
  { kbutton_t }
  kbutton_p = ^kbutton_t;
  kbutton_t = record
    down: array[0..2 - 1] of Integer;   { key nums holding it down }
    downtime: Word;                     { msec timestamp }
    msec: Word;                         { msec down this frame }
    state: Integer;
  end { kbutton_t };

  { Variables Moved Together }
var
  in_mlook, in_klook: kbutton_t;
  in_strafe: kbutton_t;
  in_speed: kbutton_t;

  {/// }
  {/// cl_view.c }
  {/// }
  gun_frame: Integer;
  gun_model: model_p;

implementation

end.
