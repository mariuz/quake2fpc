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
{ File(s): m_soldier.h                                                       }
{                                                                            }
{ Initial conversion by : Ben Watt (ben@delphigamedev.com)                   }
{ Initial conversion on : 04-Feb-2002                                        }
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
{ 1.) g_local.h and game.h                                                   }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{ 1.) test compilation with the above two units                              }
{----------------------------------------------------------------------------}
{
==============================================================================

SOLDIER

==============================================================================
}

unit m_soldier;

interface

uses
  g_local,
  q_shared;

const
  MODEL_SCALE     = 1.200000;

  FRAME_attak101           = 0;
  FRAME_attak102           = 1;
  FRAME_attak103           = 2;
  FRAME_attak104           = 3;
  FRAME_attak105           = 4;
  FRAME_attak106           = 5;
  FRAME_attak107           = 6;
  FRAME_attak108           = 7;
  FRAME_attak109           = 8;
  FRAME_attak110           = 9;
  FRAME_attak111           = 10;
  FRAME_attak112           = 11;
  FRAME_attak201           = 12;
  FRAME_attak202           = 13;
  FRAME_attak203           = 14;
  FRAME_attak204           = 15;
  FRAME_attak205           = 16;
  FRAME_attak206           = 17;
  FRAME_attak207           = 18;
  FRAME_attak208           = 19;
  FRAME_attak209           = 20;
  FRAME_attak210           = 21;
  FRAME_attak211           = 22;
  FRAME_attak212           = 23;
  FRAME_attak213           = 24;
  FRAME_attak214           = 25;
  FRAME_attak215           = 26;
  FRAME_attak216           = 27;
  FRAME_attak217           = 28;
  FRAME_attak218           = 29;
  FRAME_attak301           = 30;
  FRAME_attak302           = 31;
  FRAME_attak303           = 32;
  FRAME_attak304           = 33;
  FRAME_attak305           = 34;
  FRAME_attak306           = 35;
  FRAME_attak307           = 36;
  FRAME_attak308           = 37;
  FRAME_attak309           = 38;
  FRAME_attak401           = 39;
  FRAME_attak402           = 40;
  FRAME_attak403           = 41;
  FRAME_attak404           = 42;
  FRAME_attak405           = 43;
  FRAME_attak406           = 44;
  FRAME_duck01             = 45;
  FRAME_duck02             = 46;
  FRAME_duck03             = 47;
  FRAME_duck04             = 48;
  FRAME_duck05             = 49;
  FRAME_pain101            = 50;
  FRAME_pain102            = 51;
  FRAME_pain103            = 52;
  FRAME_pain104            = 53;
  FRAME_pain105            = 54;
  FRAME_pain201            = 55;
  FRAME_pain202            = 56;
  FRAME_pain203            = 57;
  FRAME_pain204            = 58;
  FRAME_pain205            = 59;
  FRAME_pain206            = 60;
  FRAME_pain207            = 61;
  FRAME_pain301            = 62;
  FRAME_pain302            = 63;
  FRAME_pain303            = 64;
  FRAME_pain304            = 65;
  FRAME_pain305            = 66;
  FRAME_pain306            = 67;
  FRAME_pain307            = 68;
  FRAME_pain308            = 69;
  FRAME_pain309            = 70;
  FRAME_pain310            = 71;
  FRAME_pain311            = 72;
  FRAME_pain312            = 73;
  FRAME_pain313            = 74;
  FRAME_pain314            = 75;
  FRAME_pain315            = 76;
  FRAME_pain316            = 77;
  FRAME_pain317            = 78;
  FRAME_pain318            = 79;
  FRAME_pain401            = 80;
  FRAME_pain402            = 81;
  FRAME_pain403            = 82;
  FRAME_pain404            = 83;
  FRAME_pain405            = 84;
  FRAME_pain406            = 85;
  FRAME_pain407            = 86;
  FRAME_pain408            = 87;
  FRAME_pain409            = 88;
  FRAME_pain410            = 89;
  FRAME_pain411            = 90;
  FRAME_pain412            = 91;
  FRAME_pain413            = 92;
  FRAME_pain414            = 93;
  FRAME_pain415            = 94;
  FRAME_pain416            = 95;
  FRAME_pain417            = 96;
  FRAME_run01              = 97;
  FRAME_run02              = 98;
  FRAME_run03              = 99;
  FRAME_run04              = 100;
  FRAME_run05              = 101;
  FRAME_run06              = 102;
  FRAME_run07              = 103;
  FRAME_run08              = 104;
  FRAME_run09              = 105;
  FRAME_run10              = 106;
  FRAME_run11              = 107;
  FRAME_run12              = 108;
  FRAME_runs01             = 109;
  FRAME_runs02             = 110;
  FRAME_runs03             = 111;
  FRAME_runs04             = 112;
  FRAME_runs05             = 113;
  FRAME_runs06             = 114;
  FRAME_runs07             = 115;
  FRAME_runs08             = 116;
  FRAME_runs09             = 117;
  FRAME_runs10             = 118;
  FRAME_runs11             = 119;
  FRAME_runs12             = 120;
  FRAME_runs13             = 121;
  FRAME_runs14             = 122;
  FRAME_runs15             = 123;
  FRAME_runs16             = 124;
  FRAME_runs17             = 125;
  FRAME_runs18             = 126;
  FRAME_runt01             = 127;
  FRAME_runt02             = 128;
  FRAME_runt03             = 129;
  FRAME_runt04             = 130;
  FRAME_runt05             = 131;
  FRAME_runt06             = 132;
  FRAME_runt07             = 133;
  FRAME_runt08             = 134;
  FRAME_runt09             = 135;
  FRAME_runt10             = 136;
  FRAME_runt11             = 137;
  FRAME_runt12             = 138;
  FRAME_runt13             = 139;
  FRAME_runt14             = 140;
  FRAME_runt15             = 141;
  FRAME_runt16             = 142;
  FRAME_runt17             = 143;
  FRAME_runt18             = 144;
  FRAME_runt19             = 145;
  FRAME_stand101           = 146;
  FRAME_stand102           = 147;
  FRAME_stand103           = 148;
  FRAME_stand104           = 149;
  FRAME_stand105           = 150;
  FRAME_stand106           = 151;
  FRAME_stand107           = 152;
  FRAME_stand108           = 153;
  FRAME_stand109           = 154;
  FRAME_stand110           = 155;
  FRAME_stand111           = 156;
  FRAME_stand112           = 157;
  FRAME_stand113           = 158;
  FRAME_stand114           = 159;
  FRAME_stand115           = 160;
  FRAME_stand116           = 161;
  FRAME_stand117           = 162;
  FRAME_stand118           = 163;
  FRAME_stand119           = 164;
  FRAME_stand120           = 165;
  FRAME_stand121           = 166;
  FRAME_stand122           = 167;
  FRAME_stand123           = 168;
  FRAME_stand124           = 169;
  FRAME_stand125           = 170;
  FRAME_stand126           = 171;
  FRAME_stand127           = 172;
  FRAME_stand128           = 173;
  FRAME_stand129           = 174;
  FRAME_stand130           = 175;
  FRAME_stand301           = 176;
  FRAME_stand302           = 177;
  FRAME_stand303           = 178;
  FRAME_stand304           = 179;
  FRAME_stand305           = 180;
  FRAME_stand306           = 181;
  FRAME_stand307           = 182;
  FRAME_stand308           = 183;
  FRAME_stand309           = 184;
  FRAME_stand310           = 185;
  FRAME_stand311           = 186;
  FRAME_stand312           = 187;
  FRAME_stand313           = 188;
  FRAME_stand314           = 189;
  FRAME_stand315           = 190;
  FRAME_stand316           = 191;
  FRAME_stand317           = 192;
  FRAME_stand318           = 193;
  FRAME_stand319           = 194;
  FRAME_stand320           = 195;
  FRAME_stand321           = 196;
  FRAME_stand322           = 197;
  FRAME_stand323           = 198;
  FRAME_stand324           = 199;
  FRAME_stand325           = 200;
  FRAME_stand326           = 201;
  FRAME_stand327           = 202;
  FRAME_stand328           = 203;
  FRAME_stand329           = 204;
  FRAME_stand330           = 205;
  FRAME_stand331           = 206;
  FRAME_stand332           = 207;
  FRAME_stand333           = 208;
  FRAME_stand334           = 209;
  FRAME_stand335           = 210;
  FRAME_stand336           = 211;
  FRAME_stand337           = 212;
  FRAME_stand338           = 213;
  FRAME_stand339           = 214;
  FRAME_walk101            = 215;
  FRAME_walk102            = 216;
  FRAME_walk103            = 217;
  FRAME_walk104            = 218;
  FRAME_walk105            = 219;
  FRAME_walk106            = 220;
  FRAME_walk107            = 221;
  FRAME_walk108            = 222;
  FRAME_walk109            = 223;
  FRAME_walk110            = 224;
  FRAME_walk111            = 225;
  FRAME_walk112            = 226;
  FRAME_walk113            = 227;
  FRAME_walk114            = 228;
  FRAME_walk115            = 229;
  FRAME_walk116            = 230;
  FRAME_walk117            = 231;
  FRAME_walk118            = 232;
  FRAME_walk119            = 233;
  FRAME_walk120            = 234;
  FRAME_walk121            = 235;
  FRAME_walk122            = 236;
  FRAME_walk123            = 237;
  FRAME_walk124            = 238;
  FRAME_walk125            = 239;
  FRAME_walk126            = 240;
  FRAME_walk127            = 241;
  FRAME_walk128            = 242;
  FRAME_walk129            = 243;
  FRAME_walk130            = 244;
  FRAME_walk131            = 245;
  FRAME_walk132            = 246;
  FRAME_walk133            = 247;
  FRAME_walk201            = 248;
  FRAME_walk202            = 249;
  FRAME_walk203            = 250;
  FRAME_walk204            = 251;
  FRAME_walk205            = 252;
  FRAME_walk206            = 253;
  FRAME_walk207            = 254;
  FRAME_walk208            = 255;
  FRAME_walk209            = 256;
  FRAME_walk210            = 257;
  FRAME_walk211            = 258;
  FRAME_walk212            = 259;
  FRAME_walk213            = 260;
  FRAME_walk214            = 261;
  FRAME_walk215            = 262;
  FRAME_walk216            = 263;
  FRAME_walk217            = 264;
  FRAME_walk218            = 265;
  FRAME_walk219            = 266;
  FRAME_walk220            = 267;
  FRAME_walk221            = 268;
  FRAME_walk222            = 269;
  FRAME_walk223            = 270;
  FRAME_walk224            = 271;
  FRAME_death101           = 272;
  FRAME_death102           = 273;
  FRAME_death103           = 274;
  FRAME_death104           = 275;
  FRAME_death105           = 276;
  FRAME_death106           = 277;
  FRAME_death107           = 278;
  FRAME_death108           = 279;
  FRAME_death109           = 280;
  FRAME_death110           = 281;
  FRAME_death111           = 282;
  FRAME_death112           = 283;
  FRAME_death113           = 284;
  FRAME_death114           = 285;
  FRAME_death115           = 286;
  FRAME_death116           = 287;
  FRAME_death117           = 288;
  FRAME_death118           = 289;
  FRAME_death119           = 290;
  FRAME_death120           = 291;
  FRAME_death121           = 292;
  FRAME_death122           = 293;
  FRAME_death123           = 294;
  FRAME_death124           = 295;
  FRAME_death125           = 296;
  FRAME_death126           = 297;
  FRAME_death127           = 298;
  FRAME_death128           = 299;
  FRAME_death129           = 300;
  FRAME_death130           = 301;
  FRAME_death131           = 302;
  FRAME_death132           = 303;
  FRAME_death133           = 304;
  FRAME_death134           = 305;
  FRAME_death135           = 306;
  FRAME_death136           = 307;
  FRAME_death201           = 308;
  FRAME_death202           = 309;
  FRAME_death203           = 310;
  FRAME_death204           = 311;
  FRAME_death205           = 312;
  FRAME_death206           = 313;
  FRAME_death207           = 314;
  FRAME_death208           = 315;
  FRAME_death209           = 316;
  FRAME_death210           = 317;
  FRAME_death211           = 318;
  FRAME_death212           = 319;
  FRAME_death213           = 320;
  FRAME_death214           = 321;
  FRAME_death215           = 322;
  FRAME_death216           = 323;
  FRAME_death217           = 324;
  FRAME_death218           = 325;
  FRAME_death219           = 326;
  FRAME_death220           = 327;
  FRAME_death221           = 328;
  FRAME_death222           = 329;
  FRAME_death223           = 330;
  FRAME_death224           = 331;
  FRAME_death225           = 332;
  FRAME_death226           = 333;
  FRAME_death227           = 334;
  FRAME_death228           = 335;
  FRAME_death229           = 336;
  FRAME_death230           = 337;
  FRAME_death231           = 338;
  FRAME_death232           = 339;
  FRAME_death233           = 340;
  FRAME_death234           = 341;
  FRAME_death235           = 342;
  FRAME_death301           = 343;
  FRAME_death302           = 344;
  FRAME_death303           = 345;
  FRAME_death304           = 346;
  FRAME_death305           = 347;
  FRAME_death306           = 348;
  FRAME_death307           = 349;
  FRAME_death308           = 350;
  FRAME_death309           = 351;
  FRAME_death310           = 352;
  FRAME_death311           = 353;
  FRAME_death312           = 354;
  FRAME_death313           = 355;
  FRAME_death314           = 356;
  FRAME_death315           = 357;
  FRAME_death316           = 358;
  FRAME_death317           = 359;
  FRAME_death318           = 360;
  FRAME_death319           = 361;
  FRAME_death320           = 362;
  FRAME_death321           = 363;
  FRAME_death322           = 364;
  FRAME_death323           = 365;
  FRAME_death324           = 366;
  FRAME_death325           = 367;
  FRAME_death326           = 368;
  FRAME_death327           = 369;
  FRAME_death328           = 370;
  FRAME_death329           = 371;
  FRAME_death330           = 372;
  FRAME_death331           = 373;
  FRAME_death332           = 374;
  FRAME_death333           = 375;
  FRAME_death334           = 376;
  FRAME_death335           = 377;
  FRAME_death336           = 378;
  FRAME_death337           = 379;
  FRAME_death338           = 380;
  FRAME_death339           = 381;
  FRAME_death340           = 382;
  FRAME_death341           = 383;
  FRAME_death342           = 384;
  FRAME_death343           = 385;
  FRAME_death344           = 386;
  FRAME_death345           = 387;
  FRAME_death401           = 388;
  FRAME_death402           = 389;
  FRAME_death403           = 390;
  FRAME_death404           = 391;
  FRAME_death405           = 392;
  FRAME_death406           = 393;
  FRAME_death407           = 394;
  FRAME_death408           = 395;
  FRAME_death409           = 396;
  FRAME_death410           = 397;
  FRAME_death411           = 398;
  FRAME_death412           = 399;
  FRAME_death413           = 400;
  FRAME_death414           = 401;
  FRAME_death415           = 402;
  FRAME_death416           = 403;
  FRAME_death417           = 404;
  FRAME_death418           = 405;
  FRAME_death419           = 406;
  FRAME_death420           = 407;
  FRAME_death421           = 408;
  FRAME_death422           = 409;
  FRAME_death423           = 410;
  FRAME_death424           = 411;
  FRAME_death425           = 412;
  FRAME_death426           = 413;
  FRAME_death427           = 414;
  FRAME_death428           = 415;
  FRAME_death429           = 416;
  FRAME_death430           = 417;
  FRAME_death431           = 418;
  FRAME_death432           = 419;
  FRAME_death433           = 420;
  FRAME_death434           = 421;
  FRAME_death435           = 422;
  FRAME_death436           = 423;
  FRAME_death437           = 424;
  FRAME_death438           = 425;
  FRAME_death439           = 426;
  FRAME_death440           = 427;
  FRAME_death441           = 428;
  FRAME_death442           = 429;
  FRAME_death443           = 430;
  FRAME_death444           = 431;
  FRAME_death445           = 432;
  FRAME_death446           = 433;
  FRAME_death447           = 434;
  FRAME_death448           = 435;
  FRAME_death449           = 436;
  FRAME_death450           = 437;
  FRAME_death451           = 438;
  FRAME_death452           = 439;
  FRAME_death453           = 440;
  FRAME_death501           = 441;
  FRAME_death502           = 442;
  FRAME_death503           = 443;
  FRAME_death504           = 444;
  FRAME_death505           = 445;
  FRAME_death506           = 446;
  FRAME_death507           = 447;
  FRAME_death508           = 448;
  FRAME_death509           = 449;
  FRAME_death510           = 450;
  FRAME_death511           = 451;
  FRAME_death512           = 452;
  FRAME_death513           = 453;
  FRAME_death514           = 454;
  FRAME_death515           = 455;
  FRAME_death516           = 456;
  FRAME_death517           = 457;
  FRAME_death518           = 458;
  FRAME_death519           = 459;
  FRAME_death520           = 460;
  FRAME_death521           = 461;
  FRAME_death522           = 462;
  FRAME_death523           = 463;
  FRAME_death524           = 464;
  FRAME_death601           = 465;
  FRAME_death602           = 466;
  FRAME_death603           = 467;
  FRAME_death604           = 468;
  FRAME_death605           = 469;
  FRAME_death606           = 470;
  FRAME_death607           = 471;
  FRAME_death608           = 472;
  FRAME_death609           = 473;
  FRAME_death610           = 474;

