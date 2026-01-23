import 'package:flutter/material.dart';
import '../../core/models/hunt_variant.dart';
import '../../core/theme/variant_ui.dart';
import '../../core/utils/time_format.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/glow_progress_bar.dart';
import '../../widgets/xp_bar_overview.dart';
import '../showcase/variant_layouts.dart';
import 'fullscreen_control.dart';
import 'music_control.dart';

class TimerLayoutData {
  TimerLayoutData({
    required this.variant,
    required this.title,
    required this.tagLabel,
    required this.remainingSeconds,
    required this.ratio,
    required this.completedCycles,
    required this.totalCycles,
    required this.isRunning,
    required this.showSuccess,
    required this.slackRemaining,
    required this.canSlack,
    required this.cycleMinutes,
    required this.accent,
    this.showSlackInHeader = true,
    required this.onClose,
    required this.onToggleRun,
    required this.onSlack,
    required this.onCycleChanged,
  });

  final HuntVariant variant;
  final String title;
  final String tagLabel;
  final int remainingSeconds;
  final double ratio;
  final int completedCycles;
  final int totalCycles;
  final bool isRunning;
  final bool showSuccess;
  final int slackRemaining;
  final bool canSlack;
  final int cycleMinutes;
  final Color accent;
  final bool showSlackInHeader;
  final VoidCallback onClose;
  final VoidCallback onToggleRun;
  final VoidCallback onSlack;
  final ValueChanged<int> onCycleChanged;
}

class TimerLayouts {
  static Widget build(TimerLayoutData data) {
    switch (data.variant) {
      case HuntVariant.huntHud:
        return _HudTimerLayout(data: data);
      case HuntVariant.timelineRail:
        return _TimelineTimerLayout(data: data);
      case HuntVariant.splitCommand:
        return _SplitTimerLayout(data: data);
      case HuntVariant.monoStrike:
        return _MonoStrikeTimerLayout(data: data);
      case HuntVariant.stellarHunt:
        return _StellarTimerLayout(data: data);
      case HuntVariant.arcadeBoard:
        return _ArcadeTimerLayout(data: data);
      case HuntVariant.orbitCommand:
        return _OrbitTimerLayout(data: data);
      case HuntVariant.auroraGlass:
        return _AuroraTimerLayout(data: data);
    }
  }
}

class TimerCountdown extends StatelessWidget {
  const TimerCountdown({
    super.key,
    required this.seconds,
    required this.style,
    this.align = TextAlign.center,
    this.glowColor,
  });

  final int seconds;
  final TextStyle style;
  final TextAlign align;
  final Color? glowColor;

  @override
  Widget build(BuildContext context) {
    final text = formatCountdown(seconds);
    final glow = glowColor;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      transitionBuilder: (child, anim) {
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.12),
          end: Offset.zero,
        ).animate(anim);
        return FadeTransition(
          opacity: anim,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: Text(
        text,
        key: ValueKey(text),
        textAlign: align,
        style: glow == null
            ? style
            : style.copyWith(
                shadows: [
                  Shadow(color: glow.withValues(alpha: 0.5), blurRadius: 18),
                  Shadow(color: glow.withValues(alpha: 0.25), blurRadius: 32),
                ],
              ),
      ),
    );
  }
}

