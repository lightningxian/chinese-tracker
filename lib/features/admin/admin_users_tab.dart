import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_data_table.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/table_tools.dart';
import '../../l10n/l10n.dart';
import '../../l10n/labels_admin.dart';
import '../../models/app_user.dart';
import '../../services/firestore_service.dart';
import 'admin_dashboard_widgets.dart';

/// Users table. Click a student's row to open their page (`/admin/users/:id`);
/// other roles open the edit form. Rows can be ticked to activate, deactivate
/// or set the HSK level in one go, and the list exports to CSV.
class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _roleFilter;
  String? _statusFilter;
  _UserSortColumn _sortColumn = _UserSortColumn.name;
  bool _sortAscending = true;

  /// Uids ticked in the table.
  Set<String> _selected = {};
  bool _busy = false;

  List<String> _csvHeader(AppLocalizations l) => [
        l.adminUsersColName,
        l.identityNameChinese,
        l.commonEmail,
        l.adminUsersColRole,
        l.adminUsersColHsk,
        l.adminUsersColWhatsapp,
        l.identityParentName,
        l.adminUsersColParentPhone,
        l.attendanceJoined,
        l.profileWidgetStatus,
      ];

  List<Object?> _csvRow(AppLocalizations l, AppUser user) => [
        user.displayNameIndonesian,
        user.displayNameChinese ?? '',
        user.email,
        _roleLabel(l, user),
        user.isStudent ? (user.level ?? '') : '',
        user.displayWhatsapp ?? '',
        user.parentName ?? '',
        user.parentPhone ?? '',
        user.createdAt == null
            ? ''
            : DateFormat('yyyy-MM-dd').format(user.createdAt!),
        user.active ? l.historyStatusActive : l.profileWidgetInactive,
      ];

  static const _toolbarFieldHeight = 48.0;
  static const _colRoleWidth = 104.0;
  static const _colHskWidth = 88.0;
  static const _colJoinedWidth = 128.0;
  static const _colStatusWidth = 84.0;
  static const _colActionsWidth = 232.0;

  Map<String?, String> _roleFilterOptions(AppLocalizations l) => {
        null: l.adminUsersAllRoles,
        AppConstants.roleAdmin: l.adminUsersRoleAdmin,
        AppConstants.roleTeacher: l.adminUsersRoleTeacher,
        AppConstants.roleStudent: l.adminUsersRoleStudent,
        AppConstants.roleParent: l.adminUsersRoleParent,
      };

  Map<String?, String> _statusFilterOptions(AppLocalizations l) => {
        null: l.adminUsersAllStatus,
        'active': l.historyStatusActive,
        'inactive': l.profileWidgetInactive,
      };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _roleLabel(AppLocalizations l, AppUser user) => user.roleLocalized(l);

  Color _roleColor(AppUser user) {
    if (user.isAdmin) return adminPurple;
    if (user.isTeacher) return AppColors.navy;
    return AppColors.teal;
  }

  String _joinedLabel(AppUser user) {
    final created = user.createdAt;
    if (created == null) return '—';
    return DateFormat('MMM d, yyyy').format(created);
  }

  String _hskLabel(AppUser user) {
    if (!user.isStudent) return '—';
    return user.level ?? '—';
  }

  List<AppUser> _filter(AppLocalizations l, List<AppUser> users) {
    var result = users;

    if (_roleFilter != null) {
      result = result.where((user) => user.role == _roleFilter).toList();
    }

    if (_statusFilter == 'active') {
      result = result.where((user) => user.active).toList();
    } else if (_statusFilter == 'inactive') {
      result = result.where((user) => !user.active).toList();
    }

    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((user) {
        return user.name.toLowerCase().contains(q) ||
            user.email.toLowerCase().contains(q) ||
            _roleLabel(l, user).toLowerCase().contains(q);
      }).toList();
    }

    return _sortUsers(l, result);
  }

  int _roleSortOrder(AppUser user) {
    return switch (user.role) {
      AppConstants.roleAdmin => 0,
      AppConstants.roleTeacher => 1,
      AppConstants.roleParent => 2,
      _ => 3,
    };
  }

  List<AppUser> _sortUsers(AppLocalizations l, List<AppUser> users) {
    final sorted = [...users];
    sorted.sort((a, b) {
      int compare;
      switch (_sortColumn) {
        case _UserSortColumn.name:
          compare = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case _UserSortColumn.role:
          compare = _roleSortOrder(a).compareTo(_roleSortOrder(b));
          if (compare == 0) {
            compare = _roleLabel(l, a).compareTo(_roleLabel(l, b));
          }
        case _UserSortColumn.joined:
          final aDate = a.createdAt;
          final bDate = b.createdAt;
          if (aDate == null && bDate == null) {
            compare = 0;
          } else if (aDate == null) {
            compare = 1;
          } else if (bDate == null) {
            compare = -1;
          } else {
            compare = aDate.compareTo(bDate);
          }
        case _UserSortColumn.status:
          compare = (a.active == b.active)
              ? a.name.toLowerCase().compareTo(b.name.toLowerCase())
              : (a.active ? -1 : 1);
      }
      return _sortAscending ? compare : -compare;
    });
    return sorted;
  }

  void _toggleSort(_UserSortColumn column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }
    });
  }

  void _onSortById(String columnId) {
    final column = _UserSortColumn.values.firstWhere(
      (item) => item.name == columnId,
      orElse: () => _sortColumn,
    );
    _toggleSort(column);
  }

  /// Student rows open the student page; staff and parents open the form.
  void _openUser(AppUser user) {
    if (user.isStudent) {
      context.push('/admin/users/${user.uid}');
    } else if (!user.isAdmin) {
      context.push('/admin/users/${user.uid}/edit');
    }
  }

  /// Ticked users still in the list; admin accounts never take bulk actions.
  List<AppUser> _selectedUsers(List<AppUser> users) => [
        for (final u in users)
          if (_selected.contains(u.uid) && !u.isAdmin) u,
      ];

  Future<void> _runBulk(Future<void> Function() action, String done) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(done)));
      if (mounted) setState(() => _selected = {});
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _bulkSetActive(List<AppUser> picked, bool active) {
    final firestore = context.read<FirestoreService>();
    final l = context.l10n;
    final n = picked.length;
    return _runBulk(
      () => firestore.setUsersActive([for (final u in picked) u.uid], active),
      active ? l.adminUsersActivated(n) : l.adminUsersDeactivated(n),
    );
  }

  Future<void> _bulkSetLevel(List<AppUser> students) async {
    final l = context.l10n;
    var level = students.first.level ?? AppConstants.hskLevels.first;
    final chosen = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l.adminUsersHskDialogTitle(students.length)),
          content: DropdownButtonFormField<String>(
            initialValue: level,
            isExpanded: true,
            items: [
              for (final hsk in AppConstants.hskLevels)
                DropdownMenuItem(value: hsk, child: Text(hsk)),
            ],
            onChanged: (v) {
              if (v != null) setDialogState(() => level = v);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, level),
              child: Text(l.adminUsersApply),
            ),
          ],
        ),
      ),
    );
    if (chosen == null || !mounted) return;
    final firestore = context.read<FirestoreService>();
    await _runBulk(
      () => firestore.setUsersLevel(
        [for (final u in students) u.uid],
        chosen,
      ),
      l.adminUsersLevelSet(students.length, chosen),
    );
  }

  Widget _selectionBar(AppLocalizations l, List<AppUser> users) {
    final picked = _selectedUsers(users);
    final students = picked.where((u) => u.isStudent).toList();
    return TableSelectionBar(
      count: picked.length,
      onClear: () => setState(() => _selected = {}),
      actions: [
        SelectionActionButton(
          label: l.adminUsersActivate,
          icon: Icons.check_circle_outline,
          onPressed: _busy ? null : () => _bulkSetActive(picked, true),
        ),
        SelectionActionButton(
          label: l.adminUsersDeactivate,
          icon: Icons.block_outlined,
          onPressed: _busy ? null : () => _bulkSetActive(picked, false),
        ),
        SelectionActionButton(
          label: students.isEmpty
              ? l.adminUsersSetHskLevel
              : l.adminUsersSetHskLevelCount(students.length),
          icon: Icons.signal_cellular_alt_outlined,
          onPressed:
              _busy || students.isEmpty ? null : () => _bulkSetLevel(students),
        ),
      ],
    );
  }

  /// One chip per role with its count; the selected chip filters the table.
  Widget _roleTabs(AppLocalizations l, List<AppUser> allUsers) {
    final counts = <String?, int>{null: allUsers.length};
    for (final user in allUsers) {
      counts[user.role] = (counts[user.role] ?? 0) + 1;
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final entry in _roleFilterOptions(l).entries)
          ChoiceChip(
            label: Text('${entry.value} (${counts[entry.key] ?? 0})'),
            selected: _roleFilter == entry.key,
            onSelected: (_) => setState(() {
              _roleFilter = entry.key;
              _selected = {};
            }),
          ),
      ],
    );
  }

  /// "Parent: Ibu Santoso" under a student, the children under a parent.
  String? _relationLabel(
    AppLocalizations l,
    AppUser user,
    List<AppUser> allUsers,
  ) {
    if (user.isParent) {
      final children = [
        for (final id in user.studentIds)
          for (final u in allUsers)
            if (u.uid == id) u.name,
      ];
      if (children.isEmpty) return l.adminUsersNoChildLinked;
      final shown = children.take(3).join(', ');
      final more = children.length - 3;
      return more > 0
          ? l.adminUsersChildrenMore(shown, more)
          : l.adminUsersChildren(children.length, shown);
    }
    if (user.isStudent) {
      for (final u in allUsers) {
        if (u.isParent && u.studentIds.contains(user.uid)) {
          return l.adminUsersParentOf(u.name);
        }
      }
    }
    return null;
  }

  List<AppTableColumn<AppUser>> _buildColumns(
    BuildContext context,
    List<AppUser> allUsers,
  ) {
    final l = context.l10n;
    final metaStyle = TextStyle(
      fontSize: 12,
      color: AppColors.textSecondary,
    );

    return [
      AppTableColumn<AppUser>(
        id: _UserSortColumn.name.name,
        label: l.adminUsersColName,
        sortable: true,
        cell: (user) => _UserNameCell(
          user: user,
          roleColor: _roleColor(user),
          detail: _relationLabel(l, user, allUsers),
        ),
      ),
      AppTableColumn<AppUser>(
        id: _UserSortColumn.role.name,
        label: l.adminUsersColRole,
        sortable: true,
        width: _colRoleWidth,
        cell: (user) => _RolePill(
          label: _roleLabel(l, user),
          color: _roleColor(user),
        ),
      ),
      AppTableColumn<AppUser>(
        id: 'hsk',
        label: l.adminUsersColHsk,
        width: _colHskWidth,
        cell: (user) => Text(
          _hskLabel(user),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: metaStyle,
        ),
      ),
      AppTableColumn<AppUser>(
        id: _UserSortColumn.joined.name,
        label: l.attendanceJoined,
        sortable: true,
        width: _colJoinedWidth,
        cell: (user) => Text(
          _joinedLabel(user),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: metaStyle,
        ),
      ),
      AppTableColumn<AppUser>(
        id: _UserSortColumn.status.name,
        label: l.profileWidgetStatus,
        sortable: true,
        width: _colStatusWidth,
        cell: (user) => Text(
          user.active ? l.historyStatusActive : l.profileWidgetInactive,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: user.active ? AppColors.success : AppColors.textSecondary,
          ),
        ),
      ),
      AppTableColumn<AppUser>(
        id: 'actions',
        label: l.adminUsersColActions,
        width: _colActionsWidth,
        alignment: Alignment.centerRight,
        cell: (user) => user.isAdmin
            ? const SizedBox.shrink()
            : _UserActionsBar(
                active: user.active,
                onEdit: () => context.push('/admin/users/${user.uid}/edit'),
                onToggleActive: () => _toggleActive(user),
                onDelete: () => _deleteAccount(user),
                compact: true,
              ),
      ),
    ];
  }

  /// Removes the login and the profile for good (Cloud Function
  /// `deleteUserAccount`); results, invoices and attendance stay as records.
  Future<void> _deleteAccount(AppUser user) async {
    final l = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.adminUsersDeleteTitle(user.displayNameIndonesian)),
        content: Text(l.adminUsersDeleteBody(user.email)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(l.adminUsersDeleteAccount),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await FirebaseFunctions.instance
          .httpsCallable('deleteUserAccount')
          .call({'uid': user.uid});
      messenger.showSnackBar(
        SnackBar(content: Text(l.adminUsersDeleted(user.email))),
      );
    } on FirebaseFunctionsException catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.message ?? l.adminUsersDeleteFailed),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _toggleActive(AppUser user) async {
    try {
      await context.read<FirestoreService>().setUserActive(
            userId: user.uid,
            active: !user.active,
          );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 720;
    final l = context.l10n;

    return StreamBuilder<List<AppUser>>(
      stream: context.read<FirestoreService>().watchAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                l.adminUsersLoadFailed('${snapshot.error}'),
                style: TextStyle(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final allUsers = snapshot.data ?? [];
        final users = _filter(l, allUsers);

        return ListView(
          padding: EdgeInsets.all(isWide ? 32 : 20),
          children: [
            _toolbar(context, isWide, users),
            const SizedBox(height: 12),
            _roleTabs(l, allUsers),
            const SizedBox(height: 12),
            _selectionBar(l, users),
            if (users.isEmpty)
              AppCard(
                child: Text(
                  snapshot.data?.isEmpty ?? true
                      ? l.adminUsersEmpty
                      : l.adminUsersNoMatch,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              )
            else
              AppDataTable<AppUser>(
                rows: users,
                columns: _buildColumns(context, allUsers),
                sortColumnId: _sortColumn.name,
                sortAscending: _sortAscending,
                onSort: _onSortById,
                onRowTap: _openUser,
                rowKey: (user) => user.uid,
                selectedKeys: _selected,
                onSelectionChanged: (keys) => setState(() => _selected = keys),
                mobileCardBuilder: (user) => _UserMobileCard(
                  user: user,
                  onOpen: user.isStudent ? () => _openUser(user) : null,
                  roleLabel: _roleLabel(l, user),
                  roleColor: _roleColor(user),
                  joinedLabel: _joinedLabel(user),
                  hskLabel: _hskLabel(user),
                  onToggleActive: () => _toggleActive(user),
                  onDelete: () => _deleteAccount(user),
                  onEdit: () => context.push('/admin/users/${user.uid}/edit'),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _toolbar(BuildContext context, bool isWide, List<AppUser> users) {
    final l = context.l10n;
    final exportButton = SizedBox(
      height: _toolbarFieldHeight,
      child: ExportCsvButton(
        fileStem: 'users',
        header: _csvHeader(l),
        rows: () => users.map((user) => _csvRow(l, user)).toList(),
      ),
    );

    final statusFilter = SizedBox(
      width: isWide ? 148 : null,
      height: _toolbarFieldHeight,
      child: _FilterDropdown<String?>(
        label: l.profileWidgetStatus,
        value: _statusFilter,
        items: _statusFilterOptions(l),
        onChanged: (value) => setState(() => _statusFilter = value),
      ),
    );

    final newUserButton = SizedBox(
      height: _toolbarFieldHeight,
      child: FilledButton.icon(
        onPressed: () => context.push('/admin/users/new'),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.navy,
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        icon: const Icon(Icons.add, size: 18),
        label: Text(l.adminUsersNewUser),
      ),
    );

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: SizedBox(
              height: _toolbarFieldHeight,
              child: _searchField(),
            ),
          ),
          const SizedBox(width: 12),
          statusFilter,
          const SizedBox(width: 12),
          exportButton,
          const SizedBox(width: 12),
          newUserButton,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: SizedBox(
                height: _toolbarFieldHeight,
                child: _searchField(),
              ),
            ),
            const SizedBox(width: 12),
            newUserButton,
          ],
        ),
        const SizedBox(height: 12),
        statusFilter,
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: _toolbarFieldHeight,
                child: _SortDropdown(
                  sortColumn: _sortColumn,
                  sortAscending: _sortAscending,
                  onChanged: (column, ascending) => setState(() {
                    _sortColumn = column;
                    _sortAscending = ascending;
                  }),
                ),
              ),
            ),
            const SizedBox(width: 12),
            exportButton,
          ],
        ),
      ],
    );
  }

  Widget _searchField() {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _query = value),
      decoration: InputDecoration(
        hintText: context.l10n.adminUsersSearchHint,
        prefixIcon: const Icon(Icons.search, size: 20),
        filled: true,
        fillColor: AppColors.card,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}

