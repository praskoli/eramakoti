import 'dart:math' as math;
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../support/support_ramakoti_screen.dart';
import '../../models/ramakoti_meta.dart';
import '../../services/auth/auth_service.dart';
import '../../services/firebase/ramakoti_service.dart';
import '../../services/notifications/reminder_service.dart';
import '../../features/navigation/main_bottom_nav_screen.dart';
import 'select_language_target_screen.dart';

class RamakotiWriterScreen extends StatefulWidget {
  const RamakotiWriterScreen({super.key});

  @override
  State<RamakotiWriterScreen> createState() => _RamakotiWriterScreenState();
}

class _RamakotiWriterScreenState extends State<RamakotiWriterScreen> {
  static const Color _bgColor = Color(0xFFF6EEDD);
  static const Color _accent = Color(0xFFFF9E2C);
  static const Color _gridFilled = Color(0xFFF3DFBE);
  static const Color _gridEmpty = Color(0xFFF8F1E8);
  static const Color _progressBg = Color(0xFFE7DFF1);
  static const Color _borderColor = Color(0xFFD8D2C8);
  static const Color _textPrimary = Color(0xFF2F2A25);
  static const Color _textSecondary = Color(0xFF6F6256);

  final AudioPlayer _writePlayer = AudioPlayer();
  final AudioPlayer _celebrationPlayer = AudioPlayer();
  late final ConfettiController _confettiController;

  bool _isWriting = false;
  bool _targetDialogShown = false;
  RamakotiMeta? _latestMeta;
  RamakotiMeta? _optimisticMeta;

