import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/quiz_provider.dart';
import '../widgets/question_card.dart';
import 'results_screen.dart';

class QuestionScreen extends StatelessWidget {
  const QuestionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<QuizProvider>(
      builder: (context, quizProvider, child) {
        final question = quizProvider.currentQuestion;

        if (question == null) {
          return const Center(child: Text('No question available.'));
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Question ${quizProvider.currentIndex + 1} of ${quizProvider.totalQuestions}'),
            actions: [
              if (quizProvider.isExamMode)
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Center(
                    child: Text(
                      quizProvider.timeExpired ? 'Time up!' : _formatTime(quizProvider.secondsRemaining),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: quizProvider.timeExpired ? Colors.red : null,
                      ),
                    ),
                  ),
                ),
              if (quizProvider.isExamMode)
                TextButton(
                  onPressed: () => _finishExam(context, quizProvider),
                  child: const Text('Finish'),
                ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: QuestionCard(
                      question: question,
                      selectedAnswer: quizProvider.selectedAnswer,
                      hasAnswered: quizProvider.hasAnswered,
                      isRevealed: quizProvider.isRevealed,
                      onAnswerSelected: (answer) {
                        quizProvider.submitAnswer(answer);
                      },
                      onReveal: () {
                        quizProvider.revealLongAnswer();
                      },
                      onSelfMark: (markedCorrect) {
                        quizProvider.submitLongAnswerSelfMark(markedCorrect);
                      },
                    ),
                  ),
                ),
                if (quizProvider.isExamMode)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: quizProvider.isFirstQuestion ? null : quizProvider.previousQuestion,
                          child: const Text('Previous'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: quizProvider.isLastQuestion ? null : quizProvider.nextQuestion,
                          child: const Text('Next'),
                        ),
                      ),
                    ],
                  )
                else if (quizProvider.hasAnswered)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (quizProvider.isLastQuestion) {
                          quizProvider.finalizeExtraTimeTaken();
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ResultsScreen()),
                          );
                        } else {
                          quizProvider.nextQuestion();
                        }
                      },
                      child: Text(quizProvider.isLastQuestion ? 'Finish' : 'Next Question'),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _finishExam(BuildContext context, QuizProvider quizProvider) {
    quizProvider.finalizeExtraTimeTaken();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ResultsScreen()),
    );
  }

  static String _formatTime(int totalSeconds) {
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}