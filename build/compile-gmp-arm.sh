#!/bin/bash

# TODO: cross-compile testsuite & run on a target device
# Building the tests without running them is easy; just do "make check TESTS=''"

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

# Extract an Android toolchain, if needed
export TARGET32="android-24"
export TARGET64="android-24"
export TOOLCHAIN32="/tmp/${TARGET32}-arm32"
export TOOLCHAIN64="/tmp/${TARGET64}-arm64"
if [ ! -d ${TOOLCHAIN32} ]
then
  echo "======= EXTRACTING TOOLCHAIN FOR ARM32 ======="
  ${NDK}/build/tools/make-standalone-toolchain.sh --toolchain=arm-linux-androideabi-4.9 --platform=${TARGET32} --install-dir=${TOOLCHAIN32} || exit 1
fi
if [ ! -d ${TOOLCHAIN64} ]
then
  echo "======= EXTRACTING TOOLCHAIN FOR ARM64 ======="
  ${NDK}/build/tools/make-standalone-toolchain.sh --toolchain=aarch64-linux-android-4.9 --platform=${TARGET64} --install-dir=${TOOLCHAIN64} || exit 1
fi

export PATH="${TOOLCHAIN32}/bin:${TOOLCHAIN64}/bin:${PATH}"
export LIBGMP_LDFLAGS='-avoid-version'
export LIBGMPXX_LDFLAGS='-avoid-version'

################################################################################################################

export BASE_CFLAGS='-O2 -g -pedantic -fomit-frame-pointer -Wa,--noexecstack -ffunction-sections -funwind-tables -no-canonical-prefixes -fno-strict-aliasing'

# LDFLAGS for 64-bit ARM
export LDFLAGS='-Wl,--no-undefined -Wl,-z,noexecstack -Wl,-z,relro -Wl,-z,now'

# arm64-v8a
echo "======= COMPILING FOR arm64-v8a ======="
export CFLAGS="${BASE_CFLAGS} -fstack-protector-strong -finline-limit=300 -funswitch-loops"
./configure --prefix=/usr --disable-static --enable-cxx --build=x86_64-pc-linux-gnu --host=aarch64-linux-android MPN_PATH="arm64 generic"
sed -i.bak '/HAVE_LOCALECONV 1/d' ./config.h
make -j8 V=1 2>&1 | tee arm64-v8a.log
make install DESTDIR=$PWD/arm64-v8a
cd arm64-v8a && mv usr/lib/libgmp.so usr/lib/libgmpxx.so usr/include/gmp.h usr/include/gmpxx.h . && rm -rf usr && cd ..
make distclean

# LDFLAGS for 32-bit ARM
export LDFLAGS='-Wl,--fix-cortex-a8 -Wl,--no-undefined -Wl,-z,noexecstack -Wl,-z,relro -Wl,-z,now'

# armeabi-v7a with neon (unsupported target: will cause crashes on many phones, but works well on the Nexus One)
export CFLAGS="${BASE_CFLAGS} -fstack-protector -finline-limit=64 -march=armv7-a -mfloat-abi=softfp -mfpu=neon -ftree-vectorize"
./configure --prefix=/usr --disable-static --enable-cxx --build=x86_64-pc-linux-gnu --host=arm-linux-androideabi MPN_PATH="arm/v6t2 arm/v6 arm/v5 arm generic"
sed -i.bak '/HAVE_LOCALECONV 1/d' ./config.h
make -j8 V=1 2>&1 | tee armeabi-v7a-neon.log
make install DESTDIR=$PWD/armeabi-v7a-neon
cd armeabi-v7a-neon && mv usr/lib/libgmp.so usr/lib/libgmpxx.so usr/include/gmp.h usr/include/gmpxx.h . && rm -rf usr && cd ..
make distclean

# armeabi-v7a
export CFLAGS="${BASE_CFLAGS} -fstack-protector -finline-limit=64 -march=armv7-a -mfloat-abi=softfp -mfpu=vfp"
./configure --prefix=/usr --disable-static --enable-cxx --build=x86_64-pc-linux-gnu --host=arm-linux-androideabi MPN_PATH="arm/v6t2 arm/v6 arm/v5 arm generic"
sed -i.bak '/HAVE_LOCALECONV 1/d' ./config.h
make -j8 V=1 2>&1 | tee armeabi-v7a.log
make install DESTDIR=$PWD/armeabi-v7a
cd armeabi-v7a && mv usr/lib/libgmp.so usr/lib/libgmpxx.so usr/include/gmp.h usr/include/gmpxx.h . && rm -rf usr && cd ..
make distclean

# armeabi
export CFLAGS="${BASE_CFLAGS} -fstack-protector -finline-limit=64 -march=armv5te -mtune=xscale -msoft-float -mthumb"
./configure --prefix=/usr --disable-static --enable-cxx --build=x86_64-pc-linux-gnu --host=arm-linux-androideabi MPN_PATH="arm/v5 arm generic"
sed -i.bak '/HAVE_LOCALECONV 1/d' ./config.h
make -j8 V=1 2>&1 | tee armeabi.log
make install DESTDIR=$PWD/armeabi
cd armeabi && mv usr/lib/libgmp.so usr/lib/libgmpxx.so usr/include/gmp.h usr/include/gmpxx.h . && rm -rf usr && cd ..
make distclean

exit 0
