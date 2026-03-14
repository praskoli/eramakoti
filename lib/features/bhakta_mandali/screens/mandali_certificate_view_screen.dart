import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/mandali_certificate_input.dart';
import '../../../services/certificates/mandali_certificate_generator_service.dart';
import '../../../services/certificates/mandali_certificate_share_service.dart';

class MandaliCertificateViewScreen extends StatefulWidget {
  const MandaliCertificateViewScreen({
    super.key,
    required this.mandaliId,
    required this.mandaliName,
    required this.certificateId,
    required this.certificateData,
  });

  final String mandaliId;
  final String mandaliName;
  final String certificateId;
  final Map<String, dynamic> certificateData;

  @override
  State<MandaliCertificateViewScreen> createState() =>
      _MandaliCertificateViewScreenState();
}

class _MandaliCertificateViewScreenState
    extends State<MandaliCertificateViewScreen> {
  static const Color _bgColor = Color(0xFFF8F2E8);
  static const Color _textPrimary = Color(0xFF2F2A25);
  static const Color _textSecondary = Color(0xFF7C7167);
  static const Color _accent = Color(0xFFFF9E2C);
  static const Color _softBorder = Color(0xFFEADFD2);
  static const Color _greenBg = Color(0xFFEAF8EE);
  static const Color _greenText = Color(0xFF217A3C);

  bool _isGenerating = false;
  bool _isDownloading = false;
  bool _isSharing = false;

  DocumentReference<Map<String, dynamic>> get _certificateRef =>
      FirebaseFirestore.instance
          .collection('bhaktaMandalis')
          .doc(widget.mandaliId)
          .collection('certificates')
          .doc(widget.certificateId);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Mandali Certificate',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _certificateRef.snapshots(),
        builder: (context, snapshot) {
          final liveData =
              snapshot.data?.data() ?? Map<String, dynamic>.from(widget.certificateData);

          final challengeName =
          (liveData['challengeName'] ?? 'Mandali Challenge').toString();
          final challengeTarget = _readInt(
            liveData['challengeTarget'] ?? liveData['targetCount'],
          );
          final recipientCount = _readInt(liveData['recipientCount']);
          final storagePath = (liveData['storagePath'] ?? '').toString();
          final downloadUrl = (liveData['downloadUrl'] ?? '').toString();
          final fileName = (liveData['fileName'] ?? '').toString();
          final status = _resolveStatus(
            rawStatus: (liveData['status'] ?? '').toString(),
            storagePath: storagePath,
            downloadUrl: downloadUrl,
          );
          final createdAtText = _formatDate(
            liveData['createdAt'] ?? liveData['completedAt'],
          );
          final generatedAtText = _formatDate(liveData['pdfGeneratedAt']);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _softBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('🙏', style: TextStyle(fontSize: 42)),
                    const SizedBox(height: 10),
                    const Text(
                      'Jai Shri Ram',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: _accent,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'This certifies the completion of the following Mandali challenge',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.5,
                        color: _textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.mandaliName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      challengeName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Target: ${_formatCount(challengeTarget)}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: _textSecondary,
                      ),
                    ),
                    if (recipientCount > 0) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Recipients: ${_formatCount(recipientCount)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: _textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Certificate ID: ${widget.certificateId}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: _textSecondary,
                      ),
                    ),
                    if (createdAtText.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Created: $createdAtText',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: _textSecondary,
                        ),
                      ),
                    ],
                    if (generatedAtText.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'PDF Generated: $generatedAtText',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: _textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: status == 'ready'
                            ? _greenBg
                            : const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        status == 'ready'
                            ? 'Certificate PDF Ready'
                            : 'Certificate PDF Not Generated Yet',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: status == 'ready'
                              ? _greenText
                              : const Color(0xFF9A5A00),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (storagePath.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _softBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PDF Storage Path',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: _textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        storagePath,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: _textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              _buildActionsCard(
                context: context,
                liveData: liveData,
                status: status,
                downloadUrl: downloadUrl,
                fileName: fileName.isNotEmpty
                    ? fileName
                    : '${widget.certificateId}_mandali_certificate.pdf',
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionsCard({
    required BuildContext context,
    required Map<String, dynamic> liveData,
    required String status,
    required String downloadUrl,
    required String fileName,
  }) {
    final ready = status == 'ready';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Actions',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _isGenerating ? null : () => _generateCertificate(liveData),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: _isGenerating
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: Colors.white,
              ),
            )
                : const Icon(Icons.picture_as_pdf_rounded),
            label: Text(
              _isGenerating
                  ? 'Generating PDF...'
                  : ready
                  ? 'Regenerate PDF'
                  : 'Generate PDF',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: (!ready || _isDownloading)
                ? null
                : () => _downloadCertificate(
              downloadUrl: downloadUrl,
              fileName: fileName,
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              side: const BorderSide(color: _softBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: _isDownloading
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            )
                : const Icon(Icons.download_rounded),
            label: Text(
              _isDownloading ? 'Downloading...' : 'Download PDF',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: (!ready || _isSharing)
                ? null
                : () => _shareCertificate(
              downloadUrl: downloadUrl,
              fileName: fileName,
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              side: const BorderSide(color: _softBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: _isSharing
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            )
                : const Icon(Icons.share_rounded),
            label: Text(
              _isSharing ? 'Preparing Share...' : 'Share PDF',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateCertificate(Map<String, dynamic> liveData) async {
    setState(() => _isGenerating = true);

    try {
      final input = MandaliCertificateInput(
        certificateId: widget.certificateId,
        mandaliId: widget.mandaliId,
        mandaliName: widget.mandaliName,
        challengeName:
        (liveData['challengeName'] ?? 'Mandali Challenge').toString(),
        challengeTarget: _readInt(
          liveData['challengeTarget'] ?? liveData['targetCount'],
        ),
        recipientCount: _readInt(liveData['recipientCount']),
        completedAt: _parseDate(
          liveData['completedAt'] ?? liveData['createdAt'],
        ) ??
            DateTime.now(),
      );

      final result = await MandaliCertificateGeneratorService.instance
          .generateAndUploadCertificate(input: input);

      await _certificateRef.set({
        'certificateId': widget.certificateId,
        'mandaliId': widget.mandaliId,
        'mandaliName': widget.mandaliName,
        'challengeName': input.challengeName,
        'challengeTarget': input.challengeTarget,
        'recipientCount': input.recipientCount,
        'storagePath': result.storagePath,
        'downloadUrl': result.downloadUrl,
        'fileName': input.fileName,
        'status': 'ready',
        'pdfGeneratedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (liveData['createdAt'] == null) 'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mandali certificate PDF generated successfully.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate certificate PDF: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _downloadCertificate({
    required String downloadUrl,
    required String fileName,
  }) async {
    if (downloadUrl.trim().isEmpty) return;

    setState(() => _isDownloading = true);

    try {
      final file =
      await MandaliCertificateShareService.instance.downloadToLocalTemp(
        downloadUrl: downloadUrl,
        fileName: fileName,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Certificate downloaded to: ${file.path}'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download certificate: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  Future<void> _shareCertificate({
    required String downloadUrl,
    required String fileName,
  }) async {
    if (downloadUrl.trim().isEmpty) return;

    setState(() => _isSharing = true);

    try {
      final File file =
      await MandaliCertificateShareService.instance.downloadToLocalTemp(
        downloadUrl: downloadUrl,
        fileName: fileName,
      );

      await MandaliCertificateShareService.instance.shareCertificate(file);

      if (!mounted) return;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share certificate: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
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

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '0').toString()) ?? 0;
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

  static String _formatCount(int count) {
    final raw = count.toString();
    final chars = raw.split('').reversed.toList();
    final buffer = StringBuffer();

    for (var i = 0; i < chars.length; i++) {
      if (i > 0 && i % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(chars[i]);
    }

    return buffer.toString().split('').reversed.join();
  }
}