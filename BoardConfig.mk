#
# Copyright (C) 2025 The Android Open Source Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Building with minimal manifest
ALLOW_MISSING_DEPENDENCIES                      := true
BUILD_BROKEN_DUP_RULES                          := true
BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES    := true

BUILD_BROKEN_NINJA_USES_ENV_VARS    += RTIC_MPGEN
BUILD_BROKEN_PLUGIN_VALIDATION      := soong-libaosprecovery_defaults soong-libguitwrp_defaults soong-libminuitwrp_defaults soong-vold_defaults

# Architecture
TARGET_ARCH                 := arm64
TARGET_ARCH_VARIANT         := armv8-a
TARGET_CPU_ABI              := arm64-v8a
TARGET_CPU_VARIANT          := oryon

# A/B
AB_OTA_PARTITIONS := \
    boot \
    dataext \
    dtbo \
    init_boot \
    odm \
    recovery \
    system_dlkm \
    vbmeta \
    vendor \
    vendor_boot \
    vendor_dlkm

# Bootloader
PRODUCT_PLATFORM                := kaanapali
TARGET_BOOTLOADER_BOARD_NAME    := Kaanapali

# Crypto
BOARD_USES_METADATA_PARTITION   := true
BOARD_USES_QCOM_FBE_DECRYPTION  := true
TW_INCLUDE_CRYPTO               := true
TW_INCLUDE_CRYPTO_FBE           := true
TW_INCLUDE_FBE_METADATA_DECRYPT := true
TW_USE_FSCRYPT_POLICY           := 2
#TW_INCLUDE_OMAPI                := true
#TW_OMAPI_UUID                   := 636F6D2E6E78702E7365637572697479 

# Debug
TARGET_USES_LOGD                := true
TWRP_INCLUDE_LOGCAT             := true
TARGET_RECOVERY_DEVICE_MODULES  += debuggerd
TARGET_RECOVERY_DEVICE_MODULES  += strace
RECOVERY_BINARY_SOURCE_FILES    += $(TARGET_OUT_EXECUTABLES)/debuggerd
RECOVERY_BINARY_SOURCE_FILES    += $(TARGET_OUT_EXECUTABLES)/strace

# File systems
TARGET_USERIMAGES_USE_EXT4  := true
TARGET_USERIMAGES_USE_F2FS  := true
TW_USE_DMCTL               := true

# Init
#TARGET_INIT_VENDOR_LIB          := //$(DEVICE_PATH):libinit_oplus_sm87xx
#TARGET_RECOVERY_DEVICE_MODULES  := libinit_oplus_sm87xx

# Kernel
BOARD_KERNEL_IMAGE_NAME     := Image
BOARD_BOOT_HEADER_VERSION   := 4
BOARD_KERNEL_PAGESIZE       := 4096
BOARD_MKBOOTIMG_ARGS        += --header_version $(BOARD_BOOT_HEADER_VERSION)
BOARD_MKBOOTIMG_ARGS        += --pagesize $(BOARD_KERNEL_PAGESIZE)

BOARD_RAMDISK_USE_LZ4       := true

# Partitions
BOARD_PROPERTY_OVERRIDES_SPLIT_ENABLED  := true
BOARD_RECOVERYIMAGE_PARTITION_SIZE      := 104857600

BOARD_SUPER_PARTITION_SIZE := 21474836480
BOARD_SUPER_PARTITION_GROUPS := qti_dynamic_partitions
BOARD_QTI_DYNAMIC_PARTITIONS_PARTITION_LIST := system odm product system_ext vendor vendor_dlkm
BOARD_QTI_DYNAMIC_PARTITIONS_SIZE := 21470642176

BOARD_ODMIMAGE_FILE_SYSTEM_TYPE := ext4
TARGET_COPY_OUT_ODM             := odm
TARGET_COPY_OUT_VENDOR          := vendor

# Platform
TARGET_BOARD_PLATFORM   := sm8850
QCOM_BOARD_PLATFORMS    += sm8850

# Recovery
BOARD_EXCLUDE_KERNEL_FROM_RECOVERY_IMAGE    := true
TARGET_RECOVERY_PIXEL_FORMAT                := RGBX_8888
TW_INCLUDE_FASTBOOTD                        := true

