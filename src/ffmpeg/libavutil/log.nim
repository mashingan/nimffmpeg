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

import ../utiltypes

when defined(windows):
  #{.push importc, dynlib: "avutil-(|55|56|57).dll".}
  {.pragma: rtl, importc, dynlib: "avutil-(|55|56|57).dll".}
elif defined(macosx):
  #{.push importc, dynliib".}
  {.pragma: rtl, importc, dynlib: "avutil(|.55|.56|.57).dylib".}
else:
  #{.push importc, dynli.}
  {.pragma: rtl, importc, dynlib: "libavutil.so(|.55|.56|.57)".}


template AV_IS_INPUT_DEVICE*(category: untyped): untyped =
  (((category) == AV_CLASS_CATEGORY_DEVICE_VIDEO_INPUT) or
      ((category) == AV_CLASS_CATEGORY_DEVICE_AUDIO_INPUT) or
      ((category) == AV_CLASS_CATEGORY_DEVICE_INPUT))

template AV_IS_OUTPUT_DEVICE*(category: untyped): untyped =
  (((category) == AV_CLASS_CATEGORY_DEVICE_VIDEO_OUTPUT) or
      ((category) == AV_CLASS_CATEGORY_DEVICE_AUDIO_OUTPUT) or
      ((category) == AV_CLASS_CATEGORY_DEVICE_OUTPUT))

## *
##  Describe the class of an AVClass context structure. That is an
##  arbitrary struct of which the first field is a pointer to an
##  AVClass struct (e.g. AVCodecContext, AVFormatContext etc.).
##


## *
##  @addtogroup lavu_log
##
##  @{
##
##  @defgroup lavu_log_constants Logging Constants
##
##  @{
##
## *
##  Print no output.
##

const
  AV_LOG_QUIET* = -8

## *
##  Something went really wrong and we will crash now.
##

const
  AV_LOG_PANIC* = 0

## *
##  Something went wrong and recovery is not possible.
##  For example, no header was found for a format which depends
##  on headers or an illegal combination of parameters is used.
##

const
  AV_LOG_FATAL* = 8

## *
##  Something went wrong and cannot losslessly be recovered.
##  However, not all future data is affected.
##

const
  AV_LOG_ERROR* = 16

## *
##  Something somehow does not look correct. This may or may not
##  lead to problems. An example would be the use of '-vstrict -2'.
##

const
  AV_LOG_WARNING* = 24

## *
##  Standard information.
##

const
  AV_LOG_INFO* = 32

## *
##  Detailed information.
##

const
  AV_LOG_VERBOSE* = 40

## *
##  Stuff which is only useful for libav* developers.
##

const
  AV_LOG_DEBUG* = 48

## *
##  Extremely verbose debugging, useful for libav* development.
##

const
  AV_LOG_TRACE* = 56
  AV_LOG_MAX_OFFSET* = (AV_LOG_TRACE - AV_LOG_QUIET)

## *
##  @}
##
## *
##  Sets additional colors for extended debugging sessions.
##  @code
##    av_log(ctx, AV_LOG_DEBUG|AV_LOG_C(134), "Message in purple\n");
##    @endcode
##  Requires 256color terminal support. Uses outside debugging is not
##  recommended.
##

template AV_LOG_C*(x: untyped): untyped =
  ((x) shl 8)

## *
##  Send the specified message to the log if the level is less than or equal
##  to the current av_log_level. By default, all logging messages are sent to
##  stderr. This behavior can be altered by setting a different logging callback
##  function.
##  @see av_log_set_callback
##
##  @param avcl A pointer to an arbitrary struct of which the first field is a
##         pointer to an AVClass struct or NULL if general log.
##  @param level The importance level of the message expressed using a @ref
##         lavu_log_constants "Logging Constant".
##  @param fmt The format string (printf-compatible) that specifies how
##         subsequent arguments are converted to output.
##
## void av_log(void *avcl, int level, const char *fmt, ...) av_printf_format(3, 4);

