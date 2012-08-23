#!/bin/bash

# TODO: cross-compile testsuite & run on a target device
# Building the tests without running them is easy; just do "make check TESTS=check"

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
export TOOLCHAIN="/tmp/${TARGET}"
if [ ! -d ${TOOLCHAIN} ]
then
  ${NDK}/build/tools/make-standalone-toolchain.sh --toolchain=arm-linux-androideabi-4.6 --platform=${TARGET} --install-dir=${TOOLCHAIN}
fi

export PATH="${TOOLCHAIN}/bin:${PATH}"
export LDFLAGS='-Wl,--fix-cortex-a8 -Wl,--no-undefined -Wl,-z,noexecstack -Wl,-z,relro -Wl,-z,now'
export LIBGMP_LDFLAGS='-avoid-version'
export LIBGMPXX_LDFLAGS='-avoid-version'

################################################################################################################

BASE_CFLAGS='-O2 -pedantic -fomit-frame-pointer -Wa,--noexecstack -ffunction-sections -funwind-tables -fstack-protector -fno-strict-aliasing -finline-limit=64'

# armeabi-v7a with neon (unsupported target: will cause crashes on many phones, but works well on the Nexus One)
export CFLAGS="${BASE_CFLAGS} -march=armv7-a -mfloat-abi=softfp -mfpu=neon -ftree-vectorize -ftree-vectorizer-verbose=2"
./configure --prefix=/usr --disable-static --build=i686-pc-linux-gnu --host=arm-linux-androideabi
make -j8 V=1 2>&1 | tee armeabi-v7a-neon.log
make -j8 check TESTS=''
TESTBASE='tests-armeabi-v7a-neon'
find tests -type f -executable -exec file '{}' \; | grep -v 'Bourne-Again shell script' | awk -F: '{print $1}' > ${TESTBASE}.txt
tar cpf ${TESTBASE}.tar -T ${TESTBASE}.txt --owner root --group root
rm -f ${TESTBASE}.txt
xz -9 -v ${TESTBASE}.tar
make install DESTDIR=$PWD/armeabi-v7a-neon
cd armeabi-v7a-neon && mv usr/lib/libgmp.so usr/include/gmp.h . && rm -rf usr && cd ..
mv ${TESTBASE}.tar.xz armeabi-v7a-neon
make distclean

# armeabi-v7a
export CFLAGS="${BASE_CFLAGS} -march=armv7-a -mfloat-abi=softfp -mfpu=vfp"
./configure --prefix=/usr --disable-static --build=i686-pc-linux-gnu --host=arm-linux-androideabi
make -j8 V=1 2>&1 | tee armeabi-v7a.log
make -j8 check TESTS=''
TESTBASE='tests-armeabi-v7a'
find tests -type f -executable -exec file '{}' \; | grep -v 'Bourne-Again shell script' | awk -F: '{print $1}' > ${TESTBASE}.txt
tar cpf ${TESTBASE}.tar -T ${TESTBASE}.txt --owner root --group root
rm -f ${TESTBASE}.txt
xz -9 -v ${TESTBASE}.tar
make install DESTDIR=$PWD/armeabi-v7a
cd armeabi-v7a && mv usr/lib/libgmp.so usr/include/gmp.h . && rm -rf usr && cd ..
mv ${TESTBASE}.tar.xz armeabi-v7a
make distclean

# armeabi
export CFLAGS="${BASE_CFLAGS} -march=armv5te -mtune=xscale -msoft-float"
./configure --prefix=/usr --disable-static --build=i686-pc-linux-gnu --host=arm-linux-androideabi
make -j8 V=1 2>&1 | tee armeabi.log
make -j8 check TESTS=''
TESTBASE='tests-armeabi'
find tests -type f -executable -exec file '{}' \; | grep -v 'Bourne-Again shell script' | awk -F: '{print $1}' > ${TESTBASE}.txt
tar cpf ${TESTBASE}.tar -T ${TESTBASE}.txt --owner root --group root
rm -f ${TESTBASE}.txt
xz -9 -v ${TESTBASE}.tar
make install DESTDIR=$PWD/armeabi
cd armeabi && mv usr/lib/libgmp.so usr/include/gmp.h . && rm -rf usr && cd ..
mv ${TESTBASE}.tar.xz armeabi
make distclean

exit 0
