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
##  @ingroup lavu_frame
##  reference-counted frame API
##

#[
import
  avutil, buffer, dict, rational, samplefmt, pixfmt, version
]#
import
  ../utiltypes,
  dict, buffer, rational, version, pixfmt

when defined(windows):
  {.push importc, dynlib: "avutil-(|55|56|57).dll".}
elif defined(macosx):
  {.push importc, dynlib: "avutil(|.55|.56|.57).dylib".}
else:
  {.push importc, dynlib: "libavutil.so(|.55|.56|.57)".}

## *
##  @defgroup lavu_frame AVFrame
##  @ingroup lavu_data
##
##  @{
##  AVFrame is an abstraction for reference-counted raw multimedia data.
##


type
  AVActiveFormatDescription* = enum
    AV_AFD_SAME = 8, AV_AFD_4_3 = 9, AV_AFD_16_9 = 10, AV_AFD_14_9 = 11,
    AV_AFD_4_3_SP_14_9 = 13, AV_AFD_16_9_SP_14_9 = 14, AV_AFD_SP_4_3 = 15


## *
##  Structure to hold side data for an AVFrame.
##
##  sizeof(AVFrameSideData) is not a part of the public ABI, so new fields may be added
##  to the end with a minor bump.
##

## *
##  Structure describing a single Region Of Interest.
##
##  When multiple regions are defined in a single side-data block, they
##  should be ordered from most to least important - some encoders are only
##  capable of supporting a limited number of distinct regions, so will have
##  to truncate the list.
##
##  When overlapping regions are defined, the first region containing a given
##  area of the frame applies.
##

type
  AVRegionOfInterest*  = object
    self_size*: uint32 ## *
                       ##  Must be set to the size of this data structure (that is,
                       ##  sizeof(AVRegionOfInterest)).
                       ##
    ## *
    ##  Distance in pixels from the top edge of the frame to the top and
    ##  bottom edges and from the left edge of the frame to the left and
    ##  right edges of the rectangle defining this region of interest.
    ##
    ##  The constraints on a region are encoder dependent, so the region
    ##  actually affected may be slightly larger for alignment or other
    ##  reasons.
    ##
    top*: cint
    bottom*: cint
    left*: cint
    right*: cint ## *
               ##  Quantisation offset.
               ##
               ##  Must be in the range -1 to +1.  A value of zero indicates no quality
               ##  change.  A negative value asks for better quality (less quantisation),
               ##  while a positive value asks for worse quality (greater quantisation).
               ##
               ##  The range is calibrated so that the extreme values indicate the
               ##  largest possible offset - if the rest of the frame is encoded with the
               ##  worst possible quality, an offset of -1 indicates that this region
               ##  should be encoded with the best possible quality anyway.  Intermediate
               ##  values are then interpolated in some codec-dependent way.
               ##
               ##  For example, in 10-bit H.264 the quantisation parameter varies between
               ##  -12 and 51.  A typical qoffset value of -1/10 therefore indicates that
               ##  this region should be encoded with a QP around one-tenth of the full
               ##  range better than the rest of the frame.  So, if most of the frame
               ##  were to be encoded with a QP of around 30, this region would get a QP
               ##  of around 24 (an offset of approximately -1/10 * (51 - -12) = -6.3).
               ##  An extreme value of -1 would indicate that this region should be
               ##  encoded with the best possible quality regardless of the treatment of
               ##  the rest of the frame - that is, should be encoded at a QP of -12.
               ##
    qoffset*: AVRational


