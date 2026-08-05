# Easy Study — Figma AI Prompt Set
Complete prompts for every screen, tab, dialog, and state.
Paste each section directly into Figma AI.

---

## HOW TO USE THIS FILE

1. Start with **Prompt 0 — Design System** (run this FIRST in every new Figma file)
2. Run **Prompt 1 — Frame Setup** to scaffold your pages
3. Read **Prompt MP — Multiplatform Rules** before designing any screen (applies to all prompts)
4. Use each numbered prompt for its screen — copy and paste as-is
5. For key screens, append the **platform suffix block** from Prompt MP to get iOS / Android / Web variants
6. Prompts marked 🔁 have multiple variants (loaded / empty / error) — run each separately

---

---

## PROMPT MP — MULTIPLATFORM RULES
> Read this before running any screen prompt. Append the relevant suffix to any prompt to get a platform-specific variant.

```
Easy Study runs on 3 platforms: Web (desktop + mobile browser), iOS, and Android.
Apply these rules per platform when designing any screen.

─────────────────────────────────────────
PLATFORM 1 — iOS (iPhone)
─────────────────────────────────────────
Frame: 390 x 844px (iPhone 14 standard)
Status bar: 54px top safe area, white icons on Navy app bar
Navigation: Bottom tab bar, 5 tabs, 83px tall including home indicator
  - Active tab: Teal indicator pill (15% opacity) behind icon + label
  - Inactive: Text secondary icon + label
Back navigation: iOS-style chevron ← in app bar, no system back button
FAB: Bottom right, 16px from edge, 16px above bottom nav
Safe areas: 34px bottom inset above home indicator line
Dialogs: Centered modal with 50% scrim; bottom sheets slide up with drag handle
Inputs: iOS-style keyboard push (screen scrolls up)

─────────────────────────────────────────
PLATFORM 2 — Android
─────────────────────────────────────────
Frame: 393 x 851px (Pixel 7 / Android 14 standard)
Status bar: 28px, Navy background, white icons (no notch — gesture bar)
Navigation: Bottom nav bar, 5 tabs, 80px tall
  - Material 3 style: active tab shows Teal pill indicator, icon + label
  - System gesture bar: 20px transparent bar below bottom nav (do not place content here)
Back navigation: System back gesture (no back button in app bar unless required)
FAB: Bottom right, above gesture bar, 16px margins
Dialogs: Material 3 modal dialogs — 28px radius, centered
Inputs: Material 3 outlined text field style (already matches app spec)
Elevation: No shadows on cards — matches app spec (flat cards, border only)

─────────────────────────────────────────
PLATFORM 3 — Web Desktop
─────────────────────────────────────────
Frame: 1440 x 900px (standard desktop browser)
Layout: Left sidebar navigation (240px fixed) + main content area (max 960px, centered)
  No bottom nav — all 5 tabs move to sidebar list items
  Sidebar: Navy #1B2A4A background, white text, teal left border on active item
  Content area: Surface #F5F6F8 background with 40px horizontal padding
Cards: Same spec (white, 12px radius, border) but arranged in multi-column grid (2–3 cols)
App bar: Replaced by sidebar header — Easy Study logo + user avatar top of sidebar
FAB: Replaced by top-right button in content header ("+ New exercise", "New class")
Dialogs: Centered modal, max 480px wide, same scrim
Inputs: Same style, max width 480px on standalone forms
Typography: Same scale — no size changes for desktop

─────────────────────────────────────────
PLATFORM 4 — Web Mobile Browser
─────────────────────────────────────────
Frame: 390 x 844px — identical to iOS frames
Navigation: Bottom nav bar (same as iOS/Android)
Differences from native:
  - No safe area inset at bottom (no home indicator)
  - Browser address bar at top reduces visible height — design with 780px usable height
  - No native back gesture — always show ← back button in app bar
  - File upload (worksheet import): fully supported on mobile Chrome
  - Image OCR: supported on mobile web (unlike native Android/iOS)
```

---

### PLATFORM SUFFIX BLOCKS
> Append one of these to the end of any screen prompt to get that platform's variant.

**For iOS variant, add:**
```
Design for iOS. Frame 390x844px. Include iOS status bar (54px, Navy). Bottom tab bar 83px with home indicator. Use iOS chevron ← for back. Safe area 34px bottom.
```

**For Android variant, add:**
```
Design for Android. Frame 393x851px. Material 3 bottom nav 80px + 20px gesture bar. Navy status bar 28px. System back gesture (no back button). Material 3 modal dialogs (28px radius).
```

**For Web Desktop variant, add:**
```
Design for web desktop. Frame 1440x900px. Replace bottom nav with left sidebar 240px Navy. Content area max 960px centered on Surface background. FAB becomes header button top-right. Use 2-column card grid where appropriate. Show Easy Study logo top of sidebar.
```

**For Web Mobile variant, add:**
```
Design for mobile web browser. Frame 390x844px. Same as iOS but no home indicator, usable height 780px. Always show ← back button in app bar. No safe area bottom inset.
```

---

---

## PROMPT 0 — DESIGN SYSTEM SETUP
> Run this once at the start of every Figma file before designing any screen.

