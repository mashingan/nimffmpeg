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
##  @ingroup libavf
##  Main libavformat public API header
##
## *
##  @defgroup libavf libavformat
##  I/O and Muxing/Demuxing Library
##
##  Libavformat (lavf) is a library for dealing with various media container
##  formats. Its main two purposes are demuxing - i.e. splitting a media file
##  into component streams, and the reverse process of muxing - writing supplied
##  data in a specified container format. It also has an @ref lavf_io
##  "I/O module" which supports a number of protocols for accessing the data (e.g.
##  file, tcp, http and others).
##  Unless you are absolutely sure you won't use libavformat's network
##  capabilities, you should also call avformat_network_init().
##
##  A supported input format is described by an AVInputFormat struct, conversely
##  an output format is described by AVOutputFormat. You can iterate over all
##  input/output formats using the  av_demuxer_iterate / av_muxer_iterate() functions.
##  The protocols layer is not part of the public API, so you can only get the names
##  of supported protocols with the avio_enum_protocols() function.
##
##  Main lavf structure used for both muxing and demuxing is AVFormatContext,
##  which exports all information about the file being read or written. As with
##  most Libavformat structures, its size is not part of public ABI, so it cannot be
##  allocated on stack or directly with av_malloc(). To create an
##  AVFormatContext, use avformat_alloc_context() (some functions, like
##  avformat_open_input() might do that for you).
##
##  Most importantly an AVFormatContext contains:
##  @li the @ref AVFormatContext.iformat "input" or @ref AVFormatContext.oformat
##  "output" format. It is either autodetected or set by user for input;
##  always set by user for output.
##  @li an @ref AVFormatContext.streams "array" of AVStreams, which describe all
##  elementary streams stored in the file. AVStreams are typically referred to
##  using their index in this array.
##  @li an @ref AVFormatContext.pb "I/O context". It is either opened by lavf or
##  set by user for input, always set by user for output (unless you are dealing
##  with an AVFMT_NOFILE format).
##
##  @section lavf_options Passing options to (de)muxers
##  It is possible to configure lavf muxers and demuxers using the @ref avoptions
##  mechanism. Generic (format-independent) libavformat options are provided by
##  AVFormatContext, they can be examined from a user program by calling
##  av_opt_next() / av_opt_find() on an allocated AVFormatContext (or its AVClass
##  from avformat_get_class()). Private (format-specific) options are provided by
##  AVFormatContext.priv_data if and only if AVInputFormat.priv_class /
##  AVOutputFormat.priv_class of the corresponding format struct is non-NULL.
##  Further options may be provided by the @ref AVFormatContext.pb "I/O context",
##  if its AVClass is non-NULL, and the protocols layer. See the discussion on
##  nesting in @ref avoptions documentation to learn how to access those.
##
##  @section urls
##  URL strings in libavformat are made of a scheme/protocol, a ':', and a
##  scheme specific string. URLs without a scheme and ':' used for local files
##  are supported but deprecated. "file:" should be used for local files.
##
##  It is important that the scheme string is not taken from untrusted
##  sources without checks.
##
##  Note that some schemes/protocols are quite powerful, allowing access to
##  both local and remote files, parts of them, concatenations of them, local
##  audio and video devices and so on.
##
##  @{
##
##  @defgroup lavf_decoding Demuxing
##  @{
##  Demuxers read a media file and split it into chunks of data (@em packets). A
##  @ref AVPacket "packet" contains one or more encoded frames which belongs to a
##  single elementary stream. In the lavf API this process is represented by the
##  avformat_open_input() function for opening a file, av_read_frame() for
##  reading a single packet and finally avformat_close_input(), which does the
##  cleanup.
##
##  @section lavf_decoding_open Opening a media file
##  The minimum information required to open a file is its URL, which
##  is passed to avformat_open_input(), as in the following code:
##  @code
##  const char    *url = "file:in.mp3";
##  AVFormatContext *s = NULL;
##  int ret = avformat_open_input(&s, url, NULL, NULL);
##  if (ret < 0)
##      abort();
##  @endcode
##  The above code attempts to allocate an AVFormatContext, open the
##  specified file (autodetecting the format) and read the header, exporting the
##  information stored there into s. Some formats do not have a header or do not
##  store enough information there, so it is recommended that you call the
##  avformat_find_stream_info() function which tries to read and decode a few
##  frames to find missing information.
##
##  In some cases you might want to preallocate an AVFormatContext yourself with
##  avformat_alloc_context() and do some tweaking on it before passing it to
##  avformat_open_input(). One such case is when you want to use custom functions
##  for reading input data instead of lavf internal I/O layer.
##  To do that, create your own AVIOContext with avio_alloc_context(), passing
##  your reading callbacks to it. Then set the @em pb field of your
##  AVFormatContext to newly created AVIOContext.
##
##  Since the format of the opened file is in general not known until after
##  avformat_open_input() has returned, it is not possible to set demuxer private
##  options on a preallocated context. Instead, the options should be passed to
##  avformat_open_input() wrapped in an AVDictionary:
##  @code
##  AVDictionary *options = NULL;
##  av_dict_set(&options, "video_size", "640x480", 0);
##  av_dict_set(&options, "pixel_format", "rgb24", 0);
##
##  if (avformat_open_input(&s, url, NULL, &options) < 0)
##      abort();
##  av_dict_free(&options);
##  @endcode
##  This code passes the private options 'video_size' and 'pixel_format' to the
##  demuxer. They would be necessary for e.g. the rawvideo demuxer, since it
##  cannot know how to interpret raw video data otherwise. If the format turns
##  out to be something different than raw video, those options will not be
##  recognized by the demuxer and therefore will not be applied. Such unrecognized
##  options are then returned in the options dictionary (recognized options are
##  consumed). The calling program can handle such unrecognized options as it
##  wishes, e.g.
##  @code
##  AVDictionaryEntry *e;
##  if (e = av_dict_get(options, "", NULL, AV_DICT_IGNORE_SUFFIX)) {
##      fprintf(stderr, "Option %s not recognized by the demuxer.\n", e->key);
##      abort();
##  }
##  @endcode
##
##  After you have finished reading the file, you must close it with
##  avformat_close_input(). It will free everything associated with the file.
##
##  @section lavf_decoding_read Reading from an opened file
##  Reading data from an opened AVFormatContext is done by repeatedly calling
##  av_read_frame() on it. Each call, if successful, will return an AVPacket
##  containing encoded data for one AVStream, identified by
##  AVPacket.stream_index. This packet may be passed straight into the libavcodec
##  decoding functions avcodec_send_packet() or avcodec_decode_subtitle2() if the
##  caller wishes to decode the data.
##
##  AVPacket.pts, AVPacket.dts and AVPacket.duration timing information will be
##  set if known. They may also be unset (i.e. AV_NOPTS_VALUE for
##  pts/dts, 0 for duration) if the stream does not provide them. The timing
##  information will be in AVStream.time_base units, i.e. it has to be
##  multiplied by the timebase to convert them to seconds.
##
##  If AVPacket.buf is set on the returned packet, then the packet is
##  allocated dynamically and the user may keep it indefinitely.
##  Otherwise, if AVPacket.buf is NULL, the packet data is backed by a
##  static storage somewhere inside the demuxer and the packet is only valid
##  until the next av_read_frame() call or closing the file. If the caller
##  requires a longer lifetime, av_packet_make_refcounted() will ensure that
##  the data is reference counted, copying the data if necessary.
##  In both cases, the packet must be freed with av_packet_unref() when it is no
##  longer needed.
##
##  @section lavf_decoding_seek Seeking
##  @}
##
##  @defgroup lavf_encoding Muxing
##  @{
##  Muxers take encoded data in the form of @ref AVPacket "AVPackets" and write
##  it into files or other output bytestreams in the specified container format.
##
##  The main API functions for muxing are avformat_write_header() for writing the
##  file header, av_write_frame() / av_interleaved_write_frame() for writing the
##  packets and av_writerailer() for finalizing the file.
##
##  At the beginning of the muxing process, the caller must first call
##  avformat_alloc_context() to create a muxing context. The caller then sets up
##  the muxer by filling the various fields in this context:
##
##  - The @ref AVFormatContext.oformat "oformat" field must be set to select the
##    muxer that will be used.
##  - Unless the format is of the AVFMT_NOFILE type, the @ref AVFormatContext.pb
##    "pb" field must be set to an opened IO context, either returned from
##    avio_open2() or a custom one.
##  - Unless the format is of the AVFMT_NOSTREAMS type, at least one stream must
##    be created with the avformat_new_stream() function. The caller should fill
##    the @ref AVStream.codecpar "stream codec parameters" information, such as the
##    codec @ref AVCodecParameters.codec_type "type", @ref AVCodecParameters.codec_id
##    "id" and other parameters (e.g. width / height, the pixel or sample format,
##    etc.) as known. The @ref AVStream.time_base "stream timebase" should
##    be set to the timebase that the caller desires to use for this stream (note
##    that the timebase actually used by the muxer can be different, as will be
##    described later).
##  - It is advised to manually initialize only the relevant fields in
##    AVCodecParameters, rather than using @ref avcodec_parameters_copy() during
##    remuxing: there is no guarantee that the codec context values remain valid
##    for both input and output format contexts.
##  - The caller may fill in additional information, such as @ref
##    AVFormatContext.metadata "global" or @ref AVStream.metadata "per-stream"
##    metadata, @ref AVFormatContext.chapters "chapters", @ref
##    AVFormatContext.programs "programs", etc. as described in the
##    AVFormatContext documentation. Whether such information will actually be
##    stored in the output depends on what the container format and the muxer
##    support.
##
##  When the muxing context is fully set up, the caller must call
##  avformat_write_header() to initialize the muxer internals and write the file
##  header. Whether anything actually is written to the IO context at this step
##  depends on the muxer, but this function must always be called. Any muxer
##  private options must be passed in the options parameter to this function.
##
##  The data is then sent to the muxer by repeatedly calling av_write_frame() or
##  av_interleaved_write_frame() (consult those functions' documentation for
##  discussion on the difference between them; only one of them may be used with
##  a single muxing context, they should not be mixed). Do note that the timing
##  information on the packets sent to the muxer must be in the corresponding
##  AVStream's timebase. That timebase is set by the muxer (in the
##  avformat_write_header() step) and may be different from the timebase
##  requested by the caller.
##
##  Once all the data has been written, the caller must call av_writerailer()
##  to flush any buffered packets and finalize the output file, then close the IO
##  context (if any) and finally free the muxing context with
##  avformat_free_context().
##  @}
##
##  @defgroup lavf_io I/O Read/Write
##  @{
##  @section lavf_io_dirlist Directory listing
##  The directory listing API makes it possible to list files on remote servers.
##
##  Some of possible use cases:
##  - an "open file" dialog to choose files from a remote location,
##  - a recursive media finder providing a player with an ability to play all
##  files from a given directory.
##
##  @subsection lavf_io_dirlist_open Opening a directory
##  At first, a directory needs to be opened by calling avio_open_dir()
##  supplied with a URL and, optionally, ::AVDictionary containing
##  protocol-specific parameters. The function returns zero or positive
##  integer and allocates AVIODirContext on success.
##
##  @code
##  AVIODirContext *ctx = NULL;
##  if (avio_open_dir(&ctx, "smb://example.com/some_dir", NULL) < 0) {
##      fprintf(stderr, "Cannot open directory.\n");
##      abort();
##  }
##  @endcode
##
##  This code tries to open a sample directory using smb protocol without
##  any additional parameters.
##
##  @subsection lavf_io_dirlist_read Reading entries
##  Each directory's entry (i.e. file, another directory, anything else
##  within ::AVIODirEntryType) is represented by AVIODirEntry.
##  Reading consecutive entries from an opened AVIODirContext is done by
##  repeatedly calling avio_read_dir() on it. Each call returns zero or
##  positive integer if successful. Reading can be stopped right after the
##  NULL entry has been read -- it means there are no entries left to be
##  read. The following code reads all entries from a directory associated
##  with ctx and prints their names to standard output.
##  @code
##  AVIODirEntry *entry = NULL;
##  for (;;) {
##      if (avio_read_dir(ctx, &entry) < 0) {
##          fprintf(stderr, "Cannot list directory.\n");
##          abort();
##      }
##      if (!entry)
##          break;
##      printf("%s\n", entry->name);
##      avio_free_directory_entry(&entry);
##  }
##  @endcode
##  @}
##
##  @defgroup lavf_codec Demuxers
##  @{
##  @defgroup lavf_codec_native Native Demuxers
##  @{
##  @}
##  @defgroup lavf_codec_wrappers External library wrappers
##  @{
##  @}
##  @}
##  @defgroup lavf_protos I/O Protocols
##  @{
##  @}
##  @defgroup lavf_internal Internal
##  @{
##  @}
##  @}
##

