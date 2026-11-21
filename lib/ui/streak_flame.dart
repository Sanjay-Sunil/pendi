import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

class StreakFlame extends StatelessWidget {
  const StreakFlame(this.days, {super.key});

  final int days;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      label: '$days day streak',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.flame,
            size: 16,
            color: days > 0 ? c.accent : c.muted,
          ),
          const SizedBox(width: 4),
          Text(
            '$days',
            style: TextStyle(
              fontFamily: mono,
              color: days > 0 ? c.accent : c.muted,
            ),
          ),
        ],
      ),
    );
  }
}
