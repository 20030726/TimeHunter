import 'package:flutter/material.dart';

class GlowProgressBar extends StatelessWidget {
  const GlowProgressBar({
    super.key,
    required this.value,
    this.height = 6.0,
    this.trackColor = const Color(0xFF334155),
    this.progressColor = const Color(0xFF22C55E),
    this.borderRadius = 999.0,
    this.glowBlur = 6.0,
  });

  final double value; // 0.0 ~ 1.0
  final double height;
  final Color trackColor;
  final Color progressColor;
  final double borderRadius;
  final double glowBlur;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          children: [
            FractionallySizedBox(
              widthFactor: v,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      progressColor,
                      // Darker tail for depth
                      const Color(0xFF059669),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(borderRadius),
                  boxShadow: [
                    BoxShadow(
                      color: progressColor.withValues(alpha: 0.5),
                      blurRadius: glowBlur,
                      spreadRadius: 1,
                      offset: Offset.zero,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
