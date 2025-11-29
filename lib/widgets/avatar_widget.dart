import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AvatarWidget extends StatelessWidget {
  final int level;
  final int xp;
  final bool isActive;
  final VoidCallback? onTap;

  const AvatarWidget({
    Key? key,
    required this.level,
    required this.xp,
    this.isActive = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isActive ? AppColors.primaryGradient : [Colors.grey[200]!, Colors.grey[300]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (isActive ? AppColors.purple : Colors.grey).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.green.withOpacity(0.2),
                  child: Icon(
                    isActive ? Icons.psychology : Icons.person,
                    size: 40,
                    color: isActive ? Colors.white : Colors.black,
                  ),
                ),
                if (isActive)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Level $level',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$xp XP',
              style: TextStyle(
                color: isActive ? Colors.white70 : Colors.grey,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: (xp % 100) / 100,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.green),
            ),
          ],
        ),
      ),
    );
  }
}









