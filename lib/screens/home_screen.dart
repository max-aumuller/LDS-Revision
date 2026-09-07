import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../state/progress_provider.dart';
import '../state/quiz_provider.dart';
import '../theme.dart';
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
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Text(label, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  hasPassed ? 'Sat' : '$daysRemaining',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                if (!hasPassed)
                  Text('days to go', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Tap to change date',
                  style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
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

          final colorScheme = Theme.of(context).colorScheme;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text('Welcome back!', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.lg),

              Row(
                children: [
                  _buildCountdownCard('AS Level Exam', _asExamDate, true),
                  const SizedBox(width: AppSpacing.sm),
                  _buildCountdownCard('A Level Exam', _aLevelExamDate, false),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),
              Text('Your Progress', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          children: [
                            Text(
                              '${progressProvider.overallPercentage.toStringAsFixed(0)}%',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text('Overall Score', style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          children: [
                            Text(
                              '${progressProvider.totalAnswered}',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text('Questions Answered', style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),
              if (dueCount > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Card(
                    color: colorScheme.tertiaryContainer,
                    child: ListTile(
                      leading: Icon(Icons.refresh, color: colorScheme.onTertiaryContainer),
                      title: Text(
                        '$dueCount question${dueCount == 1 ? '' : 's'} due for review',
                        style: TextStyle(color: colorScheme.onTertiaryContainer),
                      ),
                      subtitle: Text(
                        'Tap to review them now',
                        style: TextStyle(color: colorScheme.onTertiaryContainer),
                      ),
                      trailing: Icon(Icons.chevron_right, color: colorScheme.onTertiaryContainer),
                      onTap: _startDueReview,
                    ),
                  ),
                ),
              if (progressProvider.totalAnswered > 0 && progressProvider.weakestTopics.isNotEmpty)
                Card(
                  color: colorScheme.secondaryContainer,
                  child: ListTile(
                    leading: Icon(Icons.trending_up, color: colorScheme.onSecondaryContainer),
                    title: Text(
                      'Weakest topic: ${progressProvider.weakestTopics.first.key}',
                      style: TextStyle(color: colorScheme.onSecondaryContainer),
                    ),
                    subtitle: Text(
                      '${progressProvider.weakestTopics.first.value.toStringAsFixed(0)}% correct so far',
                      style: TextStyle(color: colorScheme.onSecondaryContainer),
                    ),
                    trailing: Icon(Icons.chevron_right, color: colorScheme.onSecondaryContainer),
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