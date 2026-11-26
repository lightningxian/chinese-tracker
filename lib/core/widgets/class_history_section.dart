import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../models/attendance_record.dart';
import '../../models/student_class_term.dart';
import '../../services/firestore_service.dart';
import '../paging/paged_controller.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';
import 'paging_bars.dart';

/// A student's class history for the student and parent screens: one card
/// per voucher (package size, validity, used / remaining bar, and the
/// classes charged to it when expanded), then every class visit grouped by
/// month. Returns a column, so callers put it inside their own list.
class ClassHistorySection extends StatelessWidget {
  const ClassHistorySection({
    super.key,
    required this.terms,
    required this.visits,
    this.onOpenSession,
    this.vouchersTitle,
  });

  final List<StudentClassTerm> terms;

  /// Header over the voucher cards; defaults to "Your vouchers".
  final String? vouchersTitle;

  /// Every visit of the student (joined or concluded), newest first.
  final List<AttendanceRecord> visits;

  /// Opens a class session's detail page; null when the viewer has none.
  final void Function(AttendanceRecord record)? onOpenSession;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final sortedTerms = List<StudentClassTerm>.from(terms)
      ..sort((a, b) {
        final aActive = a.isActive && a.isWithinTermDates;
        final bActive = b.isActive && b.isWithinTermDates;
        if (aActive != bActive) return aActive ? -1 : 1;
        return b.startDate.compareTo(a.startDate);
      });
    final visitsByTerm = <String, List<AttendanceRecord>>{};
    for (final visit in visits) {
      final termId = visit.classTermId;
      if (termId == null || termId.isEmpty) continue;
      visitsByTerm.putIfAbsent(termId, () => []).add(visit);
    }
    final byMonth = _groupByMonth(visits);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: vouchersTitle ?? l.historyVouchersTitle),
        if (sortedTerms.isEmpty)
          AppCard(
            child: Text(
              l.historyNoVouchers,
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
          )
        else
          for (final term in sortedTerms)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: VoucherHistoryCard(
                term: term,
                visits: visitsByTerm[term.id] ?? const [],
                initiallyExpanded: term.isActive && term.isWithinTermDates,
                onOpenSession: onOpenSession,
              ),
            ),
        const SizedBox(height: 16),
        SectionHeader(
          title:
              '${l.historyAllClasses} · ${l.historyClassesCount(visits.length)}',
        ),
        if (visits.isEmpty)
          AppCard(
            child: Text(
              l.studentMyClassesEmptySubtitle,
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
          )
        else
          for (final entry in byMonth) ...[
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 6),
              child: Text(
                DateFormat('MMMM yyyy', l.localeName).format(entry.key),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                  fontSize: 13,
                ),
              ),
            ),
            for (final record in entry.value)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  onTap: onOpenSession == null
                      ? null
                      : () => onOpenSession!(record),
                  child: ClassVisitRow(record: record),
                ),
              ),
          ],
      ],
    );
  }

  /// Visits grouped by the first day of their month, newest month first;
  /// visits whose date does not parse go under the oldest group.
  static List<MapEntry<DateTime, List<AttendanceRecord>>> _groupByMonth(
    List<AttendanceRecord> visits,
  ) {
    final groups = <DateTime, List<AttendanceRecord>>{};
    for (final visit in visits) {
      final day = DateTime.tryParse(visit.sessionDate) ?? DateTime(1970);
      final month = DateTime(day.year, day.month);
      groups.putIfAbsent(month, () => []).add(visit);
    }
    final entries = groups.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    for (final entry in entries) {
      entry.value.sort((a, b) {
        final byDate = b.sessionDate.compareTo(a.sessionDate);
        return byDate != 0 ? byDate : b.startMinutes - a.startMinutes;
      });
    }
    return entries;
  }
}

/// One voucher: "16 sessions", validity, status pill, used / remaining bar,
/// and (expanded) the classes charged to it.
class VoucherHistoryCard extends StatefulWidget {
  const VoucherHistoryCard({
    super.key,
    required this.term,
    this.visits = const [],
    this.loadVisits,
    this.initiallyExpanded = false,
    this.onOpenSession,
  });

  final StudentClassTerm term;
  final List<AttendanceRecord> visits;

