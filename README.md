# eSIM Management (Magisk / KernelSU Module)

**English** | [简体中文](README_zh.md)

A collection of Magisk / KernelSU modules that enable native Android system-level eSIM management on Android 12+ devices **without a built-in eUICC**, using removable physical eUICC adapters (such as 5ber, eSIM.me, eSTK, etc.).

These modules declare the `android.hardware.telephony.euicc` system feature, inject OpenEUICC as a privileged LPA (Local Profile Assistant) under `/system_ext/priv-app` along with its privileged permission whitelist, and configure eSIM UI properties so Android Settings can natively download, switch, and manage eSIM profiles.

---

## Module Matrix & Selection Guide

Use the 4-variant `universal` matrix based on your device's **SIM configuration (SS / DS)** and **LPA variant (Stock / Mod)**:

| | **SS** (keeps `multisim.config` untouched) | **DS** (forces `persist.radio.multisim.config=dsds`) |
|---|---|---|
| **Stock LPA** (Upstream OpenEUICC) | `universal_ss_stock` (`id: euicc_ss_stock`) | `universal_ds_stock` (`id: euicc_ds_stock`) |
| **Mod LPA** (Patched OpenEUICC) | `universal_ss_mod` (`id: euicc_ss_mod`) | `universal_ds_mod` (`id: euicc_ds_mod`) |

### Which Variant Should I Choose?

- **Stock vs. Mod**:
  - **Stock**: Reports only a single removable eUICC and ignores slots natively reported as eUICC by the modem when no built-in eUICC is present. Suitable for a **single removable eSIM adapter** on ROMs whose modem does **not** natively report the EID.
  - **Mod**: Recommended (or required) if either of the following applies:
    1. You use **two removable eSIM adapters simultaneously** (dual eSIM);
    2. Your device's modem **natively reports the removable eUICC EID in `IccCardStatus`** (e.g., Xiaomi HyperOS), where the Stock LPA ignores the slot and causes Android Settings to treat the eSIM as a regular physical SIM.
- **SS vs. DS**:
  - **SS**: Does not touch `persist.radio.multisim.config`. Use this on single-SIM devices or dual-SIM ROMs that already run in DSDS mode natively.
  - **DS**: Forces `persist.radio.multisim.config=dsds` in `post-fs-data.sh`. Use this when you need to force dual-SIM (DSDS) mode.

> Legacy compatibility directories `universal` (predecessor of `universal_ss_stock`), `custom` (equivalent to `universal_ds_mod`), and `mars` (equivalent to `universal_ss_mod`) are retained for reference. For new installations, choose from the 4-variant matrix above.

---

## Mod OpenEUICC Patches

Compared to upstream OpenEUICC, the **Mod** build includes two targeted patches:

1. **`shouldIgnoreSlot(slotId)` always returns `false`**:
   - Reports all removable eUICC slots to Android telephony, preventing `onGetEuiccProfileInfoList` from returning `FIRST_USER` on dual-eSIM setups or ROMs whose modem natively reports removable eUICCs.
2. **Implements `EuiccService#onGetAvailableMemoryInBytes(int)`**:
   - Reads available non-volatile memory from `EuiccInfo2.freeNvram`, fixing the `*#*#4636#*#*` Radio Info message: `The connected LPA does not implement EuiccService#onGetAvailableMemoryInBytes(int)`.

---

## Requirements & Installation

### Requirements

1. **Android 12+** with a removable eUICC card (5ber, eSIM.me, eSTK, etc.).
2. **Magisk** or **KernelSU / KernelSU-Next** with `/system` and `/system_ext` mount support.
3. **CorePatch** (or disabled signature verification), since the privileged LPA is not signed with the ROM's platform key.

> [!WARNING]
> **Do NOT install these modules on devices that already have a built-in hardware eUICC.** Use the upstream OpenEUICC module directly on devices with built-in eSIM hardware.

### Installation

1. Download the appropriate module `.zip` from the **[Releases](../../releases)** page.
2. Flash the `.zip` in Magisk or KernelSU Manager and reboot.
3. Wait ~10–15 seconds after boot for the LPA to initialize, then open **Settings → Network & internet / Mobile network → SIMs** to manage your eSIM profiles.

---

## Repository Structure

