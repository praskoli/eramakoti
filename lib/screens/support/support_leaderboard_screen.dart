import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/firebase/donation_service.dart';

class SupportLeaderboardScreen extends StatefulWidget {
  const SupportLeaderboardScreen({super.key});

  @override
  State<SupportLeaderboardScreen> createState() =>
      _SupportLeaderboardScreenState();
}

class _SupportLeaderboardScreenState extends State<SupportLeaderboardScreen> {
  static const Color _accent = Color(0xFFFF9E2C);
  static const Color _bg = Color(0xFFF8F2E8);
  static const Color _card = Colors.white;
  static const Color _border = Color(0xFFEADFD2);
  static const Color _textPrimary = Color(0xFF2F2A25);
  static const Color _textSecondary = Color(0xFF7C7167);
  static const Color _softAccent = Color(0xFFFFF1DE);

  late Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _future;

  @override
  void initState() {
    super.initState();
    _future = DonationService.instance.fetchSupportLeaderboard(limit: 25);
  }

  String _formatDate(dynamic value) {
    DateTime? date;
    if (value is Timestamp) date = value.toDate();
    if (value is String) date = DateTime.tryParse(value);
    if (date == null) return '—';
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  String _resolveName(Map<String, dynamic> data) {
    final raw = (data['name'] ?? '').toString().trim();
    if (raw.isNotEmpty) return raw;

    final anonymous = data['anonymous'] == true;
    if (anonymous) return 'Anonymous Devotee';

    return 'Devotee';
  }

  Widget _sectionCard({required Widget child}) {
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
      child: child,
    );
  }

  Widget _rankBadge(int rank) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: _accent.withOpacity(.12),
        shape: BoxShape.circle,
        border: Border.all(color: _accent.withOpacity(.24)),
      ),
      alignment: Alignment.center,
      child: Text(
        '$rank',
        style: const TextStyle(
          color: _accent,
          fontWeight: FontWeight.w800,
          fontSize: 15,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Support Leaderboard'),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final docs = snapshot.data ?? const [];

            return SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: _sectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Top Supporters',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Top 25 verified donations are shown here.',
                      style: TextStyle(
                        color: _textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (docs.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'No leaderboard entries yet.',
                          style: TextStyle(
                            color: _textSecondary,
                          ),
                        ),
                      )
                    else
                      ...List.generate(docs.length, (index) {
                        final data = docs[index].data();
                        final name = _resolveName(data);
                        final amount = data['amount'];
                        final message = (data['message'] ?? '').toString().trim();
                        final date = _formatDate(data['timestamp']);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _softAccent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _rankBadge(index + 1),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              color: _textPrimary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          '₹$amount',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: _accent,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (message.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        message,
                                        style: const TextStyle(
                                          color: _textSecondary,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 6),
                                    Text(
                                      date,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: _textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}