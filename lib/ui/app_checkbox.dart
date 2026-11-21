import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/tokens.dart';

/// 20px rounded square that fills amber; the whole row is a 44px tap target.
class AppCheckbox extends StatelessWidget {
  const AppCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.showLabel = true,
    this.labelStyle,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String label;
  final bool showLabel;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final box = AnimatedContainer(
      duration: Tokens.motion,
      curve: Curves.easeOut,
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: value ? c.accent : c.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: value ? c.accent : c.muted),
      ),
      child: value
          ? Icon(LucideIcons.check, size: 14, color: c.accentFg)
          : null,
    );
    return Semantics(
      checked: value,
      label: label,
      button: true,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(Tokens.radiusControl),
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: Tokens.tapTarget,
            minWidth: Tokens.tapTarget,
          ),
          child: Row(
            mainAxisSize: showLabel ? MainAxisSize.max : MainAxisSize.min,
            children: [
              Padding(padding: const EdgeInsets.all(12), child: box),
              if (showLabel)
                Expanded(
                  child: Text(
                    label,
                    style: labelStyle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
