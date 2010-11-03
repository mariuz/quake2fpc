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
{ File(s): anorms.c                                                          }
{                                                                            }
{ Initial conversion by : D-12 (d-12@laposte.net)                            }
{ Initial conversion on : 07-Jan-2002                                        }
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
{ none                                                                       }
{----------------------------------------------------------------------------}
{ * TODO:                                                                    }
{ none                                                                       }
{----------------------------------------------------------------------------}

(-0.525731,  0.000000,  0.850651),
(-0.442863,  0.238856,  0.864188),
(-0.295242,  0.000000,  0.955423),
(-0.309017,  0.500000,  0.809017),
(-0.162460,  0.262866,  0.951056),
( 0.000000,  0.000000,  1.000000),
( 0.000000,  0.850651,  0.525731),
(-0.147621,  0.716567,  0.681718),
( 0.147621,  0.716567,  0.681718),
( 0.000000,  0.525731,  0.850651),
( 0.309017,  0.500000,  0.809017),
( 0.525731,  0.000000,  0.850651),
( 0.295242,  0.000000,  0.955423),
( 0.442863,  0.238856,  0.864188),
( 0.162460,  0.262866,  0.951056),
(-0.681718,  0.147621,  0.716567),
(-0.809017,  0.309017,  0.500000),
(-0.587785,  0.425325,  0.688191),
(-0.850651,  0.525731,  0.000000),
(-0.864188,  0.442863,  0.238856),
(-0.716567,  0.681718,  0.147621),
(-0.688191,  0.587785,  0.425325),
(-0.500000,  0.809017,  0.309017),
(-0.238856,  0.864188,  0.442863),
(-0.425325,  0.688191,  0.587785),
(-0.716567,  0.681718, -0.147621),
(-0.500000,  0.809017, -0.309017),
(-0.525731,  0.850651,  0.000000),
( 0.000000,  0.850651, -0.525731),
(-0.238856,  0.864188, -0.442863),
( 0.000000,  0.955423, -0.295242),
(-0.262866,  0.951056, -0.162460),
( 0.000000,  1.000000,  0.000000),
( 0.000000,  0.955423,  0.295242),
(-0.262866,  0.951056,  0.162460),
( 0.238856,  0.864188,  0.442863),
( 0.262866,  0.951056,  0.162460),
( 0.500000,  0.809017,  0.309017),
( 0.238856,  0.864188, -0.442863),
( 0.262866,  0.951056, -0.162460),
( 0.500000,  0.809017, -0.309017),
( 0.850651,  0.525731,  0.000000),
( 0.716567,  0.681718,  0.147621),
( 0.716567,  0.681718, -0.147621),
( 0.525731,  0.850651,  0.000000),
( 0.425325,  0.688191,  0.587785),
( 0.864188,  0.442863,  0.238856),
( 0.688191,  0.587785,  0.425325),
( 0.809017,  0.309017,  0.500000),
( 0.681718,  0.147621,  0.716567),
( 0.587785,  0.425325,  0.688191),
( 0.955423,  0.295242,  0.000000),
( 1.000000,  0.000000,  0.000000),
( 0.951056,  0.162460,  0.262866),
( 0.850651, -0.525731,  0.000000),
( 0.955423, -0.295242,  0.000000),
( 0.864188, -0.442863,  0.238856),
( 0.951056, -0.162460,  0.262866),
( 0.809017, -0.309017,  0.500000),
( 0.681718, -0.147621,  0.716567),
( 0.850651,  0.000000,  0.525731),
( 0.864188,  0.442863, -0.238856),
( 0.809017,  0.309017, -0.500000),
( 0.951056,  0.162460, -0.262866),
( 0.525731,  0.000000, -0.850651),
( 0.681718,  0.147621, -0.716567),
( 0.681718, -0.147621, -0.716567),
( 0.850651,  0.000000, -0.525731),
( 0.809017, -0.309017, -0.500000),
( 0.864188, -0.442863, -0.238856),
( 0.951056, -0.162460, -0.262866),
( 0.147621,  0.716567, -0.681718),
( 0.309017,  0.500000, -0.809017),
( 0.425325,  0.688191, -0.587785),
( 0.442863,  0.238856, -0.864188),
( 0.587785,  0.425325, -0.688191),
( 0.688191,  0.587785, -0.425325),
(-0.147621,  0.716567, -0.681718),
(-0.309017,  0.500000, -0.809017),
( 0.000000,  0.525731, -0.850651),
(-0.525731,  0.000000, -0.850651),
(-0.442863,  0.238856, -0.864188),
(-0.295242,  0.000000, -0.955423),
(-0.162460,  0.262866, -0.951056),
( 0.000000,  0.000000, -1.000000),
( 0.295242,  0.000000, -0.955423),
( 0.162460,  0.262866, -0.951056),
(-0.442863, -0.238856, -0.864188),
(-0.309017, -0.500000, -0.809017),
(-0.162460, -0.262866, -0.951056),
( 0.000000, -0.850651, -0.525731),
(-0.147621, -0.716567, -0.681718),
( 0.147621, -0.716567, -0.681718),
( 0.000000, -0.525731, -0.850651),
( 0.309017, -0.500000, -0.809017),
( 0.442863, -0.238856, -0.864188),
( 0.162460, -0.262866, -0.951056),
( 0.238856, -0.864188, -0.442863),
( 0.500000, -0.809017, -0.309017),
( 0.425325, -0.688191, -0.587785),
( 0.716567, -0.681718, -0.147621),
( 0.688191, -0.587785, -0.425325),
( 0.587785, -0.425325, -0.688191),
( 0.000000, -0.955423, -0.295242),
( 0.000000, -1.000000,  0.000000),
( 0.262866, -0.951056, -0.162460),
( 0.000000, -0.850651,  0.525731),
( 0.000000, -0.955423,  0.295242),
( 0.238856, -0.864188,  0.442863),
( 0.262866, -0.951056,  0.162460),
( 0.500000, -0.809017,  0.309017),
( 0.716567, -0.681718,  0.147621),
( 0.525731, -0.850651,  0.000000),
(-0.238856, -0.864188, -0.442863),
(-0.500000, -0.809017, -0.309017),
(-0.262866, -0.951056, -0.162460),
(-0.850651, -0.525731,  0.000000),
(-0.716567, -0.681718, -0.147621),
(-0.716567, -0.681718,  0.147621),
(-0.525731, -0.850651,  0.000000),
(-0.500000, -0.809017,  0.309017),
(-0.238856, -0.864188,  0.442863),
(-0.262866, -0.951056,  0.162460),
(-0.864188, -0.442863,  0.238856),
(-0.809017, -0.309017,  0.500000),
(-0.688191, -0.587785,  0.425325),
(-0.681718, -0.147621,  0.716567),
(-0.442863, -0.238856,  0.864188),
(-0.587785, -0.425325,  0.688191),
(-0.309017, -0.500000,  0.809017),
(-0.147621, -0.716567,  0.681718),
(-0.425325, -0.688191,  0.587785),
(-0.162460, -0.262866,  0.951056),
( 0.442863, -0.238856,  0.864188),
( 0.162460, -0.262866,  0.951056),
( 0.309017, -0.500000,  0.809017),
( 0.147621, -0.716567,  0.681718),
( 0.000000, -0.525731,  0.850651),
( 0.425325, -0.688191,  0.587785),
( 0.587785, -0.425325,  0.688191),
( 0.688191, -0.587785,  0.425325),
(-0.955423,  0.295242,  0.000000),
(-0.951056,  0.162460,  0.262866),
(-1.000000,  0.000000,  0.000000),
(-0.850651,  0.000000,  0.525731),
(-0.955423, -0.295242,  0.000000),
(-0.951056, -0.162460,  0.262866),
(-0.864188,  0.442863, -0.238856),
(-0.951056,  0.162460, -0.262866),
(-0.809017,  0.309017, -0.500000),
(-0.864188, -0.442863, -0.238856),
(-0.951056, -0.162460, -0.262866),
(-0.809017, -0.309017, -0.500000),
(-0.681718,  0.147621, -0.716567),
(-0.681718, -0.147621, -0.716567),
(-0.850651,  0.000000, -0.525731),
(-0.688191,  0.587785, -0.425325),
(-0.587785,  0.425325, -0.688191),
(-0.425325,  0.688191, -0.587785),
(-0.425325, -0.688191, -0.587785),
(-0.587785, -0.425325, -0.688191),
(-0.688191, -0.587785, -0.425325)