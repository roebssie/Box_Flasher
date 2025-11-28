# 🖼️ OS Images Directory

Store all CoreELEC and LibreELEC images here for S905W flashing.

## Supported Images

### CoreELEC (Recommended)
- **File:** `CoreELEC-Amlogic.aarch64-latest.img` (~500 MB)
- **Download:** https://releases.coreelec.org/CoreELEC-Amlogic.aarch64-latest.img.gz
- **Decompress:** `gunzip CoreELEC-Amlogic.aarch64-latest.img.gz`
- **Arch:** aarch64 (ARMv8 64-bit)
- **Target:** Amlogic S905W

### LibreELEC (Alternative)
- **File:** `LibreELEC-Generic.aarch64-latest.img` (~600 MB)
- **Download:** https://libreelec.tv/download/
- **Arch:** aarch64
- **Target:** Generic ARM systems

## Usage

### Download Image
```bash
cd data/images

# CoreELEC
wget https://releases.coreelec.org/CoreELEC-Amlogic.aarch64-latest.img.gz
gunzip CoreELEC-Amlogic.aarch64-latest.img.gz

# Verify download
ls -lh CoreELEC-Amlogic.aarch64-latest.img
```

### Flash Image
```bash
# From project root
bash scripts/flash.sh data/images/CoreELEC-Amlogic.aarch64-latest.img

# Or manual
cd data/images
aml_usb_flashing_tool --image CoreELEC-Amlogic.aarch64-latest.img --device s905w
```

### Verify Image Integrity
```bash
# Check file size (should be ~500MB)
ls -lh CoreELEC-Amlogic.aarch64-latest.img

# Verify it's valid EXT4 filesystem
file CoreELEC-Amlogic.aarch64-latest.img
# Should output: "block special"

# Calculate MD5
md5sum CoreELEC-Amlogic.aarch64-latest.img
```

## Image Versions

| Version | Size | Release Date | Status |
|---------|------|--------------|--------|
| 20.5.2 | 512 MB | Latest | ✅ Recommended |
| 20.5.1 | 510 MB | Previous | ⚠️ Older |
| 20.4.x | 500 MB | Legacy | ❌ Deprecated |

## Cleanup

```bash
# Remove old/unused images
rm CoreELEC-Amlogic.aarch64-20.4.x.img

# Compress images for storage (saves ~50%)
gzip -k CoreELEC-Amlogic.aarch64-latest.img
```

## Notes

⚠️ **Large Files:** Images are ~500MB; ensure sufficient disk space
🔐 **Backup:** Keep one backup copy in external storage
📋 **Version Control:** Images excluded from git (see `.gitignore`)
🚀 **LFS:** Consider Git LFS if tracking image versions
