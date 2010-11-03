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


//This is "COMMON" file for \GAME\p_hud.pas & \CTF\p_hud.pas
{$DEFINE CTF}
{$IFDEF CTF}
{$ELSE}
{$ENDIF}

// PLEASE, don't modify this file
// 70% complete

{----------------------------------------------------------------------------}
{                                                                            }
{ File(s): p_view.c                                                          }
{                                                                            }
{ Initial conversion by : YgriK (Igor Karpov) - glYgriK@hotbox.ru            }
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
{ 1) g_local.??? (inc & pas)                                                 }
{                                                                            }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{ 1) Do more tests                                                           }
{                                                                            }
{----------------------------------------------------------------------------}

#include "g_local.h"
#include "m_player.h"



static   edict_t      *current_player;
static   gclient_t   *current_client;

static   vec3_t   forward, right, up;
float   xyspeed;

float   bobmove;
int      bobcycle;      // odd cycles are right foot going forward
float   bobfracsin;      // sin(bobfrac*M_PI)

{*
===============
SV_CalcRoll
===============
*}
// (GAME=CTF)
function SV_CalcRoll (vec3_t angles, vec3_t velocity) : float;
var
  sign,
  side,
  value : float;
begin
  side := DotProduct (velocity, right);
//  sign = side < 0 ? -1 : 1;
  if side < 0
  then sign := -1
  else sign := 1;
  side := abs(side);

  value := sv_rollangle.value;

  if (side < sv_rollspeed.value)
  then side := side * value / sv_rollspeed.value;
  else side := value;

  Result := side*sign;
end;//function (GAME=CTF)


{*
===============
P_DamageFeedback

Handles color blends and view kicks
===============
*}
// (GAME=CTF)
procedure P_DamageFeedback (edict_t *player);
var
   gclient_t   *client;
  side;
  realcount, count, kick : float;
  v                      : vec3_t;
  r, l                   : integer;

    static int      i;

const
  power_color : vec3_t = (0.0, 1.0, 0.0);
  acolor      : vec3_t = (1.0, 1.0, 1.0);
  bcolor      : vec3_t = (1.0, 0.0, 0.0);
begin
  client := player.client;

  // flash the backgrounds behind the status numbers
  client.ps.stats[STAT_FLASHES] := 0;
  if (client.damage_blood) then
    client.ps.stats[STAT_FLASHES] := client.ps.stats[STAT_FLASHES] OR 1;
  if (client.damage_armor AND !(player.flags & FL_GODMODE) AND (client.invincible_framenum <= level.framenum)) then
    client.ps.stats[STAT_FLASHES] := client.ps.stats[STAT_FLASHES] OR 2;

  // total points of damage shot at the player this frame
  count := (client.damage_blood + client.damage_armor + client.damage_parmor);
  if (count = 0) then
    Exit;    // didn't take any damage

  // start a pain animation if still in the player model
  if (client.anim_priority < ANIM_PAIN) AND (player.s.modelindex = 255) then
  begin
    client.anim_priority := ANIM_PAIN;
    if (client.ps.pmove.pm_flags & PMF_DUCKED)
    then begin
      player.s.frame := FRAME_crpain1-1;
      client.anim_end := FRAME_crpain4;
    end
    else begin
      i := (i+1) MOD 3;
      Case i of
        0: begin
             player.s.frame := FRAME_pain101-1;
             client.anim_end := FRAME_pain104;
            end;
        1: begin
             player.s.frame := FRAME_pain201-1;
             client.anim_end := FRAME_pain204;
            end;
        2: begin
             player.s.frame := FRAME_pain301-1;
             client.anim_end := FRAME_pain304;
            end;
      end;//case
    end;//else
  end;//if

  realcount := count;
  if (count < 10) then
    count := 10;   // allways make a visible effect

  // play an apropriate pain sound
  if ((level.time > player.pain_debounce_time) && !(player->flags & FL_GODMODE) && (client.invincible_framenum <= level.framenum)) then
  begin
{Y}    r = 1 + (rand()&1);
    player.pain_debounce_time := level.time + 0.7;
    if (player.health < 25)
    then l := 25
    else
      if (player.health < 50)
      then l := 50
      else
        if (player.health < 75)
        then l := 75
        else l := 100;
    gi.sound (player, CHAN_VOICE, gi.soundindex(va('*pain%i_%i.wav', l, r)), 1, ATTN_NORM, 0);
  end;

  // the total alpha of the blend is allways proportional to count
  if (client.damage_alpha < 0) then
    client.damage_alpha := 0;
  client.damage_alpha := client.damage_alpha + count*0.01;
  if (client.damage_alpha < 0.2) then
    client.damage_alpha := 0.2;
  if (client.damage_alpha > 0.6) then
    client.damage_alpha := 0.6;      // don't go too saturated

  // the color of the blend will vary based on how much was absorbed
  // by different armors
  VectorClear (v);
  if (client.damage_parmor) then
    VectorMA (v, (float)client.damage_parmor/realcount, power_color, v);
  if (client.damage_armor) then
    VectorMA (v, (float)client.damage_armor/realcount,  acolor, v);
  if (client.damage_blood) then
    VectorMA (v, (float)client.damage_blood/realcount,  bcolor, v);
  VectorCopy (v, client.damage_blend);


  //
  // calculate view angle kicks
  //
  kick := abs(client.damage_knockback);
  if (kick <> 0) AND (player.health > 0) then  // kick of 0 means no view adjust at all
  begin
    kick := kick * 100 / player.health;

    if (kick < count*0.5) then
      kick := count*0.5;
    if (kick > 50) then
      kick := 50;

    VectorSubtract (client.damage_from, player.s.origin, v);
    VectorNormalize (v);

    side := DotProduct (v, right);
    client.v_dmg_roll := kick*side*0.3;

    side := -DotProduct (v, forward);
    client.v_dmg_pitch := kick*side*0.3;

    client.v_dmg_time := level.time + DAMAGE_TIME;
  end;

  //
  // clear totals
  //
  client.damage_blood := 0;
  client.damage_armor := 0;
  client.damage_parmor := 0;
  client.damage_knockback := 0;
