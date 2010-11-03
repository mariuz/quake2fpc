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


(*
   Delphi_cdecl_printf.pas

   Juha Hartikainen (juha@linearteam.org):
   - This unit includes implementations for all exported C-functions with variable
     arguments. As there is not compatible method for them in Delphi, we need to
     dig out the parameters from stack by inline assembler.

     Code here is based on Michael Skovslund's example.

*)
unit Delphi_cdecl_printf;

interface

uses
  GameUnit,
  q_shared;

// From vid_dll.pas
procedure VID_Printf_cdecl(APrint_Level: Integer; AFormat: PChar); cdecl;
procedure VID_Error_cdecl(AError_Level: Integer; AFormat: PChar); cdecl;
// From server units
procedure SV_BroadcastPrintf_cdecl(Level: Integer; AFormat: PChar); cdecl;
procedure PF_centerprintf_cdecl(ent: edict_p; fmt: PChar); cdecl;
procedure PF_cprintf_cdecl(ent: edict_p; level: integer; fmt: PChar); cdecl;
procedure PF_dprintf_cdecl(fmt: PChar); cdecl;

implementation

uses
  sv_game,
  sv_send,
  {$IFDEF WIN32}
  vid_dll,
  {$ELSE}
  vid_so,
  {$ENDIF}
  SysUtils;

function ScanFormatText(AText: string; var APos: Integer; var ALen: Integer): Integer;
var
  Len: Integer;
  State: Integer;
  EndPos: Integer;
begin
  Result := 0;
  State := 0;
  Len := Length(AText);
  EndPos := APos;
  ALen := 0;
  while (APos <= Len) and (Result = 0) do
  begin
    case State of
      0:                                // looking for '%'.
        if AText[APos] = '%' then
        begin
          State := 1;
        end;
      1:                                // looking for identifier
        begin
          case AText[APos] of
            'i':                        // decimal in C but not for delphi, so this must be patched by caller.
              Result := 1;
            'd':                        // decimal
              Result := 1;
            'u':                        // unsigned decimal
              Result := 2;
            'e':                        // floating point
              Result := 3;
            'f':                        // fixed, floting point.
              Result := 3;
            'g':                        // floating point (floor)
              Result := 3;
            'n':                        // floating point
              Result := 3;
            'm':                        // money, floating point
              Result := 3;
            'p':                        // pointer
              Result := 4;
            's':                        // string (PChar)
              Result := 5;
            'x':                        // integer convert to hex
              Result := 1;
            '0'..'9',                   // format specifiers (optional)
            '.', ':', '*', '-': ;       // they must be skipped so we can identify the type
          else
            begin
              // not a know identifier so skip it
              State := 0;               // start looking for new "%"
            end;
          end;
        end;
    end;
    if Result <> 0 then
    begin
      ALen := (APos - EndPos) + 1;
    end;
    Inc(APos);
  end;
end;

function FormatString(AFormat: PChar; AParams: Cardinal): string;
var
  P, Len: Integer;
  LP: Integer;
  S, Tmp: string;
begin
  S := '';
  Tmp := AFormat;
  P := 1;
  LP := P;
  try
    while (True) do
    begin
      case ScanFormatText(Tmp, P, Len) of
        0:                              // No more params to convert
          begin
            if LP <> P then
              S := S + Copy(Tmp, LP, (P - LP));
            Break;
          end;
        1:                              // decimal
          begin                         // this could be a 'i' identifier.
            if AFormat[P - 2] = 'i' then
            begin                       // if so, change it to 'd'
              Tmp[P - 1] := 'd';
              if AFormat[P - 1] = 'd' then // to be sure check and see if next char is 'd'
                Tmp[P] := ' ';          // if so, remove it.
            end;
            S := S + Format(Copy(Tmp, LP, Len), [Integer(Pointer(AParams)^)]);
            Inc(AParams, SizeOf(Integer));
            LP := P;
          end;
        2:                              // unsigned decimal
          begin
            S := S + Format(Copy(Tmp, LP, Len), [Cardinal(Pointer(AParams)^)]);
            Inc(AParams, SizeOf(Cardinal));
            LP := P;
          end;
        3:                              // floating point
          begin
            S := S + Format(Copy(Tmp, LP, Len), [Double(Pointer(AParams)^)]);
            Inc(AParams, SizeOf(Double));
            LP := P;
          end;
        4:                              // pointer
          begin
            S := S + Format(Copy(Tmp, LP, Len), [Cardinal(Pointer(AParams)^)]);
            Inc(AParams, SizeOf(Cardinal));
            LP := P;
          end;
        5:                              // string
          begin
            S := S + Format(Copy(Tmp, LP, Len), [string(PChar(Pointer(AParams)^))]);
            Inc(AParams, SizeOf(Pointer));
            LP := P;
          end;
      end;
    end;
  except
    S := S + 'Converter : Internal error.';
  end;
  Result := S;
