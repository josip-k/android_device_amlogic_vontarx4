#
# Copyright (C) 2021-2023 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

TARGET_HAS_TEE := false

# Not set in time to check, so set before everything else
PRODUCT_IS_ATV := true

# Inherit some common AOSP stuff
$(call inherit-product, device/google/atv/products/atv_base.mk)

# Inherit some common Lineage stuff
$(call inherit-product, vendor/lineage/config/common_full_tv.mk)

# Inherit device configuration
$(call inherit-product, $(LOCAL_PATH)/device.mk)

## Device identifier. This must come after all inclusions
PRODUCT_BRAND := Khadas
PRODUCT_DEVICE := vontarx4
PRODUCT_GMS_CLIENTID_BASE := android-askey-tv
PRODUCT_MANUFACTURER := amlogic
PRODUCT_MODEL := VIM1S
PRODUCT_NAME := lineage_vontarx4

PRODUCT_BUILD_PROP_OVERRIDES += \
    PRODUCT_NAME=adt3 \
    PRIVATE_BUILD_DESC="adt3-user 13 TTT1.230205.001 9565391 release-keys"

BUILD_FINGERPRINT := ADT-3/adt3/adt3:13/TTT1.230205.001/9565391:user/release-keys
