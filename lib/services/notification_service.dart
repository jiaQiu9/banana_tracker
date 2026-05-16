import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
@pragma('vm:entry-point')
void onNotificationFired(NotificationResponse response) {
  debugPrint(
      '[Notifications] Fired: id=${response.id} payload=${response.payload}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'banana_reminder';
  static const _channelName = 'Banana Reminders';
  static const _reminderId = 0;
  static const _testId = 99;

  Future<void> init() async {
    debugPrint('[Notifications] Initializing...');

    tz_data.initializeTimeZones();
    final tzInfo = await FlutterTimezone.getLocalTimezone();
    final raw = tzInfo.toString();
    final match = RegExp(r'TimezoneInfo\(([^,]+)').firstMatch(raw);
    final tzName = match?.group(1)?.trim() ?? 'UTC';
    debugPrint('[Notifications] Timezone parsed: $tzName');
    try {
      tz.setLocalLocation(tz.getLocation(tzName));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
      debugPrint('[Notifications] Timezone not found, falling back to UTC');
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: onNotificationFired,
      onDidReceiveBackgroundNotificationResponse: onNotificationFired,
    );
    debugPrint('[Notifications] Plugin initialized');

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Daily reminder to log your bananas',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );

    final plugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await plugin?.createNotificationChannel(channel);
    await plugin?.requestNotificationsPermission();
    await plugin?.requestExactAlarmsPermission();
    final hasExactAlarm =
        await plugin?.canScheduleExactNotifications() ?? false;
    debugPrint('[Notifications] Can schedule exact alarms: $hasExactAlarm');
    if (!hasExactAlarm) {
      debugPrint('[Notifications] WARNING: Exact alarm permission denied. '
          'Notifications will not fire on time.');
    }
    debugPrint('[Notifications] Permissions requested');
  }

  NotificationDetails get _notificationDetails => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Daily reminder to log your bananas',
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          enableVibration: true,
        ),
      );

  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<void> scheduleDailyReminder(TimeOfDay time) async {
    debugPrint('[Notifications] Scheduling for ${time.hour}:${time.minute}');
    await cancelReminder();

    final scheduledDate = _nextInstanceOfTime(time);
    debugPrint('[Notifications] Scheduled time: $scheduledDate');
    debugPrint('[Notifications] Current time:   ${tz.TZDateTime.now(tz.local)}');
    debugPrint(
        '[Notifications] Is future: ${scheduledDate.isAfter(tz.TZDateTime.now(tz.local))}');

    await _plugin.zonedSchedule(
      id: _reminderId,
      title: '🍌 Banana reminder!',
      body: "Don't forget to log your bananas today.",
      scheduledDate: scheduledDate,
      notificationDetails: _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    debugPrint('[Notifications] Scheduled successfully');
  }

  Future<void> cancelReminder() async {
    debugPrint('[Notifications] Reminder cancelled');
    await _plugin.cancel(id: _reminderId);
  }

  Future<void> scheduleTestNotification() async {
    final scheduled =
        tz.TZDateTime.now(tz.local).add(const Duration(seconds: 30));
    debugPrint('[Notifications] Test firing at: $scheduled');
    await _plugin.zonedSchedule(
      id: _testId,
      title: '🍌 Test notification',
      body: 'Notifications are working!',
      scheduledDate: scheduled,
      notificationDetails: _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
    debugPrint('[Notifications] Test scheduled for: $scheduled');
    debugPrint('[Notifications] Seconds from now: '
        '${scheduled.difference(tz.TZDateTime.now(tz.local)).inSeconds}');
  }
}
