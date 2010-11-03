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
{ File(s): m_infantry.h                                                      }
{                                                                            }
{ Initial conversion by : Ben Watt (ben@delphigamedev.com)                   }
{ Initial conversion on : 28-Jan-2002                                        }
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
{----------------------------------------------------------------------------}

unit m_infantry;

interface

uses
  g_local,
  q_shared;

const MODEL_SCALE     = 1.000000;

var
  sound_pain1,
  sound_pain2,
  sound_die1,
  sound_die2,

  sound_gunshot,
  sound_weapon_cock,
  sound_punch_swing,
  sound_punch_hit,
  sound_sight,
  sound_search,
  sound_idle          : Integer;

procedure infantry_stand(self : edict_p); cdecl;
procedure infantry_fidget(self : edict_p); cdecl;
procedure infantry_walk(self : edict_p); cdecl;
procedure infantry_run(self : edict_p); cdecl;
procedure infantry_pain(self, other : edict_p; kick : single; damage : Integer); cdecl;
procedure InfantryMachineGun(self : edict_p); cdecl;
procedure infantry_sight(self, other : edict_p); cdecl;
procedure infantry_dead(self : edict_p); cdecl;
procedure infantry_die(self, inflictor, attacker : edict_p; damage : Integer; const point: vec3_t); cdecl;
procedure infantry_duck_down(self : edict_p); cdecl;
procedure infantry_duck_hold(self : edict_p); cdecl;
procedure infantry_duck_up(self : edict_p); cdecl;
procedure infantry_dodge(self, attacker : edict_p; eta : single); cdecl;
procedure infantry_cock_gun(self : edict_p); cdecl;
procedure infantry_fire(self : edict_p); cdecl;
procedure infantry_swing(self : edict_p); cdecl;
procedure infantry_smack(self : edict_p); cdecl;
procedure infantry_attack(self : edict_p); cdecl;

procedure SP_monster_infantry(self : edict_p); cdecl;

implementation

uses g_ai, g_main, g_utils, m_flash, g_monster, g_local_add, GameUnit,
  g_misc, g_weapon, game_add, CPas;


// start of m_infantry.h

