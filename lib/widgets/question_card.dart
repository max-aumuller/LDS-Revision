import 'package:flutter/material.dart';
import '../models/question.dart';
import '../theme.dart';


class QuestionCard extends StatelessWidget {
  final Question question;
  final String? selectedAnswer;
  final bool hasAnswered;
  final bool isRevealed;
  final void Function(String) onAnswerSelected;
  final void Function() onReveal;
  final void Function(bool) onSelfMark;

  const QuestionCard({
    super.key,
    required this.question,
    required this.selectedAnswer,
    required this.hasAnswered,
    required this.isRevealed,
    required this.onAnswerSelected,
    required this.onReveal,
    required this.onSelfMark,
  });

  @override
  Widget build(BuildContext context) {
    if (question.type == 'longAnswer') {
      return _buildLongAnswer(context);
    }
    return _buildChoiceQuestion(context);
  }

  Widget _buildChoiceQuestion(BuildContext context) {
    final semanticColors = context.semanticColors;
    final errorContainer = Theme.of(context).colorScheme.errorContainer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question.prompt, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.lg),
        ...?question.options?.map((option) {
          Color? tileColor;
          if (hasAnswered) {
            if (option == question.correctAnswer) {
              tileColor = semanticColors.successContainer;
            } else if (option == selectedAnswer) {
              tileColor = errorContainer;
            }
          }

          return Card(
            color: tileColor,
            child: ListTile(
              title: Text(option),
              onTap: hasAnswered ? null : () => onAnswerSelected(option),
            ),
          );
        }),
        if (hasAnswered) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            question.explanation,
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLongAnswer(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question.prompt, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.lg),
        if (!isRevealed)
          ElevatedButton(
            onPressed: onReveal,
            child: const Text('Show Model Answer'),
          ),
        if (isRevealed) ...[
          Text('Model Answer:', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(question.correctAnswer),
          const SizedBox(height: AppSpacing.lg),
          Text(
            question.explanation,
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (!hasAnswered)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => onSelfMark(true),
                    child: const Text('I got this right'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => onSelfMark(false),
                    child: const Text('I got this wrong'),
                  ),
                ),
              ],
            ),
        ],
      ],
    );
  }
}