#
# Huawei Enjoy 20 Pro (DVC-AN20) / MT6873
# TWRP product makefile — aosp 系 (twrp-11 及更新的 minimal manifest)
#

LOCAL_PATH := device/huawei/enjoy20pro

$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/aosp_base.mk)

# TWRP 公共配置 (aosp 系)
$(call inherit-product, vendor/twrp/config/common.mk)

$(call inherit-product, device/huawei/enjoy20pro/device.mk)

PRODUCT_DEVICE := enjoy20pro
PRODUCT_NAME := twrp_enjoy20pro
PRODUCT_BRAND := HUAWEI
PRODUCT_MODEL := Huawei Enjoy20 pro
PRODUCT_MANUFACTURER := HUAWEI
