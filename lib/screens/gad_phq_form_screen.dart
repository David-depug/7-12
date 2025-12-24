import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../clinical_forms.dart';
import '../services/upheal_api.dart';
import 'assessment_results_screen.dart';

/// Combined GAD‑7 + PHQ‑9 questionnaire screen.
///
/// This screen is intended to be the first thing the user sees, before
/// entering the rest of the MindQuest app.
class GadPhqFormScreen extends StatefulWidget {
  const GadPhqFormScreen({super.key});

  @override
  State<GadPhqFormScreen> createState() => _GadPhqFormScreenState();
}

class _GadPhqFormScreenState extends State<GadPhqFormScreen> {
  /// Selected answers keyed by backend keys:
  /// - gad7_q1 .. gad7_q7
  /// - phq9_q1 .. phq9_q9
  final Map<String, int> _answers = {};

  bool _submitting = false;

  int get _totalQuestionCount =>
      gad7Form.questions.length + phq9Form.questions.length;

  bool get _isComplete => _answers.length == _totalQuestionCount;

  @override
  Widget build(BuildContext context) {
    final answeredCount = _answers.length;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final scaffoldBg = theme.scaffoldBackgroundColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Clinical Assessment',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Container(
          color: scaffoldBg,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Before we start, please complete this brief questionnaire.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: colorScheme.onBackground.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: colorScheme.onBackground.withOpacity(0.7),
                          ),
                        ),
                        Text(
                          '$answeredCount / $_totalQuestionCount answered',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight:
                                _isComplete ? FontWeight.w600 : FontWeight.w400,
                            color: _isComplete
                                ? colorScheme.primary
                                : colorScheme.onBackground.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: answeredCount / _totalQuestionCount,
                      backgroundColor: colorScheme.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    _buildFormSection(
                      context: context,
                      form: gad7Form,
                      prefix: 'gad7',
                    ),
                    const SizedBox(height: 24),
                    _buildFormSection(
                      context: context,
                      form: phq9Form,
                      prefix: 'phq9',
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: !_isComplete || _submitting
                        ? null
                        : () => _onSubmitPressed(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      disabledBackgroundColor:
                          colorScheme.primary.withOpacity(0.4),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Get Assessment'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormSection({
    required BuildContext context,
    required ClinicalForm form,
    required String prefix,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      color: colorScheme.surface.withOpacity(0.95),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              form.title,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              form.instructions,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Use the 0–3 chips below each question to answer.',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            ...form.questions.map(
              (q) => _buildQuestionCard(
                context: context,
                form: form,
                question: q,
                prefix: prefix,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard({
    required BuildContext context,
    required ClinicalForm form,
    required ClinicalQuestion question,
    required String prefix,
  }) {
    final String answerKey = '${prefix}_q${question.id}';
    final int? selectedValue = _answers[answerKey];

    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${question.id}. ',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              Expanded(
                child: Text(
                  question.text,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              if (question.riskFlag)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: colorScheme.error,
                    size: 18,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: form.optionsScale.map((opt) {
              final bool selected = selectedValue == opt.value;
              return ChoiceChip(
                label: Text(
                  '${opt.value} • ${opt.label}',
                  style: GoogleFonts.inter(fontSize: 12),
                ),
                selected: selected,
                onSelected: (isSelected) {
                  setState(() {
                    _answers[answerKey] = opt.value;
                  });
                },
                selectedColor: colorScheme.primary.withOpacity(0.15),
                labelStyle: TextStyle(
                  color: selected ? colorScheme.primary : colorScheme.onSurface,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _onSubmitPressed(BuildContext context) async {
    if (!_isComplete) return;
    setState(() {
      _submitting = true;
    });

    // Show progress dialog with status messages
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WillPopScope(
        onWillPop: () async => false,
        child: const AssessmentProgressDialog(),
      ),
    );

    try {
      final Map<String, int> answers = Map.of(_answers);
      debugPrint('Processing clinical assessment: $answers');

      // Get user ID for API call
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous_${DateTime.now().millisecondsSinceEpoch}';

      // 1. Save locally (fast, synchronous-ish)
      await _saveAssessmentLocally(answers: answers);

      // 2. Call API and save to Firestore IN PARALLEL
      final results = await Future.wait([
        _callRagAssessmentApi(answers: answers, userId: userId),
        _saveAssessmentToFirestore(context, answers: answers, userId: userId),
      ]);

      final apiResponse = results[0] as Map<String, dynamic>?;

      if (!mounted) return;
      
      // Close progress dialog
      Navigator.of(context).pop();

      // 3. Check if API succeeded - REQUIRED for recommendations
      if (apiResponse != null) {
        // API Success: Navigate to results screen with recommendations
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AssessmentResultsScreen(results: apiResponse),
          ),
        );
        
        if (!mounted) return;
        // Navigate back to main app flow
        Navigator.of(context).pop();
      } else {
        // API Failed: Show detailed error dialog
        await _showApiFailureDialog(context);
        // Don't pop - let user retry or cancel manually
      }

    } on TimeoutException {
      if (!mounted) return;
      // Close progress dialog
      Navigator.of(context).pop();
      // Show detailed timeout dialog
      await _showTimeoutDialog(context);
    } catch (e, st) {
      debugPrint('Error during assessment submission: $e\n$st');
      if (!mounted) return;
      // Close progress dialog
      Navigator.of(context).pop();
      // Show detailed error dialog
      await _showGeneralErrorDialog(context, e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  /// Show detailed timeout dialog
  Future<void> _showTimeoutDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.access_time,
                color: Colors.orange[700],
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Request Timeout',
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The request took too long to complete (3 minutes).',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'This usually means the backend server is slow to respond or processing a large amount of data.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              Text(
                'Please try again. If the problem persists, check:\n\n'
                '• Backend server status\n'
                '• Internet connection speed\n'
                '• Server resource availability',
                style: TextStyle(fontSize: 13, height: 1.5),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Close form
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Show general error dialog
  Future<void> _showGeneralErrorDialog(BuildContext context, String errorMessage) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red[700],
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Error Occurred',
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'An error occurred while processing your assessment.',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Error Details:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        errorMessage,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Your answers have been saved locally. Please try again or contact support if the problem persists.',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Close form
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Show detailed error dialog when API fails
  Future<void> _showApiFailureDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.cloud_off,
                color: Colors.red[700],
                size: 28,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Cannot Get Recommendations',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Unable to connect to the recommendation system.',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your answers have been saved, but we need to retrieve personalized clinical recommendations from our AI system.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange[800],
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Possible Causes:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• Backend server is not running\n'
                        '• No internet connection\n'
                        '• Server timeout (taking too long)\n'
                        '• Firewall blocking connection',
                        style: TextStyle(fontSize: 12, height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.settings_suggest,
                            color: Colors.blue[800],
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'What to do:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '1. Make sure backend server is running\n'
                        '   (Run: start_server.bat)\n\n'
                        '2. Check internet connection\n\n'
                        '3. Try again after a moment',
                        style: TextStyle(fontSize: 12, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Close form
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                // User can retry by clicking submit again
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveAssessmentLocally({
    required Map<String, int> answers,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'clinical_answers_v1',
        jsonEncode(answers),
      );
      // Mark that user has completed at least one assessment
      await prefs.setBool('has_completed_assessment', true);
      debugPrint('Clinical assessment answers saved locally.');
    } catch (e, st) {
      debugPrint('Failed to save assessment locally: $e\n$st');
    }
  }

  Future<void> _saveAssessmentToFirestore(
    BuildContext context, {
    required Map<String, int> answers,
    required String userId,
  }) async {
    try {
      final now = DateTime.now().toUtc();

      await FirebaseFirestore.instance
          .collection('clinical_assessments')
          .add({
        'answers': answers,
        'created_at': now.toIso8601String(),
        'user_id': userId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      debugPrint('✓ Clinical assessment saved to Firestore.');
    } catch (e, st) {
      debugPrint('Failed to save assessment to Firestore: $e\n$st');
      // Don't throw - we don't want to fail the entire submission
    }
  }

  /// Call the RAG Assessment API
  Future<Map<String, dynamic>?> _callRagAssessmentApi({
    required Map<String, int> answers,
    required String userId,
  }) async {
    try {
      debugPrint('Calling RAG Assessment API...');
      
      final api = UphealApi(baseUrl: uphealBaseUrl);
      
      // Call the assess endpoint
      final response = await api.assess(
        answers: answers,
        userId: userId,
        sessionId: DateTime.now().millisecondsSinceEpoch.toString(),
      ).timeout(
        const Duration(seconds: 180), // 3 minutes
        onTimeout: () {
          throw TimeoutException('API call timed out after 180 seconds');
        },
      );

      debugPrint('✓ API Response received');
      debugPrint('  Anxiety: ${response['anxiety_probability']}');
      debugPrint('  Depression: ${response['depression_probability']}');
      
      // Save the API response to Firestore
      await _saveApiResponseToFirestore(userId: userId, response: response);
      
      // Save the results locally for quick access
      await _saveResultsLocally(response: response);
      
      return response;
    } catch (e, st) {
      debugPrint('Failed to call RAG API: $e\n$st');
      // Return null to indicate failure, but don't throw
      return null;
    }
  }

  /// Save assessment results locally for quick access
  Future<void> _saveResultsLocally({
    required Map<String, dynamic> response,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'last_assessment_results',
        jsonEncode(response),
      );
      debugPrint('✓ Results saved locally for quick access');
    } catch (e, st) {
      debugPrint('Failed to save results locally: $e\n$st');
    }
  }

  /// Save API response to a separate collection for analytics
  Future<void> _saveApiResponseToFirestore({
    required String userId,
    required Map<String, dynamic> response,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('assessment_results')
          .add({
        'user_id': userId,
        'anxiety_probability': response['anxiety_probability'],
        'depression_probability': response['depression_probability'],
        'severity': response['severity'],
        'comorbidity': response['comorbidity'],
        'query_used': response['query_used'],
        'rag_recommendations': response['rag_recommendations'],
        'timestamp': response['timestamp'],
        'created_at': FieldValue.serverTimestamp(),
      });
      
      debugPrint('✓ API response saved to Firestore');
    } catch (e, st) {
      debugPrint('Failed to save API response to Firestore: $e\n$st');
    }
  }
}

/// Progress dialog shown during assessment processing
class AssessmentProgressDialog extends StatefulWidget {
  const AssessmentProgressDialog({Key? key}) : super(key: key);

  @override
  State<AssessmentProgressDialog> createState() => _AssessmentProgressDialogState();
}

class _AssessmentProgressDialogState extends State<AssessmentProgressDialog> {
  int _currentStep = 0;
  Timer? _timer;
  
  final List<String> _steps = [
    'Processing your assessment...',
    'Analyzing anxiety patterns...',
    'Analyzing depression indicators...',
    'Consulting clinical database...',
    'Generating personalized recommendations...',
    'Almost done...',
  ];

  @override
  void initState() {
    super.initState();
    // Change message every 20 seconds
    _timer = Timer.periodic(const Duration(seconds: 20), (timer) {
      if (mounted && _currentStep < _steps.length - 1) {
        setState(() {
          _currentStep++;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              _steps[_currentStep],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'This may take up to 2-3 minutes',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: (_currentStep + 1) / _steps.length,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ],
        ),
      ),
    );
  }
}
