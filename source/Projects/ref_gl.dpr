(*
   Delphi conversion of ref_gl OpenGL renderer of Quake2
*)
library ref_gl;

uses
  Cpas in '..\qcommon\Cpas.pas',
  DelphiTypes in '..\qcommon\DelphiTypes.pas',
  q_shared in '..\game\q_shared.pas',
  q_shared_add in '..\game\q_shared_add.pas',
  gl_local in '..\ref_gl\gl_local.pas',
  gl_model_h in '..\ref_gl\gl_model_h.pas',
  qgl_h in '..\ref_gl\qgl_h.pas',
  gl_draw in '..\ref_gl\gl_draw.pas',
  glw_imp in '..\win32\glw_imp.pas',
  q_shwin in '..\win32\q_shwin.pas',
  glw_win in '..\win32\glw_win.pas',
  QFiles in '..\qcommon\qfiles.pas',
  ref in '..\client\ref.pas',
  gl_image in '..\ref_gl\gl_image.pas',
  gl_model in '..\ref_gl\gl_model.pas',
  gl_light in '..\ref_gl\gl_light.pas',
  gl_warp in '..\ref_gl\gl_warp.pas',
  gl_rmain in '..\ref_gl\gl_rmain.pas',
  gl_rsurf in '..\ref_gl\gl_rsurf.pas',
  gl_rmisc in '..\ref_gl\gl_rmisc.pas',
  gl_mesh in '..\ref_gl\gl_mesh.pas',
  qgl_win in '..\win32\qgl_win.pas',
  gl_local_add in '..\ref_gl\gl_local_add.pas';

{$R *.res}

exports
  GetRefAPI name 'GetRefAPI';

begin
end.
