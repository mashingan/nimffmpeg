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
##  @ingroup lavf_io
##  Buffered I/O operations
##

import
  ../utiltypes,
  ../libavutil/dict

{.pragma: avio, importc, header: "<libavutil/avio.h>".}

when defined(windows):
  {.push importc, dynlib: "avformat-(|55|56|57|58).dll".}
elif defined(macosx):
  {.push importc, dynlib: "avformat(|.55|.56|.57|.58).dylib".}
else:
  {.push importc, dynlib: "libavformat.so(|.55|.56|.57|.58)".}


## *
##  Seeking works like for a local file.
##

const
  AVIO_SEEKABLE_NORMAL* = (1 shl 0)

## *
##  Seeking by timestamp with avio_seekime() is possible.
##

const
  AVIO_SEEKABLE_TIME* = (1 shl 1)

## *
##  Callback for checking whether to abort blocking functions.
##  AVERROR_EXIT is returned in this case by the interrupted
##  function. During blocking operations, callback is called with
##  opaque as parameter. If the callback returns 1, the
##  blocking operation will be aborted.
##
##  No members can be added to this struct without a major bump, if
##  new elements have been added after this struct in AVFormatContext
##  or AVIOContext.
##

## *
##  Directory entry types.
##

type
  AVIODirEntryType* {.avio.} = enum
    AVIO_ENTRY_UNKNOWN, AVIO_ENTRY_BLOCK_DEVICE, AVIO_ENTRY_CHARACTER_DEVICE,
    AVIO_ENTRY_DIRECTORY, AVIO_ENTRY_NAMED_PIPE, AVIO_ENTRY_SYMBOLIC_LINK,
    AVIO_ENTRY_SOCKET, AVIO_ENTRY_FILE, AVIO_ENTRY_SERVER, AVIO_ENTRY_SHARE,
    AVIO_ENTRY_WORKGROUP


## *
##  Describes single entry of the directory.
##
##  Only name and type fields are guaranteed be set.
##  Rest of fields are protocol or/and platform dependent and might be unknown.
##

type
  AVIODirEntry* {.avio.} = object
    name*: cstring             ## *< Filename
    `type`*: cint              ## *< Type of the entry
    utf8*: cint ## *< Set to 1 when name is encoded with UTF-8, 0 otherwise.
              ##                                                Name can be encoded with UTF-8 even though 0 is set.
    size*: int64             ## *< File size in bytes, -1 if unknown.
    modificationimestamp*: int64 ## *< Time of last modification in microseconds since unix
                                   ##                                                epoch, -1 if unknown.
    accessimestamp*: int64 ## *< Time of last access/in microseconds since unix epoch,
                             ##                                                -1 if unknown.
    status_changeimestamp*: int64 ## *< Time of last status change in microseconds since unix
                                    ##                                                epoch, -1 if unknown.
    user_id*: int64          ## *< User ID of owner, -1 if unknown.
    group_id*: int64         ## *< Group ID of owner, -1 if unknown.
    filemode*: int64         ## *< Unix file mode, -1 if unknown.

  AVIODirContext* {.avio.} = object
    url_context*: ptr URLContext

  URLContext* {.avio.} = object


## *
##  Different data types that can be returned via the AVIO
##  write_dataype callback.
##

## *
##  Return the name of the protocol that will handle the passed URL.
##
##  NULL is returned if no protocol could be found for the given URL.
##
##  @return Name of the protocol or NULL.
##

proc avio_find_protocol_name*(url: cstring): cstring
## *
##  Return AVIO_FLAG_* access flags corresponding to the access permissions
##  of the resource in url, or a negative value corresponding to an
##  AVERROR code in case of failure. The returned access flags are
##  masked by the value in flags.
##
##  @note This function is intrinsically unsafe, in the sense that the
##  checked resource may change its existence or permission status from
##  one call to another. Thus you should not trust the returned value,
##  unless you are sure that no other processes are accessing the
##  checked resource.
##

proc avio_check*(url: cstring; flags: cint): cint
## *
##  Move or rename a resource.
##
##  @note url_src and url_dst should share the same protocol and authority.
##
##  @param url_src url to resource to be moved
##  @param url_dst new url to resource if the operation succeeded
##  @return >=0 on success or negative on error.
##

proc avpriv_io_move*(url_src: cstring; url_dst: cstring): cint
## *
##  Delete a resource.
##
##  @param url resource to be deleted.
##  @return >=0 on success or negative on error.
##

