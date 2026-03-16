import 'package:url_launcher/url_launcher.dart';

class UpiPaymentService {
  UpiPaymentService._();

  static final UpiPaymentService instance = UpiPaymentService._();

  static const String defaultUpiId = '9121011887@pthdfc';
  static const String defaultPayeeName = 'KOLI PRASANTH';
  static const String defaultNote = 'Support eRamakoti';

  static const String upiId = defaultUpiId;
  static const String payeeName = defaultPayeeName;
  static const String note = defaultNote;

  int sanitizeAmount(int amount) {
    if (amount <= 0) return 1;
    return amount;
  }

  String formatAmount(int amount) {
    return '₹${sanitizeAmount(amount)}';
  }

  Uri buildUpiUri({
    required int amount,
    String? transactionNote,
    bool includeNote = true,
    String? upiId,
    String? payeeName,
  }) {
    final safeAmount = sanitizeAmount(amount);
    final resolvedUpiId = (upiId ?? defaultUpiId).trim();
    final resolvedPayeeName = (payeeName ?? defaultPayeeName).trim();

    final params = <String, String>{
      'pa': resolvedUpiId,
      'pn': resolvedPayeeName,
      'am': safeAmount.toString(),
      'cu': 'INR',
      'mc': '0000',
      'mode': '02',
      'purpose': '00',
    };

    if (includeNote) {
      final usedNote =
      (transactionNote != null && transactionNote.trim().isNotEmpty)
          ? transactionNote.trim()
          : defaultNote;
      params['tn'] = usedNote;
    }

    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return Uri.parse('upi://pay?$query');
  }

  String buildUpiUrl({
    required int amount,
    String? transactionNote,
    bool includeNote = true,
    String? upiId,
    String? payeeName,
  }) {
    return buildUpiUri(
      amount: amount,
      transactionNote: transactionNote,
      includeNote: includeNote,
      upiId: upiId,
      payeeName: payeeName,
    ).toString();
  }

  Future<bool> launchUpiPayment({
    required int amount,
    String? transactionNote,
    bool includeNote = true,
    String? upiId,
    String? payeeName,
  }) async {
    final uri = buildUpiUri(
      amount: amount,
      transactionNote: transactionNote,
      includeNote: includeNote,
      upiId: upiId,
      payeeName: payeeName,
    );

    return launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  Future<bool> canOpenUpi({
    String? upiId,
    String? payeeName,
  }) async {
    try {
      final uri = buildUpiUri(
        amount: 1,
        includeNote: false,
        upiId: upiId,
        payeeName: payeeName,
      );
      return await canLaunchUrl(uri);
    } catch (_) {
      return false;
    }
  }

  String getPaymentInstructions({String? payeeName}) {
    final resolvedPayeeName = (payeeName ?? defaultPayeeName).trim();
    return 'Pay through any UPI app. The app will open with the selected amount and payee details for $resolvedPayeeName.';
  }
}
