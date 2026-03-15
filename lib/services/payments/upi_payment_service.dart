class UpiPaymentService {
  UpiPaymentService._();

  static final UpiPaymentService instance = UpiPaymentService._();

  static const String upiId = 'eramakoti@ptyes';
  static const String payeeName = 'eRamakoti';
  static const String note = 'Support eRamakoti';

  String buildUpiUrl({
    required int amount,
    String? transactionNote,
  }) {
    final safeAmount = amount <= 0 ? 1 : amount;
    final amountText = safeAmount.toDouble().toStringAsFixed(2);

    return 'upi://pay'
        '?pa=${Uri.encodeComponent(upiId)}'
        '&pn=${Uri.encodeComponent(payeeName)}'
        '&tn=${Uri.encodeComponent(transactionNote?.trim().isNotEmpty == true ? transactionNote!.trim() : note)}'
        '&am=$amountText'
        '&cu=INR';
  }

  String formatAmount(int amount) {
    return '₹$amount';
  }

  String getPaymentInstructions() {
    return 'Scan the QR in any UPI app like Google Pay, PhonePe, Paytm or BHIM to offer support. '
        'If QR scanning is easier, please use that method. '
        'This app does not process or store payment information.';
  }
}