/// Domain model for step data
/// Contains all step-related information for a single day
class StepData {
  final DateTime date;
  final int steps;
  final double distance; // in kilometers
  final int calories;
  final Duration activeTime;

  StepData({
    required this.date,
    required this.steps,
    this.distance = 0.0,
    this.calories = 0,
    this.activeTime = const Duration(seconds: 0),
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'steps': steps,
        'distance': distance,
        'calories': calories,
        'activeTime': activeTime.inSeconds,
      };

  factory StepData.fromJson(Map<String, dynamic> json) => StepData(
        date: DateTime.parse(json['date']),
        steps: json['steps'] as int,
        distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
        calories: json['calories'] as int? ?? 0,
        activeTime: Duration(seconds: json['activeTime'] as int? ?? 0),
      );

  /// Calculate XP based on steps (domain logic)
  int calculateXP({int goalSteps = 10000}) {
    // Base XP for reaching daily goal
    int baseXP = 20;

    // Bonus XP for exceeding goal
    if (steps >= goalSteps) {
      int bonus = ((steps - goalSteps) / 1000).floor() * 5;
      return baseXP + bonus;
    }

    // Partial XP for partial progress
    return (steps / goalSteps * baseXP).floor();
  }

  StepData copyWith({
    DateTime? date,
    int? steps,
    double? distance,
    int? calories,
    Duration? activeTime,
  }) {
    return StepData(
      date: date ?? this.date,
      steps: steps ?? this.steps,
      distance: distance ?? this.distance,
      calories: calories ?? this.calories,
      activeTime: activeTime ?? this.activeTime,
    );
  }
}

