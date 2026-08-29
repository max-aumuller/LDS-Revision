import 'package:sqflite/sqflite.dart';
import '../data/database_helper.dart';
import '../models/lds_record.dart';
import '../models/question.dart';
import 'dart:convert';
import '../models/past_paper_question.dart';
import '../models/progress_entry.dart';

class QueryService {
  Future<bool> hasAnyRecords() async {
    final db = await DatabaseHelper.instance.database;
    final result = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM lds_records'));
    return (result ?? 0) > 0;
  }

  Future<List<LdsRecord>> getAllRecords() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query('lds_records');

    return maps.map((map) => LdsRecord.fromJson(map)).toList();
  }

  Future<List<LdsRecord>> getSortedRecords(String field, {bool ascending = true}) async {
    final db = await DatabaseHelper.instance.database;
    final String direction = ascending ? 'ASC' : 'DESC';
    final List<Map<String, dynamic>> maps = await db.query(
      'lds_records',
      orderBy: '$field $direction',
    );

    return maps.map((map) => LdsRecord.fromJson(map)).toList();
  }

  Future<List<LdsRecord>> getRecordsByLocation(String location) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'lds_records',
      where: 'location = ?',
      whereArgs: [location],
    );

    return maps.map((map) => LdsRecord.fromJson(map)).toList();
  }

  Future<List<LdsRecord>> getRecordsByRange(String field, double min, double max) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'lds_records',
      where: '$field BETWEEN ? AND ?',
      whereArgs: [min, max],
    );

    return maps.map((map) => LdsRecord.fromJson(map)).toList();
  }

  Future<List<LdsRecord>> getFilteredSortedRecords({
    String? location,
    String? rangeField,
    double? rangeMin,
    double? rangeMax,
    required String sortField,
    required bool ascending,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final String direction = ascending ? 'ASC' : 'DESC';

    final List<String> conditions = [];
    final List<Object?> args = [];

    if (location != null) {
      conditions.add('location = ?');
      args.add(location);
    }

    if (rangeField != null && rangeMin != null && rangeMax != null) {
      conditions.add('$rangeField BETWEEN ? AND ?');
      args.add(rangeMin);
      args.add(rangeMax);
    }

    final String? whereClause = conditions.isEmpty ? null : conditions.join(' AND ');

    final List<Map<String, dynamic>> maps = await db.query(
      'lds_records',
      where: whereClause,
      whereArgs: args.isEmpty ? null : args,
      orderBy: '$sortField $direction',
    );

    return maps.map((map) => LdsRecord.fromJson(map)).toList();
  }

  /// Deletes every existing lds_records row and inserts [records] in its
  /// place, atomically, so re-importing an updated dataset overwrites
  /// cleanly instead of duplicating rows.
  Future<void> replaceAllRecords(List<LdsRecord> records) async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      await txn.delete('lds_records');
      final batch = txn.batch();
      for (final record in records) {
        batch.insert('lds_records', record.toMap());
      }
      await batch.commit(noResult: true);
    });
  }

  Future<List<Question>> getQuestions({List<String>? topics, int? limit}) async {
    final db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'questions',
      where: (topics != null && topics.isNotEmpty)
          ? 'topic IN (${List.filled(topics.length, '?').join(', ')})'
          : null,
      whereArgs: (topics != null && topics.isNotEmpty) ? topics : null,
    );

    final List<Question> questions = maps.map((map) {
      final Map<String, dynamic> converted = Map<String, dynamic>.from(map);
      if (converted['options'] != null) {
        converted['options'] = List<String>.from(jsonDecode(converted['options']));
      }
      return Question.fromJson(converted);
    }).toList();

    questions.shuffle();

    if (limit != null && limit < questions.length) {
      return questions.sublist(0, limit);
    }

    return questions;
  }

  Future<List<PastPaperQuestion>> getPastPapers() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query('past_paper_questions');

    return maps.map((map) {
      final Map<String, dynamic> converted = Map<String, dynamic>.from(map);
      converted['yourMarkingCriteria'] = List<String>.from(jsonDecode(converted['yourMarkingCriteria']));
      return PastPaperQuestion.fromJson(converted);
    }).toList();
  }

  Future<void> logProgressEntry(ProgressEntry entry) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('progress_entries', entry.toMap());
  }

  Future<List<ProgressEntry>> getAllProgressEntries() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query('progress_entries');

    return maps.map((map) {
      final Map<String, dynamic> converted = Map<String, dynamic>.from(map);
      if (converted['correct'] != null) {
        converted['correct'] = converted['correct'] == 1;
      }
      return ProgressEntry.fromJson(converted);
    }).toList();
  }

  Future<List<String>> getAllTopics() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'questions',
      distinct: true,
      columns: ['topic'],
    );
    return maps.map((map) => map['topic'] as String).toList();
  }
}