var
  sound_idle,
  sound_sight1,
  sound_sight2,
  sound_pain_light,
  sound_pain,
  sound_pain_ss,
  sound_death_light,
  sound_death,
  sound_death_ss,
  sound_cock           : Integer;

procedure soldier_idle(self : edict_p); cdecl;
procedure soldier_cock(self : edict_p); cdecl;
procedure soldier_stand(self : edict_p); cdecl;
procedure soldier_walk1_random(self : edict_p); cdecl;
procedure soldier_walk(self : edict_p); cdecl;
procedure soldier_run(self : edict_p); cdecl;
procedure soldier_pain (self, other : edict_p; kick : single; damage : integer); cdecl;
procedure soldier_fire(self : edict_p; flash_number : integer); cdecl;
procedure soldier_fire1(self : edict_p); cdecl;
procedure soldier_attack1_refire1(self : edict_p); cdecl;
procedure soldier_attack1_refire2(self : edict_p); cdecl;
procedure soldier_fire2(self : edict_p); cdecl;
procedure soldier_attack2_refire1(self : edict_p); cdecl;
procedure soldier_attack2_refire2(self : edict_p); cdecl;
procedure soldier_duck_down(self : edict_p); cdecl;
procedure soldier_duck_up(self : edict_p); cdecl;
procedure soldier_fire3(self : edict_p); cdecl;
procedure soldier_attack3_refire(self : edict_p); cdecl;
procedure soldier_fire4(self : edict_p); cdecl;
(*
procedure soldier_fire5(self : edict_p); cdecl;
procedure soldier_attack5_refire(self : edict_p); cdecl;
*)
procedure soldier_fire8(self : edict_p); cdecl;
procedure soldier_attack6_refire(self : edict_p); cdecl;
procedure soldier_attack(self : edict_p); cdecl;
procedure soldier_sight(self, other : edict_p); cdecl;
procedure soldier_duck_hold(self : edict_p); cdecl;
procedure soldier_dodge(self, attacker : edict_p; eta : single); cdecl;
procedure soldier_fire6(self : edict_p); cdecl;
procedure soldier_fire7(self : edict_p); cdecl;
procedure soldier_dead(self : edict_p); cdecl;
procedure soldier_die(self, inflictor, attacker : edict_p; damage : integer; const point : vec3_t); cdecl;

