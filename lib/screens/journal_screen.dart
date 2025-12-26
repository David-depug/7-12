import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/journal_model.dart';
import 'journaling_details_screen.dart';
import 'games/journaling_history_screen.dart';

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1B1B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B1B1B),
        elevation: 0,
        title: Text(
          'Journaling',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Consumer<JournalModel>(
        builder: (context, journalModel, _) {
          final entries = journalModel.entries;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Reflection',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Capture your thoughts, track your mood, and earn XP for healthy reflection.',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),

                // Quick actions
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const JournalingQuestionsScreen(),
                            ),
                          );
                          if (result == true) {
                            journalModel.refresh();
                          }
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('New Entry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurpleAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const JournalingHistoryScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.history),
                        label: const Text('History'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white30),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Recent entry preview or empty state
                Expanded(
                  child: entries.isEmpty
                      ? Center(
                          child: Text(
                            'No journal entries yet.\nStart by creating your first reflection.',
                            style: GoogleFonts.inter(
                              color: Colors.white60,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recent Entries',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: ListView.builder(
                                itemCount: entries.length.clamp(0, 3),
                                itemBuilder: (context, index) {
                                  final entry = entries[index];
                                  final firstAnswer = entry.answers.isNotEmpty
                                      ? entry.answers.first.answer
                                      : '';
                                  final date = entry.date;
                                  final dateStr =
                                      '${date.day}/${date.month}/${date.year}';

                                  return Container(
                                    margin:
                                        const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color:
                                            Colors.white.withOpacity(0.08),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment
                                                  .spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.calendar_today,
                                                  size: 14,
                                                  color: Colors.white70,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  dateStr,
                                                  style: GoogleFonts.inter(
                                                    color: Colors.white70,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (entry.xpAwarded != null)
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.star,
                                                    size: 14,
                                                    color: Colors.amber,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '+${entry.xpAwarded} XP',
                                                    style: GoogleFonts.inter(
                                                      color: Colors.amber,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          firstAnswer.isEmpty
                                              ? 'No content'
                                              : firstAnswer,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontSize: 14,
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
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

