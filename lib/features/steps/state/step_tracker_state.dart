import 'package:flutter/foundation.dart';
import '../domain/models/step_data.dart';
import '../domain/models/step_goal.dart';
import '../data/step_repository.dart';
import '../services/step_sensor_service.dart';
import '../services/step_permission_service.dart';
import 'dart:async';

/// State management for step tracking feature
/// 
/// Architecture:
/// - Domain: Models (StepData, StepGoal) with business logic
/// - Data: Repository handles persistence (SharedPreferences)
/// - Services: Sensor service (pedometer) and permission service
/// - State: This class manages all state and coordinates between layers
/// - UI: Screens and widgets consume this state via Provider
/// 
/// Data flow: Sensor → State → Repository → UI
class StepTrackerState extends ChangeNotifier {
  final StepRepository _repository;
  final StepSensorService _sensorService;
  final StepPermissionService _permissionService;

  // State variables
  bool _isInitialized = false;
  bool _isLoading = false;
  bool _hasPermission = false;
  bool _isTracking = false;
  String? _errorMessage;

  StepData? _todaySteps;
  List<StepData> _stepHistory = [];
  StepGoal _goal = StepGoal(dailyGoal: StepGoal.defaultDailyGoal);

  StreamSubscription<StepData>? _stepSubscription;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  bool get hasPermission => _hasPermission;
  bool get isTracking => _isTracking;
  String? get errorMessage => _errorMessage;
  StepData? get todaySteps => _todaySteps;
  List<StepData> get stepHistory => List.unmodifiable(_stepHistory);
  StepGoal get goal => _goal;
  int get todayStepCount => _todaySteps?.steps ?? 0;
  int get dailyGoal => _goal.dailyGoal;
  double get progressPercentage => 
      (todayStepCount / _goal.dailyGoal * 100).clamp(0, 100);
  bool get goalReached => todayStepCount >= _goal.dailyGoal;

  StepTrackerState({
    StepRepository? repository,
    StepSensorService? sensorService,
    StepPermissionService? permissionService,
  })  : _repository = repository ?? StepRepository(),
        _sensorService = sensorService ?? StepSensorService(),
        _permissionService = permissionService ?? StepPermissionService();

