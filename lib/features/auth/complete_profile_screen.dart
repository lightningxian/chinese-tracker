import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/registration_identity_fields.dart';
import '../../models/teacher_link_code.dart';
import '../../services/auth_service.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameIndonesianController = TextEditingController();
  final _nameChineseController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _parentNameController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _linkCodeController = TextEditingController();

  bool _isTeacher = false;
  String _level = AppConstants.hskLevels.first;
  int _termSize = AppConstants.defaultTermSize;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameIndonesianController.dispose();
    _nameChineseController.dispose();
    _whatsappController.dispose();
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    _linkCodeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = context.read<AuthService>();
      if (_isTeacher) {
        await auth.completeTeacherProfile(
          nameIndonesian: _nameIndonesianController.text,
          nameChinese: _nameChineseController.text,
          whatsapp: _whatsappController.text,
        );
      } else {
        await auth.completeProfile(
          nameIndonesian: _nameIndonesianController.text,
          nameChinese: _nameChineseController.text,
          whatsapp: _whatsappController.text,
          parentName: _parentNameController.text,
          parentPhone: _parentPhoneController.text,
          level: _level,
          termSize: _termSize,
          linkCode: _linkCodeController.text,
        );
      }
    } on TeacherLinkCodeException catch (e) {
      setState(() => _error = e.message);
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Could not complete profile');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = context.read<AuthService>().firebaseUser?.email ?? '';

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Complete your profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            await context.read<AuthService>().signOut();
            if (context.mounted) context.go('/login');
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: AppLogo(height: 64)),
                const SizedBox(height: 20),
                Text(
                  'Complete your profile',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'We found your login, but your profile data is missing.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 24),
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('Student')),
                    ButtonSegment(value: true, label: Text('Teacher')),
                  ],
                  selected: {_isTeacher},
                  onSelectionChanged: (s) =>
                      setState(() => _isTeacher = s.first),
                ),
                const SizedBox(height: 16),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      RegistrationIdentityFields(
                        nameIndonesianController: _nameIndonesianController,
                        nameChineseController: _nameChineseController,
                        whatsappController: _whatsappController,
                        enabled: !_loading,
                        requireChineseName: !_isTeacher,
                        requireWhatsapp: true,
                        showParentFields: !_isTeacher,
                        requireParentFields: !_isTeacher,
                        parentNameController: _parentNameController,
                        parentPhoneController: _parentPhoneController,
                      ),
                      if (!_isTeacher) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _linkCodeController,
                          textCapitalization: TextCapitalization.characters,
                          autocorrect: false,
                          decoration: const InputDecoration(
                            labelText: 'Teacher link code',
                            hintText: '6-character code',
                            prefixIcon: Icon(Icons.link_outlined),
                            helperText:
                                'Ask your teacher for the current code (refreshes every 15 min)',
                          ),
                          validator: (v) => v == null || v.trim().length < 4
                              ? 'Enter your teacher link code'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _level,
                          decoration: const InputDecoration(
                            labelText: 'HSK level',
                            prefixIcon: Icon(Icons.school_outlined),
                          ),
                          items: AppConstants.hskLevels
                              .map((l) => DropdownMenuItem(
                                    value: l,
                                    child: Text(l),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _level = v ?? _level),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int>(
                          initialValue: _termSize,
                          decoration: const InputDecoration(
                            labelText: 'Lessons per term',
                            prefixIcon: Icon(Icons.calendar_view_week_outlined),
                          ),
                          items: AppConstants.termSizes
                              .map((size) => DropdownMenuItem(
                                    value: size,
                                    child: Text('$size lessons per term'),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _termSize = v ?? _termSize),
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
                      : const Text('Save profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
