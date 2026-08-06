#!/usr/bin/env bash
set -euo pipefail

export BASE="/Volumes/NFS/chartmaker"
CHARTCACHE="${BASE}/chartmaker/chartcache"
logtime=$(date '+%Y-%m-%d')

FORCE=0
if [[ "${1-}" == "--force" || "${1-}" == "-f" ]]; then
  FORCE=1
fi

# === 1) Pick the best chart date using the same rules as getBestChartDate() ===
BEST_DATE="$(
python3 - << 'PY'
import json, os, sys
from datetime import datetime, date

base = os.environ["BASE"]
appdir = os.path.join(base, "chartmaker")
json_path = os.path.join(appdir, "chartdates.json")

try:
    with open(json_path, "r") as f:
        data = json.load(f)
except FileNotFoundError:
    print(f"ERROR: {json_path} not found", file=sys.stderr)
    sys.exit(1)

dates = []
for s in data.get("ChartDates", []):
    # JS uses new Date(cdate); assuming MM-DD-YYYY strings
    try:
        dt = datetime.strptime(s, "%m-%d-%Y").date()
        dates.append(dt)
    except ValueError:
        continue

if not dates:
    print("ERROR: No valid dates in ChartDates", file=sys.stderr)
    sys.exit(1)

# Sort newest → oldest
dates.sort(reverse=True)

now = date.today()
selected = None
expiredate = None

for dt in dates:
    diffdays = (now - dt).days  # integer day difference

    if selected is None:
        # if (diffdays >= -20 && diffdays <= 36)
        if -20 <= diffdays <= 36:
            selected = dt
    elif expiredate is None:
        expiredate = dt

if selected is None:
    print("ERROR: No suitable chart date was found!", file=sys.stderr)
    sys.exit(1)

print(selected.strftime("%m-%d-%Y"))
PY
)"

if [[ -z "$BEST_DATE" ]]; then
  echo "ERROR: getBestChartDate logic returned an empty date"
  exit 1
fi

#echo "Selected chart cycle (from chartdates.json): $BEST_DATE"

# === 2) Check local cache for that cycle (unless forced) ===

SECTIONAL_ZIP="${CHARTCACHE}/Sectional-${BEST_DATE}.zip"

if [[ "$FORCE" -eq 0 ]]; then
  if [[ -f "$SECTIONAL_ZIP" ]]; then
    echo "Already have Sectional ZIP for ${BEST_DATE}:"
    echo "  $SECTIONAL_ZIP"
    echo "Nothing to do."
    exit 0
  fi
  echo "No local Sectional ZIP for ${BEST_DATE}, starting build..."
else
  echo "--force specified: running Docker chart build even though cache may exist."
fi

# GO
set -u

timestamp() {
  date '+%Y-%m-%d %H:%M:%S %z'
}

# ========== TASK 1 ==========
echo "Task:      task1"          | tee $BASE/build_charts/logs/task1.$logtime
echo "Command:   $BASE/MetarMap/scripts/build_charts/1_cleanup_workarea.sh" | tee -a $BASE/build_charts/logs/task1.$logtime
echo "Host:      $(hostname -f 2>/dev/null || hostname)" | tee -a $BASE/build_charts/logs/task1.$logtime
echo "Start:     $(timestamp)"   | tee -a $BASE/build_charts/logs/task1.$logtime
echo ""                          | tee -a $BASE/build_charts/logs/task1.$logtime
echo "Output:"                   | tee -a $BASE/build_charts/logs/task1.$logtime

$BASE/MetarMap/scripts/build_charts/1_cleanup_workarea.sh | tee -a $BASE/build_charts/logs/task1.$logtime 2>&1
rc=$?

echo ""                          | tee -a $BASE/build_charts/logs/task1.$logtime
echo "End:       $(timestamp)"   | tee -a $BASE/build_charts/logs/task1.$logtime
echo "Exit code: $rc"            | tee -a $BASE/build_charts/logs/task1.$logtime

$BASE/MetarMap/scripts/build_charts/send_mail.sh task1.$logtime


# ========== TASK 2a ==========
echo "Task:      task2"         |tee $BASE/build_charts/logs/task2.$logtime
echo "Command:   $BASE/MetarMap/scripts/build_charts/2_make_charts.sh" | tee -a $BASE/build_charts/logs/task2.$logtime
echo "Host:      $(hostname -f 2>/dev/null || hostname)" | tee -a $BASE/build_charts/logs/task2.$logtime
echo "Start:     $(timestamp)"   | tee -a $BASE/build_charts/logs/task2.$logtime
echo ""                          | tee -a $BASE/build_charts/logs/task2.$logtime
echo "Output:"                   | tee -a $BASE/build_charts/logs/task2.$logtime

$BASE/MetarMap/scripts/build_charts/2_make_charts.sh | tee -a $BASE/build_charts/logs/task2.$logtime 2>&1
rc=$?

echo ""                          | tee -a $BASE/build_charts/logs/task2.$logtime
echo "End:       $(timestamp)"   | tee -a $BASE/build_charts/logs/task2.$logtime
echo "Exit code: $rc"            | tee -a $BASE/build_charts/logs/task2.$logtime

$BASE/MetarMap/scripts/build_charts/send_mail.sh task2.$logtime

