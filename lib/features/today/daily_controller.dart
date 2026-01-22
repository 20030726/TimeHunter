import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../app/providers.dart';
import '../../core/models/daily_data.dart';
import '../../core/models/task_item.dart';
import '../../core/models/task_tag.dart';
import '../../core/models/timebox_entry.dart';
import '../../core/utils/dates.dart';

final selectedDateProvider = StateProvider<DateTime>((ref) {
  return dateOnly(DateTime.now());
});

final dailyControllerProvider =
    AsyncNotifierProvider<DailyController, DailyData>(DailyController.new);

class DailyController extends AsyncNotifier<DailyData> {
  Future<void> _persist(DailyData data) async {
    final stamped = data.copyWith(
      updatedAtEpochMs: DateTime.now().millisecondsSinceEpoch,
    );
    state = AsyncData(stamped);
    await ref.read(dailyRepositoryProvider).save(stamped);
  }

  @override
  Future<DailyData> build() async {
    final date = ref.watch(selectedDateProvider);
    final repo = ref.watch(dailyRepositoryProvider);
    return repo.load(date);
  }

  Future<void> addTask({
    required String title,
    required TaskTag tag,
    required int totalCycles,
    required int cycleMinutes,
    String? backgroundMusic,
  }) async {
    final current = await future;
    const uuid = Uuid();

    final updatedTasks = [
      ...current.tasks,
      TaskItem(
        id: uuid.v4(),
        title: title.trim(),
        tag: tag,
        totalCycles: totalCycles,
        completedCycles: 0,
        cycleMinutes: cycleMinutes,
        backgroundMusic: backgroundMusic,
      ),
    ];

    final updated = current.copyWith(tasks: updatedTasks);
    await _persist(updated);
  }

  Future<void> reorderTasks(int oldIndex, int newIndex) async {
    final current = await future;
    final tasks = [...current.tasks];

    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final item = tasks.removeAt(oldIndex);
    tasks.insert(newIndex, item);

    final updated = current.copyWith(tasks: tasks);
    await _persist(updated);
  }

  Future<void> completeOneCycle(String taskId) async {
    final current = await future;

    final tasks = current.tasks
        .map((task) {
          if (task.id != taskId) return task;
          if (task.completedCycles >= task.totalCycles) return task;
          return task.copyWith(completedCycles: task.completedCycles + 1);
        })
        .toList(growable: false);

    final updated = current.copyWith(tasks: tasks);
    await _persist(updated);
  }

  Future<void> updateCycleMinutes(String taskId, int minutes) async {
    final current = await future;

    final tasks = current.tasks
        .map((task) {
          if (task.id != taskId) return task;
          return task.copyWith(cycleMinutes: minutes);
        })
        .toList(growable: false);

    final updated = current.copyWith(tasks: tasks);
    await _persist(updated);
  }

  Future<void> updateBackgroundMusic(String taskId, String? music) async {
    final current = await future;

    final tasks = current.tasks
        .map((task) {
          if (task.id != taskId) return task;
          return task.copyWith(backgroundMusic: music);
        })
        .toList(growable: false);

    final updated = current.copyWith(tasks: tasks);
    await _persist(updated);
  }

  Future<TaskItem?> removeTask(String taskId) async {
    final current = await future;
    final index = current.tasks.indexWhere((t) => t.id == taskId);
    if (index < 0) return null;

    final tasks = [...current.tasks];
    final removed = tasks.removeAt(index);

    final updated = current.copyWith(tasks: tasks);
    await _persist(updated);

    return removed;
  }

  Future<void> insertTask(TaskItem task, {int? index}) async {
    final current = await future;
    final tasks = [...current.tasks];

    final i = (index ?? tasks.length).clamp(0, tasks.length);
    tasks.insert(i, task);

    final updated = current.copyWith(tasks: tasks);
    await _persist(updated);
  }

  Future<void> useSlackTicket() async {
    final current = await future;
    if (current.slackRemaining <= 0) return;

    final updated = current.copyWith(slackUsed: current.slackUsed + 1);
    await _persist(updated);
  }

  Future<void> logTimebox({
    required TaskItem task,
    required DateTime startedAt,
    required DateTime endedAt,
    String? plannedEntryId,
  }) async {
    final current = await future;
    const uuid = Uuid();

    final startMs = startedAt.millisecondsSinceEpoch;
    final endMs = endedAt.millisecondsSinceEpoch;
    final durationMinutes = endedAt.difference(startedAt).inMinutes.abs();

    var plannedIndex = -1;
    if (plannedEntryId != null) {
      plannedIndex = current.timeboxes
          .indexWhere((entry) => entry.id == plannedEntryId);
    }
    plannedIndex = plannedIndex != -1
        ? plannedIndex
        : current.timeboxes.indexWhere((entry) {
          if (!entry.isPlanned) return false;
          if (entry.taskId != task.id) return false;
          return entry.startEpochMs <= endMs && entry.endEpochMs >= startMs;
        });

    if (plannedIndex != -1) {
      final updatedEntries = [...current.timeboxes];
      final existing = updatedEntries[plannedIndex];
      updatedEntries[plannedIndex] = existing.copyWith(
        startEpochMs: startMs,
        endEpochMs: endMs,
        cycleMinutes: durationMinutes,
        isPlanned: false,
      );

      final updated = current.copyWith(timeboxes: updatedEntries);
      await _persist(updated);
      return;
    }

    final entry = TimeboxEntry(
      id: uuid.v4(),
      taskId: task.id,
      taskTitle: task.title,
      tag: task.tag,
      startEpochMs: startMs,
      endEpochMs: endMs,
      cycleMinutes: durationMinutes,
      isPlanned: false,
    );

    final updated = current.copyWith(
      timeboxes: [...current.timeboxes, entry],
    );
    await _persist(updated);
  }

  Future<String?> addPlannedTimebox({
    required TaskItem task,
    required DateTime startedAt,
    required DateTime endedAt,
  }) async {
    final current = await future;
    if (!endedAt.isAfter(startedAt)) return null;

    const uuid = Uuid();
    final id = uuid.v4();

    final entry = TimeboxEntry(
      id: id,
      taskId: task.id,
      taskTitle: task.title,
      tag: task.tag,
      startEpochMs: startedAt.millisecondsSinceEpoch,
      endEpochMs: endedAt.millisecondsSinceEpoch,
      cycleMinutes: endedAt.difference(startedAt).inMinutes.abs(),
      isPlanned: true,
    );

    final updated = current.copyWith(
      timeboxes: [...current.timeboxes, entry],
    );
    await _persist(updated);
    return id;
  }

  Future<void> updateTimebox(TimeboxEntry entry) async {
    final current = await future;
    final updatedEntries = current.timeboxes
        .map((existing) => existing.id == entry.id ? entry : existing)
        .toList(growable: false);

    final updated = current.copyWith(timeboxes: updatedEntries);
    await _persist(updated);
  }

  Future<void> removeTimebox(String entryId) async {
    final current = await future;
    final updatedEntries =
        current.timeboxes.where((entry) => entry.id != entryId).toList();

    final updated = current.copyWith(timeboxes: updatedEntries);
    await _persist(updated);
  }
}