const
  FRAME_gun02              = 0;
  FRAME_stand01            = 1;
  FRAME_stand02            = 2;
  FRAME_stand03            = 3;
  FRAME_stand04            = 4;
  FRAME_stand05            = 5;
  FRAME_stand06            = 6;
  FRAME_stand07            = 7;
  FRAME_stand08            = 8;
  FRAME_stand09            = 9;
  FRAME_stand10            = 10;
  FRAME_stand11            = 11;
  FRAME_stand12            = 12;
  FRAME_stand13            = 13;
  FRAME_stand14            = 14;
  FRAME_stand15            = 15;
  FRAME_stand16            = 16;
  FRAME_stand17            = 17;
  FRAME_stand18            = 18;
  FRAME_stand19            = 19;
  FRAME_stand20            = 20;
  FRAME_stand21            = 21;
  FRAME_stand22            = 22;
  FRAME_stand23            = 23;
  FRAME_stand24            = 24;
  FRAME_stand25            = 25;
  FRAME_stand26            = 26;
  FRAME_stand27            = 27;
  FRAME_stand28            = 28;
  FRAME_stand29            = 29;
  FRAME_stand30            = 30;
  FRAME_stand31            = 31;
  FRAME_stand32            = 32;
  FRAME_stand33            = 33;
  FRAME_stand34            = 34;
  FRAME_stand35            = 35;
  FRAME_stand36            = 36;
  FRAME_stand37            = 37;
  FRAME_stand38            = 38;
  FRAME_stand39            = 39;
  FRAME_stand40            = 40;
  FRAME_stand41            = 41;
  FRAME_stand42            = 42;
  FRAME_stand43            = 43;
  FRAME_stand44            = 44;
  FRAME_stand45            = 45;
  FRAME_stand46            = 46;
  FRAME_stand47            = 47;
  FRAME_stand48            = 48;
  FRAME_stand49            = 49;
  FRAME_stand50            = 50;
  FRAME_stand51            = 51;
  FRAME_stand52            = 52;
  FRAME_stand53            = 53;
  FRAME_stand54            = 54;
  FRAME_stand55            = 55;
  FRAME_stand56            = 56;
  FRAME_stand57            = 57;
  FRAME_stand58            = 58;
  FRAME_stand59            = 59;
  FRAME_stand60            = 60;
  FRAME_stand61            = 61;
  FRAME_stand62            = 62;
  FRAME_stand63            = 63;
  FRAME_stand64            = 64;
  FRAME_stand65            = 65;
  FRAME_stand66            = 66;
  FRAME_stand67            = 67;
  FRAME_stand68            = 68;
  FRAME_stand69            = 69;
  FRAME_stand70            = 70;
  FRAME_stand71            = 71;
  FRAME_walk01             = 72;
  FRAME_walk02             = 73;
  FRAME_walk03             = 74;
  FRAME_walk04             = 75;
  FRAME_walk05             = 76;
  FRAME_walk06             = 77;
  FRAME_walk07             = 78;
  FRAME_walk08             = 79;
  FRAME_walk09             = 80;
  FRAME_walk10             = 81;
  FRAME_walk11             = 82;
  FRAME_walk12             = 83;
  FRAME_walk13             = 84;
  FRAME_walk14             = 85;
  FRAME_walk15             = 86;
  FRAME_walk16             = 87;
  FRAME_walk17             = 88;
  FRAME_walk18             = 89;
  FRAME_walk19             = 90;
  FRAME_walk20             = 91;
  FRAME_run01              = 92;
  FRAME_run02              = 93;
  FRAME_run03              = 94;
  FRAME_run04              = 95;
  FRAME_run05              = 96;
  FRAME_run06              = 97;
  FRAME_run07              = 98;
  FRAME_run08              = 99;
  FRAME_pain101            = 100;
  FRAME_pain102            = 101;
  FRAME_pain103            = 102;
  FRAME_pain104            = 103;
  FRAME_pain105            = 104;
  FRAME_pain106            = 105;
  FRAME_pain107            = 106;
  FRAME_pain108            = 107;
  FRAME_pain109            = 108;
  FRAME_pain110            = 109;
  FRAME_pain201            = 110;
  FRAME_pain202            = 111;
  FRAME_pain203            = 112;
  FRAME_pain204            = 113;
  FRAME_pain205            = 114;
  FRAME_pain206            = 115;
  FRAME_pain207            = 116;
  FRAME_pain208            = 117;
  FRAME_pain209            = 118;
  FRAME_pain210            = 119;
  FRAME_duck01             = 120;
  FRAME_duck02             = 121;
  FRAME_duck03             = 122;
  FRAME_duck04             = 123;
  FRAME_duck05             = 124;
  FRAME_death101           = 125;
  FRAME_death102           = 126;
  FRAME_death103           = 127;
  FRAME_death104           = 128;
  FRAME_death105           = 129;
  FRAME_death106           = 130;
  FRAME_death107           = 131;
  FRAME_death108           = 132;
  FRAME_death109           = 133;
  FRAME_death110           = 134;
  FRAME_death111           = 135;
  FRAME_death112           = 136;
  FRAME_death113           = 137;
  FRAME_death114           = 138;
  FRAME_death115           = 139;
  FRAME_death116           = 140;
  FRAME_death117           = 141;
  FRAME_death118           = 142;
  FRAME_death119           = 143;
  FRAME_death120           = 144;
  FRAME_death201           = 145;
  FRAME_death202           = 146;
  FRAME_death203           = 147;
  FRAME_death204           = 148;
  FRAME_death205           = 149;
  FRAME_death206           = 150;
  FRAME_death207           = 151;
  FRAME_death208           = 152;
  FRAME_death209           = 153;
  FRAME_death210           = 154;
  FRAME_death211           = 155;
  FRAME_death212           = 156;
  FRAME_death213           = 157;
  FRAME_death214           = 158;
  FRAME_death215           = 159;
  FRAME_death216           = 160;
  FRAME_death217           = 161;
  FRAME_death218           = 162;
  FRAME_death219           = 163;
  FRAME_death220           = 164;
  FRAME_death221           = 165;
  FRAME_death222           = 166;
  FRAME_death223           = 167;
  FRAME_death224           = 168;
  FRAME_death225           = 169;
  FRAME_death301           = 170;
  FRAME_death302           = 171;
  FRAME_death303           = 172;
  FRAME_death304           = 173;
  FRAME_death305           = 174;
  FRAME_death306           = 175;
  FRAME_death307           = 176;
  FRAME_death308           = 177;
  FRAME_death309           = 178;
  FRAME_block01            = 179;
  FRAME_block02            = 180;
  FRAME_block03            = 181;
  FRAME_block04            = 182;
  FRAME_block05            = 183;
  FRAME_attak101           = 184;
  FRAME_attak102           = 185;
  FRAME_attak103           = 186;
  FRAME_attak104           = 187;
  FRAME_attak105           = 188;
  FRAME_attak106           = 189;
  FRAME_attak107           = 190;
  FRAME_attak108           = 191;
  FRAME_attak109           = 192;
  FRAME_attak110           = 193;
  FRAME_attak111           = 194;
  FRAME_attak112           = 195;
  FRAME_attak113           = 196;
  FRAME_attak114           = 197;
  FRAME_attak115           = 198;
  FRAME_attak201           = 199;
  FRAME_attak202           = 200;
  FRAME_attak203           = 201;
  FRAME_attak204           = 202;
  FRAME_attak205           = 203;
  FRAME_attak206           = 204;
  FRAME_attak207           = 205;
  FRAME_attak208           = 206;

