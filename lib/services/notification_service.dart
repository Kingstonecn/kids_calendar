import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  // 通知点击后存储的 payload, 供 App 检查并跳转
  static String? pendingPayload;

  // 通知ID基数
  static const int _baseId = 10000;

  /// 初始化通知插件
  Future<void> init() async {
    // 初始化时区数据
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// 通知点击回调
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null && response.payload!.isNotEmpty) {
      pendingPayload = response.payload;
    }
  }

  /// 获取待处理的 payload 并清除
  static String? consumePendingPayload() {
    final payload = pendingPayload;
    pendingPayload = null;
    return payload;
  }

  /// 请求通知权限
  Future<bool> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    return false;
  }

  /// 检查是否已授予通知权限
  Future<bool> hasPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.areNotificationsEnabled() ?? false;
    }
    return true;
  }

  /// 预约提醒通知
  /// [scheduledDate] 是日程的开始日期时间
  /// [minutesBefore] 提前提醒分钟数
  Future<void> scheduleNotification({
    required int scheduleId,
    required String title,
    required String body,
    required DateTime scheduledDate,
    int minutesBefore = 0,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'kids_calendar_channel',
      '日程提醒',
      channelDescription: '亲子时光日程提醒通知',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      actions: const <AndroidNotificationAction>[],
    );
    final details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );

    // 计算提醒时间
    final alarmTime = scheduledDate.subtract(Duration(minutes: minutesBefore));
    final now = DateTime.now();

    if (alarmTime.isBefore(now)) return;

    // 转换为 TZDateTime (使用本地时区)
    final location = tz.local;
    final tzAlarmTime = tz.TZDateTime.from(alarmTime, location);

    await _plugin.zonedSchedule(
      _baseId + scheduleId,
      title,
      body,
      tzAlarmTime,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: scheduleId.toString(),
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// 取消通知
  Future<void> cancelNotification(int scheduleId) async {
    await _plugin.cancel(_baseId + scheduleId);
  }

  /// 取消所有通知
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
