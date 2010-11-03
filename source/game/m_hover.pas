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



{
=======================================

hover

=======================================
}

// m_hover.c and m_hover.h
// converted by Bob Janova <bob@redcorona.com>

{ ISSUES to be resolved:
 MFrame_t lists - array or pointer? (see line 100) - incompat. types
 Should procedures be declared CDECL, SAFECALL or neither?





}

unit m_hover;

interface

uses
  g_local,    // g_local.h
  q_shared;

{$I m_hover.inc} // m_hover.h


var sound_pain1, sound_pain2,
   sound_death1, sound_death2,
   sound_sight,
   sound_search1, sound_search2: Integer;

procedure hover_run (Self: edict_p); cdecl;
procedure hover_stand (Self: edict_p); cdecl;
procedure hover_dead (Self: edict_p); cdecl;
procedure hover_attack (Self: edict_p); cdecl;
procedure hover_reattack (Self: edict_p); cdecl;
procedure hover_fire_blaster (Self: edict_p); cdecl;
procedure hover_die (Self, Inflictor, Attacker: edict_p; Damage: Integer; const Point: Vec3_t); cdecl;

procedure SP_monster_hover (Self: edict_p); cdecl;


implementation

uses g_ai, g_main, g_utils, m_flash, g_monster, g_misc, g_local_add,
  game_add;

const hover_frames_stand: array[0..29] of mframe_t = (
 (AIFunc: AI_Stand; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Stand; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Stand; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Stand; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Stand; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Stand; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Stand; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Stand; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Stand; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Stand; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Stand; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Stand; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Stand; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Stand; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Stand; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Stand; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Stand; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Stand; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Stand; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Stand; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Stand; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Stand; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Stand; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Stand; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Stand; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Stand; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Stand; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Stand; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Stand; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Stand; Dist: 0; ThinkFunc: nil) );

Hover_move_stand: MMove_t = (
 FirstFrame:FRAME_stand01; LastFrame:FRAME_stand30; Frame:@hover_frames_stand; EndFunc: nil);

hover_frames_stop1: array [0..8] of MFrame_t = (
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil));

Hover_move_stop1: MMove_t = (
 FirstFrame:FRAME_stop101; LastFrame:FRAME_stop109; Frame:@hover_frames_stop1; EndFunc:nil);

hover_frames_stop2: array [0..7] of MFrame_t = (
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil));

Hover_move_stop2: MMove_t = (
 FirstFrame:FRAME_stop201; LastFrame:FRAME_stop208; Frame:@hover_frames_stop2; EndFunc:nil);

Hover_frames_takeoff: Array[0..29] of MFrame_t = (
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: -2; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 5; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: -1; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 1; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: -1; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: -1; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: -1; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 2; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 2; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 1; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 1; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: -6; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: -9; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 1; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 2; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 2; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 1; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 1; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 1; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 2; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 2; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 3; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 2; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil));

Hover_move_takeoff: MMove_t = (
 FirstFrame:FRAME_takeof01; LastFrame:FRAME_takeof30; Frame:@hover_frames_takeoff; EndFunc:nil);

hover_frames_pain3: array [0..8] of MFrame_t = (
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil));

Hover_move_pain3: MMove_t = (
 FirstFrame:FRAME_pain301; LastFrame:FRAME_pain309; Frame:@hover_frames_pain3; endfunc:Hover_Run);

hover_frames_pain2: array [0..11] of MFrame_t = (
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil));

Hover_move_pain2: MMove_t = (
 FirstFrame:FRAME_pain201; LastFrame:FRAME_pain212; Frame:@hover_frames_pain2; endfunc:Hover_Run);

hover_frames_pain1: array [0..27] of MFrame_t = (
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 2; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: -8; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: -4; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: -6; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: -4; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: -3; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 1; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 3; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 1; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 2; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 3; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 2; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 7; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 1; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 2; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 5; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 3; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 4; ThinkFunc: nil));

