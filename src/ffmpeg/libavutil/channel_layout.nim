##
##  Copyright (c) 2006 Michael Niedermayer <michaelni@gmx.at>
##  Copyright (c) 2008 Peter Ross
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
##  audio channel layout utility functions
##
## *
##  @addtogroup lavu_audio
##  @{
##
## *
##  @defgroup channel_masks Audio channel masks
##
##  A channel layout is a 64-bits integer with a bit set for every channel.
##  The number of bits set must be equal to the number of channels.
##  The value 0 means that the channel layout is not known.
##  @note this data structure is not powerful enough to handle channels
##  combinations that have the same channel multiple times, such as
##  dual-mono.
##
##  @{
##

const
  AV_CH_FRONT_LEFT* = 0x00000001
  AV_CH_FRONT_RIGHT* = 0x00000002
  AV_CH_FRONT_CENTER* = 0x00000004
  AV_CH_LOW_FREQUENCY* = 0x00000008
  AV_CH_BACK_LEFT* = 0x00000010
  AV_CH_BACK_RIGHT* = 0x00000020
  AV_CH_FRONT_LEFT_OF_CENTER* = 0x00000040
  AV_CH_FRONT_RIGHT_OF_CENTER* = 0x00000080
  AV_CH_BACK_CENTER* = 0x00000100
  AV_CH_SIDE_LEFT* = 0x00000200
  AV_CH_SIDE_RIGHT* = 0x00000400
  AV_CH_TOP_CENTER* = 0x00000800
  AV_CH_TOP_FRONT_LEFT* = 0x00001000
  AV_CH_TOP_FRONT_CENTER* = 0x00002000
  AV_CH_TOP_FRONT_RIGHT* = 0x00004000
  AV_CH_TOP_BACK_LEFT* = 0x00008000
  AV_CH_TOP_BACK_CENTER* = 0x00010000
  AV_CH_TOP_BACK_RIGHT* = 0x00020000
  AV_CH_STEREO_LEFT* = 0x20000000
  AV_CH_STEREO_RIGHT* = 0x40000000
  AV_CH_WIDE_LEFT* = 0x0000000000000000'i64
  AV_CH_WIDE_RIGHT* = 0x0000000000000000'i64
  AV_CH_SURROUND_DIRECT_LEFT* = 0x0000000000000000'i64
  AV_CH_SURROUND_DIRECT_RIGHT* = 0x0000000000000000'i64
  AV_CH_LOW_FREQUENCY_2* = 0x0000000000000000'i64

## * Channel mask value used for AVCodecContext.request_channel_layout
##     to indicate that the user requests the channel order of the decoder output
##     to be the native codec channel order.

const
  AV_CH_LAYOUT_NATIVE* = 0x0000000000000000'i64

## *
##  @}
##  @defgroup channel_mask_c Audio channel layouts
##  @{
##

