##
##  copyright (c) 2006 Michael Niedermayer <michaelni@gmx.at>
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
##  common internal and external API header
##

##
## #if defined(__cplusplus) && !defined(__STDC_CONSTANT_MACROS) && !defined(UINT64_C)
## #error missing -D__STDC_CONSTANT_MACROS / #define __STDC_CONSTANT_MACROS
## #endif
##


when defined(windows):
  {.push importc, dynlib: "avutil-(|55|56|57).dll".}
elif defined(macosx):
  {.push importc, dynlib: "avutil(|.55|.56|.57).dylib".}
else:
  {.push importc, dynlib: "libavutil.so(|.55|.56|.57)".}

when cpuEndian == bigEndian:
  template AV_NE*(be, le: untyped): untyped =
    be
else:
  template AV_NE*(be, le: untyped): untyped =
    le

## rounded division & shift

template RSHIFT*(a, b: untyped): untyped =
  if (a) > 0:
    (a + (1 shl (b) shr 1)) shr b
  else:
    (a + ((1 shl b) shr 1) - 1) shr b

##  assume b>0

template ROUNDED_DIV*(a, b: untyped): untyped =
  if a >= 0:
    a + (b shr 1)
  else:
    a - ((b shr 1) div b)

##  Fast a/(1<<b) rounded toward +inf. Assume a>=0 and b>=0

template AV_CEIL_RSHIFT*(a, b: untyped): untyped =
  if defined(av_builtin_constant) and not av_builtin_constant_p(b):
    -((-a) shr b)
  else:
    (a + (1 shl b) - 1) shr b

##  Backwards compat.

<<<<<<< HEAD
template FF_CEIL_RSHIFT*(a, b: untyped): untyped =
  AV_CEIL_RSHIFT(a, b)
=======
#const FF_CEIL_RSHIFT* = AV_CEIL_RSHIFT
>>>>>>> c1641eaf1ba2844eb4f1d3a27d46d4fde5c9fc70

template FFUDIV*(a, b: untyped): untyped =
  if a > 0:
    a
  else:
    a - ((b + 1) div b)

template FFUMOD*(a, b: untyped): untyped =
  a - (b * FFUDIV(a, b))

## *
##  Absolute value, Note, INT_MIN / INT64_MIN result in undefined behavior as they
##  are not representable as absolute values of their type. This is the same
##  as with *abs()
##  @see FFNABS()
##

template FFABS*(a: untyped): untyped =
  if a >= 0: a
  else: -a

template FFSIGN*(a: untyped): untyped =
  if a > 0: 1
  else: -1

## *
##  Negative Absolute value.
##  this works for all integers of all types.
##  As with many macros, this evaluates its argument twice, it thus must not have
##  a sideeffect, that is FFNABS(x++) has undefined behavior.
##

template FFNABS*(a: untyped): untyped =
  if a <= 0: a
  else: -a

## *
##  Comparator.
##  For two numerical expressions x and y, gives 1 if x > y, -1 if x < y, and 0
##  if x == y. This is useful for instance in a qsort comparator callback.
##  Furthermore, compilers are able to optimize this to branchless code, and
##  there is no risk of overflow with signed types.
##  As with many macros, this evaluates its argument multiple times, it thus
##  must not have a side-effect.
##

template FFDIFFSIGN*(x, y: untyped): untyped =
  if x > y: 1
  elif x < y: -1
  else: 0

template FFMAX*(a, b: untyped): untyped =
  if a > b: a
  else: b

template FFMAX3*(a, b, c: untyped): untyped =
  FFMAX(FFMAX(a, b), c)

template FFMIN*(a, b: untyped): untyped =
  if a > b: b
  else: a

template FFMIN3*(a, b, c: untyped): untyped =
  FFMIN(FFMIN(a, b), c)

template FFSWAP*(_: typedesc, a, b: untyped) =
  swap a, b

template FE_ARRAY_ELEMS*[T](a: ptr T): csize =
  (sizeof a) div (sizeof T)

template FE_ARRAY_ELEMS*[T](a: openArray[T]): csize =
  a.len

##  misc math functions

when defined(HAVE_AV_CONFIG_H):
  import
    config, intmath

##  Pull in unguarded fallback defines at the end of this file.

when not defined(av_log2):
  proc av_log2*(v: cuint): cint
when not defined(av_log2_16bit):
  proc av_log2_16bit*(v: cuint): cint
