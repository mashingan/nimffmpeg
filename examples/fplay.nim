# the tutorial repo is from
# https://github.com/leixiaohua1020/simplest_ffmpeg_player

import
  utiltypes,
  libavcodec/avcodec,
  libavformat/avformat,
  libavutil/[frame, samplefmt]

import sdl2, sdl2/audio

import os, strformat, times
import sugar

type
  CodecInfo = (ptr AVcodecParameters, ptr AVCodec, int)
  #[
  AudioStream = object
    stream: pointer
    size: uint32
    currpos: uint32
    hwBufSize: uint32
    packet: ptr AVPacket
    frame: ptr AVFrame

# TODO: finish the callback
proc audiocallback(data: pointer, stream: ptr byte, length: cint) {.used.} =
  var userdata = cast[ptr AudioStream](data)
  if userdata[].currpos >= userdata[].size:
    discard
  copyMem(stream, userdata[].stream, userdata[].size)
  ]#

proc render(ctx: ptr AVCodecContext, pkt: ptr AVPacket, frame: ptr AVFrame,
  rect: ptr Rect, texture: TexturePtr, renderer: RendererPtr,
  renderfps: float): uint32

proc sample(ctx: ptr AVCodecContext, pkt: ptr AVPacket, frame: ptr AVFrame;
  dev: AudioDeviceID): uint32

proc paramAndCodec(ctx: ptr AVFormatContext, vidcodec, audcodec: var CodecInfo):
  (int, float) =
  var
    streams = cast[ptr UncheckedArray[ptr AVStream]](ctx[].streams)
    foundVideo = false
    foundAudio = false
  for i in 0 .. ctx[].nb_streams:
    let localparam = streams[i][].codecpar
    if localparam[].codec_type == AVMEDIA_TYPE_VIDEO:
      let rational = streams[i].avg_frame_rate
      vidcodec[2] = int i
      result[0] = int i
      result[1] = 1.0 / (rational.num.float / rational.den.float)
      vidcodec[0] = localparam
      dump localparam[].codec_id
      vidcodec[1] = avcodec_find_decoder(localparam[].codec_id)
      foundVideo = true
    elif localparam[].codec_type == AVMEDIA_TYPE_AUDIO:
      audcodec[2] = int i
      audcodec[0] = localparam
      dump localparam[].codec_id
      audcodec[1] = avcodec_find_decoder(localparam[].codec_id)
      foundAudio = true
    if foundAudio and foundVideo:
      break

proc allocContext(vidctx, audctx: var ptr AVCodecContext,
  vidinfo, audinfo: CodecInfo) =
  vidctx = avcodec_alloc_context3(vidinfo[1])
  audctx = avcodec_alloc_context3(audinfo[1])
  if avcodec_parameters_to_context(vidctx, vidinfo[0]) < 0:
    quit "avcodec_parameters_to_context fail!"
  if avcodec_open2(vidctx, vidinfo[1], nil) < 0:
    quit "Couldn't open codec."
  if avcodec_parameters_to_context(audctx, audinfo[0]) < 0:
    quit "avcodec_parameters_to_context fail!"
  if avcodec_open2(audctx, audinfo[1], nil) < 0:
    quit "Couldn't open codec."

proc prepareAudioSpec(spec: var AudioSpec) =
  zeroMem(addr spec, sizeof AudioSpec)
  spec.freq = 44100
  spec.format = AUDIO_F32
  spec.channels = 2
  spec.samples = 4096

