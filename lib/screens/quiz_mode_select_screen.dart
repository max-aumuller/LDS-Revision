import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/quiz_provider.dart';
import '../state/progress_provider.dart';
import '../services/query_service.dart';
import 'question_screen.dart';

class QuizModeSelectScreen extends StatefulWidget {
  const QuizModeSelectScreen({super.key});

  @override
  State<QuizModeSelectScreen> createState() => _QuizModeSelectScreenState();
}

class _QuizModeSelectScreenState extends State<QuizModeSelectScreen> {
  final QueryService _queryService = QueryService();
  List<String> _availableTopics = [];
  String? _selectedTopic;
  bool _examMode = false;
  final TextEditingController _extraTimeController = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  Future<void> _loadTopics() async {
    final topics = await _queryService.getAllTopics();
    setState(() {
      _availableTopics = topics;
    });
  }

  double _getExtraTimePercent() {
    return double.tryParse(_extraTimeController.text) ?? 0;
  }

  Future<void> _startSession(Future<void> Function() sessionStarter) async {
    await sessionStarter();
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const QuestionScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Choose how you want to practice:'),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Exam Mode (timed, feedback at the end)'),
              value: _examMode,
              onChanged: (value) {
                setState(() {
                  _examMode = value;
                });
              },
            ),
            if (_examMode)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: TextField(
                  controller: _extraTimeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Extra time (%)',
                    hintText: 'e.g. 25',
                  ),
                ),
              ),
            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: () {
                final quizProvider = context.read<QuizProvider>();
                _startSession(() => quizProvider.startSession(
                      topics: null,
                      questionCount: 10,
                      examMode: _examMode,
                      extraTimePercent: _getExtraTimePercent(),
                    ));
              },
              child: const Text('All Topics (Random)'),
            ),
            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: () {
                final quizProvider = context.read<QuizProvider>();
                final progressProvider = context.read<ProgressProvider>();
                _startSession(() => quizProvider.startWeakestTopicsSession(
                      progressProvider,
                      questionCount: 10,
                      examMode: _examMode,
                      extraTimePercent: _getExtraTimePercent(),
                    ));
              },
              child: const Text('Focus on Weakest Topics'),
            ),
            const SizedBox(height: 24),

            const Text('Or pick a specific topic:'),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: _selectedTopic,
              isExpanded: true,
              hint: const Text('Select a topic'),
              items: _availableTopics.map((topic) {
                return DropdownMenuItem(value: topic, child: Text(topic));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTopic = value;
                });
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _selectedTopic == null
                  ? null
                  : () {
                      final quizProvider = context.read<QuizProvider>();
                      _startSession(() => quizProvider.startSession(
                            topics: [_selectedTopic!],
                            questionCount: 10,
                            examMode: _examMode,
                            extraTimePercent: _getExtraTimePercent(),
                          ));
                    },
              child: const Text('Start on This Topic'),
            ),
          ],
        ),
      ),
    );
  }
}