import 'dart:convert';

class PastPaperQuestion {
  final int id;
  final String examSeries;
  final int paperNumber;
  final String questionNumber;
  final String pdfUrl;
  final String? markSchemeUrl;
  final List<String> yourMarkingCriteria;
  final String topic;
  final String level;
  final int totalMarks;

  PastPaperQuestion({
    required this.id,
    required this.examSeries,
    required this.paperNumber,
    required this.questionNumber,
    required this.pdfUrl,
    this.markSchemeUrl,
    required this.yourMarkingCriteria,
    required this.topic,
    required this.level,
    required this.totalMarks,
  });

  factory PastPaperQuestion.fromJson(Map<String, dynamic> json) {
    return PastPaperQuestion(
      id: json['id'],
      examSeries: json['examSeries'],
      paperNumber: json['paperNumber'],
      questionNumber: json['questionNumber'],
      pdfUrl: json['pdfUrl'],
      markSchemeUrl: json['markSchemeUrl'],
      yourMarkingCriteria: List<String>.from(json['yourMarkingCriteria']),
      topic: json['topic'],
      level: json['level'],
      totalMarks: json['totalMarks'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'examSeries': examSeries,
      'paperNumber': paperNumber,
      'questionNumber': questionNumber,
      'pdfUrl': pdfUrl,
      'markSchemeUrl': markSchemeUrl,
      'yourMarkingCriteria': jsonEncode(yourMarkingCriteria),
      'topic': topic,
      'level': level,
      'totalMarks': totalMarks,
    };
  }
}