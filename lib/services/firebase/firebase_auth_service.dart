import 'package:firebase_auth/firebase_auth.dart';

import '../../core/auth/auth_user.dart';

class FirebaseAuthService {
  FirebaseAuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  Stream<AuthUser?> authStateChanges() =>
      _auth.authStateChanges().map(_fromUser);

  AuthUser? get currentUser => _fromUser(_auth.currentUser);

  String? get currentUserId => _auth.currentUser?.uid;

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  AuthUser? _fromUser(User? user) {
    if (user == null) return null;
    return AuthUser(uid: user.uid, email: user.email ?? '');
  }
}
