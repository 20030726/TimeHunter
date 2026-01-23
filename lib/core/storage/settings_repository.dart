import '../../services/storage/hive_service.dart';

abstract class SettingsRepository {
  Future<String?> loadVariant();
  Future<void> saveVariant(String name);

  Future<bool?> loadPlanReminderEnabled();
  Future<void> savePlanReminderEnabled(bool enabled);
  Future<int?> loadPlanReminderMinutes();
  Future<void> savePlanReminderMinutes(int minutes);
}

class HiveSettingsRepository implements SettingsRepository {
  HiveSettingsRepository(this._box);

  final HiveBoxStore _box;

  static const _variantKey = 'variant';
  static const _planReminderEnabledKey = 'plan_reminder_enabled';
  static const _planReminderMinutesKey = 'plan_reminder_minutes';

  @override
  Future<String?> loadVariant() async {
    return _box.read(_variantKey);
  }

  @override
  Future<void> saveVariant(String name) async {
    await _box.write(_variantKey, name);
  }

  @override
  Future<bool?> loadPlanReminderEnabled() async {
    final raw = _box.read(_planReminderEnabledKey);
    if (raw == null) return null;
    return raw == 'true';
  }

  @override
  Future<void> savePlanReminderEnabled(bool enabled) async {
    await _box.write(_planReminderEnabledKey, enabled.toString());
  }

  @override
  Future<int?> loadPlanReminderMinutes() async {
    final raw = _box.read(_planReminderMinutesKey);
    if (raw == null) return null;
    return int.tryParse(raw);
  }

  @override
  Future<void> savePlanReminderMinutes(int minutes) async {
    await _box.write(_planReminderMinutesKey, minutes.toString());
  }
}
