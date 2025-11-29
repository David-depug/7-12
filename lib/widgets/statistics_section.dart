import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class StatisticsSection extends StatelessWidget {
  final int totalSessions;
  final int totalTimeMinutes;
  final int currentStreak;
  final int xpEarned;

  const StatisticsSection({
    Key? key,
    required this.totalSessions,
    required this.totalTimeMinutes,
    required this.currentStreak,
    required this.xpEarned,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Progress',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.purple,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildStatCard(
                icon: Icons.timer,
                title: 'Focus Time',
                value: _formatDuration(totalTimeMinutes),
                color: AppColors.purple,
              ),
              _buildStatCard(
                icon: Icons.psychology,
                title: 'Sessions',
                value: totalSessions.toString(),
                color: AppColors.green,
              ),
              _buildStatCard(
                icon: Icons.local_fire_department,
                title: 'Streak',
                value: '$currentStreak days',
                color: AppColors.orange,
              ),
              _buildStatCard(
                icon: Icons.star,
                title: 'XP Earned',
                value: xpEarned.toString(),
                color: AppColors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${mins}m';
    } else {
      return '${mins}m';
    }
  }
}