from ../libavcodec/version as vs import FF_API_OLD_BSF
import
  ../libavcodec/[avcodec],
  ../libavutil/[dict, rational],
  version
import ../utiltypes

when defined(windows):
  {.push importc, dynlib: "avformat(|-55|-56|-57|-58).dll".}
elif defined(macosx):
  {.push importc, dynlib: "avformat(|.55|.56|.57|.58).dylib".}
else:
  {.push importc, dynlib: "libavformat.so(|.55|.56|.57|.58)".}

when FF_API_LAVF_MP4A_LATM:
  const
    AVFMT_FLAG_MP4A_LATM* = 0x00008000
when FF_API_LAVF_KEEPSIDE_FLAG:
  const
    AVFMT_FLAG_KEEP_SIDE_DATA* = 0x00040000

const
  AVSTREAM_EVENT_FLAG_METADATA_UPDATED* = 0x00000001

const
  AVFMTCTX_NOHEADER* = 0x00000001
  AVFMTCTX_UNSEEKABLE* = 0x00000002

const
  AVPROBE_SCORE_MAX* = 100
  AVPROBE_SCORE_RETRY* = (AVPROBE_SCORE_MAX div 4)
  AVPROBE_SCORE_STREAM_RETRY* = (AVPROBE_SCORE_MAX div 4 - 1)
  AVPROBE_SCORE_EXTENSION* = 50
  AVPROBE_SCORE_MIME* = 75
  AVPROBE_PADDING_SIZE* = 32

const
  AVINDEX_KEYFRAME* = 0x00000001
  AVINDEX_DISCARD_FRAME* = 0x00000002

const
  AV_DISPOSITION_DEFAULT* = 0x00000001
  AV_DISPOSITION_DUB* = 0x00000002
  AV_DISPOSITION_ORIGINAL* = 0x00000004
  AV_DISPOSITION_COMMENT* = 0x00000008
  AV_DISPOSITION_LYRICS* = 0x00000010
  AV_DISPOSITION_KARAOKE* = 0x00000020

const
  AV_PTS_WRAP_IGNORE* = 0
  AV_PTS_WRAP_ADD_OFFSET* = 1
  AV_PTS_WRAP_SUB_OFFSET* = -1


## *
##  The duration of a video can be estimated through various ways, and this enum can be used
##  to know how the duration was estimated.
##



## *
##  Callback used by devices to communicate with application.
##


