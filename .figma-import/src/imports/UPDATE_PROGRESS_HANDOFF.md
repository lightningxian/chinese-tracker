# Easy Study — Compact Update Progress & Handoff

Tracks the `FIGMA_AI_PROMPT_UPDATE_COMPACT.md` work. All edits are in `/src/app/App.tsx`.

**Status: ✅ ALL 6 items from the compact update are DONE and compiling.**

---

## ✅ DONE (this version)

### 1. Roles: Admin / Guru / Murid
- `type Role = "admin" | "guru" | "murid"` + `ROLE_LABEL` map (Teacher→Guru, Student→Murid).
- `USER_BY_ROLE` map (name, initials, accent, hsk). Admin accent = `#7A4FBF`.
- **Auth test login** shows 3 role cards (Admin / Guru / Murid). Register modes renamed `register-guru` / `register-murid`.
- `AuthScreen`, `fakeLogin`, `CompleteProfileScreen` all take `Role`.
- **Sidebar** non-generic, reads role from `USER_BY_ROLE`; role-switch cycles admin→guru→murid.
- **TopBar** takes `role` + `unread` + `onBell`; numeric unread badge on the bell.
- Nav sets: `guruNav`, `muridNav`, `adminNav`.
- Root `App`: `adminTab/guruTab/muridTab` state, generic `nav`/`setTab`/`activeTab`, `adminContent`/`guruContent`/`muridContent`. Mobile bottom nav horizontally scrolls for Admin's 7 tabs.

### 2. Guru tab restructure
- **Exercises assign-only**: `TeacherExercises` has `fullCrud` prop. Guru = assign-only (info banner, no New/Edit/Delete). Admin passes `fullCrud`.
- **Classes + attendance**: `ClassDetailScreen` has `canAttendance` prop → Present/Absent toggles per roster row, locked summary once concluded. Wired for guru + admin.
- `TeacherClasses` accepts `crossTeacher` (admin passes; cosmetic for now).

### 3. Listening (听力) exercise type — FULL
- Added to exercise mock data (id 5) and `typeDesc`.
- **Admin builder**: audio upload card, 48-bar waveform preview, answer-mode toggle (MC / Typing), manual-review fallback toggle, prompt text. Generic Questions card hidden when Listening.
- **Murid player**: play/pause button, scrubber, time labels, volume icon, MC answer cards, submit/next flow.
- **Audio-load-failed error state**: red card + Retry; "Simulate load error" affordance to demo it.

### 4. Notifications (all roles)
- `notifications` mock data (kinds: registration / session / grading; title, body, day, time, read).
- `Screen` type `{ type: "notifications" }`; `openNotifications()` clears unread + pushes screen; bell wired in TopBar (desktop) and mobile app bar.
- **`NotificationsScreen`**: PushedBar, grouped by day (Today / Yesterday / Dec 20), kind icons (registration=UserCheck, session=Calendar, grading=Award), unread teal dot + tap-through rows, empty state.
- No payment-notification variants (per scope).

### 5. Admin tabs
- **`AdminDashboard`**: 4 stat cards (users, active murid, exercises, income/mo), new-students/month bar chart, needs-attention voucher alerts, quick actions.
- **`AdminUsers`**: searchable table (Name/email, Role, Joined, Status) + per-row Activate/Deactivate toggle + New user button. Guru + Murid CRUD affordances.
- **`AdminVouchers`**: table with status pills (active / low / depleted / unissued), low+depleted rows flagged (tinted), manual-issuance modal (package + assign to murid). **No payment-proof UI.**
- **Exercises/Classes**: reuse `TeacherExercises fullCrud` + `TeacherClasses crossTeacher`.
- **Profile**: reuses `TeacherProfile` with `roleLabel="Admin"` (hides invite code).

### 6. Admin Reports tab — `AdminReports`
- **P0**: new-students/month bar, income/month bar, 3-band grade distribution (Beginner HSK1–2 / Intermediate HSK3–4 / Advanced HSK5–6), active-student list with HSK filter pills.
- **P1**: voucher/session balance list (low-balance rows flagged), exercise completion-rate + avg-score bars per exercise.
- **Loading state**: spinner on Refresh. **Empty state**: on filtered active-student list.
- Charts use `fill`-on-data pattern (no `<Cell>`).

---

## 🧭 Where things live (for next session)
- Data: mock arrays near top of `App.tsx` — `students`, `exercises` (Listening = id 5), `classes`, `adminUsers`, `vouchers`, `monthlyStudents`, `monthlyIncome`, `notifications`.
- Screens/dialogs registered in `renderPushed` inside `App`.
- Tab routing: `adminContent` / `guruContent` / `muridContent` in `App`.
- Shared atoms: `Card`, `SectionHeader`, `StatusPill`, `Avatar`, `EmptyState`, `NavyBtn`, `TealBtn`, `OutlineBtn`, `Modal`, `PushedBar`, `HskBadge`, `InputField`, `Snackbar`, `Ring`.

## Conventions
- Colors: NAVY `#1B2A4A`, TEAL `#2D6A7E`, admin purple `#7A4FBF`, SUCCESS `#2E7D5A`, ERROR `#B53A3A`, YELLOW `#F5B800`, SURFACE `#F5F6F8`, BORDER `#E2E5EB`.
- **Charts must NOT use `<Cell>`** (removed) — put a `fill` key on each datum instead.
- Chinese text → `fontFamily: "'Noto Sans SC', sans-serif"`.
- Cards: 12px radius, 1px border, no shadow.

---

## 💡 Candidate next-version work (not yet built — for you to prioritize)
Everything below is **frontend-only mock right now**; nothing is backend-wired.

- **Backend integration** — replace all mock arrays with API calls; real auth/session providing role, name, HSK, invite code. (See `EasyStudy_Build_Summary.md` for suggested endpoints.)
- **Listening — Typing answer mode player**: builder toggle exists, but Murid player only renders MC. Add a typed-answer textarea + manual-review "pending" state.
- **Admin Users CRUD depth**: New user / Edit modals are affordances only — wire actual add/edit forms + confirm-delete.
- **Voucher issuance**: modal is UI-only — persist issued vouchers, generate codes, deduct on class conclude.
- **Attendance persistence**: Present/Absent selections aren't saved on conclude — connect to session/voucher deduction.
- **Reports P1 realism**: completion-rate/avg values are derived from `id` math — replace with real per-exercise stats.
- **Notifications**: tap-through is a no-op — route each kind to its target (student detail / class detail / quiz score). Add per-item read persistence.
- **Cross-teacher class view (Admin)**: `crossTeacher` prop is passed but cosmetic — show owning-guru column/filter.
- **Guru Students read-only confirmation**: currently a table; confirm no edit paths leak in.
- **Mobile polish**: Admin's 7-tab bottom nav scrolls horizontally — consider a "More" overflow menu.

## Explicitly OUT OF SCOPE (do not build)
Payment confirmation UI (proof upload, admin approval queue). P2 reports (churn, item difficulty, revenue/HSK).
