import 'dart:math' as math;
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../../../models/bhakta_mandali.dart';
import '../../../models/mandali_writer_state.dart';
import '../../../models/user_mandali_membership.dart';
import '../../../screens/support/support_ramakoti_screen.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/firebase/bhakta_mandali_service.dart';
import '../../../services/firebase/mandali_writer_service.dart';

class MandaliWriterScreen extends StatefulWidget {
  const MandaliWriterScreen({super.key, required this.mandaliId});

  final String mandaliId;

  @override
  State<MandaliWriterScreen> createState() => _MandaliWriterScreenState();
}

class _MandaliWriterScreenState extends State<MandaliWriterScreen> {
  static const Color _bgColor = Color(0xFFF6EEDD);
  static const Color _accent = Color(0xFFFF9E2C);
  static const Color _gridFilled = Color(0xFFF3DFBE);
  static const Color _gridEmpty = Color(0xFFF8F1E8);
  static const Color _progressBg = Color(0xFFE7DFF1);
  static const Color _borderColor = Color(0xFFD8D2C8);
  static const Color _textPrimary = Color(0xFF2F2A25);
  static const Color _textSecondary = Color(0xFF6F6256);
  static const Color _completedBg = Color(0xFFEAF8EE);
  static const Color _completedText = Color(0xFF2F8F4E);

  final AudioPlayer _writePlayer = AudioPlayer();
  final AudioPlayer _celebrationPlayer = AudioPlayer();
  late final ConfettiController _confettiController;

  late final Stream<BhaktaMandali?> _mandaliStream;
  late final Stream<MandaliWriterState?> _writerStateStream;
  late final Stream<List<UserMandaliMembership>> _membershipsStream;

  bool _isWriting = false;

  BhaktaMandali? _latestMandali;
  MandaliWriterState? _latestWriterState;

