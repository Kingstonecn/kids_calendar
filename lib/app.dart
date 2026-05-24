import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'providers/schedule_provider.dart';
import 'screens/main_shell.dart';
import 'screens/schedule_form_screen.dart';
import 'screens/schedule_detail_screen.dart';
import 'models/schedule.dart';
import 'utils/constants.dart';

/// 全局导航键, 供通知回调使用
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class KidsCalendarApp extends StatelessWidget {
  const KidsCalendarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      locale: const Locale('zh', 'CN'),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppConstants.primaryColor,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: AppConstants.backgroundColor,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        // 深度链接: /schedule/{id}
        if (settings.name != null && settings.name!.startsWith('/schedule/')) {
          final idStr = settings.name!.split('/').last;
          final id = int.tryParse(idStr);
          if (id != null) {
            return MaterialPageRoute(
              builder: (_) => ScheduleDetailScreen(scheduleId: id),
            );
          }
        }

        switch (settings.name) {
          case '/add':
            return MaterialPageRoute(
              builder: (_) => const ScheduleFormScreen(),
            );
          case '/edit':
            final schedule = settings.arguments as Schedule;
            return MaterialPageRoute(
              builder: (_) => ScheduleFormScreen(schedule: schedule),
            );
          default:
            return MaterialPageRoute(
              builder: (_) => const MainShell(),
            );
        }
      },
    );
  }
}
