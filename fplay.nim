# the tutorial repo is from
# https://github.com/leixiaohua1020/simplest_ffmpeg_player

import
  utiltypes,
  libavcodec/avcodec,
  libavformat/avformat,
  libavutil/frame

import sdl2

import os, strformat, times
import sugar

proc render(ctx: ptr AVCodecContext, pkt: ptr AVPacket, frame: ptr AVFrame,
  rect: ptr Rect, texture: TexturePtr, renderer: RendererPtr,
  renderfps: float): uint32

proc vidParamAndCodec(ctx: ptr AVFormatContext, param: var ptr AVCodecParameters,
  codec: var ptr AVCodec): int =
  var streams = cast[ptr UncheckedArray[ptr AVStream]](ctx[].streams)
  for i in 0 .. ctx[].nb_streams:
    let localparam = streams[i][].codecpar
    if localparam[].codec_type == AVMEDIA_TYPE_VIDEO:
      result = int i
      param = localparam
      codec = avcodec_find_decoder(localparam[].codec_id)
      break

proc main =
  if paramCount() < 1:
    quit &"usage: {getAppFilename().extractFilename()} <filename>"

  let filename = paramStr 1
  var
    pFormatCtx: ptr AVFormatContext
    vidIdx = -1
    pCodecCtx: ptr AVCodecContext
    pCodecpar: ptr AVCodecParameters
    pCodec: ptr AVCodec
    pFrame: ptr AVFrame
    packet: ptr AVPacket

  var # sdl part
    swidth = 0
    sheight = 0
    screen: WindowPtr
    renderer: RendererPtr
    texture: TexturePtr
    rect: Rect

  sdl2.init(INIT_EVERYTHING)
  av_register_all()
  pFormatCtx = avformat_alloc_context()
  if avformat_open_input(addr pFormatCtx, filename, nil, nil) < 0:
    quit &"Couldn't open input {filename}."
  if avformat_find_stream_info(pFormatCtx, nil) < 0:
    quit "Couldn't find stream information"

  vidIdx = pFormatCtx.vidParamAndCodec(pCodecpar, pCodec)
  if vidIdx == -1:
    quit "Couldn't find video stream."
  echo &"resolution {pCodecpar[].width} x {pCodecpar[].height}."
  if pCodec.isNil:
    quit "Couldn't find codec for video."
  pCodecCtx = avcodec_alloc_context3(pCodec)
  if avcodec_parameters_to_context(pCodecCtx, pCodecpar) < 0:
    quit "avcodec_parameters_to_context fail!"
  if avcodec_open2(pCodecCtx, pCodec, nil) < 0:
    quit "Couldn't open codec."
  dump pCodecCtx[].pix_fmt
  dump pCodecCtx[].codec_id
  pFrame = av_frame_alloc()
  dump pCodecpar[].width
  dump pCodecpar[].height
  #[
  var outbuf = cast[ptr byte](av_malloc(
    av_image_get_buffer_size(AV_PIX_FMT_YUV420P,
    pCodecpar[].width,
    pcodecpar[].height,
    1)))
    # disabled because of mismatched destination data type
  if av_image_fill_arrays(pFrameYUV[].data, pFrameYUV[].linesize, outbuf,
    AV_PIX_FMT_YUV420P, pCodecCtx[].width, pCodecCtx[].height, 1) < 0:
      quit "Cannot fill the image arrays"

  ]#
  packet = av_packet_alloc()
  swidth = pCodecpar[].width
  sheight = pCodecpar[].height
  dump swidth
  dump sheight
  screen = createWindow("FPlay", SDL_WINDOWPOS_UNDEFINED,
    SDL_WINDOWPOS_UNDEFINED, cint swidth, cint sheight,
    SDL_WINDOW_OPENGL)
  if screen.isNil:
    quit &"Couldn't create window: {getError()}"
  #[
  renderer = createRenderer(screen, -1,
    Renderer_Accelerated or Renderer_PresentVsync or
    Renderer_TargetTexture)
  ]#
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
  discard av_packet_make_writable(packet)
  let render24fps = 0.041667 # for 24fps
  var framenum = 0'u32
  var evt = sdl2.defaultEvent
  block pollevent:
    while pollEvent(evt):
      if evt.kind == QuitEvent:
        break
      while av_read_frame(pFormatCtx, packet) >= 0:
        if evt.kind == QuitEvent:
          break pollevent;
        if packet[].stream_index.int == vidIdx:
          framenum = pCodecCtx.render(packet, pFrame, addr rect, texture, renderer, render24fps)
            #[
          if framenum mod 500 == 0:
            discard screen.updateSurface
            echo &"frame {framenum} renderer/texture to avoid display congestion"
            renderer = createRenderer(screen, -1, 0)
            texture = createTexture(renderer, uint32 SDL_PIXELFORMAT_IYUV,
              SDL_TEXTUREACCESS_STREAMING,
              cint swidth, cint sheight)
              ]#
          if evt.kind == QuitEvent:
            break pollevent;
  
  avformat_close_input(addr pFormatCtx)
  avformat_free_context(pFormatCtx)
  av_packet_free(addr packet)
  av_frame_free(addr pFrame)
  avcodec_free_context(addr pCodecCtx)

  destroy texture
  destroy renderer
  destroy screen
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
  

main()