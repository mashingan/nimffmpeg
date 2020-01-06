##
##  copyright (c) 2007 Michael Niedermayer <michaelni@gmx.at>
##
##  This file is part of FFmpeg.
##
##  FFmpeg is free software; you can redistribute it and/or
##  modify it under the terms of the GNU Lesser General Public
##  License as published by the Free Software Foundation; either
##  version 2.1 of the License, or (at your option) any later version.
##
##  FFmpeg is distributed in the hope that it will be useful,
##  but WITHOUT ANY WARRANTY; without even the implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
##  Lesser General Public License for more details.
##
##  You should have received a copy of the GNU Lesser General Public
##  License along with FFmpeg; if not, write to the Free Software
##  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
##

#import attributes, version

## *
##  @defgroup lavu_aes AES
##  @ingroup lavu_crypto
##  @{
##

var av_aes_size*: cint

type
  AVAES* {.importc, header: "<libavutil/aes.h>".} = object

when defined(windows):
  {.push importc, dynlib: "avutil(|-55|-56|-57).dll".}
elif defined(macosx):
  {.push importc, dynlib: "avutil(|.55|.56|.57).dylib".}
else:
  {.push importc, dynlib: "avutil.so(|.55|.56|.57)".}


## *
##  Allocate an AVAES context.
##

proc av_aes_alloc*(): ptr AVAES
## *
##  Initialize an AVAES context.
##  @param key_bits 128, 192 or 256
##  @param decrypt 0 for encryption, 1 for decryption
##

proc av_aes_init*(a: ptr AVAES; key: ptr uint8; key_bits: cint; decrypt: cint): cint
## *
##  Encrypt or decrypt a buffer using a previously initialized context.
##  @param count number of 16 byte blocks
##  @param dst destination array, can be equal to src
##  @param src source array, can be equal to dst
##  @param iv initialization vector for CBC mode, if NULL then ECB will be used
##  @param decrypt 0 for encryption, 1 for decryption
##

proc av_aes_crypt*(a: ptr AVAES; dst: ptr uint8; src: ptr uint8; count: cint;
                  iv: ptr uint8; decrypt: cint)
## *
##  @}
##
