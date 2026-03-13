import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class ReminderService {
  ReminderService._();

  static final ReminderService instance = ReminderService._();

  final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const int _dailyReminderId = 1001;
  static const String _channelId = 'ramakoti_daily_reminder';
  static const String _channelName = 'Ramakoti Daily Reminder';
  static const String _channelDescription =
      'Daily reminder to write Jai Shri Ram';

  static const String _keyEnabled = 'daily_reminder_enabled';
  static const String _keyHour = 'daily_reminder_hour';
  static const String _keyMinute = 'daily_reminder_minute';

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;

    tz_data.initializeTimeZones();

    try {
      final currentTimeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(currentTimeZone.identifier));
    } catch (_) {}

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const macSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: macSettings,
    );

    await _plugin.initialize(
      settings: settings,
    );

    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    await initialize();

    bool granted = true;

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    final androidGranted =
    await androidPlugin?.requestNotificationsPermission();
    if (androidGranted != null) {
      granted = granted && androidGranted;
    }

    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    final iosGranted = await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    if (iosGranted != null) {
      granted = granted && iosGranted;
    }

    final macPlugin = _plugin
        .resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>();

    final macGranted = await macPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    if (macGranted != null) {
      granted = granted && macGranted;
    }

    return granted;
  }

  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    if (kIsWeb) return;

    await initialize();

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();
    const macDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: macDetails,
    );

    await _plugin.cancel(
      id: _dailyReminderId,
    );

    await _plugin.zonedSchedule(
      id: _dailyReminderId,
      title: 'Ramakoti Reminder',
      body: 'Time to write Jai Shri Ram.',
      scheduledDate: scheduled,
      notificationDetails: details,
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, true);
    await prefs.setInt(_keyHour, hour);
    await prefs.setInt(_keyMinute, minute);
  }

  Future<void> cancelDailyReminder() async {
    if (kIsWeb) return;

    await initialize();

    await _plugin.cancel(
      id: _dailyReminderId,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, false);
    await prefs.remove(_keyHour);
    await prefs.remove(_keyMinute);
  }

  Future<List<PendingNotificationRequest>> pendingReminders() async {
    if (kIsWeb) return const [];

    await initialize();
    return _plugin.pendingNotificationRequests();
  }

  Future<ReminderInfo> getReminderInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_keyEnabled) ?? false;
    final hour = prefs.getInt(_keyHour);
    final minute = prefs.getInt(_keyMinute);

    return ReminderInfo(
      isEnabled: enabled,
      hour: hour,
      minute: minute,
    );
  }
}

class ReminderInfo {
  final bool isEnabled;
  final int? hour;
  final int? minute;

  const ReminderInfo({
    required this.isEnabled,
    required this.hour,
    required this.minute,
  });
}