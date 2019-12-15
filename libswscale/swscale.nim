##
##  Copyright (C) 2001-2011 Michael Niedermayer <michaelni@gmx.at>
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
##  @ingroup libsws
##  external API header
##

import
  ../utiltypes,
  ../libavutil/pixfmt,
  version

when defined(windows):
  {.push importc, dynlib: "swscale(|-4|-5|-6).dll".}
elif defined(macosx):
  {.push importc, dynlib: "swscale(|.4|.5|.6).dylib".}
else:swscale
  {.push importc, dynlib: "swscale.so(|.4|.5|.6)".}

{.pragma: swscale, importc, header: "<libswscale/swscale.h>".}

## *
##  @defgroup libsws libswscale
##  Color conversion and scaling library.
##
##  @{
##
##  Return the LIBSWSCALE_VERSION_INT constant.
##

proc swscale_version*(): cuint
## *
##  Return the libswscale build-time configuration.
##

proc swscale_configuration*(): cstring
## *
##  Return the libswscale license.
##

proc swscale_license*(): cstring
##  values for the flags, the stuff on the command line is different

const
  SWS_FAST_BILINEAR* = 1
  SWS_BILINEAR* = 2
  SWS_BICUBIC* = 4
  SWS_X* = 8
  SWS_POINT* = 0x00000010
  SWS_AREA* = 0x00000020
  SWS_BICUBLIN* = 0x00000040
  SWS_GAUSS* = 0x00000080
  SWS_SINC* = 0x00000100
  SWS_LANCZOS* = 0x00000200
  SWS_SPLINE* = 0x00000400
  SWS_SRC_V_CHR_DROP_MASK* = 0x00030000
  SWS_SRC_V_CHR_DROP_SHIFT* = 16
  SWS_PARAM_DEFAULT* = 123456
  SWS_PRINT_INFO* = 0x00001000

## the following 3 flags are not completely implemented
## internal chrominance subsampling info

const
  SWS_FULL_CHR_H_INT* = 0x00002000

## input subsampling info

const
  SWS_FULL_CHR_H_INP* = 0x00004000
  SWS_DIRECT_BGR* = 0x00008000
  SWS_ACCURATE_RND* = 0x00040000
  SWS_BITEXACT* = 0x00080000
  SWS_ERROR_DIFFUSION* = 0x00800000
  SWS_MAX_REDUCE_CUTOFF* = 0.002
  SWS_CS_ITU709* = 1
  SWS_CS_FCC* = 4
  SWS_CS_ITU601* = 5
  SWS_CS_ITU624* = 5
  SWS_CS_SMPTE170M* = 5
  SWS_CS_SMPTE240M* = 7
  SWS_CS_DEFAULT* = 5
  SWS_CS_BT2020* = 9

## *
##  Return a pointer to yuv<->rgb coefficients for the given colorspace
##  suitable for sws_setColorspaceDetails().
##
##  @param colorspace One of the SWS_CS_* macros. If invalid,
##  SWS_CS_DEFAULT is used.
##

proc sws_getCoefficients*(colorspace: cint): ptr cint
##  when used for filters they must have an odd number of elements
##  coeffs cannot be shared between vectors

type
  SwsVector* {.swscale.} = object
    coeff*: ptr cdouble         ## /< pointer to the list of coefficients
    length*: cint              ## /< number of coefficients in the vector


##  vectors can be shared

type
  SwsFilter* {.swscale.} = object
    lumH*: ptr SwsVector
    lumV*: ptr SwsVector
    chrH*: ptr SwsVector
    chrV*: ptr SwsVector

  SwsContext* {.swscale, importc: "struct SwsContext".} = object


## *
##  Return a positive value if pix_fmt is a supported input format, 0
##  otherwise.
##

proc sws_isSupportedInput*(pix_fmt: AVPixelFormat): cint
## *
##  Return a positive value if pix_fmt is a supported output format, 0
##  otherwise.
##

proc sws_isSupportedOutput*(pix_fmt: AVPixelFormat): cint
## *
##  @param[in]  pix_fmt the pixel format
##  @return a positive value if an endianness conversion for pix_fmt is
##  supported, 0 otherwise.
##

