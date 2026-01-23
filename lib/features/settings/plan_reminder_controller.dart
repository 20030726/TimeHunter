import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';

class PlanReminderSettings {
  const PlanReminderSettings({
    required this.enabled,
    required this.minutes,
  });

  final bool enabled;
  final int minutes;

  TimeOfDay get timeOfDay {
    final hour = (minutes ~/ 60) % 24;
    final minute = minutes % 60;
    return TimeOfDay(hour: hour, minute: minute);
  }

  PlanReminderSettings copyWith({bool? enabled, int? minutes}) {
    return PlanReminderSettings(
      enabled: enabled ?? this.enabled,
      minutes: minutes ?? this.minutes,
    );
  }
}

final planReminderProvider =
    AsyncNotifierProvider<PlanReminderController, PlanReminderSettings>(
  PlanReminderController.new,
);

class PlanReminderController extends AsyncNotifier<PlanReminderSettings> {
  static const int _defaultMinutes = 22 * 60;

  @override
  Future<PlanReminderSettings> build() async {
    final repo = ref.watch(settingsRepositoryProvider);
    final enabled = await repo.loadPlanReminderEnabled();
    final minutes = await repo.loadPlanReminderMinutes();

    return PlanReminderSettings(
      enabled: enabled ?? true,
      minutes: minutes ?? _defaultMinutes,
    );
  }

  Future<void> setEnabled(bool enabled) async {
    final current = state.value ?? await future;
    final updated = current.copyWith(enabled: enabled);
    state = AsyncData(updated);
    await ref.read(settingsRepositoryProvider).savePlanReminderEnabled(enabled);
  }

  Future<void> setTime(TimeOfDay time) async {
    final current = state.value ?? await future;
    final minutes = time.hour * 60 + time.minute;
    final updated = current.copyWith(minutes: minutes);
    state = AsyncData(updated);
    await ref.read(settingsRepositoryProvider).savePlanReminderMinutes(minutes);
  }
}
