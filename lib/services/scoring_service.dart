import '../models/question.dart';

class ScoringService {
  bool checkAnswer(Question question, String userAnswer) {
    return userAnswer.trim().toLowerCase() == question.correctAnswer.trim().toLowerCase();
  }

  double calculateScore(int correctCount, int totalCount) {
    if (totalCount == 0) return 0.0;
    return (correctCount / totalCount) * 100;
  }
}