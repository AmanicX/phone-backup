# OnePlus 7T (HD1901) Backup & Recovery Kit

**Location**: Stored on `/dev/sda4` (NTFS mount: `/run/media/apex/New Volume/ios-project/phone-backup-kit/`)  
**Repository**: `https://github.com/AmanicX/phone-backup.git`  
**SoC**: Qualcomm Snapdragon 855+ (SM8150-AC)  
**Target Device**: OnePlus 7T (`HD1901` / `hotdogb`)

---

## 1. What This Kit Preserves

This kit preserves all hardware, radio, baseband, bootloader, TrustZone, security applets, and sensor calibration partitions.
**Most crucially, it permanently preserves your custom/repaired IMEI and NVRAM configuration:**
- `modemst1` & `modemst2`: Qualcomm non-volatile memory storing your active IMEI and SIM calibration.
- `fsg` & `fsc`: Golden modem filesystem and security cookie.
- `oem_stanvbk` & `oem_dycnvbk`: OnePlus static and dynamic NVRAM backup partitions (which lock and protect the repaired IMEI).
- `mdm_oem_stanvbk`, `mdm_oem_dycnvbk`, `mdm1m9kefs1/2/3`: Auxiliary modem NVRAM calibration blocks.
- `persist`: Camera sensors, fingerprint calibration, and Wi-Fi/Bluetooth MAC addresses.
- `param`: OnePlus hardware board IDs, project IDs, and lock flags.
- `carrier`: Carrier-specific network definitions.

---

## 2. Zero-Compression Integrity Guarantee

- **NO COMPRESSION IS USED**: All partition files are 100% pure raw binary images dumped directly from physical flash (`/dev/block/bootdevice/by-name/*`).
- To comply with GitHub's 100 MB per-file limit without any lossy compression or archive corruption, large files (>90MB) are divided into clean, raw 90 MB byte slices (`.part00`, `.part01`, etc.).
- Joining them back produces the exact, bit-for-bit identical original image matching `partitions/SHA256SUMS`.

---

## 3. Instant 1-Click SIM & Repaired IMEI Restoration

If you ever use **EDL (MSM Download Tool)**, or flash a ROM/port (like HyperOS 2 or a custom ROM) that wipes your repaired IMEI and causes your SIM to lose signal:

### On Windows:
1. Boot your phone into **OrangeFox Recovery** (or Bootloader / Fastboot mode).
2. Connect your phone to your PC via USB.
3. Open `phone-backup-kit\` on your drive and double-click **`restore-sim.bat`**.
4. The script flashes all 16 calibration partitions back to your phone, verifies checksums, and reboots the phone into Android.
5. Your repaired IMEI, SIM detection, and cellular service are immediately restored!

### On Linux:
1. Boot phone into **OrangeFox Recovery** (or Bootloader).
2. Connect USB to laptop.
3. In a terminal, run:
   ```bash
   ./restore-sim.sh
   ```
4. The script automatically restores all IMEI and SIM partitions and reboots the phone.

*(Note: All 16 SIM and IMEI calibration partitions are whole, unsplit `.img` files, so `restore-sim` works immediately with no reassembly required!)*

---

## 4. Full System Firmware Rollback

If you ever want to restore the entire phone firmware (bootloaders, kernel, recovery, splash, radio):

### On Linux:
1. Reassemble split images (if not already reassembled):
   ```bash
   ./reassemble-partitions.sh
   ```
2. Connect phone in OrangeFox Recovery or Fastboot mode.
3. Run:
   ```bash
   ./import-backup.sh
   ```
4. Select `[3]` for Complete Full Rollback and type `RESTORE`.

### On Windows:
1. Double-click **`reassemble-partitions.bat`**.
2. Restore partitions using Fastboot or OrangeFox Recovery.

---

## 5. Verification Tools

- **`verify-backup-integrity.py`**: Runs live on-device SHA-256 checks comparing laptop backup files directly against the phone's physical flash storage block devices.
- **`partitions/SHA256SUMS`**: Cryptographic hash table for all 84 backed-up partitions.

---

## 6. Directory Structure

```
phone-backup-kit/
├── GUIDE.md                      # This manual
├── .gitignore                    # Git rules for GitHub safety
│
│── Instant SIM & IMEI Restore:
├── restore-sim.sh                # Linux 1-click restore
├── restore-sim.bat               # Windows 1-click restore
│
│── Reassembly (Zero Compression):
├── reassemble-partitions.sh      # Linux slice reassembler
├── reassemble-partitions.bat     # Windows slice reassembler
│
│── Rollback & Export:
├── import-backup.sh              # Linux full rollback tool
├── export-backup.sh              # Linux partition dumper
├── export-backup.bat             # Windows partition dumper
│
│── Verification:
├── verify-backup-integrity.py    # Bit-for-bit hardware verification
│
└── partitions/                   # 84 partition images, raw byte slices & SHA256SUMS
```
