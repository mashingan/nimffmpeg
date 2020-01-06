##
##  Video Acceleration API (shared data between FFmpeg and the video player)
##  HW decode acceleration for MPEG-2, MPEG-4, H.264 and VC-1
##
##  Copyright (C) 2008-2009 Splitted-Desktop Systems
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
##  @ingroup lavc_codec_hwaccel_vaapi
##  Public libavcodec VA API header.
##

import version

when FF_API_STRUCT_VAAPI_CONTEXT:
  ## *
  ##  @defgroup lavc_codec_hwaccel_vaapi VA API Decoding
  ##  @ingroup lavc_codec_hwaccel
  ##  @{
  ##
  ## *
  ##  This structure is used to share data between the FFmpeg library and
  ##  the client video application.
  ##  This shall be zero-allocated and available as
  ##  AVCodecContext.hwaccel_context. All user members can be set once
  ##  during initialization or through each AVCodecContext.get_buffer()
  ##  function call. In any case, they must be valid prior to calling
  ##  decoding functions.
  ##
  ##  Deprecated: use AVCodecContext.hw_frames_ctx instead.
  ##
  ## struct attribute_deprecated vaapi_context {
  type
    vaapi_context* {.importc, header: "<libavcodec/vaapi.h>".} = object
      display*: pointer        ## *
                      ##  Window system dependent data
                      ##
                      ##  - encoding: unused
                      ##  - decoding: Set by user
                      ##
      ## *
      ##  Configuration ID
      ##
      ##  - encoding: unused
      ##  - decoding: Set by user
      ##
      config_id*: uint32     ## *
                         ##  Context ID (video decode pipeline)
                         ##
                         ##  - encoding: unused
                         ##  - decoding: Set by user
                         ##
      context_id*: uint32

  ##  @}