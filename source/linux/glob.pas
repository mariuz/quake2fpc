unit glob;

//Initial conversion by : Fabrizio Rossini ( FAB )
//
{ This File contains part of convertion of Quake2 source to ObjectPascal.    }
{ More information about this project can be found at:                       }
{ http://www.sulaco.co.za/quake2/                                            }


(*
Copyright (C) 1997-2001 Id Software, Inc.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  

See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

*)
interface

{.$include <stdio.h>}


function glob_match(pattern: pchar;  text: pchar): integer;

implementation

uses SysUtils;

(* Like glob_match, but match PATTERN against any final segment of TEXT.  *)
function glob_match_after_star(pattern: pchar;  text: pchar): integer; 
var
p: pchar; 
t: pchar;
c: char; 
c1: char; 
begin
  p:=pattern; 
  t:=text; 

  c := p^;
  inc (p^);
  //while (c:=*p{++} inc(p); )='?')or(c='*')
  //do
  while ((c = '?') or (c = '*')) do
  if (c ='?') and ( t^ =#0) then
  begin
    inc(t);
    result:= 0; 
    exit;
  end;

  if c=#0 then
  begin
    result:= 1; 
    exit;
  end;
  if c = #92 then
  c1:= p^
  else
  c1:= c; 
  while True //1
  do
  begin 
    if ((c='[')or( t^= c1)) and (glob_match(p-1,t) <>0)
    then
    begin
      result:= 1; 
      exit;
    end;
    if t^ =#0 then
    begin
      inc(t);
      result:= 0; 
      exit;
    end;
  end;

end;

(* Return nonzero if PATTERN has any special globbing chars in it.  *)

function glob_pattern_p (pattern: pchar): integer;
var
p: pchar; 
c: char; 
open: integer;
(*
register char *p = pattern;
register char c;
int open = 0;
*)
begin
  p:=pattern; 
  
  open:=0;

  c := p^;
  while (c <> #0) do
  inc(p);

  case c of
    '?',
    '*': begin

        result:= 1;
        exit;
        end;
        
    '[':
        (* Only accept an open brace if there is a close *)
        (* brace to match it.  Bracket expressions must be *)
        (* complete, according to Posix.2 *)
        begin
        inc(open);

        //continue
        end;

    ']': begin
         if open <>0 then
                begin
                result:= 1;
                exit;
                end;

        //continue

        end;

             // #92: begin
             //case '\\':
             //if (*p++ == '\0')
             //return 0;
    '\': begin
         if p^ ='0' then
          begin
          inc(p);
          result:= 0;
          exit;
          end;
         end;

  end;{case?}


  result:= 0;

end;

(* Match the pattern PATTERN against the string TEXT;
   return 1 if it matches, 0 otherwise.

   A match means the entire string TEXT is used up in matching.

   In the pattern string, `*' matches any sequence of characters,
   `?' matches any character, [SET] matches any character in the specified set,
   [!SET] matches any character not in the specified set.

   A set is composed of characters or ranges; a range looks like
   character hyphen character (as in 0-9 or A-Z).
   [0-9a-zA-Z_] is the set of characters allowed in C identifiers.
   Any other character in the pattern must be matched exactly.

   To suppress the special syntactic significance of any of `[]*?!-\p,
   and match the character exactly, precede it with a `\p.
*)


function glob_match(pattern: pchar;  text: pchar): integer; 
var
p: pchar; 
t: pchar; 
c: char; 
c1: char; 
invert: integer; 
cstart: char; 
cend: char;

// register char *p = pattern, *t = text;
// register char c;
// register char c1 = *t++;
// int invert;
// register char cstart = c, cend = c;

label
match;

begin
  p:=pattern; 
  t:=text;

  c := p^;

  while (c <> '0') do

  inc (p);

  case c of
      '?': begin
           if t^ = '0' then
                begin
                result:= 0;
                exit
                end
                else
                inc(t);
                end;

    //#92: begin
     '\' : begin
                if p^ <> t^ then
                begin
                inc(p);
                inc(t);
                result:= 0;
                exit;
                end;
            end;

    '*': begin

         result:= glob_match_after_star ( p, t);
         exit;

         {goto next_label;}{<= !!!d case label without "break"}
         end;

    '[': begin
                begin
                c1:=t^;
                inc(t); ;
                if {not} c1 = #0 then
                begin
                result:= (0);
                exit;
                end;

             // invert = ((*p == '!') || (*p == '^'));
             //invert :=  StrtoInt( p^ = '!' ) or StrtoInt( p^ = '^' );
             if p^ = '!' then invert := StrtoInt(p^);
             if p^ = '^' then invert := StrtoInt(p^);
        if invert<> 0 then
        inc(p);

        c:= p^ ;
        inc(p); ;

        while True //1
        do
        begin 
          cstart:=c; 
          cend:=c; 
          if c ='\' then
          begin 
            cstart := p^;
            inc(p);
            cend := cstart;
          end;

          if c='0' then
          begin
            result:= 0; 
            exit;
          end;

          c :=  p^ ;
          inc(p);

          if (c = '-' ) and ( p^ <> ']') then
          begin 
            cend:= p^ ;{++}
            inc(p);

            if cend ='\' then
            cend:= p^ ;{++}
            inc(p);

            if cend ='0' then
            begin
              result:= 0; 
              exit;
            end;

            c:= p^ ;{++}
            inc(p);

          end;

          if (c1 >= cstart) and ( c1 <= cend ) then
          goto match;

          if c=']' then
          break; {<= !!!b possible in "switch" - then remove this line}
        end;

        if {not} invert = 0 then
        //begin
          result:= 0;
          //exit;
        //end;
        //break; {<= !!!b possible in "switch" - then remove this line}
        
      (* Skip the rest of the [...] construct that already matched.  *)
match: 
        while c<>']' do
        begin 
          if c='0' then
          begin
            result:= 0;
            exit;
          end;

          c:= p^ ;{++}
          inc(p);
          if c ='0' then
          begin
            result:= 0;
            exit;
          end
          else
          if c ='\' then
          inc(p); 
        end;

        if invert<> 0 then
        //begin
          result:= 0;
        //  exit;
        //end;
        //break; {<= !!!b possible in "switch" - then remove this line}
      end;
      {goto next_label;}{<= !!!d case label without "break"}
    end
    else
    
    begin
      if c<> t^ then
      begin
        inc(t);
        result:= 0; 
        //exit;
      end;
    end;

  end;{case?}
  
  t :='0';
  result:= StrtoInt(t);

end;


end.
