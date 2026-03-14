import 'package:flutter/material.dart';

import '../../../models/bhakta_mandali.dart';

class MandaliLeaderboardTile extends StatelessWidget {
  const MandaliLeaderboardTile({
    super.key,
    required this.rank,
    required this.mandali,
    this.onTap,
  });

  final int rank;
  final BhaktaMandali mandali;
  final VoidCallback? onTap;

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

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _softBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                alignment: Alignment.center,
                child: Text(
                  '#$rank',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _accent,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const CircleAvatar(
                radius: 22,
                backgroundColor: Color(0xFFFFF1DE),
                child: Icon(Icons.groups_rounded, color: _accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mandali.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${mandali.memberCount} members',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatIndianNumber(mandali.totalCount),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
