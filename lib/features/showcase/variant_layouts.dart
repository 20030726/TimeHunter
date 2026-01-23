import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/models/daily_data.dart';
import '../../core/models/hunt_variant.dart';
import '../../core/theme/variant_ui.dart';
import '../../core/models/task_item.dart';
import '../../core/models/task_tag.dart';
import '../../core/utils/time_format.dart';
import '../../widgets/glow_progress_bar.dart';
import '../../widgets/xp_bar_overview.dart';

class VariantData {
  VariantData({
    required this.daily,
    required this.tasks,
    required this.countdown,
    required this.onAddTask,
    required this.onStartTask,
    required this.onTriggerCompletion,
  });

  final DailyData daily;
  final List<TaskItem> tasks;
  final ValueListenable<int> countdown;
  final VoidCallback onAddTask;
  final void Function(TaskItem task) onStartTask;
  final VoidCallback onTriggerCompletion;
}

class VariantLayouts {
  static Widget build({required HuntVariant variant, required VariantData data}) {
    switch (variant) {
      case HuntVariant.huntHud:
        return HuntHudLayout(data: data);
      case HuntVariant.timelineRail:
        return TimelineRailLayout(data: data);
      case HuntVariant.splitCommand:
        return SplitCommandLayout(data: data);
      case HuntVariant.monoStrike:
        return MonoStrikeLayout(data: data);
      case HuntVariant.stellarHunt:
        return StellarHuntLayout(data: data);
      case HuntVariant.arcadeBoard:
        return ArcadeBoardLayout(data: data);
      case HuntVariant.orbitCommand:
        return OrbitCommandLayout(data: data);
      case HuntVariant.auroraGlass:
        return AuroraGlassLayout(data: data);
    }
  }
}

class CountdownDisplay extends StatelessWidget {
  const CountdownDisplay({
    super.key,
    required this.seconds,
    required this.textStyle,
    this.align = TextAlign.center,
    this.glowColor,
  });

  final ValueListenable<int> seconds;
  final TextStyle textStyle;
  final TextAlign align;
  final Color? glowColor;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: seconds,
      builder: (context, value, _) {
        final text = formatCountdown(value);
        final glow = glowColor;

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          transitionBuilder: (child, anim) {
            final offsetAnim = Tween<Offset>(
              begin: const Offset(0, 0.18),
              end: Offset.zero,
            ).animate(anim);
            return FadeTransition(
              opacity: anim,
              child: SlideTransition(position: offsetAnim, child: child),
            );
          },
          child: Text(
            text,
            key: ValueKey(text),
            textAlign: align,
            style: glow == null
                ? textStyle
                : textStyle.copyWith(
                    shadows: [
                      Shadow(color: glow.withValues(alpha: 0.55), blurRadius: 18),
                      Shadow(color: glow.withValues(alpha: 0.25), blurRadius: 36),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.onStart,
    required this.accent,
    required this.background,
    required this.border,
    required this.textColor,
    required this.subTextColor,
    this.titleStyle,
    this.metaStyle,
    this.buttonStyle,
    this.dense = false,
    this.progressHeight = 6,
    this.showShadow = true,
    this.buttonLabel = '開獵',
  });

  final TaskItem task;
  final VoidCallback onStart;
  final Color accent;
  final Color background;
  final Color border;
  final Color textColor;
  final Color subTextColor;
  final TextStyle? titleStyle;
  final TextStyle? metaStyle;
  final TextStyle? buttonStyle;
  final bool dense;
  final double progressHeight;
  final bool showShadow;
  final String buttonLabel;

  @override
  Widget build(BuildContext context) {
    final ratio = task.totalCycles <= 0
        ? 0.0
        : task.completedCycles / task.totalCycles;
    final tagColor = Color(task.tag.colorValue);

    return Container(
      padding: EdgeInsets.all(dense ? 12 : 16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: tagColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: titleStyle ??
                      Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w700,
                          ),
                ),
              ),
              _TagPill(label: task.tag.label, color: tagColor),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '${task.completedCycles}/${task.totalCycles} 輪 · ${task.cycleMinutes} 分鐘',
                style: metaStyle ??
                    Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: subTextColor),
              ),
              const Spacer(),
              Text(
                '${(ratio * 100).round()}%',
                style: metaStyle ??
                    Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: subTextColor),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GlowProgressBar(
            value: ratio,
            height: progressHeight,
            trackColor: border.withValues(alpha: 0.6),
            progressColor: accent,
            glowBlur: 6,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: accent.withValues(alpha: 0.92),
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                textStyle: buttonStyle,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: task.isDone ? null : onStart,
              child: Text(task.isDone ? '已完成' : buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class TaskListView extends StatelessWidget {
  const TaskListView({
    super.key,
    required this.tasks,
    required this.itemBuilder,
    this.padding = EdgeInsets.zero,
    this.spacing = 12,
    this.shrinkWrap = false,
    this.physics,
  });

  final List<TaskItem> tasks;
  final Widget Function(BuildContext context, TaskItem task, int index)
      itemBuilder;
  final EdgeInsets padding;
  final double spacing;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemBuilder: (context, index) {
        return itemBuilder(context, tasks[index], index);
      },
      separatorBuilder: (_, _) => SizedBox(height: spacing),
      itemCount: tasks.length,
    );
  }
}

class SlackTickets extends StatelessWidget {
  const SlackTickets({
    super.key,
    required this.remaining,
    required this.accent,
    required this.textColor,
    this.compact = false,
  });