## *
##  This structure describes decoded (raw) audio or video data.
##
##  AVFrame must be allocated using av_frame_alloc(). Note that this only
##  allocates the AVFrame itself, the buffers for the data must be managed
##  through other means (see below).
##  AVFrame must be freed with av_frame_free().
##
##  AVFrame is typically allocated once and then reused multiple times to hold
##  different data (e.g. a single AVFrame to hold frames received from a
##  decoder). In such a case, av_frame_unref() will free any references held by
##  the frame and reset it to its original clean state before it
##  is reused again.
##
##  The data described by an AVFrame is usually reference counted through the
##  AVBuffer API. The underlying buffer references are stored in AVFrame.buf /
##  AVFrame.extended_buf. An AVFrame is considered to be reference counted if at
##  least one reference is set, i.e. if AVFrame.buf[0] != NULL. In such a case,
##  every single data plane must be contained in one of the buffers in
##  AVFrame.buf or AVFrame.extended_buf.
##  There may be a single buffer for all the data, or one separate buffer for
##  each plane, or anything in between.
##
##  sizeof(AVFrame) is not a part of the public ABI, so new fields may be added
##  to the end with a minor bump.
##
##  Fields can be accessed through AVOptions, the name string used, matches the
##  C structure field name for fields accessible through AVOptions. The AVClass
##  for AVFrame can be obtained from avcodec_get_frame_class()
##


when FF_API_FRAME_GET_SET:
  ## *
  ##  Accessors for some AVFrame fields. These used to be provided for ABI
  ##  compatibility, and do not need to be used anymore.
  ##
  ## attribute_deprecated
  proc av_frame_get_best_effortimestamp*(frame: ptr AVFrame): int64
  ## attribute_deprecated
  proc av_frame_set_best_effortimestamp*(frame: ptr AVFrame; val: int64)
  ## attribute_deprecated
  proc av_frame_get_pkt_duration*(frame: ptr AVFrame): int64
  ## attribute_deprecated
  proc av_frame_set_pkt_duration*(frame: ptr AVFrame; val: int64)
  ## attribute_deprecated
  proc av_frame_get_pkt_pos*(frame: ptr AVFrame): int64
  ## attribute_deprecated
  proc av_frame_set_pkt_pos*(frame: ptr AVFrame; val: int64)
  ## attribute_deprecated
  proc av_frame_get_channel_layout*(frame: ptr AVFrame): int64
  ## attribute_deprecated
  proc av_frame_set_channel_layout*(frame: ptr AVFrame; val: int64)
  ## attribute_deprecated
  proc av_frame_get_channels*(frame: ptr AVFrame): cint
  ## attribute_deprecated
  proc av_frame_set_channels*(frame: ptr AVFrame; val: cint)
  ## attribute_deprecated
  proc av_frame_get_sample_rate*(frame: ptr AVFrame): cint
  ## attribute_deprecated
  proc av_frame_set_sample_rate*(frame: ptr AVFrame; val: cint)
  ## attribute_deprecated
  proc av_frame_get_metadata*(frame: ptr AVFrame): ptr AVDictionary
  ## attribute_deprecated
  proc av_frame_set_metadata*(frame: ptr AVFrame; val: ptr AVDictionary)
  ## attribute_deprecated
  proc av_frame_get_decode_error_flags*(frame: ptr AVFrame): cint
  ## attribute_deprecated
  proc av_frame_set_decode_error_flags*(frame: ptr AVFrame; val: cint)
  ## attribute_deprecated
  proc av_frame_get_pkt_size*(frame: ptr AVFrame): cint
  ## attribute_deprecated
  proc av_frame_set_pkt_size*(frame: ptr AVFrame; val: cint)
  when FF_API_FRAME_QP:
    ## attribute_deprecated
    proc av_frame_get_qpable*(f: ptr AVFrame; stride: ptr cint; `type`: ptr cint): ptr int8
    ## attribute_deprecated
    proc av_frame_set_qpable*(f: ptr AVFrame; buf: ptr AVBufferRef; stride: cint;
                               `type`: cint): cint
  ## attribute_deprecated
  proc av_frame_get_colorspace*(frame: ptr AVFrame): AVColorSpace
  ## attribute_deprecated
  proc av_frame_set_colorspace*(frame: ptr AVFrame; val: AVColorSpace)
  ## attribute_deprecated
  proc av_frame_get_color_range*(frame: ptr AVFrame): AVColorRange
  ## attribute_deprecated
  proc av_frame_set_color_range*(frame: ptr AVFrame; val: AVColorRange)
## *
##  Get the name of a colorspace.
##  @return a static string identifying the colorspace; can be NULL.
##

