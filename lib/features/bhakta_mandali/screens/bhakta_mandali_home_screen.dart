import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../screens/support/support_ramakoti_screen.dart';
import '../../../services/temples/temple_context_service.dart';
import 'create_mandali_screen.dart';
import 'discover_mandalis_screen.dart';
import 'global_mandali_leaderboard_screen.dart';
import 'join_mandali_screen.dart';
import 'my_mandalis_screen.dart';
import 'support_mandali_screen.dart';

class BhaktaMandaliHomeScreen extends StatelessWidget {
  const BhaktaMandaliHomeScreen({super.key});

  static const Color _bg = Color(0xFFF8F2E8);
  static const Color _card = Colors.white;
  static const Color _border = Color(0xFFEADFD2);
  static const Color _accent = Color(0xFFFF9E2C);
  static const Color _textPrimary = Color(0xFF2F2A25);
  static const Color _textSecondary = Color(0xFF7C7167);
  static const Color _softBlue = Color(0xFFEAF2FF);
  static const Color _blueText = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    final templeContext = context.watch<TempleContextService>();
    final temple = templeContext.currentTemple;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          temple != null ? 'Temple Bhakta Mandali' : 'Bhakta Mandali',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          if (temple != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _softBlue,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFD9E7FF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.account_balance_rounded, color: _blueText),
                      SizedBox(width: 8),
                      Text(
                        'Temple Context Active',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: _blueText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    temple.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Temple-specific Mandali features can now follow this temple context without changing the rest of the app flow.',
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: _textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          _ActionCard(
            title: 'My Mandalis',
            subtitle:
            'Open your joined Mandalis, active challenges, certificates and support actions.',
            icon: Icons.groups_rounded,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MyMandalisScreen()),
            ),
          ),
          const SizedBox(height: 14),
          _ActionCard(
            title: temple != null ? 'Discover Temple Mandalis' : 'Discover Mandalis',
            subtitle: temple != null
                ? 'Browse devotional communities connected to the active temple experience.'
                : 'Browse public devotional communities and join one that inspires you.',
            icon: Icons.explore_rounded,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DiscoverMandalisScreen()),
            ),
          ),
          const SizedBox(height: 14),
          _ActionCard(
            title: 'Join with Code',
            subtitle:
            'Enter a Mandali invite code shared by a devotee or organizer.',
            icon: Icons.vpn_key_rounded,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const JoinMandaliScreen()),
            ),
          ),
          const SizedBox(height: 14),
          _ActionCard(
            title: 'Create Mandali',
            subtitle: temple != null
                ? 'Create a new Bhakta Mandali for this temple context and start a devotional challenge.'
                : 'Create a new Bhakta Mandali and start a devotional challenge.',
            icon: Icons.add_circle_outline_rounded,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CreateMandaliScreen()),
            ),
          ),
          const SizedBox(height: 14),
          _ActionCard(
            title: 'Support Mandali',
            subtitle:
            'Choose a Bhakta Mandali and offer support to its devotional journey.',
            icon: Icons.volunteer_activism_rounded,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SupportMandaliScreen()),
            ),
          ),
          const SizedBox(height: 14),
          _ActionCard(
            title: 'Global Mandali Leaderboard',
            subtitle:
            'See the most active Mandalis and their overall Sri Rama Nama count.',
            icon: Icons.emoji_events_outlined,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const GlobalMandaliLeaderboardScreen(),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _ActionCard(
            title: temple != null ? 'Offer Support to Temple' : 'General Offer Support',
            subtitle: temple != null
                ? 'Offer support using the active temple UPI configuration.'
                : 'Offer support to the devotional app itself, outside any one specific Mandali.',
            icon: Icons.favorite_outline_rounded,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SupportRamakotiScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BhaktaMandaliHomeScreen._card,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: BhaktaMandaliHomeScreen._border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF1DE),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: BhaktaMandaliHomeScreen._accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: BhaktaMandaliHomeScreen._textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: BhaktaMandaliHomeScreen._textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.chevron_right_rounded,
                color: BhaktaMandaliHomeScreen._accent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
