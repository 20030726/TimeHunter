import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../app/theme.dart';
import '../../core/constants/timer_constants.dart';
import '../../core/models/daily_data.dart';
import '../../core/models/hunt_variant.dart';
import '../../core/models/task_item.dart';
import '../../core/models/task_tag.dart';
import '../../core/theme/variant_ui.dart';
import '../../core/utils/dates.dart';
import '../../widgets/glow_progress_bar.dart';
import '../../widgets/xp_bar_overview.dart';
import '../settings/variant_settings_controller.dart';
import '../tasks/add_task_dialog.dart';
import '../timer/hunt_timer_page.dart';
import 'daily_controller.dart';
import '../settings/settings_page.dart';

class TodayPage extends ConsumerWidget {
  const TodayPage({super.key});

  String _dateHeading(DateTime date) {
    final target = dateOnly(date);
    final today = dateOnly(DateTime.now());
    final tomorrow = today.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));

    if (target == today) return '今天';
    if (target == tomorrow) return '明天';
    if (target == yesterday) return '昨天';
    return ymd(target);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(selectedDateProvider);
    final dailyAsync = ref.watch(dailyControllerProvider);
    final variant =
        ref.watch(variantSettingsProvider).value ?? HuntVariant.splitCommand;
    final style = plannerStyleFor(variant);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= style.breakpoint;
    final maxWidth = isWide
        ? (screenWidth - 64).clamp(980.0, 1600.0).toDouble()
        : double.infinity;
    final horizontalPadding = isWide ? 24.0 : 16.0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: TextButton(
          style: TextButton.styleFrom(
            foregroundColor: style.textPrimary,
          ),
          onPressed: () => _showDatePicker(context, ref, date),
          child: Text(
            _dateHeading(date) == ymd(date)
                ? ymd(date)
                : '${_dateHeading(date)}  ${ymd(date)}',
            style: style.titleFont.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: style.textPrimary,
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: '設定',
            icon: const Icon(Icons.settings_outlined),
            color: style.textPrimary,
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
              backgroundColor: style.accent,
              foregroundColor: Colors.black,
            ),
      body: dailyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (daily) {
          final totalMinutes = _sumTaskMinutes(daily.tasks);
          final totalCycles = _sumTaskCycles(daily.tasks);
          final totalLabel = _formatMinutes(totalMinutes);

          final hero = _PlannerHero(
            style: style,
            date: date,
            daily: daily,
            totalCycles: totalCycles,
            taskCount: daily.tasks.length,
            totalLabel: totalLabel,
          );

          final noteCard = _DailyNoteCard(
            style: style,
            expanded: isWide,
          );

          final tasksPanel = (bool allowListScroll) => _buildTasksPanel(
                context,
                ref,
                daily.tasks,
                variant,
                style: style,
                taskCount: daily.tasks.length,
                totalCycles: totalCycles,
                totalLabel: totalLabel,
                allowListScroll: allowListScroll,
              );

          final content = isWide
              ? Column(
                  children: [
                    hero,
                    const SizedBox(height: 18),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(flex: 5, child: noteCard),
                          const SizedBox(width: 18),
                          Expanded(flex: 7, child: tasksPanel(true)),
                        ],
                      ),
                    ),
                  ],
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final compactHeight = constraints.maxHeight < 720;
                    final panel = tasksPanel(!compactHeight);
                    final column = Column(
                      children: [
                        hero,
                        const SizedBox(height: 16),
                        noteCard,
                        const SizedBox(height: 16),
                        compactHeight
                            ? panel
                            : Expanded(
                                child: panel,
                              ),
                      ],
                    );
                    if (!compactHeight) return column;
                    return SingleChildScrollView(child: column);
                  },
                );

          return Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: _PlannerBackdrop(style: style),
                ),
              ),
              if (style.showGrid)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _PlannerGridPainter(style: style),
                    ),
                  ),
                ),
              Positioned.fill(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: maxWidth,
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        12,
                        horizontalPadding,
                        18,
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: content,
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

  ButtonStyle _actionButtonStyle(
    TaskTag tag,
    Color tagColor,
    PlannerStyle style,
  ) {
    final isUrgent = tag == TaskTag.urgent;

    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return style.border;
        }
        if (isUrgent) {
          return tagColor.withValues(alpha: 0.92);
        }
        // tinted glass-like fill, same hue as border
        return tagColor.withValues(alpha: 0.12);
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return style.textSecondary;
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
    required PlannerStyle style,
    required int taskCount,
    required int totalCycles,
    required String totalLabel,
    required bool allowListScroll,
  }) {
    void onAddTask() => showAddTaskDialog(context: context);

    return _PlannerPanel(
      style: style,
      padding: EdgeInsets.zero,
      borderRadius: 26,
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: _TasksHeader(
              style: style,
              taskCount: taskCount,
              totalCycles: totalCycles,
              totalLabel: totalLabel,
              onAdd: onAddTask,
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: style.border.withValues(alpha: 0.7),
          ),
          if (allowListScroll)
            Expanded(
              child: tasks.isEmpty
                  ? _EmptyTasksState(style: style, onAdd: onAddTask)
                  : Stack(
                      children: [
                        Positioned(
                          left: 18,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            width: 1,
                            color: style.border.withValues(alpha: 0.5),
                          ),
                        ),
                        _buildTaskList(
                          context,
                          ref,
                          tasks,
                          variant,
                          style,
                          allowListScroll: true,
                        ),
                      ],
                    ),
            )
          else
            (tasks.isEmpty
                ? _EmptyTasksState(style: style, onAdd: onAddTask)
                : Stack(
                    children: [
                      Positioned(
                        left: 18,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 1,
                          color: style.border.withValues(alpha: 0.5),
                        ),
                      ),
                      _buildTaskList(
                        context,
                        ref,
                        tasks,
                        variant,
                        style,
                        allowListScroll: false,
                      ),
                    ],
                  )),
        ],
      ),
    );
  }

  Widget _buildTaskList(
    BuildContext context,
    WidgetRef ref,
    List<TaskItem> tasks,
    HuntVariant variant,
    PlannerStyle style, {
    required bool allowListScroll,
  }) {
    final components = plannerComponentsFor(style);
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 12, 16, 16),
      itemCount: tasks.length,
      buildDefaultDragHandles: false,
      shrinkWrap: !allowListScroll,
      physics: allowListScroll
          ? const BouncingScrollPhysics()
          : const NeverScrollableScrollPhysics(),
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
        final progress = task.totalCycles <= 0
            ? 0.0
            : task.completedCycles / task.totalCycles;

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
              child: Material(
                color: Colors.transparent,
                elevation: 4,
                shadowColor: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(18),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      colors: style.taskCardGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: style.border.withValues(alpha: 0.65),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 12,
                        top: 14,
                        bottom: 14,
                        child: Container(
                          width: 3,
                          decoration: BoxDecoration(
                            color: tagColor.withValues(
                              alpha:
                                  task.tag == TaskTag.urgent ? 0.95 : 0.65,
                            ),
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color: tagColor.withValues(alpha: 0.2),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                tagColor.withValues(alpha: 0.55),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 9,
                                  height: 9,
                                  decoration: BoxDecoration(
                                    color: tagColor.withValues(alpha: 0.75),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    task.title,
                                    style: style.titleFont.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: style.textPrimary,
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
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  '${task.completedCycles}/${task.totalCycles} 輪 • ${task.cycleMinutes} 分鐘',
                                  style: style.bodyFont.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: style.textSecondary,
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
                                    foregroundColor: style.textSecondary,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    minimumSize: const Size(0, 0),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    textStyle: style.bodyFont.copyWith(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                _TagPill(
                                  style: style,
                                  label: task.tag.label,
                                  color: tagColor,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: components.taskProgressStyle ==
                                          TaskProgressStyle.solid
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(999),
                                          child: LinearProgressIndicator(
                                            value: progress,
                                            minHeight: 6,
                                            backgroundColor: style.border
                                                .withValues(alpha: 0.7),
                                            valueColor:
                                                AlwaysStoppedAnimation(
                                              tagColor,
                                            ),
                                          ),
                                        )
                                      : GlowProgressBar(
                                          value: progress,
                                          height: 6,
                                          trackColor: style.border
                                              .withValues(alpha: 0.7),
                                          progressColor: tagColor,
                                          glowBlur: 8,
                                        ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            FilledButton(
                              style: _actionButtonStyle(
                                task.tag,
                                tagColor,
                                style,
                              ),
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
                              child: Text(
                                task.isDone
                                    ? components.actionDoneLabel
                                    : components.actionLabel,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
  const _DailyNoteCard({
    required this.style,
    required this.expanded,
  });

  final PlannerStyle style;
  final bool expanded;

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
  bool _previewMode = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _previewMode) {
        setState(() => _previewMode = false);
      }
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
    final style = widget.style;
    final components = plannerComponentsFor(style);
    final expands = widget.expanded;
    final isEditing = _focusNode.hasFocus;
    final currentText = _controller.text;
    final hasContent = currentText.trim().isNotEmpty;
    final showPreview = _previewMode || (!isEditing && hasContent);
    final toggleLabel = showPreview ? '編輯' : '預覽';
    final toggleIcon = showPreview ? Icons.edit : Icons.visibility;

    final borderRadius = BorderRadius.circular(20);

    final markdownStyle = MarkdownStyleSheet(
      p: style.bodyFont.copyWith(
        fontSize: 14,
        height: 1.65,
        color: style.textPrimary,
      ),
      a: style.bodyFont.copyWith(
        color: style.accent,
        decoration: TextDecoration.underline,
      ),
      h1: style.titleFont.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: style.textPrimary,
      ),
      h2: style.titleFont.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: style.textPrimary,
      ),
      h3: style.titleFont.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: style.textPrimary,
      ),
      blockquote: style.bodyFont.copyWith(
        color: style.textSecondary,
        fontStyle: FontStyle.italic,
      ),
      blockquoteDecoration: BoxDecoration(
        color: style.border.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: style.border.withValues(alpha: 0.4)),
      ),
      code: style.monoFont.copyWith(
        fontSize: 12,
        color: style.accentSoft,
      ),
      codeblockDecoration: BoxDecoration(
        color: style.border.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      listBullet: style.bodyFont.copyWith(color: style.accent),
    );

    return Material(
      color: Colors.transparent,
      elevation: 4,
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
                    color: components.panelBorderColor,
                    width: components.panelBorderWidth,
                  ),
                  gradient: LinearGradient(
                    colors: style.noteGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            if (style.showPaperLines)
              Positioned.fill(
                child: CustomPaint(
                  painter: _NotePaperPainter(
                    topOffset: 72,
                    lineGap: 26,
                    lineColor: style.noteLine,
                    marginColor: style.noteMargin,
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
                      style.accent.withValues(alpha: 0.9),
                      style.accentSoft.withValues(alpha: 0.4),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: style.accent.withValues(alpha: 0.22),
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
                      Icon(
                        Icons.edit_note,
                        color: style.accent,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '今日筆記',
                        style: style.titleFont.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: style.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: components.chipBackground,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: components.chipBorder),
                        ),
                        child: Text(
                          dateLabel,
                          style: components.chipTextStyle,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: components.chipBackground,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: components.chipBorder),
                        ),
                        child: Text(
                          isEditing ? '編輯中' : '自動保存',
                          style: components.chipTextStyle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: enabled
                            ? () {
                                if (showPreview) {
                                  setState(() => _previewMode = false);
                                  WidgetsBinding.instance.addPostFrameCallback(
                                    (_) {
                                      if (mounted) {
                                        FocusScope.of(context)
                                            .requestFocus(_focusNode);
                                      }
                                    },
                                  );
                                } else {
                                  setState(() => _previewMode = true);
                                  FocusScope.of(context).unfocus();
                                }
                              }
                            : null,
                        icon: Icon(toggleIcon, size: 14),
                        label: Text(toggleLabel),
                        style: TextButton.styleFrom(
                          foregroundColor: style.textPrimary,
                          backgroundColor: components.chipBackground,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          textStyle: style.bodyFont.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                            side: BorderSide(
                              color: components.chipBorder,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (showPreview)
                    (expands
                        ? Expanded(
                            child: _MarkdownPreview(
                              enabled: enabled,
                              data: currentText,
                              style: markdownStyle,
                              onTap: () {
                                FocusScope.of(context).requestFocus(_focusNode);
                              },
                            ),
                          )
                        : SizedBox(
                            height: 180,
                            child: _MarkdownPreview(
                              enabled: enabled,
                              data: currentText,
                              style: markdownStyle,
                              onTap: () {
                                FocusScope.of(context).requestFocus(_focusNode);
                              },
                            ),
                          ))
                  else
                    (expands
                        ? Expanded(
                            child: _NoteEditor(
                              controller: _controller,
                              focusNode: _focusNode,
                              enabled: enabled,
                              style: style,
                              onChanged: (value) => _queueSave(value, date),
                            ),
                          )
                        : _NoteEditor(
                            controller: _controller,
                            focusNode: _focusNode,
                            enabled: enabled,
                            style: style,
                            compact: true,
                            onChanged: (value) => _queueSave(value, date),
                          )),
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
    required this.lineColor,
    required this.marginColor,
  });

  final double topOffset;
  final double lineGap;
  final Color lineColor;
  final Color marginColor;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;

    for (double y = topOffset; y < size.height; y += lineGap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    final marginPaint = Paint()
      ..color = marginColor
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
        oldDelegate.lineGap != lineGap ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.marginColor != marginColor;
  }
}

class _MarkdownPreview extends StatelessWidget {
  const _MarkdownPreview({
    required this.enabled,
    required this.data,
    required this.style,
    required this.onTap,
  });

  final bool enabled;
  final String data;
  final MarkdownStyleSheet style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.only(right: 6),
          child: MarkdownBody(
            data: data,
            styleSheet: style,
          ),
        ),
      ),
    );
  }
}

class _NoteEditor extends StatelessWidget {
  const _NoteEditor({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.style,
    this.compact = false,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final PlannerStyle style;
  final bool compact;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      keyboardType: TextInputType.multiline,
      expands: !compact,
      minLines: compact ? 5 : null,
      maxLines: compact ? 10 : null,
      style: style.bodyFont.copyWith(
        color: style.textPrimary,
        fontSize: 14,
        height: 1.65,
      ),
      decoration: InputDecoration(
        hintText: '記下今天的重點、提醒、靈感或碎碎念...',
        hintStyle: style.bodyFont.copyWith(
          color: style.textSecondary.withValues(alpha: 0.6),
        ),
        border: InputBorder.none,
        isCollapsed: true,
      ),
      onChanged: onChanged,
    );
  }
}

class _PlannerBackdrop extends StatelessWidget {
  const _PlannerBackdrop({required this.style});

  final PlannerStyle style;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PlannerBackdropPainter(style: style),
      child: const SizedBox.expand(),
    );
  }
}

