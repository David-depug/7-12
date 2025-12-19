/// Domain model for step goal configuration
class StepGoal {
  final int dailyGoal;
  final DateTime? lastUpdated;

  StepGoal({
    required this.dailyGoal,
    this.lastUpdated,
  }) : assert(dailyGoal > 0, 'Daily goal must be greater than 0');

  static const int defaultDailyGoal = 10000;

  Map<String, dynamic> toJson() => {
        'dailyGoal': dailyGoal,
        'lastUpdated': lastUpdated?.toIso8601String(),
      };

  factory StepGoal.fromJson(Map<String, dynamic> json) => StepGoal(
        dailyGoal: json['dailyGoal'] as int? ?? defaultDailyGoal,
        lastUpdated: json['lastUpdated'] != null
            ? DateTime.parse(json['lastUpdated'] as String)
            : null,
      );

  StepGoal copyWith({
    int? dailyGoal,
    DateTime? lastUpdated,
  }) {
    return StepGoal(
      dailyGoal: dailyGoal ?? this.dailyGoal,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