proc av_log*(avcl: pointer; level: cint; fmt: cstring) {.rtl, varargs.}
## *
##  Send the specified message to the log if the level is less than or equal
##  to the current av_log_level. By default, all logging messages are sent to
##  stderr. This behavior can be altered by setting a different logging callback
##  function.
##  @see av_log_set_callback
##
##  @param avcl A pointer to an arbitrary struct of which the first field is a
##         pointer to an AVClass struct.
##  @param level The importance level of the message expressed using a @ref
##         lavu_log_constants "Logging Constant".
##  @param fmt The format string (printf-compatible) that specifies how
##         subsequent arguments are converted to output.
##  @param vl The arguments referenced by the format string.
##

proc av_vlog*(avcl: pointer; level: cint; fmt: cstring; vl: cstring) {.rtl, varargs.}
## *
##  Get the current log level
##
##  @see lavu_log_constants
##
##  @return Current log level
##

proc av_log_get_level*(): cint {.rtl.}
## *
##  Set the log level
##
##  @see lavu_log_constants
##
##  @param level Logging level
##

proc av_log_set_level*(level: cint) {.rtl.}
## *
##  Set the logging callback
##
##  @note The callback must be thread safe, even if the application does not use
##        threads itself as some codecs are multithreaded.
##
##  @see av_log_default_callback
##
##  @param callback A logging function with a compatible signature.
##

proc av_log_set_callback*(callback: proc (a1: pointer; a2: cint; a3: cstring; a4: cstring){.varargs.}){.rtl.}
## *
##  Default logging callback
##
##  It prints the message to stderr, optionally colorizing it.
##
##  @param avcl A pointer to an arbitrary struct of which the first field is a
##         pointer to an AVClass struct.
##  @param level The importance level of the message expressed using a @ref
##         lavu_log_constants "Logging Constant".
##  @param fmt The format string (printf-compatible) that specifies how
##         subsequent arguments are converted to output.
##  @param vl The arguments referenced by the format string.
##

proc av_log_default_callback*(avcl: pointer; level: cint; fmt: cstring; vl: cstring) {.rtl, varargs.}
## *
##  Return the context name
##
##  @param  ctx The AVClass context
##
##  @return The AVClass class_name
##

proc av_default_item_name*(ctx: pointer): cstring {.rtl.}
proc av_default_get_category*(theptr: pointer): AVClassCategory {.rtl.}
## *
##  Format a line of log the same way as the default callback.
##  @param line          buffer to receive the formatted line
##  @param line_size     size of the buffer
##  @param print_prefix  used to store whether the prefix must be printed;
##                       must point to a persistent integer initially set to 1
##

#proc av_log_format_line*(ptr: pointer; level: cint; fmt: cstring; vl: va_list;
#                        line: cstring; line_size: cint; print_prefix: ptr cint)
## *
##  Format a line of log the same way as the default callback.
##  @param line          buffer to receive the formatted line;
##                       may be NULL if line_size is 0
##  @param line_size     size of the buffer; at most line_size-1 characters will
##                       be written to the buffer, plus one null terminator
##  @param print_prefix  used to store whether the prefix must be printed;
##                       must point to a persistent integer initially set to 1
##  @return Returns a negative value if an error occurred, otherwise returns
##          the number of characters that would have been written for a
##          sufficiently large buffer, not including the terminating null
##          character. If the return value is not less than line_size, it means
##          that the log message was truncated to fit the buffer.
##

#proc av_log_format_line2*(ptr: pointer; level: cint; fmt: cstring; vl: va_list;
#                         line: cstring; line_size: cint; print_prefix: ptr cint): cint
## *
##  Skip repeated messages, this requires the user app to use av_log() instead of
##  (f)printf as the 2 would otherwise interfere and lead to
##  "Last message repeated x times" messages below (f)printf messages with some
##  bad luck.
##  Also to receive the last, "last repeated" line if any, the user app must
##  call av_log(NULL, AV_LOG_QUIET, "%s", ""); at the end
##

const
  AV_LOG_SKIP_REPEATED* = 1

## *
##  Include the log severity in messages originating from codecs.
##
##  Results in messages such as:
##  [rawvideo @ 0xDEADBEEF] [error] encode did not produce valid pts
##

const
  AV_LOG_PRINT_LEVEL* = 2

proc av_log_set_flags*(arg: cint){.rtl.}
proc av_log_get_flags*(): cint {.rtl.}
## *
##  @}
##
