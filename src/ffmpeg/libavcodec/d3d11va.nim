##
##  Direct3D11 HW acceleration
##
##  copyright (c) 2009 Laurent Aimar
##  copyright (c) 2015 Steve Lhomme
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
##  @ingroup lavc_codec_hwaccel_d3d11va
##  Public libavcodec D3D11VA header.
##

when defined(windows):
  import winlean
  {.pragma: d3d11, importc, header: "<d3d11.h>".}

when not defined(WIN32_WINNT):# or WIN32_WINNT < 0x00000602:
  const
    WIN32_WINNT* = 0x00000602
## *
##  @defgroup lavc_codec_hwaccel_d3d11va Direct3D11
##  @ingroup lavc_codec_hwaccel
##
##  @{
##

const
  FF_DXVA2_WORKAROUND_SCALING_LIST_ZIGZAG* = 1
  FF_DXVA2_WORKAROUND_INTEL_CLEARVIDEO* = 2

## *
##  This structure is used to provides the necessary configurations and data
##  to the Direct3D11 FFmpeg HWAccel implementation.
##
##  The application must make it available as AVCodecContext.hwaccel_context.
##
##  Use av_d3d11va_alloc_context() exclusively to allocate an AVD3D11VAContext.
##

type
  ID3D11VideoContext* {.d3d11.} = object
  ID3D11VideoDecoder* {.d3d11.} = object
  D3D11_VIDEO_DECODER_CONFIG* {.d3d11.} = object
  ID3D11VideoDecoderOutputView* {.d3d11.} = object

type
  AVD3D11VAContext* {.bycopy.} = object
    decoder*: ptr ID3D11VideoDecoder ## *
                                  ##  D3D11 decoder object
                                  ##
    ## *
    ##  D3D11 VideoContext
    ##
    video_context*: ptr ID3D11VideoContext ## *
                                        ##  D3D11 configuration used to create the decoder
                                        ##
    cfg*: ptr D3D11_VIDEO_DECODER_CONFIG ## *
                                      ##  The number of surface in the surface array
                                      ##
    surface_count*: cuint ## *
                        ##  The array of Direct3D surfaces used to create the decoder
                        ##
    surface*: ptr ptr ID3D11VideoDecoderOutputView ## *
                                               ##  A bit field configuring the workarounds needed for using the decoder
                                               ##
    workaround*: uint64      ## *
                        ##  Private to the FFmpeg AVHWAccel implementation
                        ##
    report_id*: cuint          ## *
                    ##  Mutex to access video_context
                    ##
    context_mutex*: HANDLE


## *
##  Allocate an AVD3D11VAContext.
##
##  @return Newly-allocated AVD3D11VAContext or NULL on failure.
##

proc av_d3d11va_alloc_context*(): ptr AVD3D11VAContext
  {.importc, dynlib: "d3d11.dll".}
## *
##  @}
##
