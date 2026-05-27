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
  Map<int, Map<String, int>> _monthlyStats = {};
  Map<String, int> _categoryStats = {};
  List<int> _availableYears = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _year = DateTime.now().year;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
    context.read<ScheduleProvider>().addListener(_onDataChanged);
  }

  @override
  void dispose() {
    context.read<ScheduleProvider>().removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    _loadData();
  }

  Future<void> _loadData() async {
    final provider = context.read<ScheduleProvider>();
    final years = await provider.getYearsWithSchedules();
    if (!mounted) return;
    if (years.isNotEmpty && !years.contains(_year)) {
      _year = years.last;
    }
    _availableYears = years;
    _monthlyStats = await provider.getMonthlyStats(_year);
    _categoryStats = await provider.getCategoryStats(_year);
    if (mounted) setState(() => _loading = false);
  }

  void _prevYear() {
    final idx = _availableYears.indexOf(_year);
    if (idx > 0) {
      setState(() => _loading = true);
      _year = _availableYears[idx - 1];
      _loadData();
    }
  }

  void _nextYear() {
    final idx = _availableYears.indexOf(_year);
    if (idx < _availableYears.length - 1) {
      setState(() => _loading = true);
      _year = _availableYears[idx + 1];
      _loadData();
    }
  }

  bool get _hasPrevYear => _availableYears.isNotEmpty && _availableYears.first < _year;
  bool get _hasNextYear => _availableYears.isNotEmpty && _availableYears.last > _year;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('统计')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 年份切换
                  _buildYearSelector(),
                  const SizedBox(height: 16),
                  // 月度走势
                  const Text(
                    '月度走势',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _legendDot(AppConstants.primaryColor, '总日程数'),
                      const SizedBox(width: 16),
                      _legendDot(Colors.green, '已打卡数'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 220,
                    child: _MonthlyChart(stats: _monthlyStats),
                  ),
                  const SizedBox(height: 24),
                  // 分类分布
                  const Text(
                    '分类分布',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: AppConstants.categories.length * 36.0 + 20,
                    child: _CategoryChart(stats: _categoryStats),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildYearSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: _hasPrevYear ? _prevYear : null,
        ),
        Text(
          '$_year年',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: _hasNextYear ? _nextYear : null,
        ),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

/// 月度柱状图
class _MonthlyChart extends StatelessWidget {
  final Map<int, Map<String, int>> stats;
  const _MonthlyChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, double.infinity),
      painter: _MonthlyChartPainter(stats: stats),
    );
  }
}

class _MonthlyChartPainter extends CustomPainter {
  final Map<int, Map<String, int>> stats;
  _MonthlyChartPainter({required this.stats});

  @override
  void paint(Canvas canvas, Size size) {
    final maxVal = stats.values
        .map((m) => (m['total'] ?? 0).toDouble())
        .reduce((a, b) => a > b ? a : b);
    final yMax = maxVal > 0 ? maxVal * 1.2 : 10.0;

    const leftMargin = 36.0;
    const topMargin = 8.0;
    const rightMargin = 8.0;
    const bottomMargin = 28.0;
    final chartWidth = size.width - leftMargin - rightMargin;
    final chartHeight = size.height - topMargin - bottomMargin;
    final baseY = size.height - bottomMargin;

    // 横轴基线
    canvas.drawLine(
      Offset(leftMargin, baseY),
      Offset(size.width - rightMargin, baseY),
      Paint()..color = Colors.grey.shade300..strokeWidth = 1,
    );

    // 纵轴刻度
    const gridCount = 4;
    for (int i = 1; i <= gridCount; i++) {
      final y = baseY - chartHeight * i / gridCount;
      canvas.drawLine(
        Offset(leftMargin, y),
        Offset(size.width - rightMargin, y),
        Paint()..color = Colors.grey.shade100..strokeWidth = 0.5,
      );
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

    final barGroupWidth = chartWidth / 12;
    final barWidth = barGroupWidth * 0.3;
    const gap = 4.0;

    for (int m = 1; m <= 12; m++) {
      final total = (stats[m]?['total'] ?? 0).toDouble();
      final completed = (stats[m]?['completed'] ?? 0).toDouble();
      final x = leftMargin + (m - 1) * barGroupWidth + barGroupWidth * 0.15;

      if (total > 0) {
        final barH = chartHeight * total / yMax;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, baseY - barH, barWidth, barH),
            const Radius.circular(3),
          ),
          Paint()..color = AppConstants.primaryColor.withValues(alpha: 0.7),
        );
      }
      if (completed > 0) {
        final barH = chartHeight * completed / yMax;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x + barWidth + gap, baseY - barH, barWidth, barH),
            const Radius.circular(3),
          ),
          Paint()..color = Colors.green.withValues(alpha: 0.7),
        );
      }

      final tp = TextPainter(
        text: TextSpan(
          text: '${m}月',
          style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: barGroupWidth);
      tp.paint(canvas, Offset(x + barWidth / 2 - tp.width / 2, baseY + 4));

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
  bool shouldRepaint(covariant _MonthlyChartPainter oldDelegate) => true;
}

/// 分类分布图（横向柱状）
class _CategoryChart extends StatelessWidget {
  final Map<String, int> stats;
  const _CategoryChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, double.infinity),
      painter: _CategoryChartPainter(stats: stats),
    );
  }
}

class _CategoryChartPainter extends CustomPainter {
  final Map<String, int> stats;
  _CategoryChartPainter({required this.stats});

  @override
  void paint(Canvas canvas, Size size) {
    final categories = AppConstants.categories.toList()
      ..sort((a, b) => (stats[b] ?? 0).compareTo(stats[a] ?? 0));
    final maxVal = stats.values.fold<int>(0, (a, b) => a > b ? a : b);
    final xMax = maxVal > 0 ? maxVal * 1.3 : 5.0;

    const labelWidth = 50.0;
    const barHeight = 24.0;
    const rowGap = 12.0;
    const leftMargin = labelWidth + 8;
    final rightMargin = 40.0;
    final chartWidth = size.width - leftMargin - rightMargin;

    int i = 0;
    for (final cat in categories) {
      final count = stats[cat] ?? 0;
      final y = i * (barHeight + rowGap) + 4;
      final color = AppConstants.getCategoryColorByName(cat);

      // 分类名
      final labelTp = TextPainter(
        text: TextSpan(
          text: cat,
          style: const TextStyle(fontSize: 11, color: Colors.black87),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: labelWidth);
      labelTp.paint(canvas, Offset(labelWidth - labelTp.width, y + (barHeight - labelTp.height) / 2));

      // 数量柱
      if (count > 0) {
        final barW = chartWidth * (count / xMax);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(leftMargin, y, barW, barHeight),
            const Radius.circular(4),
          ),
          Paint()..color = color.withValues(alpha: 0.7),
        );

        // 数值
        final valTp = TextPainter(
          text: TextSpan(
            text: count.toString(),
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        valTp.paint(canvas, Offset(leftMargin + barW + 6, y + (barHeight - valTp.height) / 2));
      } else {
        // 0 值显示灰色
        final valTp = TextPainter(
          text: const TextSpan(
            text: '0',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        valTp.paint(canvas, Offset(leftMargin, y + (barHeight - valTp.height) / 2));
      }

      i++;
    }
  }

  @override
  bool shouldRepaint(covariant _CategoryChartPainter oldDelegate) => true;
}
