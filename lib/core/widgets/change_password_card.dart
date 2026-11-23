import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../services/auth_service.dart';
import '../../services/saved_accounts_service.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';

/// Owner 2026-11-23: every role changes their own password from the
/// profile tab (current password, new password twice).
class ChangePasswordCard extends StatelessWidget {
  const ChangePasswordCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AppCard(
      child: Row(
        children: [
          Icon(Icons.lock_outline, color: AppColors.navy),
          const SizedBox(width: 12),
          Expanded(
            child: Text(l.passwordChangeTitle,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          OutlinedButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const ChangePasswordDialog(),
            ),
            child: Text(l.passwordChangeButton),
          ),
        ],
      ),
    );
  }
}

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _again = TextEditingController();
  bool _busy = false;
  bool _show = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _again.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l = context.l10n;
    if (_current.text.isEmpty) {
      setState(() => _error = l.passwordCurrentMissing);
      return;
    }
    if (_next.text.length < 8) {
      setState(() => _error = l.passwordTooShort);
      return;
    }
    if (_next.text != _again.text) {
      setState(() => _error = l.passwordMismatch);
      return;
    }
    if (_next.text == _current.text) {
      setState(() => _error = l.passwordSameAsOld);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = context.read<AuthService>();
    final saved = context.read<SavedAccountsService>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await auth.changePassword(currentPassword: _current.text, newPassword: _next.text);
      final email = auth.appUser?.email ?? '';
      if (email.isNotEmpty) await saved.updateStoredPassword(email, _next.text);
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(l.passwordChanged)));
    } on FirebaseAuthException catch (e) {
      setState(() => _error = switch (e.code) {
            'wrong-password' || 'invalid-credential' || 'invalid-login-credentials' =>
              l.passwordCurrentWrong,
            'weak-password' => l.passwordTooShort,
            'too-many-requests' => l.passwordTooManyTries,
            _ => e.message ?? e.code,
          });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    InputDecoration deco(String label) => InputDecoration(
          labelText: label,
          suffixIcon: IconButton(
            icon: Icon(_show ? Icons.visibility_off_outlined : Icons.visibility_outlined),
            onPressed: () => setState(() => _show = !_show),
          ),
        );
    return AlertDialog(
      title: Text(l.passwordChangeTitle),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _current,
              obscureText: !_show,
              autofillHints: const [AutofillHints.password],
              decoration: deco(l.passwordCurrent),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _next,
              obscureText: !_show,
              autofillHints: const [AutofillHints.newPassword],
              decoration: deco(l.passwordNew),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _again,
              obscureText: !_show,
              autofillHints: const [AutofillHints.newPassword],
              decoration: deco(l.passwordNewAgain),
              onSubmitted: (_) => _busy ? null : _submit(),
            ),
            const SizedBox(height: 8),
            Text(l.passwordRule,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: AppColors.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: Text(l.commonCancel),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(
                  width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(l.passwordChangeButton),
        ),
      ],
    );
  }
}
