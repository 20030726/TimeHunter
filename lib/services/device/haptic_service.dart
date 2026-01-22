import 'package:flutter/services.dart';

class HapticService {
  void vibrate() {
    HapticFeedback.vibrate();
  }

  void selectionClick() {
    HapticFeedback.selectionClick();
  }
}
