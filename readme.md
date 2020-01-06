# Nim FFMpeg Binding (WIP)
(Very) Thin FFMpeg C binding for Nim. The thin binding means it's almost same
with FFMpeg C APIs.  
The advantage is that we can reuse our C APIs knowledge using Nim seamlessly. We
can reuse any FFMpeg C tutorials to work with.

## Examples
Some snippet here can be used to get the first 5 video frame

```
var frameCount = 0
while frameCount < 5:
    if av_read_frame(pFrameContext, pPacket) < 0: # negative means it's error
        continue                                  # and we just skip this time
    
    if packet[].stream_index == videoIndex:       # we only process packet in specific index stream
                                                  # in this case it's video stream
        if avcodec_send_packet(pVideoCodecCtx, pPacket) < 0:  # negative means it's error
            continue
        if avcodec_receive_frame(pVideoCodecCtx, pFrame) < 0:
            continue
        doSomethingWith3YUVPlaneData(pFrame[].data) # pFrame[].data is array filled with YUV several planes
                                                    # pFrame[].data[0] is Y plane
                                                    # pFrame[].data[1] is U plane (or Cb be precise)
                                                    # pFrame[].data[2] is V plane (or Cr be precise)
        inc frameCount
```

Snippet to get the first video stream index

```
var videoIndex = -1
var streams = cast[ptr UncheckedArray[ptr AVStream]](pFormatCtx[].streams)
for i in 0 .. pFormatCtx[].nb_streams:
  let localparam = streams[i][].codecpar
  if localparam[].codec_type == AVMEDIA_TYPE_VIDEO:
    videoIndex = int i
    break
```

The index can be used later to know which stream index packet we'll process later.

Any others examples you found should be applicable with this binding too. Several worked examples
also availables in `examples` folder.

## To use
To able to compile and work with, make sure we installed shared lib to run it.