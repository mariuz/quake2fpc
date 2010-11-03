{----------------------------------------------------------------------------}
{                                                                            }
{ File(s): QCommon.h (part)                                                  }
{ Content: Quake2\QCommon\ stub instead of QCommon.inc include file          }
{                                                                            }
{ Initial conversion by : Clootie (Alexey Barkovoy) - clootie@reactor.ru     }
{ Initial conversion on : 27-Jan-2002                                        }
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
{ * Notes:                                                                   }
{ This INC files should be included instead of original QCommon.h include    }
{ file in files what are external to QCommon directory (with some exceptions)}
{----------------------------------------------------------------------------}
{ * Usage example:                                                           }
{ uses SysUtils, (*$Include QCommon.inc*);                                   }
{----------------------------------------------------------------------------}
{ * Updated:                                                                 }
{ 1) 25-Jan-2002 - Clootie (clootie@reactor.ru)                              }
{    Updated, included PMoveUnit.pas.                                        }
{ 2) 03-Mar-2002 - Clootie (clootie@reactor.ru)                              }
{    Updated, included CModel.pas.                                           }
{----------------------------------------------------------------------------}

Cmd, CModel, Common, CRC, CVar, Files, md4, net_chan, PMoveUnit, QFiles
{$IFDEF WIN32}
, net_wins{, sys_win} //Clootie: sys_win still uncompilable
{$ENDIF}
{$IFDEF LINUX}
, net_udp, sys_linux
{$ENDIF}

