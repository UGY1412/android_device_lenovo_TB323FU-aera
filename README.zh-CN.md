# TB323FU AERA Recovery R1.0 设备树（非官方移植）

作者/维护者：自恋也是种美，@DeepSeek V4.1 Flash 1017

面向 **联想拯救者 Y700 五代（TB323FU / Baldur，高通 SM8850P）** 的、社区维护的
**AERA Recovery R1.0** 非官方设备树。

本设备树在本项目已验证的 TB323FU recovery 基线（TWRP 3.7.1 Android 16 设备树
及其 OrangeFox R12.0 Android 17 线）之上把 AERA Recovery 移植到 TB323FU，加入
**AERA 产品层**（AERA 构建配置、AERA UI 与 CLI）、本项目的 **Android 17 解密
修正**、**FBE 存储解锁修复** 的传承，以及可选的 **音频 / Wi-Fi** 启用源码。
AERA 本身是独立的第三方 recovery 项目；本移植不是 AERA 官方设备构建。本项目与
Lenovo、Qualcomm、Google、AERA、TeamWin、OrangeFox Recovery Project 均无隶属、
赞助或背书关系。

> **警告**
>
> 本项目按 **“现状（AS IS）”** 提供，不附带任何形式的担保。安装或使用第三方
> recovery 可能造成数据丢失、设备无法启动、失去对加密数据的访问、安全问题或
> 其他非预期后果。是否构建、刷入、修改或使用本项目，以及是否做好备份，完全由你
> 自行决定并自行负责。维护者与贡献者对因使用本项目造成的损坏、数据丢失、功能
> 丧失或其他后果不承担任何责任。

作者/维护者：自恋也是种美，@DeepSeek V4.1 Flash 1017

Copyright (C) 2026 自恋也是种美 (krollv)

## 概览

| 项目 | 值 |
| --- | --- |
| 目标设备 | 联想拯救者 Y700 五代 — **仅 TB323FU**（代号 Baldur） |
| SoC / 平台 | 高通 SM8850P（kaanapali / canoe） |
| AERA 版本 | R1.0（Beta），非官方移植（`ro.aera.release.channel=Beta`、`ro.aera.status=Unofficial`） |
| AERA 源码基线 | `AERA-Recovery/android_manifest`，分支 `aera-16.0`（基于 AOSP 16） |
| AERA CLI | 1.1.0 |
| 产品 / lunch 目标 | `twrp_TB323FU-bp2a-eng` |
| 内核页大小 | 4 KiB |
| 分区布局 | A/B + 独立、非分槽的 `recovery` 分区；virtual A/B |
| recovery 分区大小 | 104,857,600 字节（100 MiB） |
| 验证时刷入槽位 | 仅 `recovery_a`；`recovery_b`（OrangeFox R12.0）未触碰 |
| 显示 | 原生 1904 × 3040 面板扫描输出；AERA UI 使用 1440 × 3040 逻辑画布、按 1:1 合成，左右各约 232 px 边带（更早的 R1.0 镜像使用 1440 × 3168 letterbox 画布、左右约 261 px 边带） |

## 已验证基线

