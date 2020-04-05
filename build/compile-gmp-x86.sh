#!/bin/bash

if [ ! -x configure ]
then
  echo "Run this script from the GMP base directory"
  exit 1
fi

export NDK="/tmp/android-ndk-r21"
if [ ! -d ${NDK} ]
then
  echo "Please download and install the NDK, then update the path in this script."
  echo "  http://developer.android.com/sdk/ndk/index.html"
  exit 1
fi

# Extract an android toolchain if needed
export TARGET32="android-24"
export TOOLCHAIN32="/tmp/${TARGET32}-x86"
if [ ! -d ${TOOLCHAIN32} ]
then
  ${NDK}/build/tools/make-standalone-toolchain.sh --toolchain=x86-4.9 --platform=${TARGET32} --install-dir=${TOOLCHAIN32} || exit 1
fi

export TARGET64="android-24"
export TOOLCHAIN64="/tmp/${TARGET64}-x86_64"
if [ ! -d ${TOOLCHAIN64} ]
then
  ${NDK}/build/tools/make-standalone-toolchain.sh --toolchain=x86_64-4.9 --platform=${TARGET64} --install-dir=${TOOLCHAIN64} || exit 1
fi

export PATH="${TOOLCHAIN32}/bin:${TOOLCHAIN64}/bin:${PATH}"
export LDFLAGS='-Wl,-z,noexecstack,-z,relro,-z,now,--no-undefined'
export LIBGMP_LDFLAGS='-avoid-version'
export LIBGMPXX_LDFLAGS='-avoid-version'

################################################################################################################

# base CFLAGS set from ndk-build output
BASE_CFLAGS='-O2 -g -pedantic -Wa,--noexecstack -fomit-frame-pointer -ffunction-sections -funwind-tables -fstrict-aliasing -funswitch-loops -finline-limit=300 -no-canonical-prefixes'

# x86, CFLAGS set according to 'CPU Arch ABIs' in the r8c documentation
export CFLAGS="${BASE_CFLAGS} -fstack-protector -march=i686 -mtune=intel -mssse3 -mfpmath=sse -m32"
./configure --prefix=/usr --disable-static --enable-cxx --build=x86_64-pc-linux-gnu --host=i686-linux-android MPN_PATH="x86/atom/sse2 x86/atom/mmx x86/atom x86/mmx x86 generic" || exit 1
sed -i.bak '/HAVE_LOCALECONV 1/d' ./config.h
make -j8 V=1 2>&1 | tee android-x86.log
make install DESTDIR=$PWD/x86
cd x86 && mv usr/lib/libgmp.so usr/lib/libgmpxx.so usr/include/gmp.h usr/include/gmpxx.h . && rm -rf usr && cd ..
make distclean

# x86_64, CFLAGS set according to 'CPU Arch ABIs' in the NDK documentation, LDFLAGS as observed from ndk-build
export CFLAGS="${BASE_CFLAGS} -fstack-protector-strong -march=x86-64 -msse4.2 -mpopcnt -m64 -mtune=intel"

./configure --prefix=/usr --disable-static --enable-cxx --build=x86_64-pc-linux-gnu --host=x86_64-linux-android MPN_PATH="x86_64/pentium4 x86_64/fastsse x86_64/k8 x86_64 generic" || exit 1
sed -i.bak '/HAVE_LOCALECONV 1/d' ./config.h
make -j8 V=1 2>&1 | tee android-x86_64.log
make install DESTDIR=$PWD/x86_64
cd x86_64 && mv usr/lib/libgmp.so usr/lib/libgmpxx.so usr/include/gmp.h usr/include/gmpxx.h . && rm -rf usr && cd ..
make distclean
