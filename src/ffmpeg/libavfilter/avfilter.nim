##
##  filter layer
##  Copyright (c) 2007 Bobby Bingham
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
##  @ingroup lavfi
##  Main libavfilter public API header
##
## *
##  @defgroup lavfi libavfilter
##  Graph-based frame editing library.
##
##  @{
##

#[
import
  libavutil/attributes, libavutil/avutil, libavutil/buffer, libavutil/dict,
  libavutil/frame, libavutil/log, libavutil/samplefmt, libavutil/pixfmt,
  libavutil/rational, libavfilter/version
  ]#
import ../utiltypes
import ../libavutil/[buffer, dict, rational]
import version

{.pragma: avfilter, importc, header: "<libavfilter/avfilter.h>".}

## *
##  Process multiple parts of the frame concurrently.
##

const
  AVFILTER_THREAD_SLICE* = (1 shl 0)

const
  AVLINK_UINIT* = 0
  AVLINK_STARTINIT* = 1
  AVLINK_INIT* = 2

type
  AVFilterInternal* {.avfilter.} = object
  AVFilterPad* {.avfilter.} = object
  AVFilterFormats* {.avfilter.} = object
  AVFilterGraphInternal* {.avfilter.} = object
  AVFilterChannelLayouts* {.importc: "struct $1",
    header: "<libavfilter/avfilter.h>".} = object
  AVFilterCommand* {.importc: "struct $1",
    header: "<libavfilter/avfilter.h>".} = object
  AVFilter* {.avfilter.} = object
    name*: cstring ## *
                 ##  Filter name. Must be non-NULL and unique among filters.
                 ##
    ## *
    ##  A description of the filter. May be NULL.
    ##
    ##  You should use the NULL_IF_CONFIG_SMALL() macro to define it.
    ##
    description*: cstring ## *
                        ##  List of inputs, terminated by a zeroed element.
                        ##
                        ##  NULL if there are no (static) inputs. Instances of filters with
                        ##  AVFILTER_FLAG_DYNAMIC_INPUTS set may have more inputs than present in
                        ##  this list.
                        ##
    inputs*: ptr AVFilterPad ## *
                          ##  List of outputs, terminated by a zeroed element.
                          ##
                          ##  NULL if there are no (static) outputs. Instances of filters with
                          ##  AVFILTER_FLAG_DYNAMIC_OUTPUTS set may have more outputs than present in
                          ##  this list.
                          ##
    outputs*: ptr AVFilterPad ## *
                           ##  A class for the private data, used to declare filter private AVOptions.
                           ##  This field is NULL for filters that do not declare any options.
                           ##
                           ##  If this field is non-NULL, the first member of the filter private data
                           ##  must be a pointer to AVClass, which will be set by libavfilter generic
                           ##  code to this class.
                           ##
    priv_class*: ptr AVClass    ## *
                          ##  A combination of AVFILTER_FLAG_*
                          ##
    flags*: cint ## ****************************************************************
               ##  All fields below this line are not part of the public API. They
               ##  may not be used outside of libavfilter and can be changed and
               ##  removed at will.
               ##  New public fields should be added right above.
               ## ****************************************************************
               ##
               ## *
               ##  Filter pre-initialization function
               ##
               ##  This callback will be called immediately after the filter context is
               ##  allocated, to allow allocating and initing sub-objects.
               ##
               ##  If this callback is not NULL, the uninit callback will be called on
               ##  allocation failure.
               ##
               ##  @return 0 on success,
               ##          AVERROR code on failure (but the code will be
               ##            dropped and treated as ENOMEM by the calling code)
               ##
    preinit*: proc (ctx: ptr AVFilterContext): cint ## *
                                              ##  Filter initialization function.
                                              ##
                                              ##  This callback will be called only once during the filter lifetime, after
                                              ##  all the options have been set, but before links between filters are
                                              ##  established and format negotiation is done.
                                              ##
                                              ##  Basic filter initialization should be done here. Filters with dynamic
                                              ##  inputs and/or outputs should create those inputs/outputs here based on
                                              ##  provided options. No more changes to this filter's inputs/outputs can be
                                              ##  done after this callback.
                                              ##
                                              ##  This callback must not assume that the filter links exist or frame
                                              ##  parameters are known.
                                              ##
                                              ##  @ref AVFilter.uninit "uninit" is guaranteed to be called even if
                                              ##  initialization fails, so this callback does not have to clean up on
                                              ##  failure.
                                              ##
                                              ##  @return 0 on success, a negative AVERROR on failure
                                              ##
    init*: proc (ctx: ptr AVFilterContext): cint ## *
                                           ##  Should be set instead of @ref AVFilter.init "init" by the filters that
                                           ##  want to pass a dictionary of AVOptions to nested contexts that are
                                           ##  allocated during init.
                                           ##
                                           ##  On return, the options dict should be freed and replaced with one that
                                           ##  contains all the options which could not be processed by this filter (or
                                           ##  with NULL if all the options were processed).
                                           ##
                                           ##  Otherwise the semantics is the same as for @ref AVFilter.init "init".
                                           ##
    init_dict*: proc (ctx: ptr AVFilterContext; options: ptr ptr AVDictionary): cint ## *
                                                                           ##  Filter uninitialization function.
                                                                           ##
                                                                           ##  Called only once right before the filter is freed. Should deallocate any
                                                                           ##  memory held by the filter, release any buffer references, etc. It does
                                                                           ##  not need to deallocate the AVFilterContext.priv memory itself.
                                                                           ##
                                                                           ##  This callback may be called even if @ref AVFilter.init "init" was not
                                                                           ##  called or failed, so it must be prepared to handle such a situation.
                                                                           ##
    uninit*: proc (ctx: ptr AVFilterContext) ## *
                                        ##  Query formats supported by the filter on its inputs and outputs.
                                        ##
                                        ##  This callback is called after the filter is initialized (so the inputs
                                        ##  and outputs are fixed), shortly before the format negotiation. This
                                        ##  callback may be called more than once.
                                        ##
                                        ##  This callback must set AVFilterLink.out_formats on every input link and
                                        ##  AVFilterLink.in_formats on every output link to a list of pixel/sample
                                        ##  formats that the filter supports on that link. For audio links, this
                                        ##  filter must also set @ref AVFilterLink.in_samplerates "in_samplerates" /
                                        ##  @ref AVFilterLink.out_samplerates "out_samplerates" and
                                        ##  @ref AVFilterLink.in_channel_layouts "in_channel_layouts" /
                                        ##  @ref AVFilterLink.out_channel_layouts "out_channel_layouts" analogously.
                                        ##
                                        ##  This callback may be NULL for filters with one input, in which case
                                        ##  libavfilter assumes that it supports all input formats and preserves
                                        ##  them on output.
                                        ##
                                        ##  @return zero on success, a negative value corresponding to an
                                        ##  AVERROR code otherwise
                                        ##
    query_formats*: proc (a1: ptr AVFilterContext): cint
    priv_size*: cint           ## /< size of private data to allocate for the filter
    flags_internal*: cint ## /< Additional flags for avfilter internal use only.
                        ## *
                        ##  Used by the filter registration system. Must not be touched by any other
                        ##  code.
                        ##
    next*: ptr AVFilter ## *
                     ##  Make the filter instance process a command.
                     ##
                     ##  @param cmd    the command to process, for handling simplicity all commands must be alphanumeric only
                     ##  @param arg    the argument for the command
                     ##  @param res    a buffer with size res_size where the filter(s) can return a response. This must not change when the command is not supported.
                     ##  @param flags  if AVFILTER_CMD_FLAG_FAST is set and the command would be
                     ##                time consuming then a filter should treat it like an unsupported command
                     ##
                     ##  @returns >=0 on success otherwise an error code.
                     ##           AVERROR(ENOSYS) on unsupported commands
                     ##
    process_command*: proc (a1: ptr AVFilterContext; cmd: cstring; arg: cstring;
                          res: cstring; res_len: cint; flags: cint): cint ## *
                                                                   ##  Filter initialization function, alternative to the init()
                                                                   ##  callback. Args contains the user-supplied parameters, opaque is
                                                                   ##  used for providing binary data.
                                                                   ##
    init_opaque*: proc (ctx: ptr AVFilterContext; opaque: pointer): cint ## *
                                                                 ##  Filter activation function.
                                                                 ##
                                                                 ##  Called when any processing is needed from the filter, instead of any
                                                                 ##  filter_frame and request_frame on pads.
                                                                 ##
                                                                 ##  The function must examine inlinks and outlinks and perform a single
                                                                 ##  step of processing. If there is nothing to do, the function must do
                                                                 ##  nothing and not return an error. If more steps are or may be
                                                                 ##  possible, it must use ff_filter_set_ready() to schedule another
                                                                 ##  activation.
                                                                 ##
    activate*: proc (ctx: ptr AVFilterContext): cint

  ## *
  ##  A link between two filters. This contains pointers to the source and
  ##  destination filters between which this link exists, and the indexes of
  ##  the pads involved. In addition, this link also contains the parameters
  ##  which have been negotiated and agreed upon between the filter, such as
  ##  image dimensions, format, etc.
  ##
  ##  Applications must not normally access the link structure directly.
  ##  Use the buffersrc and buffersink API instead.
  ##  In the future, access to the header may be reserved for filters
  ##  implementation.
  ##

  AVFilterLink* {.avfilter.} = object
    src*: ptr AVFilterContext   ## /< source filter
    srcpad*: ptr AVFilterPad    ## /< output pad on the source filter
    dst*: ptr AVFilterContext   ## /< dest filter
    dstpad*: ptr AVFilterPad    ## /< input pad on the dest filter
    `type`*: AVMediaType       ## /< filter media type
                       ##  These parameters apply only to video
    w*: cint                   ## /< agreed upon image width
    h*: cint                   ## /< agreed upon image height
    sample_aspect_ratio*: AVRational ## /< agreed upon sample aspect ratio
                                   ##  These parameters apply only to audio
    channel_layout*: uint64  ## /< channel layout of current buffer (see libavutil/channel_layout.h)
    sample_rate*: cint         ## /< samples per second
    format*: cint ## /< agreed upon media format
                ## *
                ##  Define the time base used by the PTS of the frames/samples
                ##  which will pass through this link.
                ##  During the configuration stage, each filter is supposed to
                ##  change only the output timebase, while the timebase of the
                ##  input link is assumed to be an unchangeable property.
                ##
    time_base*: AVRational ## ****************************************************************
                         ##  All fields below this line are not part of the public API. They
                         ##  may not be used outside of libavfilter and can be changed and
                         ##  removed at will.
                         ##  New public fields should be added right above.
                         ## ****************************************************************
                         ##
                         ## *
                         ##  Lists of formats and channel layouts supported by the input and output
                         ##  filters respectively. These lists are used for negotiating the format
                         ##  to actually be used, which will be loaded into the format and
                         ##  channel_layout members, above, when chosen.
                         ##
                         ##
    in_formats*: ptr AVFilterFormats
    out_formats*: ptr AVFilterFormats ## *
                                   ##  Lists of channel layouts and sample rates used for automatic
                                   ##  negotiation.
                                   ##
    in_samplerates*: ptr AVFilterFormats
    out_samplerates*: ptr AVFilterFormats
    in_channel_layouts*: ptr AVFilterChannelLayouts
    out_channel_layouts*: ptr AVFilterChannelLayouts ## *
                                                  ##  Audio only, the destination filter sets this to a non-zero value to
                                                  ##  request that buffers with the given number of samples should be sent to
                                                  ##  it. AVFilterPad.needs_fifo must also be set on the corresponding input
                                                  ##  pad.
                                                  ##  Last buffer before EOF will be padded with silence.
                                                  ##
    request_samples*: cint ## * stage of the initialization of the link properties (dimensions, etc)
    init_state: cint
                         ## *
                         ##  Graph the filter belongs to.
                         ##
    graph*: ptr AVFilterGraph ## *
                           ##  Current timestamp of the link, as defined by the most recent
                           ##  frame(s), in link time_base units.
                           ##
    current_pts*: int64 ## *
                        ##  Current timestamp of the link, as defined by the most recent
                        ##  frame(s), in AV_TIME_BASE units.
                        ##
    current_pts_us*: int64   ## *
                           ##  Index in the age array.
                           ##
    age_index*: cint ## *
                   ##  Frame rate of the stream on the link, or 1/0 if unknown or variable;
                   ##  if left to 0/0, will be automatically copied from the first input
                   ##  of the source filter if it exists.
                   ##
                   ##  Sources should set it to the best estimation of the real frame rate.
                   ##  If the source frame rate is unknown or variable, set this to 1/0.
                   ##  Filters should update it if necessary depending on their function.
                   ##  Sinks can use it to set a default output frame rate.
                   ##  It is similar to the r_frame_rate field in AVStream.
                   ##
    frame_rate*: AVRational ## *
                          ##  Buffer partially filled with samples to achieve a fixed/minimum size.
                          ##
    partial_buf*: ptr AVFrame   ## *
                           ##  Size of the partial buffer to allocate.
                           ##  Must be between min_samples and max_samples.
                           ##
    partial_buf_size*: cint ## *
                          ##  Minimum number of samples to filter at once. If filter_frame() is
                          ##  called with fewer samples, it will accumulate them in partial_buf.
                          ##  This field and the related ones must not be changed after filtering
                          ##  has started.
                          ##  If 0, all related fields are ignored.
                          ##
    min_samples*: cint ## *
                     ##  Maximum number of samples to filter at once. If filter_frame() is
                     ##  called with more samples, it will split them.
                     ##
    max_samples*: cint         ## *
                     ##  Number of channels.
                     ##
    channels*: cint            ## *
                  ##  Link processing flags.
                  ##
    flags*: cuint              ## *
                ##  Number of past frames sent through the link.
                ##
    frame_count_in*: int64
    frame_count_out*: int64  ## *
                            ##  A pointer to a FFFramePool struct.
                            ##
    frame_pool*: pointer ## *
                       ##  True if a frame is currently wanted on the output of this filter.
                       ##  Set when ff_request_frame() is called by the output,
                       ##  cleared when a frame is filtered.
                       ##
    frame_wanted_out*: cint ## *
                          ##  For hwaccel pixel formats, this should be a reference to the
                          ##  AVHWFramesContext describing the frames.
                          ##
    hw_frames_ctx*: ptr AVBufferRef
    when not defined(FF_INTERNAL_FIELDS):
      ## *
      ##  Internal structure members.
      ##  The fields below this limit are internal for libavfilter's use
      ##  and must in no way be accessed by applications.
      ##
      reserved*: array[0x0000F000, char]
    else:
      ## *
      ##  Queue of frames waiting to be filtered.
      ##
      fifo*: FFFrameQueue
      ## *
      ##  If set, the source filter can not generate a frame as is.
      ##  The goal is to avoid repeatedly calling the request_frame() method on
      ##  the same link.
      ##
      frame_blocked_in*: cint
      ## *
      ##  Link input status.
      ##  If not zero, all attempts of filter_frame will fail with the
      ##  corresponding code.
      ##
      status_in*: cint
      ## *
      ##  Timestamp of the input status change.
      ##
      status_in_pts*: int64
      ## *
      ##  Link output status.
      ##  If not zero, all attempts of request_frame will fail with the
      ##  corresponding code.
      ##
      status_out*: cint


  AVFilterContext* {.avfilter.} = object
    av_class*: ptr AVClass      ## /< needed for av_log() and filters common options
    filter*: ptr AVFilter       ## /< the AVFilter of which this is an instance
    name*: cstring             ## /< name of this filter instance
    input_pads*: ptr AVFilterPad ## /< array of input pads
    inputs*: ptr ptr AVFilterLink ## /< array of pointers to input links
    nb_inputs*: cuint          ## /< number of input pads
    output_pads*: ptr AVFilterPad ## /< array of output pads
    outputs*: ptr ptr AVFilterLink ## /< array of pointers to output links
    nb_outputs*: cuint         ## /< number of output pads
    priv*: pointer             ## /< private data for use by the filter
    graph*: ptr AVFilterGraph ## /< filtergraph this filter belongs to
                           ## *
                           ##  Type of multithreading being allowed/used. A combination of
                           ##  AVFILTER_THREAD_* flags.
                           ##
                           ##  May be set by the caller before initializing the filter to forbid some
                           ##  or all kinds of multithreading for this filter. The default is allowing
                           ##  everything.
                           ##
                           ##  When the filter is initialized, this field is combined using bit AND with
                           ##  AVFilterGraph.thread_type to get the final mask used for determining
                           ##  allowed threading types. I.e. a threading type needs to be set in both
                           ##  to be allowed.
                           ##
                           ##  After the filter is initialized, libavfilter sets this field to the
                           ##  threading type that is actually used (0 for no multithreading).
                           ##
    thread_type*: cint         ## *
                     ##  An opaque struct for libavfilter internal use.
                     ##
    internal*: ptr AVFilterInternal
    command_queue*: ptr AVFilterCommand
    enable_str*: cstring       ## /< enable expression string
    enable*: pointer           ## /< parsed expression (AVExpr*)
    var_values*: ptr cdouble    ## /< variable values for the enable expression
    is_disabled*: cint ## /< the enabled state from the last expression evaluation
                     ## *
                     ##  For filters which will create hardware frames, sets the device the
                     ##  filter should create them in.  All other filters will ignore this field:
                     ##  in particular, a filter which consumes or processes hardware frames will
                     ##  instead use the hw_frames_ctx field in AVFilterLink to carry the
                     ##  hardware context information.
                     ##
    hw_device_ctx*: ptr AVBufferRef ## *
                                 ##  Max number of threads allowed in this filter instance.
                                 ##  If <= 0, its value is ignored.
                                 ##  Overrides global number of threads set per filter graph.
                                 ##
    nb_threads*: cint ## *
                    ##  Ready status of the filter.
                    ##  A non-0 value means that the filter needs activating;
                    ##  a higher value suggests a more urgent activation.
                    ##
    ready*: cuint ## *
                ##  Sets the number of extra hardware frames which the filter will
                ##  allocate on its output links for use in following filters or by
                ##  the caller.
                ##
                ##  Some hardware filters require all frames that they will use for
                ##  output to be defined in advance before filtering starts.  For such
                ##  filters, any hardware frame pools used for output must therefore be
                ##  of fixed size.  The extra frames set here are on top of any number
                ##  that the filter needs internally in order to operate normally.
                ##
                ##  This field must be set before the graph containing this filter is
                ##  configured.
                ##
    extra_hw_frames*: cint


  ## *
  ##  A function pointer passed to the @ref AVFilterGraph.execute callback to be
  ##  executed multiple times, possibly in parallel.
  ##
  ##  @param ctx the filter context the job belongs to
  ##  @param arg an opaque parameter passed through from @ref
  ##             AVFilterGraph.execute
  ##  @param jobnr the index of the job being executed
  ##  @param nb_jobs the total number of jobs
  ##
  ##  @return 0 on success, a negative AVERROR on error
  ##

  avfilter_action_func* = proc (ctx: ptr AVFilterContext; arg: pointer; jobnr: cint;
                             nb_jobs: cint): cint

  ## *
  ##  A function executing multiple jobs, possibly in parallel.
  ##
  ##  @param ctx the filter context to which the jobs belong
  ##  @param func the function to be called multiple times
  ##  @param arg the argument to be passed to func
  ##  @param ret a nb_jobs-sized array to be filled with return values from each
  ##             invocation of func
  ##  @param nb_jobs the number of jobs to execute
  ##
  ##  @return 0 on success, a negative AVERROR on error
  ##

  avfilter_execute_func* = proc (ctx: ptr AVFilterContext;
                              `func`: ptr avfilter_action_func; arg: pointer;
                              ret: ptr cint; nb_jobs: cint): cint
  AVFilterGraph* {.avfilter.} = object
    av_class*: ptr AVClass
    filters*: ptr ptr AVFilterContext
    nb_filters*: cuint
    scale_sws_opts*: cstring   ## /< sws options to use for the auto-inserted scale filters
    when FF_API_LAVR_OPTS:
      ## attribute_deprecated char *resample_lavr_opts;   ///< libavresample options to use for the auto-inserted resample filters
      resample_lavr_opts*: cstring
      ## /< libavresample options to use for the auto-inserted resample filters
    thread_type*: cint ## *
                     ##  Type of multithreading allowed for filters in this graph. A combination
                     ##  of AVFILTER_THREAD_* flags.
                     ##
                     ##  May be set by the caller at any point, the setting will apply to all
                     ##  filters initialized after that. The default is allowing everything.
                     ##
                     ##  When a filter in this graph is initialized, this field is combined using
                     ##  bit AND with AVFilterContext.thread_type to get the final mask used for
                     ##  determining allowed threading types. I.e. a threading type needs to be
                     ##  set in both to be allowed.
                     ##
                     ## *
                     ##  Maximum number of threads used by filters in this graph. May be set by
                     ##  the caller before adding any filters to the filtergraph. Zero (the
                     ##  default) means that the number of threads is determined automatically.
                     ##
    nb_threads*: cint          ## *
                    ##  Opaque object for libavfilter internal use.
                    ##
    internal*: ptr AVFilterGraphInternal ## *
                                      ##  Opaque user data. May be set by the caller to an arbitrary value, e.g. to
                                      ##  be used from callbacks like @ref AVFilterGraph.execute.
                                      ##  Libavfilter will not touch this field in any way.
                                      ##
    opaque*: pointer ## *
                   ##  This callback may be set by the caller immediately after allocating the
                   ##  graph and before adding any filters to it, to provide a custom
                   ##  multithreading implementation.
                   ##
                   ##  If set, filters with slice threading capability will call this callback
                   ##  to execute multiple jobs in parallel.
                   ##
                   ##  If this field is left unset, libavfilter will use its internal
                   ##  implementation, which may or may not be multithreaded depending on the
                   ##  platform and build options.
                   ##
    execute*: ptr avfilter_execute_func
    aresample_swr_opts*: cstring ## /< swr options to use for the auto-inserted aresample filters, Access ONLY through AVOptions
                               ## *
                               ##  Private fields
                               ##
                               ##  The following fields are for internal use only.
                               ##  Their type, offset, number and semantic can change without notice.
                               ##
    sink_links*: ptr ptr AVFilterLink
    sink_links_count*: cint
    disable_auto_convert*: cuint

  ## *
  ##  A linked-list of the inputs/outputs of the filter chain.
  ##
  ##  This is mainly useful for avfilter_graph_parse() / avfilter_graph_parse2(),
  ##  where it is used to communicate open (unlinked) inputs and outputs from and
  ##  to the caller.
  ##  This struct specifies, per each not connected pad contained in the graph, the
  ##  filter context and the pad index required for establishing a link.
  ##

  AVFilterInOut* {.avfilter.} = object
    name*: cstring             ## * unique name for this input/output in the list
    ## * filter context associated to this input/output
    filter_ctx*: ptr AVFilterContext ## * index of the filt_ctx pad to use for linking
    pad_idx*: cint             ## * next input/input in the list, NULL if this is the last
    next*: ptr AVFilterInOut