| 构建 | 产物 | SHA-256 | 大小 | 状态 |
| --- | --- | --- | --- | --- |
| AERA R1.0 首个验证构建（2026-11-06） | `AERA-R1.0-Beta-Unofficial-TB323FU.img` | `a94f39468cb096fe9a62e855fe198e9d2fb3ce32d18bc50118d38328cf2a7413` | 104,857,600 B | 已真机验证：UI/触摸、`/data` FBE 解密、`/data/media/0`、`/metadata`、ADB、MTP、fastbootd |
| AERA R1.0 修复构建（2026-11-06） | `AERA-R1.0-Beta-Unofficial-TB323FU.img` | `c17430e8f0c7ee88ed4c37ea20bb6376b3ba6552dc20b08835e83e74d91279f0` | 104,857,600 B | 经过七轮修复后真机验证：UI letterbox、SOCCP 电量、中文界面、备份、到 fastbootd 的 transition |
| AERA R1.0 hotfix5（2026-11-07）—— 最新用户确认版本 | `AERA-R1.0-Beta-Unofficial-TB323FU-20261107-recovery.img` | `a27e95b068f5e236ee4c1dbb1196c2d48e2ba0f3e4219c37f63d3647aa21adb6` | 104,857,600 B | 用户确认可用：`/sdcard` 明文（FBE CE 存储已解锁）、白色主题、原生 1904 × 3040 渲染、音频播放通路、Wi-Fi 网络测试；**已知启动偶发 tagged-pointer 崩溃** |
| AERA R1.0 hotfix5 安装 zip（2026-11-07） | `AERA-R1.0-Beta-Unofficial-TB323FU-20261107-recovery.zip` | `d60c8595ae14a171a844499e3c28fbe2f51a13068aef0ef2b1a6e53c19935d24` | 77,429,288 B | 已产出；**ZIP 安装**未做真机验证 |
| 回退锚点：OrangeFox R12.0（fox_16.0）2026-11-03 | `OrangeFox-R12.0-fox16.0-TB323FU-20261103-recovery.img` | `41528bb44e7978cb974a8af6e15a4bfe7134958eb90ea69a6837f479d0f171d8` | 104,857,600 B | AERA 移植前 `recovery_a` 中的内容；移植后位于 `recovery_b` |
| 回退锚点：原厂 recovery | 原厂 `recovery_a` 镜像 | `6b2676dc839ecff3ceb0fbd2b28c59512eaae5c251d3d8a096a151846042bc80` | 104,857,600 B | 设备原厂 recovery |

AERA 构建/运行、所需 blob 与解密工作的详细说明见
[`docs/AERA-NOTES.md`](docs/AERA-NOTES.md)。继承来的基线参考文档
（`docs/KNOWN_GOOD.md`、`docs/BUILDING.md`、`docs/PROPRIETARY_FILES.md`、
`docs/DECRYPTION_TROUBLESHOOTING.md`）是为已验证的 TWRP/OrangeFox 基线所写，
作为 AERA 移植的源码/运行参考仍然有效。

## 功能

本项目已在真机上验证（最新用户确认构建：2026-11-07 hotfix5）：

- 从独立 `recovery` 分区启动 recovery；
- AERA UI 竖屏显示：原生 1904 × 3040 扫描输出 + 1440 × 3040 逻辑画布
  （1:1 合成，左右约 232 px 边带）；
- 触摸输入；
- Android 17 `/data` FBE 解密与 `/sdcard` 明文访问；
  `User 0 Decrypted Successfully`；`/data/media/0` 可读；
- `/metadata` 挂载；
- ADB 与 MTP；
- fastbootd（`is-userspace: yes`），用于刷入 `recovery_a`；
- AERA CLI 1.1.0（`aera status`、`aera storages`、备份、重启动作）；
- 中文界面、24 小时制、`CST-8` 时区；
- 通过 SOCCP attach 读取电量状态（R1.0 修复版验证报告为 68 % / Charging）；
- EFISP 可见（3 MB）并可用于备份；
- `boot` / `persist` 分区备份；
- `aera transition fastboot` 走 bootloader message（BCB）路径；
- FBE 存储解锁修复后恢复白色（浅色）主题；
- 插件商店下载通路（`curl` + 内置 CA + 镜像 fallback）；
- 通过原厂 AudioReach PAL 栈的音频播放通路（可选，见下）；
- 音频之后的 Wi-Fi 网络测试/链路恢复（可选，见下）。

可选增强（源码集成已在树内；构建时需要原厂专有 blob）：

- **音频** —— AERA 音频桥/服务/PAL player 源码、bootstrap 与 bring-up 钩子在
  树内。项目的设备构建中验证过真实播放通路（PAL stream type 1、双 AW882xx
  智能功放 start、fast-exit 处理、默认音量 60 %）。要基于本树干净重建，需本地
  暂存原厂 A17 音频运行时与模块（干净重建的端到端验证待验证）。
- **Wi-Fi** —— WCN786x（`peach v2`）模块加载器、Wi-Fi init 钩子与原厂导出的
  配置 overlay 在树内。项目的构建通过了 Wi-Fi 网络测试；干净重建需要配套原厂
  固件中的驱动模块闭包与固件（干净重建的端到端验证待验证）。

这两个可选功能都需要**不在**本仓库中的原厂专有 blob；所需路径见
[`docs/AERA-NOTES.md`](docs/AERA-NOTES.md)。

## Android 17 TEE 件替换与解密修正

