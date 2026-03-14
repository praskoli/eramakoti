import 'package:flutter/material.dart';

import '../../../models/bhakta_mandali_member.dart';
import '../../../services/firebase/bhakta_mandali_service.dart';
import '../widgets/mandali_member_tile.dart';

class MandaliLeaderboardScreen extends StatelessWidget {
  const MandaliLeaderboardScreen({
    super.key,
    required this.mandaliId,
    required this.title,
  });

  final String mandaliId;
  final String title;

  static const Color _bgColor = Color(0xFFF8F2E8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
      ),
      body: StreamBuilder<List<BhaktaMandaliMember>>(
        stream: BhaktaMandaliService.instance.watchLeaderboard(mandaliId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Failed to load leaderboard.\n${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? const <BhaktaMandaliMember>[];
          if (items.isEmpty) {
            return const Center(child: Text('No members found.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              return MandaliMemberTile(rank: index + 1, member: items[index]);
            },
          );
        },
      ),
    );
  }
}
