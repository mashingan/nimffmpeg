##
##  DXVA2 HW acceleration
##
##  copyright (c) 2009 Laurent Aimar
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
##  @ingroup lavc_codec_hwaccel_dxva2
##  Public libavcodec DXVA2 header.
##

when defined(windows):
  {.pragma: dxva2, importc, header: "<dxva2api.h>".}

when not defined(WIN32_WINNT):
  const
    WIN32_WINNT* = 0x00000602
## *
##  @defgroup lavc_codec_hwaccel_dxva2 DXVA2
##  @ingroup lavc_codec_hwaccel
##
##  @{
##

const
  FF_DXVA2_WORKAROUND_SCALING_LIST_ZIGZAG* = 1
  FF_DXVA2_WORKAROUND_INTEL_CLEARVIDEO* = 2

## *
##  This structure is used to provides the necessary configurations and data
##  to the DXVA2 FFmpeg HWAccel implementation.
##
##  The application must make it available as AVCodecContext.hwaccel_context.
##

type
  IDirectXVideoDecoder* {.dxva2.} = object
  DXVA2_ConfigPictureDecode* {.dxva2.} = object
  IDirect3DSurface9* {.importc, header: "<d3d9.h>".} = object
  LPDIRECT3DSURFACE9* = ptr IDirect3DSurface9

type
  dxva_context* {.importc, header: "<libavcodec/dxva2.h>".} = object
    decoder*: ptr IDirectXVideoDecoder ## *
                                    ##  DXVA2 decoder object
                                    ##
    ## *
    ##  DXVA2 configuration used to create the decoder
    ##
    cfg*: ptr DXVA2_ConfigPictureDecode ## *
                                     ##  The number of surface in the surface array
                                     ##
    surface_count*: cuint ## *
                        ##  The array of Direct3D surfaces used to create the decoder
                        ##
    surface*: ptr LPDIRECT3DSURFACE9 ## *
                                  ##  A bit field configuring the workarounds needed for using the decoder
                                  ##
    workaround*: uint64      ## *
                        ##  Private to the FFmpeg AVHWAccel implementation
                        ##
    report_id*: cuint


## *
##  @}
##
