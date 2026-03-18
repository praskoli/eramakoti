import 'package:flutter/material.dart';

import '../bhakta_mandali/screens/bhakta_mandali_home_screen.dart';
import '../history/history_screen.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import '../../screens/support/support_ramakoti_screen.dart';

class MainBottomNavScreen extends StatefulWidget {
  const MainBottomNavScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  static void switchTab(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_MainBottomNavScreenState>();
    state?._onNavTap(index);
  }

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
  late final PageController _pageController;

  late final List<Widget> _screens = const [
    HomeScreen(),
    RamakotiHistoryScreen(),
    BhaktaMandaliHomeScreen(),
    SupportRamakotiScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 4);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (!mounted) return;
    if (index < 0 || index >= _screens.length) return;
    if (_currentIndex == index) return;

    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  void _onPageChanged(int index) {
    if (!mounted) return;
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
  }

  Future<bool> _handleWillPop() async {
    if (_currentIndex != 0) {
      _onNavTap(0);
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentIndex != 0) {
          _onNavTap(0);
        }
      },
      child: Scaffold(
        backgroundColor: _bgColor,
        body: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
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
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
            child: Row(
              children: [
                _NavItem(
                  label: 'Home',
                  icon: Icons.home_rounded,
                  selected: _currentIndex == 0,
                  onTap: () => _onNavTap(0),
                ),
                const SizedBox(width: 6),
                _NavItem(
                  label: 'History',
                  icon: Icons.auto_stories_rounded,
                  selected: _currentIndex == 1,
                  onTap: () => _onNavTap(1),
                ),
                const SizedBox(width: 6),
                _NavItem(
                  label: 'Mandali',
                  icon: Icons.groups_rounded,
                  selected: _currentIndex == 2,
                  onTap: () => _onNavTap(2),
                ),
                const SizedBox(width: 6),
                _NavItem(
                  label: 'Support',
                  icon: Icons.volunteer_activism_rounded,
                  selected: _currentIndex == 3,
                  onTap: () => _onNavTap(3),
                ),
                const SizedBox(width: 6),
                _NavItem(
                  label: 'Profile',
                  icon: Icons.account_circle_rounded,
                  selected: _currentIndex == 4,
                  onTap: () => _onNavTap(4),
                ),
              ],
            ),
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
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? _softAccent : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: selected ? _accent : _inactive,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
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