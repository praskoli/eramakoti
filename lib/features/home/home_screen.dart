import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:share_plus/share_plus.dart';

import '../../models/ramakoti_meta.dart';
import '../../services/auth/auth_service.dart';
import '../../services/firebase/ramakoti_service.dart';
import '../../features/bhakta_mandali/screens/bhakta_mandali_home_screen.dart';
import '../../services/notifications/reminder_service.dart';
import '/../screens/ramakoti/ramakoti_writer_screen.dart';
import '/../screens/ramakoti/select_language_target_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color _bgColor = Color(0xFFF8F2E8);
  static const Color _cardColor = Colors.white;
  static const Color _textPrimary = Color(0xFF2F2A25);
  static const Color _textSecondary = Color(0xFF7C7167);
  static const Color _accent = Color(0xFFFF9E2C);
  static const Color _softAccent = Color(0xFFFFF1DE);
  static const Color _softBorder = Color(0xFFEADFD2);
  static const Color _progressBg = Color(0xFFF0E7DB);
  ReminderInfo? _reminderInfo;

  @override
  void initState() {
    super.initState();
    _loadReminderInfo();
  }

  Future<void> _loadReminderInfo() async {
    final info = await ReminderService.instance.getReminderInfo();
    if (!mounted) return;

    setState(() {
      _reminderInfo = info;
    });
  }

  Future<String> _loadMaAsayam(String language) async {
    final normalized = language.trim().toLowerCase();

    String assetPath;
    if (normalized == 'telugu') {
      assetPath = 'assets/content/ma_asayam/RamakotiIntro_te.txt';
    } else if (normalized == 'hindi') {
      assetPath = 'assets/content/ma_asayam/RamakotiIntro_hi.txt';
    } else {
      assetPath = 'assets/content/ma_asayam/RamakotiIntro_en.txt';
    }

    try {
      return await rootBundle.loadString(assetPath);
    } catch (_) {
      return await rootBundle.loadString(
        'assets/content/ma_asayam/RamakotiIntro_en.txt',
      );
    }
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

  String _greetingText(String? name) {
    final firstName = (name ?? '').trim().split(' ').firstOrNull?.trim();
    if (firstName == null || firstName.isEmpty) {
      return 'Jai Shri Ram';
    }
    return 'Jai Shri Ram, $firstName';
  }

  String _primaryCta(RamakotiMeta meta) {
    if (!meta.hasTarget || meta.language.trim().isEmpty) {
      return 'Create Journey';
    }
    if (meta.isTargetCompleted) {
      return 'Create New Journey';
    }
    return 'Continue Journey';
  }

  Future<void> _openBhaktaMandaliHub(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BhaktaMandaliHomeScreen()),
    );
  }

  String _mandaliSubtitle(RamakotiMeta meta) {
    if (meta.activeMandaliName.trim().isNotEmpty) {
      return 'Active: ${meta.activeMandaliName}';
    }
    return 'Create, join, and contribute to devotional groups.';
  }

  Future<void> _handlePrimaryAction(
      BuildContext context,
      RamakotiMeta meta,
      ) async {
    if (!mounted) return;

    if (!meta.hasTarget ||
        meta.language.trim().isEmpty ||
        meta.isTargetCompleted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const SelectLanguageTargetScreen(),
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const RamakotiWriterScreen(),
      ),
    );
  }

  Future<void> _shareApp() async {
    const appLink =
        'https://play.google.com/store/apps/details?id=com.hindu.pooja';

    final messages = [
      '''
Jai Shri Ram 🙏

On the auspicious occasion of Ugadi and Sri Rama Navami, let us write Sri Rama Nama with devotion.

Join the sacred Rama Nama journey through the eRamakoti app.

$appLink
''',
      '''
Jai Shri Ram 🙏

Let us write Sri Rama Nama together and offer our devotion.

Join the Rama Nama journey through the eRamakoti app.

$appLink
''',
      '''
Jai Shri Ram 🙏

Ugadi and Sri Rama Navami are sacred occasions for Rama Nama smarana.

Let us write Sri Rama Nama digitally with devotion through the eRamakoti app.

$appLink
''',
      '''
Jai Shri Ram 🙏

Let us chant and write Sri Rama Nama with devotion.

Join the sacred Rama Nama journey through the eRamakoti app.

$appLink
''',
      '''
Jai Shri Ram 🙏

Let us celebrate Ugadi and Sri Rama Navami by writing Sri Rama Nama with devotion.

Join the Rama Nama journey through the eRamakoti app.

$appLink
''',
      '''
Jai Shri Ram 🙏

Let us write Sri Rama Nama together and spread devotion.

Join the sacred Rama Nama journey through the eRamakoti app.

$appLink
''',
      '''
Jai Shri Ram 🙏

For Ugadi and Sri Rama Navami, let us write Sri Rama Nama together.

Let us fill the world with Rama Nama.

Join the sacred journey through the eRamakoti app.

$appLink
''',
      '''
Jai Shri Ram 🙏

Sri Rama Navami is approaching.

Let us write Sri Rama Nama with devotion and offer it to Lord Rama.

Join the Rama Nama journey through the eRamakoti app.

$appLink
''',
      '''
🚩 Jai Shri Ram 🚩

For Ugadi and Sri Rama Navami, let us write Sri Rama Nama together.

Join the Rama Nama journey through the eRamakoti app.

$appLink
''',
      '''
Jai Shri Ram 🙏

Let us write Sri Rama Nama together as a family this Sri Rama Navami.

Join the Rama Nama journey through the eRamakoti app.

$appLink
''',
      '''
Jai Shri Ram 🙏

Let us write 1,00,000 Sri Rama Namas together for Sri Rama Navami.

Join the Rama Nama journey through the eRamakoti app.

$appLink
''',
      '''
Jai Shri Ram 🙏

For Ugadi and Sri Rama Navami, let us write Sri Rama Nama together.

Our goal is to write 1,00,000 Sri Rama Namas with devotion.

Join the Rama Nama journey through the eRamakoti app.

$appLink
''',
    ];

    final randomMessage = messages[DateTime.now().millisecond % messages.length];

    await Share.share(
      randomMessage,
      subject: 'eRamakoti - Sri Rama Nama',
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _formatReminderDisplay(ReminderInfo? info) {
    if (info == null ||
        !info.isEnabled ||
        info.hour == null ||
        info.minute == null) {
      return 'No daily reminder set yet.';
    }

    final time = TimeOfDay(hour: info.hour!, minute: info.minute!);
    return 'Daily reminder is set for ${_formatTimeOfDay(time)}.';
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
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
                    color: _textPrimary,
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
                        await _loadReminderInfo();
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
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
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
                      await _loadReminderInfo();

                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Daily reminder turned off.'),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
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

  String _buildStatusLine(RamakotiMeta meta) {
    if (!meta.hasTarget || meta.language.trim().isEmpty) {
      return 'Begin your Ramakoti journey by choosing language and target.';
    }
    if (meta.isTargetCompleted) {
      return 'Your current target is completed. Begin a new Ramakoti journey.';
    }
    if (meta.currentRunCount == 0) {
      return 'Your journey is ready. Continue with your first nama.';
    }
    return 'Continue your sacred Ramakoti journey from where you left off.';
  }

  String _targetSubtitle(RamakotiMeta meta) {
    if (!meta.hasTarget) return 'No target selected';
    if (meta.isTargetCompleted) return 'Completed';
    return '${_formatIndianNumber(meta.currentRunCount)} of ${_formatIndianNumber(meta.targetCount)}';
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
      body: SafeArea(
        child: StreamBuilder<RamakotiMeta>(
          stream: RamakotiService.instance.watchSummary(user.uid),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Error loading Home.\n${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final meta = snapshot.data ?? RamakotiMeta.empty(user.uid);
            final ctaLabel = _primaryCta(meta);

            return FutureBuilder<String>(
              future: _loadMaAsayam(meta.language),
              builder: (context, introSnapshot) {
                final maAsayamText = (introSnapshot.data ?? '').trim();

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                    await Future<void>.delayed(
                      const Duration(milliseconds: 350),
                    );
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _TopHeader(
                              title: _greetingText(user.displayName),
                              subtitle: _buildStatusLine(meta),
                              photoUrl: user.photoURL,
                              onShare: _shareApp,
                            ),
                            const SizedBox(height: 18),

                            _HeroActionCard(
                              title: meta.isTargetCompleted
                                  ? 'Target completed'
                                  : 'Current Ramakoti Sankalpam',
                              subtitle: _targetSubtitle(meta),
                              ctaLabel: ctaLabel,
                              onPressed: () =>
                                  _handlePrimaryAction(context, meta),
                              isCompleted: meta.isTargetCompleted,
                            ),
                            const SizedBox(height: 16),

                            InkWell(
                              borderRadius: BorderRadius.circular(22),
                              onTap: () => _openBhaktaMandaliHub(context),
                              child: Ink(
                                decoration: BoxDecoration(
                                  color: _cardColor,
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(color: _softBorder),
                                ),
                                padding:
                                const EdgeInsets.fromLTRB(16, 16, 16, 16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: const BoxDecoration(
                                        color: _softAccent,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.groups_rounded,
                                        color: _accent,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Bhakta Mandali',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: _textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _mandaliSubtitle(meta),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: _textSecondary,
                                              height: 1.45,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      color: _accent,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            StreamBuilder<int>(
                              stream:
                              RamakotiService.instance.watchGlobalRamCount(),
                              builder: (context, globalSnapshot) {
                                final globalCount = globalSnapshot.data ?? 0;

                                return Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: _cardColor,
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(color: _softBorder),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      16,
                                      16,
                                      16,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Global Ram Count',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: _textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _formatIndianNumber(globalCount),
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w800,
                                            color: _textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'Jai Shri Ram written across devotees',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: _textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  child: _MiniStatCard(
                                    icon: Icons.auto_awesome,
                                    label: 'Lifetime Count',
                                    value: _formatIndianNumber(meta.totalCount),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _MiniStatCard(
                                    icon: Icons.edit_note_rounded,
                                    label: 'Current Run',
                                    value: _formatIndianNumber(
                                      meta.currentRunCount,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Expanded(
                                  child: _MiniStatCard(
                                    icon: Icons.today_outlined,
                                    label: 'Today',
                                    value: _formatIndianNumber(meta.todayCount),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _MiniStatCard(
                                    icon: Icons.layers_outlined,
                                    label: 'Completed Batches',
                                    value:
                                    meta.completedBatchCount.toString(),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            _SectionCard(
                              title: 'Current Progress',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _LabelValueRow(
                                    label: 'Language',
                                    value: meta.languageLabel,
                                  ),
                                  const SizedBox(height: 10),
                                  _LabelValueRow(
                                    label: 'Target',
                                    value: meta.targetLabel,
                                  ),
                                  const SizedBox(height: 10),
                                  _LabelValueRow(
                                    label: 'Batch',
                                    value:
                                    '${meta.currentBatchNumber} • ${meta.currentBatchProgress}/108',
                                  ),
                                  const SizedBox(height: 18),
                                  const Text(
                                    'Run Progress',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: _textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: LinearProgressIndicator(
                                      value: meta.targetProgressPercent,
                                      minHeight: 10,
                                      backgroundColor: _progressBg,
                                      valueColor: const AlwaysStoppedAnimation(
                                        _accent,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    meta.hasTarget
                                        ? '${_formatIndianNumber(meta.currentRunCount)} / ${_formatIndianNumber(meta.targetCount)}'
                                        : 'No target selected',
                                    style: const TextStyle(
                                      color: _textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (meta.hasTarget &&
                                      !meta.isTargetCompleted) ...[
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Current Batch Progress',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: _textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: LinearProgressIndicator(
                                        value: meta.currentBatchProgressPercent,
                                        minHeight: 10,
                                        backgroundColor: _progressBg,
                                        valueColor:
                                        const AlwaysStoppedAnimation(
                                          Color(0xFFD98A22),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${meta.currentBatchProgress} / ${RamakotiMeta.batchSize}',
                                      style: const TextStyle(
                                        color: _textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            _SectionCard(
                              title: 'Reminder',
                              trailing: TextButton(
                                onPressed: () => _openReminderActions(context),
                                child: const Text('Manage'),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: _softAccent,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.notifications_active_outlined,
                                      color: _accent,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _reminderInfo?.isEnabled == true
                                          ? _formatReminderDisplay(
                                        _reminderInfo,
                                      )
                                          : (meta.isTargetCompleted
                                          ? 'Your target is completed. You can still keep a daily reminder for your next Ramakoti journey.'
                                          : 'Set a daily reminder for your Ramakoti writing. Reminder should appear when the app is backgrounded or closed.'),
                                      style: const TextStyle(
                                        color: _textSecondary,
                                        height: 1.45,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            _SectionCard(
                              title: 'Maa Asayam',
                              child: introSnapshot.connectionState ==
                                  ConnectionState.waiting
                                  ? const Padding(
                                padding:
                                EdgeInsets.symmetric(vertical: 18),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                                  : Text(
                                maAsayamText.isEmpty
                                    ? 'Maa Asayam content not available.'
                                    : maAsayamText,
                                style: const TextStyle(
                                  fontSize: 15,
                                  height: 1.6,
                                  color: _textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            _SectionCard(
                              title: 'Sacred Milestones',
                              child: Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  _MilestoneChip(
                                    label: '108',
                                    reached: meta.totalCount >= 108,
                                  ),
                                  _MilestoneChip(
                                    label: '1,000',
                                    reached: meta.totalCount >= 1000,
                                  ),
                                  _MilestoneChip(
                                    label: '10,000',
                                    reached: meta.totalCount >= 10000,
                                  ),
                                  _MilestoneChip(
                                    label: '1 Lakh',
                                    reached: meta.totalCount >= 100000,
                                  ),
                                  _MilestoneChip(
                                    label: '10 Lakh',
                                    reached: meta.totalCount >= 1000000,
                                  ),
                                  _MilestoneChip(
                                    label: '1 Crore',
                                    reached: meta.totalCount >= 10000000,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            _SectionCard(
                              title: 'Journey Highlights',
                              child: Column(
                                children: [
                                  _JourneyRow(
                                    icon: Icons.flag_outlined,
                                    title: 'Current Target',
                                    value: meta.targetLabel,
                                  ),
                                  const Divider(height: 20),
                                  _JourneyRow(
                                    icon: Icons.language_outlined,
                                    title: 'Selected Language',
                                    value: meta.languageLabel,
                                  ),
                                  const Divider(height: 20),
                                  _JourneyRow(
                                    icon: Icons.workspace_premium_outlined,
                                    title: 'Certificates Earned',
                                    value: meta.certificatesCount.toString(),
                                  ),
                                  const Divider(height: 20),
                                  _JourneyRow(
                                    icon: Icons.emoji_events_outlined,
                                    title: 'Completed Runs',
                                    value: meta.completedRunsCount.toString(),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            SizedBox(
                              width: double.infinity,
                              height: 58,
                              child: ElevatedButton(
                                onPressed: () =>
                                    _handlePrimaryAction(context, meta),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _accent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  ctaLabel,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
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
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? photoUrl;
  final VoidCallback onShare;

  const _TopHeader({
    required this.title,
    required this.subtitle,
    required this.photoUrl,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'eRamakoti',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _HomeScreenState._accent,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: _HomeScreenState._textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: _HomeScreenState._textSecondary,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onShare,
            borderRadius: BorderRadius.circular(999),
            child: Ink(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _HomeScreenState._cardColor,
                shape: BoxShape.circle,
                border: Border.all(color: _HomeScreenState._softBorder),
              ),
              child: const Icon(
                Icons.share_rounded,
                color: _HomeScreenState._accent,
                size: 20,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        CircleAvatar(
          radius: 26,
          backgroundColor: _HomeScreenState._softAccent,
          backgroundImage: (photoUrl != null && photoUrl!.trim().isNotEmpty)
              ? NetworkImage(photoUrl!)
              : null,
          child: (photoUrl == null || photoUrl!.trim().isEmpty)
              ? const Icon(
            Icons.person_outline,
            color: _HomeScreenState._accent,
          )
              : null,
        ),
      ],
    );
  }
}

class _HeroActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String ctaLabel;
  final VoidCallback onPressed;
  final bool isCompleted;

  const _HeroActionCard({
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.onPressed,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _HomeScreenState._cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _HomeScreenState._softBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: isCompleted
                    ? const Color(0xFFEAF8EE)
                    : _HomeScreenState._softAccent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                isCompleted ? 'Completed' : 'Active Journey',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isCompleted
                      ? const Color(0xFF2F8F4E)
                      : _HomeScreenState._accent,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _HomeScreenState._textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: _HomeScreenState._textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _HomeScreenState._accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  ctaLabel,
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
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MiniStatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _HomeScreenState._cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _HomeScreenState._softBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: _HomeScreenState._accent, size: 22),
            const SizedBox(height: 14),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: _HomeScreenState._textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _HomeScreenState._textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _HomeScreenState._cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _HomeScreenState._softBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: _HomeScreenState._textPrimary,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _LabelValueRow extends StatelessWidget {
  final String label;
  final String value;

  const _LabelValueRow({
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
              color: _HomeScreenState._textSecondary,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          value,
          style: const TextStyle(
            color: _HomeScreenState._textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _MilestoneChip extends StatelessWidget {
  final String label;
  final bool reached;

  const _MilestoneChip({
    required this.label,
    required this.reached,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: reached ? _HomeScreenState._softAccent : const Color(0xFFF7F3ED),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: reached
              ? const Color(0xFFFFD7A4)
              : _HomeScreenState._softBorder,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: reached
              ? _HomeScreenState._accent
              : _HomeScreenState._textSecondary,
        ),
      ),
    );
  }
}

class _JourneyRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _JourneyRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _HomeScreenState._softAccent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: _HomeScreenState._accent,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: _HomeScreenState._textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _HomeScreenState._textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

extension _FirstOrNullExtension<E> on List<E> {
  E? get firstOrNull => isEmpty ? null : first;
}