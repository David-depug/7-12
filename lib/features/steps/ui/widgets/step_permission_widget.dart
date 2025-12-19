import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../constants/app_colors.dart';
import '../../state/step_tracker_state.dart';

/// Widget for requesting step tracking permissions
class StepPermissionWidget extends StatelessWidget {
  final StepTrackerState state;

  const StepPermissionWidget({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Colors.orange.withOpacity(0.2),
            Colors.red.withOpacity(0.1),
          ],
        ),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            LucideIcons.alertCircle,
            color: Colors.orange,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Permission Required',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'To track your steps, we need permission to access your device\'s motion sensors.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              final granted = await state.requestPermission();
              if (granted) {
                // Permission granted - re-initialize to start tracking
                // This ensures the state updates and loading clears
                if (!state.isInitialized) {
                  await state.initialize();
                }
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      'Permission denied. Please enable it in app settings.',
                    ),
                    action: SnackBarAction(
                      label: 'Settings',
                      onPressed: () async {
                        await state.openSettings();
                        // After returning from settings, re-check permissions
                        if (context.mounted) {
                          await Future.delayed(const Duration(milliseconds: 500));
                          await state.refresh();
                        }
                      },
                    ),
                  ),
                );
              }
            },
            icon: const Icon(LucideIcons.shield),
            label: const Text('Grant Permission'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