# Tool
TW_ENABLE_ALL_PARTITION_TOOLS := true
TW_INCLUDE_7ZA                := true
TW_INCLUDE_REPACKTOOLS        := true
TW_INCLUDE_RESETPROP          := true
TW_USE_TOOLBOX                := true

# TWRP display
TW_BRIGHTNESS_PATH      := /sys/class/backlight/panel0-backlight/brightness
TW_DEFAULT_BRIGHTNESS   := 2000
TW_FRAMERATE            := 60
TW_MAX_BRIGHTNESS       := 4095
TW_SCREEN_BLANK_ON_BOOT := true
ifeq ($(USE_LANDSCAPE),true)
	RECOVERY_TOUCHSCREEN_FLIP_Y := true
	RECOVERY_TOUCHSCREEN_SWAP_XY := true
	TW_THEME := landscape_hdpi
	TW_ROTATION := 90
else
	RECOVERY_TOUCHSCREEN_FLIP_Y := false
	RECOVERY_TOUCHSCREEN_SWAP_XY := false
	TW_THEME := portrait_hdpi
	TW_ROTATION := 0
endif

# TWRP file system
RECOVERY_SDCARD_ON_DATA     := true
TARGET_USES_MKE2FS          := true
TW_ENABLE_FS_COMPRESSION    := true
TW_INCLUDE_FUSE_NTFS        := true
TW_INCLUDE_NTFS_3G          := true
TW_NO_EXFAT_FUSE            := true

# Version
PLATFORM_VERSION                := 99.87.36
PLATFORM_VERSION_LAST_STABLE    := $(PLATFORM_VERSION)
PLATFORM_SECURITY_PATCH         := 2099-12-31
VENDOR_SECURITY_PATCH           := $(PLATFORM_SECURITY_PATCH)
ifeq ($(TW_DEVICE_VERSION),)
TW_DEVICE_VERSION               := TB323FU
endif

# Verified Boot
BOARD_AVB_ENABLE := true

# Vibrator
TW_SUPPORT_INPUT_AIDL_HAPTICS := true

# Other TWRP Configurations
TARGET_RECOVERY_QCOM_RTC_FIX            := true
TW_DEFAULT_LANGUAGE                     := en
TW_EXCLUDE_APEX                         := true
TW_EXCLUDE_DEFAULT_USB_INIT             := true
TW_EXTRA_LANGUAGES                      := true
TW_LOAD_VENDOR_MODULES                  := "adsp_loader_dlkm.ko stm_st54se_gpio.ko nxp-nci.ko spcom.ko spss_utils.ko q6_notifier_dlkm.ko spf_core_dlkm.ko audpkt_ion_dlkm.ko gpr_dlkm.ko audio_pkt_dlkm.ko q6_dlkm.ko audio_prm_dlkm.ko q6_pdr_dlkm.ko pinctrl_lpi_dlkm.ko swr_dlkm.ko swr_ctrl_dlkm.ko snd_event_dlkm.ko wcd_core_dlkm.ko mbhc_dlkm.ko sdca_registers_dlkm.ko wcd9xxx_dlkm.ko stub_dlkm.ko swr_dmic_dlkm.ko swr_haptics_dlkm.ko hdmi_dlkm.ko lpass_cdc_wsa2_macro_dlkm.ko lpass_cdc_wsa_macro_dlkm.ko lpass_cdc_va_macro_dlkm.ko lpass_cdc_rx_macro_dlkm.ko lpass_cdc_tx_macro_dlkm.ko lpass_cdc_dlkm.ko wsa884x_dlkm.ko wsa883x_dlkm.ko wcd938x_dlkm.ko wcd938x_slave_dlkm.ko wcd939x_dlkm.ko wcd939x_slave_dlkm.ko wcd9378_dlkm.ko wcd9378_slave_dlkm.ko simple_amp_dlkm.ko frpc-adsprpc.ko rproc_qcom_common.ko qcom_q6v5.ko qcom_q6v5_pas.ko qcom_sysmon.ko machine_dlkm.ko hqsysfs.ko aw882xx_dlkm.ko btfmcodec.ko spk_id_dlkm.ko btpower.ko btfm_slim_codec.ko bt_fm_swr.ko lpass_bt_swr_dlkm.ko"
TW_LOAD_VENDOR_MODULES_EXCLUDE_GKI      := true
TW_USE_SERIALNO_PROPERTY_FOR_DEVICE_ID  := true
TW_NO_NETWORK                           := true
TW_HAS_EDL_MODE                         := true
TW_SKIP_ADDITIONAL_FSTAB                := true
TW_INPUT_BLACKLIST                      := "hbtp_vm"

