#!/bin/sh
# Easy Study NAS backup. Runs inside the rclone container
# (scripts/nas/docker-compose.yml): once when the container starts, then every
# night at RUN_HOUR_UTC (20:00 UTC = 03:00 Jakarta, one hour after the
# 02:00 database export).
#
#   /data/firestore/<export folder>/   database exports, the last KEEP_DAYS days
#   /data/storage/current/             all uploaded files, as they are now
#   /data/storage/deleted/<day>/       files removed or changed in the app that day
#   /data/logs/backup-<day>.log        what happened
#   /data/LAST_RUN.txt                 one line: when and whether it worked
#
# KEEP_DAYS matches the privacy policy ("Backups are kept for 7 days").

set -u
CONF="${CONF:-/config/rclone.conf}"
DATA="${DATA:-/data}"
KEEP_DAYS="${KEEP_DAYS:-7}"
RUN_HOUR_UTC="${RUN_HOUR_UTC:-20}"
EXPORTS="gcs:chinese-tracker-backups"
FILES="gcs:chinese-tracker.firebasestorage.app"

mkdir -p "$DATA/firestore" "$DATA/storage/current" "$DATA/storage/deleted" "$DATA/logs"

# YYYYMMDD of a name that starts with YYYY-MM-DD, or nothing.
day_of() {
  d=$(echo "$1" | cut -c1-10 | tr -d '-')
  case "$d" in
    [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]) echo "$d" ;;
  esac
}

# Removes entries in $1 whose name starts with a date older than KEEP_DAYS.
prune() {
  cutoff=$(date -u -d "@$(( $(date +%s) - KEEP_DAYS * 86400 ))" +%Y%m%d)
  for path in "$1"/*; do
    [ -e "$path" ] || continue
    d=$(day_of "$(basename "$path")")
    if [ -n "$d" ] && [ "$d" -lt "$cutoff" ]; then
      echo "prune $path"
      rm -rf "$path"
    fi
  done
}

backup() {
  day=$(date -u +%Y-%m-%d)
  log="$DATA/logs/backup-$day.log"
  {
    echo "=== $(date -u '+%Y-%m-%d %H:%M:%S') UTC start"
    rclone copy "$EXPORTS" "$DATA/firestore" --config "$CONF" --fast-list --log-level NOTICE
    db=$?
    rclone sync "$FILES" "$DATA/storage/current" --backup-dir "$DATA/storage/deleted/$day" \
      --config "$CONF" --fast-list --log-level NOTICE
    files=$?
    prune "$DATA/firestore"
    prune "$DATA/storage/deleted"
    prune "$DATA/logs"
    echo "database exit $db, files exit $files"
    echo "=== $(date -u '+%Y-%m-%d %H:%M:%S') UTC done"
  } >>"$log" 2>&1
  if [ "$db" -eq 0 ] && [ "$files" -eq 0 ]; then
    result="OK"
  else
    result="FAILED (see logs/backup-$day.log)"
  fi
  echo "$(date -u '+%Y-%m-%d %H:%M') UTC  $result  exports: $(ls "$DATA/firestore" | wc -l)  files: $(find "$DATA/storage/current" -type f | wc -l)" \
    >"$DATA/LAST_RUN.txt"
  cat "$DATA/LAST_RUN.txt"
}

# Seconds until the next RUN_HOUR_UTC:00 (never 0).
seconds_to_next_run() {
  now=$(( $(date +%s) % 86400 ))
  wait=$(( (RUN_HOUR_UTC * 3600 - now + 86400) % 86400 ))
  [ "$wait" -eq 0 ] && wait=86400
  echo "$wait"
}

if [ "${ONCE:-0}" = "1" ]; then
  backup
  exit 0
fi

backup
while true; do
  sleep "$(seconds_to_next_run)"
  backup
done