```
Set up a design system for "Easy Study" — a professional Chinese tutoring LMS for adult learners and solo tutors.

BRAND
Product name: Easy Study (易华文教中心)
Audience: Solo Chinese tutors (admin) + adult HSK 1–6 students (learners)
Feel: Calm, professional, academic — like Notion meets Google Classroom. Not childish.

COLORS — create as local styles
Navy #1B2A4A — app bars, teacher primary buttons, headings
Navy light #2A3F66 — hover / secondary navy surfaces
Teal #2D6A7E — student accents, links, nav indicators, HSK badges
Teal light #3D8A9E — soft teal badges, hover
Surface #F5F6F8 — page/scaffold background
Card #FFFFFF — cards, inputs, bottom nav
Text primary #1A1D26 — body copy, titles
Text secondary #5C6370 — subtitles, hints, empty state copy
Border #E2E5EB — card borders, dividers, input outlines
Success #2E7D5A — correct answers, positive feedback
Error #B53A3A — errors, overdue alerts, destructive actions
Brand yellow #F5B800 — logo pill only, HSK highlight accents
Brand green #00A651 — logo calligraphy only

TYPOGRAPHY — create as text styles
Headline: Plus Jakarta Sans 28px Bold, Navy
App bar title: Plus Jakarta Sans 20px SemiBold, White
Section header: Plus Jakarta Sans 16px Bold, Navy
Card title: Plus Jakarta Sans 16px SemiBold, Text primary
Body: Plus Jakarta Sans 14–16px Regular, Text primary
Caption / nav label: Plus Jakarta Sans 12px Regular, Text secondary
Chinese content: Noto Sans SC 16px Regular, Text primary, line-height 1.5
Chinese heading: Noto Sans SC 18px SemiBold, Navy

COMPONENTS — create as components
Card: White fill, 12px corner radius, 1px border #E2E5EB, 16px padding, no shadow
App bar: Navy fill, white title + icons, flat (no elevation)
Bottom nav: White fill, 5 tabs, teal indicator pill (15% teal opacity under active icon)
Primary button (teacher): Navy fill, white text, 10px vertical padding, 8px radius
Primary button (student): Teal fill, white text, 10px vertical padding, 8px radius
Secondary button: White fill, 1px Navy border, Navy text
Destructive button: Error #B53A3A fill, white text
Input field: White fill, 10px radius, 1px border #E2E5EB; focus state 1.5px teal border
FAB (extended): Teal or Navy fill, white icon + label, 16px radius
HSK badge chip: Teal fill, white text, 6px radius, 6px 10px padding — example: "HSK 3"
Empty state: 48px icon (Text secondary), 16px SemiBold title, 14px secondary subtitle, centered, 32px padding
Loading: Centered CircularProgressIndicator in teal, on Surface background
Snackbar (error): Error #B53A3A background, white text, bottom of screen
Snackbar (success): Success #2E7D5A background, white text

GRID
8pt base grid. Page padding 20px. Max content width (auth): 420px centered. Mobile frame: 390x844.
```

---

---

## PROMPT 1 — FRAME SETUP
> Run after Prompt 0. Creates your page structure.

```
Create a Figma page structure for Easy Study app with these pages:

Page 1: Auth — Login, Register (Teacher), Register (Student), Complete Profile
Page 2: Teacher — Home (Dashboard), Students, Exercises, Classes, Profile tabs
Page 3: Teacher Screens — Student Detail, Exercise Form, Class Form, Class Detail
Page 4: Teacher Dialogs — Assign Exercise, Worksheet Import, Import Review, Add Class Term, Confirm dialogs
Page 5: Student — Home, My Classes, Lessons, Progress, Profile tabs
Page 6: Student Screens — Exercise (3 types), Lesson Detail, Quiz, Class Detail
Page 7: Student Dialogs — Join Class, Leave Class confirms
Page 8: States — All empty states, loading states, error states, coming soon states

Frame size: 390 x 844px (iPhone 14 / Android standard). Label each frame clearly.
Use Surface #F5F6F8 as frame background. Apply 8pt grid to all frames.
```

---

---

## SECTION A — AUTH SCREENS

### PROMPT A1 — Login Screen

```
Design the Easy Study login screen. Mobile frame 390x844px.

LAYOUT
Full-screen Navy #1B2A4A background at top 40% (logo area), Surface #F5F6F8 bottom 60% (form area).
Rounded top corners on the form panel (20px radius, white card).

TOP AREA (Navy)
- Easy Study logo centered: pencil mascot + "易华文教中心" + "EASY STUDY" yellow pill
- Logo on black — use brand yellow #F5B800 for the pill, teal #006B54 for text inside pill
- Tagline below logo: "Mandarin Education Center" in white, 14px, 60% opacity

FORM AREA (white card panel)
- Heading: "Welcome back" — Plus Jakarta Sans 24px Bold, Navy
- Subheading: "Sign in to continue" — 14px, Text secondary
- Email input field (full width, label above: "Email")
- Password input field (label above: "Password", show/hide toggle icon right side)
- "Forgot password?" link right-aligned, Teal color
- Primary button (Navy fill): "Sign in" — full width, 48px height
- Divider "or" with lines
- Google sign-in secondary button: white fill, border, Google icon + "Continue with Google"
- Footer: "Don't have an account? Register" — Teal link

STATES TO INCLUDE
Create 3 variants: Default, Loading (spinner inside Sign in button, button disabled), Error (red snackbar at bottom "Incorrect email or password").
```

---

### PROMPT A2 — Register Screen (Teacher)

```
Design the Easy Study teacher registration screen. Mobile 390x844px.

Same layout pattern as login: Navy top with logo, white card panel bottom.

FORM PANEL
- Heading: "Create your account" Plus Jakarta Sans 22px Bold Navy
- Role selector at top: two large toggle cards side by side
  Left card (selected): "Teacher" with chalkboard icon, Navy border + fill tint
  Right card: "Student" with book icon, unselected state (border only)
- Full name input
- Email input
- Password input (show/hide toggle)
- Confirm password input
- Primary button Navy: "Create teacher account" full width
- Footer: "Already have an account? Sign in" — Teal link

Show selected state on Teacher card with Navy left border accent + light Navy tint background.
```

---

### PROMPT A3 — Register Screen (Student)

```
Design the Easy Study student registration screen. Mobile 390x844px.

Same shell as A2 but Student role selected (Teal accent instead of Navy on the card).

FORM PANEL
- Heading: "Join Easy Study"
- Role selector: Student card selected (Teal border + teal tint), Teacher unselected
- Full name input
- Email input
- Password input
- Invite code input — label "Teacher invite code", placeholder "6-character code", info icon with tooltip "Ask your teacher for this code"
- HSK level dropdown — label "Your HSK level", options HSK 1 through HSK 6 with HSK badge chip preview
- Term size selector — label "Lessons per term", two option pills: "8 lessons" and "16 lessons" (pill toggle)
- Primary button Teal: "Join as student" full width

NOTE: HSK level selector should show a Teal HSK badge chip inline as a preview when selected.
```

---

### PROMPT A4 — Complete Profile Screen

