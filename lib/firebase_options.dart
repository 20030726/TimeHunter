import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        throw UnimplementedError(
          'FirebaseOptions not configured. Run `flutterfire configure` to '
          'generate firebase_options.dart.',
        );
      case TargetPlatform.fuchsia:
        throw UnimplementedError('FirebaseOptions not configured for fuchsia.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDqXDUGsBA29h9cJLFQPuiLLhufbwyJ5Z0',
    appId: '1:969853373996:web:b08ebe9844cfe83adf8b89',
    messagingSenderId: '969853373996',
    projectId: 'timehunter-c904e',
    authDomain: 'timehunter-c904e.firebaseapp.com',
    storageBucket: 'timehunter-c904e.firebasestorage.app',
    measurementId: 'G-CZ02VKTX6B',
  );
}
