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

unit block8;
{----------------------------------------------------------------------------}
{                                                                            }
{ File(s): block8.inc                                                        }
{                                                                            }
{ Initial conversion by : CodeFusion (Michael@Skovslund.dk)                  }
{ Initial conversion on : 22-July-2002                                       }
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
{ None.                                                                      }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{ 1) This file is not used anywhere so I have just added a procedure that    }
{    holds the asm code.                                                     }
{----------------------------------------------------------------------------}

interface

procedure Block8Proc;

implementation

procedure Block8Proc;
asm
LEnter16_16:
 mov al,ds:byte ptr[esi]
 mov cl,ds:byte ptr[esi+ebx]
 mov ah,dh
 add edx,ebp
 mov ch,dh
 lea esi,ds:dword ptr[esi+ebx*2]
 mov ax,ds:word ptr[12345678h+eax*2]
LBPatch0:
 add edx,ebp
 mov ds:word ptr[edi],ax
 mov cx,ds:word ptr[12345678h+ecx*2]
LBPatch1:
 mov ds:word ptr[2+edi],cx
 add edi,04h
 mov al,ds:byte ptr[esi]
 mov cl,ds:byte ptr[esi+ebx]
 mov ah,dh
 add edx,ebp
 mov ch,dh
 lea esi,ds:dword ptr[esi+ebx*2]
 mov ax,ds:word ptr[12345678h+eax*2]
LBPatch2:
 add edx,ebp
 mov ds:word ptr[edi],ax
 mov cx,ds:word ptr[12345678h+ecx*2]
LBPatch3:
 mov ds:word ptr[2+edi],cx
 add edi,04h
 mov al,ds:byte ptr[esi]
 mov cl,ds:byte ptr[esi+ebx]
 mov ah,dh
 add edx,ebp
 mov ch,dh
 lea esi,ds:dword ptr[esi+ebx*2]
 mov ax,ds:word ptr[12345678h+eax*2]
LBPatch4:
 add edx,ebp
 mov ds:word ptr[edi],ax
 mov cx,ds:word ptr[12345678h+ecx*2]
LBPatch5:
 mov ds:word ptr[2+edi],cx
 add edi,04h
 mov al,ds:byte ptr[esi]
 mov cl,ds:byte ptr[esi+ebx]
 mov ah,dh
 add edx,ebp
 mov ch,dh
 lea esi,ds:dword ptr[esi+ebx*2]
 mov ax,ds:word ptr[12345678h+eax*2]
LBPatch6:
 add edx,ebp
 mov ds:word ptr[edi],ax
 mov cx,ds:word ptr[12345678h+ecx*2]
LBPatch7:
 mov ds:word ptr[2+edi],cx
 add edi,04h
LEnter8_16:
 mov al,ds:byte ptr[esi]
 mov cl,ds:byte ptr[esi+ebx]
 mov ah,dh
 add edx,ebp
 mov ch,dh
 lea esi,ds:dword ptr[esi+ebx*2]
 mov ax,ds:word ptr[12345678h+eax*2]
LBPatch8:
 add edx,ebp
 mov ds:word ptr[edi],ax
 mov cx,ds:word ptr[12345678h+ecx*2]
LBPatch9:
 mov ds:word ptr[2+edi],cx
 add edi,04h
 mov al,ds:byte ptr[esi]
 mov cl,ds:byte ptr[esi+ebx]
 mov ah,dh
 add edx,ebp
 mov ch,dh
 lea esi,ds:dword ptr[esi+ebx*2]
 mov ax,ds:word ptr[12345678h+eax*2]
LBPatch10:
 add edx,ebp
 mov ds:word ptr[edi],ax
 mov cx,ds:word ptr[12345678h+ecx*2]
LBPatch11:
 mov ds:word ptr[2+edi],cx
 add edi,04h
LEnter4_16:
 mov al,ds:byte ptr[esi]
 mov cl,ds:byte ptr[esi+ebx]
 mov ah,dh
 add edx,ebp
 mov ch,dh
 lea esi,ds:dword ptr[esi+ebx*2]
 mov ax,ds:word ptr[12345678h+eax*2]
LBPatch12:
 add edx,ebp
 mov ds:word ptr[edi],ax
 mov cx,ds:word ptr[12345678h+ecx*2]
LBPatch13:
 mov ds:word ptr[2+edi],cx
 add edi,04h
LEnter2_16:
 mov al,ds:byte ptr[esi]
 mov cl,ds:byte ptr[esi+ebx]
 mov ah,dh
 add edx,ebp
 mov ch,dh
 lea esi,ds:dword ptr[esi+ebx*2]
 mov ax,ds:word ptr[12345678h+eax*2]
LBPatch14:
 add edx,ebp
 mov ds:word ptr[edi],ax
 mov cx,ds:word ptr[12345678h+ecx*2]
LBPatch15:
 mov ds:word ptr[2+edi],cx
 add edi,04h
end;

end.
