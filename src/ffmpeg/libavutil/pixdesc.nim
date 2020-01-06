##
##  pixel format descriptor
##  Copyright (c) 2009 Michael Niedermayer <michaelni@gmx.at>
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

import
  pixfmt, version


when defined(windows):
  {.push importc, dynlib: "avutil-(|55|56|57).dll".}
elif defined(macosx):
  {.push importc, dynlib: "avutil(|.55|.56|.57).dylib".}
else:
  {.push importc, dynlib: "avutil.so(|.55|.56|.57)".}

{.pragma: pixdesc, importc, header: "<libavutil/pixdesc.h".}


type
  AVComponentDescriptor*{.pixdesc.} = object
    plane*: cint               ## *
               ##  Which of the 4 planes contains the component.
               ##
    ## *
    ##  Number of elements between 2 horizontally consecutive pixels.
    ##  Elements are bits for bitstream formats, bytes otherwise.
    ##
    step*: cint ## *
              ##  Number of elements before the component of the first pixel.
              ##  Elements are bits for bitstream formats, bytes otherwise.
              ##
    offset*: cint ## *
                ##  Number of least significant bits that must be shifted away
                ##  to get the value.
                ##
    shift*: cint               ## *
               ##  Number of bits in the component.
               ##
    depth*: cint
    when FF_API_PLUS1_MINUS1:
      ## * deprecated, use step instead
      step_minus1*: cint
      ## * deprecated, use depth instead
      depth_minus1*: cint
      ## * deprecated, use offset instead
      offset_plus1*: cint


## *
##  Descriptor that unambiguously describes how the bits of a pixel are
##  stored in the up to 4 data planes of an image. It also stores the
##  subsampling factors and number of components.
##
##  @note This is separate of the colorspace (RGB, YCbCr, YPbPr, JPEG-style YUV
##        and all the YUV variants) AVPixFmtDescriptor just stores how values
##        are stored not what these values represent.
##

type
  AVPixFmtDescriptor*{.pixdesc.} = object
    name*: cstring
    nb_components*: uint8 ## /< The number of components each pixel has, (1-4)
                          ## *
                          ##  Amount to shift the luma width right to find the chroma width.
                          ##  For YV12 this is 1 for example.
                          ##  chroma_width = AV_CEIL_RSHIFT(luma_width, log2_chroma_w)
                          ##  The note above is needed to ensure rounding up.
                          ##  This value only refers to the chroma components.
                          ##
    log2_chroma_w*: uint8 ## *
                          ##  Amount to shift the luma height right to find the chroma height.
                          ##  For YV12 this is 1 for example.
                          ##  chroma_height= AV_CEIL_RSHIFT(luma_height, log2_chroma_h)
                          ##  The note above is needed to ensure rounding up.
                          ##  This value only refers to the chroma components.
                          ##
    log2_chroma_h*: uint8    ## *
                          ##  Combination of AV_PIX_FMT_FLAG_... flags.
                          ##
    flags*: uint64 ## *
                   ##  Parameters that describe how pixels are packed.
                   ##  If the format has 1 or 2 components, then luma is 0.
                   ##  If the format has 3 or 4 components:
                   ##    if the RGB flag is set then 0 is red, 1 is green and 2 is blue;
                   ##    otherwise 0 is luma, 1 is chroma-U and 2 is chroma-V.
                   ##
                   ##  If present, the Alpha channel is always the last component.
                   ##
    comp*: array[4, AVComponentDescriptor] ## *
                                        ##  Alternative comma-separated names.
                                        ##
    alias*: cstring


## *
##  Pixel format is big-endian.
##

const
  AV_PIX_FMT_FLAG_BE* = (1 shl 0)

## *
##  Pixel format has a palette in data[1], values are indexes in this palette.
##

const
  AV_PIX_FMT_FLAG_PAL* = (1 shl 1)

## *
##  All values of a component are bit-wise packed end to end.
##

const
  AV_PIX_FMT_FLAG_BITSTREAM* = (1 shl 2)

## *
##  Pixel format is an HW accelerated format.
##

const
  AV_PIX_FMT_FLAG_HWACCEL* = (1 shl 3)

