LOCAL_PATH := $(call my-dir)

ifeq ($(TARGET_DEVICE),enjoy20pro)
include $(call all-subdir-makefiles,$(LOCAL_PATH))
endif
