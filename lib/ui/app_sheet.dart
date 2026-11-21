import 'package:flutter/material.dart';

/// Modal bottom sheet with a title; scrolls and lifts above the keyboard.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required String title,
  required Widget child,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              header: true,
              child: Text(title, style: Theme.of(ctx).textTheme.titleMedium),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    ),
  );
}
