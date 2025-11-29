import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/step_data.dart';

class StepService {
  List<StepData> _stepHistory = [];
  StepData? _todaySteps;

  List<StepData> get stepHistory => List.unmodifiable(_stepHistory);
  StepData? get todaySteps => _todaySteps;
  int get todayStepCount => _todaySteps?.steps ?? 0;
  int get dailyGoal => 10000; // Default daily goal

  Future<void> initialize() async {
    await _loadStepData();
    _updateTodaySteps();
  }

  void _updateTodaySteps() {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    
    // Find today's step data
    _todaySteps = _stepHistory.firstWhere(
      (data) {
        final dataDate = DateTime(data.date.year, data.date.month, data.date.day);
        return dataDate.isAtSameMomentAs(todayDate);
      },
      orElse: () => StepData(
        date: todayDate,
        steps: 0,
      ),
    );
  }

  Future<void> updateSteps(int steps, {double? distance, int? calories, Duration? activeTime}) async {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    // Calculate distance if not provided (average step length ~0.7m)
    final calculatedDistance = distance ?? (steps * 0.0007);
    
    // Calculate calories if not provided (rough estimate: 0.04 calories per step)
    final calculatedCalories = calories ?? (steps * 0.04).round();

    final stepData = StepData(
      date: todayDate,
      steps: steps,
      distance: calculatedDistance,
      calories: calculatedCalories,
      activeTime: activeTime ?? const Duration(seconds: 0),
    );

    // Update or add today's steps
    final existingIndex = _stepHistory.indexWhere((data) {
      final dataDate = DateTime(data.date.year, data.date.month, data.date.day);
      return dataDate.isAtSameMomentAs(todayDate);
    });

    if (existingIndex >= 0) {
      _stepHistory[existingIndex] = stepData;
    } else {
      _stepHistory.add(stepData);
    }

    _todaySteps = stepData;
    await _saveStepData();
  }

  Future<void> addSteps(int additionalSteps) async {
    final currentSteps = todayStepCount;
    await updateSteps(currentSteps + additionalSteps);
  }

  List<StepData> getStepsForPeriod(DateTime startDate, DateTime endDate) {
    return _stepHistory.where((data) {
      return data.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
             data.date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  int getTotalStepsForPeriod(DateTime startDate, DateTime endDate) {
    final steps = getStepsForPeriod(startDate, endDate);
    return steps.fold(0, (sum, data) => sum + data.steps);
  }

  double getAverageStepsForPeriod(DateTime startDate, DateTime endDate) {
    final steps = getStepsForPeriod(startDate, endDate);
    if (steps.isEmpty) return 0.0;
    return getTotalStepsForPeriod(startDate, endDate) / steps.length;
  }

  Future<void> _saveStepData() async {
    final prefs = await SharedPreferences.getInstance();
    final stepsJson = _stepHistory.map((s) => s.toJson()).toList();
    await prefs.setString('step_history', jsonEncode(stepsJson));
  }

  Future<void> _loadStepData() async {
    final prefs = await SharedPreferences.getInstance();
    final stepsJson = prefs.getString('step_history');
    if (stepsJson != null) {
      final stepsList = jsonDecode(stepsJson) as List;
      _stepHistory = stepsList.map((json) => StepData.fromJson(json)).toList();
    }
  }

  Future<void> deleteStepData(StepData stepData) async {
    _stepHistory.remove(stepData);
    await _saveStepData();
    _updateTodaySteps();
  }

  Future<void> clearAllData() async {
    _stepHistory.clear();
    _todaySteps = null;
    await _saveStepData();
  }
}




