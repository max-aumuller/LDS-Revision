import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/data_browser_provider.dart';
import 'state/quiz_provider.dart';
import 'state/progress_provider.dart';
import 'theme.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => DataBrowserProvider()),
        ChangeNotifierProvider(create: (context) => QuizProvider()),
        ChangeNotifierProvider(create: (context) => ProgressProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LDS Revision',
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}