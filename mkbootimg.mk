# Huawei Enjoy 20 Pro (DVC-AN20) / MT6873
# 三分区 recovery 打包（参数来自原厂 split_img 回读）：
#   recovery.img        -> recovery         (47MB, 内核+dtb+dtbo+dummy ramdisk, header v2, base 0x40078000)
#   recovery_ramdisk.img -> recovery_ramdisk (32MB, 纯 ramdisk, header v0, base 0x80000000)
#   recovery_vendor.img  -> recovery_vendor  (16MB, dummy vendor, header v2, base 0x10078000)

LOCAL_PATH := $(call my-dir)

#
# recovery.img  (recovery 分区 = 内核)
#
INSTALLED_RECOVERYKERNELIMAGE_TARGET := $(PRODUCT_OUT)/recovery_kernel.img
RECOVERY_KERNEL_DUMMY_RAMDISK := $(PRODUCT_OUT)/recovery_kernel_dummy_ramdisk

$(RECOVERY_KERNEL_DUMMY_RAMDISK):
	$(hide) echo "dummy" > $@

# 原厂参数: base 0x40078000, header v2, ramdisk_offset 0x16f88000, second 0x00e88000, tags 0x0bc08000
TARGET_PREBUILT_DTB := $(DEVICE_PATH)/prebuilt/dtb.img
TARGET_PREBUILT_DTBO := $(DEVICE_PATH)/prebuilt/dtbo.img
INTERNAL_CUSTOM_RECOVERYIMAGE_ARGS := \
	--base 0x40078000 \
	--pagesize 2048 \
	--kernel $(INSTALLED_KERNEL_TARGET) \
	--ramdisk $(RECOVERY_KERNEL_DUMMY_RAMDISK) \
	--dtb $(TARGET_PREBUILT_DTB) \
	--recovery_dtbo $(TARGET_PREBUILT_DTBO) \
	--cmdline "bootopt=64S3,32N2,64N2 buildvariant=$(TARGET_BUILD_VARIANT)" \
	--kernel_offset 0x00008000 \
	--ramdisk_offset 0x16f88000 \
	--second_offset 0x00e88000 \
	--tags_offset 0x0bc08000 \
	--dtb_offset 0x0bc08000 \
	--header_version 2

.PHONY: recoveryimage
recoveryimage: recovery_ramdiskimage $(INSTALLED_RECOVERYKERNELIMAGE_TARGET) $(INSTALLED_RECOVERYIMAGE_TARGET)

$(INSTALLED_RECOVERYKERNELIMAGE_TARGET): $(MKBOOTIMG) $(recovery_ramdisk) $(INTERNAL_BOOTIMAGE_FILES) $(INSTALLED_KERNEL_TARGET) $(RECOVERY_KERNEL_DUMMY_RAMDISK)
	$(call pretty,"Target recovery kernel image: $@")
	$(hide) $(MKBOOTIMG) $(INTERNAL_CUSTOM_RECOVERYIMAGE_ARGS) $(INTERNAL_MKBOOTIMG_VERSION_ARGS) --output $@

# recovery.img = recovery_kernel.img 的副本（recovery 分区装内核）
$(INSTALLED_RECOVERYIMAGE_TARGET): $(INSTALLED_RECOVERYKERNELIMAGE_TARGET)
	$(hide) cp -f $< $@

INSTALLED_RADIOIMAGE_TARGET += $(INSTALLED_RECOVERYKERNELIMAGE_TARGET)

#
# recovery_ramdisk.img  (recovery_ramdisk 分区 = 纯 ramdisk)
#
INSTALLED_RECOVERY_RAMDISKIMAGE_TARGET := $(PRODUCT_OUT)/recovery_ramdisk.img

