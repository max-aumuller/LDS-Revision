import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/progress_provider.dart';
import '../widgets/stat_tile.dart';
import 'past_paper_history_screen.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProgressProvider>().loadProgress();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: Consumer<ProgressProvider>(
        builder: (context, progressProvider, child) {
          if (progressProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (progressProvider.totalAnswered == 0 && progressProvider.pastPapersAttempted == 0) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'No attempts yet. Go answer some questions or try a past paper!',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Row(
                children: [
                  Expanded(
                    child: StatTile(
                      label: 'Overall Score',
                      value: '${progressProvider.overallPercentage.toStringAsFixed(0)}%',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: StatTile(
                      label: 'Questions Answered',
                      value: '${progressProvider.totalAnswered}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: StatTile(
                      label: 'Past Papers Attempted',
                      value: '${progressProvider.pastPapersAttempted}',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: StatTile(
                      label: 'Past Paper Average',
                      value: progressProvider.pastPaperAveragePercentage == null
                          ? '—'
                          : '${progressProvider.pastPaperAveragePercentage!.toStringAsFixed(0)}%',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('Past Paper History'),
                  subtitle: const Text('View every attempt and the score you got'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PastPaperHistoryScreen()),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Weakest Topics', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ...progressProvider.weakestTopics.map((entry) {
                return Card(
                  child: ListTile(
                    title: Text(entry.key),
                    trailing: Text('${entry.value.toStringAsFixed(0)}%'),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}