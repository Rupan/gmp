#!/bin/bash

if [ ! -x configure ]
then
  echo "Run this script from the GMP base directory"
  exit 1
fi

export NDK="/tmp/android-ndk-r14b"
if [ ! -d ${NDK} ]
then
  echo "Please download and install the NDK, then update the path in this script."
  echo "  http://developer.android.com/sdk/ndk/index.html"
  exit 1
fi

# Extract an android-14 toolchain if needed
export TARGET32="android-24"
export TOOLCHAIN32="/tmp/${TARGET32}-mips"
if [ ! -d ${TOOLCHAIN32} ]
then
  ${NDK}/build/tools/make-standalone-toolchain.sh --toolchain=mipsel-linux-android-4.9 --platform=${TARGET32} --install-dir=${TOOLCHAIN32} || exit 1
fi

export TARGET64="android-24"
export TOOLCHAIN64="/tmp/${TARGET64}-mips64"
if [ ! -d ${TOOLCHAIN64} ]
then
  ${NDK}/build/tools/make-standalone-toolchain.sh --toolchain=mips64el-linux-android-4.9 --platform=${TARGET64} --install-dir=${TOOLCHAIN64} || exit 1
fi

export PATH="${TOOLCHAIN32}/bin:${TOOLCHAIN64}/bin:${PATH}"
export LDFLAGS='-Wl,--no-undefined -Wl,-z,noexecstack -Wl,-z,relro -Wl,-z,now'
export LIBGMP_LDFLAGS='-avoid-version'
export LIBGMPXX_LDFLAGS='-avoid-version'

################################################################################################################

# base CFLAGS set from ndk-build output
BASE_CFLAGS='-O2 -g -pedantic -fomit-frame-pointer -Wa,--noexecstack -fno-strict-aliasing -finline-functions -ffunction-sections -funwind-tables -fmessage-length=0 -fno-inline-functions-called-once -fgcse-after-reload -frerun-cse-after-loop -frename-registers -no-canonical-prefixes'

# mips CFLAGS not specified in 'CPU Arch ABIs' in the NDK documentation
export CFLAGS="${BASE_CFLAGS}"
./configure --prefix=/usr --disable-static --enable-cxx --build=x86_64-pc-linux-gnu --host=mipsel-linux-android MPN_PATH="mips32 generic"
sed -i.bak '/HAVE_LOCALECONV 1/d' ./config.h
make -j8 V=1 2>&1 | tee android-mips.log
make install DESTDIR=$PWD/mips
cd mips && mv usr/lib/libgmp.so usr/lib/libgmpxx.so usr/include/gmp.h usr/include/gmpxx.h . && rm -rf usr && cd ..
make distclean

# mips64 CFLAGS not specified in 'CPU Arch ABIs' in the NDK documentation
export CFLAGS="${BASE_CFLAGS}"
# Ugly hack: delete incompatible assembly code from MPN directory
rm -f mpn/mips64/{addmul_1.asm,submul_1.asm,mul_1.asm,sqr_diagonal.asm,umul.asm}
./configure --prefix=/usr --disable-static --enable-cxx --build=x86_64-pc-linux-gnu --host=mips64el-linux-android MPN_PATH="mips64 generic"
sed -i.bak '/HAVE_LOCALECONV 1/d' ./config.h
make -j8 V=1 2>&1 | tee android-mips64.log
make install DESTDIR=$PWD/mips64
cd mips64 && mv usr/lib/libgmp.so usr/lib/libgmpxx.so usr/include/gmp.h usr/include/gmpxx.h . && rm -rf usr && cd ..
make distclean

exit 0
