import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Initialize timezone database (for scheduled notifications)
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);
    await _requestPermissions();
    await _createNotificationChannels();
  }

  static Future<void> _createNotificationChannels() async {
    // Create notification channels
    const blockedAppsChannel = AndroidNotificationChannel(
      'blocked_apps',
      'Blocked Apps',
      description: 'Notifications when blocked apps are accessed',
      importance: Importance.high,
    );

    const focusStartChannel = AndroidNotificationChannel(
      'focus_channel',
      'Focus Mode',
      description: 'Notifications for focus mode start',
      importance: Importance.high,
    );

    const focusCompleteChannel = AndroidNotificationChannel(
      'focus_complete',
      'Focus Complete',
      description: 'Focus completion notifications',
      importance: Importance.high,
    );

    const streakChannel = AndroidNotificationChannel(
      'streak_channel',
      'Focus Streaks',
      description: 'Focus streak notifications',
      importance: Importance.defaultImportance,
    );

    const dailyJournalChannel = AndroidNotificationChannel(
      'daily_journal',
      'Daily Journal Reminder',
      description: 'Daily reminder to write your journal',
      importance: Importance.high,
    );

    const moodTrackerChannel = AndroidNotificationChannel(
      'mood_tracker',
      'Mood Tracker Reminder',
      description: 'Daily reminder to track your mood',
      importance: Importance.high,
    );

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(blockedAppsChannel);
    await androidPlugin?.createNotificationChannel(focusStartChannel);
    await androidPlugin?.createNotificationChannel(focusCompleteChannel);
    await androidPlugin?.createNotificationChannel(streakChannel);
    await androidPlugin?.createNotificationChannel(dailyJournalChannel);
    await androidPlugin?.createNotificationChannel(moodTrackerChannel);
  }

  static Future<void> _requestPermissions() async {
    // iOS permissions (Android controlled via system app settings)
    final iosPlugin = _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// Schedule a daily notification at 22:00 local time (production mode).
  static Future<void> scheduleDailyJournalReminder() async {
    // Cancel any existing notification with this ID to avoid duplicates
    await _notifications.cancel(2000);
    
    final now = tz.TZDateTime.now(tz.local);
    // Next 22:00 local
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 22, 0);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'daily_journal',
      'Daily Journal Reminder',
      channelDescription: 'Daily reminder to write your MindQuest journal',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF6B46C1),
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    // Daily schedule at 22:00 local time.
    await _notifications.zonedSchedule(
  2000, // id
  '📝 Evening Reflection',
  '🌿 Your journal is here whenever you\'re ready.',
  scheduled, // MUST be tz.TZDateTime
  notificationDetails,
  androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
  matchDateTimeComponents: DateTimeComponents.time,
  payload: 'evening_reflection',
);
    print('Scheduled daily journal reminder for $scheduled (local time: ${now.hour}:${now.minute.toString().padLeft(2, '0')})');
  }

  /// Schedule a daily notification at 21:00 (9 PM) local time for mood tracking.
  static Future<void> scheduleDailyMoodReminder() async {
    // Cancel any existing notification with this ID to avoid duplicates
    await _notifications.cancel(3000);
    
    final now = tz.TZDateTime.now(tz.local);
    // Next 21:00 local (9 PM)
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 21, 0);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'mood_tracker',
      'Mood Tracker Reminder',
      channelDescription: 'Daily reminder to track your mood',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF6B46C1),
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    // Daily schedule at 21:00 local time (9 PM).
    await _notifications.zonedSchedule(
      3000, // id
      '😊 Track Your Mood',
      'How are you feeling today? Take a moment to track your mood.',
      scheduled, // MUST be tz.TZDateTime
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'mood_tracking',
    );
    print('Scheduled daily mood reminder for $scheduled (local time: ${now.hour}:${now.minute.toString().padLeft(2, '0')})');
  }

  /// Debug helper: show a test notification after a short delay (no scheduling).
  static Future<void> debugOneShotTestAfter(Duration delay) async {
    await Future.delayed(delay);
    await showTestNotification();
  }

  /// Helper for manual testing: show an immediate notification.
  static Future<void> showTestNotification() async {
    final androidDetails = AndroidNotificationDetails(
      'focus_channel',
      'Focus Mode',
      channelDescription: 'Notifications for focus mode',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF6B46C1),
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      9999,
      'Test Notification',
      'If you see this, notifications are working.',
      notificationDetails,
    );
  }

  static Future<void> showFocusStartNotification() async {
    final androidDetails = AndroidNotificationDetails(
      'focus_channel',
      'Focus Mode',
      channelDescription: 'Notifications for focus mode',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF6B46C1),
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      1,
      '🎯 Focus Mode Started',
      'Stay focused! Your blocked apps are now restricted.',
      notificationDetails,
    );
  }

  static Future<void> showFocusCompleteNotification(int xpEarned) async {
    final androidDetails = AndroidNotificationDetails(
      'focus_complete',
      'Focus Complete',
      channelDescription: 'Focus completion notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF45D9A8),
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      2,
      '🎉 Focus Session Complete!',
      'Great job! You earned $xpEarned XP!',
      notificationDetails,
    );
  }

  static Future<void> showStreakNotification(int streak) async {
    final androidDetails = AndroidNotificationDetails(
      'streak_channel',
      'Focus Streaks',
      channelDescription: 'Focus streak notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF6B46C1),
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      3,
      '🔥 Focus Streak!',
      'Amazing! You have a $streak day focus streak!',
      notificationDetails,
    );
  }

  static Future<void> showBlockedAppNotification(String appName) async {
    final androidDetails = AndroidNotificationDetails(
      'blocked_apps',
      'Blocked Apps',
      channelDescription: 'Notifications when blocked apps are accessed',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF6B46C1),
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      999,
      '🚫 App Blocked During Focus',
      'You tried to open $appName! Stay focused! 💪',
      notificationDetails,
    );
  }
}