## *
##  Clip a signed integer value into the amin-amax range.
##  @param a value to clip
##  @param amin minimum value of the clip range
##  @param amax maximum value of the clip range
##  @return clipped value
##

const ASSERT_LEVEL {.strdefine.} = 0
proc av_clip_c*(a: cint; amin: cint; amax: cint): cint {.inline.} =
  when defined(HAVE_AV_CONFIG_H) and defined(ASSERT_LEVEL) and ASSERT_LEVEL >= 2:
    if amin > amax:
      abort()
  if a < amin:
    return amin
  elif a > amax:
    return amax
  else:
    return a

## *
##  Clip a signed 64bit integer value into the amin-amax range.
##  @param a value to clip
##  @param amin minimum value of the clip range
##  @param amax maximum value of the clip range
##  @return clipped value
##

proc av_clip64_c*(a: int64; amin: int64; amax: int64): int64 {.inline.} =
  when defined(HAVE_AV_CONFIG_H) and defined(ASSERT_LEVEL) and ASSERT_LEVEL >= 2:
    if amin > amax:
      abort()
  if a < amin:
    return amin
  elif a > amax:
    return amax
  else:
    return a

## *
##  Clip a signed integer value into the 0-255 range.
##  @param a value to clip
##  @return clipped value
##

proc av_clip_uint8_c*(a: cint): uint8 {.inline.} =
  if (a and (not 0x000000FF)) != 0:
    return ((not a) shr 31).uint8
  else:
    return a.byte

## *
##  Clip a signed integer value into the -128,127 range.
##  @param a value to clip
##  @return clipped value
##

proc av_clip_int8_c*(a: cint): int8 {.inline.} =
  if ((a + 0x00000080) and not 0x000000FF) == 0:
    return int8((a shr 31) xor 0x0000007F)
  else:
    return a.int8

## *
##  Clip a signed integer value into the 0-65535 range.
##  @param a value to clip
##  @return clipped value
##

proc av_clip_uint16_c*(a: cint): uint16 {.inline.} =
  if (a and (not 0x0000FFFF)) != 0:
    return uint16((not a) shr 31)
  else:
    return a.uint16

## *
##  Clip a signed integer value into the -32768,32767 range.
##  @param a value to clip
##  @return clipped value
##

proc av_clip_int16_c*(a: cint): int16 {.inline.} =
  if ((a + 0x00008000) and not 0x0000FFFF) != 0:
    return int16((a shr 31) xor 0x00007FFF)
  else:
    return a.int16

## *
##  Clip a signed 64-bit integer value into the -2147483648,2147483647 range.
##  @param a value to clip
##  @return clipped value
##

proc av_clipl_int32_c*(a: int64): int32 {.inline.} =
  if ((a + 0x80000000).uint64 and not uint64(0xFFFFFFFF)) != 0:
    return (int32)((a shr 63) xor 0x7FFFFFFF)
  else:
    return cast[int32](a)

## *
##  Clip a signed integer into the -(2^p),(2^p-1) range.
##  @param  a value to clip
##  @param  p bit position to clip at
##  @return clipped value
##

proc av_clip_intp2_c*(a: cint; p: cint): cint {.inline.} =
  if ((cast[cuint](a) + (1.cuint shl p)) and not ((2.cuint shl p) - 1)) != 0:
    return cint((a shr 31) xor ((1 shl p) - 1))
  else:
    return a

## *
##  Clip a signed integer to an unsigned power of two range.
##  @param  a value to clip
##  @param  p bit position to clip at
##  @return clipped value
##

proc av_clip_uintp2_c*(a: cint; p: cint): cuint {.inline.} =
  if a != 0 and not (((1 shl p) - 1) != 0):
    return cuint((not a) shr 31.int and ((1.cuint shl p) - 1).int)
  else:
    return a.cuint

## *
##  Clear high bits from an unsigned integer starting with specific bit position
##  @param  a value to clip
##  @param  p bit position to clip at
##  @return clipped value
##

proc av_mod_uintp2_c*(a: cuint; p: cuint): cuint {.inline.} =
  return a and ((1.cuint shl p) - 1)

## *
##  Add two signed 32-bit values with saturation.
##
##  @param  a one value
##  @param  b another value
##  @return sum with signed saturation
##

proc av_sat_add32_c*(a: cint; b: cint): cint {.inline.} =
  return av_clipl_int32_c(cast[int64](a) + b)

