import '../constants/timer_constants.dart';
import 'task_tag.dart';

class TaskItem {
  TaskItem({
    required this.id,
    required this.title,
    required this.tag,
    required this.totalCycles,
    required this.completedCycles,
    required this.cycleMinutes,
    this.backgroundMusic,
    this.note,
    this.plannedSourceId,
  });

  final String id;
  final String title;
  final TaskTag tag;
  final int totalCycles;
  final int completedCycles;
  final int cycleMinutes;
  final String? backgroundMusic;
  final String? note;
  final String? plannedSourceId;

  TaskItem copyWith({
    String? title,
    TaskTag? tag,
    int? totalCycles,
    int? completedCycles,
    int? cycleMinutes,
    String? backgroundMusic,
    String? note,
    String? plannedSourceId,
  }) {
    return TaskItem(
      id: id,
      title: title ?? this.title,
      tag: tag ?? this.tag,
      totalCycles: totalCycles ?? this.totalCycles,
      completedCycles: completedCycles ?? this.completedCycles,
      cycleMinutes: cycleMinutes ?? this.cycleMinutes,
      backgroundMusic: backgroundMusic ?? this.backgroundMusic,
      note: note ?? this.note,
      plannedSourceId: plannedSourceId ?? this.plannedSourceId,
    );
  }

  bool get isDone => completedCycles >= totalCycles;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'title': title,
      'tag': tag.name,
      'totalCycles': totalCycles,
      'completedCycles': completedCycles,
      'cycleMinutes': cycleMinutes,
      'backgroundMusic': backgroundMusic,
      'note': note,
      'plannedSourceId': plannedSourceId,
    };
  }

  static TaskItem fromJson(Map<String, Object?> json) {
    return TaskItem(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      tag: TaskTagX.fromName((json['tag'] as String?) ?? TaskTag.life.name),
      totalCycles: (json['totalCycles'] as num?)?.toInt() ??
          TimerConstants.minTotalCycles,
      completedCycles: (json['completedCycles'] as num?)?.toInt() ?? 0,
      cycleMinutes: (json['cycleMinutes'] as num?)?.toInt() ??
          TimerConstants.defaultCycleMinutes,
      backgroundMusic: json['backgroundMusic'] as String?,
      note: json['note'] as String?,
      plannedSourceId: json['plannedSourceId'] as String?,
    );
  }
}
