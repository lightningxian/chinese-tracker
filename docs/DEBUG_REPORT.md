# Full debug report — Easy Study (chinese-tracker)

Date: 2026-07-14. Static review (no `flutter analyze` available in this
environment — see item O-1). Severity: 🔴 high · 🟠 medium · 🟡 low.

Two sections: **Fixed** (already changed in the repo) and **Open for Cursor**
(needs a device build, a decision, or compile/test to close). Recommendations
for new work are at the end.

---

## ✅ Fixed in this pass

| # | Area | What was wrong | Fix |
|---|------|----------------|-----|
| F-1 | `lib/services/auth_service.dart` | `register()` created the Firebase Auth user *before* validating the link code → orphaned account on a bad code | Resolve link code first |
| F-2 | `lib/features/auth/register_screen.dart` + `functions/index.js` | Student self-registration wrote notifications client-side, which rules block → false "registration failed" | Server-side `onUserCreated` trigger; client write removed |
| F-3 | `functions/index.js` | Link-code resolution read Firestore directly (needed the collection world-readable) | `resolveLinkCode` callable; `teacher_link_codes` read locked down |
| F-4 | `firestore.rules` | `student_progress` update didn't check existing owner | Ownership check on update |
| F-5 | `lib/firebase_options.dart` | Android/iOS were placeholder keys → app dies on launch on device | Real values from native config; iOS bundle + bucket fixed |
| F-6 | `android/app/build.gradle.kts` | `minSdk` could resolve below Firebase's required 23 | `minSdk = maxOf(flutter.minSdkVersion, 23)` |
| F-7 | `android/.../AndroidManifest.xml` | No `INTERNET` permission in release manifest; label was `chinese_tracker` | Added permission + `https` query; label `Easy Study` |
| F-8 | `web/index.html` | PWA title `chinese_tracker`, missing `apple-mobile-web-app-capable` | Fixed iOS/PWA meta |
| **F-9** | `firestore.indexes.json` | **Missing composite index** `lessons (teacherId ASC, order ASC)`. `watchLessons()` uses `where(teacherId) + orderBy(order)`; with `CONTENT_OWNER_ID` set (production) every lessons list — student Lessons/Home/Progress, teacher & admin dashboards, reports — fails with "query requires an index" | Added the index |
| **F-10** | `functions/index.js` + `lib/features/student/exercise_screen.dart` | Student exercise submit called `notifyGrading` → students can't write notifications → the submit `await` throws *after* saving the score, leaving the UI stuck in "submitting" | Added `onExerciseResultCreated` trigger; removed the client write |
| **F-11** | teacher tabs (`teacher_dashboard_tab`, `teacher_students_tab`, `teacher_dashboard_stat_detail_screen`) | **Demo student/teacher saw different content.** Students resolve lessons by `teacherId` (their teacher's uid), but teacher views resolved lessons by the global `CONTENT_OWNER_ID` dart-define. They only match if `CONTENT_OWNER_ID` == the demo teacher's uid — and the relaunch rule hardcodes a *different* uid, so the teacher saw no/empty lessons while the student saw them | Teacher views now resolve lessons by the teacher's own content id (`contentTeacherId`), matching students |

### About the demo content-ownership issue (F-11)

Root cause: content ownership was read from **two sources** that only line up when
`--dart-define=CONTENT_OWNER_ID` is set to the seeded demo teacher's uid:

- Students → `AppConstants.lessonsOwnerId(user)` = the student's `teacherId`.
- Teacher/admin lesson views → `AppConstants.contentOwnerId` (the dart-define).

`CLAUDE.md` launches with
`CONTENT_OWNER_ID=2orTXFeyAhSlxfTgIlcYgs6ZuCG2`, which is not the freshly-seeded
`teacher@test.chinesetracker` uid, so the teacher demo saw the wrong owner's
lessons. After F-11 the teacher demo no longer needs that dart-define.

**Still to do (Cursor):**
- **Admin demo** still uses `AppConstants.contentOwnerId` for lessons
  (`admin_centre_metrics_section.dart`). For the admin demo to show lesson stats,
  either set `CONTENT_OWNER_ID` to the demo teacher's uid or point admin at a
  chosen teacher. Decide the intended model (single central library vs
  per-teacher) and make admin consistent.
- **Seed content before demoing.** Run `scripts/seed_test_accounts.sh` **and**
  `python3 scripts/seed_report_demo_data.py` — the latter seeds lessons/exercises
  under the demo teacher. Without it, teacher and student both correctly show
  "no lessons yet."
- Consider dropping the hardcoded uid from the relaunch rule now that
  teacher/student demos are dart-define-independent.

> After F-9 you must deploy indexes; after F-2/F-3/F-10 you must deploy
> functions. See "Deploy checklist".

---

## 🔧 Open for Cursor

### O-1…O-6 ✅ Closed in code (2026-07-14)
`flutter analyze` passes (warnings/infos only, no errors). Landing → `/login`;
`/dev-login` gated with `kDebugMode`. Auth splash/`isInitializing` (O-4).
`watchTeacherSessions` + scoped `class_sessions` rules (O-3). Dead notify
helpers removed (O-5). Voucher form uses `int.tryParse` (O-6).

**Deploy status:** `firestore:rules` + `firestore:indexes` deployed.
Functions blocked — project must be on the **Blaze** plan
(https://console.firebase.google.com/project/chinese-tracker/usage/details).

### O-7 🟡 Confirm the parallel Cursor edits didn't reintroduce anything
Re-run the register/link-code flow and the notification flows once in the
running app to be sure F-1…F-4 are still intact.

### Follow-ups added 2026-07-16
- Notification tap-through wired in admin/teacher/student shells (marks read +
  switches to the relevant tab).
- Global `FlutterError` / zone error logging in `lib/main.dart`.
- `cleanupExpiredLinkCodes` scheduled function added in `functions/index.js`
  (deploys with the rest of functions once Blaze is enabled).
- Cloud Functions still blocked on **Blaze** — upgrade at
  https://console.firebase.google.com/project/chinese-tracker/usage/details
  then `firebase deploy --only functions`.

---

## 🚀 Deploy checklist (after O-1 passes)

```bash
# Firestore indexes (F-9) + rules (F-3, F-4)
firebase deploy --only firestore:rules,firestore:indexes
# Cloud Functions (F-2, F-3, F-10) — requires Blaze plan
firebase deploy --only functions
```
Index builds take a few minutes; lessons/among others stay empty until the
`lessons` index finishes building.

---

## 💡 Recommendations to add (after bugs are closed)

1. **Automated tests + CI.** Coverage is three files and one is a stub. Add unit
   tests for `AuthService.register` ordering, `TeacherLinkCodeService`, and the
   Firestore rules (use `@firebase/rules-unit-testing` in the emulator). Wire a
   GitHub Action running `flutter analyze` + `flutter test` on push.
2. **Firebase Emulator Suite** for local dev — lets you test rules, functions,
   and the two new triggers without touching prod data.
3. **Scheduled cleanup of expired `teacher_link_codes`.** They're only deleted on
   rotation; add a scheduled function to purge expired docs.
4. **Crash/analytics reporting.** Add Firebase Crashlytics (mobile) and a global
   `FlutterError.onError` + zone guard so silent async failures (like the old
   grading bug) surface.
5. **Notification tap-through.** `AppNotification.targetRoute` exists but isn't
   wired — make notifications navigate to the relevant screen.
6. **Offline/empty/error states.** Standardize loading, empty, and error widgets
   for all `StreamBuilder`s (several show a bare spinner).
7. **App icons & splash.** Use `flutter_launcher_icons` + `flutter_native_splash`
   so Android/iOS/PWA share the Easy Study brand.
8. **Rate-limit `resolveLinkCode`.** It's callable pre-auth; add basic abuse
   protection (App Check, or a per-IP attempt cap) so codes can't be brute-forced.
9. **Release signing hygiene.** Keep the keystore + `key.properties` out of git
   (already noted in the build prompt) and document where they live.
```