procedure SP_monster_soldier_x(self : edict_p); cdecl;
procedure SP_monster_soldier_light(self : edict_p); cdecl;
procedure SP_monster_soldier(self : edict_p); cdecl;
procedure SP_monster_soldier_ss(self : edict_p); cdecl;

implementation

uses
  g_ai,
  g_main,
  g_utils,
  m_flash,
  g_monster,
  g_local_add,
  GameUnit,
  g_misc,
  q_shared_add,
  game_add,
  CPas;

procedure soldier_idle(self : edict_p);
begin
  if _random() > 0.8 then
    gi.sound(self, CHAN_VOICE, sound_idle, 1, ATTN_IDLE, 0);
end;

procedure soldier_cock(self : edict_p);
begin
  if self.s.frame = FRAME_stand322 then
    gi.sound(self, CHAN_WEAPON, sound_cock, 1, ATTN_IDLE, 0)
  else
    gi.sound(self, CHAN_WEAPON, sound_cock, 1, ATTN_NORM, 0);
end;


// STAND

const
  soldier_frames_stand1 : Array[0..29] of mframe_t =
    ((aifunc:ai_stand; dist:0; thinkfunc:soldier_idle),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),

     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),

     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil));

  soldier_move_stand1 : mmove_t =
    (firstframe:FRAME_stand101; lastframe:FRAME_stand130; frame:@soldier_frames_stand1; endfunc:soldier_stand);

  soldier_frames_stand3 : Array[0..38] of mframe_t =
    ((aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),

     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),

     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:soldier_cock),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),

     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil));

  soldier_move_stand3 : mmove_t =
    (firstframe:FRAME_stand301; lastframe:FRAME_stand339; frame:@soldier_frames_stand3; endfunc:soldier_stand);


