# Cursor prompt — restyle Easy Study to the "LinguaHub" look

Restyle the app to match the reference design at
`https://film-haven-39247069.figma.site/` (a clean navy + white SaaS look). This
is a **visual restyle only — do not change any logic, routes, data, or rules.**
Keep every screen functional; only touch theme, shared shell/card/stat widgets,
and per-screen styling. Work in the shared widgets first so the look propagates,
then sweep screens. Run `flutter analyze` after each area.

## Design language (from the reference)
- **Layout:** left **sidebar** nav + top bar + light content area. Sidebar is
  white with a subtle right border; the **active** item is a solid dark-navy
  rounded pill with white text; inactive items are muted gray with an icon.
- **Top bar:** white; a small light-gray role chip on the left; on the right a
  notification bell and a circular avatar (initials) with name + role.
- **Cards:** white, radius **16px**, 1px light border (`AppColors.border`) with a
  very soft shadow, padding 20–24px. Calm, lots of whitespace.
- **Stat tiles:** muted label (top) · large bold number (28–32px) · small green
  delta/subtitle; a **soft-tinted rounded-square icon chip** (44px, radius 12) in
  the top-right. Tints: green/blue/purple/amber pastels.
- **Buttons:** primary = dark navy fill, white text, radius 10; secondary =
  outline. **Accent/positive = teal/green.**
- **Status pills:** soft pastel background + matching darker text, small radius.
- **Login:** split screen — left dark-navy panel (logo top-left, large white
  headline, muted subtitle, footer), right white panel with the form.
- **Type:** keep the existing `google_fonts` family; tighten weights (headings
  700–800, labels 500–600, muted body).

## Palette (reuse existing `AppColors`, add a few tokens)
Keep `navy #1B2A4A`, `teal #2D6A7E`, `surface #F5F6F8`, `card #FFFFFF`,
`textPrimary #1A1D26`, `textSecondary #5C6370`, `border #E2E5EB`,
`success #2E7D5A`. Add:
- `sidebarBg = #FFFFFF`, `sidebarActive = #14181F` (near-black navy pill),
  `pageBg = #F6F7F8`.
- Stat-chip tints (bg + fg): green `#E7F5EF/#2E7D5A`, blue `#E8F0FE/#2B5FB0`,
  purple `#F0EAFB/#6B4FBF`, amber `#FDF3E0/#B7791F`.

## Files to change (shared first)
1. `lib/core/theme/app_theme.dart` — extend `AppColors` with the tokens above;
   in `AppTheme.light()` set: scaffold bg = `pageBg`; `CardTheme` radius 16 +
   border; `FilledButton`/`OutlinedButton` radius 10, navy primary; `AppBarTheme`
   flat white; input fields soft-filled, radius 10.
2. `lib/core/widgets/app_shell.dart` — the sidebar + top bar: white sidebar,
   dark-navy **active pill**, muted inactive items, top-bar role chip + bell +
   avatar. This drives admin/teacher/student/parent shells.
3. `lib/core/widgets/app_card.dart` — radius 16, 1px border, soft shadow, padding.
4. **New** `lib/core/widgets/stat_card.dart` — a reusable stat tile (label, value,
   delta, tinted icon chip). Replace the ad-hoc stat cards in
   `admin_dashboard_widgets.dart`, `teacher_dashboard_tab.dart`,
   `student_home_tab.dart`, `parent_overview_tab.dart`, and the payments/grades
   summaries so they all use it.
5. `lib/core/widgets/status_pill.dart` — soft pastel pills for statuses
   (invoice paid/pending/overdue, class open/draft, grade letters, etc.).
6. `lib/features/auth/login_screen.dart` + `lib/core/widgets/auth_scaffold.dart`
   — split-screen login (dark-navy left, white form right). Apply the same to
   `register_screen.dart` and `test_login_screen.dart`.
7. `lib/features/landing/landing_screen.dart` — already navy/teal; align card
   radius, buttons, and stat styling to the new tokens.

## Rules
- **No logic/route/model/rules changes.** If a widget's constructor must change,
  keep behavior identical.
- Centralize: don't hardcode colors/radii per screen — use `AppColors` + the
  shared widgets so it stays consistent and easy to tweak.
- Keep it responsive (the app runs on web + mobile): sidebar collapses to a
  bottom nav or drawer on narrow widths, as it does today.
- Preserve the Easy Study logo/brand marks; this is a reskin, not a rebrand.

## Acceptance
- `flutter analyze` clean; every screen still works.
- All four shells share the new sidebar/top-bar look with a dark active pill.
- Dashboards use one shared `StatCard` with tinted icon chips.
- Login is the split-screen navy/white layout.
- No color or radius is hardcoded outside `AppColors`/`AppTheme`/shared widgets.
