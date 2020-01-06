##
##  copyright (c) 2001 Fabrice Bellard
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
##  @ingroup libavc
##  Libavcodec external API header
##


import
  #[
  libavutil/samplefmt, libavutil/attributes, libavutil/avutil, libavutil/buffer,
  libavutil/cpu, libavutil/channel_layout, libavutil/dict, libavutil/frame,
  libavutil/hwcontext, libavutil/log, libavutil/pixfmt, libavutil/rational, version
]#
  version,
  ../utiltypes,
  ../libavutil/[buffer, rational, pixfmt, hwcontext, dict]

when defined(windows):
  {.push importc, dynlib: "avcodec(|-55|-56|-57|-58|-59).dll".}
elif defined(macosx):
  {.push importc, dynlib: "avcodec(|.55|.56|.57|.58|.59).dylib".}
else:
  {.push importc, dynlib: "avcodec.so(|.55|.56|.57|.58|.59)".}

{.pragma: avcodec, importc, header:"<libavcodec/avcodec.h>".}
## *
##  @defgroup libavc libavcodec
##  Encoding/Decoding Library
##
##  @{
##
##  @defgroup lavc_decoding Decoding
##  @{
##  @}
##
##  @defgroup lavc_encoding Encoding
##  @{
##  @}
##
##  @defgroup lavc_codec Codecs
##  @{
##  @defgroup lavc_codec_native Native Codecs
##  @{
##  @}
##  @defgroup lavc_codec_wrappers External library wrappers
##  @{
##  @}
##  @defgroup lavc_codec_hwaccel Hardware Accelerators bridge
##  @{
##  @}
##  @}
##  @defgroup lavc_internal Internal
##  @{
##  @}
##  @}
##
## *
##  @ingroup libavc
##  @defgroup lavc_encdec send/receive encoding and decoding API overview
##  @{
##
##  The avcodec_send_packet()/avcodec_receive_frame()/avcodec_send_frame()/
##  avcodec_receive_packet() functions provide an encode/decode API, which
##  decouples input and output.
##
##  The API is very similar for encoding/decoding and audio/video, and works as
##  follows:
##  - Set up and open the AVCodecContext as usual.
##  - Send valid input:
##    - For decoding, call avcodec_send_packet() to give the decoder raw
##      compressed data in an AVPacket.
##    - For encoding, call avcodec_send_frame() to give the encoder an AVFrame
##      containing uncompressed audio or video.
##    In both cases, it is recommended that AVPackets and AVFrames are
##    refcounted, or libavcodec might have to copy the input data. (libavformat
##    always returns refcounted AVPackets, and av_frame_get_buffer() allocates
##    refcounted AVFrames.)
##  - Receive output in a loop. Periodically call one of the avcodec_receive_*()
##    functions and process their output:
##    - For decoding, call avcodec_receive_frame(). On success, it will return
##      an AVFrame containing uncompressed audio or video data.
##    - For encoding, call avcodec_receive_packet(). On success, it will return
##      an AVPacket with a compressed frame.
##    Repeat this call until it returns AVERROR(EAGAIN) or an error. The
##    AVERROR(EAGAIN) return value means that new input data is required to
##    return new output. In this case, continue with sending input. For each
##    input frame/packet, the codec will typically return 1 output frame/packet,
##    but it can also be 0 or more than 1.
##
##  At the beginning of decoding or encoding, the codec might accept multiple
##  input frames/packets without returning a frame, until its internal buffers
##  are filled. This situation is handled transparently if you follow the steps
##  outlined above.
##
##  In theory, sending input can result in EAGAIN - this should happen only if
##  not all output was received. You can use this to structure alternative decode
##  or encode loops other than the one suggested above. For example, you could
##  try sending new input on each iteration, and try to receive output if that
##  returns EAGAIN.
##
##  End of stream situations. These require "flushing" (aka draining) the codec,
##  as the codec might buffer multiple frames or packets internally for
##  performance or out of necessity (consider B-frames).
##  This is handled as follows:
##  - Instead of valid input, send NULL to the avcodec_send_packet() (decoding)
##    or avcodec_send_frame() (encoding) functions. This will enter draining
##    mode.
##  - Call avcodec_receive_frame() (decoding) or avcodec_receive_packet()
##    (encoding) in a loop until AVERROR_EOF is returned. The functions will
##    not return AVERROR(EAGAIN), unless you forgot to enter draining mode.
##  - Before decoding can be resumed again, the codec has to be reset with
##    avcodec_flush_buffers().
##
##  Using the API as outlined above is highly recommended. But it is also
##  possible to call functions outside of this rigid schema. For example, you can
##  call avcodec_send_packet() repeatedly without calling
##  avcodec_receive_frame(). In this case, avcodec_send_packet() will succeed
##  until the codec's internal buffer has been filled up (which is typically of
##  size 1 per output frame, after initial input), and then reject input with
##  AVERROR(EAGAIN). Once it starts rejecting input, you have no choice but to
##  read at least some output.
##
##  Not all codecs will follow a rigid and predictable dataflow; the only
##  guarantee is that an AVERROR(EAGAIN) return value on a send/receive call on
##  one end implies that a receive/send call on the other end will succeed, or
##  at least will not fail with AVERROR(EAGAIN). In general, no codec will
##  permit unlimited buffering of input or output.
##
##  This API replaces the following legacy functions:
##  - avcodec_decode_video2() and avcodec_decode_audio4():
##    Use avcodec_send_packet() to feed input to the decoder, then use
##    avcodec_receive_frame() to receive decoded frames after each packet.
##    Unlike with the old video decoding API, multiple frames might result from
##    a packet. For audio, splitting the input packet into frames by partially
##    decoding packets becomes transparent to the API user. You never need to
##    feed an AVPacket to the API twice (unless it is rejected with AVERROR(EAGAIN) - then
##    no data was read from the packet).
##    Additionally, sending a flush/draining packet is required only once.
##  - avcodec_encode_video2()/avcodec_encode_audio2():
##    Use avcodec_send_frame() to feed input to the encoder, then use
##    avcodec_receive_packet() to receive encoded packets.
##    Providing user-allocated buffers for avcodec_receive_packet() is not
##    possible.
##  - The new API does not handle subtitles yet.
##
##  Mixing new and old function calls on the same AVCodecContext is not allowed,
##  and will result in undefined behavior.
##
##  Some codecs might require using the new API; using the old API will return
##  an error when calling it. All codecs support the new API.
##
##  A codec is not allowed to return AVERROR(EAGAIN) for both sending and receiving. This
##  would be an invalid state, which could put the codec user into an endless
##  loop. The API has no concept of time either: it cannot happen that trying to
##  do avcodec_send_packet() results in AVERROR(EAGAIN), but a repeated call 1 second
##  later accepts the packet (with no other receive/flush API calls involved).
##  The API is a strict state machine, and the passage of time is not supposed
##  to influence it. Some timing-dependent behavior might still be deemed
##  acceptable in certain cases. But it must never result in both send/receive
##  returning EAGAIN at the same time at any point. It must also absolutely be
##  avoided that the current state is "unstable" and can "flip-flop" between
##  the send/receive APIs allowing progress. For example, it's not allowed that
##  the codec randomly decides that it actually wants to consume a packet now
##  instead of returning a frame, after it just returned AVERROR(EAGAIN) on an
##  avcodec_send_packet() call.
##  @}
##
## *
##  @defgroup lavc_core Core functions/structures.
##  @ingroup libavc
##
##  Basic definitions, functions for querying libavcodec capabilities,
##  allocating core structures, etc.
##  @{
##
## *
##  Identify the syntax and semantics of the bitstream.
##  The principle is roughly:
##  Two decoders with the same ID can decode the same streams.
##  Two encoders with the same ID can encode compatible streams.
##  There may be slight deviations from the principle due to implementation
##  details.
##
##  If you add a codec ID to this list, add it so that
##  1. no value of an existing codec ID changes (that would break ABI),
##  2. it is as close as possible to similar codecs
##
##  After adding new codec IDs, do not forget to add an entry to the codec
##  descriptor list and bump libavcodec minor version.
##

const
  AV_CODEC_ID_IFF_BYTERUN1* = AV_CODEC_ID_IFF_ILBM
  AV_CODEC_ID_H265* = AV_CODEC_ID_HEVC
  AV_CODEC_ID_PCM_S16LE* = AV_CODEC_ID_FIRST_AUDIO
  AV_CODEC_ID_DVD_SUBTITLE* = AV_CODEC_ID_FIRST_SUBTITLE
  AV_CODEC_ID_TTF* = AV_CODEC_ID_FIRST_UNKNOWN

## *
##  This struct describes the properties of a single codec described by an
##  AVCodecID.
##  @see avcodec_descriptor_get()
##


## *
##  Codec uses only intra compression.
##  Video and audio codecs only.
##

const
  AV_CODEC_PROP_INTRA_ONLY* = (1 shl 0)

## *
##  Codec supports lossy compression. Audio and video codecs only.
##  @note a codec may support both lossy and lossless
##  compression modes
##

const
  AV_CODEC_PROP_LOSSY* = (1 shl 1)

## *
##  Codec supports lossless compression. Audio and video codecs only.
##

const
  AV_CODEC_PROP_LOSSLESS* = (1 shl 2)

## *
##  Codec supports frame reordering. That is, the coded order (the order in which
##  the encoded packets are output by the encoders / stored / input to the
##  decoders) may be different from the presentation order of the corresponding
##  frames.
##
##  For codecs that do not have this property set, PTS and DTS should always be
##  equal.
##

const
  AV_CODEC_PROP_REORDER* = (1 shl 3)

## *
##  Subtitle codec is bitmap based
##  Decoded AVSubtitle data can be read from the AVSubtitleRect->pict field.
##

const
  AV_CODEC_PROP_BITMAP_SUB* = (1 shl 16)

## *
##  Subtitle codec is text based.
##  Decoded AVSubtitle data can be read from the AVSubtitleRect->ass field.
##

const
  AV_CODEC_PROP_TEXT_SUB* = (1 shl 17)

## *
##  @ingroup lavc_decoding
##  Required number of additionally allocated bytes at the end of the input bitstream for decoding.
##  This is mainly needed because some optimized bitstream readers read
##  32 or 64 bit at once and could read over the end.<br>
##  Note: If the first 23 bits of the additional bytes are not 0, then damaged
##  MPEG bitstreams could cause overread and segfault.
##

const
  AV_INPUT_BUFFER_PADDING_SIZE* = 64

## *
##  @ingroup lavc_encoding
##  minimum encoding buffer size
##  Used to avoid some checks during header writing.
##

const
  AV_INPUT_BUFFER_MIN_SIZE* = 16384

## *
##  @ingroup lavc_decoding
##



## *
##  @ingroup lavc_encoding
##


##  encoding support
##    These flags can be passed in AVCodecContext.flags before initialization.
##    Note: Not everything is supported yet.
##
## *
##  Allow decoders to produce frames with data planes that are not aligned
##  to CPU requirements (e.g. due to cropping).
##

const
  AV_CODEC_FLAG_UNALIGNED* = (1 shl 0)

## *
##  Use fixed qscale.
##

const
  AV_CODEC_FLAG_QSCALE* = (1 shl 1)

## *
##  4 MV per MB allowed / advanced prediction for H.263.
##

const
  AV_CODEC_FLAG_4MV* = (1 shl 2)

## *
##  Output even those frames that might be corrupted.
##

const
  AV_CODEC_FLAG_OUTPUT_CORRUPT* = (1 shl 3)

## *
##  Use qpel MC.
##

const
  AV_CODEC_FLAG_QPEL* = (1 shl 4)

## *
##  Don't output frames whose parameters differ from first
##  decoded frame in stream.
##

const
  AV_CODEC_FLAG_DROPCHANGED* = (1 shl 5)

## *
##  Use internal 2pass ratecontrol in first pass mode.
##

const
  AV_CODEC_FLAG_PASS1* = (1 shl 9)

## *
##  Use internal 2pass ratecontrol in second pass mode.
##

const
  AV_CODEC_FLAG_PASS2* = (1 shl 10)

## *
##  loop filter.
##

const
  AV_CODEC_FLAG_LOOP_FILTER* = (1 shl 11)

## *
##  Only decode/encode grayscale.
##

const
  AV_CODEC_FLAG_GRAY* = (1 shl 13)

## *
##  error[?] variables will be set during encoding.
##

const
  AV_CODEC_FLAG_PSNR* = (1 shl 15)

## *
##  Input bitstream might be truncated at a random location
##  instead of only at frame boundaries.
##

const
  AV_CODEC_FLAG_TRUNCATED* = (1 shl 16)

## *
##  Use interlaced DCT.
##

const
  AV_CODEC_FLAG_INTERLACED_DCT* = (1 shl 18)

## *
##  Force low delay.
##

const
  AV_CODEC_FLAG_LOW_DELAY* = (1 shl 19)

## *
##  Place global headers in extradata instead of every keyframe.
##

const
  AV_CODEC_FLAG_GLOBAL_HEADER* = (1 shl 22)

## *
##  Use only bitexact stuff (except (I)DCT).
##

const
  AV_CODEC_FLAG_BITEXACT* = (1 shl 23)

##  Fx : Flag for H.263+ extra options
## *
##  H.263 advanced intra coding / MPEG-4 AC prediction
##

const
  AV_CODEC_FLAG_AC_PRED* = (1 shl 24)

## *
##  interlaced motion estimation
##

const
  AV_CODEC_FLAG_INTERLACED_ME* = (1 shl 29)
  AV_CODEC_FLAG_CLOSED_GOP* = (1 shl 31)

## *
##  Allow non spec compliant speedup tricks.
##

const
  AV_CODEC_FLAG2_FAST* = (1 shl 0)

## *
##  Skip bitstream encoding.
##

const
  AV_CODEC_FLAG2_NO_OUTPUT* = (1 shl 2)

## *
##  Place global headers at every keyframe instead of in extradata.
##

const
  AV_CODEC_FLAG2_LOCAL_HEADER* = (1 shl 3)

## *
##  timecode is in drop frame format. DEPRECATED!!!!
##

const
  AV_CODEC_FLAG2_DROP_FRAME_TIMECODE* = (1 shl 13)

## *
##  Input bitstream might be truncated at a packet boundaries
##  instead of only at frame boundaries.
##

const
  AV_CODEC_FLAG2_CHUNKS* = (1 shl 15)

## *
##  Discard cropping information from SPS.
##

const
  AV_CODEC_FLAG2_IGNORE_CROP* = (1 shl 16)

## *
##  Show all frames before the first keyframe
##

const
  AV_CODEC_FLAG2_SHOW_ALL* = (1 shl 22)

## *
##  Export motion vectors through frame side data
##

const
  AV_CODEC_FLAG2_EXPORT_MVS* = (1 shl 28)

## *
##  Do not skip samples and export skip information as frame side data
##

const
  AV_CODEC_FLAG2_SKIP_MANUAL* = (1 shl 29)

## *
##  Do not reset ASS ReadOrder field on flush (subtitles decoding)
##

const
  AV_CODEC_FLAG2_RO_FLUSH_NOOP* = (1 shl 30)

