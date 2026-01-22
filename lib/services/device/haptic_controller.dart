import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'haptic_service.dart';

class HapticController extends Notifier<void> {
  final HapticService _hapticService = HapticService();

  @override
  void build() {
    // No state to manage, just methods for haptic feedback
  }

  void vibrate() {
    _hapticService.vibrate();
  }

  void selectionClick() {
    _hapticService.selectionClick();
  }
}

final hapticControllerProvider = NotifierProvider<HapticController, void>(
  () => HapticController(),
);
