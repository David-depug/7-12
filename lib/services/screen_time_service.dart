import 'dart:async';
import 'package:flutter/services.dart';
import 'package:usage_stats/usage_stats.dart';
import '../models/screen_time_model.dart';

class ScreenTimeService {
  static const MethodChannel _channel = MethodChannel('screen_time_service');
  static ScreenTimeModel? _screenTimeModel;
  static Timer? _usageTimer;

  // Initialize the service
  static Future<void> initialize(ScreenTimeModel screenTimeModel) async {
    _screenTimeModel = screenTimeModel;
    
    // Set up method call handler
    _channel.setMethodCallHandler(_handleMethodCall);
    
    // Start periodic usage tracking
    _startUsageTracking();
  }

  // Handle method calls from native code
  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onAppUsageChanged':
        final String packageName = call.arguments['packageName'];
        final String appName = call.arguments['appName'];
        final int usageTimeMinutes = call.arguments['usageTimeMinutes'];
        final String category = call.arguments['category'] ?? 'Unknown';
        
        if (_screenTimeModel != null) {
          await _screenTimeModel!.addAppUsage(
            packageName,
            appName,
            Duration(minutes: usageTimeMinutes),
            category,
          );
        }
        break;
        
      case 'onContentBlocked':
        final String content = call.arguments['content'];
        final String reason = call.arguments['reason'];
        
        // Show notification or handle blocked content
        _showContentBlockedNotification(content, reason);
        break;
        
      case 'onAppBlocked':
        final String appName = call.arguments['appName'];
        