##  Unsupported options :
##               Syntax Arithmetic coding (SAC)
##               Reference Picture Selection
##               Independent Segment Decoding
##  /Fx
##  codec capabilities
## *
##  Decoder can use draw_horiz_band callback.
##

const
  AV_CODEC_CAP_DRAW_HORIZ_BAND* = (1 shl 0)

## *
##  Codec uses get_buffer() for allocating buffers and supports custom allocators.
##  If not set, it might not use get_buffer() at all or use operations that
##  assume the buffer was allocated by avcodec_default_get_buffer.
##

const
  AV_CODEC_CAP_DR1* = (1 shl 1)
  AV_CODEC_CAP_TRUNCATED* = (1 shl 3)

## *
##  Encoder or decoder requires flushing with NULL input at the end in order to
##  give the complete and correct output.
##
##  NOTE: If this flag is not set, the codec is guaranteed to never be fed with
##        with NULL data. The user can still send NULL data to the public encode
##        or decode function, but libavcodec will not pass it along to the codec
##        unless this flag is set.
##
##  Decoders:
##  The decoder has a non-zero delay and needs to be fed with avpkt->data=NULL,
##  avpkt->size=0 at the end to get the delayed data until the decoder no longer
##  returns frames.
##
##  Encoders:
##  The encoder needs to be fed with NULL data at the end of encoding until the
##  encoder no longer returns data.
##
##  NOTE: For encoders implementing the AVCodec.encode2() function, setting this
##        flag also means that the encoder must set the pts and duration for
##        each output packet. If this flag is not set, the pts and duration will
##        be determined by libavcodec from the input frame.
##

const
  AV_CODEC_CAP_DELAY* = (1 shl 5)

## *
##  Codec can be fed a final frame with a smaller size.
##  This can be used to prevent truncation of the last audio samples.
##

const
  AV_CODEC_CAP_SMALL_LAST_FRAME* = (1 shl 6)

## *
##  Codec can output multiple frames per AVPacket
##  Normally demuxers return one frame at a time, demuxers which do not do
##  are connected to a parser to split what they return into proper frames.
##  This flag is reserved to the very rare category of codecs which have a
##  bitstream that cannot be split into frames without timeconsuming
##  operations like full decoding. Demuxers carrying such bitstreams thus
##  may return multiple frames in a packet. This has many disadvantages like
##  prohibiting stream copy in many cases thus it should only be considered
##  as a last resort.
##

const
  AV_CODEC_CAP_SUBFRAMES* = (1 shl 8)

## *
##  Codec is experimental and is thus avoided in favor of non experimental
##  encoders
##

const
  AV_CODEC_CAP_EXPERIMENTAL* = (1 shl 9)

## *
##  Codec should fill in channel configuration and samplerate instead of container
##

const
  AV_CODEC_CAP_CHANNEL_CONF* = (1 shl 10)

## *
##  Codec supports frame-level multithreading.
##

const
  AV_CODEC_CAP_FRAME_THREADS* = (1 shl 12)

## *
##  Codec supports slice-based (or partition-based) multithreading.
##

const
  AV_CODEC_CAP_SLICE_THREADS* = (1 shl 13)

## *
##  Codec supports changed parameters at any point.
##

const
  AV_CODEC_CAP_PARAM_CHANGE* = (1 shl 14)

## *
##  Codec supports avctx->thread_count == 0 (auto).
##

const
  AV_CODEC_CAP_AUTO_THREADS* = (1 shl 15)

## *
##  Audio encoder supports receiving a different number of samples in each call.
##

const
  AV_CODEC_CAP_VARIABLE_FRAME_SIZE* = (1 shl 16)

## *
##  Decoder is not a preferred choice for probing.
##  This indicates that the decoder is not a good choice for probing.
##  It could for example be an expensive to spin up hardware decoder,
##  or it could simply not provide a lot of useful information about
##  the stream.
##  A decoder marked with this flag should only be used as last resort
##  choice for probing.
##

const
  AV_CODEC_CAP_AVOID_PROBING* = (1 shl 17)

## *
##  Codec is intra only.
##

const
  AV_CODEC_CAP_INTRA_ONLY* = 0x40000000

## *
##  Codec is lossless.
##

const
  AV_CODEC_CAP_LOSSLESS* = 0x80000000

## *
##  Codec is backed by a hardware implementation. Typically used to
##  identify a non-hwaccel hardware decoder. For information about hwaccels, use
##  avcodec_get_hw_config() instead.
##

const
  AV_CODEC_CAP_HARDWARE* = (1 shl 18)

## *
##  Codec is potentially backed by a hardware implementation, but not
##  necessarily. This is used instead of AV_CODEC_CAP_HARDWARE, if the
##  implementation provides some sort of internal fallback.
##

const
  AV_CODEC_CAP_HYBRID* = (1 shl 19)

## *
##  This codec takes the reordered_opaque field from input AVFrames
##  and returns it in the corresponding field in AVCodecContext after
##  encoding.
##

const
  AV_CODEC_CAP_ENCODER_REORDERED_OPAQUE* = (1 shl 20)

## *
##  Pan Scan area.
##  This specifies the area which should be displayed.
##  Note there may be multiple such areas for one frame.
##

type
  AVPanScan* {.avcodec.}  = object
    id*: cint                  ## *
            ##  id
            ##  - encoding: Set by user.
            ##  - decoding: Set by libavcodec.
            ##
    ## *
    ##  width and height in 1/16 pel
    ##  - encoding: Set by user.
    ##  - decoding: Set by libavcodec.
    ##
    width*: cint
    height*: cint ## *
                ##  position of the top left corner in 1/16 pel for up to 3 fields/frames
                ##  - encoding: Set by user.
                ##  - decoding: Set by libavcodec.
                ##
    #position*: array[3, array[2, int16]]
    position*: array[3, array[2, int16]]


## *
##  This structure describes the bitrate properties of an encoded bitstream. It
##  roughly corresponds to a subset the VBV parameters for MPEG-2 or HRD
##  parameters for H.264/HEVC.
##

type
  AVCPBProperties* {.avcodec.} = object
    when defined(FF_API_UNSANITIZED_BITRATES): ## *
                                    ##  Maximum bitrate of the stream, in bits per second.
                                    ##  Zero if unknown or unspecified.
                                    ##
      max_bitrate*: cint
      min_bitrate*: cint
      avg_bitrate*: cint
    else:
      max_bitrate*: int64
      min_bitrate*: int64
      avg_bitrate*: int64
    buffer_size*: cint ## *
                     ##  The delay between the time the packet this structure is associated with
                     ##  is received and the time when it should be decoded, in periods of a 27MHz
                     ##  clock.
                     ##
                     ##  UINT64_MAX when unknown or unspecified.
                     ##
    vbv_delay*: uint64


## *
##  The decoder will keep a reference to the frame and may reuse it later.
##

const
  AV_GET_BUFFER_FLAG_REF* = (1 shl 0)

## *
##  @defgroup lavc_packet AVPacket
##
##  Types and functions for working with AVPacket.
##  @{
##


const
  AV_PKT_DATA_QUALITY_FACTOR* = AV_PKT_DATA_QUALITY_STATS


## *
##  This structure stores compressed data. It is typically exported by demuxers
##  and then passed as input to decoders, or received as output from encoders and
##  then passed to muxers.
##
##  For video, it should typically contain one compressed frame. For audio it may
##  contain several compressed frames. Encoders are allowed to output empty
##  packets, with no compressed data, containing only side data
##  (e.g. to update some stream parameters at the end of encoding).
##
##  AVPacket is one of the few structs in FFmpeg, whose size is a part of public
##  ABI. Thus it may be allocated on stack and no new fields can be added to it
##  without libavcodec and libavformat major bump.
##
##  The semantics of data ownership depends on the buf field.
##  If it is set, the packet data is dynamically allocated and is
##  valid indefinitely until a call to av_packet_unref() reduces the
##  reference count to 0.
##
##  If the buf field is not set av_packet_ref() would make a copy instead
##  of increasing the reference count.
##
##  The side data is always allocated with av_malloc(), copied by
##  av_packet_ref() and freed by av_packet_unref().
##
##  @see av_packet_ref
##  @see av_packet_unref
##


const
  AV_PKT_FLAG_KEY* = 0x00000001
  AV_PKT_FLAG_CORRUPT* = 0x00000002
  AV_PKT_FLAG_DISCARD* = 0x00000004

## *
##  The packet comes from a trusted source.
##
##  Otherwise-unsafe constructs such as arbitrary pointers to data
##  outside the packet may be followed.
##

const
  AV_PKT_FLAG_TRUSTED* = 0x00000008

## *
##  Flag is used to indicate packets that contain frames that can
##  be discarded by the decoder.  I.e. Non-reference frames.
##

const
  AV_PKT_FLAG_DISPOSABLE* = 0x00000010

type
  AVSideDataParamChangeFlags*{.avcodec.} = enum
    AV_SIDE_DATA_PARAM_CHANGE_CHANNEL_COUNT = 0x00000001,
    AV_SIDE_DATA_PARAM_CHANGE_CHANNEL_LAYOUT = 0x00000002,
    AV_SIDE_DATA_PARAM_CHANGE_SAMPLE_RATE = 0x00000004,
    AV_SIDE_DATA_PARAM_CHANGE_DIMENSIONS = 0x00000008


## *
##  @}
##

## *
##  main external API structure.
##  New fields can be added to the end with minor version bumps.
##  Removal, reordering and changes to existing fields require a major
##  version bump.
##  You can use AVOptions (av_opt* / av_set/get*()) to access these fields from user
##  applications.
##  The name string for AVOptions options matches the associated command line
##  parameter name and can be found in libavcodec/optionsable.h
##  The AVOption/command line parameter names differ in some cases from the C
##  structure field names for historic reasons or brevity.
##  sizeof(AVCodecContext) must not be used outside libav*.
##
const
  FF_COMPRESSION_DEFAULT* = -1
  FF_PRED_LEFT* = 0
  FF_PRED_PLANE* = 1
  FF_PRED_MEDIAN* = 2

when defined(FF_API_ASS_TIMING):
 const FF_SUB_TEXT_FMT_ASS_WITH_TIMINGS* = 1

const
  FF_CMP_SAD* = 0
  FF_CMP_SSE* = 1
  FF_CMP_SATD* = 2
  FF_CMP_DCT* = 3
  FF_CMP_PSNR* = 4
  FF_CMP_BIT* = 5
  FF_CMP_RD* = 6
  FF_CMP_ZERO* = 7
  FF_CMP_VSAD* = 8
  FF_CMP_VSSE* = 9
  FF_CMP_NSSE* = 10
  FF_CMP_W53* = 11
  FF_CMP_W97* = 12
  FF_CMP_DCTMAX* = 13
  FF_CMP_DCT264* = 14
  FF_CMP_MEDIAN_SAD* = 15
  FF_CMP_CHROMA* = 256

  SLICE_FLAG_CODED_ORDER* = 0x00000001
  SLICE_FLAG_ALLOW_FIELD* = 0x00000002
  SLICE_FLAG_ALLOW_PLANE* = 0x00000004
  FF_MB_DECISION_SIMPLE* = 0
  FF_MB_DECISION_BITS* = 1
  FF_MB_DECISION_RD* = 2

when defined(FF_API_CODER_TYPE):
 const
   FF_CODER_TYPE_VLC* = 0
   FF_CODER_TYPE_AC* = 1
   FF_CODER_TYPE_RAW* = 2
   FF_CODER_TYPE_RLE* = 3

const
  FF_BUG_AUTODETECT* = 1
  FF_BUG_XVID_ILACE* = 4
  FF_BUG_UMP4* = 8
  FF_BUG_NO_PADDING* = 16
  FF_BUG_AMV* = 32
  FF_BUG_QPEL_CHROMA* = 64
  FF_BUG_STD_QPEL* = 128
  FF_BUG_QPEL_CHROMA2* = 256
  FF_BUG_DIRECT_BLOCKSIZE* = 512
  FF_BUG_EDGE* = 1024
  FF_BUG_HPEL_CHROMA* = 2048
  FF_BUG_DC_CLIP* = 4096
  FF_BUG_MS* = 8192
  FF_BUG_TRUNCATED* = 16384
  FF_BUG_IEDGE* = 32768

  FF_COMPLIANCE_VERY_STRICT* = 2
  FF_COMPLIANCE_STRICT* = 1
  FF_COMPLIANCE_NORMAL* = 0
  FF_COMPLIANCE_UNOFFICIAL* = -1
  FF_COMPLIANCE_EXPERIMENTAL* = -2

  FF_EC_GUESS_MVS* = 1
  FF_EC_DEBLOCK* = 2
  FF_EC_FAVOR_INTER* = 256

  FF_DEBUG_PICT_INFO* = 1
  FF_DEBUG_RC* = 2
  FF_DEBUG_BITSTREAM* = 4
  FF_DEBUG_MB_TYPE* = 8
  FF_DEBUG_QP* = 16

  FF_DEBUG_BUFFERS* = 0x00008000
  FF_DEBUG_THREADS* = 0x00010000
  FF_DEBUG_GREEN_MD* = 0x00800000
  FF_DEBUG_NOMC* = 0x01000000

  FF_DEBUG_DCT_COEFF* = 0x00000040
  FF_DEBUG_SKIP* = 0x00000080
  FF_DEBUG_STARTCODE* = 0x00000100
  FF_DEBUG_ER* = 0x00000400
  FF_DEBUG_MMCO* = 0x00000800
  FF_DEBUG_BUGS* = 0x00001000

when defined(FF_API_DEBUG_MV):
  const
    FF_DEBUG_VIS_QP* = 0x00002000
    FF_DEBUG_VIS_MB_TYPE* = 0x00004000

    ## *
    ##  debug
    ##  - encoding: Set by user.
    ##  - decoding: Set by user.
    ##
  const
    FF_DEBUG_VIS_MV_P_FOR* = 0x00000001
    FF_DEBUG_VIS_MV_B_FOR* = 0x00000002
    FF_DEBUG_VIS_MV_B_BACK* = 0x00000004