proc sws_isSupportedEndiannessConversion*(pix_fmt: AVPixelFormat): cint
## *
##  Allocate an empty SwsContext. This must be filled and passed to
##  sws_init_context(). For filling see AVOptions, options.c and
##  sws_setColorspaceDetails().
##

proc sws_alloc_context*(): ptr SwsContext
## *
##  Initialize the swscaler context sws_context.
##
##  @return zero or positive value on success, a negative value on
##  error
##

proc sws_init_context*(sws_context: ptr SwsContext; srcFilter: ptr SwsFilter;
                      dstFilter: ptr SwsFilter): cint
## *
##  Free the swscaler context swsContext.
##  If swsContext is NULL, then does nothing.
##

proc sws_freeContext*(swsContext: ptr SwsContext)
## *
##  Allocate and return an SwsContext. You need it to perform
##  scaling/conversion operations using sws_scale().
##
##  @param srcW the width of the source image
##  @param srcH the height of the source image
##  @param srcFormat the source image format
##  @param dstW the width of the destination image
##  @param dstH the height of the destination image
##  @param dstFormat the destination image format
##  @param flags specify which algorithm and options to use for rescaling
##  @param param extra parameters to tune the used scaler
##               For SWS_BICUBIC param[0] and [1] tune the shape of the basis
##               function, param[0] tunes f(1) and param[1] f´(1)
##               For SWS_GAUSS param[0] tunes the exponent and thus cutoff
##               frequency
##               For SWS_LANCZOS param[0] tunes the width of the window function
##  @return a pointer to an allocated context, or NULL in case of error
##  @note this function is to be removed after a saner alternative is
##        written
##

proc sws_getContext*(srcW: cint; srcH: cint; srcFormat: AVPixelFormat; dstW: cint;
                    dstH: cint; dstFormat: AVPixelFormat; flags: cint;
                    srcFilter: ptr SwsFilter; dstFilter: ptr SwsFilter;
                    param: ptr cdouble): ptr SwsContext
## *
##  Scale the image slice in srcSlice and put the resulting scaled
##  slice in the image in dst. A slice is a sequence of consecutive
##  rows in an image.
##
##  Slices have to be provided in sequential order, either in
##  top-bottom or bottom-top order. If slices are provided in
##  non-sequential order the behavior of the function is undefined.
##
##  @param c         the scaling context previously created with
##                   sws_getContext()
##  @param srcSlice  the array containing the pointers to the planes of
##                   the source slice
##  @param srcStride the array containing the strides for each plane of
##                   the source image
##  @param srcSliceY the position in the source image of the slice to
##                   process, that is the number (counted starting from
##                   zero) in the image of the first row of the slice
##  @param srcSliceH the height of the source slice, that is the number
##                   of rows in the slice
##  @param dst       the array containing the pointers to the planes of
##                   the destination image
##  @param dstStride the array containing the strides for each plane of
##                   the destination image
##  @return          the height of the output slice
##

proc sws_scale*(c: ptr SwsContext; srcSlice: ptr ptr uint8; srcStride: ptr cint;
               srcSliceY: cint; srcSliceH: cint; dst: ptr ptr uint8;
               dstStride: ptr cint): cint
## *
##  @param dstRange flag indicating the while-black range of the output (1=jpeg / 0=mpeg)
##  @param srcRange flag indicating the while-black range of the input (1=jpeg / 0=mpeg)
##  @param table the yuv2rgb coefficients describing the output yuv space, normally ff_yuv2rgb_coeffs[x]
##  @param invable the yuv2rgb coefficients describing the input yuv space, normally ff_yuv2rgb_coeffs[x]
##  @param brightness 16.16 fixed point brightness correction
##  @param contrast 16.16 fixed point contrast correction
##  @param saturation 16.16 fixed point saturation correction
##  @return -1 if not supported
##

proc sws_setColorspaceDetails*(c: ptr SwsContext; invable: array[4, cint];
                              srcRange: cint; table: array[4, cint]; dstRange: cint;
                              brightness: cint; contrast: cint; saturation: cint): cint
## *
##  @return -1 if not supported
##

