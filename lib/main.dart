// lib/main.dart
import 'package:flutter/cupertino.dart';
// ЭТОТ ИМПОРТ ОБЯЗАТЕЛЕН ДЛЯ РАБОТЫ ДЕЛЕГАТОВ
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:motel/presentation/lock_screen/lock_screen.dart'; // Убедитесь, что путь верный
import 'package:motel/core/api/api_client.dart';
import 'package:motel/core/navigation/app_navigator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await ApiClient.instance.init();
  // Используем await, чтобы гарантировать завершение инициализации перед запуском
  await initializeDateFormatting('ru_RU', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      navigatorKey: AppNavigator.navigatorKey,
      // --- ПРАВИЛЬНАЯ КОНФИГУРАЦИЯ ДЛЯ CUPERTINOAPP ---
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate, // <-- САМЫЙ ВАЖНЫЙ ДЛЯ ДИАЛОГОВ
      ],
      supportedLocales: const [
        Locale('ru', 'RU'),
      ],
      // --- КОНЕЦ ИСПРАВЛЕНИЯ ---
      debugShowCheckedModeBanner: false,
      theme: const CupertinoThemeData(
        brightness: Brightness.dark,
      ),
      home: LockScreen(),
    );
  }
}
