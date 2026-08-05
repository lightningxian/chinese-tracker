# Easy Study

Professional Flutter app for your Chinese teaching business: track students, monitor progress, and deliver lessons with quizzes — on **web, Android, and iOS**.

> Product name: **Easy Study** · Repo folder: `chinese-tracker`

## Features

- **One app, three roles** — Admin, Guru (teacher), and Murid (student) shells
- **Admin** — users, vouchers, platform reports, exercise authoring (web)
- **Teacher** — dashboard, student list, assign practice (read-only exercise library), live classes, rotating link codes
- **Student** — home, lessons by HSK level & term, quizzes, progress history
- **HSK 1–6** — students register with an HSK level
- **8 or 16 lessons per term** — students choose term size at registration
- **Teacher link codes** — 6-character codes, refresh every 15 minutes; students enter code when registering
- **Firebase** — Auth, Firestore, and Cloud Functions (link-code resolution + registration notifications)

## Project location

```
~/Projects/chinese-tracker
```

## Quick start

Flutter is not bundled with this repo. On your Mac:

```bash
cd ~/Projects/chinese-tracker
flutter create . --org com.chinesetracker --project-name chinese_tracker
flutter pub get
flutterfire configure
```

### Deploy the backend

Firestore rules + Cloud Functions must be deployed for registration to work
(the app resolves teacher link codes via the `resolveLinkCode` function).
Cloud Functions require the Firebase **Blaze** plan.

```bash
cd ~/Projects/chinese-tracker/functions && npm install && cd ..
firebase deploy --only firestore:rules,functions
```

See [docs/FIREBASE_BACKEND.md](docs/FIREBASE_BACKEND.md) for the function/rule details.

## Quick login buttons (optional, for faster testing)

If you set demo credentials at run time, the login screen will show **1-click** buttons.

```bash
cd ~/Projects/chinese-tracker
flutter run -d chrome \
  --dart-define=DEMO_TEACHER_EMAIL="your-teacher@email.com" \
  --dart-define=DEMO_TEACHER_PASSWORD="your-password" \
  --dart-define=DEMO_STUDENT_EMAIL="your-student@email.com" \
  --dart-define=DEMO_STUDENT_PASSWORD="your-password"
```

Full steps: [docs/SETUP.md](docs/SETUP.md)

Worksheet import (local scan, no API keys): [docs/WORKSHEET_IMPORT.md](docs/WORKSHEET_IMPORT.md)

Figma / design spec: [docs/design/FIGMA_AI_SPEC.md](docs/design/FIGMA_AI_SPEC.md)

Sample lesson data: [docs/SAMPLE_LESSON.md](docs/SAMPLE_LESSON.md)

## Open in Cursor

**File → Open Folder** → `~/Projects/chinese-tracker`

## Roadmap (before August)

| Week | Goal |
|------|------|
| 1 | Firebase + run app + teacher/student register |
| 2 | Add 2–3 lessons + quizzes in Firestore |
| 3 | Polish UI, test on phone + web |
| 4 | Assignment docs + demo video |

## Stack

- Flutter 3.x / Dart
- Firebase Auth, Cloud Firestore
- Provider, go_router, google_fonts

## License

Private — college & business use.