{$IF false}
  soldier_frames_stand4 : Array[0..51] of mframe_t =
    ((aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),

     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),

     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),

     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),

     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:4; thinkfunc:nil),
     (aifunc:ai_stand; dist:1; thinkfunc:nil),
     (aifunc:ai_stand; dist:-1; thinkfunc:nil),
     (aifunc:ai_stand; dist:-2; thinkfunc:nil),

     (aifunc:ai_stand; dist:0; thinkfunc:nil),
     (aifunc:ai_stand; dist:0; thinkfunc:nil));

  soldier_move_stand4 : mmove_t =
    (firstframe:FRAME_stand401; lastframe:FRAME_stand452; frame:@soldier_frames_stand4; endfunc:nil);

{$IFEND}

procedure soldier_stand(self : edict_p);
begin
  if (self.monsterinfo.currentmove = @soldier_move_stand3) or (_random() < 0.8) then
    self.monsterinfo.currentmove := @soldier_move_stand1
  else
    self.monsterinfo.currentmove := @soldier_move_stand3;
end;


//
// WALK
//

procedure soldier_walk1_random(self : edict_p);
begin
  if _random() > 0.1 then
    self.monsterinfo.nextframe := FRAME_walk101;
end;

const
  soldier_frames_walk1 : Array[0..32] of mframe_t =
    ((aifunc:ai_walk; dist:3; thinkfunc:nil),
     (aifunc:ai_walk; dist:6; thinkfunc:nil),
     (aifunc:ai_walk; dist:2; thinkfunc:nil),
     (aifunc:ai_walk; dist:2; thinkfunc:nil),
     (aifunc:ai_walk; dist:2; thinkfunc:nil),
     (aifunc:ai_walk; dist:1; thinkfunc:nil),
     (aifunc:ai_walk; dist:6; thinkfunc:nil),
     (aifunc:ai_walk; dist:5; thinkfunc:nil),
     (aifunc:ai_walk; dist:3; thinkfunc:nil),
     (aifunc:ai_walk; dist:-1; thinkfunc:soldier_walk1_random),
     (aifunc:ai_walk; dist:0; thinkfunc:nil),
     (aifunc:ai_walk; dist:0; thinkfunc:nil),
     (aifunc:ai_walk; dist:0; thinkfunc:nil),
     (aifunc:ai_walk; dist:0; thinkfunc:nil),
     (aifunc:ai_walk; dist:0; thinkfunc:nil),
     (aifunc:ai_walk; dist:0; thinkfunc:nil),
     (aifunc:ai_walk; dist:0; thinkfunc:nil),
     (aifunc:ai_walk; dist:0; thinkfunc:nil),
     (aifunc:ai_walk; dist:0; thinkfunc:nil),
     (aifunc:ai_walk; dist:0; thinkfunc:nil),
     (aifunc:ai_walk; dist:0; thinkfunc:nil),
     (aifunc:ai_walk; dist:0; thinkfunc:nil),
     (aifunc:ai_walk; dist:0; thinkfunc:nil),
     (aifunc:ai_walk; dist:0; thinkfunc:nil),
     (aifunc:ai_walk; dist:0; thinkfunc:nil),
     (aifunc:ai_walk; dist:0; thinkfunc:nil),
     (aifunc:ai_walk; dist:0; thinkfunc:nil),
     (aifunc:ai_walk; dist:0; thinkfunc:nil),
     (aifunc:ai_walk; dist:0; thinkfunc:nil),
     (aifunc:ai_walk; dist:0; thinkfunc:nil),
     (aifunc:ai_walk; dist:0; thinkfunc:nil),
     (aifunc:ai_walk; dist:0; thinkfunc:nil),
     (aifunc:ai_walk; dist:0; thinkfunc:nil));

  soldier_move_walk1 : mmove_t =
    (firstframe:FRAME_walk101; lastframe:FRAME_walk133; frame:@soldier_frames_walk1; endfunc:nil);

  soldier_frames_walk2 : Array[0..9] of mframe_t =
    ((aifunc:ai_walk; dist:4; thinkfunc:nil),
     (aifunc:ai_walk; dist:4; thinkfunc:nil),
     (aifunc:ai_walk; dist:9; thinkfunc:nil),
     (aifunc:ai_walk; dist:8; thinkfunc:nil),
     (aifunc:ai_walk; dist:5; thinkfunc:nil),
     (aifunc:ai_walk; dist:1; thinkfunc:nil),
     (aifunc:ai_walk; dist:3; thinkfunc:nil),
     (aifunc:ai_walk; dist:7; thinkfunc:nil),
     (aifunc:ai_walk; dist:6; thinkfunc:nil),
     (aifunc:ai_walk; dist:7; thinkfunc:nil));

  soldier_move_walk2 : mmove_t =
    (firstframe:FRAME_walk209; lastframe:FRAME_walk218; frame:@soldier_frames_walk2; endfunc:nil);

procedure soldier_walk(self : edict_p);
begin
  if _random() < 0.5 then
    self.monsterinfo.currentmove := @soldier_move_walk1
  else
    self.monsterinfo.currentmove := @soldier_move_walk2;
end;


//
// RUN
//

const
  soldier_frames_start_run : Array[0..1] of mframe_t =
    ((aifunc:ai_run; dist:7; thinkfunc:nil),
     (aifunc:ai_run; dist:5; thinkfunc:nil));

  soldier_move_start_run : mmove_t =
    (firstframe:FRAME_run01; lastframe:FRAME_run02; frame:@soldier_frames_start_run; endfunc:soldier_run);

  soldier_frames_run : Array[0..5] of mframe_t =
    ((aifunc:ai_run; dist:10; thinkfunc:nil),
     (aifunc:ai_run; dist:11; thinkfunc:nil),
     (aifunc:ai_run; dist:11; thinkfunc:nil),
     (aifunc:ai_run; dist:16; thinkfunc:nil),
     (aifunc:ai_run; dist:10; thinkfunc:nil),
     (aifunc:ai_run; dist:15; thinkfunc:nil));

  soldier_move_run : mmove_t =
    (firstframe:FRAME_run03; lastframe:FRAME_run08; frame:@soldier_frames_run; endfunc:nil);

procedure soldier_run(self : edict_p);
begin
  if (self.monsterinfo.aiflags and AI_STAND_GROUND) <> 0 then
  begin
    self.monsterinfo.currentmove := @soldier_move_stand1;
    exit;
  end;

  if (self.monsterinfo.currentmove = @soldier_move_walk1) or
     (self.monsterinfo.currentmove = @soldier_move_walk2) or
     (self.monsterinfo.currentmove = @soldier_move_start_run) then
    self.monsterinfo.currentmove := @soldier_move_run
  else
    self.monsterinfo.currentmove := @soldier_move_start_run;
end;

//
// PAIN
//

