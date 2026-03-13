import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/ramakoti_meta.dart';
import '../../models/ramakoti_run.dart';
import '../../services/auth/auth_service.dart';
import '../../services/certificates/certificate_generator_service.dart';
import '../../services/certificates/certificate_share_service.dart';
import '../../services/firebase/ramakoti_service.dart';
import '../../screens/ramakoti/ramakoti_writer_screen.dart';
import '../../screens/support/support_ramakoti_screen.dart';

class RamakotiHistoryDetailScreen extends StatelessWidget {
  const RamakotiHistoryDetailScreen({super.key});

  static const Color _bgColor = Color(0xFFF8F2E8);
  static const Color _cardColor = Colors.white;
  static const Color _textPrimary = Color(0xFF2F2A25);
  static const Color _textSecondary = Color(0xFF7C7167);
  static const Color _accent = Color(0xFFFF9E2C);
  static const Color _softAccent = Color(0xFFFFF1DE);
  static const Color _softBorder = Color(0xFFEADFD2);
  static const Color _greenBg = Color(0xFFEAF8EE);
  static const Color _greenText = Color(0xFF2F8F4E);
  static const Color _blueBg = Color(0xFFEAF2FF);
  static const Color _blueText = Color(0xFF2D5BBA);

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No authenticated user')),
      );
    }

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text('Ramakoti History'),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: StreamBuilder<RamakotiMeta>(
        stream: RamakotiService.instance.watchSummary(user.uid),
        builder: (context, metaSnapshot) {
          final meta = metaSnapshot.data ?? RamakotiMeta.empty(user.uid);

          return StreamBuilder<List<RamakotiRun>>(
            stream: RamakotiService.instance.watchRuns(user.uid),
            builder: (context, runsSnapshot) {
              if (runsSnapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Could not load Ramakoti history.\n${runsSnapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              if (runsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final runs = runsSnapshot.data ?? const <RamakotiRun>[];

              if (runs.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No Ramakoti history yet.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: runs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final run = runs[index];
                  final isCurrentRun = meta.currentRunId.trim().isNotEmpty &&
                      meta.currentRunId == run.runId;

                  return _RunHistoryCard(
                    run: run,
                    isCurrentRun: isCurrentRun,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _RunHistoryCard extends StatefulWidget {
  final RamakotiRun run;
  final bool isCurrentRun;

  const _RunHistoryCard({
    required this.run,
    required this.isCurrentRun,
  });

  @override
  State<_RunHistoryCard> createState() => _RunHistoryCardState();
}

class _RunHistoryCardState extends State<_RunHistoryCard> {
  bool _isGenerating = false;
  bool _certificateReady = false;
  File? _generatedFile;
  Map<String, dynamic>? _certificateMeta;

  @override
  void initState() {
    super.initState();
    _loadCertificateState();
  }

  Future<void> _loadCertificateState() async {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null || !widget.run.isCompleted) return;

    final meta = await RamakotiService.instance.getCertificateMetadata(
      uid: uid,
      runId: widget.run.runId,
    );

    if (!mounted) return;

    setState(() {
      _certificateMeta = meta;
      _certificateReady =
          meta != null &&
              (meta['downloadUrl'] ?? '').toString().trim().isNotEmpty;
    });
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

  String _targetLabel(int targetCount) {
    if (targetCount <= 0) return 'Not selected';
    if (targetCount == 10) return '10';
    if (targetCount == 108) return '108';
    if (targetCount == 1000) return '1,000';
    if (targetCount == 10000) return '10,000';
    if (targetCount == 100000) return '1 Lakh';
    if (targetCount == 1000000) return '10 Lakh';
    if (targetCount == 10000000) return '1 Crore';
    return _formatIndianNumber(targetCount);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  void _showProgressDialog({
    required BuildContext context,
    required int step,
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        String label = 'Preparing certificate';
        if (step == 2) label = 'Uploading to secure storage';
        if (step == 3) label = 'Finalizing certificate';

        return AlertDialog(
          title: const Text('Generating Certificate'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 18),
              Text('Step $step/3'),
              const SizedBox(height: 8),
              Text(label, textAlign: TextAlign.center),
            ],
          ),
        );
      },
    );
  }

  Future<void> _generateCertificate() async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() {
      _isGenerating = true;
    });

    try {
      _showProgressDialog(context: context, step: 1);

      final devoteeName = (user.displayName ?? '').trim().isEmpty
          ? 'Devotee'
          : user.displayName!.trim();

      final completedCount = widget.run.finalRunCount > 0
          ? widget.run.finalRunCount
          : widget.run.currentRunCount;

      final completedAt = widget.run.completedAt ?? DateTime.now();

      const String certificateLanguage = 'english';

      final input = await RamakotiService.instance.getOrCreateCertificateInput(
        uid: user.uid,
        runId: widget.run.runId,
        devoteeName: devoteeName,
        completedCount: completedCount,
        completedAt: completedAt,
        certificateLanguage: certificateLanguage,
      );

      navigator.pop();

      _showProgressDialog(context: context, step: 2);

      final result =
      await CertificateGeneratorService.instance.generateAndUploadCertificate(
        input: input,
      );

      navigator.pop();

      _showProgressDialog(context: context, step: 3);

      await RamakotiService.instance.saveCertificateMetadata(
        uid: user.uid,
        runId: widget.run.runId,
        certificateId: input.certificateId,
        devoteeName: input.devoteeName,
        completedCount: input.completedCount,
        completedAt: input.completedAt,
        certificateLanguage: input.certificateLanguage,
        storagePath: result.storagePath,
        downloadUrl: result.downloadUrl,
      );

      navigator.pop();

      final refreshedMeta =
      await RamakotiService.instance.getCertificateMetadata(
        uid: user.uid,
        runId: widget.run.runId,
      );

      if (!mounted) return;

      setState(() {
        _generatedFile = result.file;
        _certificateReady = true;
        _certificateMeta = refreshedMeta;
      });

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Certificate generated successfully.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Certificate generation failed: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _downloadOrShareCertificate() async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      if (_generatedFile != null && await _generatedFile!.exists()) {
        await CertificateShareService.instance.shareCertificate(_generatedFile!);
        return;
      }

      final downloadUrl = (_certificateMeta?['downloadUrl'] ?? '').toString();
      final fileName = (_certificateMeta?['fileName'] ?? '').toString();

      if (downloadUrl.isEmpty || fileName.isEmpty) {
        throw Exception('Certificate file details are missing');
      }

      final downloadedFile =
      await CertificateShareService.instance.downloadToLocalTemp(
        downloadUrl: downloadUrl,
        fileName: fileName,
      );

      if (!mounted) return;

      setState(() {
        _generatedFile = downloadedFile;
      });

      await CertificateShareService.instance.shareCertificate(downloadedFile);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not download/share certificate: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final run = widget.run;
    final progressValue = run.targetProgressPercent;
    final writtenValue =
    run.finalRunCount > 0 ? run.finalRunCount : run.currentRunCount;

    return Container(
      decoration: BoxDecoration(
        color: RamakotiHistoryDetailScreen._cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: RamakotiHistoryDetailScreen._softBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: run.isCompleted
                        ? RamakotiHistoryDetailScreen._greenBg
                        : RamakotiHistoryDetailScreen._blueBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    run.statusLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: run.isCompleted
                          ? RamakotiHistoryDetailScreen._greenText
                          : RamakotiHistoryDetailScreen._blueText,
                    ),
                  ),
                ),
                if (widget.isCurrentRun)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: RamakotiHistoryDetailScreen._softAccent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Current Run',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: RamakotiHistoryDetailScreen._accent,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              run.language.trim().isEmpty ? 'Ramakoti Journey' : run.language,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: RamakotiHistoryDetailScreen._textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              run.runId.trim().isEmpty ? 'Run ID unavailable' : run.runId,
              style: const TextStyle(
                fontSize: 12,
                color: RamakotiHistoryDetailScreen._textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            _InfoRow(label: 'Target', value: _targetLabel(run.targetCount)),
            const SizedBox(height: 10),
            _InfoRow(label: 'Written', value: _formatIndianNumber(writtenValue)),
            const SizedBox(height: 10),
            _InfoRow(
              label: 'Completed Batches',
              value: run.completedBatchCount.toString(),
            ),
            const SizedBox(height: 10),
            _InfoRow(label: 'Started', value: _formatDate(run.startedAt)),
            const SizedBox(height: 10),
            _InfoRow(label: 'Last Written', value: _formatDate(run.lastWrittenAt)),
            if (run.isCompleted) ...[
              const SizedBox(height: 10),
              _InfoRow(label: 'Completed On', value: _formatDate(run.completedAt)),
            ],
            const SizedBox(height: 16),
            const Text(
              'Progress',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: RamakotiHistoryDetailScreen._textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progressValue,
                minHeight: 10,
                backgroundColor: const Color(0xFFF0E7DB),
                valueColor: const AlwaysStoppedAnimation(
                  RamakotiHistoryDetailScreen._accent,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_formatIndianNumber(run.currentRunCount)} / ${_targetLabel(run.targetCount)}',
              style: const TextStyle(
                fontSize: 13,
                color: RamakotiHistoryDetailScreen._textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (run.isActive)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final uid = AuthService.instance.currentUser?.uid;
                        if (uid == null) return;

                        final navigator = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);

                        try {
                          await RamakotiService.instance.activateRun(
                            uid: uid,
                            run: run,
                          );

                          await navigator.push(
                            MaterialPageRoute(
                              builder: (_) => const RamakotiWriterScreen(),
                            ),
                          );
                        } catch (e) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Could not continue this run: $e'),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: RamakotiHistoryDetailScreen._accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size(0, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                if (run.isActive) const SizedBox(width: 10),
                if (run.isCompleted) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isGenerating
                          ? null
                          : (_certificateReady
                          ? _downloadOrShareCertificate
                          : _generateCertificate),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _isGenerating
                            ? 'Generating...'
                            : (_certificateReady
                            ? 'Download Certificate'
                            : 'Get Certificate'),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SupportRamakotiScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: RamakotiHistoryDetailScreen._accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size(0, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Offer Support',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
                if (!run.isActive && !run.isCompleted)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: null,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'In Progress',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: RamakotiHistoryDetailScreen._textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: RamakotiHistoryDetailScreen._textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}