# OnePlus 7T (HD1901) Hardware & Calibration Backup Kit

[![Device](https://img.shields.io/badge/Device-OnePlus%207T%20(HD1901)-blue.svg)](#)
[![SoC](https://img.shields.io/badge/SoC-Snapdragon%20855%2B%20(SM8150--AC)-orange.svg)](#)
[![Security](https://img.shields.io/badge/Integrity-SHA--256%20Bit--Verified-brightgreen.svg)](#)
[![Compression](https://img.shields.io/badge/Compression-Zero%20(Lossless%20Byte%20Slices)-purple.svg)](#)

A complete hardware backup, calibration archive, and disaster-recovery suite for the **OnePlus 7T (`HD1901` / `hotdogb`)**.

This repository permanently preserves all firmware, baseband, modem, TrustZone, bootloaders, sensor calibration, and **technician-repaired IMEI / NVRAM** data dumped directly from physical UFS flash storage.

---

## ⚡ Emergency 1-Click SIM & Repaired IMEI Restore

If you ever use the **MSM Download Tool (EDL mode)** to unbrick, or flash a ROM/port (e.g. **HyperOS 2**, custom ROMs) that wipes your technician-repaired IMEI and leaves your SIM with **"No Service"**:

### On Windows:
1. Boot your phone into **OrangeFox Recovery** (or Bootloader / Fastboot).
2. Connect your phone to your PC via USB.
3. Open this folder and double-click **`restore-sim.bat`**.
4. The script flashes all 16 calibration partitions, verifies checksums, and reboots into Android.
5. Your repaired IMEI, SIM card detection, and cellular connectivity are immediately back online!

### On Linux:
1. Boot phone into **OrangeFox Recovery** (or Bootloader).
2. Connect USB to your PC.
3. Open a terminal here and run:
   ```bash
   ./restore-sim.sh
   ```
4. The script automatically restores all IMEI and SIM partitions and reboots the phone.

> **Note:** All 16 SIM and IMEI calibration partitions are stored as **whole, unsplit, uncompressed `.img` files**. `restore-sim` works immediately out-of-the-box with no extraction or reassembly needed!

---

## 📦 Zero-Compression Architecture

- **No Compression / No Corrupted Archives:** Every partition is a 100% pure raw binary image identical down to the bit to the phone's physical flash storage.
- **GitHub 100 MB Limit Compliance:** Large partitions (>90MB) are split into raw 90 MB byte slices (`.part00`, `.part01`, etc.) using zero compression.
- **1-Click Lossless Reassembly:**
  - **Windows:** Double-click **`reassemble-partitions.bat`**
  - **Linux:** Run **`./reassemble-partitions.sh`**

---

## 🔄 Full Firmware Rollback (All 84 Partitions)

To restore the complete phone firmware back to the backed-up state (bootloader, kernel, radio, splash, recovery):

### On Linux:
```bash
# 1. Reassemble large byte slices (if needed)
./reassemble-partitions.sh

# 2. Run the interactive rollback utility
./import-backup.sh
```
Choose `[3]` for Complete Full Rollback, type `RESTORE`, and let it flash.

### On Windows:
1. Double-click `reassemble-partitions.bat`.
2. Flash partitions back using `fastboot flash <partition> partitions\<partition>.img`.

---

## 🛡️ Critical Partitions Overview

| Partition | Size | Purpose & Criticality |
|---|---|---|
| `modemst1` & `modemst2` | 2 MB each | Primary & secondary Qualcomm NVRAM. **Contains your active repaired IMEI.** |
| `oem_stanvbk` & `oem_dycnvbk` | 10 MB each | OnePlus static & dynamic NVRAM locks protecting repaired IMEI. |
| `fsg` & `fsc` | 2 MB / 128 KB | Golden modem filesystem structure and security cookie. |
| `persist` | 32 MB | Hardware sensor calibration, fingerprint sensor, and Wi-Fi/Bluetooth MAC addresses. |
| `param` | 1 MB | Hardware board IDs, project IDs (`hotdogt` 19863), and bootloader lock flags. |
| `carrier` | 64 MB | Carrier definitions, VoLTE/VoWiFi configuration, and network policies. |
| `modem_a` & `modem_b` | 300 MB each | Qualcomm Snapdragon X24 LTE cellular radio binary firmware. |
| `dsp_a` & `dsp_b` | 64 MB each | Hexagon 690 DSP firmware for baseband signal processing and audio. |
| `xbl_a/b`, `abl_a/b`, `tz_a/b` | ~25 MB total | Core UEFI bootloaders and Qualcomm TrustZone. |
| `boot_a/b`, `dtbo_a/b`, `vbmeta_a/b` | ~250 MB total | Linux kernel, device tree overlays, and Android Verified Boot metadata. |

---

## 🔍 Integrity Verification

This backup was bit-for-bit verified directly against the phone's hardware flash blocks:
- **`verify-backup-integrity.py`**: Executes `sha256sum` directly on physical block devices (`/dev/block/bootdevice/by-name/*`) over ADB and compares hashes with local files.
- **`partitions/SHA256SUMS`**: Full cryptographic manifest of all 84 backed-up partitions.
