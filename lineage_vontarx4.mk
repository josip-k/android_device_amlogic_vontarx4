#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

# Not set in time to check, so set before everything else
PRODUCT_IS_ATV := true

# Inherit some common AOSP stuff
$(call inherit-product, device/google/atv/products/atv_base.mk)

# Inherit some common Lineage stuff
$(call inherit-product, vendor/lineage/config/common_full_tv.mk)

# Inherit device configuration
$(call inherit-product, $(LOCAL_PATH)/device.mk)

## Device identifier. This must come after all inclusions
PRODUCT_BRAND := Amlogic
PRODUCT_DEVICE := vontarx4
PRODUCT_ATV_CLIENTID_BASE := ATV00100021
PRODUCT_GMS_CLIENTID_BASE := android-droid-tv
PRODUCT_MANUFACTURER := Amlogic
PRODUCT_MODEL := X4
PRODUCT_NAME := lineage_vontarx4

PRODUCT_BUILD_PROP_OVERRIDES += \
    BuildDesc="jarvis-user 14 URO4.260304.011.B1 15051976 release-keys" \
    BuildFingerprint=onn/jarvis/SNA:14/URO4.260304.011.B1/15051976:user/release-keys \
    SystemName=vontarx4
