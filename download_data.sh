#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

# Usage:
#   bash download_cvpr2027_datasets.sh [DATA_ROOT]
# Example:
#   bash download_cvpr2027_datasets.sh "$HOME/datasets/cvpr2027_anomaly"
#
# Optional:
#   EXTRACT_REALIAD=1 bash download_cvpr2027_datasets.sh ...
#   HF_WORKERS=4 bash download_cvpr2027_datasets.sh ...
#   MVTEC_URL='new_download_url' bash download_cvpr2027_datasets.sh ...

DATA_ROOT="${1:-$HOME/datasets/cvpr2027_anomaly}"
ARCHIVE_DIR="$DATA_ROOT/_archives"
TOOL_ENV="$DATA_ROOT/.download_tools"
HF_WORKERS="${HF_WORKERS:-4}"
EXTRACT_REALIAD="${EXTRACT_REALIAD:-0}"

mkdir -p "$DATA_ROOT" "$ARCHIVE_DIR"

echo "============================================================"
echo "DATA_ROOT: $DATA_ROOT"
df -h "$DATA_ROOT" || true
echo "============================================================"

# ---------------------------
# 0. Download tools
# ---------------------------
PYTHON_BIN="${PYTHON_BIN:-python3}"
if ! command -v "$PYTHON_BIN" >/dev/null 2>&1; then
    PYTHON_BIN=python
fi

"$PYTHON_BIN" - <<'PY'
import sys
if sys.version_info < (3, 9):
    raise SystemExit(
        f"Python {sys.version.split()[0]} is too old. Python >= 3.9 is required."
    )
print("Python:", sys.version.split()[0])
PY

if [[ ! -x "$TOOL_ENV/bin/python" ]]; then
    "$PYTHON_BIN" -m venv "$TOOL_ENV"
fi

"$TOOL_ENV/bin/python" -m pip install -U pip >/dev/null
"$TOOL_ENV/bin/python" -m pip install -U huggingface_hub gdown >/dev/null

HF="$TOOL_ENV/bin/hf"
GDOWN="$TOOL_ENV/bin/gdown"

# ---------------------------
# 1. MVTec 3D-AD
# ---------------------------
MVTEC_DIR="$DATA_ROOT/MVTec3D_AD"
MVTEC_ARCHIVE="$ARCHIVE_DIR/mvtec_3d_anomaly_detection.tar.xz"
MVTEC_MD5="d8bb2800fbf3ac88e798da6ae10dc819"
MVTEC_URL="${MVTEC_URL:-https://www.mydrive.ch/shares/45920/dd1eb345346df066c63b5c95676b961b/download/428824485-1643285832/mvtec_3d_anomaly_detection.tar.xz}"

echo
 echo "[1/3] MVTec 3D-AD"
if [[ ! -f "$MVTEC_ARCHIVE" ]] || ! echo "$MVTEC_MD5  $MVTEC_ARCHIVE" | md5sum -c - >/dev/null 2>&1; then
    wget \
        --continue \
        --tries=0 \
        --timeout=60 \
        --read-timeout=60 \
        --retry-connrefused \
        --output-document="$MVTEC_ARCHIVE" \
        "$MVTEC_URL"
fi

if ! echo "$MVTEC_MD5  $MVTEC_ARCHIVE" | md5sum -c -; then
    cat >&2 <<'EOF'
MVTec 3D-AD checksum failed. The current MVTec website may have issued a
new form-protected URL. Fill in the official download form, copy the final
file URL, then rerun:

  MVTEC_URL='PASTE_THE_NEW_URL_HERE' bash download_cvpr2027_datasets.sh
EOF
    exit 2
fi

if [[ ! -f "$MVTEC_DIR/.extract_complete" ]]; then
    mkdir -p "$MVTEC_DIR"
    tar -xJf "$MVTEC_ARCHIVE" -C "$MVTEC_DIR"
    touch "$MVTEC_DIR/.extract_complete"
fi

echo "MVTec 3D-AD completed: $MVTEC_DIR"

# ---------------------------
# 2. Eyecandies (10 official class archives)
# ---------------------------
EYECANDIES_DIR="$DATA_ROOT/Eyecandies"
EYECANDIES_ARCHIVE_DIR="$ARCHIVE_DIR/Eyecandies"
mkdir -p "$EYECANDIES_DIR" "$EYECANDIES_ARCHIVE_DIR"

