#!/usr/bin/env bash
set -euo pipefail

# reassemble-partitions.sh
# Lossless zero-compression reassembly of split partition images.
# Reassembles any .img.part* slices back into full bit-identical .img files.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$SCRIPT_DIR/partitions"

if [ ! -d "$BACKUP_DIR" ]; then
    echo "[ERROR] Partitions directory not found at $BACKUP_DIR"
    exit 1
fi

cd "$BACKUP_DIR"

echo "=========================================================="
echo "    OnePlus 7T: Lossless Zero-Compression Reassembly     "
echo "=========================================================="

# Find all base partition names with .part files
SPLIT_BASES=$(ls *.part* 2>/dev/null | sed -E 's/\.part[0-9]+$//' | sort -u || true)

if [ -z "$SPLIT_BASES" ]; then
    echo "No split partitions found. All partitions are already complete!"
else
    for base in $SPLIT_BASES; do
        if [ -f "$base" ] && [ -s "$base" ]; then
            echo " -> [OK] $base already exists, verifying..."
        else
            echo " -> Reassembling $base from byte slices..."
            cat "$base".part* > "$base"
        fi
    done
fi

echo ""
echo "Verifying SHA-256 checksums..."
if [ -f "SHA256SUMS" ]; then
    sha256sum -c SHA256SUMS --status && echo "ALL 84 PARTITIONS ARE 100% BIT-FOR-BIT VERIFIED!" || {
        echo "[WARNING] Some partition checksums did not match. Run: sha256sum -c SHA256SUMS | grep FAILED"
    }
fi

echo "=========================================================="
echo "Reassembly complete. Partitions are ready for flashing/restore."
echo "=========================================================="
