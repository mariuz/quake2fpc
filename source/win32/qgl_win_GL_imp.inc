// This text from GL.pas - 336 glProcedures
//   - line 7-342:    glXxx --> dllXxx
//   - line 360-2089: glXxx --> logXxx

var
  //336 dll OpenGL procedures - It's ONLY for IMPLEMENTATION unit-section
  dllAccum: procedure(op: TGLenum; value: TGLfloat); stdcall;
  dllAlphaFunc: procedure(func: TGLenum; ref: TGLclampf); stdcall;
  dllAreTexturesResident: function (n: TGLsizei; textures: PGLuint; residences: PGLboolean): TGLboolean; stdcall;
  dllArrayElement: procedure(i: TGLint); stdcall;
  dllBegin: procedure(mode: TGLenum); stdcall;
  dllBindTexture: procedure(target: TGLenum; texture: TGLuint); stdcall;
  dllBitmap: procedure (width, height: TGLsizei; xorig, yorig: TGLfloat; xmove, ymove: TGLfloat; bitmap: PGLubyte); stdcall;
  dllBlendFunc: procedure(sfactor, dfactor: TGLenum); stdcall;
  dllCallList: procedure(list: TGLuint); stdcall;
  dllCallLists: procedure(n: TGLsizei; atype: TGLenum; lists: Pointer); stdcall;
  dllClear: procedure(mask: TGLbitfield); stdcall;
  dllClearAccum: procedure(red, green, blue, alpha: TGLfloat); stdcall;
  dllClearColor: procedure(red, green, blue, alpha: TGLclampf); stdcall;
  dllClearDepth: procedure(depth: TGLclampd); stdcall;
  dllClearIndex: procedure(c: TGLfloat); stdcall;
  dllClearStencil: procedure(s: TGLint); stdcall;
  dllClipPlane: procedure(plane: TGLenum; equation: PGLdouble); stdcall;
  dllColor3b: procedure(red, green, blue: TGLbyte); stdcall;
  dllColor3bv: procedure(v: PGLbyte); stdcall;
  dllColor3d: procedure(red, green, blue: TGLdouble); stdcall;
  dllColor3dv: procedure(v: PGLdouble); stdcall;
  dllColor3f: procedure(red, green, blue: TGLfloat); stdcall;
  dllColor3fv: procedure(v: PGLfloat); stdcall;
  dllColor3i: procedure(red, green, blue: TGLint); stdcall;
  dllColor3iv: procedure(v: PGLint); stdcall;
  dllColor3s: procedure(red, green, blue: TGLshort); stdcall;
  dllColor3sv: procedure(v: PGLshort); stdcall;
  dllColor3ub: procedure(red, green, blue: TGLubyte); stdcall;
  dllColor3ubv: procedure(v: PGLubyte); stdcall;
  dllColor3ui: procedure(red, green, blue: TGLuint); stdcall;
  dllColor3uiv: procedure(v: PGLuint); stdcall;
  dllColor3us: procedure(red, green, blue: TGLushort); stdcall;
  dllColor3usv: procedure(v: PGLushort); stdcall;
  dllColor4b: procedure(red, green, blue, alpha: TGLubyte); stdcall;
  dllColor4bv: procedure(v: PGLbyte); stdcall;
  dllColor4d: procedure(red, green, blue, alpha: TGLdouble); stdcall;
  dllColor4dv: procedure(v: PGLdouble); stdcall;
  dllColor4f: procedure(red, green, blue, alpha: TGLfloat); stdcall;
  dllColor4fv: procedure(v: PGLfloat); stdcall;
  dllColor4i: procedure(red, green, blue, alpha: TGLint); stdcall;
  dllColor4iv: procedure(v: PGLint); stdcall;
  dllColor4s: procedure(red, green, blue, alpha: TGLshort); stdcall;
  dllColor4sv: procedure(v: PGLshort); stdcall;
  dllColor4ub: procedure(red, green, blue, alpha: TGLubyte); stdcall;
  dllColor4ubv: procedure(v: PGLubyte); stdcall;
  dllColor4ui: procedure(red, green, blue, alpha: TGLuint); stdcall;
  dllColor4uiv: procedure(v: PGLuint); stdcall;
  dllColor4us: procedure(red, green, blue, alpha: TGLushort); stdcall;
  dllColor4usv: procedure(v: PGLushort); stdcall;
  dllColorMask: procedure(red, green, blue, alpha: TGLboolean); stdcall;
  dllColorMaterial: procedure(face, mode: TGLenum); stdcall;
  dllColorPointer: procedure(size: TGLint; atype: TGLenum; stride: TGLsizei; pointer: Pointer); stdcall;
  dllCopyPixels: procedure(x, y: TGLint; width, height: TGLsizei; atype: TGLenum); stdcall;
  dllCopyTexImage1D: procedure (target: TGLenum; level: TGLint; internalFormat: TGLenum; x, y: TGLint; width: TGLsizei; border: TGLint); stdcall;
  dllCopyTexImage2D: procedure(target: TGLenum; level: TGLint; internalFormat: TGLenum; x, y: TGLint; width, height: TGLsizei; border: TGLint); stdcall;
  dllCopyTexSubImage1D: procedure(target: TGLenum; level, xoffset, x, y: TGLint; width: TGLsizei); stdcall;
  dllCopyTexSubImage2D: procedure(target: TGLenum; level, xoffset, yoffset, x, y: TGLint; width, height: TGLsizei); stdcall;
  dllCullFace: procedure(mode: TGLenum); stdcall;
  dllDeleteLists: procedure(list: TGLuint; range: TGLsizei); stdcall;
  dllDeleteTextures: procedure(n: TGLsizei; textures: PGLuint); stdcall;
  dllDepthFunc: procedure(func: TGLenum); stdcall;
  dllDepthMask: procedure(flag: TGLboolean); stdcall;
  dllDepthRange: procedure(zNear, zFar: TGLclampd); stdcall;
  dllDisable: procedure(cap: TGLenum); stdcall;
  dllDisableClientState: procedure(aarray: TGLenum); stdcall;
  dllDrawArrays: procedure(mode: TGLenum; first: TGLint; count: TGLsizei); stdcall;
  dllDrawBuffer: procedure(mode: TGLenum); stdcall;
  dllDrawElements: procedure(mode: TGLenum; count: TGLsizei; atype: TGLenum; indices: Pointer); stdcall;
  dllDrawPixels: procedure(width, height: TGLsizei; format, atype: TGLenum; pixels: Pointer); stdcall;
  dllEdgeFlag: procedure(flag: TGLboolean); stdcall;
  dllEdgeFlagPointer: procedure(stride: TGLsizei; pointer: Pointer); stdcall;
  dllEdgeFlagv: procedure(flag: PGLboolean); stdcall;
  dllEnable: procedure(cap: TGLenum); stdcall;
  dllEnableClientState: procedure(aarray: TGLenum); stdcall;
  dllEnd: procedure; stdcall;
  dllEndList: procedure; stdcall;
  dllEvalCoord1d: procedure(u: TGLdouble); stdcall;
  dllEvalCoord1dv: procedure(u: PGLdouble); stdcall;
  dllEvalCoord1f: procedure(u: TGLfloat); stdcall;
  dllEvalCoord1fv: procedure(u: PGLfloat); stdcall;
  dllEvalCoord2d: procedure(u, v: TGLdouble); stdcall;
  dllEvalCoord2dv: procedure(u: PGLdouble); stdcall;
  dllEvalCoord2f: procedure(u, v: TGLfloat); stdcall;
  dllEvalCoord2fv: procedure(u: PGLfloat); stdcall;
  dllEvalMesh1: procedure(mode: TGLenum; i1, i2: TGLint); stdcall;
  dllEvalMesh2: procedure(mode: TGLenum; i1, i2, j1, j2: TGLint); stdcall;
  dllEvalPoint1: procedure(i: TGLint); stdcall;
  dllEvalPoint2: procedure(i, j: TGLint); stdcall;
  dllFeedbackBuffer: procedure(size: TGLsizei; atype: TGLenum; buffer: PGLfloat); stdcall;
  dllFinish: procedure; stdcall;
  dllFlush: procedure; stdcall;
  dllFogf: procedure(pname: TGLenum; param: TGLfloat); stdcall;
  dllFogfv: procedure(pname: TGLenum; params: PGLfloat); stdcall;
  dllFogi: procedure(pname: TGLenum; param: TGLint); stdcall;
  dllFogiv: procedure(pname: TGLenum; params: PGLint); stdcall;
  dllFrontFace: procedure(mode: TGLenum); stdcall;
  dllFrustum: procedure(left, right, bottom, top, zNear, zFar: TGLdouble); stdcall;
  dllGenLists: function(range: TGLsizei): TGLuint; stdcall;
  dllGenTextures: procedure(n: TGLsizei; textures: PGLuint); stdcall;
  dllGetBooleanv: procedure(pname: TGLenum; params: PGLboolean); stdcall;
  dllGetClipPlane: procedure(plane: TGLenum; equation: PGLdouble); stdcall;
  dllGetDoublev: procedure(pname: TGLenum; params: PGLdouble); stdcall;
  dllGetError: function: TGLenum; stdcall;
  dllGetFloatv: procedure(pname: TGLenum; params: PGLfloat); stdcall;
  dllGetIntegerv: procedure(pname: TGLenum; params: PGLint); stdcall;
  dllGetLightfv: procedure(light, pname: TGLenum; params: PGLfloat); stdcall;
  dllGetLightiv: procedure(light, pname: TGLenum; params: PGLint); stdcall;
  dllGetMapdv: procedure(target, query: TGLenum; v: PGLdouble); stdcall;
  dllGetMapfv: procedure(target, query: TGLenum; v: PGLfloat); stdcall;
  dllGetMapiv: procedure(target, query: TGLenum; v: TGLint); stdcall;
  dllGetMaterialfv: procedure(face, pname: TGLenum; params: PGLfloat); stdcall;
  dllGetMaterialiv: procedure(face, pname: TGLenum; params: TGLint); stdcall;
  dllGetPixelMapfv: procedure(map: TGLenum; values: PGLfloat); stdcall;
  dllGetPixelMapuiv: procedure(map: TGLenum; values: PGLuint); stdcall;
  dllGetPixelMapusv: procedure(map: TGLenum; values: PGLushort); stdcall;
  dllGetPointerv: procedure(pname: TGLenum; params: Pointer); stdcall;
  dllGetPolygonStipple: procedure(mask: PGLubyte); stdcall;
  dllGetString: function(name: TGLenum): PGLubyte; stdcall;
  dllGetTexEnvfv: procedure(target, pname: TGLenum; params: PGLfloat); stdcall;
  dllGetTexEnviv: procedure(target, pname: TGLenum; params: PGLint); stdcall;
  dllGetTexGendv: procedure(coord, pname: TGLenum; params: PGLdouble); stdcall;
  dllGetTexGenfv: procedure(coord, pname: TGLenum; params: PGLfloat); stdcall;
  dllGetTexGeniv: procedure(coord, pname: TGLenum; params: PGLint); stdcall;
  dllGetTexImage: procedure(target: TGLenum; level: TGLint; format: TGLenum; atype: TGLenum; pixels: Pointer); stdcall;
  dllGetTexLevelParameterfv: procedure(target: TGLenum; level: TGLint; pname: TGLenum; params: Pointer); stdcall;
  dllGetTexLevelParameteriv: procedure(target: TGLenum; level: TGLint; pname: TGLenum; params: PGLint); stdcall;
  dllGetTexParameterfv: procedure(target, pname: TGLenum; params: PGLfloat); stdcall;
  dllGetTexParameteriv: procedure(target, pname: TGLenum; params: PGLint); stdcall;
  dllHint: procedure(target, mode: TGLenum); stdcall;
  dllIndexMask: procedure(mask: TGLuint); stdcall;
  dllIndexPointer: procedure(atype: TGLenum; stride: TGLsizei; pointer: Pointer); stdcall;
  dllIndexd: procedure(c: TGLdouble); stdcall;
  dllIndexdv: procedure(c: PGLdouble); stdcall;
  dllIndexf: procedure(c: TGLfloat); stdcall;
  dllIndexfv: procedure(c: PGLfloat); stdcall;
  dllIndexi: procedure(c: TGLint); stdcall;
  dllIndexiv: procedure(c: PGLint); stdcall;
  dllIndexs: procedure(c: TGLshort); stdcall;
  dllIndexsv: procedure(c: PGLshort); stdcall;
  dllIndexub: procedure(c: TGLubyte); stdcall;
  dllIndexubv: procedure(c: PGLubyte); stdcall;
  dllInitNames: procedure; stdcall;
  dllInterleavedArrays: procedure(format: TGLenum; stride: TGLsizei; pointer: Pointer); stdcall;
  dllIsEnabled: function(cap: TGLenum): TGLboolean; stdcall;
  dllIsList: function(list: TGLuint): TGLboolean; stdcall;
  dllIsTexture: function(texture: TGLuint): TGLboolean; stdcall;
  dllLightModelf: procedure(pname: TGLenum; param: TGLfloat); stdcall;
  dllLightModelfv: procedure(pname: TGLenum; params: PGLfloat); stdcall;
  dllLightModeli: procedure(pname: TGLenum; param: TGLint); stdcall;
  dllLightModeliv: procedure(pname: TGLenum; params: PGLint); stdcall;
  dllLightf: procedure(light, pname: TGLenum; param: TGLfloat); stdcall;
  dllLightfv: procedure(light, pname: TGLenum; params: PGLfloat); stdcall;
  dllLighti: procedure(light, pname: TGLenum; param: TGLint); stdcall;
  dllLightiv: procedure(light, pname: TGLenum; params: TGLint); stdcall;
  dllLineStipple: procedure(factor: TGLint; pattern: TGLushort); stdcall;
  dllLineWidth: procedure(width: TGLfloat); stdcall;
  dllListBase: procedure(base: TGLuint); stdcall;
  dllLoadIdentity: procedure; stdcall;
  dllLoadMatrixd: procedure(m: PGLdouble); stdcall;
  dllLoadMatrixf: procedure(m: PGLfloat); stdcall;
  dllLoadName: procedure(name: TGLuint); stdcall;
  dllLogicOp: procedure(opcode: TGLenum); stdcall;
  dllMap1d: procedure(target: TGLenum; u1, u2: TGLdouble; stride, order: TGLint; points: PGLdouble); stdcall;
  dllMap1f: procedure(target: TGLenum; u1, u2: TGLfloat; stride, order: TGLint; points: PGLfloat); stdcall;
  dllMap2d: procedure(target: TGLenum; u1, u2: TGLdouble; ustride, uorder: TGLint; v1, v2: TGLdouble; vstride, vorder: TGLint; points: PGLdouble); stdcall;
  dllMap2f: procedure(target: TGLenum; u1, u2: TGLfloat; ustride, uorder: TGLint; v1, v2: TGLfloat; vstride, vorder: TGLint; points: PGLfloat); stdcall;
  dllMapGrid1d: procedure(un: TGLint; u1, u2: TGLdouble); stdcall;
  dllMapGrid1f: procedure(un: TGLint; u1, u2: TGLfloat); stdcall;
  dllMapGrid2d: procedure(un: TGLint; u1, u2: TGLdouble; vn: TGLint; v1, v2: TGLdouble); stdcall;
  dllMapGrid2f: procedure(un: TGLint; u1, u2: TGLfloat; vn: TGLint; v1, v2: TGLfloat); stdcall;
  dllMaterialf: procedure(face, pname: TGLenum; param: TGLfloat); stdcall;
  dllMaterialfv: procedure(face, pname: TGLenum; params: PGLfloat); stdcall;
  dllMateriali: procedure(face, pname: TGLenum; param: TGLint); stdcall;
  dllMaterialiv: procedure(face, pname: TGLenum; params: PGLint); stdcall;
  dllMatrixMode: procedure(mode: TGLenum); stdcall;
  dllMultMatrixd: procedure(m: PGLdouble); stdcall;
  dllMultMatrixf: procedure(m: PGLfloat); stdcall;
  dllNewList: procedure(list: TGLuint; mode: TGLenum); stdcall;
  dllNormal3b: procedure(nx, ny, nz: TGLbyte); stdcall;
  dllNormal3bv: procedure(v: PGLbyte); stdcall;
  dllNormal3d: procedure(nx, ny, nz: TGLdouble); stdcall;
  dllNormal3dv: procedure(v: PGLdouble); stdcall;
  dllNormal3f: procedure(nx, ny, nz: TGLfloat); stdcall;
  dllNormal3fv: procedure(v: PGLfloat); stdcall;
  dllNormal3i: procedure(nx, ny, nz: TGLint); stdcall;
  dllNormal3iv: procedure(v: PGLint); stdcall;
  dllNormal3s: procedure(nx, ny, nz: TGLshort); stdcall;
  dllNormal3sv: procedure(v: PGLshort); stdcall;
  dllNormalPointer: procedure(atype: TGLenum; stride: TGLsizei; pointer: Pointer); stdcall;
  dllOrtho: procedure(left, right, bottom, top, zNear, zFar: TGLdouble); stdcall;
  dllPassThrough: procedure(token: TGLfloat); stdcall;
  dllPixelMapfv: procedure(map: TGLenum; mapsize: TGLsizei; values: PGLfloat); stdcall;
  dllPixelMapuiv: procedure(map: TGLenum; mapsize: TGLsizei; values: PGLuint); stdcall;
  dllPixelMapusv: procedure(map: TGLenum; mapsize: TGLsizei; values: PGLushort); stdcall;
  dllPixelStoref: procedure(pname: TGLenum; param: TGLfloat); stdcall;
  dllPixelStorei: procedure(pname: TGLenum; param: TGLint); stdcall;
  dllPixelTransferf: procedure(pname: TGLenum; param: TGLfloat); stdcall;
  dllPixelTransferi: procedure(pname: TGLenum; param: TGLint); stdcall;
  dllPixelZoom: procedure(xfactor, yfactor: TGLfloat); stdcall;
  dllPointSize: procedure(size: TGLfloat); stdcall;
  dllPolygonMode: procedure(face, mode: TGLenum); stdcall;
  dllPolygonOffset: procedure(factor, units: TGLfloat); stdcall;
  dllPolygonStipple: procedure(mask: PGLubyte); stdcall;
  dllPopAttrib: procedure; stdcall;
  dllPopClientAttrib: procedure; stdcall;
  dllPopMatrix: procedure; stdcall;
  dllPopName: procedure; stdcall;
  dllPrioritizeTextures: procedure(n: TGLsizei; textures: PGLuint; priorities: PGLclampf); stdcall;
  dllPushAttrib: procedure(mask: TGLbitfield); stdcall;
  dllPushClientAttrib: procedure(mask: TGLbitfield); stdcall;
  dllPushMatrix: procedure; stdcall;
  dllPushName: procedure(name: TGLuint); stdcall;
  dllRasterPos2d: procedure(x, y: TGLdouble); stdcall;
  dllRasterPos2dv: procedure(v: PGLdouble); stdcall;
  dllRasterPos2f: procedure(x, y: TGLfloat); stdcall;
  dllRasterPos2fv: procedure(v: PGLfloat); stdcall;
  dllRasterPos2i: procedure(x, y: TGLint); stdcall;
  dllRasterPos2iv: procedure(v: PGLint); stdcall;
  dllRasterPos2s: procedure(x, y: TGLshort); stdcall;
  dllRasterPos2sv: procedure(v: PGLshort); stdcall;
  dllRasterPos3d: procedure(x, y, z: TGLdouble); stdcall;
  dllRasterPos3dv: procedure(v: PGLdouble); stdcall;
  dllRasterPos3f: procedure(x, y, z: TGLfloat); stdcall;
  dllRasterPos3fv: procedure(v: PGLfloat); stdcall;
  dllRasterPos3i: procedure(x, y, z: TGLint); stdcall;
  dllRasterPos3iv: procedure(v: PGLint); stdcall;
  dllRasterPos3s: procedure(x, y, z: TGLshort); stdcall;
  dllRasterPos3sv: procedure(v: PGLshort); stdcall;
  dllRasterPos4d: procedure(x, y, z, w: TGLdouble); stdcall;
  dllRasterPos4dv: procedure(v: PGLdouble); stdcall;
  dllRasterPos4f: procedure(x, y, z, w: TGLfloat); stdcall;
  dllRasterPos4fv: procedure(v: PGLfloat); stdcall;
  dllRasterPos4i: procedure(x, y, z, w: TGLint); stdcall;
  dllRasterPos4iv: procedure(v: PGLint); stdcall;
  dllRasterPos4s: procedure(x, y, z, w: TGLshort); stdcall;
  dllRasterPos4sv: procedure(v: PGLshort); stdcall;
  dllReadBuffer: procedure(mode: TGLenum); stdcall;
  dllReadPixels: procedure(x, y: TGLint; width, height: TGLsizei; format, atype: TGLenum; pixels: Pointer); stdcall;
  dllRectd: procedure(x1, y1, x2, y2: TGLdouble); stdcall;
  dllRectdv: procedure(v1: PGLdouble; v2: PGLdouble); stdcall;
  dllRectf: procedure(x1, y1, x2, y2: TGLfloat); stdcall;
  dllRectfv: procedure(v1: PGLfloat; v2: PGLfloat); stdcall;
  dllRecti: procedure(x1, y1, x2, y2: TGLint); stdcall;
  dllRectiv: procedure(v1: PGLint; v2: PGLint); stdcall;
  dllRects: procedure(x1, y1, x2, y2: TGLshort); stdcall;
  dllRectsv: procedure(v1: PGLshort; v2: PGLshort); stdcall;
  dllRenderMode: function(mode: TGLint): TGLint; stdcall;
  dllRotated: procedure(angle, x, y, z: TGLdouble); stdcall;
  dllRotatef: procedure(angle, x, y, z: TGLfloat); stdcall;
  dllScaled: procedure(x, y, z: TGLdouble); stdcall;
  dllScalef: procedure(x, y, z: TGLfloat); stdcall;
  dllScissor: procedure(x, y: TGLint; width, height: TGLsizei); stdcall;
  dllSelectBuffer: procedure(size: TGLsizei; buffer: PGLuint); stdcall;
  dllShadeModel: procedure(mode: TGLenum); stdcall;
  dllStencilFunc: procedure(func: TGLenum; ref: TGLint; mask: TGLuint); stdcall;
  dllStencilMask: procedure(mask: TGLuint); stdcall;
  dllStencilOp: procedure(fail, zfail, zpass: TGLenum); stdcall;
  dllTexCoord1d: procedure(s: TGLdouble); stdcall;
  dllTexCoord1dv: procedure(v: PGLdouble); stdcall;
  dllTexCoord1f: procedure(s: TGLfloat); stdcall;
  dllTexCoord1fv: procedure(v: PGLfloat); stdcall;
  dllTexCoord1i: procedure(s: TGLint); stdcall;
  dllTexCoord1iv: procedure(v: PGLint); stdcall;
  dllTexCoord1s: procedure(s: TGLshort); stdcall;
  dllTexCoord1sv: procedure(v: PGLshort); stdcall;
  dllTexCoord2d: procedure(s, t: TGLdouble); stdcall;
  dllTexCoord2dv: procedure(v: PGLdouble); stdcall;
  dllTexCoord2f: procedure(s, t: TGLfloat); stdcall;
  dllTexCoord2fv: procedure(v: PGLfloat); stdcall;
  dllTexCoord2i: procedure(s, t: TGLint); stdcall;
  dllTexCoord2iv: procedure(v: PGLint); stdcall;
  dllTexCoord2s: procedure(s, t: TGLshort); stdcall;
  dllTexCoord2sv: procedure(v: PGLshort); stdcall;
  dllTexCoord3d: procedure(s, t, r: TGLdouble); stdcall;
  dllTexCoord3dv: procedure(v: PGLdouble); stdcall;
  dllTexCoord3f: procedure(s, t, r: TGLfloat); stdcall;
  dllTexCoord3fv: procedure(v: PGLfloat); stdcall;
  dllTexCoord3i: procedure(s, t, r: TGLint); stdcall;
  dllTexCoord3iv: procedure(v: PGLint); stdcall;
  dllTexCoord3s: procedure(s, t, r: TGLshort); stdcall;
  dllTexCoord3sv: procedure(v: PGLshort); stdcall;
  dllTexCoord4d: procedure(s, t, r, q: TGLdouble); stdcall;
  dllTexCoord4dv: procedure(v: PGLdouble); stdcall;
  dllTexCoord4f: procedure(s, t, r, q: TGLfloat); stdcall;
  dllTexCoord4fv: procedure(v: PGLfloat); stdcall;
  dllTexCoord4i: procedure(s, t, r, q: TGLint); stdcall;
  dllTexCoord4iv: procedure(v: PGLint); stdcall;
  dllTexCoord4s: procedure(s, t, r, q: TGLshort); stdcall;
  dllTexCoord4sv: procedure(v: PGLshort); stdcall;
  dllTexCoordPointer: procedure(size: TGLint; atype: TGLenum; stride: TGLsizei; pointer: Pointer); stdcall;
  dllTexEnvf: procedure(target: TGLenum; pname: TGLenum; param: TGLfloat); stdcall;
  dllTexEnvfv: procedure(target: TGLenum; pname: TGLenum; params: PGLfloat); stdcall;
  dllTexEnvi: procedure(target: TGLenum; pname: TGLenum; param: TGLint); stdcall;
  dllTexEnviv: procedure(target: TGLenum; pname: TGLenum; params: PGLint); stdcall;
  dllTexGend: procedure(coord: TGLenum; pname: TGLenum; param: TGLdouble); stdcall;
  dllTexGendv: procedure(coord: TGLenum; pname: TGLenum; params: PGLdouble); stdcall;
  dllTexGenf: procedure(coord: TGLenum; pname: TGLenum; param: TGLfloat); stdcall;
  dllTexGenfv: procedure(coord: TGLenum; pname: TGLenum; params: PGLfloat); stdcall;
  dllTexGeni: procedure(coord: TGLenum; pname: TGLenum; param: TGLint); stdcall;
  dllTexGeniv: procedure(coord: TGLenum; pname: TGLenum; params: PGLint); stdcall;
  dllTexImage1D: procedure(target: TGLenum; level, internalformat: TGLint; width: TGLsizei; border: TGLint; format, atype: TGLenum; pixels: Pointer); stdcall;
  dllTexImage2D: procedure(target: TGLenum; level, internalformat: TGLint; width, height: TGLsizei; border: TGLint; format, atype: TGLenum; pixels: Pointer); stdcall;
  dllTexParameterf: procedure(target: TGLenum; pname: TGLenum; param: TGLfloat); stdcall;
  dllTexParameterfv: procedure(target: TGLenum; pname: TGLenum; params: PGLfloat); stdcall;
  dllTexParameteri: procedure(target: TGLenum; pname: TGLenum; param: TGLint); stdcall;
  dllTexParameteriv: procedure(target: TGLenum; pname: TGLenum; params: PGLint); stdcall;
  dllTexSubImage1D: procedure(target: TGLenum; level, xoffset: TGLint; width: TGLsizei; format, atype: TGLenum; pixels: Pointer); stdcall;
  dllTexSubImage2D: procedure(target: TGLenum; level, xoffset, yoffset: TGLint; width, height: TGLsizei; format, atype: TGLenum; pixels: Pointer); stdcall;
  dllTranslated: procedure(x, y, z: TGLdouble); stdcall;
  dllTranslatef: procedure(x, y, z: TGLfloat); stdcall;
  dllVertex2d: procedure(x, y: TGLdouble); stdcall;
  dllVertex2dv: procedure(v: PGLdouble); stdcall;
  dllVertex2f: procedure(x, y: TGLfloat); stdcall;
  dllVertex2fv: procedure(v: PGLfloat); stdcall;
  dllVertex2i: procedure(x, y: TGLint); stdcall;
  dllVertex2iv: procedure(v: PGLint); stdcall;
  dllVertex2s: procedure(x, y: TGLshort); stdcall;
  dllVertex2sv: procedure(v: PGLshort); stdcall;
  dllVertex3d: procedure(x, y, z: TGLdouble); stdcall;
  dllVertex3dv: procedure(v: PGLdouble); stdcall;
  dllVertex3f: procedure(x, y, z: TGLfloat); stdcall;
  dllVertex3fv: procedure(v: PGLfloat); stdcall;
  dllVertex3i: procedure(x, y, z: TGLint); stdcall;
  dllVertex3iv: procedure(v: PGLint); stdcall;
  dllVertex3s: procedure(x, y, z: TGLshort); stdcall;
  dllVertex3sv: procedure(v: PGLshort); stdcall;
  dllVertex4d: procedure(x, y, z, w: TGLdouble); stdcall;
  dllVertex4dv: procedure(v: PGLdouble); stdcall;
  dllVertex4f: procedure(x, y, z, w: TGLfloat); stdcall;
  dllVertex4fv: procedure(v: PGLfloat); stdcall;
  dllVertex4i: procedure(x, y, z, w: TGLint); stdcall;
  dllVertex4iv: procedure(v: PGLint); stdcall;
  dllVertex4s: procedure(x, y, z, w: TGLshort); stdcall;
  dllVertex4sv: procedure(v: PGLshort); stdcall;
  dllVertexPointer: procedure(size: TGLint; atype: TGLenum; stride: TGLsizei; pointer: Pointer); stdcall;
  dllViewport: procedure(x, y: TGLint; width, height: TGLsizei); stdcall;


