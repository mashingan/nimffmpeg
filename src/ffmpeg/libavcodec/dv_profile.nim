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

import ../libavutil/pixfmt
import ../libavutil/rational

##  minimum number of bytes to read from a DV stream in order to
##  determine the profile

const
  DV_PROFILE_BYTES* = (6 * 80)    ##  6 DIF blocks

##
##  AVDVProfile is used to express the differences between various
##  DV flavors. For now it's primarily used for differentiating
##  525/60 and 625/50, but the plans are to use it for various
##  DV specs as well (e.g. SMPTE314M vs. IEC 61834).
##

type
  AVDVProfile* {.importc, header: "<libavformat/dv_profile.>".} = object
    dsf*: cint                 ##  value of the dsf in the DV header
    video_stype*: cint         ##  stype for VAUX source pack
    frame_size*: cint          ##  total size of one frame in bytes
    difseg_size*: cint         ##  number of DIF segments per DIF channel
    n_difchan*: cint           ##  number of DIF channels per frame
    time_base*: AVRational     ##  1/framerate
    ltc_divisor*: cint         ##  FPS from the LTS standpoint
    height*: cint              ##  picture height in pixels
    width*: cint               ##  picture width in pixels
    sar*: array[2, AVRational]  ##  sample aspect ratios for 4:3 and 16:9
    pix_fmt*: AVPixelFormat    ##  picture pixel format
    bpm*: cint                 ##  blocks per macroblock
    block_sizes*: ptr uint8   ##  AC block sizes, in bits
    audio_stride*: cint        ##  size of audio_shuffle table
    audio_min_samples*: array[3, cint] ##  min amount of audio samples
                                    ##  for 48kHz, 44.1kHz and 32kHz
    audio_samples_dist*: array[5, cint] ##  how many samples are supposed to be
                                     ##  in each frame in a 5 frames window
    audio_shuffle*: array[9, uint8] ##  PCM shuffling table


when defined(windows):
  {.push importc, dynlib: "avcodec(|-55|-56|-57|-58|-59).dll".}
elif defined(macosx):
  {.push importc, dynlib: "avcodec(|.55|.56|.57|.58|.59).dylib".}
else:
  {.push importc, dynlib: "avcodec.so(|.55|.56|.57|.58|.59)".}

## *
##  Get a DV profile for the provided compressed frame.
##
##  @param sys the profile used for the previous frame, may be NULL
##  @param frame the compressed data buffer
##  @param buf_size size of the buffer in bytes
##  @return the DV profile for the supplied data or NULL on failure
##

proc av_dv_frame_profile*(sys: ptr AVDVProfile; frame: ptr uint8; buf_size: cuint): ptr AVDVProfile
## *
##  Get a DV profile for the provided stream parameters.
##

proc av_dv_codec_profile*(width: cint; height: cint; pix_fmt: AVPixelFormat): ptr AVDVProfile
## *
##  Get a DV profile for the provided stream parameters.
##  The frame rate is used as a best-effort parameter.
##

proc av_dv_codec_profile2*(width: cint; height: cint; pix_fmt: AVPixelFormat;
                          frame_rate: AVRational): ptr AVDVProfile