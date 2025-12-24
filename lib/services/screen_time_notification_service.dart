import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import '../models/screen_time_settings_model.dart';
import 'screen_time_service.dart';

/// Service for managing screen time notifications
class ScreenTimeNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _backgroundTaskName = 'screenTimeMonitor';
  static const String _dailySummaryTaskName = 'dailySummary';

  /// Initialize the notification service
  static Future<void> initialize() async {
    // Initialize flutter_local_notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    
    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request notification permissions (Android 13+)
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Initialize Workmanager for background tasks
    await Workmanager().initialize(_callbackDispatcher, isInDebugMode: false);

    // Start background monitoring
    await startBackgroundMonitoring();
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    // Navigate to analytics screen when notification is tapped
    // This would need to be handled by the app's navigation system
  }

  /// Start background monitoring
  static Future<void> startBackgroundMonitoring() async {
    final settings = await ScreenTimeSettingsModel.load();
    
    if (!settings.notificationsEnabled) {
      await Workmanager().cancelAll();
      return;
    }

    // Register periodic task to check usage every 15 minutes
    await Workmanager().registerPeriodicTask(
      _backgroundTaskName,
      _backgroundTaskName,
      frequency: const Duration(minutes: 15),
    );

    // Schedule daily summary
    await scheduleDailySummary();
  }

  /// Stop background monitoring
  static Future<void> stopBackgroundMonitoring() async {
    await Workmanager().cancelAll();
  }

  /// Schedule daily summary notification
  static Future<void> scheduleDailySummary() async {
    final settings = await ScreenTimeSettingsModel.load();
    
    if (!settings.dailySummary) return;

    // Parse the time
    final timeParts = settings.dailySummaryTime.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    // Calculate next occurrence
    var scheduledDate = DateTime.now();
    scheduledDate = DateTime(
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
      hour,
      minute,
    );

    // If time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(DateTime.now())) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Register one-time task
    await Workmanager().registerOneOffTask(
      _dailySummaryTaskName,
      _dailySummaryTaskName,
      initialDelay: scheduledDate.difference(DateTime.now()),
    );
  }

  /// Check usage limits and send notifications if needed
  static Future<void> checkUsageLimits() async {
    try {
      final settings = await ScreenTimeSettingsModel.load();
      
      if (!settings.notificationsEnabled || settings.isInQuietHours()) {
        return;
      }

      // Get today's usage
      final usageStats = await ScreenTimeService.getUltraAccurateUsageStats(period: 'daily');
      final totalUsageMs = usageStats.fold<int>(0, (sum, item) => sum + (item['usageTime'] as int));
      final totalUsageSeconds = totalUsageMs ~/ 1000;

      final goalSeconds = settings.dailyGoalSeconds;
      final usagePercentage = (totalUsageSeconds / goalSeconds * 100).toInt();

      // Check if we should send warning notifications
      final prefs = await SharedPreferences.getInstance();
      final last75Warning = prefs.getInt('last_75_warning') ?? 0;
      final last100Warning = prefs.getInt('last_100_warning') ?? 0;
      final today = DateTime.now().day;

      if (settings.usageLimitWarnings) {
        // 75% warning
        if (usagePercentage >= 75 && usagePercentage < 100 && last75Warning != today) {
          await _send75PercentWarning(totalUsageSeconds, goalSeconds);
          await prefs.setInt('last_75_warning', today);
        }

        // 100% warning
        if (usagePercentage >= 100 && last100Warning != today) {
          await _send100PercentWarning(totalUsageSeconds, goalSeconds);
          await prefs.setInt('last_100_warning', today);
        }
      }

      // Check app-specific limits
      await _checkAppLimits(usageStats, settings);

      // Check for break reminders
      if (settings.breakReminders) {
        await _checkBreakReminder(totalUsageSeconds, settings);
      }

    } catch (e) {
      print('Error checking usage limits: $e');
    }
  }

  /// Check app-specific limits
  static Future<void> _checkAppLimits(List<Map<String, dynamic>> usageStats, ScreenTimeSettingsModel settings) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().day;

    for (final app in usageStats) {
      final packageName = app['packageName'] as String;
      final usageTimeMs = app['usageTime'] as int;
      final usageTimeMinutes = usageTimeMs ~/ (1000 * 60);

      if (settings.appLimits.containsKey(packageName)) {
        final limit = settings.appLimits[packageName]!;
        
        if (usageTimeMinutes >= limit) {
          final warningKey = 'app_limit_warning_${packageName}_$today';
          final alreadyWarned = prefs.getBool(warningKey) ?? false;

          if (!alreadyWarned) {
            await _sendAppLimitNotification(app['appName'] as String, limit);
            await prefs.setBool(warningKey, true);
          }
        }
      }
    }
  }

  /// Check if break reminder is needed
  static Future<void> _checkBreakReminder(int totalUsageSeconds, ScreenTimeSettingsModel settings) async {
    final prefs = await SharedPreferences.getInstance();
    final lastBreakReminder = prefs.getInt('last_break_reminder') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    final intervalSeconds = settings.breakReminderInterval * 60;
    
    // Send reminder if enough time has passed since last reminder
    if (now - lastBreakReminder >= intervalSeconds && totalUsageSeconds >= intervalSeconds) {
      await _sendBreakReminder(settings.breakReminderInterval);
      await prefs.setInt('last_break_reminder', now);
    }
  }

  /// Send 75% usage warning
  static Future<void> _send75PercentWarning(int totalSeconds, int goalSeconds) async {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final goalHours = goalSeconds ~/ 3600;

    await _showNotification(
      id: 1,
      title: '⚠️ Screen Time Alert',
      body: 'You\'ve used ${hours}h ${minutes}m today (75% of your ${goalHours}h goal). Try to limit usage for the rest of the day.',
      priority: Priority.high,
    );
  }

  /// Send 100% usage warning
  static Future<void> _send100PercentWarning(int totalSeconds, int goalSeconds) async {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final goalHours = goalSeconds ~/ 3600;

    await _showNotification(
      id: 2,
      title: '🚨 Daily Goal Reached',
      body: 'You\'ve reached your ${goalHours}h screen time goal (${hours}h ${minutes}m used). Consider taking a break!',
      priority: Priority.high,
    );
  }

  /// Send app limit notification
  static Future<void> _sendAppLimitNotification(String appName, int limitMinutes) async {
    await _showNotification(
      id: 3,
      title: '🚨 App Limit Reached',
      body: 'You\'ve reached your ${limitMinutes}-minute limit for $appName today. Taking a break will help you stay focused!',
      priority: Priority.high,
    );
  }

  /// Send break reminder
  static Future<void> _sendBreakReminder(int intervalMinutes) async {
    await _showNotification(
      id: 4,
      title: '👀 Time for a Break!',
      body: 'You\'ve been using your phone continuously. Give your eyes a rest!',
      priority: Priority.defaultPriority,
    );
  }

  /// Send daily summary
  static Future<void> sendDailySummary() async {
    try {
      final settings = await ScreenTimeSettingsModel.load();
      
      if (!settings.dailySummary || settings.isInQuietHours()) {
        // Reschedule for tomorrow
        await scheduleDailySummary();
        return;
      }

      // Get today's and yesterday's usage
      final todayStats = await ScreenTimeService.getUltraAccurateUsageStats(period: 'daily');
      final yesterdayStats = await ScreenTimeService.getUltraAccurateUsageStats(period: 'yesterday');

      final todayTotalMs = todayStats.fold<int>(0, (sum, item) => sum + (item['usageTime'] as int));
      final yesterdayTotalMs = yesterdayStats.fold<int>(0, (sum, item) => sum + (item['usageTime'] as int));

      final todaySeconds = todayTotalMs ~/ 1000;
      final yesterdaySeconds = yesterdayTotalMs ~/ 1000;

      final hours = todaySeconds ~/ 3600;
      final minutes = (todaySeconds % 3600) ~/ 60;

      // Calculate change
      final change = yesterdaySeconds > 0
          ? ((todaySeconds - yesterdaySeconds) / yesterdaySeconds * 100).toInt()
          : 0;
      final changeText = change > 0 ? '↑$change%' : change < 0 ? '↓${-change}%' : 'Same';

      // Get top 3 apps
      final topApps = List<Map<String, dynamic>>.from(todayStats)
        ..sort((a, b) => (b['usageTime'] as int).compareTo(a['usageTime'] as int));
      final top3 = topApps.take(3).map((app) {
        final appTime = (app['usageTime'] as int) ~/ (1000 * 60);
        return '${app['appName']} (${appTime}m)';
      }).join(', ');

      // Check if met goal
      final metGoal = todaySeconds <= settings.dailyGoalSeconds;
      final emoji = metGoal ? '✨' : '⚠️';
      final goalText = metGoal
          ? 'Great job staying under your ${settings.dailyGoalHours.toInt()}h goal!'
          : 'You exceeded your ${settings.dailyGoalHours.toInt()}h goal.';

      await _showNotification(
        id: 5,
        title: '📊 Today\'s Screen Time',
        body: '🕐 ${hours}h ${minutes}m ($changeText from yesterday)\n📱 Top Apps: $top3\n$emoji $goalText',
        priority: Priority.high,
      );

      // Update streak
      if (metGoal) {
        await _updateStreak(settings);
      } else {
        await _resetStreak();
      }

      // Reschedule for tomorrow
      await scheduleDailySummary();

    } catch (e) {
      print('Error sending daily summary: $e');
    }
  }

  /// Update streak for meeting goal
  static Future<void> _updateStreak(ScreenTimeSettingsModel settings) async {
    final today = DateTime.now();
    final lastUpdate = settings.lastStreakUpdate;

    if (lastUpdate == null || !_isSameDay(lastUpdate, today)) {
      final newStreak = settings.currentStreak + 1;
      final updatedSettings = settings.copyWith(
        currentStreak: newStreak,
        lastStreakUpdate: today,
      );
      await updatedSettings.save();

      // Send achievement notification for milestones
      if (settings.achievementNotifications) {
        if (newStreak == 3) {
          await sendAchievement('🔥 3-Day Streak! Keep it going!');
        } else if (newStreak == 7) {
          await sendAchievement('🎉 7-Day Streak! You\'ve met your goal for a full week!');
        } else if (newStreak == 30) {
          await sendAchievement('🏆 30-Day Streak! Amazing consistency!');
        }
      }
    }
  }

  /// Reset streak
  static Future<void> _resetStreak() async {
    final settings = await ScreenTimeSettingsModel.load();
    final updatedSettings = settings.copyWith(
      currentStreak: 0,
      lastStreakUpdate: DateTime.now(),
    );
    await updatedSettings.save();
  }

  /// Check if two dates are the same day
  static bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Send achievement notification
  static Future<void> sendAchievement(String message) async {
    final settings = await ScreenTimeSettingsModel.load();
    
    if (!settings.achievementNotifications || settings.isInQuietHours()) {
      return;
    }

    await _showNotification(
      id: 6,
      title: 'Achievement Unlocked!',
      body: message,
      priority: Priority.high,
    );
  }

  /// Show a notification
  static Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    Priority priority = Priority.defaultPriority,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'screen_time_channel',
      'Screen Time Notifications',
      channelDescription: 'Notifications for screen time tracking and reminders',
      importance: priority == Priority.high ? Importance.high : Importance.defaultImportance,
      priority: priority,
      styleInformation: BigTextStyleInformation(body),
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
    );
  }

  /// Cancel all notifications
  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
    await Workmanager().cancelAll();
  }
}

/// Callback dispatcher for Workmanager background tasks
@pragma('vm:entry-point')
void _callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      switch (task) {
        case ScreenTimeNotificationService._backgroundTaskName:
          await ScreenTimeNotificationService.checkUsageLimits();
          break;
        case ScreenTimeNotificationService._dailySummaryTaskName:
          await ScreenTimeNotificationService.sendDailySummary();
          break;
      }
      return true;
    } catch (e) {
      print('Background task error: $e');
      return false;
    }
  });
}

