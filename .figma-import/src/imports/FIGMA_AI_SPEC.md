# Figma AI design spec — Easy Study

Use this document when prompting Figma AI. Copy sections into your prompt as needed.

> **Branding:** The product name is **Easy Study**. The repo/package is still `chinese-tracker` — always show **Easy Study** in UI, marketing, and Figma frames.

---

## Quick prompt (paste into Figma AI)

```
Design screens for "Easy Study" — a professional Chinese tutoring LMS for adults.
Audience: solo tutors (teacher admin) and adult HSK students (mobile-first web app).

Brand: Easy Study (易华文教中心) — use official mascot: yellow pencil with graduation cap, 易华 on body.
Logo colors: Yellow #F5B800, Green #00A651, Teal #006B54 on black. App UI chrome: Navy #1B2A4A, Teal #2D6A7E, surface #F5F6F8.
Typography: Plus Jakarta Sans (Latin/UI). Noto Sans SC for Chinese characters and HSK labels.
Include real Chinese sample text (组词成句, 选词填空, 南方的 / 夏天 / 热极了).
Cards: 12px radius, 1px border, no drop shadow.
Bottom nav: 5 tabs. Material 3 inspired but custom navy/teal palette.
Design empty states (icon 48px + title + subtitle) and loading spinners (teal/navy).
```

---

## 1. Branding

| Item | Value |
|------|-------|
| **Product name** | **Easy Study** |
| **Chinese name** | **易华文教中心** |
| **Tagline** | Mandarin Education Center & China Education Consultant |
| **Repo / package** | `chinese-tracker` (do not show in UI) |
| **Legacy name** | Chinese Tracker (retired in UI) |
| **Audience** | Adult learners, private Chinese tutors, HSK 1–6 |
| **Tone** | Friendly-professional education brand; mascot pencil with graduation cap |

### Logo assets (in repo)

Import into Figma from `assets/brand/`:

| File | Description |
|------|-------------|
| `logo_primary.png` | Full lockup: mascot + 易华文教中心 + EASY STUDY yellow pill |
| `logo_with_tagline.png` | Lockup + white English tagline |
| `mascot_pencil.png` | Standalone pencil mascot (app icon source) |
| `mascot_board.png` | Board graphic |
| `mascot_writing.png` | Calligraphy graphic |

See [assets/brand/README.md](../../assets/brand/README.md).

**Login / marketing:** Logo on **black** `#000000` background. **In-app screens:** light surface `#F5F6F8` with navy app bar.

---

## 2. Color palette

### Logo / marketing (official artwork)

| Token | Hex | Usage |
|-------|-----|--------|
| **Brand yellow** | `#F5B800` | EASY STUDY pill, pencil body |
| **Brand green** | `#00A651` | Chinese calligraphy |
| **Brand teal** | `#006B54` | EASY STUDY text, pencil tip |
| **Brand black** | `#000000` | Logo background, cap |

### App UI (current Flutter theme)

Source: `lib/core/theme/app_theme.dart` → `AppColors`

| Token | Hex | Usage |
|-------|-----|--------|
| **Navy** | `#1B2A4A` | App bar, teacher primary buttons, section emphasis |
| **Navy light** | `#2A3F66` | Hover / secondary navy surfaces |
| **Teal** | `#2D6A7E` | Student buttons, links, nav indicator, HSK/accent highlights |
| **Teal light** | `#3D8A9E` | Teal hover, soft badges |
| **Surface** | `#F5F6F8` | Page background (scaffold) |
| **Card** | `#FFFFFF` | Cards, inputs, bottom nav background |
| **Text primary** | `#1A1D26` | Body copy, titles |
| **Text secondary** | `#5C6370` | Subtitles, hints, empty states |
| **Border** | `#E2E5EB` | Card borders, dividers, input outlines |
| **Success** | `#2E7D5A` | Correct answers, positive feedback |
| **Error** | `#B53A3A` | Errors, overdue alerts, destructive actions |

**Background style:** Light mode only (v1). Off-white page + white cards. No dark mode.

**Accent for Chinese / HSK:** Use **teal** for HSK level chips, Chinese exercise type labels, and worksheet highlights. Navy for structural chrome.

**Semantic colors (teacher dashboard):**

| Alert | Color |
|-------|-------|
| Overdue / stale assignment | Error `#B53A3A` |
| Inactive student | Text secondary |
| Low sessions remaining | Teal |