proc avpriv_io_delete*(url: cstring): cint
## *
##  Open directory for reading.
##
##  @param s       directory read context. Pointer to a NULL pointer must be passed.
##  @param url     directory to be listed.
##  @param options A dictionary filled with protocol-private options. On return
##                 this parameter will be destroyed and replaced with a dictionary
##                 containing options that were not found. May be NULL.
##  @return >=0 on success or negative on error.
##

proc avio_open_dir*(s: ptr ptr AVIODirContext; url: cstring;
                   options: ptr ptr AVDictionary): cint
## *
##  Get next directory entry.
##
##  Returned entry must be freed with avio_free_directory_entry(). In particular
##  it may outlive AVIODirContext.
##
##  @param s         directory read context.
##  @param[out] next next entry or NULL when no more entries.
##  @return >=0 on success or negative on error. End of list is not considered an
##              error.
##

proc avio_read_dir*(s: ptr AVIODirContext; next: ptr ptr AVIODirEntry): cint
## *
##  Close directory.
##
##  @note Entries created using avio_read_dir() are not deleted and must be
##  freeded with avio_free_directory_entry().
##
##  @param s         directory read context.
##  @return >=0 on success or negative on error.
##

proc avio_close_dir*(s: ptr ptr AVIODirContext): cint
## *
##  Free entry allocated by avio_read_dir().
##
##  @param entry entry to be freed.
##

proc avio_free_directory_entry*(entry: ptr ptr AVIODirEntry)
## *
##  Allocate and initialize an AVIOContext for buffered I/O. It must be later
##  freed with avio_context_free().
##
##  @param buffer Memory block for input/output operations via AVIOContext.
##         The buffer must be allocated with av_malloc() and friends.
##         It may be freed and replaced with a new buffer by libavformat.
##         AVIOContext.buffer holds the buffer currently in use,
##         which must be later freed with av_free().
##  @param buffer_size The buffer size is very important for performance.
##         For protocols with fixed blocksize it should be set to this blocksize.
##         For others a typical size is a cache page, e.g. 4kb.
##  @param write_flag Set to 1 if the buffer should be writable, 0 otherwise.
##  @param opaque An opaque pointer to user-specific data.
##  @param read_packet  A function for refilling the buffer, may be NULL.
##                      For stream protocols, must never return 0 but rather
##                      a proper AVERROR code.
##  @param write_packet A function for writing the buffer contents, may be NULL.
##         The function may not change the input buffers content.
##  @param seek A function for seeking to specified byte position, may be NULL.
##
##  @return Allocated AVIOContext or NULL on failure.
##

proc avio_alloc_context*(buffer: ptr cuchar; buffer_size: cint; write_flag: cint;
                        opaque: pointer; read_packet: proc (opaque: pointer;
    buf: ptr uint8; buf_size: cint): cint; write_packet: proc (opaque: pointer;
    buf: ptr uint8; buf_size: cint): cint; seek: proc (opaque: pointer; offset: int64;
    whence: cint): int64): ptr AVIOContext
## *
##  Free the supplied IO context and everything associated with it.
##
##  @param s Double pointer to the IO context. This function will write NULL
##  into s.
##

proc avio_context_free*(s: ptr ptr AVIOContext)
proc avio_w8*(s: ptr AVIOContext; b: cint)
proc avio_write*(s: ptr AVIOContext; buf: ptr cuchar; size: cint)
proc avio_wl64*(s: ptr AVIOContext; val: uint64)
proc avio_wb64*(s: ptr AVIOContext; val: uint64)
proc avio_wl32*(s: ptr AVIOContext; val: cuint)
proc avio_wb32*(s: ptr AVIOContext; val: cuint)
proc avio_wl24*(s: ptr AVIOContext; val: cuint)
proc avio_wb24*(s: ptr AVIOContext; val: cuint)
proc avio_wl16*(s: ptr AVIOContext; val: cuint)
proc avio_wb16*(s: ptr AVIOContext; val: cuint)
## *
##  Write a NULL-terminated string.
##  @return number of bytes written.
##

proc avio_put_str*(s: ptr AVIOContext; str: cstring): cint
## *
##  Convert an UTF-8 string to UTF-16LE and write it.
##  @param s the AVIOContext
##  @param str NULL-terminated UTF-8 string
##
##  @return number of bytes written.
##

proc avio_put_str16le*(s: ptr AVIOContext; str: cstring): cint
## *
##  Convert an UTF-8 string to UTF-16BE and write it.
##  @param s the AVIOContext
##  @param str NULL-terminated UTF-8 string
##
##  @return number of bytes written.
##