## *
##  At least one pixel component is not in the first data plane.
##

const
  AV_PIX_FMT_FLAG_PLANAR* = (1 shl 4)

## *
##  The pixel format contains RGB-like data (as opposed to YUV/grayscale).
##

const
  AV_PIX_FMT_FLAG_RGB* = (1 shl 5)

## *
##  The pixel format is "pseudo-paletted". This means that it contains a
##  fixed palette in the 2nd plane but the palette is fixed/constant for each
##  PIX_FMT. This allows interpreting the data as if it was PAL8, which can
##  in some cases be simpler. Or the data can be interpreted purely based on
##  the pixel format without using the palette.
##  An example of a pseudo-paletted format is AV_PIX_FMT_GRAY8
##
##  @deprecated This flag is deprecated, and will be removed. When it is removed,
##  the extra palette allocation in AVFrame.data[1] is removed as well. Only
##  actual paletted formats (as indicated by AV_PIX_FMT_FLAG_PAL) will have a
##  palette. Starting with FFmpeg versions which have this flag deprecated, the
##  extra "pseudo" palette is already ignored, and API users are not required to
##  allocate a palette for AV_PIX_FMT_FLAG_PSEUDOPAL formats (it was required
##  before the deprecation, though).
##

const
  AV_PIX_FMT_FLAG_PSEUDOPAL* {.deprecated.} = (1 shl 6)

## *
##  The pixel format has an alpha channel. This is set on all formats that
##  support alpha in some way, including AV_PIX_FMT_PAL8. The alpha is always
##  straight, never pre-multiplied.
##
##  If a codec or a filter does not support alpha, it should set all alpha to
##  opaque, or use the equivalent pixel formats without alpha component, e.g.
##  AV_PIX_FMT_RGB0 (or AV_PIX_FMT_RGB24 etc.) instead of AV_PIX_FMT_RGBA.
##

const
  AV_PIX_FMT_FLAG_ALPHA* = (1 shl 7)

## *
##  The pixel format is following a Bayer pattern
##

const
  AV_PIX_FMT_FLAG_BAYER* = (1 shl 8)

## *
##  The pixel format contains IEEE-754 floating point values. Precision (double,
##  single, or half) should be determined by the pixel size (64, 32, or 16 bits).
##

const
  AV_PIX_FMT_FLAG_FLOAT* = (1 shl 9)

## *
##  Return the number of bits per pixel used by the pixel format
##  described by pixdesc. Note that this is not the same as the number
##  of bits per sample.
##
##  The returned number of bits refers to the number of bits actually
##  used for storing the pixel information, that is padding bits are
##  not counted.
##

proc av_get_bits_per_pixel*(pixdesc: ptr AVPixFmtDescriptor): cint
## *
##  Return the number of bits per pixel for the pixel format
##  described by pixdesc, including any padding or unused bits.
##

proc av_get_padded_bits_per_pixel*(pixdesc: ptr AVPixFmtDescriptor): cint
## *
##  @return a pixel format descriptor for provided pixel format or NULL if
##  this pixel format is unknown.
##

proc av_pix_fmt_desc_get*(pix_fmt: AVPixelFormat): ptr AVPixFmtDescriptor
## *
##  Iterate over all pixel format descriptors known to libavutil.
##
##  @param prev previous descriptor. NULL to get the first descriptor.
##
##  @return next descriptor or NULL after the last descriptor
##

proc av_pix_fmt_desc_next*(prev: ptr AVPixFmtDescriptor): ptr AVPixFmtDescriptor
## *
##  @return an AVPixelFormat id described by desc, or AV_PIX_FMT_NONE if desc
##  is not a valid pointer to a pixel format descriptor.
##

proc av_pix_fmt_desc_get_id*(desc: ptr AVPixFmtDescriptor): AVPixelFormat
## *
##  Utility function to access log2_chroma_w log2_chroma_h from
##  the pixel format AVPixFmtDescriptor.
##
##  @param[in]  pix_fmt the pixel format
##  @param[out] h_shift store log2_chroma_w (horizontal/width shift)
##  @param[out] v_shift store log2_chroma_h (vertical/height shift)
##
##  @return 0 on success, AVERROR(ENOSYS) on invalid or unknown pixel format
##

