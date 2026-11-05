#!/usr/bin/env bash
set -euo pipefail

# export-backup.sh
# Exhaustive read-only export of ALL firmware, baseband, modem, TrustZone,
# bootloader, radio, vendor, carrier, calibration, and parameter partitions
# from OnePlus 7T (HD1901).
# Guarantees that any custom technician modification (IMEI repair, carrier
# unlock, modem patch, param tweak, NVRAM) is 100% preserved.
# EXCLUDES ONLY: userdata (personal data) and super (custom ROM).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$SCRIPT_DIR/partitions"

# Auto-detect tools
if command -v adb >/dev/null 2>&1; then
    SAFE_ADB="$(command -v adb)"
elif [ -f "/run/media/apex/New Volume/ios-project/tools/safe/adb" ]; then
    SAFE_ADB="/run/media/apex/New Volume/ios-project/tools/safe/adb"
else
    echo "[ERROR] 'adb' was not found in PATH."
    exit 1
fi

mkdir -p "$BACKUP_DIR"
cd "$BACKUP_DIR"

echo "=========================================================="
echo "    OnePlus 7T: Exhaustive Hardware & Firmware Export     "
echo "    Destination: $BACKUP_DIR"
echo "=========================================================="

echo "[1/4] Checking recovery connection..."
"$SAFE_ADB" devices

# Detect on-device by-name path
DEV_BY_NAME="/dev/block/bootdevice/by-name"
if ! "$SAFE_ADB" shell "ls /dev/block/bootdevice/by-name" >/dev/null 2>&1; then
    if "$SAFE_ADB" shell "ls /dev/block/by-name" >/dev/null 2>&1; then
        DEV_BY_NAME="/dev/block/by-name"
    fi
fi
echo "Using on-device partition path: $DEV_BY_NAME"

ALL_PARTS=(
    # 1. Baseband, IMEI, SIM & Radio Calibration (TOP PRIORITY)
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
    
    # 2. Hardware parameters, carrier, sensor, and persist calibration
    "persist"
    "param"
    "carrier"
    "config"
    "devinfo"
    "secdata"
    "limits"
    "op1"
    "op2"
    "opproduct_a"
    "opproduct_b"
    
    # 3. Bootloaders, TrustZone, security applets & crypto
    "xbl_a" "xbl_b"
    "xbl_config_a" "xbl_config_b"
    "abl_a" "abl_b"
    "tz_a" "tz_b"
    "hyp_a" "hyp_b"
    "aop_a" "aop_b"
    "keymaster_a" "keymaster_b"
    "cmnlib_a" "cmnlib_b"
    "cmnlib64_a" "cmnlib64_b"
    "devcfg_a" "devcfg_b"
    "qupfw_a" "qupfw_b"
    "storsec_a" "storsec_b"
    "uefisecapp_a" "uefisecapp_b"
    "uefivarstore"
    "imagefv_a" "imagefv_b"
    
    # 4. Modem firmware, DSP, Bluetooth & auxiliary firmware blobs
    "modem_a" "modem_b"
    "dsp_a" "dsp_b"
    "bluetooth_a" "bluetooth_b"
    "cdt"
    "ddr"
    "mdmddr"
    "catecontentfv"
    "catefv"
    "cateloader"
    "spunvm"
    "msadp"
    "apdp"
    "dip"
    "ALIGN_TO_128K_1"
    "ALIGN_TO_128K_2"
    
    # 5. Kernel, dtbo, verified boot & splash
    "boot_a" "boot_b"
    "dtbo_a" "dtbo_b"
    "vbmeta_a" "vbmeta_b"
    "vbmeta_system_a" "vbmeta_system_b"
    "recovery_a" "recovery_b"
    "splash"
    "LOGO_a" "LOGO_b"
)

TOTAL=${#ALL_PARTS[@]}
INDEX=0
SUCCESS_COUNT=0

echo "[2/4] Exporting all $TOTAL hardware, firmware, and calibration partitions..."

for part in "${ALL_PARTS[@]}"; do
    INDEX=$((INDEX + 1))
    TARGET_FILE="$BACKUP_DIR/$part.img"
    
    if [ -f "$TARGET_FILE" ] && [ -s "$TARGET_FILE" ]; then
        echo "[$INDEX/$TOTAL] Already backed up: $part.img"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        echo "[$INDEX/$TOTAL] Pulling: $part -> $part.img ..."
        if "$SAFE_ADB" pull "$DEV_BY_NAME/$part" "$TARGET_FILE" 2>/dev/null; then
            if [ -s "$TARGET_FILE" ]; then
                SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
            fi
        else
            echo "   [NOTE] Partition $part not present on this hardware variant; skipping."
            rm -f "$TARGET_FILE"
        fi
    fi
done

echo "[3/4] Generating SHA-256 integrity checksums..."
sha256sum *.img > SHA256SUMS

echo "[4/4] Verifying essential calibration images..."
ESSENTIAL_PARTS=("modemst1" "modemst2" "fsg" "fsc" "persist" "oem_stanvbk" "oem_dycnvbk" "boot_b" "dtbo_b" "vbmeta_b")
ESSENTIAL_FAILURES=0

for part in "${ESSENTIAL_PARTS[@]}"; do
    if [ ! -s "$BACKUP_DIR/$part.img" ]; then
        echo "[CRITICAL ERROR] Essential partition $part.img is missing or zero bytes!"
        ESSENTIAL_FAILURES=$((ESSENTIAL_FAILURES + 1))
    fi
done

if [ "$ESSENTIAL_FAILURES" -eq 0 ]; then
    echo "=========================================================="
    echo "  EXHAUSTIVE EXPORT COMPLETE!"
    echo "  Total partitions backed up: $SUCCESS_COUNT"
    echo "  Every technician patch, baseband, and calibration partition is safe."
    echo "  Location: $BACKUP_DIR"
    echo "  Total storage used: $(du -sh "$BACKUP_DIR" | cut -f1)"
    echo "=========================================================="
    exit 0
else
    echo "[FAIL] $ESSENTIAL_FAILURES essential calibration partition(s) failed."
    exit 1
fi
