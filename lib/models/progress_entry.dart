class ProgressEntry {
  final int id;
  final int questionId;
  final String questionType;
  final bool? correct;
  final String timestamp;
  final String? nextReviewDate;
  final int? marksAchieved;
  final int? totalMarksAvailable;

  ProgressEntry({
    required this.id,
    required this.questionId,
    required this.questionType,
    this.correct,
    required this.timestamp,
    this.nextReviewDate,
    this.marksAchieved,
    this.totalMarksAvailable,
  });

  factory ProgressEntry.fromJson(Map<String, dynamic> json) {
    return ProgressEntry(
      id: json['id'],
      questionId: json['questionId'],
      questionType: json['questionType'],
      correct: json['correct'],
      timestamp: json['timestamp'],
      nextReviewDate: json['nextReviewDate'],
      marksAchieved: json['marksAchieved'],
      totalMarksAvailable: json['totalMarksAvailable'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'questionId': questionId,
      'questionType': questionType,
      'correct': correct,
      'timestamp': timestamp,
      'nextReviewDate': nextReviewDate,
      'marksAchieved': marksAchieved,
      'totalMarksAvailable': totalMarksAvailable,
    };
  }
}