end;//procedure (GAME=CTF)


{*
===============
SV_CalcViewOffset

Auto pitching on slopes?

  fall from 128: 400 = 160000
  fall from 256: 580 = 336400
  fall from 384: 720 = 518400
  fall from 512: 800 = 640000
  fall from 640: 960 =

  damage = deltavelocity*deltavelocity  * 0.0001

===============
*}
// (GAME=CTF)
procedure SV_CalcViewOffset (edict_t *ent);
var
   float      *angles;
  bob,
  ratio,
  delta : float;
  v     : vec3_t;
begin
//===================================

  // base angles
  angles := ent.client.ps.kick_angles;

  // if dead, fix the angle and don't add any kick
  if (ent.deadflag)
  then begin
    VectorClear (angles);

    ent.client.ps.viewangles[ROLL] := 40;
    ent.client.ps.viewangles[PITCH] := -15;
    ent.client.ps.viewangles[YAW] := ent.client.killer_yaw;
  end
  else begin
    // add angles based on weapon kick

    VectorCopy (ent.client.kick_angles, angles);

    // add angles based on damage kick

    ratio := (ent.client.v_dmg_time - level.time) / DAMAGE_TIME;
    if (ratio < 0) then
    begin
      ratio := 0;
      ent.client.v_dmg_pitch := 0;
      ent.client.v_dmg_roll := 0;
    end;
    angles[PITCH] := angles[PITCH] + ratio * ent.client.v_dmg_pitch;
    angles[ROLL]  := angles[ROLL]  + ratio * ent.client.v_dmg_roll;

    // add pitch based on fall kick

    ratio := (ent.client.fall_time - level.time) / FALL_TIME;
    if (ratio < 0) then
      ratio = 0;
    angles[PITCH] := angles[PITCH] + ratio * ent.client.fall_value;

    // add angles based on velocity

    delta := DotProduct (ent.velocity, forward);
    angles[PITCH] := angles[PITCH] + delta*run_pitch.value;

    delta := DotProduct (ent.velocity, right);
    angles[ROLL] := angles[ROLL] + delta*run_roll.value;

    // add angles based on bob

    delta := bobfracsin * bob_pitch.value * xyspeed;
    if (ent.client.ps.pmove.pm_flags & PMF_DUCKED) then
      delta := delta * 6;   // crouching
    angles[PITCH] := angles[PITCH] + delta;
    delta := bobfracsin * bob_roll.value * xyspeed;
    if (ent.client.ps.pmove.pm_flags & PMF_DUCKED)
      delta := delta * 6;   // crouching
    if (bobcycle & 1) then
      delta := -delta;
    angles[ROLL] := angles[ROLL] + delta;
  end;

//===================================

  // base origin

  VectorClear (v);

  // add view height

  v[2] := v[2] + ent.viewheight;

  // add fall height

  ratio := (ent.client.fall_time - level.time) / FALL_TIME;
  if (ratio < 0) then
    ratio = 0;
  v[2] := v[2] - ratio * ent.client.fall_value * 0.4;

  // add bob height

  bob := bobfracsin * xyspeed * bob_up.value;
  if (bob > 6) then
    bob := 6;
  //idsoft gi.DebugGraph (bob *2, 255);
  v[2] := v[2] + bob;

  // add kick offset

  VectorAdd (v, ent.client.kick_origin, v);

  // absolutely bound offsets
  // so the view can never be outside the player box

  if (v[0] < -14)
  then v[0] := -14
  else
    if (v[0] > 14)
    then v[0] := 14
    else
      if (v[1] < -14)
      then v[1] := -14
      else
        if (v[1] > 14)
        then v[1] := 14
        else
          if (v[2] < -22)
          then v[2] := -22
          else
            if (v[2] > 30) then
              v[2] := 30;

  VectorCopy (v, ent.client.ps.viewoffset);
