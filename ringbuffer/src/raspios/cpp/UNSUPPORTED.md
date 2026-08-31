# C++ Unsupported on Raspios

Raspios (Raspberry Pi OS) Bookworm provides GCC 12.2 as the default
C++ compiler via its official repositories (raspberrypi.com).  GCC 12
does not include the `<format>` C++20 header, which the ringbuffer
library requires.

Because `archive.raspberrypi.com` is the only approved package source
for this image, a newer GCC is not available.  The ringbuffer C++
library cannot be built on Raspios until a newer GCC becomes available
through the official Raspberry Pi OS channels.
