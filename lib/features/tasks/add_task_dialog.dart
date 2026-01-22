import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/timer_constants.dart';
import '../../core/models/task_tag.dart';
import '../today/daily_controller.dart';

Future<void> showAddTaskDialog({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  // Defer dialog until after current pointer update to avoid mouse tracker re-entrancy.
  await Future<void>.delayed(Duration.zero);
  if (!context.mounted) return;

  final titleController = TextEditingController();
  var tag = TaskTag.study;
  var totalCycles = TimerConstants.defaultTotalCycles;
  var cycleMinutes = TimerConstants.defaultCycleMinutes;
  final cycleOptions = TimerConstants.cycleMinuteOptions;

  try {
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
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.label),
                          ),
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
                      Text('$totalCycles'),
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

                    await ref.read(dailyControllerProvider.notifier).addTask(
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
  } finally {
    titleController.dispose();
  }
}
