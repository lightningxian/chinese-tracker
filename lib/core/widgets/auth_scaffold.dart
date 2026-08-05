import 'package:flutter/material.dart';

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
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final bool showBackButton;
  final VoidCallback? onBack;

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
          Row(
            children: [
              const AppLogo(variant: AppLogoVariant.mascot, height: 36),
              const SizedBox(width: 12),
              const Text(
                AppConstants.brandName,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const Spacer(),
          const Text(
            'Learn Chinese,\nthe easy way.',
            style: TextStyle(
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
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final bool showBackButton;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showBackButton)
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
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
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        if (title != null || subtitle != null) const SizedBox(height: 24),
        child,
      ],
    );
  }
}
