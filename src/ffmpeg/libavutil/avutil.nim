##
##  copyright (c) 2006 Michael Niedermayer <michaelni@gmx.at>
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
##  @ingroup lavu
##  Convenience header that includes @ref lavu "libavutil"'s core.
##
## *
##  @mainpage
##
##  @section ffmpeg_intro Introduction
##
##  This document describes the usage of the different libraries
##  provided by FFmpeg.
##
##  @li @ref libavc "libavcodec" encoding/decoding library
##  @li @ref lavfi "libavfilter" graph-based frame editing library
##  @li @ref libavf "libavformat" I/O and muxing/demuxing library
##  @li @ref lavd "libavdevice" special devices muxing/demuxing library
##  @li @ref lavu "libavutil" common utility library
##  @li @ref lswr "libswresample" audio resampling, format conversion and mixing
##  @li @ref lpp  "libpostproc" post processing library
##  @li @ref libsws "libswscale" color conversion and scaling library
##
##  @section ffmpeg_versioning Versioning and compatibility
##
##  Each of the FFmpeg libraries contains a version.h header, which defines a
##  major, minor and micro version number with the
##  <em>LIBRARYNAME_VERSION_{MAJOR,MINOR,MICRO}</em> macros. The major version
##  number is incremented with backward incompatible changes - e.g. removing
##  parts of the public API, reordering public struct members, etc. The minor
##  version number is incremented for backward compatible API changes or major
##  new features - e.g. adding a new public function or a new decoder. The micro
##  version number is incremented for smaller changes that a calling program
##  might still want to check for - e.g. changing behavior in a previously
##  unspecified situation.
##
##  FFmpeg guarantees backward API and ABI compatibility for each library as long
##  as its major version number is unchanged. This means that no public symbols
##  will be removed or renamed. Types and names of the public struct members and
##  values of public macros and enums will remain the same (unless they were
##  explicitly declared as not part of the public API). Documented behavior will
##  not change.
##
##  In other words, any correct program that works with a given FFmpeg snapshot
##  should work just as well without any changes with any later snapshot with the
##  same major versions. This applies to both rebuilding the program against new
##  FFmpeg versions or to replacing the dynamic FFmpeg libraries that a program
##  links against.
##
##  However, new public symbols may be added and new members may be appended to
##  public structs whose size is not part of public ABI (most public structs in
##  FFmpeg). New macros and enum values may be added. Behavior in undocumented
##  situations may change slightly (and be documented). All those are accompanied
##  by an entry in doc/APIchanges and incrementing either the minor or micro
##  version number.
##
## *
##  @defgroup lavu libavutil
##  Common code shared across all FFmpeg libraries.
##
##  @note
##  libavutil is designed to be modular. In most cases, in order to use the
##  functions provided by one component of libavutil you must explicitly include
##  the specific header containing that feature. If you are only using
##  media-related components, you could simply include libavutil/avutil.h, which
##  brings in most of the "core" components.
##
##  @{
##
##  @defgroup lavu_crypto Crypto and Hashing
##
##  @{
##  @}
##
##  @defgroup lavu_math Mathematics
##  @{
##
##  @}
##
##  @defgroup lavu_string String Manipulation
##
##  @{
##
##  @}
##
##  @defgroup lavu_mem Memory Management
##
##  @{
##
##  @}
##
##  @defgroup lavu_data Data Structures
##  @{
##
##  @}
##
##  @defgroup lavu_video Video related
##
##  @{
##
##  @}
##
##  @defgroup lavu_audio Audio related
##
##  @{
##
##  @}
##
##  @defgroup lavu_error Error Codes
##
##  @{
##
##  @}
##
##  @defgroup lavu_log Logging Facility
##
##  @{
##
##  @}
##
##  @defgroup lavu_misc Other
##
##  @{
##
##  @defgroup preproc_misc Preprocessor String Macros
##
##  @{
##
##  @}
##
##  @defgroup version_utils Library Version Macros
##
##  @{
##
##  @}
##
## *
##  @addtogroup lavu_ver
##  @{
##
## *
##  Return the LIBAVUTIL_VERSION_INT constant.
##

#[
import
  common, error, rational, version, macros, mathematics, log, pixfmt
]#
import rational, ../utiltypes

when defined(windows):
  {.push importc, dynlib: "avutil(|-55|-56|-57).dll".}
elif defined(macosx):
  {.push importc, dynlib: "avutil(|.55|.56|.57).dylib".}