//#define SIG( x ) fprintf( glw_state.log_fp, x "\n" )
procedure SIG (x : string);
begin
//  fprintf( glw_state.log_fp, x "\n" )
  WriteLn (glw_state.log_fp, x{"\n"});
end;

//Y: my-code
procedure SIG2 (x : string; Args: array of const);
begin
  WriteLn (glw_state.log_fp, Format(x, Args));
end;


//336 log OpenGL procedures - It's ONLY for IMPLEMENTATION unit-section
procedure logAccum (op: TGLenum; value: TGLfloat); stdcall;
begin
  SIG ('glAccum');
  dllAccum (op, value);
end;
procedure logAlphaFunc (func: TGLenum; ref: TGLclampf); stdcall;
begin
//  fprintf( glw_state.log_fp, 'glAlphaFunc( 0x%x, %f )\n', func, ref );
  SIG2 ('glAlphaFunc (0x%x, %f)\n', [func, ref]);
  dllAlphaFunc( func, ref );
end;
function  logAreTexturesResident (n: TGLsizei; textures: PGLuint; residences: PGLboolean): TGLboolean; stdcall;
begin
//  fprintf( glw_state.log_fp, 'glAreTexturesResident\n' );
  SIG ('glAreTexturesResident');
  Result := dllAreTexturesResident (n, textures, residences);
