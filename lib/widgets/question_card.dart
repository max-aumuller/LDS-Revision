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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question.prompt, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        ...?question.options?.map((option) {
          Color? tileColor;
          if (hasAnswered) {
            if (option == question.correctAnswer) {
              tileColor = AppTheme.correctColor.withValues(alpha: 0.15);
            } else if (option == selectedAnswer) {
              tileColor = AppTheme.incorrectColor.withValues(alpha: 0.15);
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
          const SizedBox(height: 16),
          Text(
            question.explanation,
            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey.shade700),
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
        const SizedBox(height: 16),
        if (!isRevealed)
          ElevatedButton(
            onPressed: onReveal,
            child: const Text('Show Model Answer'),
          ),
        if (isRevealed) ...[
          Text('Model Answer:', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(question.correctAnswer),
          const SizedBox(height: 16),
          Text(
            question.explanation,
            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 16),
          if (!hasAnswered)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => onSelfMark(true),
                    child: const Text('I got this right'),
                  ),
                ),
                const SizedBox(width: 8),
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