import 'package:cloud_firestore/cloud_firestore.dart';

enum DonationPaymentState {
  initiated,
  appLaunched,
  submitted,
  success,
  failed,
  cancelled,
  unknown,
  launchFailed,
}

extension DonationPaymentStateX on DonationPaymentState {
  String get value {
    switch (this) {
      case DonationPaymentState.initiated:
        return 'initiated';
      case DonationPaymentState.appLaunched:
        return 'app_launched';
      case DonationPaymentState.submitted:
        return 'submitted';
      case DonationPaymentState.success:
        return 'success';
      case DonationPaymentState.failed:
        return 'failed';
      case DonationPaymentState.cancelled:
        return 'cancelled';
      case DonationPaymentState.unknown:
        return 'unknown';
      case DonationPaymentState.launchFailed:
        return 'launch_failed';
    }
  }
}

class DonationPaymentRecord {
  final String id;
  final String uid;
  final int amount;
  final String currency;
  final String upiId;
  final String payeeName;
  final String note;
  final String transactionRef;
  final String? transactionId;
  final String? approvalRefNo;
  final String? responseCode;
  final String? rawResponse;
  final String? appPackage;
  final String? appName;
  final DonationPaymentState state;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool userReportedSuccess;

  const DonationPaymentRecord({
    required this.id,
    required this.uid,
    required this.amount,
    required this.currency,
    required this.upiId,
    required this.payeeName,
    required this.note,
    required this.transactionRef,
    required this.state,
    required this.createdAt,
    required this.updatedAt,
    this.transactionId,
    this.approvalRefNo,
    this.responseCode,
    this.rawResponse,
    this.appPackage,
    this.appName,
    this.userReportedSuccess = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'amount': amount,
      'currency': currency,
      'upiId': upiId,
      'payeeName': payeeName,
      'note': note,
      'transactionRef': transactionRef,
      'transactionId': transactionId,
      'approvalRefNo': approvalRefNo,
      'responseCode': responseCode,
      'rawResponse': rawResponse,
      'appPackage': appPackage,
      'appName': appName,
      'state': state.value,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'userReportedSuccess': userReportedSuccess,
    };
  }
}