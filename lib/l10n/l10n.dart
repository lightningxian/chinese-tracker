import 'package:flutter/widgets.dart';

import 'generated/app_localizations.dart';

export 'generated/app_localizations.dart';

/// Short access to the UI strings: `context.l10n.loginSubtitle`.
///
/// Strings live in `lib/l10n/app_en.arb` (template) and `app_id.arb`;
/// run `flutter gen-l10n` after editing them.
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
