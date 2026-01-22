import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/models/daily_data.dart';
import '../../core/utils/dates.dart';
import '../../widgets/heatmap_calendar.dart';
import '../today/daily_controller.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  late DateTime _month;
  Future<Map<String, DailyData>>? _monthFuture;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month, 1);
    _monthFuture = _loadMonth(_month);
  }

  Future<Map<String, DailyData>> _loadMonth(DateTime month) async {
    final repo = ref.read(dailyRepositoryProvider);

    final nextMonth = DateTime(month.year, month.month + 1, 1);
    final daysInMonth = nextMonth.subtract(const Duration(days: 1)).day;

    final result = <String, DailyData>{};

    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      final data = await repo.loadExisting(date);
      if (data != null) {
        result[data.dateYmd] = data;
      }
    }

    return result;
  }

  int _levelFor(Map<String, DailyData> map, DateTime day) {
    final key = ymd(day);
    final data = map[key];
    if (data == null) return 0;

    final ratio = data.completionRatio;
    if (ratio >= 0.80) return 3;
    if (ratio >= 0.55) return 2;
    if (ratio >= 0.25) return 1;
    return 0;
  }

  void _prevMonth() {
    setState(() {
      _month = DateTime(_month.year, _month.month - 1, 1);
      _monthFuture = _loadMonth(_month);
    });
  }

  void _nextMonth() {
    setState(() {
      _month = DateTime(_month.year, _month.month + 1, 1);
      _monthFuture = _loadMonth(_month);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('日曆')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: '上個月',
                      onPressed: _prevMonth,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: Text(
                        '${_month.year} 年 ${_month.month} 月',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: '下個月',
                      onPressed: _nextMonth,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FutureBuilder<Map<String, DailyData>>(
                  future: _monthFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final data = snapshot.data ?? const <String, DailyData>{};

                    return HeatmapCalendar(
                      month: _month,
                      levelForDay: (day) => _levelFor(data, day),
                      onTapDay: (day) {
                        ref.read(selectedDateProvider.notifier).state =
                            dateOnly(day);
                        ref.read(navIndexProvider.notifier).state = 0;

                        final key = ymd(day);
                        final d = data[key];
                        final percent = d == null
                            ? 0
                            : (d.completionRatio * 100).round();

                        ScaffoldMessenger.of(context)
                          ..clearSnackBars()
                          ..showSnackBar(
                            SnackBar(content: Text('$key 完成度 $percent%')),
                          );
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  '顏色越深代表完成度越高（讀取本地 Hive 真資料）。',
                  style: TextStyle(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
