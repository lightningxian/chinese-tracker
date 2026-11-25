import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../core/paging/date_range.dart';
import '../../core/paging/paged_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/csv_export.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/paging_bars.dart';
import '../../core/widgets/shell_nested_page.dart';
import '../../l10n/l10n.dart';
import '../../models/leaderboard.dart';
import '../../models/test_track.dart';
import '../../services/auth_service.dart';
import '../../services/promotion_service.dart';
import 'leaderboard_export.dart';
import 'test_labels.dart';

/// What the leaderboard screen shows: the ranked board of one code, a
/// page at a time (Build 9C), the student's own place and, for staff, the
/// staff label of each student (Build 2B, LB-01).
class LeaderboardViewModel extends ChangeNotifier {
  LeaderboardViewModel({
    required this.codeId,
    required this.staff,
    this.uid,
    PromotionService? service,
  }) : _service = service ?? PromotionService() {
    _init();
  }

  final String codeId;
  final bool staff;
  final String? uid;
  final PromotionService _service;

  PagedController<LeaderboardEntry>? pages;
  ({LeaderboardEntry entry, int total})? mine;
  String code = '';
  String level = '';
  Map<String, String> staffLabels = const {};
  bool loading = true;
  Object? error;
  bool _disposed = false;

  Future<void> _init() async {
    try {
      final info = await _service.boardInfo(codeId);
      code = info.code;
      level = info.level;
      final source = await _service.leaderboardSource(codeId);
      if (_disposed) return;
      pages = PagedController<LeaderboardEntry>(
        build: (_) => source,
        range: DateRangeSel.preset(RangePreset.all),
      )..addListener(_onPage);
      if (!staff && uid != null) mine = await _service.myPlace(codeId, uid!);
    } catch (e) {
      error = e;
    }
    loading = false;
    if (!_disposed) notifyListeners();
  }

  Future<void> _onPage() async {
    if (!staff) return;
    final missing = (pages?.items ?? const <LeaderboardEntry>[])
        .map((e) => e.studentId)
        .where((id) => !staffLabels.containsKey(id))
        .toList();
    if (missing.isEmpty) return;
    try {
      staffLabels = {...staffLabels, ...await _service.staffLabels(missing)};
      if (!_disposed) notifyListeners();
    } catch (e) {
      debugPrint('leaderboard: staff labels: $e');
    }
  }

  /// Every row of the board (for an export), with staff labels loaded.
  Future<List<LeaderboardEntry>> allRows() async {
    final out = await pages!.fetchAll();
    if (staff) {
      final missing = out.rows
          .map((e) => e.studentId)
          .where((id) => !staffLabels.containsKey(id))
          .toList();
      if (missing.isNotEmpty) {
        staffLabels = {...staffLabels, ...await _service.staffLabels(missing)};
      }
    }
    return out.rows;
  }

  String nameOf(LeaderboardEntry e) => staff ? (staffLabels[e.studentId] ?? e.name) : e.name;

  @override
  void dispose() {
    _disposed = true;
    pages?.dispose();
    super.dispose();
  }
}

