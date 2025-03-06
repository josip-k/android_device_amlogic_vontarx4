#
# Copyright (C) 2021-2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

DEVICE_PATH := device/amlogic/vontarx4

## Bluetooth
BOARD_BLUETOOTH_BDROID_BUILDCFG_INCLUDE_DIR := $(DEVICE_PATH)/bluetooth/include
BOARD_CUSTOM_BT_CONFIG := $(DEVICE_PATH)/bluetooth/vnd_vontarx4.txt
BOARD_HAVE_BLUETOOTH := true
BOARD_HAVE_BLUETOOTH_BCM := true

## Bootloader
TARGET_BOOTLOADER_BOARD_NAME := vontarx4

## DTB
TARGET_DTB_NAME := vontarx4
TARGET_DTBO_NAME := android_overlay_dt

## Kernel
TARGET_KERNEL_CONFIG := lineage_vontarx4_defconfig

## Kernel modules
TARGET_KERNEL_EXT_MODULES := \
    dhd-driver/bcmdhd.101.10.361.x

## Partitions
BOARD_SUPER_PARTITION_SIZE := 2084569088

## Properties
TARGET_VENDOR_PROP += $(DEVICE_PATH)/vendor.prop

## Wi-Fi
BOARD_HOSTAPD_PRIVATE_LIB := lib_driver_cmd_bcmdhd
BOARD_WLAN_DEVICE := bcmdhd
BOARD_WPA_SUPPLICANT_DRIVER := NL80211
BOARD_WPA_SUPPLICANT_PRIVATE_LIB := lib_driver_cmd_bcmdhd
WIFI_DRIVER_FW_PATH_AP := "/vendor/etc/wifi/buildin/fw_bcm4356a2_ag_apsta.bin"
WIFI_DRIVER_FW_PATH_STA := "/vendor/etc/wifi/buildin/fw_bcm4356a2_ag.bin"
WIFI_DRIVER_FW_PATH_PARAM := "/sys/module/dhd/parameters/firmware_path"
WPA_SUPPLICANT_VERSION := VER_0_8_X

## Include the common tree BoardConfig makefile
include device/amlogic/ne-common/BoardConfigCommon.mk

## Include the proprietary BoardConfig makefile
include vendor/amlogic/vontarx4/BoardConfigVendor.mk
