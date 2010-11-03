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
{ File(s): QGL_WIN.C                                                         }
{                                                                            }
{ Initial conversion by : YgriK (Igor Karpov) - glYgriK@hotbox.ru            }
{ Initial conversion on : 18-Jan-2002                                        }
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


{*
** QGL_WIN.C
**
** This file implements the operating system binding of GL to QGL function
** pointers.  When doing a port of Quake2 you must implement the following
** two functions:
**
** QGL_Init() - loads libraries, assigns function pointers, etc.
** QGL_Shutdown() - unloads libraries, NULLs function pointers
*}


unit qgl_win;  //336 glProc

interface

uses
  Windows,
  SysUtils,
  OpenGL,
  q_shared,
  glw_win;

procedure QGL_Shutdown;
function QGL_Init (dllname : PChar) : qboolean;
procedure GLimp_EnableLogging (enable : qboolean);
procedure GLimp_LogNewFrame;

{$I qgl_win_GL_int.inc}  //Xxx_int - interface

implementation

uses
  glw_imp,
  ref,
  gl_rmain,
  gl_local;


{$I qgl_win_GL_imp.inc}  //Xxx_imp - implementation


{*
** QGL_Shutdown
**
** Unloads the specified DLL then nulls out all the proc pointers.
*}
procedure QGL_Shutdown;
begin
  if (glw_state.hinstOpenGL <>0) then
   begin
     FreeLibrary (glw_state.hinstOpenGL);
//{Y}     glw_state.hinstOpenGL := 0;
   end;

  glw_state.hinstOpenGL := 0;

  qglAccum                   := Nil;
  qglAlphaFunc               := Nil;
  qglAreTexturesResident     := Nil;
  qglArrayElement            := Nil;
  qglBegin                   := Nil;
  qglBindTexture             := Nil;
  qglBitmap                  := Nil;
  qglBlendFunc               := Nil;
  qglCallList                := Nil;
  qglCallLists               := Nil;
  qglClear                   := Nil;
  qglClearAccum              := Nil;
  qglClearColor              := Nil;
  qglClearDepth              := Nil;
  qglClearIndex              := Nil;
  qglClearStencil            := Nil;
  qglClipPlane               := Nil;
  qglColor3b                 := Nil;
  qglColor3bv                := Nil;
  qglColor3d                 := Nil;
  qglColor3dv                := Nil;
  qglColor3f                 := Nil;
  qglColor3fv                := Nil;
  qglColor3i                 := Nil;
  qglColor3iv                := Nil;
  qglColor3s                 := Nil;
  qglColor3sv                := Nil;
  qglColor3ub                := Nil;
  qglColor3ubv               := Nil;
  qglColor3ui                := Nil;
  qglColor3uiv               := Nil;
  qglColor3us                := Nil;
  qglColor3usv               := Nil;
  qglColor4b                 := Nil;
  qglColor4bv                := Nil;
  qglColor4d                 := Nil;
  qglColor4dv                := Nil;
  qglColor4f                 := Nil;
  qglColor4fv                := Nil;
  qglColor4i                 := Nil;
  qglColor4iv                := Nil;
  qglColor4s                 := Nil;
  qglColor4sv                := Nil;
  qglColor4ub                := Nil;
  qglColor4ubv               := Nil;
  qglColor4ui                := Nil;
  qglColor4uiv               := Nil;
  qglColor4us                := Nil;
  qglColor4usv               := Nil;
  qglColorMask               := Nil;
  qglColorMaterial           := Nil;
  qglColorPointer            := Nil;
  qglCopyPixels              := Nil;
  qglCopyTexImage1D          := Nil;
  qglCopyTexImage2D          := Nil;
  qglCopyTexSubImage1D       := Nil;
  qglCopyTexSubImage2D       := Nil;
  qglCullFace                := Nil;
  qglDeleteLists             := Nil;
  qglDeleteTextures          := Nil;
  qglDepthFunc               := Nil;
  qglDepthMask               := Nil;
  qglDepthRange              := Nil;
  qglDisable                 := Nil;
  qglDisableClientState      := Nil;
  qglDrawArrays              := Nil;
  qglDrawBuffer              := Nil;
  qglDrawElements            := Nil;
  qglDrawPixels              := Nil;
  qglEdgeFlag                := Nil;
  qglEdgeFlagPointer         := Nil;
  qglEdgeFlagv               := Nil;
  qglEnable                  := Nil;
  qglEnableClientState       := Nil;
  qglEnd                     := Nil;
  qglEndList                 := Nil;
  qglEvalCoord1d             := Nil;
  qglEvalCoord1dv            := Nil;
  qglEvalCoord1f             := Nil;
  qglEvalCoord1fv            := Nil;
  qglEvalCoord2d             := Nil;
  qglEvalCoord2dv            := Nil;
  qglEvalCoord2f             := Nil;
  qglEvalCoord2fv            := Nil;
  qglEvalMesh1               := Nil;
  qglEvalMesh2               := Nil;
  qglEvalPoint1              := Nil;
  qglEvalPoint2              := Nil;
  qglFeedbackBuffer          := Nil;
  qglFinish                  := Nil;
  qglFlush                   := Nil;
  qglFogf                    := Nil;
  qglFogfv                   := Nil;
  qglFogi                    := Nil;
  qglFogiv                   := Nil;
  qglFrontFace               := Nil;
  qglFrustum                 := Nil;
  qglGenLists                := Nil;
  qglGenTextures             := Nil;
  qglGetBooleanv             := Nil;
  qglGetClipPlane            := Nil;
  qglGetDoublev              := Nil;
  qglGetError                := Nil;
  qglGetFloatv               := Nil;
  qglGetIntegerv             := Nil;
  qglGetLightfv              := Nil;
  qglGetLightiv              := Nil;
  qglGetMapdv                := Nil;
  qglGetMapfv                := Nil;
  qglGetMapiv                := Nil;
  qglGetMaterialfv           := Nil;
  qglGetMaterialiv           := Nil;
  qglGetPixelMapfv           := Nil;
  qglGetPixelMapuiv          := Nil;
  qglGetPixelMapusv          := Nil;
  qglGetPointerv             := Nil;
  qglGetPolygonStipple       := Nil;
  qglGetString               := Nil;
  qglGetTexEnvfv             := Nil;
  qglGetTexEnviv             := Nil;
  qglGetTexGendv             := Nil;
  qglGetTexGenfv             := Nil;
  qglGetTexGeniv             := Nil;
  qglGetTexImage             := Nil;
  qglGetTexLevelParameterfv  := Nil;
  qglGetTexLevelParameteriv  := Nil;
  qglGetTexParameterfv       := Nil;
  qglGetTexParameteriv       := Nil;
  qglHint                    := Nil;
  qglIndexMask               := Nil;
  qglIndexPointer            := Nil;
  qglIndexd                  := Nil;
  qglIndexdv                 := Nil;
  qglIndexf                  := Nil;
  qglIndexfv                 := Nil;
  qglIndexi                  := Nil;
  qglIndexiv                 := Nil;
  qglIndexs                  := Nil;
  qglIndexsv                 := Nil;
  qglIndexub                 := Nil;
  qglIndexubv                := Nil;
  qglInitNames               := Nil;
  qglInterleavedArrays       := Nil;
  qglIsEnabled               := Nil;
  qglIsList                  := Nil;
  qglIsTexture               := Nil;
  qglLightModelf             := Nil;
  qglLightModelfv            := Nil;
  qglLightModeli             := Nil;
  qglLightModeliv            := Nil;
  qglLightf                  := Nil;
  qglLightfv                 := Nil;
  qglLighti                  := Nil;
  qglLightiv                 := Nil;
  qglLineStipple             := Nil;
  qglLineWidth               := Nil;
  qglListBase                := Nil;
  qglLoadIdentity            := Nil;
  qglLoadMatrixd             := Nil;
  qglLoadMatrixf             := Nil;
  qglLoadName                := Nil;
  qglLogicOp                 := Nil;
  qglMap1d                   := Nil;
  qglMap1f                   := Nil;
  qglMap2d                   := Nil;
  qglMap2f                   := Nil;
  qglMapGrid1d               := Nil;
  qglMapGrid1f               := Nil;
  qglMapGrid2d               := Nil;
  qglMapGrid2f               := Nil;
  qglMaterialf               := Nil;
  qglMaterialfv              := Nil;
  qglMateriali               := Nil;
  qglMaterialiv              := Nil;
  qglMatrixMode              := Nil;
  qglMultMatrixd             := Nil;
  qglMultMatrixf             := Nil;
  qglNewList                 := Nil;
  qglNormal3b                := Nil;
  qglNormal3bv               := Nil;
  qglNormal3d                := Nil;
  qglNormal3dv               := Nil;
  qglNormal3f                := Nil;
  qglNormal3fv               := Nil;
  qglNormal3i                := Nil;
  qglNormal3iv               := Nil;
  qglNormal3s                := Nil;
  qglNormal3sv               := Nil;
  qglNormalPointer           := Nil;
  qglOrtho                   := Nil;
  qglPassThrough             := Nil;
  qglPixelMapfv              := Nil;
  qglPixelMapuiv             := Nil;
  qglPixelMapusv             := Nil;
  qglPixelStoref             := Nil;
  qglPixelStorei             := Nil;
  qglPixelTransferf          := Nil;
  qglPixelTransferi          := Nil;
  qglPixelZoom               := Nil;
  qglPointSize               := Nil;
  qglPolygonMode             := Nil;
  qglPolygonOffset           := Nil;
  qglPolygonStipple          := Nil;
  qglPopAttrib               := Nil;
  qglPopClientAttrib         := Nil;
  qglPopMatrix               := Nil;
  qglPopName                 := Nil;
  qglPrioritizeTextures      := Nil;
  qglPushAttrib              := Nil;
  qglPushClientAttrib        := Nil;
  qglPushMatrix              := Nil;
  qglPushName                := Nil;
  qglRasterPos2d             := Nil;
  qglRasterPos2dv            := Nil;
  qglRasterPos2f             := Nil;
  qglRasterPos2fv            := Nil;
  qglRasterPos2i             := Nil;
  qglRasterPos2iv            := Nil;
  qglRasterPos2s             := Nil;
  qglRasterPos2sv            := Nil;
  qglRasterPos3d             := Nil;
  qglRasterPos3dv            := Nil;
  qglRasterPos3f             := Nil;
  qglRasterPos3fv            := Nil;
  qglRasterPos3i             := Nil;
  qglRasterPos3iv            := Nil;
  qglRasterPos3s             := Nil;
  qglRasterPos3sv            := Nil;
  qglRasterPos4d             := Nil;
  qglRasterPos4dv            := Nil;
  qglRasterPos4f             := Nil;
  qglRasterPos4fv            := Nil;
  qglRasterPos4i             := Nil;
  qglRasterPos4iv            := Nil;
  qglRasterPos4s             := Nil;
  qglRasterPos4sv            := Nil;
  qglReadBuffer              := Nil;
  qglReadPixels              := Nil;
  qglRectd                   := Nil;
  qglRectdv                  := Nil;
  qglRectf                   := Nil;
  qglRectfv                  := Nil;
  qglRecti                   := Nil;
  qglRectiv                  := Nil;
  qglRects                   := Nil;
  qglRectsv                  := Nil;
  qglRenderMode              := Nil;
  qglRotated                 := Nil;
  qglRotatef                 := Nil;
  qglScaled                  := Nil;
  qglScalef                  := Nil;
  qglScissor                 := Nil;
  qglSelectBuffer            := Nil;
  qglShadeModel              := Nil;
  qglStencilFunc             := Nil;
  qglStencilMask             := Nil;
  qglStencilOp               := Nil;
  qglTexCoord1d              := Nil;
  qglTexCoord1dv             := Nil;
  qglTexCoord1f              := Nil;
  qglTexCoord1fv             := Nil;
  qglTexCoord1i              := Nil;
  qglTexCoord1iv             := Nil;
  qglTexCoord1s              := Nil;
  qglTexCoord1sv             := Nil;
  qglTexCoord2d              := Nil;
  qglTexCoord2dv             := Nil;
  qglTexCoord2f              := Nil;
  qglTexCoord2fv             := Nil;
  qglTexCoord2i              := Nil;
  qglTexCoord2iv             := Nil;
  qglTexCoord2s              := Nil;
  qglTexCoord2sv             := Nil;
  qglTexCoord3d              := Nil;
  qglTexCoord3dv             := Nil;
  qglTexCoord3f              := Nil;
  qglTexCoord3fv             := Nil;
  qglTexCoord3i              := Nil;
  qglTexCoord3iv             := Nil;
  qglTexCoord3s              := Nil;
  qglTexCoord3sv             := Nil;
  qglTexCoord4d              := Nil;
  qglTexCoord4dv             := Nil;
  qglTexCoord4f              := Nil;
  qglTexCoord4fv             := Nil;
  qglTexCoord4i              := Nil;
  qglTexCoord4iv             := Nil;
  qglTexCoord4s              := Nil;
  qglTexCoord4sv             := Nil;
  qglTexCoordPointer         := Nil;
  qglTexEnvf                 := Nil;
  qglTexEnvfv                := Nil;
  qglTexEnvi                 := Nil;
  qglTexEnviv                := Nil;
  qglTexGend                 := Nil;
  qglTexGendv                := Nil;
  qglTexGenf                 := Nil;
  qglTexGenfv                := Nil;
  qglTexGeni                 := Nil;
  qglTexGeniv                := Nil;
  qglTexImage1D              := Nil;
  qglTexImage2D              := Nil;
  qglTexParameterf           := Nil;
  qglTexParameterfv          := Nil;
  qglTexParameteri           := Nil;
  qglTexParameteriv          := Nil;
  qglTexSubImage1D           := Nil;
  qglTexSubImage2D           := Nil;
  qglTranslated              := Nil;
  qglTranslatef              := Nil;
  qglVertex2d                := Nil;
  qglVertex2dv               := Nil;
  qglVertex2f                := Nil;
  qglVertex2fv               := Nil;
  qglVertex2i                := Nil;
  qglVertex2iv               := Nil;
  qglVertex2s                := Nil;
  qglVertex2sv               := Nil;
  qglVertex3d                := Nil;
  qglVertex3dv               := Nil;
  qglVertex3f                := Nil;
  qglVertex3fv               := Nil;
  qglVertex3i                := Nil;
  qglVertex3iv               := Nil;
  qglVertex3s                := Nil;
  qglVertex3sv               := Nil;
  qglVertex4d                := Nil;
  qglVertex4dv               := Nil;
  qglVertex4f                := Nil;
  qglVertex4fv               := Nil;
  qglVertex4i                := Nil;
  qglVertex4iv               := Nil;
  qglVertex4s                := Nil;
  qglVertex4sv               := Nil;
  qglVertexPointer           := Nil;
  qglViewport                := Nil; 

  qwglCopyContext            := Nil;
  qwglCreateContext          := Nil;
  qwglCreateLayerContext     := Nil;
  qwglDeleteContext          := Nil;
  qwglDescribeLayerPlane     := Nil;
  qwglGetCurrentContext      := Nil;
  qwglGetCurrentDC           := Nil;
  qwglGetLayerPaletteEntries := Nil;
  qwglGetProcAddress         := Nil;
  qwglMakeCurrent            := Nil;
  qwglRealizeLayerPalette    := Nil;
  qwglSetLayerPaletteEntries := Nil;
  qwglShareLists             := Nil;
  qwglSwapLayerBuffers       := Nil;
  qwglUseFontBitmaps         := Nil;
  qwglUseFontOutlines        := Nil;

  qwglChoosePixelFormat      := Nil;
  qwglDescribePixelFormat    := Nil;
  qwglGetPixelFormat         := Nil;
  qwglSetPixelFormat         := Nil;
  qwglSwapBuffers            := Nil;

  qwglSwapIntervalEXT        := Nil;

  qwglGetDeviceGammaRampEXT  := Nil;
  qwglSetDeviceGammaRampEXT  := Nil;
