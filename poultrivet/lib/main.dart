import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import '/pages/welcome_page.dart';
import 'services/alert_service.dart';
import 'services/background_service.dart';
import 'services/theme_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await AlertService.init();
  await BackgroundService.init();
  await BackgroundService.scheduleDistrictCheck();

  // Load saved theme preference before first frame
  final themeNotifier = ThemeNotifier();
  await themeNotifier.load();

  runApp(
    ChangeNotifierProvider.value(
      value: themeNotifier,
      child: const PoulVetApp(),
    ),
  );
}

class PoulVetApp extends StatelessWidget {
  const PoulVetApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeNotifier>();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: theme.themeMode,
      theme:     ThemeNotifier.lightTheme(theme.fontSize),
      darkTheme: ThemeNotifier.darkTheme(theme.fontSize),
      home: const WelcomePage(),
    );
  }
}
