import 'dart:convert';

class Question {
  final int id;
  final String type;
  final String prompt;
  final List<String>? options;
  final String correctAnswer;
  final String explanation;
  final String topic;
  final String difficulty;
  final String? relatedLocation;

  Question({
    required this.id,
    required this.type,
    required this.prompt,
    this.options,
    required this.correctAnswer,
    required this.explanation,
    required this.topic,
    required this.difficulty,
    this.relatedLocation,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      type: json['type'],
      prompt: json['prompt'],
      options: json['options'] != null ? List<String>.from(json['options']) : null,
      correctAnswer: json['correctAnswer'],
      explanation: json['explanation'],
      topic: json['topic'],
      difficulty: json['difficulty'],
      relatedLocation: json['relatedLocation'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'prompt': prompt,
      'options': options != null ? jsonEncode(options) : null,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'topic': topic,
      'difficulty': difficulty,
      'relatedLocation': relatedLocation,
    };
  }
}