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


(*==============================================================================
   Copyright (C) 2002 THallium Software

   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation; either version 2
   of the License, or (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

   See the GNU General Public License for more details.
==============================================================================*)

(*==============================================================================
   THallium Software
       Author  : Thomas Lavergne (thomas.lavergne@laposte.net)
       Version : 0.1.0 alpha

   History :
       16/01/2001 : v0.1.0 alpha, mostly untested
       04/07/2002 : (Juha Hartikainen) Fixed memcmp and strcmp functions

   Bug :
       none (most of this file was untested)
==============================================================================*)

(*==============================================================================
   CPas try to help you to convert C programs to Pascal.
   It provide consts, types and functions commonly used in C.
   A big part of this project is a translation of the c standard lib.

   Some of functions in this file was present in recent version of SysUtils,
   but I don't want to include SysUtils, I try to provide most C functions I
   can without any other unit.

   Some of these function was not optimised, in first time I prefer add two
   slow functions rather than one optimised.
==============================================================================*)

(*==============================================================================
   Todo
     - Make a lot of tests.
     - Convert stdio.h : a lot of work, I do this in three part
         first I convert printf and similar
         second I convert file handling
         finally all the other (not a lot of stuff here)
     - Optimise code : I don't known if I can really optimise a lot if keep
         code in pascal, but some function could be rewritten in asm.
==============================================================================*)
unit CPas;

interface

//==============================================================================
// Basic types and pointers
//==============================================================================
  (*
type
  // Basic C types
  short             = SmallInt;
  shortint          = SmallInt;
  signedshort       = SmallInt;
  signedshortint    = SmallInt;
  unsignedshort     = Word;
  unsignedshortint  = Word;
  int               = Integer;
  signed            = Integer;
  signedint         = Integer;
  unsigned          = Cardinal;
  unsignedint       = Cardinal;
  long              = LongInt;
  signedlong        = LongInt;
  signedlongint     = LongInt;
  unsignedlong      = LongWord;
  unsignedlongint   = LongWord;
  unsignedchar      = Char;
  signedchar        = SmallInt;
  float             = Single;

  // Pointers to basic C types
  Pshort            = ^SmallInt;
  Pshortint         = ^SmallInt;
  Psignedshort      = ^SmallInt;
  Psignedshortint   = ^SmallInt;
  Punsignedshort    = ^Word;
  Punsignedshortint = ^Word;
  Pint              = ^Integer;
  Psigned           = ^Integer;
  Psignedint        = ^Integer;
  Punsigned         = ^Cardinal;
  Punsignedint      = ^Cardinal;
  Plong             = ^LongInt;
  Plongint          = ^LongInt;
  Psignedlong       = ^LongInt;
  Psignedlongint    = ^LongInt;
  Punsignedlong     = ^LongWord;
  Punsignedlongint  = ^LongWord;
  Punsignedchar     = ^Char;
  Psignedchar       = ^SmallInt;
  Pfloat            = ^Single;

  // Somme Pointer to array (usefull for working on buffers);
//  PByteArray = ^TByteArray;
//  TByteArray = array[0..32767] of Byte;

  PWordArray = ^TWordArray;
  TWordArray = array[0..0] of Word;

  PLongWordArray = ^TLongWordArray;
  TLongWordArray = array[0..0] of Word;
  *)

//==============================================================================
// Stddef.h
//==============================================================================
type
  ptrdiff_t = Integer;
  size_t = Integer;

const
  NULL = nil;

  //==============================================================================
  // Stdlib.h
  //==============================================================================
type
  div_t = packed record
    quot, rem: Integer;
  end;
  ldiv_t = packed record
    quot, rem: LongInt;
  end;

const
  EXIT_SUCCESS = 0;
  EXIT_FAILURE = 1;

function calloc(nb_blocs, size: size_t): Pointer;
function malloc(size: size_t): Pointer;
procedure realloc(adr: Pointer; size: size_t);
procedure free(adr: Pointer);

procedure abort_;
procedure exit_(state: Integer);

function div_(num, den: Integer): div_t;
function ldiv(num, den: LongInt): ldiv_t;

//==============================================================================
// stdlib.h
//==============================================================================

function rand: Integer;

//==============================================================================
// Ctype.h
//==============================================================================
function isalnum(c: Integer): integer;
function isalpha(c: Integer): integer;
function iscntrl(c: Integer): integer;
function isdigit(c: Integer): integer;
function isgraph(c: Integer): integer;
function islower(c: Integer): integer;
function isprint(c: Integer): integer;
function ispunct(c: Integer): integer;
function isspace(c: Integer): integer;
function isupper(c: Integer): integer;
function isxdigit(c: Integer): integer;

//==============================================================================
// String.h
//==============================================================================
function memcpy(dst: Pointer; const src: Pointer; len: size_t): Pointer;
function memmove(dst: Pointer; const src: Pointer; len: size_t): Pointer;
function strcpy(dst: PChar; const src: PChar): PChar;
function strncpy(dst: PChar; const src: PChar; len: size_t): PChar;

function strcat(dst: PChar; const src: PChar): PChar;
function strncat(dst: PChar; const src: PChar; len: size_t): PChar;

function memcmp(const buf1, buf2: Pointer; len: size_t): Integer;
function strcmp(const str1, str2: PChar): Integer;
function strcoll(const str1, str2: PChar): Integer;
function strncmp(const str1, str2: PChar; len: size_t): Integer;
function strxfrm(dst: PChar; const src: PChar; len: size_t): size_t;

function memchr(const buf: Pointer; c: Integer; len: size_t): Pointer;
function strchr(const str: PChar; c: Integer): PChar;
function strcspn(const str1, str2: PChar): size_t;
function strpbrk(const str1, str2: PChar): PChar;
function strrchr(const str: PChar; c: Integer): PChar;
function strspn(const str1, str2: PChar): size_t;
function strstr(const str1, str2: PChar): PChar;
function strtok(str: PChar; const tok: PChar): PChar;

function memset(buf: Pointer; c: Integer; len: size_t): Pointer;
function strerror(nb_error: Integer): PChar;
function strlen(const str1: PChar): size_t;

function atoi(s: PChar): Integer;
function atof(s: PChar): Single;
function sscanf(const s: PChar; const fmt: PChar;
  const pointers: array of Pointer): Integer;

type
  QSortCB = function(const arg1, arg2: Pointer): Integer;

procedure qsort(base: Pointer; num: Size_t; width: Size_t; compare: QSortCB);

implementation

uses
  SysUtils;

procedure qsort_int(base: Pointer; width: Integer; compare: QSortCB; Left, Right: Integer; TempBuffer, TempBuffer2: Pointer);
var
  Lo, Hi: Integer;
  P: Pointer;
begin
  Lo := Left;
  Hi := Right;
  P := Pointer(PtrInt(base) + ((Lo + Hi) div 2) * width);
  Move(P^, TempBuffer2^, width);
  repeat
    while compare(Pointer(Integer(base) + Lo * width), TempBuffer2) < 0 do
      Inc(Lo);
    while compare(Pointer(Integer(base) + Hi * width), TempBuffer2) > 0 do
      Dec(Hi);
    if Lo <= Hi then
    begin
      Move(Pointer(Integer(base) + Lo * width)^, TempBuffer^, width);
      Move(Pointer(Integer(base) + Hi * width)^, Pointer(Integer(base) + Lo * width)^, width);
      Move(TempBuffer^, Pointer(Integer(base) + Hi * width)^, width);
      Inc(Lo);
      Dec(Hi);
    end;
  until Lo > Hi;
  if Hi > Left then
    qsort_int(base, width, compare, Left, Hi, TempBuffer, TempBuffer2);
  if Lo < Right then
    qsort_int(base, width, compare, Lo, Right, TempBuffer, TempBuffer2);
end;

procedure qsort(base: Pointer; num: Size_t; width: Size_t; compare: QSortCB);
var
  tmp1, tmp2: Pointer;
begin
  // Juha: Small tweak to avoid unnnecessary memory allocation.
  if num < 2 then
    exit;
  GetMem(tmp1, width);
  GetMem(tmp2, width);
  try
    qsort_int(base, width, compare, 0, num - 1, tmp1, tmp2);
  finally
    FreeMem(tmp1, width);
    FreeMem(tmp2, width);
  end;
end;

//==============================================================================
// Stdlib.h
//==============================================================================

function calloc(nb_blocs, size: size_t): Pointer;
begin
  Result := malloc(nb_blocs * size);
end;

function malloc(size: size_t): Pointer;
begin
  GetMem(Result, size);
end;

procedure realloc(adr: Pointer; size: size_t);
begin
  ReallocMem(adr, size);
end;

procedure free(adr: Pointer);
begin
  FreeMem(adr);
end;

procedure abort_;
begin
  exit_(EXIT_FAILURE);
end;

procedure exit_(state: Integer);
begin
  Halt(state);
end;

function div_(num, den: Integer): div_t;
begin
  Result.quot := num div den;
  Result.rem := num mod den;
end;

function ldiv(num, den: LongInt): ldiv_t;
begin
  Result.quot := num div den;
  Result.rem := num mod den;
end;

//==============================================================================
// stdlib.h
//==============================================================================

function rand: Integer;
const
  RAND_MAX = $7FFF;
begin
  Result := Random(RAND_MAX);
end;

//==============================================================================
// Ctype.h
//==============================================================================

function isalnum(c: Integer): integer;
begin
  if Chr(c) in ['a'..'z', 'A'..'Z', '0'..'9'] then
    Result := 1
  else
    Result := 0;
end;

function isalpha(c: Integer): integer;
begin
  if Chr(c) in ['a'..'z', 'A'..'Z'] then
    Result := 1
  else
    Result := 0;
end;

function iscntrl(c: Integer): integer;
begin
  if Chr(c) in [#0..#31, #127] then
    Result := 1
  else
    Result := 0;
end;

function isdigit(c: Integer): integer;
begin
  if Chr(c) in ['0'..'9'] then
    Result := 1
  else
    Result := 0;
end;

function isgraph(c: Integer): integer;
begin
  if Chr(c) in [#33..#126, #128..#254] then
    Result := 1
  else
    Result := 0;
end;

function islower(c: Integer): integer;
begin
  if Chr(c) in ['a'..'z'] then
    Result := 1
  else
    Result := 0;
end;

function isprint(c: Integer): integer;
begin
  if Chr(c) in [#32..#126, #128..#254] then
    Result := 1
  else
    Result := 0;
end;

function ispunct(c: Integer): integer;
begin
  Result := 0;
  if isprint(c) = 1 then
    if (isalnum(c) + isspace(c)) = 0 then
      Result := 1;
end;

function isspace(c: Integer): integer;
begin
  if Chr(c) in [#09, #10, #11, #13, #32] then
    Result := 1
  else
    Result := 0;
end;

function isupper(c: Integer): integer;
begin
  if Chr(c) in ['A'..'Z'] then
    Result := 1
  else
    Result := 0;
end;

function isxdigit(c: Integer): integer;
begin
  if Chr(c) in ['a'..'f', 'A'..'F', '0'..'9'] then
    Result := 1
  else
    Result := 0;
end;

//==============================================================================
// String.h
//==============================================================================

function min(const a, b: Integer): Integer;
begin
  if a <= b then
    Result := a
  else
    Result := b;
end;

function memcpy(dst: Pointer; const src: Pointer; len: size_t): Pointer;
begin
  Move(src^, dst^, len);
  Result := dst;
end;

function memmove(dst: Pointer; const src: Pointer; len: size_t): Pointer;
begin
  Move(src^, dst^, len);
  Result := dst;
end;

function strcpy(dst: PChar; const src: PChar): PChar;
begin
  Result := memcpy(dst, src, strlen(src) + 1);
end;

function strncpy(dst: PChar; const src: PChar; len: size_t): PChar;
begin
  Result := memcpy(dst, src, min(strlen(src) + 1, len));
end;

function strcat(dst: PChar; const src: PChar): PChar;
begin
  Result := dst;
  while dst[0] <> #0 do
    Inc(Dst);
  memcpy(dst, src, strlen(src) + 1);
end;

function strncat(dst: PChar; const src: PChar; len: size_t): PChar;
begin
  Result := dst;
  while dst[0] <> #0 do
    Inc(Dst);
  memcpy(dst, src, min(strlen(src) + 1, len));
end;

function memcmp(const buf1, buf2: Pointer; len: size_t): Integer;
var
  i: Integer;
begin
  Result := 0;
  i := 0;
  while (i < len) and (Result = 0) do
  begin
    if PChar(buf1)[i] < PChar(buf2)[i] then
      Result := -1
    else if PChar(buf1)[i] > PChar(buf2)[i] then
      Result := 1;
    Inc(i);
  end;
end;

function strcmp(const str1, str2: PChar): Integer;
var
  l1, l2: Integer;
begin
  l1 := strlen(str1);
  l2 := strlen(str2);
  Result := memcmp(str1, str2, min(l1, l2));
  if Result = 0 then
    if l1 < l2 then
      Result := -1
    else if l1 > l2 then
      Result := 1;
end;

function strcoll(const str1, str2: PChar): Integer;
begin
  Result := strcmp(str1, str2);
end;

function strncmp(const str1, str2: PChar; len: size_t): Integer;
var
  l1, l2: Integer;
begin
  l1 := min(strlen(str1), len);
  l2 := min(strlen(str2), len);
  Result := memcmp(str1, str2, min(l1, l2));
  if Result = 0 then
    if l1 < l2 then
      Result := -1
    else if l2 > l1 then
      Result := 1;
end;

function strxfrm(dst: PChar; const src: PChar; len: size_t): size_t;
begin
  Result := strlen(src);
  if Result <= len then
    strcpy(dst, src);
end;

function memchr(const buf: Pointer; c: Integer; len: size_t): Pointer;
var
  l: Char;
begin
  Result := buf;
  l := chr(c);
  while len <> 0 do
  begin
    if PChar(Result)[0] = l then
      Exit;
    Inc(ptruint(Result));
    Dec(len);
  end;
  Result := NULL;
end;

function strchr(const str: PChar; c: Integer): PChar;
begin
  Result := memchr(str, c, strlen(str) + 1);
end;

function strcspn(const str1, str2: PChar): size_t;
var
  t: PChar;
begin
  Result := 0;
  t := str1;
  while t[0] <> #0 do
  begin
    if strchr(str2, Ord(t[0])) <> NULL then
      Exit;
    Inc(Result);
    Inc(t);
  end;
end;

function strpbrk(const str1, str2: PChar): PChar;
begin
  Result := str1;
  while Result[0] <> #0 do
  begin
    if strchr(str2, Ord(Result[0])) <> NULL then
      Exit;
    Inc(Result);
  end;
  Result := NULL;
end;

function strrchr(const str: PChar; c: Integer): PChar;
var
  len: Integer;
  l: Char;
begin
  len := strlen(str);
  Result := str + len;
  l := chr(c);
  while len <> 0 do
  begin
    if Result[0] = l then
      Exit;
    Dec(Result);
    Dec(len);
  end;
  Result := NULL;
end;

function strspn(const str1, str2: PChar): size_t;
var
  t: PChar;
begin
  Result := 0;
  t := str1;
  while t[0] <> #0 do
  begin
    if strchr(str2, Ord(t[0])) = NULL then
      Exit;
    Inc(Result);
    Inc(t);
  end;
end;

function strstr(const str1, str2: PChar): PChar;
var
  l: Integer;
begin
  l := strlen(str2);
  Result := str1;
  while Result[0] <> #0 do
  begin
    if strncmp(Result, str2, l) = 0 then
      Exit;
    Inc(Result);
  end;
  Result := NULL;
end;

var
  strtok_str: PChar;

function strtok(str: PChar; const tok: PChar): PChar;
begin
  if str <> NULL then
    strtok_str := str;
  Result := strtok_str;
  while strtok_str[0] <> #0 do
  begin
    if strchr(tok, Ord(strtok_str[0])) <> NULL then
    begin
      strtok_str[0] := #0;
      Inc(strtok_str);
      Exit;
    end;
    Inc(strtok_str);
  end;
  Result := NULL;
end;

function memset(buf: Pointer; c: Integer; len: size_t): Pointer;
begin
  FillChar(buf^, len, c);
  Result := buf;
end;

function strerror(nb_error: Integer): PChar;
begin
  Result := NULL;
end;

function strlen(const str1: PChar): size_t;
begin
  Result := 0;
  while str1[Result] <> #0 do
    Inc(Result);
end;

function atoi(s: PChar): Integer;
begin
  Result := StrToIntDef(s, 0);
end;

function atof(s: PChar): Single;
var
  s2: string;
  i: Integer;
begin
  s2 := s;
  for i := 1 to Length(s2) do
  begin
    if s2[i] in ['.', ','] then
      s2[i] := SysUtils.DecimalSeparator;
  end;
  Result := StrToFloatDef(s2, 0.0);
end;

function sscanf(const s: PChar; const fmt: PChar;
  const pointers: array of Pointer): Integer;
type
  TScanfFmtType = (sftInvalid, sftInteger, sftFloat, sftString);
var
  i, n, m: integer;
  s1: array[0..1023] of Char;

  procedure AddChar(c: Char);
  begin
    s1[strlen(s1) + 1] := #0;
    s1[strlen(s1)] := c;
  end;

  function GetInt: Integer;
  begin
    s1[0] := #0;
    while (s[n] = ' ') and (strlen(s) > n) do
      Inc(n);
    while (s[n] in ['0'..'9', '+', '-']) and (strlen(s) >= n) do
    begin
      AddChar(s[n]);
      Inc(n);
    end;
    Result := strlen(s1);
  end;

  function GetFloat: Integer;
  begin
    s1[0] := #0;
    while (s[n] = ' ') and (strlen(s) > n) do
      Inc(n);
    while (s[n] in ['0'..'9', '+', '-', '.', 'e', 'E'])
      and (strlen(s) >= n) do
    begin
      AddChar(s[n]);
      Inc(n);
    end;
    Result := strlen(s1);
  end;

  function GetString: Integer;
  begin
    s1[0] := #0;
    while (s[n] = ' ') and (strlen(s) > n) do
      Inc(n);
    while (s[n] <> ' ') and (strlen(s) >= n) do
    begin
      AddChar(s[n]);
      Inc(n);
    end;
    Result := strlen(s1);
  end;

  function ScanStr(c: Char): Boolean;
  begin
    Result := False;

    while (s[n] <> c) and (strlen(s) > n) do
      Inc(n);
    Inc(n);

    if (n <= strlen(s)) then
      Result := True
  end;

  function GetFmt: TScanfFmtType;
  begin
    Result := sftInvalid;

    while (True) do
    begin
      while (fmt[m] = ' ') and (strlen(fmt) > m) do
        Inc(m);
      if (m >= strlen(fmt)) then
        Break;

      if (fmt[m] = '%') then
      begin
        Inc(m);
        case fmt[m] of
          'd': Result := sftInteger;
          'f': Result := sftFloat;
          's': Result := sftString;
        end;
        Inc(m);
        Break;
      end;

      if (not ScanStr(fmt[m])) then
        Break;
      Inc(m);
    end;
  end;

begin
  n := 0;
  m := 0;
  Result := 0;

  for i := 0 to High(pointers) do
  begin
    case GetFmt of
      sftInteger:
        begin
          if GetInt > 0 then
          begin
            //        l := atoi(s1);
            //        Move(l, pointers[i]^, SizeOf(LongInt));
            PInteger(pointers[i])^ := atoi(s1);
            Inc(Result);
          end
          else
            Break;
        end;

      sftFloat:
        begin
          if GetFloat > 0 then
          begin
            //        x := atof(s1);
            //        Move(x, pointers[i]^, SizeOf(Extended));
            PSingle(pointers[i])^ := atof(s1);
            Inc(Result);
          end
          else
            Break;
        end;

      sftString:
        begin
          if GetString > 0 then
          begin
            //        Move(s1, pointers[i]^, strlen(s1) + 1);
            strcpy(pointers[i], s1);
            Inc(Result);
          end
          else
            Break;
        end;

    else
      Break;
    end;
  end;
end;

end.
