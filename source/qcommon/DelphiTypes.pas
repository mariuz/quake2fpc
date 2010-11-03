unit DelphiTypes;

interface

{$IFDEF WIN32}
{$INCLUDE ..\Jedi.inc}
{$ELSE}
{$INCLUDE ../Jedi.inc}
{$ENDIF}

//uses
//DELPHI 5
//  D5Compat;


type

  PPByte = ^PByte;

  PCardinalArray = ^TCardinalArray;
  TCardinalArray = array[0..MaxInt div SizeOf(Cardinal) - 1] of Cardinal;

  TSingleArray = array[0..MaxInt div SizeOf(Single) - 1] of Single;
  PSingleArray = ^TSingleArray;

  TSmallIntArray = array[0..MaxInt div SizeOf(SmallInt) - 1] of SmallInt;
  PSmallIntArray = ^TSmallIntArray;

  TShortIntArray = array[0..MaxInt div SizeOf(ShortInt) - 1] of ShortInt;
  PShortIntArray = ^TShortIntArray;



{$IFNDEF COMPILER6_UP}
//type
//  TByteArray = array[0..MaxInt div SizeOf(Byte) - 1] of Byte;
//  PByteArray = ^TByteArray;

//  PPCharArray = ^TPCharArray;
//  TPCharArray = array[0..MaxInt div SizeOf(PChar) - 1] of PChar;

//  PCardinal = ^Cardinal;

//  TIntegerArray = array[0..MaxInt div SizeOf(Integer) ] of Integer;
//  PIntegerArray = ^TIntegerArray;
{$ENDIF}

{$IFNDEF COMPILER5_UP}
//type
//  PPointer = ^Pointer;
{$ENDIF}

implementation

end.
