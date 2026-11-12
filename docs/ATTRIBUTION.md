# Attribution — directory-level source mapping / 归属 — 逐目录来源映射

Last updated / 最后更新: 2026-11-12

This document maps each part of the repository to its upstream origin. The
same mapping is given in English and Chinese. It complements
[`../CREDITS.md`](../CREDITS.md) (per-project credits) and
[`COMPLIANCE.md`](COMPLIANCE.md) (inclusion/exclusion policy).

本文档把仓库的每个部分映射到其上游来源，提供英文与中文两个版本。它与
[`../CREDITS.md`](../CREDITS.md)（逐项目致谢）和 [`COMPLIANCE.md`](COMPLIANCE.md)
（收录/排除策略）互补。

## English

| Path | Content | Upstream origin | Status / notes |
| --- | --- | --- | --- |
| `aera_TB323FU.mk`, `vendorsetup.sh` | AERA R1.0 product configuration and build environment for TB323FU | Project-authored adaptation modelled on the official AERA device-tree structure (`aera_<device>.mk` product switches / `AERA_*` environment) | Project terms; AERA conventions credited in `CREDITS.md` |
| `audio/` | AERA audio bridge/service, PAL player, AW882xx PA probe, `Android.bp` | Adapted from the AERA reference device-tree audio implementations (`android_device_xiaomi_myron-AERA` / `..._dodge-AERA` lineage); files carry `Copyright (C) 2026 AERA Recovery Project contributors` | Apache-2.0 per SPDX headers where present; upstream AERA terms retained |
| `apply-audio-t10.sh`, `apply-audio-t11.sh`, `apply-audio-t12.sh` | Idempotent audio integration steps | Project-authored integration scripts that apply the adapted audio sources into a device tree | Project terms |
| `recovery/root/init.recovery.audio.rc`, `recovery/root/system/bin/aera-audio-bootstrap`, `aera-pal-probe.sh` | Audio bring-up hooks and scripts | Project-authored adaptation following the AERA reference device-tree audio bring-up pattern (stock AudioReach/PAL runtime, DSP daemons, AGM) | Project terms; stock runtime it loads is not distributed |
| `recovery/root/init.recovery.wifi.rc`, `recovery/root/system/bin/aera-wlan-up.sh` | Wi-Fi bring-up hooks and module loader | Project-authored adaptation following the AERA reference device-tree Wi-Fi integration pattern (`android_device_oneplus_dodge-AERA` lineage), with TB323FU-specific driver loading | Project terms |
| `recovery/root/vendor/etc/wifi/` (`peach_v2/WCNSS_qcom_cfg.ini`, `wpa_supplicant*.conf`, `vendor_cmd.xml`, `sar-vendor-cmd.xml`) | Stock-derived Wi-Fi configuration overlay | Extracted from matching TB323FU stock vendor firmware (Lenovo/Qualcomm) | Redistribution status of these small stock config files is 待验证; see `COMPLIANCE.md` |
| `recovery/root/system/etc/security/cacerts.pem` | System CA certificate store | Android Open Source Project CA bundle | AOSP terms; standard system trust store |
| `recovery/root/` proprietary targets inherited from the baseline tree | Lenovo/Qualcomm proprietary services, libraries, firmware | Acquired separately through the hash-pinned payload flow (25 files from matching TB323FU stock firmware, 78 from public polygraphene TB322FC Git history at `c9c6a9f1287e5b416c3480c5fe06b23dc54c9ab8`) | Not distributed; builders must obtain them lawfully |
| `recovery/root/AERA/audio/`, `recovery/root/AERA/modules/`, `recovery/root/system/bin/aera-pd-mapper`, `aera-dspservice`, `aera-audioadsprpcd` (optional audio/Wi-Fi staging) | Stock A17 audio runtime, DSP daemons and kernel module closures | Extracted from matching stock firmware (`vendor.img`, `vendor_dlkm.img`, `system_dlkm.img`, `modem` firmware) | **Not committed**; local staging only; see `AERA-NOTES.md` |
| `BoardConfig.mk`, `device.mk`, `AndroidProducts.mk`, `twrp_TB323FU.mk`, `Android.bp`, `system.prop`, `recovery.fstab` | Device configuration | Derived from the validated TB323FU TWRP/OrangeFox baseline device tree (isrgish/TB323FU-TWRP lineage) plus AERA integration; TB323FU-specific A17 corrections | Apache-2.0 SPDX headers on inherited files; project changes under project terms |
| `recovery/root/` text files (init rc, `twrp.flags`, VINTF manifests, crypto hooks) | Recovery ramdisk configuration | Baseline device tree lineage with TB323FU corrections | Per-file notices retained |
| `patches/` | Android 16 compatibility patches | Inherited baseline patches; two retain their upstream author (polygraphene) | Upstream author and terms retained |
| `scripts/` | Baseline build/acquisition/verification scripts | Project-authored for the validated TWRP/OrangeFox baseline; the AERA build uses the AERA manifest command sequence instead | Project terms; third-party tool notices under `LICENSES/third-party-tools/` |
| `proprietary-files.tsv`, `proprietary-sources.tsv`, `proprietary-overrides.tsv`, `prebuilt-tools.tsv` | Hash-pinned manifests (paths, sizes, SHA-256; no binary content) | Project-authored from provenance research | Project terms |
| `docs/` (baseline documents) | Inherited TWRP/OrangeFox baseline documentation | Project-authored for the validated baseline (fix3b) | Project terms; read together with `AERA-NOTES.md` |
| `docs/AERA-NOTES.md`, this file, `docs/COMPLIANCE.md`, `README*.md`, `AUTHORS.md`, `CREDITS.md`, `NOTICE` | AERA-specific documentation and attribution | Project-authored | Project terms; see `NOTICE` |
| `LICENSES/Apache-2.0.txt` | Apache-2.0 license text | Apache Software Foundation | Verbatim license text |
| `LICENSES/third-party-tools/` | License/notice texts for the six prebuilt shell tools | Upstream curl, fastfetch, git, wget, zsh, zstd and their dependencies | Verbatim notices; see `NOTICE-SOURCE-MAP.tsv` |
| `prebuilts/` (when present) | Six tracked third-party shell-tool binaries | Third-party upstream projects (see `docs/THIRD_PARTY_TOOLS.md`) | Pinned by `prebuilt-tools.tsv`; license texts under `LICENSES/third-party-tools/` |
| `THIRD_PARTY_SOURCE_BUNDLE.sha256` | Checksum pointer to the corresponding-source bundle | Project-authored / third-party sources | See `docs/THIRD_PARTY_TOOLS.md` |

