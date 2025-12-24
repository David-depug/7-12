import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/screen_time_settings_model.dart';
import '../services/screen_time_notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  late ScreenTimeSettingsModel _settings;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    _settings = await ScreenTimeSettingsModel.load();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isSaving = true;
    });

    await _settings.save();
    
    // Restart background monitoring with new settings
    if (_settings.notificationsEnabled) {
      await ScreenTimeNotificationService.startBackgroundMonitoring();
    } else {
      await ScreenTimeNotificationService.stopBackgroundMonitoring();
    }

    setState(() {
      _isSaving = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Settings saved successfully!',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF1B1B1B),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1B1B1B),
          elevation: 0,
          title: Text(
            'Notification Settings',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1B1B1B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B1B1B),
        elevation: 0,
        title: Text(
          'Notification Settings',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(LucideIcons.save, color: Colors.white),
              onPressed: _saveSettings,
              tooltip: 'Save Settings',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Master toggle
            _buildMasterToggle(),
            const SizedBox(height: 24),

            // Daily Goal Section
            _buildDailyGoalSection(),
            const SizedBox(height: 24),

            // Notification Types
            _buildNotificationTypesSection(),
            const SizedBox(height: 24),

            // Timing Settings
            _buildTimingSection(),
            const SizedBox(height: 24),

            // Quiet Hours
            _buildQuietHoursSection(),
            const SizedBox(height: 24),

            // Break Reminders
            _buildBreakRemindersSection(),
            const SizedBox(height: 32),

            // Save Button
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildMasterToggle() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: _settings.notificationsEnabled
              ? [const Color(0xFF7C3AED).withOpacity(0.2), const Color(0xFF7C3AED).withOpacity(0.1)]
              : [const Color(0xFF3A3A3A), const Color(0xFF2A2A2A)],
        ),
        border: Border.all(
          color: _settings.notificationsEnabled ? const Color(0xFF7C3AED) : const Color(0xFF4A4A4A),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: _settings.notificationsEnabled
                  ? const Color(0xFF7C3AED)
                  : const Color(0xFF4A4A4A),
            ),
            child: Icon(
              _settings.notificationsEnabled ? LucideIcons.bell : LucideIcons.bellOff,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enable Notifications',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _settings.notificationsEnabled
                      ? 'Receive screen time alerts and reminders'
                      : 'All notifications are disabled',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _settings.notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(notificationsEnabled: value);
              });
            },
            activeColor: const Color(0xFF7C3AED),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyGoalSection() {
    return _buildSection(
      icon: LucideIcons.target,
      title: 'Daily Screen Time Goal',
      subtitle: 'Set your target screen time per day',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_settings.dailyGoalHours.toStringAsFixed(1)} hours',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF7C3AED),
                ),
              ),
              Text(
                '${_settings.dailyGoalMinutes} minutes',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: const Color(0xFF7C3AED),
              inactiveTrackColor: const Color(0xFF3A3A3A),
              thumbColor: const Color(0xFF7C3AED),
              overlayColor: const Color(0xFF7C3AED).withOpacity(0.2),
            ),
            child: Slider(
              value: _settings.dailyGoalHours,
              min: 1.0,
              max: 12.0,
              divisions: 44, // 0.25 hour increments
              label: '${_settings.dailyGoalHours.toStringAsFixed(1)}h',
              onChanged: (value) {
                setState(() {
                  _settings = _settings.copyWith(dailyGoalHours: value);
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTypesSection() {
    return _buildSection(
      icon: LucideIcons.bellRing,
      title: 'Notification Types',
      subtitle: 'Choose which notifications you want to receive',
      child: Column(
        children: [
          _buildToggleItem(
            'Usage Limit Warnings',
            'Alert at 75% and 100% of daily goal',
            _settings.usageLimitWarnings,
            (value) {
              setState(() {
                _settings = _settings.copyWith(usageLimitWarnings: value);
              });
            },
            icon: LucideIcons.alertTriangle,
          ),
          _buildToggleItem(
            'Daily Summary',
            'Evening recap of your screen time',
            _settings.dailySummary,
            (value) {
              setState(() {
                _settings = _settings.copyWith(dailySummary: value);
              });
            },
            icon: LucideIcons.barChart3,
          ),
          _buildToggleItem(
            'Break Reminders',
            'Remind you to take regular breaks',
            _settings.breakReminders,
            (value) {
              setState(() {
                _settings = _settings.copyWith(breakReminders: value);
              });
            },
            icon: LucideIcons.coffee,
          ),
          _buildToggleItem(
            'Achievement Notifications',
            'Celebrate your milestones and streaks',
            _settings.achievementNotifications,
            (value) {
              setState(() {
                _settings = _settings.copyWith(achievementNotifications: value);
              });
            },
            icon: LucideIcons.trophy,
          ),
        ],
      ),
    );
  }

  Widget _buildTimingSection() {
    return _buildSection(
      icon: LucideIcons.clock,
      title: 'Daily Summary Time',
      subtitle: 'When to receive your daily screen time summary',
      child: _buildTimePickerItem(
        'Summary Time',
        _settings.dailySummaryTime,
        (value) {
          setState(() {
            _settings = _settings.copyWith(dailySummaryTime: value);
          });
        },
      ),
    );
  }

  Widget _buildQuietHoursSection() {
    return _buildSection(
      icon: LucideIcons.moonStar,
      title: 'Quiet Hours',
      subtitle: 'No notifications during these hours',
      child: Column(
        children: [
          _buildTimePickerItem(
            'Start Time',
            _settings.quietHoursStart,
            (value) {
              setState(() {
                _settings = _settings.copyWith(quietHoursStart: value);
              });
            },
          ),
          const SizedBox(height: 12),
          _buildTimePickerItem(
            'End Time',
            _settings.quietHoursEnd,
            (value) {
              setState(() {
                _settings = _settings.copyWith(quietHoursEnd: value);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBreakRemindersSection() {
    return _buildSection(
      icon: LucideIcons.timer,
      title: 'Break Reminder Interval',
      subtitle: 'How often to remind you to take breaks',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Every ${_settings.breakReminderInterval} minutes',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: const Color(0xFF7C3AED),
              inactiveTrackColor: const Color(0xFF3A3A3A),
              thumbColor: const Color(0xFF7C3AED),
              overlayColor: const Color(0xFF7C3AED).withOpacity(0.2),
            ),
            child: Slider(
              value: _settings.breakReminderInterval.toDouble(),
              min: 30,
              max: 180,
              divisions: 5,
              label: '${_settings.breakReminderInterval} min',
              onChanged: (value) {
                setState(() {
                  _settings = _settings.copyWith(breakReminderInterval: value.toInt());
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF2A2A2A),
        border: Border.all(color: const Color(0xFF3A3A3A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFF7C3AED).withOpacity(0.2),
                ),
                child: Icon(icon, color: const Color(0xFF7C3AED), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildToggleItem(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged, {
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: value ? const Color(0xFF7C3AED).withOpacity(0.2) : const Color(0xFF3A3A3A),
            ),
            child: Icon(icon, color: value ? const Color(0xFF7C3AED) : Colors.grey, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF7C3AED),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePickerItem(
    String label,
    String time,
    ValueChanged<String> onChanged,
  ) {
    return InkWell(
      onTap: () async {
        final timeParts = time.split(':');
        final initialTime = TimeOfDay(
          hour: int.parse(timeParts[0]),
          minute: int.parse(timeParts[1]),
        );

        final pickedTime = await showTimePicker(
          context: context,
          initialTime: initialTime,
        );

        if (pickedTime != null) {
          final newTime = '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';
          onChanged(newTime);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(top: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF3A3A3A),
          border: Border.all(color: const Color(0xFF4A4A4A)),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.clock, color: Color(0xFF7C3AED), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
            Text(
              time,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF7C3AED),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(LucideIcons.chevronRight, color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveSettings,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7C3AED),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Save Settings',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}


