import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'section_label.dart';

/// A quiet card grouping one Today section: icon + mono label + trailing info.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.label,
    required this.icon,
    required this.children,
    this.trailing,
  });

  final String label;
  final IconData icon;
  final Widget? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Tokens.radiusCard),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: c.muted),
              const SizedBox(width: 8),
              Expanded(child: SectionLabel(label)),
              ?trailing,
            ],
          ),
          const SizedBox(height: 4),
          ...children,
        ],
      ),
    );
  }
}

/// Fades content in once (150ms); instant when animations are disabled.
class FadeIn extends StatelessWidget {
  const FadeIn({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Tokens.motion,
      curve: Curves.easeOut,
      builder: (_, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 6),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
