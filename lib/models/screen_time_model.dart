import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AppUsage {
  final String packageName;
  final String appName;
  final Duration usageTime;
  final DateTime date;
  final String category;

  AppUsage({
    required this.packageName,
    required this.appName,
    required this.usageTime,
    required this.date,
    required this.category,
  });

  Map<String, dynamic> toJson() => {
    'packageName': packageName,
    'appName': appName,
    'usageTime': usageTime.inMinutes,
    'date': date.toIso8601String(),
    'category': category,
  };

  factory AppUsage.fromJson(Map<String, dynamic> json) => AppUsage(
    packageName: json['packageName'],
    appName: json['appName'],
    usageTime: Duration(minutes: json['usageTime']),
    date: DateTime.parse(json['date']),
    category: json['category'],
  );
}

class ScreenTimeModel extends ChangeNotifier {
  List<AppUsage> _dailyUsage = [];
  List<AppUsage> _weeklyUsage = [];
  Map<String, Duration> _categoryUsage = {};
  Duration _totalScreenTime = Duration.zero;
  Duration _averageDailyTime = Duration.zero;
  int _focusScore = 0;
  List<String> _blockedApps = [];
  List<String> _nsfwKeywords = [];

  // Getters
  List<AppUsage> get dailyUsage => List.unmodifiable(_dailyUsage);
  List<AppUsage> get weeklyUsage => List.unmodifiable(_weeklyUsage);
  Map<String, Duration> get categoryUsage => Map.unmodifiable(_categoryUsage);
  Duration get totalScreenTime => _totalScreenTime;
  Duration get averageDailyTime => _averageDailyTime;
  int get focusScore => _focusScore;
  List<String> get blockedApps => List.unmodifiable(_blockedApps);
  List<String> get nsfwKeywords => List.unmodifiable(_nsfwKeywords);

  ScreenTimeModel() {
    _loadData();
    _calculateAnalytics();
  }

  // Load data from storage
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load daily usage
    final dailyUsageJson = prefs.getString('dailyUsage');
    if (dailyUsageJson != null) {
      final List<dynamic> dailyList = json.decode(dailyUsageJson);
      _dailyUsage = dailyList.map((json) => AppUsage.fromJson(json)).toList();
    }

    // Load weekly usage
    final weeklyUsageJson = prefs.getString('weeklyUsage');
    if (weeklyUsageJson != null) {
      final List<dynamic> weeklyList = json.decode(weeklyUsageJson);
      _weeklyUsage = weeklyList.map((json) => AppUsage.fromJson(json)).toList();
    }

    // Load blocked apps
    final blockedAppsJson = prefs.getString('blockedApps');
    if (blockedAppsJson != null) {
      _blockedApps = List<String>.from(json.decode(blockedAppsJson));
    }

    // Load NSFW keywords
    final nsfwKeywordsJson = prefs.getString('nsfwKeywords');
    if (nsfwKeywordsJson != null) {
      _nsfwKeywords = List<String>.from(json.decode(nsfwKeywordsJson));
    }

