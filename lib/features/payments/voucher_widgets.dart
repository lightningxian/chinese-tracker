import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/money_format.dart';
import '../../core/widgets/app_card.dart';
import '../../l10n/l10n.dart';
import '../../models/pricing_settings.dart';
import '../../models/student_class_term.dart';
import '../../services/firestore_service.dart';
import '../../services/payment_service.dart';

/// Build 5 (docs/PLAN.md §4, Must 2): what the buy sheet shows, as pure
/// logic (tested in `test/voucher_purchase_test.dart`).
class VoucherOffer {
  const VoucherOffer({
    required this.item,
    required this.validDays,
  });

  final PriceItem item;

  /// The package's validity, or the Price list's fallback.
  final int validDays;

  String get title =>
      item.nameChinese.isEmpty ? item.name : '${item.nameChinese} · ${item.name}';

  /// The session packages a student or parent may buy, cheapest first.
  static List<VoucherOffer> fromPricing(PricingSettings p) => [
        for (final it in p.items.where((i) => i.buyable))
          VoucherOffer(
            item: it,
            validDays: it.validDays > 0 ? it.validDays : p.termValidDays,
          ),
      ]..sort((a, b) => a.item.price.compareTo(b.item.price));

  /// **Bayar** is enabled only with a package picked and the terms ticked.
  static bool canPay({required VoucherOffer? picked, required bool accepted}) =>
      picked != null && accepted;
}

/// Opens the buy sheet for [studentId] (the student themself or a linked
/// parent's child).
Future<void> showBuyVoucherSheet(BuildContext context, {required String studentId}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _BuyVoucherSheet(studentId: studentId),
  );
}

class _BuyVoucherSheet extends StatefulWidget {
  const _BuyVoucherSheet({required this.studentId});

  final String studentId;

  @override
  State<_BuyVoucherSheet> createState() => _BuyVoucherSheetState();
}

class _BuyVoucherSheetState extends State<_BuyVoucherSheet> {
  VoucherOffer? _picked;

  /// Owner 2026-11-23 (second round): no class day at purchase; the
  /// student books any class until the voucher's deadline.
  bool _accepted = false;
  bool _busy = false;
  String? _error;

  Future<void> _pay() async {
    final picked = _picked;
    if (picked == null) return;
    final payments = context.read<PaymentService>();
    final navigator = Navigator.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final created = await payments.buyVoucher(
        studentId: widget.studentId,
        priceItemId: picked.item.id,
      );
      await payments.openPayment(created.redirectUrl);
      navigator.pop();
    } on PaymentException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final terms = [l.voucherTerm1, l.voucherTerm2, l.voucherTerm3, l.voucherTerm4];
    return StreamBuilder<PricingSettings>(
      stream: context.read<FirestoreService>().watchPricing(),
      builder: (context, snap) {
        final offers = VoucherOffer.fromPricing(snap.data ?? PricingSettings.defaults);
        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
                20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l.voucherBuyTitle,
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.navy)),
                const SizedBox(height: 4),
                Text(l.voucherBuyIntro, style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                if (offers.isEmpty)
                  Text(l.voucherNoPackages, style: TextStyle(color: AppColors.textSecondary)),
                for (final o in offers)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _OfferCard(
                      offer: o,
                      selected: _picked?.item.id == o.item.id,
                      onTap: _busy ? null : () => setState(() => _picked = o),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(l.voucherTermsTitle,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                for (final t in terms)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('•  '),
                        Expanded(child: Text(t)),
                      ],
                    ),
                  ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _accepted,
                  onChanged: _busy ? null : (v) => setState(() => _accepted = v ?? false),
                  title: Text(l.voucherAgree),
                ),
                if (_error != null) ...[
                  Text(_error!, style: TextStyle(color: AppColors.error)),
                  const SizedBox(height: 8),
                ],
                FilledButton.icon(
                  onPressed: _busy ||
                          !VoucherOffer.canPay(picked: _picked, accepted: _accepted)
                      ? null
                      : _pay,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.lock_outline),
                  label: Text(_picked == null
                      ? l.voucherPay
                      : '${l.voucherPay} · ${formatRupiah(_picked!.item.price)}'),
                ),
                const SizedBox(height: 6),
                Text(l.voucherPayNote,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({required this.offer, required this.selected, required this.onTap});

  final VoucherOffer offer;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final o = offer;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.teal : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? AppColors.teal : AppColors.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(o.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text(l.voucherOfferLine(o.item.sessions, o.validDays),
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Text(formatRupiah(o.item.price),
                style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy)),
          ],
        ),
      ),
    );
  }
}

