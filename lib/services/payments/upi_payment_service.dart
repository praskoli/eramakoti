import 'package:url_launcher/url_launcher.dart';

class UpiPaymentService {
  UpiPaymentService._();

  static final UpiPaymentService instance = UpiPaymentService._();

  static const String upiId = '9121011887@pthdfc';
  static const String payeeName = 'Koli Prasanth';
  static const String note = 'Support eRamakoti';

  Future<void> launchPayment({
    required int amount,
  }) async {
    final uri = Uri(
      scheme: 'upi',
      host: 'pay',
      queryParameters: {
        'pa': upiId,
        'pn': payeeName,
        'tn': note,
        if (amount > 0) 'am': amount.toString(),
        'cu': 'INR',
      },
    );

    final ok = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!ok) {
      throw Exception('No UPI app found on this device');
    }
  }
}