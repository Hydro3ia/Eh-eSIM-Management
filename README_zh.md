# eSIM Management (Magisk / KernelSU Module)

[English](README.md) | **简体中文**

为**无内置 eUICC**、使用**可插拔 eSIM 物理卡**（如 5ber、eSIM.me、eSTK 等）的 Android 12+ 设备提供原生系统级 eSIM 管理支持的 Magisk / KernelSU 模块集合。

模块通过声明 `android.hardware.telephony.euicc` 系统特性、将 OpenEUICC 作为 `/system_ext/priv-app` 特权 LPA（Local Profile Assistant）注入并配置权限白名单，让系统「设置 → SIM 卡」原生接管可插拔 eSIM 卡的切卡、下载与管理。

---

## 模块版本矩阵与选型指南

推荐优先使用 `universal` 四版本矩阵，按设备的**卡槽模式（SS / DS）**与 **LPA 类型（Stock / Mod）**二选一组合：

| | **SS**（不动 `multisim.config`） | **DS**（强制 `persist.radio.multisim.config=dsds`） |
|---|---|---|
| **Stock LPA**（原版 OpenEUICC） | `universal_ss_stock` (`id: euicc_ss_stock`) | `universal_ds_stock` (`id: euicc_ds_stock`) |
| **Mod LPA**（补丁版 OpenEUICC） | `universal_ss_mod` (`id: euicc_ss_mod`) | `universal_ds_mod` (`id: euicc_ds_mod`) |

### 选型规则

- **Stock vs Mod**：
  - **Stock（原版）**：仅向系统报告一张可插拔 eUICC，且在「无内置 eUICC」模式下会忽略 modem 原生上报为 eUICC 的槽位。适用于 **单张 eSIM 卡** 且 **modem 不原生上报 EID** 的设备。
  - **Mod（补丁版）**：推荐用于以下任一场景：
    1. **双卡槽同时插两张可插拔 eSIM 卡**；
    2. **modem 原生在 `IccCardStatus` 中上报可插拔 eUICC 的 EID**（如小米 HyperOS 等 ROM，使用 Stock 版会导致 eSIM 被误识别为普通物理 SIM 卡）。
- **SS vs DS**：
  - **SS**：不修改 `persist.radio.multisim.config`，适合单卡设备或 ROM 本身已正确启用双卡（DSDS）的设备。
  - **DS**：在 `post-fs-data.sh` 中强制设置 `persist.radio.multisim.config=dsds`，适合需要强制开启双卡双待的场景。

> 仓库中另保留了历史兼容目录 `universal`（等同旧版 `universal_ss_stock`）、`custom`（对应 `universal_ds_mod`）与 `mars`（对应 `universal_ss_mod`）。新安装建议直接选用上方四版本矩阵。

---

## Mod 版 OpenEUICC 补丁说明

相较上游原版 OpenEUICC，Mod 版包含以下两项关键改动：

1. **`shouldIgnoreSlot(slotId)` 恒返回 `false`**：
   - 允许系统同时识别全部可插拔 eUICC 槽位，避免在双 eSIM 卡或 modem 原生上报 EID 的 ROM 上返回 `FIRST_USER` 导致订阅无法标记 `isEmbedded=1`。
2. **实现 `EuiccService#onGetAvailableMemoryInBytes(int)`**：
   - 从 `EuiccInfo2.freeNvram` 读取 eUICC 可用非易失性内存字节数并返回，修复 `*#*#4636#*#*` 手机信息（Radio Info）中提示 `The connected LPA does not implement EuiccService#onGetAvailableMemoryInBytes(int)` 的问题。

---

## 安装要求与步骤

### 前置要求

1. **Android 12+**，且使用可插拔 eUICC 实体卡（5ber / eSIM.me / eSTK 等）。
2. **Magisk** 或 **KernelSU / KernelSU-Next**（需支持挂载 `/system` 与 `/system_ext`）。
3. **CorePatch / 禁用签名验证**（特权 LPA 非 ROM 平台签名，需放行系统签名校验）。

> [!WARNING]
> **请勿在自带内置 eUICC（硬件 eSIM）的设备上使用本模块。** 内置 eUICC 设备建议直接使用上游原版 OpenEUICC 模块。

### 安装方式

1. 前往本仓库的 **[Releases](../../releases)** 页面，根据上方选型规则下载对应的模块 `.zip` 压缩包。
2. 在 Magisk 或 KernelSU 管理器中刷入下载的 `.zip` 包并重启设备。
3. 重启后约 10–15 秒待 LPA 初始化完成，进入系统 **设置 → 网络和互联网 / 移动网络 → SIM 卡** 即可管理 eSIM Profile。

---

## 仓库目录结构

本仓库仅托管纯文本模块骨架与文档；编译/签名后的 `OpenEUICC.apk` 与可刷入模块 `.zip` 统一通过 **GitHub Releases** 分发。

