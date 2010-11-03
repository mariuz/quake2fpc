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

unit r_scana;
{----------------------------------------------------------------------------}
{                                                                            }
{ File(s): r_scana.asm                                                       }
{                                                                            }
{ Initial conversion by : CodeFusion (michael@skovslund.dk)                  }
{ Initial conversion on : 16-July-2002                                       }
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
{  These variables has been moved from r_scan.pas to this one because        }
{  otherwise we would have had circular references.                          }
{                                                                            }
{  As r_scan.pas has not been created yet, the one who creates it MUST remove}
{  the variables below from the declaration part as it is implemented here.  }
{                                                                            }
{  r_turb_pbase      : PByte;                                                }
{  r_turb_pdest      : PByte;                                                }
{  r_turb_s          : fixed16_t;                                            }
{  r_turb_t          : fixed16_t;                                            }
{  r_turb_sstep      : fixed16_t;                                            }
{  r_turb_tstep      : fixed16_t;                                            }
{  r_turb_turb       : PInteger;                                             }
{  r_turb_spancount  : Integer;                                              }
{                                                                            }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{----------------------------------------------------------------------------}

interface

uses
  qasm_inc,
  d_if_inc;

type
  fixed16_t = Integer;

var
  r_turb_pbase: PByte;
  r_turb_pdest: PByte;

  r_turb_s: fixed16_t;
  r_turb_t: fixed16_t;
  r_turb_sstep: fixed16_t;
  r_turb_tstep: fixed16_t;

  r_turb_turb: PInteger;
  r_turb_spancount: Integer;

{$IFDEF   id386}
procedure D_DrawTurbulent8Span;
{$ENDIF}

implementation

{$IFDEF   id386}

{$ALIGN 4}

procedure D_DrawTurbulent8Span;
asm
  push    ebp   // preserve caller's stack frame pointer
  push    esi   // preserve register variables
  push    edi
  push    ebx

  mov     esi,ds:dword ptr[r_turb_s]
  mov     ecx,ds:dword ptr[r_turb_t]
  mov     edi,ds:dword ptr[r_turb_pdest]
  mov     ebx,ds:dword ptr[r_turb_spancount]

@Llp:
  mov     eax,ecx
  mov     edx,esi
  sar     eax,16
  mov     ebp,ds:dword ptr[r_turb_turb]
  sar     edx,16
  and     eax,offset CYCLE-1
  and     edx,offset CYCLE-1
  mov     eax,ds:dword ptr[ebp+eax*4]
  mov     edx,ds:dword ptr[ebp+edx*4]
  add     eax,esi
  sar     eax,16
  add     edx,ecx
  sar     edx,16
  and     eax,offset TURB_TEX_SIZE-1
  and     edx,offset TURB_TEX_SIZE-1
  shl     edx,6
  mov     ebp,ds:dword ptr[r_turb_pbase]
  add     edx,eax
  inc     edi
  add     esi,ds:dword ptr[r_turb_sstep]
  add     ecx,ds:dword ptr[r_turb_tstep]
  mov     dl,ds:byte ptr[ebp+edx*1]
  dec     ebx
  mov     ds:byte ptr[-1+edi],dl
  jnz     @Llp

  mov     ds:dword ptr[r_turb_pdest],edi

  pop     ebx   // restore register variables
  pop     edi
  pop     esi
  pop     ebp   // restore caller's stack frame pointer
end;
{$ENDIF}

end.