proc avio_put_str16be*(s: ptr AVIOContext; str: cstring): cint
## *
##  Mark the written bytestream as a specific type.
##
##  Zero-length ranges are omitted from the output.
##
##  @param time the stream time the current bytestream pos corresponds to
##              (in AV_TIME_BASE units), or AV_NOPTS_VALUE if unknown or not
##              applicable
##  @param type the kind of data written starting at the current pos
##

proc avio_write_marker*(s: ptr AVIOContext; time: int64; `type`: AVIODataMarkerType)
## *
##  ORing this as the "whence" parameter to a seek function causes it to
##  return the filesize without seeking anywhere. Supporting this is optional.
##  If it is not supported then the seek function will return <0.
##

const
  AVSEEK_SIZE* = 0x00010000

## *
##  Passing this flag as the "whence" parameter to a seek function causes it to
##  seek by any means (like reopening and linear reading) or other normally unreasonable
##  means that can be extremely slow.
##  This may be ignored by the seek code.
##

const
  AVSEEK_FORCE* = 0x00020000

## *
##  fseek() equivalent for AVIOContext.
##  @return new position or AVERROR.
##

proc avio_seek*(s: ptr AVIOContext; offset: int64; whence: cint): int64
## *
##  Skip given number of bytes forward
##  @return new position or AVERROR.
##

proc avio_skip*(s: ptr AVIOContext; offset: int64): int64
## *
##  ftell() equivalent for AVIOContext.
##  @return position or AVERROR.
##

proc avioell*(s: ptr AVIOContext): int64 {.inline.} =
  return avio_seek(s, 0, cint fspCur)

## *
##  Get the filesize.
##  @return filesize or AVERROR
##

proc avio_size*(s: ptr AVIOContext): int64
## *
##  Similar to feof() but also returns nonzero on read errors.
##  @return non zero if and only if at end of file or a read error happened when reading.
##

proc avio_feof*(s: ptr AVIOContext): cint
## *
##  Writes a formatted string to the context.
##  @return number of bytes written, < 0 on error.
##
## int avio_printf(AVIOContext *s, const char *fmt, ...) av_printf_format(2, 3);
## *
##  Write a NULL terminated array of strings to the context.
##  Usually you don't need to use this function directly but its macro wrapper,
##  avio_print.
##

proc avio_print_string_array*(s: ptr AVIOContext; strings: ptr cstring)
## *
##  Write strings (const char *) to the context.
##  This is a convenience macro around avio_print_string_array and it
##  automatically creates the string array from the variable argument list.
##  For simple string concatenations this function is more performant than using
##  avio_printf since it does not need a temporary buffer.
##
## #define avio_print(s, ...) \
##     avio_print_string_array(s, (const char*[]){__VA_ARGS__, NULL})
## *
##  Force flushing of buffered data.
##
##  For write streams, force the buffered data to be immediately written to the output,
##  without to wait to fill the internal buffer.
##
##  For read streams, discard all currently buffered data, and advance the
##  reported file position to that of the underlying stream. This does not
##  read new data, and does not perform any seeks.
##

proc avio_flush*(s: ptr AVIOContext)
## *
##  Read size bytes from AVIOContext into buf.
##  @return number of bytes read or AVERROR
##

proc avio_read*(s: ptr AVIOContext; buf: ptr cuchar; size: cint): cint
## *
##  Read size bytes from AVIOContext into buf. Unlike avio_read(), this is allowed
##  to read fewer bytes than requested. The missing bytes can be read in the next
##  call. This always tries to read at least 1 byte.
##  Useful to reduce latency in certain cases.
##  @return number of bytes read or AVERROR
##

proc avio_read_partial*(s: ptr AVIOContext; buf: ptr cuchar; size: cint): cint
## *
##  @name Functions for reading from AVIOContext
##  @{
##
##  @note return 0 if EOF, so you cannot use it if EOF handling is
##        necessary
##

proc avio_r8*(s: ptr AVIOContext): cint
proc avio_rl16*(s: ptr AVIOContext): cuint
proc avio_rl24*(s: ptr AVIOContext): cuint
proc avio_rl32*(s: ptr AVIOContext): cuint
proc avio_rl64*(s: ptr AVIOContext): uint64
proc avio_rb16*(s: ptr AVIOContext): cuint
proc avio_rb24*(s: ptr AVIOContext): cuint
proc avio_rb32*(s: ptr AVIOContext): cuint
proc avio_rb64*(s: ptr AVIOContext): uint64
## *
##  @}
##
## *
##  Read a string from pb into buf. The reading will terminate when either
##  a NULL character was encountered, maxlen bytes have been read, or nothing
##  more can be read from pb. The result is guaranteed to be NULL-terminated, it
##  will be truncated if buf is too small.
##  Note that the string is not interpreted or validated in any way, it
##  might get truncated in the middle of a sequence for multi-byte encodings.
##
##  @return number of bytes read (is always <= maxlen).
##  If reading ends on EOF or error, the return value will be one more than
##  bytes actually read.
##