项目设备运行原厂 Android 17，而 AERA 树基于 AOSP 16 recovery 基线构建。修正后
的 TEE 通信链使用配套 Android 17 原厂字节替换以下 8 个 recovery ramdisk 文件：

- `system/bin/qseecomd`
- `system/lib64/libQSEEComAPI.so`
- `system/lib64/hw/libqtigatekeeper.so`
- `system/lib64/libdrmfs.so`
- `system/lib64/libminkdescriptor.so`
- `system/lib64/libdmabufheap.so`
- `system/lib64/libion.so`
- `system/lib64/libqcbor.so`

同一修正在 [`docs/AERA-NOTES.md`](docs/AERA-NOTES.md) 中给出了逐文件大小与复现
说明。这 8 个文件是联想/高通专有字节，**不在本仓库分发**；构建者须从自己有权
使用的配套原厂固件中暂存。另有 11 个 Android 17 替代的 crypto 文件记录在
`proprietary-overrides.tsv`（`status=substituted`）。

此外，2026-11-07 的项目构建包含 **FBE 存储解锁修复**（解密后 `/sdcard` 为
明文）。该修复位于 recovery 源码树，而不在本设备树；范围与注意事项见
[`docs/AERA-NOTES.md`](docs/AERA-NOTES.md)。

## 专有文件

本仓库的组织方式保证联想/高通专有二进制**不提交进 Git**。

- `proprietary-files.tsv` —— 每个外部 payload 文件的目标路径与 SHA-256
  （共 103 个目标）。
- `proprietary-sources.tsv` —— 获取映射：25 个来自配套 TB323FU 原厂固件，
  78 个来自公开的 polygraphene TB322FC donor 树。
- `proprietary-overrides.tsv` —— 已文档化的 Android 17 替代项。
- `scripts/acquire-proprietary-files.sh` —— 暂存本地提供的缓存，并拒绝哈希与
  清单不符的文件。

可选的音频/Wi-Fi 原厂 blob（模块、PAL/AGM 运行时、DSP 服务、固件）是仅在启用
这些功能时才需要的外部材料；见 [`docs/AERA-NOTES.md`](docs/AERA-NOTES.md)。

## 构建

构建目标是 **TB323FU**；文中出现的 TB322FC 仅指上游 donor 基线。

### 依赖

| 依赖 | 用途 | 说明 |
| --- | --- | --- |
| Linux 构建主机 | AERA/AOSP 源码构建 | 基于 Ubuntu、具备常规 AOSP 构建环境的发行版 |
| `repo`、`git`、`python3`、`sha256sum`、`rsync`、`cp`、`cmp`、`stat` | 源码同步 + payload 获取/校验 | 项目脚本会检查 |
| AERA 源码检出 | 构建树 | `AERA-Recovery/android_manifest`，分支 `aera-16.0` |
| AOSP 16 manifest 项目 | 构建树 | 由 `repo sync` 按 AERA manifest 解析 |
| 103 个专有 payload 文件 | 构建 payload | 另行获取；绝不提交 |
| 六个 shell 工具预编译件 | `curl`、`fastfetch`、`git`、`wget`、`zsh`、`zstd` | 由 `prebuilt-tools.tsv` 锁定；许可原文见 `LICENSES/third-party-tools/` |
| JDK 17 或 21 | Android 构建 | 两者均可用；开发时默认 JDK 21 |
| 磁盘空间 | 源码 + 输出 | 需按大型 AOSP 检出与输出树预留（数十 GB）；具体取决于 manifest 剪枝 |
| `ccache` | 可选构建加速 | 非必需 |

### 源码同步与构建

```bash
# 1) 同步 AERA 源码树（项目使用默认剪枝 manifest）
repo init -u https://github.com/AERA-Recovery/android_manifest.git -b aera-16.0
repo sync -c --force-sync --no-clone-bundle --no-tags -j$(nproc)

# 2) 把本设备树放入源码检出（先去掉 .git）
#    device/lenovo/TB323FU/

# 3) 准备专有 payload
scripts/acquire-proprietary-files.sh --stock-root /path/to/TB323FU-stock-root

# 4) 清理产品输出目录（必须：复用输出目录时 ramdisk 打包会因残留符号链接失败）
rm -rf out/target/product/TB323FU

# 5) 配置并构建
source build/envsetup.sh
lunch twrp_TB323FU-bp2a-eng
mka adbd recoveryimage
```

