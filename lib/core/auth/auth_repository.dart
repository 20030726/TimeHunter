import 'auth_user.dart';
import '../../services/firebase/firebase_auth_service.dart';

abstract class AuthRepository {
  Stream<AuthUser?> authStateChanges();
  AuthUser? get currentUser;

  Future<void> signInWithEmail({
    required String email,
    required String password,
  });

  Future<void> signUpWithEmail({
    required String email,
    required String password,
  });

  Future<void> signOut();
}

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._authService);

  final FirebaseAuthService _authService;

  @override
  Stream<AuthUser?> authStateChanges() => _authService.authStateChanges();

  @override
  AuthUser? get currentUser => _authService.currentUser;

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _authService.signInWithEmail(email: email, password: password);
  }

  @override
  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    await _authService.signUpWithEmail(email: email, password: password);
  }

  @override
  Future<void> signOut() async {
    await _authService.signOut();
  }
}
