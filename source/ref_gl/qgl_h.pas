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
{ File(s): qgl_h.pas                                                         }
{                                                                            }
{ Initial conversion by : Lars Middendorf (lmid@gmx.de)                      }
{ Initial conversion on : 07-Jan-2002                                        }
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

unit qgl_h;

interface

uses
  {$ifdef WIN32}
  windows,
  {$endif}
  sysutils,
  OpenGL,
  q_shared;


(*
type
  pcolorref=^colorref;

var
  QGL_Init:function(const dllname:pchar):qboolean;
  QGL_Shutdown:procedure;

  qglaccum:procedure(op:TGLenum;value:TGLfloat);stdcall;
  qglalphafunc:procedure(func:TGLenum;ref:TGLclampf);stdcall;
  qglaretexturesresident:function(n:TGLsizei;textures:PGLuint;residences:PGLboolean):TGLboolean;stdcall;
  qglarrayelement:procedure(i:TGLint);stdcall;
  qglbegin:procedure(mode:TGLenum);stdcall;
  qglbindtexture:procedure(target:TGLenum;texture:TGLuint);stdcall;
  qglbitmap:procedure(width:TGLsizei;height:TGLsizei;xorig:TGLfloat;yorig:TGLfloat;xmove:TGLfloat;ymove:TGLfloat;bitmap:PGLubyte);stdcall;
  qglblendfunc:procedure(sfactor:TGLenum;dfactor:TGLenum);stdcall;
  qglcalllist:procedure(list:TGLuint);stdcall;
  qglcalllists:procedure(n:TGLsizei;_type:TGLenum;const lists:pointer);stdcall;
  qglclear:procedure(mask:TGLbitfield);stdcall;
  qglclearaccum:procedure(red:TGLfloat;green:TGLfloat;blue:TGLfloat;alpha:TGLfloat);stdcall;
  qglclearcolor:procedure(red:TGLclampf;green:TGLclampf;blue:TGLclampf;alpha:TGLclampf);stdcall;
  qglcleardepth:procedure(depth:TGLclampd);stdcall;
  qglclearindex:procedure(c:TGLfloat);stdcall;
  qglclearstencil:procedure(s:TGLint);stdcall;
  qglclipplane:procedure(plane:TGLenum;equation:PGLdouble);stdcall;
  qglcolor3b:procedure(red:TGLbyte;green:TGLbyte;blue:TGLbyte);stdcall;
  qglcolor3bv:procedure(v:PGLbyte);stdcall;
  qglcolor3d:procedure(red:TGLdouble;green:TGLdouble;blue:TGLdouble);stdcall;
  qglcolor3dv:procedure(v:PGLdouble);stdcall;
  qglcolor3f:procedure(red:TGLfloat;green:TGLfloat;blue:TGLfloat);stdcall;
  qglcolor3fv:procedure(v:PGLfloat);stdcall;
  qglcolor3i:procedure(red:TGLint;green:TGLint;blue:TGLint);stdcall;
  qglcolor3iv:procedure(v:PGLint);stdcall;
  qglcolor3s:procedure(red:TGLshort;green:TGLshort;blue:TGLshort);stdcall;
  qglcolor3sv:procedure(v:PGLshort);stdcall;
  qglcolor3ub:procedure(red:TGLubyte;green:TGLubyte;blue:TGLubyte);stdcall;
  qglcolor3ubv:procedure(v:PGLubyte);stdcall;
  qglcolor3ui:procedure(red:TGLuint;green:TGLuint;blue:TGLuint);stdcall;
  qglcolor3uiv:procedure(v:PGLuint);stdcall;
  qglcolor3us:procedure(red:TGLushort;green:TGLushort;blue:TGLushort);stdcall;
  qglcolor3usv:procedure(v:PGLushort);stdcall;
  qglcolor4b:procedure(red:TGLbyte;green:TGLbyte;blue:TGLbyte;alpha:TGLbyte);stdcall;
  qglcolor4bv:procedure(v:PGLbyte);stdcall;
  qglcolor4d:procedure(red:TGLdouble;green:TGLdouble;blue:TGLdouble;alpha:TGLdouble);stdcall;
  qglcolor4dv:procedure(v:PGLdouble);stdcall;
  qglcolor4f:procedure(red:TGLfloat;green:TGLfloat;blue:TGLfloat;alpha:TGLfloat);stdcall;
  qglcolor4fv:procedure(v:PGLfloat);stdcall;
  qglcolor4i:procedure(red:TGLint;green:TGLint;blue:TGLint;alpha:TGLint);stdcall;
  qglcolor4iv:procedure(v:PGLint);stdcall;
  qglcolor4s:procedure(red:TGLshort;green:TGLshort;blue:TGLshort;alpha:TGLshort);stdcall;
  qglcolor4sv:procedure(v:PGLshort);stdcall;
  qglcolor4ub:procedure(red:TGLubyte;green:TGLubyte;blue:TGLubyte;alpha:TGLubyte);stdcall;
  qglcolor4ubv:procedure(v:PGLubyte);stdcall;
  qglcolor4ui:procedure(red:TGLuint;green:TGLuint;blue:TGLuint;alpha:TGLuint);stdcall;
  qglcolor4uiv:procedure(v:PGLuint);stdcall;
  qglcolor4us:procedure(red:TGLushort;green:TGLushort;blue:TGLushort;alpha:TGLushort);stdcall;
  qglcolor4usv:procedure(v:PGLushort);stdcall;
  qglcolormask:procedure(red:TGLboolean;green:TGLboolean;blue:TGLboolean;alpha:TGLboolean);stdcall;
  qglcolormaterial:procedure(face:TGLenum;mode:TGLenum);stdcall;
  qglcolorpointer:procedure(size:TGLint;_type:TGLenum;stride:TGLsizei;const p:pointer);stdcall;
  qglcopypixels:procedure(x:TGLint;y:TGLint;width:TGLsizei;height:TGLsizei;_type:TGLenum);stdcall;
  qglcopyteximage1d:procedure(target:TGLenum;level:TGLint;internalformat:TGLenum;x:TGLint;y:TGLint;width:TGLsizei;border:TGLint);stdcall;
  qglcopyteximage2d:procedure(target:TGLenum;level:TGLint;internalformat:TGLenum;x:TGLint;y:TGLint;width:TGLsizei;height:TGLsizei;border:TGLint);stdcall;
  qglcopytexsubimage1d:procedure(target:TGLenum;level:TGLint;xoffset:TGLint;x:TGLint;y:TGLint;width:TGLsizei);stdcall;
  qglcopytexsubimage2d:procedure(target:TGLenum;level:TGLint;xoffset:TGLint;yoffset:TGLint;x:TGLint;y:TGLint;width:TGLsizei;height:TGLsizei);stdcall;
  qglcullface:procedure(mode:TGLenum);stdcall;
  qgldeletelists:procedure(list:TGLuint;range:TGLsizei);stdcall;
  qgldeletetextures:procedure(n:TGLsizei;textures:PGLuint);stdcall;
  qgldepthfunc:procedure(func:TGLenum);stdcall;
  qgldepthmask:procedure(flag:TGLboolean);stdcall;
  qgldepthrange:procedure(znear:TGLclampd;zfar:TGLclampd);stdcall;
  qgldisable:procedure(cap:TGLenum);stdcall;
  qgldisableclientstate:procedure(_array:TGLenum);stdcall;
  qgldrawarrays:procedure(mode:TGLenum;first:TGLint;count:TGLsizei);stdcall;
  qgldrawbuffer:procedure(mode:TGLenum);stdcall;
  qgldrawelements:procedure(mode:TGLenum;count:TGLsizei;_type:TGLenum;const indices:pointer);stdcall;
  qgldrawpixels:procedure(width:TGLsizei;height:TGLsizei;format:TGLenum;_type:TGLenum;const pixels:pointer);stdcall;
  qgledgeflag:procedure(flag:TGLboolean);stdcall;
  qgledgeflagpointer:procedure(stride:TGLsizei;const p:pointer);stdcall;
  qgledgeflagv:procedure(flag:PGLboolean);stdcall;
  qglenable:procedure(cap:TGLenum);stdcall;
  qglenableclientstate:procedure(_array:TGLenum);stdcall;
  qglend:procedure;stdcall;
  qglendlist:procedure;stdcall;
  qglevalcoord1d:procedure(u:TGLdouble);stdcall;
  qglevalcoord1dv:procedure(u:PGLdouble);stdcall;
  qglevalcoord1f:procedure(u:TGLfloat);stdcall;
  qglevalcoord1fv:procedure(u:PGLfloat);stdcall;
  qglevalcoord2d:procedure(u:TGLdouble;v:TGLdouble);stdcall;
  qglevalcoord2dv:procedure(u:PGLdouble);stdcall;
  qglevalcoord2f:procedure(u:TGLfloat;v:TGLfloat);stdcall;
  qglevalcoord2fv:procedure(u:PGLfloat);stdcall;
  qglevalmesh1:procedure(mode:TGLenum;i1:TGLint;i2:TGLint);stdcall;
  qglevalmesh2:procedure(mode:TGLenum;i1:TGLint;i2:TGLint;j1:TGLint;j2:TGLint);stdcall;
  qglevalpoint1:procedure(i:TGLint);stdcall;
  qglevalpoint2:procedure(i:TGLint;j:TGLint);stdcall;
  qglfeedbackbuffer:procedure(size:TGLsizei;_type:TGLenum;buffer:PGLfloat);stdcall;
  qglfinish:procedure;stdcall;
  qglflush:procedure;stdcall;
  qglfogf:procedure(pname:TGLenum;param:TGLfloat);stdcall;
  qglfogfv:procedure(pname:TGLenum;params:PGLfloat);stdcall;
  qglfogi:procedure(pname:TGLenum;param:TGLint);stdcall;
  qglfogiv:procedure(pname:TGLenum;params:PGLint);stdcall;
  qglfrontface:procedure(mode:TGLenum);stdcall;
  qglfrustum:procedure(left:TGLdouble;right:TGLdouble;bottom:TGLdouble;top:TGLdouble;znear:TGLdouble;zfar:TGLdouble);stdcall;
  qglgenlists:function(range:TGLsizei):TGLuint;stdcall;
  qglgentextures:procedure(n:TGLsizei;textures:PGLuint);stdcall;
  qglgetbooleanv:procedure(pname:TGLenum;params:PGLboolean);stdcall;
  qglgetclipplane:procedure(plane:TGLenum;equation:PGLdouble);stdcall;
  qglgetdoublev:procedure(pname:TGLenum;params:PGLdouble);stdcall;
  qglgeterror:function :TGLenum;stdcall;
  qglgetfloatv:procedure(pname:TGLenum;params:PGLfloat);stdcall;
  qglgetintegerv:procedure(pname:TGLenum;params:PGLint);stdcall;
  qglgetlightfv:procedure(light:TGLenum;pname:TGLenum;params:PGLfloat);stdcall;
  qglgetlightiv:procedure(light:TGLenum;pname:TGLenum;params:PGLint);stdcall;
  qglgetmapdv:procedure(target:TGLenum;query:TGLenum;v:PGLdouble);stdcall;
  qglgetmapfv:procedure(target:TGLenum;query:TGLenum;v:PGLfloat);stdcall;
  qglgetmapiv:procedure(target:TGLenum;query:TGLenum;v:PGLint);stdcall;
  qglgetmaterialfv:procedure(face:TGLenum;pname:TGLenum;params:PGLfloat);stdcall;
  qglgetmaterialiv:procedure(face:TGLenum;pname:TGLenum;params:PGLint);stdcall;
  qglgetpixelmapfv:procedure(map:TGLenum;values:PGLfloat);stdcall;
  qglgetpixelmapuiv:procedure(map:TGLenum;values:PGLuint);stdcall;
  qglgetpixelmapusv:procedure(map:TGLenum;values:PGLushort);stdcall;
  qglgetpointerv:procedure(pname:TGLenum;params:pointer);stdcall;
  qglgetpolygonstipple:procedure(mask:PGLubyte);stdcall;
  qglgetstring:function(name:TGLenum):PGLubyte;stdcall;
  qglgettexenvfv:procedure(target:TGLenum;pname:TGLenum;params:PGLfloat);stdcall;
  qglgettexenviv:procedure(target:TGLenum;pname:TGLenum;params:PGLint);stdcall;
  qglgettexgendv:procedure(coord:TGLenum;pname:TGLenum;params:PGLdouble);stdcall;
  qglgettexgenfv:procedure(coord:TGLenum;pname:TGLenum;params:PGLfloat);stdcall;
  qglgettexgeniv:procedure(coord:TGLenum;pname:TGLenum;params:PGLint);stdcall;
  qglgetteximage:procedure(target:TGLenum;level:TGLint;format:TGLenum;_type:TGLenum;pixels:pointer);stdcall;
  qglgettexlevelparameterfv:procedure(target:TGLenum;level:TGLint;pname:TGLenum;params:PGLfloat);stdcall;
  qglgettexlevelparameteriv:procedure(target:TGLenum;level:TGLint;pname:TGLenum;params:PGLint);stdcall;
  qglgettexparameterfv:procedure(target:TGLenum;pname:TGLenum;params:PGLfloat);stdcall;
  qglgettexparameteriv:procedure(target:TGLenum;pname:TGLenum;params:PGLint);stdcall;
  qglhint:procedure(target:TGLenum;mode:TGLenum);stdcall;
  qglindexmask:procedure(mask:TGLuint);stdcall;
  qglindexpointer:procedure(_type:TGLenum;stride:TGLsizei;p:pointer);stdcall;
  qglindexd:procedure(c:TGLdouble);stdcall;
  qglindexdv:procedure(c:PGLdouble);stdcall;
  qglindexf:procedure(c:TGLfloat);stdcall;
  qglindexfv:procedure(c:PGLfloat);stdcall;
  qglindexi:procedure(c:TGLint);stdcall;
  qglindexiv:procedure(c:PGLint);stdcall;
  qglindexs:procedure(c:TGLshort);stdcall;
  qglindexsv:procedure(c:PGLshort);stdcall;
  qglindexub:procedure(c:TGLubyte);stdcall;
  qglindexubv:procedure(c:PGLubyte);stdcall;
  qglinitnames:procedure;stdcall;
  qglinterleavedarrays:procedure(format:TGLenum;stride:TGLsizei;p:pointer);stdcall;
  qglisenabled:function(cap:TGLenum):TGLboolean;stdcall;
  qglislist:function(list:TGLuint):TGLboolean;stdcall;
  qglistexture:function(texture:TGLuint):TGLboolean;stdcall;
  qgllightmodelf:procedure(pname:TGLenum;param:TGLfloat);stdcall;
  qgllightmodelfv:procedure(pname:TGLenum;params:PGLfloat);stdcall;
  qgllightmodeli:procedure(pname:TGLenum;param:TGLint);stdcall;
  qgllightmodeliv:procedure(pname:TGLenum;params:PGLint);stdcall;
  qgllightf:procedure(light:TGLenum;pname:TGLenum;param:TGLfloat);stdcall;
  qgllightfv:procedure(light:TGLenum;pname:TGLenum;params:PGLfloat);stdcall;
  qgllighti:procedure(light:TGLenum;pname:TGLenum;param:TGLint);stdcall;
  qgllightiv:procedure(light:TGLenum;pname:TGLenum;params:PGLint);stdcall;
  qgllinestipple:procedure(factor:TGLint;pattern:TGLushort);stdcall;
  qgllinewidth:procedure(width:TGLfloat);stdcall;
  qgllistbase:procedure(base:TGLuint);stdcall;
  qglloadidentity:procedure;stdcall;
  qglloadmatrixd:procedure(m:PGLdouble);stdcall;
  qglloadmatrixf:procedure(m:PGLfloat);stdcall;
  qglloadname:procedure(name:TGLuint);stdcall;
  qgllogicop:procedure(opcode:TGLenum);stdcall;
  qglmap1d:procedure(target:TGLenum;u1:TGLdouble;u2:TGLdouble;stride:TGLint;order:TGLint;points:PGLdouble);stdcall;
  qglmap1f:procedure(target:TGLenum;u1:TGLfloat;u2:TGLfloat;stride:TGLint;order:TGLint;points:PGLfloat);stdcall;
  qglmap2d:procedure(target:TGLenum;u1:TGLdouble;u2:TGLdouble;ustride:TGLint;uorder:TGLint;v1:TGLdouble;v2:TGLdouble;vstride:TGLint;vorder:TGLint;points:PGLdouble);stdcall;
  qglmap2f:procedure(target:TGLenum;u1:TGLfloat;u2:TGLfloat;ustride:TGLint;uorder:TGLint;v1:TGLfloat;v2:TGLfloat;vstride:TGLint;vorder:TGLint;points:PGLfloat);stdcall;
  qglmapgrid1d:procedure(un:TGLint;u1:TGLdouble;u2:TGLdouble);stdcall;
  qglmapgrid1f:procedure(un:TGLint;u1:TGLfloat;u2:TGLfloat);stdcall;
  qglmapgrid2d:procedure(un:TGLint;u1:TGLdouble;u2:TGLdouble;vn:TGLint;v1:TGLdouble;v2:TGLdouble);stdcall;
  qglmapgrid2f:procedure(un:TGLint;u1:TGLfloat;u2:TGLfloat;vn:TGLint;v1:TGLfloat;v2:TGLfloat);stdcall;
  qglmaterialf:procedure(face:TGLenum;pname:TGLenum;param:TGLfloat);stdcall;
  qglmaterialfv:procedure(face:TGLenum;pname:TGLenum;params:PGLfloat);stdcall;
  qglmateriali:procedure(face:TGLenum;pname:TGLenum;param:TGLint);stdcall;
  qglmaterialiv:procedure(face:TGLenum;pname:TGLenum;params:PGLint);stdcall;
  qglmatrixmode:procedure(mode:TGLenum);stdcall;
  qglmultmatrixd:procedure(m:PGLdouble);stdcall;
  qglmultmatrixf:procedure(m:PGLfloat);stdcall;
  qglnewlist:procedure(list:TGLuint;mode:TGLenum);stdcall;
  qglnormal3b:procedure(nx:TGLbyte;ny:TGLbyte;nz:TGLbyte);stdcall;
  qglnormal3bv:procedure(v:PGLbyte);stdcall;
  qglnormal3d:procedure(nx:TGLdouble;ny:TGLdouble;nz:TGLdouble);stdcall;
  qglnormal3dv:procedure(v:PGLdouble);stdcall;
  qglnormal3f:procedure(nx:TGLfloat;ny:TGLfloat;nz:TGLfloat);stdcall;
  qglnormal3fv:procedure(v:PGLfloat);stdcall;
  qglnormal3i:procedure(nx:TGLint;ny:TGLint;nz:TGLint);stdcall;
  qglnormal3iv:procedure(v:PGLint);stdcall;
  qglnormal3s:procedure(nx:TGLshort;ny:TGLshort;nz:TGLshort);stdcall;
  qglnormal3sv:procedure(v:PGLshort);stdcall;
  qglnormalpointer:procedure(_type:TGLenum;stride:TGLsizei;pointer:pointer);stdcall;
  qglortho:procedure(left:TGLdouble;right:TGLdouble;bottom:TGLdouble;top:TGLdouble;znear:TGLdouble;zfar:TGLdouble);stdcall;
  qglpassthrough:procedure(token:TGLfloat);stdcall;
  qglpixelmapfv:procedure(map:TGLenum;mapsize:TGLsizei;values:PGLfloat);stdcall;
  qglpixelmapuiv:procedure(map:TGLenum;mapsize:TGLsizei;values:PGLuint);stdcall;
  qglpixelmapusv:procedure(map:TGLenum;mapsize:TGLsizei;values:PGLushort);stdcall;
  qglpixelstoref:procedure(pname:TGLenum;param:TGLfloat);stdcall;
  qglpixelstorei:procedure(pname:TGLenum;param:TGLint);stdcall;
  qglpixeltransferf:procedure(pname:TGLenum;param:TGLfloat);stdcall;
  qglpixeltransferi:procedure(pname:TGLenum;param:TGLint);stdcall;
  qglpixelzoom:procedure(xfactor:TGLfloat;yfactor:TGLfloat);stdcall;
  qglpointsize:procedure(size:TGLfloat);stdcall;
  qglpolygonmode:procedure(face:TGLenum;mode:TGLenum);stdcall;
  qglpolygonoffset:procedure(factor:TGLfloat;units:TGLfloat);stdcall;
  qglpolygonstipple:procedure(mask:PGLubyte);stdcall;
  qglpopattrib:procedure;stdcall;
  qglpopclientattrib:procedure;stdcall;
  qglpopmatrix:procedure;stdcall;
  qglpopname:procedure;stdcall;
  qglprioritizetextures:procedure(n:TGLsizei;textures:PGLuint;priorities:PGLclampf);stdcall;
  qglpushattrib:procedure(mask:TGLbitfield);stdcall;
  qglpushclientattrib:procedure(mask:TGLbitfield);stdcall;
  qglpushmatrix:procedure;stdcall;
  qglpushname:procedure(name:TGLuint);stdcall;
  qglrasterpos2d:procedure(x:TGLdouble;y:TGLdouble);stdcall;
  qglrasterpos2dv:procedure(v:PGLdouble);stdcall;
  qglrasterpos2f:procedure(x:TGLfloat;y:TGLfloat);stdcall;
  qglrasterpos2fv:procedure(v:PGLfloat);stdcall;
  qglrasterpos2i:procedure(x:TGLint;y:TGLint);stdcall;
  qglrasterpos2iv:procedure(v:PGLint);stdcall;
  qglrasterpos2s:procedure(x:TGLshort;y:TGLshort);stdcall;
  qglrasterpos2sv:procedure(v:PGLshort);stdcall;
  qglrasterpos3d:procedure(x:TGLdouble;y:TGLdouble;z:TGLdouble);stdcall;
  qglrasterpos3dv:procedure(v:PGLdouble);stdcall;
  qglrasterpos3f:procedure(x:TGLfloat;y:TGLfloat;z:TGLfloat);stdcall;
  qglrasterpos3fv:procedure(v:PGLfloat);stdcall;
  qglrasterpos3i:procedure(x:TGLint;y:TGLint;z:TGLint);stdcall;
  qglrasterpos3iv:procedure(v:PGLint);stdcall;
  qglrasterpos3s:procedure(x:TGLshort;y:TGLshort;z:TGLshort);stdcall;
  qglrasterpos3sv:procedure(v:PGLshort);stdcall;
  qglrasterpos4d:procedure(x:TGLdouble;y:TGLdouble;z:TGLdouble;w:TGLdouble);stdcall;
  qglrasterpos4dv:procedure(v:PGLdouble);stdcall;
  qglrasterpos4f:procedure(x:TGLfloat;y:TGLfloat;z:TGLfloat;w:TGLfloat);stdcall;
  qglrasterpos4fv:procedure(v:PGLfloat);stdcall;
  qglrasterpos4i:procedure(x:TGLint;y:TGLint;z:TGLint;w:TGLint);stdcall;
  qglrasterpos4iv:procedure(v:PGLint);stdcall;
  qglrasterpos4s:procedure(x:TGLshort;y:TGLshort;z:TGLshort;w:TGLshort);stdcall;
  qglrasterpos4sv:procedure(v:PGLshort);stdcall;
  qglreadbuffer:procedure(mode:TGLenum);stdcall;
  qglreadpixels:procedure(x:TGLint;y:TGLint;width:TGLsizei;height:TGLsizei;format:TGLenum;_type:TGLenum;pixels:pointer);stdcall;
  qglrectd:procedure(x1:TGLdouble;y1:TGLdouble;x2:TGLdouble;y2:TGLdouble);stdcall;
  qglrectdv:procedure(v1:PGLdouble;v2:PGLdouble);stdcall;
  qglrectf:procedure(x1:TGLfloat;y1:TGLfloat;x2:TGLfloat;y2:TGLfloat);stdcall;
  qglrectfv:procedure(v1:PGLfloat;v2:PGLfloat);stdcall;
  qglrecti:procedure(x1:TGLint;y1:TGLint;x2:TGLint;y2:TGLint);stdcall;
  qglrectiv:procedure(v1:PGLint;v2:PGLint);stdcall;
  qglrects:procedure(x1:TGLshort;y1:TGLshort;x2:TGLshort;y2:TGLshort);stdcall;
  qglrectsv:procedure(v1:PGLshort;v2:PGLshort);stdcall;
  qglrendermode:function(mode:TGLenum):TGLint;stdcall;
  qglrotated:procedure(angle:TGLdouble;x:TGLdouble;y:TGLdouble;z:TGLdouble);stdcall;
  qglrotatef:procedure(angle:TGLfloat;x:TGLfloat;y:TGLfloat;z:TGLfloat);stdcall;
  qglscaled:procedure(x:TGLdouble;y:TGLdouble;z:TGLdouble);stdcall;
  qglscalef:procedure(x:TGLfloat;y:TGLfloat;z:TGLfloat);stdcall;
  qglscissor:procedure(x:TGLint;y:TGLint;width:TGLsizei;height:TGLsizei);stdcall;
  qglselectbuffer:procedure(size:TGLsizei;buffer:PGLuint);stdcall;
  qglshademodel:procedure(mode:TGLenum);stdcall;
  qglstencilfunc:procedure(func:TGLenum;ref:TGLint;mask:TGLuint);stdcall;
  qglstencilmask:procedure(mask:TGLuint);stdcall;
  qglstencilop:procedure(fail:TGLenum;zfail:TGLenum;zpass:TGLenum);stdcall;
  qgltexcoord1d:procedure(s:TGLdouble);stdcall;
  qgltexcoord1dv:procedure(v:PGLdouble);stdcall;
  qgltexcoord1f:procedure(s:TGLfloat);stdcall;
  qgltexcoord1fv:procedure(v:PGLfloat);stdcall;
  qgltexcoord1i:procedure(s:TGLint);stdcall;
  qgltexcoord1iv:procedure(v:PGLint);stdcall;
  qgltexcoord1s:procedure(s:TGLshort);stdcall;
  qgltexcoord1sv:procedure(v:PGLshort);stdcall;
  qgltexcoord2d:procedure(s:TGLdouble;t:TGLdouble);stdcall;
  qgltexcoord2dv:procedure(v:PGLdouble);stdcall;
  qgltexcoord2f:procedure(s:TGLfloat;t:TGLfloat);stdcall;
  qgltexcoord2fv:procedure(v:PGLfloat);stdcall;
  qgltexcoord2i:procedure(s:TGLint;t:TGLint);stdcall;
  qgltexcoord2iv:procedure(v:PGLint);stdcall;
  qgltexcoord2s:procedure(s:TGLshort;t:TGLshort);stdcall;
  qgltexcoord2sv:procedure(v:PGLshort);stdcall;
  qgltexcoord3d:procedure(s:TGLdouble;t:TGLdouble;r:TGLdouble);stdcall;
  qgltexcoord3dv:procedure(v:PGLdouble);stdcall;
  qgltexcoord3f:procedure(s:TGLfloat;t:TGLfloat;r:TGLfloat);stdcall;
  qgltexcoord3fv:procedure(v:PGLfloat);stdcall;
  qgltexcoord3i:procedure(s:TGLint;t:TGLint;r:TGLint);stdcall;
  qgltexcoord3iv:procedure(v:PGLint);stdcall;
  qgltexcoord3s:procedure(s:TGLshort;t:TGLshort;r:TGLshort);stdcall;
  qgltexcoord3sv:procedure(v:PGLshort);stdcall;
  qgltexcoord4d:procedure(s:TGLdouble;t:TGLdouble;r:TGLdouble;q:TGLdouble);stdcall;
  qgltexcoord4dv:procedure(v:PGLdouble);stdcall;
  qgltexcoord4f:procedure(s:TGLfloat;t:TGLfloat;r:TGLfloat;q:TGLfloat);stdcall;
  qgltexcoord4fv:procedure(v:PGLfloat);stdcall;
  qgltexcoord4i:procedure(s:TGLint;t:TGLint;r:TGLint;q:TGLint);stdcall;
  qgltexcoord4iv:procedure(v:PGLint);stdcall;
  qgltexcoord4s:procedure(s:TGLshort;t:TGLshort;r:TGLshort;q:TGLshort);stdcall;
  qgltexcoord4sv:procedure(v:PGLshort);stdcall;
  qgltexcoordpointer:procedure(size:TGLint;_type:TGLenum;stride:TGLsizei;p:pointer);stdcall;
  qgltexenvf:procedure(target:TGLenum;pname:TGLenum;param:TGLfloat);stdcall;
  qgltexenvfv:procedure(target:TGLenum;pname:TGLenum;params:PGLfloat);stdcall;
  qgltexenvi:procedure(target:TGLenum;pname:TGLenum;param:TGLint);stdcall;
  qgltexenviv:procedure(target:TGLenum;pname:TGLenum;params:PGLint);stdcall;
  qgltexgend:procedure(coord:TGLenum;pname:TGLenum;param:TGLdouble);stdcall;
  qgltexgendv:procedure(coord:TGLenum;pname:TGLenum;params:PGLdouble);stdcall;
  qgltexgenf:procedure(coord:TGLenum;pname:TGLenum;param:TGLfloat);stdcall;
  qgltexgenfv:procedure(coord:TGLenum;pname:TGLenum;params:PGLfloat);stdcall;
  qgltexgeni:procedure(coord:TGLenum;pname:TGLenum;param:TGLint);stdcall;
  qgltexgeniv:procedure(coord:TGLenum;pname:TGLenum;params:PGLint);stdcall;
  qglteximage1d:procedure(target:TGLenum;level:TGLint;internalformat:TGLint;width:TGLsizei;border:TGLint;format:TGLenum;_type:TGLenum;pixels:pointer);stdcall;
  qglteximage2d:procedure(target:TGLenum;level:TGLint;internalformat:TGLint;width:TGLsizei;height:TGLsizei;border:TGLint;format:TGLenum;_type:TGLenum;pixels:pointer);stdcall;
  qgltexparameterf:procedure(target:TGLenum;pname:TGLenum;param:TGLfloat);stdcall;
  qgltexparameterfv:procedure(target:TGLenum;pname:TGLenum;params:PGLfloat);stdcall;
  qgltexparameteri:procedure(target:TGLenum;pname:TGLenum;param:TGLint);stdcall;
  qgltexparameteriv:procedure(target:TGLenum;pname:TGLenum;params:PGLint);stdcall;
  qgltexsubimage1d:procedure(target:TGLenum;level:TGLint;xoffset:TGLint;width:TGLsizei;format:TGLenum;_type:TGLenum;pixels:pointer);stdcall;
  qgltexsubimage2d:procedure(target:TGLenum;level:TGLint;xoffset:TGLint;yoffset:TGLint;width:TGLsizei;height:TGLsizei;format:TGLenum;_type:TGLenum;pixels:pointer);stdcall;
  qgltranslated:procedure(x:TGLdouble;y:TGLdouble;z:TGLdouble);stdcall;
  qgltranslatef:procedure(x:TGLfloat;y:TGLfloat;z:TGLfloat);stdcall;
  qglvertex2d:procedure(x:TGLdouble;y:TGLdouble);stdcall;
  qglvertex2dv:procedure(v:PGLdouble);stdcall;
  qglvertex2f:procedure(x:TGLfloat;y:TGLfloat);stdcall;
  qglvertex2fv:procedure(v:PGLfloat);stdcall;
  qglvertex2i:procedure(x:TGLint;y:TGLint);stdcall;
  qglvertex2iv:procedure(v:PGLint);stdcall;
  qglvertex2s:procedure(x:TGLshort;y:TGLshort);stdcall;
  qglvertex2sv:procedure(v:PGLshort);stdcall;
  qglvertex3d:procedure(x:TGLdouble;y:TGLdouble;z:TGLdouble);stdcall;
  qglvertex3dv:procedure(v:PGLdouble);stdcall;
  qglvertex3f:procedure(x:TGLfloat;y:TGLfloat;z:TGLfloat);stdcall;
  qglvertex3fv:procedure(v:PGLfloat);stdcall;
  qglvertex3i:procedure(x:TGLint;y:TGLint;z:TGLint);stdcall;
  qglvertex3iv:procedure(v:PGLint);stdcall;
  qglvertex3s:procedure(x:TGLshort;y:TGLshort;z:TGLshort);stdcall;
  qglvertex3sv:procedure(v:PGLshort);stdcall;
  qglvertex4d:procedure(x:TGLdouble;y:TGLdouble;z:TGLdouble;w:TGLdouble);stdcall;
  qglvertex4dv:procedure(v:PGLdouble);stdcall;
  qglvertex4f:procedure(x:TGLfloat;y:TGLfloat;z:TGLfloat;w:TGLfloat);stdcall;
  qglvertex4fv:procedure(v:PGLfloat);stdcall;
  qglvertex4i:procedure(x:TGLint;y:TGLint;z:TGLint;w:TGLint);stdcall;
  qglvertex4iv:procedure(v:PGLint);stdcall;
  qglvertex4s:procedure(x:TGLshort;y:TGLshort;z:TGLshort;w:TGLshort);stdcall;
  qglvertex4sv:procedure(v:PGLshort);stdcall;
  qglvertexpointer:procedure(size:TGLint;_type:TGLenum;stride:TGLsizei;pointer:pointer);stdcall;
  qglviewport:procedure(x:TGLint;y:TGLint;width:TGLsizei;height:TGLsizei);stdcall;
  qglpointparameterfext:procedure(param:TGLenum;value:TGLfloat);stdcall;
  qglpointparameterfvext:procedure(param:TGLenum;value:PGLfloat);stdcall;
  qglcolortableext:procedure(p1,p2,p3,p4,p5:integer;p6:pointer);stdcall;
  qgllockarraysext:procedure(first,size:integer);stdcall;
  qglunlockarraysext:procedure;stdcall;
  qglmtexcoord2fsgis:procedure(p1:TGLenum;p2:TGLfloat;p3:TGLfloat);stdcall;
  qglselecttexturesgis:procedure(p1:TGLenum);stdcall;

  {$ifdef WIN32}

  qwglchoosepixelformat:function(dc:hdc;pfd:ppixelformatdescriptor):integer;stdcall;
  qwgldescribepixelformat:function(dc:hdc;p2:integer;p3:cardinal;pfd:ppixelformatdescriptor):integer;stdcall;
  qwglgetpixelformat:function(dc:hdc):integer;stdcall;
  qwglsetpixelformat:function(dc:hdc;p2:integer;pfd:ppixelformatdescriptor):bytebool;stdcall;
  qwglswapbuffers:function(dc:hdc):bytebool;stdcall;
  qwglcopycontext:function(rc:hglrc;rc2:hglrc;p3:cardinal):bytebool;stdcall;
  qwglcreatecontext:function(dc:hdc):hglrc;stdcall;
  qwglcreatelayercontext:function(dc:hdc;p2:integer):hglrc;stdcall;
  qwgldeletecontext:function(rc:hglrc):bytebool;stdcall;
  qwglgetcurrentcontext:function:hglrc;stdcall;
  qwglgetcurrentdc:function:hdc;stdcall;
  qwglgetprocaddress:function(procname:pchar):pointer;stdcall;
  qwglmakecurrent:function(dc:hdc;rc:hglrc):bytebool;stdcall;
  qwglsharelists:function(rc:hglrc;rc2:hglrc):bytebool;stdcall;
  qwglusefontbitmaps:function(dc:hdc;p2:dword;p3:dword;p4:dword):bytebool;stdcall;
  qwglusefontoutlines:function(dc:hdc;p2:dword;p3:dword;p4:dword;p5:single;p6:single;p7:integer;p8:pglyphmetricsfloat):bytebool;stdcall;
  qwgldescribelayerplane:function(dc:hdc;p2:integer;p3:integer;p4:cardinal;p5:playerplanedescriptor):bytebool;stdcall;
  qwglsetlayerpaletteentries:function(dc:hdc;p2:integer;p3:integer;p4:integer;cr:colorref):integer;stdcall;
  qwglgetlayerpaletteentries:function(dc:hdc;p2:integer;p3:integer;p4:integer;p5:colorref):integer;stdcall;
  qwglrealizelayerpalette:function(dc:hdc;p2:integer;p3:bytebool):bytebool;stdcall;

  qwglswaplayerbuffers:function(dc:hdc;p2:cardinal):bytebool;stdcall;
  qwglswapintervalext:function(interval:integer):bytebool;stdcall;
  qwglgetdevicegammarampext:function(red,green,blue:pbytearray):bytebool;stdcall;
  qwglsetdevicegammarampext:function(const red,green,blue:pbytearray):bytebool;stdcall;

{$Endif}
*)
{
** extension constants
}
const
  GL_POINT_SIZE_MIN_EXT            =$8126;
  GL_POINT_SIZE_MAX_EXT            =$8127;
  GL_POINT_FADE_THRESHOLD_SIZE_EXT           =$8128;
  GL_DISTANCE_ATTENUATION_EXT         =$8129;

  {$ifdef __sgi}
  GL_SHARED_TEXTURE_PALETTE_EXT = GL_TEXTURE_COLOR_TABLE_SGI;
  {$else}
  GL_SHARED_TEXTURE_PALETTE_EXT = $81FB;
  {$endif}

  GL_TEXTURE0_SGIS            = $835E;
  GL_TEXTURE1_SGIS            = $835F;
  GL_TEXTURE0_ARB               = $84C0;
  GL_TEXTURE1_ARB               = $84C1;




implementation

end.
