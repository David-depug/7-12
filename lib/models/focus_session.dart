import 'package:flutter/foundation.dart';

/// Simple data object for tracking the state of an in-app focus session.
class FocusSession {
  FocusSession({
    required this.duration,
    required this.blockedApps,
    DateTime? startTime,
  })  : startTime = startTime ?? DateTime.now(),
        remainingTime = duration;

  /// Total scheduled duration for the session.
  final Duration duration;

  /// Remaining countdown time. Mutated by the session controller.
  Duration remainingTime;

  /// Apps/categories that will be blocked while the session is active.
  final List<String> blockedApps;

  /// Time when the session started.
  final DateTime startTime;

  /// Convenience getter to know if the session finished.
  bool get isCompleted => remainingTime <= Duration.zero;

  /// Value between 0 and 1 used for progress indicators.
  double get progress {
    if (duration.inSeconds == 0) return 1;
    final completed = duration.inSeconds - remainingTime.inSeconds;
    return (completed / duration.inSeconds).clamp(0, 1);
  }

  /// Helper to subtract time from the countdown.
  void decrement(Duration delta) {
    final next = remainingTime - delta;
    remainingTime = next > Duration.zero ? next : Duration.zero;
  }

  /// Resets the remaining time back to the original duration.
  void reset() {
    remainingTime = duration;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FocusSession &&
        listEquals(other.blockedApps, blockedApps) &&
        other.duration == duration &&
        other.remainingTime == remainingTime &&
        other.startTime == startTime;
  }

  @override
  int get hashCode =>
      Object.hash(duration, remainingTime, startTime, Object.hashAll(blockedApps));
}





