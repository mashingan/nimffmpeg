##
##  Version macros.
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
##  @ingroup libavf
##  Libavformat version macros
##

import
  ../libavutil/version

##  Major bumping may affect Ticket5467, 5421, 5451(compatibility with Chromium)
##  Also please add any ticket numbers that you believe might be affected here

const
  LIBAVFORMAT_VERSION_MAJOR* = 58
  LIBAVFORMAT_VERSION_MINOR* = 35
  LIBAVFORMAT_VERSION_MICRO* = 101
  LIBAVFORMAT_VERSION_INT* = AV_VERSION_INT(LIBAVFORMAT_VERSION_MAJOR,
      LIBAVFORMAT_VERSION_MINOR, LIBAVFORMAT_VERSION_MICRO)
  #LIBAVFORMAT_VERSION* = AV_VERSION(LIBAVFORMAT_VERSION_MAJOR,
  #                                LIBAVFORMAT_VERSION_MINOR,
  #                                LIBAVFORMAT_VERSION_MICRO)
  LIBAVFORMAT_BUILD* = LIBAVFORMAT_VERSION_INT
  LIBAVFORMAT_IDENT* = "Lavf"

## #define LIBAVFORMAT_IDENT       "Lavf" AV_STRINGIFY(LIBAVFORMAT_VERSION)
## *
##  FF_API_* defines may be placed below to indicate public API that will be
##  dropped at a future version bump. The defines themselves are not part of
##  the public API and may change, break or disappear at any time.
##
##  @note, when bumping the major version it is recommended to manually
##  disable each FF_API_* in its own commit instead of disabling them all
##  at once through the bump. This improves the git bisect-ability of the change.
##
##

const
  FF_API_COMPUTE_PKT_FIELDS2*      = (LIBAVFORMAT_VERSION_MAJOR < 59)
  FF_API_OLD_OPEN_CALLBACKS*       = (LIBAVFORMAT_VERSION_MAJOR < 59)
  FF_API_LAVF_AVCTX*               = (LIBAVFORMAT_VERSION_MAJOR < 59)
  FF_API_HTTP_USER_AGENT*          = (LIBAVFORMAT_VERSION_MAJOR < 59)
  FF_API_HLS_WRAP*                 = (LIBAVFORMAT_VERSION_MAJOR < 59)
  FF_API_HLS_USE_LOCALTIME*        = (LIBAVFORMAT_VERSION_MAJOR < 59)
  FF_API_LAVF_KEEPSIDE_FLAG*       = (LIBAVFORMAT_VERSION_MAJOR < 59)
  FF_API_OLD_ROTATE_API*           = (LIBAVFORMAT_VERSION_MAJOR < 59)
  FF_API_FORMAT_GET_SET*           = (LIBAVFORMAT_VERSION_MAJOR < 59)
  FF_API_OLD_AVIO_EOF_0*           = (LIBAVFORMAT_VERSION_MAJOR < 59)
  FF_API_LAVF_FFSERVER*            = (LIBAVFORMAT_VERSION_MAJOR < 59)
  FF_API_FORMAT_FILENAME*          = (LIBAVFORMAT_VERSION_MAJOR < 59)
  FF_API_OLD_RTSP_OPTIONS*         = (LIBAVFORMAT_VERSION_MAJOR < 59)
  FF_API_NEXT*                     = (LIBAVFORMAT_VERSION_MAJOR < 59)
  FF_API_DASH_MIN_SEG_DURATION*    = (LIBAVFORMAT_VERSION_MAJOR < 59)
  FF_API_LAVF_MP4A_LATM*           = (LIBAVFORMAT_VERSION_MAJOR < 59)
  FF_API_AVIOFORMAT*               = (LIBAVFORMAT_VERSION_MAJOR < 59)

  FF_API_R_FRAME_RATE*             = 1