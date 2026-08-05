# Easy Study — Setup Guide

## 1. Install Flutter

macOS (Homebrew):

```bash
brew install --cask flutter
flutter doctor
```

Enable web and one mobile platform:

```bash
flutter config --enable-web
```

## 2. Generate platform folders

From the project root:

```bash
cd ~/Projects/chinese-tracker
flutter create . --org com.chinesetracker --project-name chinese_tracker
flutter pub get
```

## 3. Firebase project

1. Go to [Firebase Console](https://console.firebase.google.com/) → **Create project**.
2. Enable **Authentication** → Email/Password.
3. Enable **Cloud Firestore** → Start in production mode, then deploy rules from `firestore.rules`.
4. Register apps: **Web**, **Android**, **iOS** (as needed).

Install FlutterFire and generate config:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

This overwrites `lib/firebase_options.dart` with real values.

## 4. Firestore indexes

When you first run queries, Firebase may show index URLs in the console. Create composite indexes for:

- `users`: `role` + `teacherId` + `name`
- `lessons`: `teacherId` + `order`

## 5. Run the app

```bash
flutter run -d chrome    # web
flutter run              # connected phone/emulator
```

## 6. Worksheet import (teachers)

On **web**, teachers can upload PDF, Word, or image worksheets when creating exercises. Text is read on-device and question types are detected automatically — no API keys or cloud OCR setup.

See [WORKSHEET_IMPORT.md](WORKSHEET_IMPORT.md).

## 7. First-time usage

1. **Register as Teacher** → note your **invite code** on Profile.
2. In Firestore, add a lesson (see `docs/SAMPLE_LESSON.md`).
3. **Register as Student** with the invite code.
4. Student opens **Lessons** → completes **Quiz**.

## 8. Development rules (temporary only)

If you hit permission errors while testing, you can temporarily use test mode in Firestore — **do not ship with open rules**.
