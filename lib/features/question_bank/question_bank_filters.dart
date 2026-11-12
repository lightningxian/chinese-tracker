import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../l10n/l10n.dart';
import '../../l10n/labels_exercises.dart';
import '../../models/exercise_category.dart';
import '../../models/exercise_type.dart';
import '../../models/question_bank_item.dart';

const _unset = Object();

/// What the bank list (and the picker in the exercise form) is narrowed to:
/// free text plus the three dropdowns.
class QuestionBankFilter {
  const QuestionBankFilter({
    this.search = '',
    this.category,
    this.type,
    this.level,
  });

  final String search;
  final ExerciseCategory? category;
  final ExerciseType? type;
  final String? level;

  bool get isEmpty =>
      search.trim().isEmpty &&
      category == null &&
      type == null &&
      level == null;

  QuestionBankFilter copyWith({
    String? search,
    Object? category = _unset,
    Object? type = _unset,
    Object? level = _unset,
  }) =>
      QuestionBankFilter(
        search: search ?? this.search,
        category:
            category == _unset ? this.category : category as ExerciseCategory?,
        type: type == _unset ? this.type : type as ExerciseType?,
        level: level == _unset ? this.level : level as String?,
      );

  /// A worksheet matches when the dropdowns match and the search text is in
  /// its code, title, type or any of its questions.
  /// [l] adds the translated type and category names to the search, so
  /// typing what the chips show ("Ujian", "Pilihan ganda") finds the sheet.
  bool matches(QuestionBankSheet sheet, {AppLocalizations? l}) {
    if (type != null && sheet.type != type) return false;
    if (category != null && sheet.category != category) return false;
    if (level != null && sheet.level != level) return false;
    final needle = search.trim().toLowerCase();
    if (needle.isEmpty) return true;
    final hay = [
      sheet.code,
      sheet.title,
      sheet.type.label,
      sheet.category.label,
      if (l != null) sheet.type.localized(l),
      if (l != null) sheet.category.localized(l),
      sheet.level ?? '',
      for (final item in sheet.items) item.displayText,
    ].join(' ').toLowerCase();
    return hay.contains(needle);
  }
}

/// Search field with the Type of exercise, Question type and Level
/// dropdowns. Wraps onto two lines when the space is narrow.
class QuestionBankFilterBar extends StatelessWidget {
  const QuestionBankFilterBar({
    super.key,
    required this.filter,
    required this.onChanged,
    this.searchHint,
  });

  final QuestionBankFilter filter;
  final ValueChanged<QuestionBankFilter> onChanged;

  /// Placeholder of the search field; the bank's own wording when null.
  final String? searchHint;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 820;
        final search = TextField(
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: searchHint ?? l.bankFiltersSearchHint,
            isDense: true,
          ),
          onChanged: (v) => onChanged(filter.copyWith(search: v)),
        );
        final dropdowns = [
          _Dropdown<ExerciseCategory?>(
            label: l.bankFiltersTypeOfExercise,
            value: filter.category,
            width: wide ? 180 : null,
            items: [
              for (final c in ExerciseCategory.values) (c, c.localized(l)),
            ],
            onChanged: (v) => onChanged(filter.copyWith(category: v)),
          ),
          _Dropdown<ExerciseType?>(
            label: l.bankFiltersQuestionType,
            value: filter.type,
            width: wide ? 220 : null,
            items: [
              for (final t in ExerciseType.values) (t, t.localized(l)),
            ],
            onChanged: (v) => onChanged(filter.copyWith(type: v)),
          ),
          _Dropdown<String?>(
            label: l.bankFiltersLevel,
            value: filter.level,
            width: wide ? 120 : null,
            items: [
              for (final l in AppConstants.hskLevels) (l, l),
            ],
            onChanged: (v) => onChanged(filter.copyWith(level: v)),
          ),
        ];
        if (wide) {
          return Row(
            children: [
              Expanded(child: search),
              for (final d in dropdowns) ...[const SizedBox(width: 12), d],
            ],
          );
        }
        return Column(
          children: [
            search,
            const SizedBox(height: 10),
            Row(
              children: [
                for (final (i, d) in dropdowns.indexed) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(child: d),
                ],
              ],
            ),
          ],
        );
      },
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.width,
  });

  final String label;
  final T value;
  final List<(T, String)> items;
  final ValueChanged<T?> onChanged;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final field = DropdownButtonFormField<T>(
      // A new key when the value changes from outside keeps the field in
      // step (DropdownButtonFormField only reads initialValue once).
      key: ValueKey('$label-$value'),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label, isDense: true),
      items: [
        DropdownMenuItem<T>(value: null as T, child: Text(l.bankFiltersAll)),
        for (final (v, text) in items)
          DropdownMenuItem<T>(
            value: v,
            child: Text(text, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onChanged,
    );
    return width == null ? field : SizedBox(width: width, child: field);
  }
}
