#!/bin/bash

if [ ! -x configure ]
then
  echo "Run this script from the GMP base directory"
  exit 1
fi

export NDK="/space/android-ndk-r9"
if [ ! -d ${NDK} ]
then
  echo "Please download and install the NDK, then update the path in this script."
  echo "  http://developer.android.com/sdk/ndk/index.html"
  exit 1
fi

# Extract an android-14 toolchain if needed
export TARGET="android-14"
export TOOLCHAIN="/tmp/${TARGET}-mips"
if [ ! -d ${TOOLCHAIN} ]
then
  ${NDK}/build/tools/make-standalone-toolchain.sh --toolchain=mipsel-linux-android-4.7 --platform=${TARGET} --install-dir=${TOOLCHAIN} --system=linux-x86_64
fi

export PATH="${TOOLCHAIN}/bin:${PATH}"
export LDFLAGS='-Wl,--no-undefined -Wl,-z,noexecstack -Wl,-z,relro -Wl,-z,now'
export LIBGMP_LDFLAGS='-avoid-version'
export LIBGMPXX_LDFLAGS='-avoid-version'

# The following line enables C++ support. For GMP <= 5.1.2 you *must* apply gmp_decimal_point.patch prior to running this script.
export CPLUSPLUS_FLAGS='--enable-cxx'

################################################################################################################

# base CFLAGS set from ndk-build output
BASE_CFLAGS='-O2 -pedantic -fomit-frame-pointer -Wa,--noexecstack -fno-strict-aliasing -finline-functions -ffunction-sections -funwind-tables -fmessage-length=0 -fno-inline-functions-called-once -fgcse-after-reload -frerun-cse-after-loop -frename-registers -funswitch-loops -finline-limit=300'

# mips CFLAGS not specified in 'CPU Arch ABIs' in the r8b documentation
export CFLAGS="${BASE_CFLAGS}"
./configure --prefix=/usr --disable-static ${CPLUSPLUS_FLAGS} --build=x86_64-pc-linux-gnu --host=mipsel-linux-android
make -j8 V=1 2>&1 | tee android-mips.log
#make -j8 check TESTS=''
#TESTBASE='tests-mips'
#find tests -type f -executable -exec file '{}' \; | grep -v 'Bourne-Again shell script' | awk -F: '{print $1}' > ${TESTBASE}.txt
#tar cpf ${TESTBASE}.tar -T ${TESTBASE}.txt --owner root --group root
#rm -f ${TESTBASE}.txt
#xz -9 -v ${TESTBASE}.tar
make install DESTDIR=$PWD/mips
if [ -z "${CPLUSPLUS_FLAGS}" ]
then
  cd mips && mv usr/lib/libgmp.so usr/include/gmp.h . && rm -rf usr && cd ..
else
  cd mips && mv usr/lib/libgmp.so usr/lib/libgmpxx.so usr/include/gmp.h usr/include/gmpxx.h . && rm -rf usr && cd ..
fi
make distclean
#mv ${TESTBASE}.tar.xz mips
exit 0
