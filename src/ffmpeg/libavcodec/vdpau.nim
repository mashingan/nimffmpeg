##
##  The Video Decode and Presentation API for UNIX (VDPAU) is used for
##  hardware-accelerated decoding of MPEG-1/2, H.264 and VC-1.
##
##  Copyright (C) 2008 NVIDIA
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
##  @ingroup lavc_codec_hwaccel_vdpau
##  Public libavcodec VDPAU header.
##
## *
##  @defgroup lavc_codec_hwaccel_vdpau VDPAU Decoder and Renderer
##  @ingroup lavc_codec_hwaccel
##
##  VDPAU hardware acceleration has two modules
##  - VDPAU decoding
##  - VDPAU presentation
##
##  The VDPAU decoding module parses all headers using FFmpeg
##  parsing mechanisms and uses VDPAU for the actual decoding.
##
##  As per the current implementation, the actual decoding
##  and rendering (API calls) are done as part of the VDPAU
##  presentation (vo_vdpau.c) module.
##
##  @{
##

import
  ../utiltypes,
  version

type
  AVVDPAU_Render2* = proc (a1: ptr AVCodecContext; a2: ptr AVFrame;
                        a3: ptr VdpPictureInfo; a4: uint32;
                        a5: ptr VdpBitstreamBuffer): cint

## *
##  This structure is used to share data between the libavcodec library and
##  the client video application.
##  The user shall allocate the structure via the av_alloc_vdpau_hwaccel
##  function and make it available as
##  AVCodecContext.hwaccel_context. Members can be set by the user once
##  during initialization or through each AVCodecContext.get_buffer()
##  function call. In any case, they must be valid prior to calling
##  decoding functions.
##
##  The size of this structure is not a part of the public ABI and must not
##  be used outside of libavcodec. Use av_vdpau_alloc_context() to allocate an
##  AVVDPAUContext.
##

{.pragma: vdpau, header: "<libavcodec/vdpau.h>".}

type
  VdpDecoder* {.importc: "struct $1", vdpau.} = object
  VdpDecoderRender* {.importc: "struct $1", vdpau.} = object
  AVVDPAUContext* {.importc, vdpau.} = object
    decoder*: VdpDecoder       ## *
                       ##  VDPAU decoder handle
                       ##
                       ##  Set by user.
                       ##
    ## *
    ##  VDPAU decoder render callback
    ##
    ##  Set by the user.
    ##
    render*: ptr VdpDecoderRender
    render2*: AVVDPAU_Render2


when defined(windows):
  {.push importc, dynlib: "avcodec(|-55|-56|-57|-58|-59).dll".}
elif defined(macosx):avcodec
  {.push importc, dynlib: "avcodec(|.55|.56|.57|.58|.59).dylib".}
else:avcodec
  {.push importc, dynlib: "avcodec.so(|.55|.56|.57|.58|.59)".}

## *
##  @brief allocation function for AVVDPAUContext
##
##  Allows extending the struct without breaking API/ABI
##

proc av_alloc_vdpaucontext*(): ptr AVVDPAUContext
proc av_vdpau_hwaccel_get_render2*(a1: ptr AVVDPAUContext): AVVDPAU_Render2
proc av_vdpau_hwaccel_set_render2*(a1: ptr AVVDPAUContext; a2: AVVDPAU_Render2)
## *
##  Associate a VDPAU device with a codec context for hardware acceleration.
##  This function is meant to be called from the get_format() codec callback,
##  or earlier. It can also be called after avcodec_flush_buffers() to change
##  the underlying VDPAU device mid-stream (e.g. to recover from non-transparent
##  display preemption).
##
##  @note get_format() must return AV_PIX_FMT_VDPAU if this function completes
##  successfully.
##
##  @param avctx decoding context whose get_format() callback is invoked
##  @param device VDPAU device handle to use for hardware acceleration
##  @param get_proc_address VDPAU device driver
##  @param flags zero of more OR'd AV_HWACCEL_FLAG_* flags
##
##  @return 0 on success, an AVERROR code on failure.
##

proc av_vdpau_bind_context*(avctx: ptr AVCodecContext; device: VdpDevice;
                           get_proc_address: ptr VdpGetProcAddress; flags: cuint): cint
## *
##  Gets the parameters to create an adequate VDPAU video surface for the codec
##  context using VDPAU hardware decoding acceleration.
##
##  @note Behavior is undefined if the context was not successfully bound to a
##  VDPAU device using av_vdpau_bind_context().
##
##  @param avctx the codec context being used for decoding the stream
##  @param type storage space for the VDPAU video surface chroma type
##               (or NULL to ignore)
##  @param width storage space for the VDPAU video surface pixel width
##               (or NULL to ignore)
##  @param height storage space for the VDPAU video surface pixel height
##               (or NULL to ignore)
##
##  @return 0 on success, a negative AVERROR code on failure.
##

proc av_vdpau_get_surface_parameters*(avctx: ptr AVCodecContext;
                                     `type`: ptr VdpChromaType; width: ptr uint32;
                                     height: ptr uint32): cint
## *
##  Allocate an AVVDPAUContext.
##
##  @return Newly-allocated AVVDPAUContext or NULL on failure.
##

proc av_vdpau_alloc_context*(): ptr AVVDPAUContext
when FF_API_VDPAU_PROFILE:
  ## *
  ##  Get a decoder profile that should be used for initializing a VDPAU decoder.
  ##  Should be called from the AVCodecContext.get_format() callback.
  ##
  ##  @deprecated Use av_vdpau_bind_context() instead.
  ##
  ##  @param avctx the codec context being used for decoding the stream
  ##  @param profile a pointer into which the result will be written on success.
  ##                 The contents of profile are undefined if this function returns
  ##                 an error.
  ##
  ##  @return 0 on success (non-negative), a negative AVERROR on failure.
  ##
  ## attribute_deprecated
  proc av_vdpau_get_profile*(avctx: ptr AVCodecContext;
                            profile: ptr VdpDecoderProfile): cint
    {.deprecated: "Use av_vdpau_bind_context() instead.".}
##  @}
