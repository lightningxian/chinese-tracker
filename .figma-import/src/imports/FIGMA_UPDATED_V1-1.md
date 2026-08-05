# Figma Updated V.1 — Status & remaining work

Living brief for the **Easy Study** Figma Make file and Flutter app alignment.

| | |
|---|---|
| **Figma Make file** | [Follow-MD-file-instructions](https://figma.com/make/8LDbnO1nfJCZX74gGssbRB/Follow-MD-file-instructions) |
| **File key** | `8LDbnO1nfJCZX74gGssbRB` |
| **Flutter repo** | `~/Projects/chinese-tracker` |
| **Related docs** | [FIGMA_AI_SPEC.md](FIGMA_AI_SPEC.md) · [SCREEN_INVENTORY.md](../screen-inventory/SCREEN_INVENTORY.md) |

---

## V.1 goal

One design source that a developer can implement screen-by-screen without guessing:

- Every **routed screen** in the app
- All **dialogs** and **UI states**
- **Web desktop** (1440×900) and **mobile** (390×844) frames
- Real **Easy Study** branding (not placeholder emoji)

---

## Coverage summary (audit V.1.2 — Jun 23, 2026)

Re-checked live Make source (`App.tsx`, `fonts.css`) via Figma MCP after your latest Figma pass.

| Area | Web desktop (Make) | Mobile frames | Flutter app |
|------|-------------------|---------------|-------------|
| Desktop shell (sidebar + top bar) | ✅ Done | — | ✅ Done (≥900px) |
| Mobile shell (app bar + bottom nav) | ❌ Missing | ❌ Missing | ✅ Done (<900px) |
| Auth — test login | ✅ Done | ❌ Missing | ✅ Done |
| Auth — login / register | ✅ Done | ❌ Missing | ❌ Not wired |
| Auth — complete profile | ❌ Missing | ❌ Missing | ✅ Exists (route) |
| Teacher tabs (5) | ✅ Done | ❌ Missing | ✅ Done |
| Student tabs (5) | ✅ Done | ❌ Missing | ✅ Done |
| Teacher pushed (4 screens) | ✅ Done | ❌ Missing | ⚠️ Partial / old UI |
| Student pushed (7 screens) | ⚠️ S7 wrong screen | ❌ Missing | ⚠️ Partial / old UI |
| Dialogs (8) | ⚠️ 3 of 8 | ❌ Missing | ⚠️ Partial |
| States reference sheet | ❌ Missing | ❌ Missing | ✅ Inline only |
| Design system / logo | ⚠️ Emoji, not PNG | — | ⚠️ Assets in repo |
| Noto Sans SC font | ✅ In `fonts.css` | — | ❌ Not in Flutter theme |
| Docs in Make source | ⚠️ Old V.1 MD copy | — | ✅ V.1.1 in repo |

**Legend:** ✅ Done · ⚠️ Partial · ❌ Not started

**V.1.2 verdict:** Desktop web prototype is still strong, but the **3 recommended P1 tasks were not implemented yet** in `App.tsx`. Paste the prompts in § “Copy-paste prompts for Figma Make” below.

---

## What’s done in Figma Make (V.1.1)

The clickable prototype (`App.tsx`) now includes:

### Auth
- Test login + Sign in tabs on black background
- Register teacher / register student (role toggle, invite code, HSK, term size)
- Loading state on sign-in

### Shell
- 240px navy sidebar with Easy Study branding, user block, role switch, sign out
- White top bar with title, notification bell, avatar, optional action button
- Navigation stack for pushed screens (back bar)

### Teacher — tabs
- **Dashboard** — stat cards, weekly bar chart, Needs attention list, quick actions
- **Students** — search + data table (Name, HSK, progress, sessions)
- **Exercises** — filter pills, cards, assign + edit links
- **Classes** — upcoming / past sections, date pills
- **Profile** — invite code, settings list

### Teacher — pushed screens
- **T1 Student detail** — header, class term, lesson grid, practice results, Export PDF
- **T2 Exercise form** — type picker, MC / compose / matching editors, coming-soon placeholders, worksheet upload card, assign sidebar
- **T3 Class form** — title, date, time, duration pills, video link, student chips
- **T4 Class detail** — info, Zoom link, students, conclude / delete

### Student — pushed screens
- **S1 MC exercise** — progress bar, Chinese prompt, A–D, correct/incorrect states
- **S2 Compose sentences** — dashed answer zone, word bank chips (南方的 / 夏天 / 热极了)
- **S3 Matching** — two-column prompts + answers
- **S4 Coming soon** — construction empty state
- **S5 Lesson detail** — vocabulary cards, Start quiz
- **S6 Quiz** — MC questions
- **S6b Quiz score** — results breakdown screen

### Dialogs (partial)
- **D1 Assign exercise** — search, checkboxes, due date toggle
- **D2 Worksheet import progress** — 3-step modal with progress bar
- **D5 Conclude class** — confirm modal (inside class detail)

### Docs bundled in Make
- `EasyStudy_FigmaAI_Prompts.md`
- `FIGMA_AI_SPEC.md`
- `FIGMA_UPDATED_V1.md`
- Logo PNG assets (6 files in Make images)

### Flutter (repo) — already aligned
- Desktop sidebar shell + white top bar (`lib/core/widgets/app_shell.dart`)
- Test login navy + white panel layout
- Brand assets in `assets/brand/`

---

## Recommended next 3 tasks (do these first)

| Order | Task | ID | Why |
|-------|------|-----|-----|
| **1** | **Import review screen** | D3 | Worksheet workflow stops after progress modal — teachers need detected type, editable text, question preview, Import button |
| **2** | **Mobile shell + 10 tab frames** | §2 | App uses bottom nav on phone; Make is desktop-only today |
| **3** | **Wire real logo** | §1 | Replace ✏️ emoji with `mascot_pencil.png` in sidebar + auth (files already in Make) |

---

## Remaining work — Figma Make

### P1 — Must ship (blocking full V.1)

| # | Task | Spec |
|---|------|------|
| **D3** | **Import review screen** | Full-screen (not modal): navy bar with × close + “Import questions”; detected type card (e.g. Multiple choice, HSK 3); editable textarea with sample Chinese OCR text; “Re-analyze” link; question preview list (3 items); warning banner for OCR accuracy; sticky “Import N questions” button. See Prompt D3 in `EasyStudy_FigmaAI_Prompts.md`. |
| **§2** | **Mobile shell — Teacher** | Frame 390×844: navy app bar, 5-tab bottom nav (Dashboard, Students, Exercises, Classes, Profile), FAB on Exercises + Classes tabs |
| **§2** | **Mobile shell — Student** | Frame 390×844: navy app bar, 5-tab bottom nav (Home, My Classes, Lessons, Progress, Profile), notification bell on Home |
| **§1** | **Real logo in UI** | Sidebar: `mascot_pencil.png` ~32px; Auth: `logo_primary.png` on black background; remove ✏️ emoji placeholder |
| **S7** | **Student class detail** | Separate from teacher class detail: session info, teacher name, **Leave class** button, leave confirm (D8) — not teacher Conclude UI |
| **D7** | **Join class dialog** | Modal on student Home “Join class”: session code input (6 chars), class preview, Confirm |

### P2 — Full app completeness

| # | Task | Spec |
|---|------|------|
| **A5** | **Complete profile** | First login: avatar placeholder, name, role chip, HSK + term (student), Save and continue |
| **D4** | **Delete exercise** | Confirm: “Delete exercise?” + cannot undo + Cancel / Delete (error red) |
| **D6** | **Add class term** | Modal from student detail “Add term”: 8/16 sessions toggle, start date, end date |
| **D8** | **Leave class confirm** | “Leave this class?” + Cancel / Leave (student) |
| **§7** | **States reference page** | One page/grid: 8 empty + 4 loading + 3 error variants (copy from `FIGMA_AI_SPEC.md` §7–9) |
| **§1** | **Noto Sans SC font** | Add to `fonts.css`; apply to all Chinese exercise text, vocabulary, import preview |
| **§1** | **Componentize atoms** | Extract Card, HskBadge, StatusPill, EmptyState, Avatar, PushedBar, Modal as reusable components (code or Figma Design file) |

### P3 — Polish & handoff

| # | Task | Spec |
|---|------|------|
| **Z1** | **App icon 1024** | Pencil mascot on black; test at 60px and 120px |
| **§8** | **Tab pixel polish** | Match prompts exactly where Make differs from `FIGMA_AI_SPEC.md` |
| **Design file** | **Optional:** Export key screens to static Figma `/design/` file for non-Make handoff |
| **Reading cloze / Picture** | Keep **placeholder only** until Flutter implements editors (out of full V.1 scope) |

---

## Remaining work — Flutter app

Implement to match Figma Make prototype (`App.tsx`). Priority follows Figma P1.

| # | Screen / area | Route / file | Status |
|---|---------------|--------------|--------|
| F1 | Import review dialog | `teacher_exercise_form_screen.dart` | ⚠️ Exists — align layout to D3 |
| F2 | Student detail | `/teacher/student/:id` | ⚠️ Exists — restyle to T1 |
| F3 | Exercise form layout | `/teacher/exercise/new` | ⚠️ Exists — 2-col layout + upload card |
| F4 | Class form | `/teacher/session/new` | ⚠️ Exists — restyle to T3 |
| F5 | Class detail (teacher) | `/teacher/session/:id` | ⚠️ Exists — restyle to T4 |
| F6 | MC exercise player | `/student/exercise/:id` | ⚠️ Exists — restyle to S1 (states) |
| F7 | Compose exercise player | same | ⚠️ Exists — restyle to S2 |
| F8 | Matching exercise player | same | ⚠️ Exists — restyle to S3 |
| F9 | Lesson detail | `/student/lesson/:id` | ⚠️ Exists — vocabulary cards |
| F10 | Quiz + score | `/student/quiz/:lessonId` | ⚠️ Exists — add score summary screen |
| F11 | Student class detail | `/student/class/:sessionId` | ⚠️ Exists — add leave flow |
| F12 | Assign exercise dialog | `teacher_exercises_tab.dart` | ⚠️ Exists — match D1 |
| F13 | Real logo in sidebar | `app_shell.dart` | Use `AppLogo` mascot variant |
| F14 | Production login/register | router | ❌ Wire `login_screen.dart` / `register_screen.dart` |

---

## Checklist by screen ID

Use this to tick off V.1 completion.

### Auth

| ID | Screen | Figma Make | Mobile frame | Flutter |
|----|--------|------------|----------------|---------|
| A1 | Test login | ✅ | ❌ | ✅ |
| A2 | Login | ✅ | ❌ | ❌ |
| A3 | Register teacher | ✅ | ❌ | ❌ |
| A4 | Register student | ✅ | ❌ | ❌ |
| A5 | Complete profile | ❌ | ❌ | ⚠️ |

### Teacher pushed

| ID | Screen | Figma Make | Mobile frame | Flutter |
|----|--------|------------|----------------|---------|
| T1 | Student detail | ✅ | ❌ | ⚠️ |
| T2 | Exercise form | ✅ | ❌ | ⚠️ |
| T3 | Class form | ✅ | ❌ | ⚠️ |
| T4 | Class detail | ✅ | ❌ | ⚠️ |

### Student pushed

| ID | Screen | Figma Make | Mobile frame | Flutter |
|----|--------|------------|----------------|---------|
| S1 | Exercise — MC | ✅ | ❌ | ⚠️ |
| S2 | Exercise — compose | ✅ | ❌ | ⚠️ |
| S3 | Exercise — matching | ✅ | ❌ | ⚠️ |
| S4 | Exercise — coming soon | ✅ | ❌ | ⚠️ |
| S5 | Lesson detail | ✅ | ❌ | ⚠️ |
| S6 | Quiz | ✅ | ❌ | ⚠️ |
| S6b | Quiz score | ✅ | ❌ | ❌ |
| S7 | Class detail (student) | ❌ | ❌ | ⚠️ |

### Dialogs

| ID | Dialog | Figma Make | Flutter |
|----|--------|------------|---------|
| D1 | Assign exercise | ✅ | ⚠️ |
| D2 | Import progress | ✅ | ✅ |
| D3 | Import review | ❌ | ⚠️ |
| D4 | Delete exercise | ❌ | ✅ |
| D5 | Conclude class | ✅ | ✅ |
| D6 | Add class term | ❌ | ✅ |
| D7 | Join class | ❌ | ⚠️ |
| D8 | Leave class | ❌ | ⚠️ |

### Shell & system

| Item | Figma Make | Mobile | Flutter |
|------|------------|--------|---------|
| Desktop shell | ✅ | — | ✅ |
| Mobile shell | ❌ | ❌ | ✅ |
| States sheet | ❌ | ❌ | — |
| Real logo | ❌ | ❌ | ⚠️ |
| Noto Sans SC | ✅ | ❌ | ❌ |
| App icon 1024 | ❌ | — | ⚠️ web icons only |

---

## Brand & design system (still needed)

### Logo — use repo assets

Import from `assets/brand/` into Make UI:

| File | Use |
|------|-----|
| `mascot_pencil.png` | Sidebar compact mark (~32px) |
| `logo_primary.png` | Auth screen, marketing |
| `logo_with_tagline.png` | Footer / about |

### Components to publish

| Component | Variants |
|-----------|----------|
| Sidebar | Teacher active, Student active |
| Top bar | With action, with bell, plain |
| Card | Default, alert accent bar, teal upload tint |
| HSK badge | HSK 1–6 |
| Status pill | Published, Draft, Upcoming, Concluded, Not started, In progress, Done |
| Primary button | Navy (teacher), Teal (student), Destructive |
| Secondary button | Outlined navy |
| Empty state | 8 variants (§7 below) |
| Avatar | 32 / 44 / 64 / 72 |
| Search bar | Full width + magnifier |
| Progress | Linear bar, circular ring |
| Pushed bar | Back + title + optional right action |
| Modal / bottom sheet | Centered dialog, assign sheet |

### Typography

| Role | Font |
|------|------|
| UI / Latin | Plus Jakarta Sans |
| Chinese content | **Noto Sans SC** — exercise prompts, vocabulary, worksheet import text |

---

## Mobile bottom nav labels (must match app)

| Teacher | Student |
|---------|---------|
| Dashboard | Home |
| Students | My Classes |
| Exercises | Lessons |
| Classes | Progress |
| Profile | Profile |

Frame size: **390 × 844**. Navy app bar on mobile (not white top bar).

---

## States reference page (create in Figma)

One page titled **States** with a grid of all variants.

### Empty states (8)

1. No students — `Students appear here after they register…`
2. No exercises — `Tap New exercise to create practice…`
3. No active classes — `Tap New class to create a session…`
4. No class history — `Concluded classes appear here…`
5. No classes joined — `Go to Home and tap Join…`
6. No content / lessons — `Your teacher will assign exercises…`
7. No progress — `Complete a lesson or quiz…`
8. Exercise type coming soon — `This worksheet type is not available…`

Pattern: 48px icon + 16px semibold title + 14px subtitle.

### Loading (4)

1. Full-screen spinner on surface
2. List skeleton cards (optional)
3. Button with inline spinner
4. Worksheet import step 2 active

### Error (3)

1. Snackbar bottom `#B53A3A`
2. Inline field error below input
3. Worksheet import failure card on exercise form

---

## Suggested Figma page structure

```
📁 Easy Study V.1
├── 🎨 Design system (colors, type, components)
├── 🖥️ Web — Shell ✅
├── 🖥️ Web — Teacher tabs ✅
├── 🖥️ Web — Teacher screens ✅
├── 🖥️ Web — Student tabs ✅
├── 🖥️ Web — Student screens ✅
├── 📱 Mobile — Shell ❌
├── 📱 Mobile — Teacher ❌
├── 📱 Mobile — Student ❌
├── 💬 Dialogs & sheets ⚠️ (3/8)
├── ⚠️ States (empty / loading / error) ❌
└── 🔐 Auth ✅ (except A5)
```

---

## Content & copy rules

- **Product name:** Easy Study (never “Chinese Tracker”)
- **Chinese centre:** 易华文教中心
- **Tagline:** Mandarin Education Center & China Education Consultant
- **Sample students:** Wang Fang, Li Ming, Ahmad Hassan, Priya Sharma
- **HSK chips:** Teal, “HSK 1” … “HSK 6”
- **Exercise types:** Multiple choice, Compose sentences (组词成句), Matching (对话配对)
- **Chinese samples:** `南方的 / 夏天 / 热极了`, `组词成句`, `你好吗？`, `谢谢`
- **Dates:** “Mon 23 Dec”, “Dec 20”
- **Cards:** 12px radius, 1px border `#E2E5EB`, no drop shadow

---

## Out of scope for V.1

- Dark mode
- Motion / animation specs
- Marketing website
- Multi-teacher / multi-school admin
- Reading cloze & picture sentence **full** editors (placeholder only)
- Separate static Figma Design file (optional P3)

---

## Copy-paste prompts for Figma Make

Paste **one prompt at a time** into Figma Make chat. Wait for each to finish before the next.

### Prompt 1 — D3 Import review (highest priority)

```
After WorksheetImportDialog finishes, open a full-screen ImportReviewScreen (not a small modal).

Layout:
- Navy top bar: × close on left, title "Import questions"
- Detected type card: "Multiple choice" + HSK 3 badge
- Editable textarea with sample OCR text mixing Indonesian + Chinese, e.g.:
  "SOAL PILIHAN GANDA
  1. 南方的天气很（ ）
  A. 热  B. 冷  C. 好  D. 大"
- "Re-analyze" link with rotate icon
- Question preview list (3 items with prompts/options)
- Yellow warning banner: "Check OCR text — scanned worksheets may have errors"
- Sticky bottom button: "Import 3 questions" (navy)

Wire: Exercise form → Choose file → WorksheetImportDialog → ImportReviewScreen → back to form with "3 questions imported".

Use Noto Sans SC for Chinese. Match existing navy/teal tokens.
```

### Prompt 2 — Real logo

```
Replace the ✏️ emoji placeholder with the real logo PNGs already in this Make project.

- Auth screen: logo_primary.png centered on black background (~80px height)
- Sidebar: mascot_pencil.png ~32px in the brand row (keep "Easy Study" + 易华文教中心 text)

Remove the yellow emoji box. Use <img src="..."> for the PNG assets in the project.
```

### Prompt 3 — Mobile shell (teacher + student)

```
Add responsive mobile layout for viewport width < 900px (390×844 frame feel).

When mobile:
- Hide the 240px sidebar
- Show navy app bar with Easy Study title + notification bell
- Show 5-tab bottom navigation (not sidebar)

Teacher bottom nav: Dashboard, Students, Exercises, Classes, Profile
Student bottom nav: Home, My Classes, Lessons, Progress, Profile

On Exercises and Classes tabs, show a navy FAB (+) bottom-right.
Keep desktop sidebar layout unchanged at ≥900px.
Add a viewport toggle or use window resize to demo both.
```

### Prompt 4 — S7 Student class detail + D8 Leave class

```
Add StudentClassDetailScreen — different from teacher ClassDetailScreen.

Student view shows: class title, date/time, teacher name "Teacher Ng", Zoom link, status pill.
Primary action: red outlined "Leave class" button (not Conclude/Delete).

Wire: Student → My Classes → View details → StudentClassDetailScreen.
Leave class opens confirm modal D8: "Leave this class?" Cancel / Leave (destructive).

Do NOT reuse teacher conclude/delete UI for students.
```

### Prompt 5 — D7 Join class dialog

```
On Student Home, add a "Join class" card/button that opens JoinClassDialog.

Modal: title "Join class session", 6-character code input, class preview card
(e.g. "HSK 2 — Grammar Review · Mon 23 Dec · Teacher Ng"), Cancel + Confirm (teal).

Show on Home tab above "Your practice".
```

### Prompt 6 — Remaining dialogs + A5

```
Add these modals wired to existing UI triggers:

D4 Delete exercise — from exercise card overflow menu: "Delete exercise?" cannot undo
D6 Add class term — from Student detail "Add term": 8/16 toggle, start date, end date
A5 Complete profile — screen after first register: name, role chip, HSK + term (student), Save

Match existing Modal component style.
```

### Prompt 7 — States reference page

```
Add a dev-only "States" view (button in Profile or role switch area) showing a grid:

8 empty states, 4 loading states, 3 error states — copy titles from FIGMA_AI_SPEC.md §7–9.
Each cell: 48px icon + title + subtitle. Use existing EmptyState component where possible.
```

---

## How to use this doc

1. Work **Recommended next 3 tasks** first.
2. Tick items in **Checklist by screen ID** as you complete them.
3. After Figma updates, implement matching **Flutter** rows in § “Remaining work — Flutter app”.
4. Update **Changelog** below when a version ships.

### Changelog

| Version | Date | Notes |
|---------|------|-------|
| **V.1** | Jun 2026 | Initial gap doc: Make vs Flutter; P1/P2 priorities |
| **V.1.1** | Jun 2026 | Audit after major Make update: auth, all tabs, pushed screens, partial dialogs done; added coverage matrix, checklists, Flutter backlog, next-3 tasks |
| **V.1.2** | Jun 2026 | Re-audit: P1 tasks still missing in App.tsx; Noto Sans SC added in fonts.css; copy-paste Figma Make prompts added |

---

*Last audited against Figma Make `8LDbnO1nfJCZX74gGssbRB` and Flutter repo `chinese-tracker`.*
