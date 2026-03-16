import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/temples/temple_context_service.dart';

class TempleContextBanner extends StatelessWidget {
  const TempleContextBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final templeContext = context.watch<TempleContextService>();
    final temple = templeContext.currentTemple;

    if (temple == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6C89C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Temple Mode Active',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF8A4B08),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            temple.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A2C12),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${temple.city} • ${temple.address}',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B4E35),
            ),
          ),
        ],
      ),
    );
  }
}