#!/bin/bash

if [ ! -x configure ]
then
  echo "Run this script from the GMP base directory"
  exit 1
fi

export NDK="/space/android-ndk-r8e"
if [ ! -d ${NDK} ]
then
  echo "Please download and install the NDK, then update the path in this script."
  echo "  http://developer.android.com/sdk/ndk/index.html"
  exit 1
fi

# Extract an android-9 toolchain if needed
export TARGET="android-9"
export TOOLCHAIN="/tmp/${TARGET}-x86"
if [ ! -d ${TOOLCHAIN} ]
then
  ${NDK}/build/tools/make-standalone-toolchain.sh --toolchain=x86-4.7 --platform=${TARGET} --install-dir=${TOOLCHAIN} --system=linux-x86_64
fi

export PATH="${TOOLCHAIN}/bin:${PATH}"
export LDFLAGS='-Wl,-z,noexecstack,-z,relro'
export LIBGMP_LDFLAGS='-avoid-version'
export LIBGMPXX_LDFLAGS='-avoid-version'

################################################################################################################

# base CFLAGS set from ndk-build output
BASE_CFLAGS='-O2 -pedantic -Wa,--noexecstack -fomit-frame-pointer -ffunction-sections -funwind-tables -fstrict-aliasing -funswitch-loops -finline-limit=300'

# x86, CFLAGS set according to 'CPU Arch ABIs' in the r8c documentation
export CFLAGS="${BASE_CFLAGS} -march=i686 -mtune=atom -msse3 -mstackrealign -mfpmath=sse -m32"
./configure --prefix=/usr --disable-static --build=i686-pc-linux-gnu --host=i686-linux-android
make -j8 V=1 2>&1 | tee android-x86.log
#make -j8 check TESTS=''
#TESTBASE='tests-x86'
#find tests -type f -executable -exec file '{}' \; | grep -v 'Bourne-Again shell script' | awk -F: '{print $1}' > ${TESTBASE}.txt
#tar cpf ${TESTBASE}.tar -T ${TESTBASE}.txt --owner root --group root
#rm -f ${TESTBASE}.txt
#xz -9 -v ${TESTBASE}.tar
make install DESTDIR=$PWD/x86
cd x86 && mv usr/lib/libgmp.so usr/include/gmp.h . && rm -rf usr && cd ..
make distclean
#mv ${TESTBASE}.tar.xz x86
exit 0
