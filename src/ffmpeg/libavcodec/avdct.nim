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

import
  ../utiltypes

## *
##  AVDCT context.
##  @note function pointers can be NULL if the specific features have been
##        disabled at build time.
##

{.pragma: avdct, importc, header:"<libavcodec/avdct.h>".}

type
  AVDCT* {.avdct.} = object
    av_class*: ptr AVClass
    idct*: proc (`block`: ptr int16) ##  IDCT input permutation.
                                ##  Several optimized IDCTs need a permutated input (relative to the
                                ##  normal order of the reference IDCT).
                                ##  This permutation must be performed before the idct_put/add.
                                ##  Note, normally this can be merged with the zigzag/alternate scan<br>
                                ##  An example to avoid confusion:
                                ##  - (->decode coeffs -> zigzag reorder -> dequant -> reference IDCT -> ...)
                                ##  - (x -> reference DCT -> reference IDCT -> x)
                                ##  - (x -> reference DCT -> simple_mmx_perm = idct_permutation
                                ##     -> simple_idct_mmx -> x)
                                ##  - (-> decode coeffs -> zigzag reorder -> simple_mmx_perm -> dequant
                                ##     -> simple_idct_mmx -> ...)
                                ##
                                ##  align 16
    idct_permutation*: array[64, uint8]
    fdct*: proc (`block`: ptr int16) ## *
                                ##  DCT algorithm.
                                ##  must use AVOptions to set this field.
                                ##
    ##  align 16
    dct_algo*: cint            ## *
                  ##  IDCT algorithm.
                  ##  must use AVOptions to set this field.
                  ##
    idct_algo*: cint
    get_pixels*: proc (`block`: ptr int16; ##  align 16
                     pixels: ptr uint8; ##  align 8
                     line_size: csize)
    bits_per_sample*: cint


## *
##  Allocates a AVDCT context.
##  This needs to be initialized with avcodec_dct_init() after optionally
##  configuring it with AVOptions.
##
##  To free it use av_free()
##

when defined(windows):
  {.push importc, dynlib: "avcodec(|-55|-56|-57|-58|-59).dll".}
elif defined(macosx):
  {.push importc, dynlib: "avcodec(|.55|.56|.57|.58|.59).dylib".}
else:
  {.push importc, dynlib: "avcodec.so(|.55|.56|.57|.58|.59)".}

proc avcodec_dct_alloc*(): ptr AVDCT
proc avcodec_dct_init*(a1: ptr AVDCT): cint
proc avcodec_dct_get_class*(): ptr AVClass