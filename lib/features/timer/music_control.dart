import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timehunter/app/providers.dart';
import 'package:timehunter/core/constants/audio_assets.dart';

class MusicControl extends ConsumerWidget {
  const MusicControl({super.key, this.compact = false});

  final bool compact;

  void _showMusicSelectionDialog(BuildContext context, WidgetRef ref) {
    final audioService = ref.read(backgroundAudioProvider);
    final musicList = AudioAssets.backgroundMusic;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Background Music'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: musicList.length,
              itemBuilder: (BuildContext context, int index) {
                final music = musicList[index];
                final musicName = music.split('.').first.replaceAll('BouncyTeacupWaltz', 'Waltz').replaceAll('Campfireinthe Woods', 'Campfire');
                return ListTile(
                  title: Text(musicName),
                  onTap: () {
                    if (music == AudioAssets.none) {
                      audioService.stop();
                    } else {
                      audioService.playAsset(music);
                    }
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioService = ref.watch(backgroundAudioProvider);
    final currentMusic = audioService.currentAsset ?? AudioAssets.none;
    final currentMusicName = currentMusic.split('.').first.replaceAll('BouncyTeacupWaltz', 'Waltz').replaceAll('Campfireinthe Woods', 'Campfire');

    return TextButton.icon(
      style: compact
          ? TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: Colors.black.withValues(alpha: 0.25),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            )
          : null,
      icon: Icon(Icons.music_note, size: compact ? 16 : null),
      label: Text(
        currentMusicName,
        style: compact
            ? const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)
            : null,
      ),
      onPressed: () => _showMusicSelectionDialog(context, ref),
    );
  }
}
