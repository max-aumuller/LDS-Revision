import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/quiz_provider.dart';
import '../theme.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<QuizProvider>(
      builder: (context, quizProvider, child) {
        final bool ranOutOfTime = quizProvider.timeExpired;

        return Scaffold(
          appBar: AppBar(title: const Text('Results')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (ranOutOfTime) ...[
                    Text(
                      'Score not in timed condition',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${quizProvider.finalScorePercentage.toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      '${quizProvider.correctCount} out of ${quizProvider.totalQuestions} correct',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (quizProvider.extraTimeTakenSeconds != null)
                      Text(
                        'Extra time taken beyond the limit: ${_formatExtraTime(quizProvider.extraTimeTakenSeconds!)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    const SizedBox(height: AppSpacing.xl),
                    const Divider(),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Score under timed conditions',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${quizProvider.timedScorePercentage!.toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    Text(
                      '${quizProvider.timedCorrectCount} out of ${quizProvider.totalQuestions} correct',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${quizProvider.timedUnansweredCount} question(s) unanswered when time ran out',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ] else ...[
                    Text(
                      '${quizProvider.finalScorePercentage.toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '${quizProvider.correctCount} out of ${quizProvider.totalQuestions} correct',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xxl),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    child: const Text('Back to Quiz Menu'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static String _formatExtraTime(int totalSeconds) {
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    if (minutes == 0) return '${seconds}s';
    return '${minutes}m ${seconds}s';
  }
}