end;

procedure Proc_ZeroParamAndString(ARoutine: Integer;
  AFormat: PChar; AParams: Cardinal); cdecl;
var
  S: string;
begin
  S := FormatString(AFormat, AParams);
  case ARoutine of
    1:                                  // PF_dprintf
      PF_dprintf('%s', [S]);
  end;
end;

procedure Proc_OneParamAndString(ARoutine: Integer; APrint_Level: Cardinal;
  AFormat: PChar; AParams: Cardinal); cdecl;
var
  S: string;
begin
  S := FormatString(AFormat, AParams);
  case ARoutine of
    1:                                  // VID_Printf
      VID_Printf(APrint_Level, '%s', [S]);
    2:                                  // VID_Error
      VID_Error(APrint_Level, '%s', [S]);
    3:                                  // SV_BroadcastPrintf
      SV_BroadcastPrintf(APrint_Level, '%s', [S]);
    4:                                  // PF_centerprintf
      PF_centerprintf(Pointer(APrint_Level), '%s', [S]);
  end;
end;

procedure Proc_TwoParamAndString(ARoutine: Integer; Param1: Cardinal; APrint_Level: Cardinal;
  AFormat: PChar; AParams: Cardinal); cdecl;
var
  S: string;
begin
  S := FormatString(AFormat, AParams);
  case ARoutine of
    1:                                  // PF_cprintf
      PF_cprintf(Pointer(Param1), APrint_level, '%s', [S]);
  end;
end;

procedure PF_dprintf_cdecl(fmt: PChar); cdecl;
asm
// ASM statement produces push ebp
// Stack now: ebp
//        +4: return adr.
//        +8: AFormat
//       +12: First param.
  PUSH    EAX                 // Store register
  PUSH    EBX                 // Store register
  PUSH    ECX                 // Store register
  PUSH    EDI                 // Store register

  MOV     EAX,EBP             // Get stack pointer
  ADD     EAX,$0C             // Point to first variable parameter

  PUSH    EAX                 // Store pointer to parameters
  PUSH    DWORD PTR [EBP+$08]           // store format string
  PUSH    $00000001           // Indicate SV_BroadCastPrintf
  CALL    Proc_ZeroParamAndString       // use the VarArgs in delphi routine
  ADD     ESP,$0C             // pop params off the stack

  POP     EDI                 // restore register
  POP     ECX                 // restore register
  POP     EBX                 // restore register
  POP     EAX                 // restore register
end;

procedure PF_cprintf_cdecl(ent: edict_p; level: integer; fmt: PChar); cdecl;
asm
// ASM statement produces push ebp
// Stack now: ebp
//        +4: return adr.
//        +8: ent
//       +12: level
//       +16: AFormat
//       +20: First param.
  PUSH    EAX                 // Store register
  PUSH    EBX                 // Store register
  PUSH    ECX                 // Store register
  PUSH    EDI                 // Store register

  MOV     EAX,EBP             // Get stack pointer
  ADD     EAX,$14             // Point to first variable parameter

  PUSH    EAX                 // Store pointer to parameters
  PUSH    DWORD PTR [EBP+$10]           // store format string
  PUSH    DWORD PTR [EBP+$0C]           // store level
  PUSH    DWORD PTR [EBP+$08]           // store ent
  PUSH    $00000001           // Indicate PF_cprintf
  CALL    Proc_TwoParamAndString       // use the VarArgs in delphi routine
  ADD     ESP,$14             // pop params off the stack

  POP     EDI                 // restore register
  POP     ECX                 // restore register
  POP     EBX                 // restore register
  POP     EAX                 // restore register
end;