## 中文

| 路径 | 内容 | 上游来源 | 状态 / 说明 |
| --- | --- | --- | --- |
| `aera_TB323FU.mk`、`vendorsetup.sh` | TB323FU 的 AERA R1.0 产品配置与构建环境 | 本项目按 AERA 官方设备树结构（`aera_<device>.mk` 产品开关 / `AERA_*` 环境）改编编写 | 项目条款；AERA 约定在 `CREDITS.md` 中署名 |
| `audio/` | AERA 音频桥/服务、PAL player、AW882xx 功放探测、`Android.bp` | 改编自 AERA 参考设备树音频实现（`android_device_xiaomi_myron-AERA` / `..._dodge-AERA` 传承）；文件带 `Copyright (C) 2026 AERA Recovery Project contributors` | 有 SPDX 头处为 Apache-2.0；保留上游 AERA 条款 |
| `apply-audio-t10.sh`、`apply-audio-t11.sh`、`apply-audio-t12.sh` | 幂等的音频集成步骤 | 本项目编写的集成脚本，把改编后的音频源码应用到设备树 | 项目条款 |
| `recovery/root/init.recovery.audio.rc`、`recovery/root/system/bin/aera-audio-bootstrap`、`aera-pal-probe.sh` | 音频 bring-up 钩子与脚本 | 本项目按 AERA 参考设备树音频 bring-up 模式（原厂 AudioReach/PAL 运行时、DSP daemon、AGM）改编编写 | 项目条款；其加载的原厂运行时不随仓库分发 |
| `recovery/root/init.recovery.wifi.rc`、`recovery/root/system/bin/aera-wlan-up.sh` | Wi-Fi bring-up 钩子与模块加载器 | 本项目按 AERA 参考设备树 Wi-Fi 集成模式（`android_device_oneplus_dodge-AERA` 传承）改编，并加入 TB323FU 专用驱动加载 | 项目条款 |
| `recovery/root/vendor/etc/wifi/`（`peach_v2/WCNSS_qcom_cfg.ini`、`wpa_supplicant*.conf`、`vendor_cmd.xml`、`sar-vendor-cmd.xml`） | 原厂导出的 Wi-Fi 配置 overlay | 提取自配套 TB323FU 原厂 vendor 固件（联想/高通） | 这些小体积原厂配置文件的再分发状态为待验证；见 `COMPLIANCE.md` |
| `recovery/root/system/etc/security/cacerts.pem` | 系统 CA 证书库 | Android 开源项目 CA 证书包 | AOSP 条款；标准系统信任库 |
| 从基线继承的 `recovery/root/` 专有目标 | 联想/高通专有服务、库与固件 | 通过哈希锁定 payload 流程另行获取（25 个来自配套 TB323FU 原厂固件，78 个来自公开的 polygraphene TB322FC Git 历史 `c9c6a9f1287e5b416c3480c5fe06b23dc54c9ab8`） | 不分发；构建者须合法获取 |
| `recovery/root/AERA/audio/`、`recovery/root/AERA/modules/`、`recovery/root/system/bin/aera-pd-mapper`、`aera-dspservice`、`aera-audioadsprpcd`（可选音频/Wi-Fi 暂存） | 原厂 A17 音频运行时、DSP daemon 与内核模块闭包 | 从配套原厂固件（`vendor.img`、`vendor_dlkm.img`、`system_dlkm.img`、`modem` 固件）提取 | **不提交**；仅本地暂存；见 `AERA-NOTES.md` |
| `BoardConfig.mk`、`device.mk`、`AndroidProducts.mk`、`twrp_TB323FU.mk`、`Android.bp`、`system.prop`、`recovery.fstab` | 设备配置 | 衍生自已验证的 TB323FU TWRP/OrangeFox 基线设备树（isrgish/TB323FU-TWRP 传承）并加入 AERA 集成与 TB323FU 专用 A17 修正 | 继承文件保留 Apache-2.0 SPDX 头；项目改动按项目条款 |
| `recovery/root/` 文本文件（init rc、`twrp.flags`、VINTF manifest、crypto 钩子） | recovery ramdisk 配置 | 基线设备树传承 + TB323FU 修正 | 保留逐文件声明 |
| `patches/` | Android 16 兼容补丁 | 继承的基线补丁；其中两个保留上游作者（polygraphene） | 保留上游作者与条款 |
| `scripts/` | 基线构建/获取/校验脚本 | 本项目为已验证的 TWRP/OrangeFox 基线编写；AERA 构建改用 AERA manifest 命令序列 | 项目条款；第三方工具声明见 `LICENSES/third-party-tools/` |
| `proprietary-files.tsv`、`proprietary-sources.tsv`、`proprietary-overrides.tsv`、`prebuilt-tools.tsv` | 哈希锁定清单（路径、大小、SHA-256；不含二进制内容） | 本项目基于来源研究编写 | 项目条款 |
| `docs/`（基线文档） | 继承的 TWRP/OrangeFox 基线文档 | 本项目为已验证基线（fix3b）编写 | 项目条款；请结合 `AERA-NOTES.md` 阅读 |
| `docs/AERA-NOTES.md`、本文件、`docs/COMPLIANCE.md`、`README*.md`、`AUTHORS.md`、`CREDITS.md`、`NOTICE` | AERA 专用文档与归属 | 本项目编写 | 项目条款；见 `NOTICE` |
| `LICENSES/Apache-2.0.txt` | Apache-2.0 许可原文 | Apache Software Foundation | 逐字许可原文 |
| `LICENSES/third-party-tools/` | 六个预编译 shell 工具的许可/声明原文 | 上游 curl、fastfetch、git、wget、zsh、zstd 及其依赖 | 逐字声明；见 `NOTICE-SOURCE-MAP.tsv` |
| `prebuilts/`（存在时） | 六个随仓库跟踪的第三方 shell 工具二进制 | 第三方上游项目（见 `docs/THIRD_PARTY_TOOLS.md`） | 由 `prebuilt-tools.tsv` 锁定；许可原文见 `LICENSES/third-party-tools/` |
| `THIRD_PARTY_SOURCE_BUNDLE.sha256` | 对应源码包校验指针 | 本项目编写 / 第三方源码 | 见 `docs/THIRD_PARTY_TOOLS.md` |

## Remarks / 备注

- Do not commit anything under `recovery/root/AERA/`; that path is local staging
  for stock blobs and modules. / 不要把 `recovery/root/AERA/` 下的任何内容提交；
  该路径是原厂 blob 与模块的本地暂存区。
- Repository-level licensing: `LICENSE` (mixed-origin) and
  `docs/LICENSING.md`. / 仓库级许可：`LICENSE`（混合来源）与
  `docs/LICENSING.md`。
- No binary file is added by the documentation/compliance work documented here.
  / 本文档/合规工作不新增任何二进制文件。
