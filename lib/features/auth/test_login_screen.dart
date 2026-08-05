import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/test_accounts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/auth_scaffold.dart';
import '../../services/auth_service.dart';

/// Dev entry screen — role shortcuts and sign-in on launch.
class TestLoginScreen extends StatefulWidget {
  const TestLoginScreen({super.key});

  @override
  State<TestLoginScreen> createState() => _TestLoginScreenState();
}

class _TestLoginScreenState extends State<TestLoginScreen> {
  int _tabIndex = 0;
  String? _signingInLabel;
  bool _signInLoading = false;
  String? _signInError;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  static const _adminColor = Color(0xFF7A4FBF);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInAs(TestAccount account) async {
    setState(() => _signingInLabel = account.label);
    try {
      await context.read<AuthService>().signIn(
            email: account.email,
            password: account.password,
          );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_authErrorMessage(e, account)),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _signingInLabel = null);
    }
  }

  Future<void> _signInManual() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _signInError = 'Enter email and password.');
      return;
    }

    setState(() {
      _signInLoading = true;
      _signInError = null;
    });
    try {
      await context.read<AuthService>().signIn(
            email: email,
            password: password,
          );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _signInError = e.message ?? 'Sign in failed.');
    } finally {
      if (mounted) setState(() => _signInLoading = false);
    }
  }

  String _authErrorMessage(FirebaseAuthException e, TestAccount account) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Sign-in failed for ${account.label}. '
            'Run scripts/seed_test_accounts.sh (password: testpass123).';
      case 'too-many-requests':
        return 'Too many attempts. Wait a moment and try again.';
      default:
        return e.message ??
            'Could not sign in as ${account.label}. (${e.code})';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Same split navy/white auth layout as login/register.
    return AuthScaffold(
      title: 'Developer login',
      subtitle: 'Role shortcuts and email sign-in for testing.',
      child: _authCard(),
    );
  }

  Widget _authCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _tabBar(),
          const SizedBox(height: 8),
          if (_tabIndex == 0) _testLoginTab() else _signInTab(),
        ],
      ),
    );
  }

  Widget _tabBar() {
    return Row(
      children: [
        _tabButton('Test login', 0),
        _tabButton('Sign in', 1),
      ],
    );
  }

  Widget _tabButton(String label, int index) {
    final selected = _tabIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _tabIndex = index),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppColors.navy : AppColors.textSecondary,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 2,
                decoration: BoxDecoration(
                  color: selected ? AppColors.teal : Colors.transparent,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _testLoginTab() {
    final admin = TestAccounts.adminOptions.first;
    final guru = TestAccounts.teacherOptions.first;
    final murid = TestAccounts.studentOptions.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Dev mode — choose a role to preview the app.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        _roleCard(
          label: 'Admin',
          subtitle: 'Users, exercises, vouchers, reports',
          icon: Icons.verified_user_outlined,
          color: _adminColor,
          account: admin,
        ),
        const SizedBox(height: 12),
        _roleCard(
          label: 'Guru',
          subtitle: 'Students, classes, attendance',
          icon: Icons.school_outlined,
          color: AppColors.navy,
          account: guru,
        ),
        const SizedBox(height: 12),
        _roleCard(
          label: 'Murid',
          subtitle: 'Classes, exercises, progress',
          icon: Icons.menu_book_outlined,
          color: AppColors.teal,
          account: murid,
        ),
      ],
    );
  }

  Widget _roleCard({
    required String label,
    required String subtitle,
    required IconData icon,
    required Color color,
    required TestAccount account,
  }) {
    final loading = _signingInLabel == account.label;
    final disabled = _signingInLabel != null && !loading;

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: disabled ? null : () => _signInAs(account),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (loading)
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              else
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _signInTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Sign in with your email and password.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        if (_signInError != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _signInError!,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),
        ],
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: true,
          autofillHints: const [AutofillHints.password],
          decoration: const InputDecoration(
            labelText: 'Password',
            prefixIcon: Icon(Icons.lock_outline),
          ),
          onSubmitted: (_) => _signInManual(),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _signInLoading ? null : _signInManual,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.navy,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: _signInLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Sign in'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => context.push('/register'),
          child: const Text('Create new account'),
        ),
        TextButton(
          onPressed: () => context.go('/'),
          child: const Text('Back to home'),
        ),
      ],
    );
  }
}