end;//procedure

//#   define GPA( a ) GetProcAddress( glw_state.hinstOpenGL, a )
procedure GPA (var qglProcName, dllProcname : TFarProc; ProcName : PChar);
begin
  dllProcName := GetProcAddress (glw_state.hinstOpenGL, ProcName);
  qglProcName := dllProcName;
end;//procedure
procedure GPA1 (var qwglProcName : {pointer}TFarProc; ProcName : PChar);
begin
  qwglProcName := GetProcAddress (glw_state.hinstOpenGL, ProcName);
end;//procedure

{*
** QGL_Init
**
** This is responsible for binding our qgl function pointers to
** the appropriate GL stuff.  In Windows this means doing a
** LoadLibrary and a bunch of calls to GetProcAddress.  On other
** operating systems we need to do the right thing, whatever that
** might be.
**
*}
//function QGL_Init (const char *dllname ) : qboolean;
function QGL_Init (dllname : PChar) : qboolean;
var
  buf : PChar;
begin
  buf := nil;
  // update 3Dfx gamma irrespective of underlying DLL
  {
  char envbuffer[1024];
  float g;

  g = 2.00 * ( 0.8 - ( vid_gamma->value - 0.5 ) ) + 1.0F;
  Com_sprintf( envbuffer, sizeof(envbuffer), "SSTV2_GAMMA=%f", g );
  putenv( envbuffer );
  Com_sprintf( envbuffer, sizeof(envbuffer), "SST_GAMMA=%f", g );
  putenv( envbuffer );
  }

  glw_state.hinstOpenGL := LoadLibrary (dllname);
  if (glw_state.hinstOpenGL = 0) then
  begin
    FormatMessage (FORMAT_MESSAGE_ALLOCATE_BUFFER OR FORMAT_MESSAGE_FROM_SYSTEM,
                   Nil, GetLastError(),
                   0, //MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
                   buf, 0, Nil);
    ri.Con_Printf (PRINT_ALL, '%s'#10, buf);
    Result := false;
    Exit;
  end;

  gl_config.allow_cds := true;

  GPA (@qglAccum                    , @dllAccum                  , 'glAccum');
  GPA (@qglAlphaFunc                , @dllAlphaFunc              , 'glAlphaFunc');
  GPA (@qglAreTexturesResident      , @dllAreTexturesResident    , 'glAreTexturesResident');
  GPA (@qglArrayElement             , @dllArrayElement           , 'glArrayElement');
  GPA (@qglBegin                    , @dllBegin                  , 'glBegin');
  GPA (@qglBindTexture              , @dllBindTexture            , 'glBindTexture');
  GPA (@qglBitmap                   , @dllBitmap                 , 'glBitmap');
  GPA (@qglBlendFunc                , @dllBlendFunc              , 'glBlendFunc');
  GPA (@qglCallList                 , @dllCallList               , 'glCallList');
  GPA (@qglCallLists                , @dllCallLists              , 'glCallLists');
  GPA (@qglClear                    , @dllClear                  , 'glClear');
  GPA (@qglClearAccum               , @dllClearAccum             , 'glClearAccum');
  GPA (@qglClearColor               , @dllClearColor             , 'glClearColor');
  GPA (@qglClearDepth               , @dllClearDepth             , 'glClearDepth');
  GPA (@qglClearIndex               , @dllClearIndex             , 'glClearIndex');
  GPA (@qglClearStencil             , @dllClearStencil           , 'glClearStencil');
  GPA (@qglClipPlane                , @dllClipPlane              , 'glClipPlane');
  GPA (@qglColor3b                  , @dllColor3b                , 'glColor3b');
  GPA (@qglColor3bv                 , @dllColor3bv               , 'glColor3bv');
  GPA (@qglColor3d                  , @dllColor3d                , 'glColor3d');
  GPA (@qglColor3dv                 , @dllColor3dv               , 'glColor3dv');
  GPA (@qglColor3f                  , @dllColor3f                , 'glColor3f');
  GPA (@qglColor3fv                 , @dllColor3fv               , 'glColor3fv');
  GPA (@qglColor3i                  , @dllColor3i                , 'glColor3i');
  GPA (@qglColor3iv                 , @dllColor3iv               , 'glColor3iv');
  GPA (@qglColor3s                  , @dllColor3s                , 'glColor3s');
  GPA (@qglColor3sv                 , @dllColor3sv               , 'glColor3sv');
  GPA (@qglColor3ub                 , @dllColor3ub               , 'glColor3ub');
  GPA (@qglColor3ubv                , @dllColor3ubv              , 'glColor3ubv');
  GPA (@qglColor3ui                 , @dllColor3ui               , 'glColor3ui');
  GPA (@qglColor3uiv                , @dllColor3uiv              , 'glColor3uiv');
  GPA (@qglColor3us                 , @dllColor3us               , 'glColor3us');
  GPA (@qglColor3usv                , @dllColor3usv              , 'glColor3usv');
  GPA (@qglColor4b                  , @dllColor4b                , 'glColor4b');
  GPA (@qglColor4bv                 , @dllColor4bv               , 'glColor4bv');
  GPA (@qglColor4d                  , @dllColor4d                , 'glColor4d');
  GPA (@qglColor4dv                 , @dllColor4dv               , 'glColor4dv');
  GPA (@qglColor4f                  , @dllColor4f                , 'glColor4f');
  GPA (@qglColor4fv                 , @dllColor4fv               , 'glColor4fv');
  GPA (@qglColor4i                  , @dllColor4i                , 'glColor4i');
  GPA (@qglColor4iv                 , @dllColor4iv               , 'glColor4iv');
  GPA (@qglColor4s                  , @dllColor4s                , 'glColor4s');
  GPA (@qglColor4sv                 , @dllColor4sv               , 'glColor4sv');
  GPA (@qglColor4ub                 , @dllColor4ub               , 'glColor4ub');
  GPA (@qglColor4ubv                , @dllColor4ubv              , 'glColor4ubv');
  GPA (@qglColor4ui                 , @dllColor4ui               , 'glColor4ui');
  GPA (@qglColor4uiv                , @dllColor4uiv              , 'glColor4uiv');
  GPA (@qglColor4us                 , @dllColor4us               , 'glColor4us');
  GPA (@qglColor4usv                , @dllColor4usv              , 'glColor4usv');
  GPA (@qglColorMask                , @dllColorMask              , 'glColorMask');
  GPA (@qglColorMaterial            , @dllColorMaterial          , 'glColorMaterial');
  GPA (@qglColorPointer             , @dllColorPointer           , 'glColorPointer');
  GPA (@qglCopyPixels               , @dllCopyPixels             , 'glCopyPixels');
  GPA (@qglCopyTexImage1D           , @dllCopyTexImage1D         , 'glCopyTexImage1D');
  GPA (@qglCopyTexImage2D           , @dllCopyTexImage2D         , 'glCopyTexImage2D');
  GPA (@qglCopyTexSubImage1D        , @dllCopyTexSubImage1D      , 'glCopyTexSubImage1D');
  GPA (@qglCopyTexSubImage2D        , @dllCopyTexSubImage2D      , 'glCopyTexSubImage2D');
  GPA (@qglCullFace                 , @dllCullFace               , 'glCullFace');
  GPA (@qglDeleteLists              , @dllDeleteLists            , 'glDeleteLists');
  GPA (@qglDeleteTextures           , @dllDeleteTextures         , 'glDeleteTextures');
  GPA (@qglDepthFunc                , @dllDepthFunc              , 'glDepthFunc');
  GPA (@qglDepthMask                , @dllDepthMask              , 'glDepthMask');
  GPA (@qglDepthRange               , @dllDepthRange             , 'glDepthRange');
  GPA (@qglDisable                  , @dllDisable                , 'glDisable');
  GPA (@qglDisableClientState       , @dllDisableClientState     , 'glDisableClientState');
  GPA (@qglDrawArrays               , @dllDrawArrays             , 'glDrawArrays');
  GPA (@qglDrawBuffer               , @dllDrawBuffer             , 'glDrawBuffer');
  GPA (@qglDrawElements             , @dllDrawElements           , 'glDrawElements');
  GPA (@qglDrawPixels               , @dllDrawPixels             , 'glDrawPixels');
  GPA (@qglEdgeFlag                 , @dllEdgeFlag               , 'glEdgeFlag');
  GPA (@qglEdgeFlagPointer          , @dllEdgeFlagPointer        , 'glEdgeFlagPointer');
  GPA (@qglEdgeFlagv                , @dllEdgeFlagv              , 'glEdgeFlagv');
  GPA (@qglEnable                   , @dllEnable                 , 'glEnable');
  GPA (@qglEnableClientState        , @dllEnableClientState      , 'glEnableClientState');
  GPA (@qglEnd                      , @dllEnd                    , 'glEnd');
  GPA (@qglEndList                  , @dllEndList                , 'glEndList');
  GPA (@qglEvalCoord1d          , @dllEvalCoord1d            , 'glEvalCoord1d');
  GPA (@qglEvalCoord1dv             , @dllEvalCoord1dv           , 'glEvalCoord1dv');
  GPA (@qglEvalCoord1f              , @dllEvalCoord1f            , 'glEvalCoord1f');
  GPA (@qglEvalCoord1fv             , @dllEvalCoord1fv           , 'glEvalCoord1fv');
  GPA (@qglEvalCoord2d              , @dllEvalCoord2d            , 'glEvalCoord2d');
  GPA (@qglEvalCoord2dv             , @dllEvalCoord2dv           , 'glEvalCoord2dv');
  GPA (@qglEvalCoord2f              , @dllEvalCoord2f            , 'glEvalCoord2f');
  GPA (@qglEvalCoord2fv             , @dllEvalCoord2fv           , 'glEvalCoord2fv');
  GPA (@qglEvalMesh1                , @dllEvalMesh1              , 'glEvalMesh1');
  GPA (@qglEvalMesh2                , @dllEvalMesh2              , 'glEvalMesh2');
  GPA (@qglEvalPoint1               , @dllEvalPoint1             , 'glEvalPoint1');
  GPA (@qglEvalPoint2               , @dllEvalPoint2             , 'glEvalPoint2');
  GPA (@qglFeedbackBuffer           , @dllFeedbackBuffer         , 'glFeedbackBuffer');
  GPA (@qglFinish                   , @dllFinish                 , 'glFinish');
  GPA (@qglFlush                    , @dllFlush                  , 'glFlush');
  GPA (@qglFogf                     , @dllFogf                   , 'glFogf');
  GPA (@qglFogfv                    , @dllFogfv                  , 'glFogfv');
  GPA (@qglFogi                     , @dllFogi                   , 'glFogi');
  GPA (@qglFogiv                    , @dllFogiv                  , 'glFogiv');
  GPA (@qglFrontFace                , @dllFrontFace              , 'glFrontFace');
  GPA (@qglFrustum                  , @dllFrustum                , 'glFrustum');
  GPA (@qglGenLists                 , @dllGenLists               , 'glGenLists');
  GPA (@qglGenTextures              , @dllGenTextures            , 'glGenTextures');
  GPA (@qglGetBooleanv              , @dllGetBooleanv            , 'glGetBooleanv');
  GPA (@qglGetClipPlane             , @dllGetClipPlane           , 'glGetClipPlane');
  GPA (@qglGetDoublev               , @dllGetDoublev             , 'glGetDoublev');
  GPA (@qglGetError                 , @dllGetError               , 'glGetError');
  GPA (@qglGetFloatv                , @dllGetFloatv              , 'glGetFloatv');
  GPA (@qglGetIntegerv              , @dllGetIntegerv            , 'glGetIntegerv');
  GPA (@qglGetLightfv               , @dllGetLightfv             , 'glGetLightfv');
  GPA (@qglGetLightiv               , @dllGetLightiv             , 'glGetLightiv');
  GPA (@qglGetMapdv                 , @dllGetMapdv               , 'glGetMapdv');
  GPA (@qglGetMapfv                 , @dllGetMapfv               , 'glGetMapfv');
  GPA (@qglGetMapiv                 , @dllGetMapiv               , 'glGetMapiv');
  GPA (@qglGetMaterialfv            , @dllGetMaterialfv          , 'glGetMaterialfv');
  GPA (@qglGetMaterialiv            , @dllGetMaterialiv          , 'glGetMaterialiv');
  GPA (@qglGetPixelMapfv            , @dllGetPixelMapfv          , 'glGetPixelMapfv');
  GPA (@qglGetPixelMapuiv           , @dllGetPixelMapuiv         , 'glGetPixelMapuiv');
  GPA (@qglGetPixelMapusv           , @dllGetPixelMapusv         , 'glGetPixelMapusv');
  GPA (@qglGetPointerv              , @dllGetPointerv            , 'glGetPointerv');
  GPA (@qglGetPolygonStipple        , @dllGetPolygonStipple      , 'glGetPolygonStipple');
  GPA (@qglGetString                , @dllGetString              , 'glGetString');
  GPA (@qglGetTexEnvfv              , @dllGetTexEnvfv            , 'glGetTexEnvfv');
  GPA (@qglGetTexEnviv              , @dllGetTexEnviv            , 'glGetTexEnviv');
  GPA (@qglGetTexGendv              , @dllGetTexGendv            , 'glGetTexGendv');
  GPA (@qglGetTexGenfv              , @dllGetTexGenfv            , 'glGetTexGenfv');
  GPA (@qglGetTexGeniv              , @dllGetTexGeniv            , 'glGetTexGeniv');
  GPA (@qglGetTexImage              , @dllGetTexImage            , 'glGetTexImage');
  GPA (@qglGetTexLevelParameterfv   , @dllGetTexLevelParameterfv , 'glGetLevelParameterfv');
  GPA (@qglGetTexLevelParameteriv   , @dllGetTexLevelParameteriv , 'glGetLevelParameteriv');
  GPA (@qglGetTexParameterfv        , @dllGetTexParameterfv      , 'glGetTexParameterfv');
  GPA (@qglGetTexParameteriv        , @dllGetTexParameteriv      , 'glGetTexParameteriv');
  GPA (@qglHint                     , @dllHint                   , 'glHint');
  GPA (@qglIndexMask                , @dllIndexMask              , 'glIndexMask');
  GPA (@qglIndexPointer             , @dllIndexPointer           , 'glIndexPointer');
  GPA (@qglIndexd                   , @dllIndexd                 , 'glIndexd');
  GPA (@qglIndexdv                  , @dllIndexdv                , 'glIndexdv');
  GPA (@qglIndexf                   , @dllIndexf                 , 'glIndexf');
  GPA (@qglIndexfv                  , @dllIndexfv                , 'glIndexfv');
  GPA (@qglIndexi                   , @dllIndexi                 , 'glIndexi');
  GPA (@qglIndexiv                  , @dllIndexiv                , 'glIndexiv');
  GPA (@qglIndexs                   , @dllIndexs                 , 'glIndexs');
  GPA (@qglIndexsv                  , @dllIndexsv                , 'glIndexsv');
  GPA (@qglIndexub                  , @dllIndexub                , 'glIndexub');
  GPA (@qglIndexubv                 , @dllIndexubv               , 'glIndexubv');
  GPA (@qglInitNames                , @dllInitNames              , 'glInitNames');
  GPA (@qglInterleavedArrays        , @dllInterleavedArrays      , 'glInterleavedArrays');
  GPA (@qglIsEnabled                , @dllIsEnabled              , 'glIsEnabled');
  GPA (@qglIsList                   , @dllIsList                 , 'glIsList');
  GPA (@qglIsTexture                , @dllIsTexture              , 'glIsTexture');
  GPA (@qglLightModelf              , @dllLightModelf            , 'glLightModelf');
  GPA (@qglLightModelfv             , @dllLightModelfv           , 'glLightModelfv');
  GPA (@qglLightModeli              , @dllLightModeli            , 'glLightModeli');
  GPA (@qglLightModeliv             , @dllLightModeliv           , 'glLightModeliv');
  GPA (@qglLightf                   , @dllLightf                 , 'glLightf');
  GPA (@qglLightfv                  , @dllLightfv                , 'glLightfv');
  GPA (@qglLighti                   , @dllLighti                 , 'glLighti');
  GPA (@qglLightiv                  , @dllLightiv                , 'glLightiv');
  GPA (@qglLineStipple              , @dllLineStipple            , 'glLineStipple');
  GPA (@qglLineWidth                , @dllLineWidth              , 'glLineWidth');
  GPA (@qglListBase                 , @dllListBase               , 'glListBase');
  GPA (@qglLoadIdentity             , @dllLoadIdentity           , 'glLoadIdentity');
  GPA (@qglLoadMatrixd              , @dllLoadMatrixd            , 'glLoadMatrixd');
  GPA (@qglLoadMatrixf              , @dllLoadMatrixf            , 'glLoadMatrixf');
  GPA (@qglLoadName                 , @dllLoadName               , 'glLoadName');
  GPA (@qglLogicOp                  , @dllLogicOp                , 'glLogicOp');
  GPA (@qglMap1d                    , @dllMap1d                  , 'glMap1d');
  GPA (@qglMap1f                    , @dllMap1f                  , 'glMap1f');
  GPA (@qglMap2d                    , @dllMap2d                  , 'glMap2d');
  GPA (@qglMap2f                    , @dllMap2f                  , 'glMap2f');
  GPA (@qglMapGrid1d                , @dllMapGrid1d              , 'glMapGrid1d');
  GPA (@qglMapGrid1f                , @dllMapGrid1f              , 'glMapGrid1f');
  GPA (@qglMapGrid2d                , @dllMapGrid2d              , 'glMapGrid2d');
  GPA (@qglMapGrid2f                , @dllMapGrid2f              , 'glMapGrid2f');
  GPA (@qglMaterialf                , @dllMaterialf              , 'glMaterialf');
  GPA (@qglMaterialfv               , @dllMaterialfv             , 'glMaterialfv');
  GPA (@qglMateriali                , @dllMateriali              , 'glMateriali');
  GPA (@qglMaterialiv               , @dllMaterialiv             , 'glMaterialiv');
  GPA (@qglMatrixMode               , @dllMatrixMode             , 'glMatrixMode');
  GPA (@qglMultMatrixd              , @dllMultMatrixd            , 'glMultMatrixd');
  GPA (@qglMultMatrixf              , @dllMultMatrixf            , 'glMultMatrixf');
  GPA (@qglNewList                  , @dllNewList                , 'glNewList');
  GPA (@qglNormal3b                 , @dllNormal3b               , 'glNormal3b');
  GPA (@qglNormal3bv                , @dllNormal3bv              , 'glNormal3bv');
  GPA (@qglNormal3d                 , @dllNormal3d               , 'glNormal3d');
  GPA (@qglNormal3dv                , @dllNormal3dv              , 'glNormal3dv');
  GPA (@qglNormal3f                 , @dllNormal3f               , 'glNormal3f');
  GPA (@qglNormal3fv                , @dllNormal3fv              , 'glNormal3fv');
  GPA (@qglNormal3i                 , @dllNormal3i               , 'glNormal3i');
  GPA (@qglNormal3iv                , @dllNormal3iv              , 'glNormal3iv');
  GPA (@qglNormal3s                 , @dllNormal3s               , 'glNormal3s');
  GPA (@qglNormal3sv                , @dllNormal3sv              , 'glNormal3sv');
  GPA (@qglNormalPointer            , @dllNormalPointer          , 'glNormalPointer');
  GPA (@qglOrtho                    , @dllOrtho                  , 'glOrtho');
  GPA (@qglPassThrough              , @dllPassThrough            , 'glPassThrough');
  GPA (@qglPixelMapfv               , @dllPixelMapfv             , 'glPixelMapfv');
  GPA (@qglPixelMapuiv              , @dllPixelMapuiv            , 'glPixelMapuiv');
  GPA (@qglPixelMapusv              , @dllPixelMapusv            , 'glPixelMapusv');
  GPA (@qglPixelStoref              , @dllPixelStoref            , 'glPixelStoref');
  GPA (@qglPixelStorei              , @dllPixelStorei            , 'glPixelStorei');
  GPA (@qglPixelTransferf           , @dllPixelTransferf         , 'glPixelTransferf');
  GPA (@qglPixelTransferi           , @dllPixelTransferi         , 'glPixelTransferi');
  GPA (@qglPixelZoom                , @dllPixelZoom              , 'glPixelZoom');
  GPA (@qglPointSize                , @dllPointSize              , 'glPointSize');
  GPA (@qglPolygonMode              , @dllPolygonMode            , 'glPolygonMode');
  GPA (@qglPolygonOffset            , @dllPolygonOffset          , 'glPolygonOffset');
  GPA (@qglPolygonStipple           , @dllPolygonStipple         , 'glPolygonStipple');
  GPA (@qglPopAttrib                , @dllPopAttrib              , 'glPopAttrib');
  GPA (@qglPopClientAttrib          , @dllPopClientAttrib        , 'glPopClientAttrib');
  GPA (@qglPopMatrix                , @dllPopMatrix              , 'glPopMatrix');
  GPA (@qglPopName                  , @dllPopName                , 'glPopName');
  GPA (@qglPrioritizeTextures       , @dllPrioritizeTextures     , 'glPrioritizeTextures');
  GPA (@qglPushAttrib               , @dllPushAttrib             , 'glPushAttrib');
  GPA (@qglPushClientAttrib         , @dllPushClientAttrib       , 'glPushClientAttrib');
  GPA (@qglPushMatrix               , @dllPushMatrix             , 'glPushMatrix');
  GPA (@qglPushName                 , @dllPushName               , 'glPushName');
  GPA (@qglRasterPos2d              , @dllRasterPos2d            , 'glRasterPos2d');
  GPA (@qglRasterPos2dv             , @dllRasterPos2dv           , 'glRasterPos2dv');
  GPA (@qglRasterPos2f              , @dllRasterPos2f            , 'glRasterPos2f');
  GPA (@qglRasterPos2fv             , @dllRasterPos2fv           , 'glRasterPos2fv');
  GPA (@qglRasterPos2i              , @dllRasterPos2i            , 'glRasterPos2i');
  GPA (@qglRasterPos2iv             , @dllRasterPos2iv           , 'glRasterPos2iv');
  GPA (@qglRasterPos2s              , @dllRasterPos2s            , 'glRasterPos2s');
  GPA (@qglRasterPos2sv             , @dllRasterPos2sv           , 'glRasterPos2sv');
  GPA (@qglRasterPos3d              , @dllRasterPos3d            , 'glRasterPos3d');
  GPA (@qglRasterPos3dv             , @dllRasterPos3dv           , 'glRasterPos3dv');
  GPA (@qglRasterPos3f              , @dllRasterPos3f            , 'glRasterPos3f');
  GPA (@qglRasterPos3fv             , @dllRasterPos3fv           , 'glRasterPos3fv');
  GPA (@qglRasterPos3i              , @dllRasterPos3i            , 'glRasterPos3i');
  GPA (@qglRasterPos3iv             , @dllRasterPos3iv           , 'glRasterPos3iv');
  GPA (@qglRasterPos3s              , @dllRasterPos3s            , 'glRasterPos3s');
  GPA (@qglRasterPos3sv             , @dllRasterPos3sv           , 'glRasterPos3sv');
  GPA (@qglRasterPos4d              , @dllRasterPos4d            , 'glRasterPos4d');
  GPA (@qglRasterPos4dv             , @dllRasterPos4dv           , 'glRasterPos4dv');
  GPA (@qglRasterPos4f              , @dllRasterPos4f            , 'glRasterPos4f');
  GPA (@qglRasterPos4fv             , @dllRasterPos4fv           , 'glRasterPos4fv');
  GPA (@qglRasterPos4i              , @dllRasterPos4i            , 'glRasterPos4i');
  GPA (@qglRasterPos4iv             , @dllRasterPos4iv           , 'glRasterPos4iv');
  GPA (@qglRasterPos4s              , @dllRasterPos4s            , 'glRasterPos4s');
  GPA (@qglRasterPos4sv             , @dllRasterPos4sv           , 'glRasterPos4sv');
  GPA (@qglReadBuffer               , @dllReadBuffer             , 'glReadBuffer');
  GPA (@qglReadPixels               , @dllReadPixels             , 'glReadPixels');
  GPA (@qglRectd                    , @dllRectd                  , 'glRectd');
  GPA (@qglRectdv                   , @dllRectdv                 , 'glRectdv');
  GPA (@qglRectf                    , @dllRectf                  , 'glRectf');
  GPA (@qglRectfv                   , @dllRectfv                 , 'glRectfv');
  GPA (@qglRecti                    , @dllRecti                  , 'glRecti');
  GPA (@qglRectiv                   , @dllRectiv                 , 'glRectiv');
  GPA (@qglRects                    , @dllRects                  , 'glRects');
  GPA (@qglRectsv                   , @dllRectsv                 , 'glRectsv');
  GPA (@qglRenderMode               , @dllRenderMode             , 'glRenderMode');
  GPA (@qglRotated                  , @dllRotated                , 'glRotated');
  GPA (@qglRotatef                  , @dllRotatef                , 'glRotatef');
  GPA (@qglScaled                   , @dllScaled                 , 'glScaled');
  GPA (@qglScalef                   , @dllScalef                 , 'glScalef');
  GPA (@qglScissor                  , @dllScissor                , 'glScissor');
  GPA (@qglSelectBuffer             , @dllSelectBuffer           , 'glSelectBuffer');
  GPA (@qglShadeModel               , @dllShadeModel             , 'glShadeModel');
  GPA (@qglStencilFunc              , @dllStencilFunc            , 'glStencilFunc');
  GPA (@qglStencilMask              , @dllStencilMask            , 'glStencilMask');
  GPA (@qglStencilOp                , @dllStencilOp              , 'glStencilOp');
  GPA (@qglTexCoord1d               , @dllTexCoord1d             , 'glTexCoord1d');
  GPA (@qglTexCoord1dv              , @dllTexCoord1dv            , 'glTexCoord1dv');
  GPA (@qglTexCoord1f               , @dllTexCoord1f             , 'glTexCoord1f');
  GPA (@qglTexCoord1fv              , @dllTexCoord1fv            , 'glTexCoord1fv');
  GPA (@qglTexCoord1i               , @dllTexCoord1i             , 'glTexCoord1i');
  GPA (@qglTexCoord1iv              , @dllTexCoord1iv            , 'glTexCoord1iv');
  GPA (@qglTexCoord1s               , @dllTexCoord1s             , 'glTexCoord1s');
  GPA (@qglTexCoord1sv              , @dllTexCoord1sv            , 'glTexCoord1sv');
  GPA (@qglTexCoord2d               , @dllTexCoord2d             , 'glTexCoord2d');
  GPA (@qglTexCoord2dv              , @dllTexCoord2dv            , 'glTexCoord2dv');
  GPA (@qglTexCoord2f               , @dllTexCoord2f             , 'glTexCoord2f');
  GPA (@qglTexCoord2fv              , @dllTexCoord2fv            , 'glTexCoord2fv');
  GPA (@qglTexCoord2i               , @dllTexCoord2i             , 'glTexCoord2i');
  GPA (@qglTexCoord2iv              , @dllTexCoord2iv            , 'glTexCoord2iv');
  GPA (@qglTexCoord2s               , @dllTexCoord2s             , 'glTexCoord2s');
  GPA (@qglTexCoord2sv              , @dllTexCoord2sv            , 'glTexCoord2sv');
  GPA (@qglTexCoord3d               , @dllTexCoord3d             , 'glTexCoord3d');
  GPA (@qglTexCoord3dv              , @dllTexCoord3dv            , 'glTexCoord3dv');
  GPA (@qglTexCoord3f               , @dllTexCoord3f             , 'glTexCoord3f');
  GPA (@qglTexCoord3fv              , @dllTexCoord3fv            , 'glTexCoord3fv');
  GPA (@qglTexCoord3i               , @dllTexCoord3i             , 'glTexCoord3i');
  GPA (@qglTexCoord3iv              , @dllTexCoord3iv            , 'glTexCoord3iv');
  GPA (@qglTexCoord3s               , @dllTexCoord3s             , 'glTexCoord3s');
  GPA (@qglTexCoord3sv              , @dllTexCoord3sv            , 'glTexCoord3sv');
  GPA (@qglTexCoord4d               , @dllTexCoord4d             , 'glTexCoord4d');
  GPA (@qglTexCoord4dv              , @dllTexCoord4dv            , 'glTexCoord4dv');
  GPA (@qglTexCoord4f               , @dllTexCoord4f             , 'glTexCoord4f');
  GPA (@qglTexCoord4fv              , @dllTexCoord4fv            , 'glTexCoord4fv');
  GPA (@qglTexCoord4i               , @dllTexCoord4i             , 'glTexCoord4i');
  GPA (@qglTexCoord4iv              , @dllTexCoord4iv            , 'glTexCoord4iv');
  GPA (@qglTexCoord4s               , @dllTexCoord4s             , 'glTexCoord4s');
  GPA (@qglTexCoord4sv              , @dllTexCoord4sv            , 'glTexCoord4sv');
  GPA (@qglTexCoordPointer          , @dllTexCoordPointer        , 'glTexCoordPointer');
  GPA (@qglTexEnvf                  , @dllTexEnvf                , 'glTexEnvf');
  GPA (@qglTexEnvfv                 , @dllTexEnvfv               , 'glTexEnvfv');
  GPA (@qglTexEnvi                  , @dllTexEnvi                , 'glTexEnvi');
  GPA (@qglTexEnviv                 , @dllTexEnviv               , 'glTexEnviv');
  GPA (@qglTexGend                  , @dllTexGend                , 'glTexGend');
  GPA (@qglTexGendv                 , @dllTexGendv               , 'glTexGendv');
  GPA (@qglTexGenf                  , @dllTexGenf                , 'glTexGenf');
  GPA (@qglTexGenfv                 , @dllTexGenfv               , 'glTexGenfv');
  GPA (@qglTexGeni                  , @dllTexGeni                , 'glTexGeni');
  GPA (@qglTexGeniv                 , @dllTexGeniv               , 'glTexGeniv');
  GPA (@qglTexImage1D               , @dllTexImage1D             , 'glTexImage1D');
  GPA (@qglTexImage2D               , @dllTexImage2D             , 'glTexImage2D');
  GPA (@qglTexParameterf            , @dllTexParameterf          , 'glTexParameterf');
  GPA (@qglTexParameterfv           , @dllTexParameterfv         , 'glTexParameterfv');
  GPA (@qglTexParameteri            , @dllTexParameteri          , 'glTexParameteri');
  GPA (@qglTexParameteriv           , @dllTexParameteriv         , 'glTexParameteriv');
  GPA (@qglTexSubImage1D            , @dllTexSubImage1D          , 'glTexSubImage1D');
  GPA (@qglTexSubImage2D            , @dllTexSubImage2D          , 'glTexSubImage2D');
  GPA (@qglTranslated               , @dllTranslated             , 'glTranslated');
  GPA (@qglTranslatef               , @dllTranslatef             , 'glTranslatef');
  GPA (@qglVertex2d                 , @dllVertex2d               , 'glVertex2d');
  GPA (@qglVertex2dv                , @dllVertex2dv              , 'glVertex2dv');
  GPA (@qglVertex2f                 , @dllVertex2f               , 'glVertex2f');
  GPA (@qglVertex2fv                , @dllVertex2fv              , 'glVertex2fv');
  GPA (@qglVertex2i                 , @dllVertex2i               , 'glVertex2i');
  GPA (@qglVertex2iv                , @dllVertex2iv              , 'glVertex2iv');
  GPA (@qglVertex2s                 , @dllVertex2s               , 'glVertex2s');
  GPA (@qglVertex2sv                , @dllVertex2sv              , 'glVertex2sv');
  GPA (@qglVertex3d                 , @dllVertex3d               , 'glVertex3d');
  GPA (@qglVertex3dv                , @dllVertex3dv              , 'glVertex3dv');
  GPA (@qglVertex3f                 , @dllVertex3f               , 'glVertex3f');
  GPA (@qglVertex3fv                , @dllVertex3fv              , 'glVertex3fv');
  GPA (@qglVertex3i                 , @dllVertex3i               , 'glVertex3i');
  GPA (@qglVertex3iv                , @dllVertex3iv              , 'glVertex3iv');
  GPA (@qglVertex3s                 , @dllVertex3s               , 'glVertex3s');
  GPA (@qglVertex3sv                , @dllVertex3sv              , 'glVertex3sv');
  GPA (@qglVertex4d                 , @dllVertex4d               , 'glVertex4d');
  GPA (@qglVertex4dv                , @dllVertex4dv              , 'glVertex4dv');
  GPA (@qglVertex4f                 , @dllVertex4f               , 'glVertex4f');
  GPA (@qglVertex4fv                , @dllVertex4fv              , 'glVertex4fv');
  GPA (@qglVertex4i                 , @dllVertex4i               , 'glVertex4i');
  GPA (@qglVertex4iv                , @dllVertex4iv              , 'glVertex4iv');
  GPA (@qglVertex4s                 , @dllVertex4s               , 'glVertex4s');
  GPA (@qglVertex4sv                , @dllVertex4sv              , 'glVertex4sv');
  GPA (@qglVertexPointer            , @dllVertexPointer          , 'glVertexPointer');
  GPA (@qglViewport                 , @dllViewport               , 'glViewport');

  GPA1 (@qwglCopyContext            , 'wglCopyContext');
  GPA1 (@qwglCreateContext          , 'wglCreateContext');
  GPA1 (@qwglCreateLayerContext     , 'wglCreateLayerContext');
  GPA1 (@qwglDeleteContext          , 'wglDeleteContext');
  GPA1 (@qwglDescribeLayerPlane     , 'wglDescribeLayerPlane');
  GPA1 (@qwglGetCurrentContext      , 'wglGetCurrentContext');
  GPA1 (@qwglGetCurrentDC           , 'wglGetCurrentDC');
  GPA1 (@qwglGetLayerPaletteEntries , 'wglGetLayerPaletteEntries');
  GPA1 (@qwglGetProcAddress         , 'wglGetProcAddress');
  GPA1 (@qwglMakeCurrent            , 'wglMakeCurrent');
  GPA1 (@qwglRealizeLayerPalette    , 'wglRealizeLayerPalette');
  GPA1 (@qwglSetLayerPaletteEntries , 'wglSetLayerPaletteEntries');
  GPA1 (@qwglShareLists             , 'wglShareLists');
  GPA1 (@qwglSwapLayerBuffers       , 'wglSwapLayerBuffers');
  GPA1 (@qwglUseFontBitmaps         , 'wglUseFontBitmapsA');
  GPA1 (@qwglUseFontOutlines        , 'wglUseFontOutlinesA');

  GPA1 (@qwglChoosePixelFormat      , 'wglChoosePixelFormat');
  GPA1 (@qwglDescribePixelFormat    , 'wglDescribePixelFormat');
  GPA1 (@qwglGetPixelFormat         , 'wglGetPixelFormat');
  GPA1 (@qwglSetPixelFormat         , 'wglSetPixelFormat');
  GPA1 (@qwglSwapBuffers            , 'wglSwapBuffers');

  qwglSwapIntervalEXT    := Nil;
  qglPointParameterfEXT  := Nil;
  qglPointParameterfvEXT := Nil;
  qglColorTableEXT       := Nil;
  qglSelectTextureSGIS   := Nil;
  qglMTexCoord2fSGIS     := Nil;

  Result := true;
end;//function

procedure GLimp_EnableLogging (enable : qboolean);
var
  F : textfile; {666}
begin
  if enable
  then begin
//    if ( !glw_state.log_fp ) then
    //PAS-code for "var F : textfile"
    if (TTextRec(F).Mode = fmClosed) or (TTextRec(F).Name = '') then
    begin
(*666      struct tm *newtime;
      time_t aclock;
      char buffer[1024];

      time( &aclock );
      newtime = localtime( &aclock );

      asctime( newtime );

      Com_sprintf (buffer, sizeof(buffer), '%s/gl.log', ri.FS_Gamedir());
//      glw_state.log_fp = fopen( buffer, 'wt');
//      fprintf( glw_state.log_fp, '%s'#10, asctime( newtime ));
      AssignFile (glw_state.log_fp, buffer); //'wt'
      Rewrite (glw_state.log_fp);
      WriteLn (glw_state.log_fp, Format('%s'#10, [asctime(newtime)])); 666*)
    end;

    qglAccum                  := logAccum;
    qglAlphaFunc              := logAlphaFunc;
    qglAreTexturesResident    := logAreTexturesResident;
    qglArrayElement           := logArrayElement;
    qglBegin                  := logBegin;
    qglBindTexture            := logBindTexture;
    qglBitmap                 := logBitmap;
    qglBlendFunc              := logBlendFunc;
    qglCallList               := logCallList;
    qglCallLists              := logCallLists;
    qglClear                  := logClear;
    qglClearAccum             := logClearAccum;
    qglClearColor             := logClearColor;
    qglClearDepth             := logClearDepth;
    qglClearIndex             := logClearIndex;
    qglClearStencil           := logClearStencil;
    qglClipPlane              := logClipPlane;
    qglColor3b                := logColor3b;
    qglColor3bv               := logColor3bv;
    qglColor3d                := logColor3d;
    qglColor3dv               := logColor3dv;
    qglColor3f                := logColor3f;
    qglColor3fv               := logColor3fv;
    qglColor3i                := logColor3i;
    qglColor3iv               := logColor3iv;
    qglColor3s                := logColor3s;
    qglColor3sv               := logColor3sv;
    qglColor3ub               := logColor3ub;
    qglColor3ubv              := logColor3ubv;
    qglColor3ui               := logColor3ui;
    qglColor3uiv              := logColor3uiv;
    qglColor3us               := logColor3us;
    qglColor3usv              := logColor3usv;
    qglColor4b                := logColor4b;
    qglColor4bv               := logColor4bv;
    qglColor4d                := logColor4d;
    qglColor4dv               := logColor4dv;
    qglColor4f                := logColor4f;
    qglColor4fv               := logColor4fv;
    qglColor4i                := logColor4i;
    qglColor4iv               := logColor4iv;
    qglColor4s                := logColor4s;
    qglColor4sv               := logColor4sv;
    qglColor4ub               := logColor4ub;
    qglColor4ubv              := logColor4ubv;
    qglColor4ui               := logColor4ui;
    qglColor4uiv              := logColor4uiv;
    qglColor4us               := logColor4us;
    qglColor4usv              := logColor4usv;
    qglColorMask              := logColorMask;
    qglColorMaterial          := logColorMaterial;
    qglColorPointer           := logColorPointer;
    qglCopyPixels             := logCopyPixels;
    qglCopyTexImage1D         := logCopyTexImage1D;
    qglCopyTexImage2D         := logCopyTexImage2D;
    qglCopyTexSubImage1D      := logCopyTexSubImage1D;
    qglCopyTexSubImage2D      := logCopyTexSubImage2D;
    qglCullFace               := logCullFace;
    qglDeleteLists            := logDeleteLists ;
    qglDeleteTextures         := logDeleteTextures ;
    qglDepthFunc              := logDepthFunc ;
    qglDepthMask              := logDepthMask ;
    qglDepthRange             := logDepthRange ;
    qglDisable                := logDisable ;
    qglDisableClientState     := logDisableClientState ;
    qglDrawArrays             := logDrawArrays ;
    qglDrawBuffer             := logDrawBuffer ;
    qglDrawElements           := logDrawElements ;
    qglDrawPixels             := logDrawPixels ;
    qglEdgeFlag               := logEdgeFlag ;
    qglEdgeFlagPointer        := logEdgeFlagPointer ;
    qglEdgeFlagv              := logEdgeFlagv ;
    qglEnable                 := logEnable                    ;
    qglEnableClientState      := logEnableClientState         ;
    qglEnd                    := logEnd                       ;
    qglEndList                := logEndList                   ;
    qglEvalCoord1d         := logEvalCoord1d            ;
    qglEvalCoord1dv           := logEvalCoord1dv              ;
    qglEvalCoord1f            := logEvalCoord1f               ;
    qglEvalCoord1fv           := logEvalCoord1fv              ;
    qglEvalCoord2d            := logEvalCoord2d               ;
    qglEvalCoord2dv           := logEvalCoord2dv              ;
    qglEvalCoord2f            := logEvalCoord2f               ;
    qglEvalCoord2fv           := logEvalCoord2fv              ;
    qglEvalMesh1              := logEvalMesh1                 ;
    qglEvalMesh2              := logEvalMesh2                 ;
    qglEvalPoint1             := logEvalPoint1                ;
    qglEvalPoint2             := logEvalPoint2                ;
    qglFeedbackBuffer         := logFeedbackBuffer            ;
    qglFinish                 := logFinish                    ;
    qglFlush                  := logFlush                     ;
    qglFogf                   := logFogf                      ;
    qglFogfv                  := logFogfv                     ;
    qglFogi                   := logFogi                      ;
    qglFogiv                  := logFogiv                     ;
    qglFrontFace              := logFrontFace                 ;
    qglFrustum                := logFrustum                   ;
    qglGenLists               := logGenLists                  ;
    qglGenTextures            := logGenTextures               ;
    qglGetBooleanv            := logGetBooleanv               ;
    qglGetClipPlane           := logGetClipPlane              ;
    qglGetDoublev             := logGetDoublev                ;
    qglGetError               := logGetError                  ;
    qglGetFloatv              := logGetFloatv                 ;
    qglGetIntegerv            := logGetIntegerv               ;
    qglGetLightfv             := logGetLightfv                ;
    qglGetLightiv             := logGetLightiv                ;
    qglGetMapdv               := logGetMapdv                  ;
    qglGetMapfv               := logGetMapfv                  ;
    qglGetMapiv               := logGetMapiv                  ;
    qglGetMaterialfv          := logGetMaterialfv             ;
    qglGetMaterialiv          := logGetMaterialiv             ;
    qglGetPixelMapfv          := logGetPixelMapfv             ;
    qglGetPixelMapuiv         := logGetPixelMapuiv            ;
    qglGetPixelMapusv         := logGetPixelMapusv            ;
    qglGetPointerv            := logGetPointerv               ;
    qglGetPolygonStipple      := logGetPolygonStipple         ;
    qglGetString              := logGetString                 ;
    qglGetTexEnvfv            := logGetTexEnvfv               ;
    qglGetTexEnviv            := logGetTexEnviv               ;
    qglGetTexGendv            := logGetTexGendv               ;
    qglGetTexGenfv            := logGetTexGenfv               ;
    qglGetTexGeniv            := logGetTexGeniv               ;
    qglGetTexImage            := logGetTexImage               ;
    qglGetTexLevelParameterfv := logGetTexLevelParameterfv    ;
    qglGetTexLevelParameteriv := logGetTexLevelParameteriv    ;
    qglGetTexParameterfv      := logGetTexParameterfv         ;
    qglGetTexParameteriv      := logGetTexParameteriv         ;
    qglHint                   := logHint                      ;
    qglIndexMask              := logIndexMask                 ;
    qglIndexPointer           := logIndexPointer              ;
    qglIndexd                 := logIndexd                    ;
    qglIndexdv                := logIndexdv                   ;
    qglIndexf                 := logIndexf                    ;
    qglIndexfv                := logIndexfv                   ;
    qglIndexi                 := logIndexi                    ;
    qglIndexiv                := logIndexiv                   ;
    qglIndexs                 := logIndexs                    ;
    qglIndexsv                := logIndexsv                   ;
    qglIndexub                := logIndexub                   ;
    qglIndexubv               := logIndexubv                  ;
    qglInitNames              := logInitNames                 ;
    qglInterleavedArrays      := logInterleavedArrays         ;
    qglIsEnabled              := logIsEnabled                 ;
    qglIsList                 := logIsList                    ;
    qglIsTexture              := logIsTexture                 ;
    qglLightModelf            := logLightModelf               ;
    qglLightModelfv           := logLightModelfv              ;
    qglLightModeli            := logLightModeli               ;
    qglLightModeliv           := logLightModeliv              ;
    qglLightf                 := logLightf                    ;
    qglLightfv                := logLightfv                   ;
    qglLighti                 := logLighti                    ;
    qglLightiv                := logLightiv                   ;
    qglLineStipple            := logLineStipple               ;
    qglLineWidth              := logLineWidth                 ;
    qglListBase               := logListBase                  ;
    qglLoadIdentity           := logLoadIdentity              ;
    qglLoadMatrixd            := logLoadMatrixd               ;
    qglLoadMatrixf            := logLoadMatrixf               ;
    qglLoadName               := logLoadName                  ;
    qglLogicOp                := logLogicOp                   ;
    qglMap1d                  := logMap1d                     ;
    qglMap1f                  := logMap1f                     ;
    qglMap2d                  := logMap2d                     ;
    qglMap2f                  := logMap2f                     ;
    qglMapGrid1d              := logMapGrid1d                 ;
    qglMapGrid1f              := logMapGrid1f                 ;
    qglMapGrid2d              := logMapGrid2d                 ;
    qglMapGrid2f              := logMapGrid2f                 ;
    qglMaterialf              := logMaterialf                 ;
    qglMaterialfv             := logMaterialfv                ;
    qglMateriali              := logMateriali                 ;
    qglMaterialiv             := logMaterialiv                ;
    qglMatrixMode             := logMatrixMode                ;
    qglMultMatrixd            := logMultMatrixd               ;
    qglMultMatrixf            := logMultMatrixf               ;
    qglNewList                := logNewList                   ;
    qglNormal3b               := logNormal3b                  ;
    qglNormal3bv              := logNormal3bv                 ;
    qglNormal3d               := logNormal3d                  ;
    qglNormal3dv              := logNormal3dv                 ;
    qglNormal3f               := logNormal3f                  ;
    qglNormal3fv              := logNormal3fv                 ;
    qglNormal3i               := logNormal3i                  ;
    qglNormal3iv              := logNormal3iv                 ;
    qglNormal3s               := logNormal3s                  ;
    qglNormal3sv              := logNormal3sv                 ;
    qglNormalPointer          := logNormalPointer             ;
    qglOrtho                  := logOrtho                     ;
    qglPassThrough            := logPassThrough               ;
    qglPixelMapfv             := logPixelMapfv                ;
    qglPixelMapuiv            := logPixelMapuiv               ;
    qglPixelMapusv            := logPixelMapusv               ;
    qglPixelStoref            := logPixelStoref               ;
    qglPixelStorei            := logPixelStorei               ;
    qglPixelTransferf         := logPixelTransferf            ;
    qglPixelTransferi         := logPixelTransferi            ;
    qglPixelZoom              := logPixelZoom                 ;
    qglPointSize              := logPointSize                 ;
    qglPolygonMode            := logPolygonMode               ;
    qglPolygonOffset          := logPolygonOffset             ;
    qglPolygonStipple         := logPolygonStipple            ;
    qglPopAttrib              := logPopAttrib                 ;
    qglPopClientAttrib        := logPopClientAttrib           ;
    qglPopMatrix              := logPopMatrix                 ;
    qglPopName                := logPopName                   ;
    qglPrioritizeTextures     := logPrioritizeTextures        ;
    qglPushAttrib             := logPushAttrib                ;
    qglPushClientAttrib       := logPushClientAttrib          ;
    qglPushMatrix             := logPushMatrix                ;
    qglPushName               := logPushName                  ;
    qglRasterPos2d            := logRasterPos2d               ;
    qglRasterPos2dv           := logRasterPos2dv              ;
    qglRasterPos2f            := logRasterPos2f               ;
    qglRasterPos2fv           := logRasterPos2fv              ;
    qglRasterPos2i            := logRasterPos2i               ;
    qglRasterPos2iv           := logRasterPos2iv              ;
    qglRasterPos2s            := logRasterPos2s               ;
    qglRasterPos2sv           := logRasterPos2sv              ;
    qglRasterPos3d            := logRasterPos3d               ;
    qglRasterPos3dv           := logRasterPos3dv              ;
    qglRasterPos3f            := logRasterPos3f               ;
    qglRasterPos3fv           := logRasterPos3fv              ;
    qglRasterPos3i            := logRasterPos3i               ;
    qglRasterPos3iv           := logRasterPos3iv              ;
    qglRasterPos3s            := logRasterPos3s               ;
    qglRasterPos3sv           := logRasterPos3sv              ;
    qglRasterPos4d            := logRasterPos4d               ;
    qglRasterPos4dv           := logRasterPos4dv              ;
    qglRasterPos4f            := logRasterPos4f               ;
    qglRasterPos4fv           := logRasterPos4fv              ;
    qglRasterPos4i            := logRasterPos4i               ;
    qglRasterPos4iv           := logRasterPos4iv              ;
    qglRasterPos4s            := logRasterPos4s               ;
    qglRasterPos4sv           := logRasterPos4sv              ;
    qglReadBuffer             := logReadBuffer                ;
    qglReadPixels             := logReadPixels                ;
    qglRectd                  := logRectd                     ;
    qglRectdv                 := logRectdv                    ;
    qglRectf                  := logRectf                     ;
    qglRectfv                 := logRectfv                    ;
    qglRecti                  := logRecti                     ;
    qglRectiv                 := logRectiv                    ;
    qglRects                  := logRects                     ;
    qglRectsv                 := logRectsv                    ;
    qglRenderMode             := logRenderMode                ;
    qglRotated                := logRotated                   ;
    qglRotatef                := logRotatef                   ;
    qglScaled                 := logScaled                    ;
    qglScalef                 := logScalef                    ;
    qglScissor                := logScissor                   ;
    qglSelectBuffer           := logSelectBuffer              ;
    qglShadeModel             := logShadeModel                ;
    qglStencilFunc            := logStencilFunc               ;
    qglStencilMask            := logStencilMask               ;
    qglStencilOp              := logStencilOp                 ;
    qglTexCoord1d             := logTexCoord1d                ;
    qglTexCoord1dv            := logTexCoord1dv               ;
    qglTexCoord1f             := logTexCoord1f                ;
    qglTexCoord1fv            := logTexCoord1fv               ;
    qglTexCoord1i             := logTexCoord1i                ;
    qglTexCoord1iv            := logTexCoord1iv               ;
    qglTexCoord1s             := logTexCoord1s                ;
    qglTexCoord1sv            := logTexCoord1sv               ;
    qglTexCoord2d             := logTexCoord2d                ;
    qglTexCoord2dv            := logTexCoord2dv               ;
    qglTexCoord2f             := logTexCoord2f                ;
    qglTexCoord2fv            := logTexCoord2fv               ;
    qglTexCoord2i             := logTexCoord2i                ;
    qglTexCoord2iv            := logTexCoord2iv               ;
    qglTexCoord2s             := logTexCoord2s                ;
    qglTexCoord2sv            := logTexCoord2sv               ;
    qglTexCoord3d             := logTexCoord3d                ;
    qglTexCoord3dv            := logTexCoord3dv               ;
    qglTexCoord3f             := logTexCoord3f                ;
    qglTexCoord3fv            := logTexCoord3fv               ;
    qglTexCoord3i             := logTexCoord3i                ;
    qglTexCoord3iv            := logTexCoord3iv               ;
    qglTexCoord3s             := logTexCoord3s                ;
    qglTexCoord3sv            := logTexCoord3sv               ;
    qglTexCoord4d             := logTexCoord4d                ;
    qglTexCoord4dv            := logTexCoord4dv               ;
    qglTexCoord4f             := logTexCoord4f                ;
    qglTexCoord4fv            := logTexCoord4fv               ;
    qglTexCoord4i             := logTexCoord4i                ;
    qglTexCoord4iv            := logTexCoord4iv               ;
    qglTexCoord4s             := logTexCoord4s                ;
    qglTexCoord4sv            := logTexCoord4sv               ;
    qglTexCoordPointer        := logTexCoordPointer           ;
    qglTexEnvf                := logTexEnvf                   ;
    qglTexEnvfv               := logTexEnvfv                  ;
    qglTexEnvi                := logTexEnvi                   ;
    qglTexEnviv               := logTexEnviv                  ;
    qglTexGend                := logTexGend                   ;
    qglTexGendv               := logTexGendv                  ;
    qglTexGenf                := logTexGenf                   ;
    qglTexGenfv               := logTexGenfv                  ;
    qglTexGeni                := logTexGeni                   ;
    qglTexGeniv               := logTexGeniv                  ;
    qglTexImage1D             := logTexImage1D                ;
    qglTexImage2D             := logTexImage2D                ;
    qglTexParameterf          := logTexParameterf             ;
    qglTexParameterfv         := logTexParameterfv            ;
    qglTexParameteri          := logTexParameteri             ;
    qglTexParameteriv         := logTexParameteriv            ;
    qglTexSubImage1D          := logTexSubImage1D             ;
    qglTexSubImage2D          := logTexSubImage2D             ;
    qglTranslated             := logTranslated                ;
    qglTranslatef             := logTranslatef                ;
    qglVertex2d               := logVertex2d                  ;
    qglVertex2dv              := logVertex2dv                 ;
    qglVertex2f               := logVertex2f                  ;
    qglVertex2fv              := logVertex2fv                 ;
    qglVertex2i               := logVertex2i                  ;
    qglVertex2iv              := logVertex2iv                 ;
    qglVertex2s               := logVertex2s                  ;
    qglVertex2sv              := logVertex2sv                 ;
    qglVertex3d               := logVertex3d                  ;
    qglVertex3dv              := logVertex3dv                 ;
    qglVertex3f               := logVertex3f                  ;
    qglVertex3fv              := logVertex3fv                 ;
    qglVertex3i               := logVertex3i                  ;
    qglVertex3iv              := logVertex3iv                 ;
    qglVertex3s               := logVertex3s                  ;
    qglVertex3sv              := logVertex3sv                 ;
    qglVertex4d               := logVertex4d                  ;
    qglVertex4dv              := logVertex4dv                 ;
    qglVertex4f               := logVertex4f                  ;
    qglVertex4fv              := logVertex4fv                 ;
    qglVertex4i               := logVertex4i                  ;
    qglVertex4iv              := logVertex4iv                 ;
    qglVertex4s               := logVertex4s                  ;
    qglVertex4sv              := logVertex4sv                 ;
    qglVertexPointer          := logVertexPointer             ;
    qglViewport               := logViewport                  ;
  end
  else begin
    qglAccum                  := dllAccum;
    qglAlphaFunc              := dllAlphaFunc;
    qglAreTexturesResident    := dllAreTexturesResident;
    qglArrayElement           := dllArrayElement;
    qglBegin                  := dllBegin;
    qglBindTexture            := dllBindTexture;
    qglBitmap                 := dllBitmap;
    qglBlendFunc              := dllBlendFunc;
    qglCallList               := dllCallList;
    qglCallLists              := dllCallLists;
    qglClear                  := dllClear;
    qglClearAccum             := dllClearAccum;
    qglClearColor             := dllClearColor;
    qglClearDepth             := dllClearDepth;
    qglClearIndex             := dllClearIndex;
    qglClearStencil           := dllClearStencil;
    qglClipPlane              := dllClipPlane;
    qglColor3b                := dllColor3b;
    qglColor3bv               := dllColor3bv;
    qglColor3d                := dllColor3d;
    qglColor3dv               := dllColor3dv;
    qglColor3f                := dllColor3f;
    qglColor3fv               := dllColor3fv;
    qglColor3i                := dllColor3i;
    qglColor3iv               := dllColor3iv;
    qglColor3s                := dllColor3s;
    qglColor3sv               := dllColor3sv;
    qglColor3ub               := dllColor3ub;
    qglColor3ubv              := dllColor3ubv;
    qglColor3ui               := dllColor3ui;
    qglColor3uiv              := dllColor3uiv;
    qglColor3us               := dllColor3us;
    qglColor3usv              := dllColor3usv;
    qglColor4b                := dllColor4b;
    qglColor4bv               := dllColor4bv;
    qglColor4d                := dllColor4d;
    qglColor4dv               := dllColor4dv;
    qglColor4f                := dllColor4f;
    qglColor4fv               := dllColor4fv;
    qglColor4i                := dllColor4i;
    qglColor4iv               := dllColor4iv;
    qglColor4s                := dllColor4s;
    qglColor4sv               := dllColor4sv;
    qglColor4ub               := dllColor4ub;
    qglColor4ubv              := dllColor4ubv;
    qglColor4ui               := dllColor4ui;
    qglColor4uiv              := dllColor4uiv;
    qglColor4us               := dllColor4us;
    qglColor4usv              := dllColor4usv;
    qglColorMask              := dllColorMask;
    qglColorMaterial          := dllColorMaterial;
    qglColorPointer           := dllColorPointer;
    qglCopyPixels             := dllCopyPixels;
    qglCopyTexImage1D         := dllCopyTexImage1D;
    qglCopyTexImage2D         := dllCopyTexImage2D;
    qglCopyTexSubImage1D      := dllCopyTexSubImage1D;
    qglCopyTexSubImage2D      := dllCopyTexSubImage2D;
    qglCullFace               := dllCullFace;
    qglDeleteLists            := dllDeleteLists ;
    qglDeleteTextures         := dllDeleteTextures ;
    qglDepthFunc              := dllDepthFunc ;
    qglDepthMask              := dllDepthMask ;
    qglDepthRange             := dllDepthRange ;
    qglDisable                := dllDisable ;
    qglDisableClientState     := dllDisableClientState ;
    qglDrawArrays             := dllDrawArrays ;
    qglDrawBuffer             := dllDrawBuffer ;
    qglDrawElements           := dllDrawElements ;
    qglDrawPixels             := dllDrawPixels ;
    qglEdgeFlag               := dllEdgeFlag ;
    qglEdgeFlagPointer        := dllEdgeFlagPointer ;
    qglEdgeFlagv              := dllEdgeFlagv ;
    qglEnable                 := dllEnable                    ;
    qglEnableClientState      := dllEnableClientState         ;
    qglEnd                    := dllEnd                       ;
    qglEndList                := dllEndList                   ;
    qglEvalCoord1d         := dllEvalCoord1d            ;
    qglEvalCoord1dv           := dllEvalCoord1dv              ;
    qglEvalCoord1f            := dllEvalCoord1f               ;
    qglEvalCoord1fv           := dllEvalCoord1fv              ;
    qglEvalCoord2d            := dllEvalCoord2d               ;
    qglEvalCoord2dv           := dllEvalCoord2dv              ;
    qglEvalCoord2f            := dllEvalCoord2f               ;
    qglEvalCoord2fv           := dllEvalCoord2fv              ;
    qglEvalMesh1              := dllEvalMesh1                 ;
    qglEvalMesh2              := dllEvalMesh2                 ;
    qglEvalPoint1             := dllEvalPoint1                ;
    qglEvalPoint2             := dllEvalPoint2                ;
    qglFeedbackBuffer         := dllFeedbackBuffer            ;
    qglFinish                 := dllFinish                    ;
    qglFlush                  := dllFlush                     ;
    qglFogf                   := dllFogf                      ;
    qglFogfv                  := dllFogfv                     ;
    qglFogi                   := dllFogi                      ;
    qglFogiv                  := dllFogiv                     ;
    qglFrontFace              := dllFrontFace                 ;
    qglFrustum                := dllFrustum                   ;
    qglGenLists               := dllGenLists                  ;
    qglGenTextures            := dllGenTextures               ;
    qglGetBooleanv            := dllGetBooleanv               ;
    qglGetClipPlane           := dllGetClipPlane              ;
    qglGetDoublev             := dllGetDoublev                ;
    qglGetError               := dllGetError                  ;
    qglGetFloatv              := dllGetFloatv                 ;
    qglGetIntegerv            := dllGetIntegerv               ;
    qglGetLightfv             := dllGetLightfv                ;
    qglGetLightiv             := dllGetLightiv                ;
    qglGetMapdv               := dllGetMapdv                  ;
    qglGetMapfv               := dllGetMapfv                  ;
    qglGetMapiv               := dllGetMapiv                  ;
    qglGetMaterialfv          := dllGetMaterialfv             ;
    qglGetMaterialiv          := dllGetMaterialiv             ;
    qglGetPixelMapfv          := dllGetPixelMapfv             ;
    qglGetPixelMapuiv         := dllGetPixelMapuiv            ;
    qglGetPixelMapusv         := dllGetPixelMapusv            ;
    qglGetPointerv            := dllGetPointerv               ;
    qglGetPolygonStipple      := dllGetPolygonStipple         ;
    qglGetString              := dllGetString                 ;
    qglGetTexEnvfv            := dllGetTexEnvfv               ;
    qglGetTexEnviv            := dllGetTexEnviv               ;
    qglGetTexGendv            := dllGetTexGendv               ;
    qglGetTexGenfv            := dllGetTexGenfv               ;
    qglGetTexGeniv            := dllGetTexGeniv               ;
    qglGetTexImage            := dllGetTexImage               ;
    qglGetTexLevelParameterfv := dllGetTexLevelParameterfv    ;
    qglGetTexLevelParameteriv := dllGetTexLevelParameteriv    ;
    qglGetTexParameterfv      := dllGetTexParameterfv         ;
    qglGetTexParameteriv      := dllGetTexParameteriv         ;
    qglHint                   := dllHint                      ;
    qglIndexMask              := dllIndexMask                 ;
    qglIndexPointer           := dllIndexPointer              ;
    qglIndexd                 := dllIndexd                    ;
    qglIndexdv                := dllIndexdv                   ;
    qglIndexf                 := dllIndexf                    ;
    qglIndexfv                := dllIndexfv                   ;
    qglIndexi                 := dllIndexi                    ;
    qglIndexiv                := dllIndexiv                   ;
    qglIndexs                 := dllIndexs                    ;
    qglIndexsv                := dllIndexsv                   ;
    qglIndexub                := dllIndexub                   ;
    qglIndexubv               := dllIndexubv                  ;
    qglInitNames              := dllInitNames                 ;
    qglInterleavedArrays      := dllInterleavedArrays         ;
    qglIsEnabled              := dllIsEnabled                 ;
    qglIsList                 := dllIsList                    ;
    qglIsTexture              := dllIsTexture                 ;
    qglLightModelf            := dllLightModelf               ;
    qglLightModelfv           := dllLightModelfv              ;
    qglLightModeli            := dllLightModeli               ;
    qglLightModeliv           := dllLightModeliv              ;
    qglLightf                 := dllLightf                    ;
    qglLightfv                := dllLightfv                   ;
    qglLighti                 := dllLighti                    ;
    qglLightiv                := dllLightiv                   ;
    qglLineStipple            := dllLineStipple               ;
    qglLineWidth              := dllLineWidth                 ;
    qglListBase               := dllListBase                  ;
    qglLoadIdentity           := dllLoadIdentity              ;
    qglLoadMatrixd            := dllLoadMatrixd               ;
    qglLoadMatrixf            := dllLoadMatrixf               ;
    qglLoadName               := dllLoadName                  ;
    qglLogicOp                := dllLogicOp                   ;
    qglMap1d                  := dllMap1d                     ;
    qglMap1f                  := dllMap1f                     ;
    qglMap2d                  := dllMap2d                     ;
    qglMap2f                  := dllMap2f                     ;
    qglMapGrid1d              := dllMapGrid1d                 ;
    qglMapGrid1f              := dllMapGrid1f                 ;
    qglMapGrid2d              := dllMapGrid2d                 ;
    qglMapGrid2f              := dllMapGrid2f                 ;
    qglMaterialf              := dllMaterialf                 ;
    qglMaterialfv             := dllMaterialfv                ;
    qglMateriali              := dllMateriali                 ;
    qglMaterialiv             := dllMaterialiv                ;
    qglMatrixMode             := dllMatrixMode                ;
    qglMultMatrixd            := dllMultMatrixd               ;
    qglMultMatrixf            := dllMultMatrixf               ;
    qglNewList                := dllNewList                   ;
    qglNormal3b               := dllNormal3b                  ;
    qglNormal3bv              := dllNormal3bv                 ;
    qglNormal3d               := dllNormal3d                  ;
    qglNormal3dv              := dllNormal3dv                 ;
    qglNormal3f               := dllNormal3f                  ;
    qglNormal3fv              := dllNormal3fv                 ;
    qglNormal3i               := dllNormal3i                  ;
    qglNormal3iv              := dllNormal3iv                 ;
    qglNormal3s               := dllNormal3s                  ;
    qglNormal3sv              := dllNormal3sv                 ;
    qglNormalPointer          := dllNormalPointer             ;
    qglOrtho                  := dllOrtho                     ;
    qglPassThrough            := dllPassThrough               ;
    qglPixelMapfv             := dllPixelMapfv                ;
    qglPixelMapuiv            := dllPixelMapuiv               ;
    qglPixelMapusv            := dllPixelMapusv               ;
    qglPixelStoref            := dllPixelStoref               ;
    qglPixelStorei            := dllPixelStorei               ;
    qglPixelTransferf         := dllPixelTransferf            ;
    qglPixelTransferi         := dllPixelTransferi            ;
    qglPixelZoom              := dllPixelZoom                 ;
    qglPointSize              := dllPointSize                 ;
    qglPolygonMode            := dllPolygonMode               ;
    qglPolygonOffset          := dllPolygonOffset             ;
    qglPolygonStipple         := dllPolygonStipple            ;
    qglPopAttrib              := dllPopAttrib                 ;
    qglPopClientAttrib        := dllPopClientAttrib           ;
    qglPopMatrix              := dllPopMatrix                 ;
    qglPopName                := dllPopName                   ;
    qglPrioritizeTextures     := dllPrioritizeTextures        ;
    qglPushAttrib             := dllPushAttrib                ;
    qglPushClientAttrib       := dllPushClientAttrib          ;
    qglPushMatrix             := dllPushMatrix                ;
    qglPushName               := dllPushName                  ;
    qglRasterPos2d            := dllRasterPos2d               ;
    qglRasterPos2dv           := dllRasterPos2dv              ;
    qglRasterPos2f            := dllRasterPos2f               ;
    qglRasterPos2fv           := dllRasterPos2fv              ;
    qglRasterPos2i            := dllRasterPos2i               ;
    qglRasterPos2iv           := dllRasterPos2iv              ;
    qglRasterPos2s            := dllRasterPos2s               ;
    qglRasterPos2sv           := dllRasterPos2sv              ;
    qglRasterPos3d            := dllRasterPos3d               ;
    qglRasterPos3dv           := dllRasterPos3dv              ;
    qglRasterPos3f            := dllRasterPos3f               ;
    qglRasterPos3fv           := dllRasterPos3fv              ;
    qglRasterPos3i            := dllRasterPos3i               ;
    qglRasterPos3iv           := dllRasterPos3iv              ;
    qglRasterPos3s            := dllRasterPos3s               ;
    qglRasterPos3sv           := dllRasterPos3sv              ;
    qglRasterPos4d            := dllRasterPos4d               ;
    qglRasterPos4dv           := dllRasterPos4dv              ;
    qglRasterPos4f            := dllRasterPos4f               ;
    qglRasterPos4fv           := dllRasterPos4fv              ;
    qglRasterPos4i            := dllRasterPos4i               ;
    qglRasterPos4iv           := dllRasterPos4iv              ;
    qglRasterPos4s            := dllRasterPos4s               ;
    qglRasterPos4sv           := dllRasterPos4sv              ;
    qglReadBuffer             := dllReadBuffer                ;
    qglReadPixels             := dllReadPixels                ;
    qglRectd                  := dllRectd                     ;
    qglRectdv                 := dllRectdv                    ;
    qglRectf                  := dllRectf                     ;
    qglRectfv                 := dllRectfv                    ;
    qglRecti                  := dllRecti                     ;
    qglRectiv                 := dllRectiv                    ;
    qglRects                  := dllRects                     ;
    qglRectsv                 := dllRectsv                    ;
    qglRenderMode             := dllRenderMode                ;
    qglRotated                := dllRotated                   ;
    qglRotatef                := dllRotatef                   ;
    qglScaled                 := dllScaled                    ;
    qglScalef                 := dllScalef                    ;
    qglScissor                := dllScissor                   ;
    qglSelectBuffer           := dllSelectBuffer              ;
    qglShadeModel             := dllShadeModel                ;
    qglStencilFunc            := dllStencilFunc               ;
    qglStencilMask            := dllStencilMask               ;
    qglStencilOp              := dllStencilOp                 ;
    qglTexCoord1d             := dllTexCoord1d                ;
    qglTexCoord1dv            := dllTexCoord1dv               ;
    qglTexCoord1f             := dllTexCoord1f                ;
    qglTexCoord1fv            := dllTexCoord1fv               ;
    qglTexCoord1i             := dllTexCoord1i                ;
    qglTexCoord1iv            := dllTexCoord1iv               ;
    qglTexCoord1s             := dllTexCoord1s                ;
    qglTexCoord1sv            := dllTexCoord1sv               ;
    qglTexCoord2d             := dllTexCoord2d                ;
    qglTexCoord2dv            := dllTexCoord2dv               ;
    qglTexCoord2f             := dllTexCoord2f                ;
    qglTexCoord2fv            := dllTexCoord2fv               ;
    qglTexCoord2i             := dllTexCoord2i                ;
    qglTexCoord2iv            := dllTexCoord2iv               ;
    qglTexCoord2s             := dllTexCoord2s                ;
    qglTexCoord2sv            := dllTexCoord2sv               ;
    qglTexCoord3d             := dllTexCoord3d                ;
    qglTexCoord3dv            := dllTexCoord3dv               ;
    qglTexCoord3f             := dllTexCoord3f                ;
    qglTexCoord3fv            := dllTexCoord3fv               ;
    qglTexCoord3i             := dllTexCoord3i                ;
    qglTexCoord3iv            := dllTexCoord3iv               ;
    qglTexCoord3s             := dllTexCoord3s                ;
    qglTexCoord3sv            := dllTexCoord3sv               ;
    qglTexCoord4d             := dllTexCoord4d                ;
    qglTexCoord4dv            := dllTexCoord4dv               ;
    qglTexCoord4f             := dllTexCoord4f                ;
    qglTexCoord4fv            := dllTexCoord4fv               ;
    qglTexCoord4i             := dllTexCoord4i                ;
    qglTexCoord4iv            := dllTexCoord4iv               ;
    qglTexCoord4s             := dllTexCoord4s                ;
    qglTexCoord4sv            := dllTexCoord4sv               ;
    qglTexCoordPointer        := dllTexCoordPointer           ;
    qglTexEnvf                := dllTexEnvf                   ;
    qglTexEnvfv               := dllTexEnvfv                  ;
    qglTexEnvi                := dllTexEnvi                   ;
    qglTexEnviv               := dllTexEnviv                  ;
    qglTexGend                := dllTexGend                   ;
    qglTexGendv               := dllTexGendv                  ;
    qglTexGenf                := dllTexGenf                   ;
    qglTexGenfv               := dllTexGenfv                  ;
    qglTexGeni                := dllTexGeni                   ;
    qglTexGeniv               := dllTexGeniv                  ;
    qglTexImage1D             := dllTexImage1D                ;
    qglTexImage2D             := dllTexImage2D                ;
    qglTexParameterf          := dllTexParameterf             ;
    qglTexParameterfv         := dllTexParameterfv            ;
    qglTexParameteri          := dllTexParameteri             ;
    qglTexParameteriv         := dllTexParameteriv            ;
    qglTexSubImage1D          := dllTexSubImage1D             ;
    qglTexSubImage2D          := dllTexSubImage2D             ;
    qglTranslated             := dllTranslated                ;
    qglTranslatef             := dllTranslatef                ;
    qglVertex2d               := dllVertex2d                  ;
    qglVertex2dv              := dllVertex2dv                 ;
    qglVertex2f               := dllVertex2f                  ;
    qglVertex2fv              := dllVertex2fv                 ;
    qglVertex2i               := dllVertex2i                  ;
    qglVertex2iv              := dllVertex2iv                 ;
    qglVertex2s               := dllVertex2s                  ;
    qglVertex2sv              := dllVertex2sv                 ;
    qglVertex3d               := dllVertex3d                  ;
    qglVertex3dv              := dllVertex3dv                 ;
    qglVertex3f               := dllVertex3f                  ;
    qglVertex3fv              := dllVertex3fv                 ;
    qglVertex3i               := dllVertex3i                  ;
    qglVertex3iv              := dllVertex3iv                 ;
    qglVertex3s               := dllVertex3s                  ;
    qglVertex3sv              := dllVertex3sv                 ;
    qglVertex4d               := dllVertex4d                  ;
    qglVertex4dv              := dllVertex4dv                 ;
    qglVertex4f               := dllVertex4f                  ;
    qglVertex4fv              := dllVertex4fv                 ;
    qglVertex4i               := dllVertex4i                  ;
    qglVertex4iv              := dllVertex4iv                 ;
    qglVertex4s               := dllVertex4s                  ;
    qglVertex4sv              := dllVertex4sv                 ;
    qglVertexPointer          := dllVertexPointer             ;
    qglViewport               := dllViewport                  ;
  end;//else
end;//procedure

procedure GLimp_LogNewFrame;
begin
//  fprintf (glw_state.log_fp, '*** R_BeginFrame ***'#10);
  WriteLn (glw_state.log_fp, '*** R_BeginFrame ***'#10);
end;//procedure

end.
