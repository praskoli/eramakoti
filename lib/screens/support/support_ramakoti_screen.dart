import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../services/firebase/donation_service.dart';
import '../../services/firebase/ramakoti_service.dart';
import '../../services/payments/upi_payment_service.dart';

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

  String _buildUpiUrl({required int amount}) {
    final uri = Uri(
      scheme: 'upi',
      host: 'pay',
      queryParameters: {
        'pa': UpiPaymentService.upiId,
        'pn': UpiPaymentService.payeeName,
        'tn': UpiPaymentService.note,
        if (amount > 0) 'am': amount.toString(),
        'cu': 'INR',
      },
    );
    return uri.toString();
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

  Future<void> _startSupportFlow(int amount, {String? source}) async {
    final messenger = ScaffoldMessenger.of(context);

    if (_loading) return;

    setState(() {
      _loading = true;
    });

    try {
      final donationId = await DonationService.instance.createDonation(
        amount: amount,
        source: (source ?? _resolvedSource).trim().isEmpty
            ? _resolvedSource
            : (source ?? _resolvedSource).trim(),
        note: _isMandaliSupport
            ? 'Mandali support offering'
            : 'Support eRamakoti',
        anonymous: _anonymous,
        supporterName: _nameController.text.trim(),
        supporterMessage: _messageController.text.trim(),
        supportType: _supportType,
        sourceMandaliId: widget.sourceMandaliId,
        sourceMandaliName: widget.sourceMandaliName,
        sourceChallengeId: widget.sourceChallengeId,
      );

      await UpiPaymentService.instance.launchPayment(amount: amount);

      await DonationService.instance.markDonationReturned(
        donationId: donationId,
      );

      if (!mounted) return;
      _showRecordedDialog(amount);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not process support: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _showRecordedDialog(int amount) {
    final title = _isMandaliSupport
        ? '🙏 Mandali Support Recorded'
        : '🙏 Offering Recorded';

    final body = _isMandaliSupport
        ? 'Your Mandali support entry for ₹$amount has been created.\n\n'
        'If you completed the payment in the UPI app, the status will be reviewed and updated in Support History.\n\n'
        'Jai Shri Ram.'
        : 'Your offering entry for ₹$amount has been created.\n\n'
        'If you completed the payment in the UPI app, the status will be reviewed and updated in Support History.\n\n'
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
          : () async {
        setState(() {
          _selectedAmount = amount;
          _customController.clear();
        });
        await _startSupportFlow(
          amount,
          source: _isMandaliSupport
              ? 'mandali_preset_amount_tile'
              : 'preset_amount_tile',
        );
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
    final customAmount = _selectedValue ?? 21;
    final qrData = _buildUpiUrl(amount: customAmount);

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
                                  : '🪔 Support this devotional effort',
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
                                  : 'Offerings help maintain this devotional app and support future Ramakoti features.\nPart of donations support Annadanam programs and spiritual education.',
                              style: const TextStyle(
                                height: 1.45,
                                color: _textSecondary,
                              ),
                            ),
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
                                  : 'Choose an offering',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: _textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _isMandaliSupport
                                  ? 'Tap any amount to support this Mandali instantly via UPI.'
                                  : 'Tap any amount to pay instantly via UPI.',
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
                                  });
                                },
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText:
                                  'Name for verified support wall (optional)',
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
                                  'Post anonymously if verified',
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'UPI QR',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: _textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _isMandaliSupport
                                    ? 'Scan to support this Mandali with ₹$customAmount'
                                    : 'Scan to pay ₹$customAmount',
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
                                  'UPI ID: ${UpiPaymentService.upiId}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: _textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Center(
                                child: Text(
                                  'Payee: ${UpiPaymentService.payeeName}',
                                  style: const TextStyle(
                                    color: _textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _accent,
                                  ),
                                  onPressed: _loading
                                      ? null
                                      : () async {
                                    final value = _selectedValue;

                                    if (value == null || value <= 0) {
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

                                    await _startSupportFlow(
                                      value,
                                      source: _isMandaliSupport
                                          ? 'mandali_custom_amount'
                                          : 'custom_amount',
                                    );
                                  },
                                  child: _loading
                                      ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                      : Text(
                                    _isMandaliSupport
                                        ? 'Pay Mandali Support via UPI'
                                        : 'Pay Custom Amount via UPI',
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
                              value: UpiPaymentService.upiId,
                              actionText: 'Copy',
                              onTap: () => _copyText(
                                'UPI ID',
                                UpiPaymentService.upiId,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _infoRow(
                              label: 'Payee',
                              value: UpiPaymentService.payeeName,
                              actionText: 'Copy',
                              onTap: () => _copyText(
                                'Payee name',
                                UpiPaymentService.payeeName,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _infoRow(
                              label: 'Note',
                              value: UpiPaymentService.note,
                              actionText: 'Copy',
                              onTap: () => _copyText(
                                'Note',
                                UpiPaymentService.note,
                              ),
                            ),
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
                                _isMandaliSupport
                                    ? 'After payment, please return to the app. Your Mandali support will appear in Support History and can be tracked separately from individual offerings.'
                                    : 'After payment, please return to the app. Your offering will appear in Support History and move to the Support Wall only after verification.',
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
                              'Verified Support Wall',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: _textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Only verified offerings are shown here.',
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
                                  'No verified support entries yet.',
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