const
  AV_EF_CRCCHECK* = (1 shl 0)
  AV_EF_BITSTREAM* = (1 shl 1) ## /< detect bitstream specification deviations
  AV_EF_BUFFER* = (1 shl 2)   ## /< detect improper bitstream length
  AV_EF_EXPLODE* = (1 shl 3)  ## /< abort decoding on minor error detection
  AV_EF_IGNORE_ERR* = (1 shl 15) ## /< ignore errors and continue
  AV_EF_CAREFUL* = (1 shl 16) ## /< consider things that violate the spec, are fast to calculate and have not been seen in the wild as errors
  AV_EF_COMPLIANT* = (1 shl 17) ## /< consider all spec non compliances as errors
  AV_EF_AGGRESSIVE* = (1 shl 18) ## /< consider things that a sane encoder should not do as an error

  FF_DCT_AUTO* = 0
  FF_DCT_FASTINT* = 1
  FF_DCT_INT* = 2
  FF_DCT_MMX* = 3
  FF_DCT_ALTIVEC* = 5
  FF_DCT_FAAN* = 6

  FF_IDCT_AUTO* = 0
  FF_IDCT_INT* = 1
  FF_IDCT_SIMPLE* = 2
  FF_IDCT_SIMPLEMMX* = 3
  FF_IDCT_ARM* = 7
  FF_IDCT_ALTIVEC* = 8
  FF_IDCT_SIMPLEARM* = 10
  FF_IDCT_XVID* = 14
  FF_IDCT_SIMPLEARMV5TE* = 16
  FF_IDCT_SIMPLEARMV6* = 17
  FF_IDCT_FAAN* = 20
  FF_IDCT_SIMPLENEON* = 22
  FF_IDCT_NONE* = 24
  FF_IDCT_SIMPLEAUTO* = 128

  FF_THREAD_FRAME* = 1
  FF_THREAD_SLICE* = 2

  FF_PROFILE_UNKNOWN* = -99
  FF_PROFILE_RESERVED* = -100
  FF_PROFILE_AAC_MAIN* = 0
  FF_PROFILE_AAC_LOW* = 1
  FF_PROFILE_AAC_SSR* = 2
  FF_PROFILE_AAC_LTP* = 3
  FF_PROFILE_AAC_HE* = 4
  FF_PROFILE_AAC_HE_V2* = 28
  FF_PROFILE_AAC_LD* = 22
  FF_PROFILE_AAC_ELD* = 38
  FF_PROFILE_MPEG2_AAC_LOW* = 128
  FF_PROFILE_MPEG2_AAC_HE* = 131
  FF_PROFILE_DNXHD* = 0
  FF_PROFILE_DNXHR_LB* = 1
  FF_PROFILE_DNXHR_SQ* = 2
  FF_PROFILE_DNXHR_HQ* = 3
  FF_PROFILE_DNXHR_HQX* = 4
  FF_PROFILE_DNXHR_444* = 5
  FF_PROFILE_DTS* = 20
  FF_PROFILE_DTS_ES* = 30
  FF_PROFILE_DTS_96_24* = 40
  FF_PROFILE_DTS_HD_HRA* = 50
  FF_PROFILE_DTS_HD_MA* = 60
  FF_PROFILE_DTS_EXPRESS* = 70
  FF_PROFILE_MPEG2_422* = 0
  FF_PROFILE_MPEG2_HIGH* = 1
  FF_PROFILE_MPEG2_SS* = 2
  FF_PROFILE_MPEG2_SNR_SCALABLE* = 3
  FF_PROFILE_MPEG2_MAIN* = 4
  FF_PROFILE_MPEG2_SIMPLE* = 5
  FF_PROFILE_H264_CONSTRAINED* = (1 shl 9) ##  8+1; constraint_set1_flag
  FF_PROFILE_H264_INTRA* = (1 shl 11) ##  8+3; constraint_set3_flag
  FF_PROFILE_H264_BASELINE* = 66
  FF_PROFILE_H264_CONSTRAINED_BASELINE* = (66 or FF_PROFILE_H264_CONSTRAINED)
  FF_PROFILE_H264_MAIN* = 77
  FF_PROFILE_H264_EXTENDED* = 88
  FF_PROFILE_H264_HIGH* = 100
  FF_PROFILE_H264_HIGH_10* = 110
  FF_PROFILE_H264_HIGH_10_INTRA* = (110 or FF_PROFILE_H264_INTRA)
  FF_PROFILE_H264_MULTIVIEW_HIGH* = 118
  FF_PROFILE_H264_HIGH_422* = 122
  FF_PROFILE_H264_HIGH_422_INTRA* = (122 or FF_PROFILE_H264_INTRA)
  FF_PROFILE_H264_STEREO_HIGH* = 128
  FF_PROFILE_H264_HIGH_444* = 144
  FF_PROFILE_H264_HIGH_444_PREDICTIVE* = 244
  FF_PROFILE_H264_HIGH_444_INTRA* = (244 or FF_PROFILE_H264_INTRA)
  FF_PROFILE_H264_CAVLC_444* = 44
  FF_PROFILE_VC1_SIMPLE* = 0
  FF_PROFILE_VC1_MAIN* = 1
  FF_PROFILE_VC1_COMPLEX* = 2
  FF_PROFILE_VC1_ADVANCED* = 3
  FF_PROFILE_MPEG4_SIMPLE* = 0
  FF_PROFILE_MPEG4_SIMPLE_SCALABLE* = 1
  FF_PROFILE_MPEG4_CORE* = 2
  FF_PROFILE_MPEG4_MAIN* = 3
  FF_PROFILE_MPEG4_N_BIT* = 4
  FF_PROFILE_MPEG4_SCALABLE_TEXTURE* = 5
  FF_PROFILE_MPEG4_SIMPLE_FACE_ANIMATION* = 6
  FF_PROFILE_MPEG4_BASIC_ANIMATED_TEXTURE* = 7
  FF_PROFILE_MPEG4_HYBRID* = 8
  FF_PROFILE_MPEG4_ADVANCED_REAL_TIME* = 9
  FF_PROFILE_MPEG4_CORE_SCALABLE* = 10
  FF_PROFILE_MPEG4_ADVANCED_CODING* = 11
  FF_PROFILE_MPEG4_ADVANCED_CORE* = 12
  FF_PROFILE_MPEG4_ADVANCED_SCALABLE_TEXTURE* = 13
  FF_PROFILE_MPEG4_SIMPLE_STUDIO* = 14
  FF_PROFILE_MPEG4_ADVANCED_SIMPLE* = 15
  FF_PROFILE_JPEG2000_CSTREAM_RESTRICTION_0* = 1
  FF_PROFILE_JPEG2000_CSTREAM_RESTRICTION_1* = 2
  FF_PROFILE_JPEG2000_CSTREAM_NO_RESTRICTION* = 32768
  FF_PROFILE_JPEG2000_DCINEMA_2K* = 3
  FF_PROFILE_JPEG2000_DCINEMA_4K* = 4
  FF_PROFILE_VP9_0* = 0
  FF_PROFILE_VP9_1* = 1
  FF_PROFILE_VP9_2* = 2
  FF_PROFILE_VP9_3* = 3
  FF_PROFILE_HEVC_MAIN* = 1
  FF_PROFILE_HEVC_MAIN_10* = 2
  FF_PROFILE_HEVC_MAIN_STILL_PICTURE* = 3
  FF_PROFILE_HEVC_REXT* = 4
  FF_PROFILE_AV1_MAIN* = 0
  FF_PROFILE_AV1_HIGH* = 1
  FF_PROFILE_AV1_PROFESSIONAL* = 2
  FF_PROFILE_MJPEG_HUFFMAN_BASELINE_DCT* = 0x000000C0
  FF_PROFILE_MJPEG_HUFFMAN_EXTENDED_SEQUENTIAL_DCT* = 0x000000C1
  FF_PROFILE_MJPEG_HUFFMAN_PROGRESSIVE_DCT* = 0x000000C2
  FF_PROFILE_MJPEG_HUFFMAN_LOSSLESS* = 0x000000C3
  FF_PROFILE_MJPEG_JPEG_LS* = 0x000000F7
  FF_PROFILE_SBC_MSBC* = 1
  FF_PROFILE_PRORES_PROXY* = 0
  FF_PROFILE_PRORES_LT* = 1
  FF_PROFILE_PRORES_STANDARD* = 2
  FF_PROFILE_PRORES_HQ* = 3
  FF_PROFILE_PRORES_4444* = 4
  FF_PROFILE_PRORES_XQ* = 5
  FF_PROFILE_ARIB_PROFILE_A* = 0
  FF_PROFILE_ARIB_PROFILE_C* = 1

  FF_LEVEL_UNKNOWN* = -99

  FF_SUB_CHARENC_MODE_DO_NOTHING* = -1
  FF_SUB_CHARENC_MODE_AUTOMATIC* = 0
  FF_SUB_CHARENC_MODE_PRE_DECODER* = 1
  FF_SUB_CHARENC_MODE_IGNORE* = 2

#when defined(FF_API_DEBUG_MV) and not (FF_API_DEBUG_MV == 0):
when not defined(FF_API_DEBUG_MV):
  const
    FF_DEBUG_VIS_MV_P_FOR* = 0x00000001
    FF_DEBUG_VIS_MV_B_FOR* = 0x00000002
    FF_DEBUG_VIS_MV_B_BACK* = 0x00000004
      ## *
      ##  debug motion vectors
      ##  - encoding: Set by user.
      ##  - decoding: Set by user.
      ##

const
  FF_CODEC_PROPERTY_LOSSLESS* = 0x00000001
  FF_CODEC_PROPERTY_CLOSED_CAPTIONS* = 0x00000002

  FF_SUB_TEXT_FMT_ASS* = 0

type
  AVCodecHWConfig* {.avcodec.} = object
    pix_fmt*: AVPixelFormat    ## *
                          ##  A hardware pixel format which the codec can use.
                          ##
    ## *
    ##  Bit set of AV_CODEC_HW_CONFIG_METHOD_* flags, describing the possible
    ##  setup methods which can be used with this configuration.
    ##
    methods*: cint ## *
                 ##  The device type associated with the configuration.
                 ##
                 ##  Must be set for AV_CODEC_HW_CONFIG_METHOD_HW_DEVICE_CTX and
                 ##  AV_CODEC_HW_CONFIG_METHOD_HW_FRAMES_CTX, otherwise unused.
                 ##
    deviceype*: AVHWDeviceType




when FF_API_CODEC_GET_SET:
  ## *
  ##  Accessors for some AVCodecContext fields. These used to be provided for ABI
  ##  compatibility, and do not need to be used anymore.
  ##
  ## attribute_deprecated
  proc av_codec_get_pktimebase*(avctx: ptr AVCodecContext): AVRational
  ## attribute_deprecated
  proc av_codec_set_pktimebase*(avctx: ptr AVCodecContext; val: AVRational)
  ## attribute_deprecated
  proc av_codec_get_codec_descriptor*(avctx: ptr AVCodecContext): ptr AVCodecDescriptor
  ## attribute_deprecated
  proc av_codec_set_codec_descriptor*(avctx: ptr AVCodecContext;
                                     desc: ptr AVCodecDescriptor)
  ## attribute_deprecated
  proc av_codec_get_codec_properties*(avctx: ptr AVCodecContext): cuint
  when FF_API_LOWRES:
    ## attribute_deprecated
    proc av_codec_get_lowres*(avctx: ptr AVCodecContext): cint
    ## attribute_deprecated
    proc av_codec_set_lowres*(avctx: ptr AVCodecContext; val: cint)
  ## attribute_deprecated
  proc av_codec_get_seek_preroll*(avctx: ptr AVCodecContext): cint
  ## attribute_deprecated
  proc av_codec_set_seek_preroll*(avctx: ptr AVCodecContext; val: cint)
  ## attribute_deprecated
  proc av_codec_get_chroma_intra_matrix*(avctx: ptr AVCodecContext): ptr uint16
  ## attribute_deprecated
  proc av_codec_set_chroma_intra_matrix*(avctx: ptr AVCodecContext;
                                        val: ptr uint16)
## *
##  AVProfile.
##


const ## *
     ##  The codec supports this format via the hw_device_ctx interface.
     ##
     ##  When selecting this format, AVCodecContext.hw_device_ctx should
     ##  have been set to a device of the specified type before calling
     ##  avcodec_open2().
     ##
  AV_CODEC_HW_CONFIG_METHOD_HW_DEVICE_CTX* = 0x00000001 ## *
                                                     ##  The codec supports this format via the hw_frames_ctx interface.
                                                     ##
                                                     ##  When selecting this format for a decoder,
                                                     ##  AVCodecContext.hw_frames_ctx should be set to a suitable frames
                                                     ##  context inside the get_format() callback.  The frames context
                                                     ##  must have been created on a device of the specified type.
                                                     ##
  AV_CODEC_HW_CONFIG_METHOD_HW_FRAMES_CTX* = 0x00000002 ## *
                                                     ##  The codec supports this format by some internal method.
                                                     ##
                                                     ##  This format can be selected without any additional configuration -
                                                     ##  no device or frames context is required.
                                                     ##
  AV_CODEC_HW_CONFIG_METHOD_INTERNAL* = 0x00000004 ## *
                                                ##  The codec supports this format by some ad-hoc method.
                                                ##
                                                ##  Additional settings and/or function calls are required.  See the
                                                ##  codec-specific documentation for details.  (Methods requiring
                                                ##  this sort of configuration are deprecated and others should be
                                                ##  used in preference.)
                                                ##
  AV_CODEC_HW_CONFIG_METHOD_AD_HOC* = 0x00000008



when FF_API_CODEC_GET_SET:
  ## attribute_deprecated
  proc av_codec_get_max_lowres*(codec: ptr AVCodec): cint


## *
##  Retrieve supported hardware configurations for a codec.
##
##  Values of index from zero to some maximum return the indexed configuration
##  descriptor; all other values return NULL.  If the codec does not support
##  any hardware configurations then it will always return NULL.
##

proc avcodec_get_hw_config*(codec: ptr AVCodec; index: cint): ptr AVCodecHWConfig
## *
##  @defgroup lavc_hwaccel AVHWAccel
##
##  @note  Nothing in this structure should be accessed by the user.  At some
##         point in future it will not be externally visible at all.
##
##  @{
##


## *
##  HWAccel is experimental and is thus avoided in favor of non experimental
##  codecs
##

const
  AV_HWACCEL_CODEC_CAP_EXPERIMENTAL* = 0x00000200

## *
##  Hardware acceleration should be used for decoding even if the codec level
##  used is unknown or higher than the maximum supported level reported by the
##  hardware driver.
##
##  It's generally a good idea to pass this flag unless you have a specific
##  reason not to, as hardware tends to under-report supported levels.
##

const
  AV_HWACCEL_FLAG_IGNORE_LEVEL* = (1 shl 0)

## *
##  Hardware acceleration can output YUV pixel formats with a different chroma
##  sampling than 4:2:0 and/or other than 8 bits per component.
##

const
  AV_HWACCEL_FLAG_ALLOW_HIGH_DEPTH* = (1 shl 1)

## *
##  Hardware acceleration should still be attempted for decoding when the
##  codec profile does not match the reported capabilities of the hardware.
##
##  For example, this can be used to try to decode baseline profile H.264
##  streams in hardware - it will often succeed, because many streams marked
##  as baseline profile actually conform to constrained baseline profile.
##
##  @warning If the stream is actually not supported then the behaviour is
##           undefined, and may include returning entirely incorrect output
##           while indicating success.
##

const
  AV_HWACCEL_FLAG_ALLOW_PROFILE_MISMATCH* = (1 shl 2)

## *
##  @}
##


const
  AV_SUBTITLE_FLAG_FORCED* = 0x00000001

## *
##  This struct describes the properties of an encoded stream.
##
##  sizeof(AVCodecParameters) is not a part of the public ABI, this struct must
##  be allocated with avcodec_parameters_alloc() and freed with
##  avcodec_parameters_free().
##


## *
##  Iterate over all registered codecs.
##
##  @param opaque a pointer where libavcodec will store the iteration state. Must
##                point to NULL to start the iteration.
##
##  @return the next registered codec or NULL when the iteration is
##          finished
##

