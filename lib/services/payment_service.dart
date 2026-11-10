import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';

/// Result of a createInvoice call.
class CreatedInvoice {
  const CreatedInvoice({
    required this.invoiceId,
    this.snapToken,
    this.redirectUrl,
  });

  final String invoiceId;
  final String? snapToken;
  final String? redirectUrl;
}

class PaymentException implements Exception {
  const PaymentException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Thin client over the `createInvoice` Cloud Function + Midtrans Snap.
///
/// The Midtrans **Server Key** never touches the client — the callable runs on
/// Cloud Functions (Blaze) and returns a Snap token / redirect URL that the app
/// opens. The webhook (`midtransNotification`) is what marks an invoice paid.
class PaymentService {
  PaymentService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  /// Staff creates an online invoice for [studentId] from a Price list row.
  /// The server looks up the price; [classTermId] links the invoice to a term
  /// that already exists. Returns the Snap token / redirect URL.
  Future<CreatedInvoice> createInvoice({
    required String studentId,
    required String priceItemId,
    required String dueDate,
    String? classTermId,
  }) async {
    try {
      final callable = _functions.httpsCallable('createInvoice');
      final result = await callable.call({
        'studentId': studentId,
        'priceItemId': priceItemId,
        'dueDate': dueDate,
        if (classTermId != null) 'classTermId': classTermId,
      });
      final data = (result.data as Map).cast<String, dynamic>();
      return CreatedInvoice(
        invoiceId: data['invoiceId'] as String? ?? '',
        snapToken: data['snapToken'] as String?,
        redirectUrl: data['redirectUrl'] as String?,
      );
    } on FirebaseFunctionsException catch (e) {
      throw PaymentException(
        e.message ?? 'Could not create the invoice. Try again.',
      );
    }
  }

  /// Admin records a cash or bank-transfer payment. The server flips the
  /// invoice to paid and credits the sessions (or marks the linked term paid).
  Future<void> markInvoicePaid({
    required String invoiceId,
    required String method, // 'cash' | 'transfer'
    String? note,
  }) async {
    try {
      await _functions.httpsCallable('markInvoicePaid').call({
        'invoiceId': invoiceId,
        'method': method,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      });
    } on FirebaseFunctionsException catch (e) {
      throw PaymentException(
        e.message ?? 'Could not record the payment. Try again.',
      );
    }
  }

  /// Opens the Midtrans Snap payment page in a browser tab.
  Future<void> openPayment(String? redirectUrl) async {
    final url = redirectUrl?.trim();
    if (url == null || url.isEmpty) {
      throw const PaymentException(
          'No payment link available for this invoice.');
    }
    final uri = Uri.tryParse(url);
    if (uri == null) {
      throw const PaymentException('Invalid payment link.');
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      throw const PaymentException('Could not open the payment page.');
    }
  }
}