```
Design the Easy Study complete profile screen (shown on first login). Mobile 390x844px.

This is a one-time setup screen. Navy app bar, Surface background.

APP BAR: Navy, title "Complete your profile", no back button

CONTENT (scrollable)
- Progress indicator: step dots "1 of 2" or linear bar, Teal
- Avatar placeholder: large circle 80px, Surface fill with person icon, "Add photo" label below
- Full name input (pre-filled if available from auth)
- Role display: read-only chip "Teacher" or "Student" (already set from registration)

IF STUDENT ROLE:
- HSK level dropdown (required)
- Term size pill toggle: 8 or 16 lessons
- Invite code input (if not already linked to teacher)

IF TEACHER ROLE:
- No extra fields — just name and confirm

Bottom: Primary button full width "Save and continue" (Navy for teacher, Teal for student)
```

---

---

## SECTION B — TEACHER TABS

### PROMPT B1 — Teacher Dashboard (Home Tab)

```
Design the Easy Study Teacher Dashboard tab. Mobile 390x844px. Bottom nav tab 0 of 5.

APP BAR: Navy, title "Easy Study", subtitle "Good morning, [Teacher name]" in smaller white text below title

BOTTOM NAV: 5 tabs — Home (active, teal indicator pill), Students, Exercises, Classes, Profile

CONTENT (scrollable, Surface background)

1. STAT CARDS ROW — horizontal scroll, 3 cards
   Card 1: "12" large Navy number, "Students" label, people icon Teal
   Card 2: "3" large number, "Active exercises" label, fitness icon
   Card 3: "5" large number, "Classes this term" label, calendar icon
   Card style: White, 12px radius, 1px border, 100px wide each

2. WEEKLY ACTIVITY SECTION
   Section header: "This week" 16px Bold Navy
   Simple bar chart (7 bars, Mon–Sun), Teal bars, active day Navy, 80px tall
   Below: "4 students active · 2 exercises completed" caption

3. NEEDS ATTENTION SECTION
   Section header: "Needs attention" with count badge (e.g. "3") in Error red chip
   Alert cards (stacked, white cards):
   
   Card type A — Overdue assignment:
   Left: Error red vertical accent bar (4px wide)
   Icon: assignment_late in Error red
   Title: "Wang Fang — HSK 2 Practice overdue"
   Subtitle: "Due 3 days ago · Multiple choice"
   Right: chevron →
   
   Card type B — Low sessions:
   Left: Teal accent bar
   Icon: hourglass in Teal
   Title: "Li Ming — 2 sessions remaining"
   Subtitle: "Term ends Dec 30"
   Right: chevron →
   
   Card type C — Inactive student:
   Left: Text secondary accent bar
   Icon: person_off in secondary
   Title: "Ahmad — No activity in 14 days"
   Subtitle: "Last seen Nov 15"
   Right: chevron →

4. EMPTY STATE VARIANT (separate frame)
   Replace section 3 with: no icon, inline soft card, text "All caught up — no students need follow-up right now." Text secondary, centered in card.
```

---

### PROMPT B2 — Teacher Students Tab

```
Design the Easy Study Teacher Students tab. Mobile 390x844px. Bottom nav tab 1.

APP BAR: Navy, title "Students"
Search bar below app bar: white input, magnifier icon, placeholder "Search students…", 10px radius, 1px border

BOTTOM NAV: tab 1 active

STUDENT LIST (scrollable)
Each student card (white, 12px radius, border, 16px padding):
- Left: Avatar circle 44px, initials, Navy fill
- Center: 
  Student name 16px SemiBold, Navy
  HSK badge chip (Teal) "HSK 3" inline
  "Term 1 · 5/8 lessons" in caption text secondary
- Right: 
  Sessions pill "6 sessions" in soft teal chip
  Chevron →

Show 5–6 student cards in the list. Mix of HSK levels 1–4.

EMPTY STATE (separate frame):
Center: people_outline icon 48px text secondary, "No students yet" title, "Students appear here after they register with your invite code." subtitle, no CTA button.

LOADING STATE (separate frame):
Centered teal spinner on Surface background, app bar visible.
```

---

### PROMPT B3 — Teacher Exercises Tab

```
Design the Easy Study Teacher Exercises tab. Mobile 390x844px. Bottom nav tab 2.

APP BAR: Navy, title "Exercises"
BOTTOM NAV: tab 2 active
FAB: Extended FAB bottom right — Teal fill, + icon, label "New exercise"

FILTER ROW: horizontal pill toggles below app bar
"All" (selected, Navy fill white text) | "Published" | "Draft"

EXERCISE LIST (scrollable)
Each exercise card (white, 12px radius, border):
- Status pill top right: "Published" (Success green) or "Draft" (text secondary, border)
- Exercise title 16px SemiBold
- Type label: icon + text e.g. "Multiple choice · 5 questions" in caption, Text secondary
- HSK badge chip: "HSK 2"
- Bottom row: "Assigned to 3 students" + "Due Dec 20" (if set) in caption
- 3-dot overflow menu icon top right (Edit / Assign / Delete)

Show 4 cards: 2 published, 2 draft. Mix exercise types.

EMPTY STATE (separate frame):
fitness_center icon 48px, "No exercises yet" title, "Tap New exercise to create practice, then assign it to students." subtitle.
```

---

### PROMPT B4 — Teacher Classes Tab

```
Design the Easy Study Teacher Classes tab. Mobile 390x844px. Bottom nav tab 3.

APP BAR: Navy, title "Classes"
BOTTOM NAV: tab 3 active
FAB: Extended FAB — Navy fill, + icon, label "New class"

SECTION: "Upcoming" header
Class session cards (white, 12px radius, border):
- Date pill top left: "Mon 23 Dec" — Teal background, white text, 6px radius
- Title: "HSK 2 — Grammar Review" 16px SemiBold
- Time: "10:00 AM · 60 min" caption
- Students: "4 joined" with people icon
- Actions row: "Edit" text button (Navy) | "Conclude" text button (Teal) | delete icon

SECTION: "Past classes" header (collapsed by default, show 2 cards)
Past class card — same layout but greyed, no action buttons, "Concluded" chip in Success green

EMPTY STATES (separate frames):
Active tab: event icon, "No active classes", "Tap New class to create a session students can join."
History tab: history icon, "No class history yet", "Concluded classes appear here after you tap Conclude class."
```

---

### PROMPT B5 — Teacher Profile Tab

