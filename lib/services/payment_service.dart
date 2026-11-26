import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
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

  /// Build 5: a student (for themself) or a linked parent buys a voucher
  /// package. [acceptedTerms] must be true (the flyer's terms). A second
  /// call while one purchase is open returns that invoice again.
  Future<CreatedInvoice> buyVoucher({
    required String studentId,
    required String priceItemId,
    String classDay = '',
  }) async {
    try {
      final result = await _functions.httpsCallable('createInvoice').call({
        'studentId': studentId,
        'priceItemId': priceItemId,
        'acceptedTerms': true,
        if (classDay.isNotEmpty) 'classDay': classDay,
      });
      final data = (result.data as Map).cast<String, dynamic>();
      return CreatedInvoice(
        invoiceId: data['invoiceId'] as String? ?? '',
        snapToken: data['snapToken'] as String?,
        redirectUrl: data['redirectUrl'] as String?,
      );
    } on FirebaseFunctionsException catch (e) {
      throw PaymentException(
        e.message ?? 'Could not start the payment. Try again.',
      );
    }
  }

  /// Admin records a cash or bank-transfer payment. The server flips the
  /// invoice to paid and credits the sessions (or marks the linked term paid).
  ///
  /// Owner 2026-11-26: [proofBytes] is the photo of the payment (receipt or
  /// transfer screenshot). It is uploaded first to
  /// `payment_proofs/{invoiceId}/` and the function checks it is there.
  Future<void> markInvoicePaid({
    required String invoiceId,
    required String method, // 'cash' | 'transfer'
    String? note,
    required Uint8List proofBytes,
    required String proofName,
  }) async {
    final ext = _imageExt(proofName);
    final path = 'payment_proofs/$invoiceId/'
        '${DateTime.now().millisecondsSinceEpoch}.$ext';
    final ref = FirebaseStorage.instance.ref(path);
    try {
      await ref.putData(
        proofBytes,
        SettableMetadata(contentType: ext == 'png' ? 'image/png'
            : ext == 'webp' ? 'image/webp' : 'image/jpeg'),
      );
    } catch (e) {
      throw PaymentException('Could not upload the payment photo. Try again. ($e)');
    }
    try {
      await _functions.httpsCallable('markInvoicePaid').call({
        'invoiceId': invoiceId,
        'method': method,
        'proofPath': path,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      });
    } on FirebaseFunctionsException catch (e) {
      // The invoice was not marked paid: the photo is not kept.
      try {
        await ref.delete();
      } catch (_) {}
      throw PaymentException(
        e.message ?? 'Could not record the payment. Try again.',
      );
    }
  }

  /// A link to the payment photo of a paid invoice (admins only).
  Future<String> paymentProofUrl(String proofPath) =>
      FirebaseStorage.instance.ref(proofPath).getDownloadURL();

  static String _imageExt(String name) {
    final dot = name.lastIndexOf('.');
    final ext = dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
    return switch (ext) {
      'png' => 'png',
      'webp' => 'webp',
      _ => 'jpg',
    };
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