const
  soldier_frames_pain1 : Array[0..4] of mframe_t =
    ((aifunc:ai_move; dist:-3; thinkfunc:nil),
     (aifunc:ai_move; dist:4;  thinkfunc:nil),
     (aifunc:ai_move; dist:1;  thinkfunc:nil),
     (aifunc:ai_move; dist:1;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;  thinkfunc:nil));

  soldier_move_pain1 : mmove_t =
    (firstframe:FRAME_pain101; lastframe:FRAME_pain105; frame:@soldier_frames_pain1; endfunc:soldier_run);

  soldier_frames_pain2 : Array[0..6] of mframe_t =
    ((aifunc:ai_move; dist:-13; thinkfunc:nil),
     (aifunc:ai_move; dist:-1;  thinkfunc:nil),
     (aifunc:ai_move; dist:2;   thinkfunc:nil),
     (aifunc:ai_move; dist:4;   thinkfunc:nil),
     (aifunc:ai_move; dist:2;   thinkfunc:nil),
     (aifunc:ai_move; dist:3;   thinkfunc:nil),
     (aifunc:ai_move; dist:2;   thinkfunc:nil));

  soldier_move_pain2 : mmove_t =
    (firstframe:FRAME_pain201; lastframe:FRAME_pain207; frame:@soldier_frames_pain2; endfunc:soldier_run);

  soldier_frames_pain3 : Array[0..17] of mframe_t =
    ((aifunc:ai_move; dist:-8; thinkfunc:nil),
     (aifunc:ai_move; dist:10; thinkfunc:nil),
     (aifunc:ai_move; dist:-4; thinkfunc:nil),
     (aifunc:ai_move; dist:-1; thinkfunc:nil),
     (aifunc:ai_move; dist:-3; thinkfunc:nil),
     (aifunc:ai_move; dist:0;  thinkfunc:nil),
     (aifunc:ai_move; dist:3;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;  thinkfunc:nil),
     (aifunc:ai_move; dist:1;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;  thinkfunc:nil),
     (aifunc:ai_move; dist:1;  thinkfunc:nil),
     (aifunc:ai_move; dist:2;  thinkfunc:nil),
     (aifunc:ai_move; dist:4;  thinkfunc:nil),
     (aifunc:ai_move; dist:3;  thinkfunc:nil),
     (aifunc:ai_move; dist:2;  thinkfunc:nil));

  soldier_move_pain3 : mmove_t =
    (firstframe:FRAME_pain301; lastframe:FRAME_pain318; frame:@soldier_frames_pain3; endfunc:soldier_run);

  soldier_frames_pain4 : Array[0..16] of mframe_t =
    ((aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:-10; thinkfunc:nil),
     (aifunc:ai_move; dist:-6;  thinkfunc:nil),
     (aifunc:ai_move; dist:8;   thinkfunc:nil),
     (aifunc:ai_move; dist:4;   thinkfunc:nil),
     (aifunc:ai_move; dist:1;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:2;   thinkfunc:nil),
     (aifunc:ai_move; dist:5;   thinkfunc:nil),
     (aifunc:ai_move; dist:2;   thinkfunc:nil),
     (aifunc:ai_move; dist:-1;  thinkfunc:nil),
     (aifunc:ai_move; dist:-1;  thinkfunc:nil),
     (aifunc:ai_move; dist:3;   thinkfunc:nil),
     (aifunc:ai_move; dist:2;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil));

  soldier_move_pain4 : mmove_t =
    (firstframe:FRAME_pain401; lastframe:FRAME_pain417; frame:@soldier_frames_pain4; endfunc:soldier_run);

procedure soldier_pain (self, other : edict_p; kick : single; damage : integer);
var
  r : single;
  n : integer;
begin
  if self.health < (self.max_health / 2) then
    self.s.skinnum := self.s.skinnum or 1;

  if level.time < self.pain_debounce_time then
  begin
    if ((self.velocity[2] > 100) and
       ((self.monsterinfo.currentmove = @soldier_move_pain1) or
       (self.monsterinfo.currentmove = @soldier_move_pain2) or
       (self.monsterinfo.currentmove = @soldier_move_pain3))) then
      self.monsterinfo.currentmove := @soldier_move_pain4;

    exit;
  end;

  self.pain_debounce_time := level.time + 3;

  n := self.s.skinnum or 1;
  if n = 1 then
    gi.sound(self, CHAN_VOICE, sound_pain_light, 1, ATTN_NORM, 0)
  else if n = 3 then
    gi.sound(self, CHAN_VOICE, sound_pain, 1, ATTN_NORM, 0)
  else
    gi.sound(self, CHAN_VOICE, sound_pain_ss, 1, ATTN_NORM, 0);

  if self.velocity[2] > 100 then
  begin
    self.monsterinfo.currentmove := @soldier_move_pain4;
    exit;
  end;

  if skill.value = 3 then
    exit;      // no pain anims in nightmare

  r := _random();

  if r < 0.33 then
    self.monsterinfo.currentmove := @soldier_move_pain1
  else if r < 0.66 then
    self.monsterinfo.currentmove := @soldier_move_pain2
  else
    self.monsterinfo.currentmove := @soldier_move_pain3;
end;


//
// ATTACK
//

var

  blaster_flash : array[0..7] of integer =
    (MZ2_SOLDIER_BLASTER_1, MZ2_SOLDIER_BLASTER_2,
     MZ2_SOLDIER_BLASTER_3, MZ2_SOLDIER_BLASTER_4,
     MZ2_SOLDIER_BLASTER_5, MZ2_SOLDIER_BLASTER_6,
     MZ2_SOLDIER_BLASTER_7, MZ2_SOLDIER_BLASTER_8);

  shotgun_flash : array[0..7] of integer =
    (MZ2_SOLDIER_SHOTGUN_1, MZ2_SOLDIER_SHOTGUN_2,
     MZ2_SOLDIER_SHOTGUN_3, MZ2_SOLDIER_SHOTGUN_4,
     MZ2_SOLDIER_SHOTGUN_5, MZ2_SOLDIER_SHOTGUN_6,
     MZ2_SOLDIER_SHOTGUN_7, MZ2_SOLDIER_SHOTGUN_8);

  machinegun_flash : array[0..7] of integer =
    (MZ2_SOLDIER_MACHINEGUN_1, MZ2_SOLDIER_MACHINEGUN_2,
     MZ2_SOLDIER_MACHINEGUN_3, MZ2_SOLDIER_MACHINEGUN_4,
     MZ2_SOLDIER_MACHINEGUN_5, MZ2_SOLDIER_MACHINEGUN_6,
     MZ2_SOLDIER_MACHINEGUN_7, MZ2_SOLDIER_MACHINEGUN_8);

procedure soldier_fire(self : edict_p; flash_number : integer);
var
  start, fwrd, right, up, aim, dir, eend : vec3_t;
  r, u : single;
  flash_index : integer;