end;//procedure (GAME=CTF)


{*
==============
SV_CalcGunOffset
==============
*}
// (GAME=CTF)
procedure SV_CalcGunOffset (edict_t *ent);
var
  i     : integer;
  delta : float;
begin
  // gun angles from bobbing
  ent.client.ps.gunangles[ROLL] := xyspeed * bobfracsin * 0.005;
  ent.client.ps.gunangles[YAW] := xyspeed * bobfracsin * 0.01;
  if (bobcycle & 1) then
  begin
    ent.client.ps.gunangles[ROLL] := -ent.client.ps.gunangles[ROLL];
    ent.client.ps.gunangles[YAW]  := -ent.client.ps.gunangles[YAW];
  end;

  ent.client.ps.gunangles[PITCH] := xyspeed * bobfracsin * 0.005;

  // gun angles from delta movement
  for i:=0 to 2 do
  begin
    delta := ent->client->oldviewangles[i] - ent->client->ps.viewangles[i];
    if (delta > 180) then
      delta := delta - 360;
    if (delta < -180) then
      delta := delta + 360;
    if (delta > 45) then
      delta := 45;
    if (delta < -45) then
      delta := -45;
    if (i = YAW) then
      ent.client.ps.gunangles[ROLL] := ent.client.ps.gunangles[ROLL] + 0.1*delta;
    ent.client.ps.gunangles[i] := ent.client.ps.gunangles[i] + 0.2 * delta;
  end;

  // gun height
  VectorClear (ent.client.ps.gunoffset);
//idsoft   ent->ps->gunorigin[2] += bob;

  // gun_x / gun_y / gun_z are development tools
  for i:=0 to 2 do
  begin
(*    ent->client->ps.gunoffset[i] += forward[i]*(gun_y->value);
    ent->client->ps.gunoffset[i] += right[i]*gun_x->value;
    ent->client->ps.gunoffset[i] += up[i]* (-gun_z->value);*)
    ent.client.ps.gunoffset[i] := ent.client.ps.gunoffset[i] + forward[i]*gun_y.value +
                                                               right[i]*gun_x.value +
                                                               up[i]*(-gun_z.value);
  end;
end;//procedure (GAME=CTF)


{*
=============
SV_AddBlend
=============
*}
// (GAME=CTF)
procedure SV_AddBlend (r, g, b, a : float; float *v_blend);
var
  a2, a3 : float;
begin
  if (a <= 0) then
    Exit;
  a2 := v_blend[3] + (1-v_blend[3])*a;   // new total alpha
  a3 := v_blend[3]/a2;      // fraction of color from old

  v_blend[0] := v_blend[0]*a3 + r*(1-a3);
  v_blend[1] := v_blend[1]*a3 + g*(1-a3);
  v_blend[2] := v_blend[2]*a3 + b*(1-a3);
  v_blend[3] := a2;
end;//procedure (GAME=CTF)

{*
=============
SV_CalcBlend
=============
*}
// (GAME=CTF)
procedure SV_CalcBlend (edict_t *ent);
var
  vieworg   : vec3_t;
  contents,
  remaining : integer;
