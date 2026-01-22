import '../models/daily_data.dart';
import '../utils/dates.dart';
import 'daily_repository.dart';
import '../../services/firebase/firestore_daily_service.dart';

class FirebaseDailyRepository implements DailyRepository {
  FirebaseDailyRepository({required FirestoreDailyService service})
      : _service = service;

  final FirestoreDailyService _service;

  String _key(DateTime dateTime) => ymd(dateTime);

  @override
  Future<DailyData> load(DateTime dateTime) async {
    final data = await _service.loadExisting(dateTime);
    if (data != null) return data;

    return DailyData(
      dateYmd: _key(dateTime),
      slackUsed: 0,
      tasks: const [],
      timeboxes: const [],
      updatedAtEpochMs: 0,
    );
  }

  @override
  Future<DailyData?> loadExisting(DateTime dateTime) async {
    return _service.loadExisting(dateTime);
  }

  @override
  Future<List<String>> listKeys() async {
    return _service.listKeys();
  }

  @override
  Future<void> save(DailyData data) async {
    await _service.save(data);
  }
}