class _PlannerBackdropPainter extends CustomPainter {
  const _PlannerBackdropPainter({required this.style});

  final PlannerStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final basePaint = Paint()
      ..shader =
          LinearGradient(colors: style.canvasGradient).createShader(rect);
    canvas.drawRect(rect, basePaint);

    _paintGlow(
      canvas,
      center: Offset(size.width * 0.18, size.height * 0.2),
      radius: size.width * 0.55,
      color: style.accent.withValues(alpha: 0.18),
    );
    _paintGlow(
      canvas,
      center: Offset(size.width * 0.82, size.height * 0.85),
      radius: size.width * 0.6,
      color: style.accentSoft.withValues(alpha: 0.14),
    );
  }

  void _paintGlow(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required Color color,
  }) {
    final paint = Paint()
      ..blendMode = BlendMode.plus
      ..shader = RadialGradient(
        colors: [color, Colors.transparent],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _PlannerBackdropPainter oldDelegate) {
    return oldDelegate.style != style;
  }
}

class _PlannerGridPainter extends CustomPainter {
  const _PlannerGridPainter({required this.style});

  final PlannerStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = style.gridColor
      ..strokeWidth = 1;

    const step = 36.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PlannerGridPainter oldDelegate) {
    return oldDelegate.style != style;
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.style,
    required this.icon,
    required this.label,
  });

  final PlannerStyle style;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final components = plannerComponentsFor(style);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: components.chipBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: components.chipBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: components.chipIconColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: components.chipTextStyle,
          ),
        ],
      ),
    );
  }
}

