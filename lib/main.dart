import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/prayer_book_provider.dart';
import 'screens/splash_screen.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => PrayerBookProvider(),
      child: const AnglicaPrayerApp(),
    ),
  );
}

class AnglicaPrayerApp extends StatelessWidget {
  const AnglicaPrayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Igitabo cy'Amasengesho",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // Clamp system text scaling so UI chrome never breaks at large font settings.
      // The in-app reading font size (provider.fontSize) is unaffected — it uses
      // explicit pixel sizes, not the text scaler.
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        minScaleFactor: 1.0,
        maxScaleFactor: 1.3,
        child: child!,
      ),
      home: const SplashScreen(),
    );
  }
}