## *
##  @defgroup metadata_api Public Metadata API
##  @{
##  @ingroup libavf
##  The metadata API allows libavformat to export metadata tags to a client
##  application when demuxing. Conversely it allows a client application to
##  set metadata when muxing.
##
##  Metadata is exported or set as pairs of key/value strings in the 'metadata'
##  fields of the AVFormatContext, AVStream, AVChapter and AVProgram structs
##  using the @ref lavu_dict "AVDictionary" API. Like all strings in FFmpeg,
##  metadata is assumed to be UTF-8 encoded Unicode. Note that metadata
##  exported by demuxers isn't checked to be valid UTF-8 in most cases.
##
##  Important concepts to keep in mind:
##  -  Keys are unique; there can never be 2 tags with the same key. This is
##     also meant semantically, i.e., a demuxer should not knowingly produce
##     several keys that are literally different but semantically identical.
##     E.g., key=Author5, key=Author6. In this example, all authors must be
##     placed in the same tag.
##  -  Metadata is flat, not hierarchical; there are no subtags. If you
##     want to store, e.g., the email address of the child of producer Alice
##     and actor Bob, that could have key=alice_and_bobs_childs_email_address.
##  -  Several modifiers can be applied to the tag name. This is done by
##     appending a dash character ('-') and the modifier name in the order
##     they appear in the list below -- e.g. foo-eng-sort, not foo-sort-eng.
##     -  language -- a tag whose value is localized for a particular language
##        is appended with the ISO 639-2/B 3-letter language code.
##        For example: Author-ger=Michael, Author-eng=Mike
##        The original/default language is in the unqualified "Author" tag.
##        A demuxer should set a default if it sets any translated tag.
##     -  sorting  -- a modified version of a tag that should be used for
##        sorting will have '-sort' appended. E.g. artist="The Beatles",
##        artist-sort="Beatles, The".
##  - Some protocols and demuxers support metadata updates. After a successful
##    call to av_read_packet(), AVFormatContext.event_flags or AVStream.event_flags
##    will be updated to indicate if metadata changed. In order to detect metadata
##    changes on a stream, you need to loop through all streams in the AVFormatContext
##    and check their individual event_flags.
##
##  -  Demuxers attempt to export metadata in a generic format, however tags
##     with no generic equivalents are left as they are stored in the container.
##     Follows a list of generic tag names:
##
##  @verbatim
##  album        -- name of the set this work belongs to
##  album_artist -- main creator of the set/album, if different from artist.
##                  e.g. "Various Artists" for compilation albums.
##  artist       -- main creator of the work
##  comment      -- any additional description of the file.
##  composer     -- who composed the work, if different from artist.
##  copyright    -- name of copyright holder.
##  creationime-- date when the file was created, preferably in ISO 8601.
##  date         -- date when the work was created, preferably in ISO 8601.
##  disc         -- number of a subset, e.g. disc in a multi-disc collection.
##  encoder      -- name/settings of the software/hardware that produced the file.
##  encoded_by   -- person/group who created the file.
##  filename     -- original name of the file.
##  genre        -- <self-evident>.
##  language     -- main language in which the work is performed, preferably
##                  in ISO 639-2 format. Multiple languages can be specified by
##                  separating them with commas.
##  performer    -- artist who performed the work, if different from artist.
##                  E.g for "Also sprach Zarathustra", artist would be "Richard
##                  Strauss" and performer "London Philharmonic Orchestra".
##  publisher    -- name of the label/publisher.
##  service_name     -- name of the service in broadcasting (channel name).
##  service_provider -- name of the service provider in broadcasting.
##  title        -- name of the work.
##  track        -- number of this work in the set, can be in form current/total.
##  variant_bitrate -- the total bitrate of the bitrate variant that the current stream is part of
##  @endverbatim
##
##  Look in the examples section for an application example how to use the Metadata API.
##
##  @}
##
##  packet functions
## *
##  Allocate and read the payload of a packet and initialize its
##  fields with default values.
##
##  @param s    associated IO context
##  @param pkt packet
##  @param size desired payload size
##  @return >0 (read size) if OK, AVERROR_xxx otherwise
##

proc av_get_packet*(s: ptr AVIOContext; pkt: ptr AVPacket; size: cint): cint
## *
##  Read data and append it to the current content of the AVPacket.
##  If pkt->size is 0 this is identical to av_get_packet.
##  Note that this uses av_grow_packet and thus involves a realloc
##  which is inefficient. Thus this function should only be used
##  when there is no reasonable way to know (an upper bound of)
##  the final size.
##
##  @param s    associated IO context
##  @param pkt packet
##  @param size amount of data to read
##  @return >0 (read size) if OK, AVERROR_xxx otherwise, previous data
##          will not be lost even if an error occurs.
##

proc av_append_packet*(s: ptr AVIOContext; pkt: ptr AVPacket; size: cint): cint
## ***********************************************
##  input/output formats

## / Demuxer will use avio_open, no opened file should be provided by the caller.

const
  AVFMT_NOFILE* = 0x00000001
  AVFMT_NEEDNUMBER* = 0x00000002
  AVFMT_SHOW_IDS* = 0x00000008
  AVFMT_GLOBALHEADER* = 0x00000040
  AVFMT_NOTIMESTAMPS* = 0x00000080
  AVFMT_GENERIC_INDEX* = 0x00000100
  AVFMT_TS_DISCONT* = 0x00000200
  AVFMT_VARIABLE_FPS* = 0x00000400
  AVFMT_NODIMENSIONS* = 0x00000800
  AVFMT_NOSTREAMS* = 0x00001000
  AVFMT_NOBINSEARCH* = 0x00002000
  AVFMT_NOGENSEARCH* = 0x00004000
  AVFMT_NO_BYTE_SEEK* = 0x00008000
  AVFMT_ALLOW_FLUSH* = 0x00010000
  AVFMT_TS_NONSTRICT* = 0x00020000
  AVFMT_TS_NEGATIVE* = 0x00040000
  AVFMT_SEEK_TO_PTS* = 0x04000000

## *
##  @addtogroup lavf_encoding
##  @{
##



## *
##  @}
##
## *
##  @addtogroup lavf_decoding
##  @{
##


## *
##  @}
##

## *
##  Track should be used during playback by default.
##  Useful for subtitle track that should be displayed
##  even when user did not explicitly ask for subtitles.
##

const
  AV_DISPOSITION_FORCED* = 0x00000040
  AV_DISPOSITION_HEARING_IMPAIRED* = 0x00000080
  AV_DISPOSITION_VISUAL_IMPAIRED* = 0x00000100
  AV_DISPOSITION_CLEAN_EFFECTS* = 0x00000200

## *
##  The stream is stored in the file as an attached picture/"cover art" (e.g.
##  APIC frame in ID3v2). The first (usually only) packet associated with it
##  will be returned among the first few packets read from the file unless
##  seeking takes place. It can also be accessed at any time in
##  AVStream.attached_pic.
##

const
  AV_DISPOSITION_ATTACHED_PIC* = 0x00000400

## *
##  The stream is sparse, and contains thumbnail images, often corresponding
##  to chapter markers. Only ever used with AV_DISPOSITION_ATTACHED_PIC.
##

const
  AV_DISPOSITION_TIMED_THUMBNAILS* = 0x00000800


## *
##  To specify text track kind (different from subtitles default).
##

const
  AV_DISPOSITION_CAPTIONS* = 0x00010000
  AV_DISPOSITION_DESCRIPTIONS* = 0x00020000
  AV_DISPOSITION_METADATA* = 0x00040000
  AV_DISPOSITION_DEPENDENT* = 0x00080000
  AV_DISPOSITION_STILL_IMAGE* = 0x00100000

## *
##  Options for behavior on timestamp wrap detection.
##


when FF_API_FORMAT_GET_SET:
  ## *
  ##  Accessors for some AVStream fields. These used to be provided for ABI
  ##  compatibility, and do not need to be used anymore.
  ##
  proc av_stream_get_r_frame_rate*(s: ptr AVStream): AVRational
  proc av_stream_set_r_frame_rate*(s: ptr AVStream; r: AVRational)
  when FF_API_LAVF_FFSERVER:
    proc av_stream_get_recommended_encoder_configuration*(s: ptr AVStream): cstring
    proc av_stream_set_recommended_encoder_configuration*(s: ptr AVStream;
        configuration: cstring)
proc av_stream_get_parser*(s: ptr AVStream): ptr AVCodecParserContext
## *
##  Returns the pts of the last muxed packet + its duration
##
##  the retuned value is undefined when used with a demuxer.
##

proc av_stream_get_end_pts*(st: ptr AVStream): int64
const
  AV_PROGRAM_RUNNING* = 1

## *
##  New fields can be added to the end with minor version bumps.
##  Removal, reordering and changes to existing fields require a major
##  version bump.
##  sizeof(AVProgram) must not be used outside libav*.
##




## *
##  Format I/O context.
##  New fields can be added to the end with minor version bumps.
##  Removal, reordering and changes to existing fields require a major
##  version bump.
##  sizeof(AVFormatContext) must not be used outside libav*, use
##  avformat_alloc_context() to create an AVFormatContext.
##
##  Fields can be accessed through AVOptions (av_opt*),
##  the name string used matches the associated command line parameter name and
##  can be found in libavformat/optionsable.h.
##  The AVOption/command line parameter names differ in some cases from the C
##  structure field names for historic reasons or brevity.
##

const
  AVFMT_FLAG_GENPTS* = 0x00000001
  AVFMT_FLAG_IGNIDX* = 0x00000002
  AVFMT_FLAG_NONBLOCK* = 0x00000004
  AVFMT_FLAG_IGNDTS* = 0x00000008
  AVFMT_FLAG_NOFILLIN* = 0x00000010
  AVFMT_FLAG_NOPARSE* = 0x00000020
  AVFMT_FLAG_NOBUFFER* = 0x00000040
  AVFMT_FLAG_CUSTOM_IO* = 0x00000080
  AVFMT_FLAG_DISCARD_CORRUPT* = 0x00000100
  AVFMT_FLAG_FLUSH_PACKETS* = 0x00000200
  AVFMT_FLAG_BITEXACT* = 0x00000400

