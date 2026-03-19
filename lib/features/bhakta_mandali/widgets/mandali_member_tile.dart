import 'package:flutter/material.dart';

import '../../../models/bhakta_mandali_member.dart';

class MandaliMemberTile extends StatelessWidget {
  const MandaliMemberTile({
    super.key,
    required this.member,
    required this.rank,
  });

  final BhaktaMandaliMember member;
  final int rank;

  static const Color _textPrimary = Color(0xFF2F2A25);
  static const Color _textSecondary = Color(0xFF7C7167);
  static const Color _accent = Color(0xFFFF9E2C);
  static const Color _softBorder = Color(0xFFEADFD2);

  @override
  Widget build(BuildContext context) {
    final displayName =
    member.displayName.trim().isEmpty ? 'Devotee' : member.displayName;

    final initials = _initials(displayName);

    return Container(
      key: ValueKey(member.uid), // ✅ FIX: ensures Flutter does not skip/reuse wrongly
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _softBorder),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          Container(
            width: 34,
            alignment: Alignment.center,
            child: Text(
              '#$rank',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: _accent,
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 21,
            backgroundColor: const Color(0xFFFFF1DE),
            child: Text(
              initials,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: _textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              displayName,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                (member.contributionCount).toString(), // ✅ always show (even 0)
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _textPrimary,
                ),
              ),
              Text(
                member.isCreator ? 'Creator' : 'Member',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: _textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts =
    name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'D';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}