# Easy Study — App Overview

> **Product name:** Easy Study · **Repo:** `chinese-tracker`  
> Design tokens & Figma prompts: [design/FIGMA_AI_SPEC.md](design/FIGMA_AI_SPEC.md)

## What kind of app is this?

**Easy Study** is a **learning management and student progress app** built for **solo Chinese tutors** (or small teaching businesses). It combines:

- A **student portal** for lessons, quizzes, and homework-style practice
- A **teacher admin panel** for managing students, live classes, and assignments
- **Progress tracking** tied to HSK levels and lesson terms

Think of it as a lightweight LMS (Learning Management System) focused on **1-to-1 or small-group Chinese tutoring**, not a large school platform like Google Classroom or Canvas.

It runs as a **cross-platform Flutter app** on **web, iOS, and Android**, with **Firebase** handling login and cloud data storage.

---

## Who is it for?

| User | Purpose |
|------|---------|
| **Admin** | Manage users, vouchers, and platform reports; create and edit exercises (web only); oversee classes |
| **Teacher / tutor (Guru)** | Manage students, run live classes, **assign** practice (read-only exercise library), track who needs follow-up, export student PDFs |
| **Student (Murid)** | Join classes, complete lessons and quizzes, do assigned exercises, see progress |

The app uses **one codebase with three roles**. After login, each role sees a different shell and workflow.

---

## What problem does it solve?

Private Chinese tutors often juggle:

- Spreadsheets for student lists
- WhatsApp for class links and reminders
- Manual tracking of who paid for how many sessions
- Separate tools for quizzes and homework

Easy Study centralises this into one place:

1. **Students** know what to do next (lessons, assigned practice, live class join)
2. **Teachers** see progress, attendance, exercise scores, and who needs attention
3. **Session packages** (8 or 16 live classes) are tracked so billing and attendance stay aligned

---

## Core concepts

### HSK levels
Students register with an **HSK level** (HSK 1–6). Lessons and content can be filtered to match their level.

### Lesson terms
Students choose **8 or 16 lessons per term** at registration. Progress is organised by term so teachers and students can see how far through a block of lessons they are.

### Live class sessions
Teachers create **class sessions** (date, time, title). Students join from their home screen. When a class is **concluded**, it can deduct one session from the student’s **paid class term** package.

### Paid class terms
Teachers add **8- or 16-session packages** to a student profile with start and deadline dates. The app tracks **sessions remaining** and warns when a student is running low.

### Exercises (teacher-assigned practice)
Unlike lessons (which students browse by level), **exercises are assigned by the teacher** to specific students. Students only see practice their teacher has assigned to them.

Teachers can set an optional **due date** when assigning. Overdue or unfinished work appears on the teacher dashboard under **Needs attention**.

---

## Features by role

### Admin

| Area | What you can do |
|------|-----------------|
| **Dashboard** | Centre-wide stats, weekly activity, needs attention |
| **Users** | Create Murid/Guru accounts, edit profiles, activate/deactivate |
| **Exercises** | Create, edit, publish, delete exercises; **worksheet import** (web only); assign to students |
| **Classes** | Create and manage live sessions |
| **Vouchers** | View and manage all class term packages |
| **Reports** | Export platform PDFs (user roster, cohort summary, worksheet inventory) |

### Teacher (Guru)

| Area | What you can do |
|------|-----------------|
| **Dashboard** | Student count, weekly activity, **Needs attention** alerts (overdue practice, inactive students, low sessions) |
| **Students** | View all students, open profiles, manage paid class terms, see lesson progress by term, **export progress PDF** |
| **Exercises** | **View only** — browse published practice by HSK level and skill; **assign to students** (with search and optional due date) |
| **Classes** | Create and manage live sessions; add/remove students; conclude class and credit attendance |
| **Profile** | Share rotating **link code** for student registration (6 characters, refreshes every 15 minutes) |

### Student

| Area | What you can do |
|------|-----------------|
| **Home** | Join live class, **Continue learning** (assigned practice + next lesson) |
| **Lessons** | Assigned exercises + lessons grouped by term |
| **My classes** | View joined and past class sessions |
| **Progress** | Term progress, completed lessons, average quiz scores |
| **Profile** | Account info, class term status, sign out |

---

## Exercise types