```
Design the Easy Study Teacher Profile tab. Mobile 390x844px. Bottom nav tab 4.

APP BAR: Navy, title "Profile"
BOTTOM NAV: tab 4 active

CONTENT (scrollable, Surface background)

1. PROFILE HEADER CARD (white, 12px radius)
   Avatar 72px circle, Navy fill, initials "TN"
   Name: "Teacher Name" 20px Bold Navy
   Role chip: "Teacher" Navy fill white text 6px radius
   Email caption below

2. INVITE CODE SECTION (white card)
   Section label: "Your invite code" caption text secondary
   Code display: large monospace "ABC123" Navy 28px Bold
   Subtext: "Share this code with students when they register"
   Copy button: icon + "Copy code" Teal text button

3. ACCOUNT SECTION (white card, list items with dividers)
   Row: person icon "Edit profile" → chevron
   Row: notifications icon "Notifications" → chevron
   Row: help icon "Help & support" → chevron

4. SIGN OUT
   Destructive text button: "Sign out" in Error red, centered, 48px tap target
```

---

---

## SECTION C — TEACHER PUSHED SCREENS

### PROMPT C1 — Student Detail Screen

```
Design the Easy Study Student Detail screen (teacher view). Mobile 390x844px.

APP BAR: Navy, back arrow ←, title "Student profile", "Export PDF" text button right (Teal)

CONTENT (scrollable)

1. STUDENT HEADER CARD (white)
   Avatar 64px circle, Navy, initials
   Name: "Wang Fang" 20px Bold
   HSK badge: "HSK 3" Teal chip
   Row: "Term 1 · 5 of 8 lessons completed"
   Row: "Joined Nov 10, 2024"

2. CLASS TERM CARD (white)
   Section header: "Class term" + "Add term" Teal text button right
   Active package: "16 sessions" chip Navy, "6 remaining" caption
   Date range: "Nov 1 – Dec 31, 2024"
   Progress bar: Teal fill, 10/16 done (62%)
   Edit icon top right of card

3. LESSON PROGRESS SECTION
   Section header: "Lesson progress"
   Term selector pill toggle: "Term 1" (selected) | "Term 2"
   Progress grid: 8 lesson pills in 4x2 grid
   Completed: Navy fill, white number + checkmark
   In progress: Teal border, Teal number
   Not started: Border only, grey number

4. PRACTICE RESULTS SECTION
   Section header: "Practice results"
   Result cards (white, stacked):
   - Exercise title
   - Score pill: "80%" Success green or Error red if low
   - "Attempt 1 of 2 · Due Dec 20" caption
   - Overdue indicator: Error red text "3 days overdue" if applicable
```

---

### PROMPT C2 — Exercise Form (Create / Edit)

```
Design the Easy Study Exercise Form screen. Mobile 390x844px. Scrollable form.

APP BAR: Navy, back arrow, title "New exercise" (or "Edit exercise"), "Save draft" text right

FORM CONTENT (white cards as sections, 16px gap between)

SECTION 1 — Basic info card
- Exercise type dropdown: label "Exercise type", value "Multiple choice", chevron down
  Below type, show type description in caption: "Students pick one answer from A–D options"
- Title input: label "Title", placeholder "e.g. HSK 2 Grammar — Unit 3"
- HSK level dropdown: label "HSK level", show HSK chip preview inline

SECTION 2 — Instructions card
- Instructions textarea: label "Instructions (optional)", placeholder "e.g. Circle the correct answer", 3 lines tall

SECTION 3 — Import from file card (highlight card, soft teal background tint)
- Icon: upload_file in Teal
- Title: "Import from worksheet" SemiBold
- Body: "Upload a PDF, Word doc, or image. Questions are read on your device — no internet needed."
- Button: Secondary button "Choose file to upload"
- Supported formats row: "PDF · DOCX · JPG · PNG" in caption chips

SECTION 4 — Questions card
- Section header: "Questions" + question count chip "3"
- Question cards (stacked):
  Question 1:
  - "Q1" Navy label, question text input
  - Options A B C D (each a row: letter pill + text input)
  - Correct answer radio: "Correct: B" teal selection
  - Delete question icon top right
- "Add question" Teal text button + icon at bottom

BOTTOM ACTIONS (sticky footer, white bar)
- Left: "Assign students" secondary button
- Right: "Publish" Navy primary button
```

---

### PROMPT C3 — Class Form (Create / Edit)

```
Design the Easy Study Class Form screen. Mobile 390x844px.

APP BAR: Navy, back ←, title "New class" (or "Edit class")

FORM (white card)
- Title input: label "Class title", placeholder "e.g. HSK 2 — Speaking Practice"
- Date picker: label "Date", show calendar icon, value "Monday, 23 Dec 2024"
- Time picker: label "Start time", value "10:00 AM"
- Duration: label "Duration", pill toggle options "45 min" | "60 min" | "90 min" | "Custom"
- Video link input: label "Video call link (optional)", placeholder "Zoom / Meet URL", link icon left

STUDENTS SECTION (below form, white card)
- Section header: "Students" + "Add students" Teal text button right
- Student chips (horizontal wrap): each chip shows avatar + name, with × remove button
- Show 3 sample chips

BOTTOM: Primary Navy button "Save class" full width sticky footer
```

---

### PROMPT C4 — Class Detail Screen (Teacher)

```
Design the Easy Study Class Detail screen (teacher view). Mobile 390x844px.

APP BAR: Navy, back ←, title class title, edit icon right

CONTENT

1. CLASS INFO CARD (white)
   Title: "HSK 2 — Grammar Review" 18px Bold
   Date/time: calendar icon "Mon 23 Dec · 10:00 AM"
   Status chip: "Upcoming" Teal fill or "Concluded" Success green

2. VIDEO LINK CARD (white, if link exists)
   link icon, "Join on Zoom" Teal text, copy icon right

3. STUDENTS SECTION
   Header: "Students (4)" + "Add students" Teal text button
   List: Student rows (avatar + name + HSK chip), 4 items, remove swipe action hint

4. ACTIONS (bottom, white card)
   "Conclude class" primary Navy button — full width
   Below: "Conclude to credit attendance and deduct one session from each student's term."
   Caption text secondary, centered

   "Delete class" destructive red text button below, smaller

CONCLUDED STATE (separate frame):
Replace conclude button with: green checkmark icon + "Class concluded" Success text, "Attendance credited to 4 students" caption
```

