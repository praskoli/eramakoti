import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/firebase/donation_service.dart';
import '../../services/firebase/ramakoti_service.dart';
import '../../services/payments/razorpay_payment_service.dart';
import 'support_leaderboard_screen.dart';

class SupportRamakotiScreen extends StatefulWidget {
  const SupportRamakotiScreen({
    super.key,
    this.source = 'support_screen',
    this.sourceMandaliId,
    this.sourceMandaliName,
    this.sourceChallengeId,
  });

  final String source;
  final String? sourceMandaliId;
  final String? sourceMandaliName;
  final String? sourceChallengeId;

  @override
  State<SupportRamakotiScreen> createState() => _SupportRamakotiScreenState();
}

class _SupportRamakotiScreenState extends State<SupportRamakotiScreen>
    with TickerProviderStateMixin {
  static const Color _accent = Color(0xFFFF9E2C);
  static const Color _bg = Color(0xFFF8F2E8);
  static const Color _card = Colors.white;
  static const Color _border = Color(0xFFEADFD2);
  static const Color _textPrimary = Color(0xFF2F2A25);
  static const Color _textSecondary = Color(0xFF7C7167);
  static const Color _softAccent = Color(0xFFFFF1DE);
  static const Color _softGreen = Color(0xFFEAF8EE);
  static const Color _greenText = Color(0xFF2F8F4E);
  static const Color _softBlue = Color(0xFFEAF2FF);
  static const Color _blueText = Color(0xFF2563EB);

  final List<int> _offerings = const [11, 21, 51, 101, 501, 1001, 5001, 10001];

  final List<String> _blessingMessages = const [
    'May Shri Ram bless you and your family with peace and prosperity 🙏',
    'Your offering strengthens this sacred journey of devotion.',
    'May Lord Rama guide and protect you always.',
    'Your seva adds light to this spiritual mission.',
    'May your home be filled with devotion, grace, and joy.',
    'Jai Shri Ram 🙏 Your support helps Ram Naam continue.',
    'May Sri Ram bless your family with strength and harmony.',
    'Your devotion will return as blessings in your life.',
    'With gratitude and prayer, we thank you for your offering.',
    'May this sacred offering bring peace to your heart and home.',
  ];

  int? _selectedAmount;
  final TextEditingController _customController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  bool _loading = false;
  bool _anonymous = false;
  bool _showAdvanced = false;

  bool _showSuccessPopup = false;
  bool _showPreparingPaymentOverlay = false;

  int _lastSuccessAmount = 0;
  String _lastSuccessName = 'Devotee';
  String _lastSuccessMessage = '';

  late final AudioPlayer _audioPlayer;
  late final AnimationController _popupController;
  late final AnimationController _flowerController;
  late final Animation<double> _popupFade;
  late final Animation<Offset> _popupSlide;

  late final List<_FlowerParticle> _flowers;
  int _messageRotationIndex = 0;

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _supportWallDocs = [];
  DocumentSnapshot<Map<String, dynamic>>? _supportWallLastDocument;
  bool _supportWallLoading = true;
  bool _supportWallLoadingMore = false;
  bool _supportWallHasMore = false;

  bool get _isMandaliSupport =>
      (widget.sourceMandaliId ?? '').trim().isNotEmpty;

  String get _supportType => _isMandaliSupport ? 'mandali' : 'individual';

  String get _resolvedSource {
    final raw = widget.source.trim();
    if (raw.isNotEmpty) return raw;
    return _isMandaliSupport ? 'mandali_support_screen' : 'support_screen';
  }

  int? get _selectedValue {
    if (_selectedAmount != null) return _selectedAmount;
    final raw = _customController.text.trim();
    if (raw.isEmpty) return null;
    return int.tryParse(raw);
  }

  @override
  void initState() {
    super.initState();
    RazorpayPaymentService.instance.initialize();

    _audioPlayer = AudioPlayer();
    _popupController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _flowerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    _popupFade = CurvedAnimation(
      parent: _popupController,
      curve: Curves.easeOutCubic,
    );

    _popupSlide = Tween<Offset>(
      begin: const Offset(0, -0.14),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _popupController,
        curve: Curves.easeOutBack,
      ),
    );

    _flowers = List.generate(
      18,
          (index) => _FlowerParticle.random(index),
    );

    _loadInitialSupportWall();
  }

  @override
  void dispose() {
    _customController.dispose();
    _nameController.dispose();
    _messageController.dispose();
    _audioPlayer.dispose();
    _popupController.dispose();
    _flowerController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialSupportWall() async {
    setState(() {
      _supportWallLoading = true;
    });

    try {
      final page = await DonationService.instance.fetchSupportWallPage(limit: 25);
      if (!mounted) return;
      setState(() {
        _supportWallDocs
          ..clear()
          ..addAll(page.docs);
        _supportWallLastDocument = page.lastDocument;
        _supportWallHasMore = page.hasMore;
        _supportWallLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _supportWallDocs.clear();
        _supportWallLastDocument = null;
        _supportWallHasMore = false;
        _supportWallLoading = false;
      });
    }
  }

  Future<void> _loadNextSupportWallPage() async {
    if (_supportWallLoadingMore || !_supportWallHasMore) return;

    setState(() {
      _supportWallLoadingMore = true;
    });

    try {
      final page = await DonationService.instance.fetchSupportWallPage(
        limit: 25,
        startAfterDocument: _supportWallLastDocument,
      );

      if (!mounted) return;

      setState(() {
        _supportWallDocs.addAll(page.docs);
        _supportWallLastDocument = page.lastDocument;
        _supportWallHasMore = page.hasMore;
        _supportWallLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _supportWallLoadingMore = false;
      });
    }
  }

  String _formatDate(dynamic value) {
    DateTime? date;
    if (value is Timestamp) date = value.toDate();
    if (value is String) date = DateTime.tryParse(value);
    if (date == null) return '—';
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  String _formatIndianNumber(int value) {
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

  String _friendlyError(Object e) {
    final text = e.toString().toLowerCase();

    if (text.contains('permission-denied')) {
      return 'Permission denied while processing support payment.';
    }
    if (text.contains('network')) {
      return 'Network issue. Please check your internet and try again.';
    }
    if (text.contains('unavailable')) {
      return 'Payment service is temporarily unavailable. Please try again.';
    }
    return e.toString();
  }

  String _resolveDisplayName({
    required RazorpayPaymentResult result,
  }) {
    if (result.anonymous) return 'A Devotee';

    final enteredName = (result.supporterName ?? '').trim();
    if (enteredName.isNotEmpty) return enteredName;

    final localName = _nameController.text.trim();
    if (localName.isNotEmpty) return localName;

    final firebaseName = FirebaseAuth.instance.currentUser?.displayName?.trim();
    if (firebaseName != null && firebaseName.isNotEmpty) {
      return firebaseName;
    }

    final email = FirebaseAuth.instance.currentUser?.email?.trim();
    if (email != null && email.isNotEmpty && email.contains('@')) {
      final prefix = email.split('@').first.trim();
      if (prefix.isNotEmpty) {
        return prefix;
      }
    }

    return 'Devotee';
  }

  String _nextBlessingMessage(String customMessage) {
    if (customMessage.trim().isNotEmpty) {
      return customMessage.trim();
    }
    final message =
    _blessingMessages[_messageRotationIndex % _blessingMessages.length];
    _messageRotationIndex++;
    return message;
  }

  Future<void> _playSuccessSound() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(
        AssetSource('audio/jai_shri_ram.mp3'),
        volume: 1.0,
      );
    } catch (_) {}
  }

  Future<void> _showCelebrationPopup(
      RazorpayPaymentResult result,
      int amount,
      ) async {
    final resolvedAmount = result.requestedAmount ?? amount;
    final resolvedName = _resolveDisplayName(result: result);
    final resolvedMessage = _nextBlessingMessage(result.supporterMessage ?? '');

    setState(() {
      _lastSuccessAmount = resolvedAmount;
      _lastSuccessName = resolvedName;
      _lastSuccessMessage = resolvedMessage;
      _showSuccessPopup = true;
    });

    _flowers
      ..clear()
      ..addAll(
        List.generate(
          18,
              (index) => _FlowerParticle.random(index),
        ),
      );

    await Future.wait([
      _popupController.forward(from: 0),
      _flowerController.forward(from: 0),
      _playSuccessSound(),
    ]);
  }

  Future<void> _closeSuccessPopup() async {
    await _popupController.reverse();
    if (!mounted) return;
    setState(() {
      _showSuccessPopup = false;
    });
  }

  Future<void> _continueAfterSuccess() async {
    await _popupController.reverse();
    if (!mounted) return;

    setState(() {
      _showSuccessPopup = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.pop(true);
      }
    });
  }

  Future<void> _startSupportPayment(int amount) async {
    final messenger = ScaffoldMessenger.of(context);

    if (_loading) return;

    if (amount <= 0) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() {
      _loading = true;
      _showPreparingPaymentOverlay = true;
      _selectedAmount = amount;
    });

    try {
      final result = await RazorpayPaymentService.instance.startPayment(
        request: RazorpayPaymentRequest(
          amount: amount,
          source: _resolvedSource,
          supportType: _supportType,
          supporterName: _nameController.text.trim(),
          supporterMessage: _messageController.text.trim(),
          anonymous: _anonymous,
          sourceMandaliId: widget.sourceMandaliId,
          sourceMandaliName: widget.sourceMandaliName,
          sourceChallengeId: widget.sourceChallengeId,
        ),
      );

      if (!mounted) return;

      switch (result.status) {
        case RazorpayPaymentStatus.success:
          await _showCelebrationPopup(result, amount);
          break;
        case RazorpayPaymentStatus.cancelled:
          messenger.showSnackBar(
            SnackBar(
              content: Text(result.message ?? 'Payment cancelled.'),
            ),
          );
          break;
        case RazorpayPaymentStatus.failed:
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                result.message ?? 'Payment failed. Please try again.',
              ),
            ),
          );
          break;
        case RazorpayPaymentStatus.externalWallet:
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                result.message ?? 'External wallet selected.',
              ),
            ),
          );
          break;
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(_friendlyError(e)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _showPreparingPaymentOverlay = false;
        });
      }
    }
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

  Widget _offeringTile(int amount) {
    final selected = _selectedAmount == amount;

    return GestureDetector(
      onTap: _loading
          ? null
          : () async {
        setState(() {
          _selectedAmount = amount;
          _customController.clear();
        });
        await _startSupportPayment(amount);
      },
      child: Container(
        height: 58,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? _accent : Colors.grey.shade300,
          ),
          color: selected ? _accent.withOpacity(.10) : Colors.white,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '₹$amount',
              maxLines: 1,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: selected ? _accent : Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _supportContextCard() {
    if (!_isMandaliSupport) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _softBlue,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD9E7FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.groups_rounded, color: _blueText),
              SizedBox(width: 8),
              Text(
                'Mandali Support',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: _blueText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Mandali: ${widget.sourceMandaliName ?? 'Bhakta Mandali'}',
            style: const TextStyle(
              color: _textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          if ((widget.sourceChallengeId ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Challenge ID: ${widget.sourceChallengeId}',
              style: const TextStyle(
                color: _textSecondary,
                fontSize: 12.5,
              ),
            ),
          ],
          const SizedBox(height: 8),
          const Text(
            'This support will be recorded as a Mandali contribution and tracked separately from individual offerings.',
            style: TextStyle(
              color: _textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlowerLayer() {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _flowerController,
        builder: (context, _) {
          return Stack(
            children: _flowers.map((flower) {
              final progress = _flowerController.value;
              final top = (-40) + ((300 + flower.travelDistance) * progress);
              final sway =
                  sin((progress * pi * 2) + flower.phase) * flower.sway;
              final rotation = (progress * 2.5) + flower.phase;

              return Positioned(
                left: flower.left + sway,
                top: top,
                child: Transform.rotate(
                  angle: rotation,
                  child: Opacity(
                    opacity: (1 - progress * 0.35).clamp(0, 1),
                    child: Text(
                      flower.symbol,
                      style: TextStyle(
                        fontSize: flower.size,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildPreparingPaymentOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: false,
        child: Container(
          color: Colors.black.withOpacity(0.18),
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 28),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _accent.withOpacity(.25)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  SizedBox(
                    width: 34,
                    height: 34,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Preparing secure payment...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _textPrimary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Jai Shri Ram 🙏',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessPopup() {
    final title =
    _isMandaliSupport ? '🙏 Mandali Support Successful' : '🙏 Support Successful';

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: false,
        child: Container(
          color: Colors.black.withOpacity(0.12),
          child: Stack(
            children: [
              _buildFlowerLayer(),
              SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                    child: FadeTransition(
                      opacity: _popupFade,
                      child: SlideTransition(
                        position: _popupSlide,
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: _accent.withOpacity(.35),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x26000000),
                                  blurRadius: 22,
                                  offset: Offset(0, 12),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: _softAccent,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _accent.withOpacity(.25),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.temple_hindu_rounded,
                                    size: 30,
                                    color: _accent,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  title,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: _textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Thank you for offering ₹$_lastSuccessAmount, $_lastSuccessName',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: _accent,
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: _softAccent,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Text(
                                    _lastSuccessMessage,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w600,
                                      color: _textSecondary,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'May Sri Ram bless you and your family. Jai Shri Ram 🙏',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: _textPrimary,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: _closeSuccessPopup,
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(
                                            color: _accent.withOpacity(.4),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 13,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                            BorderRadius.circular(14),
                                          ),
                                        ),
                                        child: const Text('Stay Here'),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: _continueAfterSuccess,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _accent,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 13,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                            BorderRadius.circular(14),
                                          ),
                                        ),
                                        child: const Text('Continue'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupportWallSection() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Support Wall',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Support entries shown here can be reviewed later.',
            style: TextStyle(
              color: _textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SupportLeaderboardScreen(),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: _accent.withOpacity(.35)),
                foregroundColor: _accent,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'View Leaderboard',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (_supportWallLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_supportWallDocs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No support entries yet.',
                style: TextStyle(
                  color: _textSecondary,
                ),
              ),
            )
          else ...[
              ..._supportWallDocs.map((doc) {
                final data = doc.data();
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _softAccent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              (data['name'] ?? 'Devotee').toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: _textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            '₹${data['amount'] ?? ''}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: _accent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if ((data['message'] ?? '').toString().trim().isNotEmpty)
                        Text(
                          (data['message'] ?? '').toString(),
                          style: const TextStyle(
                            color: _textSecondary,
                            height: 1.4,
                          ),
                        ),
                      const SizedBox(height: 6),
                      Text(
                        _formatDate(data['timestamp']),
                        style: const TextStyle(
                          fontSize: 12,
                          color: _textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _supportWallHasMore && !_supportWallLoadingMore
                      ? _loadNextSupportWallPage
                      : null,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: _accent.withOpacity(.35)),
                    foregroundColor: _accent,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _supportWallLoadingMore
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  )
                      : Text(
                    _supportWallHasMore
                        ? 'View next 25'
                        : 'No more to display',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedAmount = _selectedValue ?? 21;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(_isMandaliSupport ? 'Mandali Support' : 'Offer Support'),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            StreamBuilder<int>(
              stream: RamakotiService.instance.watchGlobalRamCount(),
              builder: (context, globalSnapshot) {
                final globalTotal = globalSnapshot.data ?? 0;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isMandaliSupport
                                  ? '🪔 Support this Mandali'
                                  : '🪔 Offer Support to eRamakoti',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: _textPrimary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _isMandaliSupport
                                  ? 'Your support helps this Bhakta Mandali continue devotional activities and complete its sacred challenge.'
                                  : 'Your voluntary contribution helps maintain this devotional platform and support future spiritual initiatives.',
                              style: const TextStyle(
                                height: 1.45,
                                color: _textSecondary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'This offering is completely optional and does not unlock any features in the app.',
                              style: TextStyle(
                                height: 1.45,
                                color: _textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (_isMandaliSupport) ...[
                              const SizedBox(height: 16),
                              _supportContextCard(),
                            ],
                            const SizedBox(height: 16),
                            StreamBuilder<int>(
                              stream: RamakotiService.instance
                                  .watchGlobalDevotionCount(),
                              builder: (context, devotionSnapshot) {
                                final globalDevotionTotal =
                                    devotionSnapshot.data ?? globalTotal;

                                return Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: _softAccent,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Global Ram Count',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: _textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _formatIndianNumber(globalTotal),
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w800,
                                          color: _textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      const Text(
                                        'Sri Rama Nama written inside the app only.',
                                        style: TextStyle(
                                          color: _textSecondary,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      const Divider(height: 1),
                                      const SizedBox(height: 14),
                                      const Text(
                                        'Global Devotion Count',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: _textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _formatIndianNumber(
                                          globalDevotionTotal,
                                        ),
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w800,
                                          color: _textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      const Text(
                                        'Includes in-app writing, manual writing, japa, and additional devotional entries.',
                                        style: TextStyle(
                                          color: _textSecondary,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _sectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isMandaliSupport
                                  ? 'Choose a Mandali support amount'
                                  : 'Choose an offering amount',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: _textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _isMandaliSupport
                                  ? 'Tap any amount to continue to secure Mandali support payment.'
                                  : 'Tap any amount to continue to secure support payment.',
                              style: const TextStyle(
                                color: _textSecondary,
                              ),
                            ),
                            const SizedBox(height: 14),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _offerings.length,
                              gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: 2.2,
                              ),
                              itemBuilder: (_, index) {
                                return _offeringTile(_offerings[index]);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _sectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _showAdvanced = !_showAdvanced;
                                });
                              },
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _isMandaliSupport
                                          ? 'Other amount & Mandali support details'
                                          : 'Other amount & optional details',
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        color: _textPrimary,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    _showAdvanced
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                  ),
                                ],
                              ),
                            ),
                            if (_showAdvanced) ...[
                              const SizedBox(height: 16),
                              TextField(
                                controller: _customController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: _isMandaliSupport
                                      ? 'Other Mandali support amount'
                                      : 'Other amount',
                                  prefixText: '₹ ',
                                  border: const OutlineInputBorder(),
                                ),
                                onChanged: (_) {
                                  setState(() {
                                    _selectedAmount = null;
                                  });
                                },
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Name for support wall (optional)',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _messageController,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  labelText: _isMandaliSupport
                                      ? 'Mandali support message (optional)'
                                      : 'Message (optional)',
                                  hintText: 'Jai Shri Ram',
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SwitchListTile(
                                value: _anonymous,
                                onChanged: (value) {
                                  setState(() {
                                    _anonymous = value;
                                  });
                                },
                                contentPadding: EdgeInsets.zero,
                                title: const Text(
                                  'Post anonymously if reviewed',
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _accent,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: _loading
                                      ? null
                                      : () async {
                                    final amount = _selectedValue;
                                    if (amount == null || amount <= 0) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Please enter a valid amount',
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    await _startSupportPayment(amount);
                                  },
                                  child: _loading
                                      ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                      : Text(
                                    _isMandaliSupport
                                        ? 'Pay Mandali Support'
                                        : 'Pay ₹$selectedAmount',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _softGreen,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFD5EEDC),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.lock_outline_rounded,
                              color: _greenText,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _isMandaliSupport
                                    ? 'Payments are processed securely through Razorpay. After successful payment, your Mandali support is recorded automatically.'
                                    : 'Payments are processed securely through Razorpay. After successful payment, your support is recorded automatically.',
                                style: const TextStyle(
                                  height: 1.4,
                                  color: _greenText,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      _buildSupportWallSection(),
                    ],
                  ),
                );
              },
            ),
            if (_showPreparingPaymentOverlay) _buildPreparingPaymentOverlay(),
            if (_showSuccessPopup) _buildSuccessPopup(),
          ],
        ),
      ),
    );
  }
}

class _FlowerParticle {
  final double left;
  final double size;
  final double phase;
  final double sway;
  final double travelDistance;
  final String symbol;

  const _FlowerParticle({
    required this.left,
    required this.size,
    required this.phase,
    required this.sway,
    required this.travelDistance,
    required this.symbol,
  });

  factory _FlowerParticle.random(int seed) {
    final random = Random(seed * 97 + 13);
    const symbols = ['🌸', '🌺', '🌼', '🏵️'];

    return _FlowerParticle(
      left: 10 + random.nextDouble() * 320,
      size: 18 + random.nextDouble() * 12,
      phase: random.nextDouble() * pi,
      sway: 10 + random.nextDouble() * 22,
      travelDistance: 40 + random.nextDouble() * 120,
      symbol: symbols[random.nextInt(symbols.length)],
    );
  }
}