import libavcodec/version
import libavutil/[rational, buffer, dict, pixfmt]
import libavutil/version as utilvs
import libavformat/version as fmtvs

{.pragma: avcodec, importc, header: "<libavcodec/avcodec.h>".}
{.pragma: avformat, importc, header: "<libavformat/avformat.h>".}
{.pragma: avio, importc, header: "<libavformat/avio.h>".}
{.pragma: avutil, importc, header: "<libavutil/avutil.h>".}
{.pragma: frame, importc, header: "<libavutil/frame.h>".}
{.pragma: samplefmt, importc, header: "<libavutil/samplefmt.h>".}
{.pragma: avdevice, importc, header: "<libavdevice/avdevice.h>".}
{.pragma: log, importc, header: "<libavutil/log.h>".}
{.pragma: opt, importc, header: "<libavutil/opt.h>".}

const
  MAX_REORDER_DELAY* = 16

const
  MAX_STD_TIMEBASES* = (30 * 12 + 30 + 3 + 6)
  AV_PARSER_PTS_NB* = 4


const
  AV_NUM_DATA_POINTERS* = 8

  AV_FRAME_FLAG_CORRUPT* = (1 shl 0)
  AV_FRAME_FLAG_DISCARD* = (1 shl 2)

  FF_DECODE_ERROR_INVALID_BITSTREAM* = 1
  FF_DECODE_ERROR_MISSING_REFERENCE* = 2
  FF_DECODE_ERROR_CONCEALMENT_ACTIVE* = 4
  FF_DECODE_ERROR_DECODE_SLICES* = 8

type
  AVCodecTag* {.avcodec.} = object # defined in internal.h from ffmpeg source

type
  AVPictureStructure* {.avcodec.} = enum
    AV_PICTURE_STRUCTURE_UNKNOWN, ## < unknown
    AV_PICTURE_STRUCTURE_TOP_FIELD, ## < coded as top field
    AV_PICTURE_STRUCTURE_BOTTOM_FIELD, ## < coded as bottom field
    AV_PICTURE_STRUCTURE_FRAME ## < coded as frame

  AVStreamParseType* {.avformat.} = enum
    AVSTREAM_PARSE_NONE, AVSTREAM_PARSE_FULL, ## *< full parsing and repack
    AVSTREAM_PARSE_HEADERS,   ## *< Only parse headers, do not repack.
    AVSTREAM_PARSE_TIMESTAMPS, ## *< full parsing and interpolation of timestamps for frames not starting on a packet boundary
    AVSTREAM_PARSE_FULL_ONCE, ## *< full parsing and repack of the first frame only, only implemented for H.264 currently
    AVSTREAM_PARSE_FULL_RAW ## *< full parsing and repack with timestamp and position generation by parser for raw
                           ##                                     this assumes that each packet in the file contains no demuxer level headers and
                           ##                                     just codec level data, otherwise position generation would fail

type
  AVDiscard* {.avcodec, importc: "enum AVDiscard".} = enum ##  We leave some space between them for extensions (drop some
                 ##  keyframes for intra-only or drop just some bidir frames).
    AVDISCARD_NONE = -16,       ## /< discard nothing
    AVDISCARD_DEFAULT = 0,      ## /< discard useless packets like 0 size packets in avi
    AVDISCARD_NONREF = 8,       ## /< discard all non reference
    AVDISCARD_BIDIR = 16,       ## /< discard all bidirectional frames
    AVDISCARD_NONINTRA = 24,    ## /< discard all non intra frames
    AVDISCARD_NONKEY = 32,      ## /< discard all frames except keyframes
    AVDISCARD_ALL = 48          ## /< discard all

type
  AVAudioServiceType* {.avcodec, importc: "enum AVAudioServiceType".} = enum
    AV_AUDIO_SERVICE_TYPE_MAIN = 0, AV_AUDIO_SERVICE_TYPE_EFFECTS = 1,
    AV_AUDIO_SERVICE_TYPE_VISUALLY_IMPAIRED = 2,
    AV_AUDIO_SERVICE_TYPE_HEARING_IMPAIRED = 3, AV_AUDIO_SERVICE_TYPE_DIALOGUE = 4,
    AV_AUDIO_SERVICE_TYPE_COMMENTARY = 5, AV_AUDIO_SERVICE_TYPE_EMERGENCY = 6,
    AV_AUDIO_SERVICE_TYPE_VOICE_OVER = 7, AV_AUDIO_SERVICE_TYPE_KARAOKE = 8, AV_AUDIO_SERVICE_TYPE_NB ## /< Not part of ABI

type
  AVFieldOrder* {.avcodec, importc: "enum AVFieldOrder".} = enum
    AV_FIELD_UNKNOWN, AV_FIELD_PROGRESSIVE, AV_FIELD_TT, ## < Top coded_first, top displayed first
    AV_FIELD_BB,              ## < Bottom coded first, bottom displayed first
    AV_FIELD_TB,              ## < Top coded first, bottom displayed first
    AV_FIELD_BT               ## < Bottom coded first, top displayed first


type
  AVCodecID* {.avcodec, importc: "enum AVCodecID".} = enum
    AV_CODEC_ID_NONE,         ##  video codecs
    AV_CODEC_ID_MPEG1VIDEO, AV_CODEC_ID_MPEG2VIDEO, ## /< preferred ID for MPEG-1/2 video decoding
    AV_CODEC_ID_H261, AV_CODEC_ID_H263, AV_CODEC_ID_RV10, AV_CODEC_ID_RV20,
    AV_CODEC_ID_MJPEG, AV_CODEC_ID_MJPEGB, AV_CODEC_ID_LJPEG, AV_CODEC_ID_SP5X,
    AV_CODEC_ID_JPEGLS, AV_CODEC_ID_MPEG4, AV_CODEC_ID_RAWVIDEO,
    AV_CODEC_ID_MSMPEG4V1, AV_CODEC_ID_MSMPEG4V2, AV_CODEC_ID_MSMPEG4V3,
    AV_CODEC_ID_WMV1, AV_CODEC_ID_WMV2, AV_CODEC_ID_H263P, AV_CODEC_ID_H263I,
    AV_CODEC_ID_FLV1, AV_CODEC_ID_SVQ1, AV_CODEC_ID_SVQ3, AV_CODEC_ID_DVVIDEO,
    AV_CODEC_ID_HUFFYUV, AV_CODEC_ID_CYUV, AV_CODEC_ID_H264, AV_CODEC_ID_INDEO3,
    AV_CODEC_ID_VP3, AV_CODEC_ID_THEORA, AV_CODEC_ID_ASV1, AV_CODEC_ID_ASV2,
    AV_CODEC_ID_FFV1, AV_CODEC_ID_4XM, AV_CODEC_ID_VCR1, AV_CODEC_ID_CLJR,
    AV_CODEC_ID_MDEC, AV_CODEC_ID_ROQ, AV_CODEC_ID_INTERPLAY_VIDEO,
    AV_CODEC_ID_XAN_WC3, AV_CODEC_ID_XAN_WC4, AV_CODEC_ID_RPZA,
    AV_CODEC_ID_CINEPAK, AV_CODEC_ID_WS_VQA, AV_CODEC_ID_MSRLE,
    AV_CODEC_ID_MSVIDEO1, AV_CODEC_ID_IDCIN, AV_CODEC_ID_8BPS, AV_CODEC_ID_SMC,
    AV_CODEC_ID_FLIC, AV_CODEC_ID_TRUEMOTION1, AV_CODEC_ID_VMDVIDEO,
    AV_CODEC_ID_MSZH, AV_CODEC_ID_ZLIB, AV_CODEC_ID_QTRLE, AV_CODEC_ID_TSCC,
    AV_CODEC_ID_ULTI, AV_CODEC_ID_QDRAW, AV_CODEC_ID_VIXL, AV_CODEC_ID_QPEG,
    AV_CODEC_ID_PNG, AV_CODEC_ID_PPM, AV_CODEC_ID_PBM, AV_CODEC_ID_PGM,
    AV_CODEC_ID_PGMYUV, AV_CODEC_ID_PAM, AV_CODEC_ID_FFVHUFF, AV_CODEC_ID_RV30,
    AV_CODEC_ID_RV40, AV_CODEC_ID_VC1, AV_CODEC_ID_WMV3, AV_CODEC_ID_LOCO,
    AV_CODEC_ID_WNV1, AV_CODEC_ID_AASC, AV_CODEC_ID_INDEO2, AV_CODEC_ID_FRAPS,
    AV_CODEC_ID_TRUEMOTION2, AV_CODEC_ID_BMP, AV_CODEC_ID_CSCD,
    AV_CODEC_ID_MMVIDEO, AV_CODEC_ID_ZMBV, AV_CODEC_ID_AVS, AV_CODEC_ID_SMACKVIDEO,
    AV_CODEC_ID_NUV, AV_CODEC_ID_KMVC, AV_CODEC_ID_FLASHSV, AV_CODEC_ID_CAVS,
    AV_CODEC_ID_JPEG2000, AV_CODEC_ID_VMNC, AV_CODEC_ID_VP5, AV_CODEC_ID_VP6,
    AV_CODEC_ID_VP6F, AV_CODEC_ID_TARGA, AV_CODEC_ID_DSICINVIDEO,
    AV_CODEC_ID_TIERTEXSEQVIDEO, AV_CODEC_ID_TIFF, AV_CODEC_ID_GIF,
    AV_CODEC_ID_DXA, AV_CODEC_ID_DNXHD, AV_CODEC_ID_THP, AV_CODEC_ID_SGI,
    AV_CODEC_ID_C93, AV_CODEC_ID_BETHSOFTVID, AV_CODEC_ID_PTX, AV_CODEC_ID_TXD,
    AV_CODEC_ID_VP6A, AV_CODEC_ID_AMV, AV_CODEC_ID_VB, AV_CODEC_ID_PCX,
    AV_CODEC_ID_SUNRAST, AV_CODEC_ID_INDEO4, AV_CODEC_ID_INDEO5, AV_CODEC_ID_MIMIC,
    AV_CODEC_ID_RL2, AV_CODEC_ID_ESCAPE124, AV_CODEC_ID_DIRAC, AV_CODEC_ID_BFI,
    AV_CODEC_ID_CMV, AV_CODEC_ID_MOTIONPIXELS, AV_CODEC_ID_TGV, AV_CODEC_ID_TGQ,
    AV_CODEC_ID_TQI, AV_CODEC_ID_AURA, AV_CODEC_ID_AURA2, AV_CODEC_ID_V210X,
    AV_CODEC_ID_TMV, AV_CODEC_ID_V210, AV_CODEC_ID_DPX, AV_CODEC_ID_MAD,
    AV_CODEC_ID_FRWU, AV_CODEC_ID_FLASHSV2, AV_CODEC_ID_CDGRAPHICS,
    AV_CODEC_ID_R210, AV_CODEC_ID_ANM, AV_CODEC_ID_BINKVIDEO, AV_CODEC_ID_IFF_ILBM,
    AV_CODEC_ID_KGV1, AV_CODEC_ID_YOP, AV_CODEC_ID_VP8, AV_CODEC_ID_PICTOR,
    AV_CODEC_ID_ANSI, AV_CODEC_ID_A64_MULTI, AV_CODEC_ID_A64_MULTI5,
    AV_CODEC_ID_R10K, AV_CODEC_ID_MXPEG, AV_CODEC_ID_LAGARITH, AV_CODEC_ID_PRORES,
    AV_CODEC_ID_JV, AV_CODEC_ID_DFA, AV_CODEC_ID_WMV3IMAGE, AV_CODEC_ID_VC1IMAGE,
    AV_CODEC_ID_UTVIDEO, AV_CODEC_ID_BMV_VIDEO, AV_CODEC_ID_VBLE,
    AV_CODEC_ID_DXTORY, AV_CODEC_ID_V410, AV_CODEC_ID_XWD, AV_CODEC_ID_CDXL,
    AV_CODEC_ID_XBM, AV_CODEC_ID_ZEROCODEC, AV_CODEC_ID_MSS1, AV_CODEC_ID_MSA1,
    AV_CODEC_ID_TSCC2, AV_CODEC_ID_MTS2, AV_CODEC_ID_CLLC, AV_CODEC_ID_MSS2,
    AV_CODEC_ID_VP9, AV_CODEC_ID_AIC, AV_CODEC_ID_ESCAPE130, AV_CODEC_ID_G2M,
    AV_CODEC_ID_WEBP, AV_CODEC_ID_HNM4_VIDEO, AV_CODEC_ID_HEVC, AV_CODEC_ID_FIC,
    AV_CODEC_ID_ALIAS_PIX, AV_CODEC_ID_BRENDER_PIX, AV_CODEC_ID_PAF_VIDEO,
    AV_CODEC_ID_EXR, AV_CODEC_ID_VP7, AV_CODEC_ID_SANM, AV_CODEC_ID_SGIRLE,
    AV_CODEC_ID_MVC1, AV_CODEC_ID_MVC2, AV_CODEC_ID_HQX, AV_CODEC_ID_TDSC,
    AV_CODEC_ID_HQ_HQA, AV_CODEC_ID_HAP, AV_CODEC_ID_DDS, AV_CODEC_ID_DXV,
    AV_CODEC_ID_SCREENPRESSO, AV_CODEC_ID_RSCC, AV_CODEC_ID_AVS2,
    AV_CODEC_ID_Y41P = 0x00008000, AV_CODEC_ID_AVRP, AV_CODEC_ID_012V,
    AV_CODEC_ID_AVUI, AV_CODEC_ID_AYUV, AV_CODEC_ID_TARGA_Y216, AV_CODEC_ID_V308,
    AV_CODEC_ID_V408, AV_CODEC_ID_YUV4, AV_CODEC_ID_AVRN, AV_CODEC_ID_CPIA,
    AV_CODEC_ID_XFACE, AV_CODEC_ID_SNOW, AV_CODEC_ID_SMVJPEG, AV_CODEC_ID_APNG,
    AV_CODEC_ID_DAALA, AV_CODEC_ID_CFHD, AV_CODEC_ID_TRUEMOTION2RT,
    AV_CODEC_ID_M101, AV_CODEC_ID_MAGICYUV, AV_CODEC_ID_SHEERVIDEO,
    AV_CODEC_ID_YLC, AV_CODEC_ID_PSD, AV_CODEC_ID_PIXLET, AV_CODEC_ID_SPEEDHQ,
    AV_CODEC_ID_FMVC, AV_CODEC_ID_SCPR, AV_CODEC_ID_CLEARVIDEO, AV_CODEC_ID_XPM,
    AV_CODEC_ID_AV1, AV_CODEC_ID_BITPACKED, AV_CODEC_ID_MSCC, AV_CODEC_ID_SRGC,
    AV_CODEC_ID_SVG, AV_CODEC_ID_GDV, AV_CODEC_ID_FITS, AV_CODEC_ID_IMM4,
    AV_CODEC_ID_PROSUMER, AV_CODEC_ID_MWSC, AV_CODEC_ID_WCMV, AV_CODEC_ID_RASC,
    AV_CODEC_ID_HYMT, AV_CODEC_ID_ARBC, AV_CODEC_ID_AGM, AV_CODEC_ID_LSCR,
    AV_CODEC_ID_VP4, AV_CODEC_ID_IMM5, AV_CODEC_ID_MVDV, AV_CODEC_ID_MVHA, ##  various PCM "codecs"
    AV_CODEC_ID_FIRST_AUDIO = 0x00010000, ## /< A dummy id pointing at the start of audio codecs
    AV_CODEC_ID_PCM_S16BE, AV_CODEC_ID_PCM_U16LE, AV_CODEC_ID_PCM_U16BE,
    AV_CODEC_ID_PCM_S8, AV_CODEC_ID_PCM_U8, AV_CODEC_ID_PCM_MULAW,
    AV_CODEC_ID_PCM_ALAW, AV_CODEC_ID_PCM_S32LE, AV_CODEC_ID_PCM_S32BE,
    AV_CODEC_ID_PCM_U32LE, AV_CODEC_ID_PCM_U32BE, AV_CODEC_ID_PCM_S24LE,
    AV_CODEC_ID_PCM_S24BE, AV_CODEC_ID_PCM_U24LE, AV_CODEC_ID_PCM_U24BE,
    AV_CODEC_ID_PCM_S24DAUD, AV_CODEC_ID_PCM_ZORK, AV_CODEC_ID_PCM_S16LE_PLANAR,
    AV_CODEC_ID_PCM_DVD, AV_CODEC_ID_PCM_F32BE, AV_CODEC_ID_PCM_F32LE,
    AV_CODEC_ID_PCM_F64BE, AV_CODEC_ID_PCM_F64LE, AV_CODEC_ID_PCM_BLURAY,
    AV_CODEC_ID_PCM_LXF, AV_CODEC_ID_S302M, AV_CODEC_ID_PCM_S8_PLANAR,
    AV_CODEC_ID_PCM_S24LE_PLANAR, AV_CODEC_ID_PCM_S32LE_PLANAR,
    AV_CODEC_ID_PCM_S16BE_PLANAR, AV_CODEC_ID_PCM_S64LE = 0x00010800,
    AV_CODEC_ID_PCM_S64BE, AV_CODEC_ID_PCM_F16LE, AV_CODEC_ID_PCM_F24LE, AV_CODEC_ID_PCM_VIDC, ##  various ADPCM codecs
    AV_CODEC_ID_ADPCM_IMA_QT = 0x00011000, AV_CODEC_ID_ADPCM_IMA_WAV,
    AV_CODEC_ID_ADPCM_IMA_DK3, AV_CODEC_ID_ADPCM_IMA_DK4,
    AV_CODEC_ID_ADPCM_IMA_WS, AV_CODEC_ID_ADPCM_IMA_SMJPEG, AV_CODEC_ID_ADPCM_MS,
    AV_CODEC_ID_ADPCM_4XM, AV_CODEC_ID_ADPCM_XA, AV_CODEC_ID_ADPCM_ADX,
    AV_CODEC_ID_ADPCM_EA, AV_CODEC_ID_ADPCM_G726, AV_CODEC_ID_ADPCM_CT,
    AV_CODEC_ID_ADPCM_SWF, AV_CODEC_ID_ADPCM_YAMAHA, AV_CODEC_ID_ADPCM_SBPRO_4,
    AV_CODEC_ID_ADPCM_SBPRO_3, AV_CODEC_ID_ADPCM_SBPRO_2, AV_CODEC_ID_ADPCM_THP,
    AV_CODEC_ID_ADPCM_IMA_AMV, AV_CODEC_ID_ADPCM_EA_R1, AV_CODEC_ID_ADPCM_EA_R3,
    AV_CODEC_ID_ADPCM_EA_R2, AV_CODEC_ID_ADPCM_IMA_EA_SEAD,
    AV_CODEC_ID_ADPCM_IMA_EA_EACS, AV_CODEC_ID_ADPCM_EA_XAS,
    AV_CODEC_ID_ADPCM_EA_MAXIS_XA, AV_CODEC_ID_ADPCM_IMA_ISS,
    AV_CODEC_ID_ADPCM_G722, AV_CODEC_ID_ADPCM_IMA_APC, AV_CODEC_ID_ADPCM_VIMA,
    AV_CODEC_ID_ADPCM_AFC = 0x00011800, AV_CODEC_ID_ADPCM_IMA_OKI,
    AV_CODEC_ID_ADPCM_DTK, AV_CODEC_ID_ADPCM_IMA_RAD, AV_CODEC_ID_ADPCM_G726LE,
    AV_CODEC_ID_ADPCM_THP_LE, AV_CODEC_ID_ADPCM_PSX, AV_CODEC_ID_ADPCM_AICA,
    AV_CODEC_ID_ADPCM_IMA_DAT4, AV_CODEC_ID_ADPCM_MTAF, AV_CODEC_ID_ADPCM_AGM, ##  AMR
    AV_CODEC_ID_AMR_NB = 0x00012000, AV_CODEC_ID_AMR_WB, ##  RealAudio codecs
    AV_CODEC_ID_RA_144 = 0x00013000, AV_CODEC_ID_RA_288, ##  various DPCM codecs
    AV_CODEC_ID_ROQ_DPCM = 0x00014000, AV_CODEC_ID_INTERPLAY_DPCM,
    AV_CODEC_ID_XAN_DPCM, AV_CODEC_ID_SOL_DPCM,
    AV_CODEC_ID_SDX2_DPCM = 0x00014800, AV_CODEC_ID_GREMLIN_DPCM, ##  audio codecs
    AV_CODEC_ID_MP2 = 0x00015000, AV_CODEC_ID_MP3, ## /< preferred ID for decoding MPEG audio layer 1, 2 or 3
    AV_CODEC_ID_AAC, AV_CODEC_ID_AC3, AV_CODEC_ID_DTS, AV_CODEC_ID_VORBIS,
    AV_CODEC_ID_DVAUDIO, AV_CODEC_ID_WMAV1, AV_CODEC_ID_WMAV2, AV_CODEC_ID_MACE3,
    AV_CODEC_ID_MACE6, AV_CODEC_ID_VMDAUDIO, AV_CODEC_ID_FLAC, AV_CODEC_ID_MP3ADU,
    AV_CODEC_ID_MP3ON4, AV_CODEC_ID_SHORTEN, AV_CODEC_ID_ALAC,
    AV_CODEC_ID_WESTWOOD_SND1, AV_CODEC_ID_GSM, ## /< as in Berlin toast format
    AV_CODEC_ID_QDM2, AV_CODEC_ID_COOK, AV_CODEC_ID_TRUESPEECH, AV_CODEC_ID_TTA,
    AV_CODEC_ID_SMACKAUDIO, AV_CODEC_ID_QCELP, AV_CODEC_ID_WAVPACK,
    AV_CODEC_ID_DSICINAUDIO, AV_CODEC_ID_IMC, AV_CODEC_ID_MUSEPACK7,
    AV_CODEC_ID_MLP, AV_CODEC_ID_GSM_MS, ##  as found in WAV
    AV_CODEC_ID_ATRAC3, AV_CODEC_ID_APE, AV_CODEC_ID_NELLYMOSER,
    AV_CODEC_ID_MUSEPACK8, AV_CODEC_ID_SPEEX, AV_CODEC_ID_WMAVOICE,
    AV_CODEC_ID_WMAPRO, AV_CODEC_ID_WMALOSSLESS, AV_CODEC_ID_ATRAC3P,
    AV_CODEC_ID_EAC3, AV_CODEC_ID_SIPR, AV_CODEC_ID_MP1, AV_CODEC_ID_TWINVQ,
    AV_CODEC_ID_TRUEHD, AV_CODEC_ID_MP4ALS, AV_CODEC_ID_ATRAC1,
    AV_CODEC_ID_BINKAUDIO_RDFT, AV_CODEC_ID_BINKAUDIO_DCT, AV_CODEC_ID_AAC_LATM,
    AV_CODEC_ID_QDMC, AV_CODEC_ID_CELT, AV_CODEC_ID_G723_1, AV_CODEC_ID_G729,
    AV_CODEC_ID_8SVX_EXP, AV_CODEC_ID_8SVX_FIB, AV_CODEC_ID_BMV_AUDIO,
    AV_CODEC_ID_RALF, AV_CODEC_ID_IAC, AV_CODEC_ID_ILBC, AV_CODEC_ID_OPUS,
    AV_CODEC_ID_COMFORT_NOISE, AV_CODEC_ID_TAK, AV_CODEC_ID_METASOUND,
    AV_CODEC_ID_PAF_AUDIO, AV_CODEC_ID_ON2AVC, AV_CODEC_ID_DSS_SP,
    AV_CODEC_ID_CODEC2, AV_CODEC_ID_FFWAVESYNTH = 0x00015800, AV_CODEC_ID_SONIC,
    AV_CODEC_ID_SONIC_LS, AV_CODEC_ID_EVRC, AV_CODEC_ID_SMV, AV_CODEC_ID_DSD_LSBF,
    AV_CODEC_ID_DSD_MSBF, AV_CODEC_ID_DSD_LSBF_PLANAR,
    AV_CODEC_ID_DSD_MSBF_PLANAR, AV_CODEC_ID_4GV, AV_CODEC_ID_INTERPLAY_ACM,
    AV_CODEC_ID_XMA1, AV_CODEC_ID_XMA2, AV_CODEC_ID_DST, AV_CODEC_ID_ATRAC3AL,
    AV_CODEC_ID_ATRAC3PAL, AV_CODEC_ID_DOLBY_E, AV_CODEC_ID_APTX,
    AV_CODEC_ID_APTX_HD, AV_CODEC_ID_SBC, AV_CODEC_ID_ATRAC9, AV_CODEC_ID_HCOM, AV_CODEC_ID_ACELP_KELVIN, ##  subtitle codecs
    AV_CODEC_ID_FIRST_SUBTITLE = 0x00017000, ## /< A dummy ID pointing at the start of subtitle codecs.
    AV_CODEC_ID_DVB_SUBTITLE, AV_CODEC_ID_TEXT, ## /< raw UTF-8 text
    AV_CODEC_ID_XSUB, AV_CODEC_ID_SSA, AV_CODEC_ID_MOV_TEXT,
    AV_CODEC_ID_HDMV_PGS_SUBTITLE, AV_CODEC_ID_DVB_TELETEXT, AV_CODEC_ID_SRT,
    AV_CODEC_ID_MICRODVD = 0x00017800, AV_CODEC_ID_EIA_608, AV_CODEC_ID_JACOSUB,
    AV_CODEC_ID_SAMI, AV_CODEC_ID_REALTEXT, AV_CODEC_ID_STL,
    AV_CODEC_ID_SUBVIEWER1, AV_CODEC_ID_SUBVIEWER, AV_CODEC_ID_SUBRIP,
    AV_CODEC_ID_WEBVTT, AV_CODEC_ID_MPL2, AV_CODEC_ID_VPLAYER, AV_CODEC_ID_PJS,
    AV_CODEC_ID_ASS, AV_CODEC_ID_HDMV_TEXT_SUBTITLE, AV_CODEC_ID_TTML, AV_CODEC_ID_ARIB_CAPTION, ##  other specific kind of codecs (generally used for attachments)
    AV_CODEC_ID_FIRST_UNKNOWN = 0x00018000, ## /< A dummy ID pointing at the start of various fake codecs.
    AV_CODEC_ID_SCTE_35,      ## /< Contain timestamp estimated through PCR of program stream.
    AV_CODEC_ID_EPG, AV_CODEC_ID_BINTEXT = 0x00018800, AV_CODEC_ID_XBIN,
    AV_CODEC_ID_IDF, AV_CODEC_ID_OTF, AV_CODEC_ID_SMPTE_KLV, AV_CODEC_ID_DVD_NAV,
    AV_CODEC_ID_TIMED_ID3, AV_CODEC_ID_BIN_DATA, AV_CODEC_ID_PROBE = 0x00019000, ## /< codec_id is not known (like AV_CODEC_ID_NONE) but lavf should attempt to identify it
    AV_CODEC_ID_MPEG2TS = 0x00020000, ## *< _FAKE_ codec to indicate a raw MPEG-2 TS
                                   ##  stream (only used by libavformat)
    AV_CODEC_ID_MPEG4SYSTEMS = 0x00020001, ## *< _FAKE_ codec to indicate a MPEG-4 Systems
                                        ##  stream (only used by libavformat)
    AV_CODEC_ID_FFMETADATA = 0x00021000, ## /< Dummy codec for streams containing only metadata information.
    AV_CODEC_ID_WRAPPED_AVFRAME = 0x00021001 ## /< Passthrough codec, AVFrames wrapped in AVPacket