when defined(windows):
  {.push importc, dynlib: "avfilter(|-5|-6|-7|-8).dll".}
elif defined(macosx):
  {.push importc, dynlib: "avfilter(|.5|.6|.7|.8).dylib".}
else:
  {.push importc, dynlib: "avfilter.so(|.5|.6|.7|.8)".}

## *
##  Return the LIBAVFILTER_VERSION_INT constant.
##

proc avfilter_version*(): cuint
## *
##  Return the libavfilter build-time configuration.
##

proc avfilter_configuration*(): cstring
## *
##  Return the libavfilter license.
##

proc avfilter_license*(): cstring

## *
##  Get the number of elements in a NULL-terminated array of AVFilterPads (e.g.
##  AVFilter.inputs/outputs).
##

proc avfilter_pad_count*(pads: ptr AVFilterPad): cint
## *
##  Get the name of an AVFilterPad.
##
##  @param pads an array of AVFilterPads
##  @param pad_idx index of the pad in the array; it is the caller's
##                 responsibility to ensure the index is valid
##
##  @return name of the pad_idx'th pad in pads
##

proc avfilter_pad_get_name*(pads: ptr AVFilterPad; pad_idx: cint): cstring
## *
##  Get the type of an AVFilterPad.
##
##  @param pads an array of AVFilterPads
##  @param pad_idx index of the pad in the array; it is the caller's
##                 responsibility to ensure the index is valid
##
##  @return type of the pad_idx'th pad in pads
##

