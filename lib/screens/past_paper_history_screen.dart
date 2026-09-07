import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/progress_provider.dart';
import '../theme.dart';

class PastPaperHistoryScreen extends StatelessWidget {
  const PastPaperHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Past Paper History')),
      body: Consumer<ProgressProvider>(
        builder: (context, progressProvider, child) {
          final List<PastPaperAttempt> history = progressProvider.pastPaperHistory;

          if (history.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  'No past paper attempts yet.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final PastPaperAttempt attempt = history[index];
              final int achieved = attempt.entry.marksAchieved!;
              final int total = attempt.entry.totalMarksAvailable!;
              final double percentage = total == 0 ? 0 : (achieved / total) * 100;

              return Card(
                child: ListTile(
                  title: Text(
                    '${attempt.paper.examSeries} Paper ${attempt.paper.paperNumber} — Q${attempt.paper.questionNumber}',
                  ),
                  subtitle: Text(
                    '${attempt.paper.topic} • ${_formatDate(attempt.entry.timestamp)}',
                  ),
                  trailing: Text(
                    '$achieved/$total (${percentage.toStringAsFixed(0)}%)',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  static String _formatDate(String isoTimestamp) {
    final DateTime date = DateTime.parse(isoTimestamp);
    return '${date.day}/${date.month}/${date.year}';
  }
}
