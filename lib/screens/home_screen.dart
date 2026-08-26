import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../state/progress_provider.dart';
import '../state/quiz_provider.dart';
import 'question_screen.dart';

class HomeScreen extends StatefulWidget {
  final void Function(int) onNavigateToTab;

  const HomeScreen({super.key, required this.onNavigateToTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  DateTime _asExamDate = DateTime(2027, 5, 21, 13, 30);
  DateTime _aLevelExamDate = DateTime(2027, 6, 16, 13, 30);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProgressProvider>().loadProgress();
      context.read<QuizProvider>().refreshDueQuestionCount();
    });
    _loadExamDates();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<QuizProvider>().refreshDueQuestionCount();
      setState(() {});
    }
  }

  Future<void> _startDueReview() async {
    final quizProvider = context.read<QuizProvider>();
    await quizProvider.startDueReviewSession();
    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QuestionScreen()),
    );

    if (mounted) {
      context.read<QuizProvider>().refreshDueQuestionCount();
    }
  }

  Future<void> _loadExamDates() async {
    final prefs = await SharedPreferences.getInstance();
    final String? storedAs = prefs.getString('asExamDate');
    final String? storedALevel = prefs.getString('aLevelExamDate');

    setState(() {
      if (storedAs != null) _asExamDate = DateTime.parse(storedAs);
      if (storedALevel != null) _aLevelExamDate = DateTime.parse(storedALevel);
    });
  }

  Future<void> _pickExamDate(bool isAsLevel) async {
    final DateTime current = isAsLevel ? _asExamDate : _aLevelExamDate;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 1095)),
    );

    if (picked != null) {
      final prefs = await SharedPreferences.getInstance();
      final String key = isAsLevel ? 'asExamDate' : 'aLevelExamDate';
      await prefs.setString(key, picked.toIso8601String());
      setState(() {
        if (isAsLevel) {
          _asExamDate = picked;
        } else {
          _aLevelExamDate = picked;
        }
      });
    }
  }

  Widget _buildCountdownCard(String label, DateTime examDate, bool isAsLevel) {
    final int daysRemaining = examDate.difference(DateTime.now()).inDays;
    final bool hasPassed = daysRemaining < 0;

    return Expanded(
      child: Card(
        child: InkWell(
          onTap: () => _pickExamDate(isAsLevel),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(label, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 8),
                Text(
                  hasPassed ? 'Sat' : '$daysRemaining',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                if (!hasPassed)
                  Text('days to go', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(
                  'Tap to change date',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Consumer<ProgressProvider>(
        builder: (context, progressProvider, child) {
          final int dueCount = context.watch<QuizProvider>().dueQuestionCount;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text('Welcome back!', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),

              Row(
                children: [
                  _buildCountdownCard('AS Level Exam', _asExamDate, true),
                  const SizedBox(width: 8),
                  _buildCountdownCard('A Level Exam', _aLevelExamDate, false),
                ],
              ),

              const SizedBox(height: 24),
              Text('Your Progress', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              '${progressProvider.overallPercentage.toStringAsFixed(0)}%',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 4),
                            Text('Overall Score', style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              '${progressProvider.totalAnswered}',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 4),
                            Text('Questions Answered', style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              if (dueCount > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Card(
                    color: Colors.amber.shade50,
                    child: ListTile(
                      leading: const Icon(Icons.refresh),
                      title: Text('$dueCount question${dueCount == 1 ? '' : 's'} due for review'),
                      subtitle: const Text('Tap to review them now'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _startDueReview,
                    ),
                  ),
                ),
              if (progressProvider.totalAnswered > 0 && progressProvider.weakestTopics.isNotEmpty)
                Card(
                  color: Colors.deepPurple.shade50,
                  child: ListTile(
                    leading: const Icon(Icons.trending_up),
                    title: Text('Weakest topic: ${progressProvider.weakestTopics.first.key}'),
                    subtitle: Text('${progressProvider.weakestTopics.first.value.toStringAsFixed(0)}% correct so far'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => widget.onNavigateToTab(2),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}