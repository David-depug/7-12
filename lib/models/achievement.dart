import 'package:flutter/material.dart';

enum AchievementType {
  focusStreak,
  totalSessions,
  totalTime,
  level,
  special,
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final Color color;
  final AchievementType type;
  final int requirement;
  final int? currentProgress;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final int xpReward;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.type,
    required this.requirement,
    this.currentProgress,
    this.isUnlocked = false,
    this.unlockedAt,
    this.xpReward = 50,
  });

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? icon,
    Color? color,
    AchievementType? type,
    int? requirement,
    int? currentProgress,
    bool? isUnlocked,
    DateTime? unlockedAt,
    int? xpReward,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      type: type ?? this.type,
      requirement: requirement ?? this.requirement,
      currentProgress: currentProgress ?? this.currentProgress,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      xpReward: xpReward ?? this.xpReward,
    );
  }

  double get progress {
    if (currentProgress == null) return 0.0;
    return (currentProgress! / requirement).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'icon': icon,
    'color': color.value,
    'type': type.name,
    'requirement': requirement,
    'currentProgress': currentProgress,
    'isUnlocked': isUnlocked,
    'unlockedAt': unlockedAt?.toIso8601String(),
    'xpReward': xpReward,
  };

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    icon: json['icon'],
    color: Color(json['color']),
    type: AchievementType.values.firstWhere((e) => e.name == json['type']),
    requirement: json['requirement'],
    currentProgress: json['currentProgress'],
    isUnlocked: json['isUnlocked'] ?? false,
    unlockedAt: json['unlockedAt'] != null ? DateTime.parse(json['unlockedAt']) : null,
    xpReward: json['xpReward'] ?? 50,
  );

  static List<Achievement> getDefaultAchievements() => [
    // Focus Streak Achievements
    Achievement(
      id: 'streak_3',
      title: 'Getting Started',
      description: 'Focus for 3 days in a row',
      icon: '🔥',
      color: Colors.orange,
      type: AchievementType.focusStreak,
      requirement: 3,
    ),
    Achievement(
      id: 'streak_7',
      title: 'Week Warrior',
      description: 'Focus for 7 days in a row',
      icon: '💪',
      color: Colors.red,
      type: AchievementType.focusStreak,
      requirement: 7,
    ),
    Achievement(
      id: 'streak_30',
      title: 'Focus Master',
      description: 'Focus for 30 days in a row',
      icon: '👑',
      color: Colors.purple,
      type: AchievementType.focusStreak,
      requirement: 30,
    ),
    
    // Total Sessions Achievements
    Achievement(
      id: 'sessions_10',
      title: 'Dedicated',
      description: 'Complete 10 focus sessions',
      icon: '🎯',
      color: Colors.blue,
      type: AchievementType.totalSessions,
      requirement: 10,
    ),
    Achievement(
      id: 'sessions_50',
      title: 'Focused Mind',
      description: 'Complete 50 focus sessions',
      icon: '🧠',
      color: Colors.green,
      type: AchievementType.totalSessions,
      requirement: 50,
    ),
    Achievement(
      id: 'sessions_100',
      title: 'Zen Master',
      description: 'Complete 100 focus sessions',
      icon: '🧘',
      color: Colors.teal,
      type: AchievementType.totalSessions,
      requirement: 100,
    ),
    
    // Total Time Achievements
    Achievement(
      id: 'time_10h',
      title: 'Time Keeper',
      description: 'Focus for 10 hours total',
      icon: '⏰',
      color: Colors.indigo,
      type: AchievementType.totalTime,
      requirement: 600, // 10 hours in minutes
    ),
    Achievement(
      id: 'time_50h',
      title: 'Time Master',
      description: 'Focus for 50 hours total',
      icon: '⏳',
      color: Colors.deepPurple,
      type: AchievementType.totalTime,
      requirement: 3000, // 50 hours in minutes
    ),
    
    // Level Achievements
    Achievement(
      id: 'level_5',
      title: 'Rising Star',
      description: 'Reach level 5',
      icon: '⭐',
      color: Colors.yellow,
      type: AchievementType.level,
      requirement: 5,
    ),
    Achievement(
      id: 'level_10',
      title: 'Focus Champion',
      description: 'Reach level 10',
      icon: '🏆',
      color: Colors.amber,
      type: AchievementType.level,
      requirement: 10,
    ),
    
    // Special Achievements
    Achievement(
      id: 'first_session',
      title: 'First Steps',
      description: 'Complete your first focus session',
      icon: '🎉',
      color: Colors.pink,
      type: AchievementType.special,
      requirement: 1,
    ),
    Achievement(
      id: 'perfect_week',
      title: 'Perfect Week',
      description: 'Focus every day for a week',
      icon: '✨',
      color: Colors.cyan,
      type: AchievementType.special,
      requirement: 7,
    ),
  ];
}









