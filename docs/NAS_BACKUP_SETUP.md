# NAS backup: database + uploaded files → UGREEN NAS

> **Rewritten 2026-11-26.** The old version needed `gcloud` on the Mac, a Cloud
> Function (removed 2026-11-13) and the UGOS Task Scheduler. Now: one script in
> Google Cloud Shell (in the browser, nothing to install) and one Docker
> project on the NAS.

## What you get

Every night, without anyone doing anything:

| Time (Jakarta) | Where | What happens |
|---|---|---|
| 02:00 | Google | Cloud Scheduler asks Firestore to export the whole database into the bucket `gs://chinese-tracker-backups` (no code; job `firestore-nightly-export`). |
| 03:00 | NAS | The `easystudy-backup` container copies the new export and all uploaded files (payment photos, recordings, papers, answer PDFs…) to the NAS. |

On the NAS, in `/volume1/backups/easystudy/`:

```
LAST_RUN.txt             one line: when it last ran and whether it worked
firestore/<date…>/       database exports, the last 7 days
storage/current/         every uploaded file, as it is now
storage/deleted/<day>/   files removed or replaced in the app that day (kept 7 days)
logs/                    one log per day (kept 7 days)
```

Seven days matches the privacy policy ("Backups are kept for 7 days"; it also
says a copy is kept on the centre's own storage device). If you change
`KEEP_DAYS`, change the policy text too (`lib/features/legal/privacy_policy_page.dart`).

The NAS is never in the live path. The website keeps working if the NAS is off;
it only catches up the next night.

Firestore's own daily backups (`docs/OWNER_PROCEDURES.md` §B) stay on too;
those live inside Google and can be restored in minutes, but cannot be
downloaded. The NAS copy is the one on hardware you own.

---

## Step 1: Google side (about 5 minutes, once)

1. Open **https://shell.cloud.google.com/?project=chinese-tracker** with the
   Google account that owns the Firebase project. A terminal opens at the
   bottom of the page (click **Authorize** if it asks).
2. Paste this line and press Enter:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/lightningxian/chinese-tracker/main/scripts/setup_nas_backup_gcp.sh -o setup_nas.sh && bash setup_nas.sh
   ```
   It makes the backup bucket, the nightly export job, a **read-only** account
   for the NAS and its key, and starts the first export. It ends with
   "Done on the Google side".
3. Download the key: in Cloud Shell click **⋮ (More) → Download**, type
   `nas-backup-key.json` (it is in your home folder) and save it on the PC.
4. Remove the copy in Cloud Shell:
   ```bash
   rm ~/nas-backup-key.json
   ```

`nas-backup-key.json` can **read** all student data and uploaded files (it
cannot change or delete anything). Keep it only on the NAS; never put it in the
repo (it is git-ignored) or in chat. If it leaks, delete the key in Google
Cloud console → IAM → Service accounts → `nas-backup` → Keys, and make a new one
by running the script again.

## Step 2: NAS side (about 10 minutes, once)

1. **File Manager** on the NAS: make two folders:
   - `docker/easystudy-backup` (inside the `docker` shared folder)
   - `backups/easystudy` (make a shared folder `backups` if there is none)
2. Copy these four files into `docker/easystudy-backup`:
   - `nas-backup-key.json` (from Step 1)
   - `backup_loop.sh`, `rclone.conf`, `docker-compose.yml` from the repo
     folder `scripts\nas\`
3. **Docker** app → **Project** → **Create**:
   - Name: `easystudy-backup`
   - Path: the `docker/easystudy-backup` folder
   - Compose: it finds `docker-compose.yml` (or paste its contents)
   - **Deploy / Start**
4. The container runs a backup straight away. After a few minutes open
   `backups/easystudy/LAST_RUN.txt`. It should say **OK** with a number of
   exports and files. If it says FAILED, open the newest file in `logs/`.

If the NAS storage pool is not `volume1`, change the two left-hand paths in
`docker-compose.yml` before step 3 (the Docker app shows the real path when
you pick a folder).

## Checking it later

- `LAST_RUN.txt` should show today's (or last night's) date and **OK**.
- In Google Cloud console → **Cloud Scheduler**, the job
  `firestore-nightly-export` shows "Success" for its last run.

## Restoring (only if ever needed)

- **Database:** upload the export folder back to a bucket and import it into a
  **new** database, never straight over the live one:
  ```bash
  gcloud firestore databases create --database=restored-copy --location=asia-southeast2
  gcloud firestore import gs://chinese-tracker-backups/<export folder> --database=restored-copy
  ```
  Then compare and copy what is needed. Ask the BUILD chat for help first.
- **Files:** upload the needed files from `storage/current/` (or
  `storage/deleted/<day>/`) back to the same path in Firebase Storage.

## Cost

Small. Each export reads every document once (Firestore read charges), the
bucket keeps exports for 2 days only, and the NAS downloads only new or
changed files after the first night (Google charges a little for data leaving
its network).

## Files

| File | Runs where | Job |
|---|---|---|
| `scripts/setup_nas_backup_gcp.sh` | Google Cloud Shell, once | bucket, export job, NAS account and key |
| `scripts/nas/docker-compose.yml` | NAS Docker | the `easystudy-backup` container (rclone 1.68.2) |
| `scripts/nas/backup_loop.sh` | inside that container | runs at start and every night at 03:00 Jakarta; `ONCE=1` runs once |
| `scripts/nas/rclone.conf` | inside that container | tells rclone to use the key |
