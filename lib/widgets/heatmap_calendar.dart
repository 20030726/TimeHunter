import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../core/utils/dates.dart';

class HeatmapCalendar extends StatelessWidget {
  const HeatmapCalendar({
    super.key,
    required this.month,
    required this.levelForDay,
    this.onTapDay,
    this.circleSize = 32,
    this.cellExtent = 44,
    this.mainAxisSpacing = 10,
    this.crossAxisSpacing = 10,
    this.startWeekday = DateTime.monday,
  });

  /// Any date within the month to render.
  final DateTime month;

  /// Completion level: 0..3.
  final int Function(DateTime day) levelForDay;

  final void Function(DateTime day)? onTapDay;

  /// Visual circle diameter.
  final double circleSize;

  /// Fixed grid cell size; prevents huge circles on wide screens.
  final double cellExtent;

  final double mainAxisSpacing;
  final double crossAxisSpacing;

  /// DateTime.monday or DateTime.sunday.
  final int startWeekday;

  static const _greens = <Color>[
    Color(0xFF9BE9A8),
    Color(0xFF40C463),
    Color(0xFF30A14E),
    Color(0xFF216E39),
  ];

  int _leadingDays(DateTime firstDay) {
    final delta = (firstDay.weekday - startWeekday) % 7;
    return delta < 0 ? delta + 7 : delta;
  }

  @override
  Widget build(BuildContext context) {
    final monthStart = DateTime(month.year, month.month, 1);
    final nextMonth = DateTime(month.year, month.month + 1, 1);
    final daysInMonth = nextMonth.subtract(const Duration(days: 1)).day;

    final leading = _leadingDays(monthStart);
    final gridStart = monthStart.subtract(Duration(days: leading));

    final cells = List<DateTime>.generate(
      42,
      (i) => gridStart.add(Duration(days: i)),
      growable: false,
    );

    final today = dateOnly(DateTime.now());
    final gridWidth = (cellExtent * 7) + (crossAxisSpacing * 6);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${month.year}-${month.month.toString().padLeft(2, '0')}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const _Legend(),
          ],
        ),
        const SizedBox(height: 12),
        Center(
          child: SizedBox(
            width: gridWidth,
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: mainAxisSpacing,
                crossAxisSpacing: crossAxisSpacing,
              ),
              itemCount: cells.length,
              itemBuilder: (context, index) {
                final day = cells[index];
                final isInMonth = day.month == month.month;
                final isToday = dateOnly(day) == today;

                final level = isInMonth ? levelForDay(day).clamp(0, 3) : 0;

                final baseColor = level == 0
                    ? AppColors.divider
                    : _greens[level].withValues(alpha: isInMonth ? 1.0 : 0.35);

                final glow = level == 0
                    ? null
                    : [
                        BoxShadow(
                          color: baseColor.withValues(alpha: 0.35),
                          blurRadius: 4,
                        ),
                      ];

                final dot = AnimatedScale(
                  duration: const Duration(milliseconds: 160),
                  scale: isToday ? 1.1 : 1.0,
                  child: Container(
                    width: circleSize,
                    height: circleSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: baseColor.withValues(
                        alpha: isInMonth ? 1.0 : 0.22,
                      ),
                      boxShadow: glow,
                      border: isToday
                          ? Border.all(
                              color: const Color(
                                0xFF22C55E,
                              ).withValues(alpha: 0.85),
                              width: 2,
                            )
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      isInMonth ? '${day.day}' : '',
                      style: TextStyle(
                        fontSize: 12,
                        color: isInMonth
                            ? AppColors.textPrimary.withValues(
                                alpha: level == 0 ? 0.55 : 0.95,
                              )
                            : AppColors.textSecondary.withValues(alpha: 0.25),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );

                return GestureDetector(
                  onTap: isInMonth && onTapDay != null
                      ? () => onTapDay!(day)
                      : null,
                  child: Center(child: dot),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '本月：$daysInMonth 天',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    const colors = <Color>[
      Color(0xFF334155),
      Color(0xFF9BE9A8),
      Color(0xFF40C463),
      Color(0xFF30A14E),
      Color(0xFF216E39),
    ];

    return Row(
      children: [
        const Text(
          'Less',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
        const SizedBox(width: 6),
        for (final c in colors)
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
        const SizedBox(width: 6),
        const Text(
          'More',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
      ],
    );
  }
}
