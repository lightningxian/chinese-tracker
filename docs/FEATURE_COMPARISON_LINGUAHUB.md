# Feature comparison — LinguaHub prototype vs Easy Study

Source reviewed: https://film-haven-39247069.figma.site/ (LinguaHub — a general
"platform for language course institutions"). Explored live across all four
roles. This maps what LinguaHub has against what Easy Study already does, and
lists candidate features to add, prioritized for a Chinese-teaching business
(易华文教中心, Rupiah, easystudy.id).

---

## What LinguaHub is

A multi-role institution platform with **four** roles (Easy Study has three):

| LinguaHub role | Closest Easy Study role |
|----------------|--------------------------|
| **Owner** (institution owner) | — (no equivalent; sits above Admin) |
| Admin | Admin |
| Teacher | Guru |
| **Student / Parent** (combined account) | Murid (student only) |

### Owner (new tier)
Institution-wide dashboard: revenue this month/semester, active students,
active classes, revenue chart (6 mo), outstanding payments (paid/pending/
overdue), student growth, **teacher performance ratings**, operational alerts
(overdue invoices, low attendance, low class occupancy, evaluation forms open).
Nav: Dashboard · Reports · Users · Classes · Schedule Calendar · Payments ·
Materials · Settings · Audit Logs.

### Admin
Users (Admins / Teachers / Students-Parents) with **granular permissions**
("Full access" vs "Payments only"), plus the operational modules.

### Teacher
Dashboard (classes today, attendance to input, grades pending, evaluations to
write). Nav: My Schedule · My Classes · Materials · **Question Bank** ·
**Quizzes** · Attendance · **Grades** · **Student Evaluations**.

### Student / Parent
Combined parent+student account. Dashboard: remaining quota (3/8), next class,
outstanding bill, latest score (letter grade). Nav: My Classes · **Assignments**
· **Calendar** · **Payments** · **Quota** (buy more sessions) · Attendance ·
**Grades** · **Evaluations** · Profile.

---

## Gap analysis

### Easy Study already has (overlap — no work needed)
- Roles, auth, class sessions + attendance, live-class join.
- **Session packages / quota** → your `student_class_terms` (sessions remaining,
  deadline) is LinguaHub's "Quota / session pack."
- Vouchers with auto codes; teacher link codes.
- Lessons, quizzes, exercises (MC, compose, matching, listening), progress.
- Notifications; some reports (admin platform, cohort, student progress PDF).
- Worksheet OCR import.

### In LinguaHub but NOT in Easy Study (candidate adds)
1. **Payments & invoicing with a gateway (Midtrans).** Invoices with status
   paid/pending/overdue/expired, "collected this month," payment report,
   webhook-driven status. Easy Study tracks quota but never collects money.
2. **Owner tier + financial dashboard** (revenue, outstanding, growth).
3. **Parent access** — a parent linked to a student, seeing progress, bills,
   attendance.
4. **Schedule Calendar** (Month / Week / Day) — you have sessions but no calendar.
5. **Student / semester Evaluations** + **teacher performance ratings**.
6. **Question Bank** — reusable question pool separate from a specific quiz.
7. **Materials repository** — shared files with status (draft/published), tags,
   author; distinct from structured lessons.
8. **Granular admin permissions** (scoped roles, e.g. payments-only admin).
9. **Audit logs** — record of important actions + system/webhook events.
10. **Settings page** — org toggles (email verification, auto staff passwords,
    enable payments, allow teacher self-reschedule, open evaluation forms).
11. **Reports tabs** (Revenue / Teacher / Student performance) + Export.
12. **Class metadata** — delivery mode (Offline/Online/Hybrid), room, capacity/
    occupancy; open-for-registration vs draft vs active states.
13. **Gradebook** — grades as first-class records (scores + letter grades),
    "grades pending" for teachers.
14. **Self-service top-up** — student/parent "Buy more sessions."

---

## Recommended to add — prioritized

Ranked by value-for-effort for your business.

### Tier 1 — highest value
- **Payments + Midtrans invoicing.** You're already Rupiah/Indonesia and have
  session packages; adding Midtrans turns quota into real revenue with
  paid/pending/overdue tracking and webhook updates. Biggest single upgrade.
- **Parent access.** Parents paying for kids want visibility (progress,
  attendance, bills). Low-to-medium effort: a `parent` role or a parent link on
  the student profile; reuse existing student screens read-only.
- **Schedule Calendar (week view).** You already store sessions — this is mostly
  a new view over existing data. High perceived polish, low data work.

### Tier 2 — strong, medium effort
- **Gradebook + "grades pending."** Formalize quiz/exercise scores into a grades
  record with optional letter grade; gives teachers a to-do and students a
  transcript.
- **Question Bank.** Reusable questions your exercises/quizzes draw from —
  reduces re-authoring; complements your existing worksheet import.
- **Class metadata** (mode/room/capacity/occupancy + registration state) — small
  schema additions that unlock the calendar and "open for registration."

### Tier 3 — nice, do later
- **Owner financial dashboard** (only if you add payments and have >1 teacher).
- **Student/semester evaluations** + teacher ratings.
- **Materials repository** (if you want shared files beyond structured lessons).
- **Audit logs**, **granular admin permissions**, **org settings page** —
  operational maturity, matter most as staff/teacher count grows.

### Probably skip (unless you scale to a multi-teacher institution)
- Full **Owner tier** as a separate role — your current Admin likely covers it
  for a single centre.
- Teacher performance ratings across many teachers.

---

## Notes on fit
Easy Study is HSK/Chinese-specific; LinguaHub is a generic multi-teacher
institution. Several LinguaHub features assume scale (Owner, teacher ratings,
audit logs, granular permissions). For a single Chinese centre, the clear wins
are **payments (Midtrans), parent access, calendar, and a gradebook** — the rest
is optional maturity you can add as you grow.