end;
procedure logArrayElement (i: TGLint); stdcall;
begin
//  fprintf( glw_state.log_fp, 'glArrayElement\n' );
  SIG ('glArrayElement');
  dllArrayElement (i);
end;
procedure logBegin (mode: TGLenum); stdcall;
begin
//  fprintf( glw_state.log_fp, 'glBegin( 0x%x )\n', mode );
  SIG2 ('glBegin (0x%x)\n', [mode]);
  dllBegin (mode);
end;
procedure logBindTexture (target: TGLenum; texture: TGLuint); stdcall;
begin
//  fprintf( glw_state.log_fp, 'glBindTexture( 0x%x, %u )\n', target, texture );
  SIG2 ('glBindTexture (0x%x, %u)\n', [target, texture]);
  dllBindTexture (target, texture);
end;
procedure logBitmap (width, height: TGLsizei; xorig, yorig: TGLfloat; xmove, ymove: TGLfloat; bitmap: PGLubyte); stdcall;
begin
//  fprintf( glw_state.log_fp, 'glBitmap\n' );
  SIG ('glBitmap');
  dllBitmap (width, height, xorig, yorig, xmove, ymove, bitmap);
end;
procedure logBlendFunc (sfactor, dfactor: TGLenum); stdcall;
begin
//  fprintf( glw_state.log_fp, 'glBlendFunc( 0x%x, 0x%x )\n', sfactor, dfactor );
  SIG2 ('glBlendFunc (0x%x, 0x%x)\n', [sfactor, dfactor]);
  dllBlendFunc (sfactor, dfactor);
end;
procedure logCallList (list: TGLuint); stdcall;
begin
//  fprintf( glw_state.log_fp, 'glCallList( %u )\n', list );
  SIG2 ('glCallList( %u )\n', [list]);
  dllCallList (list);
end;
procedure logCallLists (n: TGLsizei; atype: TGLenum; lists: Pointer); stdcall;
begin
//  fprintf( glw_state.log_fp, 'glCallLists\n' );
  SIG ('glCallLists');
  dllCallLists (n, atype, lists);
end;
procedure logClear (mask: TGLbitfield); stdcall;
begin
//  fprintf( glw_state.log_fp, 'glClear\n' );
  SIG ('glClear');
  dllClear (mask);
end;
procedure logClearAccum (red, green, blue, alpha: TGLfloat); stdcall;
begin
//  fprintf( glw_state.log_fp, 'glClearAccum\n' );
  SIG ('glClearAccum');
  dllClearAccum (red, green, blue, alpha);
end;
procedure logClearColor (red, green, blue, alpha: TGLclampf); stdcall;
begin
//  fprintf( glw_state.log_fp, 'glClearColor\n' );
  SIG ('glClearColor');
  dllClearColor (red, green, blue, alpha);
end;
procedure logClearDepth (depth: TGLclampd); stdcall;
begin
//  fprintf( glw_state.log_fp, 'glClearDepth\n' );
  SIG ('glClearDepth');
  dllClearDepth (depth);
end;
procedure logClearIndex (c: TGLfloat); stdcall;
begin
//  fprintf( glw_state.log_fp, 'glClearIndex\n' );
  SIG ('glClearIndex');
  dllClearIndex (c);
end;
procedure logClearStencil (s: TGLint); stdcall;
begin
//  fprintf( glw_state.log_fp, 'glClearStencil\n' );
  SIG ('glClearStencil');
  dllClearStencil (s);
end;
procedure logClipPlane (plane: TGLenum; equation: PGLdouble); stdcall;
begin
//  fprintf( glw_state.log_fp, 'glClipPlane\n' );
  SIG ('glClipPlane');
  dllClipPlane (plane, equation);
end;
procedure logColor3b (red, green, blue: TGLbyte); stdcall;
begin
//  fprintf( glw_state.log_fp, 'glColor3b\n' );
  SIG ('glColor3b');
  dllColor3b (red, green, blue);
end;
procedure logColor3bv (v: PGLbyte); stdcall;
begin
//  fprintf( glw_state.log_fp, 'glColor3bv\n' );
  SIG ('glColor3bv');
  dllColor3bv (v);
end;
procedure logColor3d (red, green, blue: TGLdouble); stdcall;
begin
//  fprintf( glw_state.log_fp, 'glColor3d\n' );
  SIG ('glColor3d');
  dllColor3d (red, green, blue);