  Color _selectedInkColor = const Color(0xFF1A237E);
  _PaperStyle _selectedPaperStyle = _PaperStyle.cleanWhite;
  bool _handwritingMode = true;
  bool _showWritingExperienceOptions = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 1800),
    );

    final normalizedMandaliId = widget.mandaliId.trim();
    final user = AuthService.instance.currentUser;

    _mandaliStream =
    normalizedMandaliId.isEmpty
        ? Stream<BhaktaMandali?>.value(null)
        : BhaktaMandaliService.instance.watchMandali(normalizedMandaliId);

    if (user != null) {
      _writerStateStream = MandaliWriterService.instance.watchWriterState(
        mandaliId: widget.mandaliId,
        uid: user.uid,
      );
      _membershipsStream =
          BhaktaMandaliService.instance.watchMyMandalis(user.uid);
    }
  }

  @override
  void dispose() {
    _writePlayer.dispose();
    _celebrationPlayer.dispose();
    _confettiController.dispose();
    super.dispose();
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

  Future<void> _playWriteTone() async {
    try {
      await _writePlayer.stop();
      await _writePlayer.play(AssetSource('audio/jaisriramtone.mp3'));
    } catch (_) {}
  }

  Future<void> _playTempleBell() async {
    try {
      await _celebrationPlayer.stop();
      await _celebrationPlayer.play(AssetSource('audio/temple_bell.mp3'));
    } catch (_) {}
  }

  Future<void> _handleWrite() async {
    final user = AuthService.instance.currentUser;
    if (user == null || _isWriting) return;

    final mandali = _latestMandali;
    final writerState = _latestWriterState;

    if (mandali == null || writerState == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mandali details are not loaded yet.')),
      );
      return;
    }

    if (writerState.challengeStatus.trim().toLowerCase() == 'completed') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This Mandali challenge has already been completed.',
          ),
        ),
      );
      return;
    }

    setState(() => _isWriting = true);

    try {
      await _playWriteTone();

      final result = await MandaliWriterService.instance.writeForMandali(
        mandaliId: mandali.mandaliId,
        challengeId: writerState.challengeId,
      );

      if (result.batchCompleted && mounted) {
        await _playTempleBell();
      }

      if (result.challengeCompleted && mounted) {
        _confettiController.play();
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Jai Shri Ram'),
            content: Text(
              '${mandali.displayName} completed the challenge '
                  '"${mandali.activeChallenge?.title ?? 'Mandali Challenge'}". '
                  'Mandali certificates can now be generated for all members who contributed at least once.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Continue'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Write failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isWriting = false);
      }
    }
  }

  Widget _buildWritingExperienceCard() {
    const inkOptions = <_InkOption>[
      _InkOption('Blue', Color(0xFF1A237E)),
      _InkOption('Black', Color(0xFF000000)),
      _InkOption('Saffron', Color(0xFFFF8F00)),
      _InkOption('Maroon', Color(0xFF800000)),
      _InkOption('Green', Color(0xFF2E7D32)),
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _borderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              setState(() {
                _showWritingExperienceOptions = !_showWritingExperienceOptions;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.brush_rounded,
                    size: 18,
                    color: _accent,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Writing Experience',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1DE),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _showWritingExperienceOptions ? 'Hide' : 'Customize',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _showWritingExperienceOptions
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: _textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (_showWritingExperienceOptions) ...[
            const Divider(height: 1, color: _borderColor),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ink Color',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: _textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: inkOptions.map((option) {
                      final selected =
                          _selectedInkColor.value == option.color.value;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedInkColor = option.color;
                          });
                        },
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? option.color.withOpacity(0.10)
                                : const Color(0xFFF8F1E8),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: selected ? option.color : _borderColor,
                              width: selected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: option.color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.black.withOpacity(0.08),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                option.label,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: _textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Paper Style',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: _textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _PaperStyle.values.map((style) {
                      final selected = _selectedPaperStyle == style;
                      return ChoiceChip(
                        label: Text(style.label),
                        selected: selected,
                        onSelected: (_) {
                          setState(() {
                            _selectedPaperStyle = style;
                          });
                        },
                        selectedColor: const Color(0xFFFFF1DE),
                        backgroundColor: const Color(0xFFF8F1E8),
                        labelStyle: TextStyle(
                          fontSize: 11.5,
                          fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                          color: _textPrimary,
                        ),
                        side: BorderSide(
                          color: selected ? _accent : _borderColor,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: _handwritingMode,
                    onChanged: (value) {
                      setState(() {
                        _handwritingMode = value;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    activeColor: _accent,
                    title: const Text(
                      'Handwriting Style',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                    subtitle: const Text(
                      'Natural handwritten feel for the current writing',
                      style: TextStyle(
                        fontSize: 11,
                        color: _textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final normalizedMandaliId = widget.mandaliId.trim();
    if (normalizedMandaliId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Invalid Mandali reference')),
      );
    }

    final user = AuthService.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No authenticated user')),
      );
    }

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Mandali Writer',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Stack(
        children: [
          StreamBuilder<BhaktaMandali?>(
            stream: _mandaliStream,
            initialData: _latestMandali,
            builder: (context, mandaliSnapshot) {
              if (mandaliSnapshot.hasError && mandaliSnapshot.data == null) {
                return Center(
                  child: Text(
                    'Failed to load Mandali.\n${mandaliSnapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                );
              }

              if (mandaliSnapshot.connectionState == ConnectionState.waiting &&
                  mandaliSnapshot.data == null) {
                return const Center(child: CircularProgressIndicator());
              }

              final mandali = mandaliSnapshot.data;
              if (mandali == null) {
                return const Center(child: Text('Mandali not found.'));
              }
              _latestMandali = mandali;

              return StreamBuilder<List<UserMandaliMembership>>(
                stream: _membershipsStream,
                builder: (context, membershipSnapshot) {
                  if (membershipSnapshot.hasError &&
                      (membershipSnapshot.data == null ||
                          membershipSnapshot.data!.isEmpty)) {
                    return Center(
                      child: Text(
                        'Failed to load your Mandali membership.\n${membershipSnapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  if (membershipSnapshot.connectionState ==
                      ConnectionState.waiting &&
                      membershipSnapshot.data == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final memberships =
                      membershipSnapshot.data ?? const <UserMandaliMembership>[];

                  final membership = memberships
                      .where(
                        (m) =>
                    m.mandaliId == widget.mandaliId &&
                        m.status.trim().toLowerCase() == 'active',
                  )
                      .cast<UserMandaliMembership?>()
                      .firstWhere((m) => m != null, orElse: () => null);

                  if (membership == null) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'You are not an active member of this Mandali.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  return StreamBuilder<MandaliWriterState?>(
                    stream: _writerStateStream,
                    initialData: _latestWriterState,
                    builder: (context, stateSnapshot) {
                      if (stateSnapshot.hasError && stateSnapshot.data == null) {
                        return Center(
                          child: Text(
                            'Failed to load writer state.\n${stateSnapshot.error}',
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      if (stateSnapshot.connectionState ==
                          ConnectionState.waiting &&
                          stateSnapshot.data == null) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final state = stateSnapshot.data;
                      if (state == null) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'No active challenge found for this Mandali.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }

                      _latestWriterState = state;

                      final isCompleted =
                          state.challengeStatus.trim().toLowerCase() ==
                              'completed';

                      return SafeArea(
                        bottom: false,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 460),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Writing for ${state.mandaliName}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: _accent,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Challenge: ${state.challengeName.isEmpty ? 'Mandali Challenge' : state.challengeName}  •  Grid ${state.currentBatchNumber}  •  Your Count ${_formatIndianNumber(state.userContribution)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      height: 1.35,
                                      color: _textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  _TopSummaryCard(
                                    mandaliTotal:
                                    _formatIndianNumber(state.mandaliTotal),
                                    yourContribution: _formatIndianNumber(
                                      state.userContribution,
                                    ),
                                    challengeTitle: state.challengeName,
                                  ),
                                  const SizedBox(height: 12),
                                  if (isCompleted)
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: _completedBg,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: const Color(0xFFD5EEDC),
                                        ),
                                      ),
                                      child: const Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Challenge Completed',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: _completedText,
                                            ),
                                          ),
                                          SizedBox(height: 6),
                                          Text(
                                            'This Mandali has already reached its target. You can view certificates or offer support.',
                                            style: TextStyle(
                                              color: _completedText,
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (isCompleted) const SizedBox(height: 12),
                                  const Text(
                                    'Challenge Progress',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: _textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: LinearProgressIndicator(
                                      value: state.challengeProgressPercent,
                                      minHeight: 8,
                                      backgroundColor: _progressBg,
                                      valueColor: const AlwaysStoppedAnimation(
                                        _accent,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    '${_formatIndianNumber(state.challengeProgress)} / ${_formatIndianNumber(state.challengeTarget)}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: _textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Your 108 Grid Progress',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: _textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: LinearProgressIndicator(
                                      value: state.batchProgressPercent,
                                      minHeight: 8,
                                      backgroundColor: _progressBg,
                                      valueColor: const AlwaysStoppedAnimation(
                                        Color(0xFFD8D1E8),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    '${state.currentBatchProgress} / 108',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: _textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    isCompleted
                                        ? 'This Mandali challenge is completed. Your contribution for this challenge has been recorded.'
                                        : 'Every Jai Shri Ram here contributes directly to this Mandali challenge.',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: _textSecondary,
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  _buildWritingExperienceCard(),
                                  const SizedBox(height: 10),

                                  Builder(
                                    builder: (context) {
                                      final int displayFilledCells =
                                      _isWriting &&
                                          !isCompleted &&
                                          state.currentBatchProgress < 108
                                          ? state.currentBatchProgress + 1
                                          : state.currentBatchProgress;

                                      return RepaintBoundary(
                                        child: _MandaliGrid(
                                          filledCells: displayFilledCells,
                                          gridLabel: 'Jai Shri\nRam',
                                          inkColor: _selectedInkColor,
                                          paperStyle: _selectedPaperStyle,
                                          handwritingMode: _handwritingMode,
                                          animateLatestFill: _isWriting,
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 96),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
          IgnorePointer(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.directional,
                blastDirection: math.pi / 2,
                emissionFrequency: 0.03,
                numberOfParticles: 12,
                maxBlastForce: 5,
                minBlastForce: 2,
                gravity: 0.22,
                shouldLoop: false,
                colors: const [
                  Color(0xFFFFC1CC),
                  Color(0xFFFFD59E),
                  Color(0xFFFFF4D6),
                  Color(0xFFE8B4FF),
                ],
                createParticlePath: _petalPath,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(14, 10, 14, 14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          decoration: BoxDecoration(
            color: _bgColor,
            border: const Border(top: BorderSide(color: _borderColor)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 150,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
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
                  onPressed: () {
                    final state = _latestWriterState;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SupportRamakotiScreen(
                          source: 'mandali_writer_offer_support',
                          sourceMandaliId: normalizedMandaliId,
                          sourceMandaliName: state?.mandaliName,
                          sourceChallengeId: state?.challengeId,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Offer Support',
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Builder(
                  builder: (context) {
                    final state = _latestWriterState;
                    final isCompleted =
                        (state?.challengeStatus ?? '').trim().toLowerCase() ==
                            'completed';

                    return ElevatedButton(
                      onPressed: (_isWriting || isCompleted) ? null : _handleWrite,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.orangeAccent.shade100,
                        disabledForegroundColor: Colors.white,
                        minimumSize: const Size(0, 54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 0,
                      ),
                      child: _isWriting
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          isCompleted ? 'Completed' : 'Jai Shri Ram',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopSummaryCard extends StatelessWidget {
  const _TopSummaryCard({
    required this.mandaliTotal,
    required this.yourContribution,
    required this.challengeTitle,
  });

  final String mandaliTotal;
  final String yourContribution;
  final String challengeTitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _MandaliWriterScreenState._borderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            challengeTitle.isEmpty ? 'Mandali Challenge' : challengeTitle,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _MandaliWriterScreenState._textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _miniStat('Mandali Total', mandaliTotal)),
              const SizedBox(width: 10),
              Expanded(child: _miniStat('Your Contribution', yourContribution)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: _MandaliWriterScreenState._textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _MandaliWriterScreenState._textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

enum _PaperStyle {
  notebook,
  parchment,
  manuscript,
  cleanWhite,
}

extension _PaperStyleLabel on _PaperStyle {
  String get label {
    switch (this) {
      case _PaperStyle.notebook:
        return 'Notebook';
      case _PaperStyle.parchment:
        return 'Parchment';
      case _PaperStyle.manuscript:
        return 'Temple';
      case _PaperStyle.cleanWhite:
        return 'White';
    }
  }
}

class _InkOption {
  final String label;
  final Color color;

  const _InkOption(this.label, this.color);
}

class _MandaliGrid extends StatefulWidget {
  const _MandaliGrid({
    required this.filledCells,
    required this.gridLabel,
    required this.inkColor,
    required this.paperStyle,
    required this.handwritingMode,
    required this.animateLatestFill,
  });

  final int filledCells;
  final String gridLabel;
  final Color inkColor;
  final _PaperStyle paperStyle;
  final bool handwritingMode;
  final bool animateLatestFill;

  @override
  State<_MandaliGrid> createState() => _MandaliGridState();
}

class _MandaliGridState extends State<_MandaliGrid> {
  @override
  Widget build(BuildContext context) {
    const totalCells = 108;
    const columns = 6;
    final latestFilledIndex = widget.filledCells - 1;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: totalCells,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (context, index) {
        final isFilled = index < widget.filledCells;
        final isLatestAnimatedCell =
            widget.animateLatestFill &&
                isFilled &&
                index == latestFilledIndex;

        if (!isFilled) {
          return _PaperStyledCell(
            paperStyle: widget.paperStyle,
            isFilled: false,
          );
        }

        if (isLatestAnimatedCell) {
          return _AnimatedWritingCell(
            text: widget.gridLabel,
            inkColor: widget.inkColor,
            paperStyle: widget.paperStyle,
            handwritingMode: widget.handwritingMode,
          );
        }

        return _PaperStyledCell(
          paperStyle: widget.paperStyle,
          isFilled: true,
          child: _GridCellText(
            text: widget.gridLabel,
            inkColor: widget.inkColor,
            handwritingMode: widget.handwritingMode,
          ),
        );
      },
    );
  }
}

class _PaperStyledCell extends StatelessWidget {
  final _PaperStyle paperStyle;
  final bool isFilled;
  final Widget? child;

  const _PaperStyledCell({
    required this.paperStyle,
    required this.isFilled,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: _paperDecoration(paperStyle),
          ),
          if (paperStyle == _PaperStyle.notebook)
            const CustomPaint(
              painter: _NotebookLinesPainter(),
            ),
          if (paperStyle == _PaperStyle.manuscript)
            const CustomPaint(
              painter: _TempleManuscriptPainter(),
            ),
          if (isFilled)
            Container(
              color: const Color(0x14FF9E2C),
            ),
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: _MandaliWriterScreenState._borderColor,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          if (child != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: child!,
              ),
            ),
        ],
      ),
    );
  }

  BoxDecoration _paperDecoration(_PaperStyle style) {
    switch (style) {
      case _PaperStyle.notebook:
        return BoxDecoration(
          color: const Color(0xFFFFFCF5),
          borderRadius: BorderRadius.circular(10),
        );
      case _PaperStyle.parchment:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF5E7C8),
              Color(0xFFEAD6AA),
            ],
          ),
        );
      case _PaperStyle.manuscript:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const RadialGradient(
            center: Alignment.center,
            radius: 1.1,
            colors: [
              Color(0xFFF8EAC9),
              Color(0xFFE8D4A0),
            ],
          ),
        );
      case _PaperStyle.cleanWhite:
        return BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        );
    }
  }
}

class _GridCellText extends StatelessWidget {
  final String text;
  final Color inkColor;
  final bool handwritingMode;

  const _GridCellText({
    required this.text,
    required this.inkColor,
    required this.handwritingMode,
  });

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: _gridTextStyle(
          inkColor: inkColor,
          handwritingMode: handwritingMode,
        ),
      ),
    );
  }
}

class _AnimatedWritingCell extends StatefulWidget {
  final String text;
  final Color inkColor;
  final _PaperStyle paperStyle;
  final bool handwritingMode;

  const _AnimatedWritingCell({
    required this.text,
    required this.inkColor,
    required this.paperStyle,
    required this.handwritingMode,
  });

  @override
  State<_AnimatedWritingCell> createState() => _AnimatedWritingCellState();
}

class _AnimatedWritingCellState extends State<_AnimatedWritingCell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final progress = Curves.easeOut.transform(_controller.value);
            final penLeft = 8 + ((constraints.maxWidth - 30) * progress);
            final penTop =
                (constraints.maxHeight * 0.18) +
                    (math.sin(progress * math.pi * 4) * 2.0);
            final penOpacity =
            progress < 0.82
                ? 1.0
                : (1.0 - ((progress - 0.82) / 0.18)).clamp(0.0, 1.0);
            final trailWidth = (constraints.maxWidth - 18) * progress;

            return Stack(
              fit: StackFit.expand,
              children: [
                _PaperStyledCell(
                  paperStyle: widget.paperStyle,
                  isFilled: true,
                ),
                Positioned(
                  left: 8,
                  right: 8,
                  top: constraints.maxHeight * 0.52,
                  child: Opacity(
                    opacity: 0.18,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: trailWidth,
                        height: 1.8,
                        decoration: BoxDecoration(
                          color: widget.inkColor,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: ClipRect(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress.clamp(0.0, 1.0),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            widget.text,
                            textAlign: TextAlign.center,
                            style: _gridTextStyle(
                              inkColor: widget.inkColor,
                              handwritingMode: widget.handwritingMode,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: penLeft,
                  top: penTop,
                  child: Opacity(
                    opacity: penOpacity,
                    child: Transform.rotate(
                      angle:
                      -0.45 + (math.sin(progress * math.pi * 2) * 0.08),
                      child: Icon(
                        Icons.edit_rounded,
                        size: 18,
                        color: widget.inkColor.withOpacity(0.92),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

TextStyle _gridTextStyle({
  required Color inkColor,
  required bool handwritingMode,
}) {
  return TextStyle(
    fontSize: handwritingMode ? 11.5 : 10,
    fontWeight: FontWeight.w600,
    fontStyle: handwritingMode ? FontStyle.italic : FontStyle.normal,
    letterSpacing: handwritingMode ? 0.2 : 0,
    height: 1.05,
    color: inkColor,
    shadows: handwritingMode
        ? [
      Shadow(
        color: inkColor.withOpacity(0.10),
        blurRadius: 1,
        offset: const Offset(0.4, 0.4),
      ),
    ]
        : null,
  );
}

class _NotebookLinesPainter extends CustomPainter {
  const _NotebookLinesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x33007AFF)
      ..strokeWidth = 0.8;

    const gap = 11.0;
    for (double y = 10; y < size.height; y += gap) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TempleManuscriptPainter extends CustomPainter {
  const _TempleManuscriptPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = const Color(0x668B5E00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    final innerPaint = Paint()
      ..color = const Color(0x22A06B00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(10),
    );
    final innerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(4, 4, size.width - 8, size.height - 8),
      const Radius.circular(8),
    );

    canvas.drawRRect(rect, borderPaint);
    canvas.drawRRect(innerRect, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Path _petalPath(Size size) {
  final width = size.width;
  final height = size.height;

  final path = Path();
  path.moveTo(width * 0.5, 0);
  path.quadraticBezierTo(
    width * 0.95,
    height * 0.2,
    width * 0.7,
    height * 0.65,
  );
  path.quadraticBezierTo(
    width * 0.55,
    height * 0.95,
    width * 0.5,
    height,
  );
  path.quadraticBezierTo(
    width * 0.45,
    height * 0.95,
    width * 0.3,
    height * 0.65,
  );
  path.quadraticBezierTo(
    width * 0.05,
    height * 0.2,
    width * 0.5,
    0,
  );
  path.close();
  return path;
}