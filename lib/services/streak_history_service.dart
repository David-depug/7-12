import 'package:shared_preferences/shared_preferences.dart';

/// Manages persistence and loading of streak history dates.
///
/// Dates are stored as ISO yyyy-MM-dd strings in SharedPreferences.
class StreakHistoryService {
  static const String _datesKey = 'streak_history_dates';
  static const String _lastIncrementKey = 'last_streak_increment_date';

  /// Returns a set of unique streak dates (date-only, no time) for all history.
  static Future<Set<DateTime>> loadStreakDates() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_datesKey) ?? <String>[];
    final result = <DateTime>{};

    for (final s in rawList) {
      try {
        final dt = DateTime.parse(s);
        result.add(DateTime(dt.year, dt.month, dt.day));
      } catch (_) {
        // Ignore malformed entries
      }
    }

    return result;
  }

  /// Adds today's date to the streak history if it hasn't been added yet today.
  ///
  /// This is intended to be called when the user successfully increments their streak.
  static Future<void> addTodayIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayKey = _toDateKey(now);

    final lastIncrement = prefs.getString(_lastIncrementKey);
    if (lastIncrement == todayKey) {
      // Already recorded today
      return;
    }

    final dates = prefs.getStringList(_datesKey) ?? <String>[];
    if (!dates.contains(todayKey)) {
      dates.add(todayKey);
    }

    await prefs.setStringList(_datesKey, dates);
    await prefs.setString(_lastIncrementKey, todayKey);
  }

  /// Calculates current streak (consecutive days ending today),
  /// best streak (max consecutive days), and total active days.
  static Future<StreakSummary> loadSummary() async {
    final dates = await loadStreakDates();
    if (dates.isEmpty) {
      return const StreakSummary(
        currentStreak: 0,
        bestStreak: 0,
        totalDays: 0,
      );
    }

    final sorted = dates.toList()
      ..sort((a, b) => a.compareTo(b));

    int bestStreak = 1;
    int currentRun = 1;

    for (int i = 1; i < sorted.length; i++) {
      final prev = sorted[i - 1];
      final cur = sorted[i];
      if (_isNextDay(prev, cur)) {
        currentRun += 1;
      } else if (!_isSameDay(prev, cur)) {
        currentRun = 1;
      }
      if (currentRun > bestStreak) {
        bestStreak = currentRun;
      }
    }

    // Compute current streak ending today
    final today = DateTime.now();
    int currentStreak = 0;
    var cursor = DateTime(today.year, today.month, today.day);
    final dateSet = dates;

    while (dateSet.contains(cursor)) {
      currentStreak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return StreakSummary(
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      totalDays: dates.length,
    );
  }

  static String _toDateKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool _isNextDay(DateTime a, DateTime b) {
    final next = DateTime(a.year, a.month, a.day).add(const Duration(days: 1));
    return _isSameDay(next, b);
  }
}

class StreakSummary {
  final int currentStreak;
  final int bestStreak;
  final int totalDays;

  const StreakSummary({
    required this.currentStreak,
    required this.bestStreak,
    required this.totalDays,
  });
}