const
  AVFMT_FLAG_SORT_DTS* = 0x00010000
  AVFMT_FLAG_PRIV_OPT* = 0x00020000

const
  AVFMT_FLAG_FAST_SEEK* = 0x00080000
  AVFMT_FLAG_SHORTEST* = 0x00100000
  AVFMT_FLAG_AUTO_BSF* = 0x00200000

const
  FF_FDEBUG_TS* = 0x00000001

const
  AVFMT_EVENT_FLAG_METADATA_UPDATED* = 0x00000001

const
  AVFMT_AVOID_NEG_TS_AUTO* = -1
  AVFMT_AVOID_NEG_TS_MAKE_NON_NEGATIVE* = 1
  AVFMT_AVOID_NEG_TS_MAKE_ZERO* = 2



when FF_API_FORMAT_GET_SET:
  ## *
  ##  Accessors for some AVFormatContext fields. These used to be provided for ABI
  ##  compatibility, and do not need to be used anymore.
  ##
  proc av_format_get_probe_score*(s: ptr AVFormatContext): cint
  proc av_format_get_video_codec*(s: ptr AVFormatContext): ptr AVCodec
  proc av_format_set_video_codec*(s: ptr AVFormatContext; c: ptr AVCodec)
  proc av_format_get_audio_codec*(s: ptr AVFormatContext): ptr AVCodec
  proc av_format_set_audio_codec*(s: ptr AVFormatContext; c: ptr AVCodec)
  proc av_format_get_subtitle_codec*(s: ptr AVFormatContext): ptr AVCodec
  proc av_format_set_subtitle_codec*(s: ptr AVFormatContext; c: ptr AVCodec)
  proc av_format_get_data_codec*(s: ptr AVFormatContext): ptr AVCodec
  proc av_format_set_data_codec*(s: ptr AVFormatContext; c: ptr AVCodec)
  proc av_format_get_metadata_header_padding*(s: ptr AVFormatContext): cint
  proc av_format_set_metadata_header_padding*(s: ptr AVFormatContext; c: cint)
  proc av_format_get_opaque*(s: ptr AVFormatContext): pointer
  proc av_format_set_opaque*(s: ptr AVFormatContext; opaque: pointer)
  proc av_format_get_control_message_cb*(s: ptr AVFormatContext): av_format_control_message
  proc av_format_set_control_message_cb*(s: ptr AVFormatContext;
                                        callback: av_format_control_message)
  when FF_API_OLD_OPEN_CALLBACKS:
    proc av_format_get_open_cb*(s: ptr AVFormatContext): AVOpenCallback
    proc av_format_set_open_cb*(s: ptr AVFormatContext; callback: AVOpenCallback)
## *
##  This function will cause global side data to be injected in the next packet
##  of each stream as well as after any subsequent seek.
##

proc av_format_inject_global_side_data*(s: ptr AVFormatContext)
## *
##  Returns the method used to set ctx->duration.
##
##  @return AVFMT_DURATION_FROM_PTS, AVFMT_DURATION_FROM_STREAM, or AVFMT_DURATION_FROM_BITRATE.
##

proc av_fmt_ctx_get_duration_estimation_method*(ctx: ptr AVFormatContext): AVDurationEstimationMethod

## *
##  @defgroup lavf_core Core functions
##  @ingroup libavf
##
##  Functions for querying libavformat capabilities, allocating core structures,
##  etc.
##  @{
##
## *
##  Return the LIBAVFORMAT_VERSION_INT constant.
##

proc avformat_version*(): cuint
## *
##  Return the libavformat build-time configuration.
##

proc avformat_configuration*(): cstring
## *
##  Return the libavformat license.
##

proc avformat_license*(): cstring
when FF_API_NEXT:
  ## *
  ##  Initialize libavformat and register all the muxers, demuxers and
  ##  protocols. If you do not call this function, then you can select
  ##  exactly which formats you want to support.
  ##
  ##  @see av_register_input_format()
  ##  @see av_register_output_format()
  ##
  proc av_register_all*()
  proc av_register_input_format*(format: ptr AVInputFormat)
  proc av_register_output_format*(format: ptr AVOutputFormat)
## *
##  Do global initialization of network libraries. This is optional,
##  and not recommended anymore.
##
##  This functions only exists to work around thread-safety issues
##  with older GnuTLS or OpenSSL libraries. If libavformat is linked
##  to newer versions of those libraries, or if you do not use them,
##  calling this function is unnecessary. Otherwise, you need to call
##  this function before any other threads using them are started.
##
##  This function will be deprecated once support for older GnuTLS and
##  OpenSSL libraries is removed, and this function has no purpose
##  anymore.
##

proc avformat_network_init*(): cint
## *
##  Undo the initialization done by avformat_network_init. Call it only
##  once for each time you called avformat_network_init.
##

proc avformat_network_deinit*(): cint
when FF_API_NEXT:
  ## *
  ##  If f is NULL, returns the first registered input format,
  ##  if f is non-NULL, returns the next registered input format after f
  ##  or NULL if f is the last one.
  ##
  proc av_iformat_next*(f: ptr AVInputFormat): ptr AVInputFormat
  ## *
  ##  If f is NULL, returns the first registered output format,
  ##  if f is non-NULL, returns the next registered output format after f
  ##  or NULL if f is the last one.
  ##
  proc av_oformat_next*(f: ptr AVOutputFormat): ptr AVOutputFormat
## *
##  Iterate over all registered muxers.
##
##  @param opaque a pointer where libavformat will store the iteration state. Must
##                point to NULL to start the iteration.
##
##  @return the next registered muxer or NULL when the iteration is
##          finished
##

proc av_muxer_iterate*(opaque: ptr pointer): ptr AVOutputFormat
## *
##  Iterate over all registered demuxers.
##
##  @param opaque a pointer where libavformat will store the iteration state. Must
##                point to NULL to start the iteration.
##
##  @return the next registered demuxer or NULL when the iteration is
##          finished
##

proc av_demuxer_iterate*(opaque: ptr pointer): ptr AVInputFormat
## *
##  Allocate an AVFormatContext.
##  avformat_free_context() can be used to free the context and everything
##  allocated by the framework within it.
##

proc avformat_alloc_context*(): ptr AVFormatContext
## *
##  Free an AVFormatContext and all its streams.
##  @param s context to free
##

proc avformat_free_context*(s: ptr AVFormatContext)
## *
##  Get the AVClass for AVFormatContext. It can be used in combination with
##  AV_OPT_SEARCH_FAKE_OBJ for examining options.
##
##  @see av_opt_find().
##

proc avformat_get_class*(): ptr AVClass
## *
##  Add a new stream to a media file.
##
##  When demuxing, it is called by the demuxer in read_header(). If the
##  flag AVFMTCTX_NOHEADER is set in s.ctx_flags, then it may also
##  be called in read_packet().
##
##  When muxing, should be called by the user before avformat_write_header().
##
##  User is required to call avcodec_close() and avformat_free_context() to
##  clean up the allocation by avformat_new_stream().
##
##  @param s media file handle
##  @param c If non-NULL, the AVCodecContext corresponding to the new stream
##  will be initialized to use this codec. This is needed for e.g. codec-specific
##  defaults to be set, so codec should be provided if it is known.
##
##  @return newly created stream or NULL on error.
##

proc avformat_new_stream*(s: ptr AVFormatContext; c: ptr AVCodec): ptr AVStream
## *
##  Wrap an existing array as stream side data.
##
##  @param st stream
##  @param type side information type
##  @param data the side data array. It must be allocated with the av_malloc()
##              family of functions. The ownership of the data is transferred to
##              st.
##  @param size side information size
##  @return zero on success, a negative AVERROR code on failure. On failure,
##          the stream is unchanged and the data remains owned by the caller.
##

proc av_stream_add_side_data*(st: ptr AVStream; `type`: AVPacketSideDataType;
                             data: ptr uint8; size: csize): cint
## *
##  Allocate new information from stream.
##
##  @param stream stream
##  @param type desired side information type
##  @param size side information size
##  @return pointer to fresh allocated data or NULL otherwise
##

proc av_stream_new_side_data*(stream: ptr AVStream; `type`: AVPacketSideDataType;
                             size: cint): ptr uint8
## *
##  Get side information from stream.
##
##  @param stream stream
##  @param type desired side information type
##  @param size pointer for side information size to store (optional)
##  @return pointer to data if present or NULL otherwise
##

proc av_stream_get_side_data*(stream: ptr AVStream; `type`: AVPacketSideDataType;
                             size: ptr cint): ptr uint8