type
  AVFrameSideDataType* {.frame.} = enum ## *
                           ##  The data is the AVPanScan struct defined in libavcodec.
                           ##
    AV_FRAME_DATA_PANSCAN, ## *
                          ##  ATSC A53 Part 4 Closed Captions.
                          ##  A53 CC bitstream is stored as uint8 in AVFrameSideData.data.
                          ##  The number of bytes of CC data is AVFrameSideData.size.
                          ##
    AV_FRAME_DATA_A53_CC, ## *
                         ##  Stereoscopic 3d metadata.
                         ##  The data is the AVStereo3D struct defined in libavutil/stereo3d.h.
                         ##
    AV_FRAME_DATA_STEREO3D, ## *
                           ##  The data is the AVMatrixEncoding enum defined in libavutil/channel_layout.h.
                           ##
    AV_FRAME_DATA_MATRIXENCODING, ## *
                                 ##  Metadata relevant to a downmix procedure.
                                 ##  The data is the AVDownmixInfo struct defined in libavutil/downmix_info.h.
                                 ##
    AV_FRAME_DATA_DOWNMIX_INFO, ## *
                               ##  ReplayGain information in the form of the AVReplayGain struct.
                               ##
    AV_FRAME_DATA_REPLAYGAIN, ## *
                             ##  This side data contains a 3x3 transformation matrix describing an affine
                             ##  transformation that needs to be applied to the frame for correct
                             ##  presentation.
                             ##
                             ##  See libavutil/display.h for a detailed description of the data.
                             ##
    AV_FRAME_DATA_DISPLAYMATRIX, ## *
                                ##  Active Format Description data consisting of a single byte as specified
                                ##  in ETSI TS 101 154 using AVActiveFormatDescription enum.
                                ##
    AV_FRAME_DATA_AFD, ## *
                      ##  Motion vectors exported by some codecs (on demand through the export_mvs
                      ##  flag set in the libavcodec AVCodecContext flags2 option).
                      ##  The data is the AVMotionVector struct defined in
                      ##  libavutil/motion_vector.h.
                      ##
    AV_FRAME_DATA_MOTION_VECTORS, ## *
                                 ##  Recommmends skipping the specified number of samples. This is exported
                                 ##  only if the "skip_manual" AVOption is set in libavcodec.
                                 ##  This has the same format as AV_PKT_DATA_SKIP_SAMPLES.
                                 ##  @code
                                 ##  u32le number of samples to skip from start of this packet
                                 ##  u32le number of samples to skip from end of this packet
                                 ##  u8    reason for start skip
                                 ##  u8    reason for end   skip (0=padding silence, 1=convergence)
                                 ##  @endcode
                                 ##
    AV_FRAME_DATA_SKIP_SAMPLES, ## *
                               ##  This side data must be associated with an audio frame and corresponds to
                               ##  enum AVAudioServiceType defined in avcodec.h.
                               ##
    AV_FRAME_DATA_AUDIO_SERVICE_TYPE, ## *
                                     ##  Mastering display metadata associated with a video frame. The payload is
                                     ##  an AVMasteringDisplayMetadata type and contains information about the
                                     ##  mastering display color volume.
                                     ##
    AV_FRAME_DATA_MASTERING_DISPLAY_METADATA, ## *
                                             ##  The GOP timecode in 25 bit timecode format. Data format is 64-bit integer.
                                             ##  This is set on the first frame of a GOP that has a temporal reference of 0.
                                             ##
    AV_FRAME_DATA_GOP_TIMECODE, ## *
                               ##  The data represents the AVSphericalMapping structure defined in
                               ##  libavutil/spherical.h.
                               ##
    AV_FRAME_DATA_SPHERICAL, ## *
                            ##  Content light level (based on CTA-861.3). This payload contains data in
                            ##  the form of the AVContentLightMetadata struct.
                            ##
    AV_FRAME_DATA_CONTENT_LIGHT_LEVEL, ## *
                                      ##  The data contains an ICC profile as an opaque octet buffer following the
                                      ##  format described by ISO 15076-1 with an optional name defined in the
                                      ##  metadata key entry "name".
                                      ##
    AV_FRAME_DATA_ICC_PROFILE, ## #if FF_API_FRAME_QP
                              ## *
                              ##  Implementation-specific description of the format of AV_FRAME_QP_TABLE_DATA.
                              ##  The contents of this side data are undocumented and internal; use
                              ##  av_frame_set_qpable() and av_frame_get_qpable() to access this in a
                              ##  meaningful way instead.
                              ##
    AV_FRAME_DATA_QP_TABLE_PROPERTIES, ## *
                                      ##  Raw QP table data. Its format is described by
                                      ##  AV_FRAME_DATA_QP_TABLE_PROPERTIES. Use av_frame_set_qpable() and
                                      ##  av_frame_get_qpable() to access this instead.
                                      ##
    AV_FRAME_DATA_QP_TABLE_DATA, ## #endif
                                ## *
                                ##  Timecode which conforms to SMPTE ST 12-1. The data is an array of 4 uint32
                                ##  where the first uint32 describes how many (1-3) of the other timecodes are used.
                                ##  The timecode format is described in the avimecode_get_smpte_from_framenum()
                                ##  function in libavutil/timecode.c.
                                ##
    AV_FRAME_DATA_S12M_TIMECODE, ## *
                                ##  HDR dynamic metadata associated with a video frame. The payload is
                                ##  an AVDynamicHDRPlus type and contains information for color
                                ##  volume transform - application 4 of SMPTE 2094-40:2016 standard.
                                ##
    AV_FRAME_DATA_DYNAMIC_HDR_PLUS, ## *
                                   ##  Regions Of Interest, the data is an array of AVRegionOfInterest type, the number of
                                   ##  array element is implied by AVFrameSideData.size / AVRegionOfInterest.self_size.
                                   ##
    AV_FRAME_DATA_REGIONS_OF_INTEREST

type
  AVPictureType* {.avutil.} = enum
    AV_PICTURE_TYPE_NONE = 0,   ## /< Undefined
    AV_PICTURE_TYPE_I,        ## /< Intra
    AV_PICTURE_TYPE_P,        ## /< Predicted
    AV_PICTURE_TYPE_B,        ## /< Bi-dir predicted
    AV_PICTURE_TYPE_S,        ## /< S(GMC)-VOP MPEG-4
    AV_PICTURE_TYPE_SI,       ## /< Switching Intra
    AV_PICTURE_TYPE_SP,       ## /< Switching Predicted
    AV_PICTURE_TYPE_BI        ## /< BI type


type
  AVSampleFormat* {.samplefmt, importc: "enum AVSampleFormat".} = enum
    AV_SAMPLE_FMT_NONE = -1, AV_SAMPLE_FMT_U8, ## /< unsigned 8 bits
    AV_SAMPLE_FMT_S16,        ## /< signed 16 bits
    AV_SAMPLE_FMT_S32,        ## /< signed 32 bits
    AV_SAMPLE_FMT_FLT,        ## /< float
    AV_SAMPLE_FMT_DBL,        ## /< double
    AV_SAMPLE_FMT_U8P,        ## /< unsigned 8 bits, planar
    AV_SAMPLE_FMT_S16P,       ## /< signed 16 bits, planar
    AV_SAMPLE_FMT_S32P,       ## /< signed 32 bits, planar
    AV_SAMPLE_FMT_FLTP,       ## /< float, planar
    AV_SAMPLE_FMT_DBLP,       ## /< double, planar
    AV_SAMPLE_FMT_S64,        ## /< signed 64 bits
    AV_SAMPLE_FMT_S64P,       ## /< signed 64 bits, planar
    AV_SAMPLE_FMT_NB          ## /< Number of sample formats. DO NOT USE if linking dynamically

type
  AVClassCategory* {.avutil.} = enum
    AV_CLASS_CATEGORY_NA = 0, AV_CLASS_CATEGORY_INPUT, AV_CLASS_CATEGORY_OUTPUT,
    AV_CLASS_CATEGORY_MUXER, AV_CLASS_CATEGORY_DEMUXER, AV_CLASS_CATEGORY_ENCODER,
    AV_CLASS_CATEGORY_DECODER, AV_CLASS_CATEGORY_FILTER,
    AV_CLASS_CATEGORY_BITSTREAM_FILTER, AV_CLASS_CATEGORY_SWSCALER,
    AV_CLASS_CATEGORY_SWRESAMPLER, AV_CLASS_CATEGORY_DEVICE_VIDEO_OUTPUT = 40,
    AV_CLASS_CATEGORY_DEVICE_VIDEO_INPUT, AV_CLASS_CATEGORY_DEVICE_AUDIO_OUTPUT,
    AV_CLASS_CATEGORY_DEVICE_AUDIO_INPUT, AV_CLASS_CATEGORY_DEVICE_OUTPUT,
    AV_CLASS_CATEGORY_DEVICE_INPUT, AV_CLASS_CATEGORY_NB ## /< not part of ABI/API

when FF_API_AVPICTURE:
  ## *
  ##  @defgroup lavc_picture AVPicture
  ##
  ##  Functions for working with AVPicture
  ##  @{
  ##
  ## *
  ##  Picture data structure.
  ##
  ##  Up to four components can be stored into it, the last component is
  ##  alpha.
  ##  @deprecated use AVFrame or imgutils functions instead
  ##
  type
    AVPicture* {.avcodec.}  = object
      data*: array[AV_NUM_DATA_POINTERS, ptr uint8] ## attribute_deprecated
      ## /< pointers to the image data planes
      ## attribute_deprecated
      linesize*: array[AV_NUM_DATA_POINTERS, cint] ## /< number of bytes per line