proc av_get_colorspace_name*(val: AVColorSpace): cstring
## *
##  Allocate an AVFrame and set its fields to default values.  The resulting
##  struct must be freed using av_frame_free().
##
##  @return An AVFrame filled with default values or NULL on failure.
##
##  @note this only allocates the AVFrame itself, not the data buffers. Those
##  must be allocated through other means, e.g. with av_frame_get_buffer() or
##  manually.
##

proc av_frame_alloc*(): ptr AVFrame
## *
##  Free the frame and any dynamically allocated objects in it,
##  e.g. extended_data. If the frame is reference counted, it will be
##  unreferenced first.
##
##  @param frame frame to be freed. The pointer will be set to NULL.
##

proc av_frame_free*(frame: ptr ptr AVFrame)
## *
##  Set up a new reference to the data described by the source frame.
##
##  Copy frame properties from src to dst and create a new reference for each
##  AVBufferRef from src.
##
##  If src is not reference counted, new buffers are allocated and the data is
##  copied.
##
##  @warning: dst MUST have been either unreferenced with av_frame_unref(dst),
##            or newly allocated with av_frame_alloc() before calling this
##            function, or undefined behavior will occur.
##
##  @return 0 on success, a negative AVERROR on error
##

proc av_frame_ref*(dst: ptr AVFrame; src: ptr AVFrame): cint
## *
##  Create a new frame that references the same data as src.
##
##  This is a shortcut for av_frame_alloc()+av_frame_ref().
##
##  @return newly created AVFrame on success, NULL on error.
##

proc av_frame_clone*(src: ptr AVFrame): ptr AVFrame
## *
##  Unreference all the buffers referenced by frame and reset the frame fields.
##

proc av_frame_unref*(frame: ptr AVFrame)
## *
##  Move everything contained in src to dst and reset src.
##
##  @warning: dst is not unreferenced, but directly overwritten without reading
##            or deallocating its contents. Call av_frame_unref(dst) manually
##            before calling this function to ensure that no memory is leaked.
##

proc av_frame_move_ref*(dst: ptr AVFrame; src: ptr AVFrame)
## *
##  Allocate new buffer(s) for audio or video data.
##
##  The following fields must be set on frame before calling this function:
##  - format (pixel format for video, sample format for audio)
##  - width and height for video
##  - nb_samples and channel_layout for audio
##
##  This function will fill AVFrame.data and AVFrame.buf arrays and, if
##  necessary, allocate and fill AVFrame.extended_data and AVFrame.extended_buf.
##  For planar formats, one buffer will be allocated for each plane.
##
##  @warning: if frame already has been allocated, calling this function will
##            leak memory. In addition, undefined behavior can occur in certain
##            cases.
##
##  @param frame frame in which to store the new buffers.
##  @param align Required buffer size alignment. If equal to 0, alignment will be
##               chosen automatically for the current CPU. It is highly
##               recommended to pass 0 here unless you know what you are doing.
##
##  @return 0 on success, a negative AVERROR on error.
##

proc av_frame_get_buffer*(frame: ptr AVFrame; align: cint): cint
## *
##  Check if the frame data is writable.
##
##  @return A positive value if the frame data is writable (which is true if and
##  only if each of the underlying buffers has only one reference, namely the one
##  stored in this frame). Return 0 otherwise.
##
##  If 1 is returned the answer is valid until av_buffer_ref() is called on any
##  of the underlying AVBufferRefs (e.g. through av_frame_ref() or directly).
##
##  @see av_frame_make_writable(), av_buffer_is_writable()
##

proc av_frame_is_writable*(frame: ptr AVFrame): cint
## *
##  Ensure that the frame data is writable, avoiding data copy if possible.
##
##  Do nothing if the frame is writable, allocate new buffers and copy the data
##  if it is not.
##
##  @return 0 on success, a negative AVERROR on error.
##
##  @see av_frame_is_writable(), av_buffer_is_writable(),
##  av_buffer_make_writable()
##

