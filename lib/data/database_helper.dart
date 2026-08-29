import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/question.dart';
import '../models/past_paper_question.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'lds_app.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE lds_records(
        id INTEGER PRIMARY KEY,
        location TEXT NOT NULL,
        year INTEGER NOT NULL,
        date TEXT NOT NULL,
        dailyMeanTemp REAL,
        dailyTotalRainfall REAL,
        dailyMeanPressure REAL,
        dailyMeanWindSpeed REAL,
        windSpeedBeaufort TEXT,
        dailyTotalSunshine REAL,
        dailyMaxGust REAL,
        dailyMaxRelativeHumidity REAL,
        cloudCoverOktas INTEGER,
        visibilityDam REAL,
        windDirectionDegrees INTEGER,
        windDirectionCardinal TEXT,
        gustDirectionDegrees INTEGER,
        gustDirectionCardinal TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE questions(
        id INTEGER PRIMARY KEY,
        type TEXT NOT NULL,
        prompt TEXT NOT NULL,
        options TEXT,
        correctAnswer TEXT NOT NULL,
        explanation TEXT NOT NULL,
        topic TEXT NOT NULL,
        difficulty TEXT NOT NULL,
        relatedLocation TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE past_paper_questions(
        id INTEGER PRIMARY KEY,
        examSeries TEXT NOT NULL,
        paperNumber INTEGER NOT NULL,
        questionNumber TEXT NOT NULL,
        pdfUrl TEXT NOT NULL,
        markSchemeUrl TEXT,
        yourMarkingCriteria TEXT NOT NULL,
        topic TEXT NOT NULL,
        level TEXT NOT NULL,
        totalMarks INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE progress_entries(
        id INTEGER PRIMARY KEY,
        questionId INTEGER NOT NULL,
        questionType TEXT NOT NULL,
        correct INTEGER,
        timestamp TEXT NOT NULL,
        nextReviewDate TEXT,
        marksAchieved INTEGER,
        totalMarksAvailable INTEGER
      )
    ''');
    await _seedQuestionBankData(db);
    await _seedPastPapersData(db);
  }

  Future<void> _seedQuestionBankData(Database db) async {
    final String jsonString = await rootBundle.loadString('lib/data/question_bank.json');
    final List<dynamic> jsonList = jsonDecode(jsonString);

    for (final item in jsonList) {
      final question = Question.fromJson(item);
      await db.insert('questions', question.toMap());
    }
  }

  Future<void> _seedPastPapersData(Database db) async {
    final String jsonString = await rootBundle.loadString('lib/data/past_papers.json');
    final List<dynamic> jsonList = jsonDecode(jsonString);

    for (final item in jsonList) {
      final pastPaperQuestion = PastPaperQuestion.fromJson(item);
      await db.insert('past_paper_questions', pastPaperQuestion.toMap());
    }
  }
}