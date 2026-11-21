import 'package:flutter/material.dart';

/// Labelled text field. [maxLines] > 1 makes it a text area.
class AppInput extends StatelessWidget {
  const AppInput({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.maxLines = 1,
    this.minLines,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.maxLength,
    this.textInputAction,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final int maxLines;
  final int? minLines;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final int? maxLength;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: maxLines,
          minLines: minLines,
          keyboardType: keyboardType,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          autofocus: autofocus,
          maxLength: maxLength,
          textInputAction: textInputAction,
          decoration: InputDecoration(hintText: hint, counterText: ''),
        ),
      ],
    );
  }
}
