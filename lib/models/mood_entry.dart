/// Mood entry model for MindQuest app.
/// Tracks daily mood with 5 levels: Very Happy, Happy, Neutral, Sad, Very Sad
class MoodEntry {
  final String id;
  final String mood; // "Very Happy", "Happy", "Neutral", "Sad", "Very Sad"
  final DateTime date;
  final DateTime timestamp;

  MoodEntry({
    required this.id,
    required this.mood,
    required this.date,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'mood': mood,
        'date': date.toIso8601String(),
        'timestamp': timestamp.toIso8601String(),
      };

  factory MoodEntry.fromJson(Map<String, dynamic> json) => MoodEntry(
        id: json['id'] as String,
        mood: json['mood'] as String,
        date: DateTime.parse(json['date'] as String),
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  /// Get mood value (1-5) for analysis
  int get moodValue {
    switch (mood) {
      case 'Very Happy':
        return 5;
      case 'Happy':
        return 4;
      case 'Neutral':
        return 3;
      case 'Sad':
        return 2;
      case 'Very Sad':
        return 1;
      default:
        return 3;
    }
  }

  /// Get emoji for mood
  String get emoji {
    switch (mood) {
      case 'Very Happy':
        return '😄';
      case 'Happy':
        return '😊';
      case 'Neutral':
        return '😐';
      case 'Sad':
        return '😢';
      case 'Very Sad':
        return '😭';
      default:
        return '😐';
    }
  }

  /// Get color for mood
  int get colorValue {
    switch (mood) {
      case 'Very Happy':
        return 0xFF4CAF50; // Green
      case 'Happy':
        return 0xFF8BC34A; // Light Green
      case 'Neutral':
        return 0xFFFFC107; // Amber
      case 'Sad':
        return 0xFFFF9800; // Orange
      case 'Very Sad':
        return 0xFFF44336; // Red
      default:
        return 0xFFFFC107;
    }
  }
}

/// Available mood options
class MoodOptions {
  static const List<String> moods = [
    'Very Happy',
    'Happy',
    'Neutral',
    'Sad',
    'Very Sad',
  ];

  static const List<String> emojis = ['😄', '😊', '😐', '😢', '😭'];

  static const List<int> colors = [
    0xFF4CAF50, // Very Happy - Green
    0xFF8BC34A, // Happy - Light Green
    0xFFFFC107, // Neutral - Amber
    0xFFFF9800, // Sad - Orange
    0xFFF44336, // Very Sad - Red
  ];
}

