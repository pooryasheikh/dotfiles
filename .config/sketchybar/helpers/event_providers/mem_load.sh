#!/bin/bash
# Fires a sketchybar event with current memory usage.
# Shows active+wired only (not compressed/swap) — reflects real app pressure
# rather than macOS's memory compression bookkeeping.
EVENT_NAME="${1:-mem_update}"
INTERVAL="${2:-2}"

while true; do
  page_size=$(pagesize 2>/dev/null || echo 4096)
  stats=$(vm_stat)
  active=$(echo "$stats" | awk '/Pages active/{gsub(/\./, "", $3); print $3 + 0}')
  wired=$(echo "$stats" | awk '/Pages wired/{gsub(/\./, "", $4); print $4 + 0}')
  total=$(sysctl -n hw.memsize)
  used=$(( (active + wired) * page_size ))
  pct=$(( used * 100 / total ))
  sketchybar --trigger "$EVENT_NAME" percent="$pct"
  sleep "$INTERVAL"
done