procedure PF_centerprintf_cdecl(ent: edict_p; fmt: PChar); cdecl;
asm
// ASM statement produces push ebp
// Stack now: ebp
//        +4: return adr.
//        +8: ent
//       +12: AFormat
//       +16: First param.
  PUSH    EAX                 // Store register
  PUSH    EBX                 // Store register
  PUSH    ECX                 // Store register
  PUSH    EDI                 // Store register

  MOV     EAX,EBP             // Get stack pointer
  ADD     EAX,$10             // Point to first variable parameter

  PUSH    EAX                 // Store pointer to parameters
  PUSH    DWORD PTR [EBP+$0C]           // store format string
  PUSH    DWORD PTR [EBP+$08]           // store ent
  PUSH    $00000004           // Indicate SV_BroadCastPrintf
  CALL    Proc_OneParamAndString       // use the VarArgs in delphi routine
  ADD     ESP,$10             // pop params off the stack

  POP     EDI                 // restore register
  POP     ECX                 // restore register
  POP     EBX                 // restore register
  POP     EAX                 // restore register
end;

procedure SV_BroadcastPrintf_cdecl(Level: Integer; AFormat: PChar); cdecl;
asm
// ASM statement produces push ebp
// Stack now: ebp
//        +4: return adr.
//        +8: APrint_Level
//       +12: AFormat
//       +16: First param.
  PUSH    EAX                 // Store register
  PUSH    EBX                 // Store register
  PUSH    ECX                 // Store register
  PUSH    EDI                 // Store register

  MOV     EAX,EBP             // Get stack pointer
  ADD     EAX,$10             // Point to first variable parameter

  PUSH    EAX                 // Store pointer to parameters
  PUSH    DWORD PTR [EBP+$0C]           // store format string
  PUSH    DWORD PTR [EBP+$08]           // store print_level
  PUSH    $00000003           // Indicate SV_BroadCastPrintf
  CALL    Proc_OneParamAndString       // use the VarArgs in delphi routine
  ADD     ESP,$10             // pop params off the stack

  POP     EDI                 // restore register
  POP     ECX                 // restore register
  POP     EBX                 // restore register
  POP     EAX                 // restore register
end;

procedure VID_Printf_cdecl(APrint_Level: Integer; AFormat: PChar); cdecl;
asm
// ASM statement produces push ebp
// Stack now: ebp
//        +4: return adr.
//        +8: APrint_Level
//       +12: AFormat
//       +16: First param.
  PUSH    EAX                 // Store register
  PUSH    EBX                 // Store register
  PUSH    ECX                 // Store register
  PUSH    EDI                 // Store register

  MOV     EAX,EBP             // Get stack pointer
  ADD     EAX,$10             // Point to first variable parameter

  PUSH    EAX                 // Store pointer to parameters
  PUSH    DWORD PTR [EBP+$0C]           // store format string
  PUSH    DWORD PTR [EBP+$08]           // store print_level
  PUSH    $00000001           // Indicate VID_Printf
  CALL    Proc_OneParamAndString       // use the VarArgs in delphi routine
  ADD     ESP,$10             // pop params off the stack

  POP     EDI                 // restore register
  POP     ECX                 // restore register
  POP     EBX                 // restore register
  POP     EAX                 // restore register
end;

procedure VID_Error_cdecl(AError_Level: Integer; AFormat: PChar); cdecl;
asm
// ASM statement produces push ebp
// Stack now: ebp
//        +4: return adr.
//        +8: APrint_Level
//       +12: AFormat
//       +16: First param.
  PUSH    EAX                 // Store register
  PUSH    EBX                 // Store register
  PUSH    ECX                 // Store register
  PUSH    EDI                 // Store register

  MOV     EAX,EBP             // Get stack pointer
  ADD     EAX,$10             // Point to first variable parameter

  PUSH    EAX                 // Store pointer to parameters
  PUSH    DWORD PTR [EBP+$0C]           // store format string
  PUSH    DWORD PTR [EBP+$08]           // store print_level
  PUSH    $00000002           // Indicate VID_Error
  CALL    Proc_OneParamAndString       // use the VarArgs in delphi routine
  ADD     ESP,$10             // pop params off the stack

  POP     EDI                 // restore register
  POP     ECX                 // restore register
  POP     EBX                 // restore register
  POP     EAX                 // restore register
end;

end.
