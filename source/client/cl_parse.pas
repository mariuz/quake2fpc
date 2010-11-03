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
{ File(s): cl_parse                                                          }
{ Content: parse a message received from the server                          }
{                                                                            }
{ Initial conversion by : Ter Roshak                                         }
{ Initial conversion on : -                                                  }
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
// cl_parse.c  -- parse a message received from the server
unit cl_parse;

interface

uses
  q_shared,
  client;

const
  svc_strings: array[0..255] of PChar =
  (
    'svc_bad',
    'svc_muzzleflash',
    'svc_muzzlflash2',
    'svc_temp_entity',
    'svc_layout',
    'svc_inventory',
    'svc_nop',
    'svc_disconnect',
    'svc_reconnect',
    'svc_sound',
    'svc_print',
    'svc_stufftext',
    'svc_serverdata',
    'svc_configstring',
    'svc_spawnbaseline',
    'svc_centerprint',
    'svc_download',
    'svc_playerinfo',
    'svc_packetentities',
    'svc_deltapacketentities',
    'svc_frame',
    nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
    nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
    nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
    nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
    nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
    nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
    nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
    nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
    nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
    nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
    nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
    nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
    nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
    nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
    nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
    nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
    nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
    nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
    nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
    nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
    nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
    nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
    nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
    nil, nil, nil, nil, nil
    );

procedure CL_ParseClientinfo(player: Integer);
procedure CL_LoadClientinfo(ci: clientinfo_p; s: pchar);
procedure CL_ParseServerMessage();
procedure CL_RegisterSounds();
function CL_CheckOrDownloadFile(filename: pchar): qboolean;
procedure CL_Download_f(); cdecl;
procedure SHOWNET(s: pchar);

implementation

uses
  cl_inv,
  cl_cin,
  cl_main,
  cl_tent,
  cl_ents,
  cl_view,
  cl_fx,
  cl_scrn,
  {$IFDEF WIN32}
  cd_win,
  sys_win,
  vid_dll,
  {$ELSE}
  cd_sdl,
  sys_linux,
  vid_so,
  {$ENDIF}
  net_chan,
  SysUtils,
  snd_dma,
  Files,
  Common,
  Cmd,
  Console,
  CModel,
  CVar,
  CPas;

//=============================================================================

procedure CL_DownloadFileName(dest: pchar; destlen: integer; fn: pchar);
begin
  if strncmp(fn, 'players', 7) = 0 then
    Com_sprintf(dest, destlen, '%s/%s', [BASEDIRNAME, fn])
  else
    Com_sprintf(dest, destlen, '%s/%s', [FS_Gamedir(), fn]);
end;

{*
===============
CL_CheckOrDownloadFile

Returns true if the file exists, otherwise it attempts
to start a download from the server.
===============
*}
function CL_CheckOrDownloadFile(filename: pchar): qboolean;
var
  fp: integer;
  name: array[0..MAX_OSPATH - 1] of char;
  len: Integer;