class _PlannerPanel extends StatelessWidget {
  const _PlannerPanel({
    required this.style,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 20,
    this.elevation = 3,
  });

  final PlannerStyle style;
  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final components = plannerComponentsFor(style);

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
              color: components.panelBorderColor,
              width: components.panelBorderWidth,
            ),
            gradient: LinearGradient(
              colors: style.panelGradient,
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
    required this.style,
    required this.taskCount,
    required this.totalCycles,
    required this.totalLabel,
    required this.onAdd,
  });

  final PlannerStyle style;
  final int taskCount;
  final int totalCycles;
  final String totalLabel;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '任務清單',
                style: style.titleFont.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: style.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _StatChip(
                    style: style,
                    icon: Icons.checklist,
                    label: '$taskCount 項',
                  ),
                  _StatChip(
                    style: style,
                    icon: Icons.cached,
                    label: '$totalCycles 輪',
                  ),
                  _StatChip(
                    style: style,
                    icon: Icons.schedule,
                    label: totalLabel,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('新增任務'),
          style: OutlinedButton.styleFrom(
            foregroundColor: style.textPrimary,
            side: BorderSide(color: style.border.withValues(alpha: 0.7)),
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
  const _EmptyTasksState({required this.style, required this.onAdd});

  final PlannerStyle style;
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
              color: style.accent.withValues(alpha: 0.9),
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              '今天還沒排任務',
              style: style.titleFont.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: style.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '把想完成的事情寫下來，像排一份行程表。',
              textAlign: TextAlign.center,
              style: style.bodyFont.copyWith(
                fontSize: 12,
                color: style.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: onAdd,
              style: FilledButton.styleFrom(
                backgroundColor: style.accent,
                foregroundColor: Colors.black,
              ),
              child: const Text('新增任務'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({
    required this.style,
    required this.label,
    required this.color,
  });

  final PlannerStyle style;
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
        style: style.bodyFont.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _PlannerHero extends StatelessWidget {
  const _PlannerHero({
    required this.style,
    required this.date,
    required this.daily,
    required this.totalCycles,
    required this.taskCount,
    required this.totalLabel,
  });

  final PlannerStyle style;
  final DateTime date;
  final DailyData daily;
  final int totalCycles;
  final int taskCount;
  final String totalLabel;

  @override
  Widget build(BuildContext context) {
    final completion = daily.completionRatio.clamp(0.0, 1.0);
    final components = plannerComponentsFor(style);
    Widget? badge;
    switch (components.heroBadgeStyle) {
      case HeroBadgeStyle.none:
        badge = null;
        break;
      case HeroBadgeStyle.ring:
        badge = _CompletionRing(
          value: completion,
          style: style,
          progressColor: components.heroProgressColor,
          trackColor: components.heroTrackColor,
        );
        break;
      case HeroBadgeStyle.orbit:
        badge = _OrbitBadge(
          value: completion,
          style: style,
          progressColor: components.heroProgressColor,
          trackColor: components.heroTrackColor,
        );
        break;
    }

    return _PlannerPanel(
      style: style,
      borderRadius: 24,
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '今日概覽',
                  style: style.titleFont.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: style.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  ymd(date),
                  style: style.monoFont.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: style.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatChip(
                      style: style,
                      icon: Icons.checklist,
                      label: '$taskCount 項',
                    ),
                    _StatChip(
                      style: style,
                      icon: Icons.cached,
                      label: '$totalCycles 輪',
                    ),
                    _StatChip(
                      style: style,
                      icon: Icons.schedule,
                      label: totalLabel,
                    ),
                    _StatChip(
                      style: style,
                      icon: Icons.nights_stay,
                      label: '偷懶券 ${daily.slackRemaining}/3',
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (components.heroProgressStyle == HeroProgressStyle.xpBar) ...[
                  Text(
                    'XP 進度',
                    style: style.bodyFont.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: style.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  XpBarOverview(
                    value: completion,
                    accent: components.heroProgressColor,
                    track: components.heroTrackColor,
                  ),
                ] else
                  GlowProgressBar(
                    value: completion,
                    height: 6,
                    trackColor: components.heroTrackColor,
                    progressColor: components.heroProgressColor,
                    glowBlur: 8,
                  ),
              ],
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 16),
            Column(
              children: [
                badge,
                const SizedBox(height: 6),
                Text(
                  '${(completion * 100).round()}% 完成',
                  style: style.bodyFont.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: style.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CompletionRing extends StatelessWidget {
  const _CompletionRing({
    required this.value,
    required this.style,
    required this.progressColor,
    required this.trackColor,
  });

  final double value;
  final PlannerStyle style;
  final Color progressColor;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    return SizedBox(
      width: 62,
      height: 62,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: clamped,
            strokeWidth: 6,
            backgroundColor: trackColor,
            valueColor: AlwaysStoppedAnimation(progressColor),
          ),
          Text(
            '${(clamped * 100).round()}%',
            style: style.titleFont.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: style.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrbitBadge extends StatelessWidget {
  const _OrbitBadge({
    required this.value,
    required this.style,
    required this.progressColor,
    required this.trackColor,
  });

  final double value;
  final PlannerStyle style;
  final Color progressColor;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    return SizedBox(
      width: 62,
      height: 62,
      child: CustomPaint(
        painter: _OrbitBadgePainter(
          value: clamped,
          progressColor: progressColor,
          trackColor: trackColor,
        ),
        child: Center(
          child: Text(
            '${(clamped * 100).round()}%',
            style: style.titleFont.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: style.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _OrbitBadgePainter extends CustomPainter {
  _OrbitBadgePainter({
    required this.value,
    required this.progressColor,
    required this.trackColor,
  });

  final double value;
  final Color progressColor;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 6.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    canvas.drawCircle(center, radius, trackPaint);

    final sweep = math.max(0.02, value) * math.pi * 2;
    final start = -math.pi / 2;
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = progressColor;
    canvas.drawArc(rect, start, sweep, false, progressPaint);

    final dotAngle = start + sweep;
    final dotCenter = Offset(
      center.dx + math.cos(dotAngle) * radius,
      center.dy + math.sin(dotAngle) * radius,
    );
    final dotPaint = Paint()..color = progressColor;
    canvas.drawCircle(dotCenter, stroke / 2.1, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _OrbitBadgePainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor;
  }
}