proc av_new_program*(s: ptr AVFormatContext; id: cint): ptr AVProgram
## *
##  @}
##
## *
##  Allocate an AVFormatContext for an output format.
##  avformat_free_context() can be used to free the context and
##  everything allocated by the framework within it.
##
##  @param *ctx is set to the created format context, or to NULL in
##  case of failure
##  @param oformat format to use for allocating the context, if NULL
##  format_name and filename are used instead
##  @param format_name the name of output format to use for allocating the
##  context, if NULL filename is used instead
##  @param filename the name of the filename to use for allocating the
##  context, may be NULL
##  @return >= 0 in case of success, a negative AVERROR code in case of
##  failure
##

proc avformat_alloc_output_context2*(ctx: ptr ptr AVFormatContext;
                                    oformat: ptr AVOutputFormat;
                                    format_name: cstring; filename: cstring): cint
## *
##  @addtogroup lavf_decoding
##  @{
##
## *
##  Find AVInputFormat based on the short name of the input format.
##

proc av_find_input_format*(short_name: cstring): ptr AVInputFormat
## *
##  Guess the file format.
##
##  @param pd        data to be probed
##  @param is_opened Whether the file is already opened; determines whether
##                   demuxers with or without AVFMT_NOFILE are probed.
##

proc av_probe_input_format*(pd: ptr AVProbeData; is_opened: cint): ptr AVInputFormat
## *
##  Guess the file format.
##
##  @param pd        data to be probed
##  @param is_opened Whether the file is already opened; determines whether
##                   demuxers with or without AVFMT_NOFILE are probed.
##  @param score_max A probe score larger that this is required to accept a
##                   detection, the variable is set to the actual detection
##                   score afterwards.
##                   If the score is <= AVPROBE_SCORE_MAX / 4 it is recommended
##                   to retry with a larger probe buffer.
##

proc av_probe_input_format2*(pd: ptr AVProbeData; is_opened: cint; score_max: ptr cint): ptr AVInputFormat
## *
##  Guess the file format.
##
##  @param is_opened Whether the file is already opened; determines whether
##                   demuxers with or without AVFMT_NOFILE are probed.
##  @param score_ret The score of the best detection.
##

proc av_probe_input_format3*(pd: ptr AVProbeData; is_opened: cint; score_ret: ptr cint): ptr AVInputFormat
## *
##  Probe a bytestream to determine the input format. Each time a probe returns
##  with a score that is too low, the probe buffer size is increased and another
##  attempt is made. When the maximum probe size is reached, the input format
##  with the highest score is returned.
##
##  @param pb the bytestream to probe
##  @param fmt the input format is put here
##  @param url the url of the stream
##  @param logctx the log context
##  @param offset the offset within the bytestream to probe from
##  @param max_probe_size the maximum probe buffer size (zero for default)
##  @return the score in case of success, a negative value corresponding to an
##          the maximal score is AVPROBE_SCORE_MAX
##  AVERROR code otherwise
##

proc av_probe_input_buffer2*(pb: ptr AVIOContext; fmt: ptr ptr AVInputFormat;
                            url: cstring; logctx: pointer; offset: cuint;
                            max_probe_size: cuint): cint
## *
##  Like av_probe_input_buffer2() but returns 0 on success
##

proc av_probe_input_buffer*(pb: ptr AVIOContext; fmt: ptr ptr AVInputFormat;
                           url: cstring; logctx: pointer; offset: cuint;
                           max_probe_size: cuint): cint
## *
##  Open an input stream and read the header. The codecs are not opened.
##  The stream must be closed with avformat_close_input().
##
##  @param ps Pointer to user-supplied AVFormatContext (allocated by avformat_alloc_context).
##            May be a pointer to NULL, in which case an AVFormatContext is allocated by this
##            function and written into ps.
##            Note that a user-supplied AVFormatContext will be freed on failure.
##  @param url URL of the stream to open.
##  @param fmt If non-NULL, this parameter forces a specific input format.
##             Otherwise the format is autodetected.
##  @param options  A dictionary filled with AVFormatContext and demuxer-private options.
##                  On return this parameter will be destroyed and replaced with a dict containing
##                  options that were not found. May be NULL.
##
##  @return 0 on success, a negative AVERROR on failure.
##
##  @note If you want to use custom IO, preallocate the format context and set its pb field.
##

proc avformat_open_input*(ps: ptr ptr AVFormatContext; url: cstring;
                         fmt: ptr AVInputFormat; options: ptr ptr AVDictionary): cint
proc av_demuxer_open*(ic: ptr AVFormatContext): cint
## *
##  Read packets of a media file to get stream information. This
##  is useful for file formats with no headers such as MPEG. This
##  function also computes the real framerate in case of MPEG-2 repeat
##  frame mode.
##  The logical file position is not changed by this function;
##  examined packets may be buffered for later processing.
##
##  @param ic media file handle
##  @param options  If non-NULL, an ic.nb_streams long array of pointers to
##                  dictionaries, where i-th member contains options for
##                  codec corresponding to i-th stream.
##                  On return each dictionary will be filled with options that were not found.
##  @return >=0 if OK, AVERROR_xxx on error
##
##  @note this function isn't guaranteed to open all the codecs, so
##        options being non-empty at return is a perfectly normal behavior.
##
##  @todo Let the user decide somehow what information is needed so that
##        we do not waste time getting stuff the user does not need.
##

proc avformat_find_stream_info*(ic: ptr AVFormatContext;
                               options: ptr ptr AVDictionary): cint
## *
##  Find the programs which belong to a given stream.
##
##  @param ic    media file handle
##  @param last  the last found program, the search will start after this
##               program, or from the beginning if it is NULL
##  @param s     stream index
##  @return the next program which belongs to s, NULL if no program is found or
##          the last program is not among the programs of ic.
##

proc av_find_program_from_stream*(ic: ptr AVFormatContext; last: ptr AVProgram; s: cint): ptr AVProgram
proc av_program_add_stream_index*(ac: ptr AVFormatContext; progid: cint; idx: cuint)
## *
##  Find the "best" stream in the file.
##  The best stream is determined according to various heuristics as the most
##  likely to be what the user expects.
##  If the decoder parameter is non-NULL, av_find_best_stream will find the
##  default decoder for the stream's codec; streams for which no decoder can
##  be found are ignored.
##
##  @param ic                media file handle
##  @param type              stream type: video, audio, subtitles, etc.
##  @param wanted_stream_nb  user-requested stream number,
##                           or -1 for automatic selection
##  @param related_stream    try to find a stream related (eg. in the same
##                           program) to this one, or -1 if none
##  @param decoder_ret       if non-NULL, returns the decoder for the
##                           selected stream
##  @param flags             flags; none are currently defined
##  @return  the non-negative stream number in case of success,
##           AVERROR_STREAM_NOT_FOUND if no stream with the requested type
##           could be found,
##           AVERROR_DECODER_NOT_FOUND if streams were found but no decoder
##  @note  If av_find_best_stream returns successfully and decoder_ret is not
##         NULL, then *decoder_ret is guaranteed to be set to a valid AVCodec.
##

proc av_find_best_stream*(ic: ptr AVFormatContext; `type`: AVMediaType;
                         wanted_stream_nb: cint; related_stream: cint;
                         decoder_ret: ptr ptr AVCodec; flags: cint): cint
## *
##  Return the next frame of a stream.
##  This function returns what is stored in the file, and does not validate
##  that what is there are valid frames for the decoder. It will split what is
##  stored in the file into frames and return one for each call. It will not
##  omit invalid data between valid frames so as to give the decoder the maximum
##  information possible for decoding.
##
##  If pkt->buf is NULL, then the packet is valid until the next
##  av_read_frame() or until avformat_close_input(). Otherwise the packet
##  is valid indefinitely. In both cases the packet must be freed with
##  av_packet_unref when it is no longer needed. For video, the packet contains
##  exactly one frame. For audio, it contains an integer number of frames if each
##  frame has a known fixed size (e.g. PCM or ADPCM data). If the audio frames
##  have a variable size (e.g. MPEG audio), then it contains one frame.
##
##  pkt->pts, pkt->dts and pkt->duration are always set to correct
##  values in AVStream.time_base units (and guessed if the format cannot
##  provide them). pkt->pts can be AV_NOPTS_VALUE if the video format
##  has B-frames, so it is better to rely on pkt->dts if you do not
##  decompress the payload.
##
##  @return 0 if OK, < 0 on error or end of file
##

