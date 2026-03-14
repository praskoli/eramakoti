import 'package:flutter/material.dart';

import '../bhakta_mandali/screens/bhakta_mandali_home_screen.dart';
import '../history/history_screen.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';

class MainBottomNavScreen extends StatefulWidget {
  const MainBottomNavScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainBottomNavScreen> createState() => _MainBottomNavScreenState();
}

class _MainBottomNavScreenState extends State<MainBottomNavScreen> {
  static const Color _bgColor = Color(0xFFF8F2E8);
  static const Color _navBg = Colors.white;
  static const Color _accent = Color(0xFFFF9E2C);
  static const Color _inactive = Color(0xFF8F857A);
  static const Color _softAccent = Color(0xFFFFF1DE);
  static const Color _softBorder = Color(0xFFEADFD2);

  late int _currentIndex;

  late final List<Widget> _screens = const [
    HomeScreen(),
    RamakotiHistoryScreen(),
    BhaktaMandaliHomeScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 3);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: _navBg,
            border: Border(
              top: BorderSide(color: _softBorder),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 16,
                offset: Offset(0, -4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          child: Row(
            children: [
              _NavItem(
                label: 'Home',
                icon: Icons.home_rounded,
                selected: _currentIndex == 0,
                onTap: () => setState(() => _currentIndex = 0),
              ),
              const SizedBox(width: 8),
              _NavItem(
                label: 'History',
                icon: Icons.auto_stories_rounded,
                selected: _currentIndex == 1,
                onTap: () => setState(() => _currentIndex = 1),
              ),
              const SizedBox(width: 8),
              _NavItem(
                label: 'Mandali',
                icon: Icons.groups_rounded,
                selected: _currentIndex == 2,
                onTap: () => setState(() => _currentIndex = 2),
              ),
              const SizedBox(width: 8),
              _NavItem(
                label: 'Profile',
                icon: Icons.account_circle_rounded,
                selected: _currentIndex == 3,
                onTap: () => setState(() => _currentIndex = 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  static const Color _accent = Color(0xFFFF9E2C);
  static const Color _inactive = Color(0xFF8F857A);
  static const Color _softAccent = Color(0xFFFFF1DE);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? _softAccent : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 26,
                  color: selected ? _accent : _inactive,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected ? _accent : _inactive,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}