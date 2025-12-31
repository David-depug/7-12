import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../constants/app_colors.dart';
import '../../domain/models/step_data.dart';

/// Card widget for displaying today's step progress
class StepProgressCard extends StatelessWidget {
  final int steps;
  final int goal;
  final double progress;
  final StepData? todayData;

  const StepProgressCard({
    super.key,
    required this.steps,
    required this.goal,
    required this.progress,
    this.todayData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.purple.withOpacity(0.3),
            const Color(0xFFF97316).withOpacity(0.2),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Today\'s Steps',
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    steps.toString(),
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.purple,
                      Color(0xFFF97316),
                    ],
                  ),
                ),
                child: const Icon(
                  LucideIcons.footprints,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Goal: $goal steps',
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 12,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.purple),
            ),
          ),
          if (todayData != null) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Distance',
                  '${todayData!.distance.toStringAsFixed(2)} km',
                  LucideIcons.mapPin,
                ),
                _buildStatItem(
                  'Calories',
                  '${todayData!.calories}',
                  LucideIcons.flame,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

