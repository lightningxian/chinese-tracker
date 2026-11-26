#!/usr/bin/env bash
# One-time Google Cloud setup for the NAS backup (docs/NAS_BACKUP_SETUP.md).
#
# Run it in Google Cloud Shell (nothing to install), signed in as the owner:
#   https://shell.cloud.google.com/?project=chinese-tracker
#   curl -fsSL https://raw.githubusercontent.com/lightningxian/chinese-tracker/main/scripts/setup_nas_backup_gcp.sh -o setup_nas.sh && bash setup_nas.sh
#
# What it makes (safe to run again; it skips what already exists):
#   1. Bucket gs://chinese-tracker-backups (Jakarta, same place as the database).
#      Exports older than 2 days are deleted there; the NAS keeps its own copy.
#   2. Service account "firestore-export": may only export the database into
#      that bucket. A Cloud Scheduler job uses it every night at 02:00 Jakarta
#      (no Cloud Function, no code to deploy).
#   3. Service account "nas-backup": READ-ONLY on the backup bucket and on the
#      app's file bucket. Its key (nas-backup-key.json) goes onto the NAS.
#   4. Runs the export once now so the NAS has something to fetch today.

set -euo pipefail

PROJ="${GCP_PROJECT:-chinese-tracker}"
REGION="asia-southeast2"            # where Firestore lives
SCHED_REGION="us-central1"          # where the app's other scheduler jobs live
BUCKET="gs://chinese-tracker-backups"
FILES_BUCKET="gs://chinese-tracker.firebasestorage.app"
EXPORT_SA="firestore-export@${PROJ}.iam.gserviceaccount.com"
NAS_SA="nas-backup@${PROJ}.iam.gserviceaccount.com"
JOB="firestore-nightly-export"
KEY_OUT="$HOME/nas-backup-key.json"

echo "==> Project $PROJ"
gcloud config set project "$PROJ" >/dev/null
PROJECT_NUMBER="$(gcloud projects describe "$PROJ" --format='value(projectNumber)')"
FIRESTORE_AGENT="service-${PROJECT_NUMBER}@gcp-sa-firestore.iam.gserviceaccount.com"

echo "==> Turn on the APIs it needs"
gcloud services enable cloudscheduler.googleapis.com iam.googleapis.com \
  firestore.googleapis.com storage.googleapis.com >/dev/null

echo "==> 1. Backup bucket"
if gcloud storage buckets describe "$BUCKET" >/dev/null 2>&1; then
  echo "    $BUCKET already exists"
else
  gcloud storage buckets create "$BUCKET" --location="$REGION" \
    --uniform-bucket-level-access --public-access-prevention
fi
cat >/tmp/es_lifecycle.json <<'EOF'
{"rule": [{"action": {"type": "Delete"}, "condition": {"age": 2}}]}
EOF
gcloud storage buckets update "$BUCKET" --lifecycle-file=/tmp/es_lifecycle.json >/dev/null
echo "    exports there are deleted after 2 days (the NAS keeps 7)"

echo "==> 2. Nightly export (service account + Cloud Scheduler job)"
if ! gcloud iam service-accounts describe "$EXPORT_SA" >/dev/null 2>&1; then
  gcloud iam service-accounts create firestore-export \
    --display-name="Nightly Firestore export to the backup bucket"
fi
gcloud projects add-iam-policy-binding "$PROJ" \
  --member="serviceAccount:$EXPORT_SA" --role="roles/datastore.importExportAdmin" \
  --condition=None --quiet >/dev/null
for MEMBER in "serviceAccount:$EXPORT_SA" "serviceAccount:$FIRESTORE_AGENT"; do
  gcloud storage buckets add-iam-policy-binding "$BUCKET" \
    --member="$MEMBER" --role="roles/storage.admin" --quiet >/dev/null
done

URI="https://firestore.googleapis.com/v1/projects/${PROJ}/databases/(default):exportDocuments"
BODY="{\"outputUriPrefix\":\"${BUCKET}\"}"
if gcloud scheduler jobs describe "$JOB" --location="$SCHED_REGION" >/dev/null 2>&1; then
  echo "    job $JOB already exists"
else
  gcloud scheduler jobs create http "$JOB" --location="$SCHED_REGION" \
    --schedule="0 2 * * *" --time-zone="Asia/Jakarta" \
    --uri="$URI" --http-method=POST \
    --headers="Content-Type=application/json" --message-body="$BODY" \
    --oauth-service-account-email="$EXPORT_SA" \
    --oauth-token-scope="https://www.googleapis.com/auth/datastore" \
    --description="Easy Study: nightly Firestore export for the NAS backup"
fi

echo "==> 3. Read-only account for the NAS"
if ! gcloud iam service-accounts describe "$NAS_SA" >/dev/null 2>&1; then
  gcloud iam service-accounts create nas-backup --display-name="NAS backup (read-only)"
fi
for B in "$BUCKET" "$FILES_BUCKET"; do
  gcloud storage buckets add-iam-policy-binding "$B" \
    --member="serviceAccount:$NAS_SA" --role="roles/storage.objectViewer" --quiet >/dev/null
done
if [[ -f "$KEY_OUT" ]]; then
  echo "    $KEY_OUT already exists (delete it first if you need a new key)"
else
  gcloud iam service-accounts keys create "$KEY_OUT" --iam-account="$NAS_SA"
fi

echo "==> 4. First export now"
sleep 20   # new permissions take a moment to apply
gcloud scheduler jobs run "$JOB" --location="$SCHED_REGION"
echo "    started; it takes a few minutes. Check with:"
echo "    gcloud storage ls $BUCKET"

cat <<EOF

Done on the Google side.

NEXT (in this Cloud Shell window):
  1. Click the three dots (More) at the top of Cloud Shell -> Download,
     type:  $KEY_OUT   and save it on your PC.
  2. Then remove the copy here:   rm $KEY_OUT

Then follow "On the NAS" in docs/NAS_BACKUP_SETUP.md.
Keep nas-backup-key.json private: it can READ all student data.
EOF
