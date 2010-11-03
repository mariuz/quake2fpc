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
{ File(s): server.c                                                          }
{ Content:                                                                   }
{                                                                            }
{ Initial conversion by : osamaao                                            }
{ Initial conversion on : 12-Jan-2002                                        }
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
{ none                                                                       }
{----------------------------------------------------------------------------}
// 25.07.2002 Juha: Proof-readed this unit
// server.h
//define   PARANOID         // speed sapping error checking

unit server;

interface

uses
  Common,
  GameUnit,
  qfiles,
  q_shared;

const
  MAX_MASTERS = 8;                      // max recipients for heartbeat packets
  LATENCY_COUNTS = 16;
  RATE_MESSAGES = 10;

  // MAX_CHALLENGES is made large to prevent a denial
  // of service attack that could cycle all of them
  // out before legitimate users connected
  MAX_CHALLENGES = 1024;

type

  redirect_t = (RD_NONE, RD_CLIENT, RD_PACKET);
  redirect_p = ^redirect_t;

  server_state_p = ^server_state_t;
  server_state_t = (
    ss_dead,                            // no map loaded
    ss_loading,                         // spawning level edicts
    ss_game,                            // actively running
    ss_cinematic,
    ss_demo,
    ss_pic);
  // some qc commands are only valid before the server has finished
  // initializing (precache commands, static sounds / objects, etc)

  server_p = ^server_t;
  server_t = record
    State: server_state_t;              // precache commands are only valid during load
    attractloop: qboolean;              // running cinematics and demos for the local system only
    loadgame: qboolean;                 // client begins should reuse existing entity
    time: Cardinal;                     // always sv.framenum * 100 msec
    framenum: Integer;
    name: array[0..MAX_QPATH - 1] of char; // map name, or cinematic name
    models: array[0..MAX_MODELS - 1] of cmodel_p;
    configstrings: array[0..MAX_CONFIGSTRINGS - 1, 0..MAX_QPATH - 1] of char;
    baselines: array[0..MAX_EDICTS - 1] of entity_state_t;

    // the multicast buffer is used to send a message to a set of clients
    // it is only used to marshall data until SV_Multicast is called
    multicast: Sizebuf_t;
    multicast_buf: array[0..MAX_MSGLEN - 1] of byte;

    // demo server information
    demofile: integer;                  //File handle
    timedemo: qBoolean;                 // don't time sync
  end;

  client_state_t = (
    cs_free,                            // can be reused for a new connection
    cs_zombie,                          // client has been disconnected, but don't reuse
    // connection for a couple seconds
    cs_connected,                       // has been assigned to a client_t, but not in game yet
    cs_spawned                          // client is fully in game
    );

  client_frame_p = ^client_frame_t;
  client_frame_t = record
    areaBytes: Integer;
    areaBits: array[0..(MAX_MAP_AREAS div 8) - 1] of byte; // portalarea visibility bits
    ps: player_state_t;
    num_entities: Integer;
    first_entity: Integer;              // into the circular sv_packet_entities[]
    SentTime: Integer;                  // for ping calculations
  end;

  client_p = ^client_s;
  client_s = record
    state: client_state_t;
    userinfo: array[0..MAX_INFO_STRING - 1] of char; // name, etc
    lastframe: Integer;                 // for delta compression
    lastcmd: usercmd_t;                 // for filling in big drops
    commandMsec: Integer;               // every seconds this is reset, if user
    // commands exhaust it, assume time cheating
    frame_latency: array[0..LATENCY_COUNTS - 1] of Integer;
    ping: Integer;
    message_size: array[0..RATE_MESSAGES - 1] of Integer; // used to rate drop packets
    rate: Integer;
    surpressCount: Integer;             // number of messages rate supressed
    edict: edict_p;                     // EDICT_NUM(clientnum+1)
    name: array[0..32 - 1] of char;     // extracted from userinfo, high bits masked
    messagelevel: Integer;              // for filtering printed messages
    // The datagram is written to by sound calls, prints, temp ents, etc.
    // It can be harmlessly overflowed.
    datagram: sizebuf_t;
    datagram_buf: array[0..MAX_MSGLEN - 1] of byte;
    frames: array[0..UPDATE_BACKUP - 1] of client_frame_t; // updates can be delta'd from here
    download: PByte;                    // file being downloaded
    downloadsize: Integer;              // total bytes (can't use EOF because of paks)
    downloadcount: Integer;             // bytes sent
    lastmessage: Integer;               // sv.framenum when packet was last received
    lastconnect: Integer;
    challenge: Integer;                 // challenge of this user, randomly generated
    netchan: netchan_t;
  end;
  client_t = client_s;

  // a client can leave the server in one of four ways:
  // dropping properly by quiting or disconnecting
  // timing out if no valid messages are received for timeout.value seconds
  // getting kicked off by the server operator
  // a program error, like an overflowed reliable buffer

  challenge_p = ^challenge_t;
  challenge_t = record
    Adr: NetAdr_t;
    Challenge: Integer;
    Time: Integer;
  end;

  TEntityStateArr = array[0..0] of entity_state_t;
  PEntityStateArr = ^TEntityStateArr;
  TClientArr = array[0..0] of client_t;
  PClientArr = ^TClientArr;

  server_static_p = ^server_static_t;
  server_static_t = record
    initialized: qboolean;              // sv_init has completed
    realtime: Integer;                  // always increasing, no clamping, etc
    MapCmd: array[0..MAX_TOKEN_CHARS - 1] of char; // ie: *intro.cin+base
    spawncount: Integer;                // incremented each server start
    // used to check late spawns
    Clients: PClientArr;                // [maxclients->value];
    Num_Client_Entities: Integer;       // maxclients->value*UPDATE_BACKUP*MAX_PACKET_ENTITIES
    Next_Client_Entities: Integer;      // next client_entity to use
    Client_Entities: PEntityStateArr;   // [num_client_entities]
    Last_HeartBeat: Integer;
    challenges: array[0..MAX_CHALLENGES - 1] of challenge_t; // to prevent invalid IPs from connecting
    // serverrecord values
    DemoFile: integer;                  // File handle
    demo_multicast: SizeBuf_t;
    demo_multicast_buf: array[0..MAX_MSGLEN - 1] of byte;
  end;

function NUM_FOR_EDICT(e: edict_p): Integer;
function EDICT_NUM(n: integer): edict_p;

const
  SV_OUTPUTBUF_LENGTH = MAX_MSGLEN - 16;

implementation

uses
  sv_game;

function EDICT_NUM(n: integer): edict_p;
begin
  Result := Pointer(Cardinal(ge.Edicts) + ge.Edict_size * n);
end;

function NUM_FOR_EDICT(e: edict_p): Integer;
begin
  Result := (Cardinal(e) - Cardinal(ge.Edicts)) div ge.Edict_size;
end;

end.