begin
  if (strstr(filename, '..') <> nil) then
  begin
    Com_Printf('Refusing to download a path with ..'#10, []);
    Result := True;
    exit;
  end;

  if (FS_LoadFile(filename, nil) <> -1) then
  begin
    // it exists, no need to download
    Result := True;
    exit;
  end;

  strcpy(cls.downloadname, filename);

  // download to a temp name, and only rename
  // to the real name when done, so if interrupted
  // a runt file wont be left
  COM_StripExtension(cls.downloadname, cls.downloadtempname);
  strcat(cls.downloadtempname, '.tmp');

  //ZOID
   // check to see if we already have a tmp for this file, if so, try to resume
   // open the file if not opened yet
  CL_DownloadFileName(name, sizeof(name), cls.downloadtempname);

  //   FS_CreatePath (name);

  fp := FileOpen(name, fmOpenReadWrite);
  if (fp <> -1) then
  begin                                 // it exists
    len := FileSeek(fp, 0, 2);

    cls.download := fp;

    // give the server an offset to start the download
    Com_Printf('Resuming %s'#10, [cls.downloadname]);
    MSG_WriteByte(cls.netchan.message, Integer(clc_stringcmd));
    MSG_WriteString(cls.netchan.message,
      va('download %s %d', [cls.downloadname, len]));
  end
  else
  begin
    Com_Printf('Downloading %s'#10, [cls.downloadname]);
    MSG_WriteByte(cls.netchan.message, Integer(clc_stringcmd));
    MSG_WriteString(cls.netchan.message,
      va('download %s', [cls.downloadname]));
  end;

  Inc(cls.downloadnumber);

  Result := false;
end;

{*
===============
CL_Download_f

Request a download from the server
===============
*}
procedure CL_Download_f();
var
  filename: array[0..MAX_OSPATH - 1] of char;
begin
  if (Cmd_Argc() <> 2) then
  begin
    Com_Printf('Usage: download <filename>'#10);
    exit;
  end;

  Com_sprintf(filename, sizeof(filename), '%s', [Cmd_Argv(1)]);

  if (strstr(filename, '..') <> nil) then
  begin
    Com_Printf('Refusing to download a path with ..'#10);
    exit;
  end;

  if (FS_LoadFile(filename, nil) <> -1) then
  begin
    // it exists, no need to download
    Com_Printf('File already exists.'#10);
    exit;
  end;

  strcpy(cls.downloadname, filename);
  Com_Printf('Downloading %s'#10, [cls.downloadname]);

  // download to a temp name, and only rename
  // to the real name when done, so if interrupted
  // a runt file wont be left
  COM_StripExtension(cls.downloadname, cls.downloadtempname);
  strcat(cls.downloadtempname, '.tmp');

  MSG_WriteByte(cls.netchan.message, Integer(clc_stringcmd));
  MSG_WriteString(cls.netchan.message,
    va('download %s', [cls.downloadname]));

  Inc(cls.downloadnumber);
end;

{*
======================
CL_RegisterSounds
======================
*}
procedure CL_RegisterSounds();
var
  i: integer;
begin
  S_BeginRegistration();
  CL_RegisterTEntSounds();
  for i := 1 to MAX_SOUNDS - 1 do
  begin
    if (cl.configstrings[CS_SOUNDS + i][0] = #0) then
      break;
    cl.sound_precache[i] := S_RegisterSound(cl.configstrings[CS_SOUNDS + i]);
    Sys_SendKeyEvents();                // pump message loop
  end;
  S_EndRegistration();
end;

{*
=====================
CL_ParseDownload

A download message has been received from the server
=====================
*}
procedure CL_ParseDownload();
var
  size, percent: Integer;
  name: array[0..MAX_OSPATH - 1] of char;
  r: boolean;
  oldn: array[0..MAX_OSPATH - 1] of char;
  newn: array[0..MAX_OSPATH - 1] of char;
begin
  // read the data
  size := MSG_ReadShort(net_message);
  percent := MSG_ReadByte(net_message);
  if (size = -1) then
  begin
    Com_Printf('Server does not have this file.'#10);
    if (cls.download > 0) then
    begin
      // if here, we tried to resume a file but the server said no
      FileClose(cls.download);
      cls.download := 0;
    end;
    CL_RequestNextDownload();
    exit;
  end;

  // open the file if not opened yet
  if (cls.download <= 0) then
  begin
    CL_DownloadFileName(name, sizeof(name), cls.downloadtempname);

    FS_CreatePath(name);

    cls.download := FileOpen(name, fmOpenReadWrite);
    if (cls.download = -1) then
    begin
      net_message.readcount := net_message.readcount + size;
      Com_Printf('Failed to open %s'#10, [cls.downloadtempname]);
      CL_RequestNextDownload();
      cls.download := 0;
      exit;
    end;
  end;

  FileWrite(cls.download, Pointer(Cardinal(net_message.data) + net_message.readcount)^, size);
  net_message.readcount := net_message.readcount + size;

  if (percent <> 100) then
  begin
    // request next block
  // change display routines by zoid
  {
    Com_Printf (".");
    if (10*(percent/10) != cls.downloadpercent)
    begin
     cls.downloadpercent = 10*(percent/10);
     Com_Printf ("%i%%", cls.downloadpercent);
      end;
  }
    cls.downloadpercent := percent;

    MSG_WriteByte(cls.netchan.message, Integer(clc_stringcmd));
    SZ_Print(cls.netchan.message, 'nextdl');
  end
  else
  begin

    //      Com_Printf ("100%%\n");

    FileClose(cls.download);

    // rename the temp file to it's final name
    CL_DownloadFileName(oldn, sizeof(oldn), cls.downloadtempname);
    CL_DownloadFileName(newn, sizeof(newn), cls.downloadname);
    r := renamefile(oldn, newn);
    if (not r) then
      Com_Printf('failed to rename.'#10);

    cls.download := 0;
    cls.downloadpercent := 0;

    // get another file if needed

    CL_RequestNextDownload();
  end;
end;

{*
=====================================================================

  SERVER CONNECTING MESSAGES

=====================================================================
*}

{*
==================
CL_ParseServerData
==================
*}
procedure CL_ParseServerData();
var
  str: PChar;
  i: Integer;
begin
  Com_DPrintf('Serverdata packet received.'#10);
  //
  // wipe the client_state_t struct
  //
  CL_ClearState();
  cls.state := ca_connected;

  // parse protocol version number
  i := MSG_ReadLong(net_message);
  cls.serverProtocol := i;

  // BIG HACK to let demos from release work with the 3.0x patch!!!
  if (Com_ServerState() <> 0) and (PROTOCOL_VERSION = 34) then
  begin
  end
  else if (i <> PROTOCOL_VERSION) then
    Com_Error(ERR_DROP, 'Server returned version %i, not %i', [i, PROTOCOL_VERSION]);

  cl.servercount := MSG_ReadLong(net_message);
  cl.attractloop := MSG_ReadByte(net_message) <> 0;

  // game directory
  str := MSG_ReadString(net_message);
  strncpy(cl.gamedir, str, sizeof(cl.gamedir) - 1);

  // set gamedir
  if ((str^ <> #0) and ((fs_gamedirvar^.string_ = nil) or (fs_gamedirvar^.string_^ = #0) or (strcmp(fs_gamedirvar^.string_, str) <> 0)) or
    ((str^ = #0) and ((fs_gamedirvar^.string_ <> nil) or (fs_gamedirvar^.string_^ <> #0)))) then
    Cvar_Set('game', str);

  // parse player entity number
  cl.playernum := MSG_ReadShort(net_message);

  // get the full level name
  str := MSG_ReadString(net_message);

  if (cl.playernum = -1) then
  begin
    // playing a cinematic or showing a pic, not a level
    SCR_PlayCinematic(str);
  end
  else
  begin
    // seperate the printfs so the server message can have a color
    Com_Printf(#10#10#29#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#30#31#10#10);
    Com_Printf('%s%s'#10, [#2, str]);

    // need to prep refresh at next oportunity
    cl.refresh_prepped := false;
  end;
end;

{*
==================
CL_ParseBaseline
==================
*}
procedure CL_ParseBaseline();
var
  es: entity_state_p;
  bits: Integer;
  newnum: Integer;
  nilstate: entity_state_t;
begin
  FillChar(nilstate, sizeof(nilstate), 0);

  newnum := CL_ParseEntityBits(@bits);
  es := @cl_entities[newnum].baseline;
  CL_ParseDelta(@nilstate, es, newnum, bits);
end;

{*
================
CL_LoadClientinfo

================
*}
procedure CL_LoadClientinfo(ci: clientinfo_p; s: pchar);
var
  i: Integer;
  t: PChar;
  model_name: array[0..MAX_QPATH - 1] of char;
  skin_name: array[0..MAX_QPATH - 1] of char;
  model_filename: array[0..MAX_QPATH - 1] of char;
  skin_filename: array[0..MAX_QPATH - 1] of char;
  weapon_filename: array[0..MAX_QPATH - 1] of char;
begin
  strncpy(ci^.cinfo, s, sizeof(ci^.cinfo));
  ci^.cinfo[sizeof(ci^.cinfo) - 1] := #0;

  // isolate the player's name
  strncpy(ci^.name, s, sizeof(ci^.name));
  ci^.name[sizeof(ci^.name) - 1] := #0;
  t := strstr(s, '\');
  if (t <> nil) then
  begin
    ci^.name[t - s] := #0;
    s := t + 1;
  end;

  if (cl_noskins^.value <> 0) or (s^ = #0) then
  begin
    Com_sprintf(model_filename, sizeof(model_filename), 'players/male/tris.md2', []);
    Com_sprintf(weapon_filename, sizeof(weapon_filename), 'players/male/weapon.md2', []);
    Com_sprintf(skin_filename, sizeof(skin_filename), 'players/male/grunt.pcx', []);
    Com_sprintf(ci^.iconname, sizeof(ci^.iconname), '/players/male/grunt_i.pcx', []);
    ci^.model := re.RegisterModel(model_filename);
    FillChar(ci^.weaponmodel, sizeof(ci^.weaponmodel), 0);
    ci^.weaponmodel[0] := re.RegisterModel(weapon_filename);
    ci^.skin := re.RegisterSkin(skin_filename);
    ci^.icon := re.RegisterPic(ci^.iconname);
  end
  else
  begin
    // isolate the model name
    strcpy(model_name, s);
    t := strstr(model_name, '/');
    if (t = nil) then
      t := strstr(model_name, '\');
    if (t = nil) then
      t := model_name;
    t^ := #0;

    // isolate the skin name
    strcpy(skin_name, s + strlen(model_name) + 1);

    // model file
    Com_sprintf(model_filename, sizeof(model_filename), 'players/%s/tris.md2', [model_name]);
    ci^.model := re.RegisterModel(model_filename);
    if (ci^.model = nil) then
    begin
      strcpy(model_name, 'male');
      Com_sprintf(model_filename, sizeof(model_filename), 'players/male/tris.md2', []);
      ci^.model := re.RegisterModel(model_filename);
    end;

    // skin file
    Com_sprintf(skin_filename, sizeof(skin_filename), 'players/%s/%s.pcx', [model_name, skin_name]);
    ci^.skin := re.RegisterSkin(skin_filename);

    // if we don't have the skin and the model wasn't male,
    // see if the male has it (this is for CTF's skins)
    if (ci^.skin = nil) and (Q_stricmp(model_name, 'male') <> 0) then
    begin
      // change model to male
      strcpy(model_name, 'male');
      Com_sprintf(model_filename, sizeof(model_filename), 'players/male/tris.md2', []);
      ci^.model := re.RegisterModel(model_filename);

      // see if the skin exists for the male model
      Com_sprintf(skin_filename, sizeof(skin_filename), 'players/%s/%s.pcx', [model_name, skin_name]);
      ci^.skin := re.RegisterSkin(skin_filename);
    end;

    // if we still don't have a skin, it means that the male model didn't have
    // it, so default to grunt
    if (ci^.skin = nil) then
    begin
      // see if the skin exists for the male model
      Com_sprintf(skin_filename, sizeof(skin_filename), 'players/%s/grunt.pcx', [model_name, skin_name]);
      ci^.skin := re.RegisterSkin(skin_filename);
    end;

    // weapon file
    for i := 0 to num_cl_weaponmodels - 1 do
    begin
      Com_sprintf(weapon_filename, sizeof(weapon_filename), 'players/%s/%s', [model_name, cl_weaponmodels[i]]);
      ci^.weaponmodel[i] := re.RegisterModel(weapon_filename);
      if (ci^.weaponmodel[i] = nil) and (strcmp(model_name, 'cyborg') = 0) then
      begin
        // try male
        Com_sprintf(weapon_filename, sizeof(weapon_filename), 'players/male/%s', [cl_weaponmodels[i]]);
        ci^.weaponmodel[i] := re.RegisterModel(weapon_filename);
      end;
      if (cl_vwep^.value = 0) then
        break;                          // only one when vwep is off
    end;

    // icon file
    Com_sprintf(ci^.iconname, sizeof(ci^.iconname), '/players/%s/%s_i.pcx', [model_name, skin_name]);
    ci^.icon := re.RegisterPic(ci^.iconname);
  end;

  // must have loaded all data types to be valud
  if (ci^.skin = nil) or (ci^.icon = nil) or (ci^.model = nil) or (ci^.weaponmodel[0] = nil) then
  begin
    ci^.skin := nil;
    ci^.icon := nil;
    ci^.model := nil;
    ci^.weaponmodel[0] := nil;
  end;
end;

{*
================
CL_ParseClientinfo

Load the skin, icon, and model for a client
================
*}
procedure CL_ParseClientinfo(player: Integer);
var
  s: pchar;
  ci: clientinfo_p;
begin
  s := cl.configstrings[player + CS_PLAYERSKINS];

  ci := @cl.clientinfo[player];

  CL_LoadClientinfo(ci, s);
end;

{*
================
CL_ParseConfigString
================
*}
procedure CL_ParseConfigString();
var
  i: Integer;
  s: PChar;
  olds: array[0..MAX_QPATH - 1] of char;
begin
  i := MSG_ReadShort(net_message);
  if (i < 0) or (i >= MAX_CONFIGSTRINGS) then
    Com_Error(ERR_DROP, 'configstring > MAX_CONFIGSTRINGS');
  s := MSG_ReadString(net_message);

  strncpy(olds, cl.configstrings[i], sizeof(olds));
  olds[sizeof(olds) - 1] := #0;

  strcpy(cl.configstrings[i], s);

  // do something apropriate

  if (i >= CS_LIGHTS) and (i < CS_LIGHTS + MAX_LIGHTSTYLES) then
    CL_SetLightstyle(i - CS_LIGHTS)
  else if (i = CS_CDTRACK) then
  begin
    if (cl.refresh_prepped) then
      CDAudio_Play(StrToInt(cl.configstrings[CS_CDTRACK]), true);
  end
  else if (i >= CS_MODELS) and (i < CS_MODELS + MAX_MODELS) then
  begin
    if (cl.refresh_prepped) then
    begin
      cl.model_draw[i - CS_MODELS] := re.RegisterModel(cl.configstrings[i]);
      if (cl.configstrings[i][0] = '*') then
        cl.model_clip[i - CS_MODELS] := CM_InlineModel(cl.configstrings[i])
      else
        cl.model_clip[i - CS_MODELS] := nil;
    end;
  end
  else if (i >= CS_SOUNDS) and (i < CS_SOUNDS + MAX_MODELS) then
  begin
    if (cl.refresh_prepped) then
      cl.sound_precache[i - CS_SOUNDS] := S_RegisterSound(cl.configstrings[i]);
  end
  else if (i >= CS_IMAGES) and (i < CS_IMAGES + MAX_MODELS) then
  begin
    if (cl.refresh_prepped) then
      cl.image_precache[i - CS_IMAGES] := re.RegisterPic(cl.configstrings[i]);
  end
  else if (i >= CS_PLAYERSKINS) and (i < CS_PLAYERSKINS + MAX_CLIENTS) then
  begin
    if (cl.refresh_prepped) and (strcmp(olds, s) <> 0) then
      CL_ParseClientinfo(i - CS_PLAYERSKINS);
  end;
end;

{*
=====================================================================

ACTION MESSAGES

=====================================================================
*}

{*
==================
CL_ParseStartSoundPacket
==================
*}
procedure CL_ParseStartSoundPacket();
var
  pos_v: vec3_t;
  pos: PSingle;
  channel, ent: Integer;
  sound_num: Integer;
  volume: Single;
  attenuation: Single;
  flags: Integer;
  ofs: Single;
begin
  flags := MSG_ReadByte(net_message);
  sound_num := MSG_ReadByte(net_message);

  if (flags and SND_VOLUME <> 0) then
    volume := MSG_ReadByte(net_message) / 255.0
  else
    volume := DEFAULT_SOUND_PACKET_VOLUME;

  if (flags and SND_ATTENUATION <> 0) then
    attenuation := MSG_ReadByte(net_message) / 64.0
  else
    attenuation := DEFAULT_SOUND_PACKET_ATTENUATION;

  if (flags and SND_OFFSET <> 0) then
    ofs := MSG_ReadByte(net_message) / 1000.0
  else
    ofs := 0;

  if (flags and SND_ENT <> 0) then
  begin
    // entity reletive
    channel := MSG_ReadShort(net_message);
    ent := channel shr 3;
    if (ent > MAX_EDICTS) then
      Com_Error(ERR_DROP, 'CL_ParseStartSoundPacket: ent = %i', [ent]);

    channel := channel and 7;
  end
  else
  begin
    ent := 0;
    channel := 0;
  end;

  if (flags and SND_POS <> 0) then
  begin
    // positioned in space
    MSG_ReadPos(net_message, pos_v);

    pos := @pos_v;
  end
  else                                  // use entity number
    pos := nil;

  if (cl.sound_precache[sound_num] = nil) then
    exit;

  S_StartSound(vec3_p(pos), ent, channel, cl.sound_precache[sound_num], volume, attenuation, ofs);
end;

procedure SHOWNET(s: pchar);
begin
  if (cl_shownet^.value >= 2) then
    Com_Printf('%3d:%s'#10, [net_message.readcount - 1, s]);
end;

{*
=====================
CL_ParseServerMessage
=====================
*}
procedure CL_ParseServerMessage();
var
  cmd: Integer;
  s: PChar;
  i: Integer;
begin
  //
  // if recording demos, copy the message out
  //
  if (cl_shownet^.value = 1) then
    Com_Printf('%i ', [net_message.cursize])
  else if (cl_shownet^.value >= 2) then
    Com_Printf('------------------'#10);

  //
  // parse the message
  //
  while (true) do
  begin
    if (net_message.readcount > net_message.cursize) then
    begin
      Com_Error(ERR_DROP, 'CL_ParseServerMessage: Bad server message');
      break;
    end;

    cmd := MSG_ReadByte(net_message);

    if (cmd = -1) then
    begin
      SHOWNET('END OF MESSAGE');
      break;
    end;

    if (cl_shownet^.value >= 2) then
    begin
      if (svc_strings[cmd] = nil) then
        Com_Printf('%3d:BAD CMD %d'#10, [net_message.readcount - 1, cmd])
      else
        SHOWNET(svc_strings[cmd]);
    end;

    // other commands
    case svc_ops_e(cmd) of

      svc_nop:
        //         Com_Printf ("svc_nop\n");
        ;
      svc_disconnect:
        Com_Error(ERR_DISCONNECT, 'Server disconnected'#10);

      svc_reconnect:
        begin
          Com_Printf('Server disconnected, reconnecting'#10);
          if (cls.download > 0) then
          begin
            //ZOID, close download
            FileClose(cls.download);
            cls.download := 0;
          end;
          cls.state := ca_connecting;
          cls.connect_time := -99999;   // CL_CheckForResend() will fire immediately
        end;

      svc_print:
        begin
          i := MSG_ReadByte(net_message);
          if (i = PRINT_CHAT) then
          begin
            S_StartLocalSound('misc/talk.wav');
            con.ormask := 128;
          end;
          Com_Printf('%s', [MSG_ReadString(net_message)]);
          con.ormask := 0;
        end;

      svc_centerprint:
        SCR_CenterPrint(MSG_ReadString(net_message));

      svc_stufftext:
        begin
          s := MSG_ReadString(net_message);
          Com_DPrintf('stufftext: %s'#10, [s]);
          Cbuf_AddText(s);
        end;

      svc_serverdata:
        begin
          Cbuf_Execute();               // make sure any stuffed commands are done
          CL_ParseServerData();
        end;

      svc_configstring:
        CL_ParseConfigString();

      svc_sound:
        CL_ParseStartSoundPacket();

      svc_spawnbaseline:
        CL_ParseBaseline();

      svc_temp_entity:
        CL_ParseTEnt();

      svc_muzzleflash:
        CL_ParseMuzzleFlash();

      svc_muzzleflash2:
        CL_ParseMuzzleFlash2();

      svc_download:
        CL_ParseDownload();

      svc_frame:
        CL_ParseFrame();

      svc_inventory:
        CL_ParseInventory();

      svc_layout:
        begin
          s := MSG_ReadString(net_message);
          strncpy(cl.layout, s, sizeof(cl.layout) - 1);
        end;
      svc_playerinfo,
        svc_packetentities,
        svc_deltapacketentities:
        Com_Error(ERR_DROP, 'Out of place frame data');
    else
      begin
        Com_Error(ERR_DROP, 'CL_ParseServerMessage: Illegible server message'#10);
      end;
    end;
  end;

  CL_AddNetgraph();

  //
  // we don't know if it is ok to save a demo message until
  // after we have parsed the frame
  //
  if (cls.demorecording) and (not cls.demowaiting) then
    CL_WriteDemoMessage();

end;

end.
