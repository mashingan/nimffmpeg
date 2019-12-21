import libavcodec/avcodec
import libavformat/avformat
import libavutil/[error, frame, pixfmt]
import utiltypes
import streams, strformat, os, strutils

proc fetchFrame(fmt: ptr AVFormatContext, frame: ptr AVFrame,
                ctx: ptr AVCodecContext, pkt: ptr AVPacket): bool =
  template check: untyped =
    if retval < 0: return false

  var retval: cint
  retval = av_read_frame(fmt, pkt)
  check()
  retval = avcodec_send_packet(ctx, pkt)
  check()
  retval = avcodec_receive_frame(ctx, frame)
  check()
  true

proc saveFrameAsJpeg(fmt: ptr AVFormatContext, ctx: ptr AVCodecContext,
                    pkt: ptr AVPacket, streamid, frameno: int) =
  var retval: cint
  var jpegCodec = avcodec_find_encoder(AV_CODEC_ID_MJPEG)
  if jpegCodec.isNil:
    echo "Cannot open jpeg codec"
    return
  var jpegCtx = avcodec_alloc_context3(jpegCodec)
  if jpegCtx.isNil:
    echo "Cannot open jpeg codec"
    return

  var frame = av_frame_alloc()
  var encpkt = av_packet_alloc()
  defer:
    av_packet_free(addr encpkt);
    av_frame_free(addr frame);
    avcodec_free_context(addr jpegCtx);

  retval = av_seek_frame(fmt, cint streamid, frameno, AVSEEK_FLAG_FRAME)
  if retval < 0:
    echo "error seeking"
    return

  while true:
    if fetchFrame(fmt, frame, ctx, pkt) and pkt[].stream_index == streamid:
        break
    else:
        continue
    av_packet_unref(pkt)
  av_packet_unref(pkt)

  var streams = cast[ptr UncheckedArray[ptr AVStream]](fmt[].streams)
  jpegCtx[].time_base = streams[streamid][].time_base
  jpegCtx[].pix_fmt = AV_PIX_FMT_YUVJ420P
  jpegCtx[].height = frame[].height
  jpegCtx[].width = frame[].width
  retval = avcodec_open2(jpegCtx, jpegCodec, nil)
  if retval < 0:
    echo "error avcodec_open2"
    return
  retval = avcodec_send_frame(jpegctx, frame)
  if retval < 0:
    echo "error avcodec_send_frame"
    return
  retval = avcodec_receive_packet(jpegctx, encpkt)
  if retval < 0:
    echo "error avcodec_receive_packet"
    return
  echo "size: ", encpkt[].size
  var f = newFileStream(&"dvr-{frameno:08d}.jpg", mode = fmWrite)
  f.writeData(encpkt[].data, encpkt[].size)
  close f

proc main =
  if paramCount() < 2:
    quit(&"Usage: {getAppFilename()} <input_file> <frameno = default 1>" &
        "example program to save a specific frame to jpg.\n") 

  var frameno = 1
  if paramCount() == 2:
    frameno = try: paramStr(2).parseInt
              except: 1
  let fname = paramStr 1
  var retval: cint
  var fmtCtx = avformat_alloc_context()
  retval = avformat_open_input(addr fmtctx, fname, nil, nil)
  if retval < 0:
    echo &"error opening file {fname} with message"
    return
  retval = avformat_find_stream_info(fmtctx, nil)
  if retval < 0:
    echo &"error finding stream with message"
    return
  var streamid = -1
  var streams = cast[ptr UncheckedArray[ptr AVStream]](fmtctx[].streams)
  var codecParam: ptr AVCodecParameters
  var vidCodec: ptr AVCodec
  for i in 0 ..< fmtctx[].nb_streams:
    var locpar = streams[i][].codecpar
    var locdec = avcodec_find_decoder(locpar[].codec_id)
    if locpar[].codec_type == AVMEDIA_TYPE_VIDEO:
      vidCodec = locdec
      codecParam = locpar
      streamid = int i
      break
  var vidCtx = avcodec_alloc_context3(vidCodec)
  var packet = av_packet_alloc()
  defer:
    av_packet_free(addr packet);
    avcodec_free_context(addr vidCtx);
    avformat_close_input(addr fmtctx);
    avformat_free_context(fmtctx);

  retval = avcodec_parameters_to_context(vidCtx, codecParam)
  if retval < 0:
    echo &"failed param to context"
    return
  retval = avcodec_open2(vidCtx, vidCodec, nil)
  if retval < 0:
    echo &"failed open2 vidCtx"
    return
  saveFrameAsJpeg(fmtctx, vidCtx, packet, streamid, frameno)

main()