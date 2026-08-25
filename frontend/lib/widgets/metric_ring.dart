import 'package:flutter/material.dart';

class MetricRing extends StatelessWidget {
  const MetricRing({
    required this.value,
    required this.label,
    required this.color,
    this.size = 96,
    super.key,
  });

  final double value;
  final String label;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final percent = value.clamp(0, 100) / 100;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: percent,
            strokeWidth: 9,
            backgroundColor: color.withValues(alpha: 0.12),
            color: color,
            strokeCap: StrokeCap.round,
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${value.round()}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              Text(label, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ],
      ),
    );
  }
}

