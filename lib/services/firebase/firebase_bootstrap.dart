import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseBootstrap {
  const FirebaseBootstrap({FirebaseFirestore? firestore})
      : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  Future<void> initialize({required FirebaseOptions options}) async {
    await Firebase.initializeApp(options: options);
    final firestore = _firestore ?? FirebaseFirestore.instance;
    firestore.settings = const Settings(persistenceEnabled: true);
  }
}
