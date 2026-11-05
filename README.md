# OnePlus 7T (HD1901) Hardware & Calibration Backup Kit

[![Device](https://img.shields.io/badge/Device-OnePlus%207T%20(HD1901)-blue.svg)](#)
[![SoC](https://img.shields.io/badge/SoC-Snapdragon%20855%2B%20(SM8150--AC)-orange.svg)](#)
[![Security](https://img.shields.io/badge/Integrity-SHA--256%20Bit--Verified-brightgreen.svg)](#)
[![Compression](https://img.shields.io/badge/Compression-Zero%20(Lossless%20Byte%20Slices)-purple.svg)](#)

A complete hardware backup, calibration archive, and disaster-recovery suite for the **OnePlus 7T (`HD1901` / `hotdogb`)**.

This repository permanently preserves all firmware, baseband, modem, TrustZone, bootloaders, sensor calibration, and **technician-repaired IMEI / NVRAM** data dumped directly from physical UFS flash storage (`/dev/block/bootdevice/by-name/*`).

---

## 📑 Table of Contents
1. [Prerequisites & USB Setup](#1-prerequisites--usb-setup)
2. [How to Boot into Recovery or Fastboot](#2-how-to-boot-into-recovery-or-fastboot)
3. [Scenario A: 1-Click SIM & Repaired IMEI Restore (Most Common)](#3-scenario-a-1-click-sim--repaired-imei-restore-most-common)
4. [Scenario B: Complete Full Firmware Rollback (All 84 Partitions)](#4-scenario-b-complete-full-firmware-rollback-all-84-partitions)
5. [Scenario C: Manual Command-by-Command CLI Restore](#5-scenario-c-manual-command-by-command-cli-restore)
6. [Zero-Compression Architecture & Reassembly](#6-zero-compression-architecture--reassembly)
7. [Partition Reference Guide](#7-partition-reference-guide)
8. [Troubleshooting & FAQs](#8-troubleshooting--faqs)

---

## 1. Prerequisites & USB Setup

### On Windows:
1. **Android Platform Tools**: Ensure `adb` and `fastboot` are installed and available in your system `PATH` (or copy `adb.exe`, `fastboot.exe`, and their `.dll` files directly into this directory).
2. **OnePlus USB Drivers**: Install the official OnePlus USB drivers or Google USB drivers so the device is recognized in Device Manager under *Android Device* without any yellow warning icons.

### On Linux:
1. Install `android-tools`:
   - Arch Linux: `sudo pacman -S android-tools`
   - Ubuntu / Debian: `sudo apt install android-tools-adb android-tools-fastboot`
   - Fedora: `sudo dnf install android-tools`
2. Ensure your user has permissions for USB devices (or run scripts with standard `adb` permissions).

---

## 2. How to Boot into Recovery or Fastboot

Before running any restoration script, put your OnePlus 7T into **OrangeFox Recovery** (recommended) or **Fastboot Mode**:

### Method 1: Via ADB (If phone is currently booted into Android)
- **To Boot into Recovery:**
  ```bash
  adb reboot recovery
  ```
- **To Boot into Fastboot / Bootloader:**
  ```bash
  adb reboot bootloader
  ```

### Method 2: Hardware Key Combinations (If phone is powered off or bootlooping)
- **To enter Recovery Mode (OrangeFox):**
  1. Power off the phone completely.
  2. Press and hold **Power + Volume Down** simultaneously.
  3. Release both buttons when the OnePlus logo appears.
  4. OrangeFox Recovery will load.
  > **Note on OrangeFox Screen:** If OrangeFox prompts you for a password/pattern to decrypt, tap **Cancel**. If it prompts to allow system modifications, tap **Keep Read Only**.
- **To enter Fastboot / Bootloader Mode:**
  1. Power off the phone completely.
  2. Press and hold **Power + Volume Up + Volume Down** (all three buttons together).
  3. Release when the Fastboot screen (black screen with "FASTBOOT MODE") appears.

---

## 3. Scenario A: 1-Click SIM & Repaired IMEI Restore (Most Common)

### When to use this:
- After using the **MSM Download Tool (EDL mode)** to unbrick your phone.
- After flashing a custom ROM or port (such as **HyperOS 2**) that wipes your technician-repaired IMEI.
- Whenever your phone shows **"No Service"**, **"Invalid SIM"**, or **"IMEI: Unknown / 0"**.

### Step-by-Step on Windows:
1. Boot your phone into **OrangeFox Recovery** (or Fastboot mode).
2. Plug the USB cable connecting your phone to your PC.
3. Open this repository folder on your PC.
4. **Double-click `restore-sim.bat`**.
5. The script automatically:
   - Verifies the cryptographic SHA-256 hash of all 16 calibration files.
   - Detects the phone via ADB or Fastboot.
   - Restores: `modemst1`, `modemst2`, `fsg`, `fsc`, `oem_stanvbk`, `oem_dycnvbk`, `mdm_oem_stanvbk`, `mdm_oem_dycnvbk`, `mdm1m9kefs1/2/3`, `persist`, `carrier`, and `param`.
   - Automatically reboots the phone into Android.
6. Once Android starts, insert your SIM card. Your repaired IMEI, cellular signal, and 4G/LTE mobile data will immediately be functional!

### Step-by-Step on Linux:
1. Boot phone into **OrangeFox Recovery** (or Fastboot mode) and connect USB.
2. Open a terminal in this repository folder.
3. Run:
   ```bash
   ./restore-sim.sh
   ```
4. The script flashes the calibration partitions and reboots your phone into Android in ~5 seconds.

> **💡 Zero Extraction Required:** All 16 SIM and IMEI calibration partitions are stored as **whole, unsplit `.img` files**. `restore-sim` works immediately out-of-the-box without needing to run any reassembly tools!

---

## 4. Scenario B: Complete Full Firmware Rollback (All 84 Partitions)

### When to use this:
- If your phone is soft-bricked, stuck in a bootloop, or corrupted.
- If you want to restore the phone completely back to the exact backed-up state (clean firmware, kernel, bootloaders, recovery, modem, DSP, splash screen).

### Step-by-Step on Windows:
1. **Step 1 — Reassemble Large Images:**
   - Double-click **`reassemble-partitions.bat`**.
   - This takes the raw 90MB byte slices (`opproduct_a`, `opproduct_b`, `modem_a`, `modem_b`, `boot_a`, `boot_b`, `recovery_a`, `recovery_b`, `op1`, `op2`) and losslessly reassembles them back into full `.img` files using native Windows binary copy.
2. **Step 2 — Connect Phone:**
   - Boot your phone into **OrangeFox Recovery** (or Bootloader mode) and plug in USB.
3. **Step 3 — Run Rollback:**
   - Double-click **`import-backup.bat`**.
   - Select option **`[3] Complete Full Rollback`**.
   - Type **`RESTORE`** and press Enter.
   - The script flashes all 84 partitions and reboots the phone.

### Step-by-Step on Linux:
1. **Step 1 — Reassemble Large Images:**
   ```bash
   ./reassemble-partitions.sh
   ```
   *(This reassembles any sliced images and verifies all 84 partitions against `SHA256SUMS`).*
2. **Step 2 — Connect Phone:**
   - Boot phone into OrangeFox Recovery (or Bootloader) and connect USB.
3. **Step 3 — Run Rollback Tool:**
   ```bash
   ./import-backup.sh
   ```
4. Choose option **`[3]`**, type **`RESTORE`**, and let the script flash all partitions.
5. The phone reboots cleanly into the restored system.

---

## 5. Scenario C: Manual Command-by-Command CLI Restore

If you prefer to restore specific partitions manually from a command prompt, use the following commands:

### A. Restoring IMEI & Baseband via Fastboot (Bootloader Mode):
```bash
fastboot flash modemst1 partitions/modemst1.img
fastboot flash modemst2 partitions/modemst2.img
fastboot flash fsg partitions/fsg.img
fastboot flash fsc partitions/fsc.img
fastboot flash oem_stanvbk partitions/oem_stanvbk.img
fastboot flash oem_dycnvbk partitions/oem_dycnvbk.img
fastboot flash persist partitions/persist.img
fastboot flash param partitions/param.img
fastboot flash carrier partitions/carrier.img
fastboot reboot
```

### B. Restoring Kernel & Recovery via Fastboot:
```bash
# First reassemble slices: cat partitions/boot_a.img.part* > partitions/boot_a.img
fastboot flash boot_a partitions/boot_a.img
fastboot flash boot_b partitions/boot_b.img
fastboot flash dtbo_a partitions/dtbo_a.img
fastboot flash dtbo_b partitions/dtbo_b.img
fastboot flash vbmeta_a partitions/vbmeta_a.img
fastboot flash vbmeta_b partitions/vbmeta_b.img
fastboot flash recovery_a partitions/recovery_a.img
fastboot flash recovery_b partitions/recovery_b.img
fastboot reboot
```

### C. Restoring via OrangeFox Recovery (ADB Shell):
In OrangeFox Recovery, partitions are written via physical block devices:
```bash
adb push partitions/modemst1.img /dev/part_tmp.img
adb shell "dd if=/dev/part_tmp.img of=/dev/block/bootdevice/by-name/modemst1 bs=4096"
adb shell "rm -f /dev/part_tmp.img"
```

---

## 6. Zero-Compression Architecture & Reassembly

- **Why No Compression?**  
  Binary firmware and NVRAM partitions are extremely sensitive. Compression formats (zip/rar/7z) can suffer archive bit rot or extraction errors. By using zero compression, every byte is guaranteed 100% bit-identical to the phone's hardware UFS storage.
- **GitHub 100 MB Limit Compliance:**  
  GitHub rejects files larger than 100 MB. To store full 1.7 GB partitions like `opproduct` without compression, they were divided using raw byte slice splitting (`split -b 90M`).
- **Bit-for-Bit Reassembly:**  
  Concatenating the parts (`cat file.img.part* > file.img` or Windows `copy /b file.img.part* file.img`) reconstructs the exact original file matching `partitions/SHA256SUMS`.

---

## 7. Partition Reference Guide

| Partition Group | Partition Names | Function & Content |
|---|---|---|
| **IMEI & Cellular NVRAM** | `modemst1`, `modemst2`, `fsg`, `fsc` | Holds Qualcomm non-volatile memory, radio calibration, and **your active repaired IMEI**. |
| **OnePlus NVRAM Locks** | `oem_stanvbk`, `oem_dycnvbk`, `mdm_oem_*` | Static & dynamic NVRAM locks that prevent the bootloader from wiping custom IMEIs. |
| **Hardware Persist** | `persist` | Camera sensor calibration, fingerprint sensor calibration, Bluetooth & Wi-Fi MAC addresses. |
| **Board Parameters** | `param`, `carrier`, `devinfo`, `config` | OnePlus board IDs (`hotdogt` 19863), bootloader flags, and carrier network profiles. |
| **Cellular Radio & DSP** | `modem_a/b`, `dsp_a/b`, `bluetooth_a/b` | Qualcomm X24 LTE modem firmware, Hexagon 690 DSP code, and Bluetooth radio binaries. |
| **Bootloaders & TrustZone** | `xbl_a/b`, `abl_a/b`, `tz_a/b`, `hyp_a/b`, `aop_a/b` | Qualcomm primary bootloaders (XBL), Android Bootloader (ABL), TrustZone security monitor, and hypervisor. |
| **Crypto & Keystore** | `keymaster_a/b`, `cmnlib_a/b`, `qupfw_a/b`, `uefisecapp_a/b` | Hardware keystore applets, secure storage engines, and Qualcomm firmware applets. |
| **Kernel & Verified Boot** | `boot_a/b`, `dtbo_a/b`, `vbmeta_a/b`, `recovery_a/b` | Linux kernel image, device tree overlays, AVB 2.0 metadata, and recovery environment. |

---

## 8. Troubleshooting & FAQs

### Q1: `adb devices` or `fastboot devices` shows nothing when phone is plugged in.
- **Solution:** 
  1. Try a different USB cable or a USB 2.0 port instead of USB 3.0/3.1 (Qualcomm bootloaders sometimes fail enumeration on USB 3.0/USB-C ports).
  2. On Windows, open **Device Manager**. If you see *Android* with a yellow triangle, right-click -> *Update driver* -> *Browse my computer* -> *Let me pick from a list* -> Select *Android Device* -> Choose *Android ADB Interface* or *Android Bootloader Interface*.

### Q2: OrangeFox Recovery prompts for a decryption pattern / password.
- **Solution:** Tap **Cancel** on the pattern/PIN screen. The backup scripts do not touch the encrypted `/data/userdata` partition; they only write to raw low-level firmware partitions which do not require decryption.

### Q3: How do I verify that my backup files on disk are 100% genuine and not corrupted?
- **On Linux:** Run `cd partitions && sha256sum -c SHA256SUMS`. All 84 partitions will report `OK`.
- **Live On-Device Check:** Boot into OrangeFox, connect USB, and run `./verify-backup-integrity.py`. It compares the hash of every backup file directly against the physical flash blocks inside the phone over ADB.
