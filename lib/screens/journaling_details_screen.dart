import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/journal_entry.dart';
import '../models/journal_model.dart';

class JournalingQuestionsScreen extends StatefulWidget {
  const JournalingQuestionsScreen({super.key});

  @override
  State<JournalingQuestionsScreen> createState() =>
      _JournalingQuestionsScreenState();
}

class _JournalingQuestionsScreenState
    extends State<JournalingQuestionsScreen> {
  final List<TextEditingController> _controllers = [];
  final List<FocusNode> _focusNodes = [];
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  // Default journaling questions
  final List<String> _questions = [
    'What are three things you\'re grateful for today?',
    'What was the highlight of your day?',
    'What challenge did you face today, and how did you handle it?',
    'How are you feeling right now?',
    'What would you like to improve or focus on tomorrow?',
  ];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < _questions.length; i++) {
      _controllers.add(TextEditingController());
      _focusNodes.add(FocusNode());
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  Future<void> _submitJournal() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final now = DateTime.now();
      final entry = JournalEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: DateTime(now.year, now.month, now.day),
        answers: List.generate(
          _questions.length,
          (index) => QuestionAnswer(
            question: _questions[index],
            answer: _controllers[index].text.trim(),
          ),
        ),
        mood: null, // Can be added later with a mood picker
        timestamp: now,
        xpAwarded: _calculateXP(),
      );

      final journalModel = Provider.of<JournalModel>(context, listen: false);
      final success = await journalModel.saveEntry(entry);
      
      if (!success) {
        throw Exception(journalModel.errorMessage ?? 'Failed to save entry');
      }

      if (!mounted) return;
      
      // Show success dialog with XP
      await _showSuccessDialog(entry.xpAwarded ?? 0);
      if (!mounted) return;
      Navigator.of(context).pop(true); // Return true to indicate success
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving journal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  int _calculateXP() {
    // Award XP based on answer length and completeness
    int totalChars = 0;
    for (var controller in _controllers) {
      totalChars += controller.text.trim().length;
    }
    // Base XP: 10, plus 1 XP per 50 characters (max 50 XP)
    return 10 + (totalChars / 50).floor().clamp(0, 40);
  }

  Future<void> _showSuccessDialog(int xp) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 32),
            const SizedBox(width: 12),
            const Text('Journal Saved!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Thank you for taking time to reflect.'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    '+$xp XP',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Journal'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.book,
                    size: 48,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Reflect on Your Day',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Take a moment to answer these questions',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Questions
            ...List.generate(_questions.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Question ${index + 1}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _questions[index],
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Type your answer here...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please provide an answer';
                        }
                        if (value.trim().length < 10) {
                          return 'Please write at least 10 characters';
                        }
                        return null;
                      },
                      textInputAction: index < _questions.length - 1
                          ? TextInputAction.next
                          : TextInputAction.done,
                      onFieldSubmitted: (value) {
                        if (index < _questions.length - 1) {
                          _focusNodes[index + 1].requestFocus();
                        } else {
                          _submitJournal();
                        }
                      },
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitJournal,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Save Journal Entry',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