---

## 3. Typography

| Role | Font | Weight | Notes |
|------|------|--------|-------|
| **UI / Latin** | [Plus Jakarta Sans](https://fonts.google.com/specimen/Plus+Jakarta+Sans) | 400 body, 600–700 headings | Loaded via Google Fonts in app |
| **Chinese (CJK)** | [Noto Sans SC](https://fonts.google.com/noto/specimen/Noto+Sans+SC) | 400–600 | Simplified Chinese; use for 组词成句, passages, HSK content |
| **Fallback stack** | `Plus Jakarta Sans`, `Noto Sans SC`, system-ui, sans-serif | — | Figma: set both families on text styles |

**Scale (approximate from Flutter theme):**

| Style | Size | Weight | Color |
|-------|------|--------|-------|
| Headline (login) | 28px | 700 | Navy |
| App bar title | 20px | 600 | White on navy |
| Section header | 16px | 700 | Navy |
| Card title | 16px | 600 | Text primary |
| Body | 14–16px | 400 | Text primary |
| Caption / nav label | 12px | 400–600 | Text secondary / navy when selected |
| Chinese exercise prompt | 16px | 400 | Text primary, line-height 1.5 |

**Adult education feel:** Plus Jakarta Sans is geometric and friendly-professional. Avoid rounded display fonts or childish illustrations.

---

## 4. Chinese character rendering

The app constantly mixes **English/Indonesian instructions** with **Chinese content**.

**Figma requirements:**

1. Add **Noto Sans SC** to the file (Google Fonts plugin).
2. Create a text style **Body / Chinese** using Noto Sans SC 16px.
3. Sample strings for realistic frames:
   - Exercise type: `组词成句` · `对话配对` · `选词填空`
   - Compose segments: `南方的` / `夏天` / `热极了`
   - Matching prompt: `例如：你好吗？( )`
   - HSK label: `HSK 3`
4. Never use a Latin-only font for Chinese — characters will look wrong or fall back to system default.
5. Worksheet import UI may show mixed Latin + CJK paragraphs — design with adequate line-height (1.45–1.5).

**OCR context:** Teachers upload scanned HSK worksheets (often Indonesian headers + Chinese body). Show both scripts in import review dialogs.

---

## 5. Layout & components

| Element | Spec |
|---------|------|
| **Max content width (auth)** | 420px centered |
| **Page padding** | 20px |
| **Card** | White, 12px radius, 1px border `#E2E5EB`, 16px padding, no elevation |
| **App bar** | Navy background, white title + icons, flat |
| **Bottom navigation** | 5 destinations, white bar, teal indicator pill (15% opacity) |
| **Primary button (teacher)** | Navy fill, white text, 10–14px vertical padding |
| **Primary button (student)** | Teal fill |
| **Input** | White fill, 10px radius, 1px border; focus border teal 1.5px |
| **FAB** | Extended FAB on Exercises / Classes tabs — teal or navy per context |
| **Progress (import)** | Linear bar + 3 step labels: Prepare file → Read file → Detect questions |

---

## 6. Loading states

No skeleton loaders in v1 — use **centered circular spinner** (`CircularProgressIndicator`, teal or default).

| Screen / context | Loading UI |
|----------------|------------|
| Teacher / student shell | Full-screen centered spinner while profile loads |
| Dashboard, lists (Firestore streams) | Centered spinner until first data |
| Exercise screen | Centered spinner while exercise loads |
| Student detail | Centered spinner; export PDF shows small spinner on button |
| Test login | Spinner inside tapped button; disable other buttons |
| Worksheet upload | Modal dialog: file name, linear progress 0–100%, step checklist |
| Quiz submit | Button disabled + inline spinner |

**Figma:** Design a **Loading** variant for list screens (spinner centered on `#F5F6F8` background) and a **Worksheet import progress** modal.

---

## 7. Empty states

Reusable pattern (`EmptyState` widget): **48px icon** (text secondary) + **title** (16px semibold) + **subtitle** (14px secondary), centered, 32px padding.

| Screen | Icon | Title | Subtitle |
|--------|------|-------|----------|
| Teacher — Students | `people_outline` | No students yet | Students appear here after they register in the app. |
| Teacher — Exercises | `fitness_center` | No exercises yet | Tap New exercise to create practice, then assign it to students. |
| Teacher — Classes (active) | `event` | No active classes | Tap New class to create a session students can join. |
| Teacher — Classes (history) | `history` | No class history yet | Concluded classes appear here after you tap Conclude class. |
| Teacher — Dashboard attention | — (inline card) | — | All caught up — no students need follow-up right now. |
| Teacher — Dashboard students | — | — | No students registered yet. |
| Student — My classes | `event_available` | No classes joined yet | Go to Home and tap Join on an open class session. |
| Student — Lessons | `menu_book` | No content yet | Your teacher will assign exercises and publish lessons… |
| Student — Progress | `trending_up` | No progress yet | Complete a lesson or quiz to see your history here. |
| Student — Progress (no lessons) | `trending_up` | No lessons yet | No lessons for HSK X yet. |
| Student — Exercise (not assigned) | `lock` | Exercise not assigned | Your teacher must assign this exercise before you can do it. |
| Student — Exercise (not found) | `fitness_center` | Exercise not found | This exercise may have been removed. |
| Student — Exercise (no questions) | `fitness_center` | No questions yet | Your teacher has not added questions to this exercise. |
| Student — Quiz | `quiz` | No quiz for this lesson | No quiz is available for this lesson yet. |
| Student — Lesson | `menu_book` | Lesson not found | This lesson may have been removed. |

---

## 8. Error states

| Pattern | Spec |
|---------|------|
| **Inline form error** | Red text `#B53A3A` below field or at top of form |
| **Snack bar** | Error background `#B53A3A`, white text, bottom of screen |
| **Worksheet import failure** | Red error text on exercise form (multi-line setup/troubleshooting) |
| **Auth failure** | Error snack bar on login screen |

No dedicated full-page error screens — errors are snack bars or inline messages.

---

## 9. “Coming soon” / unimplemented exercise types

### Types not yet built

| Type | Label | Teacher | Student |
|------|-------|---------|---------|
| Reading cloze | Reading cloze (选词填空) | In type dropdown; selecting shows snackbar | Full-screen empty state |
| Picture + keyword | Picture + keyword sentence | Same | Same |

### Student — exercise screen (coming soon)

When teacher assigns an unimplemented type:

- **Icon:** `construction` (outlined)
- **Title:** Exercise type coming soon
- **Subtitle:** This worksheet type is not available for students yet.
- **Layout:** Same `EmptyState` as other errors — centered on page, navy app bar with exercise title
- **No CTA** — back button only

### Teacher — exercise form

- All 5 types appear in **Exercise type** dropdown.
- Selecting reading cloze or picture + keyword → **snackbar** (not a separate screen):
  - `"{type label} is recognized on import but not editable yet. Use compose sentences or matching for now."`
- **Worksheet import:** If detected type is unimplemented → snackbar with detection summary; import blocked.

### Figma frames to design

1. **Student — Coming soon** empty state (construction icon).
2. **Teacher — Type dropdown** with all 5 types listed; annotate last 2 as “import only”.
3. **Teacher — Snackbar** for locked type (optional).
4. **Future reading cloze (wireframe):** Passage with numbered blanks `(1) ___` and word bank A/B/C/D below — for roadmap, not v1.
5. **Future picture sentence (wireframe):** Image placeholder + keyword chip (e.g. `页`) + text field “Write a sentence using this word” — for roadmap, not v1.

---

## 10. Role-specific UI notes

### Teacher
- Navy app bar, professional admin feel.
- Dashboard: stat cards + **Needs attention** list with colored reason icons.
- FAB on Exercises and Classes tabs.

### Student
- Teal accents on home / practice cards.
- **Continue learning** hero on Home.
- Join class flow from Home (session code).

---

## 11. Related files

| Doc | Purpose |
|-----|---------|
| [SCREEN_INVENTORY.md](../screen-inventory/SCREEN_INVENTORY.md) | All routes and screens |
| [APP_OVERVIEW.md](../APP_OVERVIEW.md) | Product features |
| [WORKSHEET_IMPORT.md](../WORKSHEET_IMPORT.md) | Upload flow UI |

| Code | Purpose |
|------|---------|
| `lib/core/theme/app_theme.dart` | Colors + Plus Jakarta Sans |
| `lib/core/widgets/app_card.dart` | Card + `EmptyState` |
| `lib/models/exercise_type.dart` | Exercise types + `isImplemented` |