/// **Leaderboard** of a test code. Students see other students by the
/// Chinese name and their own row highlighted; staff see `中文名 (Latin)`.
/// Pending, invalid and placement results are never on it.
/// Build 9C: 25 rows a page, the finish time on every row, CSV / PDF /
/// share for staff, **Share my result** for a student (their own row only).
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({
    super.key,
    required this.codeId,
    this.staff = false,
    this.embedded = false,
  });

  final String codeId;
  final bool staff;
  final bool embedded;

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late final _vm = LeaderboardViewModel(
    codeId: widget.codeId,
    staff: widget.staff,
    uid: context.read<AuthService>().appUser?.uid,
  );
  bool _busy = false;

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  String _skill(String value) => _EntryRow.skillName(context.l10n, value);

  String get _stem => 'leaderboard_${_vm.code.isEmpty ? widget.codeId : _vm.code}';

  Future<void> _run(Future<void> Function() job) async {
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l10n;
    setState(() => _busy = true);
    try {
      await job();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l.pagingError('$e'))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _csv() => _run(() async {
        final rows = await _vm.allRows();
        final sk = LeaderboardExport.skills(rows);
        await CsvExport.download(
          fileStem: _stem,
          header: LeaderboardExport.header(sk, _skill),
          rows: LeaderboardExport.rows(rows, sk, _vm.nameOf),
        );
      });

  Future<Uint8List> _boardPdf() async => LeaderboardExport.boardPdf(
        code: _vm.code,
        level: _vm.level,
        board: await _vm.allRows(),
        nameOf: _vm.nameOf,
        skillName: _skill,
      );

  Future<void> _pdf() => _run(() async {
        final bytes = await _boardPdf();
        await Printing.layoutPdf(onLayout: (_) async => bytes, name: '$_stem.pdf');
      });

  Future<void> _share() => _run(() async {
        final bytes = await _boardPdf();
        await Printing.sharePdf(bytes: bytes, filename: '$_stem.pdf');
      });

  Future<void> _shareMine() => _run(() async {
        final mine = _vm.mine!;
        final bytes = await LeaderboardExport.myResultPdf(
          code: _vm.code,
          level: _vm.level,
          me: mine.entry,
          boardSize: mine.total,
          skillName: _skill,
        );
        await Printing.sharePdf(bytes: bytes, filename: 'my_result_${_vm.code}.pdf');
      });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final me = context.read<AuthService>().appUser?.uid;
    return ShellNestedPage(
      embedded: widget.embedded,
      title: l.leaderboardTitle(widget.codeId),
      child: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          if (_vm.error != null) {
            return EmptyState(
              icon: Icons.lock_outline,
              title: l.leaderboardLockedTitle,
              subtitle: l.leaderboardLockedSubtitle,
            );
          }
          final pages = _vm.pages;
          if (_vm.loading || pages == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final mine = _vm.mine;
          return PagedListBody<LeaderboardEntry>(
            controller: pages,
            padding: const EdgeInsets.all(16),
            separator: 8,
            maxWidth: 900,
            emptyIcon: Icons.emoji_events_outlined,
            emptyTitle: l.leaderboardEmptyTitle,
            emptySubtitle: l.leaderboardEmptySubtitle,
            header: ListenableBuilder(
              listenable: pages,
              builder: (context, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.staff ? l.leaderboardIntroStaff : l.leaderboardIntroStudent,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (widget.staff) ...[
                        OutlinedButton.icon(
                          onPressed: _busy ? null : _csv,
                          icon: const Icon(Icons.download_outlined, size: 18),
                          label: const Text('CSV'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _busy ? null : _pdf,
                          icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                          label: const Text('PDF'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _busy ? null : _share,
                          icon: const Icon(Icons.share_outlined, size: 18),
                          label: Text(l.leaderboardShare),
                        ),
                      ] else if (mine != null)
                        FilledButton.icon(
                          onPressed: _busy ? null : _shareMine,
                          icon: const Icon(Icons.ios_share, size: 18),
                          label: Text(l.leaderboardShareMine),
                        ),
                      if (_busy)
                        const Padding(
                          padding: EdgeInsets.all(8),
                          child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                    ],
                  ),
                  // The student's own row stays in sight on every page.
                  if (mine != null &&
                      !pages.items.any((e) => e.studentId == mine.entry.studentId)) ...[
                    const SizedBox(height: 12),
                    Text(l.leaderboardYourPlace,
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                    const SizedBox(height: 6),
                    _EntryRow(entry: mine.entry, name: mine.entry.name, mine: true),
                  ],
                ],
              ),
            ),
            itemBuilder: (_, e) =>
                _EntryRow(entry: e, name: _vm.nameOf(e), mine: e.studentId == me),
          );
        },
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.entry, required this.name, required this.mine});

  final LeaderboardEntry entry;
  final String name;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final e = entry;
    final medal = switch (e.rank) {
      1 => const Color(0xFFD4A017),
      2 => const Color(0xFF9EA7B0),
      3 => const Color(0xFFB07142),
      _ => null,
    };
    return Container(
      decoration: mine
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.teal, width: 2),
            )
          : null,
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: CircleAvatar(
                radius: 17,
                backgroundColor: medal ?? AppColors.surface,
                child: Text(
                  '${e.rank}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: medal == null ? AppColors.navy : Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mine ? l.leaderboardYou(name) : name,
                    style: AppTextStyles.question.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Wrap(
                    spacing: 10,
                    children: [
                      for (final p in e.parts)
                        Text(
                          '${skillName(l, p.skill)} ${p.mark}',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      if (e.seconds != null)
                        Text(
                          clockText(e.seconds!),
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      if (e.finishedAt != null)
                        Text(
                          LeaderboardExport.finishedText(e),
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${e.total} / ${e.max}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                Text(
                  e.passed ? '合格' : '不合格',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: e.passed ? AppColors.success : AppColors.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String skillName(AppLocalizations l, String value) {
    for (final s in TestSkill.values) {
      if (s.value == value) return s.localized(l);
    }
    return value;
  }
}
