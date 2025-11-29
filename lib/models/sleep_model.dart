import 'package:flutter/foundation.dart';
import '../services/activity_detection_service.dart';

class SleepSession {
  final DateTime startTime;
  DateTime? endTime;
  
  SleepSession({required this.startTime, this.endTime});
  
  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }
  
  int get durationInMinutes => duration.inMinutes;
  int get durationInHours => duration.inHours;
  
  bool get isActive => endTime == null;
  
  Map<String, dynamic> toJson() => {
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
  };
  
  factory SleepSession.fromJson(Map<String, dynamic> json) {
    return SleepSession(
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime'] as String) : null,
    );
  }
}

class SleepModel extends ChangeNotifier {
  List<SleepSession> _sleepSessions = [];
  SleepSession? _currentSession;
  late ActivityDetectionService _activityDetectionService;
  
  List<SleepSession> get sleepSessions => _sleepSessions;
  SleepSession? get currentSession => _currentSession;
  bool get isSleeping => _currentSession != null && _currentSession!.isActive;
  
  SleepModel() {
    _activityDetectionService = ActivityDetectionService();
    _initializeActivityDetection();
  }
  
  void _initializeActivityDetection() {
    _activityDetectionService.startMonitoring(
      onInactivityDetected: _handleInactivityDetected,
    );
  }
  
  void _handleInactivityDetected() {
    if (!isSleeping) {
      startSleepSession();
    }
  }
  
  double get totalSleepToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _sleepSessions
        .where((session) => session.startTime.isAfter(today))
        .fold<int>(0, (sum, session) => sum + session.durationInMinutes)
        .toDouble();
  }
  
  double get averageSleepDuration {
    if (_sleepSessions.isEmpty) return 0;
    final completed = _sleepSessions.where((s) => s.endTime != null);
    if (completed.isEmpty) return 0;
    final totalMinutes = completed.fold<int>(0, (sum, session) => sum + session.durationInMinutes);
    return totalMinutes / completed.length;
  }
  
  int get totalNights => _sleepSessions.where((s) => s.endTime != null).length;
  
  void recordActivity() {
    _activityDetectionService.recordManualActivity();
    
    // If sleeping, end the sleep session
    if (isSleeping) {
      endSleepSession();
    }
    
    notifyListeners();
  }
  
  void startSleepSession() {
    if (!isSleeping) {
      _currentSession = SleepSession(startTime: DateTime.now());
      notifyListeners();
    }
  }
  
  void endSleepSession() {
    if (isSleeping) {
      _currentSession!.endTime = DateTime.now();
      _sleepSessions.add(_currentSession!);
      _currentSession = null;
      notifyListeners();
    }
  }
  
  void manualStartSleep() {
    startSleepSession();
  }
  
  void manualEndSleep() {
    endSleepSession();
  }
  
  List<SleepSession> getSleepSessionsForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    return _sleepSessions
        .where((session) => session.startTime.isAfter(startOfDay) && session.startTime.isBefore(endOfDay))
        .toList();
  }
  
  void clearAllSessions() {
    _sleepSessions.clear();
    _currentSession = null;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _activityDetectionService.dispose();
    super.dispose();
  }
}
