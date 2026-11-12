# TB323FU AERA Recovery R1.0 device tree (unofficial port)

Author/Maintainer: krollv, @DeepSeek V4.1 Flash 1017

Unofficial, community-maintained **AERA Recovery R1.0** device tree for the
**Lenovo Legion Y700 Gen 5 (TB323FU / Baldur, Qualcomm SM8850P)**.

This tree ports AERA Recovery to TB323FU on top of the project's validated
TB323FU recovery baseline (the TWRP 3.7.1 Android 16 tree and its OrangeFox
R12.0 Android 17 line), adding the **AERA product layer** (AERA build
configuration, AERA UI and CLI), the project's **Android 17 decryption
correction**, the **FBE storage unlock fix** lineage, and optional **audio /
Wi-Fi** enablement sources. AERA itself is an independent third-party recovery
project; this port is not an official AERA device build. It is not affiliated
with, sponsored by, or endorsed by Lenovo, Qualcomm, Google, AERA, TeamWin, or
the OrangeFox Recovery Project.

> **Warning**
>
> This project is provided **AS IS**, without warranty of any kind. Installing
> or using a custom recovery can cause data loss, an unbootable device, loss of
> access to encrypted data, security problems, or other unintended
> consequences. You are solely responsible for deciding whether to build,
> flash, modify, or use this project and for maintaining appropriate backups.
> The maintainer and contributors accept no responsibility or liability for
> damage, data loss, loss of functionality, or other consequences arising from
> its use.

Author/Maintainer: krollv, @DeepSeek V4.1 Flash 1017

Copyright (C) 2026 自恋也是种美 (krollv)

## At a glance

| Item | Value |
| --- | --- |
| Target device | Lenovo Legion Y700 Gen 5 — **TB323FU only** (codename Baldur) |
| SoC / platform | Qualcomm SM8850P (kaanapali / canoe) |
| AERA release | R1.0 (Beta), unofficial port (`ro.aera.release.channel=Beta`, `ro.aera.status=Unofficial`) |
| AERA source base | `AERA-Recovery/android_manifest`, branch `aera-16.0` (AOSP 16 based) |
| AERA CLI | 1.1.0 |
| Product / lunch target | `twrp_TB323FU-bp2a-eng` |
| Kernel page size | 4 KiB |
| Partition layout | A/B with a dedicated, non-slotted `recovery` partition; virtual A/B |
| Recovery partition size | 104,857,600 bytes (100 MiB) |
| Flashed slot during validation | `recovery_a` only; `recovery_b` (OrangeFox R12.0) untouched |
| Display | Native 1904 × 3040 panel scanout; AERA UI uses a 1440 × 3040 logical canvas composited 1:1 with approximately 232 px side bands (earlier R1.0 images used a 1440 × 3168 letterbox canvas, ~261 px side bands) |

## Verified baselines

| Build | Artifact | SHA-256 | Size | Status |
| --- | --- | --- | --- | --- |
| AERA R1.0 first verified build (2026-11-06) | `AERA-R1.0-Beta-Unofficial-TB323FU.img` | `a94f39468cb096fe9a62e855fe198e9d2fb3ce32d18bc50118d38328cf2a7413` | 104,857,600 B | Device-verified: UI/touch, `/data` FBE decryption, `/data/media/0`, `/metadata`, ADB, MTP, fastbootd |
| AERA R1.0 fixes build (2026-11-06) | `AERA-R1.0-Beta-Unofficial-TB323FU.img` | `c17430e8f0c7ee88ed4c37ea20bb6376b3ba6552dc20b08835e83e74d91279f0` | 104,857,600 B | Device-verified after seven fix rounds: UI letterbox, battery via SOCCP, Chinese UI, backup, transition-to-fastbootd |
| AERA R1.0 hotfix5 (2026-11-07) — latest user-confirmed build | `AERA-R1.0-Beta-Unofficial-TB323FU-20261107-recovery.img` | `a27e95b068f5e236ee4c1dbb1196c2d48e2ba0f3e4219c37f63d3647aa21adb6` | 104,857,600 B | User-confirmed usable: `/sdcard` plaintext (FBE CE storage unlocked), white theme, native 1904 × 3040 rendering, audio playback path, Wi-Fi network test; **known intermittent tagged-pointer boot crash** |
| AERA R1.0 hotfix5 install zip (2026-11-07) | `AERA-R1.0-Beta-Unofficial-TB323FU-20261107-recovery.zip` | `d60c8595ae14a171a844499e3c28fbe2f51a13068aef0ef2b1a6e53c19935d24` | 77,429,288 B | Produced; **ZIP installation was not device-validated** |
| Rollback anchor: OrangeFox R12.0 (fox_16.0) 2026-11-03 | `OrangeFox-R12.0-fox16.0-TB323FU-20261103-recovery.img` | `41528bb44e7978cb974a8af6e15a4bfe7134958eb90ea69a6837f479d0f171d8` | 104,857,600 B | Content present in `recovery_a` before the AERA port and in `recovery_b` afterwards |
| Rollback anchor: stock recovery | original stock `recovery_a` image | `6b2676dc839ecff3ceb0fbd2b28c59512eaae5c251d3d8a096a151846042bc80` | 104,857,600 B | Original stock recovery of the device |