const
  AV_CH_LAYOUT_MONO* = (AV_CH_FRONT_CENTER)
  AV_CH_LAYOUT_STEREO* = (AV_CH_FRONT_LEFT or AV_CH_FRONT_RIGHT)
  AV_CH_LAYOUT_2POINT1* = (AV_CH_LAYOUT_STEREO or AV_CH_LOW_FREQUENCY)
  AV_CH_LAYOUT_2_1* = (AV_CH_LAYOUT_STEREO or AV_CH_BACK_CENTER)
  AV_CH_LAYOUT_SURROUND* = (AV_CH_LAYOUT_STEREO or AV_CH_FRONT_CENTER)
  AV_CH_LAYOUT_3POINT1* = (AV_CH_LAYOUT_SURROUND or AV_CH_LOW_FREQUENCY)
  AV_CH_LAYOUT_4POINT0* = (AV_CH_LAYOUT_SURROUND or AV_CH_BACK_CENTER)
  AV_CH_LAYOUT_4POINT1* = (AV_CH_LAYOUT_4POINT0 or AV_CH_LOW_FREQUENCY)
  AV_CH_LAYOUT_2_2* = (AV_CH_LAYOUT_STEREO or AV_CH_SIDE_LEFT or AV_CH_SIDE_RIGHT)
  AV_CH_LAYOUT_QUAD* = (AV_CH_LAYOUT_STEREO or AV_CH_BACK_LEFT or AV_CH_BACK_RIGHT)
  AV_CH_LAYOUT_5POINT0* = (
    AV_CH_LAYOUT_SURROUND or AV_CH_SIDE_LEFT or AV_CH_SIDE_RIGHT)
  AV_CH_LAYOUT_5POINT1* = (AV_CH_LAYOUT_5POINT0 or AV_CH_LOW_FREQUENCY)
  AV_CH_LAYOUT_5POINT0_BACK* = (
    AV_CH_LAYOUT_SURROUND or AV_CH_BACK_LEFT or AV_CH_BACK_RIGHT)
  AV_CH_LAYOUT_5POINT1_BACK* = (AV_CH_LAYOUT_5POINT0_BACK or AV_CH_LOW_FREQUENCY)
  AV_CH_LAYOUT_6POINT0* = (AV_CH_LAYOUT_5POINT0 or AV_CH_BACK_CENTER)
  AV_CH_LAYOUT_6POINT0_FRONT* = (AV_CH_LAYOUT_2_2 or AV_CH_FRONT_LEFT_OF_CENTER or
      AV_CH_FRONT_RIGHT_OF_CENTER)
  AV_CH_LAYOUT_HEXAGONAL* = (AV_CH_LAYOUT_5POINT0_BACK or AV_CH_BACK_CENTER)
  AV_CH_LAYOUT_6POINT1* = (AV_CH_LAYOUT_5POINT1 or AV_CH_BACK_CENTER)
  AV_CH_LAYOUT_6POINT1_BACK* = (AV_CH_LAYOUT_5POINT1_BACK or AV_CH_BACK_CENTER)
  AV_CH_LAYOUT_6POINT1_FRONT* = (AV_CH_LAYOUT_6POINT0_FRONT or
      AV_CH_LOW_FREQUENCY)
  AV_CH_LAYOUT_7POINT0* = (
    AV_CH_LAYOUT_5POINT0 or AV_CH_BACK_LEFT or AV_CH_BACK_RIGHT)
  AV_CH_LAYOUT_7POINT0_FRONT* = (AV_CH_LAYOUT_5POINT0 or
      AV_CH_FRONT_LEFT_OF_CENTER or AV_CH_FRONT_RIGHT_OF_CENTER)
  AV_CH_LAYOUT_7POINT1* = (
    AV_CH_LAYOUT_5POINT1 or AV_CH_BACK_LEFT or AV_CH_BACK_RIGHT)
  AV_CH_LAYOUT_7POINT1_WIDE* = (AV_CH_LAYOUT_5POINT1 or
      AV_CH_FRONT_LEFT_OF_CENTER or AV_CH_FRONT_RIGHT_OF_CENTER)
  AV_CH_LAYOUT_7POINT1_WIDE_BACK* = (AV_CH_LAYOUT_5POINT1_BACK or
      AV_CH_FRONT_LEFT_OF_CENTER or AV_CH_FRONT_RIGHT_OF_CENTER)
  AV_CH_LAYOUT_OCTAGONAL* = (AV_CH_LAYOUT_5POINT0 or AV_CH_BACK_LEFT or
      AV_CH_BACK_CENTER or AV_CH_BACK_RIGHT)
  AV_CH_LAYOUT_HEXADECAGONAL* = (AV_CH_LAYOUT_OCTAGONAL or AV_CH_WIDE_LEFT or
      AV_CH_WIDE_RIGHT or AV_CH_TOP_BACK_LEFT or AV_CH_TOP_BACK_RIGHT or
      AV_CH_TOP_BACK_CENTER or AV_CH_TOP_FRONT_CENTER or AV_CH_TOP_FRONT_LEFT or
      AV_CH_TOP_FRONT_RIGHT)
  AV_CH_LAYOUT_STEREO_DOWNMIX* = (AV_CH_STEREO_LEFT or AV_CH_STEREO_RIGHT)

type
  AVMatrixEncoding* {.importc: "enum $1", header: "<libavutil/channel_layout.h>".} = enum
    AV_MATRIX_ENCODING_NONE, AV_MATRIX_ENCODING_DOLBY, AV_MATRIX_ENCODING_DPLII,
    AV_MATRIX_ENCODING_DPLIIX, AV_MATRIX_ENCODING_DPLIIZ,
    AV_MATRIX_ENCODING_DOLBYEX, AV_MATRIX_ENCODING_DOLBYHEADPHONE,
    AV_MATRIX_ENCODING_NB


