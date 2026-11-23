import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../services/auth_service.dart';
import '../../services/saved_accounts_service.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';

/// Owner 2026-11-24 (App Store, Apple guideline 5.1.1(v)): a student or a
/// parent deletes their own account. The password is asked first; the
/// `deleteMyAccount` function removes the sign-in and the profile, the
/// centre keeps results, invoices and attendance as records.
class DeleteAccountCard extends StatelessWidget {
  const DeleteAccountCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AppCard(
      child: Row(
        children: [
          Icon(Icons.person_remove_outlined, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.deleteAccountTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(l.deleteAccountSubtitle,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => showDeleteAccountDialog(context),
            child: Text(l.deleteAccountButton),
          ),
        ],
      ),
    );
  }
}

Future<void> showDeleteAccountDialog(BuildContext context) =>
    showDialog<void>(context: context, builder: (_) => const _DeleteAccountDialog());

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _password = TextEditingController();
  bool _busy = false;
  bool _sure = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final l = context.l10n;
    if (_password.text.isEmpty) {
      setState(() => _error = l.passwordCurrentMissing);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = context.read<AuthService>();
    final saved = context.read<SavedAccountsService>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final email = auth.appUser?.email ?? FirebaseAuth.instance.currentUser?.email ?? '';
    try {
      await auth.reauthenticate(_password.text);
      await FirebaseFunctions.instance.httpsCallable('deleteMyAccount').call<dynamic>({});
      if (email.isNotEmpty) await saved.removeAccount(email);
      navigator.pop();
      await auth.signOut();
      messenger.showSnackBar(SnackBar(content: Text(l.deleteAccountDone)));
    } on FirebaseAuthException catch (e) {
      setState(() => _error = switch (e.code) {
            'wrong-password' || 'invalid-credential' || 'invalid-login-credentials' =>
              l.passwordCurrentWrong,
            'too-many-requests' => l.passwordTooManyTries,
            _ => e.message ?? e.code,
          });
    } on FirebaseFunctionsException catch (e) {
      setState(() => _error = e.message ?? e.code);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.deleteAccountTitle),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.deleteAccountBody, style: const TextStyle(height: 1.45)),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(labelText: l.passwordCurrent),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _sure,
              onChanged: _busy ? null : (v) => setState(() => _sure = v ?? false),
              title: Text(l.deleteAccountConfirm),
            ),
            if (_error != null) Text(_error!, style: TextStyle(color: AppColors.error)),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context), child: Text(l.commonCancel)),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: _busy || !_sure ? null : _delete,
          child: Text(l.deleteAccountButton),
        ),
      ],
    );
  }
}