begin
  ent.client.ps.blend[0] := 0;
  ent.client.ps.blend[1] := 0;
  ent.client.ps.blend[2] := 0;
  ent.client.ps.blend[3] := 0;

  // add for contents
  VectorAdd (ent.s.origin, ent.client.ps.viewoffset, vieworg);
  contents := gi.pointcontents (vieworg);
  if (contents AND (CONTENTS_LAVA OR CONTENTS_SLIME OR CONTENTS_WATER) <> 0)
  then ent.client.ps.rdflags := ent.client.ps.rdflags OR RDF_UNDERWATER
  else ent.client.ps.rdflags := ent.client.ps.rdflags AND (NOT RDF_UNDERWATER);

  if (contents AND (CONTENTS_SOLID OR CONTENTS_LAVA) <> 0)
  then SV_AddBlend (1.0, 0.3, 0.0, 0.6, ent.client.ps.blend)
  else
    if (contents AND CONTENTS_SLIME <> 0)
    then SV_AddBlend (0.0, 0.1, 0.05, 0.6, ent.client.ps.blend)
    else
      if (contents AND CONTENTS_WATER <> 0) then
        SV_AddBlend (0.5, 0.3, 0.2, 0.4, ent.client.ps.blend);

  // add for powerups
  if (ent.client.quad_framenum > level.framenum)
  then begin
    remaining := ent.client.quad_framenum - level.framenum;
    if (remaining = 30)   then  // beginning to fade
      gi.sound(ent, CHAN_ITEM, gi.soundindex('items/damage2.wav'), 1, ATTN_NORM, 0);
    if (remaining > 30) OR (remaining & 4) then 
      SV_AddBlend (0, 0, 1, 0.08, ent.client.ps.blend);
  end
  else
    if (ent.client.invincible_framenum > level.framenum)
    then begin
      remaining := ent.client.invincible_framenum - level.framenum;
      if (remaining = 30) then  // beginning to fade
        gi.sound(ent, CHAN_ITEM, gi.soundindex('items/protect2.wav'), 1, ATTN_NORM, 0);
      if (remaining > 30) OR (remaining & 4) then
        SV_AddBlend (1, 1, 0, 0.08, ent.client.ps.blend);
    end
    else
      if (ent.client.enviro_framenum > level.framenum)
      then begin
        remaining := ent.client.enviro_framenum - level.framenum;
        if (remaining = 30) then  // beginning to fade
          gi.sound(ent, CHAN_ITEM, gi.soundindex('items/airout.wav'), 1, ATTN_NORM, 0);
        if (remaining > 30) OR (remaining & 4) then
          SV_AddBlend (0, 1, 0, 0.08, ent.client.ps.blend);
      end
      else
        if (ent.client.breather_framenum > level.framenum) then
        begin
          remaining := ent.client.breather_framenum - level.framenum;
          if (remaining = 30) then  // beginning to fade
            gi.sound(ent, CHAN_ITEM, gi.soundindex('items/airout.wav'), 1, ATTN_NORM, 0);
          if (remaining > 30) OR (remaining & 4)
            SV_AddBlend (0.4, 1, 0.4, 0.04, ent.client.ps.blend);
        end;

  // add for damage
  if (ent.client.damage_alpha > 0) then
    SV_AddBlend (ent.client.damage_blend[0], ent.client.damage_blend[1],
                 ent.client.damage_blend[2], ent.client.damage_alpha, ent.client.ps.blend);

  if (ent.client.bonus_alpha > 0) thne
    SV_AddBlend (0.85, 0.7, 0.3, ent.client.bonus_alpha, ent.client.ps.blend);

  // drop the damage value
  ent.client.damage_alpha := ent.client.damage_alpha - 0.06;
  if (ent.client.damage_alpha < 0) then
    ent.client.damage_alpha := 0;

  // drop the bonus value
  ent.client.bonus_alpha := ent.client.bonus_alpha - 0.1;
  if (ent.client.bonus_alpha < 0) then
    ent.client.bonus_alpha := 0;
end;//procedure (GAME=CTF)

{*
=================
P_FallingDamage
=================
*}
// (GAME <> CTF)
procedure P_FallingDamage (edict_t *ent);
var
  delta  : float;
  damage : integer;
  dir    : vec3_t;
begin
  if (ent.s.modelindex <> 255) then
    Exit;  // not in the player model

  if (ent.movetype = MOVETYPE_NOCLIP) then
    Exit;

  if ((ent.client.oldvelocity[2] < 0) AND (ent.velocity[2] > ent.client.oldvelocity[2]) AND (!ent.groundentity))
  then delta := ent.client.oldvelocity[2]
  else begin
    if (!ent.groundentity) then
      Exit;
    delta := ent.velocity[2] - ent.client.oldvelocity[2];
  end;
  delta := delta*delta * 0.0001;

{$IFDEF CTF}   //onlyCTF
//ZOID
  // never take damage if just release grapple or on grapple
  if ( (level.time - ent.client.ctf_grapplereleasetime <= FRAMETIME * 2) OR
       (ent.client.ctf_grapple AND ent.client.ctf_grapplestate > CTF_GRAPPLE_STATE_FLY) ) then
    Exit;
//ZOID
{$ENDIF}

  // never take falling damage if completely underwater
  if (ent.waterlevel = 3) then
    Exit;
  if (ent.waterlevel = 2) then
    delta := delta * 0.25;
  if (ent.waterlevel = 1) then
    delta := delta * 0.5;

  if (delta < 1) then
    Exit;
  if (delta < 15) then
  begin
    ent.s.event := EV_FOOTSTEP;
    Exit;
  end;

  ent.client.fall_value := delta*0.5;
  if (ent.client.fall_value > 40) then
    ent.client.fall_value := 40;
  ent.client.fall_time := level.time + FALL_TIME;

  if (delta > 30)
  then begin
    if (ent.health > 0) then
      if (delta >= 55)
      then ent.s.event := EV_FALLFAR
      else ent.s.event := EV_FALL;
    ent.pain_debounce_time := level.time;  // no normal pain sound
    damage := (delta-30)/2;
    if (damage < 1) then
      damage := 1;
    VectorSet (dir, 0, 0, 1);

    if (!deathmatch.value OR !((int)dmflags.value & DF_NO_FALLING) ) then
      T_Damage (ent, world, world, dir, ent.s.origin, vec3_origin, damage, 0, 0, MOD_FALLING);
  end
  else begin
    ent.s.event := EV_FALLSHORT;
    Exit;
  end;
end;//procedure (GAME <> CTF)


{*
=============
P_WorldEffects
=============
*}
// (GAME=CTF)
procedure P_WorldEffects;
var
  breather
  envirosuit     : qboolean;
  waterlevel,
  old_waterlevel : integer;
