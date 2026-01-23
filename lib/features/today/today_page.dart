import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/constants/timer_constants.dart';
import '../../core/models/task_item.dart';
import '../../core/models/task_tag.dart';
import '../../core/utils/dates.dart';
import '../../widgets/background_grid.dart';
import '../../widgets/glow_progress_bar.dart';
import '../settings/variant_settings_controller.dart';
import '../tasks/add_task_dialog.dart';
import '../timer/hunt_timer_page.dart';
import 'daily_controller.dart';
import '../showcase/variant_layouts.dart';
import '../settings/settings_page.dart';

class TodayPage extends ConsumerWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(selectedDateProvider);
    final dailyAsync = ref.watch(dailyControllerProvider);
    final variant =
        ref.watch(variantSettingsProvider).value ?? HuntVariant.huntHud;
    final isWide = MediaQuery.of(context).size.width >= 960;

    return Scaffold(
      appBar: AppBar(
        title: TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => _showDatePicker(context, ref, date),
          child: Text(
            '今天  ${ymd(date)}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        actions: [
          IconButton(
            tooltip: '設定',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: isWide
          ? null
          : FloatingActionButton.extended(
              onPressed: () => showAddTaskDialog(context: context),
              icon: const Icon(Icons.add),
              label: const Text('新增任務'),
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.background,
            ),
      body: dailyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (daily) {
          final totalMinutes = _sumTaskMinutes(daily.tasks);
          final totalCycles = _sumTaskCycles(daily.tasks);
          final totalLabel = _formatMinutes(totalMinutes);

          final noteSection = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DailyProgressHeader(
                slackRemaining: daily.slackRemaining,
                completionRatio: daily.completionRatio,
                completedCycles: daily.completedCycles,
                totalCycles: daily.totalCycles,
              ),
              const SizedBox(height: 16),
              const _DailyNoteCard(),
            ],
          );

          final tasksPanel = _buildTasksPanel(
            context,
            ref,
            daily.tasks,
            variant,
            taskCount: daily.tasks.length,
            totalCycles: totalCycles,
            totalLabel: totalLabel,
          );

          return Stack(
            children: [
              const Positioned.fill(
                child: IgnorePointer(
                  child: BackgroundGrid(child: SizedBox.expand()),
                ),
              ),
              Positioned.fill(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isWide ? 1200 : double.infinity,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: isWide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 4, child: noteSection),
                                const SizedBox(width: 20),
                                Expanded(flex: 6, child: tasksPanel),
                              ],
                            )
                          : Column(
                              children: [
                                noteSection,
                                const SizedBox(height: 20),
                                Expanded(child: tasksPanel),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showDatePicker(
    BuildContext context,
    WidgetRef ref,
    DateTime currentDate,
  ) async {
    final now = DateTime.now();
    final newDate = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365)),
    );

    if (newDate != null) {
      ref.read(selectedDateProvider.notifier).state = dateOnly(newDate);
    }
  }

  ButtonStyle _actionButtonStyle(TaskTag tag, Color tagColor) {
    final isUrgent = tag == TaskTag.urgent;

    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return AppColors.track;
        }
        if (isUrgent) {
          return tagColor.withValues(alpha: 0.92);
        }
        // tinted glass-like fill, same hue as border
        return tagColor.withValues(alpha: 0.12);
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return AppColors.textSecondary;
        }
        return isUrgent ? Colors.black : tagColor.withValues(alpha: 0.92);
      }),
      side: WidgetStateProperty.all(
        BorderSide(
          color: isUrgent
              ? Colors.transparent
              : tagColor.withValues(alpha: 0.55),
          width: 1,
        ),
      ),
      overlayColor: WidgetStateProperty.all(tagColor.withValues(alpha: 0.10)),
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  String _formatMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final remain = minutes % 60;
    if (hours <= 0) return '${remain}m';
    if (remain == 0) return '${hours}h';
    return '${hours}h ${remain}m';
  }

  int _sumTaskMinutes(List<TaskItem> tasks) {
    return tasks.fold<int>(
      0,
      (total, task) => total + task.totalCycles * task.cycleMinutes,
    );
  }

  int _sumTaskCycles(List<TaskItem> tasks) {
    return tasks.fold<int>(0, (total, task) => total + task.totalCycles);
  }

  Widget _buildTasksPanel(
    BuildContext context,
    WidgetRef ref,
    List<TaskItem> tasks,
    HuntVariant variant, {
    required int taskCount,
    required int totalCycles,
    required String totalLabel,
  }) {
    void onAddTask() => showAddTaskDialog(context: context);

    return _PlannerPanel(
      padding: EdgeInsets.zero,
      borderRadius: 24,
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: _TasksHeader(
              taskCount: taskCount,
              totalCycles: totalCycles,
              totalLabel: totalLabel,
              onAdd: onAddTask,
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.divider.withValues(alpha: 0.6),
          ),
          Expanded(
            child: tasks.isEmpty
                ? _EmptyTasksState(onAdd: onAddTask)
                : Stack(
                    children: [
                      Positioned(
                        left: 18,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 1,
                          color: AppColors.divider.withValues(alpha: 0.45),
                        ),
                      ),
                      _buildTaskList(context, ref, tasks, variant),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(
    BuildContext context,
    WidgetRef ref,
    List<TaskItem> tasks,
    HuntVariant variant,
  ) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 12, 16, 16),
      itemCount: tasks.length,
      buildDefaultDragHandles: false,
      onReorderStart: (_) {
        HapticFeedback.selectionClick();
      },
      onReorder: (oldIndex, newIndex) {
        ref.read(dailyControllerProvider.notifier).reorderTasks(
              oldIndex,
              newIndex,
            );
      },
      proxyDecorator: (child, index, animation) {
        return Material(
          color: Colors.transparent,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 120),
            scale: 1.02,
            child: child,
          ),
        );
      },
      itemBuilder: (context, index) {
        final task = tasks[index];
        final tagColor = Color(task.tag.colorValue);

        return ReorderableDelayedDragStartListener(
          key: ValueKey(task.id),
          index: index,
          child: Dismissible(
            key: ValueKey('dismiss-${task.id}'),
            direction: DismissDirection.endToStart,
            confirmDismiss: (_) => _confirmDelete(context, task.title),
            background: const SizedBox.shrink(),
            secondaryBackground: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(
                  0xFF7F1D1D,
                ).withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(
                    0xFFEF4444,
                  ).withValues(alpha: 0.35),
                ),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 16),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.delete_outline,
                    color: Color(0xFFFCA5A5),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '刪除',
                    style: TextStyle(
                      color: Color(0xFFFCA5A5),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            onDismissed: (_) => _deleteWithUndo(
              context,
              ref,
              taskId: task.id,
              title: task.title,
              index: index,
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(
                    color: AppColors.divider,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 3,
                          margin: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: tagColor.withValues(
                              alpha:
                                  task.tag == TaskTag.urgent ? 0.9 : 0.55,
                            ),
                            borderRadius: BorderRadius.circular(
                              999,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: tagColor.withValues(
                                  alpha: 0.20,
                                ),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  color: tagColor.withValues(
                                    alpha: 0.7,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  task.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Builder(
                                builder: (menuContext) {
                                  return IconButton(
                                    tooltip: '任務選單',
                                    icon: const Icon(Icons.menu),
                                    onPressed: () async {
                                      final action = await _showTaskMenu(
                                        menuContext,
                                      );
                                      if (!menuContext.mounted) {
                                        return;
                                      }
                                      if (action == 'delete') {
                                        _deleteWithUndo(
                                          menuContext,
                                          ref,
                                          taskId: task.id,
                                          title: task.title,
                                          index: index,
                                          askConfirm: true,
                                        );
                                      }
                                      if (action == 'adjust_cycles') {
                                        await _showAdjustCyclesSheet(
                                          menuContext,
                                          ref,
                                          task,
                                        );
                                      }
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Text(
                                '${task.completedCycles}/${task.totalCycles} 輪 • ${task.cycleMinutes} 分鐘',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                onPressed: () => _showAdjustCyclesSheet(
                                  context,
                                  ref,
                                  task,
                                ),
                                icon: const Icon(Icons.tune, size: 14),
                                label: const Text('調整'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.textSecondary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  textStyle: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              _TagPill(
                                label: task.tag.label,
                                color: tagColor,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: GlowProgressBar(
                                  value: task.totalCycles <= 0
                                      ? 0
                                      : task.completedCycles / task.totalCycles,
                                  height: 6,
                                  trackColor: AppColors.divider,
                                  progressColor: tagColor,
                                  glowBlur: 6,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          FilledButton(
                            style: _actionButtonStyle(task.tag, tagColor),
                            onPressed: task.isDone
                                ? null
                                : () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => HuntTimerPage(
                                          taskId: task.id,
                                          variant: variant,
                                        ),
                                      ),
                                    );
                                  },
                            child: Text(task.isDone ? '已完成' : '開獵'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAdjustCyclesSheet(
    BuildContext context,
    WidgetRef ref,
    TaskItem task,
  ) async {
    var totalCycles = task.totalCycles;
    final minCycles = TimerConstants.minTotalCycles;
    final maxCycles = TimerConstants.maxTotalCycles;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final totalMinutes = totalCycles * task.cycleMinutes;
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                16 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Card(
                elevation: 6,
                shadowColor: Colors.black.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '調整輪數',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          Text(
                            _formatMinutes(totalMinutes),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        task.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          IconButton(
                            onPressed: totalCycles <= minCycles
                                ? null
                                : () => setState(() => totalCycles -= 1),
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text(
                            '$totalCycles 輪',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          IconButton(
                            onPressed: totalCycles >= maxCycles
                                ? null
                                : () => setState(() => totalCycles += 1),
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                          const Spacer(),
                          Text(
                            '每輪 ${task.cycleMinutes} 分',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Slider(
                        value: totalCycles.toDouble(),
                        min: minCycles.toDouble(),
                        max: maxCycles.toDouble(),
                        divisions: maxCycles - minCycles,
                        label: '$totalCycles 輪',
                        onChanged: (value) {
                          setState(() => totalCycles = value.round());
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('取消'),
                          ),
                          const Spacer(),
                          FilledButton(
                            onPressed: () async {
                              await ref
                                  .read(dailyControllerProvider.notifier)
                                  .updateTotalCycles(task.id, totalCycles);
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                            child: const Text('更新'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<String?> _showTaskMenu(BuildContext context) {
    final overlay = Overlay.of(context).context.findRenderObject();
    final button = context.findRenderObject();

    RelativeRect position = const RelativeRect.fromLTRB(0, 0, 0, 0);

    if (overlay is RenderBox && button is RenderBox) {
      final topLeft = button.localToGlobal(Offset.zero, ancestor: overlay);
      final bottomRight = button.localToGlobal(
        button.size.bottomRight(Offset.zero),
        ancestor: overlay,
      );

      position = RelativeRect.fromRect(
        Rect.fromPoints(topLeft, bottomRight),
        Offset.zero & overlay.size,
      );
    }

    return showMenu<String>(
      context: context,
      position: position,
      items: const [
        PopupMenuItem(
          value: 'adjust_cycles',
          child: Row(
            children: [
              Icon(Icons.tune),
              SizedBox(width: 10),
              Text('調整輪數'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline),
              SizedBox(width: 10),
              Text('刪除'),
            ],
          ),
        ),
      ],
    );
  }

  Future<bool> _confirmDelete(BuildContext context, String title) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('刪除任務？'),
          content: Text('要刪除「$title」嗎？這可以復原一次（Undo）。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('刪除'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> _deleteWithUndo(
    BuildContext context,
    WidgetRef ref, {
    required String taskId,
    required String title,
    required int index,
    bool askConfirm = false,
  }) async {
    if (askConfirm) {
      final ok = await _confirmDelete(context, title);
      if (!ok) return;
    }

    final removed = await ref
        .read(dailyControllerProvider.notifier)
        .removeTask(taskId);
    if (removed == null) return;

    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text('已刪除「$title」'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              ref
                  .read(dailyControllerProvider.notifier)
                  .insertTask(removed, index: index);
            },
          ),
        ),
      );
  }

}

class _DailyNoteCard extends ConsumerStatefulWidget {
  const _DailyNoteCard();

  @override
  ConsumerState<_DailyNoteCard> createState() => _DailyNoteCardState();
}

class _DailyNoteCardState extends ConsumerState<_DailyNoteCard> {
  static const _saveDelay = Duration(milliseconds: 500);

  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  Timer? _debounce;
  String _lastSaved = '';
  DateTime? _lastDate;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _commitNow();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isSameTextForDate(String text, DateTime date) {
    return _lastDate != null &&
        _sameDay(_lastDate!, date) &&
        _lastSaved == text;
  }

  void _setControllerText(String text) {
    if (_controller.text == text) return;
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
      composing: TextRange.empty,
    );
  }

  void _queueSave(String text, DateTime date) {
    if (_isSameTextForDate(text, date)) return;
    _debounce?.cancel();
    _debounce = Timer(_saveDelay, () => _save(text, date));
  }

  Future<void> _save(String text, DateTime date) async {
    if (_isSameTextForDate(text, date)) return;
    _lastSaved = text;
    _lastDate = date;
    await ref.read(dailyControllerProvider.notifier).updateDailyNoteForDate(
          date: date,
          note: text,
        );
  }

  void _commitNow() {
    final date = ref.read(selectedDateProvider);
    _debounce?.cancel();
    _save(_controller.text, date);
  }

  @override
  Widget build(BuildContext context) {
    final date = ref.watch(selectedDateProvider);
    final dailyAsync = ref.watch(dailyControllerProvider);
    final note = dailyAsync.valueOrNull?.dailyNote ?? '';
    final dateChanged = _lastDate == null || !_sameDay(_lastDate!, date);

    if (dateChanged) {
      _debounce?.cancel();
      if (_focusNode.hasFocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _focusNode.unfocus();
        });
      }
      _setControllerText(note);
      _lastSaved = note;
      _lastDate = date;
    } else if (!_focusNode.hasFocus && _controller.text != note) {
      _setControllerText(note);
      _lastSaved = note;
    }

    final enabled = dailyAsync.hasValue;
    final dateLabel = ymd(date);

    final borderRadius = BorderRadius.circular(20);

    return Material(
      color: Colors.transparent,
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.35),
      borderRadius: borderRadius,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  border: Border.all(
                    color: AppColors.divider.withValues(alpha: 0.6),
                  ),
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF101C32).withValues(alpha: 0.95),
                      const Color(0xFF0B1220).withValues(alpha: 0.95),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _NotePaperPainter(
                  topOffset: 68,
                  lineGap: 26,
                ),
              ),
            ),
            Positioned(
              left: 16,
              top: 16,
              bottom: 16,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accent.withValues(alpha: 0.9),
                      AppColors.accentDark.withValues(alpha: 0.4),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.22),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(30, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.edit_note,
                        color: AppColors.accent,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '今日筆記',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.divider.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          dateLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.divider.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          '自動保存',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    enabled: enabled,
                    keyboardType: TextInputType.multiline,
                    minLines: 5,
                    maxLines: 10,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      height: 1.65,
                    ),
                    decoration: InputDecoration(
                      hintText: '記下今天的重點、提醒、靈感或碎碎念...',
                      hintStyle: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.6),
                      ),
                      border: InputBorder.none,
                      isCollapsed: true,
                    ),
                    onChanged: (value) => _queueSave(value, date),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotePaperPainter extends CustomPainter {
  const _NotePaperPainter({
    required this.topOffset,
    required this.lineGap,
  });

  final double topOffset;
  final double lineGap;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppColors.divider.withValues(alpha: 0.28)
      ..strokeWidth = 1;

    for (double y = topOffset; y < size.height; y += lineGap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    final marginPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.18)
      ..strokeWidth = 1;

    const marginX = 26.0;
    canvas.drawLine(
      const Offset(marginX, 0),
      Offset(marginX, size.height),
      marginPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _NotePaperPainter oldDelegate) {
    return oldDelegate.topOffset != topOffset ||
        oldDelegate.lineGap != lineGap;
  }
}

class _PlannerPanel extends StatelessWidget {
  const _PlannerPanel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 20,
    this.elevation = 3,
  });

  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);

    return Material(
      color: Colors.transparent,
      elevation: elevation,
      shadowColor: Colors.black.withValues(alpha: 0.35),
      borderRadius: radius,
      child: ClipRRect(
        borderRadius: radius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: AppColors.divider.withValues(alpha: 0.6),
            ),
            gradient: LinearGradient(
              colors: [
                const Color(0xFF111C30).withValues(alpha: 0.92),
                const Color(0xFF0B1220).withValues(alpha: 0.96),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class _TasksHeader extends StatelessWidget {
  const _TasksHeader({
    required this.taskCount,
    required this.totalCycles,
    required this.totalLabel,
    required this.onAdd,
  });

  final int taskCount;
  final int totalCycles;
  final String totalLabel;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final summary = taskCount == 0
        ? '今天還沒有排任務'
        : '$taskCount 項 • $totalCycles 輪 • $totalLabel';

    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '任務清單',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              summary,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('新增任務'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: BorderSide(color: AppColors.divider.withValues(alpha: 0.7)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }
}

class _EmptyTasksState extends StatelessWidget {
  const _EmptyTasksState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome_outlined,
              color: AppColors.accent.withValues(alpha: 0.9),
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              '今天還沒排任務',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              '把想完成的事情寫下來，像排一份行程表。',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: onAdd,
              child: const Text('新增任務'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _DailyProgressHeader extends StatelessWidget {
  const _DailyProgressHeader({
    required this.slackRemaining,
    required this.completionRatio,
    required this.completedCycles,
    required this.totalCycles,
  });

  final int slackRemaining;
  final double completionRatio;
  final int completedCycles;
  final int totalCycles;

  @override
  Widget build(BuildContext context) {
    return _PlannerPanel(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                '今日概覽',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.divider.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${(completionRatio * 100).round()}% 完成',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '偷懶券 $slackRemaining/3',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const Spacer(),
              Text(
                '總進度 $completedCycles/$totalCycles 輪',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GlowProgressBar(
            value: completionRatio,
            height: 6,
            trackColor: const Color(0xFF334155),
            progressColor: const Color(0xFF22C55E),
            glowBlur: 6,
          ),
        ],
      ),
    );
  }
}
