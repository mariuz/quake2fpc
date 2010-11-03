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

cl_cin.pas created on 5-march-2002 by Skybuck Flying

converted from cl_cin.c

CHANGES:

03-jun-2002 Juha Hartikainen (juha@linearteam.org)
- Updated this to be a real unit
- Fixed conversion and language errors

06-jun-2002 Juha Hartikainen (juha@linearteam.org)
- Unit now compiles, Huff1decompress might be broken.

*)
unit cl_cin;

interface

uses
  DelphiTypes,
  q_shared,
  Files,
  SysUtils;

type
  cblock_t = record
    data: pbytearray;
    count: integer;
  end;

  cinematics_t = record
    restart_sound: qboolean;
    s_rate: integer;
    s_width: integer;
    s_channels: integer;

    width: integer;
    height: integer;
    pic: pbyte;
    pic_pending: pbyte;

    // order 1 huffman stuff
    hnodes1: pinteger;                  // [256][256][2];
    numhnodes1: array[0..255] of integer;

    h_used: array[0..511] of integer;
    h_count: array[0..511] of integer;
  end;

procedure SCR_PlayCinematic(arg: pchar);
function SCR_DrawCinematic: qboolean;
procedure SCR_RunCinematic;
procedure SCR_StopCinematic;
procedure SCR_FinishCinematic;

var
  cin: cinematics_t;

implementation

uses
  Common,
  qfiles,
  {$IFDEF WIN32}
  vid_dll,
  cd_win,
  q_shwin,
  {$ELSE}
  vid_so,
  cd_sdl,
  q_shlinux,
  {$ENDIF}
  cl_main,
  snd_dma,
  Client,
  cl_scrn,
  CPas,
  CVar;

{
=================================================================

PCX LOADING

=================================================================
}

{
==============
SCR_LoadPCX
==============
}

procedure SCR_LoadPCX(filename: PChar; pic, palette: PPByte; width, height: PInteger);
var
  raw: PByte;
  pcx: pcx_p;
  x, y: Integer;
  len: Integer;
  dataByte, runLength: Integer;
  _out, pix: PByteArray;
