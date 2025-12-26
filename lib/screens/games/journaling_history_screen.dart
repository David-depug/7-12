import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/journal_entry.dart';
import '../../models/journal_model.dart';
import '../journaling_details_screen.dart';
import '../journaling_questions_screen.dart';

class JournalingHistoryScreen extends StatefulWidget {
  const JournalingHistoryScreen({super.key});

  @override
  State<JournalingHistoryScreen> createState() => _JournalingHistoryScreenState();
}

class _JournalingHistoryScreenState extends State<JournalingHistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Load entries when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<JournalModel>(context, listen: false).loadEntries();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<JournalModel>(
      builder: (context, journalModel, child) {

        if (journalModel.isLoading && journalModel.entries.isEmpty) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (journalModel.hasError && journalModel.entries.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Journal History')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading journals: ${journalModel.errorMessage}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      journalModel.loadEntries();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final entries = journalModel.entries;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Journal History'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  journalModel.refresh();
                },
              ),
            ],
          ),
          body: entries.isEmpty
              ? _buildEmptyState(context)
              : RefreshIndicator(
                  onRefresh: () => journalModel.refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return _buildJournalCard(context, entry, journalModel);
                    },
                  ),
                ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const JournalingQuestionsScreen(),
                ),
              );
              if (result == true) {
                // Refresh if entry was saved
                journalModel.refresh();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('New Entry'),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'No Journal Entries Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start your journaling journey by creating your first entry',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade500,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const JournalingQuestionsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Create First Entry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJournalCard(
      BuildContext context, JournalEntry entry, JournalModel journalModel) {
    final dateStr = _formatDate(entry.date);
    final preview = entry.answers.isNotEmpty
        ? entry.answers.first.answer
        : 'No content';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => JournalingDetailsScreen(entry: entry),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        dateStr,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  if (entry.xpAwarded != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star,
                            size: 14,
                            color: Colors.amber.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${entry.xpAwarded} XP',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                preview,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${entry.answers.length} questions answered',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                    IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: Colors.red.shade300,
                    onPressed: () => _showDeleteDialog(context, entry, journalModel),
                    tooltip: 'Delete entry',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entryDate = DateTime(date.year, date.month, date.day);

    if (entryDate == today) {
      return 'Today';
    } else if (entryDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showDeleteDialog(
      BuildContext context, JournalEntry entry, JournalModel journalModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Journal Entry?'),
        content: Text(
          'Are you sure you want to delete the entry from ${_formatDate(entry.date)}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await journalModel.deleteEntry(entry.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Entry deleted' : 'Failed to delete entry'),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