Hover_move_pain1: MMove_t = (
 FirstFrame:FRAME_pain101; LastFrame:FRAME_pain128; Frame:@hover_frames_pain1; endfunc:Hover_Run);

hover_frames_land: Array[0..0] of MFrame_t = (
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil));

Hover_move_land: MMove_t = (
 FirstFrame:FRAME_land01; LastFrame:FRAME_land01; Frame:@hover_frames_land; EndFunc:nil);

hover_frames_forward: Array[0..34] of MFrame_t = (
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil));

Hover_move_forward: MMove_t = (
 FirstFrame:FRAME_forwrd01; LastFrame:FRAME_forwrd35; Frame:@hover_frames_forward; EndFunc:nil);

hover_frames_walk: Array[0..34] of MFrame_t = (
 (AIFunc: AI_Move; Dist: 4; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 4; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 4; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 4; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 4; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 4; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 4; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 4; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 4; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 4; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 4; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 4; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 4; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 4; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 4; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 4; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 4; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 4; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 4; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 4; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 4; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 4; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 4; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 4; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 4; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 4; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 4; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 4; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 4; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 4; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 4; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 4; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 4; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 4; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 4; ThinkFunc: nil));

Hover_move_walk: MMove_t = (
 FirstFrame:FRAME_forwrd01; LastFrame:FRAME_forwrd35; Frame:@hover_frames_walk; EndFunc:nil);

hover_frames_run: Array[0..34] of MFrame_t = (
 (AIFunc: AI_Move; Dist: 10; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 10; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 10; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 10; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 10; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 10; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 10; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 10; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 10; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 10; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 10; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 10; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 10; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 10; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 10; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 10; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 10; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 10; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 10; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 10; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 10; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 10; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 10; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 10; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 10; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 10; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 10; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 10; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 10; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 10; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 10; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 10; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 10; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 10; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 10; ThinkFunc: nil));

Hover_move_run: MMove_t = (
 FirstFrame:FRAME_forwrd01; LastFrame:FRAME_forwrd35; Frame:@hover_frames_run; EndFunc:nil);

hover_frames_death1: Array[0..10] of MFrame_t = (
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: -10; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 3; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 5; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 4; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 7; ThinkFunc: nil));

Hover_move_death1: MMove_t = (
 FirstFrame:FRAME_death101; LastFrame:FRAME_death111; Frame:@hover_frames_death1; EndFunc:Hover_Dead);

hover_frames_backward: Array[0..23] of MFrame_t = (
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil),
 (AIFunc: AI_Move; Dist: 0; ThinkFunc: nil));

Hover_move_backward: MMove_t = (
 FirstFrame:FRAME_backwd01; LastFrame:FRAME_backwd24; Frame:@hover_frames_backward; EndFunc:nil);

hover_frames_start_attack: Array[0..2] of MFrame_t = (
 (AIFunc: AI_Charge; Dist: 1; ThinkFunc: nil),
 (AIFunc: AI_Charge; Dist: 1; ThinkFunc: nil),
 (AIFunc: AI_Charge; Dist: 1; ThinkFunc: nil));

Hover_move_start_attack: MMove_t = (
 FirstFrame:FRAME_attak101; LastFrame:FRAME_attak103; Frame:@hover_frames_start_attack; EndFunc:Hover_Attack);

hover_frames_attack1: Array[0..2] of MFrame_t = (
 (AIFunc: AI_Charge; Dist: -10; ThinkFunc: Hover_Fire_Blaster),
 (AIFunc: AI_Charge; Dist: -10; ThinkFunc: Hover_Fire_Blaster),
 (AIFunc: AI_Charge; Dist: 0; ThinkFunc: Hover_ReAttack));

Hover_move_attack1: MMove_t = (
 FirstFrame:FRAME_attak104; LastFrame:FRAME_attak106; Frame:@hover_frames_attack1; EndFunc:nil);

