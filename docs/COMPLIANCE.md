# Compliance and redistribution notes / 合规与再分发说明

Last updated / 最后更新: 2026-11-12

This document records what the repository intentionally includes and excludes,
how third-party material is handled, and how to contact the maintainers about a
takedown request. The same content is provided in English and Chinese.

本文档记录仓库刻意收录/排除的内容、第三方材料的处理方式，以及下架请求的联系
渠道。以下提供英文与中文两个版本。

## English

### 1. Scope

This repository is an unofficial community port of **AERA Recovery R1.0** to
the Lenovo Legion Y700 Gen 5 (TB323FU). It is **not** an official AERA, Lenovo,
Qualcomm, TeamWin or OrangeFox release. It contains AERA product-layer
integration, device/recovery configuration, audio/Wi-Fi bring-up sources,
project scripts, patches, documentation and hash-pinned manifests. It does
**not** contain Lenovo/Qualcomm proprietary binaries, stock firmware images,
proprietary audio/Wi-Fi runtime blobs, build outputs or private development
caches.

### 2. Included in Git

| Item | Location | Basis |
| --- | --- | --- |
| AERA product configuration and build environment | `aera_TB323FU.mk`, `vendorsetup.sh` | Project-authored adaptation of the AERA device-tree structure |
| Audio bridge/service/PAL-player/PA-probe sources | `audio/`, `apply-audio-t*.sh` | Adapted from AERA reference device trees; SPDX headers where present |
| Audio/Wi-Fi bring-up hooks and scripts | `recovery/root/init.recovery.*.rc`, `recovery/root/system/bin/aera-*` | Project-authored adaptation of AERA integration patterns |
| Device/recovery configuration (text) | repository root, inherited `recovery/root/` | Baseline-derived project work; Apache-2.0 SPDX headers where present |
| Compatibility patches | `patches/` | Inherited baseline; two patches retain their upstream author (polygraphene) |
| Documentation | `README*.md`, `AUTHORS.md`, `CREDITS.md`, `NOTICE`, `docs/`, `TREE_PROVENANCE.md` | Project-authored documentation |
| Hash-pinned payload/tool manifests (no binaries) | `proprietary-files.tsv`, `proprietary-sources.tsv`, `proprietary-overrides.tsv`, `prebuilt-tools.tsv` | Project-authored manifests recording paths/sizes/SHA-256 |
| License texts and third-party notices | `LICENSES/` | Verbatim upstream license/notice texts |
| Six third-party shell tools | `prebuilts/` (when staged) | Tracked third-party binary prebuilts, pinned by `prebuilt-tools.tsv` |
| Small stock-derived Wi-Fi configuration overlay | `recovery/root/vendor/etc/wifi/` | Extracted from matching stock firmware; redistribution status 待验证 (see §7) |
| System CA certificate store | `recovery/root/system/etc/security/cacerts.pem` | AOSP CA bundle |

### 3. Excluded from Git

| Item | Why excluded |
| --- | --- |
| Lenovo/Qualcomm proprietary services, libraries and firmware (inherited payload paths listed in `.gitignore` and `proprietary-files.tsv`) | No redistribution rights; builders must acquire them from a source they are legally entitled to use |
| Android 17 TEE-chain files used by the decryption correction (8 files) | Proprietary stock bytes; must be staged from matching stock firmware |
| Stock A17 audio runtime and DSP daemons staged under `recovery/root/AERA/audio/` and `recovery/root/system/bin/aera-pd-mapper`, `aera-dspservice`, `aera-audioadsprpcd` | Proprietary stock bytes; local staging only |
| Stock audio/Wi-Fi kernel module closures staged under `recovery/root/AERA/modules/` | Proprietary stock bytes; local staging only |
| Stock firmware images / partition dumps | Proprietary; not redistributable by this project |
| Built recovery images, ramdisks, install zips, OTA payloads | Build outputs; not source |
| Private development caches, private blob directories | Private; never published |
| Credentials, keys, local environment files | Security; never published |
| User data / device-specific dumps (including serial numbers and MAC addresses) | Privacy and security; never published |

The acquisition flow is deliberately hash-pinned: `proprietary-sources.tsv`
pins every payload target and `scripts/acquire-proprietary-files.sh` verifies
size/SHA-256 before installing anything into the recovery tree.

### 4. Third-party handling

- Repository-level licensing: [`LICENSE`](../LICENSE) states the mixed-origin
  policy; per-file SPDX notices govern each file.
- Upstream copyright/SPDX/license notices are preserved per file.
- AERA-derived audio/Wi-Fi code and scripts retain the AERA upstream terms and
  are credited in `CREDITS.md`.