# TB323FU Android 16 recovery crypto fallback:
# AIDL KeyMint V4 is the real service; force a non-empty legacy TWRP helper
# property so old Keymaster-version detection cannot reset it to blank.
TW_FORCE_KEYMASTER_VER := true

# ---------------------------------------------------------------------------
# OrangeFox R12 (fox_16.0) integration
# ---------------------------------------------------------------------------
# This device tree started as the validated TWRP baseline
# (isrgish/TB323FU-TWRP, fix3b). Everything above is that baseline and is kept
# byte-for-byte where possible; the variables below exist only because
# OrangeFox needs them, or because they change OrangeFox defaults that would
# otherwise contradict the validated baseline.

# OrangeFox *requires* OF_DEFAULT_KEYMASTER_VERSION whenever
# TW_FORCE_KEYMASTER_VER is true (orangefox.mk: $(error ...)).
# twrp.cpp does SetProperty("keymaster_ver", OF_DEFAULT_KEYMASTER_VERSION), so
# this reproduces the baseline's system.prop "keymaster_ver=4.x" and the
# partitionmanager fallback to legacy Keymaster 4.x for decryption.
OF_DEFAULT_KEYMASTER_VERSION := 4.x

# A/B device that also owns a dedicated recovery partition, with the custom
# recovery flashed to recovery_b only (recovery_a stays stock).
OF_AB_DEVICE_WITH_RECOVERY_PARTITION := 1

# Lenovo device, not Xiaomi: keep OrangeFox's MIUI/HyperOS OTA machinery out of
# the flash/backup paths so behaviour matches the validated TWRP baseline.
OF_DISABLE_MIUI_SPECIFIC_FEATURES := 1

# Required for the "mount USB hard drive" feature: without it OrangeFox sets
# TW_NO_USB_STORAGE := true. (The microSD entry comes from
# recovery/root/system/etc/twrp.flags -> /external_sd on /dev/block/mmcblk1p1.)
OF_ENABLE_USB_STORAGE := 1

# Display: the 8.8" panel is 3040x1904 native (landscape) and the recovery UI is
# portrait, i.e. 1904 wide by 3040 tall -- see TW_THEME/TW_ROTATION above.
# OrangeFox defaults OF_SCREEN_H to 1920, which would misplace its status bar.
OF_SCREEN_H := 3040
OF_STATUS_H := 114

# Ramdisk compression must match BOARD_RAMDISK_USE_LZ4 above, or OrangeFox's
# boot-image repacking would change the ramdisk format.
OF_USE_LZ4_COMPRESSION := 1

# China: POSIX TZ string (no DST).
OF_DEFAULT_TIMEZONE := CST-8

OF_MAINTAINER := TB323FU-unofficial