hover_frames_end_attack: Array[0..1] of MFrame_t = (
 (AIFunc: AI_Charge; Dist: 1; ThinkFunc: nil),
 (AIFunc: AI_Charge; Dist: 1; ThinkFunc: nil));

Hover_move_end_attack: MMove_t = (
 FirstFrame:FRAME_attak107; LastFrame:FRAME_attak108; Frame:@hover_frames_end_attack; EndFunc:Hover_Run);

procedure hover_reattack (Self: edict_p);
begin
if (self^.enemy^.health > 0) then
 if visible (self, self^.enemy) then
  if (_random() <= 0.6) then begin
   self^.monsterinfo.currentmove := @hover_move_attack1;
   exit;
  end;
Self^.monsterinfo.currentmove := @hover_move_end_attack;
end;

procedure hover_sight (Self, Other: edict_p); cdecl;
begin
  gi.sound (self, CHAN_VOICE, sound_sight, 1, ATTN_NORM, 0);
end;

procedure hover_search (Self: edict_p); cdecl;
begin
if _random() < 0.5 then
 gi.sound (self, CHAN_VOICE, sound_search1, 1, ATTN_NORM, 0)
else gi.sound (self, CHAN_VOICE, sound_search2, 1, ATTN_NORM, 0);
end;

procedure hover_fire_blaster (Self: edict_p);
var Start, ForwardV, Right, EndV, Dir: Vec3_t;
 Effect: Integer;
begin
if (self^.s.frame = FRAME_attak104) then effect := EF_HYPERBLASTER
else effect := 0;

AngleVectors (self^.s.angles, @forwardv, @right, nil);
G_ProjectSource (self^.s.origin, monster_flash_offset[MZ2_HOVER_BLASTER_1], forwardv, right, start);

VectorCopy (self^.enemy^.s.origin, endv);
endv[2] := EndV[2] + self^.enemy^.viewheight;
VectorSubtract (endv, start, dir);

monster_fire_blaster (self, start, dir, 1, 1000, MZ2_HOVER_BLASTER_1, effect);
end;


procedure hover_stand (Self: edict_p);
begin
self^.monsterinfo.currentmove := @hover_move_stand;
end;

procedure hover_run (Self: edict_p); 
begin
if (self^.monsterinfo.aiflags and AI_STAND_GROUND) > 0 then
 self^.monsterinfo.currentmove := @hover_move_stand
else self^.monsterinfo.currentmove := @hover_move_run;
end;

procedure hover_walk (Self: edict_p); cdecl;
begin
self^.monsterinfo.currentmove := @hover_move_walk;
end;

procedure hover_start_attack (Self: edict_p); cdecl;
begin
self^.monsterinfo.currentmove := @hover_move_start_attack;
end;

procedure hover_attack(Self: edict_p);
begin
self^.monsterinfo.currentmove := @hover_move_attack1;
end;


procedure hover_pain (Self, Other: edict_p; Kick: Single; Damage: Integer); cdecl;
begin
if (self^.health < (self^.max_health / 2)) then self^.s.skinnum := 1;
if (level.time < self^.pain_debounce_time) then exit;

self^.pain_debounce_time := level.time + 3;

if (skill^.value = 3) then exit;   // no pain anims in nightmare

if (damage <= 25) then begin
 if (_random() < 0.5) then begin
  gi.sound (self, CHAN_VOICE, sound_pain1, 1, ATTN_NORM, 0);
  self^.monsterinfo.currentmove := @hover_move_pain3;
 end else begin
  gi.sound (self, CHAN_VOICE, sound_pain2, 1, ATTN_NORM, 0);
  self^.monsterinfo.currentmove := @hover_move_pain2;
 end;
end else begin
 gi.sound (self, CHAN_VOICE, sound_pain1, 1, ATTN_NORM, 0);
 self^.monsterinfo.currentmove := @hover_move_pain1;
end;
end;