Detailed AERA build/runtime notes, required blobs and the decryption work are in
[`docs/AERA-NOTES.md`](docs/AERA-NOTES.md). The inherited baseline reference
documents (`docs/KNOWN_GOOD.md`, `docs/BUILDING.md`,
`docs/PROPRIETARY_FILES.md`, `docs/DECRYPTION_TROUBLESHOOTING.md`) were written
for the validated TWRP/OrangeFox baseline and remain useful as source/runtime
reference for the AERA port.

## Features

Validated on the device in this project (latest user-confirmed build:
2026-11-07 hotfix5):

- recovery boot from the dedicated `recovery` partition;
- AERA UI in portrait, native 1904 × 3040 scanout with a 1440 × 3040 logical
  canvas (1:1 compositing, ~232 px side bands);
- touch input;
- Android 17 `/data` FBE decryption and `/sdcard` plaintext access
  (`User 0 Decrypted Successfully`; `/data/media/0` readable);
- `/metadata` mount;
- ADB and MTP;
- fastbootd (`is-userspace: yes`), used to flash `recovery_a`;
- AERA CLI 1.1.0 (`aera status`, `aera storages`, backup, reboot actions);
- Chinese UI, 24-hour clock, `CST-8` time zone;
- battery status via SOCCP attach (reported 68 % / Charging in the R1.0 fix
  validation);
- EFISP visible (3 MB) and available for backup;
- backup of `boot` / `persist` partitions;
- `aera transition fastboot` through the bootloader-message (BCB) path;
- white (light) theme recovery after the FBE storage unlock fix;
- plugin-store download path (`curl` + built-in CA + mirror fallback);
- audio playback path through the stock AudioReach PAL stack (optional, see
  below);
- Wi-Fi network test / link recovery after audio (optional, see below).

Optional enhancements (source integration present; require proprietary stock
blobs at build time):

- **Audio** — AERA audio bridge/service/PAL player sources, bootstrap and
  bring-up hooks are in the tree. In the project's device builds a real
  playback path was validated (PAL stream type 1, dual AW882xx smart-PA start,
  fast-exit handling, 60 % default volume). A clean rebuild from this tree
  requires staging the stock A17 audio runtime and modules locally (待验证
  end-to-end for a clean-room build).
- **Wi-Fi** — WCN786x (`peach v2`) module loader, Wi-Fi init hooks and a
  stock-derived configuration overlay are in the tree. The project's builds
  passed Wi-Fi network tests; a clean rebuild requires the stock driver module
  closure and firmware from the matching stock firmware (待验证 end-to-end for
  a clean-room build).

Both optional features need proprietary blobs that are **not** in this
repository; the required paths are listed in
[`docs/AERA-NOTES.md`](docs/AERA-NOTES.md).

## Android 17 TEE replacement and decryption correction

The project device runs stock Android 17, while the AERA tree is built from an
AOSP 16 recovery base. The corrected TEE communication chain uses the matching
Android 17 stock bytes for these eight recovery-ramdisk files:

- `system/bin/qseecomd`
- `system/lib64/libQSEEComAPI.so`
- `system/lib64/hw/libqtigatekeeper.so`
- `system/lib64/libdrmfs.so`
- `system/lib64/libminkdescriptor.so`
- `system/lib64/libdmabufheap.so`
- `system/lib64/libion.so`
- `system/lib64/libqcbor.so`

The same correction is described with per-file sizes and reproduction notes in
[`docs/AERA-NOTES.md`](docs/AERA-NOTES.md). The eight files are proprietary
Lenovo/Qualcomm bytes and are **not distributed here**; builders must stage
them from matching stock firmware they are entitled to use. 11 further
Android-17-substituted crypto files are documented in
`proprietary-overrides.tsv` (`status=substituted`).

In addition, the 2026-11-07 project build included a **FBE storage unlock
fix** (so `/sdcard` is plaintext after decryption). That fix lives in the
recovery source tree, not in this device tree; see
[`docs/AERA-NOTES.md`](docs/AERA-NOTES.md) for scope and caveats.

## Proprietary files

This repository is structured so Lenovo/Qualcomm proprietary binaries are
**not committed to Git**.

- `proprietary-files.tsv` — required target path and SHA-256 for each external
  payload file (103 targets).
- `proprietary-sources.tsv` — acquisition mapping: 25 files from matching
  TB323FU stock firmware, 78 from the public polygraphene TB322FC donor tree.
- `proprietary-overrides.tsv` — documented Android 17 substitutions.
- `scripts/acquire-proprietary-files.sh` — stages a locally supplied cache and
  refuses files whose hash does not match.

The optional audio/Wi-Fi stock blobs (modules, PAL/AGM runtime, DSP services,
firmware) are additional external material required only for those features;
see [`docs/AERA-NOTES.md`](docs/AERA-NOTES.md).

## Build

The build target is **TB323FU**; TB322FC references identify the upstream donor
base only.

### Dependencies

| Dependency | Purpose | Notes |
| --- | --- | --- |
| Linux build host | AERA/AOSP source build | Ubuntu-based distribution with a normal AOSP build environment |
| `repo`, `git`, `python3`, `sha256sum`, `rsync`, `cp`, `cmp`, `stat` | source sync + payload acquisition/verification | checked by the project scripts |
| AERA source checkout | build tree | `AERA-Recovery/android_manifest`, branch `aera-16.0` |
| AOSP 16 manifest projects | build tree | resolved by `repo sync` from the AERA manifest |
| 103 proprietary payload files | build payload | acquired separately; never committed |
| Six shell-tool prebuilts | `curl`, `fastfetch`, `git`, `wget`, `zsh`, `zstd` | pinned by `prebuilt-tools.tsv`; licenses under `LICENSES/third-party-tools/` |
| JDK 17 or 21 | Android build | both are usable; JDK 21 was the default during development |
| Disk space | source + output | plan for a large AOSP checkout and output tree (tens of GB); exact size depends on manifest pruning |
| `ccache` | optional build acceleration | not required |

### Source sync and build

```bash
# 1) sync the AERA source tree (the project used the default pruned manifest)
repo init -u https://github.com/AERA-Recovery/android_manifest.git -b aera-16.0
repo sync -c --force-sync --no-clone-bundle --no-tags -j$(nproc)

# 2) stage this device tree in the source checkout (drop .git first)
#    device/lenovo/TB323FU/

# 3) provide the proprietary payload
scripts/acquire-proprietary-files.sh --stock-root /path/to/TB323FU-stock-root

# 4) clean the product output directory (required: the ramdisk packer fails on
#    stale symlinks when the output directory is reused)
rm -rf out/target/product/TB323FU

# 5) configure and build
source build/envsetup.sh
lunch twrp_TB323FU-bp2a-eng
mka adbd recoveryimage
```

