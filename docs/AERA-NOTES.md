# AERA Recovery R1.0 on TB323FU — build, blobs and decryption notes / AERA Recovery R1.0（TB323FU）构建、blob 与解密说明

Last updated / 最后更新: 2026-11-12

This file collects the AERA-specific knowledge needed to rebuild, extend and
audit this device tree. It is bilingual: the English section is followed by the
Chinese section with the same structure and the same data.

本文件汇总重建、扩展与审计本设备树所需的 AERA 专用知识。文件为双语：英文部分
之后是结构与数据完全一致的中文部分。

---

# English

## 1. What this repository is (and what it is not)

This repository is the **AERA device tree** for TB323FU: the AERA product
configuration, the device/recovery configuration inherited from the validated
TB323FU baseline, the optional audio/Wi-Fi integration sources, and the
hash-pinned proprietary-file manifests.

It is **not**:

- an AERA official device build or an AERA fork of the recovery source;
- the system/ROM device tree — that is the main TB323FU repository
  (`LineageOS 24` / Android 17);
- a carrier of proprietary binaries: all Lenovo/Qualcomm payload bytes,
  including the stock audio/Wi-Fi runtime, are acquired separately.

The inherited baseline documents (`docs/KNOWN_GOOD.md`, `docs/BUILDING.md`,
`docs/PROPRIETARY_FILES.md`, `docs/DECRYPTION_TROUBLESHOOTING.md`,
`docs/PUBLICATION_STATUS.md`, `TREE_PROVENANCE.md`) describe the validated
TWRP/OrangeFox baseline. They remain valid as reference for the device and for
the payload manifests, but they are not AERA-specific release notes.

## 2. Relationship to the main repository and the sibling recovery repository

| Repository | Role | Build system |
| --- | --- | --- |
| `android_device_lenovo_TB323FU` (main) | LineageOS 24 / Android 17 **system** device tree for TB323FU: ROM build, boot chain, hardware enablement, system-level root-cause documentation | LineageOS 24 manifest |
| `android_device_lenovo_TB323FU-orangefox` (sibling) | TWRP 3.7.1 (Android 16) + OrangeFox R12.0 (Android 17) **recovery** device tree; the source of the validated recovery baseline and the Android 17 decryption correction | TWRP-Test `twrp-16.0` manifest; OrangeFox `fox_16.0` manifest |
| this repository (`...-aera`) | **AERA Recovery R1.0** device tree: AERA product layer on the same baseline, optional audio/Wi-Fi, A17 decryption correction carried forward | AERA `aera-16.0` manifest |

Shared material and boundaries:

- The **103-file proprietary payload manifest**
  (`proprietary-*.tsv`, `scripts/acquire-proprietary-files.sh`) is shared with
  the sibling recovery repository: 25 files from matching TB323FU stock
  firmware and 78 from the public polygraphene TB322FC donor tree, pinned by
  size and SHA-256. It is not the system ROM payload.
- The **Android 17 TEE/decryption correction** was developed on the recovery
  line and is carried into this tree; see §4.
- This tree **cannot be built from the main LineageOS tree**, and the main tree
  cannot be built from this recovery tree: different manifests, different
  products. Only the device configuration concepts and the payload manifests
  are shared.
- The device can hold only one recovery per slot; the project validated AERA on
  `recovery_a` and kept the OrangeFox R12.0 image on `recovery_b` as a rollback
  path.

## 3. Build essentials

### 3.1 Source tree

- Manifest: `https://github.com/AERA-Recovery/android_manifest`, branch
  `aera-16.0` (AOSP 16 based).
- Sync:

  ```bash
  repo init -u https://github.com/AERA-Recovery/android_manifest.git -b aera-16.0
  repo sync -c --force-sync --no-clone-bundle --no-tags -j$(nproc)
  ```

- Device tree placement: copy this repository to
  `device/lenovo/TB323FU/` in the source checkout (remove `.git` first). The
  project also stripped the `artifacts/` directory from its working copy; the
  public repository contains no build artifacts.
- Product: `twrp_TB323FU-bp2a-eng`; build command: `mka adbd recoveryimage`.
- Clean before each rebuild: `rm -rf out/target/product/TB323FU`. A reused
  product output directory makes the ramdisk packer fail on stale symlinks
  (e.g. `root/odm/etc`).

Disk and memory: a synced AERA tree and its output directory occupy tens of
gigabytes (the project synced 411 projects including repo metadata); plan for a
large Linux build host and use conservative parallelism if RAM is limited.

### 3.2 Product and environment configuration

`aera_TB323FU.mk` (AERA product layer) and `vendorsetup.sh` (build environment)
carry the port-specific configuration:

| Setting | Value / effect |
| --- | --- |
| `AERA_AB_DEVICE`, `AERA_VIRTUAL_AB_DEVICE` | `1`: A/B with virtual A/B |
| `AERA_AB_DEVICE_WITH_RECOVERY_PARTITION` | `1`: A/B device that also owns a dedicated, non-slotted recovery partition |
| `AERA_SCREEN_H` | `2280`: AERA UI converts this to a 1440-wide logical canvas with `logical_height = AERA_SCREEN_H * 4 / 3 = 3040`; `DisplayTransform::Adaptive` then selects scale 1000/1000, so the UI is composited 1:1 with zero resampling and ~232 px side bands are filled with the page background. True full-width 1904 × 3040 rendering needs a horizontal scene reflow (R2, not in this tree) |
| `AERA_STATUS_H` | `114` |
| `AERA_DEFAULT_LANGUAGE`, `AERA_EXTRA_LANGUAGES` | `zh_CN`, `true`: simplified Chinese default, all 33 languages packaged, CJK font fallback |
| `AERA_USE_LZ4_COMPRESSION` | `1`: LZ4 ramdisk (matches the baseline boot header/packing) |
| `AERA_USE_UPDATED_MAGISKBOOT` | `0` (deliberately): the default AERA prebuilt `magiskboot` is 4 KiB ELF aligned and runs on this 4 KiB-page kernel; the `_updated` variant is 16 KiB aligned and must not be used |
| `AERA_DELETE_MAGISK_ADDON` | `1`: keep `magiskboot` for image repacking, do not bundle the Magisk addon |
| `AERA_ENABLE_ROOT_MANAGER` | `1`: Root Manager UI assets only; no KernelSU/SukiSU patching was performed on the Magisk-rooted device |
| `AERA_ENABLE_EFISP`, `AERA_ENABLE_ABL_PRESERVATION` | `1`: EFISP is visible and backup-able; ABL preservation is offered by the install zip (not device-validated) |
| `AERA_ENABLE_WLAN` | `1`: Wi-Fi source integration; stock driver modules must be staged (see §6) |
| `AERA_SETTINGS_ROOT_DIRECTORY`, `AERA_MISCELLANEOUS_ROOT_DIRECTORY` | `/data/recovery`, `/sdcard` |
| `AERA_BUILD_STATUS`, `AERA_BUILD_TYPE` | `Unofficial`, `Beta` |
| `AERA_CURRENT_BRANCH` | `aera-16.0`: branch label for the recovery banner (the source tree has no usable `.git` metadata if `.repo` project objects are pruned) |

