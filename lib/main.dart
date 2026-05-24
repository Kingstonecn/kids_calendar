import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/schedule_provider.dart';
import 'services/notification_service.dart';
import 'screens/schedule_detail_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化通知服务
  final notificationService = NotificationService();
  await notificationService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ScheduleProvider()),
      ],
      child: const KidsCalendarApp(),
    ),
  );

  // 检查是否有来自通知的跳转
  _checkPendingNotification();
}

void _checkPendingNotification() {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final payload = NotificationService.consumePendingPayload();
    if (payload != null) {
      final id = int.tryParse(payload);
      if (id != null) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => ScheduleDetailScreen(scheduleId: id),
          ),
        );
      }
    }
  });
}