proc avio_get_str*(pb: ptr AVIOContext; maxlen: cint; buf: cstring; buflen: cint): cint
## *
##  Read a UTF-16 string from pb and convert it to UTF-8.
##  The reading will terminate when either a null or invalid character was
##  encountered or maxlen bytes have been read.
##  @return number of bytes read (is always <= maxlen)
##

proc avio_get_str16le*(pb: ptr AVIOContext; maxlen: cint; buf: cstring; buflen: cint): cint
proc avio_get_str16be*(pb: ptr AVIOContext; maxlen: cint; buf: cstring; buflen: cint): cint
## *
##  @name URL open modes
##  The flags argument to avio_open must be one of the following
##  constants, optionally ORed with other flags.
##  @{
##

const
  AVIO_FLAG_READ* = 1
  AVIO_FLAG_WRITE* = 2
  AVIO_FLAG_READ_WRITE* = (AVIO_FLAG_READ or AVIO_FLAG_WRITE) ## *< read-write pseudo flag

## *
##  @}
##
## *
##  Use non-blocking mode.
##  If this flag is set, operations on the context will return
##  AVERROR(EAGAIN) if they can not be performed immediately.
##  If this flag is not set, operations on the context will never return
##  AVERROR(EAGAIN).
##  Note that this flag does not affect the opening/connecting of the
##  context. Connecting a protocol will always block if necessary (e.g. on
##  network protocols) but never hang (e.g. on busy devices).
##  Warning: non-blocking protocols is work-in-progress; this flag may be
##  silently ignored.
##

const
  AVIO_FLAG_NONBLOCK* = 8

## *
##  Use direct mode.
##  avio_read and avio_write should if possible be satisfied directly
##  instead of going through a buffer, and avio_seek will always
##  call the underlying seek function directly.
##

const
  AVIO_FLAG_DIRECT* = 0x00008000

## *
##  Create and initialize a AVIOContext for accessing the
##  resource indicated by url.
##  @note When the resource indicated by url has been opened in
##  read+write mode, the AVIOContext can be used only for writing.
##
##  @param s Used to return the pointer to the created AVIOContext.
##  In case of failure the pointed to value is set to NULL.
##  @param url resource to access
##  @param flags flags which control how the resource indicated by url
##  is to be opened
##  @return >= 0 in case of success, a negative value corresponding to an
##  AVERROR code in case of failure
##

proc avio_open*(s: ptr ptr AVIOContext; url: cstring; flags: cint): cint
## *
##  Create and initialize a AVIOContext for accessing the
##  resource indicated by url.
##  @note When the resource indicated by url has been opened in
##  read+write mode, the AVIOContext can be used only for writing.
##
##  @param s Used to return the pointer to the created AVIOContext.
##  In case of failure the pointed to value is set to NULL.
##  @param url resource to access
##  @param flags flags which control how the resource indicated by url
##  is to be opened
##  @param int_cb an interrupt callback to be used at the protocols level
##  @param options  A dictionary filled with protocol-private options. On return
##  this parameter will be destroyed and replaced with a dict containing options
##  that were not found. May be NULL.
##  @return >= 0 in case of success, a negative value corresponding to an
##  AVERROR code in case of failure
##

proc avio_open2*(s: ptr ptr AVIOContext; url: cstring; flags: cint;
                int_cb: ptr AVIOInterruptCB; options: ptr ptr AVDictionary): cint
## *
##  Close the resource accessed by the AVIOContext s and free it.
##  This function can only be used if s was opened by avio_open().
##
##  The internal buffer is automatically flushed before closing the
##  resource.
##
##  @return 0 on success, an AVERROR < 0 on error.
##  @see avio_closep
##

proc avio_close*(s: ptr AVIOContext): cint
## *
##  Close the resource accessed by the AVIOContext *s, free it
##  and set the pointer pointing to it to NULL.
##  This function can only be used if s was opened by avio_open().
##
##  The internal buffer is automatically flushed before closing the
##  resource.
##
##  @return 0 on success, an AVERROR < 0 on error.
##  @see avio_close
##

