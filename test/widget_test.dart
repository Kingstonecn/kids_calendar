import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:kids_calendar/app.dart';
import 'package:kids_calendar/providers/schedule_provider.dart';

void main() {
  testWidgets('App should display title and calendar', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ScheduleProvider()),
        ],
        child: const KidsCalendarApp(),
      ),
    );

    // 验证 App 标题
    expect(find.text('亲子时光'), findsOneWidget);

    // 验证日历头部 (当前月份)
    final now = DateTime.now();
    expect(find.text('${now.year}年${now.month}月'), findsOneWidget);

    // 验证星期标签
    expect(find.text('日'), findsOneWidget);
    expect(find.text('六'), findsOneWidget);

    // 验证 FAB (新增按钮)
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
