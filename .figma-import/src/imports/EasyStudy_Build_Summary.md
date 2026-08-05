# Easy Study — Build Summary

**Chinese Tutoring LMS** for adult learners and solo tutors
易华文教中心 · Mandarin Education Center & China Education Consultant

| | |
|---|---|
| **Stack** | React + Tailwind CSS (Figma Make) |
| **Entry point** | `/src/app/App.tsx` |
| **Design handoff** | `/src/app/Handoff.tsx` (open via Teacher Profile → 📐 Design handoff) |
| **State** | Full UI shell complete with mock data — ready for backend wiring |
| **Version** | v1.2 · Jun 2026 |

---

## Design system

| Token | Hex | Usage |
|-------|-----|-------|
| Navy | `#1B2A4A` | App bars, headings, teacher primary buttons |
| Navy light | `#2A3F66` | Hover / secondary navy surfaces |
| Teal | `#2D6A7E` | Student accents, links, HSK badges, nav indicator |
| Teal light | `#3D8A9E` | Soft teal badges, hover |
| Surface | `#F5F6F8` | Page / scaffold background |
| Card | `#FFFFFF` | Cards, inputs, bottom nav |
| Text primary | `#1A1D26` | Body copy, titles |
| Text secondary | `#5C6370` | Subtitles, hints, captions |
| Border | `#E2E5EB` | Card borders, dividers, input outlines |
| Success | `#2E7D5A` | Correct answers, positive feedback |
| Error | `#B53A3A` | Errors, overdue alerts, destructive actions |
| Brand yellow | `#F5B800` | Logo pill / pencil body |

- **Typography:** Plus Jakarta Sans (Latin/UI) + Noto Sans SC (all Chinese content)
- **Cards:** 12px radius, 1px border, no drop shadow
- **Grid:** 8pt base · Sidebar 240px · Content max 960px · Mobile 390×844
- **Logo assets wired:** `Logo_ES.png` (auth), `Pensil.png` (sidebar + mobile app bar)

---

## Screens implemented (35+)

### Authentication
- **A1 — Test login** (dev role picker: Teacher / Student)
- **A2 — Login** (email, password, show/hide, forgot password, Google, error snackbar)
- **A3 — Register teacher** (role toggle, name, email, password)
- **A4 — Register student** (+ invite code, HSK dropdown, term size 8/16)
- **A5 — Complete profile** (first-login setup: avatar, name, role chip, HSK + term)

### Teacher tabs
- **Dashboard** — stat cards, weekly bar chart, "Needs attention" list, quick actions
- **Students** — searchable data table (name, HSK, progress, sessions, last active)
- **Exercises** — filter pills (All/Published/Draft), cards, assign + edit + delete
- **Classes** — upcoming / past sections, date pills, conclude action
- **Profile** — invite code, settings, UI states + design handoff links

### Teacher pushed screens
- **T1 — Student detail** — header, class term, lesson grid, practice results, Export PDF
- **T2 — Exercise form** — type picker, MC / compose / matching editors, coming-soon placeholders, worksheet upload card, assign sidebar
- **T3 — Class form** — title, date, time, duration pills, video link, student chips
- **T4 — Class detail** — info, Zoom link, students, conclude / delete

### Student tabs
- **Home** — greeting, live class banner, assigned practice, continue learning, term ring, avg score, Join class button
- **My Classes** — upcoming / past class cards
- **Lessons** — assigned practice + lesson list with quiz badges & lock states
- **Progress** — term ring, weekly quiz bars, quiz history, completed lessons, HSK level
- **Profile** — HSK badge, class term status, settings

### Student pushed screens
- **S1 — Exercise: Multiple choice** — progress bar, Chinese prompt, A–D, correct/incorrect states
- **S2 — Exercise: Compose sentences** — dashed answer zone, word bank chips (南方的 / 夏天 / 热极了)
- **S3 — Exercise: Matching** — two-column prompts + answers, tap-to-link
- **S4 — Exercise: Coming soon** — construction empty state (reading cloze / picture)
- **S5 — Lesson detail** — vocabulary cards (你好 / 谢谢 / 再见), Start quiz
- **S6 — Quiz** — MC flow with progress
- **S6b — Quiz score** — pass/fail header + per-question breakdown
- **S7 — Class detail (student)** — session info, teacher name, Zoom, Leave class

---

## Dialogs (8)

| ID | Dialog | Trigger |
|----|--------|---------|
| D1 | Assign exercise | Exercises tab — search, checkboxes, due date toggle |
| D2 | Worksheet import progress | Exercise form — 3-step modal (Prepare → Read → Detect) |
| D3 | Import review | Full-screen after D2 — detected type, editable OCR text, question preview, warning banner |
| D4 | Delete exercise | Exercise card overflow menu |
| D5 | Conclude class | Class detail — confirm + student list |
| D6 | Add class term | Student detail "Add term" — 8/16 toggle, date range |
| D7 | Join class | Student Home — session code + class preview |
| D8 | Leave class | Student class detail — destructive confirm |

---

## UI states

- **Empty states (8):** No students, no exercises, no active classes, no class history, no classes joined, no content, no progress, exercise coming soon
- **Loading (4):** full-screen spinner, skeleton cards, button spinner, worksheet import step
- **Error (3):** snackbar, inline field error, import failure card
- Accessible via **Teacher Profile → 🧪 UI States reference**

---

## Responsive layout

| Breakpoint | Layout |
|-----------|--------|
| ≥ 900px | Desktop — 240px navy sidebar + white top bar + surface content |
| < 900px | Mobile — navy app bar (logo + title + bell) + 5-tab bottom nav + FAB on Exercises/Classes |

Navigation uses a **push/pop screen stack** for pushed screens; back bar returns to the active tab.

---

## Exercise types

| # | Type | Chinese | Status |
|---|------|---------|--------|
| 1 | Multiple choice | 选择题 | ✅ Live (teacher editor + student player) |
| 2 | Compose sentences | 组词成句 | ✅ Live |
| 3 | Matching | 对话配对 | ✅ Live |
| 4 | Reading cloze | 选词填空 | ⚠️ Import-only (detected, editor coming soon) |
| 5 | Picture + keyword | 图文造句 | ⚠️ Import-only |

---

## Design handoff page

`/src/app/Handoff.tsx` — a live, navigable spec with 9 sections: Brand, Colors, Typography, Spacing, Components, Layout, Screen inventory, Exercise types, Chinese rendering. Each component is rendered with copy-to-clipboard hex values and pixel spec tags.

---

## Backend integration — what's ready to wire

All data shapes and interactions are mocked and documented. Suggested endpoints:

| Data | Endpoint |
|------|----------|
| Students list | `GET /api/teacher/students` |
| Exercises | `GET /api/teacher/exercises` |
| Classes | `GET /api/teacher/classes` |
| Weekly activity | `GET /api/teacher/activity?range=week` |
| Student progress | `GET /api/student/progress` |

**Mutations needed:** conclude class, delete class, publish/assign exercise, copy invite code, join/leave class, start/continue exercise, submit quiz, complete lesson, worksheet import + OCR.

**Auth context needed:** replace the local `role` toggle with a real session providing `role`, `userName`, `initials`, `hskLevel` (students), `inviteCode` (teachers).

---

*Generated from `App.tsx` · Figma Make file `8LDbnO1nfJCZX74gGssbRB` · Flutter repo `chinese-tracker`*
