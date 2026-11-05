#!/usr/bin/env python3
import os
import sys
import subprocess
import hashlib

BACKUP_DIR = "/run/media/apex/New Volume/ios-project/phone-backup-kit/partitions"
SAFE_ADB = "/run/media/apex/New Volume/ios-project/tools/safe/adb"
if not os.path.isfile(SAFE_ADB):
    SAFE_ADB = "/usr/bin/adb"

print("==========================================================================")
print("     Bit-for-Bit On-Device vs Laptop SHA-256 Checksum Comparison          ")
print("==========================================================================")

# Priority list of critical partitions to check first
CHECK_PARTS = [
    # IMEI & Baseband
    "modemst1", "modemst2", "fsg", "fsc",
    "oem_stanvbk", "oem_dycnvbk",
    "mdm_oem_stanvbk", "mdm_oem_dycnvbk",
    "mdm1m9kefs1", "mdm1m9kefs2", "mdm1m9kefs3", "mdm1m9kefsc", "mdm1oemnvbktmp",
    # Hardware Persist & Param
    "persist", "param", "carrier", "devinfo", "config", "secdata", "limits",
    # Core bootloader
    "abl_b", "xbl_b", "tz_b", "hyp_b", "aop_b",
    # Kernel & Verified boot
    "boot_b", "dtbo_b", "vbmeta_b"
]

def hash_file_local(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        while chunk := f.read(1024 * 1024):
            h.update(chunk)
    return h.hexdigest()

def hash_device_part(part_name):
    # Try both standard by-name paths
    for base in ["/dev/block/bootdevice/by-name", "/dev/block/by-name"]:
        full_path = f"{base}/{part_name}"
        try:
            res = subprocess.run([SAFE_ADB, "shell", f"sha256sum {full_path}"],
                                 stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, timeout=30)
            if res.returncode == 0 and res.stdout.strip():
                # Format: "<hash>  <path>"
                tokens = res.stdout.strip().split()
                if len(tokens) >= 1 and len(tokens[0]) == 64:
                    return tokens[0]
        except Exception as e:
            pass
    return None

matches = 0
failures = 0
skipped = 0

print(f"{'PARTITION':<20} | {'STATUS':<10} | {'PHONE SHA-256':<32} | {'LAPTOP SHA-256':<32}")
print("-" * 105)

for part in CHECK_PARTS:
    img_path = os.path.join(BACKUP_DIR, f"{part}.img")
    if not os.path.isfile(img_path):
        print(f"{part:<20} | {'MISSING':<10} | File not found in {BACKUP_DIR}")
        skipped += 1
        continue
    
    local_hash = hash_file_local(img_path)
    remote_hash = hash_device_part(part)
    
    if remote_hash is None:
        print(f"{part:<20} | {'UNREADABLE':<10} | Could not read from device block")
        failures += 1
    elif local_hash == remote_hash:
        print(f"{part:<20} | {'MATCH [OK]':<10} | {remote_hash[:16]}...{remote_hash[-12:]} | {local_hash[:16]}...{local_hash[-12:]}")
        matches += 1
    else:
        print(f"{part:<20} | {'MISMATCH':<10} | {remote_hash[:16]}... | {local_hash[:16]}...")
        failures += 1

print("-" * 105)
print(f"Comparison Complete: {matches} exact bit-for-bit matches, {failures} mismatches, {skipped} skipped.")
if failures == 0 and matches > 0:
    print("[RESULT: 100% VERIFIED] Every single checked partition on /dev/sda4 is a bit-for-bit clone of the phone.")
    sys.exit(0)
else:
    sys.exit(1)