proc avfilter_pad_get_type*(pads: ptr AVFilterPad; pad_idx: cint): AVMediaType
## *
##  The number of the filter inputs is not determined just by AVFilter.inputs.
##  The filter might add additional inputs during initialization depending on the
##  options supplied to it.
##

const
  AVFILTER_FLAG_DYNAMIC_INPUTS* = (1 shl 0)

## *
##  The number of the filter outputs is not determined just by AVFilter.outputs.
##  The filter might add additional outputs during initialization depending on
##  the options supplied to it.
##

const
  AVFILTER_FLAG_DYNAMIC_OUTPUTS* = (1 shl 1)

## *
##  The filter supports multithreading by splitting frames into multiple parts
##  and processing them concurrently.
##

const
  AVFILTER_FLAG_SLICE_THREADS* = (1 shl 2)

## *
##  Some filters support a generic "enable" expression option that can be used
##  to enable or disable a filter in the timeline. Filters supporting this
##  option have this flag set. When the enable expression is false, the default
##  no-op filter_frame() function is called in place of the filter_frame()
##  callback defined on each input pad, thus the frame is passed unchanged to
##  the next filters.
##

const
  AVFILTER_FLAG_SUPPORT_TIMELINE_GENERIC* = (1 shl 16)

## *
##  Same as AVFILTER_FLAG_SUPPORT_TIMELINE_GENERIC, except that the filter will
##  have its filter_frame() callback(s) called as usual even when the enable
##  expression is false. The filter will disable filtering within the
##  filter_frame() callback(s) itself, for example executing code depending on
##  the AVFilterContext->is_disabled value.
##

