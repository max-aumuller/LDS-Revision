import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/data_browser_provider.dart';
import '../widgets/sort_filter_bar.dart';
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
      appBar: AppBar(title: const Text('Large Data Set')),
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
                  return const Center(child: Text('No records found.'));
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