begin
  pic := nil;

  //
  // load the file
  //
  len := FS_LoadFile(filename, @raw);

  if (raw = nil) then
    Exit;                               // Com_Printf ('Bad pcx file %s'#10, filename);

  //
  // parse the PCX file
  //
  pcx := pcx_p(raw);                    // *** ??? *** need pointer type to structure
  raw := @pcx^.data;

  if (pcx.manufacturer <> #$0A) or
    (pcx.version <> #5) or
    (pcx.encoding <> #1) or
    (pcx.bits_per_pixel <> #8) or
    (pcx.xmax >= 640) or
    (pcx.ymax >= 480) then
  begin
    Com_Printf('Bad pcx file %s'#10, [filename]);
    exit;
  end;

  _out := Z_Malloc((pcx.ymax + 1) * (pcx.xmax + 1));

  pic^ := PByte(_out);

  pix := _out;

  if (palette <> nil) then
  begin
    palette^ := Z_Malloc(768);
    Move(palette^, PChar(Integer(pcx) + len - 768)^, 768);
  end;

  if (width <> nil) then
    width^ := pcx.xmax + 1;
  if (height <> nil) then
    height^ := pcx.ymax + 1;

  y := 0;
  while y <= pcx^.ymax do
  begin
    x := 0;
    while (x <= pcx.xmax) do
    begin
      dataByte := raw^;
      Inc(raw);
      if ((dataByte and $C0) = $C0) then
      begin
        runLength := dataByte and $3F;
        dataByte := raw^;
        Inc(raw);
      end
      else
        runLength := 1;

      while (runLength > 0) do
      begin
        pix[x] := Byte(dataByte);
        Inc(x);
        Dec(runLength);
      end;
      Inc(x);
    end;

    Inc(y);
    Inc(pix, pcx^.xmax + 1);
  end;

  if (Integer(raw) - Integer(pcx) > len) then
  begin
    Com_Printf('PCX file %s was malformed', [filename]);
    Z_Free(pic^);
    pic^ := nil;
  end;

  FS_FreeFile(pcx);
end;

//=============================================================

{
==================
SCR_StopCinematic
==================
}

procedure SCR_StopCinematic;
begin
  cl.cinematictime := 0;                // done
  if (cin.pic <> nil) then
  begin
    Z_Free(cin.pic);
    cin.pic := nil;
  end;
  if (cin.pic_pending <> nil) then
  begin
    Z_Free(cin.pic_pending);
    cin.pic_pending := nil;
  end;
  if (cl.cinematicpalette_active) then
  begin
    re.CinematicSetPalette(nil);
    cl.cinematicpalette_active := false;
  end;
  if (cl.cinematic_file <> 0) then
  begin
    FileClose(cl.cinematic_file);
    cl.cinematic_file := 0;
  end;
  if (cin.hnodes1 <> nil) then
  begin
    Z_Free(cin.hnodes1);
    cin.hnodes1 := nil;
  end;

  // switch back down to 11 khz sound if necessary
  if (cin.restart_sound) then
  begin
    cin.restart_sound := false;
    CL_Snd_Restart_f();
  end;
end;

{
====================
SCR_FinishCinematic

Called when either the cinematic completes, or it is aborted
====================
}

procedure SCR_FinishCinematic;
begin
  // tell the server to advance to the next map / cinematic
  MSG_WriteByte(cls.netchan.message, Integer(clc_stringcmd));
  SZ_Print(cls.netchan.message, va('nextserver %d'#10, [cl.servercount]));
end;

//==========================================================================

{
==================
SmallestNode1
==================
}

function SmallestNode1(numhnodes: integer): integer;
var
  i: integer;
  best, bestnode: integer;
begin
  best := 99999999;
  bestnode := -1;
  for i := 0 to numhnodes - 1 do
  begin
    if (cin.h_used[i] <> 0) then
      continue;
    if (cin.h_count[i] = 0) then
      continue;
    if (cin.h_count[i] < best) then
    begin
      best := cin.h_count[i];
      bestnode := i;
    end;
  end;

  if (bestnode = -1) then
  begin
    result := -1;
    exit;
  end;

  cin.h_used[bestnode] := Integer(true);
  result := bestnode;
end;

{
==================
Huff1TableInit

Reads the 64k counts table and initializes the node trees
==================
}

procedure Huff1TableInit;
var
  prev: integer;
  j: integer;
  node: PIntegerArray;
  nodebase: PInteger;
  counts: array[0..255] of byte;
  numhnodes: integer;
begin

  cin.hnodes1 := Z_Malloc(256 * 256 * 2 * 4);
  FillChar(cin.hnodes1^, 256 * 256 * 2 * 4, #0);

  for prev := 0 to 255 do
  begin
    FillChar(cin.h_count, sizeof(cin.h_count), #0);
    FillChar(cin.h_used, sizeof(cin.h_used), #0);

    // read a row of counts
    FS_Read(@counts, sizeof(counts), cl.cinematic_file);

    for j := 0 to 255 do
      cin.h_count[j] := counts[j];

    // build the nodes
    numhnodes := 256;
    nodebase := Pointer(Cardinal(cin.hnodes1) + ((prev * 256 * 2) * SizeOf(Integer)));

    while (numhnodes <> 511) do
    begin
      node := Pointer(Cardinal(nodebase) + (((numhnodes - 256) * 2) * SizeOf(Integer)));

      // pick two lowest counts
      node[0] := SmallestNode1(numhnodes);
      if (node[0] = -1) then
        break;                          // no more

      node[1] := SmallestNode1(numhnodes);
      if (node[1] = -1) then
        break;

      cin.h_count[numhnodes] := cin.h_count[node[0]] + cin.h_count[node[1]];
      numhnodes := numhnodes + 1;
    end;

    cin.numhnodes1[prev] := numhnodes - 1;
  end;
end;

{
==================
Huff1Decompress
==================
}

function Huff1Decompress(_in: cblock_t): cblock_t;
var
  input: pbyte;
  out_p: pbyte;
  nodenum: integer;
  count: integer;
  _out: cblock_t;
  inbyte: integer;
  hnodes: PIntegerArray;
  hnodesbase: PInteger;
begin

  // get decompressed count
  count := _in.data[0] + (_in.data[1] shl 8) + (_in.data[2] shl 16) + (_in.data[3] shl 24);
  input := Pointer(Cardinal(_in.data) + 4);
  _out.data := Z_Malloc(count);
  out_p := PByte(_out.data);

  // read bits

  hnodesbase := PInteger(Cardinal(cin.hnodes1) - SizeOf(Integer) * (256 * 2)); // nodes 0-255 aren't stored

  hnodes := PIntegerArray(hnodesbase);
  nodenum := cin.numhnodes1[0];
  while (count <> 0) do
  begin
    inbyte := input^;
    Inc(Input);
    //-----------
    if (nodenum < 256) then
    begin
      hnodes := Pointer(Cardinal(hnodesbase) + SizeOf(PInteger) * (nodenum shl 9));
      out_p^ := Byte(nodenum);
      Inc(out_p);
      Dec(Count);
      if (count = 0) then
        break;
      nodenum := cin.numhnodes1[nodenum];
    end;
    nodenum := hnodes[nodenum * 2 + (inbyte and 1)];
    inbyte := inbyte shr 1;
    //-----------
    if (nodenum < 256) then
    begin
      hnodes := Pointer(Cardinal(hnodesbase) + SizeOf(PInteger) * (nodenum shl 9));
      out_p^ := Byte(nodenum);
      Inc(out_p);
      Dec(Count);
      if (count = 0) then
        break;
      nodenum := cin.numhnodes1[nodenum];
    end;
    nodenum := hnodes[nodenum * 2 + (inbyte and 1)];
    inbyte := inbyte shr 1;
    //-----------
    if (nodenum < 256) then
    begin
      hnodes := Pointer(cardinal(hnodesbase) + SizeOf(PInteger) * (nodenum shl 9));
      out_p^ := Byte(nodenum);
      Inc(out_p);
      Dec(Count);
      if (count = 0) then
        break;
      nodenum := cin.numhnodes1[nodenum];
    end;
    nodenum := hnodes[nodenum * 2 + (inbyte and 1)];
    inbyte := inbyte shr 1;
    //-----------
    if (nodenum < 256) then
    begin
      hnodes := Pointer(Cardinal(hnodesbase) + SizeOf(PInteger) * (nodenum shl 9));
      out_p^ := Byte(nodenum);
      Inc(out_p);
      Dec(Count);
      if (count = 0) then
        break;
      nodenum := cin.numhnodes1[nodenum];
    end;
    nodenum := hnodes[nodenum * 2 + (inbyte and 1)];
    inbyte := inbyte shr 1;
    //-----------
    if (nodenum < 256) then
    begin
      hnodes := Pointer(Cardinal(hnodesbase) + SizeOf(PInteger) * (nodenum shl 9));
      out_p^ := Byte(nodenum);
      Inc(out_p);
      Dec(Count);
      if (count = 0) then
        break;
      nodenum := cin.numhnodes1[nodenum];
    end;
    nodenum := hnodes[nodenum * 2 + (inbyte and 1)];
    inbyte := inbyte shr 1;
    //-----------
    if (nodenum < 256) then
    begin
      hnodes := Pointer(Cardinal(hnodesbase) + SizeOf(PInteger) * (nodenum shl 9));
      out_p^ := Byte(nodenum);
      Inc(out_p);
      Dec(Count);
      if (count = 0) then
        break;
      nodenum := cin.numhnodes1[nodenum];
    end;
    nodenum := hnodes[nodenum * 2 + (inbyte and 1)];
    inbyte := inbyte shr 1;
    //-----------
    if (nodenum < 256) then
    begin
      hnodes := Pointer(Cardinal(hnodesbase) + SizeOf(PInteger) * (nodenum shl 9));
      out_p^ := Byte(nodenum);
      Inc(out_p);
      Dec(Count);
      if (count = 0) then
        break;
      nodenum := cin.numhnodes1[nodenum];
    end;
    nodenum := hnodes[nodenum * 2 + (inbyte and 1)];
    inbyte := inbyte shr 1;
    //-----------
    if (nodenum < 256) then
    begin
      hnodes := Pointer(Cardinal(hnodesbase) + SizeOf(PInteger) * (nodenum shl 9));
      out_p^ := Byte(nodenum);
      Inc(out_p);
      Dec(Count);
      if (count = 0) then
        break;
      nodenum := cin.numhnodes1[nodenum];
    end;
    nodenum := hnodes[nodenum * 2 + (inbyte and 1)];
    inbyte := inbyte shr 1;
  end;

  if (Cardinal(input) - Cardinal(_in.data) <> _in.count) and
    (Cardinal(input) - Cardinal(_in.data) <> _in.count + 1) then
  begin
    Com_Printf('Decompression overread by %d', [(Cardinal(input) - cardinal(_in.data)) - _in.count]);
  end;
  _out.count := Cardinal(out_p) - Cardinal(_out.data);

  Result := _out;
end;

{
==================
SCR_ReadNextFrame
==================
}

function SCR_ReadNextFrame: PByte;
var
  r: integer;
  command: integer;
  samples: array[0..(22050 div 14 * 4) - 1] of byte;
  compressed: array[0..$20000 - 1] of byte;
  size: integer;
  pic: pbyte;
  _in, huf1: cblock_t;
  start, _end, count: integer;
begin
  Result := nil;

  // read the next frame
  r := FileRead(cl.cinematic_file, command, 4);
  if (r = 0) then                       // we'll give it one more chance
    r := FileRead(cl.cinematic_file, command, 4);

  // Juha 7-Jul-2002: This really should test result against 4. Original C
  // code tests it agains 1, which means that it has read one 4-byte block,
  // but in delphi we test that we have read 4 bytes. (!)
  if (r <> 4) then
    Exit;
  command := LittleLong(command);
  if (command = 2) then
    Exit;                               // last frame marker

  if (command = 1) then
  begin
    // read palette
    FS_Read(@cl.cinematicpalette, sizeof(cl.cinematicpalette), cl.cinematic_file);
    cl.cinematicpalette_active := False; // dubious....  exposes an edge case
  end;

  // decompress the next frame
  FS_Read(@size, 4, cl.cinematic_file);
  size := LittleLong(size);
  if (size > sizeof(compressed)) or (size < 1) then
    Com_Error(ERR_DROP, 'Bad compressed frame size', []);
  FS_Read(@compressed, size, cl.cinematic_file);

  // read sound
  start := cl.cinematicframe * cin.s_rate div 14;
  _end := (cl.cinematicframe + 1) * cin.s_rate div 14;
  count := _end - start;

  FS_Read(@samples, count * cin.s_width * cin.s_channels, cl.cinematic_file);

  S_RawSamples(count, cin.s_rate, cin.s_width, cin.s_channels, @samples);

  _in.data := @compressed;
  _in.count := size;

  huf1 := Huff1Decompress(_in);

  pic := PByte(huf1.data);

  cl.cinematicframe := cl.cinematicframe + 1;

  result := pic;
end;

{
==================
SCR_RunCinematic

==================
}

procedure SCR_RunCinematic;
var
  frame: integer;
begin

  if (cl.cinematictime <= 0) then
  begin
    SCR_StopCinematic();
    exit;
  end;

  if (cl.cinematicframe = -1) then
    exit;                               // static image

  if (cls.key_dest <> key_game) then
  begin
    // pause if menu or console is up
    cl.cinematictime := cls.realtime - cl.cinematicframe * 1000 div 14;
    exit;
  end;

  frame := round((cls.realtime - cl.cinematictime) * 14.0 / 1000);
  if (frame <= cl.cinematicframe) then
    exit;
  if (frame > cl.cinematicframe + 1) then
  begin
    Com_Printf('Dropped frame: %d > %d'#10, [frame, cl.cinematicframe + 1]);
    cl.cinematictime := Round(cls.realtime - cl.cinematicframe * 1000 / 14);
  end;
  if (cin.pic <> nil) then
    Z_Free(cin.pic);
  cin.pic := cin.pic_pending;
  cin.pic_pending := nil;
  cin.pic_pending := SCR_ReadNextFrame();
  if (cin.pic_pending = nil) then
  begin
    SCR_StopCinematic();
    SCR_FinishCinematic();
    cl.cinematictime := 1;              // hack to get the black screen behind loading
    SCR_BeginLoadingPlaque();
    cl.cinematictime := 0;
    exit;
  end;
end;

{
==================
SCR_DrawCinematic

Returns true if a cinematic is active, meaning the view rendering
should be skipped
==================
}

function SCR_DrawCinematic: qboolean;
begin
  if (cl.cinematictime <= 0) then
  begin
    result := false;
    exit;
  end;

  if (cls.key_dest = key_menu) then
  begin
    // blank screen and pause if menu is up
    re.CinematicSetPalette(nil);
    cl.cinematicpalette_active := false;
    result := true;
    exit;
  end;

  if (not cl.cinematicpalette_active) then
  begin
    re.CinematicSetPalette(@cl.cinematicpalette);
    cl.cinematicpalette_active := true;
  end;

  if (cin.pic = nil) then
  begin
    result := true;
    exit;
  end;

  re.DrawStretchRaw(0, 0, viddef.width, viddef.height,
    cin.width, cin.height, cin.pic);

  result := true;
end;

{
==================
SCR_PlayCinematic

==================
}

procedure SCR_PlayCinematic(arg: Pchar);
var
  width, height: integer;
  palette: pbyte;
  name: array[0..MAX_OSPATH - 1] of char;
  dot: Pchar;
  old_khz: integer;
begin

  // make sure CD isn't playing music
  CDAudio_Stop();

  cl.cinematicframe := 0;
  dot := strstr(arg, '.');
  if (dot <> nil) and (strcmp(dot, '.pcx') = 0) then
  begin
    // static pcx image
    Com_sprintf(name, sizeof(name), 'pics/%s', [arg]);
    SCR_LoadPCX(name, @cin.pic, @palette, @cin.width, @cin.height);
    cl.cinematicframe := -1;
    cl.cinematictime := 1;
    SCR_EndLoadingPlaque();
    cls.state := ca_active;
    if (cin.pic = nil) then
    begin
      Com_Printf('%s not found.'#10, [name]);
      cl.cinematictime := 0;
    end
    else
    begin
      memcpy(@cl.cinematicpalette, palette, sizeof(cl.cinematicpalette));
      Z_Free(palette);
    end;
    exit;
  end;

  Com_sprintf(name, sizeof(name), 'video/%s', [arg]);
  FS_FOpenFile(name, cl.cinematic_file);
  if (cl.cinematic_file = 0) then
  begin
    //      Com_Error (ERR_DROP, 'Cinematic %s not found.'#10, [name]);
    SCR_FinishCinematic();
    cl.cinematictime := 0;              // done
    exit;
  end;

  SCR_EndLoadingPlaque();

  cls.state := ca_active;

  FS_Read(@width, 4, cl.cinematic_file);
  FS_Read(@height, 4, cl.cinematic_file);
  cin.width := LittleLong(width);
  cin.height := LittleLong(height);

  FS_Read(@cin.s_rate, 4, cl.cinematic_file);
  cin.s_rate := LittleLong(cin.s_rate);
  FS_Read(@cin.s_width, 4, cl.cinematic_file);
  cin.s_width := LittleLong(cin.s_width);
  FS_Read(@cin.s_channels, 4, cl.cinematic_file);
  cin.s_channels := LittleLong(cin.s_channels);

  Huff1TableInit();

  // switch up to 22 khz sound if necessary
  old_khz := Trunc(Cvar_VariableValue('s_khz'));
  if (old_khz <> cin.s_rate div 1000) then
  begin
    cin.restart_sound := true;
    Cvar_SetValue('s_khz', cin.s_rate div 1000);
    CL_Snd_Restart_f();
    Cvar_SetValue('s_khz', old_khz);
  end;

  cl.cinematicframe := 0;
  cin.pic := SCR_ReadNextFrame();
  cl.cinematictime := Sys_Milliseconds();

end;

end.