Teachers choose an exercise type when creating practice (**admins on web only**). These match common HSK worksheet formats:

| Type | Worksheet example | Status |
|------|-------------------|--------|
| **Compose sentences (组词成句)** | Reorder word parts: `南方的 / 夏天 / 热极了` | Supported |
| **Matching (对话配对)** | Answer bank A–F + numbered prompts to match | Supported |
| **Multiple choice** | Standalone question + A/B/C/D options | Supported |
| **Reading cloze (选词填空)** | Passage with numbered blanks + word choices | Detected on import; editor coming soon |
| **Picture + keyword sentence** | Image + keyword (e.g. 页) → student writes a sentence | Detected on import; editor coming soon |

### Import from file

On the exercise form (**admin, web only**), tap **Choose file to upload** (PDF, DOCX, JPG, PNG). Processing runs **locally in the browser**:

1. **Read file** — PDF text layer, Word XML, or Tesseract OCR for scans/images  
2. **Detect questions** — parser picks compose / matching / multiple choice from worksheet layout  
3. **Review & import** — teacher edits text, then imports draft questions  

No Gemini, no API keys, no Firebase Functions. Details: [WORKSHEET_IMPORT.md](WORKSHEET_IMPORT.md).

Workflow: **Create → Publish → Assign to students → Student completes → Teacher sees results**

---

## Lessons and quizzes

- **Lessons** hold content (stored in Firestore; can be added manually or via scripts)
- Many lessons have an attached **quiz**; completing the quiz records a score and marks the lesson complete
- Student progress is saved per lesson (completed, score, date)

---

## Technology stack

| Layer | Choice |
|-------|--------|
| **Frontend** | Flutter 3.x / Dart |
| **Auth** | Firebase Authentication |
| **Database** | Cloud Firestore |
| **State & routing** | Provider, go_router |
| **UI** | Custom theme, Google Fonts |

### Main Firestore collections

- `users` — teacher and student profiles
- `lessons`, `quizzes` — learning content
- `exercises`, `exercise_assignments`, `exercise_results` — practice and scores
- `student_progress`, `quiz_results` — lesson completion
- `class_sessions`, `attendance` — live classes
- `student_class_terms` — paid session packages

---

## Typical workflows

### Teacher onboarding a new student
1. Student registers with HSK level and term size  
2. Teacher adds a **paid class term** (8 or 16 sessions) on the student profile  
3. Teacher **assigns exercises** and publishes lessons for that level  
4. Teacher creates **class sessions**; student joins from Home  

### Student study session
1. Open **Home** → see assigned practice or next lesson  
2. Complete an exercise or lesson + quiz  
3. Join a live class when scheduled  
4. Check **Progress** for term completion  

### Teacher weekly check-in
1. Open **Dashboard** → review **Needs attention**  
2. Tap a student → see **Practice results** and lesson progress  
3. Assign more work or add sessions if running low  

---

## What this app is *not*

- Not a marketplace for finding tutors  
- Not a video conferencing tool (it tracks classes; video would be external, e.g. Zoom)  
- Not a full content authoring studio (lesson editor in-app is limited; content can be managed in Firestore)  
- Not multi-teacher / multi-school at scale (designed around **one teacher** and their students)

---

## Summary

**Easy Study** is a **private tutoring operations app**: it helps a Chinese teacher **deliver lessons, assign practice, run live classes, and track student progress** in one place — with a student-friendly mobile/web experience and a teacher-focused admin side.

It fits **college projects**, **small teaching businesses**, and **solo tutors** who want something tailored to HSK-based Chinese learning rather than a generic LMS.

---

## Documentation

| Doc | Description |
|-----|-------------|
| [SETUP.md](SETUP.md) | Install Flutter, Firebase, run the app |
| [WORKSHEET_IMPORT.md](WORKSHEET_IMPORT.md) | Upload worksheets locally (no API keys) |
| [Screen inventory](screen-inventory/SCREEN_INVENTORY.md) | All screens, routes, tabs, and dialogs |
| [Figma AI spec](design/FIGMA_AI_SPEC.md) | Colors, typography, empty/loading states, branding |
| [Figma updated V.1](design/FIGMA_UPDATED_V1.md) | Screens & components to add in Figma |
| [SAMPLE_LESSON.md](SAMPLE_LESSON.md) | Example Firestore lesson data |
