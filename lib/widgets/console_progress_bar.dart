import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/theme.dart';

/// Legacy (backup) console-style dotted progress bar.
/// Kept for reference; not used by default.
class ConsoleProgressBar extends StatelessWidget {
  const ConsoleProgressBar({
    super.key,
    required this.value,
    this.height = 8,
    this.dotRadius = 1.2,
    this.dotGap = 4.2,
    this.trackColor = AppColors.track,
    this.progressColor = AppColors.accent,
    this.showPercent = true,
  });

  final double value;
  final double height;
  final double dotRadius;
  final double dotGap;
  final Color trackColor;
  final Color progressColor;
  final bool showPercent;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: height,
            child: CustomPaint(
              painter: _ConsoleBarPainter(
                value: clamped,
                dotRadius: dotRadius,
                dotGap: dotGap,
                trackColor: trackColor,
                progressColor: progressColor,
              ),
            ),
          ),
        ),
        if (showPercent) ...[
          const SizedBox(width: 12),
          Text(
            '${(clamped * 100).round()}%',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _ConsoleBarPainter extends CustomPainter {
  _ConsoleBarPainter({
    required this.value,
    required this.dotRadius,
    required this.dotGap,
    required this.trackColor,
    required this.progressColor,
  });

  final double value;
  final double dotRadius;
  final double dotGap;
  final Color trackColor;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final paint = Paint()..style = PaintingStyle.fill;

    final step = (dotRadius * 2) + dotGap;
    final count = (size.width / step).floor().clamp(1, 10000);
    final progressCount = (count * value).floor();

    paint.color = trackColor.withValues(alpha: 0.35);
    for (var i = 0; i < count; i++) {
      final x = i * step + dotRadius;
      canvas.drawCircle(Offset(x, centerY), dotRadius, paint);
    }

    final glowPaint = Paint()
      ..color = progressColor.withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    for (var i = 0; i < progressCount; i++) {
      final x = i * step + dotRadius;
      canvas.drawCircle(Offset(x, centerY), dotRadius + 1.0, glowPaint);
    }

    paint.color = progressColor.withValues(alpha: 0.9);
    for (var i = 0; i < progressCount; i++) {
      final x = i * step + dotRadius;
      canvas.drawCircle(Offset(x, centerY), dotRadius, paint);
    }

    if (progressCount > 0) {
      final endX = progressCount * step;
      final cap = Rect.fromCenter(
        center: Offset(math.min(endX, size.width), centerY),
        width: 1,
        height: size.height,
      );
      canvas.drawRect(
        cap,
        Paint()..color = progressColor.withValues(alpha: 0.35),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ConsoleBarPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.dotRadius != dotRadius ||
        oldDelegate.dotGap != dotGap ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor;
  }
}
