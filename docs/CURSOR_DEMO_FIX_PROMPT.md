# Cursor prompt — demo (student/teacher) content-ownership + follow-ups

Copy the block below into Cursor and run it on the Mac with Flutter + Firebase CLI.
Full context is in `docs/DEBUG_REPORT.md` (see F-11).

---

## Already done (verify, don't redo)

The teacher content-ownership bug was fixed: `teacher_dashboard_tab.dart`,
`teacher_students_tab.dart`, and `teacher_dashboard_stat_detail_screen.dart` now
resolve lessons by the teacher's own content id (`AppConstants.contentTeacherId`)
instead of the global `CONTENT_OWNER_ID` — matching how students resolve via
`teacherId`. `teacher_students_tab.dart` gained an `AuthService` import.

## Tasks

### 1. Confirm it compiles and runs
```bash
flutter pub get
flutter analyze
```
Fix any errors (I edited these files without a compiler, and other edits happened
in parallel). Then run the app:
```bash
flutter run -d chrome
```

### 2. Prove the demo works end to end
1. Seed accounts **and** content:
   ```bash
   bash scripts/seed_test_accounts.sh
   python3 scripts/seed_report_demo_data.py
   ```
2. Log in as **Guru** (`teacher@test.chinesetracker`) and as **Murid**
   (`student1@test.chinesetracker`). Confirm **both see the same lessons and
   exercises**, with no dependency on `--dart-define=CONTENT_OWNER_ID`.
3. If either side is empty, check that the seeded lessons' `teacherId` equals the
   demo teacher's uid and the student's `teacherId` equals the same uid.

### 3. Make admin content-ownership consistent (decision needed)
`admin_centre_metrics_section.dart` still reads lessons from
`AppConstants.contentOwnerId`. Pick the intended model and implement it:
- **Per-teacher content** (matches students + the F-11 fix): admin views a
  selected teacher's content, or aggregates per teacher. Preferred for consistency.
- **Single central library**: then students should ALSO read from `contentOwnerId`
  (not `teacherId`) — change `AppConstants.lessonsOwnerId` accordingly and require
  `CONTENT_OWNER_ID` in all builds.
State which you chose in a comment.

### 4. Single source of truth for content ownership
Content ownership is currently resolved in two places that can drift
(`AppConstants.lessonsOwnerId` for students vs `AppConstants.contentOwnerId` for
staff) — that drift caused F-11. Add one resolver, e.g.
`AppConstants.contentOwnerFor(AppUser user)`, and use it in every lessons/exercises
query (student, teacher, admin). Remove the ad-hoc `contentOwnerId` locals.

### 5. Round out the demo (optional but recommended)
- Seed a **teacher link code** and one **open class session** so the
  register-with-code and "join live class" flows are demoable, not just lessons.
- Add a "no demo data yet — run the seed script" empty state on the teacher and
  student dashboards instead of a blank list.
- Now that teacher/student demos don't need it, drop the hardcoded
  `CONTENT_OWNER_ID=2orTXFeyAhSlxfTgIlcYgs6ZuCG2` from
  `.cursor/rules/relaunch-after-changes.mdc` (or set it to the seeded teacher uid).

### 6. Deploy (after analyze passes)
```bash
firebase deploy --only firestore:rules,firestore:indexes
firebase deploy --only functions   # requires Blaze plan
```
The new `lessons (teacherId, order)` index must finish building or lesson lists
stay empty.

## Acceptance
- `flutter analyze` clean.
- After seeding, Guru and Murid demos show the same lessons/exercises with no
  `CONTENT_OWNER_ID` flag.
- Admin lesson stats resolve per the model chosen in task 3.
- One content-owner resolver is used everywhere.
