Project: Quake2 Pure FreePascal conversion 

porting it to linux 
The first issue was replacing the libc with something more portable 

http://wiki.freepascal.org/libc_unit

Pointers arhithmetic is not quite 64bit safe and it will require a lot of cleanup

Here is one guide 

http://www.stack.nl/~marcov/porting.pdf



------------------------------------------------------------

Introduction:

This is Freepascal conversion of Quake2 sourcecode.

To view an overview of Quake2 source code , a good intro is here 

 http://fabiensanglard.net/quake2/index.php
 
Original quake2 source code 

 https://github.com/id-Software/Quake-2

FreePascal notes:
  See the Quake2FPC.LPR project file for comments about 
  this project and graphics problem.

WWW-sites:

Old Delphi project site: 
 http://www.sulaco.co.za/quake2/

Old stalled Freepascal port:
 http://z505.com
 





