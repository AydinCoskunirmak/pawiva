import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'splash_screen.dart';
import 'package:pawiva/services/notification_service.dart';
import 'package:pawiva/l10n/app_localizations.dart';
import 'package:pawiva/l10n/locale_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  tz.initializeTimeZones();
  await NotificationService().initialize();
  await NotificationService().requestPermissions();
  runApp(const PawivaApp());
}

class PawivaApp extends StatefulWidget {
  const PawivaApp({super.key});

  @override
  State<PawivaApp> createState() => PawivaAppState();
}

class PawivaAppState extends State<PawivaApp> {
  AppLocalizations get localizations => AppLocalizations(LocaleProvider().languageCode);

  @override
  void initState() {
    super.initState();
    LocaleProvider().addListener(_onLanguageChanged);
    LocaleProvider().loadSavedLanguage();
  }

  void _onLanguageChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    LocaleProvider().removeListener(_onLanguageChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pawiva',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: false,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFAE3C6)),
      ),
      home: const SplashScreen(),
    );
  }
}
