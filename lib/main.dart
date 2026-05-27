import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'splash_screen.dart';
import 'package:pawiva/services/notification_service.dart';
import 'package:pawiva/l10n/app_localizations.dart';
import 'package:pawiva/l10n/locale_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase error: $e');
  };
  try {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (e) {
    debugPrint('Crashlytics error: $e');
  }
  tz.initializeTimeZones();
  runApp(const PawivaApp());
  try {
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('Notification init error: $e');
  }
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