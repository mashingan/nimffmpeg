const
  TEST_ATTRIBUTE* = true
  attribute_deprecated* = __attribute__((deprecated))

template test*(a, b: untyped): untyped =
  this(a, b)

var magic*: pointer

type
  test* {.bycopy.} = object
    when defined(TEST_ATTRIBUTE):
      var test1*: cint
    else:
      var test1*: cfloat

