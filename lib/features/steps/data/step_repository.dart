import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models/step_data.dart';
import '../domain/models/step_goal.dart';

/// Repository for step data persistence
/// Handles all data storage and retrieval operations
class StepRepository {
  static const String _stepHistoryKey = 'step_history';
  static const String _stepGoalKey = 'step_goal';

  /// Load all step history from storage
  Future<List<StepData>> loadStepHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stepsJson = prefs.getString(_stepHistoryKey);
      if (stepsJson == null) return [];

      final stepsList = jsonDecode(stepsJson) as List;
      return stepsList
          .map((json) => StepData.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading step history: $e');
      return [];
    }
  }

  /// Save step history to storage
  Future<void> saveStepHistory(List<StepData> history) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stepsJson = jsonEncode(history.map((s) => s.toJson()).toList());
      await prefs.setString(_stepHistoryKey, stepsJson);
    } catch (e) {
      print('Error saving step history: $e');
    }
  }

  /// Load step goal from storage
  Future<StepGoal> loadStepGoal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final goalJson = prefs.getString(_stepGoalKey);
      if (goalJson == null) {
        return StepGoal(dailyGoal: StepGoal.defaultDailyGoal);
      }

      final goalMap = jsonDecode(goalJson) as Map<String, dynamic>;
      return StepGoal.fromJson(goalMap);
    } catch (e) {
      print('Error loading step goal: $e');
      return StepGoal(dailyGoal: StepGoal.defaultDailyGoal);
    }
  }

  /// Save step goal to storage
  Future<void> saveStepGoal(StepGoal goal) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final goalJson = jsonEncode(goal.toJson());
      await prefs.setString(_stepGoalKey, goalJson);
    } catch (e) {
      print('Error saving step goal: $e');
    }
  }

  /// Clear all step data
  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_stepHistoryKey);
      await prefs.remove(_stepGoalKey);
    } catch (e) {
      print('Error clearing step data: $e');
    }
  }
}