  /// Build 9A session 2: reads the voucher's classes when the card is
  /// opened (instead of every class of the student up front).
  final Future<List<AttendanceRecord>> Function()? loadVisits;
  final bool initiallyExpanded;
  final void Function(AttendanceRecord record)? onOpenSession;

  @override
  State<VoucherHistoryCard> createState() => _VoucherHistoryCardState();
}

class _VoucherHistoryCardState extends State<VoucherHistoryCard> {
  late bool _expanded = widget.initiallyExpanded;
  List<AttendanceRecord>? _loaded;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (_expanded) _load();
  }

  Future<void> _load() async {
    final load = widget.loadVisits;
    if (load == null || _loaded != null || _loading) return;
    setState(() => _loading = true);
    try {
      final list = await load();
      if (mounted) setState(() => _loaded = list);
    } catch (e) {
      debugPrint('voucher visits: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  static String _date(String iso, String locale) {
    final parsed = DateTime.tryParse(iso);
    return parsed == null
        ? iso
        : DateFormat('d MMM yyyy', locale).format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final term = widget.term;
    final active = term.isActive && term.isWithinTermDates;
    final usedUp = term.sessionsRemaining <= 0;
    final (statusLabel, statusColor) = usedUp
        ? (l.historyStatusUsedUp, AppColors.textSecondary)
        : active
            ? (l.historyStatusActive, AppColors.success)
            : (l.historyStatusExpired, AppColors.error);
    final used = (term.packageSize - term.sessionsRemaining).clamp(
      0,
      term.packageSize,
    );
    final fraction = term.packageSize == 0 ? 0.0 : used / term.packageSize;
    final code = term.voucherCode ?? '';
    final sortedVisits = List<AttendanceRecord>.from(_loaded ?? widget.visits)
      ..sort((a, b) => b.sessionDate.compareTo(a.sessionDate));

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.confirmation_number_outlined,
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.historyVoucherTitle(term.packageSize),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      [
                        if (code.isNotEmpty) code,
                        l.historyValid(
                          _date(term.startDate, l.localeName),
                          _date(term.deadlineDate, l.localeName),
                        ),
                      ].join(' · '),
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              backgroundColor: AppColors.border,
              color: usedUp ? AppColors.textSecondary : AppColors.teal,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  l.historySessionsUsed(used, term.packageSize),
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                l.historyRemaining(term.sessionsRemaining),
                style: TextStyle(
                  color: active ? AppColors.teal : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                setState(() => _expanded = !_expanded);
                if (_expanded) _load();
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                visualDensity: VisualDensity.compact,
              ),
              icon: Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                size: 18,
              ),
              label: Text(
                _expanded
                    ? l.historyHideSessions
                    : l.historyShowSessions(
                        widget.loadVisits != null && _loaded == null
                            ? used
                            : sortedVisits.length),
              ),
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 4),
            if (_loading)
              const LinearProgressIndicator(minHeight: 2)
            else if (sortedVisits.isEmpty)
              Text(
                l.historyNoSessionsYet,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              )
            else
              for (final record in sortedVisits)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: widget.onOpenSession == null
                        ? null
                        : () => widget.onOpenSession!(record),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      child: ClassVisitRow(record: record, dense: true),
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

/// Date, title and time of one class visit with its attendance status.
class ClassVisitRow extends StatelessWidget {
  const ClassVisitRow({super.key, required this.record, this.dense = false});

  final AttendanceRecord record;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final parsed = DateTime.tryParse(record.sessionDate);
    final dateLabel = parsed != null
        ? DateFormat(dense ? 'EEE, d MMM' : 'EEE, d MMM yyyy', l.localeName)
            .format(parsed)
        : record.sessionDate;
    final status = record.normalizedStatus;
    final (label, color, icon) = status == AttendanceRecord.izin
        ? (l.attendanceExcused, AppColors.chipAmberFg, Icons.event_busy)
        : status == AttendanceRecord.alpa
            ? (l.attendanceAbsent, AppColors.error, Icons.cancel_outlined)
            : status == AttendanceRecord.hadir || record.attended
                ? (
                    l.attendancePresent,
                    AppColors.success,
                    Icons.check_circle_outline
                  )
                : (l.attendanceJoined, AppColors.teal, Icons.login);

    return Row(
      children: [
        Icon(icon, color: color, size: dense ? 18 : 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                record.sessionTitle.isNotEmpty
                    ? record.sessionTitle
                    : l.commonClassSession,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: dense ? 13 : 14,
                ),
              ),
              Text(
                [
                  dateLabel,
                  if (record.startMinutes != 0 || record.endMinutes != 0)
                    record.timeRangeLabel,
                ].join(' · '),
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// Build 9A session 2 (supervisor 2026-11-25): a student's history read in
/// pages. The vouchers (few) come first, each reading its own classes when
/// opened; then every class visit, 25 a page, in a date range (default
/// this month), grouped by month on the page.
class PagedClassHistory extends StatefulWidget {
  const PagedClassHistory({
    super.key,
    required this.studentId,
    this.onOpenSession,
    this.vouchersTitle,
    this.padding = const EdgeInsets.all(20),
    this.inline = false,
  });

  /// Inside the caller's own list (the parent's overview).
  final bool inline;

  final String studentId;
  final void Function(AttendanceRecord record)? onOpenSession;
  final String? vouchersTitle;
  final EdgeInsets padding;

  @override
  State<PagedClassHistory> createState() => _PagedClassHistoryState();
}

class _PagedClassHistoryState extends State<PagedClassHistory> {
  late final FirestoreService _firestore = context.read<FirestoreService>();
  late final Stream<List<StudentClassTerm>> _terms =
      _firestore.watchStudentClassTerms(widget.studentId);
  late final PagedController<AttendanceRecord> _pages =
      PagedController<AttendanceRecord>(
    build: (range) => _firestore.studentVisitSource(widget.studentId, range),
  );

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return StreamBuilder<List<StudentClassTerm>>(
      stream: _terms,
      builder: (context, termsSnap) {
        final terms = [...(termsSnap.data ?? const <StudentClassTerm>[])]
          ..sort((a, b) {
            final aActive = a.isActive && a.isWithinTermDates;
            final bActive = b.isActive && b.isWithinTermDates;
            if (aActive != bActive) return aActive ? -1 : 1;
            return b.startDate.compareTo(a.startDate);
          });
        return ListenableBuilder(
          listenable: _pages,
          builder: (context, _) {
            final visits = _pages.items
                .where((r) => r.attended || r.joinedByStudent)
                .toList();
            final byMonth = ClassHistorySection._groupByMonth(visits);
            return PagedListBody<AttendanceRecord>(
              controller: _pages,
              padding: widget.padding,
              inline: widget.inline,
              emptyIcon: Icons.history_outlined,
              emptyTitle: l.studentMyClassesEmptyTitle,
              emptySubtitle: l.studentMyClassesEmptySubtitle,
              header: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(title: widget.vouchersTitle ?? l.historyVouchersTitle),
                  if (terms.isEmpty)
                    AppCard(
                      child: Text(
                        l.historyNoVouchers,
                        style: TextStyle(color: AppColors.textSecondary, height: 1.4),
                      ),
                    )
                  else
                    for (final term in terms)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: VoucherHistoryCard(
                          key: ValueKey(term.id),
                          term: term,
                          loadVisits: () =>
                              _firestore.termVisits(widget.studentId, term.id),
                          initiallyExpanded: false,
                          onOpenSession: widget.onOpenSession,
                        ),
                      ),
                  const SizedBox(height: 16),
                  SectionHeader(
                    title: _pages.total == null
                        ? l.historyAllClasses
                        : '${l.historyAllClasses} · ${l.historyClassesCount(_pages.total!)}',
                  ),
                  DateRangeBar(value: _pages.range, onChanged: _pages.setRange),
                ],
              ),
              itemBuilder: (context, _) => const SizedBox.shrink(),
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final entry in byMonth) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 6),
                      child: Text(
                        DateFormat('MMMM yyyy', l.localeName).format(entry.key),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    for (final record in entry.value)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AppCard(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          onTap: widget.onOpenSession == null
                              ? null
                              : () => widget.onOpenSession!(record),
                          child: ClassVisitRow(record: record),
                        ),
                      ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}
