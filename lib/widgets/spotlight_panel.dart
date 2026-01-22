import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app/theme.dart';
import 'glass_panel.dart';

class SpotlightPanel extends StatefulWidget {
  const SpotlightPanel({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsets padding;

  @override
  State<SpotlightPanel> createState() => _SpotlightPanelState();
}

class _SpotlightPanelState extends State<SpotlightPanel> {
  Offset? _local;
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final body = Stack(
      children: [
        GlassPanel(
          borderRadius: widget.borderRadius,
          padding: widget.padding,
          child: widget.child,
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: _hover ? 1 : 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  gradient: RadialGradient(
                    radius: 0.9,
                    center: _local == null
                        ? Alignment.center
                        : Alignment(
                            (_local!.dx / _size.width) * 2 - 1,
                            (_local!.dy / _size.height) * 2 - 1,
                          ),
                    colors: [
                      Colors.white.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.55],
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 240),
              opacity: _hover ? 1 : 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.20),
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );

    if (kIsWeb) {
      return MouseRegion(
        onHover: (e) {
          setState(() {
            _hover = true;
            _local = e.localPosition;
          });
        },
        onExit: (_) {
          setState(() {
            _hover = false;
            _local = null;
          });
        },
        child: body,
      );
    }

    return body;
  }

  Size get _size {
    final renderObject = context.findRenderObject();
    if (renderObject is RenderBox) {
      return renderObject.size;
    }
    return const Size(1, 1);
  }
}
