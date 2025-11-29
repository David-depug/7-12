class SleepSession {
  final DateTime startTime;
  final DateTime? endTime;
  final Duration? duration;
  final SleepQuality quality;
  final List<String> notes;
  bool isCompleted;

  SleepSession({
    required this.startTime,
    this.endTime,
    this.duration,
    this.quality = SleepQuality.good,
    this.notes = const [],
    this.isCompleted = false,
  });

  Duration get elapsedTime {
    if (endTime != null) {
      return endTime!.difference(startTime);
    }
    return DateTime.now().difference(startTime);
  }

  bool get isActive => !isCompleted && endTime == null;

  int calculateXP() {
    if (!isCompleted || duration == null) return 0;
    
    // Base XP for completing sleep session
    int baseXP = 30;
    
    // Bonus XP for longer sleep (7-9 hours is optimal)
    int hours = duration!.inHours;
    int durationBonus = 0;
    if (hours >= 7 && hours <= 9) {
      durationBonus = 20; // Optimal sleep
    } else if (hours >= 6 && hours < 7) {
      durationBonus = 10; // Good sleep
    } else if (hours >= 9 && hours <= 10) {
      durationBonus = 15; // Long sleep
    }
    
    // Quality bonus
    int qualityBonus = quality.index * 5;
    
    return baseXP + durationBonus + qualityBonus;
  }

  Map<String, dynamic> toJson() => {
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'duration': duration?.inMilliseconds,
    'quality': quality.name,
    'notes': notes,
    'isCompleted': isCompleted,
  };

  factory SleepSession.fromJson(Map<String, dynamic> json) => SleepSession(
    startTime: DateTime.parse(json['startTime']),
    endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
    duration: json['duration'] != null 
        ? Duration(milliseconds: json['duration']) 
        : null,
    quality: SleepQuality.values.firstWhere(
      (e) => e.name == json['quality'],
      orElse: () => SleepQuality.good,
    ),
    notes: List<String>.from(json['notes'] ?? []),
    isCompleted: json['isCompleted'] ?? false,
  );
}

enum SleepQuality {
  poor,
  fair,
  good,
  excellent,
}


