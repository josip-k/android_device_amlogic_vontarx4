#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

## Bluetooth
PRODUCT_PACKAGES += \
    BluetoothOverlayTarget \
    libbt-vendor

PRODUCT_SOONG_NAMESPACES += \
    hardware/broadcom/libbt

$(call soong_config_set,brcm_libbt,bdroid_buildcfg_include_dir,$(LOCAL_PATH)/bluetooth/include)
$(call soong_config_set,brcm_libbt,custom_bt_config,//$(LOCAL_PATH):vnd_vontarx4.txt)

## Init
PRODUCT_PACKAGES += \
    init.amlogic.wifi_buildin.rc

## Keylayout (IR)
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/keylayout/Vendor_0001_Product_0001.kl:$(TARGET_COPY_OUT_VENDOR)/usr/keylayout/Vendor_0001_Product_0001.kl

## Netflix
PRODUCT_PACKAGES += \
    NetflixConfig \
    NetflixConfigOverlayTarget

## Platform
TARGET_AMLOGIC_SOC := sc2

## Soong Namespaces
PRODUCT_SOONG_NAMESPACES += \
    $(LOCAL_PATH)

## Inherit from the common tree product makefile
$(call inherit-product, device/amlogic/ne-common/ne.mk)

## Inherit from the proprietary files makefile
$(call inherit-product, vendor/amlogic/vontarx4/vontarx4-vendor.mk)

# AOSP in-process KeyMint.
PRODUCT_PACKAGES += \
    android.hardware.security.keymint-service

# AIDL software gatekeeper (Amlogic GK + HIDL software GK are blanked in factory.mk).
PRODUCT_PACKAGES += \
    com.android.hardware.gatekeeper.nonsecure
