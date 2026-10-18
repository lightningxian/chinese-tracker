import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/auth_scaffold.dart';
import '../../core/widgets/registration_identity_fields.dart';
import '../../services/auth_service.dart';
import '../../services/child_link_service.dart';
import '../../models/teacher_link_code.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameIndonesianController = TextEditingController();
  final _nameChineseController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _parentNameController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _linkCodeController = TextEditingController();
  final _childCodeController = TextEditingController();

  String _role = AppConstants.roleStudent;
  bool _loading = false;
  String? _error;
  String _level = AppConstants.hskLevels.first;
  int _termSize = AppConstants.defaultTermSize;

  bool get _isParent => _role == AppConstants.roleParent;
  bool get _isStudent => _role == AppConstants.roleStudent;

  @override
  void dispose() {
    _nameIndonesianController.dispose();
    _nameChineseController.dispose();
    _whatsappController.dispose();
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _linkCodeController.dispose();
    _childCodeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final auth = context.read<AuthService>();
    try {
      if (_isParent) {
        await auth.registerParent(
          nameIndonesian: _nameIndonesianController.text,
          nameChinese: _nameChineseController.text,
          whatsapp: _whatsappController.text,
          email: _emailController.text,
          password: _passwordController.text,
          childCode: _childCodeController.text,
        );
      } else {
        await auth.register(
          nameIndonesian: _nameIndonesianController.text,
          nameChinese: _nameChineseController.text,
          whatsapp: _whatsappController.text,
          parentName: _parentNameController.text,
          parentPhone: _parentPhoneController.text,
          email: _emailController.text,
          password: _passwordController.text,
          level: _level,
          termSize: _termSize,
          linkCode: _linkCodeController.text,
        );
        if (!mounted) return;
        // Registration notifications for admin + teacher are created
        // server-side by the onUserCreated Cloud Function (students aren't
        // allowed to write notifications), so nothing to do here.
      }
    } on TeacherLinkCodeException catch (e) {
      setState(() => _error = e.message);
    } on ChildLinkException catch (e) {
      setState(() => _error = e.message);
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _authErrorMessage(e));
    } on FirebaseException catch (e) {
      setState(() => _error = _firebaseErrorMessage(e));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _authErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered. Try Sign in instead.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is disabled in Firebase.';
      default:
        return e.message ?? 'Registration failed (${e.code})';
    }
  }

  String _firebaseErrorMessage(FirebaseException e) {
    if (e.code == 'permission-denied') {
      return 'Firestore blocked this action. Publish firestore.rules from the project.';
    }
    return e.message ?? 'Firebase error (${e.code})';
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Create account',
      subtitle: 'Join Easy Study as a student or parent',
      showBackButton: true,
      onBack: () => context.pop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: AppConstants.roleStudent,
                label: Text('Student'),
              ),
              ButtonSegment(
                value: AppConstants.roleParent,
                label: Text('Parent'),
              ),
            ],
            selected: {_role},
            onSelectionChanged: (s) => setState(() => _role = s.first),
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
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) =>
                      v == null || !v.contains('@') ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (v) =>
                      v == null || v.length < 6 ? 'Minimum 6 characters' : null,
                ),
                if (_isParent) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _childCodeController,
                    textCapitalization: TextCapitalization.characters,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'Child access code',
                      hintText: '6-character code',
                      prefixIcon: Icon(Icons.family_restroom_outlined),
                      helperText:
                          "Find this in your child's Profile under 'Parent access'.",
                    ),
                    validator: (v) => v == null || v.trim().length < 4
                        ? 'Enter your child access code'
                        : null,
                  ),
                ],
                if (_isStudent) ...[
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
                        .map((l) => DropdownMenuItem(value: l, child: Text(l)))
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
                        .map(
                          (size) => DropdownMenuItem(
                            value: size,
                            child: Text('$size lessons per term'),
                          ),
                        )
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
                : Text(
                    _isParent ? 'Register as parent' : 'Create account',
                  ),
          ),
        ],
      ),
    );
  }
}
