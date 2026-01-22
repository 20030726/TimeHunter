import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  Future<void> init() async {
    await Hive.initFlutter();
  }

  Future<HiveBoxStore> openBox(String name) async {
    final box = await Hive.openBox<String>(name);
    return HiveBoxStore(box);
  }
}

class HiveBoxStore {
  HiveBoxStore(this._box);

  final Box<String> _box;

  String? read(String key) => _box.get(key);

  Future<void> write(String key, String value) async {
    await _box.put(key, value);
  }

  Future<void> delete(String key) async {
    await _box.delete(key);
  }

  List<String> keys() {
    return _box.keys.whereType<String>().toList(growable: false);
  }
}
