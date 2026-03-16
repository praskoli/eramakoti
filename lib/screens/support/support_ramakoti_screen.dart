import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/support/support_mode_service.dart';
import '../../services/firebase/donation_service.dart';
import '../../services/firebase/ramakoti_service.dart';
import '../../services/payments/upi_payment_service.dart';
import '../../services/temples/support_target_resolver.dart';
import '../../services/temples/temple_context_service.dart';

class SupportRamakotiScreen extends StatefulWidget {
  const SupportRamakotiScreen({
    super.key,
    this.source = 'support_screen',
    this.sourceMandaliId,
    this.sourceMandaliName,
    this.sourceChallengeId,
    this.forcePlatformSupport = false,
  });
  final String source;
  final String? sourceMandaliId;
  final String? sourceMandaliName;
  final String? sourceChallengeId;
  final bool forcePlatformSupport;
  @override
  State<SupportRamakotiScreen> createState() => _SupportRamakotiScreenState();
}

class _SupportRamakotiScreenState extends State<SupportRamakotiScreen> {
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

  final List<int> _offerings = [11, 21, 51, 101, 501, 1001];

  int? _selectedAmount;
  final TextEditingController _customController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  bool _loading = false;
  bool _anonymous = false;
  bool _showAdvanced = false;

  String? _currentDonationId;
  String? _currentTransactionRef;

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

  String _paymentNote(SupportTarget target) {
    if (_isMandaliSupport) {
      return 'Mandali Support via ${target.label}';
    }
    return 'Support ${target.label}';
  }

  String _buildUpiUrl({
    required int amount,
    required SupportTarget target,
  }) {
    return UpiPaymentService.instance.buildUpiUrl(
      amount: amount,
      transactionNote: _paymentNote(target),
      includeNote: true,
      upiId: target.upiId,
      payeeName: target.payeeName,
    );
  }

  String _formatDate(dynamic value) {
    DateTime? date;
    if (value is Timestamp) date = value.toDate();
    if (value is String) date = DateTime.tryParse(value);
    if (date == null) return '—';
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  Future<void> _copyText(String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied')),
    );
  }

  String _friendlyError(Object e) {
    final text = e.toString().toLowerCase();

    if (text.contains('permission-denied')) {
      return 'Permission denied while saving support details';
    }
    if (text.contains('network')) {
      return 'Network issue. Please check your internet and try again';
    }
    if (text.contains('unavailable')) {
      return 'Service temporarily unavailable. Please try again';
    }
    return e.toString();
  }

  Future<void> _ensurePaymentAttempt({
    required int amount,
    required String source,
    required SupportTarget target,
  }) async {
    if (_currentDonationId != null && _currentTransactionRef != null) return;

    final transactionRef =
        'ERK${DateTime.now().millisecondsSinceEpoch}${amount.toString()}';

    final donationId = await DonationService.instance.createDonation(
      amount: amount,
      source: source.trim().isEmpty ? _resolvedSource : source.trim(),
      note: _paymentNote(target),
      anonymous: _anonymous,
      supporterName: _nameController.text.trim(),
      supporterMessage: _messageController.text.trim(),
      supportType: _supportType,
      sourceMandaliId: widget.sourceMandaliId,
      sourceMandaliName: widget.sourceMandaliName,
      sourceChallengeId: widget.sourceChallengeId,
      transactionRef: transactionRef,
      paymentMethod: 'upi',
      paymentStatus: 'initiated',
      upiUrl: _buildUpiUrl(amount: amount, target: target),
    );

    _currentDonationId = donationId;
    _currentTransactionRef = transactionRef;
  }

