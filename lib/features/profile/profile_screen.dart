import 'package:flutter/material.dart';

import '../../core/build/app_footer_helper.dart';
import '../../models/user_profile.dart';
import '../../services/auth/auth_service.dart';
import '../../services/firebase/profile_service.dart';
import '../auth/login_screen.dart';
import '../devotion/personal_summary_devotion_screen.dart';
import '../navigation/main_bottom_nav_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color _bgColor = Color(0xFFF8F2E8);
  static const Color _cardColor = Color(0xFFFFFCF8);
  static const Color _textPrimary = Color(0xFF2F2A25);
  static const Color _textSecondary = Color(0xFF7C7167);
  static const Color _accent = Color(0xFFFF9E2C);
  static const Color _accentDeep = Color(0xFFE8881A);
  static const Color _softBorder = Color(0xFFEADFD2);
  static const Color _outline = Color(0xFF9B8F86);

  late Future<UserProfile> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = ProfileService.instance.getOrCreateProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: FutureBuilder<UserProfile>(
          future: _profileFuture,
          builder: (context, snapshot) {
            final profile = snapshot.data;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
              children: [
                const Text(
                  'Profile',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 22),
                if (snapshot.connectionState == ConnectionState.waiting &&
                    profile == null)
                  const _ProfileLoadingCard()
                else if (snapshot.hasError)
                  _ErrorCard(
                    message: 'Failed to load profile: ${snapshot.error}',
                    onRetry: _reloadProfile,
                  )
                else if (profile != null) ...[
                    _ProfileHeaderCard(
                      profile: profile,
                      onEditAvatar: () => _openEditProfile(profile),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _PrimaryActionButton(
                            label: 'Edit Profile',
                            onTap: () => _openEditProfile(profile),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _OutlineActionButton(
                            label: 'Logout',
                            onTap: _handleLogout,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _DevotionEntryCard(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PersonalSummaryScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    _SupportShortcutCard(
                      onTap: _openSupportTab,
                    ),
                  ],
                const SizedBox(height: 26),
                FutureBuilder<String>(
                  future: AppFooterHelper.getFooterText(),
                  builder: (context, snapshot) {
                    final footerText = snapshot.data ?? 'Loading version...';

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: _cardColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: _softBorder),
                      ),
                      child: Center(
                        child: Text(
                          footerText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: _textPrimary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _reloadProfile() async {
    setState(() {
      _profileFuture = ProfileService.instance.getOrCreateProfile();
    });
  }

  Future<void> _openEditProfile(UserProfile profile) async {
    final result = await Navigator.of(context).push<UserProfile>(
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(initialProfile: profile),
      ),
    );

    if (result == null || !mounted) return;

    setState(() {
      _profileFuture = Future.value(result);
    });

    _showSnackBar('Profile updated successfully.');
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text('Logout'),
          content: const Text(
            'Are you sure you want to logout from eRamakoti?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: _accentDeep),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      await AuthService.instance.signOut();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );
    } catch (e) {
      _showSnackBar('Logout failed: $e');
    }
  }

  void _openSupportTab() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const MainBottomNavScreen(initialIndex: 3),
      ),
          (route) => false,
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({
    required this.profile,
    required this.onEditAvatar,
  });

  final UserProfile profile;
  final VoidCallback onEditAvatar;

  @override
  Widget build(BuildContext context) {
    final initials = _buildInitials(profile.displayName);
    final providerLabel = _providerLabel(profile.provider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        color: _ProfileScreenState._cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _ProfileScreenState._softBorder),
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: const Color(0xFFECE1FA),
                backgroundImage: profile.photoUrl.trim().isNotEmpty
                    ? NetworkImage(profile.photoUrl)
                    : null,
                child: profile.photoUrl.trim().isEmpty
                    ? Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF7C1FB1),
                  ),
                )
                    : null,
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onEditAvatar,
                    borderRadius: BorderRadius.circular(999),
                    child: Ink(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: _ProfileScreenState._accent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Profile ID: ${profile.resolvedProfileId}',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: _ProfileScreenState._textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Name: ${profile.displayName.isNotEmpty ? profile.displayName : '-'}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: _ProfileScreenState._textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Email: ${profile.email.isNotEmpty ? profile.email : '-'}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: _ProfileScreenState._textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Mobile: ${profile.mobileNumber.isNotEmpty ? profile.mobileNumber : '-'}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: _ProfileScreenState._textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            providerLabel,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14.5,
              color: _ProfileScreenState._textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  static String _providerLabel(String provider) {
    switch (provider.trim()) {
      case 'google.com':
        return 'Logged in using Google';
      case 'facebook.com':
        return 'Logged in using Facebook';
      default:
        return 'Logged in';
    }
  }

  static String _buildInitials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

class _SupportShortcutCard extends StatelessWidget {
  const _SupportShortcutCard({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1DE),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEADFD2)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.volunteer_activism_rounded,
                color: Color(0xFFE8881A),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Support eRamakoti',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2F2A25),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Offer Support and support-related details are available in the Support tab.',
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: Color(0xFF2F2A25),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: _ProfileScreenState._accent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                'Offer Support',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: _ProfileScreenState._accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _OutlineActionButton extends StatelessWidget {
  const _OutlineActionButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: _ProfileScreenState._accentDeep,
          side: const BorderSide(color: _ProfileScreenState._outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ProfileLoadingCard extends StatelessWidget {
  const _ProfileLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _ProfileScreenState._cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _ProfileScreenState._softBorder),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: _ProfileScreenState._accent,
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _ProfileScreenState._cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _ProfileScreenState._softBorder),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _ProfileScreenState._textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: _ProfileScreenState._accent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _DevotionEntryCard extends StatelessWidget {
  final VoidCallback onTap;

  const _DevotionEntryCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: const Color(0xFFF8F1E8),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE5D5C5)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(10),
              child: const Icon(
                Icons.self_improvement,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Personal Devotion',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF3E2A1F),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Add Japa, manual writing, and other devotion',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6A5546),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF6A5546),
            ),
          ],
        ),
      ),
    );
  }
}