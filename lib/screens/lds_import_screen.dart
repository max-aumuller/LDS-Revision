import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/lds_import_service.dart';
import '../services/query_service.dart';

// TODO: confirm this is still the correct page before shipping — Pearson
// reorganises its qualifications site periodically.
const String _pearsonLdsUrl =
    'https://qualifications.pearson.com/en/qualifications/edexcel-a-levels/mathematics-2017.coursematerials.html#filterQuery=category:Pearson-UK:Category%2FSpecification-and-sample-assessments';
const String _cloudConvertUrl = 'https://cloudconvert.com/xls-to-xlsx';

enum _ImportStatus { idle, loading, success, error }

class LdsImportScreen extends StatefulWidget {
  const LdsImportScreen({super.key});

  @override
  State<LdsImportScreen> createState() => _LdsImportScreenState();
}

class _LdsImportScreenState extends State<LdsImportScreen> {
  final QueryService _queryService = QueryService();
  final LdsImportService _importService = LdsImportService();

  _ImportStatus _status = _ImportStatus.idle;
  LdsImportResult? _result;
  String? _errorMessage;

  Future<void> _openPearsonPage() async {
    final uri = Uri.parse(_pearsonLdsUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the Pearson website.')),
      );
    }
  }

  Future<void> _openCloudConvert() async {
    final uri = Uri.parse(_cloudConvertUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open CloudConvert.')),
      );
    }
  }

  Future<void> _pickAndImport() async {
    final hasExisting = await _queryService.hasAnyRecords();
    if (hasExisting) {
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Replace existing data?'),
          content: const Text(
            'This will replace your currently imported Large Data Set with the contents of the new file. This can\'t be undone — continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Replace'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    // Deliberately not filtering by allowedExtensions here: on iOS, files
    // downloaded via Safari are sometimes tagged with a UTI that doesn't
    // match file_picker's xlsx filter, which makes them appear greyed out
    // and unselectable in the native picker. We validate the extension
    // ourselves after picking instead.
    final picked = await FilePicker.pickFile(type: FileType.any);
    if (picked == null || picked.path == null) return;

    final extension = picked.extension?.toLowerCase();
    if (extension != 'xlsx' && extension != 'xls') {
      if (!mounted) return;
      setState(() {
        _status = _ImportStatus.error;
        _result = null;
        _errorMessage = '"${picked.name}" isn\'t an Excel file. Make sure you selected the Large Data Set workbook (.xls or .xlsx) you downloaded from Pearson.';
      });
      return;
    }

    setState(() {
      _status = _ImportStatus.loading;
      _result = null;
      _errorMessage = null;
    });

    try {
      final result = await _importService.importFromFile(picked.path!);

      if (result.rowsImported == 0) {
        setState(() {
          _status = _ImportStatus.error;
          _errorMessage = result.warnings.isNotEmpty
              ? 'No rows could be imported.\n\n${result.warnings.join('\n')}'
              : 'No rows could be imported. Check that this is the Large Data Set workbook.';
        });
        return;
      }

      await _queryService.replaceAllRecords(result.records);

      setState(() {
        _status = _ImportStatus.success;
        _result = result;
      });
    } on LdsImportException catch (e) {
      setState(() {
        _status = _ImportStatus.error;
        _errorMessage = extension == 'xls'
            ? '${e.message}\n\nSome .xls files use features this app can\'t yet read. Try opening the file in Excel, Numbers, or Google Sheets and saving/exporting it as .xlsx, then import that instead. Or convert it online at cloudconvert.com/xls-to-xlsx.'
            : e.message;
      });
    } catch (e) {
      setState(() {
        _status = _ImportStatus.error;
        _errorMessage = 'Something went wrong while importing this file: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import Large Data Set')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'This app does not include a copy of Pearson\'s Large Data Set. '
              'Download your own copy from Pearson\'s official website, then import '
              'the file here (.xls or .xlsx).',
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _openPearsonPage,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open Pearson\'s Large Data Set page'),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('On that page:', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    _instructionStep(1, 'Find "AS and A level Mathematics" and expand "Specification and sample assessments".'),
                    _instructionStep(2, 'In the list that appears, find "AS and A level Mathematics Data Set" and download it.'),
                    _instructionStep(3, 'Come back to this app and tap "Choose file" below, then select the file you just downloaded.'),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black54),
                        children: [
                          const TextSpan(
                            text: 'If the download is a .xls file and won\'t import, open it in Excel, '
                                'Numbers, or Google Sheets, save/export it as .xlsx, and import that instead. '
                                'Or convert it online with ',
                          ),
                          TextSpan(
                            text: 'cloudconvert.com/xls-to-xlsx',
                            style: TextStyle(color: Theme.of(context).colorScheme.primary, decoration: TextDecoration.underline),
                            recognizer: TapGestureRecognizer()..onTap = _openCloudConvert,
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _status == _ImportStatus.loading ? null : _pickAndImport,
              icon: const Icon(Icons.upload_file),
              label: const Text('Choose file'),
            ),
            const SizedBox(height: 24),
            _buildStatusArea(),
          ],
        ),
      ),
    );
  }

  Widget _instructionStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              '$number',
              style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildStatusArea() {
    switch (_status) {
      case _ImportStatus.idle:
        return const SizedBox.shrink();

      case _ImportStatus.loading:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        );

      case _ImportStatus.success:
        final result = _result!;
        return Card(
          color: Colors.green.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Imported ${result.rowsImported} row${result.rowsImported == 1 ? '' : 's'} '
                        'across ${result.locationsFound} location${result.locationsFound == 1 ? '' : 's'}.',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                if (result.warnings.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Warnings:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  ...result.warnings.map((w) => Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text('• $w', style: const TextStyle(fontSize: 13)),
                      )),
                ],
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ),
        );

      case _ImportStatus.error:
        return Card(
          color: Colors.red.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_errorMessage ?? 'Something went wrong.'),
                ),
              ],
            ),
          ),
        );
    }
  }
}