proc avio_closep*(s: ptr ptr AVIOContext): cint
## *
##  Open a write only memory stream.
##
##  @param s new IO context
##  @return zero if no error.
##

proc avio_open_dyn_buf*(s: ptr ptr AVIOContext): cint
## *
##  Return the written size and a pointer to the buffer.
##  The AVIOContext stream is left intact.
##  The buffer must NOT be freed.
##  No padding is added to the buffer.
##
##  @param s IO context
##  @param pbuffer pointer to a byte buffer
##  @return the length of the byte buffer
##

proc avio_get_dyn_buf*(s: ptr AVIOContext; pbuffer: ptr ptr uint8): cint
## *
##  Return the written size and a pointer to the buffer. The buffer
##  must be freed with av_free().
##  Padding of AV_INPUT_BUFFER_PADDING_SIZE is added to the buffer.
##
##  @param s IO context
##  @param pbuffer pointer to a byte buffer
##  @return the length of the byte buffer
##

proc avio_close_dyn_buf*(s: ptr AVIOContext; pbuffer: ptr ptr uint8): cint
## *
##  Iterate through names of available protocols.
##
##  @param opaque A private pointer representing current protocol.
##         It must be a pointer to NULL on first iteration and will
##         be updated by successive calls to avio_enum_protocols.
##  @param output If set to 1, iterate over output protocols,
##                otherwise over input protocols.
##
##  @return A static string containing the name of current protocol or NULL
##

proc avio_enum_protocols*(opaque: ptr pointer; output: cint): cstring
## *
##  Pause and resume playing - only meaningful if using a network streaming
##  protocol (e.g. MMS).
##
##  @param h     IO context from which to call the read_pause function pointer
##  @param pause 1 for pause, 0 for resume
##

proc avio_pause*(h: ptr AVIOContext; pause: cint): cint
## *
##  Seek to a given timestamp relative to some component stream.
##  Only meaningful if using a network streaming protocol (e.g. MMS.).
##
##  @param h IO context from which to call the seek function pointers
##  @param stream_index The stream index that the timestamp is relative to.
##         If stream_index is (-1) the timestamp should be in AV_TIME_BASE
##         units from the beginning of the presentation.
##         If a stream_index >= 0 is used and the protocol does not support
##         seeking based on component streams, the call will fail.
##  @param timestamp timestamp in AVStream.time_base units
##         or if there is no stream specified then in AV_TIME_BASE units.
##  @param flags Optional combination of AVSEEK_FLAG_BACKWARD, AVSEEK_FLAG_BYTE
##         and AVSEEK_FLAG_ANY. The protocol may silently ignore
##         AVSEEK_FLAG_BACKWARD and AVSEEK_FLAG_ANY, but AVSEEK_FLAG_BYTE will
##         fail if used and not supported.
##  @return >= 0 on success
##  @see AVInputFormat::read_seek
##

proc avio_seekime*(h: ptr AVIOContext; stream_index: cint; timestamp: int64;
                    flags: cint): int64
##  Avoid a warning. The header can not be included because it breaks c++.

type
  AVBPrint* {.avio.} = object


## *
##  Read contents of h into print buffer, up to max_size bytes, or up to EOF.
##
##  @return 0 for success (max_size bytes read or EOF reached), negative error
##  code otherwise
##

proc avio_reado_bprint*(h: ptr AVIOContext; pb: ptr AVBPrint; max_size: csize): cint
## *
##  Accept and allocate a client context on a server context.
##  @param  s the server context
##  @param  c the client context, must be unallocated
##  @return   >= 0 on success or a negative value corresponding
##            to an AVERROR on failure
##

proc avio_accept*(s: ptr AVIOContext; c: ptr ptr AVIOContext): cint
## *
##  Perform one step of the protocol handshake to accept a new client.
##  This function must be called on a client returned by avio_accept() before
##  using it as a read/write context.
##  It is separate from avio_accept() because it may block.
##  A step of the handshake is defined by places where the application may
##  decide to change the proceedings.
##  For example, on a protocol with a request header and a reply header, each
##  one can constitute a step because the application may use the parameters
##  from the request to change parameters in the reply; or each individual
##  chunk of the request can constitute a step.
##  If the handshake is already finished, avio_handshake() does nothing and
##  returns 0 immediately.
##
##  @param  c the client context to perform the handshake on
##  @return   0   on a complete and successful handshake
##            > 0 if the handshake progressed, but is not complete
##            < 0 for an AVERROR code
##

proc avio_handshake*(c: ptr AVIOContext): cint