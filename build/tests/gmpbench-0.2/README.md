GMPbench 0.2 for Android

=== Environment ===

The binaries for GMPbench version 0.2 should be compiled for Android as follows:

  arm-linux-androideabi-gcc -O3 -fomit-frame-pointer foo.c -o foo -lgmp

The toolchain should be extracted from the Android NDK r8c as follows:

  ${NDK}/build/tools/make-standalone-toolchain.sh --toolchain=arm-linux-androideabi-4.6 --platform=android-9 --install-dir=/tmp/android-9-bin

=== Running ===

* Compile the source files as listed above.  Refer to the official GMPbench source for details.
* The 'runbench' script as well as all binaries should be copied to the target device.
* Run the script, then copy all RES-* files from the device back to your host system.
* The 'printbench' script should be used on the host machine with the RUN-* files to generate the report.
* You will have to re-link each test application for all ABIs prior to running them.
* Each test run takes a little over 8 minutes on a Galaxy Nexus.
* Informal tests on a Galaxy Nexus indicate approximately a 20% speedup between armeabi and armeabi-v7a builds.
