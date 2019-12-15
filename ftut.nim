# This example is taken from ffmpeg tutorial page
# https://github.com/leandromoreira/ffmpeg-libav-tutorial

import libavcodec/avcodec
import libavformat/avformat
import libavutil/[log, frame]
import utiltypes
import os, strformat, strutils, streams
import sugar

# the pointer math operation is from nim forum post:
# https://forum.nim-lang.org/t/1188#7366
template `+`*[T](p: ptr T, off: int): ptr T =
  cast[ptr type(p[])](cast[ByteAddress](p) +% off * sizeof(p[]))

template `+=`*[T](p: ptr T, off: int) =
  p = p + off

template `-`*[T](p: ptr T, off: int): ptr T =
  cast[ptr type(p[])](cast[ByteAddress](p) -% off * sizeof(p[]))

template `-=`*[T](p: ptr T, off: int) =
  p = p - off

template `[]`*[T](p: ptr T, off: int): T =
  (p+off)[]

template `[]=`*[T](p: ptr T, off: int, val: T) =
  (p+off)[] = val


proc saveGrayFrame(buf: ptr byte, wrap, xsize, ysize: cint, name: string) =
  var s = newFileStream(name, mode = fmWrite)
  s.write &"P5\n{xsize} {ysize}\n{255}\n"
  for i in 0 ..< ysize:
    var currbuf = buf[i * wrap]
    s.writeData(addr currbuf, xsize)
  close s

proc main =
  if paramCount() < 1:
    quit(&"Usage: {getAppFilename()} <input_file>" &
        "example program to demonstrate the use of the libavformat metadata API.\n") 

  let filename = paramStr 1
  var fmtctx = avformat_alloc_context()
  var retval = avformat_open_input(addr fmtctx, cstring filename, nil, nil)
  dump retval
  if retval != 0:
    quit &"Fail to open {filename}"
  echo "Format $#, duration $# us." % [
    $fmtctx[].iformat[].long_name, $fmtctx[].duration]

  retval = avformat_find_stream_info(fmtctx, nil)
  dump retval
  if retval < 0:
    av_log(nil, AV_LOG_ERROR, "Cannot find stream information\n")
    quit "Fail find stream info"
  echo "got $# streams." % [$fmtctx.nb_streams]
  var vidcodec: ptr AVCodec
  var vidparam: ptr AVCodecParameters
  var vidStreamId = -1
  for i in 0 ..< fmtctx[].nb_streams:
    var stream = fmtctx[].streams[int i]
    if stream.isNil:
      echo &"now stream is nil iter {i}"
      continue

    var localparam = stream.codecpar
    if localparam.isNil:
      echo &"iter {i} got nil"
      continue
    var localcodec = avcodec_find_decoder(localparam.codec_id)
    if localparam[].codec_type == AVMEDIA_TYPE_VIDEO:
      if vidStreamId == -1:
        vidcodec = localcodec
        vidparam = localparam
        vidStreamId = int i
      stdout.write "Video param: resolution $# x $#" % [
        $localparam[].width, $localparam[].height]
    elif localparam[].codec_type == AVMEDIA_TYPE_AUDIO:
      stdout.write &"Audio param: {localparam[].channels} channels, sample rate " &
        &"{localparam[].sample_rate}"
    else:
      echo &"{localparam[].codec_type}"
    if localcodec.isNil:
      continue
    echo &"   Codec {localcodec[].long_name} ID {localcodec[].id} bit rate {localparam[].bit_rate}"

  var codecContext = avcodec_alloc_context3(vidcodec)
  if codecContext.isNil:
    quit &"avcodec_alloc_context3"

  if avcodec_parameters_to_context(codecContext, vidparam) < 0:
    quit "avcodec_parameters_to_context fail!"

  if avcodec_open2(codecContext, vidcodec, nil) < 0:
    quit "avcodec_open2 fail!"
  
  var pPacket = av_packet_alloc()
  var pFrame = av_frame_alloc()
  var processedPacket = 8
  while av_read_frame(fmtctx, pPacket) >= 0:
    if pPacket[].stream_index.int == vidStreamId:
      if avcodec_send_packet(codecContext, pPacket) < 0: continue
      if avcodec_receive_frame(codecContext, pFrame) < 0: continue
      echo(("Frame $# (size=$#) pts $# dts $# key_frame $#" &
        " [coded_picture_number $#, display_picture_number $#]") % [
          $codecContext[].frame_number,
          $pFrame[].pkt_size,
          $pFrame[].pts,
          $pFrame[].pkt_dts,
          $pFrame[].key_frame,
          $pFrame[].coded_picture_number,
          $pFrame[].display_picture_number])
      let fname = &"{filename}-gray-{(8-processedPacket):02d}.pgm"
      saveGrayFrame(pFrame[].data[0], pFrame[].linesize[0],
        pFrame[].width, pFrame[].height, fname)
      dec processedPacket
    av_packet_unref(pPacket)
    if processedPacket < 0: break
  avformat_close_input(addr fmtctx)
  avformat_free_context(fmtctx)
  av_packet_free(addr pPacket)
  av_frame_free(addr pFrame)
  avcodec_free_context(addr codecContext)

main()