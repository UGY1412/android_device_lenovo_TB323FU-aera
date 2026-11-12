# Credits and third-party sources / 致谢与第三方来源

Last updated / 最后更新: 2026-11-12

This file lists the third-party projects, upstream sources and tools connected to
this repository. The same rows are given in English and Chinese below. See also
[`docs/ATTRIBUTION.md`](docs/ATTRIBUTION.md) for the directory-level mapping and
[`docs/COMPLIANCE.md`](docs/COMPLIANCE.md) for inclusion/exclusion policy.

本文件列出与本仓库相关的第三方项目、上游来源与工具。下表提供英文与中文两个版本，
行与数据完全一致。逐目录的来源映射见 [`docs/ATTRIBUTION.md`](docs/ATTRIBUTION.md)，
收录/排除策略见 [`docs/COMPLIANCE.md`](docs/COMPLIANCE.md)。

## English

| # | Component / source | Upstream | Relationship to this repository | License / notice status |
| --- | --- | --- | --- | --- |
| 1 | AERA Recovery Project | <https://github.com/AERA-Recovery/android_manifest> (branch `aera-16.0`) | Primary upstream: AERA build system, AERA UI/CLI and product-layer conventions this port is built on | Upstream project licenses; ported/adapted code retains upstream terms |
| 2 | AERA reference device trees (e.g. `android_device_xiaomi_myron-AERA`, `..._dodge-AERA`) | <https://github.com/AERA-Recovery> | Reference implementations for the audio bridge/service, audio bootstrap and Wi-Fi integration patterns adapted for TB323FU | Upstream project licenses |
| 3 | Android Open Source Project (AOSP) | <https://source.android.com/> | Platform build-system conventions, recovery interfaces and Apache-2.0 SPDX headers on inherited files | Apache-2.0; per-file SPDX notices retained |
| 4 | LineageOS | <https://github.com/LineageOS> | Related Android platform ecosystem and conventions used by the wider TB323FU project; no LineageOS source was identified as vendored in this recovery tree (per-file verification 待验证) | Upstream licenses per repository; per-file notices retained |
| 5 | TWRP / TeamWin Recovery Project | <https://github.com/TeamWin> | Recovery base and device-tree conventions in this tree's baseline lineage | Upstream licenses retained per file; reproduced notice texts under `LICENSES/` |
| 6 | TWRP-Test | <https://github.com/TWRP-Test/platform_manifest_twrp_aosp> | Build manifest of the inherited validated TWRP baseline (`twrp-16.0`) | Manifest repository upstream terms |
| 7 | polygraphene TB322FC work | <https://github.com/polygraphene/android_device_lenovo_TB322FC> and <https://github.com/polygraphene/android_bootable_recovery> | TB322FC donor device-tree bytes (78 of the 103 acquired payload files, not distributed here) and the inherited recovery fork `twrp-16.0-TB322FC` | Upstream licenses per repository; patch authorship retained |
| 8 | OrangeFox Recovery Project | <https://gitlab.com/OrangeFox> | Baseline lineage of the validated OrangeFox R12.0 (`fox_16.0`) recovery tree this port derives from; OrangeFox release images are build outputs, not committed here | Upstream project licenses; not vendored as source in this tree (待验证 per file) |
| 9 | isrgish / TB323FU-TWRP | <https://github.com/isrgish/TB323FU-TWRP> | Original TB323FU TWRP device tree this repository derives from (through the validated baseline) | **No explicit LICENSE file**: the upstream repository declares provenance/lineage only, and no license grant is asserted by the upstream author. Treated as an attributed upstream source; confirm reuse terms with the upstream author. |
| 10 | aweiyry / lenovo-ota-tool | <https://github.com/aweiyry/lenovo-ota-tool> | External tool used to obtain/handle Lenovo OTA and stock partition images; not vendored | MIT |
| 11 | DeepSeek V4.1 Flash 1017 | — | Co-author (collaboration on development and documentation) | — |
| 12 | Six prebuilt shell tools: curl, fastfetch, git, wget, zsh, zstd | see `docs/THIRD_PARTY_TOOLS.md` | Tracked third-party binary prebuilts used by the recovery build | Per-tool licenses; texts under `LICENSES/third-party-tools/` |
| 13 | Magisk (topjohnwu) | <https://github.com/topjohnwu/Magisk> | The project device is Magisk-rooted; Root Manager integration is referenced but no KernelSU/SukiSU patching is performed | GPL-3.0 (upstream); not bundled in this Git repository |
| 14 | Awinic (AW882xx) speaker amplifier driver | vendor kernel driver (stock firmware) | The optional audio path drives the stock AW882xx smart-PA through the stock kernel driver; no driver source is included | Vendor kernel driver, stock firmware only; not redistributed |

