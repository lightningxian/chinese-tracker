import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/registration_identity_fields.dart';
import '../../core/widgets/shell_nested_page.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class AdminCreateUserScreen extends StatefulWidget {
  const AdminCreateUserScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AdminCreateUserScreen> createState() => _AdminCreateUserScreenState();
}

class _AdminCreateUserScreenState extends State<AdminCreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameIndonesianController = TextEditingController();
  final _nameChineseController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _parentNameController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String _role = AppConstants.roleStudent;
  String _level = AppConstants.hskLevels.first;
  int _termSize = AppConstants.defaultTermSize;
  final Set<String> _childIds = {};
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameIndonesianController.dispose();
    _nameChineseController.dispose();
    _whatsappController.dispose();
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _isStudent => _role == AppConstants.roleStudent;
  bool get _isParent => _role == AppConstants.roleParent;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isParent && _childIds.isEmpty) {
      setState(() => _error = 'Select at least one child for this parent.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final profile = await context.read<AuthService>().createUserByAdmin(
            nameIndonesian: _nameIndonesianController.text,
            nameChinese: _nameChineseController.text,
            whatsapp: _whatsappController.text,
            parentName: _parentNameController.text,
            parentPhone: _parentPhoneController.text,
            email: _emailController.text,
            password: _passwordController.text,
            role: _role,
            level: _isStudent ? _level : null,
            termSize: _isStudent ? _termSize : null,
            studentIds: _isParent ? _childIds.toList() : const [],
          );

      if (!mounted) return;

      // Registration notifications for murid are created by the onUserCreated
      // Cloud Function — do not also write them from the client.

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${profile.roleDisplayLabel} account created for ${profile.displayNameIndonesian}',
          ),
        ),
      );
      context.pop();
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _authErrorMessage(e));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _authErrorMessage(FirebaseAuthException e) {
    return switch (e.code) {
      'email-already-in-use' => 'This email is already registered.',
      'weak-password' => 'Password is too weak. Use at least 6 characters.',
      'invalid-email' => 'Invalid email address.',
      'operation-not-allowed' =>
        'Email/password sign-in is disabled in Firebase.',
      _ => e.message ?? 'Registration failed (${e.code})',
    };
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 720;

    return ShellNestedPage(
      embedded: widget.embedded,
      title: 'Register new user',
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isWide ? 32 : 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: AppCard(
              padding: EdgeInsets.all(isWide ? 28 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Create a Murid or Guru account',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'The new user can sign in with the email and password you set. '
                    'You stay signed in as admin.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: AppConstants.roleStudent,
                        label: Text('Murid'),
                      ),
                      ButtonSegment(
                        value: AppConstants.roleTeacher,
                        label: Text('Guru'),
                      ),
                      ButtonSegment(
                        value: AppConstants.roleParent,
                        label: Text('Ortu'),
                      ),
                    ],
                    selected: {_role},
                    onSelectionChanged: _loading
                        ? null
                        : (selection) =>
                            setState(() => _role = selection.first),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _error!,
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        RegistrationIdentityFields(
                          nameIndonesianController: _nameIndonesianController,
                          nameChineseController: _nameChineseController,
                          whatsappController: _whatsappController,
                          enabled: !_loading,
                          requireChineseName: _isStudent,
                          requireWhatsapp: true,
                          showParentFields: _isStudent,
                          requireParentFields: _isStudent,
                          parentNameController: _parentNameController,
                          parentPhoneController: _parentPhoneController,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          enabled: !_loading,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (value) =>
                              value == null || !value.contains('@')
                                  ? 'Enter a valid email'
                                  : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          enabled: !_loading,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock_outline),
                            helperText: 'Minimum 6 characters',
                          ),
                          validator: (value) =>
                              value == null || value.length < 6
                                  ? 'Minimum 6 characters'
                                  : null,
                        ),
                        if (_isParent) ...[
                          const SizedBox(height: 16),
                          _ChildPicker(
                            selectedIds: _childIds,
                            enabled: !_loading,
                            onToggle: (id, selected) => setState(() {
                              if (selected) {
                                _childIds.add(id);
                              } else {
                                _childIds.remove(id);
                              }
                            }),
                          ),
                        ],
                        if (_isStudent) ...[
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: _level,
                            decoration: const InputDecoration(
                              labelText: 'HSK level',
                              prefixIcon: Icon(Icons.school_outlined),
                            ),
                            items: AppConstants.hskLevels
                                .map(
                                  (level) => DropdownMenuItem(
                                    value: level,
                                    child: Text(level),
                                  ),
                                )
                                .toList(),
                            onChanged: _loading
                                ? null
                                : (value) =>
                                    setState(() => _level = value ?? _level),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<int>(
                            initialValue: _termSize,
                            decoration: const InputDecoration(
                              labelText: 'Lessons per term',
                              prefixIcon:
                                  Icon(Icons.calendar_view_week_outlined),
                            ),
                            items: AppConstants.termSizes
                                .map(
                                  (size) => DropdownMenuItem(
                                    value: size,
                                    child: Text('$size lessons per term'),
                                  ),
                                )
                                .toList(),
                            onChanged: _loading
                                ? null
                                : (value) => setState(
                                      () => _termSize = value ?? _termSize,
                                    ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _isStudent
                                ? 'Create Murid account'
                                : _isParent
                                    ? 'Create Ortu account'
                                    : 'Create Guru account',
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Multi-select list of students to link to a new parent account.
class _ChildPicker extends StatelessWidget {
  const _ChildPicker({
    required this.selectedIds,
    required this.onToggle,
    required this.enabled,
  });

  final Set<String> selectedIds;
  final void Function(String id, bool selected) onToggle;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Linked children',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Choose which students this parent can follow (read-only).',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: StreamBuilder<List<AppUser>>(
            stream: firestore.watchAllStudents(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final students = snap.data ?? [];
              if (students.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No students to link yet.'),
                );
              }
              return _SearchableStudentList(
                students: students,
                selectedIds: selectedIds,
                onToggle: onToggle,
                enabled: enabled,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Student checklist with a search box, so a parent's children can be found
/// in a long roster.
class _SearchableStudentList extends StatefulWidget {
  const _SearchableStudentList({
    required this.students,
    required this.selectedIds,
    required this.onToggle,
    required this.enabled,
  });

  final List<AppUser> students;
  final Set<String> selectedIds;
  final void Function(String uid, bool selected) onToggle;
  final bool enabled;

  @override
  State<_SearchableStudentList> createState() => _SearchableStudentListState();
}

class _SearchableStudentListState extends State<_SearchableStudentList> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final shown = widget.students.where((s) {
      if (q.isEmpty) return true;
      return s.displayNameIndonesian.toLowerCase().contains(q) ||
          s.name.toLowerCase().contains(q) ||
          s.email.toLowerCase().contains(q) ||
          (s.level ?? '').toLowerCase().contains(q);
    }).toList();
    final selectedCount = widget.selectedIds.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
          child: TextField(
            enabled: widget.enabled,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Search by name, email or HSK level',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              suffixText: selectedCount == 0 ? null : '$selectedCount selected',
            ),
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 260),
          child: shown.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No students match this search.'),
                )
              : ListView(
                  shrinkWrap: true,
                  children: [
                    for (final s in shown)
                      CheckboxListTile(
                        dense: true,
                        value: widget.selectedIds.contains(s.uid),
                        title: Text(s.displayNameIndonesian),
                        subtitle: s.level != null ? Text(s.level!) : null,
                        onChanged: widget.enabled
                            ? (v) => widget.onToggle(s.uid, v ?? false)
                            : null,
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
