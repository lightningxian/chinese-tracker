# Easy Study — Figma AI Update Prompt (compact)

Follow-up to FIGMA_AI_SPEC.md / FIGMA_UPDATED_V1.md. Apply these changes only.

## Roles: Admin, Guru, Murid (not Teacher/Student)

Guru tabs: Dashboard, Students (read-only), Classes (full session CRUD + attendance), Exercises (assign-only), Profile.

Admin tabs (new): Dashboard, Users (CRUD guru/murid, activate/deactivate), Exercises (full CRUD + OCR import — move from Guru), Classes (CRUD, cross-teacher view), Vouchers (CRUD, manual issuance only — no payment-proof UI), Reports, Profile.

Murid tabs: unchanged.

## New exercise type: Listening
Add "Listening (听力)" alongside MC / Compose sentences / Matching / Reading cloze / Picture+keyword.
Admin builder: audio upload (mp3/m4a) + waveform preview, prompt text, answer mode = MC or Typing (manual-review fallback toggle).
Murid taking screen: audio player (play/pause/scrub) + MC or typed-answer UI.
Add audio-load-failed error state.

## Notifications
Bell icon + unread badge, all roles. List screen: chronological, grouped by day, read/unread state, tap-through.
Variants: registration (approved / new-user alert), session reminder (upcoming class), grading complete (score).
No payment-notification variants.

## Admin Reports (new tab)
P0: new-students/month trend, income/month trend, active-student list (HSK filter), grade distribution (3-band rollup of HSK1-6).
P1: voucher/session balance (flag low-balance rows), exercise completion rate + avg score (per exercise/HSK).
Each report: empty + loading states.

## Out of scope — do not build
Payment confirmation UI (proof upload, admin queue). P2 reports (churn, item difficulty, revenue/HSK).
