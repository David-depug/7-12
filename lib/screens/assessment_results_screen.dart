import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

/// Screen to display clinical assessment results and RAG recommendations
class AssessmentResultsScreen extends StatelessWidget {
  final Map<String, dynamic> results;

  const AssessmentResultsScreen({
    super.key,
    required this.results,
  });

  @override
  Widget build(BuildContext context) {
    final anxietyProb = (results['anxiety_probability'] as num).toDouble();
    final depressionProb = (results['depression_probability'] as num).toDouble();
    final severity = results['severity'] as Map<String, dynamic>;
    final comorbidity = results['comorbidity'] as bool;
    final recommendations = results['rag_recommendations'] as List<dynamic>;
    final queryUsed = results['query_used'] as String;
    
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Your Assessment & Action Plan',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Crisis Support Banner (if high severity)
              if (severity['anxiety'] == 'High' || severity['depression'] == 'High')
                _buildCrisisSupportBanner(context),
              
              if (severity['anxiety'] == 'High' || severity['depression'] == 'High')
                const SizedBox(height: 16),
              
              // Summary Card
              _buildSummaryCard(
                context,
                anxietyProb,
                depressionProb,
                severity,
                comorbidity,
              ),
              
              const SizedBox(height: 24),
              
              // Understanding Your Case
              _buildCaseExplanation(
                context,
                anxietyProb,
                depressionProb,
                severity,
                comorbidity,
              ),
              
              const SizedBox(height: 24),
              
              // Immediate Action Steps
              _buildActionSteps(
                context,
                severity,
                comorbidity,
              ),
              
              const SizedBox(height: 24),
              
              // Recommendations Section
              Text(
                'Clinical Recommendations',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onBackground,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Based on evidence-based clinical literature',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: colorScheme.onBackground.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 16),
              
              // Query used (debug info)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Search: "$queryUsed"',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Recommendation Cards
              ...recommendations.asMap().entries.map((entry) {
                final index = entry.key;
                final rec = entry.value as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildRecommendationCard(context, rec, index + 1),
                );
              }),
              
              // Disclaimer
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange[700],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'These recommendations are educational and not a substitute for professional mental health care. Please consult with a licensed mental health professional for diagnosis and treatment.',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.orange[900],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Continue Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Continue to App',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
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

  Widget _buildCrisisSupportBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red[700]!, Colors.red[900]!],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.emergency,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Need Immediate Support?',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'If you\'re experiencing a crisis or having thoughts of self-harm, please reach out immediately:',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _launchPhone('988'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red[900],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.phone),
                  label: Text(
                    '988 Suicide Hotline',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCaseExplanation(
    BuildContext context,
    double anxietyProb,
    double depressionProb,
    Map<String, dynamic> severity,
    bool comorbidity,
  ) {
    final anxietySeverity = severity['anxiety'] as String;
    final depressionSeverity = severity['depression'] as String;
    
    String caseDescription = _getCaseDescription(
      anxietySeverity,
      depressionSeverity,
      comorbidity,
    );
    
    String whatItMeans = _getWhatItMeans(
      anxietySeverity,
      depressionSeverity,
      comorbidity,
    );

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.psychology,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Understanding Your Case',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'Your Assessment',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              caseDescription,
              style: GoogleFonts.inter(
                fontSize: 15,
                height: 1.6,
              ),
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'What This Means',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              whatItMeans,
              style: GoogleFonts.inter(
                fontSize: 15,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionSteps(
    BuildContext context,
    Map<String, dynamic> severity,
    bool comorbidity,
  ) {
    final steps = _getActionSteps(severity, comorbidity);
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.checklist_rounded,
                    color: Colors.green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your Action Plan',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 4),
            
            Text(
              'Follow these steps to start your journey to wellness',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            
            const SizedBox(height: 16),
            
            ...steps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildActionStepItem(
                  context,
                  index + 1,
                  step['title']!,
                  step['description']!,
                  step['icon'] as IconData,
                  step['priority'] as String,
                ),
              );
            }),
            
            const SizedBox(height: 8),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.amber.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Colors.amber[800],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Remember: Recovery is a journey, not a destination. Take it one step at a time.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.amber[900],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionStepItem(
    BuildContext context,
    int number,
    String title,
    String description,
    IconData icon,
    String priority,
  ) {
    Color priorityColor;
    Color bgColor;
    
    switch (priority) {
      case 'high':
        priorityColor = Colors.red;
        bgColor = Colors.red.withOpacity(0.1);
        break;
      case 'medium':
        priorityColor = Colors.orange;
        bgColor = Colors.orange.withOpacity(0.1);
        break;
      default:
        priorityColor = Colors.blue;
        bgColor = Colors.blue.withOpacity(0.1);
    }
    
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: priorityColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: priorityColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$number',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18, color: priorityColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: priorityColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.4,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getCaseDescription(String anxiety, String depression, bool comorbidity) {
    if (comorbidity) {
      return 'Your assessment indicates that you are experiencing symptoms of both anxiety and depression at moderate to high levels. This is called comorbidity and is more common than you might think. Both conditions can interact and influence each other, which is why comprehensive care is important.';
    } else if (anxiety == 'High') {
      return 'Your assessment shows elevated anxiety symptoms. You may be experiencing excessive worry, restlessness, difficulty concentrating, or physical symptoms like rapid heartbeat or tension. These are common signs that your mind and body are in a heightened state of alert.';
    } else if (depression == 'High') {
      return 'Your assessment indicates significant symptoms of depression. You may be experiencing persistent sadness, loss of interest in activities, fatigue, or changes in sleep and appetite. These symptoms suggest that your mood and energy levels are being significantly affected.';
    } else if (anxiety == 'Moderate' || depression == 'Moderate') {
      return 'Your assessment shows moderate symptoms that are affecting your daily life. While not severe, these symptoms are significant enough to warrant attention and intervention. Early action can prevent escalation and improve your quality of life.';
    } else {
      return 'Your assessment shows mild or low symptoms. This is a good time to focus on maintaining your mental wellness through healthy habits and preventive strategies. Building resilience now can help protect against future difficulties.';
    }
  }

  String _getWhatItMeans(String anxiety, String depression, bool comorbidity) {
    if (comorbidity) {
      return 'Having both anxiety and depression means you might experience overlapping symptoms like fatigue, difficulty concentrating, and sleep problems. The good news is that treatments like Cognitive Behavioral Therapy (CBT) can effectively address both conditions simultaneously. Professional help is strongly recommended.';
    } else if (anxiety == 'High' || depression == 'High') {
      return 'This level of symptoms typically requires professional intervention. While these feelings can be overwhelming, evidence-based treatments are highly effective. With proper support, most people experience significant improvement within 3-6 months.';
    } else if (anxiety == 'Moderate' || depression == 'Moderate') {
      return 'Moderate symptoms indicate that your wellbeing is being impacted, but there are many effective interventions available. A combination of professional support, self-help strategies, and lifestyle changes can make a significant difference.';
    } else {
      return 'Low symptoms suggest you\'re managing well overall. Continue practicing healthy coping strategies, maintaining social connections, and taking care of your physical health to support your mental wellness.';
    }
  }

  List<Map<String, dynamic>> _getActionSteps(Map<String, dynamic> severity, bool comorbidity) {
    final anxietySeverity = severity['anxiety'] as String;
    final depressionSeverity = severity['depression'] as String;
    
    List<Map<String, dynamic>> steps = [];
    
    // Step 1: Always recommend professional help for moderate-high
    if (anxietySeverity == 'High' || depressionSeverity == 'High' || comorbidity) {
      steps.add({
        'title': 'Consult a Mental Health Professional',
        'description': 'Schedule an appointment with a licensed therapist, psychologist, or psychiatrist. They can provide proper diagnosis and create a personalized treatment plan.',
        'icon': Icons.medical_services,
        'priority': 'high',
      });
    } else if (anxietySeverity == 'Moderate' || depressionSeverity == 'Moderate') {
      steps.add({
        'title': 'Consider Professional Support',
        'description': 'Talk to a counselor or therapist. Early intervention can prevent symptoms from worsening and provide you with effective coping strategies.',
        'icon': Icons.psychology_outlined,
        'priority': 'medium',
      });
    }
    
    // Step 2: Learn about CBT or relevant therapy
    if (anxietySeverity != 'Low' || depressionSeverity != 'Low') {
      steps.add({
        'title': 'Explore Cognitive Behavioral Therapy (CBT)',
        'description': 'CBT is the gold standard treatment for anxiety and depression. It helps you identify and change negative thought patterns. Many online resources and apps are available.',
        'icon': Icons.school_outlined,
        'priority': anxietySeverity == 'High' || depressionSeverity == 'High' ? 'high' : 'medium',
      });
    }
    
    // Step 3: Lifestyle changes
    steps.add({
      'title': 'Establish Healthy Daily Routines',
      'description': 'Focus on regular sleep schedule (7-9 hours), balanced nutrition, and daily physical activity. These foundational habits significantly impact mental health.',
      'icon': Icons.schedule,
      'priority': 'medium',
    });
    
    // Step 4: Exercise
    steps.add({
      'title': 'Exercise Regularly',
      'description': 'Aim for 30 minutes of moderate exercise most days. Physical activity releases endorphins and can be as effective as medication for mild-moderate symptoms.',
      'icon': Icons.directions_run,
      'priority': 'medium',
    });
    
    // Step 5: Social support
    steps.add({
      'title': 'Connect with Support System',
      'description': 'Reach out to trusted friends, family, or support groups. Social connection is crucial for recovery. Don\'t isolate yourself.',
      'icon': Icons.people,
      'priority': anxietySeverity == 'High' || depressionSeverity == 'High' ? 'high' : 'low',
    });
    
    // Step 6: Mindfulness/relaxation
    if (anxietySeverity != 'Low') {
      steps.add({
        'title': 'Practice Relaxation Techniques',
        'description': 'Try deep breathing, meditation, or progressive muscle relaxation. These techniques can reduce anxiety symptoms and promote calm.',
        'icon': Icons.self_improvement,
        'priority': 'medium',
      });
    }
    
    // Step 7: Track progress
    steps.add({
      'title': 'Monitor Your Progress',
      'description': 'Use this app to track your mood, activities, and symptoms. Retake the assessment in 2-4 weeks to see how you\'re progressing.',
      'icon': Icons.trending_up,
      'priority': 'low',
    });
    
    return steps;
  }

  void _launchPhone(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Widget _buildSummaryCard(
    BuildContext context,
    double anxietyProb,
    double depressionProb,
    Map<String, dynamic> severity,
    bool comorbidity,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primaryContainer,
              colorScheme.secondaryContainer,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.assessment,
                  color: colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Assessment Summary',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Anxiety
            _buildMetricRow(
              context,
              'Anxiety Level',
              severity['anxiety'] ?? 'Unknown',
              anxietyProb,
              Colors.orange,
            ),
            
            const SizedBox(height: 16),
            
            // Depression
            _buildMetricRow(
              context,
              'Depression Level',
              severity['depression'] ?? 'Unknown',
              depressionProb,
              Colors.blue,
            ),
            
            if (comorbidity) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.purple.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.purple[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Comorbidity detected: Both anxiety and depression indicators present',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.purple[900],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(
    BuildContext context,
    String label,
    String severity,
    double probability,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                severity,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: probability,
            minHeight: 8,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${(probability * 100).toStringAsFixed(1)}% probability',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationCard(
    BuildContext context,
    Map<String, dynamic> recommendation,
    int index,
  ) {
    final source = recommendation['source'] as String;
    final section = recommendation['section'] as String;
    final content = recommendation['content'] as String;
    final similarity = (recommendation['similarity'] as num).toDouble();
    final pages = recommendation['pages'] as String;
    
    final colorScheme = Theme.of(context).colorScheme;
    
    // Determine relevance color
    Color relevanceColor;
    if (similarity >= 80) {
      relevanceColor = Colors.green;
    } else if (similarity >= 70) {
      relevanceColor = Colors.orange;
    } else {
      relevanceColor = Colors.grey;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Index badge
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '$index',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Source info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        source,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Pages: $pages',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Similarity badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: relevanceColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: relevanceColor.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    '${similarity.toStringAsFixed(0)}%',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: relevanceColor,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                section,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Content
            Text(
              content,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.5,
                color: colorScheme.onSurface.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