# ---------------------------------------------------------------------------
# AERA Recovery R1.0 integration (public AERA_* configuration namespace)
# ---------------------------------------------------------------------------
# AERA's build system translates the public AERA_* namespace back to the
# legacy backend variable names in bootable/recovery/aera_config.mk (included
# from build/make/core/config.mk after envsetup.mk has parsed the product and
# board configuration).  These are therefore intentional dual-writes of the
# validated TWRP/OrangeFox values above; they must stay in sync with them.
AERA_AB_DEVICE_WITH_RECOVERY_PARTITION := 1
AERA_DEFAULT_KEYMASTER_VERSION := 4.x
AERA_FORCE_KEYMASTER_VER := true
AERA_INCLUDE_CRYPTO := true
AERA_INCLUDE_CRYPTO_FBE := true
AERA_INCLUDE_FBE_METADATA_DECRYPT := true
AERA_USE_FSCRYPT_POLICY := 2
AERA_USE_DMCTL := true
AERA_INCLUDE_FASTBOOTD := true
AERA_INCLUDE_LOGCAT := true
AERA_INCLUDE_REPACKTOOLS := true
AERA_INCLUDE_RESETPROP := true
AERA_INCLUDE_LIBRESETPROP := true
AERA_INCLUDE_LPDUMP := true
AERA_INCLUDE_LPTOOLS := true
AERA_USE_TOOLBOX := true
AERA_SKIP_ADDITIONAL_FSTAB := true
AERA_EXCLUDE_APEX := true
AERA_EXCLUDE_DEFAULT_USB_INIT := true
# 中文化：默认简体中文，并打包全部 33 种语言（上游 AERA 设备树同款配置）。
AERA_DEFAULT_LANGUAGE := zh_CN
AERA_EXTRA_LANGUAGES := true
AERA_BRIGHTNESS_PATH := /sys/class/backlight/panel0-backlight/brightness
AERA_DEFAULT_BRIGHTNESS := 2000
AERA_MAX_BRIGHTNESS := 4095
AERA_FRAMERATE := 60
AERA_THEME := portrait_hdpi
AERA_SCREEN_BLANK_ON_BOOT := true
AERA_DEVICE_VERSION := TB323FU
AERA_LOAD_VENDOR_MODULES := "adsp_loader_dlkm.ko stm_st54se_gpio.ko nxp-nci.ko spcom.ko spss_utils.ko q6_notifier_dlkm.ko spf_core_dlkm.ko audpkt_ion_dlkm.ko gpr_dlkm.ko audio_pkt_dlkm.ko q6_dlkm.ko audio_prm_dlkm.ko q6_pdr_dlkm.ko pinctrl_lpi_dlkm.ko swr_dlkm.ko swr_ctrl_dlkm.ko snd_event_dlkm.ko wcd_core_dlkm.ko mbhc_dlkm.ko sdca_registers_dlkm.ko wcd9xxx_dlkm.ko stub_dlkm.ko swr_dmic_dlkm.ko swr_haptics_dlkm.ko hdmi_dlkm.ko lpass_cdc_wsa2_macro_dlkm.ko lpass_cdc_wsa_macro_dlkm.ko lpass_cdc_va_macro_dlkm.ko lpass_cdc_rx_macro_dlkm.ko lpass_cdc_tx_macro_dlkm.ko lpass_cdc_dlkm.ko wsa884x_dlkm.ko wsa883x_dlkm.ko wcd938x_dlkm.ko wcd938x_slave_dlkm.ko wcd939x_dlkm.ko wcd939x_slave_dlkm.ko wcd9378_dlkm.ko wcd9378_slave_dlkm.ko simple_amp_dlkm.ko frpc-adsprpc.ko rproc_qcom_common.ko qcom_q6v5.ko qcom_q6v5_pas.ko qcom_sysmon.ko machine_dlkm.ko hqsysfs.ko aw882xx_dlkm.ko btfmcodec.ko spk_id_dlkm.ko btpower.ko btfm_slim_codec.ko bt_fm_swr.ko lpass_bt_swr_dlkm.ko"
AERA_LOAD_VENDOR_MODULES_EXCLUDE_GKI := true
AERA_USE_LZ4_COMPRESSION := 1
AERA_DEFAULT_TIMEZONE := CST-8
AERA_DISABLE_MIUI_SPECIFIC_FEATURES := 1
AERA_ENABLE_USB_STORAGE := 1
AERA_SUPPORT_INPUT_AIDL_HAPTICS := true
AERA_USE_SERIALNO_PROPERTY_FOR_DEVICE_ID := true
AERA_INPUT_BLACKLIST := "hbtp_vm"
AERA_UI_ADAPTIVE_RESOLUTION := false
AERA_ENABLE_ALL_PARTITION_TOOLS := 1
AERA_ENABLE_FS_COMPRESSION := 1
AERA_INCLUDE_FUSE_NTFS := true
AERA_INCLUDE_NTFS_3G := true
AERA_NO_EXFAT_FUSE := true
AERA_INCLUDE_7ZA := true
AERA_USE_MAGISKBOOT := 1
