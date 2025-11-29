import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sleep_session.dart';

class SleepService {
  SleepSession? _currentSession;
  List<SleepSession> _sessions = [];

  SleepSession? get currentSession => _currentSession;
  List<SleepSession> get sessions => List.unmodifiable(_sessions);
  bool get isTracking => _currentSession != null && _currentSession!.isActive;

  Future<void> initialize() async {
    await _loadSessions();
  }

  Future<void> startSleepTracking() async {
    if (_currentSession != null && _currentSession!.isActive) {
      return; // Already tracking
    }

    _currentSession = SleepSession(
      startTime: DateTime.now(),
      quality: SleepQuality.good,
    );
    await _saveSessions();
  }

  Future<void> endSleepTracking({
    SleepQuality? quality,
    List<String>? notes,
  }) async {
    if (_currentSession == null || !_currentSession!.isActive) {
      return; // No active session
    }

    final endTime = DateTime.now();
    final duration = endTime.difference(_currentSession!.startTime);

    _currentSession = SleepSession(
      startTime: _currentSession!.startTime,
      endTime: endTime,
      duration: duration,
      quality: quality ?? _currentSession!.quality,
      notes: notes ?? _currentSession!.notes,
      isCompleted: true,
    );

    _sessions.add(_currentSession!);
    await _saveSessions();
    _currentSession = null;
  }

  Future<void> updateSleepQuality(SleepQuality quality) async {
    if (_currentSession != null && _currentSession!.isActive) {
      _currentSession = SleepSession(
        startTime: _currentSession!.startTime,
        quality: quality,
        notes: _currentSession!.notes,
      );
      await _saveSessions();
    }
  }

  Future<void> addNote(String note) async {
    if (_currentSession != null && _currentSession!.isActive) {
      final updatedNotes = List<String>.from(_currentSession!.notes)..add(note);
      _currentSession = SleepSession(
        startTime: _currentSession!.startTime,
        quality: _currentSession!.quality,
        notes: updatedNotes,
      );
      await _saveSessions();
    }
  }

  Future<List<SleepSession>> getWeeklySessions() async {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return _sessions.where((s) => s.startTime.isAfter(weekAgo)).toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  Future<List<SleepSession>> getMonthlySessions() async {
    final now = DateTime.now();
    final monthAgo = now.subtract(const Duration(days: 30));
    return _sessions.where((s) => s.startTime.isAfter(monthAgo)).toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  Duration getAverageSleepDuration() {
    if (_sessions.isEmpty) return Duration.zero;
    
    final completedSessions = _sessions.where((s) => s.duration != null).toList();
    if (completedSessions.isEmpty) return Duration.zero;

    final totalMinutes = completedSessions
        .map((s) => s.duration!.inMinutes)
        .reduce((a, b) => a + b);
    
    return Duration(minutes: totalMinutes ~/ completedSessions.length);
  }

  double getAverageSleepQuality() {
    if (_sessions.isEmpty) return 0.0;
    
    final completedSessions = _sessions.where((s) => s.isCompleted).toList();
    if (completedSessions.isEmpty) return 0.0;

    final totalQuality = completedSessions
        .map((s) => s.quality.index.toDouble())
        .reduce((a, b) => a + b);
    
    return totalQuality / completedSessions.length;
  }

  Future<void> _saveSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionsJson = _sessions.map((s) => s.toJson()).toList();
    await prefs.setString('sleep_sessions', jsonEncode(sessionsJson));
    
    if (_currentSession != null) {
      await prefs.setString('current_sleep_session', jsonEncode(_currentSession!.toJson()));
    } else {
      await prefs.remove('current_sleep_session');
    }
  }

  Future<void> _loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load completed sessions
    final sessionsJson = prefs.getString('sleep_sessions');
    if (sessionsJson != null) {
      final sessionsList = jsonDecode(sessionsJson) as List;
      _sessions = sessionsList.map((json) => SleepSession.fromJson(json)).toList();
    }

    // Load current session if exists
    final currentSessionJson = prefs.getString('current_sleep_session');
    if (currentSessionJson != null) {
      final sessionData = jsonDecode(currentSessionJson) as Map<String, dynamic>;
      _currentSession = SleepSession.fromJson(sessionData);
      
      // If session is older than 24 hours, mark as completed
      if (_currentSession!.startTime.isBefore(
        DateTime.now().subtract(const Duration(hours: 24)),
      )) {
        await endSleepTracking();
      }
    }
  }

  Future<void> deleteSession(SleepSession session) async {
    _sessions.remove(session);
    await _saveSessions();
  }
}


