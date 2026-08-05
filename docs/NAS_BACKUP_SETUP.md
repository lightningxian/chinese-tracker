# NAS backup setup — Firestore + Storage → UGREEN NAS

Two parts: (A) GCP exports your data to a Cloud Storage bucket on a schedule;
(B) the NAS pulls that bucket (and the Storage bucket) on a schedule with rclone.
The NAS is never in the live path — it's a recovery copy on hardware you control.

Project: `chinese-tracker`. Replace bucket names if you prefer.

---

## Quick start (UGREEN UGOS)

**On your Mac** (one time):

```bash
gcloud auth login
gcloud config set project chinese-tracker
bash scripts/setup_nas_backup_gcp.sh
```

This creates `gs://chinese-tracker-backups`, grants the scheduled export function
access, creates a read-only `nas-backup` service account, and writes
`nas-backup-key.json` (gitignored) plus `scripts/nas/rclone.conf`.

**On the UGREEN NAS:**

1. **File Manager** (or SMB): create folders
   - `/volume1/docker/rclone/`
   - `/volume1/backups/easystudy/`
2. Copy from your Mac:
   - `nas-backup-key.json` → `/volume1/docker/rclone/`
   - `scripts/nas/nas_backup_sync.sh` → `/volume1/docker/rclone/`
   - `scripts/nas/rclone.conf` → `/volume1/docker/rclone/`
3. **UGOS → Docker**: ensure Docker is enabled (pulls `rclone/rclone` on first run).
4. **UGOS → Task Scheduler → Create**:
   - Name: `Easy Study backup`
   - Schedule: daily **03:00** (after the 02:00 Firestore export)
   - User-defined script:
     ```sh
     /volume1/docker/rclone/nas_backup_sync.sh
     ```
5. Run the script once from SSH or Task Scheduler → confirm files under
   `/volume1/backups/easystudy/firestore/` and `…/storage/`.

The nightly export function `scheduledFirestoreExport` is already deployed.

---

## A. GCP side — scheduled export to a bucket

### 1. Create the backup bucket (same region as Firestore)
```bash
gcloud config set project chinese-tracker
gcloud storage buckets create gs://chinese-tracker-backups --location=asia-southeast2
```

### 2. Option 1 — managed scheduled export via a Cloud Function (recommended)
Add to `functions/` (needs the export client):
```bash
cd functions && npm install @google-cloud/firestore && cd ..
```
```js
// functions/index.js — append
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {v1} = require("@google-cloud/firestore");
const exportClient = new v1.FirestoreAdminClient();

exports.scheduledFirestoreExport = onSchedule(
  {schedule: "every day 02:00", timeZone: "Asia/Jakarta"},
  async () => {
    const projectId = process.env.GCLOUD_PROJECT;
    const name = exportClient.databasePath(projectId, "(default)");
    const day = new Date().toISOString().slice(0, 10);
    await exportClient.exportDocuments({
      name,
      outputUriPrefix: `gs://chinese-tracker-backups/firestore/${day}`,
      collectionIds: [], // empty = all collections
    });
    return null;
  },
);
```
Grant the functions runtime service account export rights:
```bash
PROJ=chinese-tracker
SA="$PROJ@appspot.gserviceaccount.com"   # or the gen2 compute SA shown in console
gcloud projects add-iam-policy-binding $PROJ \
  --member="serviceAccount:$SA" --role="roles/datastore.importExportAdmin"
gcloud storage buckets add-iam-policy-binding gs://chinese-tracker-backups \
  --member="serviceAccount:$SA" --role="roles/storage.admin"
```
Deploy: `firebase deploy --only functions:scheduledFirestoreExport`

### 2. Option 2 — no code (manual/cron on any machine)
```bash
gcloud firestore export gs://chinese-tracker-backups/firestore/$(date +%F)
```
Run it from Cloud Shell now to seed the first backup; schedule later.

### 3. Read-only service account for the NAS
```bash
PROJ=chinese-tracker
gcloud iam service-accounts create nas-backup --display-name="NAS backup (read-only)"
NAS_SA="nas-backup@$PROJ.iam.gserviceaccount.com"
# read the export bucket
gcloud storage buckets add-iam-policy-binding gs://chinese-tracker-backups \
  --member="serviceAccount:$NAS_SA" --role="roles/storage.objectViewer"
# read the app's Storage bucket (uploaded materials / photos)
gcloud storage buckets add-iam-policy-binding gs://chinese-tracker.firebasestorage.app \
  --member="serviceAccount:$NAS_SA" --role="roles/storage.objectViewer"
gcloud iam service-accounts keys create nas-backup-key.json --iam-account=$NAS_SA
```
Move `nas-backup-key.json` onto the NAS (e.g. `/volume1/docker/rclone/`). Keep it
private; it is read-only but still a credential.

---

## B. NAS side (UGREEN UGOS) — rclone pull

### 1. rclone config (`rclone.conf`)
```ini
[gcs]
type = google cloud storage
service_account_file = /config/nas-backup-key.json
project_number = chinese-tracker
```

### 2. Run rclone in Docker (UGOS → Docker)
```bash
docker run --rm \
  -v /volume1/docker/rclone:/config \
  -v /volume1/backups/easystudy:/data \
  rclone/rclone:latest \
  sync gcs:chinese-tracker-backups /data/firestore \
  --config /config/rclone.conf --fast-list
```
Second job for uploaded files:
```bash
docker run --rm \
  -v /volume1/docker/rclone:/config \
  -v /volume1/backups/easystudy:/data \
  rclone/rclone:latest \
  sync gcs:chinese-tracker.firebasestorage.app /data/storage \
  --config /config/rclone.conf --fast-list
```

### 3. Schedule daily (UGOS Task Scheduler, ~03:00, after the 02:00 export)
Put both `docker run` lines in a small script and add it as a scheduled task, or
use UGOS's built-in **cloud sync** if it lists Google Cloud Storage as a provider.

### 4. Verify + know the restore
- [ ] Confirm files actually land in `/volume1/backups/easystudy/…`.
- [ ] Restore drill (into a **test** project/db, never prod):
  ```bash
  gcloud firestore import gs://chinese-tracker-backups/firestore/<DATE>
  ```
  Storage files can be copied back with `gcloud storage cp -r`.

> Result: a daily local copy of every student, invoice, grade, and uploaded
> material on your NAS — without exposing the NAS or touching the live app.
