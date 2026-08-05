# Screen Inventory — Easy Study

> **Product name:** Easy Study · Design spec: [FIGMA_AI_SPEC.md](../design/FIGMA_AI_SPEC.md)

Complete list of screens, tabs, routes, and major dialogs in the app.

**Project path:** `~/Projects/chinese-tracker`  
**Router:** `lib/core/router/app_router.dart`  
**Last updated:** July 2026

---

## Route map

```
/                               → Landing page
/login                          → Email/password login (+ saved accounts)
/register                       → Teacher or student registration
/dev-login                      → Dev one-tap test accounts
/complete-profile               → First-time profile setup (legacy / OAuth)
/admin                          → Admin shell (7 tabs)
  /admin/users/new              → Create user (Murid or Guru)
  /admin/users/:id/edit         → Edit user profile
  /admin/vouchers/new           → Create voucher package
  /admin/vouchers/:id/edit      → Edit voucher package
  /admin/exercise/new           → New exercise (admin, web only)
  /admin/exercise/:id/edit      → Edit exercise (admin, web only)
  /admin/session/new            → New class session
/teacher                        → Teacher shell (5 tabs)
  /teacher/student/:id          → Student detail + export progress PDF
  /teacher/exercise/new         → Redirects non-admins (authoring is admin-only)
  /teacher/exercise/:id/edit    → Redirects non-admins
  /teacher/session/new          → New class session
  /teacher/session/:id/edit     → Edit class session
  /teacher/session/:id          → Class session detail
/student                        → Student shell (5 tabs)
  /student/class/:sessionId     → Class detail (student)
  /student/exercise/:id         → Do assigned exercise
  /student/lesson/:id           → Lesson content
  /student/quiz/:lessonId       → Lesson quiz
```

---

## Roles & responsibilities

| Role | Route | Shell tabs | Key privileges |
|------|-------|------------|----------------|
| **Admin** | `/admin` | Dashboard, Users, Exercises, Classes, Vouchers, Reports, Account | Create/edit exercises (web), manage users, vouchers, platform reports |
| **Guru (teacher)** | `/teacher` | Home, Students, Exercises, Classes, Profile | View exercises (read-only), assign practice, run classes, export student PDFs |
| **Murid (student)** | `/student` | Home, My classes, Lessons, Progress, Profile | Join classes, do lessons/quizzes, complete assigned practice |

Exercise **creation and editing** is **admin-only on web**. Teachers browse published exercises and assign them to students.

---

## Auth

| Screen | Route | File | Role | Purpose |
|--------|-------|------|------|---------|
| **Landing** | `/` | `lib/features/landing/landing_screen.dart` | Public | Marketing page, sign in / register CTAs |
| **Login** | `/login` | `lib/features/auth/login_screen.dart` | All | Email/password login + saved accounts |
| **Register** | `/register` | `lib/features/auth/register_screen.dart` | All | Teacher or student registration; students need a **teacher link code** |
| **Test login** | `/dev-login` | `lib/features/auth/test_login_screen.dart` | Dev | One-tap sign-in as test accounts |
| **Complete profile** | `/complete-profile` | `lib/features/auth/complete_profile_screen.dart` | All | First sign-in profile setup with link code |

---

## Admin

### Shell tabs (`/admin`)

Bottom nav in `lib/features/admin/admin_shell.dart`.

| Tab | Label | File | Purpose |
|-----|-------|------|---------|
| 0 | **Dashboard** | `lib/features/admin/admin_dashboard_tab.dart` | Centre stats, weekly activity, needs attention |
| 1 | **Users** | `lib/features/admin/admin_users_tab.dart` | All users, activate/deactivate, create/edit |
| 2 | **Exercises** | `lib/features/teacher/teacher_exercises_tab.dart` | Create, edit, publish, delete, assign (shared tab) |
| 3 | **Classes** | `lib/features/teacher/teacher_attendance_tab.dart` | Live class sessions (shared tab) |
| 4 | **Vouchers** | `lib/features/admin/admin_vouchers_tab.dart` | Class term packages across all students |
| 5 | **Reports** | `lib/features/admin/admin_reports_tab.dart` | Platform PDF exports (users, cohort, worksheets) |
| 6 | **Account** | `lib/features/admin/admin_profile_tab.dart` | Admin profile, sign out |

### Pushed screens

| Screen | Route | File | Purpose |
|--------|-------|------|---------|
| **Create user** | `/admin/users/new` | `lib/features/admin/admin_create_user_screen.dart` | Admin creates Murid or Guru account |
| **Edit user** | `/admin/users/:id/edit` | `lib/features/admin/admin_edit_user_screen.dart` | Edit name, phone, HSK level, term size |
| **Voucher form** | `/admin/vouchers/new`, `.../edit` | `lib/features/admin/admin_voucher_form_screen.dart` | Create/edit 8- or 16-session package |
| **Exercise form** | `/admin/exercise/new`, `.../edit` | `lib/features/teacher/teacher_exercise_form_screen.dart` | Create/edit exercise + worksheet upload |
| **Class form** | `/admin/session/new` | `lib/features/teacher/teacher_session_form_screen.dart` | Create live class session |