begin
  if (current_player.movetype = MOVETYPE_NOCLIP) then
  begin
    current_player.air_finished := level.time + 12;  // don't need air
    Exit;
  end;

  waterlevel := current_player.waterlevel;
  old_waterlevel := current_client.old_waterlevel;
  current_client.old_waterlevel := waterlevel;

  breather := current_client.breather_framenum > level.framenum;
  envirosuit := current_client.enviro_framenum > level.framenum;

  //
  // if just entered a water volume, play a sound
  //
  if (!old_waterlevel && waterlevel) then
  begin
    PlayerNoise(current_player, current_player.s.origin, PNOISE_SELF);
    if (current_player.watertype & CONTENTS_LAVA)
    then gi.sound (current_player, CHAN_BODY, gi.soundindex('player/lava_in.wav'), 1, ATTN_NORM, 0)
    else
      if (current_player.watertype & CONTENTS_SLIME)
      then gi.sound (current_player, CHAN_BODY, gi.soundindex('player/watr_in.wav'), 1, ATTN_NORM, 0)
      else
        if (current_player.watertype & CONTENTS_WATER) then
         gi.sound (current_player, CHAN_BODY, gi.soundindex('player/watr_in.wav'), 1, ATTN_NORM, 0);
    current_player.flags := current_player.flags OR FL_INWATER;

    // clear damage_debounce, so the pain sound will play immediately
    current_player.damage_debounce_time := level.time - 1;
  end;

  //
  // if just completely exited a water volume, play a sound
  //
  if (old_waterlevel && ! waterlevel) then
  begin
    PlayerNoise(current_player, current_player.s.origin, PNOISE_SELF);
    gi.sound (current_player, CHAN_BODY, gi.soundindex('player/watr_out.wav'), 1, ATTN_NORM, 0);
    current_player.flags := current_player.flags AND (NOT FL_INWATER);
  end;

  //
  // check for head just going under water
  //
  if (old_waterlevel <> 3) AND (waterlevel = 3) then
    gi.sound (current_player, CHAN_BODY, gi.soundindex('player/watr_un.wav'), 1, ATTN_NORM, 0);

  //
  // check for head just coming out of water
  //
  if (old_waterlevel = 3) AND waterlevel <> 3) then
    if (current_player.air_finished < level.time)
    then begin
      // gasp for air
      gi.sound (current_player, CHAN_VOICE, gi.soundindex('player/gasp1.wav'), 1, ATTN_NORM, 0);
      PlayerNoise(current_player, current_player.s.origin, PNOISE_SELF);
    end
    else
      if (current_player.air_finished < level.time + 11) then
       // just break surface
        gi.sound (current_player, CHAN_VOICE, gi.soundindex('player/gasp2.wav'), 1, ATTN_NORM, 0);


  //
  // check for drowning
  //
  if (waterlevel = 3)
  then begin
    // breather or envirosuit give air
    if (breather OR envirosuit) then
    begin
      current_player.air_finished := level.time + 10;

      if (((int)(current_client.breather_framenum - level.framenum) % 25) == 0) then
      begin
        if (!current_client.breather_sound)
        then gi.sound (current_player, CHAN_AUTO, gi.soundindex('player/u_breath1.wav'), 1, ATTN_NORM, 0)
        else gi.sound (current_player, CHAN_AUTO, gi.soundindex('player/u_breath2.wav'), 1, ATTN_NORM, 0);
        current_client.breather_sound := current_client.breather_sound XOR 1;
        PlayerNoise(current_player, current_player.s.origin, PNOISE_SELF);
        //FIXME: release a bubble?
      end;
    end;

    // if out of air, start drowning
    if (current_player.air_finished < level.time) then
    begin
      // drown!
      if (current_player.client.next_drown_time < level.time) AND (current_player.health > 0) then
      begin
        current_player.client.next_drown_time := level.time + 1;

        // take more damage the longer underwater
        current_player.dmg += 2;
        if (current_player.dmg > 15) then
          current_player.dmg := 15;

        // play a gurp sound instead of a normal pain sound
        if (current_player.health <= current_player.dmg)
        then gi.sound (current_player, CHAN_VOICE, gi.soundindex('player/drown1.wav'), 1, ATTN_NORM, 0);
        else
          if (rand()&1)
          then gi.sound (current_player, CHAN_VOICE, gi.soundindex('*gurp1.wav'), 1, ATTN_NORM, 0)
          else gi.sound (current_player, CHAN_VOICE, gi.soundindex('*gurp2.wav'), 1, ATTN_NORM, 0);

        current_player.pain_debounce_time := level.time;

        T_Damage (current_player, world, world, vec3_origin, current_player.s.origin, vec3_origin, current_player.dmg, 0, DAMAGE_NO_ARMOR, MOD_WATER);
      end;
    end;
  end
  else begin
    current_player.air_finished := level.time + 12;
    current_player.dmg := 2;
  end;

  //
  // check for sizzle damage
  //
  if (waterlevel AND (current_player.watertype AND (CONTENTS_LAVA OR CONTENTS_SLIME) <> 0) ) then
  begin
    if (current_player.watertype AND CONTENTS_LAVA) <> 0 then
    begin
      if (current_player->health > 0) AND
         (current_player->pain_debounce_time <= level.time) AND
         (current_client->invincible_framenum < level.framenum) then
      begin
        if (rand()&1)
        then gi.sound (current_player, CHAN_VOICE, gi.soundindex('player/burn1.wav'), 1, ATTN_NORM, 0)
        else gi.sound (current_player, CHAN_VOICE, gi.soundindex('player/burn2.wav'), 1, ATTN_NORM, 0);
        current_player.pain_debounce_time := level.time + 1;
      end;

      if (envirosuit)  // take 1/3 damage with envirosuit
      then T_Damage (current_player, world, world, vec3_origin, current_player.s.origin, vec3_origin, 1*waterlevel, 0, 0, MOD_LAVA)
      else T_Damage (current_player, world, world, vec3_origin, current_player.s.origin, vec3_origin, 3*waterlevel, 0, 0, MOD_LAVA);
    end;

    if (current_player.watertype AND CONTENTS_SLIME) <> 0 then
      if (!envirosuit) then
         // no damage from slime with envirosuit
        T_Damage (current_player, world, world, vec3_origin, current_player.s.origin, vec3_origin, 1*waterlevel, 0, 0, MOD_SLIME);
  end;