begin
  if self.s.skinnum < 2 then
    flash_index := blaster_flash[flash_number]
  else if self.s.skinnum < 4 then
    flash_index := shotgun_flash[flash_number]
  else
    flash_index := machinegun_flash[flash_number];

  AngleVectors(self.s.angles, @fwrd, @right, nil);
  G_ProjectSource(self.s.origin, monster_flash_offset[flash_index], fwrd, right, start);

  if (flash_number = 5) or (flash_number = 6) then
    VectorCopy(fwrd, aim)
  else
  begin
    VectorCopy(self.enemy.s.origin, eend);
    eend[2] := eend[2] + self.enemy.viewheight;
    VectorSubtract(eend, start, aim);
    vectoangles(aim, dir);
    AngleVectors(dir, @fwrd, @right, @up);

    r := crandom()*1000;
    u := crandom()*500;
    VectorMA(start, 8192, fwrd, eend);
    VectorMA(eend, r, right, eend);
    VectorMA(eend, u, up, eend);

    VectorSubtract(eend, start, aim);
    VectorNormalize(aim);
  end;

  if self.s.skinnum <= 1 then
    monster_fire_blaster(self, start, aim, 5, 600, flash_index, EF_BLASTER)
  else if self.s.skinnum <= 3 then
    monster_fire_shotgun(self, start, aim, 2, 1, DEFAULT_SHOTGUN_HSPREAD, DEFAULT_SHOTGUN_VSPREAD, DEFAULT_SHOTGUN_COUNT, flash_index)
  else
  begin
    if (self.monsterinfo.aiflags and AI_HOLD_FRAME) = 0 then
      self.monsterinfo.pausetime := level.time + (3 + rand() mod 8) * FRAMETIME;

    monster_fire_bullet(self, start, aim, 2, 4, DEFAULT_BULLET_HSPREAD, DEFAULT_BULLET_VSPREAD, flash_index);

    if level.time >= self.monsterinfo.pausetime then
      self.monsterinfo.aiflags := (self.monsterinfo.aiflags and not AI_HOLD_FRAME)
    else
      self.monsterinfo.aiflags := (self.monsterinfo.aiflags or AI_HOLD_FRAME);
  end;
end;

// ATTACK1 (blaster/shotgun)

procedure soldier_fire1(self : edict_p);
begin
  soldier_fire(self, 0);
end;

procedure soldier_attack1_refire1(self : edict_p);
begin
  if self.s.skinnum > 1 then
    exit;

  if self.enemy.health <= 0 then
    exit;

  if ((skill.value = 3) and (_random() < 0.5)) or (range(self, self.enemy) = RANGE_MELEE) then
    self.monsterinfo.nextframe := FRAME_attak102
  else
    self.monsterinfo.nextframe := FRAME_attak110;
end;

procedure soldier_attack1_refire2(self : edict_p);
begin
  if self.s.skinnum < 2 then
    exit;

  if self.enemy.health <= 0 then
    exit;

  if ((skill.value = 3) and (_random() < 0.5)) or (range(self, self.enemy) = RANGE_MELEE) then
    self.monsterinfo.nextframe := FRAME_attak102;
end;

const
  soldier_frames_attack1 : Array[0..11] of mframe_t =
    ((aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:soldier_fire1),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:soldier_attack1_refire1),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:soldier_cock),
     (aifunc:ai_charge; dist:0; thinkfunc:soldier_attack1_refire2),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:nil));

  soldier_move_attack1 : mmove_t =
    (firstframe:FRAME_attak101; lastframe:FRAME_attak112; frame:@soldier_frames_attack1; endfunc:soldier_run);

// ATTACK2 (blaster/shotgun)

procedure soldier_fire2(self : edict_p);
begin
  soldier_fire (self, 1);
end;

procedure soldier_attack2_refire1(self : edict_p);
begin
  if self.s.skinnum > 1 then
    exit;

  if self.enemy.health <= 0 then
    exit;

  if ((skill.value = 3) and (_random() < 0.5)) or (range(self, self.enemy) = RANGE_MELEE) then
    self.monsterinfo.nextframe := FRAME_attak204
  else
    self.monsterinfo.nextframe := FRAME_attak216;
end;

procedure soldier_attack2_refire2(self : edict_p);
begin
  if self.s.skinnum < 2 then
    exit;

  if self.enemy.health <= 0 then
    exit;

  if ((skill.value = 3) and (_random() < 0.5)) or (range(self, self.enemy) = RANGE_MELEE) then
    self.monsterinfo.nextframe := FRAME_attak204;
end;

const
  soldier_frames_attack2 : Array[0..17] of mframe_t =
    ((aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:soldier_fire2),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:soldier_attack2_refire1),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:soldier_cock),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:soldier_attack2_refire2),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:nil));

  soldier_move_attack2 : mmove_t =
    (firstframe:FRAME_attak201; lastframe:FRAME_attak218; frame:@soldier_frames_attack2; endfunc:soldier_run);

// ATTACK3 (duck and shoot)

procedure soldier_duck_down(self : edict_p);
begin
  if (self.monsterinfo.aiflags and AI_DUCKED) <> 0 then
    exit;
  self.monsterinfo.aiflags := (self.monsterinfo.aiflags or AI_DUCKED);
  self.maxs[2] := self.maxs[2] - 32;
  self.takedamage := DAMAGE_YES;
  self.monsterinfo.pausetime := level.time + 1;
  gi.linkentity(self);
end;

procedure soldier_duck_up(self : edict_p);
begin
  self.monsterinfo.aiflags := (self.monsterinfo.aiflags and AI_DUCKED);
  self.maxs[2] := self.maxs[2] + 32;
  self.takedamage := DAMAGE_AIM;
  gi.linkentity(self);
end;

procedure soldier_fire3(self : edict_p);
begin
  soldier_duck_down(self);
  soldier_fire(self, 2);
end;

procedure soldier_attack3_refire(self : edict_p);
begin
  if (level.time + 0.4) < self.monsterinfo.pausetime then
    self.monsterinfo.nextframe := FRAME_attak303;
end;

const
  soldier_frames_attack3 : Array[0..8] of mframe_t =
    ((aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:soldier_fire3),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:soldier_attack3_refire),
     (aifunc:ai_charge; dist:0; thinkfunc:soldier_duck_up),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:nil));

  soldier_move_attack3 : mmove_t =
    (firstframe:FRAME_attak301; lastframe:FRAME_attak309; frame:@soldier_frames_attack3; endfunc:soldier_run);

// ATTACK4 (machinegun)

procedure soldier_fire4(self : edict_p);
begin
  soldier_fire(self, 3);
//
//   if self.enemy.health <= 0 then
//     exit;
//
//   if ((skill.value = 3) and (_random() < 0.5)) or (range(self, self.enemy) = RANGE_MELEE) then
//     self.monsterinfo.nextframe := FRAME_attak402;
end;

const
  soldier_frames_attack4 : Array[0..5] of mframe_t =
    ((aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:soldier_fire4),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:nil));

  soldier_move_attack4 : mmove_t =
    (firstframe:FRAME_attak401; lastframe:FRAME_attak406; frame:@soldier_frames_attack4; endfunc:soldier_run);

{$IF false}
// ATTACK5 (prone)

procedure soldier_fire5(self : edict_p);
begin
  soldier_fire(self, 4);
end;

procedure soldier_attack5_refire(self : edict_p);
begin
  if self.enemy.health <= 0 then
    exit;

  if ((skill.value = 3) and (_random() < 0.5)) or (range(self, self.enemy) = RANGE_MELEE) then
    self.monsterinfo.nextframe := FRAME_attak505;
