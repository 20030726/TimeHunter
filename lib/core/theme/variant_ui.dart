import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/hunt_variant.dart';

TextStyle _withFallback(TextStyle style) {
  return style.copyWith(
    fontFamilyFallback: const [
      'Noto Sans TC',
      'PingFang TC',
      'Heiti TC',
      'Microsoft JhengHei',
    ],
  );
}

class PlannerStyle {
  const PlannerStyle({
    required this.variant,
    required this.accent,
    required this.accentSoft,
    required this.panelGradient,
    required this.taskCardGradient,
    required this.noteGradient,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.canvasGradient,
    required this.gridColor,
    required this.showGrid,
    required this.showPaperLines,
    required this.breakpoint,
    required this.titleFont,
    required this.bodyFont,
    required this.monoFont,
    required this.displayFont,
    required this.noteLine,
    required this.noteMargin,
  });

  final HuntVariant variant;
  final Color accent;
  final Color accentSoft;
  final List<Color> panelGradient;
  final List<Color> taskCardGradient;
  final List<Color> noteGradient;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final List<Color> canvasGradient;
  final Color gridColor;
  final bool showGrid;
  final bool showPaperLines;
  final double breakpoint;
  final TextStyle titleFont;
  final TextStyle bodyFont;
  final TextStyle monoFont;
  final TextStyle displayFont;
  final Color noteLine;
  final Color noteMargin;
}

