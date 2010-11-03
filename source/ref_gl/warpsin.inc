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
{ File(s): gl_ref/warpsin.h                                                  }
{                                                                            }
{ Initial conversion by : D-12 (d-12@laposte.net)                            }
{ Initial conversion on : 06-Jan-2002                                        }
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

  0.00000    ,  0.19633,  0.392541,  0.588517,  0.784137,  0.979285,  1.173840,  1.36770,
  1.56072    ,  1.75281,  1.943840,  2.133700,  2.322280,  2.509450,  2.695120,  2.87916,
  3.06147    ,  3.24193,  3.420440,  3.596890,  3.771170,  3.943190,  4.112820,  4.27998,
  4.44456    ,  4.60647,  4.765590,  4.921850,  5.075150,  5.225380,  5.372470,  5.51632,
  5.65685    ,  5.79398,  5.927610,  6.057670,  6.184080,  6.306770,  6.425660,  6.54068,
  6.65176    ,  6.75883,  6.861830,  6.960700,  7.055370,  7.145790,  7.231910,  7.31368,
  7.39104    ,  7.46394,  7.532350,  7.596230,  7.655520,  7.710210,  7.760250,  7.80562,
  7.84628    ,  7.88222,  7.913410,  7.939840,  7.961480,  7.978320,  7.990360,  7.99759,
  8.00000    ,  7.99759,  7.990360,  7.978320,  7.961480,  7.939840,  7.913410,  7.88222,
  7.84628    ,  7.80562,  7.760250,  7.710210,  7.655520,  7.596230,  7.532350,  7.46394,
  7.39104    ,  7.31368,  7.231910,  7.145790,  7.055370,  6.960700,  6.861830,  6.75883,
  6.65176    ,  6.54068,  6.425660,  6.306770,  6.184080,  6.057670,  5.927610,  5.79398,
  5.65685    ,  5.51632,  5.372470,  5.225380,  5.075150,  4.921850,  4.765590,  4.60647,
  4.44456    ,  4.27998,  4.112820,  3.943190,  3.771170,  3.596890,  3.420440,  3.24193,
  3.06147    ,  2.87916,  2.695120,  2.509450,  2.322280,  2.133700,  1.943840,  1.75281,
  1.56072    ,  1.36770,  1.173840,  0.979285,  0.784137,  0.588517,  0.392541,  0.19633,
  9.79717e-16, -0.19633, -0.392541, -0.588517, -0.784137, -0.979285, -1.173840, -1.36770,
 -1.56072    , -1.75281, -1.943840, -2.133700, -2.322280, -2.509450, -2.695120, -2.87916,
 -3.06147    , -3.24193, -3.420440, -3.596890, -3.771170, -3.943190, -4.112820, -4.27998,
 -4.44456    , -4.60647, -4.765590, -4.921850, -5.075150, -5.225380, -5.372470, -5.51632,
 -5.65685    , -5.79398, -5.927610, -6.057670, -6.184080, -6.306770, -6.425660, -6.54068,
 -6.65176    , -6.75883, -6.861830, -6.960700, -7.055370, -7.145790, -7.231910, -7.31368,
 -7.39104    , -7.46394, -7.532350, -7.596230, -7.655520, -7.710210, -7.760250, -7.80562,
 -7.84628    , -7.88222, -7.913410, -7.939840, -7.961480, -7.978320, -7.990360, -7.99759,
 -8.00000    , -7.99759, -7.990360, -7.978320, -7.961480, -7.939840, -7.913410, -7.88222,
 -7.84628    , -7.80562, -7.760250, -7.710210, -7.655520, -7.596230, -7.532350, -7.46394,
 -7.39104    , -7.31368, -7.231910, -7.145790, -7.055370, -6.960700, -6.861830, -6.75883,
 -6.65176    , -6.54068, -6.425660, -6.306770, -6.184080, -6.057670, -5.927610, -5.79398,
 -5.65685    , -5.51632, -5.372470, -5.225380, -5.075150, -4.921850, -4.765590, -4.60647,
 -4.44456    , -4.27998, -4.112820, -3.943190, -3.771170, -3.596890, -3.420440, -3.24193,
 -3.06147    , -2.87916, -2.695120, -2.509450, -2.322280, -2.133700, -1.943840, -1.75281,
 -1.56072    , -1.36770, -1.173840, -0.979285, -0.784137, -0.588517, -0.392541, -0.19633