procedure hover_deadthink (Self: edict_p); cdecl;
begin
if (self^.groundentity = nil) and (level.time < self^.timestamp) then begin
 self^.nextthink := level.time + FRAMETIME;
 exit;
end;
BecomeExplosion1(self);
end;

procedure hover_dead (Self: edict_p);
begin
VectorSet (self^.mins, -16, -16, -24);
VectorSet (self^.maxs, 16, 16, -8);
self^.movetype := MOVETYPE_TOSS;
self^.think := hover_deadthink;
self^.nextthink := level.time + FRAMETIME;
self^.timestamp := level.time + 15;
gi.linkentity (self);
end;

procedure hover_die (Self, Inflictor, Attacker: edict_p; Damage: Integer; const Point: Vec3_t);
var n: Integer;
begin
// check for gib
if (self^.health <= self^.gib_health) then begin
 gi.sound (self, CHAN_VOICE, gi.soundindex ('misc/udeath.wav'), 1, ATTN_NORM, 0);
 for n := 0 to 1 do
  ThrowGib (self, 'models/objects/gibs/bone/tris.md2', damage, GIB_ORGANIC);
 for n := 0 to 1 do
  ThrowGib (self, 'models/objects/gibs/sm_meat/tris.md2', damage, GIB_ORGANIC);
 ThrowHead (self, 'models/objects/gibs/sm_meat/tris.md2', damage, GIB_ORGANIC);
 self^.deadflag := DEAD_DEAD;
 exit;
end;

if (self^.deadflag = DEAD_DEAD) then exit;

// regular death
if (_random() < 0.5) then
 gi.sound (self, CHAN_VOICE, sound_death1, 1, ATTN_NORM, 0)
else gi.sound (self, CHAN_VOICE, sound_death2, 1, ATTN_NORM, 0);
self^.deadflag := DEAD_DEAD;
self^.takedamage := DAMAGE_YES;
self^.monsterinfo.currentmove := @hover_move_death1;
end;

{QUAKED monster_hover (1 .5 0) (-16 -16 -24) (16 16 32) Ambush Trigger_Spawn Sight
}
procedure SP_monster_hover (Self: edict_p);
begin
if deathmatch^.value > 0 then begin
 G_FreeEdict (self);
 exit;
end;

sound_pain1 := gi.soundindex ('hover/hovpain1.wav');
sound_pain2 := gi.soundindex ('hover/hovpain2.wav');
sound_death1 := gi.soundindex ('hover/hovdeth1.wav');
sound_death2 := gi.soundindex ('hover/hovdeth2.wav');
sound_sight := gi.soundindex ('hover/hovsght1.wav');
sound_search1 := gi.soundindex ('hover/hovsrch1.wav');
sound_search2 := gi.soundindex ('hover/hovsrch2.wav');

gi.soundindex ('hover/hovatck1.wav');

self^.s.sound := gi.soundindex ('hover/hovidle1.wav');

self^.movetype := MOVETYPE_STEP;
self^.solid := SOLID_BBOX;
self^.s.modelindex := gi.modelindex('models/monsters/hover/tris.md2');
VectorSet (self^.mins, -24, -24, -24);
VectorSet (self^.maxs, 24, 24, 32);

self^.health := 240;
self^.gib_health := -100;
self^.mass := 150;

self^.pain := hover_pain;
self^.die := hover_die;

self^.monsterinfo.stand := hover_stand;
self^.monsterinfo.walk := hover_walk;
self^.monsterinfo.run := hover_run;
//self^.monsterinfo.dodge := hover_dodge;
self^.monsterinfo.attack := hover_start_attack;
self^.monsterinfo.sight := hover_sight;
self^.monsterinfo.search := hover_search;

gi.linkentity (self);

self^.monsterinfo.currentmove := @hover_move_stand;
self^.monsterinfo.scale := MODEL_SCALE;

flymonster_start (self);
end;

end.
