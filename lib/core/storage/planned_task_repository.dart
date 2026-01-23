import 'dart:convert';

import '../models/planned_task.dart';
import 'hive_boxes.dart';
import '../../services/storage/hive_service.dart';

abstract class PlannedTaskRepository {
  Future<List<PlannedTask>> loadAll();
  Future<List<PlannedTask>> loadForDate(String dateYmd);
  Future<void> save(PlannedTask task);
  Future<void> remove(String id);
}

class HivePlannedTaskRepository implements PlannedTaskRepository {
  HivePlannedTaskRepository(this._box);

  final HiveBoxStore _box;

  static Future<HivePlannedTaskRepository> open(HiveService hive) async {
    final box = await hive.openBox(HiveBoxes.plannedTasks);
    return HivePlannedTaskRepository(box);
  }

  @override
  Future<List<PlannedTask>> loadAll() async {
    final tasks = <PlannedTask>[];
    for (final key in _box.keys()) {
      final raw = _box.read(key);
      if (raw == null) continue;

      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          tasks.add(PlannedTask.fromJson(decoded.cast<String, Object?>()));
        }
      } catch (_) {
        // ignore malformed rows
      }
    }

    return tasks;
  }

  @override
  Future<List<PlannedTask>> loadForDate(String dateYmd) async {
    final all = await loadAll();
    return all
        .where((task) => task.plannedDates.contains(dateYmd))
        .toList(growable: false);
  }

  @override
  Future<void> save(PlannedTask task) async {
    final encoded = jsonEncode(task.toJson());
    await _box.write(task.id, encoded);
  }

  @override
  Future<void> remove(String id) async {
    await _box.delete(id);
  }
}
