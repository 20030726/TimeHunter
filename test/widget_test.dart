import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:timehunter/app/providers.dart';
import 'package:timehunter/app/time_hunter_app.dart';
import 'package:timehunter/core/auth/auth_user.dart';
import 'package:timehunter/core/auth/auth_repository.dart';
import 'package:timehunter/core/models/daily_data.dart';
import 'package:timehunter/core/models/task_item.dart';
import 'package:timehunter/core/models/task_tag.dart';
import 'package:timehunter/core/storage/daily_repository.dart';
import 'package:timehunter/core/storage/settings_repository.dart';
import 'package:timehunter/core/utils/dates.dart';

class FakeDailyRepository implements DailyRepository {
  final _store = <String, DailyData>{};

  @override
  Future<DailyData> load(DateTime dateTime) async {
    final key = ymd(dateTime);
    return _store.putIfAbsent(
      key,
      () => DailyData(
        dateYmd: key,
        slackUsed: 0,
        tasks: [
          TaskItem(
            id: 't1',
            title: 'Test Task',
            tag: TaskTag.study,
            totalCycles: 2,
            completedCycles: 0,
            cycleMinutes: 10,
          ),
        ],
      ),
    );
  }

  @override
  Future<DailyData?> loadExisting(DateTime dateTime) async {
    return _store[ymd(dateTime)];
  }

  @override
  Future<List<String>> listKeys() async {
    return _store.keys.toList(growable: false);
  }

  @override
  Future<void> save(DailyData data) async {
    _store[data.dateYmd] = data;
  }
}

class FakeSettingsRepository implements SettingsRepository {
  String? _variantName;

  @override
  Future<String?> loadVariant() async => _variantName;

  @override
  Future<void> saveVariant(String name) async {
    _variantName = name;
  }
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.user});

  final AuthUser? user;

  @override
  Stream<AuthUser?> authStateChanges() => Stream.value(user);

  @override
  AuthUser? get currentUser => user;

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signOut() async {}
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('App boots and shows main home', (tester) async {
    final repo = FakeDailyRepository();
    final settingsRepo = FakeSettingsRepository();
    final authRepo = FakeAuthRepository(
      user: const AuthUser(uid: 'u1', email: 'test@example.com'),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dailyRepositoryProvider.overrideWithValue(repo),
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
          authRepositoryProvider.overrideWithValue(authRepo),
        ],
        child: const TimeHunterApp(),
      ),
    );

    // Let AsyncNotifier load.
    await tester.pumpAndSettle();

    expect(find.text('Test Task'), findsOneWidget);
    expect(find.text('新增任務'), findsWidgets);
  });
}