/// A row of `voucher_history` (purchase or expiry).
class VoucherHistoryEntry {
  const VoucherHistoryEntry({
    required this.kind,
    required this.sessions,
    required this.nameChinese,
    required this.date,
  });

  final String kind;
  final int sessions;
  final String nameChinese;
  final DateTime? date;

  factory VoucherHistoryEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? const <String, dynamic>{};
    return VoucherHistoryEntry(
      kind: m['kind'] as String? ?? '',
      sessions: (m['sessions'] as num?)?.toInt() ?? 0,
      nameChinese: m['nameChinese'] as String? ?? '',
      date: (m['date'] as Timestamp?)?.toDate(),
    );
  }
}

/// Build 5 (Must 7): the student's vouchers (Chinese name, sessions left,
/// booked, deadline with days left, status) and the voucher history, with a
/// **Beli voucher** button. Used by the student and the parent Payments tab.
class VoucherSection extends StatelessWidget {
  const VoucherSection({super.key, required this.studentId, this.canBuy = true});

  final String studentId;
  final bool canBuy;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final firestore = context.read<FirestoreService>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(l.voucherMyVouchers,
                  style: TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.navy)),
            ),
            if (canBuy)
              FilledButton.icon(
                onPressed: () => showBuyVoucherSheet(context, studentId: studentId),
                style: FilledButton.styleFrom(backgroundColor: AppColors.navy),
                icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                label: Text(l.voucherBuy),
              ),
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<StudentClassTerm>>(
          stream: firestore.watchStudentClassTerms(studentId),
          builder: (context, snap) {
            final terms = (snap.data ?? const <StudentClassTerm>[])
                .where((t) => t.isActive || t.isExpired || t.sessionsRemaining > 0)
                .take(4)
                .toList();
            if (terms.isEmpty) {
              return AppCard(
                child: Text(l.voucherNone, style: TextStyle(color: AppColors.textSecondary)),
              );
            }
            return Column(
              children: [
                for (final t in terms)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _VoucherCard(term: t),
                  ),
              ],
            );
          },
        ),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('voucher_history')
              .where('studentId', isEqualTo: studentId)
              .snapshots(),
          builder: (context, snap) {
            final rows = (snap.data?.docs ?? const [])
                .map(VoucherHistoryEntry.fromDoc)
                .toList()
              ..sort((a, b) => (b.date ?? DateTime(2000)).compareTo(a.date ?? DateTime(2000)));
            if (rows.isEmpty) return const SizedBox.shrink();
            return AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l.voucherHistory, style: const TextStyle(fontWeight: FontWeight.w700)),
                  for (final r in rows.take(10))
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        r.kind == 'expiry' ? Icons.event_busy_outlined : Icons.add_card_outlined,
                        color: r.kind == 'expiry' ? AppColors.error : AppColors.teal,
                      ),
                      title: Text(r.kind == 'expiry'
                          ? l.voucherHistoryExpiry(-r.sessions)
                          : l.voucherHistoryPurchase(r.sessions)),
                      subtitle: Text([
                        if (r.nameChinese.isNotEmpty) r.nameChinese,
                        if (r.date != null) DateFormat.yMMMd().format(r.date!),
                      ].join(' · ')),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _VoucherCard extends StatelessWidget {
  const _VoucherCard({required this.term});

  final StudentClassTerm term;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = term;
    final days = t.daysLeft();
    final status = t.isExpired
        ? l.voucherStatusExpired
        : t.sessionsRemaining <= 0
            ? l.voucherStatusUsedUp
            : l.voucherStatusActive;
    final color = t.isExpired || t.sessionsRemaining <= 0
        ? AppColors.error
        : (t.sessionsRemaining <= 2 || (days ?? 99) <= 7)
            ? AppColors.chipAmberFg
            : AppColors.success;
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.nameChinese.isEmpty ? l.voucherSessionsPackage(t.packageSize) : t.nameChinese,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    l.voucherLeft(t.sessionsRemaining, t.packageSize),
                    l.voucherBooked(t.sessionsBooked),
                    if (t.deadlineDate.isNotEmpty)
                      days != null && days >= 0
                          ? l.voucherUntil(t.deadlineDate, days)
                          : l.voucherEnded(t.deadlineDate),
                    if (t.isExpired && t.sessionsForfeited > 0)
                      l.voucherForfeited(t.sessionsForfeited),
                  ].join(' · '),
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(status,
                style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