Do not set `AERA_USE_DMSETUP` (the tree uses `TW_USE_DMCTL` / `AERA_USE_DMCTL`),
and keep `ro.aera.live_fastbootd` false (in-place live recovery ↔ fastbootd
transition is a known crash path; transition uses the BCB reboot path).

### 3.3 Image budget

- Recovery partition: `BOARD_RECOVERYIMAGE_PARTITION_SIZE := 104857600`
  (100 MiB), boot header v4, 4 KiB kernel page size, LZ4 ramdisk.
- Reference builds: the 2026-11-06 R1.0 fixes build had
  `ramdisk-recovery.img = 70,709,037 B`; the 2026-11-07 build with audio/Wi-Fi
  and the FBE fix had `ramdisk-recovery.img = 89,470,975 B` and a final image of
  exactly 104,857,600 B (AVB `Algorithm: NONE`).
- Always assert the produced `recovery.img` is ≤ 104,857,600 bytes. Enabling the
  optional audio/Wi-Fi material consumes a large part of the remaining budget;
  measure before adding more.

### 3.4 Recovery-source fixes are not in this repository

The AERA device tree is only half of the recovery build. The project also
applied fixes to the AERA recovery source tree (not in any of the TB323FU
repositories), including UI layout patches, the FBE storage unlock fix,
plugin-store download fixes and logcat stability fixes. Re-syncing the tree
discards them. This repository documents their scope and their device-visible
effects, but does not ship the source patches; treat a clean rebuild as
"R1.0 core functionality" rather than a byte-for-byte reproduction of the
2026-11-07 image.

### 3.5 Flashing and rollback

- Only fastbootd may write the recovery partition on this device; bootloader
  fastboot returns `remote: 'unknown command'`.
- The project flashed `recovery_a` only. `recovery_b` kept the OrangeFox R12.0
  image.
- Write failure `AdbWriteEndpointSync failed ... (121)` is recovered by a
  USB/ADB PnP reset and retry.
- Rollback: flash the OrangeFox R12.0 image
  `41528bb44e7978cb974a8af6e15a4bfe7134958eb90ea69a6837f479d0f171d8` or the
  stock recovery image
  `6b2676dc839ecff3ceb0fbd2b28c59512eaae5c251d3d8a096a151846042bc80` back to
  `recovery_a` and reboot.
- Changing the recovery partition carries a known red-screen / slot-unbootable
  risk on this device; keep a valid EDL recovery path available.

## 4. Android 17 TEE replacement and decryption correction

### 4.1 Why it is needed

The device ships with stock Android 17, while AERA R1.0 is built from an
AOSP 16 recovery base. The symptom on the un-fixed build was: `/data` mounts
but `/data/media` stays empty — F2FS mounts, FBE does not unlock.

Root cause, established by file-by-file hash comparison against stock
Android 17 `vendor.img`: most SPU KeyMint / onekeymint / gatekeeper-rust files
were already Android 17 versions, but the **TEE communication chain was still
Android 16 (TB322FC)** and does not match the Android 17 TZ/SPU services.

### 4.2 The eight replaced files

| File (recovery ramdisk path) | Android 16 baseline size | Android 17 stock size |
| --- | --- | --- |
| `system/bin/qseecomd` | 69,168 B | 85,992 B |
| `system/lib64/libQSEEComAPI.so` | 85,168 B | 69,360 B |
| `system/lib64/hw/libqtigatekeeper.so` | 101,760 B | 101,912 B |
| `system/lib64/libdrmfs.so` | 101,048 B | 101,480 B |
| `system/lib64/libminkdescriptor.so` | 85,512 B | 85,976 B |
| `system/lib64/libdmabufheap.so` | 102,352 B | 102,400 B |
| `system/lib64/libion.so` | 51,232 B | 51,312 B |
| `system/lib64/libqcbor.so` | 52,024 B | 52,112 B |

These are proprietary Lenovo/Qualcomm bytes and are not in this repository.
They are **not** part of the 103-file Android 16 fix3b payload pinned by
`proprietary-sources.tsv`. Stage them from matching Android 17 stock firmware
you are entitled to use.

### 4.3 The 11 documented Android 17 substitutions

`proprietary-overrides.tsv` records 11 payload files that were substituted with
Android 17 stock bytes (`status=substituted`) instead of the A16 donor bytes.
The list is dominated by the crypto chain, for example:

- `system/bin/hw/android.hardware.gatekeeper-rust-service-qti`
- `system/bin/hw/android.hardware.security.onekeymint-service-qti`
- `system/bin/hw/vendor.qti.hardware.spu-service`
- `system/bin/sec_nvm`, `system/bin/spdaemon`
- `system/lib64/libspukeymint.so`, `libspukeymintdeviceutils.so`,
  `libspukeymintprovision.so`, `libspukeymintutils.so`
- `system/lib64/libspuqtigatekeeper.so`, `system/lib64/hw/libspuqtigatekeeper.so`
  (both mapped from the same stock `vendor.img` path)

The overrides file contains the pinned and found hashes/sizes and the stock
source paths; that is the authoritative record.

### 4.4 Decryption and FBE results

