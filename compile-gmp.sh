#!/bin/bash

if [ ! -x configure ]
then
  echo "Run this script from the GMP base directory"
  exit 1
fi

# bugfix for GMP 5.0.2, published on gmplib.org
if [ ! -f ANDROID_PATCHED ]
then
  patch -p1 < $0
  touch ANDROID_PATCHED
fi

export NDK="${HOME}/work/android-ndk-r6b"
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
export LIBGMP_LDFLAGS='-avoid-version'
export LIBGMPXX_LDFLAGS='-avoid-version'

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
export CFLAGS="-O2 -pedantic -fomit-frame-pointer"
./configure --prefix=/usr --disable-static --build=i686-pc-linux-gnu --host=arm-linux-androideabi
make
make install DESTDIR=$PWD/armeabi
cd armeabi && mv usr/lib/libgmp.so usr/include/gmp.h . && rm -rf usr && cd ..
make distclean

exit 0

################################################################################################################

# HG changeset patch
# User Torbjorn Granlund <tege@gmplib.org>
# Date 1310730221 -7200
# Node ID 538dfce27f410b910d5e2f011119269e224d16a3
# Parent  03ed209dd7efd4f4fff0ce297bb3a8f7e7ba2366
(mpn_dcpi1_bdiv_q): Get mpn_sub_1 size argument right.

diff -r 03ed209dd7ef -r 538dfce27f41 mpn/generic/dcpi1_bdiv_q.c
--- a/mpn/generic/dcpi1_bdiv_q.c	Thu Jun 16 12:22:24 2011 +0200
+++ b/mpn/generic/dcpi1_bdiv_q.c	Fri Jul 15 13:43:41 2011 +0200
@@ -7,7 +7,7 @@
    SAFE TO REACH THEM THROUGH DOCUMENTED INTERFACES.  IN FACT, IT IS ALMOST
    GUARANTEED THAT THEY WILL CHANGE OR DISAPPEAR IN A FUTURE GMP RELEASE.
 
-Copyright 2006, 2007, 2009, 2010 Free Software Foundation, Inc.
+Copyright 2006, 2007, 2009, 2010, 2011 Free Software Foundation, Inc.
 
 This file is part of the GNU MP Library.
 
@@ -28,7 +28,6 @@
 #include "gmp-impl.h"
 
 
-
 mp_size_t
 mpn_dcpi1_bdiv_q_n_itch (mp_size_t n)
 {
@@ -130,7 +129,7 @@
       qn = nn - qn;
       while (qn > dn)
 	{
-	  mpn_sub_1 (np + dn, np + dn, qn, cy);
+	  mpn_sub_1 (np + dn, np + dn, qn - dn, cy);
 	  cy = mpn_dcpi1_bdiv_qr_n (qp, np, dp, dn, dinv, tp);
 	  qp += dn;
 	  np += dn;

