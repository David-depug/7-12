import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Model for storing screen time notification settings
class ScreenTimeSettingsModel {
  // Daily goal in hours
  double dailyGoalHours;
  
  // Notification preferences
  bool notificationsEnabled;
  bool breakReminders;
  bool dailySummary;
  bool usageLimitWarnings;
  bool achievementNotifications;
  
  // Daily summary time (24-hour format, e.g., "20:00")
  String dailySummaryTime;
  
  // Quiet hours
  String quietHoursStart;
  String quietHoursEnd;
  
  // App-specific limits (package name -> limit in minutes)
  Map<String, int> appLimits;
  
  // Break reminder interval in minutes
  int breakReminderInterval;
  
  // Usage streak (days)
  int currentStreak;
  DateTime? lastStreakUpdate;

  ScreenTimeSettingsModel({
    this.dailyGoalHours = 5.0,
    this.notificationsEnabled = true,
    this.breakReminders = true,
    this.dailySummary = true,
    this.usageLimitWarnings = true,
    this.achievementNotifications = true,
    this.dailySummaryTime = '20:00',
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '07:00',
    this.appLimits = const {},
    this.breakReminderInterval = 120, // 2 hours default
    this.currentStreak = 0,
    this.lastStreakUpdate,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'daily_goal_hours': dailyGoalHours,
      'notifications_enabled': notificationsEnabled,
      'break_reminders': breakReminders,
      'daily_summary': dailySummary,
      'usage_limit_warnings': usageLimitWarnings,
      'achievement_notifications': achievementNotifications,
      'daily_summary_time': dailySummaryTime,
      'quiet_hours_start': quietHoursStart,
      'quiet_hours_end': quietHoursEnd,
      'app_limits': appLimits,
      'break_reminder_interval': breakReminderInterval,
      'current_streak': currentStreak,
      'last_streak_update': lastStreakUpdate?.toIso8601String(),
    };
  }

  /// Create from JSON
  factory ScreenTimeSettingsModel.fromJson(Map<String, dynamic> json) {
    return ScreenTimeSettingsModel(
      dailyGoalHours: (json['daily_goal_hours'] as num?)?.toDouble() ?? 5.0,
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
      breakReminders: json['break_reminders'] as bool? ?? true,
      dailySummary: json['daily_summary'] as bool? ?? true,
      usageLimitWarnings: json['usage_limit_warnings'] as bool? ?? true,
      achievementNotifications: json['achievement_notifications'] as bool? ?? true,
      dailySummaryTime: json['daily_summary_time'] as String? ?? '20:00',
      quietHoursStart: json['quiet_hours_start'] as String? ?? '22:00',
      quietHoursEnd: json['quiet_hours_end'] as String? ?? '07:00',
      appLimits: Map<String, int>.from(json['app_limits'] as Map? ?? {}),
      breakReminderInterval: json['break_reminder_interval'] as int? ?? 120,
      currentStreak: json['current_streak'] as int? ?? 0,
      lastStreakUpdate: json['last_streak_update'] != null
          ? DateTime.parse(json['last_streak_update'] as String)
          : null,
    );
  }

  /// Save to SharedPreferences
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(toJson());
    await prefs.setString('screen_time_settings', jsonString);
  }

  /// Load from SharedPreferences
  static Future<ScreenTimeSettingsModel> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('screen_time_settings');
    
    if (jsonString == null) {
      // Return default settings
      return ScreenTimeSettingsModel();
    }
    
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return ScreenTimeSettingsModel.fromJson(json);
    } catch (e) {
      // If parsing fails, return default settings
      return ScreenTimeSettingsModel();
    }
  }

  /// Check if currently in quiet hours
  bool isInQuietHours() {
    final now = DateTime.now();
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    final start = quietHoursStart;
    final end = quietHoursEnd;
    
    // Handle case where quiet hours span midnight
    if (start.compareTo(end) > 0) {
      return currentTime.compareTo(start) >= 0 || currentTime.compareTo(end) < 0;
    } else {
      return currentTime.compareTo(start) >= 0 && currentTime.compareTo(end) < 0;
    }
  }

  /// Get daily goal in seconds
  int get dailyGoalSeconds => (dailyGoalHours * 3600).toInt();

  /// Get daily goal in minutes
  int get dailyGoalMinutes => (dailyGoalHours * 60).toInt();

  /// Copy with method for updating specific fields
  ScreenTimeSettingsModel copyWith({
    double? dailyGoalHours,
    bool? notificationsEnabled,
    bool? breakReminders,
    bool? dailySummary,
    bool? usageLimitWarnings,
    bool? achievementNotifications,
    String? dailySummaryTime,
    String? quietHoursStart,
    String? quietHoursEnd,
    Map<String, int>? appLimits,
    int? breakReminderInterval,
    int? currentStreak,
    DateTime? lastStreakUpdate,
  }) {
    return ScreenTimeSettingsModel(
      dailyGoalHours: dailyGoalHours ?? this.dailyGoalHours,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      breakReminders: breakReminders ?? this.breakReminders,
      dailySummary: dailySummary ?? this.dailySummary,
      usageLimitWarnings: usageLimitWarnings ?? this.usageLimitWarnings,
      achievementNotifications: achievementNotifications ?? this.achievementNotifications,
      dailySummaryTime: dailySummaryTime ?? this.dailySummaryTime,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      appLimits: appLimits ?? this.appLimits,
      breakReminderInterval: breakReminderInterval ?? this.breakReminderInterval,
      currentStreak: currentStreak ?? this.currentStreak,
      lastStreakUpdate: lastStreakUpdate ?? this.lastStreakUpdate,
    );
  }
}