end;
procedure logColor3dv (v: PGLdouble); stdcall;
begin
//  fprintf( glw_state.log_fp, 'glColor3dv\n' );
  SIG ('glColor3dv');
  dllColor3dv (v);
end;
procedure logColor3f (red, green, blue: TGLfloat); stdcall;
begin
//  fprintf( glw_state.log_fp, 'glColor3f\n' );
  SIG ('glColor3f');
  dllColor3f (red, green, blue);
end;
procedure logColor3fv (v: PGLfloat); stdcall;
begin
//  fprintf( glw_state.log_fp, 'glColor3fv\n' );
  SIG ('glColor3fv');
  dllColor3fv (v);
end;
procedure logColor3i (red, green, blue: TGLint); stdcall;
begin
//  fprintf( glw_state.log_fp, 'glColor3i\n' );
  SIG ('glColor3i');
  dllColor3i (red, green, blue);
end;
procedure logColor3iv (v: PGLint); stdcall;
begin
//  fprintf( glw_state.log_fp, 'glColor3iv\n' );
  SIG ('glColor3iv');
  dllColor3iv (v);
end;
procedure logColor3s (red, green, blue: TGLshort); stdcall;
begin
//  fprintf( glw_state.log_fp, 'glColor3s\n' );
  SIG ('glColor3s');
  dllColor3s (red, green, blue);
end;
procedure logColor3sv (v: PGLshort); stdcall;
begin
//  fprintf( glw_state.log_fp, 'glColor3sv\n' );
  SIG ('glColor3sv');
  dllColor3sv (v);
end;
procedure logColor3ub (red, green, blue: TGLubyte); stdcall;
begin
//  fprintf( glw_state.log_fp, 'glColor3ub\n' );
  SIG ('glColor3ub');
  dllColor3ub (red, green, blue);
end;
procedure logColor3ubv (v: PGLubyte); stdcall;
begin
//  fprintf( glw_state.log_fp, 'glColor3ubv\n' );
  SIG ('glColor3ubv');
  dllColor3ubv (v);
end;
procedure logColor3ui (red, green, blue: TGLuint); stdcall;
begin
  SIG('glColor3ui');
  dllColor3ui (red, green, blue);
end;
procedure logColor3uiv (v: PGLuint); stdcall;
begin
  SIG( 'glColor3uiv' );
  dllColor3uiv( v );
end;
procedure logColor3us (red, green, blue: TGLushort); stdcall;
begin
  SIG( 'glColor3us' );
  dllColor3us( red, green, blue );
end;
procedure logColor3usv (v: PGLushort); stdcall;
begin
  SIG( 'glColor3usv' );
  dllColor3usv( v );
end;
procedure logColor4b (red, green, blue, alpha: TGLubyte); stdcall;
begin
  SIG( 'glColor4b' );
  dllColor4b( red, green, blue, alpha );
end;
procedure logColor4bv (v: PGLbyte); stdcall;
begin
  SIG( 'glColor4bv' );
  dllColor4bv( v );
end;
procedure logColor4d (red, green, blue, alpha: TGLdouble); stdcall;
begin
  SIG( 'glColor4d' );
  dllColor4d( red, green, blue, alpha );
end;
procedure logColor4dv (v: PGLdouble); stdcall;
begin
  SIG( 'glColor4dv' );
  dllColor4dv( v );
end;
procedure logColor4f (red, green, blue, alpha: TGLfloat); stdcall;
begin
//  fprintf( glw_state.log_fp, 'glColor4f( %f,%f,%f,%f )\n', red, green, blue, alpha );
  SIG2 ('glColor4f (%f,%f,%f,%f)\n', [red, green, blue, alpha]);
  dllColor4f (red, green, blue, alpha);
end;

procedure logColor4fv (v: PGLfloat); stdcall;

  //Y: my-code
  type
    PGLArrayF4 = ^TGLArrayF4;
    TGLArrayF4 = array[0..3] of TGLfloat;
  var
    v_ : PGLArrayF4;
  begin
    v_ := PGLArrayF4(v);
  //Y:

//  fprintf( glw_state.log_fp, 'glColor4fv( %f,%f,%f,%f )\n', v[0], v[1], v[2], v[3] );
  SIG2 ('glColor4fv (%f,%f,%f,%f)\n', [v_[0], v_[1], v_[2], v_[3]]);
  dllColor4fv (v);
end;

procedure logColor4i (red, green, blue, alpha: TGLint); stdcall;
begin
  SIG( 'glColor4i' );
  dllColor4i( red, green, blue, alpha );
end;
procedure logColor4iv (v: PGLint); stdcall;
begin
  SIG( 'glColor4iv' );
  dllColor4iv( v );
end;
procedure logColor4s (red, green, blue, alpha: TGLshort); stdcall;
begin
  SIG( 'glColor4s' );
  dllColor4s( red, green, blue, alpha );
end;
procedure logColor4sv (v: PGLshort); stdcall;
begin
  SIG( 'glColor4sv' );
  dllColor4sv( v );
end;
procedure logColor4ub (red, green, blue, alpha: TGLubyte); stdcall;
begin
  SIG( 'glColor4b' );
  dllColor4b( red, green, blue, alpha );
end;
procedure logColor4ubv (v: PGLubyte); stdcall;
begin
  SIG( 'glColor4ubv' );
  dllColor4ubv( v );
end;
procedure logColor4ui (red, green, blue, alpha: TGLuint); stdcall;
begin
  SIG( 'glColor4ui' );
  dllColor4ui( red, green, blue, alpha );
end;
procedure logColor4uiv (v: PGLuint); stdcall;
begin
  SIG( 'glColor4uiv' );
  dllColor4uiv( v );
end;
procedure logColor4us (red, green, blue, alpha: TGLushort); stdcall;
begin
  SIG( 'glColor4us' );
  dllColor4us( red, green, blue, alpha );
end;
procedure logColor4usv (v: PGLushort); stdcall;
begin
  SIG( 'glColor4usv' );
  dllColor4usv( v );
end;
procedure logColorMask (red, green, blue, alpha: TGLboolean); stdcall;
begin
  SIG( 'glColorMask' );
  dllColorMask( red, green, blue, alpha );
end;
procedure logColorMaterial (face, mode: TGLenum); stdcall;
begin
  SIG( 'glColorMaterial' );
  dllColorMaterial( face, mode );
end;
procedure logColorPointer (size: TGLint; atype: TGLenum; stride: TGLsizei; pointer: Pointer); stdcall;
begin
  SIG( 'glColorPointer' );
  dllColorPointer( size, atype, stride, pointer );
end;
procedure logCopyPixels (x, y: TGLint; width, height: TGLsizei; atype: TGLenum); stdcall;
begin
  SIG( 'glCopyPixels' );
  dllCopyPixels( x, y, width, height, atype );
end;
procedure logCopyTexImage1D (target: TGLenum; level: TGLint; internalFormat: TGLenum; x, y: TGLint; width: TGLsizei; border: TGLint); stdcall;
begin
  SIG( 'glCopyTexImage1D' );
  dllCopyTexImage1D( target, level, internalFormat, x, y, width, border );
end;
procedure logCopyTexImage2D (target: TGLenum; level: TGLint; internalFormat: TGLenum; x, y: TGLint; width, height: TGLsizei; border: TGLint); stdcall;
begin
  SIG( 'glCopyTexImage2D' );
  dllCopyTexImage2D( target, level, internalFormat, x, y, width, height, border );
end;
procedure logCopyTexSubImage1D (target: TGLenum; level, xoffset, x, y: TGLint; width: TGLsizei); stdcall;
begin
  SIG( 'glCopyTexSubImage1D' );
  dllCopyTexSubImage1D( target, level, xoffset, x, y, width );
end;
procedure logCopyTexSubImage2D (target: TGLenum; level, xoffset, yoffset, x, y: TGLint; width, height: TGLsizei); stdcall;
begin
  SIG( 'glCopyTexSubImage2D' );
  dllCopyTexSubImage2D( target, level, xoffset, yoffset, x, y, width, height );
end;
procedure logCullFace (mode: TGLenum); stdcall;
begin
  SIG( 'glCullFace' );
  dllCullFace( mode );
end;
procedure logDeleteLists (list: TGLuint; range: TGLsizei); stdcall;
begin
  SIG( 'glDeleteLists' );
  dllDeleteLists( list, range );
end;
procedure logDeleteTextures (n: TGLsizei; textures: PGLuint); stdcall;
begin
  SIG( 'glDeleteTextures' );
  dllDeleteTextures( n, textures );
end;
procedure logDepthFunc (func: TGLenum); stdcall;
begin
  SIG( 'glDepthFunc' );
  dllDepthFunc( func );
end;
procedure logDepthMask (flag: TGLboolean); stdcall;
begin
  SIG( 'glDepthMask' );
  dllDepthMask( flag );
end;
procedure logDepthRange (zNear, zFar: TGLclampd); stdcall;
begin
  SIG( 'glDepthRange' );
  dllDepthRange( zNear, zFar );
end;
procedure logDisable (cap: TGLenum); stdcall;
begin
//  fprintf( glw_state.log_fp, 'glDisable( 0x%x )\n', cap );
  SIG2 ('glDisable (0x%x)\n', [cap]);
  dllDisable (cap);
end;
procedure logDisableClientState (aarray: TGLenum); stdcall;
begin
  SIG( 'glDisableClientState' );
  dllDisableClientState( aarray );
end;
procedure logDrawArrays (mode: TGLenum; first: TGLint; count: TGLsizei); stdcall;
begin
  SIG( 'glDrawArrays' );
  dllDrawArrays( mode, first, count );
end;
procedure logDrawBuffer (mode: TGLenum); stdcall;
begin
  SIG( 'glDrawBuffer' );
  dllDrawBuffer( mode );
end;
procedure logDrawElements (mode: TGLenum; count: TGLsizei; atype: TGLenum; indices: Pointer); stdcall;
begin
  SIG( 'glDrawElements' );
  dllDrawElements( mode, count, atype, indices );
end;
procedure logDrawPixels (width, height: TGLsizei; format, atype: TGLenum; pixels: Pointer); stdcall;
begin
  SIG( 'glDrawPixels' );
  dllDrawPixels( width, height, format, atype, pixels );
end;
procedure logEdgeFlag (flag: TGLboolean); stdcall;
begin
  SIG( 'glEdgeFlag' );
  dllEdgeFlag( flag );
end;
procedure logEdgeFlagPointer (stride: TGLsizei; pointer: Pointer); stdcall;
begin
  SIG( 'glEdgeFlagPointer' );
  dllEdgeFlagPointer( stride, pointer );
end;
procedure logEdgeFlagv (flag: PGLboolean); stdcall;
begin
  SIG( 'glEdgeFlagv' );
  dllEdgeFlagv( flag );
end;
procedure logEnable (cap: TGLenum); stdcall;
begin
//  fprintf( glw_state.log_fp, 'glEnable( 0x%x )\n', cap );
  SIG2 ('glEnable (0x%x)\n', [cap]);
  dllEnable (cap);
end;
procedure logEnableClientState (aarray: TGLenum); stdcall;
begin
  SIG( 'glEnableClientState' );
  dllEnableClientState (aarray);
end;
procedure logEnd; stdcall;
begin
  SIG( 'glEnd' );
  dllEnd();
end;
procedure logEndList; stdcall;
begin
  SIG( 'glEndList' );
  dllEndList();
end;
procedure logEvalCoord1d (u: TGLdouble); stdcall;
begin
  SIG( 'glEvalCoord1d' );
  dllEvalCoord1d( u );
end;
procedure logEvalCoord1dv (u: PGLdouble); stdcall;
begin
  SIG( 'glEvalCoord1dv' );
  dllEvalCoord1dv( u );
end;
procedure logEvalCoord1f (u: TGLfloat); stdcall;
begin
  SIG( 'glEvalCoord1f' );
  dllEvalCoord1f( u );