- The decrypting R1.0 build reported `User 0 Decrypted Successfully`,
  `Data successfully decrypted`, metadata encryption `aes-256-xts`, and
  `/data/media/0` accessible.
- A later issue appeared on 2026-11-07: metadata (DE) decryption succeeded but
  the FBE CE storage of user 0 was not unlocked, so `/sdcard` showed ciphertext
  names and writes failed with `Required key not available` (`ENOKEY`). The
  project fixed it in the **recovery source tree** with a small patch series
  (keep `/data` mounted, decrypt-device mount fallback, spblob/handle parse
  guards). After the fix, `/sdcard` is plaintext, `mkdir /sdcard/AERA` succeeds,
  and the white theme is restored.
- Those FBE patches are **not** in this device tree; see §3.4.
- Decryption was validated with the default-password path only; a custom
  lock-screen password was not tested (待验证).
- The device's stock Android 17 firmware revision matters: hashes recorded in
  the project correspond to the A16 ROW firmware for the 25 stock payload files
  and to the Android 17 stock `vendor.img` for the substitutions. A different
  firmware revision may produce different bytes; verify hashes and mark
  outcomes as 待验证.

## 5. Optional audio enhancement

### 5.1 What is in this repository

- `audio/`: AERA audio bridge, AGM service, PAL player and AW882xx PA probe
  sources, built as recovery binaries (`aera-audio-bridge`, `aera-audio-service`,
  `aera-palplayer`, `aera-aw-hal`).
- `recovery/root/init.recovery.audio.rc`: disabled services for the stock DSP
  daemons, the AGM service and the bootstrap; the bootstrap is started on
  `sys.boot_completed=1`.
- `recovery/root/system/bin/aera-audio-bootstrap`: mounts the stock vendor/DSP
  partitions read-only, builds the PAL mixer compatibility overlay, loads the
  audio module closure and brings the AudioReach/AGM stack up.
- `recovery/root/system/bin/aera-pal-probe.sh`: stream-type probe helper.
- `apply-audio-t10.sh`, `apply-audio-t11.sh`, `apply-audio-t12.sh`: idempotent
  integration steps applied to this tree (with `--dry-run` / `--revert`).

### 5.2 Stock blobs you must supply (paths only, no binaries)

