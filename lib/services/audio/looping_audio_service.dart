import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

class LoopingAudioService extends ChangeNotifier {
  LoopingAudioService({AudioPlayer? player}) : _player = player ?? AudioPlayer() {
    _player.setReleaseMode(ReleaseMode.loop);
  }

  final AudioPlayer _player;
  String? _currentAsset;
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;
  String? get currentAsset => _currentAsset;

  Future<void> playAsset(String fileName, {double volume = 0.5}) async {
    if (_isPlaying && _currentAsset == fileName) return;

    try {
      await _player.stop();
      await _player.play(AssetSource('audio/$fileName'), volume: volume);
      _currentAsset = fileName;
      _isPlaying = true;
    } catch (_) {
      _currentAsset = null;
      _isPlaying = false;
    }
    notifyListeners();
  }

  Future<void> stop() async {
    await _player.stop();
    _currentAsset = null;
    _isPlaying = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
