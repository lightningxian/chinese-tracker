# Recommendations for Cursor

Running list of what to do next, newest priorities first. Claude maintains this;
Cursor should work top-down and note anything done/deviated in
`docs/CURSOR_CHANGES_FOR_CLAUDE.md`.

## 1. ~~Deploy the pending changes~~ ✅ Done 2026-07-22

Functions, hosting, and storage rules deployed. Payment-integrity fixes +
question-bank `question_bank_media` storage path are live.

**Next verify manually:** sandbox payment test (invoice → pay → paid → sessions
credited → replay = no double-credit).

## 2. Verify
- `flutter analyze` — ✅ clean (0 errors, 2026-07-22).
- After the font bump, eyeball tight fixed-height rows (tables, chips, stat cards)
  for overflow at ~360px width; nudge any that clip (most already use ellipsis).
- ~~Run the **sandbox payment test**~~ — **deferred** (do after landing page ships).

## 3. Queued build prompts (when ready)
- ~~**Landing page**~~ — ✅ Done 2026-07-22 (`docs/landing_mockup.html` + Unsplash
  photos + YouTube embed showcase). Orang Tua role card included.
- ~~**Question bank upgrade**~~ — ✅ Done 2026-07-22
  (`docs/CURSOR_QUESTION_BANK_UPGRADE_PROMPT.md`). Quiz authoring built.

## 4. Low-priority hardening / cleanup (from Claude's debug pass)
- **Student teacherId at registration** is client-set (link-code check is only
  client-side). For hardening, move student registration through a callable that
  validates the code server-side, like `linkChild` does for parents.
- **Cross-owner reads**: any signed-in user can read any *published* material, and
  teachers can read any student profile. Fine for one centre — scope by owner if
  you add more teachers.
- **Storage `materials/{ownerId}` write** isn't uid-scoped (any staff can write
  under any ownerId path). Tighten to `request.auth.uid == ownerId || isAdmin()`.
- **Enforce the stored settings** that are currently display-only:
  `requireEmailVerification`, `autoGenerateStaffPasswords`.
- **Consolidate content-owner helpers** — `contentTeacherId` and `contentOwnerFor`
  coexist and can drift; converge on one.

## 5. Testing / CI (recommended before real users)
- Firestore **rules tests** (`@firebase/rules-unit-testing`): student can't read
  others' data or self-link as a parent or mark invoices paid; parent reads only
  linked children.
- **Webhook unit test** (status mapping + no double-credit).
- **GitHub Action**: `flutter analyze` + `flutter test` + `node --check` on push.