---

---

## SECTION D — TEACHER DIALOGS

### PROMPT D1 — Assign Exercise Dialog

```
Design the Easy Study Assign Exercise bottom sheet dialog. Mobile 390px wide, height ~580px.

BOTTOM SHEET (white, 20px top radius, drag handle at top)
Title: "Assign exercise" 18px Bold Navy
Subtitle: "HSK 2 Grammar — Unit 3" in Text secondary

SEARCH: full-width input "Search students…" magnifier icon

STUDENT LIST (scrollable, 240px max height)
Each row: checkbox left + avatar + name + HSK chip
Pre-selected: 2 students checked (Navy checkbox fill)
Unselected: 3 students unchecked

DUE DATE ROW
Toggle: "Set due date" with switch (off by default)
When on: show date picker row inline "Dec 20, 2024" with calendar icon

ACTIONS (sticky bottom of sheet)
Left: "Cancel" secondary button
Right: "Assign to 2 students" primary Navy button (updates count dynamically)
```

---

### PROMPT D2 — Worksheet Import Progress Dialog

```
Design the Easy Study Worksheet Import Progress dialog. Modal overlay, 390px wide, auto height.

MODAL (white card, 16px radius, centered, 280px wide)
Scrim: 50% black behind

HEADER
Upload file icon 48px Teal
Title: "Reading worksheet…" 18px SemiBold
Filename: "HSK3_Grammar_Unit2.pdf" caption text secondary

PROGRESS
Linear progress bar: Teal fill, animated, 0–100%, 6px tall, full width, 8px radius

STEP CHECKLIST (3 steps, stacked with 12px gap)
Step 1: ✓ checkmark Success green + "Prepare file" strikethrough (completed)
Step 2: spinning loader Teal + "Read file" (in progress, active)
Step 3: circle outline + "Detect questions" (pending, text secondary)

No cancel button — processing is fast. Auto-closes on completion.
```

---

### PROMPT D3 — Import Review Dialog

```
Design the Easy Study Import Review dialog. Mobile 390x844px full screen (not a sheet).

APP BAR: Navy, × close icon left, title "Review import", "Import questions" primary button right (Navy, disabled until reviewed)

CONTENT (scrollable)

DETECTED TYPE CARD (white, soft teal border accent)
- Label: "Detected type" caption
- Value: "Multiple choice" 16px Bold + info icon
- HSK: "HSK 3 detected from title" caption Success green

EXTRACTED TEXT CARD (white)
- Label: "Extracted text — edit if needed"
- Editable textarea showing raw OCR text (monospace-style, Noto Sans SC for Chinese)
- Sample text: "1. 南方的天气很（ ）\nA. 热 B. 冷 C. 好 D. 大"
- "Re-analyze" Teal text button below textarea

QUESTION PREVIEW LIST (white card)
- Label: "Questions detected (3)"
- Each question row: Q number chip + question text + answer options preview in caption

WARNING BANNER (if applicable, soft orange tint card)
- ⚠ icon + "OCR may have missed some characters. Review Chinese text carefully." caption

BOTTOM: "Import 3 questions" Navy full-width button (sticky)
```

---

### PROMPT D4 — Confirm Dialogs

```
Design 3 Easy Study confirmation dialogs. Each as a 300x200px centered modal on 390x844px frame.

DIALOG 1 — Delete exercise
Title: "Delete exercise?" 16px Bold
Body: "This will also remove all student assignments. This cannot be undone."
Actions: "Cancel" secondary | "Delete" Error red primary

DIALOG 2 — Conclude class
Title: "Conclude this class?" 16px Bold
Body: "This will credit attendance and deduct one session from each student's term."
Student list: "Wang Fang, Li Ming, Ahmad (+1 more)" caption
Actions: "Cancel" secondary | "Conclude" Navy primary

DIALOG 3 — Add class term
Title: "Add class term" 16px Bold
Term size toggle: "8 sessions" | "16 sessions" pill toggle
Start date picker
End date picker
Actions: "Cancel" secondary | "Add term" Navy primary

All dialogs: white fill, 16px radius, centered modal, 50% black scrim, 20px padding.
```

---

---

## SECTION E — STUDENT TABS

### PROMPT E1 — Student Home Tab

```
Design the Easy Study Student Home tab. Mobile 390x844px. Bottom nav tab 0.

APP BAR: Navy, title "Easy Study", teal notification bell right

BOTTOM NAV: 5 tabs — Home (active), My Classes, Lessons, Progress, Profile

CONTENT (scrollable, Surface background)

1. GREETING HEADER (no card, inline)
   "Good morning, Li Ming 👋" Plus Jakarta Sans 22px Bold Navy
   HSK badge chip "HSK 3" inline Teal

2. JOIN CLASS CARD (white, Teal left accent border 4px)
   Row: live_tv icon Teal + "Class in progress" SemiBold
   Title: "HSK 3 — Speaking Practice"
   Time: "Started 5 min ago"
   "Join class" Teal primary button right side

3. ASSIGNED PRACTICE SECTION
   Section header: "Your practice" + "See all" Teal text link right
   
   Practice cards (horizontal scroll, 280px wide each):
   Card 1 — Due soon:
   "HSK 2 Grammar" title
   "Multiple choice · 5 questions" caption
   Due badge: "Due tomorrow" Error red chip
   Progress: 0% started, grey progress bar
   "Start" Teal button
   
   Card 2 — In progress:
   "Reading Practice" title
   "Compose sentences · 3 questions" caption
   Progress: 60% Teal bar
   "Continue" Navy button

4. CONTINUE LEARNING SECTION
   Section header: "Continue learning"
   Lesson card (full width, white):
   "Term 1 · Lesson 4" caption
   "Greetings & Introductions" 16px Bold
   Progress: "3 of 8 lessons done" + Teal progress bar
   "Continue →" Teal text button right
```

---

### PROMPT E2 — Student My Classes Tab