  int? _previewNextMalaAfterCompletedBatch;

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
  }

  @override
  void dispose() {
    _writePlayer.dispose();
    _celebrationPlayer.dispose();
    _confettiController.dispose();
    super.dispose();
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

  String _localizedRamLabel(String language) {
    switch (language.trim().toLowerCase()) {
      case 'telugu':
        return 'జై శ్రీ రామ్';
      case 'hindi':
        return 'जय श्री राम';
      default:
        return 'Jai Shri Ram';
    }
  }

  _WriterLocalizedText _localizedPopupText(String language) {
    switch (language.trim().toLowerCase()) {
      case 'telugu':
        return const _WriterLocalizedText(
          jaiShriRamTitle: 'జై శ్రీ రామ్',
          targetCompletedTitle: 'జై శ్రీ రామ్',
          targetCompletedMessage:
          '🙏 మీరు మీ రామకోటి లక్ష్యాన్ని ఆనందంగా పూర్తి చేశారు. శ్రీరాముని కృప ఎల్లప్పుడూ మీపై ప్రసరిస్తూ ఉండుగాక.',
          homeButton: 'హోమ్',
          setNewTargetButton: 'కొత్త లక్ష్యం',
          japaMalaCompletedMessage:
          '🙏 మీరు పవిత్రమైన 108 నామాల జపమాల పూర్తి చేశారు. శ్రీరాముని ఆశీస్సులు మీ భక్తిని మరింత బలపరచుగాక.',
          blessingLine: 'శ్రీరాముడు మీ భక్తిని ఆశీర్వదించుగాక.',
          nextSacredStepLabel: 'తదుపరి పవిత్ర దశ:',
          onlyMoreToReachIt: 'దాన్ని చేరడానికి ఇంకా',
          continueWritingButton: 'రచన కొనసాగించండి',
        );

      case 'hindi':
        return const _WriterLocalizedText(
          jaiShriRamTitle: 'जय श्री राम',
          targetCompletedTitle: 'जय श्री राम',
          targetCompletedMessage:
          '🙏 आपने अपना रामकोटि लक्ष्य पूर्ण कर लिया है। श्रीराम की कृपा सदा आपके साथ बनी रहे।',
          homeButton: 'होम',
          setNewTargetButton: 'नया लक्ष्य',
          japaMalaCompletedMessage:
          '🙏 आपने 108 नामों की पवित्र जपमाला पूर्ण की है। श्रीराम आपके श्रद्धा को और गहन करें।',
          blessingLine: 'श्री राम आपकी भक्ति को आशीर्वाद दें।',
          nextSacredStepLabel: 'अगला पवित्र चरण:',
          onlyMoreToReachIt: 'वहाँ पहुँचने के लिए अभी',
          continueWritingButton: 'लेखन जारी रखें',
        );

      default:
        return const _WriterLocalizedText(
          jaiShriRamTitle: 'Jai Shri Ram',
          targetCompletedTitle: 'Jai Shri Ram',
          targetCompletedMessage:
          '🙏 You have joyfully completed your Ramakoti target. May the grace of Shri Ram ever shine upon you.',
          homeButton: 'Home',
          setNewTargetButton: 'Set New Target',
          japaMalaCompletedMessage:
          '🙏 You have completed the sacred Japa Mala of 108 names. May Shri Ram deepen your devotion.',
          blessingLine: 'May Shri Ram bless your devotion.',
          nextSacredStepLabel: 'Next sacred step:',
          onlyMoreToReachIt: 'Only',
          continueWritingButton: 'Continue Writing',
        );
    }
  }

  String _localizedRamGridLabel(String language) {
    switch (language.trim().toLowerCase()) {
      case 'telugu':
        return 'జై శ్రీ\nరామ్';
      case 'hindi':
        return 'जय श्री\nराम';
      default:
        return 'Jai Shri\nRam';
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _greetingName(String? displayName) {
    final trimmed = (displayName ?? '').trim();
    if (trimmed.isEmpty) return 'Devotee';
    return trimmed.split(' ').first;
  }

  int _nextSacredStep(RamakotiMeta meta) {
    return (meta.completedBatchCount + 1) * RamakotiMeta.batchSize;
  }

  int _remainingToNextSacredStep(RamakotiMeta meta) {
    final remaining = _nextSacredStep(meta) - meta.currentRunCount;
    return remaining < 0 ? 0 : remaining;
  }

  Future<void> _goHome() async {
    if (!mounted) return;
    await Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const MainBottomNavScreen(initialIndex: 0),
      ),
          (route) => false,
    );
  }

  Future<void> _openDonateFlow() async {
    if (!mounted) return;

    final meta = _latestMeta;
    final activeMandaliId = (meta?.activeMandaliId ?? '').trim();
    final activeMandaliName = (meta?.activeMandaliName ?? '').trim();
    final activeMandaliChallengeId =
    (meta?.activeMandaliChallengeId ?? '').trim();

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SupportRamakotiScreen(
          source: 'writer_offer_support',
          sourceMandaliId: activeMandaliId.isEmpty ? null : activeMandaliId,
          sourceMandaliName: activeMandaliName.isEmpty ? null : activeMandaliName,
          sourceChallengeId:
          activeMandaliChallengeId.isEmpty ? null : activeMandaliChallengeId,
        ),
      ),
    );
  }

  Future<void> _openMandaliHub() async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const MainBottomNavScreen(initialIndex: 2),
      ),
    );
  }

  Future<void> _goToNewTarget() async {
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const SelectLanguageTargetScreen()),
    );
  }

  Future<void> _openReminderActions(BuildContext context) async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reminders are not available on web builds.'),
        ),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Reminder Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.of(sheetContext).pop();

                      final granted =
                      await ReminderService.instance.requestPermissions();

                      if (!mounted) return;

                      if (!granted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Notification permission was not granted.',
                            ),
                          ),
                        );
                        return;
                      }

                      final picked = await showTimePicker(
                        context: context,
                        initialTime: const TimeOfDay(hour: 6, minute: 0),
                        initialEntryMode: TimePickerEntryMode.input,
                      );

                      if (picked == null) return;

                      try {
                        await ReminderService.instance.scheduleDailyReminder(
                          hour: picked.hour,
                          minute: picked.minute,
                        );

                        final pending =
                        await ReminderService.instance.pendingReminders();

                        if (!mounted) return;

                        final exists = pending.any((n) => n.id == 1001);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              exists
                                  ? 'Daily reminder set for ${_formatTimeOfDay(picked)}.'
                                  : 'Reminder could not be verified. Please try again.',
                            ),
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to schedule reminder: $e'),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Set Daily Reminder'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      Navigator.of(sheetContext).pop();

                      await ReminderService.instance.cancelDailyReminder();

                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Daily reminder turned off.'),
                        ),
                      );
                    },
                    child: const Text('Turn Off Reminder'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showTargetCompletedDialog(
      BuildContext context,
      RamakotiMeta meta,
      ) async {
    if (_targetDialogShown) return;
    _targetDialogShown = true;

    final t = _localizedPopupText(meta.language);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "🙏",
                  style: TextStyle(fontSize: 42),
                ),
                const SizedBox(height: 10),
                Text(
                  t.targetCompletedTitle,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF8C00),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  t.targetCompletedMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          Navigator.of(dialogContext).pop();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Your certificate is available in Ramakoti History.',
                                ),
                              ),
                            );
                          }
                          await _goHome();
                        },
                        child: Text(t.homeButton),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.of(dialogContext).pop();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Your certificate is available in Ramakoti History.',
                                ),
                              ),
                            );
                          }
                          await _goToNewTarget();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF8C00),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            t.setNewTargetButton,
                            maxLines: 1,
                          ),
                        ),
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

  Future<void> _showJapaMalaCompletedDialog(
      BuildContext context,
      RamakotiMeta meta,
      ) async {
    await _playTempleBell();
    _confettiController.play();

    final nextStep = _nextSacredStep(meta);
    final remaining = _remainingToNextSacredStep(meta);
    final t = _localizedPopupText(meta.language);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "🙏",
                  style: TextStyle(fontSize: 42),
                ),
                const SizedBox(height: 10),
                Text(
                  t.jaiShriRamTitle,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF8C00),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  t.japaMalaCompletedMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  t.blessingLine,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "${t.nextSacredStepLabel} ${_formatIndianNumber(nextStep)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "${t.onlyMoreToReachIt} ${_formatIndianNumber(remaining)}",
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8C00),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      t.continueWritingButton,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) return;

    setState(() {
      _previewNextMalaAfterCompletedBatch = meta.completedBatchCount;
    });
  }

  Future<void> _handleWrite(
      BuildContext context,
      String uid,
      RamakotiMeta meta,
      ) async {
    if (_isWriting || meta.isTargetCompleted) return;

    final nextRunCount = meta.currentRunCount + 1;
    final nextTotalCount = meta.totalCount + 1;
    final nextTodayCount = meta.todayCount + 1;

    final nextBatchNumber =
    nextRunCount <= 0 ? 1 : ((nextRunCount - 1) ~/ 108) + 1;
    final nextBatchProgress =
    nextRunCount % 108 == 0 ? 108 : nextRunCount % 108;
    final nextCompletedBatchCount = nextRunCount ~/ 108;

    final optimisticMeta = meta.copyWith(
      currentRunCount: nextRunCount,
      totalCount: nextTotalCount,
      todayCount: nextTodayCount,
      storedCurrentBatchNumber: nextBatchNumber,
      storedCurrentBatchProgress: nextBatchProgress,
      storedCompletedBatchCount: nextCompletedBatchCount,
    );

    setState(() {
      _isWriting = true;
      _optimisticMeta = optimisticMeta;
    });

    try {
      _playWriteTone();

      final result = await RamakotiService.instance.writeOne(uid);

      if (!mounted) return;

      final updatedMeta = meta.copyWith(
        currentRunCount: result.currentRunCount,
        totalCount: result.totalCount,
        todayCount: result.todayCount,
        storedCurrentBatchNumber:
        result.currentRunCount <= 0
            ? 1
            : ((result.currentRunCount - 1) ~/ 108) + 1,
        storedCurrentBatchProgress:
        result.currentRunCount % 108 == 0
            ? 108
            : result.currentRunCount % 108,
        storedCompletedBatchCount: result.currentRunCount ~/ 108,
      );

      if (result.batchCompleted && !updatedMeta.isTargetCompleted) {
        await _showJapaMalaCompletedDialog(context, updatedMeta);
      }

      if (updatedMeta.isTargetCompleted) {
        await _showTargetCompletedDialog(context, updatedMeta);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _optimisticMeta = null;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Write failed: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isWriting = false;
          _optimisticMeta = null;
        });
      }
    }
  }

  Future<void> _handleBottomAction(
      BuildContext context,
      String uid,
      RamakotiMeta meta,
      ) async {
    if (meta.isTargetCompleted) {
      await _goToNewTarget();
      return;
    }

    await _handleWrite(context, uid, meta);
  }

  String _statusLine(
      RamakotiMeta meta, {
        required bool showNextMalaPreview,
        required int displayMalaNumber,
      }) {
    if (meta.isTargetCompleted) {
      return 'Your journey is complete. Start a new target.';
    }

    if (showNextMalaPreview) {
      return 'Japa Mala $displayMalaNumber is ready. Tap Jai Shri Ram to write the first nama.';
    }

    if (meta.currentBatchProgress == RamakotiMeta.batchSize) {
      return 'Sacred Japa Mala complete.';
    }

    return '${meta.remainingInCurrentBatch} more in this Japa Mala • ${_formatIndianNumber(meta.remainingToTarget)} more to target';
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
                    children:
                    inkOptions.map((option) {
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
                            color:
                            selected
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
                                  fontWeight:
                                  selected
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
                    children:
                    _PaperStyle.values.map((style) {
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
                          selected
                              ? FontWeight.w700
                              : FontWeight.w500,
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
    final user = AuthService.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No authenticated user')),
      );
    }

    final userName = _greetingName(user.displayName);

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: _goHome,
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
        ),
        centerTitle: true,
        title: const Text(
          'Ramakoti Writer',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _openReminderActions(context),
            icon: const Icon(
              Icons.notifications_none,
              color: Colors.black87,
            ),
          ),
          IconButton(
            onPressed: _goHome,
            icon: const Icon(Icons.home_outlined, color: Colors.black87),
          ),
        ],
      ),
      body: Stack(
        children: [
          StreamBuilder<int>(
            stream: RamakotiService.instance.watchGlobalRamCount(),
            builder: (context, globalSnapshot) {
              final globalCount = globalSnapshot.data ?? 0;

              return StreamBuilder<RamakotiMeta>(
                initialData: _latestMeta ?? RamakotiMeta.empty(user.uid),
                stream: RamakotiService.instance.watchSummary(user.uid),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final serverMeta =
                      snapshot.data ?? RamakotiMeta.empty(user.uid);
                  final meta = _optimisticMeta ?? serverMeta;
                  _latestMeta = serverMeta;

                  if (!meta.isTargetCompleted) {
                    _targetDialogShown = false;
                  }

                  if (meta.currentBatchProgress < RamakotiMeta.batchSize) {
                    _previewNextMalaAfterCompletedBatch = null;
                  }

                  final showNextMalaPreview =
                      meta.currentBatchProgress == RamakotiMeta.batchSize &&
                          !meta.isTargetCompleted &&
                          _previewNextMalaAfterCompletedBatch ==
                              meta.completedBatchCount;

                  final displayMalaNumber =
                  showNextMalaPreview
                      ? meta.currentBatchNumber + 1
                      : meta.currentBatchNumber;
                  final displayMalaProgress =
                  showNextMalaPreview ? 0 : meta.currentBatchProgress;
                  final displayMalaProgressPercent =
                  showNextMalaPreview
                      ? 0.0
                      : meta.currentBatchProgressPercent;

                  final targetText =
                  meta.targetCount > 0
                      ? _formatIndianNumber(meta.targetCount)
                      : 'Not selected';
                  final gridLabel = _localizedRamGridLabel(meta.language);

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
                                'Jai Shri Ram, $userName',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: _accent,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'May Shri Ram bless your journey of writing His divine name.',
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.35,
                                  color: _textSecondary,
                                ),
                              ),
                              if (meta.activeMandaliName.trim().isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: InkWell(
                                    onTap: _openMandaliHub,
                                    borderRadius: BorderRadius.circular(999),
                                    child: Ink(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF1DE),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.groups_rounded,
                                            size: 18,
                                            color: Color(0xFFFF9E2C),
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              'Active Mandali: ${meta.activeMandaliName}',
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF2F2A25),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              _GlobalRamCountCard(count: globalCount),
                              const SizedBox(height: 10),
                              const Text(
                                'Japa Mala Progress',
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
                                  value: displayMalaProgressPercent,
                                  minHeight: 8,
                                  backgroundColor: _progressBg,
                                  valueColor: const AlwaysStoppedAnimation(
                                    _accent,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '$displayMalaProgress / ${RamakotiMeta.batchSize}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: _textSecondary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Target Progress',
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
                                  value: meta.targetProgressPercent,
                                  minHeight: 8,
                                  backgroundColor: _progressBg,
                                  valueColor: const AlwaysStoppedAnimation(
                                    Color(0xFFD8D1E8),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '${_formatIndianNumber(meta.currentRunCount)} / $targetText',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: _textSecondary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _statusLine(
                                  meta,
                                  showNextMalaPreview: showNextMalaPreview,
                                  displayMalaNumber: displayMalaNumber,
                                ),
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: _textSecondary,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _buildWritingExperienceCard(),
                              const SizedBox(height: 10),
                              RepaintBoundary(
                                child: _RamakotiGrid(
                                  filledCells: meta.currentBatchProgress,
                                  gridLabel: gridLabel,
                                  showNextMalaPreview: showNextMalaPreview,
                                  inkColor: _selectedInkColor,
                                  paperStyle: _selectedPaperStyle,
                                  handwritingMode: _handwritingMode,
                                  animateLatestFill:
                                  _isWriting && !showNextMalaPreview,
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
            border: const Border(
              top: BorderSide(color: _borderColor),
            ),
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
                width: 118,
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
                  onPressed: _openDonateFlow,
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
                child: ElevatedButton(
                  onPressed:
                  _isWriting
                      ? null
                      : () async {
                    final meta =
                        _optimisticMeta ??
                            _latestMeta ??
                            RamakotiMeta.empty(user.uid);
                    await _handleBottomAction(context, user.uid, meta);
                  },
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
                  child:
                  _isWriting
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
                      ((_optimisticMeta ?? _latestMeta)
                          ?.isTargetCompleted ??
                          false)
                          ? 'Set New Target'
                          : _localizedRamLabel(
                        (_optimisticMeta ?? _latestMeta)?.language ??
                            '',
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
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
}

class _GlobalRamCountCard extends StatelessWidget {
  final int count;

  const _GlobalRamCountCard({required this.count});

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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: _RamakotiWriterScreenState._borderColor,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Global Ram Count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _RamakotiWriterScreenState._textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatIndianNumber(count),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _RamakotiWriterScreenState._textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Jai Shri Ram written across devotees',
            style: TextStyle(
              fontSize: 11,
              color: _RamakotiWriterScreenState._textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

enum _PaperStyle { notebook, parchment, manuscript, cleanWhite }

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

class _RamakotiGrid extends StatefulWidget {
  final int filledCells;
  final String gridLabel;
  final bool showNextMalaPreview;
  final Color inkColor;
  final _PaperStyle paperStyle;
  final bool handwritingMode;
  final bool animateLatestFill;

  const _RamakotiGrid({
    required this.filledCells,
    required this.gridLabel,
    required this.showNextMalaPreview,
    required this.inkColor,
    required this.paperStyle,
    required this.handwritingMode,
    required this.animateLatestFill,
  });

  @override
  State<_RamakotiGrid> createState() => _RamakotiGridState();
}

class _RamakotiGridState extends State<_RamakotiGrid> {
  @override
  Widget build(BuildContext context) {
    const int totalCells = 108;
    const int columns = 6;
    const int totalRows = totalCells ~/ columns;

    if (widget.showNextMalaPreview) {
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
          return _PaperStyledCell(
            paperStyle: widget.paperStyle,
            isFilled: false,
          );
        },
      );
    }

    if (widget.filledCells >= totalCells) {
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

    final int currentRow =
    widget.filledCells <= 0 ? 0 : ((widget.filledCells - 1) ~/ columns);
    final int startRow = currentRow <= 0 ? 0 : currentRow - 1;
    final int visibleRows = totalRows - startRow;
    final int visibleItemCount = visibleRows * columns;
    final int latestFilledIndex = widget.filledCells - 1;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: visibleItemCount,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (context, visibleIndex) {
        final int actualIndex = (startRow * columns) + visibleIndex;
        final bool isFilled = actualIndex < widget.filledCells;
        final bool isLatestAnimatedCell =
            widget.animateLatestFill &&
                isFilled &&
                actualIndex == latestFilledIndex;

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
                color: _RamakotiWriterScreenState._borderColor,
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
    shadows:
    handwritingMode
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
    final paint =
    Paint()
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
    final borderPaint =
    Paint()
      ..color = const Color(0x668B5E00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    final innerPaint =
    Paint()
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

class _WriterLocalizedText {
  final String jaiShriRamTitle;
  final String targetCompletedTitle;
  final String targetCompletedMessage;
  final String homeButton;
  final String setNewTargetButton;
  final String japaMalaCompletedMessage;
  final String blessingLine;
  final String nextSacredStepLabel;
  final String onlyMoreToReachIt;
  final String continueWritingButton;

  const _WriterLocalizedText({
    required this.jaiShriRamTitle,
    required this.targetCompletedTitle,
    required this.targetCompletedMessage,
    required this.homeButton,
    required this.setNewTargetButton,
    required this.japaMalaCompletedMessage,
    required this.blessingLine,
    required this.nextSacredStepLabel,
    required this.onlyMoreToReachIt,
    required this.continueWritingButton,
  });
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