```text
eSIM_Management/
├── modules/
│   ├── universal_ss_stock/   # 通用单卡 + 原版 LPA 骨架
│   ├── universal_ss_mod/     # 通用单卡 + 补丁 LPA 骨架
│   ├── universal_ds_stock/   # 通用双卡 + 原版 LPA 骨架
│   ├── universal_ds_mod/     # 通用双卡 + 补丁 LPA 骨架
│   ├── universal/            # 历史通用版（兼容保留）
│   ├── custom/               # 历史设备专用版（兼容保留）
│   └── mars/                 # 历史 HyperOS 专用版（兼容保留）
├── README.md                 # 英文说明
└── README_zh.md              # 中文说明（本文件）
```

每个模块目录包含以下核心文件：
- `module.prop`：模块元信息
- `post-fs-data.sh`：设置 eSIM 系统 UI 属性（DS 版额外设置 `persist.radio.multisim.config=dsds`）
- `system/etc/permissions/android.hardware.telephony.euicc.xml`：声明 `android.hardware.telephony.euicc` 系统特性
- `system/system_ext/etc/permissions/privapp_whitelist_im.angry.openeuicc.xml`：OpenEUICC 特权权限白名单
- `META-INF/com/google/android/update-binary` & `updater-script`：模块刷入脚本
- *(打包发布时放入)* `system/system_ext/priv-app/OpenEUICC/OpenEUICC.apk`：OpenEUICC 特权 LPA

---

## 已验证环境

已在以下设备与系统环境完成实机验证：
- **Sony Xperia XZ Premium (G8142 / maple)** — PixelOS (Android 16, SDK 36)，KernelSU-Next + Hybrid Mount（magic 模式，内核 4.4）+ CorePatch
- **Sony Xperia XZ2 Premium** — Android 16，验证 Mod 版 `onGetAvailableMemoryInBytes` 正常返回 eUICC 可用内存
- **Xiaomi Redmi K40 Pro (M2102K1AC / mars)** — HyperOS 2.0 (Android 16, SDK 36)，KernelSU-Next + Hybrid Mount（overlay/ext4 模式）+ CorePatch

---

## 常见问题与排障备忘

### 1. 刷入后设置里完全没有 eSIM 入口（`Euicc Feature is disabled`）
- 检查模块中 feature XML 路径是否为 `system/etc/permissions/android.hardware.telephony.euicc.xml`（**不要**放进 `system/system/etc/permissions/`）。Hybrid Mount 会将模块的 `system/` 1:1 映射到 `/system/`，多一层 `system/` 会导致 Android 无法识别该 feature。
- 可通过 `pm list features | grep euicc` 确认 `android.hardware.telephony.euicc` 是否已成功注册。

### 2. 设置有 eSIM 入口，但插入的 eSIM 卡仍被识别为普通物理卡（`isEmbedded=0`）
- 常见于 HyperOS 等 modem 会在 `IccCardStatus` 中原生上报可插拔 eUICC EID 的 ROM。
- 原因：Stock 版 OpenEUICC 会忽略 modem 上报为 eUICC 的槽位，导致 `onGetEuiccProfileInfoList` 返回 `FIRST_USER`。
- 解决：更换为 **Mod 版**模块（`universal_ss_mod` 或 `universal_ds_mod`）并重启。

### 3. 旧内核设备（如内核 4.4 无 overlayfs）挂载失败
- 使用 KernelSU + Hybrid Mount 时请切换为 **magic 模式**，overlay 模式在无 overlayfs 支持的内核上会挂载失败甚至触发重启/panic。

### 4. 已知限制
- **「关于手机」双 EID 同时显示**：重签系统 `Settings.apk` 会导致 SELinux `seinfo` 从 `platform` 变为 `default` 引发崩溃；纯 RRO 无法填充第二行运行时数据。目前系统「关于手机」默认仅显示单行 EID，不影响双卡 eSIM 正常切换与使用。
- **MEP（Multiple Enabled Profiles，单卡多待）**：依赖硬件与 Radio HAL `IRadio 2.1+` 支持；仅支持 `android.hardware.radio@1.0/1.1` 的旧设备无法开启 MEP。

---

## 卸载 / 还原

在 Magisk 或 KernelSU 管理器中禁用或卸载对应模块（或删除 `/data/adb/modules/<module_id>`），然后重启设备即可完全还原。

---

## 致谢与免责声明

- 致谢 [OpenEUICC](https://gitea.angry.im/PeterCxy/OpenEUICC) 及原版 OpenEUICC Magisk 模块维护者。
- 本项目仅供技术研究与个人学习使用。修改系统分区与 Root 模块存在变砖或数据丢失风险，使用前请做好备份，风险自负。
