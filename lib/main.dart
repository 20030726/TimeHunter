import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/providers.dart';
import 'app/time_hunter_app.dart';
import 'core/auth/auth_repository.dart';
import 'core/storage/daily_repository.dart';
import 'core/storage/firebase_daily_repository.dart';
import 'core/storage/hive_boxes.dart';
import 'core/storage/planned_task_repository.dart';
import 'core/storage/settings_repository.dart';
import 'core/storage/synced_daily_repository.dart';
import 'core/storage/timer_repository.dart';
import 'firebase_options.dart';
import 'services/firebase/firebase_auth_service.dart';
import 'services/firebase/firebase_bootstrap.dart';
import 'services/firebase/firestore_daily_service.dart';
import 'services/storage/hive_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final hiveService = HiveService();
  await hiveService.init();
  final dailyBox = await hiveService.openBox(HiveBoxes.daily);
  final timerBox = await hiveService.openBox(HiveBoxes.timer);
  final settingsBox = await hiveService.openBox(HiveBoxes.settings);
  final plannedTasksBox = await hiveService.openBox(HiveBoxes.plannedTasks);

  const firebaseBootstrap = FirebaseBootstrap();
  await firebaseBootstrap.initialize(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final authService = FirebaseAuthService();
  final firestoreDailyService = FirestoreDailyService(authService: authService);

  final authRepository = FirebaseAuthRepository(authService);
  final localDailyRepository = HiveDailyRepository(dailyBox);
  final remoteDailyRepository = FirebaseDailyRepository(
    service: firestoreDailyService,
  );
  final dailyRepository = SyncedDailyRepository(
    local: localDailyRepository,
    remote: remoteDailyRepository,
    auth: authRepository,
  );
  final timerRepository = HiveTimerRepository(timerBox);
  final settingsRepository = HiveSettingsRepository(settingsBox);
  final plannedTaskRepository = HivePlannedTaskRepository(plannedTasksBox);

  runApp(
    ProviderScope(
      overrides: [
        dailyRepositoryProvider.overrideWithValue(dailyRepository),
        timerRepositoryProvider.overrideWithValue(timerRepository),
        settingsRepositoryProvider.overrideWithValue(settingsRepository),
        plannedTaskRepositoryProvider.overrideWithValue(plannedTaskRepository),
        authRepositoryProvider.overrideWithValue(authRepository),
      ],
      child: const TimeHunterApp(),
    ),
  );
}