proc av_pix_fmt_get_chroma_sub_sample*(pix_fmt: AVPixelFormat; h_shift: ptr cint;
                                      v_shift: ptr cint): cint
## *
##  @return number of planes in pix_fmt, a negative AVERROR if pix_fmt is not a
##  valid pixel format.
##

proc av_pix_fmt_count_planes*(pix_fmt: AVPixelFormat): cint
## *
##  @return the name for provided color range or NULL if unknown.
##

proc av_color_range_name*(range: AVColorRange): cstring
## *
##  @return the AVColorRange value for name or an AVError if not found.
##

proc av_color_range_from_name*(name: cstring): cint
## *
##  @return the name for provided color primaries or NULL if unknown.
##

proc av_color_primaries_name*(primaries: AVColorPrimaries): cstring
## *
##  @return the AVColorPrimaries value for name or an AVError if not found.
##

proc av_color_primaries_from_name*(name: cstring): cint
## *
##  @return the name for provided color transfer or NULL if unknown.
##

proc av_colorransfer_name*(transfer: AVColorTransferCharacteristic): cstring
## *
##  @return the AVColorTransferCharacteristic value for name or an AVError if not found.
##

proc av_colorransfer_from_name*(name: cstring): cint
## *
##  @return the name for provided color space or NULL if unknown.
##

proc av_color_space_name*(space: AVColorSpace): cstring
## *
##  @return the AVColorSpace value for name or an AVError if not found.
##

proc av_color_space_from_name*(name: cstring): cint
## *
##  @return the name for provided chroma location or NULL if unknown.
##

proc av_chroma_location_name*(location: AVChromaLocation): cstring
## *
##  @return the AVChromaLocation value for name or an AVError if not found.
##

proc av_chroma_location_from_name*(name: cstring): cint
## *
##  Return the pixel format corresponding to name.
##
##  If there is no pixel format with name name, then looks for a
##  pixel format with the name corresponding to the native endian
##  format of name.
##  For example in a little-endian system, first looks for "gray16",
##  then for "gray16le".
##
##  Finally if no pixel format has been found, returns AV_PIX_FMT_NONE.
##

proc av_get_pix_fmt*(name: cstring): AVPixelFormat
## *
##  Return the short name for a pixel format, NULL in case pix_fmt is
##  unknown.
##
##  @see av_get_pix_fmt(), av_get_pix_fmt_string()
##

proc av_get_pix_fmt_name*(pix_fmt: AVPixelFormat): cstring
## *
##  Print in buf the string corresponding to the pixel format with
##  number pix_fmt, or a header if pix_fmt is negative.
##
##  @param buf the buffer where to write the string
##  @param buf_size the size of buf
##  @param pix_fmt the number of the pixel format to print the
##  corresponding info string, or a negative value to print the
##  corresponding header.
##

proc av_get_pix_fmt_string*(buf: cstring; buf_size: cint; pix_fmt: AVPixelFormat): cstring
## *
##  Read a line from an image, and write the values of the
##  pixel format component c to dst.
##
##  @param data the array containing the pointers to the planes of the image
##  @param linesize the array containing the linesizes of the image
##  @param desc the pixel format descriptor for the image
##  @param x the horizontal coordinate of the first pixel to read
##  @param y the vertical coordinate of the first pixel to read
##  @param w the width of the line to read, that is the number of
##  values to write to dst
##  @param read_pal_component if not zero and the format is a paletted
##  format writes the values corresponding to the palette
##  component c in data[1] to dst, rather than the palette indexes in
##  data[0]. The behavior is undefined if the format is not paletted.
##  @param dst_element_size size of elements in dst array (2 or 4 byte)
##

proc av_read_image_line2*(dst: pointer; data: array[4, ptr uint8];
                         linesize: array[4, cint]; desc: ptr AVPixFmtDescriptor;
                         x: cint; y: cint; c: cint; w: cint; read_pal_component: cint;
                         dst_element_size: cint)
