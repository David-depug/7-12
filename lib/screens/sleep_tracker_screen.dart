import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/sleep_session.dart';
import '../services/sleep_service.dart';
import '../constants/app_colors.dart';
import '../main.dart';

class SleepTrackerScreen extends StatefulWidget {
  const SleepTrackerScreen({super.key});

  @override
  State<SleepTrackerScreen> createState() => _SleepTrackerScreenState();
}

class _SleepTrackerScreenState extends State<SleepTrackerScreen> {
  final SleepService _sleepService = SleepService();
  bool _isLoading = false;
  String _selectedPeriod = 'weekly'; // 'weekly' or 'monthly'

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    setState(() => _isLoading = true);
    await _sleepService.initialize();
    setState(() => _isLoading = false);
  }

  Future<void> _startSleepTracking() async {
    await _sleepService.startSleepTracking();
    setState(() {});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sleep tracking started! 🌙'),
          backgroundColor: AppColors.purple,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _endSleepTracking() async {
    if (!_sleepService.isTracking) return;

    showDialog(
      context: context,
      builder: (context) => _SleepEndDialog(
        onEnd: (quality, notes) async {
          await _sleepService.endSleepTracking(quality: quality, notes: notes);
          setState(() {});
          if (mounted) {
            Navigator.of(context).pop();
            final session = _sleepService.sessions.last;
            final xp = session.calculateXP();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Sleep session completed! +$xp XP 🌟'),
                backgroundColor: AppColors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1B1B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B1B1B),
        elevation: 0,
        title: Text(
          'Sleep Tracker',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            LucideIcons.menu,
            color: Colors.white,
            size: 24,
          ),
          onPressed: () {
            rootNavScaffoldKey.currentState?.openDrawer();
          },
          tooltip: 'Menu',
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.purple))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Current Sleep Session Card
                  if (_sleepService.isTracking) _buildActiveSessionCard(),
                  if (!_sleepService.isTracking) _buildStartSleepCard(),
                  const SizedBox(height: 20),

                  // Period Selector
                  _buildPeriodSelector(),
                  const SizedBox(height: 20),

                  // Overview Stats
                  _buildOverviewStats(),
                  const SizedBox(height: 20),

                  // Sleep Chart
                  _buildSleepChart(),
                  const SizedBox(height: 20),

                  // Recent Sessions
                  _buildRecentSessions(),
                ],
              ),
            ),
    );
  }

  Widget _buildStartSleepCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.purple.withOpacity(0.3),
            AppColors.blue.withOpacity(0.2),
          ],
        ),
        border: Border.all(
          color: AppColors.purple.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  color: AppColors.purple.withOpacity(0.2),
                ),
                child: const Icon(
                  LucideIcons.moon,
                  color: AppColors.purple,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Ready to Sleep?',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Track your sleep to improve your well-being',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _startSleepTracking,
                  icon: const Icon(LucideIcons.moon),
                  label: Text(
                    'Start Sleep Tracking',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveSessionCard() {
    final session = _sleepService.currentSession!;
    final elapsed = session.elapsedTime;
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes % 60;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.green.withOpacity(0.3),
            AppColors.teal.withOpacity(0.2),
          ],
        ),
        border: Border.all(
          color: AppColors.green.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            LucideIcons.moon,
            color: AppColors.green,
            size: 40,
          ),
          const SizedBox(height: 16),
          Text(
            'Sleeping...',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$hours hours $minutes minutes',
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _endSleepTracking,
              icon: const Icon(LucideIcons.sun),
              label: Text(
                'End Sleep Session',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFF2A2A2A),
        border: Border.all(color: const Color(0xFF3A3A3A)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildPeriodButton('Weekly', 'weekly', LucideIcons.calendarDays),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildPeriodButton('Monthly', 'monthly', LucideIcons.calendarRange),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, String value, IconData icon) {
    final isSelected = _selectedPeriod == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedPeriod = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? AppColors.purple : const Color(0xFF3A3A3A),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewStats() {
    final avgDuration = _sleepService.getAverageSleepDuration();
    final avgQuality = _sleepService.getAverageSleepQuality();
    final hours = avgDuration.inHours;
    final minutes = avgDuration.inMinutes % 60;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Avg. Sleep',
            value: hours > 0 ? '${hours}h ${minutes}m' : '--',
            icon: LucideIcons.clock,
            color: AppColors.purple,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Quality',
            value: _getQualityText(avgQuality),
            icon: LucideIcons.star,
            color: AppColors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              color: color.withOpacity(0.2),
            ),
            child: Icon(icon, color: color, size: 25),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepChart() {
    return FutureBuilder<List<SleepSession>>(
      future: _selectedPeriod == 'weekly'
          ? _sleepService.getWeeklySessions()
          : _sleepService.getMonthlySessions(),
      builder: (context, snapshot) {
        final sessions = snapshot.data ?? [];
        
        if (sessions.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFF2A2A2A),
            ),
            child: Center(
              child: Text(
                'No sleep data available',
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.barChart3, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Sleep Duration Trend',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 1,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.white.withOpacity(0.1),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= sessions.length) return const Text('');
                            final date = sessions[value.toInt()].startTime;
                            return Text(
                              '${date.day}/${date.month}',
                              style: GoogleFonts.inter(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 10,
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.toInt()}h',
                              style: GoogleFonts.inter(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 10,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: sessions.asMap().entries.map((entry) {
                      final index = entry.key;
                      final session = entry.value;
                      final hours = session.duration?.inHours.toDouble() ?? 0.0;
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: hours,
                            color: _getQualityColor(session.quality),
                            width: 16,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentSessions() {
    return FutureBuilder<List<SleepSession>>(
      future: _selectedPeriod == 'weekly'
          ? _sleepService.getWeeklySessions()
          : _sleepService.getMonthlySessions(),
      builder: (context, snapshot) {
        final sessions = snapshot.data ?? [];
        
        if (sessions.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.history, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Recent Sessions',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...sessions.take(5).map((session) => _buildSessionCard(session)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSessionCard(SleepSession session) {
    final duration = session.duration;
    final hours = duration?.inHours ?? 0;
    final minutes = duration != null ? (duration.inMinutes % 60) : 0;
    final date = session.startTime;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: _getQualityColor(session.quality).withOpacity(0.2),
            ),
            child: Icon(
              LucideIcons.moon,
              color: _getQualityColor(session.quality),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  duration != null
                      ? '$hours hours $minutes minutes • ${_getQualityText(session.quality.index.toDouble())}'
                      : 'Incomplete',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          if (duration != null)
            Text(
              '+${session.calculateXP()} XP',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.green,
              ),
            ),
        ],
      ),
    );
  }

  Color _getQualityColor(SleepQuality quality) {
    switch (quality) {
      case SleepQuality.excellent:
        return AppColors.green;
      case SleepQuality.good:
        return AppColors.blue;
      case SleepQuality.fair:
        return AppColors.orange;
      case SleepQuality.poor:
        return AppColors.red;
    }
  }

  String _getQualityText(double qualityIndex) {
    if (qualityIndex >= 3) return 'Excellent';
    if (qualityIndex >= 2) return 'Good';
    if (qualityIndex >= 1) return 'Fair';
    return 'Poor';
  }
}

class _SleepEndDialog extends StatefulWidget {
  final Function(SleepQuality, List<String>) onEnd;

  const _SleepEndDialog({required this.onEnd});

  @override
  State<_SleepEndDialog> createState() => _SleepEndDialogState();
}

class _SleepEndDialogState extends State<_SleepEndDialog> {
  SleepQuality _selectedQuality = SleepQuality.good;
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2A2A2A),
      title: Text(
        'End Sleep Session',
        style: GoogleFonts.inter(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How was your sleep?',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          const SizedBox(height: 16),
          ...SleepQuality.values.map((quality) => RadioListTile<SleepQuality>(
            title: Text(
              quality.name.toUpperCase(),
              style: GoogleFonts.inter(color: Colors.white),
            ),
            value: quality,
            groupValue: _selectedQuality,
            onChanged: (value) => setState(() => _selectedQuality = value!),
            activeColor: AppColors.purple,
          )),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            decoration: InputDecoration(
              labelText: 'Notes (optional)',
              labelStyle: GoogleFonts.inter(color: Colors.white70),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            style: GoogleFonts.inter(color: Colors.white),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: GoogleFonts.inter(color: Colors.white70),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            final notes = _notesController.text.trim();
            widget.onEnd(
              _selectedQuality,
              notes.isNotEmpty ? [notes] : [],
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.purple,
          ),
          child: Text(
            'End Session',
            style: GoogleFonts.inter(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

