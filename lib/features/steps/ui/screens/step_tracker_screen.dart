import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../constants/app_colors.dart';
import '../../../../main.dart';
import '../../state/step_tracker_state.dart';
import '../widgets/step_permission_widget.dart';
import '../widgets/step_progress_card.dart';
import '../widgets/step_stat_card.dart';

/// Main step tracking screen
/// Displays step data, charts, and statistics
class StepTrackerScreen extends StatefulWidget {
  const StepTrackerScreen({super.key});

  @override
  State<StepTrackerScreen> createState() => _StepTrackerScreenState();
}

class _StepTrackerScreenState extends State<StepTrackerScreen> with WidgetsBindingObserver {
  String _selectedPeriod = 'weekly'; // 'daily', 'weekly', 'monthly'

  @override
  void initState() {
    super.initState();
    // Listen to app lifecycle changes to detect permission grants
    WidgetsBinding.instance.addObserver(this);
    // Initialize step tracking when screen is first shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<StepTrackerState>();
      if (!state.isInitialized) {
        state.initialize();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When app resumes (e.g., after permission dialog), re-check permissions
    if (state == AppLifecycleState.resumed) {
      final stepState = context.read<StepTrackerState>();
      // Re-check permissions and re-initialize if needed
      stepState.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1B1B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B1B1B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.menu, color: Colors.white, size: 24),
          onPressed: () => rootNavScaffoldKey.currentState?.openDrawer(),
          tooltip: 'Menu',
        ),
        title: Text(
          'Step Tracker',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, color: Colors.white),
            onPressed: () {
              context.read<StepTrackerState>().refresh();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Consumer<StepTrackerState>(
        builder: (context, state, _) {
          if (state.isLoading && !state.isInitialized) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.purple),
            );
          }

          if (!state.hasPermission) {
            return SingleChildScrollView(
              child: StepPermissionWidget(state: state),
            );
          }

          if (state.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    LucideIcons.alertCircle,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.errorMessage!,
                    style: GoogleFonts.inter(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => state.refresh(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return _buildContent(context, state);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, StepTrackerState state) {
    final stepCount = state.todayStepCount;
    final goal = state.dailyGoal;
    final progress = state.progressPercentage / 100;
    final todaySteps = state.todaySteps;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Today's Steps Card
          StepProgressCard(
            steps: stepCount,
            goal: goal,
            progress: progress,
            todayData: todaySteps,
          ),
          const SizedBox(height: 20),

          // Quick Actions
          _buildQuickActionsCard(context, state, goal - stepCount, goal),
          const SizedBox(height: 20),

          // Period Selector
          _buildPeriodSelector(),
          const SizedBox(height: 20),

          // Statistics Cards
          _buildStatisticsCards(state),
          const SizedBox(height: 20),

          // Step Chart
          _buildStepChart(state),
          const SizedBox(height: 20),

          // Recent History
          _buildRecentHistory(state),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard(
    BuildContext context,
    StepTrackerState state,
    int remainingSteps,
    int goal,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showAddStepsDialog(context, state),
                  icon: const Icon(LucideIcons.plus),
                  label: const Text('Add Steps'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    state.updateSteps(goal);
                  },
                  icon: const Icon(LucideIcons.target),
                  label: const Text('Set to Goal'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddStepsDialog(BuildContext context, StepTrackerState state) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: Text(
          'Add Steps',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: GoogleFonts.inter(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Number of steps',
            labelStyle: GoogleFonts.inter(color: Colors.white70),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white70),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.purple),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () {
              final steps = int.tryParse(controller.text) ?? 0;
              if (steps > 0) {
                state.addSteps(steps);
                Navigator.pop(context);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added $steps steps! 🚶'),
                      backgroundColor: AppColors.purple,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: Text(
              'Add',
              style: GoogleFonts.inter(color: AppColors.purple),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.1),
      ),
      child: Row(
        children: [
          _buildPeriodButton('Daily', 'daily'),
          _buildPeriodButton('Weekly', 'weekly'),
          _buildPeriodButton('Monthly', 'monthly'),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, String period) {
    final isSelected = _selectedPeriod == period;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPeriod = period),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isSelected ? AppColors.purple : Colors.transparent,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: isSelected ? Colors.white : Colors.white70,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsCards(StepTrackerState state) {
    final now = DateTime.now();
    DateTime startDate;

    switch (_selectedPeriod) {
      case 'daily':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'weekly':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        break;
      case 'monthly':
        startDate = DateTime(now.year, now.month, 1);
        break;
      default:
        startDate = now.subtract(const Duration(days: 7));
    }

    final totalSteps = state.getTotalStepsForPeriod(startDate, now);
    final avgSteps = state.getAverageStepsForPeriod(startDate, now);
    final steps = state.getStepsForPeriod(startDate, now);

    return Row(
      children: [
        Expanded(
          child: StepStatCard(
            label: 'Total',
            value: totalSteps.toString(),
            icon: LucideIcons.trendingUp,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StepStatCard(
            label: 'Average',
            value: avgSteps.toStringAsFixed(0),
            icon: LucideIcons.barChart3,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StepStatCard(
            label: 'Days',
            value: steps.length.toString(),
            icon: LucideIcons.calendar,
          ),
        ),
      ],
    );
  }

  Widget _buildStepChart(StepTrackerState state) {
    final now = DateTime.now();
    List chartData;

    switch (_selectedPeriod) {
      case 'daily':
        chartData = [if (state.todaySteps != null) state.todaySteps!];
        break;
      case 'weekly':
        final startDate = now.subtract(Duration(days: now.weekday - 1));
        chartData = state.getStepsForPeriod(startDate, now);
        break;
      case 'monthly':
        final startDate = DateTime(now.year, now.month, 1);
        chartData = state.getStepsForPeriod(startDate, now);
        break;
      default:
        chartData = [];
    }

    if (chartData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withOpacity(0.05),
        ),
        child: Center(
          child: Text(
            'No data available',
            style: GoogleFonts.inter(color: Colors.white70),
          ),
        ),
      );
    }

    final maxSteps = chartData.map((d) => d.steps).reduce((a, b) => a > b ? a : b);
    final maxY = ((maxSteps / 1000).ceil() * 1000).toDouble();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step Chart',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: chartData.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value.steps.toDouble());
                    }).toList(),
                    isCurved: true,
                    color: AppColors.purple,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.purple.withOpacity(0.2),
                    ),
                  ),
                ],
                minY: 0,
                maxY: maxY,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentHistory(StepTrackerState state) {
    final recentSteps = state.stepHistory.take(7).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    if (recentSteps.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent History',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...recentSteps.map((data) => _buildHistoryItem(data)),
      ],
    );
  }

  Widget _buildHistoryItem(data) {
    final dateStr = '${data.date.day}/${data.date.month}/${data.date.year}';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateStr,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${data.distance.toStringAsFixed(2)} km • ${data.calories} cal',
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Text(
            '${data.steps} steps',
            style: GoogleFonts.inter(
              color: AppColors.purple,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

