# Easy Study (`chinese-tracker`) — Claude project guide

Flutter web + Firebase LMS for a Chinese teaching centre (易华文教中心).
Roles: admin · teacher · student · parent. Live at https://chinese-tracker.web.app.
The owner (Wilsin, a Flutter/Firebase beginner) works **only with Claude Code**, on a Mac
and a PC. Chat does not sync between machines: the docs in this repo are the shared memory,
so keep them current. Explain steps in simple English and ask before big or hard-to-undo
decisions. This app is also the owner's thesis project (see the thesis docs below).

## Read first
1. `docs/CLAUDE_FULL_HANDOFF.md`: live config, what's built, architecture map.
2. `docs/THESIS_FEATURE_AUDIT.md`: the thesis spec (`docs/THESIS_FEATURE_BACKLOG.md`, v2) compared with the code, open questions, suggested order. `docs/THESIS_PROPOSAL_ASSETS.md` lists the screenshots the proposal needs.
3. `docs/SESSION_LOG.md` (newest session first) and the top of `docs/CHANGELOG.md`.
4. `docs/BACKLOG.md` for the older non-thesis backlog.

## Decisions already made by the owner (don't re-ask)
- Design: landing page = direction "A · Pensil" (shipped 2026-10-18, `lib/features/landing/`); signed-in app = the same brand, calmer (white surfaces, less decoration). Brand tokens: `lib/features/landing/landing_brand.dart`, logo assets in `assets/brand/`.
- Keep the parent role, materials library and class modes even though the thesis leaves them out.
- UI language: Indonesian + English switch, to be built in thesis Phase 1 (app is English today).
- Teacher self-registration is closed; admins create teachers.
- Keep the Grades and Evaluations tabs (outside the thesis).
- Thesis test codes are random strings typed by the admin, with HSK level and release year as separate fields. No access to the old `easy-study-hsk` project: no import of old results.
- Voucher packages: Chinese name, validity (e.g. 2 months), 8 or 16 sessions, the student's class day. Prices live in the admin **Price list** (`settings/pricing.items`, flyer defaults).
- **Payments ↔ vouchers (2026-10-27):** every voucher links to an invoice (`sourceInvoiceId`). Admin records cash/transfer payments (`markInvoicePaid` callable); teachers may still add a term on a student page, which creates a pending invoice for the admin; old vouchers without a payment are shown on the admin dashboard as "Vouchers without payment".
- Order of work: quick security fixes (done) → emulator (done) → design system → thesis phases in order, rebuilding each screen in the new design as its phase touches it, with ViewModels.

## Never
- Create a new GitHub repo or Firebase project, or re-run `flutterfire configure`.
  `lib/firebase_options.dart` already points at the live `chinese-tracker` project.
- Commit the Midtrans **server** key. It lives in Firebase Secret Manager as `MIDTRANS_SERVER_KEY`.
- Switch Midtrans to production keys before the sandbox payment E2E test passes.
- Rewrite old commits (the first commit's author name is wrong, and that's accepted).
- Sign in to the live site with a password yourself; the owner signs in. Local emulator accounts are fine.

## Conventions
- **Commit author:** `GIT_AUTHOR_NAME="Wilsin Kuonadi" GIT_AUTHOR_EMAIL=wilsinkarimunwkk@gmail.com`
  (and matching `GIT_COMMITTER_*`) per commit. Don't change global git config.
- **Push notes:** each commit body has a 2–6 bullet plain-language summary. For milestones and deploys, also `gh release create vX.Y.Z` with the same summary (latest: v0.1.7).
- **Change log:** after any code, rules, functions or config change, add an entry at the **top** of `docs/CHANGELOG.md` (What changed / Why / For review).
- **Session log:** when a session ships something, add a dated entry at the top of `docs/SESSION_LOG.md`. Update `docs/THESIS_FEATURE_AUDIT.md` status when a spec item is finished.
- **Scoped invariants:** `.claude/rules/*.md` (auth and link codes, exercise authoring admin/web-only, worksheet import web-only). Read the matching file before editing those areas.
- **Deploys change the live site.** Confirm with the owner before `firebase deploy`, unless they have already said to go ahead in the current session.
- There is **no staging**: a local `flutter run` talks to the live database. Use the emulator (below) for anything that writes test data.

## Commands
```bash
flutter pub get
flutter run -d chrome                 # no CONTENT_OWNER_ID needed locally; talks to LIVE Firebase
flutter analyze                       # baseline: 0 errors, 0 warnings, ~35 infos
flutter test                          # 7/7 pass
node --check functions/index.js

# Firestore rules tests (needs Java 21: brew install openjdk@21)
export PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH"
npm --prefix rules-tests run test:emulator      # 18 pass, 1 skipped (emulator limitation)

# Full emulator suite (auth 9099, firestore 8080, functions 5001, storage 9199, UI 4000)
firebase emulators:start --project demo-chinese-tracker

# Hosting deploy: ALWAYS via the script. It builds web with the live config,
# copies the Android APK to /downloads/easy-study.apk (hosting deploys are
# full snapshots, a bare deploy would drop the APK) and deploys.
scripts/deploy_web.sh --web-only # until billing is enabled (free plan refuses .apk uploads)
scripts/deploy_web.sh            # web + APK, reuse last APK build (needs Blaze)
scripts/deploy_web.sh --apk      # rebuild the APK too (~6 min, needs JDK 21)
```
Android: `flutter config --jdk-dir=/opt/homebrew/opt/openjdk@21` is set on this Mac; the
release keystore is referenced by `android/key.properties` (never commit the keystore).
iOS: no native app; Xcode is incomplete on this Mac and there is no Apple Developer
account on record. Users add the web app to the home screen from Safari.

## Known blockers (update when resolved)
- Cloud Functions run on **Node 22** since 2026-11-05 (Node 20 was retired 2026-10-30); `functions/package.json` engines = 22, firebase-functions 7, firebase-admin 14.
- Billing was off 2026-10-13 → 2026-10-20. Owner upgraded to **Blaze on 2026-10-20**; all 9 functions and the APK were redeployed and work (owner re-test PUB-09 passed).
- **Nightly backup still fails** (`scheduledFirestoreExport`, 02:00 Jakarta): `PERMISSION_DENIED` again on 2026-10-22 with billing on, so it is an IAM problem. Fix in Google Cloud console (gcloud on this Mac is not signed in and reports a broken install): IAM → grant the functions' runtime service account `345172802163-compute@developer.gserviceaccount.com` the role **Cloud Datastore Import Export Admin**, and give it **Storage Object Admin** on bucket `gs://chinese-tracker-backups` (create the bucket in `asia-southeast2` if it doesn't exist). Then confirm in `firebase functions:log` after the next run.
- Test accounts on the live project: `admin@`, `teacher@`, `student1-3@test.chinesetracker`, password in `docs/CLAUDE_FULL_HANDOFF.md`. No test parent yet.

## Tools on the owner's Mac
- **Caveman** (`@caveman-ai/cli`, getcaveman.dev) is enabled for Claude Code since 2026-10-22: traffic goes through a local proxy (`ANTHROPIC_BASE_URL=http://127.0.0.1:8787/w/claude` in `~/.claude/settings.json`), plus hooks that add context notes to prompts. If Claude can't connect, the proxy isn't running: run `caveman status`, or undo with `caveman disable claude`.
- **Owner test checklist:** https://claude.ai/artifact/7U7WnXt1rKRArcDDvoiBEb (results in its db collection `results`, read with the Artifact tool `read_db`). PUB-01…09 checked; PUB-05 (Android) needs a re-test since the APK went live.