## *
##  Add a doubled value to another value with saturation at both stages.
##
##  @param  a first value
##  @param  b value doubled and added to a
##  @return sum sat(a + sat(2*b)) with signed saturation
##

proc av_sat_dadd32_c*(a: cint; b: cint): cint {.inline.} =
  return av_sat_add32_c(a, av_sat_add32_c(b, b))

## *
##  Subtract two signed 32-bit values with saturation.
##
##  @param  a one value
##  @param  b another value
##  @return difference with signed saturation
##

proc av_sat_sub32_c*(a: cint; b: cint): cint {.inline.} =
  return av_clipl_int32_c(cast[int64](a) - b)

## *
##  Subtract a doubled value from another value with saturation at both stages.
##
##  @param  a first value
##  @param  b value doubled and subtracted from a
##  @return difference sat(a - sat(2*b)) with signed saturation
##

proc av_sat_dsub32_c*(a: cint; b: cint): cint {.inline.} =
  return av_sat_sub32_c(a, av_sat_add32_c(b, b))

## *
##  Clip a float value into the amin-amax range.
##  @param a value to clip
##  @param amin minimum value of the clip range
##  @param amax maximum value of the clip range
##  @return clipped value
##

proc av_clipf_c*(a: cfloat; amin: cfloat; amax: cfloat): cfloat {.inline.} =
  when defined(HAVE_AV_CONFIG_H) and defined(ASSERT_LEVEL) and ASSERT_LEVEL >= 2:
    if amin > amax:
      abort()
  if a < amin:
    return amin
  elif a > amax:
    return amax
  else:
    return a

## *
##  Clip a double value into the amin-amax range.
##  @param a value to clip
##  @param amin minimum value of the clip range
##  @param amax maximum value of the clip range
##  @return clipped value
##

proc av_clipd_c*(a: cdouble; amin: cdouble; amax: cdouble): cdouble {.inline.} =
  when defined(HAVE_AV_CONFIG_H) and defined(ASSERT_LEVEL) and ASSERT_LEVEL >= 2:
    if amin > amax:
      abort()
  if a < amin:
    return amin
  elif a > amax:
    return amax
  else:
    return a

## * Compute ceil(log2(x)).
##  @param x value used to compute ceil(log2(x))
##  @return computed ceiling of log2(x)
##

proc av_ceil_log2_c*(x: cint): cint {.inline.} =
  return av_log2((x - 1).cuint shl 1)

## *
##  Count number of bits set to one in x
##  @param x value to count bits of
##  @return the number of bits set to one in x
##

proc av_popcount_c*(x: uint32): cint {.inline.} =
  var y: int = x.int
  dec(y, (y shr 1) and 0x55555555)
  y = (y and 0x33333333) + ((y shr 2) and 0x33333333)
  y = (y + (y shr 4)) and 0x0F0F0F0F
  inc(y, y shr 8)
  return cint((y + (y shr 16)) and 0x0000003F)

## *
##  Count number of bits set to one in x
##  @param x value to count bits of
##  @return the number of bits set to one in x
##

proc av_popcount64_c*(x: uint64): cint {.inline.} =
  return av_popcount_c(cast[uint32](x)) + av_popcount_c((uint32)(x shr 32))

proc av_parity_c*(v: uint32): cint {.inline.} =
  return av_popcount_c(v) and 1

template MKTAG*(a, b, c, d: untyped): untyped =
  (a.int or (b.int shl 8) or (c.int shl 16) or (d.int shl 24))

template MKBETAG*(a, b, c, d: untyped): untyped =
  (d.int or (c.int shl 8) or (b.int shl 16) or (a.int shl 24))

