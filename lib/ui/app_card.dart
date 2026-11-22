import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = 16,
    this.onTap,
  });

  final Widget child;
  final double padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(Tokens.radiusCard);
    final content = Padding(padding: EdgeInsets.all(padding), child: child);
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: c.border),
      ),
      clipBehavior: Clip.antiAlias,
      // Only tappable cards get an InkWell; otherwise it would merge the card's
      // controls into one node for screen readers.
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}
