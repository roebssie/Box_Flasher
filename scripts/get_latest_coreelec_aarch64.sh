#!/usr/bin/env bash
set -euo pipefail

# Download the latest CoreELEC Amlogic aarch64 release asset and save it to the specified directory.
# Tries to parse https://releases.coreelec.org/releases.json using jq first, then python3.
# Usage: ./scripts/get_latest_coreelec_aarch64.sh [output-dir]

OUTDIR="${1:-.}"
mkdir -p "$OUTDIR"

RELEASES_JSON_URL="https://releases.coreelec.org/releases.json"
TMPJSON="$(mktemp -t coreelec_releases.XXXX.json)"
trap 'rm -f "$TMPJSON"' EXIT

echo "Fetching releases index..."
if ! curl -fsSL "$RELEASES_JSON_URL" -o "$TMPJSON"; then
    echo "Error: failed to download $RELEASES_JSON_URL" >&2
    exit 2
fi

extract_latest_with_jq() {
    command -v jq >/dev/null 2>&1 || return 1
    jq -r '..|.file?.name? // empty' "$TMPJSON" \
        | grep -Ei 'Amlogic.*aarch64' \
        | sort -V \
        | tail -n1
}

extract_latest_with_python() {
    command -v python3 >/dev/null 2>&1 || return 1
    python3 - <<'PY'
#!/usr/bin/env bash
set -euo pipefail

# Download the latest CoreELEC Amlogic aarch64 release asset and save it to the specified directory.
# Tries to parse https://releases.coreelec.org/releases.json using jq first, then python3.
# Usage: ./scripts/get_latest_coreelec_aarch64.sh [output-dir]

OUTDIR="${1:-.}"
mkdir -p "$OUTDIR"

RELEASES_JSON_URL="https://releases.coreelec.org/releases.json"
TMPJSON="$(mktemp -t coreelec_releases.XXXX.json)"
trap 'rm -f "$TMPJSON"' EXIT

echo "Fetching releases index..."
if ! curl -fsSL "$RELEASES_JSON_URL" -o "$TMPJSON"; then
    echo "Error: failed to download $RELEASES_JSON_URL" >&2
    exit 2
fi

extract_latest_with_jq() {
    command -v jq >/dev/null 2>&1 || return 1
    jq -r '..|.file?.name? // empty' "$TMPJSON" \
        | grep -Ei 'Amlogic.*aarch64' \
        | sort -V \
        | tail -n1
}

extract_latest_with_python() {
    command -v python3 >/dev/null 2>&1 || return 1
    python3 - "$TMPJSON" <<'PY'
import json,sys,re
tmp=sys.argv[1]
data=json.load(open(tmp))
matches=[]
def walk(o):
    if isinstance(o,dict):
        if 'file' in o and isinstance(o['file'],dict) and 'name' in o['file']:
            name=o['file']['name']
            if re.search(r'Amlogic.*aarch64', name, re.I):
                matches.append(name)
        for v in o.values():
            walk(v)
    elif isinstance(o,list):
        for v in o:
            walk(v)

walk(data)
if not matches:
    sys.exit(1)
matches.sort()
print(matches[-1])
PY
}

echo "Locating latest Amlogic aarch64 asset..."
LATEST_NAME=""
if LATEST_NAME=$(extract_latest_with_jq 2>/dev/null || true); then
    :
fi
if [ -z "$LATEST_NAME" ]; then
    LATEST_NAME=$(extract_latest_with_python 2>/dev/null || true)
fi

if [ -z "$LATEST_NAME" ]; then
    echo "Error: couldn't locate an Amlogic aarch64 asset in releases.json using jq or python3." >&2
    echo "You can inspect the releases index manually: $RELEASES_JSON_URL" >&2
    exit 3
fi

echo "Selected asset: $LATEST_NAME"

# Construct GitHub releases download URL. releases.json uses GitHub release tags as the leading path segment.
TAG="${LATEST_NAME%%/*}"
ASSET="${LATEST_NAME#*/}"
DOWNLOAD_URL="https://github.com/CoreELEC/CoreELEC/releases/download/${TAG}/${ASSET}"

echo "Download URL: $DOWNLOAD_URL"

OUTPATH="$OUTDIR/$ASSET"
if [ -f "$OUTPATH" ]; then
    echo "File $OUTPATH already exists — skipping download." 
    exit 0
fi

echo "Downloading $ASSET to $OUTDIR..."
if command -v wget >/dev/null 2>&1; then
    wget -c "$DOWNLOAD_URL" -O "$OUTPATH"
else
    curl -L --fail -o "$OUTPATH" "$DOWNLOAD_URL"
fi

echo "Download complete: $OUTPATH"
echo "IMPORTANT: verify the checksum shown on the release page for tag '$TAG' before flashing."
echo "Example: shasum -a 256 $OUTPATH  # compare with release checksum"

exit 0
data=json.load(open(sys.argv[1]))
