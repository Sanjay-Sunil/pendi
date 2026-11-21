import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    super.key,
    required this.value,
    required this.max,
    required this.label,
  });

  final num value;
  final num max;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final pct = max <= 0 ? 0.0 : (value / max).clamp(0, 1).toDouble();
    return Semantics(
      label: label,
      value: '${(pct * 100).round()}%',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          height: 4,
          child: Stack(
            children: [
              Positioned.fill(child: ColoredBox(color: c.surface2)),
              FractionallySizedBox(
                widthFactor: pct,
                child: ColoredBox(
                  color: c.accent,
                  child: const SizedBox.expand(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
