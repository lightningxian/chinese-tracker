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
import '../../models/app_user.dart';
import '../../services/firestore_service.dart';
import 'admin_dashboard_widgets.dart';

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

  static const _toolbarFieldHeight = 48.0;
  static const _colRoleWidth = 104.0;
  static const _colHskWidth = 88.0;
  static const _colJoinedWidth = 128.0;
  static const _colStatusWidth = 84.0;
  static const _colActionsWidth = 232.0;

  static const _roleFilterOptions = <String?, String>{
    null: 'All roles',
    AppConstants.roleAdmin: 'Admin',
    AppConstants.roleTeacher: 'Guru',
    AppConstants.roleStudent: 'Murid',
    AppConstants.roleParent: 'Orang Tua',
  };

  static const _statusFilterOptions = <String?, String>{
    null: 'All status',
    'active': 'Active',
    'inactive': 'Inactive',
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _roleLabel(AppUser user) => user.roleDisplayLabel;

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

  List<AppUser> _filter(List<AppUser> users) {
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
            _roleLabel(user).toLowerCase().contains(q);
      }).toList();
    }

    return _sortUsers(result);
  }

  int _roleSortOrder(AppUser user) {
    return switch (user.role) {
      AppConstants.roleAdmin => 0,
      AppConstants.roleTeacher => 1,
      AppConstants.roleParent => 2,
      _ => 3,
    };
  }

  List<AppUser> _sortUsers(List<AppUser> users) {
    final sorted = [...users];
    sorted.sort((a, b) {
      int compare;
      switch (_sortColumn) {
        case _UserSortColumn.name:
          compare = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case _UserSortColumn.role:
          compare = _roleSortOrder(a).compareTo(_roleSortOrder(b));
          if (compare == 0) {
            compare = _roleLabel(a).compareTo(_roleLabel(b));
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

  List<AppTableColumn<AppUser>> _buildColumns(BuildContext context) {
    const metaStyle = TextStyle(
      fontSize: 12,
      color: AppColors.textSecondary,
    );

    return [
      AppTableColumn<AppUser>(
        id: _UserSortColumn.name.name,
        label: 'Name',
        sortable: true,
        cell: (user) => _UserNameCell(user: user, roleColor: _roleColor(user)),
      ),
      AppTableColumn<AppUser>(
        id: _UserSortColumn.role.name,
        label: 'Role',
        sortable: true,
        width: _colRoleWidth,
        cell: (user) => _RolePill(
          label: _roleLabel(user),
          color: _roleColor(user),
        ),
      ),
      AppTableColumn<AppUser>(
        id: 'hsk',
        label: 'HSK',
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
        label: 'Joined',
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
        label: 'Status',
        sortable: true,
        width: _colStatusWidth,
        cell: (user) => Text(
          user.active ? 'Active' : 'Inactive',
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
        label: 'Actions',
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${user.displayNameIndonesian}?'),
        content: Text(
          '${user.email} will no longer be able to sign in and the profile is '
          'removed. This cannot be undone. Exercise results, invoices and '
          'attendance stay as the centre\'s records.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete account'),
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
        SnackBar(content: Text('Deleted ${user.email}.')),
      );
    } on FirebaseFunctionsException catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Could not delete the account.'),
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
                'Could not load users: ${snapshot.error}',
                style: const TextStyle(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final users = _filter(snapshot.data ?? []);

        return ListView(
          padding: EdgeInsets.all(isWide ? 32 : 20),
          children: [
            _toolbar(context, isWide),
            const SizedBox(height: 16),
            if (users.isEmpty)
              AppCard(
                child: Text(
                  snapshot.data?.isEmpty ?? true
                      ? 'No users found. Run scripts/seed_test_accounts.sh '
                          'or check that your admin account has role: admin in Firestore.'
                      : 'No users match your search.',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              )
            else
              AppDataTable<AppUser>(
                rows: users,
                columns: _buildColumns(context),
                sortColumnId: _sortColumn.name,
                sortAscending: _sortAscending,
                onSort: _onSortById,
                mobileCardBuilder: (user) => _UserMobileCard(
                  user: user,
                  roleLabel: _roleLabel(user),
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

  Widget _toolbar(BuildContext context, bool isWide) {
    final roleFilter = SizedBox(
      width: isWide ? 148 : null,
      height: _toolbarFieldHeight,
      child: _FilterDropdown<String?>(
        label: 'Role',
        value: _roleFilter,
        items: _roleFilterOptions,
        onChanged: (value) => setState(() => _roleFilter = value),
      ),
    );

    final statusFilter = SizedBox(
      width: isWide ? 148 : null,
      height: _toolbarFieldHeight,
      child: _FilterDropdown<String?>(
        label: 'Status',
        value: _statusFilter,
        items: _statusFilterOptions,
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
        label: const Text('New user'),
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
          roleFilter,
          const SizedBox(width: 12),
          statusFilter,
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
        Row(
          children: [
            Expanded(child: roleFilter),
            const SizedBox(width: 12),
            Expanded(child: statusFilter),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
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
      ],
    );
  }

  Widget _searchField() {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _query = value),
      decoration: InputDecoration(
        hintText: 'Search users…',
        prefixIcon: const Icon(Icons.search, size: 20),
        filled: true,
        fillColor: AppColors.card,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}

enum _UserSortColumn { name, role, joined, status }

extension on _UserSortColumn {
  String get label => switch (this) {
        _UserSortColumn.name => 'Name',
        _UserSortColumn.role => 'Role',
        _UserSortColumn.joined => 'Joined',
        _UserSortColumn.status => 'Status',
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
    return DropdownButtonFormField<String>(
      initialValue: '${sortColumn.name}_${sortAscending ? 'asc' : 'desc'}',
      decoration: InputDecoration(
        labelText: 'Sort by',
        filled: true,
        fillColor: AppColors.card,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
      items: [
        for (final column in _UserSortColumn.values) ...[
          DropdownMenuItem(
            value: '${column.name}_asc',
            child: Text('${column.label} (A–Z)'),
          ),
          DropdownMenuItem(
            value: '${column.name}_desc',
            child: Text('${column.label} (Z–A)'),
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
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
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
  const _UserNameCell({required this.user, required this.roleColor});

  final AppUser user;
  final Color roleColor;

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
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                user.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
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
    required this.roleLabel,
    required this.roleColor,
    required this.joinedLabel,
    required this.hskLabel,
    required this.onToggleActive,
    required this.onDelete,
    required this.onEdit,
  });

  final AppUser user;
  final String roleLabel;
  final Color roleColor;
  final String joinedLabel;
  final String hskLabel;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
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
                      style: const TextStyle(
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
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              if (user.isStudent) ...[
                const Text(
                  ' · ',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                Text(
                  hskLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const Spacer(),
              Text(
                user.active ? 'Active' : 'Inactive',
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
          icon: const Icon(Icons.delete_forever_outlined, color: AppColors.error),
          tooltip: 'Delete account',
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
        message: 'Edit profile',
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
            child: const SizedBox(
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
      label: const Text('Edit'),
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
      child: Text(active ? 'Deactivate' : 'Activate'),
    );
  }
}
