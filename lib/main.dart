import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/settings_service.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const TranslatorApp());
}

class TranslatorApp extends StatefulWidget {
  const TranslatorApp({super.key});

  @override
  State<TranslatorApp> createState() => _TranslatorAppState();
}

class _TranslatorAppState extends State<TranslatorApp> {
  bool _darkMode = true;

  @override
  void initState() {
    super.initState();
    SettingsService().getDarkMode().then((v) => setState(() => _darkMode = v));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Language Translator Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
      home: HomeScreen(onDarkModeChanged: (v) => setState(() => _darkMode = v)),
    );
  }
}