// end of m_infantry.h

const
  infantry_frames_stand : Array[0..21] of mframe_t =
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
     (aifunc:ai_stand; dist:0; thinkfunc:nil));

  infantry_move_stand : mmove_t =
    (firstframe:FRAME_stand50; lastframe:FRAME_stand71; frame:@infantry_frames_stand; endfunc:nil);

procedure infantry_stand(self : edict_p);
begin
  self.monsterinfo.currentmove := @infantry_move_stand;
end;

const
  infantry_frames_fidget : Array[0..48] of mframe_t =
    ((aifunc:ai_stand; dist:1;  thinkfunc:nil),
     (aifunc:ai_stand; dist:0;  thinkfunc:nil),
     (aifunc:ai_stand; dist:1;  thinkfunc:nil),
     (aifunc:ai_stand; dist:3;  thinkfunc:nil),
     (aifunc:ai_stand; dist:6;  thinkfunc:nil),
     (aifunc:ai_stand; dist:3;  thinkfunc:nil),
     (aifunc:ai_stand; dist:0;  thinkfunc:nil),
     (aifunc:ai_stand; dist:0;  thinkfunc:nil),
     (aifunc:ai_stand; dist:0;  thinkfunc:nil),
     (aifunc:ai_stand; dist:0;  thinkfunc:nil),
     (aifunc:ai_stand; dist:1;  thinkfunc:nil),
     (aifunc:ai_stand; dist:0;  thinkfunc:nil),
     (aifunc:ai_stand; dist:0;  thinkfunc:nil),
     (aifunc:ai_stand; dist:0;  thinkfunc:nil),
     (aifunc:ai_stand; dist:0;  thinkfunc:nil),
     (aifunc:ai_stand; dist:1;  thinkfunc:nil),
     (aifunc:ai_stand; dist:0;  thinkfunc:nil),
     (aifunc:ai_stand; dist:-1; thinkfunc:nil),
     (aifunc:ai_stand; dist:0;  thinkfunc:nil),
     (aifunc:ai_stand; dist:0;  thinkfunc:nil),
     (aifunc:ai_stand; dist:1;  thinkfunc:nil),
     (aifunc:ai_stand; dist:0;  thinkfunc:nil),
     (aifunc:ai_stand; dist:-2; thinkfunc:nil),
     (aifunc:ai_stand; dist:1;  thinkfunc:nil),
     (aifunc:ai_stand; dist:1;  thinkfunc:nil),
     (aifunc:ai_stand; dist:1;  thinkfunc:nil),
     (aifunc:ai_stand; dist:-1; thinkfunc:nil),
     (aifunc:ai_stand; dist:0;  thinkfunc:nil),
     (aifunc:ai_stand; dist:0;  thinkfunc:nil),
     (aifunc:ai_stand; dist:-1; thinkfunc:nil),
     (aifunc:ai_stand; dist:0;  thinkfunc:nil),
     (aifunc:ai_stand; dist:0;  thinkfunc:nil),
     (aifunc:ai_stand; dist:0;  thinkfunc:nil),
     (aifunc:ai_stand; dist:0;  thinkfunc:nil),
     (aifunc:ai_stand; dist:0;  thinkfunc:nil),
     (aifunc:ai_stand; dist:-1; thinkfunc:nil),
     (aifunc:ai_stand; dist:0;  thinkfunc:nil),
     (aifunc:ai_stand; dist:0;  thinkfunc:nil),
     (aifunc:ai_stand; dist:1;  thinkfunc:nil),
     (aifunc:ai_stand; dist:0;  thinkfunc:nil),
     (aifunc:ai_stand; dist:0;  thinkfunc:nil),
     (aifunc:ai_stand; dist:-1; thinkfunc:nil),
     (aifunc:ai_stand; dist:-1; thinkfunc:nil),
     (aifunc:ai_stand; dist:0;  thinkfunc:nil),
     (aifunc:ai_stand; dist:-3; thinkfunc:nil),
     (aifunc:ai_stand; dist:-2; thinkfunc:nil),
     (aifunc:ai_stand; dist:-3; thinkfunc:nil),
     (aifunc:ai_stand; dist:-3; thinkfunc:nil),
     (aifunc:ai_stand; dist:-2; thinkfunc:nil));

  infantry_move_fidget : mmove_t =
    (firstframe:FRAME_stand01; lastframe:FRAME_stand49; frame:@infantry_frames_fidget; endfunc:infantry_stand);