- The two polygraphene-authored patches retain their `From:`/`Subject:` headers.
- The six prebuilt shell tools keep their license/notice texts under
  `LICENSES/third-party-tools/`; their corresponding source/provenance bundle is
  identified in `docs/THIRD_PARTY_TOOLS.md`.
- No blanket license is asserted over files that lack an explicit license or a
  clear upstream origin. See `docs/LICENSING.md`.

### 5. Takedown / rights-holder contact (72 hours)

If you are a rights holder and believe material in this repository should not
be redistributed:

1. Open an issue on this repository (preferred), or contact the maintainer's
   GitHub account: <https://github.com/UGY1412>.
2. Include the exact file path(s), the material you own, and the legal basis
   for the request.
3. The maintainers will acknowledge and act on a clear, complete request
   within **72 hours** — typically by removing or replacing the identified
   material. No dedicated e-mail address has been published for this project
   yet; if one is added later it will be listed here (待验证 / to be verified).

This section describes project policy.

### 6. Disclaimer

- The project is provided **AS IS**, without warranty of any kind.
- It is unofficial and not affiliated with or endorsed by AERA, Lenovo,
  Qualcomm, Google, TeamWin, or the OrangeFox Recovery Project. All trademarks
  belong to their respective owners.
- Nothing in this repository grants rights to proprietary Lenovo/Qualcomm
  material.
- This is compliance documentation; obtain
  professional advice if you intend to redistribute third-party material.

### 7. Items marked "to be verified" (待验证)

- Redistribution status of the small stock-derived Wi-Fi configuration files
  under `recovery/root/vendor/etc/wifi/`.
- Per-file license identification for inherited device-tree and recovery files.
- Exact redistribution terms of the isrgish/TB323FU-TWRP baseline (no explicit
  LICENSE was found upstream; only a provenance/lineage statement).
- Provenance of the eight Android 17 TEE-chain files across stock firmware
  revisions, and the exact set of stock files required by the optional
  audio/Wi-Fi features.
- License status of some AERA/OrangeFox/LineageOS-adjacent components where no
  per-file notice is present in this tree.
