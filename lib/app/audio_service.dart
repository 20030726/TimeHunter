import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/audio_assets.dart';
import '../features/settings/audio_settings.dart';
import '../services/audio/looping_audio_service.dart';

final backgroundAudioServiceProvider =
    Provider((ref) => BackgroundAudioService(ref));

class BackgroundAudioService {
  BackgroundAudioService(this._ref, {LoopingAudioService? loopingAudio})
      : _loopingAudio = loopingAudio ?? LoopingAudioService() {
    _ref.listen<BackgroundMusic>(backgroundMusicProvider, (_, next) {
      _handleMusicChange(next);
    });
  }

  final Ref _ref;
  final LoopingAudioService _loopingAudio;

  void _handleMusicChange(BackgroundMusic selection) {
    switch (selection) {
      case BackgroundMusic.campfire:
        _loopingAudio.playAsset(
          AudioAssets.campfire,
          volume: AudioVolumes.background,
        );
        break;
      case BackgroundMusic.clock:
        _loopingAudio.playAsset(
          AudioAssets.clock,
          volume: AudioVolumes.background,
        );
        break;
      case BackgroundMusic.off:
        stop();
        break;
    }
  }

  Future<void> stop() async {
    await _loopingAudio.stop();
  }

  void dispose() {
    _loopingAudio.dispose();
  }
}