end;

const
  soldier_frames_attack5 : Array[0..7] of mframe_t =
    ((aifunc:ai_charge; dist:8; thinkfunc:nil),
     (aifunc:ai_charge; dist:8; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:soldier_fire5),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:soldier_attack5_refire));

  soldier_move_attack5 : mmove_t =
    (firstframe:FRAME_attak501; lastframe:FRAME_attak508; frame:@soldier_frames_attack5; endfunc:soldier_run);
{$IFEND}

// ATTACK6 (run & shoot)

procedure soldier_fire8(self : edict_p);
begin
  soldier_fire(self, 7);
end;

procedure soldier_attack6_refire(self : edict_p);
begin
  if self.enemy.health <= 0 then
    exit;

  if range(self, self.enemy) < RANGE_MID then
    exit;

  if skill.value = 3 then
    self.monsterinfo.nextframe := FRAME_runs03;
end;

const
  soldier_frames_attack6 : Array[0..13] of mframe_t =
    ((aifunc:ai_charge; dist:10; thinkfunc:nil),
     (aifunc:ai_charge; dist:4;  thinkfunc:nil),
     (aifunc:ai_charge; dist:12; thinkfunc:nil),
     (aifunc:ai_charge; dist:11; thinkfunc:soldier_fire8),
     (aifunc:ai_charge; dist:13; thinkfunc:nil),
     (aifunc:ai_charge; dist:18; thinkfunc:nil),
     (aifunc:ai_charge; dist:15; thinkfunc:nil),
     (aifunc:ai_charge; dist:14; thinkfunc:nil),
     (aifunc:ai_charge; dist:11; thinkfunc:nil),
     (aifunc:ai_charge; dist:8;  thinkfunc:nil),
     (aifunc:ai_charge; dist:11; thinkfunc:nil),
     (aifunc:ai_charge; dist:12; thinkfunc:nil),
     (aifunc:ai_charge; dist:12; thinkfunc:nil),
     (aifunc:ai_charge; dist:17; thinkfunc:soldier_attack6_refire));

  soldier_move_attack6 : mmove_t =
    (firstframe:FRAME_runs01; lastframe:FRAME_runs14; frame:@soldier_frames_attack6; endfunc:soldier_run);

procedure soldier_attack(self : edict_p);
begin
  if self.s.skinnum < 4 then
  begin
    if _random() < 0.5 then
      self.monsterinfo.currentmove := @soldier_move_attack1
    else
      self.monsterinfo.currentmove := @soldier_move_attack2;
  end
  else
    self.monsterinfo.currentmove := @soldier_move_attack4;
end;

//
// SIGHT
//

procedure soldier_sight(self, other : edict_p);
begin
  if _random() < 0.5 then
    gi.sound (self, CHAN_VOICE, sound_sight1, 1, ATTN_NORM, 0)
  else
    gi.sound (self, CHAN_VOICE, sound_sight2, 1, ATTN_NORM, 0);

  if (skill.value > 0) and (range(self, self.enemy) >= RANGE_MID) then
  begin
    if _random() > 0.5 then
      self.monsterinfo.currentmove := @soldier_move_attack6;
  end;
end;

//
// DUCK
//

procedure soldier_duck_hold(self : edict_p);
begin
  if level.time >= self.monsterinfo.pausetime then
    self.monsterinfo.aiflags := (self.monsterinfo.aiflags and not AI_HOLD_FRAME)
  else
    self.monsterinfo.aiflags := (self.monsterinfo.aiflags or AI_HOLD_FRAME);
end;

const
  soldier_frames_duck : Array[0..4] of mframe_t =
    ((aifunc:ai_move; dist:5;  thinkfunc:soldier_duck_down),
     (aifunc:ai_move; dist:-1; thinkfunc:soldier_duck_hold),
     (aifunc:ai_move; dist:1;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;  thinkfunc:soldier_duck_up),
     (aifunc:ai_move; dist:5;  thinkfunc:nil));

  soldier_move_duck : mmove_t =
    (firstframe:FRAME_duck01; lastframe:FRAME_duck05; frame:@soldier_frames_duck; endfunc:soldier_run);

procedure soldier_dodge(self, attacker : edict_p; eta : single);
var
  r : single;
begin
  r := _random();
  if r > 0.25 then
    exit;

  if (self.enemy = nil) then
    self.enemy := attacker;

  if skill.value = 0 then
  begin
    self.monsterinfo.currentmove := @soldier_move_duck;
    exit;
  end;

  self.monsterinfo.pausetime := level.time + eta + 0.3;
  r := _random();

  if skill.value = 1 then
  begin
    if r > 0.33 then
      self.monsterinfo.currentmove := @soldier_move_duck
    else
      self.monsterinfo.currentmove := @soldier_move_attack3;
    exit;
  end;

  if skill.value >= 2 then
  begin
    if r > 0.66 then
      self.monsterinfo.currentmove := @soldier_move_duck
    else
      self.monsterinfo.currentmove := @soldier_move_attack3;
    exit;
  end;

  self.monsterinfo.currentmove := @soldier_move_attack3;
end;

//
// DEATH
//

procedure soldier_fire6(self : edict_p);
begin
  soldier_fire(self, 5);
end;

procedure soldier_fire7(self : edict_p);
begin
  soldier_fire(self, 6);
end;

procedure soldier_dead(self : edict_p);
begin
  VectorSet(self.mins, -16, -16, -24);
  VectorSet(self.maxs, 16, 16, -8);
  self.movetype := MOVETYPE_TOSS;
  self.svflags  :=(self.svflags or SVF_DEADMONSTER);
  self.nextthink := 0;
  gi.linkentity(self);
end;

