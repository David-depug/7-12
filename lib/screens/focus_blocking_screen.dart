import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../constants/app_colors.dart';
import '../models/focus_session.dart';
import '../widgets/focus_mode_card.dart';
import '../widgets/focus_timer.dart';

class FocusBlockingScreen extends StatefulWidget {
  const FocusBlockingScreen({super.key});

  @override
  State<FocusBlockingScreen> createState() => _FocusBlockingScreenState();
}

class _FocusBlockingScreenState extends State<FocusBlockingScreen> {
  static const _tick = Duration(seconds: 1);
  final List<Duration> _presets = const [
    Duration(minutes: 25),
    Duration(minutes: 45),
    Duration(hours: 1),
  ];

  final Map<String, List<String>> _categoryApps = const {
    'Social Media': ['TikTok', 'Instagram', 'Snapchat'],
    'Gaming': ['Clash Royale', 'Roblox', 'PUBG'],
    'Video': ['YouTube', 'Netflix', 'Prime Video'],
    'Shopping': ['Amazon', 'Temu', 'eBay'],
  };

  late final Map<String, bool> _categorySelection = {
    for (final entry in _categoryApps.entries) entry.key: entry.key == 'Social Media'
  };

  Duration _selectedDuration = const Duration(minutes: 25);
  bool _notificationsMuted = true;
  FocusSession? _activeSession;
  Timer? _ticker;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus & Blocker'),
        actions: [
          IconButton(
            tooltip: 'Reset preferences',
            onPressed: _activeSession == null ? _resetPreferences : null,
            icon: const Icon(LucideIcons.rotateCcw),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FocusModeCard(
              session: _activeSession,
              isActive: _activeSession != null,
              onStart: _startSession,
              onEnd: _endSession,
            ),
            const SizedBox(height: 16),
            _buildDurationSelector(),
            const SizedBox(height: 16),
            _buildBlockList(),
            const SizedBox(height: 16),
            _buildFocusControls(),
            const SizedBox(height: 16),
            _buildAutomationSettings(),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationSelector() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.timer, color: AppColors.purple),
                const SizedBox(width: 8),
                Text(
                  'Focus duration',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _presets.map((duration) {
                final isSelected = duration == _selectedDuration;
                final label = duration.inHours >= 1
                    ? '${duration.inHours}h'
                    : '${duration.inMinutes}m';
                return ChoiceChip(
                  label: Text(label),
                  selected: isSelected,
                  onSelected: (value) {
                    if (!value) return;
                    setState(() => _selectedDuration = duration);
                  },
                  selectedColor: AppColors.purple.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.purple : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockList() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.shield, color: AppColors.orange),
                const SizedBox(width: 8),
                Text(
                  'Auto-block distractions',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._categoryApps.entries.map((entry) {
              final title = entry.key;
              final apps = entry.value;
              final isEnabled = _categorySelection[title] ?? false;
              return SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(title),
                subtitle: Text(apps.join(', ')),
                value: isEnabled,
                onChanged: (value) {
                  setState(() => _categorySelection[title] = value);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFocusControls() {
    return FocusTimer(
      session: _activeSession,
      onStart: _startSession,
      onPause: _pauseSession,
      onResume: _resumeSession,
      onEnd: _endSession,
    );
  }

  Widget _buildAutomationSettings() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.sparkles, color: AppColors.green),
                const SizedBox(width: 8),
                Text(
                  'Automation',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Mute notifications'),
              subtitle: const Text('Prevent notification sounds during focus'),
              value: _notificationsMuted,
              onChanged: (value) => setState(() => _notificationsMuted = value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Auto-start next session'),
              subtitle: const Text('Take a 5 minute break between sessions'),
              value: _activeSession != null && _activeSession!.remainingTime == Duration.zero,
              onChanged: null,
            ),
          ],
        ),
      ),
    );
  }

  void _startSession() {
    if (_activeSession != null) {
      _endSession(showSnackBar: false);
    }

    final blockedApps = _categorySelection.entries
        .where((entry) => entry.value)
        .expand((entry) => _categoryApps[entry.key] ?? const <String>[])
        .toList();

    setState(() {
      _activeSession = FocusSession(
        duration: _selectedDuration,
        blockedApps: blockedApps,
      );
    });

    _startTicker();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          blockedApps.isEmpty
              ? 'Focus mode started for ${_formatDuration(_selectedDuration)}'
              : 'Blocking ${blockedApps.length} apps for ${_formatDuration(_selectedDuration)}',
        ),
      ),
    );
  }

  void _pauseSession() {
    _ticker?.cancel();
  }

  void _resumeSession() {
    if (_activeSession == null || _activeSession!.isCompleted) return;
    _startTicker();
  }

  void _endSession({bool showSnackBar = true}) {
    _ticker?.cancel();
    if (!mounted) return;
    if (_activeSession != null && showSnackBar) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Focus session ended')),
      );
    }
    setState(() => _activeSession = null);
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(_tick, (timer) {
      if (!mounted || _activeSession == null) {
        timer.cancel();
        return;
      }
      setState(() {
        _activeSession!.decrement(_tick);
        if (_activeSession!.isCompleted) {
          timer.cancel();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Focus complete! Take a short break.')),
          );
        }
      });
    });
  }

  void _resetPreferences() {
    setState(() {
      for (final key in _categorySelection.keys) {
        _categorySelection[key] = key == 'Social Media';
      }
      _selectedDuration = _presets.first;
      _notificationsMuted = true;
    });
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours >= 1) {
      final mins = duration.inMinutes.remainder(60);
      return '${duration.inHours}h ${mins}m';
    }
    return '${duration.inMinutes}m';
  }
}

