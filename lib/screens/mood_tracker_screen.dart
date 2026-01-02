import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/mood_entry.dart';
import '../models/mood_model.dart';
import '../constants/app_colors.dart';

class MoodTrackerScreen extends StatefulWidget {
  const MoodTrackerScreen({super.key});

  @override
  State<MoodTrackerScreen> createState() => _MoodTrackerScreenState();
}

class _MoodTrackerScreenState extends State<MoodTrackerScreen> {
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Load today's entry to check if already tracked
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MoodModel>().loadEntries();
    });
  }

  Future<void> _trackMood(String mood) async {
    if (_isSubmitting) return;

    final moodModel = context.read<MoodModel>();
    
    // Check if already tracked today
    if (moodModel.hasTrackedToday) {
      _showMessage('You have already tracked your mood today. Come back tomorrow!', isError: true);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      final entry = MoodEntry(
        id: const Uuid().v4(),
        mood: mood,
        date: today,
        timestamp: now,
      );

      final success = await moodModel.saveEntry(entry);

      if (success && mounted) {
        _showMessage('Your mood has been tracked! 😊', isError: false);
        // Refresh to update UI
        await moodModel.loadEntries();
      } else {
        if (mounted) {
          _showMessage(
            moodModel.errorMessage ?? 'Failed to save mood entry',
            isError: true,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Error tracking mood: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildMoodButton(String mood, String emoji, int colorValue, bool isSelected) {
    final isDisabled = _isSubmitting || context.watch<MoodModel>().hasTrackedToday;
    
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Material(
          color: isSelected 
              ? Color(colorValue).withOpacity(0.3)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: isDisabled ? null : () => _trackMood(mood),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected 
                      ? Color(colorValue)
                      : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(16),
                color: isSelected 
                    ? Color(colorValue).withOpacity(0.1)
                    : Colors.white,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    emoji,
                    style: const TextStyle(fontSize: 40),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    mood,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Color(colorValue) : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final moodModel = context.watch<MoodModel>();
    final todayEntry = moodModel.todayEntry;
    final hasTracked = moodModel.hasTrackedToday;
    final isLoading = moodModel.isLoading;

    // Determine background color based on today's mood
    Color backgroundColor = Colors.white;
    if (todayEntry != null) {
      backgroundColor = Color(todayEntry.colorValue).withOpacity(0.1);
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Mood Tracker'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Question
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'How are you feeling today?',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    if (hasTracked) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: todayEntry != null 
                              ? Color(todayEntry.colorValue).withOpacity(0.2)
                              : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              todayEntry?.emoji ?? '✅',
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              hasTracked
                                  ? 'You tracked: ${todayEntry?.mood ?? "your mood"}'
                                  : 'Mood tracked!',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: todayEntry != null 
                                    ? Color(todayEntry.colorValue)
                                    : Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You can track your mood again tomorrow!',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Mood Buttons
              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                Row(
                  children: [
                    _buildMoodButton(
                      'Very Happy',
                      '😄',
                      MoodOptions.colors[0],
                      todayEntry?.mood == 'Very Happy',
                    ),
                    _buildMoodButton(
                      'Happy',
                      '😊',
                      MoodOptions.colors[1],
                      todayEntry?.mood == 'Happy',
                    ),
                    _buildMoodButton(
                      'Neutral',
                      '😐',
                      MoodOptions.colors[2],
                      todayEntry?.mood == 'Neutral',
                    ),
                    _buildMoodButton(
                      'Sad',
                      '😢',
                      MoodOptions.colors[3],
                      todayEntry?.mood == 'Sad',
                    ),
                    _buildMoodButton(
                      'Very Sad',
                      '😭',
                      MoodOptions.colors[4],
                      todayEntry?.mood == 'Very Sad',
                    ),
                  ],
                ),

              const SizedBox(height: 32),

              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Track your mood once per day to build emotional awareness and patterns.',
                        style: TextStyle(
                          color: Colors.blue.shade900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Recent Moods (if any)
              if (moodModel.entries.isNotEmpty) ...[
                Text(
                  'Recent Moods',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                ...moodModel.entries.take(7).map((entry) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Text(
                          entry.emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.mood,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${entry.date.day}/${entry.date.month}/${entry.date.year}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

