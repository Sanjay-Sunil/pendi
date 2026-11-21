import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

enum BadgeTone { neutral, accent, success, danger }

class AppBadge extends StatelessWidget {
  const AppBadge(this.text, {super.key, this.tone = BadgeTone.neutral});

  final String text;
  final BadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (fg, bg) = switch (tone) {
      BadgeTone.neutral => (c.muted, Colors.transparent),
      BadgeTone.accent => (c.accent, c.accentSoft),
      BadgeTone.success => (c.success, Colors.transparent),
      BadgeTone.danger => (c.danger, Colors.transparent),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: tone == BadgeTone.accent
              ? c.accent.withValues(alpha: 0.4)
              : c.border,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(fontFamily: mono, fontSize: 11, color: fg),
      ),
    );
  }
}
