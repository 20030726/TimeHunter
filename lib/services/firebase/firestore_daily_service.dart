import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/models/daily_data.dart';
import '../../core/utils/dates.dart';
import 'firebase_auth_service.dart';

class FirestoreDailyService {
  FirestoreDailyService({
    FirebaseFirestore? firestore,
    required FirebaseAuthService authService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _authService = authService;

  final FirebaseFirestore _firestore;
  final FirebaseAuthService _authService;

  CollectionReference<Map<String, Object?>> _collectionForUser(String uid) {
    return _firestore.collection('users').doc(uid).collection('daily');
  }

  String _key(DateTime dateTime) => ymd(dateTime);

  Future<DailyData?> loadExisting(DateTime dateTime) async {
    final uid = _authService.currentUserId;
    if (uid == null) return null;

    final key = _key(dateTime);
    final snapshot = await _collectionForUser(uid).doc(key).get();
    final raw = snapshot.data();
    if (raw == null) return null;

    return DailyData.fromJson(raw);
  }

  Future<List<String>> listKeys() async {
    final uid = _authService.currentUserId;
    if (uid == null) return const [];

    final snapshot = await _collectionForUser(uid).get();
    return snapshot.docs.map((doc) => doc.id).toList(growable: false);
  }

  Future<void> save(DailyData data) async {
    final uid = _authService.currentUserId;
    if (uid == null) return;

    final key = data.dateYmd;
    await _collectionForUser(uid).doc(key).set(data.toJson());
  }
}
