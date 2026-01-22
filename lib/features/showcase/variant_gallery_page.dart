import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/daily_data.dart';
import '../../core/models/task_item.dart';
import '../settings/settings_page.dart';
import '../settings/variant_settings_controller.dart';
import '../tasks/add_task_dialog.dart';
import '../timer/hunt_timer_page.dart';
import '../today/daily_controller.dart';
import 'variant_layouts.dart';

class VariantHomePage extends ConsumerStatefulWidget {
  const VariantHomePage({super.key});

  @override
  ConsumerState<VariantHomePage> createState() => _VariantHomePageState();
}

class _VariantHomePageState extends ConsumerState<VariantHomePage> {
  late final ValueNotifier<int> _countdown;
  ProviderSubscription<AsyncValue<DailyData>>? _dailySub;

  @override
  void initState() {
    super.initState();
    _countdown = ValueNotifier<int>(0);
    _dailySub = ref.listenManual<AsyncValue<DailyData>>(
      dailyControllerProvider,
      (_, next) {
        final daily = next.valueOrNull;
        if (daily == null) return;
        _syncCountdownFromDaily(daily);
      },
    );
  }

  @override
  void dispose() {
    _dailySub?.close();
    _countdown.dispose();
    super.dispose();
  }

  void _syncCountdownFromDaily(DailyData daily) {
    if (daily.tasks.isEmpty) {
      if (_countdown.value != 0) {
        _countdown.value = 0;
      }
      return;
    }

    final task = daily.tasks.firstWhere(
      (task) => !task.isDone,
      orElse: () => daily.tasks.first,
    );
    final next = task.cycleMinutes * 60;
    if (_countdown.value != next) {
      _countdown.value = next;
    }
  }

  Future<void> _showAddTaskDialog() async {
    await showAddTaskDialog(context: context, ref: ref);
  }

  void _startTask(TaskItem task, HuntVariant variant) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HuntTimerPage(taskId: task.id, variant: variant),
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final variantAsync = ref.watch(variantSettingsProvider);
    final dailyAsync = ref.watch(dailyControllerProvider);

    return variantAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (variant) {
        return Scaffold(
          body: dailyAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (daily) {
              final data = VariantData(
                daily: daily,
                tasks: daily.tasks,
                countdown: _countdown,
                onAddTask: _showAddTaskDialog,
                onStartTask: (task) => _startTask(task, variant),
                onTriggerCompletion: () {},
              );

              return Stack(
                children: [
                  VariantLayouts.build(variant: variant, data: data),
                  _SettingsButton(onPressed: _openSettings),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _SettingsButton extends StatelessWidget {
  const _SettingsButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: IconButton(
              tooltip: '設定',
              onPressed: onPressed,
              icon: const Icon(Icons.settings),
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