| Target path in the device tree | Content | Source |
| --- | --- | --- |
| `recovery/root/AERA/audio/lib64/` | Stock A17 PAL/AGM/QMI/QRTR/minijail runtime libraries (67 files in the project's staging) | stock `vendor.img` `/vendor/lib64/...` |
| `recovery/root/AERA/audio/abi/` | Stock A17 binder/ABI libraries used by the PAL host (`libbinder`, `libbinder_ndk`, `libc++`, `libcutils`, `libbase`, `libutils`, `libhardware`, `libhidlbase`, …; 9 files in the project's staging) | stock `vendor.img` |
| `recovery/root/AERA/modules/audio/` | Audio kernel module closure (54 modules: audio DLKMs plus dependencies) | stock `vendor_dlkm.img` / `system_dlkm.img` |
| `recovery/root/system/bin/aera-pd-mapper`, `aera-dspservice`, `aera-audioadsprpcd` | Stock ADSP helper daemons, renamed to the AERA service names | stock `vendor.img` `/vendor/bin/...` |
| `recovery/root/vendor/firmware/aw882xx_acf.bin` | Awinic speaker amplifier configuration blob (1,792 B in the project's staging) | stock `vendor.img` |

Staged size in the project: the audio runtime is roughly 14 MB uncompressed
(about 5–7 MB compressed), plus the module closure. The reset of the audio
stack reads the stock partitions at runtime, read-only, and is not staged:
`/vendor` (erofs), `/vendor/dsp`, `/firmware` (stock `modem_a` vfat),
`/mnt/vendor/persist`, `/vendor/etc/audio/sku_canoe` and the `acdbdata`
configuration. Those must exist on the device's stock firmware; they are not
part of this repository.

### 5.3 Validation status

In the project's device builds the audio path reached real speaker output: PAL
stream type 1 (`PAL_STREAM_LOW_LATENCY`), PAL started, both AW882xx smart-PA
started successfully, a fast-exit teardown avoided a `SIGABRT` on stream close,
and the default software volume was 60 %. The public tree carries the same
sources; a clean public rebuild still requires staging the blobs above and was
not re-validated end-to-end (待验证). A missing or mismatched blob shows up in
`/tmp/aera-audio.log`.

## 6. Optional Wi-Fi enhancement

### 6.1 What is in this repository

- `recovery/root/init.recovery.wifi.rc`: on-demand Wi-Fi bring-up
  (`sys.aera.wlan.up=1`), module loader service, Wi-Fi-ready signalling and the
  `wpa_supplicant` service.
- `recovery/root/system/bin/aera-wlan-up.sh`: the WCN786x (`peach v2`) module
  closure loader; it sets the firmware path to `/firmware/image`, recreates the
  stock config/MAC symlink tree, signals `cnss fs_ready`, then lets init start
  `wpa_supplicant`.
- `recovery/root/vendor/etc/wifi/`: stock-derived configuration overlay
  (`peach_v2/WCNSS_qcom_cfg.ini`, `wpa_supplicant.conf`,
  `wpa_supplicant_overlay.conf`, `vendor_cmd.xml`, `sar-vendor-cmd.xml`).
- `AERA_ENABLE_WLAN := 1` in `aera_TB323FU.mk`.

### 6.2 Stock blobs you must supply (paths only, no binaries)

| Target path in the device tree | Content | Source |
| --- | --- | --- |
| `recovery/root/AERA/modules/wlan/qca_cld3_peach_v2.ko` | WCN786x `peach v2` main driver (21,380,096 B in the project's stock inventory) | stock `vendor_dlkm.img` |
| `recovery/root/AERA/modules/wlan/cnss2.ko` | CNSS2 platform bus driver (1,073,968 B) | stock `vendor_dlkm.img` |
| `recovery/root/AERA/modules/wlan/cnss_prealloc.ko` | CNSS preallocation (54,272 B) | stock `vendor_dlkm.img` |
| `recovery/root/AERA/modules/wlan/cnss_utils.ko` | CNSS utilities (37,024 B) | stock `vendor_dlkm.img` |
| `recovery/root/AERA/modules/wlan/cnss_nl.ko` | CNSS netlink (16,136 B) | stock `vendor_dlkm.img` |
| `recovery/root/AERA/modules/wlan/cnss_plat_ipc_qmi_svc.ko` | CNSS platform IPC QMI service (58,096 B) | stock `vendor_dlkm.img` |
| `recovery/root/AERA/modules/wlan/wlan_firmware_service.ko` | WLAN firmware service (104,464 B) | stock `vendor_dlkm.img` |
| `recovery/root/AERA/modules/wlan/{rfkill,smem-mailbox,rmnet_mem,gsim,ipam}.ko` | module-closure dependencies loaded before/around CNSS2 (sizes not recorded in this document) | stock `vendor_dlkm.img` |
| `recovery/root/AERA/modules/wlan/{cfg80211,mac80211}.ko` (reference copies) | Wi-Fi stack modules normally present in the recovery `/lib/modules` | stock `vendor_dlkm.img` or the recovery ramdisk |

Runtime dependencies that are **not** staged into the repository:

- WLAN firmware, read from the stock `/firmware` partition (`modem_a`, vfat):
  `image/peach/bdwlan.elf`, `image/peach/amss20.bin`, `image/peach/regdb.bin`,
  `image/tmel_peach_20.elf`.
- Factory MAC address from the device's `/persist/peach_v2/wlan_mac.bin`
  (device-specific; redacted as `<MAC>` here and never committed). If the file
  is missing, AERA derives a stable MAC.
- `cnss-daemon` may be required for the QMI/calibration handshake on some
  platforms; the project did not verify this (待验证).
- `wpa_supplicant` / `wpa_cli` come from the AERA source tree
  (`external/wpa_supplicant_8`), not from the device's stock blobs.

### 6.3 Validation status

The project's builds passed Wi-Fi network tests and recovered the link after
audio use. The module closure is large (about 21.67 MiB of driver bytes alone,
mostly `qca_cld3_peach_v2.ko`) and the recovery image budget is fixed; measure
the produced image. A clean public rebuild requires the blobs above and was not
re-validated end-to-end (待验证). Diagnosis log: `/tmp/aera-wlan.log`.

## 7. Feature switches and risk notes

- **Root Manager** (`ro.aera.root_manager.enabled=1`): UI assets only. The
  project device is Magisk-rooted; KernelSU/SukiSU patch routines would
  conflict with Magisk and were deliberately not run. Do not patch `init_boot`
  or `abl` on a Magisk-rooted device without a verified backup.
- **EFISP** (3 MB partition, `/efisp`, `/dev/block/sde84`): safe for backup and
  read; writing/restoring EFI applications was not validated (待验证) and is
  high risk.
- **ABL preservation**: the install zip offers it; it was not device-validated
  (待验证).
- **Magisk addon**: deleted from the build (`AERA_DELETE_MAGISK_ADDON=1`);
  `magiskboot` is kept for image repacking.
- **Multi-kernel Root Manager assets**: only the 6.12 kernel assets are
  packaged (`AERA_ROOT_MODULE_KERNELS := 6.12`, matching the device kernel
  `6.12.69`).
- **Fingerprint / OMAPI / NFC / mobile data / DMSETUP**: not enabled; the
  device's recovery volume list and stock HAL set do not support them cleanly.
- **FRP wipe**: ineffective in this configuration — `ro.frp.pst` is not
  present in recovery (待验证 if needed).
- **Live fastbootd transition**: disabled by design; use the BCB reboot path.

## 8. Known limitations and open items

1. Intermittent tagged-pointer boot crash on the 2026-11-07 build (待验证 for a
   full fix).
2. Audio/Wi-Fi need locally staged proprietary blobs; no clean-room
   re-validation (待验证).
3. FBE unlock fix and UI fixes live in the recovery source tree, outside this
   repository (待验证 for exact reproduction).
4. Full-width 1904 × 3040 UI layout (R2) is not done; native canvas rotation can
   corrupt the display.
5. No tombstone support (`crash_dump64` missing); SELinux is permissive;
   `/data/recovery/AERA` has no `file_contexts`.
6. `misc` is not in the backup volume list; restore/wipe/ZIP-UI/OTA paths were
   not device-validated.
7. Custom lock-screen password decryption was not tested.
8. Per-file provenance of the eight A17 TEE files and of the optional
   audio/Wi-Fi stock blobs across stock firmware revisions is 待验证.

## 9. Artifact reference

| Artifact | SHA-256 | Size |
| --- | --- | --- |
| `AERA-R1.0-Beta-Unofficial-TB323FU.img` (first verified R1.0) | `a94f39468cb096fe9a62e855fe198e9d2fb3ce32d18bc50118d38328cf2a7413` | 104,857,600 B |
| `AERA-R1.0-Beta-Unofficial-TB323FU.img` (R1.0 fixes) | `c17430e8f0c7ee88ed4c37ea20bb6376b3ba6552dc20b08835e83e74d91279f0` | 104,857,600 B |
| `AERA-R1.0-Beta-Unofficial-TB323FU-20261107-recovery.img` (hotfix5) | `a27e95b068f5e236ee4c1dbb1196c2d48e2ba0f3e4219c37f63d3647aa21adb6` | 104,857,600 B |
| `AERA-R1.0-Beta-Unofficial-TB323FU-20261107-recovery.zip` (hotfix5) | `d60c8595ae14a171a844499e3c28fbe2f51a13068aef0ef2b1a6e53c19935d24` | 77,429,288 B |
| OrangeFox R12.0 rollback image | `41528bb44e7978cb974a8af6e15a4bfe7134958eb90ea69a6837f479d0f171d8` | 104,857,600 B |
| stock `recovery_a` rollback image | `6b2676dc839ecff3ceb0fbd2b28c59512eaae5c251d3d8a096a151846042bc80` | 104,857,600 B |

---

# 中文

## 1. 本仓库是什么（不是什么）

本仓库是 TB323FU 的 **AERA 设备树**：AERA 产品配置、继承自已验证 TB323FU
基线的设备/recovery 配置、可选的音频/Wi-Fi 集成源码，以及哈希锁定的专有文件
清单。

它**不是**：

- AERA 官方设备构建，也不是 AERA recovery 源码的 fork；
- 系统/ROM 设备树 —— 那是 TB323FU 主仓库（`LineageOS 24` / Android 17）；
- 专有二进制载体：所有联想/高通 payload 字节（包括原厂音频/Wi-Fi 运行时）均
  另行获取。

继承的基线文档（`docs/KNOWN_GOOD.md`、`docs/BUILDING.md`、
`docs/PROPRIETARY_FILES.md`、`docs/DECRYPTION_TROUBLESHOOTING.md`、
`docs/PUBLICATION_STATUS.md`、`TREE_PROVENANCE.md`）描述的是已验证的
TWRP/OrangeFox 基线。它们作为设备与 payload 清单的参考仍然有效，但不是 AERA
专用发布说明。

## 2. 与主仓库、兄弟 recovery 仓库的关系

| 仓库 | 角色 | 构建系统 |
| --- | --- | --- |
| `android_device_lenovo_TB323FU`（主仓库） | TB323FU 的 LineageOS 24 / Android 17 **系统**设备树：ROM 构建、启动链、硬件启用、系统级根因文档 | LineageOS 24 manifest |
| `android_device_lenovo_TB323FU-orangefox`（兄弟仓库） | TWRP 3.7.1（Android 16）+ OrangeFox R12.0（Android 17）**recovery** 设备树；已验证 recovery 基线与 Android 17 解密修正的来源 | TWRP-Test `twrp-16.0` manifest；OrangeFox `fox_16.0` manifest |
| 本仓库（`...-aera`） | **AERA Recovery R1.0** 设备树：同一基线上的 AERA 产品层、可选音频/Wi-Fi、延续的 A17 解密修正 | AERA `aera-16.0` manifest |

共享材料与边界：

- **103 文件专有 payload 清单**（`proprietary-*.tsv`、
  `scripts/acquire-proprietary-files.sh`）与兄弟 recovery 仓库共享：25 个来自
  配套 TB323FU 原厂固件，78 个来自公开的 polygraphene TB322FC donor 树，按
  大小与 SHA-256 锁定。它不是系统 ROM 的 payload。
- **Android 17 TEE/解密修正**在 recovery 线开发，并延续到本树；见 §4。
- 本树**不能用主线 LineageOS 树构建**，主线树也不能用本 recovery 树构建：
  manifest 与 product 不同。共享的只有设备配置概念与 payload 清单。
- 设备每个槽位只能放一个 recovery；项目在 `recovery_a` 上验证 AERA，并在
  `recovery_b` 保留 OrangeFox R12.0 镜像作为回退路径。

## 3. 构建要点

### 3.1 源码树

- Manifest：`https://github.com/AERA-Recovery/android_manifest`，分支
  `aera-16.0`（基于 AOSP 16）。
- 同步：

  ```bash
  repo init -u https://github.com/AERA-Recovery/android_manifest.git -b aera-16.0
  repo sync -c --force-sync --no-clone-bundle --no-tags -j$(nproc)
  ```

- 设备树位置：把本仓库复制到源码检出的 `device/lenovo/TB323FU/`（先去掉
  `.git`）。项目的工作副本还删除了 `artifacts/` 目录；公开仓库不含任何构建
  产物。
- 产品：`twrp_TB323FU-bp2a-eng`；构建命令：`mka adbd recoveryimage`。
- 每次重建前清理：`rm -rf out/target/product/TB323FU`。复用产品输出目录会让
  ramdisk 打包因残留符号链接失败（例如 `root/odm/etc`）。

磁盘与内存：同步后的 AERA 树与输出目录占数十 GB（项目同步了 411 个 project，
含 repo 元数据）；需大型 Linux 构建主机，内存有限时用保守并行度。

### 3.2 产品与环境配置

`aera_TB323FU.mk`（AERA 产品层）与 `vendorsetup.sh`（构建环境）承载移植专用
配置：

| 配置 | 取值 / 作用 |
| --- | --- |
| `AERA_AB_DEVICE`、`AERA_VIRTUAL_AB_DEVICE` | `1`：A/B + virtual A/B |
| `AERA_AB_DEVICE_WITH_RECOVERY_PARTITION` | `1`：A/B 设备，另有独立、非分槽的 recovery 分区 |
| `AERA_SCREEN_H` | `2280`：AERA UI 把它转成 1440 宽逻辑画布，`logical_height = AERA_SCREEN_H * 4 / 3 = 3040`；随后 `DisplayTransform::Adaptive` 选择缩放 1000/1000，UI 按 1:1、零重采样合成，左右约 232 px 边带由页面背景填充。真正的满宽 1904 × 3040 需要场景横向重排（R2，本树未包含） |
| `AERA_STATUS_H` | `114` |
| `AERA_DEFAULT_LANGUAGE`、`AERA_EXTRA_LANGUAGES` | `zh_CN`、`true`：默认简体中文、打包全部 33 种语言、CJK 字体 fallback |
| `AERA_USE_LZ4_COMPRESSION` | `1`：LZ4 ramdisk（与基线 boot header/打包一致） |
| `AERA_USE_UPDATED_MAGISKBOOT` | `0`（刻意）：AERA 默认预编译 `magiskboot` 为 4 KiB ELF 对齐，可在本机 4 KiB 页内核运行；`_updated` 变体为 16 KiB 对齐，不可使用 |
| `AERA_DELETE_MAGISK_ADDON` | `1`：保留 `magiskboot` 用于镜像重打包，不捆绑 Magisk addon |
| `AERA_ENABLE_ROOT_MANAGER` | `1`：仅 Root Manager UI 资产；未在已 Magisk root 的设备上执行 KernelSU/SukiSU patch |
| `AERA_ENABLE_EFISP`、`AERA_ENABLE_ABL_PRESERVATION` | `1`：EFISP 可见、可备份；ABL 保活由安装 zip 提供（未真机验证） |
| `AERA_ENABLE_WLAN` | `1`：Wi-Fi 源码集成；原厂驱动模块需自行暂存（见 §6） |
| `AERA_SETTINGS_ROOT_DIRECTORY`、`AERA_MISCELLANEOUS_ROOT_DIRECTORY` | `/data/recovery`、`/sdcard` |
| `AERA_BUILD_STATUS`、`AERA_BUILD_TYPE` | `Unofficial`、`Beta` |
| `AERA_CURRENT_BRANCH` | `aera-16.0`：recovery 横幅的分支标签（若 `.repo` project objects 被裁剪，源码树无可用的 `.git` 元数据） |

不要设 `AERA_USE_DMSETUP`（本树使用 `TW_USE_DMCTL` / `AERA_USE_DMCTL`），并
让 `ro.aera.live_fastbootd` 保持 false（原地 live recovery ↔ fastbootd 切换是
已知崩溃路径；transition 走 BCB 重启路径）。

### 3.3 镜像预算

- recovery 分区：`BOARD_RECOVERYIMAGE_PARTITION_SIZE := 104857600`
  （100 MiB），boot header v4，4 KiB 内核页，LZ4 ramdisk。
- 参考构建：2026-11-06 的 R1.0 修复构建 `ramdisk-recovery.img = 70,709,037 B`；
  2026-11-07 含音频/Wi-Fi 与 FBE 修复的构建为 `ramdisk-recovery.img =
  89,470,975 B`，最终镜像恰为 104,857,600 B（AVB `Algorithm: NONE`）。
- 始终断言产出的 `recovery.img` ≤ 104,857,600 字节。启用可选音频/Wi-Fi 材料会
  吃掉剩余预算的很大一部分；加东西前先实测。

### 3.4 recovery 源码修复不在本仓库

AERA 设备树只是 recovery 构建的一半。项目还对 AERA recovery 源码树应用了修复
（不在任何 TB323FU 仓库中），包括 UI 版式补丁、FBE 存储解锁修复、插件商店下载
修复与 logcat 稳定性修复。重新 `repo sync` 会丢弃它们。本仓库文档化其范围与
设备可见效果，但不随仓库提供源码补丁；请把干净重建视为“R1.0 核心功能”，而不是
2026-11-07 镜像的逐字节复现。

### 3.5 刷入与回退

- 本机只有 fastbootd 能写 recovery 分区；bootloader fastboot 返回
  `remote: 'unknown command'`。
- 项目只刷 `recovery_a`；`recovery_b` 保留 OrangeFox R12.0 镜像。
- 写入失败 `AdbWriteEndpointSync failed ... (121)`：对 USB/ADB PnP 设备做复位后
  重试。
- 回退：把 OrangeFox R12.0 镜像
  `41528bb44e7978cb974a8af6e15a4bfe7134958eb90ea69a6837f479d0f171d8` 或原厂
  recovery 镜像
  `6b2676dc839ecff3ceb0fbd2b28c59512eaae5c251d3d8a096a151846042bc80` 刷回
  `recovery_a` 并重启。
- 改 recovery 分区在本机有已知红屏 / slot 不可启动风险；请保留可用的 EDL 恢复
  通道。

## 4. Android 17 TEE 件替换与解密修正

### 4.1 为什么需要

设备出厂为原厂 Android 17，而 AERA R1.0 基于 AOSP 16 recovery 基线构建。未修复
构建的现象是：`/data` 能挂载，但 `/data/media` 为空 —— F2FS 挂上了、FBE 没有
解开。

根因（通过对原厂 Android 17 `vendor.img` 逐文件哈希比对确认）：大部分 SPU
KeyMint / onekeymint / gatekeeper-rust 文件已经是 Android 17 版本，但 **TEE
通信链仍是 Android 16（TB322FC）**，与 Android 17 的 TZ/SPU 服务不配套。

### 4.2 被替换的 8 个文件

| 文件（recovery ramdisk 内路径） | Android 16 基线大小 | Android 17 原厂大小 |
| --- | --- | --- |
| `system/bin/qseecomd` | 69,168 B | 85,992 B |
| `system/lib64/libQSEEComAPI.so` | 85,168 B | 69,360 B |
| `system/lib64/hw/libqtigatekeeper.so` | 101,760 B | 101,912 B |
| `system/lib64/libdrmfs.so` | 101,048 B | 101,480 B |
| `system/lib64/libminkdescriptor.so` | 85,512 B | 85,976 B |
| `system/lib64/libdmabufheap.so` | 102,352 B | 102,400 B |
| `system/lib64/libion.so` | 51,232 B | 51,312 B |
| `system/lib64/libqcbor.so` | 52,024 B | 52,112 B |

这些是联想/高通专有字节，不在本仓库。它们**不属于** `proprietary-sources.tsv`
锁定的 103 个 Android 16 fix3b payload；请从自己有权使用的配套 Android 17 原厂
固件中暂存。

### 4.3 已文档化的 11 个 Android 17 替代项

`proprietary-overrides.tsv` 记录了 11 个用 Android 17 原厂字节替代 A16 donor
字节的 payload 文件（`status=substituted`）。列表集中在 crypto 链，例如：

- `system/bin/hw/android.hardware.gatekeeper-rust-service-qti`
- `system/bin/hw/android.hardware.security.onekeymint-service-qti`
- `system/bin/hw/vendor.qti.hardware.spu-service`
- `system/bin/sec_nvm`、`system/bin/spdaemon`
- `system/lib64/libspukeymint.so`、`libspukeymintdeviceutils.so`、
  `libspukeymintprovision.so`、`libspukeymintutils.so`
- `system/lib64/libspuqtigatekeeper.so`、`system/lib64/hw/libspuqtigatekeeper.so`
  （两者都映射自同一个原厂 `vendor.img` 路径）

overrides 文件含 pinned/found 哈希与大小、原厂来源路径，是权威记录。

### 4.4 解密与 FBE 结果

- 可解密的 R1.0 构建报告了 `User 0 Decrypted Successfully`、
  `Data successfully decrypted`、metadata 加密 `aes-256-xts`，且
  `/data/media/0` 可访问。
- 2026-11-07 又出现一个问题：metadata（DE）解密成功，但 user 0 的 FBE CE
  存储未解锁，导致 `/sdcard` 显示密文名、写入返回 `Required key not available`
  （`ENOKEY`）。项目在 **recovery 源码树**用一小组补丁修复（保持 `/data` 挂载、
  decrypt-device 挂载回退、spblob/handle 解析守卫）。修复后 `/sdcard` 为明文、
  `mkdir /sdcard/AERA` 成功、白色主题恢复。
- 这些 FBE 补丁**不在**本设备树；见 §3.4。
- 解密仅验证了默认密码路径；自定义锁屏密码未测试（待验证）。
- 设备原厂 Android 17 固件版本很关键：项目中 25 个 stock payload 文件的哈希对应
  A16 ROW 固件，替代项对应原厂 Android 17 `vendor.img`。不同固件版本可能产生
  不同字节；请校验哈希并把结果标为待验证。

## 5. 可选音频增强

### 5.1 本仓库包含什么

- `audio/`：AERA 音频桥、AGM 服务、PAL player 与 AW882xx 功放探测源码，构建为
  recovery 二进制（`aera-audio-bridge`、`aera-audio-service`、
  `aera-palplayer`、`aera-aw-hal`）。
- `recovery/root/init.recovery.audio.rc`：原厂 DSP daemon、AGM 服务与 bootstrap
  的 disabled 服务定义；bootstrap 在 `sys.boot_completed=1` 时启动。
- `recovery/root/system/bin/aera-audio-bootstrap`：只读挂载原厂 vendor/DSP 分区、
  构建 PAL mixer 兼容 overlay、加载音频模块闭包并拉起 AudioReach/AGM 栈。
- `recovery/root/system/bin/aera-pal-probe.sh`：stream-type 探测辅助脚本。
- `apply-audio-t10.sh`、`apply-audio-t11.sh`、`apply-audio-t12.sh`：应用到本树的
  幂等集成步骤（支持 `--dry-run` / `--revert`）。

### 5.2 需要自备的原厂 blob（只列路径，不给二进制）

| 设备树目标路径 | 内容 | 来源 |
| --- | --- | --- |
| `recovery/root/AERA/audio/lib64/` | 原厂 A17 PAL/AGM/QMI/QRTR/minijail 运行时库（项目暂存为 67 个文件） | 原厂 `vendor.img` `/vendor/lib64/...` |
| `recovery/root/AERA/audio/abi/` | PAL host 使用的原厂 A17 binder/ABI 库（`libbinder`、`libbinder_ndk`、`libc++`、`libcutils`、`libbase`、`libutils`、`libhardware`、`libhidlbase` 等；项目暂存为 9 个文件） | 原厂 `vendor.img` |
| `recovery/root/AERA/modules/audio/` | 音频内核模块闭包（54 个模块：audio DLKM 及其依赖） | 原厂 `vendor_dlkm.img` / `system_dlkm.img` |
| `recovery/root/system/bin/aera-pd-mapper`、`aera-dspservice`、`aera-audioadsprpcd` | 原厂 ADSP 辅助 daemon，重命名为 AERA 服务名 | 原厂 `vendor.img` `/vendor/bin/...` |
| `recovery/root/vendor/firmware/aw882xx_acf.bin` | Awinic 扬声器功放配置 blob（项目暂存为 1,792 B） | 原厂 `vendor.img` |

项目暂存大小：音频运行时约 14 MB 未压缩（压缩后约 5–7 MB），另加模块闭包。
音频栈其余部分在运行时只读读取原厂分区，不暂存：`/vendor`（erofs）、
`/vendor/dsp`、`/firmware`（原厂 `modem_a` vfat）、`/mnt/vendor/persist`、
`/vendor/etc/audio/sku_canoe` 与 `acdbdata` 配置。这些必须在设备原厂固件上
存在，不属于本仓库。

### 5.3 验证状态

项目的设备构建中，音频通路达到了真实扬声器出声：PAL stream type 1
（`PAL_STREAM_LOW_LATENCY`）、PAL 启动、双 AW882xx 智能功放 start 成功、
fast-exit 退出避免了流关闭时的 `SIGABRT`，默认软件音量 60 %。公开树携带相同
源码；干净公开重建仍需暂存上面的 blob，且未做端到端重新验证（待验证）。blob
缺失或不匹配会体现在 `/tmp/aera-audio.log`。

## 6. 可选 Wi-Fi 增强

### 6.1 本仓库包含什么

- `recovery/root/init.recovery.wifi.rc`：按需 Wi-Fi bring-up
  （`sys.aera.wlan.up=1`）、模块加载服务、Wi-Fi ready 信号与 `wpa_supplicant`
  服务。
- `recovery/root/system/bin/aera-wlan-up.sh`：WCN786x（`peach v2`）模块闭包
  加载器；设置固件路径为 `/firmware/image`、重建原厂配置/MAC 符号链接树、
  通知 `cnss fs_ready`，随后由 init 启动 `wpa_supplicant`。
- `recovery/root/vendor/etc/wifi/`：原厂导出的配置 overlay
  （`peach_v2/WCNSS_qcom_cfg.ini`、`wpa_supplicant.conf`、
  `wpa_supplicant_overlay.conf`、`vendor_cmd.xml`、`sar-vendor-cmd.xml`）。
- `aera_TB323FU.mk` 中的 `AERA_ENABLE_WLAN := 1`。

### 6.2 需要自备的原厂 blob（只列路径，不给二进制）

| 设备树目标路径 | 内容 | 来源 |
| --- | --- | --- |
| `recovery/root/AERA/modules/wlan/qca_cld3_peach_v2.ko` | WCN786x `peach v2` 主驱动（项目原厂盘点中为 21,380,096 B） | 原厂 `vendor_dlkm.img` |
| `recovery/root/AERA/modules/wlan/cnss2.ko` | CNSS2 平台总线驱动（1,073,968 B） | 原厂 `vendor_dlkm.img` |
| `recovery/root/AERA/modules/wlan/cnss_prealloc.ko` | CNSS 预分配（54,272 B） | 原厂 `vendor_dlkm.img` |
| `recovery/root/AERA/modules/wlan/cnss_utils.ko` | CNSS 工具库（37,024 B） | 原厂 `vendor_dlkm.img` |
| `recovery/root/AERA/modules/wlan/cnss_nl.ko` | CNSS netlink（16,136 B） | 原厂 `vendor_dlkm.img` |
| `recovery/root/AERA/modules/wlan/cnss_plat_ipc_qmi_svc.ko` | CNSS 平台 IPC QMI 服务（58,096 B） | 原厂 `vendor_dlkm.img` |
| `recovery/root/AERA/modules/wlan/wlan_firmware_service.ko` | WLAN 固件服务（104,464 B） | 原厂 `vendor_dlkm.img` |
| `recovery/root/AERA/modules/wlan/{rfkill,smem-mailbox,rmnet_mem,gsim,ipam}.ko` | CNSS2 前后加载的模块闭包依赖（本文件未记录大小） | 原厂 `vendor_dlkm.img` |
| `recovery/root/AERA/modules/wlan/{cfg80211,mac80211}.ko`（参考副本） | 通常已存在于 recovery `/lib/modules` 的 Wi-Fi 栈模块 | 原厂 `vendor_dlkm.img` 或 recovery ramdisk |

不暂存进仓库、但运行期需要的依赖：

- WLAN 固件，从原厂 `/firmware` 分区（`modem_a`，vfat）读取：
  `image/peach/bdwlan.elf`、`image/peach/amss20.bin`、`image/peach/regdb.bin`、
  `image/tmel_peach_20.elf`。
- 设备工厂 MAC 地址来自 `/persist/peach_v2/wlan_mac.bin`（设备相关；此处以
  `<MAC>` 脱敏，绝不提交）。若文件缺失，AERA 会派生稳定 MAC。
- 某些平台上 QMI/校准握手可能需要 `cnss-daemon`；项目未验证（待验证）。
- `wpa_supplicant` / `wpa_cli` 由 AERA 源码树（`external/wpa_supplicant_8`）
  提供，不来自设备原厂 blob。

### 6.3 验证状态

项目的构建通过了 Wi-Fi 网络测试，并在音频使用后恢复了链路。模块闭包很大
（仅驱动字节就约 21.67 MiB，主要是 `qca_cld3_peach_v2.ko`），而 recovery 镜像
预算固定；请实测产物大小。干净公开重建需要上面的 blob，且未做端到端重新验证
（待验证）。诊断日志：`/tmp/aera-wlan.log`。

## 7. 功能开关与风险提示

- **Root Manager**（`ro.aera.root_manager.enabled=1`）：仅 UI 资产。项目设备为
  Magisk root；KernelSU/SukiSU patch 流程会与 Magisk 冲突，刻意未执行。不要在
  已 Magisk root 的设备上 patch `init_boot` 或 `abl`，除非有已验证的备份。
- **EFISP**（3 MB 分区，`/efisp`、`/dev/block/sde84`）：备份与读取安全；写入/
  恢复 EFI 应用未验证（待验证），风险高。
- **ABL 保活**：安装 zip 提供该选项；未做真机验证（待验证）。
- **Magisk addon**：构建中删除（`AERA_DELETE_MAGISK_ADDON=1`）；保留
  `magiskboot` 用于镜像重打包。
- **多内核 Root Manager 资产**：只打包 6.12 内核资产
  （`AERA_ROOT_MODULE_KERNELS := 6.12`，匹配设备内核 `6.12.69`）。
- **指纹 / OMAPI / NFC / mobile data / DMSETUP**：未启用；设备的 recovery 卷
  列表与原厂 HAL 集合无法干净支持。
- **FRP 擦除**：在此配置下无效 —— recovery 中没有 `ro.frp.pst`（如确有需要，
  待验证）。
- **live fastbootd transition**：按设计关闭；使用 BCB 重启路径。

## 8. 已知限制与待办项

1. 2026-11-07 构建存在启动偶发 tagged-pointer 崩溃（完整修复待验证）。
2. 音频/Wi-Fi 需本地暂存专有 blob；未做干净重建后的重新验证（待验证）。
3. FBE 解锁修复与 UI 修复位于 recovery 源码树，不在本仓库（精确复现待验证）。
4. 满宽 1904 × 3040 UI 版式（R2）未做；native 画布旋转可能造成显示花屏。
5. 无 tombstone 支持（缺 `crash_dump64`）；SELinux 为 permissive；
   `/data/recovery/AERA` 无 `file_contexts`。
6. `misc` 不在备份卷列表中；restore/wipe/ZIP UI/OTA 路径均未做真机验证。
7. 自定义锁屏密码解密未测试。
8. 8 个 A17 TEE 文件与可选音频/Wi-Fi 原厂 blob 的跨固件版本逐文件来源为
   待验证。

## 9. 产物参考

| 产物 | SHA-256 | 大小 |
| --- | --- | --- |
| `AERA-R1.0-Beta-Unofficial-TB323FU.img`（R1.0 首个验证） | `a94f39468cb096fe9a62e855fe198e9d2fb3ce32d18bc50118d38328cf2a7413` | 104,857,600 B |
| `AERA-R1.0-Beta-Unofficial-TB323FU.img`（R1.0 修复） | `c17430e8f0c7ee88ed4c37ea20bb6376b3ba6552dc20b08835e83e74d91279f0` | 104,857,600 B |
| `AERA-R1.0-Beta-Unofficial-TB323FU-20261107-recovery.img`（hotfix5） | `a27e95b068f5e236ee4c1dbb1196c2d48e2ba0f3e4219c37f63d3647aa21adb6` | 104,857,600 B |
| `AERA-R1.0-Beta-Unofficial-TB323FU-20261107-recovery.zip`（hotfix5） | `d60c8595ae14a171a844499e3c28fbe2f51a13068aef0ef2b1a6e53c19935d24` | 77,429,288 B |
| OrangeFox R12.0 回退镜像 | `41528bb44e7978cb974a8af6e15a4bfe7134958eb90ea69a6837f479d0f171d8` | 104,857,600 B |
| 原厂 `recovery_a` 回退镜像 | `6b2676dc839ecff3ceb0fbd2b28c59512eaae5c251d3d8a096a151846042bc80` | 104,857,600 B |
