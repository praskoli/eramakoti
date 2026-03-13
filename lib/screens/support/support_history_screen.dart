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
  static const Color _accent = Color(0xFFFF9E2C);
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
  static const Color _rejectedBg = Color(0xFFFFECE8);
  static const Color _rejectedText = Color(0xFFC94A34);
  static const Color _neutralBg = Color(0xFFEAF2FF);
  static const Color _neutralText = Color(0xFF2D5BBA);

  String _formatAmount(dynamic value) {
    if (value == null) return 'Open UPI';
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
        return (label: 'Verified', bg: _verifiedBg, text: _verifiedText);
      case 'rejected':
        return (label: 'Rejected', bg: _rejectedBg, text: _rejectedText);
      case 'returned_from_upi':
        return (
        label: 'Awaiting Review',
        bg: _pendingBg,
        text: _pendingText,
        );
      case 'initiated':
        return (label: 'Initiated', bg: _neutralBg, text: _neutralText);
      default:
        return (
        label: rawStatus.isEmpty ? 'Unknown' : rawStatus,
        bg: _neutralBg,
        text: _neutralText,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final amount = _formatAmount(data['amount']);
    final status = _statusStyle((data['status'] ?? '').toString().trim());
    final createdAt = _formatDate(data['createdAt']);
    final updatedAt = _formatDate(data['updatedAt']);
    final donationId = (data['donationId'] ?? '').toString().trim();
    final note = (data['note'] ?? '').toString().trim();
    final source = (data['source'] ?? '').toString().trim();
    final adminNote = (data['adminNote'] ?? '').toString().trim();

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
              note.isEmpty ? 'Support eRamakoti' : note,
              style: const TextStyle(
                fontSize: 14,
                color: SupportHistoryScreen._textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            _InfoRow(label: 'Offering ID', value: donationId.isEmpty ? '—' : donationId),
            const SizedBox(height: 10),
            _InfoRow(label: 'Created', value: createdAt),
            const SizedBox(height: 10),
            _InfoRow(label: 'Last Updated', value: updatedAt),
            if (source.isNotEmpty) ...[
              const SizedBox(height: 10),
              _InfoRow(label: 'Source', value: source),
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