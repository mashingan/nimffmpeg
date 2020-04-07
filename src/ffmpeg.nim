import os

# qsv is depend on intel media sdk library hence not included.
# in case of someone want to use it, they can directly import it
# like:
# import ffmpeg/libavcodec/qsv

const source = currentSourcePath.parentDir()
const includepath = "-I" & (source / "cinclude")
{.passC: includepath.}

import ffmpeg/utiltypes

import ffmpeg/libavcodec/[avcodec, ac3_parser, adts_parser, avdct,
                          avfft, dirac, dv_profile, jni,
                          mediacodec, vorbis_parser]

when defined(windows):
  import ffmpeg/libavcodec/[d3d11va, dxva2]
else:
  import ffmpeg/libavcodec/[vaapi, vdpau, xvmc]

when defined(macosx):
  import ffmpeg/libavcodec/videotoolbox

import ffmpeg/libavdevice/avdevice

import ffmpeg/libavfilter/[avfilter, buffersink, buffersrc]

import ffmpeg/libavformat/[avformat, avio]

import ffmpeg/libavutil/[log, avutil, common, dict, frame, hwcontext,
                         opt, pixdesc, pixfmt, rational, samplefmt,
                         channel_layout, avconfig, buffer, adler32,
                         aes, aes_ctr, imgutils, error]

import ffmpeg/libpostproc/postprocess

import ffmpeg/libswresample/swresample

import ffmpeg/libswscale/swscale

export utiltypes

export avcodec, ac3_parser, adts_parser, avdct,
       avfft, dirac, dv_profile, jni,
       mediacodec, vorbis_parser

when defined(windows):
  export d3d11va, dxva2
else:
  export vaapi, vdpau, xvmc

when defined(macosx):
  export videotoolbox

export avdevice

export avfilter, buffersink, buffersrc

export avformat, avio

export log, avutil, common, dict, frame, hwcontext,
       opt, pixdesc, pixfmt, rational, samplefmt,
       channel_layout, avconfig, buffer, adler32,
       aes, aes_ctr, imgutils, error

export postprocess

export swresample

export swscale
