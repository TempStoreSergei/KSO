// lib/main.dart
import 'package:flutter/cupertino.dart';
// ЭТОТ ИМПОРТ ОБЯЗАТЕЛЕН ДЛЯ РАБОТЫ ДЕЛЕГАТОВ
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'presentation/lock_screen/lock_screen.dart'; // Убедитесь, что путь верный

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  // Используем await, чтобы гарантировать завершение инициализации перед запуском
  await initializeDateFormatting('ru_RU', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      // --- ПРАВИЛЬНАЯ КОНФИГУРАЦИЯ ДЛЯ CUPERTINOAPP ---
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate, // <-- САМЫЙ ВАЖНЫЙ ДЛЯ ДИАЛОГОВ
      ],
      supportedLocales: [
        Locale('ru', 'RU'),
      ],
      // --- КОНЕЦ ИСПРАВЛЕНИЯ ---
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(
        brightness: Brightness.dark,
      ),
      home: LockScreen(),
    );
  }
}