#!/bin/sh
# Daily NAS pull: GCS backup bucket + Firebase Storage → local disk.
# Install on UGREEN NAS at: /volume1/docker/rclone/nas_backup_sync.sh
# Schedule via UGOS Task Scheduler (~03:00, after the 02:00 Firestore export).

set -eu

CONFIG_DIR="/volume1/docker/rclone"
DATA_DIR="/volume1/backups/easystudy"
LOG_DIR="/volume1/backups/easystudy/logs"
RCLONE_IMAGE="rclone/rclone:latest"

mkdir -p "$CONFIG_DIR" "$DATA_DIR/firestore" "$DATA_DIR/storage" "$LOG_DIR"
LOG="$LOG_DIR/sync-$(date +%Y%m%d-%H%M).log"

if [ ! -f "$CONFIG_DIR/nas-backup-key.json" ]; then
  echo "Missing $CONFIG_DIR/nas-backup-key.json — run setup_nas_backup_gcp.sh on your Mac first." >&2
  exit 1
fi

if [ ! -f "$CONFIG_DIR/rclone.conf" ]; then
  cat >"$CONFIG_DIR/rclone.conf" <<'EOF'
[gcs]
type = google cloud storage
service_account_file = /config/nas-backup-key.json
project_number = chinese-tracker
EOF
fi

run_sync() {
  SRC="$1"
  DEST="$2"
  echo "==> sync $SRC -> $DEST" | tee -a "$LOG"
  docker run --rm \
    -v "$CONFIG_DIR:/config:ro" \
    -v "$DATA_DIR:/data" \
    "$RCLONE_IMAGE" \
    sync "$SRC" "$DEST" \
    --config /config/rclone.conf \
    --fast-list \
    --log-file /data/logs/rclone-last.log \
    --log-level INFO \
    2>&1 | tee -a "$LOG"
}

{
  echo "=== Easy Study NAS backup $(date -Iseconds) ==="
  run_sync "gcs:chinese-tracker-backups" "/data/firestore"
  run_sync "gcs:chinese-tracker.firebasestorage.app" "/data/storage"
  echo "=== done ==="
} >>"$LOG" 2>&1

# Keep last 14 daily logs
ls -1t "$LOG_DIR"/sync-*.log 2>/dev/null | tail -n +15 | while read -r f; do rm -f "$f"; done