end;//procedure (GAME=CTF)


{*
===============
G_SetClientEffects
===============
*}
// (GAME <> CTF)
procedure G_SetClientEffects (edict_t *ent);
var
  pa_type,
  remaining : integer;
begin
  ent.s.effects := 0;
  ent.s.renderfx := 0;

  if (ent.health <= 0 OR level.intermissiontime) then
    Exit;

  if (ent.powerarmor_time > level.time) then
  begin
    pa_type := PowerArmorType (ent);
    if (pa_type = POWER_ARMOR_SCREEN)
    then ent.s.effects := ent.s.effects OR EF_POWERSCREEN
    else
      if (pa_type = POWER_ARMOR_SHIELD) then
      begin
        ent.s.effects := ent.s.effects OR EF_COLOR_SHELL;
        ent.s.renderfx := ent.s.renderfx OR RF_SHELL_GREEN;
      end;
  end;

{$IFDEF CTF}
//ZOID
  CTFEffects(ent);

  if (ent.client.quad_framenum > level.framenum) AND (level.framenum & 8)
//ZOID
{$ELSE}
  if (ent.client.quad_framenum > level.framenum)
{$ENDIF}
  then begin
    remaining := ent.client.quad_framenum - level.framenum;
    if (remaining > 30) OR (remaining & 4) then
      ent.s.effects := ent.s.effects OR EF_QUAD;
  end;

{$IFDEF CTF}
//ZOID
  if (ent.client.invincible_framenum > level.framenum) AND (level.framenum & 8)
//ZOID
{$ELSE}
  if (ent.client.invincible_framenum > level.framenum)
{$ENDIF}
  then begin
    remaining := ent.client.invincible_framenum - level.framenum;
    if (remaining > 30) OR (remaining & 4) then
      ent.s.effects := ent.s.effects OR EF_PENT;
  end;

  // show cheaters!!!
  if (ent.flags & FL_GODMODE) then
  begin
    ent.s.effects := ent.s.effects OR EF_COLOR_SHELL;
    ent.s.renderfx := ent.s.renderfx OR (RF_SHELL_RED OR RF_SHELL_GREEN OR RF_SHELL_BLUE);
  end;
end;//procedure (GAME <> CTF)


{*
===============
G_SetClientEvent
===============
*}
// (GAME=CTF)
procedure G_SetClientEvent (edict_t *ent);
begin
  if (ent.s.event) then
    Exit;

  if ( ent.groundentity && xyspeed > 225) then
    if ( (int)(current_client->bobtime+bobmove) != bobcycle )
      ent.s.event := EV_FOOTSTEP;
end;//procedure (GAME=CTF)


{*
===============
G_SetClientSound
===============
*}
// (GAME <> CTF)
procedure G_SetClientSound (edict_t *ent)
var
   char   *weap;
