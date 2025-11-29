import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import '../services/screen_time_service.dart';
import '../main.dart';


class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _hasPermission = false;
  bool _isLoading = false;
  List<Map<String, dynamic>> usageData = [];
  int totalScreenTime = 0;
  String _selectedTimePeriod = 'daily'; // 'daily', 'yesterday', 'weekly', 'monthly', '3months', '6months', '1year'

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    try {
      final hasPermission = await ScreenTimeService.checkUsageStatsPermission();
      setState(() {
        _hasPermission = hasPermission;
      });
      if (hasPermission) {
        _loadUsageStats();
      }
    } catch (e) {
      debugPrint("Permission check failed: $e");
      setState(() {
        _hasPermission = false;
      });
    }
  }

  Future<void> _requestPermission() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await ScreenTimeService.requestUsageStatsPermission();
      _showPermissionDialog();
    } catch (e) {
      debugPrint('Error requesting permission: $e');
      _showPermissionDialog();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUsageStats() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Note: Period selection is handled by the service internally

      List<Map<String, dynamic>> realUsageStats;
      if (_selectedTimePeriod == 'weekly') {
        realUsageStats = await ScreenTimeService.getBetterWeeklyUsage();
      } else {
        realUsageStats = await ScreenTimeService.getUltraAccurateUsageStats(period: _selectedTimePeriod);
      }
      
      // Debug: Print detailed information about the data
      print('=== USAGE STATS DEBUG ===');
      print('Total apps found: ${realUsageStats.length}');
      
      if (realUsageStats.isNotEmpty) {
        print('Sample usage data: ${realUsageStats.first}');
        
        // Show top 5 apps with their raw data
        final sortedStats = List.from(realUsageStats)
          ..sort((a, b) => (b['usageTime'] as int).compareTo(a['usageTime'] as int));
        
        print('Top 5 apps by usage:');
        for (int i = 0; i < 5 && i < sortedStats.length; i++) {
          final app = sortedStats[i];
          final rawTime = app['usageTime'] as int;
          final timeInSeconds = rawTime ~/ 1000;
          final timeInMinutes = timeInSeconds ~/ 60;
          final timeInHours = timeInMinutes ~/ 60;
          
          print('${i + 1}. ${app['appName']}: $rawTime ms = $timeInSeconds sec = $timeInMinutes min = $timeInHours hours');
        }
      }
      
      if (mounted) {
        setState(() {
          usageData = realUsageStats.where((d) => d['usageTime'] > 0).toList()
            ..sort((a, b) => (b['usageTime'] as int).compareTo(a['usageTime'] as int));
          // Convert milliseconds to seconds for display
          totalScreenTime = realUsageStats.fold(0, (sum, item) => sum + ((item['usageTime'] as int) ~/ 1000));
          
          // Debug: Print the calculated total time
          print('=== CALCULATED TOTALS ===');
          print('Total screen time (seconds): $totalScreenTime');
          print('Total screen time (minutes): ${totalScreenTime / 60}');
          print('Total screen time (hours): ${totalScreenTime / 3600}');
          print('Apps with usage: ${usageData.length}');
        });
      }
    } catch (e) {
      debugPrint("Failed to load usage stats: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: Text(
            'Enable Usage Access',
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
                'To view real screen time data, please:',
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '1. Tap "Open Settings" below',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '2. Look for "my_app" in the list',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '3. If you don\'t see "my_app", scroll down or search',
                style: GoogleFonts.inter(
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '4. Toggle "Permit usage access" ON',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '5. Return to the app',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _openUsageStatsSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Open Settings',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openUsageStatsSettings() {
    // This will open the usage stats settings page
    ScreenTimeService.requestUsageStatsPermission();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1B1B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B1B1B),
        elevation: 0,
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
        title: Text(
          'Screen Time Analytics',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              setState(() {
                _isLoading = true;
              });
              await _loadUsageStats();
              setState(() {
                _isLoading = false;
              });
            },
            icon: const Icon(LucideIcons.refreshCw, color: Colors.white),
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Time Period Selector
            _buildTimePeriodSelector(),
            const SizedBox(height: 20),
            
            // Debug Info (only show if no permission or data issues)
            if (!_hasPermission || usageData.isEmpty) ...[
              _buildDebugInfo(),
              const SizedBox(height: 20),
            ],
            
            // Permission Request Section
            if (!_hasPermission) ...[
              _buildPermissionRequestCard(),
              const SizedBox(height: 20),
            ],
            
            // Overview Cards
            _buildOverviewCards(),
            const SizedBox(height: 20),
            
            // Focus Score
            _buildFocusScoreCard(),
            const SizedBox(height: 20),
            
            // Usage Chart
            _buildUsageChart(),
            const SizedBox(height: 20),
            
            // Category Breakdown
            _buildCategoryBreakdown(),
            const SizedBox(height: 20),
            
            // Top Apps
            _buildTopApps(),
            const SizedBox(height: 20),
            
            // App Usage Visualization
            _buildAppUsageVisualization(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFF2A2A2A),
        border: Border.all(color: const Color(0xFF3A3A3A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Time Period',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTimePeriodButton('Today', 'daily', LucideIcons.calendar),
                const SizedBox(width: 8),
                _buildTimePeriodButton('Yesterday', 'yesterday', LucideIcons.calendar),
                const SizedBox(width: 8),
                _buildTimePeriodButton('Weekly', 'weekly', LucideIcons.calendarDays),
                const SizedBox(width: 8),
                _buildTimePeriodButton('Monthly', 'monthly', LucideIcons.calendarRange),
                const SizedBox(width: 8),
                _buildTimePeriodButton('3 Months', '3months', LucideIcons.calendar),
                const SizedBox(width: 8),
                _buildTimePeriodButton('6 Months', '6months', LucideIcons.calendar),
                const SizedBox(width: 8),
                _buildTimePeriodButton('1 Year', '1year', LucideIcons.calendar),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePeriodButton(String label, String value, IconData icon) {
    final isSelected = _selectedTimePeriod == value;
    return GestureDetector(
      onTap: () async {
        setState(() {
          _selectedTimePeriod = value;
        });
        await _loadUsageStats();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFF3A3A3A),
          border: Border.all(
            color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFF4A4A4A),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.orange.withOpacity(0.1),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.info, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Text(
                'Usage Data Debug Info',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Permission Status: ${_hasPermission ? "Granted" : "Not Granted"}',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
          ),
          Text(
            'Data Count: ${usageData.length} apps',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
          ),
          Text(
            'Total Time: ${_formatTime(totalScreenTime)}',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () async {
              try {
                final realStats = await ScreenTimeService.getUltraAccurateUsageStats(period: _selectedTimePeriod);
                final totalTimeMs = realStats.fold(0, (sum, item) => sum + (item['usageTime'] as int));
                final totalTimeHours = totalTimeMs / (1000 * 60 * 60);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Found ${realStats.length} apps. Total time: ${totalTimeHours.toStringAsFixed(2)} hours'),
                    duration: const Duration(seconds: 5),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Validation failed: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              minimumSize: const Size(double.infinity, 32),
            ),
            child: Text(
              'Validate Data Accuracy',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionRequestCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange.withOpacity(0.2),
            Colors.orange.withOpacity(0.1),
          ],
        ),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
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
                  color: Colors.orange.withOpacity(0.2),
                ),
                child: const Icon(
                  LucideIcons.shield,
                  color: Colors.orange,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Enable Usage Access',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'To view real screen time data, please enable usage access permission.',
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
                  onPressed: _isLoading ? null : _requestPermission,
                  icon: _isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(LucideIcons.shield),
                  label: Text(
                    _isLoading ? 'Requesting...' : 'Enable Usage Access',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
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

  Widget _buildOverviewCards() {
    String timeLabel;
    switch (_selectedTimePeriod) {
      case 'yesterday':
        timeLabel = 'Yesterday';
        break;
      case 'weekly':
        timeLabel = 'This Week';
        break;
      case 'monthly':
        timeLabel = 'This Month';
        break;
      case '3months':
        timeLabel = 'Last 3 Months';
        break;
      case '6months':
        timeLabel = 'Last 6 Months';
        break;
      case '1year':
        timeLabel = 'Last Year';
        break;
      default:
        timeLabel = 'Today';
    }

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: timeLabel,
            value: _formatTime(totalScreenTime),
            icon: LucideIcons.clock,
            color: const Color(0xFF7C3AED),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Apps Used',
            value: '${usageData.length}',
            icon: LucideIcons.smartphone,
            color: const Color(0xFF4CAF50),
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
            child: Icon(
              icon,
              color: color,
              size: 25,
            ),
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

  Widget _buildFocusScoreCard() {
    final focusScore = _calculateFocusScore();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.target, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Focus Score',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  children: [
                    CircularProgressIndicator(
                      value: focusScore / 100,
                      strokeWidth: 8,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getScoreColor(focusScore),
                      ),
                    ),
                    Center(
                      child: Text(
                        '$focusScore',
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _getScoreMessage(focusScore),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUsageChart() {
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
                'Weekly Usage Trend',
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
            child: FutureBuilder<List<FlSpot>>(
              future: _loadWeeklyTrendData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF7C3AED),
                    ),
                  );
                }
                
                final spots = snapshot.data ?? _generateWeeklyData();
                
                return LineChart(
                  LineChartData(
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
                            const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                            return Text(
                              days[value.toInt() % 7],
                              style: GoogleFonts.inter(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
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
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: const Color(0xFF7C3AED),
                        barWidth: 3,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: const Color(0xFF7C3AED),
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: const Color(0xFF7C3AED).withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
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
              const Icon(LucideIcons.pieChart, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'Category Breakdown',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
            ),
          const SizedBox(height: 16),
          ...usageData.take(5).map((app) {
            final percentage = totalScreenTime > 0
                ? ((((app['usageTime'] as int) ~/ 1000) / totalScreenTime) * 100).round()
                : 0;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  _AppIconWidget(
                    packageName: app['packageName'] as String,
                    appName: app['appName'] as String,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      app['appName'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    '${percentage}%',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTopApps() {
    final topApps = _getTopApps();
    
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
              const Icon(LucideIcons.smartphone, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'Most Used Apps',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...topApps.map((app) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                _AppIconWidget(
                  packageName: app['packageName'] as String,
                  appName: app['name'] as String,
                  size: 40,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app['name'],
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        app['time'],
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    // Block app functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Block ${app['name']} functionality coming soon!'),
                        backgroundColor: const Color(0xFF7C3AED),
                      ),
                    );
                  },
                  icon: const Icon(
                    LucideIcons.shield,
                    color: Colors.orange,
                    size: 16,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildAppUsageVisualization() {
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
              const Icon(LucideIcons.pieChart, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'App Usage Distribution',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Circular chart
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: usageData.isEmpty
                      ? const CircularProgressIndicator(value: 1.0, color: Colors.grey)
                      : CustomPaint(
                          painter: CircularChartPainter(usageData, totalScreenTime),
                        ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Total', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text(
                      _formatTime(totalScreenTime),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    if (totalSeconds < 60) return '$totalSeconds secs';
    final int minutes = totalSeconds ~/ 60;
    final int hours = minutes ~/ 60;
    final int remainingMinutes = minutes % 60;

    if (hours > 0) {
      return '${hours} hr ${remainingMinutes} mins';
    } else if (minutes > 0) {
      return '${minutes} mins';
    } else {
      return '$totalSeconds secs';
    }
  }

  int _calculateFocusScore() {
    if (usageData.isEmpty) return 0;
    
    // Simple focus score calculation based on app diversity and total time
    final productiveApps = usageData.where((app) {
      final appName = app['appName'] as String;
      return appName.toLowerCase().contains('chrome') ||
        appName.toLowerCase().contains('notes') ||
        appName.toLowerCase().contains('calendar') ||
        appName.toLowerCase().contains('email');
    }).length;
    
    final totalApps = usageData.length;
    final productiveRatio = totalApps > 0 ? productiveApps / totalApps : 0;
    
    // Base score from productive ratio, adjusted by total time
    final baseScore = (productiveRatio * 100).round();
    final timeAdjustment = totalScreenTime > 3600 ? -10 : 0; // Penalty for excessive usage
    
    return (baseScore + timeAdjustment).clamp(0, 100);
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return const Color(0xFF4CAF50);
    if (score >= 60) return const Color(0xFFFFC107);
    if (score >= 40) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  String _getScoreMessage(int score) {
    if (score >= 80) return 'Excellent focus! Keep it up!';
    if (score >= 60) return 'Good focus, room for improvement';
    if (score >= 40) return 'Moderate focus, try to reduce distractions';
    return 'Low focus, consider blocking more apps';
  }


  List<FlSpot> _generateWeeklyData() {
    // This will be replaced with real data loading
    return List.generate(7, (index) {
      final baseHours = (totalScreenTime / 3600) / 7; // Distribute current usage across week
      final randomVariation = (index % 3 - 1) * 0.5;
      return FlSpot(index.toDouble(), (baseHours + randomVariation).clamp(0.0, 12.0));
    });
  }

  // Load real weekly trend data
  Future<List<FlSpot>> _loadWeeklyTrendData() async {
    try {
      final dailyData = await ScreenTimeService.getDailyUsageForTrend();
      
      if (dailyData.isEmpty) {
        // Fallback to generated data if no real data available
        return _generateWeeklyData();
      }
      
      // Convert real daily data to chart spots
      List<FlSpot> spots = [];
      for (var day in dailyData) {
        final dayNumber = day['day'] as int;
        final totalHours = day['totalHours'] as double;
        spots.add(FlSpot(dayNumber.toDouble(), totalHours));
      }
      
      print('=== WEEKLY TREND CHART DATA ===');
      for (int i = 0; i < spots.length; i++) {
        print('Day ${i + 1}: ${spots[i].y.toStringAsFixed(2)} hours');
      }
      
      return spots;
    } catch (e) {
      print('Error loading weekly trend data: $e');
      return _generateWeeklyData();
    }
  }

  List<Map<String, dynamic>> _getTopApps() {
    return usageData.take(5).map((app) => {
          'name': app['appName'] as String,
          'packageName': app['packageName'] as String,
          'time': _formatTime((app['usageTime'] as int) ~/ 1000), // Convert ms to seconds
        }).toList();
  }
}

// Circular chart painter for screen time visualization
class CircularChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> usageData;
  final int totalTime;
  final List<Color> colors = [
    Colors.blueAccent,
    Colors.red,
    Colors.green,
    Colors.purple,
    Colors.orange,
    Colors.teal,
    Colors.pink
  ];

  CircularChartPainter(this.usageData, this.totalTime);

  @override
  void paint(Canvas canvas, Size size) {
    if (totalTime == 0) return;

    double startAngle = -pi / 2;
    const double sweepAngle = 2 * pi;
    const double strokeWidth = 20.0;

    final Paint backgroundPaint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width / 2, backgroundPaint);

    final List<Map<String, dynamic>> sortedData = usageData.where((d) => d['usageTime'] > 0).toList()
      ..sort((a, b) => (b['usageTime'] as int).compareTo(a['usageTime'] as int));

    for (int i = 0; i < sortedData.take(5).length; i++) {
      final data = sortedData[i];
      final double fraction = ((data['usageTime'] as int) ~/ 1000) / totalTime; // Convert ms to seconds
      final double segmentAngle = sweepAngle * fraction;

      final Paint segmentPaint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: Offset(size.width / 2, size.height / 2), radius: size.width / 2),
        startAngle,
        segmentAngle,
        false,
        segmentPaint,
      );

      startAngle += segmentAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

// Widget to display actual app icons
class _AppIconWidget extends StatelessWidget {
  final String packageName;
  final String appName;
  final double size;

  const _AppIconWidget({
    required this.packageName,
    required this.appName,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.2),
        color: _getAppColor(appName).withOpacity(0.1),
        border: Border.all(
          color: _getAppColor(appName).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Icon(
        _getAppIcon(appName),
        size: size * 0.6,
        color: _getAppColor(appName),
      ),
    );
  }


  Color _getAppColor(String appName) {
    if (appName.contains('Instagram')) return Colors.blueAccent;
    if (appName.contains('YouTube')) return Colors.red;
    if (appName.contains('Chrome')) return Colors.orange;
    if (appName.contains('Discord')) return Colors.purple;
    if (appName.contains('Spotify')) return Colors.green;
    if (appName.contains('TikTok')) return Colors.black;
    if (appName.contains('Facebook')) return Colors.blue;
    if (appName.contains('Twitter')) return Colors.lightBlue;
    if (appName.contains('Snapchat')) return Colors.yellow;
    if (appName.contains('WhatsApp')) return Colors.green;
    if (appName.contains('Telegram')) return Colors.blue;
    if (appName.contains('Netflix')) return Colors.red;
    if (appName.contains('Gmail')) return Colors.red;
    if (appName.contains('Maps')) return Colors.green;
    if (appName.contains('Photos')) return Colors.blue;
    if (appName.contains('Calendar')) return Colors.blue;
    if (appName.contains('Drive')) return Colors.blue;
    if (appName.contains('Zoom')) return Colors.blue;
    if (appName.contains('Slack')) return Colors.purple;
    if (appName.contains('Uber')) return Colors.black;
    if (appName.contains('Airbnb')) return Colors.red;
    if (appName.contains('Pinterest')) return Colors.red;
    if (appName.contains('Reddit')) return Colors.orange;
    if (appName.contains('LinkedIn')) return Colors.blue;
    if (appName.contains('GitHub')) return Colors.black;
    if (appName.contains('Medium')) return Colors.black;
    if (appName.contains('Quora')) return Colors.red;
    if (appName.contains('Tumblr')) return Colors.blue;
    if (appName.contains('Flickr')) return Colors.pink;
    if (appName.contains('VSCO')) return Colors.black;
    if (appName.contains('Lightroom')) return Colors.purple;
    if (appName.contains('Snapseed')) return Colors.blue;
    if (appName.contains('Canva')) return Colors.blue;
    if (appName.contains('Adobe')) return Colors.red;
    if (appName.contains('Kindle')) return Colors.orange;
    if (appName.contains('Audible')) return Colors.orange;
    if (appName.contains('Podcasts')) return Colors.purple;
    if (appName.contains('SoundCloud')) return Colors.orange;
    if (appName.contains('Pandora')) return Colors.pink;
    if (appName.contains('iHeartRadio')) return Colors.red;
    if (appName.contains('Fitness')) return Colors.green;
    if (appName.contains('Strava')) return Colors.orange;
    if (appName.contains('Nike')) return Colors.black;
    if (appName.contains('Stack')) return Colors.orange;
    if (appName.contains('Teams')) return Colors.blue;
    if (appName.contains('Skype')) return Colors.blue;
    if (appName.contains('Trello')) return Colors.blue;
    if (appName.contains('Notion')) return Colors.black;
    if (appName.contains('Evernote')) return Colors.green;
    if (appName.contains('Keep')) return Colors.yellow;
    if (appName.contains('Duo')) return Colors.blue;
    if (appName.contains('Messages')) return Colors.green;
    if (appName.contains('Firefox')) return Colors.orange;
    if (appName.contains('Opera')) return Colors.red;
    if (appName.contains('Edge')) return Colors.blue;
    if (appName.contains('Samsung')) return Colors.blue;
    if (appName.contains('Books')) return Colors.orange;
    if (appName.contains('Meet')) return Colors.green;
    if (appName.contains('Translate')) return Colors.blue;
    if (appName.contains('Docs')) return Colors.blue;
    if (appName.contains('Excel')) return Colors.green;
    if (appName.contains('Word')) return Colors.blue;
    if (appName.contains('PowerPoint')) return Colors.orange;
    if (appName.contains('DoorDash')) return Colors.red;
    if (appName.contains('Grubhub')) return Colors.orange;
    if (appName.contains('Booking')) return Colors.blue;
    if (appName.contains('Layout')) return Colors.purple;
    if (appName.contains('Boomerang')) return Colors.blue;
    if (appName.contains('Hyperlapse')) return Colors.purple;
    
    return Colors.teal;
  }

  IconData _getAppIcon(String appName) {
    final lowerName = appName.toLowerCase();
    
    if (lowerName.contains('tiktok')) return LucideIcons.music;
    if (lowerName.contains('instagram')) return LucideIcons.camera;
    if (lowerName.contains('youtube')) return LucideIcons.play;
    if (lowerName.contains('facebook')) return LucideIcons.facebook;
    if (lowerName.contains('twitter')) return LucideIcons.twitter;
    if (lowerName.contains('snapchat')) return LucideIcons.camera;
    if (lowerName.contains('whatsapp')) return LucideIcons.messageCircle;
    if (lowerName.contains('telegram')) return LucideIcons.send;
    if (lowerName.contains('discord')) return LucideIcons.messageSquare;
    if (lowerName.contains('spotify')) return LucideIcons.music;
    if (lowerName.contains('netflix')) return LucideIcons.tv;
    if (lowerName.contains('chrome')) return LucideIcons.globe;
    if (lowerName.contains('gmail')) return LucideIcons.mail;
    if (lowerName.contains('maps')) return LucideIcons.mapPin;
    if (lowerName.contains('photos')) return LucideIcons.image;
    if (lowerName.contains('calendar')) return LucideIcons.calendar;
    if (lowerName.contains('drive')) return LucideIcons.folder;
    if (lowerName.contains('zoom')) return LucideIcons.video;
    if (lowerName.contains('slack')) return LucideIcons.messageSquare;
    if (lowerName.contains('uber')) return LucideIcons.car;
    if (lowerName.contains('airbnb')) return LucideIcons.home;
    if (lowerName.contains('pinterest')) return LucideIcons.pin;
    if (lowerName.contains('reddit')) return LucideIcons.messageCircle;
    if (lowerName.contains('linkedin')) return LucideIcons.linkedin;
    if (lowerName.contains('github')) return LucideIcons.github;
    if (lowerName.contains('medium')) return LucideIcons.bookOpen;
    if (lowerName.contains('quora')) return LucideIcons.helpCircle;
    if (lowerName.contains('tumblr')) return LucideIcons.messageSquare;
    if (lowerName.contains('flickr')) return LucideIcons.image;
    if (lowerName.contains('vsco')) return LucideIcons.camera;
    if (lowerName.contains('lightroom')) return LucideIcons.image;
    if (lowerName.contains('snapseed')) return LucideIcons.image;
    if (lowerName.contains('canva')) return LucideIcons.palette;
    if (lowerName.contains('adobe')) return LucideIcons.image;
    if (lowerName.contains('kindle')) return LucideIcons.book;
    if (lowerName.contains('audible')) return LucideIcons.headphones;
    if (lowerName.contains('podcasts')) return LucideIcons.podcast;
    if (lowerName.contains('soundcloud')) return LucideIcons.music;
    if (lowerName.contains('pandora')) return LucideIcons.music;
    if (lowerName.contains('iheartradio')) return LucideIcons.radio;
    if (lowerName.contains('fitness')) return LucideIcons.activity;
    if (lowerName.contains('strava')) return LucideIcons.activity;
    if (lowerName.contains('nike')) return LucideIcons.activity;
    if (lowerName.contains('stack')) return LucideIcons.code;
    if (lowerName.contains('teams')) return LucideIcons.users;
    if (lowerName.contains('skype')) return LucideIcons.video;
    if (lowerName.contains('trello')) return LucideIcons.trello;
    if (lowerName.contains('notion')) return LucideIcons.fileText;
    if (lowerName.contains('evernote')) return LucideIcons.fileText;
    if (lowerName.contains('keep')) return LucideIcons.stickyNote;
    if (lowerName.contains('duo')) return LucideIcons.video;
    if (lowerName.contains('messages')) return LucideIcons.messageCircle;
    if (lowerName.contains('firefox')) return LucideIcons.globe;
    if (lowerName.contains('opera')) return LucideIcons.globe;
    if (lowerName.contains('edge')) return LucideIcons.globe;
    if (lowerName.contains('samsung')) return LucideIcons.globe;
    if (lowerName.contains('books')) return LucideIcons.book;
    if (lowerName.contains('meet')) return LucideIcons.video;
    if (lowerName.contains('translate')) return LucideIcons.languages;
    if (lowerName.contains('docs')) return LucideIcons.fileText;
    if (lowerName.contains('excel')) return LucideIcons.table;
    if (lowerName.contains('word')) return LucideIcons.fileText;
    if (lowerName.contains('powerpoint')) return LucideIcons.presentation;
    if (lowerName.contains('doordash')) return LucideIcons.truck;
    if (lowerName.contains('grubhub')) return LucideIcons.truck;
    if (lowerName.contains('booking')) return LucideIcons.bed;
    if (lowerName.contains('layout')) return LucideIcons.layout;
    if (lowerName.contains('boomerang')) return LucideIcons.rotateCcw;
    if (lowerName.contains('hyperlapse')) return LucideIcons.fastForward;
    
    // Default icon for unknown apps
    return LucideIcons.smartphone;
  }
}


