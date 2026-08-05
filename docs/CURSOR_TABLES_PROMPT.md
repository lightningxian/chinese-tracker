# Cursor prompt — reusable table widget + convert Payments / Vouchers / Grades

Two tasks: (1) extract the table already built inside `admin_users_tab.dart` into
a shared, reusable widget; (2) convert the Payments, Vouchers, and Grades tabs to
use it. **Visual/refactor only — no changes to data, queries, rules, routes, or
what any action does.** Keep every existing behavior (sorting, filtering, toggle
active, pay, create, score/edit/delete). Run `flutter analyze` after each step.

---

## Task 1 — Extract `AppDataTable`

Source of truth for the look/behavior: the private `_UsersTable`,
`_SortableHeaderCell`, `_UserTableRow` in
`lib/features/admin/admin_users_tab.dart` (navy-tinted header row, sortable header
cells with up/down arrows, striped rows, bottom borders, wrapped in `AppCard`
padding-zero + `ClipRRect`, and a mobile **card fallback** below 720px).

Create `lib/core/widgets/app_data_table.dart`:

```dart
class AppTableColumn<T> {
  final String id;                 // stable id used for sort state
  final String label;
  final double? width;             // fixed column width; null => flex
  final int flex;                  // used when width == null (default 1)
  final bool sortable;
  final Alignment alignment;       // header + cell alignment
  final Widget Function(T row) cell;
  const AppTableColumn({
    required this.id, required this.label, required this.cell,
    this.width, this.flex = 1, this.sortable = false,
    this.alignment = Alignment.centerLeft,
  });
}

class AppDataTable<T> extends StatelessWidget {
  final List<T> rows;
  final List<AppTableColumn<T>> columns;
  final String? sortColumnId;      // active sort column
  final bool sortAscending;
  final void Function(String columnId)? onSort;
  final void Function(T row)? onRowTap;
  final Widget Function(T row) mobileCardBuilder; // <720px fallback
  final double mobileBreakpoint;   // default 720
  // ...
}
```

Requirements:
- Header: reuse the tinted header + `_SortableHeaderCell` visuals; clicking a
  sortable header calls `onSort(column.id)` (parent owns the sort state, exactly
  like the Users tab does today).
- Rows: striped (odd rows tinted), bottom border, 12px vertical padding; render
  each column via `column.cell(row)`; respect fixed `width` vs `flex`.
- Below `mobileBreakpoint`, render `rows.map(mobileCardBuilder)` in a
  `ResponsiveCardGrid` instead of the table (same as Users today).
- Style strictly from `AppColors` / theme — no new hardcoded colors.

Then **refactor `admin_users_tab.dart` to use `AppDataTable`** (columns: Name,
Role, HSK, Joined, Status, Actions; mobile builder = the existing
`_UserMobileCard`). The Users tab must look and behave **identically** after the
refactor — this is the proof the extraction is faithful. Keep its sort/filter
state where it is.

## Task 2 — Convert three tabs

Reuse `StatusPill` / `StatusPills` (`lib/core/widgets/status_pill.dart`) for all
status cells. Preserve each tab's existing data source, actions, empty/loading
states, toolbars, and the mobile card fallback.

### 2a. Payments — `lib/features/admin/admin_invoices_tab.dart`
Model `Invoice`. Columns: **Invoice #** (`invoiceNumber`) · **Student**
(`studentName`) · **Package** (`packageSize` sessions) · **Amount**
(`amount`, format IDR) · **Due** (`dueDate`) · **Status** (`status` →
`StatusPill`: paid=success, pending=amber, expired/failed=error/grey). Keep the
existing "Create Invoice" toolbar/action.

### 2b. Vouchers — `lib/features/admin/admin_vouchers_tab.dart`
Model `StudentClassTerm`. Columns: **Code** (`voucherCode`) · **Student**
(resolved name — keep the current lookup) · **Package** (`packageSize`) ·
**Sessions left** (`sessionsRemaining`/`packageSize`) · **Deadline**
(`deadlineDate`) · **Status** (`status` → pill). Keep existing create/edit
actions.

### 2c. Grades — `lib/features/teacher/teacher_grades_tab.dart`
Model `Grade`. Keep the pending-vs-recorded split (two `AppDataTable`s, or one
with a Status column). Columns: **Student** (resolved name) · **Assessment**
(`title`) · **Category** (`category.label`) · **Score** (`score` or "—") ·
**Letter** (`letterGrade` / derived) · **Status** (`status` → pill) · **Date**
(`gradedAt ?? createdAt`) · **Actions** (score / edit / delete — unchanged).

## Guardrails
- No changes to Firestore queries, models, rules, functions, or routes.
- Every action keeps its current behavior and permission checks.
- Keep the responsive (<720px) card fallback on every converted tab.
- Don't hardcode colors/radii outside `AppColors` / theme / shared widgets.

## Acceptance
- `flutter analyze` clean.
- `AppDataTable` exists and is used by Users + the three converted tabs; no tab
  has its own bespoke table code anymore.
- Users tab is visually/behaviorally unchanged.
- Payments, Vouchers, and Grades render as sortable tables on desktop with the
  card fallback on mobile, statuses shown via `StatusPill`, all actions working.
- Append a summary to `docs/CURSOR_CHANGES_FOR_CLAUDE.md` (note anything you had
  to change beyond styling).
```