PlannerStyle plannerStyleFor(HuntVariant variant) {
  switch (variant) {
    case HuntVariant.timelineRail:
      final accent = const Color(0xFFF59E0B);
      final textPrimary = const Color(0xFF3B2F2F);
      final textSecondary = const Color(0xFF7B6A58);
      return PlannerStyle(
        variant: variant,
        accent: accent,
        accentSoft: const Color(0xFFFCD34D),
        panelGradient: [
          const Color(0xFFF8F3EC),
          const Color(0xFFF0E6D8),
        ],
        taskCardGradient: [
          const Color(0xFFF7F0E7),
          const Color(0xFFF0E3D4),
        ],
        noteGradient: [
          const Color(0xFFF7F0E7),
          const Color(0xFFF0E3D4),
        ],
        border: const Color(0xFFD6C6B6),
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        canvasGradient: const [
          Color(0xFFF7F3EE),
          Color(0xFFEDE3D6),
        ],
        gridColor: const Color(0xFFCDBBAA).withValues(alpha: 0.18),
        showGrid: false,
        showPaperLines: true,
        breakpoint: 1024,
        titleFont: _withFallback(GoogleFonts.ibmPlexSans()),
        bodyFont: _withFallback(GoogleFonts.ibmPlexSans()),
        monoFont: _withFallback(GoogleFonts.spaceMono()),
        displayFont: _withFallback(GoogleFonts.bebasNeue()),
        noteLine: const Color(0xFFCDBBAA).withValues(alpha: 0.55),
        noteMargin: accent.withValues(alpha: 0.22),
      );
    case HuntVariant.splitCommand:
      final accent = const Color(0xFFF97316);
      final textPrimary = const Color(0xFFE2E8F0);
      final textSecondary = const Color(0xFF94A3B8);
      return PlannerStyle(
        variant: variant,
        accent: accent,
        accentSoft: const Color(0xFF38BDF8),
        panelGradient: [
          const Color(0xFF182235).withValues(alpha: 0.95),
          const Color(0xFF0F1726).withValues(alpha: 0.98),
        ],
        taskCardGradient: [
          const Color(0xFF1C273B),
          const Color(0xFF121C30),
        ],
        noteGradient: [
          const Color(0xFF192337),
          const Color(0xFF111A2D),
        ],
        border: const Color(0xFF334155),
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        canvasGradient: const [
          Color(0xFF101623),
          Color(0xFF241810),
        ],
        gridColor: const Color(0xFF334155).withValues(alpha: 0.18),
        showGrid: true,
        showPaperLines: false,
        breakpoint: 1040,
        titleFont: _withFallback(GoogleFonts.sora()),
        bodyFont: _withFallback(GoogleFonts.sora()),
        monoFont: _withFallback(GoogleFonts.spaceMono()),
        displayFont: _withFallback(GoogleFonts.sora()),
        noteLine: const Color(0xFF334155).withValues(alpha: 0.2),
        noteMargin: accent.withValues(alpha: 0.16),
      );
    case HuntVariant.monoStrike:
      final accent = const Color(0xFF00FF7F);
      final textPrimary = const Color(0xFFF8FAFC);
      final textSecondary = const Color(0xFF94A3B8);
      return PlannerStyle(
        variant: variant,
        accent: accent,
        accentSoft: const Color(0xFF6EE7B7),
        panelGradient: [
          const Color(0xFF121826).withValues(alpha: 0.96),
          const Color(0xFF0B1220).withValues(alpha: 0.98),
        ],
        taskCardGradient: [
          const Color(0xFF162030),
          const Color(0xFF0F1828),
        ],
        noteGradient: [
          const Color(0xFF131D2D),
          const Color(0xFF0C1424),
        ],
        border: const Color(0xFF2B3448),
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        canvasGradient: const [
          Color(0xFF020617),
          Color(0xFF0B1220),
        ],
        gridColor: const Color(0xFF334155).withValues(alpha: 0.12),
        showGrid: false,
        showPaperLines: false,
        breakpoint: 1000,
        titleFont: _withFallback(GoogleFonts.spaceMono()),
        bodyFont: _withFallback(GoogleFonts.spaceMono()),
        monoFont: _withFallback(GoogleFonts.spaceMono()),
        displayFont: _withFallback(GoogleFonts.spaceMono()),
        noteLine: const Color(0xFF334155).withValues(alpha: 0.2),
        noteMargin: accent.withValues(alpha: 0.14),
      );
    case HuntVariant.stellarHunt:
      final accent = const Color(0xFF7EE8FA);
      final textPrimary = const Color(0xFFE2F1FF);
      final textSecondary = const Color(0xFF91A3B5);
      return PlannerStyle(
        variant: variant,
        accent: accent,
        accentSoft: const Color(0xFF39FF14),
        panelGradient: [
          const Color(0xFF101A2B).withValues(alpha: 0.95),
          const Color(0xFF0B1121).withValues(alpha: 0.98),
        ],
        taskCardGradient: [
          const Color(0xFF172337),
          const Color(0xFF0E1829),
        ],
        noteGradient: [
          const Color(0xFF121C30),
          const Color(0xFF0C1424),
        ],
        border: const Color(0xFF2A364C),
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        canvasGradient: const [
          Color(0xFF020617),
          Color(0xFF0F1C33),
        ],
        gridColor: const Color(0xFF334155).withValues(alpha: 0.16),
        showGrid: true,
        showPaperLines: false,
        breakpoint: 1040,
        titleFont: _withFallback(GoogleFonts.orbitron()),
        bodyFont: _withFallback(GoogleFonts.spaceGrotesk()),
        monoFont: _withFallback(GoogleFonts.spaceMono()),
        displayFont: _withFallback(GoogleFonts.orbitron()),
        noteLine: const Color(0xFF334155).withValues(alpha: 0.2),
        noteMargin: accent.withValues(alpha: 0.18),
      );
    case HuntVariant.arcadeBoard:
      final accent = const Color(0xFF00F5FF);
      final accentSoft = const Color(0xFF39FF14);
      final textPrimary = const Color(0xFFF8FAFC);
      final textSecondary = const Color(0xFF9CA3AF);
      final panelSurface = const Color(0xFF0B1320).withValues(alpha: 0.92);
      final cardSurface = const Color(0xFF0B0F14).withValues(alpha: 0.96);
      return PlannerStyle(
        variant: variant,
        accent: accent,
        accentSoft: accentSoft,
        panelGradient: [
          panelSurface,
          const Color(0xFF0B0F14).withValues(alpha: 0.98),
        ],
        taskCardGradient: [
          cardSurface,
          const Color(0xFF0B0F14).withValues(alpha: 0.98),
        ],
        noteGradient: [
          panelSurface,
          const Color(0xFF0B0F14).withValues(alpha: 0.98),
        ],
        border: accentSoft,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        canvasGradient: const [
          Color(0xFF0B0F14),
          Color(0xFF0B1220),
        ],
        gridColor: const Color(0xFF334155).withValues(alpha: 0.12),
        showGrid: false,
        showPaperLines: false,
        breakpoint: 1040,
        titleFont: _withFallback(GoogleFonts.pressStart2p()),
        bodyFont: _withFallback(GoogleFonts.pressStart2p()),
        monoFont: _withFallback(GoogleFonts.rubikMonoOne()),
        displayFont: _withFallback(GoogleFonts.rubikMonoOne()),
        noteLine: const Color(0xFF334155).withValues(alpha: 0.2),
        noteMargin: accentSoft.withValues(alpha: 0.14),
      );
    case HuntVariant.orbitCommand:
      final accent = const Color(0xFF22D3EE);
      final accentSoft = const Color(0xFFFCD34D);
      final textPrimary = const Color(0xFFE2E8F0);
      final textSecondary = const Color(0xFF94A3B8);
      return PlannerStyle(
        variant: variant,
        accent: accent,
        accentSoft: accentSoft,
        panelGradient: [
          const Color(0xFF0F1726).withValues(alpha: 0.92),
          const Color(0xFF0B1220).withValues(alpha: 0.98),
        ],
        taskCardGradient: [
          const Color(0xFF111A2B),
          const Color(0xFF0B1424),
        ],
        noteGradient: [
          const Color(0xFF10192A),
          const Color(0xFF0B1424),
        ],
        border: const Color(0xFF2A364C),
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        canvasGradient: const [
          Color(0xFF0B1220),
          Color(0xFF0B1A2A),
        ],
        gridColor: const Color(0xFF334155).withValues(alpha: 0.12),
        showGrid: false,
        showPaperLines: false,
        breakpoint: 1040,
        titleFont: _withFallback(GoogleFonts.exo2()),
        bodyFont: _withFallback(GoogleFonts.exo2()),
        monoFont: _withFallback(GoogleFonts.spaceMono()),
        displayFont: _withFallback(GoogleFonts.exo2()),
        noteLine: const Color(0xFF334155).withValues(alpha: 0.2),
        noteMargin: accentSoft.withValues(alpha: 0.16),
      );
    case HuntVariant.auroraGlass:
      final accent = const Color(0xFF22C55E);
      final textPrimary = const Color(0xFFF8FAFC);
      final textSecondary = const Color(0xFFCBD5F5);
      return PlannerStyle(
        variant: variant,
        accent: accent,
        accentSoft: const Color(0xFF0EA5E9),
        panelGradient: [
          const Color(0xFF0B1220).withValues(alpha: 0.55),
          const Color(0xFF0B1220).withValues(alpha: 0.75),
        ],
        taskCardGradient: [
          const Color(0xFF0B1220).withValues(alpha: 0.55),
          const Color(0xFF0B1220).withValues(alpha: 0.75),
        ],
        noteGradient: [
          const Color(0xFF0B1220).withValues(alpha: 0.55),
          const Color(0xFF0B1220).withValues(alpha: 0.75),
        ],
        border: const Color(0xFF2C3A54),
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        canvasGradient: const [
          Color(0xFF0EA5E9),
          Color(0xFF22C55E),
        ],
        gridColor: const Color(0xFF334155).withValues(alpha: 0.10),
        showGrid: false,
        showPaperLines: false,
        breakpoint: 1024,
        titleFont: _withFallback(GoogleFonts.manrope()),
        bodyFont: _withFallback(GoogleFonts.manrope()),
        monoFont: _withFallback(GoogleFonts.spaceMono()),
        displayFont: _withFallback(GoogleFonts.spaceGrotesk()),
        noteLine: const Color(0xFF334155).withValues(alpha: 0.2),
        noteMargin: accent.withValues(alpha: 0.18),
      );
    case HuntVariant.huntHud:
    default:
      final accent = const Color(0xFF22D3EE);
      final accentSoft = const Color(0xFF39FF88);
      final textPrimary = const Color(0xFFE6F8F2);
      final textSecondary = const Color(0xFF7BA3A7);
      return PlannerStyle(
        variant: variant,
        accent: accent,
        accentSoft: accentSoft,
        panelGradient: [
          const Color(0xFF0B1F2C).withValues(alpha: 0.9),
          const Color(0xFF0B1727).withValues(alpha: 0.98),
        ],
        taskCardGradient: [
          const Color(0xFF0B1F2C).withValues(alpha: 0.9),
          const Color(0xFF0B1727).withValues(alpha: 0.98),
        ],
        noteGradient: [
          const Color(0xFF0B1F2C).withValues(alpha: 0.9),
          const Color(0xFF0B1727).withValues(alpha: 0.98),
        ],
        border: const Color(0xFF1F2A3B),
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        canvasGradient: const [
          Color(0xFF05070F),
          Color(0xFF08162B),
          Color(0xFF041320),
        ],
        gridColor: accent.withValues(alpha: 0.12),
        showGrid: false,
        showPaperLines: false,
        breakpoint: 1040,
        titleFont: _withFallback(GoogleFonts.orbitron()),
        bodyFont: _withFallback(GoogleFonts.spaceGrotesk()),
        monoFont: _withFallback(GoogleFonts.spaceMono()),
        displayFont: _withFallback(GoogleFonts.orbitron()),
        noteLine: const Color(0xFF334155).withValues(alpha: 0.2),
        noteMargin: accent.withValues(alpha: 0.18),
      );
  }
}