- Whether the AERA install zip's ABL-preservation path introduces any
  additional redistribution obligations (it operates on the device's own ABL).

## 中文

### 1. 范围

本仓库是 **AERA Recovery R1.0** 面向联想拯救者 Y700 五代（TB323FU）的非官方
社区移植，**不是** AERA、联想、高通、TeamWin 或 OrangeFox 的官方发布。它包含
AERA 产品层集成、设备/recovery 配置、音频/Wi-Fi bring-up 源码、项目脚本、补丁、
文档与哈希锁定清单；**不**包含联想/高通专有二进制、原厂固件镜像、专有音频/Wi-Fi
运行时 blob、构建产物或私有开发缓存。

### 2. Git 中收录的内容

| 项目 | 位置 | 依据 |
| --- | --- | --- |
| AERA 产品配置与构建环境 | `aera_TB323FU.mk`、`vendorsetup.sh` | 本项目按 AERA 设备树结构改编编写 |
| 音频桥/服务/PAL player/PA 探测源码 | `audio/`、`apply-audio-t*.sh` | 改编自 AERA 参考设备树；有 SPDX 头处保留 |
| 音频/Wi-Fi bring-up 钩子与脚本 | `recovery/root/init.recovery.*.rc`、`recovery/root/system/bin/aera-*` | 本项目按 AERA 集成模式改编编写 |
| 设备/recovery 配置（文本） | 仓库根目录、继承的 `recovery/root/` | 基于基线衍生的本项目成果；有 SPDX 头处为 Apache-2.0 |
| 兼容补丁 | `patches/` | 继承的基线；其中两个补丁保留上游作者（polygraphene） |
| 文档 | `README*.md`、`AUTHORS.md`、`CREDITS.md`、`NOTICE`、`docs/`、`TREE_PROVENANCE.md` | 本项目编写的文档 |
| 哈希锁定 payload/工具清单（无二进制） | `proprietary-files.tsv`、`proprietary-sources.tsv`、`proprietary-overrides.tsv`、`prebuilt-tools.tsv` | 本项目编写、记录路径/大小/SHA-256 的清单 |
| 许可原文与第三方声明 | `LICENSES/` | 逐字复制的上游许可/声明原文 |
| 六个第三方 shell 工具 | `prebuilts/`（暂存后） | 随仓库跟踪的第三方二进制预编译件，由 `prebuilt-tools.tsv` 锁定 |
| 小体积原厂 Wi-Fi 配置 overlay | `recovery/root/vendor/etc/wifi/` | 提取自配套原厂固件；再分发状态待验证（见 §7） |
| 系统 CA 证书库 | `recovery/root/system/etc/security/cacerts.pem` | AOSP CA 证书包 |

### 3. Git 中排除的内容

| 项目 | 排除原因 |
| --- | --- |
| 联想/高通专有服务、库与固件（`.gitignore` 与 `proprietary-files.tsv` 中列出的继承 payload 路径） | 无再分发权；构建者须从合法来源获取 |
| 解密修正所用的 Android 17 TEE 通信链文件（8 个） | 专有原厂字节；须从配套原厂固件暂存 |
| 暂存在 `recovery/root/AERA/audio/` 与 `recovery/root/system/bin/aera-pd-mapper`、`aera-dspservice`、`aera-audioadsprpcd` 的原厂 A17 音频运行时与 DSP daemon | 专有原厂字节；仅本地暂存 |
| 暂存在 `recovery/root/AERA/modules/` 的原厂音频/Wi-Fi 内核模块闭包 | 专有原厂字节；仅本地暂存 |
| 原厂固件镜像 / 分区 dump | 专有材料；本项目无权再分发 |
| 已构建的 recovery 镜像、ramdisk、安装 zip、OTA payload | 构建产物，非源码 |
| 私有开发缓存、私有 blob 目录 | 私有；永不公开 |
| 凭据、密钥、本地环境文件 | 安全；永不公开 |
| 用户数据 / 设备相关 dump（含序列号、MAC 地址） | 隐私与安全；永不公开 |

获取流程刻意采用哈希锁定：`proprietary-sources.tsv` 锁定每个 payload 目标，
`scripts/acquire-proprietary-files.sh` 在写入 recovery 树之前校验大小/SHA-256。

### 4. 第三方材料处理

- 仓库级许可说明见 [`LICENSE`](../LICENSE)（混合来源；逐文件 SPDX 声明为准）。
- 逐文件保留上游版权/SPDX/许可声明。
- AERA 衍生的音频/Wi-Fi 代码与脚本保留 AERA 上游条款，并在 `CREDITS.md` 中
  署名。
- 两个由 polygraphene 编写的补丁保留其 `From:`/`Subject:` 头。
- 六个预编译 shell 工具在 `LICENSES/third-party-tools/` 下保留许可/声明原文；
  其对应源码/来源包在 `docs/THIRD_PARTY_TOOLS.md` 中标识。
- 对于缺少显式许可或明确上游来源的文件，不主张任何笼统许可。见
  `docs/LICENSING.md`。

### 5. 下架 / 权利人联系（72 小时）

如果你是权利人，并认为本仓库中的材料不应被再分发：

1. 在本仓库提交 issue（首选），或联系维护者的 GitHub 账号：
   <https://github.com/UGY1412>。
2. 注明确切的文件路径、你拥有权利的材料，以及请求的法律依据。
3. 维护者将在 **72 小时**内对清晰、完整的请求作出确认并采取行动——通常为移除
   或替换被指出的材料。本项目目前尚未公布专用电子邮箱；如后续添加，会在此处
   更新（待验证）。

本节为项目实务政策，不构成法律意见。

### 6. 免责

- 本项目按 **“现状（AS IS）”** 提供，不附带任何形式的担保。
- 本项目为非官方项目，与 AERA、联想、高通、Google、TeamWin、OrangeFox
  Recovery Project 无隶属或背书关系。所有商标归其各自所有者。
- 本仓库中的任何内容都不授予联想/高通专有材料的任何权利。
- 本文档为实务合规文档，不构成法律意见；如计划再分发第三方材料，请获取专业
  意见。

### 7. 标注为“待验证”的事项

- `recovery/root/vendor/etc/wifi/` 下小体积原厂 Wi-Fi 配置文件的再分发状态。
- 继承的设备树与 recovery 文件的逐文件许可识别。
- isrgish/TB323FU-TWRP 基线的确切再分发条款（上游未发现显式 LICENSE，只有
  来源/传承声明）。
- 8 个 Android 17 TEE 通信链文件在各原厂固件版本上的来源，以及可选音频/Wi-Fi
  功能所需的原厂文件确切集合。
- 本树中部分与 AERA/OrangeFox/LineageOS 相关、但缺失逐文件声明的组件的许可
  状态。
- AERA 安装 zip 的 ABL 保活路径是否引入额外再分发义务（它只操作设备自身的
  ABL）。
