import 'package:flutter/foundation.dart';

class UserModel extends ChangeNotifier {
  UserModel({
    required this.username,
    int xp = 0,
    int level = 1,
    int streakDays = 0,
    int badges = 0,
    int rank = 100,
  })  : _xp = xp,
        _level = level,
        _streakDays = streakDays,
        _badges = badges,
        _rank = rank;

  final String username;
  int _xp;
  int _level;
  int _streakDays;
  int _badges;
  int _rank;

  int get xp => _xp;
  int get level => _level;
  int get streakDays => _streakDays;
  int get badges => _badges;
  int get rank => _rank;

  double get levelProgress {
    final int xpForNextLevel = 100 + (_level - 1) * 50;
    final int xpIntoLevel = _xp % xpForNextLevel;
    return xpForNextLevel == 0 ? 0 : (xpIntoLevel / xpForNextLevel).clamp(0.0, 1.0);
  }

  void addXp(int amount) {
    if (amount <= 0) return;
    _xp += amount;
    while (_xp >= _xpRequiredForLevel(_level + 1)) {
      _level += 1;
    }
    notifyListeners();
  }

  void incrementStreak() {
    _streakDays += 1;
    notifyListeners();
  }

  void awardBadge() {
    _badges += 1;
    notifyListeners();
  }

  void updateRank(int newRank) {
    _rank = newRank;
    notifyListeners();
  }

  int _xpRequiredForLevel(int targetLevel) {
    // Simple progressive ramp: sum of per-level requirements
    int total = 0;
    for (int l = 1; l < targetLevel; l++) {
      total += 100 + (l - 1) * 50;
    }
    return total;
  }
}