end;
procedure logEvalCoord1fv (u: PGLfloat); stdcall;
begin
  SIG( 'glEvalCoord1fv' );
  dllEvalCoord1fv( u );
end;
procedure logEvalCoord2d (u, v: TGLdouble); stdcall;
begin
  SIG( 'glEvalCoord2d' );
  dllEvalCoord2d( u, v );
end;
procedure logEvalCoord2dv (u: PGLdouble); stdcall;
begin
  SIG( 'glEvalCoord2dv' );
  dllEvalCoord2dv( u );
end;
procedure logEvalCoord2f (u, v: TGLfloat); stdcall;
begin
  SIG( 'glEvalCoord2f' );
  dllEvalCoord2f( u, v );
end;
procedure logEvalCoord2fv (u: PGLfloat); stdcall;
begin
  SIG( 'glEvalCoord2fv' );
  dllEvalCoord2fv( u );
end;
procedure logEvalMesh1 (mode: TGLenum; i1, i2: TGLint); stdcall;
begin
  SIG( 'glEvalMesh1' );
  dllEvalMesh1( mode, i1, i2 );
end;
procedure logEvalMesh2 (mode: TGLenum; i1, i2, j1, j2: TGLint); stdcall;
begin
  SIG( 'glEvalMesh2' );
  dllEvalMesh2( mode, i1, i2, j1, j2 );
end;
procedure logEvalPoint1 (i: TGLint); stdcall;
begin
  SIG( 'glEvalPoint1' );
  dllEvalPoint1( i );
end;
procedure logEvalPoint2 (i, j: TGLint); stdcall;
begin
  SIG( 'glEvalPoint2' );
  dllEvalPoint2( i, j );
end;
procedure logFeedbackBuffer (size: TGLsizei; atype: TGLenum; buffer: PGLfloat); stdcall;
begin
  SIG('glFeedbackBuffer');
  dllFeedbackBuffer (size, atype, buffer);
end;
procedure logFinish; stdcall;
begin
  SIG( 'glFinish' );
  dllFinish();
end;
procedure logFlush; stdcall;
begin
  SIG( 'glFlush' );
  dllFlush();
end;
procedure logFogf (pname: TGLenum; param: TGLfloat); stdcall;
begin
  SIG( 'glFogf' );
  dllFogf( pname, param );
end;
procedure logFogfv (pname: TGLenum; params: PGLfloat); stdcall;
begin
  SIG( 'glFogfv' );
  dllFogfv( pname, params );
end;
procedure logFogi (pname: TGLenum; param: TGLint); stdcall;
begin
  SIG( 'glFogi' );
  dllFogi( pname, param );
end;
procedure logFogiv (pname: TGLenum; params: PGLint); stdcall;
begin
  SIG( 'glFogiv' );
  dllFogiv( pname, params );
end;
procedure logFrontFace (mode: TGLenum); stdcall;
begin
  SIG( 'glFrontFace' );
  dllFrontFace( mode );
end;
procedure logFrustum (left, right, bottom, top, zNear, zFar: TGLdouble); stdcall;
begin
  SIG( 'glFrustum' );
  dllFrustum( left, right, bottom, top, zNear, zFar );
end;
function  logGenLists (range: TGLsizei): TGLuint; stdcall;
begin
  SIG( 'glGenLists' );
  Result := dllGenLists (range);
end;
procedure logGenTextures (n: TGLsizei; textures: PGLuint); stdcall;
begin
  SIG( 'glGenTextures' );
  dllGenTextures( n, textures );
end;
procedure logGetBooleanv (pname: TGLenum; params: PGLboolean); stdcall;
begin
  SIG( 'glGetBooleanv' );
  dllGetBooleanv( pname, params );
end;
procedure logGetClipPlane (plane: TGLenum; equation: PGLdouble); stdcall;
begin
  SIG( 'glGetClipPlane' );
  dllGetClipPlane( plane, equation );
end;
procedure logGetDoublev (pname: TGLenum; params: PGLdouble); stdcall;
begin
  SIG( 'glGetDoublev' );
  dllGetDoublev( pname, params );
end;
function  logGetError : TGLenum; stdcall;
begin
  SIG ('glGetError');
  Result := dllGetError();
end;
procedure logGetFloatv (pname: TGLenum; params: PGLfloat); stdcall;
begin
  SIG( 'glGetFloatv' );
  dllGetFloatv( pname, params );
end;
procedure logGetIntegerv (pname: TGLenum; params: PGLint); stdcall;
begin
  SIG( 'glGetIntegerv' );
  dllGetIntegerv( pname, params );
end;
procedure logGetLightfv (light, pname: TGLenum; params: PGLfloat); stdcall;
begin
  SIG ('glGetLightfv');
  dllGetLightfv (light, pname, params);
end;
procedure logGetLightiv (light, pname: TGLenum; params: PGLint); stdcall;
begin
  SIG( 'glGetLightiv' );
  dllGetLightiv( light, pname, params );
end;
procedure logGetMapdv (target, query: TGLenum; v: PGLdouble); stdcall;
begin
  SIG( 'glGetMapdv' );
  dllGetMapdv( target, query, v );
end;
procedure logGetMapfv (target, query: TGLenum; v: PGLfloat); stdcall;
begin
  SIG( 'glGetMapfv' );
  dllGetMapfv( target, query, v );
end;
procedure logGetMapiv (target, query: TGLenum; v: TGLint); stdcall;
begin
  SIG( 'glGetMapiv' );
  dllGetMapiv( target, query, v );
end;
procedure logGetMaterialfv (face, pname: TGLenum; params: PGLfloat); stdcall;
begin
  SIG ('glGetMaterialfv');
  dllGetMaterialfv (face, pname, params);
end;
procedure logGetMaterialiv (face, pname: TGLenum; params: TGLint); stdcall;
begin
  SIG ('glGetMaterialiv');
  dllGetMaterialiv (face, pname, params);
end;
procedure logGetPixelMapfv (map: TGLenum; values: PGLfloat); stdcall;
begin
  SIG( 'glGetPixelMapfv' );
  dllGetPixelMapfv( map, values );
end;
procedure logGetPixelMapuiv (map: TGLenum; values: PGLuint); stdcall;
begin
  SIG( 'glGetPixelMapuiv' );
  dllGetPixelMapuiv( map, values );
end;
procedure logGetPixelMapusv (map: TGLenum; values: PGLushort); stdcall;
begin
  SIG ('glGetPixelMapusv');
  dllGetPixelMapusv (map, values);
end;
procedure logGetPointerv (pname: TGLenum; params: Pointer); stdcall;
begin
  SIG( 'glGetPointerv' );
  dllGetPointerv( pname, params );
end;
procedure logGetPolygonStipple (mask: PGLubyte); stdcall;
begin
  SIG( 'glGetPolygonStipple' );
  dllGetPolygonStipple( mask );
end;
function logGetString (name: TGLenum): PGLubyte; stdcall;
begin
  SIG ('glGetString');
  Result := dllGetString (name);
end;
procedure logGetTexEnvfv (target, pname: TGLenum; params: PGLfloat); stdcall;
begin
  SIG( 'glGetTexEnvfv' );
  dllGetTexEnvfv( target, pname, params );
end;
procedure logGetTexEnviv (target, pname: TGLenum; params: PGLint); stdcall;
begin
  SIG( 'glGetTexEnviv' );
  dllGetTexEnviv( target, pname, params );
end;
procedure logGetTexGendv (coord, pname: TGLenum; params: PGLdouble); stdcall;
begin
  SIG( 'glGetTexGendv' );
  dllGetTexGendv( coord, pname, params );
end;
procedure logGetTexGenfv (coord, pname: TGLenum; params: PGLfloat); stdcall;
begin
  SIG( 'glGetTexGenfv' );
  dllGetTexGenfv( coord, pname, params );
end;
procedure logGetTexGeniv (coord, pname: TGLenum; params: PGLint); stdcall;
begin
  SIG ('glGetTexGeniv');
  dllGetTexGeniv(coord, pname, params);
end;
procedure logGetTexImage (target: TGLenum; level: TGLint; format: TGLenum; atype: TGLenum; pixels: Pointer); stdcall;
begin
  SIG( 'glGetTexImage' );
  dllGetTexImage( target, level, format, atype, pixels );
end;
procedure logGetTexLevelParameterfv (target: TGLenum; level: TGLint; pname: TGLenum; params: Pointer); stdcall;
begin
  SIG ('glGetTexLevelParameterfv');
  dllGetTexLevelParameterfv (target, level, pname, params);
end;
procedure logGetTexLevelParameteriv (target: TGLenum; level: TGLint; pname: TGLenum; params: PGLint); stdcall;
begin
  SIG ('glGetTexLevelParameteriv');
  dllGetTexLevelParameteriv (target, level, pname, params);
end;
procedure logGetTexParameterfv (target, pname: TGLenum; params: PGLfloat); stdcall;
begin
  SIG( 'glGetTexParameterfv' );
  dllGetTexParameterfv( target, pname, params );
end;
procedure logGetTexParameteriv (target, pname: TGLenum; params: PGLint); stdcall;
begin
  SIG( 'glGetTexParameteriv' );
  dllGetTexParameteriv (target, pname, params);
end;
procedure logHint (target, mode: TGLenum); stdcall;
begin
//  fprintf( glw_state.log_fp, 'glHint( 0x%x, 0x%x )\n', target, mode );
  SIG2 ('glHint (0x%x, 0x%x)\n', [target, mode]);
  dllHint (target, mode);
end;
procedure logIndexMask (mask: TGLuint); stdcall;
begin
  SIG( 'glIndexMask' );
  dllIndexMask( mask );
end;
procedure logIndexPointer (atype: TGLenum; stride: TGLsizei; pointer: Pointer); stdcall;
begin
  SIG ('glIndexPointer');
  dllIndexPointer (atype, stride, pointer);
end;
procedure logIndexd (c: TGLdouble); stdcall;
begin
  SIG( 'glIndexd' );
  dllIndexd( c );
end;
procedure logIndexdv (c: PGLdouble); stdcall;
begin
  SIG( 'glIndexdv' );
  dllIndexdv( c );
end;
procedure logIndexf (c: TGLfloat); stdcall;
begin
  SIG( 'glIndexf' );
  dllIndexf( c );
end;
procedure logIndexfv (c: PGLfloat); stdcall;
begin
  SIG( 'glIndexfv' );
  dllIndexfv( c );
end;
procedure logIndexi (c: TGLint); stdcall;
begin
  SIG( 'glIndexi' );
  dllIndexi( c );
end;
procedure logIndexiv (c: PGLint); stdcall;
begin
  SIG( 'glIndexiv' );
  dllIndexiv( c );
end;
procedure logIndexs (c: TGLshort); stdcall;
begin
  SIG( 'glIndexs' );
  dllIndexs( c );
end;
procedure logIndexsv (c: PGLshort); stdcall;
begin
  SIG ('glIndexsv');
  dllIndexsv (c);
end;
procedure logIndexub (c: TGLubyte); stdcall;
begin
  SIG( 'glIndexub' );
  dllIndexub( c );
end;
procedure logIndexubv (c: PGLubyte); stdcall;
begin
  SIG ('glIndexubv');
  dllIndexubv (c);
end;
procedure logInitNames; stdcall;
begin
  SIG( 'glInitNames' );
  dllInitNames();
end;
procedure logInterleavedArrays (format: TGLenum; stride: TGLsizei; pointer: Pointer); stdcall;
begin
  SIG( 'glInitNames' );
  dllInitNames();
end;
function logIsEnabled (cap: TGLenum): TGLboolean; stdcall;
begin
  SIG ('glIsEnabled');
  Result := dllIsEnabled (cap);
end;
function logIsList (list: TGLuint): TGLboolean; stdcall;
begin
  SIG ('glIsList');
  Result := dllIsList (list);
