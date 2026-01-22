import 'task_tag.dart';

class TimeboxEntry {
  TimeboxEntry({
    required this.id,
    required this.taskId,
    required this.taskTitle,
    required this.tag,
    required this.startEpochMs,
    required this.endEpochMs,
    required this.cycleMinutes,
    this.isPlanned = false,
  });

  final String id;
  final String taskId;
  final String taskTitle;
  final TaskTag tag;
  final int startEpochMs;
  final int endEpochMs;
  final int cycleMinutes;
  final bool isPlanned;

  Duration get duration => Duration(milliseconds: endEpochMs - startEpochMs);

  TimeboxEntry copyWith({
    String? id,
    String? taskId,
    String? taskTitle,
    TaskTag? tag,
    int? startEpochMs,
    int? endEpochMs,
    int? cycleMinutes,
    bool? isPlanned,
  }) {
    return TimeboxEntry(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      taskTitle: taskTitle ?? this.taskTitle,
      tag: tag ?? this.tag,
      startEpochMs: startEpochMs ?? this.startEpochMs,
      endEpochMs: endEpochMs ?? this.endEpochMs,
      cycleMinutes: cycleMinutes ?? this.cycleMinutes,
      isPlanned: isPlanned ?? this.isPlanned,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'taskId': taskId,
      'taskTitle': taskTitle,
      'tag': tag.name,
      'startEpochMs': startEpochMs,
      'endEpochMs': endEpochMs,
      'cycleMinutes': cycleMinutes,
      'isPlanned': isPlanned,
    };
  }

  static TimeboxEntry? fromJson(Map<String, Object?> json) {
    final id = json['id'] as String?;
    final taskId = json['taskId'] as String?;
    if (id == null || id.isEmpty || taskId == null || taskId.isEmpty) {
      return null;
    }

    final taskTitle = (json['taskTitle'] as String?) ?? '';
    final tagName = (json['tag'] as String?) ?? TaskTag.life.name;
    final startEpochMs = (json['startEpochMs'] as num?)?.toInt() ?? 0;
    final endEpochMs = (json['endEpochMs'] as num?)?.toInt() ?? 0;
    final cycleMinutes = (json['cycleMinutes'] as num?)?.toInt() ?? 0;
    final isPlanned = (json['isPlanned'] as bool?) ?? false;

    return TimeboxEntry(
      id: id,
      taskId: taskId,
      taskTitle: taskTitle,
      tag: TaskTagX.fromName(tagName),
      startEpochMs: startEpochMs,
      endEpochMs: endEpochMs,
      cycleMinutes: cycleMinutes,
      isPlanned: isPlanned,
    );
  }
}
