import '../models/progress_entry.dart';

class SpacedRepetitionService {
  String? calculateNextReviewDate(List<ProgressEntry> previousEntries, bool correctNow) {
    final int consecutiveCorrect = _countConsecutiveCorrect(previousEntries, correctNow);

    if (!correctNow) {
      return DateTime.now().add(const Duration(hours: 1)).toIso8601String();
    }

    if (consecutiveCorrect >= 3) {
      return null;
    }

    final bool wasEverWrong = previousEntries.any((e) => e.correct == false);
    final int daysToAdd = wasEverWrong ? 2 : 4;

    return DateTime.now().add(Duration(days: daysToAdd)).toIso8601String();
  }

  int _countConsecutiveCorrect(List<ProgressEntry> previousEntries, bool correctNow) {
    if (!correctNow) return 0;

    int count = 1;
    final List<ProgressEntry> sorted = List.from(previousEntries)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    for (final entry in sorted) {
      if (entry.correct == true) {
        count++;
      } else {
        break;
      }
    }

    return count;
  }

  bool isDue(String? nextReviewDate) {
    if (nextReviewDate == null) return false;
    final DateTime reviewDate = DateTime.parse(nextReviewDate);
    return DateTime.now().isAfter(reviewDate);
  }
}