proc av_read_frame*(s: ptr AVFormatContext; pkt: ptr AVPacket): cint
## *
##  Seek to the keyframe at timestamp.
##  'timestamp' in 'stream_index'.
##
##  @param s media file handle
##  @param stream_index If stream_index is (-1), a default
##  stream is selected, and timestamp is automatically converted
##  from AV_TIME_BASE units to the stream specific time_base.
##  @param timestamp Timestamp in AVStream.time_base units
##         or, if no stream is specified, in AV_TIME_BASE units.
##  @param flags flags which select direction and seeking mode
##  @return >= 0 on success
##

proc av_seek_frame*(s: ptr AVFormatContext; stream_index: cint; timestamp: int64;
                   flags: cint): cint
## *
##  Seek to timestamp ts.
##  Seeking will be done so that the point from which all active streams
##  can be presented successfully will be closest to ts and within min/maxs.
##  Active streams are all streams that have AVStream.discard < AVDISCARD_ALL.
##
##  If flags contain AVSEEK_FLAG_BYTE, then all timestamps are in bytes and
##  are the file position (this may not be supported by all demuxers).
##  If flags contain AVSEEK_FLAG_FRAME, then all timestamps are in frames
##  in the stream with stream_index (this may not be supported by all demuxers).
##  Otherwise all timestamps are in units of the stream selected by stream_index
##  or if stream_index is -1, in AV_TIME_BASE units.
##  If flags contain AVSEEK_FLAG_ANY, then non-keyframes are treated as
##  keyframes (this may not be supported by all demuxers).
##  If flags contain AVSEEK_FLAG_BACKWARD, it is ignored.
##
##  @param s media file handle
##  @param stream_index index of the stream which is used as time base reference
##  @param mins smallest acceptable timestamp
##  @param ts target timestamp
##  @param maxs largest acceptable timestamp
##  @param flags flags
##  @return >=0 on success, error code otherwise
##
##  @note This is part of the new seek API which is still under construction.
##        Thus do not use this yet. It may change at any time, do not expect
##        ABI compatibility yet!
##

proc avformat_seek_file*(s: ptr AVFormatContext; stream_index: cint; mins: int64;
                        ts: int64; maxs: int64; flags: cint): cint
## *
##  Discard all internally buffered data. This can be useful when dealing with
##  discontinuities in the byte stream. Generally works only with formats that
##  can resync. This includes headerless formats like MPEG-TS/TS but should also
##  work with NUT, Ogg and in a limited way AVI for example.
##
##  The set of streams, the detected duration, stream parameters and codecs do
##  not change when calling this function. If you want a complete reset, it's
##  better to open a new AVFormatContext.
##
##  This does not flush the AVIOContext (s->pb). If necessary, call
##  avio_flush(s->pb) before calling this function.
##
##  @param s media file handle
##  @return >=0 on success, error code otherwise
##

proc avformat_flush*(s: ptr AVFormatContext): cint
## *
##  Start playing a network-based stream (e.g. RTSP stream) at the
##  current position.
##

proc av_read_play*(s: ptr AVFormatContext): cint
## *
##  Pause a network-based stream (e.g. RTSP stream).
##
##  Use av_read_play() to resume it.
##

proc av_read_pause*(s: ptr AVFormatContext): cint
## *
##  Close an opened input AVFormatContext. Free it and all its contents
##  and set *s to NULL.
##

proc avformat_close_input*(s: ptr ptr AVFormatContext)
## *
##  @}
##

const
  AVSEEK_FLAG_BACKWARD* = 1
  AVSEEK_FLAG_BYTE* = 2
  AVSEEK_FLAG_ANY* = 4
  AVSEEK_FLAG_FRAME* = 8

## *
##  @addtogroup lavf_encoding
##  @{
##

const
  AVSTREAM_INIT_IN_WRITE_HEADER* = 0
  AVSTREAM_INIT_IN_INIT_OUTPUT* = 1

## *
##  Allocate the stream private data and write the stream header to
##  an output media file.
##
##  @param s Media file handle, must be allocated with avformat_alloc_context().
##           Its oformat field must be set to the desired output format;
##           Its pb field must be set to an already opened AVIOContext.
##  @param options  An AVDictionary filled with AVFormatContext and muxer-private options.
##                  On return this parameter will be destroyed and replaced with a dict containing
##                  options that were not found. May be NULL.
##
##  @return AVSTREAM_INIT_IN_WRITE_HEADER on success if the codec had not already been fully initialized in avformat_init,
##          AVSTREAM_INIT_IN_INIT_OUTPUT  on success if the codec had already been fully initialized in avformat_init,
##          negative AVERROR on failure.
##
##  @see av_opt_find, av_dict_set, avio_open, av_oformat_next, avformat_init_output.
##

proc avformat_write_header*(s: ptr AVFormatContext; options: ptr ptr AVDictionary): cint
## *
##  Allocate the stream private data and initialize the codec, but do not write the header.
##  May optionally be used before avformat_write_header to initialize stream parameters
##  before actually writing the header.
##  If using this function, do not pass the same options to avformat_write_header.
##
##  @param s Media file handle, must be allocated with avformat_alloc_context().
##           Its oformat field must be set to the desired output format;
##           Its pb field must be set to an already opened AVIOContext.
##  @param options  An AVDictionary filled with AVFormatContext and muxer-private options.
##                  On return this parameter will be destroyed and replaced with a dict containing
##                  options that were not found. May be NULL.
##
##  @return AVSTREAM_INIT_IN_WRITE_HEADER on success if the codec requires avformat_write_header to fully initialize,
##          AVSTREAM_INIT_IN_INIT_OUTPUT  on success if the codec has been fully initialized,
##          negative AVERROR on failure.
##
##  @see av_opt_find, av_dict_set, avio_open, av_oformat_next, avformat_write_header.
##

proc avformat_init_output*(s: ptr AVFormatContext; options: ptr ptr AVDictionary): cint
## *
##  Write a packet to an output media file.
##
##  This function passes the packet directly to the muxer, without any buffering
##  or reordering. The caller is responsible for correctly interleaving the
##  packets if the format requires it. Callers that want libavformat to handle
##  the interleaving should call av_interleaved_write_frame() instead of this
##  function.
##
##  @param s media file handle
##  @param pkt The packet containing the data to be written. Note that unlike
##             av_interleaved_write_frame(), this function does not take
##             ownership of the packet passed to it (though some muxers may make
##             an internal reference to the input packet).
##             <br>
##             This parameter can be NULL (at any time, not just at the end), in
##             order to immediately flush data buffered within the muxer, for
##             muxers that buffer up data internally before writing it to the
##             output.
##             <br>
##             Packet's @ref AVPacket.stream_index "stream_index" field must be
##             set to the index of the corresponding stream in @ref
##             AVFormatContext.streams "s->streams".
##             <br>
##             The timestamps (@ref AVPacket.pts "pts", @ref AVPacket.dts "dts")
##             must be set to correct values in the stream's timebase (unless the
##             output format is flagged with the AVFMT_NOTIMESTAMPS flag, then
##             they can be set to AV_NOPTS_VALUE).
##             The dts for subsequent packets passed to this function must be strictly
##             increasing when compared in their respective timebases (unless the
##             output format is flagged with the AVFMT_TS_NONSTRICT, then they
##             merely have to be nondecreasing).  @ref AVPacket.duration
##             "duration") should also be set if known.
##  @return < 0 on error, = 0 if OK, 1 if flushed and there is no more data to flush
##
##  @see av_interleaved_write_frame()
##

proc av_write_frame*(s: ptr AVFormatContext; pkt: ptr AVPacket): cint
## *
##  Write a packet to an output media file ensuring correct interleaving.
##
##  This function will buffer the packets internally as needed to make sure the
##  packets in the output file are properly interleaved in the order of
##  increasing dts. Callers doing their own interleaving should call
##  av_write_frame() instead of this function.
##
##  Using this function instead of av_write_frame() can give muxers advance
##  knowledge of future packets, improving e.g. the behaviour of the mp4
##  muxer for VFR content in fragmenting mode.
##
##  @param s media file handle
##  @param pkt The packet containing the data to be written.
##             <br>
##             If the packet is reference-counted, this function will take
##             ownership of this reference and unreference it later when it sees
##             fit.
##             The caller must not access the data through this reference after
##             this function returns. If the packet is not reference-counted,
##             libavformat will make a copy.
##             <br>
##             This parameter can be NULL (at any time, not just at the end), to
##             flush the interleaving queues.
##             <br>
##             Packet's @ref AVPacket.stream_index "stream_index" field must be
##             set to the index of the corresponding stream in @ref
##             AVFormatContext.streams "s->streams".
##             <br>
##             The timestamps (@ref AVPacket.pts "pts", @ref AVPacket.dts "dts")
##             must be set to correct values in the stream's timebase (unless the
##             output format is flagged with the AVFMT_NOTIMESTAMPS flag, then
##             they can be set to AV_NOPTS_VALUE).
##             The dts for subsequent packets in one stream must be strictly
##             increasing (unless the output format is flagged with the
##             AVFMT_TS_NONSTRICT, then they merely have to be nondecreasing).
##             @ref AVPacket.duration "duration") should also be set if known.
##
##  @return 0 on success, a negative AVERROR on error. Libavformat will always
##          take care of freeing the packet, even if this function fails.
##
##  @see av_write_frame(), AVFormatContext.max_interleave_delta
##

