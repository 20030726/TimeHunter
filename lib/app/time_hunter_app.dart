import 'package:flutter/material.dart';

import '../features/auth/auth_gate.dart';
import 'theme.dart';

class TimeHunterApp extends StatelessWidget {
  const TimeHunterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Time Hunter',
      theme: darkTheme(),
      darkTheme: darkTheme(),
      themeMode: ThemeMode.dark,
      home: const AuthGate(),
    );
  }
}
