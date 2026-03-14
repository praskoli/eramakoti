import 'package:flutter/material.dart';

import '../../../models/bhakta_mandali.dart';
import '../../../models/user_mandali_membership.dart';
import '../../../screens/support/support_ramakoti_screen.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/firebase/bhakta_mandali_service.dart';

class SupportMandaliScreen extends StatelessWidget {
  const SupportMandaliScreen({super.key});

  static const Color _bg = Color(0xFFF8F2E8);
  static const Color _card = Colors.white;
  static const Color _border = Color(0xFFEADFD2);
  static const Color _accent = Color(0xFFFF9E2C);
  static const Color _textPrimary = Color(0xFF2F2A25);
  static const Color _textSecondary = Color(0xFF7C7167);
  static const Color _completedBg = Color(0xFFEAF8EE);
  static const Color _completedText = Color(0xFF2F8F4E);
  static const Color _activeBg = Color(0xFFEAF2FF);
  static const Color _activeText = Color(0xFF2563EB);

  bool _isCompleted(BhaktaMandali mandali) =>
      (mandali.activeChallenge?.status ?? '').trim().toLowerCase() == 'completed';

  bool _isActive(BhaktaMandali mandali) =>
      (mandali.activeChallenge?.status ?? '').trim().toLowerCase() == 'active';

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('No authenticated user')));
    }

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Support Mandali',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800),
        ),
      ),
      body: StreamBuilder<List<UserMandaliMembership>>(
        stream: BhaktaMandaliService.instance.watchMyMandalis(user.uid),
        builder: (context, membershipSnapshot) {
          if (membershipSnapshot.hasError) {
            return Center(child: Text('Failed to load Mandalis.\n${membershipSnapshot.error}'));
          }
          if (membershipSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final memberships = membershipSnapshot.data ?? const <UserMandaliMembership>[];
          if (memberships.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Join a Mandali first to offer support directly to its devotional journey.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return FutureBuilder<List<BhaktaMandali>>(
            future: _loadMandalis(memberships),
            builder: (context, mandalisSnapshot) {
              if (mandalisSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final mandalis = mandalisSnapshot.data ?? const <BhaktaMandali>[];

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                itemCount: mandalis.length,
                itemBuilder: (context, index) {
                  final mandali = mandalis[index];
                  final isCompleted = _isCompleted(mandali);
                  final isActive = _isActive(mandali);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFF1DE),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.volunteer_activism_rounded,
                                color: _accent,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                mandali.displayName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: _textPrimary,
                                ),
                              ),
                            ),
                            if (isCompleted)
                              const _Badge(label: 'Completed', bg: _completedBg, fg: _completedText)
                            else if (isActive)
                              const _Badge(label: 'Active Challenge', bg: _activeBg, fg: _activeText),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          mandali.description.isEmpty
                              ? 'Offer support to this Bhakta Mandali.'
                              : mandali.description,
                          style: const TextStyle(
                            color: _textSecondary,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if ((mandali.activeChallenge?.title ?? '').trim().isNotEmpty)
                          Text(
                            'Challenge: ${mandali.activeChallenge!.title}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _textPrimary,
                            ),
                          ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => SupportRamakotiScreen(
                                    source: 'support_mandali_screen',
                                    sourceMandaliId: mandali.mandaliId,
                                    sourceMandaliName: mandali.displayName,
                                    sourceChallengeId: mandali.activeChallengeId,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.favorite_outline_rounded),
                            label: Text(isCompleted ? 'Support Completed Mandali' : 'Offer Support'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accent,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<List<BhaktaMandali>> _loadMandalis(List<UserMandaliMembership> memberships) async {
    final out = <BhaktaMandali>[];
    for (final membership in memberships) {
      final mandali = await BhaktaMandaliService.instance.watchMandali(membership.mandaliId).first;
      if (mandali != null) out.add(mandali);
    }
    out.sort((a, b) {
      final aCompleted = _isCompleted(a);
      final bCompleted = _isCompleted(b);
      if (aCompleted != bCompleted) return aCompleted ? 1 : -1;
      return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
    });
    return out;
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.bg,
    required this.fg,
  });

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
