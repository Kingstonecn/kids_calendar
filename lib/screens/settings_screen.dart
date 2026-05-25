import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../utils/app_themes.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _weekdayOptions = [
    {'value': 0, 'label': '周日'},
    {'value': 1, 'label': '周一'},
    {'value': 6, 'label': '周六'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 主题选择
          const Text(
            '主题选择',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            '选择你喜欢的界面风格，切换后立即生效',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return DropdownButtonFormField<int>(
                value: themeProvider.selectedThemeIndex,
                decoration: const InputDecoration(
                  labelText: '主题',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.palette),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                isExpanded: true,
                items: List.generate(AppThemes.infos.length, (index) {
                  final info = AppThemes.infos[index];
                  return DropdownMenuItem(
                    value: index,
                    child: Row(
                      children: [
                        ...info.swatches.take(3).map((c) => Container(
                              width: 14,
                              height: 14,
                              margin: const EdgeInsets.only(right: 3),
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                              ),
                            )),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${info.name}  —  ${info.description}',
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                onChanged: (value) {
                  if (value != null) themeProvider.setTheme(value);
                },
              );
            },
          ),
          const SizedBox(height: 24),
          // 周起始日
          const Text(
            '日历设置',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            '设置日历每周的第一天',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return DropdownButtonFormField<int>(
                value: themeProvider.firstDayOfWeek,
                decoration: const InputDecoration(
                  labelText: '每周起始日',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_view_week),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                items: _weekdayOptions.map((opt) {
                  return DropdownMenuItem(
                    value: opt['value'] as int,
                    child: Text(opt['label'] as String),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) themeProvider.setFirstDayOfWeek(value);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
