import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../constants/app_constants.dart';
import '../theme/app_theme.dart';
import 'app_logo.dart';

/// Split auth layout matching Figma Make (logo panel + form panel).
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.showBackButton = false,
    this.onBack,
    this.topAction,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final bool showBackButton;
  final VoidCallback? onBack;

  /// Optional widget at the top-right of the form panel (e.g. the language
  /// toggle), on the same line as the back button.
  final Widget? topAction;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 600;

    if (isWide) {
      return Scaffold(
        backgroundColor: AppColors.navy,
        body: Row(
          children: [
            Expanded(child: _BrandPanel()),
            Expanded(
              child: Container(
                color: AppColors.card,
                child: SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(40),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: _FormPanel(
                          title: title,
                          subtitle: subtitle,
                          showBackButton: showBackButton,
                          onBack: onBack,
                          topAction: topAction,
                          child: child,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.navy,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: AppLogo(
                        variant: AppLogoVariant.primary,
                        height: 56,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _FormPanel(
                    title: title,
                    subtitle: subtitle,
                    showBackButton: showBackButton,
                    onBack: onBack,
                    topAction: topAction,
                    child: child,
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

class _BrandPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Reference layout: logo top-left, large white headline mid-panel,
    // muted subtitle, small footer at the bottom.
    return Container(
      color: AppColors.navy,
      padding: const EdgeInsets.all(48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo artwork with the white tagline, made for dark backgrounds.
          const Align(
            alignment: Alignment.centerLeft,
            child: AppLogo(variant: AppLogoVariant.withTagline, height: 64),
          ),
          const Spacer(),
          Text(
            context.l10n.authBrandHeadline,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 40,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppConstants.brandTagline,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const Spacer(),
          Text(
            '© ${DateTime.now().year} ${AppConstants.brandName}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _FormPanel extends StatelessWidget {
  const _FormPanel({
    required this.child,
    this.title,
    this.subtitle,
    this.showBackButton = false,
    this.onBack,
    this.topAction,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final bool showBackButton;
  final VoidCallback? onBack;
  final Widget? topAction;

  @override
  Widget build(BuildContext context) {
    final backButton = IconButton(
      onPressed: onBack,
      icon: const Icon(Icons.arrow_back),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (topAction != null)
          Row(
            children: [
              if (showBackButton) backButton,
              const Spacer(),
              topAction!,
            ],
          )
        else if (showBackButton)
          Align(
            alignment: Alignment.centerLeft,
            child: backButton,
          ),
        if (title != null) ...[
          Text(
            title!,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
          ),
          const SizedBox(height: 8),
        ],
        if (subtitle != null)
          Text(
            subtitle!,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        if (title != null || subtitle != null) const SizedBox(height: 24),
        child,
      ],
    );
  }
}
