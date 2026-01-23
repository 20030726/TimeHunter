import 'package:flutter/material.dart';

class XpBarOverview extends StatelessWidget {
  const XpBarOverview({
    super.key,
    required this.value,
    required this.accent,
    required this.track,
  });

  final double value;
  final Color accent;
  final Color track;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    return Stack(
      children: [
        Container(
          height: 12,
          decoration: BoxDecoration(
            color: track,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        FractionallySizedBox(
          widthFactor: v,
          child: Container(
            height: 12,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.6),
                  blurRadius: 12,
                ),
              ],
            ),
          ),
        ),
        Positioned.fill(
          child: Row(
            children: List.generate(6, (index) {
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 2,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
