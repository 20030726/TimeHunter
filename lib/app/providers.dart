import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/auth_repository.dart';
import '../core/storage/daily_repository.dart';
import '../core/storage/planned_task_repository.dart';
import '../core/storage/settings_repository.dart';
import '../core/storage/timer_repository.dart';
import '../services/audio/looping_audio_service.dart';

final dailyRepositoryProvider = Provider<DailyRepository>((ref) {
  throw UnimplementedError('Override dailyRepositoryProvider in main()');
});

final timerRepositoryProvider = Provider<TimerRepository>((ref) {
  throw UnimplementedError('Override timerRepositoryProvider in main()');
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  throw UnimplementedError('Override settingsRepositoryProvider in main()');
});

final plannedTaskRepositoryProvider = Provider<PlannedTaskRepository>((ref) {
  throw UnimplementedError('Override plannedTaskRepositoryProvider in main()');
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  throw UnimplementedError('Override authRepositoryProvider in main()');
});

final backgroundAudioProvider = ChangeNotifierProvider<LoopingAudioService>((ref) {
  final service = LoopingAudioService();
  ref.onDispose(service.dispose);
  return service;
});

final authStateProvider = StreamProvider((ref) {
  return ref.read(authRepositoryProvider).authStateChanges();
});

/// Bottom tab index: 0 Hunt, 1 Records, 2 Year.
final navIndexProvider = StateProvider<int>((ref) => 0);