proc sws_getColorspaceDetails*(c: ptr SwsContext; invable: ptr ptr cint;
                              srcRange: ptr cint; table: ptr ptr cint;
                              dstRange: ptr cint; brightness: ptr cint;
                              contrast: ptr cint; saturation: ptr cint): cint
## *
##  Allocate and return an uninitialized vector with length coefficients.
##

proc sws_allocVec*(length: cint): ptr SwsVector
## *
##  Return a normalized Gaussian curve used to filter stuff
##  quality = 3 is high quality, lower is lower quality.
##

proc sws_getGaussianVec*(variance: cdouble; quality: cdouble): ptr SwsVector
## *
##  Scale all the coefficients of a by the scalar value.
##

proc sws_scaleVec*(a: ptr SwsVector; scalar: cdouble)
## *
##  Scale all the coefficients of a so that their sum equals height.
##

proc sws_normalizeVec*(a: ptr SwsVector; height: cdouble)
when FF_API_SWS_VECTOR:
  proc sws_getConstVec*(c: cdouble; length: cint): ptr SwsVector
  proc sws_getIdentityVec*(): ptr SwsVector
  proc sws_convVec*(a: ptr SwsVector; b: ptr SwsVector)
  proc sws_addVec*(a: ptr SwsVector; b: ptr SwsVector)
  proc sws_subVec*(a: ptr SwsVector; b: ptr SwsVector)
  proc sws_shiftVec*(a: ptr SwsVector; shift: cint)
  proc sws_cloneVec*(a: ptr SwsVector): ptr SwsVector
  proc sws_printVec2*(a: ptr SwsVector; log_ctx: ptr AVClass; log_level: cint)
proc sws_freeVec*(a: ptr SwsVector)
proc sws_getDefaultFilter*(lumaGBlur: cfloat; chromaGBlur: cfloat;
                          lumaSharpen: cfloat; chromaSharpen: cfloat;
                          chromaHShift: cfloat; chromaVShift: cfloat; verbose: cint): ptr SwsFilter
proc sws_freeFilter*(filter: ptr SwsFilter)
## *
##  Check if context can be reused, otherwise reallocate a new one.
##
##  If context is NULL, just calls sws_getContext() to get a new
##  context. Otherwise, checks if the parameters are the ones already
##  saved in context. If that is the case, returns the current
##  context. Otherwise, frees context and gets a new context with
##  the new parameters.
##
##  Be warned that srcFilter and dstFilter are not checked, they
##  are assumed to remain the same.
##

proc sws_getCachedContext*(context: ptr SwsContext; srcW: cint; srcH: cint;
                          srcFormat: AVPixelFormat; dstW: cint; dstH: cint;
                          dstFormat: AVPixelFormat; flags: cint;
                          srcFilter: ptr SwsFilter; dstFilter: ptr SwsFilter;
                          param: ptr cdouble): ptr SwsContext
## *
##  Convert an 8-bit paletted frame into a frame with a color depth of 32 bits.
##
##  The output frame will have the same packed format as the palette.
##
##  @param src        source frame buffer
##  @param dst        destination frame buffer
##  @param num_pixels number of pixels to convert
##  @param palette    array with [256] entries, which must match color arrangement (RGB or BGR) of src
##

proc sws_convertPalette8ToPacked32*(src: ptr uint8; dst: ptr uint8;
                                   num_pixels: cint; palette: ptr uint8)
## *
##  Convert an 8-bit paletted frame into a frame with a color depth of 24 bits.
##
##  With the palette format "ABCD", the destination frame ends up with the format "ABC".
##
##  @param src        source frame buffer
##  @param dst        destination frame buffer
##  @param num_pixels number of pixels to convert
##  @param palette    array with [256] entries, which must match color arrangement (RGB or BGR) of src
##

proc sws_convertPalette8ToPacked24*(src: ptr uint8; dst: ptr uint8;
                                   num_pixels: cint; palette: ptr uint8)
## *
##  Get the AVClass for swsContext. It can be used in combination with
##  AV_OPT_SEARCH_FAKE_OBJ for examining options.
##
##  @see av_opt_find().
##

proc sws_get_class*(): ptr AVClass
## *
##  @}
##
