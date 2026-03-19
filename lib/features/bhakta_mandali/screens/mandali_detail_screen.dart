import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../models/bhakta_mandali.dart';
import '../../../models/bhakta_mandali_member.dart';
import '../../../screens/support/support_ramakoti_screen.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/firebase/bhakta_mandali_service.dart';
import '../widgets/challenge_progress_card.dart';
import '../widgets/mandali_member_tile.dart';
import 'mandali_certificates_screen.dart';
import 'mandali_leaderboard_screen.dart';
import 'mandali_writer_screen.dart';

class MandaliDetailScreen extends StatelessWidget {
  const MandaliDetailScreen({
    super.key,
    required this.mandaliId,
  });

  final String mandaliId;

  static const Color _bgColor = Color(0xFFF8F2E8);
  static const Color _accent = Color(0xFFFF9E2C);
  static const Color _textPrimary = Color(0xFF2F2A25);
  static const Color _textSecondary = Color(0xFF7C7167);
  static const Color _completedBg = Color(0xFFEAF8EE);
  static const Color _completedText = Color(0xFF2F8F4E);

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
    if (remaining.isNotEmpty) parts.insert(0, remaining);
    return '${parts.join(',')},$last3';
  }

  bool _isCompleted(BhaktaMandali mandali) =>
      (mandali.activeChallenge?.status ?? '').trim().toLowerCase() == 'completed';

  @override
  Widget build(BuildContext context) {
    final normalizedMandaliId = mandaliId.trim();
    if (normalizedMandaliId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Invalid Mandali reference')),
      );
    }

    final user = AuthService.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('No authenticated user')));
    }

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Mandali Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
      ),
      body: StreamBuilder<BhaktaMandali?>(
        stream: BhaktaMandaliService.instance.watchMandali(normalizedMandaliId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Failed to load Mandali.\n${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final mandali = snapshot.data;
          if (mandali == null) {
            return const Center(child: Text('Mandali not found.'));
          }

          final isCompleted = _isCompleted(mandali);

          return StreamBuilder<List<BhaktaMandaliMember>>(
            stream: BhaktaMandaliService.instance.watchLeaderboard(normalizedMandaliId),
            builder: (context, membersSnapshot) {
              final members = membersSnapshot.data ?? const <BhaktaMandaliMember>[];

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  Text(
                    mandali.displayName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    mandali.description.isEmpty
                        ? 'A devotional Bhakta Mandali for Sri Rama Nama writing.'
                        : mandali.description,
                    style: const TextStyle(
                      fontSize: 14.5,
                      height: 1.55,
                      color: _textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _statCard('Members', mandali.memberCount.toString(), Icons.people_outline_rounded),
                      _statCard('Mandali Count', _formatIndianNumber(mandali.totalCount), Icons.auto_awesome_outlined),
                      _statCard('Invite Code', mandali.inviteCode, Icons.key_rounded),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (mandali.activeChallenge != null)
                    ChallengeProgressCard(challenge: mandali.activeChallenge!),
                  if (isCompleted) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _completedBg,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Text(
                        'This challenge is completed. Writing is closed for this Mandali until a new challenge is created.',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _completedText,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: Icon(isCompleted ? Icons.check_circle_outline : Icons.edit_note_rounded),
                          label: Text(isCompleted ? 'Challenge Completed' : 'Write for this Mandali'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isCompleted ? Colors.grey.shade300 : _accent,
                            foregroundColor: isCompleted ? Colors.black54 : Colors.white,
                          ),
                          onPressed: isCompleted
                              ? null
                              : () async {
                            await BhaktaMandaliService.instance.setActiveMandali(
                              uid: user.uid,
                              mandaliId: normalizedMandaliId,
                              mandaliName: mandali.displayName,
                              challengeId: mandali.activeChallengeId,
                            );
                            if (!context.mounted) return;
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => MandaliWriterScreen(mandaliId: normalizedMandaliId),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.workspace_premium_outlined),
                          label: const Text('Certificates'),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => MandaliCertificatesScreen(
                                  mandaliId: normalizedMandaliId,
                                  mandaliName: mandali.displayName,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.favorite_outline_rounded),
                          label: const Text('Offer Support'),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => SupportRamakotiScreen(
                                  source: 'mandali_detail_offer_support',
                                  sourceMandaliId: normalizedMandaliId,
                                  sourceMandaliName: mandali.displayName,
                                  sourceChallengeId: mandali.activeChallengeId,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.ios_share_rounded),
                    label: const Text('Invite'),
                    onPressed: () async {
                      final text = BhaktaMandaliService.instance.buildInviteMessage(mandali);
                      await Share.share(text);
                    },
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Leaderboard Preview',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: _textPrimary,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => MandaliLeaderboardScreen(
                                mandaliId: normalizedMandaliId,
                                title: mandali.displayName,
                              ),
                            ),
                          );
                        },
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Debug members length: ${members.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (members.isEmpty)
                    const Text('No members yet.')
                  else
                    ...members.take(5).toList().asMap().entries.map(
                          (entry) => Padding(
                        key: ValueKey(entry.value.uid),
                        padding: const EdgeInsets.only(bottom: 10),
                        child: MandaliMemberTile(
                          rank: entry.key + 1,
                          member: entry.value,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Copy Invite Code'),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: mandali.inviteCode));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invite code copied.')),
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Container(
      width: 160,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _accent),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(fontSize: 12.5, color: _textSecondary)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: _textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