  final int remaining;
  final Color accent;
  final Color textColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final total = 3;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '偷懶券',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: compact ? 11 : 12,
            ),
          ),
          const SizedBox(width: 8),
          ...List.generate(total, (index) {
            final filled = index < remaining;
            return Container(
              width: compact ? 8 : 10,
              height: compact ? 8 : 10,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: filled ? accent : accent.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
            );
          }),
          Text(
            '$remaining/$total',
            style: TextStyle(
              color: textColor.withValues(alpha: 0.8),
              fontSize: compact ? 10 : 11,
            ),
          ),
        ],
      ),
    );
  }
}

class ProgressRingView extends StatelessWidget {
  const ProgressRingView({
    super.key,
    required this.value,
    required this.size,
    required this.trackColor,
    required this.progressColor,
    required this.textStyle,
  });

  final double value;
  final double size;
  final Color trackColor;
  final Color progressColor;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            value: v,
            strokeWidth: size * 0.08,
            backgroundColor: trackColor,
            valueColor: AlwaysStoppedAnimation(progressColor),
          ),
        ),
        Text('${(v * 100).round()}%', style: textStyle),
      ],
    );
  }
}

class HeatmapOverview extends StatelessWidget {
  const HeatmapOverview({
    super.key,
    required this.baseValue,
    required this.color,
    this.columns = 7,
    this.rows = 4,
    this.size = 14,
  });

  final double baseValue;
  final Color color;
  final int columns;
  final int rows;
  final double size;

  double _valueFor(int index) {
    final seed = (index * 37 + (baseValue * 100).round()) % 100;
    return (seed / 100).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final cells = <Widget>[];
    for (var i = 0; i < rows * columns; i++) {
      final v = (baseValue * 0.65 + _valueFor(i) * 0.35).clamp(0.0, 1.0);
      cells.add(
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Color.lerp(color.withValues(alpha: 0.12), color, v),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      );
    }

    return Wrap(spacing: 6, runSpacing: 6, children: cells);
  }
}

class MiniBarOverview extends StatelessWidget {
  const MiniBarOverview({
    super.key,
    required this.value,
    required this.color,
    this.count = 8,
    this.height = 54,
  });

  final double value;
  final Color color;
  final int count;
  final double height;

  double _barValue(int index) {
    final seed = (index * 19 + (value * 100).round()) % 100;
    return (seed / 100).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(count, (index) {
        final v = (value * 0.5 + _barValue(index) * 0.5).clamp(0.0, 1.0);
        return Expanded(
          child: Container(
            height: height * (0.3 + v * 0.7),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15 + 0.75 * v),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        );
      }),
    );
  }
}

class OrbitOverview extends StatelessWidget {
  const OrbitOverview({
    super.key,
    required this.value,
    required this.accent,
    required this.track,
    this.size = 120,
  });

