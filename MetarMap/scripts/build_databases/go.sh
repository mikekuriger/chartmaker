#!/bin/bash

set -e

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
BASE="/Volumes/NFS/chartmaker/"
REPO="$BASE/metarmap"
PYTHON="$BASE/venv/bin/python"

cd "$BASE/MetarMap/scripts/build_databases"
log "Working directory: $(pwd)"

# download new files
"$PYTHON" get_data.py > /tmp/deploy.log
if [ $? -eq 1 ]; then
    cat /tmp/deploy.log | sed "s/^/$date - /" >> deploy.log
    exit 0
fi
cat /tmp/deploy.log | sed "s/^/$date - /" >> deploy.log

# unzip files
zips="$BASE/build_databases/zip"
zipfile=$(ls $zips|tail -1)
/bin/rm -rf $BASE/build_databases/alldata/*
cd $BASE/build_databases/alldata
unzip $zips/$zipfile
/bin/rm -rf $BASE/build_databases/data/*
cd $BASE/build_databases/data
unzip $BASE/build_databases/alldata/CSV_Data/*zip
# process files into sqlite3 database
cd $BASE/build_databases
"$PYTHON" import_faa_csvs.py
"$PYTHON" import_fix_csvs.py  
"$PYTHON" import_frq_csv.py
"$PYTHON" import_all.py
/bin/mv -f data/*db .
# generate manifest for app
"$PYTHON" generate_manifest.py
# move files to site
/bin/cp *db db_manifest.json $REPO/sqlite
/bin/cp *db db_manifest.json /Volumes/Development/AndroidStudioProjects/MetarMap/app/src/main/assets/databases

# deploy live
cd $BASE
$BASE/deploy.sh