when defined(windows):
  {.push importc, dynlib: "avutil(|-55|-56|-57).dll".}
elif defined(macosx):
  {.push importc, dynlib: "avutil(|.55|.56|.57).dylib".}
else:
  {.push importc, dynlib: "avutil.so(|.55|.56|.57)".}


## *
##  Return a channel layout id that matches name, or 0 if no match is found.
##
##  name can be one or several of the following notations,
##  separated by '+' or '|':
##  - the name of an usual channel layout (mono, stereo, 4.0, quad, 5.0,
##    5.0(side), 5.1, 5.1(side), 7.1, 7.1(wide), downmix);
##  - the name of a single channel (FL, FR, FC, LFE, BL, BR, FLC, FRC, BC,
##    SL, SR, TC, TFL, TFC, TFR, TBL, TBC, TBR, DL, DR);
##  - a number of channels, in decimal, followed by 'c', yielding
##    the default channel layout for that number of channels (@see
##    av_get_default_channel_layout);
##  - a channel layout mask, in hexadecimal starting with "0x" (see the
##    AV_CH_* macros).
##
##  Example: "stereo+FC" = "2c+FC" = "2c+1c" = "0x7"
##

proc av_get_channel_layout*(name: cstring): uint64
## *
##  Return a channel layout and the number of channels based on the specified name.
##
##  This function is similar to (@see av_get_channel_layout), but can also parse
##  unknown channel layout specifications.
##
##  @param[in]  name             channel layout specification string
##  @param[out] channel_layout   parsed channel layout (0 if unknown)
##  @param[out] nb_channels      number of channels
##
##  @return 0 on success, AVERROR(EINVAL) if the parsing fails.
##

proc av_get_extended_channel_layout*(name: cstring; channel_layout: ptr uint64;
                                    nb_channels: ptr cint): cint
## *
##  Return a description of a channel layout.
##  If nb_channels is <= 0, it is guessed from the channel_layout.
##
##  @param buf put here the string containing the channel layout
##  @param buf_size size in bytes of the buffer
##

proc av_get_channel_layout_string*(buf: cstring; buf_size: cint; nb_channels: cint;
                                  channel_layout: uint64)
type
  AVBPrint* {.bycopy.} = object


## *
##  Append a description of a channel layout to a bprint buffer.
##

proc av_bprint_channel_layout*(bp: ptr AVBPrint; nb_channels: cint;
                              channel_layout: uint64)
## *
##  Return the number of channels in the channel layout.
##

proc av_get_channel_layout_nb_channels*(channel_layout: uint64): cint
## *
##  Return default channel layout for a given number of channels.
##

proc av_get_default_channel_layout*(nb_channels: cint): int64
## *
##  Get the index of a channel in channel_layout.
##
##  @param channel a channel layout describing exactly one channel which must be
##                 present in channel_layout.
##
##  @return index of channel in channel_layout on success, a negative AVERROR
##          on error.
##

proc av_get_channel_layout_channel_index*(channel_layout: uint64;
    channel: uint64): cint
## *
##  Get the channel with the given index in channel_layout.
##

proc av_channel_layout_extract_channel*(channel_layout: uint64; index: cint): uint64
## *
##  Get the name of a given channel.
##
##  @return channel name on success, NULL on error.
##

proc av_get_channel_name*(channel: uint64): cstring
## *
##  Get the description of a given channel.
##
##  @param channel  a channel layout with a single channel
##  @return  channel description on success, NULL on error
##

proc av_get_channel_description*(channel: uint64): cstring
## *
##  Get the value and name of a standard channel layout.
##
##  @param[in]  index   index in an internal list, starting at 0
##  @param[out] layout  channel layout mask
##  @param[out] name    name of the layout
##  @return  0  if the layout exists,
##           <0 if index is beyond the limits
##

proc av_get_standard_channel_layout*(index: cuint; layout: ptr uint64;
                                    name: cstringArray): cint
## *
##  @}
##  @}
##