procedure infantry_fidget(self : edict_p);
begin
  self.monsterinfo.currentmove := @infantry_move_fidget;
  gi.sound(self, CHAN_VOICE, sound_idle, 1, ATTN_IDLE, 0);
end;

const
  infantry_frames_walk : Array[0..11] of mframe_t =
    ((aifunc:ai_walk; dist:5;  thinkfunc:nil),
     (aifunc:ai_walk; dist:4;  thinkfunc:nil),
     (aifunc:ai_walk; dist:4;  thinkfunc:nil),
     (aifunc:ai_walk; dist:5;  thinkfunc:nil),
     (aifunc:ai_walk; dist:4;  thinkfunc:nil),
     (aifunc:ai_walk; dist:5;  thinkfunc:nil),
     (aifunc:ai_walk; dist:6;  thinkfunc:nil),
     (aifunc:ai_walk; dist:4;  thinkfunc:nil),
     (aifunc:ai_walk; dist:4;  thinkfunc:nil),
     (aifunc:ai_walk; dist:4;  thinkfunc:nil),
     (aifunc:ai_walk; dist:4;  thinkfunc:nil),
     (aifunc:ai_walk; dist:5;  thinkfunc:nil));

  infantry_move_walk : mmove_t =
    (firstframe:FRAME_walk03; lastframe:FRAME_walk14; frame:@infantry_frames_walk; endfunc:nil);

procedure infantry_walk(self : edict_p);
begin
  self.monsterinfo.currentmove := @infantry_move_walk;
end;

const
  infantry_frames_run : Array[0..7] of mframe_t =
    ((aifunc:ai_run; dist:10; thinkfunc:nil),
     (aifunc:ai_run; dist:20; thinkfunc:nil),
     (aifunc:ai_run; dist:5;  thinkfunc:nil),
     (aifunc:ai_run; dist:7;  thinkfunc:nil),
     (aifunc:ai_run; dist:30; thinkfunc:nil),
     (aifunc:ai_run; dist:35; thinkfunc:nil),
     (aifunc:ai_run; dist:2;  thinkfunc:nil),
     (aifunc:ai_run; dist:6;  thinkfunc:nil));

  infantry_move_run : mmove_t =
    (firstframe:FRAME_run01; lastframe:FRAME_run08; frame:@infantry_frames_run; endfunc:nil);

procedure infantry_run(self : edict_p);
begin
  if (self.monsterinfo.aiflags and AI_STAND_GROUND) <> 0 then
    self.monsterinfo.currentmove := @infantry_move_stand
  else
    self.monsterinfo.currentmove := @infantry_move_run;
end;

const
  infantry_frames_pain1 : Array[0..9] of mframe_t =
    ((aifunc:ai_run; dist:-3; thinkfunc:nil),
     (aifunc:ai_run; dist:-2; thinkfunc:nil),
     (aifunc:ai_run; dist:-1; thinkfunc:nil),
     (aifunc:ai_run; dist:-2; thinkfunc:nil),
     (aifunc:ai_run; dist:-1; thinkfunc:nil),
     (aifunc:ai_run; dist:1;  thinkfunc:nil),
     (aifunc:ai_run; dist:-1; thinkfunc:nil),
     (aifunc:ai_run; dist:1;  thinkfunc:nil),
     (aifunc:ai_run; dist:6;  thinkfunc:nil),
     (aifunc:ai_run; dist:2;  thinkfunc:nil));

  infantry_move_pain1 : mmove_t =
    (firstframe:FRAME_pain101; lastframe:FRAME_pain110; frame:@infantry_frames_pain1; endfunc:infantry_run);