begin
{$IFDEF CTF}
  if (ent.client.resp.game_helpchanged <> game.helpchanged) then
  begin
    ent.client.resp.game_helpchanged := game.helpchanged;
    ent.client.resp.helpchanged := 1;
  end;

  // help beep (no more than three times)
  if (ent.client.resp.helpchanged && ent.client.resp.helpchanged <= 3 && !(level.framenum&63) ) then
  begin
    ent.client.resp.helpchanged++;
    gi.sound (ent, CHAN_VOICE, gi.soundindex ('misc/pc_up.wav'), 1, ATTN_STATIC, 0);
  end;
{$ELSE}
  if (ent.client.pers.game_helpchanged <> game.helpchanged) then
  begin
    ent.client.pers.game_helpchanged := game.helpchanged;
    ent.client.pers.helpchanged := 1;
  end;

  // help beep (no more than three times)
  if (ent.client.pers.helpchanged && ent.client.pers.helpchanged <= 3 && !(level.framenum&63) ) then
  begin
    ent.client.pers.helpchanged++;
    gi.sound (ent, CHAN_VOICE, gi.soundindex ('misc/pc_up.wav'), 1, ATTN_STATIC, 0);
  end;
{$ENDIF}

  if (ent.client.pers.weapon)
  then weap := ent.client.pers.weapon.classname;
  else weap := '';

  if (ent->waterlevel && (ent->watertype&(CONTENTS_LAVA|CONTENTS_SLIME)) )
  then ent.s.sound := snd_fry
  else
    if (strcmp(weap, 'weapon_railgun') == 0)
    then ent.s.sound := gi.soundindex('weapons/rg_hum.wav');
    else
      if (strcmp(weap, 'weapon_bfg') == 0)
      then ent.s.sound := gi.soundindex('weapons/bfg_hum.wav')
      else
        if (ent.client.weapon_sound)
        then ent.s.sound := ent.client.weapon_sound
        else ent.s.sound := 0;
end;//procedure (GAME <> CTF)

{*
===============
G_SetClientFrame
===============
*}
// (GAME <> CTF)
procedure G_SetClientFrame (edict_t *ent);
var
   gclient_t   *client;
  duck, run : qboolean;
begin
  if (ent.s.modelindex <> 255)
    Exit;  // not in the player model

  client := ent.client;

  if (client->ps.pmove.pm_flags & PMF_DUCKED)
  then duck := true
  else duck := false;
  if (xyspeed)
  then run := true
  else run := false;

  // check for stand/duck and stop/go transitions
  if (duck <> client.anim_duck) AND (client.anim_priority < ANIM_DEATH) then
    goto newanim;
  if (run <> client.anim_run) AND (client.anim_priority = ANIM_BASIC) then
    goto newanim;
  if (!ent->groundentity) AND (client.anim_priority <= ANIM_WAVE) then
    goto newanim;

  if(client.anim_priority = ANIM_REVERSE)
  then
    if (ent.s.frame > client.anim_end) then
    begin
      ent->s.frame--;
      Exit;
    end;
  else
    if (ent.s.frame < client.anim_end) then
    begin
      // continue an animation
      ent->s.frame++;
      Exit;
    end;

  if (client.anim_priority = ANIM_DEATH) then
    Exit;   // stay there
  if (client.anim_priority = ANIM_JUMP) then
  begin
    if (!ent->groundentity) then
      Exit;   // stay there
    ent.client.anim_priority := ANIM_WAVE;
    ent.s.frame := FRAME_jump3;
    ent.client.anim_end := FRAME_jump6;
    Exit;
  end;

newanim:
  // return to either a running or standing frame
  client.anim_priority := ANIM_BASIC;
  client.anim_duck := duck;
  client.anim_run := run;

  if (!ent->groundentity)
  then begin
{$IFDEF CTF}
//ZOID: if on grapple, don't go into jump frame, go into standing
//frame
    if (client.ctf_grapple)
    then begin
      ent->s.frame = FRAME_stand01;
      client->anim_end = FRAME_stand40;
    end
    else begin
//ZOID
      client.anim_priority := ANIM_JUMP;
      if (ent.s.frame <> FRAME_jump2) then
        ent.s.frame := FRAME_jump1;
      client.anim_end := FRAME_jump2;
    end;
{$ELSE}
    client.anim_priority := ANIM_JUMP;
    if (ent.s.frame <> FRAME_jump2) then
      ent.s.frame := FRAME_jump1;
    client.anim_end := FRAME_jump2;
{$ENDIF}
  end
  else
    if (run)
    then
      // running
      if (duck)
      then begin
        ent.s.frame := FRAME_crwalk1;
        client.anim_end := FRAME_crwalk6;
      end
      else begin
        ent.s.frame := FRAME_run1;
        client.anim_end := FRAME_run6;
      end;
    else
      // standing
      if (duck)
      then begin
        ent.s.frame := FRAME_crstnd01;
        client.anim_end := FRAME_crstnd19;
      end
      else begin
        ent.s.frame := FRAME_stand01;
        client.anim_end := FRAME_stand40;
      end;
end;//procedure (GAME <> CTF)


{*
=================
ClientEndServerFrame

Called for each player at the end of the server frame
and right after spawning
=================
*}
// (GAME <> CTF)
procedure ClientEndServerFrame (edict_t *ent);
var
  bobtime : float;
  i       : integer;
