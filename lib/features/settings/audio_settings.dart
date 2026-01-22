import 'package:flutter_riverpod/flutter_riverpod.dart';

enum BackgroundMusic {
  off,
  campfire,
  clock,
}

final backgroundMusicProvider = StateProvider<BackgroundMusic>((_) => BackgroundMusic.off);
