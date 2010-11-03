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
 Additions for Quake2Delphi to compile with Delphi 5

 Author: Lars (L505)
 Site: http://z505.com

Note:
 Although this unit will help to compile the Quake2Delphi code in Delphi 5,
 Delphi 5 does not have variable function paramaters, so I gave up trying to get 
 Quak2Delphi project to compile with Delphi 5 for now and commented out these 
 lines below. 
 
 FreePascal already has these Types below, so to get it to compile with 
 freepascal or Delphi 6, this unit should really be $IFDEF'ed in the uses
 clause of other units.


 }
unit D5Compat;

interface

//type
//  PInteger = ^Integer;
//  PSingle = ^Single;
//  PDouble = ^Double;
//  PPointer = ^Pointer;

//  TPCharArray = Array of PChar;
//  PPCharArray = ^TPCharArray;
//  PByte = ^Byte;


{
function StrToFloatDef(const S: string; const Default: Extended): Extended;

function TextToFloat(Buffer: PChar; Var Value: Extended): Boolean;
}
implementation
{
uses
  sysutils;
}
{
function StrToFloatDef(const S: string; const Default: Extended): Extended;
begin
   if not TextToFloat(PChar(S),Result) then
     Result:= Default;
end;

function TextToFloat(Buffer: PChar; var Value: Extended): Boolean;
var
  E, P : Integer;
  S : string;
begin
  S:= StrPas(Buffer);
  P:= Pos(DecimalSeparator, S);
  if (P <> 0) then
    S[P] := '.';
  Val(trim(S), Value, E);
  Result:= (E = 0);
end;
}
end.

