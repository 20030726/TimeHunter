import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/audio_assets.dart';
import '../../app/providers.dart';
import 'audio_sfx_service.dart'; // Assuming this exists

class AudioController extends Notifier<void> {
  final AudioSfxService _sfxService = AudioSfxService();

  @override
  void build() {
    // No state to manage, just methods for playing audio
  }

  Future<void> playStartSound() async {
    await _sfxService.playAsset(
      AudioAssets.startRiser,
      volume: AudioVolumes.sfx,
    );
  }

  Future<void> playCompletionSound() async {
    // 1. 延遲 300ms，讓動畫先跑
    await Future.delayed(AudioDurations.completionDelay);
    // Note: `mounted` check is not needed here as it's not a widget
    await _sfxService.playAsset(
      AudioAssets.completion,
      volume: AudioVolumes.sfx,
    );
  }

  Future<void> playBigTaskCompletionSound() async {
    await Future.delayed(AudioDurations.completionDelay);
    // Note: `mounted` check is not needed here as it's not a widget
    await _sfxService.playAsset(
      AudioAssets.bigCompletion,
      volume: AudioVolumes.sfx,
    );
  }

  void stopBackgroundAudio() {
    ref.read(backgroundAudioProvider).stop(); // Assuming backgroundAudioProvider exists
  }
}

final audioControllerProvider = NotifierProvider<AudioController, void>(
  () => AudioController(),
);