proc av_frame_make_writable*(frame: ptr AVFrame): cint
## *
##  Copy the frame data from src to dst.
##
##  This function does not allocate anything, dst must be already initialized and
##  allocated with the same parameters as src.
##
##  This function only copies the frame data (i.e. the contents of the data /
##  extended data arrays), not any other properties.
##
##  @return >= 0 on success, a negative AVERROR on error.
##

proc av_frame_copy*(dst: ptr AVFrame; src: ptr AVFrame): cint
## *
##  Copy only "metadata" fields from src to dst.
##
##  Metadata for the purpose of this function are those fields that do not affect
##  the data layout in the buffers.  E.g. pts, sample rate (for audio) or sample
##  aspect ratio (for video), but not width/height or channel layout.
##  Side data is also copied.
##

proc av_frame_copy_props*(dst: ptr AVFrame; src: ptr AVFrame): cint
## *
##  Get the buffer reference a given data plane is stored in.
##
##  @param plane index of the data plane of interest in frame->extended_data.
##
##  @return the buffer reference that contains the plane or NULL if the input
##  frame is not valid.
##

proc av_frame_get_plane_buffer*(frame: ptr AVFrame; plane: cint): ptr AVBufferRef
## *
##  Add a new side data to a frame.
##
##  @param frame a frame to which the side data should be added
##  @param type type of the added side data
##  @param size size of the side data
##
##  @return newly added side data on success, NULL on error
##

proc av_frame_new_side_data*(frame: ptr AVFrame; `type`: AVFrameSideDataType; size: cint): ptr AVFrameSideData
## *
##  Add a new side data to a frame from an existing AVBufferRef
##
##  @param frame a frame to which the side data should be added
##  @param type  the type of the added side data
##  @param buf   an AVBufferRef to add as side data. The ownership of
##               the reference is transferred to the frame.
##
##  @return newly added side data on success, NULL on error. On failure
##          the frame is unchanged and the AVBufferRef remains owned by
##          the caller.
##

proc av_frame_new_side_data_from_buf*(frame: ptr AVFrame; `type`: AVFrameSideDataType;
                                     buf: ptr AVBufferRef): ptr AVFrameSideData
## *
##  @return a pointer to the side data of a given type on success, NULL if there
##  is no side data with such type in this frame.
##

proc av_frame_get_side_data*(frame: ptr AVFrame; `type`: AVFrameSideDataType): ptr AVFrameSideData
## *
##  Remove and free all side data instances of the given type.
##

proc av_frame_remove_side_data*(frame: ptr AVFrame; `type`: AVFrameSideDataType)
## *
##  Flags for frame cropping.
##

const ## *
     ##  Apply the maximum possible cropping, even if it requires setting the
     ##  AVFrame.data[] entries to unaligned pointers. Passing unaligned data
     ##  to FFmpeg API is generally not allowed, and causes undefined behavior
     ##  (such as crashes). You can pass unaligned data only to FFmpeg APIs that
     ##  are explicitly documented to accept it. Use this flag only if you
     ##  absolutely know what you are doing.
     ##
  AV_FRAME_CROP_UNALIGNED* = 1 shl 0

## *
##  Crop the given video AVFrame according to its crop_left/cropop/crop_right/
##  crop_bottom fields. If cropping is successful, the function will adjust the
##  data pointers and the width/height fields, and set the crop fields to 0.
##
##  In all cases, the cropping boundaries will be rounded to the inherent
##  alignment of the pixel format. In some cases, such as for opaque hwaccel
##  formats, the left/top cropping is ignored. The crop fields are set to 0 even
##  if the cropping was rounded or ignored.
##
##  @param frame the frame which should be cropped
##  @param flags Some combination of AV_FRAME_CROP_* flags, or 0.
##
##  @return >= 0 on success, a negative AVERROR on error. If the cropping fields
##  were invalid, AVERROR(ERANGE) is returned, and nothing is changed.
##

proc av_frame_apply_cropping*(frame: ptr AVFrame; flags: cint): cint
## *
##  @return a string identifying the side data type
##

proc av_frame_side_data_name*(`type`: AVFrameSideDataType): cstring
## *
##  @}
##