enum _UserSortColumn { name, role, joined, status }

extension on _UserSortColumn {
  String label(AppLocalizations l) => switch (this) {
        _UserSortColumn.name => l.adminUsersColName,
        _UserSortColumn.role => l.adminUsersColRole,
        _UserSortColumn.joined => l.attendanceJoined,
        _UserSortColumn.status => l.profileWidgetStatus,
      };
}

class _SortDropdown extends StatelessWidget {
  const _SortDropdown({
    required this.sortColumn,
    required this.sortAscending,
    required this.onChanged,
  });

  final _UserSortColumn sortColumn;
  final bool sortAscending;
  final void Function(_UserSortColumn column, bool ascending) onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return DropdownButtonFormField<String>(
      initialValue: '${sortColumn.name}_${sortAscending ? 'asc' : 'desc'}',
      decoration: InputDecoration(
        labelText: l.adminUsersSortBy,
        filled: true,
        fillColor: AppColors.card,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.border),
        ),
      ),
      items: [
        for (final column in _UserSortColumn.values) ...[
          DropdownMenuItem(
            value: '${column.name}_asc',
            child: Text('${column.label(l)} (A–Z)'),
          ),
          DropdownMenuItem(
            value: '${column.name}_desc',
            child: Text('${column.label(l)} (Z–A)'),
          ),
        ],
      ],
      onChanged: (value) {
        if (value == null) return;
        final parts = value.split('_');
        final ascending = parts.removeLast() == 'asc';
        final columnName = parts.join('_');
        final column = _UserSortColumn.values.firstWhere(
          (item) => item.name == columnName,
        );
        onChanged(column, ascending);
      },
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final Map<T, String> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.card,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.border),
        ),
      ),
      items: items.entries
          .map(
            (entry) => DropdownMenuItem<T>(
              value: entry.key,
              child: Text(entry.value),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _UserNameCell extends StatelessWidget {
  const _UserNameCell({
    required this.user,
    required this.roleColor,
    this.detail,
  });

  final AppUser user;
  final Color roleColor;

  /// Linked parent or children, under the email.
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppUserAvatar(
          initials: userInitials(user.displayNameIndonesian),
          photoUrl: user.photoUrl,
          size: 34,
          backgroundColor: roleColor,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                user.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              if (detail != null)
                Text(
                  detail!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.teal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UserMobileCard extends StatelessWidget {
  const _UserMobileCard({
    required this.user,
    this.onOpen,
    required this.roleLabel,
    required this.roleColor,
    required this.joinedLabel,
    required this.hskLabel,
    required this.onToggleActive,
    required this.onDelete,
    required this.onEdit,
  });

  final AppUser user;

  /// Opens the student page; null for staff and parents.
  final VoidCallback? onOpen;
  final String roleLabel;
  final Color roleColor;
  final String joinedLabel;
  final String hskLabel;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppUserAvatar(
                initials: userInitials(user.displayNameIndonesian),
                photoUrl: user.photoUrl,
                size: 34,
                backgroundColor: roleColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _RolePill(label: roleLabel, color: roleColor),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                joinedLabel,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              if (user.isStudent) ...[
                Text(
                  ' · ',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                Text(
                  hskLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const Spacer(),
              Text(
                user.active ? l.historyStatusActive : l.profileWidgetInactive,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color:
                      user.active ? AppColors.success : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          if (!user.isAdmin) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: _UserActionsBar(
                active: user.active,
                onEdit: onEdit,
                onToggleActive: onToggleActive,
                onDelete: onDelete,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  const _RolePill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _UserActionsBar extends StatelessWidget {
  const _UserActionsBar({
    required this.active,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
    this.compact = false,
  });

  final bool active;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _UserEditButton(onPressed: onEdit, compact: compact),
        SizedBox(width: compact ? 10 : 12),
        _ActionButton(active: active, onPressed: onToggleActive),
        SizedBox(width: compact ? 6 : 8),
        IconButton(
          onPressed: onDelete,
          icon: Icon(Icons.delete_forever_outlined, color: AppColors.error),
          tooltip: context.l10n.adminUsersDeleteAccount,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

class _UserEditButton extends StatelessWidget {
  const _UserEditButton({
    required this.onPressed,
    this.compact = false,
  });

  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Tooltip(
        message: context.l10n.adminUsersEditProfile,
        child: Material(
          color: AppColors.navy.withValues(alpha: 0.07),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: AppColors.navy.withValues(alpha: 0.14),
            ),
          ),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 36,
              height: 36,
              child: Icon(
                Icons.edit_outlined,
                size: 17,
                color: AppColors.navy,
              ),
            ),
          ),
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.edit_outlined, size: 16),
      label: Text(context.l10n.adminUsersEdit),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.navy,
        backgroundColor: AppColors.navy.withValues(alpha: 0.04),
        side: BorderSide(color: AppColors.navy.withValues(alpha: 0.18)),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.active,
    required this.onPressed,
  });

  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.error : AppColors.success;

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        backgroundColor: active ? AppColors.card : color.withValues(alpha: 0.1),
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      child: Text(
        active
            ? context.l10n.adminUsersDeactivate
            : context.l10n.adminUsersActivate,
      ),
    );
  }
}
