import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../models/ramakoti_meta.dart';
import '../../../models/user_mandali_membership.dart';
import '../../../screens/support/support_ramakoti_screen.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/firebase/bhakta_mandali_service.dart';
import '../../../services/firebase/ramakoti_service.dart';
import 'mandali_certificates_screen.dart';
import 'mandali_detail_screen.dart';
import 'mandali_writer_screen.dart';

class MyMandalisScreen extends StatelessWidget {
  const MyMandalisScreen({super.key});

  static const Color _bg = Color(0xFFF8F2E8);
  static const Color _card = Colors.white;
  static const Color _border = Color(0xFFEADFD2);
  static const Color _accent = Color(0xFFFF9E2C);
  static const Color _textPrimary = Color(0xFF2F2A25);
  static const Color _textSecondary = Color(0xFF7C7167);
  static const Color _selectedBg = Color(0xFFFFF1DE);
  static const Color _activeBg = Color(0xFFEAF2FF);
  static const Color _activeText = Color(0xFF2563EB);
  static const Color _completedBg = Color(0xFFEAF8EE);
  static const Color _completedText = Color(0xFF2F8F4E);

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No authenticated user')),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'My Mandalis',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: StreamBuilder<List<UserMandaliMembership>>(
        stream: BhaktaMandaliService.instance.watchMyMandalis(user.uid),
        builder: (context, membershipsSnapshot) {
          if (membershipsSnapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load Mandalis.\n${membershipsSnapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (membershipsSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final memberships =
              membershipsSnapshot.data ?? const <UserMandaliMembership>[];

          if (memberships.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'You have not joined any Bhakta Mandali yet.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return StreamBuilder<RamakotiMeta>(
            stream: RamakotiService.instance.watchSummary(user.uid),
            initialData: RamakotiMeta.empty(user.uid),
            builder: (context, summarySnapshot) {
              final summary =
                  summarySnapshot.data ?? RamakotiMeta.empty(user.uid);

              return FutureBuilder<List<_MandaliCardData>>(
                future: _loadMandaliCards(
                  memberships: memberships,
                  selectedMandaliId: summary.activeMandaliId,
                ),
                builder: (context, cardsSnapshot) {
                  if (cardsSnapshot.hasError) {
                    return Center(
                      child: Text(
                        'Failed to load Mandali cards.\n${cardsSnapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  if (cardsSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final cards =
                      cardsSnapshot.data ?? const <_MandaliCardData>[];

                  if (cards.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'No Mandali data available.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: cards.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final item = cards[index];
                      return _MandaliCard(
                        item: item,
                        onOpen: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => MandaliDetailScreen(
                                mandaliId: item.mandaliId,
                              ),
                            ),
                          );
                        },
                        onWrite: item.canWrite
                            ? () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => MandaliWriterScreen(
                                mandaliId: item.mandaliId,
                              ),
                            ),
                          );
                        }
                            : null,
                        onCertificates: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => MandaliCertificatesScreen(
                                mandaliId: item.mandaliId,
                                mandaliName: item.displayName,
                              ),
                            ),
                          );
                        },
                        onOfferSupport: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SupportRamakotiScreen(
                                source: 'support_mandali_card',
                                sourceMandaliId: item.mandaliId,
                                sourceMandaliName: item.displayName,
                                sourceChallengeId: item.activeChallengeId,
                              ),
                            ),
                          );
                        },
                        onSetActive: item.canSelect
                            ? () async {
                          await BhaktaMandaliService.instance
                              .setActiveMandali(
                            uid: user.uid,
                            mandaliId: item.mandaliId,
                            mandaliName: item.displayName,
                            challengeId: item.activeChallengeId,
                          );
                        }
                            : null,
                        onClearActive: item.isSelected
                            ? () async {
                          await BhaktaMandaliService.instance
                              .clearActiveMandali(
                            uid: user.uid,
                          );
                        }
                            : null,
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<List<_MandaliCardData>> _loadMandaliCards({
    required List<UserMandaliMembership> memberships,
    required String selectedMandaliId,
  }) async {
    final firestore = FirebaseFirestore.instance;

    final futures = memberships.map((membership) async {
      final mandaliId = membership.mandaliId.trim();
      if (mandaliId.isEmpty) return null;

      final doc =
      await firestore.collection('bhaktaMandalis').doc(mandaliId).get();

      if (!doc.exists) return null;

      final data = doc.data() ?? <String, dynamic>{};
      final activeChallenge = _asMap(data['activeChallenge']);
      final challengeStatus =
      (activeChallenge['status'] ?? '').toString().trim().toLowerCase();

      final normalizedStatus =
      challengeStatus.isEmpty ? 'active' : challengeStatus;
      final isCompleted = normalizedStatus == 'completed';
      final isActiveChallenge = normalizedStatus == 'active';
      final isSelected = !isCompleted && selectedMandaliId == mandaliId;

      return _MandaliCardData(
        mandaliId: mandaliId,
        displayName:
        (data['displayName'] ?? data['name'] ?? 'Bhakta Mandali')
            .toString(),
        description: (data['description'] ?? '').toString(),
        memberCount: _asInt(data['memberCount']),
        totalCount: _asInt(data['totalCount']),
        activeChallengeId: (data['activeChallengeId'] ?? '').toString(),
        challengeTitle:
        (activeChallenge['title'] ?? activeChallenge['challengeName'] ?? '')
            .toString(),
        challengeStatus: normalizedStatus,
        isSelected: isSelected,
        isCompleted: isCompleted,
        isActiveChallenge: isActiveChallenge,
      );
    }).toList();

    final items =
    (await Future.wait(futures)).whereType<_MandaliCardData>().toList();

    items.sort((a, b) {
      int rank(_MandaliCardData x) {
        if (x.isSelected && x.isActiveChallenge) return 0;
        if (x.isActiveChallenge) return 1;
        if (x.isCompleted) return 2;
        return 3;
      }

      final rankCompare = rank(a).compareTo(rank(b));
      if (rankCompare != 0) return rankCompare;

      return a.displayName.toLowerCase().compareTo(
        b.displayName.toLowerCase(),
      );
    });

    return items;
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return <String, dynamic>{};
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class _MandaliCardData {
  const _MandaliCardData({
    required this.mandaliId,
    required this.displayName,
    required this.description,
    required this.memberCount,
    required this.totalCount,
    required this.activeChallengeId,
    required this.challengeTitle,
    required this.challengeStatus,
    required this.isSelected,
    required this.isCompleted,
    required this.isActiveChallenge,
  });

  final String mandaliId;
  final String displayName;
  final String description;
  final int memberCount;
  final int totalCount;
  final String activeChallengeId;
  final String challengeTitle;
  final String challengeStatus;
  final bool isSelected;
  final bool isCompleted;
  final bool isActiveChallenge;

  bool get canWrite => isActiveChallenge;
  bool get canSelect => isActiveChallenge && !isSelected;
}

class _MandaliCard extends StatelessWidget {
  const _MandaliCard({
    required this.item,
    required this.onOpen,
    required this.onCertificates,
    required this.onOfferSupport,
    this.onWrite,
    this.onSetActive,
    this.onClearActive,
  });

  final _MandaliCardData item;
  final VoidCallback onOpen;
  final VoidCallback onCertificates;
  final VoidCallback onOfferSupport;
  final VoidCallback? onWrite;
  final VoidCallback? onSetActive;
  final VoidCallback? onClearActive;

  static const Color _card = MyMandalisScreen._card;
  static const Color _border = MyMandalisScreen._border;
  static const Color _accent = MyMandalisScreen._accent;
  static const Color _textPrimary = MyMandalisScreen._textPrimary;
  static const Color _textSecondary = MyMandalisScreen._textSecondary;
  static const Color _selectedBg = MyMandalisScreen._selectedBg;
  static const Color _activeBg = MyMandalisScreen._activeBg;
  static const Color _activeText = MyMandalisScreen._activeText;
  static const Color _completedBg = MyMandalisScreen._completedBg;
  static const Color _completedText = MyMandalisScreen._completedText;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.displayName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _textPrimary,
            ),
          ),
          if (item.description.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              item.description,
              style: const TextStyle(
                color: _textSecondary,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (item.isSelected)
                const _StatusBadge(
                  label: 'Selected',
                  backgroundColor: _selectedBg,
                  textColor: _accent,
                ),
              if (item.isCompleted)
                const _StatusBadge(
                  label: 'Completed',
                  backgroundColor: _completedBg,
                  textColor: _completedText,
                )
              else if (item.isActiveChallenge)
                const _StatusBadge(
                  label: 'Active Challenge',
                  backgroundColor: _activeBg,
                  textColor: _activeText,
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniInfo(
                  label: 'Members',
                  value: item.memberCount.toString(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniInfo(
                  label: 'Mandali Count',
                  value: _formatIndianNumber(item.totalCount),
                ),
              ),
            ],
          ),
          if (item.challengeTitle.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8F0),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Challenge',
                    style: TextStyle(
                      color: _textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.challengeTitle,
                    style: const TextStyle(
                      color: _textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (item.isSelected)
                OutlinedButton(
                  onPressed: onClearActive,
                  child: const Text('Clear Active'),
                )
              else if (item.canSelect)
                OutlinedButton(
                  onPressed: onSetActive,
                  child: const Text('Set Active'),
                ),
              OutlinedButton(
                onPressed: onOpen,
                child: const Text('Open'),
              ),
              ElevatedButton(
                onPressed: item.canWrite ? onWrite : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                ),
                child: Text(item.canWrite ? 'Write' : 'Completed'),
              ),
              OutlinedButton(
                onPressed: onCertificates,
                child: const Text('Certificates'),
              ),
              OutlinedButton(
                onPressed: onOfferSupport,
                child: const Text('Offer Support'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatIndianNumber(int value) {
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
}

class _MiniInfo extends StatelessWidget {
  const _MiniInfo({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  static const Color _textPrimary = MyMandalisScreen._textPrimary;
  static const Color _textSecondary = MyMandalisScreen._textSecondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F0),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: _textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}