import '../auth/auth_repository.dart';
import '../models/daily_data.dart';
import 'daily_repository.dart';

class SyncedDailyRepository implements DailyRepository {
  SyncedDailyRepository({
    required DailyRepository local,
    required DailyRepository remote,
    required AuthRepository auth,
  })  : _local = local,
        _remote = remote,
        _auth = auth;

  final DailyRepository _local;
  final DailyRepository _remote;
  final AuthRepository _auth;

  bool get _signedIn => _auth.currentUser != null;

  bool _hasData(DailyData data) {
    return data.tasks.isNotEmpty ||
        data.timeboxes.isNotEmpty ||
        data.dailyNote.trim().isNotEmpty ||
        data.slackUsed > 0;
  }

  Future<DailyData> _resolve(
    DailyData local,
    DailyData remote,
  ) async {
    if (remote.updatedAtEpochMs > local.updatedAtEpochMs) {
      await _local.save(remote);
      return remote;
    }

    if (local.updatedAtEpochMs > remote.updatedAtEpochMs) {
      await _remote.save(local);
      return local;
    }

    if (local.updatedAtEpochMs == 0 && remote.updatedAtEpochMs > 0) {
      await _local.save(remote);
      return remote;
    }

    if (remote.updatedAtEpochMs == 0 && local.updatedAtEpochMs > 0) {
      await _remote.save(local);
      return local;
    }

    return local;
  }

  @override
  Future<DailyData> load(DateTime dateTime) async {
    final localData = await _local.load(dateTime);

    if (!_signedIn) return localData;

    final remoteData = await _remote.loadExisting(dateTime);
    if (remoteData == null) {
      if (_hasData(localData)) {
        await _remote.save(localData);
      }
      return localData;
    }

    return _resolve(localData, remoteData);
  }

  @override
  Future<DailyData?> loadExisting(DateTime dateTime) async {
    final localExisting = await _local.loadExisting(dateTime);
    if (!_signedIn) return localExisting;

    final remoteExisting = await _remote.loadExisting(dateTime);
    if (localExisting == null && remoteExisting == null) return null;

    if (localExisting == null && remoteExisting != null) {
      await _local.save(remoteExisting);
      return remoteExisting;
    }

    if (localExisting != null && remoteExisting == null) {
      if (_hasData(localExisting)) {
        await _remote.save(localExisting);
      }
      return localExisting;
    }

    return _resolve(localExisting!, remoteExisting!);
  }

  @override
  Future<List<String>> listKeys() async {
    final localKeys = await _local.listKeys();
    if (!_signedIn) return localKeys;

    final remoteKeys = await _remote.listKeys();
    final merged = {...localKeys, ...remoteKeys}.toList();
    merged.sort();
    return merged;
  }

  @override
  Future<void> save(DailyData data) async {
    await _local.save(data);
    if (_signedIn) {
      await _remote.save(data);
    }
  }

  Future<void> syncAll() async {
    if (!_signedIn) return;

    final localKeys = await _local.listKeys();
    final remoteKeys = await _remote.listKeys();
    final allKeys = {...localKeys, ...remoteKeys}.toList();

    for (final key in allKeys) {
      final date = DateTime.tryParse(key);
      if (date == null) continue;

      final local = await _local.loadExisting(date);
      final remote = await _remote.loadExisting(date);

      if (local == null && remote == null) continue;
      if (local == null && remote != null) {
        await _local.save(remote);
        continue;
      }
      if (local != null && remote == null) {
        if (_hasData(local)) await _remote.save(local);
        continue;
      }

      await _resolve(local!, remote!);
    }
  }
}