else:
  {.push importc, dynlib: "libavutil.so(|.55|.56|.57)".}

proc avutil_version*(): cuint
## *
##  Return an informative version string. This usually is the actual release
##  version number or a git commit description. This string has no fixed format
##  and can change any time. It should never be parsed by code.
##

proc av_version_info*(): cstring
## *
##  Return the libavutil build-time configuration.
##

proc avutil_configuration*(): cstring
## *
##  Return the libavutil license.
##

proc avutil_license*(): cstring
## *
##  @}
##
## *
##  @addtogroup lavu_media Media Type
##  @brief Media Type
##

## *
##  Return a string describing the mediaype enum, NULL if mediaype
##  is unknown.
##

proc av_get_mediaype_string*(mediaype: AVMediaType): cstring
## *
##  @defgroup lavu_const Constants
##  @{
##
##  @defgroup lavu_enc Encoding specific
##
##  @note those definition should move to avcodec
##  @{
##

const
  FF_LAMBDA_SHIFT* = 7
  FF_LAMBDA_SCALE* = (1 shl FF_LAMBDA_SHIFT)
  FF_QP2LAMBDA* = 118
  FF_LAMBDA_MAX* = (256 * 128 - 1)
  FF_QUALITY_SCALE* = FF_LAMBDA_SCALE

## *
##  @}
##  @defgroup lavuime Timestamp specific
##
##  FFmpeg internal timebase and timestamp definitions
##
##  @{
##
## *
##  @brief Undefined timestamp value
##
##  Usually reported by demuxer that work on containers that do not provide
##  either pts or dts.
##

const
  #AV_NOPTS_VALUE* = (cast[int64](UINT64_C(0x0000000000000000'i64)))
  AV_NOPTS_VALUE* = 0x0000000000000000'i64

## *
##  Internal time base represented as integer
##

const
  AV_TIME_BASE* = 1000000

## *
##  Internal time base represented as fractional value
##
## #define AV_TIME_BASE_Q          (AVRational){1, AV_TIME_BASE}
## *
##  @}
##  @}
##  @defgroup lavu_picture Image related
##
##  AVPicture types, pixel formats and basic image planes manipulation.
##
##  @{
##

## *
##  Return a single letter to describe the given picture type
##  pictype.
##
##  @param[in] pictype the picture type @return a single character
##  representing the picture type, '?' if pictype is unknown
##

proc av_get_pictureype_char*(pictype: AVPictureType): char
## *
##  @}
##

## *
##  Return x default pointer in case p is NULL.
##

proc av_x_if_null*(p: pointer; x: pointer): pointer {.inline.} =
  #return cast[pointer]((intptr)(if p: p else: x))
  if p.isNil: x
  else: p

## *
##  Compute the length of an integer list.
##
##  @param elsize  size in bytes of each list element (only 1, 2, 4 or 8)
##  @param term    list terminator (usually 0 or -1)
##  @param list    pointer to the list
##  @return  length of the list, in elements, not counting the terminator
##

proc av_int_list_length_for_size*(elsize: cuint; list: pointer; term: uint64): cuint
  ## const void *list, uint64 term) av_pure;
## *
##  Compute the length of an integer list.
##
##  @param term  list terminator (usually 0 or -1)
##  @param list  pointer to the list
##  @return  length of the list, in elements, not counting the terminator
##

template av_int_list_length*(list, term: untyped): untyped =
  av_int_list_length_for_size(sizeof(((list)[])), list, term)

## *
##  Open a file using a UTF-8 filename.
##  The API of this function matches POSIX fopen(), errors are returned through
##  errno.
##

proc av_fopen_utf8*(path: cstring; mode: cstring): ptr FILE
## *
##  Return the fractional representation of the internal time base.
##

proc av_getime_base_q*(): AVRational
const
  AV_FOURCC_MAX_STRING_SIZE* = 32

## #define av_fourcc2str(fourcc) av_fourcc_make_string((char[AV_FOURCC_MAX_STRING_SIZE]){0}, fourcc)
## *
##  Fill the provided buffer with a string containing a FourCC (four-character
##  code) representation.
##
##  @param buf    a buffer with size in bytes of at least AV_FOURCC_MAX_STRING_SIZE
##  @param fourcc the fourcc to represent
##  @return the buffer in input
##

proc av_fourcc_make_string*(buf: cstring; fourcc: uint32): cstring
## *
##  @}
##  @}
##