The product configuration is provided by `aera_TB323FU.mk` plus the AERA
environment setup in `vendorsetup.sh`; it sets, among other things,
`AERA_USE_UPDATED_MAGISKBOOT=0` (the default prebuilt `magiskboot` is ELF
aligned to 4 KiB and matches this 4 KiB-page kernel; the `_updated` variant is
16 KiB aligned and must not be used) and `ro.aera.live_fastbootd` stays false.

The produced image is `out/target/product/TB323FU/recovery.img` and must fit
the 100 MiB recovery partition. The 2026-11-07 hotfix5 build had a
`ramdisk-recovery.img` of 89,470,975 bytes (the 2026-11-06 R1.0 fixes build had
70,709,037 bytes), so the exact headroom depends on which optional features are
enabled. Always measure the produced image and keep it within 104,857,600
bytes.

Notes:

- The project's recovery-source fixes (UI patches, FBE unlock patches, logcat
  fixes, etc.) are not part of the AERA manifest; if you re-sync the tree they
  must be re-applied. Only some of them are documented in this repository (see
  [`docs/AERA-NOTES.md`](docs/AERA-NOTES.md)).
- The inherited `scripts/` wrappers target the TWRP/OrangeFox baseline trees,
  not the AERA manifest; use the AERA command sequence above.

### Flashing

Only fastbootd can write the recovery partition on this device (bootloader
fastboot returns `unknown command` for this partition):

```bash
adb reboot fastboot
fastboot flash recovery_a AERA-R1.0-Beta-Unofficial-TB323FU-20261107-recovery.img
fastboot reboot
# then, from the booted system
adb reboot recovery
```

If a write fails with `AdbWriteEndpointSync failed ... (121)`, reset the
USB/ADB PnP device and retry. Never overwrite both recovery slots; keep the
stock slot and a verified rollback image.

## Repository layout

| Path | Content |
| --- | --- |
| `aera_TB323FU.mk`, `vendorsetup.sh` | AERA R1.0 product configuration and build environment for TB323FU |
| `audio/` | AERA audio bridge/service/PAL-player/PA-probe sources (`aera-audio-bridge`, `aera-audio-service`, `aera-palplayer`, `aera-aw-hal`) |
| `apply-audio-t10.sh`, `apply-audio-t11.sh`, `apply-audio-t12.sh` | Audio integration steps applied to this tree (idempotent, with `--dry-run` / `--revert`) |
| `recovery/root/init.recovery.audio.rc`, `init.recovery.wifi.rc`, `system/bin/aera-*` | Optional audio/Wi-Fi bring-up hooks and scripts; proprietary runtime modules are excluded |
| `recovery/root/vendor/etc/wifi/peach_v2/`, `wifi/` | Stock-derived Wi-Fi configuration overlay (`WCNSS_qcom_cfg.ini`, `wpa_supplicant*.conf`, vendor command XMLs) |
| `recovery/root/` (other) | Inherited baseline recovery configuration (init rc, fstab flags, VINTF manifests, crypto fix hooks) |
| `BoardConfig.mk`, `device.mk`, `AndroidProducts.mk`, `twrp_TB323FU.mk`, `Android.bp`, `system.prop`, `recovery.fstab` | Device configuration (baseline plus AERA integration) |
| `patches/` | Android 16 compatibility patches inherited from the baseline |
| `scripts/` | Baseline build/acquisition/verification scripts (TWRP/OrangeFox flow) |
| `proprietary-*.tsv`, `prebuilt-tools.tsv` | Hash-pinned manifests (no binary content) |
| `docs/` | Baseline reference docs plus AERA-specific notes, attribution and compliance |
| `LICENSES/` | Apache-2.0 text and third-party tool notices |

## Known issues and limitations

- **Intermittent tagged-pointer boot crash**: the 2026-11-07 build may
  occasionally crash during boot (`Pointer tag ... truncated`) and
  self-recover by rebooting. The user-confirmed state is a boot with
  `crash_counter=0`. 待验证 for a full fix.
- **Optional audio / Wi-Fi are not clean-room reproducible from this
  repository alone**: their source integration is in the tree, but the
  required proprietary stock blobs are not; features were validated in the
  project's own builds, not re-validated after a clean public rebuild (待验证).
