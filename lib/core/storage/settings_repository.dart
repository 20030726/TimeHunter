import '../../services/storage/hive_service.dart';

abstract class SettingsRepository {
  Future<String?> loadVariant();
  Future<void> saveVariant(String name);
}

class HiveSettingsRepository implements SettingsRepository {
  HiveSettingsRepository(this._box);

  final HiveBoxStore _box;

  static const _variantKey = 'variant';

  @override
  Future<String?> loadVariant() async {
    return _box.read(_variantKey);
  }

  @override
  Future<void> saveVariant(String name) async {
    await _box.write(_variantKey, name);
  }
}
