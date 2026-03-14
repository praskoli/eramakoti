import 'package:flutter/material.dart';

import '../../../models/bhakta_mandali_challenge.dart';

class ChallengeProgressCard extends StatelessWidget {
  const ChallengeProgressCard({
    super.key,
    required this.challenge,
  });

  final BhaktaMandaliChallenge challenge;

  static const Color _cardColor = Colors.white;
  static const Color _textPrimary = Color(0xFF2F2A25);
  static const Color _textSecondary = Color(0xFF7C7167);
  static const Color _accent = Color(0xFFFF9E2C);
  static const Color _softBorder = Color(0xFFEADFD2);

  String _formatIndianNumber(int value) {
    final number = value.toString();
    if (number.length <= 3) return number;
    final last3 = number.substring(number.length - 3);
    var remaining = number.substring(0, number.length - 3);
    final parts = <String>[];
    while (remaining.length > 2) {
      parts.insert(0, remaining.substring(remaining.length - 2));
      remaining = remaining.substring(0, remaining.length - 2);
    }
    if (remaining.isNotEmpty) {
      parts.insert(0, remaining);
    }
    return '${parts.join(',')},$last3';
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '-';
    final d = value.day.toString().padLeft(2, '0');
    final m = value.month.toString().padLeft(2, '0');
    final y = value.year.toString();
    return '$d/$m/$y';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _softBorder),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Active Challenge',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            challenge.title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          LinearProgressIndicator(
            value: challenge.progressPercent,
            minHeight: 10,
            borderRadius: BorderRadius.circular(999),
            backgroundColor: const Color(0xFFF2E8DC),
            valueColor: const AlwaysStoppedAnimation<Color>(_accent),
          ),
          const SizedBox(height: 10),
          Text(
            '${_formatIndianNumber(challenge.progressCount)} / ${_formatIndianNumber(challenge.target)}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_formatIndianNumber(challenge.remainingCount)} remaining',
            style: const TextStyle(
              fontSize: 13.5,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _stat('Start', _formatDate(challenge.startDate)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _stat('End', _formatDate(challenge.endDate)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F0),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: _textSecondary)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