- The eight Android 17 TEE-chain bytes are proprietary and not distributed;
  per-file provenance across stock firmware revisions is 待验证.
- The FBE storage unlock fix (2026-11-07) lives in the recovery source tree,
  not in this device tree; reproducing it requires re-applying those source
  patches.
- AERA UI content is a 1440-wide logical canvas composited 1:1 into the
  1904 × 3040 panel; full-width 1904 × 3040 layout reflow is planned for R2
  (not in this tree).
- Rotating the native canvas is not safely handled and can corrupt the display.
- GPU rendering falls back to CPU software scanout because the Adreno EGL path
  is unavailable in recovery.
- `ro.aera.live_fastbootd` is deliberately disabled (in-place live
  recovery ↔ fastbootd transition is a known crash path); transition uses the
  BCB reboot path.
- SELinux is permissive in the recovery tree; `/data/recovery/AERA` has no
  `file_contexts` (待验证 for enforcing).
- No tombstone support: the ramdisk does not include `crash_dump64`.
- `aera backup --parts misc` is not available (the recovery volume list does
  not expose `misc`); `boot` / `persist` backup works.
- MTP is skipped after a crash-restart in this baseline (the inherited
  `crash_counter` gate); PC auto-enable protection is not included.
- Restore, wipe, ZIP installation UI and OTA paths were not device-validated;
  the install zip's `INSTALL.txt` is the upstream AERA template.
- Decryption was validated with the default password path only; a custom
  lock-screen password was not tested (待验证).
- Root Manager UI is enabled (`ro.aera.root_manager.enabled=1`) but no
  KernelSU/SukiSU patching was performed on the Magisk-rooted device.
- If `.repo` metadata is pruned, the AERA banner shows a decorative
  `[Branch]: broken repo` field; it has no functional effect.
- Some inherited baseline documents (`docs/INDEX.md`, `docs/PUBLICATION_STATUS.md`,
  `docs/THIRD_PARTY_TOOLS.md`, etc.) are written for the TWRP baseline; read
  them together with [`docs/AERA-NOTES.md`](docs/AERA-NOTES.md).
- Project builds after 2026-11-07 continued as internal experiments and were
  not user-confirmed as release baselines; they are intentionally not listed
  here.

## Safety rules

- Target device: **Lenovo TB323FU only**.
- Keep an exact stock recovery backup before testing.
- Preserve a known-good recovery path.
- For first testing of a new image, flash only the intended recovery slot.
- Do not casually overwrite both recovery slots.
- Verify image hashes before flashing.
- Do not run destructive EFISP/ABL operations before validating them.

## Related projects and documentation

- Main project repository (LineageOS 24 / Android 17 system device tree for
  TB323FU): <https://github.com/UGY1412/android_device_lenovo_TB323FU>
  — build, flash, hardware-support, root-cause and troubleshooting
  documentation in English and Chinese under its `docs/` directory.
- Sibling TWRP/OrangeFox recovery device tree for the same device:
  <https://github.com/UGY1412/android_device_lenovo_TB323FU-orangefox>
- AERA upstream project: <https://github.com/AERA-Recovery/android_manifest>
- AERA build/runtime, blob and decryption notes:
  [`docs/AERA-NOTES.md`](docs/AERA-NOTES.md)
- Baseline known-good reference: [`docs/KNOWN_GOOD.md`](docs/KNOWN_GOOD.md)
- Provenance: [`TREE_PROVENANCE.md`](TREE_PROVENANCE.md)
- Attribution and compliance: [`docs/ATTRIBUTION.md`](docs/ATTRIBUTION.md),
  [`docs/COMPLIANCE.md`](docs/COMPLIANCE.md)
- Licensing: [`LICENSE`](LICENSE), [`docs/LICENSING.md`](docs/LICENSING.md),
  [`NOTICE`](NOTICE), [`LICENSES/`](LICENSES/)

---

Copyright (C) 2026 自恋也是种美 (krollv). Original project content is provided
under the terms stated in [`NOTICE`](NOTICE), [`LICENSE`](LICENSE) and
[`docs/LICENSING.md`](docs/LICENSING.md); third-party components retain their
own licenses.
