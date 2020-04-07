##
##  Copyright (C) 2001-2003 Michael Niedermayer (michaelni@gmx.at)
##
##  This file is part of FFmpeg.
##
##  FFmpeg is free software; you can redistribute it and/or modify
##  it under the terms of the GNU General Public License as published by
##  the Free Software Foundation; either version 2 of the License, or
##  (at your option) any later version.
##
##  FFmpeg is distributed in the hope that it will be useful,
##  but WITHOUT ANY WARRANTY; without even the implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##  GNU General Public License for more details.
##
##  You should have received a copy of the GNU General Public License
##  along with FFmpeg; if not, write to the Free Software
##  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
##

## *
##  @file
##  @ingroup lpp
##  external API header
##
## *
##  @defgroup lpp libpostproc
##  Video postprocessing library.
##
##  @{
##

import version

## *
##  Return the LIBPOSTPROC_VERSION_INT constant.
##

type
  pp_context* = void
  pp_mode* = void

when LIBPOSTPROC_VERSION_INT < (52 shl 16):
  type
    pp_context_t* = pp_context
    pp_mode_t* = pp_mode
  var pp_help*: cstring
  ## /< a simple help text
else:
  var pp_help*: ptr char
  ## /< a simple help text

when defined(windows):
  {.push importc, dynlib: "postproc(|-53|-54|-55|-56|-57).dll".}
elif defined(macosx):
  {.push importc, dynlib: "postproc(|.53|.54|.55|.56|.57).dylib".}
else:
  {.push importc, dynlib: "libpostproc.so(|.53|.54|.55|.56|.57)".}

proc pp_postprocess*(src: array[3, ptr uint8]; srcStride: array[3, cint];
                    dst: array[3, ptr uint8]; dstStride: array[3, cint];
                    horizontalSize: cint; verticalSize: cint; QP_store: ptr int8;
                    QP_stride: cint; mode: pointer; ppContext: pointer;
                    pict_type: cint)


proc postproc_version*(): cuint
## *
##  Return the libpostproc build-time configuration.
##

proc postproc_configuration*(): cstring
## *
##  Return the libpostproc license.
##

proc postproc_license*(): cstring
const
  PP_QUALITY_MAX* = 6
## *
##  Return a pp_mode or NULL if an error occurred.
##
##  @param name    the string after "-pp" on the command line
##  @param quality a number from 0 to PP_QUALITY_MAX
##

proc pp_get_mode_by_name_and_quality*(name: cstring; quality: cint): pointer
proc pp_free_mode*(mode: pointer)
proc pp_get_context*(width: cint; height: cint; flags: cint): pointer
proc pp_free_context*(ppContext: pointer)
const
  PP_CPU_CAPS_MMX* = 0x80000000
  PP_CPU_CAPS_MMX2* = 0x20000000
  PP_CPU_CAPS_3DNOW* = 0x40000000
  PP_CPU_CAPS_ALTIVEC* = 0x10000000
  PP_CPU_CAPS_AUTO* = 0x00080000
  PP_FORMAT* = 0x00000008
  PP_FORMAT_420* = (0x00000011 or PP_FORMAT)
  PP_FORMAT_422* = (0x00000001 or PP_FORMAT)
  PP_FORMAT_411* = (0x00000002 or PP_FORMAT)
  PP_FORMAT_444* = (0x00000000 or PP_FORMAT)
  PP_FORMAT_440* = (0x00000010 or PP_FORMAT)
  PP_PICT_TYPE_QP2* = 0x00000010

## *
##  @}
##
