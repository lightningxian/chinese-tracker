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
  });

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

  bool get isBook => item == 'book';

  /// What the invoice is for, for lists and cards.
  String get itemLabel =>
      isBook ? 'HSK materials & book' : '$packageSize sessions';

  bool get isPending => status == InvoiceStatus.pending;
  bool get isPaid => status == InvoiceStatus.paid;
  bool get isPayable => status == InvoiceStatus.pending;

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
      dueDate: data['dueDate'] as String? ?? '',
      midtransOrderId: data['midtransOrderId'] as String?,
      snapToken: data['snapToken'] as String?,
      redirectUrl: data['redirectUrl'] as String?,
      studentName: data['studentName'] as String?,
      createdBy: data['createdBy'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      paidAt: (data['paidAt'] as Timestamp?)?.toDate(),
    );
  }
}
