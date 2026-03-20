import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/firebase/donation_service.dart';

class SupportHistoryScreen extends StatelessWidget {
  const SupportHistoryScreen({super.key});

  static const Color _bgColor = Color(0xFFF8F2E8);
  static const Color _cardColor = Colors.white;
  static const Color _textPrimary = Color(0xFF2F2A25);
  static const Color _textSecondary = Color(0xFF7C7167);
  static const Color _softBorder = Color(0xFFEADFD2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text('Support History'),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: DonationService.instance.watchSupportHistory(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load support history.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? const [];

          if (docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No support history yet.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              return _DonationHistoryCard(data: docs[index].data());
            },
          );
        },
      ),
    );
  }
}

class _DonationHistoryCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _DonationHistoryCard({
    required this.data,
  });

  static const Color _pendingBg = Color(0xFFFFF1DE);
  static const Color _pendingText = Color(0xFFE8881A);
  static const Color _verifiedBg = Color(0xFFEAF8EE);
  static const Color _verifiedText = Color(0xFF2F8F4E);
  static const Color _failedBg = Color(0xFFFFECE8);
  static const Color _failedText = Color(0xFFC94A34);
  static const Color _neutralBg = Color(0xFFEAF2FF);
  static const Color _neutralText = Color(0xFF2D5BBA);
  static const Color _cancelledBg = Color(0xFFF3F4F6);
  static const Color _cancelledText = Color(0xFF6B7280);
  static const Color _refundedBg = Color(0xFFF5EEFF);
  static const Color _refundedText = Color(0xFF7C3AED);

  String _formatAmount(dynamic value) {
    if (value == null) return '₹0';
    if (value is int) return '₹$value';
    if (value is double) return '₹${value.toInt()}';
    return '₹$value';
  }

  DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String _formatDate(dynamic value) {
    final date = _parseTimestamp(value);
    if (date == null) return '—';
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  ({String label, Color bg, Color text}) _statusStyle(String rawStatus) {
    switch (rawStatus) {
      case 'verified':
        return (label: 'Paid', bg: _verifiedBg, text: _verifiedText);
      case 'created':
        return (label: 'Created', bg: _pendingBg, text: _pendingText);
      case 'initiated':
        return (label: 'Initiated', bg: _neutralBg, text: _neutralText);
      case 'pending':
        return (label: 'Pending', bg: _pendingBg, text: _pendingText);
      case 'verification_failed':
        return (
        label: 'Verification Failed',
        bg: _failedBg,
        text: _failedText,
        );
      case 'failed':
        return (label: 'Failed', bg: _failedBg, text: _failedText);
      case 'cancelled':
        return (label: 'Cancelled', bg: _cancelledBg, text: _cancelledText);
      case 'returned':
        return (label: 'Returned', bg: _cancelledBg, text: _cancelledText);
      case 'refunded':
        return (label: 'Refunded', bg: _refundedBg, text: _refundedText);
      default:
        return (
        label: rawStatus.isEmpty ? 'Unknown' : _humanize(rawStatus),
        bg: _neutralBg,
        text: _neutralText,
        );
    }
  }

  String _humanize(String value) {
    return value
        .split('_')
        .where((e) => e.trim().isNotEmpty)
        .map(
          (word) =>
      word.substring(0, 1).toUpperCase() + word.substring(1).toLowerCase(),
    )
        .join(' ');
  }

  String _buildTitle({
    required String note,
    required String supportType,
    required String sourceMandaliName,
  }) {
    if (note.isNotEmpty) return note;
    if (supportType == 'mandali') {
      if (sourceMandaliName.isNotEmpty) {
        return 'Mandali support • $sourceMandaliName';
      }
      return 'Mandali support';
    }
    return 'Support eRamakoti';
  }

  @override
  Widget build(BuildContext context) {
    final amount = _formatAmount(data['amount']);
    final rawStatus = (data['status'] ?? '').toString().trim();
    final status = _statusStyle(rawStatus);
    final createdAt = _formatDate(data['createdAt']);
    final updatedAt = _formatDate(data['updatedAt']);
    final verifiedAt = _formatDate(data['verifiedAt']);
    final paidAt = _formatDate(data['paidAt']);

    final donationId = (data['donationId'] ?? '').toString().trim();
    final note = (data['note'] ?? '').toString().trim();
    final source = (data['source'] ?? '').toString().trim();
    final adminNote = (data['adminNote'] ?? '').toString().trim();
    final supportType = (data['supportType'] ?? '').toString().trim();
    final sourceMandaliName =
    (data['sourceMandaliName'] ?? '').toString().trim();

    final paymentProvider = (data['paymentProvider'] ?? '').toString().trim();
    final paymentMode = (data['paymentMode'] ?? '').toString().trim();
    final razorpayOrderId = (data['razorpayOrderId'] ?? '').toString().trim();
    final razorpayPaymentId =
    (data['razorpayPaymentId'] ?? '').toString().trim();
    final failureReason = (data['failureReason'] ?? '').toString().trim();

    final title = _buildTitle(
      note: note,
      supportType: supportType,
      sourceMandaliName: sourceMandaliName,
    );

    return Container(
      decoration: BoxDecoration(
        color: SupportHistoryScreen._cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: SupportHistoryScreen._softBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: status.bg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    status.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: status.text,
                    ),
                  ),
                ),
                if (supportType == 'mandali')
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF2FF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Mandali',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2D5BBA),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              amount,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: SupportHistoryScreen._textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: SupportHistoryScreen._textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            _InfoRow(
              label: 'Offering ID',
              value: donationId.isEmpty ? '—' : donationId,
            ),
            const SizedBox(height: 10),
            _InfoRow(label: 'Created', value: createdAt),
            const SizedBox(height: 10),
            _InfoRow(label: 'Last Updated', value: updatedAt),
            if (paidAt != '—') ...[
              const SizedBox(height: 10),
              _InfoRow(label: 'Paid At', value: paidAt),
            ],
            if (verifiedAt != '—') ...[
              const SizedBox(height: 10),
              _InfoRow(label: 'Verified At', value: verifiedAt),
            ],
            if (paymentProvider.isNotEmpty) ...[
              const SizedBox(height: 10),
              _InfoRow(
                label: 'Provider',
                value: _humanize(paymentProvider),
              ),
            ],
            if (paymentMode.isNotEmpty) ...[
              const SizedBox(height: 10),
              _InfoRow(
                label: 'Mode',
                value: _humanize(paymentMode),
              ),
            ],
            if (razorpayOrderId.isNotEmpty) ...[
              const SizedBox(height: 10),
              _InfoRow(label: 'Order ID', value: razorpayOrderId),
            ],
            if (razorpayPaymentId.isNotEmpty) ...[
              const SizedBox(height: 10),
              _InfoRow(label: 'Payment ID', value: razorpayPaymentId),
            ],
            if (source.isNotEmpty) ...[
              const SizedBox(height: 10),
              _InfoRow(label: 'Source', value: source),
            ],
            if (sourceMandaliName.isNotEmpty) ...[
              const SizedBox(height: 10),
              _InfoRow(label: 'Mandali', value: sourceMandaliName),
            ],
            if (failureReason.isNotEmpty) ...[
              const SizedBox(height: 10),
              _InfoRow(
                label: 'Failure Reason',
                value: _humanize(failureReason),
              ),
            ],
            if (adminNote.isNotEmpty) ...[
              const SizedBox(height: 10),
              _InfoRow(label: 'Admin Note', value: adminNote),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: SupportHistoryScreen._textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: SupportHistoryScreen._textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}