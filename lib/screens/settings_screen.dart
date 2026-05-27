import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/schedule_provider.dart';
import '../services/data_io_service.dart';
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
                  prefixIcon: Icon(Icons.date_range),
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
          const SizedBox(height: 24),
          // 农历显示模式
          const Text(
            '农历显示',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            '选择日历中的农历和节日显示方式',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return DropdownButtonFormField<int>(
                value: themeProvider.lunarDisplayMode,
                decoration: const InputDecoration(
                  labelText: '显示模式',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_view_month),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 0,
                    child: Text('显示节日和农历'),
                  ),
                  DropdownMenuItem(
                    value: 1,
                    child: Text('仅显示农历'),
                  ),
                  DropdownMenuItem(
                    value: 2,
                    child: Text('不显示节日和农历'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) themeProvider.setLunarDisplayMode(value);
                },
              );
            },
          ),
          const SizedBox(height: 24),
          // 数据导入导出
          const Text(
            '数据管理',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            '导出日程备份或从备份中恢复',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          _buildExportImportSection(context),
        ],
      ),
    );
  }

  Widget _buildExportImportSection(BuildContext context) {
    return Column(
      children: [
        // 导出
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _doExport(context, 'csv'),
                icon: const Icon(Icons.table_chart, size: 18),
                label: const Text('导出 CSV'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _doExport(context, 'json'),
                icon: const Icon(Icons.code, size: 18),
                label: const Text('导出 JSON'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 导入
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _doImport(context, 'csv'),
                icon: const Icon(Icons.file_open, size: 18),
                label: const Text('导入 CSV'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _doImport(context, 'json'),
                icon: const Icon(Icons.file_open, size: 18),
                label: const Text('导入 JSON'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _doExport(BuildContext context, String format) async {
    final service = DataIoService();
    try {
      if (format == 'csv') {
        await service.exportCsv(context);
      } else {
        await service.exportJson(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    }
  }

  Future<void> _doImport(BuildContext context, String format) async {
    final service = DataIoService();
    try {
      final count = format == 'csv'
          ? await service.importCsv(context)
          : await service.importJson(context);

      if (!context.mounted) return;

      if (count > 0) {
        // 刷新数据
        context.read<ScheduleProvider>().loadAllDates();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('成功导入 $count 个日程')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('未找到有效的日程数据')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e')),
        );
      }
    }
  }
}
