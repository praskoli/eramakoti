import 'package:flutter/material.dart';

import '../../../models/bhakta_mandali.dart';

class MandaliCard extends StatelessWidget {
  const MandaliCard({
    super.key,
    required this.mandali,
    this.onTap,
    this.trailing,
  });

  final BhaktaMandali mandali;
  final VoidCallback? onTap;
  final Widget? trailing;

  static const Color _cardColor = Colors.white;
  static const Color _textPrimary = Color(0xFF2F2A25);
  static const Color _textSecondary = Color(0xFF7C7167);
  static const Color _accent = Color(0xFFFF9E2C);
  static const Color _softBorder = Color(0xFFEADFD2);
  static const Color _softAccent = Color(0xFFFFF1DE);

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

  @override
  Widget build(BuildContext context) {
    final challenge = mandali.activeChallenge;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _softBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10000000),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        color: _softAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.groups_rounded, color: _accent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        mandali.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _textPrimary,
                        ),
                      ),
                    ),
                    if (trailing != null) trailing!,
                  ],
                ),
                const SizedBox(height: 12),
                if (mandali.description.trim().isNotEmpty)
                  Text(
                    mandali.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.45,
                      color: _textSecondary,
                    ),
                  ),
                if (mandali.description.trim().isNotEmpty) const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _pill(Icons.category_outlined, mandali.category),
                    _pill(Icons.people_alt_outlined, '${mandali.memberCount} members'),
                    _pill(Icons.auto_awesome_outlined, _formatIndianNumber(mandali.totalCount)),
                    _pill(Icons.key_outlined, mandali.inviteCode),
                  ],
                ),
                if (challenge != null) ...[
                  const SizedBox(height: 14),
                  LinearProgressIndicator(
                    value: challenge.progressPercent,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(999),
                    backgroundColor: const Color(0xFFF2E8DC),
                    valueColor: const AlwaysStoppedAnimation<Color>(_accent),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${challenge.title} • ${_formatIndianNumber(challenge.progressCount)} / ${_formatIndianNumber(challenge.target)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: _softAccent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: _accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
