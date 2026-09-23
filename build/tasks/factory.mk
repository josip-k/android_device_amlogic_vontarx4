#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

ifneq ($(filter vontarx4,$(TARGET_DEVICE)),)

FACTORY_PATH := device/amlogic/vontarx4/factory

PRODUCT_UPGRADE_OUT := $(PRODUCT_OUT)/upgrade
PACKAGE_CONFIG_FILE := $(PRODUCT_UPGRADE_OUT)/image.cfg
# Host aml_image_packer writes truncated VERIFY strings ("d6" instead of
# "sha1sum <hash>"), which makes TPL `oem verify` fail with argc < 3.
# This is the same binary the old tree packed flashable images with; its
# -r already produces a v2 image.
AML_IMAGE_TOOL := $(FACTORY_PATH)/aml_image_v2_packer

INSTALLED_AML_UPGRADE_PACKAGE_TARGET := $(PRODUCT_OUT)/aml_upgrade_package.img

# USB TPL disk_initial looks up AML_ entries as chipset/platform/rev.
# Stock U-Boot matches sc2/ah212/2g and sc2/ah212/4g in this gzipped blob.
# The 5.15 kernel DTB uses amlogic-dt-id "sc2_s905x4_ah212", which becomes
# sc2/s905x4/ah212 and fails with "Failed at check dts".
AML_UPGRADE_DTB := $(FACTORY_PATH)/_aml_dtb.PARTITION
ifeq ($(wildcard $(AML_UPGRADE_DTB)),)
$(error $(AML_UPGRADE_DTB) is required for USB burn)
endif

# source:name copied into the upgrade directory
AML_UPGRADE_FILES := \
    $(FACTORY_PATH)/DDR.USB:DDR.USB \
    $(FACTORY_PATH)/aml_sdc_burn.UBOOT:aml_sdc_burn.UBOOT \
    $(FACTORY_PATH)/bootloader.img:bootloader.PARTITION \
    $(FACTORY_PATH)/odm_ext_a.PARTITION:odm_ext_a.PARTITION \
    $(PRODUCT_OUT)/logo.img:logo.PARTITION \
    $(FACTORY_PATH)/aml_sdc_burn.ini:aml_sdc_burn.ini \
    $(FACTORY_PATH)/usb_flow.aml:usb_flow.aml \
    $(FACTORY_PATH)/image.cfg:image.cfg \
    $(FACTORY_PATH)/platform.conf:platform.conf \
    $(PRODUCT_OUT)/boot.img:boot_a.PARTITION \
    $(AML_UPGRADE_DTB):_aml_dtb.PARTITION \
    $(PRODUCT_OUT)/dtbo.img:dtbo_a.PARTITION \
    $(PRODUCT_OUT)/super.img:super.PARTITION \
    $(PRODUCT_OUT)/vbmeta.img:vbmeta_a.PARTITION \
    $(PRODUCT_OUT)/vbmeta_system.img:vbmeta_system_a.PARTITION \
    $(PRODUCT_OUT)/vendor_boot.img:vendor_boot_a.PARTITION

aml-upgrade-src = $(word 1,$(subst :, ,$(1)))
aml-upgrade-dst = $(word 2,$(subst :, ,$(1)))

define aml-copy-upgrade-file
$(hide) $(ACP) $(1) $(PRODUCT_UPGRADE_OUT)/$(2)

endef

# ne-common owns fstab.amlogic in Soong (soong_namespace blocks overrides).
# Replace oem AVB / first-stage-required entries after that copy, before pack.
VONTARX4_FSTAB_SRC := device/amlogic/vontarx4/init/fstab.amlogic
VONTARX4_FSTAB_RAMDISK := $(PRODUCT_OUT)/vendor_ramdisk/first_stage_ramdisk/system/etc/fstab.amlogic
VONTARX4_FSTAB_VENDOR := $(PRODUCT_OUT)/vendor/etc/fstab.amlogic
VONTARX4_FSTAB_STAMP := $(PRODUCT_OUT)/obj/PACKAGING/vontarx4_fstab/replaced

$(VONTARX4_FSTAB_STAMP): $(VONTARX4_FSTAB_SRC) $(VONTARX4_FSTAB_RAMDISK) $(VONTARX4_FSTAB_VENDOR)
	$(hide) cp -f $(VONTARX4_FSTAB_SRC) $(VONTARX4_FSTAB_RAMDISK)
	$(hide) cp -f $(VONTARX4_FSTAB_SRC) $(VONTARX4_FSTAB_VENDOR)
	$(hide) mkdir -p $(dir $@)
	$(hide) touch $@

$(PRODUCT_OUT)/vendor_boot.img: $(VONTARX4_FSTAB_STAMP)
$(PRODUCT_OUT)/vendor.img: $(VONTARX4_FSTAB_STAMP)

