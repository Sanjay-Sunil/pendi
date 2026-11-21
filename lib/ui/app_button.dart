import 'package:flutter/material.dart';

import '../theme/tokens.dart';

enum ButtonVariant { primary, secondary, ghost, danger }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.icon,
    this.small = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final IconData? icon;
  final bool small;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final pad = EdgeInsets.symmetric(horizontal: small ? 12 : 16);
    final size = Size(
      expand ? double.infinity : Tokens.tapTarget,
      Tokens.tapTarget,
    );
    final text = Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.w600),
    );
    final child = icon == null
        ? text
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [Icon(icon, size: 16), const SizedBox(width: 8), text],
          );
    return switch (variant) {
      ButtonVariant.primary => FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(padding: pad, minimumSize: size),
        child: child,
      ),
      ButtonVariant.secondary => OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(padding: pad, minimumSize: size),
        child: child,
      ),
      ButtonVariant.ghost => TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(padding: pad, minimumSize: size),
        child: child,
      ),
      ButtonVariant.danger => OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: pad,
          minimumSize: size,
          foregroundColor: c.danger,
        ),
        child: child,
      ),
    };
  }
}
