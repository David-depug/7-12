import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../constants/app_colors.dart';

/// Reusable stat card widget for displaying step statistics
class StepStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const StepStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? AppColors.purple;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: cardColor, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 20,
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
      ),
    );
  }
}