产品配置由 `aera_TB323FU.mk` 与 `vendorsetup.sh` 中的 AERA 环境设置提供；其中
包括 `AERA_USE_UPDATED_MAGISKBOOT=0`（默认预编译 `magiskboot` 为 4 KiB ELF
对齐，匹配本机 4 KiB 页内核；`_updated` 变体为 16 KiB 对齐，不可使用），且
`ro.aera.live_fastbootd` 保持 false。

产物为 `out/target/product/TB323FU/recovery.img`，必须能装入 100 MiB 的
recovery 分区。2026-11-07 hotfix5 构建的 `ramdisk-recovery.img` 为 89,470,975
字节（2026-11-06 的 R1.0 修复构建为 70,709,037 字节），因此实际余量取决于启用了哪些可选功能。
务必实测产物大小并保持在 104,857,600 字节以内。

说明：

- 项目的 recovery 源码修复（UI 补丁、FBE 解锁补丁、logcat 修复等）不属于 AERA
  manifest；重新 `repo sync` 后需要重新打上。本仓库只文档化了其中一部分（见
  [`docs/AERA-NOTES.md`](docs/AERA-NOTES.md)）。
- 继承的 `scripts/` 封装面向 TWRP/OrangeFox 基线树，不是 AERA manifest；
  请使用上面的 AERA 命令序列。

### 刷入

本机只有 fastbootd 能写 recovery 分区（bootloader fastboot 对该分区返回
`unknown command`）：

```bash
adb reboot fastboot
fastboot flash recovery_a AERA-R1.0-Beta-Unofficial-TB323FU-20261107-recovery.img
fastboot reboot
# 进入系统后
adb reboot recovery
```

若写入报 `AdbWriteEndpointSync failed ... (121)`，对 USB/ADB PnP 设备做复位后
重试。绝不要同时覆盖两个 recovery 槽位；保留原厂槽位与已校验的回退镜像。

## 仓库结构

| 路径 | 内容 |
| --- | --- |
| `aera_TB323FU.mk`、`vendorsetup.sh` | AERA R1.0 的 TB323FU 产品配置与构建环境 |
| `audio/` | AERA 音频桥/服务/PAL player/PA 探测源码（`aera-audio-bridge`、`aera-audio-service`、`aera-palplayer`、`aera-aw-hal`） |
| `apply-audio-t10.sh`、`apply-audio-t11.sh`、`apply-audio-t12.sh` | 应用到本树的音频集成步骤（幂等，支持 `--dry-run` / `--revert`） |
| `recovery/root/init.recovery.audio.rc`、`init.recovery.wifi.rc`、`system/bin/aera-*` | 可选音频/Wi-Fi bring-up 钩子与脚本；专有运行时模块被排除 |
| `recovery/root/vendor/etc/wifi/peach_v2/`、`wifi/` | 原厂导出的 Wi-Fi 配置 overlay（`WCNSS_qcom_cfg.ini`、`wpa_supplicant*.conf`、vendor command XML） |
| `recovery/root/`（其它） | 继承的基线 recovery 配置（init rc、fstab flags、VINTF manifest、crypto 修复钩子） |
| `BoardConfig.mk`、`device.mk`、`AndroidProducts.mk`、`twrp_TB323FU.mk`、`Android.bp`、`system.prop`、`recovery.fstab` | 设备配置（基线 + AERA 集成） |
| `patches/` | 从基线继承的 Android 16 兼容补丁 |
| `scripts/` | 基线构建/获取/校验脚本（TWRP/OrangeFox 流程） |
| `proprietary-*.tsv`、`prebuilt-tools.tsv` | 哈希锁定清单（不含二进制内容） |
| `docs/` | 基线参考文档，以及 AERA 专用说明、归属与合规文档 |
| `LICENSES/` | Apache-2.0 原文与第三方工具声明 |

## 已知问题与限制

- **启动偶发 tagged-pointer 崩溃**：2026-11-07 构建偶发在启动阶段崩溃
  （`Pointer tag ... truncated`）并自恢复重启。用户确认的状态是启动正常
  （`crash_counter=0`）的那次。完整修复待验证。
- **可选音频 / Wi-Fi 无法仅凭本仓库干净复现**：源码集成在树内，但所需原厂专有
  blob 不在；这些功能是在项目自己的构建中验证的，未在干净公开重建后重新验证
  （待验证）。
