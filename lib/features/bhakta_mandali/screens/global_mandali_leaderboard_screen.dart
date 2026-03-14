import 'package:flutter/material.dart';

import '../../../models/bhakta_mandali.dart';
import '../../../services/firebase/bhakta_mandali_service.dart';
import '../widgets/mandali_leaderboard_tile.dart';
import 'mandali_detail_screen.dart';

class GlobalMandaliLeaderboardScreen extends StatelessWidget {
  const GlobalMandaliLeaderboardScreen({super.key});

  static const Color _bgColor = Color(0xFFF8F2E8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Global Mandali Leaderboard',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
      ),
      body: StreamBuilder<List<BhaktaMandali>>(
        stream: BhaktaMandaliService.instance.watchGlobalLeaderboard(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Failed to load leaderboard.\n${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data ?? const <BhaktaMandali>[];
          if (items.isEmpty) {
            return const Center(child: Text('No Mandalis yet.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              return MandaliLeaderboardTile(
                rank: index + 1,
                mandali: item,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MandaliDetailScreen(mandaliId: item.mandaliId),
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
}