class TimerTagPill extends StatelessWidget {
  const TimerTagPill({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class TimerActionButtons extends StatelessWidget {
  const TimerActionButtons({
    super.key,
    required this.isRunning,
    required this.canSlack,
    required this.accent,
    required this.primaryText,
    required this.onToggleRun,
    required this.onSlack,
    this.textStyle,
    this.secondaryStyle,
    this.primaryLabel,
    this.pauseLabel,
    this.slackLabel = '偷懶 15 分鐘',
  });

  final bool isRunning;
  final bool canSlack;
  final Color accent;
  final Color primaryText;
  final VoidCallback onToggleRun;
  final VoidCallback onSlack;
  final TextStyle? textStyle;
  final ButtonStyle? secondaryStyle;
  final String? primaryLabel;
  final String? pauseLabel;
  final String slackLabel;

  @override
  Widget build(BuildContext context) {
    final label = isRunning ? (pauseLabel ?? '暫停') : (primaryLabel ?? '開獵');

    return Row(
      children: [
        Expanded(
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: accent.withValues(alpha: 0.92),
              foregroundColor: primaryText,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              textStyle: textStyle,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: onToggleRun,
            child: Text(label),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            style: secondaryStyle ??
                FilledButton.styleFrom(
                  backgroundColor: accent.withValues(alpha: 0.12),
                  foregroundColor: accent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  textStyle: textStyle,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
            onPressed: canSlack ? onSlack : null,
            child: Text(slackLabel),
          ),
        ),
      ],
    );
  }
}

class TimerCycleSlider extends StatelessWidget {
  const TimerCycleSlider({
    super.key,
    required this.minutes,
    required this.enabled,
    required this.accent,
    required this.textColor,
    required this.onChanged,
    this.label = 'Cycle 時長',
  });

  final int minutes;
  final bool enabled;
  final Color accent;
  final Color textColor;
  final ValueChanged<int> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(color: textColor.withValues(alpha: 0.8), fontSize: 12),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: accent.withValues(alpha: 0.85),
                inactiveTrackColor: accent.withValues(alpha: 0.2),
                thumbColor: accent,
                overlayColor: accent.withValues(alpha: 0.12),
                valueIndicatorColor: accent,
              ),
              child: Slider(
                value: [5, 10, 15, 20].indexOf(minutes).toDouble(),
                min: 0,
                max: 3,
                divisions: 3,
                label: '$minutes 分鐘',
                onChanged: enabled
                    ? (value) {
                        final next = [5, 10, 15, 20][value.round()];
                        onChanged(next);
                      }
                    : null,
              ),
            ),
          ),
          SizedBox(
            width: 52,
            child: Text(
              '${minutes}m',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TimerSuccessOverlay extends StatelessWidget {
  const TimerSuccessOverlay({super.key, required this.show, required this.color});

  final bool show;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();

    return Positioned.fill(
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: -1.2, end: 1.2),
          duration: const Duration(milliseconds: 520),
          curve: Curves.easeOut,
          builder: (context, value, _) {
            return Stack(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                  ),
                  child: const SizedBox.expand(),
                ),
                Align(
                  alignment: Alignment(value, 0),
                  child: FractionallySizedBox(
                    widthFactor: 0.65,
                    heightFactor: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            color.withValues(alpha: 0.35),
                            color.withValues(alpha: 0.12),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.45, 0.55, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox.shrink(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HudTimerLayout extends StatelessWidget {
  const _HudTimerLayout({required this.data});

  final TimerLayoutData data;

  @override
  Widget build(BuildContext context) {
    final style = plannerStyleFor(data.variant);
    final accent = style.accent;
    final textColor = style.textPrimary;
    final muted = style.textSecondary;
    final tagColor = data.accent;

    return Stack(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: style.canvasGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const SizedBox.expand(),
        ),
        Positioned(
          top: -120,
          right: -80,
          child: _GlowBlob(color: style.accentSoft, size: 220, opacity: 0.25),
        ),
        Positioned(
          bottom: -140,
          left: -80,
          child: _GlowBlob(color: accent, size: 260, opacity: 0.18),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: data.onClose,
                      icon: const Icon(Icons.close),
                      color: textColor,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        data.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: style.titleFont.copyWith(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    TimerTagPill(label: data.tagLabel, color: tagColor),
                    if (data.showSlackInHeader) ...[
                      const SizedBox(width: 10),
                      SlackTickets(
                        remaining: data.slackRemaining,
                        accent: accent,
                        textColor: textColor,
                        compact: true,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: TimerCountdown(
                          seconds: data.remainingSeconds,
                          glowColor: accent,
                          style: style.displayFont.copyWith(
                            fontSize: 96,
                            color: textColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      GlowProgressBar(
                        value: data.ratio,
                        height: 6,
                        trackColor: Colors.white.withValues(alpha: 0.12),
                        progressColor: accent,
                        glowBlur: 6,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${(data.ratio * 100).round()}%',
                          style: style.bodyFont.copyWith(
                            color: muted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: accent.withValues(alpha: 0.35)),
                  ),
                  child: Column(
                    children: [
                      TimerActionButtons(
                        isRunning: data.isRunning,
                        canSlack: data.canSlack,
                        accent: accent,
                        primaryText: Colors.black,
                        onToggleRun: data.onToggleRun,
                        onSlack: data.onSlack,
                        textStyle: style.bodyFont.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TimerCycleSlider(
                        minutes: data.cycleMinutes,
                        enabled: !data.isRunning,
                        accent: accent,
                        textColor: textColor,
                        onChanged: data.onCycleChanged,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TimelineTimerLayout extends StatelessWidget {
  const _TimelineTimerLayout({required this.data});

  final TimerLayoutData data;

  @override
  Widget build(BuildContext context) {
    final style = plannerStyleFor(data.variant);
    final accent = style.accent;
    final textColor = style.textPrimary;
    final muted = style.textSecondary;

    return Stack(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: style.canvasGradient,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: const SizedBox.expand(),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: data.onClose,
                      icon: const Icon(Icons.close),
                      color: textColor,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        data.title,
                        style: style.titleFont.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (data.showSlackInHeader)
                      SlackTickets(
                        remaining: data.slackRemaining,
                        accent: accent,
                        textColor: textColor,
                        compact: true,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TimerCountdown(
                  seconds: data.remainingSeconds,
                  style: style.displayFont.copyWith(
                    fontSize: 92,
                    color: textColor,
                    letterSpacing: 2,
                  ),
                  align: TextAlign.left,
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: data.ratio,
                  backgroundColor: accent.withValues(alpha: 0.2),
                  color: accent,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      '${data.completedCycles}/${data.totalCycles} 輪',
                      style: style.bodyFont.copyWith(
                        color: muted,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${(data.ratio * 100).round()}%',
                      style: style.bodyFont.copyWith(
                        color: muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                MiniBarOverview(value: data.ratio, color: accent, count: 8),
                const Spacer(),
                TimerActionButtons(
                  isRunning: data.isRunning,
                  canSlack: data.canSlack,
                  accent: accent,
                  primaryText: Colors.black,
                  onToggleRun: data.onToggleRun,
                  onSlack: data.onSlack,
                  textStyle: style.bodyFont.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  secondaryStyle: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: accent,
                    textStyle: style.bodyFont.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TimerCycleSlider(
                  minutes: data.cycleMinutes,
                  enabled: !data.isRunning,
                  accent: accent,
                  textColor: textColor,
                  onChanged: data.onCycleChanged,
                  label: 'Cycle 時長',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SplitTimerLayout extends StatelessWidget {
  const _SplitTimerLayout({required this.data});

  final TimerLayoutData data;

  @override
  Widget build(BuildContext context) {
    final style = plannerStyleFor(data.variant);
    final accent = style.accent;
    final accent2 = style.accentSoft;
    final textColor = style.textPrimary;
    final muted = style.textSecondary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 720;

        final left = Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent2.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: data.onClose,
                    icon: const Icon(Icons.close),
                    color: textColor,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      data.title,
                      style: style.titleFont.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (data.showSlackInHeader)
                    SlackTickets(
                      remaining: data.slackRemaining,
                      accent: accent,
                      textColor: textColor,
                      compact: true,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Center(
                  child: TimerCountdown(
                    seconds: data.remainingSeconds,
                    glowColor: accent2,
                    style: style.displayFont.copyWith(
                      color: textColor,
                      fontSize: 84,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              GlowProgressBar(
                value: data.ratio,
                height: 6,
                trackColor: Colors.white.withValues(alpha: 0.12),
                progressColor: accent2,
                glowBlur: 6,
              ),
              const SizedBox(height: 8),
              Text(
                '${(data.ratio * 100).round()}%  ·  ${data.completedCycles}/${data.totalCycles} 輪',
                style: style.bodyFont.copyWith(color: muted, fontSize: 12),
              ),
            ],
          ),
        );

        final right = Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '控制台',
                      style: style.titleFont.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const MusicControl(compact: true),
                  const SizedBox(width: 8),
                  const FullscreenControl(compact: true),
                ],
              ),
              const SizedBox(height: 12),
              TimerActionButtons(
                isRunning: data.isRunning,
                canSlack: data.canSlack,
                accent: accent,
                primaryText: Colors.black,
                onToggleRun: data.onToggleRun,
                onSlack: data.onSlack,
                textStyle: style.bodyFont.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              TimerCycleSlider(
                minutes: data.cycleMinutes,
                enabled: !data.isRunning,
                accent: accent,
                textColor: textColor,
                onChanged: data.onCycleChanged,
              ),
            ],
          ),
        );

        return Stack(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: style.canvasGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const SizedBox.expand(),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: isWide
                    ? Row(
                        children: [
                          Expanded(child: left),
                          const SizedBox(width: 16),
                          Expanded(child: right),
                        ],
                      )
                    : Column(
                        children: [
                          Expanded(child: left),
                          const SizedBox(height: 16),
                          Expanded(child: right),
                        ],
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MonoStrikeTimerLayout extends StatelessWidget {
  const _MonoStrikeTimerLayout({required this.data});

  final TimerLayoutData data;

  @override
  Widget build(BuildContext context) {
    final style = plannerStyleFor(data.variant);
    final accent = style.accent;
    final textColor = style.textPrimary;
    final muted = style.textSecondary;

    return Stack(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: style.canvasGradient,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: const SizedBox.expand(),
        ),
        GridBackdrop(color: accent),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: data.onClose,
                      icon: const Icon(Icons.close),
                      color: accent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        data.title,
                        style: style.titleFont.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SlackTickets(
                      remaining: data.slackRemaining,
                      accent: accent,
                      textColor: textColor,
                      compact: true,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Center(
                    child: TimerCountdown(
                      seconds: data.remainingSeconds,
                      glowColor: accent,
                      style: style.displayFont.copyWith(
                        fontSize: 92,
                        color: textColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                XpBarOverview(
                  value: data.ratio,
                  accent: accent,
                  track: Colors.white.withValues(alpha: 0.12),
                ),
                const SizedBox(height: 10),
                Text(
                  '${data.completedCycles}/${data.totalCycles} 輪',
                  style: style.bodyFont.copyWith(
                    color: muted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                TimerActionButtons(
                  isRunning: data.isRunning,
                  canSlack: data.canSlack,
                  accent: accent,
                  primaryText: Colors.black,
                  onToggleRun: data.onToggleRun,
                  onSlack: data.onSlack,
                  textStyle: style.bodyFont.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                TimerCycleSlider(
                  minutes: data.cycleMinutes,
                  enabled: !data.isRunning,
                  accent: accent,
                  textColor: textColor,
                  onChanged: data.onCycleChanged,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StellarTimerLayout extends StatelessWidget {
  const _StellarTimerLayout({required this.data});

  final TimerLayoutData data;

  @override
  Widget build(BuildContext context) {
    final style = plannerStyleFor(data.variant);
    final accent = style.accent;
    final accent2 = style.accentSoft;
    final textColor = style.textPrimary;
    final muted = style.textSecondary;

    return Stack(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: style.canvasGradient,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: const SizedBox.expand(),
        ),
        StarfieldBackdrop(accent: accent),
        Positioned(
          bottom: -120,
          right: -80,
          child: _GlowBlob(color: accent2, size: 240, opacity: 0.2),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: data.onClose,
                      icon: const Icon(Icons.close),
                      color: textColor,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        data.title,
                        style: style.titleFont.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (data.showSlackInHeader)
                      SlackTickets(
                        remaining: data.slackRemaining,
                        accent: accent2,
                        textColor: textColor,
                        compact: true,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ProgressRingView(
                          value: data.ratio,
                          size: 190,
                          trackColor: Colors.white.withValues(alpha: 0.12),
                          progressColor: accent2,
                          textStyle: style.bodyFont.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        TimerCountdown(
                          seconds: data.remainingSeconds,
                          glowColor: accent2,
                          style: style.displayFont.copyWith(
                            fontSize: 64,
                            color: textColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Text(
                  '星際進度 ${data.completedCycles}/${data.totalCycles} 輪',
                  style: style.bodyFont.copyWith(color: muted, fontSize: 12),
                ),
                const SizedBox(height: 12),
                TimerActionButtons(
                  isRunning: data.isRunning,
                  canSlack: data.canSlack,
                  accent: accent2,
                  primaryText: Colors.black,
                  onToggleRun: data.onToggleRun,
                  onSlack: data.onSlack,
                  textStyle: style.bodyFont.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                TimerCycleSlider(
                  minutes: data.cycleMinutes,
                  enabled: !data.isRunning,
                  accent: accent2,
                  textColor: textColor,
                  onChanged: data.onCycleChanged,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ArcadeTimerLayout extends StatelessWidget {
  const _ArcadeTimerLayout({required this.data});

  final TimerLayoutData data;

  @override
  Widget build(BuildContext context) {
    final style = plannerStyleFor(data.variant);
    final accent = style.accent;
    final accent2 = style.accentSoft;
    final textColor = style.textPrimary;
    final muted = style.textSecondary;

    return Stack(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: style.canvasGradient,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: const SizedBox.expand(),
        ),
        Positioned(
          top: -100,
          right: -60,
          child: _GlowBlob(color: accent, size: 200, opacity: 0.2),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: data.onClose,
                      icon: const Icon(Icons.close),
                      color: accent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        data.title,
                        style: style.titleFont.copyWith(
                          color: accent,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    _HeartTickets(remaining: data.slackRemaining),
                  ],
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: Center(
                    child: TimerCountdown(
                      seconds: data.remainingSeconds,
                      glowColor: accent2,
                      style: style.displayFont.copyWith(
                        color: textColor,
                        fontSize: 72,
                      ),
                    ),
                  ),
                ),
                Text(
                  'XP 進度',
                  style: style.bodyFont.copyWith(
                    color: muted,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 6),
                XpBarOverview(
                  value: data.ratio,
                  accent: accent2,
                  track: Colors.white.withValues(alpha: 0.12),
                ),
                const SizedBox(height: 12),
                TimerActionButtons(
                  isRunning: data.isRunning,
                  canSlack: data.canSlack,
                  accent: accent2,
                  primaryText: Colors.black,
                  onToggleRun: data.onToggleRun,
                  onSlack: data.onSlack,
                  textStyle: style.bodyFont.copyWith(fontSize: 8),
                  primaryLabel: 'START',
                  pauseLabel: 'PAUSE',
                  slackLabel: 'COIN +15',
                ),
                const SizedBox(height: 12),
                TimerCycleSlider(
                  minutes: data.cycleMinutes,
                  enabled: !data.isRunning,
                  accent: accent2,
                  textColor: textColor,
                  onChanged: data.onCycleChanged,
                  label: 'CYCLE',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OrbitTimerLayout extends StatelessWidget {
  const _OrbitTimerLayout({required this.data});

  final TimerLayoutData data;

  @override
  Widget build(BuildContext context) {
    final style = plannerStyleFor(data.variant);
    final accent = style.accent;
    final accent2 = style.accentSoft;
    final textColor = style.textPrimary;

    return Stack(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: style.canvasGradient,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: const SizedBox.expand(),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: data.onClose,
                      icon: const Icon(Icons.close),
                      color: textColor,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        data.title,
                        style: style.titleFont.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (data.showSlackInHeader)
                      SlackTickets(
                        remaining: data.slackRemaining,
                        accent: accent2,
                        textColor: textColor,
                        compact: true,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        OrbitOverview(
                          value: data.ratio,
                          accent: accent2,
                          track: Colors.white.withValues(alpha: 0.12),
                          size: 220,
                        ),
                        TimerCountdown(
                          seconds: data.remainingSeconds,
                          glowColor: accent,
                          style: style.displayFont.copyWith(
                            fontSize: 68,
                            color: textColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                TimerActionButtons(
                  isRunning: data.isRunning,
                  canSlack: data.canSlack,
                  accent: accent2,
                  primaryText: Colors.black,
                  onToggleRun: data.onToggleRun,
                  onSlack: data.onSlack,
                  textStyle: style.bodyFont.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                TimerCycleSlider(
                  minutes: data.cycleMinutes,
                  enabled: !data.isRunning,
                  accent: accent2,
                  textColor: textColor,
                  onChanged: data.onCycleChanged,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AuroraTimerLayout extends StatelessWidget {
  const _AuroraTimerLayout({required this.data});

  final TimerLayoutData data;

  @override
  Widget build(BuildContext context) {
    final style = plannerStyleFor(data.variant);
    final accent = style.accent;
    final accent2 = style.accentSoft;
    final textColor = style.textPrimary;
    final muted = style.textSecondary;

    return Stack(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: style.canvasGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const SizedBox.expand(),
        ),
        Positioned(
          top: -140,
          right: -60,
          child: _GlowBlob(color: accent2, size: 240, opacity: 0.35),
        ),
        Positioned(
          bottom: -120,
          left: -80,
          child: _GlowBlob(color: accent, size: 240, opacity: 0.25),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: data.onClose,
                      icon: const Icon(Icons.close),
                      color: textColor,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        data.title,
                        style: style.titleFont.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (data.showSlackInHeader)
                      SlackTickets(
                        remaining: data.slackRemaining,
                        accent: textColor,
                        textColor: textColor,
                        compact: true,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Center(
                    child: GlassPanel(
                      borderRadius: 22,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'SAVE THE TIME',
                            style: style.bodyFont.copyWith(
                              color: textColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TimerCountdown(
                            seconds: data.remainingSeconds,
                            glowColor: textColor,
                            style: style.displayFont.copyWith(
                              fontSize: 72,
                              color: textColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Cycle ${data.cycleMinutes} 分鐘',
                            style: style.bodyFont.copyWith(
                              color: muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                GlowProgressBar(
                  value: data.ratio,
                  height: 6,
                  trackColor: Colors.white.withValues(alpha: 0.2),
                  progressColor: textColor,
                  glowBlur: 6,
                ),
                const SizedBox(height: 12),
                TimerActionButtons(
                  isRunning: data.isRunning,
                  canSlack: data.canSlack,
                  accent: textColor,
                  primaryText: Colors.black,
                  onToggleRun: data.onToggleRun,
                  onSlack: data.onSlack,
                  textStyle: style.bodyFont.copyWith(fontWeight: FontWeight.w700),
                  secondaryStyle: FilledButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    foregroundColor: textColor,
                    textStyle: style.bodyFont.copyWith(fontWeight: FontWeight.w700),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TimerCycleSlider(
                  minutes: data.cycleMinutes,
                  enabled: !data.isRunning,
                  accent: textColor,
                  textColor: textColor,
                  onChanged: data.onCycleChanged,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.color, required this.size, required this.opacity});

  final Color color;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _HeartTickets extends StatelessWidget {
  const _HeartTickets({required this.remaining});

  final int remaining;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (index) {
        final filled = index < remaining;
        return Icon(
          Icons.favorite,
          color: filled ? const Color(0xFFEF4444) : Colors.white24,
          size: 16,
        );
      }),
    );
  }
}