const
  soldier_frames_death1 : Array[0..35] of mframe_t =
    ((aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:-10; thinkfunc:nil),
     (aifunc:ai_move; dist:-10; thinkfunc:nil),
     (aifunc:ai_move; dist:-10; thinkfunc:nil),
     (aifunc:ai_move; dist:-5;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),

     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),

     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:soldier_fire6),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:soldier_fire7),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),

     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil));

  soldier_move_death1 : mmove_t =
    (firstframe:FRAME_death101; lastframe:FRAME_death136; frame:@soldier_frames_death1; endfunc:soldier_dead);

  soldier_frames_death2 : Array[0..34] of mframe_t =
    ((aifunc:ai_move; dist:-5; thinkfunc:nil),
     (aifunc:ai_move; dist:-5; thinkfunc:nil),
     (aifunc:ai_move; dist:-5; thinkfunc:nil),
     (aifunc:ai_move; dist:0;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;  thinkfunc:nil),

     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),

     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),

     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil));

  soldier_move_death2 : mmove_t =
    (firstframe:FRAME_death201; lastframe:FRAME_death235; frame:@soldier_frames_death2; endfunc:soldier_dead);

  soldier_frames_death3 : Array[0..44] of mframe_t =
    ((aifunc:ai_move; dist:-5; thinkfunc:nil),
     (aifunc:ai_move; dist:-5; thinkfunc:nil),
     (aifunc:ai_move; dist:-5; thinkfunc:nil),
     (aifunc:ai_move; dist:0;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;  thinkfunc:nil),

     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),

     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),

     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),

     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil));

  soldier_move_death3 : mmove_t =
    (firstframe:FRAME_death301; lastframe:FRAME_death345; frame:@soldier_frames_death3; endfunc:soldier_dead);

  soldier_frames_death4 : Array[0..52] of mframe_t =
    ((aifunc:ai_move; dist:0;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;  thinkfunc:nil),

     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),

     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),

     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),

     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),

     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil));

  soldier_move_death4 : mmove_t =
    (firstframe:FRAME_death401; lastframe:FRAME_death453; frame:@soldier_frames_death4; endfunc:soldier_dead);

  soldier_frames_death5 : Array[0..23] of mframe_t =
    ((aifunc:ai_move; dist:-5; thinkfunc:nil),
     (aifunc:ai_move; dist:-5; thinkfunc:nil),
     (aifunc:ai_move; dist:-5; thinkfunc:nil),
     (aifunc:ai_move; dist:0;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;  thinkfunc:nil),

     (aifunc:ai_move; dist:0;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;  thinkfunc:nil),

     (aifunc:ai_move; dist:0;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;  thinkfunc:nil));

  soldier_move_death5 : mmove_t =
    (firstframe:FRAME_death501; lastframe:FRAME_death524; frame:@soldier_frames_death5; endfunc:soldier_dead);

  soldier_frames_death6 : Array[0..9] of mframe_t =
    ((aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil),
     (aifunc:ai_move; dist:0; thinkfunc:nil));

  soldier_move_death6 : mmove_t =
    (firstframe:FRAME_death601; lastframe:FRAME_death610; frame:@soldier_frames_death6; endfunc:soldier_dead);

procedure soldier_die(self, inflictor, attacker : edict_p; damage : integer; const point : vec3_t);
var
  n : integer;
begin
  // check for gib
  if self.health <= self.gib_health then
  begin
    gi.sound(self, CHAN_VOICE, gi.soundindex('misc/udeath.wav'), 1, ATTN_NORM, 0);
    for n := 0 to 2 do
      ThrowGib(self, 'models/objects/gibs/sm_meat/tris.md2', damage, GIB_ORGANIC);
    ThrowGib(self, 'models/objects/gibs/chest/tris.md2', damage, GIB_ORGANIC);
    ThrowHead(self, 'models/objects/gibs/head2/tris.md2', damage, GIB_ORGANIC);
    self.deadflag := DEAD_DEAD;
    exit;
  end;

  if self.deadflag = DEAD_DEAD then
    exit;

  // regular death
  self.deadflag := DEAD_DEAD;
  self.takedamage := DAMAGE_YES;
  self.s.skinnum := (self.s.skinnum or 1);

  if self.s.skinnum = 1 then
    gi.sound(self, CHAN_VOICE, sound_death_light, 1, ATTN_NORM, 0)
  else if self.s.skinnum = 3 then
    gi.sound(self, CHAN_VOICE, sound_death, 1, ATTN_NORM, 0)
  else// if self.s.skinnum = 5 then
    gi.sound(self, CHAN_VOICE, sound_death_ss, 1, ATTN_NORM, 0);

  if fabs((self.s.origin[2] + self.viewheight) - point[2]) <= 4 then
  begin
    // head shot
    self.monsterinfo.currentmove := @soldier_move_death3;
    exit;
  end;

  n := rand() mod 5;
  if n = 0 then
    self.monsterinfo.currentmove := @soldier_move_death1
  else if n = 1 then
    self.monsterinfo.currentmove := @soldier_move_death2
  else if n = 2 then
    self.monsterinfo.currentmove := @soldier_move_death4
  else if n = 3 then
    self.monsterinfo.currentmove := @soldier_move_death5
  else
    self.monsterinfo.currentmove := @soldier_move_death6;
end;


//
// SPAWN
//

procedure SP_monster_soldier_x(self : edict_p);
begin

  self.s.modelindex := gi.modelindex('models/monsters/soldier/tris.md2');
  self.monsterinfo.scale := MODEL_SCALE;
  VectorSet(self.mins, -16, -16, -24);
  VectorSet(self.maxs, 16, 16, 32);
  self.movetype := MOVETYPE_STEP;
  self.solid := SOLID_BBOX;

  sound_idle   :=   gi.soundindex('soldier/solidle1.wav');
  sound_sight1 :=   gi.soundindex('soldier/solsght1.wav');
  sound_sight2 :=   gi.soundindex('soldier/solsrch1.wav');
  sound_cock   :=   gi.soundindex('infantry/infatck3.wav');

  self.mass := 100;

  self.pain := soldier_pain;
  self.die  := soldier_die;

  self.monsterinfo.stand  := soldier_stand;
  self.monsterinfo.walk   := soldier_walk;
  self.monsterinfo.run    := soldier_run;
  self.monsterinfo.dodge  := soldier_dodge;
  self.monsterinfo.attack := soldier_attack;
  self.monsterinfo.melee  := nil;
  self.monsterinfo.sight  := soldier_sight;

  gi.linkentity(self);

  self.monsterinfo.stand(self);

  walkmonster_start(self);
end;


{QUAKED monster_soldier_light (1 .5 0) (-16 -16 -24) (16 16 32) Ambush Trigger_Spawn Sight
}
procedure SP_monster_soldier_light(self : edict_p);
begin
  if deathmatch.value <> 0 then
  begin
    G_FreeEdict(self);
    exit;
  end;

  SP_monster_soldier_x(self);

  sound_pain_light  := gi.soundindex('soldier/solpain2.wav');
  sound_death_light := gi.soundindex('soldier/soldeth2.wav');
  gi.modelindex('models/objects/laser/tris.md2');
  gi.soundindex('misc/lasfly.wav');
  gi.soundindex('soldier/solatck2.wav');

  self.s.skinnum  := 0;
  self.health     := 20;
  self.gib_health := -30;
end;

{QUAKED monster_soldier (1 .5 0) (-16 -16 -24) (16 16 32) Ambush Trigger_Spawn Sight
}
procedure SP_monster_soldier(self : edict_p);
begin
  if deathmatch.value <> 0 then
  begin
    G_FreeEdict(self);
    exit;
  end;

  SP_monster_soldier_x(self);
  sound_pain  := gi.soundindex('soldier/solpain1.wav');
  sound_death := gi.soundindex('soldier/soldeth1.wav');
  gi.soundindex('soldier/solatck1.wav');

  self.s.skinnum  := 2;
  self.health     := 30;
  self.gib_health := -30;
end;

{QUAKED monster_soldier_ss (1 .5 0) (-16 -16 -24) (16 16 32) Ambush Trigger_Spawn Sight
}
procedure SP_monster_soldier_ss(self : edict_p);
begin
  if deathmatch.value <> 0 then
  begin
    G_FreeEdict(self);
    exit;
  end;

  SP_monster_soldier_x(self);

  sound_pain_ss  := gi.soundindex('soldier/solpain3.wav');
  sound_death_ss := gi.soundindex('soldier/soldeth3.wav');
  gi.soundindex('soldier/solatck3.wav');

  self.s.skinnum  := 4;
  self.health     := 40;
  self.gib_health := -30;
end;

end.