proc av_codec_iterate*(opaque: ptr pointer): ptr AVCodec
when FF_API_NEXT:
  ## *
  ##  If c is NULL, returns the first registered codec,
  ##  if c is non-NULL, returns the next registered codec after c,
  ##  or NULL if c is the last one.
  ##
  ## attribute_deprecated
  proc av_codec_next*(c: ptr AVCodec): ptr AVCodec
## *
##  Return the LIBAVCODEC_VERSION_INT constant.
##

proc avcodec_version*(): cuint
## *
##  Return the libavcodec build-time configuration.
##

proc avcodec_configuration*(): cstring
## *
##  Return the libavcodec license.
##

proc avcodec_license*(): cstring
when FF_API_NEXT:
  ## *
  ##  Register the codec codec and initialize libavcodec.
  ##
  ##  @warning either this function or avcodec_register_all() must be called
  ##  before any other libavcodec functions.
  ##
  ##  @see avcodec_register_all()
  ##
  ## attribute_deprecated
  proc avcodec_register*(codec: ptr AVCodec)
  ## *
  ##  Register all the codecs, parsers and bitstream filters which were enabled at
  ##  configuration time. If you do not call this function you can select exactly
  ##  which formats you want to support, by using the individual registration
  ##  functions.
  ##
  ##  @see avcodec_register
  ##  @see av_register_codec_parser
  ##  @see av_register_bitstream_filter
  ##
  ## attribute_deprecated
  proc avcodec_register_all*()
## *
##  Allocate an AVCodecContext and set its fields to default values. The
##  resulting struct should be freed with avcodec_free_context().
##
##  @param codec if non-NULL, allocate private data and initialize defaults
##               for the given codec. It is illegal to then call avcodec_open2()
##               with a different codec.
##               If NULL, then the codec-specific defaults won't be initialized,
##               which may result in suboptimal default settings (this is
##               important mainly for encoders, e.g. libx264).
##
##  @return An AVCodecContext filled with default values or NULL on failure.
##

proc avcodec_alloc_context3*(codec: ptr AVCodec): ptr AVCodecContext
## *
##  Free the codec context and everything associated with it and write NULL to
##  the provided pointer.
##

proc avcodec_free_context*(avctx: ptr ptr AVCodecContext)
when FF_API_GET_CONTEXT_DEFAULTS:
  ## *
  ##  @deprecated This function should not be used, as closing and opening a codec
  ##  context multiple time is not supported. A new codec context should be
  ##  allocated for each new use.
  ##
  proc avcodec_get_context_defaults3*(s: ptr AVCodecContext; codec: ptr AVCodec): cint
    {.deprecated: "Should not be used, closing and opening a codec context not supported".}
## *
##  Get the AVClass for AVCodecContext. It can be used in combination with
##  AV_OPT_SEARCH_FAKE_OBJ for examining options.
##
##  @see av_opt_find().
##

proc avcodec_get_class*(): ptr AVClass
when FF_API_COPY_CONTEXT:
  ## *
  ##  Get the AVClass for AVFrame. It can be used in combination with
  ##  AV_OPT_SEARCH_FAKE_OBJ for examining options.
  ##
  ##  @see av_opt_find().
  ##
  proc avcodec_get_frame_class*(): ptr AVClass
  ## *
  ##  Get the AVClass for AVSubtitleRect. It can be used in combination with
  ##  AV_OPT_SEARCH_FAKE_OBJ for examining options.
  ##
  ##  @see av_opt_find().
  ##
  proc avcodec_get_subtitle_rect_class*(): ptr AVClass
  ## *
  ##  Copy the settings of the source AVCodecContext into the destination
  ##  AVCodecContext. The resulting destination codec context will be
  ##  unopened, i.e. you are required to call avcodec_open2() before you
  ##  can use this AVCodecContext to decode/encode video/audio data.
  ##
  ##  @param dest target codec context, should be initialized with
  ##              avcodec_alloc_context3(NULL), but otherwise uninitialized
  ##  @param src source codec context
  ##  @return AVERROR() on error (e.g. memory allocation error), 0 on success
  ##
  ##  @deprecated The semantics of this function are ill-defined and it should not
  ##  be used. If you need to transfer the stream parameters from one codec context
  ##  to another, use an intermediate AVCodecParameters instance and the
  ##  avcodec_parameters_from_context() / avcodec_parameterso_context()
  ##  functions.
  ##
  ## attribute_deprecated
  proc avcodec_copy_context*(dest: ptr AVCodecContext; src: ptr AVCodecContext): cint
    {.deprecated: "should not be used".}
## *
##  Allocate a new AVCodecParameters and set its fields to default values
##  (unknown/invalid/0). The returned struct must be freed with
##  avcodec_parameters_free().
##

proc avcodec_parameters_alloc*(): ptr AVCodecParameters
## *
##  Free an AVCodecParameters instance and everything associated with it and
##  write NULL to the supplied pointer.
##

proc avcodec_parameters_free*(par: ptr ptr AVCodecParameters)
## *
##  Copy the contents of src to dst. Any allocated fields in dst are freed and
##  replaced with newly allocated duplicates of the corresponding fields in src.
##
##  @return >= 0 on success, a negative AVERROR code on failure.
##

proc avcodec_parameters_copy*(dst: ptr AVCodecParameters; src: ptr AVCodecParameters): cint
## *
##  Fill the parameters struct based on the values from the supplied codec
##  context. Any allocated fields in par are freed and replaced with duplicates
##  of the corresponding fields in codec.
##
##  @return >= 0 on success, a negative AVERROR code on failure
##

proc avcodec_parameters_from_context*(par: ptr AVCodecParameters;
                                     codec: ptr AVCodecContext): cint
## *
##  Fill the codec context based on the values from the supplied codec
##  parameters. Any allocated fields in codec that have a corresponding field in
##  par are freed and replaced with duplicates of the corresponding field in par.
##  Fields in codec that do not have a counterpart in par are not touched.
##
##  @return >= 0 on success, a negative AVERROR code on failure.
##

proc avcodec_parameters_to_context*(codec: ptr AVCodecContext;
                                   par: ptr AVCodecParameters): cint
## *
##  Initialize the AVCodecContext to use the given AVCodec. Prior to using this
##  function the context has to be allocated with avcodec_alloc_context3().
##
##  The functions avcodec_find_decoder_by_name(), avcodec_find_encoder_by_name(),
##  avcodec_find_decoder() and avcodec_find_encoder() provide an easy way for
##  retrieving a codec.
##
##  @warning This function is not thread safe!
##
##  @note Always call this function before using decoding routines (such as
##  @ref avcodec_receive_frame()).
##
##  @code
##  avcodec_register_all();
##  av_dict_set(&opts, "b", "2.5M", 0);
##  codec = avcodec_find_decoder(AV_CODEC_ID_H264);
##  if (!codec)
##      exit(1);
##
##  context = avcodec_alloc_context3(codec);
##
##  if (avcodec_open2(context, codec, opts) < 0)
##      exit(1);
##  @endcode
##
##  @param avctx The context to initialize.
##  @param codec The codec to open this context for. If a non-NULL codec has been
##               previously passed to avcodec_alloc_context3() or
##               for this context, then this parameter MUST be either NULL or
##               equal to the previously passed codec.
##  @param options A dictionary filled with AVCodecContext and codec-private options.
##                 On return this object will be filled with options that were not found.
##
##  @return zero on success, a negative value on error
##  @see avcodec_alloc_context3(), avcodec_find_decoder(), avcodec_find_encoder(),
##       av_dict_set(), av_opt_find().
##

proc avcodec_open2*(avctx: ptr AVCodecContext; codec: ptr AVCodec;
                   options: ptr ptr AVDictionary): cint
## *
##  Close a given AVCodecContext and free all the data associated with it
##  (but not the AVCodecContext itself).
##
##  Calling this function on an AVCodecContext that hasn't been opened will free
##  the codec-specific data allocated in avcodec_alloc_context3() with a non-NULL
##  codec. Subsequent calls will do nothing.
##
##  @note Do not use this function. Use avcodec_free_context() to destroy a
##  codec context (either open or closed). Opening and closing a codec context
##  multiple times is not supported anymore -- use multiple codec contexts
##  instead.
##

proc avcodec_close*(avctx: ptr AVCodecContext): cint
## *
##  Free all allocated data in the given subtitle struct.
##
##  @param sub AVSubtitle to free.
##

proc avsubtitle_free*(sub: ptr AVSubtitle)
## *
##  @}
##
## *
##  @addtogroup lavc_packet
##  @{
##
## *
##  Allocate an AVPacket and set its fields to default values.  The resulting
##  struct must be freed using av_packet_free().
##
##  @return An AVPacket filled with default values or NULL on failure.
##
##  @note this only allocates the AVPacket itself, not the data buffers. Those
##  must be allocated through other means such as av_new_packet.
##
##  @see av_new_packet
##

proc av_packet_alloc*(): ptr AVPacket
## *
##  Create a new packet that references the same data as src.
##
##  This is a shortcut for av_packet_alloc()+av_packet_ref().
##
##  @return newly created AVPacket on success, NULL on error.
##
##  @see av_packet_alloc
##  @see av_packet_ref
##

proc av_packet_clone*(src: ptr AVPacket): ptr AVPacket
## *
##  Free the packet, if the packet is reference counted, it will be
##  unreferenced first.
##
##  @param pkt packet to be freed. The pointer will be set to NULL.
##  @note passing NULL is a no-op.
##

proc av_packet_free*(pkt: ptr ptr AVPacket)
## *
##  Initialize optional fields of a packet with default values.
##
##  Note, this does not touch the data and size members, which have to be
##  initialized separately.
##
##  @param pkt packet
##

proc av_init_packet*(pkt: ptr AVPacket)
## *
##  Allocate the payload of a packet and initialize its fields with
##  default values.
##
##  @param pkt packet
##  @param size wanted payload size
##  @return 0 if OK, AVERROR_xxx otherwise
##

proc av_new_packet*(pkt: ptr AVPacket; size: cint): cint
## *
##  Reduce packet size, correctly zeroing padding
##
##  @param pkt packet
##  @param size new size
##

proc av_shrink_packet*(pkt: ptr AVPacket; size: cint)
## *
##  Increase packet size, correctly zeroing padding
##
##  @param pkt packet
##  @param grow_by number of bytes by which to increase the size of the packet
##

proc av_grow_packet*(pkt: ptr AVPacket; grow_by: cint): cint
## *
##  Initialize a reference-counted packet from av_malloc()ed data.
##
##  @param pkt packet to be initialized. This function will set the data, size,
##         and buf fields, all others are left untouched.
##  @param data Data allocated by av_malloc() to be used as packet data. If this
##         function returns successfully, the data is owned by the underlying AVBuffer.
##         The caller may not access the data through other means.
##  @param size size of data in bytes, without the padding. I.e. the full buffer
##         size is assumed to be size + AV_INPUT_BUFFER_PADDING_SIZE.
##
##  @return 0 on success, a negative AVERROR on error
##

proc av_packet_from_data*(pkt: ptr AVPacket; data: ptr uint8; size: cint): cint
when FF_API_AVPACKET_OLD_API:
  ## *
  ##  @warning This is a hack - the packet memory allocation stuff is broken. The
  ##  packet is allocated if it was not really allocated.
  ##
  ##  @deprecated Use av_packet_ref or av_packet_make_refcounted
  ##
  ## attribute_deprecated
  proc av_dup_packet*(pkt: ptr AVPacket): cint
    {.deprecated: "Use av_packet_ref or av_packet_make_refcounted".}
  ## *
  ##  Copy packet, including contents
  ##
  ##  @return 0 on success, negative AVERROR on fail
  ##
  ##  @deprecated Use av_packet_ref
  ##
  ## attribute_deprecated
  proc av_copy_packet*(dst: ptr AVPacket; src: ptr AVPacket): cint
    {.deprecated: "Use av_packet_ref".}
  ## *
  ##  Copy packet side data
  ##
  ##  @return 0 on success, negative AVERROR on fail
  ##
  ##  @deprecated Use av_packet_copy_props
  ##
  ## attribute_deprecated
  proc av_copy_packet_side_data*(dst: ptr AVPacket; src: ptr AVPacket): cint
    {.deprecated: "Use av_packet_copy_props".}
  ## *
  ##  Free a packet.
  ##
  ##  @deprecated Use av_packet_unref
  ##
  ##  @param pkt packet to free
  ##
  ## attribute_deprecated
  proc av_free_packet*(pkt: ptr AVPacket)
    {.deprecated: "Use av_packet_unref".}
## *
##  Allocate new information of a packet.
##
##  @param pkt packet
##  @param type side information type
##  @param size side information size
##  @return pointer to fresh allocated data or NULL otherwise
##

proc av_packet_new_side_data*(pkt: ptr AVPacket; `type`: AVPacketSideDataType;
                             size: cint): ptr uint8
## *
##  Wrap an existing array as a packet side data.
##
##  @param pkt packet
##  @param type side information type
##  @param data the side data array. It must be allocated with the av_malloc()
##              family of functions. The ownership of the data is transferred to
##              pkt.
##  @param size side information size
##  @return a non-negative number on success, a negative AVERROR code on
##          failure. On failure, the packet is unchanged and the data remains
##          owned by the caller.
##

proc av_packet_add_side_data*(pkt: ptr AVPacket; `type`: AVPacketSideDataType;
                             data: ptr uint8; size: csize): cint
## *
##  Shrink the already allocated side data buffer
##
##  @param pkt packet
##  @param type side information type
##  @param size new side information size
##  @return 0 on success, < 0 on failure
##

proc av_packet_shrink_side_data*(pkt: ptr AVPacket; `type`: AVPacketSideDataType;
                                size: cint): cint
## *
##  Get side information from packet.
##
##  @param pkt packet
##  @param type desired side information type
##  @param size pointer for side information size to store (optional)
##  @return pointer to data if present or NULL otherwise
##

proc av_packet_get_side_data*(pkt: ptr AVPacket; `type`: AVPacketSideDataType;
                             size: ptr cint): ptr uint8
when FF_API_MERGE_SD_API:
  ## attribute_deprecated
  proc av_packet_merge_side_data*(pkt: ptr AVPacket): cint
  ## attribute_deprecated
  proc av_packet_split_side_data*(pkt: ptr AVPacket): cint
proc av_packet_side_data_name*(`type`: AVPacketSideDataType): cstring
## *
##  Pack a dictionary for use in side_data.
##
##  @param dict The dictionary to pack.
##  @param size pointer to store the size of the returned data
##  @return pointer to data if successful, NULL otherwise
##

proc av_packet_pack_dictionary*(dict: ptr AVDictionary; size: ptr cint): ptr uint8
## *
##  Unpack a dictionary from side_data.
##
##  @param data data from side_data
##  @param size size of the data
##  @param dict the metadata storage dictionary
##  @return 0 on success, < 0 on failure
##

proc av_packet_unpack_dictionary*(data: ptr uint8; size: cint;
                                 dict: ptr ptr AVDictionary): cint
## *
##  Convenience function to free all the side data stored.
##  All the other fields stay untouched.
##
##  @param pkt packet
##

