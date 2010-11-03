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
{ File(s): qcommon/md4.c                                                     }
{                                                                            }
{ Initial conversion by : D-12 (d-12@laposte.net)                            }
{ Initial conversion on : 08-Jan-2002                                        }
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
{ * Updated:                                                                 }
{ 1) 03-Mar-2002 - Clootie (clootie@reactor.ru)                              }
{    Exported Com_BlockChecksum function.                                    }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{----------------------------------------------------------------------------}

unit MD4;

interface

type
  PUINT2 = ^UINT2;
  UINT2 = Word;
  PUINT4 = ^UINT4;
  UINT4 = Cardinal;

type
  PState = ^TState;
  TState = array[0..3] of UINT4;
  PCount = ^TCount;
  TCount = array[0..1] of UINT4;
  PBuffer = ^TBuffer;
  TBuffer = array[0..63] of Char;
  TCardinalArray = array[0..2222222] of Cardinal;
  PCardinalArray = ^TCardinalArray;

  (* MD4 context. *)
  PMD4_CTX = ^MD4_CTX;
  MD4_CTX = record
    state: TState;                      (* state (ABCD) *)
    count: TCount;                      (* number of bits, modulo 2^64 (lsb first) *)
    buffer: TBuffer;                    (* input buffer *)
  end;

  PDigest = ^TDigest;
  TDigest = array[0..15] of Char;

procedure MD4Init(context: PMD4_CTX);
procedure MD4Update(context: PMD4_CTX; input: PChar; inputLen: Cardinal);
procedure MD4Final(digest: PDigest; context: PMD4_CTX);

function Com_BlockChecksum(buffer: Pointer; length: Integer): Cardinal;

implementation

(* MD4C.C - RSA Data Security, Inc., MD4 message-digest algorithm *)
(* Copyright (C) 1990-2, RSA Data Security, Inc. All rights reserved.

   License to copy and use this software is granted provided that it
   is identified as the "RSA Data Security, Inc. MD4 Message-Digest
   Algorithm" in all material mentioning or referencing this software
   or this function.

   License is also granted to make and use derivative works provided
   that such works are identified as "derived from the RSA Data
   Security, Inc. MD4 Message-Digest Algorithm" in all material
   mentioning or referencing the derived work.

   RSA Data Security, Inc. makes no representations concerning either
   the merchantability of this software or the suitability of this
   software for any particular purpose. It is provided "as is"
   without express or implied warranty of any kind.

   These notices must be retained in any copies of any part of this
   documentation and/or software.
 *)

(* Constants for MD4Transform routine.  *)
const
  S11 = 3;
  S12 = 7;
  S13 = 11;
  S14 = 19;
  S21 = 3;
  S22 = 5;
  S23 = 9;
  S24 = 13;
  S31 = 3;
  S32 = 9;
  S33 = 11;
  S34 = 15;

procedure MD4Transform(state: PState; block: PBuffer); forward;
procedure Encode(output: PChar; input: PUINT4; len: Cardinal); forward;
procedure Decode(output: PUINT4; input: PChar; len: Cardinal); forward;

