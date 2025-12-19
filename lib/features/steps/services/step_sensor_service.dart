import 'dart:async';
import 'package:pedometer/pedometer.dart';
import '../domain/models/step_data.dart';

/// Service for interacting with step sensor hardware
/// Handles pedometer stream and step counting
class StepSensorService {
  StreamSubscription<StepCount>? _stepCountSubscription;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusSubscription;
  
  int _initialStepCount = 0;
  DateTime? _lastStepCountTime;
  PedestrianStatus? _status;
  bool _initialCountSet = false; // Flag to prevent race condition

  /// Stream controller for step updates
  final _stepStreamController = StreamController<StepData>.broadcast();
  Stream<StepData> get stepStream => _stepStreamController.stream;

  /// Current pedestrian status
  PedestrianStatus? get status => _status;

  /// Initialize step sensor and start listening
  Future<bool> initialize() async {
    try {
      // Try to get initial step count with timeout to avoid blocking
      // If it doesn't arrive immediately, the stream listener will handle it
      try {
        final initialCount = await Pedometer.stepCountStream
            .first
            .timeout(const Duration(seconds: 2));
        if (!_initialCountSet) {
          _initialStepCount = initialCount.steps;
          _lastStepCountTime = initialCount.timeStamp;
          _initialCountSet = true;
        }
      } catch (e) {
        // Timeout or error is OK - stream listener will handle first event when it arrives
        print('Initial step count not available yet, will use first stream event: $e');
      }

      // Start listening to streams (after attempting to get initial count)
      // This prevents blocking if the stream doesn't emit immediately
      _stepCountSubscription = Pedometer.stepCountStream.listen(
        (StepCount event) {
          // Set initial step count on first event if not already set
          if (!_initialCountSet) {
            _initialStepCount = event.steps;
            _lastStepCountTime = event.timeStamp;
            _initialCountSet = true;
          }
          _onStepCount(event);
        },
        onError: _onStepCountError,
      );

      // Listen to pedestrian status
      _pedestrianStatusSubscription = Pedometer.pedestrianStatusStream.listen(
        _onPedestrianStatus,
        onError: _onPedestrianStatusError,
      );

      // Try to get initial pedestrian status (non-blocking)
      try {
        final initialStatus = await Pedometer.pedestrianStatusStream
            .first
            .timeout(const Duration(seconds: 1));
        _status = initialStatus;
      } catch (e) {
        // Status stream may not be available on all platforms or may timeout
        // This is OK - stream listener will handle status updates when they arrive
        print('Warning: Could not get initial pedestrian status: $e');
      }

      return true;
    } catch (e) {
      print('Error initializing step sensor: $e');
      return false;
    }
  }

  /// Handle step count updates
  void _onStepCount(StepCount event) {
    final currentSteps = event.steps - _initialStepCount;
    final now = DateTime.now();

    // Calculate distance (average step length ~0.7m)
    final distance = currentSteps * 0.0007;

    // Calculate calories (rough estimate: 0.04 calories per step)
    final calories = (currentSteps * 0.04).round();

    // Calculate active time based on status
    // Note: Active time calculation simplified - can be enhanced based on actual status
    Duration activeTime = const Duration(seconds: 0);
    // Only calculate active time if we have steps (indicating movement)
    if (currentSteps > 0 && _lastStepCountTime != null) {
      activeTime = now.difference(_lastStepCountTime!);
    }

    final stepData = StepData(
      date: DateTime(now.year, now.month, now.day),
      steps: currentSteps.clamp(0, 999999),
      distance: distance,
      calories: calories,
      activeTime: activeTime,
    );

    _lastStepCountTime = now;
    _stepStreamController.add(stepData);
  }

  /// Handle step count errors
  void _onStepCountError(error) {
    print('Step count error: $error');
    _stepStreamController.addError(error);
  }

  /// Handle pedestrian status updates
  void _onPedestrianStatus(PedestrianStatus event) {
    _status = event;
  }

  /// Handle pedestrian status errors
  void _onPedestrianStatusError(error) {
    print('Pedestrian status error: $error');
  }

  /// Dispose resources
  void dispose() {
    _stepCountSubscription?.cancel();
    _pedestrianStatusSubscription?.cancel();
    _stepStreamController.close();
  }

  /// Get current step count (synchronous, may be outdated)
  Future<int> getCurrentStepCount() async {
    try {
      final stepCount = await Pedometer.stepCountStream.first;
      return (stepCount.steps - _initialStepCount).clamp(0, 999999);
    } catch (e) {
      print('Error getting current step count: $e');
      return 0;
    }
  }
}