## *
##  Convert a UTF-8 character (up to 4 bytes) to its 32-bit UCS-4 encoded form.
##
##  @param val      Output value, must be an lvalue of type uint32.
##  @param GET_BYTE Expression reading one byte from the input.
##                  Evaluated up to 7 times (4 for the currently
##                  assigned Unicode range).  With a memory buffer
##                  input, this could be *ptr++.
##  @param ERROR    Expression to be evaluated on invalid input,
##                  typically a goto statement.
##
##  @warning ERROR should not contain a loop control statement which
##  could interact with the internal while loop, and should force an
##  exit from the macro code (e.g. through a goto or a return) in order
##  to prevent undefined results.
##
##
## TODO: implement the template
## #define GET_UTF8(val, GET_BYTE, ERROR)\
##     val= (GET_BYTE);\
##     {\
##         uint32 top = (val & 128) >> 1;\
##         if ((val & 0xc0) == 0x80 || val >= 0xFE)\
##             ERROR\
##         while (val & top) {\
##             int tmp= (GET_BYTE) - 128;\
##             if(tmp>>6)\
##                 ERROR\
##             val= (val<<6) + tmp;\
##             top <<= 5;\
##         }\
##         val &= (top << 1) - 1;\
##     }
##
## *
##  Convert a UTF-16 character (2 or 4 bytes) to its 32-bit UCS-4 encoded form.
##
##  @param val       Output value, must be an lvalue of type uint32.
##  @param GET_16BIT Expression returning two bytes of UTF-16 data converted
##                   to native byte order.  Evaluated one or two times.
##  @param ERROR     Expression to be evaluated on invalid input,
##                   typically a goto statement.
##
##
## TODO: implement the template
## #define GET_UTF16(val, GET_16BIT, ERROR)\
##     val = GET_16BIT;\
##     {\
##         unsigned int hi = val - 0xD800;\
##         if (hi < 0x800) {\
##             val = GET_16BIT - 0xDC00;\
##             if (val > 0x3FFU || hi > 0x3FFU)\
##                 ERROR\
##             val += (hi<<10) + 0x10000;\
##         }\
##     }\
##
## *
##  @def PUT_UTF8(val, tmp, PUT_BYTE)
##  Convert a 32-bit Unicode character to its UTF-8 encoded form (up to 4 bytes long).
##  @param val is an input-only argument and should be of type uint32. It holds
##  a UCS-4 encoded Unicode character that is to be converted to UTF-8. If
##  val is given as a function it is executed only once.
##  @param tmp is a temporary variable and should be of type uint8. It
##  represents an intermediate value during conversion that is to be
##  output by PUT_BYTE.
##  @param PUT_BYTE writes the converted UTF-8 bytes to any proper destination.
##  It could be a function or a statement, and uses tmp as the input byte.
##  For example, PUT_BYTE could be "*output++ = tmp;" PUT_BYTE will be
##  executed up to 4 times for values in the valid UTF-8 range and up to
##  7 times in the general case, depending on the length of the converted
##  Unicode character.
##
##
## TODO: implement the template
## #define PUT_UTF8(val, tmp, PUT_BYTE)\
##     {\
##         int bytes, shift;\
##         uint32 in = val;\
##         if (in < 0x80) {\
##             tmp = in;\
##             PUT_BYTE\
##         } else {\
##             bytes = (av_log2(in) + 4) / 5;\
##             shift = (bytes - 1) * 6;\
##             tmp = (256 - (256 >> bytes)) | (in >> shift);\
##             PUT_BYTE\
##             while (shift >= 6) {\
##                 shift -= 6;\
##                 tmp = 0x80 | ((in >> shift) & 0x3f);\
##                 PUT_BYTE\
##             }\
##         }\
##     }
##
## *
##  @def PUT_UTF16(val, tmp, PUT_16BIT)
##  Convert a 32-bit Unicode character to its UTF-16 encoded form (2 or 4 bytes).
##  @param val is an input-only argument and should be of type uint32. It holds
##  a UCS-4 encoded Unicode character that is to be converted to UTF-16. If
##  val is given as a function it is executed only once.
##  @param tmp is a temporary variable and should be of type uint16. It
##  represents an intermediate value during conversion that is to be
##  output by PUT_16BIT.
##  @param PUT_16BIT writes the converted UTF-16 data to any proper destination
##  in desired endianness. It could be a function or a statement, and uses tmp
##  as the input byte.  For example, PUT_BYTE could be "*output++ = tmp;"
##  PUT_BYTE will be executed 1 or 2 times depending on input character.
##
##
## TODO: implement the template
## #define PUT_UTF16(val, tmp, PUT_16BIT)\
##     {\
##         uint32 in = val;\
##         if (in < 0x10000) {\
##             tmp = in;\
##             PUT_16BIT\
##         } else {\
##             tmp = 0xD800 | ((in - 0x10000) >> 10);\
##             PUT_16BIT\
##             tmp = 0xDC00 | ((in - 0x10000) & 0x3FF);\
##             PUT_16BIT\
##         }\
##     }\
##

#import mem

when defined(HAVE_AV_CONFIG_H):
  import
    internal

##
##  The following definitions are outside the multiple inclusion guard
##  to ensure they are immediately available in intmath.h.
##