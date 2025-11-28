#!/usr/bin/env bash
set -euo pipefail

# Safe helper to flash a raw image to a disk on macOS using dd.
# Prompts for explicit disk identifier and a typed confirmation to avoid mistakes.
# Usage: ./scripts/safe_dd_flash.sh --image /path/to/image.img

IMAGE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --image) IMAGE="$2"; shift 2;;
    --help|-h) echo "Usage: $0 --image /path/to/image.img"; exit 0;;
    *) echo "Unknown arg: $1" >&2; exit 1;;
  esac
done

if [ -z "$IMAGE" ]; then
  echo "No image specified. Try: $0 --image /path/to/SYSTEM" >&2
  exit 2
fi

if [ ! -f "$IMAGE" ]; then
  echo "Error: image file not found: $IMAGE" >&2
  exit 3
fi

echo "Image: $IMAGE"
IMG_BYTES=$(stat -f%z "$IMAGE")
printf "Image size: %s bytes (%.1f MB)\n" "$IMG_BYTES" "$(awk "BEGIN{printf %.1f, $IMG_BYTES/1024/1024}")"

echo
echo "Available disks (external & all):"
diskutil list
echo

# Ask user for disk identifier
read -r -p "Paste the whole device path to WRITE (example /dev/disk2) or type 'exit' to cancel: " USB_DEVICE
if [ "$USB_DEVICE" = "exit" ]; then
  echo "Cancelled."; exit 0
fi

# Basic validation
if ! [[ "$USB_DEVICE" =~ ^/dev/disk[0-9]+$ ]]; then
  echo "Invalid device format. Expect /dev/diskN" >&2
  exit 4
fi

# Show device info and size
echo
echo "Device info for $USB_DEVICE:" 
diskutil info "$USB_DEVICE" || { echo "Failed to query $USB_DEVICE" >&2; exit 5; }

# Get device block size in bytes and total size
DEV_SIZE_BYTES=$(diskutil info "$USB_DEVICE" | awk -F: '/Disk Size/ {print $2}' | sed -E 's/^[[:space:]]*([0-9,.]+).*/\1/' | tr -d ',' ) || true
# Fallback: use diskutil info raw size if available
if [ -z "$DEV_SIZE_BYTES" ]; then
  DEV_SIZE_BYTES=0
fi

echo
echo "WARNING: This will ERASE ALL DATA on $USB_DEVICE"
echo "Image file: $IMAGE ($(du -h "$IMAGE" | awk '{print $1}'))"
echo "You must type the DEVICE identifier to confirm (exactly): $USB_DEVICE"
read -r -p "Type the device identifier to proceed: " CONFIRM
if [ "$CONFIRM" != "$USB_DEVICE" ]; then
  echo "Confirmation mismatch — aborting." >&2
  exit 6
fi

read -r -p "Type YES (uppercase) to start flashing: " FINAL
if [ "$FINAL" != "YES" ]; then
  echo "You did not type YES — aborting." >&2
  exit 7
fi

echo "Unmounting $USB_DEVICE..."
diskutil unmountDisk "$USB_DEVICE"

RAW_DEVICE="/dev/r${USB_DEVICE#/dev/}"
echo "Flashing $IMAGE -> $RAW_DEVICE (this may take several minutes)"
sudo dd if="$IMAGE" of="$RAW_DEVICE" bs=4m status=progress conv=sync

echo "Flushing caches..."
sync

echo "Ejecting $USB_DEVICE..."
diskutil eject "$USB_DEVICE" || true

echo "Done. Power-cycle the device and wait a few minutes for first boot."

exit 0
