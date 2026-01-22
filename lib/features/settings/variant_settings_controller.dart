import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../showcase/variant_layouts.dart';

final variantSettingsProvider =
    AsyncNotifierProvider<VariantSettingsController, HuntVariant>(
  VariantSettingsController.new,
);

class VariantSettingsController extends AsyncNotifier<HuntVariant> {
  @override
  Future<HuntVariant> build() async {
    final repo = ref.watch(settingsRepositoryProvider);
    final name = await repo.loadVariant();
    return _fromName(name);
  }

  Future<void> setVariant(HuntVariant variant) async {
    state = AsyncData(variant);
    await ref.read(settingsRepositoryProvider).saveVariant(variant.name);
  }

  HuntVariant _fromName(String? name) {
    if (name == null || name.isEmpty) return HuntVariant.splitCommand;
    for (final variant in HuntVariant.values) {
      if (variant.name == name) return variant;
    }
    return HuntVariant.splitCommand;
  }
}