```
Design the Easy Study Student My Classes tab. Mobile 390x844px. Bottom nav tab 1.

APP BAR: Navy, title "My classes"

CONTENT (scrollable)

SECTION: "Upcoming"
Class card (white, 12px radius, border):
- Date pill: "Mon 23 Dec" Teal fill
- Title: "HSK 3 — Grammar Review" 16px SemiBold
- Time: "10:00 AM · 60 min" caption
- Teacher: person icon + "Teacher Name" caption
- "View details" Teal text button right

SECTION: "Past classes"
Past class card (same but muted): greyed title, "Concluded" Success chip, date in past
Show 2 past cards

EMPTY STATE (separate frame):
event_available icon 48px, "No classes joined yet" title, "Go to Home and tap Join on an open class session." subtitle
```

---

### PROMPT E3 — Student Lessons Tab

```
Design the Easy Study Student Lessons tab. Mobile 390x844px. Bottom nav tab 2.

APP BAR: Navy, title "Lessons"

CONTENT (scrollable)

ASSIGNED PRACTICE SECTION
Section header: "Assigned practice" + count chip "2"
Exercise assignment cards (white):
- Exercise title + type caption
- Due date chip if set: "Due Dec 20" soft red or "No due date" text secondary
- Status pill: "Not started" | "In progress" (Teal) | "Done" (Success)
- Score if done: "85%" Success green

LESSONS BY TERM SECTION
Term selector: "Term 1" (active, Navy) | "Term 2" pill toggle

Lesson list rows (white cards, stacked):
Each row:
- Lesson number circle: Navy fill white number (completed) or border only (incomplete)
- Lesson title 16px
- "Quiz" badge if has quiz: small Teal chip
- Status icon right: ✓ Success (done), → Teal (in progress), lock (not yet)
- Score if completed: "90%" caption Success green

Show 8 lessons, mix of completed (3), in progress (1), not started (4).

EMPTY STATE (separate frame):
menu_book icon, "No content yet", "Your teacher will assign exercises and publish lessons for your level."
```

---

### PROMPT E4 — Student Progress Tab

```
Design the Easy Study Student Progress tab. Mobile 390x844px. Bottom nav tab 3.

APP BAR: Navy, title "Progress"

CONTENT (scrollable)

1. TERM SUMMARY CARD (white, prominent)
   "Term 1" 20px Bold Navy
   Progress ring (circular, Teal, 80px): "5/8" center text
   Below ring: "Lessons completed" caption
   Stats row: "Average score: 82%" | "Quizzes taken: 5"

2. WEEKLY ACTIVITY (white card)
   Header: "This week"
   Bar chart: 7 days Mon–Sun, Teal bars for active days
   "3 lessons completed this week" caption

3. QUIZ HISTORY (white card)
   Section header: "Recent quizzes"
   Quiz result rows:
   - Lesson name
   - Score chip: "90%" Success | "55%" Error | "75%" Navy
   - Date caption "Dec 15"
   Show 4 rows

4. COMPLETED LESSONS (white card)
   Section header: "Completed"
   Lesson chips in wrap layout: "Lesson 1 ✓" "Lesson 2 ✓" etc. Navy fill white text, 6px radius

EMPTY STATE (separate frame):
trending_up icon, "No progress yet", "Complete a lesson or quiz to see your history here."
```

---

### PROMPT E5 — Student Profile Tab

```
Design the Easy Study Student Profile tab. Mobile 390x844px. Bottom nav tab 4.

APP BAR: Navy, title "Profile"

CONTENT (scrollable)

1. PROFILE HEADER CARD (white)
   Avatar 72px circle, Teal fill, initials
   Name: "Li Ming" 20px Bold
   HSK badge chip "HSK 3" Teal
   Email caption

2. CLASS TERM STATUS CARD (white)
   Section header: "Class term"
   Active term: "16 sessions" Navy chip + "6 remaining" SemiBold
   Progress bar: Teal 10/16 (62%)
   Date range: "Nov 1 – Dec 31, 2024" caption
   "Term ends in 32 days" warning caption if near end

3. ACCOUNT SECTION (white card, list rows)
   "Edit profile" → chevron
   "Help" → chevron

4. SIGN OUT
   "Sign out" Error red text button, centered
```

---

---

## SECTION F — STUDENT PUSHED SCREENS

### PROMPT F1 — Exercise Screen (Multiple Choice)

```
Design the Easy Study Exercise screen — Multiple Choice type. Mobile 390x844px.

APP BAR: Navy, back ←, title exercise name, progress "Q 2 of 5" right

CONTENT

PROGRESS BAR: Teal linear bar below app bar, 40% fill (Q2 of 5)

QUESTION CARD (white, 12px radius, prominent)
- Question number: "Question 2" caption Teal
- Question text (Noto Sans SC + Plus Jakarta Sans mixed): 
  "南方的天气很（ ）" 18px, centered
  Translation hint (optional): "Southern weather is very ___" 13px text secondary italic

ANSWER OPTIONS (4 cards, stacked, full width)
Each option card (white, border, 12px radius, 52px height):
- Left: letter pill "A" "B" "C" "D" — Navy fill white text 24px circle
- Right: option text — Noto Sans SC 16px
- Options: A. 热 B. 冷 C. 好 D. 大

SELECTED STATE variant:
Selected card: Teal border 2px + soft Teal background tint, letter pill Teal

CORRECT/INCORRECT STATE variants (show after tap):
Correct: Success green border + green checkmark, letter pill green
Incorrect: Error red border + red X on selected, correct answer highlighted in green

BOTTOM: "Next question →" primary Teal button, 48px, full width (sticky)
```

---

### PROMPT F2 — Exercise Screen (Compose Sentences)

```
Design the Easy Study Exercise screen — Compose Sentences (组词成句) type. Mobile 390x844px.

APP BAR: Navy, back ←, title "Compose sentences", "Q 1 of 3" right
PROGRESS BAR: Teal, 33%

INSTRUCTION BANNER (soft Surface card, icon left)
"Arrange the word segments into a correct sentence."

ANSWER ZONE (white card, dashed Teal border, 80px tall, 12px radius)
Shows arranged segments so far as chips inside zone.
Placeholder: "Tap segments below to add them here" in center, text secondary italic

WORD BANK (below, white card)
Label: "Word bank"
Segment chips (wrap layout, horizontal with wrap):
Each chip: white fill, Teal border, Noto Sans SC 16px Bold, 12px radius, 12px 16px padding
Segments: "南方的" · "夏天" · "热极了" (tappable — tap adds to answer zone)
Tapped/used chips: greyed out, opacity 40%, no border

CLEAR button: "Clear" text secondary button top right of answer zone

BOTTOM: "Check answer" Teal primary button, disabled until all chips placed
```

