#!/usr/bin/env bash
set -euo pipefail

# restore-sim.sh
# One-click SIM, IMEI & Baseband restoration tool for OnePlus 7T (HD1901)
# Use this after EDL unbricking or factory reset to instantly restore your
# repaired IMEI, baseband calibration, and network connectivity.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$SCRIPT_DIR/partitions"

# Auto-detect tools
if command -v adb >/dev/null 2>&1; then
    REAL_ADB="$(command -v adb)"
elif [ -f "/run/media/apex/New Volume/ios-project/tools/safe/adb" ]; then
    REAL_ADB="/run/media/apex/New Volume/ios-project/tools/safe/adb"
else
    echo "[ERROR] 'adb' was not found in PATH."
    exit 1
fi

if command -v fastboot >/dev/null 2>&1; then
    REAL_FASTBOOT="$(command -v fastboot)"
elif [ -f "/run/media/apex/New Volume/ios-project/tools/safe/fastboot" ]; then
    REAL_FASTBOOT="/run/media/apex/New Volume/ios-project/tools/safe/fastboot"
else
    REAL_FASTBOOT="fastboot"
fi

if [ ! -d "$BACKUP_DIR" ] || [ ! -f "$BACKUP_DIR/SHA256SUMS" ]; then
    echo "[ERROR] Backup directory or SHA256SUMS not found at $BACKUP_DIR"
    echo "If you cloned this repo, run ./unpack-backup.sh first!"
    exit 1
fi

cd "$BACKUP_DIR"

echo "=========================================================="
echo "    OnePlus 7T: Instant SIM & Repaired IMEI Restoration   "
echo "    Source: $BACKUP_DIR"
echo "=========================================================="

SIM_PARTS=(
    "modemst1"
    "modemst2"
    "fsg"
    "fsc"
    "oem_stanvbk"
    "oem_dycnvbk"
    "mdm_oem_stanvbk"
    "mdm_oem_dycnvbk"
    "mdm1m9kefs1"
    "mdm1m9kefs2"
    "mdm1m9kefs3"
    "mdm1m9kefsc"
    "mdm1oemnvbktmp"
    "persist"
    "param"
    "carrier"
)

# 1. Verify checksums of calibration files
echo "[1/3] Verifying SHA-256 integrity of SIM & IMEI calibration files..."
for part in "${SIM_PARTS[@]}"; do
    if [ ! -f "$part.img" ]; then
        echo "[ERROR] Missing calibration file: $part.img"
        exit 1
    fi
    grep "$part.img" SHA256SUMS | sha256sum -c --status || {
        echo "[ERROR] SHA-256 checksum verification failed for $part.img!"
        exit 1
    }
done
echo "All calibration files are intact and verified!"

# 2. Detect connection mode
echo "[2/3] Detecting phone connection..."
DEV_BY_NAME="/dev/block/bootdevice/by-name"
if "$REAL_ADB" devices | grep -q "recovery"; then
    MODE="RECOVERY"
    echo "Phone detected in OrangeFox / Recovery mode via ADB."
    if ! "$REAL_ADB" shell "ls /dev/block/bootdevice/by-name" >/dev/null 2>&1; then
        if "$REAL_ADB" shell "ls /dev/block/by-name" >/dev/null 2>&1; then
            DEV_BY_NAME="/dev/block/by-name"
        fi
    fi
elif "$REAL_FASTBOOT" devices | grep -q "fastboot"; then
    MODE="FASTBOOT"
    echo "Phone detected in Bootloader / Fastboot mode."
else
    echo "[ERROR] Phone not detected!"
    echo "Please boot into OrangeFox Recovery (or Bootloader) and connect USB."
    exit 1
fi

# 3. Flash / restore calibration partitions
echo "[3/3] Restoring IMEI and SIM calibration partitions..."
for part in "${SIM_PARTS[@]}"; do
    echo " -> Restoring $part ..."
    if [ "$MODE" = "RECOVERY" ]; then
        "$REAL_ADB" push "$part.img" "/dev/part_tmp.img" >/dev/null 2>&1
        "$REAL_ADB" shell "dd if=/dev/part_tmp.img of=$DEV_BY_NAME/$part bs=4096 2>/dev/null"
        "$REAL_ADB" shell "rm -f /dev/part_tmp.img"
    elif [ "$MODE" = "FASTBOOT" ]; then
        "$REAL_FASTBOOT" flash "$part" "$part.img"
    fi
done

echo ""
echo "=========================================================="
echo "SUCCESS: Your repaired IMEI and SIM setup are restored!"
echo "Rebooting phone..."
if [ "$MODE" = "RECOVERY" ]; then
    "$REAL_ADB" reboot
else
    "$REAL_FASTBOOT" reboot
fi
echo "The phone is rebooting into Android. Your SIM is ready."
echo "=========================================================="
