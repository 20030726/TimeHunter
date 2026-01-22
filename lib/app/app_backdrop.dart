import 'package:flutter/material.dart';

import '../widgets/noise_overlay.dart';
import 'theme.dart';

class AppBackdrop extends StatelessWidget {
  const AppBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(color: AppColors.background),
          ),
        ),
        // Soft vignette
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                radius: 1.1,
                colors: [Colors.transparent, Color(0xAA000000)],
                stops: [0.0, 1.0],
              ),
            ),
          ),
        ),
        Positioned.fill(child: child),
        const Positioned.fill(child: NoiseOverlay(opacity: 0.04)),
      ],
    );
  }
}
