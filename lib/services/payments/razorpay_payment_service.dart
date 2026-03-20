import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

enum RazorpayPaymentStatus {
  success,
  failed,
  cancelled,
  externalWallet,
}

class RazorpayPaymentResult {
  final RazorpayPaymentStatus status;
  final String? donationId;
  final String? orderId;
  final String? paymentId;
  final String? signature;
  final String? externalWalletName;
  final String? message;
  final int? code;

  final int? requestedAmount;
  final String? supporterName;
  final String? supporterMessage;
  final bool anonymous;

  const RazorpayPaymentResult({
    required this.status,
    this.donationId,
    this.orderId,
    this.paymentId,
    this.signature,
    this.externalWalletName,
    this.message,
    this.code,
    this.requestedAmount,
    this.supporterName,
    this.supporterMessage,
    this.anonymous = false,
  });

  bool get isSuccess => status == RazorpayPaymentStatus.success;
  bool get isFailed => status == RazorpayPaymentStatus.failed;
  bool get isCancelled => status == RazorpayPaymentStatus.cancelled;
}

class RazorpayPaymentException implements Exception {
  final String message;
  final Object? cause;

  const RazorpayPaymentException(this.message, [this.cause]);

  @override
  String toString() => message;
}

class RazorpayPaymentRequest {
  final int amount;
  final String source;
  final String supportType;
  final String supporterName;
  final String supporterMessage;
  final bool anonymous;
  final String? sourceMandaliId;
  final String? sourceMandaliName;
  final String? sourceChallengeId;

  const RazorpayPaymentRequest({
    required this.amount,
    required this.source,
    this.supportType = 'individual',
    this.supporterName = '',
    this.supporterMessage = '',
    this.anonymous = false,
    this.sourceMandaliId,
    this.sourceMandaliName,
    this.sourceChallengeId,
  });
}

class RazorpayPaymentService {
  RazorpayPaymentService._();

  static final RazorpayPaymentService instance = RazorpayPaymentService._();