const
  infantry_frames_pain2 : Array[0..9] of mframe_t =
    ((aifunc:ai_run; dist:-3; thinkfunc:nil),
     (aifunc:ai_run; dist:-3; thinkfunc:nil),
     (aifunc:ai_run; dist:0;  thinkfunc:nil),
     (aifunc:ai_run; dist:-1; thinkfunc:nil),
     (aifunc:ai_run; dist:-2; thinkfunc:nil),
     (aifunc:ai_run; dist:0;  thinkfunc:nil),
     (aifunc:ai_run; dist:0;  thinkfunc:nil),
     (aifunc:ai_run; dist:2;  thinkfunc:nil),
     (aifunc:ai_run; dist:5;  thinkfunc:nil),
     (aifunc:ai_run; dist:2;  thinkfunc:nil));

  infantry_move_pain2 : mmove_t =
    (firstframe:FRAME_pain201; lastframe:FRAME_pain210; frame:@infantry_frames_pain2; endfunc:infantry_run);

procedure infantry_pain(self, other : edict_p; kick : Single; damage : Integer);
var
  n : integer;
begin
  if self^.health < self^.max_health/2 then
    self^.s.skinnum := 1;

  if level.time < self^.pain_debounce_time then
    exit;

  self^.pain_debounce_time := level.time + 3;

  if skill^.value = 3 then
    exit;  // no pain anims in nightmare

  n := rand() mod 2;
  if n = 0 then
  begin
    self^.monsterinfo.currentmove := @infantry_move_pain1;
    gi.sound(self, CHAN_VOICE, sound_pain1, 1, ATTN_NORM, 0);
  end
  else
  begin
    self^.monsterinfo.currentmove := @infantry_move_pain2;
    gi.sound(self, CHAN_VOICE, sound_pain2, 1, ATTN_NORM, 0);
  end;
end;

const
  aimangles : Array[0..11] of vec3_t =
    (( 0.0,  5.0, 0.0),
     (10.0, 15.0, 0.0),
     (20.0, 25.0, 0.0),
     (25.0, 35.0, 0.0),
     (30.0, 40.0, 0.0),
     (30.0, 45.0, 0.0),
     (25.0, 50.0, 0.0),
     (20.0, 40.0, 0.0),
     (15.0, 35.0, 0.0),
     (40.0, 35.0, 0.0),
     (70.0, 35.0, 0.0),
     (90.0, 35.0, 0.0));

procedure InfantryMachineGun(self : edict_p);
var
  start, target : vec3_t;
  fwrd, right   : vec3_t;
  vec           : vec3_t;
  flash_number  : integer;
begin
  if self.s.frame = FRAME_attak111 then
  begin
    flash_number := MZ2_INFANTRY_MACHINEGUN_1;
    AngleVectors(self.s.angles, @fwrd, @right, nil);
    G_ProjectSource(self.s.origin, monster_flash_offset[flash_number], fwrd, right, start);

    if (self.enemy <> nil) then
    begin
      VectorMA(self.enemy.s.origin, -0.2, self.enemy.velocity, target);
      target[2] := target[2] + self.enemy.viewheight;
      VectorSubtract(target, start, fwrd);
      VectorNormalize(fwrd);
    end
    else
      AngleVectors(self.s.angles, @fwrd, @right, nil);
  end
  else
  begin
    flash_number := MZ2_INFANTRY_MACHINEGUN_2 + (self.s.frame - FRAME_death211);

    AngleVectors(self.s.angles, @fwrd, @right, nil);
    G_ProjectSource(self.s.origin, monster_flash_offset[flash_number], fwrd, right, start);

    VectorSubtract(self.s.angles, aimangles[flash_number-MZ2_INFANTRY_MACHINEGUN_2], vec);
    AngleVectors(vec, @fwrd, nil, nil);
  end;

  monster_fire_bullet(self, start, fwrd, 3, 4, DEFAULT_BULLET_HSPREAD, DEFAULT_BULLET_VSPREAD, flash_number);
end;

procedure infantry_sight(self, other : edict_p);
begin
  gi.sound(self, CHAN_BODY, sound_sight, 1, ATTN_NORM, 0);
end;

procedure infantry_dead(self : edict_p);
begin
  VectorSet(self.mins, -16, -16, -24);
  VectorSet(self.maxs, 16, 16, -8);
  self.movetype := MOVETYPE_TOSS;
  self.svflags  :=(self.svflags or SVF_DEADMONSTER);
  gi.linkentity(self);

  M_FlyCheck(self);
end;

