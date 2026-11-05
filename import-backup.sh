#!/usr/bin/env bash
set -euo pipefail

# import-backup.sh
# Emergency Rollback & Restore tool for OnePlus 7T (HD1901 / hotdogb)
# Restores backed-up partitions back to the physical device.

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
    echo "[ERROR] Backup directory or SHA256SUMS not found in $BACKUP_DIR"
    echo "If you cloned this repo, run ./unpack-backup.sh first!"
    exit 1
fi

cd "$BACKUP_DIR"

echo "=========================================================="
echo "    OnePlus 7T: Partition Restore & Emergency Rollback    "
echo "    Source: $BACKUP_DIR"
echo "=========================================================="
echo ""
echo "Select what you want to restore:"
echo "  [1] SIM, IMEI & Baseband Calibration ONLY (modemst1/2, fsg, fsc, persist, nvram)"
echo "  [2] Boot, Kernel & Verified Boot ONLY (boot, dtbo, vbmeta)"
echo "  [3] Complete Full Rollback (All firmware, bootloaders, and calibration)"
echo "  [4] Cancel / Exit"
echo ""
read -rp "Enter choice [1-4]: " CHOICE

PARTS_TO_RESTORE=()

case "$CHOICE" in
    1)
        PARTS_TO_RESTORE=(
            "modemst1" "modemst2" "fsg" "fsc"
            "oem_stanvbk" "oem_dycnvbk"
            "mdm_oem_stanvbk" "mdm_oem_dycnvbk"
            "mdm1m9kefs1" "mdm1m9kefs2" "mdm1m9kefs3" "mdm1m9kefsc" "mdm1oemnvbktmp"
            "persist" "param" "carrier" "config" "devinfo" "secdata" "limits"
        )
        ;;
    2)
        PARTS_TO_RESTORE=(
            "boot_a" "boot_b"
            "dtbo_a" "dtbo_b"
            "vbmeta_a" "vbmeta_b"
            "vbmeta_system_a" "vbmeta_system_b"
            "recovery_a" "recovery_b"
            "opproduct_a" "opproduct_b"
        )
        ;;
    3)
        for img in *.img; do
            pname="${img%.img}"
            if [ "$pname" != "userdata" ] && [ "$pname" != "super" ]; then
                PARTS_TO_RESTORE+=("$pname")
            fi
        done
        ;;
    4)
        echo "Aborted by user."
        exit 0
        ;;
    *)
        echo "Invalid selection."
        exit 1
        ;;
esac

echo ""
echo "=========================================================="
echo "ATTENTION: You are about to restore the following partitions:"
printf ' %s\n' "${PARTS_TO_RESTORE[@]}"
echo "=========================================================="
echo "Type 'RESTORE' to confirm and proceed:"
read -rp "> " CONFIRM

if [ "$CONFIRM" != "RESTORE" ]; then
    echo "Confirmation mismatch. Aborted."
    exit 1
fi

# Detect device mode
DEV_BY_NAME="/dev/block/bootdevice/by-name"
if "$REAL_ADB" devices | grep -q "recovery"; then
    MODE="RECOVERY"
    echo "Detected device in RECOVERY mode via ADB."
    if ! "$REAL_ADB" shell "ls /dev/block/bootdevice/by-name" >/dev/null 2>&1; then
        if "$REAL_ADB" shell "ls /dev/block/by-name" >/dev/null 2>&1; then
            DEV_BY_NAME="/dev/block/by-name"
        fi
    fi
elif "$REAL_FASTBOOT" devices | grep -q "fastboot"; then
    MODE="FASTBOOT"
    echo "Detected device in FASTBOOT mode."
else
    echo "[ERROR] No device detected in Recovery (adb) or Fastboot mode."
    echo "Please connect the phone in recovery or bootloader."
    exit 1
fi

echo ""
echo "Verifying checksums before writing..."
for part in "${PARTS_TO_RESTORE[@]}"; do
    if [ ! -f "$part.img" ]; then
        echo "[ERROR] Missing backup file: $part.img"
        exit 1
    fi
    grep "$part.img" SHA256SUMS | sha256sum -c --status || {
        echo "[ERROR] Checksum verification failed for $part.img!"
        exit 1
    }
done
echo "Checksum verification PASSED for all selected partitions."

echo ""
echo "Starting restoration via $MODE..."

for part in "${PARTS_TO_RESTORE[@]}"; do
    echo "Restoring $part from $part.img ..."
    if [ "$MODE" = "RECOVERY" ]; then
        # Direct raw block write via temporary RAM buffer in recovery
        "$REAL_ADB" push "$part.img" "/dev/part_tmp.img" >/dev/null 2>&1
        "$REAL_ADB" shell "dd if=/dev/part_tmp.img of=$DEV_BY_NAME/$part bs=4096 2>/dev/null"
        "$REAL_ADB" shell "rm -f /dev/part_tmp.img"
    elif [ "$MODE" = "FASTBOOT" ]; then
        "$REAL_FASTBOOT" flash "$part" "$part.img"
    fi
done

echo ""
echo "=========================================================="
echo "SUCCESS: Restoration completed!"
echo "You may now reboot your phone:"
if [ "$MODE" = "RECOVERY" ]; then
    echo "  $REAL_ADB reboot"
else
    echo "  $REAL_FASTBOOT reboot"
fi
echo "=========================================================="
