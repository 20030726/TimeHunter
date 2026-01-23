import '../constants/timer_constants.dart';
import 'task_item.dart';
import 'timebox_entry.dart';

class DailyData {
  DailyData({
    required this.dateYmd,
    required this.slackUsed,
    required this.tasks,
    this.dailyNote = '',
    this.timeboxes = const [],
    this.updatedAtEpochMs = 0,
  });

  final String dateYmd;
  final int slackUsed;
  final List<TaskItem> tasks;
  final String dailyNote;
  final List<TimeboxEntry> timeboxes;
  final int updatedAtEpochMs;

  DailyData copyWith({
    int? slackUsed,
    List<TaskItem>? tasks,
    String? dailyNote,
    List<TimeboxEntry>? timeboxes,
    int? updatedAtEpochMs,
  }) {
    return DailyData(
      dateYmd: dateYmd,
      slackUsed: slackUsed ?? this.slackUsed,
      tasks: tasks ?? this.tasks,
      dailyNote: dailyNote ?? this.dailyNote,
      timeboxes: timeboxes ?? this.timeboxes,
      updatedAtEpochMs: updatedAtEpochMs ?? this.updatedAtEpochMs,
    );
  }

  int get slackRemaining {
    final remaining = TimerConstants.slackMax - slackUsed;
    return remaining < 0 ? 0 : remaining;
  }

  int get totalCycles => tasks.fold(0, (sum, t) => sum + t.totalCycles);

  int get completedCycles => tasks.fold(0, (sum, t) => sum + t.completedCycles);

  double get completionRatio {
    if (totalCycles <= 0) return 0;
    return completedCycles / totalCycles;
  }

  Map<String, Object?> toJson() {
    return {
      'dateYmd': dateYmd,
      'slackUsed': slackUsed,
      'tasks': tasks.map((t) => t.toJson()).toList(growable: false),
      'dailyNote': dailyNote,
      'timeboxes': timeboxes.map((t) => t.toJson()).toList(growable: false),
      'updatedAtEpochMs': updatedAtEpochMs,
    };
  }

  static DailyData fromJson(Map<String, Object?> json) {
    final tasksRaw = json['tasks'];
    final tasks = <TaskItem>[];
    if (tasksRaw is List) {
      for (final item in tasksRaw) {
        if (item is Map) {
          tasks.add(TaskItem.fromJson(item.cast<String, Object?>()));
        }
      }
    }

    final timeboxesRaw = json['timeboxes'];
    final timeboxes = <TimeboxEntry>[];
    if (timeboxesRaw is List) {
      for (final item in timeboxesRaw) {
        if (item is Map) {
          final entry = TimeboxEntry.fromJson(item.cast<String, Object?>());
          if (entry != null) timeboxes.add(entry);
        }
      }
    }

    return DailyData(
      dateYmd: (json['dateYmd'] as String?) ?? '',
      slackUsed: (json['slackUsed'] as num?)?.toInt() ?? 0,
      tasks: tasks,
      dailyNote: (json['dailyNote'] as String?) ?? '',
      timeboxes: timeboxes,
      updatedAtEpochMs: (json['updatedAtEpochMs'] as num?)?.toInt() ?? 0,
    );
  }
}