end;
function logIsTexture (texture: TGLuint): TGLboolean; stdcall;
begin
  SIG ('glIsTexture');
  Result := dllIsTexture (texture);
end;
procedure logLightModelf (pname: TGLenum; param: TGLfloat); stdcall;
begin
  SIG( 'glLightModelf' );
  dllLightModelf( pname, param );
end;
procedure logLightModelfv (pname: TGLenum; params: PGLfloat); stdcall;
begin
  SIG( 'glLightModelfv' );
  dllLightModelfv( pname, params );
end;
procedure logLightModeli (pname: TGLenum; param: TGLint); stdcall;
begin
  SIG( 'glLightModeli' );
  dllLightModeli( pname, param );
end;
procedure logLightModeliv (pname: TGLenum; params: PGLint); stdcall;
begin
  SIG( 'glLightModeliv' );
  dllLightModeliv( pname, params );
end;
procedure logLightf (light, pname: TGLenum; param: TGLfloat); stdcall;
begin
  SIG( 'glLightf' );
  dllLightf( light, pname, param );
end;
procedure logLightfv (light, pname: TGLenum; params: PGLfloat); stdcall;
begin
  SIG( 'glLightfv' );
  dllLightfv( light, pname, params );
end;
procedure logLighti (light, pname: TGLenum; param: TGLint); stdcall;
begin
  SIG( 'glLighti' );
  dllLighti( light, pname, param );
end;
procedure logLightiv (light, pname: TGLenum; params: TGLint); stdcall;
begin
  SIG( 'glLightiv' );
  dllLightiv( light, pname, params );
end;
procedure logLineStipple (factor: TGLint; pattern: TGLushort); stdcall;
begin
  SIG( 'glLineStipple' );
  dllLineStipple( factor, pattern );
end;
procedure logLineWidth (width: TGLfloat); stdcall;
begin
  SIG( 'glLineWidth' );
  dllLineWidth( width );
end;
procedure logListBase (base: TGLuint); stdcall;
begin
  SIG( 'glListBase' );
  dllListBase( base );
end;
procedure logLoadIdentity; stdcall;
begin
  SIG( 'glLoadIdentity' );
  dllLoadIdentity();
end;
procedure logLoadMatrixd (m: PGLdouble); stdcall;
begin
  SIG( 'glLoadMatrixd' );
  dllLoadMatrixd( m );
end;
procedure logLoadMatrixf (m: PGLfloat); stdcall;
begin
  SIG( 'glLoadMatrixf' );
  dllLoadMatrixf( m );
end;
procedure logLoadName (name: TGLuint); stdcall;
begin
  SIG( 'glLoadName' );
  dllLoadName( name );
end;
procedure logLogicOp (opcode: TGLenum); stdcall;
begin
  SIG( 'glLogicOp' );
  dllLogicOp( opcode );
end;
procedure logMap1d (target: TGLenum; u1, u2: TGLdouble; stride, order: TGLint; points: PGLdouble); stdcall;
begin
  SIG( 'glMap1d' );
  dllMap1d( target, u1, u2, stride, order, points );
end;
procedure logMap1f (target: TGLenum; u1, u2: TGLfloat; stride, order: TGLint; points: PGLfloat); stdcall;
begin
  SIG( 'glMap1f' );
  dllMap1f( target, u1, u2, stride, order, points );
end;
procedure logMap2d (target: TGLenum; u1, u2: TGLdouble; ustride, uorder: TGLint; v1, v2: TGLdouble; vstride, vorder: TGLint; points: PGLdouble); stdcall;
begin
  SIG( 'glMap2d' );
  dllMap2d( target, u1, u2, ustride, uorder, v1, v2, vstride, vorder, points );
end;
procedure logMap2f (target: TGLenum; u1, u2: TGLfloat; ustride, uorder: TGLint; v1, v2: TGLfloat; vstride, vorder: TGLint; points: PGLfloat); stdcall;
begin
  SIG( 'glMap2f' );
  dllMap2f( target, u1, u2, ustride, uorder, v1, v2, vstride, vorder, points );
end;
procedure logMapGrid1d (un: TGLint; u1, u2: TGLdouble); stdcall;
begin
  SIG( 'glMapGrid1d' );
  dllMapGrid1d( un, u1, u2 );
end;
procedure logMapGrid1f (un: TGLint; u1, u2: TGLfloat); stdcall;
begin
  SIG( 'glMapGrid1f' );
  dllMapGrid1f( un, u1, u2 );
end;
procedure logMapGrid2d (un: TGLint; u1, u2: TGLdouble; vn: TGLint; v1, v2: TGLdouble); stdcall;
begin
  SIG( 'glMapGrid2d' );
  dllMapGrid2d( un, u1, u2, vn, v1, v2 );
end;
procedure logMapGrid2f (un: TGLint; u1, u2: TGLfloat; vn: TGLint; v1, v2: TGLfloat); stdcall;
begin
  SIG( 'glMapGrid2f' );
  dllMapGrid2f( un, u1, u2, vn, v1, v2 );
end;
procedure logMaterialf (face, pname: TGLenum; param: TGLfloat); stdcall;
begin
  SIG( 'glMaterialf' );
  dllMaterialf( face, pname, param );
end;
procedure logMaterialfv (face, pname: TGLenum; params: PGLfloat); stdcall;
begin
  SIG( 'glMaterialfv' );
  dllMaterialfv( face, pname, params );
end;
procedure logMateriali (face, pname: TGLenum; param: TGLint); stdcall;
begin
  SIG( 'glMateriali' );
  dllMateriali( face, pname, param );
end;
procedure logMaterialiv (face, pname: TGLenum; params: PGLint); stdcall;
begin
  SIG( 'glMaterialiv' );
  dllMaterialiv( face, pname, params );
end;
procedure logMatrixMode (mode: TGLenum); stdcall;
begin
  SIG( 'glMatrixMode' );
  dllMatrixMode( mode );
end;
procedure logMultMatrixd (m: PGLdouble); stdcall;
begin
  SIG( 'glMultMatrixd' );
  dllMultMatrixd( m );
end;
procedure logMultMatrixf (m: PGLfloat); stdcall;
begin
  SIG( 'glMultMatrixf' );
  dllMultMatrixf( m );
end;
procedure logNewList (list: TGLuint; mode: TGLenum); stdcall;
begin
  SIG( 'glNewList' );
  dllNewList( list, mode );
end;
procedure logNormal3b (nx, ny, nz: TGLbyte); stdcall;
begin
  SIG ('glNormal3b' );
  dllNormal3b( nx, ny, nz );
end;
procedure logNormal3bv (v: PGLbyte); stdcall;
begin
  SIG( 'glNormal3bv' );
  dllNormal3bv( v );
end;
procedure logNormal3d (nx, ny, nz: TGLdouble); stdcall;
begin
  SIG( 'glNormal3d' );
  dllNormal3d( nx, ny, nz );
end;
procedure logNormal3dv (v: PGLdouble); stdcall;
begin
  SIG( 'glNormal3dv' );
  dllNormal3dv( v );
end;
procedure logNormal3f (nx, ny, nz: TGLfloat); stdcall;
begin
  SIG( 'glNormal3f' );
  dllNormal3f( nx, ny, nz );
end;
procedure logNormal3fv (v: PGLfloat); stdcall;
begin
  SIG( 'glNormal3fv' );
  dllNormal3fv( v );
end;
procedure logNormal3i (nx, ny, nz: TGLint); stdcall;
begin
  SIG( 'glNormal3i' );
  dllNormal3i( nx, ny, nz );
end;
procedure logNormal3iv (v: PGLint); stdcall;
begin
  SIG( 'glNormal3iv' );
  dllNormal3iv( v );
end;
procedure logNormal3s (nx, ny, nz: TGLshort); stdcall;
begin
  SIG ('glNormal3s');
  dllNormal3s (nx, ny, nz);
end;
procedure logNormal3sv (v: PGLshort); stdcall;
begin
  SIG( 'glNormal3sv' );
  dllNormal3sv( v );
end;
procedure logNormalPointer (atype: TGLenum; stride: TGLsizei; pointer: Pointer); stdcall;
begin
  SIG ('glNormalPointer');
  dllNormalPointer (atype, stride, pointer);
end;
procedure logOrtho (left, right, bottom, top, zNear, zFar: TGLdouble); stdcall;
begin
  SIG ('glOrtho');
  dllOrtho (left, right, bottom, top, zNear, zFar);
end;
procedure logPassThrough (token: TGLfloat); stdcall;
begin
  SIG( 'glPassThrough' );
  dllPassThrough( token );
end;
procedure logPixelMapfv (map: TGLenum; mapsize: TGLsizei; values: PGLfloat); stdcall;
begin
  SIG( 'glPixelMapfv' );
  dllPixelMapfv( map, mapsize, values );
end;
procedure logPixelMapuiv (map: TGLenum; mapsize: TGLsizei; values: PGLuint); stdcall;
begin
  SIG( 'glPixelMapuiv' );
  dllPixelMapuiv( map, mapsize, values );
end;
procedure logPixelMapusv (map: TGLenum; mapsize: TGLsizei; values: PGLushort); stdcall;
begin
  SIG( 'glPixelMapusv' );
  dllPixelMapusv( map, mapsize, values );
end;
procedure logPixelStoref (pname: TGLenum; param: TGLfloat); stdcall;
begin
  SIG( 'glPixelStoref' );
  dllPixelStoref( pname, param );
end;
procedure logPixelStorei (pname: TGLenum; param: TGLint); stdcall;
begin
  SIG( 'glPixelStorei' );
  dllPixelStorei( pname, param );
end;
procedure logPixelTransferf (pname: TGLenum; param: TGLfloat); stdcall;
begin
  SIG( 'glPixelTransferf' );
  dllPixelTransferf( pname, param );
end;
procedure logPixelTransferi (pname: TGLenum; param: TGLint); stdcall;
begin
  SIG( 'glPixelTransferi' );
  dllPixelTransferi( pname, param );
end;
procedure logPixelZoom (xfactor, yfactor: TGLfloat); stdcall;
begin
  SIG( 'glPixelZoom' );
  dllPixelZoom( xfactor, yfactor );
end;
procedure logPointSize (size: TGLfloat); stdcall;
begin
  SIG( 'glPointSize' );
  dllPointSize( size );
end;
procedure logPolygonMode (face, mode: TGLenum); stdcall;
begin
//  fprintf( glw_state.log_fp, 'glPolygonMode( 0x%x, 0x%x )\n', face, mode );
  SIG2 ('glPolygonMode (0x%x, 0x%x)\n', [face, mode]);
  dllPolygonMode (face, mode);
end;
procedure logPolygonOffset (factor, units: TGLfloat); stdcall;
begin
  SIG( 'glPolygonOffset' );
  dllPolygonOffset( factor, units );
end;
procedure logPolygonStipple (mask: PGLubyte); stdcall;
begin
  SIG( 'glPolygonStipple' );
  dllPolygonStipple( mask );
end;
procedure logPopAttrib; stdcall;
begin
  SIG( 'glPopAttrib' );
  dllPopAttrib();
end;
procedure logPopClientAttrib; stdcall;
begin
  SIG( 'glPopClientAttrib' );
  dllPopClientAttrib();
end;
procedure logPopMatrix; stdcall;
begin
  SIG( 'glPopMatrix' );
  dllPopMatrix();
end;
procedure logPopName; stdcall;
begin
  SIG( 'glPopName' );
  dllPopName();
end;
procedure logPrioritizeTextures (n: TGLsizei; textures: PGLuint; priorities: PGLclampf); stdcall;
begin
  SIG( 'glPrioritizeTextures' );
  dllPrioritizeTextures( n, textures, priorities );
