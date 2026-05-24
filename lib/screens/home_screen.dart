import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/schedule_provider.dart';
import '../widgets/dual_calendar.dart';
import '../widgets/timeline_list.dart';
import '../utils/date_utils.dart' as date_utils;
import '../utils/constants.dart';
import 'schedule_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final provider = context.read<ScheduleProvider>();
    provider.selectDate(DateTime.now());
    provider.loadAllDates();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text(
              '亲子时光',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Consumer<ScheduleProvider>(
              builder: (context, provider, _) {
                final friendly = date_utils.DateUtils.friendlyDate(
                  date_utils.DateUtils.formatDate(provider.selectedDate),
                );
                return Text(
                  friendly,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                );
              },
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearch(context),
          ),
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              context.read<ScheduleProvider>().selectDate(DateTime.now());
            },
          ),
        ],
      ),
      body: Consumer<ScheduleProvider>(
        builder: (context, provider, _) {
          return RefreshIndicator(
            onRefresh: () async {
              await provider.selectDate(provider.selectedDate);
              await provider.loadAllDates();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  // 双历组件
                  const DualCalendar(),
                  const SizedBox(height: 12),
                  // 日期标题
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 16,
                          color: AppConstants.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          date_utils.DateUtils.detailDate(
                            date_utils.DateUtils.formatDate(provider.selectedDate),
                          ),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppConstants.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${provider.currentSchedules.length}个日程',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppConstants.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 时间轴列表
                  if (provider.isLoading)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    TimelineList(
                      schedules: provider.currentSchedules,
                      selectedDate: provider.selectedDate,
                    ),
                  const SizedBox(height: 80), // FAB 空间
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ScheduleFormScreen(),
            ),
          );
          if (result == true) {
            // 数据已通过 Provider 自动刷新
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showSearch(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('搜索日程'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '输入标题或描述...',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (controller.text.isNotEmpty) {
                _showSearchResults(controller.text);
              }
            },
            child: const Text('搜索'),
          ),
        ],
      ),
    );
  }

  void _showSearchResults(String keyword) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return FutureBuilder(
          future: context.read<ScheduleProvider>().searchSchedules(keyword),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final results = snapshot.data!;
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.3,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        '搜索 "${keyword}" 共 ${results.length} 条结果',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          final schedule = results[index];
                          return ListTile(
                            leading: Container(
                              width: 4,
                              height: 40,
                              color: AppConstants.getCategoryColorByName(
                                  schedule.category),
                            ),
                            title: Text(schedule.title),
                            subtitle: Text(
                              '${schedule.date} ${schedule.startTime ?? ''}',
                            ),
                            onTap: () {
                              final date = DateTime.tryParse(schedule.date);
                              if (date != null) {
                                context
                                    .read<ScheduleProvider>()
                                    .selectDate(date);
                              }
                              Navigator.pop(ctx);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
