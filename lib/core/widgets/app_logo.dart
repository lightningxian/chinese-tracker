import 'package:flutter/material.dart';

/// Easy Study brand mark from `assets/brand/`.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.variant = AppLogoVariant.primary,
    this.height = 72,
    this.fit = BoxFit.contain,
  });

  final AppLogoVariant variant;
  final double height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      variant.assetPath,
      height: height,
      fit: fit,
      semanticLabel: 'Easy Study logo',
    );
  }
}

enum AppLogoVariant {
  primary('assets/brand/logo_primary.png'),
  withTagline('assets/brand/logo_with_tagline.png'),
  mascot('assets/brand/mascot_pencil.png');

  const AppLogoVariant(this.assetPath);

  final String assetPath;
}