const
  PADDING: array[0..63] of Char =
  (#$80, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0,
    #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0,
    #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0,
    #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0);

  (* F, G and H are basic MD4 functions. *)

function F(x, y, z: UINT4): UINT4;
begin
  Result := (x and y) or ((not x) and z);
end;

function G(x, y, z: UINT4): UINT4;
begin
  Result := (x and y) or (x and z) or (y and z);
end;

function H(x, y, z: UINT4): UINT4;
begin
  Result := x xor y xor z;
end;

(* ROTATE_LEFT rotates x left n bits. *)

function ROTATE_LEFT(x, n: UINT4): UINT4;
begin
  Result := (x shl n) or (x shr (32 - n));
end;

(* FF, GG and HH are transformations for rounds 1, 2 and 3 *)
(* Rotation is separate from addition to prevent recomputation *)

procedure FF(var a, b, c, d, x: UINT4; s: Byte);
begin
  a := Cardinal(a + F(b, c, d) + x);
  a := ROTATE_LEFT(a, s);
end;

procedure GG(var a, b, c, d, x: UINT4; s: Byte);
begin
  Inc(a, G(b, c, d) + x + UINT4($5A827999));
  a := ROTATE_LEFT(a, s);
end;

procedure HH(var a, b, c, d, x: UINT4; s: Byte);
begin
  Inc(a, H(b, c, d) + x + UINT4($6ED9EBA1));
  a := ROTATE_LEFT(a, s);
end;

(* MD4 initialization. Begins an MD4 operation, writing a new context. *)

procedure MD4Init(context: PMD4_CTX);
begin
  context^.count[0] := 0;
  context^.count[1] := 0;
  (* Load magic initialization constants.*)
  context^.state[0] := $67452301;
  context^.state[1] := $EFCDAB89;
  context^.state[2] := $98BADCFE;
  context^.state[3] := $10325476;
end;

(* MD4 block update operation. Continues an MD4 message-digest operation,
   processing another message block, and updating the context. *)

procedure MD4Update(context: PMD4_CTX; input: PChar; inputLen: Cardinal);
var
  i, index, partLen: Cardinal;
begin
  (* Compute number of bytes mod 64 *)
  index := (context^.count[0] shr 3) and $3F;

  (* Update number of bits *)
  Inc(context^.count[0], inputLen shl 3);
  if context^.count[0] < (inputLen shl 3) then
    Inc(context^.count[1]);

  Inc(context^.count[1], inputLen shr 29);

  partLen := 64 - index;

  (* Transform as many times as possible.*)
  if inputLen >= partLen then
  begin
    Move(input^, context^.buffer[index], partLen);
    MD4Transform(@context^.state, @context^.buffer);

    i := partLen;
    while i + 63 < inputLen do
    begin
      MD4Transform(@context^.state, PBuffer(@input[i]));
      Inc(i, 64);
    end;

    index := 0;
  end
  else
  begin
    i := 0;
  end;

  (* Buffer remaining input *)
  Move(input[I], context^.buffer[index], inputLen - i);
end;

(* MD4 finalization. Ends an MD4 message-digest operation, writing the the
   message digest and zeroizing the context. *)

procedure MD4Final(digest: PDigest; context: PMD4_CTX);
var
  bits: array[0..7] of Char;
  index, padLen: Cardinal;
begin
  (* Save number of bits *)
  Encode(@bits, @context^.count, 8);

  (* Pad out to 56 mod 64.*)
  index := (context^.count[0] shr 3) and $3F;
  if index < 56 then
    padLen := 56 - index
  else
    padLen := 120 - index;
  MD4Update(context, PADDING, padLen);

  (* Append length (before padding) *)
  MD4Update(context, bits, 8);

  (* Store state in digest *)
  Encode(PChar(digest), @context^.state, 16);

  (* Zeroize sensitive information.*)
  FillChar(context^.state, SizeOf(context^.state), 0);
end;

(* MD4 basic transformation. Transforms state based on block. *)

procedure MD4Transform(state: PState; block: PBuffer);
var
  a, b, c, d: UINT4;
  x: array[0..15] of UINT4;
begin
  a := state^[0];
  b := state^[1];
  c := state^[2];
  d := state^[3];

  Decode(@x, PChar(block), 64);

  (* Round 1 *)
  FF(a, b, c, d, x[0], S11);            (* 1 *)
  FF(d, a, b, c, x[1], S12);            (* 2 *)
  FF(c, d, a, b, x[2], S13);            (* 3 *)
  FF(b, c, d, a, x[3], S14);            (* 4 *)
  FF(a, b, c, d, x[4], S11);            (* 5 *)
  FF(d, a, b, c, x[5], S12);            (* 6 *)
  FF(c, d, a, b, x[6], S13);            (* 7 *)
  FF(b, c, d, a, x[7], S14);            (* 8 *)
  FF(a, b, c, d, x[8], S11);            (* 9 *)
  FF(d, a, b, c, x[9], S12);            (* 10 *)
  FF(c, d, a, b, x[10], S13);           (* 11 *)
  FF(b, c, d, a, x[11], S14);           (* 12 *)
  FF(a, b, c, d, x[12], S11);           (* 13 *)
  FF(d, a, b, c, x[13], S12);           (* 14 *)
  FF(c, d, a, b, x[14], S13);           (* 15 *)
  FF(b, c, d, a, x[15], S14);           (* 16 *)

  (* Round 2 *)
  GG(a, b, c, d, x[0], S21);            (* 17 *)
  GG(d, a, b, c, x[4], S22);            (* 18 *)
  GG(c, d, a, b, x[8], S23);            (* 19 *)
  GG(b, c, d, a, x[12], S24);           (* 20 *)
  GG(a, b, c, d, x[1], S21);            (* 21 *)
  GG(d, a, b, c, x[5], S22);            (* 22 *)
  GG(c, d, a, b, x[9], S23);            (* 23 *)
  GG(b, c, d, a, x[13], S24);           (* 24 *)
  GG(a, b, c, d, x[2], S21);            (* 25 *)
  GG(d, a, b, c, x[6], S22);            (* 26 *)
  GG(c, d, a, b, x[10], S23);           (* 27 *)
  GG(b, c, d, a, x[14], S24);           (* 28 *)
  GG(a, b, c, d, x[3], S21);            (* 29 *)
  GG(d, a, b, c, x[7], S22);            (* 30 *)
  GG(c, d, a, b, x[11], S23);           (* 31 *)
  GG(b, c, d, a, x[15], S24);           (* 32 *)

  (* Round 3 *)
  HH(a, b, c, d, x[0], S31);            (* 33 *)
  HH(d, a, b, c, x[8], S32);            (* 34 *)
  HH(c, d, a, b, x[4], S33);            (* 35 *)
  HH(b, c, d, a, x[12], S34);           (* 36 *)
  HH(a, b, c, d, x[2], S31);            (* 37 *)
  HH(d, a, b, c, x[10], S32);           (* 38 *)
  HH(c, d, a, b, x[6], S33);            (* 39 *)
  HH(b, c, d, a, x[14], S34);           (* 40 *)
  HH(a, b, c, d, x[1], S31);            (* 41 *)
  HH(d, a, b, c, x[9], S32);            (* 42 *)
  HH(c, d, a, b, x[5], S33);            (* 43 *)
  HH(b, c, d, a, x[13], S34);           (* 44 *)
  HH(a, b, c, d, x[3], S31);            (* 45 *)
  HH(d, a, b, c, x[11], S32);           (* 46 *)
  HH(c, d, a, b, x[7], S33);            (* 47 *)
  HH(b, c, d, a, x[15], S34);           (* 48 *)

  state^[0] := state^[0] + a;
  state^[1] := state^[1] + b;
  state^[2] := state^[2] + c;
  state^[3] := state^[3] + d;

  (* Zeroize sensitive information.*)
  FillChar(x, SizeOf(x), 0);
end;

(* Encodes input (UINT4) into output (unsigned char). Assumes len is a multiple
   of 4. *)

procedure Encode(output: PChar; input: PUINT4; len: Cardinal);
var
  i, j: Cardinal;
begin
  i := 0;
  j := 0;
  while j < len do
  begin
    output[j] := Char(PCardinalArray(input)[i] and $FF);
    output[j + 1] := Char((PCardinalArray(input)[i] shr 8) and $FF);
    output[j + 2] := Char((PCardinalArray(input)[i] shr 16) and $FF);
    output[j + 3] := Char((PCardinalArray(input)[i] shr 24) and $FF);
    Inc(i);
    Inc(j, 4);
  end;
end;

(* Decodes input (unsigned char) into output (UINT4). Assumes len is a multiple
   of 4. *)

procedure Decode(output: PUINT4; input: PChar; len: Cardinal);
//type
//  TUINT4Array = array[0..222222] of UINT4;
var
  i, j: Cardinal;
begin
  i := 0;
  j := 0;
  while j < len do
  begin
    PCardinalArray(output)[i] := Byte(input[j]) or (Byte(input[j + 1]) shl 8) or
      (Byte(input[j + 2]) shl 16) or (Byte(input[j + 3]) shl 24);
    Inc(i);
    Inc(j, 4);
  end;
end;

//===================================================================

function Com_BlockChecksum(buffer: Pointer; length: Integer): Cardinal;
var
  digest: array[0..3] of Cardinal;
  ctx: MD4_CTX;
begin
  MD4Init(@ctx);
  MD4Update(@ctx, PChar(Buffer), length);
  MD4Final(@digest, @ctx);

  Result := digest[0] xor digest[1] xor digest[2] xor digest[3];
end;

end.
