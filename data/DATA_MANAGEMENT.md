# 📦 Data Management System

All project data is centrally located in the `/data` directory structure.

## Directory Structure

```
data/
├── images/              # CoreELEC and OS images
│   ├── README.md
│   └── CoreELEC-Amlogic.aarch64-latest.img [~500MB]
│
├── config/              # Configuration files
│   ├── device.config    # Device settings
│   ├── build.config     # Build parameters
│   ├── flashing.config  # Flashing parameters
│   └── service.config   # Service configuration
│
├── resources/           # Scripts and utilities
│   ├── monitor.service  # Systemd service file
│   ├── flashing-tools/  # External tool references
│   └── documentation/   # Resource files
│
├── cache/               # Temporary build/download cache
│   ├── downloaded/      # Downloaded images cache
│   └── build/           # Build artifacts cache
│
└── logs/                # Application logs
    ├── flashing.log     # Flashing operation logs
    ├── deployment.log   # Service deployment logs
    └── build.log        # Build process logs
```

## Usage

### Storing Images
```bash
# Download CoreELEC image to data/images/
cd data/images
wget https://releases.coreelec.org/CoreELEC-Amlogic.aarch64-latest.img.gz
gunzip CoreELEC-Amlogic.aarch64-latest.img.gz
```

### Configuration Files
All configuration is in `data/config/`:
- Device parameters
- Build flags
- Flashing settings
- Service startup options

### Logs
All operations log to `data/logs/`:
- Flashing operations
- Service deployments
- Build processes

### Cache
Downloaded files and build cache stored in `data/cache/`:
- Prevents re-downloading large images
- Speeds up repeated builds
- Automatic cleanup available

## .gitignore Configuration

Add to `.gitignore`:
```
data/images/*.img
data/images/*.img.gz
data/cache/**
data/logs/**
data/.env
```

(Images are large; configure Git LFS if needed for version control)

## Environment Variables

```bash
# Load from data/.env
export DATA_DIR="$(pwd)/data"
export IMAGES_DIR="$DATA_DIR/images"
export CONFIG_DIR="$DATA_DIR/config"
export RESOURCES_DIR="$DATA_DIR/resources"
export CACHE_DIR="$DATA_DIR/cache"
export LOGS_DIR="$DATA_DIR/logs"
```

## Quick Commands

```bash
# Initialize data directories
bash scripts/init_data.sh

# Clean cache and logs
bash scripts/clean_cache.sh

# Check data directory size
du -sh data/

# List all images
ls -lh data/images/
```