proc av_packet_free_side_data*(pkt: ptr AVPacket)
## *
##  Setup a new reference to the data described by a given packet
##
##  If src is reference-counted, setup dst as a new reference to the
##  buffer in src. Otherwise allocate a new buffer in dst and copy the
##  data from src into it.
##
##  All the other fields are copied from src.
##
##  @see av_packet_unref
##
##  @param dst Destination packet
##  @param src Source packet
##
##  @return 0 on success, a negative AVERROR on error.
##

proc av_packet_ref*(dst: ptr AVPacket; src: ptr AVPacket): cint
## *
##  Wipe the packet.
##
##  Unreference the buffer referenced by the packet and reset the
##  remaining packet fields to their default values.
##
##  @param pkt The packet to be unreferenced.
##

proc av_packet_unref*(pkt: ptr AVPacket)
## *
##  Move every field in src to dst and reset src.
##
##  @see av_packet_unref
##
##  @param src Source packet, will be reset
##  @param dst Destination packet
##

proc av_packet_move_ref*(dst: ptr AVPacket; src: ptr AVPacket)
## *
##  Copy only "properties" fields from src to dst.
##
##  Properties for the purpose of this function are all the fields
##  beside those related to the packet data (buf, data, size)
##
##  @param dst Destination packet
##  @param src Source packet
##
##  @return 0 on success AVERROR on failure.
##

proc av_packet_copy_props*(dst: ptr AVPacket; src: ptr AVPacket): cint
## *
##  Ensure the data described by a given packet is reference counted.
##
##  @note This function does not ensure that the reference will be writable.
##        Use av_packet_make_writable instead for that purpose.
##
##  @see av_packet_ref
##  @see av_packet_make_writable
##
##  @param pkt packet whose data should be made reference counted.
##
##  @return 0 on success, a negative AVERROR on error. On failure, the
##          packet is unchanged.
##

proc av_packet_make_refcounted*(pkt: ptr AVPacket): cint
## *
##  Create a writable reference for the data described by a given packet,
##  avoiding data copy if possible.
##
##  @param pkt Packet whose data should be made writable.
##
##  @return 0 on success, a negative AVERROR on failure. On failure, the
##          packet is unchanged.
##

proc av_packet_make_writable*(pkt: ptr AVPacket): cint
## *
##  Convert valid timing fields (timestamps / durations) in a packet from one
##  timebase to another. Timestamps with unknown values (AV_NOPTS_VALUE) will be
##  ignored.
##
##  @param pkt packet on which the conversion will be performed
##  @param tb_src source timebase, in which the timing fields in pkt are
##                expressed
##  @param tb_dst destination timebase, to which the timing fields will be
##                converted
##

proc av_packet_rescales*(pkt: ptr AVPacket; tb_src: AVRational; tb_dst: AVRational)
## *
##  @}
##
## *
##  @addtogroup lavc_decoding
##  @{
##
## *
##  Find a registered decoder with a matching codec ID.
##
##  @param id AVCodecID of the requested decoder
##  @return A decoder if one was found, NULL otherwise.
##

proc avcodec_find_decoder*(id: AVCodecID): ptr AVCodec
## *
##  Find a registered decoder with the specified name.
##
##  @param name name of the requested decoder
##  @return A decoder if one was found, NULL otherwise.
##

proc avcodec_find_decoder_by_name*(name: cstring): ptr AVCodec
## *
##  The default callback for AVCodecContext.get_buffer2(). It is made public so
##  it can be called by custom get_buffer2() implementations for decoders without
##  AV_CODEC_CAP_DR1 set.
##

proc avcodec_default_get_buffer2*(s: ptr AVCodecContext; frame: ptr AVFrame;
                                 flags: cint): cint
## *
##  Modify width and height values so that they will result in a memory
##  buffer that is acceptable for the codec if you do not use any horizontal
##  padding.
##
##  May only be used if a codec with AV_CODEC_CAP_DR1 has been opened.
##

proc avcodec_align_dimensions*(s: ptr AVCodecContext; width: ptr cint; height: ptr cint)
## *
##  Modify width and height values so that they will result in a memory
##  buffer that is acceptable for the codec if you also ensure that all
##  line sizes are a multiple of the respective linesize_align[i].
##
##  May only be used if a codec with AV_CODEC_CAP_DR1 has been opened.
##

proc avcodec_align_dimensions2*(s: ptr AVCodecContext; width: ptr cint;
                               height: ptr cint; linesize_align: array[
    AV_NUM_DATA_POINTERS, cint])
## *
##  Converts AVChromaLocation to swscale x/y chroma position.
##
##  The positions represent the chroma (0,0) position in a coordinates system
##  with luma (0,0) representing the origin and luma(1,1) representing 256,256
##
##  @param xpos  horizontal chroma sample position
##  @param ypos  vertical   chroma sample position
##

proc avcodec_enumo_chroma_pos*(xpos: ptr cint; ypos: ptr cint; pos: AVChromaLocation): cint
## *
##  Converts swscale x/y chroma position to AVChromaLocation.
##
##  The positions represent the chroma (0,0) position in a coordinates system
##  with luma (0,0) representing the origin and luma(1,1) representing 256,256
##
##  @param xpos  horizontal chroma sample position
##  @param ypos  vertical   chroma sample position
##

proc avcodec_chroma_poso_enum*(xpos, ypos: cint): AVChromaLocation
## *
##  Decode the audio frame of size avpkt->size from avpkt->data into frame.
##
##  Some decoders may support multiple frames in a single AVPacket. Such
##  decoders would then just decode the first frame and the return value would be
##  less than the packet size. In this case, avcodec_decode_audio4 has to be
##  called again with an AVPacket containing the remaining data in order to
##  decode the second frame, etc...  Even if no frames are returned, the packet
##  needs to be fed to the decoder with remaining data until it is completely
##  consumed or an error occurs.
##
##  Some decoders (those marked with AV_CODEC_CAP_DELAY) have a delay between input
##  and output. This means that for some packets they will not immediately
##  produce decoded output and need to be flushed at the end of decoding to get
##  all the decoded data. Flushing is done by calling this function with packets
##  with avpkt->data set to NULL and avpkt->size set to 0 until it stops
##  returning samples. It is safe to flush even those decoders that are not
##  marked with AV_CODEC_CAP_DELAY, then no samples will be returned.
##
##  @warning The input buffer, avpkt->data must be AV_INPUT_BUFFER_PADDING_SIZE
##           larger than the actual read bytes because some optimized bitstream
##           readers read 32 or 64 bits at once and could read over the end.
##
##  @note The AVCodecContext MUST have been opened with @ref avcodec_open2()
##  before packets may be fed to the decoder.
##
##  @param      avctx the codec context
##  @param[out] frame The AVFrame in which to store decoded audio samples.
##                    The decoder will allocate a buffer for the decoded frame by
##                    calling the AVCodecContext.get_buffer2() callback.
##                    When AVCodecContext.refcounted_frames is set to 1, the frame is
##                    reference counted and the returned reference belongs to the
##                    caller. The caller must release the frame using av_frame_unref()
##                    when the frame is no longer needed. The caller may safely write
##                    to the frame if av_frame_is_writable() returns 1.
##                    When AVCodecContext.refcounted_frames is set to 0, the returned
##                    reference belongs to the decoder and is valid only until the
##                    next call to this function or until closing or flushing the
##                    decoder. The caller may not write to it.
##  @param[out] got_frame_ptr Zero if no frame could be decoded, otherwise it is
##                            non-zero. Note that this field being set to zero
##                            does not mean that an error has occurred. For
##                            decoders with AV_CODEC_CAP_DELAY set, no given decode
##                            call is guaranteed to produce a frame.
##  @param[in]  avpkt The input AVPacket containing the input buffer.
##                    At least avpkt->data and avpkt->size should be set. Some
##                    decoders might also require additional fields to be set.
##  @return A negative error code is returned if an error occurred during
##          decoding, otherwise the number of bytes consumed from the input
##          AVPacket is returned.
##
##  @deprecated Use avcodec_send_packet() and avcodec_receive_frame().
##
## attribute_deprecated

proc avcodec_decode_audio4*(avctx: ptr AVCodecContext; frame: ptr AVFrame;
                           got_frame_ptr: ptr cint; avpkt: ptr AVPacket): cint
  {.deprecated: "use pair of avcodec_send_packet and avcodec_receive_frame".}
## *
##  Decode the video frame of size avpkt->size from avpkt->data into picture.
##  Some decoders may support multiple frames in a single AVPacket, such
##  decoders would then just decode the first frame.
##
##  @warning The input buffer must be AV_INPUT_BUFFER_PADDING_SIZE larger than
##  the actual read bytes because some optimized bitstream readers read 32 or 64
##  bits at once and could read over the end.
##
##  @warning The end of the input buffer buf should be set to 0 to ensure that
##  no overreading happens for damaged MPEG streams.
##
##  @note Codecs which have the AV_CODEC_CAP_DELAY capability set have a delay
##  between input and output, these need to be fed with avpkt->data=NULL,
##  avpkt->size=0 at the end to return the remaining frames.
##
##  @note The AVCodecContext MUST have been opened with @ref avcodec_open2()
##  before packets may be fed to the decoder.
##
##  @param avctx the codec context
##  @param[out] picture The AVFrame in which the decoded video frame will be stored.
##              Use av_frame_alloc() to get an AVFrame. The codec will
##              allocate memory for the actual bitmap by calling the
##              AVCodecContext.get_buffer2() callback.
##              When AVCodecContext.refcounted_frames is set to 1, the frame is
##              reference counted and the returned reference belongs to the
##              caller. The caller must release the frame using av_frame_unref()
##              when the frame is no longer needed. The caller may safely write
##              to the frame if av_frame_is_writable() returns 1.
##              When AVCodecContext.refcounted_frames is set to 0, the returned
##              reference belongs to the decoder and is valid only until the
##              next call to this function or until closing or flushing the
##              decoder. The caller may not write to it.
##
##  @param[in] avpkt The input AVPacket containing the input buffer.
##             You can create such packet with av_init_packet() and by then setting
##             data and size, some decoders might in addition need other fields like
##             flags&AV_PKT_FLAG_KEY. All decoders are designed to use the least
##             fields possible.
##  @param[in,out] got_picture_ptr Zero if no frame could be decompressed, otherwise, it is nonzero.
##  @return On error a negative value is returned, otherwise the number of bytes
##  used or zero if no frame could be decompressed.
##
##  @deprecated Use avcodec_send_packet() and avcodec_receive_frame().
##
## attribute_deprecated

proc avcodec_decode_video2*(avctx: ptr AVCodecContext; picture: ptr AVFrame;
                           got_picture_ptr: ptr cint; avpkt: ptr AVPacket): cint
  {.deprecated: "use pair of avcodec_send_packet and avcodec_receive_frame".}
## *
##  Decode a subtitle message.
##  Return a negative value on error, otherwise return the number of bytes used.
##  If no subtitle could be decompressed, got_sub_ptr is zero.
##  Otherwise, the subtitle is stored in *sub.
##  Note that AV_CODEC_CAP_DR1 is not available for subtitle codecs. This is for
##  simplicity, because the performance difference is expect to be negligible
##  and reusing a get_buffer written for video codecs would probably perform badly
##  due to a potentially very different allocation pattern.
##
##  Some decoders (those marked with AV_CODEC_CAP_DELAY) have a delay between input
##  and output. This means that for some packets they will not immediately
##  produce decoded output and need to be flushed at the end of decoding to get
##  all the decoded data. Flushing is done by calling this function with packets
##  with avpkt->data set to NULL and avpkt->size set to 0 until it stops
##  returning subtitles. It is safe to flush even those decoders that are not
##  marked with AV_CODEC_CAP_DELAY, then no subtitles will be returned.
##
##  @note The AVCodecContext MUST have been opened with @ref avcodec_open2()
##  before packets may be fed to the decoder.
##
##  @param avctx the codec context
##  @param[out] sub The Preallocated AVSubtitle in which the decoded subtitle will be stored,
##                  must be freed with avsubtitle_free if *got_sub_ptr is set.
##  @param[in,out] got_sub_ptr Zero if no subtitle could be decompressed, otherwise, it is nonzero.
##  @param[in] avpkt The input AVPacket containing the input buffer.
##

proc avcodec_decode_subtitle2*(avctx: ptr AVCodecContext; sub: ptr AVSubtitle;
                              got_sub_ptr: ptr cint; avpkt: ptr AVPacket): cint
## *
##  Supply raw packet data as input to a decoder.
##
##  Internally, this call will copy relevant AVCodecContext fields, which can
##  influence decoding per-packet, and apply them when the packet is actually
##  decoded. (For example AVCodecContext.skip_frame, which might direct the
##  decoder to drop the frame contained by the packet sent with this function.)
##
##  @warning The input buffer, avpkt->data must be AV_INPUT_BUFFER_PADDING_SIZE
##           larger than the actual read bytes because some optimized bitstream
##           readers read 32 or 64 bits at once and could read over the end.
##
##  @warning Do not mix this API with the legacy API (like avcodec_decode_video2())
##           on the same AVCodecContext. It will return unexpected results now
##           or in future libavcodec versions.
##
##  @note The AVCodecContext MUST have been opened with @ref avcodec_open2()
##        before packets may be fed to the decoder.
##
##  @param avctx codec context
##  @param[in] avpkt The input AVPacket. Usually, this will be a single video
##                   frame, or several complete audio frames.
##                   Ownership of the packet remains with the caller, and the
##                   decoder will not write to the packet. The decoder may create
##                   a reference to the packet data (or copy it if the packet is
##                   not reference-counted).
##                   Unlike with older APIs, the packet is always fully consumed,
##                   and if it contains multiple frames (e.g. some audio codecs),
##                   will require you to call avcodec_receive_frame() multiple
##                   times afterwards before you can send a new packet.
##                   It can be NULL (or an AVPacket with data set to NULL and
##                   size set to 0); in this case, it is considered a flush
##                   packet, which signals the end of the stream. Sending the
##                   first flush packet will return success. Subsequent ones are
##                   unnecessary and will return AVERROR_EOF. If the decoder
##                   still has frames buffered, it will return them after sending
##                   a flush packet.
##
##  @return 0 on success, otherwise negative error code:
##       AVERROR(EAGAIN):   input is not accepted in the current state - user
##                          must read output with avcodec_receive_frame() (once
##                          all output is read, the packet should be resent, and
##                          the call will not fail with EAGAIN).
##       AVERROR_EOF:       the decoder has been flushed, and no new packets can
##                          be sent to it (also returned if more than 1 flush
##                          packet is sent)
##       AVERROR(EINVAL):   codec not opened, it is an encoder, or requires flush
##       AVERROR(ENOMEM):   failed to add packet to internal queue, or similar
##       other errors: legitimate decoding errors
##