const
  AVFILTER_FLAG_SUPPORT_TIMELINE_INTERNAL* = (1 shl 17)

## *
##  Handy mask to test whether the filter supports or no the timeline feature
##  (internally or generically).
##

const
  AVFILTER_FLAG_SUPPORT_TIMELINE* = (AVFILTER_FLAG_SUPPORT_TIMELINE_GENERIC or
      AVFILTER_FLAG_SUPPORT_TIMELINE_INTERNAL)

## *
##  Filter definition. This defines the pads a filter contains, and all the
##  callback functions used to interact with the filter.
##


## *
##  Link two filters together.
##
##  @param src    the source filter
##  @param srcpad index of the output pad on the source filter
##  @param dst    the destination filter
##  @param dstpad index of the input pad on the destination filter
##  @return       zero on success
##

proc avfilter_link*(src: ptr AVFilterContext; srcpad: cuint; dst: ptr AVFilterContext;
                   dstpad: cuint): cint
## *
##  Free the link in *link, and set its pointer to NULL.
##

proc avfilter_link_free*(link: ptr ptr AVFilterLink)
when FF_API_FILTER_GET_SET:
  ## *
  ##  Get the number of channels of a link.
  ##  @deprecated Use av_buffersink_get_channels()
  ##
  ## //attribute_deprecated
  proc avfilter_link_get_channels*(link: ptr AVFilterLink): cint
