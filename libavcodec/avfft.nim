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

## *
##  @file
##  @ingroup lavc_fft
##  FFT functions
##
## *
##  @defgroup lavc_fft FFT functions
##  @ingroup lavc_misc
##
##  @{
##

type
  FFTSample* = cfloat
  FFTComplex* {.bycopy.} = object
    re*: FFTSample
    im*: FFTSample


## *
##  Set up a complex FFT.
##  @param nbits           log2 of the length of the input array
##  @param inverse         if 0 perform the forward transform, if 1 perform the inverse
##

proc av_fft_init*(nbits: cint; inverse: cint): ptr FFTContext
## *
##  Do the permutation needed BEFORE calling ff_fft_calc().
##

proc av_fft_permute*(s: ptr FFTContext; z: ptr FFTComplex)
## *
##  Do a complex FFT with the parameters defined in av_fft_init(). The
##  input data must be permuted before. No 1.0/sqrt(n) normalization is done.
##

proc av_fft_calc*(s: ptr FFTContext; z: ptr FFTComplex)
proc av_fft_end*(s: ptr FFTContext)
proc av_mdct_init*(nbits: cint; inverse: cint; scale: cdouble): ptr FFTContext
proc av_imdct_calc*(s: ptr FFTContext; output: ptr FFTSample; input: ptr FFTSample)
proc av_imdct_half*(s: ptr FFTContext; output: ptr FFTSample; input: ptr FFTSample)
proc av_mdct_calc*(s: ptr FFTContext; output: ptr FFTSample; input: ptr FFTSample)
proc av_mdct_end*(s: ptr FFTContext)
##  Real Discrete Fourier Transform

type
  RDFTransformType* = enum
    DFT_R2C, IDFT_C2R, IDFT_R2C, DFT_C2R



## *
##  Set up a real FFT.
##  @param nbits           log2 of the length of the input array
##  @param trans           the type of transform
##

proc av_rdft_init*(nbits: cint; trans: RDFTransformType): ptr RDFTContext
proc av_rdft_calc*(s: ptr RDFTContext; data: ptr FFTSample)
proc av_rdft_end*(s: ptr RDFTContext)
##  Discrete Cosine Transform

type
  DCTTransformType* = enum
    DCT_II = 0, DCT_III, DCT_I, DST_I


## *
##  Set up DCT.
##
##  @param nbits           size of the input array:
##                         (1 << nbits)     for DCT-II, DCT-III and DST-I
##                         (1 << nbits) + 1 for DCT-I
##  @param type            the type of transform
##
##  @note the first element of the input of DST-I is ignored
##

proc av_dct_init*(nbits: cint; type: DCTTransformType): ptr DCTContext
proc av_dct_calc*(s: ptr DCTContext; data: ptr FFTSample)
proc av_dct_end*(s: ptr DCTContext)
## *
##  @}
##
