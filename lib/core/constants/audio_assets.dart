class AudioAssets {
  static const String none = 'None';
  static const String startRiser = 'CinematicRiser (Boom).mp3';
  static const String completion = 'highpitchalarm buzzer.mp3';
  static const String bigCompletion = 'BouncyTeacupWaltz.mp3';
  static const String campfire = 'Campfireinthe Woods.mp3';
  static const String clock = 'ClockTickingSFX.mp3';
  static const String clockLegacy = 'Clock Ticking SFX.mp3';

  static const List<String> backgroundMusic = [
    none,
    campfire,
    clock,
  ];
}

class AudioVolumes {
  static const double sfx = 1.0;
  static const double background = 0.5;
}

class AudioDurations {
  static const Duration completionDelay = Duration(milliseconds: 300);
}
