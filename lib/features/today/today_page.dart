import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/constants/timer_constants.dart';
import '../../core/models/task_tag.dart';
import '../../core/utils/dates.dart';
import '../../widgets/glow_progress_bar.dart';
import '../settings/variant_settings_controller.dart';
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTaskDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('新增任務'),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.background,
      ),
      body: dailyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (daily) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _DailyProgressHeader(
                  slackRemaining: daily.slackRemaining,
                  completionRatio: daily.completionRatio,
                  completedCycles: daily.completedCycles,
                  totalCycles: daily.totalCycles,
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ReorderableListView.builder(
                    itemCount: daily.tasks.length,
                    buildDefaultDragHandles: false,
                    onReorderStart: (_) {
                      HapticFeedback.selectionClick();
                    },
                    onReorder: (oldIndex, newIndex) {
                      ref
                          .read(dailyControllerProvider.notifier)
                          .reorderTasks(oldIndex, newIndex);
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
                      final task = daily.tasks[index];
                      final tagColor = Color(task.tag.colorValue);

                      return ReorderableDelayedDragStartListener(
                        key: ValueKey(task.id),
                        index: index,
                        child: Dismissible(
                          key: ValueKey('dismiss-${task.id}'),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (_) =>
                              _confirmDelete(context, task.title),
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
                                            alpha: task.tag == TaskTag.urgent
                                                ? 0.9
                                                : 0.55,
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
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
                                                      fontWeight:
                                                          FontWeight.w600,
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
                                                    final action =
                                                        await _showTaskMenu(
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
                                                    : task.completedCycles /
                                                          task.totalCycles,
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
                                          style: _actionButtonStyle(
                                            task.tag,
                                            tagColor,
                                          ),
                                          onPressed: task.isDone
                                              ? null
                                              : () {
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          HuntTimerPage(
                                                            taskId: task.id,
                                                            variant: variant,
                                                          ),
                                                    ),
                                                  );
                                                },
                                          child: Text(
                                            task.isDone ? '已完成' : '開獵',
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
                      );
                    },
                  ),
                ),
              ],
            ),
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

  Future<void> _showAddTaskDialog(BuildContext context, WidgetRef ref) async {
    final titleController = TextEditingController();
    var tag = TaskTag.study;
    var totalCycles = TimerConstants.defaultTotalCycles;
    var cycleMinutes = TimerConstants.defaultCycleMinutes;
    final cycleOptions = TimerConstants.cycleMinuteOptions;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('新增任務'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    autofocus: true,
                    style: const TextStyle(color: AppColors.textPrimary),
                    cursorColor: AppColors.accent,
                    decoration: const InputDecoration(
                      labelText: '名稱',
                      hintText: '例如：寫論文/慢跑/整理',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<TaskTag>(
                    initialValue: tag,
                    decoration: const InputDecoration(labelText: '標籤'),
                    items: TaskTag.values
                        .map(
                          (t) =>
                              DropdownMenuItem(value: t, child: Text(t.label)),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => tag = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('輪數'),
                      const Spacer(),
                      IconButton(
                        onPressed: totalCycles <= TimerConstants.minTotalCycles
                            ? null
                            : () => setState(() => totalCycles -= 1),
                        icon: const Icon(Icons.remove),
                      ),
                      Text(
                        '$totalCycles',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        onPressed: totalCycles >= TimerConstants.maxTotalCycles
                            ? null
                            : () => setState(() => totalCycles += 1),
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('Cycle 時長'),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Slider(
                          value: cycleOptions.indexOf(cycleMinutes).toDouble(),
                          min: 0,
                          max: (cycleOptions.length - 1).toDouble(),
                          divisions: cycleOptions.length - 1,
                          label: '$cycleMinutes 分鐘',
                          onChanged: (value) {
                            setState(() {
                              cycleMinutes = cycleOptions[value.round()];
                            });
                          },
                        ),
                      ),
                      SizedBox(width: 52, child: Text('${cycleMinutes}m')),
                    ],
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
                    final title = titleController.text;
                    if (title.trim().isEmpty) return;

                    await ref
                        .read(dailyControllerProvider.notifier)
                        .addTask(
                          title: title,
                          tag: tag,
                          totalCycles: totalCycles,
                          cycleMinutes: cycleMinutes,
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

    titleController.dispose();
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
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
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
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${(completionRatio * 100).round()}%',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