## *
##  Set the closed field of a link.
##  @deprecated applications are not supposed to mess with links, they should
##  close the sinks.
##
## //attribute_deprecated

proc avfilter_link_set_closed*(link: ptr AVFilterLink; closed: cint)
## *
##  Negotiate the media format, dimensions, etc of all inputs to a filter.
##
##  @param filter the filter to negotiate the properties for its inputs
##  @return       zero on successful negotiation
##

proc avfilter_config_links*(filter: ptr AVFilterContext): cint
const
  AVFILTER_CMD_FLAG_ONE* = 1
  AVFILTER_CMD_FLAG_FAST* = 2

## *
##  Make the filter instance process a command.
##  It is recommended to use avfilter_graph_send_command().
##

proc avfilter_process_command*(filter: ptr AVFilterContext; cmd: cstring;
                              arg: cstring; res: cstring; res_len: cint; flags: cint): cint
## *
##  Iterate over all registered filters.
##
##  @param opaque a pointer where libavfilter will store the iteration state. Must
##                point to NULL to start the iteration.
##
##  @return the next registered filter or NULL when the iteration is
##          finished
##

proc av_filter_iterate*(opaque: ptr pointer): ptr AVFilter
when FF_API_NEXT:
  ## * Initialize the filter system. Register all builtin filters.
  ## attribute_deprecated
  proc avfilter_register_all*()
  ## *
  ##  Register a filter. This is only needed if you plan to use
  ##  avfilter_get_by_name later to lookup the AVFilter structure by name. A
  ##  filter can still by instantiated with avfilter_graph_alloc_filter even if it
  ##  is not registered.
  ##
  ##  @param filter the filter to register
  ##  @return 0 if the registration was successful, a negative value
  ##  otherwise
  ##
  ## attribute_deprecated
  proc avfilter_register*(filter: ptr AVFilter): cint
  ## *
  ##  Iterate over all registered filters.
  ##  @return If prev is non-NULL, next registered filter after prev or NULL if
  ##  prev is the last filter. If prev is NULL, return the first registered filter.
  ##
  ## attribute_deprecated
  proc avfilter_next*(prev: ptr AVFilter): ptr AVFilter
