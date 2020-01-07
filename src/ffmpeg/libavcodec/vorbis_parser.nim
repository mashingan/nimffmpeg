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
##  A public API for Vorbis parsing
##
##  Determines the duration for each packet.
##


## *
##  Allocate and initialize the Vorbis parser using headers in the extradata.
##

const
  VORBIS_FLAG_HEADER* = 0x00000001
  VORBIS_FLAG_COMMENT* = 0x00000002
  VORBIS_FLAG_SETUP* = 0x00000004

type
  AVVorbisParseContext* {.importc, header: "<libavcodec/vorbis_parser.h>".} = object

when defined(windows):
  {.push importc, dynlib: "avcodec(|-55|-56|-57|-58|-59).dll".}
elif defined(macosx):
  {.push importc, dynlib: "avcodec(|.55|.56|.57|.58|.59).dylib".}
else:
  {.push importc, dynlib: "libavcodec.so(|.55|.56|.57|.58|.59)".}

proc av_vorbis_parse_init*(extradata: ptr uint8; extradata_size: cint): ptr AVVorbisParseContext
## *
##  Free the parser and everything associated with it.
##

proc av_vorbis_parse_free*(s: ptr ptr AVVorbisParseContext)

## *
##  Get the duration for a Vorbis packet.
##
##  If @p flags is @c NULL,
##  special frames are considered invalid.
##
##  @param s        Vorbis parser context
##  @param buf      buffer containing a Vorbis frame
##  @param buf_size size of the buffer
##  @param flags    flags for special frames
##

proc av_vorbis_parse_frame_flags*(s: ptr AVVorbisParseContext; buf: ptr uint8;
                                 buf_size: cint; flags: ptr cint): cint
## *
##  Get the duration for a Vorbis packet.
##
##  @param s        Vorbis parser context
##  @param buf      buffer containing a Vorbis frame
##  @param buf_size size of the buffer
##

proc av_vorbis_parse_frame*(s: ptr AVVorbisParseContext; buf: ptr uint8;
                           buf_size: cint): cint
proc av_vorbis_parse_reset*(s: ptr AVVorbisParseContext)