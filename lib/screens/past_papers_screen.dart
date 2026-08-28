import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/past_paper_question.dart';
import '../services/query_service.dart';
import 'past_paper_marking_screen.dart';

class PastPapersScreen extends StatefulWidget {
  const PastPapersScreen({super.key});

  @override
  State<PastPapersScreen> createState() => _PastPapersScreenState();
}

class _PastPapersScreenState extends State<PastPapersScreen> {
  final QueryService _queryService = QueryService();
  List<PastPaperQuestion> _pastPapers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPastPapers();
  }

  Future<void> _loadPastPapers() async {
    final papers = await _queryService.getPastPapers();
    setState(() {
      _pastPapers = papers;
      _isLoading = false;
    });
  }

  Future<void> _openInBrowser(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Past Papers')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pastPapers.isEmpty
              ? const Center(child: Text('No past papers added yet.'))
              : ListView.builder(
                  itemCount: _pastPapers.length,
                  itemBuilder: (context, index) {
                    final paper = _pastPapers[index];
                    return ListTile(
                      title: Text('${paper.examSeries} — Paper ${paper.paperNumber}, Q${paper.questionNumber}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: paper.level == 'A Level' ? Colors.deepPurple.shade100 : Colors.teal.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  paper.level,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(paper.topic)),
                            ],
                          ),
                          const Text(
                            'Tap for marking criteria',
                            style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.picture_as_pdf),
                            tooltip: 'Question paper',
                            onPressed: () => _openInBrowser(paper.pdfUrl),
                          ),
                          if (paper.markSchemeUrl != null)
                            IconButton(
                              icon: const Icon(Icons.checklist),
                              tooltip: 'Mark scheme',
                              onPressed: () => _openInBrowser(paper.markSchemeUrl!),
                            ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PastPaperMarkingScreen(pastPaper: paper),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}