enum HeroProgressStyle { glowBar, xpBar }
enum HeroBadgeStyle { ring, none, orbit }
enum TaskProgressStyle { glow, solid }

class PlannerComponents {
  const PlannerComponents({
    required this.heroProgressStyle,
    required this.heroBadgeStyle,
    required this.heroProgressColor,
    required this.heroTrackColor,
    required this.panelBorderColor,
    required this.panelBorderWidth,
    required this.chipBackground,
    required this.chipBorder,
    required this.chipTextStyle,
    required this.chipIconColor,
    required this.taskProgressStyle,
    required this.actionLabel,
    required this.actionDoneLabel,
  });

  final HeroProgressStyle heroProgressStyle;
  final HeroBadgeStyle heroBadgeStyle;
  final Color heroProgressColor;
  final Color heroTrackColor;
  final Color panelBorderColor;
  final double panelBorderWidth;
  final Color chipBackground;
  final Color chipBorder;
  final TextStyle chipTextStyle;
  final Color chipIconColor;
  final TaskProgressStyle taskProgressStyle;
  final String actionLabel;
  final String actionDoneLabel;
}

PlannerComponents plannerComponentsFor(PlannerStyle style) {
  switch (style.variant) {
    case HuntVariant.timelineRail:
      return PlannerComponents(
        heroProgressStyle: HeroProgressStyle.glowBar,
        heroBadgeStyle: HeroBadgeStyle.ring,
        heroProgressColor: style.accent,
        heroTrackColor: style.border.withValues(alpha: 0.5),
        panelBorderColor: style.border.withValues(alpha: 0.7),
        panelBorderWidth: 1,
        chipBackground: style.border.withValues(alpha: 0.18),
        chipBorder: style.border.withValues(alpha: 0.5),
        chipTextStyle: style.bodyFont.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: style.textSecondary,
        ),
        chipIconColor: style.accent,
        taskProgressStyle: TaskProgressStyle.solid,
        actionLabel: '開獵',
        actionDoneLabel: '已完成',
      );
    case HuntVariant.arcadeBoard:
      return PlannerComponents(
        heroProgressStyle: HeroProgressStyle.xpBar,
        heroBadgeStyle: HeroBadgeStyle.none,
        heroProgressColor: style.accentSoft,
        heroTrackColor: Colors.white.withValues(alpha: 0.12),
        panelBorderColor: style.accent.withValues(alpha: 0.45),
        panelBorderWidth: 1.2,
        chipBackground: Colors.black.withValues(alpha: 0.28),
        chipBorder: style.accent.withValues(alpha: 0.5),
        chipTextStyle: style.bodyFont.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: style.textSecondary,
        ),
        chipIconColor: style.accent,
        taskProgressStyle: TaskProgressStyle.solid,
        actionLabel: 'START',
        actionDoneLabel: 'CLEAR',
      );
    case HuntVariant.splitCommand:
      return PlannerComponents(
        heroProgressStyle: HeroProgressStyle.glowBar,
        heroBadgeStyle: HeroBadgeStyle.ring,
        heroProgressColor: style.accentSoft,
        heroTrackColor: style.border.withValues(alpha: 0.7),
        panelBorderColor: style.border.withValues(alpha: 0.6),
        panelBorderWidth: 1,
        chipBackground: style.border.withValues(alpha: 0.2),
        chipBorder: style.border.withValues(alpha: 0.5),
        chipTextStyle: style.monoFont.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: style.textSecondary,
        ),
        chipIconColor: style.accent,
        taskProgressStyle: TaskProgressStyle.glow,
        actionLabel: '開獵',
        actionDoneLabel: '已完成',
      );
    case HuntVariant.monoStrike:
      return PlannerComponents(
        heroProgressStyle: HeroProgressStyle.xpBar,
        heroBadgeStyle: HeroBadgeStyle.none,
        heroProgressColor: style.accent,
        heroTrackColor: Colors.white.withValues(alpha: 0.12),
        panelBorderColor: style.border.withValues(alpha: 0.6),
        panelBorderWidth: 1,
        chipBackground: style.border.withValues(alpha: 0.2),
        chipBorder: style.border.withValues(alpha: 0.5),
        chipTextStyle: style.monoFont.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: style.textSecondary,
        ),
        chipIconColor: style.accent,
        taskProgressStyle: TaskProgressStyle.solid,
        actionLabel: '開獵',
        actionDoneLabel: '已完成',
      );
    case HuntVariant.stellarHunt:
      return PlannerComponents(
        heroProgressStyle: HeroProgressStyle.glowBar,
        heroBadgeStyle: HeroBadgeStyle.ring,
        heroProgressColor: style.accentSoft,
        heroTrackColor: style.border.withValues(alpha: 0.7),
        panelBorderColor: style.border.withValues(alpha: 0.6),
        panelBorderWidth: 1,
        chipBackground: style.border.withValues(alpha: 0.2),
        chipBorder: style.border.withValues(alpha: 0.5),
        chipTextStyle: style.monoFont.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: style.textSecondary,
        ),
        chipIconColor: style.accent,
        taskProgressStyle: TaskProgressStyle.glow,
        actionLabel: '開獵',
        actionDoneLabel: '已完成',
      );
    case HuntVariant.orbitCommand:
      return PlannerComponents(
        heroProgressStyle: HeroProgressStyle.glowBar,
        heroBadgeStyle: HeroBadgeStyle.orbit,
        heroProgressColor: style.accentSoft,
        heroTrackColor: style.border.withValues(alpha: 0.7),
        panelBorderColor: style.border.withValues(alpha: 0.6),
        panelBorderWidth: 1,
        chipBackground: style.border.withValues(alpha: 0.2),
        chipBorder: style.border.withValues(alpha: 0.5),
        chipTextStyle: style.monoFont.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: style.textSecondary,
        ),
        chipIconColor: style.accent,
        taskProgressStyle: TaskProgressStyle.solid,
        actionLabel: '開獵',
        actionDoneLabel: '已完成',
      );
    case HuntVariant.auroraGlass:
      return PlannerComponents(
        heroProgressStyle: HeroProgressStyle.glowBar,
        heroBadgeStyle: HeroBadgeStyle.ring,
        heroProgressColor: style.textPrimary,
        heroTrackColor: style.border.withValues(alpha: 0.4),
        panelBorderColor: style.border.withValues(alpha: 0.6),
        panelBorderWidth: 1,
        chipBackground: style.border.withValues(alpha: 0.2),
        chipBorder: style.border.withValues(alpha: 0.5),
        chipTextStyle: style.monoFont.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: style.textSecondary,
        ),
        chipIconColor: style.accentSoft,
        taskProgressStyle: TaskProgressStyle.glow,
        actionLabel: '開獵',
        actionDoneLabel: '已完成',
      );
    case HuntVariant.huntHud:
      return PlannerComponents(
        heroProgressStyle: HeroProgressStyle.glowBar,
        heroBadgeStyle: HeroBadgeStyle.ring,
        heroProgressColor: style.accent,
        heroTrackColor: style.border.withValues(alpha: 0.6),
        panelBorderColor: style.accent.withValues(alpha: 0.35),
        panelBorderWidth: 1,
        chipBackground: Colors.black.withValues(alpha: 0.25),
        chipBorder: style.accent.withValues(alpha: 0.35),
        chipTextStyle: style.bodyFont.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: style.textSecondary,
        ),
        chipIconColor: style.accent,
        taskProgressStyle: TaskProgressStyle.glow,
        actionLabel: '開獵',
        actionDoneLabel: '已完成',
      );
    default:
      return PlannerComponents(
        heroProgressStyle: HeroProgressStyle.glowBar,
        heroBadgeStyle: HeroBadgeStyle.ring,
        heroProgressColor: style.accent,
        heroTrackColor: style.border.withValues(alpha: 0.7),
        panelBorderColor: style.border.withValues(alpha: 0.6),
        panelBorderWidth: 1,
        chipBackground: style.border.withValues(alpha: 0.2),
        chipBorder: style.border.withValues(alpha: 0.5),
        chipTextStyle: style.monoFont.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: style.textSecondary,
        ),
        chipIconColor: style.accent,
        taskProgressStyle: TaskProgressStyle.glow,
        actionLabel: '開獵',
        actionDoneLabel: '已完成',
      );
  }
}