begin
  current_player := ent;
  current_client := ent.client;

  //
  // If the origin or velocity have changed since ClientThink(),
  // update the pmove values.  This will happen when the client
  // is pushed by a bmodel or kicked by an explosion.
  //
  // If it wasn't updated here, the view position would lag a frame
  // behind the body position when pushed -- "sinking into plats"
  //
  for i:=0 to 2 do
  begin
    current_client.ps.pmove.origin[i] := ent.s.origin[i] * 8.0;
    current_client.ps.pmove.velocity[i] := ent.velocity[i] * 8.0;
  end;

  //
  // If the end of unit layout is displayed, don't give
  // the player any normal movement attributes
  //
  if (level.intermissiontime) then
  begin
    // FIXME: add view drifting here?
    current_client.ps.blend[3] := 0;
    current_client.ps.fov := 90;
    G_SetStats (ent);
    Exit;
  end;

  AngleVectors (ent.client.v_angle, forward, right, up);

  // burn from lava, etc
  P_WorldEffects ();

  //
  // set model angles from view angles so other things in
  // the world can tell which direction you are looking
  //
  if (ent.client.v_angle[PITCH] > 180)
  then ent.s.angles[PITCH] := (-360 + ent.client.v_angle[PITCH])/3;
  else ent.s.angles[PITCH] := ent.client.v_angle[PITCH]/3;
  ent.s.angles[YAW] := ent.client.v_angle[YAW];
  ent.s.angles[ROLL] := 0;
  ent.s.angles[ROLL] := SV_CalcRoll (ent.s.angles, ent.velocity)*4;

  //
  // calculate speed and cycle to be used for
  // all cyclic walking effects
  //
  xyspeed := sqrt(ent.velocity[0]*ent.velocity[0] + ent.velocity[1]*ent.velocity[1]);

  if (xyspeed < 5)
  then begin
    bobmove := 0;
    current_client.bobtime := 0;  // start at beginning of cycle again
  end
  else
    if (ent->groundentity) then
    begin
      // so bobbing only cycles when on ground
      if (xyspeed > 210)
      then bobmove := 0.25
      else
        if (xyspeed > 100)
        then bobmove := 0.125
        else bobmove := 0.0625;
    end;

{Y}  bobtime = (current_client->bobtime += bobmove);

  if (current_client->ps.pmove.pm_flags & PMF_DUCKED) then
    bobtime := bobtime * 4;

  bobcycle := (int)bobtime;
  bobfracsin := abs(sin(bobtime*M_PI));

  // detect hitting the floor
  P_FallingDamage (ent);

  // apply all the damage taken this frame
  P_DamageFeedback (ent);

  // determine the view offsets
  SV_CalcViewOffset (ent);

  // determine the gun offsets
  SV_CalcGunOffset (ent);

  // determine the full screen color blend
  // must be after viewoffset, so eye contents can be
  // accurately determined
  // FIXME: with client prediction, the contents
  // should be determined by the client
  SV_CalcBlend (ent);

{$IFDEF CTF}
//ZOID
  if (!ent.client.chase_target) then
//ZOID
    G_SetStats (ent);

//ZOID
//update chasecam follower stats
  for i:=1 to maxclients.value do
  begin
    edict_t *e = g_edicts + i;
    if (!e.inuse) OR (e.client.chase_target <> ent) then
      Continue;
    memcpy (e->client->ps.stats,
            ent->client->ps.stats,
            sizeof(ent->client->ps.stats));
    e.client.ps.stats[STAT_LAYOUTS] := 1;
    Break;
  end;
//ZOID
{$ELSE}
  // chase cam stuff
  if (ent.client.resp.spectator)
  then G_SetSpectatorStats(ent)
  else G_SetStats (ent);
  G_CheckChaseStats(ent);
{$ENDIF}

  G_SetClientEvent (ent);

  G_SetClientEffects (ent);

  G_SetClientSound (ent);

  G_SetClientFrame (ent);

  VectorCopy (ent.velocity, ent.client.oldvelocity);
  VectorCopy (ent.client.ps.viewangles, ent.client.oldviewangles);

  // clear weapon kicks
  VectorClear (ent.client.kick_origin);
  VectorClear (ent.client.kick_angles);

  // if the scoreboard is up, update it
//  if (ent.client.showscores) && !(level.framenum & 31) ) then
  if (ent.client.showscores) AND ((level.framenum AND 31) = 0) then
  begin
{$IFDEF CTF}
//ZOID
    if (ent.client.menu)
    then begin
      PMenu_Do_Update(ent);
      ent.client.menudirty := false;
      ent.client.menutime := level.time;
    end
    else DeathmatchScoreboardMessage (ent, ent.enemy);
    gi.unicast (ent, false);
//ZOID
{$ELSE}
    DeathmatchScoreboardMessage (ent, ent.enemy);
    gi.unicast (ent, false);
{$ENDIF}
  end;//if
end;//procedure (GAME <> CTF)

// End of file


My current problems:
--------------------
1)  if (rand()&1)

2)  bobtime = (current_client->bobtime += bobmove);
    A = (B += C)