## *
##  Get a filter definition matching the given name.
##
##  @param name the filter name to find
##  @return     the filter definition, if any matching one is registered.
##              NULL if none found.
##

proc avfilter_get_by_name*(name: cstring): ptr AVFilter
## *
##  Initialize a filter with the supplied parameters.
##
##  @param ctx  uninitialized filter context to initialize
##  @param args Options to initialize the filter with. This must be a
##              ':'-separated list of options in the 'key=value' form.
##              May be NULL if the options have been set directly using the
##              AVOptions API or there are no options that need to be set.
##  @return 0 on success, a negative AVERROR on failure
##

proc avfilter_init_str*(ctx: ptr AVFilterContext; args: cstring): cint
## *
##  Initialize a filter with the supplied dictionary of options.
##
##  @param ctx     uninitialized filter context to initialize
##  @param options An AVDictionary filled with options for this filter. On
##                 return this parameter will be destroyed and replaced with
##                 a dict containing options that were not found. This dictionary
##                 must be freed by the caller.
##                 May be NULL, then this function is equivalent to
##                 avfilter_init_str() with the second parameter set to NULL.
##  @return 0 on success, a negative AVERROR on failure
##
##  @note This function and avfilter_init_str() do essentially the same thing,
##  the difference is in manner in which the options are passed. It is up to the
##  calling code to choose whichever is more preferable. The two functions also
##  behave differently when some of the provided options are not declared as
##  supported by the filter. In such a case, avfilter_init_str() will fail, but
##  this function will leave those extra options in the options AVDictionary and
##  continue as usual.
##

