import '../constants/timer_constants.dart';

class ActiveTimerState {
  ActiveTimerState({
    required this.taskId,
    required this.cycleMinutes,
    required this.isRunning,
    required this.remainingSeconds,
    required this.endsAtEpochMs,
    required this.startedAtEpochMs,
    required this.plannedTimeboxId,
  });

  final String taskId;
  final int cycleMinutes;
  final bool isRunning;

  /// Used when paused; when running we still keep it for display fallback.
  final int remainingSeconds;

  /// When running, compute remaining = endsAt - now.
  final int? endsAtEpochMs;

  /// Start timestamp for the current cycle (used for timebox logs).
  final int? startedAtEpochMs;

  /// Planned timebox entry id for this cycle.
  final String? plannedTimeboxId;

  Map<String, Object?> toJson() {
    return {
      'taskId': taskId,
      'cycleMinutes': cycleMinutes,
      'isRunning': isRunning,
      'remainingSeconds': remainingSeconds,
      'endsAtEpochMs': endsAtEpochMs,
      'startedAtEpochMs': startedAtEpochMs,
      'plannedTimeboxId': plannedTimeboxId,
    };
  }

  static ActiveTimerState? fromJson(Map<String, Object?> json) {
    final taskId = json['taskId'] as String?;
    if (taskId == null || taskId.isEmpty) return null;

    return ActiveTimerState(
      taskId: taskId,
      cycleMinutes: (json['cycleMinutes'] as num?)?.toInt() ??
          TimerConstants.defaultCycleMinutes,
      isRunning: (json['isRunning'] as bool?) ?? false,
      remainingSeconds: (json['remainingSeconds'] as num?)?.toInt() ?? 0,
      endsAtEpochMs: (json['endsAtEpochMs'] as num?)?.toInt(),
      startedAtEpochMs: (json['startedAtEpochMs'] as num?)?.toInt(),
      plannedTimeboxId: json['plannedTimeboxId'] as String?,
    );
  }
}