# The Amlogic gatekeeper HAL comes from ne-common, which must stay untouched,
# and inherit-product only leaves an INHERIT_TAG marker in PRODUCT_PACKAGES at
# the point device.mk runs, so it cannot be filtered out. Two
# IGatekeeper/default fragments would blank the device VINTF manifest, so
# overwrite the fragment and rc in place instead. Do not delete the files:
# vendor.img's file_list still names them. amlogic.mk also installs HIDL
# software gatekeeper; blank that too so only the AIDL nonsecure APEX remains.
# tee_hdcp.rc is the same story: the daemon lives in ne-common, but TA
# ff2a4bea panics on unmatched RPMB, so do not start it. Do not add stub
# files under device/.../init or vintf.
VONTARX4_GATEKEEPER_STAMP := $(PRODUCT_OUT)/obj/PACKAGING/vontarx4_gatekeeper/replaced
VONTARX4_AML_GK_XML := $(PRODUCT_OUT)/vendor/etc/vintf/manifest/android.hardware.gatekeeper-service.amlogic.xml
VONTARX4_AML_GK_RC := $(PRODUCT_OUT)/vendor/etc/init/android.hardware.gatekeeper-service.amlogic.rc
VONTARX4_SW_GK_XML := $(PRODUCT_OUT)/vendor/etc/vintf/manifest/android.hardware.gatekeeper@1.0-service.software.xml
VONTARX4_SW_GK_RC := $(PRODUCT_OUT)/vendor/etc/init/android.hardware.gatekeeper@1.0-service.software.rc
VONTARX4_TEE_HDCP_RC := $(PRODUCT_OUT)/vendor/etc/init/tee_hdcp.rc
VONTARX4_HDCP_TA := $(PRODUCT_OUT)/vendor/lib/teetz/ff2a4bea-ef6d-11e6-89cc-d4ae52a7b3b3.ta

$(VONTARX4_GATEKEEPER_STAMP): $(VONTARX4_AML_GK_XML) $(VONTARX4_AML_GK_RC) $(VONTARX4_SW_GK_XML) $(VONTARX4_SW_GK_RC) $(VONTARX4_TEE_HDCP_RC)
	$(hide) printf '%s\n' '<manifest version="1.0" type="device">' '</manifest>' > $(VONTARX4_AML_GK_XML)
	$(hide) printf '%s\n' '# Disabled: opens TA 2088528d, not available on this board.' > $(VONTARX4_AML_GK_RC)
	$(hide) printf '%s\n' '<manifest version="1.0" type="device">' '</manifest>' > $(VONTARX4_SW_GK_XML)
	$(hide) printf '%s\n' '# Disabled: HIDL software GK; AIDL nonsecure APEX is IGatekeeper/default.' > $(VONTARX4_SW_GK_RC)
	$(hide) printf '%s\n' '# Disabled: tee_hdcp TA ff2a4bea panics on unmatched RPMB.' > $(VONTARX4_TEE_HDCP_RC)
	$(hide) rm -f $(VONTARX4_HDCP_TA)
	$(hide) mkdir -p $(dir $@)
	$(hide) touch $@

$(PRODUCT_OUT)/vendor.img: $(VONTARX4_GATEKEEPER_STAMP)

# ne-common's prebuilt amlogic_fbc_lib.ko has a module_layout ABI mismatch
# against this 5.15 GKI. It is not in the device modules.load lists; the
# media rc still insmods it. Comment that out without editing ne-common.
VONTARX4_FBC_STAMP := $(PRODUCT_OUT)/obj/PACKAGING/vontarx4_fbc/replaced
VONTARX4_MEDIA_RC := $(PRODUCT_OUT)/vendor/etc/init/hw/init.amlogic.media.rc

$(VONTARX4_FBC_STAMP): $(VONTARX4_MEDIA_RC)
	$(hide) sed -i '/insmod \/vendor\/lib\/modules\/amlogic_fbc_lib.ko/s|^|# |' $(VONTARX4_MEDIA_RC)
	$(hide) mkdir -p $(dir $@)
	$(hide) touch $@

$(PRODUCT_OUT)/vendor.img: $(VONTARX4_FBC_STAMP)

$(INSTALLED_AML_UPGRADE_PACKAGE_TARGET): $(foreach f,$(AML_UPGRADE_FILES),$(call aml-upgrade-src,$(f))) $(ACP) $(AML_IMAGE_TOOL)
	$(hide) mkdir -p $(PRODUCT_UPGRADE_OUT)
	$(foreach f,$(AML_UPGRADE_FILES),$(call aml-copy-upgrade-file,$(call aml-upgrade-src,$(f)),$(call aml-upgrade-dst,$(f))))
	$(hide) $(AML_IMAGE_TOOL) -r $(PACKAGE_CONFIG_FILE) $(PRODUCT_UPGRADE_OUT)/ $@
	$(hide) rm -rf $(PRODUCT_UPGRADE_OUT)
	@echo " $@ created"

.PHONY: aml_upgrade
aml_upgrade: $(INSTALLED_AML_UPGRADE_PACKAGE_TARGET)

# Pack factory/bootloader.img from a regular fip/mk of sc2_vontarx4 plus stock
# BBST+BL2E+BL2X. Does not compile U-Boot.
.PHONY: bootloader
bootloader:
	device/amlogic/vontarx4/pack-bootloader.sh

endif
