import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/build/app_footer_helper.dart';
import '../../models/user_profile.dart';
import '../../screens/support/support_ramakoti_screen.dart';
import '../../services/auth/auth_service.dart';
import '../../services/firebase/profile_service.dart';
import '../../services/payments/upi_payment_service.dart';
import '../../services/temples/support_target_resolver.dart';
import '../../services/temples/temple_context_service.dart';
import '../auth/login_screen.dart';
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
  static const Color _softAccent = Color(0xFFFFF1DE);
  static const Color _softBorder = Color(0xFFEADFD2);
  static const Color _outline = Color(0xFF9B8F86);
  static const Color _softBlue = Color(0xFFEAF2FF);
  static const Color _blueText = Color(0xFF2563EB);

  bool _showSupportCards = true;

  late Future<UserProfile> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = ProfileService.instance.getOrCreateProfile();
  }

  @override
  Widget build(BuildContext context) {
    final templeContext = context.watch<TempleContextService>();

    final templeSupportTarget = SupportTargetResolver.resolve(
      temple: templeContext.currentTemple,
      defaultUpiId: UpiPaymentService.defaultUpiId,
      defaultPayeeName: UpiPaymentService.defaultPayeeName,
      defaultLabel: 'eRamakoti Support',
    );

    const platformSupportTarget = SupportTarget(
      upiId: UpiPaymentService.defaultUpiId,
      payeeName: UpiPaymentService.defaultPayeeName,
      label: 'eRamakoti Platform',
    );

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
                const SizedBox(height: 18),
                if (_showSupportCards)
                  _DualSupportCards(
                    showTempleCard: templeContext.isTempleMode,
                    templeLabel: templeSupportTarget.label,
                    onTempleSupport: () => _openTempleSupport(context),
                    onTempleDetails: () => _showSupportDetails(
                      context: context,
                      title: 'Support ${templeSupportTarget.label}',
                      message:
                      'Your support helps continue the devotional effort for ${templeSupportTarget.label} through the active temple context.',
                      actionLabel: 'Support Temple',
                      onAction: () => _openTempleSupport(context),
                    ),
                    onPlatformSupport: () => _openPlatformSupport(context),
                    onPlatformDetails: () => _showSupportDetails(
                      context: context,
                      title: 'Support eRamakoti Platform',
                      message:
                      'Your support helps us maintain and improve the eRamakoti platform for all devotees.',
                      actionLabel: 'Support Platform',
                      onAction: () => _openPlatformSupport(context),
                    ),
                    onDismiss: () {
                      setState(() {
                        _showSupportCards = false;
                      });
                      _showSnackBar('Support cards dismissed.');
                    },
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
                    if (templeContext.isTempleMode) ...[
                      _ContributionCard(
                        title: 'Support ${templeSupportTarget.label}',
                        subtitle: 'Temple support using the active temple context',
                        upiId: templeSupportTarget.upiId,
                        payeeName: templeSupportTarget.payeeName,
                        supportLabel: templeSupportTarget.label,
                        accentColor: _blueText,
                        badgeText: 'Temple Support',
                        badgeBg: _softBlue,
                        badgeTextColor: _blueText,
                        onCopyUpi: () => _copyUpiId(templeSupportTarget.upiId),
                        onShareUpi: () => _shareUpi(
                          templeSupportTarget.upiId,
                          templeSupportTarget.payeeName,
                          templeSupportTarget.label,
                        ),
                        onDonateAmount: (_) => _openTempleSupport(context),
                        onOpenSheet: () => _openTempleSupport(context),
                        onTapQr: () => _openTempleSupport(context),
                      ),
                      const SizedBox(height: 18),
                    ],
                    _ContributionCard(
                      title: 'Support eRamakoti Platform',
                      subtitle: 'Help maintain and improve the app for all devotees',
                      upiId: platformSupportTarget.upiId,
                      payeeName: platformSupportTarget.payeeName,
                      supportLabel: platformSupportTarget.label,
                      accentColor: _accentDeep,
                      badgeText: 'Platform Support',
                      badgeBg: _softAccent,
                      badgeTextColor: _accentDeep,
                      onCopyUpi: () => _copyUpiId(platformSupportTarget.upiId),
                      onShareUpi: () => _shareUpi(
                        platformSupportTarget.upiId,
                        platformSupportTarget.payeeName,
                        platformSupportTarget.label,
                      ),
                      onDonateAmount: (_) => _openPlatformSupport(context),
                      onOpenSheet: () => _openPlatformSupport(context),
                      onTapQr: () => _openPlatformSupport(context),
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

  Future<void> _openTempleSupport(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SupportRamakotiScreen(),
      ),
    );
  }

  Future<void> _openPlatformSupport(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SupportRamakotiScreen(
          source: 'platform_support_profile',
          forcePlatformSupport: true,
        )
      ),
    );
  }

  void _showSupportDetails({
    required BuildContext context,
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4C7BA),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.5,
                    color: _textSecondary,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      onAction();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      actionLabel,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _copyUpiId(String upiId) async {
    await Clipboard.setData(ClipboardData(text: upiId));
    _showSnackBar('UPI ID copied.');
  }

  Future<void> _shareUpi(
      String upiId,
      String payeeName,
      String supportLabel,
      ) async {
    await Share.share(
      'Support $supportLabel\nUPI ID: $upiId\nPayee: $payeeName',
      subject: 'Support $supportLabel',
    );
  }

  Future<void> _launchUpiWithAmount(int amount) async {
    if (kDebugMode) {
      debugPrint('Requested support amount: ₹$amount');
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SupportRamakotiScreen(),
      ),
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

class _DualSupportCards extends StatelessWidget {
  const _DualSupportCards({
    required this.showTempleCard,
    required this.templeLabel,
    required this.onTempleSupport,
    required this.onTempleDetails,
    required this.onPlatformSupport,
    required this.onPlatformDetails,
    required this.onDismiss,
  });

  final bool showTempleCard;
  final String templeLabel;
  final VoidCallback onTempleSupport;
  final VoidCallback onTempleDetails;
  final VoidCallback onPlatformSupport;
  final VoidCallback onPlatformDetails;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showTempleCard) ...[
          _SupportCard(
            title: '🙏 Support $templeLabel',
            subtitle: 'Voluntary support for the active temple seva.',
            accentBg: _ProfileScreenState._softBlue,
            accentText: _ProfileScreenState._blueText,
            primaryLabel: 'Support Temple',
            secondaryLabel: 'Details',
            onDonate: onTempleSupport,
            onDetails: onTempleDetails,
            onDismiss: onDismiss,
          ),
          const SizedBox(height: 14),
        ],
        _SupportCard(
          title: '🙏 Support eRamakoti Platform',
          subtitle: 'Voluntary support for app maintenance and improvements.',
          accentBg: _ProfileScreenState._softAccent,
          accentText: _ProfileScreenState._accentDeep,
          primaryLabel: 'Support App',
          secondaryLabel: 'Details',
          onDonate: onPlatformSupport,
          onDetails: onPlatformDetails,
          onDismiss: onDismiss,
        ),
      ],
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard({
    required this.title,
    required this.subtitle,
    required this.accentBg,
    required this.accentText,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onDonate,
    required this.onDetails,
    required this.onDismiss,
  });

  final String title;
  final String subtitle;
  final Color accentBg;
  final Color accentText;
  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback onDonate;
  final VoidCallback onDetails;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: accentBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _ProfileScreenState._softBorder),
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: accentText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: _ProfileScreenState._textPrimary,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x66FF9E2C),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: Color(0x33FFB347),
                          blurRadius: 28,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: onDonate,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: _ProfileScreenState._accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Text(
                        primaryLabel,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: onDetails,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: accentText,
                      side: const BorderSide(
                        color: _ProfileScreenState._outline,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: Text(
                      secondaryLabel,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: onDismiss,
                style: TextButton.styleFrom(
                  foregroundColor: accentText,
                ),
                child: const Text(
                  'Dismiss',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
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

class _ContributionCard extends StatelessWidget {
  const _ContributionCard({
    required this.title,
    required this.subtitle,
    required this.upiId,
    required this.payeeName,
    required this.supportLabel,
    required this.accentColor,
    required this.badgeText,
    required this.badgeBg,
    required this.badgeTextColor,
    required this.onCopyUpi,
    required this.onShareUpi,
    required this.onDonateAmount,
    required this.onOpenSheet,
    required this.onTapQr,
  });

  final String title;
  final String subtitle;
  final String upiId;
  final String payeeName;
  final String supportLabel;
  final Color accentColor;
  final String badgeText;
  final Color badgeBg;
  final Color badgeTextColor;
  final VoidCallback onCopyUpi;
  final VoidCallback onShareUpi;
  final ValueChanged<int> onDonateAmount;
  final VoidCallback onOpenSheet;
  final VoidCallback onTapQr;

  @override
  Widget build(BuildContext context) {
    const amounts = [51, 101, 501, 1001, 2001, 5001];

    return Container(
      decoration: BoxDecoration(
        color: _ProfileScreenState._cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _ProfileScreenState._softBorder),
      ),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: badgeTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: _ProfileScreenState._textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: _ProfileScreenState._textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              upiId,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: accentColor,
              ),
            ),
          ),
          const SizedBox(height: 14),
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTapQr,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F5F0),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _ProfileScreenState._softBorder,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.qr_code_2_rounded,
                    size: 56,
                    color: accentColor,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tap to open QR and support options',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _ProfileScreenState._textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Payee: $payeeName',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: _ProfileScreenState._textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: onCopyUpi,
                child: Text(
                  'Copy UPI ID',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
              ),
              const SizedBox(width: 18),
              TextButton(
                onPressed: onShareUpi,
                child: Text(
                  'Share UPI ID',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Center(
            child: OutlinedButton.icon(
              onPressed: onOpenSheet,
              icon: const Icon(Icons.open_in_new_rounded),
              label: Text('Open $supportLabel'),
            ),
          ),
          const SizedBox(height: 18),
          const Center(
            child: Text(
              'Choose an offering:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _ProfileScreenState._textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            alignment: WrapAlignment.center,
            children: amounts
                .map(
                  (amount) => _AmountChip(
                amount: amount,
                onTap: () => onDonateAmount(amount),
              ),
            )
                .toList(),
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

class _AmountChip extends StatelessWidget {
  const _AmountChip({
    required this.amount,
    required this.onTap,
  });

  final int amount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: 92,
          height: 54,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _ProfileScreenState._outline,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              '₹$amount',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _ProfileScreenState._textPrimary,
              ),
            ),
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