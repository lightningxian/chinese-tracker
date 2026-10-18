import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/widgets/auth_scaffold.dart';
import '../../core/theme/app_theme.dart';
import '../../models/saved_login_account.dart';
import '../../services/auth_service.dart';
import '../../services/saved_accounts_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _showManualForm = false;
  final _manualEmail = TextEditingController();
  final _manualPassword = TextEditingController();
  bool _manualRemember = true;
  bool _manualLoading = false;
  String? _signingInEmail;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SavedAccountsService>().load();
    });
  }

  @override
  void dispose() {
    _manualEmail.dispose();
    _manualPassword.dispose();
    super.dispose();
  }

  Future<void> _signIn({
    required String email,
    required String password,
    bool rememberPassword = true,
  }) async {
    setState(() => _signingInEmail = email);
    try {
      final auth = context.read<AuthService>();
      final saved = context.read<SavedAccountsService>();
      final user = await auth.signIn(email: email, password: password);
      await saved.recordSuccessfulLogin(
        user,
        password: password,
        rememberPassword: rememberPassword,
      );
      if (!mounted) return;
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Sign in failed')),
      );
    } finally {
      if (mounted) setState(() => _signingInEmail = null);
    }
  }

  Future<void> _onAccountTap(LoginListEntry entry) async {
    final email = entry.account.email;
    if (entry.demo != null) {
      await _signIn(
        email: email,
        password: entry.demo!.password,
        rememberPassword: false,
      );
      return;
    }

    final saved = context.read<SavedAccountsService>();
    final stored = await saved.getStoredPassword(email);
    if (stored != null && stored.isNotEmpty) {
      await _signIn(email: email, password: stored, rememberPassword: true);
      return;
    }

    if (!mounted) return;
    final result = await _showPasswordDialog(entry.account);
    if (result != null) {
      await _signIn(
        email: email,
        password: result.password,
        rememberPassword: result.remember,
      );
    }
  }

  Future<({String password, bool remember})?> _showPasswordDialog(
    SavedLoginAccount account,
  ) {
    final passwordController = TextEditingController();
    var remember = true;
    return showDialog<({String password, bool remember})>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(account.displayName),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    account.email,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => Navigator.pop(ctx, (
                      password: passwordController.text,
                      remember: remember,
                    )),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Remember on this device'),
                    value: remember,
                    onChanged: (v) =>
                        setDialogState(() => remember = v ?? true),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (passwordController.text.isEmpty) return;
                    Navigator.pop(ctx, (
                      password: passwordController.text,
                      remember: remember,
                    ));
                  },
                  child: const Text('Sign in'),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(passwordController.dispose);
  }

  Future<void> _onRemoveAccount(SavedLoginAccount account) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove account?'),
        content: Text(
          'Remove ${account.displayName} from this device? You can sign in again later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<SavedAccountsService>().removeAccount(account.email);
    }
  }

  Future<void> _manualSignIn() async {
    if (_manualEmail.text.trim().isEmpty || _manualPassword.text.isEmpty) {
      return;
    }
    setState(() => _manualLoading = true);
    try {
      await _signIn(
        email: _manualEmail.text.trim(),
        password: _manualPassword.text,
        rememberPassword: _manualRemember,
      );
    } finally {
      if (mounted) setState(() => _manualLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final emailController = TextEditingController(text: _manualEmail.text.trim());
    final email = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset your password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Enter your account email. We'll send a link to set a new password.",
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, emailController.text.trim()),
            child: const Text('Send reset link'),
          ),
        ],
      ),
    );
    emailController.dispose();
    if (email == null || email.isEmpty || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<AuthService>().sendPasswordResetEmail(email);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'If $email has an account, a reset link is on its way. '
            'Check your inbox and spam folder.',
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      final message = switch (e.code) {
        'invalid-email' =>
          "That email address doesn't look right. Check it and try again.",
        'too-many-requests' =>
          'Too many attempts. Wait a few minutes and try again.',
        _ => e.message ?? "Couldn't send the reset link. Try again.",
      };
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final savedService = context.watch<SavedAccountsService>();
    final entries = savedService.isLoaded ? savedService.buildLoginList() : null;

    return AuthScaffold(
      title: AppConstants.brandName,
      subtitle: 'Tap an account to sign in',
      showBackButton: true,
      onBack: () => context.canPop() ? context.pop() : context.go('/'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (entries == null)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (entries.isEmpty)
                    _EmptyAccountsHint(
                      onAddAccount: () =>
                          setState(() => _showManualForm = true),
                    )
                  else
                    Card(
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          for (var i = 0; i < entries.length; i++) ...[
                            if (i > 0) const Divider(height: 1),
                            _AccountTile(
                              entry: entries[i],
                              loading: _signingInEmail ==
                                  entries[i].account.email,
                              onTap: () => _onAccountTap(entries[i]),
                              onRemove: entries[i].demo == null
                                  ? () => _onRemoveAccount(entries[i].account)
                                  : null,
                            ),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (!_showManualForm)
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _showManualForm = true),
                      icon: const Icon(Icons.person_add_outlined),
                      label: const Text('Sign in with another email'),
                    )
                  else ...[
                    const SizedBox(height: 8),
                    Text(
                      'Another account',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.navy,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _manualEmail,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _manualPassword,
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _manualSignIn(),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _forgotPassword,
                        child: const Text('Forgot password?'),
                      ),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Remember on this device'),
                      value: _manualRemember,
                      onChanged: (v) =>
                          setState(() => _manualRemember = v ?? true),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: _manualLoading ? null : _manualSignIn,
                      child: _manualLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Sign in'),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _showManualForm = false),
                      child: const Text('Back to account list'),
                    ),
                  ],
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.push('/register'),
                    child: const Text('Create new account'),
                  ),
                  if (kDebugMode)
                    TextButton(
                      onPressed: () => context.go('/dev-login'),
                      child: const Text('Back to test login'),
                    ),
                ],
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.entry,
    required this.loading,
    required this.onTap,
    this.onRemove,
  });

  final LoginListEntry entry;
  final bool loading;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final account = entry.account;
    final isTeacher = account.role == AppConstants.roleTeacher;
    final isAdmin = account.role == AppConstants.roleAdmin;
    final avatarColor = isAdmin
        ? const Color(0xFF7A4FBF)
        : isTeacher
            ? AppColors.navy
            : AppColors.teal;

    return ListTile(
      onTap: loading ? null : onTap,
      onLongPress: onRemove,
      leading: CircleAvatar(
        backgroundColor: avatarColor.withValues(alpha: 0.12),
        child: loading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: avatarColor,
                ),
              )
            : Icon(
                isAdmin
                    ? Icons.verified_user_outlined
                    : isTeacher
                        ? Icons.school_outlined
                        : Icons.person_outline,
                color: avatarColor,
              ),
      ),
      title: Text(
        account.displayName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        entry.demo != null
            ? '${account.roleLabel} · demo'
            : account.role != null
                ? '${account.roleLabel} · ${account.email}'
                : account.email,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: loading
          ? null
          : Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary.withValues(alpha: 0.6),
            ),
    );
  }
}

class _EmptyAccountsHint extends StatelessWidget {
  const _EmptyAccountsHint({required this.onAddAccount});

  final VoidCallback onAddAccount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.account_circle_outlined,
              size: 48,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'No saved accounts yet',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in once and your account will appear here for quick access next time.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onAddAccount,
              child: const Text('Sign in'),
            ),
          ],
        ),
      ),
    );
  }
}
