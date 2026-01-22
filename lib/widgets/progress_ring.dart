import 'package:flutter/material.dart';

class ProgressRing extends StatelessWidget {
  const ProgressRing({super.key, required this.value});

  final double value; // 0~1

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 240,
          height: 240,
          child: CircularProgressIndicator(
            value: v,
            strokeWidth: 10,
            backgroundColor: const Color(0xFF2D3748),
            valueColor: const AlwaysStoppedAnimation(Color(0xFF22C55E)),
          ),
        ),
        Text(
          '${(v * 100).toInt()}%',
          style: const TextStyle(fontSize: 48, color: Color(0xFFF3F4F6)),
        ),
      ],
    );
  }
}
