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

{$ALIGN ON}{$MINENUMSIZE 4}
unit gl_local_add;

interface

uses
  q_shared;

type
  imagetype_t = (it_skin, it_sprite, it_wall, it_pic, it_sky);

  image_p = ^image_t;
  image_t = record
    name  : array [0..MAX_QPATH-1] of char;  // game path, including extension
    type_ : imagetype_t;
    width, height,              // source image
    upload_width, upload_height,             // after power of two and picmip
    registration_sequence        : integer;  // 0 = free

//   struct msurface_s   *texturechain;   // for sort-by-texture world drawing
    texturechain: pointer;//msurface_p;  // for sort-by-texture world drawing

    texnum : integer;                  // gl texture binding
    sl, tl, sh, th : Single;              // 0,0 - 1,1 unless part of the scrap
    scrap,
    has_alpha,
    paletted  : qboolean;
  end;


implementation

end.
 