  /// Initialize step tracking (load data, check permissions, start sensor)
  Future<void> initialize() async {
    if (_isInitialized) return;

    _setLoading(true);
    _clearError();

    try {
      // Load persisted data
      await _loadData();

      // Check and request permissions
      await _checkPermissions();

      // Start sensor if permission granted (non-blocking - don't wait for first event)
      if (_hasPermission) {
        // Don't await - let it start in background to avoid blocking UI
        _startTracking().catchError((error) {
          // Handle errors but don't block initialization
          _setError('Sensor initialization warning: $error');
        });
      }

      _isInitialized = true;
    } catch (e) {
      _setError('Failed to initialize step tracking: $e');
    } finally {
      // Always clear loading state, even if sensor is still initializing
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Load data from repository
  Future<void> _loadData() async {
    _stepHistory = await _repository.loadStepHistory();
    _goal = await _repository.loadStepGoal();
    _updateTodaySteps();
  }

  /// Update today's steps from history
  void _updateTodaySteps() {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

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

  /// Check and request permissions
  Future<void> _checkPermissions() async {
    _hasPermission = await _permissionService.hasPermission();
    if (!_hasPermission) {
      _hasPermission = await _permissionService.requestPermission();
    }
  }

  /// Start tracking steps from sensor
  Future<void> _startTracking() async {
    if (_isTracking) return;

    try {
      // Initialize sensor (non-blocking - won't wait for first stream event)
      final initialized = await _sensorService.initialize();
      if (!initialized) {
        throw Exception('Failed to initialize sensor');
      }

      _stepSubscription = _sensorService.stepStream.listen(
        _onStepUpdate,
        onError: (error) {
          _setError('Sensor error: $error');
        },
      );

      _isTracking = true;
    } catch (e) {
      _setError('Failed to start tracking: $e');
      _isTracking = false;
      rethrow; // Re-throw so caller can handle it
    }
  }

  /// Handle step updates from sensor
  void _onStepUpdate(StepData stepData) {
    _todaySteps = stepData;
    _updateStepHistory(stepData);
    notifyListeners();
  }

  /// Update step history with new data
  void _updateStepHistory(StepData stepData) {
    final existingIndex = _stepHistory.indexWhere((data) {
      final dataDate = DateTime(data.date.year, data.date.month, data.date.day);
      final stepDate = DateTime(stepData.date.year, stepData.date.month, stepData.date.day);
      return dataDate.isAtSameMomentAs(stepDate);
    });

    if (existingIndex >= 0) {
      _stepHistory[existingIndex] = stepData;
    } else {
      _stepHistory.add(stepData);
    }

    // Persist to storage
    _repository.saveStepHistory(_stepHistory);
  }

  /// Manually update steps (for manual entry or testing)
  Future<void> updateSteps(int steps, {
    double? distance,
    int? calories,
    Duration? activeTime,
  }) async {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    final calculatedDistance = distance ?? (steps * 0.0007);
    final calculatedCalories = calories ?? (steps * 0.04).round();

    final stepData = StepData(
      date: todayDate,
      steps: steps.clamp(0, 999999),
      distance: calculatedDistance,
      calories: calculatedCalories,
      activeTime: activeTime ?? const Duration(seconds: 0),
    );

    _onStepUpdate(stepData);
  }

  /// Add steps to current count
  Future<void> addSteps(int additionalSteps) async {
    final currentSteps = todayStepCount;
    await updateSteps(currentSteps + additionalSteps);
  }

  /// Set daily step goal
  Future<void> setGoal(int goalSteps) async {
    if (goalSteps <= 0) return;

    _goal = StepGoal(
      dailyGoal: goalSteps,
      lastUpdated: DateTime.now(),
    );

    await _repository.saveStepGoal(_goal);
    notifyListeners();
  }

  /// Request permission (can be called from UI)
  Future<bool> requestPermission() async {
    _hasPermission = await _permissionService.requestPermission();
    if (_hasPermission && !_isTracking) {
      // Start tracking without blocking - don't wait for first sensor event
      _startTracking().catchError((error) {
        // If tracking fails, still clear loading and show error
        _setError('Failed to start tracking: $error');
        _setLoading(false);
      });
    }
    notifyListeners();
    return _hasPermission;
  }

  /// Open app settings (for permanently denied permissions)
  Future<bool> openSettings() async {
    return await _permissionService.openSettings();
  }

  /// Get steps for a specific date range
  List<StepData> getStepsForPeriod(DateTime startDate, DateTime endDate) {
    return _stepHistory.where((data) {
      return data.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
             data.date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Get total steps for a period
  int getTotalStepsForPeriod(DateTime startDate, DateTime endDate) {
    final steps = getStepsForPeriod(startDate, endDate);
    return steps.fold(0, (sum, data) => sum + data.steps);
  }

  /// Get average steps for a period
  double getAverageStepsForPeriod(DateTime startDate, DateTime endDate) {
    final steps = getStepsForPeriod(startDate, endDate);
    if (steps.isEmpty) return 0.0;
    return getTotalStepsForPeriod(startDate, endDate) / steps.length;
  }

  /// Refresh data (reload from storage and sensor)
  Future<void> refresh() async {
    _setLoading(true);
    _clearError();
    
    try {
      await _loadData();
      
      // Re-check permissions (in case they changed)
      await _checkPermissions();
      
      // Start tracking if permission granted and not already tracking
      if (_hasPermission && !_isTracking) {
        // Don't await - let it start in background
        _startTracking().catchError((error) {
          _setError('Sensor warning: $error');
        });
      }
    } catch (e) {
      _setError('Failed to refresh: $e');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  @override
  void dispose() {
    _stepSubscription?.cancel();
    _sensorService.dispose();
    super.dispose();
  }
}

