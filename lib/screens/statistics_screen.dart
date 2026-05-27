import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/schedule_provider.dart';
import '../utils/constants.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  late int _year;

  @override
  void initState() {
    super.initState();
    _year = DateTime.now().year;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('统计')),
      body: Column(
        children: [
          // 年份切换
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => setState(() => _year--),
                ),
                Text(
                  '$_year年',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => setState(() => _year++),
                ),
              ],
            ),
          ),
          // 图例
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendItem(AppConstants.primaryColor, '总日程数'),
              const SizedBox(width: 24),
              _legendItem(Colors.green, '已打卡数'),
            ],
          ),
          const SizedBox(height: 8),
          // 图表
          Expanded(
            child: FutureBuilder<Map<int, Map<String, int>>>(
              future: context
                  .read<ScheduleProvider>()
                  .getMonthlyStats(_year),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final stats = snapshot.data!;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 24, 16),
                  child: _BarChart(
                    stats: stats,
                    year: _year,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}

class _BarChart extends StatelessWidget {
  final Map<int, Map<String, int>> stats;
  final int year;

  const _BarChart({required this.stats, required this.year});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _BarChartPainter(stats: stats),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final Map<int, Map<String, int>> stats;

  _BarChartPainter({required this.stats});

  @override
  void paint(Canvas canvas, Size size) {
    final maxVal = stats.values
        .map((m) => (m['total'] ?? 0).toDouble())
        .reduce((a, b) => a > b ? a : b);
    final yMax = maxVal > 0 ? maxVal * 1.2 : 10.0; // 留20%顶部空间

    final leftMargin = 36.0;
    final topMargin = 8.0;
    final rightMargin = 8.0;
    final bottomMargin = 28.0;
    final chartWidth = size.width - leftMargin - rightMargin;
    final chartHeight = size.height - topMargin - bottomMargin;

    // 横轴基线
    final baseY = size.height - bottomMargin;
    canvas.drawLine(
      Offset(leftMargin, baseY),
      Offset(size.width - rightMargin, baseY),
      Paint()
        ..color = Colors.grey.shade300
        ..strokeWidth = 1,
    );

    // 纵轴刻度线
    final gridCount = 4;
    for (int i = 1; i <= gridCount; i++) {
      final y = baseY - chartHeight * i / gridCount;
      canvas.drawLine(
        Offset(leftMargin, y),
        Offset(size.width - rightMargin, y),
        Paint()
          ..color = Colors.grey.shade100
          ..strokeWidth = 0.5,
      );
      // 刻度标签
      final val = (yMax * i / gridCount).round();
      final tp = TextPainter(
        text: TextSpan(
          text: val.toString(),
          style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: leftMargin - 4);
      tp.paint(canvas, Offset(leftMargin - tp.width - 4, y - tp.height / 2));
    }

    // 每组柱状图宽度
    final barGroupWidth = chartWidth / 12;
    final barWidth = barGroupWidth * 0.3;
    final gap = barGroupWidth * 0.1;

    for (int m = 1; m <= 12; m++) {
      final total = (stats[m]?['total'] ?? 0).toDouble();
      final completed = (stats[m]?['completed'] ?? 0).toDouble();

      final x = leftMargin + (m - 1) * barGroupWidth + barGroupWidth * 0.15;

      // 总日程柱 (蓝色)
      if (total > 0) {
        final barH = chartHeight * total / yMax;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, baseY - barH, barWidth, barH),
            const Radius.circular(3),
          ),
          Paint()..color = AppConstants.primaryColor.withOpacity(0.7),
        );
      }

      // 已打卡柱 (绿色)
      if (completed > 0) {
        final barH = chartHeight * completed / yMax;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
                x + barWidth + gap, baseY - barH, barWidth, barH),
            const Radius.circular(3),
          ),
          Paint()..color = Colors.green.withOpacity(0.7),
        );
      }

      // 月份标签
      final tp = TextPainter(
        text: TextSpan(
          text: '${m}月',
          style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: barGroupWidth);
      tp.paint(
        canvas,
        Offset(x + barWidth / 2 - tp.width / 2, baseY + 4),
      );

      // 数值标签（柱顶）
      if (total > 0) {
        final totalH = chartHeight * total / yMax;
        final totalTp = TextPainter(
          text: TextSpan(
            text: total.toInt().toString(),
            style: TextStyle(fontSize: 8, color: AppConstants.primaryColor),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        totalTp.paint(
          canvas,
          Offset(x + barWidth / 2 - totalTp.width / 2, baseY - totalH - totalTp.height - 1),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) => true;
}
