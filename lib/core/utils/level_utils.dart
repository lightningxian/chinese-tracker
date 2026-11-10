import '../constants/app_constants.dart';

abstract final class LevelUtils {
  static const _legacyToHsk = <String, String>{
    'beginner': 'HSK 1',
    'hsk1': 'HSK 1',
    'hsk 1': 'HSK 1',
    'elementary': 'HSK 2',
    'hsk2': 'HSK 2',
    'hsk 2': 'HSK 2',
    'intermediate': 'HSK 3',
    'hsk3': 'HSK 3',
    'hsk 3': 'HSK 3',
    'upper intermediate': 'HSK 4',
    'upper-intermediate': 'HSK 4',
    'hsk4': 'HSK 4',
    'hsk 4': 'HSK 4',
    'advanced': 'HSK 5',
    'hsk5': 'HSK 5',
    'hsk 5': 'HSK 5',
    'proficient': 'HSK 6',
    'hsk6': 'HSK 6',
    'hsk 6': 'HSK 6',
  };

  /// Maps legacy labels (e.g. "Intermediate") to canonical `HSK N` strings.
  static String? normalizeHskLevel(String? level) {
    if (level == null) return null;
    final trimmed = level.trim();
    if (trimmed.isEmpty) return null;
    if (AppConstants.hskLevels.contains(trimmed)) return trimmed;

    final mapped = _legacyToHsk[trimmed.toLowerCase()];
    if (mapped != null) return mapped;

    final hskMatch =
        RegExp(r'^hsk\s*(\d)$', caseSensitive: false).firstMatch(trimmed);
    if (hskMatch != null) {
      final candidate = 'HSK ${hskMatch.group(1)}';
      if (AppConstants.hskLevels.contains(candidate)) return candidate;
    }

    return trimmed;
  }

  static bool isCanonicalHsk(String? level) {
    final normalized = normalizeHskLevel(level);
    return normalized != null && AppConstants.hskLevels.contains(normalized);
  }
}
