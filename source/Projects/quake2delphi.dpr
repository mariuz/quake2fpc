{
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                     Quake 2 Freepascal/Delphi Port

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


--------------------------------------------------------------------------------
  FPC (freepascal) port:
--------------------------------------------------------------------------------

  Lars (L505) started the FPC port as an experiment, along with the DOOM
  to freepascal port to see if FPC could compile lots of Delphi/C language
  originating code.
  

  More info might be found at these websites:

  Delphi port:
    http://www.sulaco.co.za/Quake2/

  FPC port:
    http://z505.com


--------------------------------------------------------------------------------
  Contributors to Delphi port:
--------------------------------------------------------------------------------

  More info at http://www.sulaco.co.za/Quake2/

--------------------------------------------------------------------------------
 Notes regarding freepascal port:
--------------------------------------------------------------------------------

 - this project should now be called the Quake 2 Delphi/FPC port. because
   it compiles on both compilers now. If you work on this project, please
   have a copy of FPC and delphi open so you can compile side by side.. rather
   than making it specific to freepascal! thanks..

 - Notes for freepascal port:

   Quake2Delphi.exe runs fine with DEMO quake files (pak)
   Quake2FPC.exe runs the game menu, but won't play

   L505: I've made the source code so that it should compile under both Delphi
         and freepascal using ifdefs.

    The known problems with freepascal are:

   - In freepascal exe, the game introduction video won't play?

   - In freepascal exe, the game menu system graphics are a bit distrupted,
     i.e. you can see through the menu screen to the quake command area?

   - In freepascal version, the game won't play?

   - I don't know what the problem is, because this is basically exactly the
     same source code being compiled on two compilers side by side.

   - Also, see the DOOM to FreePascal port I worked on. The freepascal version
     of DOOM doesn't display graphics correctly, but the game does play.

   - Also note that in the Quake2Freepascal port, there are no keyboard
     "molasses" issues in the menu system, whereas in the Doom to Freepascal
     port, there were (slow keboard response).



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

}
program quake2Delphi;

uses
  SysUtils,
  {$IFDEF WIN32}
  sys_win   in '..\win32\sys_win.pas',
  vid_dll   in '..\win32\vid_dll.pas',
  snd_win   in '..\win32\snd_win.pas',
  in_win    in '..\win32\in_win.pas',
  q_shwin   in '..\win32\q_shwin.pas',
  net_wins  in '..\win32\net_wins.pas',
  cd_win    in '..\win32\cd_win.pas',
  vid_menu  in '..\win32\vid_menu.pas',
  ConProc   in '..\win32\ConProc.pas',
  qfiles    in '..\qcommon\qfiles.pas',
  crc       in '..\qcommon\crc.pas',
  CPas      in '..\qcommon\CPas.pas',
  cmd       in '..\qcommon\cmd.pas',
  Common    in '..\qcommon\Common.pas',
  CVar      in '..\qcommon\CVar.pas',
  Files     in '..\qcommon\Files.pas',
  CModel    in '..\qcommon\CModel.pas',
  MD4       in '..\qcommon\MD4.pas',
  PMoveUnit in '..\qcommon\PMoveUnit.pas',
  net_chan  in '..\qcommon\net_chan.pas',
  Delphi_cdecl_printf in '..\qcommon\Delphi_cdecl_printf.pas',
  q_shared  in '..\game\q_shared.pas',
  m_flash   in '..\game\m_flash.pas',
  GameUnit  in '..\game\GameUnit.pas',
  cl_main   in '..\client\cl_main.pas',
  Client    in '..\client\Client.pas',
  ref       in '..\client\ref.pas',
  menu      in '..\client\menu.pas',
  Sound_h   in '..\client\Sound_h.pas',
  Console   in '..\client\Console.pas',
  cl_scrn   in '..\client\cl_scrn.pas',
  vid_h     in '..\client\vid_h.pas',
  keys      in '..\client\keys.pas',
  snd_loc   in '..\client\snd_loc.pas',
  cl_input  in '..\client\cl_input.pas',
  cl_cin    in '..\client\cl_cin.pas',
  snd_dma   in '..\client\snd_dma.pas',
  cl_ents   in '..\client\cl_ents.pas',
  cl_pred   in '..\client\cl_pred.pas',
  cl_view   in '..\client\cl_view.pas',
  cl_parse  in '..\client\cl_parse.pas',
  Qmenu     in '..\client\Qmenu.pas',
  cl_tent   in '..\client\cl_tent.pas',
  cl_fx     in '..\client\cl_fx.pas',
  cl_newfx  in '..\client\cl_newfx.pas',
  snd_mix   in '..\client\snd_mix.pas',
  snd_mem   in '..\client\snd_mem.pas',
  cl_inv    in '..\client\cl_inv.pas',
  server    in '..\server\server.pas',
  sv_game   in '..\server\sv_game.pas',
  sv_init   in '..\server\sv_init.pas',
  sv_ccmds  in '..\server\sv_ccmds.pas',
  Sv_main   in '..\server\sv_main.pas',
  sv_send   in '..\server\sv_send.pas',
  sv_ents   in '..\server\sv_ents.pas',
  sv_user   in '..\server\sv_user.pas',
  sv_world  in '..\server\sv_world.pas',
  DelphiTypes  in '..\qcommon\DelphiTypes.pas',
  q_shared_add in '..\game\q_shared_add.pas',
  game_add     in '..\game\game_add.pas';

  {$ELSE}
  // This is for the Linux - Kylix part
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

  {$ENDIF}

{$R *.res}

{$IFDEF WIN32}
{$INCLUDE ..\Jedi.inc}
{$ELSE}
{$INCLUDE ../Jedi.inc}
{$ENDIF}


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
  {$IFDEF COMPILER6_UP}{$WARN SYMBOL_PLATFORM OFF}{$WARN SYMBOL_DEPRECATED OFF}{$ENDIF}

  {$IFDEF WIN32}
  WinMain( hInstance, hPrevInst, PChar(CommandLine), CmdShow );
  {$ELSE}
  Main ( i , PChar(CommandLine));
  {$ENDIF}

  {$IFDEF COMPILER6_UP}{$WARN SYMBOL_PLATFORM ON}{$WARN SYMBOL_DEPRECATED ON}{$ENDIF}

  { Reset the FPU to the previous state }
  Set8087CW(Saved8087CW);
end.
