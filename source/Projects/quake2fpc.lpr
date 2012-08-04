{
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                     Quake 2 Freepascal Port

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


--------------------------------------------------------------------------------
  FPC (freepascal) port:
--------------------------------------------------------------------------------

 Notes regarding freepascal port:
--------------------------------------------------------------------------------



 - Notes for freepascal port:


    The known problems with freepascal are:

   - In freepascal exe, the game introduction video won't play?

   - In freepascal exe, the game menu system graphics are a bit distrupted,
     i.e. you can see through the menu screen to the quake command area?

   - In freepascal version, the game won't play?


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

}
program quake2FPC;

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

uses
  SysUtils,

  sys_linux   in '../linux/sys_linux.pas',
  vid_so      in '../linux/vid_so.pas',
  //snd_linux   in '../linux/snd_linux.pas',
  snd_sdl     in '../linux/snd_sdl.pas',
  in_linux    in '../linux/in_linux.pas',
  q_shlinux   in '../linux/q_shlinux.pas',
  net_udp     in '../linux/net_udp.pas',
  //cd_linux    in '../linux/cd_linux.pas',
  cd_sdl      in '../linux/cd_sdl.pas',
  vid_menu    in '../linux/vid_menu.pas',
  glob        in '../linux/glob.pas',
  rw_linux_h  in '../linux/rw_linux_h.pas',
  qfiles      in '../qcommon/qfiles.pas',
  crc         in '../qcommon/crc.pas',
  CPas        in '../qcommon/CPas.pas',
  cmd         in '../qcommon/cmd.pas',
  Common      in '../qcommon/Common.pas',
  CVar        in '../qcommon/CVar.pas',
  Files       in '../qcommon/Files.pas',
  CModel      in '../qcommon/CModel.pas',
  MD4         in '../qcommon/MD4.pas',
  PMoveUnit   in '../qcommon/PMoveUnit.pas',
  net_chan    in '../qcommon/net_chan.pas',
  Delphi_cdecl_printf in '../qcommon/Delphi_cdecl_printf.pas',
  q_shared    in '../game/q_shared.pas',
  m_flash     in '../game/m_flash.pas',
  GameUnit    in '../game/GameUnit.pas',
  cl_main     in '../client/cl_main.pas',
  Client      in '../client/Client.pas',
  ref         in '../client/ref.pas',
  menu        in '../client/menu.pas',
  Sound_h     in '../client/Sound_h.pas',
  Console     in '../client/Console.pas',
  cl_scrn     in '../client/cl_scrn.pas',
  vid_h       in '../client/vid_h.pas',
  keys        in '../client/keys.pas',
  snd_loc     in '../client/snd_loc.pas',
  cl_input    in '../client/cl_input.pas',
  cl_cin      in '../client/cl_cin.pas',
  snd_dma     in '../client/snd_dma.pas',
  cl_ents     in '../client/cl_ents.pas',
  cl_pred     in '../client/cl_pred.pas',
  cl_view     in '../client/cl_view.pas',
  cl_parse    in '../client/cl_parse.pas',
  Qmenu       in '../client/Qmenu.pas',
  cl_tent     in '../client/cl_tent.pas',
  cl_fx       in '../client/cl_fx.pas',
  cl_newfx    in '../client/cl_newfx.pas',
  snd_mix     in '../client/snd_mix.pas',
  snd_mem     in '../client/snd_mem.pas',
  cl_inv      in '../client/cl_inv.pas',
  server      in '../server/server.pas',
  sv_game     in '../server/sv_game.pas',
  sv_init     in '../server/sv_init.pas',
  sv_ccmds    in '../server/sv_ccmds.pas',
  Sv_main     in '../server/sv_main.pas',
  sv_send     in '../server/sv_send.pas',
  sv_ents     in '../server/sv_ents.pas',
  sv_user     in '../server/sv_user.pas',
  sv_world    in '../server/sv_world.pas',
  DelphiTypes in '../qcommon/DelphiTypes.pas',
  q_shared_add in '../game/q_shared_add.pas',
  game_add     in '../game/game_add.pas';



{$R *.res}


{$INCLUDE ../Jedi.inc}



var
  Saved8087CW: Word;
  CommandLine: String;
  i: Integer;
begin
  { Save the current FPU state and then disable FPU exceptions }
  Saved8087CW := Default8087CW;
  Set8087CW($133f); { Disable all fpu exceptions }

  { Juha:
    We can't use CmdLine variable here, because we should not include the
    executable name, so we need to build one here }
  for i := 1 to ParamCount do
    CommandLine := CommandLine + ' ' + ParamStr(i) ;
  CommandLine := Trim(CommandLine);



  Main ( i , PChar(CommandLine));


  { Reset the FPU to the previous state }
  Set8087CW(Saved8087CW);
end.
