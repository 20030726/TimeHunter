import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../core/constants/timer_constants.dart';
import '../../core/models/active_timer_state.dart';
import '../../core/models/daily_data.dart'; // Will be used by DailyController
import '../../core/models/task_item.dart'; // Will be used by DailyController
import '../../core/utils/iterable_ext.dart';
import '../../services/audio/audio_controller.dart'; // To be created
import '../../services/device/haptic_controller.dart'; // To be created
import '../../features/today/daily_controller.dart'; // Existing

// Define the state that TimerController will manage
class TimerState {
  final String? taskId;
  final int remainingSeconds;
  final bool isRunning;
  final int cycleMinutes;
  final int? endsAtEpochMs;
  final int? cycleStartedAtEpochMs;
  final String? plannedTimeboxId;

  TimerState({
    this.taskId,
    this.remainingSeconds = 0,
    this.isRunning = false,
    this.cycleMinutes = TimerConstants.defaultCycleMinutes,
    this.endsAtEpochMs,
    this.cycleStartedAtEpochMs,
    this.plannedTimeboxId,
  });

  TimerState copyWith({
    String? taskId,
    int? remainingSeconds,
    bool? isRunning,
    int? cycleMinutes,
    int? endsAtEpochMs,
    int? cycleStartedAtEpochMs,
    String? plannedTimeboxId,
  }) {
    return TimerState(
      taskId: taskId ?? this.taskId,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isRunning: isRunning ?? this.isRunning,
      cycleMinutes: cycleMinutes ?? this.cycleMinutes,
      endsAtEpochMs: endsAtEpochMs ?? this.endsAtEpochMs,
      cycleStartedAtEpochMs: cycleStartedAtEpochMs ?? this.cycleStartedAtEpochMs,
      plannedTimeboxId: plannedTimeboxId ?? this.plannedTimeboxId,
    );
  }
}

// TimerController will be an AsyncNotifier because it performs async operations (persistence, daily data calls)
class TimerController extends AsyncNotifier<TimerState> {
  Timer? _timer;

  @override
  FutureOr<TimerState> build() async {
    ref.onDispose(() {
      _timer?.cancel();
    });
    // Load initial state from repository
    final savedState = await ref.read(timerRepositoryProvider).load();
    if (savedState != null) {
      final initialTimerState = TimerState(
        taskId: savedState.taskId,
        remainingSeconds: savedState.remainingSeconds,
        isRunning: savedState.isRunning,
        cycleMinutes: savedState.cycleMinutes,
        endsAtEpochMs: savedState.endsAtEpochMs,
        cycleStartedAtEpochMs: savedState.startedAtEpochMs,
        plannedTimeboxId: savedState.plannedTimeboxId,
      );

      // If timer was running, try to sync from endsAtEpochMs
      if (initialTimerState.isRunning && initialTimerState.endsAtEpochMs != null) {
        _syncFromEndsAt(initialTimerState.endsAtEpochMs!, current: initialTimerState);
        _startTicker();
      }
      return initialTimerState;
    }
    return TimerState();
  }

