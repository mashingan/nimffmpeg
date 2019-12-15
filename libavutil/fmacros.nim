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
##  @ingroup lavu
##  Utility Preprocessor macros
##

## *
##  @addtogroup preproc_misc Preprocessor String Macros
##
##  String manipulation macros
##
##  @{
##

template AV_TOSTRING*(s: untyped): untyped = $s

template AV_STRINGIFY*(s: untyped): untyped =
  AV_TOSTRING(s)

## #define AV_TOSTRING(s) #s
## #define AV_GLUE(a, b) a ## b

template AV_GLUE*(a, b): untyped =
  `a . b`

template AV_JOIN*(a, b: untyped): untyped =
  AV_GLUE(a, b)

## *
##  @}
##
## #define AV_PRAGMA(s) _Pragma(#s)

template FFALIGN*(x, a: untyped): untyped =
  (((x) + (a) - 1) and not ((a) - 1))
