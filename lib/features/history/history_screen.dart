import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/ramakoti_meta.dart';
import '../../models/ramakoti_run.dart';
import '../../services/auth/auth_service.dart';
import '../../services/firebase/donation_service.dart';
import '../../services/firebase/ramakoti_service.dart';
import '../../screens/ramakoti/ramakoti_history_detail_screen.dart';
import '../../screens/support/support_history_screen.dart';

class RamakotiHistoryScreen extends StatelessWidget {
  const RamakotiHistoryScreen({super.key});

  static const Color _bgColor = Color(0xFFF8F2E8);
  static const Color _cardColor = Colors.white;
  static const Color _textPrimary = Color(0xFF2F2A25);
  static const Color _textSecondary = Color(0xFF7C7167);
  static const Color _accent = Color(0xFFFF9E2C);
  static const Color _softAccent = Color(0xFFFFF1DE);
  static const Color _softBorder = Color(0xFFEADFD2);

  String _buildHistoryTitle(String? displayName) {
    final name = (displayName ?? '').trim();
    if (name.isEmpty) return 'Your Ramakoti History';

    final firstName = name.split(RegExp(r'\s+')).first;
    if (firstName.toLowerCase().endsWith('s')) {
      return "$firstName' Ramakoti History";
    }
    return "$firstName's Ramakoti History";
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('No authenticated user'),
        ),
      );
    }

    final historyTitle = _buildHistoryTitle(user.displayName);

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          historyTitle,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(
        child: StreamBuilder<RamakotiMeta>(
          stream: RamakotiService.instance.watchSummary(user.uid),
          builder: (context, metaSnapshot) {
            final meta = metaSnapshot.data ?? RamakotiMeta.empty(user.uid);

            return StreamBuilder<List<RamakotiRun>>(
              stream: RamakotiService.instance.watchRuns(user.uid),
              builder: (context, runsSnapshot) {
                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: DonationService.instance.watchSupportHistory(),
                  builder: (context, donationsSnapshot) {
                    return StreamBuilder<int>(
                      stream: RamakotiService.instance.watchGlobalRamCount(),
                      builder: (context, globalSnapshot) {
                        if (runsSnapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'Could not load Ramakoti history.\n${runsSnapshot.error}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: _textPrimary,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          );
                        }

                        if (donationsSnapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'Could not load support history.\n${donationsSnapshot.error}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: _textPrimary,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          );
                        }

                        final runs = runsSnapshot.data ?? const <RamakotiRun>[];
                        final donationDocs =
                            donationsSnapshot.data?.docs ?? const [];
                        final completedRuns =
                            runs.where((e) => e.isCompleted).length;
                        final activeRuns =
                            runs.where((e) => e.isActive).length;
                        final globalTotal = globalSnapshot.data ?? 0;

                        return ListView(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                          children: [
                            _SummaryHeader(
                              meta: meta,
                              totalRuns: runs.length,
                              completedRuns: completedRuns,
                              activeRuns: activeRuns,
                              globalTotal: globalTotal,
                            ),
                            const SizedBox(height: 18),
                            _JourneyCard(
                              title: 'Ramakoti History',
                              subtitle:
                              'View all your sacred writing runs and continue active journeys.',
                              icon: Icons.auto_stories_rounded,
                              valueText:
                              '${runs.length} runs • $completedRuns completed • $activeRuns active',
                              buttonText: 'Open Ramakoti History',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                    const RamakotiHistoryDetailScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            _JourneyCard(
                              title: 'Support History',
                              subtitle:
                              'View your support entries, offering amounts, and verification status.',
                              icon: Icons.volunteer_activism_outlined,
                              valueText:
                              '${donationDocs.length} support entries',
                              buttonText: 'Open Support History',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                    const SupportHistoryScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  final RamakotiMeta meta;
  final int totalRuns;
  final int completedRuns;
  final int activeRuns;
  final int globalTotal;

  const _SummaryHeader({
    required this.meta,
    required this.totalRuns,
    required this.completedRuns,
    required this.activeRuns,
    required this.globalTotal,
  });

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
    return Container(
      decoration: BoxDecoration(
        color: RamakotiHistoryScreen._cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: RamakotiHistoryScreen._softBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Ramakoti Journey',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: RamakotiHistoryScreen._textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'A simple view of your progress, sacred runs, and the collective Ram count.',
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: RamakotiHistoryScreen._textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MiniInfoTile(
                    label: 'Total Runs',
                    value: totalRuns.toString(),
                    icon: Icons.history_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniInfoTile(
                    label: 'Completed',
                    value: completedRuns.toString(),
                    icon: Icons.emoji_events_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniInfoTile(
                    label: 'Active',
                    value: activeRuns.toString(),
                    icon: Icons.timelapse_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: RamakotiHistoryScreen._softAccent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Global Ram Count',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: RamakotiHistoryScreen._textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatIndianNumber(globalTotal),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: RamakotiHistoryScreen._textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Jai Shri Ram written across devotees',
                    style: TextStyle(
                      fontSize: 12,
                      color: RamakotiHistoryScreen._textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniInfoTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MiniInfoTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: RamakotiHistoryScreen._softAccent,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: RamakotiHistoryScreen._accent,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: RamakotiHistoryScreen._textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: RamakotiHistoryScreen._textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String valueText;
  final String buttonText;
  final IconData icon;
  final VoidCallback onTap;

  const _JourneyCard({
    required this.title,
    required this.subtitle,
    required this.valueText,
    required this.buttonText,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: RamakotiHistoryScreen._cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: RamakotiHistoryScreen._softBorder),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: RamakotiHistoryScreen._accent,
            size: 28,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: RamakotiHistoryScreen._textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: RamakotiHistoryScreen._textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            valueText,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: RamakotiHistoryScreen._textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: RamakotiHistoryScreen._accent,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}