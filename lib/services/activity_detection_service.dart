import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'dart:math';

class ActivityDetectionService {
  static const double activityThreshold = 2.0; // Sensitivity threshold
  static const Duration inactivityCheckInterval = Duration(seconds: 30);
  static const Duration inactivityThreshold = Duration(hours: 4);

  StreamSubscription? _accelerometerSubscription;
  DateTime _lastActivityTime = DateTime.now();
  bool _isMonitoring = false;
  Timer? _inactivityCheckTimer;
  VoidCallback? _onInactivityDetected;

  bool get isMonitoring => _isMonitoring;
  DateTime get lastActivityTime => _lastActivityTime;

  void startMonitoring({required VoidCallback onInactivityDetected}) {
    if (_isMonitoring) return;

    _onInactivityDetected = onInactivityDetected;
    _lastActivityTime = DateTime.now();
    _isMonitoring = true;

    // Listen to accelerometer events
    _accelerometerSubscription = accelerometerEvents.listen((event) {
      final magnitude = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );

      // If movement is detected above threshold, update last activity time
      if (magnitude > activityThreshold) {
        _lastActivityTime = DateTime.now();
      }
    });

    // Check periodically if phone has been inactive
    _inactivityCheckTimer = Timer.periodic(inactivityCheckInterval, (_) {
      _checkInactivity();
    });
  }

  void stopMonitoring() {
    _accelerometerSubscription?.cancel();
    _inactivityCheckTimer?.cancel();
    _isMonitoring = false;
  }

  void _checkInactivity() {
    final timeSinceLastActivity = DateTime.now().difference(_lastActivityTime);
    if (timeSinceLastActivity.compareTo(inactivityThreshold) >= 0) {
      _onInactivityDetected?.call();
    }
  }

  void recordManualActivity() {
    _lastActivityTime = DateTime.now();
  }

  Duration getInactivityDuration() {
    return DateTime.now().difference(_lastActivityTime);
  }

  void dispose() {
    stopMonitoring();
    _onInactivityDetected = null;
  }
}