## 中文

| # | 组件 / 来源 | 上游 | 与本仓库的关系 | 许可 / 声明状态 |
| --- | --- | --- | --- | --- |
| 1 | AERA Recovery Project | <https://github.com/AERA-Recovery/android_manifest>（分支 `aera-16.0`） | 主要上游：本移植所基于的 AERA 构建系统、AERA UI/CLI 与产品层约定 | 上游项目许可；移植/适配代码保留上游条款 |
| 2 | AERA 参考设备树（如 `android_device_xiaomi_myron-AERA`、`..._dodge-AERA`） | <https://github.com/AERA-Recovery> | 音频桥/服务、音频 bootstrap 与 Wi-Fi 集成模式为 TB323FU 适配时所参考的实现 | 上游项目许可 |
| 3 | Android 开源项目（AOSP） | <https://source.android.com/> | 平台构建系统约定、recovery 接口，以及继承文件上的 Apache-2.0 SPDX 头 | Apache-2.0；保留逐文件 SPDX 声明 |
| 4 | LineageOS | <https://github.com/LineageOS> | 更广泛的 TB323FU 项目所使用的相关 Android 平台生态与约定；本 recovery 树中未识别到直接引入的 LineageOS 源码（逐文件核验待验证） | 各仓库上游许可；保留逐文件声明 |
| 5 | TWRP / TeamWin Recovery Project | <https://github.com/TeamWin> | 本设备树基线传承中的 recovery 基础与设备树约定 | 逐文件保留上游许可；复制的声明原文见 `LICENSES/` |
| 6 | TWRP-Test | <https://github.com/TWRP-Test/platform_manifest_twrp_aosp> | 继承的已验证 TWRP 基线（`twrp-16.0`）构建 manifest | manifest 仓库上游条款 |
| 7 | polygraphene 的 TB322FC 工作 | <https://github.com/polygraphene/android_device_lenovo_TB322FC> 与 <https://github.com/polygraphene/android_bootable_recovery> | TB322FC donor 设备树字节（103 个获取 payload 中的 78 个，不在本仓库分发）以及继承的 recovery 分支 `twrp-16.0-TB322FC` | 各仓库上游许可；保留补丁作者信息 |
| 8 | OrangeFox Recovery Project | <https://gitlab.com/OrangeFox> | 本移植所衍生自的已验证 OrangeFox R12.0（`fox_16.0`）recovery 树的基线传承；OrangeFox 发布镜像属于构建产物，不在本仓库提交 | 上游项目许可；本仓库未以源码形式引入（逐文件待验证） |
| 9 | isrgish / TB323FU-TWRP | <https://github.com/isrgish/TB323FU-TWRP> | 本仓库（经由已验证基线）所衍生的原始 TB323FU TWRP 设备树 | **无显式 LICENSE 文件**：上游仓库只声明来源/传承，上游作者未声明任何许可授权。按“已署名的上游来源”对待；复用条款需与上游作者确认。 |
| 10 | aweiyry / lenovo-ota-tool | <https://github.com/aweiyry/lenovo-ota-tool> | 用于获取/处理联想 OTA 与 stock 分区镜像的外部工具；未随仓库分发 | MIT |
| 11 | DeepSeek V4.1 Flash 1017 | — | 共同署名（协作开发与文档） | — |
| 12 | 六个预编译 shell 工具：curl、fastfetch、git、wget、zsh、zstd | 见 `docs/THIRD_PARTY_TOOLS.md` | recovery 构建所使用的、随仓库跟踪的第三方二进制预编译件 | 各工具许可；原文见 `LICENSES/third-party-tools/` |
| 13 | Magisk（topjohnwu） | <https://github.com/topjohnwu/Magisk> | 项目设备为 Magisk root；引用了 Root Manager 集成，但未执行任何 KernelSU/SukiSU patch | GPL-3.0（上游）；本 Git 仓库未捆绑其源码 |
| 14 | Awinic（AW882xx）扬声器功放驱动 | 厂商内核驱动（原厂固件） | 可选音频通路通过原厂内核驱动驱动 stock AW882xx 智能功放；不包含驱动源码 | 厂商内核驱动，仅限原厂固件；不再分发 |

## Notes / 说明

- Nothing in this file grants rights to proprietary Lenovo/Qualcomm material.
  / 本文件不授予联想/高通专有材料的任何权利。
- License status statements describe the upstream projects as understood at the
  time of writing; verify before redistribution. / 许可状态说明反映撰写时对上游项目的
  理解；再分发前请自行核实。
