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
##  Public dictionary API.
##  @deprecated
##   AVDictionary is provided for compatibility with libav. It is both in
##   implementation as well as API inefficient. It does not scale and is
##   extremely slow with large dictionaries.
##   It is recommended that new code uses our tree container from tree.c/h
##   where applicable, which uses AVL trees to achieve O(log n) performance.
##

when defined(windows):
  {.push importc, dynlib: "avutil-(|55|56|57).dll".}
elif defined(macosx):
  {.push importc, dynlib: "avutil(|.55|.56|.57).dylib".}
else:
  {.push importc, dynlib: "avutil.so(|.55|.56|.57)".}

## *
##  @addtogroup lavu_dict AVDictionary
##  @ingroup lavu_data
##
##  @brief Simple key:value store
##
##  @{
##  Dictionaries are used for storing key:value pairs. To create
##  an AVDictionary, simply pass an address of a NULL pointer to
##  av_dict_set(). NULL can be used as an empty dictionary wherever
##  a pointer to an AVDictionary is required.
##  Use av_dict_get() to retrieve an entry or iterate over all
##  entries and finally av_dict_free() to free the dictionary
##  and all its contents.
##
##  @code
##    AVDictionary *d = NULL;           // "create" an empty dictionary
##    AVDictionaryEntry *t = NULL;
##
##    av_dict_set(&d, "foo", "bar", 0); // add an entry
##
##    char *k = av_strdup("key");       // if your strings are already allocated,
##    char *v = av_strdup("value");     // you can avoid copying them like this
##    av_dict_set(&d, k, v, AV_DICT_DONT_STRDUP_KEY | AV_DICT_DONT_STRDUP_VAL);
##
##    while (t = av_dict_get(d, "", t, AV_DICT_IGNORE_SUFFIX)) {
##        <....>                             // iterate over all entries in d
##    }
##    av_dict_free(&d);
##  @endcode
##

const
  AV_DICT_MATCH_CASE* = 1
  AV_DICT_IGNORE_SUFFIX* = 2
  AV_DICT_DONT_STRDUP_KEY* = 4
  AV_DICT_DONT_STRDUP_VAL* = 8
  AV_DICT_DONT_OVERWRITE* = 16
  AV_DICT_APPEND* = 32
  AV_DICT_MULTIKEY* = 64

type
  AVDictionaryEntry*  = object
    key*: cstring
    value*: cstring
  AVDictionary*  = object


## *
##  Get a dictionary entry with matching key.
##
##  The returned entry key or value must not be changed, or it will
##  cause undefined behavior.
##
##  To iterate through all the dictionary entries, you can set the matching key
##  to the null string "" and set the AV_DICT_IGNORE_SUFFIX flag.
##
##  @param prev Set to the previous matching element to find the next.
##              If set to NULL the first matching element is returned.
##  @param key matching key
##  @param flags a collection of AV_DICT_* flags controlling how the entry is retrieved
##  @return found entry or NULL in case no matching entry was found in the dictionary
##

proc av_dict_get*(m: ptr AVDictionary; key: cstring; prev: ptr AVDictionaryEntry;
                 flags: cint): ptr AVDictionaryEntry
## *
##  Get number of entries in dictionary.
##
##  @param m dictionary
##  @return  number of entries in dictionary
##

proc av_dict_count*(m: ptr AVDictionary): cint
## *
##  Set the given entry in *pm, overwriting an existing entry.
##
##  Note: If AV_DICT_DONT_STRDUP_KEY or AV_DICT_DONT_STRDUP_VAL is set,
##  these arguments will be freed on error.
##
##  Warning: Adding a new entry to a dictionary invalidates all existing entries
##  previously returned with av_dict_get.
##
##  @param pm pointer to a pointer to a dictionary struct. If *pm is NULL
##  a dictionary struct is allocated and put in *pm.
##  @param key entry key to add to *pm (will either be av_strduped or added as a new key depending on flags)
##  @param value entry value to add to *pm (will be av_strduped or added as a new key depending on flags).
##         Passing a NULL value will cause an existing entry to be deleted.
##  @return >= 0 on success otherwise an error code <0
##

proc av_dict_set*(pm: ptr ptr AVDictionary; key: cstring; value: cstring; flags: cint): cint
## *
##  Convenience wrapper for av_dict_set that converts the value to a string
##  and stores it.
##
##  Note: If AV_DICT_DONT_STRDUP_KEY is set, key will be freed on error.
##

proc av_dict_set_int*(pm: ptr ptr AVDictionary; key: cstring; value: int64; flags: cint): cint
## *
##  Parse the key/value pairs list and add the parsed entries to a dictionary.
##
##  In case of failure, all the successfully set entries are stored in
##  *pm. You may need to manually free the created dictionary.
##
##  @param key_val_sep  a 0-terminated list of characters used to separate
##                      key from value
##  @param pairs_sep    a 0-terminated list of characters used to separate
##                      two pairs from each other
##  @param flags        flags to use when adding to dictionary.
##                      AV_DICT_DONT_STRDUP_KEY and AV_DICT_DONT_STRDUP_VAL
##                      are ignored since the key/value tokens will always
##                      be duplicated.
##  @return             0 on success, negative AVERROR code on failure
##

proc av_dict_parse_string*(pm: ptr ptr AVDictionary; str: cstring;
                          key_val_sep: cstring; pairs_sep: cstring; flags: cint): cint
## *
##  Copy entries from one AVDictionary struct into another.
##  @param dst pointer to a pointer to a AVDictionary struct. If *dst is NULL,
##             this function will allocate a struct for you and put it in *dst
##  @param src pointer to source AVDictionary struct
##  @param flags flags to use when setting entries in *dst
##  @note metadata is read using the AV_DICT_IGNORE_SUFFIX flag
##  @return 0 on success, negative AVERROR code on failure. If dst was allocated
##            by this function, callers should free the associated memory.
##

proc av_dict_copy*(dst: ptr ptr AVDictionary; src: ptr AVDictionary; flags: cint): cint
## *
##  Free all the memory allocated for an AVDictionary struct
##  and all keys and values.
##

proc av_dict_free*(m: ptr ptr AVDictionary)
## *
##  Get dictionary entries as a string.
##
##  Create a string containing dictionary's entries.
##  Such string may be passed back to av_dict_parse_string().
##  @note String is escaped with backslashes ('\').
##
##  @param[in]  m             dictionary
##  @param[out] buffer        Pointer to buffer that will be allocated with string containg entries.
##                            Buffer must be freed by the caller when is no longer needed.
##  @param[in]  key_val_sep   character used to separate key from value
##  @param[in]  pairs_sep     character used to separate two pairs from each other
##  @return                   >= 0 on success, negative on error
##  @warning Separators cannot be neither '\\' nor '\0'. They also cannot be the same.
##

proc av_dict_get_string*(m: ptr AVDictionary; buffer: cstringArray; key_val_sep: char;
                        pairs_sep: char): cint
## *
##  @}
##
