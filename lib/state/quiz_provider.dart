import 'package:flutter/foundation.dart';
import '../models/question.dart';
import '../services/scoring_service.dart';
import '../services/query_service.dart';
import '../models/progress_entry.dart';
import 'progress_provider.dart';
import '../services/spaced_repetition_service.dart';
import 'dart:async';

class QuizProvider extends ChangeNotifier {
  final ScoringService _scoringService = ScoringService();
  final QueryService _queryService = QueryService();
  final SpacedRepetitionService _spacedRepetitionService = SpacedRepetitionService();

  List<Question> _sessionQuestions = [];
  int _currentIndex = 0;
  int _correctCount = 0;
  bool _isExamMode = false;
  List<bool> _answeredFlags = [];
  List<bool> _revealedFlags = [];
  List<String?> _selectedAnswers = [];
  Timer? _examTimer;
  int _secondsRemaining = 0;
  bool _timeExpired = false;
  int? _timedCorrectCount;
  int? _timedQuestionsAnsweredAtExpiry;
  DateTime? _timeExpiredAt;
  int? _extraTimeTakenSeconds;
  int _dueQuestionCount = 0;

  Question? get currentQuestion =>
      _sessionQuestions.isEmpty ? null : _sessionQuestions[_currentIndex];
  int get currentIndex => _currentIndex;
  int get totalQuestions => _sessionQuestions.length;
  int get correctCount => _correctCount;
  bool get isExamMode => _isExamMode;
  bool get hasAnswered => _sessionQuestions.isEmpty ? false : _answeredFlags[_currentIndex];
  bool get isRevealed => _sessionQuestions.isEmpty ? false : _revealedFlags[_currentIndex];
  String? get selectedAnswer => _sessionQuestions.isEmpty ? null : _selectedAnswers[_currentIndex];
  bool get isFirstQuestion => _currentIndex == 0;
  bool get isLastQuestion => _currentIndex == _sessionQuestions.length - 1;
  double get finalScorePercentage => _scoringService.calculateScore(_correctCount, _sessionQuestions.length);
  int get secondsRemaining => _secondsRemaining;
  bool get timeExpired => _timeExpired;

  double? get timedScorePercentage {
    if (_timedCorrectCount == null) return null;
    return _scoringService.calculateScore(_timedCorrectCount!, totalQuestions);
  }

  int? get timedCorrectCount => _timedCorrectCount;

  int? get timedUnansweredCount {
    if (_timedQuestionsAnsweredAtExpiry == null) return null;
    return totalQuestions - _timedQuestionsAnsweredAtExpiry!;
  }

  int? get extraTimeTakenSeconds => _extraTimeTakenSeconds;
  int get dueQuestionCount => _dueQuestionCount;

  Future<void> startSession({
    List<String>? topics,
    int questionCount = 10,
    bool examMode = false,
    double extraTimePercent = 0,
  }) async {
    final List<Question> fetched = await _queryService.getQuestions(topics: topics, limit: null);
    final List<ProgressEntry> allEntries = await _queryService.getAllProgressEntries();

    final Map<int, String?> latestReviewDateByQuestion = {};
    for (final entry in allEntries) {
      latestReviewDateByQuestion[entry.questionId] = entry.nextReviewDate;
    }

    final List<Question> due = [];
    final List<Question> notDue = [];

    for (final question in fetched) {
      final String? reviewDate = latestReviewDateByQuestion[question.id];
      if (_spacedRepetitionService.isDue(reviewDate)) {
        due.add(question);
      } else {
        notDue.add(question);
      }
    }

    due.shuffle();
    notDue.shuffle();

    final List<Question> prioritized = [...due, ...notDue];
    final List<Question> sessionQuestions = questionCount < prioritized.length
        ? prioritized.sublist(0, questionCount)
        : prioritized;

    _beginSession(sessionQuestions, examMode: examMode, extraTimePercent: extraTimePercent);
  }

  Future<List<Question>> _fetchDueQuestions() async {
    final List<Question> fetched = await _queryService.getQuestions(limit: null);
    final List<ProgressEntry> allEntries = await _queryService.getAllProgressEntries();

    final Map<int, String?> latestReviewDateByQuestion = {};
    for (final entry in allEntries) {
      if (entry.questionType != 'original') continue;
      latestReviewDateByQuestion[entry.questionId] = entry.nextReviewDate;
    }

    return fetched
        .where((question) => _spacedRepetitionService.isDue(latestReviewDateByQuestion[question.id]))
        .toList();
  }

  Future<void> refreshDueQuestionCount() async {
    final List<Question> due = await _fetchDueQuestions();
    _dueQuestionCount = due.length;
    notifyListeners();
  }

  Future<void> startDueReviewSession() async {
    final List<Question> due = await _fetchDueQuestions();
    due.shuffle();
    _beginSession(due);
  }