const
  infantry_frames_death1 : Array[0..19] of mframe_t =
    ((aifunc:ai_move; dist:-4; thinkfunc:nil),
     (aifunc:ai_move; dist:0;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;  thinkfunc:nil),
     (aifunc:ai_move; dist:-1; thinkfunc:nil),
     (aifunc:ai_move; dist:-4; thinkfunc:nil),
     (aifunc:ai_move; dist:0;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;  thinkfunc:nil),
     (aifunc:ai_move; dist:-1; thinkfunc:nil),
     (aifunc:ai_move; dist:3;  thinkfunc:nil),
     (aifunc:ai_move; dist:1;  thinkfunc:nil),
     (aifunc:ai_move; dist:1;  thinkfunc:nil),
     (aifunc:ai_move; dist:-2; thinkfunc:nil),
     (aifunc:ai_move; dist:2;  thinkfunc:nil),
     (aifunc:ai_move; dist:2;  thinkfunc:nil),
     (aifunc:ai_move; dist:9;  thinkfunc:nil),
     (aifunc:ai_move; dist:9;  thinkfunc:nil),
     (aifunc:ai_move; dist:5;  thinkfunc:nil),
     (aifunc:ai_move; dist:-3; thinkfunc:nil),
     (aifunc:ai_move; dist:-3; thinkfunc:nil));

  infantry_move_death1 : mmove_t =
    (firstframe:FRAME_death101; lastframe:FRAME_death120; frame:@infantry_frames_death1; endfunc:infantry_dead);

// Off with his head
const
  infantry_frames_death2 : Array[0..24] of mframe_t =
    ((aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:1;   thinkfunc:nil),
     (aifunc:ai_move; dist:5;   thinkfunc:nil),
     (aifunc:ai_move; dist:-1;  thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:1;   thinkfunc:nil),
     (aifunc:ai_move; dist:1;   thinkfunc:nil),
     (aifunc:ai_move; dist:4;   thinkfunc:nil),
     (aifunc:ai_move; dist:3;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:-2;  thinkfunc:InfantryMachineGun),
     (aifunc:ai_move; dist:-2;  thinkfunc:InfantryMachineGun),
     (aifunc:ai_move; dist:-3;  thinkfunc:InfantryMachineGun),
     (aifunc:ai_move; dist:-1;  thinkfunc:InfantryMachineGun),
     (aifunc:ai_move; dist:-2;  thinkfunc:InfantryMachineGun),
     (aifunc:ai_move; dist:0;   thinkfunc:InfantryMachineGun),
     (aifunc:ai_move; dist:2;   thinkfunc:InfantryMachineGun),
     (aifunc:ai_move; dist:2;   thinkfunc:InfantryMachineGun),
     (aifunc:ai_move; dist:3;   thinkfunc:InfantryMachineGun),
     (aifunc:ai_move; dist:-10; thinkfunc:InfantryMachineGun),
     (aifunc:ai_move; dist:-7;  thinkfunc:InfantryMachineGun),
     (aifunc:ai_move; dist:-8;  thinkfunc:InfantryMachineGun),
     (aifunc:ai_move; dist:-6;  thinkfunc:nil),
     (aifunc:ai_move; dist:4;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil));

  infantry_move_death2 : mmove_t =
    (firstframe:FRAME_death201; lastframe:FRAME_death225; frame:@infantry_frames_death2; endfunc:infantry_dead);

const
  infantry_frames_death3 : Array[0..8] of mframe_t =
    ((aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:-6;  thinkfunc:nil),
     (aifunc:ai_move; dist:-11; thinkfunc:nil),
     (aifunc:ai_move; dist:-3;  thinkfunc:nil),
     (aifunc:ai_move; dist:-11; thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil),
     (aifunc:ai_move; dist:0;   thinkfunc:nil));

  infantry_move_death3 : mmove_t =
    (firstframe:FRAME_death301; lastframe:FRAME_death309; frame:@infantry_frames_death3; endfunc:infantry_dead);

procedure infantry_die(self, inflictor, attacker : edict_p; damage : Integer; const point : vec3_t);
var
  n : Integer;
