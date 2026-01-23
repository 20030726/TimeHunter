enum HuntVariant {
  huntHud,
  timelineRail,
  splitCommand,
  monoStrike,
  stellarHunt,
  arcadeBoard,
  orbitCommand,
  auroraGlass,
}

extension HuntVariantX on HuntVariant {
  String get label {
    switch (this) {
      case HuntVariant.huntHud:
        return 'Hunt HUD';
      case HuntVariant.timelineRail:
        return 'Timeline Rail';
      case HuntVariant.splitCommand:
        return 'Split Command';
      case HuntVariant.monoStrike:
        return 'Mono Strike';
      case HuntVariant.stellarHunt:
        return 'Stellar Hunt';
      case HuntVariant.arcadeBoard:
        return 'Arcade Board';
      case HuntVariant.orbitCommand:
        return 'Orbit Command';
      case HuntVariant.auroraGlass:
        return 'Aurora Glass';
    }
  }

  String get tagline {
    switch (this) {
      case HuntVariant.huntHud:
        return '霓虹戰術 HUD';
      case HuntVariant.timelineRail:
        return '時間軸手帳';
      case HuntVariant.splitCommand:
        return '指揮中樞分屏';
      case HuntVariant.monoStrike:
        return '極簡重擊';
      case HuntVariant.stellarHunt:
        return '宇宙獵場';
      case HuntVariant.arcadeBoard:
        return '街機計分板';
      case HuntVariant.orbitCommand:
        return '軌道指揮';
      case HuntVariant.auroraGlass:
        return '極光玻璃';
    }
  }
}