proc avcodec_send_packet*(avctx: ptr AVCodecContext; avpkt: ptr AVPacket): cint
## *
##  Return decoded output data from a decoder.
##
##  @param avctx codec context
##  @param frame This will be set to a reference-counted video or audio
##               frame (depending on the decoder type) allocated by the
##               decoder. Note that the function will always call
##               av_frame_unref(frame) before doing anything else.
##
##  @return
##       0:                 success, a frame was returned
##       AVERROR(EAGAIN):   output is not available in this state - user must try
##                          to send new input
##       AVERROR_EOF:       the decoder has been fully flushed, and there will be
##                          no more output frames
##       AVERROR(EINVAL):   codec not opened, or it is an encoder
##       AVERROR_INPUT_CHANGED:   current decoded frame has changed parameters
##                                with respect to first decoded frame. Applicable
##                                when flag AV_CODEC_FLAG_DROPCHANGED is set.
##       other negative values: legitimate decoding errors
##

proc avcodec_receive_frame*(avctx: ptr AVCodecContext; frame: ptr AVFrame): cint
## *
##  Supply a raw video or audio frame to the encoder. Use avcodec_receive_packet()
##  to retrieve buffered output packets.
##
##  @param avctx     codec context
##  @param[in] frame AVFrame containing the raw audio or video frame to be encoded.
##                   Ownership of the frame remains with the caller, and the
##                   encoder will not write to the frame. The encoder may create
##                   a reference to the frame data (or copy it if the frame is
##                   not reference-counted).
##                   It can be NULL, in which case it is considered a flush
##                   packet.  This signals the end of the stream. If the encoder
##                   still has packets buffered, it will return them after this
##                   call. Once flushing mode has been entered, additional flush
##                   packets are ignored, and sending frames will return
##                   AVERROR_EOF.
##
##                   For audio:
##                   If AV_CODEC_CAP_VARIABLE_FRAME_SIZE is set, then each frame
##                   can have any number of samples.
##                   If it is not set, frame->nb_samples must be equal to
##                   avctx->frame_size for all frames except the last.
##                   The final frame may be smaller than avctx->frame_size.
##  @return 0 on success, otherwise negative error code:
##       AVERROR(EAGAIN):   input is not accepted in the current state - user
##                          must read output with avcodec_receive_packet() (once
##                          all output is read, the packet should be resent, and
##                          the call will not fail with EAGAIN).
##       AVERROR_EOF:       the encoder has been flushed, and no new frames can
##                          be sent to it
##       AVERROR(EINVAL):   codec not opened, refcounted_frames not set, it is a
##                          decoder, or requires flush
##       AVERROR(ENOMEM):   failed to add packet to internal queue, or similar
##       other errors: legitimate decoding errors
##

proc avcodec_send_frame*(avctx: ptr AVCodecContext; frame: ptr AVFrame): cint
## *
##  Read encoded data from the encoder.
##
##  @param avctx codec context
##  @param avpkt This will be set to a reference-counted packet allocated by the
##               encoder. Note that the function will always call
##               av_frame_unref(frame) before doing anything else.
##  @return 0 on success, otherwise negative error code:
##       AVERROR(EAGAIN):   output is not available in the current state - user
##                          must try to send input
##       AVERROR_EOF:       the encoder has been fully flushed, and there will be
##                          no more output packets
##       AVERROR(EINVAL):   codec not opened, or it is an encoder
##       other errors: legitimate decoding errors
##

proc avcodec_receive_packet*(avctx: ptr AVCodecContext; avpkt: ptr AVPacket): cint
## *
##  Create and return a AVHWFramesContext with values adequate for hardware
##  decoding. This is meant to get called from the get_format callback, and is
##  a helper for preparing a AVHWFramesContext for AVCodecContext.hw_frames_ctx.
##  This API is for decoding with certain hardware acceleration modes/APIs only.
##
##  The returned AVHWFramesContext is not initialized. The caller must do this
##  with av_hwframe_ctx_init().
##
##  Calling this function is not a requirement, but makes it simpler to avoid
##  codec or hardware API specific details when manually allocating frames.
##
##  Alternatively to this, an API user can set AVCodecContext.hw_device_ctx,
##  which sets up AVCodecContext.hw_frames_ctx fully automatically, and makes
##  it unnecessary to call this function or having to care about
##  AVHWFramesContext initialization at all.
##
##  There are a number of requirements for calling this function:
##
##  - It must be called from get_format with the same avctx parameter that was
##    passed to get_format. Calling it outside of get_format is not allowed, and
##    can trigger undefined behavior.
##  - The function is not always supported (see description of return values).
##    Even if this function returns successfully, hwaccel initialization could
##    fail later. (The degree to which implementations check whether the stream
##    is actually supported varies. Some do this check only after the user's
##    get_format callback returns.)
##  - The hw_pix_fmt must be one of the choices suggested by get_format. If the
##    user decides to use a AVHWFramesContext prepared with this API function,
##    the user must return the same hw_pix_fmt from get_format.
##  - The device_ref passed to this function must support the given hw_pix_fmt.
##  - After calling this API function, it is the user's responsibility to
##    initialize the AVHWFramesContext (returned by the out_frames_ref parameter),
##    and to set AVCodecContext.hw_frames_ctx to it. If done, this must be done
##    before returning from get_format (this is implied by the normal
##    AVCodecContext.hw_frames_ctx API rules).
##  - The AVHWFramesContext parameters may change every time time get_format is
##    called. Also, AVCodecContext.hw_frames_ctx is reset before get_format. So
##    you are inherently required to go through this process again on every
##    get_format call.
##  - It is perfectly possible to call this function without actually using
##    the resulting AVHWFramesContext. One use-case might be trying to reuse a
##    previously initialized AVHWFramesContext, and calling this API function
##    only to test whether the required frame parameters have changed.
##  - Fields that use dynamically allocated values of any kind must not be set
##    by the user unless setting them is explicitly allowed by the documentation.
##    If the user sets AVHWFramesContext.free and AVHWFramesContext.user_opaque,
##    the new free callback must call the potentially set previous free callback.
##    This API call may set any dynamically allocated fields, including the free
##    callback.
##
##  The function will set at least the following fields on AVHWFramesContext
##  (potentially more, depending on hwaccel API):
##
##  - All fields set by av_hwframe_ctx_alloc().
##  - Set the format field to hw_pix_fmt.
##  - Set the sw_format field to the most suited and most versatile format. (An
##    implication is that this will prefer generic formats over opaque formats
##    with arbitrary restrictions, if possible.)
##  - Set the width/height fields to the coded frame size, rounded up to the
##    API-specific minimum alignment.
##  - Only _if_ the hwaccel requires a pre-allocated pool: set the initial_pool_size
##    field to the number of maximum reference surfaces possible with the codec,
##    plus 1 surface for the user to work (meaning the user can safely reference
##    at most 1 decoded surface at a time), plus additional buffering introduced
##    by frame threading. If the hwaccel does not require pre-allocation, the
##    field is left to 0, and the decoder will allocate new surfaces on demand
##    during decoding.
##  - Possibly AVHWFramesContext.hwctx fields, depending on the underlying
##    hardware API.
##
##  Essentially, out_frames_ref returns the same as av_hwframe_ctx_alloc(), but
##  with basic frame parameters set.
##
##  The function is stateless, and does not change the AVCodecContext or the
##  device_ref AVHWDeviceContext.
##
##  @param avctx The context which is currently calling get_format, and which
##               implicitly contains all state needed for filling the returned
##               AVHWFramesContext properly.
##  @param device_ref A reference to the AVHWDeviceContext describing the device
##                    which will be used by the hardware decoder.
##  @param hw_pix_fmt The hwaccel format you are going to return from get_format.
##  @param out_frames_ref On success, set to a reference to an _uninitialized_
##                        AVHWFramesContext, created from the given device_ref.
##                        Fields will be set to values required for decoding.
##                        Not changed if an error is returned.
##  @return zero on success, a negative value on error. The following error codes
##          have special semantics:
##       AVERROR(ENOENT): the decoder does not support this functionality. Setup
##                        is always manual, or it is a decoder which does not
##                        support setting AVCodecContext.hw_frames_ctx at all,
##                        or it is a software format.
##       AVERROR(EINVAL): it is known that hardware decoding is not supported for
##                        this configuration, or the device_ref is not supported
##                        for the hwaccel referenced by hw_pix_fmt.
##

proc avcodec_get_hw_frames_parameters*(avctx: ptr AVCodecContext;
                                      device_ref: ptr AVBufferRef;
                                      hw_pix_fmt: AVPixelFormat;
                                      out_frames_ref: ptr ptr AVBufferRef): cint
## *
##  @defgroup lavc_parsing Frame parsing
##  @{
##

const
  PARSER_FLAG_COMPLETE_FRAMES* = 0x00000001
  PARSER_FLAG_ONCE* = 0x00000002

  PARSER_FLAG_FETCHED_OFFSET* = 0x00000004
  PARSER_FLAG_USE_CODEC_TS* = 0x00001000


## *
##  Iterate over all registered codec parsers.
##
##  @param opaque a pointer where libavcodec will store the iteration state. Must
##                point to NULL to start the iteration.
##
##  @return the next registered codec parser or NULL when the iteration is
##          finished
##

proc av_parser_iterate*(opaque: ptr pointer): ptr AVCodecParser
## attribute_deprecated

proc av_parser_next*(c: ptr AVCodecParser): ptr AVCodecParser
## attribute_deprecated

proc av_register_codec_parser*(parser: ptr AVCodecParser)
proc av_parser_init*(codec_id: cint): ptr AVCodecParserContext
## *
##  Parse a packet.
##
##  @param s             parser context.
##  @param avctx         codec context.
##  @param poutbuf       set to pointer to parsed buffer or NULL if not yet finished.
##  @param poutbuf_size  set to size of parsed buffer or zero if not yet finished.
##  @param buf           input buffer.
##  @param buf_size      buffer size in bytes without the padding. I.e. the full buffer
##                         size is assumed to be buf_size + AV_INPUT_BUFFER_PADDING_SIZE.
##                         To signal EOF, this should be 0 (so that the last frame
##                         can be output).
##  @param pts           input presentation timestamp.
##  @param dts           input decoding timestamp.
##  @param pos           input byte position in stream.
##  @return the number of bytes of the input bitstream used.
##
##  Example:
##  @code
##    while(in_len){
##        len = av_parser_parse2(myparser, AVCodecContext, &data, &size,
##                                         in_data, in_len,
##                                         pts, dts, pos);
##        in_data += len;
##        in_len  -= len;
##
##        if(size)
##           decode_frame(data, size);
##    }
##  @endcode
##

proc av_parser_parse2*(s: ptr AVCodecParserContext; avctx: ptr AVCodecContext;
                      poutbuf: ptr ptr uint8; poutbuf_size: ptr cint;
                      buf: ptr uint8; buf_size: cint; pts: int64; dts: int64;
                      pos: int64): cint
## *
##  @return 0 if the output buffer is a subset of the input, 1 if it is allocated and must be freed
##  @deprecated use AVBitStreamFilter
##

proc av_parser_change*(s: ptr AVCodecParserContext; avctx: ptr AVCodecContext;
                      poutbuf: ptr ptr uint8; poutbuf_size: ptr cint;
                      buf: ptr uint8; buf_size: cint; keyframe: cint): cint
  {.deprecated: "use AVBitStreamFilter".}
proc av_parser_close*(s: ptr AVCodecParserContext)
## *
##  @}
##  @}
##
## *
##  @addtogroup lavc_encoding
##  @{
##
## *
##  Find a registered encoder with a matching codec ID.
##
##  @param id AVCodecID of the requested encoder
##  @return An encoder if one was found, NULL otherwise.
##

proc avcodec_find_encoder*(id: AVCodecID): ptr AVCodec
## *
##  Find a registered encoder with the specified name.
##
##  @param name name of the requested encoder
##  @return An encoder if one was found, NULL otherwise.
##

proc avcodec_find_encoder_by_name*(name: cstring): ptr AVCodec
## *
##  Encode a frame of audio.
##
##  Takes input samples from frame and writes the next output packet, if
##  available, to avpkt. The output packet does not necessarily contain data for
##  the most recent frame, as encoders can delay, split, and combine input frames
##  internally as needed.
##
##  @param avctx     codec context
##  @param avpkt     output AVPacket.
##                   The user can supply an output buffer by setting
##                   avpkt->data and avpkt->size prior to calling the
##                   function, but if the size of the user-provided data is not
##                   large enough, encoding will fail. If avpkt->data and
##                   avpkt->size are set, avpkt->destruct must also be set. All
##                   other AVPacket fields will be reset by the encoder using
##                   av_init_packet(). If avpkt->data is NULL, the encoder will
##                   allocate it. The encoder will set avpkt->size to the size
##                   of the output packet.
##
##                   If this function fails or produces no output, avpkt will be
##                   freed using av_packet_unref().
##  @param[in] frame AVFrame containing the raw audio data to be encoded.
##                   May be NULL when flushing an encoder that has the
##                   AV_CODEC_CAP_DELAY capability set.
##                   If AV_CODEC_CAP_VARIABLE_FRAME_SIZE is set, then each frame
##                   can have any number of samples.
##                   If it is not set, frame->nb_samples must be equal to
##                   avctx->frame_size for all frames except the last.
##                   The final frame may be smaller than avctx->frame_size.
##  @param[out] got_packet_ptr This field is set to 1 by libavcodec if the
##                             output packet is non-empty, and to 0 if it is
##                             empty. If the function returns an error, the
##                             packet can be assumed to be invalid, and the
##                             value of got_packet_ptr is undefined and should
##                             not be used.
##  @return          0 on success, negative error code on failure
##
##  @deprecated use avcodec_send_frame()/avcodec_receive_packet() instead
##
## attribute_deprecated

proc avcodec_encode_audio2*(avctx: ptr AVCodecContext; avpkt: ptr AVPacket;
                           frame: ptr AVFrame; got_packet_ptr: ptr cint): cint
  {.deprecated: "use pair of avcodec_send_frame and avcodec_receive_packet".}
## *
##  Encode a frame of video.
##
##  Takes input raw video data from frame and writes the next output packet, if
##  available, to avpkt. The output packet does not necessarily contain data for
##  the most recent frame, as encoders can delay and reorder input frames
##  internally as needed.
##
##  @param avctx     codec context
##  @param avpkt     output AVPacket.
##                   The user can supply an output buffer by setting
##                   avpkt->data and avpkt->size prior to calling the
##                   function, but if the size of the user-provided data is not
##                   large enough, encoding will fail. All other AVPacket fields
##                   will be reset by the encoder using av_init_packet(). If
##                   avpkt->data is NULL, the encoder will allocate it.
##                   The encoder will set avpkt->size to the size of the
##                   output packet. The returned data (if any) belongs to the
##                   caller, he is responsible for freeing it.
##
##                   If this function fails or produces no output, avpkt will be
##                   freed using av_packet_unref().
##  @param[in] frame AVFrame containing the raw video data to be encoded.
##                   May be NULL when flushing an encoder that has the
##                   AV_CODEC_CAP_DELAY capability set.
##  @param[out] got_packet_ptr This field is set to 1 by libavcodec if the
##                             output packet is non-empty, and to 0 if it is
##                             empty. If the function returns an error, the
##                             packet can be assumed to be invalid, and the
##                             value of got_packet_ptr is undefined and should
##                             not be used.
##  @return          0 on success, negative error code on failure
##
##  @deprecated use avcodec_send_frame()/avcodec_receive_packet() instead
##
## attribute_deprecated

