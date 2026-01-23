import 'task_tag.dart';

class PlannedTask {
  PlannedTask({
    required this.id,
    required this.title,
    required this.tag,
    required this.totalCycles,
    required this.cycleMinutes,
    required this.plannedDates,
    required this.plannedCycles,
    this.note,
    this.createdAtEpochMs = 0,
    this.updatedAtEpochMs = 0,
  });

  final String id;
  final String title;
  final TaskTag tag;
  final int totalCycles;
  final int cycleMinutes;
  final List<String> plannedDates;
  final List<int> plannedCycles;
  final String? note;
  final int createdAtEpochMs;
  final int updatedAtEpochMs;

  PlannedTask copyWith({
    String? title,
    TaskTag? tag,
    int? totalCycles,
    int? cycleMinutes,
    List<String>? plannedDates,
    List<int>? plannedCycles,
    String? note,
    int? createdAtEpochMs,
    int? updatedAtEpochMs,
  }) {
    return PlannedTask(
      id: id,
      title: title ?? this.title,
      tag: tag ?? this.tag,
      totalCycles: totalCycles ?? this.totalCycles,
      cycleMinutes: cycleMinutes ?? this.cycleMinutes,
      plannedDates: plannedDates ?? this.plannedDates,
      plannedCycles: plannedCycles ?? this.plannedCycles,
      note: note ?? this.note,
      createdAtEpochMs: createdAtEpochMs ?? this.createdAtEpochMs,
      updatedAtEpochMs: updatedAtEpochMs ?? this.updatedAtEpochMs,
    );
  }

  int cyclesForDate(String dateYmd) {
    final index = plannedDates.indexOf(dateYmd);
    if (index < 0) return 0;
    if (index >= plannedCycles.length) return totalCycles;
    return plannedCycles[index];
  }

  PlannedTask removeDate(String dateYmd) {
    final index = plannedDates.indexOf(dateYmd);
    if (index < 0) return this;

    final updatedDates = [...plannedDates]..removeAt(index);
    final updatedCycles = [...plannedCycles];
    if (index < updatedCycles.length) {
      updatedCycles.removeAt(index);
    }

    final updatedTotal = updatedCycles.fold<int>(0, (sum, v) => sum + v);

    return copyWith(
      plannedDates: updatedDates,
      plannedCycles: updatedCycles,
      totalCycles: updatedTotal,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'title': title,
      'tag': tag.name,
      'totalCycles': totalCycles,
      'cycleMinutes': cycleMinutes,
      'plannedDates': plannedDates,
      'plannedCycles': plannedCycles,
      'note': note,
      'createdAtEpochMs': createdAtEpochMs,
      'updatedAtEpochMs': updatedAtEpochMs,
    };
  }

  static PlannedTask fromJson(Map<String, Object?> json) {
    final plannedDatesRaw = json['plannedDates'];
    final plannedDates = <String>[];
    if (plannedDatesRaw is List) {
      for (final item in plannedDatesRaw) {
        if (item is String) plannedDates.add(item);
      }
    }

    final plannedCyclesRaw = json['plannedCycles'];
    final plannedCycles = <int>[];
    if (plannedCyclesRaw is List) {
      for (final item in plannedCyclesRaw) {
        if (item is num) plannedCycles.add(item.toInt());
      }
    }

    final totalCycles = (json['totalCycles'] as num?)?.toInt() ?? 0;
    final normalizedCycles = _normalizeCycles(
      plannedCycles,
      plannedDates.length,
      totalCycles,
    );

    return PlannedTask(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      tag: TaskTagX.fromName((json['tag'] as String?) ?? TaskTag.life.name),
      totalCycles: totalCycles,
      cycleMinutes: (json['cycleMinutes'] as num?)?.toInt() ?? 0,
      plannedDates: plannedDates,
      plannedCycles: normalizedCycles,
      note: json['note'] as String?,
      createdAtEpochMs: (json['createdAtEpochMs'] as num?)?.toInt() ?? 0,
      updatedAtEpochMs: (json['updatedAtEpochMs'] as num?)?.toInt() ?? 0,
    );
  }

  static List<int> distributeCycles(int totalCycles, int days) {
    if (days <= 0) return const [];
    final base = totalCycles ~/ days;
    final remainder = totalCycles % days;
    return List<int>.generate(
      days,
      (index) => base + (index < remainder ? 1 : 0),
    );
  }

  static List<int> _normalizeCycles(
    List<int> cycles,
    int plannedDays,
    int totalCycles,
  ) {
    if (plannedDays <= 0) return const [];
    if (cycles.length == plannedDays) return cycles;
    return distributeCycles(totalCycles, plannedDays);
  }
}
