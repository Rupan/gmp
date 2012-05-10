LOCAL_PATH := $(call my-dir)
include $(CLEAR_VARS)
LOCAL_MODULE := gmp

# possible future inclusion of the NEON shared object?
ifeq ($(TARGET_ARCH_ABI),armeabi-v7a)
  LOCAL_SRC_FILES := $(TARGET_ARCH_ABI)/libgmp.so
else
  LOCAL_SRC_FILES := $(TARGET_ARCH_ABI)/libgmp.so
endif

LOCAL_EXPORT_C_INCLUDES := $(LOCAL_PATH)/$(TARGET_ARCH_ABI)
include $(PREBUILT_SHARED_LIBRARY)
