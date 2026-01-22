import 'package:audioplayers/audioplayers.dart';

class AudioSfxService {
  Future<void> playAsset(
    String fileName, {
    double volume = 1.0,
    Duration? delay,
  }) async {
    if (delay != null && delay > Duration.zero) {
      await Future.delayed(delay);
    }

    final player = AudioPlayer();
    player.onPlayerComplete.listen((event) {
      player.dispose();
    });

    try {
      await player.play(AssetSource('audio/$fileName'), volume: volume);
    } catch (_) {
      player.dispose();
    }
  }
}