  static const String _functionsRegion = 'asia-south1';

  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: _functionsRegion,
  );
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Razorpay? _razorpay;
  Completer<RazorpayPaymentResult>? _paymentCompleter;
  String? _activeDonationId;
  String? _activeOrderId;
  RazorpayPaymentRequest? _activeRequest;
  bool _initialized = false;

  void initialize() {
    if (_initialized) return;

    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    _initialized = true;
  }

  bool get isPaymentInProgress =>
      _paymentCompleter != null && !_paymentCompleter!.isCompleted;

  Future<User> _requireFreshUser() async {
    final user = _auth.currentUser;

    debugPrint(
      'RAZORPAY AUTH CHECK 1: currentUser=${user?.uid}, email=${user?.email}',
    );

    if (user == null) {
      throw const RazorpayPaymentException(
        'No Firebase user found. Please log in again.',
      );
    }

    try {
      final token = await user.getIdToken();
      final hasToken = token != null && token.isNotEmpty;

      debugPrint(
        'RAZORPAY AUTH CHECK 2: token available, hasToken=$hasToken',
      );
    } catch (e, st) {
      debugPrint('RAZORPAY AUTH CHECK 2 FAILED: $e');
      debugPrintStack(stackTrace: st);
      throw RazorpayPaymentException(
        'Token refresh failed: $e',
        e,
      );
    }

    return user;
  }

  Future<RazorpayPaymentResult> startPayment({
    required RazorpayPaymentRequest request,
  }) async {
    initialize();

    if (isPaymentInProgress) {
      throw const RazorpayPaymentException(
        'Another payment is already in progress.',
      );
    }

    if (request.amount < 1) {
      throw const RazorpayPaymentException(
        'Amount must be at least ₹1.',
      );
    }

    try {
      final user = await _requireFreshUser();

      debugPrint('FIREBASE PROJECT ID: ${Firebase.app().options.projectId}');
      debugPrint('FIREBASE AUTH UID: ${FirebaseAuth.instance.currentUser?.uid}');
      debugPrint('FUNCTIONS REGION: $_functionsRegion');

      final createOrderCallable = _functions.httpsCallable(
        'createRazorpayOrder',
      );

      final response = await createOrderCallable.call(<String, dynamic>{
        'amount': request.amount,
        'source': request.source.trim(),
        'supportType': request.supportType.trim().isEmpty
            ? 'individual'
            : request.supportType.trim(),
        'supporterName': request.supporterName.trim(),
        'supporterMessage': request.supporterMessage.trim(),
        'anonymous': request.anonymous,
        'sourceMandaliId': request.sourceMandaliId?.trim(),
        'sourceMandaliName': request.sourceMandaliName?.trim(),
        'sourceChallengeId': request.sourceChallengeId?.trim(),
      });

      final data = Map<String, dynamic>.from(response.data as Map);

      final success = data['success'] == true;
      if (!success) {
        throw const RazorpayPaymentException(
          'Could not start payment. Please try again.',
        );
      }

      final donationId = (data['donationId'] ?? '').toString().trim();
      final orderId = (data['orderId'] ?? '').toString().trim();
      final razorpayKeyId = (data['razorpayKeyId'] ?? '').toString().trim();
      final amountInPaise = (data['amount'] as num?)?.toInt() ?? 0;
      final currency = (data['currency'] ?? 'INR').toString().trim();
      final name = (data['name'] ?? 'eRamakoti').toString().trim();
      final description =
      (data['description'] ?? 'Offer Support').toString().trim();

      final prefill =
      Map<String, dynamic>.from(data['prefill'] as Map? ?? const {});
      final notes = Map<String, dynamic>.from(data['notes'] as Map? ?? const {});

      if (donationId.isEmpty ||
          orderId.isEmpty ||
          razorpayKeyId.isEmpty ||
          amountInPaise <= 0) {
        throw const RazorpayPaymentException(
          'Invalid order details received from server.',
        );
      }

      _activeDonationId = donationId;
      _activeOrderId = orderId;
      _activeRequest = request;
      _paymentCompleter = Completer<RazorpayPaymentResult>();

      final options = <String, Object?>{
        'key': razorpayKeyId,
        'amount': amountInPaise,
        'currency': currency,
        'name': name,
        'description': description,
        'order_id': orderId,
        'prefill': <String, String>{
          'name': (prefill['name'] ?? '').toString().isNotEmpty
              ? (prefill['name'] ?? '').toString()
              : (user.displayName ?? ''),
          'email': (prefill['email'] ?? '').toString().isNotEmpty
              ? (prefill['email'] ?? '').toString()
              : (user.email ?? ''),
          'contact': (prefill['contact'] ?? '').toString(),
        },
        'notes': <String, String>{
          'donationId': donationId,
          'source': (notes['source'] ?? '').toString(),
          'supportType': (notes['supportType'] ?? '').toString(),
        },
        'theme': <String, String>{
          'color': '#FF9E2C',
        },
      };

      _razorpay!.open(options);

      return _paymentCompleter!.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () async {
          final donationId = _activeDonationId;
          final orderId = _activeOrderId;
          final activeRequest = _activeRequest;

          await _markFailed(
            reason: 'payment_timeout',
          );

          _clearActiveState();

          return RazorpayPaymentResult(
            status: RazorpayPaymentStatus.failed,
            donationId: donationId,
            orderId: orderId,
            message: 'Payment timed out. Please try again.',
            requestedAmount: activeRequest?.amount,
            supporterName: activeRequest?.supporterName,
            supporterMessage: activeRequest?.supporterMessage,
            anonymous: activeRequest?.anonymous ?? false,
          );
        },
      );
    } on FirebaseFunctionsException catch (e, st) {
      debugPrint('RAZORPAY create order FirebaseFunctionsException: $e');
      debugPrintStack(stackTrace: st);
      throw RazorpayPaymentException(
        _friendlyFunctionsMessage(e),
        e,
      );
    } catch (e, st) {
      debugPrint('RAZORPAY startPayment error: $e');
      debugPrintStack(stackTrace: st);
      if (e is RazorpayPaymentException) rethrow;
      throw RazorpayPaymentException(
        'Could not start payment. Please try again.',
        e,
      );
    }
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final completer = _paymentCompleter;
    if (completer == null || completer.isCompleted) return;

    final donationId = _activeDonationId;
    final trimmedOrderId = response.orderId?.trim();
    final orderId = (trimmedOrderId != null && trimmedOrderId.isNotEmpty)
        ? trimmedOrderId
        : (_activeOrderId ?? '');
    final paymentId = response.paymentId?.trim() ?? '';
    final signature = response.signature?.trim() ?? '';
    final activeRequest = _activeRequest;

    try {
      await _requireFreshUser();

      if (donationId == null || donationId.isEmpty || orderId.isEmpty) {
        throw const RazorpayPaymentException(
          'Payment completed, but local order context is missing.',
        );
      }

      final verifyCallable = _functions.httpsCallable(
        'verifyRazorpayPayment',
      );

      final verifyResponse = await verifyCallable.call(<String, dynamic>{
        'donationId': donationId,
        'razorpayOrderId': orderId,
        'razorpayPaymentId': paymentId,
        'razorpaySignature': signature,
      });

      final data = Map<String, dynamic>.from(verifyResponse.data as Map);
      final success = data['success'] == true;
      final status = (data['status'] ?? '').toString();

      if (!success || status != 'verified') {
        throw const RazorpayPaymentException(
          'Payment verification failed.',
        );
      }

      completer.complete(
        RazorpayPaymentResult(
          status: RazorpayPaymentStatus.success,
          donationId: donationId,
          orderId: orderId,
          paymentId: paymentId,
          signature: signature,
          message: 'Payment successful.',
          requestedAmount: activeRequest?.amount,
          supporterName: activeRequest?.supporterName,
          supporterMessage: activeRequest?.supporterMessage,
          anonymous: activeRequest?.anonymous ?? false,
        ),
      );
    } on FirebaseFunctionsException catch (e, st) {
      debugPrint('RAZORPAY verify FirebaseFunctionsException: $e');
      debugPrintStack(stackTrace: st);

      completer.complete(
        RazorpayPaymentResult(
          status: RazorpayPaymentStatus.failed,
          donationId: donationId,
          orderId: orderId,
          paymentId: paymentId,
          message: _friendlyFunctionsMessage(e),
          code: e.code.hashCode,
          requestedAmount: activeRequest?.amount,
          supporterName: activeRequest?.supporterName,
          supporterMessage: activeRequest?.supporterMessage,
          anonymous: activeRequest?.anonymous ?? false,
        ),
      );
    } catch (e, st) {
      debugPrint('RAZORPAY _handlePaymentSuccess error: $e');
      debugPrintStack(stackTrace: st);

      completer.complete(
        RazorpayPaymentResult(
          status: RazorpayPaymentStatus.failed,
          donationId: donationId,
          orderId: orderId,
          paymentId: paymentId,
          message: e is RazorpayPaymentException
              ? e.message
              : 'Payment verification failed. Please contact support if money was deducted.',
          requestedAmount: activeRequest?.amount,
          supporterName: activeRequest?.supporterName,
          supporterMessage: activeRequest?.supporterMessage,
          anonymous: activeRequest?.anonymous ?? false,
        ),
      );
    } finally {
      _clearActiveState();
    }
  }

  Future<void> _handlePaymentError(PaymentFailureResponse response) async {
    final completer = _paymentCompleter;
    if (completer == null || completer.isCompleted) return;

    final code = response.code ?? -1;
    final rawMessage = (response.message ?? '').trim();
    final donationId = _activeDonationId;
    final orderId = _activeOrderId;
    final activeRequest = _activeRequest;

    final cancelled = _isCancellation(code, rawMessage);
    final reason = cancelled
        ? 'payment_cancelled'
        : (rawMessage.isNotEmpty ? rawMessage : 'payment_failed');

    await _markFailed(reason: reason);

    completer.complete(
      RazorpayPaymentResult(
        status: cancelled
            ? RazorpayPaymentStatus.cancelled
            : RazorpayPaymentStatus.failed,
        donationId: donationId,
        orderId: orderId,
        code: code,
        message: cancelled
            ? 'Payment cancelled.'
            : (rawMessage.isNotEmpty
            ? rawMessage
            : 'Payment failed. Please try again.'),
        requestedAmount: activeRequest?.amount,
        supporterName: activeRequest?.supporterName,
        supporterMessage: activeRequest?.supporterMessage,
        anonymous: activeRequest?.anonymous ?? false,
      ),
    );

    _clearActiveState();
  }

  Future<void> _handleExternalWallet(ExternalWalletResponse response) async {
    final completer = _paymentCompleter;
    if (completer == null || completer.isCompleted) return;

    final activeRequest = _activeRequest;

    completer.complete(
      RazorpayPaymentResult(
        status: RazorpayPaymentStatus.externalWallet,
        donationId: _activeDonationId,
        orderId: _activeOrderId,
        externalWalletName: response.walletName?.trim(),
        message: response.walletName?.trim().isNotEmpty == true
            ? 'External wallet selected: ${response.walletName!.trim()}'
            : 'External wallet selected.',
        requestedAmount: activeRequest?.amount,
        supporterName: activeRequest?.supporterName,
        supporterMessage: activeRequest?.supporterMessage,
        anonymous: activeRequest?.anonymous ?? false,
      ),
    );

    _clearActiveState();
  }

  Future<void> _markFailed({
    required String reason,
  }) async {
    final donationId = _activeDonationId;
    if (donationId == null || donationId.isEmpty) return;

    try {
      await _requireFreshUser();

      final callable = _functions.httpsCallable('markRazorpayPaymentFailed');
      await callable.call(<String, dynamic>{
        'donationId': donationId,
        'reason': reason,
      });
    } catch (e, st) {
      debugPrint('RAZORPAY _markFailed error: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  bool _isCancellation(int code, String message) {
    final text = message.toLowerCase();
    return code == Razorpay.PAYMENT_CANCELLED ||
        text.contains('cancel') ||
        text.contains('dismissed') ||
        text.contains('closed by user');
  }

  String _friendlyFunctionsMessage(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'unauthenticated':
        return 'Your session has expired. Please log in again.';
      case 'permission-denied':
        return 'Permission denied while processing payment.';
      case 'invalid-argument':
        return 'Invalid payment request. Please try again.';
      case 'not-found':
        return 'Payment record not found.';
      case 'failed-precondition':
        return 'Payment order mismatch. Please try again.';
      case 'internal':
        return 'Payment service is temporarily unavailable. Please try again.';
      default:
        return e.message?.trim().isNotEmpty == true
            ? e.message!.trim()
            : 'Something went wrong while processing payment.';
    }
  }

  void _clearActiveState() {
    _paymentCompleter = null;
    _activeDonationId = null;
    _activeOrderId = null;
    _activeRequest = null;
  }

  void dispose() {
    _razorpay?.clear();
    _razorpay = null;
    _initialized = false;
    _clearActiveState();
  }
}