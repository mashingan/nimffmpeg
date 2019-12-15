# WIP

## FFMpeg Binding
Bind that eventually be completed.

To able to compile and work with, make sure we installed ffmpeg library dev and
shared lib to run it.

If you installed the ffmpeg library dev in different path than usual (e.g. `/usr/include`),
make sure pass the include path in your code (with `passC` pragma, `{.passc: "-Iyour/include/path".}`)
or in option during compilation (`--passC:"-Iyour/include/path"`).