# ========== TASK 3 ==========
echo "Task:      task3"          |tee $BASE/build_charts/logs/task3.$logtime
echo "Command:   $BASE/MetarMap/scripts/build_charts/3_make_zips.py" | tee -a $BASE/build_charts/logs/task3.$logtime
echo "Host:      $(hostname -f 2>/dev/null || hostname)" | tee -a $BASE/build_charts/logs/task3.$logtime
echo "Start:     $(timestamp)"   | tee -a $BASE/build_charts/logs/task3.$logtime
echo ""                          | tee -a $BASE/build_charts/logs/task3.$logtime
echo "Output:"                   | tee -a $BASE/build_charts/logs/task3.$logtime

$BASE/MetarMap/scripts/build_charts/3_make_zips.py | tee -a $BASE/build_charts/logs/task3.$logtime 2>&1
rc=$?

echo ""                          | tee -a $BASE/build_charts/logs/task3.$logtime
echo "End:       $(timestamp)"   | tee -a $BASE/build_charts/logs/task3.$logtime
echo "Exit code: $rc"            | tee -a $BASE/build_charts/logs/task3.$logtime

$BASE/MetarMap/scripts/build_charts/send_mail.sh task3.$logtime


# ========== TASK 4 ==========
echo "Task:      task4"          |tee $BASE/build_charts/logs/task4.$logtime
echo "Command:   $BASE/MetarMap/scripts/build_charts/4_generate_chart_zips_json.py" | tee -a $BASE/build_charts/logs/task4.$logtime
echo "Host:      $(hostname -f 2>/dev/null || hostname)" | tee -a $BASE/build_charts/logs/task4.$logtime
echo "Start:     $(timestamp)"   | tee -a $BASE/build_charts/logs/task4.$logtime
echo ""                          | tee -a $BASE/build_charts/logs/task4.$logtime
echo "Output:"                   | tee -a $BASE/build_charts/logs/task4.$logtime

$BASE/MetarMap/scripts/build_charts/4_generate_chart_zips_json.py | tee -a $BASE/build_charts/logs/task4.$logtime 2>&1
rc=$?

echo ""                          | tee -a $BASE/build_charts/logs/task4.$logtime
echo "End:       $(timestamp)"   | tee -a $BASE/build_charts/logs/task4.$logtime
echo "Exit code: $rc"            | tee -a $BASE/build_charts/logs/task4.$logtime

$BASE/MetarMap/scripts/build_charts/send_mail.sh task4.$logtime


# ========== TASK 5 ==========
echo "Task:      task5"          |tee $BASE/build_charts/logs/task5.$logtime
echo "Command:   $BASE/MetarMap/scripts/build_charts/5_update_raw_tiles.sh" | tee -a $BASE/build_charts/logs/task5.$logtime
echo "Host:      $(hostname -f 2>/dev/null || hostname)" | tee -a $BASE/build_charts/logs/task5.$logtime
echo "Start:     $(timestamp)"   | tee -a $BASE/build_charts/logs/task5.$logtime
echo ""                          | tee -a $BASE/build_charts/logs/task5.$logtime
echo "Output:"                   | tee -a $BASE/build_charts/logs/task5.$logtime

$BASE/MetarMap/scripts/build_charts/5_update_raw_tiles.sh | tee -a $BASE/build_charts/logs/task5.$logtime 2>&1
rc=$?

echo ""                          | tee -a $BASE/build_charts/logs/task5.$logtime
echo "End:       $(timestamp)"   | tee -a $BASE/build_charts/logs/task5.$logtime
echo "Exit code: $rc"            | tee -a $BASE/build_charts/logs/task5.$logtime

$BASE/MetarMap/scripts/build_charts/send_mail.sh task5.$logtime

expires=$(cat $BASE/metarmap/Sectional/metadata.json  | grep expires | awk '{print $2}' | sed 's/\"//g')
# ========== TASK 6 (SKIPPED) ==========
echo "Task:      task6"          |tee $BASE/build_charts/logs/task6.$logtime
echo "Command:   (cleanup skipped)" | tee -a $BASE/build_charts/logs/task6.$logtime
echo "Host:      $(hostname -f 2>/dev/null || hostname)" | tee -a $BASE/build_charts/logs/task6.$logtime
echo "Start:     $(timestamp)"   | tee -a $BASE/build_charts/logs/task6.$logtime
echo "End:       $(timestamp)"   | tee -a $BASE/build_charts/logs/task6.$logtime
echo "Exit code: 0"              | tee -a $BASE/build_charts/logs/task6.$logtime
echo ""                          | tee -a $BASE/build_charts/logs/task6.$logtime
echo "Output:"                   | tee -a $BASE/build_charts/logs/task6.$logtime
echo "  Task 6 (cleanup) intentionally skipped." | tee -a $BASE/build_charts/logs/task6.$logtime
echo "  The data should have been moved to $BASE/metarmap/Sectional/Terminal/Enroute_Low" | tee -a $BASE/build_charts/logs/task6.$logtime
echo "  Deploy Live when ready" | tee -a $BASE/build_charts/logs/task6.$logtime
echo "  Expires $expires" | tee -a $BASE/build_charts/logs/task6.$logtime

$BASE/MetarMap/scripts/build_charts/send_mail.sh task6.$logtime

# deploy live
#cd $BASE
#$BASE/deploy.sh