---

## Teacher

### Shell tabs (`/teacher`)

Bottom nav in `lib/features/teacher/teacher_shell.dart`.

| Tab | Label | File | Purpose |
|-----|-------|------|---------|
| 0 | **Home** | `lib/features/teacher/teacher_dashboard_tab.dart` | Stats, weekly activity, **Needs attention** |
| 1 | **Students** | `lib/features/teacher/teacher_students_tab.dart` | Searchable student list → student detail |
| 2 | **Exercises** | `lib/features/teacher/teacher_exercises_tab.dart` | **View only** — browse, filter, assign; no create/edit/delete |
| 3 | **Classes** | `lib/features/teacher/teacher_attendance_tab.dart` | Live sessions; FAB **New class** |
| 4 | **Profile** | `lib/features/teacher/teacher_profile_tab.dart` | Rotating **link code** (6 chars, 15 min), copy button, sign out |

### Pushed screens

| Screen | Route | File | Purpose |
|--------|-------|------|---------|
| **Student detail** | `/teacher/student/:id` | `lib/features/teacher/student_detail_screen.dart` | Profile, class terms, lesson progress, practice results, **export progress PDF** |
| **Class form** | `/teacher/session/new`, `.../edit` | `lib/features/teacher/teacher_session_form_screen.dart` | Create/edit live class |
| **Class detail** | `/teacher/session/:id` | `lib/features/teacher/teacher_session_detail_screen.dart` | Session info, joined students, conclude |

### Teacher dialogs & sheets

| UI | File | When shown |
|----|------|------------|
| Assign exercise | `teacher_exercises_tab.dart` | Pick students (with search), optional due date |
| Delete class | `teacher_session_detail_screen.dart` | Confirm before deleting session |
| Conclude class | `teacher_attendance_tab.dart` | Confirm attendance credit |
| Student picker | `teacher_attendance_tab.dart` | Add students to a class |
| Add class term | `lib/core/widgets/class_term_widgets.dart` | Add 8- or 16-session package on student profile |

---

## Student

### Shell tabs (`/student`)

Bottom nav in `lib/features/student/student_shell.dart`.

| Tab | Label | File | Purpose |
|-----|-------|------|---------|
| 0 | **Home** | `lib/features/student/student_home_tab.dart` | Greeting, join live class, assigned practice |
| 1 | **My classes** | `lib/features/student/student_my_classes_tab.dart` | Upcoming and past joined sessions |
| 2 | **Lessons** | `lib/features/student/student_lessons_tab.dart` | Assigned exercises + lessons by term |
| 3 | **Progress** | `lib/features/student/student_progress_tab.dart` | Term progress, quiz averages |
| 4 | **Profile** | `lib/features/student/student_profile_tab.dart` | HSK level, class term status, sign out |

### Pushed screens

| Screen | Route | File | Purpose |
|--------|-------|------|---------|
| **Exercise** | `/student/exercise/:id` | `lib/features/student/exercise_screen.dart` | MC, compose, matching |
| **Lesson detail** | `/student/lesson/:id` | `lib/features/student/lesson_detail_screen.dart` | Read lesson, start quiz |
| **Quiz** | `/student/quiz/:lessonId` | `lib/features/student/quiz_screen.dart` | Lesson quiz |
| **Class detail** | `/student/class/:sessionId` | `lib/features/student/student_class_detail_screen.dart` | Session info, leave class |

---

## Exercise types (student exercise screen)

| Type | UI on `exercise_screen.dart` |
|------|------------------------------|
| Multiple choice | Select A–D per question |
| Compose sentences (组词成句) | Reorder word segments |
| Matching | Match numbered prompts to answer bank A–F |
| Reading cloze | “Coming soon” placeholder |
| Picture + keyword | “Coming soon” placeholder |

---

## Screen count summary

| Category | Count |
|----------|-------|
| Routed full screens | 20+ |
| Shell tabs (admin) | 7 |
| Shell tabs (teacher) | 5 |
| Shell tabs (student) | 5 |
| Major dialogs | 12+ |

---

## Related docs

- [FIGMA_AI_SPEC.md](../design/FIGMA_AI_SPEC.md) — colors, typography, empty states
- [APP_OVERVIEW.md](../APP_OVERVIEW.md) — product overview
- [WORKSHEET_IMPORT.md](../WORKSHEET_IMPORT.md) — worksheet upload (admin, web only)
- [FIREBASE_BACKEND.md](../FIREBASE_BACKEND.md) — Firestore collections & security
- [SETUP.md](../SETUP.md) — run the app locally
