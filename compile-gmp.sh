#!/bin/bash

if [ ! -x configure ]
then
  echo "Run this script from the GMP base directory"
  exit 1
fi

export NDK="${HOME}/work/android-ndk-r5c"
if [ ! -d ${NDK} ]
then
  echo "Please download and install the NDK, then update the path in this script."
  echo "  http://developer.android.com/sdk/ndk/index.html"
  exit 1
fi

# Extract an android-5 toolchain if needed
export TARGET="android-5"
export TOOLCHAIN="/tmp/${TARGET}"
if [ ! -d ${TOOLCHAIN} ]
then
  ${NDK}/build/tools/make-standalone-toolchain.sh --platform=${TARGET} --install-dir=${TOOLCHAIN}
fi

export PATH=${TOOLCHAIN}/bin:$PATH
export LDFLAGS='-Wl,--fix-cortex-a8'

# patch Makefile.am to build the shared object without versioning info, then localize autotools
if [ ! -h config.sub ]
then
  patch -p1 < $0
  autoreconf -sfi
fi

################################################################################################################

# armeabi-v7a with neon (unsupported target: will cause crashes on many phones, but works well on the Nexus One)
#export CFLAGS="-O2 -pedantic -fomit-frame-pointer -march=armv7-a -mfloat-abi=softfp -mfpu=neon -ftree-vectorize"

# armeabi-v7a
export CFLAGS="-O2 -pedantic -fomit-frame-pointer -march=armv7-a -mfloat-abi=softfp"
./configure --prefix=/usr --disable-static --build=i686-pc-linux-gnu --host=arm-linux-androideabi
make
make install DESTDIR=$PWD/armeabi-v7a
cd armeabi-v7a && mv usr/lib/libgmp.so usr/include/gmp.h . && rm -rf usr && cd ..
make distclean

# armeabi
unset CFLAGS
./configure --prefix=/usr --disable-static --build=i686-pc-linux-gnu --host=arm-linux-androideabi
make
make install DESTDIR=$PWD/armeabi
cd armeabi && mv usr/lib/libgmp.so usr/include/gmp.h . && rm -rf usr && cd ..
make distclean

exit 0

################################################################################################################

This patch removes the version info (versioned soname) from the compiled library.
The Android NDK requires that prebuilt shared libraries end in ".so".

diff --git a/Makefile.am b/Makefile.am
index 52ec140..c3e86a9 100644
--- a/Makefile.am
+++ b/Makefile.am
@@ -261,7 +261,7 @@ libgmp_la_DEPENDENCIES = @TAL_OBJECT@		\
   $(MPN_OBJECTS) @mpn_objs_in_libgmp@		\
   $(PRINTF_OBJECTS)  $(SCANF_OBJECTS)
 libgmp_la_LIBADD = $(libgmp_la_DEPENDENCIES)
-libgmp_la_LDFLAGS = $(GMP_LDFLAGS) $(LIBGMP_LDFLAGS) \
+libgmp_la_LDFLAGS = $(GMP_LDFLAGS) $(LIBGMP_LDFLAGS) -avoid-version \
   -version-info $(LIBGMP_LT_CURRENT):$(LIBGMP_LT_REVISION):$(LIBGMP_LT_AGE)
 
 
@@ -275,7 +275,7 @@ endif
 libgmpxx_la_SOURCES = cxx/dummy.cc
 libgmpxx_la_DEPENDENCIES = $(CXX_OBJECTS) libgmp.la
 libgmpxx_la_LIBADD = $(libgmpxx_la_DEPENDENCIES)
-libgmpxx_la_LDFLAGS = $(GMP_LDFLAGS) $(LIBGMPXX_LDFLAGS) \
+libgmpxx_la_LDFLAGS = $(GMP_LDFLAGS) $(LIBGMPXX_LDFLAGS) -avoid-version \
   -version-info $(LIBGMPXX_LT_CURRENT):$(LIBGMPXX_LT_REVISION):$(LIBGMPXX_LT_AGE)
 
 
@@ -296,7 +296,7 @@ libmp_la_DEPENDENCIES = $(srcdir)/libmp.sym				\
   mpz/n_pow_ui$U.lo mpz/realloc$U.lo mpz/set$U.lo mpz/sub$U.lo		\
   mpz/tdiv_q$U.lo
 libmp_la_LIBADD = $(libmp_la_DEPENDENCIES)
-libmp_la_LDFLAGS = $(GMP_LDFLAGS) \
+libmp_la_LDFLAGS = $(GMP_LDFLAGS) -avoid-version \
   -version-info $(LIBMP_LT_CURRENT):$(LIBMP_LT_REVISION):$(LIBMP_LT_AGE) \
   -export-symbols $(srcdir)/libmp.sym
 EXTRA_DIST += libmp.sym
