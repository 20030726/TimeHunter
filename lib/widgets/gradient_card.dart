import 'package:flutter/material.dart';

import '../app/theme.dart';

class GradientCard extends StatelessWidget {
  const GradientCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 12,
    this.elevation = 4,
    this.start = AppColors.surface,
    this.end = AppColors.surface,
  });

  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;
  final double elevation;
  final Color start;
  final Color end;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: elevation,
      shadowColor: Colors.black.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(borderRadius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: start,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