begin
  // check for gib
  if self^.health <= self^.gib_health then
  begin
    gi.sound(self, CHAN_VOICE, gi.soundindex('misc/udeath.wav'), 1, ATTN_NORM, 0);
    for n := 0 to 1 do
      ThrowGib(self, 'models/objects/gibs/bone/tris.md2', damage, GIB_ORGANIC);
    for n := 0 to 3 do
      ThrowGib(self, 'models/objects/gibs/sm_meat/tris.md2', damage, GIB_ORGANIC);
    ThrowHead(self, 'models/objects/gibs/head2/tris.md2', damage, GIB_ORGANIC);
    self^.deadflag := DEAD_DEAD;
    exit;
  end;

  if (self.deadflag = DEAD_DEAD) then
    exit;

  // regular death
  self^.deadflag := DEAD_DEAD;
  self^.takedamage := DAMAGE_YES;

  n := rand() mod 3;
  if n = 0 then
  begin
    self^.monsterinfo.currentmove := @infantry_move_death1;
    gi.sound(self, CHAN_VOICE, sound_die2, 1, ATTN_NORM, 0);
  end
  else
  if n =1 then
  begin
    self^.monsterinfo.currentmove := @infantry_move_death2;
    gi.sound(self, CHAN_VOICE, sound_die1, 1, ATTN_NORM, 0);
  end
  else
  begin
    self^.monsterinfo.currentmove := @infantry_move_death3;
    gi.sound(self, CHAN_VOICE, sound_die2, 1, ATTN_NORM, 0);
  end;
end;

procedure infantry_duck_down(self : edict_p);
begin
  if (self.monsterinfo.aiflags and AI_DUCKED) <> 0 then
    exit;
  self.monsterinfo.aiflags:= (self.monsterinfo.aiflags or AI_DUCKED);
  self.maxs[2] := self.maxs[2] - 32;
  self.takedamage := DAMAGE_YES;
  self.monsterinfo.pausetime := level.time + 1;
  gi.linkentity(self);
end;

procedure infantry_duck_hold(self : edict_p);
begin
  if level.time >= self.monsterinfo.pausetime then
    self.monsterinfo.aiflags := (self.monsterinfo.aiflags and not AI_HOLD_FRAME)
  else
    self.monsterinfo.aiflags := (self.monsterinfo.aiflags or AI_HOLD_FRAME);
end;

procedure infantry_duck_up(self : edict_p);
begin
  self.monsterinfo.aiflags := (self.monsterinfo.aiflags and AI_DUCKED);
  self.maxs[2] := self.maxs[2] + 32;
  self.takedamage := DAMAGE_AIM;
  gi.linkentity(self);
end;

const
  infantry_frames_duck : Array[0..4] of mframe_t =
    ((aifunc:ai_move; dist:-2; thinkfunc:infantry_duck_down),
     (aifunc:ai_move; dist:-5; thinkfunc:infantry_duck_hold),
     (aifunc:ai_move; dist:3;  thinkfunc:nil),
     (aifunc:ai_move; dist:4;  thinkfunc:infantry_duck_up),
     (aifunc:ai_move; dist:0;  thinkfunc:nil));

  infantry_move_duck : mmove_t =
    (firstframe:FRAME_duck01; lastframe:FRAME_duck05; frame:@infantry_frames_duck; endfunc:infantry_run);

procedure infantry_dodge(self, attacker : edict_p; eta : single);
begin
  if _random() > 0.25 then
    exit;

  if (self.enemy = nil) then
    self.enemy := attacker;

  self.monsterinfo.currentmove := @infantry_move_duck;
end;

procedure infantry_cock_gun(self : edict_p);
var
  n : integer;
begin
  gi.sound(self, CHAN_WEAPON, sound_weapon_cock, 1, ATTN_NORM, 0);
  n := (rand() AND 15) + 3 + 7;
  self^.monsterinfo.pausetime := level.time + n * FRAMETIME;
end;

procedure infantry_fire(self : edict_p);
begin
  InfantryMachineGun(self);
  if level.time >= self.monsterinfo.pausetime then
    self.monsterinfo.aiflags := (self.monsterinfo.aiflags and not AI_HOLD_FRAME)
  else
    self.monsterinfo.aiflags := (self.monsterinfo.aiflags or AI_HOLD_FRAME);
end;

const
  infantry_frames_attack1 : Array[0..14] of mframe_t =
    ((aifunc:ai_charge; dist:4;  thinkfunc:nil),
     (aifunc:ai_charge; dist:-1; thinkfunc:nil),
     (aifunc:ai_charge; dist:-1; thinkfunc:nil),
     (aifunc:ai_charge; dist:0;  thinkfunc:infantry_cock_gun),
     (aifunc:ai_charge; dist:-1; thinkfunc:nil),
     (aifunc:ai_charge; dist:1;  thinkfunc:nil),
     (aifunc:ai_charge; dist:1;  thinkfunc:nil),
     (aifunc:ai_charge; dist:2;  thinkfunc:nil),
     (aifunc:ai_charge; dist:-2; thinkfunc:nil),
     (aifunc:ai_charge; dist:-3; thinkfunc:nil),
     (aifunc:ai_charge; dist:1;  thinkfunc:infantry_fire),
     (aifunc:ai_charge; dist:5;  thinkfunc:nil),
     (aifunc:ai_charge; dist:-1; thinkfunc:nil),
     (aifunc:ai_charge; dist:-2; thinkfunc:nil),
     (aifunc:ai_charge; dist:-3; thinkfunc:nil));

  infantry_move_attack1 : mmove_t =
    (firstframe:FRAME_attak101; lastframe:FRAME_attak115; frame:@infantry_frames_attack1; endfunc:infantry_run);