This repository tracks only the plain-text module skeletons and documentation. Prebuilt/signed `OpenEUICC.apk` binaries and flashable module `.zip` packages are distributed via **GitHub Releases**.

```text
eSIM_Management/
├── modules/
│   ├── universal_ss_stock/   # Universal SS + Stock LPA skeleton
│   ├── universal_ss_mod/     # Universal SS + Mod LPA skeleton
│   ├── universal_ds_stock/   # Universal DS + Stock LPA skeleton
│   ├── universal_ds_mod/     # Universal DS + Mod LPA skeleton
│   ├── universal/            # Legacy universal variant
│   ├── custom/               # Legacy device-specific variant
│   └── mars/                 # Legacy HyperOS variant
├── README.md                 # English documentation (this file)
└── README_zh.md              # Simplified Chinese documentation
```

Each module directory contains:
- `module.prop`: Module metadata
- `post-fs-data.sh`: Sets eSIM system UI properties (DS variants also set `persist.radio.multisim.config=dsds`)
- `system/etc/permissions/android.hardware.telephony.euicc.xml`: Declares the `android.hardware.telephony.euicc` feature
- `system/system_ext/etc/permissions/privapp_whitelist_im.angry.openeuicc.xml`: Privileged permission whitelist for OpenEUICC
- `META-INF/com/google/android/update-binary` & `updater-script`: Module installer scripts
- *(Packaged into release zips)* `system/system_ext/priv-app/OpenEUICC/OpenEUICC.apk`: OpenEUICC privileged LPA

---

## Tested Environments

Verified on the following device and ROM combinations:
- **Sony Xperia XZ Premium (G8142 / maple)** — PixelOS (Android 16, SDK 36), KernelSU-Next + Hybrid Mount (magic mode, kernel 4.4) + CorePatch
- **Sony Xperia XZ2 Premium** — Android 16 (verified Mod `onGetAvailableMemoryInBytes` readout in Radio Info)
- **Xiaomi Redmi K40 Pro (M2102K1AC / mars)** — HyperOS 2.0 (Android 16, SDK 36), KernelSU-Next + Hybrid Mount (overlay/ext4 mode) + CorePatch

---

## Troubleshooting & Technical Notes

### 1. No eSIM option in Settings (`Euicc Feature is disabled`)
- Ensure the feature XML path inside the module is `system/etc/permissions/android.hardware.telephony.euicc.xml` (and **not** `system/system/etc/permissions/`). Hybrid Mount maps `system/` 1:1 to `/system/`, so a nested `system/system/` path is ignored by Android.
- Run `pm list features | grep euicc` to verify that `android.hardware.telephony.euicc` is registered.

### 2. eSIM entry appears, but the eSIM card is treated as a physical SIM (`isEmbedded=0`)
- Common on ROMs like Xiaomi HyperOS where the modem natively reports the removable eUICC's EID in `IccCardStatus`.
- Cause: Stock OpenEUICC ignores slots reported as eUICC by the modem when no built-in eUICC exists, returning `FIRST_USER`.
- Fix: Switch to a **Mod** variant (`universal_ss_mod` or `universal_ds_mod`) and reboot.

### 3. Mount failures on older kernels (e.g., Linux 4.4 without overlayfs)
- When using KernelSU + Hybrid Mount on kernels lacking `overlayfs`, use **magic mode**. Attempting overlay mode can fail to mount or cause a kernel panic.

### 4. Known Limitations
- **Displaying two EIDs simultaneously in About Phone**: Re-signing the system `Settings.apk` changes its SELinux `seinfo` from `platform` to `default`, causing `selinux_android_setcontext` crashes; a pure RRO cannot populate runtime EID values for a second row. About Phone shows a single EID by default, though dual eSIM management works normally.
- **MEP (Multiple Enabled Profiles)**: Requires hardware and Radio HAL `IRadio 2.1+` support; older devices on `android.hardware.radio@1.0/1.1` do not support MEP.

---

## Uninstall / Rollback

Disable or remove the module in Magisk or KernelSU Manager (or delete `/data/adb/modules/<module_id>`) and reboot.

---

## Credits & Disclaimer

- Thanks to [OpenEUICC](https://gitea.angry.im/PeterCxy/OpenEUICC) and the upstream OpenEUICC Magisk module maintainers.
- This project is provided for educational and research purposes only. Modifying system partitions and using root modules carries inherent risks; always back up your data before proceeding.