---

### PROMPT F3 — Exercise Screen (Matching)

```
Design the Easy Study Exercise screen — Matching (对话配对) type. Mobile 390x844px.

APP BAR: Navy, ← back, "Matching exercise", "Q 1 of 1" right

LAYOUT: Two-column layout within screen

LEFT COLUMN header: "Prompts" caption
RIGHT COLUMN header: "Answers" caption

PROMPTS (left, stacked cards 170px wide):
Card: white, border, 12px radius, 12px padding
Number circle "1" "2" "3" Navy fill
Prompt text below: "你叫什么名字？" Noto Sans SC 14px

ANSWERS (right, stacked cards 170px wide):
Card: white, border, 12px radius, 12px padding
Letter chip "A" "B" "C" Teal fill
Answer text: "我叫李明。" Noto Sans SC 14px

CONNECTION STATE: 
Show a connecting line from prompt 1 to answer B (Teal curved line)
Selected prompt: Navy border highlight
Selected answer: Teal border highlight

MATCHED STATE variant: 
Connected pair: both cards with Success green border, faint green fill

BOTTOM: "Check answers" Teal primary button
```

---

### PROMPT F4 — Lesson Detail Screen

```
Design the Easy Study Lesson Detail screen (student). Mobile 390x844px.

APP BAR: Navy, ← back, lesson title (truncated), "Lesson 4 / 8" caption right in white

CONTENT (scrollable)

LESSON HEADER (white card)
- Term label: "Term 1 · Lesson 4" Teal caption
- Title: "Greetings & Introductions" 22px Bold Navy
- HSK badge: "HSK 1" Teal chip
- Status chip: "In progress" or "Completed ✓" Success

LESSON CONTENT (white card, reading area)
Rich text content with mixed Latin + Chinese:
- Paragraph text 16px Plus Jakarta Sans
- Chinese vocabulary: "你好 (nǐ hǎo) — Hello" in Noto Sans SC, card with soft teal background
- "谢谢 (xièxie) — Thank you"
- "再见 (zàijiàn) — Goodbye"
Adequate line-height 1.5 for mixed scripts.

BOTTOM (sticky white bar)
"Start quiz →" Teal primary button, full width, 48px
Below: "5 questions · Takes about 3 minutes" caption text secondary centered
```

---

### PROMPT F5 — Quiz Screen

```
Design the Easy Study Quiz screen. Mobile 390x844px.

APP BAR: Navy, ← back, "Greetings Quiz", "Q 3 of 5" right

PROGRESS BAR: Teal, 60%

QUESTION CARD (white, 12px radius, prominent shadow-free)
- Caption: "Question 3 of 5"
- Question: "What does 谢谢 mean?" 18px SemiBold
- Chinese: "谢谢" Noto Sans SC 28px Bold Teal, centered below question

OPTIONS (4 stacked cards):
A. Thank you
B. Hello
C. Goodbye
D. Please
Each 52px card with letter pill + text, same as F1 exercise

SCORE SUMMARY SCREEN (separate frame — shown after submit)
Navy header with ✓ or ✗ icon
Score: "4 / 5" 48px Bold white
"80%" below in brand yellow
"Great work!" subtitle white
Below (white card, rounded top):
Results breakdown: each question row (Q1 ✓, Q2 ✗, etc.) with correct answer shown for wrong
"Back to lesson" secondary button
"View progress" Teal primary button
```

---

---

## SECTION G — STATES SCREENS

### PROMPT G1 — All Empty States

```
Design an Empty States reference sheet for Easy Study. Single Figma frame, grid layout.

Create 8 empty state components using the pattern: 48px icon (Text secondary #5C6370) + title (16px SemiBold Navy) + subtitle (14px Text secondary) + optional CTA. Surface #F5F6F8 background. Centered layout. 32px padding all sides.

1. No students (people_outline icon)
   "No students yet"
   "Students appear here after they register with your invite code."

2. No exercises (fitness_center icon)
   "No exercises yet"
   "Tap New exercise to create practice, then assign it to students."

3. No active classes (event icon)
   "No active classes"
   "Tap New class to create a session students can join."

4. No class history (history icon)
   "No class history yet"
   "Concluded classes appear here after you tap Conclude class."

5. No student classes (event_available icon)
   "No classes joined yet"
   "Go to Home and tap Join on an open class session."

6. No lessons (menu_book icon)
   "No content yet"
   "Your teacher will assign exercises and publish lessons for your level."

7. No progress (trending_up icon)
   "No progress yet"
   "Complete a lesson or quiz to see your history here."

8. Exercise coming soon (construction icon)
   "Exercise type coming soon"
   "This worksheet type is not available for students yet."
   No CTA.

Layout: 2-column grid, 8pt spacing, white card backgrounds for each, 12px radius.
```

---

### PROMPT G2 — Loading States

```
Design a Loading States reference sheet for Easy Study. Single Figma frame.

Show 4 loading screen variants, each 390x844px:

1. FULL SCREEN LOADING (shell / profile load)
   Surface #F5F6F8 background
   Navy app bar with title
   Center: CircularProgressIndicator teal, 40px, with caption "Loading…" text secondary below

2. LIST LOADING (students / exercises / classes)
   Same as above but content area shows 3 greyed-out skeleton cards (grey rectangles, 12px radius, animated shimmer implied)

3. BUTTON LOADING (submit / save)
   Show Teal primary button with small white spinner inside, button text hidden, button disabled state

4. WORKSHEET IMPORT LOADING
   Full modal dialog (from D2) in mid-progress state: step 2 "Read file" active with teal spinner
```

---

### PROMPT G3 — Error States