EYECANDIES_NAMES=(
    CandyCane
    ChocolateCookie
    ChocolatePraline
    Confetto
    GummyBear
    HazelnutTruffle
    LicoriceSandwich
    Lollipop
    Marshmallow
    PeppermintCandy
)

EYECANDIES_IDS=(
    1OI0Jh5tUj98j3ihFXCXf7EW2qSpeaTSY
    1PEvIXZOcxuDMBo4iuCsUVDN63jisg0QN
    1dRlDAS31QJSwROgA6yFcXo85mL0EBh25
    10GNPUIQTUheT-qd6EzO76fsUgAwsHfaq
    1OCAKXPmpNrD9s3oUcQ--mhRZTt4HGJ-W
    1PsKc4hXxsuIjqwyHh7ciPAeS-IxsPikm
    1dtU_l9gD1zoCN7fIYRksd_9KeyZklaHC
    1DbL91Zjm2I9-AfJewU3M354pW4vnuaNz
    1pebIU3AegEFilqqoROaVzOZqkSgX-JTo
    1tF_1fPJYaUVaf1AwjlEi-fsGWzgCx6UF
)

echo
 echo "[2/3] Eyecandies"
for i in "${!EYECANDIES_NAMES[@]}"; do
    name="${EYECANDIES_NAMES[$i]}"
    file_id="${EYECANDIES_IDS[$i]}"
    archive="$EYECANDIES_ARCHIVE_DIR/${name}.tar"
    target="$EYECANDIES_DIR/$name"

    echo "  -> $name"

    if [[ ! -f "$archive" ]] || ! tar -tf "$archive" >/dev/null 2>&1; then
        "$GDOWN" --continue \
            "https://drive.google.com/uc?id=${file_id}" \
            -O "$archive"
    fi

    tar -tf "$archive" >/dev/null

    if [[ ! -f "$target/.extract_complete" ]]; then
        mkdir -p "$target"
        tar -xf "$archive" -C "$target"
        touch "$target/.extract_complete"
    fi
done

echo "Eyecandies completed: $EYECANDIES_DIR"

# ---------------------------
# 3. Real-IAD D3 (gated Hugging Face dataset)
# ---------------------------
REALIAD_DIR="$DATA_ROOT/Real-IAD_D3"
mkdir -p "$REALIAD_DIR"

echo
 echo "[3/3] Real-IAD D3"
echo "This dataset is gated. Your Hugging Face account must be approved first."

TOKEN_ARGS=()
if [[ -n "${HF_TOKEN:-}" ]]; then
    TOKEN_ARGS=(--token "$HF_TOKEN")
elif ! "$HF" auth whoami >/dev/null 2>&1; then
    echo "No Hugging Face login found. Log in now with a READ token."
    "$HF" auth login
fi

"$HF" download Real-IAD/Real-IAD_D3 \
    --repo-type dataset \
    --local-dir "$REALIAD_DIR" \
    --max-workers "$HF_WORKERS" \
    "${TOKEN_ARGS[@]}"

echo "Real-IAD D3 downloaded: $REALIAD_DIR"

# Real-IAD D3 is distributed as large ZIP archives. Extraction is optional
# because keeping both ZIPs and extracted data consumes much more disk space.
if [[ "$EXTRACT_REALIAD" == "1" ]]; then
    if ! command -v unzip >/dev/null 2>&1; then
        echo "Command 'unzip' is required for EXTRACT_REALIAD=1." >&2
        exit 3
    fi

    REALIAD_EXTRACTED="$DATA_ROOT/Real-IAD_D3_extracted"
    mkdir -p "$REALIAD_EXTRACTED"

    while IFS= read -r -d '' zipfile; do
        base="$(basename "$zipfile" .zip)"
        target="$REALIAD_EXTRACTED/$base"
        marker="$target/.extract_complete"

        if [[ ! -f "$marker" ]]; then
            echo "Extracting: $zipfile"
            mkdir -p "$target"
            unzip -q -n "$zipfile" -d "$target"
            touch "$marker"
        fi
    done < <(find "$REALIAD_DIR" -type f -name '*.zip' -print0)

    echo "Real-IAD D3 extracted: $REALIAD_EXTRACTED"
else
    echo "Real-IAD D3 ZIP files were kept compressed."
    echo "To extract later, rerun with EXTRACT_REALIAD=1."
fi

echo
echo "====================== FINISHED ============================"
du -sh "$DATA_ROOT"/* 2>/dev/null | sort -h || true
echo "============================================================"
