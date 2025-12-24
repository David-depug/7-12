import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/theme_model.dart';
import '../constants/app_colors.dart';

/// Theme switcher widget with Dark Mode and Bright Mood buttons
class ThemeSwitcher extends StatelessWidget {
  const ThemeSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeModel>(
      builder: (context, themeModel, child) {
        final isDarkMode = themeModel.isDarkMode;
        final isLightMode = themeModel.isLightMode;

        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Section Title
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 12),
                child: Text(
                  'Theme',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : AppColors.deepCharcoal.withOpacity(0.7),
                  ),
                ),
              ),

              // Theme Buttons Row
              Row(
                children: [
                  // Bright Mood Button (Light Mode)
                  Expanded(
                    child: _ThemeButton(
                      icon: LucideIcons.sun,
                      label: 'Bright Mood',
                      description: 'Light & Calming',
                      isSelected: isLightMode,
                      onTap: () => themeModel.setLightMode(),
                      colors: isLightMode
                          ? [AppColors.sereneTeal, AppColors.sereneTeal.withOpacity(0.8)]
                          : [Colors.grey.shade300, Colors.grey.shade200],
                      textColor: isLightMode ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Dark Mode Button
                  Expanded(
                    child: _ThemeButton(
                      icon: LucideIcons.moon,
                      label: 'Dark Mode',
                      description: 'Easy on Eyes',
                      isSelected: isDarkMode,
                      onTap: () => themeModel.setDarkMode(),
                      colors: isDarkMode
                          ? [AppColors.purple, AppColors.purple.withOpacity(0.8)]
                          : [Colors.grey.shade300, Colors.grey.shade200],
                      textColor: isDarkMode ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Individual theme button widget
class _ThemeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;
  final List<Color> colors;
  final Color textColor;

  const _ThemeButton({
    required this.icon,
    required this.label,
    required this.description,
    required this.isSelected,
    required this.onTap,
    required this.colors,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colors[0].withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
          border: Border.all(
            color: isSelected
                ? colors[0]
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? Colors.white.withOpacity(0.2)
                    : Colors.transparent,
              ),
              child: Icon(
                icon,
                color: textColor,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            
            // Label
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            
            // Description
            Text(
              description,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: textColor.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact theme toggle for app bar or drawer
class CompactThemeToggle extends StatelessWidget {
  const CompactThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeModel>(
      builder: (context, themeModel, child) {
        final isDark = themeModel.isDarkMode;

        return InkWell(
          onTap: () => themeModel.toggleTheme(),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isDark ? LucideIcons.moon : LucideIcons.sun,
                  size: 18,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : AppColors.deepCharcoal,
                ),
                const SizedBox(width: 8),
                Text(
                  isDark ? 'Dark' : 'Light',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : AppColors.deepCharcoal,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


