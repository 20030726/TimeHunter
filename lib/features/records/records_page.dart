import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/constants/timer_constants.dart';
import '../../core/models/daily_data.dart';
import '../../core/models/task_item.dart';
import '../../core/models/task_tag.dart';
import '../../core/models/timebox_entry.dart';
import '../../core/utils/dates.dart';
import '../tasks/add_task_dialog.dart';
import '../today/daily_controller.dart';

const double _minuteHeight = 1.1;
const double _hourLabelWidth = 52;
const double _dayColumnWidth = 140;
const int _minTimeboxMinutes = TimerConstants.minTimeboxMinutes;

class RecordsPage extends ConsumerStatefulWidget {
  const RecordsPage({super.key});

  @override
  ConsumerState<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends ConsumerState<RecordsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_handleTabChange)
      ..dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (mounted) setState(() {});
  }

  void _jumpToDay(DateTime date) {
    ref.read(selectedDateProvider.notifier).state = dateOnly(date);
    _tabController.animateTo(0);
  }

  TimeOfDay _defaultStartTime(DateTime date) {
    final now = DateTime.now();
    if (now.year != date.year || now.month != date.month || now.day != date.day) {
      return const TimeOfDay(hour: 9, minute: 0);
    }

    final minutes = now.hour * 60 + now.minute;
    final rounded = ((minutes + 14) ~/ 15) * 15;
    final hour = (rounded ~/ 60) % 24;
    final minute = rounded % 60;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> _showAddTimeboxDialog(
    BuildContext context,
    DailyData daily,
    DateTime date,
  ) async {
    if (daily.tasks.isEmpty) {
      final goAdd = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('沒有任務'),
            content: const Text('先新增任務，才能排程 Timebox。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('新增任務'),
              ),
            ],
          );
        },
      );

      if (goAdd == true && context.mounted) {
        await showAddTaskDialog(context: context);
      }
      return;
    }

    var selectedTask = daily.tasks.first;
    var startTime = _defaultStartTime(date);
    var durationMinutes = selectedTask.cycleMinutes;
    final durationOptions = TimerConstants.timeboxDurationOptions;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('新增 Timebox'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<TaskItem>(
                    initialValue: selectedTask,
                    decoration: const InputDecoration(labelText: '任務'),
                    items: daily.tasks
                        .map(
                          (task) => DropdownMenuItem(
                            value: task,
                            child: Text(task.title),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (task) {
                      if (task == null) return;
                      setState(() {
                        selectedTask = task;
                        durationMinutes = task.cycleMinutes;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('開始時間'),
                    trailing: Text(
                      startTime.format(context),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: startTime,
                      );
                      if (picked == null) return;
                      setState(() => startTime = picked);
                    },
                  ),
                  DropdownButtonFormField<int>(
                    initialValue: durationOptions.contains(durationMinutes)
                        ? durationMinutes
                        : durationOptions.first,
                    decoration: const InputDecoration(labelText: '時長'),
                    items: durationOptions
                        .map(
                          (minutes) => DropdownMenuItem(
                            value: minutes,
                            child: Text('$minutes 分鐘'),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => durationMinutes = value);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () async {
                    final start = DateTime(
                      date.year,
                      date.month,
                      date.day,
                      startTime.hour,
                      startTime.minute,
                    );
                    var end = start.add(
                      Duration(minutes: durationMinutes),
                    );
                    if (end.day != start.day) {
                      end = DateTime(
                        start.year,
                        start.month,
                        start.day,
                        23,
                        59,
                      );
                    }

                    await ref
                        .read(dailyControllerProvider.notifier)
                        .addPlannedTimebox(
                          task: selectedTask,
                          startedAt: start,
                          endedAt: end,
                        );

                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: const Text('新增'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dailyAsync = ref.watch(dailyControllerProvider);
    final date = ref.watch(selectedDateProvider);

    Widget? fab;
    if (_tabController.index == 0) {
      fab = dailyAsync.when<Widget?>(
        loading: () => FloatingActionButton.extended(
          onPressed: null,
          icon: const Icon(Icons.add),
          label: const Text('新增 Timebox'),
        ),
        error: (_, _) => null,
        data: (daily) => FloatingActionButton.extended(
          onPressed: () => _showAddTimeboxDialog(context, daily, date),
          icon: const Icon(Icons.add),
          label: const Text('新增 Timebox'),
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.black,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('紀錄'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '日'),
            Tab(text: '週'),
            Tab(text: '月'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const _RecordsDayView(),
          _RecordsWeekView(onSelectDay: _jumpToDay),
          _RecordsMonthView(onSelectDay: _jumpToDay),
        ],
      ),
      floatingActionButton: fab,
    );
  }
}

class _RecordsDayView extends ConsumerWidget {
  const _RecordsDayView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(selectedDateProvider);
    final dailyAsync = ref.watch(dailyControllerProvider);

    return dailyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (daily) {
        final dayStart = DateTime(date.year, date.month, date.day);
        final dayEnd = dayStart.add(const Duration(days: 1));
        final entries = daily.timeboxes
            .where((entry) {
              final start =
                  DateTime.fromMillisecondsSinceEpoch(entry.startEpochMs);
              final end =
                  DateTime.fromMillisecondsSinceEpoch(entry.endEpochMs);
              return start.isBefore(dayEnd) && end.isAfter(dayStart);
            })
            .toList(growable: false)
          ..sort((a, b) => a.startEpochMs.compareTo(b.startEpochMs));

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _DayHeader(
              date: date,
              onPrev: () {
                ref.read(selectedDateProvider.notifier).state = dateOnly(
                  date.subtract(const Duration(days: 1)),
                );
              },
              onNext: () {
                ref.read(selectedDateProvider.notifier).state = dateOnly(
                  date.add(const Duration(days: 1)),
                );
              },
            ),
            const SizedBox(height: 12),
            _DailySummaryCard(daily: daily),
            const SizedBox(height: 12),
            _TaskSummaryCard(tasks: daily.tasks),
            const SizedBox(height: 12),
            Text(
              'Timebox 時間表',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 520,
              child: TimeboxTimeline(
                date: date,
                entries: entries,
                onUpdate: (entry) {
                  ref.read(dailyControllerProvider.notifier).updateTimebox(entry);
                },
              ),
            ),
            const SizedBox(height: 12),
            _TimeboxSummaryCard(entries: entries),
          ],
        );
      },
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({
    required this.date,
    required this.onPrev,
    required this.onNext,
  });

  final DateTime date;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final label = ymd(date);
    return Row(
      children: [
        IconButton(
          tooltip: '前一天',
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        IconButton(
          tooltip: '後一天',
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _DailySummaryCard extends StatelessWidget {
  const _DailySummaryCard({required this.daily});

  final DailyData daily;

  int _targetMinutes() {
    var minutes = 0;
    for (final task in daily.tasks) {
      minutes += task.totalCycles * task.cycleMinutes;
    }
    return minutes;
  }

  int _completedMinutes() {
    var minutes = 0;
    for (final task in daily.tasks) {
      minutes += task.completedCycles * task.cycleMinutes;
    }
    return minutes;
  }

  @override
  Widget build(BuildContext context) {
    final totalCycles = daily.totalCycles;
    final completedCycles = daily.completedCycles;
    final ratio = totalCycles <= 0 ? 0.0 : completedCycles / totalCycles;
    final targetMinutes = _targetMinutes();
    final completedMinutes = _completedMinutes();
    final plannedCount = daily.timeboxes.where((e) => e.isPlanned).length;
    final completedCount = daily.timeboxes.length - plannedCount;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  '今日進度',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  '${daily.slackRemaining} 張偷懶券',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: ratio),
            const SizedBox(height: 12),
            Text(
              '$completedCycles / $totalCycles 輪',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              '$completedMinutes / $targetMinutes 分鐘',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Timebox $completedCount 完成 / $plannedCount 計畫',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskSummaryCard extends StatelessWidget {
  const _TaskSummaryCard({required this.tasks});

  final List<TaskItem> tasks;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '任務總覽',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (tasks.isEmpty)
              Text(
                '今天沒有任務。',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              ListView.separated(
                itemCount: tasks.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  final ratio = task.totalCycles <= 0
                      ? 0.0
                      : task.completedCycles / task.totalCycles;
                  return _TaskSummaryRow(task: task, ratio: ratio);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _TaskSummaryRow extends StatelessWidget {
  const _TaskSummaryRow({
    required this.task,
    required this.ratio,
  });

  final TaskItem task;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    final tagColor = Color(task.tag.colorValue);
    final minutes = task.totalCycles * task.cycleMinutes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: tagColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                task.title,
                style: Theme.of(context).textTheme.bodyLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${task.completedCycles}/${task.totalCycles}',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: ratio,
          minHeight: 6,
          backgroundColor: AppColors.divider,
          valueColor: AlwaysStoppedAnimation<Color>(tagColor),
        ),
        const SizedBox(height: 6),
        Text(
          '$minutes 分鐘',
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ],
    );
  }
}

class _TimeboxSummaryCard extends ConsumerWidget {
  const _TimeboxSummaryCard({required this.entries});

  final List<TimeboxEntry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Timebox 紀錄',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (entries.isEmpty)
              Text(
                '尚未有 Timebox 紀錄，完成一輪或新增排程即可出現。',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              ListView.separated(
                itemCount: entries.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return _TimeboxRow(
                    entry: entry,
                    onDelete: () {
                      ref
                          .read(dailyControllerProvider.notifier)
                          .removeTimebox(entry.id);
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _TimeboxRow extends StatelessWidget {
  const _TimeboxRow({required this.entry, required this.onDelete});

  final TimeboxEntry entry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final start = DateTime.fromMillisecondsSinceEpoch(entry.startEpochMs);
    final end = DateTime.fromMillisecondsSinceEpoch(entry.endEpochMs);
    final time =
        '${DateFormat('HH:mm').format(start)} - ${DateFormat('HH:mm').format(end)}';
    final minutes = entry.duration.inMinutes.abs();
    final color = Color(entry.tag.colorValue);

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.taskTitle,
                      style: Theme.of(context).textTheme.bodyLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _TimeboxStatusChip(isPlanned: entry.isPlanned),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '$time ・ $minutes 分鐘',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        ),
        PopupMenuButton<String>(
          onSelected: (_) => onDelete(),
          itemBuilder: (context) {
            return const [
              PopupMenuItem<String>(
                value: 'delete',
                child: Text('刪除'),
              ),
            ];
          },
        ),
      ],
    );
  }
}

class _TimeboxStatusChip extends StatelessWidget {
  const _TimeboxStatusChip({required this.isPlanned});

  final bool isPlanned;

  @override
  Widget build(BuildContext context) {
    final color = isPlanned ? const Color(0xFFF59E0B) : AppColors.accent;
    final label = isPlanned ? '計畫' : '完成';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class TimeboxTimeline extends StatefulWidget {
  const TimeboxTimeline({
    super.key,
    required this.date,
    required this.entries,
    required this.onUpdate,
  });

  final DateTime date;
  final List<TimeboxEntry> entries;
  final ValueChanged<TimeboxEntry> onUpdate;

  @override
  State<TimeboxTimeline> createState() => _TimeboxTimelineState();
}

class _TimeboxTimelineState extends State<TimeboxTimeline> {
  final ScrollController _scrollController = ScrollController();
  String? _draggingId;
  int? _draggingStartMinutes;
  String? _resizingId;
  int? _resizingEndMinutes;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  int _minutesFromEpoch(int epochMs) {
    final dayStart = DateTime(widget.date.year, widget.date.month, widget.date.day)
        .millisecondsSinceEpoch;
    return ((epochMs - dayStart) / 60000).round();
  }

  int _clampMinutes(int minutes) {
    if (minutes < 0) return 0;
    if (minutes > 24 * 60) return 24 * 60;
    return minutes;
  }

  void _startDrag(TimeboxEntry entry) {
    setState(() {
      _draggingId = entry.id;
      _draggingStartMinutes = _minutesFromEpoch(entry.startEpochMs);
      _resizingId = null;
      _resizingEndMinutes = null;
    });
  }

  void _updateDrag(TimeboxEntry entry, DragUpdateDetails details) {
    final base = _draggingStartMinutes ?? _minutesFromEpoch(entry.startEpochMs);
    final rawDuration =
        (entry.endEpochMs - entry.startEpochMs).abs() ~/ 60000;
    final safeDuration =
        rawDuration < _minTimeboxMinutes ? _minTimeboxMinutes : rawDuration;
    final maxStart = (24 * 60) - safeDuration;
    final delta = (details.delta.dy / _minuteHeight).round();
    setState(() {
      _draggingStartMinutes = (base + delta).clamp(0, maxStart).toInt();
    });
  }

  void _endDrag(TimeboxEntry entry) {
    final duration =
        (entry.endEpochMs - entry.startEpochMs).abs() ~/ 60000;
    final safeDuration = duration < _minTimeboxMinutes
        ? _minTimeboxMinutes
        : duration;
    final maxStart = (24 * 60) - safeDuration;
    final nextStart = (_draggingStartMinutes ??
            _minutesFromEpoch(entry.startEpochMs))
        .clamp(0, maxStart)
        .toInt();
    final nextEnd = _clampMinutes(nextStart + safeDuration)
        .clamp(nextStart + _minTimeboxMinutes, 24 * 60)
        .toInt();
    _commitUpdate(entry, nextStart, nextEnd);
    setState(() {
      _draggingId = null;
      _draggingStartMinutes = null;
    });
  }

  void _startResize(TimeboxEntry entry) {
    setState(() {
      _resizingId = entry.id;
      _resizingEndMinutes = _minutesFromEpoch(entry.endEpochMs);
      _draggingId = null;
      _draggingStartMinutes = null;
    });
  }

  void _updateResize(TimeboxEntry entry, DragUpdateDetails details) {
    final base = _resizingEndMinutes ?? _minutesFromEpoch(entry.endEpochMs);
    final delta = (details.delta.dy / _minuteHeight).round();
    final startMinutes = _minutesFromEpoch(entry.startEpochMs);
    final minEnd = startMinutes + _minTimeboxMinutes;
    setState(() {
      _resizingEndMinutes = _clampMinutes(base + delta)
          .clamp(minEnd, 24 * 60)
          .toInt();
    });
  }

  void _endResize(TimeboxEntry entry) {
    final startMinutes = _minutesFromEpoch(entry.startEpochMs);
    final nextEnd = _resizingEndMinutes ?? _minutesFromEpoch(entry.endEpochMs);
    if (nextEnd > startMinutes) {
      _commitUpdate(entry, startMinutes, nextEnd);
    }
    setState(() {
      _resizingId = null;
      _resizingEndMinutes = null;
    });
  }

  void _commitUpdate(TimeboxEntry entry, int startMinutes, int endMinutes) {
    final dayStart = DateTime(widget.date.year, widget.date.month, widget.date.day);
    final start = dayStart.add(Duration(minutes: startMinutes));
    final end = dayStart.add(Duration(minutes: endMinutes));
    final updated = entry.copyWith(
      startEpochMs: start.millisecondsSinceEpoch,
      endEpochMs: end.millisecondsSinceEpoch,
      cycleMinutes: end.difference(start).inMinutes.abs(),
    );
    widget.onUpdate(updated);
  }

  @override
  Widget build(BuildContext context) {
    final hourHeight = _minuteHeight * 60;
    final dayHeight = hourHeight * 24;
    final dayStart = DateTime(widget.date.year, widget.date.month, widget.date.day);

    final isToday = dateOnly(DateTime.now()) == dateOnly(widget.date);
    final nowOffset = isToday
        ? DateTime.now().difference(dayStart).inMinutes * _minuteHeight
        : null;

    return Scrollbar(
      controller: _scrollController,
      child: SingleChildScrollView(
        controller: _scrollController,
        child: SizedBox(
          height: dayHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: _hourLabelWidth,
                child: Column(
                  children: List.generate(24, (index) {
                    final label = index.toString().padLeft(2, '0');
                    return SizedBox(
                      height: hourHeight,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Text(
                          '$label:00',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: Column(
                            children: List.generate(24, (index) {
                              return Container(
                                height: hourHeight,
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: AppColors.divider
                                          .withValues(alpha: 0.35),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        if (nowOffset != null)
                          Positioned(
                            top: nowOffset,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 2,
                              color: const Color(0xFFF43F5E),
                            ),
                          ),
                        ...widget.entries.map((entry) {
                          final startMinutes = _draggingId == entry.id
                              ? (_draggingStartMinutes ??
                                  _minutesFromEpoch(entry.startEpochMs))
                              : _minutesFromEpoch(entry.startEpochMs);
                          final endMinutes = _resizingId == entry.id
                              ? (_resizingEndMinutes ??
                                  _minutesFromEpoch(entry.endEpochMs))
                              : _minutesFromEpoch(entry.endEpochMs);
                          final safeStart = _clampMinutes(startMinutes);
                          final safeEnd = _clampMinutes(endMinutes);
                          final top = safeStart * _minuteHeight;
                          var height = (safeEnd - safeStart) * _minuteHeight;
                          if (height < _minTimeboxMinutes * _minuteHeight) {
                            height = _minTimeboxMinutes * _minuteHeight;
                          }
                          final color = Color(entry.tag.colorValue);
                          final isPlanned = entry.isPlanned;

                          return Positioned(
                            top: top,
                            left: 0,
                            right: 0,
                            child: GestureDetector(
                              onPanStart: (_) => _startDrag(entry),
                              onPanUpdate: (details) =>
                                  _updateDrag(entry, details),
                              onPanEnd: (_) => _endDrag(entry),
                              child: Container(
                                height: height,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isPlanned
                                      ? color.withValues(alpha: 0.15)
                                      : color.withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isPlanned
                                        ? color.withValues(alpha: 0.55)
                                        : color.withValues(alpha: 0.8),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.12),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: Align(
                                        alignment: Alignment.topLeft,
                                        child: Text(
                                          entry.taskTitle,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium
                                              ?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: GestureDetector(
                                        onPanStart: (_) => _startResize(entry),
                                        onPanUpdate: (details) =>
                                            _updateResize(entry, details),
                                        onPanEnd: (_) => _endResize(entry),
                                        child: Center(
                                          child: Container(
                                            width: 36,
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.white.withValues(alpha: 0.6),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecordsWeekView extends ConsumerStatefulWidget {
  const _RecordsWeekView({required this.onSelectDay});

  final ValueChanged<DateTime> onSelectDay;

  @override
  ConsumerState<_RecordsWeekView> createState() => _RecordsWeekViewState();
}

class _RecordsWeekViewState extends ConsumerState<_RecordsWeekView> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  DateTime _startOfWeek(DateTime date) {
    final normalized = dateOnly(date);
    final diff = normalized.weekday - DateTime.monday;
    return normalized.subtract(Duration(days: diff));
  }

  Future<Map<String, DailyData>> _loadWeek(
    WidgetRef ref,
    DateTime start,
  ) async {
    final repo = ref.read(dailyRepositoryProvider);
    final result = <String, DailyData>{};

    for (var i = 0; i < 7; i++) {
      final date = start.add(Duration(days: i));
      final data = await repo.loadExisting(date);
      if (data != null) {
        result[data.dateYmd] = data;
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final date = ref.watch(selectedDateProvider);
    final start = _startOfWeek(date);
    final end = start.add(const Duration(days: 6));
    final rangeLabel =
        '${DateFormat('MM/dd').format(start)} - ${DateFormat('MM/dd').format(end)}';

    return FutureBuilder<Map<String, DailyData>>(
      future: _loadWeek(ref, start),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data ?? const <String, DailyData>{};

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: '前一週',
                  onPressed: () {
                    ref.read(selectedDateProvider.notifier).state = dateOnly(
                      date.subtract(const Duration(days: 7)),
                    );
                  },
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    rangeLabel,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: '下一週',
                  onPressed: () {
                    ref.read(selectedDateProvider.notifier).state = dateOnly(
                      date.add(const Duration(days: 7)),
                    );
                  },
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const SizedBox(width: _hourLabelWidth + 8),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _horizontalController,
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(7, (index) {
                        final day = start.add(Duration(days: index));
                        final label = DateFormat('E\nMM/dd').format(day);
                        final isSelected = ymd(day) == ymd(date);
                        return SizedBox(
                          width: _dayColumnWidth,
                          child: GestureDetector(
                            onTap: () => widget.onSelectDay(day),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.accent.withValues(alpha: 0.15)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.accent
                                      : AppColors.divider,
                                ),
                              ),
                              child: Text(
                                label,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 520,
              child: WeekTimeline(
                weekStart: start,
                data: data,
                horizontalController: _horizontalController,
                verticalController: _verticalController,
              ),
            ),
          ],
        );
      },
    );
  }
}

class WeekTimeline extends StatefulWidget {
  const WeekTimeline({
    super.key,
    required this.weekStart,
    required this.data,
    required this.horizontalController,
    required this.verticalController,
  });

  final DateTime weekStart;
  final Map<String, DailyData> data;
  final ScrollController horizontalController;
  final ScrollController verticalController;

  @override
  State<WeekTimeline> createState() => _WeekTimelineState();
}

class _WeekTimelineState extends State<WeekTimeline> {
  @override
  Widget build(BuildContext context) {
    final hourHeight = _minuteHeight * 60;
    final dayHeight = hourHeight * 24;

    return Scrollbar(
      controller: widget.verticalController,
      child: SingleChildScrollView(
        controller: widget.verticalController,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: _hourLabelWidth,
              child: Column(
                children: List.generate(24, (index) {
                  return SizedBox(
                    height: hourHeight,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Text(
                        '${index.toString().padLeft(2, '0')}:00',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SingleChildScrollView(
                controller: widget.horizontalController,
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(7, (index) {
                    final day = widget.weekStart.add(Duration(days: index));
                    final key = ymd(day);
                    final entries = widget.data[key]?.timeboxes ?? const [];
                    return SizedBox(
                      width: _dayColumnWidth,
                      height: dayHeight,
                      child: _WeekDayColumn(
                        date: day,
                        entries: entries,
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekDayColumn extends StatelessWidget {
  const _WeekDayColumn({required this.date, required this.entries});

  final DateTime date;
  final List<TimeboxEntry> entries;

  int _minutesFromEpoch(int epochMs) {
    final dayStart = DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
    return ((epochMs - dayStart) / 60000).round();
  }

  @override
  Widget build(BuildContext context) {
    final hourHeight = _minuteHeight * 60;
    return Stack(
      children: [
        Positioned.fill(
          child: Column(
            children: List.generate(24, (index) {
              return Container(
                height: hourHeight,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: AppColors.divider.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        ...entries.map((entry) {
          final start = _minutesFromEpoch(entry.startEpochMs);
          final end = _minutesFromEpoch(entry.endEpochMs);
          final safeStart = start.clamp(0, 24 * 60);
          final safeEnd = end.clamp(0, 24 * 60);
          final top = safeStart * _minuteHeight;
          var height = (safeEnd - safeStart) * _minuteHeight;
          if (height < _minTimeboxMinutes * _minuteHeight) {
            height = _minTimeboxMinutes * _minuteHeight;
          }
          final color = Color(entry.tag.colorValue);
          final isPlanned = entry.isPlanned;

          return Positioned(
            top: top,
            left: 6,
            right: 6,
            child: Container(
              height: height,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isPlanned
                    ? color.withValues(alpha: 0.12)
                    : color.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isPlanned
                      ? color.withValues(alpha: 0.5)
                      : color.withValues(alpha: 0.8),
                ),
              ),
              child: Text(
                entry.taskTitle,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        }),
        Positioned.fill(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 1,
              color: Colors.transparent,
            ),
          ),
        ),
      ],
    );
  }
}

class _RecordsMonthView extends ConsumerStatefulWidget {
  const _RecordsMonthView({required this.onSelectDay});

  final ValueChanged<DateTime> onSelectDay;

  @override
  ConsumerState<_RecordsMonthView> createState() => _RecordsMonthViewState();
}

class _RecordsMonthViewState extends ConsumerState<_RecordsMonthView> {
  late DateTime _focusedDay;
  Future<Map<String, DailyData>>? _monthFuture;
  ProviderSubscription<DateTime>? _selectedDateSub;

  @override
  void initState() {
    super.initState();
    final now = ref.read(selectedDateProvider);
    _focusedDay = DateTime(now.year, now.month, now.day);
    _monthFuture = _loadMonth(_focusedDay);

    _selectedDateSub = ref.listenManual<DateTime>(
      selectedDateProvider,
      (previous, next) {
      if (!mounted) return;
      if (previous == null ||
          previous.year != next.year ||
          previous.month != next.month) {
        setState(() {
          _focusedDay = DateTime(next.year, next.month, next.day);
          _monthFuture = _loadMonth(_focusedDay);
        });
      } else {
        setState(() {
          _focusedDay = DateTime(next.year, next.month, next.day);
        });
      }
    },
    );
  }

  @override
  void dispose() {
    _selectedDateSub?.close();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);

    return FutureBuilder<Map<String, DailyData>>(
      future: _monthFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data ?? const <String, DailyData>{};

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2035, 12, 31),
                focusedDay: _focusedDay,
                startingDayOfWeek: StartingDayOfWeek.monday,
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
                calendarFormat: CalendarFormat.month,
                selectedDayPredicate: (day) => isSameDay(day, selectedDate),
                onDaySelected: (selectedDay, focusedDay) {
                  widget.onSelectDay(selectedDay);
                  setState(() {
                    _focusedDay = focusedDay;
                  });
                },
                onPageChanged: (focusedDay) {
                  setState(() {
                    _focusedDay = focusedDay;
                    _monthFuture = _loadMonth(focusedDay);
                  });
                },
                eventLoader: (day) {
                  final key = ymd(day);
                  return data[key]?.timeboxes ?? const [];
                },
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    final ratio = data[ymd(day)]?.completionRatio ?? 0;
                    final color = ratio <= 0
                        ? Colors.transparent
                        : AppColors.accent.withValues(alpha: 0.12 + ratio * 0.4);
                    return _CalendarCell(
                      day: day,
                      color: color,
                      isSelected: false,
                    );
                  },
                  todayBuilder: (context, day, focusedDay) {
                    return _CalendarCell(
                      day: day,
                      color: AppColors.accent.withValues(alpha: 0.2),
                      isSelected: false,
                      borderColor: AppColors.accent,
                    );
                  },
                  selectedBuilder: (context, day, focusedDay) {
                    return _CalendarCell(
                      day: day,
                      color: AppColors.accent.withValues(alpha: 0.3),
                      isSelected: true,
                      borderColor: AppColors.accent,
                    );
                  },
                  markerBuilder: (context, day, events) {
                    if (events.isEmpty) return null;
                    return Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${events.length}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CalendarCell extends StatelessWidget {
  const _CalendarCell({
    required this.day,
    required this.color,
    required this.isSelected,
    this.borderColor,
  });

  final DateTime day;
  final Color color;
  final bool isSelected;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final textColor = isSelected ? Colors.black : AppColors.textPrimary;
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: borderColor ?? Colors.transparent,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        '${day.day}',
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
