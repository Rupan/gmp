#!/bin/bash

if [ ! -x configure ]
then
  echo "Run this script from the GMP base directory"
  exit 1
fi

export NDK="/tank/android/android-ndk-r10e"
if [ ! -d ${NDK} ]
then
  echo "Please download and install the NDK, then update the path in this script."
  echo "  http://developer.android.com/sdk/ndk/index.html"
  exit 1
fi

# Extract an android-14 toolchain if needed
export TARGET="android-19"
export TOOLCHAIN="/tmp/${TARGET}-x86"
if [ ! -d ${TOOLCHAIN} ]
then
  ${NDK}/build/tools/make-standalone-toolchain.sh --toolchain=x86-4.9 --platform=${TARGET} --install-dir=${TOOLCHAIN} --system=linux-x86_64
fi

export PATH="${TOOLCHAIN}/bin:${PATH}"
export LDFLAGS='-Wl,-z,noexecstack,-z,relro'
export LIBGMP_LDFLAGS='-avoid-version'
export LIBGMPXX_LDFLAGS='-avoid-version'

# The following line enables C++ support.  For GMP <= 5.1.2 you *must* apply gmp_decimal_point.patch prior to running this script.
export CPLUSPLUS_FLAGS='--enable-cxx'

################################################################################################################

# base CFLAGS set from ndk-build output
BASE_CFLAGS='-O2 -g -pedantic -Wa,--noexecstack -fomit-frame-pointer -ffunction-sections -funwind-tables -fstrict-aliasing -funswitch-loops -finline-limit=300'

# x86, CFLAGS set according to 'CPU Arch ABIs' in the r8c documentation
export CFLAGS="${BASE_CFLAGS} -march=i686 -mtune=atom -msse3 -mstackrealign -mfpmath=sse -m32"
./configure --prefix=/usr --disable-static ${CPLUSPLUS_FLAGS} --build=x86_64-pc-linux-gnu --host=i686-linux-android MPN_PATH="x86/atom/sse2 x86/atom/mmx x86/atom x86/mmx x86 generic"
make -j8 V=1 2>&1 | tee android-x86.log
#make -j8 check TESTS=''
#TESTBASE='tests-x86'
#find tests -type f -executable -exec file '{}' \; | grep -v 'Bourne-Again shell script' | awk -F: '{print $1}' > ${TESTBASE}.txt
#tar cpf ${TESTBASE}.tar -T ${TESTBASE}.txt --owner root --group root
#rm -f ${TESTBASE}.txt
#xz -9 -v ${TESTBASE}.tar
make install DESTDIR=$PWD/x86
if [ -z "${CPLUSPLUS_FLAGS}" ]
then
  cd x86 && mv usr/lib/libgmp.so usr/include/gmp.h . && rm -rf usr && cd ..
else
  cd x86 && mv usr/lib/libgmp.so usr/lib/libgmpxx.so usr/include/gmp.h usr/include/gmpxx.h . && rm -rf usr && cd ..
fi
make distclean
#mv ${TESTBASE}.tar.xz x86
exit 0