INTERNAL_CUSTOM_RECOVERY_RAMDISKIMAGE_ARGS := \
	--base 0x80000000 \
	--pagesize 2048 \
	--kernel /dev/null \
	--ramdisk $(recovery_ramdisk) \
	--cmdline "buildvariant=$(TARGET_BUILD_VARIANT)" \
	--kernel_offset 0x00008000 \
	--ramdisk_offset 0x02000000 \
	--second_offset 0x00f00000 \
	--tags_offset 0x00000100 \
	--header_version 0

.PHONY: recovery_ramdiskimage
recovery_ramdiskimage: recoveryvendorimage $(INSTALLED_RECOVERY_RAMDISKIMAGE_TARGET)

$(INSTALLED_RECOVERY_RAMDISKIMAGE_TARGET): $(MKBOOTIMG) $(recovery_ramdisk)
	@echo "----- Making recovery ramdisk image ------"
	$(hide) $(MKBOOTIMG) $(INTERNAL_CUSTOM_RECOVERY_RAMDISKIMAGE_ARGS) $(INTERNAL_MKBOOTIMG_VERSION_ARGS) --output $@
	$(hide) $(call assert-max-image-size,$@,$(BOARD_RECOVERYRAMDISK_PARTITION_SIZE))

INSTALLED_RADIOIMAGE_TARGET += $(INSTALLED_RECOVERY_RAMDISKIMAGE_TARGET)

#
# recovery_vendor.img  (recovery_vendor 分区)
#
INSTALLED_RECVENDOR_RAMDISK_TARGET := $(PRODUCT_OUT)/ramdisk-recovery_vendor.img
INSTALLED_RECVENDOR_RAMDISK_PLACEHOLDER_TARGET := $(PRODUCT_OUT)/ramdisk-recovery_vendor

$(INSTALLED_RECVENDOR_RAMDISK_PLACEHOLDER_TARGET):
	$(hide) mkdir -p $@/vendor
	$(hide) touch $@/vendor/placeholder

$(INSTALLED_RECVENDOR_RAMDISK_TARGET): $(MKBOOTFS) $(MINIGZIP) $(INSTALLED_RECVENDOR_RAMDISK_PLACEHOLDER_TARGET)
	$(call pretty,"Target recovery_vendor ramdisk image: $@")
	$(hide) $(MKBOOTFS) -d $(PRODUCT_OUT) $(INSTALLED_RECVENDOR_RAMDISK_PLACEHOLDER_TARGET) | $(MINIGZIP) > $@

INSTALLED_RECVENDORIMAGE_TARGET := $(PRODUCT_OUT)/recovery_vendor.img
# vendor 是占位镜像，用 header v0 避免 mkbootimg 强制要求 DTB
INTERNAL_CUSTOM_RECVENDORIMAGE_ARGS := \
	--base 0x10078000 \
	--pagesize 2048 \
	--kernel /dev/null \
	--ramdisk $(INSTALLED_RECVENDOR_RAMDISK_TARGET) \
	--cmdline "buildvariant=$(TARGET_BUILD_VARIANT)" \
	--kernel_offset 0x00008000 \
	--ramdisk_offset 0x16f88000 \
	--second_offset 0x00e88000 \
	--tags_offset 0x0bc08000 \
	--header_version 0

.PHONY: recoveryvendorimage
recoveryvendorimage: $(INSTALLED_RECVENDORIMAGE_TARGET)

$(INSTALLED_RECVENDORIMAGE_TARGET): $(MKBOOTIMG) $(INSTALLED_RECVENDOR_RAMDISK_TARGET)
	$(call pretty,"Target recovery_vendor image: $@")
	$(hide) $(MKBOOTIMG) $(INTERNAL_CUSTOM_RECVENDORIMAGE_ARGS) $(INTERNAL_MKBOOTIMG_VERSION_ARGS) --output $@
	$(hide) $(call assert-max-image-size,$@,$(BOARD_RECVENDORIMAGE_PARTITION_SIZE))

INSTALLED_RADIOIMAGE_TARGET += $(INSTALLED_RECVENDORIMAGE_TARGET)