proc avfilter_init_dict*(ctx: ptr AVFilterContext; options: ptr ptr AVDictionary): cint
## *
##  Free a filter context. This will also remove the filter from its
##  filtergraph's list of filters.
##
##  @param filter the filter to free
##

proc avfilter_free*(filter: ptr AVFilterContext)
## *
##  Insert a filter in the middle of an existing link.
##
##  @param link the link into which the filter should be inserted
##  @param filt the filter to be inserted
##  @param filt_srcpad_idx the input pad on the filter to connect
##  @param filt_dstpad_idx the output pad on the filter to connect
##  @return     zero on success
##

proc avfilter_insert_filter*(link: ptr AVFilterLink; filt: ptr AVFilterContext;
                            filt_srcpad_idx: cuint; filt_dstpad_idx: cuint): cint
## *
##  @return AVClass for AVFilterContext.
##
##  @see av_opt_find().
##

proc avfilter_get_class*(): ptr AVClass


## *
##  Allocate a filter graph.
##
##  @return the allocated filter graph on success or NULL.
##

proc avfilter_graph_alloc*(): ptr AVFilterGraph
## *
##  Create a new filter instance in a filter graph.
##
##  @param graph graph in which the new filter will be used
##  @param filter the filter to create an instance of
##  @param name Name to give to the new instance (will be copied to
##              AVFilterContext.name). This may be used by the caller to identify
##              different filters, libavfilter itself assigns no semantics to
##              this parameter. May be NULL.
##
##  @return the context of the newly created filter instance (note that it is
##          also retrievable directly through AVFilterGraph.filters or with
##          avfilter_graph_get_filter()) on success or NULL on failure.
##

proc avfilter_graph_alloc_filter*(graph: ptr AVFilterGraph; filter: ptr AVFilter;
                                 name: cstring): ptr AVFilterContext
## *
##  Get a filter instance identified by instance name from graph.
##
##  @param graph filter graph to search through.
##  @param name filter instance name (should be unique in the graph).
##  @return the pointer to the found filter instance or NULL if it
##  cannot be found.
##

proc avfilter_graph_get_filter*(graph: ptr AVFilterGraph; name: cstring): ptr AVFilterContext
## *
##  Create and add a filter instance into an existing graph.
##  The filter instance is created from the filter filt and inited
##  with the parameters args and opaque.
##
##  In case of success put in *filt_ctx the pointer to the created
##  filter instance, otherwise set *filt_ctx to NULL.
##
##  @param name the instance name to give to the created filter instance
##  @param graph_ctx the filter graph
##  @return a negative AVERROR error code in case of failure, a non
##  negative value otherwise
##

proc avfilter_graph_create_filter*(filt_ctx: ptr ptr AVFilterContext;
                                  filt: ptr AVFilter; name: cstring; args: cstring;
                                  opaque: pointer; graph_ctx: ptr AVFilterGraph): cint
## *
##  Enable or disable automatic format conversion inside the graph.
##
##  Note that format conversion can still happen inside explicitly inserted
##  scale and aresample filters.
##
##  @param flags  any of the AVFILTER_AUTO_CONVERT_* constants
##

proc avfilter_graph_set_auto_convert*(graph: ptr AVFilterGraph; flags: cuint)
const
  AVFILTER_AUTO_CONVERT_ALL* = 0 ## *< all automatic conversions enabled
  AVFILTER_AUTO_CONVERT_NONE* = -1 ## *< all automatic conversions disabled

## *
##  Check validity and configure all the links and formats in the graph.
##
##  @param graphctx the filter graph
##  @param log_ctx context used for logging
##  @return >= 0 in case of success, a negative AVERROR code otherwise
##

proc avfilter_graph_config*(graphctx: ptr AVFilterGraph; log_ctx: pointer): cint
## *
##  Free a graph, destroy its links, and set *graph to NULL.
##  If *graph is NULL, do nothing.
##

proc avfilter_graph_free*(graph: ptr ptr AVFilterGraph)

## *
##  Allocate a single AVFilterInOut entry.
##  Must be freed with avfilter_inout_free().
##  @return allocated AVFilterInOut on success, NULL on failure.
##

proc avfilter_inout_alloc*(): ptr AVFilterInOut
## *
##  Free the supplied list of AVFilterInOut and set *inout to NULL.
##  If *inout is NULL, do nothing.
##

proc avfilter_inout_free*(inout: ptr ptr AVFilterInOut)
## *
##  Add a graph described by a string to a graph.
##
##  @note The caller must provide the lists of inputs and outputs,
##  which therefore must be known before calling the function.
##
##  @note The inputs parameter describes inputs of the already existing
##  part of the graph; i.e. from the point of view of the newly created
##  part, they are outputs. Similarly the outputs parameter describes
##  outputs of the already existing filters, which are provided as
##  inputs to the parsed filters.
##
##  @param graph   the filter graph where to link the parsed graph context
##  @param filters string to be parsed
##  @param inputs  linked list to the inputs of the graph
##  @param outputs linked list to the outputs of the graph
##  @return zero on success, a negative AVERROR code on error
##