proc main =
  if paramCount() < 1:
    quit &"usage: {getAppFilename().extractFilename()} <filename>"

  let filename = paramStr 1
  var
    pFormatCtx: ptr AVFormatContext
    vidIdx = -1
    fpsrendering = 0'f
    pCodecCtx, audioCtx: ptr AVCodecContext
    pCodecpar, audiopar: ptr AVCodecParameters
    pCodec, audioCodec: ptr AVCodec
    pFrame, aframe: ptr AVFrame
    packet, audpack: ptr AVPacket
    vidinfo = (pCodecpar, pCodec, -1)
    audinfo = (audiopar, audioCodec, -1)
    parser: ptr AVCodecParserContext

  var # sdl part
    swidth = 0
    sheight = 0
    screen: WindowPtr
    renderer: RendererPtr
    texture: TexturePtr
    rect: Rect
    auddev: AudioDeviceID
    want, have: AudioSpec

  sdl2.init(INIT_EVERYTHING)
  av_register_all()
  pFormatCtx = avformat_alloc_context()
  if avformat_open_input(addr pFormatCtx, filename, nil, nil) < 0:
    quit &"Couldn't open input {filename}."
  if avformat_find_stream_info(pFormatCtx, nil) < 0:
    quit "Couldn't find stream information"

  (vidIdx, fpsrendering) = pFormatCtx.paramAndCodec(vidinfo, audinfo)
  if vidIdx == -1:
    quit "Couldn't find video stream."
  echo &"resolution {vidinfo[0][].width} x {vidinfo[0][].height}."
  dump fpsrendering
  if vidinfo[1].isNil:
    quit "Couldn't find codec for video."
  allocContext(pCodecCtx, audioCtx, vidinfo, audinfo)
  parser = av_parser_init(cint audinfo[1].id)

  dump pCodecCtx[].pix_fmt
  dump pCodecCtx[].codec_id
  dump vidinfo[0][].width
  dump vidinfo[0][].height

  pFrame = av_frame_alloc()
  aframe = av_frame_alloc()

  packet = av_packet_alloc()
  audpack = av_packet_alloc()
  swidth = vidinfo[0][].width
  sheight = vidinfo[0][].height
  screen = createWindow("FPlay", SDL_WINDOWPOS_UNDEFINED,
    SDL_WINDOWPOS_UNDEFINED, cint swidth, cint sheight,
    SDL_WINDOW_OPENGL)
  if screen.isNil:
    quit &"Couldn't create window: {getError()}"

  renderer = createRenderer(screen, -1, Renderer_Accelerated)
  texture = createTexture(renderer, uint32 SDL_PIXELFORMAT_IYUV,
    SDL_TEXTUREACCESS_STREAMING or SDL_TEXTUREACCESS_TARGET,
    cint swidth, cint sheight)

  rect.x = 0
  rect.y = 0
  rect.w = cint swidth
  rect.h = cint sheight
  dump rect
  dump filename

  want.prepareAudioSpec
  zeroMem(addr have, sizeof AudioSpec)
  want.samples = uint16 audioCtx[].sample_rate
  want.channels = uint8 audioCtx[].channels
  auddev = openAudioDevice(getAudioDeviceName(0, 0), 0, addr want, addr have, 0)
  if auddev == 0:
    quit &"Cannot open audio device: {getError()}."
  auddev.pauseAudioDevice 0
  var framenum = 0'u32
  var evt = sdl2.defaultEvent
  block pollevent:
    while av_read_frame(pFormatCtx, packet) >= 0:
      while pollEvent(evt):
        if evt.kind == QuitEvent:
          break pollevent
      if packet[].stream_index.int == vidIdx:
        framenum = pCodecCtx.render(packet, pFrame,
          addr rect, texture, renderer, fpsrendering)
      elif packet[].stream_index.int == audinfo[2]:
        framenum = audioCtx.sample(packet, aframe, auddev)

      av_packet_unref(packet)
  
  av_parser_close parser
  av_packet_free(addr packet)
  av_packet_free(addr audpack)
  avformat_close_input(addr pFormatCtx)
  avformat_free_context(pFormatCtx)
  av_packet_free(addr packet)
  av_frame_free(addr pFrame)
  av_frame_free(addr aframe)
  avcodec_free_context(addr pCodecCtx)
  avcodec_free_context(addr audioCtx)

  destroy texture
  destroy renderer
  destroy screen
  closeAudioDevice auddev
  sdl2.quit()

proc render(ctx: ptr AVCodecContext, pkt: ptr AVPacket, frame: ptr AVFrame,
  rect: ptr Rect, texture: TexturePtr, renderer: RendererPtr,
  renderfps: float): uint32 =
  let start = cpuTime()
  if avcodec_send_packet(ctx, pkt) < 0: return
  if avcodec_receive_frame(ctx, frame) < 0: return
  result = ctx[].frame_number.uint32

  if ctx[].frame_number mod 1000 == 0:
    echo(("Frame $# (size=$#) pts $# dts $# key_frame $#" &
      " [coded_picture_number $#, display_picture_number $#]") % [
        $ctx[].frame_number,
        $frame[].pkt_size,
        $frame[].pts,
        $frame[].pkt_dts,
        $frame[].key_frame,
        $frame[].coded_picture_number,
        $frame[].display_picture_number])
  texture.updateYUVTexture(rect,
    frame[].data[0], frame[].linesize[0],
    frame[].data[1], frame[].linesize[1],
    frame[].data[2], frame[].linesize[2])

  renderer.clear
  renderer.copy(texture, nil, rect)
  renderer.present
  let endupdate = cpuTime()
  let diff = endupdate - start
  echo &"frame rendering: {(diff*1000):4.3f} ms."
  dump diff
  if diff < renderfps:
    let delaytime = (renderfps - diff) * 1000
    dump delaytime
    delay delaytime.uint32
  
proc sample(ctx: ptr AVCodecContext, pkt: ptr AVPacket, frame: ptr AVFrame;
  dev: AudioDeviceID): uint32 =
  if avcodec_send_packet(ctx, pkt) < 0: return
  if avcodec_receive_frame(ctx, frame) < 0: return
  dump dev.getQueuedAudioSize
  result = ctx[].frame_number.uint32
  let isPlanar = av_sample_fmt_is_planar(frame[].format.AVSampleFormat) == 1
  var data = cast[ptr UncheckedArray[byte]](frame[].data[0])
  var size2: cint
  var _ = av_samples_get_buffer_size(addr size2, ctx[].channels,
    frame[].nb_samples, frame[].format.AVSampleFormat, 0)
  for ch in 0 ..< ctx[].channels:
    if not isPlanar:
      if dev.queueAudio(frame[].data[ch], uint32 frame[].linesize[ch]) < 0:
        echo &"cannot queue audio: {getError()}"
        return
    else:
      if dev.queueAudio(addr(data[ch * size2]), uint32 size2) < 0:
        echo &"cannot queue audio: {getError()}"
        return

main()