procedure infantry_swing(self : edict_p);
begin
  gi.sound(self, CHAN_WEAPON, sound_punch_swing, 1, ATTN_NORM, 0);
end;

procedure infantry_smack(self : edict_p);
var
  aim : vec3_t;
begin
  VectorSet(aim, MELEE_DISTANCE, 0, 0);
  if fire_hit(Self, aim, (5 + (rand() mod 5)), 50) then
    gi.sound(self, CHAN_WEAPON, sound_punch_hit, 1, ATTN_NORM, 0);
end;

const
  infantry_frames_attack2 : Array[0..7] of mframe_t =
    ((aifunc:ai_charge; dist:3; thinkfunc:nil),
     (aifunc:ai_charge; dist:6; thinkfunc:nil),
     (aifunc:ai_charge; dist:0; thinkfunc:infantry_swing),
     (aifunc:ai_charge; dist:8; thinkfunc:nil),
     (aifunc:ai_charge; dist:5; thinkfunc:nil),
     (aifunc:ai_charge; dist:8; thinkfunc:infantry_smack),
     (aifunc:ai_charge; dist:6; thinkfunc:nil),
     (aifunc:ai_charge; dist:3; thinkfunc:nil));

  infantry_move_attack2 : mmove_t =
    (firstframe:FRAME_attak201; lastframe:FRAME_attak208; frame:@infantry_frames_attack2; endfunc:infantry_run);

procedure infantry_attack(self : edict_p);
begin
  if range(self, self.enemy) = RANGE_MELEE then
    self.monsterinfo.currentmove := @infantry_move_attack2
  else
    self.monsterinfo.currentmove := @infantry_move_attack1;
end;

{QUAKED monster_infantry (1 .5 0) (-16 -16 -24) (16 16 32) Ambush Trigger_Spawn Sight}
procedure SP_monster_infantry(self : edict_p);
begin
  if deathmatch.value <> 0 then
  begin
    G_FreeEdict(self);
    exit;
  end;

  sound_pain1 := gi.soundindex('infantry/infpain1.wav');
  sound_pain2 := gi.soundindex('infantry/infpain2.wav');
  sound_die1  := gi.soundindex('infantry/infdeth1.wav');
  sound_die2  := gi.soundindex('infantry/infdeth2.wav');

  sound_gunshot     := gi.soundindex('infantry/infatck1.wav');
  sound_weapon_cock := gi.soundindex('infantry/infatck3.wav');
  sound_punch_swing := gi.soundindex('infantry/infatck2.wav');
  sound_punch_hit   := gi.soundindex('infantry/melee2.wav');

  sound_sight  := gi.soundindex('infantry/infsght1.wav');
  sound_search := gi.soundindex('infantry/infsrch1.wav');
  sound_idle   := gi.soundindex('infantry/infidle1.wav');

  self.movetype := MOVETYPE_STEP;
  self.solid := SOLID_BBOX;
  self.s.modelindex := gi.modelindex('models/monsters/infantry/tris.md2');
  VectorSet(self.mins, -16, -16, -24);
  VectorSet(self.maxs, 16, 16, 32);

  self.health     := 100;
  self.gib_health := -40;
  self.mass       := 200;

  self.pain := infantry_pain;
  self.die  := Infantry_die;

  self.monsterinfo.stand  := infantry_stand;
  self.monsterinfo.walk   := infantry_walk;
  self.monsterinfo.run    := infantry_run;
  self.monsterinfo.dodge  := infantry_dodge;
  self.monsterinfo.attack := infantry_attack;
  self.monsterinfo.melee  := nil;
  self.monsterinfo.sight  := infantry_sight;
  self.monsterinfo.idle   := infantry_fidget;

  gi.linkentity(self);

  self.monsterinfo.currentmove := @infantry_move_stand;
  self.monsterinfo.scale       := MODEL_SCALE;

  walkmonster_start(self);
end;

end.