  final double value;
  final Color accent;
  final Color track;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _OrbitPainter(value: value, accent: accent, track: track),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  _OrbitPainter({required this.value, required this.accent, required this.track});

  final double value;
  final Color accent;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width * 0.38;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.06
      ..strokeCap = StrokeCap.round
      ..color = track;

    canvas.drawCircle(center, radius, paint);

    paint.color = accent;
    final sweep = math.pi * 2 * value.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      paint,
    );

    final dotPaint = Paint()..color = accent.withValues(alpha: 0.8);
    final angle = -math.pi / 2 + sweep;
    final dot = Offset(
      center.dx + math.cos(angle) * radius,
      center.dy + math.sin(angle) * radius,
    );
    canvas.drawCircle(dot, size.width * 0.05, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.accent != accent ||
        oldDelegate.track != track;
  }
}

class MiniCalendarOverview extends StatelessWidget {
  const MiniCalendarOverview({
    super.key,
    required this.value,
    required this.accent,
  });

  final double value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final base = value.clamp(0.0, 1.0);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(28, (index) {
        final v = ((index * 13 + (base * 100).round()) % 100) / 100;
        final color = Color.lerp(
          accent.withValues(alpha: 0.1),
          accent,
          v,
        );
        return Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '${index + 1}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      }),
    );
  }
}

