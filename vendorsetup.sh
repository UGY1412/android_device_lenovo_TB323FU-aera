#
# AERA Recovery R1.0 environment setup for the Lenovo Legion Y700 Gen 5 (TB323FU)
#
# Modelled on the official AERA device trees (aera_config.mk / AERA_A16.sh).
# This file is sourced by build/envsetup.sh when the TB323FU product is
# selected. It only sets AERA_* build-time environment variables.
#
FDEVICE="TB323FU"

aera_get_target_device() {
local chkdev=$(echo "$BASH_SOURCE" | grep -w $FDEVICE)
   if [ -n "$chkdev" ]; then
      AERA_BUILD_DEVICE="$FDEVICE"
   else
      chkdev=$(set | grep BASH_ARGV | grep -w $FDEVICE)
      [ -n "$chkdev" ] && AERA_BUILD_DEVICE="$FDEVICE"
   fi
}

if [ -z "$1" -a -z "$AERA_BUILD_DEVICE" ]; then
   aera_get_target_device
fi

if [ "$1" = "$FDEVICE" -o "$AERA_BUILD_DEVICE" = "$FDEVICE" ]; then
	export LC_ALL="C"
	# This device is A/B with a dedicated (non-slotted-BOOT) recovery partition.
	export AERA_AB_DEVICE=1
	export AERA_VIRTUAL_AB_DEVICE=1
	export AERA_USE_TAR_BINARY=1
	export AERA_USE_SED_BINARY=1
	export AERA_USE_LZ4_BINARY=1
	export AERA_USE_ZSTD_BINARY=1
	export AERA_USE_DATE_BINARY=1
	export AERA_DELETE_AROMAFM=1
	export AERA_VANILLA_BUILD=1
	export AERA_PRODUCT_PREFIX=AERA
	# Unofficial, self-built image (not an AERA-official device build).
	export AERA_BUILD_STATUS=Unofficial
	export AERA_BUILD_TYPE=Beta
	export AERA_USE_GREP_BINARY=1
	export AERA_USE_BUSYBOX_BINARY=1
	export AERA_USE_XZ_UTILS=1
	export AERA_ALLOW_EARLY_SETTINGS_LOAD=1
	# AERA's default prebuilt magiskboot (vendor/recovery/prebuilt/arm64/magiskboot)
	# is ELF-aligned 4 KiB (0x1000) and runs on this 4 KiB-page kernel; the
	# "_updated" variant is ELF-aligned 16 KiB (0x4000) and must NOT be used here.
	export AERA_USE_UPDATED_MAGISKBOOT=0
	# Keep magiskboot for image repacking, but do not bundle the Magisk addon.
	export AERA_DELETE_MAGISK_ADDON=1
	export AERA_USE_FSCK_EROFS_BINARY=1
	export AERA_USE_PATCHELF_BINARY=1
	export AERA_SETTINGS_ROOT_DIRECTORY=/data/recovery
	export AERA_MISCELLANEOUS_ROOT_DIRECTORY=/sdcard

	# For Lenovo Legion Y700 Gen 5
	export TARGET_DEVICE_ALT="TB323FU"
	export AERA_TARGET_DEVICES="$TARGET_DEVICE_ALT"
	# NOTE: do NOT set AERA_USE_DMSETUP (the device tree uses TW_USE_DMCTL),
	# AERA_ENABLE_ROOT_MANAGER (Magisk is used, not KernelSU/SukiSU), or
	# AERA_ENABLE_MOBILE_DATA stays disabled (no recovery modem data path yet);
	# AERA_ENABLE_WLAN is enabled in aera_TB323FU.mk with WCN786x modules
	# staged from the stock vendor_dlkm and loaded by aera-wlan-up.sh.
	# AERA begins at R1.0; do not append a legacy maintainer patch suffix.
	unset AERA_MAINTAINER_PATCH_VERSION
fi
#
