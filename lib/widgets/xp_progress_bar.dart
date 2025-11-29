import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class XPProgressBar extends StatelessWidget {
  final int currentXP;
  final int levelXP;
  final int level;

  const XPProgressBar({
    Key? key,
    required this.currentXP,
    required this.levelXP,
    required this.level,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final progress = currentXP / levelXP;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Level $level',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$currentXP / $levelXP XP',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.green),
          ),
        ],
      ),
    );
  }
}