    notifyListeners();
  }

  // Save data to storage
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString('dailyUsage', json.encode(
      _dailyUsage.map((usage) => usage.toJson()).toList()
    ));
    
    await prefs.setString('weeklyUsage', json.encode(
      _weeklyUsage.map((usage) => usage.toJson()).toList()
    ));
    
    await prefs.setString('blockedApps', json.encode(_blockedApps));
    await prefs.setString('nsfwKeywords', json.encode(_nsfwKeywords));
  }

  // Add app usage
  Future<void> addAppUsage(String packageName, String appName, Duration usageTime, String category) async {
    // Check if we already have usage for this app today
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    
    // Remove existing usage for this app today to avoid duplicates
    _dailyUsage.removeWhere((usage) => 
        usage.packageName == packageName && 
        usage.date.isAfter(todayStart));
    
    final usage = AppUsage(
      packageName: packageName,
      appName: appName,
      usageTime: usageTime,
      date: DateTime.now(),
      category: category,
    );

    _dailyUsage.add(usage);
    _weeklyUsage.add(usage);

    // Keep only last 7 days of weekly data
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    _weeklyUsage.removeWhere((usage) => usage.date.isBefore(weekAgo));

    await _saveData();
    _calculateAnalytics();
    notifyListeners();
  }

  // Calculate analytics
  void _calculateAnalytics() {
    _totalScreenTime = Duration.zero;
    _categoryUsage.clear();

    // Calculate total screen time and category usage
    for (final usage in _dailyUsage) {
      _totalScreenTime += usage.usageTime;
      
      if (_categoryUsage.containsKey(usage.category)) {
        _categoryUsage[usage.category] = _categoryUsage[usage.category]! + usage.usageTime;
      } else {
        _categoryUsage[usage.category] = usage.usageTime;
      }
    }

    // Calculate average daily time from weekly data
    if (_weeklyUsage.isNotEmpty) {
      final totalWeeklyTime = _weeklyUsage.fold<Duration>(
        Duration.zero,
        (total, usage) => total + usage.usageTime,
      );
      _averageDailyTime = Duration(
        minutes: totalWeeklyTime.inMinutes ~/ 7,
      );
    }

    // Calculate focus score (0-100)
    _calculateFocusScore();
  }

  void _calculateFocusScore() {
    if (_totalScreenTime.inMinutes == 0) {
      _focusScore = 0;
      return;
    }

    // Focus score based on productive vs unproductive app usage
    final productiveTime = _categoryUsage['Productivity'] ?? Duration.zero;
    final socialTime = _categoryUsage['Social'] ?? Duration.zero;
    final entertainmentTime = _categoryUsage['Entertainment'] ?? Duration.zero;

    final totalTime = _totalScreenTime.inMinutes;
    final productiveRatio = productiveTime.inMinutes / totalTime;
    final socialRatio = socialTime.inMinutes / totalTime;
    final entertainmentRatio = entertainmentTime.inMinutes / totalTime;

    // Calculate score: higher for productivity, lower for social/entertainment
    _focusScore = ((productiveRatio * 100) - (socialRatio * 30) - (entertainmentRatio * 50)).round().clamp(0, 100);
  }

  // Block/Unblock apps
  Future<void> blockApp(String packageName) async {
    if (!_blockedApps.contains(packageName)) {
      _blockedApps.add(packageName);
      await _saveData();
      notifyListeners();
    }
  }

  Future<void> unblockApp(String packageName) async {
    _blockedApps.remove(packageName);
    await _saveData();
    notifyListeners();
  }

  bool isAppBlocked(String packageName) {
    return _blockedApps.contains(packageName);
  }

  // NSFW Content Filtering
  Future<void> addNsfwKeyword(String keyword) async {
    if (!_nsfwKeywords.contains(keyword.toLowerCase())) {
      _nsfwKeywords.add(keyword.toLowerCase());
      await _saveData();
      notifyListeners();
    }
  }

  Future<void> removeNsfwKeyword(String keyword) async {
    _nsfwKeywords.remove(keyword.toLowerCase());
    await _saveData();
    notifyListeners();
  }

  bool isContentBlocked(String content) {
    final lowerContent = content.toLowerCase();
    return _nsfwKeywords.any((keyword) => lowerContent.contains(keyword));
  }

  // Get usage statistics
  Map<String, dynamic> getUsageStats() {
    return {
      'totalScreenTime': _totalScreenTime,
      'averageDailyTime': _averageDailyTime,
      'focusScore': _focusScore,
      'categoryBreakdown': _categoryUsage,
      'mostUsedApp': _getMostUsedApp(),
      'productivityRatio': _getProductivityRatio(),
    };
  }

  String _getMostUsedApp() {
    if (_dailyUsage.isEmpty) return 'None';
    
    final appUsage = <String, Duration>{};
    for (final usage in _dailyUsage) {
      if (appUsage.containsKey(usage.appName)) {
        appUsage[usage.appName] = appUsage[usage.appName]! + usage.usageTime;
      } else {
        appUsage[usage.appName] = usage.usageTime;
      }
    }

    return appUsage.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  double _getProductivityRatio() {
    if (_totalScreenTime.inMinutes == 0) return 0.0;
    
    final productiveTime = _categoryUsage['Productivity'] ?? Duration.zero;
    return productiveTime.inMinutes / _totalScreenTime.inMinutes;
  }

  // Refresh data from real usage stats
  Future<void> refreshFromRealUsageStats() async {
    try {
      // This will be called by the service to update with real data
      _calculateAnalytics();
      notifyListeners();
    } catch (e) {
      print('Error refreshing from real usage stats: $e');
    }
  }

  // Get usage stats for a specific period
  Map<String, dynamic> getUsageStatsForPeriod(Duration period) {
    final cutoffDate = DateTime.now().subtract(period);
    final periodUsage = _dailyUsage.where((usage) => usage.date.isAfter(cutoffDate)).toList();
    
    Duration totalTime = Duration.zero;
    Map<String, Duration> categoryBreakdown = {};
    Map<String, Duration> appBreakdown = {};
    
    for (final usage in periodUsage) {
      totalTime += usage.usageTime;
      
      // Category breakdown
      if (categoryBreakdown.containsKey(usage.category)) {
        categoryBreakdown[usage.category] = categoryBreakdown[usage.category]! + usage.usageTime;
      } else {
        categoryBreakdown[usage.category] = usage.usageTime;
      }
      
      // App breakdown
      if (appBreakdown.containsKey(usage.appName)) {
        appBreakdown[usage.appName] = appBreakdown[usage.appName]! + usage.usageTime;
      } else {
        appBreakdown[usage.appName] = usage.usageTime;
      }
    }
    
    return {
      'totalTime': totalTime,
      'categoryBreakdown': categoryBreakdown,
      'appBreakdown': appBreakdown,
      'period': period,
      'usageCount': periodUsage.length,
    };
  }

  // Reset data
  Future<void> resetData() async {
    _dailyUsage.clear();
    _weeklyUsage.clear();
    _categoryUsage.clear();
    _totalScreenTime = Duration.zero;
    _averageDailyTime = Duration.zero;
    _focusScore = 0;
    
    await _saveData();
    notifyListeners();
  }
}