proc av_read_image_line*(dst: ptr uint16; data: array[4, ptr uint8];
                        linesize: array[4, cint]; desc: ptr AVPixFmtDescriptor;
                        x: cint; y: cint; c: cint; w: cint; read_pal_component: cint)
## *
##  Write the values from src to the pixel format component c of an
##  image line.
##
##  @param src array containing the values to write
##  @param data the array containing the pointers to the planes of the
##  image to write into. It is supposed to be zeroed.
##  @param linesize the array containing the linesizes of the image
##  @param desc the pixel format descriptor for the image
##  @param x the horizontal coordinate of the first pixel to write
##  @param y the vertical coordinate of the first pixel to write
##  @param w the width of the line to write, that is the number of
##  values to write to the image line
##  @param src_element_size size of elements in src array (2 or 4 byte)
##

proc av_write_image_line2*(src: pointer; data: array[4, ptr uint8];
                          linesize: array[4, cint]; desc: ptr AVPixFmtDescriptor;
                          x: cint; y: cint; c: cint; w: cint; src_element_size: cint)
proc av_write_image_line*(src: ptr uint16; data: array[4, ptr uint8];
                         linesize: array[4, cint]; desc: ptr AVPixFmtDescriptor;
                         x: cint; y: cint; c: cint; w: cint)
## *
##  Utility function to swap the endianness of a pixel format.
##
##  @param[in]  pix_fmt the pixel format
##
##  @return pixel format with swapped endianness if it exists,
##  otherwise AV_PIX_FMT_NONE
##

proc av_pix_fmt_swap_endianness*(pix_fmt: AVPixelFormat): AVPixelFormat
const
  FF_LOSS_RESOLUTION* = 0x00000001
  FF_LOSS_DEPTH* = 0x00000002
  FF_LOSS_COLORSPACE* = 0x00000004
  FF_LOSS_ALPHA* = 0x00000008
  FF_LOSS_COLORQUANT* = 0x00000010
  FF_LOSS_CHROMA* = 0x00000020

## *
##  Compute what kind of losses will occur when converting from one specific
##  pixel format to another.
##  When converting from one pixel format to another, information loss may occur.
##  For example, when converting from RGB24 to GRAY, the color information will
##  be lost. Similarly, other losses occur when converting from some formats to
##  other formats. These losses can involve loss of chroma, but also loss of
##  resolution, loss of color depth, loss due to the color space conversion, loss
##  of the alpha bits or loss due to color quantization.
##  av_get_fix_fmt_loss() informs you about the various types of losses
##  which will occur when converting from one pixel format to another.
##
##  @param[in] dst_pix_fmt destination pixel format
##  @param[in] src_pix_fmt source pixel format
##  @param[in] has_alpha Whether the source pixel format alpha channel is used.
##  @return Combination of flags informing you what kind of losses will occur
##  (maximum loss for an invalid dst_pix_fmt).
##

proc av_get_pix_fmt_loss*(dst_pix_fmt: AVPixelFormat; src_pix_fmt: AVPixelFormat;
                         has_alpha: cint): cint
## *
##  Compute what kind of losses will occur when converting from one specific
##  pixel format to another.
##  When converting from one pixel format to another, information loss may occur.
##  For example, when converting from RGB24 to GRAY, the color information will
##  be lost. Similarly, other losses occur when converting from some formats to
##  other formats. These losses can involve loss of chroma, but also loss of
##  resolution, loss of color depth, loss due to the color space conversion, loss
##  of the alpha bits or loss due to color quantization.
##  av_get_fix_fmt_loss() informs you about the various types of losses
##  which will occur when converting from one pixel format to another.
##
##  @param[in] dst_pix_fmt destination pixel format
##  @param[in] src_pix_fmt source pixel format
##  @param[in] has_alpha Whether the source pixel format alpha channel is used.
##  @return Combination of flags informing you what kind of losses will occur
##  (maximum loss for an invalid dst_pix_fmt).
##

proc av_find_best_pix_fmt_of_2*(dst_pix_fmt1: AVPixelFormat;
                               dst_pix_fmt2: AVPixelFormat;
                               src_pix_fmt: AVPixelFormat; has_alpha: cint;
                               loss_ptr: ptr cint): AVPixelFormat