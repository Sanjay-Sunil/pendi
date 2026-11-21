import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

class DemoBanner extends StatelessWidget {
  const DemoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SafeArea(
      bottom: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(bottom: BorderSide(color: c.border)),
        ),
        child: Text(
          'DEMO MODE · DATA RESETS WHEN THE APP RESTARTS',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: mono,
            fontSize: 11,
            letterSpacing: 0.88,
            color: c.muted,
          ),
        ),
      ),
    );
  }
}
