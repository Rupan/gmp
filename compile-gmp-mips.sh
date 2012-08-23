#!/bin/bash

if [ ! -x configure ]
then
  echo "Run this script from the GMP base directory"
  exit 1
fi

export NDK="${HOME}/Downloads/android-ndk-r8b"
if [ ! -d ${NDK} ]
then
  echo "Please download and install the NDK, then update the path in this script."
  echo "  http://developer.android.com/sdk/ndk/index.html"
  exit 1
fi

# Extract an android-9 toolchain if needed
export TARGET="android-9"
export TOOLCHAIN="/tmp/${TARGET}-mips"
if [ ! -d ${TOOLCHAIN} ]
then
  ${NDK}/build/tools/make-standalone-toolchain.sh --toolchain=mipsel-linux-android-4.6 --platform=${TARGET} --install-dir=${TOOLCHAIN}
fi

export PATH="${TOOLCHAIN}/bin:${PATH}"
export LDFLAGS='-Wl,--no-undefined -Wl,-z,noexecstack -Wl,-z,relro -Wl,-z,now'
export LIBGMP_LDFLAGS='-avoid-version'
export LIBGMPXX_LDFLAGS='-avoid-version'

################################################################################################################

# base CFLAGS set from ndk-build output
BASE_CFLAGS='-O2 -pedantic -fomit-frame-pointer -Wa,--noexecstack -fno-strict-aliasing -finline-functions -ffunction-sections -funwind-tables -fmessage-length=0 -fno-inline-functions-called-once -fgcse-after-reload -frerun-cse-after-loop -frename-registers -funswitch-loops -finline-limit=300'

# mips CFLAGS not specified in 'CPU Arch ABIs' in the r8b documentation
export CFLAGS="${BASE_CFLAGS}"
./configure --prefix=/usr --disable-static --build=i686-pc-linux-gnu --host=mipsel-linux-android
make -j8 V=1 2>&1 | tee android-mips.log
make -j8 check TESTS=''
make install DESTDIR=$PWD/mips
cd mips && mv usr/lib/libgmp.so usr/include/gmp.h . && rm -rf usr && cd ..
make distclean

exit 0
