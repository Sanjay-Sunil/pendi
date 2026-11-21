import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'app_button.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: TextStyle(color: context.colors.muted)),
          if (actionLabel != null && onAction != null)
            AppButton(
              label: actionLabel!,
              onPressed: onAction,
              variant: ButtonVariant.ghost,
              small: true,
            ),
        ],
      ),
    );
  }
}
