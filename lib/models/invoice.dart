import 'package:cloud_firestore/cloud_firestore.dart';

/// Payment status for a session-package invoice.
///
/// The transition to [paid]/[expired]/[failed] is written **only** by the
/// Midtrans webhook Cloud Function (admin SDK). Clients and rules can never
/// flip an invoice to paid.
enum InvoiceStatus {
  pending('pending'),
  paid('paid'),
  expired('expired'),
  failed('failed');

  const InvoiceStatus(this.value);

  final String value;

  static InvoiceStatus fromValue(String? value) {
    return InvoiceStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => InvoiceStatus.pending,
    );
  }

  bool get isFinal => this != InvoiceStatus.pending;

  String get label => switch (this) {
        InvoiceStatus.pending => 'Pending',
        InvoiceStatus.paid => 'Paid',
        InvoiceStatus.expired => 'Expired',
        InvoiceStatus.failed => 'Failed',
      };
}

class Invoice {
  const Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.studentId,
    required this.teacherId,
    required this.packageSize,
    this.item = 'package',
    required this.amount,
    this.currency = 'IDR',
    required this.status,
    required this.dueDate,
    this.midtransOrderId,
    this.snapToken,
    this.redirectUrl,
    this.studentName,
    this.createdBy,
    this.createdAt,
    this.paidAt,
    this.priceItemId,
    String? kind,
    int? sessions,
    this.description,
    String? paymentMethod,
    this.classTermId,
    this.paidBy,
    this.note,
  })  : kind = kind ?? (item == 'book' ? 'book' : 'sessions'),
        sessions = sessions ?? packageSize,
        paymentMethod =
            paymentMethod ?? (midtransOrderId != null ? 'midtrans' : 'manual');

  final String id;
  final String invoiceNumber;
  final String studentId;
  final String teacherId;
  final int packageSize;

  /// `package` (default) or `book` (HSK materials and textbook, no sessions).
  final String item;
  final int amount;
  final String currency;
  final InvoiceStatus status;

  /// `yyyy-MM-dd`
  final String dueDate;
  final String? midtransOrderId;
  final String? snapToken;
  final String? redirectUrl;
  final String? studentName;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? paidAt;

  /// Row of the admin Price list this invoice was made from.
  final String? priceItemId;

  /// What paying gives: `sessions`, `book`, `registration` or `other`.
  final String kind;

  /// Sessions credited on payment (0 for book / registration / other).
  final int sessions;
  final String? description;

  /// `midtrans` (online link), `manual` (recorded by staff, unpaid),
  /// `cash` or `transfer` (settled by hand by an admin).
  final String paymentMethod;

  /// Set when the invoice pays for a term that already exists (a teacher
  /// added the term first); payment then marks that term paid instead of
  /// creating a new one.
  final String? classTermId;
  final String? paidBy;
  final String? note;

  bool get creditsSessions => kind == 'sessions' && sessions > 0;
  bool get isOnline => (redirectUrl ?? '').isNotEmpty;
  bool get isOverdue =>
      isPending &&
      dueDate.isNotEmpty &&
      (DateTime.tryParse(dueDate)?.isBefore(DateTime.now()) ?? false);

  String get methodLabel => switch (paymentMethod) {
        'midtrans' => 'Online',
        'cash' => 'Cash',
        'transfer' => 'Transfer',
        _ => isPending ? 'At the centre' : 'Manual',
      };

  bool get isBook => item == 'book';

  /// What the invoice is for, for lists and cards.
  String get itemLabel {
    if (description != null && description!.isNotEmpty) return description!;
    if (isBook) return 'HSK materials & book';
    if (creditsSessions) return '$sessions sessions';
    return kind;
  }

  bool get isPending => status == InvoiceStatus.pending;
  bool get isPaid => status == InvoiceStatus.paid;
  bool get isPayable => status == InvoiceStatus.pending;

  /// `dueDate` is stored as `yyyy-MM-dd` by the server; tolerate a Timestamp
  /// (older or hand-written docs) instead of failing the whole list.
  static String _dateString(Object? raw) {
    if (raw is String) return raw;
    if (raw is Timestamp)
      return raw.toDate().toIso8601String().substring(0, 10);
    return '';
  }

  factory Invoice.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Invoice(
      id: doc.id,
      invoiceNumber: data['invoiceNumber'] as String? ?? doc.id,
      studentId: data['studentId'] as String? ?? '',
      teacherId: data['teacherId'] as String? ?? '',
      packageSize: data['packageSize'] as int? ?? 0,
      item: data['item'] as String? ?? 'package',
      amount: (data['amount'] as num?)?.toInt() ?? 0,
      currency: data['currency'] as String? ?? 'IDR',
      status: InvoiceStatus.fromValue(data['status'] as String?),
      dueDate: _dateString(data['dueDate']),
      midtransOrderId: data['midtransOrderId'] as String?,
      snapToken: data['snapToken'] as String?,
      redirectUrl: data['redirectUrl'] as String?,
      studentName: data['studentName'] as String?,
      createdBy: data['createdBy'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      paidAt: (data['paidAt'] as Timestamp?)?.toDate(),
      priceItemId: data['priceItemId'] as String?,
      kind: data['kind'] as String?,
      sessions: (data['sessions'] as num?)?.toInt(),
      description: data['description'] as String?,
      paymentMethod: data['paymentMethod'] as String?,
      classTermId: data['classTermId'] as String?,
      paidBy: data['paidBy'] as String?,
      note: data['note'] as String?,
    );
  }
}