proc av_interleaved_write_frame*(s: ptr AVFormatContext; pkt: ptr AVPacket): cint
## *
##  Write an uncoded frame to an output media file.
##
##  The frame must be correctly interleaved according to the container
##  specification; if not, then av_interleaved_write_frame() must be used.
##
##  See av_interleaved_write_frame() for details.
##

proc av_write_uncoded_frame*(s: ptr AVFormatContext; stream_index: cint;
                            frame: ptr AVFrame): cint
## *
##  Write an uncoded frame to an output media file.
##
##  If the muxer supports it, this function makes it possible to write an AVFrame
##  structure directly, without encoding it into a packet.
##  It is mostly useful for devices and similar special muxers that use raw
##  video or PCM data and will not serialize it into a byte stream.
##
##  To test whether it is possible to use it with a given muxer and stream,
##  use av_write_uncoded_frame_query().
##
##  The caller gives up ownership of the frame and must not access it
##  afterwards.
##
##  @return  >=0 for success, a negative code on error
##

proc av_interleaved_write_uncoded_frame*(s: ptr AVFormatContext; stream_index: cint;
                                        frame: ptr AVFrame): cint
## *
##  Test whether a muxer supports uncoded frame.
##
##  @return  >=0 if an uncoded frame can be written to that muxer and stream,
##           <0 if not
##

proc av_write_uncoded_frame_query*(s: ptr AVFormatContext; stream_index: cint): cint
## *
##  Write the stream trailer to an output media file and free the
##  file private data.
##
##  May only be called after a successful call to avformat_write_header.
##
##  @param s media file handle
##  @return 0 if OK, AVERROR_xxx on error
##

proc av_writerailer*(s: ptr AVFormatContext): cint
## *
##  Return the output format in the list of registered output formats
##  which best matches the provided parameters, or return NULL if
##  there is no match.
##
##  @param short_name if non-NULL checks if short_name matches with the
##  names of the registered formats
##  @param filename if non-NULL checks if filename terminates with the
##  extensions of the registered formats
##  @param mimeype if non-NULL checks if mimeype matches with the
##  MIME type of the registered formats
##

proc av_guess_format*(short_name: cstring; filename: cstring; mimeype: cstring): ptr AVOutputFormat
## *
##  Guess the codec ID based upon muxer and filename.
##

proc av_guess_codec*(fmt: ptr AVOutputFormat; short_name: cstring; filename: cstring;
                    mimeype: cstring; `type`: AVMediaType): AVCodecID
## *
##  Get timing information for the data currently output.
##  The exact meaning of "currently output" depends on the format.
##  It is mostly relevant for devices that have an internal buffer and/or
##  work in real time.
##  @param s          media file handle
##  @param stream     stream in the media file
##  @param[out] dts   DTS of the last packet output for the stream, in stream
##                    time_base units
##  @param[out] wall  absolute time when that packet whas output,
##                    in microsecond
##  @return  0 if OK, AVERROR(ENOSYS) if the format does not support it
##  Note: some formats or devices may not allow to measure dts and wall
##  atomically.
##

proc av_get_outputimestamp*(s: ptr AVFormatContext; stream: cint; dts: ptr int64;
                             wall: ptr int64): cint
## *
##  @}
##
## *
##  @defgroup lavf_misc Utility functions
##  @ingroup libavf
##  @{
##
##  Miscellaneous utility functions related to both muxing and demuxing
##  (or neither).
##
## *
##  Send a nice hexadecimal dump of a buffer to the specified file stream.
##
##  @param f The file stream pointer where the dump should be sent to.
##  @param buf buffer
##  @param size buffer size
##
##  @see av_hex_dump_log, av_pkt_dump2, av_pkt_dump_log2
##

proc av_hex_dump*(f: ptr FILE; buf: ptr uint8; size: cint)
## *
##  Send a nice hexadecimal dump of a buffer to the log.
##
##  @param avcl A pointer to an arbitrary struct of which the first field is a
##  pointer to an AVClass struct.
##  @param level The importance level of the message, lower values signifying
##  higher importance.
##  @param buf buffer
##  @param size buffer size
##
##  @see av_hex_dump, av_pkt_dump2, av_pkt_dump_log2
##

proc av_hex_dump_log*(avcl: pointer; level: cint; buf: ptr uint8; size: cint)
## *
##  Send a nice dump of a packet to the specified file stream.
##
##  @param f The file stream pointer where the dump should be sent to.
##  @param pkt packet to dump
##  @param dump_payload True if the payload must be displayed, too.
##  @param st AVStream that the packet belongs to
##

proc av_pkt_dump2*(f: ptr FILE; pkt: ptr AVPacket; dump_payload: cint; st: ptr AVStream)
## *
##  Send a nice dump of a packet to the log.
##
##  @param avcl A pointer to an arbitrary struct of which the first field is a
##  pointer to an AVClass struct.
##  @param level The importance level of the message, lower values signifying
##  higher importance.
##  @param pkt packet to dump
##  @param dump_payload True if the payload must be displayed, too.
##  @param st AVStream that the packet belongs to
##

proc av_pkt_dump_log2*(avcl: pointer; level: cint; pkt: ptr AVPacket;
                      dump_payload: cint; st: ptr AVStream)
## *
##  Get the AVCodecID for the given codec tag tag.
##  If no codec id is found returns AV_CODEC_ID_NONE.
##
##  @param tags list of supported codec_id-codecag pairs, as stored
##  in AVInputFormat.codecag and AVOutputFormat.codecag
##  @param tag  codec tag to match to a codec ID
##

proc av_codec_get_id*(tags: ptr ptr AVCodecTag; tag: cuint): AVCodecID
## *
##  Get the codec tag for the given codec id id.
##  If no codec tag is found returns 0.
##
##  @param tags list of supported codec_id-codecag pairs, as stored
##  in AVInputFormat.codecag and AVOutputFormat.codecag
##  @param id   codec ID to match to a codec tag
##

proc av_codec_getag*(tags: ptr ptr AVCodecTag; id: AVCodecID): cuint
## *
##  Get the codec tag for the given codec id.
##
##  @param tags list of supported codec_id - codecag pairs, as stored
##  in AVInputFormat.codecag and AVOutputFormat.codecag
##  @param id codec id that should be searched for in the list
##  @param tag A pointer to the found tag
##  @return 0 if id was not found in tags, > 0 if it was found
##

proc av_codec_getag2*(tags: ptr ptr AVCodecTag; id: AVCodecID; tag: ptr cuint): cint
proc av_find_default_stream_index*(s: ptr AVFormatContext): cint
## *
##  Get the index for a specific timestamp.
##
##  @param st        stream that the timestamp belongs to
##  @param timestamp timestamp to retrieve the index for
##  @param flags if AVSEEK_FLAG_BACKWARD then the returned index will correspond
##                  to the timestamp which is <= the requested one, if backward
##                  is 0, then it will be >=
##               if AVSEEK_FLAG_ANY seek to any frame, only keyframes otherwise
##  @return < 0 if no such timestamp could be found
##

proc av_index_searchimestamp*(st: ptr AVStream; timestamp: int64; flags: cint): cint
## *
##  Add an index entry into a sorted list. Update the entry if the list
##  already contains it.
##
##  @param timestamp timestamp in the time base of the given stream
##

proc av_add_index_entry*(st: ptr AVStream; pos: int64; timestamp: int64; size: cint;
                        distance: cint; flags: cint): cint
