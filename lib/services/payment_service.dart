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

  /// Staff creates an invoice for [studentId]. Returns the Snap token /
  /// redirect URL so the caller can open the payment page.
  Future<CreatedInvoice> createInvoice({
    required String studentId,
    required int packageSize,
    required int amount,
    required String dueDate,
  }) async {
    try {
      final callable = _functions.httpsCallable('createInvoice');
      final result = await callable.call({
        'studentId': studentId,
        'packageSize': packageSize,
        'amount': amount,
        'dueDate': dueDate,
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

  /// Opens the Midtrans Snap payment page in a browser tab.
  Future<void> openPayment(String? redirectUrl) async {
    final url = redirectUrl?.trim();
    if (url == null || url.isEmpty) {
      throw const PaymentException('No payment link available for this invoice.');
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