end;
procedure logPushAttrib (mask: TGLbitfield); stdcall;
begin
  SIG( 'glPushAttrib' );
  dllPushAttrib( mask );
end;
procedure logPushClientAttrib (mask: TGLbitfield); stdcall;
begin
  SIG( 'glPushClientAttrib' );
  dllPushClientAttrib( mask );
end;
procedure logPushMatrix; stdcall;
begin
  SIG( 'glPushMatrix' );
  dllPushMatrix();
end;
procedure logPushName (name: TGLuint); stdcall;
begin
  SIG( 'glPushName' );
  dllPushName( name );
end;
procedure logRasterPos2d (x, y: TGLdouble); stdcall;
begin
  SIG ('glRasterPot2d' );
  dllRasterPos2d( x, y );
end;
procedure logRasterPos2dv (v: PGLdouble); stdcall;
begin
  SIG( 'glRasterPos2dv' );
  dllRasterPos2dv( v );
end;
procedure logRasterPos2f (x, y: TGLfloat); stdcall;
begin
  SIG( 'glRasterPos2f' );
  dllRasterPos2f( x, y );
end;
procedure logRasterPos2fv (v: PGLfloat); stdcall;
begin
  SIG( 'glRasterPos2dv' );
  dllRasterPos2fv( v );
end;
procedure logRasterPos2i (x, y: TGLint); stdcall;
begin
  SIG( 'glRasterPos2if' );
  dllRasterPos2i( x, y );
end;
procedure logRasterPos2iv (v: PGLint); stdcall;
begin
  SIG( 'glRasterPos2iv' );
  dllRasterPos2iv( v );
end;
procedure logRasterPos2s (x, y: TGLshort); stdcall;
begin
  SIG( 'glRasterPos2s' );
  dllRasterPos2s( x, y );
end;
procedure logRasterPos2sv (v: PGLshort); stdcall;
begin
  SIG( 'glRasterPos2sv' );
  dllRasterPos2sv( v );
end;
procedure logRasterPos3d (x, y, z: TGLdouble); stdcall;
begin
  SIG( 'glRasterPos3d' );
  dllRasterPos3d( x, y, z );
end;
procedure logRasterPos3dv (v: PGLdouble); stdcall;
begin
  SIG( 'glRasterPos3dv' );
  dllRasterPos3dv( v );
end;
procedure logRasterPos3f (x, y, z: TGLfloat); stdcall;
begin
  SIG( 'glRasterPos3f' );
  dllRasterPos3f( x, y, z );
end;
procedure logRasterPos3fv (v: PGLfloat); stdcall;
begin
  SIG( 'glRasterPos3fv' );
  dllRasterPos3fv( v );
end;
procedure logRasterPos3i (x, y, z: TGLint); stdcall;
begin
  SIG( 'glRasterPos3i' );
  dllRasterPos3i( x, y, z );
end;
procedure logRasterPos3iv (v: PGLint); stdcall;
begin
  SIG( 'glRasterPos3iv' );
  dllRasterPos3iv( v );
end;
procedure logRasterPos3s (x, y, z: TGLshort); stdcall;
begin
  SIG( 'glRasterPos3s' );
  dllRasterPos3s( x, y, z );
end;
procedure logRasterPos3sv (v: PGLshort); stdcall;
begin
  SIG( 'glRasterPos3sv' );
  dllRasterPos3sv( v );
end;
procedure logRasterPos4d (x, y, z, w: TGLdouble); stdcall;
begin
  SIG( 'glRasterPos4d' );
  dllRasterPos4d( x, y, z, w );
end;
procedure logRasterPos4dv (v: PGLdouble); stdcall;
begin
  SIG( 'glRasterPos4dv' );
  dllRasterPos4dv( v );
end;
procedure logRasterPos4f (x, y, z, w: TGLfloat); stdcall;
begin
  SIG( 'glRasterPos4f' );
  dllRasterPos4f( x, y, z, w );
end;
procedure logRasterPos4fv (v: PGLfloat); stdcall;
begin
  SIG( 'glRasterPos4fv' );
  dllRasterPos4fv( v );
end;
procedure logRasterPos4i (x, y, z, w: TGLint); stdcall;
begin
  SIG( 'glRasterPos4i' );
  dllRasterPos4i( x, y, z, w );
end;
procedure logRasterPos4iv (v: PGLint); stdcall;
begin
  SIG( 'glRasterPos4iv' );
  dllRasterPos4iv( v );
end;
procedure logRasterPos4s (x, y, z, w: TGLshort); stdcall;
begin
  SIG( 'glRasterPos4s' );
  dllRasterPos4s( x, y, z, w );
end;
procedure logRasterPos4sv (v: PGLshort); stdcall;
begin
  SIG( 'glRasterPos4sv' );
  dllRasterPos4sv( v );
end;
procedure logReadBuffer (mode: TGLenum); stdcall;
begin
  SIG( 'glReadBuffer' );
  dllReadBuffer( mode );
end;
procedure logReadPixels (x, y: TGLint; width, height: TGLsizei; format, atype: TGLenum; pixels: Pointer); stdcall;
begin
  SIG ('glReadPixels');
  dllReadPixels (x, y, width, height, format, atype, pixels);
end;
procedure logRectd (x1, y1, x2, y2: TGLdouble); stdcall;
begin
  SIG( 'glRectd' );
  dllRectd( x1, y1, x2, y2 );
end;
procedure logRectdv (v1: PGLdouble; v2: PGLdouble); stdcall;
begin
  SIG( 'glRectdv' );
  dllRectdv( v1, v2 );
end;
procedure logRectf (x1, y1, x2, y2: TGLfloat); stdcall;
begin
  SIG( 'glRectf' );
  dllRectf( x1, y1, x2, y2 );
end;
procedure logRectfv (v1: PGLfloat; v2: PGLfloat); stdcall;
begin
  SIG( 'glRectfv' );
  dllRectfv( v1, v2 );
end;
procedure logRecti (x1, y1, x2, y2: TGLint); stdcall;
begin
  SIG( 'glRecti' );
  dllRecti( x1, y1, x2, y2 );
end;
procedure logRectiv (v1: PGLint; v2: PGLint); stdcall;
begin
  SIG( 'glRectiv' );
  dllRectiv( v1, v2 );
end;
procedure logRects (x1, y1, x2, y2: TGLshort); stdcall;
begin
  SIG( 'glRects' );
  dllRects( x1, y1, x2, y2 );
end;
procedure logRectsv (v1: PGLshort; v2: PGLshort); stdcall;
begin
  SIG( 'glRectsv' );
  dllRectsv( v1, v2 );
end;
function logRenderMode (mode: TGLint): TGLint; stdcall;
begin
  SIG ('glRenderMode');
  Result := dllRenderMode (mode);
end;
procedure logRotated (angle, x, y, z: TGLdouble); stdcall;
begin
  SIG( 'glRotated' );
  dllRotated( angle, x, y, z );
end;
procedure logRotatef (angle, x, y, z: TGLfloat); stdcall;
begin
  SIG( 'glRotatef' );
  dllRotatef( angle, x, y, z );
end;
procedure logScaled (x, y, z: TGLdouble); stdcall;
begin
  SIG( 'glScaled' );
  dllScaled( x, y, z );
end;
procedure logScalef (x, y, z: TGLfloat); stdcall;
begin
  SIG( 'glScalef' );
  dllScalef( x, y, z );
end;
procedure logScissor (x, y: TGLint; width, height: TGLsizei); stdcall;
begin
  SIG( 'glScissor' );
  dllScissor( x, y, width, height );
end;
procedure logSelectBuffer (size: TGLsizei; buffer: PGLuint); stdcall;
begin
  SIG( 'glSelectBuffer' );
  dllSelectBuffer( size, buffer );
end;
procedure logShadeModel (mode: TGLenum); stdcall;
begin
  SIG( 'glShadeModel' );
  dllShadeModel( mode );
end;
procedure logStencilFunc (func: TGLenum; ref: TGLint; mask: TGLuint); stdcall;
begin
  SIG( 'glStencilFunc' );
  dllStencilFunc( func, ref, mask );
end;
procedure logStencilMask (mask: TGLuint); stdcall;
begin
  SIG( 'glStencilMask' );
  dllStencilMask( mask );
end;
procedure logStencilOp (fail, zfail, zpass: TGLenum); stdcall;
begin
  SIG( 'glStencilOp' );
  dllStencilOp( fail, zfail, zpass );
end;
procedure logTexCoord1d (s: TGLdouble); stdcall;
begin
  SIG( 'glTexCoord1d' );
  dllTexCoord1d( s );
end;
procedure logTexCoord1dv (v: PGLdouble); stdcall;
begin
  SIG( 'glTexCoord1dv' );
  dllTexCoord1dv( v );
end;
procedure logTexCoord1f (s: TGLfloat); stdcall;
begin
  SIG( 'glTexCoord1f' );
  dllTexCoord1f( s );
end;
procedure logTexCoord1fv (v: PGLfloat); stdcall;
begin
  SIG( 'glTexCoord1fv' );
  dllTexCoord1fv( v );
end;
procedure logTexCoord1i (s: TGLint); stdcall;
begin
  SIG( 'glTexCoord1i' );
  dllTexCoord1i( s );
end;
procedure logTexCoord1iv (v: PGLint); stdcall;
begin
  SIG( 'glTexCoord1iv' );
  dllTexCoord1iv( v );
end;
procedure logTexCoord1s (s: TGLshort); stdcall;
begin
  SIG( 'glTexCoord1s' );
  dllTexCoord1s( s );
end;
procedure logTexCoord1sv (v: PGLshort); stdcall;
begin
  SIG( 'glTexCoord1sv' );
  dllTexCoord1sv( v );
end;
procedure logTexCoord2d (s, t: TGLdouble); stdcall;
begin
  SIG( 'glTexCoord2d' );
  dllTexCoord2d( s, t );
end;
procedure logTexCoord2dv (v: PGLdouble); stdcall;
begin
  SIG( 'glTexCoord2dv' );
  dllTexCoord2dv( v );
end;
procedure logTexCoord2f (s, t: TGLfloat); stdcall;
begin
  SIG( 'glTexCoord2f' );
  dllTexCoord2f( s, t );
end;
procedure logTexCoord2fv (v: PGLfloat); stdcall;
begin
  SIG( 'glTexCoord2fv' );
  dllTexCoord2fv( v );
end;
procedure logTexCoord2i (s, t: TGLint); stdcall;
begin
  SIG( 'glTexCoord2i' );
  dllTexCoord2i( s, t );
end;
procedure logTexCoord2iv (v: PGLint); stdcall;
begin
  SIG( 'glTexCoord2iv' );
  dllTexCoord2iv( v );
end;
procedure logTexCoord2s (s, t: TGLshort); stdcall;
begin
  SIG( 'glTexCoord2s' );
  dllTexCoord2s( s, t );
end;
procedure logTexCoord2sv (v: PGLshort); stdcall;
begin
  SIG( 'glTexCoord2sv' );
  dllTexCoord2sv( v );
end;
procedure logTexCoord3d (s, t, r: TGLdouble); stdcall;
begin
  SIG( 'glTexCoord3d' );
  dllTexCoord3d( s, t, r );
end;
procedure logTexCoord3dv (v: PGLdouble); stdcall;
begin
  SIG( 'glTexCoord3dv' );
  dllTexCoord3dv( v );
end;
procedure logTexCoord3f (s, t, r: TGLfloat); stdcall;
begin
  SIG( 'glTexCoord3f' );
  dllTexCoord3f( s, t, r );
end;
procedure logTexCoord3fv (v: PGLfloat); stdcall;
begin
  SIG( 'glTexCoord3fv' );
  dllTexCoord3fv( v );
end;
procedure logTexCoord3i (s, t, r: TGLint); stdcall;
begin
  SIG( 'glTexCoord3i' );
  dllTexCoord3i( s, t, r );
