import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/streak_history_service.dart';

class StreakHistoryPage extends StatelessWidget {
  const StreakHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Streak History',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: FutureBuilder<Set<DateTime>>(
        future: StreakHistoryService.loadStreakDates(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final dates = snapshot.data ?? <DateTime>{};
          if (dates.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      size: 48,
                      color: isDark ? AppColors.purple : AppColors.sereneTeal,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No streak data yet',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Complete your daily missions and claim your XP to start building your streak.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return FutureBuilder<StreakSummary>(
            future: StreakHistoryService.loadSummary(),
            builder: (context, summarySnapshot) {
              final summary = summarySnapshot.data;
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (summary != null)
                      _buildSummaryCard(context, summary),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _buildCalendar(context, dates),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, StreakSummary summary) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? AppColors.purple : AppColors.sereneTeal;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withOpacity(0.15),
            accent.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: accent.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            icon: Icons.local_fire_department,
            label: 'Current',
            value: '${summary.currentStreak}d',
            color: accent,
            theme: theme,
          ),
          _buildSummaryItem(
            icon: Icons.star,
            label: 'Best',
            value: '${summary.bestStreak}d',
            color: const Color(0xFFFFC107),
            theme: theme,
          ),
          _buildSummaryItem(
            icon: Icons.calendar_today,
            label: 'Active',
            value: '${summary.totalDays}d',
            color: theme.colorScheme.primary,
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required ThemeData theme,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  Widget _buildCalendar(BuildContext context, Set<DateTime> streakDates) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final firstOfMonth = DateTime(now.year, now.month, 1);
    final firstWeekday = firstOfMonth.weekday; // 1 (Mon) .. 7 (Sun)

    // Flutter's DateTime weekday uses Monday=1. We want the calendar to start on Monday.
    final leadingEmptyDays = firstWeekday - 1; // 0..6

    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final totalCells = leadingEmptyDays + daysInMonth;
    final rows = (totalCells / 7).ceil();

    final accent = theme.brightness == Brightness.dark
        ? AppColors.purple
        : AppColors.sereneTeal;

    Set<DateTime> normalizedStreakDates = streakDates
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_monthName(now.month)} ${now.year}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            _WeekdayLabel('M'),
            _WeekdayLabel('T'),
            _WeekdayLabel('W'),
            _WeekdayLabel('T'),
            _WeekdayLabel('F'),
            _WeekdayLabel('S'),
            _WeekdayLabel('S'),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemCount: rows * 7,
            itemBuilder: (context, index) {
              final dayNumber = index - leadingEmptyDays + 1;
              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox.shrink();
              }

              final date = DateTime(now.year, now.month, dayNumber);
              final isToday = _isSameDay(date, now);
              final isActive = normalizedStreakDates.contains(date);

              Color? bg;
              Color textColor = theme.colorScheme.onSurface.withOpacity(0.8);
              if (isActive) {
                bg = accent.withOpacity(isToday ? 0.9 : 0.2);
                textColor = isToday ? Colors.white : accent;
              } else if (isToday) {
                bg = theme.colorScheme.primary.withOpacity(0.15);
                textColor = theme.colorScheme.primary;
              }

              return Container(
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$dayNumber',
                  style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        fontWeight:
                            isToday ? FontWeight.w600 : FontWeight.w500,
                        color: textColor,
                      ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _monthName(int month) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[month - 1];
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _WeekdayLabel extends StatelessWidget {
  final String text;

  const _WeekdayLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.6),
              ),
        ),
      ),
    );
  }
}