class GridBackdrop extends StatelessWidget {
  const GridBackdrop({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GridPainter(color: color),
      child: const SizedBox.expand(),
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..strokeWidth = 1;

    const gap = 28.0;
    for (double x = 0; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class StarfieldBackdrop extends StatelessWidget {
  const StarfieldBackdrop({super.key, required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _StarfieldPainter(accent: accent),
      child: const SizedBox.expand(),
    );
  }
}

class _StarfieldPainter extends CustomPainter {
  _StarfieldPainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);
    final paint = Paint()..color = accent.withValues(alpha: 0.4);

    final count = (size.width * size.height / 1400).clamp(180, 360).toInt();
    for (var i = 0; i < count; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final r = random.nextDouble() * 1.4 + 0.6;
      paint.color = accent.withValues(alpha: 0.2 + random.nextDouble() * 0.7);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarfieldPainter oldDelegate) {
    return oldDelegate.accent != accent;
  }
}

class HuntHudLayout extends StatelessWidget {
  const HuntHudLayout({super.key, required this.data});

  final VariantData data;

  @override
  Widget build(BuildContext context) {
    final style = plannerStyleFor(HuntVariant.huntHud);
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
          top: -120,
          right: -80,
          child: _GlowBlob(color: accent2, size: 220, opacity: 0.3),
        ),
        Positioned(
          bottom: -140,
          left: -80,
          child: _GlowBlob(color: accent, size: 260, opacity: 0.25),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      'TIME HUNTER',
                      style: style.titleFont.copyWith(
                        color: textColor,
                        fontSize: 16,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    SlackTickets(
                      remaining: data.daily.slackRemaining,
                      accent: accent,
                      textColor: textColor,
                      compact: true,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  flex: 3,
                  child: Center(
                    child: CountdownDisplay(
                      seconds: data.countdown,
                      glowColor: accent,
                      textStyle: style.displayFont.copyWith(
                        fontSize: 96,
                        color: textColor,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    ProgressRingView(
                      value: data.daily.completionRatio,
                      size: 84,
                      trackColor: Colors.white.withValues(alpha: 0.12),
                      progressColor: accent,
                      textStyle: style.bodyFont.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        '總進度 ${data.daily.completedCycles}/${data.daily.totalCycles} 輪',
                        style: style.bodyFont.copyWith(
                          color: muted,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        textStyle: style.bodyFont.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: data.onAddTask,
                      icon: const Icon(Icons.add),
                      label: const Text('新增任務'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Expanded(
                  flex: 4,
                  child: TaskListView(
                    tasks: data.tasks,
                    itemBuilder: (context, task, index) {
                      return TaskTile(
                        task: task,
                        onStart: () => data.onStartTask(task),
                        accent: accent,
                        background:
                            style.panelGradient.first.withValues(alpha: 0.9),
                        border: accent.withValues(alpha: 0.35),
                        textColor: textColor,
                        subTextColor: muted,
                        titleStyle: style.titleFont.copyWith(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        metaStyle: style.bodyFont.copyWith(
                          color: muted,
                          fontSize: 12,
                        ),
                        buttonStyle:
                            style.bodyFont.copyWith(fontWeight: FontWeight.w700),
                      );
                    },
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

class TimelineRailLayout extends StatelessWidget {
  const TimelineRailLayout({super.key, required this.data});

  final VariantData data;

  @override
  Widget build(BuildContext context) {
    final style = plannerStyleFor(HuntVariant.timelineRail);
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
                    Text(
                      'TODAY RAIL',
                      style: style.titleFont.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    const Spacer(),
                    SlackTickets(
                      remaining: data.daily.slackRemaining,
                      accent: accent,
                      textColor: textColor,
                      compact: true,
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textColor,
                        side: BorderSide(color: accent.withValues(alpha: 0.5)),
                        textStyle:
                            style.bodyFont.copyWith(fontWeight: FontWeight.w700),
                      ),
                      onPressed: data.onAddTask,
                      icon: const Icon(Icons.add),
                      label: const Text('新增任務'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CountdownDisplay(
                  seconds: data.countdown,
                  textStyle: style.displayFont.copyWith(
                    fontSize: 92,
                    color: textColor,
                    letterSpacing: 2,
                  ),
                  align: TextAlign.left,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: TaskListView(
                    tasks: data.tasks,
                    itemBuilder: (context, task, index) {
                      return _TimelineItem(
                        task: task,
                        style: style,
                        accent: accent,
                        textColor: textColor,
                        muted: muted,
                        isLast: index == data.tasks.length - 1,
                        onStart: () => data.onStartTask(task),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '進度總覽',
                  style: style.titleFont.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                HeatmapOverview(
                  baseValue: data.daily.completionRatio,
                  color: accent,
                  columns: 7,
                  rows: 4,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.task,
    required this.style,
    required this.accent,
    required this.textColor,
    required this.muted,
    required this.isLast,
    required this.onStart,
  });

  final TaskItem task;
  final PlannerStyle style;
  final Color accent;
  final Color textColor;
  final Color muted;
  final bool isLast;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final ratio = task.totalCycles <= 0
        ? 0.0
        : task.completedCycles / task.totalCycles;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 26,
          child: Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    color: accent.withValues(alpha: 0.3),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: style.titleFont.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${task.completedCycles}/${task.totalCycles} 輪 · ${task.cycleMinutes} 分鐘',
                  style: style.bodyFont.copyWith(
                    color: muted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: ratio,
                  backgroundColor: accent.withValues(alpha: 0.15),
                  color: accent,
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: task.isDone ? null : onStart,
                    child: Text(
                      task.isDone ? '已完成' : '開獵',
                      style: style.bodyFont.copyWith(
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
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

class SplitCommandLayout extends StatelessWidget {
  const SplitCommandLayout({super.key, required this.data});

  final VariantData data;

  @override
  Widget build(BuildContext context) {
    final style = plannerStyleFor(HuntVariant.splitCommand);
    final accent = style.accent;
    final accent2 = style.accentSoft;
    final textColor = style.textPrimary;
    final muted = style.textSecondary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 720;
        final panel = _SplitPanel(
          data: data,
          style: style,
          accent: accent,
          accent2: accent2,
          textColor: textColor,
          muted: muted,
        );
        final list = _SplitTaskPanel(
          data: data,
          style: style,
          accent: accent,
          textColor: textColor,
          muted: muted,
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
                          Expanded(child: panel),
                          const SizedBox(width: 16),
                          Expanded(child: list),
                        ],
                      )
                    : Column(
                        children: [
                          Expanded(child: panel),
                          const SizedBox(height: 16),
                          Expanded(child: list),
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

class _SplitPanel extends StatelessWidget {
  const _SplitPanel({
    required this.data,
    required this.style,
    required this.accent,
    required this.accent2,
    required this.textColor,
    required this.muted,
  });

  final VariantData data;
  final PlannerStyle style;
  final Color accent;
  final Color accent2;
  final Color textColor;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent2.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'COMMAND',
                style: style.titleFont.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              SlackTickets(
                remaining: data.daily.slackRemaining,
                accent: accent,
                textColor: textColor,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Center(
              child: CountdownDisplay(
                seconds: data.countdown,
                glowColor: accent2,
                textStyle: style.displayFont.copyWith(
                  color: textColor,
                  fontSize: 84,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ProgressRingView(
                value: data.daily.completionRatio,
                size: 78,
                trackColor: Colors.white.withValues(alpha: 0.12),
                progressColor: accent2,
                textStyle: style.bodyFont.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '總進度 ${data.daily.completedCycles}/${data.daily.totalCycles} 輪',
                  style: style.bodyFont.copyWith(
                    color: muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              FilledButton(
                onPressed: data.onAddTask,
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.black,
                ),
                child: const Text('新增任務'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SplitTaskPanel extends StatelessWidget {
  const _SplitTaskPanel({
    required this.data,
    required this.style,
    required this.accent,
    required this.textColor,
    required this.muted,
  });

  final VariantData data;
  final PlannerStyle style;
  final Color accent;
  final Color textColor;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '任務佇列',
            style: style.titleFont.copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TaskListView(
              tasks: data.tasks,
              itemBuilder: (context, task, index) {
                return TaskTile(
                  task: task,
                  onStart: () => data.onStartTask(task),
                  accent: accent,
                  background: Colors.black.withValues(alpha: 0.25),
                  border: accent.withValues(alpha: 0.3),
                  textColor: textColor,
                  subTextColor: muted,
                  titleStyle: style.titleFont.copyWith(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  metaStyle: style.bodyFont.copyWith(
                    color: muted,
                    fontSize: 12,
                  ),
                  buttonStyle:
                      style.bodyFont.copyWith(fontWeight: FontWeight.w700),
                  dense: true,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class MonoStrikeLayout extends StatelessWidget {
  const MonoStrikeLayout({super.key, required this.data});

  final VariantData data;

  @override
  Widget build(BuildContext context) {
    final style = plannerStyleFor(HuntVariant.monoStrike);
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
                    Text(
                      'MONO STRIKE',
                      style: style.titleFont.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    SlackTickets(
                      remaining: data.daily.slackRemaining,
                      accent: accent,
                      textColor: textColor,
                      compact: true,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: data.onAddTask,
                      icon: const Icon(Icons.add),
                      color: accent,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: CountdownDisplay(
                      seconds: data.countdown,
                      glowColor: accent,
                      textStyle: style.displayFont.copyWith(
                        fontSize: 88,
                        color: textColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '今日進度 ${data.daily.completedCycles}/${data.daily.totalCycles} 輪',
                  style: style.bodyFont.copyWith(
                    color: muted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                XpBarOverview(
                  value: data.daily.completionRatio,
                  accent: accent,
                  track: Colors.white.withValues(alpha: 0.12),
                ),
                const SizedBox(height: 16),
                Expanded(
                  flex: 3,
                  child: TaskListView(
                    tasks: data.tasks,
                    itemBuilder: (context, task, index) {
                      final ratio = task.totalCycles <= 0
                          ? 0.0
                          : task.completedCycles / task.totalCycles;
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style: style.titleFont.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: ratio,
                                    backgroundColor:
                                        Colors.white.withValues(alpha: 0.12),
                                    color: accent,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '${task.completedCycles}/${task.totalCycles}',
                                  style: style.bodyFont.copyWith(
                                    color: muted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: task.isDone
                                    ? null
                                    : () => data.onStartTask(task),
                                child: Text(
                                  task.isDone ? '已完成' : '開獵',
                                  style: style.bodyFont.copyWith(
                                    color: accent,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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

class StellarHuntLayout extends StatelessWidget {
  const StellarHuntLayout({super.key, required this.data});

  final VariantData data;

  @override
  Widget build(BuildContext context) {
    final style = plannerStyleFor(HuntVariant.stellarHunt);
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
                    Text(
                      'STELLAR HUNT',
                      style: style.titleFont.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Spacer(),
                    SlackTickets(
                      remaining: data.daily.slackRemaining,
                      accent: accent2,
                      textColor: textColor,
                      compact: true,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: data.onAddTask,
                      icon: const Icon(Icons.add_circle_outline),
                      color: accent2,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: CountdownDisplay(
                      seconds: data.countdown,
                      glowColor: accent2,
                      textStyle: style.displayFont.copyWith(
                        fontSize: 84,
                        color: textColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ProgressRingView(
                      value: data.daily.completionRatio,
                      size: 70,
                      trackColor: Colors.white.withValues(alpha: 0.12),
                      progressColor: accent2,
                      textStyle: style.bodyFont.copyWith(
                        color: textColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '星際進度 ${data.daily.completedCycles} / ${data.daily.totalCycles} 輪',
                        style: style.bodyFont.copyWith(
                          color: muted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    HeatmapOverview(
                      baseValue: data.daily.completionRatio,
                      color: accent,
                      columns: 4,
                      rows: 2,
                      size: 14,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  flex: 3,
                  child: TaskListView(
                    tasks: data.tasks,
                    itemBuilder: (context, task, index) {
                      return TaskTile(
                        task: task,
                        onStart: () => data.onStartTask(task),
                        accent: accent2,
                        background: Colors.white.withValues(alpha: 0.08),
                        border: accent.withValues(alpha: 0.3),
                        textColor: textColor,
                        subTextColor: muted,
                        titleStyle: style.titleFont.copyWith(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        metaStyle: style.bodyFont.copyWith(
                          color: muted,
                          fontSize: 12,
                        ),
                        buttonStyle:
                            style.bodyFont.copyWith(fontWeight: FontWeight.w700),
                      );
                    },
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

class ArcadeBoardLayout extends StatelessWidget {
  const ArcadeBoardLayout({super.key, required this.data});

  final VariantData data;

  @override
  Widget build(BuildContext context) {
    final style = plannerStyleFor(HuntVariant.arcadeBoard);
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
                    Text(
                      'ARCADE MODE',
                      style: style.titleFont.copyWith(
                        color: accent,
                        fontSize: 10,
                      ),
                    ),
                    const Spacer(),
                    _HeartTickets(remaining: data.daily.slackRemaining),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: data.onAddTask,
                      icon: const Icon(Icons.add_circle),
                      color: accent2,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  flex: 2,
                  child: Center(
                  child: CountdownDisplay(
                    seconds: data.countdown,
                    glowColor: accent2,
                    textStyle: style.displayFont.copyWith(
                      color: textColor,
                      fontSize: 74,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'XP 進度',
                style: style.bodyFont.copyWith(
                  color: muted,
                  fontSize: 10,
                ),
              ),
                const SizedBox(height: 6),
                XpBarOverview(
                  value: data.daily.completionRatio,
                  accent: accent2,
                  track: Colors.white.withValues(alpha: 0.12),
                ),
                const SizedBox(height: 12),
                Expanded(
                  flex: 3,
                  child: TaskListView(
                    tasks: data.tasks,
                    itemBuilder: (context, task, index) {
                      final ratio = task.totalCycles <= 0
                          ? 0.0
                          : task.completedCycles / task.totalCycles;
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${index + 1}',
                                style: style.bodyFont.copyWith(
                                  color: accent,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    task.title,
                                    style: style.bodyFont.copyWith(
                                      color: textColor,
                                      fontSize: 10,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  LinearProgressIndicator(
                                    value: ratio,
                                    backgroundColor:
                                        Colors.white.withValues(alpha: 0.1),
                                    color: accent2,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: task.isDone
                                  ? null
                                  : () => data.onStartTask(task),
                              child: Text(
                                task.isDone ? '完成' : 'START',
                                style: style.bodyFont.copyWith(
                                  color: accent2,
                                  fontSize: 8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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

class OrbitCommandLayout extends StatelessWidget {
  const OrbitCommandLayout({super.key, required this.data});

  final VariantData data;

  @override
  Widget build(BuildContext context) {
    final style = plannerStyleFor(HuntVariant.orbitCommand);
    final accent = style.accent;
    final accent2 = style.accentSoft;
    final textColor = style.textPrimary;
    final muted = style.textSecondary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 720;

        final countdown = Stack(
          alignment: Alignment.center,
          children: [
            OrbitOverview(
              value: data.daily.completionRatio,
              accent: accent2,
              track: Colors.white.withValues(alpha: 0.08),
              size: 220,
            ),
            CountdownDisplay(
              seconds: data.countdown,
              glowColor: accent,
              textStyle: style.displayFont.copyWith(
                fontSize: 72,
                color: textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        );

        final taskPanel = Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    '任務軌道',
                    style: style.titleFont.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: data.onAddTask,
                    icon: const Icon(Icons.add_circle_outline),
                    color: accent2,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TaskListView(
                  tasks: data.tasks,
                  itemBuilder: (context, task, index) {
                    return TaskTile(
                      task: task,
                      onStart: () => data.onStartTask(task),
                      accent: accent2,
                      background: Colors.black.withValues(alpha: 0.3),
                      border: accent.withValues(alpha: 0.25),
                      textColor: textColor,
                      subTextColor: muted,
                      titleStyle: style.titleFont.copyWith(
                        color: textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      metaStyle: style.bodyFont.copyWith(
                        color: muted,
                        fontSize: 12,
                      ),
                      buttonStyle:
                          style.bodyFont.copyWith(fontWeight: FontWeight.w700),
                      dense: true,
                    );
                  },
                ),
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
                  children: [
                    Row(
                      children: [
                        Text(
                          'ORBIT COMMAND',
                          style: style.titleFont.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const Spacer(),
                        SlackTickets(
                          remaining: data.daily.slackRemaining,
                          accent: accent2,
                          textColor: textColor,
                          compact: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: isWide
                          ? Row(
                              children: [
                                Expanded(child: Center(child: countdown)),
                                const SizedBox(width: 16),
                                Expanded(child: taskPanel),
                              ],
                            )
                          : Column(
                              children: [
                                Expanded(child: Center(child: countdown)),
                                const SizedBox(height: 16),
                                Expanded(child: taskPanel),
                              ],
                            ),
                    ),
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

class AuroraGlassLayout extends StatelessWidget {
  const AuroraGlassLayout({super.key, required this.data});

  final VariantData data;

  @override
  Widget build(BuildContext context) {
    final style = plannerStyleFor(HuntVariant.auroraGlass);
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
                    Text(
                      'AURORA GLASS',
                      style: style.titleFont.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Spacer(),
                    SlackTickets(
                      remaining: data.daily.slackRemaining,
                      accent: textColor,
                      textColor: textColor,
                      compact: true,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: data.onAddTask,
                      icon: const Icon(Icons.add_circle_outline),
                      color: textColor,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: CountdownDisplay(
                      seconds: data.countdown,
                      glowColor: textColor,
                      textStyle: style.displayFont.copyWith(
                        fontSize: 82,
                        color: textColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ProgressRingView(
                      value: data.daily.completionRatio,
                      size: 68,
                      trackColor: Colors.white.withValues(alpha: 0.18),
                      progressColor: textColor,
                      textStyle: style.bodyFont.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '總進度 ${data.daily.completedCycles}/${data.daily.totalCycles} 輪',
                        style: style.bodyFont.copyWith(
                          color: muted,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    HeatmapOverview(
                      baseValue: data.daily.completionRatio,
                      color: textColor,
                      columns: 4,
                      rows: 2,
                      size: 12,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  flex: 3,
                  child: TaskListView(
                    tasks: data.tasks,
                    itemBuilder: (context, task, index) {
                      return TaskTile(
                        task: task,
                        onStart: () => data.onStartTask(task),
                        accent: textColor,
                        background: Colors.white.withValues(alpha: 0.18),
                        border: Colors.white.withValues(alpha: 0.35),
                        textColor: textColor,
                        subTextColor: muted,
                        titleStyle: style.titleFont.copyWith(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        metaStyle: style.bodyFont.copyWith(
                          color: muted,
                          fontSize: 12,
                        ),
                        buttonStyle:
                            style.bodyFont.copyWith(fontWeight: FontWeight.w700),
                      );
                    },
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
