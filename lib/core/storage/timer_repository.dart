import 'dart:convert';

import '../models/active_timer_state.dart';
import 'hive_boxes.dart';
import '../../services/storage/hive_service.dart';

abstract class TimerRepository {
  Future<ActiveTimerState?> load();
  Future<void> save(ActiveTimerState state);
  Future<void> clear();
}

class HiveTimerRepository implements TimerRepository {
  HiveTimerRepository(this._box);

  final HiveBoxStore _box;

  static const _key = 'active';

  static Future<HiveTimerRepository> open(HiveService hive) async {
    final box = await hive.openBox(HiveBoxes.timer);
    return HiveTimerRepository(box);
  }

  @override
  Future<ActiveTimerState?> load() async {
    final raw = _box.read(_key);
    if (raw == null) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return ActiveTimerState.fromJson(decoded.cast<String, Object?>());
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  @override
  Future<void> save(ActiveTimerState state) async {
    await _box.write(_key, jsonEncode(state.toJson()));
  }

  @override
  Future<void> clear() async {
    await _box.delete(_key);
  }
}
