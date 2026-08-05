#!/usr/bin/env bash
# One-time GCP setup for NAS backup (docs/NAS_BACKUP_SETUP.md).
# Run on your Mac after: gcloud auth login && gcloud config set project chinese-tracker
#
# Creates:
#   - gs://chinese-tracker-backups (Firestore export destination)
#   - IAM for the Cloud Functions runtime (scheduled export)
#   - read-only nas-backup service account + key file for the UGREEN NAS
#
# Output: nas-backup-key.json in the repo root (gitignored). Copy to the NAS.

set -euo pipefail

PROJ="${GCP_PROJECT:-chinese-tracker}"
BUCKET="gs://chinese-tracker-backups"
STORAGE_BUCKET="gs://chinese-tracker.firebasestorage.app"
NAS_SA_NAME="nas-backup"
NAS_SA="${NAS_SA_NAME}@${PROJ}.iam.gserviceaccount.com"
KEY_OUT="$(cd "$(dirname "$0")/.." && pwd)/nas-backup-key.json"

echo "==> Project: $PROJ"

if ! gcloud auth list --filter=status:ACTIVE --format='value(account)' | grep -q .; then
  echo "Run: gcloud auth login"
  exit 1
fi

gcloud config set project "$PROJ" >/dev/null

echo "==> Create backup bucket (skip if exists)"
if gcloud storage buckets describe "$BUCKET" >/dev/null 2>&1; then
  echo "    $BUCKET already exists"
else
  gcloud storage buckets create "$BUCKET" --location=asia-southeast2
fi

echo "==> Resolve Cloud Functions runtime service account"
PROJECT_NUMBER="$(gcloud projects describe "$PROJ" --format='value(projectNumber)')"
# Gen2 default compute SA (scheduledFirestoreExport runs as this unless overridden)
RUNTIME_SA="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"
echo "    Runtime SA: $RUNTIME_SA"

echo "==> Grant export + bucket write to runtime SA"
gcloud projects add-iam-policy-binding "$PROJ" \
  --member="serviceAccount:$RUNTIME_SA" \
  --role="roles/datastore.importExportAdmin" \
  --condition=None \
  --quiet >/dev/null
gcloud storage buckets add-iam-policy-binding "$BUCKET" \
  --member="serviceAccount:$RUNTIME_SA" \
  --role="roles/storage.admin" \
  --quiet >/dev/null

echo "==> Create read-only NAS service account (skip if exists)"
if gcloud iam service-accounts describe "$NAS_SA" >/dev/null 2>&1; then
  echo "    $NAS_SA already exists"
else
  gcloud iam service-accounts create "$NAS_SA_NAME" \
    --display-name="NAS backup (read-only)"
fi

echo "==> Grant NAS SA read-only on backup + app Storage buckets"
gcloud storage buckets add-iam-policy-binding "$BUCKET" \
  --member="serviceAccount:$NAS_SA" \
  --role="roles/storage.objectViewer" \
  --quiet >/dev/null
if gcloud storage buckets describe "$STORAGE_BUCKET" >/dev/null 2>&1; then
  gcloud storage buckets add-iam-policy-binding "$STORAGE_BUCKET" \
    --member="serviceAccount:$NAS_SA" \
    --role="roles/storage.objectViewer" \
    --quiet >/dev/null
else
  echo "    WARN: $STORAGE_BUCKET not found — enable Firebase Storage first"
fi

echo "==> Create key for NAS: $KEY_OUT"
if [[ -f "$KEY_OUT" ]]; then
  echo "    Key file already exists — delete it first if you need a new key"
else
  gcloud iam service-accounts keys create "$KEY_OUT" --iam-account="$NAS_SA"
fi

NAS_DIR="$(cd "$(dirname "$0")/nas" && pwd)"
cat >"$NAS_DIR/rclone.conf" <<EOF
[gcs]
type = google cloud storage
service_account_file = /config/nas-backup-key.json
project_number = $PROJECT_NUMBER
EOF
echo "    Wrote $NAS_DIR/rclone.conf (project_number=$PROJECT_NUMBER)"

echo "==> Seed first Firestore export (optional, may take a few minutes)"
read -r -p "Run a manual export now? [y/N] " DO_EXPORT
if [[ "${DO_EXPORT,,}" == "y" ]]; then
  DAY="$(date +%F)"
  gcloud firestore export "${BUCKET}/firestore/${DAY}"
  echo "    Export started: ${BUCKET}/firestore/${DAY}"
fi

cat <<EOF

Done. Next — on your UGREEN NAS:

  1. Copy to the NAS (File Manager or scp):
       nas-backup-key.json  →  /volume1/docker/rclone/nas-backup-key.json
       scripts/nas/         →  /volume1/docker/rclone/

  2. UGOS → Docker: ensure Docker is running.

  3. UGOS → Task Scheduler → Create:
       Name: Easy Study backup
       Schedule: Daily 03:00
       User script:
         /volume1/docker/rclone/nas_backup_sync.sh

  4. Run once manually to verify files appear under:
       /volume1/backups/easystudy/firestore/
       /volume1/backups/easystudy/storage/

See docs/NAS_BACKUP_SETUP.md for restore drill.

EOF
