import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../constants/app_colors.dart';

class AchievementsWidget extends StatelessWidget {
  final List<Achievement> achievements;
  final VoidCallback? onAchievementTap;

  const AchievementsWidget({
    Key? key,
    required this.achievements,
    this.onAchievementTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Achievements',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.purple,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              final achievement = achievements[index];
              return _buildAchievementCard(achievement);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    return Card(
      color: achievement.isUnlocked ? Colors.white : Colors.grey[100],
      child: InkWell(
        onTap: achievement.isUnlocked ? onAchievementTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              achievement.icon,
              style: TextStyle(
                fontSize: 24,
                color: achievement.isUnlocked 
                    ? achievement.color 
                    : Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              achievement.title,
              style: TextStyle(
                fontSize: 10,
                color: achievement.isUnlocked 
                    ? Colors.black 
                    : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (achievement.isUnlocked)
              const Icon(
                Icons.check_circle,
                color: AppColors.green,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
}









