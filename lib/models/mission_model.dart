import 'package:flutter/foundation.dart';

class Mission {
  Mission({
    required this.id,
    required this.title,
    required this.description,
    this.xpReward = 10,
    this.completed = false,
  });

  final String id;
  final String title;
  final String description;
  final int xpReward;
  bool completed;
}

class MissionsModel extends ChangeNotifier {
  MissionsModel({List<Mission>? initialMissions})
      : _missions = initialMissions ?? [
          Mission(id: 'm1', title: '5 min breathing', description: 'Box breathing 5-5-5-5'),
          Mission(id: 'm2', title: 'Journal entry', description: 'Reflect for 3 minutes'),
          Mission(id: 'm3', title: 'Focus sprint', description: '10 minutes pomodoro'),
        ];

  final List<Mission> _missions;

  List<Mission> get missions => List.unmodifiable(_missions);

  void toggleMission(String id) {
    final int index = _missions.indexWhere((m) => m.id == id);
    if (index == -1) return;
    _missions[index].completed = !_missions[index].completed;
    notifyListeners();
  }

  void resetAll() {
    for (final m in _missions) {
      m.completed = false;
    }
    notifyListeners();
  }

  int get completedCount => _missions.where((m) => m.completed).length;
}