proc avcodec_encode_video2*(avctx: ptr AVCodecContext; avpkt: ptr AVPacket;
                           frame: ptr AVFrame; got_packet_ptr: ptr cint): cint
  {.deprecated: "use avcodec_send_frame and avcodec_receive_packet".}
proc avcodec_encode_subtitle*(avctx: ptr AVCodecContext; buf: ptr uint8;
                             buf_size: cint; sub: ptr AVSubtitle): cint
## *
##  @}
##

when FF_API_AVPICTURE:
  ## *
  ##  @addtogroup lavc_picture
  ##  @{
  ##
  ## *
  ##  @deprecated unused
  ##
  ## attribute_deprecated
  proc avpicture_alloc*(picture: ptr AVPicture; pix_fmt: AVPixelFormat; width: cint;
                       height: cint): cint {.deprecated: "unused".}
  ## *
  ##  @deprecated unused
  ##
  ## attribute_deprecated
  proc avpicture_free*(picture: ptr AVPicture) {.deprecated: "unused".}
  ## *
  ##  @deprecated use av_image_fill_arrays() instead.
  ##
  ## attribute_deprecated
  proc avpicture_fill*(picture: ptr AVPicture; `ptr`: ptr uint8;
                      pix_fmt: AVPixelFormat; width: cint; height: cint): cint
    {.deprecated: "use av_image_fill_arrays".}
  ## *
  ##  @deprecated use av_image_copy_to_buffer() instead.
  ##
  ## attribute_deprecated
  proc avpicture_layout*(src: ptr AVPicture; pix_fmt: AVPixelFormat; width: cint;
                        height: cint; dest: ptr cuchar; dest_size: cint): cint
    {.deprecated: "use av_image_copy_to_buffer".}
  ## *
  ##  @deprecated use av_image_get_buffer_size() instead.
  ##
  ## attribute_deprecated
  proc avpicture_get_size*(pix_fmt: AVPixelFormat; width: cint; height: cint): cint
    {.deprecated: "use av_image_get_buffer_size() instead.".}
  ## *
  ##  @deprecated av_image_copy() instead.
  ##
  ## attribute_deprecated
  proc av_picture_copy*(dst: ptr AVPicture; src: ptr AVPicture; pix_fmt: AVPixelFormat;
                       width: cint; height: cint) {.deprecated: "use av_image_copy".}
  ## *
  ##  @deprecated unused
  ##
  ## attribute_deprecated
  proc av_picture_crop*(dst: ptr AVPicture; src: ptr AVPicture; pix_fmt: AVPixelFormat;
                       top_band: cint; left_band: cint): cint {.deprecated: "unused".}
  ## *
  ##  @deprecated unused
  ##
  ## attribute_deprecated
  proc av_picture_pad*(dst: ptr AVPicture; src: ptr AVPicture; height: cint; width: cint;
                      pix_fmt: AVPixelFormat; padtop: cint; padbottom: cint;
                      padleft: cint; padright: cint; color: ptr cint): cint
                      {.deprecated: "unused".}
  ## *
  ##  @}
  ##
## *
##  @defgroup lavc_misc Utility functions
##  @ingroup libavc
##
##  Miscellaneous utility functions related to both encoding and decoding
##  (or neither).
##  @{
##
## *
##  @defgroup lavc_misc_pixfmt Pixel formats
##
##  Functions for working with pixel formats.
##  @{
##

when FF_API_GETCHROMA:
  ## *
  ##  @deprecated Use av_pix_fmt_get_chroma_sub_sample
  ##
  ## attribute_deprecated
  proc avcodec_get_chroma_sub_sample*(pix_fmt: AVPixelFormat; h_shift: ptr cint;
                                     v_shift: ptr cint)
    {.deprecated: "Use av_pix_fmt_get_chroma_sub_sample".}
## *
##  Return a value representing the fourCC code associated to the
##  pixel format pix_fmt, or 0 if no associated fourCC code can be
##  found.
##

proc avcodec_pix_fmt_to_codec_tag*(pix_fmt: AVPixelFormat): cuint
## *
##  @deprecated see av_get_pix_fmt_loss()
##

proc avcodec_get_pix_fmt_loss*(dst_pix_fmt: AVPixelFormat;
                              src_pix_fmt: AVPixelFormat; has_alpha: cint): cint
    {.deprecated: "see av_get_pix_fmt_loss()".}
## *
##  Find the best pixel format to convert to given a certain source pixel
##  format.  When converting from one pixel format to another, information loss
##  may occur.  For example, when converting from RGB24 to GRAY, the color
##  information will be lost. Similarly, other losses occur when converting from
##  some formats to other formats. avcodec_find_best_pix_fmt_of_2() searches which of
##  the given pixel formats should be used to suffer the least amount of loss.
##  The pixel formats from which it chooses one, are determined by the
##  pix_fmt_list parameter.
##
##
##  @param[in] pix_fmt_list AV_PIX_FMT_NONE terminated array of pixel formats to choose from
##  @param[in] src_pix_fmt source pixel format
##  @param[in] has_alpha Whether the source pixel format alpha channel is used.
##  @param[out] loss_ptr Combination of flags informing you what kind of losses will occur.
##  @return The best pixel format to convert to or -1 if none was found.
##

proc avcodec_find_best_pix_fmt_of_list*(pix_fmt_list: UncheckedArray[AVPixelFormat],
                                       src_pix_fmt: AVPixelFormat, has_alpha: cint,
                                       loss_ptr: ptr cint): AVPixelFormat

proc avcodec_find_best_pix_fmt_of_2*(dst_pix_fmt1, dst_pix_fmt2, src_pix_fmt: AVPixelFormat,
                                     has_alpha: cint, loss_ptr: ptr cint): AVPixelFormat

## *
##  @deprecated see av_find_best_pix_fmt_of_2()
##
## attribute_deprecated
proc avcodec_find_best_pix_fmt2*(dst_pix_fmt1, dst_pix_fmt2, src_pix_fmt: AVPixelFormat,
                                 has_alpha: cint, loss_ptr: ptr cint): AVPixelFormat
                                 {.deprecated: "use av_find_best_pix_fmt_of_2".}

proc avcodec_default_get_format*(s: ptr AVCodecContext, fmt: UncheckedArray[AVPixelFormat]): AVPixelFormat
## *
##  @}
##

when FF_API_TAG_STRING:
  ## *
  ##  Put a string representing the codec tag codec_tag in buf.
  ##
  ##  @param buf       buffer to place codec tag in
  ##  @param buf_size size in bytes of buf
  ##  @param codecag codec tag to assign
  ##  @return the length of the string that would have been generated if
  ##  enough space had been available, excluding the trailing null
  ##
  ##  @deprecated see av_fourcc_make_string() and av_fourcc2str().
  ##
  ## attribute_deprecated
  proc av_get_codec_tag_string*(buf: cstring; buf_size: csize; codecag: cuint): csize
    {.deprecated: "see av_fourcc_make_string() and av_fourcc2str()".}

proc avcodec_string*(buf: cstring; buf_size: cint; enc: ptr AVCodecContext; encode: cint)

## *
##  Return a name for the specified profile, if available.
##
##  @param codec the codec that is searched for the given profile
##  @param profile the profile value for which a name is requested
##  @return A name for the profile if found, NULL otherwise.
##
proc av_get_profile_name*(codec: ptr AVCodec; profile: cint): cstring

## *
##  Return a name for the specified profile, if available.
##
##  @param codec_id the ID of the codec to which the requested profile belongs
##  @param profile the profile value for which a name is requested
##  @return A name for the profile if found, NULL otherwise.
##
##  @note unlike av_get_profile_name(), which searches a list of profiles
##        supported by a specific decoder or encoder implementation, this
##        function searches the list of profiles from the AVCodecDescriptor
##

proc avcodec_profile_name*(codec_id: AVCodecID; profile: cint): cstring
proc avcodec_default_execute*(c: ptr AVCodecContext; `func`: proc (
    c2: ptr AVCodecContext; arg2: pointer): cint; arg: pointer; ret: ptr cint; count: cint;
                             size: cint): cint
proc avcodec_default_execute2*(c: ptr AVCodecContext; `func`: proc (
    c2: ptr AVCodecContext; arg2: pointer; a3: cint; a4: cint): cint; arg: pointer;
                              ret: ptr cint; count: cint): cint
## FIXME func typedef
## *
##  Fill AVFrame audio data and linesize pointers.
##
##  The buffer buf must be a preallocated buffer with a size big enough
##  to contain the specified samples amount. The filled AVFrame data
##  pointers will point to this buffer.
##
##  AVFrame extended_data channel pointers are allocated if necessary for
##  planar audio.
##
##  @param frame       the AVFrame
##                     frame->nb_samples must be set prior to calling the
##                     function. This function fills in frame->data,
##                     frame->extended_data, frame->linesize[0].
##  @param nb_channels channel count
##  @param sample_fmt  sample format
##  @param buf         buffer to use for frame data
##  @param buf_size    size of buffer
##  @param align       plane size sample alignment (0 = default)
##  @return            >=0 on success, negative error code on failure
##  @todo return the size in bytes required to store the samples in
##  case of success, at the next libavutil bump
##

proc avcodec_fill_audio_frame*(frame: ptr AVFrame; nb_channels: cint;
                              sample_fmt: AVSampleFormat; buf: ptr uint8;
                              buf_size: cint; align: cint): cint
## *
##  Reset the internal decoder state / flush internal buffers. Should be called
##  e.g. when seeking or when switching to a different stream.
##
##  @note when refcounted frames are not used (i.e. avctx->refcounted_frames is 0),
##  this invalidates the frames previously returned from the decoder. When
##  refcounted frames are used, the decoder just releases any references it might
##  keep internally, but the caller's reference remains valid.
##

proc avcodec_flush_buffers*(avctx: ptr AVCodecContext)
## *
##  Return codec bits per sample.
##
##  @param[in] codec_id the codec
##  @return Number of bits per sample or zero if unknown for the given codec.
##

proc av_get_bits_per_sample*(codec_id: AVCodecID): cint
## *
##  Return the PCM codec associated with a sample format.
##  @param be  endianness, 0 for little, 1 for big,
##             -1 (or anything else) for native
##  @return  AV_CODEC_ID_PCM_* or AV_CODEC_ID_NONE
##

proc av_get_pcm_codec*(fmt: AVSampleFormat; be: cint): AVCodecID
## *
##  Return codec bits per sample.
##  Only return non-zero if the bits per sample is exactly correct, not an
##  approximation.
##
##  @param[in] codec_id the codec
##  @return Number of bits per sample or zero if unknown for the given codec.
##

proc av_get_exact_bits_per_sample*(codec_id: AVCodecID): cint
## *
##  Return audio frame duration.
##
##  @param avctx        codec context
##  @param frame_bytes  size of the frame, or 0 if unknown
##  @return             frame duration, in samples, if known. 0 if not able to
##                      determine.
##

proc av_get_audio_frame_duration*(avctx: ptr AVCodecContext; frame_bytes: cint): cint
## *
##  This function is the same as av_get_audio_frame_duration(), except it works
##  with AVCodecParameters instead of an AVCodecContext.
##

proc av_get_audio_frame_duration2*(par: ptr AVCodecParameters; frame_bytes: cint): cint

## *
##  The bitstream filter state.
##
##  This struct must be allocated with av_bsf_alloc() and freed with
##  av_bsf_free().
##
##  The fields in the struct will only be changed (by the caller or by the
##  filter) as described in their documentation, and are to be considered
##  immutable otherwise.
##

type
  AVBSFInternal*{.avcodec.} = object
  AVBSFList*{.avcodec.} = object
  AVBSFContext* {.avcodec.} = object
    av_class*: ptr AVClass      ## *
                        ##  A class for logging and AVOptions
                        ##
    ## *
    ##  The bitstream filter this context is an instance of.
    ##
    filter*: ptr AVBitStreamFilter ## *
                                ##  Opaque libavcodec internal data. Must not be touched by the caller in any
                                ##  way.
                                ##
    internal*: ptr AVBSFInternal ## *
                              ##  Opaque filter-specific private data. If filter->priv_class is non-NULL,
                              ##  this is an AVOptions-enabled struct.
                              ##
    priv_data*: pointer ## *
                      ##  Parameters of the input stream. This field is allocated in
                      ##  av_bsf_alloc(), it needs to be filled by the caller before
                      ##  av_bsf_init().
                      ##
    par_in*: ptr AVCodecParameters ## *
                                ##  Parameters of the output stream. This field is allocated in
                                ##  av_bsf_alloc(), it is set by the filter in av_bsf_init().
                                ##
    par_out*: ptr AVCodecParameters ## *
                                 ##  The timebase used for the timestamps of the input packets. Set by the
                                 ##  caller before av_bsf_init().
                                 ##
    time_base_in*: AVRational ## *
                            ##  The timebase used for the timestamps of the output packets. Set by the
                            ##  filter in av_bsf_init().
                            ##
    time_base_out*: AVRational

  AVBitStreamFilter* {.avcodec.} = object
    name*: cstring ## *
                 ##  A list of codec ids supported by the filter, terminated by
                 ##  AV_CODEC_ID_NONE.
                 ##  May be NULL, in that case the bitstream filter works with any codec id.
                 ##
    codec_ids*: ptr AVCodecID ## *
                           ##  A class for the private data, used to declare bitstream filter private
                           ##  AVOptions. This field is NULL for bitstream filters that do not declare
                           ##  any options.
                           ##
                           ##  If this field is non-NULL, the first member of the filter private data
                           ##  must be a pointer to AVClass, which will be set by libavcodec generic
                           ##  code to this class.
                           ##
    priv_class*: ptr AVClass ## ****************************************************************
                          ##  No fields below this line are part of the public API. They
                          ##  may not be used outside of libavcodec and can be changed and
                          ##  removed at will.
                          ##  New public fields should be added right above.
                          ## ****************************************************************
                          ##
    priv_data_size*: cint
    init*: proc (ctx: ptr AVBSFContext): cint
    filter*: proc (ctx: ptr AVBSFContext; pkt: ptr AVPacket): cint
    close*: proc (ctx: ptr AVBSFContext)
    flush*: proc (ctx: ptr AVBSFContext)

when FF_API_OLD_BSF:
  type
    AVBitStreamFilterContext* {.avcodec.} = object
      priv_data*: pointer
      filter*: ptr AVBitStreamFilter
      parser*: ptr AVCodecParserContext
      next*: ptr AVBitStreamFilterContext ## *
                                       ##  Internal default arguments, used if NULL is passed to av_bitstream_filter_filter().
                                       ##  Not for access by library users.
                                       ##
      args*: cstring