- 8 个 Android 17 TEE 通信链字节为专有材料且不分发；其跨原厂固件版本的逐文件
  来源为待验证。
- FBE 存储解锁修复（2026-11-07）位于 recovery 源码树，不在本设备树；复现它需要
  重新打上那些源码补丁。
- AERA UI 内容为 1440 宽逻辑画布，按 1:1 合成到 1904 × 3040 面板；满宽
  1904 × 3040 的版式重排计划在 R2（本树未包含）。
- 旋转 native 画布未做安全处理，可能造成显示花屏。
- 由于 recovery 内 Adreno EGL 路径不可用，GPU 渲染回退到 CPU 软件 scanout。
- `ro.aera.live_fastbootd` 刻意关闭（原地 live recovery ↔ fastbootd 切换是已知
  崩溃路径）；transition 走 BCB 重启路径。
- SELinux 在 recovery 树中为 permissive；`/data/recovery/AERA` 无
  `file_contexts`（enforcing 待验证）。
- 无 tombstone 支持：ramdisk 不包含 `crash_dump64`。
- `aera backup --parts misc` 不可用（recovery 卷列表未暴露 `misc`）；
  `boot` / `persist` 备份可用。
- 本基线在崩溃重启后会跳过 MTP（继承的 `crash_counter` 门控）；不包含 PC
  auto-enable 保护。
- restore、wipe、ZIP 安装 UI、OTA 路径均未做真机验证；安装 zip 内
  `INSTALL.txt` 为 AERA 上游模板。
- 解密仅验证了默认密码路径；自定义锁屏密码未测试（待验证）。
- Root Manager UI 已启用（`ro.aera.root_manager.enabled=1`），但未在已 Magisk
  root 的设备上做任何 KernelSU/SukiSU patch。
- 若 `.repo` 元数据被裁剪，AERA 横幅会显示装饰性的 `[Branch]: broken repo`
  字段，无功能影响。
- 部分继承的基线文档（`docs/INDEX.md`、`docs/PUBLICATION_STATUS.md`、
  `docs/THIRD_PARTY_TOOLS.md` 等）是为 TWRP 基线所写；请结合
  [`docs/AERA-NOTES.md`](docs/AERA-NOTES.md) 阅读。
- 2026-11-07 之后的项目构建属内部实验，未获用户确认为发布基线；此处刻意不列出。

## 安全规则

- 目标设备：**仅联想 TB323FU**。
- 测试前保留一份完全一致的原厂 recovery 备份。
- 保留一条已知可用的 recovery 路径。
- 首次测试新镜像时，只刷入目标 recovery 槽位。
- 不要随意同时覆盖两个 recovery 槽位。
- 刷入前校验镜像哈希。
- 验证之前不要执行 EFISP/ABL 等破坏性操作。

## 相关项目与文档

- 主项目仓库（TB323FU 的 LineageOS 24 / Android 17 系统设备树）：
  <https://github.com/UGY1412/android_device_lenovo_TB323FU>
  —— 其 `docs/` 目录下提供构建、刷写、硬件支持、根因与排障的中英文文档。
- 同设备的兄弟 TWRP/OrangeFox recovery 设备树：
  <https://github.com/UGY1412/android_device_lenovo_TB323FU-orangefox>
- AERA 上游项目：<https://github.com/AERA-Recovery/android_manifest>
- AERA 构建/运行、blob 与解密说明：
  [`docs/AERA-NOTES.md`](docs/AERA-NOTES.md)
- 基线已知可用参考：[`docs/KNOWN_GOOD.md`](docs/KNOWN_GOOD.md)
- 来源：[`TREE_PROVENANCE.md`](TREE_PROVENANCE.md)
- 归属与合规：[`docs/ATTRIBUTION.md`](docs/ATTRIBUTION.md)、
  [`docs/COMPLIANCE.md`](docs/COMPLIANCE.md)
- 许可：[`LICENSE`](LICENSE)、[`docs/LICENSING.md`](docs/LICENSING.md)、
  [`NOTICE`](NOTICE)、[`LICENSES/`](LICENSES/)

---

Copyright (C) 2026 自恋也是种美 (krollv)。本项目原创内容按 [`NOTICE`](NOTICE)、
[`LICENSE`](LICENSE) 与 [`docs/LICENSING.md`](docs/LICENSING.md) 所述条款提供；
第三方组件保留其各自许可。
