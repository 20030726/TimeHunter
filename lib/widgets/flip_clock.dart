import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Flip-style timer display (MM:SS).
///
/// Animation matches a physical flip clock sequence:
/// 1) Current bottom flap flips UP into the center line (appears to shrink).
/// 2) Next top flap flips DOWN from the center line (appears to expand).
class FlipClock extends StatelessWidget {
  const FlipClock({
    super.key,
    required this.seconds,
    this.digitSize = const Size(92, 124),
    this.gap = 10,
  });

  final int seconds;
  final Size digitSize;
  final double gap;

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final safe = seconds < 0 ? 0 : seconds;
    final mm = safe ~/ 60;
    final ss = safe % 60;
    final text = '${_two(mm)}${_two(ss)}';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _FlipDigit(digit: int.parse(text[0]), size: digitSize),
        SizedBox(width: gap),
        _FlipDigit(digit: int.parse(text[1]), size: digitSize),
        SizedBox(width: gap * 0.7),
        _Colon(height: digitSize.height),
        SizedBox(width: gap * 0.7),
        _FlipDigit(digit: int.parse(text[2]), size: digitSize),
        SizedBox(width: gap),
        _FlipDigit(digit: int.parse(text[3]), size: digitSize),
      ],
    );
  }
}

class _Colon extends StatelessWidget {
  const _Colon({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 16,
      height: height,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [_ColonDot(), SizedBox(height: 18), _ColonDot()],
      ),
    );
  }
}

class _ColonDot extends StatelessWidget {
  const _ColonDot();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.90),
        shape: BoxShape.circle,
      ),
      child: const SizedBox(width: 8, height: 8),
    );
  }
}

class _FlipDigit extends StatefulWidget {
  const _FlipDigit({required this.digit, required this.size});

  final int digit;
  final Size size;

  @override
  State<_FlipDigit> createState() => _FlipDigitState();
}

class _FlipDigitState extends State<_FlipDigit>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late int _current;
  int _target = 0;
  int? _queued;

  @override
  void initState() {
    super.initState();
    _current = widget.digit;
    _target = widget.digit;
    _controller =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 400),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            setState(() {
              _current = _target;
            });
            _controller.reset();

            final next = _queued;
            _queued = null;

            if (next != null && next != _current) {
              _target = next;
              _controller.forward();
            }
          }
        });
  }

  @override
  void didUpdateWidget(covariant _FlipDigit oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.digit == _current) return;

    if (!_controller.isAnimating) {
      _target = widget.digit;
      _controller.forward();
      return;
    }

    _queued = widget.digit;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_controller.value);

        // Two-phase animation.
        final phase1 = (t * 2).clamp(0.0, 1.0);
        final phase2 = ((t - 0.5) * 2).clamp(0.0, 1.0);

        // Phase 1: bottom current flips up (0 -> +90deg)
        final bottomAngle = (math.pi / 2) * phase1;

        // Phase 2: top target flips down (-90deg -> 0)
        final topAngle = (-math.pi / 2) + (math.pi / 2) * phase2;

        // Whether we should show target bottom as static (after halfway).
        final showTargetBottom = t >= 0.5;

        return SizedBox(
          width: size.width,
          height: size.height,
          child: Stack(
            children: [
              _CardBase(size: size),

              // Static top half of current.
              _HalfClip(
                half: _Half.top,
                size: size,
                child: _DigitText(digit: _current, dim: false),
              ),

              // Static bottom half of target, appears after mid-point.
              if (showTargetBottom)
                _HalfClip(
                  half: _Half.bottom,
                  size: size,
                  child: _DigitText(digit: _target, dim: false),
                ),

              // Phase 1: bottom current flips UP (hinge at top / center line).
              if (t < 0.5)
                _FlipBottomUp(
                  angle: bottomAngle,
                  size: size,
                  child: _DigitText(digit: _current, dim: true),
                ),

              // Phase 2: top target flips DOWN (hinge at bottom / center line).
              if (t >= 0.5)
                _FlipTopDown(
                  angle: topAngle,
                  size: size,
                  child: _DigitText(digit: _target, dim: false),
                ),

              // Divider line sits above everything.
              Positioned(
                left: 8,
                right: 8,
                top: size.height / 2 - 1,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),

              // A subtle hinge shadow at mid line.
              Positioned(
                left: 10,
                right: 10,
                top: size.height / 2,
                child: IgnorePointer(
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.10),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

enum _Half { top, bottom }

class _CardBase extends StatelessWidget {
  const _CardBase({required this.size});

  final Size size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size.width,
      height: size.height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _DigitText extends StatelessWidget {
  const _DigitText({required this.digit, required this.dim});

  final int digit;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$digit',
        style: TextStyle(
          fontSize: 76,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.0,
          color: Colors.black.withValues(alpha: dim ? 0.6 : 1.0),
        ),
      ),
    );
  }
}

class _HalfClip extends StatelessWidget {
  const _HalfClip({
    required this.half,
    required this.size,
    required this.child,
  });

  final _Half half;
  final Size size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final alignment = half == _Half.top
        ? Alignment.topCenter
        : Alignment.bottomCenter;

    return Positioned.fill(
      child: ClipRect(
        child: Align(
          alignment: alignment,
          heightFactor: 0.5,
          child: SizedBox(width: size.width, height: size.height, child: child),
        ),
      ),
    );
  }
}

class _FlipBottomUp extends StatelessWidget {
  const _FlipBottomUp({
    required this.angle,
    required this.size,
    required this.child,
  });

  final double angle;
  final Size size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Bottom half, hinged at its top edge (center line), rotates up.
    return Positioned.fill(
      child: ClipRect(
        child: Align(
          alignment: Alignment.bottomCenter,
          heightFactor: 0.5,
          child: Transform(
            alignment: Alignment.topCenter,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.003)
              ..rotateX(angle),
            child: Stack(
              children: [
                SizedBox(width: size.width, height: size.height, child: child),
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.0),
                            Colors.black.withValues(alpha: 0.3),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FlipTopDown extends StatelessWidget {
  const _FlipTopDown({
    required this.angle,
    required this.size,
    required this.child,
  });

  final double angle;
  final Size size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Top half, hinged at its bottom edge (center line), rotates down.
    return Positioned.fill(
      child: ClipRect(
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: 0.5,
          child: Transform(
            alignment: Alignment.bottomCenter,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.003)
              ..rotateX(angle),
            child: Stack(
              children: [
                SizedBox(width: size.width, height: size.height, child: child),
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.2),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
