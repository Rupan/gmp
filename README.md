GMP for Android
---------------

This repository contains a prebuilt copy of [GMP](https://gmplib.org/) 6.2.0 compiled with the Android NDK r21 against API level 24.

Compiling against API levels greater than or equal to 21 will produce backwards incompatible binaries which reference localeconv() unless special care is taken.  It is advised to check config.h at each build and confirm that localeconv is not enabled.

The C++ bindings are included; they depend on libgmp.so, so you will need to ship *both* in your APK for each platform you support.

Installation and usage in an Android project
--------------------------------------------

1. Check out a copy of this repository into your jni folder, using something like this:

     $ git submodule add git://github.com/Rupan/gmp.git jni/gmp

2. Add "gmp" to APP_MODULES in jni/Application.mk
3. Add "gmp" to LOCAL_SHARED_LIBRARIES in your module's Android.mk as required.
4. Use GMP as normal by including gmp.h in your source files where required.
5. Build the rest of your native code as you would normally:

     $ ndk-build

A basic top-level Android.mk might look like this:

    JNI_PATH := $(call my-dir)

    # Uncomment the following line to include GMP's C++ bindings in your APK
    #GMP_WITH_CPLUSPLUS := yes
    include $(JNI_PATH)/gmp/Android.mk

    LOCAL_PATH := $(JNI_PATH)
    include $(CLEAR_VARS)

    LOCAL_MODULE := myBNmodule
    LOCAL_SRC_FILES := myBNmodule.c

    LOCAL_LDLIBS += -llog
    LOCAL_SHARED_LIBRARIES := gmp
    include $(BUILD_SHARED_LIBRARY)

Inclusion via Android Studio is covered here: https://developer.android.com/studio/projects/add-native-code.html#link-gradle

Usage at runtime
----------------

The GMP library must be loaded prior to other dependent modules.  This is an apparent shortcoming of Android.  To handle this condition, do something like the following in your Java source code:

    // ...
    System.loadLibrary("gmp");
    System.loadLibrary("myBNmodule");
    // ...

The scripts used to compile and package the prebuilt libraries is named "compile-gmp-{arm,mips,x86}.sh".  The build procedure is documented therein.

An example of how to use this library is here: https://github.com/Rupan/GMPtest

Notes
-----

The testsuite cannot be easily run on a target device.  The autoconf system which runs the test binaries cannot simply be copied from the build host to the target device and run.  The next best thing is to copy the compiled binaries onto a target and run them by hand - but apparently this does not fully run the test suite.  Still, it is better than nothing since it exercises various GMP code paths and proves that the library will not crash when used in an APK.  prep-tests.sh and run-tests.sh are now provided; using them is left as an exercise to the reader.

An armeabi-v7a-neon build is now provided.  To use it, move the shared object from the armeabi-v7a-neon directory into the armeabi-v7a directory as e.g. "libgmp-neon.so".  You'll have to hack up Android.mk so it copies the new shared object together with the existing one.  Then the correct shared object must be selected at runtime by the application using the cpufeatures static library.  See the NDK documentation, or just stick with the armeabi-v7a build.

When using the "modern" 64-bit builds (i.e., arm64-v8a / x86_64 / mips64) your app must target, at a minimum, Android API level 21.

Build Reproducibility
---------------------

In order to reproduce the binaries hosted here, you'll need the following environment:

* Host operating system: Ubuntu 19.10, x86_64
* NDK toolchain: revision 21 (android-ndk-r21)
* GMP 6.2.0 source code decompressed in /tmp/gmp-6.2.0
