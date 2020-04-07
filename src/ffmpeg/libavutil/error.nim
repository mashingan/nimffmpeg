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
##  error code definitions
##

## *
##  @addtogroup lavu_error
##
##  @{
##
##  error handling
import common

when defined(windows):
  {.push importc, dynlib: "avutil-(|55|56|57).dll".}
elif defined(macosx):
  {.push importc, dynlib: "avutil(|.55|.56|.57).dylib".}
else:
  {.push importc, dynlib: "libavutil.so(|.55|.56|.57)".}

#when EDOM > 0:
when false:
  template AVERROR*(e: untyped): untyped =
    (-(e))                    ## /< Returns a negative error code from a POSIX error code, to return from library functions.

  template AVUNERROR*(e: untyped): untyped =
    (-(e))                    ## /< Returns a POSIX error code from a library function error return value.

else:
  ##  Some platforms have E* and errno already negated.
  template AVERROR*(e: untyped): untyped =
    (e)

  template AVUNERROR*(e: untyped): untyped =
    (e)

template FFERRTAG*(a, b, c, d: untyped): untyped =
  (-cast[cint](MKTAG(a, b, c, d)))

const
  AVERROR_BSF_NOT_FOUND* = FFERRTAG(0x000000F8, 'B', 'S', 'F') ## /< Bitstream filter not found
  AVERROR_BUG* = FFERRTAG('B', 'U', 'G', '!') ## /< Internal bug, also see AVERROR_BUG2
  AVERROR_BUFFER_TOO_SMALL* = FFERRTAG('B', 'U', 'F', 'S') ## /< Buffer too small
  AVERROR_DECODER_NOT_FOUND* = FFERRTAG(0x000000F8, 'D', 'E', 'C') ## /< Decoder not found
  AVERROR_DEMUXER_NOT_FOUND* = FFERRTAG(0x000000F8, 'D', 'E', 'M') ## /< Demuxer not found
  AVERROR_ENCODER_NOT_FOUND* = FFERRTAG(0x000000F8, 'E', 'N', 'C') ## /< Encoder not found
  AVERROR_EOF* = FFERRTAG('E', 'O', 'F', ' ') ## /< End of file
  AVERROR_EXIT* = FFERRTAG('E', 'X', 'I', 'T') ## /< Immediate exit was requested; the called function should not be restarted
  AVERROR_EXTERNAL* = FFERRTAG('E', 'X', 'T', ' ') ## /< Generic error in an external library
  AVERROR_FILTER_NOT_FOUND* = FFERRTAG(0x000000F8, 'F', 'I', 'L') ## /< Filter not found
  AVERROR_INVALIDDATA* = FFERRTAG('I', 'N', 'D', 'A') ## /< Invalid data found when processing input
  AVERROR_MUXER_NOT_FOUND* = FFERRTAG(0x000000F8, 'M', 'U', 'X') ## /< Muxer not found
  AVERROR_OPTION_NOT_FOUND* = FFERRTAG(0x000000F8, 'O', 'P', 'T') ## /< Option not found
  AVERROR_PATCHWELCOME* = FFERRTAG('P', 'A', 'W', 'E') ## /< Not yet implemented in FFmpeg, patches welcome
  AVERROR_PROTOCOL_NOT_FOUND* = FFERRTAG(0x000000F8, 'P', 'R', 'O') ## /< Protocol not found
  AVERROR_STREAM_NOT_FOUND* = FFERRTAG(0x000000F8, 'S', 'T', 'R') ## /< Stream not found
                                                            ## *
                                                            ##  This is semantically identical to AVERROR_BUG
                                                            ##  it has been introduced in Libav after our AVERROR_BUG and with a modified value.
                                                            ##
  AVERROR_BUG2* = FFERRTAG('B', 'U', 'G', ' ')
  AVERROR_UNKNOWN* = FFERRTAG('U', 'N', 'K', 'N') ## /< Unknown error, typically from an external library
  AVERROR_EXPERIMENTAL* = (-0x2BB2AFA8) ## /< Requested feature is flagged experimental. Set strict_std_compliance if you really want to use it.
  AVERROR_INPUT_CHANGED* = (-0x636E6701) ## /< Input changed between calls. Reconfiguration is required. (can be OR-ed with AVERROR_OUTPUT_CHANGED)
  AVERROR_OUTPUT_CHANGED* = (-0x636E6702) ## /< Output changed between calls. Reconfiguration is required. (can be OR-ed with AVERROR_INPUT_CHANGED)
                                       ##  HTTP & RTSP errors
  AVERROR_HTTP_BAD_REQUEST* = FFERRTAG(0x000000F8, '4', '0', '0')
  AVERROR_HTTP_UNAUTHORIZED* = FFERRTAG(0x000000F8, '4', '0', '1')
  AVERROR_HTTP_FORBIDDEN* = FFERRTAG(0x000000F8, '4', '0', '3')
  AVERROR_HTTP_NOT_FOUND* = FFERRTAG(0x000000F8, '4', '0', '4')
  AVERROR_HTTP_OTHER_4XX* = FFERRTAG(0x000000F8, '4', 'X', 'X')
  AVERROR_HTTP_SERVER_ERROR* = FFERRTAG(0x000000F8, '5', 'X', 'X')
  AV_ERROR_MAX_STRING_SIZE* = 64

## *
##  Put a description of the AVERROR code errnum in errbuf.
##  In case of failure the global variable errno is set to indicate the
##  error. Even in case of failure av_strerror() will print a generic
##  error message indicating the errnum provided to errbuf.
##
##  @param errnum      error code to describe
##  @param errbuf      buffer to which description is written
##  @param errbuf_size the size in bytes of errbuf
##  @return 0 on success, a negative value if a description for errnum
##  cannot be found
##

proc av_strerror*(errnum: cint; errbuf: cstring; errbuf_size: csize): cint
## *
##  Fill the provided buffer with a string containing an error string
##  corresponding to the AVERROR code errnum.
##
##  @param errbuf         a buffer
##  @param errbuf_size    size in bytes of errbuf
##  @param errnum         error code to describe
##  @return the buffer in input, filled with the error description
##  @see av_strerror()
##

proc av_make_error_string*(errbuf: var cstring; errbuf_size: csize; errnum: cint): cstring {.
    inline.} =
  discard av_strerror(errnum, errbuf, errbuf_size)
  return errbuf

## *
##  Convenience macro, the return value should be used only directly in
##  function arguments but never stand-alone.
##
## #define av_err2str(errnum) \
##     av_make_error_string((char[AV_ERROR_MAX_STRING_SIZE]){0}, AV_ERROR_MAX_STRING_SIZE, errnum)
## *
##  @}
##