  // --- Private Helper Methods ---
  void _syncFromEndsAt(int endsAtEpochMs, {TimerState? current}) {
    final baseState = current ?? state.value;
    if (baseState == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = ((endsAtEpochMs - now) / 1000).ceil();

    if (diff <= 0) {
      state = AsyncValue.data(baseState.copyWith(
        remainingSeconds: 0,
        isRunning: false,
        endsAtEpochMs: null,
      ));
      _handleFinished();
      return;
    }

    state = AsyncValue.data(baseState.copyWith(remainingSeconds: diff));
  }

  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final current = state.value;
      if (current == null) return;
      if (current.isRunning && current.endsAtEpochMs != null) {
        _syncFromEndsAt(current.endsAtEpochMs!);
      } else {
        _timer?.cancel();
      }
    });
  }

  // --- Public Methods (Business Logic) ---

  Future<void> start(String taskId, TaskItem task) async {
    // state = AsyncValue.loading(); // Could add loading state if UI needs it
    final currentTimerState = state.value!;

    ref.read(audioControllerProvider.notifier).playStartSound(); // Use AudioController

    final remaining = (currentTimerState.remainingSeconds <= 0)
        ? (currentTimerState.cycleMinutes * 60)
        : currentTimerState.remainingSeconds;

    final now = DateTime.now().millisecondsSinceEpoch;
    final cycleStartedAt = currentTimerState.cycleStartedAtEpochMs ?? now;
    final endsAt = now + (remaining * 1000);

    state = AsyncValue.data(currentTimerState.copyWith(
      taskId: taskId,
      isRunning: true,
      remainingSeconds: remaining,
      endsAtEpochMs: endsAt,
      cycleStartedAtEpochMs: cycleStartedAt,
    ));

    await _ensurePlannedTimebox(taskId, remaining, cycleStartedAt);
    await _persistTimer();
    _startTicker();
  }

  Future<void> pause() async {
    _timer?.cancel();
    ref.read(audioControllerProvider.notifier).stopBackgroundAudio(); // Use AudioController

    final currentTimerState = state.value!;
    final remaining = currentTimerState.remainingSeconds;

    state = AsyncValue.data(currentTimerState.copyWith(
      isRunning: false,
      endsAtEpochMs: null,
    ));

    final taskId = currentTimerState.taskId;
    final startedAt = currentTimerState.cycleStartedAtEpochMs;
    if (taskId != null && startedAt != null) {
      await _ensurePlannedTimebox(taskId, remaining, startedAt);
    }
    await _persistTimer();
  }

  Future<void> _handleFinished() async {
    _timer?.cancel();
    ref.read(audioControllerProvider.notifier).stopBackgroundAudio(); // Use AudioController

    final currentTimerState = state.value!;
    final taskId = currentTimerState.taskId;

    // Get the task state *before* completing the cycle.
    final dailyBefore = ref.read(dailyControllerProvider).valueOrNull;
    final taskBefore =
        dailyBefore?.tasks.where((t) => t.id == taskId).firstOrNull;
    final wasAlreadyDone = taskBefore?.isDone ?? false;

    final endTime = DateTime.now();

    state = AsyncValue.data(currentTimerState.copyWith(
      remainingSeconds: 0,
      isRunning: false,
      endsAtEpochMs: null,
      // showSuccess is a UI state, will be handled by UI
    ));

    await _clearTimer(); // Clear active timer state from repo

    ref.read(hapticControllerProvider.notifier).vibrate(); // Use HapticController

    if (taskId == null) {
      await ref.read(audioControllerProvider.notifier).playCompletionSound();
      return;
    }

    final notifier = ref.read(dailyControllerProvider.notifier);
    await notifier.completeOneCycle(taskId);

    // Get the task state *after* completing the cycle.
    final dailyAfter = ref.read(dailyControllerProvider).valueOrNull;
    final taskAfter =
        dailyAfter?.tasks.where((t) => t.id == taskId).firstOrNull;

    if (taskAfter != null) {
      // Log the timebox entry
      final startedAtEpochMs = currentTimerState.cycleStartedAtEpochMs;
      final startedAt = startedAtEpochMs == null
          ? endTime.subtract(Duration(minutes: currentTimerState.cycleMinutes))
          : DateTime.fromMillisecondsSinceEpoch(startedAtEpochMs);
      await notifier.logTimebox(
        task: taskAfter,
        startedAt: startedAt,
        endedAt: endTime,
        plannedEntryId: currentTimerState.plannedTimeboxId,
      );

      // Check if the task was just completed with this cycle
      if (!wasAlreadyDone && taskAfter.isDone) {
        await ref.read(audioControllerProvider.notifier).playBigTaskCompletionSound();
      } else {
        await ref.read(audioControllerProvider.notifier).playCompletionSound();
      }
    } else {
      // Fallback if task is not found
      await ref.read(audioControllerProvider.notifier).playCompletionSound();
    }

    // Reset cycle tracking after a short delay (UI can handle success animation)
    Future.delayed(const Duration(milliseconds: 850), () {
      state = AsyncValue.data(currentTimerState.copyWith(
        cycleStartedAtEpochMs: null,
        plannedTimeboxId: null,
      ));
    });
  }

  Future<void> _persistTimer() async {
    final currentTimerState = state.value!;
    final taskId = currentTimerState.taskId;
    if (taskId == null) return;
    final repo = ref.read(timerRepositoryProvider);

    final activeState = ActiveTimerState(
      taskId: taskId,
      cycleMinutes: currentTimerState.cycleMinutes,
      isRunning: currentTimerState.isRunning,
      remainingSeconds: currentTimerState.remainingSeconds,
      endsAtEpochMs: currentTimerState.endsAtEpochMs,
      startedAtEpochMs: currentTimerState.cycleStartedAtEpochMs,
      plannedTimeboxId: currentTimerState.plannedTimeboxId,
    );

    await repo.save(activeState);
  }

  Future<void> _clearTimer() async {
    await ref.read(timerRepositoryProvider).clear();
  }

  Future<void> _ensurePlannedTimebox(String taskId, int remainingSeconds, int startedAtEpochMs) async {
    final dailyValue = ref.read(dailyControllerProvider).valueOrNull;
    final DailyData daily = dailyValue ?? await ref.read(dailyControllerProvider.future);
    final task = daily.tasks.where((t) => t.id == taskId).firstOrNull;
    if (task == null) return;

    final startTime = DateTime.fromMillisecondsSinceEpoch(startedAtEpochMs);
    final endTime = startTime.add(Duration(seconds: remainingSeconds));

    final currentState = state.value;
    if (currentState == null) return;

    final plannedId = currentState.plannedTimeboxId;
    if (plannedId != null) {
      final existing =
          daily.timeboxes.where((entry) => entry.id == plannedId).firstOrNull;
      if (existing == null) return;
      await ref.read(dailyControllerProvider.notifier).updateTimebox(
        existing.copyWith(
          startEpochMs: startedAtEpochMs,
          endEpochMs: endTime.millisecondsSinceEpoch,
          cycleMinutes: endTime.difference(startTime).inMinutes.abs(),
          isPlanned: true,
        ),
      );
      state = AsyncValue.data(currentState.copyWith(plannedTimeboxId: plannedId));
      return;
    }

    final newPlannedId = await ref
        .read(dailyControllerProvider.notifier)
        .addPlannedTimebox(
      task: task,
      startedAt: startTime,
      endedAt: endTime,
    );
    state = AsyncValue.data(currentState.copyWith(plannedTimeboxId: newPlannedId));
  }

  Future<void> slack15() async {
    final daily = await ref.read(dailyControllerProvider.future);
    if (daily.slackRemaining <= 0) return;

    ref.read(hapticControllerProvider.notifier).selectionClick(); // Use HapticController

    await ref.read(dailyControllerProvider.notifier).useSlackTicket();

    final currentTimerState = state.value!;
    final base = currentTimerState.remainingSeconds;
    final newRemainingSeconds = base + (TimerConstants.slackMinutes * 60);

    state = AsyncValue.data(currentTimerState.copyWith(remainingSeconds: newRemainingSeconds));

    if (currentTimerState.isRunning) {
      final now = DateTime.now().millisecondsSinceEpoch;
      state = AsyncValue.data(state.value!.copyWith(endsAtEpochMs: now + (newRemainingSeconds * 1000)));
    }

    await _persistTimer();
  }

  void updateCycleMinutes(int newCycleMinutes) {
    final currentTimerState = state.value!;
    state = AsyncValue.data(currentTimerState.copyWith(
      cycleMinutes: newCycleMinutes,
      remainingSeconds: newCycleMinutes * 60, // Reset remaining seconds when cycle minutes change
    ));
    _persistTimer(); // Persist the new cycle minutes
  }
}

final timerStateProvider = AsyncNotifierProvider<TimerController, TimerState>(
  TimerController.new,
);
