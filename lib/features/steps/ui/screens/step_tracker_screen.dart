import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../constants/app_colors.dart';
import '../../../../main.dart';
import '../../state/step_tracker_state.dart';
import '../../domain/models/step_data.dart';
import '../widgets/step_permission_widget.dart';
import '../widgets/step_progress_card.dart';
import '../widgets/step_stat_card.dart';

/// Data class for Selector to minimize rebuilds
class _StepTrackerScreenData {
  final bool isLoading;
  final bool isInitialized;
  final bool hasPermission;
  final String? errorMessage;
  final int todayStepCount;
  final int dailyGoal;
  final StepData? todaySteps;

  _StepTrackerScreenData({
    required this.isLoading,
    required this.isInitialized,
    required this.hasPermission,
    required this.errorMessage,
    required this.todayStepCount,
    required this.dailyGoal,
    required this.todaySteps,
  });
}

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
      if (!mounted) return; // Prevent accessing context if widget is disposed
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
    // Only refresh if not already initialized to avoid unnecessary refreshes
    if (state == AppLifecycleState.resumed && mounted) {
      final stepState = context.read<StepTrackerState>();
      // Only refresh if not initialized or if permission might have changed
      if (!stepState.isInitialized) {
        stepState.initialize();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.menu, size: 24),
          onPressed: () => rootNavScaffoldKey.currentState?.openDrawer(),
          tooltip: 'Menu',
        ),
        title: Text(
          'Step Tracker',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: () {
              if (mounted) {
                context.read<StepTrackerState>().refresh();
              }
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Selector<StepTrackerState, _StepTrackerScreenData>(
        selector: (_, state) => _StepTrackerScreenData(
          isLoading: state.isLoading,
          isInitialized: state.isInitialized,
          hasPermission: state.hasPermission,
          errorMessage: state.errorMessage,
          todayStepCount: state.todayStepCount,
          dailyGoal: state.dailyGoal,
          todaySteps: state.todaySteps,
        ),
        builder: (context, data, _) {
          if (data.isLoading && !data.isInitialized) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.purple),
            );
          }

          if (!data.hasPermission) {
            return SingleChildScrollView(
              child: StepPermissionWidget(state: context.read<StepTrackerState>()),
            );
          }

          if (data.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.alertCircle,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    data.errorMessage!,
                    style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<StepTrackerState>().refresh(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return _buildContent(context, context.read<StepTrackerState>(), data);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, StepTrackerState state, _StepTrackerScreenData data) {
    final stepCount = data.todayStepCount;
    final goal = data.dailyGoal;
    final progress = (stepCount / goal * 100).clamp(0, 100) / 100;
    final todaySteps = data.todaySteps;

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
          _buildPeriodSelector(context),
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
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.primary.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface,
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
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    side: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
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
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        title: Text(
          'Add Steps',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface),
          decoration: InputDecoration(
            labelText: 'Number of steps',
            labelStyle: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
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
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: Text(
              'Add',
              style: GoogleFonts.inter(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      ),
      child: Row(
        children: [
          _buildPeriodButton(context, 'Daily', 'daily'),
          _buildPeriodButton(context, 'Weekly', 'weekly'),
          _buildPeriodButton(context, 'Monthly', 'monthly'),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(BuildContext context, String label, String period) {
    final isSelected = _selectedPeriod == period;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPeriod = period),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsCards(StepTrackerState state) {
    try {
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
    } catch (e) {
      debugPrint('Error building statistics: $e');
      return const SizedBox.shrink();
    }
  }

  Widget _buildStepChart(StepTrackerState state) {
    try {
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
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
          ),
          child: Center(
            child: Text(
              'No data available',
              style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
            ),
          ),
        );
      }

      // Limit chart data to prevent performance issues (max 30 points)
      final limitedChartData = chartData.length > 30 
          ? chartData.sublist(chartData.length - 30) 
          : chartData;

      // Safety check for empty data
      if (limitedChartData.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
          ),
          child: Center(
            child: Text(
              'No data available',
              style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
            ),
          ),
        );
      }

      final maxSteps = limitedChartData.map((d) => d.steps).reduce((a, b) => a > b ? a : b);
      final maxY = maxSteps > 0 ? ((maxSteps / 1000).ceil() * 1000).toDouble() : 1000.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.primary.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step Chart',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface,
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
                    spots: limitedChartData.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value.steps.toDouble());
                    }).toList(),
                    isCurved: true,
                    color: Theme.of(context).colorScheme.primary,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
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
    } catch (e) {
      debugPrint('Error building chart: $e');
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        ),
        child: Center(
          child: Text(
            'Unable to display chart',
            style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
          ),
        ),
      );
    }
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
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...recentSteps.map((data) => _buildHistoryItem(context, data)),
      ],
    );
  }

  Widget _buildHistoryItem(BuildContext context, data) {
    final dateStr = '${data.date.day}/${data.date.month}/${data.date.year}';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${data.distance.toStringAsFixed(2)} km • ${data.calories} cal',
                style: GoogleFonts.inter(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Text(
            '${data.steps} steps',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

