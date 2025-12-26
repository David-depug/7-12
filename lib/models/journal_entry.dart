/// Journal entry model for MindQuest app.
/// Follows the project's manual serialization pattern.
class JournalEntry {
  final String id;
  final DateTime date;
  final List<QuestionAnswer> answers;
  final String? mood;
  final DateTime timestamp;
  final int? xpAwarded;

  JournalEntry({
    required this.id,
    required this.date,
    required this.answers,
    this.mood,
    required this.timestamp,
    this.xpAwarded,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'answers': answers.map((a) => a.toJson()).toList(),
        'mood': mood,
        'timestamp': timestamp.toIso8601String(),
        'xpAwarded': xpAwarded,
      };

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        answers: (json['answers'] as List)
            .map((a) => QuestionAnswer.fromJson(a as Map<String, dynamic>))
            .toList(),
        mood: json['mood'] as String?,
        timestamp: DateTime.parse(json['timestamp'] as String),
        xpAwarded: json['xpAwarded'] as int?,
      );
}

class QuestionAnswer {
  final String question;
  final String answer;

  QuestionAnswer({
    required this.question,
    required this.answer,
  });

  Map<String, dynamic> toJson() => {
        'question': question,
        'answer': answer,
      };

  factory QuestionAnswer.fromJson(Map<String, dynamic> json) => QuestionAnswer(
        question: json['question'] as String,
        answer: json['answer'] as String,
      );
}

