enum TaskTag { urgent, study, workout, life }

extension TaskTagX on TaskTag {
  String get label {
    switch (this) {
      case TaskTag.urgent:
        return '緊急';
      case TaskTag.study:
        return '學習';
      case TaskTag.workout:
        return '運動';
      case TaskTag.life:
        return '生活';
    }
  }

  /// ARGB color value (kept Flutter-free).
  int get colorValue {
    switch (this) {
      case TaskTag.urgent:
        return 0xFFEF4444; // red-500
      case TaskTag.study:
        return 0xFF3B82F6; // blue-500
      case TaskTag.workout:
        return 0xFF10B981; // emerald-500
      case TaskTag.life:
        return 0xFFF59E0B; // amber-500
    }
  }

  static TaskTag fromName(String name) {
    return TaskTag.values.firstWhere(
      (tag) => tag.name == name,
      orElse: () => TaskTag.life,
    );
  }
}
