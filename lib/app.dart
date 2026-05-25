import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
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
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: themeProvider.currentTheme,
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
      },
    );
  }
}
