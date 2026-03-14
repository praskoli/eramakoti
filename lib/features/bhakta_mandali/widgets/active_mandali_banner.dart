import 'package:flutter/material.dart';

class ActiveMandaliBanner extends StatelessWidget {
  const ActiveMandaliBanner({
    super.key,
    required this.mandaliName,
    this.onTap,
  });

  final String mandaliName;
  final VoidCallback? onTap;

  static const Color _accent = Color(0xFFFF9E2C);
  static const Color _textPrimary = Color(0xFF2F2A25);
  static const Color _softAccent = Color(0xFFFFF1DE);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: _softAccent,
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              const Icon(Icons.groups_rounded, color: _accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Active Mandali: $mandaliName',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: _accent),
            ],
          ),
        ),
      ),
    );
  }
}
