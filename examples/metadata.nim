import libavformat/avformat
import libavutil/[dict, log]
import os, strformat

proc main =
    var tag: ptr AVDictionaryEntry
    var fmt: ptr AVFormatContext
    if paramCount() < 1:
        quit(&"usage: {getAppFilename()} <input_file>\n" &
            "example program to demonstrate the use of the libavformat metadata API.\n") 
    
    var retval = avformat_open_input(addr fmt, cstring(paramStr 1), nil, nil)
    if retval != 0:
        quit "Fail open input"

    retval = avformat_find_stream_info(fmt, nil)
    if retval < 0:
        av_log(nil, AV_LOG_ERROR, "Cannot find stream information\n")
        quit "Fail find stream info"

    while true:
        tag = av_dict_get(fmt[].metadata, "", tag, AV_DICT_IGNORE_SUFFIX)
        #if tag != 0 or tag != nil:
        if tag == nil:
            break
        echo &"{tag[].key}={tag[].value}"
    
    avformat_close_input(addr fmt)

main()