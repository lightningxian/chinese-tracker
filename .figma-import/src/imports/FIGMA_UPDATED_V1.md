# Figma Updated V.1 — What to add next

Brief for updating the **Easy Study** Figma file so design matches the Flutter app and fills gaps in the current prototype.

| | |
|---|---|
| **Figma Make file** | [Follow-MD-file-instructions](https://figma.com/make/8LDbnO1nfJCZX74gGssbRB/Follow-MD-file-instructions) |
| **File key** | `8LDbnO1nfJCZX74gGssbRB` |
| **Flutter repo** | `~/Projects/chinese-tracker` |
| **Related docs** | [FIGMA_AI_SPEC.md](FIGMA_AI_SPEC.md) · [SCREEN_INVENTORY.md](../screen-inventory/SCREEN_INVENTORY.md) · [EasyStudy_FigmaAI_Prompts.md](https://figma.com/make/8LDbnO1nfJCZX74gGssbRB) (in Make source) |

---

## Current state (what Figma already has)

The Make prototype (`App.tsx`) includes:

- **Web desktop layout** — 240px navy sidebar + white top bar + surface content
- **Teacher tabs** — Dashboard, Students, Exercises, Classes, Profile
- **Student tabs** — Home, My Classes, Lessons, Progress, Profile
- **Design tokens** — Navy, Teal, Surface, cards, HSK badges, status pills, empty states
- **Role switcher** in sidebar (Teacher ↔ Student preview)
- **Prompt library** — `EasyStudy_FigmaAI_Prompts.md` (29 prompts) in Make source

The Flutter app **now uses this desktop shell** (sidebar ≥900px; bottom nav on narrow screens).

---

## V.1 goal

One Figma file that a developer can implement screen-by-screen without guessing. V.1 should cover **every routed screen** in the app plus **all dialogs and UI states**, in **web desktop** and **mobile** frames.

---

## 1. Brand & design system (update existing)

### Replace placeholder logo

- Swap the yellow **易** chip in the sidebar for the real assets from `assets/brand/`:
  - `mascot_pencil.png` — sidebar compact mark
  - `logo_primary.png` — login / marketing
  - `logo_with_tagline.png` — about / footer

### Publish as Figma components

| Component | Variants |
|-----------|----------|
| **Sidebar** | Teacher active item, Student active item |
| **Top bar** | With action button, with notification bell, plain |
| **Card** | Default, accent left border (alerts), soft teal tint (upload) |
| **HSK badge** | HSK 1–6 |
| **Status pill** | Published, Draft, Upcoming, Concluded, Not started, In progress, Done |
| **Primary button** | Navy (teacher), Teal (student), Destructive (error) |
| **Secondary button** | Outlined navy |
| **Empty state** | 8 variants (see §6) |
| **Avatar** | Initials, sizes 32 / 44 / 64 / 72 |
| **Search bar** | With magnifier, full width |
| **Progress bar** | Linear teal; circular ring (term progress) |
| **App user row** | Avatar + name + HSK + chevron |

### Text styles (confirm in file)

- **UI:** Plus Jakarta Sans
- **Chinese content:** Noto Sans SC — always on exercise prompts, vocabulary, worksheet import preview

---

## 2. Layout frames to add

### A. Shell layouts (2 master frames)

| Frame | Size | Notes |
|-------|------|-------|
| **Web desktop shell** | 1440 × 900 | Sidebar + top bar — **already in Make; polish & componentize** |
| **Mobile shell** | 390 × 844 | Navy app bar + bottom nav (5 tabs) — **not in Make yet** |

**Mobile bottom nav labels (must match app):**

| Teacher | Student |
|---------|---------|
| Dashboard | Home |
| Students | My Classes |
| Exercises | Lessons |
| Classes | Progress |
| Profile | Profile |

---

## 3. Auth screens (new pages)

| # | Screen | Priority | Notes |
|---|--------|----------|-------|
| A1 | **Test login** (current dev) | P1 | Navy logo panel + white “Test mode” role picker — matches Flutter now |
| A2 | **Login** (production) | P2 | Email, password, forgot password, Google — from Prompt A1 in Make source |
| A3 | **Register teacher** | P2 | Role toggle, name, email, password |
| A4 | **Register student** | P2 | + invite code, HSK dropdown, term size 8/16 |
| A5 | **Complete profile** | P2 | First-time setup after auth |

---

## 4. Teacher — pushed screens (new)

These open **inside or beside** the shell (back arrow, no sidebar on mobile; optional collapsed sidebar on desktop).

| # | Screen | Priority | Key UI |
|---|--------|----------|--------|
| T1 | **Student detail** | P1 | Header, class term card + add term, lesson progress grid, practice results, **Export PDF** |
| T2 | **Exercise form** | P1 | Type dropdown, title, HSK, instructions, **worksheet upload card**, question editors (3 types), Publish / Assign |
| T3 | **Class form** | P1 | Title, date, time, duration pills, video link, student chips |
| T4 | **Class detail** | P1 | Info, Zoom link, student list, Conclude / Delete |

### Exercise form — question type editors (inside T2)

| Type | Editor UI |
|------|-----------|
| **Multiple choice** | Prompt + A–D options + correct answer radio |
| **Compose sentences (组词成句)** | Segment chips per question |
| **Matching** | Answer bank A–F + numbered prompts + correct letter |
| **Reading cloze** | Placeholder “Coming soon” + detection-only note |
| **Picture + keyword** | Placeholder “Coming soon” + image upload mock |

---

## 5. Student — pushed screens (new)

| # | Screen | Priority | Key UI |
|---|--------|----------|--------|
| S1 | **Exercise — multiple choice** | P1 | Progress bar, Chinese prompt, A–D cards, selected/correct/incorrect states |
| S2 | **Exercise — compose sentences** | P1 | Answer zone (dashed), word bank chips, 南方的 / 夏天 / 热极了 |
| S3 | **Exercise — matching** | P1 | Two columns: prompts + answers, connection lines |
| S4 | **Exercise — coming soon** | P1 | Construction icon empty state (reading cloze / picture) |
| S5 | **Lesson detail** | P2 | Content + vocabulary cards + “Start quiz” |
| S6 | **Quiz** | P2 | MC flow + **score summary** screen after submit |
| S7 | **Class detail (student)** | P2 | Session info, leave class |

---

## 6. Dialogs & sheets (new)

| # | Dialog | Priority | Trigger |
|---|--------|----------|---------|
| D1 | **Assign exercise** | P1 | Bottom sheet: search students, checkboxes, optional due date |
| D2 | **Worksheet import progress** | P1 | Modal: filename, linear progress, 3 steps (Prepare → Read → Detect) |
| D3 | **Import review** | P1 | Full screen: detected type, editable OCR text, question preview, Import |
| D4 | **Delete exercise** | P2 | Confirm destructive |
| D5 | **Conclude class** | P2 | Confirm + student list |
| D6 | **Add class term** | P2 | 8/16 sessions, start/end dates |
| D7 | **Join class (student)** | P2 | Session code entry |
| D8 | **Leave class** | P2 | Confirm |

---

## 7. UI states reference sheet (new page)

One Figma page: **States** — all variants in a grid.

### Empty states (8)

1. No students  
2. No exercises  
3. No active classes  
4. No class history  
5. No classes joined (student)  
6. No content / lessons  
7. No progress  
8. Exercise type coming soon  

Pattern: 48px icon + title + subtitle (see `FIGMA_AI_SPEC.md` §7).

### Loading (4)

1. Full-screen spinner  
2. List loading (optional skeleton cards)  
3. Button loading (spinner in button)  
4. Worksheet import step 2 active  

### Error (3)

1. Error snackbar (bottom, `#B53A3A`)  
2. Inline form field error  
3. Worksheet import failure card on exercise form  

---

## 8. Tab content — polish existing Make frames

The Make prototype has the right structure; these need **pixel polish** to match Flutter/Figma prompts:

| Tab | Add / improve |
|-----|----------------|
| **Teacher Dashboard** | Stat cards row, weekly bar chart, Needs attention cards with colored accent bars |
| **Teacher Students** | Desktop: **table layout** (Name, HSK, Progress bar, Sessions, Last active) — Prompt W2 |
| **Teacher Exercises** | Filter pills All/Published/Draft, overflow menu, due date on cards |
| **Teacher Classes** | Upcoming vs Past sections, date pill on cards, Conclude action |
| **Student Home** | Live class banner (teal left border), practice cards with due badges, continue learning card |
| **Student Lessons** | Assigned practice section + lesson list with quiz badges and lock states |
| **Student Progress** | Term ring chart, weekly quiz bars, quiz history list |

---

## 9. Platform matrix (V.1 coverage)

| Screen group | Web desktop | Mobile |
|--------------|-------------|--------|
| Shell + 10 tabs | ✅ In Make — polish | ❌ Add |
| Auth (5) | Add | Add |
| Teacher pushed (4) | Add | Add |
| Student pushed (7) | Add | Add |
| Dialogs (8) | Add | Add (bottom sheets where noted) |
| States sheet | Add | Add |

Use **Prompt MP** suffix blocks from `EasyStudy_FigmaAI_Prompts.md` for platform-specific frames.

---

## 10. Content & copy rules for Figma

- **Product name:** Easy Study (never “Chinese Tracker” in UI)
- **Chinese centre name:** 易华文教中心
- **Sample students:** Mix of Chinese + international names (Wang Fang, Li Ming, Ahmad Hassan)
- **HSK levels:** Always show as teal chip “HSK 1” … “HSK 6”
- **Exercise types:** Use real labels: Multiple choice, Compose sentences (组词成句), Matching (对话配对)
- **Chinese in exercises:** Use Noto Sans SC; sample: `南方的 / 夏天 / 热极了`, `组词成句`, `你好吗？`
- **Dates:** Format like “Mon 23 Dec”, “Dec 20”
- **No drop shadows** on cards — border only `#E2E5EB`

---

## 11. Suggested Figma page structure (V.1)

```
📁 Easy Study V.1
├── 🎨 Design system (colors, type, components)
├── 🖥️ Web — Shell
├── 🖥️ Web — Teacher tabs
├── 🖥️ Web — Teacher screens
├── 🖥️ Web — Student tabs
├── 🖥️ Web — Student screens
├── 📱 Mobile — Shell
├── 📱 Mobile — Teacher
├── 📱 Mobile — Student
├── 💬 Dialogs & sheets
├── ⚠️ States (empty / loading / error)
└── 🔐 Auth
```

---

## 12. Priority order for Figma work

| Phase | Deliverables |
|-------|----------------|
| **P1 — Must ship** | Componentize shell, logo assets, T2 exercise form + D2/D3 import, S1–S3 exercise players, D1 assign, States sheet |
| **P2 — Full app** | T1 student detail, T3/T4 class, auth A2–A5, mobile shells, remaining dialogs |
| **P3 — Polish** | Charts, table views, quiz score screen, app icon 1024 (Prompt Z1) |

---

## 13. Out of scope for V.1

- Dark mode  
- Animations / motion specs  
- Marketing website  
- Teacher multi-school / admin roles  
- Reading cloze & picture sentence **full** editors (placeholder only until Flutter implements them)

---

## 14. How dev will use this file

1. Implement screen from Figma frame → match `SCREEN_INVENTORY.md` route  
2. Reuse components from Design system page  
3. Chinese text always uses Noto Sans SC layer  
4. When Figma updates, note version in this file’s changelog below  

### Changelog

| Version | Date | Notes |
|---------|------|-------|
| **V.1** | Jun 2026 | Initial gap doc: Make prototype vs Flutter app; P1/P2 priorities |

---

*Generated from Flutter app state + Figma Make file `8LDbnO1nfJCZX74gGssbRB`.*