        // Show notification that app is blocked
        _showAppBlockedNotification(appName);
        break;
    }
  }

  // Start periodic usage tracking
  static void _startUsageTracking() {
    _usageTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _trackCurrentAppUsage();
    });
  }

  // Track current app usage using usage_stats
  static Future<void> _trackCurrentAppUsage() async {
    try {
      // Check if we have permission
      bool hasPermission = await checkUsageStatsPermission();
      if (!hasPermission) {
        return;
      }

      // Get usage stats for the last hour
      DateTime endDate = DateTime.now();
      DateTime startDate = endDate.subtract(const Duration(hours: 1));
      
      List<UsageInfo> usageStats = await UsageStats.queryUsageStats(startDate, endDate);
      
      if (_screenTimeModel != null) {
        for (var info in usageStats) {
          final packageName = info.packageName ?? 'unknown';
          final appName = _getAppName(packageName);
          final usageTimeMs = int.tryParse(info.totalTimeInForeground ?? '0') ?? 0;
          final category = _getAppCategory(packageName);
          
          // Only track if app is not blocked and has meaningful usage
          if (usageTimeMs > 0 && !_screenTimeModel!.isAppBlocked(packageName)) {
            await _screenTimeModel!.addAppUsage(
              packageName,
              appName,
              Duration(milliseconds: usageTimeMs),
              category,
            );
          }
        }
      }
    } catch (e) {
      print('Error tracking app usage: $e');
    }
  }

  // Get real usage statistics from Android using usage_stats
  static Future<List<Map<String, dynamic>>> getRealUsageStats() async {
    try {
      bool hasPermission = await checkUsageStatsPermission();
      if (!hasPermission) {
        return [];
      }

      DateTime endDate = DateTime.now();
      DateTime startDate = DateTime(endDate.year, endDate.month, endDate.day); // Start of today
      
      List<UsageInfo> usageStats = await UsageStats.queryUsageStats(startDate, endDate);
      
      print('=== SCREEN TIME SERVICE DEBUG ===');
      print('Query period: $startDate to $endDate');
      print('Raw usage stats count: ${usageStats.length}');
      
      if (usageStats.isNotEmpty) {
        print('Sample raw UsageInfo:');
        print('  Package: ${usageStats.first.packageName}');
        print('  TotalTimeInForeground: ${usageStats.first.totalTimeInForeground}');
        print('  LastTimeUsed: ${usageStats.first.lastTimeUsed}');
        print('  FirstTimeStamp: ${usageStats.first.firstTimeStamp}');
        print('  LastTimeStamp: ${usageStats.first.lastTimeStamp}');
        
        // Show all apps with their raw times
        print('\n=== ALL APPS WITH USAGE ===');
        for (int i = 0; i < usageStats.length && i < 10; i++) {
          final info = usageStats[i];
          final rawTime = int.tryParse(info.totalTimeInForeground ?? '0') ?? 0;
          final timeInMinutes = rawTime / (1000 * 60);
          print('${i + 1}. ${info.packageName}: ${rawTime}ms = ${timeInMinutes.toStringAsFixed(1)}min');
        }
      }
      
      Map<String, Map<String, dynamic>> appMap = {};
      for (var info in usageStats) {
        final packageName = info.packageName ?? 'unknown';
        final appName = _getAppName(packageName);
        final usageTimeMs = int.tryParse(info.totalTimeInForeground ?? '0') ?? 0;
        final category = _getAppCategory(packageName);
        
        // Filter out system apps and launchers that shouldn't count toward screen time
        // Also filter out apps with very small usage (less than 10 seconds)
        if (usageTimeMs > 10000) { // 10 seconds in milliseconds
          if (_isSystemApp(packageName, appName)) {
            print('Filtered out system app: $appName ($packageName) - ${usageTimeMs}ms');
          } else {
            // Use package name as key to avoid duplicates
            if (appMap.containsKey(packageName)) {
              // If app already exists, add the usage time
              final existing = appMap[packageName]!;
              final existingTime = existing['usageTime'] as int;
              appMap[packageName] = {
                'packageName': packageName,
                'appName': appName,
                'usageTime': existingTime + usageTimeMs, // Add to existing time
                'category': category,
                'lastTimeUsed': info.lastTimeUsed,
              };
              print('Merged duplicate: $appName - added ${usageTimeMs}ms to existing ${existingTime}ms');
            } else {
              appMap[packageName] = {
                'packageName': packageName,
                'appName': appName,
                'usageTime': usageTimeMs,
                'category': category,
                'lastTimeUsed': info.lastTimeUsed,
              };
            }
          }
        } else if (usageTimeMs > 0) {
          print('Filtered out short usage: $appName ($packageName) - ${usageTimeMs}ms');
        }
      }
      
      // Convert map to list
      List<Map<String, dynamic>> result = appMap.values.toList();
      
      print('\n=== FILTERING RESULTS ===');
      print('Processed apps with usage: ${result.length}');
      
      if (result.isNotEmpty) {
        print('Top processed app: ${result.first}');
        
        // Calculate total time from processed apps
        final totalProcessedTime = result.fold(0, (sum, item) => sum + (item['usageTime'] as int));
        final totalProcessedMinutes = totalProcessedTime / (1000 * 60);
        final totalProcessedHours = totalProcessedMinutes / 60;
        
        print('Total processed time: ${totalProcessedTime}ms = ${totalProcessedMinutes.toStringAsFixed(1)}min = ${totalProcessedHours.toStringAsFixed(2)}hours');
      }
      
      // Sort by usage time
      result.sort((a, b) => (b['usageTime'] as int).compareTo(a['usageTime'] as int));
      
      return result;
    } catch (e) {
      print('Error getting real usage stats: $e');
      return [];
    }
  }

  // Get more accurate usage stats by trying different time periods
  static Future<List<Map<String, dynamic>>> getAccurateUsageStats({String period = 'today'}) async {
    try {
      bool hasPermission = await checkUsageStatsPermission();
      if (!hasPermission) {
        print('No usage stats permission');
        return [];
      }

      // Get data for the specified time period
      final now = DateTime.now();
      List<UsageInfo> bestStats;
      String periodName;
      
      switch (period) {
        case 'yesterday':
          final yesterdayStart = DateTime(now.year, now.month, now.day - 1);
          final todayStart = DateTime(now.year, now.month, now.day);
          bestStats = await UsageStats.queryUsageStats(yesterdayStart, todayStart);
          periodName = 'yesterday';
          break;
        case 'weekly':
          // Get the start of the current week (Monday)
          final today = DateTime.now();
          final daysSinceMonday = today.weekday - 1;
          final weekStart = DateTime(today.year, today.month, today.day - daysSinceMonday);
          bestStats = await UsageStats.queryUsageStats(weekStart, now);
          periodName = 'this week (since Monday)';
          break;
        case 'monthly':
          final monthAgo = now.subtract(const Duration(days: 30));
          bestStats = await UsageStats.queryUsageStats(monthAgo, now);
          periodName = 'last 30 days';
          break;
        case '3months':
          final threeMonthsAgo = now.subtract(const Duration(days: 90));
          bestStats = await UsageStats.queryUsageStats(threeMonthsAgo, now);
          periodName = 'last 3 months';
          break;
        case '6months':
          final sixMonthsAgo = now.subtract(const Duration(days: 180));
          bestStats = await UsageStats.queryUsageStats(sixMonthsAgo, now);
          periodName = 'last 6 months';
          break;
        case '1year':
          final yearAgo = now.subtract(const Duration(days: 365));
          bestStats = await UsageStats.queryUsageStats(yearAgo, now);
          periodName = 'last year';
          break;
        default: // 'today' or 'daily'
          final todayStart = DateTime(now.year, now.month, now.day);
          bestStats = await UsageStats.queryUsageStats(todayStart, now);
          periodName = 'today';
          break;
      }
      
      print('=== QUERYING $periodName ===');
      print('Found ${bestStats.length} apps for $periodName');
      
      Map<String, Map<String, dynamic>> appMap = {};
      int totalRawTime = 0;
      
      for (var info in bestStats) {
        final packageName = info.packageName ?? 'unknown';
        final appName = _getAppName(packageName);
        final usageTimeMs = int.tryParse(info.totalTimeInForeground ?? '0') ?? 0;
        final category = _getAppCategory(packageName);
        
        totalRawTime += usageTimeMs;
        
        // Filter out system apps and launchers that shouldn't count toward screen time
        // Also filter out apps with very small usage (less than 10 seconds)
        if (usageTimeMs > 10000) { // 10 seconds in milliseconds
          if (_isSystemApp(packageName, appName)) {
            print('Filtered out system app: $appName ($packageName) - ${usageTimeMs}ms');
          } else {
            // Use package name as key to avoid duplicates
            if (appMap.containsKey(packageName)) {
              // If app already exists, add the usage time
              final existing = appMap[packageName]!;
              final existingTime = existing['usageTime'] as int;
              appMap[packageName] = {
                'packageName': packageName,
                'appName': appName,
                'usageTime': existingTime + usageTimeMs, // Add to existing time
                'category': category,
                'lastTimeUsed': info.lastTimeUsed,
              };
              print('Merged duplicate: $appName - added ${usageTimeMs}ms to existing ${existingTime}ms');
            } else {
              appMap[packageName] = {
                'packageName': packageName,
                'appName': appName,
                'usageTime': usageTimeMs,
                'category': category,
                'lastTimeUsed': info.lastTimeUsed,
              };
            }
          }
        } else if (usageTimeMs > 0) {
          print('Filtered out short usage: $appName ($packageName) - ${usageTimeMs}ms');
        }
      }
      
      // Convert map to list
      List<Map<String, dynamic>> result = appMap.values.toList();
      
      print('\n=== ACCURATE USAGE STATS ===');
      print('Total raw time: ${totalRawTime}ms = ${(totalRawTime / (1000 * 60)).toStringAsFixed(1)}min = ${(totalRawTime / (1000 * 60 * 60)).toStringAsFixed(2)}hours');
      print('Filtered apps: ${result.length}');
      
      if (result.isNotEmpty) {
        final totalFilteredTime = result.fold(0, (sum, item) => sum + (item['usageTime'] as int));
        final totalFilteredMinutes = totalFilteredTime / (1000 * 60);
        final totalFilteredHours = totalFilteredMinutes / 60;
        
        print('Total filtered time: ${totalFilteredTime}ms = ${totalFilteredMinutes.toStringAsFixed(1)}min = ${totalFilteredHours.toStringAsFixed(2)}hours');
        print('Top app: ${result.first}');
        
        // Show detailed breakdown of top 5 apps
        print('\n=== TOP 5 APPS BREAKDOWN ===');
        for (int i = 0; i < 5 && i < result.length; i++) {
          final app = result[i];
          final appTime = app['usageTime'] as int;
          final appMinutes = appTime / (1000 * 60);
          final appHours = appMinutes / 60;
          print('${i + 1}. ${app['appName']}: ${appTime}ms = ${appMinutes.toStringAsFixed(1)}min = ${appHours.toStringAsFixed(2)}hours');
        }
      }
      
      // Sort by usage time
      result.sort((a, b) => (b['usageTime'] as int).compareTo(a['usageTime'] as int));
      
      return result;
    } catch (e) {
      print('Error getting accurate usage stats: $e');
      return [];
    }
  }

  // Get ultra-accurate usage stats with very strict filtering
  static Future<List<Map<String, dynamic>>> getUltraAccurateUsageStats({String period = 'today'}) async {
    try {
      bool hasPermission = await checkUsageStatsPermission();
      if (!hasPermission) {
        print('No usage stats permission');
        return [];
      }

      // Get data for the specified time period
      final now = DateTime.now();
      List<UsageInfo> bestStats;
      String periodName;
      
      switch (period) {
        case 'yesterday':
          final yesterdayStart = DateTime(now.year, now.month, now.day - 1);
          final todayStart = DateTime(now.year, now.month, now.day);
          bestStats = await UsageStats.queryUsageStats(yesterdayStart, todayStart);
          periodName = 'yesterday';
          break;
        case 'weekly':
          // Get the start of the current week (Monday)
          final today = DateTime.now();
          final daysSinceMonday = today.weekday - 1;
          final weekStart = DateTime(today.year, today.month, today.day - daysSinceMonday);
          bestStats = await UsageStats.queryUsageStats(weekStart, now);
          periodName = 'this week (since Monday)';
          break;
        case 'monthly':
          final monthAgo = now.subtract(const Duration(days: 30));
          bestStats = await UsageStats.queryUsageStats(monthAgo, now);
          periodName = 'last 30 days';
          break;
        default: // 'today' or 'daily'
          final todayStart = DateTime(now.year, now.month, now.day);
          bestStats = await UsageStats.queryUsageStats(todayStart, now);
          periodName = 'today';
          break;
      }
      
      print('=== ULTRA ACCURATE $periodName ===');
      print('Found ${bestStats.length} apps for $periodName');
      
      Map<String, Map<String, dynamic>> appMap = {};
      int totalRawTime = 0;
      
      for (var info in bestStats) {
        final packageName = info.packageName ?? 'unknown';
        final appName = _getAppName(packageName);
        final usageTimeMs = int.tryParse(info.totalTimeInForeground ?? '0') ?? 0;
        final category = _getAppCategory(packageName);
        
        totalRawTime += usageTimeMs;
        
        // ULTRA STRICT FILTERING - Only count apps with significant usage
        if (usageTimeMs > 60000) { // Only apps used for more than 1 minute
          if (_isSystemApp(packageName, appName)) {
            print('Filtered out system app: $appName ($packageName) - ${usageTimeMs}ms');
          } else {
            // Additional filtering for suspicious apps
            if (_isSuspiciousApp(packageName, appName)) {
              print('Filtered out suspicious app: $appName ($packageName) - ${usageTimeMs}ms');
            } else {
              // Use package name as key to avoid duplicates
              if (appMap.containsKey(packageName)) {
                // If app already exists, add the usage time
                final existing = appMap[packageName]!;
                final existingTime = existing['usageTime'] as int;
                appMap[packageName] = {
                  'packageName': packageName,
                  'appName': appName,
                  'usageTime': existingTime + usageTimeMs, // Add to existing time
                  'category': category,
                  'lastTimeUsed': info.lastTimeUsed,
                };
                print('Merged duplicate: $appName - added ${usageTimeMs}ms to existing ${existingTime}ms');
              } else {
                appMap[packageName] = {
                  'packageName': packageName,
                  'appName': appName,
                  'usageTime': usageTimeMs,
                  'category': category,
                  'lastTimeUsed': info.lastTimeUsed,
                };
              }
            }
          }
        } else if (usageTimeMs > 0) {
          print('Filtered out short usage: $appName ($packageName) - ${usageTimeMs}ms');
        }
      }
      
      // Convert map to list
      List<Map<String, dynamic>> result = appMap.values.toList();
      
      print('\n=== ULTRA ACCURATE RESULTS ===');
      print('Total raw time: ${totalRawTime}ms = ${(totalRawTime / (1000 * 60)).toStringAsFixed(1)}min = ${(totalRawTime / (1000 * 60 * 60)).toStringAsFixed(2)}hours');
      print('Ultra filtered apps: ${result.length}');
      
      if (result.isNotEmpty) {
        final totalFilteredTime = result.fold(0, (sum, item) => sum + (item['usageTime'] as int));
        final totalFilteredMinutes = totalFilteredTime / (1000 * 60);
        final totalFilteredHours = totalFilteredMinutes / 60;
        
        print('Total ultra filtered time: ${totalFilteredTime}ms = ${totalFilteredMinutes.toStringAsFixed(1)}min = ${totalFilteredHours.toStringAsFixed(2)}hours');
        
        // Show detailed breakdown of ALL apps
        print('\n=== ALL FILTERED APPS ===');
        for (int i = 0; i < result.length; i++) {
          final app = result[i];
          final appTime = app['usageTime'] as int;
          final appMinutes = appTime / (1000 * 60);
          print('${i + 1}. ${app['appName']}: ${appTime}ms = ${appMinutes.toStringAsFixed(1)}min');
        }
      }
      
      // Sort by usage time
      result.sort((a, b) => (b['usageTime'] as int).compareTo(a['usageTime'] as int));
      
      return result;
    } catch (e) {
      print('Error getting ultra accurate usage stats: $e');
      return [];
    }
  }

  // Check if an app is suspicious (might be inflating screen time)
  static bool _isSuspiciousApp(String packageName, String appName) {
    // Filter out apps that might be running in background
    final suspiciousApps = [
      'com.android.systemui',
      'com.android.launcher',
      'com.android.launcher3',
      'com.google.android.launcher',
      'com.samsung.android.launcher',
      'com.miui.home',
      'com.huawei.android.launcher',
      'com.oneplus.launcher',
      'com.oppo.launcher',
      'com.vivo.launcher',
      'com.android.settings',
      'com.android.phone',
      'com.android.contacts',
      'com.android.calendar',
      'com.android.calculator2',
      'com.android.deskclock',
      'com.android.gallery3d',
      'com.android.music',
      'com.android.camera2',
      'com.android.camera',
      'com.android.gallery',
      'com.android.mms',
      'com.android.email',
      'com.android.browser',
      'com.android.chrome',
      'com.google.android.apps.maps',
      'com.google.android.apps.photos',
      'com.google.android.gm',
      'com.google.android.apps.docs',
      'com.google.android.apps.drive',
      'com.google.android.apps.calendar',
      'com.google.android.apps.keep',
      'com.google.android.apps.translate',
      'com.google.android.apps.meetings',
      'com.google.android.apps.tachyon',
      'com.google.android.apps.messaging',
      'com.google.android.apps.books',
      'com.google.android.apps.podcasts',
      'com.google.android.apps.fitness',
      'com.google.android.apps.tachyon',
      'com.google.android.apps.messaging',
      'com.google.android.apps.books',
      'com.google.android.apps.podcasts',
      'com.google.android.apps.fitness',
    ];
    
    return suspiciousApps.contains(packageName);
  }

  // Get better weekly data by aggregating daily usage
  static Future<List<Map<String, dynamic>>> getBetterWeeklyUsage() async {
    try {
      bool hasPermission = await checkUsageStatsPermission();
      if (!hasPermission) {
        print('No usage stats permission');
        return [];
      }

      // Get the start of the current week (Monday)
      final today = DateTime.now();
      final daysSinceMonday = today.weekday - 1;
      final weekStart = DateTime(today.year, today.month, today.day - daysSinceMonday);
      
      print('=== BETTER WEEKLY USAGE ===');
      print('Week start: $weekStart');
      print('Today: $today');
      
      // Query for the entire week
      List<UsageInfo> weekStats = await UsageStats.queryUsageStats(weekStart, today);
      print('Found ${weekStats.length} apps for the week');
      
      Map<String, Map<String, dynamic>> appMap = {};
      int totalRawTime = 0;
      
      for (var info in weekStats) {
        final packageName = info.packageName ?? 'unknown';
        final appName = _getAppName(packageName);
        final usageTimeMs = int.tryParse(info.totalTimeInForeground ?? '0') ?? 0;
        final category = _getAppCategory(packageName);
        
        totalRawTime += usageTimeMs;
        
        // Only count apps with significant usage (more than 5 minutes total for the week)
        if (usageTimeMs > 300000) { // 5 minutes in milliseconds
          if (_isSystemApp(packageName, appName)) {
            print('Filtered out system app: $appName ($packageName) - ${usageTimeMs}ms');
          } else {
            // Use package name as key to avoid duplicates
            if (appMap.containsKey(packageName)) {
              // If app already exists, add the usage time
              final existing = appMap[packageName]!;
              final existingTime = existing['usageTime'] as int;
              appMap[packageName] = {
                'packageName': packageName,
                'appName': appName,
                'usageTime': existingTime + usageTimeMs,
                'category': category,
                'lastTimeUsed': info.lastTimeUsed,
              };
              print('Merged duplicate: $appName - added ${usageTimeMs}ms to existing ${existingTime}ms');
            } else {
              appMap[packageName] = {
                'packageName': packageName,
                'appName': appName,
                'usageTime': usageTimeMs,
                'category': category,
                'lastTimeUsed': info.lastTimeUsed,
              };
            }
          }
        } else if (usageTimeMs > 0) {
          print('Filtered out short usage: $appName ($packageName) - ${usageTimeMs}ms');
        }
      }
      
      // Convert map to list
      List<Map<String, dynamic>> result = appMap.values.toList();
      
      print('\n=== BETTER WEEKLY RESULTS ===');
      print('Total raw time: ${totalRawTime}ms = ${(totalRawTime / (1000 * 60)).toStringAsFixed(1)}min = ${(totalRawTime / (1000 * 60 * 60)).toStringAsFixed(2)}hours');
      print('Weekly filtered apps: ${result.length}');
      
      if (result.isNotEmpty) {
        final totalFilteredTime = result.fold(0, (sum, item) => sum + (item['usageTime'] as int));
        final totalFilteredMinutes = totalFilteredTime / (1000 * 60);
        final totalFilteredHours = totalFilteredMinutes / 60;
        
        print('Total weekly filtered time: ${totalFilteredTime}ms = ${totalFilteredMinutes.toStringAsFixed(1)}min = ${totalFilteredHours.toStringAsFixed(2)}hours');
        
        // Show detailed breakdown of ALL apps
        print('\n=== WEEKLY APPS BREAKDOWN ===');
        for (int i = 0; i < result.length; i++) {
          final app = result[i];
          final appTime = app['usageTime'] as int;
          final appMinutes = appTime / (1000 * 60);
          final appHours = appMinutes / 60;
          print('${i + 1}. ${app['appName']}: ${appTime}ms = ${appMinutes.toStringAsFixed(1)}min = ${appHours.toStringAsFixed(2)}hours');
        }
      }
      
      // Sort by usage time
      result.sort((a, b) => (b['usageTime'] as int).compareTo(a['usageTime'] as int));
      
      return result;
    } catch (e) {
      print('Error getting better weekly usage: $e');
      return [];
    }
  }

  // Get daily usage data for the past 7 days for trend chart
  static Future<List<Map<String, dynamic>>> getDailyUsageForTrend() async {
    try {
      bool hasPermission = await checkUsageStatsPermission();
      if (!hasPermission) {
        print('No usage stats permission');
        return [];
      }

      final today = DateTime.now();
      List<Map<String, dynamic>> dailyData = [];
      
      // Get data for each of the past 7 days
      for (int i = 6; i >= 0; i--) {
        final dayStart = DateTime(today.year, today.month, today.day - i);
        final dayEnd = DateTime(today.year, today.month, today.day - i + 1);
        
        print('Getting data for day ${7-i}: $dayStart to $dayEnd');
        
        List<UsageInfo> dayStats = await UsageStats.queryUsageStats(dayStart, dayEnd);
        
        int dayTotalTime = 0;
        Map<String, int> appTimes = {};
        
        for (var info in dayStats) {
          final packageName = info.packageName ?? 'unknown';
          final appName = _getAppName(packageName);
          final usageTimeMs = int.tryParse(info.totalTimeInForeground ?? '0') ?? 0;
          
          // Only count non-system apps with significant usage
          if (usageTimeMs > 60000 && !_isSystemApp(packageName, appName)) { // 1 minute minimum
            dayTotalTime += usageTimeMs;
            
            if (appTimes.containsKey(packageName)) {
              appTimes[packageName] = appTimes[packageName]! + usageTimeMs;
            } else {
              appTimes[packageName] = usageTimeMs;
            }
          }
        }
        
        final dayHours = dayTotalTime / (1000 * 60 * 60);
        dailyData.add({
          'day': 7 - i, // Day number (1-7)
          'date': dayStart,
          'totalHours': dayHours,
          'totalMinutes': dayTotalTime / (1000 * 60),
          'appCount': appTimes.length,
          'topApp': appTimes.isNotEmpty ? _getAppName(appTimes.entries.reduce((a, b) => a.value > b.value ? a : b).key) : 'None',
        });
        
        print('Day ${7-i}: ${dayHours.toStringAsFixed(2)} hours, ${appTimes.length} apps');
      }
      
      print('\n=== DAILY USAGE TREND ===');
      for (var day in dailyData) {
        print('Day ${day['day']}: ${day['totalHours'].toStringAsFixed(2)}h (${day['appCount']} apps)');
      }
      
      return dailyData;
    } catch (e) {
      print('Error getting daily usage trend: $e');
      return [];
    }
  }

  // Request usage stats permission
  static Future<bool> requestUsageStatsPermission() async {
    try {
      // Use the working parental control channel to open settings
      await _channel.invokeMethod('requestUsageStatsPermission');
      return true;
    } catch (e) {
      print('Error requesting usage stats permission: $e');
      return true; // Still return true to show the dialog
    }
  }

  // Check if usage stats permission is granted
  static Future<bool> checkUsageStatsPermission() async {
    try {
      bool? hasPermission = await UsageStats.checkUsagePermission();
      return hasPermission ?? false;
    } catch (e) {
      print('Error checking usage stats permission: $e');
      return false;
    }
  }

  // Get app usage statistics for a specific period
  static Future<Map<String, dynamic>?> getUsageStats({Duration? period}) async {
    try {
      bool hasPermission = await checkUsageStatsPermission();
      if (!hasPermission) {
        return null;
      }

      DateTime endDate = DateTime.now();
      DateTime startDate = period != null 
          ? endDate.subtract(period)
          : DateTime(endDate.year, endDate.month, endDate.day);

      List<UsageInfo> usageStats = await UsageStats.queryUsageStats(startDate, endDate);
      
      int totalScreenTime = 0;
      Map<String, int> appUsage = {};
      Map<String, int> categoryUsage = {};
      
      for (var info in usageStats) {
        final packageName = info.packageName ?? 'unknown';
        final appName = _getAppName(packageName);
        final usageTime = int.tryParse(info.totalTimeInForeground ?? '0') ?? 0;
        final category = _getAppCategory(packageName);
        
        if (usageTime > 0) {
          totalScreenTime += usageTime;
          
          appUsage[appName] = (appUsage[appName] ?? 0) + usageTime;
          categoryUsage[category] = (categoryUsage[category] ?? 0) + usageTime;
        }
      }
      
      return {
        'totalScreenTime': totalScreenTime,
        'appUsage': appUsage,
        'categoryUsage': categoryUsage,
        'period': period?.inDays ?? 1,
      };
    } catch (e) {
      print('Error getting usage stats: $e');
      return null;
    }
  }

  // Helper method to get app name from package name
  static String _getAppName(String packageName) {
    if (packageName == 'unknown') return 'Unknown App';
    
    // Map of known package names to proper app names
    final appNameMap = {
      'com.zhiliaoapp.musically': 'TikTok',
      'com.ss.android.ugc.aweme': 'TikTok',
      'com.instagram.android': 'Instagram',
      'com.facebook.katana': 'Facebook',
      'com.twitter.android': 'Twitter',
      'com.snapchat.android': 'Snapchat',
      'com.whatsapp': 'WhatsApp',
      'com.telegram.messenger': 'Telegram',
      'com.discord': 'Discord',
      'com.google.android.youtube': 'YouTube',
      'com.netflix.mediaclient': 'Netflix',
      'com.amazon.avod.thirdpartyclient': 'Prime Video',
      'com.google.android.apps.photos': 'Google Photos',
      'com.google.android.gm': 'Gmail',
      'com.google.android.apps.docs': 'Google Docs',
      'com.microsoft.office.excel': 'Excel',
      'com.microsoft.office.word': 'Word',
      'com.microsoft.office.powerpoint': 'PowerPoint',
      'com.google.android.apps.maps': 'Google Maps',
      'com.ubercab': 'Uber',
      'com.ubercab.eats': 'Uber Eats',
      'com.doordash.consumer': 'DoorDash',
      'com.grubhub.android': 'Grubhub',
      'com.airbnb.android': 'Airbnb',
      'com.booking': 'Booking.com',
      'com.google.android.apps.translate': 'Google Translate',
      'com.google.android.apps.calendar': 'Google Calendar',
      'com.google.android.apps.drive': 'Google Drive',
      'com.google.android.apps.meetings': 'Google Meet',
      'com.zoom.us': 'Zoom',
      'com.skype.raider': 'Skype',
      'com.microsoft.teams': 'Microsoft Teams',
      'com.slack': 'Slack',
      'com.trello': 'Trello',
      'com.notion.id': 'Notion',
      'com.evernote': 'Evernote',
      'com.google.android.apps.keep': 'Google Keep',
      'com.google.android.apps.tachyon': 'Google Duo',
      'com.google.android.apps.messaging': 'Messages',
      'com.android.chrome': 'Chrome',
      'com.mozilla.firefox': 'Firefox',
      'com.opera.browser': 'Opera',
      'com.microsoft.emmx': 'Edge',
      'com.samsung.android.browser': 'Samsung Internet',
      'com.google.android.apps.books': 'Google Play Books',
      'com.amazon.kindle': 'Kindle',
      'com.audible.application': 'Audible',
      'com.google.android.apps.podcasts': 'Google Podcasts',
      'com.spotify.music': 'Spotify',
      'com.soundcloud.android': 'SoundCloud',
      'com.pandora.android': 'Pandora',
      'com.iheartradio.android': 'iHeartRadio',
      'com.google.android.apps.fitness': 'Google Fit',
      'com.myfitnesspal.android': 'MyFitnessPal',
      'com.strava': 'Strava',
      'com.nike.ntc': 'Nike Training Club',
      'com.adobe.reader': 'Adobe Acrobat Reader',
      'com.adobe.photoshop.express': 'Adobe Photoshop Express',
      'com.canva.editor': 'Canva',
      'com.pinterest': 'Pinterest',
      'com.reddit.frontpage': 'Reddit',
      'com.linkedin.android': 'LinkedIn',
      'com.github.android': 'GitHub',
      'com.stackexchange.marvin': 'Stack Overflow',
      'com.medium.reader': 'Medium',
      'com.quora.android': 'Quora',
      'com.tumblr': 'Tumblr',
      'com.flickr.android': 'Flickr',
      'com.vsco.cam': 'VSCO',
      'com.adobe.lightroom': 'Lightroom',
      'com.snapseed': 'Snapseed',
      'com.instagram.layout': 'Layout',
      'com.boomerang': 'Boomerang',
      'com.hyperlapse': 'Hyperlapse',
    };
    
    // Check if we have a known mapping
    if (appNameMap.containsKey(packageName)) {
      return appNameMap[packageName]!;
    }
    
    // Extract app name from package name as fallback
    List<String> parts = packageName.split('.');
    if (parts.isNotEmpty) {
      String lastPart = parts.last;
      // Capitalize first letter
      return lastPart[0].toUpperCase() + lastPart.substring(1);
    }
    return packageName;
  }

  // Helper method to check if an app is a system app or launcher
  static bool _isSystemApp(String packageName, String appName) {
    // Filter out system launchers
    if (packageName.contains('launcher') || 
        appName.toLowerCase().contains('launcher') ||
        packageName.contains('home')) {
      return true;
    }
    
    // Filter out system apps
    if (packageName.startsWith('com.android.') ||
        packageName.startsWith('com.google.android.') ||
        packageName.startsWith('android.') ||
        packageName.contains('system') ||
        packageName.contains('settings') ||
        packageName.contains('keyboard') ||
        packageName.contains('inputmethod') ||
        packageName.contains('wallpaper') ||
        packageName.contains('livewallpaper')) {
      return true;
    }
    
    // Filter out specific system packages
    final systemPackages = [
      'com.android.systemui',
      'com.android.launcher',
      'com.android.launcher3',
      'com.google.android.launcher',
      'com.samsung.android.launcher',
      'com.miui.home',
      'com.huawei.android.launcher',
      'com.oneplus.launcher',
      'com.oppo.launcher',
      'com.vivo.launcher',
      'com.android.incallui', // Phone call interface - this is what you asked about!
      'com.android.phone', // Phone app
      'com.android.contacts', // Contacts app
      'com.android.dialer', // Dialer app
      'com.android.settings', // Settings app
      'com.android.calendar', // Calendar app
      'com.android.calculator2', // Calculator app
      'com.android.deskclock', // Clock app
      'com.android.gallery3d', // Gallery app
      'com.android.music', // Music app
      'com.android.camera2', // Camera app
      'com.android.camera', // Camera app
      'com.android.gallery', // Gallery app
      'com.android.mms', // Messages app
      'com.android.email', // Email app
      'com.android.browser', // Browser app
      'com.android.chrome', // Chrome browser
      'com.google.android.apps.maps', // Google Maps
      'com.google.android.apps.photos', // Google Photos
      'com.google.android.gm', // Gmail
      'com.google.android.apps.docs', // Google Docs
      'com.google.android.apps.drive', // Google Drive
      'com.google.android.apps.calendar', // Google Calendar
      'com.google.android.apps.keep', // Google Keep
      'com.google.android.apps.translate', // Google Translate
      'com.google.android.apps.meetings', // Google Meet
      'com.google.android.apps.tachyon', // Google Duo
      'com.google.android.apps.messaging', // Google Messages
      'com.google.android.apps.books', // Google Books
      'com.google.android.apps.podcasts', // Google Podcasts
      'com.google.android.apps.fitness', // Google Fit
      'com.tencent.mm', // WeChat (often considered system-like in some regions)
      'com.tencent.mobileqq', // QQ (often considered system-like in some regions)
    ];
    
    return systemPackages.contains(packageName);
  }

  // Helper method to categorize apps
  static String _getAppCategory(String packageName) {
    // Social media apps
    if (packageName.contains('facebook') || 
        packageName.contains('twitter') || 
        packageName.contains('instagram') || 
        packageName.contains('snapchat') || 
        packageName.contains('tiktok') ||
        packageName.contains('whatsapp') ||
        packageName.contains('telegram')) {
      return 'Social';
    }
    
    // Entertainment apps
    if (packageName.contains('youtube') || 
        packageName.contains('netflix') || 
        packageName.contains('spotify') || 
        packageName.contains('twitch') ||
        packageName.contains('discord') ||
        packageName.contains('reddit')) {
      return 'Entertainment';
    }
    
    // Productivity apps
    if (packageName.contains('gmail') || 
        packageName.contains('outlook') || 
        packageName.contains('office') || 
        packageName.contains('google') ||
        packageName.contains('microsoft') ||
        packageName.contains('slack') ||
        packageName.contains('zoom')) {
      return 'Productivity';
    }
    
    // Games
    if (packageName.contains('game') || 
        packageName.contains('play') || 
        packageName.contains('unity')) {
      return 'Games';
    }
    
    // Default category
    return 'Other';
  }

  // Block an app
  static Future<bool> blockApp(String packageName) async {
    try {
      final bool result = await _channel.invokeMethod('blockApp', {
        'packageName': packageName,
      });
      
      if (result && _screenTimeModel != null) {
        await _screenTimeModel!.blockApp(packageName);
      }
      
      return result;
    } catch (e) {
      print('Error blocking app: $e');
      return false;
    }
  }

  // Unblock an app
  static Future<bool> unblockApp(String packageName) async {
    try {
      final bool result = await _channel.invokeMethod('unblockApp', {
        'packageName': packageName,
      });
      
      if (result && _screenTimeModel != null) {
        await _screenTimeModel!.unblockApp(packageName);
      }
      
      return result;
    } catch (e) {
      print('Error unblocking app: $e');
      return false;
    }
  }

  // Check if content should be blocked
  static Future<bool> checkContentFilter(String content) async {
    try {
      final bool result = await _channel.invokeMethod('checkContentFilter', {
        'content': content,
      });
      
      return result;
    } catch (e) {
      print('Error checking content filter: $e');
      return false;
    }
  }

  // Add NSFW keyword
  static Future<bool> addNsfwKeyword(String keyword) async {
    try {
      final bool result = await _channel.invokeMethod('addNsfwKeyword', {
        'keyword': keyword,
      });
      
      if (result && _screenTimeModel != null) {
        await _screenTimeModel!.addNsfwKeyword(keyword);
      }
      
      return result;
    } catch (e) {
      print('Error adding NSFW keyword: $e');
      return false;
    }
  }

  // Remove NSFW keyword
  static Future<bool> removeNsfwKeyword(String keyword) async {
    try {
      final bool result = await _channel.invokeMethod('removeNsfwKeyword', {
        'keyword': keyword,
      });
      
      if (result && _screenTimeModel != null) {
        await _screenTimeModel!.removeNsfwKeyword(keyword);
      }
      
      return result;
    } catch (e) {
      print('Error removing NSFW keyword: $e');
      return false;
    }
  }

  // Enable anti-removal protection
  static Future<bool> enableAntiRemoval() async {
    try {
      final bool result = await _channel.invokeMethod('enableAntiRemoval');
      return result;
    } catch (e) {
      print('Error enabling anti-removal: $e');
      return false;
    }
  }

  // Disable anti-removal protection
  static Future<bool> disableAntiRemoval() async {
    try {
      final bool result = await _channel.invokeMethod('disableAntiRemoval');
      return result;
    } catch (e) {
      print('Error disabling anti-removal: $e');
      return false;
    }
  }

  // Show content blocked notification
  static void _showContentBlockedNotification(String content, String reason) {
    // This would typically show a system notification
    print('Content blocked: $content - Reason: $reason');
  }

  // Show app blocked notification
  static void _showAppBlockedNotification(String appName) {
    // This would typically show a system notification
    print('App blocked: $appName');
  }

  // Cleanup
  static void dispose() {
    _usageTimer?.cancel();
    _usageTimer = null;
  }
}