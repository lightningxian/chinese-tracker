# Easy Study (`chinese-tracker`) — Claude project guide

Flutter web + Firebase LMS for a Chinese teaching centre (易华文教中心).
Roles: admin · teacher · student · parent. Live at https://chinese-tracker.web.app.
Claude owns this project as of 2026-10-16 (handed over from Cursor).

## Read first
1. `docs/CLAUDE_FULL_HANDOFF.md`: status, live config, what's done, P0–P3 backlog, architecture map.
2. `docs/CURSOR_CHAT_HISTORY.md`: conversation context and decisions the user made.
3. `docs/RECOMMENDATIONS_FOR_CURSOR.md` (the backlog) and the top of `docs/CURSOR_CHANGES_FOR_CLAUDE.md`.

## Never
- Create a new GitHub repo or Firebase project, or re-run `flutterfire configure`.
  `lib/firebase_options.dart` already points at the live `chinese-tracker` project.
- Commit the Midtrans **server** key. It lives in Firebase Secret Manager as `MIDTRANS_SERVER_KEY`.
- Switch Midtrans to production keys before the sandbox payment E2E test passes.
- Rewrite old commits (the first commit's author name is wrong, and that's accepted).

## Conventions (carried over from `.cursor/rules/`)
- **Commit author:** set `GIT_AUTHOR_NAME="Wilsin Kuonadi"` `GIT_AUTHOR_EMAIL=wilsinkarimunwkk@gmail.com`
  (and matching `GIT_COMMITTER_*`) per commit. Don't change global git config.
- **Push notes:** each commit body has a 2–6 bullet plain-language summary of the change. For
  milestones, also publish it on GitHub (`gh release create` or the PR body).
- **Change log:** after any code, rules, functions or config change, add an entry at the **top** of
  `docs/CURSOR_CHANGES_FOR_CLAUDE.md` (What changed / Why / For review).
- **After shipping:** update the backlog checkmarks in `RECOMMENDATIONS_FOR_CURSOR.md`, the
  "already done" section of `CLAUDE_FULL_HANDOFF.md`, and the session log in `docs/CURSOR_HANDOFF.md`
  (the user still uses Cursor on PC sometimes).
- **Scoped invariants:** before editing auth, link codes, exercises or worksheet import, read the
  matching `.cursor/rules/*.mdc` file. Exercise authoring and worksheet import are admin-only on web.

## Commands
```bash
flutter pub get
flutter run -d chrome            # no CONTENT_OWNER_ID needed locally
flutter analyze                  # baseline 2026-10-16: 0 errors, 1 warning, 48 infos
flutter test                     # baseline 2026-10-16: 7/7 pass
node --check functions/index.js

# Hosting deploy (sandbox config)
flutter build web --release \
  --dart-define=CONTENT_OWNER_ID=2orTXFeyAhSlxfTgIlcYgs6ZuCG2 \
  --dart-define=MIDTRANS_CLIENT_KEY=Mid-client-kQ_Bo0DQepeH8IhU
firebase deploy --only hosting
```
Deploys hit the **live** site, so confirm with the user before running `firebase deploy`.