## *
##  Split a URL string into components.
##
##  The pointers to buffers for storing individual components may be null,
##  in order to ignore that component. Buffers for components not found are
##  set to empty strings. If the port is not found, it is set to a negative
##  value.
##
##  @param proto the buffer for the protocol
##  @param proto_size the size of the proto buffer
##  @param authorization the buffer for the authorization
##  @param authorization_size the size of the authorization buffer
##  @param hostname the buffer for the host name
##  @param hostname_size the size of the hostname buffer
##  @param port_ptr a pointer to store the port number in
##  @param path the buffer for the path
##  @param path_size the size of the path buffer
##  @param url the URL to split
##

proc av_url_split*(proto: cstring; proto_size: cint; authorization: cstring;
                  authorization_size: cint; hostname: cstring; hostname_size: cint;
                  port_ptr: ptr cint; path: cstring; path_size: cint; url: cstring)
## *
##  Print detailed information about the input or output format, such as
##  duration, bitrate, streams, container, programs, metadata, side data,
##  codec and time base.
##
##  @param ic        the context to analyze
##  @param index     index of the stream to dump information about
##  @param url       the URL to print, such as source or destination file
##  @param is_output Select whether the specified context is an input(0) or output(1)
##

proc av_dump_format*(ic: ptr AVFormatContext; index: cint; url: cstring; is_output: cint)
const
  AV_FRAME_FILENAME_FLAGS_MULTIPLE* = 1

## *
##  Return in 'buf' the path with '%d' replaced by a number.
##
##  Also handles the '%0nd' format where 'n' is the total number
##  of digits and '%%'.
##
##  @param buf destination buffer
##  @param buf_size destination buffer size
##  @param path numbered sequence string
##  @param number frame number
##  @param flags AV_FRAME_FILENAME_FLAGS_*
##  @return 0 if OK, -1 on format error
##

proc av_get_frame_filename2*(buf: cstring; buf_size: cint; path: cstring; number: cint;
                            flags: cint): cint
proc av_get_frame_filename*(buf: cstring; buf_size: cint; path: cstring; number: cint): cint
## *
##  Check whether filename actually is a numbered sequence generator.
##
##  @param filename possible numbered sequence string
##  @return 1 if a valid numbered sequence string, 0 otherwise
##

proc av_filename_numberest*(filename: cstring): cint
## *
##  Generate an SDP for an RTP session.
##
##  Note, this overwrites the id values of AVStreams in the muxer contexts
##  for getting unique dynamic payload types.
##
##  @param ac array of AVFormatContexts describing the RTP streams. If the
##            array is composed by only one context, such context can contain
##            multiple AVStreams (one AVStream per RTP stream). Otherwise,
##            all the contexts in the array (an AVCodecContext per RTP stream)
##            must contain only one AVStream.
##  @param n_files number of AVCodecContexts contained in ac
##  @param buf buffer where the SDP will be stored (must be allocated by
##             the caller)
##  @param size the size of the buffer
##  @return 0 if OK, AVERROR_xxx on error
##

proc av_sdp_create*(ac: ptr ptr AVFormatContext; n_files: cint; buf: cstring; size: cint): cint
## *
##  Return a positive value if the given filename has one of the given
##  extensions, 0 otherwise.
##
##  @param filename   file name to check against the given extensions
##  @param extensions a comma-separated list of filename extensions
##

proc av_match_ext*(filename: cstring; extensions: cstring): cint
## *
##  Test if the given container can store a codec.
##
##  @param ofmt           container to check for compatibility
##  @param codec_id       codec to potentially store in container
##  @param std_compliance standards compliance level, one of FF_COMPLIANCE_*
##
##  @return 1 if codec with ID codec_id can be stored in ofmt, 0 if it cannot.
##          A negative number if this information is not available.
##

proc avformat_query_codec*(ofmt: ptr AVOutputFormat; codec_id: AVCodecID;
                          std_compliance: cint): cint
## *
##  @defgroup riff_fourcc RIFF FourCCs
##  @{
##  Get the tables mapping RIFF FourCCs to libavcodec AVCodecIDs. The tables are
##  meant to be passed to av_codec_get_id()/av_codec_getag() as in the
##  following code:
##  @code
##  uint32 tag = MKTAG('H', '2', '6', '4');
##  const struct AVCodecTag *table[] = { avformat_get_riff_videoags(), 0 };
##  enum AVCodecID id = av_codec_get_id(table, tag);
##  @endcode
##
## *
##  @return the table mapping RIFF FourCCs for video to libavcodec AVCodecID.
##

proc avformat_get_riff_videoags*(): ptr AVCodecTag
## *
##  @return the table mapping RIFF FourCCs for audio to AVCodecID.
##

proc avformat_get_riff_audioags*(): ptr AVCodecTag
## *
##  @return the table mapping MOV FourCCs for video to libavcodec AVCodecID.
##

proc avformat_get_mov_videoags*(): ptr AVCodecTag
## *
##  @return the table mapping MOV FourCCs for audio to AVCodecID.
##

proc avformat_get_mov_audioags*(): ptr AVCodecTag
## *
##  @}
##
## *
##  Guess the sample aspect ratio of a frame, based on both the stream and the
##  frame aspect ratio.
##
##  Since the frame aspect ratio is set by the codec but the stream aspect ratio
##  is set by the demuxer, these two may not be equal. This function tries to
##  return the value that you should use if you would like to display the frame.
##
##  Basic logic is to use the stream aspect ratio if it is set to something sane
##  otherwise use the frame aspect ratio. This way a container setting, which is
##  usually easy to modify can override the coded value in the frames.
##
##  @param format the format context which the stream is part of
##  @param stream the stream which the frame is part of
##  @param frame the frame with the aspect ratio to be determined
##  @return the guessed (valid) sample_aspect_ratio, 0/1 if no idea
##

proc av_guess_sample_aspect_ratio*(format: ptr AVFormatContext;
                                  stream: ptr AVStream; frame: ptr AVFrame): AVRational
## *
##  Guess the frame rate, based on both the container and codec information.
##
##  @param ctx the format context which the stream is part of
##  @param stream the stream which the frame is part of
##  @param frame the frame for which the frame rate should be determined, may be NULL
##  @return the guessed (valid) frame rate, 0/1 if no idea
##

proc av_guess_frame_rate*(ctx: ptr AVFormatContext; stream: ptr AVStream;
                         frame: ptr AVFrame): AVRational
## *
##  Check if the stream st contained in s is matched by the stream specifier
##  spec.
##
##  See the "stream specifiers" chapter in the documentation for the syntax
##  of spec.
##
##  @return  >0 if st is matched by spec;
##           0  if st is not matched by spec;
##           AVERROR code if spec is invalid
##
##  @note  A stream specifier can match several streams in the format.
##

proc avformat_match_stream_specifier*(s: ptr AVFormatContext; st: ptr AVStream;
                                     spec: cstring): cint
proc avformat_queue_attached_pictures*(s: ptr AVFormatContext): cint
when FF_API_OLD_BSF:
  ## *
  ##  Apply a list of bitstream filters to a packet.
  ##
  ##  @param codec AVCodecContext, usually from an AVStream
  ##  @param pkt the packet to apply filters to. If, on success, the returned
  ##         packet has size == 0 and side_data_elems == 0, it indicates that
  ##         the packet should be dropped
  ##  @param bsfc a NULL-terminated list of filters to apply
  ##  @return  >=0 on success;
  ##           AVERROR code on failure
  ##
  proc av_apply_bitstream_filters*(codec: ptr AVCodecContext; pkt: ptr AVPacket;
                                  bsfc: ptr AVBitStreamFilterContext): cint
type
  AVTimebaseSource* = enum
    AVFMT_TBCF_AUTO = -1, AVFMT_TBCF_DECODER, AVFMT_TBCF_DEMUXER, ## #if FF_API_R_FRAME_RATE
    AVFMT_TBCF_R_FRAMERATE    ## #endif


## *
##  Transfer internal timing information from one stream to another.
##
##  This function is useful when doing stream copy.
##
##  @param ofmt     target output format for ost
##  @param ost      output stream which needs timings copy and adjustments
##  @param ist      reference input stream to copy timings from
##  @param copyb  define from where the stream codec timebase needs to be imported
##

proc avformatransfer_internal_streamiming_info*(ofmt: ptr AVOutputFormat;
    ost: ptr AVStream; ist: ptr AVStream; copyb: AVTimebaseSource): cint
## *
##  Get the internal codec timebase from a stream.
##
##  @param st  input stream to extract the timebase from
##

proc av_stream_get_codecimebase*(st: ptr AVStream): AVRational
## *
##  @}
##
