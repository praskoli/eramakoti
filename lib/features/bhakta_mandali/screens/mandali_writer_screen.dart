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

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 1800),
    );

    final user = AuthService.instance.currentUser;

    _mandaliStream =
        BhaktaMandaliService.instance.watchMandali(widget.mandaliId);

    if (user != null) {
      _writerStateStream = MandaliWriterService.instance.watchWriterState(
        mandaliId: widget.mandaliId,
        uid: user.uid,
      );
      _membershipsStream = BhaktaMandaliService.instance.watchMyMandalis(user.uid);
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
                                  RepaintBoundary(
                                    child: _MandaliGrid(
                                      filledCells: state.currentBatchProgress,
                                      gridLabel: 'Jai Shri\nRam',
                                    ),
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
                          sourceMandaliId: widget.mandaliId,
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

class _MandaliGrid extends StatelessWidget {
  const _MandaliGrid({
    required this.filledCells,
    required this.gridLabel,
  });

  final int filledCells;
  final String gridLabel;

  @override
  Widget build(BuildContext context) {
    const totalCells = 108;
    const columns = 6;

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
        final isFilled = index < filledCells;

        return Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isFilled
                ? _MandaliWriterScreenState._gridFilled
                : _MandaliWriterScreenState._gridEmpty,
            border: Border.all(
              color: _MandaliWriterScreenState._borderColor,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: isFilled
              ? FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Text(
                gridLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _MandaliWriterScreenState._textPrimary,
                  height: 1.1,
                ),
              ),
            ),
          )
              : const SizedBox.shrink(),
        );
      },
    );
  }
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