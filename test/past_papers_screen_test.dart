// Verifies that tapping the "question paper" / "mark scheme" buttons on the
// Past Papers screen hands the URL to the OS (external browser) instead of
// opening it in an in-app viewer.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import 'package:flutter_app_large_data_set/screens/past_papers_screen.dart';

class _RecordingUrlLauncher extends UrlLauncherPlatform {
  final List<({String url, PreferredLaunchMode mode})> calls = [];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    calls.add((url: url, mode: options.mode));
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late _RecordingUrlLauncher fakeLauncher;

  setUp(() {
    fakeLauncher = _RecordingUrlLauncher();
    UrlLauncherPlatform.instance = fakeLauncher;
  });

  Future<void> pumpPastPapersScreen(WidgetTester tester) async {
    // sqflite_common_ffi does real (non-fake-clock) async I/O, which needs
    // to run inside runAsync to actually complete under AutomatedTestWidgetsFlutterBinding.
    await tester.runAsync(() async {
      await tester.pumpWidget(const MaterialApp(home: PastPapersScreen()));
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pump();
  }

  testWidgets('question paper button opens the PDF via the external browser, not in-app', (tester) async {
    await pumpPastPapersScreen(tester);

    final pdfButton = find.byIcon(Icons.picture_as_pdf).first;
    await tester.tap(pdfButton);
    await tester.pump();

    // No in-app viewer should have been pushed — we're still on this screen.
    expect(find.text('Past Papers'), findsOneWidget);

    expect(fakeLauncher.calls, hasLength(1));
    expect(fakeLauncher.calls.single.mode, PreferredLaunchMode.externalApplication);
    expect(fakeLauncher.calls.single.url, isNotEmpty);
  });

  testWidgets('mark scheme button opens via the external browser when present', (tester) async {
    await pumpPastPapersScreen(tester);

    final markSchemeButtons = find.byIcon(Icons.checklist);
    expect(markSchemeButtons, findsWidgets, reason: 'expected at least one seeded paper with a mark scheme URL');

    await tester.tap(markSchemeButtons.first);
    await tester.pump();

    expect(find.text('Past Papers'), findsOneWidget);
    expect(fakeLauncher.calls, hasLength(1));
    expect(fakeLauncher.calls.single.mode, PreferredLaunchMode.externalApplication);
  });
}