type
  AVDeviceCapabilitiesQuery* {.avdevice.} = object
    av_class*: ptr AVClass
    device_context*: ptr AVFormatContext
    codec*: AVCodecID
    sample_format*: AVSampleFormat
    pixel_format*: AVPixelFormat
    sample_rate*: cint
    channels*: cint
    channel_layout*: int64
    window_width*: cint
    window_height*: cint
    frame_width*: cint
    frame_height*: cint
    fps*: AVRational

  AVFrameSideData* {.frame.}  = object
    `type`*: AVFrameSideDataType
    data*: ptr uint8
    size*: cint
    metadata*: ptr AVDictionary
    buf*: ptr AVBufferRef

  AVFrame* {.frame.} = object
    data*: array[AV_NUM_DATA_POINTERS, ptr uint8] ## *
                                                ##  pointer to the picture/channel planes.
                                                ##  This might be different from the first allocated byte
                                                ##
                                                ##  Some decoders access areas outside 0,0 - width,height, please
                                                ##  see avcodec_align_dimensions2(). Some filters and swscale can read
                                                ##  up to 16 bytes beyond the planes, if these filters are to be used,
                                                ##  then 16 extra bytes must be allocated.
                                                ##
                                                ##  NOTE: Except for hwaccel formats, pointers not needed by the format
                                                ##  MUST be set to NULL.
                                                ##
    ## *
    ##  For video, size in bytes of each picture line.
    ##  For audio, size in bytes of each plane.
    ##
    ##  For audio, only linesize[0] may be set. For planar audio, each channel
    ##  plane must be the same size.
    ##
    ##  For video the linesizes should be multiples of the CPUs alignment
    ##  preference, this is 16 or 32 for modern desktop CPUs.
    ##  Some code requires such alignment other code can be slower without
    ##  correct alignment, for yet other it makes no difference.
    ##
    ##  @note The linesize may be larger than the size of usable data -- there
    ##  may be extra padding present for performance reasons.
    ##
    linesize*: array[AV_NUM_DATA_POINTERS, cint] ## *
                                              ##  pointers to the data planes/channels.
                                              ##
                                              ##  For video, this should simply point to data[].
                                              ##
                                              ##  For planar audio, each channel has a separate data pointer, and
                                              ##  linesize[0] contains the size of each channel buffer.
                                              ##  For packed audio, there is just one data pointer, and linesize[0]
                                              ##  contains the total size of the buffer for all channels.
                                              ##
                                              ##  Note: Both data and extended_data should always be set in a valid frame,
                                              ##  but for planar audio with more channels that can fit in data,
                                              ##  extended_data must be used in order to access all channels.
                                              ##
    extended_data*: ptr ptr uint8 ## *
                                ##  @name Video dimensions
                                ##  Video frames only. The coded dimensions (in pixels) of the video frame,
                                ##  i.e. the size of the rectangle that contains some well-defined values.
                                ##
                                ##  @note The part of the frame intended for display/presentation is further
                                ##  restricted by the @ref cropping "Cropping rectangle".
                                ##  @{
                                ##
    width*: cint
    height*: cint ## *
                ##  @}
                ##
                ## *
                ##  number of audio samples (per channel) described by this frame
                ##
    nb_samples*: cint ## *
                    ##  format of the frame, -1 if unknown or unset
                    ##  Values correspond to enum AVPixelFormat for video frames,
                    ##  enum AVSampleFormat for audio)
                    ##
    format*: cint              ## *
                ##  1 -> keyframe, 0-> not
                ##
    key_frame*: cint           ## *
                   ##  Picture type of the frame.
                   ##
    pictype*: AVPictureType ## *
                            ##  Sample aspect ratio for the video frame, 0/1 if unknown/unspecified.
                            ##
    sample_aspect_ratio*: AVRational ## *
                                   ##  Presentation timestamp in time_base units (time when frame should be shown to user).
                                   ##
    pts*: int64
    when FF_API_PKT_PTS:
      ## *
      ##  PTS copied from the AVPacket that was decoded to produce this frame.
      ##  @deprecated use the pts field instead
      ##
      ## attribute_deprecated
      pkt_pts*: int64
    pkt_dts*: int64          ## *
                    ##  picture number in bitstream order
                    ##
    coded_picture_number*: cint ## *
                              ##  picture number in display order
                              ##
    display_picture_number*: cint ## *
                                ##  quality (between 1 (good) and FF_LAMBDA_MAX (bad))
                                ##
    quality*: cint             ## *
                 ##  for some private data of the user
                 ##
    opaque*: pointer
    when FF_API_ERROR_FRAME:
      ## *
      ##  @deprecated unused
      ##
      ## attribute_deprecated
      error*: array[AV_NUM_DATA_POINTERS, uint64]
    repeat_pict*: cint         ## *
                     ##  The content of the picture is interlaced.
                     ##
    interlaced_frame*: cint ## *
                          ##  If the content is interlaced, is top field displayed first.
                          ##
    top_field_first*: cint ## *
                         ##  Tell user application that palette has changed from previous frame.
                         ##
    palette_has_changed*: cint ## *
                             ##  reordered opaque 64 bits (generally an integer or a double precision float
                             ##  PTS but can be anything).
                             ##  The user sets AVCodecContext.reordered_opaque to represent the input at
                             ##  that time,
                             ##  the decoder reorders values as needed and sets AVFrame.reordered_opaque
                             ##  to exactly one of the values provided by the user through AVCodecContext.reordered_opaque
                             ##
    reordered_opaque*: int64 ## *
                             ##  Sample rate of the audio data.
                             ##
    sample_rate*: cint         ## *
                     ##  Channel layout of the audio data.
                     ##
    channel_layout*: uint64 ## *
                            ##  AVBuffer references backing the data for this frame. If all elements of
                            ##  this array are NULL, then this frame is not reference counted. This array
                            ##  must be filled contiguously -- if buf[i] is non-NULL then buf[j] must
                            ##  also be non-NULL for all j < i.
                            ##
                            ##  There may be at most one AVBuffer per data plane, so for video this array
                            ##  always contains all the references. For planar audio with more than
                            ##  AV_NUM_DATA_POINTERS channels, there may be more buffers than can fit in
                            ##  this array. Then the extra AVBufferRef pointers are stored in the
                            ##  extended_buf array.
                            ##
    buf*: array[AV_NUM_DATA_POINTERS, ptr AVBufferRef] ## *
                                                   ##  For planar audio which requires more than AV_NUM_DATA_POINTERS
                                                   ##  AVBufferRef pointers, this array will hold all the references which
                                                   ##  cannot fit into AVFrame.buf.
                                                   ##
                                                   ##  Note that this is different from AVFrame.extended_data, which always
                                                   ##  contains all the pointers. This array only contains the extra pointers,
                                                   ##  which cannot fit into AVFrame.buf.
                                                   ##
                                                   ##  This array is always allocated using av_malloc() by whoever constructs
                                                   ##  the frame. It is freed in av_frame_unref().
                                                   ##
    extended_buf*: ptr ptr AVBufferRef ## *
                                   ##  Number of elements in extended_buf.
                                   ##
    nb_extended_buf*: cint
    side_data*: ptr ptr AVFrameSideData
    nb_side_data*: cint ## *
                      ##  @defgroup lavu_frame_flags AV_FRAME_FLAGS
                      ##  @ingroup lavu_frame
                      ##  Flags describing additional frame properties.
                      ##
                      ##  @{
                      ##
                      ## *
                      ##  The frame data may be corrupted, e.g. due to decoding errors.
                      ##
    flags*: cint               ## *
               ##  MPEG vs JPEG YUV range.
               ##  - encoding: Set by user
               ##  - decoding: Set by libavcodec
               ##
    color_range*: AVColorRange
    color_primaries*: AVColorPrimaries
    colorrc*: AVColorTransferCharacteristic ## *
                                            ##  YUV colorspace type.
                                            ##  - encoding: Set by user
                                            ##  - decoding: Set by libavcodec
                                            ##
    colorspace*: AVColorSpace
    chroma_location*: AVChromaLocation ## *
                                     ##  frame timestamp estimated using various heuristics, in stream time base
                                     ##  - encoding: unused
                                     ##  - decoding: set by libavcodec, read by user.
                                     ##
    best_effortimestamp*: int64 ## *
                                  ##  reordered pos from the last AVPacket that has been input into the decoder
                                  ##  - encoding: unused
                                  ##  - decoding: Read by user.
                                  ##
    pkt_pos*: int64 ## *
                    ##  duration of the corresponding packet, expressed in
                    ##  AVStream->time_base units, 0 if unknown.
                    ##  - encoding: unused
                    ##  - decoding: Read by user.
                    ##
    pkt_duration*: int64     ## *
                         ##  metadata.
                         ##  - encoding: Set by user.
                         ##  - decoding: Set by libavcodec.
                         ##
    metadata*: ptr AVDictionary ## *
                             ##  decode error flags of the frame, set to a combination of
                             ##  FF_DECODE_ERROR_xxx flags if the decoder produced a frame, but there
                             ##  were errors during the decoding.
                             ##  - encoding: unused
                             ##  - decoding: set by libavcodec, read by user.
                             ##
    decode_error_flags*: cint
    channels*: cint ## *
                  ##  size of the corresponding packet containing the compressed
                  ##  frame.
                  ##  It is set to a negative value if unknown.
                  ##  - encoding: unused
                  ##  - decoding: set by libavcodec, read by user.
                  ##
    pkt_size*: cint
    when FF_API_FRAME_QP:
      ## *
      ##  QP table
      ##
      ## attribute_deprecated
      qscaleable*: ptr int8
      ## *
      ##  QP store stride
      ##
      ## attribute_deprecated
      qstride*: cint
      ## attribute_deprecated
      qscaleype*: cint
      ## attribute_deprecated
      qpable_buf*: ptr AVBufferRef
    hw_frames_ctx*: ptr AVBufferRef ## *
                                 ##  AVBufferRef for free use by the API user. FFmpeg will never check the
                                 ##  contents of the buffer ref. FFmpeg calls av_buffer_unref() on it when
                                 ##  the frame is unreferenced. av_frame_copy_props() calls create a new
                                 ##  reference with av_buffer_ref() for the target frame's opaque_ref field.
                                 ##
                                 ##  This is unrelated to the opaque field, although it serves a similar
                                 ##  purpose.
                                 ##
    opaque_ref*: ptr AVBufferRef ## *
                              ##  @anchor cropping
                              ##  @name Cropping
                              ##  Video frames only. The number of pixels to discard from the the
                              ##  top/bottom/left/right border of the frame to obtain the sub-rectangle of
                              ##  the frame intended for presentation.
                              ##  @{
                              ##
    cropop*: csize
    crop_bottom*: csize
    crop_left*: csize
    crop_right*: csize ## *
                     ##  @}
                     ##
                     ## *
                     ##  AVBufferRef for internal use by a single libav* library.
                     ##  Must not be used to transfer data between libraries.
                     ##  Has to be NULL when ownership of the frame leaves the respective library.
                     ##
                     ##  Code outside the FFmpeg libs should never check or change the contents of the buffer ref.
                     ##
                     ##  FFmpeg calls av_buffer_unref() on it when the frame is unreferenced.
                     ##  av_frame_copy_props() calls create a new reference with av_buffer_ref()
                     ##  for the target frame's private_ref field.
                     ##
    private_ref*: ptr AVBufferRef

  AVClass* {.log.} = object
    class_name*: cstring ## *
                       ##  The name of the class; usually it is the same name as the
                       ##  context structure type to which the AVClass is associated.
                       ##
    ## *
    ##  A pointer to a function which returns the name of a context
    ##  instance ctx associated with the class.
    ##
    item_name*: proc (ctx: pointer): cstring ## *
                                        ##  a pointer to the first option specified in the class if any or NULL
                                        ##
                                        ##  @see av_set_default_options()
                                        ##
    option*: ptr AVOption ## *
                       ##  LIBAVUTIL_VERSION with which this structure was created.
                       ##  This is used to allow fields to be added without requiring major
                       ##  version bumps everywhere.
                       ##
    version*: cint ## *
                 ##  Offset in the structure where log_level_offset is stored.
                 ##  0 means there is no such variable
                 ##
    log_level_offset_offset*: cint ## *
                                 ##  Offset in the structure where a pointer to the parent context for
                                 ##  logging is stored. For example a decoder could pass its AVCodecContext
                                 ##  to eval as such a parent context, which an av_log() implementation
                                 ##  could then leverage to display the parent context.
                                 ##  The offset can be NULL.
                                 ##
    parent_log_context_offset*: cint ## *
                                   ##  Return next AVOptions-enabled child or NULL
                                   ##
    child_next*: proc (obj: pointer; prev: pointer): pointer ## *
                                                      ##  Return an AVClass corresponding to the next potential
                                                      ##  AVOptions-enabled child.
                                                      ##
                                                      ##  The difference between child_next and this is that
                                                      ##  child_next iterates over _already existing_ objects, while
                                                      ##  child_class_next iterates over _all possible_ children.
                                                      ##
    child_class_next*: proc (prev: ptr AVClass): ptr AVClass ## *
                                                      ##  Category used for visualization (like color)
                                                      ##  This is only set if the category is equal for all objects using this class.
                                                      ##  available since version (51 << 16 | 56 << 8 | 100)
                                                      ##
    category*: AVClassCategory ## *
                             ##  Callback to return the category.
                             ##  available since version (51 << 16 | 59 << 8 | 100)
                             ##
    get_category*: proc (ctx: pointer): AVClassCategory ## *
                                                   ##  Callback to return the supported/allowed ranges.
                                                   ##  available since version (52.12)
                                                   ##
    query_ranges*: proc (a1: ptr ptr AVOptionRanges; obj: pointer; key: cstring;
                       flags: cint): cint

  AVOptionType* {.avutil.} = enum
    AV_OPT_TYPE_FLAGS, AV_OPT_TYPE_INT, AV_OPT_TYPE_INT64, AV_OPT_TYPE_DOUBLE,
    AV_OPT_TYPE_FLOAT, AV_OPT_TYPE_STRING, AV_OPT_TYPE_RATIONAL, AV_OPT_TYPE_BINARY, ## /< offset must point to a pointer immediately followed by an int for the length
    AV_OPT_TYPE_DICT, AV_OPT_TYPE_UINT64, AV_OPT_TYPE_CONST, AV_OPT_TYPE_IMAGE_SIZE, ## /< offset must point to two consecutive integers
    AV_OPT_TYPE_PIXEL_FMT, AV_OPT_TYPE_SAMPLE_FMT, AV_OPT_TYPE_VIDEO_RATE, ## /< offset must point to AVRational
    AV_OPT_TYPE_DURATION, AV_OPT_TYPE_COLOR, AV_OPT_TYPE_CHANNEL_LAYOUT,
    AV_OPT_TYPE_BOOL


  INNER_C_UNION_opt_278*  {.union.} = object
    i64*: int64
    dbl*: cdouble
    str*: cstring              ##  TODO those are unused now
    q*: AVRational

  AVOption*  {.opt.} = object
    name*: cstring             ## *
                 ##  short English help text
                 ##  @todo What about other languages?
                 ##
    help*: cstring ## *
                 ##  The offset relative to the context structure where the option
                 ##  value is stored. It should be 0 for named constants.
                 ##
    offset*: cint
    `type`*: AVOptionType      ## *
                        ##  the default value for scalar options
                        ##
    default_val*: INNER_C_UNION_opt_278
    min*: cdouble              ## /< minimum valid value for the option
    max*: cdouble              ## /< maximum valid value for the option
    flags*: cint
    unit*: cstring ## FIXME think about enc-audio, ... style flags
                 ## *
                 ##  The logical unit to which the option belongs. Non-constant
                 ##  options and corresponding named constants share the same
                 ##  unit. May be NULL.
                 ##

  AVOptionRange* {.opt.}  = object
    str*: cstring ## *
                ##  Value range.
                ##  For string ranges this represents the min/max length.
                ##  For dimensions this represents the min/max pixel count or width/height in multi-component case.
                ##
    value_min*: cdouble
    value_max*: cdouble ## *
                      ##  Value's component range.
                      ##  For string this represents the unicode range for chars, 0-127 limits to ASCII.
                      ##
    component_min*: cdouble
    component_max*: cdouble ## *
                          ##  Range flag.
                          ##  If set to 1 the struct encodes a range, if set to 0 a single value.
                          ##
    is_range*: cint

  AVOptionRanges* {.opt.}  = object
    range*: ptr ptr AVOptionRange ## *
                              ##  Array of option ranges.
                              ##
                              ##  Most of option types use just one component.
                              ##  Following describes multi-component option types:
                              ##
                              ##  AV_OPT_TYPE_IMAGE_SIZE:
                              ##  component index 0: range of pixel count (width * height).
                              ##  component index 1: range of width.
                              ##  component index 2: range of height.
                              ##
                              ##  @note To obtain multi-component version of this structure, user must
                              ##        provide AV_OPT_MULTI_COMPONENT_RANGE to av_opt_query_ranges or
                              ##        av_opt_query_ranges_default function.
                              ##
                              ##  Multi-component range can be read as in following example:
                              ##
                              ##  @code
                              ##  int range_index, component_index;
                              ##  AVOptionRanges *ranges;
                              ##  AVOptionRange *range[3]; //may require more than 3 in the future.
                              ##  av_opt_query_ranges(&ranges, obj, key, AV_OPT_MULTI_COMPONENT_RANGE);
                              ##  for (range_index = 0; range_index < ranges->nb_ranges; range_index++) {
                              ##      for (component_index = 0; component_index < ranges->nb_components; component_index++)
                              ##          range[component_index] = ranges->range[ranges->nb_ranges * component_index + range_index];
                              ##      //do something with range here.
                              ##  }
                              ##  av_opt_freep_ranges(&ranges);
                              ##  @endcode
                              ##
    ## *
    ##  Number of ranges per component.
    ##
    nb_ranges*: cint           ## *
                   ##  Number of componentes.
                   ##
    nb_components*: cint

  AVIODataMarkerType* {.avio, importc: "enum AVIODataMarkerType".} = enum ## *
                          ##  Header data; this needs to be present for the stream to be decodeable.
                          ##
    AVIO_DATA_MARKER_HEADER, ## *
                            ##  A point in the output bytestream where a decoder can start decoding
                            ##  (i.e. a keyframe). A demuxer/decoder given the data flagged with
                            ##  AVIO_DATA_MARKER_HEADER, followed by any AVIO_DATA_MARKER_SYNC_POINT,
                            ##  should give decodeable results.
                            ##
    AVIO_DATA_MARKER_SYNC_POINT, ## *
                                ##  A point in the output bytestream where a demuxer can start parsing
                                ##  (for non self synchronizing bytestream formats). That is, any
                                ##  non-keyframe packet start point.
                                ##
    AVIO_DATA_MARKER_BOUNDARY_POINT, ## *
                                    ##  This is any, unlabelled data. It can either be a muxer not marking
                                    ##  any positions at all, it can be an actual boundary/sync point
                                    ##  that the muxer chooses not to mark, or a later part of a packet/fragment
                                    ##  that is cut into multiple write callbacks due to limited IO buffer size.
                                    ##
    AVIO_DATA_MARKER_UNKNOWN, ## *
                             ##  Trailer data, which doesn't contain actual content, but only for
                             ##  finalizing the output file.
                             ##
    AVIO_DATA_MARKER_TRAILER, ## *
                             ##  A point in the output bytestream where the underlying AVIOContext might
                             ##  flush the buffer depending on latency or buffering requirements. Typically
                             ##  means the end of a packet.
                             ##
    AVIO_DATA_MARKER_FLUSH_POINT

  AVProbeData* {.avformat.} = object
    filename*: cstring
    buf*: ptr cuchar            ## *< Buffer must have AVPROBE_PADDING_SIZE of extra allocated bytes filled with zero.
    buf_size*: cint            ## *< Size of buf except extra allocated bytes
    mimeype*: cstring        ## *< mimeype, when known.
  AVIOContext* {.avio.} = object
    av_class*: ptr AVClass ## *
                        ##  A class for private options.
                        ##
                        ##  If this AVIOContext is created by avio_open2(), av_class is set and
                        ##  passes the options down to protocols.
                        ##
                        ##  If this AVIOContext is manually allocated, then av_class may be set by
                        ##  the caller.
                        ##
                        ##  warning -- this field can be NULL, be sure to not pass this AVIOContext
                        ##  to any av_opt_* functions in that case.
                        ##
    ##
    ##  The following shows the relationship between buffer, buf_ptr,
    ##  buf_ptr_max, buf_end, buf_size, and pos, when reading and when writing
    ##  (since AVIOContext is used for both):
    ##
    ##
    ## *********************************************************************************
    ##                                    READING
    ##
    ## *********************************************************************************
    ##
    ##                             |              buffer_size              |
    ##                             |---------------------------------------|
    ##                             |                                       |
    ##
    ##                          buffer          buf_ptr       buf_end
    ##                             +---------------+-----------------------+
    ##                             |/ / / / / / / /|/ / / / / / /|         |
    ##   read buffer:              |/ / consumed / | to be read /|         |
    ##                             |/ / / / / / / /|/ / / / / / /|         |
    ##                             +---------------+-----------------------+
    ##
    ##                                                          pos
    ##               +-------------------------------------------+-----------------+
    ##   input file: |                                           |                 |
    ##               +-------------------------------------------+-----------------+
    ##
    ##
    ##
    ## *********************************************************************************
    ##                                    WRITING
    ##
    ## *********************************************************************************
    ##
    ##                              |          buffer_size                 |
    ##                              |--------------------------------------|
    ##                              |                                      |
    ##
    ##                                                 buf_ptr_max
    ##                           buffer                 (buf_ptr)       buf_end
    ##                              +-----------------------+--------------+
    ##                              |/ / / / / / / / / / / /|              |
    ##   write buffer:              | / / to be flushed / / |              |
    ##                              |/ / / / / / / / / / / /|              |
    ##                              +-----------------------+--------------+
    ##                                buf_ptr can be in this
    ##                                due to a backward seek
    ##
    ##                             pos
    ##                +-------------+----------------------------------------------+
    ##   output file: |             |                                              |
    ##                +-------------+----------------------------------------------+
    ##
    ##
    buffer*: ptr cuchar         ## *< Start of the buffer.
    buffer_size*: cint         ## *< Maximum buffer size
    buf_ptr*: ptr cuchar        ## *< Current position in the buffer
    buf_end*: ptr cuchar ## *< End of the data, may be less than
                      ##                                  buffer+buffer_size if the read function returned
                      ##                                  less data than requested, e.g. for streams where
                      ##                                  no more data has been received yet.
    opaque*: pointer ## *< A private pointer, passed to the read/write/seek/...
                   ##                                  functions.
    read_packet*: proc (opaque: pointer; buf: ptr uint8; buf_size: cint): cint
    write_packet*: proc (opaque: pointer; buf: ptr uint8; buf_size: cint): cint
    seek*: proc (opaque: pointer; offset: int64; whence: cint): int64
    pos*: int64              ## *< position in the file of the current buffer
    eof_reached*: cint         ## *< true if was unable to read due to error or eof
    write_flag*: cint          ## *< true if open for writing
    max_packet_size*: cint
    checksum*: culong
    checksum_ptr*: ptr cuchar
    update_checksum*: proc (checksum: culong; buf: ptr uint8; size: cuint): culong
    error*: cint ## *< contains the error code or 0 if no error happened
               ## *
               ##  Pause or resume playback for network streaming protocols - e.g. MMS.
               ##
    read_pause*: proc (opaque: pointer; pause: cint): cint ## *
                                                    ##  Seek to a given timestamp in stream with the specified stream_index.
                                                    ##  Needed for some network streaming protocols which don't support seeking
                                                    ##  to byte position.
                                                    ##
    read_seek*: proc (opaque: pointer; stream_index: cint; timestamp: int64;
                    flags: cint): int64 ## *
                                       ##  A combination of AVIO_SEEKABLE_ flags or 0 when the stream is not seekable.
                                       ##
    seekable*: cint ## *
                  ##  max filesize, used to limit allocations
                  ##  This field is internal to libavformat and access from outside is not allowed.
                  ##
    maxsize*: int64 ## *
                    ##  avio_read and avio_write should if possible be satisfied directly
                    ##  instead of going through a buffer, and avio_seek will always
                    ##  call the underlying seek function directly.
                    ##
    direct*: cint ## *
                ##  Bytes read statistic
                ##  This field is internal to libavformat and access from outside is not allowed.
                ##
    bytes_read*: int64 ## *
                       ##  seek statistic
                       ##  This field is internal to libavformat and access from outside is not allowed.
                       ##
    seek_count*: cint ## *
                    ##  writeout statistic
                    ##  This field is internal to libavformat and access from outside is not allowed.
                    ##
    writeout_count*: cint ## *
                        ##  Original buffer size
                        ##  used internally after probing and ensure seekback to reset the buffer size
                        ##  This field is internal to libavformat and access from outside is not allowed.
                        ##
    orig_buffer_size*: cint ## *
                          ##  Threshold to favor readahead over seek.
                          ##  This is current internal only, do not use from outside.
                          ##
    short_seekhreshold*: cint ## *
                              ##  ',' separated list of allowed protocols.
                              ##
    protocol_whitelist*: cstring ## *
                               ##  ',' separated list of disallowed protocols.
                               ##
    protocol_blacklist*: cstring ## *
                               ##  A callback that is used instead of write_packet.
                               ##
    write_dataype*: proc (opaque: pointer; buf: ptr uint8; buf_size: cint;
                          `type`: AVIODataMarkerType; time: int64): cint ## *
                                                                      ##  If set, don't call write_dataype separately for AVIO_DATA_MARKER_BOUNDARY_POINT,
                                                                      ##  but ignore them and treat them as AVIO_DATA_MARKER_UNKNOWN (to avoid needlessly
                                                                      ##  small chunks of data returned from the callback).
                                                                      ##
    ignore_boundary_point*: cint ## *
                               ##  Internal, not meant to be used from outside of AVIOContext.
                               ##
    currentype*: AVIODataMarkerType
    lastime*: int64 ## *
                      ##  A callback that is used instead of short_seekhreshold.
                      ##  This is current internal only, do not use from outside.
                      ##
    short_seek_get*: proc (opaque: pointer): cint
    written*: int64 ## *
                    ##  Maximum reached position before a backward seek in the write buffer,
                    ##  used keeping track of already written data for a later flush.
                    ##
    buf_ptr_max*: ptr cuchar ## *
                          ##  Try to buffer at least this amount of data before flushing it
                          ##
    min_packet_size*: cint

  AVProfile* {.avcodec.} = object
    profile*: cint
    name*: cstring             ## /< short name for the profile

  AVCodecDescriptor* {.avcodec.} = object
    id*: AVCodecID
    `type`*: AVMediaType ## *
                     ##  Name of the codec described by this descriptor. It is non-empty and
                     ##  unique for each codec descriptor. It should contain alphanumeric
                     ##  characters and '_' only.
                     ##
    name*: cstring ## *
                 ##  A more descriptive name for this codec. May be NULL.
                 ##
    long_name*: cstring ## *
                      ##  Codec properties, a combination of AV_CODEC_PROP_* flags.
                      ##
    props*: cint ## *
               ##  MIME type(s) associated with the codec.
               ##  May be NULL; if not, a NULL-terminated array of MIME types.
               ##  The first item is always non-NULL and is the preferred MIME type.
               ##
    mimeypes*: cstringArray ## *
                            ##  If non-NULL, an array of profiles recognized for this codec.
                            ##  Terminated with FF_PROFILE_UNKNOWN.
                            ##
    profiles*: ptr AVProfile

  AVCodecHWConfigInternal* {.avcodec.} = object
  AVCodecDefault* {.avcodec.} = object

  AVSubtitleRect* {.avcodec.}  = object
    x*: cint                   ## /< top left corner  of pict, undefined when pict is not set
    y*: cint                   ## /< top left corner  of pict, undefined when pict is not set
    w*: cint                   ## /< width            of pict, undefined when pict is not set
    h*: cint                   ## /< height           of pict, undefined when pict is not set
    nb_colors*: cint           ## /< number of colors in pict, undefined when pict is not set
    when FF_API_AVPICTURE:
      ## *
      ##  @deprecated unused
      ##
      ## attribute_deprecated
      pict*: AVPicture
    data*: array[4, ptr uint8]
    linesize*: array[4, cint]
    `type`*: AVSubtitleType
    text*: cstring ## /< 0 terminated plain UTF-8 text
                 ## *
                 ##  0 terminated ASS/SSA compatible event line.
                 ##  The presentation of this is unaffected by the other values in this
                 ##  struct.
                 ##
    ass*: cstring
    flags*: cint

  AVSubtitle*  {.avcodec.} = object
    format*: uint16          ##  0 = graphics
    start_displayime*: uint32 ##  relative to packet pts, in ms
    end_displayime*: uint32 ##  relative to packet pts, in ms
    num_rects*: cuint
    rects*: ptr ptr AVSubtitleRect
    pts*: int64              ## /< Same as packet pts, in AV_TIME_BASE

  AVSubtitleType* {.avcodec.} = enum
    SUBTITLE_NONE, SUBTITLE_BITMAP, ## /< A bitmap, pict will be set
                                  ## *
                                  ##  Plain text, the text field must be set by the decoder and is
                                  ##  authoritative. ass and pict fields may contain approximations.
                                  ##
    SUBTITLE_TEXT, ## *
                  ##  Formatted text, the ass field must be set by the decoder and is
                  ##  authoritative. pict and text fields may contain approximations.
                  ##
    SUBTITLE_ASS

  AVPacketSideDataType* {.avcodec.} = enum ## *
                            ##  An AV_PKT_DATA_PALETTE side data packet contains exactly AVPALETTE_SIZE
                            ##  bytes worth of palette. This side data signals that a new palette is
                            ##  present.
                            ##
    AV_PKT_DATA_PALETTE, ## *
                        ##  The AV_PKT_DATA_NEW_EXTRADATA is used to notify the codec or the format
                        ##  that the extradata buffer was changed and the receiving side should
                        ##  act upon it appropriately. The new extradata is embedded in the side
                        ##  data buffer and should be immediately used for processing the current
                        ##  frame or packet.
                        ##
    AV_PKT_DATA_NEW_EXTRADATA, ## *
                              ##  An AV_PKT_DATA_PARAM_CHANGE side data packet is laid out as follows:
                              ##  @code
                              ##  u32le param_flags
                              ##  if (param_flags & AV_SIDE_DATA_PARAM_CHANGE_CHANNEL_COUNT)
                              ##      s32le channel_count
                              ##  if (param_flags & AV_SIDE_DATA_PARAM_CHANGE_CHANNEL_LAYOUT)
                              ##      u64le channel_layout
                              ##  if (param_flags & AV_SIDE_DATA_PARAM_CHANGE_SAMPLE_RATE)
                              ##      s32le sample_rate
                              ##  if (param_flags & AV_SIDE_DATA_PARAM_CHANGE_DIMENSIONS)
                              ##      s32le width
                              ##      s32le height
                              ##  @endcode
                              ##
    AV_PKT_DATA_PARAM_CHANGE, ## *
                             ##  An AV_PKT_DATA_H263_MB_INFO side data packet contains a number of
                             ##  structures with info about macroblocks relevant to splitting the
                             ##  packet into smaller packets on macroblock edges (e.g. as for RFC 2190).
                             ##  That is, it does not necessarily contain info about all macroblocks,
                             ##  as long as the distance between macroblocks in the info is smaller
                             ##  than the target payload size.
                             ##  Each MB info structure is 12 bytes, and is laid out as follows:
                             ##  @code
                             ##  u32le bit offset from the start of the packet
                             ##  u8    current quantizer at the start of the macroblock
                             ##  u8    GOB number
                             ##  u16le macroblock address within the GOB
                             ##  u8    horizontal MV predictor
                             ##  u8    vertical MV predictor
                             ##  u8    horizontal MV predictor for block number 3
                             ##  u8    vertical MV predictor for block number 3
                             ##  @endcode
                             ##
    AV_PKT_DATA_H263_MB_INFO, ## *
                             ##  This side data should be associated with an audio stream and contains
                             ##  ReplayGain information in form of the AVReplayGain struct.
                             ##
    AV_PKT_DATA_REPLAYGAIN, ## *
                           ##  This side data contains a 3x3 transformation matrix describing an affine
                           ##  transformation that needs to be applied to the decoded video frames for
                           ##  correct presentation.
                           ##
                           ##  See libavutil/display.h for a detailed description of the data.
                           ##
    AV_PKT_DATA_DISPLAYMATRIX, ## *
                              ##  This side data should be associated with a video stream and contains
                              ##  Stereoscopic 3D information in form of the AVStereo3D struct.
                              ##
    AV_PKT_DATA_STEREO3D, ## *
                         ##  This side data should be associated with an audio stream and corresponds
                         ##  to enum AVAudioServiceType.
                         ##
    AV_PKT_DATA_AUDIO_SERVICE_TYPE, ## *
                                   ##  This side data contains quality related information from the encoder.
                                   ##  @code
                                   ##  u32le quality factor of the compressed frame. Allowed range is between 1 (good) and FF_LAMBDA_MAX (bad).
                                   ##  u8    picture type
                                   ##  u8    error count
                                   ##  u16   reserved
                                   ##  u64le[error count] sum of squared differences between encoder in and output
                                   ##  @endcode
                                   ##
    AV_PKT_DATA_QUALITY_STATS, ## *
                              ##  This side data contains an integer value representing the stream index
                              ##  of a "fallback" track.  A fallback track indicates an alternate
                              ##  track to use when the current track can not be decoded for some reason.
                              ##  e.g. no decoder available for codec.
                              ##
    AV_PKT_DATA_FALLBACK_TRACK, ## *
                               ##  This side data corresponds to the AVCPBProperties struct.
                               ##
    AV_PKT_DATA_CPB_PROPERTIES, ## *
                               ##  Recommmends skipping the specified number of samples
                               ##  @code
                               ##  u32le number of samples to skip from start of this packet
                               ##  u32le number of samples to skip from end of this packet
                               ##  u8    reason for start skip
                               ##  u8    reason for end   skip (0=padding silence, 1=convergence)
                               ##  @endcode
                               ##
    AV_PKT_DATA_SKIP_SAMPLES, ## *
                             ##  An AV_PKT_DATA_JP_DUALMONO side data packet indicates that
                             ##  the packet may contain "dual mono" audio specific to Japanese DTV
                             ##  and if it is true, recommends only the selected channel to be used.
                             ##  @code
                             ##  u8    selected channels (0=mail/left, 1=sub/right, 2=both)
                             ##  @endcode
                             ##
    AV_PKT_DATA_JP_DUALMONO, ## *
                            ##  A list of zero terminated key/value strings. There is no end marker for
                            ##  the list, so it is required to rely on the side data size to stop.
                            ##
    AV_PKT_DATA_STRINGS_METADATA, ## *
                                 ##  Subtitle event position
                                 ##  @code
                                 ##  u32le x1
                                 ##  u32le y1
                                 ##  u32le x2
                                 ##  u32le y2
                                 ##  @endcode
                                 ##
    AV_PKT_DATA_SUBTITLE_POSITION, ## *
                                  ##  Data found in BlockAdditional element of matroska container. There is
                                  ##  no end marker for the data, so it is required to rely on the side data
                                  ##  size to recognize the end. 8 byte id (as found in BlockAddId) followed
                                  ##  by data.
                                  ##
    AV_PKT_DATA_MATROSKA_BLOCKADDITIONAL, ## *
                                         ##  The optional first identifier line of a WebVTT cue.
                                         ##
    AV_PKT_DATA_WEBVTT_IDENTIFIER, ## *
                                  ##  The optional settings (rendering instructions) that immediately
                                  ##  follow the timestamp specifier of a WebVTT cue.
                                  ##
    AV_PKT_DATA_WEBVTT_SETTINGS, ## *
                                ##  A list of zero terminated key/value strings. There is no end marker for
                                ##  the list, so it is required to rely on the side data size to stop. This
                                ##  side data includes updated metadata which appeared in the stream.
                                ##
    AV_PKT_DATA_METADATA_UPDATE, ## *
                                ##  MPEGTS stream ID as uint8, this is required to pass the stream ID
                                ##  information from the demuxer to the corresponding muxer.
                                ##
    AV_PKT_DATA_MPEGTS_STREAM_ID, ## *
                                 ##  Mastering display metadata (based on SMPTE-2086:2014). This metadata
                                 ##  should be associated with a video stream and contains data in the form
                                 ##  of the AVMasteringDisplayMetadata struct.
                                 ##
    AV_PKT_DATA_MASTERING_DISPLAY_METADATA, ## *
                                           ##  This side data should be associated with a video stream and corresponds
                                           ##  to the AVSphericalMapping structure.
                                           ##
    AV_PKT_DATA_SPHERICAL, ## *
                          ##  Content light level (based on CTA-861.3). This metadata should be
                          ##  associated with a video stream and contains data in the form of the
                          ##  AVContentLightMetadata struct.
                          ##
    AV_PKT_DATA_CONTENT_LIGHT_LEVEL, ## *
                                    ##  ATSC A53 Part 4 Closed Captions. This metadata should be associated with
                                    ##  a video stream. A53 CC bitstream is stored as uint8 in AVPacketSideData.data.
                                    ##  The number of bytes of CC data is AVPacketSideData.size.
                                    ##
    AV_PKT_DATA_A53_CC, ## *
                       ##  This side data is encryption initialization data.
                       ##  The format is not part of ABI, use av_encryption_init_info_* methods to
                       ##  access.
                       ##
    AV_PKT_DATA_ENCRYPTION_INIT_INFO, ## *
                                     ##  This side data contains encryption info for how to decrypt the packet.
                                     ##  The format is not part of ABI, use av_encryption_info_* methods to access.
                                     ##
    AV_PKT_DATA_ENCRYPTION_INFO, ## *
                                ##  Active Format Description data consisting of a single byte as specified
                                ##  in ETSI TS 101 154 using AVActiveFormatDescription enum.
                                ##
    AV_PKT_DATA_AFD, ## *
                    ##  The number of side data types.
                    ##  This is not part of the public API/ABI in the sense that it may
                    ##  change when new side data types are added.
                    ##  This must stay the last enum value.
                    ##  If its value becomes huge, some code using it
                    ##  needs to be updated as it assumes it to be smaller than other limits.
                    ##
    AV_PKT_DATA_NB

  AVPacketSideData* {.avcodec.}  = object
    data*: ptr uint8
    size*: cint
    `type`*: AVPacketSideDataType


  AVPacketList* {.avformat.} = object
    pkt*: AVPacket
    next*: ptr AVPacketList

  AVPacket* {.avformat.}  = object
    buf*: ptr AVBufferRef ## *
                       ##  A reference to the reference-counted buffer where the packet data is
                       ##  stored.
                       ##  May be NULL, then the packet data is not reference-counted.
                       ##
    ## *
    ##  Presentation timestamp in AVStream->time_base units; the time at which
    ##  the decompressed packet will be presented to the user.
    ##  Can be AV_NOPTS_VALUE if it is not stored in the file.
    ##  pts MUST be larger or equal to dts as presentation cannot happen before
    ##  decompression, unless one wants to view hex dumps. Some formats misuse
    ##  the terms dts and pts/cts to mean something different. Such timestamps
    ##  must be converted to true pts/dts before they are stored in AVPacket.
    ##
    pts*: int64 ## *
                ##  Decompression timestamp in AVStream->time_base units; the time at which
                ##  the packet is decompressed.
                ##  Can be AV_NOPTS_VALUE if it is not stored in the file.
                ##
    dts*: int64
    data*: ptr uint8
    size*: cint
    stream_index*: cint        ## *
                      ##  A combination of AV_PKT_FLAG values
                      ##
    flags*: cint ## *
               ##  Additional packet data that can be provided by the container.
               ##  Packet can contain several types of side information.
               ##
    side_data*: ptr AVPacketSideData
    side_data_elems*: cint ## *
                         ##  Duration of this packet in AVStream->time_base units, 0 if unknown.
                         ##  Equals next_pts - this_pts in presentation order.
                         ##
    duration*: int64
    pos*: int64              ## /< byte position in stream, -1 if unknown
    when FF_API_CONVERGENCE_DURATION:
      ## *
      ##  @deprecated Same as the duration field, but as int64. This was required
      ##  for Matroska subtitles, whose duration values could overflow when the
      ##  duration field was still an int.
      ##
      ## attribute_deprecated
      convergence_duration*: int64

  AVCodec* {.avcodec.} = object
    ## *
    ##  AVCodec.
    ##
    name*: cstring ## *
                 ##  Name of the codec implementation.
                 ##  The name is globally unique among encoders and among decoders (but an
                 ##  encoder and a decoder can share the same name).
                 ##  This is the primary way to find a codec from the user perspective.
                 ##
    ## *
    ##  Descriptive name for the codec, meant to be more human readable than name.
    ##  You should use the NULL_IF_CONFIG_SMALL() macro to define it.
    ##
    long_name*: cstring
    `type`*: AVMediaType
    id*: AVCodecID             ## *
                 ##  Codec capabilities.
                 ##  see AV_CODEC_CAP_*
                 ##
    capabilities*: cint
    supported_framerates*: ptr AVRational ## /< array of supported framerates, or NULL if any, array is terminated by {0,0}
    pix_fmts*: ptr AVPixelFormat ## /< array of supported pixel formats, or NULL if unknown, array is terminated by -1
    supported_samplerates*: ptr cint ## /< array of supported audio samplerates, or NULL if unknown, array is terminated by 0
    sample_fmts*: ptr AVSampleFormat ## /< array of supported sample formats, or NULL if unknown, array is terminated by -1
    channel_layouts*: ptr uint64 ## /< array of support channel layouts, or NULL if unknown. array is terminated by 0
    max_lowres*: uint8       ## /< maximum value for lowres supported by the decoder
    priv_class*: ptr AVClass    ## /< AVClass for the private context
    profiles*: ptr AVProfile ## /< array of recognized profiles, or NULL if unknown, array is terminated by {FF_PROFILE_UNKNOWN}
                          ## *
                          ##  Group name of the codec implementation.
                          ##  This is a short symbolic name of the wrapper backing this codec. A
                          ##  wrapper uses some kind of external implementation for the codec, such
                          ##  as an external library, or a codec implementation provided by the OS or
                          ##  the hardware.
                          ##  If this field is NULL, this is a builtin, libavcodec native codec.
                          ##  If non-NULL, this will be the suffix in AVCodec.name in most cases
                          ##  (usually AVCodec.name will be of the form "<codec_name>_<wrapper_name>").
                          ##
    wrapper_name*: cstring ## ****************************************************************
                         ##  No fields below this line are part of the public API. They
                         ##  may not be used outside of libavcodec and can be changed and
                         ##  removed at will.
                         ##  New public fields should be added right above.
                         ## ****************************************************************
                         ##
    priv_data_size*: cint
    next*: ptr AVCodec ## *
                    ##  @name Frame-level threading support functions
                    ##  @{
                    ##
                    ## *
                    ##  If defined, called on thread contexts when they are created.
                    ##  If the codec allocates writable tables in init(), re-allocate them here.
                    ##  priv_data will be set to a copy of the original.
                    ##
    inithread_copy*: proc (a1: ptr AVCodecContext): cint ## *
                                                     ##  Copy necessary context variables from a previous thread context to the current one.
                                                     ##  If not defined, the next thread will start automatically; otherwise, the codec
                                                     ##  must call ffhread_finish_setup().
                                                     ##
                                                     ##  dst and src will (rarely) point to the same context, in which case memcpy should be skipped.
                                                     ##
    updatehread_context*: proc (dst: ptr AVCodecContext; src: ptr AVCodecContext): cint ##
                                                                                 ## *
                                                                                 ## @}
                                                                                 ##
                                                                                 ## *
                                                                                 ##
                                                                                 ## Private
                                                                                 ## codec-specific
                                                                                 ## defaults.
                                                                                 ##
    defaults*: ptr AVCodecDefault ## *
                               ##  Initialize codec static data, called from avcodec_register().
                               ##
                               ##  This is not intended for time consuming operations as it is
                               ##  run for every codec regardless of that codec being used.
                               ##
    init_static_data*: proc (codec: ptr AVCodec)
    init*: proc (a1: ptr AVCodecContext): cint
    encode_sub*: proc (a1: ptr AVCodecContext; buf: ptr uint8; buf_size: cint;
                     sub: ptr AVSubtitle): cint ## *
                                            ##  Encode data to an AVPacket.
                                            ##
                                            ##  @param      avctx          codec context
                                            ##  @param      avpkt          output AVPacket (may contain a user-provided buffer)
                                            ##  @param[in]  frame          AVFrame containing the raw data to be encoded
                                            ##  @param[out] got_packet_ptr encoder sets to 0 or 1 to indicate that a
                                            ##                             non-empty packet was returned in avpkt.
                                            ##  @return 0 on success, negative error code on failure
                                            ##
    encode2*: proc (avctx: ptr AVCodecContext; avpkt: ptr AVPacket; frame: ptr AVFrame;
                  got_packet_ptr: ptr cint): cint
    decode*: proc (a1: ptr AVCodecContext; outdata: pointer; outdata_size: ptr cint;
                 avpkt: ptr AVPacket): cint
    close*: proc (a1: ptr AVCodecContext): cint ## *
                                          ##  Encode API with decoupled packet/frame dataflow. The API is the
                                          ##  same as the avcodec_ prefixed APIs (avcodec_send_frame() etc.), except
                                          ##  that:
                                          ##  - never called if the codec is closed or the wrong type,
                                          ##  - if AV_CODEC_CAP_DELAY is not set, drain frames are never sent,
                                          ##  - only one drain frame is ever passed down,
                                          ##
    send_frame*: proc (avctx: ptr AVCodecContext; frame: ptr AVFrame): cint
    receive_packet*: proc (avctx: ptr AVCodecContext; avpkt: ptr AVPacket): cint ## *
                                                                        ##  Decode API with decoupled packet/frame dataflow. This function is called
                                                                        ##  to get one output frame. It should call ff_decode_get_packet() to obtain
                                                                        ##  input data.
                                                                        ##
    receive_frame*: proc (avctx: ptr AVCodecContext; frame: ptr AVFrame): cint ## *
                                                                      ##  Flush buffers.
                                                                      ##  Will be called when seeking
                                                                      ##
    flush*: proc (a1: ptr AVCodecContext) ## *
                                     ##  Internal codec capabilities.
                                     ##  See FF_CODEC_CAP_* in internal.h
                                     ##
    caps_internal*: cint ## *
                       ##  Decoding only, a comma-separated list of bitstream filters to apply to
                       ##  packets before decoding.
                       ##
    bsfs*: cstring ## *
                 ##  Array of pointers to hardware configurations supported by the codec,
                 ##  or NULL if no hardware supported.  The array is terminated by a NULL
                 ##  pointer.
                 ##
                 ##  The user can only access this field via avcodec_get_hw_config().
                 ##
    hw_configs*: ptr ptr AVCodecHWConfigInternal

  AVMediaType* {.avutil, importc: "enum AVMediaType".} = enum
    AVMEDIA_TYPE_UNKNOWN = -1,  ## /< Usually treated as AVMEDIA_TYPE_DATA
    AVMEDIA_TYPE_VIDEO, AVMEDIA_TYPE_AUDIO, AVMEDIA_TYPE_DATA, ## /< Opaque data information usually continuous
    AVMEDIA_TYPE_SUBTITLE, AVMEDIA_TYPE_ATTACHMENT, ## /< Opaque data information usually sparse
    AVMEDIA_TYPE_NB

  AVCodecInternal* {.avcodec.}  = object

  RcOverride* {.avcodec.} = object
    start_frame*: cint
    end_frame*: cint
    qscale*: cint              ##  If this is 0 then quality_factor will be used instead.
    quality_factor*: cfloat

  MpegEncContext* {.avcodec, importc: "struct MpegEncContext".} = object

  AVHWAccel*  {.avcodec.} = object
    name*: cstring ## *
                 ##  Name of the hardware accelerated codec.
                 ##  The name is globally unique among encoders and among decoders (but an
                 ##  encoder and a decoder can share the same name).
                 ##
    ## *
    ##  Type of codec implemented by the hardware accelerator.
    ##
    ##  See AVMEDIA_TYPE_xxx
    ##
    `type`*: AVMediaType         ## *
                     ##  Codec implemented by the hardware accelerator.
                     ##
                     ##  See AV_CODEC_ID_xxx
                     ##
    id*: AVCodecID ## *
                 ##  Supported pixel format.
                 ##
                 ##  Only hardware accelerated formats are supported here.
                 ##
    pix_fmt*: AVPixelFormat    ## *
                          ##  Hardware accelerated codec capabilities.
                          ##  see AV_HWACCEL_CODEC_CAP_*
                          ##
    capabilities*: cint ## ****************************************************************
                      ##  No fields below this line are part of the public API. They
                      ##  may not be used outside of libavcodec and can be changed and
                      ##  removed at will.
                      ##  New public fields should be added right above.
                      ## ****************************************************************
                      ##
                      ## *
                      ##  Allocate a custom buffer
                      ##
    alloc_frame*: proc (avctx: ptr AVCodecContext; frame: ptr AVFrame): cint ## *
                                                                    ##  Called at the beginning of each frame or field picture.
                                                                    ##
                                                                    ##  Meaningful frame information (codec specific) is guaranteed to
                                                                    ##  be parsed at this point. This function is mandatory.
                                                                    ##
                                                                    ##  Note that buf can be NULL along with buf_size set to 0.
                                                                    ##  Otherwise, this means the whole frame is available at this point.
                                                                    ##
                                                                    ##  @param avctx the codec context
                                                                    ##  @param buf the frame data buffer base
                                                                    ##  @param buf_size the size of the frame in bytes
                                                                    ##  @return zero if successful, a negative value otherwise
                                                                    ##
    start_frame*: proc (avctx: ptr AVCodecContext; buf: ptr uint8; buf_size: uint32): cint ## *
                                                                                    ##  Callback for parameter data (SPS/PPS/VPS etc).
                                                                                    ##
                                                                                    ##  Useful for hardware decoders which keep persistent state about the
                                                                                    ##  video parameters, and need to receive any changes to update that state.
                                                                                    ##
                                                                                    ##  @param avctx the codec context
                                                                                    ##  @param type the nal unit type
                                                                                    ##  @param buf the nal unit data buffer
                                                                                    ##  @param buf_size the size of the nal unit in bytes
                                                                                    ##  @return zero if successful, a negative value otherwise
                                                                                    ##
    decode_params*: proc (avctx: ptr AVCodecContext; `type`: cint; buf: ptr uint8;
                        buf_size: uint32): cint ## *
                                               ##  Callback for each slice.
                                               ##
                                               ##  Meaningful slice information (codec specific) is guaranteed to
                                               ##  be parsed at this point. This function is mandatory.
                                               ##  The only exception is XvMC, that works on MB level.
                                               ##
                                               ##  @param avctx the codec context
                                               ##  @param buf the slice data buffer base
                                               ##  @param buf_size the size of the slice in bytes
                                               ##  @return zero if successful, a negative value otherwise
                                               ##
    decode_slice*: proc (avctx: ptr AVCodecContext; buf: ptr uint8; buf_size: uint32): cint ## *
                                                                                     ##  Called at the end of each frame or field picture.
                                                                                     ##
                                                                                     ##  The whole picture is parsed at this point and can now be sent
                                                                                     ##  to the hardware accelerator. This function is mandatory.
                                                                                     ##
                                                                                     ##  @param avctx the codec context
                                                                                     ##  @return zero if successful, a negative value otherwise
                                                                                     ##
    end_frame*: proc (avctx: ptr AVCodecContext): cint ## *
                                                 ##  Size of per-frame hardware accelerator private data.
                                                 ##
                                                 ##  Private data is allocated with av_mallocz() before
                                                 ##  AVCodecContext.get_buffer() and deallocated after
                                                 ##  AVCodecContext.release_buffer().
                                                 ##
    frame_priv_data_size*: cint ## *
                              ##  Called for every Macroblock in a slice.
                              ##
                              ##  XvMC uses it to replace the ff_mpv_reconstruct_mb().
                              ##  Instead of decoding to raw picture, MB parameters are
                              ##  stored in an array provided by the video driver.
                              ##
                              ##  @param s the mpeg context
                              ##
    decode_mb*: proc (s: ptr MpegEncContext) ## *
                                        ##  Initialize the hwaccel private data.
                                        ##
                                        ##  This will be called from ff_get_format(), after hwaccel and
                                        ##  hwaccel_context are set and the hwaccel private data in AVCodecInternal
                                        ##  is allocated.
                                        ##
    init*: proc (avctx: ptr AVCodecContext): cint ## *
                                            ##  Uninitialize the hwaccel private data.
                                            ##
                                            ##  This will be called from get_format() or avcodec_close(), after hwaccel
                                            ##  and hwaccel_context are already uninitialized.
                                            ##
    uninit*: proc (avctx: ptr AVCodecContext): cint ## *
                                              ##  Size of the private data to allocate in
                                              ##  AVCodecInternal.hwaccel_priv_data.
                                              ##
    priv_data_size*: cint      ## *
                        ##  Internal hwaccel capabilities.
                        ##
    caps_internal*: cint ## *
                       ##  Fill the given hw_frames context with current codec parameters. Called
                       ##  from get_format. Refer to avcodec_get_hw_frames_parameters() for
                       ##  details.
                       ##
                       ##  This CAN be called before AVHWAccel.init is called, and you must assume
                       ##  that avctx->hwaccel_priv_data is invalid.
                       ##
    frame_params*: proc (avctx: ptr AVCodecContext; hw_frames_ctx: ptr AVBufferRef): cint

  AVCodecContext* {.avcodec.} = object
    av_class*: ptr AVClass      ## *
                        ##  information on struct for av_log
                        ##  - set by avcodec_alloc_context3
                        ##
    log_level_offset*: cint
    codec_type*: AVMediaType   ##  see AVMEDIA_TYPE_xxx
    codec*: ptr AVCodec
    codec_id*: AVCodecID ##  see AV_CODEC_ID_xxx
                       ## *
                       ##  fourcc (LSB first, so "ABCD" -> ('D'<<24) + ('C'<<16) + ('B'<<8) + 'A').
                       ##  This is used to work around some encoder bugs.
                       ##  A demuxer should set this to what is stored in the field used to identify the codec.
                       ##  If there are multiple such fields in a container then the demuxer should choose the one
                       ##  which maximizes the information about the used codec.
                       ##  If the codec tag field in a container is larger than 32 bits then the demuxer should
                       ##  remap the longer ID to 32 bits with a table or other structure. Alternatively a new
                       ##  extra_codecag + size could be added but for this a clear advantage must be demonstrated
                       ##  first.
                       ##  - encoding: Set by user, if not then the default based on codec_id will be used.
                       ##  - decoding: Set by user, will be converted to uppercase by libavcodec during init.
                       ##
    codecag*: cuint
    priv_data*: pointer ## *
                      ##  Private context used for internal data.
                      ##
                      ##  Unlike priv_data, this is not codec-specific. It is used in general
                      ##  libavcodec functions.
                      ##
    internal*: ptr AVCodecInternal ## *
                                ##  Private data of the user, can be used to carry app specific stuff.
                                ##  - encoding: Set by user.
                                ##  - decoding: Set by user.
                                ##
    opaque*: pointer ## *
                   ##  the average bitrate
                   ##  - encoding: Set by user; unused for constant quantizer encoding.
                   ##  - decoding: Set by user, may be overwritten by libavcodec
                   ##              if this info is available in the stream
                   ##
    bit_rate*: int64 ## *
                     ##  number of bits the bitstream is allowed to diverge from the reference.
                     ##            the reference can be CBR (for CBR pass1) or VBR (for pass2)
                     ##  - encoding: Set by user; unused for constant quantizer encoding.
                     ##  - decoding: unused
                     ##
    bit_rateolerance*: cint ## *
                            ##  Global quality for codecs which cannot change it per frame.
                            ##  This should be proportional to MPEG-1/2/4 qscale.
                            ##  - encoding: Set by user.
                            ##  - decoding: unused
                            ##
    global_quality*: cint      ## *
                        ##  - encoding: Set by user.
                        ##  - decoding: unused
                        ##
    compression_level*: cint
    flags*: cint               ## *
               ##  AV_CODEC_FLAG2_*
               ##  - encoding: Set by user.
               ##  - decoding: Set by user.
               ##
    flags2*: cint ## *
                ##  some codecs need / can use extradata like Huffman tables.
                ##  MJPEG: Huffman tables
                ##  rv10: additional flags
                ##  MPEG-4: global headers (they can be in the bitstream or here)
                ##  The allocated memory should be AV_INPUT_BUFFER_PADDING_SIZE bytes larger
                ##  than extradata_size to avoid problems if it is read with the bitstream reader.
                ##  The bytewise contents of extradata must not depend on the architecture or CPU endianness.
                ##  Must be allocated with the av_malloc() family of functions.
                ##  - encoding: Set/allocated/freed by libavcodec.
                ##  - decoding: Set/allocated/freed by user.
                ##
    extradata*: ptr uint8
    extradata_size*: cint ## *
                        ##  This is the fundamental unit of time (in seconds) in terms
                        ##  of which frame timestamps are represented. For fixed-fps content,
                        ##  timebase should be 1/framerate and timestamp increments should be
                        ##  identically 1.
                        ##  This often, but not always is the inverse of the frame rate or field rate
                        ##  for video. 1/time_base is not the average frame rate if the frame rate is not
                        ##  constant.
                        ##
                        ##  Like containers, elementary streams also can store timestamps, 1/time_base
                        ##  is the unit in which these timestamps are specified.
                        ##  As example of such codec time base see ISO/IEC 14496-2:2001(E)
                        ##  vopime_increment_resolution and fixed_vop_rate
                        ##  (fixed_vop_rate == 0 implies that it is different from the framerate)
                        ##
                        ##  - encoding: MUST be set by user.
                        ##  - decoding: the use of this field for decoding is deprecated.
                        ##              Use framerate instead.
                        ##
    time_base*: AVRational ## *
                         ##  For some codecs, the time base is closer to the field rate than the frame rate.
                         ##  Most notably, H.264 and MPEG-2 specify time_base as half of frame duration
                         ##  if no telecine is used ...
                         ##
                         ##  Set to time_base ticks per frame. Default 1, e.g., H.264/MPEG-2 set it to 2.
                         ##
    ticks_per_frame*: cint ## *
                         ##  Codec delay.
                         ##
                         ##  Encoding: Number of frames delay there will be from the encoder input to
                         ##            the decoder output. (we assume the decoder matches the spec)
                         ##  Decoding: Number of frames delay in addition to what a standard decoder
                         ##            as specified in the spec would produce.
                         ##
                         ##  Video:
                         ##    Number of frames the decoded output will be delayed relative to the
                         ##    encoded input.
                         ##
                         ##  Audio:
                         ##    For encoding, this field is unused (see initial_padding).
                         ##
                         ##    For decoding, this is the number of samples the decoder needs to
                         ##    output before the decoder's output is valid. When seeking, you should
                         ##    start decoding this many samples prior to your desired seek point.
                         ##
                         ##  - encoding: Set by libavcodec.
                         ##  - decoding: Set by libavcodec.
                         ##
    delay*: cint ##  video only
               ## *
               ##  picture width / height.
               ##
               ##  @note Those fields may not match the values of the last
               ##  AVFrame output by avcodec_decode_video2 due frame
               ##  reordering.
               ##
               ##  - encoding: MUST be set by user.
               ##  - decoding: May be set by the user before opening the decoder if known e.g.
               ##              from the container. Some decoders will require the dimensions
               ##              to be set by the caller. During decoding, the decoder may
               ##              overwrite those values as required while parsing the data.
               ##
    width*: cint
    height*: cint ## *
                ##  Bitstream width / height, may be different from width/height e.g. when
                ##  the decoded frame is cropped before being output or lowres is enabled.
                ##
                ##  @note Those field may not match the value of the last
                ##  AVFrame output by avcodec_receive_frame() due frame
                ##  reordering.
                ##
                ##  - encoding: unused
                ##  - decoding: May be set by the user before opening the decoder if known
                ##              e.g. from the container. During decoding, the decoder may
                ##              overwrite those values as required while parsing the data.
                ##
    coded_width*: cint
    coded_height*: cint ## *
                      ##  the number of pictures in a group of pictures, or 0 for intra_only
                      ##  - encoding: Set by user.
                      ##  - decoding: unused
                      ##
    gop_size*: cint ## *
                  ##  Pixel format, see AV_PIX_FMT_xxx.
                  ##  May be set by the demuxer if known from headers.
                  ##  May be overridden by the decoder if it knows better.
                  ##
                  ##  @note This field may not match the value of the last
                  ##  AVFrame output by avcodec_receive_frame() due frame
                  ##  reordering.
                  ##
                  ##  - encoding: Set by user.
                  ##  - decoding: Set by user if known, overridden by libavcodec while
                  ##              parsing the data.
                  ##
    pix_fmt*: AVPixelFormat ## *
                          ##  If non NULL, 'draw_horiz_band' is called by the libavcodec
                          ##  decoder to draw a horizontal band. It improves cache usage. Not
                          ##  all codecs can do that. You must check the codec capabilities
                          ##  beforehand.
                          ##  When multithreading is used, it may be called from multiple threads
                          ##  at the same time; threads might draw different parts of the same AVFrame,
                          ##  or multiple AVFrames, and there is no guarantee that slices will be drawn
                          ##  in order.
                          ##  The function is also used by hardware acceleration APIs.
                          ##  It is called at least once during frame decoding to pass
                          ##  the data needed for hardware render.
                          ##  In that mode instead of pixel data, AVFrame points to
                          ##  a structure specific to the acceleration API. The application
                          ##  reads the structure and can change some fields to indicate progress
                          ##  or mark state.
                          ##  - encoding: unused
                          ##  - decoding: Set by user.
                          ##  @param height the height of the slice
                          ##  @param y the y position of the slice
                          ##  @param type 1->top field, 2->bottom field, 3->frame
                          ##  @param offset offset into the AVFrame.data from which the slice should be read
                          ##
    draw_horiz_band*: proc (s: ptr AVCodecContext; src: ptr AVFrame;
                          offset: array[AV_NUM_DATA_POINTERS, cint]; y: cint;
                          `type`: cint; height: cint) ## *
                                                ##  callback to negotiate the pixelFormat
                                                ##  @param fmt is the list of formats which are supported by the codec,
                                                ##  it is terminated by -1 as 0 is a valid format, the formats are ordered by quality.
                                                ##  The first is always the native one.
                                                ##  @note The callback may be called again immediately if initialization for
                                                ##  the selected (hardware-accelerated) pixel format failed.
                                                ##  @warning Behavior is undefined if the callback returns a value not
                                                ##  in the fmt list of formats.
                                                ##  @return the chosen format
                                                ##  - encoding: unused
                                                ##  - decoding: Set by user, if not set the native format will be chosen.
                                                ##
    get_format*: proc (s: ptr AVCodecContext; fmt: ptr AVPixelFormat): AVPixelFormat ## *
                                                                            ##  maximum number of B-frames between non-B-frames
                                                                            ##  Note: The output will be delayed by max_b_frames+1 relative to the input.
                                                                            ##  - encoding: Set by user.
                                                                            ##  - decoding: unused
                                                                            ##
    max_b_frames*: cint ## *
                      ##  qscale factor between IP and B-frames
                      ##  If > 0 then the last P-frame quantizer will be used (q= lastp_q*factor+offset).
                      ##  If < 0 then normal ratecontrol will be done (q= -normal_q*factor+offset).
                      ##  - encoding: Set by user.
                      ##  - decoding: unused
                      ##
    b_quant_factor*: cfloat
    when FF_API_PRIVATE_OPT:
      ## * @deprecated use encoder private options instead
      ## attribute_deprecated
      b_frame_strategy*: cint
    b_quant_offset*: cfloat ## *
                          ##  Size of the frame reordering buffer in the decoder.
                          ##  For MPEG-2 it is 1 IPB or 0 low delay IP.
                          ##  - encoding: Set by libavcodec.
                          ##  - decoding: Set by libavcodec.
                          ##
    has_b_frames*: cint
    when FF_API_PRIVATE_OPT:
      ## * @deprecated use encoder private options instead
      ## attribute_deprecated
      mpeg_quant*: cint
    i_quant_factor*: cfloat    ## *
                          ##  qscale offset between P and I-frames
                          ##  - encoding: Set by user.
                          ##  - decoding: unused
                          ##
    i_quant_offset*: cfloat    ## *
                          ##  luminance masking (0-> disabled)
                          ##  - encoding: Set by user.
                          ##  - decoding: unused
                          ##
    lumi_masking*: cfloat      ## *
                        ##  temporary complexity masking (0-> disabled)
                        ##  - encoding: Set by user.
                        ##  - decoding: unused
                        ##
    temporal_cplx_masking*: cfloat ## *
                                 ##  spatial complexity masking (0-> disabled)
                                 ##  - encoding: Set by user.
                                 ##  - decoding: unused
                                 ##
    spatial_cplx_masking*: cfloat ## *
                                ##  p block masking (0-> disabled)
                                ##  - encoding: Set by user.
                                ##  - decoding: unused
                                ##
    p_masking*: cfloat         ## *
                     ##  darkness masking (0-> disabled)
                     ##  - encoding: Set by user.
                     ##  - decoding: unused
                     ##
    dark_masking*: cfloat      ## *
                        ##  slice count
                        ##  - encoding: Set by libavcodec.
                        ##  - decoding: Set by user (or 0).
                        ##
    slice_count*: cint
    when FF_API_PRIVATE_OPT:
      ## * @deprecated use encoder private options instead
      ## attribute_deprecated
      prediction_method*: cint
    slice_offset*: ptr cint ## *
                         ##  sample aspect ratio (0 if unknown)
                         ##  That is the width of a pixel divided by the height of the pixel.
                         ##  Numerator and denominator must be relatively prime and smaller than 256 for some video standards.
                         ##  - encoding: Set by user.
                         ##  - decoding: Set by libavcodec.
                         ##
    sample_aspect_ratio*: AVRational ## *
                                   ##  motion estimation comparison function
                                   ##  - encoding: Set by user.
                                   ##  - decoding: unused
                                   ##
    me_cmp*: cint              ## *
                ##  subpixel motion estimation comparison function
                ##  - encoding: Set by user.
                ##  - decoding: unused
                ##
    me_sub_cmp*: cint ## *
                    ##  macroblock comparison function (not supported yet)
                    ##  - encoding: Set by user.
                    ##  - decoding: unused
                    ##
    mb_cmp*: cint              ## *
                ##  interlaced DCT comparison function
                ##  - encoding: Set by user.
                ##  - decoding: unused
                ##
    ildct_cmp*: cint
    dia_size*: cint ## *
                  ##  amount of previous MV predictors (2a+1 x 2a+1 square)
                  ##  - encoding: Set by user.
                  ##  - decoding: unused
                  ##
    last_predictor_count*: cint
    when FF_API_PRIVATE_OPT:
      ## * @deprecated use encoder private options instead
      ## attribute_deprecated
      pre_me*: cint
    me_pre_cmp*: cint          ## *
                    ##  ME prepass diamond size & shape
                    ##  - encoding: Set by user.
                    ##  - decoding: unused
                    ##
    pre_dia_size*: cint        ## *
                      ##  subpel ME quality
                      ##  - encoding: Set by user.
                      ##  - decoding: unused
                      ##
    me_subpel_quality*: cint ## *
                           ##  maximum motion estimation search range in subpel units
                           ##  If 0 then no limit.
                           ##
                           ##  - encoding: Set by user.
                           ##  - decoding: unused
                           ##
    me_range*: cint            ## *
                  ##  slice flags
                  ##  - encoding: unused
                  ##  - decoding: Set by user.
                  ##
    slice_flags*: cint
    mb_decision*: cint
    intra_matrix*: ptr uint16 ## *
                             ##  custom inter quantization matrix
                             ##  Must be allocated with the av_malloc() family of functions, and will be freed in
                             ##  avcodec_free_context().
                             ##  - encoding: Set/allocated by user, freed by libavcodec. Can be NULL.
                             ##  - decoding: Set/allocated/freed by libavcodec.
                             ##
    inter_matrix*: ptr uint16
    when FF_API_PRIVATE_OPT:
      ## * @deprecated use encoder private options instead
      ## attribute_deprecated
      scenechangehreshold*: cint
      ## * @deprecated use encoder private options instead
      ## attribute_deprecated
      noise_reduction*: cint
    intra_dc_precision*: cint ## *
                            ##  Number of macroblock rows at the top which are skipped.
                            ##  - encoding: unused
                            ##  - decoding: Set by user.
                            ##
    skipop*: cint ## *
                  ##  Number of macroblock rows at the bottom which are skipped.
                  ##  - encoding: unused
                  ##  - decoding: Set by user.
                  ##
    skip_bottom*: cint         ## *
                     ##  minimum MB Lagrange multiplier
                     ##  - encoding: Set by user.
                     ##  - decoding: unused
                     ##
    mb_lmin*: cint             ## *
                 ##  maximum MB Lagrange multiplier
                 ##  - encoding: Set by user.
                 ##  - decoding: unused
                 ##
    mb_lmax*: cint
    when FF_API_PRIVATE_OPT:
      ## *
      ##  @deprecated use encoder private options instead
      ##
      ## attribute_deprecated
      me_penalty_compensation*: cint
    bidir_refine*: cint
    when FF_API_PRIVATE_OPT:
      ## * @deprecated use encoder private options instead
      ## attribute_deprecated
      brd_scale*: cint
    keyint_min*: cint          ## *
                    ##  number of reference frames
                    ##  - encoding: Set by user.
                    ##  - decoding: Set by lavc.
                    ##
    refs*: cint
    when FF_API_PRIVATE_OPT:
      ## * @deprecated use encoder private options instead
      ## attribute_deprecated
      chromaoffset*: cint
    mv0hreshold*: cint
    when FF_API_PRIVATE_OPT:
      ## * @deprecated use encoder private options instead
      ## attribute_deprecated
      b_sensitivity*: cint
    color_primaries*: AVColorPrimaries ## *
                                     ##  Color Transfer Characteristic.
                                     ##  - encoding: Set by user
                                     ##  - decoding: Set by libavcodec
                                     ##
    colorrc*: AVColorTransferCharacteristic ## *
                                            ##  YUV colorspace type.
                                            ##  - encoding: Set by user
                                            ##  - decoding: Set by libavcodec
                                            ##
    colorspace*: AVColorSpace  ## *
                            ##  MPEG vs JPEG YUV range.
                            ##  - encoding: Set by user
                            ##  - decoding: Set by libavcodec
                            ##
    color_range*: AVColorRange ## *
                             ##  This defines the location of chroma samples.
                             ##  - encoding: Set by user
                             ##  - decoding: Set by libavcodec
                             ##
    chroma_sample_location*: AVChromaLocation ## *
                                            ##  Number of slices.
                                            ##  Indicates number of picture subdivisions. Used for parallelized
                                            ##  decoding.
                                            ##  - encoding: Set by user
                                            ##  - decoding: unused
                                            ##
    slices*: cint              ## * Field order
                ##  - encoding: set by libavcodec
                ##  - decoding: Set by user.
                ##
    field_order*: AVFieldOrder ##  audio only
    sample_rate*: cint         ## /< samples per second
    channels*: cint            ## /< number of audio channels
                  ## *
                  ##  audio sample format
                  ##  - encoding: Set by user.
                  ##  - decoding: Set by libavcodec.
                  ##
    sample_fmt*: AVSampleFormat ## /< sample format
                              ##  The following data should not be initialized.
                              ## *
                              ##  Number of samples per channel in an audio frame.
                              ##
                              ##  - encoding: set by libavcodec in avcodec_open2(). Each submitted frame
                              ##    except the last must contain exactly frame_size samples per channel.
                              ##    May be 0 when the codec has AV_CODEC_CAP_VARIABLE_FRAME_SIZE set, then the
                              ##    frame size is not restricted.
                              ##  - decoding: may be set by some decoders to indicate constant frame size
                              ##
    frame_size*: cint ## *
                    ##  Frame counter, set by libavcodec.
                    ##
                    ##  - decoding: total number of frames returned from the decoder so far.
                    ##  - encoding: total number of frames passed to the encoder so far.
                    ##
                    ##    @note the counter is not incremented if encoding/decoding resulted in
                    ##    an error.
                    ##
    frame_number*: cint ## *
                      ##  number of bytes per packet if constant and known or 0
                      ##  Used by some WAV based audio codecs.
                      ##
    block_align*: cint         ## *
                     ##  Audio cutoff bandwidth (0 means "automatic")
                     ##  - encoding: Set by user.
                     ##  - decoding: unused
                     ##
    cutoff*: cint ## *
                ##  Audio channel layout.
                ##  - encoding: set by user.
                ##  - decoding: set by user, may be overwritten by libavcodec.
                ##
    channel_layout*: uint64 ## *
                            ##  Request decoder to use this channel layout if it can (0 for default)
                            ##  - encoding: unused
                            ##  - decoding: Set by user.
                            ##
    request_channel_layout*: uint64 ## *
                                    ##  Type of service that the audio stream conveys.
                                    ##  - encoding: Set by user.
                                    ##  - decoding: Set by libavcodec.
                                    ##
    audio_serviceype*: AVAudioServiceType ## *
                                          ##  desired sample format
                                          ##  - encoding: Not used.
                                          ##  - decoding: Set by user.
                                          ##  Decoder will decode to this format if it can.
                                          ##
    request_sample_fmt*: AVSampleFormat ## *
                                      ##  This callback is called at the beginning of each frame to get data
                                      ##  buffer(s) for it. There may be one contiguous buffer for all the data or
                                      ##  there may be a buffer per each data plane or anything in between. What
                                      ##  this means is, you may set however many entries in buf[] you feel necessary.
                                      ##  Each buffer must be reference-counted using the AVBuffer API (see description
                                      ##  of buf[] below).
                                      ##
                                      ##  The following fields will be set in the frame before this callback is
                                      ##  called:
                                      ##  - format
                                      ##  - width, height (video only)
                                      ##  - sample_rate, channel_layout, nb_samples (audio only)
                                      ##  Their values may differ from the corresponding values in
                                      ##  AVCodecContext. This callback must use the frame values, not the codec
                                      ##  context values, to calculate the required buffer size.
                                      ##
                                      ##  This callback must fill the following fields in the frame:
                                      ##  - data[]
                                      ##  - linesize[]
                                      ##  - extended_data:
                                      ##    * if the data is planar audio with more than 8 channels, then this
                                      ##      callback must allocate and fill extended_data to contain all pointers
                                      ##      to all data planes. data[] must hold as many pointers as it can.
                                      ##      extended_data must be allocated with av_malloc() and will be freed in
                                      ##      av_frame_unref().
                                      ##    * otherwise extended_data must point to data
                                      ##  - buf[] must contain one or more pointers to AVBufferRef structures. Each of
                                      ##    the frame's data and extended_data pointers must be contained in these. That
                                      ##    is, one AVBufferRef for each allocated chunk of memory, not necessarily one
                                      ##    AVBufferRef per data[] entry. See: av_buffer_create(), av_buffer_alloc(),
                                      ##    and av_buffer_ref().
                                      ##  - extended_buf and nb_extended_buf must be allocated with av_malloc() by
                                      ##    this callback and filled with the extra buffers if there are more
                                      ##    buffers than buf[] can hold. extended_buf will be freed in
                                      ##    av_frame_unref().
                                      ##
                                      ##  If AV_CODEC_CAP_DR1 is not set then get_buffer2() must call
                                      ##  avcodec_default_get_buffer2() instead of providing buffers allocated by
                                      ##  some other means.
                                      ##
                                      ##  Each data plane must be aligned to the maximum required by the target
                                      ##  CPU.
                                      ##
                                      ##  @see avcodec_default_get_buffer2()
                                      ##
                                      ##  Video:
                                      ##
                                      ##  If AV_GET_BUFFER_FLAG_REF is set in flags then the frame may be reused
                                      ##  (read and/or written to if it is writable) later by libavcodec.
                                      ##
                                      ##  avcodec_align_dimensions2() should be used to find the required width and
                                      ##  height, as they normally need to be rounded up to the next multiple of 16.
                                      ##
                                      ##  Some decoders do not support linesizes changing between frames.
                                      ##
                                      ##  If frame multithreading is used and thread_safe_callbacks is set,
                                      ##  this callback may be called from a different thread, but not from more
                                      ##  than one at once. Does not need to be reentrant.
                                      ##
                                      ##  @see avcodec_align_dimensions2()
                                      ##
                                      ##  Audio:
                                      ##
                                      ##  Decoders request a buffer of a particular size by setting
                                      ##  AVFrame.nb_samples prior to calling get_buffer2(). The decoder may,
                                      ##  however, utilize only part of the buffer by setting AVFrame.nb_samples
                                      ##  to a smaller value in the output frame.
                                      ##
                                      ##  As a convenience, av_samples_get_buffer_size() and
                                      ##  av_samples_fill_arrays() in libavutil may be used by custom get_buffer2()
                                      ##  functions to find the required data size and to fill data pointers and
                                      ##  linesize. In AVFrame.linesize, only linesize[0] may be set for audio
                                      ##  since all planes must be the same size.
                                      ##
                                      ##  @see av_samples_get_buffer_size(), av_samples_fill_arrays()
                                      ##
                                      ##  - encoding: unused
                                      ##  - decoding: Set by libavcodec, user can override.
                                      ##
    get_buffer2*: proc (s: ptr AVCodecContext; frame: ptr AVFrame; flags: cint): cint ## *
                                                                           ##  If non-zero, the decoded audio and video frames returned from
                                                                           ##  avcodec_decode_video2() and avcodec_decode_audio4() are reference-counted
                                                                           ##  and are valid indefinitely. The caller must free them with
                                                                           ##  av_frame_unref() when they are not needed anymore.
                                                                           ##  Otherwise, the decoded frames must not be freed by the caller and are
                                                                           ##  only valid until the next decode call.
                                                                           ##
                                                                           ##  This is always automatically enabled if avcodec_receive_frame() is used.
                                                                           ##
                                                                           ##  - encoding: unused
                                                                           ##  - decoding: set by the caller before avcodec_open2().
                                                                           ##
                                                                           ## attribute_deprecated
    refcounted_frames*: cint   ##  - encoding parameters
    qcompress*: cfloat         ## /< amount of qscale change between easy & hard scenes (0.0-1.0)
    qblur*: cfloat             ## /< amount of qscale smoothing over time (0.0-1.0)
                 ## *
                 ##  minimum quantizer
                 ##  - encoding: Set by user.
                 ##  - decoding: unused
                 ##
    qmin*: cint                ## *
              ##  maximum quantizer
              ##  - encoding: Set by user.
              ##  - decoding: unused
              ##
    qmax*: cint                ## *
              ##  maximum quantizer difference between frames
              ##  - encoding: Set by user.
              ##  - decoding: unused
              ##
    max_qdiff*: cint           ## *
                   ##  decoder bitstream buffer size
                   ##  - encoding: Set by user.
                   ##  - decoding: unused
                   ##
    rc_buffer_size*: cint      ## *
                        ##  ratecontrol override, see RcOverride
                        ##  - encoding: Allocated/set/freed by user.
                        ##  - decoding: unused
                        ##
    rc_override_count*: cint
    rc_override*: ptr RcOverride ## *
                              ##  maximum bitrate
                              ##  - encoding: Set by user.
                              ##  - decoding: Set by user, may be overwritten by libavcodec.
                              ##
    rc_max_rate*: int64      ## *
                        ##  minimum bitrate
                        ##  - encoding: Set by user.
                        ##  - decoding: unused
                        ##
    rc_min_rate*: int64 ## *
                        ##  Ratecontrol attempt to use, at maximum, <value> of what can be used without an underflow.
                        ##  - encoding: Set by user.
                        ##  - decoding: unused.
                        ##
    rc_max_available_vbv_use*: cfloat ## *
                                    ##  Ratecontrol attempt to use, at least, <value> times the amount needed to prevent a vbv overflow.
                                    ##  - encoding: Set by user.
                                    ##  - decoding: unused.
                                    ##
    rc_min_vbv_overflow_use*: cfloat ## *
                                   ##  Number of bits which should be loaded into the rc buffer before decoding starts.
                                   ##  - encoding: Set by user.
                                   ##  - decoding: unused
                                   ##
    rc_initial_buffer_occupancy*: cint
    when FF_API_CODER_TYPE:
      ## *
      ##  @deprecated use encoder private options instead
      ##
      ## attribute_deprecated
      coderype*: cint
    when FF_API_PRIVATE_OPT:
      ## * @deprecated use encoder private options instead
      ## attribute_deprecated
      context_model*: cint
      frame_skiphreshold*: cint
      frame_skip_factor*: cint
      frame_skip_exp*: cint
      frame_skip_cmp*: cint
    trellis*: cint
    when FF_API_PRIVATE_OPT:
      ## * @deprecated use encoder private options instead
      ## attribute_deprecated
      min_prediction_order*: cint
      max_prediction_order*: cint
      timecode_frame_start*: int64
    when FF_API_RTP_CALLBACK:
      ## *
      ##  @deprecated unused
      ##
      ##  The RTP callback: This function is called
      ##  every time the encoder has a packet to send.
      ##  It depends on the encoder if the data starts
      ##  with a Start Code (it should). H.263 does.
      ##  mb_nb contains the number of macroblocks
      ##  encoded in the RTP payload.
      ## attribute_deprecated
      rtp_callback*: proc (avctx: ptr AVCodecContext; data: pointer; size: cint;
                         mb_nb: cint)
    when FF_API_PRIVATE_OPT:
      ## * @deprecated use encoder private options instead
      ## attribute_deprecated
      rtp_payload_size*: cint
      ##  The size of the RTP payload: the coder will
      ##  do its best to deliver a chunk with size
      ##  below rtp_payload_size, the chunk will start
      ##  with a start code on some codecs like H.263.
      ##  This doesn't take account of any particular
      ##  headers inside the transmitted RTP payload.
    when FF_API_STAT_BITS:
      ##  statistics, used for 2-pass encoding
      ## attribute_deprecated
      mv_bits*: cint
      ## attribute_deprecated
      header_bits*: cint
      ## attribute_deprecated
      iex_bits*: cint
      ## attribute_deprecated
      pex_bits*: cint
      ## attribute_deprecated
      i_count*: cint
      ## attribute_deprecated
      p_count*: cint
      ## attribute_deprecated
      skip_count*: cint
      ## attribute_deprecated
      misc_bits*: cint
      ## * @deprecated this field is unused
      ## attribute_deprecated
      frame_bits*: cint
    stats_out*: cstring ## *
                      ##  pass2 encoding statistics input buffer
                      ##  Concatenated stuff from stats_out of pass1 should be placed here.
                      ##  - encoding: Allocated/set/freed by user.
                      ##  - decoding: unused
                      ##
    stats_in*: cstring ## *
                     ##  Work around bugs in encoders which sometimes cannot be detected automatically.
                     ##  - encoding: Set by user
                     ##  - decoding: Set by user
                     ##
    workaround_bugs*: cint
    strict_std_compliance*: cint
    error_concealment*: cint
    debug*: cint
    when FF_API_DEBUG_MV:
      ## *
      ##  @deprecated this option does nothing
      ##
      debug_mv*: cint
      #[
      const
        FF_DEBUG_MV* = 32
      ]#
    err_recognition*: cint ## *
                         ##  Verify checksums embedded in the bitstream (could be of either encoded or
                         ##  decoded data, depending on the codec) and print an error message on mismatch.
                         ##  If AV_EF_EXPLODE is also set, a mismatching checksum will result in the
                         ##  decoder returning an error.
                         ##
    reordered_opaque*: int64 ## *
                             ##  Hardware accelerator in use
                             ##  - encoding: unused.
                             ##  - decoding: Set by libavcodec
                             ##
    hwaccel*: ptr AVHWAccel ## *
                         ##  Hardware accelerator context.
                         ##  For some hardware accelerators, a global context needs to be
                         ##  provided by the user. In that case, this holds display-dependent
                         ##  data FFmpeg cannot instantiate itself. Please refer to the
                         ##  FFmpeg HW accelerator documentation to know how to fill this
                         ##  is. e.g. for VA API, this is a struct vaapi_context.
                         ##  - encoding: unused
                         ##  - decoding: Set by user
                         ##
    hwaccel_context*: pointer ## *
                            ##  error
                            ##  - encoding: Set by libavcodec if flags & AV_CODEC_FLAG_PSNR.
                            ##  - decoding: unused
                            ##
    error*: array[AV_NUM_DATA_POINTERS, uint64] ## *
                                               ##  DCT algorithm, see FF_DCT_* below
                                               ##  - encoding: Set by user.
                                               ##  - decoding: unused
                                               ##
    dct_algo*: cint
    idct_algo*: cint
    bits_per_coded_sample*: cint ## *
                               ##  Bits per sample/pixel of internal libavcodec pixel/sample format.
                               ##  - encoding: set by user.
                               ##  - decoding: set by libavcodec.
                               ##
    bits_per_raw_sample*: cint
    when FF_API_LOWRES:
      ## *
      ##  low resolution decoding, 1-> 1/2 size, 2->1/4 size
      ##  - encoding: unused
      ##  - decoding: Set by user.
      ##
      lowres*: cint
    when FF_API_CODED_FRAME:
      ## *
      ##  the picture in the bitstream
      ##  - encoding: Set by libavcodec.
      ##  - decoding: unused
      ##
      ##  @deprecated use the quality factor packet side data instead
      ##
      ## attribute_deprecated AVFrame *coded_frame;
    thread_count*: cint ## *
                      ##  Which multithreading methods to use.
                      ##  Use of FF_THREAD_FRAME will increase decoding delay by one frame per thread,
                      ##  so clients which cannot provide future frames should not use it.
                      ##
                      ##  - encoding: Set by user, otherwise the default is used.
                      ##  - decoding: Set by user, otherwise the default is used.
                      ##
    threadype*: cint
    activehreadype*: cint ## *
                            ##  Set by the client if its custom get_buffer() callback can be called
                            ##  synchronously from another thread, which allows faster multithreaded decoding.
                            ##  draw_horiz_band() will be called from other threads regardless of this setting.
                            ##  Ignored if the default get_buffer() is used.
                            ##  - encoding: Set by user.
                            ##  - decoding: Set by user.
                            ##
    thread_safe_callbacks*: cint ## *
                               ##  The codec may call this to execute several independent things.
                               ##  It will return only after finishing all tasks.
                               ##  The user may replace this with some multithreaded implementation,
                               ##  the default implementation will execute the parts serially.
                               ##  @param count the number of things to execute
                               ##  - encoding: Set by libavcodec, user can override.
                               ##  - decoding: Set by libavcodec, user can override.
                               ##
    execute*: proc (c: ptr AVCodecContext;
                  `func`: proc (c2: ptr AVCodecContext; arg: pointer): cint;
                  arg2: pointer; ret: ptr cint; count: cint; size: cint): cint ## *
                                                                     ##  The codec may call this to execute several independent things.
                                                                     ##  It will return only after finishing all tasks.
                                                                     ##  The user may replace this with some multithreaded implementation,
                                                                     ##  the default implementation will execute the parts serially.
                                                                     ##  Also see avcodechread_init and e.g. the --enable-pthread configure option.
                                                                     ##  @param c context passed also to func
                                                                     ##  @param count the number of things to execute
                                                                     ##  @param arg2 argument passed unchanged to func
                                                                     ##  @param ret return values of executed functions, must have space for "count" values. May be NULL.
                                                                     ##  @param func function that will be called count times, with jobnr from 0 to count-1.
                                                                     ##              threadnr will be in the range 0 to c->thread_count-1 < MAX_THREADS and so that no
                                                                     ##              two instances of func executing at the same time will have the same threadnr.
                                                                     ##  @return always 0 currently, but code should handle a future improvement where when any call to func
                                                                     ##          returns < 0 no further calls to func may be done and < 0 is returned.
                                                                     ##  - encoding: Set by libavcodec, user can override.
                                                                     ##  - decoding: Set by libavcodec, user can override.
                                                                     ##
    execute2*: proc (c: ptr AVCodecContext; `func`: proc (c2: ptr AVCodecContext;
        arg: pointer; jobnr: cint; threadnr: cint): cint; arg2: pointer; ret: ptr cint;
                   count: cint): cint ## *
                                   ##  noise vs. sse weight for the nsse comparison function
                                   ##  - encoding: Set by user.
                                   ##  - decoding: unused
                                   ##
    nsse_weight*: cint         ## *
                     ##  profile
                     ##  - encoding: Set by user.
                     ##  - decoding: Set by libavcodec.
                     ##
    profile*: cint
    level*: cint
    skip_loop_filter*: AVDiscard ## *
                               ##  Skip IDCT/dequantization for selected frames.
                               ##  - encoding: unused
                               ##  - decoding: Set by user.
                               ##
    skip_idct*: AVDiscard      ## *
                        ##  Skip decoding for selected frames.
                        ##  - encoding: unused
                        ##  - decoding: Set by user.
                        ##
    skip_frame*: AVDiscard ## *
                         ##  Header containing style information for text subtitles.
                         ##  For SUBTITLE_ASS subtitle type, it should contain the whole ASS
                         ##  [Script Info] and [V4+ Styles] section, plus the [Events] line and
                         ##  the Format line following. It shouldn't include any Dialogue line.
                         ##  - encoding: Set/allocated/freed by user (before avcodec_open2())
                         ##  - decoding: Set/allocated/freed by libavcodec (by avcodec_open2())
                         ##
    subtitle_header*: ptr uint8
    subtitle_header_size*: cint
    when FF_API_VBV_DELAY:
      ## *
      ##  VBV delay coded in the last frame (in periods of a 27 MHz clock).
      ##  Used for compliant TS muxing.
      ##  - encoding: Set by libavcodec.
      ##  - decoding: unused.
      ##  @deprecated this value is now exported as a part of
      ##  AV_PKT_DATA_CPB_PROPERTIES packet side data
      ##
      ## attribute_deprecated
      vbv_delay*: uint64
    when FF_API_SIDEDATA_ONLY_PKT:
      ## *
      ##  Encoding only and set by default. Allow encoders to output packets
      ##  that do not contain any encoded data, only side data.
      ##
      ##  Some encoders need to output such packets, e.g. to update some stream
      ##  parameters at the end of encoding.
      ##
      ##  @deprecated this field disables the default behaviour and
      ##              it is kept only for compatibility.
      ##
      ## attribute_deprecated
      side_data_only_packets*: cint
    initial_padding*: cint ## *
                         ##  - decoding: For codecs that store a framerate value in the compressed
                         ##              bitstream, the decoder may export it here. { 0, 1} when
                         ##              unknown.
                         ##  - encoding: May be used to signal the framerate of CFR content to an
                         ##              encoder.
                         ##
    framerate*: AVRational ## *
                         ##  Nominal unaccelerated pixel format, see AV_PIX_FMT_xxx.
                         ##  - encoding: unused.
                         ##  - decoding: Set by libavcodec before calling get_format()
                         ##
    sw_pix_fmt*: AVPixelFormat ## *
                             ##  Timebase in which pkt_dts/pts and AVPacket.dts/pts are.
                             ##  - encoding unused.
                             ##  - decoding set by user.
                             ##
    pktimebase*: AVRational  ## *
                            ##  AVCodecDescriptor
                            ##  - encoding: unused.
                            ##  - decoding: set by libavcodec.
                            ##
    codec_descriptor*: ptr AVCodecDescriptor
    when not FF_API_LOWRES:
      ## *
      ##  low resolution decoding, 1-> 1/2 size, 2->1/4 size
      ##  - encoding: unused
      ##  - decoding: Set by user.
      ##
      lowres*: cint
    pts_correction_num_faulty_pts*: int64 ## / Number of incorrect PTS values so far
    pts_correction_num_faulty_dts*: int64 ## / Number of incorrect DTS values so far
    pts_correction_last_pts*: int64 ## / PTS of the last frame
    pts_correction_last_dts*: int64 ## / DTS of the last frame
                                    ## *
                                    ##  Character encoding of the input subtitles file.
                                    ##  - decoding: set by user
                                    ##  - encoding: unused
                                    ##
    sub_charenc*: cstring ## *
                        ##  Subtitles character encoding mode. Formats or codecs might be adjusting
                        ##  this setting (if they are doing the conversion themselves for instance).
                        ##  - decoding: set by libavcodec
                        ##  - encoding: unused
                        ##
    sub_charenc_mode*: cint
    skip_alpha*: cint          ## *
                    ##  Number of samples to skip after a discontinuity
                    ##  - decoding: unused
                    ##  - encoding: set by libavcodec
                    ##
    seek_preroll*: cint
    when not FF_API_DEBUG_MV:
      ## *
      ##  debug motion vectors
      ##  - encoding: Set by user.
      ##  - decoding: Set by user.
      ##
      debug_mv*: cint
    chroma_intra_matrix*: ptr uint16 ## *
                                    ##  dump format separator.
                                    ##  can be ", " or "\n      " or anything else
                                    ##  - encoding: Set by user.
                                    ##  - decoding: Set by user.
                                    ##
    dump_separator*: ptr uint8 ## *
                              ##  ',' separated list of allowed decoders.
                              ##  If NULL then all are allowed
                              ##  - encoding: unused
                              ##  - decoding: set by user
                              ##
    codec_whitelist*: cstring  ## *
                            ##  Properties of the stream that gets decoded
                            ##  - encoding: unused
                            ##  - decoding: set by libavcodec
                            ##
    properties*: cuint
    coded_side_data*: ptr AVPacketSideData
    nb_coded_side_data*: cint ## *
                            ##  A reference to the AVHWFramesContext describing the input (for encoding)
                            ##  or output (decoding) frames. The reference is set by the caller and
                            ##  afterwards owned (and freed) by libavcodec - it should never be read by
                            ##  the caller after being set.
                            ##
                            ##  - decoding: This field should be set by the caller from the get_format()
                            ##              callback. The previous reference (if any) will always be
                            ##              unreffed by libavcodec before the get_format() call.
                            ##
                            ##              If the default get_buffer2() is used with a hwaccel pixel
                            ##              format, then this AVHWFramesContext will be used for
                            ##              allocating the frame buffers.
                            ##
                            ##  - encoding: For hardware encoders configured to use a hwaccel pixel
                            ##              format, this field should be set by the caller to a reference
                            ##              to the AVHWFramesContext describing input frames.
                            ##              AVHWFramesContext.format must be equal to
                            ##              AVCodecContext.pix_fmt.
                            ##
                            ##              This field should be set before avcodec_open2() is called.
                            ##
    hw_frames_ctx*: ptr AVBufferRef ## *
                                 ##  Control the form of AVSubtitle.rects[N]->ass
                                 ##  - decoding: set by user
                                 ##  - encoding: unused
                                 ##
    subext_format*: cint
    trailing_padding*: cint ## *
                          ##  The number of pixels per image to maximally accept.
                          ##
                          ##  - decoding: set by user
                          ##  - encoding: set by user
                          ##
    max_pixels*: int64 ## *
                       ##  A reference to the AVHWDeviceContext describing the device which will
                       ##  be used by a hardware encoder/decoder.  The reference is set by the
                       ##  caller and afterwards owned (and freed) by libavcodec.
                       ##
                       ##  This should be used if either the codec device does not require
                       ##  hardware frames or any that are used are to be allocated internally by
                       ##  libavcodec.  If the user wishes to supply any of the frames used as
                       ##  encoder input or decoder output then hw_frames_ctx should be used
                       ##  instead.  When hw_frames_ctx is set in get_format() for a decoder, this
                       ##  field will be ignored while decoding the associated stream segment, but
                       ##  may again be used on a following one after another get_format() call.
                       ##
                       ##  For both encoders and decoders this field should be set before
                       ##  avcodec_open2() is called and must not be written to thereafter.
                       ##
                       ##  Note that some decoders may require this field to be set initially in
                       ##  order to support hw_frames_ctx at all - in that case, all frames
                       ##  contexts used must be created on the same device.
                       ##
    hw_device_ctx*: ptr AVBufferRef ## *
                                 ##  Bit set of AV_HWACCEL_FLAG_* flags, which affect hardware accelerated
                                 ##  decoding (if active).
                                 ##  - encoding: unused
                                 ##  - decoding: Set by user (either before avcodec_open2(), or in the
                                 ##              AVCodecContext.get_format callback)
                                 ##
    hwaccel_flags*: cint ## *
                       ##  Video decoding only. Certain video codecs support cropping, meaning that
                       ##  only a sub-rectangle of the decoded frame is intended for display.  This
                       ##  option controls how cropping is handled by libavcodec.
                       ##
                       ##  When set to 1 (the default), libavcodec will apply cropping internally.
                       ##  I.e. it will modify the output frame width/height fields and offset the
                       ##  data pointers (only by as much as possible while preserving alignment, or
                       ##  by the full amount if the AV_CODEC_FLAG_UNALIGNED flag is set) so that
                       ##  the frames output by the decoder refer only to the cropped area. The
                       ##  crop_* fields of the output frames will be zero.
                       ##
                       ##  When set to 0, the width/height fields of the output frames will be set
                       ##  to the coded dimensions and the crop_* fields will describe the cropping
                       ##  rectangle. Applying the cropping is left to the caller.
                       ##
                       ##  @warning When hardware acceleration with opaque output frames is used,
                       ##  libavcodec is unable to apply cropping from the top/left border.
                       ##
                       ##  @note when this option is set to zero, the width/height fields of the
                       ##  AVCodecContext and output AVFrames have different meanings. The codec
                       ##  context fields store display dimensions (with the coded dimensions in
                       ##  coded_width/height), while the frame fields store the coded dimensions
                       ##  (with the display dimensions being determined by the crop_* fields).
                       ##
    apply_cropping*: cint ##
                        ##  Video decoding only.  Sets the number of extra hardware frames which
                        ##  the decoder will allocate for use by the caller.  This must be set
                        ##  before avcodec_open2() is called.
                        ##
                        ##  Some hardware decoders require all frames that they will use for
                        ##  output to be defined in advance before decoding starts.  For such
                        ##  decoders, the hardware frame pool must therefore be of a fixed size.
                        ##  The extra frames set here are on top of any number that the decoder
                        ##  needs internally in order to operate normally (for example, frames
                        ##  used as reference pictures).
                        ##
    extra_hw_frames*: cint ## *
                         ##  The percentage of damaged samples to discard a frame.
                         ##
                         ##  - decoding: set by user
                         ##  - encoding: unused
                         ##
    discard_damaged_percentage*: cint ## *
                                    ##  The number of samples per frame to maximally accept.
                                    ##
                                    ##  - decoding: set by user
                                    ##  - encoding: set by user
                                    ##
    max_samples*: int64

  AVCodecParameters* {.avcodec.} = object
    codec_type*: AVMediaType   ## *
                           ##  General type of the encoded data.
                           ##
    ## *
    ##  Specific type of the encoded data (the codec used).
    ##
    codec_id*: AVCodecID ## *
                       ##  Additional information about the codec (corresponds to the AVI FOURCC).
                       ##
    codecag*: uint32 ## *
                       ##  Extra binary data needed for initializing the decoder, codec-dependent.
                       ##
                       ##  Must be allocated with av_malloc() and will be freed by
                       ##  avcodec_parameters_free(). The allocated size of extradata must be at
                       ##  least extradata_size + AV_INPUT_BUFFER_PADDING_SIZE, with the padding
                       ##  bytes zeroed.
                       ##
    extradata*: ptr uint8     ## *
                         ##  Size of the extradata content in bytes.
                         ##
    extradata_size*: cint ## *
                        ##  - video: the pixel format, the value corresponds to enum AVPixelFormat.
                        ##  - audio: the sample format, the value corresponds to enum AVSampleFormat.
                        ##
    format*: cint ## *
                ##  The average bitrate of the encoded data (in bits per second).
                ##
    bit_rate*: int64 ## *
                     ##  The number of bits per sample in the codedwords.
                     ##
                     ##  This is basically the bitrate per sample. It is mandatory for a bunch of
                     ##  formats to actually decode them. It's the number of bits for one sample in
                     ##  the actual coded bitstream.
                     ##
                     ##  This could be for example 4 for ADPCM
                     ##  For PCM formats this matches bits_per_raw_sample
                     ##  Can be 0
                     ##
    bits_per_coded_sample*: cint ## *
                               ##  This is the number of valid bits in each output sample. If the
                               ##  sample format has more bits, the least significant bits are additional
                               ##  padding bits, which are always 0. Use right shifts to reduce the sample
                               ##  to its actual size. For example, audio formats with 24 bit samples will
                               ##  have bits_per_raw_sample set to 24, and format set to AV_SAMPLE_FMT_S32.
                               ##  To get the original sample use "(int32)sample >> 8"."
                               ##
                               ##  For ADPCM this might be 12 or 16 or similar
                               ##  Can be 0
                               ##
    bits_per_raw_sample*: cint ## *
                             ##  Codec-specific bitstream restrictions that the stream conforms to.
                             ##
    profile*: cint
    level*: cint ## *
               ##  Video only. The dimensions of the video frame in pixels.
               ##
    width*: cint
    height*: cint ## *
                ##  Video only. The aspect ratio (width / height) which a single pixel
                ##  should have when displayed.
                ##
                ##  When the aspect ratio is unknown / undefined, the numerator should be
                ##  set to 0 (the denominator may have any value).
                ##
    sample_aspect_ratio*: AVRational ## *
                                   ##  Video only. The order of the fields in interlaced video.
                                   ##
    field_order*: AVFieldOrder ## *
                             ##  Video only. Additional colorspace characteristics.
                             ##
    color_range*: AVColorRange
    color_primaries*: AVColorPrimaries
    colorrc*: AVColorTransferCharacteristic
    color_space*: AVColorSpace
    chroma_location*: AVChromaLocation ## *
                                     ##  Video only. Number of delayed frames.
                                     ##
    video_delay*: cint ## *
                     ##  Audio only. The channel layout bitmask. May be 0 if the channel layout is
                     ##  unknown or unspecified, otherwise the number of bits set must be equal to
                     ##  the channels field.
                     ##
    channel_layout*: uint64  ## *
                            ##  Audio only. The number of audio channels.
                            ##
    channels*: cint ## *
                  ##  Audio only. The number of audio samples per second.
                  ##
    sample_rate*: cint ## *
                     ##  Audio only. The number of bytes per coded audio frame, required by some
                     ##  formats.
                     ##
                     ##  Corresponds to nBlockAlign in WAVEFORMATEX.
                     ##
    block_align*: cint ## *
                     ##  Audio only. Audio frame size, if known. Required by some formats to be static.
                     ##
    frame_size*: cint ## *
                    ##  Audio only. The amount of padding (in samples) inserted by the encoder at
                    ##  the beginning of the audio. I.e. this number of leading decoded samples
                    ##  must be discarded by the caller to get the original audio without leading
                    ##  padding.
                    ##
    initial_padding*: cint ## *
                         ##  Audio only. The amount of padding (in samples) appended by the encoder to
                         ##  the end of the audio. I.e. this number of decoded samples must be
                         ##  discarded by the caller from the end of the stream to get the original
                         ##  audio without any trailing padding.
                         ##
    trailing_padding*: cint ## *
                          ##  Audio only. Number of samples to skip after a discontinuity.
                          ##
    seek_preroll*: cint

  AVCodecParserContext* {.avcodec.}  = object
    priv_data*: pointer
    parser*: ptr AVCodecParser
    frame_offset*: int64     ##  offset of the current frame
    cur_offset*: int64       ##  current offset
                       ##                            (incremented by each av_parser_parse())
    next_frame_offset*: int64 ##  offset of the next frame
                              ##  video info
    pictype*: cint ##  XXX: Put it back in AVCodecContext.
                   ## *
                   ##  This field is used for proper frame duration computation in lavf.
                   ##  It signals, how much longer the frame duration of the current frame
                   ##  is compared to normal frame duration.
                   ##
                   ##  frame_duration = (1 + repeat_pict) * time_base
                   ##
                   ##  It is used by codecs like H.264 to display telecined material.
                   ##
    repeat_pict*: cint         ##  XXX: Put it back in AVCodecContext.
    pts*: int64              ##  pts of the current frame
    dts*: int64              ##  dts of the current frame
                ##  private data
    last_pts*: int64
    last_dts*: int64
    fetchimestamp*: cint
    cur_frame_start_index*: cint
    cur_frame_offset*: array[AV_PARSER_PTS_NB, int64]
    cur_frame_pts*: array[AV_PARSER_PTS_NB, int64]
    cur_frame_dts*: array[AV_PARSER_PTS_NB, int64]
    flags*: cint
    offset*: int64           ## /< byte offset from starting packet start
    cur_frame_end*: array[AV_PARSER_PTS_NB, int64] ## *
                                                  ##  Set by parser to 1 for key frames and 0 for non-key frames.
                                                  ##  It is initialized to -1, so if the parser doesn't set this flag,
                                                  ##  old-style fallback using AV_PICTURE_TYPE_I picture type as key frames
                                                  ##  will be used.
                                                  ##
    key_frame*: cint
    when FF_API_CONVERGENCE_DURATION:
      ## *
      ##  @deprecated unused
      ##
      ## attribute_deprecated
      convergence_duration*: int64
    dts_sync_point*: cint ## *
                        ##  Offset of the current timestamp against last timestamp sync point in
                        ##  units of AVCodecContext.time_base.
                        ##
                        ##  Set to INT_MIN when dts_sync_point unused. Otherwise, it must
                        ##  contain a valid timestamp offset.
                        ##
                        ##  Note that the timestamp of sync point has usually a nonzero
                        ##  dts_ref_dts_delta, which refers to the previous sync point. Offset of
                        ##  the next frame after timestamp sync point will be usually 1.
                        ##
                        ##  For example, this corresponds to H.264 cpb_removal_delay.
                        ##
    dts_ref_dts_delta*: cint ## *
                           ##  Presentation delay of current frame in units of AVCodecContext.time_base.
                           ##
                           ##  Set to INT_MIN when dts_sync_point unused. Otherwise, it must
                           ##  contain valid non-negative timestamp delta (presentation time of a frame
                           ##  must not lie in the past).
                           ##
                           ##  This delay represents the difference between decoding and presentation
                           ##  time of the frame.
                           ##
                           ##  For example, this corresponds to H.264 dpb_output_delay.
                           ##
    pts_dts_delta*: cint       ## *
                       ##  Position of the packet in file.
                       ##
                       ##  Analogous to cur_frame_pts/dts
                       ##
    cur_frame_pos*: array[AV_PARSER_PTS_NB, int64] ## *
                                                  ##  Byte position of currently parsed frame in stream.
                                                  ##
    pos*: int64              ## *
                ##  Previous frame byte position.
                ##
    last_pos*: int64 ## *
                     ##  Duration of the current frame.
                     ##  For audio, this is in units of 1 / AVCodecContext.sample_rate.
                     ##  For all other types, this is in units of AVCodecContext.time_base.
                     ##
    duration*: cint
    field_order*: AVFieldOrder ## *
                             ##  Indicate whether a picture is coded as a frame, top field or bottom field.
                             ##
                             ##  For example, H.264 field_pic_flag equal to 0 corresponds to
                             ##  AV_PICTURE_STRUCTURE_FRAME. An H.264 picture with field_pic_flag
                             ##  equal to 1 and bottom_field_flag equal to 0 corresponds to
                             ##  AV_PICTURE_STRUCTURE_TOP_FIELD.
                             ##
    picture_structure*: AVPictureStructure ## *
                                         ##  Picture number incremented in presentation or output order.
                                         ##  This field may be reinitialized at the first picture of a new sequence.
                                         ##
                                         ##  For example, this corresponds to H.264 PicOrderCnt.
                                         ##
    output_picture_number*: cint ## *
                               ##  Dimensions of the decoded video intended for presentation.
                               ##
    width*: cint
    height*: cint              ## *
                ##  Dimensions of the coded video.
                ##
    coded_width*: cint
    coded_height*: cint ## *
                      ##  The format of the coded data, corresponds to enum AVPixelFormat for video
                      ##  and for enum AVSampleFormat for audio.
                      ##
                      ##  Note that a decoder can have considerable freedom in how exactly it
                      ##  decodes the data, so the format reported here might be different from the
                      ##  one returned by a decoder.
                      ##
    format*: cint

  AVCodecParser* {.avcodec.}  = object
    codec_ids*: array[5, cint]  ##  several codec IDs are permitted
    priv_data_size*: cint
    parser_init*: proc (s: ptr AVCodecParserContext): cint ##  This callback never returns an error, a negative value means that
                                                     ##  the frame start was in a previous packet.
    parser_parse*: proc (s: ptr AVCodecParserContext; avctx: ptr AVCodecContext;
                       poutbuf: ptr ptr uint8; poutbuf_size: ptr cint;
                       buf: ptr uint8; buf_size: cint): cint
    parser_close*: proc (s: ptr AVCodecParserContext)
    split*: proc (avctx: ptr AVCodecContext; buf: ptr uint8; buf_size: cint): cint
    next*: ptr AVCodecParser

  AVIndexEntry* {.avformat.} = object
    pos*: int64
    timestamp*: int64 ## *<
                      ##  Timestamp in AVStream.time_base units, preferably the time from which on correctly decoded frames are available
                      ##  when seeking to this entry. That means preferable PTS on keyframe based formats.
                      ##  But demuxers can choose to store a different timestamp, if it is more convenient for the implementation or nothing better
                      ##  is known
                      ##
    flags* {.bitsize: 2.}: cint
    size* {.bitsize: 30.}: cint  ## Yeah, trying to keep the size of this small to reduce memory requirements (it is 24 vs. 32 bytes due to possible 8-byte alignment).
    min_distance*: cint        ## *< Minimum distance between this and the previous keyframe, used to avoid unneeded searching.

  AVStreamInternal* {.avformat.} = object

  AVStream* {.avformat.} = object
    index*: cint ## *< stream index in AVFormatContext
               ## *
               ##  Format-specific stream ID.
               ##  decoding: set by libavformat
               ##  encoding: set by the user, replaced by libavformat if left unset
               ##
    id*: cint
    when FF_API_LAVF_AVCTX:
      ## *
      ##  @deprecated use the codecpar struct instead
      ##
      codec*: ptr AVCodecContext
    priv_data*: pointer ## *
                      ##  This is the fundamental unit of time (in seconds) in terms
                      ##  of which frame timestamps are represented.
                      ##
                      ##  decoding: set by libavformat
                      ##  encoding: May be set by the caller before avformat_write_header() to
                      ##            provide a hint to the muxer about the desired timebase. In
                      ##            avformat_write_header(), the muxer will overwrite this field
                      ##            with the timebase that will actually be used for the timestamps
                      ##            written into the file (which may or may not be related to the
                      ##            user-provided one, depending on the format).
                      ##
    time_base*: AVRational ## *
                         ##  Decoding: pts of the first frame of the stream in presentation order, in stream time base.
                         ##  Only set this if you are absolutely 100% sure that the value you set
                         ##  it to really is the pts of the first frame.
                         ##  This may be undefined (AV_NOPTS_VALUE).
                         ##  @note The ASF header does NOT contain a correct startime the ASF
                         ##  demuxer must NOT set this.
                         ##
    start_time*: int64 ## *
                       ##  Decoding: duration of the stream, in stream time base.
                       ##  If a source file does not specify a duration, but does specify
                       ##  a bitrate, this value will be estimated from bitrate and file size.
                       ##
                       ##  Encoding: May be set by the caller before avformat_write_header() to
                       ##  provide a hint to the muxer about the estimated duration.
                       ##
    duration*: int64
    nb_frames*: int64        ## /< number of frames in this stream if known or 0
    disposition*: cint         ## *< AV_DISPOSITION_* bit field
    `discard`*: AVDiscard ## /< Selects which packets can be discarded at will and do not need to be demuxed.
                        ## *
                        ##  sample aspect ratio (0 if unknown)
                        ##  - encoding: Set by user.
                        ##  - decoding: Set by libavformat.
                        ##
    sample_aspect_ratio*: AVRational
    metadata*: ptr AVDictionary ## *
                             ##  Average framerate
                             ##
                             ##  - demuxing: May be set by libavformat when creating the stream or in
                             ##              avformat_find_stream_info().
                             ##  - muxing: May be set by the caller before avformat_write_header().
                             ##
    avg_frame_rate*: AVRational ## *
                              ##  For streams with AV_DISPOSITION_ATTACHED_PIC disposition, this packet
                              ##  will contain the attached picture.
                              ##
                              ##  decoding: set by libavformat, must not be modified by the caller.
                              ##  encoding: unused
                              ##
    attached_pic*: AVPacket ## *
                          ##  An array of side data that applies to the whole stream (i.e. the
                          ##  container does not allow it to change between packets).
                          ##
                          ##  There may be no overlap between the side data in this array and side data
                          ##  in the packets. I.e. a given side data is either exported by the muxer
                          ##  (demuxing) / set by the caller (muxing) in this array, then it never
                          ##  appears in the packets, or the side data is exported / sent through
                          ##  the packets (always in the first packet where the value becomes known or
                          ##  changes), then it does not appear in this array.
                          ##
                          ##  - demuxing: Set by libavformat when the stream is created.
                          ##  - muxing: May be set by the caller before avformat_write_header().
                          ##
                          ##  Freed by libavformat in avformat_free_context().
                          ##
                          ##  @see av_format_inject_global_side_data()
                          ##
    side_data*: ptr AVPacketSideData ## *
                                  ##  The number of elements in the AVStream.side_data array.
                                  ##
    nb_side_data*: cint ## *
                      ##  Flags for the user to detect events happening on the stream. Flags must
                      ##  be cleared by the user once the event has been handled.
                      ##  A combination of AVSTREAM_EVENT_FLAG_*.
                      ##
    event_flags*: cint
    r_frame_rate*: AVRational ## *
                            ##  Real base framerate of the stream.
                            ##  This is the lowest framerate with which all timestamps can be
                            ##  represented accurately (it is the least common multiple of all
                            ##  framerates in the stream). Note, this value is just a guess!
                            ##  For example, if the time base is 1/90000 and all frames have either
                            ##  approximately 3600 or 1800 timer ticks, then r_frame_rate will be 50/1.
                            ##
    when FF_API_LAVF_FFSERVER:
      ## *
      ##  String containing pairs of key and values describing recommended encoder configuration.
      ##  Pairs are separated by ','.
      ##  Keys are separated from values by '='.
      ##
      ##  @deprecated unused
      ##
      recommended_encoder_configuration*: cstring
    codecpar*: ptr AVCodecParameters ## *
                                  ##  Codec parameters associated with this stream. Allocated and freed by
                                  ##  libavformat in avformat_new_stream() and avformat_free_context()
                                  ##  respectively.
                                  ##
                                  ##  - demuxing: filled by libavformat on stream creation or in
                                  ##              avformat_find_stream_info()
                                  ##  - muxing: filled by the caller before avformat_write_header()
                                  ##
                                  ## ****************************************************************
                                  ##  All fields below this line are not part of the public API. They
                                  ##  may not be used outside of libavformat and can be changed and
                                  ##  removed at will.
                                  ##  Internal note: be aware that physically removing these fields
                                  ##  will break ABI. Replace removed fields with dummy fields, and
                                  ##  add new fields to AVStreamInternal.
                                  ## ****************************************************************
                                  ##
                                  ## *
                                  ##  Stream information used internally by avformat_find_stream_info()
                                  ##
    info*: ptr INNER_C_STRUCT_avformat_1031
    pts_wrap_bits*: cint ## *< number of bits in pts (used for wrapping control)
                       ##  Timestamp generation support:
                       ## *
                       ##  Timestamp corresponding to the last dts sync point.
                       ##
                       ##  Initialized when AVCodecParserContext.dts_sync_point >= 0 and
                       ##  a DTS is received from the underlying container. Otherwise set to
                       ##  AV_NOPTS_VALUE by default.
                       ##
    first_dts*: int64
    cur_dts*: int64
    last_IP_pts*: int64
    last_IP_duration*: cint    ## *
                          ##  Number of packets to buffer for codec probing
                          ##
    probe_packets*: cint ## *
                       ##  Number of frames that have been demuxed during avformat_find_stream_info()
                       ##
    codec_info_nb_frames*: cint ##  av_read_frame() support
    need_parsing*: AVStreamParseType
    parser*: ptr AVCodecParserContext ## *
                                   ##  last packet in packet_buffer for this stream when muxing.
                                   ##
    last_in_packet_buffer*: ptr AVPacketList
    probe_data*: AVProbeData
    pts_buffer*: array[MAX_REORDER_DELAY + 1, int64]
    index_entries*: ptr AVIndexEntry ## *< Only used if the format does not
                                  ##                                     support seeking natively.
    nb_index_entries*: cint
    index_entries_allocated_size*: cuint ## *
                                       ##  Stream Identifier
                                       ##  This is the MPEG-TS stream identifier +1
                                       ##  0 means unknown
                                       ##
    stream_identifier*: cint ## *
                           ##  Details of the MPEG-TS program which created this stream.
                           ##
    program_num*: cint
    pmt_version*: cint
    pmt_stream_idx*: cint
    interleaver_chunk_size*: int64
    interleaver_chunk_duration*: int64 ## *
                                       ##  stream probing state
                                       ##  -1   -> probing finished
                                       ##   0   -> no probing requested
                                       ##  rest -> perform probing with request_probe being the minimum score to accept.
                                       ##  NOT PART OF PUBLIC API
                                       ##
    request_probe*: cint       ## *
                       ##  Indicates that everything up to the next keyframe
                       ##  should be discarded.
                       ##
    skip_to_keyframe*: cint ## *
                          ##  Number of samples to skip at the start of the frame decoded from the next packet.
                          ##
    skip_samples*: cint ## *
                      ##  If not 0, the number of samples that should be skipped from the start of
                      ##  the stream (the samples are removed from packets with pts==0, which also
                      ##  assumes negative timestamps do not happen).
                      ##  Intended for use with formats such as mp3 with ad-hoc gapless audio
                      ##  support.
                      ##
    start_skip_samples*: int64 ## *
                               ##  If not 0, the first audio sample that should be discarded from the stream.
                               ##  This is broken by design (needs global sample count), but can't be
                               ##  avoided for broken by design formats such as mp3 with ad-hoc gapless
                               ##  audio support.
                               ##
    first_discard_sample*: int64 ## *
                                 ##  The sample after last sample that is intended to be discarded after
                                 ##  first_discard_sample. Works on frame boundaries only. Used to prevent
                                 ##  early EOF if the gapless info is broken (considered concatenated mp3s).
                                 ##
    last_discard_sample*: int64 ## *
                                ##  Number of internally decoded frames, used internally in libavformat, do not access
                                ##  its lifetime differs from info which is why it is not in that structure.
                                ##
    nb_decoded_frames*: cint ## *
                           ##  Timestamp offset added to timestamps before muxing
                           ##  NOT PART OF PUBLIC API
                           ##
    muxs_offset*: int64 ## *
                          ##  Internal data to check for wrapping of the time stamp
                          ##
    pts_wrap_reference*: int64 ## *
                               ##  Options for behavior, when a wrap is detected.
                               ##
                               ##  Defined by AV_PTS_WRAP_ values.
                               ##
                               ##  If correction is enabled, there are two possibilities:
                               ##  If the first time stamp is near the wrap point, the wrap offset
                               ##  will be subtracted, which will create negative time stamps.
                               ##  Otherwise the offset will be added.
                               ##
    pts_wrap_behavior*: cint ## *
                           ##  Internal data to prevent doing update_initial_durations() twice
                           ##
    update_initial_durations_done*: cint ## *
                                       ##  Internal data to generate dts from pts
                                       ##
    pts_reorder_error*: array[MAX_REORDER_DELAY + 1, int64]
    pts_reorder_error_count*: array[MAX_REORDER_DELAY + 1, uint8] ## *
                                                               ##  Internal data to analyze DTS and detect faulty mpeg streams
                                                               ##
    last_dts_for_order_check*: int64
    dts_ordered*: uint8
    dts_misordered*: uint8   ## *
                           ##  Internal data to inject global side data
                           ##
    inject_global_side_data*: cint ## *
                                 ##  display aspect ratio (0 if unknown)
                                 ##  - encoding: unused
                                 ##  - decoding: Set by libavformat to calculate sample_aspect_ratio internally
                                 ##
    display_aspect_ratio*: AVRational ## *
                                    ##  An opaque field for libavformat internal usage.
                                    ##  Must not be accessed in any way by callers.
                                    ##
    internal*: ptr AVStreamInternal

  AVIOInterruptCB* {.avio.} = object
    callback*: proc (a1: pointer): cint
    opaque*: pointer

  AVFormatInternal* {.avformat.}  = object
  AVProgram* {.avformat.} = object
    id*: cint
    flags*: cint
    `discard`*: AVDiscard      ## /< selects which program to discard and which to feed to the caller
    stream_index*: ptr cuint
    nb_stream_indexes*: cuint
    metadata*: ptr AVDictionary
    program_num*: cint
    pmt_pid*: cint
    pcr_pid*: cint
    pmt_version*: cint ## ****************************************************************
                     ##  All fields below this line are not part of the public API. They
                     ##  may not be used outside of libavformat and can be changed and
                     ##  removed at will.
                     ##  New public fields should be added right above.
                     ## ****************************************************************
                     ##
    startime*: int64
    endime*: int64
    pts_wrap_reference*: int64 ## /< reference dts for wrap detection
    pts_wrap_behavior*: cint   ## /< behavior on wrap detection

  AVChapter* {.avformat.} = object
    id*: cint                  ## /< unique ID to identify the chapter
    time_base*: AVRational     ## /< time base in which the start/end timestamps are specified
    start*: int64
    `end`*: int64            ## /< chapter start/end time in time_base units
    metadata*: ptr AVDictionary

  av_format_control_message* {.avformat.} = proc (s: ptr AVFormatContext; `type`: cint;
                                  data: pointer; data_size: csize): cint
  AVOpenCallback* {.avformat.} = proc (s: ptr AVFormatContext; pb: ptr ptr AVIOContext; url: cstring;
                       flags: cint; int_cb: ptr AVIOInterruptCB;
                       options: ptr ptr AVDictionary): cint

  AVDurationEstimationMethod* {.avformat.} = enum
    AVFMT_DURATION_FROM_PTS,  ## /< Duration accurately estimated from PTSes
    AVFMT_DURATION_FROM_STREAM, ## /< Duration estimated from a stream with a known duration
    AVFMT_DURATION_FROM_BITRATE ## /< Duration estimated from bitrate (less accurate)

  AVFormatContext* {.avformat.} = object
    av_class*: ptr AVClass ## *
                        ##  A class for logging and @ref avoptions. Set by avformat_alloc_context().
                        ##  Exports (de)muxer private options if they exist.
                        ##
    ## *
    ##  The input container format.
    ##
    ##  Demuxing only, set by avformat_open_input().
    ##
    iformat*: ptr AVInputFormat ## *
                             ##  The output container format.
                             ##
                             ##  Muxing only, must be set by the caller before avformat_write_header().
                             ##
    oformat*: ptr AVOutputFormat ## *
                              ##  Format private data. This is an AVOptions-enabled struct
                              ##  if and only if iformat/oformat.priv_class is not NULL.
                              ##
                              ##  - muxing: set by avformat_write_header()
                              ##  - demuxing: set by avformat_open_input()
                              ##
    priv_data*: pointer ## *
                      ##  I/O context.
                      ##
                      ##  - demuxing: either set by the user before avformat_open_input() (then
                      ##              the user must close it manually) or set by avformat_open_input().
                      ##  - muxing: set by the user before avformat_write_header(). The caller must
                      ##            take care of closing / freeing the IO context.
                      ##
                      ##  Do NOT set this field if AVFMT_NOFILE flag is set in
                      ##  iformat/oformat.flags. In such a case, the (de)muxer will handle
                      ##  I/O in some other way and this field will be NULL.
                      ##
    pb*: ptr AVIOContext ##  stream info
                      ## *
                      ##  Flags signalling stream properties. A combination of AVFMTCTX_*.
                      ##  Set by libavformat.
                      ##
    ctx_flags*: cint ## *
                   ##  Number of elements in AVFormatContext.streams.
                   ##
                   ##  Set by avformat_new_stream(), must not be modified by any other code.
                   ##
    nb_streams*: cuint ## *
                     ##  A list of all streams in the file. New streams are created with
                     ##  avformat_new_stream().
                     ##
                     ##  - demuxing: streams are created by libavformat in avformat_open_input().
                     ##              If AVFMTCTX_NOHEADER is set in ctx_flags, then new streams may also
                     ##              appear in av_read_frame().
                     ##  - muxing: streams are created by the user before avformat_write_header().
                     ##
                     ##  Freed by libavformat in avformat_free_context().
                     ##
    streams*: ptr ptr AVStream
    when FF_API_FORMAT_FILENAME:
      ## *
      ##  input or output filename
      ##
      ##  - demuxing: set by avformat_open_input()
      ##  - muxing: may be set by the caller before avformat_write_header()
      ##
      ##  @deprecated Use url instead.
      ##
      filename*: array[1024, char]
    url*: cstring ## *
                ##  input or output URL. Unlike the old filename field, this field has no
                ##  length restriction.
                ##
                ##  - demuxing: set by avformat_open_input(), initialized to an empty
                ##              string if url parameter was NULL in avformat_open_input().
                ##  - muxing: may be set by the caller before calling avformat_write_header()
                ##            (or avformat_init_output() if that is called first) to a string
                ##            which is freeable by av_free(). Set to an empty string if it
                ##            was NULL in avformat_init_output().
                ##
                ##  Freed by libavformat in avformat_free_context().
                ##
                ## *
                ##  Position of the first frame of the component, in
                ##  AV_TIME_BASE fractional seconds. NEVER set this value directly:
                ##  It is deduced from the AVStream values.
                ##
                ##  Demuxing only, set by libavformat.
                ##
    startime*: int64 ## *
                       ##  Duration of the stream, in AV_TIME_BASE fractional
                       ##  seconds. Only set this value if you know none of the individual stream
                       ##  durations and also do not set any of them. This is deduced from the
                       ##  AVStream values if not set.
                       ##
                       ##  Demuxing only, set by libavformat.
                       ##
    duration*: int64 ## *
                     ##  Total stream bitrate in bit/s, 0 if not
                     ##  available. Never set it directly if the file_size and the
                     ##  duration are known as FFmpeg can compute it automatically.
                     ##
    bit_rate*: int64
    packet_size*: cuint
    max_delay*: cint ## *
                   ##  Flags modifying the (de)muxer behaviour. A combination of AVFMT_FLAG_*.
                   ##  Set by the user before avformat_open_input() / avformat_write_header().
                   ##
    flags*: cint
    probesize*: int64 ## *
                      ##  Maximum size of the data read from input for determining
                      ##  the input container format.
                      ##  Demuxing only, set by the caller before avformat_open_input().
                      ##
                      ## *
                      ##  Maximum duration (in AV_TIME_BASE units) of the data read
                      ##  from input in avformat_find_stream_info().
                      ##  Demuxing only, set by the caller before avformat_find_stream_info().
                      ##  Can be set to 0 to let avformat choose using a heuristic.
                      ##
    max_analyze_duration*: int64
    key*: ptr uint8
    keylen*: cint
    nb_programs*: cuint
    programs*: ptr ptr AVProgram ## *
                             ##  Forced video codec_id.
                             ##  Demuxing: Set by user.
                             ##
    video_codec_id*: AVCodecID ## *
                             ##  Forced audio codec_id.
                             ##  Demuxing: Set by user.
                             ##
    audio_codec_id*: AVCodecID ## *
                             ##  Forced subtitle codec_id.
                             ##  Demuxing: Set by user.
                             ##
    subtitle_codec_id*: AVCodecID ## *
                                ##  Maximum amount of memory in bytes to use for the index of each stream.
                                ##  If the index exceeds this size, entries will be discarded as
                                ##  needed to maintain a smaller size. This can lead to slower or less
                                ##  accurate seeking (depends on demuxer).
                                ##  Demuxers for which a full in-memory index is mandatory will ignore
                                ##  this.
                                ##  - muxing: unused
                                ##  - demuxing: set by user
                                ##
    max_index_size*: cuint ## *
                         ##  Maximum amount of memory in bytes to use for buffering frames
                         ##  obtained from realtime capture devices.
                         ##
    max_picture_buffer*: cuint ## *
                             ##  Number of chapters in AVChapter array.
                             ##  When muxing, chapters are normally written in the file header,
                             ##  so nb_chapters should normally be initialized before write_header
                             ##  is called. Some muxers (e.g. mov and mkv) can also write chapters
                             ##  in the trailer.  To write chapters in the trailer, nb_chapters
                             ##  must be zero when write_header is called and non-zero when
                             ##  writerailer is called.
                             ##  - muxing: set by user
                             ##  - demuxing: set by libavformat
                             ##
    nb_chapters*: cuint
    chapters*: ptr ptr AVChapter ## *
                             ##  Metadata that applies to the whole file.
                             ##
                             ##  - demuxing: set by libavformat in avformat_open_input()
                             ##  - muxing: may be set by the caller before avformat_write_header()
                             ##
                             ##  Freed by libavformat in avformat_free_context().
                             ##
    metadata*: ptr AVDictionary ## *
                             ##  Start time of the stream in real world time, in microseconds
                             ##  since the Unix epoch (00:00 1st January 1970). That is, pts=0 in the
                             ##  stream was captured at this real world time.
                             ##  - muxing: Set by the caller before avformat_write_header(). If set to
                             ##            either 0 or AV_NOPTS_VALUE, then the current wall-time will
                             ##            be used.
                             ##  - demuxing: Set by libavformat. AV_NOPTS_VALUE if unknown. Note that
                             ##              the value may become known after some number of frames
                             ##              have been received.
                             ##
    startime_realtime*: int64 ## *
                                ##  The number of frames used for determining the framerate in
                                ##  avformat_find_stream_info().
                                ##  Demuxing only, set by the caller before avformat_find_stream_info().
                                ##
    fps_probe_size*: cint ## *
                        ##  Error recognition; higher values will detect more errors but may
                        ##  misdetect some more or less valid parts as errors.
                        ##  Demuxing only, set by the caller before avformat_open_input().
                        ##
    error_recognition*: cint ## *
                           ##  Custom interrupt callbacks for the I/O layer.
                           ##
                           ##  demuxing: set by the user before avformat_open_input().
                           ##  muxing: set by the user before avformat_write_header()
                           ##  (mainly useful for AVFMT_NOFILE formats). The callback
                           ##  should also be passed to avio_open2() if it's used to
                           ##  open the file.
                           ##
    interrupt_callback*: AVIOInterruptCB ## *
                                       ##  Flags to enable debugging.
                                       ##
    debug*: cint
    max_interleave_delta*: int64 ## *
                                 ##  Maximum buffering duration for interleaving.
                                 ##
                                 ##  To ensure all the streams are interleaved correctly,
                                 ##  av_interleaved_write_frame() will wait until it has at least one packet
                                 ##  for each stream before actually writing any packets to the output file.
                                 ##  When some streams are "sparse" (i.e. there are large gaps between
                                 ##  successive packets), this can result in excessive buffering.
                                 ##
                                 ##  This field specifies the maximum difference between the timestamps of the
                                 ##  first and the last packet in the muxing queue, above which libavformat
                                 ##  will output a packet regardless of whether it has queued a packet for all
                                 ##  the streams.
                                 ##
                                 ##  Muxing only, set by the caller before avformat_write_header().
                                 ##
                                 ## *
                                 ##  Allow non-standard and experimental extension
                                 ##  @see AVCodecContext.strict_std_compliance
                                 ##
    strict_std_compliance*: cint ## *
                               ##  Flags for the user to detect events happening on the file. Flags must
                               ##  be cleared by the user once the event has been handled.
                               ##  A combination of AVFMT_EVENT_FLAG_*.
                               ##
    event_flags*: cint
    maxs_probe*: cint ## *
                      ##  Maximum number of packets to read while waiting for the first timestamp.
                      ##  Decoding only.
                      ##
                      ## *
                      ##  Avoid negative timestamps during muxing.
                      ##  Any value of the AVFMT_AVOID_NEG_TS_* constants.
                      ##  Note, this only works when using av_interleaved_write_frame. (interleave_packet_per_dts is in use)
                      ##  - muxing: Set by user
                      ##  - demuxing: unused
                      ##
    avoid_negatives*: cint
    ts_id*: cint ## *
               ##  Transport stream id.
               ##  This will be moved into demuxer private options. Thus no API/ABI compatibility
               ##
               ## *
               ##  Audio preload in microseconds.
               ##  Note, not all formats support this and unpredictable things may happen if it is used when not supported.
               ##  - encoding: Set by user
               ##  - decoding: unused
               ##
    audio_preload*: cint ## *
                       ##  Max chunk time in microseconds.
                       ##  Note, not all formats support this and unpredictable things may happen if it is used when not supported.
                       ##  - encoding: Set by user
                       ##  - decoding: unused
                       ##
    max_chunk_duration*: cint ## *
                            ##  Max chunk size in bytes
                            ##  Note, not all formats support this and unpredictable things may happen if it is used when not supported.
                            ##  - encoding: Set by user
                            ##  - decoding: unused
                            ##
    max_chunk_size*: cint ## *
                        ##  forces the use of wallclock timestamps as pts/dts of packets
                        ##  This has undefined results in the presence of B frames.
                        ##  - encoding: unused
                        ##  - decoding: Set by user
                        ##
    use_wallclock_asimestamps*: cint ## *
                                     ##  avio flags, used to force AVIO_FLAG_DIRECT.
                                     ##  - encoding: unused
                                     ##  - decoding: Set by user
                                     ##
    avio_flags*: cint ## *
                    ##  The duration field can be estimated through various ways, and this field can be used
                    ##  to know how the duration was estimated.
                    ##  - encoding: unused
                    ##  - decoding: Read by user
                    ##
    duration_estimation_method*: AVDurationEstimationMethod ## *
                                                          ##  Skip initial bytes when opening stream
                                                          ##  - encoding: unused
                                                          ##  - decoding: Set by user
                                                          ##
    skip_initial_bytes*: int64 ## *
                               ##  Correct single timestamp overflows
                               ##  - encoding: unused
                               ##  - decoding: Set by user
                               ##
    corrects_overflow*: cuint ## *
                              ##  Force seeking to any (also non key) frames.
                              ##  - encoding: unused
                              ##  - decoding: Set by user
                              ##
    seek2any*: cint            ## *
                  ##  Flush the I/O context after each packet.
                  ##  - encoding: Set by user
                  ##  - decoding: unused
                  ##
    flush_packets*: cint ## *
                       ##  format probing score.
                       ##  The maximal score is AVPROBE_SCORE_MAX, its set when the demuxer probes
                       ##  the format.
                       ##  - encoding: unused
                       ##  - decoding: set by avformat, read by user
                       ##
    probe_score*: cint ## *
                     ##  number of bytes to read maximally to identify format.
                     ##  - encoding: unused
                     ##  - decoding: set by user
                     ##
    format_probesize*: cint    ## *
                          ##  ',' separated list of allowed decoders.
                          ##  If NULL then all are allowed
                          ##  - encoding: unused
                          ##  - decoding: set by user
                          ##
    codec_whitelist*: cstring  ## *
                            ##  ',' separated list of allowed demuxers.
                            ##  If NULL then all are allowed
                            ##  - encoding: unused
                            ##  - decoding: set by user
                            ##
    format_whitelist*: cstring ## *
                             ##  An opaque field for libavformat internal usage.
                             ##  Must not be accessed in any way by callers.
                             ##
    internal*: ptr AVFormatInternal ## *
                                 ##  IO repositioned flag.
                                 ##  This is set by avformat when the underlaying IO context read pointer
                                 ##  is repositioned, for example when doing byte based seeking.
                                 ##  Demuxers can use the flag to detect such changes.
                                 ##
    io_repositioned*: cint ## *
                         ##  Forced video codec.
                         ##  This allows forcing a specific decoder, even when there are multiple with
                         ##  the same codec_id.
                         ##  Demuxing: Set by user
                         ##
    video_codec*: ptr AVCodec ## *
                           ##  Forced audio codec.
                           ##  This allows forcing a specific decoder, even when there are multiple with
                           ##  the same codec_id.
                           ##  Demuxing: Set by user
                           ##
    audio_codec*: ptr AVCodec ## *
                           ##  Forced subtitle codec.
                           ##  This allows forcing a specific decoder, even when there are multiple with
                           ##  the same codec_id.
                           ##  Demuxing: Set by user
                           ##
    subtitle_codec*: ptr AVCodec ## *
                              ##  Forced data codec.
                              ##  This allows forcing a specific decoder, even when there are multiple with
                              ##  the same codec_id.
                              ##  Demuxing: Set by user
                              ##
    data_codec*: ptr AVCodec ## *
                          ##  Number of bytes to be written as padding in a metadata header.
                          ##  Demuxing: Unused.
                          ##  Muxing: Set by user via av_format_set_metadata_header_padding.
                          ##
    metadata_header_padding*: cint ## *
                                 ##  User data.
                                 ##  This is a place for some private data of the user.
                                 ##
    opaque*: pointer ## *
                   ##  Callback used by devices to communicate with application.
                   ##
    control_message_cb*: av_format_control_message ## *
                                                 ##  Output timestamp offset, in microseconds.
                                                 ##  Muxing: set by user
                                                 ##
    outputs_offset*: int64 ## *
                             ##  dump format separator.
                             ##  can be ", " or "\n      " or anything else
                             ##  - muxing: Set by user.
                             ##  - demuxing: Set by user.
                             ##
    dump_separator*: ptr uint8 ## *
                              ##  Forced Data codec_id.
                              ##  Demuxing: Set by user.
                              ##
    data_codec_id*: AVCodecID
    when FF_API_OLD_OPEN_CALLBACKS:
      ## *
      ##  Called to open further IO contexts when needed for demuxing.
      ##
      ##  This can be set by the user application to perform security checks on
      ##  the URLs before opening them.
      ##  The function should behave like avio_open2(), AVFormatContext is provided
      ##  as contextual information and to reach AVFormatContext.opaque.
      ##
      ##  If NULL then some simple checks are used together with avio_open2().
      ##
      ##  Must not be accessed directly from outside avformat.
      ##  @See av_format_set_open_cb()
      ##
      ##  Demuxing: Set by user.
      ##
      ##  @deprecated Use io_open and io_close.
      ##
      open_cb*: proc (s: ptr AVFormatContext; p: ptr ptr AVIOContext; url: cstring;
                    flags: cint; int_cb: ptr AVIOInterruptCB;
                    options: ptr ptr AVDictionary): cint
    protocol_whitelist*: cstring ## *
                               ##  ',' separated list of allowed protocols.
                               ##  - encoding: unused
                               ##  - decoding: set by user
                               ##
                               ## *
                               ##  A callback for opening new IO streams.
                               ##
                               ##  Whenever a muxer or a demuxer needs to open an IO stream (typically from
                               ##  avformat_open_input() for demuxers, but for certain formats can happen at
                               ##  other times as well), it will call this callback to obtain an IO context.
                               ##
                               ##  @param s the format context
                               ##  @param pb on success, the newly opened IO context should be returned here
                               ##  @param url the url to open
                               ##  @param flags a combination of AVIO_FLAG_*
                               ##  @param options a dictionary of additional options, with the same
                               ##                 semantics as in avio_open2()
                               ##  @return 0 on success, a negative AVERROR code on failure
                               ##
                               ##  @note Certain muxers and demuxers do nesting, i.e. they open one or more
                               ##  additional internal format contexts. Thus the AVFormatContext pointer
                               ##  passed to this callback may be different from the one facing the caller.
                               ##  It will, however, have the same 'opaque' field.
                               ##
    io_open*: proc (s: ptr AVFormatContext; pb: ptr ptr AVIOContext; url: cstring;
                  flags: cint; options: ptr ptr AVDictionary): cint ## *
                                                             ##  A callback for closing the streams opened with AVFormatContext.io_open().
                                                             ##
    io_close*: proc (s: ptr AVFormatContext; pb: ptr AVIOContext) ## *
                                                          ##  ',' separated list of disallowed protocols.
                                                          ##  - encoding: unused
                                                          ##  - decoding: set by user
                                                          ##
    protocol_blacklist*: cstring ## *
                               ##  The maximum number of streams.
                               ##  - encoding: unused
                               ##  - decoding: set by user
                               ##
    max_streams*: cint ## *
                     ##  Skip duration calcuation in estimateimings_from_pts.
                     ##  - encoding: unused
                     ##  - decoding: set by user
                     ##
    skip_estimate_duration_from_pts*: cint ## *
                                         ##  Maximum number of packets that can be probed
                                         ##  - encoding: unused
                                         ##  - decoding: set by user
                                         ##
    max_probe_packets*: cint

  AVDeviceInfo* {.avdevice.} = object
    device_name*: cstring      ## *< device name, format depends on device
    device_description*: cstring ## *< human friendly name

  AVDeviceInfoList* {.avdevice.} = object
    devices*: ptr ptr AVDeviceInfo ## *< list of autodetected devices
    nb_devices*: cint          ## *< number of autodetected devices
    default_device*: cint      ## *< index of default device or -1 if no default


  AVInputFormat* {.avformat.} = object
    name*: cstring ## *
                 ##  A comma separated list of short names for the format. New names
                 ##  may be appended with a minor bump.
                 ##
    ## *
    ##  Descriptive name for the format, meant to be more human-readable
    ##  than name. You should use the NULL_IF_CONFIG_SMALL() macro
    ##  to define it.
    ##
    long_name*: cstring ## *
                      ##  Can use flags: AVFMT_NOFILE, AVFMT_NEEDNUMBER, AVFMT_SHOW_IDS,
                      ##  AVFMT_NOTIMESTAMPS, AVFMT_GENERIC_INDEX, AVFMT_TS_DISCONT, AVFMT_NOBINSEARCH,
                      ##  AVFMT_NOGENSEARCH, AVFMT_NO_BYTE_SEEK, AVFMT_SEEK_TO_PTS.
                      ##
    flags*: cint ## *
               ##  If extensions are defined, then no probe is done. You should
               ##  usually not use extension format guessing because it is not
               ##  reliable enough
               ##
    extensions*: cstring
    codecag*: ptr ptr AVCodecTag
    priv_class*: ptr AVClass ## /< AVClass for the private context
                          ## *
                          ##  Comma-separated list of mime types.
                          ##  It is used check for matching mime types while probing.
                          ##  @see av_probe_input_format2
                          ##
    mimeype*: cstring ## ****************************************************************
                      ##  No fields below this line are part of the public API. They
                      ##  may not be used outside of libavformat and can be changed and
                      ##  removed at will.
                      ##  New public fields should be added right above.
                      ## ****************************************************************
                      ##
    next*: ptr AVInputFormat    ## *
                          ##  Raw demuxers store their codec ID here.
                          ##
    raw_codec_id*: cint ## *
                      ##  Size of private data so that it can be allocated in the wrapper.
                      ##
    priv_data_size*: cint ## *
                        ##  Tell if a given file has a chance of being parsed as this format.
                        ##  The buffer provided is guaranteed to be AVPROBE_PADDING_SIZE bytes
                        ##  big so you do not have to check for that unless you need more.
                        ##
    read_probe*: proc (a1: ptr AVProbeData): cint ## *
                                            ##  Read the format header and initialize the AVFormatContext
                                            ##  structure. Return 0 if OK. 'avformat_new_stream' should be
                                            ##  called to create new streams.
                                            ##
    read_header*: proc (a1: ptr AVFormatContext): cint ## *
                                                 ##  Read one packet and put it in 'pkt'. pts and flags are also
                                                 ##  set. 'avformat_new_stream' can be called only if the flag
                                                 ##  AVFMTCTX_NOHEADER is used and only in the calling thread (not in a
                                                 ##  background thread).
                                                 ##  @return 0 on success, < 0 on error.
                                                 ##          When returning an error, pkt must not have been allocated
                                                 ##          or must be freed before returning
                                                 ##
    read_packet*: proc (a1: ptr AVFormatContext; pkt: ptr AVPacket): cint ## *
                                                                 ##  Close the stream. The AVFormatContext and AVStreams are not
                                                                 ##  freed by this function
                                                                 ##
    read_close*: proc (a1: ptr AVFormatContext): cint ## *
                                                ##  Seek to a given timestamp relative to the frames in
                                                ##  stream component stream_index.
                                                ##  @param stream_index Must not be -1.
                                                ##  @param flags Selects which direction should be preferred if no exact
                                                ##               match is available.
                                                ##  @return >= 0 on success (but not necessarily the new offset)
                                                ##
    read_seek*: proc (a1: ptr AVFormatContext; stream_index: cint; timestamp: int64;
                    flags: cint): cint ## *
                                    ##  Get the next timestamp in stream[stream_index].time_base units.
                                    ##  @return the timestamp or AV_NOPTS_VALUE if an error occurred
                                    ##
    readimestamp*: proc (s: ptr AVFormatContext; stream_index: cint;
                         pos: ptr int64; pos_limit: int64): int64 ## *
                                                                  ##  Start/resume playing - only meaningful if using a network-based format
                                                                  ##  (RTSP).
                                                                  ##
    read_play*: proc (a1: ptr AVFormatContext): cint ## *
                                               ##  Pause playing - only meaningful if using a network-based format
                                               ##  (RTSP).
                                               ##
    read_pause*: proc (a1: ptr AVFormatContext): cint ## *
                                                ##  Seek to timestamp ts.
                                                ##  Seeking will be done so that the point from which all active streams
                                                ##  can be presented successfully will be closest to ts and within min/maxs.
                                                ##  Active streams are all streams that have AVStream.discard < AVDISCARD_ALL.
                                                ##
    read_seek2*: proc (s: ptr AVFormatContext; stream_index: cint; mins: int64;
                     ts: int64; maxs: int64; flags: cint): cint ## *
                                                               ##  Returns device list with it properties.
                                                               ##  @see avdevice_list_devices() for more details.
                                                               ##
    get_device_list*: proc (s: ptr AVFormatContext; device_list: ptr AVDeviceInfoList): cint ## *
                                                                                    ##  Initialize device capabilities submodule.
                                                                                    ##  @see avdevice_capabilities_create() for more details.
                                                                                    ##
    create_device_capabilities*: proc (s: ptr AVFormatContext;
                                     caps: ptr AVDeviceCapabilitiesQuery): cint ## *
                                                                            ##  Free device capabilities submodule.
                                                                            ##  @see avdevice_capabilities_free() for more details.
                                                                            ##
    free_device_capabilities*: proc (s: ptr AVFormatContext;
                                   caps: ptr AVDeviceCapabilitiesQuery): cint

  AVOutputFormat* {.avformat.} = object
    name*: cstring ## *
                 ##  Descriptive name for the format, meant to be more human-readable
                 ##  than name. You should use the NULL_IF_CONFIG_SMALL() macro
                 ##  to define it.
                 ##
    long_name*: cstring
    mimeype*: cstring
    extensions*: cstring       ## *< comma-separated filename extensions
                       ##  output support
    audio_codec*: AVCodecID    ## *< default audio codec
    video_codec*: AVCodecID    ## *< default video codec
    subtitle_codec*: AVCodecID ## *< default subtitle codec
                             ## *
                             ##  can use flags: AVFMT_NOFILE, AVFMT_NEEDNUMBER,
                             ##  AVFMT_GLOBALHEADER, AVFMT_NOTIMESTAMPS, AVFMT_VARIABLE_FPS,
                             ##  AVFMT_NODIMENSIONS, AVFMT_NOSTREAMS, AVFMT_ALLOW_FLUSH,
                             ##  AVFMT_TS_NONSTRICT, AVFMT_TS_NEGATIVE
                             ##
    flags*: cint ## *
               ##  List of supported codec_id-codecag pairs, ordered by "better
               ##  choice first". The arrays are all terminated by AV_CODEC_ID_NONE.
               ##
    codecag*: ptr ptr AVCodecTag
    priv_class*: ptr AVClass ## /< AVClass for the private context
                          ## ****************************************************************
                          ##  No fields below this line are part of the public API. They
                          ##  may not be used outside of libavformat and can be changed and
                          ##  removed at will.
                          ##  New public fields should be added right above.
                          ## ****************************************************************
                          ##
                          ## *
                          ##  The const define is not part of the public API and will
                          ##  be removed without further warning.
                          ##
    next*: ptr AVOutputFormat ## *
                           ##  size of private data so that it can be allocated in the wrapper
                           ##
    priv_data_size*: cint
    write_header*: proc (a1: ptr AVFormatContext): cint ## *
                                                  ##  Write a packet. If AVFMT_ALLOW_FLUSH is set in flags,
                                                  ##  pkt can be NULL in order to flush data buffered in the muxer.
                                                  ##  When flushing, return 0 if there still is more data to flush,
                                                  ##  or 1 if everything was flushed and there is no more buffered
                                                  ##  data.
                                                  ##
    write_packet*: proc (a1: ptr AVFormatContext; pkt: ptr AVPacket): cint
    writerailer*: proc (a1: ptr AVFormatContext): cint ## *
                                                   ##  Currently only used to set pixel format if not YUV420P.
                                                   ##
    interleave_packet*: proc (a1: ptr AVFormatContext; `out`: ptr AVPacket;
                            `in`: ptr AVPacket; flush: cint): cint ## *
                                                             ##  Test if the given codec can be stored in this container.
                                                             ##
                                                             ##  @return 1 if the codec is supported, 0 if it is not.
                                                             ##          A negative number if unknown.
                                                             ##          MKTAG('A', 'P', 'I', 'C') if the codec is only supported as AV_DISPOSITION_ATTACHED_PIC
                                                             ##
    query_codec*: proc (id: AVCodecID; std_compliance: cint): cint
    get_outputimestamp*: proc (s: ptr AVFormatContext; stream: cint;
                               dts: ptr int64; wall: ptr int64) ## *
                                                              ##  Allows sending messages from application to device.
                                                              ##
    control_message*: proc (s: ptr AVFormatContext; `type`: cint; data: pointer;
                          data_size: csize): cint ## *
                                               ##  Write an uncoded AVFrame.
                                               ##
                                               ##  See av_write_uncoded_frame() for details.
                                               ##
                                               ##  The library will free *frame afterwards, but the muxer can prevent it
                                               ##  by setting the pointer to NULL.
                                               ##
    write_uncoded_frame*: proc (a1: ptr AVFormatContext; stream_index: cint;
                              frame: ptr ptr AVFrame; flags: cuint): cint ## *
                                                                   ##  Returns device list with it properties.
                                                                   ##  @see avdevice_list_devices() for more details.
                                                                   ##
    get_device_list*: proc (s: ptr AVFormatContext; device_list: ptr AVDeviceInfoList): cint ## *
                                                                                    ##  Initialize device capabilities submodule.
                                                                                    ##  @see avdevice_capabilities_create() for more details.
                                                                                    ##
    create_device_capabilities*: proc (s: ptr AVFormatContext;
                                     caps: ptr AVDeviceCapabilitiesQuery): cint ## *
                                                                            ##  Free device capabilities submodule.
                                                                            ##  @see avdevice_capabilities_free() for more details.
                                                                            ##
    free_device_capabilities*: proc (s: ptr AVFormatContext;
                                   caps: ptr AVDeviceCapabilitiesQuery): cint
    data_codec*: AVCodecID ## *< default data codec
                         ## *
                         ##  Initialize format. May allocate data here, and set any AVFormatContext or
                         ##  AVStream parameters that need to be set before packets are sent.
                         ##  This method must not write output.
                         ##
                         ##  Return 0 if streams were fully configured, 1 if not, negative AVERROR on failure
                         ##
                         ##  Any allocations made here must be freed in deinit().
                         ##
    init*: proc (a1: ptr AVFormatContext): cint ## *
                                          ##  Deinitialize format. If present, this is called whenever the muxer is being
                                          ##  destroyed, regardless of whether or not the header has been written.
                                          ##
                                          ##  If a trailer is being written, this is called after writerailer().
                                          ##
                                          ##  This is called if init() fails as well.
                                          ##
    deinit*: proc (a1: ptr AVFormatContext) ## *
                                       ##  Set up any necessary bitstream filtering and extract any extra data needed
                                       ##  for the global header.
                                       ##  Return 0 if more packets from this stream must be checked; 1 if not.
                                       ##
    check_bitstream*: proc (a1: ptr AVFormatContext; pkt: ptr AVPacket): cint

  INNER_C_STRUCT_avformat_1031* = object
    last_dts*: int64
    duration_gcd*: int64
    duration_count*: cint
    rfps_duration_sum*: int64
    duration_error*: array[2, array[MAX_STD_TIMEBASES, cdouble]]
    codec_info_duration*: int64
    codec_info_duration_fields*: int64
    frame_delay_evidence*: cint ## *
                              ##  0  -> decoder has not been searched for yet.
                              ##  >0 -> decoder found
                              ##  <0 -> decoder with codec_id == -found_decoder has not been found
                              ##
    found_decoder*: cint
    last_duration*: int64    ## *
                          ##  Those are used for average framerate estimation.
                          ##
    fps_first_dts*: int64
    fps_first_dts_idx*: cint
    fps_last_dts*: int64
    fps_last_dts_idx*: cint