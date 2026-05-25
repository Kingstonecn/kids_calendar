import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/schedule_provider.dart';
import '../widgets/dual_calendar.dart';
import '../widgets/day_view.dart';
import '../utils/constants.dart';
import 'schedule_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _viewMode = 0; // 0=月, 1=日

  static const _modeLabels = ['月', '日'];
  static const _modeIcons = [
    Icons.calendar_view_month,
    Icons.calendar_view_day,
  ];

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

  void _switchMode() {
    setState(() {
      _viewMode = (_viewMode + 1) % 2;
    });
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _viewMode = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '亲子时光',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          SizedBox(
            width: 48,
            child: GestureDetector(
              onTap: _switchMode,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_modeIcons[_viewMode], size: 22),
                  Text(_modeLabels[_viewMode],
                      style: const TextStyle(fontSize: 10)),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 48,
            child: GestureDetector(
              onTap: () => _showSearch(context),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, size: 22),
                  Text('搜索', style: TextStyle(fontSize: 10)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Consumer<ScheduleProvider>(
        builder: (context, provider, _) {
          switch (_viewMode) {
            case 0:
              return RefreshIndicator(
                onRefresh: () async {
                  await provider.loadAllDates();
                  await provider.loadDatesForMonth(
                    DateTime.now().year,
                    DateTime.now().month,
                  );
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      DualCalendar(onDateSelected: _onDateSelected),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              );
            case 1:
              return const DayView();
            default:
              return const SizedBox.shrink();
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final selectedDate = context.read<ScheduleProvider>().selectedDate;
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ScheduleFormScreen(initialDate: selectedDate),
            ),
          );
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
                        '搜索 "$keyword" 共 ${results.length} 条结果',
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
