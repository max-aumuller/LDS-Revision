import 'package:flutter/material.dart';
import '../models/past_paper_question.dart';
import '../models/progress_entry.dart';
import '../services/query_service.dart';
import '../theme.dart';

class PastPaperMarkingScreen extends StatefulWidget {
  final PastPaperQuestion pastPaper;

  const PastPaperMarkingScreen({super.key, required this.pastPaper});

  @override
  State<PastPaperMarkingScreen> createState() => _PastPaperMarkingScreenState();
}

class _PastPaperMarkingScreenState extends State<PastPaperMarkingScreen> {
  late List<bool> _checkedItems;
  final QueryService _queryService = QueryService();
  final TextEditingController _marksController = TextEditingController();
  bool _hasSubmitted = false;

  @override
  void initState() {
    super.initState();
    _checkedItems = List.filled(widget.pastPaper.yourMarkingCriteria.length, false);
  }

  void _submitMarks() {
    final int? marks = int.tryParse(_marksController.text);
    if (marks == null || marks < 0 || marks > widget.pastPaper.totalMarks) return;

    _queryService.logProgressEntry(ProgressEntry(
      id: DateTime.now().millisecondsSinceEpoch,
      questionId: widget.pastPaper.id,
      questionType: 'pastPaper',
      correct: null,
      timestamp: DateTime.now().toIso8601String(),
      nextReviewDate: null,
      marksAchieved: marks,
      totalMarksAvailable: widget.pastPaper.totalMarks,
    ));

    setState(() {
      _hasSubmitted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.pastPaper.examSeries} — Q${widget.pastPaper.questionNumber}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          ...List.generate(widget.pastPaper.yourMarkingCriteria.length, (index) {
            return CheckboxListTile(
              title: Text(widget.pastPaper.yourMarkingCriteria[index]),
              value: _checkedItems[index],
              onChanged: (value) {
                setState(() {
                  _checkedItems[index] = value ?? false;
                });
              },
            );
          }),
          const SizedBox(height: AppSpacing.xl),
          const Divider(),
          const SizedBox(height: AppSpacing.lg),
          if (_hasSubmitted)
            const Center(child: Text('Result saved.', style: TextStyle(fontStyle: FontStyle.italic)))
          else ...[
            Text(
              'How many marks out of ${widget.pastPaper.totalMarks} did you score?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _marksController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Marks (0-${widget.pastPaper.totalMarks})',
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                ElevatedButton(
                  onPressed: _submitMarks,
                  child: const Text('Submit'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}