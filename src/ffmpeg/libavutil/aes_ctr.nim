##
##  AES-CTR cipher
##  Copyright (c) 2015 Eran Kornblau <erankor at gmail dot com>
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


const
  AES_CTR_KEY_SIZE* = (16)
  AES_CTR_IV_SIZE* = (8)

type
  AVAESCTR* {.importc, header: "<libavutil/aes_ctr.h>".} = object


when defined(windows):
  {.push importc, dynlib: "avutil(|-55|-56|-57).dll".}
elif defined(macosx):
  {.push importc, dynlib: "avutil(|.55|.56|.57).dylib".}
else:
  {.push importc, dynlib: "avutil.so(|.55|.56|.57)".}

## *
##  Allocate an AVAESCTR context.
##

proc av_aes_ctr_alloc*(): ptr AVAESCTR
## *
##  Initialize an AVAESCTR context.
##  @param key encryption key, must have a length of AES_CTR_KEY_SIZE
##

proc av_aes_ctr_init*(a: ptr AVAESCTR; key: ptr uint8): cint
## *
##  Release an AVAESCTR context.
##

proc av_aes_ctr_free*(a: ptr AVAESCTR)
## *
##  Process a buffer using a previously initialized context.
##  @param dst destination array, can be equal to src
##  @param src source array, can be equal to dst
##  @param size the size of src and dst
##

proc av_aes_ctr_crypt*(a: ptr AVAESCTR; dst: ptr uint8; src: ptr uint8; size: cint)
## *
##  Get the current iv
##

proc av_aes_ctr_get_iv*(a: ptr AVAESCTR): ptr uint8
## *
##  Generate a random iv
##

proc av_aes_ctr_set_random_iv*(a: ptr AVAESCTR)
## *
##  Forcefully change the 8-byte iv
##

proc av_aes_ctr_set_iv*(a: ptr AVAESCTR; iv: ptr uint8)
## *
##  Forcefully change the "full" 16-byte iv, including the counter
##

proc av_aes_ctr_set_full_iv*(a: ptr AVAESCTR; iv: ptr uint8)
## *
##  Increment the top 64 bit of the iv (performed after each frame)
##

proc av_aes_ctr_increment_iv*(a: ptr AVAESCTR)
## *
##  @}
##
