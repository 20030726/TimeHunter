import 'dart:convert';

import '../models/daily_data.dart';
import '../utils/dates.dart';
import 'hive_boxes.dart';
import '../../services/storage/hive_service.dart';

abstract class DailyRepository {
  /// Loads a day, creating default data if missing.
  Future<DailyData> load(DateTime dateTime);

  /// Loads a day only if it already exists (no side effects).
  Future<DailyData?> loadExisting(DateTime dateTime);

  Future<void> save(DailyData data);

  /// Lists stored day keys (yyyy-MM-dd).
  Future<List<String>> listKeys();
}

class HiveDailyRepository implements DailyRepository {
  HiveDailyRepository(this._box);

  final HiveBoxStore _box;

  static Future<HiveDailyRepository> open(HiveService hive) async {
    final box = await hive.openBox(HiveBoxes.daily);
    return HiveDailyRepository(box);
  }

  @override
  Future<DailyData?> loadExisting(DateTime dateTime) async {
    final key = ymd(dateTime);
    final raw = _box.read(key);
    if (raw == null) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return DailyData.fromJson(decoded.cast<String, Object?>());
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  @override
  Future<List<String>> listKeys() async {
    return _box.keys();
  }

  @override
  Future<DailyData> load(DateTime dateTime) async {
    final key = ymd(dateTime);
    final raw = _box.read(key);

    if (raw == null) {
      // No side effects: return an empty day.
      return DailyData(dateYmd: key, slackUsed: 0, tasks: const []);
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return DailyData.fromJson(decoded.cast<String, Object?>());
      }
    } catch (_) {
      // fall through
    }

    // If the stored payload is corrupted, return empty without writing.
    return DailyData(dateYmd: key, slackUsed: 0, tasks: const []);
  }

  @override
  Future<void> save(DailyData data) async {
    final encoded = jsonEncode(data.toJson());
    await _box.write(data.dateYmd, encoded);
  }
}
