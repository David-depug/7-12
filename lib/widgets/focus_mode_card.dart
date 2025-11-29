import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/focus_session.dart';
import '../constants/app_colors.dart';

class FocusModeCard extends StatelessWidget {
  final FocusSession? session;
  final VoidCallback? onStart;
  final VoidCallback? onEnd;
  final bool isActive;

  const FocusModeCard({
    super.key,
    this.session,
    this.onStart,
    this.onEnd,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isActive ? 'Focus Mode Active' : 'Focus Zone',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: isActive ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isActive 
                        ? 'Stay focused! Apps are blocked.' 
                        : 'Block distractions, level up your focus.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isActive ? Colors.white70 : Colors.grey,
                    ),
                  ),
                ],
              ),
              if (isActive)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.psychology,
                    color: AppColors.green,
                    size: 24,
                  ),
                ).animate().scale(
                  begin: const Offset(1.0, 1.0),
                  end: const Offset(1.1, 1.1),
                  duration: 2000.ms,
                ).then().scale(
                  begin: const Offset(1.1, 1.1),
                  end: const Offset(1.0, 1.0),
                  duration: 2000.ms,
                ),
            ],
          ),
          const SizedBox(height: 24),
          if (isActive && session != null) ...[
            _buildActiveSessionInfo(session!),
            const SizedBox(height: 24),
          ],
          _buildActionButton(),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).scale();
  }

  Widget _buildActiveSessionInfo(FocusSession session) {
    final remaining = session.remainingTime;
    final progress = 1.0 - (remaining.inSeconds / session.duration.inSeconds);
    
    return Builder(
      builder: (context) => Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Time Remaining',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
              Text(
                _formatDuration(remaining),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.green),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${session.blockedApps.length} apps blocked',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}% complete',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isActive ? onEnd : onStart,
        icon: Icon(isActive ? Icons.stop : Icons.play_arrow),
        label: Text(isActive ? 'End Focus' : 'Start Focus'),
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive ? AppColors.red : AppColors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }
}
