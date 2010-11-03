{$DEFINE CTF}
//20%
{$ALIGN ON}{$MINENUMSIZE 4}
{----------------------------------------------------------------------------}
{                                                                            }
{ File(s): ctf\ctf.dsp                                                       }
{          ctf\ctf.def                                                       }
{ Content: project to build gamex86.dll for Capture The Flag Quake 2         }
{                                                                            }
{ Initial conversion by: Carl A Kenner (carlkenner@hotmail.com)              }
{ Initial conversion on: 3-Mar-2002                                          }
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
{ Updated on: 3-Mar-2002                                                     }
{ Updated by: Carl A Kenner                                                  }
{                                                                            }
{----------------------------------------------------------------------------}
{ * Still dependent (to compile correctly) on:                               }
{ lots of files                                                              }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{ remaining files                                                            }
{----------------------------------------------------------------------------}
library gamex86;

{ Important note about DLL memory management: ShareMem must be the
  first unit in your library's USES clause AND your project's (select
  Project-View Source) USES clause if your DLL exports any procedures or
  functions that pass strings as parameters or function results. This
  applies to all strings passed to and from your DLL--even those that
  are nested in records and classes. ShareMem is the interface unit to
  the BORLNDMM.DLL shared memory manager, which must be deployed along
  with your DLL. To avoid using BORLNDMM.DLL, pass string information
  using PChar or ShortString parameters. }

uses
  SysUtils,
  Classes,
  g_local in 'g_local.pas',
  q_shared in 'q_shared.pas',
  GameUnit in 'GameUnit.pas',
  g_svcmds in 'g_svcmds.pas',
  g_utils in 'g_utils.pas',
  g_main in 'g_main.pas',
  g_misc in 'g_misc.pas',
  g_save in 'g_save.pas',
  m_player in 'm_player.pas',
  p_menu in 'p_menu.pas',
  CVar in '..\qcommon\CVar.pas',
  cmd in '..\qcommon\cmd.pas',
  Common in '..\qcommon\Common.pas',
  Files in '..\qcommon\Files.pas',
  QFiles in '..\qcommon\qfiles.pas',
  crc in '..\qcommon\crc.pas',
  net_chan in '..\qcommon\net_chan.pas',
  q_shwin in '..\win32\q_shwin.pas',
  net_wins in '..\win32\net_wins.pas',
  JwaWinSock in '..\win32\JwaWinSock.pas',
  JwaWinType in '..\win32\JwaWinType.pas',
  JwaWinBase in '..\win32\JwaWinBase.pas',
  JwaWinNT in '..\win32\JwaWinNT.pas',
  JwaNtStatus in '..\win32\JwaNtStatus.pas',
  JwaWSipx in '..\win32\JwaWSipx.pas';

{$R *.res}

exports
  GetGameAPI name 'GetGameAPI';

begin
end.