proc avfilter_graph_parse*(graph: ptr AVFilterGraph; filters: cstring;
                          inputs: ptr AVFilterInOut; outputs: ptr AVFilterInOut;
                          log_ctx: pointer): cint
## *
##  Add a graph described by a string to a graph.
##
##  In the graph filters description, if the input label of the first
##  filter is not specified, "in" is assumed; if the output label of
##  the last filter is not specified, "out" is assumed.
##
##  @param graph   the filter graph where to link the parsed graph context
##  @param filters string to be parsed
##  @param inputs  pointer to a linked list to the inputs of the graph, may be NULL.
##                 If non-NULL, *inputs is updated to contain the list of open inputs
##                 after the parsing, should be freed with avfilter_inout_free().
##  @param outputs pointer to a linked list to the outputs of the graph, may be NULL.
##                 If non-NULL, *outputs is updated to contain the list of open outputs
##                 after the parsing, should be freed with avfilter_inout_free().
##  @return non negative on success, a negative AVERROR code on error
##

proc avfilter_graph_parse_ptr*(graph: ptr AVFilterGraph; filters: cstring;
                              inputs: ptr ptr AVFilterInOut;
                              outputs: ptr ptr AVFilterInOut; log_ctx: pointer): cint
## *
##  Add a graph described by a string to a graph.
##
##  @param[in]  graph   the filter graph where to link the parsed graph context
##  @param[in]  filters string to be parsed
##  @param[out] inputs  a linked list of all free (unlinked) inputs of the
##                      parsed graph will be returned here. It is to be freed
##                      by the caller using avfilter_inout_free().
##  @param[out] outputs a linked list of all free (unlinked) outputs of the
##                      parsed graph will be returned here. It is to be freed by the
##                      caller using avfilter_inout_free().
##  @return zero on success, a negative AVERROR code on error
##
##  @note This function returns the inputs and outputs that are left
##  unlinked after parsing the graph and the caller then deals with
##  them.
##  @note This function makes no reference whatsoever to already
##  existing parts of the graph and the inputs parameter will on return
##  contain inputs of the newly parsed part of the graph.  Analogously
##  the outputs parameter will contain outputs of the newly created
##  filters.
##

proc avfilter_graph_parse2*(graph: ptr AVFilterGraph; filters: cstring;
                           inputs: ptr ptr AVFilterInOut;
                           outputs: ptr ptr AVFilterInOut): cint
## *
##  Send a command to one or more filter instances.
##
##  @param graph  the filter graph
##  @param target the filter(s) to which the command should be sent
##                "all" sends to all filters
##                otherwise it can be a filter or filter instance name
##                which will send the command to all matching filters.
##  @param cmd    the command to send, for handling simplicity all commands must be alphanumeric only
##  @param arg    the argument for the command
##  @param res    a buffer with size res_size where the filter(s) can return a response.
##
##  @returns >=0 on success otherwise an error code.
##               AVERROR(ENOSYS) on unsupported commands
##

proc avfilter_graph_send_command*(graph: ptr AVFilterGraph; target: cstring;
                                 cmd: cstring; arg: cstring; res: cstring;
                                 res_len: cint; flags: cint): cint
## *
##  Queue a command for one or more filter instances.
##
##  @param graph  the filter graph
##  @param target the filter(s) to which the command should be sent
##                "all" sends to all filters
##                otherwise it can be a filter or filter instance name
##                which will send the command to all matching filters.
##  @param cmd    the command to sent, for handling simplicity all commands must be alphanumeric only
##  @param arg    the argument for the command
##  @param ts     time at which the command should be sent to the filter
##
##  @note As this executes commands after this function returns, no return code
##        from the filter is provided, also AVFILTER_CMD_FLAG_ONE is not supported.
##

proc avfilter_graph_queue_command*(graph: ptr AVFilterGraph; target: cstring;
                                  cmd: cstring; arg: cstring; flags: cint; ts: cdouble): cint
## *
##  Dump a graph into a human-readable string representation.
##
##  @param graph    the graph to dump
##  @param options  formatting options; currently ignored
##  @return  a string, or NULL in case of memory allocation failure;
##           the string must be freed using av_free
##

proc avfilter_graph_dump*(graph: ptr AVFilterGraph; options: cstring): cstring
## *
##  Request a frame on the oldest sink link.
##
##  If the request returns AVERROR_EOF, try the next.
##
##  Note that this function is not meant to be the sole scheduling mechanism
##  of a filtergraph, only a convenience function to help drain a filtergraph
##  in a balanced way under normal circumstances.
##
##  Also note that AVERROR_EOF does not mean that frames did not arrive on
##  some of the sinks during the process.
##  When there are multiple sink links, in case the requested link
##  returns an EOF, this may cause a filter to flush pending frames
##  which are sent to another sink link, although unrequested.
##
##  @return  the return value of ff_request_frame(),
##           or AVERROR_EOF if all links returned AVERROR_EOF
##

proc avfilter_graph_request_oldest*(graph: ptr AVFilterGraph): cint
## *
##  @}
##
