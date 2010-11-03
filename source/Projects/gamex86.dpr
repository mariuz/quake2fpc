(*

   Delphi conversion of gamex86.dll quake2 game module.

   In case you want to debug this module you need to set the host application
   to quake2d.exe (or to original quake2.exe) and set command line parameter to:
   +set basedir c:\games\quake2\ +set gamedir c:\games\quake2\baseq2\

*)

{ List of Code Reviewed Units:                                               }
{ ============================                                               }
{ g_combat.pas:  Reviewed... 100%.  Marked 100%                              }
{ g_chase.pas:  Reviewed... 100%.  Marked 100%                               }
{ g_cmds.pas                                                                 }
{ g_ai.pas                                                                   }
{ g_func.pas                                                                 }
{ g_items.pas                                                                }
{ g_local.pas:  Carl A Kenner (100%)                                         }
{ g_local_add.pas:  Juha (100%).  Added header and 100% Mark                 }
{ g_main.pas:  Reviewed... 100%.  Marked 100%                                }
{ g_misc.pas                                                                 }
{ g_monster.pas:  Reviewed... 100%.  Marked 100%                             }
{ g_phys.pas                                                                 }
{ g_save.pas:  Reveied... 100%.  Marked 100%, some possible load/save issues }
{                                require investigation still                 }
{ g_spawn.pas:  Reviewed... 100%.  Marked 100%                               }
{ g_svcmds.pas:  Reviewed... 100%.  Marked 100%                              }
{ g_target.pas                                                               }
{ g_trigger.pas:  Reviewed... 100%.  Marked 100%                             }
{ g_turret.pas:  Reviewed... 100%.  Marked 100%                              }
{ g_utils.pas:  Reviewed... 100%.  Marked 100%                               }
{ g_weapon.pas                                                               }
{ game_add.pas:  Juha (100%).  Added header and 100% Mark                    }
{ GameUnit.pas:  Reviewed... 100%.  Marked 100%                              }
{ m_actor.inc                                                                }
{ m_actor.pas                                                                }
{ m_berserk.inc                                                              }
{ m_berserk.pas                                                              }
{ m_boss2.inc                                                                }
{ m_boss2.pas                                                                }
{ m_boss3.pas:  Reviewed... 100%.  Marked 100%                               }
{ m_boss31.inc                                                               }
{ m_boss31.pas                                                               }
{ m_boss32.inc                                                               }
{ m_boss32.pas                                                               }
{ m_brain.inc                                                                }
{ m_brain.pas                                                                }
{ m_chick.inc                                                                }
{ m_chick.pas                                                                }
{ m_flash.pas:  Yarik (100%)                                                 }
{ m_flipper.inc                                                              }
{ m_flipper.pas:  Reviewed... 100%.  Marked 100%                             }
{ m_float.inc                                                                }
{ m_float.pas                                                                }
{ m_flyer.inc                                                                }
{ m_flyer.pas                                                                }
{ m_gladiator.inc:  Not referenced in m_gladiator.pas                        }
{ m_gladiator.pas:  Reviewed... 100%.  Marked 100%                           }
{ m_gunner.pas                                                               }
{ m_hover.inc                                                                }
{ m_hover.pas                                                                }
{ m_infantry.inc                                                             }
{ m_infantry.pas                                                             }
{ m_insane.pas                                                               }
{ m_medic.inc                                                                }
{ m_medic.pas                                                                }
{ m_move.pas:  Reviewed... 100%  - Marked 100%                               }
{ m_mutant.pas                                                               }
{ m_parasite.pas                                                             }
{ m_player.pas:  Reviewed... 100%.  Marked 100%                              }
{ m_soldier.inc                                                              }
{ m_soldier.pas                                                              }
{ m_supertank.inc                                                            }
{ m_supertank.pas                                                            }
{ m_tank.inc                                                                 }
{ m_tank.pas                                                                 }
{ p_client.pas:  Reviewed... 100% - Marked 98% (CTF Not Reviewed)            }
{ p_hud.pas:  Reviewed... 100%                                               }
{ p_trail.pas:  Clootie (100%)                                               }
{ p_view.pas:  Reviewed... 100%                                              }
{ p_weapon.pas:  Reviewed... 100%                                            }
{ q_shared.pas:  Savage (100%)                                               }
{ q_shared_add.pas:  Juha (100%).  Added header and 100% Mark                }
{                                                                            }

library gamex86;



uses
  CPas in '..\qcommon\CPas.pas',
  g_local in '..\game\g_local.pas',
  q_shared in '..\game\q_shared.pas',
  GameUnit in '..\game\GameUnit.pas',
  g_svcmds in '..\game\g_svcmds.pas',
  g_cmds in '..\game\g_cmds.pas',
  g_save in '..\game\g_save.pas',
  g_chase in '..\game\g_chase.pas',
  g_items in '..\game\g_items.pas',
  g_utils in '..\game\g_utils.pas',
  g_main in '..\game\g_main.pas',
  p_hud in '..\game\p_hud.pas',
  m_player in '..\game\m_player.pas',
  g_ai in '..\game\g_ai.pas',
  g_combat in '..\game\g_combat.pas',
  g_func in '..\game\g_func.pas',
  g_misc in '..\game\g_misc.pas',
  g_monster in '..\game\g_monster.pas',
  g_weapon in '..\game\g_weapon.pas',
  g_spawn in '..\game\g_spawn.pas',
  g_target in '..\game\g_target.pas',
  g_trigger in '..\game\g_trigger.pas',
  g_turret in '..\game\g_turret.pas',
  g_phys in '..\game\g_phys.pas',
  p_view in '..\game\p_view.pas',
  m_berserk in '..\game\m_berserk.pas',
  m_boss2 in '..\game\m_boss2.pas',
  m_boss3 in '..\game\m_boss3.pas',
  m_boss31 in '..\game\m_boss31.pas',
  m_boss32 in '..\game\m_boss32.pas',
  m_brain in '..\game\m_brain.pas',
  m_chick in '..\game\m_chick.pas',
  m_flash in '..\game\m_flash.pas',
  m_flipper in '..\game\m_flipper.pas',
  m_float in '..\game\m_float.pas',
  m_flyer in '..\game\m_flyer.pas',
  m_gladiator in '..\game\m_gladiator.pas',
  m_gunner in '..\game\m_gunner.pas',
  m_hover in '..\game\m_hover.pas',
  m_infantry in '..\game\m_infantry.pas',
  m_insane in '..\game\m_insane.pas',
  m_medic in '..\game\m_medic.pas',
  m_move in '..\game\m_move.pas',
  m_mutant in '..\game\m_mutant.pas',
  m_parasite in '..\game\m_parasite.pas',
  m_soldier in '..\game\m_soldier.pas',
  m_supertank in '..\game\m_supertank.pas',
  m_tank in '..\game\m_tank.pas',
  p_client in '..\game\p_client.pas',
  p_trail in '..\game\p_trail.pas',
  p_weapon in '..\game\p_weapon.pas',
  m_actor in '..\game\m_actor.pas',
  q_shared_add in '..\game\q_shared_add.pas',
  DelphiTypes in '..\qcommon\DelphiTypes.pas',
  g_local_add in '..\game\g_local_add.pas',
  game_add in '..\game\game_add.pas';

{$R *.res}

exports
  GetGameAPI name 'GetGameAPI';

begin
end.
