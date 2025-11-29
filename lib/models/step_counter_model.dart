import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DailyStepData {
  final DateTime date;
  int steps;
  
  DailyStepData({required this.date, required this.steps});
  
  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'steps': steps,
  };
  
  factory DailyStepData.fromJson(Map<String, dynamic> json) {
    return DailyStepData(
      date: DateTime.parse(json['date'] as String),
      steps: json['steps'] as int,
    );
  }
}

class StepCounterModel extends ChangeNotifier {
  int _todaySteps = 0;
  int _goalSteps = 10000;
  List<DailyStepData> _stepHistory = [];
  DateTime _lastSyncDate = DateTime.now();
  static const String _stepsKey = 'daily_steps';
  static const String _historyKey = 'step_history';
  static const String _goalKey = 'step_goal';
  
  int get todaySteps => _todaySteps;
  int get goalSteps => _goalSteps;
  List<DailyStepData> get stepHistory => _stepHistory;
  DateTime get lastSyncDate => _lastSyncDate;
  
  double get progressPercentage => (_todaySteps / _goalSteps * 100).clamp(0, 100);
  bool get goalReached => _todaySteps >= _goalSteps;
  
  int get weeklySteps {
    final now = DateTime.now();
    final weekAgo = now.subtract(Duration(days: 7));
    return _stepHistory
        .where((data) => data.date.isAfter(weekAgo) && data.date.isBefore(now.add(Duration(days: 1))))
        .fold<int>(0, (sum, data) => sum + data.steps);
  }
  
  int get monthlySteps {
    final now = DateTime.now();
    final monthAgo = DateTime(now.year, now.month - 1, now.day);
    return _stepHistory
        .where((data) => data.date.isAfter(monthAgo) && data.date.isBefore(now.add(Duration(days: 1))))
        .fold<int>(0, (sum, data) => sum + data.steps);
  }
  
  double get averageDailySteps {
    if (_stepHistory.isEmpty) return 0;
    final total = _stepHistory.fold<int>(0, (sum, data) => sum + data.steps);
    return total / _stepHistory.length;
  }
  
  int get streakDays {
    if (_stepHistory.isEmpty) return 0;
    
    final sortedHistory = List<DailyStepData>.from(_stepHistory)
      ..sort((a, b) => b.date.compareTo(a.date));
    
    int streak = 0;
    DateTime currentDate = DateTime.now();
    
    for (final dayData in sortedHistory) {
      final dayOnly = DateTime(dayData.date.year, dayData.date.month, dayData.date.day);
      final currentDateOnly = DateTime(currentDate.year, currentDate.month, currentDate.day);
      
      final difference = currentDateOnly.difference(dayOnly).inDays;
      
      if (difference == streak) {
        if (dayData.steps >= _goalSteps) {
          streak++;
        } else {
          break;
        }
      } else if (difference > streak) {
        break;
      }
    }
    
    return streak;
  }
  
  StepCounterModel() {
    _initializeData();
  }
  
  Future<void> _initializeData() async {
    await _loadData();
  }
  
  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load today's steps
      final today = DateTime.now();
      final todayKey = '${_stepsKey}_${today.year}_${today.month}_${today.day}';
      _todaySteps = prefs.getInt(todayKey) ?? 0;
      
      // Load goal
      _goalSteps = prefs.getInt(_goalKey) ?? 10000;
      
      // Load history
      final historyJson = prefs.getString(_historyKey);
      if (historyJson != null) {
        final List<dynamic> decoded = jsonDecode(historyJson);
        _stepHistory = decoded
            .map((item) => DailyStepData.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      
      // Ensure today's data is in history
      _syncTodayData();
      
      notifyListeners();
    } catch (e) {
      print('Error loading step data: $e');
    }
  }
  
  void _syncTodayData() {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final existingIndex = _stepHistory.indexWhere((data) {
      final dataDate = DateTime(data.date.year, data.date.month, data.date.day);
      return dataDate.isAtSameMomentAs(today);
    });
    
    if (existingIndex != -1) {
      _stepHistory[existingIndex].steps = _todaySteps;
    } else {
      _stepHistory.add(DailyStepData(date: today, steps: _todaySteps));
    }
  }
  
  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save today's steps
      final today = DateTime.now();
      final todayKey = '${_stepsKey}_${today.year}_${today.month}_${today.day}';
      await prefs.setInt(todayKey, _todaySteps);
      
      // Save goal
      await prefs.setInt(_goalKey, _goalSteps);
      
      // Save history
      final historyJson = jsonEncode(
        _stepHistory.map((data) => data.toJson()).toList(),
      );
      await prefs.setString(_historyKey, historyJson);
    } catch (e) {
      print('Error saving step data: $e');
    }
  }
  
  void updateSteps(int steps) {
    if (steps != _todaySteps) {
      _todaySteps = steps.clamp(0, 999999);
      _syncTodayData();
      _saveData();
      notifyListeners();
    }
  }
  
  void addSteps(int steps) {
    updateSteps(_todaySteps + steps);
  }
  
  void resetTodaySteps() {
    updateSteps(0);
  }
  
  void setGoal(int goal) {
    if (goal > 0) {
      _goalSteps = goal;
      _saveData();
      notifyListeners();
    }
  }
  
  void addManualSteps(int steps) {
    addSteps(steps);
  }
  
  DailyStepData? getStepsForDate(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    try {
      return _stepHistory.firstWhere((data) {
        final dataDate = DateTime(data.date.year, data.date.month, data.date.day);
        return dataDate.isAtSameMomentAs(dateOnly);
      });
    } catch (e) {
      return null;
    }
  }
  
  List<DailyStepData> getLastNDays(int days) {
    final now = DateTime.now();
    return _stepHistory
        .where((data) => data.date.isAfter(now.subtract(Duration(days: days))))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }
}