```
Design an Error States reference sheet for Easy Study. Single Figma frame.

Show 3 error patterns:

1. SNACKBAR ERROR (bottom of screen)
   Full 390x844 frame with any screen behind it (blur optional)
   Bottom snackbar: Error #B53A3A background, white text "Incorrect email or password", × dismiss icon right, 16px radius top corners, full width

2. INLINE FORM ERROR
   Input field with red border (Error #B53A3A, 1.5px), error icon right side
   Below input: Error red text "This field is required" 12px

3. IMPORT ERROR (on exercise form)
   Red-bordered card section (Error tint background, Error border):
   error_outline icon Error red 24px
   "Could not read file" SemiBold Error
   "The file may be corrupted or too large (max 15 MB). Try exporting as PDF or DOCX." caption
   "Try again" Teal text button below
```

---

---

## BONUS — PROMPT Z1 — App Icon

```
Design the Easy Study app icon. 1024x1024px frame, for App Store / Play Store.

Background: Black #000000 (matching logo background)
Center: Easy Study pencil mascot — yellow pencil body #F5B800, graduation cap on top in black/dark, teal pencil tip #006B54
Pencil should be at 45° angle, slight upward tilt (friendly, academic)
Corner radius when exported: 20% (for previewing as rounded icon)

Keep it bold and legible at small sizes (test at 60x60 and 120x120 within the frame).
No text — icon only.
```

---

---

*End of Easy Study Figma AI Prompt Set — v1.0*
*Generated from: APP_OVERVIEW.md · SCREEN_INVENTORY.md · FIGMA_AI_SPEC.md · WORKSHEET_IMPORT.md*
*Total: 25 prompts covering 14 screens, 10 tabs, 12+ dialogs, and all UI states*

---

---

## SECTION W — WEB DESKTOP KEY SCREENS
> These are the most layout-different screens on desktop. For all other screens, use the mobile prompt + Web Desktop suffix block from Prompt MP.

### PROMPT W1 — Web Desktop Shell (Teacher)

```
Design the Easy Study Teacher web desktop shell. Frame 1440x900px.

LEFT SIDEBAR (240px, Navy #1B2A4A, full height)
Top: Easy Study logo — pencil mascot + "Easy Study" white text, 20px padding, 24px from top
Below logo: Teacher name + "Teacher" role chip in muted white, 12px padding

NAV ITEMS (stacked, 52px height each, 8px horizontal margin, 8px radius)
Active item: Teal left border 3px + soft white 8% fill + white icon + white label
Inactive item: text secondary icon + label, no fill

Nav items:
- home icon "Dashboard" (active)
- people icon "Students"
- fitness_center icon "Exercises"
- event icon "Classes"
- person icon "Profile"

Bottom of sidebar: "Sign out" row with logout icon, Error red text, above bottom padding

MAIN CONTENT AREA (remaining 1200px, Surface #F5F6F8 background)
Top header bar (white, 64px, border-bottom #E2E5EB):
- Left: Page title "Dashboard" 20px Bold Navy
- Right: "Good morning, Teacher" 14px text secondary + avatar circle 36px Navy

CONTENT (40px padding, max 960px centered)
Show Teacher Dashboard content in 2-column grid:
Left column (600px): Needs Attention list (same cards as B1)
Right column (340px): Stats (3 stacked stat cards) + Weekly activity chart
```

---

### PROMPT W2 — Web Desktop Student List

```
Design the Easy Study Students page for web desktop. Frame 1440x900px.

Same sidebar shell as W1 but "Students" nav item active.

MAIN CONTENT AREA
Header bar: "Students" title left + "12 students" count chip Navy right

CONTENT (40px padding)
Search bar: 360px wide, left-aligned, white input, magnifier icon

STUDENT TABLE (white card, full width, 12px radius, border)
Table header row: Navy tint background, column labels Bold 13px
Columns: Name | HSK Level | Term Progress | Sessions | Last Active | Actions

Student rows (52px height, border-bottom between):
- Avatar 36px + Name 14px SemiBold
- HSK chip Teal "HSK 3"
- Progress bar 120px wide + "5/8" label
- Sessions pill "6 remaining"
- "Dec 15" date text secondary
- "View profile →" Teal text link

Alternating row background (white / Surface).
```

---

### PROMPT W3 — Web Desktop Exercise Form

```
Design the Easy Study Exercise Form for web desktop. Frame 1440x900px.

Same sidebar shell as W1, "Exercises" nav active.

MAIN CONTENT (40px padding, max 720px centered — form stays readable on wide screen)
Header: ← back link "Exercises" + title "New exercise" 24px Bold Navy + "Save draft" secondary button right + "Publish" Navy primary button right

TWO-COLUMN FORM LAYOUT (720px total)
Left column (440px): Main form fields
  - Exercise type dropdown
  - Title input
  - HSK level dropdown
  - Instructions textarea
  - Questions section (stacked question cards)
  - "Add question" button

Right column (260px, sticky): Sidebar panel
  White card, 12px radius, border:
  - "Import from worksheet" section (upload button + format list)
  - "Assign students" section (student count chip + "Manage" link)
  - "Published" / "Draft" status toggle
  - Due date picker

This right panel stays visible as the user scrolls the left form.
```

---

### PROMPT W4 — Web Desktop Student Home

```
Design the Easy Study Student Home page for web desktop. Frame 1440x900px.

LEFT SIDEBAR (240px, Navy) — student role
Nav items:
- home "Home" (active)
- event "My Classes"
- menu_book "Lessons"
- trending_up "Progress"
- person "Profile"

Bottom of sidebar: HSK badge chip "HSK 3" + "Li Ming" name + avatar

MAIN CONTENT (Surface background, 40px padding)
Header: "Good morning, Li Ming 👋" 28px Bold Navy + HSK chip

3-COLUMN GRID LAYOUT:

Column 1 (wide, ~560px): Assigned Practice
Section header "Your practice"
Practice cards (full width, white, stacked):
Same as E1 but full width, horizontal layout within card:
Left: icon + title + type caption
Center: progress bar
Right: due badge + action button

Column 2 (medium, ~320px): Join Class card + Continue Learning
Join class card (teal accent border, full width)
Below: Continue learning card

Right gutter: 40px padding

Bottom section (full width): Recent lessons grid 3-column
```

---

*End of Easy Study Figma AI Prompt Set — v1.1 (Multiplatform)*
*Platforms: iOS · Android · Web Desktop · Web Mobile*
*Total: 29 prompts — 14 screens · 10 tabs · 12+ dialogs · all UI states · 4 web desktop key screens*