  Future<void> _openUpiApp(int amount, SupportTarget target) async {
    final messenger = ScaffoldMessenger.of(context);

    if (_loading) return;
    if (amount <= 0) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await _ensurePaymentAttempt(
        amount: amount,
        source: _isMandaliSupport
            ? 'mandali_qr_payment_initiated'
            : 'upi_app_launch_initiated',
        target: target,
      );

      final ref = _currentTransactionRef!;
      final donationId = _currentDonationId!;

      final launched = await UpiPaymentService.instance.launchUpiPayment(
        amount: amount,
        transactionNote: _paymentNote(target),
        includeNote: true,
        upiId: target.upiId,
        payeeName: target.payeeName,
      );

      if (launched) {
        await DonationService.instance.updateDonationStatus(
          donationId: donationId,
          status: 'initiated',
          source: _isMandaliSupport
              ? 'mandali_upi_app_opened'
              : 'upi_app_opened',
          transactionRef: ref,
          paymentMethod: 'upi',
          upiUrl: _buildUpiUrl(amount: amount, target: target),
        );

        if (!mounted) return;
        _showReturnedFromUpiDialog(amount);
      } else {
        await DonationService.instance.updateDonationStatus(
          donationId: donationId,
          status: 'initiated',
          source: _isMandaliSupport
              ? 'mandali_upi_launch_failed'
              : 'upi_launch_failed',
          transactionRef: ref,
          paymentMethod: 'upi',
        );

        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Could not open UPI app. Please use QR instead.'),
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not open UPI payment: ${_friendlyError(e)}'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _confirmPayment(int amount, SupportTarget target) async {
    final messenger = ScaffoldMessenger.of(context);

    if (_loading) return;
    if (amount <= 0) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await _ensurePaymentAttempt(
        amount: amount,
        source: _isMandaliSupport
            ? 'mandali_qr_payment_initiated'
            : 'qr_payment_initiated',
        target: target,
      );

      await DonationService.instance.markUserConfirmedPayment(
        donationId: _currentDonationId!,
        source: _isMandaliSupport
            ? 'mandali_qr_payment_confirmed'
            : 'qr_payment_confirmed',
      );

      if (!mounted) return;
      _showRecordedDialog(amount);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not record support entry: ${_friendlyError(e)}'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showReturnedFromUpiDialog(int amount) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text('UPI App Opened'),
          content: Text(
            'Your UPI app was opened for ₹$amount.\n\n'
                'After completing payment there, come back and tap "I Have Paid".\n\n'
                'If you did not complete payment, you can simply close this and try again.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showRecordedDialog(int amount) {
    final title = _isMandaliSupport
        ? '🙏 Mandali Support Recorded'
        : '🙏 Offering Recorded';

    final body = _isMandaliSupport
        ? 'Your Mandali support entry for ₹$amount has been recorded.\n\n'
        'Its status is now marked for review in Support History.\n\n'
        'Jai Shri Ram.'
        : 'Your offering entry for ₹$amount has been recorded.\n\n'
        'Its status is now marked for review in Support History.\n\n'
        'Jai Shri Ram.';

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Stay Here'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
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
          : () {
        setState(() {
          _selectedAmount = amount;
          _customController.clear();
          _currentDonationId = null;
          _currentTransactionRef = null;
        });
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

  Widget _infoRow({
    required String label,
    required String value,
    required String actionText,
    required VoidCallback onTap,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '$label: $value',
            style: const TextStyle(
              color: _textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextButton(
          onPressed: onTap,
          child: Text(actionText),
        ),
      ],
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

  @override
  void dispose() {
    _customController.dispose();
    _nameController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final templeContext = context.watch<TempleContextService>();

    final support = SupportModeService.resolve(
      templeContext: templeContext,
      mandaliName: widget.sourceMandaliName,
      forcePlatform: widget.forcePlatformSupport,
    );

    final currentTemple = templeContext.currentTemple;

    final target = (support.mode == SupportMode.temple && currentTemple != null)
        ? SupportTarget(
      upiId: currentTemple.upiId,
      payeeName: currentTemple.payeeName,
      label: currentTemple.name,
    )
        : SupportTarget(
      upiId: UpiPaymentService.defaultUpiId,
      payeeName: UpiPaymentService.defaultPayeeName,
      label: support.label,
    );

    final selectedAmount = _selectedValue ?? 21;
    final qrData = _buildUpiUrl(
      amount: selectedAmount,
      target: target,
    );

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(_isMandaliSupport ? 'Mandali Support' : 'Offer Support'),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: StreamBuilder<int>(
          stream: RamakotiService.instance.watchGlobalRamCount(),
          builder: (context, globalSnapshot) {
            final globalTotal = globalSnapshot.data ?? 0;

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: DonationService.instance.watchSupportWall(limit: 8),
              builder: (context, wallSnapshot) {
                final wallDocs = wallSnapshot.data?.docs ?? const [];

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
                                  : (support.mode == SupportMode.temple
                                  ? '🪔 Offer Support to ${target.label}'
                                  : '🪔 Offer Support to eRamakoti'),
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
                                  : (support.mode == SupportMode.temple
                                  ? 'Your voluntary contribution goes to ${target.label} using its configured temple UPI details.'
                                  : 'Your voluntary contribution helps maintain this devotional platform and support future spiritual initiatives.'),
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
                            if (support.mode == SupportMode.temple &&
                                !_isMandaliSupport) ...[
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: _softBlue,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFD9E7FF),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(
                                          Icons.account_balance_rounded,
                                          color: _blueText,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Temple Support Mode',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: _blueText,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      target.label,
                                      style: const TextStyle(
                                        color: _textPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Support on this screen is currently configured to use temple-specific UPI details.',
                                      style: const TextStyle(
                                        color: _textSecondary,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (_isMandaliSupport) ...[
                              const SizedBox(height: 16),
                              _supportContextCard(),
                            ],
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: _softAccent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                    globalTotal.toString(),
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: _textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Jai Shri Ram written across devotees',
                                    style: TextStyle(color: _textSecondary),
                                  ),
                                ],
                              ),
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
                            const Text(
                              'Select an amount and pay using QR or UPI app.',
                              style: TextStyle(
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
                                          ? 'Other amount, QR & Mandali support details'
                                          : 'Other amount, QR & optional details',
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
                                    _currentDonationId = null;
                                    _currentTransactionRef = null;
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
                                    _currentDonationId = null;
                                    _currentTransactionRef = null;
                                  });
                                },
                                contentPadding: EdgeInsets.zero,
                                title: const Text(
                                  'Post anonymously if reviewed',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _sectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Scan QR to pay',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: _textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isMandaliSupport
                                  ? 'Scan to support this Mandali with ₹$selectedAmount'
                                  : (support.mode == SupportMode.temple
                                  ? 'Scan to support ${target.label} with ₹$selectedAmount'
                                  : 'Scan to pay ₹$selectedAmount'),
                              style: const TextStyle(color: _textSecondary),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: _border),
                                ),
                                child: QrImageView(
                                  data: qrData,
                                  version: QrVersions.auto,
                                  size: 220,
                                  backgroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: Text(
                                'UPI ID: ${target.upiId}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: _textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: Text(
                                'Payee: ${target.payeeName}',
                                style: const TextStyle(
                                  color: _textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: OutlinedButton.icon(
                                onPressed: _loading
                                    ? null
                                    : () => _openUpiApp(selectedAmount, target),
                                icon: const Icon(Icons.open_in_new_rounded),
                                label: const Text(
                                  'Open UPI App',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
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
                                    : () => _confirmPayment(selectedAmount, target),
                                child: _loading
                                    ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                                    : Text(
                                  _isMandaliSupport
                                      ? 'I Have Paid Mandali Support'
                                      : 'I Have Paid',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _sectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'UPI details',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: _textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _infoRow(
                              label: 'UPI ID',
                              value: target.upiId,
                              actionText: 'Copy',
                              onTap: () => _copyText(
                                'UPI ID',
                                target.upiId,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _infoRow(
                              label: 'Payee',
                              value: target.payeeName,
                              actionText: 'Copy',
                              onTap: () => _copyText(
                                'Payee',
                                target.payeeName,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _infoRow(
                              label: 'Amount',
                              value: '₹$selectedAmount',
                              actionText: 'Copy',
                              onTap: () => _copyText(
                                'Amount',
                                selectedAmount.toString(),
                              ),
                            ),
                            const SizedBox(height: 10),
                            _infoRow(
                              label: 'Note',
                              value: _paymentNote(target),
                              actionText: 'Copy',
                              onTap: () => _copyText(
                                'Note',
                                _paymentNote(target),
                              ),
                            ),
                            if ((_currentTransactionRef ?? '').isNotEmpty) ...[
                              const SizedBox(height: 10),
                              _infoRow(
                                label: 'Reference',
                                value: _currentTransactionRef!,
                                actionText: 'Copy',
                                onTap: () => _copyText(
                                  'Reference',
                                  _currentTransactionRef!,
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
                              Icons.info_outline,
                              color: _greenText,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Payments are processed through your UPI app. This app does not store or process payment information.\n\n'
                                    'For better tracking, first tap "Open UPI App" or scan the QR, then after payment return and tap "I Have Paid".',
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
                      _sectionCard(
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
                            if (wallSnapshot.connectionState ==
                                ConnectionState.waiting &&
                                wallDocs.isEmpty)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else if (wallDocs.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'No support entries yet.',
                                  style: TextStyle(color: _textSecondary),
                                ),
                              )
                            else
                              ...wallDocs.map((doc) {
                                final data = doc.data();
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: _softAccent,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              (data['name'] ?? 'Devotee')
                                                  .toString(),
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
                                      if ((data['message'] ?? '')
                                          .toString()
                                          .trim()
                                          .isNotEmpty)
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
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