end;
procedure logTexCoord3iv (v: PGLint); stdcall;
begin
  SIG( 'glTexCoord3iv' );
  dllTexCoord3iv( v );
end;
procedure logTexCoord3s (s, t, r: TGLshort); stdcall;
begin
  SIG( 'glTexCoord3s' );
  dllTexCoord3s( s, t, r );
end;
procedure logTexCoord3sv (v: PGLshort); stdcall;
begin
  SIG( 'glTexCoord3sv' );
  dllTexCoord3sv( v );
end;
procedure logTexCoord4d (s, t, r, q: TGLdouble); stdcall;
begin
  SIG( 'glTexCoord4d' );
  dllTexCoord4d( s, t, r, q );
end;
procedure logTexCoord4dv (v: PGLdouble); stdcall;
begin
  SIG( 'glTexCoord4dv' );
  dllTexCoord4dv( v );
end;
procedure logTexCoord4f (s, t, r, q: TGLfloat); stdcall;
begin
  SIG( 'glTexCoord4f' );
  dllTexCoord4f( s, t, r, q );
end;
procedure logTexCoord4fv (v: PGLfloat); stdcall;
begin
  SIG( 'glTexCoord4fv' );
  dllTexCoord4fv( v );
end;
procedure logTexCoord4i (s, t, r, q: TGLint); stdcall;
begin
  SIG( 'glTexCoord4i' );
  dllTexCoord4i( s, t, r, q );
end;
procedure logTexCoord4iv (v: PGLint); stdcall;
begin
  SIG( 'glTexCoord4iv' );
  dllTexCoord4iv( v );
end;
procedure logTexCoord4s (s, t, r, q: TGLshort); stdcall;
begin
  SIG( 'glTexCoord4s' );
  dllTexCoord4s( s, t, r, q );
end;
procedure logTexCoord4sv (v: PGLshort); stdcall;
begin
  SIG( 'glTexCoord4sv' );
  dllTexCoord4sv( v );
end;
procedure logTexCoordPointer (size: TGLint; atype: TGLenum; stride: TGLsizei; pointer: Pointer); stdcall;
begin
  SIG ('glTexCoordPointer');
  dllTexCoordPointer (size, atype, stride, pointer);
end;
procedure logTexEnvf (target: TGLenum; pname: TGLenum; param: TGLfloat); stdcall;
begin
//  fprintf( glw_state.log_fp, 'glTexEnvf( 0x%x, 0x%x, %f )\n', target, pname, param );
  SIG2 ('glTexEnvf (0x%x, 0x%x, %f)\n', [target, pname, param]);
  dllTexEnvf (target, pname, param);
end;
procedure logTexEnvfv (target: TGLenum; pname: TGLenum; params: PGLfloat); stdcall;
begin
  SIG( 'glTexEnvfv' );
  dllTexEnvfv( target, pname, params );
end;
procedure logTexEnvi (target: TGLenum; pname: TGLenum; param: TGLint); stdcall;
begin
//  fprintf( glw_state.log_fp, 'glTexEnvi( 0x%x, 0x%x, 0x%x )\n', target, pname, param );
  SIG2 ('glTexEnvi (0x%x, 0x%x, 0x%x)\n', [target, pname, param]);
  dllTexEnvi (target, pname, param);
end;
procedure logTexEnviv (target: TGLenum; pname: TGLenum; params: PGLint); stdcall;
begin
  SIG( 'glTexEnviv' );
  dllTexEnviv( target, pname, params );
end;
procedure logTexGend (coord: TGLenum; pname: TGLenum; param: TGLdouble); stdcall;
begin
  SIG( 'glTexGend' );
  dllTexGend( coord, pname, param );
end;
procedure logTexGendv (coord: TGLenum; pname: TGLenum; params: PGLdouble); stdcall;
begin
  SIG( 'glTexGendv' );
  dllTexGendv( coord, pname, params );
end;
procedure logTexGenf (coord: TGLenum; pname: TGLenum; param: TGLfloat); stdcall;
begin
  SIG( 'glTexGenf' );
  dllTexGenf( coord, pname, param );
end;
procedure logTexGenfv (coord: TGLenum; pname: TGLenum; params: PGLfloat); stdcall;
begin
  SIG( 'glTexGenfv' );
  dllTexGenfv( coord, pname, params );
end;
procedure logTexGeni (coord: TGLenum; pname: TGLenum; param: TGLint); stdcall;
begin
  SIG( 'glTexGeni' );
  dllTexGeni( coord, pname, param );
end;
procedure logTexGeniv (coord: TGLenum; pname: TGLenum; params: PGLint); stdcall;
begin
  SIG( 'glTexGeniv' );
  dllTexGeniv( coord, pname, params );
end;
procedure logTexImage1D (target: TGLenum; level, internalformat: TGLint; width: TGLsizei; border: TGLint; format, atype: TGLenum; pixels: Pointer); stdcall;
begin
  SIG ('glTexImage1D');
  dllTexImage1D (target, level, internalformat, width, border, format, atype, pixels);
end;
procedure logTexImage2D (target: TGLenum; level, internalformat: TGLint; width, height: TGLsizei; border: TGLint; format, atype: TGLenum; pixels: Pointer); stdcall;
begin
  SIG ('glTexImage2D');
  dllTexImage2D (target, level, internalformat, width, height, border, format, atype, pixels);
end;
procedure logTexParameterf (target: TGLenum; pname: TGLenum; param: TGLfloat); stdcall;
begin
//  fprintf( glw_state.log_fp, 'glTexParameterf( 0x%x, 0x%x, %f )\n', target, pname, param );
  SIG2 ('glTexParameterf (0x%x, 0x%x, %f)\n', [target, pname, param]);
  dllTexParameterf (target, pname, param);
end;
procedure logTexParameterfv (target: TGLenum; pname: TGLenum; params: PGLfloat); stdcall;
begin
  SIG( 'glTexParameterfv' );
  dllTexParameterfv( target, pname, params );
end;
procedure logTexParameteri (target: TGLenum; pname: TGLenum; param: TGLint); stdcall;
begin
//  fprintf( glw_state.log_fp, 'glTexParameteri( 0x%x, 0x%x, 0x%x )\n', target, pname, param );
  SIG2 ('glTexParameteri (0x%x, 0x%x, 0x%x)\n', [target, pname, param]);
  dllTexParameteri (target, pname, param);
end;
procedure logTexParameteriv (target: TGLenum; pname: TGLenum; params: PGLint); stdcall;
begin
  SIG( 'glTexParameteriv' );
  dllTexParameteriv( target, pname, params );
end;
procedure logTexSubImage1D (target: TGLenum; level, xoffset: TGLint; width: TGLsizei; format, atype: TGLenum; pixels: Pointer); stdcall;
begin
  SIG ('glTexSubImage1D');
  dllTexSubImage1D (target, level, xoffset, width, format, atype, pixels);
end;
procedure logTexSubImage2D (target: TGLenum; level, xoffset, yoffset: TGLint; width, height: TGLsizei; format, atype: TGLenum; pixels: Pointer); stdcall;
begin
  SIG ('glTexSubImage2D');
  dllTexSubImage2D (target, level, xoffset, yoffset, width, height, format, atype, pixels);
end;
procedure logTranslated (x, y, z: TGLdouble); stdcall;
begin
  SIG( 'glTranslated' );
  dllTranslated( x, y, z );
end;
procedure logTranslatef (x, y, z: TGLfloat); stdcall;
begin
  SIG( 'glTranslatef' );
  dllTranslatef( x, y, z );
end;
procedure logVertex2d (x, y: TGLdouble); stdcall;
begin
  SIG( 'glVertex2d' );
  dllVertex2d( x, y );
end;
procedure logVertex2dv (v: PGLdouble); stdcall;
begin
  SIG( 'glVertex2dv' );
  dllVertex2dv( v );
end;
procedure logVertex2f (x, y: TGLfloat); stdcall;
begin
  SIG( 'glVertex2f' );
  dllVertex2f( x, y );
end;
procedure logVertex2fv (v: PGLfloat); stdcall;
begin
  SIG( 'glVertex2fv' );
  dllVertex2fv( v );
end;
procedure logVertex2i (x, y: TGLint); stdcall;
begin
  SIG( 'glVertex2i' );
  dllVertex2i( x, y );
end;
procedure logVertex2iv (v: PGLint); stdcall;
begin
  SIG( 'glVertex2iv' );
  dllVertex2iv( v );
end;
procedure logVertex2s (x, y: TGLshort); stdcall;
begin
  SIG( 'glVertex2s' );
  dllVertex2s( x, y );
end;
procedure logVertex2sv (v: PGLshort); stdcall;
begin
  SIG( 'glVertex2sv' );
  dllVertex2sv( v );
end;
procedure logVertex3d (x, y, z: TGLdouble); stdcall;
begin
  SIG( 'glVertex3d' );
  dllVertex3d( x, y, z );
end;
procedure logVertex3dv (v: PGLdouble); stdcall;
begin
  SIG( 'glVertex3dv' );
  dllVertex3dv( v );
end;
procedure logVertex3f (x, y, z: TGLfloat); stdcall;
begin
  SIG( 'glVertex3f' );
  dllVertex3f( x, y, z );
end;
procedure logVertex3fv (v: PGLfloat); stdcall;
begin
  SIG( 'glVertex3fv' );
  dllVertex3fv( v );
end;
procedure logVertex3i (x, y, z: TGLint); stdcall;
begin
  SIG( 'glVertex3i' );
  dllVertex3i( x, y, z );
end;
procedure logVertex3iv (v: PGLint); stdcall;
begin
  SIG( 'glVertex3iv' );
  dllVertex3iv( v );
end;
procedure logVertex3s (x, y, z: TGLshort); stdcall;
begin
  SIG( 'glVertex3s' );
  dllVertex3s( x, y, z );
end;
procedure logVertex3sv (v: PGLshort); stdcall;
begin
  SIG( 'glVertex3sv' );
  dllVertex3sv( v );
end;
procedure logVertex4d (x, y, z, w: TGLdouble); stdcall;
begin
  SIG( 'glVertex4d' );
  dllVertex4d( x, y, z, w );
end;
procedure logVertex4dv (v: PGLdouble); stdcall;
begin
  SIG( 'glVertex4dv' );
  dllVertex4dv( v );
end;
procedure logVertex4f (x, y, z, w: TGLfloat); stdcall;
begin
  SIG( 'glVertex4f' );
  dllVertex4f( x, y, z, w );
end;
procedure logVertex4fv (v: PGLfloat); stdcall;
begin
  SIG( 'glVertex4fv' );
  dllVertex4fv( v );
end;
procedure logVertex4i (x, y, z, w: TGLint); stdcall;
begin
  SIG( 'glVertex4i' );
  dllVertex4i( x, y, z, w );
end;
procedure logVertex4iv (v: PGLint); stdcall;
begin
  SIG( 'glVertex4iv' );
  dllVertex4iv( v );
end;
procedure logVertex4s (x, y, z, w: TGLshort); stdcall;
begin
  SIG( 'glVertex4s' );
  dllVertex4s( x, y, z, w );
end;
procedure logVertex4sv (v: PGLshort); stdcall;
begin
  SIG( 'glVertex4sv' );
  dllVertex4sv( v );
end;
procedure logVertexPointer (size: TGLint; atype: TGLenum; stride: TGLsizei; pointer: Pointer); stdcall;
begin
  SIG ('glVertexPointer');
  dllVertexPointer (size, atype, stride, pointer);
end;
procedure logViewport (x, y: TGLint; width, height: TGLsizei); stdcall;
begin
  SIG ('glViewport');
  dllViewport (x, y, width, height);
end;



{
//Y: my comments
 - logColor4fv
 - SIG2: check params
 - ri.Con_Printf (PRINT_ALL, '%s\n', <PChar>);
}

