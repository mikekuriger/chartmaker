#!/bin/bash

set -e


notify_exit() {
    status=$?

    if [ "$status" -eq 0 ]; then
        /usr/bin/osascript -e \
          'display dialog "'"$DAT"' - TFR update completed successfully" with title "METAR Map"'
    else
        /usr/bin/osascript -e \
          'display dialog "'"$DAT"' - TFR update FAILED" with title "METAR Map"'
    fi
}

trap notify_exit EXIT

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

log "========================================"
log "Starting TFR update"
log "User: $(whoami)"

if [[ "$(whoami)" != "michaelkuriger" ]]; then
    log "ERROR: must be michaelkuriger"
    exit 1
fi

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

DATE=$(date "+%y%m%d_%H%M%S")
DAT=$(date "+%a %b %d %I:%M %p")

BASE="/Volumes/NFS/chartmaker"
REPO="$BASE/MetarMap"
PYTHON="$BASE/venv/bin/python"

cd "$REPO/scripts/build_tfrs"

log "Working directory: $(pwd)"

"$PYTHON" faa_get_tfrs.py tfrs.geojson

sed -i '' 's/,,/,/' tfrs.geojson

/bin/cp tfrs.geojson "$REPO/scripts/tfrs.geojson"

cd "$REPO/scripts"

/usr/bin/git add tfrs.geojson

if /usr/bin/git diff --cached --quiet; then
    log "No changes to commit"
else
    log "Changes detected; committing"

    /usr/bin/git commit -m "auto-commit $DATE"
    /usr/bin/git push origin HEAD:main

    log "Changes pushed successfully"
fi

log "TFR update completed successfully"
