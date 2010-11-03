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

unit r_varsa;
//
// d_varsa.s
//

interface

uses
  Windows,
  qasm_inc,
  d_if_inc;

(* v THIS IS A HACK *)
{$DEFINE id386}

{$IFDEF id386}

//-------------------------------------------------------
// ASM-only variables
//-------------------------------------------------------
var
  float_0: single = 0.0;
  float_1: single = 1.0;
  float_minus_1: single = -1.0;
  float_particle_z_clip: single = PARTICLE_Z_CLIP;
  float_point5: single = 0.5;

var
  fp_1m: single = 1048576.0;
  fp_1m_minus_1: single = 1048575.0;
  fp_64k: single = 65536.0;
  fp_8: single = 8.0;
  fp_16: single = 16.0;
  fp_64kx64k: DWord = $04F000000; // (float)0x8000*0x10000

var
  FloatZero: DWord = 0;
  Float2ToThe31nd: DWord = $04F000000;
  FloatMinus2ToThe31nd: DWord = $0CF000000;

var
  _r_bmodelactive: DWord = 0;

//-------------------------------------------------------
// global refresh variables
//-------------------------------------------------------

// FIXME: put all refresh variables into one contiguous block. Make into one
// big structure, like cl or sv?
{ align 4}
var
  _d_sdivzstepu: DWord = 0;
  _d_tdivzstepu: DWord = 0;
  _d_zistepu: DWord = 0;
  _d_sdivzstepv: DWord = 0;
  _d_tdivzstepv: DWord = 0;
  _d_zistepv: DWord = 0;
  _d_sdivzorigin: DWord = 0;
  _d_tdivzorigin: DWord = 0;
  _d_ziorigin: DWord = 0;

var
  _sadjust: DWord = 0;
  _tadjust: DWord = 0;
  _bbextents: DWord = 0;
  _bbextentt: DWord = 0;

var
  _cacheblock: DWord = 0;
  _cachewidth: DWord = 0;
  _d_viewbuffer: DWord = 0;
  _d_pzbuffer: DWord = 0;
  _d_zrowbytes: DWord = 0;
  _d_zwidth: DWord = 0;

//-------------------------------------------------------
// ASM-only variables
//-------------------------------------------------------
var
  izi: DWord = 0;

var
  s: DWord = 0;
  t: DWord = 0;
  snext: DWord = 0;
  tnext: DWord = 0;
  sfracf: DWord = 0;
  tfracf: DWord = 0;
  pbase: DWord = 0;
  zi8stepu: DWord = 0;
  sdivz8stepu: DWord = 0;
  tdivz8stepu: DWord = 0;
  zi16stepu: DWord = 0;
  sdivz16stepu: DWord = 0;
  tdivz16stepu: DWord = 0;
  spancountminus1: DWord = 0;
  pz: DWord = 0;

var
  izistep: DWord = 0;

//-------------------------------------------------------
// local variables for d_draw16.s
//-------------------------------------------------------

// 1/2, 1/3, 1/4, 1/5, 1/6, 1/7, 1/8, 1/9, 1/10, 1/11, 1/12, 1/13,
// 1/14, and 1/15 in 0.32 form
var
  reciprocal_table_16: array[2..15] of DWord =
  ($040000000, $02AAAAAAA, $020000000,
    $019999999, $015555555, $012492492,
    $010000000, $0E38E38E, $0CCCCCCC, $0BA2E8BA,
    $0AAAAAAA, $09D89D89, $09249249, $08888888);

(* externdef Entry2_16:dword
 externdef Entry3_16:dword
 externdef Entry4_16:dword
 externdef Entry5_16:dword
 externdef Entry6_16:dword
 externdef Entry7_16:dword
 externdef Entry8_16:dword
 externdef Entry9_16:dword
 externdef Entry10_16:dword
 externdef Entry11_16:dword
 externdef Entry12_16:dword
 externdef Entry13_16:dword
 externdef Entry14_16:dword
 externdef Entry15_16:dword
 externdef Entry16_16:dword*)

var
  entryvec_table_16: array[1..16] of DWord =
  (0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
 {the above line is a hack. it should be the below}
 {Entry2_16, Entry3_16, Entry4_16
  Entry5_16, Entry6_16, Entry7_16, Entry8_16
  Entry9_16, Entry10_16, Entry11_16, Entry12_16
  Entry13_16, Entry14_16, Entry15_16, Entry16_16}

//-------------------------------------------------------
// local variables for d_parta.s
//-------------------------------------------------------
var
  DP_Count: DWord = 0;
  DP_u: DWord = 0;
  DP_v: DWord = 0;
  DP_32768: Single = 32768.0;
  DP_Color: DWord = 0;
  DP_Pix: DWord = 0;

//externdef DP_1x1:dword
//externdef DP_2x2:dword
//externdef DP_3x3:dword
//externdef DP_4x4:dword

//DP_EntryTable: DWord = DP_1x1, DP_2x2, DP_3x3, DP_4x4

//
// advancetable is 8 bytes, but points to the middle of that range so negative
// offsets will work
//
var
  advancetable: array[0..1] of DWord = (0, 0);
  sstep: DWord = 0;
  tstep: DWord = 0;

  pspantemp: DWord = 0;
  counttemp: DWord = 0;
  jumptemp: DWord = 0;

// 1/2, 1/3, 1/4, 1/5, 1/6, and 1/7 in 0.32 form
// public reciprocal_table, entryvec_table
//var reciprocal_table: Array[2..7] of DWord =($040000000, $02aaaaaaa, $020000000,
// $019999999, $015555555, $012492492);

// externdef Entry2_8:dword
// externdef Entry3_8:dword
// externdef Entry4_8:dword
// externdef Entry5_8:dword
// externdef Entry6_8:dword
// externdef Entry7_8:dword
// externdef Entry8_8:dword

//entryvec_table dd 0, Entry2_8, Entry3_8, Entry4_8
// dd Entry5_8, Entry6_8, Entry7_8, Entry8_8

(* externdef Spr8Entry2_8:dword
 externdef Spr8Entry3_8:dword
 externdef Spr8Entry4_8:dword
 externdef Spr8Entry5_8:dword
 externdef Spr8Entry6_8:dword
 externdef Spr8Entry7_8:dword
 externdef Spr8Entry8_8:dword
*)

var
  spr8entryvec_table: array[1..8] of DWord = (0,
    0, 0, 0, 0, 0, 0, 0);
  {Spr8Entry2_8, Spr8Entry3_8, Spr8Entry4_8, Spr8Entry5_8, Spr8Entry6_8, Spr8Entry7_8, Spr8Entry8_8);}

{$ENDIF} // id386

implementation
end.
