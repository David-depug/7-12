import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
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
    // Create blocked apps notification channel
    const blockedAppsChannel = AndroidNotificationChannel(
      'blocked_apps',
      'Blocked Apps',
      description: 'Notifications when blocked apps are accessed',
      importance: Importance.high,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(blockedAppsChannel);
  }

  static Future<void> _requestPermissions() async {
    // Permissions are handled by the block_app package
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