  void _beginSession(
    List<Question> questions, {
    bool examMode = false,
    double extraTimePercent = 0,
  }) {
    _sessionQuestions = questions;
    _currentIndex = 0;
    _correctCount = 0;
    _isExamMode = examMode;
    _answeredFlags = List<bool>.filled(_sessionQuestions.length, false);
    _revealedFlags = List<bool>.filled(_sessionQuestions.length, false);
    _selectedAnswers = List<String?>.filled(_sessionQuestions.length, null);
    _timeExpired = false;
    _timedCorrectCount = null;
    _timedQuestionsAnsweredAtExpiry = null;
    _timeExpiredAt = null;
    _extraTimeTakenSeconds = null;

    if (examMode) {
      _startExamTimer(extraTimePercent);
    }

    notifyListeners();
  }

  void _startExamTimer(double extraTimePercent) {
    _examTimer?.cancel();
    final int baseSeconds = totalQuestions * 90;
    _secondsRemaining = (baseSeconds * (1 + extraTimePercent / 100)).round();

    _examTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 0) {
        timer.cancel();
        _autoSubmitRemaining();
      } else {
        _secondsRemaining--;
        notifyListeners();
      }
    });
  }

  void _autoSubmitRemaining() {
    _timeExpired = true;
    _timedCorrectCount = _correctCount;
    _timedQuestionsAnsweredAtExpiry = _answeredFlags.where((answered) => answered).length;
    _timeExpiredAt = DateTime.now();
    notifyListeners();
  }

  void finalizeExtraTimeTaken() {
    if (_timeExpiredAt == null) return;
    _extraTimeTakenSeconds = DateTime.now().difference(_timeExpiredAt!).inSeconds;
  }

  Future<void> startWeakestTopicsSession(
    ProgressProvider progressProvider, {
    int questionCount = 10,
    bool examMode = false,
    double extraTimePercent = 0,
  }) async {
    final List<String> weakTopics = progressProvider.weakestTopics.map((e) => e.key).toList();
    await startSession(
      topics: weakTopics.isEmpty ? null : weakTopics,
      questionCount: questionCount,
      examMode: examMode,
      extraTimePercent: extraTimePercent,
    );
  }

  void submitAnswer(String answer) async {
    if (hasAnswered || currentQuestion == null) return;

    final int answeredIndex = _currentIndex;
    final Question answeredQuestion = currentQuestion!;
    _selectedAnswers[answeredIndex] = answer;
    _answeredFlags[answeredIndex] = true;

    final bool isCorrect = _scoringService.checkAnswer(answeredQuestion, answer);
    if (isCorrect) {
      _correctCount++;
    }
    notifyListeners();

    final List<ProgressEntry> previousEntries = (await _queryService.getAllProgressEntries())
        .where((e) => e.questionId == answeredQuestion.id)
        .toList();
    final String? nextReviewDate = _spacedRepetitionService.calculateNextReviewDate(previousEntries, isCorrect);

    _queryService.logProgressEntry(ProgressEntry(
      id: DateTime.now().millisecondsSinceEpoch,
      questionId: answeredQuestion.id,
      questionType: 'original',
      correct: isCorrect,
      timestamp: DateTime.now().toIso8601String(),
      nextReviewDate: nextReviewDate,
    ));
  }

  void revealLongAnswer() {
    if (isRevealed || currentQuestion == null) return;
    _revealedFlags[_currentIndex] = true;
    notifyListeners();
  }

  void submitLongAnswerSelfMark(bool markedCorrect) async {
    if (hasAnswered || currentQuestion == null) return;

    final int answeredIndex = _currentIndex;
    final Question answeredQuestion = currentQuestion!;
    _answeredFlags[answeredIndex] = true;

    if (markedCorrect) {
      _correctCount++;
    }
    notifyListeners();

    final List<ProgressEntry> previousEntries = (await _queryService.getAllProgressEntries())
        .where((e) => e.questionId == answeredQuestion.id)
        .toList();
    final String? nextReviewDate = _spacedRepetitionService.calculateNextReviewDate(previousEntries, markedCorrect);

    _queryService.logProgressEntry(ProgressEntry(
      id: DateTime.now().millisecondsSinceEpoch,
      questionId: answeredQuestion.id,
      questionType: 'original',
      correct: markedCorrect,
      timestamp: DateTime.now().toIso8601String(),
      nextReviewDate: nextReviewDate,
    ));
  }

  void nextQuestion() {
    if (isLastQuestion) return;
    _currentIndex++;
    notifyListeners();
  }

  void previousQuestion() {
    if (isFirstQuestion) return;
    _currentIndex--;
    notifyListeners();
  }

  @override
  void dispose() {
    _examTimer?.cancel();
    super.dispose();
  }
}