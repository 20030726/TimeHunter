import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/utils/dates.dart';
import '../settings/plan_reminder_controller.dart';
import 'add_task_dialog.dart';

class PlanReminderListener extends ConsumerStatefulWidget {
  const PlanReminderListener({super.key});

  @override
  ConsumerState<PlanReminderListener> createState() =>
      _PlanReminderListenerState();
}

class _PlanReminderListenerState extends ConsumerState<PlanReminderListener>
    with WidgetsBindingObserver {
  Timer? _timer;
  String? _lastPromptKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ref.listenManual(
      planReminderProvider,
      (previous, next) => _scheduleReminder(),
    );
    _scheduleReminder();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _scheduleReminder();
    }
  }

  void _scheduleReminder() {
    _timer?.cancel();
    final settings = ref.read(planReminderProvider).valueOrNull;
    if (settings == null || !settings.enabled) return;

    final now = DateTime.now();
    final time = settings.timeOfDay;
    final target = DateTime(now.year, now.month, now.day, time.hour, time.minute);

    if (now.isAfter(target)) {
      unawaited(_maybePrompt());
      final next = target.add(const Duration(days: 1));
      _timer = Timer(next.difference(now), _handleTimer);
    } else {
      _timer = Timer(target.difference(now), _handleTimer);
    }
  }

  void _handleTimer() {
    unawaited(_maybePrompt());
    _scheduleReminder();
  }

  Future<void> _maybePrompt() async {
    if (!mounted) return;
    final now = DateTime.now();
    final todayKey = ymd(dateOnly(now));
    if (_lastPromptKey == todayKey) return;

    final tomorrow = dateOnly(now.add(const Duration(days: 1)));
    final planned = await ref
        .read(plannedTaskRepositoryProvider)
        .loadForDate(ymd(tomorrow));
    final existing = await ref.read(dailyRepositoryProvider).loadExisting(
          tomorrow,
        );
    if (planned.isNotEmpty || (existing?.tasks.isNotEmpty ?? false)) {
      return;
    }

    _lastPromptKey = todayKey;
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: const Text('晚安，要先規劃明天的任務嗎？'),
          action: SnackBarAction(
            label: '規劃明天',
            onPressed: () {
              showAddTaskDialog(
                context: context,
                initialRange: DateTimeRange(
                  start: tomorrow,
                  end: tomorrow,
                ),
              );
            },
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
