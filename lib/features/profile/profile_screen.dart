import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/build/app_footer_helper.dart';
import '../../models/user_profile.dart';
import '../../services/auth/auth_service.dart';
import '../../services/firebase/profile_service.dart';
import 'edit_profile_screen.dart';
import '../auth/login_screen.dart';
import '../../screens/support/support_ramakoti_screen.dart';

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
  bool _showSupportCard = true;
  static const String _upiId = '9121011887@pthdfc';
  static const String _payeeName = 'Koli Prasanth';
  static const String _upiNote = 'Support eRamakoti';

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
                const SizedBox(height: 18),
                if (_showSupportCard)
                  _SupportCard(
                    onDonate: () => _showDonationSheet(context),
                    onDetails: () => _showSupportDetails(context),
                    onDismiss: () {
                      setState(() {
                        _showSupportCard = false;
                      });
                      _showSnackBar('Support card dismissed.');
                    },
                  ),
                const SizedBox(height: 22),
                if (snapshot.connectionState == ConnectionState.waiting && profile == null)
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
                    _ContributionCard(
                      onCopyUpi: _copyUpiId,
                      onShareUpi: _shareUpi,
                      onDonateAmount: _launchUpiWithAmount,
                      onOpenSheet: () => _showDonationSheet(context),
                      onTapQr: () => _showQrPreview(context),
                    ),
                  ],
                const SizedBox(height: 26),
                FutureBuilder<String>(
                  future: AppFooterHelper.getFooterText(),
                  builder: (context, snapshot) {
                    final footerText = snapshot.data ?? 'Loading version...';

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          content: const Text('Are you sure you want to logout from eRamakoti?'),
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

  void _showSupportDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
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
                const Text(
                  'Support eRamakoti',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your support helps us continue this devotional effort and build more spiritual features for devotees.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
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
                      Navigator.pop(context);
                      Navigator.of(this.context).push(
                        MaterialPageRoute(
                          builder: (_) => const SupportRamakotiScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
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
          ),
        );
      },
    );
  }

  Future<void> _showDonationSheet(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SupportRamakotiScreen(),
      ),
    );
  }

  Future<void> _showQrPreview(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: _cardColor,
          insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Scan to Donate',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  _upiId,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: _accentDeep,
                  ),
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/images/donate_upi_qr.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _copyUpiId,
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text('Copy UPI'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _launchUpiWithoutAmount,
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: const Text('Open UPI App'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _copyUpiId() async {
    await Clipboard.setData(const ClipboardData(text: _upiId));
    _showSnackBar('UPI ID copied.');
  }

  Future<void> _shareUpi() async {
    await Share.share(
      'Support eRamakoti\nUPI ID: $_upiId\nPayee: $_payeeName',
      subject: 'Support eRamakoti',
    );
  }

  Future<void> _launchUpiWithoutAmount() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SupportRamakotiScreen(),
      ),
    );
  }

  Future<void> _launchUpiWithAmount(int amount) async {
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

class _SupportCard extends StatelessWidget {
  const _SupportCard({
    required this.onDonate,
    required this.onDetails,
    required this.onDismiss,
  });

  final VoidCallback onDonate;
  final VoidCallback onDetails;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _ProfileScreenState._softAccent,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _ProfileScreenState._softBorder),
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🙏 Support this project',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _ProfileScreenState._accentDeep,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Voluntary donation. All features are free for everyone.',
            style: TextStyle(
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
                      child: const Text(
                        'Offer Support',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
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
                      foregroundColor: _ProfileScreenState._accentDeep,
                      side: const BorderSide(color: _ProfileScreenState._outline),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Text(
                      'Details',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: onDismiss,
                style: TextButton.styleFrom(
                  foregroundColor: _ProfileScreenState._accentDeep,
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
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

class _ContributionCard extends StatelessWidget {
  const _ContributionCard({
    required this.onCopyUpi,
    required this.onShareUpi,
    required this.onDonateAmount,
    required this.onOpenSheet,
    required this.onTapQr,
  });

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
          const Center(
            child: Text(
              'Offer Support',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: _ProfileScreenState._textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Center(
            child: Text(
              _ProfileScreenState._upiId,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _ProfileScreenState._accentDeep,
              ),
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTapQr,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/images/donate_upi_qr.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: onCopyUpi,
                child: const Text(
                  'Copy UPI ID',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _ProfileScreenState._accentDeep,
                  ),
                ),
              ),
              const SizedBox(width: 18),
              TextButton(
                onPressed: onShareUpi,
                child: const Text(
                  'Share UPI ID',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _ProfileScreenState._accentDeep,
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
              label: const Text('Open Support Options'),
            ),
          ),
          const SizedBox(height: 18),
          const Center(
            child: Text(
              'Choose an offerning:',
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