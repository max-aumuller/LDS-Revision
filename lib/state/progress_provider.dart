import 'package:flutter/foundation.dart';
import '../models/progress_entry.dart';
import '../models/question.dart';
import '../models/past_paper_question.dart';
import '../services/query_service.dart';

class PastPaperAttempt {
  final PastPaperQuestion paper;
  final ProgressEntry entry;

  PastPaperAttempt({required this.paper, required this.entry});
}

class ProgressProvider extends ChangeNotifier {
  final QueryService _queryService = QueryService();

  List<ProgressEntry> _entries = [];
  List<PastPaperQuestion> _pastPapers = [];
  Map<String, List<ProgressEntry>> _entriesByTopic = {};
  bool _isLoading = false;

  Map<String, double> get topicPercentages {
    final Map<String, double> result = {};
    _entriesByTopic.forEach((topic, entries) {
      final int correct = entries.where((e) => e.correct == true).length;
      result[topic] = entries.isEmpty ? 0.0 : (correct / entries.length) * 100;
    });
    return result;
  }

  List<MapEntry<String, double>> get weakestTopics {
    final List<MapEntry<String, double>> sorted = topicPercentages.entries.toList();
    sorted.sort((a, b) => a.value.compareTo(b.value));
    return sorted.take(3).toList();
  }

  bool get isLoading => _isLoading;

  List<ProgressEntry> get _quizEntries =>
      _entries.where((e) => e.questionType == 'original').toList();

  int get totalAnswered => _quizEntries.length;
  int get totalCorrect => _quizEntries.where((e) => e.correct == true).length;

  double get overallPercentage {
    if (_quizEntries.isEmpty) return 0.0;
    return (totalCorrect / totalAnswered) * 100;
  }

  List<ProgressEntry> get _pastPaperEntries =>
      _entries.where((e) => e.questionType == 'pastPaper' && e.marksAchieved != null).toList();

  int get pastPapersAttempted => _pastPaperEntries.length;

  double? get pastPaperAveragePercentage {
    final entries = _pastPaperEntries;
    if (entries.isEmpty) return null;

    final double totalPercentageSum = entries.fold(0.0, (sum, e) {
      return sum + (e.marksAchieved! / e.totalMarksAvailable!) * 100;
    });

    return totalPercentageSum / entries.length;
  }

  List<PastPaperAttempt> get pastPaperHistory {
    final Map<int, PastPaperQuestion> paperById = {
      for (final paper in _pastPapers) paper.id: paper,
    };

    final List<PastPaperAttempt> history = [];
    for (final entry in _pastPaperEntries) {
      final PastPaperQuestion? paper = paperById[entry.questionId];
      if (paper == null) continue;
      history.add(PastPaperAttempt(paper: paper, entry: entry));
    }

    history.sort((a, b) => b.entry.timestamp.compareTo(a.entry.timestamp));
    return history;
  }

  Future<void> loadProgress() async {
    _isLoading = true;
    notifyListeners();

    _entries = await _queryService.getAllProgressEntries();
    _pastPapers = await _queryService.getPastPapers();
    await _buildTopicBreakdown();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _buildTopicBreakdown() async {
    final List<Question> allQuestions = await _queryService.getQuestions(limit: null);
    final Map<int, String> questionIdToTopic = {
      for (final q in allQuestions) q.id: q.topic,
    };

    final Map<String, List<ProgressEntry>> grouped = {};

    for (final entry in _quizEntries) {
      final String? topic = questionIdToTopic[entry.questionId];
      if (topic == null) continue;

      grouped.putIfAbsent(topic, () => []);
      grouped[topic]!.add(entry);
    }

    _entriesByTopic = grouped;
  }
}