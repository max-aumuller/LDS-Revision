import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/data_browser_provider.dart';
import '../theme.dart';
import '../widgets/sort_filter_bar.dart';
import 'lds_import_screen.dart';
import 'record_detail_screen.dart';

class DataBrowserScreen extends StatefulWidget {
  const DataBrowserScreen({super.key});

  @override
  State<DataBrowserScreen> createState() => _DataBrowserScreenState();
}

class _DataBrowserScreenState extends State<DataBrowserScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DataBrowserProvider>().loadRecords();
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Large Data Set'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Import data',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LdsImportScreen()),
              );
              if (context.mounted) {
                context.read<DataBrowserProvider>().loadRecords();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SortFilterBar(),
          Expanded(
            child: Consumer<DataBrowserProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.records.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.table_chart_outlined,
                            size: 48,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          const Text(
                            'No Large Data Set imported yet',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          const Text(
                            'This app doesn\'t ship with a copy of Pearson\'s Large Data Set. '
                            'Download it from Pearson and import it to browse and practice with your data.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          ElevatedButton.icon(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const LdsImportScreen()),
                              );
                              if (context.mounted) {
                                context.read<DataBrowserProvider>().loadRecords();
                              }
                            },
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Import Large Data Set'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: provider.records.length,
                  itemBuilder: (context, index) {
                    final record = provider.records[index];
                    return ListTile(
                      title: Text('${record.location} — ${record.date}'),
                      subtitle: Text('Mean Temp: ${record.dailyMeanTemp ?? "n/a"}°C'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RecordDetailScreen(record: record),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}