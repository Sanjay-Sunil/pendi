import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// 11px mono uppercase label used for section headers.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontFamily: mono,
          fontSize: 11,
          letterSpacing: 0.88,
          color: context.colors.muted,
        ),
      ),
    );
  }
}