when FF_API_OLD_BSF:
  ## *
  ##  @deprecated the old bitstream filtering API (using AVBitStreamFilterContext)
  ##  is deprecated. Use the new bitstream filtering API (using AVBSFContext).
  ##
  ## attribute_deprecated
  proc av_register_bitstream_filter*(bsf: ptr AVBitStreamFilter)
    {.deprecated: "Use the new bitstream filtering API (using AVBSFContext)".}
  ## *
  ##  @deprecated the old bitstream filtering API (using AVBitStreamFilterContext)
  ##  is deprecated. Use av_bsf_get_by_name(), av_bsf_alloc(), and av_bsf_init()
  ##  from the new bitstream filtering API (using AVBSFContext).
  ##
  ## attribute_deprecated
  proc av_bitstream_filter_init*(name: cstring): ptr AVBitStreamFilterContext
    {.deprecated: "Use av_bsf_get_by_name(), av_bsf_alloc(), and av_bsf_init()".}
  ## *
  ##  @deprecated the old bitstream filtering API (using AVBitStreamFilterContext)
  ##  is deprecated. Use av_bsf_send_packet() and av_bsf_receive_packet() from the
  ##  new bitstream filtering API (using AVBSFContext).
  ##
  ## attribute_deprecated
  proc av_bitstream_filter_filter*(bsfc: ptr AVBitStreamFilterContext;
                                  avctx: ptr AVCodecContext; args: cstring;
                                  poutbuf: ptr ptr uint8; poutbuf_size: ptr cint;
                                  buf: ptr uint8; buf_size: cint; keyframe: cint): cint
    {.deprecated: "Use av_bsf_send_packet() and av_bsf_receive_packet()".}
  ## *
  ##  @deprecated the old bitstream filtering API (using AVBitStreamFilterContext)
  ##  is deprecated. Use av_bsf_free() from the new bitstream filtering API (using
  ##  AVBSFContext).
  ##
  ## attribute_deprecated
  proc av_bitstream_filter_close*(bsf: ptr AVBitStreamFilterContext)
    {.deprecated: "Use av_bsf_free() from the new bitstream filtering API".}
  ## *
  ##  @deprecated the old bitstream filtering API (using AVBitStreamFilterContext)
  ##  is deprecated. Use av_bsf_iterate() from the new bitstream filtering API (using
  ##  AVBSFContext).
  ##
  ## attribute_deprecated
  proc av_bitstream_filter_next*(f: ptr AVBitStreamFilter): ptr AVBitStreamFilter
    {.deprecated: "Use av_bsf_iterate() from the new bitstream filtering API".}
## *
##  @return a bitstream filter with the specified name or NULL if no such
##          bitstream filter exists.
##

proc av_bsf_get_by_name*(name: cstring): ptr AVBitStreamFilter
## *
##  Iterate over all registered bitstream filters.
##
##  @param opaque a pointer where libavcodec will store the iteration state. Must
##                point to NULL to start the iteration.
##
##  @return the next registered bitstream filter or NULL when the iteration is
##          finished
##

proc av_bsf_iterate*(opaque: ptr pointer): ptr AVBitStreamFilter
when FF_API_NEXT:
  ## attribute_deprecated
  proc av_bsf_next*(opaque: ptr pointer): ptr AVBitStreamFilter
## *
##  Allocate a context for a given bitstream filter. The caller must fill in the
##  context parameters as described in the documentation and then call
##  av_bsf_init() before sending any data to the filter.
##
##  @param filter the filter for which to allocate an instance.
##  @param ctx a pointer into which the pointer to the newly-allocated context
##             will be written. It must be freed with av_bsf_free() after the
##             filtering is done.
##
##  @return 0 on success, a negative AVERROR code on failure
##

proc av_bsf_alloc*(filter: ptr AVBitStreamFilter; ctx: ptr ptr AVBSFContext): cint
## *
##  Prepare the filter for use, after all the parameters and options have been
##  set.
##

proc av_bsf_init*(ctx: ptr AVBSFContext): cint
## *
##  Submit a packet for filtering.
##
##  After sending each packet, the filter must be completely drained by calling
##  av_bsf_receive_packet() repeatedly until it returns AVERROR(EAGAIN) or
##  AVERROR_EOF.
##
##  @param pkt the packet to filter. The bitstream filter will take ownership of
##  the packet and reset the contents of pkt. pkt is not touched if an error occurs.
##  If pkt is empty (i.e. NULL, or pkt->data is NULL and pkt->side_data_elems zero),
##  it signals the end of the stream (i.e. no more non-empty packets will be sent;
##  sending more empty packets does nothing) and will cause the filter to output
##  any packets it may have buffered internally.
##
##  @return 0 on success, a negative AVERROR on error. This function never fails if
##  pkt is empty.
##

proc av_bsf_send_packet*(ctx: ptr AVBSFContext; pkt: ptr AVPacket): cint
## *
##  Retrieve a filtered packet.
##
##  @param[out] pkt this struct will be filled with the contents of the filtered
##                  packet. It is owned by the caller and must be freed using
##                  av_packet_unref() when it is no longer needed.
##                  This parameter should be "clean" (i.e. freshly allocated
##                  with av_packet_alloc() or unreffed with av_packet_unref())
##                  when this function is called. If this function returns
##                  successfully, the contents of pkt will be completely
##                  overwritten by the returned data. On failure, pkt is not
##                  touched.
##
##  @return 0 on success. AVERROR(EAGAIN) if more packets need to be sent to the
##  filter (using av_bsf_send_packet()) to get more output. AVERROR_EOF if there
##  will be no further output from the filter. Another negative AVERROR value if
##  an error occurs.
##
##  @note one input packet may result in several output packets, so after sending
##  a packet with av_bsf_send_packet(), this function needs to be called
##  repeatedly until it stops returning 0. It is also possible for a filter to
##  output fewer packets than were sent to it, so this function may return
##  AVERROR(EAGAIN) immediately after a successful av_bsf_send_packet() call.
##

proc av_bsf_receive_packet*(ctx: ptr AVBSFContext; pkt: ptr AVPacket): cint
## *
##  Reset the internal bitstream filter state / flush internal buffers.
##

proc av_bsf_flush*(ctx: ptr AVBSFContext)
## *
##  Free a bitstream filter context and everything associated with it; write NULL
##  into the supplied pointer.
##

proc av_bsf_free*(ctx: ptr ptr AVBSFContext)
## *
##  Get the AVClass for AVBSFContext. It can be used in combination with
##  AV_OPT_SEARCH_FAKE_OBJ for examining options.
##
##  @see av_opt_find().
##

proc av_bsf_get_class*(): ptr AVClass
## *
##  Structure for chain/list of bitstream filters.
##  Empty list can be allocated by av_bsf_list_alloc().
##


## *
##  Allocate empty list of bitstream filters.
##  The list must be later freed by av_bsf_list_free()
##  or finalized by av_bsf_list_finalize().
##
##  @return Pointer to @ref AVBSFList on success, NULL in case of failure
##

proc av_bsf_list_alloc*(): ptr AVBSFList
## *
##  Free list of bitstream filters.
##
##  @param lst Pointer to pointer returned by av_bsf_list_alloc()
##

proc av_bsf_list_free*(lst: ptr ptr AVBSFList)
## *
##  Append bitstream filter to the list of bitstream filters.
##
##  @param lst List to append to
##  @param bsf Filter context to be appended
##
##  @return >=0 on success, negative AVERROR in case of failure
##

proc av_bsf_list_append*(lst: ptr AVBSFList; bsf: ptr AVBSFContext): cint
## *
##  Construct new bitstream filter context given it's name and options
##  and append it to the list of bitstream filters.
##
##  @param lst      List to append to
##  @param bsf_name Name of the bitstream filter
##  @param options  Options for the bitstream filter, can be set to NULL
##
##  @return >=0 on success, negative AVERROR in case of failure
##

proc av_bsf_list_append2*(lst: ptr AVBSFList; bsf_name: cstring;
                         options: ptr ptr AVDictionary): cint
## *
##  Finalize list of bitstream filters.
##
##  This function will transform @ref AVBSFList to single @ref AVBSFContext,
##  so the whole chain of bitstream filters can be treated as single filter
##  freshly allocated by av_bsf_alloc().
##  If the call is successful, @ref AVBSFList structure is freed and lst
##  will be set to NULL. In case of failure, caller is responsible for
##  freeing the structure by av_bsf_list_free()
##
##  @param      lst Filter list structure to be transformed
##  @param[out] bsf Pointer to be set to newly created @ref AVBSFContext structure
##                  representing the chain of bitstream filters
##
##  @return >=0 on success, negative AVERROR in case of failure
##

proc av_bsf_list_finalize*(lst: ptr ptr AVBSFList; bsf: ptr ptr AVBSFContext): cint
## *
##  Parse string describing list of bitstream filters and create single
##  @ref AVBSFContext describing the whole chain of bitstream filters.
##  Resulting @ref AVBSFContext can be treated as any other @ref AVBSFContext freshly
##  allocated by av_bsf_alloc().
##
##  @param      str String describing chain of bitstream filters in format
##                  `bsf1[=opt1=val1:opt2=val2][,bsf2]`
##  @param[out] bsf Pointer to be set to newly created @ref AVBSFContext structure
##                  representing the chain of bitstream filters
##
##  @return >=0 on success, negative AVERROR in case of failure
##

proc av_bsf_list_parse_str*(str: cstring; bsf: ptr ptr AVBSFContext): cint
## *
##  Get null/pass-through bitstream filter.
##
##  @param[out] bsf Pointer to be set to new instance of pass-through bitstream filter
##
##  @return
##

proc av_bsf_get_null_filter*(bsf: ptr ptr AVBSFContext): cint
##  memory
## *
##  Same behaviour av_fast_malloc but the buffer has additional
##  AV_INPUT_BUFFER_PADDING_SIZE at the end which will always be 0.
##
##  In addition the whole buffer will initially and after resizes
##  be 0-initialized so that no uninitialized data will ever appear.
##

proc av_fast_padded_malloc*(`ptr`: pointer; size: ptr cuint; min_size: csize)
## *
##  Same behaviour av_fast_padded_malloc except that buffer will always
##  be 0-initialized after call.
##

proc av_fast_padded_mallocz*(`ptr`: pointer; size: ptr cuint; min_size: csize)
## *
##  Encode extradata length to a buffer. Used by xiph codecs.
##
##  @param s buffer to write to; must be at least (v/255+1) bytes long
##  @param v size of extradata in bytes
##  @return number of bytes written to the buffer.
##

proc av_xiphlacing*(s: ptr cuchar; v: cuint): cuint
when FF_API_USER_VISIBLE_AVHWACCEL:
  ## *
  ##  Register the hardware accelerator hwaccel.
  ##
  ##  @deprecated  This function doesn't do anything.
  ##
  ## attribute_deprecated
  proc av_register_hwaccel*(hwaccel: ptr AVHWAccel)
    {.deprecated: "This function doesn't do anything.".}
  ## *
  ##  If hwaccel is NULL, returns the first registered hardware accelerator,
  ##  if hwaccel is non-NULL, returns the next registered hardware accelerator
  ##  after hwaccel, or NULL if hwaccel is the last one.
  ##
  ##  @deprecated  AVHWaccel structures contain no user-serviceable parts, so
  ##               this function should not be used.
  ##
  ## attribute_deprecated
  proc av_hwaccel_next*(hwaccel: ptr AVHWAccel): ptr AVHWAccel
    {.deprecated: "AVHWaccel structures contain no user-servicable parts, so this function should not be used.".}
when FF_API_LOCKMGR:
  ## *
  ##  Lock operation used by lockmgr
  ##
  ##  @deprecated Deprecated together with av_lockmgr_register().
  ##
  type
    AVLockOp*{.avcodec, deprecated: "Deprecated together with av_lockmgr_register().".} = enum
      AV_LOCK_CREATE,         ## /< Create a mutex
      AV_LOCK_OBTAIN,         ## /< Lock the mutex
      AV_LOCK_RELEASE,        ## /< Unlock the mutex
      AV_LOCK_DESTROY         ## /< Free mutex resources
  ## *
  ##  Register a user provided lock manager supporting the operations
  ##  specified by AVLockOp. The "mutex" argument to the function points
  ##  to a (void *) where the lockmgr should store/get a pointer to a user
  ##  allocated mutex. It is NULL upon AV_LOCK_CREATE and equal to the
  ##  value left by the last call for all other ops. If the lock manager is
  ##  unable to perform the op then it should leave the mutex in the same
  ##  state as when it was called and return a non-zero value. However,
  ##  when called with AV_LOCK_DESTROY the mutex will always be assumed to
  ##  have been successfully destroyed. If av_lockmgr_register succeeds
  ##  it will return a non-negative value, if it fails it will return a
  ##  negative value and destroy all mutex and unregister all callbacks.
  ##  av_lockmgr_register is not thread-safe, it must be called from a
  ##  single thread before any calls which make use of locking are used.
  ##
  ##  @param cb User defined callback. av_lockmgr_register invokes calls
  ##            to this callback and the previously registered callback.
  ##            The callback will be used to create more than one mutex
  ##            each of which must be backed by its own underlying locking
  ##            mechanism (i.e. do not use a single static object to
  ##            implement your lock manager). If cb is set to NULL the
  ##            lockmgr will be unregistered.
  ##
  ##  @deprecated This function does nothing, and always returns 0. Be sure to
  ##              build with thread support to get basic thread safety.
  ##
  ## attribute_deprecated
  proc av_lockmgr_register*(cb: proc (mutex: ptr pointer; op: AVLockOp): cint): cint
    {.deprecated: "This function does nothing, and always returns 0".}
## *
##  Get the type of the given codec.
##

proc avcodec_getype*(codec_id: AVCodecId): AVMediaType
## *
##  Get the name of a codec.
##  @return  a static string identifying the codec; never NULL
##

proc avcodec_get_name*(id: AVCodecID): cstring
## *
##  @return a positive value if s is open (i.e. avcodec_open2() was called on it
##  with no corresponding avcodec_close()), 0 otherwise.
##

proc avcodec_is_open*(s: ptr AVCodecContext): cint
## *
##  @return a non-zero number if codec is an encoder, zero otherwise
##

proc av_codec_is_encoder*(codec: ptr AVCodec): cint
## *
##  @return a non-zero number if codec is a decoder, zero otherwise
##

proc av_codec_is_decoder*(codec: ptr AVCodec): cint
## *
##  @return descriptor for given codec ID or NULL if no descriptor exists.
##

proc avcodec_descriptor_get*(id: AVCodecID): ptr AVCodecDescriptor
## *
##  Iterate over all codec descriptors known to libavcodec.
##
##  @param prev previous descriptor. NULL to get the first descriptor.
##
##  @return next descriptor or NULL after the last descriptor
##

proc avcodec_descriptor_next*(prev: ptr AVCodecDescriptor): ptr AVCodecDescriptor
## *
##  @return codec descriptor with the given name or NULL if no such descriptor
##          exists.
##

proc avcodec_descriptor_get_by_name*(name: cstring): ptr AVCodecDescriptor
## *
##  Allocate a CPB properties structure and initialize its fields to default
##  values.
##
##  @param size if non-NULL, the size of the allocated struct will be written
##              here. This is useful for embedding it in side data.
##
##  @return the newly allocated struct or NULL on failure
##

proc av_cpb_properties_alloc*(size: ptr csize): ptr AVCPBProperties
## *
##  @}
##
