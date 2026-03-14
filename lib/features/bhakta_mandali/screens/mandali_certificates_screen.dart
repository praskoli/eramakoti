import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'mandali_certificate_view_screen.dart';

class MandaliCertificatesScreen extends StatelessWidget {
  const MandaliCertificatesScreen({
    super.key,
    required this.mandaliId,
    required this.mandaliName,
  });

  final String mandaliId;
  final String mandaliName;

  static const Color _bgColor = Color(0xFFF8F2E8);
  static const Color _textPrimary = Color(0xFF2F2A25);
  static const Color _textSecondary = Color(0xFF7C7167);
  static const Color _accent = Color(0xFFFF9E2C);
  static const Color _softBorder = Color(0xFFEADFD2);
  static const Color _successBg = Color(0xFFEAF8EE);
  static const Color _successText = Color(0xFF217A3C);
  static const Color _pendingBg = Color(0xFFFFF3E0);
  static const Color _pendingText = Color(0xFF9A5A00);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          '$mandaliName Certificates',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('bhaktaMandalis')
            .doc(mandaliId)
            .collection('certificates')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Failed to load certificates.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? const [];

          if (docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No Mandali certificates yet. Certificates appear after a challenge is completed.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final challengeName =
              (data['challengeName'] ?? 'Mandali Challenge').toString();
              final certificateId =
              (data['certificateId'] ?? docs[index].id).toString();
              final recipientCount =
                  (data['recipientCount'] as num?)?.toInt() ?? 0;
              final storagePath = (data['storagePath'] ?? '').toString();
              final downloadUrl = (data['downloadUrl'] ?? '').toString();
              final status = (data['status'] ?? '').toString().trim();
              final createdAt = _formatDate(data['createdAt']);
              final effectiveStatus = _resolveStatus(
                rawStatus: status,
                storagePath: storagePath,
                downloadUrl: downloadUrl,
              );

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MandaliCertificateViewScreen(
                          mandaliId: mandaliId,
                          mandaliName: mandaliName,
                          certificateId: certificateId,
                          certificateData: data,
                        ),
                      ),
                    );
                  },
                  child: Ink(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _softBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                challengeName,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: _textPrimary,
                                ),
                              ),
                            ),
                            _StatusChip(
                              label: effectiveStatus == 'ready'
                                  ? 'PDF Ready'
                                  : 'Pending',
                              backgroundColor: effectiveStatus == 'ready'
                                  ? _successBg
                                  : _pendingBg,
                              textColor: effectiveStatus == 'ready'
                                  ? _successText
                                  : _pendingText,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Certificate ID: $certificateId',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: _textSecondary,
                          ),
                        ),
                        if (recipientCount > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Recipients: $recipientCount',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: _textSecondary,
                            ),
                          ),
                        ],
                        if (createdAt.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Created: $createdAt',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: _textSecondary,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          effectiveStatus == 'ready'
                              ? 'Tap to download or share the generated PDF.'
                              : 'Tap to generate the certificate PDF.',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: _accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  static String _resolveStatus({
    required String rawStatus,
    required String storagePath,
    required String downloadUrl,
  }) {
    if (storagePath.isNotEmpty || downloadUrl.isNotEmpty) {
      return 'ready';
    }

    if (rawStatus.toLowerCase() == 'ready') {
      return 'ready';
    }

    return 'pending';
  }

  static String _formatDate(dynamic value) {
    final date = _parseDate(value);
    if (date == null) return '';
    return DateFormat('dd MMM yyyy, hh:mm a').format(date.toLocal());
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value)?.toLocal();
    }

    return null;
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
      ),
    );
  }
}